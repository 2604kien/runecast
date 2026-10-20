extends SceneTree
## RC-017 deterministic evidence from the ordinary playable Combat scene.
## Frames advance the production adapter explicitly; no timer/sleep proves motion.

const ProductionUI = preload("res://tests/ui_production_tests.gd")
const FRAME_SECONDS := 1.0 / 24.0
var destination := "res://output/qa/rc-017/motion"
var checks := 0
var failures := 0
var assertions: Array = []
var sequences: Array = []
var helper = ProductionUI.new()
var maximum_particles := 0
var maximum_emitters := 0
var maximum_nodes := 0
var maximum_draw_calls := 0
var maximum_texture_bytes := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			destination = argument.trim_prefix("--capture-directory=")
	DirAccess.make_dir_recursive_absolute(destination)
	for dimensions in [Vector2i(720, 1600), Vector2i(450, 1000), Vector2i(360, 640)]:
		await _capture_case(dimensions, "cast", "top")
		await _capture_case(dimensions, "cast", "board")
	await _capture_case(Vector2i(450, 1000), "shield", "top")
	await _capture_case(Vector2i(450, 1000), "pass", "top")
	await _capture_case(Vector2i(450, 1000), "victory", "top")
	await _capture_case(Vector2i(450, 1000), "defeat", "top")
	await _capture_case(Vector2i(450, 1000), "cast", "board", true)
	await _capture_case(Vector2i(360, 640), "conjure", "bottom")
	_check(maximum_emitters <= 2 and maximum_particles <= 64, "Observed transient emitters and particles stay within production caps.")
	var report := {
		"checks": checks, "failures": failures, "assertions": assertions,
		"sequences": sequences, "frame_seconds": FRAME_SECONDS,
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"resource_observations": {"maximum_emitting_particle_nodes": maximum_emitters,
			"maximum_configured_particles_on_emitting_nodes": maximum_particles,
			"maximum_scene_nodes": maximum_nodes, "maximum_rendered_draw_calls": maximum_draw_calls,
			"maximum_engine_reported_texture_bytes": maximum_texture_bytes},
		"scope": "Ordinary main.tscn in native SubViewports; actual controller accepted actions. Production adapter manually advances 1/24 second per rendered sample. Desktop render evidence, not physical-device performance or human input acceptance.",
		"fixtures": "Cast builds legal paths with shipped hand/kit using existing UI controls. Shield moves an actual Shield UID to the front of the hand, preserving shipped intent; victory/defeat set current target HP to 1 before action. Conjure uses an actually drawn Conjure. All fixture changes precede action resolution; per-frame snapshots assert no authoritative mutation during playback.",
		"memory_scope": "Engine RenderingServer texture-memory counter observed during sequential native SubViewport captures; includes render targets/caches and UI textures, excludes physical-device/driver residency. Particle count records actual emitting nodes, not an estimate from effects appearance."
	}
	var file := FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("%d RC-017 motion capture checks, %d failures; %d sequences" % [checks, failures, sequences.size()])
	quit(0 if failures == 0 else 1)

func _capture_case(dimensions: Vector2i, kind: String, framing: String, reduced := false) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	scene.sound_enabled = false # Evidence capture only; reduced-motion setting never changes this.
	scene.gestures.automatic_timing = false
	await _layout()
	var name := "%s-%s-%dx%d%s" % [kind, framing, dimensions.x, dimensions.y, "-reduced" if reduced else ""]
	_check(scene.startup_error.is_empty() and scene.setup_path == "res://data/production_encounter.json", name + " loads ordinary production Combat.")
	var presenter = scene.animation_presenter
	_check(presenter != null, name + " uses the real production animation adapter.")
	if presenter == null:
		viewport.queue_free()
		await process_frame
		return
	presenter.automatic_timing = false
	scene.set_reduced_motion(reduced)
	var model = scene.controller._combat
	if kind == "shield":
		var shield_index := -1
		for index in range(model.hand.size()):
			if model.hand[index].id == "shield":
				shield_index = index
		if shield_index >= 0:
			var card: Dictionary = model.hand[shield_index]
			model.hand.remove_at(shield_index)
			model.hand.push_front(card)
		_check(shield_index >= 0, name + " uses a real drawn Shield UID.")
	if kind == "victory":
		model.enemy_hp = 1
	if kind == "defeat":
		model.player_hp = 1
	scene._refresh()
	if kind in ["cast", "victory"] and helper._effect_uid(scene.game, true) < 0:
		# This seed opens with Shield/Conjure/Focus. Use its real Conjure to
		# obtain an actual generated Spark before constructing the damage path.
		for card in scene.game.hand.duplicate(true):
			if card.id == "conjure":
				scene._select_card(int(card.uid))
				presenter.finish()
				break
	if kind in ["cast", "shield", "victory"]:
		_check(helper._build(scene, kind in ["cast", "victory"]), name + " constructs a legal rune path using playable controls.")
		if kind == "shield":
			# The shipped enemy intent is deliberately unchanged. This is a partial
			# block when the actual Shield value is below that incoming amount.
			_check(int(scene.game.forecast.shield) > 0, name + " casts actual Shield output.")
	await _layout()
	_frame_scene(scene, framing)
	await _layout()
	var technique_uid := -1
	if kind in ["conjure", "focus"]:
		for card in scene.game.hand:
			if card.id == kind: technique_uid = int(card.uid)
		_check(technique_uid >= 0, name + " uses an actually drawn " + kind + " UID.")
		for card_view in scene.hand_box.get_children():
			if int(card_view.get_meta("uid", -1)) == technique_uid:
				scene.hand_scroll.ensure_control_visible(card_view)
		await _layout()
	var sequence_path := destination.path_join(name)
	DirAccess.make_dir_recursive_absolute(sequence_path)
	await _save(viewport, sequence_path.path_join("before.png"))
	var before: Dictionary = scene.controller.snapshot()
	var action_events: Array = []
	scene.controller.presentation_started.connect(func(result: Dictionary): action_events.assign(result.events.duplicate(true)))
	if kind in ["pass", "defeat"]:
		scene._request_pass()
		_check(scene.inspector.visible and scene.inspector_confirm_pass.visible, name + " keeps the explicit Pass confirmation.")
		scene.inspector_confirm_pass.pressed.emit()
	elif kind in ["conjure", "focus"]:
		if technique_uid >= 0: scene._select_card(technique_uid)
	else:
		scene.cast_button.pressed.emit()
	var resolved: Dictionary = scene.controller.snapshot()
	_check(scene.controller.is_busy() and presenter.is_active(), name + " locks an accepted action until its actual presentation completes.")
	_check(resolved != before, name + " resolves authoritative state before presentation.")
	var frames: Array = []
	var representative: Dictionary = {}
	var frame := 0
	# Derive the bounded capture from this batch's actual event schedule. Two
	# extra samples cover floating-point rounding without imposing a five-second
	# ceiling on longer circuits, slower pacing, or per-card cleanup/draw steps.
	var frame_budget := maxi(2, ceili(float(presenter.duration) / FRAME_SECONDS) + 2)
	var observed_start := Time.get_ticks_usec()
	while presenter.is_active() and frame < frame_budget:
		var phase := str(presenter.phase)
		var progress := float(presenter.phase_progress)
		await RenderingServer.frame_post_draw
		var path := sequence_path.path_join("frame-%03d.png" % frame)
		_check(viewport.get_texture().get_image().save_png(path) == OK, name + " writes deterministic frame %d." % frame)
		var observation := {"frame": frame, "seconds": float(presenter.elapsed), "phase": phase,
			"phase_progress": progress, "player_hp": scene.game.player_hp, "enemy_hp": scene.game.enemy_hp,
			"energy": scene.game.energy, "turn": scene.game.turn, "hand_count": scene.game.hand.size(),
			"path": path, "pose": str(scene.arena.actor.get_pose()), "pose_sample": scene.arena.actor.get_visual_sample()}
		if technique_uid >= 0:
			observation["hand_visuals"] = scene.hand_box.get_children().map(func(card_view): return {
				"uid": int(card_view.get_meta("uid", -1)),
				"scale": [card_view.scale.x, card_view.scale.y],
				"alpha": card_view.modulate.a, "brightness": card_view.modulate.r,
				"rect": [card_view.get_global_rect().position.x, card_view.get_global_rect().position.y,
					card_view.get_global_rect().size.x, card_view.get_global_rect().size.y]})
		frames.append(observation)
		if not representative.has(phase) or absf(progress - 0.5) < float(representative[phase].distance):
			representative[phase] = {"path": path, "distance": absf(progress - 0.5)}
		_check(scene.controller.snapshot() == resolved, name + " frame %d leaves authoritative outcomes and RNG unchanged." % frame)
		_measure(viewport)
		presenter.advance(FRAME_SECONDS)
		frame += 1
		await process_frame
	_check(frame <= frame_budget and not presenter.is_active() and not scene.controller.is_busy(), name + " completes and unlocks within its duration-derived sample budget.")
	_check(scene.game == resolved, name + " final view equals resolved model snapshot.")
	_check(presenter.event_trace == action_events, name + " visits every emitted event exactly once in original payload order.")
	var final_game: Dictionary = scene.game.duplicate(true)
	presenter.advance(0.5)
	_check(scene.game == final_game and scene.controller.snapshot() == resolved, name + " remains stable after extra advancement.")
	await _save(viewport, sequence_path.path_join("after.png"))
	if dimensions.x == 360:
		scene.page_scroll.ensure_control_visible(scene.hand_row)
		await _layout()
		await _save(viewport, sequence_path.path_join("after-hand.png"))
		scene.page_scroll.scroll_vertical = 100000
		await _layout()
		_check(scene.page_scroll.scroll_vertical > 0, name + " preserves intentional narrow vertical scrolling.")
		_check(scene.hand_row.get_global_rect().position.y < dimensions.y and scene.cast_button.get_global_rect().position.y < dimensions.y, name + " lower hand and Cast remain reachable by scrolling.")
		await _save(viewport, sequence_path.path_join("after-bottom.png"))
	var emitted_types: Array = action_events.map(func(event): return str(event.type))
	if kind == "pass":
		_check(not emitted_types.has("cast") and not emitted_types.has("shield") and not emitted_types.has("damage"), name + " Pass emits no synthesized spell/payment/player shield/enemy loss.")
	if kind == "victory":
		_check(resolved.state == "victory" and not emitted_types.has("retaliation") and not emitted_types.has("turn_started"), name + " lethal victory has no retaliation or next turn.")
	if kind == "defeat":
		_check(resolved.state == "defeat" and not emitted_types.has("turn_started"), name + " defeat remains terminal.")
	sequences.append({"name": name, "viewport": [dimensions.x, dimensions.y], "framing": framing,
		"technique_uid": technique_uid,
		"reduced_motion": reduced, "frames": frames, "representative": representative,
		"duration_seconds": float(presenter.duration), "sampled_seconds": frame * FRAME_SECONDS, "frame_budget": frame_budget,
		"capture_wall_ms": (Time.get_ticks_usec() - observed_start) / 1000.0,
		"events": action_events, "event_trace": presenter.event_trace.duplicate(true),
		"before": {"player_hp": before.player_hp, "enemy_hp": before.enemy_hp, "turn": before.turn},
		"after": {"player_hp": resolved.player_hp, "enemy_hp": resolved.enemy_hp, "turn": resolved.turn, "state": resolved.state}})
	scene.audio.dispose()
	viewport.queue_free()
	await process_frame

func _frame_scene(scene: Control, framing: String) -> void:
	if framing == "board":
		scene.page_scroll.scroll_vertical += int(scene.cells[0].get_global_rect().position.y) - 25
	elif framing == "bottom":
		scene.page_scroll.scroll_vertical = 100000
	else:
		scene.page_scroll.scroll_vertical = 0

func _layout() -> void:
	for _frame in range(5): await process_frame

func _save(viewport: SubViewport, path: String) -> void:
	await _layout()
	await RenderingServer.frame_post_draw
	_check(viewport.get_texture().get_image().save_png(path) == OK, "Saved " + path)

func _measure(viewport: SubViewport) -> void:
	var counts := _particle_counts(viewport)
	maximum_emitters = maxi(maximum_emitters, counts.x)
	maximum_particles = maxi(maximum_particles, counts.y)
	maximum_nodes = maxi(maximum_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	maximum_draw_calls = maxi(maximum_draw_calls, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	maximum_texture_bytes = maxi(maximum_texture_bytes, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED))

func _particle_counts(node: Node) -> Vector2i:
	var result := Vector2i.ZERO
	if (node is GPUParticles2D or node is CPUParticles2D) and node.emitting:
		result = Vector2i(1, int(node.amount))
	for child in node.get_children():
		result += _particle_counts(child)
	return result
