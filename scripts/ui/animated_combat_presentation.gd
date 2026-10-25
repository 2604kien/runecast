extends "res://scripts/ui/combat_presentation.gd"
## Detached, deterministic presentation. No model, RNG, timers or tween callbacks.
const STYLE = preload("res://scenes/vfx/combat_feedback_style.tres")
const FEEDBACK = preload("res://scenes/vfx/combat_feedback.tscn")
const SHADELING_MOTION = preload("res://assets/enemies/shadeling/motion.tres")
const TEMPORARY_ACTOR = preload("res://scripts/ui/temporary_enemy_actor.gd")
## Slow the presentation clock through frame hitches so short steps stay visible.
const MAX_AUTOMATIC_DELTA := 1.0 / 30.0

signal visual_changed(snapshot: Dictionary)
signal event_presented(event: Dictionary)
## Detached observations of this clock, never permission to resolve gameplay.
signal phase_started(notice: Dictionary)
signal contact_reached(notice: Dictionary)
signal presentation_cancelled(notice: Dictionary)

var reduced_motion := false
var automatic_timing := true
var duration := 0.0
var elapsed := 0.0
var phase := ""
var phase_progress := 0.0
var event_trace: Array = []
var _view: WeakRef
var _overlay: WeakRef
var _active := false
var _generation := 0
var _last_action := -1
var _last_encounter := -1
var _state: Dictionary = {}
var _result: Dictionary = {}
var _completed := Callable()
var _steps: Array = []
var _index := 0
var _step_elapsed := 0.0
var _contact_fraction := -1.0
var _contact_emitted := false
var _disposed := false

func _init(view: Node = null) -> void:
	if view != null:
		_view = weakref(view)
		var overlay := FEEDBACK.instantiate()
		view.add_child(overlay)
		overlay.bind_view(view)
		overlay.tick.connect(_tick)
		_overlay = weakref(overlay)

func display_snapshot(before: Dictionary, _after: Dictionary) -> Dictionary:
	return visual_snapshot() if _active else before.duplicate(true)

func visual_snapshot() -> Dictionary:
	return _state.duplicate(true)

func incoming_card() -> Dictionary:
	# A display-only card occupies its hand slot while fading in. Its zones and
	# counts still commit once at the event boundary, like every other value.
	if not _active or phase not in ["card_drawn", "card_created"] or _index >= _steps.size(): return {}
	var event: Dictionary = _steps[_index].event
	if event.type != phase: return {}
	for card in _state.hand:
		if int(card.uid) == int(event.card.uid): return {}
	return event.card.duplicate(true)

func incoming_card_opacity() -> float:
	return smoothstep(0.0, 1.0, phase_progress)

func is_active() -> bool:
	return _active

func present(result: Dictionary, completed: Callable) -> void:
	if _disposed: return
	# Action IDs are monotonic within a controller. Exact replay owns a new adapter.
	var action := int(result.get("action_id", 0))
	var encounter := int(result.get("encounter_id", 0))
	if not result.get("accepted", false) or action <= 0:
		completed.call()
		return
	if action <= _last_action and encounter <= _last_encounter:
		return
	var next_generation := _generation + 1
	cancel()
	# A cancellation subscriber may replace this action synchronously.
	if _disposed or _generation != next_generation: return
	_last_action = action
	_last_encounter = encounter
	_active = true
	_completed = completed
	_result = result.duplicate(true)
	_state = result.before.duplicate(true)
	_steps.clear()
	event_trace.clear()
	elapsed = 0.0
	duration = 0.0
	_index = 0
	_step_elapsed = 0.0
	for event in result.events:
		var seconds := _event_seconds(event)
		_steps.append({"event": event.duplicate(true), "seconds": seconds})
		duration += seconds
	var token := _generation
	_publish()
	if not _active or token != _generation: return
	if _steps.is_empty():
		_finish_sequence()
	else:
		_enter_step()

func _event_seconds(event: Dictionary) -> float:
	var seconds := 0.0
	var repetitions := 1
	match str(event.type):
		"cast": seconds = STYLE.traversal_seconds
		"damage": seconds = STYLE.hit_seconds
		"shield": seconds = STYLE.shield_seconds if int(event.amount) > 0 else 0.0
		"retaliation": seconds = STYLE.attack_seconds
		"technique": seconds = STYLE.technique_seconds
		"effect_consumed", "temporary_expired", "board_piece_cleared": seconds = STYLE.cleanup_seconds
		"turn_cleanup":
			seconds = STYLE.cleanup_seconds
			repetitions = event.discarded.size() + event.expired.size()
		"reshuffled": seconds = STYLE.cards_seconds
		"card_drawn", "card_created": seconds = STYLE.draw_seconds
		"battle_ended": seconds = STYLE.terminal_seconds
		"encounter_transition": seconds = STYLE.cards_seconds
		"enemy_phase_changed": seconds = STYLE.cards_seconds
	return (minf(seconds, STYLE.reduced_seconds) if reduced_motion else seconds) * repetitions

func _tick(delta: float) -> void:
	if automatic_timing: advance(minf(delta, MAX_AUTOMATIC_DELTA))

func advance(delta: float) -> void:
	if not _active or delta < 0.0: return
	var token := _generation
	var remaining := delta
	while _active and token == _generation and _index < _steps.size():
		var step: Dictionary = _steps[_index]
		# Split a large advance at contact, then consume its remaining time. The
		# notification observes the actual actor pose and exact logical timestamp.
		var boundary := float(step.seconds)
		if not _contact_emitted and _contact_fraction >= 0.0:
			boundary *= _contact_fraction
		var used := minf(remaining, maxf(0.0, boundary - _step_elapsed))
		_step_elapsed += used
		elapsed += used
		remaining -= used
		phase_progress = 1.0 if step.seconds <= 0.0 else clampf(_step_elapsed / step.seconds, 0.0, 1.0)
		_sample(step.event)
		if not _active or token != _generation: return
		if not _contact_emitted and _contact_fraction >= 0.0 and _step_elapsed >= float(step.seconds) * _contact_fraction:
			_contact_emitted = true
			contact_reached.emit(_phase_notice(step.event))
			if not _active or token != _generation: return
		if _step_elapsed + 0.000001 < float(step.seconds):
			if remaining > 0.0: continue
			return
		_clear_step_effects()
		_apply_event(step.event)
		event_trace.append(step.event.duplicate(true))
		_publish()
		if not _active or token != _generation: return
		event_presented.emit(step.event.duplicate(true))
		if not _active or token != _generation: return
		_index += 1
		_step_elapsed = 0.0
		if _index == _steps.size():
			_finish_sequence()
			return
		_enter_step()
		if not _active or token != _generation: return
		if remaining <= 0.0 and float(_steps[_index].seconds) > 0.0: return

func finish() -> void:
	advance(maxf(duration - elapsed, 0.0) + 0.001)

func _enter_step() -> void:
	var token := _generation
	phase = str(_steps[_index].event.type)
	phase_progress = 0.0
	_contact_fraction = _actor_contact_fraction() if phase == "retaliation" else -1.0
	_contact_emitted = false
	if phase in ["card_drawn", "card_created"]:
		var view = _view.get_ref() if _view != null else null
		# Build just this event's invisible card before its first rendered frame.
		if is_instance_valid(view) and not view._closing: view._refresh()
		if not _active or token != _generation: return
	_sample(_steps[_index].event)
	if not _active or token != _generation: return
	phase_started.emit(_phase_notice(_steps[_index].event))
	if not _active or token != _generation: return
	if _contact_fraction == 0.0:
		_contact_emitted = true
		contact_reached.emit(_phase_notice(_steps[_index].event))

func _actor_contact_fraction() -> float:
	# The bound actor's editable metadata owns contact. The exact shipped map
	# supports headless observation without inventing timing for future actors.
	var enemy_id := str(_result.before.get("encounter", {}).get("enemy_id", ""))
	var motion: Resource
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view) and is_instance_valid(view.arena.actor) and view.arena.actor.visible and str(view.arena.enemy_id) == enemy_id:
		if view.arena.actor.has_method("attack_contact_fraction"):
			return clampf(float(view.arena.actor.attack_contact_fraction()), 0.0, 1.0)
		motion = view.arena.actor.get("motion")
	elif enemy_id == "shadeling":
		motion = SHADELING_MOTION
	elif enemy_id in TEMPORARY_ACTOR.IDS:
		# Explicit shared token contact also covers detached/headless playback.
		# Never inherit the hidden Shadeling's motion or actor accent.
		return TEMPORARY_ACTOR.ATTACK_CONTACT
	if motion == null: return -1.0
	var value = motion.get("attack_contact")
	if value == null or not is_finite(float(value)): return -1.0
	return clampf(float(value), 0.0, 1.0)

func _phase_notice(event: Dictionary) -> Dictionary:
	return {"generation": _generation, "action_id": int(_result.get("action_id", 0)),
		"encounter_id": int(_result.get("encounter_id", 0)), "sequence": int(event.get("sequence", _index)),
		"event": event.duplicate(true), "elapsed": elapsed, "phase_elapsed": _step_elapsed,
		"phase_progress": phase_progress, "phase_duration": float(_steps[_index].seconds) if _index < _steps.size() else 0.0,
		"contact_fraction": _contact_fraction, "reduced_motion": reduced_motion}

func _clear_step_effects() -> void:
	# End every transient before publishing its consequence or entering the next
	# step. In particular, traversal/cleanup lights cannot spill into later events.
	var overlay = _overlay.get_ref() if _overlay != null else null
	if is_instance_valid(overlay): overlay.clear_effects()
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view): view._clear_card_arrival()
	if phase not in ["damage", "retaliation"] or not is_instance_valid(view): return
	var actor = view.arena.actor
	if is_instance_valid(actor) and actor.has_method("reset_presentation"):
		actor.reset_presentation(str(_state.get("state", "playing")), reduced_motion)
		actor.set_idle_enabled(false, reduced_motion)

func _apply_event(event: Dictionary) -> void:
	match str(event.type):
		"cast":
			_state.energy = event.energy_after
			_state.log_text = "Cast %d damage · %d shield" % [event.spell.damage, event.spell.shield]
		"damage":
			_state.enemy_hp = event.health_after
			if int(event.applied) > 0:
				_state.log_text = "%d HP lost" % event.applied
		"shield":
			_state.log_text = "%d shield" % event.amount
		"retaliation":
			_state.player_hp = event.health_after
			_state.log_text = "%d blocked · %d HP lost" % [event.blocked, event.applied]
		"passed": _state.log_text = "Passed turn"
		"effect_consumed", "temporary_expired", "board_piece_cleared":
			_state.board[int(event.cell)] = event.after.duplicate(true)
			if event.type == "effect_consumed": _state.discard_pile.append(event.card.duplicate(true))
			var kind: String = event.before.get("kind", "")
			if _state.stock.has(kind): _state.stock[kind] = mini(int(_state.stock_totals[kind]), int(_state.stock[kind]) + 1)
			_state.forecast.active.erase(int(event.cell))
			_state.forecast.valid = false
			_state.log_text = "Temporary expired" if event.type == "temporary_expired" else "Circuit clearing"
		"turn_cleanup":
			for card in event.discarded: _state.discard_pile.append(card.duplicate(true))
			_state.hand = event.hand_after.duplicate(true)
			_state.undo_count = 0
			_state.log_text = "%d discarded · %d expired" % [event.discarded.size(), event.expired.size()]
		"endpoints_changed":
			for kind in ["begin", "end"]: _state.board[int(event.before[kind].cell)] = {}
			for kind in ["begin", "end"]:
				var endpoint: Dictionary = event.after[kind]
				_state.board[int(endpoint.cell)] = {"kind": kind, "rotation": int(endpoint.rotation)}
		"kit_changed":
			_state.kit = event.after.duplicate(true)
			_state.stock_totals = event.after.totals.duplicate(true)
			_state.stock = event.after.totals.duplicate(true)
		"enemy_phase_changed":
			_state.enemy_action = event.after.duplicate(true)
			_state.intent = int(event.after.amount)
			_state.log_text = "Enemy phase %d" % int(event.after.phase)
		"turn_started":
			_state.turn = event.turn_after
			_state.energy = event.energy_after
			_state.intent = event.intent
			if event.has("enemy_action"): _state.enemy_action = event.enemy_action.duplicate(true)
			_state.forecast = _result.after.forecast.duplicate(true)
			_state.log_text = "Turn %d" % event.turn_after
		"reshuffled":
			_state.draw_pile = event.cards.duplicate(true)
			_state.discard_pile = []
			_state.log_text = "Reshuffled %d cards" % event.cards.size()
		"card_drawn":
			_remove_uid(_state.draw_pile, int(event.card.uid))
			_state.hand.append(event.card.duplicate(true))
			_state.log_text = "Drew " + str(_state.catalog[event.card.id].name)
		"card_created":
			_state.hand.append(event.card.duplicate(true))
			_state.log_text = "Created " + str(_state.catalog[event.card.id].name)
		"technique":
			_remove_uid(_state.hand, int(event.card.uid))
			_state.discard_pile.append(event.card.duplicate(true))
			_state.energy = event.energy_after
			_state.undo_count = 0
			_state.log_text = str(_state.catalog[event.card.id].name)
		"battle_ended":
			_state.state = event.state
			_state.player_hp = event.player_hp
			_state.enemy_hp = event.enemy_hp
			_state.log_text = str(event.state).capitalize()
		"encounter_transition":
			_state = _result.after.duplicate(true)
			_state.board = event.board_after.duplicate(true)
			_state.draw_pile = event.get("draw_after", []).duplicate(true)
			_state.hand = event.get("hand_after", []).duplicate(true)
			_state.discard_pile = event.get("discard_after", []).duplicate(true)

func _remove_uid(cards: Array, uid: int) -> void:
	for i in range(cards.size() - 1, -1, -1):
		if int(cards[i].uid) == uid:
			cards.remove_at(i)
			return

func _publish() -> void:
	visual_changed.emit(visual_snapshot())
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view) and not view._closing: view._refresh()

func _sample(event: Dictionary) -> void:
	var overlay = _overlay.get_ref() if _overlay != null else null
	if is_instance_valid(overlay): overlay.sample_event(event, _result.before, phase_progress, reduced_motion, _contact_fraction)
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view) and phase in ["card_drawn", "card_created"]:
		view._sample_card_arrival(int(event.card.uid), incoming_card_opacity())
	if not is_instance_valid(view) or not is_instance_valid(view.arena.actor) or not view.arena.actor.visible: return
	var actor = view.arena.actor
	if not actor.has_method("sample_presentation"): return
	actor.set_idle_enabled(false, reduced_motion)
	if phase == "retaliation": actor.sample_presentation("attack", phase_progress, reduced_motion)
	elif phase == "damage" and int(event.applied) > 0: actor.sample_presentation("hit", phase_progress, reduced_motion)
	elif phase == "battle_ended" and event.state == "victory": actor.sample_presentation("defeat", phase_progress, reduced_motion)
	else:
		actor.reset_presentation(str(_state.get("state", "playing")), reduced_motion)
		actor.set_idle_enabled(false, reduced_motion)

func _finish_sequence() -> void:
	var token := _generation
	_state = _result.after.duplicate(true)
	_publish()
	if not _active or token != _generation: return
	_active = false
	_clear_effects(str(_state.state))
	var completion := _completed
	_completed = Callable()
	_result.clear()
	_steps.clear()
	phase = ""
	if completion.is_valid(): completion.call()

func cancel() -> void:
	var notice: Dictionary = _phase_notice(_steps[_index].event if _index < _steps.size() else {}) if _active else {}
	_generation += 1
	_active = false
	_completed = Callable()
	_result.clear()
	_steps.clear()
	phase = ""
	phase_progress = 0.0
	_contact_fraction = -1.0
	_contact_emitted = false
	_clear_effects("playing")
	if not notice.is_empty(): presentation_cancelled.emit(notice)

func _clear_effects(battle_state: String) -> void:
	var overlay = _overlay.get_ref() if _overlay != null else null
	if is_instance_valid(overlay): overlay.clear_effects()
	var view = _view.get_ref() if _view != null else null
	if is_instance_valid(view): view._clear_card_arrival()
	if is_instance_valid(view) and is_instance_valid(view.arena.actor) and view.arena.actor.has_method("reset_presentation"):
		view.arena.actor.reset_presentation(battle_state, reduced_motion)

func dispose() -> void:
	_disposed = true
	cancel()
	var overlay = _overlay.get_ref() if _overlay != null else null
	if is_instance_valid(overlay):
		overlay.set_process(false)
		overlay.queue_free()
	_overlay = null
	_view = null
