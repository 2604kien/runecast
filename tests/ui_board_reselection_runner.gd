extends SceneTree
## Focused real-production-scene witness for selecting rotated board pieces.
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
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.sound_enabled = false
	await process_frame
	preload("res://tests/ui_production_tests.gd").new().board_reselection(scene, check)
	scene.audio.dispose()
	scene.queue_free()
	await process_frame
	print("%d board reselection checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
