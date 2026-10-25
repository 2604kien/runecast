extends SceneTree

var checks := 0
var failures: Array = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	preload("res://tests/rc033_core_tests.gd").new().run(check)
	var result := {"checks": checks, "failures": failures, "failure_count": failures.size(), "engine": Engine.get_version_info().string}
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-033/core")
	var file := FileAccess.open("res://output/qa/rc-033/core/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("RC-033 core: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
