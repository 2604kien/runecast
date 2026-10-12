extends SceneTree

# Actual desktop rendering and synthetic input, not physical-device testing.
const DESTINATION := "res://output/qa/rc-016a/final-ui"
var checks := 0
var failures := 0
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	await preload("res://tests/ui_touch_tests.gd").new().run_followup(_check, self, DESTINATION.path_join("touch"))
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture_layout(dimensions)
	var report := {"checks": checks, "failures": failures, "captures": captures,
		"renderer": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info().string,
		"scope": "Actual Godot scene; desktop viewport rendering and synthetic touch/keyboard. No physical device test."}
	var file := FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-016A rendered UI checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _capture_layout(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.board_example_id = "board_belfry"
	viewport.add_child(scene)
	scene.sound_enabled = false
	await _layout()
	_check(scene.startup_error.is_empty() and scene.cells.all(func(cell): return cell.clean_board), "Belfry loads with the production clean board.")
	_check(scene.game.forecast.damage == 12 and scene.game.forecast.shield == 5 and scene.game.forecast.cost == 2 and scene.forecast_values.incoming == 3, "Independent Belfry forecast is12/5/2 with3 incoming.")
	var suffix := "%dx%d" % [dimensions.x, dimensions.y]
	await _save(viewport, "built-top-" + suffix)
	scene.page_scroll.scroll_vertical += int(scene.cells[0].get_global_rect().position.y) - 32
	await _save(viewport, "board-" + suffix)
	scene.page_scroll.ensure_control_visible(scene.hand_scroll)
	await _save(viewport, "hand-" + suffix)
	scene.page_scroll.scroll_vertical = 100000
	await _save(viewport, "forecast-" + suffix)
	var before: Dictionary = scene.controller.snapshot()
	scene._request_pass()
	await _save(viewport, "pass-" + suffix)
	_check(scene.inspector_confirm_pass.visible and scene.controller.snapshot() == before, "Visible Pass opens a read-only confirmation.")
	scene._close_inspector()
	# Deliberate QA affordability boundary; never changes shipped balance/data.
	scene.controller._combat.energy = 1
	scene._refresh()
	scene.page_scroll.scroll_vertical = 100000
	_check(scene.cast_button.disabled and scene.forecast_values.cost == 2 and scene.forecast_reason.text.contains("have 1"), "An unaffordable spell remains an explicitly labelled preview and disables Cast.")
	await _save(viewport, "unaffordable-" + suffix)
	scene.player.stop()
	scene.player.stream = null
	viewport.queue_free()
	await process_frame

func _layout() -> void:
	for frame in range(4): await process_frame

func _save(viewport: SubViewport, name_text: String) -> void:
	await _layout()
	await RenderingServer.frame_post_draw
	var path := DESTINATION.path_join(name_text + ".png")
	_check(viewport.get_texture().get_image().save_png(path) == OK, "Saved actual rendered " + name_text)
	captures.append(path)
