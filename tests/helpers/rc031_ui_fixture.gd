extends RefCounted
## Excluded RC-031 UI fixture. Real supported Wisp victory and explicitly
## configured fixture reward fund the item room; production policies are untouched.
const Service = preload("res://tests/helpers/service_route_fixture.gd")
const Shop = preload("res://tests/helpers/shop_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")

class FixtureRoute extends Service.FixtureRoute:
	func _init(run_id: String, seed: int, variant: String) -> void:
		super(run_id, seed, "recovery" if variant == "shop" else variant)
		_graph.route_id = "rc031_ui_fixture-%d-%s" % [seed, variant]
		_graph.display_name = "Rune upgrade and relic UI fixture"
		if variant == "shop":
			for node in _graph.nodes:
				if node.depth == 2:
					_service(node, "shop", "")
					_nodes[node.id] = node

static func new_run(seed: int = 42, variant: String = "shop"):
	var setup: Dictionary = Loader.load_setup().setup
	var rules: Dictionary = Shop.reward_rules(160)
	rules.policy_id = "rc031_ui_fixture_reward_v1"
	return Run.new(setup, seed, true, func(id, route_seed): return FixtureRoute.new(id, route_seed, variant), Shop.FixtureResolver.new(), rules, Profile.new(setup.catalog))

static func win_first(subject) -> Dictionary:
	return Shop.win_first(subject)

static func context_for(subject) -> Dictionary:
	return Service.context_for(subject)

static func next_node(subject) -> String:
	return Service.next_node(subject)
