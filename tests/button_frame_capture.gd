extends SceneTree
## Menu and modal controls at native portrait sizes. Measures frame interiors
## and native window chrome without changing the original combat control art.
const DESTINATION := "res://output/qa/button-spacing"
const Settings = preload("res://scripts/audio/audio_settings.gd")
const RunState = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Ui = preload("res://scenes/ui/theme/components.gd")
const StateLayer = preload("res://scenes/ui/theme/state_layer.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const PRIMARY = preload("res://assets/ui/buttons/primary.png")
var checks := 0
var failures := 0
var assertions: Array = []
var captures: Array[String] = []
var raster_comparisons: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	await _check_continue_raster()
	await _check_no_availability_symbols()
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture(dimensions)
	await create_timer(0.2).timeout
	var report := FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({
		"checks": checks, "failures": failures, "assertions": assertions, "captures": captures,
		"continue_frame_raster_comparisons": raster_comparisons,
		"engine": Engine.get_version_info().string,
		"scope": "Actual Home actions and Options, route help/inspection, confirmation, Combat Menu/Guide/inspector panels at native logical sizes. Menu-button content-inset, touch-size, sibling-gap, native-window-chrome and scroll containment checks with desktop renders. Combat toolbar/Cast/navigation/card art and standalone Map controls retain their original treatment; not physical-device acceptance."
	}, "  ") + "\n")
	print("%d menu button/frame spacing checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check_continue_raster() -> void:
	# Compare actual pixels against the unmodified action constructor. Merely
	# sharing primary.png cannot detect distorted corners or frame thickness.
	if DisplayServer.get_name() == "headless":
		check(false, "Continue frame raster equivalence requires a rendering display.")
		return
	for height in [52, 64, 82]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(332, height + 32)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var original := Ui.action("", true, Vector2(300, height))
		var menu := Ui.menu_action("", true, Vector2(300, height))
		for button in [original, menu]:
			button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.focus_mode = Control.FOCUS_NONE
			viewport.add_child(button)
			button.position = Vector2(16, 16)
			button.size = Vector2(300, height)
		menu.hide()
		await settle()
		var original_image := viewport.get_texture().get_image()
		var original_path := DESTINATION.path_join("continue-original-300x%d.png" % height)
		check(original_image.save_png(original_path) == OK, "Original Continue frame raster saves at height %d." % height)
		captures.append(original_path)
		original.hide()
		menu.show()
		await settle()
		var menu_image := viewport.get_texture().get_image()
		var menu_path := DESTINATION.path_join("continue-menu-300x%d.png" % height)
		check(menu_image.save_png(menu_path) == OK, "Menu Continue frame raster saves at height %d." % height)
		captures.append(menu_path)
		var different_pixels := 0
		var visible_pixels := 0
		for y in original_image.get_height():
			for x in original_image.get_width():
				var original_pixel := original_image.get_pixel(x, y)
				if original_pixel.a > 0.01:
					visible_pixels += 1
				if original_pixel != menu_image.get_pixel(x, y):
					different_pixels += 1
		check(visible_pixels > 1000, "Original Continue comparison contains visible painted artwork at height %d." % height)
		check(original.size.is_equal_approx(Vector2(300, height)) and menu.size.is_equal_approx(original.size), "Continue raster comparison uses identical 300x%d control sizes." % height)
		check(different_pixels == 0, "Menu Continue pixels exactly match the original at 300x%d: %d differing pixels." % [height, different_pixels])
		raster_comparisons.append({"size": "300x%d" % height, "different_pixels": different_pixels, "visible_pixels": visible_pixels})
		viewport.queue_free()
		await process_frame

func _check_no_availability_symbols() -> void:
	# Compare real overlay pixels, including callers explicitly enabling old
	# badges. Availability must never add a symbol, even alongside selection.
	if DisplayServer.get_name() == "headless": return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(300, 64)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var control := Control.new()
	control.set_meta("rc_show_state_badges", true)
	viewport.add_child(control)
	control.size = Vector2(viewport.size)
	var overlay := StateLayer.new()
	overlay.observed_control = control
	control.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for selected in [false, true]:
		overlay.states = {"selected": selected}
		overlay.queue_redraw()
		await settle()
		var baseline := viewport.get_texture().get_image()
		check(baseline.is_invisible() == not selected, "Availability regression keeps the independent selection cue.")
		for state in [{"disabled": true}, {"unavailable": true}, {"disabled": true, "unavailable": true}]:
			overlay.states = state.duplicate()
			overlay.states["selected"] = selected
			overlay.queue_redraw()
			await settle()
			check(viewport.get_texture().get_image().get_data() == baseline.get_data(),
				"Disabled/unavailable never adds symbol pixels, including legacy badges enabled and selection=%s: %s" % [selected, state])
	viewport.queue_free()
	await process_frame

func _capture(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("capture-settings.cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var values: Dictionary = Settings.DEFAULTS.duplicate(true)
	values.enabled = false
	values.reduced_motion = true
	Settings.save_values(values, app.settings_path)
	viewport.add_child(app)
	await settle()
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var view := Rect2(Vector2.ZERO, Vector2(dimensions))
	_check_buttons(app.home, tag + " Home")
	_check_siblings([app.continue_button, app.new_run_button, app.options_button], 8, tag + " Home")
	for button in [app.continue_button, app.new_run_button, app.options_button]:
		check(view.encloses(button.get_global_rect()), tag + " Home action remains onscreen: " + button.text)
	check(app.continue_button.disabled and app.continue_button.get_meta("rc_skin").tint != Color.WHITE, tag + " unavailable Continue stays disabled and visibly muted.")
	if DisplayServer.get_name() != "headless":
		var region := Rect2i(app.continue_button.get_global_rect())
		var with_overlay := viewport.get_texture().get_image().get_region(region)
		var overlay: Control = app.continue_button.get_meta("rc_overlay")
		overlay.hide()
		await settle()
		check(with_overlay.get_data() == viewport.get_texture().get_image().get_region(region).get_data(),
			tag + " disabled Home Continue renders identically with its empty overlay hidden; no disabled symbol.")
		overlay.show()
		await settle()
	await save(viewport, "home-" + tag)
	app.open_options()
	await settle()
	_check_panel(app.options.panel, view, tag + " Home Options")
	_check_buttons(app.options, tag + " Home Options")
	_check_slider_insets(app.options, tag + " Home Options")
	await save(viewport, "options-top-" + tag)
	app.options.body_scroll.scroll_vertical = 10000
	await settle()
	_check_panel(app.options.panel, view, tag + " scrolled Options")
	check(app.options.body_scroll.get_global_rect().encloses(app.options.toggles.reduced_motion.get_global_rect()), tag + " Options scroll reveals the complete last toggle.")
	await save(viewport, "options-bottom-" + tag)
	app.close_options()
	app.request_new_run(294)
	await settle()
	var map: Control = app.map_screen
	for control in [map.close_button, map.help_button, map.resume_button]:
		check(not control.get_meta("rc_button_frame", false), tag + " standalone Map control retains its original frame.")
	await save(viewport, "map-" + tag)
	map._show_help()
	await settle()
	_check_panel(map.inspection_panel, view, tag + " Route help")
	_check_buttons(map.inspection, tag + " Route help")
	await save(viewport, "map-help-" + tag)
	map.close_inspection()
	var entry: String = app.run_state.route_snapshot().entry_node_ids[0]
	map.inspect_node(entry)
	await settle()
	_check_panel(map.inspection_panel, view, tag + " Room inspection")
	_check_buttons(map.inspection, tag + " Room inspection")
	_check_siblings([map.inspection_action, map.inspection_close], 8, tag + " Room inspection")
	await save(viewport, "room-inspection-" + tag)
	map.inspection_action.pressed.emit()
	await settle()
	_check_panel(app._confirmation_panel, view, tag + " Entry confirmation")
	_check_buttons(app.confirmation, tag + " Entry confirmation")
	_check_siblings([app.confirmation_confirm, app.confirmation_cancel], 8, tag + " Entry confirmation")
	await save(viewport, "entry-confirmation-" + tag)
	app.cancel_confirmation()
	app.close_map()
	# An explicit standalone run fixture attaches through the managed shell;
	# its Combat uses the shared menu without implying playable tower rooms.
	app.run_state = RunState.new(Loader.load_setup().setup, 294)
	app.persistence_context = app.run_state.restore_context_for_tests()
	var entered: Dictionary = app.run_state.enter_battle()
	app._attach_battle(entered.combat)
	await settle()
	var scene: Control = app.combat_scene
	_check_original_combat(scene, dimensions, tag)
	await save(viewport, "combat-entry-" + tag)
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	await save(viewport, "combat-controls-" + tag)
	scene._request_pass()
	await settle()
	_check_panel(scene.inspector_panel, view, tag + " Pass confirmation")
	_check_buttons(scene.inspector_panel, tag + " Pass confirmation")
	_check_siblings([scene.inspector_confirm_pass, scene.inspector_close], 8, tag + " Pass confirmation")
	await save(viewport, "pass-confirmation-" + tag)
	scene._close_inspector()
	scene._inspect_tool("straight")
	await settle()
	_check_panel(scene.inspector_panel, view, tag + " Tool inspection")
	_check_buttons(scene.inspector_panel, tag + " Tool inspection")
	await save(viewport, "tool-inspection-" + tag)
	scene._close_inspector()
	scene._show_guide()
	await settle()
	_check_popup(scene.dialog, dimensions, tag + " Guide")
	await save(viewport, "guide-" + tag)
	scene.dialog.get_ok_button().pressed.emit()
	await settle()
	check(not scene.dialog.visible, tag + " full-width Guide OK retains its native dismissal behavior.")
	scene.dialog.hide()
	await _touch(viewport, scene.combat_navigation.buttons.menu.get_global_rect().get_center())
	check(app.route_menu.visible and not scene.menu.visible, tag + " managed Combat opens the shared application Menu on the same viewport.")
	_check_panel(app._route_menu_panel, view, tag + " shared Combat Menu")
	_check_buttons(app.route_menu, tag + " shared Combat Menu")
	_check_siblings([app.route_menu_resume, app.route_menu_options, app.route_menu_collection, app.route_menu_store, app.route_menu_quit], 8, tag + " shared Combat Menu")
	await save(viewport, "combat-menu-" + tag)
	await _touch(viewport, app.route_menu_resume.get_global_rect().get_center())
	check(not app.route_menu.visible and not scene.menu.visible and not scene._shell_modal, tag + " full-width shared Menu Resume returns to Combat through native input.")
	app.request_home()
	await settle()
	_check_panel(app._confirmation_panel, view, tag + " Quit confirmation")
	_check_buttons(app.confirmation, tag + " Quit confirmation")
	await save(viewport, "quit-confirmation-" + tag)
	app.confirm_home()
	await settle()
	_check_buttons(app.home, tag + " enabled Continue")
	await save(viewport, "home-continue-" + tag)
	app.request_new_run(39)
	await settle()
	_check_panel(app._confirmation_panel, view, tag + " Replace run")
	_check_buttons(app.confirmation, tag + " Replace run")
	await save(viewport, "new-run-confirmation-" + tag)
	app.cancel_confirmation()
	app.queue_free()
	await settle()
	viewport.queue_free()
	await process_frame

func _check_buttons(node: Node, context: String) -> void:
	if node is Control and not node.is_visible_in_tree():
		return
	if node is Button:
		_check_button(node, context + " " + node.name)
	for child in node.get_children():
		_check_buttons(child, context)

func _check_button(button: Button, context: String) -> void:
	check(button.get_meta("rc_button_frame", false), context + " uses the shared Continue frame.")
	if not button.has_meta("rc_skin"):
		check(false, context + " has a frame skin.")
		return
	var skin: Control = button.get_meta("rc_skin")
	check(skin.has_method("get_content_rect"), context + " exposes a protected interior.")
	if not skin.has_method("get_content_rect"):
		return
	check(skin.texture == PRIMARY, context + " reuses the approved Continue frame texture.")
	var local_inside: Rect2 = skin.get_content_rect()
	var inside: Rect2 = skin.get_global_transform() * local_inside
	check(button.size.x >= 44 and button.size.y >= 44, context + " retains a 44px touch target.")
	check(button.get_global_rect().encloses(inside) and inside.size.x > 0 and inside.size.y > 0, context + " has a nonempty interior.")
	# Native text may be transparent when the button owns explicit label lanes.
	if not button.text.is_empty() and button.get_theme_color("font_color").a > 0.01:
		var style: StyleBox = button.get_theme_stylebox("normal")
		var native_inside := button.get_global_rect().grow_individual(-style.get_content_margin(SIDE_LEFT), -style.get_content_margin(SIDE_TOP), -style.get_content_margin(SIDE_RIGHT), -style.get_content_margin(SIDE_BOTTOM))
		var font: Font = button.get_theme_font("font")
		var font_size := button.get_theme_font_size("font_size")
		var ink := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		if button.autowrap_mode != TextServer.AUTOWRAP_OFF:
			ink = font.get_multiline_string_size(button.text, HORIZONTAL_ALIGNMENT_CENTER, native_inside.size.x, font_size)
		var text_rect := Rect2(native_inside.position + (native_inside.size - ink) / 2.0, ink)
		check(inside.grow(0.6).encloses(text_rect), context + " complete native text clears the frame: " + str(text_rect) + " inside " + str(inside))
	_check_art_children(button, inside, context)

func _check_art_children(node: Node, inside: Rect2, context: String) -> void:
	for child in node.get_children():
		if not child is Control or not child.is_visible_in_tree():
			continue
		if child is Label or child is TextureRect:
			check(inside.grow(0.6).encloses(child.get_global_rect()), context + " contains " + child.name + " clear of the frame: " + str(child.get_global_rect()) + " inside " + str(inside))
			if child is Label and child.autowrap_mode == TextServer.AUTOWRAP_OFF and not child.clip_text:
				var font: Font = child.get_theme_font("font")
				var text_size := font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size"))
				check(text_size.x <= child.size.x + 0.6, context + " label fits its reserved width: " + child.text)
		_check_art_children(child, inside, context)

func _check_panel(panel: PanelContainer, viewport: Rect2, context: String) -> void:
	check(viewport.grow(0.6).encloses(panel.get_global_rect()), context + " panel fits viewport.")
	var style := panel.get_theme_stylebox("panel")
	var inside := panel.get_global_rect().grow_individual(-style.get_content_margin(SIDE_LEFT), -style.get_content_margin(SIDE_TOP), -style.get_content_margin(SIDE_RIGHT), -style.get_content_margin(SIDE_BOTTOM))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		check(style.get_content_margin(side) >= 28, context + " content clears the 24px decorative rim.")
	for child in panel.get_children():
		if child is Control and child.is_visible_in_tree():
			check(inside.grow(0.6).encloses(child.get_global_rect()), context + " keeps its complete content column inside the padded well.")
	_check_panel_descendants(panel, inside, context)

func _check_panel_descendants(node: Node, inside: Rect2, context: String) -> void:
	for child in node.get_children():
		if not child is Control or not child.is_visible_in_tree():
			continue
		if child is ScrollContainer:
			check(inside.grow(0.6).encloses(child.get_global_rect()), context + " scroll viewport clears panel frame.")
			continue # Its body is intentionally taller and clipped by this viewport.
		if child is Button or child is Label:
			check(inside.grow(0.6).encloses(child.get_global_rect()), context + " contains " + child.name + " inside its frame.")
		_check_panel_descendants(child, inside, context)

func _check_slider_insets(options: Control, context: String) -> void:
	var body: Rect2 = options.body_scroll.get_global_rect()
	for slider in options.sliders.values():
		check(slider.size.y >= 44, context + " slider has a 44px hit target.")
		check(slider.get_global_rect().position.x >= body.position.x and slider.get_global_rect().end.x <= body.end.x, context + " slider and knob lane fit the scroll width.")

func _check_popup(popup: Window, dimensions: Vector2i, context: String) -> void:
	check(popup.size.x <= dimensions.x - 16 and popup.size.y <= dimensions.y - 16, context + " window fits portrait viewport: " + str(popup.size))
	var title_height := 0 if popup.borderless else popup.get_theme_constant("title_height")
	var decorated := Rect2(Vector2(popup.position) - Vector2(0, title_height), Vector2(popup.size) + Vector2(0, title_height))
	check(Rect2(Vector2.ZERO, Vector2(dimensions)).grow(-8).encloses(decorated), context + " window and any visible title bar keep an 8px viewport margin: " + str(decorated))
	var well := Rect2(Vector2.ZERO, Vector2(popup.size)).grow(-16)
	_check_buttons(popup, context)
	var actions: Array = []
	for button in popup.find_children("*", "Button", true, false):
		if button.is_visible_in_tree():
			actions.append(button)
			check(well.grow(0.6).encloses(button.get_global_rect()), context + " action clears the window edge: " + button.text)
			check(button.size.x >= 180, context + " action retains a wide menu-button proportion: " + button.text)
	_check_siblings(actions, 8, context + " menu actions")

func _check_siblings(nodes: Array, gap: float, context: String) -> void:
	var controls: Array = nodes.filter(func(node): return node is Control and node.is_visible_in_tree())
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			var a: Rect2 = controls[i].get_global_rect()
			var b: Rect2 = controls[j].get_global_rect()
			check(not a.grow(gap * 0.5 - 0.1).intersects(b.grow(gap * 0.5 - 0.1)), context + " action frames retain a %dpx gap: %s / %s" % [int(gap), controls[i].name, controls[j].name])

func _check_original_combat(scene: Control, dimensions: Vector2i, tag: String) -> void:
	var actions: Array = [scene.turn_pass_button, scene.cast_button]
	actions.append_array(scene.stock_buttons.values())
	actions.append_array(scene.action_buttons.values())
	actions.append_array(scene.combat_navigation.get_children())
	for button in actions:
		check(not button.get_meta("rc_button_frame", false), tag + " gameplay action retains original art: " + button.name)
	for entry in [[scene.turn_pass_button, "parchment"], [scene.cast_button, "cast"], [scene.stock_buttons.straight, "slot"], [scene.action_buttons.rotate, "button"], [scene.combat_navigation, "nav"]]:
		var skin = entry[0].get_meta("combat_surface", null)
		check(skin != null and skin.get_script() == CombatSurface and skin.kind == entry[1], tag + " restores original CombatSurface " + entry[1] + ".")
	check(scene.wiring.columns == (7 if dimensions.x >= 640 else 4), tag + " original combat toolbar column count is preserved.")
	for card in scene.hand_box.get_children():
		check(is_equal_approx(card.custom_minimum_size.y, 146), tag + " original compact card height is preserved.")
		var info: Button = scene.info_buttons[int(card.get_meta("uid"))]
		check(info.size.is_equal_approx(Vector2(44, 44)) and not info.get_meta("rc_button_frame", false), tag + " original 44px unframed Info target is preserved.")

func settle() -> void:
	for frame in 12:
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func _touch(viewport: SubViewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func save(viewport: SubViewport, filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path := DESTINATION.path_join(filename + ".png")
	check(viewport.get_texture().get_image().save_png(path) == OK, filename + " render saves.")
	captures.append(path)
