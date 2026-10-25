extends Control
## Live decoration for the reusable Ui.map_node Button. The Button retains input
## ownership; this child supplies state rings, glyphs, checks and location ribbon.
const RoomSymbol = preload("res://scripts/ui/route_map_symbol.gd")
const LABEL_FONT = preload("res://assets/fonts/combat/display.tres")
const INK := Color("102738")
const PAPER := Color("d9c59c")
var state := "locked"
var family := "normal"
var role := ""
var subdued := false
var _symbol: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_symbol = RoomSymbol.new()
	_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_symbol)
	resized.connect(queue_redraw)

func _draw() -> void:
	var scale_factor := maxf(0.5, minf(size.x, size.y) / 72.0)
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.415
	var is_current := state == "current"
	var is_available := state == "available"
	var is_complete := state in ["visited", "completed"]
	var base_ink := Color(INK, 0.38) if subdued else INK
	if role == "guardian":
		_guardian_ring(center, radius, base_ink, scale_factor)
	if is_current or is_available:
		var glow := Color("55f6ef") if is_current else Color("ffbd36")
		_halo(center, radius, glow, scale_factor)
		draw_circle(center, radius + 1.5 * scale_factor, INK)
		draw_circle(center + Vector2(0, 1) * scale_factor, radius - 3 * scale_factor, Color("18323d"))
		draw_arc(center, radius, 0, TAU, 90, Color("eaffdf") if is_current else Color("fff4b0"), 2.5 * scale_factor, true)
		draw_arc(center, radius + 3.2 * scale_factor, 0, TAU, 90, glow, 1.5 * scale_factor, true)
		draw_arc(center, radius - 4.5 * scale_factor, PI * 1.08, PI * 1.85, 30, Color(glow, 0.42), 1.1 * scale_factor, true)
	elif role != "guardian" and not (family == "recovery" and state == "locked"):
		# Slight intentional gaps echo the ink-ring treatment in the reference.
		_ink_arc(center, radius, 0.06, PI * 0.93, base_ink, 2.9 * scale_factor, scale_factor)
		_ink_arc(center, radius, PI * 1.01, PI * 1.87, base_ink, 2.9 * scale_factor, scale_factor)
		_ink_arc(center + Vector2(0.3, -0.3) * scale_factor, radius - 1.8 * scale_factor, PI * 1.92, TAU + 0.02, base_ink, 1.5 * scale_factor, scale_factor)
	if _symbol != null:
		_symbol.family = family
		_symbol.role = role
		_symbol.ink = Color("f8d77f") if is_available else Color("deefc7") if is_current else base_ink
		_symbol.cutout = INK if is_current or is_available else PAPER
		var symbol_extent := radius * (1.85 if role == "guardian" else 1.75)
		_symbol.size = Vector2.ONE * symbol_extent
		_symbol.position = center - _symbol.size / 2.0
		_symbol.queue_redraw()
	if is_complete: _check(center, radius, scale_factor)
	if is_current:
		_locator(center, radius, scale_factor)
		_ribbon(center, radius, scale_factor)

func _halo(center: Vector2, radius: float, colour: Color, scale_factor: float) -> void:
	for extra in range(12, 0, -2):
		draw_arc(center, radius + extra * scale_factor * 0.6, 0, TAU, 80, Color(colour, 0.05 + (12 - extra) * 0.008), 4 * scale_factor, true)

func _ink_arc(center: Vector2, radius: float, start: float, finish: float, colour: Color, width: float, scale_factor: float) -> void:
	var points := PackedVector2Array()
	for i in 37:
		var angle := lerpf(start, finish, float(i) / 36.0)
		var hand_edge := (sin(angle * 5.0 + 0.7) * 0.55 + sin(angle * 11.0) * 0.25) * scale_factor
		points.append(center + Vector2.from_angle(angle) * (radius + hand_edge))
	draw_polyline(points, colour, width, true)

func _guardian_ring(center: Vector2, radius: float, colour: Color, scale_factor: float) -> void:
	for i in 12:
		var angle := TAU * i / 12.0 - PI / 2.0
		var direction := Vector2.from_angle(angle)
		var normal := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([center + direction * (radius - 1) - normal * 3 * scale_factor,
			center + direction * (radius + 6 * scale_factor),
			center + direction * (radius - 1) + normal * 3 * scale_factor]), colour)
	draw_arc(center, radius, 0, TAU, 96, colour, 5.0 * scale_factor, true)
	draw_arc(center, radius - 4.6 * scale_factor, 0.15, TAU - 0.08, 96, colour, 1.2 * scale_factor, true)

func _check(center: Vector2, radius: float, scale_factor: float) -> void:
	var marker := center + Vector2(0.77, 0.76) * radius
	var check_radius := 10.5 * scale_factor
	draw_circle(marker + Vector2(0, 1) * scale_factor, check_radius + 1.7 * scale_factor, INK)
	draw_circle(marker, check_radius, Color("215b35"))
	draw_arc(marker, check_radius, 0, TAU, 40, Color("f0e5b7"), 1.3 * scale_factor, true)
	draw_polyline(PackedVector2Array([marker + Vector2(-5.5, -0.5) * scale_factor, marker + Vector2(-1.5, 4.0) * scale_factor, marker + Vector2(6.0, -5.5) * scale_factor]), Color("f4ffe6"), 2.5 * scale_factor, true)

func _locator(center: Vector2, radius: float, scale_factor: float) -> void:
	var marker := center - Vector2(0, radius + 14 * scale_factor)
	var points := PackedVector2Array([marker + Vector2(0, -13) * scale_factor, marker + Vector2(4, -4) * scale_factor,
		marker + Vector2(11, 0) * scale_factor, marker + Vector2(4, 4) * scale_factor, marker + Vector2(0, 13) * scale_factor,
		marker + Vector2(-4, 4) * scale_factor, marker + Vector2(-11, 0) * scale_factor, marker + Vector2(-4, -4) * scale_factor])
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.25, 0.96, 0.91, 0.12), 9 * scale_factor, true)
	draw_polyline(outline, Color(0.25, 0.96, 0.91, 0.18), 6 * scale_factor, true)
	draw_colored_polygon(points, Color("eaffef"))
	draw_polyline(outline, Color("075d6c"), 4 * scale_factor, true)
	draw_polyline(outline, Color("53eee4"), 1.3 * scale_factor, true)

func _ribbon(center: Vector2, radius: float, scale_factor: float) -> void:
	var width := maxf(104.0, 145 * scale_factor)
	var height := maxf(18.0, 21 * scale_factor)
	var top := center.y + radius + 5 * scale_factor
	var left := center.x - width / 2
	var right := center.x + width / 2
	var points := PackedVector2Array([Vector2(left + 9, top), Vector2(right - 9, top), Vector2(right, top + height / 2),
		Vector2(right - 9, top + height), Vector2(left + 9, top + height), Vector2(left, top + height / 2)])
	draw_colored_polygon(points, Color("073b45"))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color("29b9ad"), 1.7 * scale_factor, true)
	draw_line(Vector2(left + 11, top + 2), Vector2(right - 11, top + 2), Color("91ebd7"), 0.8 * scale_factor, true)
	var font_size := maxi(10, roundi(13 * scale_factor))
	var text := "YOU ARE HERE"
	var text_extent := LABEL_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(LABEL_FONT, Vector2(center.x - text_extent.x / 2, top + height * 0.72), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("e6f9e5"))
