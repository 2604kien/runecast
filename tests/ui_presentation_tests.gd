extends RefCounted

const Delayed = preload("res://tests/delayed_presentation.gd")

func run(scene: Control, check: Callable, tree: SceneTree) -> void:
	var original_log: String = scene.game.log_text
	scene._select_tool("corner")
	check.call(scene.status.text.contains("place corner") and scene.controller.snapshot().log_text == original_log, "Tool selection help stays in the view without mutating combat feedback.")
	scene._select_card(scene.game.hand[0].uid)
	check.call(scene.status.text.contains("install Spark") and scene.controller.snapshot().log_text == original_log, "Rune selection help stays in the view.")
	for attempt in range(2):
		scene._select_tool("split")
		scene._cell_pressed(4)
		check.call(scene.status.text.contains("You own one split"), "Rejected inventory edits replace selection help, including repeated attempts.")
	scene._restart()
	scene._select_tool("straight")
	scene._cell_pressed(12)
	scene._rotate()
	scene._flip()
	check.call(scene.game.board[12].rotation == 1 and scene.game.board[12].reversed, "Rotate and Flip route selected-cell edits through the controller.")
	scene._undo()
	check.call(not scene.game.board[12].get("reversed", false) and scene.game.board[12].rotation == 1, "UI Undo preserves the preceding rotation.")
	scene._restart()
	var model_before: Dictionary = scene.controller.snapshot()
	scene.cells[1].piece.rune_id = "shield"
	scene.cells[1].catalog.spark.cost = 999
	scene.game.hand.clear()
	check.call(scene.controller.snapshot() == model_before, "View controls cannot mutate authoritative board, hand or catalog through references.")
	# Restore the deliberately changed local drawing catalog.
	for cell in scene.cells:
		cell.catalog = scene.controller.snapshot().catalog
	scene._refresh()
	var presenter := Delayed.new()
	check.call(scene.controller.set_presenter(presenter), "A controlled delayed presenter can replace the immediate presenter while idle.")
	scene.cast_button.pressed.emit()
	var pending: Dictionary = scene.controller.snapshot()
	check.call(scene.controller.is_busy() and scene.cast_button.disabled and scene.pass_button.disabled and scene.cells[3].disabled and pending.player_hp == 22, "A delayed Cast resolves once and visibly disables gameplay controls.")
	var technique_uid := -1
	for card in pending.hand:
		if pending.catalog[card.id].type == "technique":
			technique_uid = card.uid
	check.call(technique_uid != -1, "The delayed fixture contains a real playable technique.")
	scene.cast_button.pressed.emit()
	scene.menu.custom_action.emit("pass")
	scene._select_card(technique_uid)
	scene._select_tool("erase")
	scene.cells[3].pressed.emit()
	scene._rotate()
	scene._flip()
	scene._undo()
	check.call(scene.controller.snapshot() == pending and presenter.batches.size() == 1, "Direct UI callbacks and repeated signals cannot bypass pending presentation guards.")
	scene._open_menu()
	check.call(scene.menu.visible, "Menu remains available during presentation.")
	scene.menu.hide()
	scene._show_map()
	check.call(scene.dialog.visible, "Read-only Map remains available during presentation.")
	scene.dialog.hide()
	scene._show_guide()
	check.call(scene.dialog.visible, "Guide remains available during presentation.")
	scene.dialog.hide()
	var sound_before: bool = scene.sound_enabled
	scene._toggle_sound()
	scene._toggle_sound()
	check.call(scene.sound_enabled == sound_before and scene.controller.is_busy() and scene.controller.snapshot() == pending, "Sound controls remain independent of the pending action.")
	presenter.complete()
	presenter.complete()
	check.call(not scene.controller.is_busy() and not scene.cast_button.disabled and scene.game == pending, "Completing twice unlocks the UI without resolving another action.")
	scene._select_card(technique_uid)
	check.call(scene.controller.is_busy() and presenter.batches.back().command == "technique", "Technique input also waits for delayed completion.")
	scene.menu.confirmed.emit()
	var restarted: Dictionary = scene.controller.snapshot()
	presenter.complete()
	check.call(not scene.controller.is_busy() and scene.game.turn == 1 and scene.controller.snapshot() == restarted and presenter.cancellations == 1, "Menu Restart cancels pending presentation before resetting; late completion is harmless.")
	scene.menu.custom_action.emit("pass")
	check.call(scene.controller.is_busy() and scene.game.enemy_hp == 32 and scene.game.player_hp == 22 and presenter.batches.back().command == "pass", "Menu Pass goes through the same guarded presentation boundary without damaging the enemy.")
	presenter.complete()
	scene._restart()
	scene._select_tool("erase")
	scene._cell_pressed(3)
	scene._cast()
	check.call(not scene.controller.is_busy() and scene.game.turn == 1, "An invalid UI cast releases its guard and preserves the turn.")
	scene._restart()
	# A separate real scene demonstrates _exit_tree, not just controller.dispose().
	var removed: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(removed)
	var delayed_teardown := Delayed.new()
	removed.controller.set_presenter(delayed_teardown)
	removed._cast()
	var closed_controller = removed.controller
	var state_at_exit: Dictionary = closed_controller.snapshot()
	removed.player.stop()
	removed.player.stream = null
	removed.queue_free()
	await tree.process_frame
	delayed_teardown.complete()
	check.call(delayed_teardown.cancellations == 1 and not closed_controller.is_busy() and not closed_controller.can_edit() and closed_controller.snapshot() == state_at_exit, "Actual scene teardown cancels pending work and late completion cannot update a replacement encounter.")
