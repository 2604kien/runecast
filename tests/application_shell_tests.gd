extends SceneTree
## RC-024: exercise the real Home/Combat owners and retained callbacks.
const Settings = preload("res://scripts/audio/audio_settings.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const DESTINATION := "res://output/qa/rc-024"
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

func settle() -> void:
	for frame in 5: await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	var settings_path := DESTINATION.path_join("shell-test-settings.cfg")
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
	viewport.add_child(app)
	await settle()
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
	check(app.run_state != null and is_instance_valid(app.combat_scene), "New Run creates independent state and enters the production Combat scene.")
	var scene: Control = app.combat_scene
	var run = app.run_state
	var opening: Dictionary = scene.controller.snapshot()
	check(opening.player_hp == 30 and opening.player_max_hp == 30 and opening.has("production"), "Shell uses the 30/30 production fixture and its existing rules.")
	check(is_equal_approx(scene.audio_settings.music_volume, 0.37) and is_equal_approx(scene.audio_settings.sfx_volume, 0.61), "Combat loads exactly the Home Options preferences.")
	check(scene.audio.loop_snapshot().ambience.cue == "crypt", "The Combat owner starts the delivered crypt ambience.")
	var controller = scene.controller
	scene._open_menu()
	scene.menu.get_cancel_button().pressed.emit()
	scene.menu.hide()
	check(scene.controller == controller and scene.controller.snapshot() == opening, "Menu Resume retains the current controller and exact battle state.")
	scene._open_menu()
	scene._open_options()
	scene.options.sliders.sfx_volume.value = 48
	scene._close_options()
	check(scene.menu.visible and scene.controller.snapshot() == opening, "Combat Options returns to Menu without resetting battle state.")
	scene.menu.hide()
	var delayed := Delayed.new()
	check(controller.set_presenter(delayed), "A retained-callback presenter can be attached at the supported controller seam.")
	check(controller.command("pass"), "One Pass resolves through the real controller.")
	check(not controller.command("pass"), "Repeated Pass during playback is rejected.")
	app.request_home()
	check(not app.confirmation.visible and app.combat_scene == scene, "Quit cannot interrupt an unsettled action or race its terminal commit.")
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
	check(not app.confirmation.visible and not scene.menu.visible and controller.snapshot() == progressed, "Duplicate Android Back cancels only the shell confirmation, without opening Combat Menu or mutating play.")
	await settle()
	scene.page_scroll.scroll_vertical = 100000
	await settle()
	var held_point: Vector2 = scene.stock_buttons.straight.get_global_rect().get_center()
	var press := InputEventScreenTouch.new()
	press.position = held_point
	press.pressed = true
	viewport.push_input(press, true)
	app.request_home()
	check(scene.gestures._gesture.is_empty() and scene.gestures._touches.is_empty(), "Opening the shell confirmation clears Combat's held-pointer ownership.")
	app.confirm_home()
	app.confirm_home()
	var release := InputEventScreenTouch.new()
	release.position = held_point
	release.pressed = false
	viewport.push_input(release, true)
	await settle()
	check(app.combat_scene == null and app.home.visible and run.snapshot().status == "replay_pending", "Confirmed Quit returns Home once with a replayable session.")
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
	check(app.run_state == run and app.combat_scene.controller.snapshot() == opening, "Session Continue restores the same opening once without rerolls or accidental healing beyond the explained checkpoint replay.")
	var replay_scene: Control = app.combat_scene
	var replay_before: Dictionary = replay_scene.controller.snapshot()
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
	check(app.combat_scene == null and app.continue_button.disabled, "Returning Home after defeat preserves its result and cannot replay a defeated run.")
	app.request_new_run(123)
	if app.confirmation.visible: app.confirm_new_run()
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
	var file := FileAccess.open(DESTINATION.path_join("shell-tests.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-024 shell checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

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
