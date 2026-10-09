extends RefCounted

# Catalog coverage shares the RC-007 generator and geometry suite. These checks
# establish identity-independent mechanics, not arbitrary-hand solvability.
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const ContentTests = preload("res://tests/production_content_tests.gd")
const FIXTURES := {
	"board_training": "res://data/development/rc009_training_encounter.json",
	"board_gallery": "res://data/development/rc009_gallery_encounter.json",
	"board_ossuary": "res://data/development/rc009_ossuary_encounter.json",
	"board_belfry": "res://data/development/rc009_belfry_encounter.json"
}

func run(check: Callable) -> void:
	var raw := ContentTests.documents()
	var loaded := Loader.load_setup()
	check.call(loaded.ok, "Board catalog starts from the unchanged normal production encounter.")
	if not loaded.ok:
		return
	var ids: Array = raw.boards.map(func(board): return board.id)
	var expected := FIXTURES.keys()
	expected.append("dev_entry_board")
	ids.sort()
	expected.sort()
	check.call(ids == expected, "Production board catalog has exactly the four stable board IDs and the preserved development-only entry board.")
	check.call(loaded.setup.encounter.board_id == "board_training" and Loader.DEFAULT_ENCOUNTER == "res://data/production_encounter.json", "Normal launch remains training_shadeling on board_training; development identity launches are opt-in.")
	var entry := Loader.load_setup("res://data/production_next_encounter.json")
	check.call(entry.ok and entry.setup.encounter.board_id == "dev_entry_board" and entry.setup.board[15] == {"kind": "begin", "rotation": 2} and entry.setup.board[1] == {"kind": "end", "rotation": 0}, "The historical RC-007 development successor and its authored endpoint placeholders are preserved.")
	var setups := {}
	for id in FIXTURES:
		var fixture := Loader.load_setup(FIXTURES[id])
		check.call(fixture.ok and fixture.setup.encounter.board_id == id, "%s loads through its actual development encounter file and resolves the intended definition." % id)
		if not fixture.ok:
			continue
		setups[id] = fixture.setup
		check.call(fixture.setup.production == loaded.setup.production and fixture.setup.catalog == loaded.setup.catalog and fixture.setup.owned_cards == loaded.setup.owned_cards and fixture.setup.encounter.enemy_id == "shadeling" and fixture.setup.encounter.loadout_id == "starter", "%s shares the accepted production profile, rune catalog, enemy and starter loadout without a copied catalog or balance override." % id)
		check.call(fixture.setup.encounter.title.begins_with("DEV /") and fixture.setup.encounter.help_text.begins_with("Development board identity:") and fixture.setup.encounter.energy_per_turn == 3 and fixture.setup.opening_draw == 3 and fixture.setup.opening_hand.is_empty(), "%s is visibly labeled development content and keeps normal three-card draws and three energy." % id)
		check.call(_only_endpoints(fixture.setup.board) and fixture.setup.catalog.values().all(func(rune): return rune.get("port_shape", "straight") == "straight"), "%s validates as sixteen cells with only Begin/End and no alternate effect ports." % id)
		_malformed(check, raw, fixture.setup.production, id)
		_sampling(check, loaded.setup, fixture.setup, raw, id)
		_rejections(check, fixture.setup, id)
	if setups.size() == FIXTURES.size():
		_encounter_entry(check, setups)

func _only_endpoints(board: Array) -> bool:
	return board.size() == 16 and board.filter(func(piece): return piece.get("kind") == "begin").size() == 1 and board.filter(func(piece): return piece.get("kind") == "end").size() == 1 and board.filter(func(piece): return piece.is_empty()).size() == 14

func _mechanics(game: Combat) -> Dictionary:
	var snapshot := game.snapshot()
	# Only content identity and presentation strings differ between these setups.
	for key in ["encounter", "encounter_content_id", "encounter_title", "encounter_help_text", "log_text"]:
		snapshot.erase(key)
	snapshot.random_states = [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
	snapshot.next_uid = game.next_uid
	snapshot.history = game.history.duplicate(true)
	return snapshot

func _permanents(game: Combat) -> Array:
	var instances: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].temporary:
			instances.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].temporary:
			instances.append({"id": piece.rune_id, "uid": piece.uid})
	instances.sort_custom(func(first, second): return first.uid < second.uid)
	return instances

func _malformed(check: Callable, raw: Dictionary, options: Dictionary, id: String) -> void:
	var cases := [
		["missing board id", func(d, i): d.boards[i].erase("id")],
		["invalid board id", func(d, i): d.boards[i].id = "Bad Board ID"],
		["duplicate board id", func(d, i): d.boards.append(d.boards[i].duplicate(true))],
		["missing referenced board", func(d, i): d.boards.remove_at(i)],
		["unknown board reference", func(d, _i): d.encounter.board_id = "missing_board"],
		["missing encounter board reference", func(d, _i): d.encounter.erase("board_id")],
		["incorrect width", func(d, i): d.boards[i].width = 5],
		["incorrect height", func(d, i): d.boards[i].height = 3],
		["malformed placements", func(d, i): d.boards[i].placements = {}],
		["missing End", func(d, i): d.boards[i].placements.pop_back()],
		["duplicate endpoint cell", func(d, i): d.boards[i].placements[1].cell = d.boards[i].placements[0].cell],
		["out-of-bounds endpoint", func(d, i): d.boards[i].placements[0].cell = 16],
		["blocked cell", func(d, i): d.boards[i].placements.append({"cell": 5, "kind": "blocked"})],
		["prefilled connector", func(d, i): d.boards[i].placements.append({"cell": 5, "kind": "straight"})],
		["prefilled effect", func(d, i): d.boards[i].placements.append({"cell": 5, "kind": "rune", "rune_id": "spark"})],
		["unconsumed metadata", func(d, i): d.boards[i].teaching_role = "introductory"],
		["alternate effect ports", func(d, _i): d.runes[0].port_shape = "corner"]
	]
	for entry in cases:
		var documents := raw.duplicate(true)
		documents.encounter.board_id = id
		var index: int = documents.boards.map(func(board): return board.id).find(id)
		entry[1].call(documents, index)
		var before := documents.duplicate(true)
		var invalid := Loader.validate_documents(documents, {}, null, options)
		check.call(not invalid.ok and invalid.setup.is_empty() and not invalid.errors.is_empty() and documents == before, "%s rejects %s before construction, with diagnostics and no input mutation." % [id, entry[0]])

func _sampling(check: Callable, source: Dictionary, fixture: Dictionary, raw: Dictionary, id: String) -> void:
	var documents := raw.duplicate(true)
	documents.encounter = Loader.read_document(FIXTURES[id]).document
	var index: int = documents.boards.map(func(board): return board.id).find(id)
	documents.boards[index].placements = [{"cell": 15, "kind": "begin", "rotation": 1}, {"cell": 1, "kind": "end", "rotation": 0}]
	documents.encounter.title = "Different presentation title"
	documents.encounter.help_text = "Different presentation help"
	documents.encounter.opening_log = "Different presentation log"
	var changed := Loader.validate_documents(documents, {}, null, fixture.production)
	check.call(changed.ok, "%s accepts legal alternate endpoint placeholders for the generator-independence check." % id)
	if not changed.ok:
		return
	var equal_openings := true
	var equal_successors := true
	var equal_restarts := true
	var detached_reads := true
	var clear_entries := true
	for seed in range(64):
		var reference := Combat.new(source, seed)
		var game := Combat.new(fixture, seed)
		var alternate := Combat.new(changed.setup, seed)
		equal_openings = _mechanics(game) == _mechanics(reference) and _mechanics(alternate) == _mechanics(reference) and equal_openings
		clear_entries = _only_endpoints(game.board) and _only_endpoints(alternate.board) and clear_entries
		var before := _mechanics(game)
		var exposed := game.snapshot()
		exposed.board.clear()
		exposed.kit.totals.straight = 99
		exposed.encounter.title = "Mutated detached view"
		game.forecast()
		detached_reads = _mechanics(game) == before and detached_reads
		var passed: bool = reference.execute("pass").accepted and game.execute("pass").accepted and alternate.execute("pass").accepted
		equal_successors = passed and _mechanics(game) == _mechanics(reference) and _mechanics(alternate) == _mechanics(reference) and equal_successors
		clear_entries = _only_endpoints(game.board) and _only_endpoints(alternate.board) and clear_entries
		for restart in range(2):
			reference.reset()
			game.reset()
			alternate.reset()
			equal_restarts = _mechanics(game) == _mechanics(reference) and _mechanics(alternate) == _mechanics(reference) and equal_restarts
			clear_entries = _only_endpoints(game.board) and _only_endpoints(alternate.board) and clear_entries
	check.call(equal_openings, "%s: 64 seeds produce the same opening endpoints/rotations, kits, normal hands and three RNG states as normal production, regardless of identity, metadata or legal placeholder coordinates." % id)
	check.call(equal_successors and clear_entries, "%s: ordinary Pass keeps the same successor sampling and endpoints-only turn entry as normal production for all 64 seeds." % id)
	check.call(equal_restarts, "%s: two continuing-stream Restarts per seed remain mechanically identical to normal production without metadata RNG consumption." % id)
	check.call(detached_reads, "%s: forecast and detached snapshot inspection cannot alter board, kit, history, instance allocation or random streams." % id)

func _rejections(check: Callable, setup: Dictionary, id: String) -> void:
	var game := Combat.new(setup)
	var controller := Controller.new(game)
	var endpoint := -1
	for index in range(game.board.size()):
		if game.board[index].get("kind") == "begin":
			endpoint = index
	var cases := [
		["place_wire", {"index": endpoint, "kind": "straight"}],
		["place_wire", {"index": endpoint, "kind": "erase"}],
		["place_wire", {"index": -1, "kind": "corner"}],
		["place_rune", {"index": endpoint, "uid": game.hand[0].uid}],
		["flip", {"index": endpoint}],
		["rotate", {"index": 16}],
		["undo", {}],
		["unknown_command", {}]
	]
	var before := _mechanics(game)
	var unchanged := true
	for action in cases:
		unchanged = not controller.command(action[0], action[1]) and _mechanics(game) == before and unchanged
	check.call(unchanged, "%s: rejected protected/out-of-range/unknown actions and empty Undo leave state, stock, ownership and every RNG unchanged through the actual controller." % id)
	controller.dispose()

func _encounter_entry(check: Callable, setups: Dictionary) -> void:
	# Explicit validator-owned edge case: one-HP Shadeling predecessor. This
	# isolates successful transfer; it is not an ordinary encounter-win claim.
	var documents := ContentTests.documents()
	documents.encounter = Loader.read_document(FIXTURES.board_training).document
	documents.encounter.id = "dev_rc009_transition_predecessor"
	documents.enemies[0].max_health = 1
	var validated := Loader.validate_documents(documents, {}, null, setups.board_training.production)
	check.call(validated.ok, "The explicit one-HP transition predecessor is validated before model construction; production fixture difficulty is unchanged.")
	if not validated.ok:
		return
	var reference_entry := {}
	for id in FIXTURES:
		var source: Dictionary = validated.setup.duplicate(true)
		var next := Loader.validate_transition(source, setups[id])
		check.call(next.ok, "%s is compatible as the bounded successor using existing catalogs and starter ownership." % id)
		if not next.ok:
			continue
		source.next_encounter = next.setup
		var game := Combat.new(source)
		var controller := Controller.new(game)
		var owned := _permanents(game)
		# Seed 294 naturally draws Spark UID 0 at Begin0/End2; only enemy HP is
		# controlled. The route uses the same normal Rotate/place/Cast commands.
		var built := controller.command("rotate", {"index": 0}) and controller.command("rotate", {"index": 0}) and controller.command("place_rune", {"index": 1, "uid": 0})
		var won := built and controller.command("cast") and game.state == "victory"
		check.call(won and _permanents(game) == owned and game.hand.is_empty() and _only_endpoints(game.board), "%s transition predecessor wins through legal construction/Cast and terminal cleanup conserves all permanent instances." % id)
		var before_health := game.player_hp
		var entered := controller.command("next_encounter")
		check.call(entered and game.encounter.board_id == id and game.encounter.id == setups[id].encounter.id and game.turn == 1 and game.state == "playing" and _only_endpoints(game.board), "%s enters through the real next_encounter command with its intended identity and fourteen empty cells." % id)
		check.call(game.player_hp == before_health and game.player_hp == 30 and _permanents(game) == owned and game.hand.size() == 3 and game.energy == 3 and game.snapshot().stock == game.snapshot().kit.totals and game.history.is_empty(), "%s encounter entry carries HP and exactly eight permanent UIDs, normally draws three, and supplies one full kit with cleared Undo." % id)
		if reference_entry.is_empty():
			reference_entry = _mechanics(game)
		check.call(_mechanics(game) == reference_entry, "%s encounter entry consumes the same card/endpoint/kit streams as every other board identity." % id)
		var before := _mechanics(game)
		check.call(not controller.command("next_encounter") and _mechanics(game) == before, "%s rejects a repeated transition without state or RNG mutation." % id)
		controller.dispose()
