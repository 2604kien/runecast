extends SceneTree
## Run using --main-pack runtime.pck --script <absolute path to this file>.
## The pack owns res://; source docs and test files are deliberately unavailable.
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	check(not FileAccess.file_exists("res://docs/audio-cue-catalogue.json") and not FileAccess.file_exists("res://docs/audio-loop-catalogue.json"), "Export probe has no source documentation")
	var catalogue = load("res://scripts/audio/audio_catalogue.gd")
	check(catalogue != null and catalogue.SFX.size() == 21, "Shipped metadata exists independently")
	for entry in catalogue.SFX.values():
		var stream = load(entry.runtime_path)
		check(stream is AudioStreamWAV and stream.get_length() > 0.0, "Shipped SFX imports and decodes: " + entry.runtime_path)
	check(catalogue.LOOPS.home_exploration.runtime_path == "" and catalogue.LOOPS.combat.runtime_path == "", "Pending music has no load path")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "user://export-probe-settings.cfg"
	root.add_child(scene)
	await process_frame
	check(scene.startup_error == "" and scene.controller != null, "Pack launches playable production scene")
	scene.audio.apply_settings({"enabled": true, "music_muted": false, "sfx_muted": false})
	check(scene.audio._ambience.player.stream is AudioStreamOggVorbis, "Packed crypt remains imported compressed Vorbis")
	check(scene.audio._ambience.player.stream.loop, "Packed ambience retains looping import")
	scene.audio.trace_enabled = true
	scene._pass()
	scene.animation_presenter.finish()
	check(scene.audio.trace.any(func(record): return record.role == "actor"), "Packed accepted Pass starts supplied actor audio")
	scene.audio.dispose()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("%d exported audio checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
