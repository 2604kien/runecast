extends Control
## Small live Map ornaments. These own no input, state or navigation.
## The approved artwork remains a reference; no pixels are sampled from it.
const OUTLINE := Color("14222a")
const GOLD := Color("c7a25c")
const LIGHT_GOLD := Color("f0d58e")
const DARK_GOLD := Color("8c6637")
const UNDERPAINT = preload("res://assets/ui/combat/backdrop.png")

var kind: String = "gold":
	set(value):
		kind = value
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0: return
	if kind == "backdrop":
		_backdrop()
		return
	if kind == "subtitle":
		_subtitle()
		return
	if kind == "selected":
		_selected()
		return
	var extent := minf(size.x, size.y)
	draw_set_transform((size - Vector2.ONE * extent) / 2.0, 0, Vector2.ONE * extent / 64.0)
	if kind == "gold": _pouch()
	elif kind == "depth": _stairs()

func _backdrop() -> void:
	# Only unmarked blue stone below the Combat arena is used for the top and
	# sides. Mirrored adjoining strips share the same edge pixels, avoiding a
	# hard horizontal repeat seam while keeping the original stone scale.
	var source_size := Vector2(841, 1870)
	var texture_scale := UNDERPAINT.get_size() / source_size
	var k := size.x / source_size.x
	var tile_height := 490.0 * k
	var offset := 0.0
	var mirrored := false
	while offset < size.y:
		var height := minf(tile_height, size.y - offset)
		var source_height := height / k
		var source_y := 1040.0 - source_height if mirrored else 550.0
		draw_set_transform(Vector2(0, offset + height if mirrored else offset), 0, Vector2(1, -1 if mirrored else 1))
		draw_texture_rect_region(UNDERPAINT, Rect2(0, 0, size.x, height),
			Rect2(Vector2(0, source_y) * texture_scale, Vector2(841, source_height) * texture_scale))
		offset += height
		mirrored = not mirrored
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Keep the existing lower candles at their original relative scale. A short
	# feather blends their clean stone surround into the side material above;
	# no upper arena, labels, HUD, or Map reference pixels are present.
	var bottom_height := minf(380.0 * k, size.y)
	var bottom_y := size.y - bottom_height
	var fade_height := minf(72.0 * k, bottom_height)
	var source_start := 1870.0 - bottom_height / k
	var strips := 32
	for index in strips:
		var start := fade_height * float(index) / strips
		var end := fade_height * float(index + 1) / strips
		var alpha := smoothstep(0.0, 1.0, (float(index) + 0.5) / strips)
		draw_texture_rect_region(UNDERPAINT, Rect2(0, bottom_y + start, size.x, end - start),
			Rect2(Vector2(0, source_start + start / k) * texture_scale, Vector2(841, (end - start) / k) * texture_scale),
			Color(1, 1, 1, alpha))
	var remaining := bottom_height - fade_height
	if remaining > 0:
		draw_texture_rect_region(UNDERPAINT, Rect2(0, bottom_y + fade_height, size.x, remaining),
			Rect2(Vector2(0, source_start + fade_height / k) * texture_scale, Vector2(841, remaining / k) * texture_scale))

func _pouch() -> void:
	_shape([Vector2(22, 7), Vector2(28, 10), Vector2(34, 8), Vector2(43, 7),
		Vector2(39, 20), Vector2(43, 27), Vector2(51, 38), Vector2(52, 46),
		Vector2(48, 53), Vector2(39, 57), Vector2(23, 56), Vector2(15, 51),
		Vector2(12, 44), Vector2(15, 34), Vector2(23, 24), Vector2(25, 20)], GOLD)
	_fill([Vector2(39, 23), Vector2(44, 29), Vector2(49, 39), Vector2(49, 47),
		Vector2(43, 52), Vector2(35, 54), Vector2(39, 44), Vector2(38, 31)], DARK_GOLD)
	_fill([Vector2(22, 29), Vector2(27, 25), Vector2(24, 36), Vector2(20, 45),
		Vector2(17, 43), Vector2(18, 36)], LIGHT_GOLD)
	draw_polyline(PackedVector2Array([Vector2(23, 19), Vector2(31, 21), Vector2(40, 19)]), OUTLINE, 4.5, true)
	draw_line(Vector2(24, 20), Vector2(39, 20), LIGHT_GOLD, 1.7, true)
	draw_polyline(PackedVector2Array([Vector2(39, 21), Vector2(46, 25), Vector2(43, 28)]), OUTLINE, 2.5, true)
	draw_circle(Vector2(32, 39), 8.5, OUTLINE, true, -1, true)
	draw_circle(Vector2(32, 39), 6.4, LIGHT_GOLD, true, -1, true)
	draw_arc(Vector2(32, 39), 4.3, -0.7, 2.4, 16, DARK_GOLD, 1.5, true)
	draw_line(Vector2(32, 35), Vector2(32, 42), DARK_GOLD, 1.5, true)

func _stairs() -> void:
	_shape([Vector2(8, 55), Vector2(8, 42), Vector2(22, 42), Vector2(22, 29),
		Vector2(36, 29), Vector2(36, 16), Vector2(55, 16), Vector2(55, 55)], GOLD)
	_fill([Vector2(12, 47), Vector2(25, 47), Vector2(25, 34), Vector2(39, 34),
		Vector2(39, 21), Vector2(52, 21), Vector2(52, 52), Vector2(12, 52)], DARK_GOLD)
	draw_polyline(PackedVector2Array([Vector2(10, 43), Vector2(24, 43),
		Vector2(24, 30), Vector2(38, 30), Vector2(38, 17), Vector2(53, 17)]), LIGHT_GOLD, 2.5, true)
	draw_line(Vector2(10, 47), Vector2(23, 47), OUTLINE, 2, true)
	draw_line(Vector2(24, 34), Vector2(37, 34), OUTLINE, 2, true)
	draw_line(Vector2(38, 21), Vector2(53, 21), OUTLINE, 2, true)
	draw_line(Vector2(8, 55), Vector2(56, 55), OUTLINE, 3.2, true)

func _subtitle() -> void:
	var y := size.y / 2.0
	var gap := size.x * 0.53
	var inset := size.x * 0.045
	var diamond := clampf(size.y * 0.13, 2.5, 5.0)
	for side in [-1.0, 1.0]:
		var outer := Vector2(inset if side < 0 else size.x - inset, y)
		var inner := Vector2((size.x + side * gap) / 2.0, y)
		draw_line(outer, inner, DARK_GOLD, 2, true)
		draw_line(outer + Vector2(0, -0.6), inner + Vector2(0, -0.6), GOLD, 1, true)
		_fill([outer + Vector2(-diamond, 0), outer + Vector2(0, -diamond),
			outer + Vector2(diamond, 0), outer + Vector2(0, diamond)], GOLD)
		draw_line(inner, inner + Vector2(side * diamond * 1.4, -diamond * 0.7), GOLD, 1, true)

func _selected() -> void:
	var inset := 3.0
	var corner := minf(10, minf(size.x, size.y) * 0.16)
	var points := PackedVector2Array([Vector2(inset + corner, inset), Vector2(size.x - inset - corner, inset),
		Vector2(size.x - inset, inset + corner), Vector2(size.x - inset, size.y - inset - corner),
		Vector2(size.x - inset - corner, size.y - inset), Vector2(inset + corner, size.y - inset),
		Vector2(inset, size.y - inset - corner), Vector2(inset, inset + corner)])
	draw_colored_polygon(points, Color(0.13, 0.65, 0.62, 0.16))
	points.append(points[0])
	draw_polyline(points, Color(0.27, 0.78, 0.72, 0.65), 1.5, true)
	draw_line(Vector2(size.x * 0.26, 1), Vector2(size.x * 0.74, 1), Color("86d0b2"), 2, true)

func _shape(vertices: Array, colour: Color) -> void:
	var points := PackedVector2Array(vertices)
	draw_colored_polygon(points, colour)
	points.append(points[0])
	draw_polyline(points, OUTLINE, 3.2, true)

func _fill(vertices: Array, colour: Color) -> void:
	draw_colored_polygon(PackedVector2Array(vertices), colour)
