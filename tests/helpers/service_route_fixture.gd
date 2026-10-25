extends RefCounted
## RC-030 ONLY. Excluded genuine battle → service → battle → event → shop route.
## No fixture reward Gold, forced victories, manufactured damage or new content.
const Base = preload("res://tests/helpers/encounter_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const VARIANTS := {"recovery": "", "satchel": "event_lost_satchel", "tithe": "event_blood_tithe", "reliquary": "event_sealed_reliquary", "desk": "event_etched_desk"}

class FixtureRoute extends Base.FixtureRoute:
	func _init(run_id: String, seed: int, variant: String = "recovery") -> void:
		super(run_id, seed)
		_graph.route_id = "rc030_service_fixture-%d-%s" % [seed, variant]
		_graph.display_name = "Recovery and event integration fixture"
		for node in _graph.nodes:
			if node.depth == 2:
				_service(node, "recovery" if variant == "recovery" else "event", VARIANTS.get(variant, "event_unknown"))
			elif node.depth == 3:
				node.merge({"room_id": "room_normal", "room_type": "normal", "room_reference": "", "enemy_id": "dev_calibration_wisp", "encounter_id": "rc007_entry_probe_next", "encounter_role": "development", "board_id": "board_ossuary", "title": "Calibration Wisp", "display_name": "Calibration Wisp", "content_pending": false, "fixture_loadout": "starter"}, true)
			elif node.depth == 4:
				_service(node, "event", "event_blood_tithe")
			elif node.depth == 5:
				_service(node, "shop", "")
			_nodes[node.id] = node

	func _service(node: Dictionary, kind: String, reference: String) -> void:
		node.merge({"room_id": "room_" + kind, "room_type": kind, "room_reference": reference, "enemy_id": "", "encounter_id": "", "encounter_role": "", "board_id": "", "title": kind.capitalize(), "display_name": kind.capitalize(), "content_pending": false}, true)
		node.erase("fixture_loadout")

static func new_run(seed: int = 42, variant: String = "recovery"):
	var setup: Dictionary = Loader.load_setup().setup
	return Run.new(setup, seed, true, func(id, route_seed): return FixtureRoute.new(id, route_seed, variant), Base.FixtureResolver.new(), {}, Profile.new(setup.catalog))

static func context_for(subject) -> Dictionary:
	var result: Dictionary = subject.restore_context_for_tests()
	for node in subject._route._graph.nodes:
		if node.encounter_id.is_empty(): continue
		var resolved: Dictionary = subject._resolver.resolve(node, subject._entry_data())
		if resolved.get("ok", false): result.setups[Run.content_signature(resolved.setup)] = resolved.setup
	return result

static func next_node(subject) -> String:
	var available: Array = subject.route_snapshot().nodes.filter(func(node): return node.state == "available")
	return "" if available.is_empty() else available[0].id

static func win_battle(subject, node_id: String = "") -> Dictionary:
	if node_id.is_empty(): node_id = next_node(subject)
	var requested: Dictionary = subject.request_room_entry(node_id)
	if not requested.ok: return requested
	var prepared: Dictionary = subject.prepare_route_battle(requested.token)
	if not prepared.ok: return prepared
	var entered: Dictionary = subject.commit_route_battle(prepared)
	if not entered.ok: return entered
	if not Integration.new()._win(entered.combat) or not subject.resolve_battle(entered.combat): return {"ok": false, "error": "Fixture could not win a real battle."}
	if not subject.acknowledge_result(subject.snapshot().pending_result.identity): return {"ok": false, "error": "Fixture result acknowledgement failed."}
	return {"ok": true, "node_id": next_node(subject), "player_hp": subject.snapshot().player_hp}

static func enter_service(subject, node_id: String = "") -> Dictionary:
	if node_id.is_empty(): node_id = next_node(subject)
	var requested: Dictionary = subject.request_room_entry(node_id)
	if not requested.ok: return requested
	var prepared: Dictionary = subject.prepare_route_service(requested.token)
	return subject.commit_route_service(prepared) if prepared.ok else prepared

static func enter_shop(subject) -> Dictionary:
	var requested: Dictionary = subject.request_room_entry(next_node(subject))
	if not requested.ok: return requested
	var prepared: Dictionary = subject.prepare_route_shop(requested.token)
	return subject.commit_route_shop(prepared) if prepared.ok else prepared
