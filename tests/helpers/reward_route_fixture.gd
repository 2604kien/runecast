extends RefCounted
## RC-027 reward-enabled verification only. Excluded from production exports.
## Reuses actual Wisp content and ordinary controller actions; no fake visits.
const BaseFixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const RunState = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Progression = preload("res://scripts/core/progression_state.gd")

class FixtureRoute extends BaseFixture.FixtureRoute:
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		_graph.route_id = "rc027_reward_enabled_fixture-%d" % seed
		_graph.display_name = "Reward-enabled test fixture"

class FixtureResolver extends BaseFixture.FixtureResolver:
	func _choices(_node: Dictionary) -> Array:
		return ["encounter_rewards"]
	func _reward_policy() -> String:
		return "Explicit verification policy only: three distinct implemented definitions, one optional run copy, and 7 run Gold per Wisp victory. No permanent acquisition. These are not production rules."

static func reward_rules() -> Dictionary:
	return {"policy_id": "rc027_reward_enabled_test_v1", "rules": [{
		"encounter_role": "development", "encounter_id": "rc007_entry_probe_next",
		"choice_id": "encounter_rewards", "eligible_ids": ["spark", "shield", "focus", "conjure"],
		"offer_count": 3, "gold": 7, "allow_skip": true}]}

static func new_run(seed: int = 42):
	var setup: Dictionary = Loader.load_setup().setup
	return RunState.new(setup, seed, true,
		func(run_id, route_seed): return FixtureRoute.new(run_id, route_seed),
		FixtureResolver.new(), reward_rules(), Progression.new(setup.catalog))
