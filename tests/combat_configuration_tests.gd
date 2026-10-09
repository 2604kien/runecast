extends RefCounted

# RC-007 preserves these historical assertions using the explicit legacy fixture.
# Production defaults are covered separately by production_*_tests.gd.

const Combat = preload("res://scripts/core/combat.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")

func _documents() -> Dictionary:
	var documents := {}
	for kind in ["runes", "boards", "enemies", "loadouts", "encounter"]:
		documents[kind] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % kind))
	return documents

func _all_cards(game: Combat) -> Array:
	var cards: Array = (game.hand + game.draw_pile + game.discard_pile).duplicate(true)
	for piece in game.board:
		if piece.get("kind") == "rune":
			cards.append({"id": piece.rune_id, "uid": piece.uid})
	return cards

func _counts(ids: Array) -> Dictionary:
	var counts := {}
	for id in ids:
		counts[id] = counts.get(id, 0) + 1
	return counts

func _permanent_counts(game: Combat) -> Dictionary:
	var ids: Array = []
	for card in _all_cards(game):
		if not game.catalog[card.id].get("temporary", false):
			ids.append(card.id)
	return _counts(ids)

func _unique_cards(game: Combat) -> bool:
	var seen := {}
	for card in _all_cards(game):
		if seen.has(card.uid):
			return false
		seen[card.uid] = true
	return true

func run(check: Callable) -> void:
	var training := Loader.load_setup(Loader.LEGACY_ENCOUNTER)
	var alternate := Loader.load_setup("res://data/dev_encounter.json")
	check.call(training.ok and alternate.ok, "Both shipped configurations validate before combat construction.")
	if not training.ok or not alternate.ok:
		return
	var game := Combat.new(training.setup)
	check.call(_permanent_counts(game) == {"spark": 2, "shield": 2, "focus": 2, "conjure": 2} and _all_cards(game).size() == 9, "Training allocates eight owned cards plus one separate tutorial temporary.")
	check.call(game.hand.map(func(card): return card.id) == ["spark", "shield", "conjure"] and game.draw_pile.size() == 5 and _unique_cards(game), "Training deals the curated hand from ownership and assigns unique UIDs in every zone.")
	check.call(game.stock("split") == 0 and game.stock("join") == 0 and game.snapshot().stock_totals == {"split": 1, "join": 1}, "Training's installed Split and Join consume their configured totals.")
	var result := game.execute("cast")
	check.call(result.events[0].spell.damage == 12 and result.events[0].spell.cost == 1 and game.enemy_hp == 20 and game.player_hp == 22, "Validated training retains the original first-cast outcome.")
	check.call(_permanent_counts(game) == _counts(training.setup.owned_cards) and _all_cards(game).size() == 8, "Temporary cleanup preserves every permanent training instance exactly once.")

	game = Combat.new(alternate.setup)
	var start := game.snapshot()
	check.call(start.encounter_content_id == "dev_calibration" and start.enemy_name == "Calibration Wisp" and start.enemy_hp == 45 and start.enemy_max_hp == 45, "Alternate content identity and enemy values reach the detached snapshot.")
	check.call(start.player_hp == 24 and start.player_max_hp == 40 and start.energy == 4 and start.energy_per_turn == 4 and start.draw_per_turn == 2, "Alternate current/max health, energy and draw settings initialize correctly.")
	check.call(start.encounter_title == "DEVELOPMENT FIXTURE" and start.encounter_help_text == alternate.setup.encounter.help_text and game.intent() == 3, "Alternate title/help and first scalar intent come from its selected configuration.")
	check.call(game.hand.map(func(card): return card.id) == ["focus", "shield"] and game.board[1].rune_id == "spark" and game.draw_pile.size() == 3, "Alternate installed Spark and curated hand are allocated out of six owned cards.")
	check.call(_permanent_counts(game) == _counts(alternate.setup.owned_cards) and _unique_cards(game), "Installed permanent cards appear exactly once across the alternate battle zones.")
	check.call(game.stock("split") == 2 and game.stock("join") == 0 and not game.place_wire(12, "join"), "Configured zero Join and two Split totals govern placement.")
	check.call(game.place_wire(4, "split") and game.place_wire(5, "split") and game.stock("split") == 0 and not game.place_wire(8, "split"), "Each installed Split consumes one of the two configured pieces.")
	game.undo()
	check.call(game.stock("split") == 1 and game.board[5].is_empty(), "Undo restores the configured available supply.")
	game.reset()
	var spark_uid: int = game.board[1].uid
	game.place_wire(1, "erase")
	check.call(game.hand.back().uid == spark_uid and _permanent_counts(game) == _counts(alternate.setup.owned_cards), "Removing an initially installed permanent card returns its same instance to hand.")
	game.undo()
	check.call(game.board[1].uid == spark_uid and not game.hand.any(func(card): return card.uid == spark_uid) and _unique_cards(game), "Undo restores installed ownership without duplicating its card.")
	result = game.execute("cast")
	check.call(result.accepted and game.enemy_hp == 39 and game.player_hp == 21 and game.energy == 4 and game.hand.size() == 2 and game.intent() == 7, "Alternate circuit casts six damage, then uses its own retaliation, energy and draw settings.")
	check.call(game.board[1].uid == spark_uid and _permanent_counts(game) == _counts(alternate.setup.owned_cards), "An initially installed permanent rune persists through configured turn cleanup.")
	game.pass_turn()
	check.call(game.player_hp == 14 and game.intent() == 5 and _unique_cards(game), "The alternate scalar attack sequence advances with subsequent turns.")
	var controller := Controller.new(game)
	controller.restart()
	var restarted := controller.snapshot()
	check.call(restarted.encounter_content_id == start.encounter_content_id and restarted.encounter_id > start.encounter_id and restarted.board == start.board and restarted.hand == start.hand and restarted.player_hp == 24 and restarted.enemy_hp == 45 and restarted.stock_totals == start.stock_totals, "Controller Restart restores the selected board, hand, health and inventory while advancing presentation generation.")
	controller.dispose()

	_seed_and_isolation_checks(check, training.setup, alternate.setup)
	_opening_and_effect_checks(check)

func _seed_and_isolation_checks(check: Callable, training: Dictionary, alternate: Dictionary) -> void:
	var first := Combat.new(alternate)
	var second := Combat.new(alternate)
	check.call(first.snapshot() == second.snapshot() and first.rng.state == second.rng.state, "Fresh instances with the same selected setup/seed have identical state and shuffle.")
	first.execute("technique", {"uid": first.hand[0].uid})
	second.execute("technique", {"uid": second.hand[0].uid})
	first.pass_turn()
	second.pass_turn()
	first.reset()
	second.reset()
	check.call(first.snapshot() == second.snapshot() and first.rng.state == second.rng.state, "Matching action/reset histories reproduce while Restart continues the same RNG stream.")
	first = Combat.new(training, 912)
	second = Combat.new(training, 912)
	check.call(first.snapshot() == second.snapshot() and first.encounter.seed == 912 and training.encounter.seed == 42, "An explicit seed override is reproducible, reported, and does not alter input configuration.")

	var supplied := alternate.duplicate(true)
	first = Combat.new(supplied)
	var preserved := first.snapshot()
	supplied.catalog.spark.value = 999
	supplied.encounter.intents.clear()
	supplied.encounter.name = "Wrong enemy"
	supplied.board.clear()
	supplied.owned_cards.clear()
	supplied.opening_hand.clear()
	supplied.inventory.split = 99
	check.call(first.snapshot() == preserved, "Mutating nested input definitions/setup after construction cannot mutate the active model.")
	first.catalog.spark.value = 444
	first.encounter.intents.clear()
	first.board.clear()
	first.owned_cards.clear()
	first.stock_totals.split = 33
	first.reset()
	check.call(first.catalog == alternate.catalog and first.encounter == alternate.encounter and first.board == preserved.board and first.owned_cards == alternate.owned_cards and first.stock_totals == alternate.inventory, "Runtime mutable state has no alias to the private Restart template.")
	var exposed := first.snapshot()
	exposed.stock_totals.clear()
	exposed.owned_cards.clear()
	exposed.encounter.name = "Wrong snapshot"
	check.call(first.stock_totals == alternate.inventory and first.owned_cards == alternate.owned_cards and first.encounter.name == "Calibration Wisp", "New ownership/inventory/configuration snapshot fields are detached collections.")

func _opening_and_effect_checks(check: Callable) -> void:
	var documents := _documents()
	documents.loadouts[0].opening_policy = "draw"
	documents.loadouts[0].erase("opening_hand")
	documents.loadouts[0].opening_draw = 4
	var loaded := Loader.validate_documents(documents)
	check.call(loaded.ok, "A supported opening-draw policy validates without a curated hand.")
	if not loaded.ok:
		return
	var game := Combat.new(loaded.setup)
	check.call(game.hand.size() == 4 and game.draw_pile.size() == 4 and _permanent_counts(game) == _counts(loaded.setup.owned_cards) and _unique_cards(game), "Opening draw deals from the shuffled owned deck without duplicating or losing cards.")
	check.call(game.last_result().is_empty() and game.execute("pass").events[0].type == "passed", "Initial dealing emits no stale action outcomes or setup draw events.")

	documents = _documents()
	documents.runes[2].value = 1
	documents.runes[3].value = 2
	documents.runes[3].generated_rune_id = "test_free_shield"
	var generated: Dictionary = documents.runes[4].duplicate(true)
	generated.id = "test_free_shield"
	generated.name = "Test Free Shield"
	generated.effect = "shield"
	generated.value = 4
	documents.runes.append(generated)
	documents.loadouts[0].opening_hand = ["focus", "conjure"]
	loaded = Loader.validate_documents(documents)
	check.call(loaded.ok, "Current effect definitions validate with configured draw count and a compatible generated target.")
	if not loaded.ok:
		return
	game = Combat.new(loaded.setup)
	var conjure_uid: int = game.hand[1].uid
	var result := game.execute("technique", {"uid": game.hand[0].uid})
	check.call(result.accepted and result.events.filter(func(event): return event.type == "card_drawn").size() == 1 and game.hand.size() == 2 and game.energy == 2, "Draw execution honors the definition's value instead of a hardcoded count of two.")
	result = game.execute("technique", {"uid": conjure_uid})
	check.call(result.events.map(func(event): return event.type) == ["technique", "card_created", "card_created"] and game.hand.slice(-2).all(func(card): return card.id == "test_free_shield") and _unique_cards(game), "Conjure honors both configured generated-rune ID and count with separate unique instances/events.")
	check.call(_permanent_counts(game) == _counts(loaded.setup.owned_cards), "Generated cards remain outside the permanent ownership multiset.")
	game.place_rune(1, game.hand.back().uid)
	check.call(game.forecast().shield == 8 and game.forecast().damage == 0 and game.forecast().cost == 1, "Generated target effects execute consistently when installed into the unchanged circuit.")
	game.pass_turn()
	check.call(not _all_cards(game).any(func(card): return card.id == "test_free_shield") and _permanent_counts(game) == _counts(loaded.setup.owned_cards), "Configured generated targets expire from hand and board without entering permanent piles.")
	var zero_documents := _documents()
	zero_documents.runes[3].value = 0
	var zero_setup := Loader.validate_documents(zero_documents)
	check.call(zero_setup.ok, "A zero-count conjure definition is a valid explicit no-creation technique.")
	if zero_setup.ok:
		var zero_game := Combat.new(zero_setup.setup)
		result = zero_game.execute("technique", {"uid": zero_game.hand[2].uid})
		check.call(result.accepted and result.events.map(func(event): return event.type) == ["technique"] and zero_game.hand.size() == 2, "A zero conjure value commits the technique but creates no fallback rune.")

	game = Combat.new(loaded.setup)
	for corrupt in ["effect", "type"]:
		game.reset()
		game.catalog.conjure[corrupt] = "unsupported"
		var before := game.snapshot()
		result = game.execute("technique", {"uid": game.hand[1].uid})
		check.call(not result.accepted and result.events.is_empty() and game.energy == before.energy and game.hand == before.hand and game.discard_pile == before.discard_pile and game.log_text.contains("Unsupported"), "Defensive unsupported " + corrupt + " rejection cannot pay, discard or accidentally Conjure.")
