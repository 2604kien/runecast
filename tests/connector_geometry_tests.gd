extends RefCounted

# Geometry and editing checks only: each case supplies one straight Spark.
# This is not a claim about random-hand usefulness, energy balance or playtests.
# Endpoint boards are overridden only inside this QA test; the actual production
# model and selected kits are used. No runtime solving or reroll policy changes.
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const ProductionRules = preload("res://scripts/core/production_rules.gd")
const KINDS := ["straight", "corner", "split", "join"]

func run(check: Callable) -> void:
	var loaded := Loader.load_setup()
	var rules := ProductionRules.load_rules()
	check.call(loaded.ok and rules.ok, "Geometry QA loads the actual production profile and validated provisional kit definitions.")
	if not loaded.ok or not rules.ok:
		return
	var original_setup: Dictionary = loaded.setup.duplicate(true)
	var original_rules: Dictionary = rules.rules.duplicate(true)
	for kit in rules.rules.kits:
		var failures: Array = []
		var counts := {"pairs": 0, "adjacent": 0, "begin_outward": 0, "end_outward": 0, "flips": 0}
		for begin in range(16):
			for end in range(16):
				if begin == end:
					continue
				var path := _find_path([begin], end, 0, 0, kit.totals)
				if path.is_empty():
					failures.append("%d->%d: no finite-stock rune-bearing path" % [begin, end])
					continue
				var error := _exercise_pair(loaded.setup, kit.totals, path, counts)
				if not error.is_empty():
					failures.append("%d->%d: %s" % [begin, end, error])
		check.call(failures.is_empty() and counts.pairs == 240,
			"Kit %s: all 240 ordered endpoint pairs support a command-built straight-Spark route within finite stock; all four stock limits reject exhaustion and erasing disconnected extras restores the route. Failures: %s" % [kit.id, str(failures)])
		check.call(counts.adjacent == 48, "Kit %s covers all 48 ordered horizontal/vertical adjacencies with a rune-bearing detour, without requiring a direct path or a minimum runtime route length." % kit.id)
		check.call(counts.begin_outward == 180 and counts.end_outward == 180,
			"Kit %s repairs outward initial ports through player Rotate for every boundary endpoint: 180 Begin and 180 End placements." % kit.id)
		check.call(counts.flips > 0, "Kit %s constructs routes using actual directional-wire Flip as well as Rotate and checks resulting ports." % kit.id)
	check.call(loaded.setup == original_setup and rules.rules == original_rules,
		"All 720 geometry cases leave the production setup and validated kit definitions detached and unchanged.")

func _neighbor(cell: int, direction: int) -> int:
	var x := cell % 4
	var y := int(cell / 4)
	match direction:
		0: y -= 1
		1: x += 1
		2: y += 1
		3: x -= 1
	return y * 4 + x if x >= 0 and x < 4 and y >= 0 and y < 4 else -1

func _direction(first: int, second: int) -> int:
	for direction in range(4):
		if _neighbor(first, direction) == second:
			return direction
	return -1

# Independent bounded DFS counts grid turns; one internal straight socket will
# hold the supplied rune instead of consuming a straight from the finite kit.
func _find_path(path: Array, end: int, straights: int, corners: int, totals: Dictionary) -> Array:
	var current: int = path.back()
	if current == end:
		return path if straights > 0 else []
	for direction in range(4):
		var next := _neighbor(current, direction)
		if next < 0 or path.has(next):
			continue
		var next_straights := straights
		var next_corners := corners
		if path.size() > 1:
			if _direction(path[-2], current) == direction:
				next_straights += 1
			else:
				next_corners += 1
		if next_straights > int(totals.straight) + 1 or next_corners > int(totals.corner):
			continue
		var extended := path.duplicate()
		extended.append(next)
		var result := _find_path(extended, end, next_straights, next_corners, totals)
		if not result.is_empty():
			return result
	return []

func _outward(cell: int) -> int:
	for direction in range(4):
		if _neighbor(cell, direction) < 0:
			return direction
	return -1

func _board(begin: int, end: int) -> Array:
	var result: Array = []
	for _cell in range(16):
		result.append({})
	var begin_direction := _outward(begin)
	var end_direction := _outward(end)
	result[begin] = {"kind": "begin", "rotation": (begin_direction + 3) % 4 if begin_direction >= 0 else 3}
	result[end] = {"kind": "end", "rotation": end_direction if end_direction >= 0 else 2}
	return result

func _stock_conserved(game: Combat, totals: Dictionary) -> bool:
	for kind in KINDS:
		var installed := 0
		for piece in game.board:
			if piece.get("kind") == kind:
				installed += 1
		if installed > int(totals[kind]) or game.stock(kind) + installed != int(totals[kind]):
			return false
	return game.stock_totals == totals

func _edit(game: Combat, command: String, arguments: Dictionary, totals: Dictionary) -> bool:
	var result := game.execute(command, arguments)
	return result.accepted and result.events.is_empty() and _stock_conserved(game, totals)

func _rotate_to(game: Combat, cell: int, rotation: int, totals: Dictionary) -> bool:
	for _step in range(4):
		if int(game.board[cell].get("rotation", 0)) == rotation:
			return true
		if not _edit(game, "rotate", {"index": cell}, totals):
			return false
	return int(game.board[cell].rotation) == rotation

func _ports_match(game: Combat, cell: int, input: int, output: int) -> bool:
	var ports := Circuit.ports(game.board[cell])
	return ports.input == [input] and ports.output == [output]

func _place_connector(game: Combat, cell: int, input: int, output: int, totals: Dictionary, counts: Dictionary) -> bool:
	var straight := output == (input + 2) % 4
	var kind := "straight" if straight else "corner"
	# Straight direction can use either representation. Alternating it ensures
	# that the actual Flip command is exercised for both wire shapes.
	var reversed: bool = (cell % 2 == 0) if straight else output == (input + 1) % 4
	var rotation := (input + 3) % 4 if straight and reversed else (input + 1) % 4
	if not straight and reversed:
		rotation = (input + 2) % 4
	if not _edit(game, "place_wire", {"index": cell, "kind": kind}, totals) or not _rotate_to(game, cell, rotation, totals):
		return false
	if reversed:
		if not _edit(game, "flip", {"index": cell}, totals):
			return false
		counts.flips += 1
	return _ports_match(game, cell, input, output)

func _snapshot_without_feedback(game: Combat) -> Dictionary:
	var snapshot := game.snapshot()
	snapshot.erase("log_text")
	return snapshot

func _empty_cell(game: Combat) -> int:
	for cell in range(16):
		if game.board[cell].is_empty():
			return cell
	return -1

func _exercise_pair(source: Dictionary, totals: Dictionary, path: Array, counts: Dictionary) -> String:
	var setup := source.duplicate(true)
	# Choose a test seed whose first natural kit matches the case. This search is
	# QA-only, before construction; production still selects once without rerolls.
	var test_seed := 0
	var probe := RandomNumberGenerator.new()
	while test_seed < 100:
		probe.seed = test_seed ^ 0x52434B49
		if ProductionRules.select_kit(setup.production.kits, probe).totals == totals:
			break
		test_seed += 1
	if test_seed == 100:
		return "no bounded test seed supplies this kit"
	# Supply exactly one permanent Spark with a normal draw; this is deliberately
	# a geometry test, independent of random opening-hand usefulness.
	setup.owned_cards = ["spark"]
	setup.opening_draw = 1
	setup.encounter.draw_per_turn = 1
	var game := Combat.new(setup, test_seed)
	game.board = _board(path[0], path[-1])
	var card_rng := game.rng.state
	var endpoint_rng := game.endpoint_rng.state
	var kit_rng := game.kit_rng.state
	var initial_energy := game.energy
	var initial_hp := game.player_hp
	var begin_outward := _outward(path[0]) >= 0
	var end_outward := _outward(path[-1]) >= 0
	if (begin_outward or end_outward) and game.forecast().valid:
		return "outward starting port was incorrectly valid"
	if not _stock_conserved(game, totals):
		return "initial finite stock was not conserved"
	if not _rotate_to(game, path[0], (_direction(path[0], path[1]) + 3) % 4, totals) or not _rotate_to(game, path[-1], _direction(path[-1], path[-2]), totals):
		return "endpoint Rotate failed"
	var rune_at := -1
	for offset in range(1, path.size() - 1):
		if _direction(path[offset - 1], path[offset]) == _direction(path[offset], path[offset + 1]):
			rune_at = offset
			break
	if rune_at < 1:
		return "search returned a path without a straight rune socket"
	var rune_uid := -1
	for card in game.hand:
		if card.id == "spark":
			rune_uid = int(card.uid)
			break
	if rune_uid < 0:
		return "QA fixture did not supply its explicit Spark"
	# Install the rune first so its replaced wire returns to stock before the
	# rest of a route that may require the kit's entire straight allowance.
	var rune_cell: int = path[rune_at]
	var rune_input := _direction(rune_cell, path[rune_at - 1])
	var rune_output := _direction(rune_cell, path[rune_at + 1])
	var before_stock := game.stock("straight")
	if not _edit(game, "place_wire", {"index": rune_cell, "kind": "straight"}, totals) or not _rotate_to(game, rune_cell, (rune_input + 1) % 4, totals):
		return "rune's temporary straight placement failed"
	if game.stock("straight") != before_stock - 1 or not _edit(game, "place_rune", {"index": rune_cell, "uid": rune_uid}, totals):
		return "rune replacement did not reserve its temporary wire"
	if game.stock("straight") != before_stock or not _ports_match(game, rune_cell, rune_input, rune_output):
		return "rune replacement did not return the displaced straight or preserve correct ports"
	for offset in range(1, path.size() - 1):
		if offset == rune_at:
			continue
		var cell: int = path[offset]
		if not _place_connector(game, cell, _direction(cell, path[offset - 1]), _direction(cell, path[offset + 1]), totals, counts):
			return "connector placement/Rotate/Flip failed at %d" % cell
	var forecast := game.forecast()
	if not forecast.valid or forecast.damage != int(game.catalog.spark.value) or forecast.active.size() != path.size():
		return "command-built route did not carry the supplied Spark to End"
	var route_board := game.board.duplicate(true)
	var extras: Array = []
	# Ten connectors + two endpoints + one rune fit in thirteen cells. Remaining
	# pieces can all be installed off-route; every type must still obey its cap.
	for kind in KINDS:
		while game.stock(kind) > 0:
			var cell := _empty_cell(game)
			if cell < 0 or not _edit(game, "place_wire", {"index": cell, "kind": kind}, totals):
				return "disconnected %s stock could not be installed" % kind
			extras.append(cell)
		var exhausted := _snapshot_without_feedback(game)
		var rejected := game.execute("place_wire", {"index": _empty_cell(game), "kind": kind})
		if rejected.accepted or not rejected.events.is_empty() or _snapshot_without_feedback(game) != exhausted:
			return "exhausted %s placement mutated gameplay" % kind
	for cell in extras:
		if not _edit(game, "place_wire", {"index": cell, "kind": "erase"}, totals):
			return "erasing disconnected pieces did not return stock"
	if game.board != route_board or not game.forecast().valid:
		return "erasing disconnected extras did not restore the original route"
	if game.rng.state != card_rng or game.endpoint_rng.state != endpoint_rng or game.kit_rng.state != kit_rng or game.energy != initial_energy or game.player_hp != initial_hp or game.turn != 1:
		return "editing/rejection changed RNG, energy, health or turn"
	counts.pairs += 1
	if _direction(path[0], path[-1]) >= 0:
		counts.adjacent += 1
	if begin_outward:
		counts.begin_outward += 1
	if end_outward:
		counts.end_outward += 1
	return ""
