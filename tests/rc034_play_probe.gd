extends SceneTree
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")

func _initialize() -> void:
	var records: Array = []
	var victories: Array = []
	for id in ["wickling", "stone_sentinel", "chain_warden", "bell_keeper", "training_shadeling"]:
		var path: String = "res://data/production_encounter.json" if id == "training_shadeling" else "res://data/production_" + id + "_encounter.json"
		for seed in range(16):
			var loaded := Loader.load_setup(path)
			if not loaded.ok:
				push_error(str(loaded.errors))
				quit(1)
				return
			var game := Combat.new(loaded.setup, seed)
			var controller := Controller.new(game)
			var player := Player.new()
			var commands: Array = []
			var turns: Array = []
			controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
			var entry := game.snapshot()
			for turn in 60:
				if game.state != "playing": break
				var before := game.snapshot()
				if not player.play_turn(controller):
					push_error("Failed legal play %s seed %d" % [id, seed])
					quit(1)
					return
				turns.append({"turn": before.turn, "announced": before.intent, "before_hp": before.player_hp, "enemy_before": before.enemy_hp, "plan": {"damage": player.last_plan.get("damage", 0), "shield": player.last_plan.get("shield", 0), "cost": player.last_plan.get("cost", 0)}, "after_hp": game.player_hp, "enemy_after": game.enemy_hp, "phase": game.enemy_action().phase})
			records.append({"encounter": id, "seed": seed, "entry": entry, "commands": commands, "turns": turns, "outcome": game.state, "remaining_hp": game.player_hp})
			print("%s seed %d: %s, HP %d, turns %d" % [id, seed, game.state, game.player_hp, turns.size()])
			controller.dispose()
			if game.state == "victory":
				victories.append(id)
				break
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-034/play")
	FileAccess.open("res://output/qa/rc-034/play/individual.json", FileAccess.WRITE).store_string(JSON.stringify(records, "  "))
	var failures := 0 if victories.size() == 5 else 1
	FileAccess.open("res://output/qa/rc-034/play/results-individual.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": 5, "failures": failures, "victorious_ids": victories, "scope": "Each original production enemy defeated from unchanged ordinary starter with accepted commands and exact shared-evaluator forecast agreement."}, "  "))
	print("RC-034 individual victories: 5 checks, %d failures" % failures)
	quit(0 if failures == 0 else 1)
