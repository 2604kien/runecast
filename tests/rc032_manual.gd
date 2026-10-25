extends SceneTree
## Excluded playable development tower. Home and all rooms use shipped UI;
## only new-run content/profile policy and the isolated save slot differ.
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const DESTINATION := "res://output/qa/rc-032/manual"
var save_root := DESTINATION
var variant := "normal"
var exhausted := false

class ManualShell extends "res://scripts/ui/application_shell.gd":
	var exhausted_awards := false
	func _start_new_run() -> void:
		if _closed or _transitioning or combat_scene != null or shop_screen != null or service_screen != null: return
		_transitioning = true
		var candidate = Fixture.new_run(42, exhausted_awards)
		if progression != null: candidate._profile = progression.clone_for_transaction()
		_commit_transaction(candidate, "new_run")

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): save_root = arg.trim_prefix("--save-root=")
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
		if arg == "--exhausted": exhausted = true
	call_deferred("_open")

func _open() -> void:
	if not variant in ["normal", "elite"]:
		push_error("Use --variant=normal or --variant=elite; add --exhausted for an initially full definition-unlock pool.")
		quit(2)
		return
	var destination := save_root.path_join(variant + ("-exhausted" if exhausted else "-unlocks"))
	DirAccess.make_dir_recursive_absolute(destination)
	root.title = "Rune Cast — RC-032 DEVELOPMENT tower · guardian is not Bell Keeper"
	root.size = Vector2i(450, 1000)
	var app := ManualShell.new()
	app.exhausted_awards = exhausted
	app.settings_path = destination.path_join("settings.cfg")
	app.save_path = destination.path_join("runecast-save.json")
	app.persistence_context = Fixture.context_for(Fixture.new_run(42, exhausted))
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("RC-032 DEVELOPMENT fixture save: " + ProjectSettings.globalize_path(app.save_path))
	print("Home → New Run. Play all nine visits. At depth five choose " + variant + ". Every calibration normal/elite victory explicitly offers 250 fixture Gold. Shadeling is depth six; the distinct calibration guardian is depth nine.")
	print("Map → Menu → Store is available between fully settled rooms, including zero-Gold initial browsing. Store uses current-run Gold: 45 per rune and 90 per relic, one purchase per category per run. Resolve every result and required reward before returning to Store.")
