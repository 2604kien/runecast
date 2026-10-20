extends Control
## Session owner. This is deliberately not a save format or a profile inventory.
const RunState = preload("res://scripts/core/run_state.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const CombatScene = preload("res://scenes/main.tscn")
const Ui = preload("res://scenes/ui/theme/components.gd")
const AudioOptions = preload("res://scripts/ui/audio_options.gd")
const AudioSettings = preload("res://scripts/audio/audio_settings.gd")
const AudioCoordinator = preload("res://scripts/audio/audio_coordinator.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")

signal screen_changed(screen: String)
var settings_path := AudioSettings.DEFAULT_PATH
var run_state: RunState
var combat_scene: Control
var home: Control
var new_run_button: Button
var continue_button: Button
var options_button: Button
var options: AudioOptions
var confirmation: Control
var confirmation_text: Label
var confirmation_confirm: Button
var confirmation_cancel: Button
var audio: Node
var audio_settings: Dictionary = {}
var startup_error := ""
var _tower: TextureRect
var _logo: TextureRect
var _actions: VBoxContainer
var _session_text: Label
var _session_note: Label
var _confirmation_panel: PanelContainer
var _confirmation_title: Label
var _gestures: Node
var _pending_action := ""
var _pending_seed := -1
var _transitioning := false
var _closed := false
var _generation := 0
var _last_back_frame := -1
var _audio_dispatch := 0
var _battle_changed_callback: Callable
var _battle_home_callback: Callable
var _development := false

func _ready() -> void:
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Existing harnesses deliberately launch Combat. Keep their exact interface,
	# including --capture, and do not route them through run state or Home.
	for argument in OS.get_cmdline_user_args():
		if argument == "--experiment" or argument == "--capture" or argument.begins_with("--encounter=") or argument.begins_with("--board-example="):
			_development = true
	if _development:
		combat_scene = CombatScene.instantiate()
		combat_scene.settings_path = settings_path
		add_child(combat_scene)
		return
	_build_home()
	_build_confirmation()
	options = AudioOptions.new()
	add_child(options)
	options.setting_changed.connect(_change_option)
	options.close_requested.connect(close_options)
	_gestures = TouchRouter.new()
	_gestures.mobile_only = true
	add_child(_gestures)
	for button in [continue_button, new_run_button, options_button, confirmation_confirm, confirmation_cancel]:
		_gestures.register_target(button, button.pressed.emit)
	_gestures.register_scroll(_confirmation_panel.get_meta("rc_body_scroll"))
	options.register_gestures(_gestures)
	_apply_touch_policy(self)
	_load_settings()
	_start_home_audio()
	_refresh_home()
	resized.connect(_fit_home)
	_fit_home()

func _build_home() -> void:
	home = Control.new()
	home.name = "Home"
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tower = TextureRect.new()
	_tower.texture = preload("res://assets/environments/home/home_tower.png")
	_tower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(_tower)
	_tower.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo = TextureRect.new()
	_logo.texture = preload("res://assets/ui/wordmark.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(_logo)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 12)
	home.add_child(_actions)
	_session_text = Ui.label("", "location", 18)
	_session_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_actions.add_child(_session_text)
	continue_button = Ui.action("Continue", true, Vector2(0, 64))
	new_run_button = Ui.action("New Run", false, Vector2(0, 64))
	options_button = Ui.action("Options", false, Vector2(0, 64))
	for button in [continue_button, new_run_button, options_button]: _actions.add_child(button)
	continue_button.pressed.connect(continue_run)
	new_run_button.pressed.connect(request_new_run)
	options_button.pressed.connect(open_options)
	_session_note = Ui.label("Session only · closing the app ends this run.\nMusic is not yet available.", "muted", 14)
	_session_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_actions.add_child(_session_note)

func _build_confirmation() -> void:
	confirmation = Control.new()
	confirmation.name = "Confirmation"
	confirmation.z_index = 120
	confirmation.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirmation)
	confirmation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	confirmation.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmation_panel = Ui.modal("New Run", "", 280, 340, "Replace session")
	confirmation.add_child(_confirmation_panel)
	# Hidden, unlaid-out labels briefly measure at one pixel wide. Refit after
	# wrapping settles so that transient text minima cannot stretch the modal.
	_confirmation_panel.minimum_size_changed.connect(func(): _fit_confirmation.call_deferred())
	_confirmation_title = _confirmation_panel.get_child(0).get_child(0)
	confirmation_text = _confirmation_panel.get_meta("rc_body_scroll").get_child(0)
	confirmation_confirm = _confirmation_panel.get_meta("rc_confirm")
	confirmation_cancel = _confirmation_panel.get_meta("rc_close")
	confirmation_cancel.text = "Cancel"
	confirmation_confirm.pressed.connect(_confirm_pending)
	confirmation_cancel.pressed.connect(cancel_confirmation)
	confirmation.hide()

func _apply_touch_policy(node: Node) -> void:
	if node is Control: node.focus_mode = Control.FOCUS_NONE
	if node is BaseButton: node.shortcut = null
	for child in node.get_children(): _apply_touch_policy(child)

func _fit_home() -> void:
	if home == null: return
	var scale_factor := clampf(size.x / 720.0, 0.55, 1.0)
	var width := minf(440.0, size.x - 48.0)
	_logo.size = Vector2(minf(size.x * 0.85, 612.0), minf(size.x * 0.32, 230.0))
	_logo.position = Vector2((size.x - _logo.size.x) / 2.0, maxf(8.0, size.y * 0.018))
	_actions.add_theme_constant_override("separation", maxi(8, int(14 * scale_factor)))
	for button in [continue_button, new_run_button, options_button]:
		button.custom_minimum_size.y = maxf(50.0, 82.0 * scale_factor)
		button.add_theme_font_size_override("font_size", maxi(20, int(30 * scale_factor)))
	_actions.size.x = width
	_actions.size.y = _actions.get_combined_minimum_size().y
	_actions.position = Vector2((size.x - width) / 2.0, maxf(_logo.position.y + _logo.size.y, size.y - _actions.size.y - maxf(20.0, size.y * 0.035)))
	_fit_confirmation()

func _fit_confirmation() -> void:
	if _closed or _confirmation_panel == null: return
	_confirmation_panel.custom_minimum_size = Vector2(minf(280.0, size.x - 32.0), minf(340.0, size.y - 32.0))
	_confirmation_panel.size = Vector2(minf(560.0, size.x - 32.0), minf(440.0, size.y - 32.0))
	_confirmation_panel.position = (size - _confirmation_panel.size) / 2.0

func _refresh_home() -> void:
	var state := run_state.snapshot() if run_state != null else {}
	var can_continue := not state.is_empty() and bool(state.can_continue)
	Ui.apply_states(continue_button, {"unavailable": not can_continue})
	_session_text.text = "No active session. Begin a new run."
	if not state.is_empty():
		match str(state.status):
			"replay_pending": _session_text.text = "Ashen Crypt · battle-entry replay\n%d / %d health · %d run Gold" % [state.player_hp, state.player_max_hp, state.gold]
			"encounter_won": _session_text.text = "Encounter won · the tower is not complete.\nRoute progression and rewards are not available yet."
			"defeated": _session_text.text = "Run ended in defeat.\nStart a new run to try again."
			_: _session_text.text = "Ashen Crypt · session ready"
	if not startup_error.is_empty(): _session_text.text = startup_error
	_fit_home.call_deferred()

func request_new_run(seed: int = -1) -> void:
	if _closed or _transitioning or combat_scene != null or confirmation.visible or options.visible: return
	_pending_seed = seed
	if run_state != null:
		_show_confirmation("new_run", "Replace this session?", "Starting a New Run replaces this session's run and battle-entry checkpoint. Cancel keeps the current run unchanged.\n\nRuns are session-only and are not restored after closing the application.", "Replace session")
	else:
		_start_new_run()

func confirm_new_run() -> void:
	if _pending_action != "new_run" or not confirmation.visible or _closed or _transitioning: return
	_start_new_run()

func _start_new_run() -> void:
	if _closed or _transitioning or combat_scene != null: return
	_transitioning = true
	var loaded: Dictionary = ContentLoader.load_setup()
	if not loaded.ok:
		startup_error = "Cannot start run.\n" + "\n".join(loaded.errors)
		_transitioning = false
		_dismiss_confirmation()
		_refresh_home()
		return
	var selected_seed := _pending_seed
	if selected_seed < 0:
		var seed_source := RandomNumberGenerator.new()
		seed_source.randomize()
		selected_seed = seed_source.randi_range(0, 2147483647)
	var replacement := RunState.new(loaded.setup, selected_seed)
	var entered: Dictionary = replacement.enter_battle()
	if not entered.ok:
		startup_error = "Cannot start run. " + str(entered.get("error", "Invalid run setup."))
		_transitioning = false
		_dismiss_confirmation()
		_refresh_home()
		return
	# Build the replacement fully before releasing the prior session.
	run_state = replacement
	startup_error = ""
	_dismiss_confirmation()
	_attach_battle(entered.combat)
	_transitioning = false

func continue_run() -> void:
	if _closed or _transitioning or run_state == null or combat_scene != null or confirmation.visible or options.visible: return
	if not run_state.snapshot().can_continue: return
	_transitioning = true
	var entered: Dictionary = run_state.continue_battle()
	if entered.ok:
		_attach_battle(entered.combat)
	else:
		startup_error = "Cannot continue this session. " + str(entered.get("error", ""))
		_refresh_home()
	_transitioning = false

func _attach_battle(model) -> void:
	_generation += 1
	_stop_home_audio()
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	home.hide()
	combat_scene = CombatScene.instantiate()
	combat_scene.battle_model = model
	combat_scene.run_managed = true
	combat_scene.setup_path = ContentLoader.DEFAULT_ENCOUNTER
	combat_scene.settings_path = settings_path
	add_child(combat_scene)
	# Keep application overlays above the injected scene.
	move_child(confirmation, -1)
	move_child(options, -1)
	_battle_changed_callback = _battle_changed.bind(_generation)
	_battle_home_callback = _battle_home_requested.bind(_generation)
	combat_scene.controller.changed.connect(_battle_changed_callback)
	combat_scene.home_requested.connect(_battle_home_callback)
	screen_changed.emit("combat")

func _battle_home_requested(token: int) -> void:
	if token == _generation: request_home()

func _battle_changed(token: int) -> void:
	if _closed or _transitioning or token != _generation or combat_scene == null or combat_scene.controller.is_busy(): return
	var battle_state: Dictionary = combat_scene.controller.snapshot()
	if battle_state.state in ["victory", "defeat"]:
		run_state.resolve_battle(combat_scene.battle_model)

func request_home() -> void:
	if _closed or _transitioning or combat_scene == null or _development or confirmation.visible or combat_scene.controller.is_busy(): return
	_battle_changed(_generation)
	if combat_scene.controller.snapshot().state != "playing":
		if not run_state.snapshot().status in ["encounter_won", "defeated"]:
			combat_scene.dialog.title = "Encounter result unavailable"
			combat_scene.dialog.dialog_text = "This encounter result could not be committed. The current session has been retained."
			combat_scene.dialog.popup_centered(Vector2i(mini(int(size.x) - 32, 560), 240))
			return
		_return_home()
		return
	combat_scene.menu.hide()
	combat_scene.set_shell_modal(true)
	_show_confirmation("home", "Quit to Home?", "Current battle progress will be discarded. Continue replays the original entry with the same health, cards, endpoints and random state.\n\nThis session lasts only while the application stays open.", "Quit to Home")

func confirm_home() -> void:
	if _closed or _transitioning or _pending_action != "home" or not confirmation.visible or combat_scene == null: return
	_transitioning = true
	if run_state.quit_to_home(combat_scene.battle_model):
		_return_home()
	_transitioning = false

func _return_home() -> void:
	var already_transitioning := _transitioning
	_transitioning = true
	_detach_battle()
	_dismiss_confirmation()
	_load_settings()
	home.show()
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	_gestures.set_modal(null)
	_start_home_audio()
	_refresh_home()
	screen_changed.emit("home")
	_transitioning = already_transitioning

func _detach_battle() -> void:
	_generation += 1
	if combat_scene == null: return
	var old_scene := combat_scene
	combat_scene = null
	if old_scene.controller != null and _battle_changed_callback.is_valid() and old_scene.controller.changed.is_connected(_battle_changed_callback):
		old_scene.controller.changed.disconnect(_battle_changed_callback)
	if _battle_home_callback.is_valid() and old_scene.home_requested.is_connected(_battle_home_callback):
		old_scene.home_requested.disconnect(_battle_home_callback)
	old_scene.prepare_for_exit()
	remove_child(old_scene)
	old_scene.queue_free()
	_battle_changed_callback = Callable()
	_battle_home_callback = Callable()

func _show_confirmation(action: String, title: String, body: String, confirm_label: String) -> void:
	_pending_action = action
	_confirmation_title.text = title
	confirmation_text.text = body
	confirmation_confirm.text = confirm_label
	_confirmation_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	confirmation.show()
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(confirmation)
	_fit_home()
	_feedback("ui_confirm")

func _confirm_pending() -> void:
	if _pending_action == "new_run": confirm_new_run()
	elif _pending_action == "home": confirm_home()

func cancel_confirmation() -> void:
	if _closed or _transitioning or not confirmation.visible: return
	_dismiss_confirmation()
	if combat_scene != null:
		combat_scene.set_shell_modal(false)
		_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	_feedback("ui_back")

func _dismiss_confirmation() -> void:
	_pending_action = ""
	_pending_seed = -1
	confirmation.hide()
	_gestures.cancel_pending(true)
	_gestures.set_modal(null)

func open_options() -> void:
	if _closed or _transitioning or combat_scene != null or confirmation.visible or options.visible: return
	options.set_values(audio_settings)
	options.body_scroll.scroll_vertical = 0
	options.show()
	_gestures.set_modal(options)
	_feedback("ui_confirm")

func close_options() -> void:
	if _closed or options == null or not options.visible: return
	options.hide()
	_gestures.set_modal(null)
	_feedback("ui_back")

func _load_settings() -> void:
	audio_settings = AudioSettings.load_values(settings_path)
	if "--reduced-motion" in OS.get_cmdline_user_args(): audio_settings.reduced_motion = true
	options.set_values(audio_settings)

func _change_option(key: String, value: Variant) -> void:
	if _closed or not AudioSettings.DEFAULTS.has(key) or audio_settings.get(key) == value: return
	audio_settings[key] = value
	audio_settings = AudioSettings.normalize(audio_settings)
	options.set_values(audio_settings)
	if audio != null: audio.apply_settings(audio_settings)
	var saved_values := audio_settings.duplicate()
	if key != "reduced_motion": saved_values.reduced_motion = AudioSettings.load_values(settings_path).reduced_motion
	var error := AudioSettings.save_values(saved_values, settings_path)
	if error != OK: push_warning("Options could not be saved: " + error_string(error))
	if not key.ends_with("_volume"): _feedback("ui_confirm")

func _start_home_audio() -> void:
	if audio != null: return
	audio = AudioCoordinator.new()
	home.add_child(audio)
	audio.apply_settings(audio_settings)
	audio.set_context("screen_home", false)

func _stop_home_audio() -> void:
	if audio == null: return
	audio.dispose()
	audio.get_parent().remove_child(audio)
	audio.queue_free()
	audio = null

func _feedback(cue: String) -> void:
	if audio == null or _closed: return
	_audio_dispatch += 1
	audio.ui_feedback(cue, _audio_dispatch, {"screen": "home"})

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready() or _closed or _development: return
	# Combat owns its Back path. Shell handles only its own visible overlays.
	if combat_scene != null and not confirmation.visible: return
	var frame := Engine.get_process_frames()
	if frame == _last_back_frame: return
	_last_back_frame = frame
	if confirmation.visible: cancel_confirmation()
	elif options.visible: close_options()

func _exit_tree() -> void:
	_closed = true
	_generation += 1
	if _gestures != null: _gestures.cancel_pending(true)
	if combat_scene != null: combat_scene.prepare_for_exit()
	if audio != null: audio.dispose()
