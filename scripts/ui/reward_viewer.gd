extends Control
## Detached reward presentation. Only RunState may accept a choice or payout.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
signal choose_requested(identity: Dictionary, definition_id: String)
signal skip_requested(identity: Dictionary)
signal gold_requested(identity: Dictionary)
signal close_requested

var panel: PanelContainer
var scroll: ScrollContainer
var close_button: Button
var skip_button: Button
var gold_button: Button
var choose_buttons: Dictionary = {}
var presentation: Dictionary = {}
var _body: VBoxContainer
var _grid: GridContainer
var _router: Node
var _skip_callback: Callable
var _gold_callback: Callable

func _ready() -> void:
	name = "Rewards"
	theme = Ui.THEME
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 125
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.92)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = Ui.modal("Encounter rewards", "", 280, 430)
	add_child(panel)
	panel.minimum_size_changed.connect(func(): _fit.call_deferred())
	scroll = panel.get_meta("rc_body_scroll")
	scroll.follow_focus = false
	var placeholder := scroll.get_child(0)
	scroll.remove_child(placeholder)
	placeholder.queue_free()
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	scroll.add_child(_body)
	close_button = panel.get_meta("rc_close")
	close_button.text = "Close rewards"
	close_button.pressed.connect(func(): close_requested.emit())
	var footer: Control = close_button.get_parent()
	gold_button = Ui.menu_action("Claim Gold", true, Vector2(0, Ui.POPUP_ACTION_HEIGHT))
	skip_button = Ui.menu_action("Skip rune", false, Vector2(0, Ui.POPUP_ACTION_HEIGHT))
	footer.add_child(gold_button)
	footer.add_child(skip_button)
	footer.move_child(gold_button, 0)
	footer.move_child(skip_button, 1)
	for button in [close_button, gold_button, skip_button]: button.focus_mode = Control.FOCUS_NONE
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
	if _skip_callback.is_valid(): skip_button.pressed.disconnect(_skip_callback)
	if _gold_callback.is_valid(): gold_button.pressed.disconnect(_gold_callback)
	var offered_identity: Dictionary = record.get("identity", {}).duplicate(true)
	_skip_callback = func(): skip_requested.emit(offered_identity.duplicate(true))
	_gold_callback = func(): gold_requested.emit(offered_identity.duplicate(true))
	skip_button.pressed.connect(_skip_callback)
	gold_button.pressed.connect(_gold_callback)
	if _router != null:
		_router.register_target(skip_button, _skip_callback)
		_router.register_target(gold_button, _gold_callback)
	var same_identity: bool = presentation.get("identity", {}) == record.get("identity", {})
	var previous_scroll := scroll.scroll_vertical if same_identity else 0
	presentation = record.duplicate(true)
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	choose_buttons.clear()
	_grid = null
	var available: bool = record.get("status", "unavailable") != "unavailable" and record.get("enabled", true)
	var rune_pending: bool = available and record.get("rune_status", "pending") == "pending"
	_body.add_child(Ui.label(str(record.get("summary", "Choose one rune for this run, or Skip.")), "body", 18))
	if not available:
		_body.add_child(Ui.label(str(record.get("error", "This reward policy is unavailable. The choice remains pending.")), "body", 17))
	else:
		_body.add_child(Ui.label("An unlock adds definition eligibility for future rewards and shops; it grants no stored card copy. Closing keeps this choice pending." if record.get("kind") == "definition_unlock" else "A chosen card joins your run collection for the next encounter. Closing keeps any unresolved choice pending.", "muted", 16))
		var policy_id := str(record.get("policy_id", ""))
		if "test" in policy_id:
			_body.add_child(Ui.label("TEST FIXTURE · configured rewards are verification values.", "body", 16))
		_grid = GridContainer.new()
		_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_theme_constant_override("h_separation", 14)
		_grid.add_theme_constant_override("v_separation", 18)
		_body.add_child(_grid)
		for id in record.get("offered_ids", []):
			var data := CollectionData.definition_card(catalog, str(id))
			if data.is_empty(): continue
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_grid.add_child(column)
			var card := Ui.card(data, {}, 210)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.focus_mode = Control.FOCUS_NONE
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.tooltip_text = ""
			column.add_child(card)
			var choose := Ui.menu_action(("Unlock " if record.get("kind") == "definition_unlock" else "Choose ") + str(data.name), true, Vector2(0, Ui.POPUP_ACTION_HEIGHT))
			choose.focus_mode = Control.FOCUS_NONE
			choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			Ui.apply_states(choose, {"unavailable": not rune_pending})
			var identity: Dictionary = record.get("identity", {}).duplicate(true)
			choose.pressed.connect(func(): choose_requested.emit(identity.duplicate(true), str(id)))
			column.add_child(choose)
			choose_buttons[str(id)] = choose
			if _router != null: _router.register_target(choose, choose.pressed.emit)
		if record.get("offered_ids", []).is_empty() and rune_pending:
			_body.add_child(Ui.label("No eligible runes are available. Skip resolves this rune choice without granting a card.", "body", 17))
		var permanent: Dictionary = record.get("permanent", {})
		if not permanent.is_empty():
			_body.add_child(Ui.label(str(permanent.get("summary", "")), "body", 16))
	var gold_amount := int(record.get("gold", 0))
	gold_button.visible = available and gold_amount > 0 and not bool(record.get("gold_claimed", false))
	gold_button.text = "Claim %d Gold" % gold_amount
	skip_button.visible = rune_pending and bool(record.get("allow_skip", true))
	Ui.prepare_popup_content(panel)
	show()
	_fit()
	scroll.set_deferred("scroll_vertical", previous_scroll)

func report_error(message: String) -> void:
	_body.add_child(Ui.label(message, "body", 16))
	Ui.prepare_popup_content(panel)
	_fit()

func _fit() -> void:
	if panel == null: return
	Ui.fit_popup_overlay(self, panel, Vector2(680, 1100), Vector2(280, 430))
	if _grid != null: _grid.columns = 2 if size.x - Ui.MODAL_OUTER_MARGIN * 2 >= 540 else 1
