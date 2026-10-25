extends SceneTree
## Real battles, registered shop rules, detached ownership and hostile-save tests.
const Fixture = preload("res://tests/helpers/shop_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Save = preload("res://scripts/core/local_save.gd")
const LegacyFixture = preload("res://tests/helpers/reward_route_fixture.gd")
const DESTINATION := "res://output/qa/rc-029/model"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func restore(subject, data: Dictionary = {}) -> Dictionary:
	return Run.restore_save(subject.export_save() if data.is_empty() else data, setup, subject.profile_state().clone_for_transaction(), Fixture.context_for(subject))

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	setup = Loader.load_setup().setup
	var production = Run.new(setup, 42, true, Callable(), null, Profile.production_rules(), Profile.new(setup.catalog))
	var production_export: Dictionary = production.export_save()
	check(not production.inspect_node("d7").content_pending and not production.inspect_node("d8").content_pending, "Runtime availability enables registered shop and recovery handlers without regenerating the graph.")
	check(Run.restore_save(production_export, setup, production.profile_state()).ok and production.export_save() == production_export, "Production route restores without regeneration or unrelated content-signature changes.")
	_stock_and_transactions()
	_pools_and_balances()
	_removal_histories()
	_migrations()
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-029 shop models: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func ready(gold: int = 100, unlocked: Array = Profile.INITIAL_IDS, reward_card: bool = false, chain: bool = false):
	var subject = Fixture.new_run(42, gold, unlocked, chain)
	check(subject.snapshot().gold == 0, "Fixture starts at zero Gold before its configured real battle payout.")
	var won: Dictionary = Fixture.win_first(subject, reward_card)
	check(won.ok, "Ordinary battle actions earn configured fixture Gold: " + str(won.get("error", "")))
	check(subject.snapshot().gold == gold and subject.route_snapshot().completed_count == 1, "Only actual victory and reward resolution fund the shop.")
	return subject

func _stock_and_transactions() -> void:
	var subject = ready()
	var before: Dictionary = subject.export_save()
	var token: Dictionary = subject.request_room_entry(subject.route_snapshot().nodes.filter(func(n): return n.state == "available")[0].id).token
	var candidate: Dictionary = subject.prepare_route_shop(token)
	var first_stock: Dictionary = candidate.shop.duplicate(true)
	var prepared_export: Dictionary = subject.export_save()
	prepared_export.candidate_sequence = before.candidate_sequence
	check(candidate.ok and prepared_export == before, "Preparation validates stock without consuming the visit or committed gameplay streams.")
	subject.cancel_prepared_shop(candidate)
	check(not subject.commit_route_shop(candidate).ok and subject.export_save().route == before.route and subject.export_save().shop_rng_state == before.shop_rng_state, "Cancelled entry cannot commit or change visits or committed shop RNG.")
	candidate = subject.prepare_route_shop(token)
	check(candidate.shop == first_stock, "Cancelled preparation cannot reroll the exact stock or shop stream.")
	check(candidate.ok and subject.commit_route_shop(candidate).ok, "Current eligible shop accepts a prepared entry.")
	var stock: Dictionary = subject.shop_snapshot()
	check(stock.slots.size() == 3 and stock.slots.map(func(s): return s.definition_id).size() == 3, "Three eligible rune slots are offered.")
	var ids: Array = stock.slots.map(func(s): return s.definition_id)
	check(ids.all(func(id): return ids.count(id) == 1 and id in Profile.INITIAL_IDS), "Stock is distinct, implemented and excludes temporary Free Spark.")
	check(stock.slots.all(func(s): return s.price == 30 and not s.sold), "Provisional registered rune prices are 30 Gold and initially unsold.")
	check(subject.export_save().rng_states == before.rng_states and subject.export_save().reward_rng_state == before.reward_rng_state and subject.export_save().route.graph.route_rng_state == before.route.graph.route_rng_state, "Shop sampling preserves battle, reward and route RNG streams.")
	check(subject.route_snapshot().status == "room_active" and subject.route_snapshot().completed_count == 1 and subject.inspect_node("d3").state == "locked", "Entered shop remains active and successors stay locked.")
	var original: Dictionary = subject.export_save()
	for attempt in 3:
		subject.inspect_node("d3")
		check(subject.shop_snapshot() == stock and subject.export_save() == original, "Inspection does not reroll stock or complete the active visit.")
	var restarted: Dictionary = restore(subject)
	check(restarted.ok and restarted.run.shop_snapshot() == stock and restarted.run.export_save() == original, "Active shop export/restore retains exact stock and streams: " + str(restarted.get("error", "")))
	check(not Run.restore_save(original, setup, subject.profile_state()).ok, "Production restore rejects the excluded fixture policy even for supported shops.")
	if not restarted.ok: return
	var detached: Dictionary = subject.clone_for_transaction()
	check(detached.ok and detached.run.shop_snapshot() == stock, "Transaction clone includes shop stock and random state.")
	var next_uid: int = subject.snapshot().next_uid
	check(next_uid > 8, "Real Conjure usage creates preserved temporary-consumed allocator gaps.")
	var profile_before: Dictionary = subject.profile_state().export_save()
	var route_before: Dictionary = subject.route_snapshot()
	var purchase: Dictionary = detached.run.buy_shop_rune(stock.identity, stock.slots[0].slot_id)
	check(purchase.ok and subject.export_save() == original, "Detached purchase publishes no spend, card, stock or UID prematurely.")
	subject.publish_transaction(detached.run)
	var bought: Dictionary = subject.shop_snapshot()
	check(subject.snapshot().gold == 70 and subject.snapshot().owned_cards.size() == 9 and subject.snapshot().owned_cards.back().uid == next_uid and subject.snapshot().next_uid == next_uid + 1, "Purchase spends 30 once and allocates exactly the authoritative next UID.")
	check(bought.slots[0].sold and bought.slots[0].granted_uid == next_uid and subject.route_snapshot() == route_before, "Sold slot receipt persists without an arbitrary route revision.")
	check(subject.profile_state().export_save() == profile_before, "Run purchase preserves permanent unlock ownership.")
	var after_purchase: Dictionary = subject.export_save()
	check(not subject.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok and subject.export_save() == after_purchase, "Double purchase of sold slot rejects without another charge or allocation.")
	var stale: Dictionary = stock.identity.duplicate(true)
	stale.visit_id += "-stale"
	check(not subject.buy_shop_rune(stale, stock.slots[1].slot_id).ok and not subject.remove_shop_rune(stale, 0).ok and not subject.leave_shop(stale).ok and subject.export_save() == after_purchase, "Stale purchase, removal and Leave identities change nothing.")
	check(subject.remove_shop_rune(stock.identity, 0).ok, "Removal selects one exact starter UID.")
	check(subject.snapshot().gold == 30 and subject.snapshot().owned_cards.size() == 8 and subject.snapshot().owned_cards.filter(func(c): return c.uid == 0).is_empty() and subject.snapshot().owned_cards.filter(func(c): return c.id == "spark").size() >= 1, "Removal spends 40 and preserves other copies of the same definition.")
	check(subject.snapshot().next_uid == next_uid + 1 and subject.profile_state().export_save() == profile_before, "Removed UIDs are never recycled and profile remains unchanged.")
	var after_removal: Dictionary = subject.export_save()
	check(not subject.remove_shop_rune(stock.identity, 1).ok and subject.export_save() == after_removal, "Once-used removal cannot charge again.")
	check(restore(subject).ok, "Purchased and removed ownership reconciles from immutable history.")
	_corruptions(subject)
	check(subject.leave_shop(stock.identity).ok and subject.inspect_node("d3").state == "available", "Explicit Leave completes once and unlocks the valid successor.")
	var after_leave: Dictionary = subject.export_save()
	check(not subject.leave_shop(stock.identity).ok and not subject.buy_shop_rune(stock.identity, stock.slots[1].slot_id).ok and not subject.request_room_entry(stock.identity.node_id).ok and subject.export_save() == after_leave, "Completed shops reject repeated Leave, purchases and reentry.")
	check(restore(subject).ok, "Completed shop and its transaction receipts restore.")
	var entered: Dictionary = subject.commit_route_battle(subject.prepare_route_battle(subject.request_room_entry("d3").token))
	check(entered.ok, "Subsequent supported battle accepts the changed collection.")
	if entered.ok:
		var owned: Array = entered.combat.run_handoff().owned_cards
		check(owned.filter(func(c): return c.uid == next_uid).size() == 1 and owned.filter(func(c): return c.uid == 0).is_empty(), "Purchased UID appears once and removed UID stays absent in subsequent battle.")

func _pools_and_balances() -> void:
	for unlocked in [[], ["spark"], ["spark", "shield"]]:
		var subject = ready(0, unlocked)
		check(Fixture.enter_shop(subject).ok, "Small/empty eligible pool still permits an unfunded visit.")
		var stock: Dictionary = subject.shop_snapshot()
		check(stock.slots.size() == unlocked.size() and stock.slots.all(func(s): return s.definition_id in unlocked), "Small/exhausted pools offer only accepted eligible definitions, with no filler.")
		var before: Dictionary = subject.export_save()
		if not stock.slots.is_empty(): check(not subject.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok and subject.export_save() == before, "Insufficient zero Gold changes no card, slot, UID or balance.")
		check(not subject.remove_shop_rune(stock.identity, 0).ok and subject.export_save() == before, "Insufficient service Gold changes neither ownership nor allowance.")
		check(subject.leave_shop(stock.identity).ok and restore(subject).ok, "No-purchase Leave settles an empty or unaffordable shop.")
	var exact = ready(30)
	check(Fixture.enter_shop(exact).ok, "Exact-price fixture reaches shop legitimately.")
	var stock: Dictionary = exact.shop_snapshot()
	check(exact.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok and exact.snapshot().gold == 0 and restore(exact).ok, "Exact Gold purchase settles to zero and validates.")
	var exact_removal = ready(40)
	check(Fixture.enter_shop(exact_removal).ok, "Exact service-price fixture reaches its legitimate shop.")
	check(exact_removal.remove_shop_rune(exact_removal.shop_snapshot().identity, 0).ok and exact_removal.snapshot().gold == 0 and restore(exact_removal).ok, "Exact 40-Gold removal settles to zero with a valid ownership receipt.")
	var limited = ready(100)
	Fixture.enter_shop(limited)
	stock = limited.shop_snapshot()
	# Isolated capacity guard probe; no corrupt candidate is persisted or used
	# as fixture evidence. A real nine-depth tower cannot organically reach 100.
	while limited._owned_cards.size() < Loader.MAX_CARDS:
		limited._owned_cards.append({"id": "spark", "uid": limited._next_uid})
		limited._next_uid += 1
	var before: Dictionary = limited.snapshot()
	check(not limited.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok and limited.snapshot() == before, "Bounded capacity guard rejects purchase without mutation at 100 cards.")

func _removal_histories() -> void:
	for source in ["reward", "purchase"]:
		var subject = ready(100, Profile.INITIAL_IDS, source == "reward")
		var reward_history: Array = subject.export_save().reward_records.duplicate(true)
		check(Fixture.enter_shop(subject).ok, source + " removal fixture enters a real shop.")
		var stock: Dictionary = subject.shop_snapshot()
		var uid: int = subject.snapshot().owned_cards.back().uid
		if source == "purchase":
			uid = subject.snapshot().next_uid
			check(subject.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok, "Purchase creates the exact later-removable UID.")
		check(subject.remove_shop_rune(stock.identity, uid).ok and subject.snapshot().owned_cards.filter(func(c): return c.uid == uid).is_empty(), "Exact " + source + " instance can be removed.")
		check(subject.export_save().reward_records == reward_history and restore(subject).ok, "Immutable acquisition history survives " + source + " removal and restores.")
	var floor_run = ready(240, Profile.INITIAL_IDS, false, true)
	for index in 4:
		check(Fixture.enter_shop(floor_run).ok, "Removal chain legally enters shop %d." % index)
		var stock: Dictionary = floor_run.shop_snapshot()
		check(floor_run.remove_shop_rune(stock.identity, floor_run.snapshot().owned_cards.back().uid).ok, "One allowed removal commits in distinct shop %d." % index)
		check(restore(floor_run).ok, "Chronological removal chain ownership restores after shop %d." % index)
		if index < 3: check(floor_run.leave_shop(stock.identity).ok, "Explicit Leave unlocks next chain shop.")
	check(floor_run.snapshot().owned_cards.size() == 4 and not floor_run.shop_snapshot().can_remove, "Removal floor retains four owned cards.")
	var before: Dictionary = floor_run.export_save()
	check(not floor_run.remove_shop_rune(floor_run.shop_snapshot().identity, floor_run.snapshot().owned_cards[0].uid).ok and floor_run.export_save() == before, "Further removal at four cards leaves ownership and Gold unchanged.")
	check(floor_run.leave_shop(floor_run.shop_snapshot().identity).ok, "Fourth removal shop completes through explicit Leave.")
	var prepared: Dictionary = floor_run.prepare_route_battle(floor_run.request_room_entry("d6").token)
	check(prepared.ok, "Four-card collection can enter the genuine designated Shadeling boss.")
	if prepared.ok:
		var battle = floor_run.commit_route_battle(prepared).combat
		var won: bool = Fixture.Integration.new()._win(battle)
		check(won and floor_run.resolve_battle(battle), "Ordinary four-card battle play defeats the designated boss before another shop.")
		if won:
			var reward: Dictionary = floor_run.pending_reward()
			check(floor_run.skip_reward(reward.identity).ok and floor_run.acknowledge_result(floor_run.snapshot().pending_result.identity), "Boss reward skips without adding cards or unconfigured Gold.")
			check(Fixture.enter_shop(floor_run, "d7").ok, "A fifth shop visit is reached through genuine completed rooms.")
			var at_floor: Dictionary = floor_run.export_save()
			check(not floor_run.shop_snapshot().removal.used and not floor_run.remove_shop_rune(floor_run.shop_snapshot().identity, 0).ok and floor_run.export_save() == at_floor, "Unused removal at exactly four cards rejects independently of the once-only service guard.")
			check(restore(floor_run).ok, "Long real visit history and four-card floor restore successfully.")

func _corruptions(subject) -> void:
	var valid: Dictionary = subject.export_save()
	for mutate in [
		func(d): d.gold -= 1,
		func(d): d.next_uid += 1,
		func(d): d.owned_cards.pop_back(),
		func(d): d.owned_cards.append({"id": "spark", "uid": d.next_uid - 1}),
		func(d): d.shop_records[0].slots[1].price = 29,
		func(d): d.shop_records[0].slots[1].definition_id = "free_spark",
		func(d): d.shop_records[0].slots[1].slot_id = d.shop_records[0].slots[0].slot_id,
		func(d): d.shop_records[0].slots[0].sold = false,
		func(d): d.shop_records[0].removal.used = false,
		func(d): d.shop_records[0].transactions[0].gold_spent -= 1,
		func(d): d.shop_records[0].transactions.append(d.shop_records[0].transactions[0].duplicate(true)),
		func(d): d.shop_records[0].eligible_ids.pop_back(),
		func(d): d.shop_records[0].rng_after += 1,
		func(d): d.shop_records.append(d.shop_records[0].duplicate(true))]:
		var bad := valid.duplicate(true)
		mutate.call(bad)
		check(not restore(subject, bad).ok, "Corrupt stock, prices, spending, identity or ownership rejects before publication.")
	var paths: Array = []
	_collect_paths(valid.shop_records, ["shop_records"], paths)
	for path in paths:
		var bad := valid.duplicate(true)
		var value: Variant = bad
		for index in range(path.size() - 1): value = value[path[index]]
		var original: Variant = value[path.back()]
		value[path.back()] = null if original is Dictionary or original is Array else []
		check(not restore(subject, bad).ok, "Malformed nested shop field rejects: " + str(path))

func _collect_paths(value: Variant, prefix: Array, paths: Array) -> void:
	if value is Dictionary or value is Array:
		for key in (value.keys() if value is Dictionary else range(value.size())):
			var path := prefix.duplicate()
			path.append(key)
			paths.append(path)
			_collect_paths(value[key], path, paths)

func _migrations() -> void:
	for name in ["production", "reward"]:
		var source: String = "res://tests/fixtures/rc028/" + name + "-v1.json"
		var context: Dictionary = {} if name == "production" else Fixture.context_for(LegacyFixture.new_run())
		var validator := func(payload):
			var p: Dictionary = Profile.restore_save(payload.get("profile", {}), setup.catalog, name != "production")
			return p if not p.ok else Run.restore_save(payload.get("run", {}), setup, p.profile, context)
		var destination := DESTINATION.path_join(name + "-migration-" + str(Time.get_ticks_usec()) + ".json")
		check(DirAccess.copy_absolute(source, destination) == OK, "Original real RC-028 " + name + " bytes copied into isolated migration slot.")
		var original_bytes := FileAccess.get_file_as_bytes(destination)
		var store = Save.new(destination, validator)
		var loaded: Dictionary = store.load()
		check(loaded.ok and loaded.payload.run.version == 1, "Real v1 " + name + " predecessor validates unchanged: " + str(loaded.get("error", "")))
		if not loaded.ok: continue
		for corrupt in ["starter", "gold", "receipt"]:
			if corrupt == "receipt" and loaded.payload.run.reward_records.is_empty(): continue
			var malformed: Dictionary = loaded.payload.duplicate(true)
			if corrupt == "starter": malformed.run.owned_cards.remove_at(0)
			elif corrupt == "gold": malformed.run.gold += 1
			else: malformed.run.reward_records.append(malformed.run.reward_records[0].duplicate(true))
			check(not validator.call(malformed).ok, "Real v1 " + corrupt + " corruption rejects before migration.")
		var restored: Dictionary = validator.call(loaded.payload)
		check(restored.ok, "Legacy model migrates detached: " + str(restored.get("error", "")))
		if not restored.ok: continue
		var migrated: Dictionary = restored.run.export_save()
		for key in loaded.payload.run:
			if key == "version": continue
			var legacy_shape = preload("res://tests/helpers/legacy_card_shape.gd")
			var expected: Variant = preload("res://tests/helpers/legacy_route_shape.gd").expected_hydration(loaded.payload.run[key]) if key == "route" else loaded.payload.run[key]
			check(legacy_shape.strip_new_defaults(migrated[key]) == legacy_shape.strip_new_defaults(expected), "Migration preserves legacy " + key + " with explicit unupgraded defaults and only registered planned-route ID/availability hydration.")
		var payload := {"profile": loaded.payload.profile, "run": migrated}
		store.failure_point = "replace"
		var failed: Dictionary = store.commit(payload, loaded.revision)
		check(not failed.ok and FileAccess.get_file_as_bytes(destination) == original_bytes, "Failed migration preserves original v1 bytes for Retry.")
		store.failure_point = ""
		check(store.commit(payload, loaded.revision).ok, "Successful migration validates old current while creating its backup.")
		check(FileAccess.get_file_as_bytes(destination + ".previous") == original_bytes, "Migration backup preserves exact original v1 bytes.")
		FileAccess.open(destination, FileAccess.WRITE).store_string("truncated")
		var recovery = Save.new(destination, validator)
		var damaged: Dictionary = recovery.load()
		check(not damaged.ok and damaged.recovery_available, "Damaged v2 current exposes validated v1 previous-copy recovery.")
		var recovered: Dictionary = recovery.recover_previous()
		check(recovered.ok and FileAccess.get_file_as_bytes(destination) == original_bytes, "Explicit recovery promotes the exact valid v1 predecessor.")
