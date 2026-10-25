extends SceneTree
## Store durability: expected.bin holds comparisons only, never restored owners.
## Same-process Retry retains one exact detached candidate; a process exit loses it.
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
var directory := ""
var stage := ""
var operation := ""
var point := ""
var mode := ""
var setup: Dictionary
var context: Dictionary
var subject
var store
var revision := 0
var evidence: Dictionary = {}
var checks := 0
var failures := 0
var assertions: Array = []

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): directory = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
		if argument.begins_with("--operation="): operation = argument.trim_prefix("--operation=")
		if argument.begins_with("--point="): point = argument.trim_prefix("--point=")
		if argument.begins_with("--mode="): mode = argument.trim_prefix("--mode=")
	if directory.is_empty() or stage.is_empty() or operation.is_empty() or mode.is_empty():
		quit(2)
		return
	call_deferred("_run")

func payload(owner) -> Dictionary:
	return {"profile": owner.profile_state().export_save(), "run": owner.export_save()}

func validate(value: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(value.get("profile", {}), setup.catalog, true)
	return profile if not profile.ok else Run.restore_save(value.get("run", {}), setup, profile.profile, context)

func _run() -> void:
	setup = Loader.load_setup().setup
	context = Fixture.context_for(Fixture.new_run())
	DirAccess.make_dir_recursive_absolute(directory)
	var evidence_path := directory.path_join("expected.bin")
	if FileAccess.file_exists(evidence_path): evidence = bytes_to_var(FileAccess.get_file_as_bytes(evidence_path))
	store = Save.new(directory.path_join("active.json"), validate)
	var loaded: Dictionary = store.load()
	if stage == "recover":
		check(not loaded.ok and loaded.recovery_available, "Damaged current exposes a validated preceding Store checkpoint.")
		var recovered: Dictionary = store.recover_previous()
		check(recovered.ok, "Explicit Store recovery succeeds: " + str(recovered.get("error", "")))
		if recovered.ok:
			check(FileAccess.get_file_as_bytes(store.path) == evidence.recovery_bytes, "Recovery retains exactly the genuine preceding checkpoint bytes.")
			check(FileAccess.get_file_as_string(recovered.preserved_path) == "RC-032 Store isolated damage", "Recovery preserves unreadable current bytes separately.")
	else:
		check(loaded.ok, "Fresh process reads only a validated durable checkpoint: " + str(loaded.get("error", "")))
		if loaded.ok:
			revision = loaded.revision
			if loaded.status == "valid":
				var restored := validate(loaded.payload)
				check(restored.ok, "Fresh process restores authoritative owners.")
				if restored.ok: subject = restored.run
			match stage:
				"prepare": _prepare()
				"fail": _exercise_failure()
				"restart": _restart_check()
				"damage": _damage()
				"recovered":
					check(payload(subject) == evidence.recovery_payload, "A further fresh process reproduces the exact recovered Store owner.")
					check(Settings.load_values(directory.path_join("settings.cfg")) == evidence.settings, "Recovery leaves independent Options unchanged.")
				_: check(false, "Unknown Store process stage.")
	FileAccess.open(evidence_path, FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"stage": stage, "operation": operation, "mode": mode, "point": point, "process_id": OS.get_process_id(), "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-032 Store process %s/%s/%s: %d checks, %d failures" % [operation, mode, stage, checks, failures])
	subject = null
	store = null
	context.clear()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _save_owner(owner) -> bool:
	var saved: Dictionary = store.commit(payload(owner), revision)
	check(saved.ok, "Ordinary validated commit writes the prepared boundary: " + str(saved.get("error", "")))
	if not saved.ok: return false
	revision = saved.revision
	subject = owner
	return true

func _purchase(owner, kind: String, id: String, identity: Dictionary = {}) -> Dictionary:
	if identity.is_empty(): identity = owner.store_snapshot().identity
	return owner.purchase_store_rune(identity, id) if kind == "rune" else owner.purchase_store_relic(identity, id)

func _prepare() -> void:
	var candidate = Fixture.new_run()
	if not _save_owner(candidate): return
	var entered: Dictionary = Fixture.enter_next(candidate)
	check(entered.ok and entered.has("combat"), "The funded Store boundary starts with an ordinary fixture room entry.")
	if not entered.ok: return
	check(Fixture.win_combat(entered.combat) and candidate.resolve_battle(entered.combat), "Legal Combat commands earn the fixture payout.")
	check(Fixture.finish_rewards(candidate).ok and candidate.snapshot().gold == 250, "All encounter choices and acknowledgement settle before Store access.")
	if operation.ends_with("second"):
		var prior_kind := "relic" if operation.begins_with("rune") else "rune"
		var prior_id := "relic_ember_lens" if prior_kind == "relic" else "shield"
		var bought := _purchase(candidate, prior_kind, prior_id)
		check(bought.ok, "First category purchase uses its actual Store transaction before a later visit: " + str(bought.get("error", "")))
		if not bought.ok: return
		check(Fixture.enter_next(candidate).ok and Fixture.finish_room(candidate).ok, "A subsequent real event completes between the two Store categories.")
	if not _save_owner(candidate): return
	evidence.baseline = payload(subject)
	evidence.summary = subject.run_summary()
	evidence.settings = Settings.normalize({"reduced_motion": true, "music_volume": 0.25, "sfx_volume": 0.5, "sfx_muted": true})
	check(Settings.save_values(evidence.settings, directory.path_join("settings.cfg")) == OK, "Store scenarios preserve independently persisted Options.")
	check(subject.store_snapshot().enabled, "The exact funded and settled between-room boundary enables Store.")

func _exercise_failure() -> void:
	if subject == null:
		check(false, "Purchase needs the durable prepared boundary.")
		return
	check(payload(subject) == evidence.baseline, "The process starts from the exact durable baseline.")
	var kind := "rune" if operation.begins_with("rune") else "relic"
	var id := "spark" if kind == "rune" else "relic_heart_stone"
	var identity: Dictionary = subject.store_snapshot().identity
	evidence.purchase = {"identity": identity, "kind": kind, "id": id}
	var clone: Dictionary = subject.clone_for_transaction()
	check(clone.ok, "Store stages detached run and profile owners.")
	if not clone.ok: return
	var candidate = clone.run
	var bought := _purchase(candidate, kind, id, identity)
	check(bought.ok, "The exact Store purchase stages successfully: " + str(bought.get("error", "")))
	if not bought.ok: return
	var intended := payload(candidate)
	var identical := var_to_bytes(intended)
	evidence.intended = intended # Comparison only: no stage restores this sidecar.
	var baseline: Dictionary = evidence.baseline.run
	check(intended.run.gold == baseline.gold - (45 if kind == "rune" else 90), "The documented price is charged exactly once.")
	check(intended.profile == evidence.baseline.profile, "Store purchases never change permanent definition ownership.")
	check(intended.run.route == baseline.route, "Store is outside the route and cannot create or complete a visit.")
	check(intended.run.reward_rng_state == baseline.reward_rng_state and intended.run.shop_rng_state == baseline.shop_rng_state, "Fixed Store inventory consumes no reward or shop RNG.")
	check(intended.run.store.transactions.size() == baseline.store.transactions.size() + 1, "Exactly one Store receipt is added.")
	if kind == "rune":
		check(intended.run.owned_cards.size() == baseline.owned_cards.size() + 1 and intended.run.owned_cards.back() == {"id": id, "uid": baseline.next_uid, "upgrade_rank": 0}, "Rune purchase adds the exact new unupgraded physical UID.")
		check(intended.run.relics == baseline.relics and intended.run.player_hp == baseline.player_hp and intended.run.player_max_hp == baseline.player_max_hp, "Rune purchase preserves relics and current health.")
	else:
		check(intended.run.relics.size() == baseline.relics.size() + 1 and id in intended.run.relics and intended.run.owned_cards == baseline.owned_cards, "Relic purchase grants one unique relic and no Rune copies.")
		check(intended.run.player_hp == baseline.player_hp + 4 and intended.run.player_max_hp == baseline.player_max_hp + 4, "Heart Stone applies the shared acquisition hook once to current and maximum HP.")
	var owner_before = subject
	var live_before: Dictionary = subject.snapshot()
	var disk_before := FileAccess.get_file_as_bytes(store.path)
	check(payload(subject) == evidence.baseline, "Staging leaves every published owner unchanged.")
	store.failure_point = point
	var failed: Dictionary = store.commit(intended, revision)
	check(not failed.ok, "Injected " + point + " failure rejects the Store write.")
	check(subject == owner_before and subject.snapshot() == live_before, "Failed write retains exact owner identity and visible state.")
	check(FileAccess.get_file_as_bytes(store.path) == disk_before, "Failed write preserves the last durable bytes exactly.")
	check(var_to_bytes(payload(candidate)) == identical, "Failure retains the same in-memory Retry candidate and receipt.")
	if mode == "retry":
		store.failure_point = ""
		var saved: Dictionary = store.commit(intended, revision)
		check(saved.ok and var_to_bytes(payload(candidate)) == identical, "Same-process Retry durably writes the identical candidate without rebuilding inventory or UID.")
		if saved.ok:
			subject.publish_transaction(candidate)
			revision = saved.revision
			check(payload(subject) == intended, "Published receipt and resources exactly match the durable candidate.")
	else:
		check(mode == "restart" and payload(subject) == evidence.baseline, "Process exit discards unsaved purchase intent.")
	check(Settings.load_values(directory.path_join("settings.cfg")) == evidence.settings, "Purchase and failure preserve persisted Options.")

func _restart_check() -> void:
	if subject == null:
		check(false, "Restart needs a durable owner.")
		return
	var expected: Dictionary = evidence.intended if mode == "retry" else evidence.baseline
	check(payload(subject) == expected, "Fresh process restores only the retried purchase or the prior checkpoint, never failed intent.")
	check(Settings.load_values(directory.path_join("settings.cfg")) == evidence.settings, "Fresh process retains persisted settings.")
	check(subject.profile_state().export_save() == evidence.baseline.profile, "Restart preserves permanent ownership.")
	var before := payload(subject)
	var purchase: Dictionary = evidence.purchase
	if mode == "retry":
		check(not _purchase(subject, purchase.kind, purchase.id, purchase.identity).ok, "Repeated stale purchase callback is rejected after restart.")
		check(not _purchase(subject, purchase.kind, purchase.id).ok, "Fresh Store identity cannot bypass the purchased category limit.")
		check(payload(subject) == before, "Duplicate callbacks consume no Gold, UID, health or receipts.")
		var view: Dictionary = subject.store_snapshot()
		check(view.rune_purchased == (purchase.kind == "rune" or operation.ends_with("second")) and view.relic_purchased == (purchase.kind == "relic" or operation.ends_with("second")), "One Rune and one relic limits persist across visits and OS processes.")
	else:
		var candidate: Dictionary = subject.clone_for_transaction()
		check(candidate.ok and _purchase(candidate.run, purchase.kind, purchase.id).ok, "Discarded failed intent leaves the legitimate category available.")
		check(payload(subject) == before, "Availability probing never publishes a new purchase.")

func _damage() -> void:
	evidence.recovery_bytes = FileAccess.get_file_as_bytes(store.path + ".previous")
	var decoded := Save.decode_document(evidence.recovery_bytes.get_string_from_utf8())
	check(decoded.ok, "The real preceding Store envelope is intact before explicit damage.")
	if not decoded.ok: return
	var restored := validate(decoded.payload)
	check(restored.ok, "Recovery target validates its chronological resource history.")
	if not restored.ok: return
	evidence.recovery_payload = payload(restored.run)
	FileAccess.open(store.path, FileAccess.WRITE).store_string("RC-032 Store isolated damage")
	check(FileAccess.get_file_as_bytes(store.path + ".previous") == evidence.recovery_bytes, "Isolated damage leaves genuine recovery bytes unchanged.")
