class_name RuneInstanceEffects
extends RefCounted

# One bounded, shared interpretation of a run-owned instance. Definitions stay
# immutable; rank is always owned by the physical UID, never the catalogue ID.
const VERSION := "rc031_instance_effects_v1"
const UPGRADE_CONTRACTS := {
	"spark": {"id": "upgrade_spark", "effect": "damage", "before": 6, "after": 8, "cost": 2},
	"shield": {"id": "upgrade_shield", "effect": "shield", "before": 5, "after": 7, "cost": 1},
	"focus": {"id": "upgrade_focus", "effect": "draw", "before": 2, "after": 3, "cost": 1},
	"conjure": {"id": "upgrade_conjure", "effect": "conjure", "before": 1, "after": 2, "cost": 0},
	"ember": {"id": "upgrade_ember", "effect": "damage", "before": 3, "after": 4, "cost": 1},
	"flare": {"id": "upgrade_flare", "effect": "damage", "before": 10, "after": 13, "cost": 3},
	"barrier": {"id": "upgrade_barrier", "effect": "shield", "before": 9, "after": 11, "cost": 2},
	"cinder_guard": {"id": "upgrade_cinder_guard", "effect": "damage_shield", "before": {"damage": 4, "shield": 3}, "after": {"damage": 6, "shield": 4}, "cost": 2}
}

static func contracts() -> Dictionary:
	return UPGRADE_CONTRACTS.duplicate(true)

static func resolve(catalog: Dictionary, instance: Dictionary) -> Dictionary:
	var id: Variant = instance.get("id", instance.get("rune_id"))
	var rank: Variant = instance.get("upgrade_rank", 0)
	if not id is String or not catalog.get(id) is Dictionary:
		return _failure("Unknown rune definition.")
	if not rank is int or rank < 0 or rank > 1:
		return _failure("Rune upgrade rank must be the integer 0 or 1.")
	var definition: Dictionary = catalog[id].duplicate(true)
	if not _valid_effect(definition):
		return _failure("Unsupported or malformed rune effect.")
	if rank == 1:
		if not _supports_upgrade(id, definition):
			return _failure("This rune definition cannot be upgraded.")
		var upgraded: Variant = UPGRADE_CONTRACTS[id].after
		definition.value = upgraded.duplicate(true) if upgraded is Dictionary else upgraded
	definition.upgrade_rank = rank
	return {"ok": true, "error": "", "definition": definition}

static func eligible(catalog: Dictionary, instance: Dictionary) -> bool:
	var resolved := resolve(catalog, instance)
	return resolved.ok and resolved.definition.upgrade_rank == 0 and _supports_upgrade(str(instance.get("id", instance.get("rune_id", ""))), resolved.definition)

static func upgrade_preview(catalog: Dictionary, instance: Dictionary) -> Dictionary:
	if not eligible(catalog, instance):
		return {"ok": false, "error": "This instance has no available upgrade.", "before": {}, "after": {}, "upgrade_id": ""}
	var upgraded := instance.duplicate(true)
	upgraded.upgrade_rank = 1
	var id: String = instance.get("id", instance.get("rune_id", ""))
	return {"ok": true, "error": "", "before": resolve(catalog, instance).definition,
		"after": resolve(catalog, upgraded).definition, "upgrade_id": UPGRADE_CONTRACTS[id].id}

static func card_from_piece(piece: Dictionary) -> Dictionary:
	var card := {"id": piece.get("rune_id"), "uid": piece.get("uid")}
	# Historical experiment fixtures retain their schema. Current run instances
	# are explicitly ranked on entry and retain that field through every zone.
	if piece.has("upgrade_rank"): card.upgrade_rank = piece.upgrade_rank
	return card

static func contributions(definition: Dictionary) -> Dictionary:
	if definition.get("effect") == "damage_shield":
		return definition.value.duplicate(true)
	return {"damage": int(definition.value) if definition.get("effect") == "damage" else 0,
		"shield": int(definition.value) if definition.get("effect") == "shield" else 0}

static func effect_summary(definition: Dictionary) -> String:
	match definition.get("effect"):
		"damage": return "%d damage" % int(definition.value)
		"shield": return "%d shield" % int(definition.value)
		"draw": return "Draw %d" % int(definition.value)
		"conjure": return "Create %d Free Spark%s" % [int(definition.value), "" if int(definition.value) == 1 else "s"]
		"damage_shield": return "%d damage, %d shield" % [int(definition.value.damage), int(definition.value.shield)]
	return "Unsupported effect"

static func _supports_upgrade(id: String, definition: Dictionary) -> bool:
	if not UPGRADE_CONTRACTS.has(id) or definition.get("temporary", false): return false
	var contract: Dictionary = UPGRADE_CONTRACTS[id]
	return definition.get("effect") == contract.effect and definition.get("value") == contract.before and definition.get("cost") == contract.cost and (id != "conjure" or definition.get("generated_rune_id") == "free_spark")

static func _valid_effect(definition: Dictionary) -> bool:
	if not definition.get("cost") is int or definition.cost < 0 or definition.cost > 20: return false
	if not definition.get("type") is String or not definition.get("effect") is String or not definition.get("temporary", false) is bool: return false
	var effect: Variant = definition.get("effect")
	if definition.get("type") == "rune":
		if not effect in ["damage", "shield", "damage_shield"]: return false
	elif definition.get("type") == "technique":
		if not effect in ["draw", "conjure"] or definition.get("temporary", false): return false
	else: return false
	if definition.get("temporary", false) and definition.cost != 0: return false
	if effect == "damage_shield":
		var values: Variant = definition.get("value")
		if not values is Dictionary or values.size() != 2: return false
		for key in ["damage", "shield"]:
			if not values.get(key) is int or values[key] < 0 or values[key] > 10000: return false
		return true
	return definition.get("value") is int and definition.value >= 0 and definition.value <= (20 if definition.type == "technique" else 10000)

static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error, "definition": {}}
