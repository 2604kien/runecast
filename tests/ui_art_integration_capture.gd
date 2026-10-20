extends SceneTree

const PresentationSupport = preload("res://tests/presentation_test_support.gd")

const GeneratedStatsOracle = preload("res://tests/helpers/generated_stats_oracle.gd")

# RC-016 actual main-scene rendering at native viewport sizes. Desktop synthetic
# input is evidence for these layouts, not physical-device or owner acceptance.
const DESTINATION := "res://output/qa/rc-016/runtime"
const ProductionUI = preload("res://tests/ui_production_tests.gd")
const TouchUI = preload("res://tests/ui_touch_tests.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const Ui = preload("res://scenes/ui/theme/components.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const ReferenceIcons = preload("res://scenes/ui/theme/reference_icons.gd")
const ReferenceBackdrop = preload("res://scenes/ui/theme/reference_backdrop.gd")
const ReferencePile = preload("res://scenes/ui/theme/reference_pile.gd")
const REFERENCE_PILE_REGIONS := {
	"draw": {"body": Rect2(25, 1418, 95, 136), "front": Rect2(30, 1442, 70, 108), "glyph": Rect2(39, 1459, 50, 60), "count": Rect2(45, 1521, 42, 32)},
	"discard": {"body": Rect2(725, 1423, 91, 132), "front": Rect2(747, 1444, 66, 107), "glyph": Rect2(762, 1470, 33, 42), "count": Rect2(755, 1521, 43, 33)},
}
const BoardCell = preload("res://scripts/ui/board_cell.gd")
const Circuit = preload("res://scripts/core/circuit.gd")

var checks := 0
var failures := 0
var assertions: Array = []
var captures: Array[String] = []
var geometry: Array = []
var textures := {}
var paint_samples: Array = []
var rotation_samples: Array = []
var destination := DESTINATION
var helper = ProductionUI.new()
var touch = TouchUI.new()

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": description})
	if not ok:
		failures += 1
		push_error(description)

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			destination = argument.trim_prefix("--capture-directory=")
	DirAccess.make_dir_recursive_absolute(destination)
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _native_layout(dimensions)
	var report := {
		"checks": checks, "failures": failures, "assertions": assertions,
		"captures": captures, "geometry": geometry,
		"textures": textures, "paint_samples": paint_samples, "rotation_samples": rotation_samples, "decoded_texture_bytes_estimate": _texture_bytes(),
		"memory_scope": "Sum of unique actual consumer texture dimensions as RGBA8 without mipmaps; excludes unused variants, font atlases, transient resources, driver overhead and render targets. Not measured resident/device memory.",
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"scope": "Actual ordinary main scene in native SubViewports, synthetic touch plus existing production UI construction helper. No physical-device, owner aesthetic or release-rights acceptance.",
		"qa_seams": "Only unaffordable energy, empty hand, terminal HP and a known conflicting graph are injected; shipped content and normal opening/draw/kit remain unchanged."
	}
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-016 actual-scene art integration checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _native_layout(dimensions: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	await _layout()
	var suffix := "%dx%d" % [dimensions.x, dimensions.y]
	_check(scene.startup_error.is_empty() and scene.setup_path == "res://data/production_encounter.json" and scene.game.has("production"), suffix + " starts the ordinary production encounter.")
	if scene.controller == null:
		viewport.queue_free()
		await process_frame
		return
	var setup: Dictionary = scene.initial_setup.duplicate(true)
	_check(scene.size == Vector2(dimensions), suffix + " is a native logical viewport, not a resized screenshot.")
	_check(helper._only_endpoints(scene.game.board) and scene.game.hand.size() == 3 and scene.game.energy == 3, suffix + " preserves normal endpoints, draw and energy.")
	_layout_contract(scene, viewport, suffix + " opening")
	await _backdrop_edge_raster_contract(scene, suffix)
	if dimensions.x == 720:
		_resource_contract(scene)
		await _approved_arena_raster_contract()
		_endpoint_rotation_contract()
		await _painted_raster_contract(scene)
		await _branch_rotation_raster_contract()
	_live_bindings(scene, suffix + " opening")
	await _full_page_contract(scene, viewport, "opening", true)
	await _save(viewport, "opening-top-" + suffix)
	await _board_view(scene)
	await _save(viewport, "opening-board-" + suffix)
	await _bottom_view(scene)
	await _save(viewport, "opening-bottom-" + suffix)
	await _editing(scene, viewport, suffix)
	if dimensions.x == 720:
		await _branch_rotation_controls(scene, viewport, suffix)
	await _inspection(scene, viewport, suffix)
	await _reveal(scene, scene.sound_button)
	_check(_fully_visible(scene.sound_button, viewport) and scene.sound_button.focus_mode == Control.FOCUS_NONE, suffix + " the navigation control can be exposed for touch without desktop focus.")
	scene._open_menu()
	await _layout()
	_check(scene.menu.size.x <= dimensions.x and scene.menu.size.y <= dimensions.y, suffix + " native Menu remains within the portrait viewport: " + str(scene.menu.size))
	_mobile_chrome_contract(scene, suffix + " Menu")
	scene.menu.hide()
	await _layout()
	scene._show_guide()
	await _layout()
	_mobile_chrome_contract(scene, suffix + " Guide")
	scene.dialog.hide()
	scene._show_map()
	await _layout()
	_mobile_chrome_contract(scene, suffix + " Map")
	scene.dialog.hide()
	await _layout()

	scene._exact_replay()
	var built: bool = helper._build(scene)
	_check(built and not scene.cast_button.disabled, suffix + " constructs an affordable rune circuit through existing UI actions.")
	if built:
		_live_bindings(scene, suffix + " built")
		await _full_page_contract(scene, viewport, "built")
		await _board_view(scene)
		await _save(viewport, "built-board-" + suffix)
		await _bottom_view(scene)
		await _save(viewport, "built-bottom-" + suffix)
		await _invalid_and_energy(scene, viewport, suffix)
		await _pass_cancel(scene, viewport, suffix)
		var prior: Dictionary = scene.controller.snapshot()
		var spell: Dictionary = prior.forecast
		await _reveal(scene, scene.cast_button)
		_check(_fully_visible(scene.cast_button, viewport), suffix + " pointed Cast is a visible reachable input target: " + str(scene.cast_button.get_global_rect()))
		await _save(viewport, "ready-to-cast-" + suffix)
		touch._tap(viewport, scene.cast_button)
		PresentationSupport.finish(scene)
		await _layout()
		_check(scene.game.turn == prior.turn + 1 and scene.game.enemy_hp == maxi(0, int(prior.enemy_hp) - int(spell.damage)) and helper._only_endpoints(scene.game.board), suffix + " real Cast tap applies the forecast once and resets the next board.")
		_live_bindings(scene, suffix + " after Cast")
		_check(scene.game.hand.size() == 3 and scene.game.undo_count == 0 and helper._stock_labels(scene), suffix + " Cast refreshes the normal hand, kit, piles and cleared edit history.")
		await _full_page_contract(scene, viewport, "after-cast")
		await _bottom_view(scene)
		await _save(viewport, "after-cast-bottom-" + suffix)
		_check(helper._build(scene), suffix + " the next normally drawn turn can be rebuilt through the production controls.")
		await _board_view(scene)
		await _save(viewport, "rebuilt-board-" + suffix)

	await _empty_hand_pass(scene, viewport, suffix)
	if dimensions.x == 720:
		await _resize(scene, viewport, setup)
		await _conflict(scene, viewport, setup)
		await _repeated_guard(scene, setup)
	await _terminal(scene, viewport, setup, suffix)
	scene.audio.dispose()
	viewport.queue_free()
	await process_frame

func _layout_contract(scene: Control, viewport: SubViewport, phase: String) -> void:
	var width := float(viewport.size.x)
	var controls: Array = [scene.encounter_title, scene.arena, scene.hand_scroll, scene.cast_button, scene.turn_pass_button, scene.forecast_button, scene.draw_button, scene.discard_button]
	controls.append_array(scene.stat_values.values())
	controls.append_array(scene.cells)
	controls.append_array(scene.edit_buttons)
	var outside: Array[String] = []
	for control in controls:
		var rect: Rect2 = control.get_global_rect()
		if rect.position.x < -1 or rect.end.x > width + 1:
			outside.append("%s:%s" % [control.name, rect])
	_check(outside.is_empty(), phase + " keeps every board/control region within the viewport width: " + "; ".join(outside))
	# The approved reference's empty sockets measure approximately160×142.
	# Allow pixel rounding at smaller native sizes, not a second aspect ratio.
	_check(scene.cells.all(func(cell): return cell.clean_board and cell.size.x >= 44 and cell.size.y >= 44 and absf(cell.size.y - cell.size.x * 142.0 / 160.0) <= 1.5), phase + " uses reference160:142 rectangular sockets within1.5px rounding and both input dimensions at least44px.")
	_check(scene.cells.all(func(cell): return cell.get_meta("rc_skin", null) != null and cell.get_meta("rc_skin").get_script() == CombatSurface and cell.get_meta("rc_skin").texture == CombatSurface.TEXTURES.socket), phase + " all actual board buttons consume the generated painted socket skin.")
	for cell in scene.cells:
		if cell.piece.get("kind", "") in ["begin", "end"]:
			_endpoint_layout_contract(cell, phase + " " + str(cell.piece.kind))
	_check(scene.theme == Ui.THEME and scene.cast_button.has_meta("rc_skin") and scene.cast_button.get_meta("rc_skin").texture == CombatSurface.TEXTURES.cast, phase + " uses the existing theme and generated painted Cast resource.")
	_check(_has_approved_icon(scene.cast_button, "energy"), phase + " Cast keeps the original masked reference energy crystal beside live cost.")
	_check(scene.draw_button.get_global_rect().get_center().x < scene.hand_scroll.get_global_rect().get_center().x and scene.discard_button.get_global_rect().get_center().x > scene.hand_scroll.get_global_rect().get_center().x, phase + " live Draw remains left and Discard right.")
	var hand_rect: Rect2 = scene.hand_row.get_global_rect()
	var toolbar_rect: Rect2 = scene.wiring.get_parent().get_global_rect()
	var forecast_rect: Rect2 = scene.forecast_button.get_global_rect()
	_check(is_equal_approx(hand_rect.size.y, 146.0) and is_equal_approx(hand_rect.position.y - toolbar_rect.end.y, forecast_rect.position.y - hand_rect.end.y)
		and not scene.status.is_visible_in_tree() and forecast_rect.end.y <= scene.cast_button.get_global_rect().position.y + 1, phase + " the fixed-height hand is centered between toolbar and forecast with no suggestion row, and forecast remains above Cast.")
	_check(scene.forecast_reason.get_index() + 1 == scene.forecast_button.get_index(), phase + " forecast explanation stays in one fixed layout slot above the forecast.")
	_check(scene.hand_box.get_children().all(func(card): return card.size.x <= scene.hand_scroll.size.x), phase + " each detailed card can be fully exposed by hand scrolling.")
	_check(scene.action_buttons.keys().size() == 2 and scene.action_buttons.has("erase") and scene.action_buttons.has("rotate") and scene.turn_pass_button.visible and not scene.inspect_button.is_visible_in_tree(), phase + " preserves the accepted Remove/Rotate and visible Pass controls.")
	_forecast_lanes(scene, viewport, phase)
	_arena_contract(scene, phase)
	_highlighted_content_contract(scene, phase)
	_mobile_chrome_contract(scene, phase)

func _endpoint_layout_contract(cell: Control, phase: String) -> void:
	var geometry: Dictionary = cell.get_endpoint_geometry()
	var glyph: Rect2 = geometry.glyph_rect
	var caption: Rect2 = geometry.caption_rect
	var interior := Rect2(Vector2.ZERO, cell.size).grow(-6 if cell.size.x <= 80 else -7)
	_check(interior.encloses(glyph) and interior.encloses(caption), phase + " keeps the visible endpoint ring and outlined caption within the socket inset.")
	_check(absf(glyph.get_center().x - cell.size.x * 0.5) <= 0.5 and absf(caption.get_center().x - cell.size.x * 0.5) <= 0.5, phase + " horizontally centers endpoint ring and caption.")
	var south_port: bool = Circuit.logical_ports(cell.piece).has(2)
	var gap: float = glyph.position.y - caption.end.y if south_port else caption.position.y - glyph.end.y
	_check(gap >= 1.99 and not glyph.intersects(caption), phase + " keeps at least2px between endpoint ring and caption, moving the caption above a south-facing port.")

func _endpoint_rotation_contract() -> void:
	# Cover every legal endpoint rotation without changing the live encounter.
	# These are the actual production socket sizes at720/450/360px viewports.
	var cell := BoardCell.new()
	for dimensions in [Vector2(137, 122), Vector2(94, 83), Vector2(72, 64)]:
		cell.size = dimensions
		for kind in ["begin", "end"]:
			for quarter_turn in 4:
				cell.piece = {"kind": kind, "rotation": quarter_turn}
				_endpoint_layout_contract(cell, "Endpoint " + kind + " rotation" + str(quarter_turn) + " at" + str(dimensions))
	cell.free()

func _branch_rotation_raster_contract() -> void:
	# These expected ports are an independent clockwise table. The symbol
	# pixels must stay upright while the rendered edge connections move.
	var expected_ports := {
		"split": [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]],
		"join": [[0, 1, 2], [1, 2, 3], [0, 2, 3], [0, 1, 3]],
	}
	var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	for dimensions in [Vector2(137, 122), Vector2(72, 64)]:
		for lit in [false, true]:
			for kind in ["split", "join"]:
				var viewport := SubViewport.new()
				viewport.size = Vector2i(dimensions + Vector2(40, 40))
				viewport.transparent_bg = true
				viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				root.add_child(viewport)
				var cell := BoardCell.new()
				cell.theme = Ui.THEME
				cell.position = Vector2(20, 20)
				cell.size = dimensions
				cell.clean_board = true
				cell.active = lit
				cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cell.focus_mode = Control.FOCUS_NONE
				for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
					cell.add_theme_stylebox_override(state, StyleBoxEmpty.new())
				viewport.add_child(cell)
				var surface := CombatSurface.new()
				surface.kind = "socket"
				surface.art_scale = 720.0 / 841.0
				surface.size = dimensions
				surface.show_behind_parent = true
				cell.add_child(surface)
				var center: Vector2 = cell.position + dimensions * 0.5
				# Active glow extends farther toward the center. Sample only
				# the glyph core, clear of every possible wire and its round cap.
				var side := floori(minf(dimensions.x, dimensions.y) * (0.20 if lit else 0.32))
				var core := Rect2i(Vector2i((center - Vector2.ONE * side * 0.5).floor()), Vector2i(side, side))
				var baseline: Image
				for rotation in 4:
					cell.piece = {"kind": kind, "rotation": rotation}
					cell.queue_redraw()
					await _layout()
					await RenderingServer.frame_post_draw
					var picture: Image = viewport.get_texture().get_image()
					var label := "%s %dx%d %s rotation%d" % [kind, dimensions.x, dimensions.y, "active" if lit else "idle", rotation]
					var actual_ports: Array = Circuit.logical_ports(cell.piece)
					actual_ports.sort()
					_check(actual_ports == expected_ports[kind][rotation], label + " exposes the independent clockwise logical port set.")
					var edge_alphas: Array = []
					for direction in 4:
						var point := Vector2i((center + directions[direction] * (dimensions * 0.5 + Vector2.ONE)).floor())
						var alpha := picture.get_pixelv(point).a
						edge_alphas.append(alpha)
						_check(alpha > 0.25 if expected_ports[kind][rotation].has(direction) else alpha <= 0.01, label + " paints the correct wire at edge" + str(direction) + ": alpha=" + str(alpha))
					var error := 0.0
					if rotation == 0:
						baseline = picture
						var colored_pixels := 0
						for y in range(core.position.y, core.end.y):
							for x in range(core.position.x, core.end.x):
								var color := picture.get_pixel(x, y)
								var visible := (color.g > 0.6 and color.b > 0.6 and color.r < 0.7) if kind == "split" else (color.g > 0.65 and color.r < 0.8 and color.b > 0.25) if lit else (color.r > 0.8 and color.g > 0.6 and color.b < 0.7)
								if visible:
									colored_pixels += 1
						_check(colored_pixels >= 5, label + " contains a visible operation glyph in the invariant pixel region, rather than an empty background.")
					else:
						for y in range(core.position.y, core.end.y):
							for x in range(core.position.x, core.end.x):
								var difference := picture.get_pixel(x, y) - baseline.get_pixel(x, y)
								error = maxf(error, maxf(maxf(absf(difference.r), absf(difference.g)), maxf(absf(difference.b), absf(difference.a))))
						_check(error <= 1.0 / 255.0, label + " keeps the central operation glyph upright and pixel-invariant: maximum channel difference=" + str(error))
					rotation_samples.append({"kind": kind, "size": [dimensions.x, dimensions.y], "active": lit, "rotation": rotation, "core": [core.position.x, core.position.y, side, side], "maximum_core_error": error, "edge_alphas": edge_alphas, "logical_ports": actual_ports})
					await _save(viewport, "branch-%s-%dx%d-%s-rotation%d" % [kind, dimensions.x, dimensions.y, "active" if lit else "idle", rotation])
				viewport.queue_free()
				await process_frame

func _branch_rotation_controls(scene: Control, viewport: SubViewport, suffix: String) -> void:
	for kind in ["split", "join"]:
		var before: Dictionary = scene.controller.snapshot()
		var cell_index: int = helper._empty_cells(scene.game.board)[0]
		await _reveal(scene, scene.stock_buttons[kind])
		touch._tap(viewport, scene.stock_buttons[kind])
		await _reveal(scene, scene.cells[cell_index])
		touch._tap(viewport, scene.cells[cell_index])
		_check(scene.game.board[cell_index].get("kind") == kind and scene.game.stock[kind] == before.stock[kind] - 1, suffix + " actual " + kind + " tool and socket taps install one branch piece.")
		scene._cancel_selection()
		touch._tap(viewport, scene.cells[cell_index])
		var placed: Dictionary = scene.controller.snapshot()
		for step in 4:
			await _reveal(scene, scene.action_buttons.rotate)
			touch._tap(viewport, scene.action_buttons.rotate)
			var after: Dictionary = scene.controller.snapshot()
			_check(after.board[cell_index].get("rotation") == (step + 1) % 4 and scene.selected_cell == cell_index and scene.cells[cell_index].chosen, suffix + " actual Rotate tap advances selected " + kind + " to orientation" + str((step + 1) % 4) + ".")
			_check(after.stock == placed.stock and after.hand == placed.hand and after.energy == placed.energy and after.turn == placed.turn, suffix + " rotating " + kind + " preserves kit, hand, energy and turn.")
		await _reveal(scene, scene.action_buttons.erase)
		touch._tap(viewport, scene.action_buttons.erase)
		await _reveal(scene, scene.cells[cell_index])
		touch._tap(viewport, scene.cells[cell_index])
		_check(scene.game.board[cell_index].is_empty() and scene.game.stock == before.stock, suffix + " Remove refunds the rotated " + kind + " and restores the original board.")
		scene._cancel_selection()

func _highlighted_content_contract(scene: Control, phase: String) -> void:
	_check(not _has_cast_caption(scene.combat_column), phase + " removes the Cast ends turn label and its painted caption strip from production.")
	_frame_content_contract(scene, phase)
	_compact_card_contract(scene, phase)
	for entry in [[scene.draw_button, "draw_pile"], [scene.discard_button, "discard_pile"]]:
		var pile: Control = entry[0]
		var pile_surface: Control = pile.get_meta("combat_surface")
		var glyph: Control = pile.get_node("PileIcon")
		var plaque: Control = pile.get_node("CountPlaque")
		var count: Label = scene.pile_values[entry[1]]
		var caption: Label = pile.get_node("PileCaption")
		var front := _reference_pile_rect(pile_surface, "front")
		var expected_glyph := _reference_pile_rect(pile_surface, "glyph")
		var expected_plaque := _reference_pile_rect(pile_surface, "count")
		var plate_bounds := plaque.get_global_rect()
		var count_bounds := count.get_global_rect()
		_check(pile_surface.get_script() == ReferencePile and pile_surface.pile_kind == ("discard" if entry[1] == "discard_pile" else "draw") and pile.scale == Vector2.ONE and glyph.scale == Vector2.ONE and count.scale == Vector2.ONE and caption.scale == Vector2.ONE, phase + " uses each pile's distinct approved stack and upright emblem instead of flipping or stretching a generic deck.")
		_check(front.grow(0.001).encloses(glyph.get_global_rect()) and _near_rect(glyph.get_global_rect(), expected_glyph, 0.01) and _near_rect(plate_bounds, expected_plaque, 0.01) and not glyph is TextureRect, phase + " preserves the original " + str(entry[1]) + " emblem and count-plaque locations at one uniform scale: front " + str(front) + ", emblem " + str(glyph.get_global_rect()) + ", plaque " + str(plate_bounds))
		_check(plate_bounds.grow_individual(-4, -3, -4, -3).encloses(count_bounds) and plate_bounds.get_center().distance_to(count_bounds.get_center()) <= 0.5 and count.get_visible_line_count() == 1, phase + " centers the complete " + str(entry[1]) + " count with4px side/3px vertical plaque padding: count " + str(count_bounds) + ", plaque " + str(plate_bounds))
		_check(glyph.get_global_rect().end.y < plate_bounds.position.y and is_equal_approx(plate_bounds.position.y - glyph.get_global_rect().end.y, expected_plaque.position.y - expected_glyph.end.y), phase + " preserves the approved " + str(entry[1]) + " emblem-to-plaque gap without overlap.")
		_check(caption.get_global_rect().position.y >= plate_bounds.end.y + 1 and pile.get_global_rect().encloses(caption.get_global_rect()), phase + " separates the complete " + str(entry[1]) + " caption from its count plaque: caption " + str(caption.get_global_rect()) + ", pile " + str(pile.get_global_rect()))
	var navigation: Control = scene.combat_navigation
	var nav_surface: Control = navigation.get_meta("combat_surface")
	# The rails are10/9 source pixels in the approved atlas. Reserve four
	# further pixels of slate around the complete icon and font line, not just
	# the button input rectangle; the prior icon-only test missed caption bleed.
	var nav_inside := _navigation_painted_well(nav_surface).grow(-4)
	for button in navigation.get_children():
		var icon: Control = button.get_meta("stacked_icon")
		var caption_label: Label = button.get_node("NavigationCaption")
		var caption := _centered_label_text_rect(caption_label)
		var segment: Rect2 = button.get_global_rect().grow_individual(-8, 0, -8, 0).intersection(nav_inside)
		_check(segment.encloses(icon.get_global_rect()) and segment.encloses(caption), phase + " keeps the complete " + button.text + " icon and font line at least4px clear of navigation rails and8px inside its segment: icon " + str(icon.get_global_rect()) + ", caption " + str(caption) + ", padded well " + str(segment))
		_check(icon.get_global_rect().end.y + 2 <= caption.position.y, phase + " separates the " + button.text + " navigation icon and caption by at least2px.")
		_check(caption_label.text == button.text and caption_label.get_line_count() == 1 and caption_label.get_visible_line_count() == 1, phase + " renders the complete live " + button.text + " caption as one line.")

func _frame_content_contract(scene: Control, phase: String) -> void:
	# These bounds come from the delivered PNGs, independently of the renderer's
	# content API. Map sampled slate rows through the actual slice caps rather
	# than treating the outer frame as available content. Checking only
	# the outer Control rect allowed children to cover the painted gold bevels.
	var stats_skin: Control = _find_combat_surface(scene.combat_column, "stats")
	var stats_inside := _stats_painted_well(stats_skin)
	_check(absf(stats_skin.size.y - 54) <= 0.5, phase + " retains the 54px stats frame while insetting its children.")
	_assert_content_inside(stats_skin.get_parent(), stats_inside, stats_skin, phase + " stats painted well")
	var stat_cells: Array[Node] = stats_skin.get_parent().get_children()
	_check(stat_cells.size() == 3, phase + " retains one content cell per painted stats segment.")
	for index in stat_cells.size():
		# Gold separators are painted at equal thirds, independently of the
		# HBox's minimum-size negotiation. Keep content away from each divider.
		var segment := Rect2(stats_skin.global_position + Vector2(stats_skin.size.x * float(index) / 3.0, 0), Vector2(stats_skin.size.x / 3.0, stats_skin.size.y))
		segment = segment.grow_individual(-8 if index > 0 else 0, 0, -8 if index < 2 else 0, 0).intersection(stats_inside)
		_assert_content_inside(stat_cells[index], segment, null, phase + " stats segment " + str(index))
	var turn_skin: Control = _find_combat_surface(stats_skin.get_parent(), "parchment")
	_check(turn_skin != null and stats_inside.encloses(_painted_rect(turn_skin)), phase + " contains the complete Turn parchment inside the stats painted well.")
	if turn_skin != null:
		var turn_value: Label = scene.stat_values.turn
		_check(_painted_rect(turn_skin).grow(-4).encloses(turn_value.get_global_rect()), phase + " contains the complete Turn text inside its separate parchment with4px padding.")
	var toolbar_skin: Control = _find_combat_surface(scene.wiring.get_parent(), "toolbar")
	var toolbar_inside := toolbar_skin.get_global_rect().grow_individual(-32, -15, -32, -21)
	var toolbar_gutter := _toolbar_painted_well(toolbar_skin).grow(-6)
	var buttons: Array = [scene.turn_pass_button, scene.stock_buttons.straight, scene.stock_buttons.corner, scene.stock_buttons.split, scene.stock_buttons.join, scene.action_buttons.erase, scene.action_buttons.rotate]
	_check(buttons.size() == scene.wiring.get_child_count(), phase + " checks every one of the seven toolbar controls.")
	for button in buttons:
		_check(toolbar_gutter.encloses(button.get_global_rect()), phase + " leaves at least 6px of visible slate between " + str(button.name) + " and the toolbar's painted inner rim: input " + str(button.get_global_rect()) + ", padded well " + str(toolbar_gutter))
		_check(toolbar_inside.encloses(button.get_global_rect()), phase + " contains the entire " + str(button.name) + " toolbar input in the painted well: input " + str(button.get_global_rect()) + ", well " + str(toolbar_inside))
		_assert_content_inside(button, toolbar_inside, null, phase + " toolbar painted well")
		if not button.text.is_empty():
			var text_bounds := _button_text_rect(button)
			_check(toolbar_inside.encloses(text_bounds), phase + " contains the full " + button.text + " text line in the toolbar painted well: " + str(text_bounds))
	var pass_skin: Control = scene.turn_pass_button.get_meta("combat_surface")
	_check(_painted_rect(pass_skin).encloses(_button_text_rect(scene.turn_pass_button)), phase + " contains the complete Pass turn text inside the painted parchment itself.")
	for kind in scene.stock_buttons:
		var button: Button = scene.stock_buttons[kind]
		var slot_inside := button.get_global_rect().grow_individual(-4, -2, -4, -2)
		var column: VBoxContainer = button.get_node("Content").get_child(0)
		var title: Label = column.get_child(0)
		var glyph_lane: Control = column.get_child(1)
		var count: Label = column.get_child(2)
		_assert_content_inside(column, slot_inside, null, phase + " " + str(kind) + " padded slot")
		_check(slot_inside.encloses(glyph_lane.get_global_rect()) and title.get_global_rect().end.y <= glyph_lane.get_global_rect().position.y and glyph_lane.get_global_rect().end.y <= count.get_global_rect().position.y, phase + " separates the complete " + str(kind) + " title, glyph and count inside its slot.")
	for button in scene.action_buttons.values():
		var plate: Control = button.get_meta("combat_surface")
		var glyph: Control = button.get_meta("stacked_icon")
		var caption := _button_text_rect(button)
		_check(_painted_rect(plate).grow(-8).encloses(glyph.get_global_rect()), phase + " contains the " + button.text + " icon in its raised plate with8px bevel padding.")
		_check(caption.position.y >= _painted_rect(plate).end.y and toolbar_inside.encloses(caption), phase + " separates the " + button.text + " caption below its plate within the toolbar.")

func _find_combat_surface(node: Node, kind: String) -> Control:
	if node.get_script() == CombatSurface and node.kind == kind:
		return node
	for child in node.get_children(true):
		var found := _find_combat_surface(child, kind)
		if found != null: return found
	return null

func _toolbar_painted_well(surface: Control) -> Rect2:
	# Independently sampled clear slate rows1258..1367 of the approved atlas.
	# Map the top through its12px source cap and retain the bottom inner edge;
	# outer Control padding alone cannot prove the visible frame/button gap.
	var geometry: Dictionary = surface.get_geometry()
	var caps: Vector4 = geometry.destination_caps
	var top := (1258.0 - 1248.0) / 12.0 * caps.y
	var bottom := surface.size.y - caps.w
	return surface.get_global_transform() * Rect2(26, top, surface.size.x - 52, bottom - top)

func _stats_painted_well(surface: Control) -> Rect2:
	# The generated painted frame preserves the36px live lane clear of both gold rails.
	# Native360 uses18px horizontal inset; the independent live raster suite
	# additionally verifies all rim/divider pixels and visible-ink clearance.
	var horizontal := 18 if surface.get_viewport_rect().size.x < 400 else 24
	return surface.get_global_transform() * Rect2(horizontal,9,surface.size.x-horizontal*2,36)

func _navigation_painted_well(surface: Control) -> Rect2:
	# Source rows1788..1860 lie between the top10px and bottom9px gold rails.
	var caps: Vector4 = surface.get_geometry().destination_caps
	return surface.get_global_transform() * Rect2(caps.x, caps.y, surface.size.x - caps.x - caps.z, surface.size.y - caps.y - caps.w)

func _reference_pile_rect(surface: Control, region: String) -> Rect2:
	# These independent source measurements deliberately retain each original
	# silhouette/emblem. Their geometry must not be replaced with a generic
	# mirrored nine-slice that happens to fit the same input bounds.
	var source: Dictionary = REFERENCE_PILE_REGIONS[surface.pile_kind]
	var body: Rect2 = source.body
	var sample: Rect2 = source[region]
	var lane := Vector2(surface.size.x, surface.size.y - 20)
	var scale_factor := minf(lane.x / body.size.x, lane.y / body.size.y)
	var offset := (lane - body.size * scale_factor) * 0.5
	return surface.get_global_transform() * Rect2(offset + (sample.position - body.position) * scale_factor, sample.size * scale_factor)

func _near_rect(actual: Rect2, expected: Rect2, tolerance: float) -> bool:
	return actual.position.distance_to(expected.position) <= tolerance and actual.size.distance_to(expected.size) <= tolerance

func _mobile_chrome_contract(scene: Control, phase: String) -> void:
	var tooltips: Array[String] = []
	_collect_hover_tooltips(scene, tooltips)
	_check(tooltips.is_empty(), phase + " keeps the entire production tree free of hover tooltips, including hidden/rebuilt controls and dialogs: " + "; ".join(tooltips))
	var heading: Control = scene.combat_heading
	var title: Label = scene.encounter_title
	_check(_find_combat_surface(heading, "pause") == null and not heading.get_children().any(func(child): return child is BaseButton), phase + " removes the header Pause control while retaining Menu in navigation.")
	_check(title.is_visible_in_tree() and title.text == scene.game.encounter.title.capitalize() and title.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and absf(title.get_global_rect().end.x - heading.get_global_rect().end.x + 16) <= 0.5, phase + " right-aligns the live floor name with16px padding from the header's right edge.")
	var wordmark: TextureRect = scene.combat_identity
	var header: Rect2 = heading.get_global_rect()
	var viewport_width: float = scene.get_viewport_rect().size.x
	_check(absf(header.position.x) <= 0.5 and absf(header.end.x - viewport_width) <= 0.5 and absf(header.size.y - 52) <= 0.5, phase + " spans the complete viewport width with one52px header, without side strips: " + str(header))
	var title_inset := 16 if viewport_width < 640 else 44
	_check(wordmark.is_visible_in_tree() and wordmark.texture is AtlasTexture and wordmark.texture.atlas == CombatSurface.ATLAS and wordmark.texture.region == Rect2(56, 1, 245, 46) and absf(wordmark.get_global_rect().position.x - title_inset) <= 0.5, phase + " retains the approved Rune Cast lettering at its reference left offset, with a16px native narrow inset.")
	var floor_ink := _right_label_text_rect(title)
	_check(header.grow_individual(-16, 0, -16, 0).encloses(wordmark.get_global_rect()) and wordmark.get_global_rect().end.x + 12 <= title.get_global_rect().position.x and wordmark.get_global_rect().end.x + 12 <= floor_ink.position.x and wordmark.get_global_rect().get_center().x < header.get_center().x, phase + " separates the left Rune Cast wordmark from the right floor label and visible name by12px, with padded header edges.")
	_check(not scene.arena.role_label.is_visible_in_tree() and not _has_visible_text(scene.arena, "boss"), phase + " removes the BOSS role above the live enemy name.")
	for button in [scene.cast_button, scene.action_buttons.rotate]:
		_check(button.get_meta("rc_show_state_badges", true) == false and button.has_meta("rc_overlay") and button.get_meta("rc_overlay").observed_control == button, phase + " suppresses invalid/unavailable corner symbols on " + str(button.name) + " while retaining its input state and focus overlay.")

func _collect_hover_tooltips(node: Node, found: Array[String]) -> void:
	if node is Control and not node.tooltip_text.is_empty():
		found.append(str(node.get_path()))
	for child in node.get_children(true):
		_collect_hover_tooltips(child, found)

func _painted_rect(surface: Control) -> Rect2:
	return surface.get_global_transform() * surface.get_geometry().destination_rect

func _assert_content_inside(node: Node, bounds: Rect2, excluded: Node, description: String) -> void:
	if node != excluded and node is Control and node.is_visible_in_tree():
		if node is Label or node is TextureRect or node.get_script() == CombatSurface:
			var content_rect: Rect2 = _painted_rect(node) if node.get_script() == CombatSurface else node.get_global_rect()
			_check(bounds.encloses(content_rect), description + " contains " + str(node.get_path()) + ": content " + str(content_rect) + ", well " + str(bounds))
			if node is Label:
				_check(node.get_visible_line_count() == node.get_line_count() and node.get_line_count() > 0, description + " keeps the complete " + node.text + " text visible.")
	for child in node.get_children(true):
		_assert_content_inside(child, bounds, excluded, description)

func _button_text_rect(button: Button) -> Rect2:
	# Button draws its centered text in the stylebox content region; recording
	# that actual font line exposes captions that sit on the lower frame rail.
	var style := button.get_theme_stylebox("normal")
	var content := button.get_global_rect().grow_individual(-style.get_content_margin(SIDE_LEFT), -style.get_content_margin(SIDE_TOP), -style.get_content_margin(SIDE_RIGHT), -style.get_content_margin(SIDE_BOTTOM))
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var line := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Rect2(content.position + (content.size - line) * 0.5, line)

func _centered_label_text_rect(label: Label) -> Rect2:
	# Empty horizontal label space is not painted; measure the actual centered
	# glyph advance while keeping the complete font line including descenders.
	var line := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size"))
	return Rect2(label.global_position + (label.size - line) * 0.5, line)

func _right_label_text_rect(label: Label) -> Rect2:
	var line := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size"))
	line.x = minf(line.x, label.size.x)
	return Rect2(label.global_position + Vector2(label.size.x - line.x, (label.size.y - line.y) * 0.5), line)

func _has_cast_caption(node: Node) -> bool:
	if node is Label and node.text.strip_edges() == "Cast ends turn":
		return true
	if node.get_script() == CombatSurface and node.kind == "caption":
		return true
	for child in node.get_children(true):
		if _has_cast_caption(child): return true
	return false

func _forecast_lanes(scene: Control, viewport: SubViewport, phase: String) -> void:
	var frame: Rect2 = scene.forecast_button.get_global_rect()
	var inside := frame.grow_individual(-22, -10, -22, -10)
	_check(scene.forecast_grid.get_child_count() == 3 and not _has_visible_text(scene.forecast_button, "incoming"), phase + " displays exactly Damage, Shield and Cost with no Incoming label in the forecast frame.")
	_check(absf(frame.size.y - (64 if viewport.size.x < 500 else 54)) <= 0.5, phase + " keeps the three-metric forecast at its intended frame height.")
	_check(inside.encloses(scene.forecast_grid.get_global_rect()) and scene.forecast_grid.get_global_rect().get_center().distance_to(frame.get_center()) <= 1, phase + " centers the forecast metric grid inside equal horizontal and vertical frame margins.")
	for metric in scene.forecast_grid.get_children():
		var row: Control = metric.get_node("Content").get_child(0)
		var icon: Control = row.get_child(0)
		var label: Label = row.get_child(1)
		var group := icon.get_global_rect().merge(label.get_global_rect())
		_check(inside.encloses(group) and label.get_visible_line_count() == label.get_line_count() and label.get_line_count() > 0, phase + " keeps the complete forecast icon and " + label.text.replace("\n", " ") + " text inside the painted frame margins.")
		_check(group.get_center().distance_to(metric.get_global_rect().get_center()) <= 1.5, phase + " centers the forecast icon/text group in its metric column: " + label.text.replace("\n", " ") + ", group " + str(group) + ", column " + str(metric.get_global_rect()))

func _has_visible_text(node: Node, fragment: String) -> bool:
	if node is Label and node.is_visible_in_tree() and fragment in node.text.to_lower():
		return true
	for child in node.get_children(true):
		if _has_visible_text(child, fragment): return true
	return false

func _compact_card_contract(scene: Control, phase: String) -> void:
	for card in scene.hand_box.get_children():
		var title: Label = card.get_node("Title")
		var glyph: Control = card.get_node("RuneIcon")
		var cost_icon: TextureRect = card.get_node("CostIcon")
		var cost: Label = card.get_node("Cost")
		var cost_ink := _centered_label_text_rect(cost).grow(cost.get_theme_constant("outline_size"))
		var scroll: ScrollContainer = card.get_node("DescriptionScroll")
		var description: Label = scroll.find_child("Description", true, false)
		var dividers: Array = card.get_children().filter(func(child): return child is ColorRect)
		var inside: Rect2 = card.get_global_rect().grow(-6)
		_check(not card.has_node("Type") and dividers.size() == 1, phase + " compact " + title.text + " omits its category line and keeps one divider.")
		_check(inside.encloses(glyph.get_global_rect()) and inside.encloses(title.get_global_rect()) and inside.encloses(scroll.get_global_rect()), phase + " compact " + title.text + " keeps its icon, name and effect viewport at least6px inside the frame.")
		_check(cost_icon.size.x <= 25.01 and cost_icon.size.y <= 29.01 and cost.get_theme_font_size("font_size") <= 20 and card.get_global_rect().grow(-4).encloses(cost_icon.get_global_rect()) and card.get_global_rect().grow(-4).encloses(cost_ink), phase + " compact " + title.text + " keeps its smaller cost crystal and complete outlined number4px inside the card: crystal " + str(cost_icon.get_global_rect()) + ", text " + str(cost_ink))
		_check(cost_icon.get_global_rect().get_center().distance_to(cost.get_global_rect().get_center()) <= 0.5 and not cost_ink.intersects(glyph.get_global_rect()) and cost_ink.end.y <= title.get_global_rect().position.y, phase + " compact " + title.text + " centers the cost number over its crystal without touching the main icon or title.")
		if dividers.size() == 1:
			var divider: Control = dividers[0]
			_check(glyph.get_global_rect().end.y <= title.get_global_rect().position.y and title.get_global_rect().end.y <= divider.get_global_rect().position.y and divider.get_global_rect().end.y <= scroll.get_global_rect().position.y, phase + " compact " + title.text + " separates glyph, title, divider and effect into non-overlapping lanes.")
		_check(title.get_visible_line_count() == title.get_line_count() and title.get_line_count() > 0 and description.get_theme_font_size("font_size") >= 16, phase + " compact " + title.text + " shows its complete name and maintains readable effect text.")
		var info: Control = scene.info_buttons[int(card.get_meta("uid"))]
		_check(card.get_global_rect().encloses(info.get_global_rect()) and info.size.x >= 44 and info.size.y >= 44, phase + " compact " + title.text + " retains its contained44px Info target.")

func _full_page_contract(scene: Control, viewport: SubViewport, phase: String, opening_cards: bool = false) -> void:
	# The agreed normal portrait composition must fit as one screen. Native
	# shorter viewports keep their separate minimum-target scrolling fallback.
	await _layout()
	_mobile_chrome_contract(scene, phase)
	if viewport.size != Vector2i(720, 1600):
		return
	scene.page_scroll.scroll_vertical = 0
	if opening_cards: scene.hand_scroll.scroll_horizontal = 0
	await _layout()
	var scrollbar: VScrollBar = scene.page_scroll.get_v_scroll_bar()
	var overflow: float = maxf(0, scrollbar.max_value - scrollbar.page)
	_check(overflow <= 1 and scene.combat_column.get_global_rect().end.y <= 1601, "Full-screen " + phase + " has no vertical page overflow: " + str(overflow) + "px; column " + str(scene.combat_column.get_global_rect()))
	var sections := {
		"title": scene.encounter_title.get_parent(), "arena": scene.arena,
		"board": scene.board_frame, "tools": scene.wiring, "hand": scene.hand_row,
		"forecast": scene.forecast_button, "Cast": scene.cast_button,
		"navigation": scene.sound_button.get_parent()
	}
	var outside: Array[String] = []
	for title in sections:
		var section: Control = sections[title]
		if not _fully_visible(section, viewport):
			outside.append(str(title) + ": " + str(section.get_global_rect()))
	_check(outside.is_empty(), "Full-screen " + phase + " simultaneously exposes title, full arena, board, tools, hand, forecast, Cast and navigation: " + "; ".join(outside))
	var toolbar: Array = [scene.turn_pass_button, scene.stock_buttons.straight, scene.stock_buttons.corner, scene.stock_buttons.split, scene.stock_buttons.join, scene.action_buttons.erase, scene.action_buttons.rotate]
	var row_y: float = toolbar[0].get_global_rect().position.y
	_check(toolbar.all(func(button): return _fully_visible(button, viewport) and absf(button.get_global_rect().position.y - row_y) <= 1), "Full-screen " + phase + " exposes Pass, Straight, Corner, Split, Join, Remove and Rotate in one row.")
	var ordered := true
	for index in range(toolbar.size() - 1):
		ordered = ordered and toolbar[index].get_global_rect().end.x <= toolbar[index + 1].get_global_rect().position.x + 1
	_check(ordered, "Full-screen " + phase + " keeps the seven toolbar controls in the approved order without overlap.")
	if opening_cards:
		var visible_cards: Array = scene.hand_box.get_children().slice(0, 3)
		var hand_bounds: Rect2 = scene.hand_scroll.get_global_rect().grow(1)
		_check(visible_cards.size() == 3 and visible_cards.all(func(card): return _fully_visible(card, viewport) and hand_bounds.encloses(card.get_global_rect()) and _fully_visible(scene.info_buttons[int(card.get_meta("uid"))], viewport)), "Full-screen opening exposes all three normally drawn detailed cards and their Info controls without hand scrolling.")
		_check(visible_cards.all(func(card):
			var title: Label = card.get_node("Title")
			var description: ScrollContainer = card.get_node("DescriptionScroll")
			var copy: Label = description.find_child("Description", true, false)
			return title.get_visible_line_count() == title.get_line_count() and title.get_visible_line_count() > 0 and description.get_v_scroll_bar().max_value <= description.get_v_scroll_bar().page + 1 and copy.get_visible_line_count() == copy.get_line_count() and copy.get_line_count() > 0
		), "Full-screen opening shows every card name and complete normal description without clipped font lines or internal scrolling.")
	await _save(viewport, "full-screen-" + phase + "-720x1600")

func _arena_contract(scene: Control, phase: String) -> void:
	var arena: Control = scene.arena
	_check(arena.has_method("get_geometry"), phase + " arena exposes integration geometry for the delivered contracts.")
	if not arena.has_method("get_geometry"):
		return
	var details: Dictionary = arena.get_geometry()
	geometry.append({"phase": phase, "geometry": details})
	var status_k: float = arena.size.x / 841.0
	var bleed: float = arena.reference_bleed
	var k: float = (arena.size.x + 2 * bleed) / 841.0
	_check(arena.reference_art and arena.stage_scale == status_k and arena.art_clip.position.is_equal_approx(Vector2(-bleed, 0)) and arena.art_clip.size.is_equal_approx(Vector2(arena.size.x + 2 * bleed, 450 * k)) and arena.environment.scale.is_equal_approx(Vector2.ONE * k) and arena.environment.position.is_equal_approx(Vector2(0, -60) * k), phase + " reference crypt keeps the Rect(0,60,841,450) crop full-bleed with one uniform artwork transform and a separate content-scale status layout.")
	_check(arena.actor.position.is_equal_approx(Vector2(446, 368) * k) and arena.actor.scale.is_equal_approx(Vector2.ONE * 0.75 * k), phase + " reference Shadeling keeps the shared floor contact and uniform actor transform.")
	var envelope := Rect2(Vector2(272, 56) * k, Vector2(348, 336) * k)
	_check(Rect2(Vector2.ZERO, arena.art_clip.size).encloses(envelope), phase + " declared actor/lantern pose envelope fits inside the real stage.")
	_check(arena.name_label.position.y >= details.foot.y and not arena.role_label.is_visible_in_tree() and arena.health_bar.position.y >= arena.name_label.get_rect().end.y and arena.health_bar.get_rect().end.y <= arena.size.y + 1 and arena.health_label.get_rect().end.y <= arena.size.y + 1, phase + " readable name/health lanes clear the neutral foot without a BOSS role, and all live status lanes remain separate within the stage.")
	var layers: Array = arena.environment.get_layer_nodes()
	_check(layers.size() == 2 and layers[0].name == "ReferenceCleanPlate" and layers[1].name == "ReferenceVisibleScenery" and layers.all(func(layer): return not layer.centered and layer.position == Vector2(0, 60)) and layers[0].scale.is_equal_approx(Vector2(841, 450) / layers[0].texture.get_size()) and layers[1].region_enabled and layers[1].region_rect == Rect2(0, 60, 841, 450) and layers[1].scale == Vector2.ONE, phase + " clean hidden fill and original visible scenery share the approved841x450 composition; only the clean plate is normalized for its import size.")
	_check(not arena.environment.get_node("Background").visible and not arena.environment.get_node("Floor").visible and layers[0].visible and layers[1].visible and layers[1].material.shader.resource_path == "res://assets/environments/crypt/reference/visible_edges.gdshader", phase + " reference scenery replaces both old visible layers and masks the original actor/intent/status region.")
	var playing: bool = scene.game.state == "playing"
	var enemy_defeated: bool = scene.game.state == "victory"
	_check(arena.actor.is_processing() == (playing and not scene.reduced_motion) and not arena.role_label.is_visible_in_tree() and arena.name_label.text.to_lower() == str(scene.game.enemy_name).to_lower() and arena.health_label.text.contains(str(scene.game.enemy_hp)), phase + " production idle is nonblocking only while playing; terminal/reduced states stop it, with separate live name/health and no BOSS text.")
	if playing:
		_check(arena.actor.get_pose() == "neutral" and arena.actor.pose_root.position == Vector2.ZERO and is_zero_approx(arena.actor.pose_root.rotation) and absf(arena.actor.pose_root.scale.y - 1.0) <= 0.00401 and is_equal_approx(arena.actor.pose_root.scale.x, 1.0), phase + " approved neutral idle stays foot-rooted within its 0.4% breathing bound.")
	elif enemy_defeated:
		_check(arena.actor.get_state() == "defeat" and is_zero_approx(arena.actor.pose_root.modulate.a), phase + " victory keeps the defeated enemy stably faded instead of returning to idle.")
	else:
		_check(arena.actor.get_pose() == "neutral" and arena.actor.pose_root.transform == Transform2D.IDENTITY and arena.actor.pose_root.modulate == Color.WHITE, phase + " player defeat keeps the surviving enemy stationary in its restored neutral pose.")
	var sprite: Sprite2D = arena.actor.pose_sprite
	if not enemy_defeated or scene.reduced_motion:
		_check(sprite.texture == CombatSurface.ATLAS and sprite.region_enabled and sprite.region_rect == Rect2(285, 145, 295, 290) and sprite.material is ShaderMaterial and sprite.material.shader.resource_path == "res://assets/enemies/shadeling/reference/approved_actor.gdshader", phase + " neutral actor is an independently masked original atlas region, retaining the approved face, folds, lantern and boots.")
	else:
		_check(sprite.texture.resource_path == "res://assets/enemies/shadeling/hit.png" and not sprite.region_enabled and sprite.region_rect == Rect2() and sprite.material == null, phase + " defeated actor retains its fully restored ordinary pose-texture contract at the stable faded endpoint.")
	_check(arena.health_bar.value == scene.game.enemy_hp and arena.health_bar.max_value == scene.game.enemy_max_hp and (arena.intent_label.text.contains(str(scene.game.intent)) if scene.game.state == "playing" else arena.intent_label.text.to_lower().contains(scene.game.state)), phase + " health bar and intent bind to authoritative values.")

func _live_bindings(scene: Control, phase: String) -> void:
	var snapshot: Dictionary = scene.controller.snapshot()
	var spell: Dictionary = snapshot.forecast
	var incoming: int = 0 if spell.valid and spell.damage >= snapshot.enemy_hp else maxi(0, int(snapshot.intent) - int(spell.shield)) if spell.valid else int(snapshot.intent)
	_check(scene.forecast_values == {"damage": spell.damage, "shield": spell.shield, "cost": spell.cost, "incoming": incoming}, phase + " persistent forecast agrees with the authoritative snapshot.")
	_check(scene.pile_values.draw_pile.text == str(snapshot.draw_pile.size()) and scene.pile_values.discard_pile.text == str(snapshot.discard_pile.size()) and scene.hand_count.text == "Hand %d" % snapshot.hand.size() and not scene.status.is_visible_in_tree(), phase + " live piles and hand count agree with the authoritative snapshot without a suggestion line.")
	_check(scene.hand_box.get_child_count() == snapshot.hand.size() and scene.info_buttons.size() == snapshot.hand.size() and scene.hand_box.get_children().map(func(card): return int(card.get_meta("uid", -1))) == snapshot.hand.map(func(card): return int(card.uid)), phase + " detailed cards/Info preserve every live hand identity.")
	_check(scene.cast_cost.text == (str(spell.cost) if spell.valid else "—"), phase + " the pointed Cast displays the live energy cost or unavailable marker.")
	_check(scene.hand_box.get_children().all(func(card): return card.has_meta("rc_skin") and card.get_meta("rc_skin").get_script() == CombatSurface and card.get_meta("rc_skin").kind.begins_with("card_") and card.has_meta("uid")), phase + " each live card consumes its generated painted card skin with live identity.")
	_check(scene.hand_box.get_children().all(func(card):
		var cost_font: Font = card.get_node("Cost").get_theme_font("font")
		var description_font: Font = card.get_node("DescriptionScroll/DescriptionContent/Description").get_theme_font("font")
		return card.get_node("Title").get_theme_font("font") == Ui.COMBAT_LABEL_FONT and description_font is FontVariation and description_font.base_font == Ui.COMBAT_BODY_FONT.base_font and description_font.variation_opentype == Ui.COMBAT_BODY_FONT.variation_opentype and description_font.spacing_top == -3 and description_font.spacing_bottom == -3 and cost_font is FontVariation and cost_font.base_font == Ui.COMBAT_VALUE_FONT.base_font and cost_font.variation_opentype == Ui.COMBAT_VALUE_FONT.variation_opentype and cost_font.spacing_top == -4 and cost_font.spacing_bottom == -4
	), phase + " live card titles, descriptions and costs retain the normal-width Combat font families with their measured compact line spacing.")

func _has_texture(node: Node, path: String) -> bool:
	if node is TextureRect or node is Sprite2D:
		var source := _source_texture(node.texture)
		if source != null and source.resource_path == path:
			return true
	for child in node.get_children(true):
		if _has_texture(child, path):
			return true
	return false

func _source_texture(texture: Texture2D) -> Texture2D:
	# AtlasTexture regions do not allocate independent decoded images. Audit
	# the complete imported backing texture, including nested atlas wrappers.
	while texture is AtlasTexture:
		texture = texture.atlas
	return texture

func _resource_contract(scene: Control) -> void:
	_check(scene.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and scene.texture_repeat == CanvasItem.TEXTURE_REPEAT_DISABLED, "Production root uses linear filtering with repeat disabled.")
	_collect_textures(scene)
	for pose_name in scene.arena.actor.get_retained_pose_names():
		if pose_name != &"neutral":
			_record_texture(load("res://assets/enemies/shadeling/" + String(pose_name) + ".png"))
	for texture in scene.cells[0].SYMBOLS.values():
		_record_texture(texture)
	_record_texture(ReferenceIcons.ATLAS)
	var icon_path := "res://assets/ui/combat/reference/icons.png"
	_check(textures.has(icon_path) and textures[icon_path].width == 768 and textures[icon_path].height == 576 and textures[icon_path].rgba8_bytes == 1769472, "Retained generated board/attack/editing glyphs share one size-limited768x576 allocation (1,769,472 RGBA8 bytes), deduplicated by source path.")
	var status_path := GeneratedStatsOracle.SOURCE_PATH
	_check(textures.has(status_path) and textures[status_path].width == 768 and textures[status_path].height == 305 and textures[status_path].rgba8_bytes == 936960,"Generated painted status frame is included in actual consumer resources as a768x305 allocation.")
	_check(FileAccess.get_sha256(status_path) == GeneratedStatsOracle.SOURCE_HASH,"Runtime status-frame PNG preserves the original image generation output unchanged.")
	_reference_icon_contract()
	_check(scene.hand_box.get_children().all(func(card):
		var name := str(card.get_meta("rc_card_data").icon)
		var source: Texture2D = _source_texture(card.get_node("RuneIcon").texture)
		var approved := not ReferenceIcons.source_geometry(name).is_empty()
		var expected := "res://assets/ui/combat/reference/approved-atlas.png" if approved else icon_path if ReferenceIcons.REGIONS.has(name) else "res://assets/icons/runes/core/" + name + ".svg"
		return source.resource_path == expected and textures.has(expected) and (not approved or card.get_node("RuneIcon").material == Ui.combat_icon_material(name))
	), "Every compact card uses its painted reference icon where present and the canonical glyph fallback otherwise.")
	for path in textures:
		var texture: Texture2D = load(path)
		var picture := texture.get_image()
		_check(picture != null and not picture.has_mipmaps(), "Actual consumer texture has no mipmaps: " + path)
		var imported := ConfigFile.new()
		var ok := imported.load(path + ".import") == OK
		_check(ok and imported.get_value("params", "compress/mode", -1) == 0 and not imported.get_value("params", "mipmaps/generate", true) and imported.get_value("params", "process/fix_alpha_border", false), "Lossless/alpha-border import policy is preserved: " + path)
		if path.ends_with(".svg"):
			_check(texture.get_size() == Vector2(256, 256), "Imported production symbol is the delivered 2x raster: " + path)
	_check(textures.has("res://assets/environments/crypt/reference/arena.png") and textures.has("res://assets/ui/combat/reference/approved-atlas.png") and not textures.has("res://assets/enemies/shadeling/reference/neutral.png"), "Actual scene shares the approved atlas between outer scenery, neutral actor and UI; the clean crypt fills the fixed center and the regenerated neutral is no longer loaded.")
	_check(not textures.keys().any(func(path): return "/shadeling/parts/" in path) and scene.arena.actor.get_retained_pose_names().size() == 3 and textures.has("res://assets/enemies/shadeling/attack.png") and textures.has("res://assets/enemies/shadeling/hit.png"), "Production warms the approved atlas plus two existing512 pose textures before contact, with no optional part rig.")
	_skin_borders(scene)

func _approved_arena_raster_contract() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(841, 450)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment = load("res://assets/environments/crypt/environment.tscn").instantiate()
	environment.reference_art = true
	environment.position = Vector2(0, -60)
	viewport.add_child(environment)
	var actor = load("res://assets/enemies/shadeling/character.tscn").instantiate()
	actor.reference_neutral = true
	actor.position = Vector2(446, 368)
	actor.scale = Vector2.ONE * 0.75
	viewport.add_child(actor)
	actor.show_pose(&"neutral")
	await _layout()
	await _save(viewport, "approved-actor-clean-center-arena-841x450")
	var combined: Image = viewport.get_texture().get_image()
	var source: Image = CombatSurface.ATLAS.get_image()
	# RC-017 intentionally replaces the center and feathers into retained outer
	# scenery. Compare every source pixel outside that documented composition.
	var holes := [Rect2i(374, 99, 88, 61), Rect2i(395, 410, 56, 24), Rect2i(368, 430, 110, 29), Rect2i(304, 453, 230, 41)]
	var clean_center_with_feather := Rect2i(236, 50, 378, 443)
	var compared := 0
	var changed := 0
	for y in 450:
		for x in 841:
			var point := Vector2i(x, y + 60)
			if clean_center_with_feather.has_point(point) or holes.any(func(hole): return hole.has_point(point)):
				continue
			compared += 1
			var expected := source.get_pixelv(point)
			var actual := combined.get_pixel(x, y)
			if maxf(absf(expected.r - actual.r), maxf(absf(expected.g - actual.g), absf(expected.b - actual.b))) > 1.0 / 255.0:
				changed += 1
	_check(compared > 210000 and changed == 0, "Approved outer scenery remains source-identical outside the documented broad clean-center feather and live UI holes: %d/%d differ." % [changed, compared])
	actor.hide()
	await _layout()
	await _save(viewport, "revealed-clean-center-arena-841x450")
	var revealed: Image = viewport.get_texture().get_image()
	environment.get_layer_nodes()[1].hide()
	await _layout()
	await RenderingServer.frame_post_draw
	var clean_plate: Image = viewport.get_texture().get_image()
	var clean_samples := 0
	var clean_maximum_error := 0.0
	for y in range(35, 386):
		for x in range(281, 569):
			var difference := revealed.get_pixel(x, y) - clean_plate.get_pixel(x, y)
			clean_maximum_error = maxf(clean_maximum_error, maxf(absf(difference.r), maxf(absf(difference.g), absf(difference.b))))
			clean_samples += 1
	_check(clean_samples == 101088 and clean_maximum_error <= 1.0 / 255.0, "The entire fixed center equals the actual clean plate when the actor is removed, including outside its old silhouette; no duplicate actor or silhouette-shaped scenery seam remains.")
	paint_samples.append({"surface": "rc017-clean-center", "samples": clean_samples, "maximum_rgb_error": clean_maximum_error, "outer_scenery_samples": compared, "outer_scenery_changed": changed})
	actor.show()
	environment.hide()
	await _layout()
	await _save(viewport, "approved-actor-isolated-841x450")
	var isolated: Image = viewport.get_texture().get_image()
	var opaque := 0
	var original := true
	for y in 450:
		for x in 841:
			var actual := isolated.get_pixel(x, y)
			if actual.a < 0.99:
				continue
			opaque += 1
			var expected := source.get_pixel(x, y + 60)
			original = original and maxf(absf(expected.r - actual.r), maxf(absf(expected.g - actual.g), absf(expected.b - actual.b))) <= 1.0 / 255.0
	_check(opaque > 35000 and opaque < 55000 and original, "Separate neutral actor samples original painted pixels without generated replacement or baked text.")
	var actor_points := [Vector2i(425, 199), Vector2i(330, 280), Vector2i(535, 320), Vector2i(351, 415), Vector2i(524, 419)]
	_check(actor_points.all(func(point): return isolated.get_pixel(point.x, point.y - 60).a > 0.99), "Approved actor mask preserves face, lantern, free hand and both boots.")
	var label_points := [Vector2i(407, 128), Vector2i(442, 132), Vector2i(421, 422), Vector2i(421, 445), Vector2i(421, 471)]
	_check(label_points.all(func(point): return isolated.get_pixel(point.x, point.y - 60).a < 0.01), "Separate actor excludes original intent, BOSS/name and health artwork so every status value remains live.")
	actor.show_pose(&"attack")
	_check(not actor.pose_sprite.region_enabled and actor.pose_sprite.material == null and actor.pose_sprite.texture.get_size() == Vector2(512, 512), "Existing attack pose restores its full512 canvas and ordinary material path.")
	actor.show_pose(&"neutral")
	_check(actor.pose_sprite.region_enabled and actor.pose_sprite.material != null and actor.get_attachment_position(&"foot") == Vector2.ZERO, "Returning to approved neutral restores its mask while preserving the foot-local actor API.")
	viewport.queue_free()
	await process_frame

func _painted_raster_contract(scene: Control) -> void:
	# Bounds alone missed the rectangular stats paint and old WIRING paper
	# baked into the toolbar cap. Render the real consumer's skin configuration
	# over transparency and inspect pixels independently of its content API.
	var consumers: Array = [scene.combat_stats.get_meta("combat_surface"), scene.wiring.get_parent().get_meta("combat_surface"), scene.combat_heading.get_meta("combat_surface"), scene.draw_button.get_meta("combat_surface"), scene.discard_button.get_meta("combat_surface")]
	for consumer in consumers:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(consumer.size.ceil())
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var painted: Control
		var identity: String
		if consumer.get_script() == ReferencePile:
			painted = ReferencePile.new()
			painted.pile_kind = consumer.pile_kind
			identity = "pile-" + str(consumer.pile_kind)
		else:
			painted = CombatSurface.new()
			painted.kind = consumer.kind
			painted.art_scale = consumer.art_scale
			painted.divisions = consumer.divisions
			identity = str(consumer.kind)
		painted.size = consumer.size
		viewport.add_child(painted)
		await _layout()
		await RenderingServer.frame_post_draw
		var picture: Image = viewport.get_texture().get_image()
		var samples := {"surface": identity, "size": [painted.size.x, painted.size.y]}
		if identity == "stats":
			var corners_clear := true
			for corner in [Vector2i(0,0),Vector2i(0,27),Vector2i(picture.get_width()-1,27),Vector2i(0,picture.get_height()-1),Vector2i(picture.get_width()-1,picture.get_height()-1)]:
				corners_clear = corners_clear and picture.get_pixelv(corner).a <= 0.01
			var middle := picture.get_pixel(int(painted.size.x / 2),27)
			_check(corners_clear and middle.a >= 0.99 and middle.b > middle.r+0.05,"Generated painted stats frame excludes exterior paint and retains an opaque blue-slate well.")
			var continuity := GeneratedStatsOracle.perimeter_continuity(picture)
			_check(continuity.complete,"Generated status painting has a continuous closed gold perimeter including both side rails and all corner joins: "+str(continuity))
			var comparison := GeneratedStatsOracle.source_comparison(picture,painted.texture.get_image())
			_check(painted.texture.resource_path == GeneratedStatsOracle.SOURCE_PATH and comparison.samples > 10000 and comparison.mean_rgb_error <= 0.008 and comparison.maximum_rgb_error <= 0.035,"Rendered stats face, rails and painted dividers match the independently sampled generated PNG: "+str(comparison))
			var divided := true
			for division in [1,2]:
				var center := roundi(painted.size.x*division/3.0)
				for row in range(8,picture.get_height()-8):
					var gold := false
					for column in range(center-10,center+11): gold = gold or GeneratedStatsOracle.is_gold(picture.get_pixel(column,row))
					divided = divided and gold
			_check(divided,"Both generated painted dividers extend without gaps between the top and bottom rails.")
			samples.merge({"corners_clear":corners_clear,"continuity":continuity,"generated_source":comparison,"painted_dividers_continuous":divided})
		elif identity == "toolbar":
			var slate := _raster_patch(picture, Vector2i(25, 50), 1)
			samples["left_slate_rgb"] = [slate.r, slate.g, slate.b]
			_check(slate.r < 0.2 and slate.b > slate.r + 0.015 and slate.a >= 0.99, "Toolbar raster has clean blue slate beside Pass; the old WIRING parchment edge is absent from its left cap.")
		elif identity == "heading":
			var left := picture.get_pixel(0, 0)
			var right := picture.get_pixel(int(painted.size.x) - 1, 0)
			samples.merge({"left_alpha": left.a, "right_alpha": right.a})
			_check(left.a >= 0.99 and right.a >= 0.99, "Full-width header background paints both outer corners rather than leaving exposed page strips.")
		else:
			var comparison := _pile_pixel_comparison(picture, painted)
			samples.merge(comparison)
			_check(comparison.samples > 200 and comparison.mean_rgb_error <= 0.025, "The rendered " + str(painted.pile_kind) + " emblem and front-card texture match the approved reference pixels after uniform resampling: mean RGB error " + str(comparison.mean_rgb_error))
			var opaque_gap_pixels := 0
			var gap_start := ceili(_reference_pile_rect(painted, "count").end.y)
			for y in range(gap_start, int(painted.size.y) - 23):
				for x in picture.get_width():
					if picture.get_pixel(x, y).a > 0.01: opaque_gap_pixels += 1
			samples["caption_gap_opaque_pixels"] = opaque_gap_pixels
			_check(opaque_gap_pixels == 0, "The rendered " + str(painted.pile_kind) + " leaves a transparent gap below its count plaque for the live caption, with no baked caption fragments: " + str(opaque_gap_pixels) + " painted pixels.")
		paint_samples.append(samples)
		await _save(viewport, "paint-raster-" + identity)
		viewport.queue_free()
		await process_frame
	await _card_corner_raster_contract()

func _backdrop_edge_raster_contract(scene: Control, suffix: String) -> void:
	# The stray lower-right rail came from the full-page architecture strip,
	# not the board Control. Render its actual page size at each viewport so
	# the test follows vertical page stretching rather than a fixed screen y.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(scene.combat_backdrop.size.ceil())
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var backdrop := ReferenceBackdrop.new()
	backdrop.size = scene.combat_backdrop.size
	viewport.add_child(backdrop)
	await _layout()
	await RenderingServer.frame_post_draw
	var picture: Image = viewport.get_texture().get_image()
	var k := backdrop.size.x / 841.0
	# This band spans both the former subpixel underpaint seam and the old
	# atlas strip's first columns, beside the original lower board bevel.
	var seam := Rect2i(floori(backdrop.size.x - 24 * k), floori(backdrop.size.y * 1100.0 / 1870.0), ceili(5 * k), ceili(backdrop.size.y * 155.0 / 1870.0))
	var gold_pixels := 0
	var blue_pixels := 0
	for y in range(seam.position.y, seam.end.y):
		for x in range(seam.position.x, seam.end.x):
			var color := picture.get_pixel(x, y)
			if color.r > 0.33 and color.g > 0.18 and color.b < color.r * 0.55: gold_pixels += 1
			if color.b > color.r and color.b > color.g: blue_pixels += 1
	_check(gold_pixels == 0 and blue_pixels > seam.size.x * seam.size.y * 0.9, suffix + " full-page backdrop keeps the lower-right seam blue rock, without a second gold board rail at page height" + str(backdrop.size.y) + ": " + str(gold_pixels) + " gold pixels.")
	paint_samples.append({"surface": "backdrop-right-edge", "viewport": suffix, "page_size": [backdrop.size.x, backdrop.size.y], "sample_rect": [seam.position.x, seam.position.y, seam.size.x, seam.size.y], "gold_pixels": gold_pixels, "blue_pixels": blue_pixels})
	await _save(viewport, "backdrop-right-edge-" + suffix)
	viewport.queue_free()
	await process_frame

func _card_corner_raster_contract() -> void:
	# Exercise complete factory cards, including their live cost overlay. The
	# former bottom-left patch left black below-frame pixels at this upper rim.
	var expected := {"damage": Color8(246, 155, 46), "shield": Color8(54, 144, 47), "technique": Color8(127, 33, 160), "mixed": Color8(127, 33, 160)}
	for kind in expected:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(149, 146)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var card: Control = Ui.card({"compact": true, "kind": kind, "name": kind.capitalize(), "cost": 1, "icon": "shield" if kind == "shield" else "spark", "description": ""}, {}, 149)
		card.theme = Ui.THEME
		card.size = Vector2(149, 146)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		viewport.add_child(card)
		await _layout()
		await RenderingServer.frame_post_draw
		var picture: Image = viewport.get_texture().get_image()
		var point := picture.get_pixel(3, 8)
		var reference: Color = expected[kind]
		var error := maxf(absf(point.r - reference.r), maxf(absf(point.g - reference.g), absf(point.b - reference.b)))
		_check(error <= 0.04 and point.a >= 0.99, "Factory " + kind + " card has its expected colored top-left rim rather than a black gap or blue cost fragment: " + str(point))
		var continuous := true
		var rim: Array = []
		for y in range(7, 11):
			var color := picture.get_pixel(3, y)
			rim.append([color.r, color.g, color.b, color.a])
			continuous = continuous and color.a >= 0.99 and maxf(color.r, maxf(color.g, color.b)) > 0.25 and not (color.b > color.r + 0.15 and color.g > color.r + 0.15)
		_check(continuous, "Factory " + kind + " card has a continuous material-colored upper-left vertical rim through the previously broken pixels, with no cyan cost-art leakage.")
		paint_samples.append({"surface": "factory-card-" + kind, "size": [card.size.x, card.size.y], "corner_rgb_error": error, "rim_pixels": rim})
		await _save(viewport, "factory-card-" + kind + "-corner")
		viewport.queue_free()
		await process_frame

func _raster_patch(picture: Image, center: Vector2i, radius: int) -> Color:
	var value := Color(0, 0, 0, 0)
	var count := 0
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			value += picture.get_pixel(x, y)
			count += 1
	return value / float(count)

func _pile_pixel_comparison(picture: Image, painted: Control) -> Dictionary:
	var atlas: Image = ReferencePile.ATLAS.get_image()
	var source: Dictionary = REFERENCE_PILE_REGIONS[painted.pile_kind]
	var body: Rect2 = source.body
	var face: Rect2 = source.glyph
	var lane := Vector2(painted.size.x, painted.size.y - 20)
	var scale_factor := minf(lane.x / body.size.x, lane.y / body.size.y)
	var offset := (lane - body.size * scale_factor) * 0.5
	var ratio := Vector2(atlas.get_size()) / Vector2(841, 1870)
	var error := 0.0
	var count := 0
	for y in picture.get_height():
		for x in picture.get_width():
			var reference_point := body.position + (Vector2(x + 0.5, y + 0.5) - offset) / scale_factor
			# Emblem regions are entirely inside the opaque front face and clear
			# of the intentionally replaced live numeral and outside silhouette.
			if not face.has_point(reference_point): continue
			var expected := _bilinear_pixel(atlas, reference_point * ratio - Vector2(0.5, 0.5))
			var actual := picture.get_pixel(x, y)
			error += (absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)) / 3.0
			count += 1
	return {"samples": count, "mean_rgb_error": error / maxi(count, 1)}

func _bilinear_pixel(picture: Image, point: Vector2) -> Color:
	var x := clampi(floori(point.x), 0, picture.get_width() - 2)
	var y := clampi(floori(point.y), 0, picture.get_height() - 2)
	var top := picture.get_pixel(x, y).lerp(picture.get_pixel(x + 1, y), point.x - x)
	var bottom := picture.get_pixel(x, y + 1).lerp(picture.get_pixel(x + 1, y + 1), point.x - x)
	return top.lerp(bottom, point.y - y)

func _reference_icon_contract() -> void:
	var scale: Vector2 = ReferenceIcons.ATLAS.get_size() / Vector2(1448, 1086)
	for name in ReferenceIcons.REGIONS:
		if not ReferenceIcons.source_geometry(name).is_empty(): continue
		var texture: AtlasTexture = Ui.combat_icon_texture(name)
		var source: Rect2 = ReferenceIcons.REGIONS[name]
		_check(texture.atlas == ReferenceIcons.ATLAS and texture.region.is_equal_approx(Rect2(source.position * scale, source.size * scale)) and texture.filter_clip and Rect2(Vector2.ZERO, ReferenceIcons.ATLAS.get_size()).encloses(texture.region), "Reference " + name + " samples its measured icon region at the imported texture scale without leaking adjacent atlas cells.")
	for name in ["spark", "shield"]:
		var board: AtlasTexture = ReferenceIcons.board_texture(name)
		var source: Rect2 = ReferenceIcons.REGIONS[name]
		var visible_fraction := 0.75 if name == "spark" else 0.68
		_check(board.atlas == ReferenceIcons.ATLAS and board.region.is_equal_approx(Rect2(source.position*scale,source.size*scale)) and absf(board.get_width() - board.get_height()) <= 1 and absf(maxf(board.region.size.x, board.region.size.y) / board.get_width() - visible_fraction) <= 0.005 and board.margin.position.is_equal_approx(board.margin.size * 0.5), "Board " + name + " retains its generated glyph with centered virtual padding preserving the canonical visible fraction and square port canvas.")
	var approved := {"menu":Rect2(118,1790,49,42),"map":Rect2(295,1788,63,45),"guide":Rect2(478,1788,67,46),"sound_on":Rect2(665,1788,61,46),"health":Rect2(63,521,51,46),"energy":Rect2(376,522,32,45),"shield":Rect2(395,1426,50,52),"focus":Rect2(575,1430,66,45)}
	for name in approved:
		var icon: TextureRect = Ui.combat_icon(name,Vector2(40,40))
		var texture: AtlasTexture = icon.texture
		_check(texture.atlas == CombatSurface.ATLAS and texture.region == approved[name] and texture.filter_clip and icon.material is ShaderMaterial and icon.material.shader.resource_path == "res://assets/ui/combat/reference/navigation_mask.gdshader", "Original " + name + " uses the independently measured approved source and a contour mask without rectangular backdrop paint.")
		icon.free()
	_check(Ui.combat_icon_material("sound_off") == null, "Sound Off retains its deliberate SVG fallback without an unrelated approved-art mask.")
	var shared := Ui.icon("energy")
	_check(shared.texture.resource_path == "res://assets/icons/resources/energy.svg", "Shared non-Combat icon constructors retain their canonical SVG resources.")
	shared.free()

func _has_approved_icon(node: Node, name: String) -> bool:
	if node is TextureRect and node.texture == Ui.combat_icon_texture(name) and node.material == Ui.combat_icon_material(name): return true
	for child in node.get_children(true):
		if _has_approved_icon(child,name): return true
	return false

func _collect_textures(node: Node) -> void:
	if node is Sprite2D or node is TextureRect:
		_record_texture(node.texture)
	if node is Button:
		_record_texture(node.icon)
	if node.has_meta("rc_skin"):
		_record_texture(node.get_meta("rc_skin").texture)
	# All generated surfaces preload together, including variants absent from
	# the opening hand. Count this actual resident library, not only visible art.
	if node.get_script() == CombatSurface:
		for texture in CombatSurface.TEXTURES.values():
			_record_texture(texture)
	if node.get_script() == ReferenceBackdrop:
		_record_texture(ReferenceBackdrop.ATLAS)
		_record_texture(ReferenceBackdrop.UNDERPAINT)
	if node is Control:
		var styles: Array = ["background", "fill"] if node is ProgressBar else ["panel"] if node is PanelContainer else ["scroll", "scroll_focus", "grabber", "grabber_highlight", "grabber_pressed"] if node is ScrollBar else []
		for style_name in styles:
			var style: StyleBox = node.get_theme_stylebox(style_name)
			if style is StyleBoxTexture:
				_record_texture(style.texture)
	for child in node.get_children(true):
		_collect_textures(child)

func _record_texture(texture: Texture2D) -> void:
	texture = _source_texture(texture)
	if texture != null and not texture.resource_path.is_empty():
		textures[texture.resource_path] = {"width": texture.get_width(), "height": texture.get_height(), "rgba8_bytes": texture.get_width() * texture.get_height() * 4}

func _texture_bytes() -> int:
	var total := 0
	for record in textures.values():
		total += int(record.rgba8_bytes)
	return total

func _skin_borders(node: Node) -> void:
	if node is Control and node.is_visible_in_tree() and node.has_meta("rc_skin"):
		var skin = node.get_meta("rc_skin")
		_check(skin.is_visible_in_tree(), "The recorded painted skin is rendered rather than retained hidden for " + str(node.get_path()))
		if skin.get_script() != CombatSurface and skin.get_script() != ReferencePile:
			var source: Vector2 = skin.texture.get_size()
			var caps: Vector4 = skin.source_caps
			_check(caps.x + caps.z < source.x and caps.y + caps.w < source.y, "Painted nine-slice source retains a positive center for " + str(node.get_path()))
			if not skin.proportional_caps:
				var target: Vector4 = skin.destination_caps
				_check(target.x + target.z < node.size.x and target.y + target.w < node.size.y, "Painted nine-slice destination retains a positive center for " + str(node.get_path()))
	if node.get_script() == CombatSurface and node.is_visible_in_tree():
		var geometry: Dictionary = node.get_geometry()
		var source: Rect2 = geometry.source_rect
		var destination: Rect2 = geometry.destination_rect
		var source_caps: Vector4 = geometry.source_caps
		var destination_caps: Vector4 = geometry.destination_caps
		_check(node.texture != null and Rect2(Vector2.ZERO, Vector2(node.texture.get_size())).encloses(source), "Generated surface samples inside its imported texture for " + str(node.get_path()))
		_check(source_caps.x + source_caps.z < source.size.x and source_caps.y + source_caps.w < source.size.y and destination_caps.x + destination_caps.z < destination.size.x and destination_caps.y + destination_caps.w < destination.size.y, "Generated nine-slice retains positive source and destination centers for " + str(node.get_path()))
		_check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE and node.focus_mode == Control.FOCUS_NONE and node.get_combined_minimum_size() == Vector2.ZERO, "Generated art does not take input or enlarge the live layout for " + str(node.get_path()))
	elif node.get_script() == ReferencePile and node.is_visible_in_tree():
		var details: Dictionary = node.get_geometry()
		var expected_body: Rect2 = REFERENCE_PILE_REGIONS[node.pile_kind].body
		var target: Rect2 = details.destination_rect
		_check(details.source_rect == expected_body and not details.sliced and absf(target.size.x / expected_body.size.x - target.size.y / expected_body.size.y) <= 0.00001 and Rect2(Vector2.ZERO, node.size).encloses(target), "Approved " + node.pile_kind + " pile samples its distinct original art with one uniform contained transform.")
		_check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE and node.focus_mode == Control.FOCUS_NONE and node.get_combined_minimum_size() == Vector2.ZERO, "Original pile art does not take input or enlarge the live layout for " + str(node.get_path()))
	for child in node.get_children(true):
		_skin_borders(child)

func _editing(scene: Control, viewport: SubViewport, suffix: String) -> void:
	var cell_index: int = helper._empty_cells(scene.game.board)[0]
	var before: Dictionary = scene.controller.snapshot()
	scene.action_buttons.rotate.pressed.emit()
	_check(scene.action_buttons.rotate.disabled and _same_gameplay(scene.controller.snapshot(), before), suffix + " Rotate without a selected piece remains disabled and rejects direct callbacks despite having no corner badge.")
	await _reveal(scene, scene.stock_buttons.straight)
	_check(_fully_visible(scene.stock_buttons.straight, viewport), suffix + " connector input region can be exposed.")
	touch._tap(viewport, scene.stock_buttons.straight)
	_check(scene.selected_tool == "straight" and scene.stock_buttons.straight.button_pressed, suffix + " real tap selects the visibly marked connector.")
	_check(not scene.status.is_visible_in_tree(), suffix + " connector selection keeps the suggestion line hidden.")
	await _full_page_contract(scene, viewport, "editing-feedback")
	await _reveal(scene, scene.cells[cell_index])
	touch._tap(viewport, scene.cells[cell_index])
	_check(scene.game.board[cell_index].get("kind") == "straight" and scene.game.stock.straight == before.stock.straight - 1, suffix + " the painted board input target installs exactly one connector.")
	scene._cancel_selection()
	touch._tap(viewport, scene.cells[cell_index])
	await _reveal(scene, scene.action_buttons.rotate)
	touch._tap(viewport, scene.action_buttons.rotate)
	_check(scene.game.board[cell_index].rotation == 1 and scene.selected_cell == cell_index and scene.cells[cell_index].chosen, suffix + " real Rotate keeps visible selected-cell feedback.")
	await _board_view(scene)
	await _save(viewport, "selected-rotated-board-" + suffix)
	await _reveal(scene, scene.action_buttons.erase)
	touch._tap(viewport, scene.action_buttons.erase)
	await _reveal(scene, scene.cells[cell_index])
	touch._tap(viewport, scene.cells[cell_index])
	_check(scene.game.board[cell_index].is_empty() and scene.game.stock == before.stock and helper._stock_labels(scene), suffix + " real Remove refunds the connector and updates stock labels.")
	scene._cancel_selection()

func _inspection(scene: Control, viewport: SubViewport, suffix: String) -> void:
	var uid: int = scene.game.hand[0].uid
	var origin: Button = scene.info_buttons[uid]
	await _reveal(scene, origin)
	var before: Dictionary = scene.controller.snapshot()
	touch._tap(viewport, origin)
	await _layout()
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport.size))
	_check(scene.inspector.visible and bounds.encloses(scene.inspector_panel.get_global_rect()) and bounds.encloses(scene.inspector_close.get_global_rect()) and scene.controller.snapshot() == before, suffix + " tapping Info opens a bounded read-only modal.")
	_mobile_chrome_contract(scene, suffix + " card inspector")
	await _save(viewport, "card-details-" + suffix)
	touch._tap(viewport, scene.inspector_close)
	await _layout()
	_check(not scene.inspector.visible and viewport.gui_get_focus_owner() == null and scene.controller.snapshot() == before, suffix + " tapping Close dismisses card details without desktop focus or gameplay changes.")
	await touch._forecast_display(scene, viewport, self, _check, suffix + " incomplete")
	_mobile_chrome_contract(scene, suffix + " forecast display")

func _invalid_and_energy(scene: Control, viewport: SubViewport, suffix: String) -> void:
	var pair: Dictionary = helper._endpoints(scene.game.board)
	var orientation: int = scene.game.board[pair.begin].rotation
	helper._rotate_to(scene, pair.begin, (orientation + 1) % 4)
	_check(not scene.game.forecast.valid and scene.cast_button.disabled and not scene.forecast_reason.text.is_empty(), suffix + " a disconnected endpoint shows its live reason and unavailable Cast.")
	_mobile_chrome_contract(scene, suffix + " invalid Cast")
	var incomplete: Dictionary = scene.controller.snapshot()
	scene.cast_button.pressed.emit()
	_check(_same_gameplay(scene.controller.snapshot(), incomplete), suffix + " rejected invalid Cast callbacks cannot mutate resources/turn/board (rejection log may change).")
	await _bottom_view(scene)
	_forecast_lanes(scene, viewport, suffix + " incomplete")
	await _save(viewport, "incomplete-bottom-" + suffix)
	helper._rotate_to(scene, pair.begin, orientation)
	var energy_before: int = scene.game.energy
	_check(scene.game.forecast.valid and scene.game.forecast.cost > 0, suffix + " restoring endpoint rotation restores the paid spell forecast.")
	scene.controller._combat.energy = int(scene.game.forecast.cost) - 1
	scene._refresh()
	var low_energy: Dictionary = scene.controller.snapshot()
	scene.cast_button.pressed.emit()
	_check(scene.cast_button.disabled and scene.forecast_reason.text.contains("have") and _same_gameplay(scene.controller.snapshot(), low_energy), suffix + " unaffordable preview disables Cast and rejects repeated callback without spending.")
	_mobile_chrome_contract(scene, suffix + " unaffordable Cast")
	await _bottom_view(scene)
	_forecast_lanes(scene, viewport, suffix + " unaffordable")
	await _save(viewport, "unaffordable-bottom-" + suffix)
	scene.controller._combat.energy = energy_before
	scene._refresh()

func _pass_cancel(scene: Control, viewport: SubViewport, suffix: String) -> void:
	await _reveal(scene, scene.turn_pass_button)
	var before: Dictionary = scene.controller.snapshot()
	touch._tap(viewport, scene.turn_pass_button)
	await _layout()
	_check(scene.inspector.visible and scene.inspector_confirm_pass.visible and scene.inspector_text.text.contains(str(scene.game.intent)) and scene.inspector_text.text.contains("clear") and scene.controller.snapshot() == before, suffix + " visible Pass opens incoming-damage and cleanup confirmation.")
	_mobile_chrome_contract(scene, suffix + " Pass confirmation")
	await _save(viewport, "pass-confirmation-" + suffix)
	touch._tap(viewport, scene.inspector_close)
	await _layout()
	_check(not scene.inspector.visible and scene.controller.snapshot() == before and viewport.gui_get_focus_owner() == null, suffix + " Cancel Pass preserves combat without desktop focus.")
	await _full_page_contract(scene, viewport, "pass-cancelled")

func _empty_hand_pass(scene: Control, viewport: SubViewport, suffix: String) -> void:
	scene._exact_replay()
	# Explicit presentation boundary, leaving shipped draw/ownership unchanged.
	scene.controller._combat.hand.clear()
	scene._refresh()
	await _reveal(scene, scene.turn_pass_button)
	var before: Dictionary = scene.controller.snapshot()
	touch._tap(viewport, scene.turn_pass_button)
	await _layout()
	_check(scene.game.hand.is_empty() and scene.inspector_confirm_pass.visible and not scene.turn_pass_button.disabled, suffix + " empty-hand incomplete turn can still reach Pass confirmation.")
	touch._tap(viewport, scene.inspector_confirm_pass)
	PresentationSupport.finish(scene)
	await _layout()
	_check(scene.game.turn == before.turn + 1 and scene.game.player_hp == maxi(0, int(before.player_hp) - int(before.intent)) and helper._only_endpoints(scene.game.board), suffix + " confirmed empty-hand Pass advances exactly one turn and applies displayed attack.")
	_live_bindings(scene, suffix + " after empty-hand Pass")
	await _full_page_contract(scene, viewport, "after-pass")
	await _bottom_view(scene)
	await _save(viewport, "after-pass-bottom-" + suffix)

func _resize(scene: Control, viewport: SubViewport, setup: Dictionary) -> void:
	helper._inject(scene, setup)
	var before: Dictionary = scene.controller.snapshot()
	for dimensions in [Vector2i(360, 640), Vector2i(450, 1000), Vector2i(720, 1600)]:
		viewport.size = dimensions
		await _layout()
		var suffix := "%dx%d" % [dimensions.x, dimensions.y]
		_layout_contract(scene, viewport, "resize " + suffix)
		_check(scene.controller.snapshot() == before, "Resize to " + suffix + " does not alter gameplay or draw new cards.")
		await _board_view(scene)
		await _save(viewport, "resize-board-" + suffix)
		var index: int = helper._empty_cells(scene.game.board)[0]
		touch._tap(viewport, scene.cells[index])
		_check(scene.selected_cell == index, "Resize to " + suffix + " preserves cell input alignment.")
		scene._cancel_selection()
		await _reveal(scene, scene.turn_pass_button)
		touch._tap(viewport, scene.turn_pass_button)
		await _layout()
		_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(scene.inspector_panel.get_global_rect()), "Resize to " + suffix + " keeps Pass modal inside the viewport.")
		touch._tap(viewport, scene.inspector_close)
		await _layout()
		await _full_page_contract(scene, viewport, "resized-back")

func _conflict(scene: Control, viewport: SubViewport, setup: Dictionary) -> void:
	var model = helper._inject(scene, setup)
	# Known closed cross-link from the accepted undirected regression suite.
	# UI-only QA injection exercises the existing evaluator's conflict response.
	var pieces := {0: ["begin", 0], 1: ["split", 0], 2: ["corner", 0], 5: ["split", 3], 6: ["join", 2], 9: ["corner", 2], 10: ["join", 2], 14: ["end", 0]}
	for index in range(16):
		model.board[index] = {"kind": pieces[index][0], "rotation": pieces[index][1]} if pieces.has(index) else {}
	scene._refresh()
	_check(not scene.game.forecast.valid and scene.cast_button.disabled and scene.forecast_reason.text.contains("Feedback crosses"), "Closed conflicting graph preserves accepted conflict text and disabled Cast in painted UI.")
	var before: Dictionary = scene.controller.snapshot()
	scene._cast()
	scene._cast()
	_check(_same_gameplay(scene.controller.snapshot(), before), "Repeated Cast on the conflicting graph cannot resolve, spend or reset (rejection log may change).")
	await _full_page_contract(scene, viewport, "conflicting-circuit")
	await _board_view(scene)
	await _save(viewport, "conflict-board-720x1600")
	await _bottom_view(scene)
	await _save(viewport, "conflict-bottom-720x1600")

func _repeated_guard(scene: Control, setup: Dictionary) -> void:
	helper._inject(scene, setup)
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	scene._request_pass()
	scene.inspector_confirm_pass.pressed.emit()
	var pending: Dictionary = scene.controller.snapshot()
	for repeat in range(4):
		scene._pass()
		scene._cast()
		scene._request_pass()
		scene.stock_buttons.straight.pressed.emit()
	_check(scene.controller.is_busy() and scene.cast_button.disabled and scene.turn_pass_button.disabled and scene.controller.snapshot() == pending and delayed.batches.size() == 1, "Rapid repeated production actions remain guarded during pending presentation.")
	delayed.complete()
	delayed.complete()
	_check(not scene.controller.is_busy() and scene.controller.snapshot() == pending, "Repeated presentation completion does not replay outcomes through the integrated UI.")

func _terminal(scene: Control, viewport: SubViewport, setup: Dictionary, suffix: String) -> void:
	var model = helper._inject(scene, setup)
	model.enemy_hp = 1
	scene._refresh()
	var built: bool = helper._build(scene, true)
	_check(built, suffix + " terminal fixture builds positive damage through production controls.")
	if built:
		var hp: int = scene.game.player_hp
		scene._cast()
		await _layout()
		_check(scene.game.state == "victory" and scene.game.player_hp == hp and scene.game.hand.is_empty() and scene.cast_button.disabled and scene.turn_pass_button.disabled, suffix + " lethal Cast preserves cleanup, no retaliation and disabled actions.")
		_arena_contract(scene, suffix + " victory")
		var won: Dictionary = scene.controller.snapshot()
		for repeat in range(3):
			scene._cast()
			scene._pass()
			scene._request_pass()
		_check(scene.controller.snapshot() == won and not scene.inspector.visible, suffix + " repeated victory actions cannot alter outcome or reopen Pass.")
		await _full_page_contract(scene, viewport, "victory")
		scene.page_scroll.scroll_vertical = 0
		await _save(viewport, "victory-top-" + suffix)
		await _bottom_view(scene)
		await _save(viewport, "victory-bottom-" + suffix)
	model = helper._inject(scene, setup)
	model.player_hp = 1
	scene._refresh()
	scene._request_pass()
	scene.inspector_confirm_pass.pressed.emit()
	await _layout()
	_check(scene.game.state == "defeat" and scene.game.hand.is_empty() and scene.cast_button.disabled and scene.turn_pass_button.disabled, suffix + " confirmed lethal Pass reaches defeat and disabled controls.")
	_arena_contract(scene, suffix + " defeat")
	var lost: Dictionary = scene.controller.snapshot()
	for repeat in range(3):
		scene._cast()
		scene._pass()
		scene._request_pass()
	_check(scene.controller.snapshot() == lost and not scene.inspector.visible, suffix + " repeated defeat input cannot mutate or reopen the terminal encounter.")
	await _full_page_contract(scene, viewport, "defeat")
	scene.page_scroll.scroll_vertical = 0
	await _save(viewport, "defeat-top-" + suffix)
	await _bottom_view(scene)
	await _save(viewport, "defeat-bottom-" + suffix)

func _fully_visible(control: Control, viewport: SubViewport) -> bool:
	return control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(viewport.size)).encloses(control.get_global_rect())

func _same_gameplay(first: Dictionary, second: Dictionary) -> bool:
	var lhs := first.duplicate(true)
	var rhs := second.duplicate(true)
	lhs.erase("log_text")
	rhs.erase("log_text")
	return lhs == rhs

func _layout() -> void:
	for frame in range(5):
		await process_frame

func _reveal(scene: Control, control: Control) -> void:
	await _layout()
	if scene.hand_box.is_ancestor_of(control):
		scene.hand_scroll.ensure_control_visible(control)
	scene.page_scroll.ensure_control_visible(control)
	await _layout()

func _board_view(scene: Control) -> void:
	scene.page_scroll.scroll_vertical += int(scene.cells[0].get_global_rect().position.y) - 30
	await _layout()

func _bottom_view(scene: Control) -> void:
	scene.page_scroll.scroll_vertical = 100000
	await _layout()

func _save(viewport: SubViewport, filename: String) -> void:
	await _layout()
	await RenderingServer.frame_post_draw
	var path := destination.path_join(filename + ".png")
	_check(viewport.get_texture().get_image().save_png(path) == OK, "Saved actual runtime view " + filename)
	captures.append(path)
