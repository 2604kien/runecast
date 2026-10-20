extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	await preload("res://tests/audio_settings_tests.gd").new().run(check, self)
	await create_timer(0.2).timeout
	print("%d audio settings checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
