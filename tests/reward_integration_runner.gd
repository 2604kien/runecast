extends SceneTree
## Excluded RC-027 integration/capture driver. Genuine fixed-seed Combat wins.
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Shell = preload("res://scripts/ui/application_shell.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/rc-027/integration"
var checks := 0
var failures := 0
var assertions: Array = []
var trace: Array = []
var _capture := false

func _initialize() -> void:
	_capture = "--capture-rewards" in OS.get_cmdline_user_args()
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
		root.title = "Rune Cast — RC-027 reward-enabled test fixture"
		var app := Shell.new()
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
	var report := {"checks": checks, "failures": failures, "assertions": assertions, "trace": trace,
		"policy": "Excluded reward-enabled test policy: optional one run copy from three distinct implemented definitions, 7 run Gold per Wisp visit, no permanent acquisition. Existing content, fixed seed 42, ordinary commands. Not production rules or complete-tower acceptance."}
	FileAccess.open(DESTINATION.path_join("results-capture.json" if _capture else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	if _capture: FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-027 reward integration checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _exercise(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := Shell.new()
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
	var initial: Dictionary = run.snapshot()
	check(initial.route.visit_count == 0 and initial.route.path_length == 9, tag + " Reward fixture starts honestly with zero visits and keeps the nine-depth route.")
	await save(viewport, "fixture-map-" + tag)
	var first: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.request_node_entry(first)
	app.confirm_node_entry()
	await settle()
	check(app.combat_scene != null and run.snapshot().status == "battle", tag + " First supported visit enters a real Combat scene.")
	if app.combat_scene == null:
		await _dispose(app, viewport)
		return
	var scene: Control = app.combat_scene
	var controller = scene.controller
	controller.set_presenter(Immediate.new())
	var opening: Dictionary = controller.snapshot()
	check(opening.enemy_name == "Calibration Wisp" and opening.enemy_max_hp == 45 and opening.energy == 4 and opening.hand.size() == 2, tag + " Existing Wisp content and 4/2 loadout remain unchanged.")
	var player := Player.new()
	var prepared: Dictionary = player.prepare(controller)
	check(not prepared.is_empty(), tag + " Legal preparation uses actual sampled hand/endpoints/finite kit.")
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	await _collection_check(app, viewport, dimensions, tag, "battle-installed")
	check(controller.command("cast"), tag + " Prepared cast resolves through the real controller.")
	await settle()
	await _collection_check(app, viewport, dimensions, tag, "battle-next-turn")
	for turn in range(40):
		if controller.snapshot().state != "playing": break
		check(player.play_turn(controller), tag + " Ordinary player action accepted on first visit turn %d." % controller.snapshot().turn)
		trace.append({"size": tag, "visit": 1, "turn": controller.snapshot().turn, "state": controller.snapshot().state,
			"player_hp": controller.snapshot().player_hp, "enemy_hp": controller.snapshot().enemy_hp})
	await settle()
	var terminal: Dictionary = run.snapshot()
	check(terminal.status == "result_pending" and terminal.pending_result.outcome == "victory", tag + " Real first victory commits before any reward offering.")
	if terminal.status != "result_pending" or terminal.pending_result.outcome != "victory":
		await _dispose(app, viewport)
		return
	var reward: Dictionary = run.pending_reward()
	check(reward.status == "pending" and reward.offered_ids.size() == 3 and terminal.owned_cards == initial.owned_cards and terminal.gold == 0, tag + " One stable offer is generated without granting ownership or configured Gold.")
	check(terminal.next_uid > initial.next_uid, tag + " Real generated temporary cards consumed allocator UIDs before reward allocation.")
	check(run.route_snapshot().nodes.filter(func(node): return node.state == "available").is_empty(), tag + " Required reward choice locks successors while result is pending.")
	await save(viewport, "victory-result-" + tag)
	app.cancel_confirmation()
	await settle()
	check(app.combat_scene == null and run.snapshot() == terminal, tag + " Result Return Home preserves committed result and reward; no terminal Combat replay.")
	app.audio.trace_enabled = true
	app.continue_run()
	await settle()
	check(app.confirmation.visible and run.snapshot() == terminal and run.pending_reward() == reward, tag + " Home Continue reopens result with the exact same offered IDs and transaction.")
	app.acknowledge_encounter_result()
	await settle()
	check(run.snapshot().status == "pending_choices" and app.map_screen != null and run.pending_reward() == reward, tag + " Result acknowledgement grants nothing and exposes pending reward Map state.")
	var pending_snapshot: Dictionary = run.snapshot()
	var pending_map: Control = app.map_screen
	var shared_menu: Control = app.route_menu
	await _touch(viewport, pending_map.menu_button.get_global_rect().get_center())
	check(shared_menu.visible and pending_map._blocked and run.snapshot() == pending_snapshot, tag + " Shared Menu opens from pending-reward Map without resolving, rerolling or granting resources.")
	await _touch(viewport, app.route_menu_collection.get_global_rect().get_center())
	check(app.collection_screen.visible and shared_menu.visible and run.pending_reward() == reward, tag + " Pending reward remains intact while Collection overlays the retained shared Menu.")
	await _touch(viewport, app.collection_screen.close_button.get_global_rect().get_center())
	check(not app.collection_screen.visible and app.route_menu == shared_menu and shared_menu.visible and app.map_screen == pending_map and run.snapshot() == pending_snapshot, tag + " Collection Close restores the same pending-choice Map Menu and authoritative state.")
	await _touch(viewport, app.route_menu_resume.get_global_rect().get_center())
	check(not shared_menu.visible and app.map_screen == pending_map and not pending_map._blocked and run.pending_reward() == reward and run.snapshot() == pending_snapshot, tag + " Shared Menu Resume returns to pending rewards without treating navigation as Skip.")
	app.map_screen.inspect_node(first)
	check(app.map_screen.inspection_action.text.to_lower().contains("reward"), tag + " Current completed node supplies an explicit pending rewards action.")
	app.map_screen.inspection_action.pressed.emit()
	await settle()
	check(app.reward_screen != null and app.reward_screen.visible, tag + " Map action reopens pending rewards.")
	if app.reward_screen == null:
		await _dispose(app, viewport)
		return
	var retained_skip: Callable = app.reward_screen._skip_callback
	var retained_gold: Callable = app.reward_screen._gold_callback
	await _reward_layout(app, viewport, dimensions, tag, "rewards-pending")
	var before_close: Dictionary = run.snapshot()
	await _mouse(viewport, app.reward_screen.close_button.get_global_rect().get_center())
	check(not app.reward_screen.visible and run.snapshot() == before_close, tag + " Native reward Close preserves the choice and all RNG/state.")
	app.close_map()
	await settle()
	app.continue_run()
	await settle()
	check(app.map_screen != null and run.pending_reward() == reward, tag + " Pending-choice Home Continue restores access without rerolling or skipping.")
	app.open_rewards()
	await settle()
	check(_reward_cue_count(app.audio) == 0, tag + " Inspection, reward reopening and Continue do not play reward audio.")
	var gold_before: Dictionary = run.snapshot()
	var retained_map: Control = app.map_screen
	var reentrant_rewards := [0]
	var audio_callback := func(record: Dictionary):
		if record.get("cue") != "reward": return
		reentrant_rewards[0] += 1
		# A synchronous observer of successful playback must not navigate,
		# replace owners or submit another transaction during shell refresh.
		app.close_rewards()
		app.close_map()
		app.request_new_run(99)
		app.confirm_new_run()
		app.continue_run()
		app.open_map()
		app.open_collection()
		app._choose_reward(reward.identity, str(reward.offered_ids[0]))
		app._skip_reward(reward.identity)
		app._claim_reward_gold(reward.identity)
	app.audio.cue_started.connect(audio_callback)
	await _touch(viewport, app.reward_screen.gold_button.get_global_rect().get_center())
	app.audio.cue_started.disconnect(audio_callback)
	check(reentrant_rewards[0] == 1 and app.run_state == run and app.map_screen == retained_map and app.reward_screen.visible and not app.collection_screen.visible and not app.confirmation.visible, tag + " Reward audio reentrancy cannot close, replace or navigate away from transaction owners.")
	check(run.snapshot().gold == 7 and run.snapshot().owned_cards == gold_before.owned_cards and run.snapshot().status == "pending_choices", tag + " Native Gold claim grants only explicit fixture Gold and keeps rune choice pending.")
	check(_reward_cue_count(app.audio) == 1, tag + " Successful configured Gold claim plays exactly one reward cue.")
	check(not run.claim_reward_gold(reward.identity).ok and run.snapshot().gold == 7, tag + " Repeated Gold callback cannot pay twice.")
	var offered_id: String = str(reward.offered_ids[0])
	var allocated_uid: int = run.snapshot().next_uid
	var battle_rng: Dictionary = run.snapshot().rng_states.duplicate(true)
	var chosen: Button = app.reward_screen.choose_buttons[offered_id]
	app.reward_screen.scroll.ensure_control_visible(chosen)
	await settle()
	await save(viewport, "reward-choice-" + tag)
	await _mouse(viewport, chosen.get_global_rect().get_center())
	await settle()
	var claimed: Dictionary = run.snapshot()
	check(claimed.owned_cards.size() == initial.owned_cards.size() + 1 and claimed.owned_cards.has({"id": offered_id, "uid": allocated_uid, "upgrade_rank": 0}), tag + " Native card choice grants exactly one unupgraded authoritative instance using the transferred allocator.")
	check(claimed.rng_states == battle_rng and claimed.next_uid == allocated_uid + 1 and claimed.status == "route_ready", tag + " Reward changes neither battle RNG nor old identities; completed transactions unlock successors.")
	check(not run.choose_reward(reward.identity, offered_id).ok and run.snapshot() == claimed, tag + " Duplicate card callback cannot grant twice or consume another UID.")
	check(_reward_cue_count(app.audio) == 2, tag + " Successful rune claim plays one additional reward cue; repeated claims play none.")
	var reward_audio_count: int = _reward_cue_count(app.audio)
	check(initial.owned_cards.all(func(card): return claimed.owned_cards.has(card)), tag + " Every initial instance is retained unchanged.")
	await save(viewport, "reward-claimed-" + tag)
	if app.reward_screen != null and app.reward_screen.visible: app.close_rewards()
	await _collection_check(app, viewport, dimensions, tag, "collection-awarded")
	check(_reward_cue_count(app.audio) == reward_audio_count, tag + " Collection inspection and dismissal do not replay reward audio.")
	var second: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.request_node_entry(second)
	app.confirm_node_entry()
	await settle()
	check(app.combat_scene != null and run.snapshot().status == "battle", tag + " Claimed ownership enters the second actual encounter.")
	if app.combat_scene == null:
		await _dispose(app, viewport)
		return
	scene = app.combat_scene
	controller = scene.controller
	var next: Dictionary = controller.snapshot()
	var zones: Array = next.hand + next.draw_pile + next.discard_pile
	check(zones.filter(func(card): return card.uid == allocated_uid and card.id == offered_id).size() == 1 and zones.size() == claimed.owned_cards.size(), tag + " Awarded instance participates exactly once in the successor's continued shuffle/draw.")
	check(next.encounter_content_id == opening.encounter_content_id and run.route_snapshot().visit_count == 2 and next.hand.size() == 3, tag + " Same encounter definition has a distinct second visit and ordinary configured three-card draw.")
	await save(viewport, "next-encounter-" + tag)
	controller.set_presenter(Immediate.new())
	for turn in range(40):
		if controller.snapshot().state != "playing": break
		check(player.play_turn(controller), tag + " Ordinary second-visit action accepted.")
	await settle()
	check(run.snapshot().pending_result.get("outcome") == "victory", tag + " Rewarded collection wins a second real encounter without forced state.")
	if run.snapshot().pending_result.get("outcome") == "victory":
		var second_reward: Dictionary = run.pending_reward()
		check(second_reward.identity != reward.identity and second_reward.identity.visit_id != reward.identity.visit_id, tag + " Repeated encounter definitions receive visit-scoped independent transaction identities.")
		app.acknowledge_encounter_result()
		app.open_rewards()
		await settle()
		var before_stale: Dictionary = run.snapshot()
		retained_skip.call()
		retained_gold.call()
		check(run.snapshot() == before_stale and run.pending_reward() == second_reward, tag + " Retained first-visit Skip and Gold callbacks cannot resolve or pay the second displayed choice.")
		var before_skip: int = run.snapshot().owned_cards.size()
		await _touch(viewport, app.reward_screen.skip_button.get_global_rect().get_center())
		check(run.snapshot().owned_cards.size() == before_skip and run.snapshot().status == "pending_choices", tag + " Native Skip grants no card and leaves separately unclaimed Gold pending.")
		await _touch(viewport, app.reward_screen.gold_button.get_global_rect().get_center())
		check(run.snapshot().gold == 14 and run.snapshot().status == "route_ready" and not run.snapshot().tower_completed, tag + " Second visit resolves once and preserves the unavailable production continuation.")
		await save(viewport, "second-reward-resolved-" + tag)
	await _dispose(app, viewport)

func _collection_check(app: Control, viewport: SubViewport, dimensions: Vector2i, tag: String, stage: String) -> void:
	var run_before: Dictionary = app.run_state.snapshot()
	var scene: Control = app.combat_scene
	var battle_before: Dictionary = scene.controller.snapshot() if scene != null else {}
	var selection: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell] if scene != null else []
	var offset: int = scene.page_scroll.scroll_vertical if scene != null else 0
	var via_menu: bool = scene != null and stage == "battle-installed"
	var shared_menu: Control = app.route_menu
	if via_menu:
		await _touch(viewport, scene.combat_navigation.buttons.menu.get_global_rect().get_center())
		check(app.route_menu == shared_menu and shared_menu.visible and not scene.menu.visible and scene._shell_modal, tag + " Prepared live Combat opens the single shared Menu without opening its standalone Window.")
		await _touch(viewport, app.route_menu_collection.get_global_rect().get_center())
	else:
		app.open_collection()
	await settle()
	check(app.collection_screen != null and app.collection_screen.visible, tag + " " + stage + " collection opens.")
	if app.collection_screen == null: return
	var viewer: Control = app.collection_screen
	var described: Dictionary = viewer.presentation
	check(described.owned_count == run_before.owned_cards.size(), tag + " " + stage + " collection count comes from authoritative ownership.")
	var displayed: Array = []
	for group in described.groups:
		for instance in group.instances: displayed.append(instance.uid)
	displayed.sort()
	var expected: Array = run_before.owned_cards.map(func(card): return card.uid)
	expected.sort()
	check(displayed == expected, tag + " " + stage + " each owned UID appears once, including installed cards.")
	if scene != null:
		var permanent_installed: int = battle_before.board.filter(func(piece): return piece.get("kind") == "rune" and not battle_before.catalog[piece.rune_id].get("temporary", false)).size()
		check(described.zone_counts.installed == permanent_installed, tag + " " + stage + " installed zone agrees with the detached live board.")
		check(described.temporary.all(func(card): return not card.uid in expected), tag + " " + stage + " generated battle cards never inflate owned counts.")
	await save(viewport, stage + "-" + tag)
	check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(viewer.close_button.get_global_rect()), tag + " " + stage + " collection Close stays reachable: " + str(viewer.close_button.get_global_rect()))
	if not viewer.card_buttons.is_empty():
		var card: Button = viewer.card_buttons[-1]
		viewer.body_scroll.ensure_control_visible(card)
		await settle()
		var list_offset: int = viewer.body_scroll.scroll_vertical
		await _mouse(viewport, Vector2(card.get_global_rect().get_center().x, card.get_global_rect().position.y + 30))
		check(viewer.detail_visible, tag + " " + stage + " native card tap opens read-only details.")
		await save(viewport, stage + "-details-" + tag)
		await _touch(viewport, viewer.close_button.get_global_rect().get_center())
		check(not viewer.detail_visible and viewer.body_scroll.scroll_vertical == list_offset, tag + " " + stage + " detail Back restores collection scrolling: actual %d expected %d." % [viewer.body_scroll.scroll_vertical, list_offset])
		viewer.body_scroll.scroll_vertical = 100000
		await settle()
		check(viewer.body_scroll.scroll_vertical > 0, tag + " " + stage + " collection scroll reaches all copies and temporary section.")
		await save(viewport, stage + "-scrolled-" + tag)
	await _touch(viewport, viewer.close_button.get_global_rect().get_center())
	check(app.run_state.snapshot() == run_before, tag + " " + stage + " collection inspection/Close preserves authoritative ownership and RNG.")
	if scene != null:
		check(app.combat_scene == scene and scene.controller.snapshot() == battle_before and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection and scene.page_scroll.scroll_vertical == offset, tag + " " + stage + " collection preserves Combat/controller, preparation, selection and scroll.")
	if via_menu:
		check(app.route_menu == shared_menu and shared_menu.visible and scene._shell_modal and not scene.menu.visible, tag + " Collection Close returns to the exact shared Combat Menu with gameplay still blocked.")
		await _touch(viewport, app.route_menu_resume.get_global_rect().get_center())
		check(not shared_menu.visible and not scene._shell_modal and scene.controller.snapshot() == battle_before and app.run_state.snapshot() == run_before and scene.page_scroll.scroll_vertical == offset and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, tag + " Shared Resume preserves prepared battle and ownership after collection inspection.")

func _reward_layout(app: Control, viewport: SubViewport, dimensions: Vector2i, tag: String, stage: String) -> void:
	var viewer: Control = app.reward_screen
	for button in [viewer.close_button, viewer.skip_button, viewer.gold_button]:
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Reward action is reachable: " + button.text + " " + str(button.get_global_rect()))
	check(viewer.choose_buttons.size() == 3, tag + " Exactly three distinct configured cards are displayed.")
	await save(viewport, stage + "-" + tag)
	viewer.scroll.scroll_vertical = 100000
	await settle()
	check(viewer.scroll.scroll_vertical > 0 or dimensions.y >= 1000, tag + " Narrow reward content scrolls without hiding fixed actions.")
	await save(viewport, stage + "-scrolled-" + tag)
	viewer.scroll.scroll_vertical = 0
	await settle()

func _mouse(viewport: SubViewport, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func _touch(viewport: SubViewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)
	await settle()

func _dispose(app: Control, viewport: SubViewport) -> void:
	app.queue_free()
	await settle()
	viewport.queue_free()
	await settle()

func _reward_cue_count(owner: Node) -> int:
	return owner.trace.filter(func(record): return record.cue == "reward").size()

func settle() -> void:
	for frame in 8: await process_frame
	if _capture and DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(viewport: SubViewport, file_name: String) -> void:
	if not _capture: return
	check(DisplayServer.get_name() != "headless", "Capture requires actual rendering.")
	if DisplayServer.get_name() == "headless": return
	check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(file_name + ".png")) == OK, file_name + " PNG saved.")
