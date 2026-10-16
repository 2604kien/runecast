extends Control
## The two approved piles have distinct silhouettes and painted emblems.
## Preserve those original pixels at one uniform scale; only their numerals
## are cleared for the live counter. Text labels are separate live controls.

const ATLAS = preload("res://assets/ui/combat/reference/approved-atlas.png")
const ATLAS_SIZE := Vector2(841, 1870)
const SOURCES := {
	"draw": {
		"body": Rect2(25, 1418, 95, 136),
		"front": Rect2(30, 1442, 70, 108),
		"glyph": Rect2(39, 1459, 50, 60),
		"count": Rect2(45, 1521, 42, 32),
		"numeral": Rect2(56, 1525, 21, 23),
		"material": Rect2(50, 1527, 5, 18),
		"silhouette": [
			Vector2(55, 1418), Vector2(115, 1418), Vector2(120, 1423),
			Vector2(120, 1532), Vector2(107, 1545), Vector2(87, 1554),
			Vector2(46, 1554), Vector2(27, 1547), Vector2(25, 1541),
			Vector2(25, 1449), Vector2(35, 1439), Vector2(45, 1429),
		],
	},
	"discard": {
		"body": Rect2(725, 1423, 91, 132),
		"front": Rect2(747, 1444, 66, 107),
		"glyph": Rect2(762, 1470, 33, 42),
		"count": Rect2(755, 1521, 43, 33),
		"numeral": Rect2(766, 1525, 21, 23),
		"material": Rect2(789, 1527, 5, 18),
		"silhouette": [
			Vector2(730, 1423), Vector2(791, 1423), Vector2(801, 1434),
			Vector2(811, 1444), Vector2(816, 1451), Vector2(816, 1546),
			# The old DISCARD caption begins on source row1554. Stop at
			# its upper boundary so that row is outside the painted mask.
			Vector2(810, 1553), Vector2(798, 1554), Vector2(755, 1554),
			Vector2(743, 1548), Vector2(735, 1539), Vector2(725, 1530),
			Vector2(725, 1429),
		],
	},
}

var pile_kind := "draw":
	set(value):
		pile_kind = "discard" if value == "discard" else "draw"
		queue_redraw()
var kind := "deck"
var tint := Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
var texture: Texture2D:
	get:
		return ATLAS

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

func _ready() -> void:
	resized.connect(queue_redraw)

func get_geometry() -> Dictionary:
	var source: Dictionary = SOURCES[pile_kind]
	var body: Rect2 = source.body
	# The existing 72x139 interaction target reserves its last 20px for the
	# live caption. Center the unstretched body in the remaining art lane.
	var lane := Vector2(size.x, maxf(0, size.y - 20))
	var scale_factor := minf(lane.x / body.size.x, lane.y / body.size.y)
	var extent := body.size * scale_factor
	var destination := Rect2((lane - extent) * 0.5, extent)
	return {
		"kind": kind, "pile_kind": pile_kind, "sliced": false,
		"source_rect": body, "reference_rect": body,
		"destination_rect": destination, "scale_factor": scale_factor,
		"source_front_rect": source.front,
		"front_rect": _map(source.front, body, destination, scale_factor),
		"source_glyph_rect": source.glyph,
		"glyph_rect": _map(source.glyph, body, destination, scale_factor),
		"source_count_rect": source.count,
		"count_rect": _map(source.count, body, destination, scale_factor),
		"source_numeral_rect": source.numeral,
		"numeral_rect": _map(source.numeral, body, destination, scale_factor),
		"material_rect": source.material,
		"silhouette": source.silhouette,
	}

func get_front_face_rect() -> Rect2:
	return get_geometry().front_rect

func _map(source: Rect2, body: Rect2, destination: Rect2, scale_factor: float) -> Rect2:
	return Rect2(destination.position + (source.position - body.position) * scale_factor, source.size * scale_factor)

func _draw() -> void:
	if size.x < 2 or size.y < 2: return
	var geometry := get_geometry()
	var body: Rect2 = geometry.source_rect
	var destination: Rect2 = geometry.destination_rect
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for point in geometry.silhouette:
		points.append(destination.position + (point - body.position) * geometry.scale_factor)
		uvs.append(point / ATLAS_SIZE)
	draw_colored_polygon(points, tint, uvs, ATLAS)
	# Replace only the old numeral and its dark outline. The entire original
	# gold plaque rim, face texture, compass/skull and stacked edges survive.
	var ratio := Vector2(ATLAS.get_size()) / ATLAS_SIZE
	var material: Rect2 = geometry.material_rect
	draw_texture_rect_region(ATLAS, geometry.numeral_rect, Rect2(material.position * ratio, material.size * ratio), tint)
