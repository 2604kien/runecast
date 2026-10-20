extends SceneTree
## Isolated RC-019 ambience audition and imported Vorbis verification.
## No gameplay scene, production subscription, or music placeholder.
const OUT := "res://output/qa/rc-019/"
const RUNTIME := "res://assets/audio/ambience/crypt.ogg"
var failures: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stream = load(RUNTIME)
	if not stream is AudioStreamOggVorbis:
		push_error("Crypt import is not AudioStreamOggVorbis")
		quit(1)
		return
	if "--verify" in OS.get_cmdline_user_args():
		await _verify(stream)
	else:
		_ui(stream)

func _ui(stream: AudioStreamOggVorbis) -> void:
	root.title = "Rune Cast • RC-019 crypt ambience audition"
	root.size = Vector2i(680, 240)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	root.add_child(player)
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 24)
	root.add_child(panel)
	var label := Label.new()
	label.text = "Crypt ambience • current imported Vorbis loop\nMusic remains pending by owner choice.\nFive-repeat headphone/speaker listening remains an owner review."
	panel.add_child(label)
	var play := Button.new()
	play.text = "Play looping ambience"
	play.pressed.connect(func(): player.play())
	panel.add_child(play)
	var stop := Button.new()
	stop.text = "Stop"
	stop.pressed.connect(func(): player.stop())
	panel.add_child(stop)

func _verify(stream: AudioStreamOggVorbis) -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audio-loop-catalogue.json"))
	var cue: Dictionary = {}
	for entry in catalogue.cues:
		if entry.cue_id == "crypt":
			cue = entry
	if cue.is_empty():
		push_error("Crypt catalogue entry is missing")
		quit(1)
		return
	var duration := stream.get_length()
	var expected_duration := float(cue.loop_end_sample - cue.loop_start_sample) / float(cue.sample_rate_hz)
	if not stream.loop or stream.loop_offset != 0.0:
		failures.append("Imported Vorbis must loop from offset zero")
	if absf(duration - expected_duration) > 1.0 / 48000.0:
		failures.append("Imported duration differs from exact documented loop")
	var mix_rate := int(AudioServer.get_mix_rate())
	var playback := stream.instantiate_playback()
	playback.start(0.0)
	var capture_path := OUT + "godot-loop-float32.raw"
	var output := FileAccess.open(capture_path, FileAccess.WRITE)
	var target_frames := ceili(duration * mix_rate * 5.1)
	var frames := 0
	var wraps: Array = []
	var previous_count := 0
	while frames < target_frames:
		var block := playback.mix_audio(1.0, mini(4096, target_frames - frames))
		if block.is_empty():
			failures.append("Vorbis decoder ended while loop enabled")
			break
		output.store_buffer(block.to_byte_array())
		frames += block.size()
		var loop_count := playback.get_loop_count()
		if loop_count > previous_count:
			wraps.append({"loop_count": loop_count, "observed_after_mix_frame": frames,
				"playback_position_seconds": playback.get_playback_position()})
			previous_count = loop_count
	output.close()
	var counted_loops := playback.get_loop_count()
	var position := playback.get_playback_position()
	var continued := playback.is_playing()
	playback.stop()
	if counted_loops < 5 or not continued or frames != target_frames:
		failures.append("Offline imported Vorbis did not complete five loop wraps")
	# A separate short real AudioStreamPlayer pass verifies the bus/player path.
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, "RC019Audition")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus, capture)
	var player := AudioStreamPlayer.new()
	player.bus = "RC019Audition"
	player.stream = stream
	player.volume_db = float(cue.intended_gain_db)
	root.add_child(player)
	player.play()
	await create_timer(0.7).timeout
	var live_position := player.get_playback_position()
	var live_playing := player.playing
	var live_samples := capture.get_buffer(capture.get_frames_available())
	var live_peak := 0.0
	var nonzero := 0
	for sample in live_samples:
		live_peak = maxf(live_peak, maxf(absf(sample.x), absf(sample.y)))
		if absf(sample.x) > 0.000001 or absf(sample.y) > 0.000001:
			nonzero += 1
	player.stop()
	if not live_playing or live_position <= 0 or nonzero == 0 or not is_finite(live_peak) or live_peak >= 1.0 or player.playing:
		failures.append("Real player progress, finite nonzero mix, headroom or stop failed")
	var report := {
		"schema_version": 1, "task": "RC-019", "scope": "crypt ambience only; two music loops pending",
		"engine": Engine.get_version_info().string, "audio_driver": AudioServer.get_driver_name(),
		"runtime_path": RUNTIME.trim_prefix("res://"), "runtime_sha256": FileAccess.get_sha256(RUNTIME),
		"catalogue_sha256": FileAccess.get_sha256("res://docs/audio-loop-catalogue.json"),
		"imported_resource_class": stream.get_class(), "imported_loop": stream.loop,
		"imported_loop_offset_seconds": stream.loop_offset, "imported_duration_seconds": duration,
		"offline_method": "Imported resource instantiate_playback, start and repeated mix_audio(1.0, up to 4096 frames); no wall-clock acceleration or pitch shift",
		"method_reference": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayback.html",
		"mix_sample_rate_hz": mix_rate, "capture_channels": 2, "capture_encoding": "interleaved little-endian float32",
		"capture_path": capture_path.trim_prefix("res://"), "capture_sha256": FileAccess.get_sha256(capture_path),
		"captured_frames": frames, "loop_count": counted_loops, "wrap_observations": wraps,
		"final_playback_position_seconds": position, "still_looping_before_stop": continued,
		"player_check": {"duration_seconds": 0.7, "captured_frames": live_samples.size(), "nonzero_frames": nonzero,
			"peak_linear": live_peak, "position_seconds": live_position, "playing_before_stop": live_playing, "stopped": not player.playing},
		"listening_review": "Automated decoder and internal mixer evidence only. No headphone, speaker or mobile listening acceptance.",
		"failures": failures, "passed": failures.is_empty()
	}
	var file := FileAccess.open(OUT + "godot-playback.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("RC019 crypt: %d imported Vorbis wraps, %d failures; music remains pending" % [counted_loops, failures.size()])
	quit(0 if failures.is_empty() else 1)
