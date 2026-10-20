extends RefCounted
const Audio = preload("res://scripts/audio/audio_coordinator.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Animated = preload("res://scripts/ui/animated_combat_presentation.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func run(check: Callable, tree: SceneTree) -> void:
	for reduced in [false, true]:
		for kind in ["cast", "shield", "partial", "zero", "pass", "lethal", "defeat", "focus", "conjure"]:
			_action(check, tree, kind, reduced)
	_edits(check, tree)
	_cancellation(check, tree)
	_stale_owner(check, tree)
	_contact_roles(check, tree)
	_voices(check, tree)
	_loops(check, tree)
	await _playable(check, tree)

func _fixture(tree: SceneTree, reduced := false) -> Dictionary:
	var model := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup)
	var presenter := Animated.new()
	presenter.automatic_timing = false
	presenter.reduced_motion = reduced
	var controller := Controller.new(model, presenter)
	var audio := Audio.new()
	tree.root.add_child(audio)
	audio.automatic_timing = false
	audio.trace_enabled = true
	audio.apply_settings({"enabled": true, "sfx_muted": false, "music_muted": false, "reduced_motion": reduced})
	audio.bind_controller(controller)
	return {"model": model, "presenter": presenter, "controller": controller, "audio": audio}

func _close(f: Dictionary) -> void:
	f.audio.dispose()
	f.audio.free()
	f.controller.dispose()
	f.presenter.dispose()

func _roles(audio, role: String) -> Array:
	return audio.trace.filter(func(record): return record.role == role)

func _cues(audio, cue: String) -> Array:
	return audio.trace.filter(func(record): return record.cue == cue)

func _action(check: Callable, tree: SceneTree, kind: String, reduced: bool) -> void:
	var f := _fixture(tree, reduced)
	var command := "cast"
	var arguments := {}
	match kind:
		"shield", "partial":
			f.model.board[1].rune_id = "shield"
			if kind == "partial": f.model.encounter.intents = [20]
		"zero": f.model.catalog.free_spark.value = 0
		"pass", "defeat": command = "pass"
		"lethal": f.model.enemy_hp = 1
		"focus", "conjure":
			command = "technique"
			f.model.hand = [f.model._card(kind)]
			arguments.uid = f.model.hand[0].uid
	if kind == "defeat": f.model.player_hp = 1
	var accepted: bool = f.controller.command(command, arguments)
	check.call(accepted, "%s reduced=%s actual action accepted" % [kind, reduced])
	var resolved: Dictionary = f.controller.snapshot()
	if kind == "partial":
		var retaliation: Array = f.model.last_result().events.filter(func(event): return event.type == "retaliation")
		check.call(retaliation.size() == 1 and retaliation[0].blocked > 0 and retaliation[0].applied > 0, "Partial-block fixture has real block and HP loss")
	var random_state := [f.model.rng.state, f.model.endpoint_rng.state, f.model.kit_rng.state]
	if command == "technique":
		check.call(f.audio.trace.is_empty(), "Played technique phase is silent before actual card arrival")
		f.presenter.advance(0.06 if reduced else 1.0)
		check.call(_roles(f.audio, "arrival").size() == 1, "First actual technique arrival starts one cue")
	f.presenter.finish() # Deliberately cross all remaining phases in one step.
	check.call(f.controller.snapshot() == resolved and random_state == [f.model.rng.state, f.model.endpoint_rng.state, f.model.kit_rng.state], "Audio and large advances preserve resolved state and all RNG streams")
	check.call(not f.controller.is_busy(), "Audio never delays completion")
	check.call(_roles(f.audio, "cast").size() == (1 if command == "cast" else 0), "Exactly one Cast only in accepted Cast")
	check.call(_roles(f.audio, "cleanup").size() <= 1 and _roles(f.audio, "arrival").size() <= 1, "Cleanup/arrivals coalesce across every event")
	if kind in ["zero", "shield", "partial"]:
		check.call(_roles(f.audio, "enemy_damage").is_empty(), "No enemy impact for zero applied HP loss")
	if reduced:
		check.call(_roles(f.audio, "enemy_damage").is_empty() and _roles(f.audio, "shield_gain").is_empty(), "Reduced Cast suppresses redundant damage and gain pings")
		check.call(f.audio.peak_voices <= 2, "Reduced foreground includes at most one release tail")
		check.call(_roles(f.audio, "actor").is_empty() and _roles(f.audio, "player_damage").is_empty(), "Reduced retaliation emits one semantic cue")
		if kind == "partial": check.call(_roles(f.audio, "retaliation").size() == 1 and _roles(f.audio, "retaliation")[0].cue == "damage", "Reduced partial block chooses actual player impact")
	else:
		check.call(f.audio.peak_voices <= 8, "Normal voices including tails remain bounded")
		if kind in ["shield", "partial"]:
			check.call(_roles(f.audio, "shield_gain").size() == 1 and _roles(f.audio, "block").is_empty(), "Positive shield gain represents later block without duplication")
		if kind == "partial": check.call(_roles(f.audio, "actor").size() == 1 and _roles(f.audio, "player_damage").size() == 1, "Normal partial block layers actor and actual impact only")
	if kind == "lethal":
		check.call(_roles(f.audio, "actor").is_empty() and _roles(f.audio, "retaliation").is_empty() and _cues(f.audio, "victory").size() == 1, "Lethal Cast has committed victory once and no retaliation")
	if kind == "defeat": check.call(_cues(f.audio, "defeat").size() == 1, "Defeat follows actual committed result once")
	var count: int = f.audio.trace.size()
	for event in f.model.last_result().events: f.presenter.event_presented.emit(event)
	f.presenter.finish()
	check.call(f.audio.trace.size() == count, "Duplicate consequence callbacks and completion never replay cues")
	for record in f.audio.trace:
		if record.role in ["actor", "player_damage", "block", "retaliation"]:
			check.call(is_equal_approx(float(record.target.progress), 0.28), "Retaliation cue occurs at metadata contact fraction")
	_close(f)

func _stale_owner(check: Callable, tree: SceneTree) -> void:
	# A retained disposed owner must not affect a subsequent scene's shared buses.
	var f := _fixture(tree)
	f.audio.set_context("screen_combat", true)
	f.audio.dispose()
	var next := _fixture(tree)
	next.audio.set_context("screen_combat", true)
	var old_starts: int = f.audio.loop_starts.ambience
	f.audio.apply_settings({"enabled": false})
	f.audio.set_interrupted(true)
	f.audio.set_context("screen_combat", true)
	check.call(f.audio.loop_starts.ambience == old_starts and not AudioServer.is_bus_mute(AudioServer.get_bus_index(Audio.MUSIC_BUS)), "Disposed stale settings/context callbacks cannot revive loops or mute the new owner")
	_close(f)
	_close(next)

func _edits(check: Callable, tree: SceneTree) -> void:
	var f := _fixture(tree)
	check.call(f.controller.command("place_wire", {"index": 3, "kind": "straight"}), "Accepted connector edit fixture")
	check.call(_cues(f.audio, "edit_place").size() == 1 and f.audio.trace.back().target == {"index": 3, "kind": "straight"}, "Accepted edit retains actual target/arguments")
	f.controller.command("rotate", {"index": 3})
	f.controller.command("place_wire", {"index": 3, "kind": "erase"})
	check.call(_cues(f.audio, "edit_orient").size() == 1 and _cues(f.audio, "edit_restore").size() == 1, "Rotate and historical sfx_undo Remove map once")
	for attempt in 20:
		f.controller.command("rotate", {"index": 99})
	check.call(_cues(f.audio, "action_rejected").size() == 1, "Explicit rejected attempts throttle across reasons at 250ms")
	var count: int = f.audio.trace.size()
	for refresh in 20:
		f.controller.can_edit()
		f.controller.snapshot()
		f.controller.changed.emit()
	check.call(f.audio.trace.size() == count, "Passive availability and refresh never sound")
	f.audio.ui_feedback("ui_confirm", 1)
	f.audio.ui_feedback("ui_confirm", 1)
	check.call(_cues(f.audio, "ui_confirm").size() == 1, "UI dispatch deduplication is independent of action identity")
	_close(f)

func _contact_roles(check: Callable, tree: SceneTree) -> void:
	for reduced in [false, true]:
		var f := _fixture(tree, reduced)
		f.model.encounter.intents = [0]
		f.controller.command("pass")
		f.presenter.finish()
		check.call(_cues(f.audio, "spectral").size() == 1 and _cues(f.audio, "damage").is_empty() and _cues(f.audio, "shield").is_empty(), "Zero applied/blocked retaliation chooses actor only")
		_close(f)
	var f := _fixture(tree, true)
	f.model.board[1].rune_id = "shield"
	f.controller.command("cast")
	f.presenter.advance(0.12) # Gain boundary was intentionally suppressed in reduced Cast.
	f.presenter.reduced_motion = false
	f.audio.apply_settings({"reduced_motion": false})
	f.presenter.finish()
	check.call(_roles(f.audio, "shield_gain").is_empty() and _roles(f.audio, "block").size() == 1 and _roles(f.audio, "actor").size() == 1, "Otherwise unrepresented full block pairs actor and shield, without injury")
	_close(f)

func _cancellation(check: Callable, tree: SceneTree) -> void:
	for reason in ["cancel", "restart", "mute", "individual", "zero_volume", "interrupt", "replace", "dispose"]:
		var f := _fixture(tree)
		f.controller.command("cast")
		var old_session: int = f.audio.session
		var old_batch: Dictionary = f.model.last_result()
		match reason:
			"cancel": f.controller.cancel_presentation()
			"restart": f.controller.restart()
			"mute": f.audio.apply_settings({"enabled": false})
			"individual": f.audio.apply_settings({"sfx_muted": true})
			"zero_volume": f.audio.apply_settings({"sfx_volume": 0.0})
			"interrupt": f.audio.set_interrupted(true)
			"replace": f.audio.bind_controller(null)
			"dispose": f.audio.dispose()
		check.call(f.audio.active_voice_count() == 0, reason + " stops owned SFX")
		f.audio.apply_settings({"enabled": true, "sfx_muted": false, "sfx_volume": 1.0})
		f.audio.set_interrupted(false)
		f.presenter.finish()
		f.audio._event_committed(old_batch.events.back(), old_session)
		check.call(f.audio.trace.size() == 1, reason + " invalidates pending events through resume")
		_close(f)
	var f := _fixture(tree)
	f.controller.command("cast")
	f.presenter.finish()
	var before: int = _cues(f.audio, "cast").size()
	var replacement := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup)
	var presenter := Animated.new()
	var controller := Controller.new(replacement, presenter)
	f.audio.bind_controller(controller)
	controller.command("cast")
	check.call(_cues(f.audio, "cast").size() == before + 1, "Exact replay numeric action ID reuse has a new audio session")
	presenter.finish()
	controller.dispose()
	presenter.dispose()
	_close(f)
	# Cancellation can happen inside an observer of the first contact sound.
	f = _fixture(tree)
	f.audio.cue_started.connect(func(record):
		if record.role == "actor": f.controller.cancel_presentation())
	f.controller.command("pass")
	f.presenter.finish()
	check.call(_roles(f.audio, "player_damage").is_empty() and f.audio.active_voice_count() == 0, "Reentrant cancellation prevents the second contact cue")
	_close(f)

func _voices(check: Callable, tree: SceneTree) -> void:
	var f := _fixture(tree)
	for index in 40: f.audio.ui_feedback("ui_confirm", index)
	check.call(f.audio.peak_voices <= 8 and f.audio.active_voice_count() == 8, "Repeated input cannot exceed eight active SFX including tails")
	f.audio.apply_settings({"reduced_motion": true})
	f.audio._start_cue("cast", "test-cast", "cast", {}, -999.0, -1, true, true)
	check.call(f.audio.active_voice_count() <= 2, "First reduced cue collapses prior normal-mode overlap immediately")
	f.audio._start_cue("damage", "test-contact", "retaliation", {}, -999.0, -1, true, true)
	check.call(f.audio.active_voice_count() <= 2, "Reduced policy collapses all preexisting voices and tails")
	for voice in f.audio._voices:
		if voice.active and voice.release > 0.0:
			check.call(voice.player.stream.get_length() <= 0.008 and voice.player.stream.data.decode_s16(voice.player.stream.data.size() - 2) == 0, "Release tail uses sample-domain <=8ms envelope ending at zero")
	f.audio.advance_audio(0.01)
	check.call(f.audio.active_voice_count() == 1, "Release expires while meaningful full-length impact continues")
	f.audio.advance_audio(5.0)
	check.call(f.audio.active_voice_count() == 0, "No obsolete audio queue remains after tails")
	_close(f)
	f = _fixture(tree, true)
	for index in 20: f.controller.command("rotate", {"index": 3})
	check.call(f.audio.active_voice_count() <= 2 and f.audio.trace.all(func(record): return record.reduced), "Accepted edits honor reduced foreground policy through controller success")
	_close(f)

func _loops(check: Callable, tree: SceneTree) -> void:
	var f := _fixture(tree)
	f.audio.set_context("screen_combat", true)
	f.audio.advance_audio(0.6)
	for refresh in 20: f.audio.set_context("screen_combat", true)
	check.call(f.audio.loop_starts.ambience == 1 and f.audio.loop_starts.music == 0, "Crypt starts once, absent music never loads")
	check.call(f.audio._ambience.player.stream is AudioStreamOggVorbis and f.audio._ambience.player.stream.loop, "Crypt stays compressed with imported loop points")
	f.audio.set_context("screen_home", true)
	f.audio.advance_audio(0.6)
	check.call(f.audio._ambience.cue == "", "Home never acquires crypt ambience even when crypt flag is supplied")
	# Clearly isolated in-memory test-only streams; no file/substitute is shipped.
	for cue in ["home_exploration", "combat"]:
		var stream := AudioStreamWAV.new()
		stream.data = PackedByteArray([0, 0, 1, 0, 0, 0, 255, 255])
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = 4
		f.audio._loops[cue].stream = stream
		f.audio._loops[cue].status = "available"
	f.audio.set_context("screen_home")
	f.audio.advance_audio(0.6)
	f.audio.set_context("screen_combat", true)
	f.audio.advance_audio(0.3)
	check.call(f.audio._music.all(func(slot): return is_equal_approx(slot.level, 0.5)), "Test-only music streams crossfade over 0.6 seconds")
	f.audio.set_context("screen_home")
	f.audio.advance_audio(0.6)
	check.call(f.audio._music.filter(func(slot): return slot.cue != "").size() == 1, "Interrupted crossfade reconciles in two existing players")
	check.call(f.audio._music.size() == 2, "Exactly two bounded music player slots")
	f.audio.set_interrupted(true)
	f.audio.set_context("")
	f.audio.set_interrupted(false)
	check.call(f.audio._music.all(func(slot): return slot.cue == "") and f.audio._ambience.cue == "", "Background context exit cannot resume a hidden loop")
	_close(f)

func _playable(check: Callable, tree: SceneTree) -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "res://output/qa/rc-020/playable-test-settings.cfg"
	tree.root.add_child(scene)
	await tree.process_frame
	scene.audio.trace_enabled = true
	scene.audio.apply_settings({"enabled": true, "sfx_muted": false, "music_muted": false, "reduced_motion": false})
	scene.animation_presenter.automatic_timing = false
	var starts: int = scene.audio.loop_starts.ambience
	scene._open_menu()
	scene.menu.hide()
	scene._refresh()
	check.call(scene.audio.loop_starts.ambience == starts, "Actual Menu and UI refresh preserve the crypt player")
	check.call(scene.audio.trace.all(func(record): return record.role == "ui"), "No invented opening draw cues from initial snapshot")
	scene.hide()
	check.call(scene.audio.loop_snapshot().interrupted and scene.audio.loop_snapshot().ambience.paused, "Hidden playable scene suspends owned loops")
	scene.show()
	check.call(not scene.audio.loop_snapshot().interrupted and scene.audio.loop_starts.ambience == starts, "Visible scene resumes the same loop without duplicate start")
	scene._pass()
	scene.animation_presenter.finish()
	check.call(_roles(scene.audio, "actor").size() == 1 and _roles(scene.audio, "player_damage").size() == 1 and _cues(scene.audio, "cast").is_empty(), "Actual playable Pass sounds at one retaliation contact without Cast")
	var old_session: int = scene.audio.session
	scene._exact_replay()
	check.call(scene.audio.session > old_session and scene.audio.loop_starts.ambience == starts, "Actual Exact replay rebinds outcomes while preserving compatible crypt ambience")
	scene.queue_free()
	await tree.process_frame
