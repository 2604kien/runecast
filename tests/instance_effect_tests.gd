extends RefCounted

const Effects = preload("res://scripts/core/instance_effects.gd")
const Relics = preload("res://scripts/core/relic_policy.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const ProductionContent = preload("res://tests/production_content_tests.gd")

func run(check: Callable) -> void:
	var source := ProductionContent.documents()
	# Retain the original RC-031 framework specimen rather than colliding with
	# the now-registered RC-035 definitions or relabelling its historical content.
	source.runes = Loader.read_document("res://tests/fixtures/rc035/runes-before.json").document
	source.runes.append_array(Loader.read_document("res://tests/fixtures/rc031/upgrade_framework_runes.json").document)
	source.enemies.append({"id": "rc031_effect_target", "name": "Effect Test Target", "max_health": 1000, "intents": [1]})
	source.encounter.id = "rc031_effect_framework"
	source.encounter.enemy_id = "rc031_effect_target"
	var fixture := Loader.validate_documents(source, {}, null, Rules.production_options(Rules.load_rules().rules))
	check.call(fixture.ok, "RC-031: separately excluded mixed-effect content validates through the real loader.")
	if not fixture.ok: return
	var setup: Dictionary = fixture.setup
	_contracts(check, setup, source)
	_circuits(check, setup)
	_mixed_execution(check, source)
	_instances(check, setup)
	_techniques(check, setup)
	_openings(check, setup)
	_successor(check, source)
	_relics(check)

func _entry(setup: Dictionary, rank_ids: Array = [], relics: Array = [], seed: int = 42) -> Dictionary:
	var cards: Array = []
	for id in setup.owned_cards:
		cards.append({"id": id, "uid": cards.size(), "upgrade_rank": 1 if rank_ids.has(id) else 0})
	var streams := {}
	for key in ["cards", "endpoints", "kits"]:
		var random := RandomNumberGenerator.new()
		random.seed = seed
		streams[key] = random.state
	return {"version": 1, "run_id": "rc031_effects_fixture", "encounter_id": setup.encounter.id,
		"seed": seed, "owned_cards": cards, "next_uid": cards.size(), "relics": relics.duplicate(),
		"player_hp": 30, "player_max_hp": 30, "rng_states": streams}

func _game_with(setup: Dictionary, id: String, rank_ids: Array = [], relics: Array = []) -> Combat:
	for seed in range(200):
		var entry := _entry(setup, rank_ids, relics, seed)
		var made := Combat.create_for_run(setup, entry)
		if made.ok and made.combat.hand.any(func(card): return card.id == id): return made.combat
	return null

func _card(game: Combat, id: String) -> Dictionary:
	for card in game.hand:
		if card.id == id: return card
	return {}

func _path(game: Combat, card: Dictionary) -> void:
	# A controlled graph boundary specimen, never a fabricated route victory.
	game.board = Circuit.demo_board()
	game.board[1] = {}
	game.place_rune(1, card.uid)

func _contracts(check: Callable, setup: Dictionary, documents: Dictionary) -> void:
	var legacy := ProductionContent.documents()
	legacy.runes = Loader.read_document("res://tests/fixtures/rc035/runes-before.json").document
	var production: Dictionary = Loader.validate_documents(legacy, {}, null, Rules.production_options(Rules.load_rules().rules)).setup.catalog
	check.call(Effects.contracts().size() == 8 and production.size() == 5, "RC-031 legacy: eight explicit contracts do not add missing bases to the retained five-definition catalogue.")
	var eligible: Array = []
	for id in production:
		if Effects.eligible(production, {"id": id}): eligible.append(id)
	eligible.sort()
	check.call(eligible == ["conjure", "focus", "shield", "spark"], "RC-031 legacy: only its four present permanent bases are eligible.")
	for id in Effects.contracts():
		var base := {"id": id, "uid": 123, "upgrade_rank": 0}
		var upgraded := {"id": id, "uid": 123, "upgrade_rank": 1}
		var before: Dictionary = setup.catalog.duplicate(true)
		var preview := Effects.upgrade_preview(setup.catalog, base)
		var contract: Dictionary = Effects.contracts()[id]
		check.call(preview.ok and preview.before.value == contract.before and preview.after.value == contract.after and preview.after.cost == contract.cost and preview.upgrade_id == contract.id, "RC-031: %s preview resolves exact before/after values and unchanged physical cost." % id)
		check.call(Effects.resolve(setup.catalog, upgraded).definition == preview.after and not Effects.eligible(setup.catalog, upgraded) and setup.catalog == before and base.upgrade_rank == 0, "RC-031: %s is single-rank, detached and leaves base content unchanged." % id)
	for rank in [-1, 2, 1.0, true, "1", null]:
		check.call(not Effects.resolve(setup.catalog, {"id": "spark", "upgrade_rank": rank}).ok, "RC-031: malformed rank %s cannot resolve." % str(rank))
	check.call(not Effects.resolve(setup.catalog, {"id": "free_spark", "upgrade_rank": 1}).ok and not Effects.eligible(setup.catalog, {"id": "straight"}), "RC-031: generated Free Spark and connectors cannot upgrade.")
	for field in ["type", "effect", "temporary", "value", "cost"]:
		for value in [[], {}, null]:
			var hostile: Dictionary = setup.catalog.duplicate(true)
			hostile.spark[field] = value
			check.call(not Effects.resolve(hostile, {"id": "spark", "upgrade_rank": 1}).ok, "RC-031: resolver rejects malformed %s without an engine exception." % field)
	var malformed := documents.duplicate(true)
	malformed.runes[-1].value = 4
	check.call(not Loader.validate_documents(malformed, {}, null, Rules.production_options(Rules.load_rules().rules)).ok, "RC-031: a scalar mixed-effect placeholder is rejected by content validation.")
	malformed = documents.duplicate(true)
	malformed.runes[-1].value.shield = -1
	check.call(not Loader.validate_documents(malformed, {}, null, Rules.production_options(Rules.load_rules().rules)).ok, "RC-031: malformed mixed-effect contributions are rejected.")

func _circuits(check: Callable, setup: Dictionary) -> void:
	var board := Circuit.demo_board()
	board[1].rune_id = "spark"
	board[1].upgrade_rank = 1
	var options: Dictionary = setup.production.duplicate(true)
	options.relics = ["relic_ember_lens", "relic_ward_seal"]
	var spell := Circuit.evaluate(board, setup.catalog, options)
	check.call(spell.valid and spell.damage == 18 and spell.shield == 0 and spell.cost == 3, "RC-031: upgraded Spark doubles to 16 through Split/Join, then Ember Lens adds 2 once; physical cost is three.")
	board[1].rune_id = "cinder_guard"
	spell = Circuit.evaluate(board, setup.catalog, options)
	check.call(spell.valid and spell.damage == 14 and spell.shield == 10 and spell.cost == 3, "RC-031: genuine mixed upgrade propagates 6 damage AND 4 shield twice, charges one rune, then applies each final relic once.")
	var historical := {"relics": options.relics, "damage_mode": "multi_hit"}
	spell = Circuit.evaluate(board, setup.catalog, historical)
	check.call(spell.valid and spell.damage == 14 and spell.hits == [6, 8] and spell.shield == 10 and spell.cost == 3, "RC-031: historical hit-list evaluation receives the single final bonus, never a bonus per hit.")
	board[1] = {"kind": "straight", "rotation": 0}
	spell = Circuit.evaluate(board, setup.catalog, options)
	check.call(spell.valid and spell.damage == 0 and spell.shield == 0, "RC-031: zero pre-relic output stays zero for both conditional bonuses.")
	board[7] = {}
	spell = Circuit.evaluate(board, setup.catalog, options)
	check.call(not spell.valid and spell.damage == 0 and spell.shield == 0 and spell.cost == 0, "RC-031: invalid graph grants no output, bonuses or charged cost.")

func _instances(check: Callable, setup: Dictionary) -> void:
	var entry := _entry(setup)
	entry.owned_cards[0].upgrade_rank = 1
	var made := Combat.create_for_run(setup, entry)
	check.call(made.ok, "RC-031: explicit ranked run entry is accepted.")
	var game: Combat = made.combat
	var cards: Array = game.hand + game.draw_pile
	var sparks := cards.filter(func(card): return card.id == "spark")
	check.call(sparks.size() == 2 and sparks.filter(func(card): return Effects.resolve(game.catalog, card).definition.value == 8).size() == 1 and sparks.filter(func(card): return Effects.resolve(game.catalog, card).definition.value == 6).size() == 1, "RC-031: two identical definitions independently resolve one upgraded and one ordinary UID.")
	game = _game_with(setup, "spark", ["spark"])
	var card := _card(game, "spark").duplicate(true)
	_path(game, card)
	check.call(game.board[1].upgrade_rank == 1 and game.forecast().damage == 16 and game.run_handoff().ok, "RC-031: installation carries exact rank into circuit evaluation and handoff validation.")
	check.call(game.place_wire(1, "erase") and game.hand.has(card) and game.run_handoff().ok, "RC-031: Remove returns the same ID/UID/rank to hand.")
	game.place_rune(1, card.uid)
	var result := game.execute("cast")
	check.call(result.accepted and result.events.filter(func(event): return event.type == "effect_consumed")[0].card == card and game.run_handoff().ok, "RC-031: cast cleanup events and all retained zones preserve exact upgraded instances.")
	for turn in range(4): game.pass_turn()
	var handoff := game.run_handoff()
	check.call(handoff.ok and handoff.owned_cards.has(card), "RC-031: repeated cleanup, discard and reshuffle preserve rank and ownership.")
	var next := _entry(setup)
	next.owned_cards = handoff.owned_cards
	next.rng_states = handoff.rng_states
	next.next_uid = handoff.next_uid
	next.player_hp = handoff.player_hp
	var later := Combat.create_for_run(setup, next)
	check.call(later.ok and later.combat.run_handoff().owned_cards == handoff.owned_cards, "RC-031: the next battle receives exactly the prior upgraded ownership.")
	game.hand[0].erase("upgrade_rank")
	check.call(not game.run_handoff().ok, "RC-031: dropping rank at a live boundary rejects instead of silently downgrading.")
	game = _game_with(setup, "spark", ["spark"], ["relic_ember_lens", "relic_ward_seal"])
	_path(game, _card(game, "spark"))
	game.energy = 2
	var hp := game.enemy_hp
	result = game.execute("cast")
	check.call(not result.accepted and result.events.is_empty() and game.enemy_hp == hp and game.energy == 2, "RC-031: an unaffordable upgraded cast has no effects or payment.")
	game.energy = 3
	game.enemy_hp = 18
	result = game.execute("cast")
	check.call(result.accepted and result.before.forecast.damage == 18 and result.events[0].spell.damage == 18 and game.state == "victory" and game.player_hp == 30 and result.events.filter(func(event): return event.type == "retaliation").is_empty() and game.run_handoff().ok, "RC-031: forecast, cast event and lethal execution agree; existing retaliation skip and terminal cleanup remain intact.")
	game = _game_with(setup, "shield", ["shield"], ["relic_ward_seal"])
	_path(game, _card(game, "shield"))
	result = game.execute("pass")
	check.call(result.accepted and game.player_hp == 29 and result.events.filter(func(event): return event.type in ["cast", "shield"]).is_empty(), "RC-031: Pass receives no cast shielding even with an upgraded Shield and Ward Seal installed.")

func _mixed_execution(check: Callable, source: Dictionary) -> void:
	var documents := source.duplicate(true)
	documents.loadouts[0].owned_cards[0] = "cinder_guard"
	var loaded := Loader.validate_documents(documents, {}, null, Rules.production_options(Rules.load_rules().rules))
	check.call(loaded.ok, "RC-031: the explicit mixed-effect fixture loadout validates without editing the live catalogue.")
	if not loaded.ok: return
	var game := _game_with(loaded.setup, "cinder_guard", ["cinder_guard"], ["relic_ember_lens", "relic_ward_seal"])
	_path(game, _card(game, "cinder_guard"))
	var result := game.execute("cast")
	check.call(result.accepted and game.enemy_hp == 986 and game.player_hp == 30 and result.events[0].spell.damage == 14 and result.events[0].spell.shield == 10 and result.events[0].energy_after == 0 and game.run_handoff().ok, "RC-031: mixed fixture actually casts both amplified contributions, applies both final bonuses, charges once and conserves its upgraded UID.")

func _techniques(check: Callable, setup: Dictionary) -> void:
	var game := _game_with(setup, "focus", ["focus"])
	var card := _card(game, "focus").duplicate(true)
	var result := game.execute("technique", {"uid": card.uid})
	check.call(result.accepted and result.events.filter(func(event): return event.type == "card_drawn").size() == 3 and game.energy == 2 and game.discard_pile.has(card) and game.run_handoff().ok, "RC-031: upgraded Focus pays one energy, draws three and discards its exact ranked UID.")
	game = _game_with(setup, "conjure", ["conjure"])
	var next_uid := game.next_uid
	result = game.execute("technique", {"uid": _card(game, "conjure").uid})
	var created: Array = result.events.filter(func(event): return event.type == "card_created")
	check.call(result.accepted and created.size() == 2 and created[0].card.uid == next_uid and created[1].card.uid == next_uid + 1 and created.all(func(event): return event.card.id == "free_spark" and event.card.upgrade_rank == 0) and game.energy == 3, "RC-031: upgraded Conjure creates two distinct temporary unupgraded Free Spark UIDs for zero energy.")
	game.pass_turn()
	check.call((game.hand + game.draw_pile + game.discard_pile).all(func(value): return value.id != "free_spark") and game.next_uid == next_uid + 2 and game.run_handoff().ok, "RC-031: both generated cards expire normally while allocator gaps and owned ranks remain conserved.")

func _openings(check: Callable, setup: Dictionary) -> void:
	var ordinary: Combat = Combat.create_for_run(setup, _entry(setup)).combat
	var entry := _entry(setup, ["spark"], ["relic_opening_tome", "relic_copper_coil"])
	var game: Combat = Combat.create_for_run(setup, entry).combat
	var replay: Combat = Combat.create_for_run(setup, entry).combat
	var opening := game.snapshot()
	check.call(opening.hand.size() == 4 and game.energy == 4 and opening.board == ordinary.board and opening.kit == ordinary.snapshot().kit and game.rng.state == ordinary.rng.state, "RC-031: opening relics add one owned draw after the normal draw and one energy without consuming unrelated random streams.")
	check.call(game.snapshot() == opening and game.snapshot() == replay.snapshot() and game.run_handoff() == replay.run_handoff(), "RC-031: inspection and exact entry replay reproduce the opening without repeating effects.")
	game.pass_turn()
	check.call(game.turn == 2 and game.hand.size() == 3 and game.energy == 3, "RC-031: later turns return to the configured three cards and three energy.")
	var hostile := entry.duplicate(true)
	hostile.relics.append("relic_copper_coil")
	check.call(not Combat.create_for_run(setup, hostile).ok, "RC-031: duplicate relic ownership rejects before battle construction.")

func _relics(check: Callable) -> void:
	check.call(Relics.validate_definitions(Relics.definitions()).is_empty() and Relics.definitions().size() == 6, "RC-031: all six bounded provisional relic definitions validate.")
	var hostile := Relics.definitions()
	hostile.relic_heart_stone.hook = "every_turn"
	check.call(not Relics.validate_definitions(hostile).is_empty(), "RC-031: unrestricted or changed relic hooks are rejected.")
	for field in ["id", "hook", "name", "description", "value"]:
		for value in [[], {}, null]:
			hostile = Relics.definitions()
			hostile.relic_heart_stone[field] = value
			check.call(not Relics.validate_definitions(hostile).is_empty(), "RC-031: relic definition rejects malformed %s without an engine exception." % field)
	var random := RandomNumberGenerator.new()
	random.seed = 91
	var five := Relics.ORDER.duplicate()
	five.erase("relic_heart_stone")
	check.call(Relics.offer(five, 2, random) == ["relic_heart_stone"] and Relics.offer(Relics.ORDER, 2, random).is_empty(), "RC-031: smaller and exhausted relic pools return fewer distinct unowned choices without compensation.")
	check.call(Relics.acquire_health("relic_heart_stone", 21, 30) == {"player_hp": 25, "player_max_hp": 34} and Relics.acquire_health("relic_opening_tome", 21, 30) == {"player_hp": 21, "player_max_hp": 30}, "RC-031: only Heart Stone's acquisition hook adds four current and maximum HP.")
	check.call(Relics.recovery_amount([], 10) == 10 and Relics.recovery_amount(["relic_menders_token"], 10) == 14, "RC-031: Mender's Token augments only the explicit recovery hook.")

func _successor(check: Callable, source: Dictionary) -> void:
	var documents := source.duplicate(true)
	documents.enemies[-1].max_health = 6
	var options := Rules.production_options(Rules.load_rules().rules)
	var first: Dictionary = Loader.validate_documents(documents, {}, null, options).setup
	documents.encounter.id = "rc031_effect_framework_successor"
	var second: Dictionary = Loader.validate_documents(documents, {}, null, options).setup
	var validated := Loader.validate_transition(first, second)
	check.call(validated.ok, "RC-031: the separately named low-health framework successor validates through the real transition contract.")
	first.next_encounter = validated.setup
	var game: Combat
	for seed in range(200):
		game = Combat.new(first, seed)
		if not _card(game, "spark").is_empty(): break
	# This standalone successor has no RunState acquisition seam. Set passive
	# ownership only at the explicit mechanics boundary; production transactions
	# and entry-replay ownership are tested separately through RunState.
	game.relics = ["relic_opening_tome", "relic_copper_coil"]
	_path(game, _card(game, "spark"))
	check.call(game.cast() and game.state == "victory", "RC-031: actual fixture cast wins before the standalone successor seam becomes available.")
	var moved := game.execute("next_encounter")
	check.call(moved.accepted and game.energy == 4 and game.hand.size() == 4 and game.turn == 1, "RC-031: a validated next encounter receives Tome/Coil opening benefits once.")
	game.pass_turn()
	check.call(game.energy == 3 and game.hand.size() == 3 and game.turn == 2, "RC-031: the successor's later turns do not repeat opening benefits.")
