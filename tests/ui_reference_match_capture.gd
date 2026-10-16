extends SceneTree

## Actual production renderer measurements and deterministic comparison views.
## These checks establish geometry and state presentation, not pixel identity
## with the approved painting or owner visual acceptance.
const DESTINATION := "res://output/qa/rc-016/reference-match/measurements"

var destination := DESTINATION
var checks := 0
var failures := 0
var assertions: Array = []
var captures: Array = []
var measurements: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String, evidence: Variant = null) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": description, "evidence": evidence})
	if not ok:
		failures += 1
		push_error(description + (": " + str(evidence) if evidence != null else ""))

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			destination = argument.trim_prefix("--capture-directory=")
	DirAccess.make_dir_recursive_absolute(destination)
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture_scene(dimensions)
		await _capture_scene(dimensions, "board_gallery")
	await _capture_scene(Vector2i(720,1600), "board_belfry")
	var report := {
		"checks": checks, "failures": failures, "assertions": assertions,
		"captures": captures, "measurements": measurements,
		"engine": Engine.get_version_info().string,
		"scope": "Actual main-scene native logical viewports. Production opening and existing authored board_gallery long-route and board_belfry Split/Join commands. Geometry, live labels and colored active material checks; screenshots require visual comparison. No pixel-identity, physical-device, rights or owner-acceptance claim.",
		"reference": "res://output/imagegen/approved/combat-final-v2-clean-board.png",
		"state_difference": "The reference painting's exact hand, turn, stock and forecast are not forced into the game. board_belfry is the existing legal branching witness; board_gallery is an unbranched long route. Normal opening remains unmodified. Pass and accessible Info remain approved controls."
	}
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("%d reference-layout measurements/checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _capture_scene(dimensions: Vector2i, example_id: String = "") -> void:
	var gallery := not example_id.is_empty()
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	if gallery:
		scene.board_example_id = example_id
		scene.board_example_step = "built"
	viewport.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	await _settle()
	var phase := (example_id.trim_prefix("board_") + "-built" if gallery else "opening") + "-%dx%d" % [dimensions.x, dimensions.y]
	_check(scene.startup_error.is_empty() and scene.controller != null, phase + " loads the intended actual scene", scene.startup_error)
	if scene.controller == null:
		viewport.queue_free()
		await process_frame
		return
	_check(scene.size == Vector2(dimensions), phase + " uses its native logical resolution", str(scene.size))
	_check(scene.game.has("production") and (scene.board_example_report.get("ok", false) if gallery else scene.setup_path == "res://data/production_encounter.json"), phase + " uses existing production content and legal construction")
	scene.page_scroll.scroll_vertical = 0
	scene.hand_scroll.scroll_horizontal = 0
	await _settle()
	_measure(scene, viewport, phase)
	_contract(scene, viewport, phase, gallery)
	await _save(viewport, phase + "-top")
	if dimensions.x == 720 and gallery:
		_active_material(scene, viewport, phase)
	if dimensions.x < 720:
		scene.page_scroll.scroll_vertical = 100000
		await _settle()
		_check(_visible(scene.combat_navigation, viewport) and _visible(scene.cast_button, viewport), phase + " bottom scroll exposes complete Cast and navigation")
		await _save(viewport, phase + "-bottom")
	scene.player.stop()
	scene.player.stream = null
	viewport.queue_free()
	await process_frame

func _contract(scene: Control, viewport: SubViewport, phase: String, gallery: bool) -> void:
	var stats_row: Control = scene.combat_stats
	_check(not scene.forecast_button is BaseButton and scene.forecast_button.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.forecast_button.focus_mode == Control.FOCUS_NONE and scene.forecast_button.is_visible_in_tree(), phase + " retains the persistent forecast as a visible noninteractive display above Cast")
	for parent in [scene.combat_heading, stats_row, scene.combat_navigation]:
		var surface: Control = parent.get_meta("combat_surface", null)
		_check(surface != null and surface.is_visible_in_tree() and surface.get_global_rect().is_equal_approx(parent.get_global_rect()), phase + " visible shared surface covers " + str(parent.get_path()), {"parent": _rect(parent.get_global_rect()), "surface": _rect(surface.get_global_rect()) if surface != null else []})
	var ribbon: Control = scene.completion_ribbon
	var ribbon_ratio: float = ribbon.size.x / scene.banner.size.x
	_check(ribbon.is_visible_in_tree() and scene.banner.get_global_rect().grow(1).encloses(ribbon.get_global_rect()) and absf(ribbon.get_global_rect().get_center().x - scene.banner.get_global_rect().get_center().x) <= 1 and ribbon_ratio >= 0.65 and ribbon_ratio <= 0.85, phase + " centers a visible inset completion ribbon inside the board banner", {"parent": _rect(scene.banner.get_global_rect()), "ribbon": _rect(ribbon.get_global_rect()), "width_ratio": ribbon_ratio})
	var background: Control = scene.combat_backdrop
	_check(background != null and background.get_script().resource_path == "res://scenes/ui/theme/reference_backdrop.gd" and background.size.is_equal_approx(scene.page_margin.size), phase + " uses separate clean architecture samples across the page", {"background": _rect(background.get_rect()) if background else [], "page": _rect(scene.page_margin.get_rect())})
	var arena: Control = scene.arena
	_check(not arena.role_label.is_visible_in_tree() and arena.name_label.get_rect().end.y <= arena.health_bar.position.y + 1, phase + " removes BOSS while keeping name and health without overlap", {"role_visible": arena.role_label.is_visible_in_tree(), "name": _rect(arena.name_label.get_rect()), "bar": _rect(arena.health_bar.get_rect())})
	_check(arena.name_label.position.y >= arena.get_geometry().foot.y and arena.health_label.get_rect().end.y <= arena.size.y + 1, phase + " keeps enemy name and health below the full-width actor feet and inside arena")
	_check(arena.health_bar is ProgressBar and arena.health_bar.value == scene.game.enemy_hp and arena.health_label.text == "%d/%d" % [scene.game.enemy_hp, scene.game.enemy_max_hp], phase + " retains live health bindings")
	var health_surface: Control = arena.health_bar.get_meta("combat_surface", null)
	_check(health_surface != null and health_surface.is_visible_in_tree() and health_surface.get("kind") == "health" and health_surface.get_global_rect().is_equal_approx(arena.health_bar.get_global_rect()) and is_equal_approx(float(health_surface.get("fill_ratio")), float(scene.game.enemy_hp) / maxf(scene.game.enemy_max_hp, 1)), phase + " generated health artwork follows the authoritative fill and bar bounds")
	_check(scene.cells.all(func(cell): return cell.clean_board and cell.has_meta("combat_surface") and cell.get_meta("combat_surface").kind == "socket" and cell.get_meta("combat_surface").size.is_equal_approx(cell.size)), phase + " renders reference socket surfaces at actual cell dimensions")
	_check(scene.completion_ribbon.get("completed") == bool(scene.game.forecast.valid), phase + " completion ribbon follows the actual evaluator")
	if viewport.size.x != 720:
		return
	_reference_geometry(scene, phase, gallery)
	var scrollbar: VScrollBar = scene.page_scroll.get_v_scroll_bar()
	var overflow := maxf(0, scrollbar.max_value - scrollbar.page)
	_check(overflow <= 1 and scene.combat_column.get_global_rect().end.y <= 1601, phase + " has no normal portrait vertical overflow", {"overflow_px": overflow, "column": _rect(scene.combat_column.get_global_rect())})
	for section in [scene.combat_heading, scene.arena, stats_row, scene.board_frame, scene.wiring, scene.hand_row, scene.forecast_button, scene.cast_button, scene.combat_navigation]:
		_check(_visible(section, viewport), phase + " fully exposes " + str(section.get_path()), _rect(section.get_global_rect()))
	var cast_ratio: float = scene.cast_button.size.x / float(viewport.size.x)
	_check(cast_ratio >= 0.67 and cast_ratio <= 0.72 and absf(scene.cast_button.get_global_rect().get_center().x - viewport.size.x / 2.0) <= 1, phase + " centers Cast at approximately 70% of viewport width", {"ratio": cast_ratio, "rect": _rect(scene.cast_button.get_global_rect())})
	if not gallery:
		var cards: Array = scene.hand_box.get_children()
		_check(cards.size() == 3 and cards.all(func(card): return _visible(card, viewport) and scene.hand_scroll.get_global_rect().grow(1).encloses(card.get_global_rect())), phase + " exposes three naturally drawn cards without hand scrolling")
		for card in cards:
			var title: Label = card.get_node("Title")
			var scroll: ScrollContainer = card.get_node("DescriptionScroll")
			var label: Label = scroll.find_child("Description", true, false)
			_check(title.get_visible_line_count() == title.get_line_count() and title.get_visible_line_count() > 0, phase + " shows complete card name " + title.text, _node_measure(title))
			_check(scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page + 1 and label.get_visible_line_count() == label.get_line_count() and label.get_visible_line_count() > 0, phase + " shows complete card description " + title.text, {"label": _node_measure(label), "scroll": _node_measure(scroll)})

func _reference_geometry(scene: Control, phase: String, gallery: bool) -> void:
	# Independently measured from the 841x1870 approved painting, normalized
	# to the720px design canvas; not inferred from runtime minimum sizes.
	# The regular grid deliberately resolves the painting's small irregularities.
	# The owner's annotated follow-up removes the24px caption and reallocates
	# eight pixels to the status lane, six to navigation spacing, six to its
	# height and four to bottom clearance. It also removes negative tool offsets.
	# The subsequent painted-well correction preserves these section bounds
	# while shrinking/insetting stats and tool descendants to clear their rims.
	var grid: Rect2 = scene.cells[0].get_global_rect()
	for index in scene.cells.size():
		var actual: Rect2 = scene.cells[index].get_global_rect()
		grid = grid.merge(actual)
		var expected := Rect2(80 + 141 * (index % 4), 551 + 126 * (index / 4), 137, 122)
		_check(_near_rect(actual, expected, 2), phase + " reference socket geometry " + str(index), {"actual": _rect(actual), "expected": _rect(expected)})
	_check(_near_rect(grid, Rect2(80, 551, 560, 500), 2), phase + " reference grid envelope", _rect(grid))
	for entry in [[scene.completion_ribbon, Rect2(113, 495, 495, 54)], [scene.forecast_button, Rect2(40, 1361, 640, 54)], [scene.cast_button, Rect2(110, 1420, 500, 76)], [scene.combat_navigation, Rect2(40, 1514, 640, 82)]]:
		_check(_near_rect(entry[0].get_global_rect(), entry[1], 3), phase + " reference section geometry " + str(entry[0].get_path()), {"actual": _rect(entry[0].get_global_rect()), "expected": _rect(entry[1])})
	_check(absf(grid.position.y - scene.banner.get_global_rect().end.y - 2) <= 1 and absf(scene.board_frame.get_global_rect().end.y - grid.end.y - 20) <= 1, phase + " preserves asymmetric ribbon/grid padding and the reference bottom clearance")
	if not gallery:
		for index in scene.hand_box.get_child_count():
			var card: Control = scene.hand_box.get_child(index)
			_check(_near_rect(card.get_global_rect(), Rect2(124 + 161 * index, 1205, 149, 146), 3), phase + " reference card dimensions with corrected feedback lane " + str(index), _rect(card.get_global_rect()))
	_check(scene.encounter_title.text == scene.game.encounter.title.capitalize() and scene.encounter_title.is_visible_in_tree() and _near_rect(scene.combat_heading.get_global_rect(), Rect2(0, 0, 720, 52), 1) and absf(scene.encounter_title.get_global_rect().end.x - 704) <= 0.5 and scene.encounter_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and not scene.combat_heading.get_children().any(func(child): return child is BaseButton), phase + " spans the viewport with the padded live floor name on the right and no Pause control")
	var floor_ink_width: float = scene.encounter_title.get_theme_font("font").get_string_size(scene.encounter_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, scene.encounter_title.get_theme_font_size("font_size")).x
	_check(scene.combat_identity is TextureRect and scene.combat_identity.is_visible_in_tree() and _near_rect(scene.combat_identity.get_global_rect(), Rect2(44, 6, 210, 40), 1) and scene.combat_identity.get_global_rect().end.x + 12 <= scene.encounter_title.get_global_rect().position.x and scene.combat_identity.get_global_rect().end.x + 12 <= scene.encounter_title.get_global_rect().end.x - floor_ink_width, phase + " aligns the original Rune Cast wordmark near the approved left offset with12px floor-label separation", _rect(scene.combat_identity.get_global_rect()))
	var heart: TextureRect = scene.stat_icons.health
	var heart_ink := _glyph_rect(heart)
	_check(heart.size == Vector2(42,36) and heart_ink.size.x >= 39 and heart_ink.size.x <= 42 and is_equal_approx(heart_ink.size.y,36) and Rect2(44,443,632,36).encloses(heart.get_global_rect()), phase + " restores the approved heart scale inside the9px-inset36px stats well", _rect(heart_ink))
	var menu_icon: TextureRect = scene.combat_navigation.get_child(0).get_meta("stacked_icon")
	# The owner's rail-clearance correction centers the end controls in their
	# usable painted wells, moving Menu9px inward from the old segment center.
	_check(menu_icon.size == Vector2(40,36) and _near_rect(_glyph_rect(menu_icon), Rect2(109,1527.86,40,34.29), 2), phase + " sizes the original49:42 Menu artwork inside its padded40x36 navigation lane", _rect(_glyph_rect(menu_icon)))
	var toolbar_art: Control = scene.wiring.get_parent().get_meta("combat_surface")
	_check(_near_rect(toolbar_art.get_global_rect(), Rect2(20, 1070, 680, 112), 2), phase + " balances a larger padded toolbar with reference board clearance", _rect(toolbar_art.get_global_rect()))
	_check(scene.stock_buttons.values().all(func(button): return absf(button.get_meta("combat_surface").global_position.y - button.global_position.y) <= 1 and button.size.y == 76 and button.get_meta("stock_label").get_theme_font_size("font_size") == 18), phase + " restores readable circuit controls within the padded toolbar")
	var straight: TextureRect = scene.stock_buttons.straight.get_node("Content").get_child(0).get_child(1).get_child(0)
	_check(_glyph_rect(straight).size.is_equal_approx(Vector2(53,10)), phase + " restores the reference Straight preview width and stroke", _rect(_glyph_rect(straight)))
	var plates_fit := true
	for button in scene.action_buttons.values():
		var plate: Control = button.get_meta("combat_surface")
		plates_fit = plates_fit and plate.size == Vector2(64, 52) and absf(plate.get_global_rect().get_center().x - button.get_global_rect().get_center().x) <= 1 and button.get_global_rect().encloses(plate.get_global_rect()) and button.get_theme_font_size("font_size") == 16
	_check(plates_fit, phase + " centers compact editing plates above captions inside the padded toolbar")

func _near_rect(actual: Rect2, expected: Rect2, tolerance: float) -> bool:
	return absf(actual.position.x - expected.position.x) <= tolerance and absf(actual.position.y - expected.position.y) <= tolerance and absf(actual.size.x - expected.size.x) <= tolerance and absf(actual.size.y - expected.size.y) <= tolerance

func _glyph_rect(node: TextureRect) -> Rect2:
	if node.stretch_mode == TextureRect.STRETCH_SCALE:
		return node.get_global_rect()
	var extent := node.texture.get_size()
	extent *= minf(node.size.x / extent.x, node.size.y / extent.y)
	return Rect2(node.global_position + (node.size - extent) * 0.5, extent)

func _active_material(scene: Control, viewport: SubViewport, phase: String) -> void:
	var active_endpoint: Control
	var empty_cell: Control
	for cell in scene.cells:
		if cell.active and cell.piece.get("kind", "") == "begin": active_endpoint = cell
		if cell.piece.is_empty(): empty_cell = cell
	_check(active_endpoint != null and empty_cell != null and scene.game.forecast.valid, phase + " includes active endpoint and unlit empty socket for material comparison")
	if active_endpoint == null or empty_cell == null:
		return
	var picture := viewport.get_texture().get_image()
	var active_color := _patch(picture, active_endpoint.get_global_rect())
	var empty_color := _patch(picture, empty_cell.get_global_rect())
	_check(active_color.g > empty_color.g + 0.05, phase + " actually renders the active endpoint's turquoise stone face", {"active_rgb": [active_color.r,active_color.g,active_color.b], "empty_rgb": [empty_color.r,empty_color.g,empty_color.b], "sampling": "5x5 patch centered 20% into the upper-left interior, clear of central glyph"})

func _patch(picture: Image, rect: Rect2) -> Color:
	var center := Vector2i(rect.position + rect.size * 0.2)
	var value := Color(0,0,0,0)
	for y in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			value += picture.get_pixel(x,y)
	return value / 25.0

func _measure(scene: Control, viewport: SubViewport, phase: String) -> void:
	var nodes: Array = []
	_collect(scene.combat_column, nodes)
	measurements.append({"phase": phase, "viewport": [viewport.size.x,viewport.size.y], "nodes": nodes, "background": _node_measure(scene.combat_backdrop), "snapshot": {"board": scene.game.board, "hand": scene.game.hand, "forecast": scene.game.forecast}})

func _collect(node: Node, nodes: Array) -> void:
	if node is Control: nodes.append(_node_measure(node))
	for child in node.get_children(true):
		_collect(child, nodes)

func _node_measure(node: Control) -> Dictionary:
	var result := {"path": str(node.get_path()), "class": node.get_class(), "visible": node.is_visible_in_tree(), "rect": _rect(node.get_global_rect()), "local_rect": _rect(node.get_rect()), "custom_minimum": _vector(node.custom_minimum_size), "combined_minimum": _vector(node.get_combined_minimum_size())}
	if node is Label:
		result.merge({"text": node.text, "lines": node.get_line_count(), "visible_lines": node.get_visible_line_count(), "font_size": node.get_theme_font_size("font_size")})
	if node is ScrollContainer:
		result.merge({"vertical_max": node.get_v_scroll_bar().max_value, "vertical_page": node.get_v_scroll_bar().page, "horizontal_max": node.get_h_scroll_bar().max_value, "horizontal_page": node.get_h_scroll_bar().page})
	if node.get_script() != null and node.get_script().resource_path.ends_with("combat_surface.gd"):
		result.merge({"surface_kind": node.get("kind"), "art_scale": node.get("art_scale"), "raster_texture": node.get("texture").resource_path})
	return result

func _rect(value: Rect2) -> Array:
	return [value.position.x,value.position.y,value.size.x,value.size.y]

func _vector(value: Vector2) -> Array:
	return [value.x,value.y]

func _visible(node: Control, viewport: SubViewport) -> bool:
	return node.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(viewport.size)).grow(1).encloses(node.get_global_rect())

func _settle() -> void:
	for frame in range(6):
		await process_frame

func _save(viewport: SubViewport, filename: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var path := destination.path_join(filename + ".png")
	_check(viewport.get_texture().get_image().save_png(path) == OK, "Saved actual native viewport " + filename)
	captures.append(path)
