extends SceneTree
const Loader = preload("res://scripts/core/content_loader.gd")
const RunState = preload("res://scripts/core/run_state.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
var checks := 0
var failures := 0
var assertions: Array = []
const DESTINATION := "res://output/qa/rc-027/collection-shell"

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 8: await process_frame

func _tap(viewport: Viewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func _back(app: Control) -> void:
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]: await _exercise(dimensions)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-027 collection shell checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _exercise(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("settings-" + tag + ".cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var settings: Dictionary = Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion = true
	Settings.save_values(settings, app.settings_path)
	viewport.add_child(app)
	await settle()
	app.request_new_run(42)
	await settle()
	var first_run = app.run_state
	var profile = app.progression
	var profile_before: Dictionary = profile.snapshot()
	check(first_run.snapshot().profile == profile_before and profile_before.unlocked_definition_ids.size() == 4, tag + " Production New Run starts with four definition unlocks and separate run copies.")
	var map: Control = app.map_screen
	var shared_menu: Control = app.route_menu
	map.scroll.scroll_vertical = 100000
	await settle()
	var map_offset: int = map.scroll.scroll_vertical
	var before: Dictionary = app.run_state.snapshot()
	await _tap(viewport, map.menu_button.get_global_rect().get_center())
	check(app.route_menu == shared_menu and shared_menu.visible, tag + " Native Map Menu opens the single shared menu instance.")
	await _tap(viewport, app.route_menu_collection.get_global_rect().get_center())
	check(app.collection_screen.visible and app.route_menu.visible and map._blocked, tag + " Native Menu Collection overlays the retained menu and blocks Map.")
	var viewer: Control = app.collection_screen
	viewer.body_scroll.ensure_control_visible(viewer.card_buttons[-1])
	await settle()
	var list_offset: int = viewer.body_scroll.scroll_vertical
	var card: Button = viewer.card_buttons[-1]
	await _tap(viewport, Vector2(card.get_global_rect().get_center().x, card.get_global_rect().position.y + 30))
	check(viewer.detail_visible, tag + " Native collection card inspection opens details.")
	await _back(app)
	check(viewer.visible and not viewer.detail_visible and viewer.body_scroll.scroll_vertical == list_offset and app.route_menu.visible, tag + " Duplicate native Back closes only details and restores exact collection scroll.")
	await _back(app)
	check(not viewer.visible and app.route_menu.visible and app.map_screen == map and map.scroll.scroll_vertical == map_offset, tag + " Next Back returns to the same Map Menu and preserves map scroll.")
	await _back(app)
	check(not app.route_menu.visible and app.map_screen == map and not map._blocked and app.run_state.snapshot() == before, tag + " Next Back dismisses only Menu; ownership, progression and route remain untouched.")
	app.close_map()
	await settle()
	app.request_new_run(57)
	check(app.confirmation.visible, tag + " Replacing the current run still requires the existing confirmation.")
	app.confirm_new_run()
	await settle()
	check(app.run_state != first_run and app.progression == profile and app.progression.snapshot() == profile_before and app.run_state.snapshot().profile == profile_before, tag + " Confirmed New Run replaces run identity while preserving the same session progression owner.")
	check(app.run_state.snapshot().owned_cards.size() == 8 and app.run_state.snapshot().gold == 0, tag + " Definition unlocks do not add starter copies or carry run Gold into New Run.")
	app.close_map()
	await settle()
	# Explicit standalone run adapter exercises delivered Combat without
	# manufacturing a route visit or substituting unfinished production rooms.
	app.run_state = RunState.new(Loader.load_setup().setup, 42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	var entered: Dictionary = app.run_state.enter_battle()
	check(entered.ok and app._attach_battle(entered.combat), tag + " Isolated delivered Combat attaches through the real shell seam.")
	await settle()
	var scene: Control = app.combat_scene
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var battle: Dictionary = scene.controller.snapshot()
	var battle_offset: int = scene.page_scroll.scroll_vertical
	var selection: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell]
	await _tap(viewport, scene.combat_navigation.buttons.menu.get_global_rect().get_center())
	check(app.route_menu == shared_menu and shared_menu.visible and not scene.menu.visible and scene._shell_modal, tag + " Combat opens the exact retained Map Menu instance while keeping its standalone native Menu hidden.")
	await _tap(viewport, app.route_menu_collection.get_global_rect().get_center())
	check(viewer.visible and shared_menu.visible and not scene.menu.visible and scene._shell_modal, tag + " Shared Combat Menu Collection opens read-only inspection above the retained menu without recreating Combat.")
	await _back(app)
	check(not viewer.visible and app.route_menu == shared_menu and shared_menu.visible and not scene.menu.visible and scene._shell_modal, tag + " Back restores the same shared Combat Menu and leaves its background input blocked.")
	check(app.combat_scene == scene and scene.controller.snapshot() == battle and scene.page_scroll.scroll_vertical == battle_offset and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, tag + " Menu inspection preserves Combat, preparation, selections and page scroll.")
	await _tap(viewport, app.route_menu_resume.get_global_rect().get_center())
	check(not shared_menu.visible and not scene.menu.visible and not scene._shell_modal and app.combat_scene == scene and scene.controller.snapshot() == battle and scene.page_scroll.scroll_vertical == battle_offset and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, tag + " Shared Resume returns to the exact battle and selections without exposing the standalone Menu.")
	app.queue_free()
	await settle()
	viewport.queue_free()
	await settle()
