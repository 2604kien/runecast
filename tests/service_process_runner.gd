extends SceneTree
## Every stage is a fresh OS process. Test-only expected.bin holds comparison
## evidence and retained intents; the shipped save never stores unsaved intents.
const Fixture = preload("res://tests/helpers/service_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const RewardFixture = preload("res://tests/helpers/reward_route_fixture.gd")
const RewardTests = preload("res://tests/reward_state_tests.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
var destination := ""
var scenario := ""
var stage := ""
var variant := "recovery"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary
var context: Dictionary
var evidence: Dictionary = {}
var subject
var store
var revision := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): destination = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
		if argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
		if argument.begins_with("--variant="): variant = argument.trim_prefix("--variant=")
	if destination.is_empty() or stage.is_empty() or scenario.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	setup = Loader.load_setup().setup
	context = _context()
	if FileAccess.file_exists(destination.path_join("expected.bin")): evidence = bytes_to_var(FileAccess.get_file_as_bytes(destination.path_join("expected.bin")))
	if stage == "legacy":
		check(DirAccess.copy_absolute(_legacy_source(), destination.path_join("active.json")) == OK, "Migration imports genuine predecessor envelope bytes.")
		evidence.original = FileAccess.get_file_as_bytes(destination.path_join("active.json"))
	store = Save.new(destination.path_join("active.json"), validate)
	var loaded: Dictionary = store.load()
	if stage == "recover":
		check(not loaded.ok and loaded.get("recovery_available", false), "Fresh process blocks damaged current and validates the real predecessor previous copy.")
	else:
		check(loaded.ok, "Fresh process reads a coherent checkpoint: " + str(loaded.get("error", "")))
		if not loaded.ok:
			_finish()
			return
		revision = loaded.get("revision", 0)
		if loaded.status == "valid":
			var restored: Dictionary = validate(loaded.payload)
			check(restored.ok, "Fresh process reconstructs validated owners.")
			if not restored.ok:
				_finish()
				return
			subject = restored.run
			if evidence.has("last"): check(subject.export_save() == evidence.last, "Restart retains exact committed HP, Gold, receipts, ownership, identities and RNG.")
	_run_stage(loaded)
	_finish()

func _context() -> Dictionary:
	if not scenario.begins_with("migration-"): return Fixture.context_for(Fixture.new_run(42, variant))
	if variant in ["production-v1", "production-v2"]: return {}
	if variant == "reward-v1": return ShopFixture.context_for(RewardFixture.new_run())
	if variant == "pending-reward-v2":
		return RewardTests.new()._boss_run(Profile.new(setup.catalog, ["spark"])).restore_context_for_tests()
	return ShopFixture.context_for(ShopFixture.new_run())

func _legacy_source() -> String:
	return "res://tests/fixtures/" + ("rc028/" if variant.ends_with("v1") else "rc029/") + variant + ".json"

func validate(payload: Dictionary) -> Dictionary:
	var profile: Dictionary = Profile.restore_save(payload.get("profile", {}), setup.catalog, not context.is_empty())
	return profile if not profile.ok else Run.restore_save(payload.get("run", {}), setup, profile.profile, context)

func save_candidate(candidate) -> bool:
	var result: Dictionary = store.commit({"profile": candidate.profile_state().export_save(), "run": candidate.export_save()}, revision)
	check(result.ok, "Complete candidate saves before publication: " + str(result.get("error", "")))
	if result.ok:
		revision = result.revision
		subject = candidate
		evidence.last = subject.export_save()
	return result.ok

func _choice() -> String:
	return {"recovery": "recover", "satchel": "take_gold", "tithe": "blood_tithe", "reliquary": "leave", "desk": "leave"}.get(variant, "leave")

func apply_action(candidate, action: String) -> Dictionary:
	match action:
		"entry": return Fixture.enter_service(candidate)
		"resolve": return candidate.resolve_service(candidate.service_snapshot().identity, _choice())
		"second_entry": return Fixture.enter_service(candidate)
		"second_resolve": return candidate.resolve_service(candidate.service_snapshot().identity, "blood_tithe" if candidate.snapshot().player_hp > 8 else "leave")
	return {"ok": false, "error": "Unknown action"}

func _run_stage(loaded: Dictionary) -> void:
	match stage:
		"new":
			check(subject == null, "New isolated process has no preexisting run.")
			save_candidate(Fixture.new_run(42, variant))
		"win":
			var cloned: Dictionary = subject.clone_for_transaction()
			check(cloned.ok and Fixture.win_battle(cloned.run).ok, "Genuine supported Wisp victory establishes actual damage and resources.")
			check(cloned.run.snapshot().player_hp > 0 and cloned.run.snapshot().player_hp < 30 and cloned.run.snapshot().gold == 0, "First battle carries real damage and grants no fixture Gold.")
			save_candidate(cloned.run)
			evidence.first_hp = subject.snapshot().player_hp
		"entry", "resolve", "second_entry", "second_resolve":
			var cloned: Dictionary = subject.clone_for_transaction()
			var original: Dictionary = subject.export_save()
			var result: Dictionary = apply_action(cloned.run, stage)
			check(result.ok and subject.export_save() == original, stage + " stages without live-owner mutation: " + str(result.get("error", "")))
			if result.ok: save_candidate(cloned.run)
			_verify_action(stage, original)
		"fail":
			var parts := scenario.split("-")
			var action: String = parts[1]
			var point: String = parts[2]
			var cloned: Dictionary = subject.clone_for_transaction()
			var original: Dictionary = subject.export_save()
			var bytes_before := FileAccess.get_file_as_bytes(store.path)
			check(cloned.ok and apply_action(cloned.run, action).ok, "Failure fixture stages one exact service action.")
			evidence.before_failure = original
			evidence.intent = {"profile": cloned.profile.export_save(), "run": cloned.run.export_save()}
			store.failure_point = point
			var failed: Dictionary = store.commit(evidence.intent, revision)
			check(not failed.ok and subject.export_save() == original and FileAccess.get_file_as_bytes(store.path) == bytes_before, point + " failure preserves previous HP, Gold, ownership, receipt and route bytes.")
		"retry":
			check(subject.export_save() == evidence.before_failure, "Restart after failure restores only last durable progress.")
			var intended: Dictionary = validate(evidence.intent)
			check(intended.ok, "Retained test-only staged action validates after restart.")
			if intended.ok:
				check(save_candidate(intended.run) and subject.export_save() == evidence.intent.run, "Retry publishes precisely the identical retained service outcome.")
				_verify_action(scenario.split("-")[1], evidence.before_failure)
		"next":
			var identity: Dictionary = evidence.identity
			check(not subject.resolve_service(identity, _choice()).ok and not subject.request_room_entry(identity.node_id).ok, "Completed service rejects stale actions and reentry.")
			var cloned: Dictionary = subject.clone_for_transaction()
			var prepared: Dictionary = cloned.run.prepare_route_battle(cloned.run.request_room_entry("d3").token)
			check(prepared.ok, "Next real battle prepares after service resolution.")
			if prepared.ok:
				var entered: Dictionary = cloned.run.commit_route_battle(prepared)
				check(entered.ok and entered.combat.run_handoff().player_hp == subject.snapshot().player_hp, "Subsequent battle entry uses exact post-service HP without a loadout reset.")
				evidence.opening = entered.combat.snapshot()
				evidence.entry_handoff = entered.combat.run_handoff()
				save_candidate(cloned.run)
		"replay":
			var continued: Dictionary = subject.continue_battle()
			check(continued.ok, "Fresh process resumes next battle.")
			if continued.ok:
				for key in evidence.opening:
					check(continued.combat.snapshot()[key] == evidence.opening[key], "Fresh process exactly replays post-service battle snapshot " + key + ".")
				for key in evidence.entry_handoff:
					if key == "battle_identity":
						var replay_identity: Dictionary = continued.combat.run_handoff().battle_identity.duplicate()
						var entry_identity: Dictionary = evidence.entry_handoff.battle_identity.duplicate()
						check(replay_identity.generation > entry_identity.generation, "Replay advances the callback generation to invalidate stale Combat callbacks.")
						replay_identity.erase("generation")
						entry_identity.erase("generation")
						check(replay_identity == entry_identity, "Replay retains exact run, route, node and visit identity.")
						continue
					check(continued.combat.run_handoff()[key] == evidence.entry_handoff[key], "Fresh process exactly replays post-service handoff " + key + ".")
		"next_win":
			var cloned: Dictionary = subject.clone_for_transaction()
			var continued: Dictionary = cloned.run.continue_battle()
			check(continued.ok and Integration.new()._win(continued.combat) and cloned.run.resolve_battle(continued.combat), "Second genuine supported battle resolves through ordinary controller actions.")
			if cloned.run.snapshot().pending_result.is_empty(): return
			check(cloned.run.acknowledge_result(cloned.run.snapshot().pending_result.identity), "Second battle acknowledgement preserves authoritative health boundary.")
			save_candidate(cloned.run)
			evidence.second_hp = subject.snapshot().player_hp
		"shop":
			var cloned: Dictionary = subject.clone_for_transaction()
			check(Fixture.enter_shop(cloned.run).ok, "Event resolution opens the later shop through guarded entry.")
			var gold: int = cloned.run.snapshot().gold
			var stock: Dictionary = cloned.run.shop_snapshot()
			var bought: Dictionary = cloned.run.buy_shop_rune(stock.identity, stock.slots[0].slot_id)
			check(bought.ok == (gold >= 30), "Later shop can spend only Gold already awarded by previous events.")
			if bought.ok: check(cloned.run.snapshot().gold == gold - 30, "Event-funded purchase spends exactly 30 Gold once.")
			check(cloned.run.leave_shop(stock.identity).ok, "Later shop completes once through explicit Leave.")
			save_candidate(cloned.run)
		"settled":
			check(subject.route_snapshot().completed_count == 5 and subject.snapshot().player_max_hp == 30, "Five genuine completed visits preserve maximum HP; no complete tower is claimed.")
		"legacy":
			check(loaded.payload.run.version in [1, 2], "Imported predecessor retains its original version.")
			evidence.legacy = loaded.payload
			evidence.last = subject.export_save()
			for key in loaded.payload.run:
				if key == "version": continue
				if key in ["shop_policy_id", "service_policy_id"]: continue
				var legacy_shape = preload("res://tests/helpers/legacy_card_shape.gd")
				check(legacy_shape.strip_new_defaults(subject.export_save()[key]) == legacy_shape.strip_new_defaults(loaded.payload.run[key]), "Migration preserves predecessor " + key + " with explicit rank-zero defaults.")
			check(subject.export_save().version == Run.SAVE_VERSION, "Predecessor reconstructs the current versioned extension.")
		"migration_fail":
			store.failure_point = "replace"
			var failed: Dictionary = store.commit({"profile": subject.profile_state().export_save(), "run": subject.export_save()}, revision)
			check(not failed.ok and FileAccess.get_file_as_bytes(store.path) == evidence.original, "Failed promotion preserves exact original predecessor bytes.")
		"migrate":
			check(save_candidate(subject), "Version-three promotion succeeds through ordinary transaction boundary.")
			check(FileAccess.get_file_as_bytes(store.path + ".previous") == evidence.original, "Promotion validates and retains exact predecessor as previous copy.")
		"migration_restart":
			check(loaded.payload.run.version == Run.SAVE_VERSION and subject.export_save() == evidence.last, "Fresh process restores promoted services extension without altering legacy resources.")
			if not subject.shop_snapshot().is_empty(): check(subject.shop_snapshot().status == "active", "Migrated active shop remains the active retained service.")
			if variant == "pending-reward-v2": check(not subject.snapshot().pending_result.is_empty() and not subject.pending_reward().is_empty(), "Real v2 pending result and unclaimed unlock both survive restart.")
			if variant == "replay-shop-v2": check(subject.continue_battle().ok, "Migrated v2 battle after shop replays its exact saved entry.")
		"damage":
			FileAccess.open(store.path, FileAccess.WRITE).store_string("damaged-current")
			check(FileAccess.get_file_as_bytes(store.path + ".previous") == evidence.original, "Damaged-current test retains real validated predecessor backup.")
		"recover":
			var recovered: Dictionary = store.recover_previous()
			check(recovered.ok and FileAccess.get_file_as_bytes(store.path) == evidence.original, "Explicit previous-copy recovery promotes exact original legacy bytes.")
		"recovered":
			check(loaded.payload.run.version in [1, 2] and subject.export_save() == evidence.last, "Recovered predecessor revalidates and migrates to identical owner state in a fresh process.")
		"legacy_continue":
			var cloned: Dictionary = subject.clone_for_transaction()
			check(cloned.ok, "Recovered migrated owner can stage a new transaction.")
			var candidate = cloned.run
			if variant == "active-shop-v2":
				var stock: Dictionary = candidate.shop_snapshot()
				check(candidate.leave_shop(stock.identity).ok, "Migrated active shop retains its normal durable Leave contract.")
			if variant in ["active-shop-v2", "completed-shop-v2"]:
				var entered: Dictionary = candidate.commit_route_battle(candidate.prepare_route_battle(candidate.request_room_entry("d3").token))
				check(entered.ok and entered.combat.run_handoff().player_hp == subject.snapshot().player_hp, "New battle after migrated shop starts at validated legacy HP.")
				check(entered.combat.run_handoff().owned_cards == subject.snapshot().owned_cards, "New battle after migrated shop preserves every bought/removed copy.")
			elif variant == "replay-shop-v2":
				var continued: Dictionary = candidate.continue_battle()
				check(continued.ok and Integration.new()._win(continued.combat) and candidate.resolve_battle(continued.combat), "Migrated replay reaches a genuine result and establishes the next health boundary.")
				check(candidate.acknowledge_result(candidate.snapshot().pending_result.identity), "Migrated replay result acknowledges without losing battle health history.")
			elif variant == "pending-reward-v2":
				var reward: Dictionary = candidate.pending_reward()
				check(candidate.choose_reward(reward.identity, reward.offered_ids[0]).ok, "Migrated pending unlock remains claimable once.")
				check(not candidate.choose_reward(reward.identity, reward.offered_ids[0]).ok, "Migrated unlock cannot duplicate after claim.")
				check(candidate.acknowledge_result(candidate.snapshot().pending_result.identity), "Migrated result acknowledges independently after unlock.")
			save_candidate(candidate)
		"legacy_continued":
			check(loaded.payload.run.version == Run.SAVE_VERSION and subject.export_save() == evidence.last, "Fresh process retains post-migration gameplay and reconciled new health boundaries.")
		_:
			check(false, "Unknown stage: " + stage)

func _verify_action(action: String, before: Dictionary) -> void:
	check(subject.export_save().rng_states == before.rng_states and subject.export_save().reward_rng_state == before.reward_rng_state and subject.export_save().shop_rng_state == before.shop_rng_state, "Service actions preserve Combat, reward and shop RNG streams.")
	check(subject.snapshot().player_max_hp == before.player_max_hp and subject.snapshot().owned_cards == before.owned_cards, "Service actions preserve maximum HP and exact owned copies.")
	if action.ends_with("entry"):
		var service: Dictionary = subject.service_snapshot()
		evidence.identity = service.identity
		check(not service.is_empty() and subject.route_snapshot().status == "room_active", "Committed entry retains one unresolved active service.")
		check(subject.snapshot().player_hp == before.player_hp and subject.snapshot().gold == before.gold, "Entry never grants a benefit or cost.")
	else:
		var choice := _choice() if action == "resolve" else ("blood_tithe" if before.player_hp > 8 else "leave")
		var gain := mini(10, before.player_max_hp - before.player_hp) if choice == "recover" else -8 if choice == "blood_tithe" else 0
		var gold := 20 if choice == "take_gold" else 40 if choice == "blood_tithe" else 0
		check(subject.snapshot().player_hp == before.player_hp + gain and subject.snapshot().gold == before.gold + gold, "Resolved choice applies its exact capped HP and Gold outcome together.")
		check(subject.service_snapshot().is_empty() and subject.route_snapshot().status == "route_ready", "A single durable resolution completes the room and returns to route progression.")
		var after: Dictionary = subject.export_save()
		check(not subject.resolve_service(evidence.identity, choice).ok and not subject.resolve_service(evidence.identity, "leave").ok and subject.export_save() == after, "Benefit and Leave are mutually exclusive and cannot repeat after commit.")

func _finish() -> void:
	FileAccess.open(destination.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(destination.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"scenario": scenario, "variant": variant, "stage": stage, "process_id": OS.get_process_id(), "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-030 process %s/%s: %d checks, %d failures" % [scenario, stage, checks, failures])
	quit(0 if failures == 0 else 1)
