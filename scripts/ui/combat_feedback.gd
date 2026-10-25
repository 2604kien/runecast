extends Control
## One reusable, input-transparent overlay. No particles, no per-cell emitters.
const BoardCell = preload("res://scripts/ui/board_cell.gd")
@export var style: Resource
signal tick(delta: float)
var _view: WeakRef
var _event: Dictionary = {}
var _before: Dictionary = {}
var _progress := 0.0
var _reduced := false
var _contact_fraction := -1.0
var _cast_lights: Dictionary = {}
var _technique_card: WeakRef
var _technique_scale := Vector2.ONE
var _technique_pivot := Vector2.ZERO
var _technique_tint := Color.WHITE

func bind_view(view: Node) -> void:
	_view = weakref(view)
	set_process(false)

func _process(delta: float) -> void:
	tick.emit(delta)
	queue_redraw()

func sample_event(event: Dictionary, before: Dictionary, progress: float, reduced: bool, contact_fraction := -1.0) -> void:
	_event = event
	_before = before
	_progress = progress
	_reduced = reduced
	_contact_fraction = contact_fraction
	_update_slot_lights()
	_sample_technique_card()
	set_process(true)
	queue_redraw()

func clear_effects() -> void:
	_restore_technique_card()
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view):
		for cell in view.cells:
			if is_instance_valid(cell): cell.set_feedback_light(0.0)
	_event = {}
	_before = {}
	_cast_lights.clear()
	set_process(false)
	queue_redraw()

func _exit_tree() -> void:
	clear_effects()
	_view = null

func _restore_technique_card() -> void:
	var card = _technique_card.get_ref() if _technique_card != null else null
	if is_instance_valid(card):
		card.modulate = _technique_tint
		card.scale = _technique_scale
		card.pivot_offset = _technique_pivot
	_technique_card = null

func _sample_technique_card() -> void:
	var view = _view.get_ref() if _view != null else null
	if _event.get("type", "") != "technique" or not is_instance_valid(view):
		_restore_technique_card()
		return
	# Refreshes recreate the hand. Resolve the supplied UID every sample and
	# never transfer the played-card effect to a different card or pile.
	var card: Control = null
	for candidate in view.hand_box.get_children():
		if int(candidate.get_meta("uid", -1)) == int(_event.card.uid):
			card = candidate
			break
	var previous = _technique_card.get_ref() if _technique_card != null else null
	if card != previous:
		_restore_technique_card()
		if card != null:
			_technique_card = weakref(card)
			_technique_tint = card.modulate
			_technique_scale = card.scale
			_technique_pivot = card.pivot_offset
	if card == null: return
	var progress := clampf(_progress, 0.0, 1.0)
	var brightness: float = 1.0 + style.technique_brightness * sin(PI * smoothstep(0.0, 0.65, progress))
	var opacity := 1.0 - smoothstep(0.45, 1.0, progress)
	card.modulate = _technique_tint * Color(brightness, brightness, brightness, opacity)
	# Shrinking inside its own slot avoids hand-scroll clipping and leaves the
	# HBox in charge of position/size. Reduced motion changes only colour/alpha.
	if not _reduced and card.size.x > 0.0 and card.size.y > 0.0:
		card.pivot_offset = card.size * 0.5
		card.scale = _technique_scale * (1.0 - style.technique_shrink * smoothstep(0.1, 1.0, progress))
	else:
		card.pivot_offset = _technique_pivot
		card.scale = _technique_scale

func _point(control: Control) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * (control.get_global_transform_with_canvas() * (control.size * 0.5))

func _shown(control: Control, view: Node) -> bool:
	if not is_instance_valid(control) or not control.is_visible_in_tree(): return false
	var position_in_view := control.get_global_transform_with_canvas() * (control.size * 0.5)
	return view.page_scroll.get_global_rect().has_point(position_in_view) and get_global_rect().has_point(position_in_view)

func _stat_label(control: Control, tint: Color, view: Node, text: String) -> void:
	if not _shown(control, view): return
	var center := _point(control)
	var offset := minf(control.size.x, control.size.y) * 0.42 + 9.0
	var font := get_theme_default_font()
	var size_px := 18
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	var p := center + Vector2(-width * 0.5, -offset)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 4, Color("171629"))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, tint)

func _draw() -> void:
	var view = _view.get_ref() if _view != null else null
	if _event.is_empty() or not is_instance_valid(view): return
	# Window modals are already above this canvas; in-page inspection is z=100.
	var kind := str(_event.type)
	match kind:
		"enemy_phase_changed":
			_enemy_label(view, "Phase %d" % int(_event.after.phase), Color("ead18e"))
		"damage":
			if int(_event.applied) > 0:
				_enemy_label(view, "−%d HP" % _event.applied, style.damage_color)
		"shield":
			if int(_event.amount) > 0: _stat_label(view.stat_values.health, style.shield_color, view, "+%d shield" % _event.amount)
		"retaliation":
			# Registered actors share their explicit presentation contact with
			# audio. Retain the old visual-only timing for excluded/unbound
			# fixtures; that fallback never invents actor metadata or a cue.
			var text_contact := _contact_fraction if _contact_fraction >= 0.0 else (0.0 if _reduced else 0.5)
			if _progress >= text_contact:
				var label := "%d blocked" % _event.blocked if int(_event.applied) == 0 else "−%d HP" % _event.applied
				if int(_event.blocked) > 0 and int(_event.applied) > 0: label = "%d blocked · %s" % [_event.blocked, label]
				_stat_label(view.stat_values.health, style.shield_color if int(_event.applied) == 0 else style.damage_color, view, label)

func _enemy_label(view: Node, text: String, tint: Color) -> void:
	if not _shown(view.arena, view): return
	# Outcome text belongs to the body, away from the live name/health lanes.
	var center := _point(view.arena)
	if is_instance_valid(view.arena.actor) and view.arena.actor.is_visible_in_tree():
		center = get_global_transform_with_canvas().affine_inverse() * view.arena.actor.get_attachment_position(&"body_center", true)
	var font := get_theme_default_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var p := center + Vector2(-width * 0.5, -18)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color("171629"))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)

func _update_slot_lights() -> void:
	var view = _view.get_ref() if _view != null else null
	if not is_instance_valid(view): return
	if _event.type == "cast":
		# Visit only the detached accepted circuit. The cells draw the same mint
		# stone illumination as Begin/End, below their own wires and symbols.
		var active: Array = _event.spell.active
		var sweep := clampf(_progress / 0.7, 0.0, 1.0)
		var fade := 1.0 - smoothstep(0.85, 1.0, _progress)
		for rank in range(active.size()):
			var index := int(active[rank])
			if _before.board[index].get("kind", "") in ["begin", "end"]: continue
			_cast_lights[index] = fade if _reduced else smoothstep(0.0, 1.0, sweep * active.size() - rank) * fade
	for index in range(view.cells.size()):
		var strength := float(_cast_lights.get(index, 0.0))
		var tint := BoardCell.CONNECTED_LIGHT
		if _event.type in ["effect_consumed", "temporary_expired", "board_piece_cleared"] and _event.get("cell", -1) == index:
			# One clearance at a time; its light ends before the next slot starts.
			strength = 1.0 - smoothstep(0.0, 1.0, _progress)
			if _event.type == "temporary_expired": tint = style.expiry_color
		view.cells[index].set_feedback_light(strength, tint)
