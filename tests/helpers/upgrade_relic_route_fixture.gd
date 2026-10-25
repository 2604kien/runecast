extends RefCounted
## RC-031 only: genuine Wisp battle, explicit fixture payout, chronological
## recovery/shop/event chain. Excluded from release; no invented victories.
const Base = preload("res://tests/helpers/shop_route_fixture.gd")
const Services = preload("res://tests/helpers/service_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")

class FixtureRoute extends Base.FixtureRoute:
	func _init(run_id: String, seed: int, variant: String = "history") -> void:
		super(run_id, seed)
		_graph.route_id = "rc031_upgrade_relic_fixture-%d%s" % [seed, "" if variant == "history" else "-" + variant]
		_graph.display_name = "Upgrade and relic history fixture"
		for node in _graph.nodes:
			var depth: int = node.depth
			if depth == 1 and variant != "upgrade_exhaustion": continue
			var kind := "recovery" if depth in [2, 6] else "shop" if depth in [3, 5] else "event"
			var reference := "event_blood_tithe" if depth == 4 else "event_etched_desk" if depth == 8 else "event_sealed_reliquary" if depth == 9 else ""
			if variant == "upgrade_exhaustion":
				kind = "recovery"
				reference = ""
			elif variant == "relic_exhaustion":
				kind = "shop" if depth in [2, 3, 4, 5, 6, 8] else "event"
				reference = "event_sealed_reliquary" if kind == "event" else ""
			if depth == 7 and variant == "history":
				node.merge({"room_id": "room_normal", "room_type": "normal", "room_reference": "", "enemy_id": "dev_calibration_wisp", "encounter_id": "rc007_entry_probe_next", "encounter_role": "development", "board_id": "board_ossuary", "title": "Calibration Wisp", "display_name": "Calibration Wisp", "content_pending": false, "fixture_loadout": "starter"}, true)
			else:
				node.merge({"room_id": "room_" + kind, "room_type": kind, "room_reference": reference, "enemy_id": "", "encounter_id": "", "encounter_role": "", "board_id": "", "title": kind.capitalize(), "display_name": kind.capitalize(), "content_pending": false}, true)
				node.erase("fixture_loadout")
			_nodes[node.id] = node

static func new_run(seed: int = 42, variant: String = "history"):
	var setup: Dictionary = Loader.load_setup().setup
	return Run.new(setup, seed, true, func(id, route_seed): return FixtureRoute.new(id, route_seed, variant), Base.FixtureResolver.new(), Base.reward_rules(500), Profile.new(setup.catalog))

static func context_for(subject) -> Dictionary:
	return Base.context_for(subject)

static func enter_service(subject) -> Dictionary:
	return Services.enter_service(subject)

static func enter_shop(subject) -> Dictionary:
	return Base.enter_shop(subject)

static func next_node(subject) -> String:
	return Services.next_node(subject)
