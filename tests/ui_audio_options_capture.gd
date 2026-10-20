extends SceneTree
## Actual main-scene Options capture and bounds checks; no user settings writes.
const DESTINATION := "res://output/qa/rc-020/options"
var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture(dimensions)
	# Let the native mixer release the final freed scene's stopped playback.
	await create_timer(0.2).timeout
	var report := FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions,
		"engine": Engine.get_version_info().string, "scope": "Actual reusable Options in the playable Combat scene, native logical sizes. Bounds/scroll/fixed-close verification and desktop renders; not physical-device acceptance."}, "  ") + "\n")
	print("%d Options layout checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _capture(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = DESTINATION.path_join("unused-readonly-settings.cfg")
	viewport.add_child(scene)
	scene.sound_enabled = false
	await _settle()
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	scene._open_menu()
	await _settle()
	_check(scene.menu.size.x <= dimensions.x and scene.menu.size.y <= dimensions.y, tag + " Menu including Options stays inside the viewport: " + str(scene.menu.size))
	for button in [scene.options_button, scene.menu.get_ok_button(), scene.menu.get_cancel_button(), scene.production_replay_button]:
		_check(button.is_visible_in_tree() and button.position.x >= 0 and button.get_global_rect().end.x <= scene.menu.size.x, tag + " Menu exposes " + button.text)
	await _save(viewport, "menu-" + tag)
	scene.menu.custom_action.emit("options")
	await _settle()
	var panel: PanelContainer = scene.options.panel
	var close: Button = scene.options.close_button
	_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(panel.get_global_rect()), tag + " Options panel fits in the actual viewport.")
	_check(panel.get_global_rect().encloses(close.get_global_rect()) and close.size.y >= 44, tag + " Options Close remains reachable outside the body scroll.")
	for slider in scene.options.sliders.values():
		_check(slider.size.y >= 44 and slider.size.x <= panel.size.x - 32, tag + " volume slider keeps a full-size hit area and fits panel width.")
	await _save(viewport, "options-top-" + tag)
	scene.options.body_scroll.scroll_vertical = 10000
	await _settle()
	_check(scene.options.body_scroll.get_global_rect().encloses(scene.options.toggles.reduced_motion.get_global_rect()), tag + " scrolling exposes reduced motion.")
	_check(panel.get_global_rect().encloses(close.get_global_rect()), tag + " Close stays fixed after scrolling.")
	await _save(viewport, "options-bottom-" + tag)
	scene.audio.dispose()
	viewport.queue_free()
	await process_frame

func _settle() -> void:
	for frame in 5: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func _save(viewport: SubViewport, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	_check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + " render saves.")
