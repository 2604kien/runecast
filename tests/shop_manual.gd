extends SceneTree
## Separate excluded manual shop route. The first real Wisp pays 100 fixture Gold.
const Fixture = preload("res://tests/helpers/shop_route_fixture.gd")
const DESTINATION := "res://output/qa/rc-029/manual"

class ManualShell extends "res://scripts/ui/application_shell.gd":
	func _start_new_run() -> void:
		if _closed or _transitioning or combat_scene != null or shop_screen != null: return
		_transitioning = true
		var candidate = Fixture.new_run()
		if progression != null: candidate._profile = progression.clone_for_transaction()
		_commit_transaction(candidate, "new_run")

func _initialize() -> void:
	call_deferred("_open")

func _open() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.title = "Rune Cast — shop integration fixture"
	root.size = Vector2i(450, 1000)
	var app := ManualShell.new()
	app.settings_path = DESTINATION.path_join("settings.cfg")
	app.save_path = DESTINATION.path_join("runecast-save.json")
	app.persistence_context = Fixture.context_for(Fixture.new_run())
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("Shop fixture save: " + ProjectSettings.globalize_path(app.save_path))
