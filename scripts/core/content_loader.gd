class_name RuneContentLoader
extends RefCounted

# File I/O, schema validation and normalization complete before a model is built.
const DEFAULT_ENCOUNTER := "res://data/encounter.json"
const DEFINITION_PATHS := {
	"runes": "res://data/runes.json", "boards": "res://data/boards.json",
	"enemies": "res://data/enemies.json", "loadouts": "res://data/loadouts.json"
}
const MAX_CARDS := 100
const MAX_TURN_AMOUNT := 20
const MAX_HEALTH := 100000

static func load_setup(encounter_path: String = DEFAULT_ENCOUNTER, definition_paths: Dictionary = {}) -> Dictionary:
	var paths := DEFINITION_PATHS.duplicate()
	var errors: Array = []
	for key in definition_paths:
		if not paths.has(key):
			errors.append("definition_paths.%s: unsupported definition source" % key)
		elif not definition_paths[key] is String or definition_paths[key].is_empty():
			errors.append("definition_paths.%s: expected a nonempty file path" % key)
		else:
			paths[key] = definition_paths[key]
	paths.encounter = encounter_path
	var documents := {}
	for key in paths:
		var loaded := read_document(paths[key])
		if loaded.ok:
			documents[key] = loaded.document
		else:
			errors.append_array(loaded.errors)
	if not errors.is_empty():
		return _result(errors)
	return validate_documents(documents, paths)

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

static func validate_documents(documents: Dictionary, source_names: Dictionary = {}) -> Dictionary:
	var errors: Array = []
	var definitions := {}
	for kind in ["runes", "boards", "enemies", "loadouts"]:
		definitions[kind] = _index(documents.get(kind), str(source_names.get(kind, kind)), errors)
	var catalog: Dictionary = definitions.runes
	for id in catalog:
		_validate_rune(catalog[id], _context(source_names, "runes", id), errors)
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
		boards[id] = _validate_board(definitions.boards[id], catalog, _context(source_names, "boards", id), errors)
	for id in definitions.enemies:
		_validate_enemy(definitions.enemies[id], _context(source_names, "enemies", id), errors)
	for id in definitions.loadouts:
		_validate_loadout(definitions.loadouts[id], catalog, _context(source_names, "loadouts", id), errors)
	var encounter_source := str(source_names.get("encounter", "encounter"))
	var entry: Variant = documents.get("encounter")
	if not entry is Dictionary:
		_error(errors, encounter_source, "expected an object")
		return _result(errors)
	var encounter: Dictionary = entry.duplicate(true)
	var context := "%s [%s]" % [encounter_source, encounter.get("id", "?")]
	_fields(encounter, ["id", "enemy_id", "board_id", "loadout_id", "title", "help_text", "opening_log", "seed"], context, errors)
	_id(encounter.get("id"), context + ".id", errors)
	for field in ["title", "help_text"]:
		_string(encounter.get(field), context + "." + field, errors)
	if not encounter.has("opening_log"):
		encounter.opening_log = encounter.get("help_text", "")
	_string(encounter.get("opening_log"), context + ".opening_log", errors)
	_integer(encounter, "seed", 0, 2147483647, context, errors, 42)
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
	var installed := {"split": 0, "join": 0}
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if piece.get("kind") in ["split", "join"]:
			installed[piece.kind] += 1
		elif piece.get("kind") == "rune" and not catalog[piece.rune_id].temporary:
			_allocate(available, piece.rune_id, _context(source_names, "boards", encounter.board_id) + ".placements(cell=%d).rune_id" % index, errors)
	for kind in installed:
		if installed[kind] > loadout.inventory[kind]:
			_error(errors, context + ".loadout_id", "board installs %d %s pieces, but loadout inventory owns %d" % [installed[kind], kind, loadout.inventory[kind]])
	if loadout.opening_draw > available.size():
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
	return _result([], {"catalog": catalog, "encounter": encounter, "board": board,
		"owned_cards": loadout.owned_cards, "opening_hand": loadout.opening_hand,
		"opening_draw": loadout.opening_draw, "inventory": loadout.inventory})

static func _validate_rune(rune: Dictionary, context: String, errors: Array) -> void:
	_fields(rune, ["id", "name", "board_label", "symbol", "type", "effect", "value", "cost", "color", "temporary", "generated_rune_id"], context, errors)
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

static func _validate_loadout(loadout: Dictionary, catalog: Dictionary, context: String, errors: Array) -> void:
	_fields(loadout, ["id", "max_health", "current_health", "energy_per_turn", "draw_per_turn", "owned_cards", "opening_policy", "opening_hand", "opening_draw", "inventory"], context, errors)
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
	if not loadout.get("inventory") is Dictionary:
		_error(errors, context + ".inventory", "expected an object with split and join totals")
		return
	_fields(loadout.inventory, ["split", "join"], context + ".inventory", errors)
	for kind in ["split", "join"]:
		_integer(loadout.inventory, kind, 0, 14, context + ".inventory", errors)

static func _validate_board(definition: Dictionary, catalog: Dictionary, context: String, errors: Array) -> Array:
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
		if not piece.get("kind") in ["begin", "end", "straight", "corner", "split", "join", "rune"]:
			_error(errors, field + ".kind", "unsupported piece kind")
		if entry.has("reversed") and not piece.get("kind") in ["straight", "corner"]:
			_error(errors, field + ".reversed", "only straight and corner wires support reversal")
		if _matches(piece.get("kind"), "rune"):
			if _id(piece.get("rune_id"), field + ".rune_id", errors):
				if not catalog.has(piece.rune_id):
					_error(errors, field + ".rune_id", "unknown rune ID '%s'" % piece.rune_id)
				elif not _matches(catalog[piece.rune_id].get("type"), "rune"):
					_error(errors, field + ".rune_id", "only effect runes can be installed")
		elif piece.has("rune_id"):
			_error(errors, field + ".rune_id", "only rune pieces accept a rune ID")
		if not valid_cell:
			continue
		var cell: int = piece.cell
		if seen.has(cell):
			_error(errors, field + ".cell", "duplicate cell %d" % cell)
		seen[cell] = true
		if (cell == 0 and not _matches(piece.get("kind"), "begin")) or (cell == 14 and not _matches(piece.get("kind"), "end")):
			_error(errors, field + ".kind", "fixed cells 0 and 14 require Begin and End respectively")
		if piece.get("kind") in ["begin", "end"]:
			if (piece.kind == "begin" and cell != 0) or (piece.kind == "end" and cell != 14) or not _matches(piece.get("rotation"), 0):
				_error(errors, field, "endpoints require Begin at cell 0 and End at cell 14, both rotation 0")
		piece.erase("cell")
		if _matches(piece.reversed, false):
			piece.erase("reversed")
		board[cell] = piece
	if not _matches(board[0].get("kind"), "begin") or not _matches(board[14].get("kind"), "end"):
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
