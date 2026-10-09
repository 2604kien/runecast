extends RefCounted

const Experiments = preload("res://scripts/core/experiments.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")

func run_followup(check: Callable, tree: SceneTree, capture_path: String = "") -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://data/encounter.json"
	scene.experiment_mode = true
	scene.experiment_scenario = "effects"
	scene.experiment_variant = "free_endpoints"
	scene.experiment_record_path = "res://output/qa/rc-006-free-endpoint-records/ui-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	check.call(scene.controller != null and scene.game.experiment.version == "rc006_free_endpoints_v1", "Player-rotatable endpoint scene has a separate experimental identity.")
	var initial: Dictionary = scene.controller.snapshot()
	var opening := _endpoints(initial.board)
	check.call(_only_endpoints(initial.board) and opening.begin.cell != opening.end.cell, "Random opening contains exactly two distinct endpoints.")
	check.call(initial.hand.size() == 3 and initial.draw_pile.size() == 5 and initial.stock == {"split": 1, "join": 1}, "Random endpoint placement preserves opening cards and special-piece stock.")
	scene._show_guide()
	check.call(scene.dialog.dialog_text.contains("Click Begin or End, then Rotate") and not scene.dialog.dialog_text.contains("Protected endpoints and blocked cells cannot be edited"), "Guide describes the new endpoint rotation permission accurately.")
	scene.dialog.hide()
	scene._select_tool("straight")
	scene.cells[opening.begin.cell].pressed.emit()
	check.call(scene.selected_tool == "" and scene.selected_uid == -1 and scene.selected_cell == opening.begin.cell and scene.game.board == initial.board, "Clicking Begin while a tool is selected selects the endpoint without trying to replace it.")
	_press_edit(scene, "Rotate")
	check.call(scene.game.board[opening.begin.cell].rotation == (opening.begin.rotation + 1) % 4 and scene.game.undo_count == 1, "Normal Rotate button turns Begin clockwise and creates Undo history.")
	check.call(scene.cells[opening.begin.cell].piece.rotation == scene.game.board[opening.begin.cell].rotation and scene.status.text.contains("Use Rotate"), "Begin's rendered direction and selection guidance update together.")
	_press_edit(scene, "Undo")
	check.call(scene.game.board == initial.board and scene.game.hand == initial.hand and scene.game.undo_count == 0, "Normal Undo restores Begin's orientation without changing cards.")
	scene._select_card(initial.hand[0].uid)
	scene.cells[opening.end.cell].pressed.emit()
	_press_edit(scene, "Rotate")
	check.call(scene.game.board[opening.end.cell].rotation == (opening.end.rotation + 1) % 4 and scene.game.hand == initial.hand, "Clicking End after selecting a card permits Rotate without installing or losing the card.")
	_press_edit(scene, "Undo")
	check.call(scene.game.board == initial.board, "Undo restores End's orientation too.")
	_build_opening(scene, 42)
	check.call(not scene.cast_button.disabled and scene.game.forecast.damage == 6, "Normal controls rotate endpoints and construct a rune-bearing opening circuit.")
	scene.cast_button.pressed.emit()
	var next := _endpoints(scene.game.board)
	var next_hand: Array = scene.game.hand.duplicate(true)
	check.call(scene.game.turn == 2 and scene.game.enemy_hp == 30 and _only_endpoints(scene.game.board), "Cast clears the constructed board and starts the next turn.")
	check.call(next.begin.cell != opening.begin.cell and next.end.cell != opening.end.cell and scene.game.undo_count == 0, "Both new positions differ and old endpoint rotations cannot be undone across turns.")
	check.call(scene.cells.all(func(cell): return cell.piece == scene.game.board[cell.get_index()]) and scene.experiment_events.text.contains("Begin / End moved"), "Rendered endpoint positions and movement feedback follow the authoritative state.")
	scene.controller.add_note("AUTOMATED RC-006 FREE-ENDPOINT UI CHECK: no participant evidence")
	scene._inspect_experiment_record()
	check.call(scene.record_error.is_empty() and scene.record_text.text.contains("rc006_free_endpoints_v1") and scene.record_text.text.contains("endpoints_changed"), "Inspector exports the new version and relocation events.")
	scene.record_dialog.hide()
	scene.replay_button.pressed.emit()
	check.call(scene.controller.snapshot() == initial and scene.controller.record_document().totals.attempts == 0, "Exact replay reproduces random initial endpoint positions and directions.")
	_build_opening(scene, 42)
	scene.cast_button.pressed.emit()
	check.call(_endpoints(scene.game.board) == next and scene.game.hand == next_hand, "Replaying the construction reproduces next endpoints and card draw.")
	scene._open_menu()
	scene.pass_button.pressed.emit()
	scene.menu.hide()
	var passed := _endpoints(scene.game.board)
	check.call(scene.game.turn == 3 and _only_endpoints(scene.game.board) and passed.begin.cell != next.begin.cell and passed.end.cell != next.end.cell, "Menu Pass relocates both endpoints from an otherwise empty board.")
	scene.controller.add_note("AUTOMATED RC-006 FREE-ENDPOINT REPLAY/PASS CHECK: no participant evidence")
	scene._save_experiment_record()
	check.call(scene.record_error.is_empty() and scene.controller.record_document().totals.passes == 1, "Replay and Pass save through the normal recorder to an isolated automated path.")
	var adjacent_seed := _find_adjacent_seed()
	check.call(adjacent_seed >= 0, "Seeded random openings can produce adjacent endpoints.")
	if adjacent_seed >= 0:
		scene.seed_input.text = str(adjacent_seed)
		scene._launch_selected_experiment()
		var adjacent := _endpoints(scene.game.board)
		check.call(_distance(adjacent.begin.cell, adjacent.end.cell) == 1 and _only_endpoints(scene.game.board) and scene.experiment_seed == adjacent_seed, "Adjacent endpoints are visibly present after launching the selected seed.")
		scene.cells[adjacent.begin.cell].pressed.emit()
		_press_edit(scene, "Rotate")
		check.call(scene.game.board[adjacent.begin.cell].rotation == (adjacent.begin.rotation + 1) % 4, "Normal Rotate remains usable when the endpoints are adjacent.")
		if capture_path != "":
			await tree.process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
			check.call(scene.get_viewport().get_texture().get_image().save_png(capture_path) == OK, "Adjacent endpoint and manual-rotation screen capture saves.")
		scene.controller.add_note("AUTOMATED RC-006 ADJACENT-ENDPOINT UI CHECK: no participant evidence; seed %d" % adjacent_seed)
		scene._save_experiment_record()
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame

func _build_opening(scene: Control, seed_value: int) -> void:
	for action in Experiments.known_solution_actions("effects", "free_endpoints", seed_value):
		match action.command:
			"place_rune":
				scene._select_card(action.arguments.uid)
				scene.cells[action.arguments.index].pressed.emit()
			"place_wire":
				scene._select_tool(action.arguments.kind)
				scene.cells[action.arguments.index].pressed.emit()
			"rotate", "flip":
				scene.selected_cell = action.arguments.index
				_press_edit(scene, "Rotate" if action.command == "rotate" else "Flip")

func _press_edit(scene: Control, label: String) -> void:
	for button in scene.edit_buttons:
		if button.text == label:
			button.pressed.emit()
			return

func _find_adjacent_seed() -> int:
	var setup: Dictionary = Experiments.load_setup("effects", "free_endpoints", 42).setup
	for seed_value in range(128):
		var game := Combat.new(setup, seed_value)
		var endpoints := _endpoints(game.board)
		if _distance(endpoints.begin.cell, endpoints.end.cell) == 1:
			return seed_value
	return -1

func _distance(a: int, b: int) -> int:
	return absi(a % 4 - b % 4) + absi(a / 4 - b / 4)

func _only_endpoints(board: Array) -> bool:
	return board.filter(func(piece): return not piece.is_empty()).size() == 2 and _endpoints(board).size() == 2

func _endpoints(board: Array) -> Dictionary:
	var result := {}
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if piece.get("kind") in ["begin", "end"]:
			result[piece.kind] = {"cell": index, "rotation": piece.rotation}
	return result
