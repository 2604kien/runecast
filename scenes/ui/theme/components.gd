extends RefCounted
## RC-013 display-only constructors. Callers supply all text, values and callbacks.
## No evaluator, stock mutation, save handling or navigation model lives here.
const THEME = preload("res://assets/ui/rune_cast_theme.tres")
const PaintedSkin = preload("res://scenes/ui/theme/painted_skin.gd")
const StateLayer = preload("res://scenes/ui/theme/state_layer.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const ReferencePile = preload("res://scenes/ui/theme/reference_pile.gd")
const ReferenceIcons = preload("res://scenes/ui/theme/reference_icons.gd")
const COMBAT_DISPLAY_FONT = preload("res://assets/fonts/combat/display.tres")
const COMBAT_LABEL_FONT = preload("res://assets/fonts/combat/label.tres")
const COMBAT_BODY_FONT = preload("res://assets/fonts/combat/body.tres")
const COMBAT_VALUE_FONT = preload("res://assets/fonts/combat/value.tres")
static var _combat_icon_regions: Dictionary = {}
const CREAM := Color("fff0c5")
const MUTED := Color("c7c3b6")
const TEAL := Color("64f0dd")
const GOLD := Color("edbc66")

static func label(text: String, role: String = "body", font_size: int = 0) -> Label:
	var result := Label.new()
	result.theme = THEME
	result.theme_type_variation = {"title":"RCTitle", "body":"RCBody", "muted":"RCMuted", "location":"RCLocation", "value":"RCValue"}.get(role, "RCBody")
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font_size > 0:
		result.add_theme_font_size_override("font_size", font_size)
	return result

static func combat_label(text: String, role: String = "body", font_size: int = 0) -> Label:
	var result := label(text, role, font_size)
	style_combat_label(result, role, font_size)
	return result

static func style_combat_label(control: Control, role: String = "body", font_size: int = 0) -> void:
	var font: Font = {
		"display": COMBAT_DISPLAY_FONT, "title": COMBAT_DISPLAY_FONT,
		"label": COMBAT_LABEL_FONT, "body": COMBAT_BODY_FONT,
		"muted": COMBAT_BODY_FONT, "location": COMBAT_BODY_FONT,
		"value": COMBAT_VALUE_FONT,
	}.get(role, COMBAT_LABEL_FONT)
	control.add_theme_font_override("font", font)
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)

static func combat_icon(name: String, extent: Vector2) -> TextureRect:
	# Combat samples painted sprites where available; other symbols retain
	# their SVG fallback. Size visible art without changing logical geometry.
	var result := TextureRect.new()
	apply_combat_icon(result, name)
	result.custom_minimum_size = extent
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func apply_combat_icon(target: TextureRect, name: String) -> void:
	# Texture and mask are one binding. In particular, switching Sound off
	# must clear the approved-atlas mask before displaying its SVG fallback.
	target.texture = combat_icon_texture(name)
	target.material = combat_icon_material(name)

static func combat_icon_material(name: String) -> Material:
	return ReferenceIcons.material(name)

static func combat_icon_texture(name: String) -> Texture2D:
	var painted := ReferenceIcons.texture(name)
	if painted != null:
		return painted
	var original := _icon_texture(name)
	if original == null:
		return null
	var path := original.resource_path
	if not _combat_icon_regions.has(path):
		var region := AtlasTexture.new()
		region.atlas = original
		var source := original.get_image()
		region.region = Rect2(source.get_used_rect())
		region.filter_clip = true
		_combat_icon_regions[path] = region
	return _combat_icon_regions[path]

static func icon(name: String, extent: float = 32) -> TextureRect:
	var result := TextureRect.new()
	result.texture = _icon_texture(name)
	result.custom_minimum_size = Vector2(extent, extent)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func _icon_texture(name: String) -> Texture2D:
	var folder := "resources/"
	if name in ["begin", "end", "straight", "corner", "split", "join"]:
		folder = "circuit/"
	elif name in ["spark", "shield", "focus", "conjure"]:
		folder = "runes/core/"
	elif name in ["menu", "map", "guide", "sound_on", "sound_off"]:
		folder = "navigation/"
	elif name in ["remove", "rotate"]:
		folder = "editing/"
	elif name == "temporary_marker":
		folder = ""
	return load("res://assets/icons/" + folder + name + ".svg") if not name.is_empty() else null

static func _skin(parent: Control, path: String, pointed: bool = false) -> Control:
	var skin := PaintedSkin.new()
	skin.name = "PaintedSkin"
	skin.texture = load(path)
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.show_behind_parent = true
	if pointed:
		skin.source_caps = Vector4(56, 18, 56, 18)
		skin.proportional_caps = true
	elif path.ends_with("secondary.png"):
		skin.source_caps = Vector4(38, 20, 38, 20)
		skin.destination_caps = Vector4(19, 10, 19, 10)
	parent.add_child(skin)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.set_meta("rc_skin", skin)
	return skin

static func remove_skin(parent: Control) -> void:
	# Replaced decoration must release its texture instead of remaining as an
	# invisible child. Shared theme resources still serve the other screens.
	if not parent.has_meta("rc_skin"):
		return
	var skin = parent.get_meta("rc_skin", null)
	parent.remove_meta("rc_skin")
	if is_instance_valid(skin):
		parent.remove_child(skin)
		skin.queue_free()

static func _inset(parent: Control, margin: int = 16) -> MarginContainer:
	var inset := MarginContainer.new()
	inset.name = "Content"
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "top", "right", "bottom"]:
		inset.add_theme_constant_override("margin_" + edge, margin)
	parent.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return inset

static func _column(parent: Node, separation: int = 6) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_constant_override("separation", separation)
	parent.add_child(result)
	return result

static func action(text: String, primary: bool = false, minimum: Vector2 = Vector2(180, 56), states: Dictionary = {}) -> Button:
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCPointed" if primary else "RCSecondaryLive"
	result.text = text
	result.custom_minimum_size = Vector2(maxf(minimum.x, 44), maxf(minimum.y, 44))
	result.focus_mode = Control.FOCUS_ALL
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.clip_text = false
	_skin(result, "res://assets/ui/buttons/primary.png" if primary else "res://assets/ui/buttons/secondary.png", primary)
	apply_states(result, states)
	result.button_down.connect(func(): _pressed(result, true))
	result.button_up.connect(func(): _pressed(result, false))
	return result

static func _pressed(control: Control, pressed: bool) -> void:
	var states: Dictionary = control.get_meta("rc_states", {}).duplicate()
	states["pressed"] = pressed
	apply_states(control, states)

static func apply_states(control: Control, states: Dictionary) -> void:
	control.set_meta("rc_states", states.duplicate())
	var overlay = control.get_meta("rc_overlay") if control.has_meta("rc_overlay") else null
	if overlay == null:
		overlay = StateLayer.new()
		overlay.name = "StateOverlay"
		overlay.observed_control = control
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.set_meta("rc_overlay", overlay)
	overlay.states = states.duplicate()
	overlay.board = bool(control.get_meta("rc_board", false))
	control.move_child(overlay, -1)
	overlay.queue_redraw()
	var skin = control.get_meta("rc_skin") if control.has_meta("rc_skin") else null
	if skin:
		var muted := bool(states.get("unavailable", false)) or bool(states.get("disabled", false))
		skin.tint = Color(0.55, 0.63, 0.68, 1) if muted else Color(0.72, 0.78, 0.8, 1) if states.get("pressed", false) else Color.WHITE
		skin.queue_redraw()
	if control is BaseButton:
		control.disabled = bool(states.get("disabled", false)) or bool(states.get("unavailable", false))
	# Focus is a separate child and is never dimmed with painted material.

static func socket(icon_name: String = "", states: Dictionary = {}, endpoint: String = "", extent: float = 72, quarter_turn: int = 0) -> Button:
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCSocket"
	result.custom_minimum_size = Vector2(extent, extent)
	result.set_meta("rc_board", true)
	result.set_meta("rc_icon", icon_name)
	result.set_meta("rc_endpoint", endpoint)
	_skin(result, "res://assets/ui/board/socket.png")
	if not icon_name.is_empty():
		var glyph := icon(icon_name, 0)
		result.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if icon_name in ["begin", "end"]:
			# Endpoint identity has no edge-port strokes. Reserve an interior text lane.
			glyph.offset_left = extent * 0.10
			glyph.offset_right = -extent * 0.10
			glyph.offset_top = extent * 0.03
			glyph.offset_bottom = -extent * 0.23
		# Full cell SVG keeps N/E/S/W ports exactly on the four edges.
		if not icon_name in ["begin", "end"]:
			glyph.rotation = posmod(quarter_turn, 4) * PI / 2
			glyph.resized.connect(func(): glyph.pivot_offset = glyph.size / 2)
	if endpoint.to_upper() in ["BEGIN", "END"]:
		var caption := label(endpoint.to_upper(), "body", 11 if extent <= 80 else 17)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_top = -24 if extent <= 80 else -38
		caption.offset_bottom = -8 if extent <= 80 else -12
	apply_states(result, states)
	return result

static func card(data: Dictionary, states: Dictionary = {}, width: float = 202) -> Button:
	if bool(data.get("compact", false)):
		return _compact_card(data, states, width)
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCCardLive"
	var kind := str(data.get("kind", "damage"))
	if not kind in ["damage", "shield", "technique", "mixed"]:
		kind = "mixed"
	var card_name := str(data.get("name", "Rune"))
	var text_width := maxf(width - 76, 90)
	var font: Font = THEME.get_font("font", "RCBody")
	var name_lines := maxi(2, ceili(font.get_string_size(card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x / text_width) + 1)
	result.custom_minimum_size = Vector2(maxf(width, 190), 268 + name_lines * 22)
	result.tooltip_text = card_name + "\n" + str(data.get("description", ""))
	result.set_meta("rc_card_data", data.duplicate(true))
	_skin(result, "res://assets/ui/runes/" + kind + ".png")
	var inset := 16
	var column := _column(_inset(result, inset), 5)
	column.minimum_size_changed.connect(func(): result.custom_minimum_size.y = maxf(312, column.get_combined_minimum_size().y + inset * 2))
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var cost := _column(header, 0)
	cost.add_child(icon("energy", 26))
	var cost_label := label(str(data.get("cost", 0)), "value", 18)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_child(cost_label)
	var title := label(card_name, "body", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	column.add_child(icon(str(data.get("icon", "spark")), 52))
	var type_label := label(str(data.get("type", "Rune")).to_upper(), "body", 13)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_color", GOLD)
	column.add_child(type_label)
	if data.has("value"):
		var value := label(str(data.value), "value", 16)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
	var scroll := ScrollContainer.new()
	scroll.name = "DescriptionScroll"
	scroll.custom_minimum_size.y = 76
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	column.add_child(scroll)
	var description := label(str(data.get("description", "")), "body", 14)
	description.name = "Description"
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(description)
	var markers: Array[String] = []
	if data.get("temporary", false):
		markers.append("Temporary")
	if data.get("upgraded", false):
		markers.append("Upgraded")
	if not markers.is_empty():
		var marker_row := HBoxContainer.new()
		marker_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if data.get("temporary", false):
			marker_row.add_child(icon("temporary_marker", 20))
		var marker_label := label(" / ".join(markers), "body", 12)
		marker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marker_row.add_child(marker_label)
		column.add_child(marker_row)
	apply_states(result, states)
	return result

static func _compact_card(data: Dictionary, states: Dictionary, width: float) -> Button:
	# The combat hand has a fixed footprint. Long live descriptions scroll
	# inside the card instead of changing the height of the whole combat page.
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCCardLive"
	result.custom_minimum_size = Vector2(maxf(width, 140), maxf(146, float(data.get("compact_height", 146))))
	var kind := str(data.get("kind", "damage"))
	if not kind in ["damage", "shield", "technique", "mixed"]:
		kind = "mixed"
	var card_name := str(data.get("name", "Rune"))
	result.set_meta("rc_card_data", data.duplicate(true))
	result.set_meta("rc_compact_card", true)
	# Top-right anchored offsets for the caller's separate inspection action.
	result.set_meta("rc_info_rect", Rect2(-46, 2, 44, 44))
	var surface := CombatSurface.new()
	surface.name = "CombatSurface"
	surface.kind = "card_" + kind
	surface.art_scale = 720.0 / 841.0
	surface.show_behind_parent = true
	result.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.set_meta("rc_skin", surface)
	result.set_meta("combat_surface", surface)
	var cost_icon := combat_icon("energy", Vector2(25, 29))
	cost_icon.name = "CostIcon"
	result.add_child(cost_icon)
	cost_icon.position = Vector2(8, 6)
	cost_icon.size = Vector2(25, 29)
	cost_icon.stretch_mode = TextureRect.STRETCH_SCALE
	var cost := combat_label(str(data.get("cost", 0)), "value", 20)
	cost.name = "Cost"
	var cost_font: FontVariation = COMBAT_VALUE_FONT.duplicate()
	cost_font.spacing_top = -4
	cost_font.spacing_bottom = -4
	cost.add_theme_font_override("font", cost_font)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost.autowrap_mode = TextServer.AUTOWRAP_OFF
	cost.add_theme_color_override("font_color", Color.WHITE)
	cost.add_theme_color_override("font_outline_color", Color("101522"))
	cost.add_theme_constant_override("outline_size", 2)
	result.add_child(cost)
	cost.position = cost_icon.position
	cost.size = cost_icon.size
	var glyph_extent := Vector2(52, 44)
	var glyph := combat_icon(str(data.get("icon", "spark")), glyph_extent)
	glyph.name = "RuneIcon"
	result.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	glyph.offset_left = -glyph_extent.x / 2
	glyph.offset_right = glyph_extent.x / 2
	glyph.offset_top = 7
	glyph.offset_bottom = 7 + glyph_extent.y
	# The reference name ink is smaller and more open than the old condensed
	# setting. Reserve the outline inside the existing nine-pixel inset too.
	var title_size := 18
	while title_size > 16 and COMBAT_LABEL_FONT.get_string_size(card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > result.custom_minimum_size.x - 24:
		title_size -= 1
	var title := combat_label(card_name, "label", title_size)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_color_override("font_color", Color("fffdf3"))
	title.add_theme_color_override("font_outline_color", Color("11151a"))
	title.add_theme_constant_override("outline_size", 3)
	result.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_left = 9
	title.offset_right = -9
	title.offset_top = 51
	title.offset_bottom = 77
	# Compact combat cards omit the Rune/Technique category. Keep one divider
	# and spend that lane on readable effect copy within the painted border.
	_compact_divider(result, 78, GOLD if kind == "damage" else Color("7bbd54") if kind == "shield" else Color("cfa0ea"))
	var scroll := ScrollContainer.new()
	scroll.name = "DescriptionScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Reserving a conditional scrollbar narrows the first layout enough to
	# produce an extra wrapped line and make that scrollbar self-perpetuating.
	# The compact description keeps its full width; long copy still scrolls.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = true
	result.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 9
	scroll.offset_right = -9
	scroll.offset_top = 81
	scroll.offset_bottom = -7
	var copy := _column(scroll, 2)
	copy.name = "DescriptionContent"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	if data.has("value"):
		var value := label(str(data.value), "value", 16)
		value.name = "Value"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copy.add_child(value)
	var description_text := str(data.get("description", ""))
	var description_font: FontVariation = COMBAT_BODY_FONT.duplicate()
	description_font.spacing_top = -3
	description_font.spacing_bottom = -3
	# Normal-width lettering reaches the approved effect-copy ink height at
	# sixteen pixels. Longer live descriptions retain the existing scroll lane.
	var description_size := 16
	var description := combat_label(description_text, "body", description_size)
	description.name = "Description"
	description.add_theme_font_override("font", description_font)
	description.add_theme_constant_override("line_spacing", 0)
	description.add_theme_color_override("font_color", Color("fffdf3"))
	description.add_theme_color_override("font_outline_color", Color("11151a"))
	description.add_theme_constant_override("outline_size", 3)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(description)
	var markers: Array[String] = []
	if data.get("temporary", false):
		markers.append("Temporary")
	if data.get("upgraded", false):
		markers.append("Upgraded")
	if not markers.is_empty():
		var marker_row := HBoxContainer.new()
		marker_row.name = "Markers"
		marker_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if data.get("temporary", false):
			marker_row.add_child(icon("temporary_marker", 16))
		var marker_label := label(" / ".join(markers), "body", 12)
		marker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marker_row.add_child(marker_label)
		copy.add_child(marker_row)
	apply_states(result, states)
	return result

static func _compact_divider(parent: Control, y: float, color: Color) -> void:
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = color
	parent.add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_left = 20
	line.offset_right = -20
	line.offset_top = y
	line.offset_bottom = y + 1

static func cast_button(data: Dictionary, minimum: Vector2 = Vector2(280, 72)) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 4)
	var valid := bool(data.get("valid", true))
	var affordable := bool(data.get("affordable", true))
	var states: Dictionary = data.get("states", {}).duplicate()
	states["invalid"] = not valid
	states["unavailable"] = not affordable or not valid
	states["disabled"] = not affordable or not valid
	var button := action("", true, minimum, states)
	button.name = "Cast"
	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := label("CAST", "title", 26)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(icon("energy", 34))
	var cost := label(str(data.get("cost", 1)), "value", 26)
	cost.autowrap_mode = TextServer.AUTOWRAP_OFF
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(cost)
	# Keep the already-created overlay above newly attached live content.
	apply_states(button, states)
	result.add_child(button)
	var reason := str(data.get("reason", "Cast ends turn" if valid and affordable else "Circuit incomplete" if not valid else "Not enough energy"))
	if data.get("show_caption", true):
		var caption := label(reason, "body", 14)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.add_child(caption)
	result.set_meta("rc_action", button)
	return result

static func combat_pile(title: String, count: int = 0, mirrored: bool = false) -> Button:
	# Each approved pile has its own original stack and emblem. Discard's
	# left-facing layers are already painted correctly; no sprite is flipped.
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCCardLive"
	result.custom_minimum_size = Vector2(72, 139)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		result.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var surface := ReferencePile.new()
	surface.name = "CombatSurface"
	surface.pile_kind = "discard" if mirrored else "draw"
	surface.show_behind_parent = true
	result.add_child(surface, false, Node.INTERNAL_MODE_BACK)
	result.set_meta("rc_skin", surface)
	result.set_meta("combat_surface", surface)
	# This control exposes the original painted emblem's bounds for layout
	# inspection. The renderer supplies its actual pixels from the reference.
	var glyph := Control.new()
	glyph.name = "PileIcon"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(glyph)
	var plaque := Control.new()
	plaque.name = "CountPlaque"
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(plaque)
	var number := combat_label(str(count), "value", 18)
	number.name = "Count"
	var count_font: FontVariation = COMBAT_VALUE_FONT.duplicate()
	count_font.spacing_top = -4
	count_font.spacing_bottom = -4
	number.add_theme_font_override("font", count_font)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.add_child(number)
	result.set_meta("rc_count", number)
	var caption := combat_label(title.to_upper(), "label", 14)
	caption.name = "PileCaption"
	# Keep the original pile footprint and a padded live caption with the
	# wider reference-direction font; only the longer DISCARD needs one step.
	if COMBAT_LABEL_FONT.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 4 > 64:
		caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", Color("fffdf3"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.add_child(caption)
	# The visible count already communicates an empty pile. Keep the existing
	# live-snapshot metadata without adding an extra Empty line to the layout.
	var hidden_content := Control.new()
	hidden_content.name = "HiddenContent"
	hidden_content.hide()
	result.add_child(hidden_content)
	var empty := label("Empty", "muted", 12)
	hidden_content.add_child(empty)
	result.set_meta("empty_label", empty)
	var reference: WeakRef = weakref(result)
	var queue_fit: Callable = _queue_combat_pile_fit.bind(reference)
	result.resized.connect(queue_fit)
	# Font metrics settle after the controls inherit their scene theme. Refit
	# then so a stale label minimum cannot consume the intended inner gutter.
	# Deferred work carries only a weak reference and is coalesced per pile;
	# scene teardown must not leave callbacks holding destroyed child controls.
	number.minimum_size_changed.connect(queue_fit)
	caption.minimum_size_changed.connect(queue_fit)
	result.ready.connect(queue_fit)
	result.size = result.custom_minimum_size
	_fit_combat_pile(reference)
	apply_states(result, {})
	return result

static func _queue_combat_pile_fit(reference: WeakRef) -> void:
	var pile = reference.get_ref()
	if not is_instance_valid(pile) or pile.is_queued_for_deletion(): return
	if pile.get_meta("rc_pile_fit_queued", false) or pile.get_meta("rc_pile_fit_active", false): return
	pile.set_meta("rc_pile_fit_queued", true)
	_fit_combat_pile.call_deferred(reference)

static func _fit_combat_pile(reference: WeakRef) -> void:
	var pile = reference.get_ref()
	if not is_instance_valid(pile) or pile.is_queued_for_deletion(): return
	pile.set_meta("rc_pile_fit_queued", false)
	if pile.get_meta("rc_pile_fit_active", false): return
	var surface = pile.get_meta("combat_surface", null)
	var glyph = pile.get_node_or_null("PileIcon")
	var plaque = pile.get_node_or_null("CountPlaque")
	var number = pile.get_node_or_null("Count")
	var caption = pile.get_node_or_null("PileCaption")
	for control in [surface, glyph, plaque, number, caption]:
		if not is_instance_valid(control) or control.is_queued_for_deletion(): return
	pile.set_meta("rc_pile_fit_active", true)
	surface.position = Vector2.ZERO
	surface.size = pile.size
	var geometry: Dictionary = surface.get_geometry()
	var face: Rect2 = geometry.front_rect
	glyph.position = geometry.glyph_rect.position
	glyph.size = geometry.glyph_rect.size
	plaque.position = geometry.count_rect.position
	plaque.size = geometry.count_rect.size
	number.position = plaque.position + Vector2(4, 3)
	number.size = plaque.size - Vector2(8, 6)
	caption.position = Vector2(4, pile.size.y - 23)
	caption.size = Vector2(pile.size.x - 8, 21)
	pile.set_meta("rc_pile_geometry", {
		"front_rect": face, "glyph_rect": glyph.get_rect(),
		"plaque_rect": plaque.get_rect(), "count_rect": number.get_rect(),
		"caption_rect": caption.get_rect(), "pile_kind": surface.pile_kind,
	})
	pile.set_meta("rc_pile_fit_active", false)

static func pile(kind: String, count: int, minimum: Vector2 = Vector2(90, 144)) -> Button:
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCCardLive"
	result.custom_minimum_size = Vector2(maxf(minimum.x, 90), maxf(minimum.y, 144))
	_skin(result, "res://assets/ui/frames/panel.png")
	var column := _column(_inset(result, 12), 2)
	column.add_child(icon("draw_pile" if kind.to_lower() == "draw" else "discard_pile", 44))
	var number := label(str(count), "value", 22)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(number)
	var title := label(kind, "body", 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	if count == 0:
		var empty := label("Empty", "muted", 12)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(empty)
	apply_states(result, {})
	return result

static func forecast(values: Dictionary, columns: int = 2) -> GridContainer:
	var result := GridContainer.new()
	result.columns = columns
	result.theme = THEME
	result.add_theme_constant_override("h_separation", 6)
	result.add_theme_constant_override("v_separation", 6)
	for entry in [["damage", "spark", "Damage"], ["shield", "shield", "Shield"], ["cost", "energy", "Cost"], ["incoming", "attack", "Incoming"]]:
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(142, 64)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_skin(cell, "res://assets/ui/buttons/secondary.png")
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon(entry[1], 24))
		var text := label(str(values.get(entry[0], 0)) + " " + entry[2], "body", 14)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		_inset(cell, 12).add_child(row)
		result.add_child(cell)
	return result

static func stock_tool(icon_name: String, title: String, remaining: int, total: int, states: Dictionary = {}) -> Button:
	var display_states := states.duplicate()
	display_states["unavailable"] = remaining <= 0 or bool(states.get("unavailable", false))
	var result := action("", false, Vector2(80, 100), display_states)
	result.tooltip_text = title + (": stock exhausted" if remaining == 0 else ": " + str(remaining) + " available")
	var column := _column(_inset(result, 10), 0)
	var title_label := label(title, "body", 12)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	column.add_child(icon(icon_name, 32))
	var count := label(str(remaining) + " / " + str(total), "value", 15)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count)
	apply_states(result, display_states)
	return result

static func navigation(icon_name: String, title: String, states: Dictionary = {}) -> Button:
	var result := action("", false, Vector2(68, 80), states)
	var column := _column(_inset(result, 10), 0)
	column.add_child(icon(icon_name, 32))
	var title_label := label(title, "body", 12)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	apply_states(result, states)
	return result

static func status_bar(title: String, value: float, maximum: float, kind: String = "health") -> VBoxContainer:
	var result := VBoxContainer.new()
	var text := label(title + "  " + str(int(value)) + " / " + str(int(maximum)), "value", 16)
	result.add_child(text)
	var bar := ProgressBar.new()
	bar.theme = THEME
	bar.theme_type_variation = {"health":"RCHealth", "energy":"RCEnergy", "shield":"RCShield"}.get(kind, "RCHealth")
	bar.custom_minimum_size = Vector2(120, 20)
	bar.max_value = maxf(maximum, 1)
	bar.value = value
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(bar)
	return result

static func settings_toggle(title: String, enabled: bool) -> Button:
	var result := action(title + ": " + ("On" if enabled else "Off"), false, Vector2(240, 56), {"selected":enabled})
	result.name = title.validate_node_name()
	result.toggle_mode = true
	result.button_pressed = enabled
	result.toggled.connect(func(value: bool):
		result.text = title + ": " + ("On" if value else "Off")
		apply_states(result, {"selected":value})
	)
	return result

static func settings_slider(title: String, value: float) -> VBoxContainer:
	var result := VBoxContainer.new()
	var caption := label(title + "  " + str(int(value)) + "%", "body", 16)
	result.add_child(caption)
	var slider := HSlider.new()
	slider.theme = THEME
	slider.custom_minimum_size = Vector2(240, 44)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(func(new_value: float): caption.text = title + "  " + str(int(new_value)) + "%")
	result.add_child(slider)
	result.set_meta("rc_slider", slider)
	apply_states(slider, {})
	return result

static func modal(title: String, body: String, width: float = 312, height: float = 430, confirm_text: String = "") -> PanelContainer:
	var result := PanelContainer.new()
	result.theme = THEME
	result.theme_type_variation = "RCDialog"
	result.custom_minimum_size = Vector2(width, height)
	result.size = Vector2(width, height)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	result.add_child(column)
	column.add_child(label(title, "title", 22))
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.custom_minimum_size.y = 90
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var copy := label(body, "body", 16)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(copy)
	var footer := VBoxContainer.new()
	footer.name = "FixedFooter"
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	if not confirm_text.is_empty():
		var confirm := action(confirm_text, true, Vector2(0, 52))
		confirm.name = "Confirm"
		footer.add_child(confirm)
		result.set_meta("rc_confirm", confirm)
	var close := action("Close", false, Vector2(0, 52))
	close.name = "Close"
	footer.add_child(close)
	result.set_meta("rc_close", close)
	result.set_meta("rc_body_scroll", scroll)
	return result

static func map_node(state: String, icon_name: String = "spark", extent: float = 72) -> Button:
	var states := {"selected":state == "current", "powered":state == "available", "unavailable":state == "locked"}
	var result := Button.new()
	result.theme = THEME
	result.theme_type_variation = "RCSocket"
	result.custom_minimum_size = Vector2(extent, extent)
	var ring := TextureRect.new()
	ring.texture = load("res://assets/ui/states/node_" + state + ".svg")
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(ring)
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glyph := icon(icon_name, 0)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/icons/symbol_tint.gdshader")
	material.set_shader_parameter("appearance_mode", 1)
	material.set_shader_parameter("ink", Color("111b27"))
	material.set_shader_parameter("monochrome_paper", Color("e8d5aa"))
	glyph.material = material
	result.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = extent * 0.22
	glyph.offset_top = extent * 0.22
	glyph.offset_right = -extent * 0.22
	glyph.offset_bottom = -extent * 0.22
	result.set_meta("rc_map_state", state)
	result.tooltip_text = state.capitalize()
	# Node textures already include their non-colour state symbols.
	apply_states(result, {"unavailable":state == "locked"})
	return result
