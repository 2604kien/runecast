extends SceneTree
## Production application, ordinary configuration, legal actions and real saves.
## No fixture resolver, fake visits, resource injection or forced outcomes.
const Shell = preload("res://scripts/ui/application_shell.gd")
const Journey = preload("res://tests/helpers/rc034_journey.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
var output := "res://output/qa/rc-034/shell"
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []
var capturing := false

func check(value: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": message})
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	capturing = "--capture-rc034-shell" in OS.get_cmdline_user_args()
	call_deferred("_run")

func settle() -> void:
	for frame in 5: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await settle()
	if capturing: check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, name + ": screenshot saved at actual window.")

func create_shell(path: String) -> Control:
	var app := Shell.new()
	app.save_path = path
	app.settings_path = path + ".cfg"
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return app

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await journey(1, "normal", dimensions)
		await journey(6, "elite", dimensions)
		await ossuary_normal(dimensions)
	await create_timer(0.3).timeout
	var suffix := "capture" if capturing else "headless"
	FileAccess.open(output.path_join("results-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  "))
	FileAccess.open(output.path_join("traces-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  "))
	print("RC-034 production shell: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func retry_failure(app, before: Dictionary, label: String) -> void:
	check(not app._failed_transaction.is_empty(), label + ": failed save retains a concrete candidate.")
	if app._failed_transaction.is_empty(): return
	var intended: Dictionary = app._failed_transaction.candidate.export_save()
	check(app.run_state.export_save() == before, label + ": failed save preserves authoritative owners.")
	check(app.save_store.load().payload.run == before, label + ": fresh disk load has only prior durable progress.")
	app.retry_save()
	check(not app._failed_transaction.is_empty() and app._failed_transaction.candidate.export_save() == intended, label + ": failing Retry retains the identical candidate.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(app._failed_transaction.is_empty() and app.run_state.export_save() == intended, label + ": successful Retry publishes the candidate exactly once.")

func journey(seed: int, branch: String, dimensions: Vector2i) -> void:
	var tag := "%s-seed%d-%dx%d" % [branch, seed, dimensions.x, dimensions.y]
	var path := output.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var app := create_shell(path)
	await settle()
	check(app.home.visible and app.run_state == null, tag + ": clean Home starts without a run.")
	app.request_new_run(seed)
	await settle()
	check(app.run_state != null and app.map_screen != null and app.run_state.snapshot().owned_cards.size() == 8 and app.run_state.snapshot().player_hp == 30, tag + ": ordinary New Run creates unchanged starter and unvisited Map.")
	if app.run_state == null: return
	var ended := false
	for depth in range(1, 10):
		var id := Journey.next_node(app.run_state, branch)
		var node: Dictionary = app.run_state.inspect_node(id)
		var before: Dictionary = app.run_state.export_save()
		app.map_screen.inspect_node(id)
		await settle()
		check(app.run_state.export_save() == before, tag + ": depth%d inspection is pure." % depth)
		app.map_screen.inspection_action.pressed.emit()
		await settle()
		check(app.confirmation.visible and app.run_state.export_save() == before, tag + ": entry requires confirmation at depth%d." % depth)
		var failure_case := branch == "normal" and depth == 1
		if failure_case: app.save_store.failure_point = "replace"
		app.confirmation_confirm.pressed.emit()
		await settle()
		if failure_case: await retry_failure(app, before, tag + " entry")
		check(app.run_state.route_snapshot().visit_count == depth, tag + ": exactly one visit committed.")
		if app.run_state.route_snapshot().visit_count != depth: break
		if node.room_type in ["normal", "elite", "guardian"]:
			check(app.combat_scene != null, tag + ": real battle owns screen.")
			if app.combat_scene == null: break
			var opening: Dictionary = app.combat_scene.controller.snapshot()
			var stored: Dictionary = app.run_state.export_save()
			app.combat_scene.controller.set_presenter(Immediate.new())
			var begin := 0
			for cell in 16:
				if opening.board[cell].get("kind") == "begin": begin = cell
			check(app.combat_scene.controller.command("rotate", {"index": begin}), tag + ": legal preparation before Home.")
			app.request_home()
			app.confirm_home()
			await settle()
			check(app.home.visible and app.combat_scene == null, tag + ": Quit returns Home.")
			app.continue_button.pressed.emit()
			await settle()
			check(app.combat_scene != null and app.combat_scene.controller.snapshot() == opening, tag + ": Continue replays exact committed entry.")
			app.queue_free()
			await settle()
			app = create_shell(path)
			await settle()
			app.continue_button.pressed.emit()
			await settle()
			check(app.combat_scene != null and app.combat_scene.controller.snapshot() == opening, tag + ": reconstructed shell loads exact entry for " + node.enemy_id)
			if app.combat_scene == null: break
			await capture("entry-depth%d-" % depth + tag)
			var controller = app.combat_scene.controller
			var game = app.combat_scene.battle_model
			controller.set_presenter(Immediate.new())
			var commands: Array = []
			controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
			var player := Player.new()
			before = app.run_state.export_save()
			if failure_case: app.save_store.failure_point = "replace"
			for turn in 80:
				if game.state != "playing": break
				check(player.play_turn(controller), tag + ": real legal turn at depth%d." % depth)
			await settle()
			if failure_case: await retry_failure(app, before, tag + " outcome")
			traces.append({"variant": tag, "depth": depth, "node": node, "entry": opening, "entry_run": stored, "commands": commands, "outcome": game.state, "hp": game.player_hp})
			check(commands.all(func(command): return command.accepted), tag + ": every controller command was accepted.")
			check(app.run_state.snapshot().pending_result.get("outcome") == game.state, tag + ": actual outcome saved before review.")
			if game.state == "defeat":
				check(branch == "elite" and depth == 9, tag + ": recorded elite attempt reaches guardian and loses honestly.")
				app.confirmation_confirm.pressed.emit()
				await settle()
				ended = true
				break
			if depth in [6, 9]: check(not app.run_state.snapshot().tower_completed, tag + ": Shadeling/guardian outcome alone never bypasses required choices.")
			if not await rewards(app, tag, failure_case): break
		else:
			if node.room_type == "shop":
				check(app.shop_screen != null and app.run_state.snapshot().gold < 30, tag + ": ordinary zero-income shop remains browseable with honest affordability.")
				await capture("shop-" + tag)
				app.shop_screen.leave_button.pressed.emit()
			else:
				var choice := Journey.service_choice(app.run_state)
				app.service_screen.select_choice(choice.choice)
				if choice.target != null: app.service_screen.select_upgrade(choice.target)
				app.service_screen.confirm_choice()
			await settle()
			check(app.map_screen != null, tag + ": actual room API completes visit.")
		check(app.save_store.load().payload.run == app.run_state.export_save(), tag + ": published progress equals durable save after depth%d." % depth)
		if depth == 9: ended = true
	check(ended and app.run_state.snapshot().final_results_ready and app.run_review.visible, tag + ": final result is reachable after real played outcome.")
	await capture("results-" + tag)
	if app.run_state.snapshot().final_results_ready:
		var final: Dictionary = app.run_state.export_save()
		check(not app.run_state.continue_battle().ok and not app.run_state.request_room_entry("d9").ok and app.run_state.export_save() == final, tag + ": terminal review cannot replay a fight.")
		for record in app.run_state.snapshot().reward_records:
			check(not app.run_state.choose_reward(record.identity, "conjure").ok, tag + ": terminal receipt cannot be reclaimed.")
		app.run_review.secondary_button.pressed.emit()
		await settle()
		app.queue_free()
		await settle()
		app = create_shell(path)
		await settle()
		app.continue_button.pressed.emit()
		await settle()
		check(app.run_review.visible and app.combat_scene == null, tag + ": Home Continue after reconstruction reopens read-only final results.")
	app.queue_free()
	await settle()

func rewards(app, tag: String, failure_case: bool) -> bool:
	app.open_rewards()
	await settle()
	for step in 8:
		var record: Dictionary = app.run_state.pending_reward()
		if record.is_empty(): break
		var before: Dictionary = app.run_state.export_save()
		if failure_case: app.save_store.failure_point = "replace"
		if not record.gold_claimed: app.reward_screen.gold_button.pressed.emit()
		elif record.resolution == "pending":
			var id := Journey.choose_card(record)
			if id.is_empty(): app.reward_screen.skip_button.pressed.emit()
			else: app.reward_screen.choose_buttons[id].pressed.emit()
		await settle()
		if failure_case:
			await retry_failure(app, before, tag + " reward")
			failure_case = false
	check(app.run_state.pending_reward().is_empty(), tag + ": all required rune/permanent choices settled.")
	app.reward_screen.close_button.pressed.emit()
	await settle()
	if not app.run_state.snapshot().pending_result.is_empty(): app.confirmation_confirm.pressed.emit()
	await settle()
	return app.run_state.pending_reward().is_empty()

func ossuary_normal(dimensions: Vector2i) -> void:
	var tag := "stone-ossuary-seed6-%dx%d" % [dimensions.x, dimensions.y]
	var path := output.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var app := create_shell(path)
	await settle()
	app.request_new_run(6)
	await settle()
	var node: Dictionary = app.run_state.inspect_node("d1b")
	check(node.enemy_id == "stone_sentinel" and node.board_id == "board_ossuary", tag + ": ordinary alternate opening supplies remaining normal/board combination.")
	app.map_screen.inspect_node("d1b")
	app.map_screen.inspection_action.pressed.emit()
	app.confirmation_confirm.pressed.emit()
	await settle()
	check(app.combat_scene != null, tag + ": explicit ordinary entry reaches Stone Sentinel on Ossuary.")
	if app.combat_scene != null:
		await capture("entry-" + tag)
		var controller = app.combat_scene.controller
		var game = app.combat_scene.battle_model
		var opening: Dictionary = controller.snapshot()
		controller.set_presenter(Immediate.new())
		var player := Player.new()
		var commands: Array = []
		controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
		for turn in 80:
			if game.state != "playing": break
			check(player.play_turn(controller), tag + ": legal controller turn.")
		await settle()
		check(app.run_state.snapshot().pending_result.get("outcome") == game.state, tag + ": actual alternate-board result commits.")
		traces.append({"variant": tag, "node": node, "entry": opening, "commands": commands, "outcome": game.state, "hp": game.player_hp})
		if game.state == "victory": await rewards(app, tag, false)
	app.queue_free()
	await settle()
