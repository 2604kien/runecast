extends SceneTree
## Isolated fixed-seed launch of the unmodified production application shell.
## Only New Run's existing seed argument and local save/settings paths differ.
const Shell = preload("res://scripts/ui/application_shell.gd")
var selected_seed := 1
var narrow := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="): selected_seed = int(argument.trim_prefix("--seed="))
		if argument == "--narrow": narrow = true
	call_deferred("_open")

func _open() -> void:
	var folder := "res://output/qa/rc-034/manual/seed-%d" % selected_seed
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(360, 640) if narrow else Vector2i(450, 1000)
	var app := Shell.new()
	app.save_path = folder.path_join("run.json")
	app.settings_path = folder.path_join("settings.cfg")
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.new_run_button.pressed.disconnect(app.request_new_run)
	app.new_run_button.pressed.connect(app.request_new_run.bind(selected_seed))
	print("Production RC-034 route seed %d. Home → New Run; Continue uses this isolated slot." % selected_seed)
	print("Normal walkthrough seed1: d1b, d2b Leave, d3, d4a, d5a, d6, d7 Leave, d8 Recover, d9.")
	print("Elite attempt seed6: d1a, d2b upgrade Conjure, d3, d4a, d5b, d6, d7 Leave, d8 Recover, d9.")
	print("Recorded legal commands and actual resources: output/qa/rc-034/play/. No automatic wins or resource changes.")
