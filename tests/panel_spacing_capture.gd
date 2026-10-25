extends SceneTree
## Actual panels and native input. Only the excluded RC-027 route is used for
## rewards, reached by an ordinary fixed-seed Combat victory, never fake visits.
## These SubViewports are unscaled component checks. shared_menu_capture.gd
## separately verifies the configured root-window stretch used by normal play.
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/gameplay-menu/panels"
var checks := 0
var failures := 0
var assertions: Array = []
var measurements: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String, evidence: Variant = null) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description, "evidence": evidence})
	if not condition:
		failures += 1
		push_error(description + (" " + str(evidence) if evidence != null else ""))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	for dimensions in [Vector2i(450, 1000), Vector2i(720, 1600), Vector2i(360, 640)]:
		if "--only-450" in OS.get_cmdline_user_args() and dimensions.x != 450: continue
		await _exercise(dimensions)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "assertions": assertions, "measurements": measurements,
		"scope": "Unscaled SubViewport component checks for shared Menu and borderless panels, native touch input and state preservation. Configured root-window stretch is covered separately by shared_menu_capture.gd. Reward-enabled excluded fixture uses real fixed-seed Combat victory. No native build or physical-device acceptance."}, "  ") + "\n")
	print("%d menu match capture checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _exercise(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("settings-" + tag + ".cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var settings: Dictionary = Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion = true
	Settings.save_values(settings, app.settings_path)
	viewport.add_child(app)
	await settle()
	app.run_state = Fixture.new_run(42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	var route_before: Dictionary = app.run_state.snapshot()
	var map: Control = app.map_screen
	await touch(viewport, map.menu_button)
	check(app.route_menu.visible, tag + " Native Map Menu opens.")
	_measure_panel(app._route_menu_panel, dimensions, tag + " Map Menu")
	for button in [app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit]:
		_reachable(button, dimensions, tag + " Map Menu", 68)
	var map_menu := _menu_layout(app._route_menu_panel.get_global_rect(), [app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit], app._route_menu_panel.get_child(0).get_child(0))
	map_menu.instance_id = app.route_menu.get_instance_id()
	map_menu.body = app._route_menu_panel.get_meta("rc_body_scroll").get_child(0).text
	await save(viewport, "map-menu-" + tag)
	var map_menu_scroll: ScrollContainer = app._route_menu_panel.get_meta("rc_body_scroll")
	if map_menu_scroll.get_v_scroll_bar().max_value > map_menu_scroll.get_v_scroll_bar().page:
		await scroll_to_end(viewport, map_menu_scroll)
		check(map_menu_scroll.scroll_vertical > 0, tag + " Map Menu explanatory copy scrolls while its five actions stay fixed.")
		await save(viewport, "map-menu-scrolled-" + tag)
	await touch(viewport, app.route_menu_options)
	_measure_panel(app.options.panel, dimensions, tag + " Map Options")
	_reachable(app.options.close_button, dimensions, tag + " Map Options")
	await save(viewport, "map-options-" + tag)
	await scroll_to_end(viewport, app.options.body_scroll)
	await save(viewport, "map-options-scrolled-" + tag)
	await touch(viewport, app.options.close_button)
	await touch(viewport, app.route_menu_collection)
	_measure_panel(app.collection_screen.panel, dimensions, tag + " Collection")
	_reachable(app.collection_screen.close_button, dimensions, tag + " Collection")
	await save(viewport, "collection-" + tag)
	await scroll_to_end(viewport, app.collection_screen.body_scroll)
	check(app.collection_screen.body_scroll.scroll_vertical > 0, tag + " Collection remains scrollable through its native surface.")
	await save(viewport, "collection-scrolled-" + tag)
	await touch(viewport, app.collection_screen.close_button)
	await touch(viewport, app.route_menu_resume)
	check(not app.route_menu.visible and app.run_state.snapshot() == route_before, tag + " Map menu/Options/Collection inspection preserves authoritative run and route.")
	await touch(viewport, map.help_button)
	_measure_panel(map.inspection_panel, dimensions, tag + " Map Guide")
	_reachable(map.inspection_close, dimensions, tag + " Map Guide")
	await save(viewport, "map-guide-" + tag)
	await scroll_to_end(viewport, map.inspection_panel.get_meta("rc_body_scroll"))
	await save(viewport, "map-guide-scrolled-" + tag)
	await touch(viewport, map.inspection_close)
	var first: String = app.run_state.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	map.inspect_node(first)
	await settle()
	_measure_panel(map.inspection_panel, dimensions, tag + " Room inspection")
	await save(viewport, "room-inspection-" + tag)
	await touch(viewport, map.inspection_action)
	_measure_panel(app._confirmation_panel, dimensions, tag + " Entry confirmation")
	_reachable(app.confirmation_confirm, dimensions, tag + " Entry confirmation")
	_reachable(app.confirmation_cancel, dimensions, tag + " Entry confirmation")
	await save(viewport, "entry-confirmation-" + tag)
	await touch(viewport, app.confirmation_cancel)
	check(app.run_state.snapshot() == route_before, tag + " Entry confirmation Cancel consumes no visit.")
	app.request_node_entry(first)
	app.confirm_node_entry()
	await settle()
	var scene: Control = app.combat_scene
	check(scene != null, tag + " Real Combat attaches for panel checks.")
	if scene == null:
		await dispose(app, viewport)
		return
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var battle_before: Dictionary = scene.controller.snapshot()
	var owned_before: Dictionary = app.run_state.snapshot()
	var selected: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell]
	var page_offset: int = scene.page_scroll.scroll_vertical
	await touch(viewport, scene.combat_navigation.buttons.menu)
	check(app.route_menu.visible and not scene.menu.visible, tag + " Combat opens the shared application Menu.")
	_measure_panel(app._route_menu_panel, dimensions, tag + " Combat Menu")
	for button in [app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit]:
		_reachable(button, dimensions, tag + " Combat Menu", 68)
	_check_menu_match(app, map_menu, tag)
	check(not scene._native_popup_shade.visible and scene._shell_modal, tag + " Shared Menu owns the shade and blocks background Combat input.")
	await save(viewport, "combat-menu-" + tag)
	var combat_menu_scroll: ScrollContainer = app._route_menu_panel.get_meta("rc_body_scroll")
	if combat_menu_scroll.get_v_scroll_bar().max_value > combat_menu_scroll.get_v_scroll_bar().page:
		await scroll_to_end(viewport, combat_menu_scroll)
		check(combat_menu_scroll.scroll_vertical > 0, tag + " Combat Menu explanatory copy scrolls while its five actions stay fixed.")
		await save(viewport, "combat-menu-scrolled-" + tag)
	await touch(viewport, app.route_menu_store)
	check(app.route_menu.visible and not app.options.visible and not app.collection_screen.visible and scene.controller.snapshot() == battle_before and app.run_state.snapshot() == owned_before,
		tag + " Unavailable Store native tap preserves the open Menu and battle.")
	await touch(viewport, app.route_menu_options)
	check(app.options.visible and app.route_menu.visible and not scene.menu.visible, tag + " Shared Options opens above the retained Menu.")
	_measure_panel(app.options.panel, dimensions, tag + " Combat Options")
	_reachable(app.options.close_button, dimensions, tag + " Combat Options")
	await save(viewport, "combat-options-" + tag)
	await touch(viewport, app.options.close_button)
	check(app.route_menu.visible and not app.options.visible and scene._shell_modal, tag + " Options Close restores the same shared Menu.")
	await touch(viewport, app.route_menu_collection)
	check(app.collection_screen.visible and app.route_menu.visible and not scene.menu.visible, tag + " Collection opens above the retained shared Menu.")
	await save(viewport, "combat-collection-" + tag)
	await touch(viewport, app.collection_screen.close_button)
	check(app.route_menu.visible and not app.collection_screen.visible and scene._shell_modal, tag + " Collection Close restores the same shared Menu.")
	await touch(viewport, app.route_menu_resume)
	check(not app.route_menu.visible and not scene.menu.visible and not scene._shell_modal, tag + " Primary Resume closes the shared Menu and restores Combat input.")
	await touch(viewport, scene.combat_navigation.buttons.guide)
	check(scene.dialog.visible, tag + " Native Combat Guide opens.")
	_measure_window(scene.dialog, dimensions, tag + " Combat Guide")
	var guide_title: Label = scene.dialog.get_meta("rc_title")
	check(guide_title.is_visible_in_tree() and guide_title.text == "Circuit guide" and guide_title.get_theme_font_size("font_size") == 22,
		tag + " Borderless Guide retains its internal title heading.")
	_reachable(scene.dialog.get_ok_button(), scene.dialog.size, tag + " Combat Guide")
	await save(viewport, "combat-guide-" + tag)
	var guide_scroll: ScrollContainer = scene.guide_text.get_parent()
	await scroll_to_end(scene.dialog, guide_scroll)
	check(guide_scroll.scroll_vertical > 0, tag + " Long Combat Guide scrolls through native input.")
	await save(viewport, "combat-guide-scrolled-" + tag)
	await touch(scene.dialog, scene.dialog.get_ok_button())
	check(not scene.dialog.visible and not scene._native_popup_shade.visible, tag + " Native Guide Close also removes its shade.")
	scene._inspect_tool("straight")
	await settle()
	_measure_panel(scene.inspector_panel, dimensions, tag + " Tool inspector")
	_reachable(scene.inspector_close, dimensions, tag + " Tool inspector")
	await save(viewport, "tool-inspector-" + tag)
	await touch(viewport, scene.inspector_close)
	await touch(viewport, scene.turn_pass_button)
	_measure_panel(scene.inspector_panel, dimensions, tag + " Pass confirmation")
	_reachable(scene.inspector_close, dimensions, tag + " Pass confirmation")
	_reachable(scene.inspector_confirm_pass, dimensions, tag + " Pass confirmation")
	await save(viewport, "pass-confirmation-" + tag)
	await touch(viewport, scene.inspector_close)
	await touch(viewport, scene.combat_navigation.buttons.menu)
	await touch(viewport, app.route_menu_quit)
	check(app.confirmation.visible and not scene.menu.visible and not scene._native_popup_shade.visible, tag + " Native Quit to Home opens the existing confirmation without retaining Menu chrome.")
	_measure_panel(app._confirmation_panel, dimensions, tag + " Quit confirmation")
	await save(viewport, "quit-confirmation-" + tag)
	await touch(viewport, app.confirmation_cancel)
	check(app.route_menu.visible, tag + " Quit cancellation returns to the same shared Menu.")
	await touch(viewport, app.route_menu_resume)
	check(app.combat_scene == scene and scene.controller.snapshot() == battle_before and app.run_state.snapshot() == owned_before and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selected and scene.page_scroll.scroll_vertical == page_offset,
		tag + " All panel inspection/cancellation preserves scene, battle, RNG, run ownership, selection and page scroll.")
	# Reward screen uses actual outcome ownership, not a fabricated completed room.
	scene.controller.set_presenter(Immediate.new())
	var player := Player.new()
	for turn in range(40):
		if scene.controller.snapshot().state != "playing": break
		if not player.play_turn(scene.controller): break
	await settle()
	check(app.run_state.snapshot().pending_result.get("outcome") == "victory", tag + " Fixed-seed ordinary commands produce a real reward-bearing victory.")
	if app.run_state.snapshot().pending_result.get("outcome") == "victory":
		_measure_panel(app._confirmation_panel, dimensions, tag + " Result confirmation")
		await save(viewport, "victory-result-" + tag)
		app.open_rewards()
		await settle()
		var reward_before: Dictionary = app.run_state.snapshot()
		_measure_panel(app.reward_screen.panel, dimensions, tag + " Rewards")
		for button in [app.reward_screen.gold_button, app.reward_screen.skip_button, app.reward_screen.close_button]:
			_reachable(button, dimensions, tag + " Rewards")
		await save(viewport, "rewards-" + tag)
		await scroll_to_end(viewport, app.reward_screen.scroll)
		check(app.reward_screen.scroll.scroll_vertical > 0, tag + " Reward cards remain scrollable.", {"visible": app.reward_screen.visible, "panel_rect": str(app.reward_screen.panel.get_global_rect()), "scroll_rect": str(app.reward_screen.scroll.get_global_rect())})
		_measure_panel(app.reward_screen.panel, dimensions, tag + " Rewards after native swipe")
		await save(viewport, "rewards-scrolled-" + tag)
		await touch(viewport, app.reward_screen.close_button)
		check(app.run_state.snapshot() == reward_before, tag + " Native reward Close preserves the unresolved choice and all RNG.")
	await dispose(app, viewport)

func _measure_panel(panel: PanelContainer, dimensions: Vector2i, label: String) -> void:
	var bounds := panel.get_global_rect()
	var content: Control = panel.get_child(0)
	_measure(bounds, content.get_global_rect(), Rect2(Vector2.ZERO, Vector2(dimensions)), label)

func _measure_window(window: Window, dimensions: Vector2i, label: String) -> void:
	check(window.borderless, label + " has no native title bar or embedded window decoration.")
	var bounds := Rect2(Vector2(window.position), Vector2(window.size))
	var body: Control = window.get_meta("rc_body_column")
	var content := body.get_global_rect()
	content.position += Vector2(window.position)
	_measure(bounds, content, Rect2(Vector2.ZERO, Vector2(dimensions)), label)

func _menu_layout(bounds: Rect2, buttons: Array, heading: Label) -> Dictionary:
	var actions: Array = []
	for button in buttons:
		var rectangle: Rect2 = button.get_global_rect()
		rectangle.position -= bounds.position
		actions.append({"text": button.text, "rect": rectangle, "font_size": button.get_theme_font_size("font_size"), "palette": button.get_meta("rc_button_palette", "")})
	return {"size": bounds.size, "actions": actions, "heading": heading.text, "heading_size": heading.get_theme_font_size("font_size")}

func _check_menu_match(app: Control, reference: Dictionary, label: String) -> void:
	var actions: Array = [app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit]
	var actual := _menu_layout(app._route_menu_panel.get_global_rect(), actions, app._route_menu_panel.get_child(0).get_child(0))
	check(app.route_menu.get_instance_id() == reference.instance_id and reference.body == "Resume returns to the Map. Quit to Home keeps your saved progress." and app._route_menu_panel.get_meta("rc_body_scroll").get_child(0).text == "Resume keeps this battle unchanged. Quit to Home discards battle progress; Continue replays its entry.\n\nStore: Buy supplies between rooms, after the current room is complete.",
		label + " Map and Combat reuse one Menu instance with accurate caller and Store availability text.")
	measurements.append({"label": label + " Menu parity", "map": reference, "combat": actual})
	check(actual.size == reference.size, label + " Map and Combat Menu use the same fitted 560 by 660 preferred panel size.", [reference.size, actual.size])
	check(actual.heading == "Menu" and actual.heading == reference.heading and actual.heading_size == reference.heading_size,
		label + " Map and Combat Menu share the internal Menu heading.")
	check(actions.map(func(button): return button.text) == ["Resume Combat", "Options", "Collection", "Store", "Quit to Home"],
		label + " Map and Combat use identical action labels and order.", actions.map(func(button): return button.text))
	if actual.actions.size() != reference.actions.size(): return
	for index in range(actual.actions.size()):
		var expected: Dictionary = reference.actions[index]
		var found: Dictionary = actual.actions[index]
		check(found.text == expected.text and found.rect == expected.rect and found.font_size == expected.font_size and found.palette == expected.palette,
			label + " Matching Menu action geometry and style: " + str(found.text), {"map": expected, "combat": found})
	check(actual.actions[0].palette == "primary", label + " Resume is the primary shared Menu action.")

func _measure(bounds: Rect2, content: Rect2, viewport: Rect2, label: String, client: Rect2 = Rect2()) -> void:
	var pad_bounds := client if client.has_area() else bounds
	var outer := [bounds.position.x, bounds.position.y, viewport.end.x - bounds.end.x, viewport.end.y - bounds.end.y]
	var inner := [content.position.x - pad_bounds.position.x, content.position.y - pad_bounds.position.y, pad_bounds.end.x - content.end.x, pad_bounds.end.y - content.end.y]
	measurements.append({"label": label, "bounds": str(bounds), "content": str(content), "outer_ltrb": outer, "inner_ltrb": inner})
	check(viewport.encloses(bounds) and outer.all(func(value): return value >= 23.0), label + " panel retains at least 24px outer breathing room.", outer)
	check(inner[0] >= 35.0 and inner[2] >= 35.0 and inner[1] >= 39.0 and inner[3] >= 39.0, label + " content retains 36px horizontal and 40px vertical padding.", inner)

func _reachable(button: Button, dimensions: Vector2i, label: String, minimum_height: int = 44) -> void:
	check(button.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()) and button.size.y >= minimum_height,
		label + " reachable action: " + button.text, {"rect": str(button.get_global_rect()), "minimum_height": minimum_height})

func touch(viewport: Viewport, control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func scroll_to_end(viewport: Viewport, scroll: ScrollContainer) -> void:
	var bounds := scroll.get_global_rect()
	var point := Vector2(bounds.get_center().x, bounds.end.y - 10)
	var distance := minf(180, maxf(18, bounds.size.y - 20))
	for step in range(12):
		var press := InputEventScreenTouch.new()
		press.position = point
		press.pressed = true
		viewport.push_input(press, true)
		var drag := InputEventScreenDrag.new()
		drag.position = point - Vector2(0, distance)
		drag.relative = Vector2(0, -distance)
		viewport.push_input(drag, true)
		var release := InputEventScreenTouch.new()
		release.position = drag.position
		release.pressed = false
		viewport.push_input(release, true)
		await process_frame
	await settle()

func settle() -> void:
	for frame in 8: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(viewport: SubViewport, name: String) -> void:
	check(DisplayServer.get_name() != "headless", "Capture requires rendering.")
	if DisplayServer.get_name() == "headless": return
	check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + " captured.")

func dispose(app: Control, viewport: SubViewport) -> void:
	app.queue_free()
	await settle()
	viewport.queue_free()
	await settle()
