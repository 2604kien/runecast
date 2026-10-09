extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	var directory := "res://output/qa/rc-009/board-capture-%d-%d" % [int(Time.get_unix_time_from_system()), OS.get_process_id()]
	if DisplayServer.get_name() == "headless": directory = ""
	await preload("res://tests/ui_board_catalog_tests.gd").new().run_followup(_check, self, directory)
	print("%d board scene/capture checks, %d failures; captures: %s" % [checks, failures, directory])
	quit(0 if failures == 0 else 1)
