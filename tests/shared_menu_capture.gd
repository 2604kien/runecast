extends SceneTree
## Actual configured root Window, including canvas_items stretch and letterboxing.
const Fixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
var DESTINATION := "res://output/qa/gameplay-menu"
var checks := 0
var failures := 0
var assertions: Array = []
var records: Array = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="): DESTINATION = argument.trim_prefix("--capture-directory=")
	call_deferred("_run")

func check(condition: bool, description: String, evidence: Variant = null) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description, "evidence": evidence})
	if not condition:
		failures += 1
		push_error(description + (" " + str(evidence) if evidence != null else ""))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	Input.use_accumulated_input = false
	Input.emulate_mouse_from_touch = true
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(720, 1600),
		"Harness preserves project canvas_items configuration and 720 by 1600 logical canvas.")
	for dimensions in [Vector2i(450, 1000), Vector2i(720, 1600), Vector2i(360, 640)]:
		await _exercise(dimensions)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"checks": checks, "failures": failures, "assertions": assertions, "measurements": records,
		"scope": "Large gameplay-reference Menu in the actual configured root Window at 450x1000, 720x1600 and 360x640 physical pixels. At 450x1000 the required panel is exactly 402x660 at (24,170), with 36px horizontal and 40px vertical padding, 22px heading, 16px body text and 68px actions. Project canvas_items scaling and letterboxing remain enabled. PNGs are direct root render textures: 360x640 window content is 288x640 with 36px side letterboxes outside that framebuffer. Engine touch-to-mouse native input; one Menu instance and identical geometry across callers; byte-identical opaque interior for Combat versus its live Map. Supported battle entry uses excluded reward-free fixture; no fabricated outcome or device-build claim."}, "  ") + "\n")
	print("%d gameplay-reference Menu configured-window checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _exercise(dimensions: Vector2i) -> void:
	root.size = dimensions
	await settle()
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("settings-" + tag + ".cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var settings: Dictionary = Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion = true
	Settings.save_values(settings, app.settings_path)
	root.add_child(app)
	await settle()
	app.run_state = Fixture.new_run(42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	var map: Control = app.map_screen
	var route_before: Dictionary = app.run_state.snapshot()
	await tap(map.menu_button)
	check(app.route_menu.visible and app.map_screen == map, tag + " Native Map Menu opens over its original Map.")
	var reference := menu_snapshot(app)
	check(reference.actions == ["Resume Combat", "Options", "Collection", "Store", "Quit to Home"] and not app.route_menu_store.disabled, tag + " Shared Menu preserves literal Resume Combat and enables accepted Store access between rooms.", reference.actions)
	check(reference.body == "Resume returns to the Map. Quit to Home keeps your saved progress.", tag + " Initial Map Menu accurately describes its caller without an unavailable Store warning.", reference.body)
	check(reference.title == "Menu" and app._route_menu_panel.get_viewport() == root, tag + " Shared Menu heading and panel belong to the root canvas.")
	var physical: Rect2 = reference.physical_rect
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(physical), tag + " Physically rendered Menu fits the actual window.", physical)
	validate_reference(reference, dimensions, tag)
	var map_pixels := await capture(app, "map-menu-" + tag)
	await verify_menu_scroll(app, "map-menu-" + tag)
	await subpanels(app, map, null, tag + " Map")
	await tap(app.route_menu_store)
	check(app.store_screen.visible and app.store_screen.presentation.gold == 0 and app.route_menu.visible and app.map_screen == map and app.run_state.snapshot() == route_before, tag + " Native Store tap opens zero-Gold browsing above the exact Map, Menu and run.")
	app.open_store()
	await tap(app.store_screen.close_button)
	check(not app.store_screen.visible and app.route_menu.visible and app.route_menu.get_instance_id() == reference.instance_id and app.run_state.snapshot() == route_before, tag + " Repeated Store entry and native Store Back retain the exact same Menu and run.")
	await tap(app.route_menu_resume)
	check(not app.route_menu.visible and app.map_screen == map and app.run_state.snapshot() == route_before, tag + " Native Resume restores the original Map without consuming a visit.")
	var first: String = app.run_state.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.request_node_entry(first)
	await settle()
	await tap(app.confirmation_confirm)
	var scene: Control = app.combat_scene
	check(scene != null, tag + " Native entry confirmation attaches the supported real Combat fixture.")
	if scene == null:
		app.queue_free()
		await settle()
		return
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var battle: Dictionary = scene.controller.snapshot()
	var owned: Dictionary = app.run_state.snapshot()
	var selected: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell]
	var offset: int = scene.page_scroll.scroll_vertical
	await tap(scene.combat_navigation.buttons.menu)
	check(app.route_menu.visible and not scene.menu.visible and not scene._native_popup_shade.visible, tag + " Native Combat Menu uses the shell panel and never opens its standalone native Window.")
	compare_menu(reference, menu_snapshot(app), tag + " Combat")
	var combat_reference := menu_snapshot(app)
	check(combat_reference.actions == ["Resume Combat", "Options", "Collection", "Store", "Quit to Home"] and app.route_menu_store.disabled and combat_reference.body.begins_with("Resume keeps this battle unchanged.") and "Store:" in combat_reference.body, tag + " Active Combat disables Store, explains availability and retains its checkpoint replay explanation.")
	app.route_menu_store.pressed.emit()
	app.open_store()
	check(not app.store_screen.visible and scene.controller.snapshot() == battle and app.run_state.snapshot() == owned, tag + " Active Combat rejects direct and disabled Store callbacks without changing its checkpoint.")
	var combat_pixels := await capture(app, "combat-menu-" + tag)
	check(map_pixels != combat_pixels, tag + " Shared Menu renders caller-specific Resume and checkpoint explanations.")
	await verify_menu_scroll(app, "combat-menu-" + tag)
	await subpanels(app, null, scene, tag + " Combat")
	await tap(app.route_menu_quit)
	check(app.confirmation.visible and app.combat_scene == scene and app.route_menu.visible, tag + " Native Quit preserves the battle below its existing confirmation.")
	await save("combat-quit-confirmation-" + tag)
	await tap(app.confirmation_cancel)
	check(not app.confirmation.visible and app.route_menu.visible and app.combat_scene == scene, tag + " Quit Cancel returns to the exact shared Menu instance.")
	await tap(app.route_menu_resume)
	check(not app.route_menu.visible and app.map_screen == null, tag + " Native Resume restores Combat without opening Map.")
	check(app.combat_scene == scene and scene.controller.snapshot() == battle and app.run_state.snapshot() == owned and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selected and scene.page_scroll.scroll_vertical == offset,
		tag + " Menu, Options, Collection and Quit cancellation preserve battle, RNG, run ownership, selection and scroll.")
	await tap(scene.combat_navigation.buttons.map)
	var live_map: Control = app.map_screen
	check(live_map != null and app.combat_scene == scene, tag + " Combat Map opens while retaining its live battle caller.")
	if live_map != null:
		await tap(live_map.menu_button)
		check(app.route_menu.visible and app.map_screen == live_map and not scene.menu.visible, tag + " Menu opened from Combat Map leaves that exact Map in place.")
		compare_menu(combat_reference, menu_snapshot(app), tag + " Combat Map")
		check(menu_snapshot(app).body == combat_reference.body and menu_snapshot(app).actions == combat_reference.actions, tag + " Live Combat Map and Combat share identical unavailable Store copy and actions.")
		var live_map_pixels := await capture(app, "combat-map-menu-" + tag)
		check(combat_pixels == live_map_pixels, tag + " Shared Menu opaque interior remains byte-identical above Combat Map.")
		await tap(app.route_menu_resume)
		check(app.map_screen == live_map and not app.route_menu.visible, tag + " Resume returns to its caller Map rather than discarding it.")
		await tap(live_map.close_button)
		check(app.map_screen == null and app.combat_scene == scene and scene.controller.snapshot() == battle and app.run_state.snapshot() == owned,
			tag + " Closing the resumed Map returns to the unchanged Combat owner.")
	records.append({"physical_size": root.size, "content_scale_size": root.content_scale_size,
		"logical_viewport": root.get_visible_rect(), "root_transform": root.get_final_transform(),
		"raw_render_texture_size": root.get_texture().get_image().get_size(), "letterbox_offset": root.get_final_transform().origin, "menu": reference})
	app.queue_free()
	await settle()

func subpanels(app: Control, map: Control, scene: Control, label: String) -> void:
	print("Shared Menu subpanels: ", label)
	var instance: int = app.route_menu.get_instance_id()
	await tap(app.route_menu_options)
	check(app.options.visible and app.route_menu.visible, label + " native Options uses the shared shell overlay above Menu.")
	await tap(app.options.close_button)
	check(not app.options.visible and app.route_menu.visible and app.route_menu.get_instance_id() == instance and app.map_screen == map and app.combat_scene == scene,
		label + " Options Close restores the same Menu and caller.")
	await tap(app.route_menu_collection)
	check(app.collection_screen.visible and app.route_menu.visible, label + " native Collection uses the shared shell overlay above Menu.")
	await tap(app.collection_screen.close_button)
	check(not app.collection_screen.visible and app.route_menu.visible and app.route_menu.get_instance_id() == instance and app.map_screen == map and app.combat_scene == scene,
		label + " Collection Close restores the same Menu and caller.")

func menu_snapshot(app: Control) -> Dictionary:
	var panel: PanelContainer = app._route_menu_panel
	var buttons := [app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit]
	var rect: Rect2 = panel.get_global_rect()
	var physical := root.get_final_transform() * rect
	var column: Control = panel.get_child(0)
	var content := root.get_final_transform() * column.get_global_rect()
	var title: Label = column.get_child(0)
	var body: Label = panel.get_meta("rc_body_scroll").get_child(0)
	return {"instance_id": app.route_menu.get_instance_id(), "panel_id": panel.get_instance_id(),
		"logical_rect": rect, "physical_rect": physical, "physical_content_rect": content,
		"physical_padding_ltrb": [content.position.x - physical.position.x, content.position.y - physical.position.y, physical.end.x - content.end.x, physical.end.y - content.end.y],
		"title": title.text, "body": body.text,
		"physical_heading_font_size": physical_font_size(title), "physical_body_font_size": physical_font_size(body),
		"physical_button_font_sizes": buttons.map(func(button): return physical_font_size(button)),
		"actions": buttons.map(func(button): return button.text),
		"action_rects": buttons.map(func(button): return root.get_final_transform() * button.get_global_rect())}

func physical_font_size(control: Control) -> float:
	return control.get_theme_font_size("font_size") * control.get_global_transform_with_canvas().get_scale().y * root.get_final_transform().get_scale().y

func validate_reference(actual: Dictionary, dimensions: Vector2i, label: String) -> void:
	var content_bounds := root.get_final_transform() * root.get_visible_rect()
	check(content_bounds.encloses(actual.physical_rect), label + " Menu remains inside the visible content area without drawing into letterbox margins.", actual.physical_rect)
	check(actual.action_rects.all(func(rect): return content_bounds.encloses(rect) and rect.size.y >= 44.0), label + " All five Menu actions remain physically reachable.", actual.action_rects)
	if dimensions != Vector2i(450, 1000): return
	check(actual.physical_rect.is_equal_approx(Rect2(24, 170, 402, 660)), label + " Menu exactly matches the large gameplay reference panel bounds.", actual.physical_rect)
	var padding: Array = actual.physical_padding_ltrb
	check(is_equal_approx(padding[0], 36.0) and is_equal_approx(padding[1], 40.0) and is_equal_approx(padding[2], 36.0) and is_equal_approx(padding[3], 40.0),
		label + " Menu matches the reference 36px horizontal and 40px vertical content padding.", padding)
	check(is_equal_approx(actual.physical_heading_font_size, 22.0) and is_equal_approx(actual.physical_body_font_size, 16.0),
		label + " Menu heading and body retain the reference 22px and 16px physical text sizes.", [actual.physical_heading_font_size, actual.physical_body_font_size])
	check(actual.action_rects.all(func(rect): return is_equal_approx(rect.size.y, 68.0)), label + " Every Menu action retains the reference 68px physical height.", actual.action_rects)

func compare_menu(reference: Dictionary, actual: Dictionary, label: String) -> void:
	check(actual.instance_id == reference.instance_id and actual.panel_id == reference.panel_id, label + " reuses the exact same Menu and panel objects.")
	check(actual.logical_rect == reference.logical_rect and actual.physical_rect == reference.physical_rect and actual.action_rects == reference.action_rects,
		label + " shares exact logical and physical Menu and button rectangles with Map.", {"actual": actual, "reference": reference})
	check(actual.title == reference.title and actual.actions[0] == reference.actions[0] and actual.actions[1] == reference.actions[1] and actual.actions[2] == reference.actions[2] and actual.actions[4] == reference.actions[4],
		label + " shares literal heading, Resume Combat, Options, Collection and Quit labels; Store availability is caller-specific.")

func capture(app: Control, name: String) -> PackedByteArray:
	await save(name)
	var panel: PanelContainer = app._route_menu_panel
	var physical := root.get_final_transform() * panel.get_global_rect()
	var panel_scale := panel.get_global_transform_with_canvas().get_scale() * root.get_final_transform().get_scale()
	# Transparent outer corners reveal the caller. Compare the opaque interior,
	# including all body copy and actions, independently of background artwork.
	var opaque := physical.grow(-24 * panel_scale.x)
	# The framebuffer excludes letterbox margins from physical Window space.
	opaque.position -= root.get_final_transform().origin
	var image := root.get_texture().get_image().get_region(Rect2i(opaque))
	check(image.save_png(DESTINATION.path_join(name + "-opaque.png")) == OK, name + " opaque physical-pixel comparison captured.")
	return image.get_data()

func tap(control: Control) -> void:
	var point: Vector2 = root.get_final_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
	await settle()

func verify_menu_scroll(app: Control, label: String) -> void:
	var scroll: ScrollContainer = app._route_menu_panel.get_meta("rc_body_scroll")
	if scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page: return
	var bounds := root.get_final_transform() * scroll.get_global_rect()
	var start := Vector2(bounds.get_center().x, bounds.end.y - 4)
	var travel := minf(90, bounds.size.y - 8)
	for step in range(12):
		var press := InputEventScreenTouch.new()
		press.position = start
		press.pressed = true
		Input.parse_input_event(press)
		var drag := InputEventScreenDrag.new()
		drag.position = start - Vector2(0, travel)
		drag.relative = Vector2(0, -travel)
		Input.parse_input_event(drag)
		var release := InputEventScreenTouch.new()
		release.position = drag.position
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
	await settle()
	check(scroll.scroll_vertical > 0 and app.route_menu.visible, label + " native swipe reveals overflowing reference copy while the Menu actions remain fixed.")
	await save(label + "-scrolled")

func settle() -> void:
	for frame in 10: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(name: String) -> void:
	check(DisplayServer.get_name() != "headless", "Configured-window capture requires the real renderer.")
	if DisplayServer.get_name() != "headless":
		check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + " unmodified root render texture captured.")
