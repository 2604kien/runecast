extends RefCounted

const Settings = preload("res://scripts/audio/audio_settings.gd")

# Use the engine's real touch-to-mouse conversion: it emits mouse before touch.
# Call with an otherwise empty root Window; SubViewport.push_input bypasses this.
func run(check: Callable, tree: SceneTree) -> void:
	var old_size := tree.root.size
	var old_embed := tree.root.gui_embed_subwindows
	var old_accumulation := Input.use_accumulated_input
	var old_emulation := Input.emulate_mouse_from_touch
	tree.root.size = Vector2i(720, 1600)
	tree.root.gui_embed_subwindows = true
	Input.use_accumulated_input = false
	Input.emulate_mouse_from_touch = true
	var path := "user://rc021-native-touch-settings.cfg"
	Settings.save_values(Settings.DEFAULTS, path)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = path
	tree.root.add_child(scene)
	for frame in 5: await tree.process_frame
	var before: Dictionary = scene.controller.snapshot()
	scene._open_menu()
	for frame in 3: await tree.process_frame
	_tap(scene.options_button.get_global_rect().get_center() + Vector2(scene.menu.position))
	for frame in 5: await tree.process_frame
	check.call(scene.options.visible and not scene.menu.visible, "Engine-generated touch opens Options through the captured native Menu button.")
	var music: HSlider = scene.options.sliders.music_volume
	var sfx: HSlider = scene.options.sliders.sfx_volume
	var order: Array[String] = []
	music.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed: order.append("mouse")
		if event is InputEventScreenTouch and event.pressed: order.append("touch")
	)
	_tap(music.get_global_rect().get_center())
	check.call(order.size() >= 2 and order[0] == "mouse" and order[1] == "touch", "The first native slider press receives Godot's emulated mouse before its ScreenTouch, without stale suppression.")
	check.call(absf(scene.audio_settings.music_volume - 0.5) < 0.03 and scene.audio_settings.sfx_volume == 1.0, "The first Music touch after captured Menu input changes Music only.")
	var changes := {"enabled": 0}
	scene.options.setting_changed.connect(func(key: String, _value: Variant):
		if key == "enabled": changes.enabled += 1
	)
	_tap(scene.options.toggles.enabled.get_global_rect().get_center())
	check.call(not scene.audio_settings.enabled and changes.enabled == 1, "A captured toggle after native slider input fires exactly once with engine-generated mouse-before-touch events.")
	var music_value: float = scene.audio_settings.music_volume
	_tap(sfx.get_global_rect().get_center())
	check.call(absf(scene.audio_settings.sfx_volume - 0.5) < 0.03 and scene.audio_settings.music_volume == music_value, "The first SFX touch after a captured toggle changes SFX without changing Music.")
	_tap(scene.options.toggles.enabled.get_global_rect().get_center())
	check.call(scene.audio_settings.enabled and changes.enabled == 2, "Returning from a native slider to a captured toggle still produces exactly one activation.")
	check.call(scene.controller.snapshot() == before and Settings.load_values(path) == scene.audio_settings, "Real touch-emulation Options changes persist independently and preserve combat state.")
	scene.audio.dispose()
	await tree.create_timer(0.15).timeout
	scene.queue_free()
	await tree.process_frame
	Input.use_accumulated_input = old_accumulation
	Input.emulate_mouse_from_touch = old_emulation
	tree.root.gui_embed_subwindows = old_embed
	tree.root.size = old_size
	DirAccess.remove_absolute(path)

func _tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
