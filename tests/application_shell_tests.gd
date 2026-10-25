extends SceneTree
## RC-025: real Home/Map ownership plus explicit standalone battle fixtures.
const Settings = preload("res://scripts/audio/audio_settings.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const RunState = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
var destination := "res://output/qa/rc-025"
var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-output="):
			destination = argument.trim_prefix("--qa-output=")
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 5: await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	var settings_path := destination.path_join("shell-test-settings.cfg")
	var values := Settings.DEFAULTS.duplicate(true)
	values.reduced_motion = true
	Settings.save_values(values, settings_path)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(450, 1000)
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = settings_path
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	viewport.add_child(app)
	await settle()
	var application_menu: Control = app.route_menu
	check(app.run_state == null and app.combat_scene == null and app.home.visible, "Fresh app opens Home without a run or battle.")
	check(app.continue_button.disabled, "Continue is unavailable without an in-memory session.")
	check(app.audio.loop_snapshot().context == "screen_home" and app.audio.loop_snapshot().ambience.cue == "" and app.audio.loop_snapshot().music.all(func(slot): return slot.cue == ""), "Home owns no crypt ambience and does not substitute missing music.")
	app.continue_run()
	check(app.run_state == null, "Repeated unavailable Continue cannot create a run.")
	app.open_options()
	check(app.options.visible, "Shared Options is available from Home.")
	app.options.sliders.music_volume.value = 37
	app.options.sliders.sfx_volume.value = 61
	app.close_options()
	check(is_equal_approx(Settings.load_values(settings_path).music_volume, 0.37) and is_equal_approx(Settings.load_values(settings_path).sfx_volume, 0.61), "Home Options persists independent Music and SFX preferences.")
	app.request_new_run(294)
	await settle()
	await _route_navigation(app, viewport)
	_attach_standalone(app, 294)
	await settle()
	check(app.run_state != null and is_instance_valid(app.combat_scene), "Explicit standalone fixture attaches its independent run and production Combat scene.")
	var scene: Control = app.combat_scene
	var run = app.run_state
	var opening: Dictionary = scene.controller.snapshot()
	var entry_opening: Dictionary = opening.duplicate(true)
	check(opening.player_hp == 30 and opening.player_max_hp == 30 and opening.has("production"), "Shell uses the 30/30 production fixture and its existing rules.")
	check(is_equal_approx(scene.audio_settings.music_volume, 0.37) and is_equal_approx(scene.audio_settings.sfx_volume, 0.61), "Combat loads exactly the Home Options preferences.")
	check(scene.audio.loop_snapshot().ambience.cue == "crypt", "The Combat owner starts the delivered crypt ambience.")
	var controller = scene.controller
	check(app.route_menu == application_menu and app.route_menu_resume.text == "Resume Combat", "Map and Combat retain the exact same Menu instance and approved gameplay Resume label.")
	var original_menu_callback: Callable = app._battle_menu_callback
	await _battle_map_round_trip(app, viewport)
	opening = controller.snapshot()
	scene._open_menu()
	check(app.route_menu.visible and not scene.menu.visible and scene._shell_modal, "Combat opens the application Menu and keeps the standalone native Menu hidden.")
	app.route_menu_resume.pressed.emit()
	check(not app.route_menu.visible and not scene._shell_modal and scene.controller == controller and scene.controller.snapshot() == opening, "Shared Menu Resume retains the current controller and exact battle state.")
	scene._open_menu()
	app.route_menu_options.pressed.emit()
	app.options.sliders.sfx_volume.value = 48
	app.close_options()
	check(app.route_menu.visible and scene._shell_modal and scene.controller.snapshot() == opening and is_equal_approx(scene.audio_settings.sfx_volume, 0.48), "Shared Combat Options updates the existing audio owner and returns to the same Menu without resetting battle state.")
	app.route_menu_resume.pressed.emit()
	var delayed := Delayed.new()
	check(controller.set_presenter(delayed), "A retained-callback presenter can be attached at the supported controller seam.")
	check(controller.command("pass"), "One Pass resolves through the real controller.")
	check(not controller.command("pass"), "Repeated Pass during playback is rejected.")
	app.open_map()
	check(app.map_screen == null or not app.map_screen.visible, "Map cannot open during unsettled presentation.")
	app.request_home()
	check(not app.confirmation.visible and app.combat_scene == scene, "Quit cannot interrupt an unsettled action or race its terminal commit.")
	scene._open_menu(false)
	check(app.route_menu.visible and app.route_menu_quit.disabled and app.route_menu_collection.disabled and controller.is_busy(), "Shared Menu remains available during presentation while unsafe Quit and Collection actions are disabled.")
	var busy_run: Dictionary = run.snapshot()
	app.route_menu_store.pressed.emit()
	app.open_store()
	check(app.route_menu_store.disabled and not app.store_screen.visible and run.snapshot() == busy_run and controller.is_busy(), "Disabled and direct Store callbacks cannot interrupt active presentation or alter its run.")
	app.route_menu_quit.pressed.emit()
	check(not app.confirmation.visible and controller.is_busy(), "A direct disabled Quit callback cannot bypass the unsettled-action guard.")
	app.route_menu_resume.pressed.emit()
	check(not app.route_menu.visible and not scene._shell_modal and controller.is_busy(), "Resume closes only shared Menu without completing or unlocking presentation.")
	delayed.complete()
	var progressed: Dictionary = controller.snapshot()
	check(progressed.player_hp < opening.player_hp and progressed.turn == 2, "The action advances one turn and applies the encounter's actual damage.")
	var run_before: Dictionary = run.snapshot()
	app.request_home()
	check(app.confirmation.visible and app.confirmation_text.text.to_lower().contains("replay"), "Quit explains the entry replay policy before progress is discarded.")
	await settle()
	_tap(viewport, app.confirmation_cancel.get_global_rect().get_center())
	check(app.combat_scene == scene and controller.snapshot() == progressed and run.snapshot() == run_before, "Cancelling Quit preserves the run, card identities, battle and RNG.")
	check(not app.confirmation.visible, "A real routed finger tap reaches Quit Cancel above the Combat scene.")
	app.request_home()
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.confirmation.visible and not scene.menu.visible and not app.route_menu.visible and controller.snapshot() == progressed, "Duplicate Android Back cancels only the shell confirmation, without opening Combat Menu or mutating play.")
	await settle()
	scene._open_menu(false)
	app.route_menu_quit.pressed.emit()
	check(app.confirmation.visible and app.route_menu.visible, "Shared Combat Menu keeps its caller beneath the checkpoint confirmation.")
	app.cancel_confirmation()
	check(app.route_menu.visible and scene._shell_modal and controller.snapshot() == progressed and run.snapshot() == run_before, "Cancelling checkpoint Quit restores the same shared Menu without unblocking or mutating Combat.")
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.route_menu.visible and not scene._shell_modal and controller.snapshot() == progressed, "Duplicate Back resumes from shared Combat Menu exactly once.")
	await settle()
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var held_point: Vector2 = scene.stock_buttons.straight.get_global_rect().get_center()
	var press := InputEventScreenTouch.new()
	press.position = held_point
	press.pressed = true
	viewport.push_input(press, true)
	app.open_map()
	app.map_screen.menu_requested.emit()
	app.route_menu_quit.pressed.emit()
	check(app.confirmation.visible and scene.gestures._gesture.is_empty() and scene.gestures._touches.is_empty(), "Opening Map, shared Menu and its checkpoint confirmation clears Combat's held-pointer ownership.")
	app.confirm_home()
	app.confirm_home()
	var release := InputEventScreenTouch.new()
	release.position = held_point
	release.pressed = false
	viewport.push_input(release, true)
	await settle()
	check(app.combat_scene == null and app.map_screen == null and not app.route_menu.visible and app.home.visible and run.snapshot().status == "replay_pending", "Confirmed Quit from Map over Combat dismisses Map and Menu and returns Home once with a replayable session.")
	check(not controller.command("pass"), "The detached Combat controller rejects later commands.")
	check(not app.continue_button.disabled, "Home exposes session-only Continue after Quit.")
	check(app.audio.loop_snapshot().ambience.cue == "" and app.audio.loop_starts.ambience == 0, "Returning Home disposes crypt playback instead of inheriting its ambience.")
	app.open_options()
	check(is_equal_approx(app.options.sliders.sfx_volume.value, 48.0), "Home Options retains the setting changed in Combat.")
	app.close_options()
	var checkpoint: Dictionary = run.snapshot()
	app.request_new_run(99)
	check(app.confirmation.visible, "New Run requires confirmation before replacing an existing session.")
	app.cancel_confirmation()
	check(app.run_state == run and run.snapshot() == checkpoint, "Cancelling replacement leaves identity, owned cards, HP and all RNG unchanged.")
	app.continue_run()
	app.continue_run()
	await settle()
	check(app.run_state == run and app.combat_scene.controller.snapshot() == entry_opening, "Session Continue restores the same opening once without rerolls or accidental healing beyond the explained checkpoint replay.")
	var replay_scene: Control = app.combat_scene
	var replay_before: Dictionary = replay_scene.controller.snapshot()
	original_menu_callback.call(false)
	check(not app.route_menu.visible and replay_scene.controller.snapshot() == replay_before, "An old Combat Menu callback cannot open a menu over the replacement scene.")
	app.request_new_run(999)
	check(app.run_state == run and not app.confirmation.visible, "Stale New Run taps cannot replace an attached Combat session.")
	delayed.complete()
	check(replay_scene.controller.snapshot() == replay_before and not replay_scene.controller.is_busy(), "An old animation completion cannot change the replacement scene or unlock a later action.")
	app.request_home()
	app.confirm_home()
	await settle()
	var old_id: String = run.snapshot().run_id
	app.request_new_run(42)
	app.confirm_new_run()
	app.confirm_new_run()
	await settle()
	check(app.run_state.snapshot().run_id != old_id and app.run_state.snapshot().seed == 42, "Confirmed replacement allocates one new run with the requested seed.")
	check(app.run_state.snapshot().gold == 0 and app.run_state.snapshot().relics.is_empty(), "Replacement does not inherit run Gold or relics.")
	check(app.combat_scene == null and app.map_screen.visible, "Confirmed New Run replacement opens an unvisited route, never a fabricated progressed battle.")
	app.close_map()
	_attach_standalone(app, 42)
	await settle()
	# Defeat is an actual sequence of production Pass commands, no forced model state.
	scene = app.combat_scene
	var fast := preload("res://scripts/ui/combat_presentation.gd").new()
	check(scene.controller.set_presenter(fast), "The synchronous presenter supports deterministic outcome verification.")
	for turn in 6:
		if scene.controller.snapshot().state != "playing": break
		scene.controller.command("pass")
	await settle()
	check(app.run_state.snapshot().status == "defeated" and app.run_state.snapshot().player_hp == 0, "A terminal defeat commits actual health exactly once after presentation.")
	var defeated: Dictionary = app.run_state.snapshot()
	scene.controller.changed.emit()
	check(app.run_state.snapshot() == defeated, "Repeated terminal notifications cannot commit a result again.")
	app.request_home()
	if app.confirmation.visible: app.confirm_home()
	await settle()
	check(app.combat_scene == null and not app.continue_button.disabled and app.continue_button.text == "View results" and not app.run_state.snapshot().can_continue, "Returning Home after defeat preserves accessible results and cannot replay a defeated run.")
	app.continue_run()
	await settle()
	check(app.run_review.visible and app.run_review.final_review and app.combat_scene == null and app.map_screen == null, "Home View results reopens read-only defeat review without Combat or a dead-end Map.")
	app.run_review.action_requested.emit("home", app.run_review.identity)
	await settle()
	app.request_new_run(123)
	if app.confirmation.visible: app.confirm_new_run()
	await settle()
	app.close_map()
	_attach_standalone(app, 123)
	await settle()
	var closing_controller = app.combat_scene.controller
	var closing_presenter := Delayed.new()
	closing_controller.set_presenter(closing_presenter)
	closing_controller.command("pass")
	var closing_run = app.run_state
	app.queue_free()
	await settle()
	var after_disposal: Dictionary = closing_run.snapshot()
	closing_presenter.complete()
	check(not closing_controller.command("pass") and closing_run.snapshot() == after_disposal, "Closing during playback invalidates stale completion and command callbacks.")
	var fresh: Control = load("res://scenes/application.tscn").instantiate()
	fresh.settings_path = settings_path
	fresh.save_path = fresh.settings_path + ".save-" + str(Time.get_ticks_usec())
	viewport.add_child(fresh)
	await settle()
	check(fresh.run_state == null and fresh.continue_button.disabled, "A new app instance restores preferences only; it never claims saved-run recovery.")
	check(is_equal_approx(Settings.load_values(settings_path).sfx_volume, 0.48), "Session disposal leaves existing settings intact.")
	fresh.queue_free()
	await settle()
	viewport.queue_free()
	await settle()
	await _native_home_input(settings_path)
	await create_timer(0.2).timeout
	var file := FileAccess.open(destination.path_join("shell-tests.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-025 shell checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _attach_standalone(app: Control, seed: int) -> void:
	# Only tests inject this adapter. New Run never chooses or clears a route room.
	app.run_state = RunState.new(Loader.load_setup().setup, seed)
	app.persistence_context = app.run_state.restore_context_for_tests()
	var entered: Dictionary = app.run_state.enter_battle()
	check(entered.ok, "Isolated production battle fixture enters through RunState.")
	if entered.ok:
		var before: Dictionary = app.run_state.snapshot()
		var opening: Dictionary = entered.combat.snapshot()
		var home_audio = app.audio
		var prepared: Dictionary = app._prepare_battle_scene(entered.combat, Loader.load_setup().setup)
		check(prepared.ok and prepared.scene.audio == null and not prepared.scene.visible and prepared.scene._shell_modal, "Candidate scene prepares its real controller and resources with no audio owner or active input.")
		check(app.audio == home_audio and app.run_state.snapshot() == before and entered.combat.snapshot() == opening, "Preparing the candidate leaves Home audio, committed run ownership and the exact opening unchanged.")
		var candidate_controller = prepared.scene.controller
		app._dispose_candidate_scene(prepared.scene)
		check(not candidate_controller.command("pass") and entered.combat.snapshot() == opening, "Discarding an unused candidate disposes callbacks and cannot draw, play or mutate the retained model.")
		app._attach_battle(entered.combat)

func _route_navigation(app: Control, viewport: SubViewport) -> void:
	check(app.run_state != null and app.combat_scene == null and app.map_screen.visible, "New Run creates a fresh route and opens its live Map without entering a room.")
	var run = app.run_state
	var initial: Dictionary = run.snapshot()
	var route: Dictionary = run.route_snapshot()
	check(route.visit_count == 0 and route.current_node_id == "" and route.visited_node_ids.is_empty(), "The fresh tower has zero visits and no fabricated earlier rooms.")
	check(initial.player_hp == 30 and initial.gold == 0 and initial.relics.is_empty(), "Map begins with the actual accepted health, Gold and relic baseline.")
	check(app.audio.loop_snapshot().ambience.cue == "" and app.audio.loop_starts.ambience == 0, "A route Map opened from Home never starts unrelated crypt ambience.")
	var entry: String = route.entry_node_ids[0]
	_tap(viewport, app.map_screen.node_buttons[entry].get_global_rect().get_center())
	check(app.map_screen.inspection.visible and run.snapshot() == initial, "A routed finger tap inspects an available node without changing state.")
	app.map_screen.close_inspection()
	# Tall portrait now fits the graph. Use the genuinely short viewport for the
	# scroll gesture regression instead of requiring unnecessary tall scrolling.
	var original_dimensions := viewport.size
	viewport.size = Vector2i(360, 640)
	await settle()
	app.map_screen.scroll.scroll_vertical = 100000
	await settle()
	var route_offset: int = app.map_screen.scroll.scroll_vertical
	var origin: Vector2 = app.map_screen.scroll.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.position = origin
	touch.pressed = true
	viewport.push_input(touch, true)
	var drag := InputEventScreenDrag.new()
	drag.position = origin + Vector2(0, 110)
	drag.relative = Vector2(0, 110)
	viewport.push_input(drag, true)
	touch = InputEventScreenTouch.new()
	touch.position = drag.position
	touch.pressed = false
	viewport.push_input(touch, true)
	check(route_offset > 0 and app.map_screen.scroll.scroll_vertical < route_offset and not app.map_screen.inspection.visible and run.snapshot() == initial, "Native short-portrait Map dragging scrolls toward the guardian while cancelling node activation.")
	viewport.size = original_dimensions
	await settle()
	await _route_menu_and_sound(app, initial)
	var locked: String = ""
	for node in route.nodes:
		if node.state == "locked":
			locked = node.id
			break
	app.map_screen.inspect_node(locked)
	check(app.map_screen.inspection.visible and not app.map_screen.inspection_action.visible, "Locked nodes can be inspected without an Enter action.")
	app.request_node_entry(locked)
	check(not app.confirmation.visible and run.snapshot() == initial, "A direct stale locked-node request cannot open entry confirmation or mutate a run.")
	app.map_screen.dismiss_top()
	app.map_screen.inspect_node(entry)
	check(app.map_screen.inspection.visible and app.map_screen.inspection_action.visible, "Available route node inspection exposes Enter.")
	app.map_screen.inspection_action.pressed.emit()
	check(app.confirmation.visible and run.snapshot() == initial, "Enter opens a separate confirmation without visiting, consuming RNG or unlocking successors.")
	await settle()
	_tap(viewport, app.confirmation_cancel.get_global_rect().get_center())
	check(not app.confirmation.visible and app.map_screen.visible and run.snapshot() == initial, "A native routed Cancel keeps the inspection/Map and entire model unchanged.")
	app.confirm_node_entry()
	check(run.snapshot() == initial, "A stale confirmation after Cancel cannot enter a node.")
	app.request_node_entry(entry)
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.confirmation.visible and app.map_screen.visible and app.map_screen.inspection.visible, "One duplicate Android Back dismisses only entry confirmation, retaining its inspection and Map.")
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(app.map_screen.visible and not app.map_screen.inspection.visible, "The next duplicate Android Back dismisses only node inspection.")
	await settle()
	app.request_node_entry(entry)
	app.confirm_node_entry()
	app.confirm_node_entry()
	check(run.snapshot() == initial and app.combat_scene == null, "Unsupported production room entry reports pending availability without consuming a choice or granting anything.")
	check(app.map_screen.status_label.text.contains("not available yet") and app.map_screen.status_label.text.contains("not been consumed"), "Unsupported encounter entry explains pending availability and retained route choice visibly.")
	var stale_map_generation: int = app._map_generation
	app.close_map()
	await settle()
	check(app.home.visible and not app.continue_button.disabled, "Closing a route Map returns Home with session Continue available.")
	app.request_new_run(999)
	check(app.confirmation.visible, "Replacing a route session requires explicit confirmation.")
	app.cancel_confirmation()
	app.confirm_node_entry()
	check(app.run_state == run and run.snapshot() == initial, "Replacement Cancel and stale entry callbacks retain the exact original route and RNG.")
	app.continue_run()
	app.continue_run()
	await settle()
	check(app.map_screen.visible and app.combat_scene == null and run.snapshot() == initial, "Repeated session Continue reopens the same route without regeneration.")
	var reopened: Control = app.map_screen
	app._map_entry_requested(entry, stale_map_generation)
	app._map_close_requested(stale_map_generation)
	var prior_sound: bool = app.audio_settings.enabled
	app._map_menu_requested(stale_map_generation)
	app._map_sound_requested(stale_map_generation)
	check(app.map_screen == reopened and not app.confirmation.visible and not app.route_menu.visible and app.audio_settings.enabled == prior_sound and run.snapshot() == initial, "Callbacks retained by an earlier Map cannot enter, dismiss, open Menu or toggle Sound on a reopened Map.")
	app.map_screen.menu_requested.emit()
	app.route_menu_quit.pressed.emit()
	check(app.confirmation.visible and app.map_screen.visible and app.run_state == run and run.snapshot() == initial, "Map Menu Quit requests confirmation without altering its checkpoint.")
	app.cancel_confirmation()
	check(app.map_screen.visible and app.route_menu.visible and app.run_state == run and run.snapshot() == initial, "Cancelling between-room Quit retains Menu, Map and every committed resource.")
	app.route_menu_quit.pressed.emit()
	app.confirm_home()
	await settle()
	check(app.map_screen == null and app.home.visible and app.run_state == run and run.snapshot() == initial, "Map Menu Quit returns Home without discarding or consuming route choices.")

func _route_menu_and_sound(app: Control, initial: Dictionary) -> void:
	var screen: Control = app.map_screen
	var offset: int = screen.scroll.scroll_vertical
	var audio = app.audio
	var prior_sound: bool = app.audio_settings.enabled
	screen.sound_requested.emit()
	check(app.audio_settings.enabled != prior_sound and app.audio == audio and app.run_state.snapshot() == initial, "Map Sound toggles the existing Home audio preference without replacing route state or coordinator.")
	screen.sound_requested.emit()
	check(app.audio_settings.enabled == prior_sound and app.audio.loop_snapshot().ambience.cue == "", "Restoring Map Sound retains Home's ambience-free context.")
	screen.menu_requested.emit()
	check(app.route_menu.visible and app.map_screen == screen and app.run_state.snapshot() == initial, "Map Menu retains the same route view and authoritative state.")
	check(not app.route_menu_store.disabled, "The accepted Store is available from the initial settled Map with zero Gold.")
	app.open_store()
	check(app.store_screen.visible and app.store_screen.presentation.gold == 0 and app.run_state.snapshot() == initial, "Default Store entry allows zero-Gold browsing without changing the run.")
	var store_identity: Dictionary = app.store_screen.presentation.identity.duplicate(true)
	app._store_purchase_requested(store_identity, "rune", "spark")
	check(not app.confirmation.visible and app.run_state.snapshot() == initial, "A direct unaffordable purchase callback cannot bypass zero-Gold item eligibility.")
	app.close_store()
	app._store_purchase_requested(store_identity, "rune", "spark")
	app.confirm_store_purchase()
	check(not app.store_screen.visible and not app.confirmation.visible and app.route_menu.visible and app.map_screen == screen and app.run_state.snapshot() == initial, "Store Back retains the exact Menu and Map, and detached purchase or confirmation callbacks cannot transact.")
	app.close_map()
	app.request_node_entry(app.run_state.route_snapshot().entry_node_ids[0])
	screen.sound_requested.emit()
	check(app.map_screen == screen and not app.confirmation.visible and app.audio_settings.enabled == prior_sound, "Map entry, close and Sound callbacks cannot pass through Menu.")
	app.route_menu_resume.pressed.emit()
	check(not app.route_menu.visible and app.map_screen == screen and screen.scroll.scroll_vertical == offset, "Menu Resume returns to the same Map and route scroll.")
	screen.menu_requested.emit()
	app.route_menu_options.pressed.emit()
	check(app.options.visible and app.route_menu.visible and app.map_screen == screen, "Map Menu opens shared Options above its retained caller.")
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.options.visible and app.route_menu.visible and app.map_screen == screen, "Duplicate Back closes only Map Options and returns to Menu.")
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.route_menu.visible and app.map_screen == screen and screen.scroll.scroll_vertical == offset and app.run_state.snapshot() == initial, "The next duplicate Back dismisses only Menu, preserving Map and route scroll.")
	await settle()

func _battle_map_round_trip(app: Control, viewport: SubViewport) -> void:
	var scene: Control = app.combat_scene
	var controller = scene.controller
	var model = scene.battle_model
	var audio = scene.audio
	var starts: int = audio.loop_starts.ambience
	var player = audio._ambience.player
	# Prepare a real board edit before opening Map, then retain a selected tool.
	scene._select_tool("straight")
	for index in scene.game.board.size():
		if scene.game.board[index].is_empty():
			scene.cells[index].pressed.emit()
			break
	scene._select_tool("corner")
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var preparation: Dictionary = controller.snapshot()
	var scroll: int = scene.page_scroll.scroll_vertical
	var hand_scroll: int = scene.hand_scroll.scroll_horizontal
	var selection: Array = [scene.selected_tool, scene.selected_uid, scene.selected_cell]
	var held_point: Vector2 = scene.stock_buttons.straight.get_global_rect().get_center()
	var held := InputEventScreenTouch.new()
	held.position = held_point
	held.pressed = true
	viewport.push_input(held, true)
	scene._show_map()
	await settle()
	check(app.map_screen.visible and scene._shell_modal, "Combat Map opens through the application shell and suspends Combat input.")
	check(scene.gestures._gesture.is_empty() and scene.gestures._touches.is_empty(), "Opening Map releases stale Combat pointer holds.")
	check(app.run_state.route_snapshot().is_empty(), "An explicit standalone Shadeling battle never fabricates tower history.")
	check(app.combat_scene == scene and scene.controller == controller and scene.battle_model == model, "Opening Map preserves Combat scene, controller and authoritative model identity.")
	check(scene.audio == audio and audio._ambience.player == player and audio.loop_starts.ambience == starts, "Map keeps the same ambience coordinator/player without a restart or duplicate listener.")
	scene.cells[0].pressed.emit()
	scene._select_tool("erase")
	check(controller.snapshot() == preparation and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, "Inputs beneath Map cannot edit the battle or change its selection.")
	for node_id in app.map_screen.node_buttons:
		app.map_screen.inspect_node(node_id)
		break
	check(app.map_screen.inspection.visible and app.map_screen.inspection_action.text.contains("Resume"), "Current standalone room inspection offers Resume, with no route advancement.")
	app.map_screen.inspection_action.pressed.emit()
	await settle()
	check(app.map_screen == null and not scene._shell_modal, "Resume room closes Map and restores Combat input.")
	check(controller.snapshot() == preparation and scene.page_scroll.scroll_vertical == scroll and scene.hand_scroll.scroll_horizontal == hand_scroll and [scene.selected_tool, scene.selected_uid, scene.selected_cell] == selection, "Map Resume retains board preparation, UID identities, RNG, selection and page/hand scroll.")
	app.open_map()
	await settle()
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(app.map_screen == null and not scene.menu.visible and not app.route_menu.visible and controller.snapshot() == preparation, "Duplicate Android Back closes only Map and cannot also open Combat Menu.")
	await settle()
	var release := InputEventScreenTouch.new()
	release.position = held_point
	release.pressed = false
	viewport.push_input(release, true)
	check(controller.snapshot() == preparation, "Releasing a pre-Map held finger cannot place anything after return.")
	app.open_map()
	var prior_sound: bool = scene.sound_enabled
	app.map_screen.sound_requested.emit()
	check(scene.sound_enabled != prior_sound and scene.audio == audio and scene.audio._ambience.player == player and controller.snapshot() == preparation, "Combat Map Sound updates its existing audio owner without replacing the player or model.")
	app.map_screen.sound_requested.emit()
	check(scene.sound_enabled == prior_sound, "Combat Map Sound restores the original master preference.")
	var retained_map: Control = app.map_screen
	var shared_menu: Control = app.route_menu
	app.map_screen.menu_requested.emit()
	check(app.map_screen == retained_map and app.route_menu == shared_menu and app.route_menu.visible and not scene.menu.visible and controller.snapshot() == preparation, "Map over Combat opens the same shared Menu while retaining its Map and battle caller.")
	app.route_menu_quit.pressed.emit()
	check(app.confirmation.visible and app.route_menu.visible and app.map_screen == retained_map, "Quit from the Map over Combat still requires the battle checkpoint confirmation.")
	app.cancel_confirmation()
	check(app.route_menu.visible and app.map_screen == retained_map and scene._shell_modal and controller.snapshot() == preparation, "Cancelling Map-over-Combat Quit retains Menu, Map, and the exact prepared battle.")
	app.route_menu_resume.pressed.emit()
	check(not app.route_menu.visible and app.map_screen == retained_map and scene._shell_modal, "Shared Menu Resume returns to its retained Map rather than navigating through Combat.")
	app.close_map()

func _tap(viewport: SubViewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		viewport.push_input(event, true)

func _native_home_input(settings_path: String) -> void:
	var old_size := root.size
	var old_embed := root.gui_embed_subwindows
	var old_accumulation := Input.use_accumulated_input
	var old_emulation := Input.emulate_mouse_from_touch
	root.size = Vector2i(720, 1600)
	root.gui_embed_subwindows = true
	Input.use_accumulated_input = false
	Input.emulate_mouse_from_touch = true
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = settings_path
	app.save_path = app.settings_path + ".save-" + str(Time.get_ticks_usec())
	root.add_child(app)
	await settle()
	var new_run_point: Vector2 = app.new_run_button.get_global_rect().get_center()
	_native_touch(new_run_point, true)
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_native_touch(new_run_point, false)
	check(app.run_state == null, "Home pause/resume cancels a held New Run finger without activating it on release.")
	_native_touch(app.options_button.get_global_rect().get_center(), true)
	_native_touch(app.options_button.get_global_rect().get_center(), false)
	await settle()
	check(app.options.visible, "Engine touch-to-mouse emulation opens shared Home Options exactly once.")
	var music: HSlider = app.options.sliders.music_volume
	_native_touch(music.get_global_rect().get_center(), true)
	_native_touch(music.get_global_rect().get_center(), false)
	check(absf(app.audio_settings.music_volume - 0.5) < 0.03 and is_equal_approx(app.audio_settings.sfx_volume, 0.48), "The first native Home Music touch changes Music only after captured Options input.")
	var changes := [0]
	app.options.setting_changed.connect(func(key: String, _value: Variant):
		if key == "enabled": changes[0] += 1
	)
	var toggle: Button = app.options.toggles.enabled
	_native_touch(toggle.get_global_rect().get_center(), true)
	_native_touch(toggle.get_global_rect().get_center(), false)
	check(changes[0] == 1, "Home's captured toggle after native slider input fires once.")
	var sfx: HSlider = app.options.sliders.sfx_volume
	_native_touch(sfx.get_global_rect().get_center(), true)
	_native_touch(sfx.get_global_rect().get_center(), false)
	check(absf(app.audio_settings.sfx_volume - 0.5) < 0.03 and app.run_state == null, "The first native Home SFX touch after a captured toggle changes SFX without creating a run.")
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.options.visible and app.run_state == null, "Duplicate Home Back dismisses Options without starting, replacing or quitting a run.")
	app.queue_free()
	await settle()
	Input.use_accumulated_input = old_accumulation
	Input.emulate_mouse_from_touch = old_emulation
	root.gui_embed_subwindows = old_embed
	root.size = old_size

func _native_touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
