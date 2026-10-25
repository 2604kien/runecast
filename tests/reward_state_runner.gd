extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	preload("res://tests/reward_state_tests.gd").new().run(check)
	print("RC-027 reward core: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
