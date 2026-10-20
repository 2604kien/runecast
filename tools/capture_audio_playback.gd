extends SceneTree
## RC-020 actual playable-scene evidence. Uses real imported playback and the
## production automatic clock; captures the Master mix and rendered frames.
const ProductionUI = preload("res://tests/ui_production_tests.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DEST := "res://output/qa/rc-020/demo"

var scene: Control
var capture: AudioEffectCapture
var helper := ProductionUI.new()
var pcm := PackedByteArray()
var samples := 0
var nonzero := 0
var peak := 0.0
var sum_squares := 0.0
var clipped := 0
var frames: Array = []
var sequences: Array = []
var failures: Array = []
var current_label := "Opening crypt ambience"
var next_frame := 0.0
var recording := false
var maximum_voices := 0

func _initialize() -> void:
	call_deferred("_run")

func _process(_delta: float) -> bool:
	if recording:
		_drain_audio()
		if is_instance_valid(scene): maximum_voices = maxi(maximum_voices, scene.audio.active_voice_count())
	return false

func _drain_audio() -> void:
	if capture == null: return
	var buffer := capture.get_buffer(capture.get_frames_available())
	for sample in buffer:
		samples += 1
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		sum_squares += (sample.x * sample.x + sample.y * sample.y) * 0.5
		if absf(sample.x) > 0.000001 or absf(sample.y) > 0.000001: nonzero += 1
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
		for value in [sample.x, sample.y]:
			var value_pcm := clampi(roundi(value * 32767.0), -32768, 32767)
			pcm.append(value_pcm & 255)
			pcm.append((value_pcm >> 8) & 255)

func _seconds() -> float:
	return float(samples) / AudioServer.get_mix_rate()

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST.path_join("frames"))
	root.size = Vector2i(450, 1000)
	root.content_scale_size = Vector2i(450, 1000)
	root.title = "Rune Cast RC-020 — actual playable audio capture"
	capture = AudioEffectCapture.new()
	capture.buffer_length = 4.0
	AudioServer.add_bus_effect(0, capture)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = DEST.path_join("demo-settings.cfg")
	Settings.save_values(Settings.DEFAULTS, scene.settings_path)
	root.add_child(scene)
	scene.audio.trace_enabled = true
	scene.audio.set_interrupted(false)
	recording = true
	await _wait(0.8)
	_check(scene.startup_error.is_empty() and scene.animation_presenter != null, "Actual production main scene loads with its animated presenter.")
	_check(scene.audio.loop_snapshot().ambience.cue == "crypt", "Crypt starts in production Combat.")
	await _menu_probe()
	for specification in [["conjure", false], ["focus", false], ["cast", false], ["shield", false], ["pass", false], ["cast", true], ["shield", true], ["pass", true], ["victory", false], ["defeat", true]]:
		await _action(specification[0], specification[1])
	await _loop_probe()
	await _wait(0.5)
	var final_trace: Array = scene.audio.trace.duplicate(true)
	var loops: Dictionary = scene.audio.loop_snapshot()
	maximum_voices = maxi(maximum_voices, scene.audio.peak_voices)
	_check(maximum_voices <= 8, "Real-scene SFX voices stay within eight including release tails.")
	_check(loops.music.all(func(slot): return slot.cue == "") and loops.starts.music == 0, "Unavailable music stays a valid no-music state.")
	scene.queue_free()
	await _wait(0.1)
	recording = false
	_drain_audio()
	_check(nonzero > 0 and is_finite(peak) and clipped == 0, "Actual mixed output is finite, nonzero and unclipped.")
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(AudioServer.get_mix_rate())
	stream.stereo = true
	stream.data = pcm
	_check(stream.save_to_wav(DEST.path_join("playable-mix.wav")) == OK, "Captured internal Master mix saves.")
	var report := {"engine": Engine.get_version_info().string, "audio_driver": AudioServer.get_driver_name(),
		"sample_rate": AudioServer.get_mix_rate(), "seconds": _seconds(), "captured_frames": samples,
		"nonzero_frames": nonzero, "sample_peak_linear": peak, "sample_peak_dbfs": linear_to_db(peak),
		"rms_dbfs": linear_to_db(sqrt(sum_squares / maxf(samples, 1))), "clipped_frames": clipped,
		"max_sfx_voices": maximum_voices, "loop_snapshot": loops, "sequences": sequences,
		"cue_trace": final_trace, "frames": frames, "failures": failures, "passed": failures.is_empty(),
		"method": "Ordinary main.tscn, production automatic presentation clock, real UI handlers and imported player streams; AudioEffectCapture at Master. Rendered samples synchronize to captured PCM positions. Explicit fixture changes precede action resolution.",
		"listening": "Internal measured playback only. No headphone, speaker, mobile-device or human perceived-balance acceptance is claimed.",
		"loop_probe": "Seek the active imported crypt stream to 0.2 seconds before its end; observe the real player wrap and position continuity. This is not a full 58-second listening cycle or five-join acceptance."}
	_write_json(DEST.path_join("results.json"), report)
	print("RC020 actual-scene capture: %d sequences, %.3f seconds, %.3f dBFS sample peak, %d voices, %d failures" % [sequences.size(), _seconds(), linear_to_db(peak), maximum_voices, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await process_frame
		elapsed += root.get_process_delta_time()
		await _frame()

func _frame(force := false) -> void:
	if not recording or not is_instance_valid(scene) or not scene.is_inside_tree(): return
	if not force and _seconds() < next_frame: return
	await RenderingServer.frame_post_draw
	_drain_audio()
	var filename := "frames/frame-%04d.jpg" % frames.size()
	root.get_texture().get_image().save_jpg(DEST.path_join(filename), 0.85)
	frames.append({"seconds": _seconds(), "image": filename, "label": current_label,
		"phase": scene.animation_presenter.phase if scene.animation_presenter != null else "",
		"phase_progress": scene.animation_presenter.phase_progress if scene.animation_presenter != null else 0.0})
	next_frame = _seconds() + 0.15

func _menu_probe() -> void:
	current_label = "Menu / Options preserve the crypt bed"
	var before: Dictionary = scene.audio.loop_snapshot()
	scene._open_menu()
	await _wait(0.4)
	scene._open_options()
	await _wait(0.6)
	await _frame(true)
	scene._close_options()
	scene.menu.hide()
	await _wait(0.25)
	var after: Dictionary = scene.audio.loop_snapshot()
	_check(after.starts == before.starts and after.ambience.position > before.ambience.position, "Menu and Options preserve the same advancing crypt player.")
	sequences.append({"kind": "menu_options", "before": before, "after": after})

func _action(kind: String, reduced: bool) -> void:
	current_label = "%s — %s motion" % [kind.capitalize(), "reduced" if reduced else "normal"]
	scene._exact_replay()
	scene.set_reduced_motion(reduced)
	scene.audio.set_interrupted(false)
	await _wait(0.15)
	var model = scene.controller._combat
	if kind in ["cast", "victory"] and helper._effect_uid(scene.game, true) < 0:
		for card in scene.game.hand.duplicate(true):
			if card.id == "conjure":
				scene._select_card(int(card.uid))
				await _finish_action()
				break
	if kind == "shield":
		for index in range(model.hand.size()):
			if model.hand[index].id == "shield":
				var card: Dictionary = model.hand[index]
				model.hand.remove_at(index)
				model.hand.push_front(card)
				break
	if kind == "victory": model.enemy_hp = 1
	if kind == "defeat": model.player_hp = 1
	scene._refresh()
	if kind in ["cast", "shield", "victory"]:
		_check(helper._build(scene, kind != "shield"), "Playable controls construct " + kind + " circuit.")
	await _wait(0.3)
	var start := _seconds()
	var first_trace: int = scene.audio.trace.size()
	var before: Dictionary = scene.controller.snapshot()
	if kind in ["conjure", "focus"]:
		var uid := -1
		for card in scene.game.hand:
			if card.id == kind: uid = int(card.uid)
		_check(uid >= 0, "Natural opening supplies " + kind)
		if uid >= 0: scene._select_card(uid)
	elif kind in ["pass", "defeat"]:
		scene._request_pass()
		scene.inspector_confirm_pass.pressed.emit()
	else: scene.cast_button.pressed.emit()
	var resolved: Dictionary = scene.controller.snapshot()
	var nominal: float = scene.animation_presenter.duration
	await _finish_action(resolved)
	await _wait(0.5 if kind not in ["victory", "defeat"] else 1.6)
	sequences.append({"kind": kind, "reduced_motion": reduced, "start_seconds": start,
		"end_seconds": _seconds(), "nominal_presentation_seconds": nominal,
		"before": before, "after": resolved, "trace": scene.audio.trace.slice(first_trace)})

func _finish_action(resolved: Dictionary = {}) -> void:
	var elapsed := 0.0
	while scene.controller.is_busy() and elapsed < 20.0:
		await process_frame
		elapsed += root.get_process_delta_time()
		await _frame()
		if not resolved.is_empty(): _check(scene.controller.snapshot() == resolved, "Audio/render sampling leaves the resolved combat state unchanged.")
	_check(not scene.controller.is_busy(), "Actual automatic presentation completes without audio completion calls.")

func _loop_probe() -> void:
	current_label = "Crypt wrap probe — seeking near imported loop end"
	var bed: AudioStreamPlayer = scene.audio.get_node("CryptAmbience")
	var starts: Dictionary = scene.audio.loop_snapshot().starts
	bed.seek(bed.stream.get_length() - 0.2)
	await _wait(0.7)
	_check(bed.playing and bed.get_playback_position() < 1.5 and scene.audio.loop_snapshot().starts == starts, "The existing crypt player wraps its imported full-file loop without a new start.")

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  ") + "\n")
