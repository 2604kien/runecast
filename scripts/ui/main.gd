extends Control

const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Presentation = preload("res://scripts/ui/combat_presentation.gd")
const Cell = preload("res://scripts/ui/board_cell.gd")
const Arena = preload("res://scripts/ui/arena.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const ExperimentRecord = preload("res://scripts/core/experiment_record.gd")

# Set before adding the scene to the tree to select a fixture in integration tests.
# An explicit injected path takes precedence over the development command line.
var setup_path := ""
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

func _ready() -> void:
	if setup_path == "":
		experiment_mode = experiment_mode or "--experiment" in OS.get_cmdline_user_args()
		experiment_scenario = _argument_value("--scenario=", experiment_scenario)
		experiment_variant = _argument_value("--variant=", experiment_variant)
		var seed_text := _argument_value("--seed=", str(experiment_seed))
		experiment_seed = int(seed_text) if seed_text.is_valid_int() else -1
		setup_path = _argument_value("--encounter=", "res://data/encounter.json")
	var loaded: Dictionary = Experiments.load_setup(experiment_scenario, experiment_variant, experiment_seed) if experiment_mode else ContentLoader.load_setup(setup_path)
	if loaded.ok:
		var model := Combat.new(loaded.setup)
		if experiment_mode:
			experiment_setup = loaded.setup.duplicate(true)
		controller = Controller.new(model, Presentation.new(), ExperimentRecord.new(loaded.setup, model.snapshot()) if experiment_mode else null)
		if experiment_mode and "--capture" in OS.get_cmdline_user_args():
			experiment_record_path = "res://output/qa/experiment-records/capture-%s-%s.json" % [experiment_scenario, experiment_variant]
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
	return controller != null and controller.can_edit()

func _exit_tree() -> void:
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
	return button

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0c1525")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	encounter_title = _label("", 28)
	column.add_child(encounter_title)
	if experiment_mode:
		_build_experiment_controls(column)
	arena = Control.new()
	arena.set_script(Arena)
	arena.compact = experiment_mode
	arena.custom_minimum_size.y = 90 if experiment_mode else 310
	column.add_child(arena)
	stats = _label("")
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
		cells.append(cell)
	var wiring := HBoxContainer.new()
	column.add_child(wiring)
	for kind in ["straight", "corner", "split", "join"]:
		var button := _button(kind.capitalize(), _select_tool.bind(kind), wiring)
		button.add_theme_font_size_override("font_size", 15)
		stock_buttons[kind] = button
		edit_buttons.append(button)
	for entry in [["Rotate", _rotate], ["Flip", _flip], ["Undo", _undo], ["Erase", _select_tool.bind("erase")]]:
		var button := _button(entry[0], entry[1], wiring)
		button.add_theme_font_size_override("font_size", 15)
		edit_buttons.append(button)
	column.add_child(_label("RUNES   /   tap an effect, then a socket", 17))
	var hand_scroll := ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = 104
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(hand_scroll)
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
	dialog = AcceptDialog.new()
	dialog.min_size = Vector2i(550, 360)
	dialog.dialog_autowrap = true
	add_child(dialog)
	menu = ConfirmationDialog.new()
	menu.title = "Rune Cast"
	menu.ok_button_text = "Restart"
	menu.cancel_button_text = "Resume"
	pass_button = menu.add_button("Pass turn", false, "pass")
	menu.confirmed.connect(_restart)
	menu.custom_action.connect(func(action):
		if action == "pass":
			_pass()
			menu.hide()
	)
	add_child(menu)
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

func _refresh() -> void:
	sound_button.text = "Sound: On" if sound_enabled else "Sound: Off"
	if controller == null:
		_refresh_startup_error()
		return
	game = controller.snapshot()
	if experiment_mode:
		_refresh_experiment()
	var spell: Dictionary = game.forecast
	var editable := _can_edit()
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
	if experiment_mode:
		menu.dialog_text = "Restart this experiment with continuing RNG.\nUse Exact replay above the board to restore the original seed.\n" + game.encounter.help_text
	banner.text = game.state.to_upper() if game.state != "playing" else ("CIRCUIT COMPLETE" if spell.valid else "CONNECT BEGIN TO END")
	banner.modulate = Color("#7addba") if spell.valid else Color("#edb26b")
	banner.tooltip_text = spell.message
	for index in range(cells.size()):
		var cell: Button = cells[index]
		cell.piece = game.board[index]
		cell.catalog = game.catalog
		cell.split_cost = int(game.get("experiment", {}).get("split_cost", 1))
		cell.disabled = not editable or (experiment_mode and cell.piece.get("kind") == "blocked")
		cell.active = spell.active.has(index)
		cell.chosen = index == selected_cell
		cell.end_value = int(spell.damage) if spell.valid else 0
		cell.tooltip_text = "Row %d, column %d" % [index / 4 + 1, index % 4 + 1]
		cell.queue_redraw()
	for kind in stock_buttons:
		stock_buttons[kind].text = kind.capitalize() + ("\nUnlimited" if kind in ["straight", "corner"] else "\n%d / %d" % [game.stock[kind], game.stock_totals[kind]])
		stock_buttons[kind].tooltip_text = "Unlimited supply" if kind in ["straight", "corner"] else "%d available, %d owned (%d installed)." % [game.stock[kind], game.stock_totals[kind], game.stock_totals[kind] - game.stock[kind]]
	for button in edit_buttons:
		button.disabled = not editable
	for child in hand_box.get_children():
		hand_box.remove_child(child)
		child.queue_free()
	for card in game.hand:
		var rune: Dictionary = game.catalog[card.id]
		var button := _button("%s\n%s\n%d" % [rune.name, rune.symbol, rune.value], _select_card.bind(card.uid), hand_box)
		button.custom_minimum_size = Vector2(142, 92)
		button.modulate = Color(rune.color)
		button.disabled = not editable
		button.tooltip_text = _rune_description(rune) + " | %d energy%s" % [rune.cost, " | Temporary" if rune.get("temporary", false) else ""]
		if card.uid == selected_uid:
			button.grab_focus()
	cast_button.text = "CAST    %d energy" % spell.cost if spell.valid else "CAST"
	cast_button.disabled = not spell.valid or spell.cost > game.energy or not editable
	cast_button.tooltip_text = "%d damage, %d shield. Incoming %d." % [spell.damage, spell.shield, maxi(0, game.intent - spell.shield)] if spell.valid else spell.message
	status.text = help_text if help_text != "" else game.log_text
	if spell.valid and spell.cost > game.energy and game.state == "playing":
		status.text = "Need %d energy; %d available. Edit the circuit or pass in Menu." % [spell.cost, game.energy]
	pass_button.disabled = not editable

func _rune_description(rune: Dictionary) -> String:
	match rune.effect:
		"damage": return "Adds %d damage" % rune.value
		"shield": return "Adds %d shield" % rune.value
		"draw": return "Draw up to %d cards" % rune.value
		"conjure": return "Create %d temporary %s" % [rune.value, game.catalog[rune.generated_rune_id].name]
	return ""

func _refresh_startup_error() -> void:
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
	menu.get_ok_button().disabled = true
	menu.dialog_text = startup_error

func _clear_selection() -> void:
	selected_tool = ""
	selected_uid = -1
	selected_cell = -1
	help_text = ""

func _select_tool(kind: String) -> void:
	if not _can_edit():
		return
	selected_tool = kind
	selected_uid = -1
	help_text = "Tap a socket to place %s. Then Rotate or Flip if needed." % kind
	_refresh()

func _select_card(uid: int) -> void:
	if not _can_edit():
		return
	for card in game.hand:
		if card.uid != uid:
			continue
		if game.catalog[card.id].type == "technique":
			_clear_selection()
			controller.command("technique", {"uid": uid})
		else:
			selected_uid = uid
			selected_tool = ""
			help_text = "Tap a socket to install %s. Cost is paid when casting." % game.catalog[card.id].name
		break
	_refresh()

func _cell_pressed(index: int) -> void:
	if not _can_edit():
		return
	selected_cell = index
	if selected_uid != -1:
		if controller.command("place_rune", {"index": index, "uid": selected_uid}):
			selected_uid = -1
		else:
			help_text = ""
	elif selected_tool != "":
		if not controller.command("place_wire", {"index": index, "kind": selected_tool}):
			help_text = ""
	_refresh()

func _rotate() -> void:
	if not _can_edit():
		return
	if selected_cell >= 0:
		controller.command("rotate", {"index": selected_cell})
	_refresh()

func _flip() -> void:
	if not _can_edit():
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
	if controller == null:
		return
	_clear_selection()
	controller.restart()

func _open_menu() -> void:
	menu.popup_centered(Vector2i(540, 220))

func _show_map() -> void:
	dialog.title = "Tower map"
	dialog.dialog_text = startup_error if controller == null else "%s\n%s\n\nOne encounter at a time is available in this prototype.\n\n%s\n\nPlanned route: encounters, events, shops, recovery rooms and a final guardian. Branching routes and encounter saves are not implemented." % [game.encounter.title, game.enemy_name, game.encounter.help_text]
	dialog.popup_centered(Vector2i(550, 360))

func _show_guide() -> void:
	dialog.title = "Circuit guide"
	var context: String = startup_error if controller == null else game.encounter.help_text
	dialog.dialog_text = context + "\n\nConnect Begin to End. Every powered branch must finish; loops and half-connected joins are invalid.\n\nTap a wiring tool or rune, then a socket. Tap an installed piece to select it, then Rotate. Flip reverses a wire's direction. Erase returns installed runes to your hand. Undo reverses edits until a technique is played.\n\nSplit copies the incoming spell and costs 1 energy. Join combines its branches. Regular effect runes pay once per cast and remain installed. Temporary runes expire into straight wires.\n\nTechniques resolve immediately when tapped. On desktop, hover for costs and details. Cast ends your turn; surviving enemies attack. Menu includes Pass turn and Restart."
	if experiment_mode:
		dialog.dialog_text = context + "\n\nPROVISIONAL EXPERIMENT RULES\n" + (experiment_label.text if experiment_label != null else startup_error) + "\n\nTap a tool/card then a cell; Rotate/Flip change orientation. Undo restores edits until a technique commits them. Cast and Menu > Pass end the turn. Protected endpoints and blocked cells cannot be edited. Exact replay restores the selected starting setup and seed; Menu Restart continues RNG. Inspect / export shows local command observations. See docs/circuit-experiments.md for solutions and the paired protocol."
	dialog.popup_centered(Vector2i(620, 620))

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
	column.add_child(_label("RC-005 LAB / provisional rules", 19))
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
	var seed_text := seed_input.text.strip_edges()
	var chosen_seed := int(seed_text) if seed_text.is_valid_int() else -1
	_launch_experiment(str(scenario_select.get_selected_metadata()), variant_select.get_item_text(variant_select.selected), chosen_seed)

func _launch_experiment(scenario: String, variant: String, seed_value: int, cached_setup: Dictionary = {}) -> bool:
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
		controller.dispose()
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
	experiment_label.tooltip_text = JSON.stringify(options, "  ")
	next_button.disabled = not game.get("can_advance", false) or controller.is_busy()
	replay_button.disabled = false
	var details: Array[String] = []
	# Raw ordered outcomes remain inspectable even when immediate playback completes.
	var latest: Dictionary = controller.get_record().latest_result() if controller.get_record() != null else {}
	for event in latest.get("events", []):
		if event.type == "damage":
			details.append("hit %d (%d applied)" % [event.amount, event.applied])
		elif event.type in ["effect_consumed", "temporary_expired", "battle_ended", "encounter_transition"]:
			details.append(event.type)
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

