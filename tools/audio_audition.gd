extends SceneTree
## Isolated RC-018 player. Default: labelled cue buttons. -- --verify: import/mix checks.
## Never loads the gameplay scene or installs production audio subscriptions.
var cues: Array = []
var player: AudioStreamPlayer
var capture: AudioEffectCapture
var status: Label
var failures: Array = []
var mix_pcm := PackedByteArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audio-cue-catalogue.json"))
	if not catalogue is Dictionary or not catalogue.has("source_settings"):
		push_error("RC-018 catalogue must identify active source settings")
		quit(1)
		return
	var settings_path := "res://" + str(catalogue.source_settings).trim_prefix("res://")
	var settings = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	if not settings is Dictionary or not settings.has("cues"):
		push_error("Generate RC-018 settings/assets first")
		quit(1)
		return
	cues = settings.cues
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, "RC018Audition")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus, capture)
	player = AudioStreamPlayer.new()
	player.bus = "RC018Audition"
	root.add_child(player)
	if "--verify" in OS.get_cmdline_user_args():
		await _verify()
	else:
		_ui()

func _ui() -> void:
	root.title = "Rune Cast • RC-018 isolated sound audition"
	root.size = Vector2i(880, 800)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	status = Label.new()
	status.text = "21 runtime cues • intended relative gains • no gameplay scene\nFuture-only labels mean gameplay hook not implemented.\nGrouped sequences and indexed reel: output/audio/rc-018/index.html"
	box.add_child(status)
	var stop := Button.new()
	stop.text = "Stop"
	stop.pressed.connect(func(): player.stop())
	box.add_child(stop)
	for cue in cues:
		var button := Button.new()
		button.text = "%s • %s • %+.1f dB%s" % [cue.cue_id, cue.manifest_id, cue.intended_gain_db, " • FUTURE ONLY" if cue.future_only else ""]
		button.pressed.connect(_play.bind(cue))
		box.add_child(button)

func _play(cue: Dictionary) -> void:
	player.stop()
	player.stream = load("res://" + str(cue.runtime_path).trim_prefix("res://"))
	player.volume_db = float(cue.intended_gain_db)
	player.play()
	status.text = "Playing %s • %+.1f dB%s" % [cue.cue_id, cue.intended_gain_db, " • FUTURE ONLY" if cue.future_only else ""]

func _verify() -> void:
	var records: Array = []
	await create_timer(0.1).timeout
	for cue in cues:
		var path := "res://" + str(cue.runtime_path).trim_prefix("res://")
		var stream = load(path)
		if not stream is AudioStreamWAV:
			failures.append(str(cue.cue_id) + ": imported resource is not AudioStreamWAV")
			continue
		var duration: float = stream.get_length()
		var correct_format: bool = stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == 48000 and not stream.stereo
		if not correct_format: failures.append(str(cue.cue_id) + ": unexpected imported PCM format")
		var pcm_payload := _wav_pcm(path)
		var identical_pcm: bool = pcm_payload == stream.data
		if not identical_pcm: failures.append(str(cue.cue_id) + ": imported data differs from runtime WAV PCM bytes")
		capture.clear_buffer()
		player.stream = stream
		player.volume_db = float(cue.intended_gain_db)
		var started := Time.get_ticks_msec()
		var start_frame := mix_pcm.size() / 4
		var frames := 0
		var nonzero := 0
		var peak := 0.0
		var sum_squares := 0.0
		var positions: Array = []
		player.play()
		await process_frame
		while player.playing and Time.get_ticks_msec() - started < int((duration + 2.0) * 1000):
			positions.append(player.get_playback_position())
			var samples := capture.get_buffer(capture.get_frames_available())
			for sample in samples:
				frames += 1
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
				sum_squares += (sample.x * sample.x + sample.y * sample.y) * 0.5
				if absf(sample.x) > 0.000001 or absf(sample.y) > 0.000001: nonzero += 1
				_append_sample(sample)
			await process_frame
		var completed := not player.playing
		await create_timer(0.06).timeout
		var tail := capture.get_buffer(capture.get_frames_available())
		for sample in tail:
			frames += 1
			peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
			sum_squares += (sample.x * sample.x + sample.y * sample.y) * 0.5
			if absf(sample.x) > 0.000001 or absf(sample.y) > 0.000001: nonzero += 1
			_append_sample(sample)
		var advanced: bool = positions.size() > 0 and float(positions.back()) > 0.0
		if not completed or not advanced or nonzero == 0 or not is_finite(peak) or peak >= 1.0: failures.append(str(cue.cue_id) + ": playback/completion/nonzero/headroom failure")
		var expected_duration := float(cue.duration_seconds)
		if absf(duration - expected_duration) > 1.0 / 48000.0: failures.append(str(cue.cue_id) + ": imported length changed")
		records.append({"cue_id": cue.cue_id, "runtime_path": cue.runtime_path, "runtime_sha256": FileAccess.get_sha256(path),
			"intended_gain_db": cue.intended_gain_db, "duration_seconds": duration, "sample_rate": stream.mix_rate,
			"format": "AudioStreamWAV.FORMAT_16_BITS", "channels": 2 if stream.stereo else 1,
			"imported_pcm_identical": identical_pcm, "runtime_pcm_sha256": _sha256(pcm_payload), "imported_pcm_sha256": _sha256(stream.data),
			"finished": completed, "position_advanced": advanced,
			"captured_frames": frames, "nonzero_frames": nonzero, "captured_peak_linear": peak,
			"captured_peak_dbfs": linear_to_db(peak), "captured_rms_dbfs": linear_to_db(sqrt(sum_squares / maxf(frames, 1))),
			"capture_start_seconds": float(start_frame) / AudioServer.get_mix_rate(),
			"capture_end_seconds": float(mix_pcm.size() / 4) / AudioServer.get_mix_rate()})
		player.stop()
	var mixed := AudioStreamWAV.new()
	mixed.format = AudioStreamWAV.FORMAT_16_BITS
	mixed.mix_rate = int(AudioServer.get_mix_rate())
	mixed.stereo = true
	mixed.data = mix_pcm
	var saved := mixed.save_to_wav("res://output/audio/rc-018/godot-mix-capture.wav")
	if saved != OK: failures.append("Could not save captured mix")
	var report := {"engine": Engine.get_version_info().string, "audio_driver": AudioServer.get_driver_name(),
		"mix_sample_rate": AudioServer.get_mix_rate(), "method": "Real imported AudioStreamWAV through AudioStreamPlayer at intended gain; AudioEffectCapture on isolated bus before Master; finite nonzero mix, playback progress and natural completion checked.",
		"listening_review": "No human headphone/speaker review claimed. Captured internal engine output is automated evidence only.",
		"capture_file": "output/audio/rc-018/godot-mix-capture.wav", "cues": records, "failures": failures, "passed": failures.is_empty() and records.size() == 21}
	var file := FileAccess.open("res://output/audio/rc-018/godot-playback.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("RC018 Godot import/playback: %d cues, %d failures, driver %s" % [records.size(), failures.size(), AudioServer.get_driver_name()])
	quit(0 if failures.is_empty() and records.size() == 21 else 1)

func _append_sample(sample: Vector2) -> void:
	for value in [sample.x, sample.y]:
		var pcm := clampi(roundi(value * 32767.0), -32768, 32767)
		mix_pcm.append(pcm & 255)
		mix_pcm.append((pcm >> 8) & 255)

func _wav_pcm(path: String) -> PackedByteArray:
	var bytes := FileAccess.get_file_as_bytes(path)
	var offset := 12
	while offset + 8 <= bytes.size():
		var size := bytes.decode_u32(offset + 4)
		if bytes.slice(offset, offset + 4).get_string_from_ascii() == "data":
			return bytes.slice(offset + 8, offset + 8 + size)
		offset += 8 + size + (size % 2)
	return PackedByteArray()

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
