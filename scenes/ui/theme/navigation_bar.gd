extends HBoxContainer
## Shared production navigation presentation. Screen owners wire actions and
## register these buttons with their existing input and audio owners.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const BUTTON_HEIGHT := 82.0
const ART_SCALE := 720.0 / 841.0
const KEYS := ["menu", "map", "guide", "sound"]
var buttons: Dictionary = {}
var _surface: Control
var _selected := ""

func _init() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size.y = BUTTON_HEIGHT
	add_theme_constant_override("separation", 0)
	for index in KEYS.size():
		var key: String = KEYS[index]
		var title := key.capitalize()
		var icon_name := "sound_on" if key == "sound" else key
		var button := Ui.action(title, false, Vector2(66, BUTTON_HEIGHT))
		button.name = title
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		Ui.style_combat_label(button, "label", 20)
		add_child(button)
		buttons[key] = button
		var extent := 58.0 if index in [1, 2] else 40.0 if index == 0 else 46.0
		var glyph := Ui.combat_icon(icon_name, Vector2.ZERO)
		button.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		glyph.offset_left = -extent / 2.0
		glyph.offset_right = extent / 2.0
		glyph.offset_top = 13
		glyph.offset_bottom = 49
		button.set_meta("stacked_icon", glyph)
		var spacing := StyleBoxEmpty.new()
		spacing.content_margin_top = 52
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			button.add_theme_stylebox_override(state, spacing)
		# Native text remains semantic; the explicit caption reserves the same
		# painted-frame inset lane used by the delivered Combat navigation.
		for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
			button.add_theme_color_override(colour, Color.TRANSPARENT)
		var caption := Ui.combat_label(title, "label", 19)
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
		var outer_inset := ceilf(CombatSurface.SOURCE_CAPS.nav.x * ART_SCALE + 4)
		var content_shift := (outer_inset - 8) * (0.5 if index == 0 else -0.5 if index == 3 else 0.0)
		if index == 0: caption.offset_left = outer_inset
		if index == 3: caption.offset_right = -outer_inset
		glyph.offset_left += content_shift
		glyph.offset_right += content_shift
		button.set_meta("navigation_caption", caption)
		Ui.remove_skin(button)
	_surface = CombatSurface.new()
	_surface.name = "CombatSurface"
	_surface.kind = "nav"
	_surface.divisions = 4
	_surface.art_scale = ART_SCALE
	_surface.show_behind_parent = true
	add_child(_surface, false, Node.INTERNAL_MODE_BACK)
	_surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	set_meta("combat_surface", _surface)
	resized.connect(_fit_surface)
	sort_children.connect(func(): _fit_surface.call_deferred())
	set_sound_enabled(true)

func _ready() -> void:
	_fit_surface()

func fit_viewport(viewport_width: float) -> void:
	var margin := 8.0 if viewport_width < 500 else 20.0
	custom_minimum_size = Vector2(minf(640, viewport_width - margin * 2), BUTTON_HEIGHT)
	for key in KEYS:
		var caption_size := (16 if key == "sound" else 17) if viewport_width < 400 else 19
		buttons[key].get_meta("navigation_caption").add_theme_font_size_override("font_size", caption_size)
	queue_redraw()

func set_sound_enabled(enabled: bool) -> void:
	var button: Button = buttons.sound
	button.text = "Sound"
	button.get_meta("navigation_caption").text = "Sound"
	Ui.apply_combat_icon(button.get_meta("stacked_icon"), "sound_on" if enabled else "sound_off")
	button.tooltip_text = "Sound on" if enabled else "Sound off"

func set_selected(key: String) -> void:
	# Keep the current page identity without tinting the shared navigation.
	# Buttons retain their independent keyboard focus and press feedback.
	_selected = key if buttons.has(key) else ""

func _fit_surface() -> void:
	if is_queued_for_deletion() or not is_instance_valid(_surface): return
	_surface.position = Vector2.ZERO
	_surface.size = size
	queue_redraw()
