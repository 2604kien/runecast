class_name RuneContentLoader
extends RefCounted

# File I/O, schema validation and normalization complete before a model is built.
const ProductionRules = preload("res://scripts/core/production_rules.gd")
const DEFAULT_ENCOUNTER := "res://data/production_encounter.json"
const LEGACY_ENCOUNTER := "res://data/encounter.json"
const DEFINITION_PATHS := {
	"runes": "res://data/runes.json", "boards": "res://data/boards.json",
	"enemies": "res://data/enemies.json", "loadouts": "res://data/loadouts.json"
}
const MAX_CARDS := 100
const MAX_TURN_AMOUNT := 20
const MAX_HEALTH := 100000
const EXPERIMENT_VERSION := "rc005_v1"
const FULL_RESET_EXPERIMENT_VERSION := "rc006_full_reset_v1"
const MOVING_ENDPOINT_EXPERIMENT_VERSION := "rc006_moving_endpoints_v1"
const FREE_ENDPOINT_EXPERIMENT_VERSION := "rc006_free_endpoints_v1"
const MOVING_ENDPOINT_PATHS := [
	[0, 1, 2, 6, 10, 14], [3, 7, 11, 15, 14, 13],
	[12, 8, 4, 0, 1, 2], [15, 14, 13, 9, 5, 1],
	[1, 5, 9, 10, 11, 7], [14, 10, 6, 2, 3, 7, 11],
	[4, 5, 6, 7, 11, 15], [10, 9, 8, 4, 0]
]
const EXPERIMENT_VARIANTS := {
	"effects": ["control", "treatment", "full_reset", "moving_endpoints", "free_endpoints"], "split_inventory": ["control", "treatment"],
	"split_cost": ["control", "treatment"], "endpoints": ["control", "treatment"],
	"blocked": ["control", "treatment"], "ports": ["control", "treatment"],
	"hits": ["control", "treatment"], "expiry": ["control", "retained", "empty"],
	"encounters": ["control", "treatment"]
}

# Explicit context is separate from normal JSON loading: content cannot opt
# itself into experimental capabilities by adding an encounter field.
static func experiment_options(scenario_id: Variant, variant_id: Variant, seed: Variant = 42) -> Dictionary:
	var errors: Array = []
	if not scenario_id is String or not EXPERIMENT_VARIANTS.has(scenario_id):
		_error(errors, "experiment.scenario_id", "unknown scenario")
	elif not variant_id is String or not variant_id in EXPERIMENT_VARIANTS[scenario_id]:
		_error(errors, "experiment.variant_id", "unknown variant for '%s'" % scenario_id)
	_number(seed, 0, 2147483647, "experiment.seed", errors)
	if not errors.is_empty():
		return _result(errors)
	var options := {"scenario_id": scenario_id, "variant_id": variant_id,
		"version": EXPERIMENT_VERSION, "seed": int(seed), "effects": "persistent",
		"split_cost": 1, "damage_mode": "aggregate", "expiry": "straight", "transfer": "none"}
	if scenario_id == "effects" and variant_id == "treatment":
		options.effects = "consumed"
	if scenario_id == "effects" and variant_id in ["full_reset", "moving_endpoints", "free_endpoints"]:
		# Additive RC-006 follow-up. Do not add keys to, or relabel, old fixtures.
		options.version = FULL_RESET_EXPERIMENT_VERSION
		options.effects = "discard_all"
		options.expiry = "empty"
		options.board_reset = "each_turn"
		if variant_id == "moving_endpoints":
			options.version = MOVING_ENDPOINT_EXPERIMENT_VERSION
			options.endpoint_policy = "random_each_turn"
			# Include the complete bounded geometry in the configuration fingerprint.
			# These witness paths are facilitator/test data, never participant hints.
			options.endpoint_layouts = moving_endpoint_layouts()
			_validate_endpoint_layouts(options.endpoint_layouts, errors)
		if variant_id == "free_endpoints":
			options.version = FREE_ENDPOINT_EXPERIMENT_VERSION
			options.endpoint_policy = "random_any_cells"
			options.endpoint_rotation = "player"
			options.endpoint_initial = "random"
			# Compact, versioned selection contract; no bounded route catalog.
			options.endpoint_selection = "uniform_ordered_pairs_v1"
			options.endpoint_position_pairs = 240
			options.endpoint_successor_pairs = 211
	if scenario_id == "split_cost" and variant_id == "treatment":
		options.split_cost = 2
	if scenario_id == "hits" and variant_id == "treatment":
		options.damage_mode = "multi_hit"
	if scenario_id == "expiry" and variant_id != "control":
		options.expiry = variant_id
	if scenario_id == "encounters":
		options.transfer = "reset" if variant_id == "control" else "retain"
	return _result(errors, options)

static func free_endpoint_pairs(previous_begin: int = -1, previous_end: int = -1) -> Array:
	var pairs: Array = []
	for begin in range(16):
		for end in range(16):
			if begin != end and begin != previous_begin and end != previous_end:
				pairs.append([begin, end])
	return pairs

static func moving_endpoint_layouts() -> Array:
	var layouts: Array = []
	for index in range(MOVING_ENDPOINT_PATHS.size()):
		var path: Array = MOVING_ENDPOINT_PATHS[index].duplicate()
		layouts.append({"id": "route_" + "abcdefgh"[index], "path": path,
			"begin": {"cell": path[0], "rotation": (_path_direction(path[0], path[1]) + 3) % 4},
			"end": {"cell": path[-1], "rotation": _path_direction(path[-1], path[-2])}})
	return layouts

static func _path_direction(from_cell: int, to_cell: int) -> int:
	var delta := Vector2i(to_cell % 4 - from_cell % 4, to_cell / 4 - from_cell / 4)
	return [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)].find(delta)

static func _validate_endpoint_layouts(layouts: Array, errors: Array) -> void:
	# Validate the versioned catalog itself as well as requiring supplied metadata
	# to match it exactly. A path proves connectivity without using Split/Join.
	var identities := {}
	var opening_successors := 0
	for layout in layouts:
		var field: String = "experiment.endpoint_layouts." + str(layout.id)
		if identities.has(layout.id):
			_error(errors, field, "layout ID must be unique")
		identities[layout.id] = true
		if layout.begin.cell != 0 and layout.end.cell != 14:
			opening_successors += 1
		var path: Array = layout.path
		var seen := {}
		var has_straight := false
		if path.size() < 4:
			_error(errors, field, "witness needs an interior straight rune socket")
		for step in range(path.size()):
			var cell: int = path[step]
			if cell < 0 or cell > 15 or seen.has(cell):
				_error(errors, field, "witness must be an in-bounds simple path")
			seen[cell] = true
			if step > 0 and _path_direction(path[step - 1], cell) < 0:
				_error(errors, field, "witness steps must be adjacent")
			if step > 0 and step < path.size() - 1:
				if _path_direction(path[step - 1], cell) == _path_direction(cell, path[step + 1]):
					has_straight = true
		if not has_straight:
			_error(errors, field, "witness needs an interior straight rune socket")
		var successors := 0
		for candidate in layouts:
			if candidate.begin.cell != layout.begin.cell and candidate.end.cell != layout.end.cell:
				successors += 1
		if successors == 0:
			_error(errors, field, "must allow a successor moving both endpoints")
	if opening_successors == 0:
		_error(errors, "experiment.endpoint_layouts", "must allow a successor from the fixed opening")

static func validate_experiment(context: Variant) -> Dictionary:
	if not context is Dictionary:
		return _result(["experiment: expected an explicit options object"])
	var expected := experiment_options(context.get("scenario_id"), context.get("variant_id"), context.get("seed"))
	if not expected.ok:
		return expected
	var errors: Array = []
	_fields(context, expected.setup.keys(), "experiment", errors)
	for key in expected.setup:
		if not _matches(context.get(key), expected.setup[key]):
			_error(errors, "experiment." + key, "expected %s for this version/scenario/variant" % str(expected.setup[key]))
	return _result(errors, expected.setup)

static func load_setup(encounter_path: String = DEFAULT_ENCOUNTER, definition_paths: Dictionary = {}) -> Dictionary:
	return _load_setup(encounter_path, definition_paths, false)

static func _load_setup(encounter_path: String, definition_paths: Dictionary, successor: bool) -> Dictionary:
	var selected := read_document(encounter_path)
	if not selected.ok:
		return _result(selected.errors)
	var production: Variant = null
	var next_path := ""
	var paths := DEFINITION_PATHS.duplicate()
	var errors: Array = []
	if selected.document is Dictionary and selected.document.has("ruleset"):
		if not _matches(selected.document.ruleset, ProductionRules.PRODUCTION_VERSION):
			return _result([encounter_path + ".ruleset: unsupported production ruleset"])
		var rules := ProductionRules.load_rules()
		if not rules.ok:
			return _result(rules.errors)
		production = ProductionRules.production_options(rules.rules)
		paths.boards = "res://data/production_boards.json"
		paths.loadouts = "res://data/production_loadouts.json"
		if selected.document.has("next_encounter"):
			if successor:
				return _result([encounter_path + ".next_encounter: only one successor is supported"])
			var candidate: Variant = selected.document.next_encounter
			if not candidate is String or not candidate.begins_with("res://") or not candidate.ends_with(".json"):
				return _result([encounter_path + ".next_encounter: expected a res:// JSON encounter path"])
			next_path = candidate
			# File-based chaining is resolved here before model construction. The
			# pure document validator never leaves an unresolved successor path.
			selected.document = selected.document.duplicate(true)
			selected.document.erase("next_encounter")
	for key in definition_paths:
		if not paths.has(key):
			errors.append("definition_paths.%s: unsupported definition source" % key)
		elif not definition_paths[key] is String or definition_paths[key].is_empty():
			errors.append("definition_paths.%s: expected a nonempty file path" % key)
		else:
			paths[key] = definition_paths[key]
	paths.encounter = encounter_path
	var documents := {"encounter": selected.document}
	for key in paths:
		if key == "encounter":
			continue
		var loaded := read_document(paths[key])
		if loaded.ok:
			documents[key] = loaded.document
		else:
			errors.append_array(loaded.errors)
	if not errors.is_empty():
		return _result(errors)
	var result := validate_documents(documents, paths, null, production)
	if result.ok and not next_path.is_empty():
		var next := _load_setup(next_path, definition_paths, true)
		if not next.ok:
			return next
		var compatible := validate_transition(result.setup, next.setup)
		if not compatible.ok:
			return compatible
		result.setup.next_encounter = compatible.setup
	return result

static func read_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "errors": ["%s: cannot read file (%s)" % [path, error_string(FileAccess.get_open_error())]]}
	var source := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return {"ok": false, "errors": ["%s: cannot read file (%s)" % [path, error_string(read_error)]]}
	var parser := JSON.new()
	var parse_error := parser.parse(source)
	if parse_error != OK:
		return {"ok": false, "errors": ["%s: JSON line %d: %s" % [path, parser.get_error_line(), parser.get_error_message()]]}
	return {"ok": true, "errors": [], "document": parser.data}

static func validate_documents(documents: Dictionary, source_names: Dictionary = {}, experiment_context: Variant = null, production_context: Variant = null) -> Dictionary:
	var errors: Array = []
	var experiment := {}
	var production := {}
	if production_context != null:
		if experiment_context != null:
			return _result(["production: cannot combine production and experiment contexts"])
		var validated := ProductionRules.validate_production(production_context)
		if not validated.ok:
			return _result(validated.errors)
		production = validated.rules
	if experiment_context != null:
		var validated_experiment := validate_experiment(experiment_context)
		if not validated_experiment.ok:
			return validated_experiment
		experiment = validated_experiment.setup
	_fields(documents, ["runes", "boards", "enemies", "loadouts", "encounter"], "documents", errors)
	var definitions := {}
	for kind in ["runes", "boards", "enemies", "loadouts"]:
		definitions[kind] = _index(documents.get(kind), str(source_names.get(kind, kind)), errors)
	var catalog: Dictionary = definitions.runes
	var rules: Dictionary = experiment if production.is_empty() else production
	for id in catalog:
		_validate_rune(catalog[id], _context(source_names, "runes", id), errors, rules)
	for id in catalog:
		var rune: Dictionary = catalog[id]
		if _matches(rune.get("effect"), "conjure") and rune.get("generated_rune_id") is String:
			var target_id: String = rune.generated_rune_id
			var field := _context(source_names, "runes", id) + ".generated_rune_id"
			if not catalog.has(target_id):
				_error(errors, field, "unknown rune ID '%s'" % target_id)
			else:
				var target: Dictionary = catalog[target_id]
				if not _matches(target.get("type"), "rune") or not _matches(target.get("temporary"), true) or not _matches(target.get("cost"), 0):
					_error(errors, field, "generated target must be a temporary effect rune with zero cost")
	var boards := {}
	for id in definitions.boards:
		boards[id] = _validate_board(definitions.boards[id], catalog, _context(source_names, "boards", id), errors, rules)
	for id in definitions.enemies:
		_validate_enemy(definitions.enemies[id], _context(source_names, "enemies", id), errors)
	for id in definitions.loadouts:
		_validate_loadout(definitions.loadouts[id], catalog, _context(source_names, "loadouts", id), errors, production)
	var encounter_source := str(source_names.get("encounter", "encounter"))
	var entry: Variant = documents.get("encounter")
	if not entry is Dictionary:
		_error(errors, encounter_source, "expected an object")
		return _result(errors)
	var encounter: Dictionary = entry.duplicate(true)
	var context := "%s [%s]" % [encounter_source, encounter.get("id", "?")]
	var encounter_fields := ["id", "enemy_id", "board_id", "loadout_id", "title", "help_text", "opening_log", "seed"]
	if not production.is_empty():
		encounter_fields.append("ruleset")
		if not _matches(encounter.get("ruleset"), ProductionRules.PRODUCTION_VERSION):
			_error(errors, context + ".ruleset", "must name the selected production version")
	_fields(encounter, encounter_fields, context, errors)
	_id(encounter.get("id"), context + ".id", errors)
	for field in ["title", "help_text"]:
		_string(encounter.get(field), context + "." + field, errors)
	if not encounter.has("opening_log"):
		encounter.opening_log = encounter.get("help_text", "")
	_string(encounter.get("opening_log"), context + ".opening_log", errors)
	_integer(encounter, "seed", 0, 2147483647, context, errors, 42)
	if not experiment.is_empty() and not _matches(encounter.get("seed"), experiment.seed):
		_error(errors, context + ".seed", "must match explicit experiment.seed")
	for reference in [["enemy_id", "enemies"], ["board_id", "boards"], ["loadout_id", "loadouts"]]:
		var id: Variant = encounter.get(reference[0])
		if _id(id, context + "." + reference[0], errors) and not definitions[reference[1]].has(id):
			_error(errors, context + "." + reference[0], "unknown ID '%s'" % id)
	# Only use normalized values after all structural/type/reference checks pass.
	if not errors.is_empty():
		return _result(errors)
	var enemy: Dictionary = definitions.enemies[encounter.enemy_id]
	var loadout: Dictionary = definitions.loadouts[encounter.loadout_id]
	var board: Array = boards[encounter.board_id]
	var available: Array = loadout.owned_cards.duplicate()
	for index in range(loadout.opening_hand.size()):
		_allocate(available, loadout.opening_hand[index], _context(source_names, "loadouts", loadout.id) + ".opening_hand[%d]" % index, errors)
	var installed := {}
	for kind in loadout.inventory:
		installed[kind] = 0
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if installed.has(piece.get("kind")):
			installed[piece.kind] += 1
		elif piece.get("kind") == "rune" and not catalog[piece.rune_id].temporary:
			_allocate(available, piece.rune_id, _context(source_names, "boards", encounter.board_id) + ".placements(cell=%d).rune_id" % index, errors)
	for kind in installed:
		if installed[kind] > loadout.inventory[kind]:
			_error(errors, context + ".loadout_id", "board installs %d %s pieces, but loadout inventory owns %d" % [installed[kind], kind, loadout.inventory[kind]])
	if production.is_empty() and loadout.opening_draw > available.size():
		_error(errors, _context(source_names, "loadouts", loadout.id) + ".opening_draw", "cannot draw %d opening cards from %d remaining owned cards" % [loadout.opening_draw, available.size()])
	if not errors.is_empty():
		return _result(errors)
	encounter.name = enemy.name
	encounter.max_health = enemy.max_health
	encounter.intents = enemy.intents
	encounter.player_health = loadout.current_health
	encounter.player_max_health = loadout.max_health
	encounter.energy_per_turn = loadout.energy_per_turn
	encounter.draw_per_turn = loadout.draw_per_turn
	var setup := {"catalog": catalog, "encounter": encounter, "board": board,
		"owned_cards": loadout.owned_cards, "opening_hand": loadout.opening_hand,
		"opening_draw": loadout.opening_draw, "inventory": loadout.inventory}
	if not experiment.is_empty():
		setup.experiment = experiment
	if not production.is_empty():
		setup.production = production
	return _result([], setup)

# Both inputs are normalized configurations from validation, never raw files.
# Runtime ownership reconciliation remains the model's exact-instance check.
static func validate_transition(current_setup: Dictionary, next_setup: Dictionary) -> Dictionary:
	var errors: Array = []
	for candidate in [current_setup, next_setup]:
		var validated := ProductionRules.validate_production(candidate.get("production"))
		if not validated.ok or candidate.has("experiment"):
			errors.append("next_encounter: both setups must use validated production rules")
	if next_setup.has("next_encounter") or next_setup.get("encounter", {}).has("next_encounter"):
		errors.append("next_encounter: nested successors are unsupported")
	if current_setup.get("catalog", {}) != next_setup.get("catalog", {}):
		errors.append("next_encounter: rune catalogs must be compatible")
	var current_owned: Array = current_setup.get("owned_cards", []).duplicate()
	var next_owned: Array = next_setup.get("owned_cards", []).duplicate()
	current_owned.sort()
	next_owned.sort()
	if current_owned != next_owned:
		errors.append("next_encounter: permanent ownership multisets must match")
	if current_setup.get("encounter", {}).get("id") == next_setup.get("encounter", {}).get("id"):
		errors.append("next_encounter: successor requires a distinct encounter ID")
	return _result(errors, next_setup)

static func _validate_rune(rune: Dictionary, context: String, errors: Array, experiment: Dictionary = {}) -> void:
	var allowed := ["id", "name", "board_label", "symbol", "type", "effect", "value", "cost", "color", "temporary", "generated_rune_id"]
	if experiment.get("scenario_id") in ["ports", "expiry"] or experiment.get("version") == ProductionRules.PRODUCTION_VERSION:
		allowed.append("port_shape")
	_fields(rune, allowed, context, errors)
	if rune.has("port_shape"):
		if experiment.get("version") == ProductionRules.PRODUCTION_VERSION and not _matches(rune.port_shape, "straight"):
			_error(errors, context + ".port_shape", "production effects require straight ports")
		if not rune.get("port_shape") in ["straight", "corner"] or not _matches(rune.get("type"), "rune"):
			_error(errors, context + ".port_shape", "only effect runes support straight or corner port shapes")
	for field in ["name", "symbol", "type", "effect", "color"]:
		_string(rune.get(field), context + "." + field, errors)
	if not rune.has("board_label"):
		rune.board_label = rune.get("name", "")
	_string(rune.get("board_label"), context + ".board_label", errors)
	_integer(rune, "cost", 0, MAX_TURN_AMOUNT, context, errors)
	_integer(rune, "value", 0, 10000, context, errors)
	_boolean(rune, "temporary", context, errors, false)
	if rune.get("color") is String and not Color.html_is_valid(rune.color):
		_error(errors, context + ".color", "expected an HTML color such as #efb553")
	match rune.get("type"):
		"rune":
			if not rune.get("effect") in ["damage", "shield"]:
				_error(errors, context + ".effect", "effect runes support only damage or shield")
			if _matches(rune.get("temporary"), true) and not _matches(rune.get("cost"), 0):
				_error(errors, context + ".cost", "temporary runes must have zero cost")
		"technique":
			if not rune.get("effect") in ["draw", "conjure"]:
				_error(errors, context + ".effect", "techniques support only draw or conjure")
			if _matches(rune.get("temporary"), true):
				_error(errors, context + ".temporary", "temporary techniques are unsupported")
			_integer(rune, "value", 0, MAX_TURN_AMOUNT, context, errors)
		_:
			_error(errors, context + ".type", "supported types are rune and technique")
	if _matches(rune.get("type"), "technique") and _matches(rune.get("effect"), "conjure"):
		_id(rune.get("generated_rune_id"), context + ".generated_rune_id", errors)
	elif rune.has("generated_rune_id"):
		_error(errors, context + ".generated_rune_id", "only conjure techniques accept a generated target")

static func _validate_enemy(enemy: Dictionary, context: String, errors: Array) -> void:
	_fields(enemy, ["id", "name", "max_health", "intents"], context, errors)
	_string(enemy.get("name"), context + ".name", errors)
	_integer(enemy, "max_health", 1, MAX_HEALTH, context, errors)
	if not enemy.get("intents") is Array or enemy.intents.is_empty() or enemy.intents.size() > MAX_CARDS:
		_error(errors, context + ".intents", "expected 1 to 100 scalar attack values")
		return
	for index in range(enemy.intents.size()):
		if _number(enemy.intents[index], 0, MAX_HEALTH, context + ".intents[%d]" % index, errors):
			enemy.intents[index] = int(enemy.intents[index])

static func _validate_loadout(loadout: Dictionary, catalog: Dictionary, context: String, errors: Array, production: Dictionary = {}) -> void:
	var fields := ["id", "max_health", "current_health", "energy_per_turn", "draw_per_turn", "owned_cards", "opening_policy", "opening_hand", "opening_draw"]
	if production.is_empty():
		fields.append("inventory")
	_fields(loadout, fields, context, errors)
	_integer(loadout, "max_health", 1, MAX_HEALTH, context, errors)
	if not loadout.has("current_health"):
		loadout.current_health = loadout.get("max_health")
	_integer(loadout, "current_health", 1, MAX_HEALTH, context, errors)
	if _is_integer(loadout.get("current_health")) and _is_integer(loadout.get("max_health")) and loadout.current_health > loadout.max_health:
		_error(errors, context + ".current_health", "cannot exceed max_health")
	_integer(loadout, "energy_per_turn", 0, MAX_TURN_AMOUNT, context, errors)
	_integer(loadout, "draw_per_turn", 0, MAX_TURN_AMOUNT, context, errors)
	_card_ids(loadout.get("owned_cards"), catalog, context + ".owned_cards", errors)
	match loadout.get("opening_policy"):
		"curated":
			_card_ids(loadout.get("opening_hand"), catalog, context + ".opening_hand", errors)
			if loadout.has("opening_draw"):
				_error(errors, context + ".opening_draw", "curated policy uses opening_hand; omit opening_draw")
			loadout.opening_draw = 0
		"draw":
			_integer(loadout, "opening_draw", 0, MAX_TURN_AMOUNT, context, errors)
			if loadout.has("opening_hand"):
				_error(errors, context + ".opening_hand", "draw policy uses opening_draw; omit opening_hand")
			loadout.opening_hand = []
		_:
			_error(errors, context + ".opening_policy", "expected curated or draw")
	if not production.is_empty():
		if not _matches(loadout.get("opening_policy"), "draw") or loadout.get("opening_draw") != loadout.get("draw_per_turn"):
			_error(errors, context + ".opening_policy", "production uses a normal opening draw equal to draw_per_turn")
		# The runtime selects a complete kit at every playable entry. This detached
		# normalized placeholder is replaced before any model snapshot is exposed.
		loadout.inventory = production.kits.kits[0].totals.duplicate(true)
	if not loadout.get("inventory") is Dictionary:
		_error(errors, context + ".inventory", "expected an object with split and join totals")
		return
	_fields(loadout.inventory, ["straight", "corner", "split", "join"], context + ".inventory", errors)
	for kind in ["split", "join"]:
		_integer(loadout.inventory, kind, 0, 14, context + ".inventory", errors)
	if loadout.inventory.has("straight") != loadout.inventory.has("corner"):
		_error(errors, context + ".inventory", "finite connector supply requires straight and corner totals together")
	for kind in ["straight", "corner"]:
		if loadout.inventory.has(kind):
			_integer(loadout.inventory, kind, 0, 14, context + ".inventory", errors)

static func _validate_board(definition: Dictionary, catalog: Dictionary, context: String, errors: Array, experiment: Dictionary = {}) -> Array:
	_fields(definition, ["id", "width", "height", "placements"], context, errors)
	_integer(definition, "width", 4, 4, context, errors)
	_integer(definition, "height", 4, 4, context, errors)
	var board: Array = []
	for index in range(16):
		board.append({})
	if not definition.get("placements") is Array:
		_error(errors, context + ".placements", "expected an array")
		return board
	var seen := {}
	var endpoint_count := {"begin": 0, "end": 0}
	var is_production: bool = experiment.get("version") == ProductionRules.PRODUCTION_VERSION
	var alternate_endpoints: bool = is_production or (experiment.get("scenario_id") == "endpoints" and experiment.get("variant_id") == "treatment")
	var blocked_allowed: bool = experiment.get("scenario_id") == "blocked" and experiment.get("variant_id") == "treatment"
	var starts_empty: bool = experiment.get("board_reset", "none") == "each_turn"
	for index in range(definition.placements.size()):
		var field := context + ".placements[%d]" % index
		var entry: Variant = definition.placements[index]
		if not entry is Dictionary:
			_error(errors, field, "expected an object")
			continue
		var piece: Dictionary = entry.duplicate(true)
		_fields(piece, ["cell", "kind", "rotation", "reversed", "rune_id"], field, errors)
		var valid_cell := _integer(piece, "cell", 0, 15, field, errors)
		_integer(piece, "rotation", 0, 3, field, errors, 0)
		_boolean(piece, "reversed", field, errors, false)
		var kinds := ["begin", "end", "straight", "corner", "split", "join", "rune"]
		if blocked_allowed:
			kinds.append("blocked")
		if not piece.get("kind") in kinds:
			_error(errors, field + ".kind", "unsupported piece kind")
		if starts_empty and not piece.get("kind") in ["begin", "end"]:
			_error(errors, field + ".kind", "full-reset follow-up starts with Begin and End only")
		if _matches(piece.get("kind"), "blocked") and not _matches(piece.get("rotation"), 0):
			_error(errors, field + ".rotation", "blocked cells require rotation 0")
		if entry.has("reversed") and not piece.get("kind") in ["straight", "corner"]:
			_error(errors, field + ".reversed", "only straight and corner wires support reversal")
		if _matches(piece.get("kind"), "rune"):
			if _id(piece.get("rune_id"), field + ".rune_id", errors):
				if not catalog.has(piece.rune_id):
					_error(errors, field + ".rune_id", "unknown rune ID '%s'" % piece.rune_id)
				elif not _matches(catalog[piece.rune_id].get("type"), "rune"):
					_error(errors, field + ".rune_id", "only effect runes can be installed")
				elif catalog[piece.rune_id].has("port_shape"):
					piece.port_shape = catalog[piece.rune_id].port_shape
		elif piece.has("rune_id"):
			_error(errors, field + ".rune_id", "only rune pieces accept a rune ID")
		if not valid_cell:
			continue
		var cell: int = piece.cell
		if seen.has(cell):
			_error(errors, field + ".cell", "duplicate cell %d" % cell)
		seen[cell] = true
		if not alternate_endpoints and ((cell == 0 and not _matches(piece.get("kind"), "begin")) or (cell == 14 and not _matches(piece.get("kind"), "end"))):
			_error(errors, field + ".kind", "fixed cells 0 and 14 require Begin and End respectively")
		if piece.get("kind") in ["begin", "end"]:
			endpoint_count[piece.kind] += 1
			if not alternate_endpoints and ((piece.kind == "begin" and cell != 0) or (piece.kind == "end" and cell != 14) or not _matches(piece.get("rotation"), 0)):
				_error(errors, field, "endpoints require Begin at cell 0 and End at cell 14, both rotation 0")
			if alternate_endpoints and not is_production and _is_integer(piece.get("rotation")):
				var direction: int = (1 + int(piece.rotation)) % 4 if piece.kind == "begin" else int(piece.rotation)
				if (direction == 0 and cell < 4) or (direction == 1 and cell % 4 == 3) or (direction == 2 and cell >= 12) or (direction == 3 and cell % 4 == 0):
					_error(errors, field + ".rotation", "endpoint port must face an in-bounds neighbor")
		piece.erase("cell")
		if _matches(piece.reversed, false):
			piece.erase("reversed")
		board[cell] = piece
	if alternate_endpoints and (endpoint_count.begin != 1 or endpoint_count.end != 1):
		_error(errors, context + ".placements", "exactly one Begin and one End are required")
	if not alternate_endpoints and (not _matches(board[0].get("kind"), "begin") or not _matches(board[14].get("kind"), "end")):
		_error(errors, context + ".placements", "explicit Begin at cell 0 and End at cell 14 are required")
	return board

static func _index(value: Variant, context: String, errors: Array) -> Dictionary:
	var indexed := {}
	if not value is Array:
		_error(errors, context, "expected an array of definitions")
		return indexed
	if value.is_empty():
		_error(errors, context, "definitions must not be empty")
	for index in range(value.size()):
		if not value[index] is Dictionary:
			_error(errors, context + "[%d]" % index, "expected an object")
			continue
		var definition: Dictionary = value[index].duplicate(true)
		if not _id(definition.get("id"), context + "[%d].id" % index, errors):
			continue
		if indexed.has(definition.id):
			_error(errors, context + "[%s].id" % definition.id, "duplicate definition ID")
		else:
			indexed[definition.id] = definition
	return indexed

static func _card_ids(value: Variant, catalog: Dictionary, context: String, errors: Array) -> void:
	if not value is Array or value.size() > MAX_CARDS:
		_error(errors, context, "expected an array of at most 100 permanent card IDs")
		return
	for index in range(value.size()):
		var field := context + "[%d]" % index
		if not _id(value[index], field, errors):
			continue
		if not catalog.has(value[index]):
			_error(errors, field, "unknown rune ID '%s'" % value[index])
		elif _matches(catalog[value[index]].get("temporary"), true):
			_error(errors, field, "temporary cards cannot belong to permanent ownership or curated hands")

static func _allocate(available: Array, id: String, context: String, errors: Array) -> void:
	var index := available.find(id)
	if index < 0:
		_error(errors, context, "opening allocation exceeds owned copies of '%s'" % id)
	else:
		available.remove_at(index)

static func _fields(value: Dictionary, allowed: Array, context: String, errors: Array) -> void:
	for key in value:
		if not key in allowed:
			_error(errors, context + "." + str(key), "unsupported field")

static func _id(value: Variant, context: String, errors: Array) -> bool:
	if not _string(value, context, errors):
		return false
	for character in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_":
			_error(errors, context, "IDs use lowercase letters, digits and underscores")
			return false
	return true

static func _string(value: Variant, context: String, errors: Array) -> bool:
	if not value is String or value.strip_edges().is_empty():
		_error(errors, context, "expected a nonempty string")
		return false
	return true

static func _is_integer(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and value == floor(value))

static func _matches(value: Variant, expected: Variant) -> bool:
	# GDScript comparison between some incompatible Variant types raises errors.
	return typeof(value) == typeof(expected) and value == expected

static func _number(value: Variant, minimum: int, maximum: int, context: String, errors: Array) -> bool:
	if not _is_integer(value) or value < minimum or value > maximum:
		_error(errors, context, "expected an integer in [%d, %d]" % [minimum, maximum])
		return false
	return true

static func _integer(value: Dictionary, key: String, minimum: int, maximum: int, context: String, errors: Array, default_value: Variant = null) -> bool:
	if not value.has(key) and default_value != null:
		value[key] = default_value
	if not _number(value.get(key), minimum, maximum, context + "." + key, errors):
		return false
	value[key] = int(value[key])
	return true

static func _boolean(value: Dictionary, key: String, context: String, errors: Array, default_value: bool) -> void:
	if not value.has(key):
		value[key] = default_value
	elif not value[key] is bool:
		_error(errors, context + "." + key, "expected a boolean")

static func _context(source_names: Dictionary, kind: String, id: String) -> String:
	return "%s [%s]" % [source_names.get(kind, kind), id]

static func _error(errors: Array, context: String, reason: String) -> void:
	errors.append(context + ": " + reason)

static func _result(errors: Array, setup: Dictionary = {}) -> Dictionary:
	return {"ok": errors.is_empty(), "errors": errors.duplicate(), "setup": setup.duplicate(true) if errors.is_empty() else {}}
