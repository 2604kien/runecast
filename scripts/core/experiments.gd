class_name RuneExperiments
extends RefCounted

# RC-005 development fixtures. None of these definitions replace normal files.
const Loader = preload("res://scripts/core/content_loader.gd")
const VERSION := Loader.EXPERIMENT_VERSION
const DEFAULT_SEED := 42
const SCENARIOS := [
	{"id": "effects", "title": "A · Effect lifetime", "variants": ["control", "treatment"]},
	{"id": "split_inventory", "title": "B1 · Split inventory", "variants": ["control", "treatment"]},
	{"id": "split_cost", "title": "B2 · Split cost", "variants": ["control", "treatment"]},
	{"id": "endpoints", "title": "C1 · Endpoint placement", "variants": ["control", "treatment"]},
	{"id": "blocked", "title": "C2 · Blocked cell", "variants": ["control", "treatment"]},
	{"id": "ports", "title": "C3 · Effect ports", "variants": ["control", "treatment"]},
	{"id": "hits", "title": "D · Damage hits", "variants": ["control", "treatment"]},
	{"id": "expiry", "title": "E · Temporary expiry", "variants": ["control", "retained", "empty"]},
	{"id": "encounters", "title": "F · Encounter transfer", "variants": ["control", "treatment"]}
]

static func list_scenarios() -> Array:
	return SCENARIOS.duplicate(true)

static func load_setup(scenario_id: Variant, variant_id: Variant, seed: Variant = DEFAULT_SEED) -> Dictionary:
	var source := documents(scenario_id, variant_id, seed)
	if not source.ok:
		return {"ok": false, "errors": source.errors, "setup": {}}
	return Loader.validate_documents(source.documents, {}, source.experiment)

# Raw detached fixtures are exposed for validation tests, never passed directly
# to Combat. Scenario selection and seed are validated before definitions exist.
static func documents(scenario_id: Variant, variant_id: Variant, seed: Variant = DEFAULT_SEED) -> Dictionary:
	var selected := Loader.experiment_options(scenario_id, variant_id, seed)
	if not selected.ok:
		return {"ok": false, "errors": selected.errors, "documents": {}, "experiment": {}}
	var source := Loader.read_document(Loader.DEFINITION_PATHS.runes)
	if not source.ok:
		return {"ok": false, "errors": source.errors, "documents": {}, "experiment": {}}
	if not source.document is Array or not source.document.all(func(item): return item is Dictionary):
		return {"ok": false, "errors": ["res://data/runes.json: expected an array of rune definition objects"], "documents": {}, "experiment": {}}
	var runes: Array = source.document.duplicate(true)
	var placements := _one_pair()
	var inventory := {"split": 1, "join": 1}
	var enemy_health := 36
	if scenario_id == "split_inventory" and variant_id == "treatment":
		inventory = {"split": 2, "join": 2}
	if scenario_id == "split_cost":
		inventory = {"split": 2, "join": 2}
		placements = _two_pairs()
	if scenario_id == "endpoints" and variant_id == "treatment":
		for piece in placements:
			piece.cell = 15 - int(piece.cell)
			piece.rotation = (int(piece.get("rotation", 0)) + 2) % 4
	if scenario_id in ["blocked", "ports", "expiry"]:
		placements = _simple_path()
	if scenario_id == "blocked" and variant_id == "treatment":
		placements.append({"cell": 6, "kind": "blocked"})
	if scenario_id == "ports" and variant_id == "treatment":
		# Preserve the same complete path, effect amount, ownership and cost.
		# Accommodating the corner moves its initial instance to the turn at 3.
		_set_rune_field(runes, "spark", "port_shape", "corner")
		_replace(placements, 1, {"cell": 1, "kind": "straight"})
		_replace(placements, 3, {"cell": 3, "kind": "rune", "rune_id": "spark"})
	if scenario_id == "expiry":
		# Same corner-port dependency in all three expiry variants, including
		# the generated hand card from the existing Conjure technique.
		_set_rune_field(runes, "free_spark", "port_shape", "corner")
		_replace(placements, 3, {"cell": 3, "kind": "rune", "rune_id": "free_spark"})
		placements.append({"cell": 8, "kind": "rune", "rune_id": "free_spark", "rotation": 2})
	if scenario_id == "encounters":
		enemy_health = 24
	var loadout := {"id": "rc005_collection", "max_health": 40, "current_health": 40,
		"energy_per_turn": 6, "draw_per_turn": 3,
		"owned_cards": ["spark", "shield", "conjure", "spark", "shield", "focus", "focus", "conjure"],
		"opening_policy": "curated", "opening_hand": ["spark", "shield", "conjure"], "inventory": inventory}
	var fixture_id := "rc005_" + str(scenario_id)
	var summary := rule_summary(scenario_id, variant_id)
	var data := {"runes": runes,
		"boards": [{"id": fixture_id + "_board", "width": 4, "height": 4, "placements": placements}],
		"enemies": [{"id": "rc005_probe", "name": "Experiment Wisp", "max_health": enemy_health, "intents": [3]}],
		"loadouts": [loadout],
		"encounter": {"id": fixture_id, "enemy_id": "rc005_probe", "board_id": fixture_id + "_board",
			"loadout_id": "rc005_collection", "title": "RC-005 EXPERIMENT", "help_text": summary,
			"opening_log": summary, "seed": int(seed)}}
	return {"ok": true, "errors": [], "documents": data, "experiment": selected.setup}

static func rule_summary(scenario_id: String, variant_id: String) -> String:
	match scenario_id:
		"effects":
			return "Powered permanent effects stay installed after Cast." if variant_id == "control" else "Cast consumes powered permanent effects into discard; matching wires replace them. Pass keeps them."
		"split_inventory":
			return "One Split/Join pair; each powered Split costs 1." if variant_id == "control" else "Two Split/Join pairs; each costs 1. For 18 damage: replace cell 6 with Join, cell 7 with Split, rotate cell 7 once."
		"split_cost":
			return "Two installed pairs: 18 damage, each Split costs 1 (total 4)." if variant_id == "control" else "Two installed pairs: 18 damage, each Split costs 2 (total 6). Focus competes for casting energy."
		"endpoints":
			return "Begin cell 0, End cell 14; endpoints are protected." if variant_id == "control" else "Board rotated 180 degrees: Begin cell 15, End cell 1. Endpoint ports and protection move with them."
		"blocked":
			return "All non-endpoint cells editable; simple right-edge path." if variant_id == "control" else "Cell 6 is blocked: no placement, rotation or path through it. Right-edge path remains valid."
		"ports":
			return "Spark has straight ports, installed at cell 1." if variant_id == "control" else "Spark has corner ports, installed at cell 3 on the same path. Rotate changes its actual ports."
		"hits":
			return "12 total damage is one aggregate hit." if variant_id == "control" else "12 total damage is two ordered 6-damage hits; stop on lethal. Shield is still one total."
		"expiry":
			var replacement := "straight wire" if variant_id == "control" else ("matching corner wire" if variant_id == "retained" else "empty cell")
			return "Corner temporaries at cells 3 and 8 expire to %s after Cast or Pass. Conjure tests unused hand expiry." % replacement
		"encounters":
			return "Two 24-HP encounters. Next rebuilds starting wires; installed effects return to the card pool. Health carries." if variant_id == "control" else "Two 24-HP encounters. Next retains topology and installed permanent instances. Health carries; hand is rebuilt."
	return "Unknown experimental comparison."

# Cell indices are zero-based, row-major. Actions can be issued through the
# authoritative command path; the treatment witness really installs 2 pairs.
static func known_solution_actions(scenario_id: String, variant_id: String) -> Array:
	if scenario_id == "split_inventory" and variant_id == "treatment":
		return [{"command": "place_wire", "arguments": {"index": 6, "kind": "join"}},
			{"command": "place_wire", "arguments": {"index": 7, "kind": "split"}},
			{"command": "rotate", "arguments": {"index": 7}}]
	return []

static func _one_pair() -> Array:
	return [{"cell": 0, "kind": "begin"}, {"cell": 1, "kind": "rune", "rune_id": "spark"},
		{"cell": 2, "kind": "split"}, {"cell": 3, "kind": "corner"},
		{"cell": 6, "kind": "straight", "rotation": 1}, {"cell": 7, "kind": "straight", "rotation": 1},
		{"cell": 8, "kind": "rune", "rune_id": "shield"},
		{"cell": 10, "kind": "join"}, {"cell": 11, "kind": "corner", "rotation": 1},
		{"cell": 14, "kind": "end"}]

static func _two_pairs() -> Array:
	var result := _one_pair()
	_replace(result, 6, {"cell": 6, "kind": "join"})
	_replace(result, 7, {"cell": 7, "kind": "split", "rotation": 1})
	return result

static func _simple_path() -> Array:
	return [{"cell": 0, "kind": "begin"}, {"cell": 1, "kind": "rune", "rune_id": "spark"},
		{"cell": 2, "kind": "straight"}, {"cell": 3, "kind": "corner"},
		{"cell": 7, "kind": "straight", "rotation": 1},
		{"cell": 10, "kind": "corner", "rotation": 3, "reversed": true},
		{"cell": 11, "kind": "corner", "rotation": 1}, {"cell": 14, "kind": "end"}]

static func _set_rune_field(runes: Array, id: String, field: String, value: Variant) -> void:
	for rune in runes:
		if rune.get("id") == id:
			rune[field] = value

static func _replace(placements: Array, cell: int, replacement: Dictionary) -> void:
	for index in range(placements.size()):
		if placements[index].cell == cell:
			placements[index] = replacement
			return
