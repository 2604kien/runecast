extends RefCounted
## Excluded nine-visit RC-032 lifecycle fixture. Ordinary entry/Combat/room
## commands only. No completed-visit construction or postlaunch resource edits.
const Run = preload("res://scripts/core/run_state.gd")
const Route = preload("res://scripts/core/route_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const FIXTURE_SOURCES := {
	"rc032_calibration_normal": {"file": "normal", "enemy": "dev_rc032_spark", "role": "normal", "board": "board_gallery"},
	"rc032_calibration_elite": {"file": "elite", "enemy": "dev_rc032_elite", "role": "elite", "board": "board_ossuary"},
	"rc032_calibration_guardian": {"file": "guardian", "enemy": "dev_rc032_guardian", "role": "guardian", "board": "board_belfry"}}

class FixtureRoute extends Route:
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		preload("res://tests/helpers/legacy_route_shape.gd").retain(self)
		_graph.route_id = "rc032_full_route_fixture-%d" % seed
		_graph.display_name = "RC-032 development fixture"
		for node in _graph.nodes:
			if node.depth in [1, 3, 4] or node.id == "d5a":
				_battle(node, "normal", "rc032_calibration_normal", "dev_rc032_spark", "board_gallery", "FIXTURE Calibration Spark")
			elif node.id == "d5b":
				_battle(node, "elite", "rc032_calibration_elite", "dev_rc032_elite", "board_ossuary", "FIXTURE Calibration Elite")
			elif node.depth == 2:
				node.room_reference = "event_lost_satchel" if node.lane == 0 else "event_sealed_reliquary"
				node.title = "Lost Satchel" if node.lane == 0 else "Sealed Reliquary"
				node.display_name = node.title
				node.content_pending = false
			elif node.depth == 9:
				_battle(node, "guardian", "rc032_calibration_guardian", "dev_rc032_guardian", "board_belfry", "FIXTURE Calibration Guardian")
			_nodes[node.id] = node

	func _battle(node: Dictionary, family: String, encounter: String, enemy: String, board: String, title: String) -> void:
		node.merge({"room_id": "room_" + family, "room_type": family, "room_reference": "", "enemy_id": enemy,
			"encounter_id": encounter, "encounter_role": family, "board_id": board, "title": title,
			"display_name": title, "content_pending": false}, true)

class FixtureResolver extends "res://scripts/core/encounter_resolver.gd":
	func resolve(node: Dictionary, entry: Dictionary) -> Dictionary:
		var id := str(node.get("encounter_id", ""))
		if id == "training_shadeling": return super(node, entry)
		if not FIXTURE_SOURCES.has(id): return _failure("Unknown excluded RC-032 encounter.")
		var spec: Dictionary = FIXTURE_SOURCES[id]
		if node.get("enemy_id") != spec.enemy or node.get("encounter_role") != spec.role or node.get("board_id") != spec.board:
			return _failure("The excluded fixture role/identity/board does not match its explicit registration.")
		var path := "res://tests/fixtures/rc032/" + str(spec.file) + ".json"
		var loaded: Dictionary = Loader.load_setup(path, {"enemies": "res://tests/fixtures/rc032/enemies.json"})
		if not loaded.ok: return _failure("\n".join(loaded.errors))
		var setup: Dictionary = loaded.setup
		setup.owned_cards = entry.get("owned_cards", []).map(func(card): return card.get("id", ""))
		entry = entry.duplicate(true)
		entry.encounter_id = id
		var error := Combat.validate_run_entry(setup, entry)
		if not error.is_empty(): return _failure(error)
		setup.encounter.encounter_role = spec.role
		return {"ok": true, "error": "", "setup": setup, "entry": entry, "source_path": path,
			"pending_choices": ["encounter_rewards"], "reward_policy": _reward_policy()}
	func _reward_policy() -> String:
		return "Excluded RC-032 fixture: each calibration normal/elite victory offers one optional rune and 250 Gold; Shadeling and calibration guardian each offer a rune and one still-locked definition, or nothing when exhausted. Not production rewards or balance."

static func reward_rules() -> Dictionary:
	var rules: Array = []
	for id in FIXTURE_SOURCES:
		var role: String = FIXTURE_SOURCES[id].role
		rules.append({"encounter_role": role, "encounter_id": id, "choice_id": "encounter_rewards", "eligible_ids": Profile.INITIAL_IDS.duplicate(), "offer_count": 3, "gold": 0 if role == "guardian" else 250, "allow_skip": true, "permanent_unlock": role == "guardian"})
	rules.append({"encounter_role": "boss", "encounter_id": "training_shadeling", "choice_id": "encounter_rewards", "eligible_ids": Profile.INITIAL_IDS.duplicate(), "offer_count": 3, "gold": 0, "allow_skip": true, "permanent_unlock": true})
	return {"policy_id": "rc032_full_route_fixture_rewards_v1", "rules": rules}

static func new_run(seed: int = 42, exhausted: bool = false):
	var setup: Dictionary = Loader.load_setup().setup
	return Run.new(setup, seed, true, func(id, route_seed): return FixtureRoute.new(id, route_seed),
		FixtureResolver.new(), reward_rules(), Profile.new(setup.catalog, Profile.INITIAL_IDS if exhausted else ["spark", "shield"]))

static func context_for(subject) -> Dictionary:
	var context: Dictionary = subject.restore_context_for_tests()
	for node in subject._route._graph.nodes:
		if node.encounter_id.is_empty(): continue
		var resolved: Dictionary = subject._resolver.resolve(node, subject._entry_data())
		if resolved.get("ok", false): context.setups[Run.content_signature(resolved.setup)] = resolved.setup
	return context

static func next_node(subject, branch: String = "normal") -> String:
	var available: Array = subject.route_snapshot().nodes.filter(func(node): return node.state == "available")
	if available.is_empty(): return ""
	if available[0].depth == 1:
		# The normal variant visits Satchel; elite visits Reliquary via a legal link.
		var event_id := "d2a" if branch == "normal" else "d2b"
		for node in available:
			if event_id in node.next_ids: return node.id
	if available[0].depth == 5: return "d5a" if branch == "normal" else "d5b"
	return available[0].id

static func enter_next(subject, branch: String = "normal") -> Dictionary:
	var id := next_node(subject, branch)
	var node: Dictionary = subject.inspect_node(id)
	var request: Dictionary = subject.request_room_entry(id)
	if not request.ok: return request
	var candidate: Dictionary
	match node.room_type:
		"shop":
			candidate = subject.prepare_route_shop(request.token)
			return subject.commit_route_shop(candidate) if candidate.ok else candidate
		"event", "recovery":
			candidate = subject.prepare_route_service(request.token)
			return subject.commit_route_service(candidate) if candidate.ok else candidate
		_:
			candidate = subject.prepare_route_battle(request.token)
			return subject.commit_route_battle(candidate) if candidate.ok else candidate

static func win_combat(game, trace: Array = []) -> bool:
	var controller := Controller.new(game)
	var player := Player.new()
	controller.command_resolved.connect(func(outcome):
		var current: Dictionary = game.snapshot()
		trace.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted,
			"turn": current.turn, "state": current.state, "player_hp": current.player_hp, "enemy_hp": current.enemy_hp}))
	for turn in range(60):
		if game.state != "playing": break
		if not player.play_turn(controller):
			controller.dispose()
			return false
	controller.dispose()
	return game.state == "victory"

static func finish_rewards(subject, acknowledge: bool = true, unlock_first: bool = false) -> Dictionary:
	var records: Array = subject.snapshot().reward_records.filter(func(record): return record.status == "pending")
	if unlock_first: records.reverse()
	for record in records:
		var result: Dictionary
		if record.resolution == "pending":
			result = subject.choose_reward(record.identity, record.offered_ids[0]) if record.kind == "definition_unlock" else subject.skip_reward(record.identity)
			if not result.ok: return result
		if not record.gold_claimed:
			result = subject.claim_reward_gold(record.identity)
			if not result.ok: return result
	var pending: Dictionary = subject.snapshot().pending_result
	if acknowledge and not pending.is_empty() and not subject.acknowledge_result(pending.identity): return {"ok": false, "error": "Result acknowledgement failed."}
	return {"ok": true}

static func finish_room(subject) -> Dictionary:
	var shop: Dictionary = subject.shop_snapshot()
	if not shop.is_empty():
		var result: Dictionary = subject.buy_shop_rune(shop.identity, shop.slots[0].slot_id)
		if not result.ok: return result
		result = subject.upgrade_shop_rune(shop.identity, 0)
		if not result.ok: return result
		result = subject.buy_shop_relic(shop.identity)
		if not result.ok: return result
		return subject.leave_shop(shop.identity)
	var room: Dictionary = subject.service_snapshot()
	if room.is_empty(): return {"ok": false, "error": "No active supported room."}
	match room.definition_id:
		"event_lost_satchel": return subject.resolve_service(room.identity, "take_gold")
		"event_sealed_reliquary": return subject.resolve_service(room.identity, "open_reliquary", room.offered_relics[0])
		"recovery": return subject.resolve_service(room.identity, "recover")
	return {"ok": false, "error": "Unknown fixture service."}

static func play_to_guardian_pending(subject, branch: String = "normal") -> Dictionary:
	for depth in range(1, 10):
		var entered := enter_next(subject, branch)
		if not entered.ok: return entered
		if entered.has("combat"):
			if not win_combat(entered.combat) or not subject.resolve_battle(entered.combat): return {"ok": false, "error": "Legal fixture battle failed at depth %d." % depth}
			if depth == 9: return {"ok": true}
			var awards := finish_rewards(subject)
			if not awards.ok: return awards
		else:
			var completed := finish_room(subject)
			if not completed.ok: return completed
	return {"ok": false, "error": "Guardian was not reached."}
