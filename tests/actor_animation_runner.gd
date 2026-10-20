extends SceneTree

var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": message})
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	await preload("res://tests/actor_animation_tests.gd").new().run(_check, self)
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-017/actor")
	var report := FileAccess.open("res://output/qa/rc-017/actor/results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "engine": Engine.get_version_info().string}, "  ") + "\n")
	print("%d RC-017 actor checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
