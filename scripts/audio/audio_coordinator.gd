extends Node
## One scene-owned mixer. Audio observes detached outcomes; it never completes or
## mutates combat. All envelopes run here, with no retained timers/tween callbacks.
const Catalogue = preload("res://scripts/audio/audio_catalogue.gd")
const MAX_SFX := 8
const RELEASE_SECONDS := 0.008
const CROSSFADE_SECONDS := 0.6
const REJECTION_MSEC := 250
## Measured rapid accepted edit overlap exceeded full-scale at catalogue gains.
## Reserve 6 dB for the bounded SFX mix; the user's 100% still means this baseline.
const SFX_HEADROOM_DB := -6.0
const SFX_BUS := "RuneCast SFX"
const MUSIC_BUS := "RuneCast Music"
const AMBIENCE_BUS := "RuneCast Ambience"

signal cue_started(record: Dictionary)

var automatic_timing := true
var trace_enabled := false
var trace: Array = []
var session := 0
var peak_voices := 0
var loop_starts := {"music": 0, "ambience": 0}
var _settings := {"enabled": true, "music_volume": 1.0, "sfx_volume": 1.0,
	"music_muted": false, "sfx_muted": false, "reduced_motion": false}
var _controller
var _presenter
var _connections: Array = []
var _batch: Dictionary = {}
var _seen: Dictionary = {}
var _ui_seen: Dictionary = {}
var _voices: Array = []
var _music: Array = []
var _ambience: Dictionary = {}
var _context := ""
var _crypt := false
var _desired_music := ""
var _desired_ambience := ""
var _loops: Dictionary = {}
var _streams: Dictionary = {}
var _last_rejection_msec := -REJECTION_MSEC
var _command_dispatch := 0
var _interrupted := false
var _focused := true
var _suspended := false
var _visible_owner := true
var _closed := false
var _initialized := false
var _presenter_generation := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_players()
	if get_parent() is CanvasItem:
		get_parent().visibility_changed.connect(_owner_visibility_changed)
		_owner_visibility_changed()

func _owner_visibility_changed() -> void:
	if _closed or not is_instance_valid(get_parent()): return
	_visible_owner = get_parent().is_visible_in_tree()
	set_interrupted(not _focused or _suspended or not _visible_owner)

func _initialize_players() -> void:
	if _initialized: return
	_initialized = true
	_ensure_bus(MUSIC_BUS, "Master")
	_ensure_bus(AMBIENCE_BUS, MUSIC_BUS)
	_ensure_bus(SFX_BUS, "Master")
	_loops = Catalogue.LOOPS.duplicate(true)
	for index in MAX_SFX:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%d" % index
		player.bus = SFX_BUS
		add_child(player)
		_voices.append({"player": player, "active": false, "remaining": 0.0,
			"release": 0.0, "priority": 0, "gain": 0.0, "cue": ""})
	for index in 2: _music.append(_new_loop_player("Music%d" % index, MUSIC_BUS))
	_ambience = _new_loop_player("CryptAmbience", AMBIENCE_BUS)
	_apply_buses()

func _ensure_bus(bus_name: String, parent: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0: return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, parent)

func _new_loop_player(player_name: String, bus: String) -> Dictionary:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	add_child(player)
	return {"player": player, "cue": "", "level": 0.0, "start": 0.0,
		"target": 0.0, "elapsed": 0.0, "seconds": CROSSFADE_SECONDS}

func bind_controller(controller) -> void:
	if _closed: return
	_disconnect_all()
	session += 1
	_batch.clear()
	_seen.clear()
	_presenter_generation = -1
	_stop_sfx()
	_controller = controller
	_presenter = null
	if controller == null: return
	_connect(controller, "presentation_started", _presentation_started.bind(session))
	_connect(controller, "command_resolved", _command_resolved.bind(session))
	_connect(controller, "presentation_invalidated", _invalidated.bind(session))
	_connect(controller, "presenter_changed", _presenter_changed.bind(session))
	_presenter = controller.get_presenter()
	if _presenter.has_signal("phase_started"):
		_connect(_presenter, "phase_started", _phase_started.bind(session))
		_connect(_presenter, "contact_reached", _contact_reached.bind(session))
		_connect(_presenter, "event_presented", _event_committed.bind(session))
		_connect(_presenter, "presentation_cancelled", _presenter_cancelled.bind(session))

func _connect(source, signal_name: String, callback: Callable) -> void:
	source.connect(signal_name, callback)
	_connections.append({"source": weakref(source), "signal": signal_name, "callback": callback})

func _disconnect_all() -> void:
	for connection in _connections:
		var source = connection.source.get_ref()
		if source != null and source.is_connected(connection.signal, connection.callback):
			source.disconnect(connection.signal, connection.callback)
	_connections.clear()

func _presenter_changed(_replacement, token: int) -> void:
	if token == session and not _closed: bind_controller(_controller)

func _invalidated(notice: Dictionary, token: int) -> void:
	if token != session or _closed: return
	_batch.clear()
	_presenter_generation = -1
	_stop_sfx()
	if notice.get("reason") == "dispose": bind_controller(null)

func _presenter_cancelled(notice: Dictionary, token: int) -> void:
	if token != session or _batch.is_empty(): return
	if int(notice.get("action_id", -1)) == int(_batch.action_id): _invalidated(notice, token)

func _presentation_started(result: Dictionary, token: int) -> void:
	if token != session or _closed: return
	if result.command == "next_encounter": _stop_sfx()
	_batch = result.duplicate(true) if _sfx_enabled() else {}
	_presenter_generation = -1

func _command_resolved(outcome: Dictionary, token: int) -> void:
	if token != session or _closed: return
	_command_dispatch += 1
	if not outcome.accepted:
		reject_attempt("command:%d:%d" % [session, _command_dispatch], outcome.arguments)
		return
	var cue := ""
	match str(outcome.command):
		"place_wire": cue = "edit_restore" if outcome.arguments.get("kind") == "erase" else "edit_place"
		"place_rune": cue = "edit_place"
		"rotate": cue = "edit_orient"
	if cue.is_empty(): return
	var result: Dictionary = outcome.result
	var key := "%d:%d:%d:edit" % [session, result.encounter_id, result.action_id]
	_play_once(cue, key, "edit", outcome.arguments, -999.0, -1, false, bool(_settings.reduced_motion))

func _valid_notice(notice: Dictionary, token: int) -> bool:
	if _closed or token != session or _batch.is_empty() or not _sfx_enabled(): return false
	if int(notice.action_id) != int(_batch.action_id) or int(notice.encounter_id) != int(_batch.encounter_id): return false
	if _presenter_generation < 0: _presenter_generation = int(notice.generation)
	return int(notice.generation) == _presenter_generation

func _action_key() -> String:
	return "%d:%d:%d" % [session, _batch.encounter_id, _batch.action_id]

func _event_key(event: Dictionary, role: String) -> String:
	return "%s:%d:%s" % [_action_key(), int(event.sequence), role]

func _phase_started(notice: Dictionary, token: int) -> void:
	if not _valid_notice(notice, token): return
	var event: Dictionary = notice.event
	var reduced := bool(notice.reduced_motion)
	var reduced_cast: bool = reduced and _batch.command == "cast"
	var target := {"event": event.duplicate(true), "clock": notice.elapsed,
		"progress": notice.phase_progress, "generation": notice.generation}
	match str(event.type):
		"cast": _play_once("cast", _action_key() + ":cast", "cast", target, -999.0, -1, true, reduced)
		"damage":
			if int(event.applied) > 0 and not reduced_cast:
				_play_once("damage", _event_key(event, "enemy_damage"), "enemy_damage", target, -999.0, -1, true, reduced)
		"shield":
			if int(event.amount) > 0 and not reduced_cast:
				var represented := _action_key() + ":shield_represented"
				if _play_once("shield", _action_key() + ":shield_gain", "shield_gain", target, -6.0, -1, true, reduced):
					_seen[represented] = true
		"card_drawn", "card_created":
			if not event.get("card", {}).has("uid"): return
			var created: bool = event.type == "card_created"
			var meaningful: bool = _batch.command == "technique"
			_play_once("technique_conjure" if created else "technique_draw",
				_action_key() + ":arrival:" + str(event.type), "arrival", target, -999.0,
				60 if meaningful else 30, meaningful, reduced)
		"effect_consumed", "temporary_expired", "board_piece_cleared", "turn_cleanup":
			if event.type == "turn_cleanup" and event.discarded.is_empty() and event.expired.is_empty(): return
			_play_once("temporary_expired", _action_key() + ":cleanup", "cleanup", target, -999.0, -1, false, reduced)

func _contact_reached(notice: Dictionary, token: int) -> void:
	if not _valid_notice(notice, token): return
	var event: Dictionary = notice.event
	if event.type != "retaliation": return
	var reduced := bool(notice.reduced_motion)
	var actor_id := str(_batch.before.get("encounter", {}).get("enemy_id", ""))
	var actor: String = Catalogue.ACTORS.get(actor_id, "")
	var target := {"event": event.duplicate(true), "actor_id": actor_id,
		"clock": notice.elapsed, "progress": notice.phase_progress, "generation": notice.generation}
	var impact := int(event.applied) > 0
	var block := int(event.blocked) > 0
	if reduced:
		var cue := "damage" if impact else "shield" if block else actor
		var gain := -5.0 if impact else -4.0 if block else -999.0
		if not cue.is_empty(): _play_once(cue, _event_key(event, "retaliation"), "retaliation", target, gain, -1, true, true)
		return
	if not actor.is_empty(): _play_once(actor, _event_key(event, "actor"), "actor", target, -3.0, -1, true)
	if not _valid_notice(notice, token): return
	if impact:
		_play_once("damage", _event_key(event, "player_damage"), "player_damage", target, -5.0, -1, true)
	elif block and not _seen.has(_action_key() + ":shield_represented"):
		_play_once("shield", _event_key(event, "block"), "block", target, -4.0, -1, true)

func _event_committed(event: Dictionary, token: int) -> void:
	if token != session or _closed or _batch.is_empty() or not _sfx_enabled(): return
	if event.action_id != _batch.action_id or event.encounter_id != _batch.encounter_id: return
	if event.type != "battle_ended" or event.state not in ["victory", "defeat"]: return
	var key := "%d:%d:result:%s" % [session, event.encounter_id, event.state]
	_play_once(event.state, key, "result", {"event": event.duplicate(true), "moment": "committed"}, -999.0, -1, true, bool(_settings.reduced_motion))

func ui_feedback(cue: String, dispatch_id, target: Dictionary = {}) -> void:
	if cue not in ["ui_confirm", "ui_back"] or _closed: return
	var key := str(dispatch_id)
	if _ui_seen.has(key): return
	_ui_seen[key] = true
	# UI IDs are independent of model action IDs, including during Exact replay.
	if _ui_seen.size() > 2048: _ui_seen.erase(_ui_seen.keys()[0])
	_start_cue(cue, "ui:" + key, "ui", target, -999.0, -1, false, bool(_settings.reduced_motion))

func reject_attempt(dispatch_id, target: Dictionary = {}) -> void:
	var key := "reject:" + str(dispatch_id)
	if _ui_seen.has(key) or _closed: return
	_ui_seen[key] = true
	var now := Time.get_ticks_msec()
	if now - _last_rejection_msec < REJECTION_MSEC: return
	_last_rejection_msec = now
	_start_cue("action_rejected", key, "rejection", target, -999.0, -1, false, bool(_settings.reduced_motion))

func _play_once(cue: String, identity: String, role: String, target: Dictionary,
	gain := -999.0, priority := -1, meaningful := false, reduced := false) -> bool:
	if _seen.has(identity): return false
	_seen[identity] = true # Dropped/muted cues are consumed, never put in a queue.
	return _start_cue(cue, identity, role, target, gain, priority, meaningful, reduced)

func _start_cue(cue: String, identity: String, role: String, target: Dictionary,
	gain: float, priority: int, meaningful: bool, reduced: bool) -> bool:
	if not _sfx_enabled() or not Catalogue.SFX.has(cue): return false
	_initialize_players()
	var entry: Dictionary = Catalogue.SFX[cue]
	if entry.future_only: return false
	var stream := _load_stream(entry)
	if stream == null: return false
	var level: float = entry.gain_db if gain == -999.0 else gain
	var rank: int = entry.priority if priority < 0 else priority
	if reduced:
		for voice in _voices:
			if voice.active and voice.release <= 0.0 and int(voice.priority) > rank and not meaningful: return false
		# Keep exactly one foreground plus one bounded release tail, even if a
		# deterministic advance crosses several meaningful boundaries in one frame.
		var foreground: Dictionary = {}
		for voice in _voices:
			if voice.active and voice.release <= 0.0:
				if foreground.is_empty() or int(voice.priority) >= int(foreground.priority): foreground = voice
		for voice in _voices:
			if voice.active:
				if voice == foreground: _release_voice(voice)
				else: _stop_voice(voice)
	elif rank >= 100:
		for voice in _voices:
			if voice.active and int(voice.priority) < rank: _release_voice(voice)
	var free: Dictionary = {}
	for voice in _voices:
		if not voice.active:
			free = voice
			break
	if free.is_empty():
		var victim: Dictionary = _voices[0]
		for voice in _voices:
			if int(voice.priority) < int(victim.priority): victim = voice
		if int(victim.priority) > rank and not meaningful: return false
		_stop_voice(victim)
		free = victim
	free.active = true
	free.remaining = stream.get_length()
	free.release = 0.0
	free.priority = rank
	free.gain = level
	free.cue = cue
	free.player.stream = stream
	free.player.volume_db = level
	free.player.play()
	peak_voices = maxi(peak_voices, active_voice_count())
	var record := {"session": session, "identity": identity, "cue": cue, "role": role,
		"gain_db": level, "priority": rank, "reduced": reduced,
		"voices": active_voice_count(), "target": target.duplicate(true)}
	if trace_enabled: trace.append(record.duplicate(true))
	cue_started.emit(record)
	return true

func _release_voice(voice: Dictionary) -> void:
	if voice.release > 0.0: return
	# A frame-driven 8 ms tween can skip its entire envelope at 60 Hz. Author
	# the short release in PCM instead, using the already imported SFX samples.
	# Only this owned tail is shortened; ordinary playback keeps the whole WAV.
	var source: AudioStreamWAV = voice.player.stream
	var position: float = voice.player.get_playback_position() + AudioServer.get_time_since_last_mix()
	var first := clampi(int(position * source.mix_rate), 0, source.data.size() / 2)
	var frames := mini(int(RELEASE_SECONDS * source.mix_rate), source.data.size() / 2 - first)
	if frames <= 1:
		_stop_voice(voice)
		return
	var pcm := source.data.slice(first * 2, (first + frames) * 2)
	for frame in frames:
		var sample := int(round(float(pcm.decode_s16(frame * 2)) * float(frames - 1 - frame) / float(frames - 1)))
		pcm.encode_s16(frame * 2, sample)
	var tail := AudioStreamWAV.new()
	tail.format = AudioStreamWAV.FORMAT_16_BITS
	tail.mix_rate = source.mix_rate
	tail.stereo = false
	tail.data = pcm
	voice.player.stop()
	voice.player.stream = tail
	voice.player.play()
	voice.release = float(frames) / source.mix_rate
	voice.remaining = voice.release

func _stop_voice(voice: Dictionary) -> void:
	voice.player.stop()
	voice.player.stream = null
	voice.active = false
	voice.remaining = 0.0
	voice.release = 0.0

func _stop_sfx() -> void:
	for voice in _voices: _stop_voice(voice)

func active_voice_count() -> int:
	var count := 0
	for voice in _voices:
		if voice.active: count += 1
	return count

func _process(delta: float) -> void:
	if not automatic_timing or _closed: return
	# Native playback owns real-time lifetimes. The frame delta may precede a
	# cue started by input this frame; subtracting it would truncate that new WAV.
	for voice in _voices:
		if voice.active and not voice.player.playing: _stop_voice(voice)
	_advance_loops(delta)

func advance_audio(delta: float) -> void:
	if _closed or delta < 0.0: return
	for voice in _voices:
		if not voice.active: continue
		voice.remaining -= delta
		if voice.release > 0.0:
			voice.release = maxf(0.0, float(voice.release) - delta)
			if voice.release <= 0.0: _stop_voice(voice)
		if voice.active and voice.remaining <= 0.0: _stop_voice(voice)
	_advance_loops(delta)

func _advance_loops(delta: float) -> void:
	if _interrupted or not _music_enabled(): return
	for slot in _music: _advance_loop(slot, delta)
	if not _ambience.is_empty(): _advance_loop(_ambience, delta)

func apply_settings(values: Dictionary) -> void:
	if _closed: return
	var was_enabled := _sfx_enabled()
	for key in _settings:
		if values.has(key): _settings[key] = values[key]
	_settings.music_volume = clampf(float(_settings.music_volume), 0.0, 1.0)
	_settings.sfx_volume = clampf(float(_settings.sfx_volume), 0.0, 1.0)
	if was_enabled and not _sfx_enabled():
		_batch.clear()
		_stop_sfx()
	if _initialized:
		_apply_buses()
		_reconcile_loops()

func _sfx_enabled() -> bool:
	return not _closed and not _interrupted and bool(_settings.enabled) and not bool(_settings.sfx_muted) and float(_settings.sfx_volume) > 0.0

func _music_enabled() -> bool:
	return not _closed and not _interrupted and bool(_settings.enabled) and not bool(_settings.music_muted) and float(_settings.music_volume) > 0.0

func _apply_buses() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), SFX_HEADROOM_DB + linear_to_db(maxf(0.00001, _settings.sfx_volume)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(maxf(0.00001, _settings.music_volume)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), not _sfx_enabled())
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), not _music_enabled())

func set_context(context: String, crypt := false) -> void:
	if _closed: return
	_initialize_players()
	_context = context
	_crypt = crypt and context != "screen_home" and context != ""
	_desired_music = ""
	_desired_ambience = ""
	for id in _loops:
		var entry: Dictionary = _loops[id]
		if entry.get("status") not in ["delivered", "available"]: continue
		if entry.get("stream") == null and str(entry.get("runtime_path", "")).is_empty(): continue
		if not context in entry.contexts: continue
		if id == "crypt":
			if _crypt: _desired_ambience = id
		else: _desired_music = id
	_reconcile_loops()

func _reconcile_loops() -> void:
	var selected: Dictionary = {}
	for slot in _music:
		if slot.cue == _desired_music and not _desired_music.is_empty(): selected = slot
	if selected.is_empty() and not _desired_music.is_empty():
		selected = _music[0] if float(_music[0].level) <= float(_music[1].level) else _music[1]
		_start_loop(selected, _desired_music, "music")
	for slot in _music:
		_retarget_loop(slot, 1.0 if slot == selected else 0.0)
		_pause_loop(slot)
	if not _desired_ambience.is_empty() and _ambience.cue != _desired_ambience:
		_start_loop(_ambience, _desired_ambience, "ambience")
	_retarget_loop(_ambience, 0.0 if _desired_ambience.is_empty() else 1.0)
	_pause_loop(_ambience)

func _start_loop(slot: Dictionary, cue: String, kind: String) -> void:
	var stream := _load_stream(_loops[cue])
	if stream == null: return
	slot.player.stop()
	slot.player.stream = stream
	slot.cue = cue
	slot.level = 0.0
	slot.target = 0.0
	slot.player.volume_db = -80.0
	slot.player.play()
	loop_starts[kind] += 1

func _load_stream(entry: Dictionary) -> AudioStream:
	# Injected streams exist only in isolated tests. Production metadata contains
	# shipped paths; the scene owns this cache rather than static script constants.
	if entry.get("stream") is AudioStream: return entry.stream
	var path := str(entry.get("runtime_path", ""))
	if path.is_empty(): return null
	if not _streams.has(path): _streams[path] = load(path)
	return _streams[path] as AudioStream

func _retarget_loop(slot: Dictionary, target: float) -> void:
	if slot.is_empty() or float(slot.target) == target: return
	slot.start = slot.level
	slot.target = target
	slot.elapsed = 0.0

func _pause_loop(slot: Dictionary) -> void:
	if slot.is_empty(): return
	if not _music_enabled() and slot.target == 0.0:
		_stop_loop(slot)
	else: slot.player.stream_paused = not _music_enabled()

func _advance_loop(slot: Dictionary, delta: float) -> void:
	if slot.cue.is_empty(): return
	slot.elapsed = minf(float(slot.seconds), float(slot.elapsed) + delta)
	slot.level = lerpf(float(slot.start), float(slot.target), float(slot.elapsed) / float(slot.seconds))
	slot.player.volume_db = float(_loops[slot.cue].gain_db) + linear_to_db(maxf(0.00001, slot.level))
	if slot.elapsed >= slot.seconds and slot.target == 0.0: _stop_loop(slot)

func _stop_loop(slot: Dictionary) -> void:
	slot.player.stop()
	slot.player.stream = null
	slot.cue = ""
	slot.level = 0.0
	slot.target = 0.0

func loop_snapshot() -> Dictionary:
	var music: Array = []
	for slot in _music:
		music.append({"cue": slot.cue, "level": slot.level, "target": slot.target,
			"position": slot.player.get_playback_position(), "paused": slot.player.stream_paused})
	return {"context": _context, "music": music, "ambience": {} if _ambience.is_empty() else {
		"cue": _ambience.cue, "level": _ambience.level, "target": _ambience.target,
		"position": _ambience.player.get_playback_position(), "paused": _ambience.player.stream_paused},
		"starts": loop_starts.duplicate(), "interrupted": _interrupted}

func set_interrupted(interrupted: bool) -> void:
	if _closed or _interrupted == interrupted: return
	_interrupted = interrupted
	if interrupted:
		_batch.clear()
		_stop_sfx()
	if _initialized:
		_apply_buses()
		_reconcile_loops()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT: _focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN: _focused = true
		NOTIFICATION_APPLICATION_PAUSED: _suspended = true
		NOTIFICATION_APPLICATION_RESUMED: _suspended = false
		_: return
	set_interrupted(not _focused or _suspended or not _visible_owner)

func dispose() -> void:
	if _closed: return
	_closed = true
	var owner := get_parent()
	if owner is CanvasItem and owner.visibility_changed.is_connected(_owner_visibility_changed):
		owner.visibility_changed.disconnect(_owner_visibility_changed)
	session += 1
	_batch.clear()
	_desired_music = ""
	_desired_ambience = ""
	_context = ""
	_disconnect_all()
	_controller = null
	_presenter = null
	_stop_sfx()
	for slot in _music: _stop_loop(slot)
	if not _ambience.is_empty(): _stop_loop(_ambience)
	_streams.clear()
	_loops.clear()
	set_process(false)

func _exit_tree() -> void:
	dispose()
