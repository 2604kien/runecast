extends RefCounted

const Experiments = preload("res://scripts/core/experiments.gd")

func run_followup(check: Callable, tree: SceneTree) -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://data/encounter.json"
	scene.experiment_mode = true
	scene.experiment_scenario = "effects"
	scene.experiment_variant = "full_reset"
	scene.experiment_record_path = "res://output/qa/rc-006-full-reset-records/ui-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	await run(scene, check, tree)
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame

# Caller supplies a dedicated automated record path before adding the scene.
func run(scene: Control, check: Callable, tree: SceneTree) -> void:
	check.call(scene.controller != null and scene.experiment_variant == "full_reset" and scene.game.experiment.version == "rc006_full_reset_v1", "Full-reset launch exposes its separate study identity.")
	check.call(_empty_board(scene.game.board) and scene.cast_button.disabled and not scene.pass_button.disabled, "Only endpoints are visible initially; Cast needs construction and Pass remains available.")
	check.call(scene.game.hand.size() == 3 and scene.game.draw_pile.size() == 5 and scene.game.stock == {"split": 1, "join": 1}, "Full-reset UI starts with normal curated cards and available special pieces.")
	var initial: Dictionary = scene.controller.snapshot()
	for action in Experiments.known_solution_actions("effects", "full_reset"):
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
	check.call(not scene.cast_button.disabled and scene.game.forecast.damage == 6, "A player-built example becomes castable through existing UI controls.")
	scene.cast_button.pressed.emit()
	check.call(_empty_board(scene.game.board) and scene.game.turn == 2 and scene.game.enemy_hp == 30 and scene.game.hand.size() == 3, "UI Cast resolves damage, clears the board and draws the next hand.")
	check.call(scene.cells.all(func(cell): return cell.piece.is_empty() or cell.piece.get("kind") in ["begin", "end"]), "Rendered cell snapshots clear with authoritative state.")
	check.call(scene.cast_button.disabled and scene.experiment_events.text.contains("cleared 4 cells"), "Post-Cast controls require reconstruction and compact feedback explains cleanup.")
	scene.controller.add_note("AUTOMATED RC-006 UI CHECK: no participant evidence")
	scene._inspect_experiment_record()
	check.call(scene.record_dialog.visible and scene.record_text.text.contains("rc006_full_reset_v1") and scene.record_text.text.contains("board_piece_cleared") and scene.record_error.is_empty(), "Export/inspection preserves new version and ordered cleanup events.")
	scene.record_dialog.hide()
	scene.replay_button.pressed.emit()
	check.call(scene.controller.snapshot() == initial and scene.controller.record_document().totals.attempts == 0, "Exact replay restores identical endpoints-only state and fresh metrics.")
	scene._select_card(scene.game.hand[1].uid)
	scene.cells[8].pressed.emit()
	scene._select_tool("split")
	scene.cells[5].pressed.emit()
	scene._open_menu()
	scene.pass_button.pressed.emit()
	check.call(_empty_board(scene.game.board) and scene.game.turn == 2 and scene.game.stock.split == 1 and scene.game.undo_count == 0, "Menu Pass clears disconnected runes and special pieces, restores stock and clears Undo.")
	scene.menu.hide()
	scene.controller.add_note("AUTOMATED RC-006 UI PASS CHECK: no participant evidence")
	scene._save_experiment_record()
	check.call(scene.record_error.is_empty() and scene.controller.record_document().totals.passes == 1, "Pass follow-up record is saved without a synthesized Cast.")
	await tree.process_frame

func _empty_board(board: Array) -> bool:
	return board.filter(func(piece): return not piece.is_empty()).size() == 2 and board[0].get("kind") == "begin" and board[14].get("kind") == "end"
