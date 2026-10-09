extends RefCounted

const Examples = preload("res://scripts/dev/board_examples.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const EXPECTED := {
	"board_training": {"damage": 6, "shield": 0, "cost": 2, "active": 3, "hp": 22},
	"board_gallery": {"damage": 6, "shield": 5, "cost": 3, "active": 9, "hp": 27},
	"board_ossuary": {"damage": 6, "shield": 0, "cost": 2, "active": 8, "hp": 22},
	"board_belfry": {"damage": 12, "shield": 5, "cost": 2, "active": 9, "hp": 27}
}

func run(check: Callable) -> void:
	_document_failures(check)
	for board_id in Examples.BOARD_IDS:
		var loaded := Examples.load_example(board_id)
		check.call(loaded.ok, "%s loads its authored witness and ordinary production starter encounter: %s" % [board_id, str(loaded.errors)])
		if not loaded.ok:
			continue
		var example: Dictionary = loaded.example
		var model := Combat.new(loaded.setup)
		var controller := Controller.new(model)
		var initial := _state(model)
		var opening := Examples.apply(controller, example, "opening")
		check.call(opening.ok and _state(model) == initial and _endpoints_only(model) and model.energy == 3 and model.hand.size() == 3,
			"%s recorded opening is an untouched, natural three-card/three-energy starter draw with two endpoints." % board_id)
		check.call(not Examples.apply(controller, example, "unsupported").ok and _state(model) == initial,
			"%s rejects unsupported replay stages without commands or RNG changes." % board_id)
		_invalid_actions(check, model, controller, board_id)
		var original_owned := _permanents(model)
		var original_rng := _rng(model)
		for index in range(example.commands.size()):
			var action: Dictionary = example.commands[index]
			var before := model.snapshot()
			var accepted: bool = controller.command(action.command, action.arguments)
			check.call(accepted and not controller.is_busy() and _stock_conserved(model) and _permanents(model) == original_owned and _rng(model) == original_rng and model.energy == 3,
				"%s authored command %d (%s) preserves finite stock, all eight permanent instances, preparation energy and three RNG streams." % [board_id, index + 1, action.command])
			if action.command == "place_rune" and before.board[int(action.arguments.index)].get("kind") in ["straight", "corner", "split", "join"]:
				var displaced: String = before.board[int(action.arguments.index)].kind
				check.call(model.stock(displaced) == int(before.stock[displaced]) + 1,
					"%s rune replacement immediately returns its displaced physical connector." % board_id)
		var built := Examples.facts(model.snapshot())
		var expected: Dictionary = EXPECTED[board_id]
		var spell := model.forecast()
		check.call(built == example.expected.built and spell.valid and spell.damage == expected.damage and spell.shield == expected.shield and spell.cost == expected.cost and spell.active.size() == expected.active,
			"%s exact command-built board has the independently specified active cells, damage, shield and physical cast cost." % board_id)
		var before_stale := _state(model)
		check.call(not Examples.apply(controller, example, "built").ok and _state(model) == before_stale,
			"%s cannot apply an authored opening over an already edited board." % board_id)
		var snapshot := model.snapshot()
		var rune_cell := int(spell.active.filter(func(cell): return snapshot.board[cell].get("kind") == "rune")[0])
		var before_invalid := _state(model)
		check.call(not controller.command("flip", {"index": rune_cell}) and _state(model) == before_invalid,
			"%s rejects effect Flip without changing the circuit, ownership or RNG." % board_id)
		check.call(controller.command("cast"), "%s commits one affordable authored Cast through the real controller." % board_id)
		var result := model.last_result()
		check.call(result.events[0].type == "cast" and result.events[0].energy_before == 3 and result.events[0].energy_after == 3 - int(expected.cost) and model.enemy_hp == 32 - int(expected.damage) and model.player_hp == expected.hp,
			"%s pays its physical cost once, applies aggregate damage and blocks the expected part of Shadeling's eight-point retaliation." % board_id)
		check.call(Examples.facts(model.snapshot()) == example.expected.after_cast and _endpoints_only(model) and model.turn == 2 and model.energy == 3 and model.hand.size() == 3 and model.history.is_empty() and model.snapshot().stock == model.stock_totals and _permanents(model) == original_owned,
			"%s cleans all non-endpoints, preserves each permanent UID, normally draws the documented hand and selects the documented next endpoints/full kit." % board_id)
		var cleanup_cells: Array = []
		var consumed_uids: Array = []
		for event in result.events:
			if event.type in ["board_piece_cleared", "effect_consumed", "temporary_expired"]:
				cleanup_cells.append(event.cell)
			if event.type == "effect_consumed": consumed_uids.append(event.card.uid)
		var sorted_cells := cleanup_cells.duplicate()
		sorted_cells.sort()
		check.call(cleanup_cells == sorted_cells and cleanup_cells.size() == int(expected.active) - 2 and consumed_uids.size() == built.physical_usage.rune - (1 if board_id == "board_belfry" else 0),
			"%s clears each physical piece in cell order and discards each installed permanent exactly once." % board_id)
		if board_id == "board_belfry":
			var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
			check.call(expired.size() == 1 and expired[0].before.uid == 8 and not (model.hand + model.draw_pile + model.discard_pile).any(func(card): return card.id == "free_spark") and built.physical_usage.split == 1 and built.physical_usage.join == 1,
				"Belfry's real zero-cost Conjure creates UID8; one finite Split/Join amplifies it and cleanup deletes it without adding a permanent card.")
		var after := _state(model)
		check.call(not controller.command("undo") and _state(model) == after,
			"%s cannot Undo across the Cast/cleanup boundary." % board_id)
		controller.dispose()
		var replay_model := Combat.new(loaded.setup)
		var replay := Controller.new(replay_model)
		var replay_result := Examples.apply(replay, example, "cast")
		check.call(replay_result.ok and _state(replay_model) == after,
			"%s shared helper exactly replays opening, commands, Cast, next draw and RNG without setup mutation." % board_id)
		replay.dispose()
		_stock_boundary(check, loaded, board_id)

func _document_failures(check: Callable) -> void:
	var loaded := Loader.read_document(Examples.PATH)
	check.call(loaded.ok and Examples.validate_document(loaded.document).ok, "RC-009 authored witness document validates exactly four IDs and exact construction commands.")
	if not loaded.ok:
		return
	for fault in ["version", "missing", "duplicate", "unknown", "seed", "setup", "path", "commands", "arguments", "expected"]:
		var source: Dictionary = loaded.document.duplicate(true)
		match fault:
			"version": source.version = "unknown"
			"missing": source.examples.pop_back()
			"duplicate": source.examples[1].board_id = source.examples[0].board_id
			"unknown": source.examples[0].board_id = "board_unknown"
			"seed": source.examples[0].seed = 1.5
			"setup": source.examples[0].setup_kind = "supplied_spark"
			"path": source.examples[0].encounter_path = "res://data/encounter.json"
			"commands": source.examples[0].commands = [{"command": "cast", "arguments": {}}]
			"arguments": source.examples[0].commands = [{"command": "rotate", "arguments": {"index": 16}}]
			"expected": source.examples[0].expected.erase("built")
		var result := Examples.validate_document(source)
		check.call(not result.ok and result.setup.is_empty() and result.example.is_empty(), "Malformed authored example (%s) fails without a partial setup or witness." % fault)
	check.call(not Examples.load_example("board_unknown").ok, "Unknown authored example IDs fail explicitly.")
	for malformed in [{}, [], true, 42, null]:
		for field in ["version", "setup_kind"]:
			var source: Dictionary = loaded.document.duplicate(true)
			if field == "version": source.version = malformed
			else: source.examples[0].setup_kind = malformed
			check.call(not Examples.validate_document(source).ok,
				"Malformed %s type %d fails through validation without an incompatible Variant comparison." % [field, typeof(malformed)])

func _invalid_actions(check: Callable, model: Combat, controller, board_id: String) -> void:
	var begin: int = Examples.facts(model.snapshot()).endpoints.begin.cell
	for action in [{"command": "cast", "arguments": {}}, {"command": "flip", "arguments": {"index": begin}},
		{"command": "place_wire", "arguments": {"index": begin, "kind": "straight"}},
		{"command": "place_rune", "arguments": {"index": 1, "uid": 9999}},
		{"command": "technique", "arguments": {"uid": 9999}}]:
		var before := _state(model)
		check.call(not controller.command(action.command, action.arguments) and _state(model) == before,
			"%s rejects invalid %s without state/RNG changes." % [board_id, action.command])

func _stock_boundary(check: Callable, loaded: Dictionary, board_id: String) -> void:
	var model := Combat.new(loaded.setup)
	var controller := Controller.new(model)
	var empty: Array = []
	for cell in range(16):
		if model.board[cell].is_empty(): empty.append(cell)
	var total := model.stock("split")
	for index in range(total):
		controller.command("place_wire", {"index": empty[index], "kind": "split"})
	var exhausted := _state(model)
	check.call(model.stock("split") == 0 and not controller.command("place_wire", {"index": empty[total], "kind": "split"}) and _state(model) == exhausted,
		"%s refuses another physical Split at the naturally selected kit limit with unchanged RNG/state." % board_id)
	var replaced: bool = controller.command("place_wire", {"index": empty[0], "kind": "straight"})
	check.call(replaced and model.stock("split") == 1 and _stock_conserved(model), "%s connector replacement refunds the displaced finite Split." % board_id)
	check.call(controller.command("undo") and _state(model) == exhausted,
		"%s Undo restores the exact exhausted kit, board, hand, history and RNG." % board_id)
	controller.dispose()

func _rng(model: Combat) -> Array:
	return [model.rng.state, model.endpoint_rng.state, model.kit_rng.state]

func _state(model: Combat) -> Dictionary:
	var snapshot := model.snapshot()
	snapshot.erase("log_text")
	return {"snapshot": snapshot, "rng": _rng(model), "history": model.history.duplicate(true)}

func _endpoints_only(model: Combat) -> bool:
	return model.board.filter(func(piece): return not piece.is_empty()).size() == 2 and Examples.facts(model.snapshot()).endpoints.size() == 2

func _permanents(model: Combat) -> Array:
	var cards: Array = []
	for card in model.hand + model.draw_pile + model.discard_pile:
		if not model.catalog[card.id].temporary: cards.append(card.duplicate(true))
	for piece in model.board:
		if piece.get("kind") == "rune" and not model.catalog[piece.rune_id].temporary:
			cards.append({"id": piece.rune_id, "uid": piece.uid})
	cards.sort_custom(func(first, second): return first.uid < second.uid)
	return cards

func _stock_conserved(model: Combat) -> bool:
	for kind in ["straight", "corner", "split", "join"]:
		var installed: int = model.board.filter(func(piece): return piece.get("kind") == kind).size()
		if installed > int(model.stock_totals[kind]) or model.stock(kind) + installed != int(model.stock_totals[kind]):
			return false
	return true
