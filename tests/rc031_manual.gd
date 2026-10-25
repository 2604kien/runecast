extends SceneTree
## Excluded manual fixture: play the real Wisp, claim its explicit fixture Gold,
## then enter the selected item room. No automatic victories or item grants.
const Fixture = preload("res://tests/helpers/rc031_ui_fixture.gd")
const DESTINATION := "res://output/qa/rc-031/manual"
const VARIANTS := ["shop", "recovery", "desk", "reliquary"]
var variant := "shop"

class ManualShell extends "res://scripts/ui/application_shell.gd":
	var fixture_variant := "shop"
	func _start_new_run() -> void:
		if _closed or _transitioning or combat_scene != null or shop_screen != null or service_screen != null: return
		_transitioning = true
		var candidate = Fixture.new_run(42, fixture_variant)
		if progression != null: candidate._profile = progression.clone_for_transaction()
		_commit_transaction(candidate, "new_run")

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--variant="): variant = argument.trim_prefix("--variant=")
	call_deferred("_open")

func _open() -> void:
	if not variant in VARIANTS:
		push_error("Unknown RC-031 fixture variant; choose shop, recovery, desk or reliquary.")
		quit(2)
		return
	var destination := DESTINATION.path_join(variant)
	DirAccess.make_dir_recursive_absolute(destination)
	root.title = "Rune Cast — upgrades and relics integration fixture"
	root.size = Vector2i(450, 1000)
	var app := ManualShell.new()
	app.fixture_variant = variant
	app.settings_path = destination.path_join("settings.cfg")
	app.save_path = destination.path_join("runecast-save.json")
	app.persistence_context = Fixture.context_for(Fixture.new_run(42, variant))
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("RC-031 fixture save: " + ProjectSettings.globalize_path(app.save_path))
	print("New Run starts the real Wisp. Win, claim the explicit 160 Gold fixture reward, then enter " + variant + ".")
