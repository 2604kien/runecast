extends Control
## Detached catalogue presentation. RunState owns prices, limits and purchases.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
const InstanceEffects = preload("res://scripts/core/instance_effects.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
signal purchase_requested(identity: Dictionary, kind: String, definition_id: String)
signal close_requested

var panel: PanelContainer
var scroll: ScrollContainer
var close_button: Button
var purchase_buttons: Dictionary = {}
var presentation: Dictionary = {}
var _body: VBoxContainer
var _router: Node
var _blocked := false
var _presentation_generation := 0

func _ready() -> void:
	name = "Store"
	theme = Ui.THEME
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 110
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.92)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = Ui.modal("Store", "", 280, 430)
	add_child(panel)
	panel.minimum_size_changed.connect(func(): _fit.call_deferred())
	scroll = panel.get_meta("rc_body_scroll")
	scroll.follow_focus = false
	var placeholder := scroll.get_child(0)
	scroll.remove_child(placeholder)
	placeholder.queue_free()
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_body)
	close_button = panel.get_meta("rc_close")
	close_button.text = "Back to Menu"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func():
		if not _blocked: close_requested.emit()
	)
	resized.connect(func(): _fit.call_deferred())
	get_viewport().size_changed.connect(func(): _fit.call_deferred())
	Ui.prepare_popup_content(panel)
	hide()
	_fit()

func register_gestures(router: Node) -> void:
	_router = router
	_router.register_scroll(scroll)
	_router.register_target(close_button, close_button.pressed.emit)

func present(record: Dictionary, catalog: Dictionary) -> void:
	if _router != null: _router.cancel_pending()
	_presentation_generation += 1
	var generation := _presentation_generation
	var previous_scroll := scroll.scroll_vertical if visible else 0
	presentation = record.duplicate(true)
	_blocked = false
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	purchase_buttons.clear()
	_body.add_child(Ui.label("%d Gold" % int(record.get("gold", 0)), "value", 16))
	if not record.get("enabled", false):
		_body.add_child(Ui.label(str(record.get("error", "Finish this room and its rewards to use the Store.")), "body", 16))
	for kind in ["rune", "relic"]:
		var purchased: bool = record.get(kind + "_purchased", false)
		var items: Array = record.get("runes" if kind == "rune" else "relics", [])
		var cost := int(items[0].get("cost", 0)) if not items.is_empty() else 0
		var heading := HBoxContainer.new()
		var category := Ui.label("Runes" if kind == "rune" else "Relics", "title", 22)
		category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(category)
		var price := Ui.label("%d Gold" % cost, "value", 16)
		price.visible = not items.is_empty()
		price.autowrap_mode = TextServer.AUTOWRAP_OFF
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		heading.add_child(price)
		_body.add_child(heading)
		var status := "Purchased this run" if purchased else "1 purchase this run"
		if not purchased and int(record.get("gold", 0)) < cost:
			status = "Need %d more Gold" % (cost - int(record.get("gold", 0)))
		elif not purchased and not items.is_empty() and not items.any(func(item): return item.get("enabled", false)):
			status = "All relics owned" if kind == "relic" and items.all(func(item): return item.get("owned", false)) else str(items[0].get("error", "Unavailable"))
		if items.is_empty(): status = "No unlocked runes" if kind == "rune" else "No relics available"
		_body.add_child(Ui.label(status, "muted", 16))
		for item in items:
			var definition_id := str(item.get("definition_id", ""))
			var icon_name := ""
			var summary := ""
			if kind == "rune":
				var data := CollectionData.definition_card(catalog, definition_id)
				if data.is_empty(): continue
				icon_name = str(data.icon)
				summary = InstanceEffects.effect_summary(catalog[definition_id])
			else:
				var relic: Dictionary = RelicPolicy.definitions().get(definition_id, {})
				icon_name = _relic_icon(str(relic.get("hook", "")))
				summary = "Owned" if item.get("owned", false) else _relic_summary(relic)
			var button := _item_row(str(item.get("name", definition_id)), summary, icon_name)
			button.set_meta("store_enabled", bool(item.get("enabled", false)) and bool(record.get("enabled", false)))
			var identity: Dictionary = record.get("identity", {}).duplicate(true)
			button.pressed.connect(func():
				if not _blocked and is_visible_in_tree() and generation == _presentation_generation:
					purchase_requested.emit(identity.duplicate(true), kind, definition_id)
			)
			_body.add_child(button)
			purchase_buttons[kind + ":" + definition_id] = button
			if _router != null: _router.register_target(button, button.pressed.emit)
	Ui.prepare_popup_content(panel)
	set_blocked(false)
	show()
	_fit()
	scroll.set_deferred("scroll_vertical", previous_scroll)

func set_blocked(value: bool) -> void:
	_blocked = value
	Ui.apply_states(close_button, {"disabled": value})
	for button in purchase_buttons.values():
		Ui.apply_states(button, {"unavailable": not button.get_meta("store_enabled", false), "disabled": value})
		button.get_meta("store_content").modulate = Color("aeb8c2") if button.disabled else Color.WHITE

func _item_row(item_name: String, summary: String, icon_name: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, Ui.POPUP_ACTION_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("192f40") if state in ["hover", "pressed"] else Color("102131")
		style.border_color = Color("64b5aa") if state in ["hover", "pressed"] else Color("344554")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, style)
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]: content.add_theme_constant_override("margin_" + side, 10)
	for side in ["top", "bottom"]: content.add_theme_constant_override("margin_" + side, 8)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.set_meta("store_content", content)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var glyph := Ui.icon(icon_name, 32)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	copy.add_child(Ui.label(item_name, "body", 16))
	copy.add_child(Ui.label(summary, "muted", 16))
	var arrow := Ui.label("›", "value", 16)
	arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(arrow)
	content.minimum_size_changed.connect(func():
		button.custom_minimum_size.y = maxf(Ui.POPUP_ACTION_HEIGHT, content.get_combined_minimum_size().y)
	)
	return button

func _relic_icon(hook: String) -> String:
	return {"final_damage": "spark", "final_shield": "shield", "opening_draw": "focus", "opening_energy": "energy", "recovery": "health", "acquisition_health": "health"}.get(hook, "health")

func _relic_summary(relic: Dictionary) -> String:
	var amount := int(relic.get("value", 0))
	match str(relic.get("hook", "")):
		"final_damage": return "Damage spells +%d" % amount
		"final_shield": return "Shield spells +%d" % amount
		"opening_draw": return "Opening draw +%d" % amount
		"opening_energy": return "First-turn energy +%d" % amount
		"recovery": return "Recovery healing +%d" % amount
		"acquisition_health": return "+%d HP and max HP" % amount
	return "Run relic"

func report_error(message: String) -> void:
	_body.add_child(Ui.label(message, "body", 16))
	Ui.prepare_popup_content(panel)
	_fit()

func _fit() -> void:
	if panel == null: return
	Ui.fit_popup_overlay(self, panel, Vector2(560, 660), Vector2(280, 430))
