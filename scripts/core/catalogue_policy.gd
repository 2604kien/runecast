extends RefCounted
## Complete trusted catalogue generations. A retained run keeps its generation
## until it ends; New Run is the only expansion boundary. Saved definitions are
## never executable inputs and arbitrary subsets are never compatibility cases.
const INITIAL_IDS := ["spark", "shield", "focus", "conjure"]
const REGISTERED_IDS := ["spark", "shield", "focus", "conjure", "ember", "flare", "barrier", "bulwark", "deep_focus", "twin_conjure", "cinder_guard", "ward_spark"]
const LEGACY_DEFINITIONS := [
	{"id": "spark", "name": "Spark", "symbol": "*", "value": 6, "cost": 2, "type": "rune", "effect": "damage", "color": "#efb553"},
	{"id": "shield", "name": "Shield", "symbol": "<>", "value": 5, "cost": 1, "type": "rune", "effect": "shield", "color": "#82d6a0"},
	{"id": "focus", "name": "Focus", "symbol": "?", "value": 2, "cost": 1, "type": "technique", "effect": "draw", "color": "#ba9bef"},
	{"id": "conjure", "name": "Conjure Spark", "symbol": "+", "value": 1, "cost": 0, "type": "technique", "effect": "conjure", "generated_rune_id": "free_spark", "color": "#ba9bef"},
	{"id": "free_spark", "name": "Free Spark", "board_label": "Spark", "symbol": "*", "value": 6, "cost": 0, "type": "rune", "effect": "damage", "temporary": true, "color": "#efb553"}
]

static func legacy_catalog() -> Dictionary:
	var result := {}
	for source in LEGACY_DEFINITIONS:
		var definition: Dictionary = source.duplicate(true)
		definition.board_label = definition.get("board_label", definition.name)
		definition.temporary = definition.get("temporary", false)
		result[definition.id] = definition
	return result

static func is_legacy(catalog: Dictionary) -> bool:
	return catalog == legacy_catalog()

static func eligibility_version(catalog: Dictionary) -> int:
	return 1 if is_legacy(catalog) else 2

static func registered_ids(catalog: Dictionary) -> Array:
	return INITIAL_IDS.duplicate() if is_legacy(catalog) else REGISTERED_IDS.duplicate()

static func legacy_setup(setup: Dictionary) -> Dictionary:
	var retained := setup.duplicate(true)
	retained.catalog = legacy_catalog()
	if retained.has("next_encounter"): retained.next_encounter = legacy_setup(retained.next_encounter)
	return retained
