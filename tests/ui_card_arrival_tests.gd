extends RefCounted
## Real event cards fade individually without moving the staged hand or layout.
const Combat = preload("res://scripts/core/combat.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const ProductionUI = preload("res://tests/ui_production_tests.gd")
const Style = preload("res://scenes/vfx/combat_feedback_style.tres")

func run(check: Callable, tree: SceneTree) -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	var setup: Dictionary = scene.initial_setup.duplicate(true)
	for scenario in ["focus", "empty_turn", "created", "reduced"]:
		var source := setup.duplicate(true)
		var card_id := "conjure" if scenario == "created" else "focus"
		if scenario == "empty_turn": source.opening_draw = 0
		var seed_value := _seed_with_card(source, card_id) if scenario != "empty_turn" else 0
		check.call(seed_value >= 0, "%s arrival fixture uses real production cards and ordered model events." % scenario)
		if seed_value < 0: continue
		var presenter := _prepare(scene, source, seed_value, scenario == "reduced")
		await tree.process_frame
		await tree.process_frame
		var lane := _lane(scene)
		check.call(_fixed_lane(scene), "%s hand reserves exactly 146 pixels before any incoming card, including an empty hand." % scenario)
		var results: Array = []
		scene.controller.presentation_started.connect(func(result): results.append(result), CONNECT_ONE_SHOT)
		if scenario == "empty_turn": scene._pass()
		else: _card(scene, _uid(scene.game.hand, card_id)).pressed.emit()
		var authoritative: Dictionary = scene.controller.snapshot()
		var model_state := _model_state(scene)
		var arrivals: Array = results[0].events.filter(func(event): return event.type in ["card_drawn", "card_created"])
		var expected_count := 1 if scenario == "created" else (3 if scenario == "empty_turn" else 2)
		check.call(arrivals.size() == expected_count, "%s supplies exactly %d actual arrivals without invented cards." % [scenario, expected_count])
		for event in arrivals:
			_advance_to_event(presenter, int(event.sequence))
			var staged: Dictionary = scene.game.duplicate(true)
			var incoming: Control = _card(scene, int(event.card.uid))
			check.call(incoming != null and is_zero_approx(incoming.modulate.a) and incoming.disabled and incoming.get_meta("rc_incoming_card", false)
				and _arrivals_match(scene, event, staged) and not _has_uid(staged.hand, int(event.card.uid)),
				"%s arrival %d starts only its actual incoming UID at zero opacity, after every prior card has completed." % [scenario, event.sequence])
			if incoming == null: break
			var seconds: float = presenter._steps[presenter._index].seconds
			check.call(is_equal_approx(seconds, minf(Style.draw_seconds, Style.reduced_seconds) if scenario == "reduced" else Style.draw_seconds),
				"%s arrival %d receives its complete individual fade duration." % [scenario, event.sequence])
			await tree.process_frame
			await tree.process_frame
			var card_position := incoming.position
			var card_size := incoming.size
			for progress in [0.25, 0.5, 0.9]:
				presenter.advance(seconds * (progress - presenter.phase_progress))
				incoming = _card(scene, int(event.card.uid))
				check.call(incoming != null and incoming.modulate.a > 0.0 and incoming.modulate.a < 1.0
					and incoming.position == card_position and incoming.size == card_size and incoming.scale == Vector2.ONE
					and incoming.pivot_offset == Vector2.ZERO and _arrivals_match(scene, event, staged)
					and scene.game == staged and _model_state(scene) == model_state and _staged_counts(scene, staged),
					"%s arrival %d at %.0f%% fades only its incoming card while earlier cards, future UIDs, staged counts and resolved gameplay stay correct." % [scenario, event.sequence, progress * 100.0])
				if progress == 0.5:
					var midpoint_alpha := incoming.modulate.a
					var old_card: WeakRef = weakref(incoming)
					scene._refresh()
					incoming = _card(scene, int(event.card.uid))
					check.call(incoming != null and is_equal_approx(incoming.modulate.a, midpoint_alpha),
						"%s arrival %d reapplies its partial opacity synchronously during UI refresh, without a fully visible frame." % [scenario, event.sequence])
					await tree.process_frame
					await tree.process_frame
					check.call(old_card.get_ref() == null and incoming != null and is_equal_approx(incoming.modulate.a, midpoint_alpha)
						and _fixed_lane(scene) and _lane(scene) == lane,
						"%s arrival %d survives hand-control replacement with unchanged fade and fixed hand/forecast/scroll geometry." % [scenario, event.sequence])
			presenter.advance(seconds * (1.0 - presenter.phase_progress))
			var committed := _card(scene, int(event.card.uid))
			check.call(committed != null and committed.modulate == Color.WHITE and not committed.get_meta("rc_incoming_card", false) and _has_uid(scene.game.hand, int(event.card.uid))
				and _staged_counts(scene, scene.game),
				"%s arrival %d commits its fully visible actual card and counts only after the fade finishes." % [scenario, event.sequence])
		presenter.finish()
		await tree.process_frame
		await tree.process_frame
		check.call(not scene.controller.is_busy() and scene.game == authoritative and _clean_hand(scene) and _fixed_lane(scene)
			and _lane(scene) == lane and _model_state(scene) == model_state,
			"%s finishes with exactly the authoritative hand, opaque cards and unchanged 146-pixel lane." % scenario)
	for mode in ["cancel", "restart", "replay"]:
		await _interruption(scene, setup, mode, check, tree)
	scene.audio.dispose()
	scene.queue_free()
	await tree.process_frame

func _interruption(scene: Control, setup: Dictionary, mode: String, check: Callable, tree: SceneTree) -> void:
	var presenter := _prepare(scene, setup, _seed_with_card(setup, "focus"), false)
	var results: Array = []
	scene.controller.presentation_started.connect(func(result): results.append(result), CONNECT_ONE_SHOT)
	_card(scene, _uid(scene.game.hand, "focus")).pressed.emit()
	var event: Dictionary = results[0].events.filter(func(item): return item.type == "card_drawn")[0]
	_advance_to_event(presenter, int(event.sequence))
	presenter.advance(Style.draw_seconds * 0.5)
	var preview: Control = _card(scene, int(event.card.uid))
	check.call(preview != null and preview.modulate.a > 0.0 and preview.modulate.a < 1.0,
		"%s interrupts an actual partially visible incoming card." % mode)
	if mode == "cancel": scene.controller.cancel_presentation()
	elif mode == "restart": scene._restart()
	else: scene._exact_replay()
	var settled: Dictionary = scene.controller.snapshot()
	await tree.process_frame
	await tree.process_frame
	check.call(not presenter.is_active() and not scene.controller.is_busy() and scene.game == settled and _clean_hand(scene) and _fixed_lane(scene),
		"%s removes the obsolete arrival preview and restores only the current fully opaque hand." % mode)
	presenter.advance(100.0)
	presenter.finish()
	check.call(scene.controller.snapshot() == settled and scene.game == settled and _clean_hand(scene),
		"%s rejects late arrival writes from the previous sequence." % mode)

func _prepare(scene: Control, setup: Dictionary, seed_value: int, reduced: bool) -> Animated:
	ProductionUI.new()._inject(scene, setup, seed_value)
	scene._install_animation_presenter()
	scene.set_reduced_motion(reduced)
	var presenter: Animated = scene.controller.get_presenter()
	presenter.automatic_timing = false
	return presenter

func _seed_with_card(setup: Dictionary, id: String) -> int:
	for seed_value in range(128):
		if _uid(Combat.new(setup, seed_value).hand, id) >= 0: return seed_value
	return -1

func _uid(cards: Array, id: String) -> int:
	for card in cards:
		if card.id == id: return int(card.uid)
	return -1

func _has_uid(cards: Array, uid: int) -> bool:
	return cards.any(func(card): return int(card.uid) == uid)

func _card(scene: Control, uid: int) -> Control:
	for card in scene.hand_box.get_children():
		if int(card.get_meta("uid", -1)) == uid: return card
	return null

func _advance_to_event(presenter: Animated, sequence: int) -> void:
	for step in range(100):
		if not presenter.is_active() or int(presenter._steps[presenter._index].event.sequence) == sequence: return
		presenter.advance(maxf(0.0, presenter._steps[presenter._index].seconds - presenter._step_elapsed))

func _arrivals_match(scene: Control, event: Dictionary, staged: Dictionary) -> bool:
	var expected: Array = staged.hand.map(func(card): return int(card.uid))
	expected.append(int(event.card.uid))
	var actual: Array = []
	for card in scene.hand_box.get_children():
		var uid := int(card.get_meta("uid", -1))
		actual.append(uid)
		if uid != int(event.card.uid) and card.modulate != Color.WHITE: return false
	return actual == expected

func _clean_hand(scene: Control) -> bool:
	var expected: Array = scene.game.hand.map(func(card): return int(card.uid))
	var actual: Array = []
	for card in scene.hand_box.get_children():
		actual.append(int(card.get_meta("uid", -1)))
		if card.modulate != Color.WHITE or card.scale != Vector2.ONE or card.pivot_offset != Vector2.ZERO or card.get_meta("rc_incoming_card", false): return false
	return actual == expected

func _fixed_lane(scene: Control) -> bool:
	if not is_equal_approx(scene.hand_scroll.size.y, 146.0) or not is_equal_approx(scene.hand_row.size.y, 146.0): return false
	var lane_rect: Rect2 = scene.hand_scroll.get_global_rect()
	for card in scene.hand_box.get_children():
		var card_rect: Rect2 = card.get_global_rect()
		if card_rect.position.y < lane_rect.position.y - 0.01 or card_rect.end.y > lane_rect.end.y + 0.01: return false
	return true

func _lane(scene: Control) -> Array:
	return [scene.hand_row.position.y, scene.hand_row.size.y, scene.hand_scroll.size.y,
		scene.forecast_button.position.y, scene.cast_button.position.y, scene.page_scroll.scroll_vertical]

func _staged_counts(scene: Control, staged: Dictionary) -> bool:
	return scene.hand_count.text == "Hand %d" % staged.hand.size() and scene.pile_values.draw_pile.text == str(staged.draw_pile.size()) and scene.pile_values.discard_pile.text == str(staged.discard_pile.size())

func _model_state(scene: Control) -> Dictionary:
	var model = scene.controller._combat
	return {"snapshot": model.snapshot(), "rng": [model.rng.state, model.endpoint_rng.state, model.kit_rng.state],
		"uid": model.next_uid, "history": model.history.duplicate(true)}
