extends RefCounted
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")

static func new_run(seed: int):
	return Run.new(Loader.load_setup().setup, seed, true, Callable(), null, Profile.production_rules())

static func next_node(run, branch: String) -> String:
	var available: Array = run.route_snapshot().nodes.filter(func(node): return node.state == "available")
	if available.is_empty(): return ""
	if available[0].depth == 5: return "d5b" if branch == "elite" else "d5a"
	if available[0].depth == 1:
		# Prefer the free upgrade event when one is reachable. This is an ordinary
		# visible route choice, never seed alteration or a fabricated prior visit.
		for node in available:
			for destination in node.next_ids:
				if run.inspect_node(destination).room_reference == "event_etched_desk": return node.id
	for node in available:
		if node.enemy_id == "wickling": return node.id
	return available[0].id

static func enter(run, id: String) -> Dictionary:
	var node: Dictionary = run.inspect_node(id)
	var request: Dictionary = run.request_room_entry(id)
	if not request.ok: return request
	var prepared: Dictionary
	match node.room_type:
		"shop":
			prepared = run.prepare_route_shop(request.token)
			return run.commit_route_shop(prepared) if prepared.ok else prepared
		"event", "recovery":
			prepared = run.prepare_route_service(request.token)
			return run.commit_route_service(prepared) if prepared.ok else prepared
		_:
			prepared = run.prepare_route_battle(request.token)
			return run.commit_route_battle(prepared) if prepared.ok else prepared

static func choose_card(record: Dictionary) -> String:
	if record.get("kind") == "definition_unlock" and not record.offered_ids.is_empty():
		return str(record.offered_ids[0])
	for id in ["conjure", "shield", "spark", "focus"]:
		if id in record.offered_ids: return id
	return ""

static func upgrade_uid(run) -> int:
	for id in ["conjure", "shield", "spark", "focus"]:
		for card in run.snapshot().owned_cards:
			if card.id == id and card.upgrade_rank == 0: return card.uid
	return -1

static func finish_rewards(run) -> Dictionary:
	for record in run.snapshot().reward_records:
		if record.status != "pending": continue
		if record.resolution == "pending":
			var id := str(record.offered_ids[0]) if record.kind == "definition_unlock" and not record.offered_ids.is_empty() else choose_card(record)
			var chosen: Dictionary = run.skip_reward(record.identity) if id.is_empty() else run.choose_reward(record.identity, id)
			if not chosen.ok: return chosen
		if not record.gold_claimed:
			var gold: Dictionary = run.claim_reward_gold(record.identity)
			if not gold.ok: return gold
	var pending: Dictionary = run.snapshot().pending_result
	if not pending.is_empty() and not run.acknowledge_result(pending.identity): return {"ok": false, "error": "acknowledge rejected"}
	return {"ok": true}

static func service_choice(run) -> Dictionary:
	var room: Dictionary = run.service_snapshot()
	match room.definition_id:
		"event_etched_desk": return {"choice": "refine_rune", "target": upgrade_uid(run)}
		"event_lost_satchel": return {"choice": "take_gold", "target": null}
		"recovery":
			if run.snapshot().player_hp < run.snapshot().player_max_hp: return {"choice": "recover", "target": null}
			return {"choice": "refine_rune", "target": upgrade_uid(run)}
	return {"choice": "leave", "target": null}

static func finish_room(run) -> Dictionary:
	var shop: Dictionary = run.shop_snapshot()
	if not shop.is_empty(): return run.leave_shop(shop.identity)
	var room: Dictionary = run.service_snapshot()
	var choice := service_choice(run)
	return run.resolve_service(room.identity, choice.choice, choice.target)

static func play(seed: int, branch: String) -> Dictionary:
	var run = new_run(seed)
	var history: Array = []
	for depth in range(1, 10):
		var id := next_node(run, branch)
		var node: Dictionary = run.inspect_node(id)
		var entered := enter(run, id)
		if not entered.ok: return {"error": entered.get("error"), "seed": seed, "branch": branch, "history": history}
		var record := {"node": node, "entry": run.snapshot()}
		if entered.has("combat"):
			var controller := Controller.new(entered.combat)
			var player := Player.new()
			var commands: Array = []
			var turns: Array = []
			controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
			for turn in 80:
				if entered.combat.state != "playing": break
				if not player.play_turn(controller): return {"error": "legal player failed", "seed": seed, "branch": branch}
				turns.append({"turn": entered.combat.turn, "hp": entered.combat.player_hp, "enemy_hp": entered.combat.enemy_hp, "events": entered.combat.last_result().events})
			controller.dispose()
			record.commands = commands
			record.turns = turns
			record.outcome = entered.combat.state
			if not run.resolve_battle(entered.combat): return {"error": "resolve failed", "seed": seed, "branch": branch}
			if entered.combat.state != "victory":
				history.append(record)
				return {"seed": seed, "branch": branch, "outcome": "defeat", "depth": depth, "history": history, "final": run.export_save()}
			var rewards := finish_rewards(run)
			if not rewards.ok: return {"error": rewards.error, "seed": seed, "branch": branch}
		else:
			record.choice = service_choice(run) if node.room_type != "shop" else {"choice": "leave"}
			var result := finish_room(run)
			if not result.ok: return {"error": result.error, "seed": seed, "branch": branch}
		record.after = run.snapshot()
		history.append(record)
	return {"seed": seed, "branch": branch, "outcome": "victory", "depth": 9, "history": history, "final": run.export_save()}
