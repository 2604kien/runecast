extends Control
## Live ink silhouettes, independent of node and route state.
## RC-041 can replace these shapes without changing input or route ownership.
const SYMBOL_FONT = preload("res://assets/fonts/combat/display.tres")
var family := "normal"
var role := ""
var ink := Color("102738")
var cutout := Color("dac59a")

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(64, 64))
	if role == "guardian":
		_guardian()
	elif role == "boss":
		_shadeling()
	elif family == "elite":
		_horned_skull()
	elif family == "normal":
		_sword(Vector2(13, 11), Vector2(50, 51))
		_sword(Vector2(51, 11), Vector2(14, 51))
	elif family == "shop":
		_pouch()
	elif family == "recovery":
		_fire()
	else:
		var text_size := SYMBOL_FONT.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 56)
		draw_string(SYMBOL_FONT, Vector2(32 - text_size.x / 2, 51), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, ink)

func _guardian() -> void:
	# The long hood and skull distinguish the guardian from Shadeling.
	_poly([Vector2(32, 3), Vector2(45, 16), Vector2(51, 39), Vector2(57, 52), Vector2(43, 57), Vector2(37, 49), Vector2(32, 62), Vector2(27, 49), Vector2(21, 57), Vector2(7, 52), Vector2(13, 39), Vector2(19, 16)], ink)
	_poly([Vector2(32, 13), Vector2(43, 29), Vector2(45, 43), Vector2(36, 54), Vector2(39, 35), Vector2(32, 26), Vector2(25, 35), Vector2(28, 54), Vector2(19, 43), Vector2(21, 29)], cutout)
	_poly([Vector2(24, 32), Vector2(32, 27), Vector2(40, 32), Vector2(39, 42), Vector2(35, 45), Vector2(32, 57), Vector2(29, 45), Vector2(25, 42)], cutout)
	_poly([Vector2(25, 34), Vector2(31, 36), Vector2(28, 40), Vector2(25, 39)], ink)
	_poly([Vector2(39, 34), Vector2(33, 36), Vector2(36, 40), Vector2(39, 39)], ink)
	_poly([Vector2(32, 39), Vector2(35, 44), Vector2(29, 44)], ink)
	draw_line(Vector2(20, 19), Vector2(16, 36), cutout, 1.1, true)
	draw_line(Vector2(44, 19), Vector2(48, 36), cutout, 1.1, true)

func _shadeling() -> void:
	_poly([Vector2(33, 8), Vector2(44, 20), Vector2(45, 34), Vector2(51, 48), Vector2(43, 47), Vector2(40, 55), Vector2(29, 51), Vector2(19, 55), Vector2(12, 50), Vector2(20, 36), Vector2(21, 21)], ink)
	_poly([Vector2(33, 17), Vector2(39, 26), Vector2(37, 35), Vector2(27, 35), Vector2(25, 27)], cutout)
	draw_line(Vector2(27, 27), Vector2(30, 29), ink, 2.8, true)
	draw_line(Vector2(34, 29), Vector2(37, 27), ink, 2.8, true)
	draw_line(Vector2(32, 39), Vector2(29, 47), cutout, 1.5, true)
	# Lantern is an identity cue, not an encounter mechanic.
	draw_line(Vector2(45, 33), Vector2(51, 38), ink, 3, true)
	draw_arc(Vector2(51, 41), 4, PI, TAU, 12, ink, 2, true)
	draw_rect(Rect2(47, 41, 8, 12), ink)
	draw_rect(Rect2(49, 43, 4, 7), cutout)

func _horned_skull() -> void:
	_poly([Vector2(14, 29), Vector2(7, 22), Vector2(6, 12), Vector2(13, 19), Vector2(21, 20), Vector2(25, 24), Vector2(39, 24), Vector2(43, 20), Vector2(51, 19), Vector2(58, 12), Vector2(57, 22), Vector2(50, 29), Vector2(47, 41), Vector2(40, 46), Vector2(39, 52), Vector2(25, 52), Vector2(24, 46), Vector2(17, 41)], ink)
	_poly([Vector2(20, 32), Vector2(29, 35), Vector2(25, 41), Vector2(20, 39)], cutout)
	_poly([Vector2(44, 32), Vector2(35, 35), Vector2(39, 41), Vector2(44, 39)], cutout)
	_poly([Vector2(32, 39), Vector2(36, 45), Vector2(28, 45)], cutout)
	for x in [29.0, 35.0]: draw_line(Vector2(x, 48), Vector2(x, 53), cutout, 1.7, true)

func _pouch() -> void:
	_poly([Vector2(22, 9), Vector2(27, 12), Vector2(32, 10), Vector2(37, 12), Vector2(43, 9), Vector2(38, 23), Vector2(45, 31), Vector2(51, 43), Vector2(49, 51), Vector2(40, 55), Vector2(24, 55), Vector2(15, 51), Vector2(13, 43), Vector2(19, 31), Vector2(26, 23)], ink)
	draw_line(Vector2(24, 22), Vector2(40, 22), cutout, 2.2, true)
	draw_line(Vector2(23, 26), Vector2(41, 26), cutout, 1.5, true)
	var text_size := SYMBOL_FONT.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(SYMBOL_FONT, Vector2(32 - text_size.x / 2, 49), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, cutout)
	draw_arc(Vector2(31, 42), 14, PI * 0.82, PI * 1.18, 10, cutout, 1.2, true)

func _fire() -> void:
	_poly([Vector2(32, 3), Vector2(38, 16), Vector2(37, 26), Vector2(44, 20), Vector2(43, 14), Vector2(50, 29), Vector2(48, 39), Vector2(42, 46), Vector2(22, 46), Vector2(15, 38), Vector2(14, 29), Vector2(21, 18), Vector2(20, 29), Vector2(25, 33), Vector2(23, 20), Vector2(29, 11)], ink)
	_poly([Vector2(32, 24), Vector2(37, 32), Vector2(36, 39), Vector2(40, 36), Vector2(37, 43), Vector2(27, 43), Vector2(24, 36), Vector2(29, 39), Vector2(28, 33)], cutout)
	_poly([Vector2(11, 47), Vector2(13, 43), Vector2(53, 56), Vector2(51, 61)], ink)
	_poly([Vector2(51, 43), Vector2(53, 47), Vector2(13, 61), Vector2(11, 56)], ink)

func _sword(tip: Vector2, hilt: Vector2) -> void:
	var axis := (hilt - tip).normalized()
	var normal := Vector2(-axis.y, axis.x)
	_poly([tip, tip + axis * 12 + normal * 5, hilt - axis * 13 + normal * 3, hilt - axis * 13 - normal * 3, tip + axis * 12 - normal * 5], ink)
	draw_line(hilt - axis * 13 - normal * 7, hilt - axis * 13 + normal * 7, ink, 4, true)
	draw_line(hilt - axis * 12, hilt, ink, 4, true)
	draw_circle(hilt, 2.6, ink)
	draw_line(tip + axis * 8, hilt - axis * 17, cutout, 0.8, true)

func _poly(vertices: Array, colour: Color) -> void:
	draw_colored_polygon(PackedVector2Array(vertices), colour)
