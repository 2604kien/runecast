extends SceneTree
## Focused entry point for the production draw/creation animation regression.
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
	await preload("res://tests/ui_card_arrival_tests.gd").new().run(check, self)
	print("%d card arrival checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
