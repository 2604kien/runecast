extends Control
## Transparent live paths over the separate reusable parchment surface.
## The view supplies coordinates and detached states; no route logic lives here.
var points: Dictionary = {}
var nodes: Dictionary = {}
var edges: Array = []
var radii: Dictionary = {}
# Retained as a display palette, not a painted runtime background.
const PAPER := Color("d8c39a")
const INK := Color("122636")

func _draw() -> void:
	var line_scale := clampf(size.x / 680.0, 0.65, 1.0)
	for edge in edges:
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if not points.has(from_id) or not points.has(to_id): continue
		var from: Vector2 = points[from_id]
		var to: Vector2 = points[to_id]
		var state := str(nodes.get(to_id, {}).get("state", "locked"))
		var from_state := str(nodes.get(from_id, {}).get("state", "locked"))
		var available := state == "available" and from_state in ["visited", "current"]
		var travelled := from_state == "visited" and state in ["visited", "current"]
		var direction := (to - from).normalized()
		from += direction * float(radii.get(from_id, 28.0))
		to -= direction * float(radii.get(to_id, 28.0))
		if from.distance_to(to) < 2.0: continue
		if available or travelled:
			for width in [11.0, 7.0]:
				draw_line(from, to, Color(1.0, 0.62, 0.06, 0.09), width * line_scale, true)
			draw_line(from, to, Color("ce922a"), 4.3 * line_scale, true)
			draw_line(from, to, Color("ffcf62"), 2.5 * line_scale, true)
			if available:
				draw_dashed_line(from, to, Color("fff9c7"), 1.5 * line_scale, 9.0 * line_scale, true)
			else:
				draw_line(from, to, Color("fff0b1"), 1.0 * line_scale, true)
		else:
			var dimmed := bool(nodes.get(from_id, {}).get("subdued", false)) or bool(nodes.get(to_id, {}).get("subdued", false))
			var colour := Color(0.12, 0.17, 0.20, 0.36 if dimmed else 0.82)
			draw_dashed_line(from, to, colour, 2.2 * line_scale, 10.0 * line_scale, true)
