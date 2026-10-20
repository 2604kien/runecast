extends RefCounted
## Actual playable scene coverage. Each sequence advances explicitly; frame
## awaits below allow only scene/layout/teardown processing, never timing sleeps.
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const ProductionUI = preload("res://tests/ui_production_tests.gd")

func run(check: Callable, tree: SceneTree) -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(scene)
	await tree.process_frame
	var presenter: Animated = scene.controller.get_presenter() as Animated
	check.call(presenter != null and scene.game.has("production"), "The ordinary playable Combat scene installs the production animation adapter by default.")
	if presenter == null:
		scene.queue_free()
		await tree.process_frame
		return
	presenter.automatic_timing = false
	var helper := ProductionUI.new()
	check.call(helper._build(scene, true), "Production animation integration builds a positive-damage Cast through real controls.")
	var phase_boundaries: Array = []
	var presenter_owner: WeakRef = weakref(presenter)
	presenter.event_presented.connect(func(event):
		var active = presenter_owner.get_ref()
		var feedback = active._overlay.get_ref()
		var view = active._view.get_ref()
		phase_boundaries.append({"event": event.sequence, "overlay_clear": feedback._event.is_empty(),
			"lights_clear": view.cells.all(func(cell): return is_zero_approx(cell.feedback_light)),
			"idle_stopped": not view.arena.actor.is_processing(), "neutral": view.arena.actor.get_pose() == &"neutral"})
	)
	var before: Dictionary = scene.controller.snapshot()
	var sound_before: bool = scene.sound_enabled
	scene._cast()
	var after: Dictionary = scene.controller.snapshot()
	check.call(scene.controller.is_busy() and presenter.is_active() and scene.game == before and scene.game != after,
		"Accepted real-scene Cast resolves authoritative gameplay while the visible HP, hand and board remain at the before-state.")
	check.call(scene.cast_button.disabled and scene.turn_pass_button.disabled and scene.cells[3].disabled,
		"The real animated scene disables gameplay for the complete ordered presentation.")
	var elapsed_before := presenter.elapsed
	scene._cast()
	scene._pass()
	scene._select_tool("erase")
	scene.cells[3].pressed.emit()
	check.call(scene.controller.snapshot() == after and presenter.elapsed == elapsed_before,
		"Repeated real UI actions cannot resolve or restart a pending animated action.")
	var old_board: Array = before.board.duplicate(true)
	_advance_to(presenter, "damage")
	check.call(presenter.phase == "damage" and scene.game.board == old_board and scene.game.enemy_hp == before.enemy_hp,
		"Actual cast traversal precedes the HP update and preserves the uncleared circuit on screen.")
	var overlay = presenter._overlay.get_ref()
	check.call(overlay._event.type == "damage" and overlay._event.sequence == 1 and is_zero_approx(presenter.phase_progress),
		"The real overlay starts the damage phase at zero progress with no retained Cast traversal event.")
	presenter.finish()
	check.call(not phase_boundaries.is_empty() and phase_boundaries.all(func(boundary): return boundary.overlay_clear and boundary.lights_clear and boundary.idle_stopped and boundary.neutral),
		"Each real visual phase clears its transient overlay and actor reaction before its commit signal and the next phase.")
	check.call(not scene.controller.is_busy() and scene.game == after and scene.stat_values.health.text == "%d/%d" % [after.player_hp, after.player_max_hp]
		and scene.pile_values.draw_pile.text == str(after.draw_pile.size()) and scene.hand_count.text == "Hand %d" % after.hand.size(),
		"Completed real animation binds final health, actual hand, piles and rebuilt board to the accepted result.")
	check.call(scene.arena.actor.get_pose() == &"neutral" and scene.arena.actor.pose_sprite.region_enabled and scene.arena.actor.pose_sprite.material != null,
		"Normal real-scene completion restores the approved masked atlas neutral after full-texture poses.")
	check.call(is_instance_valid(overlay) and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"The reusable combat feedback overlay never intercepts gameplay or navigation input.")

	# Production scene setting is a view preference and must not alter audio.
	scene.set_reduced_motion(true)
	check.call(presenter.reduced_motion and scene.sound_enabled == sound_before, "Reduced motion connects to the production presenter without muting existing audio.")
	before = scene.controller.snapshot()
	scene._pass()
	after = scene.controller.snapshot()
	presenter.finish()
	check.call(scene.game == after and after.turn == before.turn + 1 and scene.arena.actor.pose_root.transform == Transform2D.IDENTITY,
		"Reduced-motion Pass settles the actual scene with identical gameplay and no residual actor movement.")
	scene.set_reduced_motion(false)

	# Restart inside an actor/traversal phase must restore all presentation state.
	scene._exact_replay()
	presenter = scene.controller.get_presenter()
	presenter.automatic_timing = false
	helper._build(scene, true)
	scene._cast()
	_advance_to(presenter, "retaliation")
	presenter.advance(0.08)
	scene._restart()
	var restarted: Dictionary = scene.controller.snapshot()
	presenter.finish()
	check.call(not presenter.is_active() and not scene.controller.is_busy() and scene.game == restarted and restarted.turn == 1,
		"Restart from an actual enemy animation cancels it and restores a fresh playable scene without late writes.")
	check.call(scene.arena.actor.get_pose() == &"neutral" and scene.arena.actor.pose_sprite.region_enabled and scene.arena.actor.pose_sprite.modulate == Color.WHITE,
		"Restart restores neutral pose, atlas region/mask and tint in the live arena.")

	# Exact replay owns a fresh adapter/controller; an old adapter cannot unlock it.
	scene._pass()
	var old_presenter: Animated = presenter
	var old_controller = scene.controller
	scene._exact_replay()
	presenter = scene.controller.get_presenter()
	presenter.automatic_timing = false
	scene._pass()
	after = scene.controller.snapshot()
	old_presenter.finish()
	old_presenter.advance(100.0)
	check.call(scene.controller != old_controller and presenter != old_presenter and scene.controller.is_busy() and scene.controller.snapshot() == after and not old_controller.can_edit(),
		"Old production playback cannot unlock or modify a newer action after Exact replay replaces the controller.")
	presenter.finish()

	# Terminal fixtures change only initial HP before a legitimate scene command.
	for outcome in ["victory", "defeat"]:
		scene._exact_replay()
		presenter = scene.controller.get_presenter()
		presenter.automatic_timing = false
		if outcome == "victory":
			scene.controller._combat.enemy_hp = 1
			scene._refresh()
			helper._build(scene, true)
			scene._cast()
		else:
			scene.controller._combat.player_hp = 1
			scene._refresh()
			scene._pass()
		after = scene.controller.snapshot()
		presenter.finish()
		presenter.advance(100.0)
		check.call(scene.game == after and scene.game.state == outcome and scene.cast_button.disabled and scene.turn_pass_button.disabled and not scene.arena.actor.is_processing(),
			"The actual %s outcome remains stable, terminal and free from automatic idle/next-turn work." % outcome)

	# Verify the actual overlay _process -> tick -> adapter path as well as
	# deterministic seeking. Bound frames and restore the test's FPS cap.
	scene._exact_replay()
	presenter = scene.controller.get_presenter()
	var prior_max_fps := Engine.max_fps
	Engine.max_fps = 240
	scene._pass()
	var maximum_frames := maxi(600, ceili(presenter.duration * float(Engine.max_fps) * 2.0))
	for frame in range(maximum_frames):
		if not scene.controller.is_busy(): break
		await tree.process_frame
	Engine.max_fps = prior_max_fps
	check.call(not scene.controller.is_busy() and not presenter.is_active() and presenter.elapsed > 0.0 and scene.game == scene.controller.snapshot(),
		"Actual automatic frame ticking completes a playable action without tests calling advance or finish.")
	scene._exact_replay()
	presenter = scene.controller.get_presenter()
	presenter.automatic_timing = false
	scene._pass()
	var closed_controller = scene.controller
	var at_exit: Dictionary = closed_controller.snapshot()
	scene.audio.dispose()
	scene.queue_free()
	await tree.process_frame
	presenter.finish()
	presenter.advance(100.0)
	check.call(not presenter.is_active() and not closed_controller.can_edit() and closed_controller.snapshot() == at_exit and not closed_controller.command("pass"),
		"Actual scene teardown stops owned effects and leaves no live view callbacks or editable old controller.")
	check.call(presenter._view == null and presenter._overlay == null, "Scene teardown releases the production adapter's obsolete node references.")

func _advance_to(presenter: Animated, phase: String) -> void:
	var ticks := 0
	while presenter.is_active() and presenter.phase != phase and ticks < 10000:
		presenter.advance(0.001)
		ticks += 1

