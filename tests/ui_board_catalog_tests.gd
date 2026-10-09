extends RefCounted

# Real scene + controller witnesses, with reused RC-008 synthetic touch helpers.
const Examples = preload("res://scripts/dev/board_examples.gd")
const Touch = preload("res://tests/ui_touch_tests.gd")
const IDS := ["board_training", "board_gallery", "board_ossuary", "board_belfry"]

func run_followup(check: Callable, tree: SceneTree, directory: String = "") -> void:
	var touch := Touch.new()
	for board_id in IDS:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, 1600)
		viewport.handle_input_locally = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		tree.root.add_child(viewport)
		var scene: Control = load("res://scenes/main.tscn").instantiate()
		scene.board_example_id = board_id
		scene.board_example_step = "opening"
		viewport.add_child(scene)
		scene.sound_enabled = false
		await touch._layout(tree)
		check.call(scene.controller != null and scene.startup_error.is_empty() and scene.board_example_report.ok, "%s opens its natural starter witness in the actual scene." % board_id)
		if scene.controller == null:
			viewport.queue_free()
			await tree.process_frame
			continue
		scene.gestures.automatic_timing = false
		var loaded := Examples.load_example(board_id)
		check.call(scene.initial_setup.encounter.board_id == board_id and scene.encounter_title.text.contains("DEV") and _only_endpoints(scene.game.board), "%s binds its development title and endpoints-only opening without production prefill." % board_id)
		await touch._capture(viewport, tree, directory, board_id + "-opening.png", check)
		if board_id == "board_belfry":
			var touch_directory := directory.path_join("belfry-touch") if directory != "" else ""
			await touch._inspection(scene, viewport, tree, check, touch_directory)
			await touch._editing(scene, viewport, tree, check, touch_directory)
			scene._exact_replay()
			await touch._small_inspector(scene, viewport, tree, check, touch_directory)
			viewport.size = Vector2i(720, 1600)
			scene._exact_replay()
			scene.page_scroll.scroll_vertical = 0
			await touch._layout(tree)
		var result := Examples.apply(scene.controller, loaded.example, "built")
		check.call(result.ok and scene.game.forecast.valid and not scene.cast_button.disabled, "%s executes every authored construction command and exposes an affordable Cast. %s" % [board_id, str(result.errors)])
		if result.ok:
			await touch._capture(viewport, tree, directory, board_id + "-built.png", check)
			var before: Dictionary = scene.controller.snapshot()
			scene.cast_button.pressed.emit()
			check.call(scene.game.enemy_hp == before.enemy_hp - before.forecast.damage and scene.game.player_hp == before.player_hp - maxi(0, before.intent - before.forecast.shield), "%s actual Cast applies the displayed damage and shield once." % board_id)
			check.call(scene.game.turn == 2 and scene.game.energy == 3 and scene.game.hand.size() == 3 and _only_endpoints(scene.game.board) and scene.game.undo_count == 0 and scene.game.stock == scene.game.stock_totals, "%s Cast cleans up to a new playable endpoints-only turn with fresh finite stock." % board_id)
			await touch._capture(viewport, tree, directory, board_id + "-turn2.png", check)
		scene.player.stop()
		scene.player.stream = null
		viewport.queue_free()
		await tree.process_frame
	# The opt-in launcher also fails visibly instead of silently launching training.
	for invalid in [{"id": "missing_board", "step": "opening"}, {"id": "board_gallery", "step": "invalid"}]:
		var scene: Control = load("res://scenes/main.tscn").instantiate()
		scene.board_example_id = invalid.id
		scene.board_example_step = invalid.step
		tree.root.add_child(scene)
		await tree.process_frame
		check.call(scene.controller == null and not scene.startup_error.is_empty() and scene.cast_button.disabled, "Invalid development example ID/stage disables gameplay with diagnostics.")
		scene.queue_free()
		await tree.process_frame

func _only_endpoints(board: Array) -> bool:
	var kinds: Array = []
	for piece in board:
		if not piece.is_empty(): kinds.append(piece.kind)
	kinds.sort()
	return board.size() == 16 and kinds == ["begin", "end"]
