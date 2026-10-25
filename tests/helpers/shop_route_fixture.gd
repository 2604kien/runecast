extends RefCounted
## RC-029 ONLY. Excluded integration route, explicit configured victory Gold.
## Every visit is entered/resolved through the real run APIs; never fabricated.
const Base = preload("res://tests/helpers/encounter_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")

class FixtureRoute extends Base.FixtureRoute:
	func _init(run_id: String, seed: int, removal_chain: bool = false) -> void:
		super(run_id, seed)
		_graph.route_id = "rc029_shop_fixture-%d%s" % [seed, "-removals" if removal_chain else ""]
		_graph.display_name = "Shop integration fixture"
		for node in _graph.nodes:
			if node.depth == 2 or (removal_chain and node.depth in [3, 4, 5]):
				node.merge({"room_id": "room_shop", "room_type": "shop", "room_reference": "", "enemy_id": "", "encounter_id": "", "encounter_role": "", "board_id": "", "title": "Shop", "display_name": "Shop", "content_pending": false}, true)
				node.erase("fixture_loadout")
			elif node.depth == 3:
				node.merge({"room_id": "room_normal", "room_type": "normal", "room_reference": "", "enemy_id": "dev_calibration_wisp", "encounter_id": "rc007_entry_probe_next", "encounter_role": "development", "board_id": "board_ossuary", "title": "Calibration Wisp", "display_name": "Calibration Wisp", "content_pending": false, "fixture_loadout": "starter"}, true)
			_nodes[node.id] = node

class FixtureResolver extends Base.FixtureResolver:
	func _choices(_node: Dictionary) -> Array:
		return ["encounter_rewards"]
	func _reward_policy() -> String:
		return "Explicit isolated shop verification payout; not production tuning."

static func reward_rules(gold: int = 100) -> Dictionary:
	return {"policy_id": "rc029_shop_fixture_reward_v1", "rules": [
		{"encounter_role": "development", "encounter_id": "rc007_entry_probe_next", "choice_id": "encounter_rewards", "eligible_ids": Profile.INITIAL_IDS.duplicate(), "offer_count": 3, "gold": gold, "allow_skip": true},
		{"encounter_role": "boss", "encounter_id": "training_shadeling", "choice_id": "encounter_rewards", "eligible_ids": Profile.INITIAL_IDS.duplicate(), "offer_count": 3, "gold": 0, "allow_skip": true}]}

static func new_run(seed: int = 42, gold: int = 100, unlocked: Array = Profile.INITIAL_IDS, removal_chain: bool = false):
	var setup: Dictionary = Loader.load_setup().setup
	return Run.new(setup, seed, true, func(id, route_seed): return FixtureRoute.new(id, route_seed, removal_chain), FixtureResolver.new(), reward_rules(gold), Profile.new(setup.catalog, unlocked))

static func context_for(subject) -> Dictionary:
	var result: Dictionary = subject.restore_context_for_tests()
	for node in subject._route._graph.nodes:
		if node.encounter_id.is_empty(): continue
		var resolved: Dictionary = subject._resolver.resolve(node, subject._entry_data())
		if resolved.get("ok", false): result.setups[Run.content_signature(resolved.setup)] = resolved.setup
	return result

static func win_first(subject, choose_rune: bool = false) -> Dictionary:
	var requested: Dictionary = subject.request_room_entry("d1a")
	if not requested.ok: return requested
	var prepared: Dictionary = subject.prepare_route_battle(requested.token)
	if not prepared.ok: return prepared
	var entered: Dictionary = subject.commit_route_battle(prepared)
	if not entered.ok: return entered
	if not Integration.new()._win(entered.combat) or not subject.resolve_battle(entered.combat): return {"ok": false, "error": "Fixture could not win a real battle."}
	var reward: Dictionary = subject.pending_reward()
	var claimed: Dictionary = subject.choose_reward(reward.identity, reward.offered_ids[0]) if choose_rune and not reward.offered_ids.is_empty() else subject.skip_reward(reward.identity)
	if not claimed.ok: return claimed
	if reward.gold_amount > 0:
		claimed = subject.claim_reward_gold(reward.identity)
		if not claimed.ok: return claimed
	if not subject.acknowledge_result(subject.snapshot().pending_result.identity): return {"ok": false, "error": "Fixture result acknowledgement failed."}
	return {"ok": true, "shop_node": subject.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id}

static func enter_shop(subject, node_id: String = "") -> Dictionary:
	if node_id.is_empty(): node_id = subject.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	var requested: Dictionary = subject.request_room_entry(node_id)
	if not requested.ok: return requested
	var prepared: Dictionary = subject.prepare_route_shop(requested.token)
	return subject.commit_route_shop(prepared) if prepared.ok else prepared
