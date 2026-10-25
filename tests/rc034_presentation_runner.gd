extends SceneTree
## Actual production entries with unchanged 30-HP starter. Presentation-only
## boundaries replay the recorded legal victories from the ordinary starter.
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Actor = preload("res://scripts/ui/temporary_enemy_actor.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const DESTINATION := "res://output/qa/rc-034/presentation"
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []
var capturing := false

func _initialize() -> void:
	capturing = "--capture-rc034" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 6: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(scene, name: String) -> void:
	await settle()
	if scene.inspector.visible:
		check(root.get_visible_rect().encloses(scene.inspector_panel.get_global_rect()), name + ": inspector fits viewport.")
		check(root.get_visible_rect().encloses(scene.inspector_close.get_global_rect()), name + ": Close remains reachable.")
	if capturing:
		check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + ": capture saved.")

func tap(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		for enemy_id in Actor.IDS:
			var loaded := Loader.load_setup("res://data/production_%s_encounter.json" % enemy_id)
			check(loaded.ok, "Production " + enemy_id + " loads.")
			if loaded.ok: await _journey(loaded.setup, dimensions)
	await _actor_contract()
	_contact_cancellation()
	FileAccess.open(DESTINATION.path_join("results-capture.json" if capturing else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	FileAccess.open(DESTINATION.path_join("legal-commands.json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  ") + "\n")
	print("RC-034 presentation: %d checks, %d failures" % [checks, failures])
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)

func _journey(setup: Dictionary, dimensions: Vector2i) -> void:
	var id := str(setup.encounter.enemy_id)
	var tag := "%s-%dx%d" % [id, dimensions.x, dimensions.y]
	var evidence: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rc034/presentation-victories.json"))
	var wins: Array = evidence.filter(func(item): return item.encounter == id)
	check(not wins.is_empty(), tag + ": retained ordinary-resource victory exists.")
	if wins.is_empty(): return
	var replay: Dictionary = wins[0]
	print("RC-034 presentation ", tag)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = setup
	scene.battle_model = Combat.new(setup, int(replay.seed))
	scene.settings_path = DESTINATION.path_join(tag + ".cfg")
	root.add_child(scene)
	scene.animation_presenter.automatic_timing = false
	scene.audio.trace_enabled = true
	scene.audio.automatic_timing = false
	scene.audio.apply_settings({"enabled": true, "sfx_muted": false, "sfx_volume": 1.0})
	await settle()
	var opening: Dictionary = scene.controller.snapshot()
	var commands: Array = []
	scene.controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
	check(root.size == dimensions, tag + ": actual configured window.")
	check(opening.player_hp == 30 and opening.player_max_hp == 30 and opening.energy_per_turn == 3, tag + ": ordinary entry resources unchanged.")
	check(scene.arena.actor == scene.arena.temporary_actor and scene.arena.actor.visible and not scene.arena.shadeling_actor.visible, tag + ": dedicated token; Shadeling hidden.")
	check(scene.arena.actor.enemy_id == id and scene.arena.name_label.text == opening.enemy_name and scene.arena.health_label.text == "%d/%d" % [opening.enemy_hp, opening.enemy_max_hp], tag + ": actual identity and health shown.")
	check(scene.arena.actor.get_attachment_position(&"foot", true).is_equal_approx(scene.arena.actor.global_position), tag + ": shared foot anchor.")
	await capture(scene, tag + "-opening")
	tap(scene.arena.intent_button)
	await settle()
	check(scene.inspector.visible and scene.inspector_title.text == "Enemy intent", tag + ": touch opens actual intent.")
	check(scene.inspector_text.text.contains("Announced attack: " + str(opening.intent)), tag + ": authoritative announcement inspectable.")
	await capture(scene, tag + "-intent")
	if id == "bell_keeper":
		scene.inspector_scroll.scroll_vertical = 10000
		await capture(scene, tag + "-intent-scrolled")
	tap(scene.inspector_close)
	await settle()
	check(scene.controller.snapshot() == opening and commands.is_empty(), tag + ": inspection is read-only.")
	var contacts: Array = []
	scene.animation_presenter.contact_reached.connect(func(notice): contacts.append(notice.duplicate(true)))
	var first_cast := true
	var phase_count := 0
	for command in replay.commands:
		check(scene.controller.command(str(command.command), command.arguments), tag + ": retained legal " + str(command.command))
		if command.command == "cast":
			var result: Dictionary = scene.battle_model.last_result()
			var crossing: bool = result.events.any(func(event): return event.type == "enemy_phase_changed")
			var has_damage: bool = result.events.any(func(event): return event.type == "damage" and int(event.applied) > 0)
			if (first_cast and has_damage) or crossing:
				_seek(scene, "damage")
				scene.animation_presenter.advance(0.10)
				check(scene.arena.actor.get_visual_sample().state == "hit", tag + ": applied damage samples token hit.")
				if first_cast: await capture(scene, tag + "-hit")
				_seek(scene, "retaliation")
				check(scene.animation_presenter._contact_fraction == 0.5, tag + ": explicit token contact independent of Shadeling metadata.")
				var contact_count := contacts.size()
				scene.animation_presenter.advance(float(scene.animation_presenter._steps[scene.animation_presenter._index].seconds) * 0.5)
				check(contacts.size() == contact_count + 1 and is_equal_approx(float(contacts.back().phase_progress), 0.5), tag + ": exactly one midpoint contact.")
				check(scene.arena.actor.get_visual_sample().state == "attack" and scene.game.player_hp == result.before.player_hp, tag + ": attack feedback precedes health commit.")
				if first_cast: await capture(scene, tag + "-attack")
				if crossing:
					check(scene.game.intent == result.before.intent and scene.game.enemy_action.phase == 1, tag + ": old intent retained through threshold retaliation.")
					await capture(scene, tag + "-old-retaliation")
					_seek(scene, "enemy_phase_changed")
					phase_count += 1
					await capture(scene, tag + "-phase-change")
				first_cast = false
			if scene.controller.is_busy(): scene.animation_presenter.finish()
			if crossing:
				check(scene.game.enemy_action.phase == 2 and scene.game.intent == 12, tag + ": next surviving turn begins phase two at 12.")
				await capture(scene, tag + "-phase-two")
		elif scene.controller.is_busy(): scene.animation_presenter.finish()
	check(scene.game.state == "victory" and scene.game.player_hp == int(replay.remaining_hp), tag + ": exact ordinary-resource victory reproduced.")
	check(scene.arena.actor.get_visual_sample().opacity == 0.0, tag + ": committed enemy defeat fades token fully.")
	check(scene.audio.trace.any(func(cue): return cue.role == "player_damage") and not scene.audio.trace.any(func(cue): return cue.role == "actor" or cue.cue == "spectral"), tag + ": shared impact cues with silent unavailable actor accents and no Shadeling audio.")
	check(phase_count == (1 if id == "bell_keeper" else 0), tag + ": phase transition occurs only for guardian, once.")
	await capture(scene, tag + "-victory")
	var saved_contacts := contacts.size()
	scene.animation_presenter.finish()
	check(contacts.size() == saved_contacts and not scene.controller.command("cast") and not scene.controller.command("pass"), tag + ": duplicate finish and terminal callbacks do nothing.")
	traces.append({"tag": tag, "entry": opening, "commands": commands, "final": scene.controller.snapshot(), "purpose": "ordinary starter legal victory replay with production presentation"})
	scene.queue_free()
	await settle()

func _seek(scene, phase: String) -> void:
	for sample in 5000:
		if scene.animation_presenter.phase == phase or not scene.controller.is_busy(): break
		scene.animation_presenter.advance(0.005)
	check(scene.animation_presenter.phase == phase, "Ordered presentation reaches " + phase)

func _actor_contract() -> void:
	var actor := Actor.new()
	root.add_child(actor)
	for id in Actor.IDS:
		actor.configure(id)
		for reduced in [false, true]:
			for phase in [&"hit", &"attack", &"defeat"]:
				check(actor.sample_presentation(phase, 0.5, reduced), id + ": sample " + str(phase))
				var sample := actor.get_visual_sample()
				if reduced: check(sample.rotation == 0.0 and sample.scale == [1.0, 1.0], id + ": reduced motion holds transforms.")
			actor.reset_presentation("victory", reduced)
			check(actor.get_visual_sample().opacity == 0.0, id + ": committed enemy defeat fades fully.")
			actor.reset_presentation("playing", reduced)
			check(actor.get_visual_sample().opacity == 1.0 and actor.pose_root.rotation == 0.0, id + ": cancellation/replay resets transient art.")
	actor.queue_free()
	await process_frame

func _contact_cancellation() -> void:
	var loaded := Loader.load_setup("res://data/production_wickling_encounter.json")
	var controller := Controller.new(Combat.new(loaded.setup))
	var presenter := Animated.new()
	presenter.automatic_timing = false
	controller.set_presenter(presenter)
	var contacts := [0]
	var owner: WeakRef = weakref(controller)
	presenter.contact_reached.connect(func(_notice):
		contacts[0] += 1
		owner.get_ref().cancel_presentation())
	check(controller.command("pass"), "Detached token Pass accepted.")
	var committed: Dictionary = controller.snapshot()
	presenter.finish()
	presenter.finish()
	check(contacts[0] == 1 and not presenter.is_active() and not controller.is_busy(), "Reentrant contact cancellation invalidates remainder and duplicate callbacks.")
	check(controller.snapshot() == committed and committed.player_hp == 24, "Contact cancellation cannot alter already committed gameplay.")
	controller.dispose()
	presenter.dispose()
