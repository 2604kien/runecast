extends SceneTree
## Excluded, reproducible catalogue mechanics checks. Combat specimens use
## explicitly declared owned pools and real production enemies; all actions
## after construction use the ordinary guarded Combat command API.
const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Effects = preload("res://scripts/core/instance_effects.gd")
const Relics = preload("res://scripts/core/relic_policy.gd")
const Production = preload("res://tests/production_content_tests.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
const Fixture = preload("res://tests/helpers/rc035_catalogue_fixture.gd")
const Rooms = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Save = preload("res://scripts/core/local_save.gd")
const DESTINATION := "res://output/qa/rc-035/catalogue"
var checks := 0
var failures: Array = []
var assertions: Array = []
var journeys: Array = []
var restart_cases: Array = []

class Driver extends RefCounted:
	var game
	var commands: Array = []
	func _init(value): game = value
	func snapshot() -> Dictionary: return game.snapshot()
	func command(action: String, arguments: Dictionary = {}) -> bool:
		var result: Dictionary = game.execute(action, arguments)
		commands.append({"action": action, "arguments": arguments.duplicate(true), "accepted": result.accepted})
		return result.accepted
	func is_busy() -> bool: return false

func check(ok: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": message})
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	if "--restart" in OS.get_cmdline_user_args():
		_restart()
		FileAccess.open(DESTINATION.path_join("restart-results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "failure_count": failures.size(), "assertions": assertions, "engine": Engine.get_version_info().string, "process_id": OS.get_process_id()}, "\t"))
		print("RC-035 catalogue restart: %d checks, %d failures" % [checks, failures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	_catalogue()
	_runes()
	_draws()
	_conjures()
	_upgrades()
	_markets()
	_services()
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "failure_count": failures.size(), "assertions": assertions, "engine": Engine.get_version_info().string}, "\t"))
	FileAccess.open(DESTINATION.path_join("combat-commands.json"), FileAccess.WRITE).store_string(JSON.stringify(journeys, "\t"))
	FileAccess.open(DESTINATION.path_join("restart-cases.bin"), FileAccess.WRITE).store_buffer(var_to_bytes({"process_id": OS.get_process_id(), "cases": restart_cases}))
	print("RC-035 catalogue: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _documents(ids: Array, enemy_path: String = "res://data/production_wickling_encounter.json") -> Dictionary:
	var source := Production.documents()
	source.encounter = Loader.read_document(enemy_path).document
	source.loadouts[0].owned_cards = ids.duplicate()
	return source

func _setup(ids: Array, enemy_path: String = "res://data/production_wickling_encounter.json") -> Dictionary:
	var loaded := Loader.validate_documents(_documents(ids, enemy_path), {}, null, Rules.production_options(Rules.load_rules().rules))
	return loaded.setup if loaded.ok else {}

func _entry(setup: Dictionary, seed: int = 42, ranks: Array = [], relics: Array = [], hp: int = 30) -> Dictionary:
	var cards: Array = []
	for id in setup.owned_cards: cards.append({"id": id, "uid": cards.size(), "upgrade_rank": 1 if id in ranks else 0})
	var streams := {}
	for key in ["cards", "endpoints", "kits"]:
		var random := RandomNumberGenerator.new()
		random.seed = seed
		streams[key] = random.state
	return {"version": 1, "run_id": "rc035_explicit_catalogue_combat", "encounter_id": setup.encounter.id,
		"seed": seed, "owned_cards": cards, "next_uid": cards.size(), "relics": relics.duplicate(),
		"player_hp": hp, "player_max_hp": 30, "rng_states": streams}

func _game(ids: Array, seed: int = 42, ranks: Array = [], relics: Array = [], hp: int = 30):
	var setup := _setup(ids)
	var made := Combat.create_for_run(setup, _entry(setup, seed, ranks, relics, hp))
	return made.combat if made.ok else null

func _with_card(ids: Array, id: String):
	for seed in 100:
		var game = _game(ids, seed)
		if game != null and game.hand.any(func(card): return card.id == id): return game
	return null

func _card(game, id: String) -> Dictionary:
	for card in game.hand:
		if card.id == id: return card
	return {}

func _catalogue() -> void:
	var loaded := Loader.load_setup()
	check(loaded.ok, "Full production catalogue validates before constructing any model.")
	if not loaded.ok: return
	var catalog: Dictionary = loaded.setup.catalog
	var owned: Array = catalog.keys().filter(func(id): return not catalog[id].get("temporary", false))
	var expected := Fixture.IDS.duplicate()
	owned.sort()
	expected.sort()
	check(catalog.size() == 13 and owned == expected and catalog.free_spark.temporary, "Exactly twelve registered ownable definitions and one separate temporary Free Spark exist.")
	var original: Array = Loader.read_document("res://tests/fixtures/rc035/runes-before.json").document
	var current: Array = Loader.read_document("res://data/runes.json").document
	for definition in original:
		check(current.filter(func(row): return row.id == definition.id) == [definition], "Original %s definition is byte-value equivalent to the retained pre-expansion contract." % definition.id)
	var contracts := {"ember": ["damage", 3, 1], "flare": ["damage", 10, 3], "barrier": ["shield", 9, 2], "bulwark": ["shield", 13, 3], "deep_focus": ["draw", 4, 2], "twin_conjure": ["conjure", 2, 1], "cinder_guard": ["damage_shield", {"damage": 4, "shield": 3}, 2], "ward_spark": ["damage_shield", {"damage": 2, "shield": 2}, 1]}
	for id in contracts:
		var spec: Array = contracts[id]
		var definition: Dictionary = catalog[id]
		check(definition.effect == spec[0] and definition.value == spec[1] and definition.cost == spec[2] and definition.get("port_shape", "straight") == "straight", "%s has its exact accepted effect, energy cost and straight rune ports." % id)
		check(not Effects.effect_summary(definition).contains("Unsupported") and not definition.name.begins_with("Fixture"), "%s has a real production name and truthful shared value-aware description." % id)
	check(catalog.twin_conjure.generated_rune_id == "free_spark" and catalog.free_spark.value == 6 and catalog.free_spark.cost == 0, "Twin Conjure references the unchanged zero-cost, six-damage generated definition.")
	check(loaded.setup.owned_cards == ["spark", "shield", "conjure", "spark", "shield", "focus", "focus", "conjure"], "The original eight-card starter and its order remain unchanged.")
	for id in ["bulwark", "deep_focus", "twin_conjure", "ward_spark", "free_spark", "straight", "missing"]:
		check(not Effects.eligible(catalog, {"id": id, "uid": 1, "upgrade_rank": 0}) and not Effects.resolve(catalog, {"id": id, "uid": 1, "upgrade_rank": 1}).ok, "%s cannot acquire an unsupported upgrade rank." % id)
	for id in ["cinder_guard", "ward_spark"]:
		for bad in [4, {"damage": 4}, {"damage": 4, "shield": -1}, {"damage": 4, "shield": 3, "heal": 1}]:
			var source := _documents([id])
			for row in source.runes:
				if row.id == id: row.value = bad
			check(not Loader.validate_documents(source, {}, null, Rules.production_options(Rules.load_rules().rules)).ok, "%s rejects malformed mixed values %s." % [id, str(bad)])
	check(Relics.definitions().size() == 6 and Relics.validate_definitions(Relics.definitions()).is_empty(), "Exactly the six authoritative existing relic contracts remain supported.")
	check(Relics.DEFINITIONS.relic_menders_token.description.contains("No Combat or Blood Tithe effect"), "Mender's Token explicitly describes its recovery-only limitation.")

func _runes() -> void:
	for id in ["ember", "flare", "barrier", "bulwark", "cinder_guard", "ward_spark"]:
		var witnessed := false
		for seed in 100:
			var game = _game([id], seed)
			var driver := Driver.new(game)
			var plan: Dictionary = Player.new().prepare(driver)
			if plan.is_empty() or plan.has("error") or plan.placed.is_empty(): continue
			var forecast: Dictionary = game.forecast()
			var old_hp: int = game.enemy_hp
			var old_player_hp: int = game.player_hp
			var incoming: int = game.intent()
			var result: Dictionary = game.execute("cast")
			check(result.accepted and forecast.valid and game.enemy_hp == maxi(0, old_hp - forecast.damage) and game.player_hp == old_player_hp - maxi(0, incoming - forecast.shield), "%s executes its real effect through legal placement/rotation/Cast against production Wickling." % id)
			var paid: int = result.events[0].energy_before - result.events[0].energy_after
			check(paid == forecast.cost and paid == game.catalog[id].cost + int(plan.shape.splits), "%s pays for its physical rune once, plus each actual Split, independently of amplification." % id)
			check(game.run_handoff().ok and game.run_handoff().owned_cards == [{"id": id, "uid": 0, "upgrade_rank": 0}], "%s survives real cast cleanup/next draw with its exact owned UID." % id)
			journeys.append({"definition": id, "seed": seed, "fixture_owned": [id], "enemy": "wickling", "commands": driver.commands + [{"action": "cast", "accepted": result.accepted}], "forecast": forecast, "events": result.events})
			witnessed = true
			break
		check(witnessed, "%s has a reproducible legal production-Combat execution specimen." % id)
	for id in ["cinder_guard", "ward_spark"]:
		var board := Circuit.demo_board()
		board[1].rune_id = id
		var options: Dictionary = Loader.load_setup().setup.production
		options.relics = ["relic_ember_lens", "relic_ward_seal"]
		var spell := Circuit.evaluate(board, Loader.load_setup().setup.catalog, options)
		var values: Dictionary = Loader.load_setup().setup.catalog[id].value
		check(spell.valid and spell.damage == values.damage * 2 + 2 and spell.shield == values.shield * 2 + 2 and spell.cost == Loader.load_setup().setup.catalog[id].cost + 1, "%s propagates both values through Split/Join; each final relic adds exactly two once." % id)

func _draws() -> void:
	for ids in [["deep_focus"], ["deep_focus", "ember"], ["deep_focus", "ember", "shield", "conjure"], Fixture.IDS]:
		var game = _with_card(ids, "deep_focus")
		check(game != null, "Deep Focus fixture has an ordinary shuffled opening containing the technique.")
		if game == null: continue
		var before_hand: int = game.hand.size()
		var available: int = game.draw_pile.size() + game.discard_pile.size() + 1
		var uid: int = _card(game, "deep_focus").uid
		var result: Dictionary = game.execute("technique", {"uid": uid})
		var draws: Array = result.events.filter(func(event): return event.type == "card_drawn")
		check(result.accepted and draws.size() == mini(4, available) and game.hand.size() == before_hand - 1 + mini(4, available) and game.energy == 1, "Deep Focus with %d owned cards draws only available cards and pays two energy." % ids.size())
		check(game.run_handoff().ok and game.run_handoff().owned_cards.size() == ids.size(), "Deep Focus with %d owned cards cannot duplicate or lose any UID." % ids.size())
		if ids.size() < 5:
			check(result.events.any(func(event): return event.type == "reshuffled") and game.hand.any(func(card): return card.uid == uid), "Short/empty draw pile reshuffles the consumed technique from discard using the existing draw rule.")
		var before: Dictionary = game.snapshot()
		var handoff: Dictionary = game.run_handoff()
		var refused: Dictionary = game.execute("technique", {"uid": uid})
		var after: Dictionary = game.snapshot()
		before.erase("log_text")
		after.erase("log_text")
		check(not refused.accepted and after == before and game.run_handoff() == handoff, "Insufficient energy/stale Deep Focus activation is guarded without changing cards or RNG.")
		journeys.append({"definition": "deep_focus", "fixture_owned": ids, "drawn": draws.size(), "events": result.events})

func _conjures() -> void:
	for terminal in [false, true]:
		var game = _game(["twin_conjure"], 42, [], [], 1 if terminal else 30)
		var uid: int = game.hand[0].uid
		var next_uid: int = game.next_uid
		var result: Dictionary = game.execute("technique", {"uid": uid})
		var created: Array = result.events.filter(func(event): return event.type == "card_created")
		check(result.accepted and created.size() == 2 and created[0].card.uid == next_uid and created[1].card.uid == next_uid + 1 and created.all(func(event): return event.card.id == "free_spark" and event.card.upgrade_rank == 0) and game.energy == 2, "Twin Conjure creates two distinct temporary rank-zero UIDs and pays one energy.")
		var before: Dictionary = game.snapshot()
		check(not game.execute("technique", {"uid": uid}).accepted and game.snapshot() == before, "The consumed Twin Conjure UID rejects repeated activation without side effects.")
		result = game.execute("pass")
		check(result.accepted and game.state == ("defeat" if terminal else "playing") and (game.hand + game.draw_pile + game.discard_pile).all(func(card): return card.id != "free_spark") and game.run_handoff().ok and game.run_handoff().owned_cards == [{"id": "twin_conjure", "uid": 0, "upgrade_rank": 0}] and game.next_uid == next_uid + 2, "Twin Conjure temporaries expire after %s cleanup while allocator gaps remain." % ("terminal defeat" if terminal else "ordinary Pass"))
		journeys.append({"definition": "twin_conjure", "terminal": terminal, "created": created, "cleanup_events": result.events})
	var won := false
	for seed in 100:
		var game = _game(["twin_conjure"], seed)
		var driver := Driver.new(game)
		for turn in 12:
			if game.state != "playing": break
			if not driver.command("technique", {"uid": 0}): break
			var plan: Dictionary = Player.new().prepare(driver)
			if plan.has("error"): break
			driver.command("pass" if plan.is_empty() else "cast")
		if game.state != "victory": continue
		check(game.run_handoff().ok and game.run_handoff().owned_cards.size() == 1 and (game.hand + game.draw_pile + game.discard_pile).all(func(card): return card.id != "free_spark"), "Twin Conjure's generated Free Sparks legally defeat production Wickling; victory cleanup excludes all temporaries from owned handoff.")
		journeys.append({"definition": "twin_conjure", "seed": seed, "result": "wickling_victory", "commands": driver.commands})
		won = true
		break
	check(won, "Twin Conjure has a legal victory specimen with terminal generated-card cleanup.")

func _upgrades() -> void:
	var catalog: Dictionary = Loader.load_setup().setup.catalog
	check(Effects.contracts().size() == 8, "The existing single-rank system still contains exactly eight upgrade contracts.")
	for id in Effects.contracts():
		var base := {"id": id, "uid": 41, "upgrade_rank": 0}
		var sibling := {"id": id, "uid": 42, "upgrade_rank": 0}
		var preview := Effects.upgrade_preview(catalog, base)
		check(preview.ok and preview.upgrade_id == "upgrade_" + id and preview.before.value == Effects.contracts()[id].before and preview.after.value == Effects.contracts()[id].after and preview.before.cost == preview.after.cost and preview.before.get("port_shape", "straight") == preview.after.get("port_shape", "straight"), "%s activates its exact existing upgrade preview without changing costs or ports." % id)
		base.upgrade_rank = 1
		check(Effects.resolve(catalog, base).definition.value == Effects.contracts()[id].after and Effects.resolve(catalog, sibling).definition.value == Effects.contracts()[id].before and not Effects.upgrade_preview(catalog, base).ok, "%s resolves independent duplicate ranks and rejects a repeated upgrade." % id)
	for rank in [-1, 2, 1.0, true, "1", null]:
		check(not Effects.resolve(catalog, {"id": "cinder_guard", "uid": 1, "upgrade_rank": rank}).ok, "Mixed rune rejects malformed rank %s." % str(rank))

func _restore(subject, payload: Dictionary = {}) -> Dictionary:
	return Run.restore_save(subject.export_save() if payload.is_empty() else payload, Loader.load_setup().setup, subject.profile_state().clone_for_transaction(), subject.restore_context_for_tests())

func _markets() -> void:
	var additions := Fixture.IDS.slice(4)
	var locked = ShopFixture.new_run(42, 500)
	check(ShopFixture.win_first(locked).ok, "Ordinary initial-unlock fixture earns explicit funding without opening locked definitions.")
	var locked_before: Dictionary = locked.export_save()
	for id in additions:
		check(not locked.purchase_store_rune(locked.store_snapshot().identity, id).ok and locked.export_save() == locked_before, "Funded Store still rejects locked %s without mutation." % id)
	check(ShopFixture.enter_shop(locked).ok and locked.shop_snapshot().eligible_ids.size() == 4 and locked.shop_snapshot().slots.all(func(slot): return slot.definition_id in Profile.INITIAL_IDS), "Funded route shop excludes all eight locked definitions from stock.")
	var unfunded = Fixture.new_run()
	var unfunded_before: Dictionary = unfunded.export_save()
	check(unfunded.store_snapshot().runes.size() == 12, "Explicit all-unlocked fixture Store registers twelve distinct fixed rune entries.")
	for id in additions:
		check(not unfunded.purchase_store_rune(unfunded.store_snapshot().identity, id).ok and unfunded.export_save() == unfunded_before, "Unlocked %s cannot be bought without the required 45 Gold." % id)
	for id in additions:
		var subject = Fixture.new_run()
		check(ShopFixture.win_first(subject).ok, "%s purchase witness earns real fixture battle funding." % id)
		var stale: Dictionary = subject.store_snapshot().identity
		check(subject.purchase_store_relic(stale, "relic_ember_lens").ok, "%s witness first spends its separate relic allowance." % id)
		var before: Dictionary = subject.export_save()
		check(not subject.purchase_store_rune(stale, id).ok and subject.export_save() == before, "%s rejects a stale pre-relic Store confirmation." % id)
		var bought: Dictionary = subject.purchase_store_rune(subject.store_snapshot().identity, id)
		check(bought.ok and bought.gold_spent == 45 and bought.granted_card.upgrade_rank == 0 and subject._gold == 365 and _restore(subject).ok, "%s purchase grants a fresh rank-zero copy with exact independent 45/90 receipts." % id)
		before = subject.export_save()
		for request in [id, "spark", "free_spark", "missing"]:
			check(not subject.purchase_store_rune(subject.store_snapshot().identity, request).ok and subject.export_save() == before, "%s purchase rejects repeated/second/unsupported request %s without spending." % [id, request])
		var corrupt: Dictionary = subject.export_save()
		corrupt.store.transactions[1].eligible_rune_ids.erase(id)
		check(not _restore(subject, corrupt).ok, "%s receipt cannot forge a narrower retained eligibility pool." % id)
		corrupt = subject.export_save()
		corrupt.store.version = 1
		corrupt.store.policy_id = "rc032_store_v1"
		check(not _restore(subject, corrupt).ok, "%s new-content receipt cannot claim historical Store policy." % id)
	var poor = ShopFixture.new_run(42, 20, Fixture.IDS)
	check(ShopFixture.win_first(poor).ok and ShopFixture.enter_shop(poor).ok, "All-unlocked low-income route-shop fixture opens with exactly twenty earned Gold.")
	var poor_before: Dictionary = poor.export_save()
	for slot in poor.shop_snapshot().slots:
		check(not poor.buy_shop_rune(poor.shop_snapshot().identity, slot.slot_id).ok and poor.export_save() == poor_before, "Route-shop insufficient funds preserve exact stock and all ownership.")
	var seen := {}
	for seed in 32:
		var subject = ShopFixture.new_run(seed, 500, Fixture.IDS)
		if not ShopFixture.win_first(subject).ok or not ShopFixture.enter_shop(subject).ok: continue
		var shop: Dictionary = subject.shop_snapshot()
		check(shop.eligible_ids.size() == 12 and shop.slots.size() == 3 and shop.slots[0].definition_id != shop.slots[1].definition_id and shop.slots[1].definition_id != shop.slots[2].definition_id and shop.slots[0].definition_id != shop.slots[2].definition_id, "Expanded route shop retains three distinct definition slots sampled from all twelve.")
		for slot in shop.slots:
			if slot.definition_id not in additions or seen.has(slot.definition_id): continue
			var before: Dictionary = subject.export_save()
			var stale: Dictionary = shop.identity.duplicate(true)
			stale.visit_id += "-stale"
			check(not subject.buy_shop_rune(stale, slot.slot_id).ok and subject.export_save() == before, "%s route stock rejects an identity from another visit." % slot.definition_id)
			var bought: Dictionary = subject.buy_shop_rune(shop.identity, slot.slot_id)
			check(bought.ok and bought.gold_spent == 30 and bought.granted_card.id == slot.definition_id and bought.granted_card.upgrade_rank == 0 and not subject.store_snapshot().rune_purchased and _restore(subject).ok, "%s route purchase preserves its separate 30-Gold price and does not consume the Store allowance." % slot.definition_id)
			before = subject.export_save()
			check(not subject.buy_shop_rune(shop.identity, slot.slot_id).ok and subject.export_save() == before, "%s sold route slot cannot grant a duplicate or charge twice." % slot.definition_id)
			seen[slot.definition_id] = true
		for version in [1, 3, "2", null, []]:
			var corrupt: Dictionary = subject.export_save()
			corrupt.shop_records[0].eligibility_version = version
			check(not _restore(subject, corrupt).ok, "Expanded shop rejects malformed or historical eligibility marker %s." % str(version))
		if seen.size() == additions.size(): break
	check(seen.size() == 8, "Every added definition has a real retained-stock route-shop purchase witness.")

func _services() -> void:
	for id in Effects.contracts():
		var acquired := Fixture.purchased(id)
		check(acquired.ok, "%s is acquired as rank zero through the funded fixture's ordinary Store purchase: %s" % [id, acquired.get("error", "")])
		if not acquired.ok: continue
		var subject = acquired.run
		var card: Dictionary = acquired.card
		check(card.upgrade_rank == 0 and card.uid >= 8 and subject._gold == 455 and _restore(subject).ok, "%s Store purchase has a fresh UID, exact 45-Gold receipt and restorable ownership." % id)
		check(Rooms.enter_service(subject).ok, "%s enters the supported recovery refinement service." % id)
		var identity: Dictionary = subject.service_snapshot().identity
		var before: Dictionary = subject.export_save()
		check(not subject.resolve_service(identity, "refine_rune", -1).ok and subject.export_save() == before, "%s rejects a stale exact target without consuming recovery." % id)
		var clone: Dictionary = subject.clone_for_transaction()
		check(clone.run.resolve_service(identity, "refine_rune", card.uid).ok and subject.export_save() == before, "%s refinement changes only its detached candidate before durable publication." % id)
		var exact: Dictionary = clone.run.export_save()
		var path := DESTINATION.path_join("service-" + id + "-%d.json" % Time.get_ticks_usec())
		var store = Save.new(path, func(payload): return _restore(subject, payload.run))
		check(store.load().status == "empty" and store.commit({"run": before}, 0).ok, "%s persists the exact pre-refinement checkpoint." % id)
		for point in ["write", "flush", "close", "backup", "replace"]:
			store.failure_point = point
			check(not store.commit({"run": exact}, 1).ok and subject.export_save() == before and clone.run.export_save() == exact, "%s %s failure preserves owners and the identical Retry candidate." % [id, point])
		store.failure_point = ""
		check(store.commit({"run": exact}, 1).ok, "%s Retry saves the identical candidate." % id)
		subject.publish_transaction(clone.run)
		var loaded: Dictionary = Save.new(path, func(payload): return _restore(subject, payload.run)).load()
		check(loaded.ok and loaded.payload.run == exact and _restore(subject, loaded.payload.run).ok, "%s survives local save/reload with its service receipt and Store allowance." % id)
		restart_cases.append({"id": id, "uid": card.uid, "path": path, "expected": exact})
		check(subject._owned_card(card.uid).upgrade_rank == 1 and not subject.resolve_service(identity, "refine_rune", card.uid).ok and subject._owned_cards.filter(func(item): return item.uid != card.uid).all(func(item): return item.upgrade_rank == 0), "%s upgrades exactly the purchased UID once; every duplicate remains rank zero." % id)
		_ranked_zones(subject, id, card.uid)
		check(Rooms.enter_shop(subject).ok, "%s can enter the next route shop with its ranked copy." % id)
		var shop: Dictionary = subject.shop_snapshot()
		check(subject.remove_shop_rune(shop.identity, card.uid).ok and subject._owned_card(card.uid).is_empty() and subject.store_snapshot().rune_purchased and _restore(subject).ok, "%s exact-copy removal preserves rank history, Store cap and valid chronological ownership." % id)

func _ranked_zones(subject, id: String, uid: int) -> void:
	# Explicit Combat boundary specimens borrow the real purchased/refined
	# collection. They do not edit the run or fabricate a completed visit.
	var ids: Array = subject._owned_cards.map(func(card): return card.id)
	var setup := _setup(ids)
	var game
	for seed in 100:
		var entry := _entry(setup, seed)
		entry.owned_cards = subject._owned_cards.duplicate(true)
		entry.next_uid = subject._next_uid
		var made := Combat.create_for_run(setup, entry)
		if made.ok and made.combat.hand.any(func(card): return card.uid == uid):
			game = made.combat
			break
	check(game != null, "%s purchased/refined copy enters a real enemy's ordinary opening draw." % id)
	if game == null: return
	var card: Dictionary = subject._owned_card(uid).duplicate(true)
	if setup.catalog[id].type == "rune":
		var cell := -1
		for index in 16:
			if game.board[index].is_empty():
				cell = index
				break
		check(game.execute("place_rune", {"index": cell, "uid": uid}).accepted and game.board[cell].upgrade_rank == 1 and game.run_handoff().ok, "%s retains rank and exact UID when installed." % id)
		check(game.execute("place_wire", {"index": cell, "kind": "erase"}).accepted and game.hand.has(card), "%s Remove returns the same ranked card to hand." % id)
		game.execute("place_rune", {"index": cell, "uid": uid})
	else:
		var activated: Dictionary = game.execute("technique", {"uid": uid})
		check(activated.accepted and game.run_handoff().owned_cards.has(card), "%s activates its purchased upgrade through the actual technique guard." % id)
	game.execute("pass")
	check(game.run_handoff().ok and game.run_handoff().owned_cards.has(card), "%s survives ordinary full-turn discard/draw cleanup with its rank." % id)
	for turn in 2: game.execute("pass")
	var handoff: Dictionary = game.run_handoff()
	check(handoff.ok and handoff.owned_cards.has(card), "%s preserves its exact rank through repeated discard and reshuffle." % id)
	var next_setup := _setup(ids, "res://data/production_stone_sentinel_encounter.json")
	var next_entry := _entry(next_setup)
	next_entry.owned_cards = handoff.owned_cards
	next_entry.next_uid = handoff.next_uid
	next_entry.rng_states = handoff.rng_states
	next_entry.player_hp = handoff.player_hp
	var next := Combat.create_for_run(next_setup, next_entry)
	check(next.ok and next.combat.run_handoff().owned_cards == handoff.owned_cards, "%s transfers its exact ranked owned boundary and allocator into real Stone Sentinel content." % id)

func _restart() -> void:
	var expected: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(DESTINATION.path_join("restart-cases.bin")))
	check(expected.process_id != OS.get_process_id() and expected.cases.size() == 8, "All eight upgrade restart cases cross a distinct operating-system process.")
	for specimen in expected.cases:
		var subject = Fixture.new_run()
		var loaded: Dictionary = Save.new(specimen.path, func(payload): return _restore(subject, payload.run)).load()
		check(loaded.ok and loaded.payload.run == specimen.expected, "%s fresh process loads identical durable refinement bytes and exact allocator/history." % specimen.id)
		if not loaded.ok: continue
		var restored := _restore(subject, loaded.payload.run)
		check(restored.ok and restored.run._owned_card(specimen.uid) == {"id": specimen.id, "uid": specimen.uid, "upgrade_rank": 1} and restored.run.store_snapshot().rune_purchased and restored.run._gold == 455, "%s restart retains purchased rank-one UID, 45-Gold spending and consumed Store allowance." % specimen.id)
		if not restored.ok: continue
		var rune: Dictionary = restored.run._owned_card(specimen.uid)
		check(not Effects.upgrade_preview(restored.run._setup.catalog, rune).ok and restored.run.eligible_upgrade_targets().all(func(card): return card.uid != specimen.uid), "%s restart rejects repeat refinement of the upgraded copy." % specimen.id)
