extends RefCounted

# Automated contract checks only; no participant records are read or written.
# Detached board/setup overrides exercise all cell pairs and terminal states.
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Record = preload("res://scripts/core/experiment_record.gd")

func run(check: Callable) -> void:
	var loaded := Experiments.load_setup("effects", "free_endpoints", 42)
	check.call(loaded.ok, "Free endpoints validates as a separately versioned follow-up.")
	if not loaded.ok:
		return
	_validation(check)
	_pair_domain_and_routes(check, loaded.setup)
	_rotation_and_protection(check, loaded.setup)
	_cleanup(check, loaded.setup)
	_terminal_and_rejection(check, loaded.setup)
	_randomness_and_replay(check, loaded.setup)
	_isolation(check)

func _endpoints(board: Array) -> Dictionary:
	var result := {}
	for index in range(board.size()):
		if board[index].get("kind") in ["begin", "end"]:
			result[board[index].kind] = {"cell": index, "rotation": int(board[index].get("rotation", 0))}
	return result

func _empty_board(begin: int, end: int, begin_rotation: int = 0, end_rotation: int = 0) -> Array:
	var result: Array = []
	for _cell in range(16):
		result.append({})
	result[begin] = {"kind": "begin", "rotation": begin_rotation}
	result[end] = {"kind": "end", "rotation": end_rotation}
	return result

func _only_endpoints(board: Array) -> bool:
	return board.size() == 16 and board.filter(func(piece): return piece.get("kind") == "begin").size() == 1 and board.filter(func(piece): return piece.get("kind") == "end").size() == 1 and board.filter(func(piece): return not piece.is_empty()).size() == 2

func _uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id:
			return int(card.uid)
	return -1

func _permanents(game: Combat) -> Array:
	var result: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].get("temporary", false):
			result.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].get("temporary", false):
			result.append({"id": piece.rune_id, "uid": piece.uid})
	result.sort_custom(func(a, b): return a.uid < b.uid)
	return result

func _same_gameplay(first: Dictionary, second: Dictionary) -> bool:
	var a := first.duplicate(true)
	var b := second.duplicate(true)
	a.erase("log_text")
	b.erase("log_text")
	return a == b

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _changes(result: Dictionary) -> Array:
	return result.events.filter(func(event): return event.type == "endpoints_changed")

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

func _straight_socket(path: Array) -> int:
	for index in range(1, path.size() - 1):
		if _direction(path[index - 1], path[index]) == _direction(path[index], path[index + 1]):
			return index
	return -1

# Independent DFS on grid adjacency, not a production path/solution helper.
func _find_path(path: Array, end: int) -> Array:
	var current: int = path.back()
	if current == end:
		return path if _straight_socket(path) > 0 else []
	for direction in range(4):
		var next := _neighbor(current, direction)
		if next < 0 or path.has(next):
			continue
		var extended := path.duplicate()
		extended.append(next)
		var result := _find_path(extended, end)
		if not result.is_empty():
			return result
	return []

func _rotate_to(game: Combat, cell: int, rotation: int) -> bool:
	for _step in range(4):
		if int(game.board[cell].get("rotation", 0)) == rotation:
			return true
		if not game.rotate(cell):
			return false
	return int(game.board[cell].rotation) == rotation

func _build(game: Combat, rune_uid: int = -1) -> bool:
	var endpoints := _endpoints(game.board)
	var path := _find_path([endpoints.begin.cell], endpoints.end.cell)
	if path.is_empty():
		return false
	if not _rotate_to(game, path[0], (_direction(path[0], path[1]) + 3) % 4) or not _rotate_to(game, path[-1], _direction(path[-1], path[-2])):
		return false
	var rune_at := _straight_socket(path)
	for offset in range(1, path.size() - 1):
		var index: int = path[offset]
		var input := _direction(index, path[offset - 1])
		var output := _direction(index, path[offset + 1])
		var chosen := {}
		for kind in ["straight", "corner"]:
			for rotation in range(4):
				for reversed in [false, true]:
					var candidate := {"kind": kind, "rotation": rotation, "reversed": reversed}
					var ports := Circuit.ports(candidate)
					if ports.input == [input] and ports.output == [output]:
						chosen = candidate
		if chosen.is_empty() or not game.place_wire(index, chosen.kind) or not _rotate_to(game, index, chosen.rotation):
			return false
		if chosen.reversed and not game.execute("flip", {"index": index}).accepted:
			return false
		if offset == rune_at and rune_uid >= 0:
			if not game.place_rune(index, rune_uid) or not _rotate_to(game, index, (input + 1) % 4):
				return false
	return game.forecast().valid and game.forecast().cost <= game.energy

func _validation(check: Callable) -> void:
	var source := Experiments.documents("effects", "free_endpoints", 42)
	var untouched := source.duplicate(true)
	var cases := [
		["old version", func(options): options.version = "rc006_moving_endpoints_v1"],
		["missing endpoint policy", func(options): options.erase("endpoint_policy")],
		["fixed endpoint policy", func(options): options.endpoint_policy = "fixed"],
		["missing manual rotation", func(options): options.erase("endpoint_rotation")],
		["locked rotation", func(options): options.endpoint_rotation = "locked"],
		["fixed opening", func(options): options.endpoint_initial = "fixed"],
		["unversioned selection", func(options): options.endpoint_selection = "random"],
		["incomplete initial pair domain", func(options): options.endpoint_position_pairs = 239],
		["incomplete successor domain", func(options): options.endpoint_successor_pairs = 210],
		["missing full reset", func(options): options.erase("board_reset")],
		["retained effects", func(options): options.effects = "persistent"],
		["retained temporary wire", func(options): options.expiry = "straight"],
		["encounter transfer", func(options): options.transfer = "retain"],
		["extraneous geometry catalog", func(options): options.endpoint_layouts = []]
	]
	for entry in cases:
		var context: Dictionary = source.experiment.duplicate(true)
		entry[1].call(context)
		var before := context.duplicate(true)
		var invalid := Loader.validate_documents(source.documents, {}, context)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty() and context == before and source == untouched, "Free endpoint validation rejects %s without changing inputs or returning a partial setup." % entry[0])
	for entry in [
		["preinstalled wire", func(data): data.boards[0].placements.append({"cell": 5, "kind": "straight"})],
		["extra endpoint", func(data): data.boards[0].placements.append({"cell": 4, "kind": "end"})],
		["mismatched seed", func(data): data.encounter.seed = 7],
		["embedded endpoint policy", func(data): data.encounter.endpoint_policy = "random_any_cells"]
	]:
		var data: Dictionary = source.documents.duplicate(true)
		entry[1].call(data)
		var before := data.duplicate(true)
		var invalid := Loader.validate_documents(data, {}, source.experiment)
		check.call(not invalid.ok and invalid.setup.is_empty() and data == before and source == untouched, "Free endpoint validation rejects %s without source mutation." % entry[0])
	check.call(Loader.validate_documents(source.documents, {}, source.experiment).ok, "Malformed free-endpoint cases leave the original documents valid.")

func _pair_domain_and_routes(check: Callable, setup: Dictionary) -> void:
	var pairs := Loader.free_endpoint_pairs()
	var expected: Array = []
	for begin in range(16):
		for end in range(16):
			if begin != end:
				expected.append([begin, end])
	check.call(pairs.size() == 240 and pairs == expected, "Initial selection includes all 240 distinct ordered pairs, without adjacency, edge or corner exclusions.")
	var all_successors := true
	var all_routes := true
	var all_rotations := true
	var adjacency := {"horizontal": 0, "vertical": 0, "corner": 0}
	var failures: Array = []
	for pair in pairs:
		var successors := Loader.free_endpoint_pairs(pair[0], pair[1])
		var valid_successors: Array = expected.filter(func(candidate): return candidate[0] != pair[0] and candidate[1] != pair[1])
		all_successors = successors.size() == 211 and successors == valid_successors and successors.has([pair[1], pair[0]]) and all_successors
		var game := Combat.new(setup)
		game.board = _empty_board(pair[0], pair[1], 3, 2)
		var card_rng := game.rng.state
		var endpoint_rng := game.endpoint_rng.state
		var built := _build(game, _uid(game, "spark"))
		var forecast := game.forecast()
		all_routes = built and forecast.valid and forecast.damage == 6 and forecast.cost == 2 and all_routes
		all_rotations = game.endpoint_rng.state == endpoint_rng and game.rng.state == card_rng and all_rotations
		if not built or forecast.damage != 6 or forecast.cost != 2:
			failures.append(pair)
		var direction := _direction(pair[0], pair[1])
		if direction >= 0:
			adjacency["horizontal" if direction % 2 == 1 else "vertical"] += 1
			if pair[0] in [0, 3, 12, 15] or pair[1] in [0, 3, 12, 15]:
				adjacency.corner += 1
	check.call(all_successors, "Every one of 240 pairs has exactly 211 equally eligible distinct successors moving both endpoints, including their cross-swap.")
	check.call(all_routes, "Independent search builds a directed affordable Spark route by ordinary rotation/placement for all 240 ordered pairs. Failures: %s" % str(failures))
	check.call(adjacency.horizontal == 24 and adjacency.vertical == 24 and adjacency.corner == 16, "The exhaustive rune-capable route check includes both directions of all horizontal/vertical adjacencies and corner-adjacent pairs.")
	check.call(all_rotations, "Constructing and orienting every pair never consumes card or endpoint randomness.")
	pairs.clear()
	check.call(Loader.free_endpoint_pairs().size() == 240, "Caller mutation of the pair list cannot narrow future selections.")
	var direct_valid := true
	for pair in [[0, 1], [1, 0], [0, 4], [4, 0], [14, 15], [15, 11]]:
		var game := Combat.new(setup)
		var direction := _direction(pair[0], pair[1])
		game.board = _empty_board(pair[0], pair[1], (direction + 3) % 4, (direction + 2) % 4)
		var expected_spell := Circuit.evaluate(game.board, game.catalog, Experiments.load_setup("endpoints", "treatment", 42).setup.experiment)
		var spell := game.forecast()
		var result := game.execute("cast")
		direct_valid = expected_spell.valid and spell.valid and spell.damage == 0 and spell.cost == 0 and result.accepted and _changes(result).size() == 1 and direct_valid
	check.call(direct_valid, "Direct adjacent Begin-to-End circuits retain base evaluation: valid zero-damage, zero-cost casts, followed by ordinary turn cleanup/movement.")
	var witness := Combat.new(setup)
	var accepted := true
	for action in Experiments.known_solution_actions("effects", "free_endpoints", 42):
		accepted = witness.execute(action.command, action.arguments).accepted and accepted
	check.call(accepted and witness.forecast().valid and witness.forecast().damage == 6 and witness.forecast().cost == 2, "Seed-42 facilitator commands solve the actual randomized opening without entering player-facing instructions.")

func _rotation_and_protection(check: Callable, setup: Dictionary) -> void:
	var game := Combat.new(setup)
	var original := _endpoints(game.board)
	check.call(setup.experiment.version == "rc006_free_endpoints_v1" and setup.experiment.endpoint_rotation == "player" and setup.experiment.endpoint_initial == "random" and _only_endpoints(game.board), "The new experiment opens with only its separately versioned randomized, player-rotatable endpoints.")
	for kind in ["begin", "end"]:
		var cell: int = original[kind].cell
		var before := game.snapshot()
		var history := game.history.duplicate(true)
		var card_rng := game.rng.state
		var endpoint_rng := game.endpoint_rng.state
		var rotated := game.execute("rotate", {"index": cell})
		check.call(rotated.accepted and int(game.board[cell].rotation) == (int(before.board[cell].rotation) + 1) % 4 and game.history.size() == history.size() + 1, "%s supports the ordinary one-quarter-turn command and records one Undo step." % kind)
		check.call(game.hand == before.hand and game.draw_pile == before.draw_pile and game.discard_pile == before.discard_pile and game.energy == before.energy and game.rng.state == card_rng and game.endpoint_rng.state == endpoint_rng and _endpoints(game.board)[kind].cell == cell, "%s rotation changes no cards, energy, position or random stream." % kind)
		check.call(game.execute("undo").accepted and game.snapshot() == before and game.history == history, "Undo restores the exact %s orientation and earlier history." % kind)
		var all_rotated := true
		for _quarter in range(4):
			all_rotated = game.rotate(cell) and all_rotated
		check.call(all_rotated and game.board == before.board and game.rng.state == card_rng and game.endpoint_rng.state == endpoint_rng, "Four %s rotations return to the original direction without rerolling." % kind)
	var protected := true
	var before := game.snapshot()
	var history := game.history.duplicate(true)
	for endpoint in [original.begin.cell, original.end.cell]:
		for kind in ["straight", "corner", "split", "join", "erase"]:
			protected = not game.execute("place_wire", {"index": endpoint, "kind": kind}).accepted and protected
		protected = not game.execute("place_rune", {"index": endpoint, "uid": _uid(game, "spark")}).accepted and not game.execute("flip", {"index": endpoint}).accepted and protected
	check.call(protected and _same_gameplay(before, game.snapshot()) and game.history == history, "Rotatable endpoints remain protected from erasure, all wire replacements, rune placement and Flip.")
	var invalid := true
	for index in [-1, 16]:
		invalid = not game.execute("rotate", {"index": index}).accepted and invalid
	check.call(invalid and _same_gameplay(before, game.snapshot()), "Out-of-range endpoint rotation requests remain rejected without gameplay changes.")
	game = Combat.new(setup)
	game.board = _empty_board(0, 15, 2, 1)
	check.call(not game.forecast().valid and game.rotate(0) and game.rotate(15), "Outward-facing corner endpoints may temporarily be invalid and still accept manual rotation.")
	for _step in range(40):
		game.rotate(0)
	var undone := 0
	while game.execute("undo").accepted:
		undone += 1
	check.call(undone == 32 and game.history.is_empty(), "Endpoint rotation uses the existing bounded 32-step Undo history without expanding it.")

func _cleanup(check: Callable, source: Dictionary) -> void:
	var setup := source.duplicate(true)
	setup.owned_cards = ["spark", "shield", "conjure", "conjure"]
	setup.opening_hand = setup.owned_cards.duplicate()
	setup.opening_draw = 0
	var probe := Combat.new(setup)
	var destination := _endpoints(probe.execute("pass").after.board)
	var game := Combat.new(setup)
	var old := _endpoints(game.board)
	var owned := _permanents(game)
	var targets: Array = [destination.begin.cell, destination.end.cell].filter(func(cell): return cell not in [old.begin.cell, old.end.cell])
	check.call(not targets.is_empty(), "Cleanup witness has a new endpoint destination that currently accepts a card.")
	if targets.is_empty():
		return
	var cells: Array = []
	for cell in range(16):
		if cell not in [old.begin.cell, old.end.cell, targets[0]]:
			cells.append(cell)
	var permanent_uid := _uid(game, "spark")
	var prepared := game.place_rune(targets[0], permanent_uid) and game.play_technique(_uid(game, "conjure")) and game.place_rune(cells[0], _uid(game, "free_spark")) and game.play_technique(_uid(game, "conjure")) and game.place_wire(cells[1], "split") and game.place_wire(cells[2], "join")
	check.call(prepared and _uid(game, "free_spark") >= 0, "Witness includes a future-endpoint permanent, disconnected board/hand temporaries and both special connectors.")
	var result := game.execute("pass")
	var changes := _changes(result)
	var consumed: Array = result.events.filter(func(event): return event.type == "effect_consumed")
	var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
	var cleanup: Array = result.events.filter(func(event): return event.type == "turn_cleanup")
	check.call(result.accepted and changes.size() == 1 and consumed.size() == 1 and consumed[0].card.uid == permanent_uid and consumed[0].to == "discard" and consumed[0].after == {} and consumed[0].sequence < changes[0].sequence, "A permanent at a newly chosen endpoint is discarded exactly once before placing that endpoint.")
	check.call(expired.size() == 1 and expired[0].cell == cells[0] and expired[0].after == {} and cleanup.size() == 1 and cleanup[0].expired.size() == 1, "Disconnected board and unused hand temporary runes both disappear at turn cleanup.")
	check.call(_only_endpoints(game.board) and _endpoints(game.board) == destination and _permanents(game) == owned and game.stock("split") == 1 and game.stock("join") == 1, "Pass leaves only the new endpoints, restores supplies and conserves every permanent instance.")
	check.call(not (game.hand + game.draw_pile + game.discard_pile).any(func(card): return game.catalog[card.id].get("temporary", false)) and game.hand.size() == 3, "Normal next-turn drawing cannot retain temporary instances or bypass the configured hand draw.")
	var types := _types(result)
	check.call(types.find("retaliation") < types.find("turn_cleanup") and types.find("turn_cleanup") < types.find("endpoints_changed") and types.find("endpoints_changed") < types.find("turn_started") and types.find("turn_started") < types.find("card_drawn"), "Retaliation, cleanup, endpoint movement, turn start and draws remain ordered.")
	var after := game.snapshot()
	check.call(not game.execute("undo").accepted and game.snapshot() == after, "Undo cannot restore the previous turn's endpoints, cards or circuit.")
	var editable := true
	for cell in [old.begin.cell, old.end.cell]:
		if cell not in [destination.begin.cell, destination.end.cell]:
			editable = game.place_wire(cell, "straight") and editable
	check.call(editable, "Vacated Begin and End cells accept normal circuit pieces.")
	game = Combat.new(source)
	owned = _permanents(game)
	check.call(_build(game, _uid(game, "spark")), "Cast cleanup witness builds a rune-capable circuit through rotated endpoints.")
	var prediction := game.forecast()
	var hp := game.enemy_hp
	result = game.execute("cast")
	check.call(result.accepted and prediction.damage == 6 and game.enemy_hp == hp - prediction.damage and _changes(result).size() == 1 and _only_endpoints(game.board) and _permanents(game) == owned, "Accepted Cast resolves predicted damage then clears cards/wires and relocates endpoints without losing ownership.")

func _terminal_and_rejection(check: Callable, source: Dictionary) -> void:
	var game := Combat.new(source)
	game.board = _empty_board(0, 15, 2, 1)
	var before := game.snapshot()
	var endpoint_rng := game.endpoint_rng.state
	var card_rng := game.rng.state
	var result := game.execute("cast")
	check.call(not result.accepted and result.events.is_empty() and _same_gameplay(before, game.snapshot()) and game.endpoint_rng.state == endpoint_rng and game.rng.state == card_rng, "An invalid outward-facing Cast does not clear, draw or move endpoints.")
	check.call(_build(game, _uid(game, "spark")), "Manual rotation can recover an initially outward-facing pair into a valid Spark circuit.")
	game.energy = 0
	before = game.snapshot()
	var history := game.history.duplicate(true)
	result = game.execute("cast")
	check.call(not result.accepted and result.events.is_empty() and _same_gameplay(before, game.snapshot()) and game.history == history and game.endpoint_rng.state == endpoint_rng and game.rng.state == card_rng, "An unaffordable Cast preserves rotations, circuit, history, cards and both RNG streams.")
	for outcome in ["victory", "defeat"]:
		game = Combat.new(source)
		var prepared := _build(game, _uid(game, "spark"))
		if outcome == "victory":
			game.enemy_hp = 6
		else:
			game.player_hp = 1
		var endpoints := _endpoints(game.board)
		var owned := _permanents(game)
		endpoint_rng = game.endpoint_rng.state
		card_rng = game.rng.state
		result = game.execute("cast" if outcome == "victory" else "pass")
		check.call(prepared and result.accepted and game.state == outcome and _only_endpoints(game.board) and _endpoints(game.board) == endpoints and _permanents(game) == owned and game.hand.is_empty(), "Terminal %s clears installed runes and hand but keeps the final manually oriented endpoints." % outcome)
		check.call(_changes(result).is_empty() and not _types(result).has("turn_started") and not _types(result).has("card_drawn") and game.endpoint_rng.state == endpoint_rng and game.rng.state == card_rng, "Terminal %s neither chooses a new pair nor starts/draws another turn." % outcome)
		before = game.snapshot()
		check.call(not game.execute("rotate", {"index": endpoints.begin.cell}).accepted and not game.execute("cast").accepted and not game.execute("pass").accepted and game.snapshot() == before, "Terminal %s rejects endpoint edits and repeated turn commands." % outcome)

func _randomness_and_replay(check: Callable, source: Dictionary) -> void:
	var setup := source.duplicate(true)
	setup.encounter.player_health = 1000
	setup.encounter.player_max_health = 1000
	setup.encounter.max_health = 1000
	var seen_pairs := {}
	var rotations := {"begin": {}, "end": {}}
	var initial_valid := true
	var adjacent := false
	var outward := false
	for seed in range(128):
		var seeded := Combat.new(setup, seed)
		var endpoints := _endpoints(seeded.board)
		var pair: Array = [endpoints.begin.cell, endpoints.end.cell]
		seen_pairs[str(pair)] = true
		rotations.begin[endpoints.begin.rotation] = true
		rotations.end[endpoints.end.rotation] = true
		initial_valid = Loader.free_endpoint_pairs().has(pair) and _only_endpoints(seeded.board) and initial_valid
		adjacent = _direction(pair[0], pair[1]) >= 0 or adjacent
		outward = _neighbor(pair[0], (1 + int(endpoints.begin.rotation)) % 4) < 0 or _neighbor(pair[1], endpoints.end.rotation) < 0 or outward
	check.call(initial_valid and seen_pairs.size() > 64 and rotations.begin.size() == 4 and rotations.end.size() == 4 and adjacent and outward, "Seed sweep samples diverse initial pairs, all four directions, adjacent endpoints and outward-facing endpoints without excluding them.")
	var first := Combat.new(setup)
	var second := Combat.new(setup)
	var reproducible := first.snapshot() == second.snapshot()
	var movement := true
	for turn_number in range(8):
		var old := _endpoints(first.board)
		if turn_number % 2 == 0:
			reproducible = _build(first) and _build(second) and reproducible
		var command := "cast" if turn_number % 2 == 0 else "pass"
		var left := first.execute(command)
		var right := second.execute(command)
		var current := _endpoints(first.board)
		movement = current.begin.cell != old.begin.cell and current.end.cell != old.end.cell and _changes(left).size() == 1 and movement
		reproducible = left.accepted and left == right and first.snapshot() == second.snapshot() and first.rng.state == second.rng.state and first.endpoint_rng.state == second.endpoint_rng.state and reproducible
	check.call(reproducible and first.turn == 9 and movement, "Exact seed/commands reproduce eight mixed Cast/Pass turns, endpoint rotation, draw/reshuffle order and matching movement events.")
	var fixed_setup: Dictionary = Experiments.load_setup("effects", "full_reset", 42).setup.duplicate(true)
	fixed_setup.encounter.player_health = 1000
	fixed_setup.encounter.player_max_health = 1000
	first = Combat.new(setup)
	var fixed := Combat.new(fixed_setup)
	var independent := first.hand == fixed.hand and first.draw_pile == fixed.draw_pile and first.rng.state == fixed.rng.state
	for _turn in range(8):
		first.execute("pass")
		fixed.execute("pass")
		independent = first.hand == fixed.hand and first.draw_pile == fixed.draw_pile and first.discard_pile == fixed.discard_pile and first.rng.state == fixed.rng.state and independent
	check.call(independent, "Randomizing opening and subsequent endpoints does not perturb ordinary card draws or reshuffles.")
	var technique_setup := setup.duplicate(true)
	technique_setup.owned_cards = ["conjure", "focus"]
	technique_setup.opening_hand = ["conjure", "focus"]
	technique_setup.opening_draw = 0
	var active := Combat.new(technique_setup)
	var passive := Combat.new(technique_setup)
	var endpoint_rng := active.endpoint_rng.state
	var techniques := active.play_technique(_uid(active, "conjure")) and active.play_technique(_uid(active, "focus"))
	check.call(techniques and active.rng.state != passive.rng.state and active.endpoint_rng.state == endpoint_rng, "Technique draws may reshuffle cards while preserving the endpoint RNG stream.")
	var same_geometry := true
	for _turn in range(3):
		active.execute("pass")
		passive.execute("pass")
		same_geometry = _endpoints(active.board) == _endpoints(passive.board) and active.endpoint_rng.state == passive.endpoint_rng.state and same_geometry
	check.call(same_geometry, "Extra card draws do not change the subsequent endpoint sequence.")
	var before := first.snapshot()
	endpoint_rng = first.endpoint_rng.state
	var expected := RandomNumberGenerator.new()
	expected.state = endpoint_rng
	expected.randi_range(0, 239)
	expected.randi_range(0, 3)
	expected.randi_range(0, 3)
	first.reset()
	check.call(first.endpoint_rng.state == expected.state and _only_endpoints(first.board) and first.turn == 1 and first.snapshot().encounter_id == before.encounter_id + 1, "Ordinary Restart continues endpoint RNG and chooses a new opening using the complete pair domain.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	check.call(first.snapshot() == second.snapshot() and first.endpoint_rng.state == second.endpoint_rng.state and first.execute("pass") == second.execute("pass"), "Fresh Exact replay restores both streams and the same random opening/next pair.")
	var clock := [1000]
	first = Combat.new(source)
	var record := Record.new(source, first.snapshot(), func(): return clock[0])
	var commands: Array = Experiments.known_solution_actions("effects", "free_endpoints", 42)
	commands.append({"command": "cast", "arguments": {}})
	commands.append({"command": "pass", "arguments": {}})
	for command in commands:
		clock[0] += 100
		record.record(first.execute(command.command, command.arguments), command.arguments)
	var document := record.document()
	second = Combat.new(document.starting_setup)
	var replayed: bool = document.initial_state.circuit.cells == second.board
	for command in document.commands:
		var result := second.execute(command.command, command.arguments)
		replayed = command.accepted == result.accepted and command.events == result.events and command.after.circuit.cells == second.board and command.after.hand.cards == second.hand and replayed
	check.call(replayed and first.snapshot() == second.snapshot() and document.experiment.version == "rc006_free_endpoints_v1" and record.summary().casts == 1 and record.summary().passes == 1, "An in-memory observation captures manual edits/new endpoint events and replays exactly without writing participant records.")

func _isolation(check: Callable) -> void:
	for variant in ["full_reset", "moving_endpoints"]:
		var game := Combat.new(Experiments.load_setup("effects", variant, 42).setup)
		var before := game.snapshot()
		var endpoints := _endpoints(game.board)
		var rejected := not game.rotate(endpoints.begin.cell) and not game.rotate(endpoints.end.cell)
		check.call(rejected and _same_gameplay(before, game.snapshot()) and not game.snapshot().experiment.has("endpoint_rotation"), "Existing effects/%s retains protected endpoint rotation and its original metadata." % variant)
	for variant in ["control", "treatment"]:
		var game := Combat.new(Experiments.load_setup("effects", variant, 42).setup)
		var result := game.execute("cast")
		check.call(result.accepted and game.board[2].get("kind") == "split" and game.board[8].get("rune_id") == "shield" and _changes(result).is_empty(), "Legacy effects/%s retains its original cleanup and fixed endpoint behavior." % variant)
	var normal := Combat.new(Loader.load_setup().setup)
	check.call(not normal.rotate(0) and not normal.rotate(14) and not normal.snapshot().has("experiment") and normal.cast() and normal.board[2].get("kind") == "split", "Normal gameplay remains outside manual endpoint rotation, random placement and full-reset rules.")
