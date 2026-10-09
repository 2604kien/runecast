class_name RuneProductionRules
extends RefCounted

# Versioned owner-selected production contract. This helper owns no combat state
# or random stream; configuration is validated before model construction.
const DEFAULT_PATH := "res://data/production_rules.json"
const VERSION := "rc007_connector_kits_v1"
const PRODUCTION_VERSION := "rc007_production_v1"
const CONNECTOR_KINDS := ["straight", "corner", "split", "join"]
const KIT_TOTALS := {
	"extra_straights": {"straight": 6, "corner": 2, "split": 1, "join": 1},
	"extra_corners": {"straight": 4, "corner": 4, "split": 1, "join": 1},
	"extra_branches": {"straight": 4, "corner": 2, "split": 2, "join": 2}
}

static func load_rules(path: String = DEFAULT_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(["%s: cannot read file (%s)" % [path, error_string(FileAccess.get_open_error())]])
	var source := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return _result(["%s: cannot read file (%s)" % [path, error_string(read_error)]])
	var parser := JSON.new()
	if parser.parse(source) != OK:
		return _result(["%s: JSON line %d: %s" % [path, parser.get_error_line(), parser.get_error_message()]])
	return validate_rules(parser.data, path)

static func validate_rules(document: Variant, source: String = "production_rules") -> Dictionary:
	if not document is Dictionary:
		return _result([source + ": expected an object"])
	var rules: Dictionary = document.duplicate(true)
	var errors: Array = []
	_fields(rules, ["version", "balance", "kits"], source, errors)
	if not _matches(rules.get("version"), VERSION):
		errors.append(source + ".version: expected " + VERSION)
	if not _matches(rules.get("balance"), "provisional"):
		errors.append(source + ".balance: expected provisional; these counts are selected tuning values")
	if not rules.get("kits") is Array or rules.kits.size() != KIT_TOTALS.size():
		errors.append(source + ".kits: expected exactly the three selected ten-piece kits")
		return _result(errors)
	var identities := {}
	for index in range(rules.kits.size()):
		var context := source + ".kits[%d]" % index
		if not rules.kits[index] is Dictionary:
			errors.append(context + ": expected an object")
			continue
		var kit: Dictionary = rules.kits[index]
		_fields(kit, ["id", "weight", "totals"], context, errors)
		var id: Variant = kit.get("id")
		var valid_id: bool = id is String and KIT_TOTALS.has(id)
		if not valid_id:
			errors.append(context + ".id: expected extra_straights, extra_corners or extra_branches")
		elif identities.has(id):
			errors.append(context + ".id: duplicate kit ID " + id)
		else:
			identities[id] = true
		if not _integer_equals(kit.get("weight"), 1):
			errors.append(context + ".weight: expected 1 for equal initial kit probabilities")
		else:
			kit.weight = 1
		if not kit.get("totals") is Dictionary:
			errors.append(context + ".totals: expected all four connector totals")
			continue
		_fields(kit.totals, CONNECTOR_KINDS, context + ".totals", errors)
		for kind in CONNECTOR_KINDS:
			if valid_id and not _integer_equals(kit.totals.get(kind), KIT_TOTALS[id][kind]):
				errors.append(context + ".totals." + kind + ": expected %d for %s" % [KIT_TOTALS[id][kind], id])
			elif valid_id:
				kit.totals[kind] = int(kit.totals[kind])
	return _result(errors, rules)

# Call only with validated rules and a dedicated injected RNG. One call means
# one kit selection; rendering, edits and Undo never need to call this helper.
# Equal weights intentionally use a single bounded draw, with repeats allowed.
static func select_kit(validated_rules: Dictionary, kit_rng: RandomNumberGenerator) -> Dictionary:
	assert(kit_rng != null, "Kit selection requires its own supplied random stream.")
	assert(validated_rules.get("kits") is Array and validated_rules.kits.size() == 3, "Validate production kit rules before selecting.")
	var index := kit_rng.randi_range(0, validated_rules.kits.size() - 1)
	return validated_rules.kits[index].duplicate(true)

static func production_options(validated_kit_rules: Dictionary) -> Dictionary:
	return {"version": PRODUCTION_VERSION, "board_reset": "each_turn",
		"effects": "discard_all", "expiry": "empty", "split_cost": 1, "join_cost": 0,
		"damage_mode": "aggregate", "endpoint_policy": "random_any_cells",
		"endpoint_rotation": "player", "endpoint_initial": "random",
		"endpoint_selection": "uniform_ordered_pairs_v1", "kits": validated_kit_rules.duplicate(true)}

static func validate_production(context: Variant) -> Dictionary:
	if not context is Dictionary:
		return _result(["production: expected a versioned options object"])
	var validated := validate_rules(context.get("kits"), "production.kits")
	if not validated.ok:
		return validated
	var expected := production_options(validated.rules)
	var errors: Array = []
	_fields(context, expected.keys(), "production", errors)
	for key in expected:
		if key == "kits":
			continue
		if not _matches(context.get(key), expected[key]):
			errors.append("production.%s: expected %s" % [key, str(expected[key])])
	return _result(errors, expected)

static func _integer_equals(value: Variant, expected: int) -> bool:
	return (value is int or (value is float and is_finite(value) and value == floor(value))) and value == expected

static func _matches(value: Variant, expected: Variant) -> bool:
	return typeof(value) == typeof(expected) and value == expected

static func _fields(value: Dictionary, allowed: Array, source: String, errors: Array) -> void:
	for key in value:
		if not key in allowed:
			errors.append(source + "." + str(key) + ": unsupported field")

static func _result(errors: Array, rules: Dictionary = {}) -> Dictionary:
	return {"ok": errors.is_empty(), "errors": errors.duplicate(), "rules": rules.duplicate(true) if errors.is_empty() else {}}
