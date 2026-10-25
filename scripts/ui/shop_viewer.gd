extends Control
## Detached shop presentation. Only the shell's durable transaction owner may
## spend Gold, grant/remove instances, or finish this visit.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")
const NavigationBar = preload("res://scenes/ui/theme/navigation_bar.gd")
const MapChrome = preload("res://scripts/ui/route_map_chrome.gd")
signal purchase_requested(identity: Dictionary, slot_id: String)
signal remove_requested(identity: Dictionary, uid: int)
signal upgrade_requested(identity: Dictionary, uid: int)
signal relic_purchase_requested(identity: Dictionary, slot_id: String)
signal leave_requested(identity: Dictionary)
signal map_requested
signal menu_requested
signal sound_requested

var presentation: Dictionary = {}
var card_buttons: Dictionary = {}
var buy_buttons: Dictionary = {}
var selection_buttons: Dictionary = {}
var remove_button: Button
var upgrade_button: Button
var leave_button: Button
var balance: Label
var status_label: Label
var scroll: ScrollContainer
var inspection: Control
var panel: PanelContainer
var modal_action: Button
var modal_close: Button
var gestures: Node
var _navigation: NavigationBar
var _body: VBoxContainer
var _grid: GridContainer
var _modal_body: VBoxContainer
var _modal_title: Label
var _modal_scroll: ScrollContainer
var _selection_grid: GridContainer
var _header: Control
var _title: Label
var _gold_icon: Control
var _catalog: Dictionary = {}
var _mode := ""
var _selected_slot := ""
var _selected_uid := -1
var _blocked := false
var _disposed := false
var _generation := 0

func _ready() -> void:
	name = "Shop"
	theme = Ui.THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := MapChrome.new()
	backdrop.kind = "backdrop"
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_title = Ui.combat_label("RUNE SHOP", "display", 26)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_child(_title)
	_gold_icon = MapChrome.new()
	_gold_icon.kind = "gold"
	_header.add_child(_gold_icon)
	balance = Ui.combat_label("0", "value", 22)
	balance.autowrap_mode = TextServer.AUTOWRAP_OFF
	balance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header.add_child(balance)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = false
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 20)
	scroll.add_child(_body)
	status_label = Ui.label("", "body", 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	leave_button = Ui.menu_action("Leave shop", true, Vector2(0, 68))
	add_child(leave_button)
	leave_button.pressed.connect(func():
		if _can_act(): leave_requested.emit(presentation.get("identity", {}).duplicate(true))
	)
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
	inspection.name = "ShopInspection"
	inspection.z_index = 110
	inspection.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(inspection)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	inspection.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = Ui.modal("Rune", "", 280, 430, "Buy")
	inspection.add_child(panel)
	_modal_title = panel.get_child(0).get_child(0)
	_modal_scroll = panel.get_meta("rc_body_scroll")
	var placeholder := _modal_scroll.get_child(0)
	_modal_scroll.remove_child(placeholder)
	placeholder.queue_free()
	_modal_body = VBoxContainer.new()
	_modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_body.add_theme_constant_override("separation", 14)
	_modal_scroll.add_child(_modal_body)
	modal_action = panel.get_meta("rc_confirm")
	modal_close = panel.get_meta("rc_close")
	modal_action.pressed.connect(_modal_activate)
	modal_close.pressed.connect(dismiss_top)
	panel.minimum_size_changed.connect(func(): _fit_modal.call_deferred())
	inspection.hide()

func present(record: Dictionary, catalog: Dictionary, _run_snapshot: Dictionary = {}) -> void:
	_generation += 1
	presentation = record.duplicate(true)
	_catalog = catalog.duplicate(true)
	if gestures != null: gestures.cancel_pending(true)
	_clear(_body)
	card_buttons.clear()
	buy_buttons.clear()
	balance.text = "%d Gold" % record.get("gold", 0)
	status_label.text = ""
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 20)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_grid)
	var token := _generation
	for slot in record.get("slots", []):
		var id := str(slot.get("slot_id", ""))
		var data := CollectionData.definition_card(_catalog, str(slot.get("definition_id", "")))
		if data.is_empty(): continue
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 10)
		_grid.add_child(column)
		var card := Ui.card(data, {}, 190)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = ""
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(func():
			if token == _generation: inspect_slot(id)
		)
		column.add_child(card)
		card_buttons[id] = card
		gestures.register_target(card, card.pressed.emit, card.pressed.emit)
		var buy := Ui.menu_action("Sold" if slot.get("sold", false) else "Buy · %d Gold" % slot.get("price", 0), true, Vector2(0, 68))
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.focus_mode = Control.FOCUS_NONE
		Ui.apply_states(buy, {"unavailable": bool(slot.get("sold", false))})
		buy.pressed.connect(func():
			if token == _generation: _request_purchase(id)
		)
		column.add_child(buy)
		buy_buttons[id] = buy
		gestures.register_target(buy, buy.pressed.emit)
	if record.get("slots", []).is_empty(): _body.add_child(Ui.label("No runes available this visit.", "body", 22))
	for slot in record.get("relic_slots", []):
		var relic: Dictionary = RelicPolicy.definitions().get(str(slot.get("definition_id", "")), {})
		if relic.is_empty(): continue
		var id := str(slot.get("slot_id", ""))
		_body.add_child(Ui.label(str(relic.name), "title", 22))
		_body.add_child(Ui.label(str(relic.description), "body", 18))
		var buy := Ui.menu_action("Sold" if slot.get("sold", false) else "Inspect relic · %d Gold" % slot.get("price", 60), true, Vector2(0, 68))
		buy.focus_mode = Control.FOCUS_NONE
		Ui.apply_states(buy, {"unavailable": bool(slot.get("sold", false))})
		buy.pressed.connect(func():
			if token == _generation: inspect_relic(id)
		)
		_body.add_child(buy)
		buy_buttons[id] = buy
		gestures.register_target(buy, buy.pressed.emit)
	_body.add_child(Ui.label("Services", "title", 26))
	var removal: Dictionary = record.get("removal", {})
	remove_button = Ui.menu_action("Rune removal · used" if removal.get("used", false) else "Remove one rune · %d Gold" % removal.get("price", 40), false, Vector2(0, 68))
	remove_button.focus_mode = Control.FOCUS_NONE
	Ui.apply_states(remove_button, {"unavailable": bool(removal.get("used", false))})
	remove_button.pressed.connect(open_removal)
	_body.add_child(remove_button)
	gestures.register_target(remove_button, open_removal)
	var upgrade: Dictionary = record.get("upgrade", {})
	upgrade_button = Ui.menu_action("Rune upgrade · used" if upgrade.get("used", false) else "Upgrade one rune · %d Gold" % upgrade.get("price", 35), false, Vector2(0, 68))
	upgrade_button.focus_mode = Control.FOCUS_NONE
	Ui.apply_states(upgrade_button, {"disabled": not bool(upgrade.get("eligible", false))})
	upgrade_button.pressed.connect(open_upgrade)
	_body.add_child(upgrade_button)
	gestures.register_target(upgrade_button, open_upgrade)
	if not upgrade.get("eligible", false): _body.add_child(Ui.label(str(upgrade.get("reason", "Upgrades are unavailable in this retained visit.")), "muted", 16))
	if record.get("relic_slots", []).is_empty(): _body.add_child(Ui.label("No relics available this visit.", "muted", 16))
	close_inspection()
	_fit()

func _can_act() -> bool:
	return not _blocked and not _disposed and is_visible_in_tree() and presentation.get("status") == "active" and not inspection.visible

func _slot(slot_id: String) -> Dictionary:
	for slot in presentation.get("slots", []):
		if slot.get("slot_id") == slot_id: return slot
	return {}

func _request_purchase(slot_id: String) -> void:
	if _blocked or _disposed or not is_visible_in_tree(): return
	var slot := _slot(slot_id)
	if slot.is_empty() or slot.get("sold", false): return
	purchase_requested.emit(presentation.get("identity", {}).duplicate(true), slot_id)

func inspect_slot(slot_id: String) -> void:
	if not _can_act(): return
	var slot := _slot(slot_id)
	if slot.is_empty(): return
	_begin_modal("item", str(_catalog.get(slot.definition_id, {}).get("name", "Rune")))
	_selected_slot = slot_id
	_add_card(_modal_body, str(slot.definition_id))
	var detail := CollectionData.definition_card(_catalog, str(slot.definition_id))
	if detail.get("inspection", "") != detail.get("description", ""):
		_modal_body.add_child(Ui.label(str(detail.inspection), "body", 16))
	_modal_body.add_child(Ui.label("Sold" if slot.get("sold", false) else "%d Gold" % slot.price, "body", 18))
	modal_action.text = "Buy · %d Gold" % slot.price
	modal_action.visible = not slot.get("sold", false)
	modal_close.text = "Back to shop"
	_finish_modal()

func open_removal() -> void:
	if not _can_act(): return
	if presentation.get("removal", {}).get("used", false): return
	if presentation.get("owned_cards", []).size() <= 4:
		report_error("Keep at least four runes in your collection.")
		return
	_begin_modal("selection", "Choose a rune to remove")
	_modal_body.add_child(Ui.label("Remove one copy · %d Gold" % presentation.get("removal", {}).get("price", 40), "body", 18))
	_selection_grid = GridContainer.new()
	_selection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_grid.add_theme_constant_override("h_separation", 14)
	_selection_grid.add_theme_constant_override("v_separation", 18)
	_modal_body.add_child(_selection_grid)
	selection_buttons.clear()
	var token := _generation
	for owned in presentation.get("owned_cards", []):
		var uid := int(owned.get("uid", -1))
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_selection_grid.add_child(column)
		var card := _add_instance_card(column, owned, true)
		card.pressed.connect(func():
			if token == _generation: select_removal(uid)
		)
		column.add_child(Ui.label("Copy %d" % uid, "muted", 16))
		selection_buttons[uid] = card
		gestures.register_target(card, card.pressed.emit)
	modal_action.hide()
	modal_close.text = "Cancel"
	_finish_modal()

func select_removal(uid: int) -> void:
	if _blocked or _disposed or _mode != "selection" or not inspection.visible: return
	var selected: Dictionary = {}
	for owned in presentation.get("owned_cards", []):
		if owned.get("uid") == uid: selected = owned
	if selected.is_empty(): return
	_begin_modal("remove", "Remove this rune?")
	_selected_uid = uid
	_add_instance_card(_modal_body, selected)
	var count: int = presentation.get("owned_cards", []).size()
	_modal_body.add_child(Ui.label("Copy %d · %d Gold\nCollection: %d to %d runes" % [uid, presentation.get("removal", {}).get("price", 40), count, count - 1], "body", 18))
	modal_action.text = "Remove · %d Gold" % presentation.get("removal", {}).get("price", 40)
	modal_action.show()
	modal_close.text = "Cancel"
	_finish_modal()

func confirm_removal() -> void:
	if _blocked or _disposed or not inspection.visible or _mode != "remove" or _selected_uid < 0: return
	remove_requested.emit(presentation.get("identity", {}).duplicate(true), _selected_uid)

func inspect_relic(slot_id: String) -> void:
	if not _can_act(): return
	var slot := _relic_slot(slot_id)
	var relic: Dictionary = RelicPolicy.definitions().get(str(slot.get("definition_id", "")), {})
	if slot.is_empty() or relic.is_empty(): return
	_begin_modal("relic", str(relic.name))
	_selected_slot = slot_id
	_modal_body.add_child(Ui.label(str(relic.description), "body", 18))
	_modal_body.add_child(Ui.label("Unique passive relic · this run only", "muted", 16))
	modal_action.text = "Buy · %d Gold" % int(slot.get("price", 60))
	modal_action.visible = not slot.get("sold", false)
	modal_close.text = "Cancel"
	_finish_modal()

func _relic_slot(slot_id: String) -> Dictionary:
	for slot in presentation.get("relic_slots", []):
		if slot.get("slot_id") == slot_id: return slot
	return {}

func open_upgrade() -> void:
	if not _can_act() or not presentation.get("upgrade", {}).get("eligible", false): return
	_begin_modal("upgrade_selection", "Choose a rune to upgrade")
	_modal_body.add_child(Ui.label("Upgrade one copy · %d Gold" % int(presentation.upgrade.get("price", 35)), "body", 18))
	_selection_grid = GridContainer.new()
	_selection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_grid.add_theme_constant_override("h_separation", 14)
	_selection_grid.add_theme_constant_override("v_separation", 18)
	_modal_body.add_child(_selection_grid)
	selection_buttons.clear()
	var token := _generation
	for owned in presentation.upgrade.get("targets", []):
		var uid := int(owned.get("uid", -1))
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_selection_grid.add_child(column)
		var card := _add_instance_card(column, owned, true)
		card.pressed.connect(func():
			if token == _generation: select_upgrade(uid)
		)
		column.add_child(Ui.label("Copy %d · unupgraded" % uid, "muted", 16))
		selection_buttons[uid] = card
		gestures.register_target(card, card.pressed.emit)
	modal_action.hide()
	modal_close.text = "Cancel"
	_finish_modal()

func select_upgrade(uid: int) -> void:
	if _blocked or _disposed or _mode != "upgrade_selection" or not inspection.visible: return
	var selected: Dictionary = {}
	for owned in presentation.get("upgrade", {}).get("targets", []):
		if int(owned.get("uid", -1)) == uid: selected = owned
	if selected.is_empty(): return
	_begin_modal("upgrade", "Upgrade this rune?")
	_selected_uid = uid
	_add_instance_card(_modal_body, selected)
	_modal_body.add_child(Ui.label("Copy %d\n\n%s" % [uid, CollectionData.upgrade_text(_catalog, selected)], "body", 18))
	modal_action.text = "Upgrade · %d Gold" % int(presentation.upgrade.get("price", 35))
	modal_action.show()
	modal_close.text = "Cancel"
	_finish_modal()

func confirm_upgrade() -> void:
	if _blocked or _disposed or not inspection.visible or _mode != "upgrade" or _selected_uid < 0: return
	upgrade_requested.emit(presentation.get("identity", {}).duplicate(true), _selected_uid)

func _modal_activate() -> void:
	if not inspection.visible: return
	if _mode == "item": _request_purchase(_selected_slot)
	elif _mode == "remove": confirm_removal()
	elif _mode == "upgrade": confirm_upgrade()
	elif _mode == "relic" and not _blocked and not _disposed:
		var slot := _relic_slot(_selected_slot)
		if not slot.is_empty() and not slot.get("sold", false): relic_purchase_requested.emit(presentation.get("identity", {}).duplicate(true), _selected_slot)

func _show_guide() -> void:
	if not _can_act(): return
	_begin_modal("guide", "Shop")
	_modal_body.add_child(Ui.label("Spend run Gold on offered runes and relics, or upgrade one eligible copy. Upgrades and removal are each available once this visit; keep at least four runes.\n\nTap a card to inspect it. Leave shop completes this room. Map and Home keep your visit open.", "body", 16))
	modal_action.hide()
	modal_close.text = "Back to shop"
	_finish_modal()

func _begin_modal(mode: String, title: String) -> void:
	gestures.cancel_pending()
	_clear(_modal_body)
	_selection_grid = null
	_mode = mode
	_modal_title.text = title
	_modal_scroll.scroll_vertical = 0
	Ui.apply_states(modal_action, {})

func _finish_modal() -> void:
	Ui.prepare_popup_content(panel)
	inspection.show()
	gestures.set_modal(inspection)
	_fit_modal()

func _add_card(parent: Node, definition_id: String, interactive: bool = false) -> Button:
	return _add_instance_card(parent, {"id": definition_id, "upgrade_rank": 0}, interactive)

func _add_instance_card(parent: Node, instance: Dictionary, interactive: bool = false) -> Button:
	var card := Ui.card(CollectionData.instance_card(_catalog, instance), {}, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.tooltip_text = ""
	if not interactive: card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(card)
	return card

func report_error(message: String) -> void:
	status_label.text = message
	if inspection.visible:
		for child in _modal_body.get_children():
			if child.name == "ActionError":
				_modal_body.remove_child(child)
				child.queue_free()
		var error := Ui.label(message, "body", 16)
		error.name = "ActionError"
		_modal_body.add_child(error)
		Ui.prepare_popup_content(panel)
		_fit_modal()

func dismiss_top() -> void:
	if _blocked or _disposed: return
	if inspection.visible: close_inspection()
	else: menu_requested.emit()

func close_inspection() -> void:
	inspection.hide()
	_mode = ""
	_selected_slot = ""
	_selected_uid = -1
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
	# Shop content keeps readable display-size controls through the configured
	# canvas transform. The approved shared navigation retains its own 82px
	# geometry and is positioned separately in the unchanged gameplay canvas.
	var canvas_scale := get_viewport().get_final_transform().get_scale().abs()
	if canvas_scale.x <= 0: return
	var rendered := size * canvas_scale
	var fit_scale := minf(1, minf(rendered.x / 360.0, rendered.y / 640.0))
	var content_scale := fit_scale / canvas_scale.x
	var width := size.x / content_scale
	var margin := 20.0
	for control in [_header, scroll, status_label, leave_button]: control.scale = Vector2.ONE * content_scale
	_header.position = Vector2(margin, 16) * content_scale
	_header.size = Vector2(width - margin * 2, 48)
	_title.position = Vector2.ZERO
	_title.size = Vector2(maxf(1, _header.size.x - 160), 48)
	_gold_icon.position = Vector2(_header.size.x - 148, 9)
	_gold_icon.size = Vector2(30, 30)
	balance.position = Vector2(_header.size.x - 112, 0)
	balance.size = Vector2(112, 48)
	_navigation.fit_viewport(size.x)
	_navigation.position = Vector2((size.x - _navigation.custom_minimum_size.x) / 2, size.y - _navigation.custom_minimum_size.y - 8)
	_navigation.size = _navigation.custom_minimum_size
	leave_button.position = Vector2(margin * content_scale, _navigation.position.y - 84 * content_scale)
	leave_button.size = Vector2(width - margin * 2, 68)
	status_label.position = Vector2(margin * content_scale, leave_button.position.y - 58 * content_scale)
	status_label.size = Vector2(width - margin * 2, 52)
	scroll.position = Vector2(margin, 82) * content_scale
	scroll.size = Vector2(width - margin * 2, maxf(80, status_label.position.y / content_scale - 96))
	if _grid != null: _grid.columns = 3 if scroll.size.x >= 620 else 2 if scroll.size.x >= 398 else 1
	_fit_modal()

func _fit_modal() -> void:
	if _disposed or panel == null: return
	Ui.fit_popup_overlay(inspection, panel, Vector2(560, 430), Vector2(280, 340))
	if is_instance_valid(_selection_grid): _selection_grid.columns = 2 if inspection.size.x - Ui.MODAL_OUTER_MARGIN * 2 >= 540 else 1

func prepare_for_exit() -> void:
	_disposed = true
	set_blocked(true)

static func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
