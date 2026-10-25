extends Control
## A read-only overlay over the previous screen. It owns no model/controller,
## and emits only dismissal. All information is copied on presentation.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
signal close_requested

var panel: PanelContainer
var body_scroll: ScrollContainer
var close_button: Button
var card_buttons: Array[Button] = []
var relic_buttons: Array[Button] = []
var presentation: Dictionary = {}
var detail_visible := false
var _relic_detail := false
var _title: Label
var _listing: VBoxContainer
var _detail: VBoxContainer
var _grid: GridContainer
var _router: Node
var _list_scroll := 0
var _presentation_generation := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 115
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = Ui.modal("Run collection", "", 280, 430)
	add_child(panel)
	_title = panel.get_child(0).get_child(0)
	body_scroll = panel.get_meta("rc_body_scroll")
	body_scroll.follow_focus = false
	var placeholder := body_scroll.get_child(0)
	body_scroll.remove_child(placeholder)
	placeholder.queue_free()
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)
	_listing = VBoxContainer.new()
	_listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_listing.add_theme_constant_override("separation", 14)
	body.add_child(_listing)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 14)
	body.add_child(_detail)
	_detail.hide()
	close_button = panel.get_meta("rc_close")
	close_button.pressed.connect(dismiss_top)
	panel.minimum_size_changed.connect(func(): _fit.call_deferred())
	resized.connect(func(): _fit.call_deferred())
	get_viewport().size_changed.connect(func(): _fit.call_deferred())
	Ui.prepare_popup_content(panel)
	_fit()
	hide()

func register_gestures(router: Node) -> void:
	_router = router
	_router.register_scroll(body_scroll)
	_router.register_target(close_button, dismiss_top)
	for button in card_buttons: _register_card(button)

func present(run_snapshot: Dictionary, catalog: Dictionary, live_snapshot: Dictionary = {}) -> void:
	_presentation_generation += 1
	presentation = CollectionData.describe(run_snapshot, catalog, live_snapshot)
	_clear(_listing)
	_clear(_detail)
	card_buttons.clear()
	relic_buttons.clear()
	_title.text = "Run collection"
	detail_visible = false
	_relic_detail = false
	_detail.hide()
	_listing.show()
	close_button.text = "Close collection"
	_listing.add_child(Ui.label("%d owned cards · %d rune definitions" % [presentation.owned_count, presentation.definition_count], "body", 18))
	_listing.add_child(Ui.label("Cards belong to this run. Installing a rune keeps it owned. Tap a card to inspect its copies.", "muted", 16))
	if presentation.has_live:
		var zones: Dictionary = presentation.zone_counts
		_listing.add_child(Ui.label("%s · owned card locations\nHand %d · Draw %d · Discard %d · Installed %d" % ["Live battle" if presentation.battle_active else "Settled battle", zones.hand, zones.draw_pile, zones.discard_pile, zones.installed], "body", 16))
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 18)
	_listing.add_child(_grid)
	for group in presentation.groups:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 7)
		_grid.add_child(column)
		var button := Ui.card(group.card, {}, 210)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = ""
		button.set_meta("collection_group", group.duplicate(true))
		button.pressed.connect(_inspect_group.bind(group))
		column.add_child(button)
		card_buttons.append(button)
		if _router != null: _register_card(button)
		column.add_child(Ui.label("Owned × %d" % group.count, "body", 17))
		column.add_child(Ui.label(_instances_text(group.instances), "muted", 15))
	if presentation.groups.is_empty(): _listing.add_child(Ui.label("No owned runes in this run.", "body", 18))
	_listing.add_child(Ui.label("Run relics", "title", 20))
	if presentation.relics.is_empty(): _listing.add_child(Ui.label("No relics acquired.", "muted", 16))
	for relic in presentation.relics:
		var button := Ui.menu_action(str(relic.get("name", "Relic")), false, Vector2(0, 68))
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_inspect_relic.bind(relic))
		_listing.add_child(button)
		relic_buttons.append(button)
		if _router != null: _router.register_target(button, button.pressed.emit, button.pressed.emit)
	if not presentation.temporary.is_empty():
		_listing.add_child(Ui.label("Temporary battle cards · not owned", "title", 20))
		_listing.add_child(Ui.label("Generated cards disappear after Cast or Pass and never enter run ownership.", "muted", 16))
		for item in presentation.temporary:
			_listing.add_child(Ui.label("%s · UID %d · %s\nCost %d · %s" % [item.card.name, item.uid, item.label, item.card.cost, item.card.description], "body", 16))
	if presentation.has_profile:
		_listing.add_child(Ui.label("Permanent definition unlocks", "title", 20))
		_listing.add_child(Ui.label("Saved unlocks remain after restarting the application and starting a New Run. They enable future rewards, shops and Store entries, grant no stored card copies and do not change the starter collection.", "muted", 16))
		var names: Array[String] = []
		for definition in presentation.unlocked_definitions: names.append(str(definition.name))
		_listing.add_child(Ui.label("Unlocked: " + (", ".join(names) if not names.is_empty() else "None"), "body", 16))
	_list_scroll = 0
	body_scroll.scroll_vertical = 0
	Ui.prepare_popup_content(panel)
	show()
	_fit()

func _register_card(button: Button) -> void:
	var group: Dictionary = button.get_meta("collection_group")
	_router.register_target(button, _inspect_group.bind(group), _inspect_group.bind(group))

func _inspect_group(group: Dictionary) -> void:
	if not visible or detail_visible: return
	_relic_detail = false
	_list_scroll = body_scroll.scroll_vertical
	if _router != null: _router.cancel_pending()
	_clear(_detail)
	_title.text = str(group.card.name)
	var card := Ui.card(group.card, {}, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.focus_mode = Control.FOCUS_NONE
	_detail.add_child(card)
	if group.card.get("inspection", "") != group.card.description:
		_detail.add_child(Ui.label(str(group.card.inspection), "body", 16))
	_detail.add_child(Ui.label("Owned × %d\n%s" % [group.count, _instances_text(group.instances)], "body", 18))
	_detail.add_child(Ui.label("Upgraded · rank 1. These copies retain their upgrade for this run." if int(group.get("upgrade_rank", 0)) > 0 else "Unupgraded copies. Each eligible copy may be upgraded once during this run.", "body", 16))
	_detail.add_child(Ui.label("Inspection is read-only. Techniques activate only from the battle hand.", "muted", 16))
	_listing.hide()
	_detail.show()
	detail_visible = true
	close_button.text = "Back to collection"
	body_scroll.scroll_vertical = 0
	Ui.prepare_popup_content(panel)
	_fit()

func _inspect_relic(relic: Dictionary) -> void:
	if not visible or detail_visible: return
	_relic_detail = true
	_list_scroll = body_scroll.scroll_vertical
	if _router != null: _router.cancel_pending()
	_clear(_detail)
	_title.text = str(relic.get("name", "Relic"))
	_detail.add_child(Ui.label(str(relic.get("description", "")), "body", 18))
	_detail.add_child(Ui.label("Passive run relic · unique\nThis relic lasts for the current run and never occupies the board.", "muted", 16))
	_listing.hide()
	_detail.show()
	detail_visible = true
	close_button.text = "Back to collection"
	body_scroll.scroll_vertical = 0
	Ui.prepare_popup_content(panel)
	_fit()

func dismiss_top() -> void:
	if _router != null: _router.cancel_pending()
	if detail_visible:
		detail_visible = false
		_detail.hide()
		_listing.show()
		_title.text = "Run collection"
		close_button.text = "Close collection"
		_fit()
		_restore_list_scroll(_presentation_generation, _list_scroll)
	else:
		close_requested.emit()

func _restore_list_scroll(generation: int, offset: int) -> void:
	# Showing the taller list schedules container sorting. Assigning before
	# that sort clamps its saved offset to the shorter detail body's range.
	for frame in 2: await get_tree().process_frame
	if is_inside_tree() and visible and not detail_visible and generation == _presentation_generation:
		body_scroll.scroll_vertical = offset

func _fit() -> void:
	if panel == null: return
	Ui.fit_popup_overlay(self, panel, Vector2(660, 430 if detail_visible and _relic_detail else 1000), Vector2(280, 430))
	if _grid != null: _grid.columns = 2 if size.x - Ui.MODAL_OUTER_MARGIN * 2 >= 540 else 1

static func _instances_text(instances: Array) -> String:
	var lines: Array[String] = []
	for instance in instances: lines.append("UID %d · %s" % [instance.uid, instance.location])
	return "\n".join(lines)

static func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
