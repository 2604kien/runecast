extends SceneTree
## RC-026 actual shell integration; --manual opens the labeled fixture to play.
const Fixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const FailureShell = preload("res://tests/helpers/encounter_failure_shell.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/rc-026/integration"
var checks := 0
var failures := 0
var assertions: Array = []
var _capture := false
var _trace: Array = []

func _initialize() -> void:
	_capture = "--capture-integration" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	if "--manual" in OS.get_cmdline_user_args():
		root.size = Vector2i(450, 1000)
		root.title = "Rune Cast — RC-026 reward-free integration fixture"
		var app := FailureShell.new()
		app.settings_path = DESTINATION.path_join("manual-settings.cfg")
		app.save_path = DESTINATION.path_join("manual-save-" + str(Time.get_ticks_usec()) + ".json")
		root.add_child(app)
		app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		app.run_state = Fixture.new_run(42)
		app.persistence_context = app.run_state.restore_context_for_tests()
		app.open_map()
		return
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		await _exercise(dimensions)
	var report := {"checks": checks, "failures": failures, "assertions": assertions, "trace": _trace,
		"policy": "Explicit reward-free test route. Existing enemy stats, fixed seed 42, legal player commands. No endpoint, seed, health or outcome substitution. Not production tower acceptance."}
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-026 shell integration checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _exercise(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := FailureShell.new()
	app.settings_path = DESTINATION.path_join("settings-" + tag + ".cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var settings: Dictionary = Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion = true
	Settings.save_values(settings, app.settings_path)
	viewport.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.run_state = Fixture.new_run(42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	var run = app.run_state
	app.open_map()
	await settle()
	var first_node: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	var initial: Dictionary = run.snapshot()
	check(initial.route.visit_count == 0 and initial.route.path_length == 9, tag + " Fixture starts with zero visits and explicitly keeps nine depths.")
	# Failed construction and a tree-incompatible scene both preserve every owner.
	for fault in ["fail_next_scene", "invalid_next_scene", "reject_attached_scene"]:
		app.set(fault, true)
		app.request_node_entry(first_node)
		app.confirm_node_entry()
		await settle()
		check(run.snapshot() == initial and app.combat_scene == null and app.map_screen != null, tag + " " + fault + " leaves route, HP, UIDs, RNG and checkpoint unchanged.")
	app.request_node_entry(first_node)
	await settle()
	check(app.confirmation.visible and run.snapshot() == initial, tag + " Entry confirmation does not commit a visit.")
	await save(viewport, "entry-confirmation-" + tag)
	app.confirm_node_entry()
	app.confirm_node_entry()
	await settle()
	check(app.combat_scene != null and app.map_screen == null and run.snapshot().status == "battle" and run.route_snapshot().visit_count == 1, tag + " Repeated confirmation creates exactly one attached battle and one visit.")
	if app.combat_scene == null:
		app.queue_free()
		viewport.queue_free()
		await settle()
		return
	var scene: Control = app.combat_scene
	var controller = scene.controller
	var opening: Dictionary = controller.snapshot()
	var entry_route: Dictionary = run.route_snapshot()
	check(opening.enemy_name == "Calibration Wisp" and opening.enemy_max_hp == 45 and opening.player_hp == 30 and opening.player_max_hp == 30 and opening.energy == 4 and opening.hand.size() == 2, tag + " Selected Wisp uses real enemy stats and 4/2 configuration, carrying the run's 30/30 instead of authored 24/40.")
	await save(viewport, "combat-entry-" + tag)
	controller.set_presenter(Immediate.new())
	# Prepare through real actions, retain selection and scroll across live Map.
	var player := Player.new()
	var plan: Dictionary = player.prepare(controller)
	check(not plan.is_empty(), tag + " Legal construction uses the actual sampled endpoints, hand and finite kit.")
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var prepared: Dictionary = controller.snapshot()
	var offset: int = scene.page_scroll.scroll_vertical
	var selection: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell]
	var audio = scene.audio
	var ambience_player = audio._ambience.player
	var ambience_starts: int = audio.loop_starts.ambience
	await save(viewport, "combat-prepared-" + tag)
	app.open_map()
	await settle()
	check(app.map_screen != null and scene.audio == audio and audio._ambience.player == ambience_player and audio.loop_starts.ambience == ambience_starts, tag + " Map retains the same audio owner and players.")
	await save(viewport, "live-map-" + tag)
	app.map_screen.inspect_node(first_node)
	check(app.map_screen.inspection_action.text.contains("Resume"), tag + " Current route node offers live Resume.")
	app.map_screen.inspection_action.pressed.emit()
	await settle()
	check(app.combat_scene == scene and scene.controller == controller and controller.snapshot() == prepared and scene.page_scroll.scroll_vertical == offset and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, tag + " Live Resume keeps scene, controller, model, preparation, selection and scroll.")
	await save(viewport, "live-resumed-" + tag)
	# Advance once, then demonstrate exact entry replay and subsequent sequence.
	check(controller.command("cast"), tag + " Prepared opening Cast resolves normally.")
	var after_first: Dictionary = controller.snapshot()
	app.request_home()
	await settle()
	await save(viewport, "quit-confirmation-" + tag)
	app.confirm_home()
	await settle()
	check(run.snapshot().status == "replay_pending" and run.route_snapshot() == entry_route and app.combat_scene == null, tag + " Quit retains the selected node and same visit.")
	var replay_before: Dictionary = run.snapshot()
	app.fail_next_scene = true
	app.continue_run()
	await settle()
	check(run.snapshot() == replay_before and app.combat_scene == null, tag + " Failed replay attachment leaves the entry checkpoint recoverable.")
	app.continue_run()
	app.continue_run()
	await settle()
	scene = app.combat_scene
	controller = scene.controller
	check(controller.snapshot() == opening and run.route_snapshot() == entry_route, tag + " Continue reproduces the exact stored opening with no extra visit.")
	await save(viewport, "entry-replay-" + tag)
	# The current-node action also handles a replay-pending route.
	app.request_home()
	app.confirm_home()
	await settle()
	app.open_map()
	app.map_screen.inspect_node(first_node)
	check(app.map_screen.inspection_action.text.contains("Replay"), tag + " Current route node identifies entry replay separately from live Resume.")
	app.map_screen.inspection_action.pressed.emit()
	await settle()
	scene = app.combat_scene
	controller = scene.controller
	check(controller.snapshot() == opening and run.route_snapshot() == entry_route, tag + " Current-node replay keeps the exact opening and visit.")
	controller.set_presenter(Immediate.new())
	player.play_turn(controller)
	check(controller.snapshot() == after_first, tag + " Repeated legal commands after replay reproduce the next hand, endpoints, kit and health.")
	var route_rng: int = run.route_snapshot().route_rng_state
	# Win via actual commands; hold the lethal presentation before committing.
	var delayed := Delayed.new()
	for turn in range(20):
		if controller.snapshot().state != "playing": break
		var action: Dictionary = player.prepare(controller)
		var before: Dictionary = controller.snapshot()
		var lethal: bool = not action.is_empty() and int(before.forecast.damage) >= int(before.enemy_hp)
		if lethal: controller.set_presenter(delayed)
		check(controller.command("pass" if action.is_empty() else "cast"), tag + " Actual action resolves turn %d." % int(before.turn))
		_trace.append({"size": tag, "visit": 1, "turn": before.turn, "outcome": controller.snapshot().state, "hp": controller.snapshot().player_hp, "enemy_hp": controller.snapshot().enemy_hp})
		if lethal:
			check(run.snapshot().status == "battle" and not app.confirmation.visible and controller.is_busy(), tag + " Terminal cleanup waits for presentation before result commit.")
			delayed.complete()
	await settle()
	var won: Dictionary = run.snapshot()
	check(won.status == "result_pending" and won.pending_result.outcome == "victory" and won.player_hp == 21, tag + " Actual Wisp victory commits 21/30 once.")
	check(won.owned_cards == initial.owned_cards and won.gold == initial.gold and won.relics == initial.relics and run.route_snapshot().route_rng_state == route_rng, tag + " Permanent instances, Gold, relics and independent route stream remain conserved.")
	check(app.confirmation.visible and app.confirmation_text.text.contains("No Gold"), tag + " Result explicitly promises no missing rewards.")
	await save(viewport, "terminal-result-" + tag)
	var result_scroll: ScrollContainer = app._confirmation_panel.get_meta("rc_body_scroll")
	result_scroll.scroll_vertical = 100000
	await settle()
	# The current popup policy fits short content before enabling scrolling.
	# After requesting the end, the complete policy must either fit or be reachable.
	check(result_scroll.scroll_vertical + result_scroll.size.y + 1 >= result_scroll.get_child(0).size.y, tag + " Full result policy fits or is reachable at the end of the bounded body.")
	for button in [app.confirmation_confirm, app.confirmation_cancel]:
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Result action remains reachable: " + button.text)
	await save(viewport, "terminal-result-policy-" + tag)
	controller.changed.emit()
	delayed.complete()
	check(run.snapshot() == won, tag + " Duplicate terminal and stale presentation callbacks cannot recommit.")
	# Home/Continue retains pending acknowledgement, never replays terminal Combat.
	app.cancel_confirmation()
	await settle()
	check(app.combat_scene == null and run.snapshot().status == "result_pending", tag + " Result Return Home keeps acknowledgement pending.")
	app.continue_run()
	await settle()
	check(app.confirmation.visible and app.combat_scene == null and run.snapshot() == won, tag + " Pending-result Continue shows the result without recreating Combat.")
	app.acknowledge_encounter_result()
	app.acknowledge_encounter_result()
	await settle()
	check(app.map_screen != null and run.route_snapshot().completed_count == 1 and run.snapshot().status == "route_ready", tag + " One acknowledgement returns Map with exactly one completion.")
	await save(viewport, "returned-map-" + tag)
	var second_node: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.request_node_entry(second_node)
	app.confirm_node_entry()
	await settle()
	scene = app.combat_scene
	controller = scene.controller
	var second: Dictionary = controller.snapshot()
	check(second.player_hp == 21 and second.player_max_hp == 30 and second.energy == 3 and second.hand.size() == 3 and second.turn == 1, tag + " Second encounter carries 21/30 and resets to its 3/3 configuration.")
	check(second.encounter_content_id == opening.encounter_content_id and run.route_snapshot().visit_count == 2, tag + " Repeated encounter definition has a distinct second visit.")
	check(second.board.filter(func(piece): return piece.is_empty()).size() == 14 and second.discard_pile.is_empty() and second.stock == second.kit.totals and second.hand.all(func(card): return card.id != "free_spark"), tag + " Second battle has only endpoints, clean zones, fresh kit and no carried temporary.")
	await save(viewport, "second-entry-" + tag)
	controller.set_presenter(Immediate.new())
	for turn in range(20):
		if controller.snapshot().state != "playing": break
		player.play_turn(controller)
		_trace.append({"size": tag, "visit": 2, "turn": controller.snapshot().turn, "outcome": controller.snapshot().state, "hp": controller.snapshot().player_hp, "enemy_hp": controller.snapshot().enemy_hp})
	await settle()
	check(run.snapshot().status == "result_pending" and run.snapshot().pending_result.outcome == "victory" and run.snapshot().player_hp == 14 and run.route_snapshot().visit_count == 2, tag + " Second real Combat wins at 14/30 through the same shell commit boundary.")
	await save(viewport, "second-result-" + tag)
	var second_outcome: String = run.snapshot().pending_result.outcome
	app.acknowledge_encounter_result()
	await settle()
	check(run.snapshot().status == ("route_ready" if second_outcome == "victory" else "defeated") and not run.snapshot().tower_completed, tag + " Second outcome is retained and never claims guardian completion.")
	await save(viewport, "second-map-" + tag)
	app.queue_free()
	await settle()
	viewport.queue_free()
	await settle()

func settle() -> void:
	for frame in 8: await process_frame
	if _capture and DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(viewport: SubViewport, file_name: String) -> void:
	if not _capture: return
	check(DisplayServer.get_name() != "headless", "Capture requires actual rendering.")
	if DisplayServer.get_name() == "headless": return
	check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(file_name + ".png")) == OK, file_name + " PNG saved.")
