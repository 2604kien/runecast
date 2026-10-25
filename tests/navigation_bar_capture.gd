extends SceneTree
## Actual production Combat and Map, measured and rendered side by side.
## No gameplay traversal, reference painting or reconstructed navigation is used.
var destination := "res://output/qa/rc-025-shared-navigation/screenshots"
const Settings = preload("res://scripts/audio/audio_settings.gd")
const SHARED_SCRIPT := "res://scenes/ui/theme/navigation_bar.gd"
const KEYS := ["menu", "map", "guide", "sound"]
var checks := 0
var failures := 0
var assertions: Array = []
var measurements: Array = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-output="):
			destination = argument.trim_prefix("--qa-output=").path_join("screenshots")
	call_deferred("_run")

func check(condition: bool, description: String, evidence: Variant = null) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description, "evidence": evidence})
	if not condition:
		failures += 1
		push_error(description + (": " + str(evidence) if evidence != null else ""))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	for dimensions in [Vector2i(841, 1870), Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture(dimensions)
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions,
		"measurements": measurements, "engine": Engine.get_version_info().string,
		"scope": "Actual production Combat and fresh route Map desktop viewports. Shared relative geometry, frame, glyph, font and native input checks. Both navigation bars retain neutral backgrounds. No native build or physical-device acceptance."}, "  ") + "\n")
	print("%d shared navigation checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _viewport(dimensions: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport

func _settings_path(name: String) -> String:
	var path := destination.path_join(name + "-settings.cfg")
	var values := Settings.DEFAULTS.duplicate(true)
	values.enabled = true
	values.reduced_motion = true
	Settings.save_values(values, path)
	return path

func _capture(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var combat_view := _viewport(dimensions)
	var map_view := _viewport(dimensions)
	var combat: Control = load("res://scenes/main.tscn").instantiate()
	combat.settings_path = _settings_path("combat-" + tag)
	combat_view.add_child(combat)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = _settings_path("map-" + tag)
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	map_view.add_child(app)
	await settle()
	app.request_new_run(294)
	combat._select_tool("straight")
	for index in combat.game.board.size():
		if combat.game.board[index].is_empty():
			combat.cells[index].pressed.emit()
			break
	combat.page_scroll.scroll_vertical = 100000
	await settle()
	var map_screen: Control = app.map_screen
	var battle_before: Dictionary = combat.controller.snapshot()
	var route_before: Dictionary = app.run_state.snapshot()
	var combat_owner = combat.audio
	var combat_player = combat.audio._ambience.player
	var scroll_before: int = combat.page_scroll.scroll_vertical
	check(combat.startup_error.is_empty() and app.combat_scene == null, tag + " Actual retained Combat and fresh route Map loaded independently.")
	_compare(combat.combat_navigation, map_screen._navigation, dimensions, tag + "-sound-on")
	await _save_pair(combat_view, map_view, combat.combat_navigation, map_screen._navigation, tag + "-sound-on")

	await _mouse(map_view, map_screen._navigation.buttons.map.get_global_rect().get_center())
	check(app.map_screen == map_screen and app.run_state.snapshot() == route_before, tag + " Selected Map click keeps the same screen and untouched route.")
	await _mouse(map_view, map_screen._navigation.buttons.guide.get_global_rect().get_center())
	check(map_screen.inspection.visible, tag + " Native Map Guide mouse click opens route help.")
	await _touch(map_view, map_screen._navigation.buttons.menu.get_global_rect().get_center())
	check(not app.route_menu.visible and map_screen.inspection.visible, tag + " Map help blocks navigation underneath.")
	map_screen.close_inspection()
	await settle()
	await _touch(map_view, map_screen._navigation.buttons.menu.get_global_rect().get_center())
	check(app.route_menu.visible and app.map_screen == map_screen, tag + " Native Map Menu finger tap opens the existing route menu once.")
	await _mouse(map_view, map_screen._navigation.buttons.sound.get_global_rect().get_center())
	check(bool(app.audio_settings.enabled), tag + " Open Map Menu blocks the underlying Sound button.")
	app.route_menu_resume.pressed.emit()
	await settle()
	await _mouse(map_view, map_screen._navigation.buttons.sound.get_global_rect().get_center())
	check(not bool(app.audio_settings.enabled) and app.map_screen == map_screen and app.run_state.snapshot() == route_before, tag + " Native Map Sound mouse click changes one owner preference without recreating Map or route.")

	await _mouse(combat_view, combat.combat_navigation.buttons.menu.get_global_rect().get_center())
	check(combat.menu.visible, tag + " Native Combat Menu mouse click reaches its existing menu.")
	combat.menu.hide()
	await settle()
	await _touch(combat_view, combat.combat_navigation.buttons.guide.get_global_rect().get_center())
	check(combat.dialog.visible, tag + " Native Combat Guide finger tap opens its existing guide.")
	combat.dialog.hide()
	await settle()
	await _touch(combat_view, combat.combat_navigation.buttons.map.get_global_rect().get_center())
	check(combat.standalone_map != null and combat._shell_modal, tag + " Native Combat Map finger tap opens the retained Map overlay.")
	if combat.standalone_map != null:
		combat._close_standalone_map()
	await settle()
	check(combat.controller.snapshot() == battle_before and combat.page_scroll.scroll_vertical == scroll_before, tag + " Navigation preserves actual prepared Combat and page scroll.")
	await _touch(combat_view, combat.combat_navigation.buttons.sound.get_global_rect().get_center())
	check(not combat.sound_enabled and combat.audio == combat_owner and combat.audio._ambience.player == combat_player, tag + " Native Combat Sound finger tap changes its existing owner without replacing playback.")
	_clear_pointer(combat_view)
	_clear_pointer(map_view)
	await settle()
	_compare(combat.combat_navigation, map_screen._navigation, dimensions, tag + "-sound-off")
	await _save_pair(combat_view, map_view, combat.combat_navigation, map_screen._navigation, tag + "-sound-off")
	await _mouse(combat_view, combat.combat_navigation.buttons.sound.get_global_rect().get_center())
	await _touch(map_view, map_screen._navigation.buttons.sound.get_global_rect().get_center())
	check(combat.sound_enabled and bool(app.audio_settings.enabled), tag + " Opposite input methods restore Sound once in both contexts.")
	check(combat.controller.snapshot() == battle_before and app.run_state.snapshot() == route_before, tag + " All native navigation actions preserve authoritative gameplay state.")
	combat.queue_free()
	app.queue_free()
	await settle()
	combat_view.queue_free()
	map_view.queue_free()
	await process_frame

func _compare(combat_bar: Control, map_bar: Control, dimensions: Vector2i, phase: String) -> void:
	var view_rect := Rect2(Vector2.ZERO, Vector2(dimensions))
	var expected_width := minf(640.0, dimensions.x - (16.0 if dimensions.x < 500 else 40.0))
	check(combat_bar.get_script().resource_path == SHARED_SCRIPT and map_bar.get_script().resource_path == SHARED_SCRIPT, phase + " Both real screens instantiate the same navigation component.")
	check(combat_bar._selected.is_empty() and map_bar._selected == "map" and map_bar.buttons.values().all(func(button): return not bool(button.get_meta("rc_states", {}).get("selected", false))), phase + " Logical Map identity adds no persistent selected-tab decoration.")
	check(combat_bar.size.is_equal_approx(map_bar.size) and combat_bar.size.is_equal_approx(Vector2(expected_width, 82)), phase + " Both bars retain Combat width and 82-pixel height.", {"combat": _rect(combat_bar.get_global_rect()), "map": _rect(map_bar.get_global_rect())})
	check(is_equal_approx(combat_bar.global_position.x, map_bar.global_position.x), phase + " Both bars have identical horizontal placement.")
	check(view_rect.encloses(combat_bar.get_global_rect()) and view_rect.encloses(map_bar.get_global_rect()), phase + " Both complete navigation bars are visible.")
	var combat_surface: Control = combat_bar.get_meta("combat_surface")
	var map_surface: Control = map_bar.get_meta("combat_surface")
	check(combat_surface.get_global_rect().is_equal_approx(combat_bar.get_global_rect()) and map_surface.get_global_rect().is_equal_approx(map_bar.get_global_rect()) and combat_surface.is_visible_in_tree() and map_surface.is_visible_in_tree(), phase + " Each painted frame visibly fills its container.")
	check(combat_surface.kind == "nav" and map_surface.kind == "nav" and combat_surface.divisions == 4 and map_surface.divisions == 4 and is_equal_approx(combat_surface.art_scale, map_surface.art_scale), phase + " Frame asset, four divisions and artwork scale match.")
	var record := {"phase": phase, "combat_bar": _rect(combat_bar.get_global_rect()), "map_bar": _rect(map_bar.get_global_rect()), "frame_scale": combat_surface.art_scale, "buttons": []}
	for key in KEYS:
		var a: Button = combat_bar.buttons[key]
		var b: Button = map_bar.buttons[key]
		var a_icon: TextureRect = a.get_meta("stacked_icon")
		var b_icon: TextureRect = b.get_meta("stacked_icon")
		var a_caption: Label = a.get_meta("navigation_caption")
		var b_caption: Label = b.get_meta("navigation_caption")
		check(_relative(a, combat_bar).is_equal_approx(_relative(b, map_bar)) and a.size.x >= 44 and a.size.y >= 44, phase + " " + key + " button geometry and touch area match.")
		check(_relative(a_icon, combat_bar).is_equal_approx(_relative(b_icon, map_bar)) and _glyph_rect(a_icon, combat_bar).is_equal_approx(_glyph_rect(b_icon, map_bar)), phase + " " + key + " icon lane and fitted glyph bounds match.")
		check(a_icon.texture == b_icon.texture and a_icon.material == b_icon.material and a_icon.stretch_mode == b_icon.stretch_mode, phase + " " + key + " icon asset and mask match.")
		check(_relative(a_caption, combat_bar).is_equal_approx(_relative(b_caption, map_bar)) and a_caption.text == b_caption.text, phase + " " + key + " live caption content and geometry match.")
		var a_font: FontVariation = a_caption.get_theme_font("font")
		var b_font: FontVariation = b_caption.get_theme_font("font")
		check(a_caption.get_theme_font_size("font_size") == b_caption.get_theme_font_size("font_size") and a_font.base_font == b_font.base_font and a_font.spacing_top == b_font.spacing_top and a_font.spacing_bottom == b_font.spacing_bottom and a_caption.get_theme_color("font_color") == b_caption.get_theme_color("font_color"), phase + " " + key + " visible font, size, spacing and colour match.")
		check(a.get_global_rect().encloses(a_caption.get_global_rect()) and b.get_global_rect().encloses(b_caption.get_global_rect()) and a_caption.get_visible_line_count() == 1 and b_caption.get_visible_line_count() == 1, phase + " " + key + " caption remains one visible line inside its button.")
		record.buttons.append({"id": key, "button": _rect(_relative(a, combat_bar)), "glyph": _rect(_glyph_rect(a_icon, combat_bar)), "caption": _rect(_relative(a_caption, combat_bar)), "font_size": a_caption.get_theme_font_size("font_size")})
	measurements.append(record)

func _relative(control: Control, origin: Control) -> Rect2:
	return Rect2(control.global_position - origin.global_position, control.size)

func _glyph_rect(control: TextureRect, origin: Control) -> Rect2:
	var extent := control.texture.get_size()
	extent *= minf(control.size.x / extent.x, control.size.y / extent.y)
	return Rect2(control.global_position - origin.global_position + (control.size - extent) / 2, extent)

func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

func _save_pair(combat_view: SubViewport, map_view: SubViewport, combat_bar: Control, map_bar: Control, tag: String) -> void:
	var images := [combat_view.get_texture().get_image(), map_view.get_texture().get_image()]
	for index in 2:
		check(images[index].save_png(destination.path_join(("combat-" if index == 0 else "map-") + tag + ".png")) == OK, tag + " Actual viewport PNG saved.")
	var full := _viewport(Vector2i(combat_view.size.x * 2 + 24, combat_view.size.y + 40))
	var bars := _viewport(Vector2i(int(combat_bar.size.x * 2) + 24, 122))
	for target in [full, bars]:
		var background := ColorRect.new()
		background.color = Color("101923")
		background.size = Vector2(target.size)
		target.add_child(background)
	for index in 2:
		var source := ImageTexture.create_from_image(images[index])
		for target in [full, bars]:
			var is_bar: bool = target == bars
			var image_width: float = combat_bar.size.x if is_bar else combat_view.size.x
			var origin := Vector2(index * (image_width + 24), 40)
			var picture := TextureRect.new()
			if is_bar:
				var region := AtlasTexture.new()
				region.atlas = source
				region.region = combat_bar.get_global_rect() if index == 0 else map_bar.get_global_rect()
				picture.texture = region
				picture.size = combat_bar.size
			else:
				picture.texture = source
				picture.size = Vector2(combat_view.size)
			picture.position = origin
			target.add_child(picture)
			var caption := Label.new()
			caption.text = "COMBAT" if index == 0 else "MAP"
			caption.position = origin - Vector2(-8, 33)
			caption.add_theme_font_size_override("font_size", 18)
			target.add_child(caption)
	await settle()
	for pair in [[full, "screens-"], [bars, "bars-"]]:
		check(pair[0].get_texture().get_image().save_png(destination.path_join(pair[1] + tag + ".png")) == OK, tag + " Actual screenshot comparison saved.")
	full.queue_free()
	bars.queue_free()
	await process_frame

func _clear_pointer(viewport: SubViewport) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2.ZERO
	viewport.push_input(motion, true)
	var focus := viewport.gui_get_focus_owner()
	if focus != null: focus.release_focus()

func _mouse(viewport: SubViewport, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func _touch(viewport: SubViewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func settle() -> void:
	for frame in 8: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
