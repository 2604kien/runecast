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
const BoardExamples = preload("res://scripts/dev/board_examples.gd")
const Ui = preload("res://scenes/ui/theme/components.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")

# Set before adding the scene to the tree to select a fixture in integration tests.
# An explicit injected path takes precedence over the development command line.
var setup_path := ""
# Explicit development witnesses; ordinary launch never reads the example data.
var board_example_id := ""
var board_example_step := "built"
var board_example_report: Dictionary = {}
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
var wiring: GridContainer
var turn_pass_button: Button
# Retain the shared layout reference; this is a display, never an action.
var forecast_button: Control
var forecast_grid: GridContainer
var forecast_reason: Label
var forecast_values := {}
var draw_button: Button
var discard_button: Button
var hand_count: Label
var action_log: Label
var info_buttons := {}
var inspector_origin: WeakRef
var combat_column: VBoxContainer
var page_margin: MarginContainer
var board_frame: PanelContainer
var hand_row: HBoxContainer
var editing_row: HBoxContainer
var cast_cost: Label
var stat_values := {}
var stat_icons := {}
var combat_stats: HBoxContainer
var pile_values := {}
var completion_ribbon: Control
var combat_backdrop: Control
var combat_heading: HBoxContainer
var combat_identity: Control
var combat_navigation: HBoxContainer

func _ready() -> void:
	if setup_path == "" and board_example_id == "":
		board_example_id = _argument_value("--board-example=", "")
		board_example_step = _argument_value("--example-step=", board_example_step)
		experiment_mode = experiment_mode or "--experiment" in OS.get_cmdline_user_args()
		experiment_scenario = _argument_value("--scenario=", experiment_scenario)
		experiment_variant = _argument_value("--variant=", experiment_variant)
		var seed_text := _argument_value("--seed=", str(experiment_seed))
		experiment_seed = int(seed_text) if seed_text.is_valid_int() else -1
		setup_path = _argument_value("--encounter=", ContentLoader.DEFAULT_ENCOUNTER)
	var loaded: Dictionary
	if board_example_id != "":
		if experiment_mode or (setup_path != "" and setup_path != ContentLoader.DEFAULT_ENCOUNTER) or board_example_step not in ["opening", "built", "cast"]:
			loaded = {"ok": false, "errors": ["Board examples require their own development fixture and an opening, built or cast step."]}
		else:
			loaded = BoardExamples.load_example(board_example_id)
			if loaded.ok:
				setup_path = loaded.example.encounter_path
	else:
		loaded = Experiments.load_setup(experiment_scenario, experiment_variant, experiment_seed) if experiment_mode else ContentLoader.load_setup(setup_path)
	if loaded.ok:
		initial_setup = loaded.setup.duplicate(true)
		var model := Combat.new(loaded.setup)
		if experiment_mode:
			experiment_setup = loaded.setup.duplicate(true)
		controller = Controller.new(model, Presentation.new(), ExperimentRecord.new(loaded.setup, model.snapshot()) if experiment_mode else null)
		if board_example_id != "":
			board_example_report = BoardExamples.apply(controller, loaded.example, board_example_step)
			if not board_example_report.ok:
				startup_error = "Cannot reproduce board example.\n" + "\n".join(board_example_report.errors)
				printerr(startup_error)
				controller.dispose()
				controller = null
		if experiment_mode and "--capture" in OS.get_cmdline_user_args():
			# Each automated capture owns its observations; never replace earlier study exports.
			experiment_record_path = "res://output/qa/rc-007/capture-%d-%d-%d/%s-%s.json" % [int(Time.get_unix_time_from_system()), OS.get_process_id(), Time.get_ticks_usec(), experiment_scenario, experiment_variant]
			controller.add_note("AUTOMATED CAPTURE: no human observation")
		if controller != null:
			game = controller.snapshot()
	else:
		startup_error = "Cannot start encounter.\n" + "\n".join(loaded.errors)
		printerr(startup_error)
	_build_theme()
	_build_ui()
	if game.has("production"):
		_track_page_focus(combat_column)
		_apply_mobile_ui_policy(self)
		get_tree().node_added.connect(_mobile_node_added)
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
		# Allow nested card/forecast containers to finish their minimum-size
		# passes before recording the normal launch composition.
		for frame in 4: await get_tree().process_frame
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
	if game.has("production"):
		theme = Ui.THEME
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		return
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
	var button := Ui.action(value, false, Vector2(66, 50)) if game.has("production") else Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(66, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	if gestures != null:
		gestures.register_target(button, action)
	return button

func _icon_texture(icon_name: String) -> Texture2D:
	var sample := Ui.icon(icon_name)
	var texture := sample.texture
	sample.free()
	return texture

func _build_ui() -> void:
	gestures = TouchRouter.new()
	add_child(gestures)
	var background := ColorRect.new()
	background.color = Color("#0c1525")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	page_scroll = scroll
	scroll.follow_focus = game.has("production")
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	gestures.register_scroll(scroll)
	var margin := MarginContainer.new()
	page_margin = margin
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	combat_column = column
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0 if game.has("production") else 6)
	margin.add_child(column)
	if game.has("production"):
		combat_backdrop = preload("res://scenes/ui/theme/reference_backdrop.gd").new()
		combat_backdrop.name = "CombatBackdrop"
		combat_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(combat_backdrop)
		margin.move_child(combat_backdrop, 0)
		margin.sort_children.connect(func():
			combat_backdrop.set_deferred("position", Vector2.ZERO)
			combat_backdrop.set_deferred("size", margin.size)
		)
	var heading := HBoxContainer.new()
	combat_heading = heading
	if game.has("production"):
		# The content column is inset; the header spans the viewport independently.
		var heading_slot := Control.new()
		heading_slot.name = "CombatHeaderSlot"
		heading_slot.custom_minimum_size.y = 52
		column.add_child(heading_slot)
		heading_slot.add_child(heading)
		heading.custom_minimum_size.y = 52
		heading.add_theme_constant_override("separation", 0)
		_surface(heading, "heading")
		var heading_inset := Control.new()
		heading_inset.name = "HeaderStartInset"
		heading_inset.custom_minimum_size.x = 44
		heading.add_child(heading_inset)
	else:
		column.add_child(heading)
	encounter_title = _label("", 28)
	if game.has("production"):
		encounter_title.theme_type_variation = "RCLocation"
		Ui.style_combat_label(encounter_title, "location", 26)
		encounter_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		encounter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	encounter_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if game.has("production"):
		encounter_title.autowrap_mode = TextServer.AUTOWRAP_OFF
		encounter_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	encounter_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(encounter_title)
	if game.has("production"):
		var title_gap := Control.new()
		title_gap.name = "HeaderTitleGap"
		title_gap.custom_minimum_size.x = 12
		heading.add_child(title_gap)
		var wordmark := TextureRect.new()
		wordmark.name = "RuneCastWordmark"
		var title_art := AtlasTexture.new()
		title_art.atlas = CombatSurface.ATLAS
		title_art.region = Rect2(56, 1, 245, 46)
		title_art.filter_clip = true
		wordmark.texture = title_art
		wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wordmark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wordmark.set_meta("accessible_title", "Rune Cast")
		heading.add_child(wordmark)
		heading.move_child(wordmark, 1)
		heading.move_child(title_gap, 2)
		combat_identity = wordmark
		var title_end_inset := Control.new()
		title_end_inset.custom_minimum_size.x = 16
		heading.add_child(title_end_inset)
		heading.minimum_size_changed.connect(_fit_combat_header)
	if experiment_mode:
		_build_experiment_controls(column)
	arena = Control.new()
	arena.set_script(Arena)
	arena.compact = experiment_mode
	arena.reference_art = game.has("production")
	arena.custom_minimum_size.y = 90 if experiment_mode else 310
	column.add_child(arena)
	stats = _label("")
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	banner = _label("", 22)
	column.add_child(banner)
	var center := CenterContainer.new()
	column.add_child(center)
	if game.has("production"):
		board_frame = PanelContainer.new()
		board_frame.theme_type_variation = "RCPanel"
		_combat_panel(board_frame, 14, "board")
		var board_spacing := board_frame.get_theme_stylebox("panel")
		board_spacing.content_margin_top = 6
		board_spacing.content_margin_bottom = 20
		column.remove_child(banner)
		column.remove_child(center)
		column.add_child(board_frame)
		var board_content := VBoxContainer.new()
		board_content.add_theme_constant_override("separation", 2)
		board_frame.add_child(board_content)
		board_content.add_child(banner)
		banner.custom_minimum_size.y = 54
		Ui.style_combat_label(banner, "label", 26)
		banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		completion_ribbon = _surface(banner, "ribbon")
		board_content.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4 if game.has("production") else 6)
	grid.add_theme_constant_override("v_separation", 4 if game.has("production") else 6)
	center.add_child(grid)
	for index in range(16):
		var cell := Button.new()
		cell.set_script(Cell)
		if game.has("production"):
			cell.theme_type_variation = "RCSocket"
			cell.set_meta("rc_board", true)
			_replace_surface(cell, "socket").socket_variant = index
			Ui.apply_states(cell, {})
		cell.custom_minimum_size = Vector2(137, 137)
		cell.catalog = game.get("catalog", {})
		cell.pressed.connect(_cell_pressed.bind(index))
		grid.add_child(cell)
		gestures.register_target(cell, _cell_pressed.bind(index), _inspect_cell.bind(index))
		cell.set_meta("inspect_shortcuts", game.has("production"))
		cells.append(cell)
	wiring = GridContainer.new()
	wiring.columns = 7 if game.has("production") else 4
	wiring.add_theme_constant_override("h_separation", 6 if game.has("production") else 8)
	if game.has("production"):
		var toolbar := PanelContainer.new()
		_combat_panel(toolbar, 6, "toolbar")
		toolbar.custom_minimum_size.y = 112
		column.add_child(toolbar)
		toolbar.add_child(wiring)
	else:
		column.add_child(wiring)
	if game.has("production"):
		turn_pass_button = _button("Pass Turn", _request_pass, wiring)
		turn_pass_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		turn_pass_button.add_theme_font_size_override("font_size", 15)
		turn_pass_button.tooltip_text = "End this turn without a spell. Review the enemy attack before confirming."
		_replace_surface(turn_pass_button, "parchment")
		turn_pass_button.add_theme_color_override("font_color", Color("1e1721"))
		turn_pass_button.add_theme_constant_override("outline_size", 0)
		Ui.style_combat_label(turn_pass_button, "label", 16)
	for kind in ["straight", "corner", "split", "join"]:
		var button: Button
		if game.has("production"):
			button = Ui.stock_tool(kind, kind.capitalize(), 1, 1)
			wiring.add_child(button)
			button.pressed.connect(_select_tool.bind(kind))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var content: VBoxContainer = button.get_node("Content").get_child(0)
			button.set_meta("stock_label", content.get_child(2))
			Ui.style_combat_label(content.get_child(0), "label", 15)
			Ui.style_combat_label(content.get_child(2), "value", 18)
			var tool_title_font: FontVariation = Ui.COMBAT_LABEL_FONT.duplicate()
			tool_title_font.spacing_top = -2
			tool_title_font.spacing_bottom = -2
			content.get_child(0).add_theme_font_override("font", tool_title_font)
			var tool_count_font: FontVariation = Ui.COMBAT_VALUE_FONT.duplicate()
			tool_count_font.spacing_top = -4
			tool_count_font.spacing_bottom = -4
			content.get_child(2).add_theme_font_override("font", tool_count_font)
			Ui.apply_combat_icon(content.get_child(1), kind)
			if kind == "straight":
				var glyph: TextureRect = content.get_child(1)
				content.remove_child(glyph)
				var lane := CenterContainer.new()
				lane.custom_minimum_size = Vector2(52, 40)
				content.add_child(lane)
				content.move_child(lane, 1)
				lane.add_child(glyph)
				glyph.stretch_mode = TextureRect.STRETCH_SCALE
				glyph.custom_minimum_size = Vector2(52, 9)
			_replace_surface(button, "slot")
		else:
			button = _button(kind.capitalize(), _select_tool.bind(kind), wiring)
		button.add_theme_font_size_override("font_size", 15)
		stock_buttons[kind] = button
		button.toggle_mode = true
		gestures.register_target(button, _select_tool.bind(kind), _inspect_tool.bind(kind))
		edit_buttons.append(button)
		if game.has("production"):
			button.set_meta("inspect_action", _inspect_tool.bind(kind))
			button.set_meta("inspect_shortcuts", true)
	var editing := HBoxContainer.new()
	editing_row = editing
	column.add_child(editing)
	if game.has("production"): editing.hide()
	var editing_entries := [["Rotate", _rotate], ["Flip", _flip], ["Undo", _undo], ["Erase", _select_tool.bind("erase")]]
	if game.has("production"):
		editing_entries = [["Remove", _select_tool.bind("erase")], ["Rotate", _rotate]]
	for entry in editing_entries:
		var button := _button(entry[0], entry[1], wiring if game.has("production") else editing)
		button.add_theme_font_size_override("font_size", 15)
		button.custom_minimum_size.y = 58
		action_buttons["erase" if entry[0] == "Remove" else str(entry[0]).to_lower()] = button
		if entry[0] in ["Erase", "Remove"]: button.toggle_mode = true
		if game.has("production"):
			button.icon = _icon_texture(str(entry[0]).to_lower())
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 28)
			Ui.style_combat_label(button, "display", 18)
			_stacked_button_icon(button, str(entry[0]).to_lower(), 36, 54)
			button.get_meta("stacked_icon").position.y = 10
			_replace_surface(button, "button")
		edit_buttons.append(button)
	var inspection_actions := HBoxContainer.new()
	column.add_child(inspection_actions)
	inspect_button = _button("Inspect", _toggle_inspect_mode, inspection_actions)
	inspect_button.toggle_mode = true
	cancel_button = _button("Cancel selection", _cancel_selection, inspection_actions)
	_button("Details / Pass", _show_details, inspection_actions)
	for button in inspection_actions.get_children():
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection_actions.visible = not game.has("production")
	var hand_hint := _label("RUNES / tap to use · hold to inspect · drag to scroll", 17)
	if game.has("production"):
		hand_hint.text = "Tap to use · Info or hold for details · I / right-click on pieces · tap selected item to clear"
	hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hand_hint)
	if game.has("production"): hand_hint.hide() # Guide and Info retain the full instructions.
	if game.has("production"):
		action_log = _label("", 17)
		Ui.style_combat_label(action_log, "body", 16)
		action_log.custom_minimum_size.y = 23
		action_log.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_log.autowrap_mode = TextServer.AUTOWRAP_OFF
		action_log.clip_text = true
		action_log.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(action_log)
		hand_row = HBoxContainer.new()
		hand_row.add_theme_constant_override("separation", 32)
		column.add_child(hand_row)
		draw_button = _combat_pile("Draw", "draw_pile", hand_row)
		hand_count = _label("", 15)
		column.add_child(hand_count)
		hand_count.hide() # Counts also live on both flanking piles; hand remains inspectable.
	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = 104
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if game.has("production"):
		hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Drag/focus still scroll the hand. A conditional scrollbar must not
		# change the hand height and trigger a page/arena width feedback loop.
		hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		hand_row.add_child(hand_scroll)
		discard_button = _combat_pile("Discard", "discard_pile", hand_row)
	else:
		column.add_child(hand_scroll)
	hand_scroll.follow_focus = true
	gestures.register_scroll(hand_scroll)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 12 if game.has("production") else 8)
	hand_scroll.add_child(hand_box)
	status = _label("", 17)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 23 if game.has("production") else 46
	if game.has("production"):
		Ui.style_combat_label(status, "body", 16)
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.autowrap_mode = TextServer.AUTOWRAP_OFF
		status.clip_text = true
		status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(status)
	if game.has("production"):
		column.move_child(status, action_log.get_index())
	if game.has("production"):
		var hand_gap := Control.new()
		hand_gap.custom_minimum_size.y = 10
		column.add_child(hand_gap)
		forecast_button = Control.new()
		forecast_button.name = "ForecastDisplay"
		forecast_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		forecast_button.focus_mode = Control.FOCUS_NONE
		forecast_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		forecast_button.custom_minimum_size.y = 136
		column.add_child(forecast_button)
		_surface(forecast_button, "forecast")
		forecast_reason = _label("", 15)
		forecast_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(forecast_reason)
		column.move_child(forecast_reason, forecast_button.get_index())
		forecast_reason.hide() # Retained diagnostic state; the summary has no input action.
	if game.has("production"):
		var cast_gap := Control.new()
		cast_gap.custom_minimum_size.y = 5
		column.add_child(cast_gap)
		var cast_control := Ui.cast_button({"cost": "—", "show_caption": false}, Vector2(280, 76))
		cast_control.add_theme_constant_override("separation", 0)
		column.add_child(cast_control)
		cast_button = cast_control.get_meta("rc_action")
		_replace_surface(cast_button, "cast")
		cast_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cast_button.custom_minimum_size.x = 500
		cast_button.pressed.connect(_cast)
		gestures.register_target(cast_button, _cast)
		for child in cast_button.get_children():
			if child is HBoxContainer:
				cast_cost = child.get_child(2)
				Ui.style_combat_label(child.get_child(0), "display", 46)
				var cast_font: FontVariation = Ui.COMBAT_DISPLAY_FONT.duplicate()
				cast_font.variation_opentype = {"width": 100.0, "weight": 850.0}
				child.get_child(0).add_theme_font_override("font", cast_font)
				child.get_child(0).add_theme_color_override("font_color", Color("ffe28a"))
				child.get_child(0).add_theme_color_override("font_outline_color", Color("17120b"))
				child.get_child(0).add_theme_constant_override("outline_size", 4)
				Ui.style_combat_label(cast_cost, "value", 44)
				Ui.apply_combat_icon(child.get_child(1), "energy")
				child.get_child(1).custom_minimum_size = Vector2(30, 40)
	else:
		cast_button = _button("CAST", _cast, column)
		cast_button.custom_minimum_size.y = 64
		cast_button.add_theme_font_size_override("font_size", 28)
		column.add_child(_label("Cast ends turn", 16))
	var navigation := HBoxContainer.new()
	combat_navigation = navigation
	if game.has("production"):
		navigation.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		navigation.add_theme_constant_override("separation", 0)
		var navigation_gap := Control.new()
		navigation_gap.custom_minimum_size.y = 18
		column.add_child(navigation_gap)
	column.add_child(navigation)
	_button("Menu", _open_menu, navigation)
	_button("Map", _show_map, navigation)
	_button("Guide", _show_guide, navigation)
	sound_button = _button("Sound: On", _toggle_sound, navigation)
	for button in navigation.get_children():
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if game.has("production"): button.add_theme_font_size_override("font_size", 15)
	if game.has("production"):
		var names := ["menu", "map", "guide", "sound_on"]
		for i in navigation.get_child_count():
			var button: Button = navigation.get_child(i)
			button.autowrap_mode = TextServer.AUTOWRAP_OFF
			button.icon = _icon_texture(names[i])
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 30)
			Ui.style_combat_label(button, "label", 20)
			button.custom_minimum_size.y = 82
			_stacked_button_icon(button, names[i], 58 if i in [1, 2] else 40 if i == 0 else 46, 52)
			button.get_meta("stacked_icon").offset_top = 13
			button.get_meta("stacked_icon").offset_bottom = 49
			# Native Button text has no reliable painted-frame padding. Keep its
			# semantic title and draw the caption in an explicit inset lane.
			for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
				button.add_theme_color_override(colour, Color.TRANSPARENT)
			var caption := Ui.combat_label(button.text, "label", 19)
			var caption_font: FontVariation = Ui.COMBAT_LABEL_FONT.duplicate()
			caption_font.spacing_top = -5
			caption_font.spacing_bottom = -5
			caption.add_theme_font_override("font", caption_font)
			caption.name = "NavigationCaption"
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			button.add_child(caption)
			caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			caption.offset_left = 8
			caption.offset_right = -8
			caption.offset_top = 52
			caption.offset_bottom = 70
			# End segments also contain the sloped outer gold rails. Center their
			# contents in the remaining slate, with four pixels beyond the rail.
			var outer_inset := ceilf(CombatSurface.SOURCE_CAPS.nav.x * 720.0 / 841.0 + 4)
			var content_shift := (outer_inset - 8) * (0.5 if i == 0 else -0.5 if i == 3 else 0.0)
			if i == 0: caption.offset_left = outer_inset
			if i == 3: caption.offset_right = -outer_inset
			button.get_meta("stacked_icon").offset_left += content_shift
			button.get_meta("stacked_icon").offset_right += content_shift
			button.set_meta("navigation_caption", caption)
			Ui.remove_skin(button)
		_surface(navigation, "nav", 4)
		_build_combat_stats()
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
	menu.dialog_autowrap = true
	menu.title = "Rune Cast"
	menu.ok_button_text = "Restart"
	menu.cancel_button_text = "Resume"
	pass_button = menu.add_button("Pass Turn", false, "pass")
	production_replay_button = menu.add_button("Exact replay", false, "exact_replay")
	production_next_button = menu.add_button("Next encounter", false, "next_encounter")
	production_replay_button.hide()
	production_next_button.hide()
	menu.confirmed.connect(_restart)
	menu.custom_action.connect(func(action):
		if action == "pass":
			menu.hide()
			if game.has("production"): _request_pass()
			else: _pass()
		elif action == "exact_replay":
			_exact_replay()
			menu.hide()
		elif action == "next_encounter":
			_next_production_encounter()
			menu.hide()
	)
	add_child(menu)
	if game.has("production"):
		# Native dialog actions keep their existing behavior. Compact painted
		# padding lets Resume / Restart / Exact replay fit the 360px viewport.
		for button in [menu.get_ok_button(), menu.get_cancel_button(), pass_button, production_replay_button, production_next_button]:
			button.theme_type_variation = "RCSecondaryLive"
			button.custom_minimum_size.y = 50
			button.add_theme_font_size_override("font_size", 14)
			var spacing := StyleBoxEmpty.new()
			spacing.content_margin_left = 10
			spacing.content_margin_right = 10
			button.add_theme_stylebox_override("normal", spacing)
			Ui._skin(button, "res://assets/ui/buttons/secondary.png")
			Ui.apply_states(button, {})
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

func _track_page_focus(node: Node) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE and not node.has_meta("page_focus_tracked"):
		node.set_meta("page_focus_tracked", true)
		node.focus_entered.connect(func(): _reveal_page_focus.call_deferred(node))
	for child in node.get_children(): _track_page_focus(child)

func _reveal_page_focus(control: Control) -> void:
	# Explicitly support both the normal Window and native-size SubViewports.
	# Native ScrollContainer follow_focus does not reveal every nested focus
	# change in the latter. Never scroll the background for modal focus.
	if not is_instance_valid(control) or not control.has_focus() or not page_scroll.is_ancestor_of(control): return
	if hand_box.is_ancestor_of(control): hand_scroll.ensure_control_visible(control)
	page_scroll.ensure_control_visible(control)

func _combat_pile(title: String, zone: String, parent: Node) -> Button:
	var pile := Ui.combat_pile(title, 0, zone == "discard_pile")
	parent.add_child(pile)
	pile_values[zone] = pile.get_meta("rc_count")
	pile.pressed.connect(_inspect_pile.bind(zone))
	gestures.register_target(pile, _inspect_pile.bind(zone))
	return pile

func _stacked_button_icon(button: Button, icon_name: String, extent: float, top_padding: float) -> void:
	# Keep the delivered glyph at its intended size. Native Button's expanded
	# top icon can collapse when sharing its minimum-height box with the title.
	button.icon = null
	# Godot reserves another text-height row for TOP icon alignment even when
	# icon is null. The independently placed glyph must not inflate the button.
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var glyph := Ui.combat_icon(icon_name, Vector2.ZERO)
	button.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	glyph.offset_left = -extent / 2
	glyph.offset_right = extent / 2
	glyph.offset_top = 0
	glyph.offset_bottom = extent
	button.set_meta("stacked_icon", glyph)
	var spacing := StyleBoxEmpty.new()
	spacing.content_margin_top = top_padding
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, spacing)

func _surface(parent: Control, kind: String, divisions: int = 0) -> Control:
	var surface := CombatSurface.new()
	surface.name = "CombatSurface"
	surface.kind = kind
	surface.divisions = divisions
	surface.art_scale = 720.0 / 841.0
	surface.show_behind_parent = true
	# Internal decorations must not become extra HBox/Grid slots or input targets.
	parent.add_child(surface, false, Node.INTERNAL_MODE_BACK)
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var fit := func():
		if not is_instance_valid(parent) or not is_instance_valid(surface): return
		if parent.is_queued_for_deletion() or surface.is_queued_for_deletion(): return
		surface.position = Vector2.ZERO
		surface.size = parent.size
		if kind == "ribbon":
			surface.position.x = parent.size.x * 0.12
			surface.size.x = parent.size.x * 0.76
		elif kind == "button":
			surface.size = Vector2(minf(parent.size.x - 8, 64), 52)
			surface.position = Vector2((parent.size.x - surface.size.x) / 2, 2)
			parent.set_meta("rc_state_rect", surface.get_rect())
			if parent.has_meta("rc_overlay"): parent.get_meta("rc_overlay").queue_redraw()
	parent.resized.connect(fit)
	if parent is Container: parent.sort_children.connect(func(): fit.call_deferred())
	fit.call_deferred()
	parent.set_meta("combat_surface", surface)
	return surface

func _replace_surface(parent: Control, kind: String) -> Control:
	Ui.remove_skin(parent)
	if parent is Button:
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			if not parent.has_theme_stylebox_override(state):
				parent.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var surface := _surface(parent, kind)
	parent.set_meta("rc_skin", surface)
	# Preserve any pressed/unavailable state already applied by the factory.
	Ui.apply_states(parent, parent.get_meta("rc_states", {}))
	return surface

func _combat_panel(panel: PanelContainer, inset: int, kind: String = "panel") -> void:
	# Content lives in the painted well; slice caps include the decorative rim.
	var spacing := StyleBoxEmpty.new()
	var margins: Vector4 = CombatSurface.CONTENT_MARGINS.get(kind, Vector4(inset, inset, inset, inset))
	spacing.content_margin_left = margins.x
	spacing.content_margin_top = margins.y
	spacing.content_margin_right = margins.z
	spacing.content_margin_bottom = margins.w
	panel.add_theme_stylebox_override("panel", spacing)
	var skin := _surface(panel, kind)
	# PanelContainer insets ordinary children. Restore the pointer-transparent
	# decoration to the outside of that content inset after each layout sort.
	panel.sort_children.connect(func():
		if not is_instance_valid(panel) or not is_instance_valid(skin): return
		if panel.is_queued_for_deletion() or skin.is_queued_for_deletion(): return
		skin.set_deferred("position", Vector2.ZERO)
		skin.set_deferred("size", panel.size)
	)

func _build_combat_stats() -> void:
	var row := HBoxContainer.new()
	combat_stats = row
	# The full-width arena crop can bleed a few pixels past its layout slot.
	# Keep this foreground frame above the arena's art/status layers (20–22).
	row.z_index = 30
	row.add_theme_constant_override("separation", 0)
	row.custom_minimum_size.y = 54
	combat_column.add_child(row)
	combat_column.move_child(row, stats.get_index())
	_surface(row, "stats", 3)
	stats.hide()
	var stat_font: FontVariation = Ui.COMBAT_VALUE_FONT.duplicate()
	stat_font.spacing_top = -4
	stat_font.spacing_bottom = -5
	for entry in [["health", "health"], ["energy", "energy"], ["turn", ""]]:
		var well := MarginContainer.new()
		well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var margins: Vector4 = CombatSurface.CONTENT_MARGINS.stats
		well.add_theme_constant_override("margin_left", int(margins.x))
		well.add_theme_constant_override("margin_right", int(margins.z))
		well.add_theme_constant_override("margin_top", int(margins.y))
		well.add_theme_constant_override("margin_bottom", int(margins.w))
		row.add_child(well)
		var group := HBoxContainer.new()
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.alignment = BoxContainer.ALIGNMENT_CENTER
		group.add_theme_constant_override("separation", 8)
		well.add_child(group)
		if entry[0] == "health":
			group.alignment = BoxContainer.ALIGNMENT_BEGIN
			var inset := Control.new()
			inset.name = "ReferenceHealthInset"
			inset.custom_minimum_size.x = 6
			group.add_child(inset)
		if not entry[1].is_empty():
			var glyph := Ui.combat_icon(entry[1], Vector2(42, 38) if entry[0] == "health" else Vector2(30, 38))
			glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			group.add_child(glyph)
			stat_icons[entry[0]] = glyph
		var value := Ui.combat_label("", "value", 28)
		value.add_theme_font_override("font", stat_font)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if entry[0] == "energy": value.add_theme_color_override("font_color", Color("50edfa"))
		if entry[0] == "turn":
			var paper := PanelContainer.new()
			paper.name = "TurnPlaque"
			paper.custom_minimum_size.x = 118
			_combat_panel(paper, 4, "parchment")
			group.add_child(paper)
			paper.add_child(value)
			value.add_theme_font_size_override("font_size", 22)
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value.add_theme_color_override("font_color", Color("171018"))
			value.add_theme_constant_override("outline_size", 0)
		else:
			group.add_child(value)
		stat_values[entry[0]] = value

func _fit_combat_header() -> void:
	if not is_instance_valid(combat_heading) or combat_heading.is_queued_for_deletion(): return
	var width := get_viewport_rect().size.x
	var margin := 8 if width < 500 else 20
	combat_heading.position = Vector2(-margin, 0)
	combat_heading.size = Vector2(width, 52)
	combat_heading.get_node("HeaderStartInset").custom_minimum_size.x = 16 if width < 640 else 44

func _fit_layout() -> void:
	if cells.is_empty(): return
	var width := get_viewport_rect().size.x
	cancel_button.text = "Cancel" if width < 500 else "Cancel selection"
	var side := minf(137, floorf((width - 70) / 4.0))
	var cell_height := side
	if game.has("production"):
		var margin := 8 if width < 500 else 20
		combat_identity.custom_minimum_size = Vector2(148, 30) if width < 500 else Vector2(210, 40)
		_fit_combat_header()
		arena.reference_bleed = float(margin)
		for edge in ["left", "right", "top", "bottom"]:
			page_margin.add_theme_constant_override("margin_" + edge, margin)
		page_margin.add_theme_constant_override("margin_top", 0)
		if width >= 640:
			page_margin.add_theme_constant_override("margin_top", 0)
			page_margin.add_theme_constant_override("margin_bottom", 4)
		# The approved portrait uses slightly wider-than-tall sockets and one
		# tool strip. Keep that footprint instead of growing a square board.
		side = minf(137, floorf((width - margin * 2 - 28 - 12 - 16) / 4.0))
		cell_height = floorf(side * 122.0 / 137.0)
		arena.custom_minimum_size.y = arena.recommended_height(width - margin * 2 - 12)
		banner.add_theme_font_size_override("font_size", 17 if width < 500 else 26)
		banner.add_theme_constant_override("outline_size", 2)
		encounter_title.add_theme_font_size_override("font_size", 20 if width < 500 else 26)
		for value in stat_values.values():
			value.add_theme_font_size_override("font_size", 19 if width < 400 else 22 if width < 500 else 32)
		stat_values.turn.add_theme_font_size_override("font_size", 20 if width < 500 else 25)
		stat_icons.health.custom_minimum_size = Vector2(30, 28) if width < 400 else Vector2(32, 30) if width < 500 else Vector2(42, 36)
		stat_icons.energy.custom_minimum_size = Vector2(20, 28) if width < 400 else Vector2(22, 30) if width < 500 else Vector2(26, 36)
		stat_values.health.get_parent().get_node("ReferenceHealthInset").visible = width >= 500
		stat_values.turn.get_parent().custom_minimum_size.x = 78 if width < 500 else 118
		for well in combat_stats.get_children():
			well.add_theme_constant_override("margin_left", 10 if width < 500 and well.get_index() > 0 else 24)
			well.add_theme_constant_override("margin_right", 10 if width < 500 and well.get_index() < 2 else 24)
			if width < 400:
				well.add_theme_constant_override("margin_left", 18 if well.get_index() == 0 else 8)
				well.add_theme_constant_override("margin_right", 18 if well.get_index() == 2 else 8)
			well.get_child(0).add_theme_constant_override("separation", 4 if width < 500 else 8)
		for button in action_buttons.values():
			button.add_theme_font_size_override("font_size", 16)
		turn_pass_button.add_theme_font_size_override("font_size", 13 if width < 500 else 16)
		for card in hand_box.get_children():
			card.custom_minimum_size.x = 149
		hand_row.add_theme_constant_override("separation", 6 if width < 640 else 32)
		forecast_button.custom_minimum_size.x = minf(640, width - margin * 2)
		combat_navigation.custom_minimum_size.x = minf(640, width - margin * 2)
		for button in combat_navigation.get_children():
			var caption_size := (16 if button == sound_button else 17) if width < 400 else 19
			button.get_meta("navigation_caption").add_theme_font_size_override("font_size", caption_size)
		cast_button.custom_minimum_size.x = minf(500, width - margin * 2 - 36)
		cast_cost.add_theme_font_size_override("font_size", 28 if width < 500 else 44)
		for child in cast_button.get_children():
			if child is HBoxContainer:
				child.get_child(0).add_theme_font_size_override("font_size", 28 if width < 500 else 43)
	for cell in cells:
		cell.custom_minimum_size = Vector2(side, cell_height)
	dialog.min_size = Vector2i(mini(550, int(width) - 32), 300)
	if game.has("production"):
		wiring.columns = 7 if width >= 640 else 4
		wiring.add_theme_constant_override("h_separation", 7 if width >= 640 else 5)
		# The taller two-row fallback stretches the painted center; retain the
		# same visible gutter at its lower rail with four more pixels of inset.
		wiring.get_parent().get_theme_stylebox("panel").content_margin_bottom = 21 if width >= 640 else 26
		for button in wiring.get_children():
			button.custom_minimum_size = Vector2(66 if width < 640 else (86 if button == turn_pass_button else (82 if button in action_buttons.values() else 80)), 76)
			# A shared painted strip carries the frame; compact controls retain
			# their focus/selection overlays without seven heavy nested borders.
			var spacing := StyleBoxEmpty.new()
			if button in action_buttons.values():
				spacing.content_margin_top = 54
			for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
				button.add_theme_stylebox_override(state, spacing)
		for button in stock_buttons.values():
			var content: VBoxContainer = button.get_node("Content").get_child(0)
			content.add_theme_constant_override("separation", 1)
			for edge in ["left", "right", "top", "bottom"]:
				button.get_node("Content").add_theme_constant_override("margin_" + edge, 2 if edge in ["top", "bottom"] else 4)
			content.get_child(0).add_theme_font_size_override("font_size", 14 if width < 400 else 15)
			content.get_child(1).custom_minimum_size = Vector2(53, 34)
			if button == stock_buttons.straight:
				content.get_child(1).get_child(0).custom_minimum_size = Vector2(53, 10)
			content.get_child(2).add_theme_font_size_override("font_size", 18)
		_layout_forecast()

func _refresh() -> void:
	gestures.cancel_pending()
	sound_button.text = "Sound: On" if sound_enabled else "Sound: Off"
	if game.has("production"):
		sound_button.text = "Sound"
		sound_button.get_meta("navigation_caption").text = "Sound"
		Ui.apply_combat_icon(sound_button.get_meta("stacked_icon"), "sound_on" if sound_enabled else "sound_off")
		sound_button.tooltip_text = "Sound on" if sound_enabled else "Sound off"
	if controller == null:
		_refresh_startup_error()
		return
	var previous := game
	game = controller.snapshot()
	if previous != game or controller.is_busy():
		_close_inspector(false)
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
	if game.has("production"): encounter_title.text = game.encounter.title.capitalize()
	encounter_title.tooltip_text = game.encounter.help_text
	arena.enemy_name = game.enemy_name
	arena.enemy_hp = game.enemy_hp
	arena.enemy_max_hp = game.enemy_max_hp
	arena.attack = game.intent
	arena.battle_state = game.state
	arena.enemy_id = game.encounter.get("enemy_id", "")
	arena.tooltip_text = "%s: %d / %d health. Incoming attack: %d." % [game.enemy_name, game.enemy_hp, game.enemy_max_hp, game.intent]
	arena.refresh()
	stats.text = "HEALTH %d / %d       ENERGY %d / %d       TURN %d" % [game.player_hp, game.player_max_hp, game.energy, game.energy_per_turn, game.turn]
	stats.tooltip_text = "Refreshes to %d energy and draws %d cards each turn." % [game.energy_per_turn, game.draw_per_turn]
	if not stat_values.is_empty():
		stat_values.health.text = "%d/%d" % [game.player_hp, game.player_max_hp]
		stat_values.energy.text = "%d/%d" % [game.energy, game.energy_per_turn]
		stat_values.turn.text = "Turn %d" % game.turn
	menu.dialog_text = "Restart %s?\nInstalled effects persist between turns.\nPass Turn is available when you cannot cast." % game.encounter.title
	production_replay_button.visible = game.has("production")
	production_next_button.visible = game.has("production") and initial_setup.has("next_encounter")
	production_next_button.disabled = not game.get("can_advance", false) or controller.is_busy()
	if game.has("production"):
		menu.dialog_text = "Cast or Pass clears every non-endpoint piece.\nRestart deals a fresh opening with continuing randomness.\nExact replay restores the original seed and opening."
		stats.tooltip_text += "\nHand %d; draw pile %d; discard %d. %s." % [game.hand.size(), game.draw_pile.size(), game.discard_pile.size(), _kit_description()]
	if experiment_mode:
		menu.dialog_text = "Restart this experiment with continuing RNG.\nUse Exact replay above the board to restore the original seed.\n" + game.encounter.help_text
	banner.text = game.state.to_upper() if game.state != "playing" else ("CIRCUIT COMPLETE" if spell.valid else "CONNECT BEGIN TO END")
	if game.has("production"):
		completion_ribbon.completed = spell.valid and game.state == "playing"
		completion_ribbon.show_check = spell.valid and game.state == "playing"
		completion_ribbon.queue_redraw()
	banner.self_modulate = Color("#43f4c7") if spell.valid else Color("#edb26b")
	banner.tooltip_text = spell.message
	for index in range(cells.size()):
		var cell: Button = cells[index]
		cell.piece = game.board[index]
		cell.clean_board = game.has("production")
		cell.set_meta("rc_clean_board", cell.clean_board)
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
		if game.has("production"):
			Ui.apply_states(cell, {"selected": cell.chosen, "powered": cell.active})
			# apply_states is display-only here; the controller owns availability.
			cell.disabled = not editable
	for kind in stock_buttons:
		var finite: bool = game.stock_totals.has(kind)
		if game.has("production"):
			stock_buttons[kind].get_meta("stock_label").text = "%d / %d" % [game.stock[kind], game.stock_totals[kind]]
		else:
			stock_buttons[kind].text = kind.capitalize() + ("\n%d / %d" % [game.stock[kind], game.stock_totals[kind]] if finite else "\nUnlimited")
		stock_buttons[kind].tooltip_text = "%d available, %d owned (%d installed)." % [game.stock[kind], game.stock_totals[kind], game.stock_totals[kind] - game.stock[kind]] if finite else "Unlimited supply"
		stock_buttons[kind].set_pressed_no_signal(selected_tool == kind)
		stock_buttons[kind].modulate = Color("#b5bdc9") if finite and game.stock[kind] == 0 else Color.WHITE
	for button in edit_buttons:
		button.disabled = not editable
	for action in ["rotate", "flip", "undo"]:
		if not action_buttons.has(action): continue
		var availability: Dictionary = InspectionData.edit_action(game, selected_cell, action)
		action_buttons[action].disabled = not editable or not availability.allowed
		action_buttons[action].tooltip_text = availability.reason
	action_buttons.erase.set_pressed_no_signal(selected_tool == "erase")
	inspect_button.set_pressed_no_signal(inspect_mode)
	inspect_button.text = "Inspect: ON" if inspect_mode else "Inspect"
	inspect_button.disabled = not editable
	cancel_button.disabled = not editable or (selected_tool == "" and selected_uid == -1 and selected_cell == -1 and not inspect_mode)
	var focused := get_viewport().gui_get_focus_owner()
	var focus_uid := -1
	var focus_info := false
	for child in hand_box.get_children():
		if child == focused or (focused != null and child.is_ancestor_of(focused)):
			focus_uid = int(child.get_meta("uid", -1))
			focus_info = focused == info_buttons.get(focus_uid)
		hand_box.remove_child(child)
		child.queue_free()
	info_buttons.clear()
	for card in game.hand:
		var rune: Dictionary = game.catalog[card.id]
		var button: Button
		if game.has("production"):
			var icon_name: String = rune.effect if rune.type == "technique" else ("shield" if rune.effect == "shield" else "spark")
			if icon_name == "draw": icon_name = "focus"
			button = Ui.card({"name": rune.name, "cost": rune.cost, "icon": icon_name,
				"kind": "technique" if rune.type == "technique" else rune.effect,
				"type": rune.type, "description": _rune_description(rune), "temporary": rune.get("temporary", false), "compact": true}, {"selected": card.uid == selected_uid}, 149)
			hand_box.add_child(button)
			button.pressed.connect(_select_card.bind(card.uid))
			gestures.register_target(button, _select_card.bind(card.uid), _inspect_hand.bind(card.uid))
			var info := _button("i", _inspect_hand.bind(card.uid), button)
			info.custom_minimum_size = Vector2(44, 44)
			info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			info.offset_left = -46
			info.offset_right = -2
			info.offset_top = 2
			info.offset_bottom = 46
			Ui.remove_skin(info)
			for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
				info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			info.add_theme_font_size_override("font_size", 16)
			info.tooltip_text = "Read " + str(rune.name) + " without using it"
			info.disabled = not editable
			info_buttons[int(card.uid)] = info
			button.set_meta("inspect_action", _inspect_hand.bind(card.uid))
			button.set_meta("inspect_shortcuts", true)
		else:
			button = _button("%s\n%s\n%d" % [rune.name, rune.symbol, rune.value], _select_card.bind(card.uid), hand_box)
			button.custom_minimum_size = Vector2(142, 92)
		button.toggle_mode = true
		button.set_pressed_no_signal(card.uid == selected_uid)
		button.set_meta("uid", int(card.uid))
		gestures.register_target(button, _select_card.bind(card.uid), _inspect_hand.bind(card.uid))
		if game.has("production"):
			# Child Info must win hit testing over its encompassing card.
			gestures.register_target(info_buttons[int(card.uid)], _inspect_hand.bind(card.uid))
			_track_page_focus(button)
		else:
			button.modulate = Color(rune.color)
		button.disabled = not editable
		button.tooltip_text = _rune_description(rune) + " | %d energy%s" % [rune.cost, " | Temporary" if rune.get("temporary", false) else ""]
		if editable and int(card.uid) == focus_uid:
			if focus_info and info_buttons.has(focus_uid): info_buttons[focus_uid].grab_focus()
			else: button.grab_focus()
	cast_button.text = "CAST    %d energy" % spell.cost if spell.valid else "CAST"
	cast_button.disabled = not spell.valid or spell.cost > game.energy or not editable
	if game.has("production"):
		cast_button.text = ""
		cast_cost.text = str(spell.cost) if spell.valid else "—"
		Ui.apply_states(cast_button, {"disabled": not editable, "unavailable": not spell.valid or spell.cost > game.energy, "invalid": not spell.valid})
	var incoming: int = 0 if spell.damage >= game.enemy_hp else maxi(0, game.intent - spell.shield)
	if game.state != "playing": incoming = 0
	cast_button.tooltip_text = "%d damage, %d shield. Incoming %d." % [spell.damage, spell.shield, incoming] if spell.valid else spell.message
	status.text = help_text if help_text != "" else game.log_text
	if game.has("production"):
		action_log.text = game.log_text
		action_log.tooltip_text = game.log_text
		pile_values.draw_pile.text = str(game.draw_pile.size())
		pile_values.discard_pile.text = str(game.discard_pile.size())
		for entry in [[draw_button, "draw_pile"], [discard_button, "discard_pile"]]:
			entry[0].get_meta("empty_label").visible = game[entry[1]].is_empty()
			entry[0].tooltip_text = "%s: %d cards" % [str(entry[1]).replace("_", " ").capitalize(), game[entry[1]].size()]
			entry[0].disabled = not editable
		hand_count.text = "Hand %d" % game.hand.size()
		turn_pass_button.disabled = not editable
		_refresh_forecast(spell, incoming)
		status.text += "\n%s. Hand %d / draw %d / discard %d." % [_kit_description(), game.hand.size(), game.draw_pile.size(), game.discard_pile.size()]
	if spell.valid and spell.cost > game.energy and game.state == "playing":
		if help_text == "": status.text = "Need %d energy; %d available. Edit the circuit or open Details / Pass." % [spell.cost, game.energy]
	if help_text == "" and not spell.valid and game.state == "playing":
		status.text = spell.message + "\nKeep building, or open Details / Pass."
		if game.has("production"): status.text += "\n%s. Hand %d / draw %d / discard %d." % [_kit_description(), game.hand.size(), game.draw_pile.size(), game.discard_pile.size()]
	pass_button.disabled = not editable
	pass_button.visible = not game.has("production")
	if game.has("production"):
		status.text = status.text.replace("open Details / Pass", "use Pass Turn").replace("Erase", "Remove")
		# Avoid repeating the action log, kit and pile values in the page. Explicit
		# editing feedback remains live; the forecast displays the spell totals.
		status.text = help_text.replace("Erase", "Remove")
		status.visible = not status.text.is_empty()
		status.tooltip_text = status.text
		action_log.visible = not status.visible
		for button in edit_buttons:
			var disabled: bool = button.disabled
			Ui.apply_states(button, {"selected": button.button_pressed, "disabled": disabled})

	if game.has("production"):
		_apply_mobile_ui_policy(self)

func _mobile_node_added(node: Node) -> void:
	if is_ancestor_of(node):
		_apply_mobile_ui_policy.call_deferred(node)

func _apply_mobile_ui_policy(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	if node is Control:
		# Touch inspection/Info carry item descriptions.
		# Never create desktop hover popups or floating availability badges.
		node.tooltip_text = ""
		node.set_meta("rc_show_state_badges", false)
		if node.has_meta("rc_overlay"): node.get_meta("rc_overlay").queue_redraw()
	for child in node.get_children(): _apply_mobile_ui_policy(child)

func _rule_options() -> Dictionary:
	return game.get("production", game.get("experiment", {}))

func _refresh_forecast(spell: Dictionary, incoming: int) -> void:
	forecast_values = {"damage": spell.damage, "shield": spell.shield, "cost": spell.cost, "incoming": incoming}
	if forecast_grid != null:
		forecast_button.remove_child(forecast_grid)
		forecast_grid.queue_free()
	var values := forecast_values.duplicate()
	if not spell.valid:
		for key in ["damage", "shield", "cost"]: values[key] = "—"
	forecast_grid = Ui.forecast(values, 3)
	var incoming_cell := forecast_grid.get_child(3)
	forecast_grid.remove_child(incoming_cell)
	incoming_cell.queue_free()
	forecast_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forecast_button.add_child(forecast_grid)
	forecast_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_forecast()
	forecast_reason.text = ("Cast preview" if spell.cost <= game.energy else "Preview only · need %d energy, have %d" % [spell.cost, game.energy]) if spell.valid else spell.message + " Pass Turn remains available."
	if game.state != "playing": forecast_reason.text = "Battle ended"
	if spell.valid and spell.cost > game.energy and game.state == "playing":
		banner.text = "NEED %d ENERGY · HAVE %d" % [spell.cost, game.energy]
	elif not spell.valid and "conflict" in spell.message.to_lower():
		banner.text = "CONFLICTING CONNECTIONS"

func _layout_forecast() -> void:
	if forecast_grid == null: return
	var narrow := size.x < 500
	# Only the three spell totals are shown. Center each icon/text group in
	# the full frame; Pass confirmation still shows the incoming enemy attack.
	forecast_button.custom_minimum_size.y = 64 if narrow else 54
	forecast_grid.columns = 3
	forecast_grid.offset_left = 22
	forecast_grid.offset_right = -22
	forecast_grid.offset_top = 10
	forecast_grid.offset_bottom = -10
	for index in forecast_grid.get_child_count():
		var cell: Control = forecast_grid.get_child(index)
		cell.custom_minimum_size = Vector2(82 if narrow else 90, 34)
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Ui.remove_skin(cell)
		var inset: MarginContainer = cell.get_node("Content")
		for edge in ["left", "right", "top", "bottom"]:
			inset.add_theme_constant_override("margin_" + edge, 2)
		var row: HBoxContainer = inset.get_child(0)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4 if narrow else 8)
		var glyph: TextureRect = row.get_child(0)
		Ui.apply_combat_icon(glyph, ["spark", "shield", "energy"][index])
		glyph.custom_minimum_size = Vector2(20, 26) if narrow else Vector2(32, 30)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var text: Label = row.get_child(1)
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		Ui.style_combat_label(text, "display", 13 if narrow else 22)

func _inspect_pile(zone: String) -> void:
	if not _can_edit(): return
	var cards: Array = game.get(zone, [])
	var names: Array[String] = []
	var counts := {}
	for card in cards:
		var name_text: String = game.catalog[card.id].name
		counts[name_text] = int(counts.get(name_text, 0)) + 1
	var sorted_names: Array = counts.keys()
	sorted_names.sort()
	for name_text in sorted_names: names.append("%s × %d" % [name_text, counts[name_text]])
	_open_inspector({"title": "Draw pile" if zone == "draw_pile" else "Discard pile", "text": "%d cards\n\n%s" % [cards.size(), "\n".join(names) if not names.is_empty() else "Empty"]})

func _request_pass() -> void:
	if not _can_edit(): return
	_open_inspector({"title": "Pass this turn?", "text": ""})
	_confirm_pass_details()

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
	if game.has("production"):
		inspector_panel.add_theme_stylebox_override("panel", preload("res://assets/ui/styles/panel.tres"))
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
	inspector_pass = _button("Pass Turn…", _confirm_pass_details, column)
	inspector_confirm_pass = _button("Confirm Pass / enemy acts", _accept_pass_details, column)
	inspector_close = _button("Close", _close_inspector, column)
	for button in [inspector_pass, inspector_confirm_pass, inspector_close]:
		button.custom_minimum_size.y = 64
	inspector.hide()

func _open_inspector(detail: Dictionary) -> void:
	if detail.is_empty() or not _can_edit(): return
	gestures.cancel_pending()
	var origin := get_viewport().gui_get_focus_owner()
	inspector_origin = weakref(origin) if origin != null else null
	inspector_title.text = detail.title
	inspector_close.text = "Close"
	inspector_text.text = detail.text
	inspector_scroll.scroll_vertical = 0
	inspector_pass.hide()
	inspector_confirm_pass.hide()
	inspector.show()
	gestures.set_modal(inspector)
	inspector_close.grab_focus()

func _close_inspector(restore_focus: bool = true) -> void:
	if inspector == null or not inspector.visible: return
	inspector.hide()
	gestures.set_modal(null)
	inspector_close.release_focus()
	var origin: Control = inspector_origin.get_ref() if inspector_origin != null else null
	inspector_origin = null
	if restore_focus and is_instance_valid(origin) and not origin.is_queued_for_deletion() and origin.is_visible_in_tree() and not (origin is BaseButton and origin.disabled):
		origin.grab_focus()

func _inspect_hand(uid: int) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_hand(controller.snapshot(), uid))

func _inspect_cell(index: int) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_cell(controller.snapshot(), index))

func _inspect_tool(kind: String) -> void:
	if _can_edit(): _open_inspector(InspectionData.describe_tool(controller.snapshot(), kind))

func _toggle_inspect_mode() -> void:
	if not _can_edit() or game.has("production"): return
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
			if game.has("production") and action in ["flip", "undo"]: continue
			var availability: Dictionary = InspectionData.edit_action(game, selected_cell, action)
			text += "\n%s: %s" % [action.capitalize(), availability.reason]
	_open_inspector({"title": "Circuit details", "text": text})
	inspector_pass.visible = not game.has("production")

func _confirm_pass_details() -> void:
	if controller == null or not controller.can_edit() or not inspector.visible: return
	inspector_title.text = "Pass this turn?"
	inspector_text.text = "The enemy attacks for %d damage. No spell or shield is used.\n\n%s" % [game.intent, "All non-endpoint pieces clear, permanent runes discard and temporaries expire. A surviving player gets a new turn, hand and kit." if game.has("production") else "Normal turn cleanup and the active profile's board rules apply."]
	inspector_pass.hide()
	inspector_confirm_pass.show()
	inspector_close.text = "Cancel" if game.has("production") else "Close"
	inspector_scroll.scroll_vertical = 0
	gestures.cancel_pending()

func _accept_pass_details() -> void:
	if controller == null or not controller.can_edit() or not inspector.visible or not inspector_confirm_pass.visible: return
	_close_inspector(false)
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
	_close_inspector(false)
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
	_close_inspector(false)

func _select_tool(kind: String) -> void:
	if not _can_edit():
		return
	if inspect_mode:
		_inspect_tool(kind)
		return
	if game.has("production") and selected_tool == kind:
		_cancel_selection()
		return
	selected_tool = kind
	selected_uid = -1
	selected_cell = -1
	help_text = "Tap a socket to place %s. Then Rotate or Flip if needed." % kind
	if game.has("production"): help_text = "Tap a socket to place %s. Rotate changes its connections; hold or I/right-click for details." % kind
	if game.stock_totals.has(kind) and int(game.stock[kind]) == 0:
		help_text = "No %s available. Erase one to refund it, or replace the same kind." % kind
	elif kind == "erase":
		help_text = "Remove selected. Tap an eligible piece to return it; endpoints are protected." if game.has("production") else "Erase selected. Tap an eligible piece to return it; endpoints are protected."
	_refresh()

func _select_card(uid: int) -> void:
	if not _can_edit():
		return
	if inspect_mode:
		_inspect_hand(uid)
		return
	if game.has("production") and selected_uid == uid:
		_cancel_selection()
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
			help_text = _endpoint_direction(selected_cell) + (" Use Rotate to turn clockwise." if game.has("production") else " Use Rotate to turn clockwise; Undo restores the previous direction.")
	_refresh()

func _flip() -> void:
	if not _can_edit() or game.has("production"):
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
	if not _can_edit() or game.has("production"):
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
	if game.has("production"):
		for button in [menu.get_ok_button(), menu.get_cancel_button(), pass_button, production_replay_button, production_next_button]:
			Ui.apply_states(button, {"disabled": button.disabled})
	menu.popup_centered(Vector2i(mini(int(size.x) - 32, 660), 250) if game.has("production") else Vector2i(540, 220))

func _show_map() -> void:
	dialog.title = "Tower map"
	dialog.dialog_text = startup_error if controller == null else "%s\n%s\n\nOne encounter at a time is available in this prototype.\n\n%s\n\nPlanned route: encounters, events, shops, recovery rooms and a final guardian. Branching routes and encounter saves are not implemented." % [game.encounter.title, game.enemy_name, game.encounter.help_text]
	dialog.popup_centered(Vector2i(mini(550, int(size.x) - 32), mini(360, int(size.y) - 32)))

func _show_guide() -> void:
	dialog.title = "Circuit guide"
	var context: String = startup_error if controller == null else game.encounter.help_text
	if game.has("production"):
		dialog.dialog_text = "Every playable turn starts with only Begin and End. Click Begin or End, then Rotate to change its connection. Endpoints may be adjacent or face outward; Remove cannot erase them.\n\nCompatible ports connect in either direction. Straight runes and wires rotate geometrically. Split has three logical ports and branches one route into two; Join merges two into one. Their decorative tips are not extra ports. Every powered port must connect, every branch must reach End, and conflicting feedback is invalid. Disconnected pieces contribute nothing.\n\nSplit copies the incoming signal and costs 1 energy; Join costs 0. A Spark before two branches contributes twice, while a shared Spark after Join contributes once. Every physical rune pays once. Cast resolves one total damage hit, then shield and retaliation only if the enemy survives. The live forecast above Cast shows the same evaluation; an unaffordable preview cannot Cast.\n\nPass Turn beside the wiring tools opens confirmation of the enemy's unshielded attack. It remains available with an incomplete circuit or empty hand. Cast or Pass clears all non-endpoints. Permanent hand/installed cards discard; temporary cards disappear. Surviving players get new endpoints, a fresh finite kit, refreshed energy and a normal draw. No useful hand or opening is guaranteed.\n\nTap a card/tool then a cell; tap it again or press Escape to clear selection. Remove returns runes to hand or connectors to stock. Rotate turns the selected piece clockwise. Techniques activate immediately when tapped. Info on a card or a hold opens details safely; keyboard I or right-click also inspects pieces/tools. The forecast is an information display only. Close/Escape dismisses details.\n\nDrag the hand horizontally and the page vertically to scroll. Movement cancels tap/hold. Menu offers Restart with continuing randomness and Exact replay of the original seed."
		dialog.popup_centered(Vector2i(mini(620, int(size.x) - 32), mini(620, int(size.y) - 32)))
		return
	dialog.dialog_text = context + "\n\nConnect Begin to End. Every powered branch must finish; loops and half-connected joins are invalid.\n\nTap a wiring tool or rune, then a socket. Tap an installed piece to select it, then Rotate. Flip reverses a wire's direction. Erase returns installed runes to your hand. Undo reverses edits until a technique is played.\n\nSplit copies the incoming spell and costs 1 energy. Join combines its branches. Regular effect runes pay once per cast and remain installed. Temporary runes expire into straight wires.\n\nTechniques resolve immediately when tapped. On desktop, hover for costs and details. Cast ends your turn; surviving enemies attack. Menu includes Pass Turn and Restart."
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

