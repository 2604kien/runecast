extends RefCounted
## Deterministic tests of the production adapter, using real model results.
## No wall-clock waits, gameplay callbacks, or presentation-only fake events.

const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const FeedbackStyle = preload("res://scenes/vfx/combat_feedback_style.tres")

func run(check: Callable) -> void:
	check.call(FeedbackStyle.hit_seconds >= 1.5 and FeedbackStyle.attack_seconds >= 1.5,
		"Normal enemy hit and attack phases each preserve the owner's minimum 1.5-second reading time.")
	var source: Dictionary = Loader.load_setup().setup
	var game := Combat.new(_setup(source))
	check.call(_pair(game), "Animation fixture builds a valid production circuit with real owned cards and stock.")
	game.place_rune(8, _uid(game, "shield"))
	game.play_technique(_uid(game, "conjure"))
	game.place_rune(5, _uid(game, "free_spark"))
	game.play_technique(_uid(game, "conjure"))
	var result := game.execute("cast")
	_exercise(check, game, result, "Cast with permanent, temporary and connector cleanup")
	check.call(result.events[0].spell.active.size() > 2 and result.after.board.filter(func(piece): return not piece.is_empty()).size() == 2,
		"Traversal retains the detached active circuit after the authoritative board has already cleared.")

	game = Combat.new(_setup(source))
	_pair(game, "shield")
	result = game.execute("cast")
	_exercise(check, game, result, "Zero-damage shield Cast and fully blocked retaliation")
	check.call(result.events[1].applied == 0 and result.events[3].applied == 0 and result.events[3].blocked == 8,
		"Shield animation fixture represents zero applied HP loss on both combatants.")

	game = Combat.new(_setup(source))
	result = game.execute("pass")
	_exercise(check, game, result, "Pass with an incomplete circuit")
	check.call(not _types(result).has("cast") and not _types(result).has("damage") and not _types(result).has("shield"),
		"Pass presentation receives no synthetic spell, payment, enemy damage or player shield.")
	game = Combat.new(_setup(source, []))
	_exercise(check, game, game.execute("pass"), "Pass with an empty hand")

	game = Combat.new(_setup(source))
	_exercise(check, game, game.execute("technique", {"uid": _uid(game, "conjure")}), "Conjure actual generated card")
	game = Combat.new(_setup(source, ["focus"]))
	result = game.execute("technique", {"uid": _uid(game, "focus")})
	_exercise(check, game, result, "Focus actual reshuffle and short draw")
	check.call(_types(result) == ["technique", "reshuffled", "card_drawn"],
		"Short-draw presentation cannot invent a second card when Focus only recycles itself.")

	for outcome in ["victory", "defeat"]:
		game = Combat.new(_setup(source))
		_pair(game)
		if outcome == "victory": game.enemy_hp = 7
		else: game.player_hp = 1
		result = game.execute("cast")
		_exercise(check, game, result, "Terminal " + outcome)
		check.call(_types(result).back() == "battle_ended" and not _types(result).has("turn_started") and not _types(result).has("card_drawn"),
			"Animated %s has stable terminal state with no next-turn geometry or card animation." % outcome)
		if outcome == "victory":
			check.call(result.events[1].amount == 12 and result.events[1].applied == 7 and not _types(result).has("retaliation"),
				"Lethal presentation distinguishes requested damage from actual HP loss and suppresses retaliation.")
	_controller_lifecycle(check, source)
	_signal_reentry(check, source)
	_transition(check)

func _setup(source: Dictionary, cards: Array = ["spark", "shield", "conjure", "conjure"]) -> Dictionary:
	var setup := source.duplicate(true)
	setup.erase("next_encounter")
	setup.owned_cards = cards.duplicate()
	setup.opening_hand = []
	setup.opening_draw = cards.size()
	setup.encounter.player_health = 1000
	setup.encounter.player_max_health = 1000
	setup.encounter.max_health = 1000
	setup.encounter.intents = [8]
	setup.encounter.energy_per_turn = 6
	return setup

func _uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id: return int(card.uid)
	return -1

func _pair(game: Combat, rune_id: String = "spark") -> bool:
	game.board = Circuit.empty_board()
	var prepared := game.place_rune(1, _uid(game, rune_id))
	for placement in [[2, "split", 0], [3, "corner", 0], [6, "straight", 1], [7, "straight", 1], [10, "join", 0], [11, "corner", 1]]:
		prepared = game.place_wire(placement[0], placement[1]) and prepared
		for quarter in range(placement[2]): prepared = game.rotate(placement[0]) and prepared
	return prepared and game.forecast().valid

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _state(game: Combat) -> Dictionary:
	return {"snapshot": game.snapshot(), "rng": [game.rng.state, game.endpoint_rng.state, game.kit_rng.state],
		"uid": game.next_uid, "history": game.history.duplicate(true)}

func _capture(presenter: Animated, events: Array, snapshots: Array) -> Callable:
	# A weak presenter reference also checks that retaining diagnostic listeners
	# does not create a reference cycle or keep cancelled adapters alive.
	var owner: WeakRef = weakref(presenter)
	return func(event: Dictionary):
		events.append(event.duplicate(true))
		var active = owner.get_ref()
		if active != null: snapshots.append(active.visual_snapshot())

func _exercise(check: Callable, game: Combat, result: Dictionary, label: String) -> void:
	check.call(result.accepted, label + " supplies an accepted authoritative action.")
	if not result.accepted: return
	var authoritative := _state(game)
	var normal_events: Array = []
	var normal_states: Array = []
	for reduced in [false, true]:
		var presenter := Animated.new()
		presenter.reduced_motion = reduced
		var events: Array = []
		var snapshots: Array = []
		presenter.event_presented.connect(_capture(presenter, events, snapshots))
		var completions := [0]
		var input := result.duplicate(true)
		presenter.present(input, func(): completions[0] += 1)
		input.before.board.clear()
		input.after.hand.clear()
		input.events.clear()
		var detached := presenter.visual_snapshot()
		if detached.has("board"): detached.board.clear()
		presenter.finish()
		presenter.finish()
		presenter.advance(100.0)
		check.call(events == result.events and snapshots.size() == events.size(), label + " presents detached events exactly once in emitted order (reduced=%s)." % reduced)
		check.call(completions[0] == 1 and not presenter.is_active() and presenter.visual_snapshot() == result.after,
			label + " reaches the exact final snapshot and completes once (reduced=%s)." % reduced)
		check.call(_state(game) == authoritative, label + " never rewrites gameplay, permanent ownership, UID allocation, history or any RNG stream.")
		if snapshots.size() == events.size():
			_assert_stages(check, result, events, snapshots, label)
		if reduced:
			check.call(events == normal_events and snapshots == normal_states, label + " reduced motion preserves every event and intermediate visual value.")
		else:
			normal_events = events.duplicate(true)
			normal_states = snapshots.duplicate(true)
		var count := events.size()
		presenter.present(result.duplicate(true), Callable())
		presenter.finish()
		check.call(events.size() == count and _state(game) == authoritative, label + " rejects duplicate action playback by its existing identity.")
		presenter.cancel()
	_sequential_timing(check, result, label)

func _sequential_timing(check: Callable, result: Dictionary, label: String) -> void:
	# Observe the public clock/signals instead of inspecting the scheduler's
	# private steps. In particular, more cards/cells must not divide each one's
	# configured reading time into an imperceptible fraction of a frame.
	for reduced in [false, true]:
		var presenter := Animated.new()
		presenter.reduced_motion = reduced
		var commitments: Array = []
		var completions := [0]
		var owner: WeakRef = weakref(presenter)
		presenter.event_presented.connect(func(event):
			var active = owner.get_ref()
			commitments.append({"sequence": event.sequence, "elapsed": active.elapsed, "progress": active.phase_progress, "phase": active.phase})
		)
		presenter.present(result, func(): completions[0] += 1)
		var boundaries := 0
		var held_until_complete := true
		while presenter.is_active() and boundaries <= result.events.size():
			# Structural events may commit together at the same timestamp; they
			# must not steal time from the next nonzero animation.
			presenter.advance(0.0)
			if not presenter.is_active(): break
			var index := commitments.size()
			var event: Dictionary = result.events[index]
			var seconds := _expected_seconds(event, reduced)
			if seconds <= 0.0:
				held_until_complete = false
				break
			var before := presenter.visual_snapshot()
			var phase := presenter.phase
			var epsilon := minf(0.001, seconds * 0.01)
			presenter.advance(seconds * 0.5)
			held_until_complete = held_until_complete and commitments.size() == index and presenter.phase == phase and presenter.phase_progress < 1.0 and presenter.visual_snapshot() == before
			presenter.advance(seconds * 0.5 - epsilon)
			held_until_complete = held_until_complete and commitments.size() == index and presenter.phase == phase and presenter.visual_snapshot() == before and completions[0] == 0
			presenter.advance(epsilon)
			held_until_complete = held_until_complete and commitments.size() > index
			boundaries += 1
		check.call(held_until_complete and not presenter.is_active() and completions[0] == 1,
			label + " holds each visual phase and its values until that animation finishes before starting the next (reduced=%s)." % reduced)
		var elapsed_expected := 0.0
		var intervals_match: bool = commitments.size() == result.events.size()
		for index in range(mini(commitments.size(), result.events.size())):
			elapsed_expected += _expected_seconds(result.events[index], reduced)
			intervals_match = intervals_match and is_equal_approx(float(commitments[index].elapsed), elapsed_expected) and is_equal_approx(float(commitments[index].progress), 1.0)
			intervals_match = intervals_match and commitments[index].sequence == index and commitments[index].phase == result.events[index].type
		check.call(intervals_match and is_equal_approx(presenter.duration, elapsed_expected),
			label + " gives each cleanup/card event its full configured duration and commits all phases in sequence (reduced=%s)." % reduced)
		presenter.cancel()

func _expected_seconds(event: Dictionary, reduced: bool) -> float:
	# This is the user-facing timing contract from the editable style, independent
	# of the implementation's choice of scheduler or number of queued events.
	var timing_keys := {"cast": "traversal_seconds", "damage": "hit_seconds", "shield": "shield_seconds",
		"retaliation": "attack_seconds", "technique": "technique_seconds", "effect_consumed": "cleanup_seconds",
		"temporary_expired": "cleanup_seconds", "board_piece_cleared": "cleanup_seconds", "turn_cleanup": "cleanup_seconds",
		"reshuffled": "cards_seconds", "card_drawn": "draw_seconds", "card_created": "draw_seconds",
		"battle_ended": "terminal_seconds", "encounter_transition": "cards_seconds"}
	var seconds := 0.0
	if event.type == "turn_cleanup":
		var per_card: float = minf(FeedbackStyle.cleanup_seconds, FeedbackStyle.reduced_seconds) if reduced else FeedbackStyle.cleanup_seconds
		return per_card * float(event.discarded.size() + event.expired.size())
	if timing_keys.has(event.type): seconds = float(FeedbackStyle.get(timing_keys[event.type]))
	if event.type == "shield" and int(event.amount) <= 0: seconds = 0.0
	return minf(seconds, FeedbackStyle.reduced_seconds) if reduced else seconds

func _assert_stages(check: Callable, result: Dictionary, events: Array, snapshots: Array, label: String) -> void:
	var previous: Dictionary = result.before
	for index in range(events.size()):
		var event: Dictionary = events[index]
		var stage: Dictionary = snapshots[index]
		var valid := true
		match event.type:
			"cast": valid = stage.energy == event.energy_after and stage.enemy_hp == previous.enemy_hp and stage.board == previous.board
			"damage": valid = stage.enemy_hp == event.health_after and stage.player_hp == previous.player_hp
			"shield": valid = stage.enemy_hp == previous.enemy_hp and stage.player_hp == previous.player_hp
			"passed": valid = stage.energy == previous.energy and stage.enemy_hp == previous.enemy_hp and stage.hand == previous.hand
			"retaliation": valid = stage.player_hp == event.health_after and stage.enemy_hp == previous.enemy_hp
			"effect_consumed": valid = stage.board[event.cell] == event.after and stage.discard_pile.has(event.card)
			"temporary_expired", "board_piece_cleared": valid = stage.board[event.cell] == event.after and stage.draw_pile == previous.draw_pile
			"turn_cleanup": valid = stage.hand == event.hand_after and stage.undo_count == 0 and event.discarded.all(func(card): return stage.discard_pile.has(card))
			"turn_started": valid = stage.turn == event.turn_after and stage.energy == event.energy_after and stage.intent == event.intent
			"endpoints_changed":
				valid = stage.board[event.after.begin.cell].get("kind") == "begin" and stage.board[event.after.end.cell].get("kind") == "end" and stage.hand == previous.hand
			"kit_changed": valid = stage.kit == event.after and stage.stock == event.after.totals
			"reshuffled": valid = stage.draw_pile == event.cards and stage.discard_pile.is_empty() and stage.hand == previous.hand
			"card_drawn": valid = stage.hand.back() == event.card and stage.hand.size() == event.hand_size and stage.draw_pile.size() == event.draw_remaining
			"technique": valid = stage.energy == event.energy_after and not stage.hand.has(event.card) and stage.discard_pile.has(event.card) and stage.undo_count == 0
			"card_created": valid = stage.hand.back() == event.card and stage.draw_pile == previous.draw_pile and stage.discard_pile == previous.discard_pile
			"battle_ended": valid = stage.state == event.state and stage.player_hp == event.player_hp and stage.enemy_hp == event.enemy_hp
		check.call(valid, "%s stages event %d (%s) from its actual payload before later effects." % [label, index, event.type])
		previous = stage

func _controller_lifecycle(check: Callable, source: Dictionary) -> void:
	var game := Combat.new(_setup(source))
	_pair(game)
	var presenter := Animated.new()
	var controller := Controller.new(game, presenter)
	var before := controller.snapshot()
	var changed_states: Array = []
	var weak_controller: WeakRef = weakref(controller)
	controller.changed.connect(func():
		var active = weak_controller.get_ref()
		if active != null: changed_states.append(active.display_snapshot())
	)
	check.call(controller.command("cast") and controller.is_busy(), "Real animation adapter retains the controller's accepted-action guard.")
	check.call(not changed_states.is_empty() and changed_states[0] == before, "The first controller refresh stages before-state instead of exposing final HP, board and hand then rolling backward.")
	presenter._tick(5.0)
	check.call(presenter.is_active() and presenter.phase == "cast" and presenter.event_trace.is_empty()
		and presenter.elapsed > 0.0 and presenter.elapsed <= Animated.MAX_AUTOMATIC_DELTA and presenter.visual_snapshot() == before,
		"A five-second automatic frame hitch advances only the capped visual interval without skipping Cast, applying hit feedback or committing later cards.")
	var authoritative := _state(game)
	var rejected := true
	for command in ["cast", "pass", "undo", "rotate", "place_wire", "technique"]:
		rejected = not controller.command(command, {"index": 1, "kind": "erase", "uid": 0}) and rejected
	check.call(rejected and _state(game) == authoritative, "Rapid/double gameplay input cannot bypass an active production animation.")
	presenter.finish()
	check.call(not controller.is_busy() and controller.display_snapshot() == controller.snapshot(), "Production completion unlocks only after its exact final staged snapshot.")

	# Cancel separately during traversal, damage, enemy action, cleanup and draw.
	for phase in ["cast", "damage", "retaliation", "effect_consumed", "card_drawn"]:
		game = Combat.new(_setup(source))
		_pair(game)
		presenter = Animated.new()
		controller = Controller.new(game, presenter)
		var visited: Array = []
		presenter.event_presented.connect(func(event): visited.append(event.type))
		controller.command("cast")
		var ticks := 0
		while presenter.phase != phase and presenter.is_active() and ticks < 10000:
			presenter.advance(0.001)
			ticks += 1
		presenter.advance(0.001)
		check.call(presenter.phase == phase, "Deterministic advancement reaches cancellation inside phase " + phase + ".")
		authoritative = _state(game)
		controller.cancel_presentation()
		var cancelled_visual := presenter.visual_snapshot()
		var events_after := visited.size()
		presenter.advance(100.0)
		presenter.finish()
		check.call(not presenter.is_active() and not controller.is_busy() and presenter.visual_snapshot() == cancelled_visual and visited.size() == events_after and _state(game) == authoritative,
			"Cancellation during %s stops owned work and all late visual/gameplay writes." % phase)
		controller.command("pass")
		check.call(controller.is_busy(), "A newer action can run after cancelling " + phase + ".")
		presenter.finish()
		check.call(not controller.is_busy(), "Only the newer action completes after cancelling " + phase + ".")
		controller.dispose()

	game = Combat.new(_setup(source))
	presenter = Animated.new()
	controller = Controller.new(game, presenter)
	controller.command("pass")
	controller.restart()
	var restarted := controller.snapshot()
	presenter.advance(100.0)
	check.call(not presenter.is_active() and not controller.is_busy() and controller.snapshot() == restarted and restarted.turn == 1,
		"Restart cancels production animation before resetting; deterministic late advancement cannot change the new generation.")
	controller.command("pass")
	authoritative = _state(game)
	controller.dispose()
	presenter.finish()
	check.call(not controller.can_edit() and not controller.is_busy() and not presenter.is_active() and _state(game) == authoritative,
		"Disposal closes production animation and cannot reapply a resolved action.")
	var weak_presenter: WeakRef = weakref(presenter)
	controller = null
	presenter = null
	check.call(weak_presenter.get_ref() == null, "Disposed production adapter releases retained completion and controller references.")

func _transition(check: Callable) -> void:
	var source: Dictionary = Loader.load_setup("res://data/production_transition_encounter.json").setup
	var game := Combat.new(source)
	# This narrow fixture sets terminal health before a legitimate command, as
	# existing transition tests do; presentation itself never sets game state.
	game.state = "victory"
	game.enemy_hp = 0
	var result := game.execute("next_encounter")
	_exercise(check, game, result, "Configured encounter replacement")

func _signal_reentry(check: Callable, source: Dictionary) -> void:
	var game := Combat.new(_setup(source))
	var first := game.execute("pass")
	var second := game.execute("pass")
	var presenter := Animated.new()
	var completions := [0]
	var updates := [0]
	var owner: WeakRef = weakref(presenter)
	presenter.visual_changed.connect(func(_snapshot):
		updates[0] += 1
		owner.get_ref().cancel()
	)
	presenter.present(first, func(): completions[0] += 1)
	presenter.finish()
	check.call(updates[0] == 1 and completions[0] == 0 and not presenter.is_active() and presenter.event_trace.is_empty(),
		"Cancellation reentered from the initial visual signal prevents all later event samples and completion.")
	presenter = Animated.new()
	owner = weakref(presenter)
	var replaced := [false]
	var old_completion := [0]
	var new_completion := [0]
	var events: Array = []
	presenter.event_presented.connect(func(event):
		events.append(event.duplicate(true))
		if not replaced[0]:
			replaced[0] = true
			owner.get_ref().present(second, func(): new_completion[0] += 1)
	)
	presenter.present(first, func(): old_completion[0] += 1)
	presenter.finish()
	check.call(presenter.is_active() and old_completion[0] == 0 and events.size() == 1 and presenter.visual_snapshot() == second.before,
		"Replacement reentered from an event signal stops the old advance loop before sampling the newer sequence.")
	presenter.finish()
	check.call(new_completion[0] == 1 and old_completion[0] == 0 and presenter.visual_snapshot() == second.after and events.slice(1) == second.events,
		"A reentrant replacement preserves its own order and exactly-once completion without the obsolete callback.")
	game = Combat.new(_setup(source))
	presenter = Animated.new()
	var controller := Controller.new(game, presenter)
	var controller_owner: WeakRef = weakref(controller)
	var restart_once := [false]
	presenter.event_presented.connect(func(_event):
		if not restart_once[0]:
			restart_once[0] = true
			controller_owner.get_ref().restart()
	)
	controller.command("pass")
	presenter.finish()
	var restarted := controller.snapshot()
	presenter.advance(100.0)
	check.call(restart_once[0] and not presenter.is_active() and not controller.is_busy() and restarted.turn == 1 and controller.snapshot() == restarted,
		"Controller Restart reentered during an event invalidates the sequence before any obsolete completion or subsequent event.")
	controller.dispose()
