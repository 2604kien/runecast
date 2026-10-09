extends RefCounted

# Automated model checks only. These do not create participant observations or
# export records, and use detached setup overrides for explicit edge cases.
const Combat = preload("res://scripts/core/combat.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func run(check: Callable) -> void:
	var loaded := Experiments.load_setup("effects", "full_reset", 42)
	check.call(loaded.ok, "Full-reset follow-up validates as an explicit experiment.")
	if not loaded.ok:
		return
	_validation(check)
	_initial_and_rejection(check, loaded.setup)
	_cast_cleanup(check, loaded.setup)
	_pass_cleanup(check, loaded.setup)
	_temporary_cleanup(check, loaded.setup)
	_terminal_cleanup(check, loaded.setup)
	_recycling_and_replay(check, loaded.setup)
	_legacy_isolation(check)

func _validation(check: Callable) -> void:
	var source := Experiments.documents("effects", "full_reset", 42)
	var untouched := source.duplicate(true)
	for kind in ["straight", "blocked"]:
		var documents: Dictionary = source.documents.duplicate(true)
		var context: Dictionary = source.experiment.duplicate(true)
		documents.boards[0].placements.append({"cell": 1, "kind": kind})
		var before := documents.duplicate(true)
		var invalid := Loader.validate_documents(documents, {}, context)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty(), "Full-reset validation rejects an opening %s in a non-endpoint cell." % kind)
		check.call(documents == before and context == source.experiment, "Rejecting an opening %s leaves supplied documents and experiment context unchanged." % kind)
	var cases := [
		["missing board_reset", func(options): options.erase("board_reset")],
		["wrong board_reset", func(options): options.board_reset = "after_cast"],
		["legacy version", func(options): options.version = "rc005_v1"],
		["inconsistent effects", func(options): options.effects = "consumed"],
		["inconsistent expiry", func(options): options.expiry = "straight"],
		["inconsistent transfer", func(options): options.transfer = "retain"]
	]
	for entry in cases:
		var documents: Dictionary = source.documents.duplicate(true)
		var context: Dictionary = source.experiment.duplicate(true)
		entry[1].call(context)
		var before := context.duplicate(true)
		var invalid := Loader.validate_documents(documents, {}, context)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty(), "Full-reset validation rejects %s without partial configuration." % entry[0])
		check.call(context == before and documents == source.documents, "Rejecting %s does not repair or mutate supplied configuration." % entry[0])
	check.call(source == untouched and Loader.validate_documents(source.documents, {}, source.experiment).ok, "Detached malformed cases leave the original full-reset documents intact and valid.")

func _only_endpoints(board: Array) -> bool:
	if board.size() != 16 or board[0].get("kind") != "begin" or board[14].get("kind") != "end":
		return false
	for index in range(board.size()):
		if index not in [0, 14] and not board[index].is_empty():
			return false
	return true

func _permanents(game: Combat) -> Array:
	var cards: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].get("temporary", false):
			cards.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].get("temporary", false):
			cards.append({"id": piece.rune_id, "uid": piece.uid})
	cards.sort_custom(func(first, second): return first.uid < second.uid)
	return cards

func _controlled_setup(source: Dictionary, opening_hand: Array = ["spark", "shield", "conjure"]) -> Dictionary:
	var setup := source.duplicate(true)
	setup.opening_hand = opening_hand.duplicate()
	setup.opening_draw = 0
	return setup

func _uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id:
			return int(card.uid)
	return -1

func _build(game: Combat) -> bool:
	# A wire-only, one-pair circuit lets edge cases install their own hand runes.
	for placement in [[1, "straight", 0], [2, "split", 0], [3, "corner", 0], [6, "straight", 1], [7, "straight", 1], [10, "join", 0], [11, "corner", 1]]:
		if not game.place_wire(placement[0], placement[1]):
			return false
		for rotation in range(placement[2]):
			if not game.rotate(placement[0]):
				return false
	return game.forecast().valid and game.forecast().cost <= game.energy

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _same_gameplay(first: Dictionary, second: Dictionary) -> bool:
	var before := first.duplicate(true)
	var after := second.duplicate(true)
	before.erase("log_text")
	after.erase("log_text")
	return before == after

func _clearing_events(result: Dictionary) -> Array:
	return result.events.filter(func(event): return event.type in ["effect_consumed", "temporary_expired", "board_piece_cleared"])

func _assert_order(check: Callable, result: Dictionary, terminal: bool, label: String) -> void:
	var types := _types(result)
	var cleanup_index := types.find("turn_cleanup")
	var resolved_index := types.find("retaliation")
	if resolved_index < 0:
		resolved_index = types.find("damage")
	var clear_events := _clearing_events(result)
	check.call(not clear_events.is_empty() and clear_events.all(func(event): return event.sequence > resolved_index and event.sequence < cleanup_index and event.after == {}), label + " clears every installed piece after resolution and before hand cleanup.")
	if terminal:
		check.call(types.back() == "battle_ended" and types.find("battle_ended") > cleanup_index and not types.has("turn_started") and not types.has("card_drawn") and not types.has("reshuffled"), label + " completes cleanup before battle end without starting or drawing a new turn.")
	else:
		check.call(types.find("turn_started") > cleanup_index and types.find("card_drawn") > types.find("turn_started"), label + " starts and draws the next turn only after cleanup.")

func _initial_and_rejection(check: Callable, setup: Dictionary) -> void:
	var game := Combat.new(setup)
	check.call(setup.experiment.version == "rc006_full_reset_v1" and setup.experiment.board_reset == "each_turn" and setup.experiment.effects == "discard_all" and setup.experiment.expiry == "empty", "Full reset has its own version and complete explicit rule options.")
	check.call(_only_endpoints(game.board) and game.hand.size() == 3 and _permanents(game).size() == 8, "Full reset starts with only Begin/End, a three-card hand and eight unique permanent instances.")
	check.call(not game.forecast().valid and game.stock("split") == game.stock_totals.split and game.stock("join") == game.stock_totals.join, "An untouched full-reset board needs construction and makes the complete supply available.")
	var before := game.snapshot()
	var rng_before: int = game.rng.state
	var rejected := game.execute("cast")
	check.call(not rejected.accepted and rejected.events.is_empty() and _same_gameplay(before, game.snapshot()) and game.rng.state == rng_before, "An invalid Cast neither clears nor draws nor changes gameplay or RNG.")
	var actions := Experiments.known_solution_actions("effects", "full_reset")
	var accepted := not actions.is_empty()
	for action in actions:
		accepted = game.execute(action.command, action.arguments).accepted and accepted
	check.call(accepted and game.forecast().valid and game.forecast().damage == 6 and game.forecast().cost == 2, "The full-reset facilitator witness constructs a valid affordable Spark circuit from the empty opening.")
	game = Combat.new(_controlled_setup(setup))
	check.call(_build(game) and game.place_rune(1, _uid(game, "spark")), "The full-reset construction witness accepts editor commands and powers a hand rune.")
	game.energy = 0
	before = game.snapshot()
	rng_before = game.rng.state
	var history_before := game.history.duplicate(true)
	rejected = game.execute("cast")
	check.call(not rejected.accepted and rejected.events.is_empty() and _same_gameplay(before, game.snapshot()) and game.history == history_before and game.rng.state == rng_before, "An unaffordable Cast preserves installed runes, wiring, hand, history and RNG.")

func _cast_cleanup(check: Callable, setup: Dictionary) -> void:
	var game := Combat.new(_controlled_setup(setup))
	var owned := _permanents(game)
	var endpoints := [game.board[0].duplicate(true), game.board[14].duplicate(true)]
	var spark_uid := _uid(game, "spark")
	var shield_uid := _uid(game, "shield")
	check.call(_build(game) and game.place_rune(1, spark_uid) and game.place_rune(8, shield_uid), "Cast fixture installs one powered Spark and one disconnected Shield.")
	var spell := game.forecast()
	var enemy_before: int = game.enemy_hp
	var result := game.execute("cast")
	check.call(result.accepted and spell.damage == 12 and game.enemy_hp == enemy_before - spell.damage, "Full reset preserves the predicted duplicated Spark damage before clearing.")
	check.call(_only_endpoints(game.board) and [game.board[0], game.board[14]] == endpoints, "Accepted Cast empties every non-endpoint cell and preserves exact endpoint geometry.")
	var consumed: Array = result.events.filter(func(event): return event.type == "effect_consumed")
	check.call(consumed.size() == 2 and consumed.map(func(event): return event.card.uid) == [spark_uid, shield_uid] and consumed.all(func(event): return event.from == "board" and event.to == "discard" and event.after == {}), "Powered and disconnected permanent instances each move from board to discard exactly once.")
	check.call(_permanents(game) == owned and game.discard_pile.has({"id": "spark", "uid": spark_uid}) and game.discard_pile.has({"id": "shield", "uid": shield_uid}), "Cast conserves all permanent UIDs while ordinary remaining draw cards deal first.")
	_assert_order(check, result, false, "Cast")
	check.call(game.hand.size() == 3 and game.turn == 2 and game.energy == game.encounter.energy_per_turn and game.history.is_empty(), "The next turn has a normal hand, refreshed energy and no previous-turn undo history.")
	check.call(game.stock("split") == game.stock_totals.split and game.stock("join") == game.stock_totals.join, "Clearing returns both connector supplies exactly to their configured totals.")
	var after := game.snapshot()
	check.call(not game.execute("undo").accepted and game.snapshot() == after, "Undo cannot recover cards or circuits from a completed turn.")
	check.call(game.place_wire(2, "split") and game.stock("split") == 0 and not game.place_wire(6, "split") and game.place_wire(10, "join") and game.stock("join") == 0 and not game.place_wire(11, "join"), "Returned connectors can be placed once and cannot exceed bounded supply.")

func _pass_cleanup(check: Callable, setup: Dictionary) -> void:
	var game := Combat.new(_controlled_setup(setup))
	var owned := _permanents(game)
	game.place_rune(8, _uid(game, "shield"))
	game.place_wire(2, "split")
	game.place_wire(10, "join")
	game.place_wire(12, "corner")
	check.call(not game.forecast().valid, "Pass fixture has an unfinished circuit and disconnected permanent rune.")
	var hp_before: int = game.player_hp
	var result := game.execute("pass")
	check.call(result.accepted and game.player_hp == hp_before - 3 and _only_endpoints(game.board) and _permanents(game) == owned, "Pass retaliates once and clears an unfinished board without losing permanent ownership.")
	check.call(_types(result).count("effect_consumed") == 1 and _types(result).count("board_piece_cleared") == 3 and game.stock("split") == 1 and game.stock("join") == 1, "Pass reports permanent removal and each wire removal, returning both supplies.")
	_assert_order(check, result, false, "Pass")

func _temporary_cleanup(check: Callable, setup: Dictionary) -> void:
	for command in ["cast", "pass"]:
		var game := Combat.new(_controlled_setup(setup, ["spark", "conjure", "conjure"]))
		var owned := _permanents(game)
		check.call(_build(game) and game.place_rune(1, _uid(game, "spark")), command + " temporary fixture builds the powered permanent circuit.")
		var created := game.play_technique(_uid(game, "conjure"))
		created = game.place_rune(12, _uid(game, "free_spark")) and created
		created = game.play_technique(_uid(game, "conjure")) and created
		check.call(created and _uid(game, "free_spark") >= 0 and game.board[12].get("rune_id") == "free_spark", command + " creates separate installed and unused hand temporary instances.")
		var result := game.execute(command)
		var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
		var cleanup: Array = result.events.filter(func(event): return event.type == "turn_cleanup")
		check.call(result.accepted and expired.size() == 1 and expired[0].cell == 12 and expired[0].after == {} and cleanup.size() == 1 and cleanup[0].expired.size() == 1, command + " deletes the disconnected board temporary and unused hand temporary during cleanup.")
		check.call(_only_endpoints(game.board) and _permanents(game) == owned and not (game.hand + game.draw_pile + game.discard_pile).any(func(card): return game.catalog[card.id].get("temporary", false)), command + " leaves no temporary in any card pile and conserves all permanent instances.")
		_assert_order(check, result, false, command + " with temporaries")

func _terminal_cleanup(check: Callable, source: Dictionary) -> void:
	for outcome in ["victory", "defeat"]:
		var setup := _controlled_setup(source)
		if outcome == "victory":
			setup.encounter.max_health = 12
		else:
			setup.encounter.player_health = 3
		var game := Combat.new(setup)
		var owned := _permanents(game)
		check.call(_build(game) and game.place_rune(1, _uid(game, "spark")) and game.place_rune(8, _uid(game, "shield")), outcome + " fixture includes powered and disconnected permanent runes.")
		var result := game.execute("cast")
		check.call(result.accepted and game.state == outcome and _only_endpoints(game.board) and game.hand.is_empty() and game.history.is_empty() and _permanents(game) == owned, outcome + " clears board and hand once while conserving every permanent instance.")
		check.call((_types(result).count("retaliation") == 0 if outcome == "victory" else _types(result).count("retaliation") == 1) and _types(result).count("effect_consumed") == 2, outcome + " preserves lethal/retaliation ordering and still discards all installed permanents.")
		_assert_order(check, result, true, outcome)
		var ended := game.snapshot()
		check.call(not game.execute("pass").accepted and not game.execute("cast").accepted and game.snapshot() == ended, outcome + " rejects further turn commands without repeated cleanup.")

func _recycling_and_replay(check: Callable, source: Dictionary) -> void:
	var setup := _controlled_setup(source, ["spark"])
	setup.owned_cards = ["spark"]
	var game := Combat.new(setup)
	var uid := _uid(game, "spark")
	check.call(_build(game) and game.place_rune(1, uid), "Single-card recycle fixture builds with its only permanent instance.")
	var result := game.execute("cast")
	check.call(result.accepted and game.hand == [{"id": "spark", "uid": uid}] and game.draw_pile.is_empty() and game.discard_pile.is_empty() and _types(result).count("reshuffled") == 1 and _types(result).count("card_drawn") == 1, "Normal recycling allows a just-discarded installed rune to appear in the next hand, without duplication or a forced hand difference.")
	var first := Combat.new(source)
	var second := Combat.new(source)
	var reproducible := first.snapshot() == second.snapshot() and first.rng.state == second.rng.state
	for _round_number in range(3):
		reproducible = _build(first) and _build(second) and first.snapshot() == second.snapshot() and reproducible
		reproducible = first.execute("pass") == second.execute("pass") and reproducible
		reproducible = first.rng.state == second.rng.state and _only_endpoints(first.board) and reproducible
	check.call(reproducible and first.turn == 4 and _permanents(first).size() == 8, "Exact setup and seed reproduce all construction, clearing, draw and reshuffle events over three turns.")

func _legacy_isolation(check: Callable) -> void:
	for variant in ["control", "treatment"]:
		var loaded := Experiments.load_setup("effects", variant, 42)
		var game := Combat.new(loaded.setup)
		var result := game.execute("cast")
		check.call(loaded.setup.experiment.version == "rc005_v1" and not loaded.setup.experiment.has("board_reset") and result.accepted and game.board[2].get("kind") == "split" and game.board[8].get("rune_id") == "shield", "Legacy effects/%s retains its original experiment version, wires and disconnected permanent." % variant)
	var normal := Combat.new(Loader.load_setup().setup)
	var result := normal.execute("cast")
	check.call(result.accepted and not normal.snapshot().has("experiment") and normal.board[2].get("kind") == "split" and not _only_endpoints(normal.board), "Normal gameplay remains outside the opt-in full-reset experiment.")
