extends RefCounted

# Local RC-005 observation data. The controller calls record once after execution
# and before presentation; this object never executes gameplay or uses its RNG.
# Preparation time is elapsed monotonic wall time from the initial/next-turn
# authoritative snapshot to an accepted Cast/Pass outcome. It includes thinking,
# edits, techniques, rejected attempts and presentation time; it is not CPU time.
# Edit counts count accepted commands, including no-ops and undo, not meaningful
# layout changes. Card summaries report composition and emptiness, not usability.
const SCHEMA_VERSION := 1
const EDIT_KINDS := ["place_wire", "place_rune", "erase", "rotate", "flip", "undo"]

var _clock: Callable
var _session_started := 0
var _turn_started := 0
var _last_time := 0
var _document: Dictionary
var _latest_result := {}
var _seen_actions := {}
var _default_path := ""
var _export_serial := 0

func _init(setup: Dictionary, initial_snapshot: Dictionary, clock: Callable = Callable()) -> void:
	_clock = clock
	_session_started = _now()
	_turn_started = _session_started
	var experiment: Dictionary = setup.get("experiment", {}).duplicate(true)
	var edits := {}
	for kind in EDIT_KINDS:
		edits[kind] = 0
	_document = {
		"schema_version": SCHEMA_VERSION,
		"experiment": experiment,
		"configuration_fingerprint": JSON.stringify(setup, "", true).sha256_text(),
		"seed": setup.get("encounter", {}).get("seed", experiment.get("seed", 0)),
		"starting_setup": setup.duplicate(true),
		"initial_state": _state(initial_snapshot),
		"commands": [], "lifecycle": [], "notes": [],
		"totals": {"attempts": 0, "accepted": 0, "rejected": 0,
			"edits": 0, "edits_by_kind": edits, "casts": 0, "passes": 0,
			"techniques": 0, "damage": 0, "shield": 0, "blocked": 0,
			"retaliation": 0, "cost": 0, "transitions": 0, "outcomes": []}
	}
	var identity := "%s-%s" % [experiment.get("scenario_id", "experiment"), experiment.get("variant_id", "session")]
	# IDs in validated fixtures are safe, but sanitize the default filename too.
	identity = identity.validate_filename().replace(" ", "_")
	_default_path = "user://experiments/%s-%d-%d.json" % [identity, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]

func _now() -> int:
	var value := int(_clock.call()) if _clock.is_valid() else Time.get_ticks_msec()
	_last_time = maxi(_last_time, value)
	return _last_time

func record(result: Dictionary, arguments: Dictionary = {}) -> bool:
	var accepted: bool = result.get("accepted", false)
	if accepted:
		var key := "%s:%s" % [result.get("encounter_id", 0), result.get("action_id", 0)]
		if _seen_actions.has(key):
			return false
		_seen_actions[key] = true
	if result.has("encounter_id"):
		_latest_result = result.duplicate(true)
	var before: Dictionary = result.get("before", {})
	var after: Dictionary = result.get("after", before)
	var now := _now()
	var name := str(result.get("command", ""))
	var kind := "erase" if name == "place_wire" and arguments.get("kind") == "erase" else name
	var totals: Dictionary = _document.totals
	totals.attempts += 1
	if accepted:
		totals.accepted += 1
		if kind in EDIT_KINDS:
			totals.edits += 1
			totals.edits_by_kind[kind] += 1
		if name == "cast": totals.casts += 1
		if name == "pass": totals.passes += 1
		if name == "technique": totals.techniques += 1
	else:
		totals.rejected += 1
	var metrics := {"damage": 0, "shield": 0, "blocked": 0, "retaliation": 0, "cost": 0, "hits": []}
	var events: Array = result.get("events", []) if accepted else []
	for event in events:
		match event.get("type", ""):
			"damage":
				if event.get("target") == "enemy":
					metrics.damage += int(event.get("applied", 0))
					metrics.hits.append({"amount": event.get("amount", 0), "applied": event.get("applied", 0), "hit_index": event.get("hit_index", 0)})
			"shield": metrics.shield += int(event.get("amount", 0))
			"retaliation":
				metrics.retaliation += int(event.get("applied", 0))
				metrics.blocked += int(event.get("blocked", 0))
			"cast", "technique": metrics.cost += int(event.get("energy_before", 0)) - int(event.get("energy_after", 0))
			"battle_ended":
				totals.outcomes.append({"state": event.get("state"), "encounter_id": after.get("encounter_id", 0), "encounter_number": after.get("encounter_number", 1), "turn": after.get("turn", 1)})
			"encounter_transition": totals.transitions += 1
	for metric in ["damage", "shield", "blocked", "retaliation", "cost"]:
		totals[metric] += metrics[metric]
	var entry := {
		"attempt": totals.attempts, "command": name, "kind": kind,
		"arguments": arguments.duplicate(true), "accepted": accepted,
		"action_id": result.get("action_id", 0),
		"encounter_id": before.get("encounter_id", result.get("encounter_id", 0)),
		"encounter_number": before.get("encounter_number", 1), "turn": before.get("turn", 1),
		"elapsed_ms": now - _session_started, "turn_elapsed_ms": now - _turn_started,
		"cumulative_edits": totals.edits, "metrics": metrics,
		"before": _state(before), "after": _state(after), "events": events.duplicate(true)
	}
	if not accepted:
		entry.rejection = result.get("rejection", "model_rejected")
	if accepted and name in ["cast", "pass"]:
		entry.preparation_ms = now - _turn_started
	_document.commands.append(entry)
	if accepted and (before.get("turn") != after.get("turn") or before.get("encounter_id") != after.get("encounter_id") or before.get("encounter_number", 1) != after.get("encounter_number", 1)):
		_turn_started = now
	return true

func record_guard_rejection(name: String, arguments: Dictionary, snapshot: Dictionary, reason: String) -> void:
	record({"accepted": false, "command": name, "action_id": 0, "before": snapshot,
		"after": snapshot, "events": [], "rejection": reason}, arguments)

func record_restart(before: Dictionary, after: Dictionary) -> void:
	var now := _now()
	_latest_result.clear()
	_document.lifecycle.append({"type": "restart_rng_continues", "elapsed_ms": now - _session_started,
		"before": _state(before), "after": _state(after)})
	_turn_started = now

func add_note(note: String) -> void:
	if not note.strip_edges().is_empty():
		_document.notes.append({"text": note, "elapsed_ms": _now() - _session_started})

func summary() -> Dictionary:
	return _document.totals.duplicate(true)

func document() -> Dictionary:
	return _document.duplicate(true)

func latest_result() -> Dictionary:
	return _latest_result.duplicate(true)

func default_path() -> String:
	return _default_path

func _state(snapshot: Dictionary) -> Dictionary:
	var state := {}
	for key in ["encounter_id", "encounter_content_id", "encounter_number", "turn", "state", "player_hp", "enemy_hp", "energy", "stock", "undo_count"]:
		if snapshot.has(key): state[key] = snapshot[key]
	var board: Array = snapshot.get("board", [])
	var layout := board.duplicate(true)
	for piece in layout: piece.erase("uid")
	state.circuit = {"cells": board.duplicate(true), "forecast": snapshot.get("forecast", {}).duplicate(true),
		"layout_fingerprint": JSON.stringify(layout, "", true).sha256_text()}
	var catalog: Dictionary = snapshot.get("catalog", {})
	for key in ["hand", "draw_pile", "discard_pile"]:
		var cards: Array = snapshot.get(key, [])
		var counts := {"total": cards.size(), "permanent_runes": 0, "temporary_runes": 0, "techniques": 0}
		var by_definition := {}
		for card in cards:
			var definition: Dictionary = catalog.get(card.id, {})
			by_definition[card.id] = int(by_definition.get(card.id, 0)) + 1
			if definition.get("type") == "technique": counts.techniques += 1
			elif definition.get("temporary", false): counts.temporary_runes += 1
			else: counts.permanent_runes += 1
		state[key] = {"cards": cards.duplicate(true), "counts": counts, "by_definition": by_definition, "empty": cards.is_empty()}
	return state.duplicate(true)

# Publish through a sibling temporary file, retaining the old complete record
# until the new file is flushed. A failed replacement restores the backup.
# No failure throws or affects authoritative gameplay; the UI shows `error`.
func export_record(path: String = "") -> Dictionary:
	var destination := _default_path if path.is_empty() else path
	if not destination.ends_with(".json"):
		return _failure(destination, "Observation path must end in .json.")
	var absolute := ProjectSettings.globalize_path(destination)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if directory_error != OK:
		return _failure(destination, "Cannot create observation directory: %s" % error_string(directory_error))
	_export_serial += 1
	var temporary := "%s.tmp-%d-%d" % [absolute, Time.get_ticks_usec(), _export_serial]
	var backup := temporary + ".previous"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _failure(destination, "Cannot open observation output: %s" % error_string(FileAccess.get_open_error()))
	file.store_string(JSON.stringify(_document, "\t", true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return _failure(destination, "Cannot write observation output: %s" % error_string(write_error))
	var had_previous := FileAccess.file_exists(absolute)
	if had_previous:
		var backup_error := DirAccess.rename_absolute(absolute, backup)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary)
			return _failure(destination, "Cannot preserve previous observation: %s" % error_string(backup_error))
	var publish_error := DirAccess.rename_absolute(temporary, absolute)
	if publish_error != OK:
		var recovery_error := OK
		if had_previous: recovery_error = DirAccess.rename_absolute(backup, absolute)
		DirAccess.remove_absolute(temporary)
		var message := "Cannot publish observation: %s" % error_string(publish_error)
		if recovery_error != OK: message += "; previous complete record remains at %s" % backup
		return _failure(destination, message)
	if had_previous: DirAccess.remove_absolute(backup)
	return {"ok": true, "error": "", "path": absolute}

func _failure(path: String, message: String) -> Dictionary:
	return {"ok": false, "error": message, "path": path}
