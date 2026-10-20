extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	preload("res://tests/rc020_presentation_tests.gd").new().run(check)
	print("RC-020 presentation: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
