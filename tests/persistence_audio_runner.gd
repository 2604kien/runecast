extends SceneTree
const Audio = preload("res://scripts/audio/audio_coordinator.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var owner := Audio.new()
	root.add_child(owner)
	owner.trace_enabled = true
	owner.automatic_timing = false
	owner.defer_terminal_results = true
	owner._batch = {"action_id": 1, "encounter_id": 1}
	owner._event_committed({"type": "battle_ended", "state": "victory", "action_id": 1, "encounter_id": 1}, owner.session)
	check(owner.trace.is_empty(), "presented terminal battle cannot sound before save")
	var identity := {"run_id": "run-test", "route_id": "route", "node_id": "node", "visit_id": "visit", "generation": 1}
	check(owner.result_committed(identity, "victory"), "durable outcome sounds once")
	check(owner.trace.size() == 1 and owner.trace[0].target.moment == "saved", "result feedback explicitly follows saved transaction")
	check(not owner.result_committed(identity, "victory") and owner.trace.size() == 1, "duplicate outcome does not sound again")
	check(not owner.result_committed({}, "victory"), "missing identity silent")
	owner.apply_settings({"sfx_muted": true})
	identity.visit_id = "muted"
	check(not owner.result_committed(identity, "defeat"), "muted saved result consumed silently")
	owner.apply_settings({"sfx_muted": false})
	check(not owner.result_committed(identity, "defeat") and owner.trace.size() == 1, "unmute does not replay saved result")
	owner.set_interrupted(true)
	identity.visit_id = "interrupted"
	check(not owner.result_committed(identity, "victory"), "interrupted saved result consumed silently")
	owner.set_interrupted(false)
	check(not owner.result_committed(identity, "victory"), "resume does not replay result")
	owner.dispose()
	identity.visit_id = "closed"
	check(not owner.result_committed(identity, "victory"), "disposed owner silent")
	owner.free()
	await create_timer(0.2).timeout
	print("RC-028 durable audio checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
