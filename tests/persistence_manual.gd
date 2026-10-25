extends SceneTree
## Excluded manual restart fixture. It never reads/writes the production slot.
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/rc-028/manual"

class ManualShell extends "res://scripts/ui/application_shell.gd":
	func _start_new_run() -> void:
		if _closed or _transitioning or combat_scene != null: return
		_transitioning = true
		var candidate = Fixture.new_run(42)
		if progression != null: candidate._profile = progression.clone_for_transaction()
		_commit_transaction(candidate, "new_run")

func _init() -> void:
	call_deferred("_open")

func _open() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.title = "Rune Cast — RC-028 saved reward test fixture"
	root.size = Vector2i(450, 1000)
	var registry = Fixture.new_run(42)
	var context: Dictionary = registry.restore_context_for_tests()
	for id in ["d1a", "d2a", "d2b"]:
		var resolved: Dictionary = registry._resolver.resolve(registry._route._nodes[id], registry._entry_data())
		if resolved.get("ok", false): context.setups[Run.content_signature(resolved.setup)] = resolved.setup
	var app := ManualShell.new()
	app.settings_path = DESTINATION.path_join("settings.cfg")
	app.save_path = DESTINATION.path_join("runecast-save.json")
	app.persistence_context = context
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("Manual RC-028 fixture save: " + ProjectSettings.globalize_path(app.save_path))
