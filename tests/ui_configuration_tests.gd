extends RefCounted

func run(training: Control, check: Callable, tree: SceneTree) -> void:
	training._restart()
	check.call(training.startup_error == "" and training.encounter_title.text == "RUNE CAST   /   TRAINING CRYPT" and training.arena.enemy_name == "Shadeling", "The default screen retains the training title and Shadeling identity.")
	check.call(training.stats.text == "HEALTH 30 / 30       ENERGY 3 / 3       TURN 1" and training.stock_buttons.split.text == "Split\n0 / 1" and training.stock_buttons.join.text == "Join\n0 / 1", "Training labels preserve player stats and installed inventory accounting.")
	check.call(training.cast_button.tooltip_text.contains("12 damage") and training.cast_button.text.contains("1 energy"), "The unchanged training opening forecast is bound to the Cast control.")

	training.hide()
	var alternate: Control = load("res://scenes/main.tscn").instantiate()
	alternate.setup_path = "res://data/dev_encounter.json"
	tree.root.add_child(alternate)
	await tree.process_frame
	check.call(alternate.controller != null and alternate.game.encounter_content_id == "dev_calibration" and alternate.startup_error == "", "The actual scene creates the explicitly selected validated development setup.")
	check.call(alternate.stats.text == "HEALTH 24 / 40       ENERGY 4 / 4       TURN 1" and alternate.stats.tooltip_text.contains("draws 2 cards"), "The alternate scene displays configured health, energy maximum and draw help.")
	check.call(alternate.arena.enemy_name == "Calibration Wisp" and alternate.arena.enemy_hp == 45 and alternate.arena.enemy_max_hp == 45 and alternate.arena.attack == 3 and alternate.arena.tooltip_text.contains("Calibration Wisp: 45 / 45"), "Arena rendering data and tooltip identify the alternate enemy, health and attack.")
	check.call(alternate.encounter_title.text == "RUNE CAST   /   DEVELOPMENT FIXTURE" and alternate.encounter_title.tooltip_text.contains("test content"), "The alternate title and contextual help identify the development fixture.")
	check.call(alternate.stock_buttons.split.text == "Split\n2 / 2" and alternate.stock_buttons.join.text == "Join\n0 / 0" and alternate.stock_buttons.join.tooltip_text.contains("0 owned"), "Alternate inventory controls show configured available and owned totals.")
	check.call(alternate.hand_box.get_child_count() == 2 and alternate.hand_box.get_child(0).text.begins_with("Focus") and alternate.hand_box.get_child(1).text.begins_with("Shield") and alternate.hand_box.get_child(0).tooltip_text.contains("Draw up to 2 cards"), "The scene displays the alternate curated hand and value-aware technique tooltip.")
	check.call(alternate.cells[1].piece.rune_id == "spark" and alternate.cells[2].piece.kind == "straight" and alternate.cells[6].piece.is_empty() and alternate.cast_button.text.contains("2 energy"), "The alternate owned Spark and simple path reach the real board controls.")
	alternate._open_menu()
	check.call(alternate.menu.dialog_text.contains("DEVELOPMENT FIXTURE") and not alternate.menu.dialog_text.to_lower().contains("training"), "Restart help names the selected encounter.")
	alternate.menu.hide()
	alternate._show_map()
	check.call(alternate.dialog.dialog_text.contains("Calibration Wisp") and alternate.dialog.dialog_text.contains("test content") and not alternate.dialog.dialog_text.contains("Shadeling"), "Map describes the alternate fixture without claiming a training enemy.")
	alternate.dialog.hide()
	alternate._show_guide()
	check.call(alternate.dialog.dialog_text.contains("Two Splits and no Joins") and not alternate.dialog.dialog_text.contains("Shadeling"), "Guide includes selected setup help.")
	alternate.dialog.hide()
	alternate._select_tool("split")
	alternate._cell_pressed(4)
	check.call(alternate.stock_buttons.split.text == "Split\n1 / 2" and alternate.stock_buttons.split.tooltip_text.contains("1 installed"), "Installing a configured Split updates available inventory without changing its total.")
	alternate._undo()
	check.call(alternate.stock_buttons.split.text == "Split\n2 / 2" and alternate.cells[4].piece.is_empty(), "UI Undo restores configured stock and board placement.")
	alternate._select_tool("join")
	alternate._cell_pressed(4)
	check.call(alternate.cells[4].piece.is_empty() and alternate.status.text.contains("You own 0 join"), "A zero-owned Join cannot be installed through UI callbacks.")
	alternate._cast()
	check.call(alternate.game.enemy_hp == 39 and alternate.game.player_hp == 21 and alternate.game.turn == 2 and alternate.game.hand.size() == 2 and alternate.stats.text == "HEALTH 21 / 40       ENERGY 4 / 4       TURN 2" and alternate.arena.attack == 7, "Casting the alternate circuit updates visible configured combat, draw and next-intent values.")
	alternate.menu.confirmed.emit()
	check.call(alternate.game.encounter_content_id == "dev_calibration" and alternate.game.enemy_hp == 45 and alternate.game.player_hp == 24 and alternate.game.hand[0].id == "focus" and alternate.cells[1].piece.rune_id == "spark", "Menu Restart restores the selected alternate setup and owned installed card.")
	await _free_scene(alternate, tree)

	await _check_invalid("res://tests/fixtures/rc004-missing-encounter.json", "rc004-missing-encounter.json", check, tree)
	# Targeted file fixture; never modify shipped content to exercise failure.
	var invalid_path := "user://rc004-invalid-ui-encounter.json"
	var file := FileAccess.open(invalid_path, FileAccess.WRITE)
	file.store_string('{"id":"invalid_ui","enemy_id":"missing_enemy","board_id":"board_training","loadout_id":"starter","title":"Invalid fixture","help_text":"Deliberately missing enemy reference."}')
	file.close()
	await _check_invalid(invalid_path, "enemy_id", check, tree)
	DirAccess.remove_absolute(invalid_path)
	training.show()

func _check_invalid(path: String, diagnostic: String, check: Callable, tree: SceneTree) -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = path
	tree.root.add_child(scene)
	await tree.process_frame
	check.call(scene.controller == null and scene.game.is_empty() and scene.startup_error.contains(diagnostic), "Invalid startup rejects content before any battle/controller creation: " + path)
	check.call(scene.status.text.contains(diagnostic) and scene.status.tooltip_text == scene.startup_error and scene.encounter_title.text.contains("CONTENT ERROR"), "Invalid startup shows a useful diagnostic in visible feedback and its full tooltip: " + path)
	var all_disabled: bool = scene.cast_button.disabled and scene.pass_button.disabled and scene.menu.get_ok_button().disabled and scene.hand_box.get_child_count() == 0
	for cell in scene.cells:
		all_disabled = all_disabled and cell.disabled
	for button in scene.edit_buttons:
		all_disabled = all_disabled and button.disabled
	check.call(all_disabled, "Invalid startup disables every gameplay control, including Restart: " + path)
	scene.cast_button.pressed.emit()
	scene.menu.custom_action.emit("pass")
	scene.menu.confirmed.emit()
	scene._select_tool("straight")
	scene._select_card(1)
	scene.cells[1].pressed.emit()
	scene._rotate()
	scene._flip()
	scene._undo()
	check.call(scene.controller == null and scene.game.is_empty() and scene.selected_tool == "" and scene.selected_cell == -1, "Direct callbacks cannot start a fallback or mutate an invalid screen: " + path)
	scene._open_menu()
	check.call(scene.menu.visible and scene.menu.dialog_text.contains(diagnostic), "Menu remains available and shows the invalid configuration reason: " + path)
	scene.menu.hide()
	scene._show_map()
	check.call(scene.dialog.visible and scene.dialog.dialog_text.contains(diagnostic), "Read-only navigation remains available after invalid startup: " + path)
	scene.dialog.hide()
	await _free_scene(scene, tree)

func _free_scene(scene: Control, tree: SceneTree) -> void:
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame
