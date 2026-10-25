extends SceneTree
## Actual-window legal-action evidence, independent of the unit-test fixtures.
const Fixture = preload("res://tests/helpers/rc033_fixture.gd")
const DESTINATION := "res://output/qa/rc-033/ui"
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []
var capturing := false

func _initialize() -> void:
	capturing = "--capture-rc033" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 6: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(scene, name: String) -> void:
	await settle()
	var bounds := root.get_visible_rect()
	if scene.inspector.visible:
		check(bounds.encloses(scene.inspector_panel.get_global_rect()), name + ": inspector fits actual window.")
		check(bounds.encloses(scene.inspector_close.get_global_rect()), name + ": fixed Close remains reachable.")
	if capturing:
		check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + ": rendered capture saved.")

func tap(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = position
		event.pressed = pressed
		root.push_input(event, true)

func _run() -> void:
	print("RC-033 UI beginning")
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	var loaded := Fixture.load_fixture()
	check(loaded.ok, "Excluded fixture validates through the production loader: " + str(loaded.get("errors", [])))
	if loaded.ok:
		for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
			print("RC-033 UI window ", dimensions)
			root.size = dimensions
			await settle()
			await journey(loaded.setup, dimensions)
	await create_timer(0.3).timeout
	FileAccess.open(DESTINATION.path_join("results-capture.json" if capturing else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	FileAccess.open(DESTINATION.path_join("legal-walkthrough.json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  ") + "\n")
	print("RC-033 actual-window UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func journey(setup: Dictionary, dimensions: Vector2i) -> void:
	print("RC-033 UI creating scene")
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = setup
	scene.battle_model = Fixture.new_combat()
	scene.settings_path = DESTINATION.path_join(tag + ".cfg")
	root.add_child(scene)
	scene.sound_enabled = false
	scene.animation_presenter.automatic_timing = false
	await settle()
	print("RC-033 UI scene settled")
	var opening: Dictionary = scene.controller.snapshot()
	var commands: Array = []
	scene.controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
	check(root.size == dimensions, tag + ": actual desktop window uses requested dimensions.")
	check(opening.enemy_hp == 80 and opening.player_hp == 400 and opening.intent == 8 and opening.enemy_action.phase == 1, tag + ": explicit fixture resources and first phase intent.")
	await capture(scene, "opening-" + tag)
	var original: Dictionary = scene.controller.snapshot()
	tap(scene.arena.intent_button)
	await settle()
	check(scene.inspector.visible and scene.inspector_title.text == "Enemy intent", tag + ": viewport touch opens enemy intent.")
	check(scene.inspector_text.text.contains("40") and scene.inspector_text.text.contains("8") and scene.inspector_text.text.contains("20"), tag + ": details explain threshold and both patterns.")
	await capture(scene, "intent-phase-one-" + tag)
	scene.inspector_scroll.scroll_vertical = 10000
	await capture(scene, "intent-phase-one-scrolled-" + tag)
	check(scene.inspector_scroll.scroll_vertical > 0, tag + ": longer phase explanation is scrollable above fixed Close.")
	for repeat in 5: scene._refresh()
	scene._cast()
	check(scene.controller.snapshot() == original and commands.is_empty(), tag + ": inspection refresh and background Cast leave model/commands unchanged.")
	tap(scene.inspector_close)
	await settle()
	check(not scene.inspector.visible and scene.controller.snapshot() == original, tag + ": touch Close consumes no turn.")
	for count in 2: check(Fixture.command(scene.controller, "pass"), tag + ": ordinary opening Pass " + str(count + 1))
	var paths: Array = []
	for count in 6:
		var plan := Fixture.prepare_spark(scene.controller)
		check(plan.get("ok", false), tag + ": legal one-Spark preparation " + str(count + 1))
		if not plan.get("ok", false): break
		paths.append({"turn": scene.game.turn, "path": plan.path, "rune_cell": plan.rune_cell})
		check(Fixture.command(scene.controller, "cast"), tag + ": ordinary one-Spark Cast " + str(count + 1))
	check(scene.game.enemy_hp == 44 and scene.game.intent == 16 and scene.game.turn == 9, tag + ": reproducible pre-threshold turn announces 16.")
	await capture(scene, "before-threshold-" + tag)
	var prepared := Fixture.prepare_spark(scene.controller)
	check(prepared.get("ok", false), tag + ": threshold Cast uses one real Spark.")
	if not prepared.get("ok", false):
		scene.queue_free()
		await settle()
		return
	paths.append({"turn": scene.game.turn, "path": prepared.path, "rune_cell": prepared.rune_cell})
	var model_before: Dictionary = scene.controller.snapshot()
	scene._open_menu(false)
	scene.menu.hide()
	await settle()
	check(scene.controller.snapshot() == model_before, tag + ": live Menu Resume retains phase, announced attack and legal preparation.")
	check(scene.controller.command("cast"), tag + ": threshold Cast accepted.")
	for sample in 1000:
		if scene.animation_presenter.phase == "retaliation": break
		scene.animation_presenter.advance(0.01)
	check(scene.animation_presenter.phase == "retaliation" and scene.game.enemy_hp == 38 and scene.game.intent == 16 and scene.game.enemy_action.phase == 1, tag + ": old 16 intent remains visible after damage while retaliation is staged.")
	check(scene.controller.snapshot().enemy_action.phase == 2 and scene.controller.snapshot().intent == 12, tag + ": authoritative future phase is committed but hidden by presentation.")
	await capture(scene, "old-retaliation-" + tag)
	for sample in 3000:
		if scene.animation_presenter.phase == "enemy_phase_changed": break
		scene.animation_presenter.advance(0.01)
	check(scene.animation_presenter.phase == "enemy_phase_changed" and scene.game.intent == 16, tag + ": phase feedback begins after cleanup with old intent until its own commit.")
	await capture(scene, "phase-change-" + tag)
	scene.animation_presenter.finish()
	check(scene.game.enemy_action.phase == 2 and scene.game.enemy_action.sequence_index == 0 and scene.game.intent == 12 and scene.game.player_hp == model_before.player_hp - 16, tag + ": next playable turn begins at 12 after actual old 16 retaliation.")
	await capture(scene, "after-threshold-" + tag)
	tap(scene.arena.intent_button)
	await capture(scene, "intent-phase-two-" + tag)
	check(scene.inspector_text.text.contains("Phase 2"), tag + ": phase-two details are truthful.")
	scene.inspector_scroll.scroll_vertical = 10000
	await capture(scene, "intent-phase-two-scrolled-" + tag)
	scene._go_back()
	await settle()
	check(not scene.inspector.visible and not scene.menu.visible, tag + ": Back dismisses only the inspector.")
	for expected in [16, 20, 12]:
		check(Fixture.command(scene.controller, "pass") and scene.game.intent == expected and scene.game.enemy_action.phase == 2, tag + ": phase two cycles to " + str(expected) + " without retrigger.")
	for count in 7:
		check(Fixture.prepare_spark(scene.controller).get("ok", false) and Fixture.command(scene.controller, "cast"), tag + ": legal phase-two damage " + str(count + 1))
	check(scene.game.state == "victory" and scene.game.enemy_hp == 0, tag + ": legal overkill ends the fixture.")
	var last: Dictionary = scene.battle_model.last_result()
	check(not last.events.any(func(event): return event.type in ["retaliation", "enemy_phase_changed", "turn_started"]), tag + ": lethal Cast suppresses retaliation, transition and next-turn work.")
	check(last.events.filter(func(event): return event.type == "damage")[0].amount == 6 and last.events.filter(func(event): return event.type == "damage")[0].applied == 2, tag + ": requested six damage remains distinct from final two HP loss.")
	await capture(scene, "victory-" + tag)
	scene._exact_replay()
	scene.animation_presenter.automatic_timing = false
	check(scene.controller.snapshot() == opening, tag + ": exact replay reconstructs original entry and first intent.")
	traces.append({"window": tag, "paths_to_threshold": paths, "commands": commands})
	scene.queue_free()
	await settle()
