extends SceneTree

const Surface = preload("res://scenes/ui/theme/combat_surface.gd")
# Independent approved-atlas measurements. The cyan crest belongs to the rim;
# the replacement face must continue into both tips without a slice seam.
const OUTER := [Vector2(126, 1708), Vector2(167, 1663), Vector2(670, 1663), Vector2(714, 1707), Vector2(669, 1751), Vector2(168, 1751)]
const INNER := [Vector2(165, 1707), Vector2(190, 1679), Vector2(653, 1679), Vector2(675, 1707), Vector2(651, 1735), Vector2(190, 1735)]
const FACE := Rect2(191, 1678, 103, 59)

class RedMaterial:
	extends "res://scenes/ui/theme/combat_surface.gd"
	func get_geometry() -> Dictionary:
		var geometry := super.get_geometry()
		geometry.material_rect = Rect2(333, 464, 43, 16)
		return geometry
var destination := "res://output/qa/rc-016/cast-face-continuity/focused"
var capture_only := false
var checks := 0
var failures := 0
var assertions: Array = []
var measurements: Array = []
var captures: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String, evidence: Variant = null) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": description, "evidence": evidence})
	if not ok:
		failures += 1
		push_error(description + ": " + str(evidence))

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="): destination = argument.trim_prefix("--capture-directory=")
		elif argument == "--capture-only": capture_only = true
	DirAccess.make_dir_recursive_absolute(destination)
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		for built in [false, true]:
			await _actual_scene(dimensions, built)
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "measurements": measurements, "captures": captures, "engine": Engine.get_version_info().string, "scope": "Actual production opening and existing legal Belfry built circuit at three native viewport sizes; Cast crop and production skin."}, "  ") + "\n")
	print("%d focused Cast face checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _actual_scene(dimensions: Vector2i, built: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	if built:
		scene.board_example_id = "board_belfry"
		scene.board_example_step = "built"
	viewport.add_child(scene)
	scene.sound_enabled = false
	await _settle()
	scene.page_scroll.ensure_control_visible(scene.cast_button)
	await _settle()
	var phase := ("built" if built else "opening") + "-%dx%d" % [dimensions.x, dimensions.y]
	_check(scene.startup_error.is_empty() and scene.cast_button.disabled != built, phase + " loads the real " + ("ready" if built else "unavailable") + " Cast state")
	await RenderingServer.frame_post_draw
	var picture: Image = viewport.get_texture().get_image()
	var cast: Rect2 = scene.cast_button.get_global_rect()
	_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(cast), phase + " fully exposes Cast", str(cast))
	var live := picture.get_region(Rect2i(cast))
	_save(live, "cast-live-" + phase)
	var zoom := live.duplicate()
	zoom.resize(live.get_width() * 3, live.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(zoom, "cast-live-" + phase + "-3x")
	var skin: Control = scene.cast_button.get_meta("combat_surface")
	_check(not scene.cast_button.get_meta("rc_show_state_badges", true) and skin.tint == (Color.WHITE if built else Color(0.55, 0.63, 0.68, 1)), phase + " retains the availability tint and suppresses corner badge artwork")
	var isolated: Image = await _render_surface(skin.size, skin.art_scale)
	_save(isolated, "cast-skin-" + phase)
	measurements.append({"phase": phase, "size": str(skin.size), "art_scale": skin.art_scale, "disabled": scene.cast_button.disabled, "forecast": scene.forecast_values})
	if not capture_only:
		await _raster_checks(isolated, skin.size, skin.art_scale, phase)
		# Apply the expected availability colour before GPU output quantization,
		# as in gameplay. Multiplying an already rounded 8-bit white capture
		# introduced an extra rounding error in the unavailable-state oracle.
		var expected_live := isolated if built else await _render_surface(skin.size, skin.art_scale, false, Color(0.55, 0.63, 0.68, 1))
		var live_tips := _live_tip_comparison(live, expected_live, skin.size, skin.art_scale)
		_check(live_tips.samples > 300 and live_tips.maximum_error <= 1.1 / 255.0, phase + " actual painted tips use the corrected skin and expected availability tint", live_tips)
	scene.player.stop()
	scene.player.stream = null
	viewport.queue_free()
	await process_frame

func _render_surface(size: Vector2, brush_scale: float, red: bool = false, color := Color.WHITE) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size.ceil())
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var surface: Control = RedMaterial.new() if red else Surface.new()
	surface.kind = "cast"
	surface.art_scale = brush_scale
	surface.size = size
	surface.tint = color
	viewport.add_child(surface)
	await _settle()
	await RenderingServer.frame_post_draw
	var picture: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return picture

func _raster_checks(picture: Image, size: Vector2, brush_scale: float, phase: String) -> void:
	var face := _face_comparison(picture, size, brush_scale)
	_check(face.left.samples > 100 and face.right.samples > 100 and face.left.maximum_error <= 0.012 and face.right.maximum_error <= 0.012, phase + " both former cap boundaries follow the same continuous whole-face texture sampling", face)
	_check(face.full.samples > 7000 and face.full.maximum_error <= 0.012, phase + " the complete inner face has continuous clean paint, including the lower crystal-shadow region", face.full)
	var red: Image = await _render_surface(size, brush_scale, true)
	_save(red, "cast-red-probe-" + phase)
	var rim := _rim_comparison(picture, red, size, brush_scale)
	_check(rim.samples > 500 and rim.maximum_reference_error <= 0.025 and rim.mean_reference_error <= 0.008, phase + " preserves approved gold and cyan rim pixels independently of the clean face", rim)
	_check(rim.changed_pixels == 0 and rim.changed_face_pixels > 2000, phase + " changing the face to red cannot recolor the preserved rim, while the interior visibly changes", rim)
	measurements.append({"phase": phase, "face": face, "rim": rim})
	var previous_path := "res://output/qa/rc-016/cast-face-continuity/before/cast-skin-" + phase + ".png"
	if FileAccess.file_exists(previous_path):
		var before := Image.load_from_file(previous_path)
		var negative := _face_comparison(before, size, brush_scale)
		_check(negative.left.mean_error > 0.015 and negative.right.mean_error > 0.015, phase + " the same continuous-face oracle rejects the original cap-fragment rendering on both sides", negative)
		measurements.append({"phase": phase, "negative_control": negative})

func _face_comparison(picture: Image, size: Vector2, brush_scale: float) -> Dictionary:
	var atlas: Image = Surface.ATLAS.get_image()
	var result := {}
	var inner := _polygon(INNER, size, brush_scale)
	for name_text in ["left", "right", "full"]:
		var seam := 57 * brush_scale if name_text == "left" else size.x - 57 * brush_scale
		var total := 0.0
		var maximum := 0.0
		var samples := 0
		var rows := range(int(size.y / 2) - 6, int(size.y / 2) + 7) if name_text != "full" else range(int(size.y))
		var columns := range(floori(seam) - 10, floori(seam) + 11) if name_text != "full" else range(int(size.x))
		for y in rows:
			for x in columns:
				var point := Vector2(x + 0.5, y + 0.5)
				if not Geometry2D.is_point_in_polygon(point, inner) or _distance(point, inner) < 1: continue
				var uv := Vector2(point.x / size.x, (point.y - 12 * brush_scale) / (size.y - 24 * brush_scale))
				var expected := _bilinear(atlas, FACE.position + uv * FACE.size - Vector2(0.5, 0.5))
				var error := _error(picture.get_pixel(x, y), expected)
				total += error
				maximum = maxf(maximum, error)
				samples += 1
		result[name_text] = {"samples": samples, "mean_error": total / maxi(samples, 1), "maximum_error": maximum}
	return result

func _rim_comparison(picture: Image, red: Image, size: Vector2, brush_scale: float) -> Dictionary:
	var atlas: Image = Surface.ATLAS.get_image()
	var outer := _polygon(OUTER, size, brush_scale)
	var inner := _polygon(INNER, size, brush_scale)
	var samples := 0
	var total := 0.0
	var maximum := 0.0
	var changed := 0
	var face_changed := 0
	for y in picture.get_height():
		for x in picture.get_width():
			var point := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(point, inner):
				if _distance(point, inner) > 2 and _error(picture.get_pixel(x, y), red.get_pixel(x, y)) > 0.2: face_changed += 1
				continue
			if not Geometry2D.is_point_in_polygon(point, outer) or _distance(point, outer) <= 1 or _distance(point, inner) <= 1: continue
			var source := Vector2(126 + _to_source(point.x, size.x, 588, 65, 65, 57 * brush_scale, 57 * brush_scale), 1663 + _to_source(point.y, size.y, 88, 15, 14, 12 * brush_scale, 12 * brush_scale))
			# The approved center's crystal reaches the lower bevel. The clean
			# unlettered strip preserves its original vertical rim coordinates.
			if point.x > 57 * brush_scale and point.x < size.x - 57 * brush_scale and point.y > 12 * brush_scale:
				source.x = 191 + (point.x - 57 * brush_scale) / (size.x - 114 * brush_scale) * 103
			var expected := _bilinear(atlas, source - Vector2(0.5, 0.5))
			var error := _error(picture.get_pixel(x, y), expected)
			total += error
			maximum = maxf(maximum, error)
			samples += 1
			if _error(picture.get_pixel(x, y), red.get_pixel(x, y)) > 1.1 / 255.0: changed += 1
	return {"samples": samples, "mean_reference_error": total / maxi(samples, 1), "maximum_reference_error": maximum, "changed_pixels": changed, "changed_face_pixels": face_changed}

func _live_tip_comparison(live: Image, skin: Image, size: Vector2, brush_scale: float) -> Dictionary:
	var outer := _polygon(OUTER, size, brush_scale)
	var count := 0
	var maximum := 0.0
	for y in live.get_height():
		for x in live.get_width():
			var point := Vector2(x + 0.5, y + 0.5)
			if x > 57 * brush_scale + 10 and x < size.x - 57 * brush_scale - 10: continue
			if not Geometry2D.is_point_in_polygon(point, outer) or _distance(point, outer) <= 1: continue
			maximum = maxf(maximum, _error(live.get_pixel(x, y), skin.get_pixel(x, y)))
			count += 1
	return {"samples": count, "maximum_error": maximum}

func _polygon(source: Array, size: Vector2, brush_scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in source:
		result.append(Vector2(_to_target(point.x - 126, 588, size.x, 65, 65, 57 * brush_scale, 57 * brush_scale), _to_target(point.y - 1663, 88, size.y, 15, 14, 12 * brush_scale, 12 * brush_scale)))
	return result

func _to_target(value: float, source: float, target: float, first: float, last: float, target_first: float, target_last: float) -> float:
	if value <= first: return value / first * target_first
	if value >= source - last: return target - (source - value) / last * target_last
	return target_first + (value - first) / (source - first - last) * (target - target_first - target_last)

func _to_source(value: float, target: float, source: float, first: float, last: float, target_first: float, target_last: float) -> float:
	if value <= target_first: return value / target_first * first
	if value >= target - target_last: return source - (target - value) / target_last * last
	return first + (value - target_first) / (target - target_first - target_last) * (source - first - last)

func _distance(point: Vector2, polygon: PackedVector2Array) -> float:
	var distance := INF
	for index in polygon.size():
		distance = minf(distance, point.distance_to(Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])))
	return distance

func _error(first: Color, second: Color) -> float:
	return maxf(absf(first.r - second.r), maxf(absf(first.g - second.g), absf(first.b - second.b)))

func _bilinear(picture: Image, point: Vector2) -> Color:
	var x := clampi(floori(point.x), 0, picture.get_width() - 2)
	var y := clampi(floori(point.y), 0, picture.get_height() - 2)
	return picture.get_pixel(x, y).lerp(picture.get_pixel(x + 1, y), point.x - x).lerp(picture.get_pixel(x, y + 1).lerp(picture.get_pixel(x + 1, y + 1), point.x - x), point.y - y)

func _save(picture: Image, name_text: String) -> void:
	var path := destination.path_join(name_text + ".png")
	_check(picture.save_png(path) == OK, "Saved " + name_text)
	captures.append(path)

func _settle() -> void:
	for frame in range(5): await process_frame
