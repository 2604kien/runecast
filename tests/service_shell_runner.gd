extends SceneTree
## Real configured-root service lifecycle; presenter-only boundary states are
## named explicitly and never written into an authoritative run or save.
const Fixture = preload("res://tests/helpers/service_route_fixture.gd")
const Policy = preload("res://scripts/core/service_policy.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const Ui = preload("res://scenes/ui/theme/components.gd")
const DESTINATION := "res://output/qa/rc-030/shell"
var checks := 0
var failures := 0
var assertions: Array = []
var _capture := false

class CheckShell extends "res://scripts/ui/application_shell.gd":
	var fail_service_scene_once := false
	func _create_service_scene() -> Control:
		if fail_service_scene_once:
			fail_service_scene_once = false
			return null
		return super._create_service_scene()

func _initialize() -> void:
	_capture = "--capture-service" in OS.get_cmdline_user_args()
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

func new_shell(path: String, context: Dictionary) -> Control:
	var app := CheckShell.new()
	app.settings_path = path + ".settings.cfg"
	app.save_path = path
	app.persistence_context = context
	var values: Dictionary = Settings.DEFAULTS.duplicate(true)
	values.reduced_motion = true
	Settings.save_values(values, app.settings_path)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.audio.trace_enabled = true
	return app

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(720, 1600), "Services preserve the configured logical canvas and stretch.")
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		for variant in ["recovery", "satchel", "tithe", "reliquary", "desk"]:
			await exercise(dimensions, variant)
	FileAccess.open(DESTINATION.path_join("results-capture.json" if _capture else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Actual configured-root Window at 450x1000 and 360x640; genuine Wisp damage, service entry/resolution and persisted restart. Full-health and 8-HP Tithe captures are detached presentation specimens; the 6-HP Tithe rejection follows a genuine second battle. No physical-device acceptance."}, "  ") + "\n")
	print("RC-030 service shell: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func exercise(dimensions: Vector2i, variant: String) -> void:
	var tag := "%s-%dx%d" % [variant, dimensions.x, dimensions.y]
	var path := DESTINATION.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var run = Fixture.new_run(42, variant)
	var won: Dictionary = Fixture.win_battle(run)
	check(won.get("ok", false), tag + " reaches service through a genuine completed battle: " + str(won.get("error", "")))
	if not won.get("ok", false): return
	var context: Dictionary = Fixture.context_for(run)
	var app := new_shell(path, context)
	await settle()
	app.run_state = run
	app.progression = run.profile_state()
	var persisted: Dictionary = app._persist_candidate(run)
	check(persisted.get("ok", false), tag + " persists real battle health before service entry: " + str(persisted.get("error", "")))
	if not persisted.get("ok", false):
		app.queue_free()
		await settle()
		return
	app.continue_run()
	await settle()
	var node_id: String = Fixture.next_node(run)
	var before_entry: Dictionary = run.export_save()
	app.request_node_entry(node_id)
	app.cancel_confirmation()
	check(run.export_save() == before_entry and app.service_screen == null, tag + " canceled entry consumes no visit.")
	if variant == "recovery":
		app.fail_service_scene_once = true
		app.request_node_entry(node_id)
		app.confirm_node_entry()
		check(run.export_save() == before_entry and app.service_screen == null, tag + " scene preparation failure cannot consume the visit.")
	app.request_node_entry(node_id)
	if variant == "recovery": app.save_store.failure_point = "replace"
	app.confirm_node_entry()
	await settle()
	if variant == "recovery":
		check(run.export_save() == before_entry and app.service_screen == null and app._failed_transaction.get("action") == "service_entry", tag + " failed durable entry preserves the route and unopened service.")
		if app._failed_transaction.is_empty():
			app.queue_free()
			await settle()
			return
		var entry_candidate: Dictionary = app._failed_transaction.candidate.export_save()
		await capture(app, "entry-save-failure-" + tag)
		app.save_store.failure_point = ""
		app.retry_save()
		await settle()
		check(run.export_save() == entry_candidate, tag + " entry Retry publishes the identical prepared visit.")
	check(app.service_screen != null and app.map_screen == null and app.combat_scene == null, tag + " service opens as the active screen.")
	if app.service_screen == null:
		app.queue_free()
		await settle()
		return
	var viewer: Control = app.service_screen
	var record: Dictionary = run.service_snapshot()
	var identity: Dictionary = record.identity
	var original: Dictionary = run.export_save()
	var initial_hp: int = run.snapshot().player_hp
	var initial_gold: int = run.snapshot().gold
	var choice: String = {"recovery": "recover", "satchel": "take_gold", "tithe": "blood_tithe", "reliquary": "leave", "desk": "leave"}[variant]
	check(viewer.presentation.definition_id == record.definition_id and not viewer.leave_button.disabled, tag + " preserves assigned identity and an enabled free Leave.")
	await capture(app, "choices-" + tag)
	if variant in ["reliquary", "desk"]:
		var gated: String = "open_reliquary" if variant == "reliquary" else "refine_rune"
		viewer.select_choice(gated)
		if variant == "reliquary":
			check(viewer.choice_buttons[gated].disabled and not viewer.inspection.visible and run.export_save() == original, tag + " unfunded reliquary stays disabled without consuming the room.")
		else:
			check(not viewer.choice_buttons[gated].disabled and viewer.inspection.visible and run.export_save() == original, tag + " supported Desk opens exact-copy selection without consuming the room.")
			viewer.dismiss_top()
	viewer.select_choice(choice)
	await settle()
	check(viewer.inspection.visible and viewer.modal_body.text.contains("Health") and viewer.modal_body.text.contains("Gold"), tag + " confirmation displays consequences before applying them.")
	if variant == "recovery": check(viewer.modal_body.text.contains("%d to 30" % initial_hp), tag + " capped recovery previews the authoritative current-to-maximum gain.")
	await capture(app, "confirm-" + tag)
	viewer.dismiss_top()
	viewer.confirm_choice()
	check(run.export_save() == original and not viewer.inspection.visible, tag + " Back and canceled confirmation never resolve or choose Leave.")
	if variant == "recovery":
		await navigation(app, tag, original)
		await presenter_boundary(app, record, 30, "presenter-full-health-" + tag)
	elif variant == "tithe":
		await presenter_boundary(app, record, 8, "presenter-insufficient-tithe-" + tag)
	var original_generation: int = app._generation
	app._return_home()
	await settle()
	check(app.service_screen == null and run.export_save() == original, tag + " Quit to Home retains the unresolved room.")
	if variant == "recovery": app.fail_service_scene_once = true
	app.continue_run()
	if variant == "recovery":
		check(app.service_screen == null and app._pending_action == "retry_service_open" and run.export_save() == original, tag + " saved-screen preparation failure keeps the unresolved visit intact.")
		app._confirm_pending()
	await settle()
	check(app.service_screen != null and run.export_save() == original, tag + " Continue reopens the same unresolved room without reroll or effect.")
	app._service_choice_requested(identity, choice, original_generation)
	check(run.export_save() == original, tag + " stale prior-screen callback cannot resolve a reopened visit.")
	app.queue_free()
	await settle()
	app = new_shell(path, context)
	await settle()
	run = app.run_state
	check(run != null and run.export_save() == original and cue_count(app.audio) == 0, tag + " restored active visit is exact and silent.")
	if run == null:
		app.queue_free()
		await settle()
		return
	app.continue_run()
	await settle()
	viewer = app.service_screen
	if viewer == null:
		check(false, tag + " restored service screen failed.")
		app.queue_free()
		await settle()
		return
	var old_generation: int = app._generation
	viewer.select_choice(choice)
	var cues_before := cue_count(app.audio)
	if variant in ["recovery", "tithe", "reliquary"]: app.save_store.failure_point = "flush"
	viewer.confirm_choice()
	await settle()
	if variant in ["recovery", "tithe", "reliquary"]:
		check(run.export_save() == original and app.confirmation.visible and cue_count(app.audio) == cues_before, tag + " failed resolution preserves HP/Gold, route and silence.")
		await capture(app, "resolution-save-failure-" + tag)
		var intended: Dictionary = app._failed_transaction.candidate.export_save()
		app._resolve_service_choice(identity, "leave")
		check(app._failed_transaction.candidate.export_save() == intended, tag + " failed choice cannot be replaced by Leave.")
		app.save_store.failure_point = ""
		var reentrant := [0]
		app.audio.cue_started.connect(func(_record):
			reentrant[0] += 1
			app._resolve_service_choice(identity, choice)
			app._resolve_service_choice(identity, "leave"))
		app.retry_save()
		await settle()
		check(run.export_save() == intended and reentrant[0] == 1, tag + " Retry publishes the identical atomic result and rejects reentrant callbacks.")
	check(app.service_screen == null and app.map_screen != null and run.inspect_node(node_id).state == "visited", tag + " one resolution retires the service and returns to Map.")
	var expected_hp: int = mini(30, initial_hp + 10) if variant == "recovery" else initial_hp - 8 if variant == "tithe" else initial_hp
	var expected_gold: int = initial_gold + (20 if variant == "satchel" else 40 if variant == "tithe" else 0)
	check(run.snapshot().player_hp == expected_hp and run.snapshot().gold == expected_gold and run.snapshot().player_max_hp == 30, tag + " commits the exact supported benefit or no-benefit Leave.")
	var resolved: Dictionary = run.export_save()
	app._service_choice_requested(identity, choice, old_generation)
	app._resolve_service_choice(identity, "leave")
	check(run.export_save() == resolved, tag + " retired/stale callbacks cannot grant again or change the resolution.")
	app.queue_free()
	await settle()
	app = new_shell(path, context)
	await settle()
	check(app.run_state != null and app.run_state.export_save() == resolved and cue_count(app.audio) == 0, tag + " restored resolution receipt remains exact and silent.")
	app.continue_run()
	await settle()
	check(app.service_screen == null and app.map_screen != null, tag + " completed room cannot reopen through Continue.")
	if variant == "tithe": await insufficient_after_battle(app, tag)
	app.queue_free()
	await settle()

func insufficient_after_battle(app: Control, tag: String) -> void:
	app._return_home()
	var staged: Dictionary = app._stage_current()
	check(staged.get("ok", false), tag + " stages the subsequent real battle for ineligible-service evidence.")
	if not staged.get("ok", false): return
	var won: Dictionary = Fixture.win_battle(staged.run)
	check(won.get("ok", false) and staged.run.snapshot().player_hp == 6, tag + " actual Tithe then subsequent Wisp damage leaves 6 HP.")
	if not won.get("ok", false): return
	check(app._commit_transaction(staged.run, "fixture_checkpoint"), tag + " persists genuine second-battle health without fabricated progress.")
	app.continue_run()
	await settle()
	app.request_node_entry(Fixture.next_node(app.run_state))
	app.confirm_node_entry()
	await settle()
	check(app.service_screen != null and app.service_screen.presentation.player_hp == 6, tag + " next retained Tithe opens with real 6 HP.")
	if app.service_screen == null: return
	var before: Dictionary = app.run_state.export_save()
	check(app.service_screen.choice_buttons.blood_tithe.disabled and not app.service_screen.leave_button.disabled, tag + " genuinely insufficient Tithe disables payment and keeps Leave reachable.")
	app.service_screen.select_choice("blood_tithe")
	check(not app.service_screen.inspection.visible and app.run_state.export_save() == before, tag + " ineligible real-room selection cannot spend HP or grant Gold.")
	await capture(app, "insufficient-after-battle-" + tag)
	app.service_screen.select_choice("leave")
	app.service_screen.confirm_choice()
	await settle()
	check(app.service_screen == null and app.map_screen != null and app.run_state.snapshot().player_hp == 6 and app.run_state.snapshot().gold == 40, tag + " ineligible Tithe Leave completes without changing actual HP or earned Gold.")

func navigation(app: Control, tag: String, original: Dictionary) -> void:
	var viewer: Control = app.service_screen
	viewer.dismiss_top()
	await settle()
	check(app.route_menu.visible and app.route_menu_resume.text == "Resume Combat", tag + " root Back opens the shared Menu with the approved action label.")
	var body: Label = app._route_menu_panel.get_meta("rc_body_scroll").get_child(0)
	check(body.text.contains("keeps this visit open"), tag + " Menu describes unresolved service preservation truthfully.")
	if root.size == Vector2i(450, 1000): check((root.get_final_transform() * app._route_menu_panel.get_global_rect()).is_equal_approx(Rect2(24, 170, 402, 660)), tag + " service retains approved Menu geometry.")
	await capture(app, "menu-" + tag)
	app.open_options()
	await settle()
	await capture(app, "options-" + tag)
	app.close_options()
	check(app.route_menu.visible and app.service_screen == viewer, tag + " Options returns to the same service Menu.")
	app.open_collection()
	await settle()
	await capture(app, "collection-" + tag)
	app.close_collection()
	check(app.route_menu.visible and app.service_screen == viewer, tag + " Collection returns to the same service Menu.")
	app._close_route_menu()
	app.open_map()
	await settle()
	var map: Control = app.map_screen
	app._map_menu_requested(app._map_generation)
	await settle()
	await capture(app, "map-menu-" + tag)
	app._close_route_menu()
	check(app.map_screen == map and app.service_screen == viewer, tag + " shared Menu resumes its exact Map-over-service caller.")
	app.close_map()
	check(app.service_screen == viewer and app.run_state.export_save() == original, tag + " Map inspection and all shared overlays preserve the active room.")

func presenter_boundary(app: Control, original_record: Dictionary, hp: int, filename: String) -> void:
	var model_before: Dictionary = app.run_state.export_save()
	var specimen := original_record.duplicate(true)
	specimen.player_hp = hp
	var definition: Dictionary = Policy.definition(str(specimen.room_id), "" if specimen.room_type == "recovery" else str(specimen.definition_id))
	specimen.choices = Policy.choices(definition, hp, int(specimen.player_max_hp), int(specimen.gold))
	app.service_screen.present(specimen)
	await settle()
	var benefit := "recover" if specimen.room_type == "recovery" else "blood_tithe"
	check(app.service_screen.choice_buttons[benefit].disabled and not app.service_screen.leave_button.disabled, filename + " detached specimen disables the ineligible benefit while preserving Leave.")
	await capture(app, filename)
	app.service_screen.present(original_record)
	check(app.run_state.export_save() == model_before, filename + " presentation boundary specimen never changes authoritative history.")

func cue_count(owner: Node) -> int:
	return owner.trace.filter(func(record): return record.get("cue") == "ui_confirm").size()

func capture(app: Control, filename: String) -> void:
	await settle()
	var bounds := root.get_final_transform() * root.get_visible_rect()
	var controls: Array = []
	var popup: PanelContainer
	if app.confirmation.visible:
		controls = [app.confirmation_confirm, app.confirmation_cancel, app.recovery_retry_button]
		popup = app._confirmation_panel
	elif app.options.visible or app.collection_screen.visible:
		pass # Existing shared overlay suites own their unchanged internal layout.
	elif app.route_menu.visible:
		controls = [app.route_menu_resume, app.route_menu_quit, app.route_menu_options]
		popup = app._route_menu_panel
	elif app.service_screen != null:
		if app.service_screen.inspection.visible:
			controls = [app.service_screen.modal_action, app.service_screen.modal_close]
			popup = app.service_screen.panel
		else:
			controls = [app.service_screen.leave_button]
			check(bounds.encloses(root.get_final_transform() * app.service_screen._header.get_global_rect()) and not app.service_screen.resources_label.get_global_rect().intersects(app.service_screen.scroll.get_global_rect()) and not app.service_screen._header.get_global_rect().intersects(app.service_screen.scroll.get_global_rect()), filename + " header/resources fit above scrollable choices.")
	if popup != null:
		check(bounds.encloses(root.get_final_transform() * popup.get_global_rect()) and popup.size.y <= Ui.POPUP_MAX_HEIGHT, filename + " popup fits and respects the shared 660px content height cap.")
	for button in controls:
		if button.is_visible_in_tree(): check(bounds.encloses(root.get_final_transform() * button.get_global_rect()), filename + " keeps " + button.text + " reachable.")
	if _capture: check(root.get_texture().get_image().save_png(DESTINATION.path_join(filename + ".png")) == OK, filename + " actual configured-root screenshot saved.")
