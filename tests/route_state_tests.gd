extends RefCounted
## Fixture adapters live only in tests. They exercise navigation transactions,
## never simulate production battle, reward, healing or shop implementation.

const Route = preload("res://scripts/core/route_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func run(check: Callable) -> void:
	var setup: Dictionary = Loader.load_setup().setup
	_graphs(check)
	_invalid_graphs(check)
	_isolation(check, setup)
	_entry_boundaries(check, setup)
	_completion_boundaries(check, setup)
	_all_paths(check, setup)

func _paths(graph: Dictionary) -> Array:
	var by_id := {}
	for node in graph.nodes: by_id[node.id] = node
	var pending: Array = []
	var completed: Array = []
	for id in graph.entry_node_ids: pending.append([id])
	while not pending.is_empty():
		var path: Array = pending.pop_front()
		var successors: Array = by_id[path[-1]].next_ids
		if successors.is_empty(): completed.append(path)
		for id in successors: pending.append(path + [id])
	return completed

func _graphs(check: Callable) -> void:
	var variants := {}
	for seed in range(64):
		var graph := Route.generate(seed)
		var same := Route.generate(seed)
		check.call(graph == same and Route.validate_graph(graph).ok, "RC-025: seed %d generates one reproducible valid bounded graph." % seed)
		var nodes := {}
		for node in graph.nodes: nodes[node.id] = node
		var paths := _paths(graph)
		var valid := paths.size() == 8
		for path in paths:
			var roles: Array = []
			var rooms: Array = []
			var depths: Array = []
			for id in path:
				roles.append(nodes[id].encounter_role)
				rooms.append(nodes[id].room_type)
				depths.append(nodes[id].depth)
			valid = valid and path.size() == 9 and depths == range(1, 10)
			valid = valid and rooms[7] == "recovery" and roles[5] == "boss" and roles[8] == "guardian"
			valid = valid and nodes[path[5]].enemy_id == "shadeling" and nodes[path[8]].enemy_id == "bell_keeper"
		check.call(valid and graph.nodes.size() > 9, "RC-025: all eight legal paths for seed %d contain nine visits, one boss, recovery and a distinct guardian." % seed)
		var normal_ok := true
		for node in graph.nodes:
			if node.encounter_role == "normal": normal_ok = normal_ok and node.enemy_id in Route.NORMAL_ENEMIES and node.enemy_id != "shadeling"
		check.call(normal_ok and nodes.d5a.encounter_role == "normal" and nodes.d5b.encounter_role == "elite", "RC-025: seed %d retains a meaningful normal/elite choice and excludes Shadeling from normal pools." % seed)
		variants[JSON.stringify(graph.nodes)] = true
	check.call(variants.size() > 1 and Route.generate(-1).is_empty() and Route.validate_graph(Route.generate(9007199254740993)).ok, "RC-028: route references vary with the independent integer seed; negative seeds reject and 64-bit seeds remain exact.")

func _invalid_graphs(check: Callable) -> void:
	for fault in ["version", "seed", "identity", "length", "nodes_type", "empty_nodes", "huge_nodes", "node_type", "duplicate_id",
		"missing_id", "depth_type", "depth_range", "lane_type", "lane_range", "room", "room_mismatch", "next_type", "unknown_next",
		"duplicate_next", "backward", "cycle", "self", "dead_end", "guardian_successor", "edge_missing", "edge_unknown", "edge_duplicate",
		"entry_missing", "entry_unknown", "entry_duplicate", "entry_middle", "unreachable", "normal_shadeling", "boss_actor", "boss_encounter",
		"guardian_shadeling", "guardian_role", "elite", "board", "event", "service_encounter", "invented_encounter", "no_recovery"]:
		var graph := Route.generate(42)
		match fault:
			"version": graph.version = "unknown"
			"seed": graph.seed = []
			"identity": graph.route_id = ""
			"length": graph.path_length = 10
			"nodes_type": graph.nodes = {}
			"empty_nodes": graph.nodes = []
			"huge_nodes": graph.nodes.resize(33)
			"node_type": graph.nodes[0] = "invalid"
			"duplicate_id": graph.nodes[1].id = graph.nodes[0].id
			"missing_id": graph.nodes[0].erase("id")
			"depth_type": graph.nodes[0].depth = []
			"depth_range": graph.nodes[0].depth = 0
			"lane_type": graph.nodes[0].lane = []
			"lane_range": graph.nodes[0].lane = 2
			"room": graph.nodes[0].room_id = "room_boss"
			"room_mismatch": graph.nodes[0].room_type = "event"
			"next_type": graph.nodes[0].next_ids = "invalid"
			"unknown_next": graph.nodes[0].next_ids = ["missing"]
			"duplicate_next": graph.nodes[0].next_ids.append(graph.nodes[0].next_ids[0])
			"backward": graph.nodes[4].next_ids = ["d1a"]
			"cycle": graph.nodes[4].next_ids = ["d2a"]
			"self": graph.nodes[0].next_ids = ["d1a"]
			"dead_end": graph.nodes[0].next_ids = []
			"guardian_successor": graph.nodes[-1].next_ids = ["d1a"]
			"edge_missing": graph.edges.pop_back()
			"edge_unknown": graph.edges[0].to = "missing"
			"edge_duplicate": graph.edges[0] = graph.edges[1].duplicate()
			"entry_missing": graph.entry_node_ids = []
			"entry_unknown": graph.entry_node_ids = ["missing"]
			"entry_duplicate": graph.entry_node_ids = ["d1a", "d1a"]
			"entry_middle": graph.entry_node_ids = ["d3"]
			"unreachable":
				graph.nodes[0].next_ids = graph.nodes[1].next_ids.duplicate()
				graph.edges = _edges(graph.nodes)
			"normal_shadeling": graph.nodes[0].enemy_id = "shadeling"
			"boss_actor": graph.nodes[9].enemy_id = "wickling"
			"boss_encounter": graph.nodes[9].encounter_id = "new_boss"
			"guardian_shadeling": graph.nodes[-1].enemy_id = "shadeling"
			"guardian_role": graph.nodes[-1].encounter_role = "boss"
			"elite": graph.nodes[8].enemy_id = "wickling"
			"board": graph.nodes[0].board_id = "missing"
			"event": graph.nodes[2].room_reference = "missing"
			"service_encounter": graph.nodes[10].encounter_id = "training_shadeling"
			"invented_encounter": graph.nodes[0].encounter_id = "unapproved_normal"
			"no_recovery":
				graph.nodes[-2].room_id = "room_shop"
				graph.nodes[-2].room_type = "shop"
		var before := graph.duplicate(true)
		var result := Route.validate_graph(graph)
		check.call(not result.ok and not result.errors.is_empty() and graph == before, "RC-025: malformed %s graph rejects without changing input or traversing invalid connections." % fault)

func _edges(nodes: Array) -> Array:
	var edges: Array = []
	for node in nodes:
		for id in node.next_ids: edges.append({"from": node.id, "to": id})
	return edges

func _isolation(check: Callable, setup: Dictionary) -> void:
	var first := Run.new(setup, 991, true)
	var second := Run.new(setup, 991, true)
	var standalone := Run.new(setup, 991)
	var initial := first.snapshot()
	check.call(initial.mode == "route" and initial.status == "route_ready" and initial.can_continue and initial.current_node_id == "" and initial.route.visits.is_empty(), "RC-025: a fresh run starts at its unvisited route, never with fabricated earlier rooms.")
	check.call(initial.route == second.route_snapshot() and initial.run_id != second.snapshot().run_id and initial.rng_states == standalone.snapshot().rng_states, "RC-025: same-seed route identities and topology reproduce while run identities differ and all three combat RNG streams remain untouched.")
	check.call(standalone.route_snapshot().is_empty() and standalone.snapshot().current_node_id == "fixture_shadeling" and standalone.enter_battle().ok, "RC-025: explicit standalone Shadeling remains independent of tower progress.")
	var graph_before := first.route_snapshot()
	standalone.current_battle().pass_turn()
	check.call(first.route_snapshot() == graph_before and not first.enter_battle().ok, "RC-025: combat sampling cannot reroll the independent route; route mode cannot silently enter the standalone boss.")
	for repeat in range(20):
		for node in graph_before.nodes:
			var detail := first.inspect_node(node.id)
			detail.next_ids.clear()
			detail.title = "caller mutation"
		var requested := first.request_room_entry("d1a")
		requested.token.node_id = "d9"
		var detached := first.snapshot()
		detached.route.nodes.clear()
		detached.route.edges.clear()
		detached.route.entry_node_ids.clear()
	check.call(first.snapshot() == initial, "RC-025: repeated inspection, cancelled selection and nested snapshot mutation cannot alter route, references, state or RNG.")
	check.call(not first.inspect_node("missing").ok and not first.request_room_entry("missing").ok and first.snapshot() == initial, "RC-025: unknown inspection and entry reject without changes.")

func _accept(_node: Dictionary, _visit: Dictionary) -> Dictionary:
	return {"ok": true}

# Structural traversal uses the registered service owner now that these rooms
# exist. Only Leave is selected; battle adapters test route status only.
func _enter_fixture_room(run: Run, token: Dictionary) -> Dictionary:
	var room_id: String = run.inspect_node(token.node_id).room_id
	if room_id == "room_shop":
		var prepared := run.prepare_route_shop(token)
		if not prepared.ok: return prepared
		var entered := run.commit_route_shop(prepared)
		if entered.ok: entered.visit = run.route_snapshot().active_visit
		return entered
	if room_id in ["room_event", "room_recovery"]:
		var prepared := run.prepare_route_service(token)
		if not prepared.ok: return prepared
		var entered := run.commit_route_service(prepared)
		if entered.ok: entered.visit = run.route_snapshot().active_visit
		return entered
	return run.confirm_room_entry(token, _accept)

func _complete_fixture_room(run: Run, visit: Dictionary) -> bool:
	var room_id: String = run.inspect_node(visit.node_id).room_id
	if room_id == "room_shop": return run.leave_shop(run.shop_snapshot().identity).ok
	if room_id in ["room_event", "room_recovery"]: return run.resolve_service(run.service_snapshot().identity, "leave").ok
	return run.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed")

func _refuse(node: Dictionary, visit: Dictionary) -> Dictionary:
	node.id = "modified"
	node.next_ids.clear()
	visit.visit_id = "modified"
	return {"ok": false, "error": "Fixture handler failed before entry."}

func _entry_boundaries(check: Callable, setup: Dictionary) -> void:
	var run := Run.new(setup, 42, true)
	var initial := run.snapshot()
	check.call(run.inspect_node("d1a").state == "available" and run.inspect_node("d1b").state == "available" and run.inspect_node("d9").state == "locked", "RC-025: only explicit initial choices are available.")
	var request := run.request_room_entry("d1a")
	check.call(request.ok and run.snapshot() == initial and not run.request_room_entry("d3").ok, "RC-025: entry request is observational and rejects unconnected nodes.")
	var unavailable := run.confirm_room_entry(request.token)
	check.call(not unavailable.ok and "not available" in unavailable.error and run.snapshot() == initial, "RC-025: production room without an adapter reports pending availability and consumes no selection, visit, HP or RNG.")
	check.call(not run.confirm_room_entry(request.token, _refuse).ok and run.snapshot() == initial, "RC-025: failed adapter cannot mutate detached node/visit data or consume the request.")
	for field in ["run_id", "route_id", "node_id", "revision"]:
		var token: Dictionary = request.token.duplicate()
		token[field] = -1 if field == "revision" else "stale"
		check.call(not run.confirm_room_entry(token, _accept).ok and run.snapshot() == initial, "RC-025: mismatched %s rejects stale entry atomically." % field)
	var entered := run.confirm_room_entry(request.token, _accept)
	var active := run.snapshot()
	check.call(entered.ok and active.status == "room_active" and active.route.visit_count == 1 and active.route.completed_count == 0 and active.route.visited_node_ids.is_empty(), "RC-025: successful room acceptance creates one visit without prematurely completing it.")
	check.call(run.inspect_node("d1a").state == "current" and run.inspect_node("d1b").state == "locked" and "not chosen" in run.inspect_node("d1b").reason, "RC-025: active choice is current and its unchosen branch is locked with a reason.")
	check.call(not run.confirm_room_entry(request.token, _accept).ok and not run.request_room_entry(entered.visit.node_id).ok and run.snapshot() == active, "RC-025: duplicate confirmation and current-node entry cannot enter a second time.")
	check.call(active.route.nodes.filter(func(node): return node.state == "available").is_empty(), "RC-025: future rooms stay locked throughout active combat/service work.")
	var other := Run.new(setup, 42, true)
	check.call(not other.confirm_room_entry(request.token, _accept).ok, "RC-025: a same-seed replacement run rejects the previous run's confirmation.")

func _completion_boundaries(check: Callable, setup: Dictionary) -> void:
	var run := Run.new(setup, 15, true)
	var entered := run.confirm_room_entry(run.request_room_entry("d1a").token, _accept)
	var visit: Dictionary = entered.visit
	var active := run.snapshot()
	for mismatch in ["run", "node", "visit", "outcome", "duplicate_choices", "invalid_choices"]:
		var ok := run.resolve_room("stale" if mismatch == "run" else visit.run_id,
			"d9" if mismatch == "node" else visit.node_id, "stale" if mismatch == "visit" else visit.visit_id,
			"victory" if mismatch == "outcome" else "completed",
			["reward", "reward"] if mismatch == "duplicate_choices" else [42] if mismatch == "invalid_choices" else [])
		check.call(not ok and run.snapshot() == active, "RC-025: %s completion rejects without unlocking successors." % mismatch)
	check.call(run.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed", ["rune_offer", "relic_offer"]), "RC-025: one matching room outcome can establish required choices without granting rewards.")
	var pending := run.snapshot()
	check.call(pending.status == "pending_choices" and pending.route.completed_count == 0 and pending.route.nodes.filter(func(node): return node.state == "available").is_empty(), "RC-025: pending rewards keep the room current and all successors unavailable.")
	check.call(not run.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed") and not run.complete_room_choice(visit.run_id, visit.node_id, visit.visit_id, "unknown") and not run.complete_room_choice("old_run", visit.node_id, visit.visit_id, "rune_offer") and run.snapshot() == pending, "RC-025: repeated resolution, stale choices and unknown choices leave required locks intact.")
	check.call(run.complete_room_choice(visit.run_id, visit.node_id, visit.visit_id, "rune_offer") and not run.complete_room_choice(visit.run_id, visit.node_id, visit.visit_id, "rune_offer") and run.snapshot().status == "pending_choices", "RC-025: each pending choice applies once; other required choices still block progression.")
	check.call(run.complete_room_choice(visit.run_id, visit.node_id, visit.visit_id, "relic_offer"), "RC-025: completing the final required choice commits the visit.")
	var completed := run.snapshot()
	check.call(completed.status == "route_ready" and completed.route.completed_count == 1 and run.inspect_node(visit.node_id).state == "visited" and not completed.tower_completed, "RC-025: room completion becomes visited and returns to route rather than declaring tower victory.")
	var successor: String = run.inspect_node(visit.node_id).next_ids[0]
	check.call(run.inspect_node(successor).state == "available" and not run.request_room_entry(visit.node_id).ok and not run.request_room_entry("d1b").ok, "RC-025: only connected successors unlock; completed and unchosen rooms cannot replay.")
	check.call(not run.complete_room_choice(visit.run_id, visit.node_id, visit.visit_id, "relic_offer") and not run.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed") and run.snapshot() == completed, "RC-025: late completion callbacks cannot reclaim or advance an already completed node.")
	entered = _enter_fixture_room(run, run.request_room_entry(successor).token)
	var next_visit: Dictionary = entered.visit
	check.call(next_visit.visit_id != visit.visit_id and not run.resolve_room(visit.run_id, visit.node_id, visit.visit_id, "completed"), "RC-025: subsequent node visits have distinct identities and reject callbacks from the prior room.")
	check.call(not run.resolve_room(next_visit.run_id, next_visit.node_id, next_visit.visit_id, "defeat") and _complete_fixture_room(run, next_visit), "RC-030: the event rejects a fabricated defeat; authoritative free Leave alone completes it.")
	entered = _enter_fixture_room(run, run.request_room_entry(run.inspect_node(successor).next_ids[0]).token)
	next_visit = entered.visit
	check.call(run.resolve_room(next_visit.run_id, next_visit.node_id, next_visit.visit_id, "defeat") and run.snapshot().status == "defeated" and not run.snapshot().can_continue and not run.snapshot().tower_completed, "RC-025: defeat ends continuation without finishing a tower.")
	var defeated := run.snapshot()
	check.call(defeated.route.completed_count == 2 and defeated.route.nodes.filter(func(node): return node.state == "available").is_empty() and run.inspect_node(next_visit.node_id).state == "locked" and not run.resolve_room(next_visit.run_id, next_visit.node_id, next_visit.visit_id, "completed") and run.snapshot() == defeated, "RC-025: defeat cannot resume, complete, unlock successors or erase already completed history.")

func _all_paths(check: Callable, setup: Dictionary) -> void:
	for seed in [0, 1, 42, 991]:
		var graph := Route.generate(seed)
		for path in _paths(graph):
			var run := Run.new(setup, seed, true)
			var initial := run.snapshot()
			var valid := true
			var visits := {}
			for id in path:
				var requested := run.request_room_entry(id)
				if not requested.ok:
					valid = false
					break
				var entered := _enter_fixture_room(run, requested.token)
				if not entered.ok:
					valid = false
					break
				var visit: Dictionary = entered.visit
				valid = valid and not visits.has(visit.visit_id)
				visits[visit.visit_id] = true
				valid = valid and _complete_fixture_room(run, visit)
				valid = valid and (run.snapshot().tower_completed == (id == "d9"))
			var final := run.snapshot()
			check.call(valid and final.status == "tower_completed" and final.route.visited_node_ids == path and final.route.completed_count == 9 and final.route.visit_count == 9 and not final.can_continue, "RC-025: fixture-only seed %d path %s completes each room exactly once and only guardian completion ends the tower." % [seed, str(path)])
			check.call(final.owned_cards == initial.owned_cards and final.player_hp == initial.player_hp and final.gold == 0 and final.relics.is_empty() and final.rng_states == initial.rng_states, "RC-025: structural traversal grants no fake Gold, rewards, healing or permanent acquisition and consumes no combat RNG.")
