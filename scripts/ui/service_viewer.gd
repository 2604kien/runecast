extends Control
## Recovery/event presentation. The shell alone stages and durably commits a
## choice; inspecting, canceling and leaving this screen never resolve a room.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")
const NavigationBar = preload("res://scenes/ui/theme/navigation_bar.gd")
const MapChrome = preload("res://scripts/ui/route_map_chrome.gd")
signal choice_requested(identity: Dictionary, choice_id: String)
signal targeted_choice_requested(identity: Dictionary, choice_id: String, target: Variant)
signal map_requested
signal menu_requested
signal sound_requested

var presentation: Dictionary = {}
var choice_buttons: Dictionary = {}
var selection_buttons: Dictionary = {}
var leave_button: Button
var status_label: Label
var resources_label: Label
var scroll: ScrollContainer
var inspection: Control
var panel: PanelContainer
var modal_action: Button
var modal_close: Button
var modal_body: Label
var gestures: Node
var _navigation: NavigationBar
var _body: VBoxContainer
var _header: Label
var _modal_title: Label
var _modal_scroll: ScrollContainer
var _modal_content: VBoxContainer
var _target_content: VBoxContainer
var _catalog: Dictionary = {}
var _selected_target: Variant = null
var _selected_choice := ""
var _blocked := false
var _disposed := false
var _generation := 0

func _ready() -> void:
	name = "ServiceRoom"
	theme = Ui.THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := MapChrome.new()
	backdrop.kind = "backdrop"
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header = Ui.combat_label("RECOVERY", "display", 26)
	_header.autowrap_mode = TextServer.AUTOWRAP_OFF
	_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_header)
	resources_label = Ui.combat_label("", "value", 20)
	resources_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(resources_label)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = false
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 18)
	scroll.add_child(_body)
	status_label = Ui.label("", "body", 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	leave_button = Ui.menu_action("Leave", false, Vector2(0, 68))
	add_child(leave_button)
	leave_button.pressed.connect(func(): select_choice("leave"))
	_navigation = NavigationBar.new()
	add_child(_navigation)
	_navigation.buttons.menu.pressed.connect(func():
		if _can_act(): menu_requested.emit()
	)
	_navigation.buttons.map.pressed.connect(func():
		if _can_act(): map_requested.emit()
	)
	_navigation.buttons.guide.pressed.connect(_show_guide)
	_navigation.buttons.sound.pressed.connect(func():
		if _can_act(): sound_requested.emit()
	)
	_build_inspection()
	gestures = TouchRouter.new()
	gestures.mobile_only = true
	add_child(gestures)
	gestures.register_scroll(scroll)
	gestures.register_scroll(_modal_scroll)
	for button in [leave_button, modal_action, modal_close] + _navigation.buttons.values():
		button.focus_mode = Control.FOCUS_NONE
		gestures.register_target(button, button.pressed.emit)
	resized.connect(_fit)
	get_viewport().size_changed.connect(func(): _fit.call_deferred())
	_fit()

func _build_inspection() -> void:
	inspection = Control.new()
	inspection.name = "ServiceInspection"
	inspection.z_index = 110
	inspection.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(inspection)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	inspection.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = Ui.modal("Confirm choice", "", 280, 430, "Confirm")
	inspection.add_child(panel)
	_modal_title = panel.get_child(0).get_child(0)
	_modal_scroll = panel.get_meta("rc_body_scroll")
	modal_body = _modal_scroll.get_child(0)
	_modal_scroll.remove_child(modal_body)
	_modal_content = VBoxContainer.new()
	_modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_theme_constant_override("separation", 14)
	_modal_scroll.add_child(_modal_content)
	_target_content = VBoxContainer.new()
	_target_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_content.add_theme_constant_override("separation", 14)
	_modal_content.add_child(_target_content)
	_modal_content.add_child(modal_body)
	modal_action = panel.get_meta("rc_confirm")
	modal_close = panel.get_meta("rc_close")
	modal_action.pressed.connect(confirm_choice)
	modal_close.pressed.connect(dismiss_top)
	panel.minimum_size_changed.connect(func(): _fit_modal.call_deferred())
	inspection.hide()

func present(record: Dictionary, catalog: Dictionary = {}) -> void:
	_generation += 1
	presentation = record.duplicate(true)
	_catalog = catalog.duplicate(true)
	if gestures != null: gestures.cancel_pending(true)
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	_header.text = "RECOVERY" if record.get("room_type") == "recovery" else "EVENT"
	resources_label.text = "Health %d / %d  ·  %d Gold" % [record.get("player_hp", 0), record.get("player_max_hp", 0), record.get("gold", 0)]
	if record.get("room_type") != "recovery": _body.add_child(Ui.label(str(record.get("title", "Room")), "title", 28))
	_body.add_child(Ui.label(str(record.get("premise", "")), "body", 20))
	var token := _generation
	for choice in record.get("choices", []):
		var id := str(choice.get("choice_id", ""))
		if id == "leave":
			choice_buttons[id] = leave_button
			Ui.apply_states(leave_button, {"disabled": not bool(choice.get("eligible", false))})
			continue
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 8)
		_body.add_child(column)
		var button := Ui.menu_action(str(choice.get("label", "Choose")), true, Vector2(0, 68))
		button.focus_mode = Control.FOCUS_NONE
		Ui.apply_states(button, {"disabled": not bool(choice.get("eligible", false))})
		button.pressed.connect(func():
			if token == _generation: select_choice(id)
		)
		column.add_child(button)
		choice_buttons[id] = button
		gestures.register_target(button, button.pressed.emit)
		var explanation := str(choice.get("description", ""))
		if not bool(choice.get("eligible", false)):
			explanation += "\n" + str(choice.get("reason", "Unavailable."))
		column.add_child(Ui.label(explanation, "body", 18))
	status_label.text = "Choose once, or Leave without a benefit."
	close_inspection()
	_fit()

func _can_act() -> bool:
	return not _blocked and not _disposed and is_visible_in_tree() and presentation.get("status") == "active" and not inspection.visible

func _choice(choice_id: String) -> Dictionary:
	for choice in presentation.get("choices", []):
		if choice.get("choice_id") == choice_id: return choice
	return {}

func select_choice(choice_id: String) -> void:
	if not _can_act(): return
	var choice := _choice(choice_id)
	if choice.is_empty() or not choice.get("eligible", false): return
	_selected_choice = choice_id
	_selected_target = null
	_clear_targets()
	if choice.get("effect") == "upgrade":
		_show_upgrade_targets(choice)
		return
	if choice.get("effect") == "relic":
		_show_relic_targets(choice)
		return
	_modal_title.text = str(choice.get("label", "Confirm choice"))
	var lines: Array[String] = [str(choice.get("description", ""))]
	var hp := int(presentation.get("player_hp", 0))
	var maximum := int(presentation.get("player_max_hp", 0))
	var gold := int(presentation.get("gold", 0))
	lines.append("Health %d to %d / %d\nGold %d to %d" % [hp, hp + int(choice.get("hp_delta", 0)), maximum, gold, gold + int(choice.get("gold_delta", 0))])
	lines.append("This completes the room." if choice_id == "leave" else "This completes the room. No other choice can be taken.")
	modal_body.text = "\n\n".join(lines)
	modal_action.text = "Leave" if choice_id == "leave" else "Confirm"
	modal_action.show()
	modal_close.text = "Cancel"
	_open_inspection()

func confirm_choice() -> void:
	if _blocked or _disposed or not is_visible_in_tree() or not inspection.visible or _selected_choice.is_empty(): return
	var choice := _choice(_selected_choice)
	if choice.is_empty() or not choice.get("eligible", false) or presentation.get("status") != "active": return
	if choice.get("effect") in ["upgrade", "relic"]:
		if _selected_target != null: targeted_choice_requested.emit(presentation.get("identity", {}).duplicate(true), _selected_choice, _selected_target)
		return
	choice_requested.emit(presentation.get("identity", {}).duplicate(true), _selected_choice)

func _show_upgrade_targets(choice: Dictionary) -> void:
	_modal_title.text = "Choose a rune to upgrade"
	modal_body.text = "Choose one exact copy. Cancel keeps this room open."
	for owned in choice.get("targets", []):
		var uid := int(owned.get("uid", -1))
		var card := Ui.card(CollectionData.instance_card(_catalog, owned), {}, 190)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_NONE
		card.tooltip_text = ""
		card.pressed.connect(select_upgrade.bind(uid))
		_target_content.add_child(card)
		_target_content.add_child(Ui.label("Copy %d · unupgraded" % uid, "muted", 16))
		selection_buttons[uid] = card
		gestures.register_target(card, card.pressed.emit)
	modal_action.hide()
	modal_close.text = "Cancel"
	_open_inspection()

func select_upgrade(uid: int) -> void:
	if _blocked or _disposed or not inspection.visible or _selected_choice.is_empty() or _selected_target != null: return
	var selected: Dictionary = {}
	for owned in _choice(_selected_choice).get("targets", []):
		if int(owned.get("uid", -1)) == uid: selected = owned
	if selected.is_empty(): return
	_selected_target = uid
	_clear_targets()
	_modal_title.text = "Upgrade this rune?"
	var card := Ui.card(CollectionData.instance_card(_catalog, selected), {}, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.focus_mode = Control.FOCUS_NONE
	_target_content.add_child(card)
	modal_body.text = "Copy %d\n\n%s\n\nFree. This completes the room; no other choice can be taken." % [uid, CollectionData.upgrade_text(_catalog, selected)]
	modal_action.text = "Upgrade"
	modal_action.show()
	_open_inspection()

func _show_relic_targets(choice: Dictionary) -> void:
	_modal_title.text = "Choose a relic"
	modal_body.text = "Acquire one relic for %d Gold. Cancel keeps this room open." % absi(int(choice.get("gold_delta", -15)))
	for entry in choice.get("offered_relics", presentation.get("offered_relics", [])):
		var id := str(entry.get("definition_id", "")) if entry is Dictionary else str(entry)
		var relic: Dictionary = RelicPolicy.definitions().get(id, {})
		if relic.is_empty(): continue
		var button := Ui.menu_action(str(relic.name), true, Vector2(0, 68))
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_relic.bind(id))
		_target_content.add_child(button)
		_target_content.add_child(Ui.label(str(relic.description), "body", 16))
		selection_buttons[id] = button
		gestures.register_target(button, button.pressed.emit)
	modal_action.hide()
	modal_close.text = "Cancel"
	_open_inspection()

func select_relic(id: String) -> void:
	if _blocked or _disposed or not inspection.visible or _selected_choice.is_empty() or _selected_target != null or not selection_buttons.has(id): return
	var relic: Dictionary = RelicPolicy.definitions().get(id, {})
	if relic.is_empty(): return
	_selected_target = id
	_clear_targets()
	_modal_title.text = str(relic.name)
	var price := absi(int(_choice(_selected_choice).get("gold_delta", -15)))
	modal_body.text = "%s\n\n%d Gold · unique passive relic for this run.\n\nThis completes the room; no other choice can be taken." % [str(relic.description), price]
	modal_action.text = "Acquire · %d Gold" % price
	modal_action.show()
	_open_inspection()

func _clear_targets() -> void:
	selection_buttons.clear()
	for child in _target_content.get_children():
		_target_content.remove_child(child)
		child.queue_free()

func _show_guide() -> void:
	if not _can_act(): return
	_selected_choice = ""
	_selected_target = null
	_clear_targets()
	_modal_title.text = str(presentation.get("title", "Room"))
	modal_body.text = "Review a choice and confirm to complete this room. Leave completes it without a benefit.\n\nMap, Menu and Home keep this visit open. Continue returns to the same room. Cancel and Back never choose for you."
	modal_action.hide()
	modal_close.text = "Back to room"
	_open_inspection()

func _open_inspection() -> void:
	gestures.cancel_pending(true)
	_modal_scroll.scroll_vertical = 0
	Ui.prepare_popup_content(panel)
	inspection.show()
	gestures.set_modal(inspection)
	_fit_modal()

func report_error(message: String) -> void:
	status_label.text = message
	if inspection.visible:
		modal_body.text = message + "\n\n" + str(_choice(_selected_choice).get("description", ""))
		_fit_modal()

func dismiss_top() -> void:
	if _blocked or _disposed: return
	if inspection.visible: close_inspection()
	else: menu_requested.emit()

func close_inspection() -> void:
	inspection.hide()
	_selected_choice = ""
	_selected_target = null
	_clear_targets()
	if gestures != null:
		gestures.cancel_pending(true)
		gestures.set_modal(null)

func set_blocked(value: bool) -> void:
	_blocked = value
	if gestures == null: return
	gestures.cancel_pending(true)
	gestures.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	if not value: gestures.set_modal(inspection if inspection.visible else null)

func set_sound_enabled(value: bool) -> void:
	_navigation.set_sound_enabled(value)

func _fit() -> void:
	if _navigation == null: return
	var canvas_scale := get_viewport().get_final_transform().get_scale().abs()
	if canvas_scale.x <= 0: return
	var rendered := size * canvas_scale
	var fit_scale := minf(1, minf(rendered.x / 360.0, rendered.y / 640.0))
	var content_scale := fit_scale / canvas_scale.x
	var width := size.x / content_scale
	var margin := 20.0
	for control in [_header, resources_label, scroll, status_label, leave_button]: control.scale = Vector2.ONE * content_scale
	_header.position = Vector2(margin, 16) * content_scale
	_header.size = Vector2(width - margin * 2, 42)
	resources_label.position = Vector2(margin, 62) * content_scale
	resources_label.size = Vector2(width - margin * 2, 36)
	_navigation.fit_viewport(size.x)
	_navigation.position = Vector2((size.x - _navigation.custom_minimum_size.x) / 2, size.y - _navigation.custom_minimum_size.y - 8)
	_navigation.size = _navigation.custom_minimum_size
	leave_button.position = Vector2(margin * content_scale, _navigation.position.y - 84 * content_scale)
	leave_button.size = Vector2(width - margin * 2, 68)
	status_label.position = Vector2(margin * content_scale, leave_button.position.y - 60 * content_scale)
	status_label.size = Vector2(width - margin * 2, 54)
	scroll.position = Vector2(margin, 118) * content_scale
	scroll.size = Vector2(width - margin * 2, maxf(80, status_label.position.y / content_scale - 130))
	_fit_modal()

func _fit_modal() -> void:
	if _disposed or panel == null: return
	Ui.fit_popup_overlay(inspection, panel, Vector2(560, 430), Vector2(280, 340))

func prepare_for_exit() -> void:
	_disposed = true
	set_blocked(true)
