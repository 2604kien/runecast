extends Control
## Read-only Map presentation. The owning shell validates and commits entry.
const Ui = preload("res://scenes/ui/theme/components.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")
const MapCanvas = preload("res://scripts/ui/route_map_canvas.gd")
const MapNode = preload("res://scripts/ui/route_map_node.gd")
const MapChrome = preload("res://scripts/ui/route_map_chrome.gd")
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const NavigationBar = preload("res://scenes/ui/theme/navigation_bar.gd")
const PARCHMENT = preload("res://assets/ui/map/parchment.png")
const INK := Color("182b38")

signal close_requested
signal resume_requested
signal entry_requested(node_id: String)
signal menu_requested
signal sound_requested
signal details_requested

var scroll: ScrollContainer
var inspection: Control
var inspection_panel: PanelContainer
var inspection_body: Label
var inspection_action: Button
var inspection_close: Button
var close_button: Button
var resume_button: Button
var help_button: Button
var menu_button: Button
var sound_button: Button
var details_button: Button
var node_buttons: Dictionary = {}
var gestures: Node
var canvas: Control
var header_stats: Label
var status_label: Label
var _snapshot: Dictionary = {}
var _node_data: Dictionary = {}
var _node_groups: Dictionary = {}
var _header: Control
var _navigation: NavigationBar
var _logo: TextureRect
var _close_icon: Label
var _paper: TextureRect
var _stats: Control
var _stat_values: Array[Label] = []
var _stat_icons: Array[Control] = []
var _surfaces: Array[Control] = []
var _flourish: Control
var _sound_enabled := true
var _title: Label
var _subtitle: Label
var _inspection_title: Label
var _inspected_id := ""
var _blocked := false
var _disposed := false
var _identity := ""
var _initial_position := true

func _ready() -> void:
	name = "RouteMap"
	theme = Ui.THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	var backdrop := MapChrome.new()
	backdrop.kind = "backdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_logo = TextureRect.new()
	var logo_art := AtlasTexture.new()
	logo_art.atlas = CombatSurface.ATLAS
	logo_art.region = Rect2(56, 1, 245, 46)
	logo_art.filter_clip = true
	_logo.texture = logo_art
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.set_meta("accessible_title", "Rune Cast")
	_header.add_child(_logo)
	close_button = _bare_button("Close Map")
	close_button.name = "TopClose"
	_header.add_child(close_button)
	_surface(close_button, "pause")
	var cross := Ui.combat_label("×", "label", 38)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_button.add_child(cross)
	_close_icon = cross
	cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_button.pressed.connect(_close)
	_stats = Control.new()
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stats)
	var stats_surface := _surface(_stats, "stats", 3)
	stats_surface.show_dividers = true
	for kind in ["health", "gold", "depth"]:
		var icon: Control
		if kind == "health":
			icon = Ui.combat_icon("health", Vector2.ZERO)
		else:
			icon = MapChrome.new()
			icon.kind = kind
		_stats.add_child(icon)
		_stat_icons.append(icon)
		var value := Ui.combat_label("", "value", 36)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_stats.add_child(value)
		_stat_values.append(value)
	# A semantic aggregate remains available to existing inspection/accessibility
	# consumers; the visible three fields are independently laid out.
	header_stats = Ui.label("", "value", 20)
	add_child(header_stats)
	header_stats.hide()
	# The existing run header is the secondary route to run details. Its hit
	# target leaves the approved painted stats composition unchanged.
	details_button = _bare_button("Run details")
	details_button.tooltip_text = "Run details"
	_stats.add_child(details_button)
	details_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	details_button.pressed.connect(_details)
	_paper = TextureRect.new()
	_paper.texture = PARCHMENT
	_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	_title = Ui.combat_label("TOWER MAP", "display", 48)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", INK)
	_title.add_theme_constant_override("outline_size", 0)
	add_child(_title)
	_flourish = MapChrome.new()
	_flourish.kind = "subtitle"
	add_child(_flourish)
	_subtitle = Ui.combat_label("Ashen Crypt", "body", 28)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", INK)
	_subtitle.add_theme_constant_override("outline_size", 0)
	add_child(_subtitle)
	scroll = ScrollContainer.new()
	scroll.name = "RouteScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	canvas = MapCanvas.new()
	canvas.name = "LiveParchment"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)
	status_label = Ui.combat_label("Choose your next encounter", "body", 26)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(status_label)
	_navigation = NavigationBar.new()
	add_child(_navigation)
	_navigation.set_selected("map")
	menu_button = _navigation.buttons.menu
	help_button = _navigation.buttons.guide
	sound_button = _navigation.buttons.sound
	menu_button.pressed.connect(_menu)
	help_button.pressed.connect(_show_help)
	sound_button.pressed.connect(_sound)
	# Resume is intentionally reached through the current node's inspection.
	# Keep the action object for existing callers, outside the painted footer.
	resume_button = Ui.action("Resume room", true, Vector2(0, 64))
	add_child(resume_button)
	resume_button.hide()
	resume_button.pressed.connect(_resume)
	_build_inspection()
	gestures = TouchRouter.new()
	gestures.mobile_only = true
	add_child(gestures)
	for button in [close_button, details_button, menu_button, _navigation.buttons.map, resume_button, help_button, sound_button, inspection_action, inspection_close]:
		button.focus_mode = Control.FOCUS_NONE
		gestures.register_target(button, button.pressed.emit)
	gestures.register_scroll(scroll)
	gestures.register_scroll(inspection_panel.get_meta("rc_body_scroll"))
	resized.connect(_fit)
	visibility_changed.connect(_visibility_changed)
	set_snapshot(_snapshot)
	_fit()

func _bare_button(semantic_text: String) -> Button:
	var button := Button.new()
	button.text = semantic_text
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
		button.add_theme_color_override(colour, Color.TRANSPARENT)
	return button

func _surface(parent: Control, kind: String, divisions: int = 0) -> Control:
	var surface := CombatSurface.new()
	surface.kind = kind
	surface.divisions = divisions
	surface.show_behind_parent = true
	parent.add_child(surface, false, Node.INTERNAL_MODE_BACK)
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	# Container decorations need an explicit deferred fit after their sort;
	# anchors alone are reset by the HBox's minimum-size/layout pass.
	var fit := func():
		if not is_instance_valid(parent) or not is_instance_valid(surface): return
		if parent.is_queued_for_deletion() or surface.is_queued_for_deletion(): return
		surface.position = Vector2.ZERO
		surface.size = parent.size
	parent.resized.connect(fit)
	if parent is Container: parent.sort_children.connect(func(): fit.call_deferred())
	fit.call_deferred()
	parent.set_meta("combat_surface", surface)
	_surfaces.append(surface)
	return surface

func set_sound_enabled(value: bool) -> void:
	_sound_enabled = value
	if not is_node_ready() or _navigation == null: return
	_navigation.set_sound_enabled(value)

func _menu() -> void:
	if _blocked or _disposed: return
	gestures.cancel_pending(true)
	menu_requested.emit()

func _details() -> void:
	if _blocked or _disposed or inspection.visible: return
	gestures.cancel_pending(true)
	details_requested.emit()

func _sound() -> void:
	if _blocked or _disposed: return
	gestures.cancel_pending()
	sound_requested.emit()

func _build_inspection() -> void:
	inspection = Control.new()
	inspection.name = "NodeInspection"
	inspection.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(inspection)
	inspection.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.88)
	inspection.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspection_panel = Ui.modal("Room", "", 280, 320, "Enter")
	inspection.add_child(inspection_panel)
	_inspection_title = inspection_panel.get_child(0).get_child(0)
	inspection_body = inspection_panel.get_meta("rc_body_scroll").get_child(0)
	inspection_action = inspection_panel.get_meta("rc_confirm")
	inspection_close = inspection_panel.get_meta("rc_close")
	inspection_close.text = "Back to Map"
	inspection_action.pressed.connect(_inspection_activate)
	inspection_close.pressed.connect(close_inspection)
	inspection_panel.minimum_size_changed.connect(func(): _fit_inspection.call_deferred())
	get_viewport().size_changed.connect(func(): _fit_inspection.call_deferred())
	Ui.prepare_popup_content(inspection_panel)
	inspection.hide()

func set_snapshot(value: Dictionary) -> void:
	_snapshot = value.duplicate(true)
	if not is_node_ready(): return
	var identity := str(value.get("run_id", "")) + ":" + str(value.get("route", {}).get("route_id", "standalone"))
	if _identity != identity:
		_identity = identity
		_initial_position = true
		close_inspection()
	gestures.cancel_pending()
	_rebuild_nodes()
	var route: Dictionary = _snapshot.get("route", {})
	var depth := int(route.get("visit_count", 0))
	_stat_values[0].text = "%d/%d" % [value.get("player_hp", 30), value.get("player_max_hp", 30)]
	_stat_values[1].text = "%d" % value.get("gold", 0)
	_stat_values[2].text = "Depth %d" % depth if not route.is_empty() else "—"
	if route.is_empty():
		header_stats.text = "Health %d / %d   ·   Gold %d" % [value.get("player_hp", 30), value.get("player_max_hp", 30), value.get("gold", 0)]
		_subtitle.text = "Standalone encounter"
		status_label.text = "Inspect your current encounter to resume"
	else:
		header_stats.text = "Health %d / %d   ·   Gold %d   ·   Depth %d / %d" % [value.get("player_hp", 30), value.get("player_max_hp", 30), value.get("gold", 0), depth, route.get("path_length", 9)]
		_subtitle.text = str(route.get("display_name", "Ashen Crypt"))
		match str(value.get("status", "")):
			"battle": status_label.text = "Inspect your current encounter to resume"
			"room_active": status_label.text = "Inspect your current room to resume"
			"replay_pending": status_label.text = "Resume the current room from its exact entry"
			"result_pending": status_label.text = "Review the current encounter result"
			"pending_choices": status_label.text = "Required room choices are pending · route locked"
			"defeated": status_label.text = "Run ended in defeat"
			"tower_completed": status_label.text = "Tower complete"
			_: status_label.text = "Choose your next encounter"
	resume_button.hide()
	set_sound_enabled(_sound_enabled)
	if not _inspected_id.is_empty() and _node_data.has(_inspected_id) and inspection.visible:
		_populate_inspection(_inspected_id)
	_fit.call_deferred()
	_position_initial.call_deferred()

func _rebuild_nodes() -> void:
	for child in canvas.get_children():
		canvas.remove_child(child)
		child.queue_free()
	node_buttons.clear()
	_node_groups.clear()
	_node_data.clear()
	var route: Dictionary = _snapshot.get("route", {})
	var nodes: Array = route.get("nodes", [])
	if route.is_empty():
		nodes = [{"id": _snapshot.get("current_node_id", "fixture_shadeling"), "depth": 1,
			"room_type": "normal", "encounter_role": _snapshot.get("current_encounter_role", "boss"),
			"encounter_id": _snapshot.get("current_encounter_id", "training_shadeling"),
			"display_name": _snapshot.get("current_enemy_name", "Shadeling"), "state": "current",
			"reason": _snapshot.get("current_encounter_help", "This is a standalone encounter, separate from the tower route.")}]
	for data in nodes:
		var id := str(data.id)
		_node_data[id] = data.duplicate(true)
		var group := Control.new()
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(group)
		_node_groups[id] = group
		var state := str(data.get("state", "locked"))
		var button := Ui.map_node("completed" if state == "visited" else state, "", 72)
		button.name = id.validate_node_name()
		# Locked nodes are inspectable. Their ring/lock remains unavailable;
		# eligibility is explained by the model and is never a widget decision.
		Ui.apply_states(button, {})
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = ""
		button.pressed.connect(inspect_node.bind(id))
		group.add_child(button)
		node_buttons[id] = button
		# Retain the shared map-node hit target/state contract, replacing only
		# its temporary decoration with live reference-shaped rings and glyphs.
		for child in button.get_children():
			if child is CanvasItem: child.hide()
		for style in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		var art := MapNode.new()
		art.state = state
		art.family = str(data.get("room_type", "normal"))
		art.role = str(data.get("encounter_role", ""))
		art.subdued = state == "locked" and int(data.get("depth", 0)) <= int(route.get("visit_count", 0))
		_node_data[id]["subdued"] = art.subdued
		button.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var caption := Ui.combat_label("", "display", 20)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", INK)
		caption.add_theme_constant_override("outline_size", 0)
		caption.name = "Caption"
		group.add_child(caption)
		if art.role == "guardian" and state != "current":
			caption.text = "Crypt Guardian"
		elif art.role == "boss" and state != "current":
			caption.text = "Shadeling · Boss"
		else:
			caption.hide()
		gestures.register_target(button, button.pressed.emit)
	canvas.edges = route.get("edges", []).duplicate(true)
	canvas.nodes = _node_data.duplicate(true)

func _node_title(data: Dictionary) -> String:
	var role := str(data.get("encounter_role", ""))
	var title := str(data.get("display_name", data.get("title", "Room")))
	if role == "boss": return title + "\nBoss"
	if role == "guardian": return title + "\nGuardian"
	if role == "elite": return title + "\nElite"
	return title

func inspect_node(node_id: String) -> void:
	if _blocked or _disposed or not is_visible_in_tree() or not _node_data.has(node_id): return
	_inspected_id = node_id
	_populate_inspection(node_id)
	# An inspection opens at its identity/type information, even when the shared
	# sheet was previously scrolled for this or another room.
	inspection_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	inspection.show()
	gestures.set_modal(inspection)
	_fit_inspection.call_deferred()

func _populate_inspection(node_id: String) -> void:
	var node: Dictionary = _node_data[node_id]
	_inspection_title.text = str(node.get("display_name", node.get("title", "Room")))
	var role := str(node.get("encounter_role", ""))
	var family := str(node.get("room_type", "")).capitalize()
	var state := str(node.get("state", "locked"))
	var lines: Array[String] = []
	if not role.is_empty():
		lines.append("Encounter: " + role.capitalize())
		if role == "boss": lines.append("Designated Shadeling boss · separate from the final guardian.")
	else:
		lines.append("Room: " + family)
	if _snapshot.get("route", {}).is_empty():
		lines.append("Standalone encounter. No earlier tower rooms have been completed.")
	else:
		lines.append("Room %d of %d · %s" % [node.get("depth", 0), _snapshot.route.get("path_length", 9), "Boss" if role == "boss" else family])
	var encounter := str(node.get("encounter_id", ""))
	if not encounter.is_empty(): lines.append("Known encounter: " + encounter)
	if not str(node.get("board_id", "")).is_empty(): lines.append("Board: " + str(node.board_id))
	lines.append("")
	match state:
		"current":
			lines.append("Current room. Return to its unresolved encounter or choices.")
			if _snapshot.get("status") == "pending_choices":
				lines.append("Review the pending rewards for this visit. Successors stay locked until every required choice is resolved.")
		"available":
			lines.append("Connected next choice. Inspecting does not enter this room.")
		"visited":
			lines.append("Completed room. This visit cannot be replayed or claimed again.")
		_:
			lines.append(str(node.get("reason", "Complete the connected preceding room before entry.")))
	if state == "current" and not str(node.get("reason", "")).is_empty(): lines.append(str(node.reason))
	if node.get("content_pending", false):
		lines.append("")
		lines.append("This room is not playable yet. Your route choice will remain available.")
	inspection_body.text = "\n".join(lines)
	inspection_action.visible = state == "available" or (state == "current" and bool(_snapshot.get("can_resume_room", false)))
	inspection_action.text = ("Review result" if _snapshot.get("status") == "result_pending" else "Review rewards" if _snapshot.get("status") == "pending_choices" else "Replay entry" if _snapshot.get("status") == "replay_pending" else "Resume room") if state == "current" else "Enter"
	Ui.apply_states(inspection_action, {})

func _inspection_activate() -> void:
	if _blocked or not inspection.visible or not _node_data.has(_inspected_id): return
	var node: Dictionary = _node_data[_inspected_id]
	if node.get("state") == "current" and bool(_snapshot.get("can_resume_room", false)):
		_resume()
	elif node.get("state") == "available":
		gestures.cancel_pending()
		entry_requested.emit(_inspected_id)

func report_entry_error(message: String) -> void:
	if _disposed: return
	if inspection.visible:
		# Repeated failed confirmations display the latest report once, rather
		# than accumulating an ever-growing history in the inspection sheet.
		if _node_data.has(_inspected_id): _populate_inspection(_inspected_id)
		inspection_body.text = message + "\n\n" + inspection_body.text
		inspection_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	else:
		status_label.text = message

func close_inspection() -> void:
	if inspection == null or _blocked: return
	inspection.hide()
	_inspected_id = ""
	if gestures != null: gestures.set_modal(null)

func dismiss_top() -> void:
	if _blocked: return
	if inspection != null and inspection.visible:
		close_inspection()
	else:
		_close()

func set_blocked(value: bool) -> void:
	_blocked = value
	if gestures == null: return
	gestures.cancel_pending(true)
	# A shell confirmation has its own router. Disabling this router leaves that
	# owner in charge, unlike suspension which would consume its pointer input.
	gestures.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	if not value: gestures.set_modal(inspection if inspection.visible else null)

func _show_help() -> void:
	if _blocked: return
	_inspected_id = ""
	_inspection_title.text = "Choose your route"
	inspection_body.text = "Ascend from the bottom of the Map toward the guardian. Tap a room to inspect it.\n\nGold rings mark connected next choices. Enter opens a confirmation; selecting a node alone never commits it.\n\nThe turquoise star and YOU ARE HERE ribbon mark your active room. Green checks mark completed visits. Muted nodes and dashed paths are unavailable; inspect them to learn why.\n\nCrossed swords mark combat, a question mark an event, a skull an elite, a pouch a shop and a flame recovery. Shadeling is a separate boss before the spiked guardian endpoint.\n\nTap the health / Gold / depth header for run details and the separate Abandon Run action. Pending results and reward choices must be reviewed first.\n\nEvery path visits nine rooms. The route is saved between sessions. Production room content is still being built."
	if _snapshot.get("route", {}).is_empty():
		inspection_body.text = "This is a standalone encounter, separate from the tower route.\n\nInspect the current room or choose Resume room to return to the same battle. Map navigation keeps your prepared cards and current turn intact.\n\nNo tower visits or rewards are created by opening this screen."
	inspection_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	inspection_action.hide()
	inspection.show()
	gestures.set_modal(inspection)
	_fit_inspection.call_deferred()

func _close() -> void:
	if _blocked or _disposed: return
	gestures.cancel_pending(true)
	close_requested.emit()

func _resume() -> void:
	if _blocked or _disposed or not bool(_snapshot.get("can_resume_room", false)): return
	gestures.cancel_pending(true)
	resume_requested.emit()

func _fit() -> void:
	if _navigation == null: return
	var k := size.x / 841.0
	var margin := maxf(10, 28 * k)
	var header_height := maxf(44, 62 * k)
	var stats_height := maxf(44, 90 * k)
	_header.position = Vector2(margin, 0)
	_header.size = Vector2(size.x - margin * 2, header_height)
	_logo.position = Vector2(22 * k, 0)
	_logo.size = Vector2(290 * k, header_height - 3 * k)
	close_button.position = Vector2(_header.size.x - maxf(50, 80 * k), 0)
	close_button.size = Vector2(maxf(50, 80 * k), header_height)
	_close_icon.add_theme_font_size_override("font_size", maxi(27, int(43 * k)))
	_stats.position = Vector2(margin, header_height)
	_stats.size = Vector2(size.x - margin * 2, stats_height)
	for i in 3:
		var cell_width := _stats.size.x / 3.0
		var icon_extent := maxf(22, 49 * k)
		_stat_icons[i].position = Vector2(cell_width * i + 28 * k, (stats_height - icon_extent) / 2)
		_stat_icons[i].size = Vector2(icon_extent, icon_extent)
		_stat_values[i].position = Vector2(cell_width * i + 85 * k, 0)
		_stat_values[i].size = Vector2(cell_width - 92 * k, stats_height)
		_stat_values[i].add_theme_font_size_override("font_size", maxi(16, int(37 * k)))
	_navigation.fit_viewport(size.x)
	var nav_extent := _navigation.custom_minimum_size
	var bottom_inset := 8.0 if size.x < 500 else 4.0 if size.x >= 640 else 20.0
	var nav_top := size.y - bottom_inset - nav_extent.y
	_navigation.position = Vector2(floorf((size.x - nav_extent.x) / 2), nav_top)
	_navigation.size = nav_extent
	var paper_top := header_height + stats_height + 8 * k
	var paper_bottom := nav_top - maxf(40, 88 * k)
	_paper.position = Vector2(margin - 10 * k, paper_top)
	_paper.size = Vector2(size.x - (margin - 10 * k) * 2, maxf(160, paper_bottom - paper_top))
	_title.position = Vector2(margin, paper_top + 16 * k)
	_title.size = Vector2(size.x - margin * 2, maxf(32, 64 * k))
	_title.add_theme_font_size_override("font_size", maxi(24, int(49 * k)))
	_subtitle.position = Vector2(margin, paper_top + maxf(39, 78 * k))
	_subtitle.size = Vector2(size.x - margin * 2, maxf(22, 38 * k))
	_subtitle.add_theme_font_size_override("font_size", maxi(15, int(29 * k)))
	_flourish.position = Vector2(size.x * 0.22, _subtitle.position.y)
	_flourish.size = Vector2(size.x * 0.56, _subtitle.size.y)
	_flourish.visible = not _snapshot.get("route", {}).is_empty()
	scroll.position = Vector2(margin + 28 * k, _subtitle.position.y + _subtitle.size.y + 10 * k)
	scroll.size = Vector2(size.x - 2 * (margin + 28 * k), maxf(90, paper_bottom - scroll.position.y - 28 * k))
	status_label.position = Vector2(margin, paper_bottom + 3 * k)
	status_label.size = Vector2(size.x - margin * 2, maxf(34, nav_top - paper_bottom - 6 * k))
	status_label.add_theme_font_size_override("font_size", maxi(13, int(27 * k)))
	for surface in _surfaces: surface.art_scale = k
	var route: Dictionary = _snapshot.get("route", {})
	var total_depth := int(route.get("path_length", 1))
	# Keep all nine levels visible at tall reference proportions. Short portrait
	# screens retain real touch targets and scroll within the fixed paper frame.
	var top_pad := maxf(48, 76 * k)
	for data in _node_data.values():
		if data.get("encounter_role") == "guardian" and data.get("state") == "current":
			top_pad = maxf(top_pad, maxf(65, 132 * k) * 0.82 + 4)
	var bottom_pad := maxf(55, 110 * k)
	var row_height := maxf(72, (scroll.size.y - top_pad - bottom_pad) / maxi(1, total_depth - 1))
	var canvas_height := maxf(scroll.size.y, top_pad + bottom_pad + (total_depth - 1) * row_height)
	canvas.custom_minimum_size = Vector2(0, canvas_height)
	var width := scroll.size.x - (12 if canvas_height > scroll.size.y + 1 else 0)
	var points: Dictionary = {}
	var radii: Dictionary = {}
	for id in _node_data:
		var data: Dictionary = _node_data[id]
		var peers: Array = []
		for candidate in _node_data.values():
			if candidate.get("depth", 1) == data.get("depth", 1): peers.append(candidate)
		peers.sort_custom(func(a, b): return a.get("lane", 0) < b.get("lane", 0))
		var index := 0
		for i in peers.size():
			if peers[i].id == id: index = i
		var x := width * ((float(index) + 0.5) / float(peers.size()))
		var y := top_pad + (total_depth - int(data.get("depth", 1))) * row_height
		if total_depth == 1: y = canvas_height * 0.48
		var role := str(data.get("encounter_role", ""))
		var extent := maxf(44, 86 * k)
		if role == "guardian": extent = maxf(65, 132 * k)
		elif data.get("state") == "current": extent = maxf(48, 96 * k)
		var group: Control = _node_groups[id]
		var group_width := minf(250 * k, (width - 12) / maxi(peers.size(), 1))
		group.position = Vector2(x - group_width / 2, y - extent / 2)
		group.size = Vector2(group_width, extent)
		var button: Button = node_buttons[id]
		button.custom_minimum_size = Vector2(extent, extent)
		button.size = Vector2(extent, extent)
		button.position = Vector2((group_width - extent) / 2, 0)
		var caption: Label = group.get_node("Caption")
		caption.position = Vector2(0, extent - 1)
		caption.size = Vector2(group_width, maxf(19, 29 * k))
		caption.add_theme_font_size_override("font_size", maxi(12, int(23 * k)))
		points[id] = group.position + button.position + button.size / 2
		radii[id] = extent * 0.415
	canvas.points = points
	canvas.radii = radii
	canvas.queue_redraw()
	_fit_inspection()

func _fit_inspection() -> void:
	if _disposed or inspection_panel == null: return
	Ui.fit_popup_overlay(inspection, inspection_panel, Vector2(560, 570), Vector2(280, 320))

func _position_initial() -> void:
	if _disposed or not _initial_position or scroll == null: return
	# Scrollbar ranges become authoritative only after container layout. Setting
	# the offset in _ready would clamp it to zero and hide the opening choices.
	await get_tree().process_frame
	if _disposed: return
	await get_tree().process_frame
	if _disposed or not _initial_position: return
	_initial_position = false
	scroll.scroll_vertical = int(canvas.custom_minimum_size.y)
	var current_id := str(_snapshot.get("route", {}).get("current_node_id", ""))
	if node_buttons.has(current_id):
		scroll.scroll_vertical = maxi(0, int(_node_groups[current_id].position.y - scroll.size.y * 0.55))

func _visibility_changed() -> void:
	if gestures == null: return
	gestures.cancel_pending(true)
	gestures.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() and not _blocked else Node.PROCESS_MODE_DISABLED

func _exit_tree() -> void:
	_disposed = true
	if gestures != null: gestures.cancel_pending(true)
