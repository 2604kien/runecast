extends Control

const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Presentation = preload("res://scripts/ui/combat_presentation.gd")
const Cell = preload("res://scripts/ui/board_cell.gd")
const Arena = preload("res://scripts/ui/arena.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const ExperimentRecord = preload("res://scripts/core/experiment_record.gd")
const InspectionData = preload("res://scripts/ui/inspection_data.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")

# Set before adding the scene to the tree to select a fixture in integration tests.
# An explicit injected path takes precedence over the development command line.
var setup_path := ""
var initial_setup: Dictionary = {}
var _replacing_controller := false
var _closing := false
var startup_error := ""
var controller: Controller
# View-local snapshot and help text; neither is authoritative combat state.
var game: Dictionary = {}
var help_text := ""
var cells: Array = []
var selected_tool := ""
var selected_uid := -1
var selected_cell := -1
var arena: Control
var stats: Label
var encounter_title: Label
var banner: Label
var status: Label
var hand_box: HBoxContainer
var cast_button: Button
var stock_buttons := {}
var edit_buttons: Array = []
var sound_button: Button
var sound_enabled := true
var player: AudioStreamPlayer
var dialog: AcceptDialog
var menu: ConfirmationDialog
var pass_button: Button
var production_replay_button: Button
var production_next_button: Button
var experiment_mode := false
var experiment_scenario := "effects"
var experiment_variant := "control"
var experiment_seed := 42
# Tests explicitly use output/qa; human sessions default to user://experiments.
var experiment_record_path := ""
var experiment_setup: Dictionary = {}
var scenario_select: OptionButton
var variant_select: OptionButton
var seed_input: LineEdit
var experiment_label: Label
var experiment_feedback: Label
var experiment_events: Label
var next_button: Button
var replay_button: Button
var record_dialog: AcceptDialog
var record_text: TextEdit
var note_input: LineEdit
var last_record_path := ""
var record_error := ""
var gestures: Node
var page_scroll: ScrollContainer
var hand_scroll: ScrollContainer
var inspect_mode := false
var inspect_button: Button
var cancel_button: Button
var action_buttons := {}
var inspector: Control
var inspector_title: Label
var inspector_text: Label
var inspector_scroll: ScrollContainer
var inspector_close: Button
var inspector_pass: Button
var inspector_confirm_pass: Button
var inspector_panel: PanelContainer
var guide_text: Label

func _ready() -> void:
	if setup_path == "":
		experiment_mode = experiment_mode or "--experiment" in OS.get_cmdline_user_args()
		experiment_scenario = _argument_value("--scenario=", experiment_scenario)
		experiment_variant = _argument_value("--variant=", experiment_variant)
		var seed_text := _argument_value("--seed=", str(experiment_seed))
		experiment_seed = int(seed_text) if seed_text.is_valid_int() else -1
		setup_path = _argument_value("--encounter=", ContentLoader.DEFAULT_ENCOUNTER)
	var loaded: Dictionary = Experiments.load_setup(experiment_scenario, experiment_variant, experiment_seed) if experiment_mode else ContentLoader.load_setup(setup_path)
	if loaded.ok:
		initial_setup = loaded.setup.duplicate(true)
		var model := Combat.new(loaded.setup)
		if experiment_mode:
			experiment_setup = loaded.setup.duplicate(true)
		controller = Controller.new(model, Presentation.new(), ExperimentRecord.new(loaded.setup, model.snapshot()) if experiment_mode else null)
		if experiment_mode and "--capture" in OS.get_cmdline_user_args():
			# Each automated capture owns its observations; never replace earlier study exports.
			experiment_record_path = "res://output/qa/rc-007/capture-%d-%d-%d/%s-%s.json" % [int(Time.get_unix_time_from_system()), OS.get_process_id(), Time.get_ticks_usec(), experiment_scenario, experiment_variant]
			controller.add_note("AUTOMATED CAPTURE: no human observation")
		game = controller.snapshot()
	else:
		startup_error = "Cannot start encounter.\n" + "\n".join(loaded.errors)
		printerr(startup_error)
	_build_theme()
	_build_ui()
	_load_settings()
	if controller != null:
		controller.changed.connect(_refresh)
		controller.presentation_started.connect(_presentation_started)
		if experiment_mode:
			controller.changed.connect(_save_experiment_record)
			_save_experiment_record()
	_refresh()
	resized.connect(_fit_layout)
	_fit_layout()
	if "--capture" in OS.get_cmdline_user_args():
		if experiment_mode and controller != null:
			var capture_step := _argument_value("--capture-step=", "opening")
			if capture_step == "cast":
				_cast()
			elif capture_step == "inspect":
				_inspect_experiment_record()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var capture_path := _argument_value("--capture-path=", "res://output/qa/foundation-screen.png")
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		var error := get_viewport().get_texture().get_image().save_png(capture_path)
		print("Screenshot saved: ", error_string(error))
		get_tree().quit(0 if error == OK and startup_error == "" else 1)

func _argument_value(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback

func _can_edit() -> bool:
	return not _closing and not _replacing_controller and controller != null and controller.can_edit() and (inspector == null or not inspector.visible)

func _exit_tree() -> void:
	_closing = true
	if gestures != null:
		gestures.cancel_pending()
	if controller != null:
		if experiment_mode:
			_save_experiment_record()
		controller.dispose()

func _presentation_started(result: Dictionary) -> void:
	if result.command == "cast" and sound_enabled:
		player.play()

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", Color("#eee0bf"))
	for button_state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#17273b") if button_state != "pressed" else Color("#326071")
		style.border_color = Color("#96784d") if button_state != "focus" else Color("#f7d28a")
		style.set_border_width_all(2)
		style.set_corner_radius_all(7)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		theme.set_stylebox(button_state, "Button", style)
	theme.set_color("font_color", "Button", Color("#eee0bf"))
	theme.set_color("font_disabled_color", "Button", Color("#7a879a"))

func _label(value: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _button(value: String, action: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(66, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	if gestures != null:
		gestures.register_target(button, action)
	return button

func _build_ui() -> void:
	gestures = TouchRouter.new()
	add_child(gestures)
	var background := ColorRect.new()
	background.color = Color("#0c1525")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	page_scroll = scroll
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	gestures.register_scroll(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	encounter_title = _label("", 28)
	encounter_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(encounter_title)
	if experiment_mode:
		_build_experiment_controls(column)
	arena = Control.new()
	arena.set_script(Arena)
	arena.compact = experiment_mode
	arena.custom_minimum_size.y = 90 if experiment_mode else 310
	column.add_child(arena)
	stats = _label("")
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	banner = _label("", 22)
	column.add_child(banner)
	var center := CenterContainer.new()
	column.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	center.add_child(grid)
	for index in range(16):
		var cell := Button.new()
		cell.set_script(Cell)
		cell.custom_minimum_size = Vector2(137, 137)
		cell.catalog = game.get("catalog", {})
		cell.pressed.connect(_cell_pressed.bind(index))
		grid.add_child(cell)
		gestures.register_target(cell, _cell_pressed.bind(index), _inspect_cell.bind(index))
		cells.append(cell)
	var wiring := HBoxContainer.new()
	column.add_child(wiring)
	for kind in ["straight", "corner", "split", "join"]:
		var button := _button(kind.capitalize(), _select_tool.bind(kind), wiring)
		button.add_theme_font_size_override("font_size", 15)
		stock_buttons[kind] = button
		button.toggle_mode = true
		gestures.register_target(button, _select_tool.bind(kind), _inspect_tool.bind(kind))
		edit_buttons.append(button)
	var editing := HBoxContainer.new()
	column.add_child(editing)
	for entry in [["Rotate", _rotate], ["Flip", _flip], ["Undo", _undo], ["Erase", _select_tool.bind("erase")]]:
		var button := _button(entry[0], entry[1], editing)
		button.add_theme_font_size_override("font_size", 15)
		button.custom_minimum_size.y = 58
		action_buttons[str(entry[0]).to_lower()] = button
		if entry[0] == "Erase": button.toggle_mode = true
		edit_buttons.append(button)
	var inspection_actions := HBoxContainer.new()
	column.add_child(inspection_actions)
	inspect_button = _button("Inspect", _toggle_inspect_mode, inspection_actions)
	inspect_button.toggle_mode = true
	cancel_button = _button("Cancel selection", _cancel_selection, inspection_actions)
	_button("Details / Pass", _show_details, inspection_actions)
	for button in inspection_actions.get_children():
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hand_hint := _label("RUNES / tap to use · hold to inspect · drag to scroll", 17)
	hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hand_hint)
	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = 104
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(hand_scroll)
	gestures.register_scroll(hand_scroll)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 8)
	hand_scroll.add_child(hand_box)
	status = _label("", 17)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 46
	column.add_child(status)
	cast_button = _button("CAST", _cast, column)
	cast_button.custom_minimum_size.y = 64
	cast_button.add_theme_font_size_override("font_size", 28)
	column.add_child(_label("Cast ends turn", 16))
	var navigation := HBoxContainer.new()
	column.add_child(navigation)
	_button("Menu", _open_menu, navigation)
	_button("Map", _show_map, navigation)
	_button("Guide", _show_guide, navigation)
	sound_button = _button("Sound: On", _toggle_sound, navigation)
	for button in navigation.get_children():
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog = AcceptDialog.new()
	dialog.min_size = Vector2i(550, 360)
	dialog.dialog_autowrap = true
	add_child(dialog)
	# Keep native help dialogs bounded: their text scrolls instead of increasing
	# the Window's minimum height as help grows.
	dialog.get_label().hide()
	dialog.get_label().max_lines_visible = 0
	var guide_scroll := ScrollContainer.new()
	guide_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guide_scroll.custom_minimum_size = Vector2(260, 240)
	dialog.add_child(guide_scroll)
	guide_text = _label("", 20)
	guide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_scroll.add_child(guide_text)
	var guide_gestures := TouchRouter.new()
	dialog.add_child(guide_gestures)
	guide_gestures.register_scroll(guide_scroll)
	dialog.about_to_popup.connect(func():
		guide_text.text = dialog.dialog_text
		guide_scroll.scroll_vertical = 0
	)
	menu = ConfirmationDialog.new()
	menu.title = "Rune Cast"
	menu.ok_button_text = "Restart"
	menu.cancel_button_text = "Resume"
	pass_button = menu.add_button("Pass turn", false, "pass")
	production_replay_button = menu.add_button("Exact replay", false, "exact_replay")
	production_next_button = menu.add_button("Next encounter", false, "next_encounter")
	production_replay_button.hide()
	production_next_button.hide()
	menu.confirmed.connect(_restart)
	menu.custom_action.connect(func(action):
		if action == "pass":
			_pass()
			menu.hide()
		elif action == "exact_replay":
			_exact_replay()
			menu.hide()
		elif action == "next_encounter":
			_next_production_encounter()
			menu.hide()
	)
	add_child(menu)
	for popup in [dialog, menu]:
		popup.about_to_popup.connect(func(): gestures.set_suspended(true))
		popup.visibility_changed.connect(func():
			_sync_native_modal()
		)
	_build_inspector()
	player = AudioStreamPlayer.new()
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	for i in range(2205):
		samples.append(int(128 + sin(float(i) / 22050.0 * TAU * 440.0) * 20 * (1.0 - float(i) / 2205.0)))
	sound.data = samples
	player.stream = sound
	player.volume_db = -12
	add_child(player)
	if experiment_mode:
		_build_record_dialog()
		record_dialog.about_to_popup.connect(func(): gestures.set_suspended(true))
		record_dialog.visibility_changed.connect(_sync_native_modal)

func _sync_native_modal() -> void:
	gestures.set_suspended(dialog.visible or menu.visible or (record_dialog != null and record_dialog.visible))

func _fit_layout() -> void:
	if cells.is_empty(): return
	var width := get_viewport_rect().size.x
	cancel_button.text = "Cancel" if width < 500 else "Cancel selection"
	var side := minf(137, floorf((width - 70) / 4.0))
	for cell in cells:
		cell.custom_minimum_size = Vector2(side, side)
	dialog.min_size = Vector2i(mini(550, int(width) - 32), 300)

func _refresh() -> void:
	gestures.cancel_pending()
	sound_button.text = "Sound: On" if sound_enabled else "Sound: Off"
	if controller == null:
		_refresh_startup_error()
		return
	var previous := game
	game = controller.snapshot()
	if previous != game or controller.is_busy():
		_close_inspector()
		help_text = ""
		if previous.get("turn") != game.turn or previous.get("encounter_id") != game.encounter_id or previous.get("state") != game.state or controller.is_busy():
			_clear_selection()
		if selected_uid != -1 and InspectionData.describe_hand(game, selected_uid).is_empty():
			selected_uid = -1
	if experiment_mode:
		_refresh_experiment()
	var spell: Dictionary = game.forecast
	# Modal routing blocks background input without leaving controls visually
	# disabled after a same-state refresh and dismissal.
	var editable := not _closing and not _replacing_controller and controller.can_edit()
	encounter_title.text = "RUNE CAST   /   " + game.encounter.title.to_upper()
	encounter_title.tooltip_text = game.encounter.help_text
	arena.enemy_name = game.enemy_name
	arena.enemy_hp = game.enemy_hp
	arena.enemy_max_hp = game.enemy_max_hp
	arena.attack = game.intent
	arena.battle_state = game.state
	arena.tooltip_text = "%s: %d / %d health. Incoming attack: %d." % [game.enemy_name, game.enemy_hp, game.enemy_max_hp, game.intent]
	arena.queue_redraw()
	stats.text = "HEALTH %d / %d       ENERGY %d / %d       TURN %d" % [game.player_hp, game.player_max_hp, game.energy, game.energy_per_turn, game.turn]
	stats.tooltip_text = "Refreshes to %d energy and draws %d cards each turn." % [game.energy_per_turn, game.draw_per_turn]
	menu.dialog_text = "Restart %s?\nInstalled effects persist between turns.\nPass turn is available when you cannot cast." % game.encounter.title
	production_replay_button.visible = game.has("production")
	production_next_button.visible = game.has("production") and initial_setup.has("next_encounter")
	production_next_button.disabled = not game.get("can_advance", false) or controller.is_busy()
	if game.has("production"):
		menu.dialog_text = "Cast or Pass clears every non-endpoint piece.\nRestart deals a fresh opening with continuing randomness.\nExact replay restores the original seed and opening."
		stats.tooltip_text += "\nHand %d; draw pile %d; discard %d. %s." % [game.hand.size(), game.draw_pile.size(), game.discard_pile.size(), _kit_description()]
	if experiment_mode:
		menu.dialog_text = "Restart this experiment with continuing RNG.\nUse Exact replay above the board to restore the original seed.\n" + game.encounter.help_text
	banner.text = game.state.to_upper() if game.state != "playing" else ("CIRCUIT COMPLETE" if spell.valid else "CONNECT BEGIN TO END")
	banner.modulate = Color("#7addba") if spell.valid else Color("#edb26b")
	banner.tooltip_text = spell.message
	for index in range(cells.size()):
		var cell: Button = cells[index]
		cell.piece = game.board[index]
		cell.catalog = game.catalog
		cell.split_cost = int(_rule_options().get("split_cost", 1))
		cell.disabled = not editable or (experiment_mode and cell.piece.get("kind") == "blocked")
		cell.active = spell.active.has(index)
		cell.chosen = index == selected_cell
		cell.preview = 0
		if not inspect_mode and (selected_tool != "" or selected_uid != -1):
			cell.preview = 1 if InspectionData.placement(game, index, selected_tool, selected_uid).allowed else -1
		cell.end_value = int(spell.damage) if spell.valid else 0
		cell.tooltip_text = "Row %d, column %d" % [index / 4 + 1, index % 4 + 1]
		if _rule_options().get("endpoint_rotation") == "player" and cell.piece.get("kind") in ["begin", "end"]:
			cell.tooltip_text += ". Select, then Rotate to change direction."
		cell.queue_redraw()
	for kind in stock_buttons:
		var finite: bool = game.stock_totals.has(kind)
		stock_buttons[kind].text = kind.capitalize() + ("\n%d / %d" % [game.stock[kind], game.stock_totals[kind]] if finite else "\nUnlimited")
		stock_buttons[kind].tooltip_text = "%d available, %d owned (%d installed)." % [game.stock[kind], game.stock_totals[kind], game.stock_totals[kind] - game.stock[kind]] if finite else "Unlimited supply"
		stock_buttons[kind].set_pressed_no_signal(selected_tool == kind)
		stock_buttons[kind].modulate = Color("#b5bdc9") if finite and game.stock[kind] == 0 else Color.WHITE
	for button in edit_buttons:
		button.disabled = not editable
	for action in ["rotate", "flip", "undo"]:
		var availability: Dictionary = InspectionData.edit_action(game, selected_cell, action)
		action_buttons[action].disabled = not editable or not availability.allowed
		action_buttons[action].tooltip_text = availability.reason
	action_buttons.erase.set_pressed_no_signal(selected_tool == "erase")
	inspect_button.set_pressed_no_signal(inspect_mode)
	inspect_button.text = "Inspect: ON" if inspect_mode else "Inspect"
	inspect_button.disabled = not editable
	cancel_button.disabled = not editable or (selected_tool == "" and selected_uid == -1 and selected_cell == -1 and not inspect_mode)
	for child in hand_box.get_children():
		hand_box.remove_child(child)
		child.queue_free()
	for card in game.hand:
		var rune: Dictionary = game.catalog[card.id]
		var button := _button("%s\n%s\n%d" % [rune.name, rune.symbol, rune.value], _select_card.bind(card.uid), hand_box)
		button.custom_minimum_size = Vector2(142, 92)
		button.toggle_mode = true
		button.set_pressed_no_signal(card.uid == selected_uid)
		button.set_meta("uid", int(card.uid))
		gestures.register_target(button, _select_card.bind(card.uid), _inspect_hand.bind(card.uid))
		button.modulate = Color(rune.color)
		button.disabled = not editable
		button.tooltip_text = _rune_description(rune) + " | %d energy%s" % [rune.cost, " | Temporary" if rune.get("temporary", false) else ""]
	cast_button.text = "CAST    %d energy" % spell.cost if spell.valid else "CAST"
	cast_button.disabled = not spell.valid or spell.cost > game.energy or not editable
	var incoming: int = 0 if spell.damage >= game.enemy_hp else maxi(0, game.intent - spell.shield)
	cast_button.tooltip_text = "%d damage, %d shield. Incoming %d." % [spell.damage, spell.shield, incoming] if spell.valid else spell.message
	status.text = help_text if help_text != "" else game.log_text
	if game.has("production"):
		status.text += "\n%s. Hand %d / draw %d / discard %d." % [_kit_description(), game.hand.size(), game.draw_pile.size(), game.discard_pile.size()]
	if spell.valid and spell.cost > game.energy and game.state == "playing":
		if help_text == "": status.text = "Need %d energy; %d available. Edit the circuit or open Details / Pass." % [spell.cost, game.energy]
	if help_text == "" and not spell.valid and game.state == "playing":
		status.text = spell.message + "\nKeep building, or open Details / Pass."
		if game.has("production"): status.text += "\n%s. Hand %d / draw %d / discard %d." % [_kit_description(), game.hand.size(), game.draw_pile.size(), game.discard_pile.size()]
	pass_button.disabled = not editable

func _rule_options() -> Dictionary:
	return game.get("production", game.get("experiment", {}))

func _build_inspector() -> void:
	inspector = Control.new()
	inspector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspector.mouse_filter = Control.MOUSE_FILTER_STOP
	inspector.z_index = 100
	add_child(inspector)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspector.add_child(shade)
	inspector_panel = PanelContainer.new()
	inspector_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspector_panel.anchor_left = 0.04
	inspector_panel.anchor_right = 0.96
	inspector_panel.anchor_top = 0.12
	inspector_panel.anchor_bottom = 0.88
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#142535")
	frame.border_color = Color("#cfad69")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(12)
	for side in ["left", "right", "top", "bottom"]:
		frame.set("content_margin_" + side, 18)
	inspector_panel.add_theme_stylebox_override("panel", frame)
	inspector.add_child(inspector_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	inspector_panel.add_child(column)
	inspector_title = _label("Inspection", 28)
	inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inspector_title)
	inspector_scroll = ScrollContainer.new()
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(inspector_scroll)
	gestures.register_scroll(inspector_scroll)
	inspector_text = _label("", 23)
	inspector_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	inspector_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.add_child(inspector_text)
	inspector_pass = _button("Pass turn…", _confirm_pass_details, column)
	inspector_confirm_pass = _button("Confirm Pass / enemy acts", _accept_pass_details, column)
	inspector_close = _button("Close", _close_inspector, column)
	for button in [inspector_pass, inspector_confirm_pass, inspector_close]:
		button.custom_minimum_size.y = 64
	inspector.hide()

func _open_inspector(detail: Dictionary) -> void:
	if detail.is_empty() or not _can_edit(): return
	gestures.cancel_pending()
	inspector_title.text = detail.title
	inspector_text.text = detail.text
	inspector_scroll.scroll_vertical = 0
	inspector_pass.hide()
	inspector_confirm_pass.hide()
	inspector.show()
	gestures.set_modal(inspector)
	inspector_close.grab_focus()

func _close_inspector() -> void:
	if inspector == null or not inspector.visible: return
	inspector.hide()
	gestures.set_modal(null)
	inspector_close.release_focus()

func _inspect_hand(uid: int) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_hand(controller.snapshot(), uid))

func _inspect_cell(index: int) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_cell(controller.snapshot(), index))

func _inspect_tool(kind: String) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_tool(controller.snapshot(), kind))

func _toggle_inspect_mode() -> void:
	if not _can_edit(): return
	var enabled := not inspect_mode
	_clear_selection()
	inspect_mode = enabled
	help_text = "Inspect ON: tap a card, piece or connector for details. Nothing will be played or placed." if enabled else "Inspect off. Tap to use; hold to inspect."
	_refresh()

func _cancel_selection() -> void:
	if not _can_edit(): return
	_clear_selection()
	help_text = "Selection cleared. Tap to use; hold to inspect."
	_refresh()

func _endpoint_direction(index: int) -> String:
	var piece: Dictionary = game.board[index]
	var ports: Dictionary = preload("res://scripts/core/circuit.gd").ports(piece)
	var direction: int = ports.output[0] if piece.kind == "begin" else ports.input[0]
	return "%s %s %s." % [str(piece.kind).capitalize(), "points" if piece.kind == "begin" else "receives from", ["up", "right", "down", "left"][direction]]

func _show_details() -> void:
	if not _can_edit(): return
	var spell: Dictionary = game.forecast
	var incoming: int = 0 if spell.valid and spell.damage >= game.enemy_hp else maxi(0, int(game.intent) - int(spell.shield)) if spell.valid else int(game.intent)
	var text := "%s\n\nEnergy: %d available. Cast cost: %d.\nSpell: %d damage, %d shield. Incoming after Cast: %d.\n\nPass is available even with an incomplete circuit or an empty hand. Pass uses no spell or shield; the enemy attacks for %d." % [spell.message, game.energy, spell.cost, spell.damage, spell.shield, incoming, game.intent]
	if game.has("production"):
		text += "\n\nCast / Pass discards all permanent hand and installed runes, deletes temporaries and clears connectors. The next playable turn draws normally and gets new endpoints and a fresh kit."
	if not spell.valid:
		text += "\n\nThis circuit cannot Cast yet. Legal construction steps remain allowed."
	if selected_cell >= 0:
		for action in ["rotate", "flip", "erase", "undo"]:
			var availability: Dictionary = InspectionData.edit_action(game, selected_cell, action)
			text += "\n%s: %s" % [action.capitalize(), availability.reason]
	_open_inspector({"title": "Circuit details", "text": text})
	inspector_pass.show()

func _confirm_pass_details() -> void:
	if controller == null or not controller.can_edit() or not inspector.visible: return
	inspector_title.text = "Pass this turn?"
	inspector_text.text = "The enemy attacks for %d damage. No spell or shield is used.\n\n%s" % [game.intent, "All non-endpoint pieces clear, permanent runes discard and temporaries expire. A surviving player gets a new turn, hand and kit." if game.has("production") else "Normal turn cleanup and the active profile's board rules apply."]
	inspector_pass.hide()
	inspector_confirm_pass.show()
	inspector_scroll.scroll_vertical = 0
	gestures.cancel_pending()

func _accept_pass_details() -> void:
	if controller == null or not controller.can_edit() or not inspector.visible or not inspector_confirm_pass.visible: return
	_close_inspector()
	_pass()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if inspector != null and inspector.visible:
			_close_inspector()
		else:
			_cancel_selection()
		get_viewport().set_input_as_handled()

func _kit_description() -> String:
	var kit: Dictionary = game.get("kit", {})
	return "Kit: " + str(kit.get("id", "")).replace("_", " ").capitalize()

func _rune_description(rune: Dictionary) -> String:
	match rune.effect:
		"damage": return "Adds %d damage" % rune.value
		"shield": return "Adds %d shield" % rune.value
		"draw": return "Draw up to %d cards" % rune.value
		"conjure": return "Create %d temporary %s" % [rune.value, game.catalog[rune.generated_rune_id].name]
	return ""

func _refresh_startup_error() -> void:
	_close_inspector()
	_clear_selection()
	inspect_button.disabled = true
	cancel_button.disabled = true
	if experiment_mode:
		experiment_label.text = "%s / %s | seed %d | unavailable" % [experiment_scenario, experiment_variant, experiment_seed]
		next_button.disabled = true
		replay_button.disabled = true
	encounter_title.text = "RUNE CAST   /   CONTENT ERROR"
	encounter_title.tooltip_text = setup_path
	arena.enemy_name = "ENCOUNTER UNAVAILABLE"
	arena.enemy_hp = 0
	arena.enemy_max_hp = 1
	arena.battle_state = "configuration error"
	arena.tooltip_text = startup_error
	arena.queue_redraw()
	stats.text = "Battle setup unavailable"
	banner.text = "CHECK CONTENT CONFIGURATION"
	banner.modulate = Color("#edb26b")
	banner.tooltip_text = startup_error
	status.text = startup_error
	status.tooltip_text = startup_error
	for cell in cells:
		cell.disabled = true
	for button in edit_buttons:
		button.disabled = true
	cast_button.disabled = true
	cast_button.tooltip_text = startup_error
	pass_button.disabled = true
	production_replay_button.hide()
	production_next_button.hide()
	menu.get_ok_button().disabled = true
	menu.dialog_text = startup_error

func _clear_selection() -> void:
	selected_tool = ""
	selected_uid = -1
	selected_cell = -1
	help_text = ""
	inspect_mode = false
	if gestures != null: gestures.cancel_pending()
	_close_inspector()

func _select_tool(kind: String) -> void:
	if not _can_edit():
		return
	if inspect_mode:
		_inspect_tool(kind)
		return
	selected_tool = kind
	selected_uid = -1
	selected_cell = -1
	help_text = "Tap a socket to place %s. Then Rotate or Flip if needed." % kind
	if game.stock_totals.has(kind) and int(game.stock[kind]) == 0:
		help_text = "No %s available. Erase one to refund it, or replace the same kind." % kind
	elif kind == "erase":
		help_text = "Erase selected. Tap an eligible piece to return it; endpoints are protected."
	_refresh()

func _select_card(uid: int) -> void:
	if not _can_edit():
		return
	if inspect_mode:
		_inspect_hand(uid)
		return
	for card in game.hand:
		if card.uid != uid:
			continue
		if game.catalog[card.id].type == "technique":
			var availability: Dictionary = InspectionData.technique_action(controller.snapshot(), uid)
			if not availability.allowed:
				help_text = availability.reason
				_refresh()
				return
			_clear_selection()
			if not controller.command("technique", {"uid": uid}): help_text = controller.snapshot().log_text
		else:
			selected_uid = uid
			selected_tool = ""
			selected_cell = -1
			help_text = "Tap a socket to install %s. Cost is paid when casting." % game.catalog[card.id].name
		break
	_refresh()

func _cell_pressed(index: int) -> void:
	if not _can_edit():
		return
	if inspect_mode:
		_inspect_cell(index)
		return
	if index < 0 or index >= game.board.size(): return
	selected_cell = index
	help_text = ""
	if _rule_options().get("endpoint_rotation") == "player" and game.board[index].get("kind") in ["begin", "end"]:
		selected_tool = ""
		selected_uid = -1
		help_text = "%s selected; protected from replacement/erase. Use Rotate to change its direction." % str(game.board[index].kind).capitalize()
		if game.has("production"):
			help_text += " " + _endpoint_direction(index)
		_refresh()
		return
	if selected_uid != -1 or selected_tool != "":
		var preview: Dictionary = InspectionData.placement(game, index, selected_tool, selected_uid)
		if not preview.allowed:
			help_text = preview.reason
			_refresh()
			return
	if selected_uid != -1:
		if controller.command("place_rune", {"index": index, "uid": selected_uid}):
			selected_uid = -1
		else:
			help_text = ""
	elif selected_tool != "":
		if not controller.command("place_wire", {"index": index, "kind": selected_tool}):
			help_text = ""
	else:
		var detail: Dictionary = InspectionData.describe_cell(game, index)
		help_text = str(detail.get("title", "Socket")) + " selected. Hold to inspect."
		var reason: Dictionary = InspectionData.edit_action(game, index, "rotate")
		if not reason.allowed: help_text += " " + str(reason.reason)
	_refresh()

func _rotate() -> void:
	if not _can_edit():
		return
	var availability: Dictionary = InspectionData.edit_action(game, selected_cell, "rotate")
	if not availability.allowed:
		help_text = availability.reason
		_refresh()
		return
	if selected_cell >= 0:
		if controller.command("rotate", {"index": selected_cell}) and game.board[selected_cell].get("kind") in ["begin", "end"]:
			help_text = _endpoint_direction(selected_cell) + " Use Rotate to turn clockwise; Undo restores the previous direction."
	_refresh()

func _flip() -> void:
	if not _can_edit():
		return
	var availability: Dictionary = InspectionData.edit_action(game, selected_cell, "flip")
	if not availability.allowed:
		help_text = availability.reason
		_refresh()
		return
	if selected_cell >= 0:
		controller.command("flip", {"index": selected_cell})
	_refresh()

func _undo() -> void:
	if not _can_edit():
		return
	_clear_selection()
	controller.command("undo")

func _cast() -> void:
	if not _can_edit():
		return
	_clear_selection()
	controller.command("cast")

func _pass() -> void:
	if not _can_edit():
		return
	_clear_selection()
	controller.command("pass")

func _restart() -> void:
	if controller == null or _replacing_controller or _closing:
		return
	_clear_selection()
	controller.restart()

func _exact_replay() -> void:
	if controller == null or _replacing_controller or _closing or not game.has("production"):
		return
	_replacing_controller = true
	controller.dispose()
	if not is_inside_tree():
		_replacing_controller = false
		return
	controller = Controller.new(Combat.new(initial_setup), Presentation.new())
	controller.changed.connect(_refresh)
	controller.presentation_started.connect(_presentation_started)
	_replacing_controller = false
	_clear_selection()
	_refresh()

func _next_production_encounter() -> void:
	if controller == null or _replacing_controller or _closing or not game.has("production"):
		return
	_clear_selection()
	controller.command("next_encounter")

func _open_menu() -> void:
	menu.popup_centered(Vector2i(660, 250) if game.has("production") else Vector2i(540, 220))

func _show_map() -> void:
	dialog.title = "Tower map"
	dialog.dialog_text = startup_error if controller == null else "%s\n%s\n\nOne encounter at a time is available in this prototype.\n\n%s\n\nPlanned route: encounters, events, shops, recovery rooms and a final guardian. Branching routes and encounter saves are not implemented." % [game.encounter.title, game.enemy_name, game.encounter.help_text]
	dialog.popup_centered(Vector2i(mini(550, int(size.x) - 32), mini(360, int(size.y) - 32)))

func _show_guide() -> void:
	dialog.title = "Circuit guide"
	var context: String = startup_error if controller == null else game.encounter.help_text
	dialog.dialog_text = context + "\n\nConnect Begin to End. Every powered branch must finish; loops and half-connected joins are invalid.\n\nTap a wiring tool or rune, then a socket. Tap an installed piece to select it, then Rotate. Flip reverses a wire's direction. Erase returns installed runes to your hand. Undo reverses edits until a technique is played.\n\nSplit copies the incoming spell and costs 1 energy. Join combines its branches. Regular effect runes pay once per cast and remain installed. Temporary runes expire into straight wires.\n\nTechniques resolve immediately when tapped. On desktop, hover for costs and details. Cast ends your turn; surviving enemies attack. Menu includes Pass turn and Restart."
	if game.has("production"):
		dialog.dialog_text = context + "\n\nEvery playable turn starts with only Begin and End. Click Begin or End, then Rotate to change its direction. Undo restores edits. Endpoints may be adjacent and may initially face outward; they cannot be replaced, erased, flipped or dragged.\n\nConnect Begin to End. Every powered branch must finish; loops and half-connected Joins are invalid. Effect runes have straight ports. Split copies output and costs 1 energy per powered piece; Join costs 0. Each physical rune pays once. Cast deals one total damage hit, then shields against a surviving enemy's retaliation.\n\nCast or Pass clears every non-endpoint piece, including disconnected pieces. Permanent runes go to discard; all temporary runes disappear. Unplayed permanent cards also go to discard. The next turn moves both endpoints, replaces the ten-piece kit, refreshes energy and draws normally; repeats are allowed. A finished battle does not draw another hand or kit.\n\nTap a rune to install it; techniques resolve immediately. Menu offers Pass, Restart with continuing randomness, and Exact replay of the original seed. Kit balance is provisional."
	if experiment_mode:
		var endpoint_help := "Protected endpoints and blocked cells cannot be edited."
		if game.get("experiment", {}).get("endpoint_rotation") == "player":
			endpoint_help = "Click Begin or End, then Rotate to change its direction. Endpoints cannot be replaced, erased or flipped."
		dialog.dialog_text = context + "\n\nPROVISIONAL EXPERIMENT RULES\n" + (experiment_label.text if experiment_label != null else startup_error) + "\n\nTap a tool/card then a cell; Rotate/Flip change orientation. Undo restores edits until a technique commits them. Cast and Menu > Pass end the turn. " + endpoint_help + " Exact replay restores the selected starting setup and seed; Menu Restart continues RNG. Inspect / export shows local command observations. See docs/circuit-experiments.md for solutions and the paired protocol."
	if controller != null and game.stock_totals.has("straight") and game.stock_totals.has("corner"):
		dialog.dialog_text += "\n\nStraight, Corner, Split and Join show available / total quantities. Every installed connector reserves one piece, including disconnected pieces. Erase or replacement returns the displaced connector; installing a rune over a connector returns it too. Rotate and Flip preserve quantities. Undo restores the board, hand and connector supply together."
	dialog.dialog_text = dialog.dialog_text.replace("On desktop, hover for costs and details.", "Hold any card or piece to inspect costs and details.")
	dialog.dialog_text += "\n\nTOUCH CONTROLS\nTap effects/tools, then an eligible + socket. A legal unfinished circuit is allowed; x sockets explain protected or unavailable targets. Tap an installed piece, then Rotate; Flip supports straight/corner wires only. Rotate/Flip/Undo show actual availability. Cancel selection clears the active card, tool and Inspect mode.\n\nHold a card, piece or stock button for details without using it. Or switch Inspect ON, then tap any item safely, including techniques. Close returns to the board; Inspect stays ON until switched off or cancelled. Normal short taps still play techniques immediately. Drag horizontally over the hand or vertically over the page to scroll; movement cancels tap and hold. Details / Pass explains the circuit and offers a confirmed Pass even when Cast is unavailable."
	dialog.popup_centered(Vector2i(mini(620, int(size.x) - 32), mini(620, int(size.y) - 32)))

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	if not sound_enabled:
		player.stop()
	var config := ConfigFile.new()
	config.set_value("audio", "enabled", sound_enabled)
	config.save("user://settings.cfg")
	_refresh()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		sound_enabled = bool(config.get_value("audio", "enabled", true))

func _build_experiment_controls(column: VBoxContainer) -> void:
	column.add_child(_label("EXPERIMENT LAB / testing only", 19))
	var choices := HBoxContainer.new()
	column.add_child(choices)
	scenario_select = OptionButton.new()
	scenario_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in Experiments.list_scenarios():
		scenario_select.add_item(entry.title)
		scenario_select.set_item_metadata(scenario_select.item_count - 1, entry.id)
		if entry.id == experiment_scenario:
			scenario_select.select(scenario_select.item_count - 1)
	choices.add_child(scenario_select)
	variant_select = OptionButton.new()
	choices.add_child(variant_select)
	seed_input = LineEdit.new()
	seed_input.text = str(experiment_seed)
	seed_input.placeholder_text = "Seed"
	seed_input.tooltip_text = "Integer seed, 0 to 2147483647"
	seed_input.custom_minimum_size.x = 100
	choices.add_child(seed_input)
	scenario_select.item_selected.connect(_experiment_scenario_selected)
	_experiment_scenario_selected(scenario_select.selected)
	for index in range(variant_select.item_count):
		if variant_select.get_item_text(index) == experiment_variant:
			variant_select.select(index)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_button("Launch", _launch_selected_experiment, actions)
	replay_button = _button("Exact replay", _replay_experiment, actions)
	next_button = _button("Next encounter", _next_experiment_encounter, actions)
	_button("Inspect / export", _inspect_experiment_record, actions)
	for button in actions.get_children():
		button.add_theme_font_size_override("font_size", 16)
	experiment_label = _label("", 16)
	experiment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(experiment_label)
	experiment_events = _label("", 15)
	experiment_events.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(experiment_events)
	experiment_feedback = _label("", 14)
	experiment_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(experiment_feedback)

func _experiment_scenario_selected(index: int) -> void:
	variant_select.clear()
	var id: String = scenario_select.get_item_metadata(index)
	for entry in Experiments.list_scenarios():
		if entry.id == id:
			for variant in entry.variants:
				variant_select.add_item(variant)

func _launch_selected_experiment() -> void:
	if _closing or _replacing_controller: return
	var seed_text := seed_input.text.strip_edges()
	var chosen_seed := int(seed_text) if seed_text.is_valid_int() else -1
	_launch_experiment(str(scenario_select.get_selected_metadata()), variant_select.get_item_text(variant_select.selected), chosen_seed)

func _launch_experiment(scenario: String, variant: String, seed_value: int, cached_setup: Dictionary = {}) -> bool:
	if _closing or _replacing_controller: return false
	var loaded: Dictionary = Experiments.load_setup(scenario, variant, seed_value) if cached_setup.is_empty() else {"ok": true, "setup": cached_setup.duplicate(true)}
	if not loaded.ok:
		experiment_feedback.text = "Launch rejected: " + " / ".join(loaded.errors)
		return false
	# Preserve a session if its local record cannot be saved; gameplay can continue.
	if controller != null:
		_save_experiment_record()
		if record_error != "":
			experiment_feedback.text = "Session kept. " + record_error
			return false
	_replacing_controller = true
	gestures.cancel_pending()
	_close_inspector()
	if controller != null:
		controller.dispose()
	if _closing or not is_inside_tree():
		_replacing_controller = false
		return false
	experiment_scenario = scenario
	experiment_variant = variant
	experiment_seed = seed_value
	experiment_setup = loaded.setup.duplicate(true)
	startup_error = ""
	var model := Combat.new(experiment_setup)
	controller = Controller.new(model, Presentation.new(), ExperimentRecord.new(experiment_setup, model.snapshot()))
	controller.changed.connect(_refresh)
	controller.changed.connect(_save_experiment_record)
	controller.presentation_started.connect(_presentation_started)
	_replacing_controller = false
	_clear_selection()
	menu.get_ok_button().disabled = false
	_refresh()
	_save_experiment_record()
	return true

func _replay_experiment() -> void:
	_launch_experiment(experiment_scenario, experiment_variant, experiment_seed, experiment_setup)

func _next_experiment_encounter() -> void:
	if controller != null:
		_clear_selection()
		controller.command("next_encounter")

func _refresh_experiment() -> void:
	var options: Dictionary = game.get("experiment", {})
	experiment_label.text = "%s / %s | seed %d | encounter %d/ %d\n%s" % [experiment_scenario, experiment_variant, experiment_seed, game.get("encounter_number", 1), 2 if options.get("transfer", "none") != "none" else 1, game.encounter.help_text]
	var visible_options := options.duplicate(true)
	# The catalog carries facilitator witnesses for reproducible audit, not hints.
	visible_options.erase("endpoint_layouts")
	experiment_label.tooltip_text = JSON.stringify(visible_options, "  ")
	next_button.disabled = not game.get("can_advance", false) or controller.is_busy()
	replay_button.disabled = false
	var details: Array[String] = []
	var cleared_cells := 0
	var endpoints_moved := false
	# Raw ordered outcomes remain inspectable even when immediate playback completes.
	var latest: Dictionary = controller.get_record().latest_result() if controller.get_record() != null else {}
	for event in latest.get("events", []):
		if event.type == "damage":
			details.append("hit %d (%d applied)" % [event.amount, event.applied])
		elif event.type == "endpoints_changed":
			endpoints_moved = true
		elif options.get("board_reset") == "each_turn" and event.type in ["effect_consumed", "temporary_expired", "board_piece_cleared"]:
			cleared_cells += 1
		elif event.type in ["effect_consumed", "temporary_expired", "battle_ended", "encounter_transition"]:
			details.append(event.type)
	if cleared_cells > 0:
		details.append("cleared %d cells; Begin / End %s" % [cleared_cells, "moved" if endpoints_moved else "kept"])
	elif endpoints_moved:
		details.append("Begin / End moved")
	experiment_events.text = "Latest: " + (", ".join(details) if not details.is_empty() else "No damage / cleanup events yet")
	experiment_events.tooltip_text = JSON.stringify(latest, "  ")

func _save_experiment_record() -> void:
	if not experiment_mode or controller == null:
		return
	var result: Dictionary = controller.export_record(experiment_record_path)
	record_error = "" if result.ok else "Record write failed: " + result.error
	if result.ok:
		last_record_path = result.path
	if experiment_feedback != null:
		experiment_feedback.text = "Saved locally. Inspect / export for path and notes." if result.ok else record_error
		experiment_feedback.tooltip_text = result.path

func _build_record_dialog() -> void:
	record_dialog = AcceptDialog.new()
	record_dialog.title = "Local experiment observation"
	record_dialog.min_size = Vector2i(660, 720)
	add_child(record_dialog)
	var body := VBoxContainer.new()
	record_dialog.add_child(body)
	note_input = LineEdit.new()
	note_input.placeholder_text = "Optional tester note (avoid personal information)"
	body.add_child(note_input)
	_button("Add note and export", _add_experiment_note, body)
	record_text = TextEdit.new()
	record_text.editable = false
	record_text.custom_minimum_size = Vector2(620, 550)
	record_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(record_text)

func _inspect_experiment_record() -> void:
	if controller == null:
		return
	_save_experiment_record()
	record_text.text = (last_record_path if record_error == "" else record_error) + "\n\n" + JSON.stringify(controller.record_document(), "  ")
	record_dialog.popup_centered(Vector2i(660, 720))

func _add_experiment_note() -> void:
	if controller == null:
		return
	if not note_input.text.strip_edges().is_empty():
		controller.add_note(note_input.text.strip_edges())
		note_input.clear()
	_inspect_experiment_record()

