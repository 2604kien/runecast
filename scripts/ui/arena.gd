extends Control
var enemy_hp := 32
var enemy_max_hp := 32
var attack := 8
var battle_state := "playing"

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(size.x / 680.0, size.y / 300.0))
	draw_rect(Rect2(0, 0, 680, 300), Color("#111c32"))
	for i in range(8):
		var x := float(i * 100 - 25)
		draw_rect(Rect2(x, 20, 38, 205), Color("#253953"))
		draw_line(Vector2(x, 225), Vector2(x + 15, 25), Color("#3a4d68"), 3)
	for i in range(5):
		draw_line(Vector2(0, 230 + i * 17), Vector2(680, 230 + i * 17), Color("#354056"), 2)
	for x in [65, 150, 530, 610]:
		draw_rect(Rect2(x, 195, 9, 27), Color("#d3aa70"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 195), Vector2(x + 5, 170), Vector2(x + 13, 195)]), Color("#ffc568"))
	draw_ellipse_shadow()
	# Deliberately simple vector stand-in; final painted art has its own production milestone.
	draw_colored_polygon(PackedVector2Array([Vector2(340, 72), Vector2(305, 119), Vector2(287, 220), Vector2(317, 207), Vector2(338, 233), Vector2(354, 207), Vector2(386, 221), Vector2(375, 122)]), Color("#4d354e"))
	draw_polyline(PackedVector2Array([Vector2(340, 72), Vector2(305, 119), Vector2(287, 220), Vector2(317, 207), Vector2(338, 233), Vector2(354, 207), Vector2(386, 221), Vector2(375, 122), Vector2(340, 72)]), Color("#090e1d"), 6, true)
	draw_colored_polygon(PackedVector2Array([Vector2(319, 103), Vector2(344, 92), Vector2(359, 111), Vector2(340, 143)]), Color("#e6d4a0"))
	draw_circle(Vector2(330, 115), 5, Color("#f4a640"))
	draw_circle(Vector2(348, 112), 5, Color("#f4a640"))
	draw_line(Vector2(308, 137), Vector2(270, 157), Color("#9c6c67"), 11, true)
	draw_line(Vector2(270, 157), Vector2(265, 185), Color("#bb9b58"), 3, true)
	draw_rect(Rect2(249, 183, 30, 33), Color("#c89541"))
	draw_rect(Rect2(256, 188, 16, 23), Color("#ffcf68"))
	var font := get_theme_default_font()
	_text(font, "ATTACK %d" % attack if battle_state == "playing" else battle_state.to_upper(), 48, 24, Color("#ff9d89"))
	_text(font, "SHADELING", 260, 19, Color("#f1dfb6"))
	draw_rect(Rect2(239, 273, 202, 18), Color("#522438"))
	draw_rect(Rect2(240, 274, 200.0 * float(enemy_hp) / enemy_max_hp, 16), Color("#c95563"))
	_text(font, "%d / %d" % [enemy_hp, enemy_max_hp], 288, 15, Color.WHITE)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(340, 227), 0, Vector2(1, 0.15))
	draw_circle(Vector2.ZERO, 56, Color("#080d19"))
	draw_set_transform(Vector2.ZERO, 0, Vector2(size.x / 680.0, size.y / 300.0))

func _text(font: Font, value: String, y: float, font_size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((680 - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

