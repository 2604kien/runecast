extends Control

const Combat = preload("res://scripts/core/combat.gd")
const Cell = preload("res://scripts/ui/board_cell.gd")
const Arena = preload("res://scripts/ui/arena.gd")

var game := Combat.new()
var cells: Array = []
var selected_tool := ""
var selected_uid := -1
var selected_cell := -1
var arena: Control
var stats: Label
var banner: Label
var status: Label
var hand_box: HBoxContainer
var cast_button: Button
var stock_buttons := {}
var sound_button: Button
var sound_enabled := true
var player: AudioStreamPlayer
var dialog: AcceptDialog
var menu: ConfirmationDialog

func _ready() -> void:
	_build_theme()
	_build_ui()
	_load_settings()
	_refresh()
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://output/qa")
		var error := get_viewport().get_texture().get_image().save_png("res://output/qa/foundation-screen.png")
		print("Screenshot saved: ", error_string(error))
		get_tree().quit(0 if error == OK else 1)

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
	column.add_child(_label("RUNE CAST   /   TRAINING CRYPT", 28))
	arena = Control.new()
	arena.set_script(Arena)
	arena.custom_minimum_size.y = 310
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
		cell.catalog = game.catalog
		cell.pressed.connect(_cell_pressed.bind(index))
		grid.add_child(cell)
		cells.append(cell)
	var wiring := HBoxContainer.new()
	column.add_child(wiring)
	for kind in ["straight", "corner", "split", "join"]:
		var button := _button(kind.capitalize(), _select_tool.bind(kind), wiring)
		button.add_theme_font_size_override("font_size", 15)
		stock_buttons[kind] = button
	for entry in [["Rotate", _rotate], ["Flip", _flip], ["Undo", _undo], ["Erase", _select_tool.bind("erase")]]:
		var button := _button(entry[0], entry[1], wiring)
		button.add_theme_font_size_override("font_size", 15)
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
	menu.dialog_text = "Restart the training encounter?\nInstalled effects persist between turns.\nPass turn is available when you cannot cast."
	menu.ok_button_text = "Restart"
	menu.cancel_button_text = "Resume"
	menu.add_button("Pass turn", false, "pass")
	menu.confirmed.connect(_restart)
	menu.custom_action.connect(func(action):
		if action == "pass":
			game.pass_turn()
			menu.hide()
			_clear_selection()
			_refresh()
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

func _refresh() -> void:
	var spell := game.forecast()
	arena.enemy_hp = game.enemy_hp
	arena.enemy_max_hp = int(game.encounter.max_health)
	arena.attack = game.intent()
	arena.battle_state = game.state
	arena.queue_redraw()
	stats.text = "HEALTH %d / 30       ENERGY %d / 3       TURN %d" % [game.player_hp, game.energy, game.turn]
	banner.text = game.state.to_upper() if game.state != "playing" else ("CIRCUIT COMPLETE" if spell.valid else "CONNECT BEGIN TO END")
	banner.modulate = Color("#7addba") if spell.valid else Color("#edb26b")
	banner.tooltip_text = spell.message
	for index in range(cells.size()):
		var cell: Button = cells[index]
		cell.piece = game.board[index]
		cell.active = spell.active.has(index)
		cell.chosen = index == selected_cell
		cell.end_value = int(spell.damage) if spell.valid else 0
		cell.tooltip_text = "Row %d, column %d" % [index / 4 + 1, index % 4 + 1]
		cell.queue_redraw()
	for kind in stock_buttons:
		stock_buttons[kind].text = kind.capitalize() + ("\nUnlimited" if kind in ["straight", "corner"] else "\n%d / 1" % game.stock(kind))
	for child in hand_box.get_children():
		hand_box.remove_child(child)
		child.queue_free()
	for card in game.hand:
		var rune: Dictionary = game.catalog[card.id]
		var button := _button("%s\n%s\n%d" % [rune.name, rune.symbol, rune.value], _select_card.bind(card.uid), hand_box)
		button.custom_minimum_size = Vector2(142, 92)
		button.modulate = Color(rune.color)
		button.tooltip_text = "%s | %d energy%s" % [rune.type.capitalize(), rune.cost, " | Temporary" if rune.get("temporary", false) else ""]
		if card.uid == selected_uid:
			button.grab_focus()
	cast_button.text = "CAST    %d energy" % spell.cost if spell.valid else "CAST"
	cast_button.disabled = not spell.valid or spell.cost > game.energy or game.state != "playing"
	cast_button.tooltip_text = "%d damage, %d shield. Incoming %d." % [spell.damage, spell.shield, maxi(0, game.intent() - spell.shield)] if spell.valid else spell.message
	status.text = game.log_text
	if spell.valid and spell.cost > game.energy and game.state == "playing":
		status.text = "Need %d energy; %d available. Edit the circuit or pass in Menu." % [spell.cost, game.energy]
	sound_button.text = "Sound: On" if sound_enabled else "Sound: Off"

func _clear_selection() -> void:
	selected_tool = ""
	selected_uid = -1
	selected_cell = -1

func _select_tool(kind: String) -> void:
	selected_tool = kind
	selected_uid = -1
	game.log_text = "Tap a socket to place %s. Then Rotate or Flip if needed." % kind
	_refresh()

func _select_card(uid: int) -> void:
	for card in game.hand:
		if card.uid != uid:
			continue
		if game.catalog[card.id].type == "technique":
			game.play_technique(uid)
			_clear_selection()
		else:
			selected_uid = uid
			selected_tool = ""
			game.log_text = "Tap a socket to install %s. Cost is paid when casting." % game.catalog[card.id].name
		break
	_refresh()

func _cell_pressed(index: int) -> void:
	selected_cell = index
	if selected_uid != -1:
		if game.place_rune(index, selected_uid):
			selected_uid = -1
	elif selected_tool != "":
		game.place_wire(index, selected_tool)
	_refresh()

func _rotate() -> void:
	if selected_cell >= 0:
		game.rotate(selected_cell)
	_refresh()

func _flip() -> void:
	if selected_cell >= 0:
		game.flip(selected_cell)
	_refresh()

func _undo() -> void:
	game.undo()
	_clear_selection()
	_refresh()

func _cast() -> void:
	if game.cast() and sound_enabled:
		player.play()
	_clear_selection()
	_refresh()

func _restart() -> void:
	game.reset()
	_clear_selection()
	_refresh()

func _open_menu() -> void:
	menu.popup_centered(Vector2i(540, 220))

func _show_map() -> void:
	dialog.title = "Tower map"
	dialog.dialog_text = "Training Crypt\n\nOne encounter is implemented in this foundation.\n\nPlanned route: encounters, events, shops, recovery rooms and a final guardian. Branching routes and encounter saves are the next milestone."
	dialog.popup_centered(Vector2i(550, 360))

func _show_guide() -> void:
	dialog.title = "Circuit guide"
	dialog.dialog_text = "Connect Begin to End. Every powered branch must finish; loops and half-connected joins are invalid.\n\nTap a wiring tool or rune, then a socket. Tap an installed piece to select it, then Rotate. Flip reverses a wire's direction. Erase returns installed runes to your hand. Undo reverses edits until a technique is played.\n\nSplit copies the incoming spell and costs 1 energy. Join combines its branches. Regular effect runes pay once per cast and remain installed. Temporary Sparks expire into straight wires.\n\nFocus and Conjure Spark are techniques: tapping them resolves immediately. On desktop, hover for costs and details. Cast ends your turn; surviving enemies attack. Menu includes Pass turn and Restart."
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

