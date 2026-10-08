extends SceneTree
var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(scene.cells.size() == 16 and not scene.cast_button.disabled, "The screen opens with sixteen cells and a castable circuit.")
	scene._select_card(scene.game.hand[0].uid)
	scene.cells[1].pressed.emit()
	check(scene.game.board[1].rune_id == "spark" and scene.cast_button.text.contains("3 energy"), "A hand rune can be installed through the UI and updates casting cost.")
	scene.cast_button.pressed.emit()
	check(scene.game.enemy_hp == 20 and scene.game.turn == 2, "The Cast button resolves the encounter turn.")
	scene._select_tool("erase")
	scene.cells[3].pressed.emit()
	check(scene.cast_button.disabled, "Breaking a branch disables the Cast button.")
	scene._undo()
	check(scene.game.board[3].kind == "corner", "UI Undo restores the removed piece.")
	scene._open_menu()
	check(scene.menu.visible, "Menu opens.")
	scene.menu.hide()
	scene._show_map()
	check(scene.dialog.visible and scene.dialog.dialog_text.contains("One encounter"), "Map identifies the limited prototype scope.")
	scene.dialog.hide()
	scene._show_guide()
	check(scene.dialog.visible and scene.dialog.dialog_text.contains("Split"), "Guide explains the circuit.")
	scene.dialog.hide()
	var original_sound: bool = scene.sound_enabled
	scene._toggle_sound()
	var settings := ConfigFile.new()
	check(settings.load("user://settings.cfg") == OK and settings.get_value("audio", "enabled") == not original_sound, "Sound toggles and persists.")
	scene._toggle_sound()
	check(scene.sound_enabled == original_sound, "Sound preference is restored after the smoke check.")
	scene._restart()
	check(scene.game.turn == 1 and scene.game.enemy_hp == 32 and scene.game.player_hp == 30, "Restart returns to the opening encounter.")
	await preload("res://tests/ui_presentation_tests.gd").new().run(scene, check, self)
	await process_frame
	print("%d UI checks, %d failures" % [checks, failures])
	scene.player.stop()
	scene.player.stream = null
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

