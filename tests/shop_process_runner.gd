extends SceneTree
## Each stage is a fresh OS process, with explicit isolated file/APPDATA paths.
const Fixture = preload("res://tests/helpers/shop_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
var destination := ""
var scenario := ""
var stage := ""
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
	if destination.is_empty() or stage.is_empty() or scenario.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	setup = Loader.load_setup().setup
	context = Fixture.context_for(Fixture.new_run())
	if FileAccess.file_exists(destination.path_join("expected.bin")): evidence = bytes_to_var(FileAccess.get_file_as_bytes(destination.path_join("expected.bin")))
	store = Save.new(destination.path_join("active.json"), validate)
	var loaded: Dictionary = store.load()
	check(loaded.ok, "Fresh process reads a coherent checkpoint: " + str(loaded.get("error", "")))
	if loaded.ok:
		revision = loaded.revision if loaded.has("revision") else 0
		if loaded.status == "valid":
			var restored: Dictionary = validate(loaded.payload)
			check(restored.ok, "Fresh process reconstructs validated owner state.")
			if restored.ok:
				subject = restored.run
				check(subject.export_save() == evidence.last, "Restart retains exact committed identity, stock, ownership, Gold and RNG.")
		_run_stage()
	FileAccess.open(destination.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(destination.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"scenario": scenario, "stage": stage, "process_id": OS.get_process_id(), "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-029 process %s/%s: %d checks, %d failures" % [scenario, stage, checks, failures])
	quit(0 if failures == 0 else 1)

func validate(payload: Dictionary) -> Dictionary:
	var profile: Dictionary = Profile.restore_save(payload.get("profile", {}), setup.catalog, true)
	return profile if not profile.ok else Run.restore_save(payload.get("run", {}), setup, profile.profile, context)

func save_candidate(candidate) -> bool:
	var result: Dictionary = store.commit({"profile": candidate.profile_state().export_save(), "run": candidate.export_save()}, revision)
	check(result.ok, "Candidate commits before authoritative publication: " + str(result.get("error", "")))
	if result.ok:
		revision = result.revision
		subject = candidate
		evidence.last = subject.export_save()
	return result.ok

func apply_action(candidate, action: String) -> Dictionary:
	match action:
		"entry": return Fixture.enter_shop(candidate)
		"purchase": return candidate.buy_shop_rune(candidate.shop_snapshot().identity, candidate.shop_snapshot().slots[0].slot_id)
		"remove": return candidate.remove_shop_rune(candidate.shop_snapshot().identity, 0)
		"leave": return candidate.leave_shop(candidate.shop_snapshot().identity)
	return {"ok": false, "error": "Unknown action"}

func _run_stage() -> void:
	match stage:
		"new":
			check(subject == null, "New isolated process has no preexisting run.")
			save_candidate(Fixture.new_run())
		"win":
			var cloned: Dictionary = subject.clone_for_transaction()
			check(cloned.ok and Fixture.win_first(cloned.run).ok, "Ordinary battle victory and configured rewards create the funded pre-shop checkpoint.")
			save_candidate(cloned.run)
		"entry", "purchase", "remove", "leave":
			var cloned: Dictionary = subject.clone_for_transaction()
			var original: Dictionary = subject.export_save()
			var result: Dictionary = apply_action(cloned.run, stage)
			check(result.ok and subject.export_save() == original, stage + " stages changes without publishing them.")
			if result.ok: save_candidate(cloned.run)
			_verify_action(stage)
		"fail":
			var parts := scenario.split("_")
			var action: String = parts[0]
			var point: String = parts[1]
			var cloned: Dictionary = subject.clone_for_transaction()
			var original: Dictionary = subject.export_save()
			var bytes_before := FileAccess.get_file_as_bytes(store.path)
			check(cloned.ok and apply_action(cloned.run, action).ok, "Failure fixture stages the exact " + action + " once.")
			evidence.intent = {"profile": cloned.profile.export_save(), "run": cloned.run.export_save()}
			store.failure_point = point
			var failed: Dictionary = store.commit(evidence.intent, revision)
			check(not failed.ok and subject.export_save() == original and FileAccess.get_file_as_bytes(store.path) == bytes_before, point + " failure publishes no Gold, UID, stock, service or route change.")
		"retry":
			var intended: Dictionary = validate(evidence.intent)
			check(intended.ok, "Retained staged choice is valid after process restart.")
			if intended.ok:
				check(save_candidate(intended.run) and subject.export_save() == evidence.intent.run, "Retry publishes precisely the retained stock, price and resulting UID.")
				_verify_action(scenario.split("_")[0])
		"next":
			check(subject.route_snapshot().completed_count == 2 and subject.snapshot().gold == 30 and subject.snapshot().owned_cards.size() == 8, "Restart after Leave retains exactly one spend and one removal.")
			var identity: Dictionary = evidence.identity
			check(not subject.buy_shop_rune(identity, "rune-2").ok and not subject.leave_shop(identity).ok and not subject.request_room_entry(identity.node_id).ok, "Completed-shop stale callbacks cannot reopen transactions.")
			var candidate: Dictionary = subject.prepare_route_battle(subject.request_room_entry("d3").token)
			check(candidate.ok, "Next supported battle prepares from reconciled collection.")
			if candidate.ok:
				var entered: Dictionary = subject.commit_route_battle(candidate)
				check(entered.ok, "Next supported battle commits its real route visit.")
				var cards: Array = entered.combat.run_handoff().owned_cards
				check(cards.filter(func(c): return c.uid == evidence.bought_uid).size() == 1 and cards.filter(func(c): return c.uid == 0).is_empty(), "Purchased UID occurs once and removed starter remains absent after restart into next battle.")
				save_candidate(subject)
		"replay":
			var continued: Dictionary = subject.continue_battle()
			check(continued.ok and subject.route_snapshot().visit_count == 3, "Fresh process resumes subsequent battle without fabricating another visit.")
		_:
			check(false, "Unknown stage: " + stage)

func _verify_action(action: String) -> void:
	match action:
		"entry":
			var stock: Dictionary = subject.shop_snapshot()
			evidence.identity = stock.identity
			check(subject.route_snapshot().visit_count == 2 and subject.route_snapshot().completed_count == 1 and stock.slots.size() == 3, "Entry consumes exactly one active visit and retains distinct fixed stock.")
		"purchase":
			var stock: Dictionary = subject.shop_snapshot()
			evidence.bought_uid = stock.slots[0].granted_uid
			check(stock.slots[0].sold and subject.snapshot().owned_cards.size() == 9 and subject.snapshot().gold == 70 and subject.snapshot().next_uid == evidence.bought_uid + 1, "Purchase commits one 30-Gold debit, one owned UID and one sold slot.")
			check(not subject.buy_shop_rune(stock.identity, stock.slots[0].slot_id).ok, "Committed purchase cannot repeat after Retry or restart.")
		"remove":
			var stock: Dictionary = subject.shop_snapshot()
			check(stock.removal.used and subject.snapshot().owned_cards.size() == 8 and subject.snapshot().gold == 30 and subject.snapshot().owned_cards.filter(func(c): return c.uid == 0).is_empty(), "Removal commits one 40-Gold debit and exact UID deletion.")
			check(not subject.remove_shop_rune(stock.identity, 1).ok, "Committed once-only service cannot repeat.")
		"leave":
			check(subject.inspect_node("d3").state == "available" and subject.route_snapshot().completed_count == 2, "Explicit Leave completes once and unlocks successor.")
