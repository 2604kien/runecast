extends RefCounted
## Explicit reward-free integration route. Not reachable from production New Run
## and excluded from resource exports. Enemy definitions and tuning are reused.

const RunState = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

class FixtureRoute extends "res://scripts/core/route_state.gd":
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		preload("res://tests/helpers/legacy_route_shape.gd").retain(self)
		# Preserve nine depths, branches, d6 Shadeling and d9 guardian. Only the
		# first two fixture depths substitute actual supported development Wisp.
		_graph.route_id = "rc026_reward_free_fixture-%d" % seed
		_graph.display_name = "Reward-free integration fixture"
		for node in _graph.nodes:
			if node.depth in [1, 2]:
				node.room_id = "room_normal"
				node.room_type = "normal"
				node.room_reference = ""
				node.enemy_id = "dev_calibration_wisp"
				node.encounter_id = "rc007_entry_probe_next"
				node.encounter_role = "development"
				node.board_id = "board_gallery" if node.depth == 1 else "board_ossuary"
				node.title = "FIXTURE %d · Calibration Wisp" % node.depth
				node.display_name = node.title
				node.content_pending = false
				node.fixture_loadout = "dev_entry" if node.depth == 1 else "starter"
				_nodes[node.id] = node

class FixtureResolver extends "res://scripts/core/encounter_resolver.gd":
	func _supports_node(node: Dictionary) -> bool:
		# The retained boss-boundary fixture predates production board binding.
		# This capability exists only in the excluded resolver, never saved data.
		return super(node) or (node.get("encounter_id") == "training_shadeling" and node.get("enemy_id") == "shadeling" and node.get("encounter_role") == "boss" and node.get("board_id") == "board_gallery")
	func _load(node: Dictionary, path: String) -> Dictionary:
		return Loader.load_selected_encounter(path, str(node.get("board_id", "")), str(node.get("fixture_loadout", "")))
	func _choices(_node: Dictionary) -> Array:
		return []
	func _reward_policy() -> String:
		return "Reward-free verification fixture: no Gold, cards, healing, relics, perks or permanent unlocks."

static func new_run(seed: int = 42, require_choices: bool = false):
	return RunState.new(Loader.load_setup().setup, seed, true,
		func(run_id, route_seed): return FixtureRoute.new(run_id, route_seed),
		preload("res://scripts/core/encounter_resolver.gd").new() if require_choices else FixtureResolver.new())
