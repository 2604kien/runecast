extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

# This opt-in fixture tests confirmed finite editing separately from unresolved
# production setup, turn cleanup, costs and RNG policies.
func run_followup(check: Callable, tree: SceneTree, capture_path: String = "") -> void:
	var documents := {}
	for kind in ["runes", "boards", "enemies", "loadouts", "encounter"]:
		documents[kind] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % kind))
	documents.loadouts[0].inventory = {"straight": 6, "corner": 2, "split": 1, "join": 1}
	documents.boards[0].placements = [{"cell": 0, "kind": "begin"}, {"cell": 14, "kind": "end"}]
	documents.encounter.title = "FINITE STOCK QA"
	documents.encounter.help_text = "Automated finite connector editing fixture. Turn setup and cleanup are not production selections."
	documents.encounter.opening_log = "Finite editing fixture: six Straights, two Corners, one Split and one Join."
	var loaded := Loader.validate_documents(documents)
	check.call(loaded.ok, "Finite connector UI fixture validates before creating its authoritative model.")
	if not loaded.ok:
		return
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://data/encounter.json"
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	check.call(scene.stock_buttons.straight.text == "Straight\nUnlimited" and scene.stock_buttons.corner.text == "Corner\nUnlimited", "Historical normal setup retains its explicit unlimited basic-wire labels.")
	# Keep the shipped UI and handlers, injecting only an independently validated
	# model so the fixture does not change shipped content or write study records.
	scene.controller.dispose()
	scene.controller = Controller.new(Combat.new(loaded.setup))
	scene.controller.changed.connect(scene._refresh)
	scene.controller.presentation_started.connect(scene._presentation_started)
	scene._clear_selection()
	scene._refresh()
	check.call(_labels_match(scene) and not scene.experiment_mode and scene.controller.get_record() == null, "All four finite quantities render in the normal UI without experiment controls or observations.")
	scene._show_guide()
	check.call(scene.dialog.dialog_text.contains("Straight, Corner, Split and Join show available / total quantities") and scene.dialog.dialog_text.contains("including disconnected pieces") and scene.dialog.dialog_text.contains("Erase or replacement returns the displaced connector") and scene.dialog.dialog_text.contains("Undo restores the board, hand and connector supply together"), "Finite-inventory Guide describes actual availability, disconnected reservation, refunds and Undo.")
	scene.dialog.hide()
	for kind in ["straight", "corner", "split", "join"]:
		scene._restart()
		var total: int = scene.game.stock_totals[kind]
		scene.stock_buttons[kind].pressed.emit()
		for index in range(1, total + 1):
			scene.cells[index].pressed.emit()
		check.call(scene.game.stock[kind] == 0 and _labels_match(scene) and scene.stock_buttons[kind].text == "%s\n0 / %d" % [kind.capitalize(), total], "Actual %s tool/cell inputs consume finite stock, including disconnected pieces." % kind)
		var exhausted: Dictionary = scene.controller.snapshot()
		scene.cells[13].pressed.emit()
		var rejected: Dictionary = scene.controller.snapshot()
		check.call(rejected.board == exhausted.board and rejected.hand == exhausted.hand and rejected.stock == exhausted.stock and rejected.undo_count == exhausted.undo_count and scene.status.text.contains("You own %d %s" % [total, kind]) and _labels_match(scene), "Exhausted %s placement rejects without changing board, hand, inventory or Undo, with visible feedback." % kind)
		scene._clear_selection()
		scene.cells[1].pressed.emit()
		_press_edit(scene, "Rotate")
		check.call(scene.game.board[1].rotation == 1 and scene.game.stock == exhausted.stock and _labels_match(scene), "Rotating installed %s preserves all displayed connector quantities." % kind)
		_press_edit(scene, "Undo")
		check.call(scene.game.board == exhausted.board and _labels_match(scene), "Undo restores %s orientation and finite labels together." % kind)
		if kind in ["straight", "corner"]:
			scene.cells[1].pressed.emit()
			_press_edit(scene, "Flip")
			check.call(scene.game.board[1].get("reversed", false) and scene.game.stock == exhausted.stock and _labels_match(scene), "Flipping %s changes direction without spending stock." % kind)
			_press_edit(scene, "Undo")
		_press_edit(scene, "Erase")
		scene.cells[1].pressed.emit()
		check.call(scene.game.board[1].is_empty() and scene.game.stock[kind] == 1 and _labels_match(scene), "Erasing %s returns one piece to its displayed supply." % kind)
		_press_edit(scene, "Undo")
		check.call(scene.game.board == exhausted.board and scene.game.stock[kind] == 0 and _labels_match(scene), "Undo of %s erase reinstalls its reserved piece without creating stock." % kind)
		var replacement: String = "corner" if kind == "straight" else "straight"
		var replacement_before: int = scene.game.stock[replacement]
		scene.stock_buttons[replacement].pressed.emit()
		scene.cells[1].pressed.emit()
		check.call(scene.game.stock[kind] == 1 and scene.game.stock[replacement] == replacement_before - 1 and _labels_match(scene), "Replacing %s refunds it and reserves the replacement's own type." % kind)
		_press_edit(scene, "Undo")
		var hand_before: Array = scene.game.hand.duplicate(true)
		var spark_uid: int = hand_before[0].uid
		scene.hand_box.get_child(0).pressed.emit()
		scene.cells[1].pressed.emit()
		check.call(scene.game.board[1].get("uid") == spark_uid and scene.game.stock[kind] == 1 and scene.game.hand.size() == hand_before.size() - 1 and _labels_match(scene), "Installing a rune over %s returns the displaced connector and updates hand/stock controls." % kind)
		_press_edit(scene, "Undo")
		check.call(scene.game.board == exhausted.board and scene.game.hand == hand_before and scene.game.stock[kind] == 0 and _labels_match(scene), "Rune-displacement Undo restores the %s board, hand instance and quantities together." % kind)
	if capture_path != "":
		scene._restart()
		scene.stock_buttons.straight.pressed.emit()
		scene.cells[12].pressed.emit()
		scene._clear_selection()
		scene._refresh()
		await tree.process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		var capture_error: Error = scene.get_viewport().get_texture().get_image().save_png(capture_path)
		check.call(capture_error == OK, "Fresh finite connector UI screenshot is saved to its separate RC-007 QA destination.")
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame

func _labels_match(scene: Control) -> bool:
	for kind in ["straight", "corner", "split", "join"]:
		var total: int = scene.game.stock_totals[kind]
		var installed := 0
		for piece in scene.game.board:
			if piece.get("kind") == kind:
				installed += 1
		var available := total - installed
		if scene.game.stock[kind] != available:
			return false
		if scene.stock_buttons[kind].text != "%s\n%d / %d" % [kind.capitalize(), available, total]:
			return false
		if scene.stock_buttons[kind].tooltip_text != "%d available, %d owned (%d installed)." % [available, total, installed]:
			return false
	return true

func _press_edit(scene: Control, caption: String) -> void:
	for button in scene.edit_buttons:
		if button.text == caption:
			button.pressed.emit()
			return
