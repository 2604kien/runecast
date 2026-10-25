extends "res://tests/rc031_ui_runner.gd"
## Additional real Combat captures after durable item acquisition. Uses the
## normal shell/controller and ordinary drawing/Pass; no hand or board injection.

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await live_battle(dimensions)
	# Allow renderer/audio teardown after freeing the final live Combat scene.
	await create_timer(0.25).timeout
	FileAccess.open(DESTINATION.path_join("live-results-capture.json" if capturing else "live-results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Actual next-battle upgraded hand, supported hand/installed/pile inspection, live Resume and exact entry replay after durable genuine-fixture shop acquisition."}, "  ") + "\n")
	print("RC-031 live UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func live_battle(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var path := DESTINATION.path_join("live-" + tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var run = Fixture.new_run(42, "shop")
	check(Fixture.win_first(run).get("ok", false), tag + " live UI starts after genuine Wisp victory.")
	var app := create_shell(path, Fixture.context_for(run))
	await settle()
	app.run_state = run
	app.progression = run.profile_state()
	check(app._persist_candidate(run).get("ok", false), tag + " pre-shop boundary persists.")
	app.continue_run()
	app.request_node_entry(Fixture.next_node(run))
	app.confirm_node_entry()
	await settle()
	if app.shop_screen == null:
		check(false, tag + " shop opens for live integration.")
		app.queue_free()
		await settle()
		return
	var identity: Dictionary = run.shop_snapshot().identity
	var target: Dictionary = run.shop_snapshot().upgrade.targets.filter(func(card): return card.id == "spark")[0]
	app._upgrade_shop_rune(identity, target.uid)
	app._purchase_shop_relic(identity, str(run.shop_snapshot().relic_slots[0].slot_id))
	app._leave_shop(identity)
	await settle()
	app.request_node_entry(Fixture.next_node(run))
	app.confirm_node_entry()
	await settle()
	check(app.combat_scene != null, tag + " actual next battle opens with retained ownership.")
	if app.combat_scene == null:
		app.queue_free()
		await settle()
		return
	var scene: Control = app.combat_scene
	var opening: Dictionary = scene.controller.snapshot()
	var attempts := 0
	while not scene.controller.snapshot().hand.any(func(card): return card.uid == target.uid) and attempts < 4 and scene.controller.can_edit():
		check(scene.controller.command("pass"), tag + " ordinary Pass advances drawing without injected cards.")
		await wait_controller(scene)
		attempts += 1
	var hand: Array = scene.controller.snapshot().hand
	check(hand.any(func(card): return card.uid == target.uid and card.upgrade_rank == 1), tag + " actual hand draws the same upgraded UID.")
	await capture("live-upgraded-hand-" + tag)
	scene._inspect_hand(target.uid)
	await capture("live-upgraded-hand-inspection-" + tag)
	check(scene.inspector_text.text.contains("8 damage") and scene.inspector_title.text == "Spark +", tag + " live hand inspection shows effective values and marker.")
	scene._close_inspector(false)
	var empty: int = scene.controller.snapshot().board.find({})
	check(scene.controller.command("place_rune", {"index": empty, "uid": target.uid}), tag + " real controller installs the upgraded physical copy.")
	await settle()
	scene._open_inspector(InspectionData.describe_cell(scene.controller.snapshot(), empty))
	await capture("live-upgraded-installed-inspection-" + tag)
	check(scene.inspector_text.text.contains("8 damage") and scene.inspector_title.text == "Spark +", tag + " supported installed inspection retains the effective upgrade.")
	scene._close_inspector(false)
	check(scene.controller.command("pass"), tag + " real cleanup sends upgraded installed rune to discard.")
	await wait_controller(scene)
	scene._inspect_pile("discard_pile")
	await capture("live-upgraded-pile-inspection-" + tag)
	check(scene.inspector_text.text.contains("Spark +") and scene.inspector_text.text.contains("8 damage"), tag + " actual discard inspection distinguishes ranked copies and values.")
	scene._close_inspector(false)
	var before: Dictionary = scene.controller.snapshot()
	app._battle_menu_requested(app._generation, false)
	app._close_route_menu()
	check(scene.controller.snapshot() == before, tag + " live Menu Resume changes no ranked cards, hand or relic opening state.")
	app.request_home()
	app.confirm_home()
	await settle()
	app.continue_run()
	await settle()
	check(app.combat_scene != null and app.combat_scene.controller.snapshot() == opening, tag + " Continue exactly replays initial ranked entry without reapplying acquisition health.")
	app.queue_free()
	await settle()

func wait_controller(scene: Control) -> void:
	for frame in 600:
		if not scene.controller.is_busy(): break
		await process_frame
	await settle()
