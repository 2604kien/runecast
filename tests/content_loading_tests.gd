extends RefCounted

const Loader = preload("res://scripts/core/content_loader.gd")
const Circuit = preload("res://scripts/core/circuit.gd")

static func documents(encounter_path: String = Loader.DEFAULT_ENCOUNTER) -> Dictionary:
	var result := {}
	for kind in Loader.DEFINITION_PATHS:
		result[kind] = Loader.read_document(Loader.DEFINITION_PATHS[kind]).document
	result.encounter = Loader.read_document(encounter_path).document
	return result

func run(check: Callable) -> void:
	var training := Loader.load_setup()
	check.call(training.ok and training.errors.is_empty(), "Training files validate before battle creation.")
	var alternate := Loader.load_setup("res://data/dev_encounter.json")
	check.call(alternate.ok and alternate.setup.encounter.name == "Calibration Wisp" and alternate.setup.encounter.player_health == 24 and alternate.setup.encounter.player_max_health == 40 and alternate.setup.inventory == {"split": 2, "join": 0}, "Development fixture resolves its own enemy, player and inventory definitions.")
	var original := documents()
	var retained := original.duplicate(true)
	var validated := Loader.validate_documents(original)
	validated.setup.catalog.spark.cost = 20
	validated.setup.encounter.intents.clear()
	validated.setup.board.clear()
	validated.setup.owned_cards.clear()
	check.call(original == retained and Loader.validate_documents(original).setup == training.setup, "Validation normalization and returned setup share no mutable collections with source documents.")
	var defaults := documents()
	defaults.encounter.erase("seed")
	defaults.encounter.erase("opening_log")
	defaults.loadouts[0].erase("current_health")
	validated = Loader.validate_documents(defaults)
	check.call(validated.ok and validated.setup.encounter.seed == 42 and validated.setup.encounter.opening_log == defaults.encounter.help_text and validated.setup.encounter.player_health == 30 and validated.setup.catalog.spark.temporary == false and validated.setup.catalog.spark.board_label == "Spark" and validated.setup.board[0].rotation == 0, "Only documented omitted fields receive defaults; normalization preserves presentation labels.")
	var incomplete := documents()
	incomplete.boards[0].placements = [{"cell": 0, "kind": "begin"}, {"cell": 14, "kind": "end"}]
	validated = Loader.validate_documents(incomplete)
	check.call(validated.ok and not Circuit.evaluate(validated.setup.board, validated.setup.catalog).valid, "An editable but incomplete starting circuit is valid content.")
	var draw_policy := documents()
	draw_policy.loadouts[0].opening_policy = "draw"
	draw_policy.loadouts[0].erase("opening_hand")
	draw_policy.loadouts[0].opening_draw = 4
	validated = Loader.validate_documents(draw_policy)
	check.call(validated.ok and validated.setup.opening_hand.is_empty() and validated.setup.opening_draw == 4, "Draw opening policy normalizes to an empty curated hand and explicit opening count.")
	var missing := Loader.load_setup("res://tests/fixtures/does_not_exist.json")
	check.call(not missing.ok and missing.setup.is_empty() and _has(missing, "does_not_exist.json: cannot read file"), "Missing encounter files return actionable paths without fallback setup.")
	var unreadable := Loader.load_setup("res://data")
	check.call(not unreadable.ok and unreadable.setup.is_empty() and _has(unreadable, "cannot read file"), "Unreadable file paths fail without constructing playable data.")
	var malformed := Loader.load_setup("res://tests/fixtures/malformed_content.json")
	check.call(not malformed.ok and malformed.setup.is_empty() and _has(malformed, "malformed_content.json: JSON line"), "Malformed JSON reports its source path, parser line and reason.")
	var missing_catalog := Loader.load_setup(Loader.DEFAULT_ENCOUNTER, {"runes": "res://tests/fixtures/does_not_exist.json"})
	check.call(not missing_catalog.ok and missing_catalog.setup.is_empty(), "Definition-file failures cannot silently retain the training catalog.")
	var unsupported_source := Loader.load_setup(Loader.DEFAULT_ENCOUNTER, {"future_schema": "res://data/runes.json"})
	check.call(not unsupported_source.ok and _has(unsupported_source, "definition_paths.future_schema"), "Unsupported source overrides are diagnosed.")
	var named := documents()
	named.runes[0].cost = -1
	validated = Loader.validate_documents(named, {"runes": "res://example/runes.json"})
	check.call(_has(validated, "res://example/runes.json [spark].cost:"), "Validation diagnostics include source file, stable content ID and field.")
	var cases := [
		["Wrong definition root", func(d): d.runes = {}, "runes: expected an array"],
		["Wrong encounter root", func(d): d.encounter = [], "encounter: expected an object"],
		["Non-object definition", func(d): d.enemies[0] = 7, "enemies[0]: expected an object"],
		["Empty definition array", func(d): d.runes = [], "definitions must not be empty"],
		["Missing required field", func(d): d.runes[0].erase("cost"), "[spark].cost:"],
		["Duplicate definition ID", func(d): d.runes.append(d.runes[0].duplicate(true)), "duplicate definition ID"],
		["Malformed content ID", func(d): d.runes[0].id = "Bad ID", "IDs use lowercase"],
		["Fractional cost", func(d): d.runes[0].cost = 1.5, "[spark].cost:"],
		["String numeric field", func(d): d.runes[0].cost = "2", "[spark].cost:"],
		["Boolean numeric field", func(d): d.runes[0].cost = true, "[spark].cost:"],
		["Nonfinite numeric field", func(d): d.runes[0].value = INF, "[spark].value:"],
		["Negative value", func(d): d.runes[0].value = -1, "[spark].value:"],
		["Wrong boolean type", func(d): d.runes[4].temporary = "true", "[free_spark].temporary:"],
		["Malformed color", func(d): d.runes[0].color = "blueish", "[spark].color:"],
		["Empty display name", func(d): d.enemies[0].name = " ", "[shadeling].name:"],
		["Empty board label", func(d): d.runes[4].board_label = "", "[free_spark].board_label:"],
		["Unsupported rune type", func(d): d.runes[0].type = "relic", "[spark].type:"],
		["Wrong rune type value", func(d): d.runes[0].type = 2, "[spark].type:"],
		["Wrong effect type", func(d): d.runes[0].effect = true, "[spark].effect:"],
		["Unsupported effect family", func(d): d.runes[0].effect = "damage_shield", "[spark].effect:"],
		["Unknown technique effect", func(d): d.runes[3].effect = "typo", "techniques support only draw or conjure"],
		["Rune/technique effect mismatch", func(d): d.runes[0].effect = "draw", "effect runes support only damage or shield"],
		["Temporary technique", func(d): d.runes[2].temporary = true, "temporary techniques are unsupported"],
		["Charged temporary rune", func(d): d.runes[4].cost = 1, "temporary runes must have zero cost"],
		["Unknown generated target", func(d): d.runes[3].generated_rune_id = "missing", "unknown rune ID 'missing'"],
		["Missing generated target", func(d): d.runes[3].erase("generated_rune_id"), "[conjure].generated_rune_id:"],
		["Permanent generated target", func(d): d.runes[3].generated_rune_id = "spark", "generated target must be a temporary"],
		["Technique generated target", func(d): d.runes[3].generated_rune_id = "focus", "generated target must be a temporary"],
		["Ignored generator on draw", func(d): d.runes[2].generated_rune_id = "free_spark", "only conjure techniques accept"],
		["Too-large technique count", func(d): d.runes[3].value = 21, "[conjure].value:"],
		["Zero maximum health", func(d): d.enemies[0].max_health = 0, "[shadeling].max_health:"],
		["Excess current health", func(d): d.loadouts[0].current_health = 31, "cannot exceed max_health"],
		["Nonliving initial player", func(d): d.loadouts[0].current_health = 0, "[starter].current_health:"],
		["Negative energy", func(d): d.loadouts[0].energy_per_turn = -1, "[starter].energy_per_turn:"],
		["Excess draw count", func(d): d.loadouts[0].draw_per_turn = 21, "[starter].draw_per_turn:"],
		["Fractional draw count", func(d): d.loadouts[0].draw_per_turn = 2.5, "[starter].draw_per_turn:"],
		["Empty intent sequence", func(d): d.enemies[0].intents = [], "expected 1 to 100 scalar attack values"],
		["Structured future intent", func(d): d.enemies[0].intents[0] = {"damage": 8}, ".intents[0]:"],
		["Negative intent", func(d): d.enemies[0].intents[0] = -1, ".intents[0]:"],
		["Fractional intent", func(d): d.enemies[0].intents[0] = 0.5, ".intents[0]:"],
		["Unknown enemy reference", func(d): d.encounter.enemy_id = "missing", ".enemy_id: unknown ID"],
		["Unknown board reference", func(d): d.encounter.board_id = "missing", ".board_id: unknown ID"],
		["Unknown loadout reference", func(d): d.encounter.loadout_id = "missing", ".loadout_id: unknown ID"],
		["Fractional seed", func(d): d.encounter.seed = 42.5, ".seed:"],
		["Negative seed", func(d): d.encounter.seed = -1, ".seed:"],
		["Unsupported dimensions", func(d): d.boards[0].width = 5, "[board_training].width:"],
		["Unsupported obstacles", func(d): d.boards[0].obstacles = [4], ".obstacles: unsupported field"],
		["Unsupported ports", func(d): d.boards[0].placements[1].ports = [1], ".ports: unsupported field"],
		["Wrong placements type", func(d): d.boards[0].placements = {}, ".placements: expected an array"],
		["Wrong placement type", func(d): d.boards[0].placements[1] = 1, ".placements[1]: expected an object"],
		["Invalid cell", func(d): d.boards[0].placements[1].cell = 16, ".cell:"],
		["Fractional cell", func(d): d.boards[0].placements[1].cell = 1.2, ".cell:"],
		["Duplicate cell", func(d): d.boards[0].placements.append(d.boards[0].placements[1].duplicate(true)), "duplicate cell"],
		["Unsupported piece", func(d): d.boards[0].placements[1].kind = "obstacle", ".kind: unsupported piece"],
		["Wrong piece kind type", func(d): d.boards[0].placements[0].kind = 2, ".kind: unsupported piece"],
		["Out-of-range rotation", func(d): d.boards[0].placements[1].rotation = 4, ".rotation:"],
		["Wrong endpoint rotation type", func(d): d.boards[0].placements[0].rotation = "0", ".rotation:"],
		["Wrong rune rotation type", func(d): d.boards[0].placements[1].rotation = {}, ".rotation:"],
		["Invalid reversal type", func(d): d.boards[0].placements[3].reversed = "false", ".reversed: expected a boolean"],
		["Invalid reversal object", func(d): d.boards[0].placements[3].reversed = {}, ".reversed: expected a boolean"],
		["Unsupported reversal", func(d): d.boards[0].placements[1].reversed = true, "only straight and corner"],
		["Moved endpoint", func(d): d.boards[0].placements[0].cell = 4, "endpoints require Begin at cell 0"],
		["Rotated endpoint", func(d): d.boards[0].placements[0].rotation = 1, "endpoints require Begin at cell 0"],
		["Missing endpoint", func(d): d.boards[0].placements.remove_at(0), "explicit Begin at cell 0"],
		["Unknown installed rune", func(d): d.boards[0].placements[1].rune_id = "missing", "unknown rune ID 'missing'"],
		["Installed technique", func(d): d.boards[0].placements[1].rune_id = "focus", "only effect runes can be installed"],
		["Unowned installed rune", func(d): d.boards[0].placements[1].rune_id = "shield"; d.loadouts[0].owned_cards = ["spark", "shield", "conjure"], "opening allocation exceeds owned"],
		["Unknown owned card", func(d): d.loadouts[0].owned_cards[0] = "missing", "unknown rune ID 'missing'"],
		["Owned temporary", func(d): d.loadouts[0].owned_cards.append("free_spark"), "temporary cards cannot belong"],
		["Unowned opening card count", func(d): d.loadouts[0].opening_hand = ["spark", "spark", "spark"], "opening allocation exceeds owned"],
		["Unknown opening policy", func(d): d.loadouts[0].opening_policy = "randomish", ".opening_policy:"],
		["Ignored opening draw field", func(d): d.loadouts[0].opening_draw = 1, "curated policy uses opening_hand"],
		["Wrong inventory type", func(d): d.loadouts[0].inventory = [], ".inventory: expected an object"],
		["Negative inventory", func(d): d.loadouts[0].inventory.split = -1, ".inventory.split:"],
		["Installed pieces exceed stock", func(d): d.loadouts[0].inventory.split = 0, "board installs 1 split pieces"],
		["Unknown inventory kind", func(d): d.loadouts[0].inventory.obstacle = 1, ".inventory.obstacle: unsupported field"]
	]
	for item in cases:
		var data := documents()
		item[1].call(data)
		var result := Loader.validate_documents(data)
		check.call(not result.ok and result.setup.is_empty() and _has(result, item[2]), item[0] + " is rejected with a useful field diagnostic and no partial setup.")
	draw_policy.loadouts[0].opening_draw = 9
	validated = Loader.validate_documents(draw_policy)
	check.call(not validated.ok and _has(validated, "cannot draw 9 opening cards from 8"), "Opening draw cannot exceed remaining ownership after board allocation.")
	var zero_effects := documents()
	zero_effects.runes[2].value = 0
	zero_effects.runes[3].value = 0
	zero_effects.loadouts[0].energy_per_turn = 0
	zero_effects.loadouts[0].draw_per_turn = 0
	check.call(Loader.validate_documents(zero_effects).ok, "Zero costs/counts and zero per-turn resources are valid explicit values.")

static func _has(result: Dictionary, text: String) -> bool:
	return result.errors.any(func(error): return text in error)
