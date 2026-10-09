extends RefCounted

const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")

static func documents() -> Dictionary:
	return {
		"runes": Loader.read_document("res://data/runes.json").document,
		"enemies": Loader.read_document("res://data/enemies.json").document,
		"boards": Loader.read_document("res://data/production_boards.json").document,
		"loadouts": Loader.read_document("res://data/production_loadouts.json").document,
		"encounter": Loader.read_document(Loader.DEFAULT_ENCOUNTER).document}

func run(check: Callable) -> void:
	var options := Rules.production_options(Rules.load_rules().rules)
	var raw := documents()
	var retained := raw.duplicate(true)
	var loaded := Loader.load_setup()
	check.call(loaded.ok and loaded.setup.has("production") and not loaded.setup.has("experiment"), "Default loading validates the selected production profile, separately from historical experiments.")
	if not loaded.ok:
		return
	check.call(loaded.setup.encounter.id == "training_shadeling" and loaded.setup.encounter.board_id == "board_training" and loaded.setup.encounter.energy_per_turn == 3 and loaded.setup.opening_draw == 3 and loaded.setup.opening_hand.is_empty(), "Production preserves stable content IDs and uses three energy with a normal three-card opening draw.")
	check.call(Loader.validate_documents(raw, {}, null, options).setup == loaded.setup and raw == retained, "Production file and pure document validation agree without mutating input documents.")
	check.call(not Loader.validate_documents(raw).ok, "Production markers cannot silently enter legacy content validation.")
	check.call(not Loader.validate_documents(raw, {}, Loader.experiment_options("effects", "control").setup, options).ok, "Production and experiment contexts cannot be mixed.")
	var malformed := [
		["missing profile", func(d): d.encounter.erase("ruleset")],
		["unknown profile", func(d): d.encounter.ruleset = "future"],
		["unresolved successor", func(d): d.encounter.next_encounter = "res://data/production_next_encounter.json"],
		["prefilled wire", func(d): d.boards[0].placements.append({"cell": 5, "kind": "straight"})],
		["prefilled effect", func(d): d.boards[0].placements.append({"cell": 5, "kind": "rune", "rune_id": "spark"})],
		["blocked cell", func(d): d.boards[0].placements.append({"cell": 5, "kind": "blocked"})],
		["extra Begin", func(d): d.boards[0].placements.append({"cell": 5, "kind": "begin"})],
		["missing End", func(d): d.boards[0].placements.pop_back()],
		["same endpoint cell", func(d): d.boards[0].placements[1].cell = 0],
		["outside board", func(d): d.boards[0].placements[1].cell = 16],
		["endpoint flip", func(d): d.boards[0].placements[0].reversed = true],
		["corner effect", func(d): d.runes[0].port_shape = "corner"],
		["independent authored stock", func(d): d.loadouts[0].inventory = {"straight": 99}],
		["curated opening", func(d): d.loadouts[0].opening_policy = "curated"; d.loadouts[0].erase("opening_draw"); d.loadouts[0].opening_hand = ["spark"]],
		["different opening count", func(d): d.loadouts[0].opening_draw = 2]
	]
	for entry in malformed:
		var document := raw.duplicate(true)
		entry[1].call(document)
		var before := document.duplicate(true)
		var invalid := Loader.validate_documents(document, {}, null, options)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty() and document == before, "Production rejects %s before construction, without repairing input or returning a partial setup." % entry[0])
	for field in options:
		var bad := options.duplicate(true)
		bad.erase(field)
		var invalid := Loader.validate_documents(raw, {}, null, bad)
		check.call(not invalid.ok and invalid.setup.is_empty(), "Production rejects a missing contract field: " + field)
	for entry in [["split_cost", 2], ["join_cost", 1], ["damage_mode", "multi_hit"], ["effects", "persistent"], ["endpoint_rotation", "locked"], ["unexpected", true]]:
		var bad := options.duplicate(true)
		bad[entry[0]] = entry[1]
		check.call(not Loader.validate_documents(raw, {}, null, bad).ok, "Production rejects an unselected contract override: " + entry[0])
	var all_pairs := true
	for begin in range(16):
		for end in range(16):
			if begin == end:
				continue
			var document := raw.duplicate(true)
			document.boards[0].placements = [{"cell": begin, "kind": "begin", "rotation": 3}, {"cell": end, "kind": "end", "rotation": 2}]
			all_pairs = Loader.validate_documents(document, {}, null, options).ok and all_pairs
	check.call(all_pairs, "Production validation accepts every distinct endpoint pair, adjacency and outward-facing authored directions.")
	var empty := raw.duplicate(true)
	empty.loadouts[0].owned_cards = []
	check.call(Loader.validate_documents(empty, {}, null, options).ok, "Production permits an empty permanent pool and normal draws that yield fewer cards.")
	var straight := raw.duplicate(true)
	straight.runes[0].port_shape = "straight"
	check.call(Loader.validate_documents(straight, {}, null, options).ok, "Production permits an explicitly straight effect definition.")
	var exposed: Dictionary = loaded.setup
	exposed.production.kits.kits[0].totals.straight = 99
	exposed.board.clear()
	check.call(Loader.load_setup().setup.board.size() == 16 and Loader.load_setup().setup.production.kits == Rules.load_rules().rules and raw == retained, "Returned production setup and nested kit definitions cannot mutate future loads or their source.")
	_transition_checks(check)

func _transition_checks(check: Callable) -> void:
	var fixture := Loader.load_setup("res://data/production_transition_encounter.json")
	check.call(fixture.ok and fixture.setup.has("next_encounter") and not fixture.setup.next_encounter.has("next_encounter"), "The bounded encounter-entry fixture resolves exactly one validated successor before initialization.")
	if not fixture.ok:
		return
	var first: Dictionary = fixture.setup
	var next: Dictionary = first.next_encounter
	check.call(next.encounter.energy_per_turn == 4 and next.encounter.draw_per_turn == 2 and next.encounter.player_max_health == 40 and next.encounter.player_health == 24 and next.encounter.board_id == "dev_entry_board", "The successor fixture supplies distinct board metadata, resource values and authored health for testing carried-health precedence.")
	var validated := Loader.validate_transition(first, next)
	validated.setup.encounter.max_health = 999
	check.call(next.encounter.max_health == 45 and Loader.validate_transition(first, next).ok, "Successor validation returns detached values without changing either cached setup.")
	for entry in [
		["legacy profile", func(d): d.erase("production")],
		["experiment profile", func(d): d.experiment = {}],
		["nested transition", func(d): d.next_encounter = {}],
		["different collection", func(d): d.owned_cards.pop_back()],
		["different effect catalog", func(d): d.catalog.spark.value = 999],
		["same identity", func(d): d.encounter.id = first.encounter.id]
	]:
		var candidate := next.duplicate(true)
		entry[1].call(candidate)
		var before := candidate.duplicate(true)
		var rejected := Loader.validate_transition(first, candidate)
		check.call(not rejected.ok and rejected.setup.is_empty() and candidate == before, "Successor rejects %s without partial reconciliation or input mutation." % entry[0])
	# File tests remain under a unique QA directory and cannot replace study data.
	var directory := "res://output/qa/rc-007/implementation/invalid-entry-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(directory)
	for entry in [["missing", "res://tests/fixtures/missing-successor.json"], ["legacy", Loader.LEGACY_ENCOUNTER], ["nested", "res://data/production_transition_encounter.json"], ["invalid_type", 3]]:
		var raw: Dictionary = Loader.read_document(Loader.DEFAULT_ENCOUNTER).document
		raw.next_encounter = entry[1]
		var path := directory.path_join(entry[0] + ".json")
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(raw))
		file.close()
		var invalid := Loader.load_setup(path)
		check.call(not invalid.ok and invalid.setup.is_empty(), "File setup refuses %s successor configuration before constructing a model." % entry[0])
