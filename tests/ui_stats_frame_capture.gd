extends SceneTree

# Raster tests deliberately do not read the renderer's sampling geometry: gold
# must enclose the face, survive live content, and remain
# visible on all four sides at the game's actual presentation scales.
const Surface = preload("res://scenes/ui/theme/combat_surface.gd")
const Oracle = preload("res://tests/helpers/generated_stats_oracle.gd")

var destination := "res://output/qa/rc-016/stats-generated-frame/focused"
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
	DirAccess.make_dir_recursive_absolute(destination)
	_check(FileAccess.get_sha256(Oracle.SOURCE_PATH) == Oracle.SOURCE_HASH, "Runtime generated status PNG is byte-identical to the original image generation output")
	var recipe := ConfigFile.new()
	_check(recipe.load(Oracle.SOURCE_PATH+".import") == OK and recipe.get_value("params","process/size_limit") == 768 and recipe.get_value("params","compress/mode") == 0 and not recipe.get_value("params","mipmaps/generate"), "Generated status frame uses the lossless size-limited768px import without mipmaps")
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _actual_scene(dimensions)
	var report := {"checks": checks, "failures": failures, "assertions": assertions, "measurements": measurements, "captures": captures, "engine": Engine.get_version_info().string, "scope": "Actual game stats row at three native viewport sizes: generated PNG identity and independently measured pixel mapping, closed painted gold perimeter at native/mobile presentation scales, transparent corners, live content containment and protection, with the previous open-ended frame as a negative control."}
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("%d focused stats border checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _actual_scene(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	scene.sound_enabled = false
	await _settle()
	var suffix := "%dx%d" % [dimensions.x, dimensions.y]
	_check(scene.startup_error.is_empty(), suffix + " loads the ordinary production scene")
	var surface: Control = scene.combat_stats.get_meta("combat_surface")
	_check(surface.size.y == 54 and absf(surface.art_scale - 720.0 / 841.0) < 0.00001, suffix + " retains the real 54px stats row and production brush scale", {"size": str(surface.size), "art_scale": surface.art_scale})
	_check(surface.texture.resource_path == Oracle.SOURCE_PATH, suffix + " actual stats consumer uses the generated painted PNG")
	_live_content_contract(scene, suffix)
	await RenderingServer.frame_post_draw
	var picture: Image = viewport.get_texture().get_image()
	var live := picture.get_region(Rect2i(scene.combat_stats.get_global_rect()))
	# The original generatedPNG uses alpha253/255 across much of its face.
	# Compare live content with an identically composited frame/background,
	# keeping child layout intact while temporarily making their ink invisible.
	var content_children: Array[Node] = scene.combat_stats.get_children()
	var original_modulates := []
	for child in content_children:
		original_modulates.append(child.modulate)
		child.modulate.a = 0.0
	await _settle()
	await RenderingServer.frame_post_draw
	var clean_live := viewport.get_texture().get_image().get_region(Rect2i(scene.combat_stats.get_global_rect()))
	for index in content_children.size(): content_children[index].modulate = original_modulates[index]
	await _settle()
	_save(live, "stats-live-" + suffix)
	var enlarged := live.duplicate()
	enlarged.resize(live.get_width() * 3, live.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(enlarged, "stats-live-" + suffix + "-3x")
	var size: Vector2 = surface.size
	var ordinary: Image = await _render_surface(size, surface.art_scale)
	_save(ordinary, "stats-skin-" + suffix)
	var source_comparison := Oracle.source_comparison(ordinary,surface.texture.get_image())
	_check(source_comparison.samples > 10000 and source_comparison.mean_rgb_error <= 0.008 and source_comparison.maximum_rgb_error <= 0.035, suffix + " isolated skin reproduces independently sampled generated painting across face, corners, rails and dividers", source_comparison)
	var live_comparison := _gold_comparison(ordinary, clean_live, live)
	_check(live_comparison.protected_pixels > 1000 and live_comparison.changed_gold_pixels == 0, suffix + " live icons, values and Turn parchment leave every opaque gold bezel and divider pixel untouched", live_comparison)
	var clearance := _visible_divider_clearance(ordinary, clean_live, live)
	_check(clearance.minimum_pixels >= 2.5, suffix + " visible stats contents retain at least a 3px gap from the painted divider pixels", clearance)
	_check(_clear_corners(ordinary), suffix + " keeps exterior corners transparent instead of painting a rectangular backdrop")
	measurements.append({"viewport": suffix, "size": str(size), "generated_source":source_comparison, "live_content": live_comparison, "divider_clearance": clearance})
	for presentation_scale in [1.0, 0.625, 0.5]:
		var presented := ordinary.duplicate()
		presented.resize(roundi(size.x * presentation_scale), roundi(size.y * presentation_scale), Image.INTERPOLATE_BILINEAR)
		var continuity := Oracle.perimeter_continuity(presented)
		_check(continuity.complete, suffix + " has a closed gold border on all four sides at presentation scale " + str(presentation_scale), continuity)
		measurements.append({"viewport": suffix, "presentation_scale": presentation_scale, "continuity": continuity})
	var old_open := Image.load_from_file("res://output/qa/rc-016/full-screen-polish/stats-focused/stats-skin-" + suffix + ".png")
	var old_continuity := Oracle.perimeter_continuity(old_open)
	_check(not old_continuity.complete and not old_continuity.encloses_face, suffix + " closed-border oracle rejects the previous open-ended status frame", old_continuity)
	scene.audio.dispose()
	viewport.queue_free()
	await process_frame

func _render_surface(size: Vector2, brush_scale: float) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size.ceil())
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var surface: Control = Surface.new()
	surface.kind = "stats"
	surface.art_scale = brush_scale
	surface.size = size
	viewport.add_child(surface)
	await _settle()
	await RenderingServer.frame_post_draw
	var picture: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return picture

func _live_content_contract(scene: Control, phase: String) -> void:
	var frame: Rect2 = scene.combat_stats.get_global_rect()
	var horizontal := 18 if scene.get_viewport_rect().size.x < 400 else 24
	var well := Rect2(frame.position + Vector2(horizontal,9), Vector2(frame.size.x-horizontal*2,36))
	var failed := []
	var contents := []
	contents.append_array(scene.stat_icons.values())
	contents.append_array(scene.stat_values.values())
	contents.append(scene.stat_values.turn.get_parent())
	for child in contents:
		var rect: Rect2 = child.get_global_rect()
		if not well.grow(0.01).encloses(rect): failed.append({"node":str(child.name),"rect":str(rect)})
	_check(failed.is_empty(), phase + " live glyphs, numbers and Turn parchment fit the unchanged 36px inner lane", {"well":str(well),"outside":failed})

func _gold_comparison(skin: Image, clean_live: Image, changed: Image) -> Dictionary:
	var protected := 0
	var changed_gold := 0
	var changed_face := 0
	var worst := 0.0
	for y in skin.get_height():
		for x in skin.get_width():
			var original := skin.get_pixel(x,y)
			var error := _color_error(clean_live.get_pixel(x,y),changed.get_pixel(x,y))
			if _is_gold(original) and original.a >= 0.98:
				protected += 1
				worst = maxf(worst,error)
				# Permit one 8-bit channel rounding step between the isolated
				# transparent target and the opaque live viewport.
				if error > 1.1/255.0: changed_gold += 1
			elif original.a >= 0.99 and original.b > original.r and error > 0.2:
				changed_face += 1
	return {"protected_pixels":protected,"changed_gold_pixels":changed_gold,"maximum_gold_error":worst,"changed_face_pixels":changed_face}

func _visible_divider_clearance(skin: Image, clean_live: Image, live: Image) -> Dictionary:
	var smallest := INF
	var nearest := Vector2.ZERO
	for y in range(9,45):
		var divider_pixels := []
		for division in [1,2]:
			var center := roundi(skin.get_width()*division/3.0)
			for column in range(center-18,center+19):
				if _is_gold(skin.get_pixel(column,y)): divider_pixels.append(column+0.5)
		for x in range(9,skin.get_width()-9):
			if skin.get_pixel(x,y).a < 0.98 or _is_gold(skin.get_pixel(x,y)) or _color_error(clean_live.get_pixel(x,y),live.get_pixel(x,y)) < 0.08: continue
			for column in divider_pixels:
				var distance := absf(x+0.5-column)-1.0
				if distance < smallest:
					smallest = distance
					nearest = Vector2(x+0.5,y+0.5)
	return {"minimum_pixels":smallest,"nearest_visible_pixel":str(nearest)}

func _is_gold(color: Color) -> bool:
	return color.a > 0.90 and color.r > 0.18 and color.r > color.g*1.03 and color.g > color.b*1.15

func _clear_corners(picture: Image) -> bool:
	for point in [Vector2i(0,0),Vector2i(3,3),Vector2i(picture.get_width()-1,0),Vector2i(picture.get_width()-4,3),Vector2i(0,picture.get_height()-1),Vector2i(3,picture.get_height()-4),Vector2i(picture.get_width()-1,picture.get_height()-1),Vector2i(picture.get_width()-4,picture.get_height()-4)]:
		if picture.get_pixelv(point).a > 0.01: return false
	return true

func _color_error(first: Color, second: Color) -> float:
	return maxf(absf(first.r-second.r),maxf(absf(first.g-second.g),absf(first.b-second.b)))

func _save(picture: Image, name_text: String) -> void:
	var path := destination.path_join(name_text+".png")
	_check(picture.save_png(path) == OK,"Saved "+name_text)
	captures.append(path)

func _settle() -> void:
	for frame in range(5): await process_frame
