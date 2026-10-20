extends SceneTree
var checks := 0
var failures := 0
var assertions: Array = []

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	preload("res://tests/audio_catalogue_tests.gd").new().run(check)
	preload("res://tests/rc020_presentation_tests.gd").new().run(check)
	await preload("res://tests/audio_playback_tests.gd").new().run(check, self)
	await preload("res://tests/audio_settings_tests.gd").new().run(check, self)
	await preload("res://tests/audio_lifetime_tests.gd").new().run(check, self)
	await create_timer(0.2).timeout
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-020")
	var file := FileAccess.open("res://output/qa/rc-020/audio-tests.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-020 audio checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
