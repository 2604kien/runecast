extends RefCounted

const Experiments = preload("res://scripts/core/experiments.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")

func run(training: Control, check: Callable, tree: SceneTree) -> void:
	check.call(not training.experiment_mode and training.scenario_select == null and training.controller.get_record() == null, "Normal launch has no experiment controls or observation writes.")
	training.hide()
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.experiment_mode = true
	scene.setup_path = "res://data/encounter.json"
	scene.experiment_record_path = "res://output/qa/experiment-records/ui-session.json"
	tree.root.add_child(scene)
	await tree.process_frame
	check.call(scene.controller != null and scene.scenario_select.item_count == 9 and scene.experiment_label.text.contains("effects / control | seed 42"), "Opt-in screen exposes bounded scenario selection and active variant/seed.")
	for scenario_index in range(scene.scenario_select.item_count):
		scene.scenario_select.select(scenario_index)
		scene.scenario_select.item_selected.emit(scenario_index)
		var scenario: String = scene.scenario_select.get_selected_metadata()
		for variant_index in range(scene.variant_select.item_count):
			scene.variant_select.select(variant_index)
			scene.seed_input.text = "42"
			scene._launch_selected_experiment()
			var variant: String = scene.variant_select.get_item_text(variant_index)
			check.call(scene.game.experiment.scenario_id == scenario and scene.game.experiment.variant_id == variant and scene.experiment_label.text.contains(scenario + " / " + variant), "Selection launches real validated scene: " + scenario + "/" + variant)
			var initial: Dictionary = scene.controller.snapshot()
			var actions: Array = Experiments.known_solution_actions(scenario, variant)
			for action in actions:
				if action.command == "place_wire":
					scene._select_tool(action.arguments.kind)
					scene.cells[action.arguments.index].pressed.emit()
				elif action.command == "rotate":
					scene.selected_cell = action.arguments.index
					scene._rotate()
			check.call(not scene.cast_button.disabled, "Known solution is castable through UI: " + scenario + "/" + variant)
			scene.cast_button.pressed.emit()
			check.call(scene.controller.record_document().totals.accepted == 1 + actions.size(), "Playable edits/cast recorded once through UI: " + scenario + "/" + variant)
			scene.controller.add_note("AUTOMATED UI CHECK: no participant evidence")
			var exported: Dictionary = scene.controller.export_record("res://output/qa/experiment-records/ui-%s-%s.json" % [scenario, variant])
			check.call(exported.ok, "Per-variant playable evidence exported separately: " + scenario + "/" + variant)
			scene.replay_button.pressed.emit()
			check.call(scene.controller.snapshot() == initial and scene.controller.record_document().totals.attempts == 0, "Exact replay reconstructs all starting state and a new record: " + scenario + "/" + variant)
	# Invalid selection does not replace a running experiment with another setup.
	var before: Dictionary = scene.controller.snapshot()
	scene.seed_input.text = "not-a-seed"
	scene._launch_selected_experiment()
	check.call(scene.experiment_feedback.text.contains("Launch rejected") and scene.controller.snapshot() == before, "Invalid seed is visibly rejected without replacing the session.")
	scene._launch_experiment("hits", "treatment", 42)
	scene._cast()
	check.call(scene.experiment_events.text.count("hit ") >= 2, "Multi-hit ordered damage is visible in the experiment debug readout.")
	scene._inspect_experiment_record()
	check.call(scene.record_dialog.visible and scene.record_text.text.contains("configuration_fingerprint") and scene.record_text.text.contains("ui-session.json"), "Inspect/export exposes actual local JSON and location.")
	scene.note_input.text = "AUTOMATED QA: not a participant observation"
	scene._add_experiment_note()
	check.call(scene.controller.record_document().notes.size() == 1 and scene.record_text.text.contains("AUTOMATED QA"), "Optional local notes survive export and inspection.")
	scene.record_dialog.hide()
	var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string(scene.experiment_record_path))
	check.call(stored is Dictionary and stored.totals.casts == 1 and stored.notes.size() == 1, "UI export on disk matches authoritative metrics and notes.")
	scene.experiment_record_path = "res://output/qa/experiment-records/no-extension"
	scene._pass()
	check.call(scene.record_error.contains("Record write failed") and scene.game.turn >= 2, "Visible write failure does not corrupt or stop gameplay.")
	before = scene.controller.snapshot()
	scene._replay_experiment()
	check.call(scene.controller.snapshot() == before and scene.experiment_feedback.text.contains("Session kept"), "Replay preserves unsaved observations when export fails.")
	scene.experiment_record_path = "res://output/qa/experiment-records/ui-session.json"
	scene._save_experiment_record()
	for variant in ["control", "treatment"]:
		scene._launch_experiment("encounters", variant, 42)
		scene._cast()
		scene._cast()
		check.call(scene.game.state == "victory" and not scene.next_button.disabled, "Paired scene exposes Next encounter after actual victory: " + variant)
		scene.next_button.pressed.emit()
		check.call(scene.game.encounter_number == 2 and scene.next_button.disabled, "Next encounter uses guarded authoritative transition exactly once: " + variant)
		var second: Dictionary = scene.controller.snapshot()
		scene._next_experiment_encounter()
		check.call(scene.controller.snapshot() == second, "Direct duplicate Next callback cannot transfer twice: " + variant)
		if variant == "control":
			scene._select_card(scene.game.hand[0].uid)
			scene.cells[1].pressed.emit()
		scene._cast()
		scene._cast()
		check.call(scene.game.state == "victory" and scene.game.encounter_number == 2 and scene.next_button.disabled, "Both encounters complete through playable controls: " + variant)
		scene.controller.add_note("AUTOMATED PAIRED PLAYTHROUGH: no participant evidence")
		scene.controller.export_record("res://output/qa/experiment-records/ui-encounters-%s-complete.json" % variant)
	# Exact replay cancels a live adapter; its retained callback cannot unlock a new action.
	scene._launch_experiment("hits", "treatment", 42)
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	scene._cast()
	scene._replay_experiment()
	var newer := Delayed.new()
	scene.controller.set_presenter(newer)
	scene._cast()
	delayed.complete()
	check.call(scene.controller.is_busy() and delayed.cancellations == 1, "Experiment replay cancels playback and stale completion cannot unlock the new session.")
	newer.complete()
	# Validate known geometry reaches actual rendering data and input guards.
	scene._launch_experiment("blocked", "treatment", 42)
	scene._select_tool("erase")
	scene._cell_pressed(6)
	check.call(scene.cells[6].piece.kind == "blocked" and scene.cells[6].disabled, "Blocked cell is rendered and remains blocked under direct UI editing.")
	scene._launch_experiment("endpoints", "treatment", 42)
	scene._select_tool("erase")
	scene._cell_pressed(15)
	check.call(scene.cells[15].piece.kind == "begin" and scene.cells[1].piece.kind == "end", "Alternate endpoint rendering and direct edit protection agree.")
	scene._launch_experiment("ports", "treatment", 42)
	check.call(scene.cells[3].piece.port_shape == "corner" and scene.cells[3].catalog.spark.port_shape == "corner", "Alternate rune port metadata reaches renderer and catalog together.")
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame
	var invalid: Control = load("res://scenes/main.tscn").instantiate()
	invalid.setup_path = "res://data/encounter.json"
	invalid.experiment_mode = true
	invalid.experiment_scenario = "unknown"
	invalid.experiment_record_path = "res://output/qa/experiment-records/invalid.json"
	tree.root.add_child(invalid)
	await tree.process_frame
	check.call(invalid.controller == null and invalid.startup_error.contains("unknown scenario") and invalid.cast_button.disabled and invalid.next_button.disabled, "Unknown experiment startup displays diagnostics with no playable fallback.")
	invalid.queue_free()
	await tree.process_frame
	training.show()
