extends SceneTree
## RC-018 isolated evidence: real controller results and real presentation clock.
## No main scene, production subscriptions, gameplay changes or invented events.
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Fixtures = preload("res://tests/combat_animation_tests.gd")
const Motion = preload("res://assets/enemies/shadeling/motion.tres")

var failures: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := Loader.load_setup()
	if not loaded.get("ok", false):
		push_error("Production setup failed")
		quit(1)
		return
	var records: Array = []
	for scenario in ["cast", "shield", "pass", "focus", "conjure", "cleanup", "victory", "defeat"]:
		for reduced in [false, true]:
			records.append(_record(loaded.setup, scenario, reduced))
	var hashes := {}
	for path in ["scripts/ui/animated_combat_presentation.gd", "scripts/ui/combat_controller.gd", "scripts/core/combat.gd", "scenes/vfx/combat_feedback_style.gd", "assets/enemies/shadeling/motion.gd", "assets/enemies/shadeling/motion.tres"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {
		"schema_version": 1, "engine": Engine.get_version_info().string,
		"source": "Real production controller.command + AnimatedCombatPresentation; detached controlled test setup for circuit/outcome cases; natural seed-selected opening for techniques.",
		"clock": "Presentation seconds, not wall clock; duration/steps read from the live adapter before deterministic advance.",
		"attack_contact_fraction": Motion.attack_contact,
		"event_presented_semantics": "After visual effect and staged consequence commit; never phase start/contact.",
		"source_sha256": hashes, "scenarios": records, "failures": failures,
		"passed": failures.is_empty()
	}
	DirAccess.make_dir_recursive_absolute("res://output/audio/rc-018")
	var file := FileAccess.open("res://output/audio/rc-018/presentation-traces.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("RC018 presentation traces: %d scenarios, %d failures" % [records.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)

func _record(source: Dictionary, scenario: String, reduced: bool) -> Dictionary:
	var fixture := Fixtures.new()
	var game = Combat.new(fixture._setup(source))
	var command := "cast"
	var arguments := {}
	var fixture_note := "Controlled detached setup from existing animation tests; real owned UIDs, commands and production rules."
	match scenario:
		"cast", "shield", "victory", "defeat":
			if not fixture._pair(game, "shield" if scenario == "shield" else "spark"):
				failures.append(scenario + ": circuit preparation failed")
			if scenario == "victory": game.enemy_hp = 7
			if scenario == "defeat": game.player_hp = 1
		"cleanup":
			fixture._pair(game)
			game.place_rune(8, fixture._uid(game, "shield"))
			game.play_technique(fixture._uid(game, "conjure"))
			game.place_rune(5, fixture._uid(game, "free_spark"))
			game.play_technique(fixture._uid(game, "conjure"))
			command = "pass"
		"pass": command = "pass"
		"focus", "conjure":
			var found := false
			for seed_value in range(128):
				game = Combat.new(source, seed_value)
				var uid: int = fixture._uid(game, scenario)
				if uid >= 0:
					found = true
					arguments = {"uid": uid}
					fixture_note = "Unmodified production setup, natural opening seed %d; actual supplied %s UID %d." % [seed_value, scenario, uid]
					break
			if not found: failures.append(scenario + ": no natural opening found")
			command = "technique"
	var presenter := Animated.new()
	presenter.automatic_timing = false
	presenter.reduced_motion = reduced
	var controller := Controller.new(game, presenter)
	var commits: Array = []
	var weak_presenter: WeakRef = weakref(presenter)
	presenter.event_presented.connect(func(event: Dictionary):
		var active = weak_presenter.get_ref()
		commits.append({"sequence": event.sequence, "type": event.type, "seconds": active.elapsed})
	)
	var accepted: bool = controller.command(command, arguments)
	var result: Dictionary = game.last_result()
	if not accepted: failures.append(scenario + ": command rejected")
	var before_playback := controller.snapshot()
	var steps: Array = []
	var seconds := 0.0
	for step in presenter.get("_steps"):
		var end := seconds + float(step.seconds)
		steps.append({"event": step.event.duplicate(true), "start_seconds": seconds, "end_seconds": end, "duration_seconds": step.seconds})
		seconds = end
	var nominal_duration := presenter.duration
	presenter.finish()
	if controller.is_busy() or presenter.event_trace != result.events or controller.snapshot() != before_playback:
		failures.append(scenario + ": completion/order/authoritative state mismatch")
	for i in range(mini(steps.size(), commits.size())):
		if absf(float(steps[i].end_seconds) - float(commits[i].seconds)) > 0.00001:
			failures.append(scenario + ": consequence time mismatch")
	var record := {"id": scenario, "mode": "reduced" if reduced else "normal", "fixture_note": fixture_note,
		"accepted": accepted, "command": command, "arguments": arguments,
		"action_id": result.action_id, "encounter_id": result.encounter_id,
		"actor_id": "shadeling", "duration_seconds": nominal_duration,
		"before": result.before, "after": result.after, "steps": steps, "commits": commits}
	controller.dispose()
	presenter.dispose()
	return record
