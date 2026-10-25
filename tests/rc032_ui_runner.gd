extends SceneTree
## Actual configured-window lifecycle and failure checks. All saves/settings
## stay under excluded RC-032 evidence; Combat uses legal controller commands.
const Shell = preload("res://scripts/ui/application_shell.gd")
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const ItemFixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const DESTINATION := "res://output/qa/rc-032/ui"
var checks := 0
var failures := 0
var assertions: Array = []
var capturing := false

func _initialize() -> void:
	capturing = "--capture-rc032" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 8: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func create_shell(path: String, context: Dictionary = {}) -> Control:
	var app := Shell.new()
	app.save_path = path
	app.settings_path = path + ".settings.cfg"
	app.persistence_context = context
	if not FileAccess.file_exists(app.settings_path):
		var values: Dictionary = Settings.DEFAULTS.duplicate(true)
		values.reduced_motion = true
		Settings.save_values(values, app.settings_path)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return app

func capture(app: Control, name: String) -> void:
	await settle()
	var panel: PanelContainer
	var actions: Array = []
	if app.confirmation.visible:
		panel = app._confirmation_panel
		actions = [app.confirmation_confirm, app.confirmation_cancel, app.recovery_retry_button]
	elif app.run_review.visible:
		panel = app.run_review.panel
		actions = [app.run_review.primary_button, app.run_review.secondary_button]
	var bounds := root.get_final_transform() * root.get_visible_rect()
	if panel != null:
		check(bounds.encloses(root.get_final_transform() * panel.get_global_rect()) and panel.size.y <= 660, name + ": popup fits the actual window and shared cap.")
	for action in actions:
		if action.is_visible_in_tree(): check(bounds.encloses(root.get_final_transform() * action.get_global_rect()), name + ": fixed " + action.text + " action remains reachable.")
	if capturing: check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + ": screenshot saved.")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		var tag := "%dx%d" % [dimensions.x, dimensions.y]
		await home_navigation(tag)
		for fault in ["write", "flush", "close", "backup", "replace"]: await abandon_live(tag, fault)
		for room in ["shop", "service"]: await abandon_active_room(tag, room)
		await defeat_review(tag)
	FileAccess.open(DESTINATION.path_join("results-capture.json" if capturing else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Actual 450x1000 and360x640 configured Windows; legal live Combat, durable abandonment/defeat/results/replacement and five failure points. Desktop Back simulation is not physical Android validation."}, "  ") + "\n")
	print("RC-032 lifecycle UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func home_navigation(tag: String) -> void:
	var path := DESTINATION.path_join("home-" + tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var app := create_shell(path)
	await settle()
	check(app.continue_button.disabled and app.home.visible, tag + ": fresh Home has no Continue.")
	app.open_options()
	app._change_option("reduced_motion", false)
	app.close_options()
	check(not Settings.load_values(app.settings_path).reduced_motion, tag + ": Home Options persist independently.")
	app.request_new_run(42)
	await settle()
	check(app.map_screen != null and app.run_state.route_snapshot().visit_count == 0, tag + ": New Run saves an unvisited map.")
	var before: Dictionary = app.run_state.export_save()
	app.map_screen.details_button.pressed.emit()
	await capture(app, "run-details-empty-" + tag)
	check(app.run_review.visible and app.run_review.presentation.entered_rooms == 0, tag + ": Map header opens committed run details.")
	var stale: Dictionary = app.run_review.identity.duplicate(true)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.run_review.visible and app.map_screen != null, tag + ": duplicate desktop Back closes details only.")
	app._review_action("abandon", stale)
	check(not app.confirmation.visible and app.run_state.export_save() == before, tag + ": stale details callback cannot abandon.")
	await settle()
	app.map_screen.menu_button.pressed.emit()
	app.route_menu_quit.pressed.emit()
	check(app.confirmation.visible and app.map_screen != null, tag + ": Menu Quit asks before returning Home.")
	app.cancel_confirmation()
	check(app.route_menu.visible and app.run_state.export_save() == before, tag + ": Quit cancellation restores the same shared Menu and run.")
	app.route_menu_options.pressed.emit()
	check(app.options.visible and not app.audio_settings.reduced_motion, tag + ": Menu opens the shared Options with persisted values.")
	app.close_options()
	app.route_menu_quit.pressed.emit()
	app.confirm_home()
	check(app.map_screen == null and app.home.visible and app.run_state.export_save() == before, tag + ": confirmed Quit keeps checkpoint and returns Home.")
	app.request_new_run(43)
	app.cancel_confirmation()
	check(app.run_state.export_save() == before, tag + ": New Run cancellation retains the prior run.")
	app.continue_run()
	check(app.map_screen != null and app.run_state.export_save() == before, tag + ": between-room Continue restores unchanged route.")
	app._return_home()
	check(app._persist_candidate(app.run_state).ok, tag + ": recovery setup creates a validated previous checkpoint.")
	app.queue_free()
	await settle()
	var unreadable := "{\"truncated\":"
	FileAccess.open(path, FileAccess.WRITE).store_string(unreadable)
	app = create_shell(path)
	await settle()
	check(app.run_state == null and app.new_run_button.disabled and app.recovery_button.visible and FileAccess.get_file_as_string(path) == unreadable, tag + ": invalid save blocks replacement and preserves damaged bytes.")
	app.open_save_recovery()
	await capture(app, "save-recovery-" + tag)
	app.recover_previous_save()
	check(app.run_state != null and app.run_state.export_save() == before, tag + ": explicit recovery restores only a validated previous copy.")
	var preserved := false
	for file in DirAccess.get_files_at(path.get_base_dir()):
		if file.begins_with(path.get_file() + ".unreadable-") and FileAccess.get_file_as_string(path.get_base_dir().path_join(file)) == unreadable: preserved = true
	check(preserved, tag + ": successful recovery retains the original damaged file for diagnosis.")
	app.queue_free()
	await settle()

func abandon_live(tag: String, fault: String) -> void:
	var path := DESTINATION.path_join("abandon-" + tag + "-" + fault + "-" + str(Time.get_ticks_usec()) + ".json")
	var subject = Fixture.new_run()
	var context: Dictionary = Fixture.context_for(subject)
	var app := create_shell(path, context)
	await settle()
	app._commit_transaction(subject, "new_run")
	app.request_node_entry(Fixture.next_node(subject))
	app.confirm_node_entry()
	await settle()
	check(app.combat_scene != null, tag + fault + ": real battle entered before abandonment.")
	if app.combat_scene == null:
		app.queue_free()
		await settle()
		return
	var scene: Control = app.combat_scene
	scene.controller.set_presenter(Immediate.new())
	var opening: Dictionary = scene.controller.snapshot()
	var player := Player.new()
	check(not player.prepare(scene.controller).is_empty(), tag + fault + ": live preparation uses legal actions.")
	var prepared: Dictionary = scene.controller.snapshot()
	var prior: Dictionary = subject.export_save()
	var bytes := FileAccess.get_file_as_string(path)
	app.open_map()
	app.map_screen.details_button.pressed.emit()
	check(app.run_review.visible and app.run_review.presentation.entered_rooms == 1 and app.run_review.presentation.completed_rooms == 0, tag + fault + ": active visit stays entered, not completed.")
	if fault == "replace": await capture(app, "run-details-live-" + tag)
	app.run_review.secondary_button.pressed.emit()
	if fault == "replace": await capture(app, "abandon-confirmation-" + tag)
	app.cancel_confirmation()
	check(app.run_review.visible and app.combat_scene == scene and scene.controller.snapshot() == prepared and subject.export_save() == prior, tag + fault + ": cancellation preserves live scene and committed history.")
	app.run_review.primary_button.pressed.emit()
	app.map_screen.resume_button.pressed.emit()
	check(app.combat_scene == scene and scene.controller.snapshot() == prepared and app.map_screen == null, tag + fault + ": live Map Resume preserves exact preparation.")
	app.open_map()
	app.map_screen.details_button.pressed.emit()
	var stale: Dictionary = app.run_review.identity.duplicate(true)
	app.run_review.secondary_button.pressed.emit()
	app.save_store.failure_point = fault
	app.confirm_abandon()
	check(not app._failed_transaction.is_empty() and app._failed_transaction.action == "abandon", tag + fault + ": failed ending retains Retry candidate.")
	check(subject.export_save() == prior and app.combat_scene == scene and scene.controller.snapshot() == prepared and FileAccess.get_file_as_string(path) == bytes, tag + fault + ": failed write preserves prior owners, live scene and durable bytes.")
	if app._failed_transaction.is_empty():
		app.queue_free()
		await settle()
		return
	var intended: Dictionary = app._failed_transaction.candidate.export_save()
	app.confirm_abandon()
	app._review_action("abandon", stale)
	check(app._failed_transaction.candidate.export_save() == intended, tag + fault + ": duplicate/stale confirmation cannot replace pending intent.")
	if fault == "replace": await capture(app, "abandon-save-failure-" + tag)
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(subject.export_save() == intended and subject.snapshot().status == "abandoned" and app.combat_scene == null and app.map_screen == null and app.home.visible, tag + fault + ": identical Retry saves before disposing scenes and returning Home.")
	check(subject.snapshot().player_hp == opening.player_hp and subject.run_summary().completed_rooms == 0 and subject.run_summary().defeated_enemy_count == 0, tag + fault + ": abandonment uses the entry boundary without defeat or fabricated victories.")
	app._review_action("abandon", stale)
	app.confirm_abandon()
	check(subject.export_save() == intended and app.continue_button.text == "View results", tag + fault + ": terminal callbacks reject and Home exposes review.")
	app.continue_run()
	if fault == "replace": await capture(app, "abandoned-results-" + tag)
	check(app.run_review.visible and app.run_review.final_review and app.combat_scene == null, tag + fault + ": terminal Continue opens only read-only results.")
	app.run_review.secondary_button.pressed.emit()
	var final_save: Dictionary = subject.export_save()
	app.queue_free()
	await settle()
	app = create_shell(path, context)
	await settle()
	check(app.run_state != null and app.run_state.export_save() == final_save, tag + fault + ": new shell restores exact abandoned record.")
	app.continue_run()
	check(app.run_review.visible and app.run_state.run_summary().outcome == "abandoned", tag + fault + ": reopening never resumes abandoned gameplay.")
	app.queue_free()
	await settle()

func abandon_active_room(tag: String, room: String) -> void:
	var path := DESTINATION.path_join("abandon-room-" + room + "-" + tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var specimen := "ranked-relic-shop-v4" if room == "shop" else "active-reliquary-v4"
	check(DirAccess.copy_absolute("res://tests/fixtures/rc031/" + specimen + ".json", path) == OK, tag + room + ": uses an unchanged genuine active-room predecessor.")
	var context: Dictionary = ItemFixture.context_for(ItemFixture.new_run(15))
	var app := create_shell(path, context)
	await settle()
	check(app.run_state != null and app.run_state.snapshot().status == "room_active", tag + room + ": historical active room restores and migrates successfully.")
	if app.run_state == null:
		app.queue_free()
		await settle()
		return
	app.continue_run()
	await settle()
	check(app.shop_screen != null if room == "shop" else app.service_screen != null, tag + room + ": ordinary Continue still opens the supported active room.")
	app.open_map()
	app.map_screen.details_button.pressed.emit()
	app.run_review.secondary_button.pressed.emit()
	app.confirm_abandon()
	await settle()
	var terminal: Dictionary = app.run_state.export_save()
	check(app.run_state.snapshot().is_terminal and app.home.visible and app.shop_screen == null and app.service_screen == null, tag + room + ": durable abandonment disposes its active room before Home.")
	app._open_saved_shop()
	app._open_saved_service()
	check(app.shop_screen == null and app.service_screen == null and not app.confirmation.visible and app.run_state.export_save() == terminal, tag + room + ": retained stale room-open callbacks cannot attach terminal gameplay or mutate history.")
	app.continue_run()
	app._open_saved_shop()
	app._open_saved_service()
	check(app.run_review.visible and app.run_review.final_review and app.shop_screen == null and app.service_screen == null, tag + room + ": terminal review retains exclusive input ownership against stale open callbacks.")
	app.queue_free()
	await settle()
	app = create_shell(path, context)
	await settle()
	app._open_saved_shop()
	app._open_saved_service()
	check(app.run_state.export_save() == terminal and app.shop_screen == null and app.service_screen == null, tag + room + ": restored terminal history cannot reopen its historically active room.")
	app.continue_run()
	check(app.run_review.visible and app.run_review.presentation.outcome == "abandoned", tag + room + ": restarted Continue opens only abandoned results.")
	app.queue_free()
	await settle()

func defeat_review(tag: String) -> void:
	var path := DESTINATION.path_join("defeat-" + tag + "-" + str(Time.get_ticks_usec()) + ".json")
	# This flow replaces the fixture with the ordinary production New Run;
	# use the genuine production initial-unlock profile for that transition.
	var subject = Fixture.new_run(42, true)
	var context: Dictionary = Fixture.context_for(subject)
	var app := create_shell(path, context)
	await settle()
	app._commit_transaction(subject, "new_run")
	app.request_node_entry(Fixture.next_node(subject))
	app.confirm_node_entry()
	await settle()
	if app.combat_scene == null:
		check(false, tag + ": defeat battle entry succeeds.")
		app.queue_free()
		await settle()
		return
	var controller = app.combat_scene.controller
	controller.set_presenter(Immediate.new())
	for turn in 40:
		if controller.snapshot().state != "playing": break
		check(controller.command("pass"), tag + ": defeat follows a legal Pass.")
	check(subject.snapshot().status == "result_pending" and subject.snapshot().terminal.outcome == "defeat", tag + ": committed defeat is terminal while result acknowledgement remains separate.")
	check(subject.pending_reward().is_empty() and subject.run_summary().permanent_awards.is_empty(), tag + ": defeat fabricates no rewards or rescue.")
	app.cancel_confirmation()
	app.continue_run()
	check(app.confirmation.visible and app._pending_action == "encounter_result", tag + ": Home/Continue preserves pending defeat result.")
	app.acknowledge_encounter_result()
	await capture(app, "defeat-results-" + tag)
	check(app.run_review.visible and app.map_screen == null, tag + ": defeat acknowledgement opens final results, never dead-end Map.")
	var settled: Dictionary = subject.export_save()
	app.save_store.failure_point = "replace"
	app.run_review.secondary_button.pressed.emit()
	check(subject.export_save() == settled and app._failed_transaction.get("action") == "final_home", tag + ": failed final acknowledgement preserves prior terminal owner.")
	await capture(app, "results-save-failure-" + tag)
	var candidate: Dictionary = app._failed_transaction.candidate.export_save()
	app.save_store.failure_point = ""
	app.retry_save()
	check(subject.export_save() == candidate and app.home.visible and not app.run_review.visible, tag + ": final acknowledgement Retry grants nothing and returns Home.")
	app.continue_run()
	app.run_review.primary_button.pressed.emit()
	app.cancel_confirmation()
	check(app.run_review.visible and subject.export_save() == candidate, tag + ": New Run cancellation returns to unchanged final review.")
	app.run_review.primary_button.pressed.emit()
	app.save_store.failure_point = "replace"
	app.confirm_new_run()
	check(app.run_state == subject and subject.export_save() == candidate and app._failed_transaction.get("action") == "new_run", tag + ": failed replacement preserves final run.")
	var replacement: Dictionary = app._failed_transaction.candidate.export_save()
	var profile: Dictionary = app.progression.export_save()
	var settings: Dictionary = Settings.load_values(app.settings_path)
	app.save_store.failure_point = ""
	app.retry_save()
	if not (app.run_state != subject and app.run_state.export_save() == replacement and app.map_screen != null and not app.run_review.visible):
		print("RC032 replacement diagnostic ", {"different_owner": app.run_state != subject, "same_candidate": app.run_state.export_save() == replacement, "map": app.map_screen != null, "review": app.run_review.visible, "failure": app._failed_transaction.get("error", ""), "status": app.run_state.snapshot().status, "confirmation": app._pending_action})
	check(app.run_state != subject and app.run_state.export_save() == replacement and app.map_screen != null and not app.run_review.visible, tag + ": replacement opens fresh Map only after saving the identical candidate.")
	check(app.progression.export_save() == profile and Settings.load_values(app.settings_path) == settings, tag + ": replacement preserves permanent unlocks and Options.")
	app.queue_free()
	await settle()
