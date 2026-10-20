extends Control
## October 15 owner direction adopts the approved painting itself. The atlas is
## byte-identical to that painting, but no complete screen or text-bearing panel
## is drawn. Only clean sockets, decorative rims and unmarked material patches
## are sampled here. Labels, values, symbols, paths and hit targets stay live.
## The status frame is a generated painted PNG; code only places its pixels.

const ATLAS = preload("res://assets/ui/combat/reference/approved-atlas.png")
const ATLAS_SIZE := Vector2(841, 1870)
const STATS_FRAME = preload("res://assets/ui/combat/reference/status-frame.png")
const STATS_FRAME_SIZE := Vector2(1987, 791)
const STATS_FRAME_REGION := Rect2(20, 270, 1948, 232)
const STATS_FRAME_COLUMNS := [20.0, 683.5, 1302.5, 1968.0]
const STATS_FRAME_ROWS := [270.0, 314.0, 458.0, 502.0]
const TEXTURES := {
	"board": ATLAS, "socket": ATLAS, "stats": STATS_FRAME, "toolbar": ATLAS,
	"forecast": ATLAS, "nav": ATLAS, "ribbon": ATLAS, "parchment": ATLAS,
	"card_damage": ATLAS, "card_shield": ATLAS,
	"card_technique": ATLAS, "card_mixed": ATLAS, "button": ATLAS,
	"cast": ATLAS, "heading": ATLAS, "caption": ATLAS, "health": ATLAS,
}

## Original 841x1870 source pixels. A region is the outer decorative envelope;
## its middle is never sampled wholesale unless it is the clean empty socket.
const REGIONS := {
	"board": Rect2(18, 570, 805, 685),
	"socket": Rect2(94, 797, 163, 143),
	"stats": Rect2(22, 510, 795, 69),
	"toolbar": Rect2(21, 1248, 801, 129),
	"forecast": Rect2(40, 1581, 762, 79),
	"nav": Rect2(43, 1778, 758, 91),
	"ribbon": Rect2(132, 579, 576, 59),
	"parchment": Rect2(651, 525, 133, 42),
	"card_damage": Rect2(143, 1404, 178, 177),
	"card_shield": Rect2(330, 1404, 177, 177),
	"card_technique": Rect2(518, 1404, 176, 177),
	# The approved screen has no separate mixed-card painting. Its violet
	# frame is the shared reference material; the live rune defines the role.
	"card_mixed": Rect2(518, 1404, 176, 177),
	"button": Rect2(605, 1268, 86, 69),
	"cast": Rect2(126, 1663, 588, 88),
	"heading": Rect2(46, 48, 663, 10),
	"caption": Rect2(43, 1736, 760, 46),
	"health": Rect2(308, 455, 222, 35),
}
const MATERIALS := {
	"board": Rect2(113, 819, 125, 103),
	"stats": Rect2(221, 530, 45, 27),
	"toolbar": Rect2(55, 1265, 79, 13),
	"forecast": Rect2(264, 1598, 64, 21),
	"nav": Rect2(243, 1793, 40, 48),
	"ribbon": Rect2(151, 594, 67, 25),
	"parchment": Rect2(659, 535, 13, 22),
	"card_damage": Rect2(161, 1457, 34, 43),
	"card_shield": Rect2(347, 1451, 39, 49),
	"card_technique": Rect2(535, 1451, 35, 52),
	"card_mixed": Rect2(535, 1451, 35, 52),
	"button": Rect2(616, 1280, 12, 32),
	"cast": Rect2(191, 1678, 103, 59),
	"caption": Rect2(149, 1746, 142, 23),
	"health": Rect2(333, 464, 43, 16),
}
## Actual source border widths, left/top/right/bottom. Text-bearing centers
## are replaced with the corresponding clean patch above, never stretched.
const SOURCE_CAPS := {
	"board": Vector4(27, 9, 29, 13),
	"socket": Vector4(18, 18, 18, 18),
	"stats": Vector4(40, 12, 40, 12),
	"toolbar": Vector4(25, 12, 25, 10),
	"forecast": Vector4(27, 11, 27, 11),
	"nav": Vector4(25, 10, 25, 9),
	"ribbon": Vector4(86, 10, 88, 12),
	"parchment": Vector4(19, 5, 16, 5),
	"card_damage": Vector4(10, 11, 12, 12),
	"card_shield": Vector4(10, 11, 12, 12),
	"card_technique": Vector4(10, 11, 12, 12),
	"card_mixed": Vector4(10, 11, 12, 12),
	"button": Vector4(12, 10, 12, 9),
	"cast": Vector4(65, 15, 65, 14),
	"caption": Vector4(25, 7, 25, 8),
	"health": Vector4(18, 5, 18, 5),
}
const CONTENT_MARGINS := {
	"stats": Vector4(24, 9, 24, 9),
	"toolbar": Vector4(32, 15, 32, 21),
	"slot": Vector4(4, 2, 4, 2),
	"button": Vector4(8, 8, 8, 8),
	"parchment": Vector4(8, 4, 8, 4),
}

# These fields belong to unoccupied cells in the approved artwork. Keep the
# same socket border geometry while avoiding one repeated slate crack pattern.
const SOCKET_MATERIALS := [
	Rect2(112, 815, 127, 107), Rect2(282, 815, 127, 107),
	Rect2(112, 961, 127, 102), Rect2(282, 961, 127, 102),
	Rect2(112, 1103, 127, 106), Rect2(282, 1103, 127, 106),
	Rect2(606, 1103, 125, 106),
]
var socket_variant := 0:
	set(value):
		socket_variant = value
		queue_redraw()

var kind := "panel":
	set(value):
		kind = value
		queue_redraw()
var divisions := 0:
	set(value):
		divisions = value
		queue_redraw()
var completed := true:
	set(value):
		completed = value
		queue_redraw()
var art_scale := 1.0:
	set(value):
		art_scale = maxf(0.25, value)
		queue_redraw()
var fill_ratio := 1.0:
	set(value):
		fill_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
var show_check := true:
	set(value):
		show_check = value
		queue_redraw()
var show_dividers := false:
	set(value):
		show_dividers = value
		queue_redraw()
var tint := Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
var texture: Texture2D:
	get:
		return STATS_FRAME if kind == "stats" else ATLAS

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

func _ready() -> void:
	resized.connect(queue_redraw)

func _asset_kind() -> String:
	if kind in ["pause", "slot"]: return "button"
	return kind if REGIONS.has(kind) else "forecast"

func get_geometry() -> Dictionary:
	if kind == "stats":
		var ratio := Vector2(STATS_FRAME.get_size()) / STATS_FRAME_SIZE
		return {
			"kind": kind, "asset_kind": "stats", "generated_frame": true,
			"source_rect": Rect2(STATS_FRAME_REGION.position * ratio, STATS_FRAME_REGION.size * ratio),
			"source_caps": Vector4(88 * ratio.x, 44 * ratio.y, 88 * ratio.x, 44 * ratio.y),
			"destination_rect": Rect2(Vector2.ZERO, size), "destination_caps": Vector4(24, 8, 24, 8),
			"source_rim_caps": Vector4.ZERO, "destination_rim_caps": Vector4.ZERO,
			"sliced": true, "reference_rect": STATS_FRAME_REGION, "reference_caps": Vector4(88, 44, 88, 44),
			"material_rect": Rect2(120, 330, 450, 90), "mask_polygon": PackedVector2Array(),
			"source_columns": STATS_FRAME_COLUMNS, "source_rows": STATS_FRAME_ROWS,
		}
	var asset := _asset_kind()
	var source: Rect2 = REGIONS[asset]
	var source_caps: Vector4 = SOURCE_CAPS.get(asset, Vector4.ZERO)
	var destination := Rect2(Vector2.ZERO, size)
	var destination_caps := source_caps * art_scale
	var material: Rect2 = MATERIALS.get(asset, source)
	if asset == "socket": material = SOCKET_MATERIALS[posmod(socket_variant, SOCKET_MATERIALS.size())]
	var sliced := asset != "heading"
	match asset:
		"board": destination_caps = Vector4(27, 9, 29, 20) * art_scale
		"toolbar": destination_caps = Vector4(28, 12, 28, 12) * art_scale
		"forecast": destination_caps = Vector4(27, 10, 27, 10) * art_scale
		"nav": destination_caps = Vector4(25, 10, 25, 9) * art_scale
		"ribbon": destination_caps = Vector4(86, 9, 88, 10) * art_scale
		"parchment":
			var height := minf(size.y, 55 * art_scale)
			destination = Rect2(0, (size.y - height) * 0.5, size.x, height)
			destination_caps = Vector4(10, 5, 10, 5) * art_scale
		"card_damage", "card_shield", "card_technique", "card_mixed":
			destination_caps = Vector4(10, 11, 12, 12) * art_scale
		"cast": destination_caps = Vector4(57, 12, 57, 12) * art_scale
		"heading":
			destination = Rect2(0, maxf(0, size.y - 8 * art_scale), size.x, 8 * art_scale)
		"health": destination_caps = Vector4(18, 5, 18, 5) * art_scale
	if kind == "pause":
		source = Rect2(724, 3, 80, 60)
		source_caps = Vector4(17, 13, 15, 12)
		material = Rect2(738, 21, 9, 25)
		destination_caps = Vector4(17, 13, 15, 12) * art_scale
	elif kind == "slot":
		source = Rect2(158, 1258, 97, 103)
		source_caps = Vector4(6, 8, 6, 6)
		material = Rect2(171, 1282, 69, 9)
		destination_caps = Vector4(4, 5, 4, 4) * art_scale
	if sliced: destination_caps = _fit_caps(destination_caps, destination.size)
	else:
		source_caps = Vector4.ZERO
		destination_caps = Vector4.ZERO
	var ratio := Vector2(ATLAS.get_size()) / ATLAS_SIZE
	var geometry := {
		"kind": kind, "asset_kind": asset,
		"source_rect": Rect2(source.position * ratio, source.size * ratio),
		"source_caps": source_caps * Vector4(ratio.x, ratio.y, ratio.x, ratio.y),
		"destination_rect": destination, "destination_caps": destination_caps,
		"source_rim_caps": Vector4.ZERO, "destination_rim_caps": Vector4.ZERO,
		"sliced": sliced, "reference_rect": source, "reference_caps": source_caps,
		"material_rect": material,
	}
	# Rectangular atlas corners contain neighboring backdrop and caption paint.
	# Clip those samples to the original artwork silhouette before drawing them.
	var outline := PackedVector2Array()
	if kind == "cast":
		outline = PackedVector2Array([Vector2(126, 1708), Vector2(167, 1663), Vector2(670, 1663), Vector2(714, 1707), Vector2(669, 1751), Vector2(168, 1751)])
	elif kind == "parchment":
		outline = PackedVector2Array([Vector2(660, 525), Vector2(674, 526), Vector2(680, 525), Vector2(747, 525), Vector2(751, 527), Vector2(779, 525), Vector2(783, 535), Vector2(784, 557), Vector2(776, 562), Vector2(777, 567), Vector2(662, 567), Vector2(659, 561), Vector2(652, 559), Vector2(651, 539), Vector2(658, 531)])
	elif kind == "ribbon":
		# Keep the torn emerald silhouette and its original end proportions;
		# the rectangular source also contains dark crypt pixels beside it.
		outline = PackedVector2Array([Vector2(132, 586), Vector2(152, 580), Vector2(195, 579), Vector2(185, 596), Vector2(211, 580), Vector2(707, 580), Vector2(696, 603), Vector2(708, 635), Vector2(677, 635), Vector2(674, 624), Vector2(666, 635), Vector2(648, 633), Vector2(634, 622), Vector2(613, 636), Vector2(213, 636), Vector2(195, 622), Vector2(180, 633), Vector2(164, 622), Vector2(154, 632), Vector2(132, 632), Vector2(140, 611), Vector2(153, 609), Vector2(141, 604)])
	var mask := PackedVector2Array()
	for point in outline:
		mask.append(_map_reference_position(point, geometry))
	geometry["mask_polygon"] = mask
	if kind == "cast":
		# One face must continue into both pointed ends. Replacing just the
		# rectangular nine-slice center leaves a different teal patch in
		# each cap, producing a visible vertical colour seam.
		var inner_source := PackedVector2Array([Vector2(165, 1707), Vector2(190, 1679), Vector2(653, 1679), Vector2(675, 1707), Vector2(651, 1735), Vector2(190, 1735)])
		var inner := PackedVector2Array()
		for point in inner_source:
			inner.append(_map_reference_position(point, geometry))
		geometry["inner_polygon"] = inner
	return geometry

func _map_reference_position(point: Vector2, geometry: Dictionary) -> Vector2:
	var source: Rect2 = geometry.reference_rect
	var destination: Rect2 = geometry.destination_rect
	var sc: Vector4 = geometry.reference_caps
	var dc: Vector4 = geometry.destination_caps
	return destination.position + Vector2(
		_map_slice_axis(point.x - source.position.x, source.size.x, destination.size.x, sc.x, sc.z, dc.x, dc.z),
		_map_slice_axis(point.y - source.position.y, source.size.y, destination.size.y, sc.y, sc.w, dc.y, dc.w))

func _map_slice_axis(value: float, source_extent: float, destination_extent: float, source_begin: float, source_end: float, destination_begin: float, destination_end: float) -> float:
	if value <= source_begin:
		return value * destination_begin / maxf(source_begin, 0.001)
	if value >= source_extent - source_end:
		return destination_extent - (source_extent - value) * destination_end / maxf(source_end, 0.001)
	return destination_begin + (value - source_begin) * (destination_extent - destination_begin - destination_end) / maxf(source_extent - source_begin - source_end, 0.001)

func _fit_caps(caps: Vector4, extent: Vector2) -> Vector4:
	var horizontal := minf(1, maxf(0, extent.x - 1) / maxf(caps.x + caps.z, 1))
	var vertical := minf(1, maxf(0, extent.y - 1) / maxf(caps.y + caps.w, 1))
	return caps * Vector4(horizontal, vertical, horizontal, vertical)

func get_content_rect() -> Rect2:
	var destination: Rect2 = get_geometry().destination_rect
	var inset: Vector4 = CONTENT_MARGINS.get(kind, Vector4.ZERO)
	return Rect2(destination.position + Vector2(inset.x, inset.y), Vector2(maxf(0, destination.size.x - inset.x - inset.z), maxf(0, destination.size.y - inset.y - inset.w)))

func _draw() -> void:
	if size.x < 2 or size.y < 2: return
	var geometry := get_geometry()
	var destination: Rect2 = geometry.destination_rect
	if destination.size.x <= 0 or destination.size.y <= 0: return
	var color := tint
	if kind == "ribbon" and not completed: color *= Color(0.56, 0.65, 0.65, 1)
	if kind == "stats":
		_draw_stats_frame(geometry, color)
	elif kind == "cast":
		_draw_cast_frame(geometry, color)
	elif kind == "health":
		_draw_frame(geometry, color * Color(0.30, 0.20, 0.23, 1))
		if fill_ratio > 0:
			_draw_frame(geometry, color, Rect2(destination.position, Vector2(destination.size.x * fill_ratio, destination.size.y)))
	elif not geometry.sliced:
		if kind == "heading":
			# Cover the complete header lane before its lower gold rule; the
			# clean patch contains no wordmark, location or Pause artwork.
			_sample(Rect2(Vector2.ZERO, size), Rect2(310, 2, 132, 36), color)
		_sample(destination, geometry.reference_rect, color)
	else:
		_draw_frame(geometry, color)
	_draw_live_rules()

func _draw_cast_frame(geometry: Dictionary, color: Color) -> void:
	var outer: PackedVector2Array = geometry.mask_polygon
	var inner: PackedVector2Array = geometry.inner_polygon
	# Share the same texture coordinates across the complete pointed face.
	# The original gold rim and cyan bevel remain a separate painted ring.
	var source: Rect2 = geometry.reference_rect
	var destination: Rect2 = geometry.destination_rect
	var sc: Vector4 = geometry.reference_caps
	var dc: Vector4 = geometry.destination_caps
	var face := Rect2(destination.position + Vector2(0, dc.y), Vector2(destination.size.x, destination.size.y - dc.y - dc.w))
	_sample(face, geometry.material_rect, color, Rect2(), inner)
	var sx := [source.position.x, source.position.x + sc.x, source.end.x - sc.z, source.end.x]
	var sy := [source.position.y, source.position.y + sc.y, source.end.y - sc.w, source.end.y]
	var dx := [destination.position.x, destination.position.x + dc.x, destination.end.x - dc.z, destination.end.x]
	var dy := [destination.position.y, destination.position.y + dc.y, destination.end.y - dc.w, destination.end.y]
	for edge in outer.size():
		var next := (edge + 1) % outer.size()
		var rim := PackedVector2Array([outer[edge], outer[next], inner[next], inner[edge]])
		for y in 3:
			for x in 3:
				var target := Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y])
				var sample := Rect2(sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y])
				if x == 1 and y > 0:
					# The original crystal and its shadow reach the lower cyan
					# bevel. Continue a clean unlettered strip at the same source
					# height instead of retaining those baked cost pixels.
					sample = Rect2(191, sy[y], 103, sy[y + 1] - sy[y])
				_sample(target, sample, color, Rect2(), rim)

func _draw_stats_frame(geometry: Dictionary, color: Color) -> void:
	# The entire frame, slate and dividers are generated artwork. Split the
	# image at its painted divider centers to align the three live cells.
	# Vertical slices preserve clear space for the existing 36px text lane.
	var ratio := Vector2(STATS_FRAME.get_size()) / STATS_FRAME_SIZE
	var dx := [0.0, size.x / 3.0, size.x * 2.0 / 3.0, size.x]
	var dy := [0.0, 8.0, size.y - 8.0, size.y]
	for y in 3:
		for x in 3:
			var target := Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y])
			var source := Rect2(STATS_FRAME_COLUMNS[x], STATS_FRAME_ROWS[y], STATS_FRAME_COLUMNS[x + 1] - STATS_FRAME_COLUMNS[x], STATS_FRAME_ROWS[y + 1] - STATS_FRAME_ROWS[y])
			draw_texture_rect_region(STATS_FRAME, target, Rect2(source.position * ratio, source.size * ratio), color)

func _draw_frame(geometry: Dictionary, color: Color, clip := Rect2()) -> void:
	var source: Rect2 = geometry.reference_rect
	var destination: Rect2 = geometry.destination_rect
	var sc: Vector4 = geometry.reference_caps
	var dc: Vector4 = geometry.destination_caps
	var sx := [source.position.x, source.position.x + sc.x, source.end.x - sc.z, source.end.x]
	var sy := [source.position.y, source.position.y + sc.y, source.end.y - sc.w, source.end.y]
	var dx := [destination.position.x, destination.position.x + dc.x, destination.end.x - dc.z, destination.end.x]
	var dy := [destination.position.y, destination.position.y + dc.y, destination.end.y - dc.w, destination.end.y]
	for y in 3:
		for x in 3:
			var target := Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y])
			var sample := Rect2(sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y])
			var mirror_sample_x := false
			if x == 1 and y == 1:
				if kind == "board":
					# The full source face is used at approximately its native
					# brush scale. Most joins sit behind the live socket grid.
					_sample_stone(target, geometry.material_rect, color, clip)
					continue
				# Keep the complete clean painted patch. Cover-cropping a
				# narrow strip previously magnified only a few pixel rows into
				# an almost flat field, losing the original brush variation.
				sample = geometry.material_rect
			elif kind.begins_with("card_") and y == 0:
				# Cost badges obscure the painted upper-left corner in the
				# supplied image. Mirror its clean upper-right counterpart so
				# the upper and side rims meet in the same orientation. The
				# old lower-left sample included below-frame background and
				# put the bottom bevel in this upper corner, leaving a gap.
				if x == 0:
					sample = Rect2(source.end.x - sc.z, source.position.y, sc.z, sc.y)
					mirror_sample_x = true
				elif x == 1: sample = Rect2(source.position.x + 47, source.position.y, source.size.x - 47 - sc.z, sc.y)
			elif kind.begins_with("card_") and x == 0 and y == 1:
				# The blue cost badge also overlaps the first few pixels of
				# the upper left edge; reuse its clean lower continuation.
				sample = Rect2(source.position.x, source.position.y + 53, sc.x, source.size.y - 53 - sc.w)
			elif kind == "forecast" and x == 1 and y == 2:
				# Incoming has descenders just above the source bottom rim.
				# The left section contains the same trim and no red letters.
				sample = Rect2(90, 1649, 200, 11)
			elif kind == "toolbar" and x == 0 and y == 1:
				# The original WIRING parchment starts at x42. The nominal
				# 25px left cap reached x46 and stretched its gold edge into
				# an orphan line beside the live Pass button. Keep only the
				# clean border/inner-slate columns to the left of that paper.
				sample = Rect2(21, 1260, 20, 107)
			_sample(target, sample, color, clip, geometry.mask_polygon, mirror_sample_x)

func _sample_stone(destination: Rect2, source: Rect2, color: Color, clip: Rect2) -> void:
	var pitch := Vector2(163, 143) * art_scale
	var origin := Vector2(70, 73) * art_scale
	while origin.x > destination.position.x: origin.x -= pitch.x
	while origin.y > destination.position.y: origin.y -= pitch.y
	var rows := ceili((destination.end.y - origin.y) / pitch.y)
	var columns := ceili((destination.end.x - origin.x) / pitch.x)
	var crop := destination.intersection(clip) if clip.has_area() else destination
	for row in rows:
		for column in columns:
			_sample(Rect2(origin + Vector2(column, row) * pitch, pitch), source, color * Color(0.68, 0.72, 0.80, 1), crop)

func _sample(destination: Rect2, source: Rect2, color: Color, clip := Rect2(), mask := PackedVector2Array(), mirror_x := false) -> void:
	if destination.size.x <= 0 or destination.size.y <= 0: return
	if clip.has_area():
		var overlap := destination.intersection(clip)
		if not overlap.has_area(): return
		var fraction := (overlap.position - destination.position) / destination.size
		if mirror_x:
			fraction.x = 1.0 - fraction.x - overlap.size.x / destination.size.x
		source = Rect2(source.position + source.size * fraction, source.size * overlap.size / destination.size)
		destination = overlap
	var ratio := Vector2(ATLAS.get_size()) / ATLAS_SIZE
	if not mask.is_empty() or mirror_x:
		var rectangle := PackedVector2Array([destination.position, Vector2(destination.end.x, destination.position.y), destination.end, Vector2(destination.position.x, destination.end.y)])
		var polygons: Array[PackedVector2Array] = [rectangle]
		if not mask.is_empty():
			polygons = Geometry2D.intersect_polygons(rectangle, mask)
		for polygon in polygons:
			var uvs := PackedVector2Array()
			for point in polygon:
				var fraction := (point - destination.position) / destination.size
				if mirror_x:
					fraction.x = 1.0 - fraction.x
				uvs.append((source.position + fraction * source.size) / ATLAS_SIZE)
			draw_polygon(polygon, PackedColorArray([color]), uvs, ATLAS)
		return
	draw_texture_rect_region(ATLAS, destination, Rect2(source.position * ratio, source.size * ratio), color)

func _draw_live_rules() -> void:
	if kind == "stats": return # The generated PNG already contains both dividers.
	var count := divisions
	if count == 0: count = 4 if kind == "nav" else 0
	for i in range(1, count):
		var x := size.x * float(i) / float(count)
		draw_line(Vector2(x, 8 * art_scale), Vector2(x, size.y - 8 * art_scale), Color("090f18") * tint, 2 * art_scale, true)
		draw_line(Vector2(x + art_scale, 8 * art_scale), Vector2(x + art_scale, size.y - 8 * art_scale), Color("887344") * tint, art_scale, true)
	if kind == "ribbon" and show_check and completed:
		var check_scale := art_scale
		var x := size.x * 0.2
		var caption := get_parent() as Label
		if caption != null:
			var font := caption.get_theme_font("font")
			var text_width := font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption.get_theme_font_size("font_size")).x
			var text_left := (caption.size.x - text_width) * 0.5 - position.x - caption.get_theme_constant("outline_size")
			# Keep the full check stroke clear of the centered caption and
			# inside the ribbon, including native narrow-screen layouts.
			var right := minf(x + 26 * art_scale, text_left - 8 * art_scale)
			check_scale = minf(art_scale, maxf(0, right - 10 * art_scale) / 43.0)
			x = right - 26 * check_scale
		var cy := size.y * 0.48
		if check_scale > 0:
			var check := PackedVector2Array([Vector2(x - 12 * check_scale, cy), Vector2(x - 2 * check_scale, cy + 10 * check_scale), Vector2(x + 21 * check_scale, cy - 16 * check_scale)])
			draw_polyline(check, Color("071e19") * tint, 10 * check_scale, true)
			draw_polyline(check, Color("5cff9f") * tint, 7 * check_scale, true)
	if kind == "slot":
		draw_line(Vector2(10 * art_scale, size.y * 0.7), Vector2(size.x - 10 * art_scale, size.y * 0.7), Color("776338") * tint, art_scale, true)
	if show_dividers and kind.begins_with("card_"):
		var accent := Color("dd9225")
		if kind == "card_shield": accent = Color("87c653")
		elif kind == "card_technique": accent = Color("b976e4")
		for fraction in [0.59, 0.735]:
			draw_line(Vector2(15 * art_scale, size.y * fraction), Vector2(size.x - 15 * art_scale, size.y * fraction), accent * tint, art_scale, true)

