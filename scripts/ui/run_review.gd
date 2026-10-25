extends Control
## Read-only committed run history. The shell owns every transition and save.
const Ui = preload("res://scenes/ui/theme/components.gd")
const InstanceEffects = preload("res://scripts/core/instance_effects.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
signal action_requested(action: String, identity: Dictionary)

var panel: PanelContainer
var body_scroll: ScrollContainer
var primary_button: Button
var secondary_button: Button
var presentation: Dictionary = {}
var identity: Dictionary = {}
var final_review := false
var _title: Label
var _body: VBoxContainer
var _router: Node
var _primary_callback: Callable
var _secondary_callback: Callable

func _ready() -> void:
	name = "RunReview"
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 110
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = Ui.modal("Run details", "", 280, 430, "Back to Map")
	add_child(panel)
	_title = panel.get_child(0).get_child(0)
	body_scroll = panel.get_meta("rc_body_scroll")
	var placeholder := body_scroll.get_child(0)
	body_scroll.remove_child(placeholder)
	placeholder.queue_free()
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	body_scroll.add_child(_body)
	primary_button = panel.get_meta("rc_confirm")
	secondary_button = panel.get_meta("rc_close")
	panel.minimum_size_changed.connect(func(): _fit.call_deferred())
	get_viewport().size_changed.connect(func(): _fit.call_deferred())
	Ui.prepare_popup_content(panel)
	hide()

func register_gestures(router: Node) -> void:
	_router = router
	router.register_scroll(body_scroll)
	router.register_target(primary_button, primary_button.pressed.emit)
	router.register_target(secondary_button, secondary_button.pressed.emit)

func present(state: Dictionary, token: Dictionary, final: bool) -> void:
	if _router != null: _router.cancel_pending(true)
	presentation = state.get("summary", {}).duplicate(true)
	identity = token.duplicate(true)
	final_review = final
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var outcome := str(presentation.get("outcome", "in_progress"))
	var outcome_text: String = {"in_progress": "In progress", "victory": "Tower complete", "defeat": "Defeated", "abandoned": "Abandoned"}.get(outcome, outcome.capitalize())
	_title.text = "Run results" if final else "Run details"
	_heading(str(outcome_text))
	var route_name := str(state.get("route", {}).get("display_name", ""))
	if not route_name.is_empty(): _line(route_name)
	_line("Health %d / %d · Gold %d" % [presentation.get("player_hp", 0), presentation.get("player_max_hp", 0), presentation.get("gold", 0)])
	if final:
		_line("This run has ended. Its collection and relics are a read-only record.")
	elif state.get("status") in ["battle", "replay_pending"]:
		_line("History and health use the saved battle-entry checkpoint. Current turn preparation is not part of this record.")
	_heading("Rooms · %d entered / %d completed" % [presentation.get("entered_rooms", 0), presentation.get("completed_rooms", 0)])
	for visit in presentation.get("visits", []):
		var status := str(visit.get("status", "entered")).replace("_", " ")
		if final and status == "active": status = "Entered · unfinished"
		_line("%s · %s\n%s" % [str(visit.get("title", "Room")), str(visit.get("room_type", "")).capitalize(), status.capitalize()])
	if presentation.get("visits", []).is_empty(): _line("No rooms entered.")
	_heading("Defeated enemies · %d" % int(presentation.get("defeated_enemy_count", 0)))
	for enemy in presentation.get("defeated_enemies", []): _line(str(enemy.get("name", enemy.get("enemy_id", "Enemy"))))
	if presentation.get("defeated_enemies", []).is_empty(): _line("None.")
	_heading("Final owned runes" if final else "Owned runes")
	for card in presentation.get("owned_cards", []):
		var definition: Dictionary = card.get("effective_definition", {})
		var rank := int(card.get("upgrade_rank", 0))
		var effect := InstanceEffects.effect_summary(definition) if not definition.is_empty() else str(card.get("effect_summary", ""))
		_line("%s%s · UID %d · Rank %d\n%s · Energy %d" % [str(card.get("name", card.get("id", "Rune"))), " +" if rank == 1 else "", int(card.get("uid", 0)), rank, effect, int(definition.get("cost", 0))])
	_heading("Run relics")
	for relic_id in presentation.get("relics", []):
		var relic: Dictionary = RelicPolicy.definitions().get(str(relic_id), {})
		_line("%s\n%s" % [str(relic.get("name", relic_id)), str(relic.get("description", ""))])
	if presentation.get("relics", []).is_empty(): _line("None.")
	_heading("Permanent awards this run")
	_line("Definition unlocks remain available for future runs. They do not grant stored card copies.")
	for award in presentation.get("permanent_awards", []): _line(str(award.get("name", award.get("definition_id", "Rune"))))
	if presentation.get("permanent_awards", []).is_empty(): _line("No permanent definition was awarded during this run.")
	if not final and not bool(state.get("can_abandon", false)):
		_line(str(state.get("abandonment_error", "Review pending results and choices before abandoning this run.")))
	primary_button.text = "New Run" if final else "Back to Map"
	secondary_button.text = "Home" if final else "Abandon Run" if state.get("can_abandon", false) else "Review pending choices"
	Ui.apply_states(primary_button, {})
	Ui.apply_states(secondary_button, {})
	if _primary_callback.is_valid(): primary_button.pressed.disconnect(_primary_callback)
	if _secondary_callback.is_valid(): secondary_button.pressed.disconnect(_secondary_callback)
	_primary_callback = _dispatch.bind("new_run" if final else "close", identity.duplicate(true))
	_secondary_callback = _dispatch.bind("home" if final else "abandon" if state.get("can_abandon", false) else "pending", identity.duplicate(true))
	primary_button.pressed.connect(_primary_callback)
	secondary_button.pressed.connect(_secondary_callback)
	body_scroll.scroll_vertical = 0
	Ui.prepare_popup_content(panel)
	show()
	_fit()

func _heading(text: String) -> void:
	_body.add_child(Ui.label(text, "title", 22))

func _line(text: String) -> void:
	_body.add_child(Ui.label(text, "body", 16))

func _dispatch(action: String, token: Dictionary) -> void:
	if not visible or token != identity: return
	action_requested.emit(action, token.duplicate(true))

func dismiss_top() -> void:
	_dispatch("home" if final_review else "close", identity)

func _fit() -> void:
	if panel != null and is_inside_tree(): Ui.fit_popup_overlay(self, panel, Vector2(560, 660), Vector2(280, 430))
