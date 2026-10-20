extends SceneTree
## Actual application captures at native logical portrait sizes, not mockups.
const DESTINATION := "res://output/qa/rc-024/screenshots"
var checks := 0
var failures := 0
var assertions: Array = []

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
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture(dimensions)
	await create_timer(0.2).timeout
	var file := FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions,
		"engine": Engine.get_version_info().string, "scope": "Actual desktop renders at native logical sizes; no physical-device acceptance."}, "  ") + "\n")
	print("%d RC-024 capture checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _capture(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("capture-settings.cfg")
	var settings := preload("res://scripts/audio/audio_settings.gd")
	var values: Dictionary = settings.DEFAULTS.duplicate(true)
	values.enabled = false
	settings.save_values(values, app.settings_path)
	viewport.add_child(app)
	await settle()
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	for button in [app.continue_button, app.new_run_button, app.options_button]:
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Home control is reachable: " + button.text)
	await save(viewport, "home-" + tag)
	app.open_options()
	await settle()
	check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(app.options.panel.get_global_rect()), tag + " Home Options fits the portrait viewport.")
	check(app.options.panel.get_global_rect().encloses(app.options.close_button.get_global_rect()), tag + " Home Options Close stays reachable.")
	await save(viewport, "home-options-" + tag)
	app.close_options()
	app.request_new_run(294)
	await settle()
	check(app.combat_scene != null and app.combat_scene.cells.size() == 16, tag + " New Run enters the original sixteen-cell Combat scene.")
	await save(viewport, "combat-entry-" + tag)
	app.combat_scene.page_scroll.scroll_vertical = 100000
	await settle()
	await save(viewport, "combat-controls-" + tag)
	app.combat_scene._open_menu()
	await settle()
	check(app.combat_scene.menu.size.x <= dimensions.x and app.combat_scene.menu.size.y <= dimensions.y, tag + " Session Combat Menu fits the viewport.")
	for button in [app.combat_scene.home_button, app.combat_scene.options_button, app.combat_scene.menu.get_cancel_button()]:
		check(button.is_visible_in_tree() and button.size.y >= 44 and Rect2(Vector2.ZERO, Vector2(app.combat_scene.menu.size)).encloses(button.get_global_rect()), tag + " Session Menu exposes a touch-sized " + button.text)
	await save(viewport, "combat-menu-" + tag)
	app.combat_scene.menu.hide()
	app.request_home()
	await settle()
	check(app.confirmation.visible, tag + " Quit explains entry-checkpoint replay.")
	check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(app._confirmation_panel.get_global_rect()) and app._confirmation_panel.size.y <= minf(440.0, dimensions.y - 32.0), tag + " Quit panel fits and returns to its intended bounded height after text wraps.")
	for button in [app.confirmation_confirm, app.confirmation_cancel]:
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Quit confirmation control is reachable: " + button.text)
	await save(viewport, "quit-confirmation-" + tag)
	app.confirm_home()
	await settle()
	check(app.home.visible and app.combat_scene == null and not app.continue_button.disabled, tag + " Returned Home exposes session-only Continue.")
	await save(viewport, "returned-home-" + tag)
	app.request_new_run(39)
	await settle()
	check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(app._confirmation_panel.get_global_rect()) and app._confirmation_panel.size.y <= minf(440.0, dimensions.y - 32.0), tag + " New Run panel fits after text wraps.")
	for button in [app.confirmation_confirm, app.confirmation_cancel]:
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()), tag + " Replacement confirmation fits: " + button.text)
	await save(viewport, "new-run-confirmation-" + tag)
	app.cancel_confirmation()
	app.queue_free()
	await settle()
	viewport.queue_free()
	await process_frame

func settle() -> void:
	for frame in 8: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(viewport: SubViewport, file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		check(false, "Captures require a rendering display.")
		return
	check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(file_name + ".png")) == OK, file_name + " PNG saved.")
