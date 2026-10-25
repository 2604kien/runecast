extends SceneTree
## RC-031: each process reconstructs durable owners before doing one action.
const Fixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const Shop = preload("res://tests/helpers/shop_route_fixture.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
var directory := ""
var stage := ""
var action := ""
var point := ""
var seed_value := 15
var setup: Dictionary
var context: Dictionary
var evidence: Dictionary = {}
var checks := 0
var failures := 0
var assertions: Array = []
var subject
var store
var revision := 0

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): directory = arg.trim_prefix("--save-root=")
		if arg.begins_with("--stage="): stage = arg.trim_prefix("--stage=")
		if arg.begins_with("--action="): action = arg.trim_prefix("--action=")
		if arg.begins_with("--point="): point = arg.trim_prefix("--point=")
		if arg.begins_with("--seed="): seed_value = arg.trim_prefix("--seed=").to_int()
	if directory.is_empty() or stage.is_empty():
		quit(2)
		return
	setup = Loader.load_setup().setup
	context = Fixture.context_for(Fixture.new_run(seed_value))
	DirAccess.make_dir_recursive_absolute(directory)
	if FileAccess.file_exists(directory.path_join("expected.bin")): evidence = bytes_to_var(FileAccess.get_file_as_bytes(directory.path_join("expected.bin")))
	store = Save.new(directory.path_join("active.json"), validate)
	var loaded: Dictionary = store.load()
	check(loaded.ok, "Fresh process reads valid durable checkpoint: " + str(loaded.get("error", "")))
	if loaded.ok:
		revision = loaded.revision
		if loaded.status == "valid":
			var restored := validate(loaded.payload)
			check(restored.ok, "Restored ownership and chronological health validate.")
			if restored.ok:
				subject = restored.run
				check(subject.export_save() == evidence.last, "Restart retains exact ranks, relics, stock, receipts, HP, Gold and all random streams.")
		_run_stage()
	FileAccess.open(directory.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"stage": stage, "seed": seed_value, "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-031 process %s: %d checks, %d failures" % [stage, checks, failures])
	quit(0 if failures == 0 else 1)

func validate(payload: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(payload.get("profile", {}), setup.catalog, true)
	return profile if not profile.ok else Run.restore_save(payload.get("run", {}), setup, profile.profile, context)

func commit(candidate) -> bool:
	var result: Dictionary = store.commit({"profile": candidate.profile_state().export_save(), "run": candidate.export_save()}, revision)
	check(result.ok, "Candidate validates and saves before publication: " + str(result.get("error", "")))
	if not result.ok: return false
	if subject == null: subject = candidate
	else: subject.publish_transaction(candidate)
	check(subject.export_save() == candidate.export_save(), "Publication uses precisely the saved candidate.")
	revision = result.revision
	evidence.last = subject.export_save()
	return true

func _apply(candidate, operation: String) -> Dictionary:
	match operation:
		"win": return Shop.win_first(candidate)
		"recovery_entry", "tithe_entry", "recovery2_entry", "desk_entry", "reliquary_entry": return Fixture.enter_service(candidate)
		"recovery_before", "recovery_after": return candidate.resolve_service(candidate.service_snapshot().identity, "recover")
		"shop_entry", "second_shop_entry": return Fixture.enter_shop(candidate)
		"upgrade": return candidate.upgrade_shop_rune(candidate.shop_snapshot().identity, 0)
		"second_upgrade": return candidate.upgrade_shop_rune(candidate.shop_snapshot().identity, 3)
		"relic", "second_relic": return candidate.buy_shop_relic(candidate.shop_snapshot().identity)
		"remove": return candidate.remove_shop_rune(candidate.shop_snapshot().identity, 0)
		"leave", "second_leave": return candidate.leave_shop(candidate.shop_snapshot().identity)
		"tithe": return candidate.resolve_service(candidate.service_snapshot().identity, "blood_tithe")
		"battle_entry":
			var prepared: Dictionary = candidate.prepare_route_battle(candidate.request_room_entry(Fixture.next_node(candidate)).token)
			return candidate.commit_route_battle(prepared) if prepared.ok else prepared
		"replay": return candidate.continue_battle()
		"battle_win":
			var entered: Dictionary = candidate.continue_battle()
			if not entered.ok: return entered
			if not Integration.new()._win(entered.combat) or not candidate.resolve_battle(entered.combat): return {"ok": false, "error": "Genuine second battle failed."}
			var reward: Dictionary = candidate.pending_reward()
			if not candidate.skip_reward(reward.identity).ok or not candidate.claim_reward_gold(reward.identity).ok: return {"ok": false, "error": "Second fixture rewards failed."}
			return {"ok": candidate.acknowledge_result(candidate.snapshot().pending_result.identity)}
		"desk_upgrade": return candidate.resolve_service(candidate.service_snapshot().identity, "refine_rune", 5)
		"reliquary_take":
			var room: Dictionary = candidate.service_snapshot()
			return candidate.resolve_service(room.identity, "open_reliquary", room.offered_relics[0])
	return {"ok": false, "error": "Unknown process action."}

func _run_stage() -> void:
	if stage == "new":
		check(subject == null, "New fixture starts with an empty isolated save.")
		commit(Fixture.new_run(seed_value))
		return
	if subject == null: return
	if stage == "retry":
		var intended := validate(evidence.intent)
		check(intended.ok and subject.export_save() == evidence.before_failure, "Restart after failed write retains previous owners and validates exact staged candidate.")
		if intended.ok:
			commit(intended.run)
			check(subject.export_save() == evidence.intent.run, "Retry applies precisely one intended acquisition/upgrade without reroll.")
		return
	if stage in ["settled", "settled_failure"]:
		check(subject.profile_state().export_save() == evidence.profile, "Run modifiers never change persistent definition unlocks.")
		var fresh = Run.new(setup, seed_value, true, Callable(), null, Profile.production_rules(), subject.profile_state().clone_for_transaction())
		check(fresh.snapshot().relics.is_empty() and fresh.snapshot().player_hp == 30 and fresh.snapshot().player_max_hp == 30, "New Run resets all relics and restores 30/30 health.")
		check(fresh.snapshot().owned_cards.all(func(card): return card.upgrade_rank == 0), "New Run resets every instance upgrade.")
		check(fresh.profile_state().export_save() == evidence.profile, "New Run retains definition unlocks.")
		if stage == "settled":
			check(subject.snapshot().relics.size() == 3 and subject.snapshot().player_max_hp == 34, "Two shop relics and one Reliquary acquisition persist, Heart Stone applies once.")
			check(subject.snapshot().owned_cards.filter(func(card): return card.uid == 0).is_empty(), "Removed upgraded UID stays removed after later rooms and battles.")
		return
	var before: Dictionary = subject.export_save()
	var clone: Dictionary = subject.clone_for_transaction()
	check(clone.ok, "Authoritative owners clone before the action.")
	if not clone.ok: return
	var operation := action if stage == "fail" else stage
	var result: Dictionary = _apply(clone.run, operation)
	check(result.ok and subject.export_save() == before, operation + " succeeds on detached candidate without premature owner mutation: " + str(result.get("error", "")))
	if not result.ok: return
	if not evidence.has("profile"): evidence.profile = subject.profile_state().export_save()
	if operation == "battle_entry": evidence.opening = result.combat.snapshot()
	if operation == "replay": check(result.combat.snapshot() == evidence.opening, "Fresh-process replay reproduces exact initial hand, energy, topology and ranked instances.")
	if operation in ["relic", "second_relic"]:
		var expected: String = ("relic_heart_stone" if seed_value == 15 else "relic_menders_token") if operation == "relic" else ("relic_menders_token" if seed_value == 15 else "relic_heart_stone")
		check(result.relic_id == expected, "Retained seed selects the expected acquisition order.")
		var gain := 4 if expected == "relic_heart_stone" else 0
		check(clone.run.snapshot().player_hp == before.player_hp + gain and clone.run.snapshot().player_max_hp == before.player_max_hp + gain, "Acquisition changes current/max HP only for Heart Stone, once.")
		check(not clone.run.buy_shop_relic(clone.run.shop_snapshot().identity).ok, "Duplicate relic acquisition cannot charge or apply again.")
	if operation == "remove":
		check(result.get("removed_card", {}).get("upgrade_rank") == 1, "Removal targets the upgraded physical copy.")
	if operation in ["recovery_before", "recovery_after"]:
		var amount := 10 if operation == "recovery_before" else 14
		check(clone.run.snapshot().player_hp == mini(before.player_max_hp, before.player_hp + amount), "Recovery uses only relics acquired before this visit, capped at current maximum.")
	if operation in ["upgrade", "second_upgrade", "desk_upgrade"]:
		var uid := 0 if operation == "upgrade" else 3 if operation == "second_upgrade" else 5
		check(clone.run.snapshot().owned_cards.filter(func(card): return card.uid == uid and card.upgrade_rank == 1).size() == 1, "Exactly the selected physical UID gains one rank.")
	if stage == "fail":
		evidence.before_failure = before
		evidence.intent = {"profile": clone.profile.export_save(), "run": clone.run.export_save()}
		var original := FileAccess.get_file_as_bytes(store.path)
		store.failure_point = point
		var failed: Dictionary = store.commit(evidence.intent, revision)
		check(not failed.ok and subject.export_save() == before and FileAccess.get_file_as_bytes(store.path) == original, "Injected " + point + " failure preserves old owners and original durable bytes.")
		return
	commit(clone.run)
