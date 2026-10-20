extends RefCounted
## Native AudioStreamPlayer lifetime checks. The deliberately oversized frame
## delta is not elapsed playback time for a sound started in this same frame.
const Audio = preload("res://scripts/audio/audio_coordinator.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func run(check: Callable, tree: SceneTree) -> void:
	var audio := Audio.new()
	tree.root.add_child(audio)
	# Drive only the coordinator's frame callback explicitly. Child native
	# players keep running and can report their own natural finished signal
	# before the owner observes playing=false and reclaims the slot.
	audio.set_process(false)
	audio.apply_settings({"enabled": true, "sfx_muted": false, "sfx_volume": 1.0})
	audio.set_interrupted(false)
	audio.ui_feedback("ui_confirm", "native-lifetime")
	var voice: Dictionary = audio._voices.filter(func(slot): return slot.active)[0]
	var native_finishes := [0]
	voice.player.finished.connect(func(): native_finishes[0] += 1)
	var source_length: float = voice.player.stream.get_length()
	var stream = voice.player.stream
	audio._process(2.0)
	check.call(voice.active and voice.player.playing and voice.player.stream == stream,
		"A newly started imported SFX survives a preceding two-second frame delta without truncation.")
	await tree.create_timer(minf(0.06, source_length * 0.25)).timeout
	check.call(voice.active and voice.player.playing and voice.player.get_playback_position() > 0.0,
		"The native SFX decoder advances after the oversized frame; playback has not been simulated to completion.")
	await _wait_for_finish(tree, voice.player, source_length + 1.0)
	audio._process(0.0)
	check.call(native_finishes[0] == 1 and not voice.active and not voice.player.playing,
		"A full imported WAV finishes naturally once, then its owned voice becomes reusable.")

	audio.apply_settings({"reduced_motion": true})
	check.call(audio._start_cue("cast", "native-cast", "cast", {}, -999.0, -1, true, true),
		"Native release fixture starts the delivered Cast WAV as its reduced foreground.")
	voice = audio._voices.filter(func(slot): return slot.active)[0]
	var original: AudioStreamWAV = voice.player.stream
	var original_pcm: PackedByteArray = original.data
	await tree.create_timer(0.04).timeout
	check.call(voice.player.playing and voice.player.get_playback_position() > 0.0,
		"Native release replaces an actually advancing Cast rather than an unstarted simulated sound.")
	audio._start_cue("damage", "native-impact", "retaliation", {}, -999.0, -1, true, true)
	var tails: Array = audio._voices.filter(func(slot): return slot.active and slot.release > 0.0)
	check.call(tails.size() == 1 and audio.active_voice_count() == 2,
		"Reduced native replacement retains exactly one foreground plus its owned release tail.")
	if tails.size() == 1:
		var tail: Dictionary = tails[0]
		var release_stream: AudioStreamWAV = tail.player.stream
		var tail_finishes := [0]
		tail.player.finished.connect(func(): tail_finishes[0] += 1, CONNECT_ONE_SHOT)
		check.call(release_stream.get_length() > 0.0 and release_stream.get_length() <= 0.008
			and release_stream.data.decode_s16(release_stream.data.size() - 2) == 0
			and original.data == original_pcm,
			"The native release owns <=8 ms of zero-ending PCM without shortening or mutating its source WAV.")
		# This is a main-thread call immediately after play, before yielding for
		# a mixer cycle. Its delta must not consume the new sample-domain release.
		var was_playing: bool = tail.player.playing
		audio._process(2.0)
		check.call(not was_playing or tail.active and tail.player.stream == release_stream,
			"A preceding long frame does not erase a newly started native release envelope.")
		await _wait_for_finish(tree, tail.player, 1.0)
		audio._process(0.0)
		check.call(tail_finishes[0] == 1 and not tail.active,
			"The PCM release finishes through the native audio player, independently of frame lifetime arithmetic.")
		check.call(audio.active_voice_count() == 1,
			"The replacement impact continues at full authored length after the release has naturally ended.")
	var foregrounds: Array = audio._voices.filter(func(slot): return slot.active)
	if not foregrounds.is_empty():
		await _wait_for_finish(tree, foregrounds[0].player, 2.0)
		audio._process(0.0)
	check.call(audio.active_voice_count() == 0, "Natural native completion leaves no queued foreground or release voice.")
	_nested_notifications(check, audio)
	audio.dispose()
	audio.free()

func _nested_notifications(check: Callable, audio: Audio) -> void:
	var model := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup)
	var presenter := Animated.new()
	presenter.automatic_timing = false
	var controller := Controller.new(model, presenter)
	audio.trace_enabled = true
	audio.apply_settings({"reduced_motion": false})
	audio.bind_controller(controller)
	audio.set_context("screen_combat", true)
	var starts: int = audio.loop_starts.ambience
	controller.command("cast")
	var cues: int = audio.trace.size()
	check.call(cues == 1 and not audio._batch.is_empty(),
		"Notification fixture begins with a real accepted Cast and pending retaliation phases.")
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check.call(audio.loop_snapshot().interrupted and audio.loop_snapshot().ambience.paused
		and audio.active_voice_count() == 0 and audio._batch.is_empty(),
		"Application focus-out invalidates pending action audio and pauses the existing loop.")
	audio.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check.call(audio.loop_snapshot().interrupted and audio.loop_snapshot().ambience.paused,
		"Focus-in during application suspension cannot resume any audio.")
	presenter.finish()
	audio.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check.call(not audio.loop_snapshot().interrupted and not audio.loop_snapshot().ambience.paused
		and audio.loop_starts.ambience == starts and audio.trace.size() == cues and audio.active_voice_count() == 0,
		"Resume after focus-in preserves the loop and never replays phases skipped while suspended.")
	controller.command("pass")
	audio.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	audio.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check.call(audio.loop_snapshot().interrupted and audio.loop_snapshot().ambience.paused,
		"Application resume while still unfocused cannot override focus interruption.")
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	presenter.finish()
	check.call(not audio.loop_snapshot().interrupted and audio.loop_starts.ambience == starts
		and audio.trace.size() == cues and audio.active_voice_count() == 0,
		"Final focus-in permits the same loop but consumes the entire interrupted Pass batch without late cues.")
	controller.dispose()
	presenter.dispose()

func _wait_for_finish(tree: SceneTree, player: AudioStreamPlayer, timeout_seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while player.playing and Time.get_ticks_msec() < deadline:
		await tree.create_timer(0.01).timeout
