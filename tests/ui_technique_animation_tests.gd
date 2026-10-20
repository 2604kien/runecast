extends RefCounted
## Observe the real played UID's live card, including UI rebuild/cancel paths.
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
	var seed_with_focus := -1
	for seed_value in range(128):
		var candidate := Combat.new(setup, seed_value)
		if candidate.hand.any(func(card): return card.id == "focus"):
			seed_with_focus = seed_value
			break
	check.call(seed_with_focus >= 0, "Technique animation fixture finds a natural production opening with a real paid Focus card.")
	if seed_with_focus < 0:
		scene.queue_free()
		await tree.process_frame
		return
	ProductionUI.new()._inject(scene, setup, seed_with_focus)
	scene._install_animation_presenter()
	for mode in ["finish", "reduced", "cancel", "restart", "refresh"]:
		scene._exact_replay()
		scene.set_reduced_motion(mode == "reduced")
		var presenter: Animated = scene.controller.get_presenter()
		presenter.automatic_timing = false
		await tree.process_frame
		await tree.process_frame
		var uid := -1
		for card in scene.game.hand:
			if card.id == "focus":
				uid = int(card.uid)
				break
		var before: Dictionary = scene.controller.snapshot()
		var baselines := _hand_visuals(scene)
		_card(scene, uid).pressed.emit()
		var authoritative: Dictionary = scene.controller.snapshot()
		await tree.process_frame
		await tree.process_frame
		var seconds: float = minf(Style.technique_seconds, Style.reduced_seconds) if mode == "reduced" else Style.technique_seconds
		presenter.advance(seconds * 0.6)
		var target := _card(scene, uid)
		check.call(presenter.phase == "technique" and scene.controller.is_busy() and scene.game == before
			and scene.controller.snapshot() == authoritative and authoritative.energy == before.energy - 1,
			"%s technique animation retains the displayed card/payment until phase completion while gameplay has already resolved once." % mode)
		var played_visual := _visual(target)
		var other_cards_unchanged := true
		for other in scene.hand_box.get_children():
			var other_uid := int(other.get_meta("uid", -1))
			if other_uid != uid: other_cards_unchanged = other_cards_unchanged and _visual(other) == baselines[other_uid]
		check.call(played_visual.modulate.a < baselines[uid].modulate.a and played_visual.modulate.r > baselines[uid].modulate.r
			and other_cards_unchanged and played_visual.position == baselines[uid].position,
			"%s animates brightness/opacity on only the actual played UID; other hand cards and card position stay unchanged." % mode)
		if mode == "reduced":
			check.call(played_visual.scale == baselines[uid].scale and played_visual.pivot == baselines[uid].pivot
				and seconds <= 0.1 and seconds < Style.technique_seconds,
				"Reduced-motion technique feedback stays stationary without scale/pivot movement and keeps its brief phase.")
		else:
			check.call(played_visual.scale.x < baselines[uid].scale.x and played_visual.scale.y < baselines[uid].scale.y,
				"%s technique visibly shrinks the actual card around its center before discarding it." % mode)
		if mode == "refresh":
			var old_card: WeakRef = weakref(target)
			scene._refresh()
			await tree.process_frame
			await tree.process_frame
			presenter.advance(seconds * 0.05)
			target = _card(scene, uid)
			check.call(old_card.get_ref() == null and target.modulate.a < 1.0 and target.scale.x < 1.0
				and scene.game.hand == before.hand and scene.game.energy == before.energy,
				"A mid-technique UI rebuild frees the obsolete card and resumes animation on the current control with the same UID.")
		if mode == "cancel":
			scene.controller.cancel_presentation()
		elif mode == "restart":
			scene._restart()
		else:
			presenter.advance(seconds * (0.35 if mode == "refresh" else 0.4))
			check.call(scene.game.energy == authoritative.energy and not scene.game.hand.any(func(card): return int(card.uid) == uid)
				and not presenter.event_trace.is_empty() and presenter.event_trace[0].type == "technique",
				"%s technique commits its displayed payment/discard only after the complete card animation and before the draw phase." % mode)
			presenter.finish()
		check.call(not presenter.is_active() and not scene.controller.is_busy() and _cards_clean(scene)
			and (not is_instance_valid(target) or _visual(target) == baselines[uid]),
			"%s restores the played card's original scale, pivot and tint and leaves no transformed live hand controls." % mode)
		var settled: Dictionary = scene.controller.snapshot()
		presenter.advance(100.0)
		presenter.finish()
		check.call(scene.controller.snapshot() == settled and scene.game == settled and _cards_clean(scene),
			"%s ignores late advancement after technique completion/cancellation/restart." % mode)
	scene.audio.dispose()
	scene.queue_free()
	await tree.process_frame

func _card(scene: Control, uid: int) -> Control:
	for child in scene.hand_box.get_children():
		if int(child.get_meta("uid", -1)) == uid: return child
	return null

func _visual(card: Control) -> Dictionary:
	return {"position": card.position, "scale": card.scale, "pivot": card.pivot_offset,
		"modulate": card.modulate, "self_modulate": card.self_modulate, "rotation": card.rotation, "z_index": card.z_index}

func _hand_visuals(scene: Control) -> Dictionary:
	var visuals := {}
	for card in scene.hand_box.get_children(): visuals[int(card.get_meta("uid", -1))] = _visual(card)
	return visuals

func _cards_clean(scene: Control) -> bool:
	for card in scene.hand_box.get_children():
		if card.scale != Vector2.ONE or card.pivot_offset != Vector2.ZERO or card.modulate != Color.WHITE or card.self_modulate != Color.WHITE or not is_zero_approx(card.rotation):
			return false
	return true
