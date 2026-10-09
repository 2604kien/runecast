extends RefCounted

const Experiments = preload("res://scripts/core/experiments.gd")

func run_followup(check: Callable, tree: SceneTree, capture_path: String = "") -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://data/encounter.json"
	scene.experiment_mode = true
	scene.experiment_scenario = "effects"
	scene.experiment_variant = "moving_endpoints"
	scene.experiment_record_path = "res://output/qa/rc-006-moving-endpoint-records/ui-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	check.call(scene.controller != null and scene.game.experiment.version == "rc006_moving_endpoints_v1", "Moving-endpoint scene has a distinct version and record identity.")
	check.call(not scene.experiment_label.tooltip_text.contains("endpoint_layouts") and not scene.experiment_label.tooltip_text.contains("\"path\""), "Normal participant help does not reveal the catalog's solution paths.")
	var initial: Dictionary = scene.controller.snapshot()
	var opening := _endpoints(initial.board)
	check.call(_only_endpoints(initial.board) and opening.begin.cell == 0 and opening.end.cell == 14 and scene.cast_button.disabled, "Controlled first turn starts with endpoints only at the original positions.")
	_build_opening(scene)
	check.call(not scene.cast_button.disabled and scene.game.forecast.damage == 6, "Existing UI tools construct an affordable opening cast.")
	scene.cast_button.pressed.emit()
	var moved := _endpoints(scene.game.board)
	var hand: Array = scene.game.hand.duplicate(true)
	check.call(scene.game.turn == 2 and scene.game.enemy_hp == 30 and _only_endpoints(scene.game.board), "Cast resolves damage then leaves only the new endpoints.")
	check.call(moved.begin.cell != opening.begin.cell and moved.end.cell != opening.end.cell, "Both endpoint positions change on the first surviving turn transition.")
	check.call(scene.cells.all(func(cell): return cell.piece == scene.game.board[cell.get_index()]), "Rendered cells match authoritative moved positions and rotations.")
	check.call(scene.experiment_events.text.contains("cleared 4 cells") and scene.experiment_events.text.contains("Begin / End moved") and not scene.experiment_events.text.contains("kept"), "Latest feedback describes clearing and endpoint movement accurately.")
	check.call(scene.cast_button.disabled and scene.game.hand.size() == 3 and scene.game.undo_count == 0, "Next turn needs reconstruction and has a fresh hand with no old Undo history.")
	if capture_path != "":
		await tree.process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		check.call(scene.get_viewport().get_texture().get_image().save_png(capture_path) == OK, "Moved and rotated endpoint screen capture saves successfully.")
	var protected_board: Array = scene.game.board.duplicate(true)
	scene.selected_cell = moved.begin.cell
	scene._rotate()
	scene.selected_cell = moved.end.cell
	scene._rotate()
	check.call(scene.game.board == protected_board, "UI Rotate cannot change game-selected endpoints during the turn.")
	var old_cell: int = opening.begin.cell if not opening.begin.cell in [moved.begin.cell, moved.end.cell] else opening.end.cell
	if not old_cell in [moved.begin.cell, moved.end.cell]:
		scene._select_tool("straight")
		scene.cells[old_cell].pressed.emit()
		check.call(scene.game.board[old_cell].get("kind") == "straight", "A vacated original endpoint cell is available for circuit construction.")
	scene.controller.add_note("AUTOMATED RC-006 MOVING-ENDPOINT UI CHECK: no participant evidence")
	scene._inspect_experiment_record()
	check.call(scene.record_dialog.visible and scene.record_error.is_empty() and scene.record_text.text.contains("endpoints_changed") and scene.record_text.text.contains("rc006_moving_endpoints_v1"), "Inspector exports relocation events and the distinct version.")
	scene.record_dialog.hide()
	scene.replay_button.pressed.emit()
	check.call(scene.controller.snapshot() == initial and scene.controller.record_document().totals.attempts == 0, "Exact replay restores the controlled opening and fresh recorder.")
	_build_opening(scene)
	scene.cast_button.pressed.emit()
	check.call(_endpoints(scene.game.board) == moved and scene.game.hand == hand, "Identical replay reproduces endpoint selection and hand through scene controls.")
	scene._open_menu()
	scene.pass_button.pressed.emit()
	scene.menu.hide()
	var passed := _endpoints(scene.game.board)
	check.call(scene.game.turn == 3 and _only_endpoints(scene.game.board) and passed.begin.cell != moved.begin.cell and passed.end.cell != moved.end.cell, "Menu Pass from an empty board moves both endpoints for the next turn.")
	check.call(scene.experiment_events.text.contains("Begin / End moved"), "An empty-board Pass still explains endpoint movement.")
	scene.controller.add_note("AUTOMATED RC-006 MOVING-ENDPOINT REPLAY/PASS CHECK: no participant evidence")
	scene._save_experiment_record()
	check.call(scene.record_error.is_empty() and scene.controller.record_document().totals.passes == 1, "Automated replay and Pass are saved to a dedicated record path.")
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame

func _build_opening(scene: Control) -> void:
	for action in Experiments.known_solution_actions("effects", "moving_endpoints"):
		match action.command:
			"place_rune":
				scene._select_card(action.arguments.uid)
				scene.cells[action.arguments.index].pressed.emit()
			"place_wire":
				scene._select_tool(action.arguments.kind)
				scene.cells[action.arguments.index].pressed.emit()
			"rotate":
				scene.selected_cell = action.arguments.index
				scene._rotate()

func _only_endpoints(board: Array) -> bool:
	return board.filter(func(piece): return not piece.is_empty()).size() == 2 and _endpoints(board).size() == 2

func _endpoints(board: Array) -> Dictionary:
	var result := {}
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if piece.get("kind") in ["begin", "end"]:
			result[piece.kind] = {"cell": index, "rotation": piece.rotation}
	return result
