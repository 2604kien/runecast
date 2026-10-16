extends Control
## Independent overlays compose selection, keyboard focus and availability.
## Board decorations are limited to corners, leaving exact edge ports clear.
var states: Dictionary = {}
var board := false
var observed_control: Control
const CREAM := Color("fff0c5")
const TEAL := Color("64f0dd")
const GOLD := Color("edbc66")
const ALERT := Color("ffac88")
const ENERGY = preload("res://assets/icons/resources/energy.svg")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	if observed_control:
		observed_control.focus_entered.connect(queue_redraw)
		observed_control.focus_exited.connect(queue_redraw)
		if observed_control is Range:
			observed_control.value_changed.connect(func(_value: float): queue_redraw())

func _corners(inset: float, length: float, colour: Color, line_width: float) -> void:
	for corner in [Vector2(inset, inset), Vector2(size.x - inset, inset), Vector2(inset, size.y - inset), size - Vector2(inset, inset)]:
		var direction := Vector2(1 if corner.x < size.x / 2 else -1, 1 if corner.y < size.y / 2 else -1)
		draw_line(corner, corner + Vector2(length * direction.x, 0), colour, line_width, true)
		draw_line(corner, corner + Vector2(0, length * direction.y), colour, line_width, true)

func _badge_rect() -> Rect2:
	var bounds := Rect2(Vector2.ZERO, size)
	if observed_control != null:
		var painted_bounds = observed_control.get_meta("rc_state_rect", bounds)
		if painted_bounds is Rect2:
			return bounds.intersection(painted_bounds.abs())
	return bounds

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	if observed_control is HSlider:
		var ratio: float = (observed_control.value - observed_control.min_value) / maxf(1.0, observed_control.max_value - observed_control.min_value)
		var p := Vector2(8 + (size.x - 16) * ratio, size.y * 0.5)
		draw_circle(p, 10, Color("101d2b"))
		draw_texture_rect(ENERGY, Rect2(p - Vector2(13, 13), Vector2(26, 26)), false)
	var selected := bool(states.get("selected", false))
	var focused := bool(states.get("focused", false)) or (observed_control != null and observed_control.has_focus())
	if states.get("powered", false) and not (observed_control != null and observed_control.get_meta("rc_clean_board", false)):
		_corners(11, minf(size.x, size.y) * 0.14, GOLD, 3)
	if selected:
		_corners(4, minf(size.x, size.y) * 0.22, TEAL, 2)
		# A filled corner notch remains distinguishable without colour.
		draw_colored_polygon(PackedVector2Array([Vector2(4, 4), Vector2(18, 4), Vector2(4, 18)]), TEAL)
	if focused:
		# Dashes stay in corner quarters on sockets, never across a port channel.
		var length := minf(size.x, size.y) * 0.24 if board else minf(size.x, size.y) * 0.42
		for i in range(0, int(length), 8):
			for corner in [Vector2(1, 1), Vector2(size.x - 1, 1), Vector2(1, size.y - 1), size - Vector2(1, 1)]:
				var dir := Vector2(1 if corner.x < size.x / 2 else -1, 1 if corner.y < size.y / 2 else -1)
				draw_line(corner + Vector2(i * dir.x, 0), corner + Vector2((i + 4) * dir.x, 0), CREAM, 2, true)
				draw_line(corner + Vector2(0, i * dir.y), corner + Vector2(0, (i + 4) * dir.y), CREAM, 2, true)
	# Badge placement follows the painted active body when it is smaller than
	# its hit target. Selection and focus still describe the full control.
	if observed_control != null and not observed_control.get_meta("rc_show_state_badges", true):
		return
	var badge_bounds := _badge_rect()
	var badge_scale := minf(1.0, minf(badge_bounds.size.x, badge_bounds.size.y) / 22.0)
	if badge_scale <= 0:
		return
	var badge_inset := Vector2(minf(11, badge_bounds.size.x / 2), minf(11, badge_bounds.size.y / 2))
	if states.get("invalid", false):
		var p := Vector2(badge_bounds.end.x - badge_inset.x, badge_bounds.position.y + badge_inset.y)
		draw_circle(p, 8 * badge_scale, Color("231d29"))
		draw_line(p - Vector2(4, 4) * badge_scale, p + Vector2(4, 4) * badge_scale, ALERT, 2 * badge_scale, true)
		draw_line(p + Vector2(-4, 4) * badge_scale, p + Vector2(4, -4) * badge_scale, ALERT, 2 * badge_scale, true)
	if states.get("unavailable", false) or states.get("disabled", false):
		var p := badge_bounds.end - badge_inset
		draw_circle(p, 8 * badge_scale, Color("172330"))
		draw_arc(p, 6 * badge_scale, 0, TAU, 24, CREAM, 1.5 * badge_scale, true)
		draw_line(p + Vector2(-4, 4) * badge_scale, p + Vector2(4, -4) * badge_scale, CREAM, 1.5 * badge_scale, true)
