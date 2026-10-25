extends SceneTree
## Actual retained envelopes, trusted catalogue generations and prospective
## production milestones. Fixture resources never enter production rewards.
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Catalogues = preload("res://scripts/core/catalogue_policy.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Journey = preload("res://tests/helpers/rc034_journey.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const FullFixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const ItemFixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const RewardFixture = preload("res://tests/helpers/reward_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
var setup: Dictionary
var context: Dictionary = {}
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []
var directory := "res://output/qa/rc-035/compatibility"
var stage := "prepare"

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): directory = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
	setup = Loader.load_setup().setup
	call_deferred("_run")

func validate(value: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(value.get("profile", {}), setup.catalog, not context.is_empty())
	return profile if not profile.ok else Run.restore_save(value.get("run", {}), setup, profile.profile, context)

func payload(run) -> Dictionary:
	return {"profile": run.profile_state().export_save(), "run": run.export_save()}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	if stage == "restart": _restart()
	else:
		_retained()
		_adversarial()
		_production()
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "engine": Engine.get_version_info().string, "stage": stage, "process_id": OS.get_process_id()}, "\t"))
	FileAccess.open(directory.path_join(stage + "-traces.json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "\t"))
	print("RC-035 compatibility %s: %d checks, %d failures" % [stage, checks, failures])
	await process_frame
	quit(0 if failures == 0 else 1)

func _historical_full_route(id: String, seed: int):
	var route = FullFixture.FixtureRoute.new(id, seed)
	route._graph.display_name = "RC-032 development tower · calibration content"
	return route

func _retained() -> void:
	var origins: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rc035/origins.json"))
	var replay_path := "res://" + str(origins.replay_evidence.fixture)
	check(FileAccess.get_sha256(replay_path) == origins.replay_evidence.sha256, "Original production opening/command/terminal witnesses retain genuine source bytes.")
	var replay: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(replay_path))
	for specimen in origins.specimens:
		var name := str(specimen.fixture).get_file().trim_suffix(".json")
		context = {}
		if name.begins_with("store-"): context = FullFixture.context_for(FullFixture.new_run())
		elif name == "pending-permanent-v6":
			var fixture = Run.new(setup, 42, true, _historical_full_route, FullFixture.FixtureResolver.new(), FullFixture.reward_rules(), Profile.new(setup.catalog, ["spark", "shield"]))
			context = FullFixture.context_for(fixture)
		elif name in ["abandoned-ranked-v5", "abandoned-service-v5", "abandoned-ranked-v6", "abandoned-service-v6"]: context = ItemFixture.context_for(ItemFixture.new_run(15))
		elif name == "abandoned-entry-v5": context = ShopFixture.context_for(RewardFixture.new_run(42))
		var path := "res://" + str(specimen.fixture)
		check(FileAccess.get_sha256(path) == specimen.sha256, name + " retains exact genuine pre-change bytes.")
		var loaded := Save.new(path, validate).load()
		check(loaded.ok, name + " validates original envelope and historical contract: " + str(loaded.get("error", "")))
		if not loaded.ok: continue
		var restored := validate(loaded.payload)
		if not restored.ok: continue
		var run = restored.run
		check(Catalogues.is_legacy(run._setup.catalog), name + " selects complete trusted original catalogue, never arbitrary subsets.")
		check(run.profile_state().export_save() == loaded.payload.profile, name + " grants no new automatic unlocks.")
		if loaded.payload.run.version == 6:
			check(run.export_save() == loaded.payload.run, name + " retains exact offers, receipts, prices, policies, RNG, ownership and signatures.")
		if run.export_save().status == "replay_pending":
			var opening: Dictionary = run.continue_battle()
			check(opening.ok and opening.combat.snapshot().catalog == Catalogues.legacy_catalog(), name + " replays with original executable definitions.")
			if name.begins_with("production-") and opening.ok:
				var witnesses: Array = replay.records.filter(func(record): return record.label == str(specimen.source).get_file().trim_suffix(".json"))
				check(witnesses.size() == 1 and opening.combat.snapshot() == witnesses[0].opening, name + " reconstructs exact original opening with untouched RNG, UID, hand, endpoints and kits.")
				if witnesses.size() == 1:
					var controller := Controller.new(opening.combat)
					var accepted := true
					for command in witnesses[0].commands:
						if not controller.command(command.command, command.arguments):
							accepted = false
							break
					check(accepted and opening.combat.snapshot() == witnesses[0].terminal_snapshot, name + " exact original commands reproduce terminal health, phase and RNG under historical definitions.")
					controller.dispose()
		if name == "production-exhausted-v6":
			var records: Array = run.export_save().reward_records
			check(records.any(func(record): return record.kind == "definition_unlock" and record.resolution == "exhausted" and record.offered_ids.is_empty()), "Exhausted Shadeling milestone is not retroactively awarded.")
			var entered := Journey.enter(run, "d7")
			check(entered.ok and run.shop_snapshot().eligible_ids.size() == 4 and run.export_save().shop_records.back().eligibility_version == 1, "Old run's first future shop retains original four-definition eligibility.")
		if name == "production-map-v6":
			var modern_profile: Dictionary = loaded.payload.duplicate(true)
			modern_profile.profile.unlocked_definition_ids.append("ember")
			modern_profile.profile.unlocked_definition_ids.sort()
			var compatible := validate(modern_profile)
			check(compatible.ok and compatible.run.store_snapshot().runes.size() == 4, "Profile with later unlock opens old run while its Store retains original universe.")
			var prepared := Journey.enter(run, Journey.next_node(run, "normal"))
			check(prepared.ok and prepared.combat.snapshot().catalog == Catalogues.legacy_catalog(), "Old run enters new real room with original catalogue and exact production enemy.")
	context = {}

func _adversarial() -> void:
	var run = Journey.new_run(1)
	var original := payload(run)
	check(validate(original).ok, "New production catalogue and versioned eligibility restore together.")
	check(run.store_snapshot().runes.size() == 4 and run.snapshot().owned_cards.size() == 8, "New profile exposes only four initial definitions and unchanged eight-card starter.")
	for id in ["free_spark", "unsupported", "", "straight"]:
		var copy := original.duplicate(true)
		copy.profile.unlocked_definition_ids.append(id)
		check(not validate(copy).ok and not run.profile_state().unlock(id), "Unknown/generated profile ID rejects: " + id)
	for fault in ["signature", "store_version", "store_policy", "reward_policy", "unknown_card", "rank"]:
		var copy := original.duplicate(true)
		match fault:
			"signature": copy.run.content.signature = "a".repeat(64)
			"store_version": copy.run.store.version = 1
			"store_policy": copy.run.store.policy_id = "rc032_store_v1"
			"reward_policy": copy.run.policy_id = Profile.POLICY_ID
			"unknown_card": copy.run.owned_cards[0].id = "free_spark"
			"rank": copy.run.owned_cards[0].upgrade_rank = 2
		check(not validate(copy).ok, "Malformed current " + fault + " rejects without policy/hash rewriting.")
	var subset := setup.duplicate(true)
	subset.catalog.erase("ember")
	var copy := original.duplicate(true)
	copy.run.content.signature = Run.content_signature(subset)
	check(not validate(copy).ok, "Arbitrary catalogue subset is not a compatibility candidate.")
	var forged_legacy := Catalogues.legacy_setup(setup)
	forged_legacy.catalog.spark.value = 7
	copy.run.content.signature = Run.content_signature(forged_legacy)
	check(not validate(copy).ok, "Changed old definition semantics cannot impersonate historical catalogue.")
	var identity: Dictionary = run.store_snapshot().identity
	check(not run.purchase_store_rune(identity, "ember").ok and not run.purchase_store_rune(identity, "spark").ok and payload(run) == original, "Locked purchase and insufficient ordinary funds reject without state changes.")

func _battle(run, entered: Dictionary, label: String) -> bool:
	var controller := Controller.new(entered.combat)
	var player := Player.new()
	var commands: Array = []
	controller.command_resolved.connect(func(result): commands.append({"command": result.command, "arguments": result.arguments, "accepted": result.accepted}))
	for turn in 80:
		if entered.combat.state != "playing": break
		if not player.play_turn(controller): break
	controller.dispose()
	traces.append({"label": label, "commands": commands, "final": entered.combat.snapshot()})
	check(entered.combat.state == "victory" and run.resolve_battle(entered.combat), label + " wins through real Combat commands and commits actual terminal handoff.")
	return entered.combat.state == "victory"

func _production() -> void:
	var run = Journey.new_run(1)
	var unlocked := ""
	for depth in range(1, 7):
		var entered := Journey.enter(run, Journey.next_node(run, "normal"))
		check(entered.ok, "Production seed1 enters depth%d through ordinary API." % depth)
		if not entered.ok: return
		if entered.has("combat"):
			if not _battle(run, entered, "seed1-depth%d" % depth): return
			if depth == 6:
				var reward: Dictionary = run.snapshot().reward_records.filter(func(record): return record.kind == "definition_unlock").back()
				check(reward.eligible_ids.size() == 8 and reward.offered_ids.size() == 1, "Real Shadeling milestone offers one of eight locked implemented definitions.")
				unlocked = str(reward.offered_ids[0])
				var before: Array = run.snapshot().owned_cards
				check(run.choose_reward(reward.identity, unlocked).ok and run.snapshot().owned_cards == before, "Definition unlock adds no run-owned copy.")
			check(Journey.finish_rewards(run).ok, "Production depth%d resolves retained run choice and result." % depth)
		else: check(Journey.finish_room(run).ok, "Production room resolves ordinary service.")
	check(not unlocked.is_empty() and unlocked in run.profile_state().snapshot().unlocked_definition_ids, "Permanent unlock persists in profile owner.")
	var view: Dictionary = run.store_snapshot()
	check(view.runes.any(func(item): return item.definition_id == unlocked) and view.runes.size() == 5, "New unlock prospectively enables fixed Store entry while seven locked definitions remain excluded.")
	var entered := Journey.enter(run, "d7")
	check(entered.ok and unlocked in run.shop_snapshot().eligible_ids and run.shop_snapshot().eligible_ids.size() == 5, "Later ordinary route shop samples five unlocked definitions under eligibility v2.")
	var retained: Dictionary = run.export_save()
	var location := directory.path_join("production-unlocked.json")
	var store := Save.new(location, validate)
	var loaded := store.load()
	var baseline := payload(run)
	var written := store.commit(baseline, loaded.revision)
	check(written.ok, "Real milestone plus retained later shop saves durably.")
	if not written.ok: return
	var clone: Dictionary = run.clone_for_transaction()
	check(clone.run.leave_shop(clone.run.shop_snapshot().identity).ok, "Detached candidate leaves actual shop.")
	var candidate := payload(clone.run)
	for failure in ["write", "flush", "close", "backup", "replace"]:
		store.failure_point = failure
		check(not store.commit(candidate, written.revision).ok and run.export_save() == retained and payload(clone.run) == candidate, "Failed " + failure + " retains original owners and identical Retry candidate.")
		var durable := Save.new(location, validate).load()
		check(durable.ok and durable.payload == baseline, "Restart after failed " + failure + " uses only durable milestone/shop state.")
	store.failure_point = ""
	check(store.commit(candidate, written.revision).ok, "Identical Retry saves the already prepared candidate.")
	run.publish_transaction(clone.run)
	var next = Run.new(setup, 1, true, Callable(), null, Profile.production_rules(), run.profile_state().clone_for_transaction())
	check(next.snapshot().owned_cards.size() == 8 and next.snapshot().owned_cards.all(func(card): return card.id in Profile.INITIAL_IDS and card.upgrade_rank == 0), "New Run retains unlock and exactly eight rank-zero starter copies.")
	check(next.store_snapshot().runes.size() == 5 and next.export_save().store.transactions.is_empty(), "New Run retains definition eligibility while resetting run-only Store allowances.")
	FileAccess.open(directory.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes({"process_id": OS.get_process_id(), "unlocked": unlocked, "payload": payload(run), "new_run": payload(next)}))

func _restart() -> void:
	var expected: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(directory.path_join("expected.bin")))
	check(expected.process_id != OS.get_process_id(), "Restart is a distinct operating-system process.")
	var loaded := Save.new(directory.path_join("production-unlocked.json"), validate).load()
	check(loaded.ok and loaded.payload == expected.payload, "Fresh process loads exact successful Retry candidate with permanent unlock.")
	if not loaded.ok: return
	var restored := validate(loaded.payload)
	check(restored.ok and payload(restored.run) == expected.payload, "Current catalogue restore preserves shop stock, receipts, rank, resources and RNG.")
	var next = Run.new(setup, 1, true, Callable(), null, Profile.production_rules(), restored.run.profile_state().clone_for_transaction())
	check(expected.unlocked in next.profile_state().snapshot().unlocked_definition_ids and next.snapshot().owned_cards.size() == 8 and next.snapshot().owned_cards.all(func(card): return card.id in Profile.INITIAL_IDS), "Restart then New Run keeps new unlock without granting a starter copy.")
	check(next.store_snapshot().runes.any(func(item): return item.definition_id == expected.unlocked), "Later run's fixed Store offers the legitimately unlocked definition.")
	_use_unlocked(restored.run.profile_state(), str(expected.unlocked))

func _use_unlocked(profile, id: String) -> void:
	for seed in range(8):
		var run = Run.new(setup, seed, true, Callable(), null, Profile.production_rules(), profile.clone_for_transaction())
		var first := Journey.enter(run, Journey.next_node(run, "normal"))
		if not first.ok or not _battle(run, first, "new-run-seed%d-depth1" % seed): continue
		var offer: Dictionary = run.pending_reward()
		if not id in offer.offered_ids: continue
		var acquired: Dictionary = run.choose_reward(offer.identity, id)
		check(acquired.ok and acquired.granted_card.upgrade_rank == 0 and acquired.granted_card.uid >= 8, "Later real normal victory offers and grants the unlocked definition as a fresh rank-zero UID.")
		if not acquired.ok: return
		var uid: int = acquired.granted_card.uid
		check(Journey.finish_rewards(run).ok, "New-content reward retains ordinary result/choice ordering.")
		var used := false
		for depth in range(2, 6):
			var entered := Journey.enter(run, Journey.next_node(run, "normal"))
			check(entered.ok, "Acquired new definition enters next real room without changing catalogue or UID.")
			if not entered.ok: return
			if entered.has("combat"):
				check(entered.combat.run_handoff().owned_cards.has(acquired.granted_card), "Actual Combat receives new owned definition across enemy transfer.")
				if not _battle(run, entered, "new-run-seed%d-depth%d" % [seed, depth]): return
				var trace: Dictionary = traces.back()
				used = used or trace.commands.any(func(command): return command.command == "place_rune" and command.arguments.get("uid") == uid and command.accepted)
				check(Journey.finish_rewards(run).ok, "Later real enemy reward and result settle with new content retained.")
			else: check(Journey.finish_room(run).ok, "New-content journey resolves ordinary service.")
			if used: break
		check(used and run.snapshot().owned_cards.has(acquired.granted_card), "Legitimately acquired " + id + " executes through actual controller and remains owned after enemy handoff.")
		var path := directory.path_join("new-run-acquisition.json")
		var store := Save.new(path, validate)
		var loaded := store.load()
		check(store.commit(payload(run), loaded.revision).ok, "Real new-content journey saves with exact UID, later reward history and profile unlock.")
		traces.append({"acquisition_seed": seed, "unlocked_definition": id, "granted_card": acquired.granted_card, "final": run.snapshot()})
		return
	check(false, "Bounded ordinary journeys must demonstrate a later offer of the legitimate unlock.")
