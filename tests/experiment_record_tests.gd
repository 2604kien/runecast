extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const ExperimentRecord = preload("res://scripts/core/experiment_record.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")

func setup() -> Dictionary:
	var value: Dictionary = ContentLoader.load_setup().setup
	value.experiment = {"scenario_id": "metrics_fixture", "variant_id": "control", "version": 1, "seed": 42}
	return value

func run(check: Callable) -> void:
	var config := setup()
	var game := Combat.new(config)
	var clock := [1000]
	var record := ExperimentRecord.new(config, game.snapshot(), func(): return clock[0])
	var first := record.document()
	var shuffled_keys := {}
	var keys: Array = config.keys()
	keys.reverse()
	for key in keys: shuffled_keys[key] = config[key]
	var equivalent := ExperimentRecord.new(shuffled_keys, game.snapshot(), func(): return clock[0])
	check.call(first.configuration_fingerprint == equivalent.document().configuration_fingerprint and first.seed == 42 and first.starting_setup == config, "Record identifies the full setup and seed with an order-independent configuration fingerprint.")
	var alternate_instances := game.snapshot()
	alternate_instances.board[1].uid = 9000
	var same_layout := ExperimentRecord.new(config, alternate_instances)
	check.call(first.initial_state.circuit.layout_fingerprint == same_layout.document().initial_state.circuit.layout_fingerprint and first.initial_state.circuit.cells[1].uid != same_layout.document().initial_state.circuit.cells[1].uid, "Layout fingerprints ignore instance UIDs while retaining raw installed-instance identity.")
	config.encounter.seed = 17
	first.starting_setup.catalog.spark.cost = 999
	first.initial_state.circuit.cells.clear()
	check.call(record.document().seed == 42 and record.document().starting_setup.catalog.spark.cost == 2 and record.document().initial_state.circuit.cells.size() == 16, "Recorder setup, initial state and returned documents are detached.")
	var controller := Controller.new(game, null, record)
	for command in [["place_wire", {"index": 12, "kind": "straight"}], ["rotate", {"index": 12}], ["flip", {"index": 12}], ["place_wire", {"index": 12, "kind": "erase"}], ["undo", {}]]:
		controller.command(command[0], command[1])
	clock[0] = 2000
	controller.command("technique", {"uid": game.hand[2].uid})
	clock[0] = 3500
	controller.command("rotate", {"index": 0})
	clock[0] = 5000
	controller.command("cast")
	var cast: Dictionary = record.document().commands.back()
	check.call(cast.preparation_ms == 4000 and cast.cumulative_edits == 5, "Preparation spans editing, technique and rejected attempts from the authoritative turn start.")
	check.call(cast.metrics.damage == 12 and cast.metrics.cost == 1 and cast.metrics.retaliation == 8, "Cast metrics use actual authoritative damage and payment despite next-turn energy refresh.")
	check.call(cast.before.hand.counts.temporary_runes == 1 and cast.before.hand.counts.techniques == 0 and not cast.before.hand.empty and cast.after.hand.counts.total == 3, "Hand metrics distinguish exact composition/emptiness before and after cleanup/draws.")
	check.call(cast.before.circuit.cells.size() == 16 and cast.before.circuit.forecast.damage == 12 and cast.after.circuit.cells[1].kind == "straight" and cast.after.draw_pile.cards == game.draw_pile, "Circuit and ordered pile summaries expose layouts and depletion at command boundaries.")
	var totals := record.summary()
	check.call(totals.edits_by_kind == {"place_wire": 1, "place_rune": 0, "erase": 1, "rotate": 1, "flip": 1, "undo": 1} and totals.rejected == 1 and totals.techniques == 1 and totals.casts == 1, "Metrics classify accepted erase, placement, rotate, flip, undo and technique separately from rejection.")
	clock[0] = 9000
	controller.command("pass")
	var pass_record: Dictionary = record.document().commands.back()
	check.call(pass_record.preparation_ms == 4000 and pass_record.metrics.damage == 0 and pass_record.metrics.cost == 0 and record.summary().passes == 1, "New turn resets preparation timing and Pass never synthesizes cast damage or cost.")
	clock[0] = 10000
	controller.restart()
	check.call(record.latest_result().is_empty(), "Restart clears the previous encounter's event readout while retaining its record.")
	clock[0] = 12000
	controller.command("cast")
	check.call(record.document().lifecycle.size() == 1 and record.document().lifecycle[0].type == "restart_rng_continues" and record.document().commands.back().preparation_ms == 2000, "Normal Restart records RNG-continuation lifecycle and a fresh preparation interval.")
	var original_result := game.last_result()
	var total_before := record.summary()
	check.call(not record.record(original_result) and record.summary() == total_before, "An accepted authoritative action identity cannot be counted twice.")
	var replay := Immediate.new()
	var callbacks := [0]
	for ignored in range(2): replay.present(original_result, func(): callbacks[0] += 1)
	check.call(callbacks[0] == 2 and record.summary() == total_before, "Presentation replay never duplicates command measurements.")
	var exposed := record.latest_result()
	exposed.events.clear()
	totals = record.summary()
	totals.edits_by_kind.clear()
	check.call(not record.latest_result().events.is_empty() and record.summary().edits_by_kind.size() == 6, "Debug outcomes and nested total dictionaries cannot rewrite observations.")
	controller.add_note("Observed repeated layout; no participant result claimed.")
	controller.add_note("   ")
	check.call(record.document().notes.size() == 1 and record.document().notes[0].elapsed_ms == 11000, "Optional notes retain text and monotonic session offset, excluding blank submissions.")
	var recorded_game := Combat.new(setup())
	var plain_game := Combat.new(setup())
	var observed := Controller.new(recorded_game, null, ExperimentRecord.new(setup(), recorded_game.snapshot()))
	var plain := Controller.new(plain_game)
	for action in ["cast", "pass", "pass"]:
		observed.command(action)
		plain.command(action)
	observed.restart()
	plain.restart()
	check.call(recorded_game.snapshot() == plain_game.snapshot() and recorded_game.rng.state == plain_game.rng.state, "Instrumentation preserves gameplay, draw order and RNG consumption including normal Restart.")
	_terminal_and_guard_checks(check)
	_transition_checks(check)
	_export_checks(check, record)

func _transition_checks(check: Callable) -> void:
	var config := setup()
	config.experiment.transfer = "retain"
	var game := Combat.new(config)
	game.enemy_hp = 1
	var clock := [1000]
	var record := ExperimentRecord.new(config, game.snapshot(), func(): return clock[0])
	var delayed := Delayed.new()
	var controller := Controller.new(game, delayed, record)
	clock[0] = 2000
	controller.command("cast")
	check.call(not controller.command("next_encounter") and record.document().commands.back().rejection == "busy", "A victory outcome cannot transition until its pending presentation completes.")
	delayed.complete(0)
	clock[0] = 9000
	var accepted := controller.command("next_encounter")
	var transition: Dictionary = record.document().commands.back()
	check.call(accepted and controller.is_busy() and transition.before.encounter_number == 1 and transition.after.encounter_number == 2 and record.summary().transitions == 1 and record.summary().outcomes.size() == 1, "Paired transition records both authoritative encounter boundaries and waits for presentation once.")
	var before := game.snapshot()
	check.call(not controller.command("next_encounter") and game.snapshot() == before and record.summary().transitions == 1, "A repeated busy transition records rejection without duplicating transfer metrics or state.")
	delayed.complete(0)
	check.call(controller.is_busy(), "The first encounter's stale victory completion cannot release a transition presentation.")
	delayed.complete(1)
	check.call(not controller.command("next_encounter") and record.document().commands.back().rejection == "model_rejected" and record.summary().transitions == 1, "An idle duplicate transition remains a recorded model rejection.")
	clock[0] = 12000
	controller.command("pass")
	check.call(record.document().commands.back().preparation_ms == 3000 and record.document().commands.back().encounter_number == 2, "Paired transition starts a fresh monotonic preparation interval including subsequent playback time.")
	controller.dispose()

func _terminal_and_guard_checks(check: Callable) -> void:
	var game := Combat.new(setup())
	game.enemy_hp = 7
	var record := ExperimentRecord.new(setup(), game.snapshot())
	var controller := Controller.new(game, null, record)
	controller.command("cast")
	controller.command("pass")
	check.call(record.summary().damage == 7 and record.document().commands[0].metrics.hits[0].amount == 12 and record.summary().outcomes[0].state == "victory", "Lethal metrics count actual HP lost while retaining requested hit size and outcome.")
	check.call(record.summary().attempts == 2 and record.summary().rejected == 1 and record.document().commands.back().rejection == "terminal", "Terminal attempts are recorded once without applying gameplay.")
	game = Combat.new(setup())
	record = ExperimentRecord.new(setup(), game.snapshot())
	controller = Controller.new(game, null, record)
	controller.command("place_rune", {"index": 1, "uid": game.hand[1].uid})
	controller.command("cast")
	check.call(record.summary().shield == 10 and record.summary().blocked == 8 and record.summary().retaliation == 0 and record.summary().cost == 2 and record.summary().edits_by_kind.place_rune == 1, "Shield generated, damage blocked, HP loss and paid energy remain distinct metrics.")
	game = Combat.new(setup())
	record = ExperimentRecord.new(setup(), game.snapshot())
	var delayed := Delayed.new()
	controller = Controller.new(game, delayed, record)
	var weak_controller: WeakRef = weakref(controller)
	controller.presentation_started.connect(func(_result): weak_controller.get_ref().command("pass"))
	controller.command("cast")
	var authoritative := game.snapshot()
	controller.command("undo")
	check.call(record.summary().attempts == 3 and record.summary().accepted == 1 and record.summary().rejected == 2 and record.document().commands[1].rejection == "busy" and game.snapshot() == authoritative, "Busy and synchronous signal reentry each record one rejection after the accepted authoritative outcome.")
	check.call(record.latest_result().command == "cast", "Busy guard attempts preserve the last authoritative model outcome for hit inspection.")
	delayed.complete(0)
	delayed.complete(0)
	check.call(record.summary().attempts == 3 and not controller.is_busy(), "Duplicate presentation completion does not duplicate records or unlock twice.")
	controller.command("pass")
	controller.restart()
	controller.command("cast")
	var count: int = record.summary().attempts
	delayed.complete(1)
	check.call(controller.is_busy() and record.summary().attempts == count, "Stale pre-Restart completion cannot unlock or duplicate newer experiment records.")
	controller.dispose()
	delayed.complete()
	check.call(not controller.is_busy() and record.summary().attempts == count, "Disposal and stale presentation playback are observation-neutral.")

func _export_checks(check: Callable, record: ExperimentRecord) -> void:
	var path := "res://output/qa/experiment-records/record-test.json"
	var default_path := record.default_path()
	check.call(default_path.begins_with("user://experiments/") and default_path == record.default_path(), "Human observations have a stable per-session local user://experiments destination.")
	var saved := record.export_record(path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if saved.ok else null
	check.call(saved.ok and parsed is Dictionary and parsed.configuration_fingerprint == record.document().configuration_fingerprint and parsed.commands.size() == record.summary().attempts, "Test-only observation export produces inspectable complete JSON in the QA directory.")
	record.add_note("Safe replacement verification.")
	saved = record.export_record(path)
	parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if saved.ok else null
	check.call(saved.ok and parsed is Dictionary and parsed.notes.back().text == "Safe replacement verification.", "Replacing an existing record publishes a complete updated JSON document.")
	var before := record.document()
	var directory_path := "res://output/qa/experiment-records/occupied.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory_path))
	var failed := record.export_record(directory_path)
	check.call(not failed.ok and not failed.error.is_empty() and record.document() == before and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory_path)), "A publication failure is visible and leaves observations and existing paths intact.")
	failed = record.export_record("res://output/qa/experiment-records/invalid.txt")
	check.call(not failed.ok and not failed.error.is_empty(), "Invalid output paths fail explicitly without silently switching destinations.")
	var final_saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check.call(final_saved is Dictionary and final_saved.notes.back().text == "Safe replacement verification.", "Failed export attempts cannot corrupt a prior successful record.")
