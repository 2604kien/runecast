extends SceneTree
## Real accepted fixture actions exercise the existing ordered presenter.
const Fixture = preload("res://tests/helpers/rc033_fixture.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const Inspect = preload("res://scripts/ui/inspection_data.gd")
const Audio = preload("res://scripts/audio/audio_coordinator.gd")
const DESTINATION := "res://output/qa/rc-033/presentation"
var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _state(model) -> Dictionary:
	return {"snapshot": model.snapshot(), "rng": [model.rng.state, model.endpoint_rng.state, model.kit_rng.state],
		"next_uid": model.next_uid, "history": model.history.duplicate(true)}

func _prepared() -> Dictionary:
	var model = Fixture.new_combat()
	var controller := Controller.new(model)
	for turn in 2: check(Fixture.command(controller, "pass"), "Fixture advances original intent with legal Pass %d." % turn)
	for turn in 6:
		check(Fixture.prepare_spark(controller).ok and Fixture.command(controller, "cast"), "Fixture deals six damage through legal Cast %d." % turn)
	check(Fixture.prepare_spark(controller).ok, "Fixture prepares the legal threshold-crossing Cast.")
	check(controller.snapshot().enemy_hp == 44 and controller.snapshot().intent == 16, "Crossing begins at 44 HP with phase-one 16 already announced.")
	return {"model": model, "controller": controller}

func _run() -> void:
	var loaded := Fixture.load_fixture()
	check(loaded.ok, "Excluded fixture validates through the normal content loader.")
	if loaded.ok:
		for reduced in [false, true]: await _ordered(reduced)
		_cancellation()
		_stale_completion()
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-033 presentation: %d checks, %d failures" % [checks, failures])
	await process_frame
	quit(0 if failures == 0 else 1)

func _ordered(reduced: bool) -> void:
	var fixture := _prepared()
	var controller = fixture.controller
	var model = fixture.model
	var presenter := Animated.new()
	presenter.automatic_timing = false
	presenter.reduced_motion = reduced
	check(controller.set_presenter(presenter), "Attach production presenter before crossing (reduced=%s)." % reduced)
	var coordinator := Audio.new()
	coordinator.trace_enabled = true
	coordinator.automatic_timing = false
	root.add_child(coordinator)
	coordinator.bind_controller(controller)
	coordinator.apply_settings({"enabled": true, "reduced_motion": reduced})
	var before := _state(model)
	var description := Inspect.describe_intent(before.snapshot)
	for refresh in 40: check(Inspect.describe_intent(controller.snapshot()) == description, "Intent description is stable on refresh %d (reduced=%s)." % [refresh, reduced])
	check(_state(model) == before, "Repeated intent inspection preserves preparation, ownership and all RNG streams.")
	check(description.text.contains("Announced attack: 16") and description.text.contains("Current position: 3 of 3")
		and description.text.contains("Active phase: 1 of 2") and description.text.contains("40 HP or less")
		and description.text.contains("12 / 16 / 20") and description.text.contains("preserves this turn's announced attack"), "Intent explains the authoritative announcement, index, phase, threshold and delayed transition.")
	var commits: Array = []
	var starts: Array = []
	var weak_presenter: WeakRef = weakref(presenter)
	var weak_audio: WeakRef = weakref(coordinator)
	presenter.phase_started.connect(func(notice): starts.append({"event": notice.event.duplicate(true), "snapshot": weak_presenter.get_ref().visual_snapshot(), "cues": weak_audio.get_ref().trace.size()}))
	presenter.event_presented.connect(func(event): commits.append({"event": event.duplicate(true), "snapshot": weak_presenter.get_ref().visual_snapshot(), "cues": weak_audio.get_ref().trace.size()}))
	check(controller.command("cast"), "Threshold-crossing Cast is accepted (reduced=%s)." % reduced)
	var result: Dictionary = model.last_result()
	var authoritative := _state(model)
	check(controller.is_busy() and controller.snapshot().intent == 12 and controller.display_snapshot().intent == 16
		and controller.display_snapshot().enemy_action.phase == 1, "Committed phase-two state remains hidden while prior consequences animate.")
	check(not controller.command("cast") and not controller.command("pass") and _state(model) == authoritative, "Busy duplicate Cast/Pass cannot advance phase, sequence or RNG.")
	presenter.advance(1000)
	var commit_count := commits.size()
	presenter.finish()
	presenter.present(result, func(): check(false, "Duplicate presentation must not complete again."))
	check(commits.size() == commit_count and not controller.is_busy() and presenter.event_trace == result.events, "One large advance presents every event once; duplicate batches/finish have no effects.")
	var phase_index: int = result.events.find(result.events.filter(func(event): return event.type == "enemy_phase_changed")[0])
	var old_retaliation := false
	var no_early_action := true
	for index in range(commits.size()):
		if index < phase_index: no_early_action = no_early_action and commits[index].snapshot.intent == 16 and commits[index].snapshot.enemy_action.phase == 1
		if commits[index].event.type == "retaliation": old_retaliation = commits[index].event.amount == 16 and commits[index].snapshot.player_hp == result.before.player_hp - 16
	check(no_early_action and old_retaliation, "Old 16 intent remains visible through its retaliation and all old-turn cleanup.")
	check(commits[phase_index].snapshot.enemy_action.phase == 2 and commits[phase_index].snapshot.enemy_action.sequence_index == 0
		and commits[phase_index].snapshot.intent == 12, "Explicit phase commit publishes phase two's first announcement at the boundary.")
	check(starts[phase_index].cues == commits[phase_index].cues, "Committed enemy phase feedback is deliberately silent.")
	check(starts.map(func(item): return item.event.type) == result.events.map(func(event): return event.type), "Animation phase_started remains an ordered step observation distinct from gameplay enemy_phase_changed.")
	check(presenter.visual_snapshot() == result.after and _state(model) == authoritative, "Normal/reduced presentation never reapplies model effects or consumes RNG.")
	var detached: Dictionary = presenter.visual_snapshot()
	detached.enemy_action.sequence.clear()
	detached.enemy_action.next_sequence.clear()
	check(presenter.visual_snapshot() == result.after and _state(model) == authoritative, "Presented action arrays are detached from model and retained presentation.")
	check(Inspect.describe_intent(controller.snapshot()).text.contains("Phase 2 is active"), "Phase-two inspection explains continued cycling without retriggering.")
	coordinator.dispose()
	coordinator.queue_free()
	controller.dispose()
	presenter.dispose()
	await process_frame

func _cancellation() -> void:
	var fixture := _prepared()
	var controller = fixture.controller
	var presenter := Animated.new()
	presenter.automatic_timing = false
	controller.set_presenter(presenter)
	var weak_controller: WeakRef = weakref(controller)
	var weak_presenter: WeakRef = weakref(presenter)
	var phase_count := [0]
	presenter.phase_started.connect(func(notice):
		if notice.event.type == "enemy_phase_changed": weak_controller.get_ref().cancel_presentation())
	presenter.event_presented.connect(func(event):
		if event.type == "enemy_phase_changed": phase_count[0] += 1)
	check(controller.command("cast"), "Cancellation fixture commits a real crossing Cast.")
	var committed: Dictionary = controller.snapshot()
	presenter.advance(1000)
	presenter.finish()
	check(not controller.is_busy() and not presenter.is_active() and phase_count[0] == 0
		and not presenter.event_trace.any(func(event): return event.type in ["enemy_phase_changed", "turn_started"]), "Cancellation at phase entry suppresses obsolete phase/next-turn presentation work.")
	check(controller.snapshot() == committed and committed.enemy_action.phase == 2 and controller.display_snapshot() == committed, "Cancellation retains authoritative phase progression and releases display to settled state.")
	controller.dispose()
	presenter.dispose()
	check(weak_presenter.get_ref() != null, "Cancellation presenter remains safely observable until test teardown.")

func _stale_completion() -> void:
	var fixture := _prepared()
	var controller = fixture.controller
	var delayed := Delayed.new()
	controller.set_presenter(delayed)
	check(controller.command("cast") and controller.snapshot().enemy_action.phase == 2, "Delayed crossing owns committed phase-two state.")
	var changes := [0]
	controller.changed.connect(func(): changes[0] += 1)
	delayed.complete(0)
	var count: int = changes[0]
	delayed.complete(0)
	check(changes[0] == count and not controller.is_busy(), "Duplicate completion cannot apply or announce the phase twice.")
	check(controller.command("pass"), "Next phase-two action starts under its own completion token.")
	delayed.complete(0)
	check(controller.is_busy() and controller.snapshot().intent == 16, "Stale crossing completion cannot release the next action.")
	check(controller.restart(), "Reset is accepted while phase-two presentation is pending.")
	var reset: Dictionary = controller.snapshot()
	delayed.complete(1)
	check(controller.snapshot() == reset and reset.enemy_action.phase == 1 and reset.enemy_action.sequence_index == 0 and reset.intent == 8
		and not controller.is_busy(), "Reset invalidates late callbacks and restores the first phase/index/announcement.")
	controller.dispose()
