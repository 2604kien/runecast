extends Button
const Circuit = preload("res://scripts/core/circuit.gd")
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

func _draw() -> void:
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
	var line_color := Color("#ffc76b") if active else Color("#657993")
	var stroke := maxf(3, size.x * 8.0 / 128.0)
	for direction in ports:
		# Extend through half the six-pixel grid gap to meet the adjacent cell.
		var edge := center + Vector2(Circuit.STEP[direction]) * (size * 0.5 + Vector2(3, 3))
		draw_line(center, edge, line_color, stroke, true)
	var kind: String = piece.get("kind", "")
	if kind in ["straight", "corner"]:
		if active:
			# A collar distinguishes powered wires without relying on colour.
			draw_arc(center, stroke * 1.05, 0, TAU, 24, line_color, 2, true)
		return
	var symbol := kind
	if kind == "rune":
		# All currently supported effect definitions share their effect's symbol;
		# Free Spark deliberately has the same board identity as permanent Spark.
		symbol = "shield" if catalog.get(piece.get("rune_id", ""), {}).get("effect") == "shield" else "spark"
	if not SYMBOLS.has(symbol):
		return
	var endpoint := kind in ["begin", "end"]
	var extent := size.x * (0.62 if endpoint else 0.55)
	draw_circle(center, size.x * 0.29, Color("#142535"))
	if active:
		draw_arc(center, size.x * 0.30, 0, TAU, 32, line_color, 2, true)
	draw_set_transform(center, 0 if endpoint else int(piece.get("rotation", 0)) * PI / 2)
	draw_texture_rect(SYMBOLS[symbol], Rect2(Vector2(-extent / 2, -extent / 2), Vector2(extent, extent)), false)
	draw_set_transform(Vector2.ZERO)
	if endpoint:
		var font := get_theme_default_font()
		var font_size := 11 if size.x <= 80 else 15
		var south_port: bool = ports.has(2)
		var baseline := float(font_size + 5) if south_port else size.y - 6
		var caption := kind.to_upper()
		var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_rect(Rect2(Vector2((size.x - text_size.x) / 2 - 3, baseline - font_size), Vector2(text_size.x + 6, font_size + 3)), Color("#142535"))
		_center_text(font, caption, baseline, font_size, Color("#eee0bf"))

