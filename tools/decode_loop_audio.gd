extends SceneTree
## RC-019 offline MP3/Ogg -> stereo float32 PCM. No player, buses, recording, or wall clock.
## Godot 4.7.2 AudioStreamPlayback.mix_audio returns frames at AudioServer mix rate.
## -- --manifest=absolute.json --output-dir=absolute-directory

func _initialize() -> void:
	call_deferred("_run")

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _run() -> void:
	var manifest_path := ""
	var output_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--manifest="): manifest_path = arg.trim_prefix("--manifest=")
		if arg.begins_with("--output-dir="): output_dir = arg.trim_prefix("--output-dir=")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or output_dir.is_empty():
		push_error("Expected --manifest JSON with sources and --output-dir")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Could not create decoder output directory")
		quit(1)
		return
	var rate := int(AudioServer.get_mix_rate())
	var records: Array = []
	var failures: Array = []
	for source in manifest.sources:
		var path := str(source.path)
		var original := FileAccess.get_file_as_bytes(path)
		var stream: AudioStream
		if path.get_extension().to_lower() == "ogg":
			stream = AudioStreamOggVorbis.load_from_file(path)
		else:
			stream = AudioStreamMP3.new()
			stream.data = original
		stream.loop = false
		var duration := stream.get_length()
		if original.is_empty() or duration <= 0:
			failures.append(str(source.cue_id) + ": MP3 decode failed")
			continue
		var playback := stream.instantiate_playback()
		var pcm := PackedFloat32Array()
		var guard_frames := ceili((duration + 1.0) * rate)
		var frames := 0
		var finite := true
		playback.start(0.0)
		while playback.is_playing() and frames < guard_frames:
			var samples := playback.mix_audio(1.0, 4096)
			if samples.is_empty(): break
			for sample in samples:
				finite = finite and is_finite(sample.x) and is_finite(sample.y)
				pcm.append(sample.x)
				pcm.append(sample.y)
			frames += samples.size()
		var exhausted := not playback.is_playing()
		playback.stop()
		if not exhausted or not finite or frames == 0:
			failures.append(str(source.cue_id) + ": incomplete/nonfinite decoder output")
			continue
		var pcm_path := output_dir.path_join(str(source.cue_id) + ".f32le")
		var bytes := pcm.to_byte_array()
		var file := FileAccess.open(pcm_path, FileAccess.WRITE)
		if file == null:
			failures.append(str(source.cue_id) + ": cannot write decoded PCM")
			continue
		file.store_buffer(bytes)
		file.close()
		records.append({"cue_id": source.cue_id, "original_path": path,
			"original_sha256": _sha256(original), "pcm_path": pcm_path,
			"pcm_sha256": _sha256(bytes), "channels": 2, "sample_rate": rate,
			"format": "interleaved IEEE float32 little endian", "frames": frames,
			"stream_duration_seconds": duration, "decoded_duration_seconds": float(frames) / rate,
			"finite": finite, "completed": exhausted})
	var report := {"schema_version": 1, "engine": Engine.get_version_info().string,
		"audio_driver": AudioServer.get_driver_name(), "sample_rate": rate,
		"method": "Direct MP3/Ogg AudioStream.instantiate_playback().mix_audio(1.0,4096); no AudioStreamPlayer or realtime capture. Returned frame counts honored; float32 stereo saved before editing.",
		"decoder_script": "tools/decode_loop_audio.gd", "cues": records,
		"failures": failures, "passed": failures.is_empty() and records.size() == manifest.sources.size()}
	var report_file := FileAccess.open(output_dir.path_join("decode-report.json"), FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	report_file.close()
	print("RC-019 offline audio decode: %d sources, %d failures, %d Hz" % [records.size(), failures.size(), rate])
	quit(0 if report.passed else 1)
