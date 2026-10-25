extends SceneTree
const Audio = preload("res://scripts/audio/audio_coordinator.gd")
const Catalogue = preload("res://scripts/audio/audio_catalogue.gd")
var checks := 0
var failures := 0
var assertions: Array = []
const DESTINATION := "res://output/qa/rc-027/reward-audio"

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _receipt(id: String, kind: String = "rune") -> Dictionary:
	return {"ok": true, "transaction_id": id, "granted_card": {"id": "spark", "uid": 17} if kind == "rune" else {},
		"gold_granted": 15 if kind == "gold" else 0,
		"claim": {"component": kind, "resolution": "unlocked" if kind == "definition_unlock" else "skipped" if kind == "skip" else "claimed", "unlocked_definition_id": "spark" if kind == "definition_unlock" else ""}}

func _run() -> void:
	preload("res://tests/audio_catalogue_tests.gd").new().run(check)
	for reduced in [false, true]:
		var owner := Audio.new()
		root.add_child(owner)
		owner.automatic_timing = false
		owner.trace_enabled = true
		owner.apply_settings({"enabled": true, "sfx_muted": false, "sfx_volume": 1.0, "reduced_motion": reduced})
		check(not Catalogue.SFX.reward.future_only, "Reward uses the delivered existing cue after authoritative commit.")
		var rejected := _receipt("rejected")
		rejected.ok = false
		check(not owner.reward_committed("rejected", rejected) and not owner.reward_committed("", _receipt("")) and not owner.reward_committed("stale", _receipt("other")), "Rejected, missing and stale transaction identities are silent.")
		check(not owner.reward_committed("skip", _receipt("skip", "skip")) and owner.trace.is_empty(), "Skip and empty acquisitions do not play the reward flourish.")
		for kind in ["rune", "gold", "definition_unlock"]:
			var id: String = "run-a:visit-one:" + kind
			var receipt := _receipt(id, kind)
			var before := receipt.duplicate(true)
			check(owner.reward_committed(id, receipt), "Reduced=%s: committed %s starts a reward cue." % [reduced, kind])
			var count := owner.trace.size()
			check(not owner.reward_committed(id, receipt) and owner.trace.size() == count, "Repeated committed %s receipt is deduplicated." % kind)
			check(receipt == before and owner.trace.back().target.transaction_id == id and owner.trace.back().cue == "reward", "Reward playback retains a detached transaction identity without mutating receipt.")
		owner.bind_controller(null)
		check(not owner.reward_committed("run-a:visit-one:rune", _receipt("run-a:visit-one:rune")), "Controller replacement does not reset committed reward deduplication.")
		var count := owner.trace.size()
		for screen in ["screen_rewards", "screen_collection", "screen_map", "screen_home", "screen_rewards"]: owner.set_context(screen)
		check(owner.trace.size() == count, "Offer reopening, collection inspection and screen changes never replay reward cues.")
		owner.apply_settings({"sfx_muted": true})
		check(not owner.reward_committed("muted", _receipt("muted")), "A muted committed reward consumes its cue without playback.")
		owner.apply_settings({"sfx_muted": false})
		check(not owner.reward_committed("muted", _receipt("muted")) and owner.trace.size() == count, "Unmuting cannot replay a consumed acquisition.")
		owner.set_interrupted(true)
		check(not owner.reward_committed("interrupted", _receipt("interrupted")), "An interrupted owner consumes committed reward feedback silently.")
		owner.set_interrupted(false)
		check(not owner.reward_committed("interrupted", _receipt("interrupted")), "Resume never queues stale reward feedback.")
		owner.dispose()
		check(not owner.reward_committed("disposed", _receipt("disposed")), "A disposed audio owner cannot sound a retained callback.")
		owner.free()
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-027 reward audio checks, %d failures" % [checks, failures])
	# Let the runner frame release local receipt/audio references before shutdown.
	call_deferred("_finish")

func _finish() -> void:
	# Retire stopped audio playback after _run has released its local owners.
	# Waiting inside that coroutine leaves those final references alive.
	await create_timer(0.2).timeout
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
