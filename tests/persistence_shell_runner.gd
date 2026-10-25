extends SceneTree
## RC-028 actual configured-root persistence UI and transaction failure checks.
const Shell = preload("res://tests/helpers/encounter_failure_shell.gd")
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const LocalSave = preload("res://scripts/core/local_save.gd")
const DESTINATION := "res://output/qa/rc-028/shell-persistence"
var checks := 0
var failures := 0
var assertions: Array = []
var _capture := false

func _initialize() -> void:
	_capture = "--capture-persistence" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 8: await process_frame
	if _capture: await RenderingServer.frame_post_draw

func _new_shell(path: String, context: Dictionary = {}) -> Control:
	var app := Shell.new()
	app.save_path = path
	app.settings_path = path + ".settings.cfg"
	app.persistence_context = context
	var values: Dictionary = Settings.DEFAULTS.duplicate(true)
	values.reduced_motion = true
	Settings.save_values(values, app.settings_path)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return app

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(720, 1600), "Configured root stretch and logical dimensions remain unchanged.")
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await _home_and_recovery(dimensions)
	root.size = Vector2i(450, 1000)
	await settle()
	await _gameplay_failures()
	await _unlock_failure()
	var report := {"checks": checks, "failures": failures, "assertions": assertions,
		"scope": "Isolated real file commits and actual configured root Window. Failures cover temporary write, flush, close, backup and promotion; detached candidate ownership, attachment, terminal audio, reward and acknowledgement retries. Captures preserve canvas_items stretch and narrow letterboxing; no physical-device acceptance."}
	FileAccess.open(DESTINATION.path_join("results-capture.json" if _capture else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-028 persistence shell checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _home_and_recovery(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var path := DESTINATION.path_join("home-" + tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var app := _new_shell(path)
	await settle()
	check(app.run_state == null and app.continue_button.disabled and not app.new_run_button.disabled, tag + " Empty Home explains unavailable Continue and permits New Run.")
	await capture(app, "home-empty-" + tag)
	app.request_new_run(42)
	await settle()
	check(app.map_screen != null and app.run_state != null and FileAccess.file_exists(path), tag + " New Run saves before opening Map.")
	if app.run_state == null:
		app.queue_free()
		await settle()
		return
	app.close_map()
	await settle()
	var original = app.run_state
	var snapshot: Dictionary = original.export_save()
	var file_before := FileAccess.get_file_as_string(path)
	await capture(app, "home-saved-" + tag)
	app.request_new_run(43)
	await settle()
	await capture(app, "replacement-confirmation-" + tag)
	app.cancel_confirmation()
	check(app.run_state == original and original.export_save() == snapshot and FileAccess.get_file_as_string(path) == file_before, tag + " Replacement cancellation preserves the exact original run, profile and disk file.")
	var previous_id := ""
	for fault in ["write", "flush", "close", "backup", "replace"]:
		original = app.run_state
		snapshot = original.export_save()
		var profile_before: Dictionary = app.progression.export_save()
		file_before = FileAccess.get_file_as_string(path)
		previous_id = str(snapshot.run_id)
		app.save_store.failure_point = fault
		app.request_new_run(50 + checks)
		app.confirm_new_run()
		await settle()
		check(app.run_state == original and original.export_save() == snapshot and app.progression.export_save() == profile_before and FileAccess.get_file_as_string(path) == file_before, tag + " Failed replacement at " + fault + " preserves all owners and last committed bytes.")
		check(app.confirmation.visible and app.confirmation_confirm.text == "Retry saving" and app._failed_transaction.action == "new_run", tag + " Failed " + fault + " exposes truthful Retry for the retained replacement.")
		var intended_id: String = app._failed_transaction.candidate.export_save().run_id
		if fault == "replace": await capture(app, "save-failure-" + tag)
		app.save_store.failure_point = ""
		app.retry_save()
		await settle()
		check(app.run_state.export_save().run_id == intended_id and app.run_state != original and app._failed_transaction.is_empty() and app.map_screen != null, tag + " Retry " + fault + " publishes the same replacement exactly once after saving.")
		app.close_map()
		await settle()
	var current_id: String = app.run_state.export_save().run_id
	app.queue_free()
	await settle()
	app = _new_shell(path)
	await settle()
	check(app.run_state != null and app.run_state.export_save().run_id == current_id and not app.continue_button.disabled, tag + " A new shell owner reads the same committed run from disk.")
	app.queue_free()
	await settle()
	var unreadable := "{\"truncated\":"
	FileAccess.open(path, FileAccess.WRITE).store_string(unreadable)
	app = _new_shell(path)
	await settle()
	check(app.run_state == null and app._save_status == "invalid" and app.continue_button.disabled and app.new_run_button.disabled and app.recovery_button.visible and FileAccess.get_file_as_string(path) == unreadable, tag + " Truncated save remains intact; Home blocks implicit replacement and exposes recovery.")
	await capture(app, "home-invalid-" + tag)
	app.open_save_recovery()
	await settle()
	check(app._recovery_available and app.confirmation_confirm.text == "Recover previous save" and app.recovery_retry_button.visible, tag + " Recovery offers only its validated previous copy plus Retry loading.")
	await capture(app, "recovery-confirmation-" + tag)
	app.recover_previous_save()
	await settle()
	check(app.run_state != null and app.run_state.export_save().run_id == previous_id and not app.continue_button.disabled and not app.recovery_button.visible, tag + " Explicit recovery restores the validated previous run and normal Continue.")
	var preserved := false
	for file in DirAccess.get_files_at(path.get_base_dir()):
		if file.begins_with(path.get_file() + ".unreadable-") and FileAccess.get_file_as_string(path.get_base_dir().path_join(file)) == unreadable: preserved = true
	check(preserved, tag + " Recovery preserves the original unreadable bytes under a diagnosis filename.")
	await capture(app, "home-recovered-" + tag)
	app.queue_free()
	await settle()

func _gameplay_failures() -> void:
	var path := DESTINATION.path_join("gameplay-" + str(Time.get_ticks_usec()) + ".json")
	var app := _new_shell(path)
	app.run_state = Fixture.new_run(42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	var run = app.run_state
	var initial: Dictionary = run.export_save()
	var first: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.fail_next_scene = true
	app.request_node_entry(first)
	app.confirm_node_entry()
	check(run.export_save() == initial and app.combat_scene == null and not FileAccess.file_exists(path), "Failed scene construction consumes neither visit nor save checkpoint.")
	app.save_store.failure_point = "write"
	app.request_node_entry(first)
	app.confirm_node_entry()
	await settle()
	check(run.export_save() == initial and app.combat_scene == null and app._failed_transaction.action == "entry", "Entry write failure disposes the hidden candidate scene and leaves route ownership unchanged.")
	var prepared_identity: Dictionary = app._failed_transaction.candidate.snapshot().active_battle
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(app.combat_scene != null and run.route_snapshot().visit_count == 1 and run.snapshot().active_battle == prepared_identity, "Entry Retry attaches and saves the same single visit and prepared battle identity.")
	if app.combat_scene == null:
		app.queue_free()
		await settle()
		return
	var original_opening: Dictionary = app.combat_scene.controller.snapshot()
	var context: Dictionary = app.persistence_context
	app.queue_free()
	await settle()
	app = _new_shell(path, context)
	await settle()
	run = app.run_state
	var restored_entry: Dictionary = run.export_save()
	app.reject_attached_scene = true
	app.continue_run()
	await settle()
	check(app.combat_scene == null and run.export_save() == restored_entry and run.route_snapshot().visit_count == 1, "A failed scene attachment after restore preserves the exact checkpoint and does not consume another visit.")
	app.continue_run()
	await settle()
	check(app.combat_scene != null and app.combat_scene.controller.snapshot() == original_opening and run.route_snapshot().visit_count == 1, "Retry after failed restored attachment opens the saved battle entry with the same cards, HP and RNG.")
	var scene: Control = app.combat_scene
	var controller = scene.controller
	controller.set_presenter(Immediate.new())
	scene.audio.trace_enabled = true
	var entry_export: Dictionary = run.export_save()
	var entry_file := FileAccess.get_file_as_string(path)
	app.save_store.failure_point = "replace"
	var player := Player.new()
	for turn in 40:
		if controller.snapshot().state != "playing": break
		check(player.play_turn(controller), "Ordinary Combat action reaches terminal persistence boundary, turn %d." % turn)
	await settle()
	check(controller.snapshot().state == "victory" and app._failed_transaction.get("action") == "outcome", "A real victory waits for the failed durable outcome transaction.")
	check(run.export_save() == entry_export and FileAccess.get_file_as_string(path) == entry_file and run.pending_reward().is_empty(), "Failed outcome preserves the battle entry file and publishes no offer, grant or successor.")
	check(_cue_count(scene.audio, "victory") == 0 and _cue_count(scene.audio, "reward") == 0, "Failed terminal persistence produces no victory or acquisition success audio.")
	var intended: Dictionary = app._failed_transaction.candidate.pending_reward()
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.snapshot().status == "result_pending" and run.pending_reward() == intended and app.confirmation.visible, "Outcome Retry publishes its same retained offer and pending result without replaying battle.")
	check(_cue_count(scene.audio, "victory") == 1, "Successful outcome Retry plays one committed victory cue.")
	app.open_rewards()
	await settle()
	var identity: Dictionary = intended.identity
	var chosen: String = intended.offered_ids[0]
	var reward_before: Dictionary = run.export_save()
	var original_profile = run.profile_state()
	var profile_before: Dictionary = original_profile.export_save()
	app.save_store.failure_point = "close"
	app._choose_reward(identity, chosen)
	await settle()
	check(run.export_save() == reward_before and run.profile_state() == original_profile and original_profile.export_save() == profile_before and _cue_count(scene.audio, "reward") == 0, "Failed Choose retains cards, allocator, profile, receipt and route lock without success audio.")
	var intended_uid: int = app._failed_transaction.candidate.reward_snapshot(identity).granted_uid
	var reentrant := [0]
	scene.audio.cue_started.connect(func(record: Dictionary):
		if record.get("cue") != "reward": return
		reentrant[0] += 1
		app._claim_reward_gold(identity)
		app._choose_reward(identity, chosen))
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.reward_snapshot(identity).granted_uid == intended_uid and run.snapshot().owned_cards.size() == 9 and run.snapshot().next_uid == intended_uid + 1 and _cue_count(scene.audio, "reward") == 1, "Choose Retry publishes exactly one owned UID and allocator advance, then one acquisition cue.")
	check(reentrant[0] == 1 and run.snapshot().gold == 0, "Reentrant reward-audio callbacks cannot claim Gold or repeat Choose during durable publication.")
	check(app.reward_screen.visible and app.confirmation.visible, "Reward Retry preserves result review beneath the reopened reward flow.")
	var chosen_before: Dictionary = run.export_save()
	app.save_store.failure_point = "flush"
	app._claim_reward_gold(identity)
	await settle()
	check(run.export_save() == chosen_before and run.snapshot().gold == 0 and _cue_count(scene.audio, "reward") == 1, "Failed independent Gold claim preserves already claimed rune and unresolved Gold without extra audio.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.snapshot().gold == 7 and run.snapshot().owned_cards.size() == 9 and run.reward_snapshot(identity).status == "resolved" and _cue_count(scene.audio, "reward") == 2, "Gold Retry retains the rune and publishes exactly one Gold receipt and success cue.")
	app.close_rewards()
	var before_ack: Dictionary = run.export_save()
	var stale_terminal: Callable = app._battle_changed_callback
	app.save_store.failure_point = "backup"
	app.acknowledge_encounter_result()
	await settle()
	check(run.export_save() == before_ack and app.combat_scene == scene and run.snapshot().status == "result_pending", "Failed acknowledgement retains the pending result and live scene, despite completed route choices.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.snapshot().status == "route_ready" and app.combat_scene == null and app.map_screen != null and run.snapshot().owned_cards.size() == 9, "Acknowledgement Retry retires the resolved scene and exposes successors without another grant.")
	var completed: Dictionary = run.export_save()
	stale_terminal.call()
	app._choose_reward(identity, chosen)
	app._claim_reward_gold(identity)
	check(run.export_save() == completed, "Retired terminal and stale reward callbacks cannot overwrite or repeat a committed transaction.")
	app.queue_free()
	await settle()

func _unlock_failure() -> void:
	var path := DESTINATION.path_join("unlock-" + str(Time.get_ticks_usec()) + ".json")
	var app := _new_shell(path)
	var profile = preload("res://scripts/core/progression_state.gd").new(preload("res://scripts/core/content_loader.gd").load_setup().setup.catalog, ["spark"])
	var fixture = preload("res://tests/reward_state_tests.gd").new()
	var run = fixture._boss_run(profile)
	check(fixture.win(run) != null, "Explicit narrowed-profile fixture earns its genuine Shadeling milestone through ordinary battle actions.")
	app.run_state = run
	app.progression = profile
	app.persistence_context = run.restore_context_for_tests()
	check(app._persist_candidate(run).ok, "Fixture milestone outcome is committed before testing its permanent acquisition.")
	app.continue_run()
	app.open_rewards()
	var run_reward: Dictionary = run.pending_reward()
	app._skip_reward(run_reward.identity)
	await settle()
	var offer: Dictionary = run.pending_reward()
	check(offer.kind == "definition_unlock" and offer.offered_ids.size() == 1 and not offer.offered_ids[0] in profile.snapshot().unlocked_definition_ids, "Fixture exposes a genuine still-locked definition without changing the starter.")
	app.audio.trace_enabled = true
	var before: Dictionary = run.export_save()
	var profile_before: Dictionary = profile.export_save()
	var bytes_before := FileAccess.get_file_as_string(path)
	app.save_store.failure_point = "replace"
	app._choose_reward(offer.identity, offer.offered_ids[0])
	await settle()
	check(run.export_save() == before and profile.export_save() == profile_before and FileAccess.get_file_as_string(path) == bytes_before and _cue_count(app.audio, "reward") == 0, "Failed permanent acquisition changes neither profile nor run, receipt, route lock or file, and emits no acquisition audio.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.profile_state() == profile and profile.snapshot().unlocked_definition_ids.size() == 2 and offer.offered_ids[0] in profile.snapshot().unlocked_definition_ids and run.snapshot().owned_cards == before.owned_cards and run.snapshot().next_uid == before.next_uid and _cue_count(app.audio, "reward") == 1, "Permanent Retry adds exactly one definition to the same profile owner, with no card or UID allocation and one acquisition cue.")
	app.queue_free()
	await settle()

func _cue_count(owner: Node, cue: String) -> int:
	return owner.trace.filter(func(record): return record.get("cue") == cue).size()

func capture(app: Control, name: String) -> void:
	if not _capture: return
	await settle()
	var visible_buttons := [app.continue_button, app.new_run_button, app.options_button, app.recovery_button]
	if app.confirmation.visible: visible_buttons = [app.confirmation_confirm, app.confirmation_cancel, app.recovery_retry_button]
	var bounds := root.get_final_transform() * root.get_visible_rect()
	for button in visible_buttons:
		if button.is_visible_in_tree(): check(bounds.encloses(root.get_final_transform() * button.get_global_rect()), name + " keeps " + button.text + " inside the configured content viewport.")
	check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + " root render PNG saved.")
