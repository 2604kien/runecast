extends SceneTree
## Actual live Map renders. Traversed states use only this excluded test adapter;
## they prove presentation, never a completed playable production tower.
const DESTINATION := "res://output/qa/rc-025-map-match/screenshots"
const RunState = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	for dimensions in [Vector2i(841, 1870), Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture(dimensions)
	await create_timer(0.2).timeout
	var file := FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions,
		"engine": Engine.get_version_info().string,
		"scope": "Actual desktop live UI renders. Fresh/inspection/confirmation/pending are production flow. Fixture-current/fixture-completed are isolated adapter traversal. Battle is an explicit standalone encounter. No physical-device or playable-full-tower acceptance."}, "  ") + "\n")
	print("%d RC-025 Map reference capture checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _capture(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = DESTINATION.path_join("capture-settings.cfg")
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	var settings := preload("res://scripts/audio/audio_settings.gd")
	var values: Dictionary = settings.DEFAULTS.duplicate(true)
	# Capture runs use Godot's Dummy audio driver; keep the visible Sound state
	# enabled so the reference comparison reflects the normal speaker icon.
	values.enabled = true
	values.reduced_motion = true
	settings.save_values(values, app.settings_path)
	viewport.add_child(app)
	await settle()
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	app.request_new_run(294)
	await settle()
	check(app.map_screen != null and app.combat_scene == null, tag + " Production New Run opens live Map.")
	var screen: Control = app.map_screen
	var view_rect := Rect2(Vector2.ZERO, Vector2(dimensions))
	check(view_rect.encloses(screen.close_button.get_global_rect()) and screen.close_button.size.y >= 44, tag + " Map dismissal is reachable and touch-sized.")
	check(view_rect.encloses(screen.scroll.get_global_rect()), tag + " Route scroll area fits the portrait viewport.")
	var navigation_surface: Control = screen._navigation.get_meta("combat_surface")
	check(navigation_surface.size == screen._navigation.size and navigation_surface.size.x > 0, tag + " Framed navigation surface fills the live navigation container.")
	await save(viewport, "fresh-route-" + tag)
	var initial: Dictionary = app.run_state.snapshot()
	screen.menu_requested.emit()
	await settle()
	check(app.route_menu.visible and view_rect.encloses(app._route_menu_panel.get_global_rect()), tag + " Map Menu fits the viewport.")
	for button in [app.route_menu_resume, app.route_menu_options, app.route_menu_store, app.route_menu_quit]:
		check(view_rect.encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Map Menu action remains reachable: " + button.text)
	await save(viewport, "map-menu-" + tag)
	app.route_menu_options.pressed.emit()
	await settle()
	check(app.options.visible and view_rect.encloses(app.options.panel.get_global_rect()), tag + " Shared Options fits above Map Menu.")
	await save(viewport, "map-options-" + tag)
	app.close_options()
	app.route_menu_resume.pressed.emit()
	await settle()
	check(app.map_screen == screen and app.run_state.snapshot() == initial, tag + " Menu and Options return to the same Map without model changes.")
	var entry: String = app.run_state.route_snapshot().entry_node_ids[0]
	check(screen.scroll.get_global_rect().encloses(screen.node_buttons[entry].get_global_rect()), tag + " Fresh Map initially reveals its available entry node.")
	var node_rects: Array[Rect2] = []
	for button in screen.node_buttons.values():
		check(button.size.x >= 44 and button.size.y >= 44, tag + " Each live node keeps a touch-sized target.")
		var bounds: Rect2 = button.get_global_rect()
		for previous in node_rects:
			check(not previous.intersects(bounds), tag + " Live node targets never overlap.")
		node_rects.append(bounds)
	screen.inspect_node(entry)
	await settle()
	_check_sheet(screen, view_rect, tag)
	await save(viewport, "node-inspection-" + tag)
	screen.inspection_action.pressed.emit()
	await settle()
	check(app.confirmation.visible and view_rect.encloses(app._confirmation_panel.get_global_rect()), tag + " Entry confirmation fits the viewport.")
	for button in [app.confirmation_confirm, app.confirmation_cancel]:
		check(view_rect.encloses(button.get_global_rect()) and button.size.y >= 44, tag + " Entry confirmation action is reachable: " + button.text)
	await save(viewport, "entry-confirmation-" + tag)
	app.cancel_confirmation()
	app.request_node_entry(entry)
	app.confirm_node_entry()
	await settle()
	check(app.run_state.snapshot() == initial, tag + " Pending production content never consumes route selection.")
	_check_sheet(screen, view_rect, tag)
	await save(viewport, "room-pending-" + tag)
	screen.dismiss_top()
	screen.scroll.scroll_vertical = 0
	await settle()
	check(screen.scroll.scroll_vertical == 0, tag + " Scroll reaches guardian end.")
	await save(viewport, "route-guardian-end-" + tag)
	screen.scroll.scroll_vertical = 100000
	await settle()
	check(screen.scroll.scroll_vertical > 0 or screen.scroll.get_v_scroll_bar().max_value <= screen.scroll.size.y, tag + " Narrow route scroll reaches initial entries.")
	await save(viewport, "route-entry-end-" + tag)
	app.close_map()
	check(app.map_screen == null and app.home.visible, tag + " Dismissal returns to Home caller.")
	# Traversal is a deliberately isolated fixture. It invokes the exact model
	# entry/completion interfaces but does not heal, reward or play these rooms.
	var fixture = RunState.new(Loader.load_setup().setup, 294, true)
	for depth in 2:
		var visit := _enter_available(fixture)
		check(not visit.is_empty() and fixture.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed"), tag + " Fixture commits one structural room " + str(depth + 1))
	var reference_visit := _enter_available(fixture)
	app.run_state = fixture
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	screen = app.map_screen
	check(fixture.route_snapshot().completed_count == 2 and fixture.route_snapshot().visit_count == 3, tag + " Comparison fixture has exactly two completed rooms and one current room.")
	await save(viewport, "reference-current-depth3-" + tag)
	if dimensions == Vector2i(841, 1870):
		await _save_comparison(viewport, "approved-vs-live-current-depth3", "LIVE MAP · active third room · isolated test traversal")
	check(fixture.resolve_room(reference_visit.run_id, reference_visit.node_id, reference_visit.visit_id, "completed"), tag + " Comparison fixture resolves current room before successors unlock.")
	app.close_map()
	app.open_map()
	await settle()
	await save(viewport, "reference-frontier-depth3-" + tag)
	if dimensions == Vector2i(841, 1870):
		await _save_comparison(viewport, "approved-vs-live-frontier-depth3", "LIVE MAP · three completed rooms · isolated test traversal")
	app.close_map()
	var fourth := _enter_available(fixture)
	check(fixture.resolve_room(fourth.run_id, fourth.node_id, fourth.visit_id, "completed"), tag + " Fixture reaches fourth completion without fabricated rewards.")
	var active := _enter_available(fixture)
	app.run_state = fixture
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	screen = app.map_screen
	_focus_node(screen, active.node_id)
	await settle()
	check(fixture.route_snapshot().completed_count == 4 and fixture.route_snapshot().visit_count == 5, tag + " Fixture current/visited/locked states reflect real route transitions.")
	await save(viewport, "fixture-current-visited-locked-" + tag)
	screen.inspect_node(active.node_id)
	await settle()
	_check_sheet(screen, view_rect, tag)
	await save(viewport, "fixture-current-inspection-" + tag)
	screen.dismiss_top()
	check(fixture.resolve_room(active.run_id, active.node_id, active.visit_id, "completed"), tag + " Fixture room completes exactly once.")
	app.close_map()
	app.open_map()
	await settle()
	screen = app.map_screen
	_focus_node(screen, active.node_id)
	await settle()
	await save(viewport, "fixture-completed-available-" + tag)
	for node in fixture.route_snapshot().nodes:
		if node.encounter_role == "boss":
			screen.inspect_node(node.id)
			break
	await settle()
	check(screen.inspection_body.text.contains("Encounter: Boss") and not screen.inspection_body.text.contains("Room 6 of 9 · Normal"), tag + " Shadeling inspection communicates Boss despite its underlying normal room family.")
	var body_scroll: ScrollContainer = screen.inspection_panel.get_meta("rc_body_scroll")
	check(body_scroll.scroll_vertical == 0 and screen.inspection_body.position.y >= 0, tag + " Newly opened boss sheet starts at its first line; scroll=%d, label_y=%f." % [body_scroll.scroll_vertical, screen.inspection_body.position.y])
	await save(viewport, "fixture-boss-inspection-" + tag)
	body_scroll.scroll_vertical = 100000
	await settle()
	var scrolled_boss: int = body_scroll.scroll_vertical
	screen.close_inspection()
	screen.inspect_node("d6")
	await settle()
	check(body_scroll.scroll_vertical == 0, tag + " Reopening a scrolled boss sheet starts at the top (prior offset %d)." % scrolled_boss)
	body_scroll.scroll_vertical = 100000
	await settle()
	screen.inspect_node("d9")
	await settle()
	check(body_scroll.scroll_vertical == 0, tag + " Switching from a scrolled sheet to another node starts at the top.")
	body_scroll.scroll_vertical = 100000
	await settle()
	screen._show_help()
	await settle()
	check(body_scroll.scroll_vertical == 0, tag + " Route help starts at the top after inspecting scrolled content.")
	body_scroll.scroll_vertical = 100000
	await settle()
	screen.close_inspection()
	screen._show_help()
	await settle()
	check(body_scroll.scroll_vertical == 0, tag + " Reopening scrolled route help starts at the top.")
	screen.dismiss_top()
	screen.inspect_node(active.node_id)
	await settle()
	check(not screen.inspection_action.visible, tag + " Visited fixture node has no replay/reclaim action.")
	await save(viewport, "fixture-visited-inspection-" + tag)
	screen.dismiss_top()
	for node in fixture.route_snapshot().nodes:
		if node.state == "locked":
			screen.inspect_node(node.id)
			break
	await settle()
	_check_sheet(screen, view_rect, tag)
	await save(viewport, "fixture-locked-inspection-" + tag)
	app.close_map()
	for depth in range(6, 9):
		var visit := _enter_available(fixture)
		check(fixture.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed"), tag + " Test adapter completes room %d before guardian presentation." % depth)
	var guardian_visit := _enter_available(fixture)
	app.open_map()
	await settle()
	screen = app.map_screen
	check(fixture.route_snapshot().completed_count == 8 and fixture.route_snapshot().visit_count == 9 and guardian_visit.node_id == "d9", tag + " Guardian-current capture uses eight actual fixture completions and a ninth active visit.")
	check(screen.scroll.get_global_rect().encloses(screen.node_buttons[guardian_visit.node_id].get_global_rect()), tag + " Active guardian is initially visible without clipping its node target.")
	await save(viewport, "fixture-current-guardian-" + tag)
	app.close_map()
	# Explicit RC-024 standalone battle: no earlier tower rooms are invented.
	app.run_state = RunState.new(Loader.load_setup().setup, 294)
	app.persistence_context = app.run_state.restore_context_for_tests()
	var entered: Dictionary = app.run_state.enter_battle()
	app._attach_battle(entered.combat)
	await settle()
	var scene: Control = app.combat_scene
	scene._select_tool("straight")
	for index in scene.game.board.size():
		if scene.game.board[index].is_empty():
			scene.cells[index].pressed.emit()
			break
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var preparation: Dictionary = scene.controller.snapshot()
	var controller = scene.controller
	var model = scene.battle_model
	var scroll_position: int = scene.page_scroll.scroll_vertical
	await save(viewport, "battle-prepared-" + tag)
	scene._show_map()
	await settle()
	check(app.map_screen != null and app.combat_scene == scene and scene.controller == controller and scene.battle_model == model, tag + " Battle Map preserves scene/controller/model identity.")
	await save(viewport, "battle-map-" + tag)
	for node_id in app.map_screen.node_buttons:
		app.map_screen.inspect_node(node_id)
		break
	await settle()
	_check_sheet(app.map_screen, view_rect, tag)
	await save(viewport, "battle-resume-inspection-" + tag)
	app.map_screen.inspection_action.pressed.emit()
	await settle()
	check(app.map_screen == null and scene.controller.snapshot() == preparation and scene.page_scroll.scroll_vertical == scroll_position, tag + " Resume retains actual preparation and scroll.")
	await save(viewport, "battle-resumed-" + tag)
	app.queue_free()
	await settle()
	viewport.queue_free()
	await process_frame

func _fixture_handler(_node: Dictionary, _visit: Dictionary) -> Dictionary:
	return {"ok": true}

func _enter_available(run) -> Dictionary:
	for node in run.route_snapshot().nodes:
		if node.state == "available":
			var requested: Dictionary = run.request_room_entry(node.id)
			var entered: Dictionary = run.confirm_room_entry(requested.token, _fixture_handler)
			return entered.get("visit", {})
	return {}

func _focus_node(screen: Control, node_id: String) -> void:
	if screen.node_buttons.has(node_id):
		screen.scroll.ensure_control_visible(screen.node_buttons[node_id])

func _check_sheet(screen: Control, view_rect: Rect2, tag: String) -> void:
	check(screen.inspection.visible and view_rect.encloses(screen.inspection_panel.get_global_rect()), tag + " Inspection sheet fits without clipping.")
	check(view_rect.encloses(screen.inspection_close.get_global_rect()) and screen.inspection_close.size.y >= 44, tag + " Inspection Close remains reachable.")
	if screen.inspection_action.visible:
		check(view_rect.encloses(screen.inspection_action.get_global_rect()) and screen.inspection_action.size.y >= 44, tag + " Inspection primary action remains reachable.")

func settle() -> void:
	for frame in 8: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func save(viewport: SubViewport, file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		check(false, "Captures require a rendering display.")
		return
	check(viewport.get_texture().get_image().save_png(DESTINATION.path_join(file_name + ".png")) == OK, file_name + " PNG saved.")

func _save_comparison(live_viewport: SubViewport, file_name: String, live_caption: String) -> void:
	# QA-only display of the reference beside the live rendered viewport. The
	# reference is never imported, cropped or used by the production Map.
	var comparison := SubViewport.new()
	comparison.size = Vector2i(1722, 1930)
	comparison.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(comparison)
	var background := ColorRect.new()
	background.color = Color("141c29")
	background.size = Vector2(comparison.size)
	comparison.add_child(background)
	var reference_image := Image.load_from_file(ProjectSettings.globalize_path("res://output/imagegen/approved/map.png"))
	check(reference_image != null and reference_image.get_size() == Vector2i(841, 1870), "QA comparison uses the intact approved reference at its native dimensions.")
	for index in 2:
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(reference_image) if index == 0 else live_viewport.get_texture()
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.position = Vector2(index * 881, 60)
		picture.size = Vector2(841, 1870)
		comparison.add_child(picture)
		var caption := Label.new()
		caption.text = "APPROVED REFERENCE · visual direction" if index == 0 else live_caption
		caption.add_theme_font_size_override("font_size", 22)
		caption.position = Vector2(index * 881 + 12, 12)
		caption.size = Vector2(817, 40)
		comparison.add_child(caption)
	await settle()
	await save(comparison, file_name)
	comparison.queue_free()
	await process_frame
