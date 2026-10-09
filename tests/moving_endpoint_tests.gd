extends RefCounted

# Automated follow-up checks, never participant evidence. Detached overrides
# below make terminal and catalog boundaries reachable without writing records.
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func run(check: Callable) -> void:
	var loaded := Experiments.load_setup("effects", "moving_endpoints", 42)
	check.call(loaded.ok, "Moving endpoints validates as a separate opt-in follow-up.")
	if not loaded.ok:
		return
	_validation(check)
	_catalog(check, loaded.setup)
	_initial_and_commands(check, loaded.setup)
	_cleanup_before_movement(check, loaded.setup)
	_terminal(check, loaded.setup)
	_replay_and_rng(check, loaded.setup)
	_isolation(check, loaded.setup)

func _endpoints(board: Array) -> Dictionary:
	var result := {}
	for index in range(board.size()):
		if board[index].get("kind") in ["begin", "end"]:
			result[board[index].kind] = {"cell": index, "rotation": int(board[index].get("rotation", 0))}
	return result

func _empty_between_endpoints(board: Array) -> bool:
	return board.size() == 16 and board.filter(func(piece): return piece.get("kind") == "begin").size() == 1 and board.filter(func(piece): return piece.get("kind") == "end").size() == 1 and board.filter(func(piece): return not piece.is_empty()).size() == 2

func _endpoint_board(layout: Dictionary) -> Array:
	var result: Array = []
	for _cell in range(16):
		result.append({})
	result[int(layout.begin.cell)] = {"kind": "begin", "rotation": int(layout.begin.rotation)}
	result[int(layout.end.cell)] = {"kind": "end", "rotation": int(layout.end.rotation)}
	return result

func _permanents(game: Combat) -> Array:
	var result: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].get("temporary", false):
			result.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].get("temporary", false):
			result.append({"id": piece.rune_id, "uid": piece.uid})
	result.sort_custom(func(first, second): return first.uid < second.uid)
	return result

func _uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id:
			return int(card.uid)
	return -1

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _endpoint_events(result: Dictionary) -> Array:
	return result.events.filter(func(event): return event.type == "endpoints_changed")

func _same_except_log(first: Dictionary, second: Dictionary) -> bool:
	var a := first.duplicate(true)
	var b := second.duplicate(true)
	a.erase("log_text")
	b.erase("log_text")
	return a == b

func _long_setup(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result.encounter.player_health = 1000
	result.encounter.player_max_health = 1000
	result.encounter.max_health = 1000
	return result

# Independent search uses only the displayed endpoint ports and a four-by-four
# grid. It does not consume the production catalog's stored solution paths.
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

func _search_path(path: Array, end: int, end_input: int) -> Array:
	var current: int = path.back()
	if current == end:
		return path if _direction(end, path[-2]) == end_input and _straight_socket(path) > 0 else []
	for direction in range(4):
		var next := _neighbor(current, direction)
		if next < 0 or path.has(next):
			continue
		var extended := path.duplicate()
		extended.append(next)
		var result := _search_path(extended, end, end_input)
		if not result.is_empty():
			return result
	return []

func _path_for(board: Array) -> Array:
	var endpoints := _endpoints(board)
	if not endpoints.has("begin") or not endpoints.has("end"):
		return []
	var first := _neighbor(endpoints.begin.cell, (1 + int(endpoints.begin.rotation)) % 4)
	if first < 0 or first == endpoints.end.cell:
		return []
	return _search_path([endpoints.begin.cell, first], endpoints.end.cell, endpoints.end.rotation)

func _build(game: Combat, rune_uid: int = -1) -> bool:
	var path := _path_for(game.board)
	if path.is_empty():
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
		if chosen.is_empty() or not game.place_wire(index, chosen.kind):
			return false
		for _rotation in range(chosen.rotation):
			if not game.rotate(index):
				return false
		if chosen.reversed and not game.execute("flip", {"index": index}).accepted:
			return false
		if offset == rune_at and rune_uid >= 0:
			if not game.place_rune(index, rune_uid):
				return false
			# Rune cards have directed straight ports but cannot be flipped.
			while Circuit.ports(game.board[index]).input != [input]:
				if not game.rotate(index):
					return false
	return game.forecast().valid and game.forecast().cost <= game.energy

func _validation(check: Callable) -> void:
	var source := Experiments.documents("effects", "moving_endpoints", 42)
	var original := source.duplicate(true)
	var modifications := [
		["old full-reset version", func(options): options.version = "rc006_full_reset_v1"],
		["missing endpoint policy", func(options): options.erase("endpoint_policy")],
		["unknown endpoint policy", func(options): options.endpoint_policy = "random_on_edit"],
		["missing layout catalog", func(options): options.erase("endpoint_layouts")],
		["empty layout catalog", func(options): options.endpoint_layouts = []],
		["non-array layout catalog", func(options): options.endpoint_layouts = {}],
		["mutated endpoint cell", func(options): options.endpoint_layouts[0].begin.cell = 5],
		["mutated endpoint rotation", func(options): options.endpoint_layouts[0].end.rotation = 1],
		["mutated route path", func(options): options.endpoint_layouts[0].path[1] = 5],
		["incomplete layout", func(options): options.endpoint_layouts[0].erase("end")],
		["unknown catalog entry field", func(options): options.endpoint_layouts[0].weight = 9],
		["duplicate catalog entry", func(options): options.endpoint_layouts.append(options.endpoint_layouts[0].duplicate(true))],
		["missing board reset", func(options): options.erase("board_reset")],
		["persistent effects", func(options): options.effects = "persistent"],
		["retained temporary wire", func(options): options.expiry = "retained"],
		["encounter transfer", func(options): options.transfer = "retain"]
	]
	for entry in modifications:
		var context: Dictionary = source.experiment.duplicate(true)
		entry[1].call(context)
		var before := context.duplicate(true)
		var invalid := Loader.validate_documents(source.documents, {}, context)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty() and context == before and source == original, "Moving endpoint validation rejects %s without mutation or partial setup." % entry[0])
	var board_cases := [
		["preinstalled wire", func(data): data.boards[0].placements.append({"cell": 5, "kind": "straight"})],
		["alternate opening Begin", func(data): data.boards[0].placements[0].cell = 4],
		["rotated opening End", func(data): data.boards[0].placements[1].rotation = 1],
		["extra endpoint", func(data): data.boards[0].placements.append({"cell": 4, "kind": "begin"})],
		["mismatched encounter seed", func(data): data.encounter.seed = 7],
		["embedded endpoint rule", func(data): data.encounter.endpoint_policy = "random_each_turn"]
	]
	for entry in board_cases:
		var data: Dictionary = source.documents.duplicate(true)
		entry[1].call(data)
		var before := data.duplicate(true)
		var invalid := Loader.validate_documents(data, {}, source.experiment)
		check.call(not invalid.ok and invalid.setup.is_empty() and data == before and source == original, "Moving endpoint validation rejects %s while preserving source inputs." % entry[0])
	check.call(Loader.validate_documents(source.documents, {}, source.experiment).ok, "The original versioned moving endpoint source remains valid after malformed-case checks.")

func _catalog(check: Callable, setup: Dictionary) -> void:
	var layouts := Loader.moving_endpoint_layouts()
	check.call(layouts.size() >= 4 and layouts.size() <= 32 and layouts == setup.experiment.endpoint_layouts, "The endpoint catalog is bounded, nontrivial and captured in explicit experiment metadata.")
	var keys := {}
	var orientations := {}
	var route_lengths := {}
	var all_valid := true
	var all_transitions := true
	var transition_count := 0
	for layout in layouts:
		var board := _endpoint_board(layout)
		var path := _path_for(board)
		var key := str(_endpoints(board))
		all_valid = not keys.has(key) and not path.is_empty() and _empty_between_endpoints(board) and all_valid
		keys[key] = true
		orientations[str([layout.begin.rotation, layout.end.rotation])] = true
		route_lengths[layout.path.size()] = true
		var game := Combat.new(setup)
		game.board = board
		check.call(_build(game, _uid(game, "spark")) and game.forecast().damage == 6 and game.forecast().cost == 2, "Catalog %s supports an independently discovered directed circuit with an affordable straight Spark socket." % layout.id)
		var expected := {}
		for next_layout in layouts:
			if next_layout.begin.cell != layout.begin.cell and next_layout.end.cell != layout.end.cell:
				expected[next_layout.id] = true
		var seen := {}
		for seed in range(128):
			game = Combat.new(setup)
			game.board = _endpoint_board(layout)
			game.endpoint_rng.seed = seed
			var result := game.execute("pass")
			var changes := _endpoint_events(result)
			if not result.accepted or changes.size() != 1:
				all_transitions = false
				continue
			var change: Dictionary = changes[0]
			seen[change.after.layout_id] = true
			all_transitions = expected.has(change.after.layout_id) and change.before.begin.cell == layout.begin.cell and change.before.end.cell == layout.end.cell and change.after.begin.cell != layout.begin.cell and change.after.end.cell != layout.end.cell and _endpoints(game.board) == {"begin": change.after.begin, "end": change.after.end} and _empty_between_endpoints(game.board) and not _path_for(game.board).is_empty() and all_transitions
			if seen.size() == expected.size():
				break
		transition_count += seen.size()
		check.call(not expected.is_empty() and seen.size() == expected.size(), "Catalog %s has reachable successors and the bounded seed sweep covers every permitted destination." % layout.id)
	check.call(all_valid and orientations.size() > 1 and route_lengths.size() > 1, "Catalog entries are unique, solvable and vary endpoint orientation and route length.")
	check.call(all_transitions and transition_count >= layouts.size(), "Every observed catalog transition changes both endpoint cells, remains solvable and emits matching endpoint metadata.")
	layouts[0].begin.cell = 5
	layouts[0].path.clear()
	check.call(Loader.moving_endpoint_layouts() == setup.experiment.endpoint_layouts, "Caller mutations cannot alter the catalog used by future turns or exported metadata.")

func _initial_and_commands(check: Callable, setup: Dictionary) -> void:
	var game := Combat.new(setup)
	var initial := _endpoints(game.board)
	check.call(setup.experiment.version == "rc006_moving_endpoints_v1" and setup.experiment.endpoint_policy == "random_each_turn" and initial == {"begin": {"cell": 0, "rotation": 0}, "end": {"cell": 14, "rotation": 0}} and _empty_between_endpoints(game.board), "The moving follow-up begins at the same empty 0/14 geometry under its own version.")
	var rng_before: int = game.endpoint_rng.state
	var before := game.snapshot()
	var rejected := game.execute("cast")
	check.call(not rejected.accepted and rejected.events.is_empty() and _same_except_log(before, game.snapshot()) and game.endpoint_rng.state == rng_before, "An unfinished Cast neither moves endpoints nor advances endpoint RNG or gameplay.")
	check.call(game.place_wire(5, "corner") and game.rotate(5) and game.execute("flip", {"index": 5}).accepted and game.execute("undo").accepted and _endpoints(game.board) == initial and game.endpoint_rng.state == rng_before, "Construction, rotation, flip and Undo leave endpoint geometry and endpoint RNG unchanged.")
	check.call(game.play_technique(_uid(game, "conjure")) and _endpoints(game.board) == initial and game.endpoint_rng.state == rng_before, "Playing a card technique cannot reroll endpoint geometry or endpoint RNG.")
	game = Combat.new(setup)
	check.call(_build(game, _uid(game, "spark")), "The new opening accepts a complete circuit through ordinary editor commands.")
	game.energy = 0
	before = game.snapshot()
	rng_before = game.endpoint_rng.state
	rejected = game.execute("cast")
	check.call(not rejected.accepted and rejected.events.is_empty() and _same_except_log(before, game.snapshot()) and game.endpoint_rng.state == rng_before, "An unaffordable Cast preserves cards, circuit and endpoint RNG.")
	game = Combat.new(setup)
	var passed := game.execute("pass")
	var moved := _endpoints(game.board)
	check.call(passed.accepted and moved.begin.cell != initial.begin.cell and moved.end.cell != initial.end.cell and game.endpoint_rng.state != rng_before and _empty_between_endpoints(game.board), "Accepted nonterminal Pass moves both endpoints and advances only after ending the turn.")
	before = game.snapshot()
	rng_before = game.endpoint_rng.state
	var protected := true
	for endpoint in [moved.begin.cell, moved.end.cell]:
		for command in ["place_wire", "place_rune", "rotate", "flip"]:
			protected = not game.execute(command, {"index": endpoint, "kind": "erase", "uid": _uid(game, "spark")}).accepted and protected
	check.call(protected and _same_except_log(before, game.snapshot()) and game.endpoint_rng.state == rng_before, "New endpoint cells reject erasing, overwriting, rotation and flip without any reroll or state change.")
	var old_cells_editable := true
	for cell in [initial.begin.cell, initial.end.cell]:
		if cell not in [moved.begin.cell, moved.end.cell]:
			old_cells_editable = game.place_wire(cell, "straight") and old_cells_editable
	check.call(old_cells_editable and _endpoints(game.board) == moved and game.endpoint_rng.state == rng_before, "Vacated endpoint cells become ordinary editable sockets without moving the new endpoints.")

func _cleanup_before_movement(check: Callable, source: Dictionary) -> void:
	var setup := source.duplicate(true)
	setup.opening_hand = ["spark", "shield", "conjure", "conjure"]
	setup.opening_draw = 0
	var probe := Combat.new(setup)
	var destination := _endpoints(probe.execute("pass").after.board)
	var game := Combat.new(setup)
	var owned := _permanents(game)
	var old := _endpoints(game.board)
	var target_cells: Array = [destination.begin.cell, destination.end.cell].filter(func(cell): return cell not in [old.begin.cell, old.end.cell])
	check.call(not target_cells.is_empty(), "The cleanup witness has a future endpoint cell that can hold a card this turn.")
	if target_cells.is_empty():
		return
	var permanent_cell: int = target_cells[0]
	var permanent_uid := _uid(game, "spark")
	var temporary_cell := -1
	for cell in range(16):
		if cell not in [old.begin.cell, old.end.cell, permanent_cell]:
			temporary_cell = cell
			break
	var prepared := game.place_rune(permanent_cell, permanent_uid) and game.play_technique(_uid(game, "conjure")) and game.place_rune(temporary_cell, _uid(game, "free_spark")) and game.play_technique(_uid(game, "conjure"))
	check.call(prepared and _uid(game, "free_spark") >= 0, "Cleanup witness installs a permanent at the next endpoint and creates separate board/hand temporaries.")
	var result := game.execute("pass")
	var changes := _endpoint_events(result)
	var consumed: Array = result.events.filter(func(event): return event.type == "effect_consumed" and event.card.uid == permanent_uid)
	var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
	var cleanup: Array = result.events.filter(func(event): return event.type == "turn_cleanup")
	var types := _types(result)
	check.call(result.accepted and changes.size() == 1 and consumed.size() == 1 and consumed[0].cell == permanent_cell and consumed[0].to == "discard" and consumed[0].after == {} and consumed[0].sequence < changes[0].sequence, "A permanent occupying the chosen next endpoint is discarded exactly once before endpoint placement.")
	check.call(expired.size() == 1 and expired[0].cell == temporary_cell and expired[0].after == {} and cleanup.size() == 1 and cleanup[0].expired.size() == 1 and expired[0].sequence < changes[0].sequence, "Board and unused hand temporary cards expire before endpoint placement.")
	check.call(_permanents(game) == owned and _empty_between_endpoints(game.board) and _endpoints(game.board) == destination and not (game.hand + game.draw_pile + game.discard_pile).any(func(card): return game.catalog[card.id].get("temporary", false)), "Endpoint placement preserves every permanent UID and leaves no temporary card or old board piece behind.")
	check.call(types.find("retaliation") < types.find("turn_cleanup") and types.find("turn_cleanup") < types.find("endpoints_changed") and types.find("endpoints_changed") < types.find("turn_started") and types.find("turn_started") < types.find("card_drawn"), "Turn events resolve retaliation, cleanup, endpoint movement, turn start and draws in that order.")
	var next := game.snapshot()
	var rng_before: int = game.endpoint_rng.state
	check.call(not game.execute("undo").accepted and game.snapshot() == next and game.endpoint_rng.state == rng_before, "Undo cannot restore the previous turn's board, endpoint positions or discarded cards.")

func _terminal(check: Callable, source: Dictionary) -> void:
	for command in ["cast", "pass"]:
		var setup := source.duplicate(true)
		setup.owned_cards = ["spark"]
		setup.opening_hand = ["spark"]
		setup.opening_draw = 0
		var game := Combat.new(setup)
		game.execute("pass")
		var endpoints := _endpoints(game.board)
		var prepared := true
		if command == "cast":
			prepared = _build(game, _uid(game, "spark"))
			game.enemy_hp = 6
		else:
			game.player_hp = 1
		var owned := _permanents(game)
		var rng_before: int = game.endpoint_rng.state
		var card_rng_before: int = game.rng.state
		var result := game.execute(command)
		check.call(prepared and result.accepted and game.state == ("victory" if command == "cast" else "defeat") and _empty_between_endpoints(game.board) and _endpoints(game.board) == endpoints and _permanents(game) == owned, "Terminal %s clears installed pieces but preserves the current endpoints and all permanent ownership." % command)
		check.call(_endpoint_events(result).is_empty() and not _types(result).has("turn_started") and not _types(result).has("card_drawn") and game.endpoint_rng.state == rng_before and game.rng.state == card_rng_before, "Terminal %s does not choose endpoints, draw cards or advance either RNG." % command)
		var ended := game.snapshot()
		check.call(not game.execute("pass").accepted and not game.execute("cast").accepted and game.snapshot() == ended and game.endpoint_rng.state == rng_before, "Commands after terminal %s cannot advance endpoints or apply cleanup twice." % command)

func _replay_and_rng(check: Callable, source: Dictionary) -> void:
	var setup := _long_setup(source)
	var first := Combat.new(setup)
	var second := Combat.new(setup)
	var owned := _permanents(first)
	var reproducible := true
	var cast_movements := true
	for turn_number in range(8):
		var initial := _endpoints(first.board)
		if turn_number % 2 == 0:
			reproducible = _build(first) and _build(second) and reproducible
		var command := "cast" if turn_number % 2 == 0 else "pass"
		var left := first.execute(command)
		var right := second.execute(command)
		var final := _endpoints(first.board)
		cast_movements = final.begin.cell != initial.begin.cell and final.end.cell != initial.end.cell and _endpoint_events(left).size() == 1 and cast_movements
		reproducible = left == right and left.accepted and first.snapshot() == second.snapshot() and first.rng.state == second.rng.state and first.endpoint_rng.state == second.endpoint_rng.state and _permanents(first) == owned and reproducible
	check.call(reproducible and first.turn == 9, "Identical seed and commands exactly replay eight mixed Cast/Pass turns, including events, endpoint choices and card reshuffles.")
	check.call(cast_movements and _empty_between_endpoints(first.board), "Each accepted nonterminal Cast or Pass in the multi-turn sequence changes both endpoints exactly once.")
	var fixed_setup := _long_setup(Experiments.load_setup("effects", "full_reset", 42).setup)
	first = Combat.new(setup)
	var fixed := Combat.new(fixed_setup)
	var card_stream_equal := first.hand == fixed.hand and first.draw_pile == fixed.draw_pile and first.rng.state == fixed.rng.state
	for _turn in range(8):
		first.execute("pass")
		fixed.execute("pass")
		card_stream_equal = first.hand == fixed.hand and first.draw_pile == fixed.draw_pile and first.discard_pile == fixed.discard_pile and first.rng.state == fixed.rng.state and card_stream_equal
	check.call(card_stream_equal, "Endpoint randomness does not alter the ordinary card draw or reshuffle stream compared with fixed full reset.")
	var technique_setup := setup.duplicate(true)
	technique_setup.owned_cards = ["conjure", "focus"]
	technique_setup.opening_hand = ["conjure", "focus"]
	technique_setup.opening_draw = 0
	var technique_game := Combat.new(technique_setup)
	var untreated_game := Combat.new(technique_setup)
	var technique_rng_before: int = technique_game.endpoint_rng.state
	var played := technique_game.play_technique(_uid(technique_game, "conjure")) and technique_game.play_technique(_uid(technique_game, "focus"))
	check.call(played and technique_game.rng.state != untreated_game.rng.state and technique_game.endpoint_rng.state == technique_rng_before, "Focus can reshuffle and advance card RNG without changing endpoint RNG.")
	var same_endpoints := true
	for _turn in range(3):
		technique_game.execute("pass")
		untreated_game.execute("pass")
		same_endpoints = _endpoints(technique_game.board) == _endpoints(untreated_game.board) and technique_game.endpoint_rng.state == untreated_game.endpoint_rng.state and same_endpoints
	check.call(same_endpoints, "Additional card-technique draws and reshuffles cannot change the following endpoint sequence.")
	var endpoint_before: int = first.endpoint_rng.state
	var card_before: int = first.rng.state
	first.reset()
	check.call(first.endpoint_rng.state == endpoint_before and first.rng.state != card_before and _endpoints(first.board) == _endpoints(Combat.new(setup).board), "Ordinary restart restores opening geometry while continuing endpoint RNG and normal card RNG semantics.")
	var expected := RandomNumberGenerator.new()
	expected.state = endpoint_before
	var allowed_count := Loader.moving_endpoint_layouts().filter(func(layout): return layout.begin.cell != 0 and layout.end.cell != 14).size()
	expected.randi_range(0, allowed_count - 1)
	first.execute("pass")
	check.call(first.endpoint_rng.state == expected.state, "The first turn after ordinary restart consumes the continuing endpoint RNG stream once instead of reseeding.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	check.call(first.snapshot() == second.snapshot() and first.endpoint_rng.state == second.endpoint_rng.state and first.execute("pass") == second.execute("pass"), "A fresh exact replay resets both streams and reproduces the opening and first endpoint transition.")
	var choices := {}
	for seed in range(8):
		var seeded := Combat.new(setup, seed)
		var change: Dictionary = _endpoint_events(seeded.execute("pass"))[0]
		choices[change.after.layout_id] = true
	check.call(choices.size() > 1, "Different explicit seeds produce more than one first endpoint layout.")

func _isolation(check: Callable, setup: Dictionary) -> void:
	var fixed := Combat.new(Experiments.load_setup("effects", "full_reset", 42).setup)
	var original := _endpoints(fixed.board)
	var rng_before: int = fixed.endpoint_rng.state
	var result := fixed.execute("pass")
	check.call(result.accepted and _endpoints(fixed.board) == original and _endpoint_events(result).is_empty() and fixed.endpoint_rng.state == rng_before and not fixed.snapshot().experiment.has("endpoint_policy"), "The existing full-reset variant keeps fixed endpoints and its original metadata and events.")
	var detached := Combat.new(setup)
	var snapshot := detached.snapshot()
	snapshot.experiment.endpoint_layouts[0].begin.cell = 5
	snapshot.experiment.endpoint_layouts[0].path.clear()
	var untouched := Combat.new(setup)
	check.call(detached.execute("pass") == untouched.execute("pass") and setup.experiment.endpoint_layouts == Loader.moving_endpoint_layouts(), "Snapshot edits cannot change future endpoint selection or the caller's setup catalog.")
