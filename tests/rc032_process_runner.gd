extends SceneTree
## RC-032 durability audit. Evidence files are comparisons only: failed intent
## is never restored from a test sidecar. Retry uses the exact live candidate;
## the restart branch can read only the last committed LocalSave checkpoint.
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const ItemFixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const RewardFixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const FullFixture = preload("res://tests/helpers/rc032_route_fixture.gd")
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

func _run() -> void:
	setup = Loader.load_setup().setup
	context = FullFixture.context_for(FullFixture.new_run()) if _full_route() else ItemFixture.context_for(ItemFixture.new_run(15)) if operation in ["abandon-shop", "replacement"] else ShopFixture.context_for(RewardFixture.new_run(42))
	DirAccess.make_dir_recursive_absolute(directory)
	if FileAccess.file_exists(directory.path_join("expected.bin")):
		evidence = bytes_to_var(FileAccess.get_file_as_bytes(directory.path_join("expected.bin")))
	store = Save.new(directory.path_join("active.json"), validate)
	var loaded: Dictionary = store.load()
	check(loaded.ok, "Fresh process reads only a validated durable checkpoint: " + str(loaded.get("error", "")))
	if loaded.ok:
		revision = loaded.revision
		if loaded.status == "valid":
			var restored := validate(loaded.payload)
			check(restored.ok, "Fresh process restores authoritative owners.")
			if restored.ok: subject = restored.run
		_run_stage()
	FileAccess.open(directory.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"stage": stage, "operation": operation, "mode": mode, "point": point, "process_id": OS.get_process_id(), "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-032 process %s/%s/%s: %d checks, %d failures" % [operation, mode, stage, checks, failures])
	subject = null
	store = null
	context.clear()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func validate(payload: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(payload.get("profile", {}), setup.catalog, true)
	return profile if not profile.ok else Run.restore_save(payload.get("run", {}), setup, profile.profile, context)

func payload(owner) -> Dictionary:
	return {"profile": owner.profile_state().export_save(), "run": owner.export_save()}

func _full_route() -> bool:
	return operation.begins_with("guardian-") or operation.begins_with("victory-")

func _publish(candidate, saved: Dictionary) -> void:
	if subject == null or operation == "replacement":
		if subject != null: candidate.publish_profile_owner(subject.profile_state())
		subject = candidate
	else: subject.publish_transaction(candidate)
	revision = saved.revision
	check(payload(subject) == payload(candidate), "Only durable success publishes the precise candidate.")

func _prepare() -> void:
	var candidate
	if _full_route():
		candidate = FullFixture.new_run()
		var reached: Dictionary
		if operation == "guardian-outcome":
			reached = {"ok": true}
			for depth in range(1, 9):
				var entered: Dictionary = FullFixture.enter_next(candidate)
				if not entered.ok:
					reached = entered
					break
				if entered.has("combat"):
					if not FullFixture.win_combat(entered.combat) or not candidate.resolve_battle(entered.combat):
						reached = {"ok": false, "error": "Legal fixture battle failed."}
						break
					reached = FullFixture.finish_rewards(candidate)
				else: reached = FullFixture.finish_room(candidate)
				if not reached.ok: break
			if reached.ok: reached = FullFixture.enter_next(candidate)
		else:
			reached = FullFixture.play_to_guardian_pending(candidate)
		check(reached.ok and candidate.route_snapshot().visit_count == 9, "Legal full route reaches the separate ninth guardian: " + str(reached.get("error", "")))
		if not reached.ok: return
		if operation == "guardian-choice":
			var reward: Dictionary = candidate.pending_reward()
			check(candidate.skip_reward(reward.identity).ok and candidate.acknowledge_result(candidate.snapshot().pending_result.identity), "Guardian rune choice and encounter acknowledgement resolve before the final permanent choice.")
			evidence.final_award = candidate.pending_reward().offered_ids[0]
		elif operation in ["victory-ack", "victory-final-ack"]:
			check(FullFixture.finish_rewards(candidate, operation == "victory-final-ack").ok, "All required guardian choices settle before completed-tower review.")
	else:
		candidate = _predecessor()
	if candidate == null: return
	if operation == "final-ack":
		check(candidate.acknowledge_result(candidate.snapshot().pending_result.identity), "Final-result test first settles encounter acknowledgement without a payout.")
	var saved: Dictionary = store.commit(payload(candidate), revision)
	check(saved.ok, "Normalized baseline durably commits before exercising a failure: " + str(saved.get("error", "")))
	if not saved.ok: return
	_publish(candidate, saved)
	evidence.baseline = payload(subject)
	evidence.summary = subject.run_summary()
	evidence.settings = Settings.normalize({"reduced_motion": true, "music_volume": 0.25, "sfx_volume": 0.5, "sfx_muted": true})
	check(Settings.save_values(evidence.settings, directory.path_join("settings.cfg")) == OK, "Isolated settings persist before ending/replacement.")
	if subject.snapshot().status in ["battle", "replay_pending"]:
		var resumed: Dictionary = subject.continue_battle()
		check(resumed.ok, "Baseline has a genuine replayable entry.")
		if resumed.ok: evidence.opening = resumed.combat.snapshot()

func _predecessor():
	var specimen := "ranked-relic-shop-v4" if operation == "abandon-shop" else "ranked-history-v4" if operation == "replacement" else "pending-defeat-v4" if operation in ["result-ack", "final-ack"] else "interrupted-entry-v4"
	var decoded := Save.decode_document(FileAccess.get_file_as_string("res://tests/fixtures/rc031/" + specimen + ".json"))
	check(decoded.ok and decoded.payload.run.version == 4, "Starts from an unaltered genuine v4 specimen.")
	if not decoded.ok: return null
	var restored := validate(decoded.payload)
	check(restored.ok, "Genuine fixture restores for the transaction under test: " + str(restored.get("error", "")))
	return restored.run if restored.ok else null

func _stage_candidate() -> Dictionary:
	if operation in ["abandon-battle", "defeat", "guardian-outcome"]:
		var replay_candidate: Dictionary = subject.clone_for_transaction()
		check(replay_candidate.ok, "Resume stages the replay owner before saving the new battle generation.")
		if not replay_candidate.ok: return {"ok": false}
		var resumed: Dictionary = replay_candidate.run.continue_battle()
		check(resumed.ok and resumed.combat.snapshot() == evidence.opening, "Operation starts with the exact committed battle opening and RNG.")
		if not resumed.ok: return {"ok": false}
		var replay_saved: Dictionary = store.commit(payload(replay_candidate.run), revision)
		check(replay_saved.ok, "Resume durably commits its replay generation before publishing live Combat.")
		if not replay_saved.ok: return {"ok": false}
		_publish(replay_candidate.run, replay_saved)
		evidence.baseline = payload(subject)
		if operation == "abandon-battle":
			var controller := Controller.new(resumed.combat)
			check(Player.new().play_turn(controller), "A legal live turn precedes abandonment without a mid-turn save.")
			controller.dispose()
		elif operation == "defeat":
			while resumed.combat.state == "playing": resumed.combat.pass_turn()
			check(resumed.combat.state == "defeat", "Ordinary Pass actions reach genuine terminal defeat.")
		else: check(FullFixture.win_combat(resumed.combat), "Legal Combat actions win the distinct final guardian.")
	if operation == "replacement":
		var candidate = Run.new(setup, 15, true, func(id, seed): return ItemFixture.FixtureRoute.new(id, seed), ShopFixture.FixtureResolver.new(), ShopFixture.reward_rules(500), subject.profile_state().clone_for_transaction())
		return {"ok": true, "run": candidate}
	var clone: Dictionary = subject.clone_for_transaction()
	check(clone.ok, "Ending clones the authoritative owners before any mutation.")
	if not clone.ok: return clone
	var candidate = clone.run
	var accepted := false
	if operation.begins_with("abandon-"):
		var requested: Dictionary = subject.abandonment_request()
		check(requested.ok, "Explicit abandonment token binds the current committed checkpoint.")
		if not requested.ok: return {"ok": false}
		evidence.abandon_token = requested.token
		accepted = candidate.abandon_run(requested.token).ok
	elif operation in ["defeat", "guardian-outcome"]: accepted = candidate.resolve_battle(subject.current_battle())
	elif operation in ["result-ack", "victory-ack"]: accepted = candidate.acknowledge_result(candidate.snapshot().pending_result.identity)
	elif operation in ["final-ack", "victory-final-ack"]: accepted = candidate.acknowledge_final_result(candidate.snapshot().terminal.identity)
	elif operation == "guardian-choice": accepted = candidate.choose_reward(candidate.pending_reward().identity, evidence.final_award).ok
	check(accepted, "Requested terminal operation succeeds only on the detached candidate.")
	return {"ok": accepted, "run": candidate}

func _exercise_failure() -> void:
	check(payload(subject) == evidence.baseline, "Previous durable checkpoint is identical before the operation.")
	var staged := _stage_candidate()
	if not staged.ok: return
	var candidate = staged.run
	var old_owner = subject
	var old_combat = subject.current_battle()
	var live_before: Dictionary = subject.snapshot()
	var disk_before := FileAccess.get_file_as_bytes(store.path)
	var intended := payload(candidate)
	var identical := var_to_bytes(intended)
	evidence.intended = intended # Comparison only; no code restores this candidate.
	check(payload(subject) == evidence.baseline, "Staging leaves every committed run/profile owner unchanged.")
	if operation.begins_with("abandon-"):
		check(candidate.run_summary().player_hp == evidence.summary.player_hp and candidate.run_summary().visits == evidence.summary.visits, "Abandonment retains boundary HP and visits without zeroing health or inventing completion.")
	store.failure_point = point
	var failed: Dictionary = store.commit(intended, revision)
	check(not failed.ok, "Injected " + point + " failure rejects the terminal write.")
	check(subject == old_owner and subject.current_battle() == old_combat and subject.snapshot() == live_before, "Failure retains exact previous owner and live Combat objects/state.")
	check(FileAccess.get_file_as_bytes(store.path) == disk_before, "Failure leaves previous durable bytes identical.")
	check(var_to_bytes(payload(candidate)) == identical, "Failure retains the identical in-memory Retry candidate and receipts.")
	if mode == "retry":
		store.failure_point = ""
		var saved: Dictionary = store.commit(intended, revision)
		check(saved.ok and var_to_bytes(payload(candidate)) == identical, "Same-process Retry writes the exact candidate without regeneration.")
		if saved.ok: _publish(candidate, saved)
	else:
		check(mode == "restart" and payload(subject) == evidence.baseline, "Process exits with uncommitted intent discarded and prior owners intact.")
	check(Settings.load_values(directory.path_join("settings.cfg")) == evidence.settings, "Ending/replacement preserves persisted Options.")

func _restart_check() -> void:
	var expected: Dictionary = evidence.intended if mode == "retry" else evidence.baseline
	check(payload(subject) == expected, "Fresh process restores exactly " + ("the retried durable candidate." if mode == "retry" else "the last checkpoint; failed intent does not survive."))
	check(Settings.load_values(directory.path_join("settings.cfg")) == evidence.settings, "Fresh process retains persisted settings.")
	if operation == "guardian-choice" and mode == "retry":
		check(evidence.final_award in subject.profile_state().snapshot().unlocked_definition_ids and subject.snapshot().owned_cards == evidence.baseline.run.owned_cards, "Final permanent choice unlocks its exact definition without awarding a stored copy.")
	else: check(subject.profile_state().export_save() == evidence.baseline.profile, "Endings and replacement retain existing permanent unlock ownership.")
	if mode == "restart":
		if evidence.has("opening"):
			var replay: Dictionary = subject.continue_battle()
			check(replay.ok and replay.combat.snapshot() == evidence.opening, "Restart after failed outcome/abandonment replays exactly the durable entry.")
		return
	if operation == "replacement":
		check(subject.snapshot().run_id != evidence.baseline.run.run_id and subject.route_snapshot().visit_count == 0, "Confirmed replacement opens a new unvisited run.")
		check(subject.snapshot().relics.is_empty() and subject.snapshot().owned_cards.all(func(card): return card.upgrade_rank == 0), "Replacement resets only run-owned relics and ranks.")
		return
	if operation == "guardian-outcome":
		check(not subject.snapshot().is_terminal and subject.snapshot().status == "result_pending" and not subject.pending_reward().is_empty(), "Committed guardian victory restores pending choices before final completion.")
		check(not subject.abandonment_request().ok and not subject.continue_battle().ok, "Guardian pending result cannot be abandoned or replayed.")
		check(subject.run_summary().defeated_enemy_count == 6 and subject.route_snapshot().visit_count == 9, "Summary counts each real battle visit, including repeated encounter definitions.")
		return
	var before := payload(subject)
	check(subject.snapshot().is_terminal and not subject.continue_battle().ok, "Terminal checkpoint cannot resume gameplay.")
	check(not subject.abandonment_request().ok and not subject.abandon_run(evidence.get("abandon_token", {})).ok, "Ended runs reject repeated or reclassified abandonment.")
	check(not subject.request_room_entry("d1a").ok and not subject.confirm_room_entry({}).ok, "Terminal checkpoint cannot enter any room.")
	for record in subject.snapshot().reward_records:
		check(not subject.choose_reward(record.identity, str(record.chosen_id)).ok and not subject.skip_reward(record.identity).ok and not subject.claim_reward_gold(record.identity).ok, "Terminal review cannot claim a historical reward again.")
	var shop: Dictionary = subject.shop_snapshot()
	if not shop.is_empty():
		check(not subject.buy_shop_relic(shop.identity).ok and not subject.upgrade_shop_rune(shop.identity, 0).ok and not subject.leave_shop(shop.identity).ok, "Abandoned active shop rejects all later transactions and Leave.")
	if operation in ["final-ack", "victory-final-ack"]: check(not subject.acknowledge_final_result(subject.snapshot().terminal.identity), "Persisted final acknowledgement cannot repeat.")
	check(payload(subject) == before, "Read-only review and rejected callbacks change no resources or receipts.")
	check(subject.run_summary().owned_cards.size() == subject.snapshot().owned_cards.size(), "Final collection contains only authoritative owned instances.")

func _run_stage() -> void:
	if stage == "prepare": _prepare()
	elif subject == null: check(false, "Transaction stages require a durable baseline.")
	elif stage == "fail": _exercise_failure()
	elif stage == "restart": _restart_check()
	else: check(false, "Unknown process stage.")
