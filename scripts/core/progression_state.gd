extends RefCounted
## Persistent definition eligibility, separate from run-owned instances.
## The local save transaction owns disk I/O; this model has no file side effects.
const CataloguePolicy = preload("res://scripts/core/catalogue_policy.gd")
const INITIAL_IDS := CataloguePolicy.INITIAL_IDS
const REGISTERED_IDS := CataloguePolicy.REGISTERED_IDS
const POLICY_ID := "rc027_owner_2026_10_22"
const REWARD_POLICY_ID := "rc035_rewards_v2"
const SAVE_VERSION := 1
var _catalog: Dictionary = {}
var _unlocked: Array = []

func _init(validated_catalog: Dictionary, initial_ids: Array = INITIAL_IDS) -> void:
	_catalog = validated_catalog.duplicate(true)
	for id in initial_ids:
		if _implemented(str(id)) and not _unlocked.has(id): _unlocked.append(str(id))
	_unlocked.sort()

func snapshot() -> Dictionary:
	return {"unlocked_definition_ids": _unlocked, "session_only": false,
		"ownership": "definition_unlocks", "policy_id": POLICY_ID}.duplicate(true)

func export_save() -> Dictionary:
	return {"version": SAVE_VERSION, "policy_id": POLICY_ID, "ownership": "definition_unlocks",
		"unlocked_definition_ids": _unlocked.duplicate()}

static func restore_save(data: Dictionary, catalog: Dictionary, allow_test_fixtures: bool = false) -> Dictionary:
	if data.size() != 4 or not data.get("version") is int or data.version != SAVE_VERSION:
		return {"ok": false, "error": "Unsupported or malformed profile save version."}
	if not data.get("policy_id") is String or not data.get("ownership") is String or data.policy_id != POLICY_ID or data.ownership != "definition_unlocks":
		return {"ok": false, "error": "The saved definition ownership policy is incompatible."}
	if not data.get("unlocked_definition_ids") is Array:
		return {"ok": false, "error": "Profile unlocks must be an array of definition IDs."}
	var ids: Array = []
	for id in data.unlocked_definition_ids:
		if not id is String or not id in REGISTERED_IDS or not catalog.has(id) or catalog[id].get("temporary", false) or id in ids:
			return {"ok": false, "error": "Profile contains an unknown, temporary, or duplicate unlocked definition."}
		ids.append(id)
	if not allow_test_fixtures:
		for id in INITIAL_IDS:
			if not id in ids: return {"ok": false, "error": "Profile is missing an initially unlocked definition."}
	var restored = load("res://scripts/core/progression_state.gd").new(catalog, ids)
	return {"ok": true, "error": "", "profile": restored}

func clone_for_transaction():
	return get_script().new(_catalog, _unlocked)

func publish_transaction(candidate: RefCounted) -> void:
	_unlocked = candidate._unlocked.duplicate()

func can_unlock(id: String) -> bool:
	return validate_unlock(self, id)

func unlock(id: String) -> bool:
	if not validate_unlock(self, id): return false
	commit_validated_unlock(self, id)
	return true

static func validate_unlock(profile: RefCounted, id: String) -> bool:
	return id in REGISTERED_IDS and profile._catalog.has(id) and not profile._catalog[id].get("temporary", false) and not profile._unlocked.has(id)

# The run transaction calls this only after validating both owners, through
# this static implementation (no overridable callback can fail after commit).
static func commit_validated_unlock(profile: RefCounted, id: String) -> void:
	profile._unlocked.append(id)
	profile._unlocked.sort()

func _implemented(id: String) -> bool:
	return id in REGISTERED_IDS and _catalog.has(id) and not _catalog[id].get("temporary", false)

static func production_rules(legacy: bool = false) -> Dictionary:
	# Additive exact encounter/role dispatch preserves the original Shadeling
	# policy identity, retained offers and receipts. RC-036 owns battle Gold and
	# the elite relic contract; neither is inferred from room family here.
	var ids: Array = INITIAL_IDS if legacy else REGISTERED_IDS
	return {"policy_id": POLICY_ID if legacy else REWARD_POLICY_ID, "rules": [{
		"encounter_role": "boss", "encounter_id": "training_shadeling",
		"choice_id": "encounter_rewards", "eligible_ids": ids.duplicate(),
		"offer_count": 3, "gold": 0, "allow_skip": true, "permanent_unlock": true}, {
		"encounter_role": "normal", "encounter_id": "wickling",
		"choice_id": "encounter_rewards", "eligible_ids": ids.duplicate(),
		"offer_count": 3, "gold": 0, "allow_skip": true}, {
		"encounter_role": "normal", "encounter_id": "stone_sentinel",
		"choice_id": "encounter_rewards", "eligible_ids": ids.duplicate(),
		"offer_count": 3, "gold": 0, "allow_skip": true}, {
		"encounter_role": "elite", "encounter_id": "chain_warden",
		"choice_id": "encounter_rewards", "eligible_ids": ids.duplicate(),
		"offer_count": 3, "gold": 0, "allow_skip": true}, {
		"encounter_role": "guardian", "encounter_id": "bell_keeper",
		"choice_id": "encounter_rewards", "eligible_ids": ids.duplicate(),
		"offer_count": 3, "gold": 0, "allow_skip": true, "permanent_unlock": true}]}
