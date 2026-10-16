extends Control
## Clean architecture samples from the approved painting, behind live controls.
## Never draws the complete reference or any text, cards, values or circuits.
const ATLAS = preload("res://assets/ui/combat/reference/approved-atlas.png")
const UNDERPAINT = preload("res://assets/ui/combat/backdrop.png")

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var k := size.x / 841.0
	# Existing clean environment underpaint fills areas hidden by reference UI.
	# Original outside scenery below replaces its visible page edges.
	draw_texture_rect(UNDERPAINT, Rect2(Vector2.ZERO, size), false)
	# Header has an unmarked dark recess; title/location are separate controls.
	draw_texture_rect_region(ATLAS, Rect2(0, 0, size.x, 60 * k), Rect2(310, 2, 132, 36))
	# Narrow outside strips contain only rock and candles. They follow the page
	# height on scrollable layouts and the original proportions on portrait.
	draw_texture_rect_region(ATLAS, Rect2(0, 0, 24 * k, size.y), Rect2(0, 0, 24, 1870))
	# x818 includes the original board's lower gold point. It also left a
	# subpixel seam beside the live board where the underpaint candle shone
	# through as a second bright rail. Use only the exterior rock columns and
	# overlap the live frame by a pixel so filtering cannot reveal that seam.
	var right_width := 24 * k + 1
	draw_texture_rect_region(ATLAS, Rect2(size.x - right_width, 0, right_width, size.y), Rect2(824, 0, 17, 1870))
	var vertical := size.y / 1870.0
	draw_texture_rect_region(ATLAS, Rect2(0, 1585 * vertical, 40 * k, 190 * vertical), Rect2(0, 1585, 40, 190))
	draw_texture_rect_region(ATLAS, Rect2(size.x - 36 * k, 1585 * vertical, 36 * k, 190 * vertical), Rect2(805, 1585, 36, 190))
