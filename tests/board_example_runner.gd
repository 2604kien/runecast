extends SceneTree

const Examples = preload("res://scripts/dev/board_examples.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
var checks := 0
var failures := 0

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	preload("res://tests/board_example_tests.gd").new().run(_check)
	var reports: Array = []
	for board_id in Examples.BOARD_IDS:
		var loaded := Examples.load_example(board_id)
		if not loaded.ok:
			continue
		var model := Combat.new(loaded.setup)
		var controller := Controller.new(model)
		var report := Examples.apply(controller, loaded.example, "cast")
		report.commands = loaded.example.commands.duplicate(true)
		report.encounter_path = loaded.example.encounter_path
		report.purpose = loaded.example.purpose
		reports.append(report)
		_check(report.ok, "%s standalone witness report reproduces all expectations." % board_id)
		controller.dispose()
	var directory := "res://output/qa/rc-009/examples-%d-%d-%d" % [int(Time.get_unix_time_from_system()), OS.get_process_id(), Time.get_ticks_usec()]
	var path := directory + "/report.json"
	var made := DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(path, FileAccess.WRITE) if made == OK else null
	_check(file != null, "RC-009 standalone witness report opens a new evidence path.")
	if file != null:
		file.store_string(JSON.stringify({"version": Examples.VERSION, "automated": true,
			"checks": checks, "failures": failures, "examples": reports}, "  ") + "\n")
		file.close()
	print("%d authored-example checks, %d failures; report: %s" % [checks, failures, path])
	quit(0 if failures == 0 else 1)
