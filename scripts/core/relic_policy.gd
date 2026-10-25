class_name RuneRelicPolicy
extends RefCounted

# Run-only, unique definitions. The fixed order is part of the versioned policy;
# none of these hooks evaluates arbitrary scripts or changes base rune content.
const VERSION := "rc031_relics_v1"
const OFFER_RANDOM_VERSION := "rc031_relic_offers_v1"
const ORDER := ["relic_ember_lens", "relic_ward_seal", "relic_opening_tome", "relic_copper_coil", "relic_menders_token", "relic_heart_stone"]
const DEFINITIONS := {
	"relic_ember_lens": {"id": "relic_ember_lens", "name": "Ember Lens", "hook": "final_damage", "value": 2, "description": "Add 2 damage once after End aggregation when the cast already deals damage."},
	"relic_ward_seal": {"id": "relic_ward_seal", "name": "Ward Seal", "hook": "final_shield", "value": 2, "description": "Add 2 shield once after End aggregation when the cast already grants shield. No benefit on Pass."},
	"relic_opening_tome": {"id": "relic_opening_tome", "name": "Opening Tome", "hook": "opening_draw", "value": 1, "description": "Draw one extra owned card after the normal opening draw of each battle."},
	"relic_copper_coil": {"id": "relic_copper_coil", "name": "Copper Coil", "hook": "opening_energy", "value": 1, "description": "Gain 1 energy on the first turn of each battle. Later turns use normal energy."},
	"relic_menders_token": {"id": "relic_menders_token", "name": "Mender's Token", "hook": "recovery", "value": 4, "description": "Recovery rooms restore 4 extra HP, capped at maximum HP. Blood Tithe is unchanged."},
	"relic_heart_stone": {"id": "relic_heart_stone", "name": "Heart Stone", "hook": "acquisition_health", "value": 4, "description": "On acquisition outside combat, gain 4 maximum HP and 4 current HP once."}
}

static func definitions() -> Dictionary:
	return DEFINITIONS.duplicate(true)

static func validate_definitions(value: Variant) -> String:
	if not value is Dictionary or value.size() != ORDER.size(): return "Relic definitions require the six bounded hooks."
	for id in ORDER:
		var definition: Variant = value.get(id)
		if not definition is Dictionary or definition.size() != 5 or not definition.get("id") is String or not definition.get("hook") is String or definition.id != id or definition.hook != DEFINITIONS[id].hook:
			return "Relic identity or hook is unsupported."
		for key in ["name", "description"]:
			if not definition.get(key) is String or definition[key].is_empty(): return "Relic presentation is incomplete."
		if not definition.get("value") is int or definition.value < 1 or definition.value > 20: return "Relic value is outside the provisional bounds."
	return ""

static func validate_owned(relics: Variant) -> String:
	if not relics is Array or relics.size() > ORDER.size(): return "Run relic ownership is invalid."
	var seen := {}
	for id in relics:
		if not id is String or not DEFINITIONS.has(id) or seen.has(id): return "Relics must be supported, unique run-owned definitions."
		seen[id] = true
	return ""

static func eligible_pool(relics: Array) -> Array:
	if not validate_owned(relics).is_empty(): return []
	return ORDER.filter(func(id): return not relics.has(id))

static func offer(relics: Array, count: int, offer_rng: RandomNumberGenerator) -> Array:
	var pool := eligible_pool(relics)
	var chosen: Array = []
	for index in range(mini(maxi(count, 0), pool.size())):
		var selected := offer_rng.randi_range(0, pool.size() - 1)
		chosen.append(pool[selected])
		pool.remove_at(selected)
	return chosen

static func final_cast(spell: Dictionary, relics: Variant) -> Dictionary:
	var result := spell.duplicate(true)
	if not validate_owned(relics).is_empty():
		result.valid = false
		result.damage = 0
		result.shield = 0
		result.cost = 0
		result.message = "Invalid relic ownership."
		return result
	if relics.is_empty(): return result
	if not result.get("valid", false): return result
	# First aggregate the entire graph, then apply each conditional bonus once.
	# A multi-hit experiment adds the one final bonus to the final contribution.
	if relics.has("relic_ember_lens") and int(result.damage) > 0:
		result.damage += DEFINITIONS.relic_ember_lens.value
		if result.has("hits") and not result.hits.is_empty(): result.hits[-1] += DEFINITIONS.relic_ember_lens.value
	if relics.has("relic_ward_seal") and int(result.shield) > 0:
		result.shield += DEFINITIONS.relic_ward_seal.value
	return result

static func opening_draw_bonus(relics: Array) -> int:
	return int(DEFINITIONS.relic_opening_tome.value) if relics.has("relic_opening_tome") else 0

static func opening_energy_bonus(relics: Array) -> int:
	return int(DEFINITIONS.relic_copper_coil.value) if relics.has("relic_copper_coil") else 0

static func recovery_amount(relics: Array, base_amount: int) -> int:
	return base_amount + (int(DEFINITIONS.relic_menders_token.value) if relics.has("relic_menders_token") else 0)

# Called only by the authoritative acquisition transaction and its chronological
# validator. Battle construction, live resume and inspection never call this.
static func acquire_health(relic_id: String, hp: int, max_hp: int) -> Dictionary:
	var gain := int(DEFINITIONS.relic_heart_stone.value) if relic_id == "relic_heart_stone" else 0
	return {"player_hp": mini(hp + gain, max_hp + gain), "player_max_hp": max_hp + gain}
