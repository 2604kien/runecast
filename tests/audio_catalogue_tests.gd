extends RefCounted
## Development-only parity audit: production does not read documentation JSON.
const Catalogue = preload("res://scripts/audio/audio_catalogue.gd")

func run(check: Callable) -> void:
	var sfx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audio-cue-catalogue.json"))
	check.call(Catalogue.SFX.size() == int(sfx.expected_runtime_files), "Shipped catalogue includes exactly the delivered SFX count.")
	var actors := {}
	var families := {}
	for cue in sfx.cues:
		var id := str(cue.cue_id)
		check.call(Catalogue.SFX.has(id), "Shipped SFX contains " + id)
		if not Catalogue.SFX.has(id): continue
		var shipped: Dictionary = Catalogue.SFX[id]
		var stream := ResourceLoader.load(shipped.runtime_path) as AudioStreamWAV
		check.call(stream != null and shipped.runtime_path == "res://" + str(cue.runtime_path), id + " explicitly references its current runtime WAV.")
		check.call(is_equal_approx(float(shipped.gain_db), float(cue.intended_gain_db)), id + " gain matches the source contract.")
		check.call(shipped.priority == cue.priority and shipped.future_only == cue.future_only and shipped.manifest_id == cue.manifest_id, id + " priority and ownership metadata match.")
		check.call(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, id + " is a one-shot.")
		families[cue.manifest_id] = true
		for binding in cue.bindings:
			if binding.has("actor_id"): actors[binding.actor_id] = id
	check.call(families.size() == int(sfx.expected_manifest_families), "Shipped SFX preserves all 16 stable manifest families.")
	check.call(actors == Catalogue.ACTORS, "Actor variants use the exact supplied actor IDs, without a fallback.")
	check.call(Catalogue.SFX.edit_restore.manifest_id == "sfx_undo", "Remove preserves the historical sfx_undo manifest ID.")
	var loops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/audio-loop-catalogue.json"))
	check.call(Catalogue.LOOPS.size() == loops.cues.size(), "Shipped loop catalogue includes all availability records.")
	for cue in loops.cues:
		var id := str(cue.cue_id)
		check.call(Catalogue.LOOPS.has(id), "Shipped loops contain " + id)
		if not Catalogue.LOOPS.has(id): continue
		var shipped: Dictionary = Catalogue.LOOPS[id]
		check.call(shipped.status == cue.status and shipped.contexts == cue.contexts and is_equal_approx(float(shipped.gain_db), float(cue.intended_gain_db)), id + " retains availability, contexts and default gain.")
		if cue.runtime_available:
			var stream := ResourceLoader.load(shipped.runtime_path) as AudioStreamOggVorbis
			check.call(stream != null and shipped.runtime_path == "res://" + str(cue.runtime_path), id + " uses the delivered compressed stream.")
			check.call(stream != null and stream.loop and is_equal_approx(stream.loop_offset, float(cue.loop_offset_seconds)), id + " preserves imported loop metadata.")
		else:
			check.call(shipped.runtime_path.is_empty() and not ResourceLoader.exists("res://" + str(cue.runtime_path)), id + " remains a no-music state without an invented resource.")
	check.call(not Catalogue.LOOPS.crypt.contexts.has("screen_home"), "Home has no automatic crypt ambience binding.")
