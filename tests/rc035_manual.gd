extends SceneTree
## Isolated catalogue exploration. All extra profile/Combat resources are
## declared before construction; Store funding comes from a real fixture battle.
const Fixture = preload("res://tests/helpers/rc035_catalogue_fixture.gd")
const Shop = preload("res://tests/helpers/shop_route_fixture.gd")
const Shell = preload("res://scripts/ui/application_shell.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
var mode := "store"
var narrow := false
var smoke := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="): mode = argument.trim_prefix("--mode=")
		if argument == "--narrow": narrow = true
		if argument == "--smoke": smoke = true
	call_deferred("_open")

func _open() -> void:
	var folder := "res://output/qa/rc-035/manual/" + mode
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(360, 640) if narrow else Vector2i(450, 1000)
	if mode == "combat":
		var setup: Dictionary = Loader.load_setup("res://data/production_stone_sentinel_encounter.json").setup
		setup.owned_cards = Fixture.IDS.duplicate()
		setup.opening_draw = Fixture.IDS.size()
		setup.encounter.player_health = 400
		setup.encounter.player_max_health = 400
		var scene = load("res://scenes/main.tscn").instantiate()
		scene.entry_setup = setup
		scene.battle_model = Combat.new(setup, 42)
		scene.settings_path = folder.path_join("settings.cfg")
		root.add_child(scene)
		print("EXCLUDED RC-035 gallery: all twelve initially owned, twelve-card opening, 400 initial HP; normal three energy. This is not the production starter or balance evidence.")
		print("Drag the hand; Info/hold inspects. Deep Focus and Twin Conjure activate by tapping. Mixed runes place normally and pay once on Cast.")
		await _smoke_exit()
		return
	var prepared: Dictionary
	if mode == "upgrade": prepared = Fixture.upgraded("cinder_guard")
	else:
		var subject = Fixture.new_run()
		prepared = Shop.win_first(subject)
		if prepared.ok: prepared.run = subject
	if not prepared.get("ok", false):
		push_error(str(prepared.get("error", "Catalogue fixture failed.")))
		quit(1)
		return
	var app := Shell.new()
	app.save_path = folder.path_join("run-" + str(Time.get_ticks_usec()) + ".json")
	app.settings_path = folder.path_join("settings.cfg")
	app.persistence_context = Shop.context_for(prepared.run)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.run_state = prepared.run
	app.progression = prepared.run.profile_state()
	var saved: Dictionary = app._persist_candidate(prepared.run)
	if not saved.ok:
		push_error(str(saved.get("error", "Fixture save failed.")))
		quit(1)
		return
	app.continue_run()
	print("EXCLUDED RC-035 fixture: full initial profile, unchanged eight-card starter, real Wisp victory with explicit 500 fixture Gold. Fixture funding does not establish production affordability.")
	print("Menu → Store browses twelve runes and six relics at the normal 45/90 prices and run limits. Collection inspects exact owned copies. Save: " + app.save_path)
	if mode == "upgrade": print("Cinder Guard was purchased through Store and refined through the supported recovery service. Collection shows its exact rank-one UID and 6 damage / 4 shield.")
	await _smoke_exit()

func _smoke_exit() -> void:
	if not smoke: return
	for frame in 20: await process_frame
	for child in root.get_children(): child.queue_free()
	for frame in 10: await process_frame
	await create_timer(0.3).timeout
	quit(0)

