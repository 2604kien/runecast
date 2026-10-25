extends SceneTree
const Fixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const ServiceFixture = preload("res://tests/helpers/service_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Relics = preload("res://scripts/core/relic_policy.gd")
const Policy = preload("res://scripts/core/service_policy.gd")
const Effects = preload("res://scripts/core/instance_effects.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const DESTINATION := "res://output/qa/rc-031/state"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary

func check(ok: bool, label: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": label})
	if not ok:
		failures += 1
		push_error(label)

func restored(subject, data: Dictionary = {}) -> Dictionary:
	return Run.restore_save(subject.export_save() if data.is_empty() else data, setup, subject.profile_state().clone_for_transaction(), subject.restore_context_for_tests())

func check_restored(subject, label: String) -> void:
	var result := restored(subject)
	check(result.ok and result.run.export_save() == subject.export_save(), label + ": " + str(result.get("error", "")))

func _initialize() -> void:
	setup = Loader.load_setup().setup
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	_upgrades()
	for order in [["relic_heart_stone", "relic_menders_token"], ["relic_menders_token", "relic_heart_stone"]]: _history(order)
	_pools()
	_reliquary()
	_exhaustion()
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-031 upgrade/relic state: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _upgrades() -> void:
	var subject = ShopFixture.new_run(42, 300)
	check(ShopFixture.win_first(subject).ok and ShopFixture.enter_shop(subject).ok, "Real Wisp victory funds the upgrade/removal shop fixture.")
	var shop: Dictionary = subject.shop_snapshot()
	var profile: Dictionary = subject.profile_state().export_save()
	var before: Dictionary = subject.export_save()
	var cloned: Dictionary = subject.clone_for_transaction()
	var upgraded: Dictionary = cloned.run.upgrade_shop_rune(shop.identity, 0)
	check(upgraded.ok and cloned.run._owned_card(0).upgrade_rank == 1 and cloned.run._owned_card(3).upgrade_rank == 0, "Only the chosen Spark UID upgrades; its identical sibling remains rank zero.")
	check(subject.export_save() == before and subject.profile_state().export_save() == profile, "Detached upgrade leaves authoritative run and definition profile untouched.")
	check(not cloned.run.upgrade_shop_rune(shop.identity, 3).ok and not cloned.run.upgrade_shop_rune(shop.identity, 0).ok, "Single visit and single-rank limits reject a second upgrade.")
	subject.publish_transaction(cloned.run)
	check_restored(subject, "Paid exact-copy upgrade restores with historical rank receipt")
	check(subject.remove_shop_rune(shop.identity, 0).ok and subject._owned_card(0).is_empty() and subject._owned_card(3).upgrade_rank == 0, "Removal removes the upgraded physical copy only.")
	check_restored(subject, "Removed upgraded copy keeps valid purchase/upgrade/removal history")
	for bad_rank in [-1, 2, 1.0, "1", null, []]:
		var corrupt: Dictionary = subject.export_save()
		corrupt.owned_cards[0].upgrade_rank = bad_rank
		check(not restored(subject, corrupt).ok, "Reject malformed instance rank " + str(bad_rank))
	var corrupt: Dictionary = subject.export_save()
	corrupt.shop_records[0].transactions[0].new_rank = 2
	check(not restored(subject, corrupt).ok, "Reject changed historical upgrade rank.")
	check(subject.leave_shop(shop.identity).ok, "Explicit Leave remains required after upgrading and removal.")
	check_restored(subject, "Completed upgrade/removal shop restores")
	var fresh = Run.new(setup, 42, true, Callable(), null, subject._reward_rules, subject.profile_state().clone_for_transaction())
	check(fresh.snapshot().owned_cards.all(func(card): return card.upgrade_rank == 0) and fresh.snapshot().relics.is_empty() and fresh.snapshot().player_max_hp == 30 and fresh.profile_state().export_save() == profile, "New Run resets every upgrade and relic while preserving definition unlocks.")
	for variant in ["recovery", "desk"]:
		var service = ServiceFixture.new_run(42, variant)
		check(ServiceFixture.win_battle(service).ok and ServiceFixture.enter_service(service).ok, "Real battle opens the " + variant + " upgrade service.")
		var identity: Dictionary = service.service_snapshot().identity
		var original: Dictionary = service.export_save()
		check(not service.resolve_service(identity, "refine_rune").ok and not service.resolve_service(identity, "refine_rune", 999).ok and service.export_save() == original, "Missing/stale exact target cannot consume an upgrade service.")
		check(service.resolve_service(identity, "refine_rune", 0).ok and service._owned_card(0).upgrade_rank == 1, variant + " grants the free exact-instance upgrade.")
		check(not service.resolve_service(identity, "recover").ok and not service.resolve_service(identity, "refine_rune", 3).ok, variant + " completes once and excludes a second benefit.")
		check_restored(service, variant + " upgrade restores through its authoritative receipt")
		var candidate: Dictionary = service.prepare_route_battle(service.request_room_entry(ServiceFixture.next_node(service)).token)
		check(candidate.ok and service.commit_route_battle(candidate).ok, "Upgraded ownership enters the next supported encounter.")
		var opening: Dictionary = service.current_battle().snapshot()
		check(service.current_battle().run_handoff().owned_cards == service._owned_cards, "Battle handoff preserves rank and exact UID.")
		var replay := restored(service)
		check(replay.ok and replay.run.continue_battle().ok and replay.run.current_battle().snapshot() == opening, "Ranked next-encounter entry replays exactly.")

func _seed_for(order: Array) -> int:
	for seed in range(1000):
		var probe = Fixture.new_run(seed)
		var first: Dictionary = probe._relic_offering({"node_id": "d3", "visit_id": "ignored/visit-03/d3"}, "shop", [], 1)
		var second: Dictionary = probe._relic_offering({"node_id": "d5a", "visit_id": "ignored/visit-05/d5a"}, "shop", [order[0]], 1)
		if first.offered_ids == [order[0]] and second.offered_ids == [order[1]]: return seed
	return -1

func _history(order: Array) -> void:
	var seed := _seed_for(order)
	check(seed >= 0, "Retained seed %d covers acquisition order %s" % [seed, str(order)])
	if seed < 0: return
	var subject = Fixture.new_run(seed)
	check(ShopFixture.win_first(subject).ok, "Real Wisp actions earn the explicitly registered chronology fixture payout.")
	if subject.snapshot().status != "route_ready": return
	check(Fixture.enter_service(subject).ok, "Pre-acquisition recovery enters.")
	var earlier: Dictionary = subject.service_snapshot()
	var old_amount: int = earlier.choices[0].hp_delta
	var choice := "recover" if earlier.choices[0].eligible else "leave"
	check(old_amount == mini(10, 30 - subject._player_hp) and subject.resolve_service(earlier.identity, choice).ok, "Earlier recovery uses the original ten-HP policy.")
	check(Fixture.enter_shop(subject).ok, "First chronological relic shop enters.")
	var shop: Dictionary = subject.shop_snapshot()
	check(shop.relic_slots[0].definition_id == order[0], "First item offering follows its deterministic retained seed.")
	var profile: Dictionary = subject.profile_state().export_save()
	_retry_acquisition(subject, shop.identity)
	check(subject.snapshot().relics == [order[0]], "First acquisition publishes exactly one unique run relic.")
	check(not subject.buy_shop_relic(shop.identity).ok, "A sold/owned relic cannot be bought twice.")
	check(subject.leave_shop(shop.identity).ok, "First relic shop requires explicit Leave.")
	check(Fixture.enter_service(subject).ok, "Intervening Blood Tithe enters.")
	var tithe: Dictionary = subject.service_snapshot()
	check(tithe.choices[0].hp_delta == -8 and subject.resolve_service(tithe.identity, "blood_tithe").ok, "Mender never changes Blood Tithe damage.")
	check(Fixture.enter_shop(subject).ok, "Second chronological relic shop enters.")
	shop = subject.shop_snapshot()
	check(shop.relic_slots[0].definition_id == order[1], "Later item offering excludes already owned relics.")
	check(subject.buy_shop_relic(shop.identity).ok and subject._player_max_hp == 34, "Both acquisition orders apply Heart Stone maximum HP exactly once.")
	check_restored(subject, "Both relic orders preserve shop acquisition HP chronology")
	var bad: Dictionary = subject.export_save()
	bad.relics.append(order[0])
	check(not restored(subject, bad).ok, "Duplicate persisted relics reject.")
	bad = subject.export_save()
	bad.shop_records[1].transactions[0].entry_hp += 1
	check(not restored(subject, bad).ok, "Unexplained shop acquisition HP rejects.")
	check(subject.leave_shop(shop.identity).ok and Fixture.enter_service(subject).ok, "Recovery after both acquisitions enters.")
	var recovery: Dictionary = subject.service_snapshot()
	check(recovery.choices[0].hp_delta == mini(14, 34 - subject._player_hp), "Later recovery uses Mender plus current Heart Stone maximum.")
	check(subject.resolve_service(recovery.identity, "recover").ok and subject._player_hp == 34, "Capped recovery publishes its exact health receipt.")
	check(subject.export_save().service_records[0].receipt.hp_delta == old_amount, "Later Mender ownership never retroactively changes an earlier recovery receipt.")
	check_restored(subject, "Chronological Heart/Mender and recovery history restores")
	bad = subject.export_save()
	bad.service_records[0].receipt.hp_delta += 4
	check(not restored(subject, bad).ok, "Retroactively applying Mender to an earlier receipt rejects.")
	check(subject.profile_state().export_save() == profile, "Run relic history does not alter definition unlock profile.")
	var battle: Dictionary = subject.prepare_route_battle(subject.request_room_entry(Fixture.next_node(subject)).token)
	check(battle.ok and subject.commit_route_battle(battle).ok and subject._entry_checkpoint.player_max_hp == 34, "Later real battle accepts exact carried health and run relic ownership.")
	var opening: Dictionary = subject.current_battle().snapshot()
	var replay := restored(subject)
	check(replay.ok and replay.run.continue_battle().ok and replay.run.current_battle().snapshot() == opening, "Battle-entry replay reproduces relic ownership and never reacquires Heart Stone.")

func _retry_acquisition(subject, identity: Dictionary) -> void:
	var before: Dictionary = subject.export_save()
	var candidate: Dictionary = subject.clone_for_transaction()
	check(candidate.run.buy_shop_relic(identity).ok, "Detached relic acquisition validates exact stock and health.")
	var exact: Dictionary = candidate.run.export_save()
	var path := DESTINATION.path_join("retry-%d.json" % Time.get_ticks_usec())
	var store = Save.new(path, func(payload): return restored(subject, payload.run))
	check(store.load().status == "empty" and store.commit({"run": before}, 0).ok, "Isolated acquisition store persists the pre-acquisition boundary.")
	for point in ["write", "flush", "close", "backup", "replace"]:
		store.failure_point = point
		check(not store.commit({"run": exact}, 1).ok and subject.export_save() == before and candidate.run.export_save() == exact, point + " failure preserves every owner and the identical Retry candidate.")
	store.failure_point = ""
	check(store.commit({"run": exact}, 1).ok, "Retry durably commits the exact retained acquisition once.")
	subject.publish_transaction(candidate.run)
	var loaded: Dictionary = Save.new(path, func(payload): return restored(subject, payload.run)).load()
	check(loaded.ok and loaded.payload.run == exact and restored(subject, loaded.payload.run).ok, "Restart restores acquired health without repeating acquisition effects.")

func _pools() -> void:
	var a = Fixture.new_run(42)
	var b = Fixture.new_run(42)
	var identity_a := {"node_id": "d3", "visit_id": a._run_id + "/visit-03/d3"}
	var identity_b := {"node_id": "d3", "visit_id": b._run_id + "/visit-03/d3"}
	check(a._run_id != b._run_id and a._relic_offering(identity_a, "shop", [], 1) == b._relic_offering(identity_b, "shop", [], 1), "Same seed and visit yields identical items despite distinct cryptographic run IDs.")
	var all: Array = Relics.ORDER.duplicate()
	for count in [0, 1, 2, 5, 6]:
		var owned := all.slice(0, count)
		var offer: Dictionary = a._relic_offering(identity_a, "service", owned, 2)
		check(offer.offered_ids.size() == mini(2, 6 - count) and offer.offered_ids.all(func(id): return not id in owned) and (offer.offered_ids.size() < 2 or offer.offered_ids[0] != offer.offered_ids[1]), "Relic pool size %d yields distinct eligible unowned offerings without compensation." % (6 - count))
	check(not Effects.eligible(setup.catalog, {"id": "free_spark", "uid": 99, "upgrade_rank": 0}) and not Effects.eligible(setup.catalog, {"id": "ember", "uid": 100, "upgrade_rank": 0}), "Temporary and missing production bases cannot appear as upgrade targets.")
	check(Policy.choices(Policy.definition("room_recovery"), 10, 34, 0, Relics.recovery_amount(["relic_menders_token"], 0))[0].hp_delta == 14, "Uncapped Mender recovery is fourteen HP.")

func _reliquary() -> void:
	var subject = ServiceFixture.new_run(42, "reliquary")
	check(ServiceFixture.win_battle(subject).ok and ServiceFixture.enter_service(subject).ok, "Unfunded real reliquary opens retained offerings.")
	var room: Dictionary = subject.service_snapshot()
	var before: Dictionary = subject.export_save()
	check(room.offered_relics.size() == 2 and not subject.resolve_service(room.identity, "open_reliquary", room.offered_relics[0]).ok and subject.export_save() == before, "Insufficient Gold cannot acquire, charge or complete the reliquary.")
	check(subject.resolve_service(room.identity, "leave").ok and subject._gold == 0 and subject._relics.is_empty(), "Unfunded reliquary retains free Leave.")
	# Separate authored event-first fixture earns its Gold from actual Satchel.
	subject = ServiceFixture.new_run(42, "reliquary")
	for node in subject._route._graph.nodes:
		if node.depth == 1: subject._route._service(node, "event", "event_lost_satchel")
	check(ServiceFixture.enter_service(subject, "d1a").ok, "Explicit Satchel-first fixture enters through authoritative service preparation.")
	check(subject.resolve_service(subject.service_snapshot().identity, "take_gold").ok and subject._gold == 20, "Actual Satchel receipt funds the retained reliquary price.")
	check(ServiceFixture.enter_service(subject).ok, "Funded reliquary enters once.")
	room = subject.service_snapshot()
	before = subject.export_save()
	check_restored(subject, "Active reliquary restores exact retained choices")
	check(not subject.resolve_service(room.identity, "open_reliquary", "missing").ok and subject.export_save() == before, "Unlisted relic selection changes nothing.")
	var selected: String = room.offered_relics[0]
	check(subject.resolve_service(room.identity, "open_reliquary", selected).ok and subject._gold == 5 and subject._relics == [selected], "Fifteen Gold, acquisition hook and room completion commit atomically.")
	check(not subject.resolve_service(room.identity, "open_reliquary", room.offered_relics[1]).ok, "Resolved reliquary cannot grant its other offering.")
	check_restored(subject, "Relic service receipt and health history restore")

func _exhaustion() -> void:
	var subject = Fixture.new_run(42, "relic_exhaustion")
	check(ShopFixture.win_first(subject).ok, "Actual Wisp payout funds the separately named relic-pool exhaustion fixture.")
	for visit in range(5):
		check(Fixture.enter_shop(subject).ok, "Finite-pool shop %d opens." % (visit + 1))
		var shop: Dictionary = subject.shop_snapshot()
		check(subject.buy_shop_relic(shop.identity).ok and subject.leave_shop(shop.identity).ok, "Finite-pool shop grants one previously unowned definition.")
	check(Fixture.enter_service(subject).ok, "One-relic pool enters the retained reliquary.")
	var room: Dictionary = subject.service_snapshot()
	check(room.offered_relics.size() == 1, "Authoritative reliquary shows one choice when exactly one eligible relic remains.")
	check(subject.resolve_service(room.identity, "open_reliquary", room.offered_relics[0]).ok and subject._relics.size() == 6, "Last relic acquisition exhausts the unique run pool.")
	check_restored(subject, "All six chronological acquisitions restore")
	check(Fixture.enter_shop(subject).ok and subject.shop_snapshot().relic_slots.is_empty(), "Exhausted pool creates no replacement relic stock.")
	var shop: Dictionary = subject.shop_snapshot()
	var before: Dictionary = subject.export_save()
	check(not subject.buy_shop_relic(shop.identity).ok and subject.export_save() == before, "Empty shop relic slot cannot charge or grant compensation.")
	check(subject.leave_shop(shop.identity).ok and Fixture.enter_service(subject).ok, "Exhausted-pool reliquary remains accessible.")
	room = subject.service_snapshot()
	before = subject.export_save()
	check(room.offered_relics.is_empty() and not room.choices[0].eligible and not subject.resolve_service(room.identity, "open_reliquary", Relics.ORDER[0]).ok and subject.export_save() == before, "Empty reliquary rejects payment and duplicate acquisition.")
	check(subject.resolve_service(room.identity, "leave").ok and subject._gold == before.gold and subject._relics == before.relics, "Empty reliquary Leave completes without charge or compensation.")
	check_restored(subject, "Exhausted unique relic history and Leave restore")
	subject = Fixture.new_run(42, "upgrade_exhaustion")
	for index in range(8):
		check(Fixture.enter_service(subject).ok, "Authored full-health recovery %d opens." % (index + 1))
		room = subject.service_snapshot()
		check(subject.resolve_service(room.identity, "refine_rune", index).ok, "Recovery upgrades one exact UID once without a combat fabrication.")
	check(Fixture.enter_service(subject).ok, "Final authored recovery opens with every owned rune upgraded.")
	room = subject.service_snapshot()
	before = subject.export_save()
	check(subject.eligible_upgrade_targets().is_empty() and not room.choices[1].eligible and not subject.resolve_service(room.identity, "refine_rune", 0).ok and subject.export_save() == before, "No-eligible-target recovery rejects repeat ranks and explains exhaustion.")
	check(subject.resolve_service(room.identity, "leave").ok, "Full-health no-upgrade recovery retains explicit Leave.")
	check_restored(subject, "Eight independent instance upgrades retain valid service receipts")
