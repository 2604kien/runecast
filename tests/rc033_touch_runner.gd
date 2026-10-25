extends SceneTree
## Synthetic touch on the actual production view. No physical-device claim.
const Fixture = preload("res://tests/helpers/rc033_fixture.gd")
const Router = preload("res://scripts/ui/touch_router.gd")
const DESTINATION := "res://output/qa/rc-033/touch"
var checks := 0
var failures := 0
var assertions: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 6: await process_frame

func state(scene) -> Dictionary:
	var model = scene.battle_model
	return {"snapshot": scene.controller.snapshot(), "rng": [model.rng.state, model.endpoint_rng.state, model.kit_rng.state],
		"next_uid": model.next_uid, "history": model.history.duplicate(true)}

func touch(position: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	root.push_input(event, true)

func tap(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	touch(position, true)
	touch(position, false)

func mouse(position: Vector2, pressed: bool, device: int = 0, button: int = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.pressed = pressed
	event.device = device
	event.button_index = button
	root.push_input(event, true)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await _window(dimensions)
	await create_timer(0.25).timeout
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-033 touch: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _window(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = Fixture.load_fixture().setup
	scene.battle_model = Fixture.new_combat()
	scene.settings_path = DESTINATION.path_join(tag + ".cfg")
	root.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	scene.animation_presenter.automatic_timing = false
	await settle()
	check(Fixture.prepare_spark(scene.controller).ok, tag + " legal preparation makes background Cast consequential.")
	var commands: Array = []
	scene.controller.command_resolved.connect(func(outcome): commands.append(outcome.command))
	var before := state(scene)
	var point: Vector2 = scene.arena.intent_button.get_global_rect().get_center()
	var dispatches: int = scene._ui_audio_dispatch
	touch(point, true)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS - 0.01)
	check(not scene.inspector.visible, tag + " intent hold does not open before the shared hold threshold.")
	scene.gestures.advance_time(0.01)
	check(scene.inspector.visible and scene.inspector_title.text == "Enemy intent", tag + " intent hold opens the shared read-only popup.")
	scene.gestures.advance_time(5)
	touch(point, false)
	check(scene._ui_audio_dispatch == dispatches + 1 and state(scene) == before and commands.is_empty(), tag + " hold opens once and release neither repeats nor mutates Combat/RNG.")
	check(not scene.inspector_pass.visible and not scene.inspector_confirm_pass.visible, tag + " intent details expose only the fixed Close action.")
	for refresh in 5:
		scene._refresh()
		scene._cast()
		scene._pass()
		scene._inspect_intent()
		scene.inspector_pass.pressed.emit()
		scene.inspector_confirm_pass.pressed.emit()
	check(scene.inspector.visible and scene.inspector_title.text == "Enemy intent" and state(scene) == before and commands.is_empty(), tag + " repeated refresh and both stale Pass buttons cannot turn read-only intent into a gameplay confirmation.")
	await settle()
	tap(scene.inspector_close)
	check(not scene.inspector.visible and state(scene) == before, tag + " actual Close release cannot pass through to the prepared circuit.")
	for repeat in 4:
		tap(scene.arena.intent_button)
		await settle()
		check(scene.inspector.visible, tag + " repeated tap opens intent details %d." % repeat)
		scene._go_back()
		await settle()
	check(state(scene) == before and commands.is_empty() and not scene.menu.visible, tag + " repeated open/Back leaves every resource and RNG stream unchanged.")
	point = scene.arena.intent_button.get_global_rect().get_center()
	touch(point, true)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS)
	scene._go_back()
	touch(point, false)
	check(not scene.inspector.visible and not scene.menu.visible and state(scene) == before, tag + " Back during a held pointer consumes its release without reopening or navigating again.")
	touch(point, true)
	scene._refresh()
	scene.gestures.advance_time(1)
	touch(point, false)
	check(not scene.inspector.visible and state(scene) == before, tag + " refresh invalidates an unfinished intent hold.")
	touch(point, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(0, 30)
	drag.relative = Vector2(0, 30)
	root.push_input(drag, true)
	scene.gestures.advance_time(1)
	touch(point, false)
	check(not scene.inspector.visible and state(scene) == before, tag + " dragging over intent cancels tap/hold and retains ordinary page-scroll ownership.")
	scene.page_scroll.scroll_vertical = 0
	await settle()
	point = scene.arena.intent_button.get_global_rect().get_center()
	dispatches = scene._ui_audio_dispatch
	touch(point, true)
	mouse(point, true, Router.EMULATED_DEVICE)
	touch(point, false)
	mouse(point, false, Router.EMULATED_DEVICE)
	check(scene.inspector.visible and scene._ui_audio_dispatch == dispatches + 1 and commands.is_empty(), tag + " touch plus emulated mouse opens intent exactly once.")
	scene._go_back()
	await settle()
	for keycode in [KEY_ENTER, KEY_SPACE, KEY_I, KEY_TAB, KEY_ESCAPE, KEY_UP, KEY_DOWN]:
		for pressed in [true, false]:
			var key := InputEventKey.new()
			key.keycode = keycode
			key.pressed = pressed
			root.push_input(key, true)
	for pressed in [true, false]: mouse(point, pressed, 0, MOUSE_BUTTON_RIGHT)
	check(not scene.inspector.visible and not scene.menu.visible and scene.arena.intent_button.focus_mode == Control.FOCUS_NONE
		and root.gui_get_focus_owner() == null and state(scene) == before, tag + " production keyboard/right-click inputs cannot inspect, activate or focus the intent target.")

	# The same inspector is reused for Pass. Retained callbacks from a cancelled
	# confirmation must not turn a later read-only inspection into a Pass.
	scene._request_pass()
	await settle()
	check(scene.inspector_confirm_pass.visible and scene.inspector_text.text.contains("attacks for 8 damage"), tag + " Pass confirmation uses the actual announced attack.")
	var old_confirm: Button = scene.inspector_confirm_pass
	point = old_confirm.get_global_rect().get_center()
	touch(point, true)
	scene._go_back()
	scene._inspect_intent()
	await settle()
	touch(point, false)
	scene.inspector_pass.pressed.emit()
	old_confirm.pressed.emit()
	check(scene.inspector.visible and scene.inspector_title.text == "Enemy intent" and state(scene) == before and commands.is_empty(), tag + " cancelled Pass's retained signal and pointer release cannot act through replacement intent details.")
	scene._go_back()
	scene._request_pass()
	await settle()
	point = old_confirm.get_global_rect().get_center()
	touch(point, true)
	scene._go_back()
	scene._request_pass()
	await settle()
	touch(point, false)
	check(scene.inspector.visible and scene.inspector_confirm_pass.visible and state(scene) == before and commands.is_empty(), tag + " a newly opened Pass requires a fresh gesture; the old popup's release cannot confirm it.")
	scene._go_back()
	check(not scene.inspector.visible and state(scene) == before, tag + " cancelling Pass preserves turn, phase, intent and legal preparation.")
	check(scene.controller.command("cast"), tag + " prepared Cast starts its normal presentation after inspections close.")
	var committed := state(scene)
	scene._inspect_intent()
	scene.arena.intent_button.pressed.emit()
	point = scene.arena.intent_button.get_global_rect().get_center()
	touch(point, true)
	scene.gestures.advance_time(1)
	touch(point, false)
	check(scene.controller.is_busy() and not scene.inspector.visible and scene.arena.intent_button.disabled and state(scene) == committed, tag + " busy intent signals and holds stay closed without touching committed future state.")
	scene.animation_presenter.finish()
	check(commands == ["cast"] and scene.controller.snapshot().enemy_hp == 74, tag + " only the explicit legal Cast issued a command across all inspection and cancellation checks.")
	scene.queue_free()
	await settle()
