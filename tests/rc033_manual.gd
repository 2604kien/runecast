extends SceneTree
## Excluded manual launcher: validated content and the ordinary Combat view.
const Fixture = preload("res://tests/helpers/rc033_fixture.gd")

func _initialize() -> void:
	call_deferred("_open")

func _open() -> void:
	var loaded := Fixture.load_fixture()
	if not loaded.ok:
		push_error("\n".join(loaded.errors))
		quit(2)
		return
	root.title = "Rune Cast — RC-033 excluded phase framework (not Bell Keeper)"
	root.size = Vector2i(360, 640) if "--narrow" in OS.get_cmdline_user_args() else Vector2i(450, 1000)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = loaded.setup
	scene.battle_model = Fixture.new_combat()
	scene.settings_path = "res://output/qa/rc-033/manual/settings.cfg"
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-033/manual")
	root.add_child(scene)
	print("EXCLUDED RC-033 framework: 400 HP, 20 energy/turn, 8 draws; six Spark + two Shield. Enemy 80 HP; 8/12/16, then 12/16/20 at <=40 HP. No run/profile or production content registration.")
	print("Tap the enemy attack. Pass twice, then Cast seven single-Spark circuits (6 damage each). Seventh Cast crosses 44 -> 38 with 16 still announced; the next turn begins phase two at 12. Pass to see 16,20,12. Exact replay returns to the original entry.")
	if "--at-threshold" in OS.get_cmdline_user_args():
		# Optional reproducible preparation uses only ordinary legal commands.
		# No HP, board, hand, phase, turn or random-state writes occur here.
		for count in 2:
			if not Fixture.command(scene.controller, "pass"):
				push_error("Fixture Pass failed.")
				quit(2)
				return
		for count in 6:
			if not Fixture.prepare_spark(scene.controller).get("ok", false) or not Fixture.command(scene.controller, "cast"):
				push_error("Fixture legal preparation failed.")
				quit(2)
				return
		if not Fixture.prepare_spark(scene.controller).get("ok", false):
			push_error("Fixture crossing preparation failed.")
			quit(2)
			return
		print("Prepared with two legal Passes and six legal single-Spark Casts: turn 9, enemy 44 HP, player 308 HP, announced attack16. Tap Cast to cross to38, take the old16, then inspect phase2 attack12.")
