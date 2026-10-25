extends SceneTree

var checks := 0
var failures: Array = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	preload("res://tests/instance_effect_tests.gd").new().run(check)
	for path in ["res://tests/content_loading_tests.gd", "res://tests/combat_configuration_tests.gd", "res://tests/experiment_combat_tests.gd", "res://tests/full_reset_tests.gd", "res://tests/undirected_circuit_tests.gd", "res://tests/production_content_tests.gd", "res://tests/production_combat_tests.gd"]:
		load(path).new().run(check)
	var result := {"checks": checks, "failures": failures, "failure_count": failures.size(), "engine": Engine.get_version_info().string}
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-031/effects")
	var file := FileAccess.open("res://output/qa/rc-031/effects/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("RC-031 instance effects: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
