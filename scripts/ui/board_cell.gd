extends Button
const Circuit = preload("res://scripts/core/circuit.gd")
const ReferenceIcons = preload("res://scenes/ui/theme/reference_icons.gd")
const COMBAT_ENDPOINT_BASE_FONT = preload("res://assets/fonts/combat/display.tres")
static var endpoint_font: FontVariation = _reference_endpoint_font()
const SYMBOLS := {
	"begin": preload("res://assets/icons/circuit/begin.svg"),
	"end": preload("res://assets/icons/circuit/end.svg"),
	"split": preload("res://assets/icons/circuit/split.svg"),
	"join": preload("res://assets/icons/circuit/join.svg"),
	"spark": preload("res://assets/icons/runes/core/spark.svg"),
	"shield": preload("res://assets/icons/runes/core/shield.svg")
}
var clean_board := false
var piece: Dictionary = {}
var catalog: Dictionary = {}
var active := false
var chosen := false
var end_value := 0
var split_cost := 1
var preview := 0 # +1 eligible construction, -1 protected/unavailable; UI-only.
const CONNECTED_FACE := Color(0.0, 0.66, 0.48, 0.34)
const CONNECTED_LIGHT := Color("00eac5")
var feedback_light := 0.0
var feedback_color := CONNECTED_LIGHT
var _approved_begin: TextureRect

func set_feedback_light(strength: float, tint: Color = CONNECTED_LIGHT) -> void:
	var next := 0.0 if piece.get("kind", "") in ["begin", "end"] else clampf(strength, 0.0, 1.0)
	if is_equal_approx(feedback_light, next) and feedback_color == tint: return
	feedback_light = next
	feedback_color = tint
	queue_redraw()

func _ready() -> void:
	# A separate canvas item applies the source-contour mask only to the
	# emblem. Live wires and captions keep their own unmasked drawing.
	_approved_begin = TextureRect.new()
	_approved_begin.name = "ApprovedBeginGlyph"
	_approved_begin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_approved_begin.focus_mode = Control.FOCUS_NONE
	_approved_begin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_approved_begin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_approved_begin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_approved_begin.texture = ReferenceIcons.texture("begin")
	_approved_begin.material = ReferenceIcons.material("begin")
	_approved_begin.hide()
	add_child(_approved_begin)

static func _reference_endpoint_font() -> FontVariation:
	var result: FontVariation = COMBAT_ENDPOINT_BASE_FONT.duplicate()
	# Reference captions use compact small caps, rather than full-width capitals.
	result.variation_opentype = {"width": 62.5, "weight": 700.0}
	return result

func _draw() -> void:
	if is_instance_valid(_approved_begin):
		_approved_begin.hide()
	if clean_board:
		_draw_clean_board()
		return
	var center := size * 0.5
	if preview != 0:
		var tint := Color("#6edbc1") if preview > 0 else Color("#a57b76")
		draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), tint, false, 2)
		draw_string(get_theme_default_font(), Vector2(10, size.y - 10), "+" if preview > 0 else "x", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)
	if chosen:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("#fff0b5"), false, 3)
	if piece.is_empty():
		return
	if piece.get("kind") == "blocked":
		draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)), Color("#343844"))
		draw_line(Vector2(18, 18), size - Vector2(18, 18), Color("#ad8390"), 5)
		draw_line(Vector2(size.x - 18, 18), Vector2(18, size.y - 18), Color("#ad8390"), 5)
		_center_text(get_theme_default_font(), "BLOCKED", center.y + 6, 17, Color("#eee0bf"))
		return
	var port := Circuit.ports(piece)
	var line_color := Color("#ffc76b") if active else Color("#657993")
	for direction in port.input:
		var edge := center + Vector2(Circuit.STEP[direction]) * (size * 0.5 - Vector2(3, 3))
		draw_line(edge, center, line_color, 5, true)
	for direction in port.output:
		var vector := Vector2(Circuit.STEP[direction])
		var edge := center + vector * (size * 0.5 - Vector2(4, 4))
		draw_line(center, edge, line_color, 5, true)
		var normal := Vector2(-vector.y, vector.x)
		draw_colored_polygon(PackedVector2Array([edge, edge - vector * 12 + normal * 6, edge - vector * 12 - normal * 6]), line_color)
	var name_text: String = piece.kind.to_upper()
	var symbol := ""
	var amount := ""
	var tint := Color("#5be5d2")
	match piece.kind:
		"begin": symbol = ["^", ">", "v", "<"][port.output[0]]
		"end":
			symbol = "O"
			amount = str(end_value)
		"split": symbol = "x2"
		"join": symbol = "+"
		"rune":
			var rune: Dictionary = catalog[piece.rune_id]
			name_text = rune.get("board_label", rune.name).to_upper()
			symbol = rune.symbol
			amount = str(int(rune.value))
			tint = Color(rune.color)
		_: name_text = ""
	if name_text != "":
		draw_circle(center, size.x * 0.24, Color("#142535"))
		var font := get_theme_default_font()
		_center_text(font, name_text, 19, 14, Color("#eee0bf"))
		_center_text(font, symbol, center.y + 10, 30, tint)
		_center_text(font, amount, size.y - 10, 21, tint)
		if piece.kind in ["split", "rune"]:
			var cost := split_cost if piece.kind == "split" else int(catalog[piece.rune_id].cost)
			draw_circle(Vector2(size.x - 17, 18), 13, Color("#196090"))
			draw_string(font, Vector2(size.x - 22, 24), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func _center_text(font: Font, value: String, y: float, font_size: int, color: Color) -> void:
	draw_string(font, Vector2((size.x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# RC-016A production presentation; historical directed fixtures keep their
# original renderer above. Glyph tips are decorative, separate from ports.
func _draw_clean_board() -> void:
	var center := size * 0.5
	var kind: String = piece.get("kind", "")
	# The reference gives installed glyphs a lit stone face. Keep the socket's
	# painted rim visible; a dark disk would hide both that material and ports.
	var normally_lit := active and kind in ["begin", "end", "split", "join", "rune"]
	# Endpoints keep their existing connected appearance, even if new endpoints
	# occupy cells that still have a cleanup light from the previous board.
	var illumination := 0.0 if kind in ["begin", "end"] else feedback_light
	if normally_lit or illumination > 0.0:
		var amber: bool = kind == "rune" and catalog.get(piece.get("rune_id", ""), {}).get("effect") != "shield"
		var face := Color(0.75, 0.38, 0.015, 0.22) if amber else CONNECTED_FACE
		var light := Color("ffb323") if amber else CONNECTED_LIGHT
		light.a = 0.018
		if not normally_lit:
			face.a = 0.0
			light.a = 0.0
		var feedback_face := CONNECTED_FACE if feedback_color == CONNECTED_LIGHT else Color(feedback_color, CONNECTED_FACE.a)
		# Blend the existing amber face to the endpoint palette instead of
		# stacking another wash over the stone, glyph or logical connections.
		face = face.lerp(feedback_face, illumination)
		light = light.lerp(Color(feedback_color, 0.018), illumination)
		var inset := 7.0
		var cut := 7.0
		var r := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2)
		draw_colored_polygon(PackedVector2Array([
			r.position + Vector2(cut, 0), Vector2(r.end.x - cut, r.position.y),
			Vector2(r.end.x, r.position.y + cut), r.end - Vector2(0, cut),
			r.end - Vector2(cut, 0), Vector2(r.position.x + cut, r.end.y),
			Vector2(r.position.x, r.end.y - cut), r.position + Vector2(0, cut)
		]), face)
		# Broad translucent light retains the painted stone below the symbol.
		for halo in range(6, 0, -1):
			draw_circle(center, minf(size.x, size.y) * (0.19 + halo * 0.027), light)
	if preview != 0:
		var tint := Color("#6edbc1") if preview > 0 else Color("#a57b76")
		draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), tint, false, 2)
		if preview < 0:
			draw_line(Vector2(8, 8), Vector2(16, 16), tint, 2)
			draw_line(Vector2(16, 8), Vector2(8, 16), tint, 2)
	if chosen:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("#fff0b5"), false, 3)
	if piece.is_empty():
		return
	var ports := Circuit.logical_ports(piece)
	if kind in ["straight", "corner"]:
		if ports.size() == 2:
			var first := Vector2(Circuit.STEP[ports[0]])
			var second := Vector2(Circuit.STEP[ports[1]])
			var edge_extent := size * 0.5 + Vector2.ONE * 3
			var path := PackedVector2Array([center + first * edge_extent])
			if kind == "corner":
				# A quadratic bend follows exactly the same two logical ports.
				var radius := minf(size.x, size.y) * 0.15
				var from := center + first * radius
				var to := center + second * radius
				for step in range(9):
					var t := step / 8.0
					path.append(from * (1 - t) * (1 - t) + center * 2 * (1 - t) * t + to * t * t)
			else:
				path.append(center)
			path.append(center + second * edge_extent)
			_draw_clean_wire(path)
		return
	var symbol := kind
	if kind == "rune":
		# All currently supported effect definitions share their effect's symbol;
		# Free Spark deliberately has the same board identity as permanent Spark.
		symbol = "shield" if catalog.get(piece.get("rune_id", ""), {}).get("effect") == "shield" else "spark"
	if not SYMBOLS.has(symbol):
		return
	var endpoint := kind in ["begin", "end"]
	var endpoint_layout := get_endpoint_geometry() if endpoint else {}
	var extent: float = endpoint_layout.extent if endpoint else size.x * 0.65
	for direction in ports:
		# Rays meet the edge of the symbol without an artificial center disk.
		var vector := Vector2(Circuit.STEP[direction])
		var edge := center + vector * (size * 0.5 + Vector2.ONE * 3)
		_draw_clean_wire(PackedVector2Array([center + vector * extent * 0.31, edge]))
	var glyph_center := center
	if endpoint:
		glyph_center = endpoint_layout.center
	# Rune and Split/Join glyphs identify the effect, independently of port direction.
	# Their wires above already follow the piece's rotated logical ports.
	var upright_symbol := endpoint or kind in ["split", "join", "rune"]
	draw_set_transform(glyph_center, 0 if upright_symbol else int(piece.get("rotation", 0)) * PI / 2)
	var painted := ReferenceIcons.board_texture(symbol)
	# The approved powered Join is mint, while the stock tool remains gold.
	# This affects only the emblem; logical ports and their rotation are live.
	var glyph_color := Color(0.52, 1.18, 1.96, 1) if kind == "join" and active else Color.WHITE
	if kind == "begin" and is_instance_valid(_approved_begin):
		_approved_begin.position = endpoint_layout.glyph_rect.position
		_approved_begin.size = endpoint_layout.glyph_rect.size
		_approved_begin.show()
	else:
		draw_texture_rect(painted if painted != null else SYMBOLS[symbol], Rect2(Vector2(-extent / 2, -extent / 2), Vector2(extent, extent)), false, glyph_color)
	draw_set_transform(Vector2.ZERO)
	if endpoint:
		var font := endpoint_font
		var font_size: int = endpoint_layout.font_size
		var baseline: float = endpoint_layout.baseline
		var caption := kind.capitalize()
		var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string_outline(font, Vector2((size.x - text_size.x) / 2, baseline), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color("11191d"))
		_center_text(font, caption, baseline, font_size, Color("#eee0bf"))

func get_endpoint_geometry() -> Dictionary:
	if not piece.get("kind", "") in ["begin", "end"]:
		return {}
	var narrow := size.x <= 80
	var font_size := 14 if narrow else mini(26, roundi(size.x * 0.19))
	# Noto Serif's uppercase ink is about 72% of its em. Reserve that
	# visible cap height plus the outline, rather than the much taller line box.
	var cap_height := roundf(font_size * 0.72)
	var outline := 2.0
	var gap := 2.0
	var inset := 6.0 if narrow else 7.0
	var caption_height := cap_height + outline * 2
	# Endpoint SVG128 has an outer ring diameter of 92px; transparent source
	# padding must not be mistaken for the visible symbol's allocated size.
	var diameter := minf(size.x * 0.85 * 92.0 / 128.0, size.y - inset * 2 - caption_height - gap)
	diameter = maxf(1, diameter)
	var south_port: bool = Circuit.logical_ports(piece).has(2)
	var glyph_center := Vector2(size.x * 0.5, size.y - inset - diameter * 0.5 if south_port else inset + diameter * 0.5)
	var baseline := inset + outline + cap_height if south_port else size.y - inset - outline
	var text_width := endpoint_font.get_string_size(piece.kind.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return {
		"extent": diameter * 128.0 / 92.0,
		"center": glyph_center,
		"font_size": font_size,
		"baseline": baseline,
		"glyph_rect": Rect2(glyph_center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter),
		"caption_rect": Rect2(Vector2((size.x - text_width) * 0.5 - outline, baseline - cap_height - outline), Vector2(text_width + outline * 2, caption_height)),
		"gap": gap,
		"inset": inset
	}

func _draw_clean_wire(points: PackedVector2Array) -> void:
	var stroke := maxf(3, size.x * 7.0 / 128.0)
	if active:
		# Several translucent strokes give a static painted glow, with no
		# directional arrows, node collars, animation or gameplay state.
		for layer in [[3.4, 0.055], [2.6, 0.11], [1.8, 0.20]]:
			var glow := Color("ffa514")
			glow.a = layer[1]
			_rounded_stroke(points, glow, stroke * layer[0])
		_rounded_stroke(points, Color("ffc447"), stroke)
		_rounded_stroke(points, Color("ffe18b"), stroke * 0.42)
	else:
		_rounded_stroke(points, Color("8497a7"), stroke * 0.75)

func _rounded_stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, color, width, true)
	for point in points:
		draw_circle(point, width * 0.5, color)

