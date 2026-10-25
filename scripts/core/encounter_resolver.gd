class_name RuneEncounterResolver
extends RefCounted
## Trusted encounter/actor/role/board registration. Saved data never chooses paths.

const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const SOURCES := {
	"training_shadeling": {"path": "res://data/production_encounter.json", "enemy": "shadeling", "role": "boss", "boards": ["board_training"]},
	"wickling": {"path": "res://data/production_wickling_encounter.json", "enemy": "wickling", "role": "normal", "boards": ["board_gallery", "board_ossuary"]},
	"stone_sentinel": {"path": "res://data/production_stone_sentinel_encounter.json", "enemy": "stone_sentinel", "role": "normal", "boards": ["board_gallery", "board_ossuary"]},
	"chain_warden": {"path": "res://data/production_chain_warden_encounter.json", "enemy": "chain_warden", "role": "elite", "boards": ["board_ossuary"]},
	"bell_keeper": {"path": "res://data/production_bell_keeper_encounter.json", "enemy": "bell_keeper", "role": "guardian", "boards": ["board_belfry"]},
	# Explicit development callers retain this historical registration. Production
	# route and restore boundaries reject the development role and ID.
	"rc007_entry_probe_next": {"path": "res://data/production_next_encounter.json", "enemy": "dev_calibration_wisp", "role": "development", "boards": ["board_gallery", "board_ossuary"]}
}

static func production_id(id: String) -> bool:
	return SOURCES.has(id) and SOURCES[id].role != "development"

static func supported_node(node: Dictionary, production_only: bool = true) -> bool:
	var id := str(node.get("encounter_id", ""))
	if not SOURCES.has(id) or (production_only and not production_id(id)): return false
	var spec: Dictionary = SOURCES[id]
	return node.get("enemy_id") == spec.enemy and node.get("encounter_role") == spec.role and node.get("board_id") in spec.boards

func resolve(node: Dictionary, entry: Dictionary) -> Dictionary:
	var id := str(node.get("encounter_id", ""))
	if not SOURCES.has(id):
		return _failure("%s is not available yet. Your route choice has not been consumed." % str(node.get("title", "This room")))
	var spec: Dictionary = SOURCES[id]
	if not _supports_node(node):
		return _failure("The selected enemy, role or board does not match its registered encounter.")
	var loaded := _load(node, str(spec.path))
	if not loaded.get("ok", false): return _failure("\n".join(loaded.get("errors", ["Encounter content is unavailable."])))
	var setup: Dictionary = loaded.setup
	if setup.encounter.id != id or setup.encounter.enemy_id != node.enemy_id or setup.encounter.board_id != node.get("board_id"):
		return _failure("The selected encounter, enemy and board identities disagree.")
	# The loadout supplies battle configuration; permanent ownership comes only
	# from the run. Combat validates each original UID against the catalog.
	setup.owned_cards = entry.get("owned_cards", []).map(func(card): return card.get("id", ""))
	entry = entry.duplicate(true)
	entry.encounter_id = id
	var error := Combat.validate_run_entry(setup, entry)
	if not error.is_empty(): return _failure(error)
	setup.encounter.encounter_role = str(node.encounter_role)
	return {"ok": true, "error": "", "setup": setup, "entry": entry,
		"source_path": spec.path, "pending_choices": _choices(node), "reward_policy": _reward_policy()}

func _load(node: Dictionary, path: String) -> Dictionary:
	return Loader.load_selected_encounter(path, str(node.get("board_id", "")))

func _supports_node(node: Dictionary) -> bool:
	return supported_node(node, false)

func _choices(_node: Dictionary) -> Array:
	return ["encounter_rewards"]

func _reward_policy() -> String:
	return "Victory rewards resolve separately through the required room choices and the run's explicit reward policy."

func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
