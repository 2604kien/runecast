class_name RuneRouteState
extends RefCounted
## Run-owned route boundary, independent of Combat and presentation.
## Planned content references are not loadable encounters. Room adapters must
## explicitly accept an entry before a visit can be committed.

const VERSION := "rc025_route_v1"
const SAVE_VERSION := 1
const PATH_LENGTH := 9
const ROOM_IDS := ["room_normal", "room_elite", "room_event", "room_shop", "room_recovery", "room_guardian"]
const NORMAL_ENEMIES := ["wickling", "stone_sentinel"]
const ENEMY_NAMES := {"wickling": "Wickling", "stone_sentinel": "Stone Sentinel", "chain_warden": "Chain Warden", "shadeling": "Shadeling", "bell_keeper": "Bell Keeper"}
const EVENT_NAMES := {"event_lost_satchel": "Lost Satchel", "event_blood_tithe": "Blood Tithe", "event_sealed_reliquary": "Sealed Reliquary", "event_etched_desk": "Etched Desk"}
const BOARD_IDS := ["board_training", "board_gallery", "board_ossuary", "board_belfry"]
const MAX_NODES := 32

var _run_id := ""
var _graph: Dictionary = {}
var _nodes: Dictionary = {}
var _visits: Array = []
var _active: Dictionary = {}
var _last_node := ""
var _status := "route_ready"
var _revision := 0
var _entering := false
var _error := ""

func _init(run_id: String = "", seed: int = 42, authored_graph: Dictionary = {}) -> void:
	# Restore and transaction cloning start empty and never generate a route.
	if run_id.is_empty(): return
	_run_id = run_id
	_graph = generate(seed) if authored_graph.is_empty() else authored_graph.duplicate(true)
	var validation := validate_graph(_graph)
	if not validation.ok:
		_status = "invalid"
		_error = "\n".join(validation.errors)
		return
	for node in _graph.nodes: _nodes[node.id] = node

static func generate(seed: int) -> Dictionary:
	if seed < 0: return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed ^ 0x52435254
	var graph := {"version": VERSION, "seed": seed, "route_id": "%s-%d" % [VERSION, seed],
		"path_length": PATH_LENGTH, "entry_node_ids": ["d1a", "d1b"], "nodes": [], "edges": []}
	var first := int(rng.randi_range(0, 1))
	var fourth := int(rng.randi_range(0, 1))
	var event_offset := int(rng.randi_range(0, 3))
	var event_ids: Array = EVENT_NAMES.keys()
	var layers := [
		[_node("d1a", 1, 0, "normal", NORMAL_ENEMIES[first], "board_gallery"),
		 _node("d1b", 1, 1, "normal", NORMAL_ENEMIES[1 - first], "board_ossuary")],
		[_node("d2a", 2, 0, "event", event_ids[event_offset]),
		 _node("d2b", 2, 1, "event", event_ids[(event_offset + 1) % 4])],
		[_node("d3", 3, 0, "normal", NORMAL_ENEMIES[rng.randi_range(0, 1)], "board_gallery")],
		[_node("d4a", 4, 0, "normal", NORMAL_ENEMIES[fourth], "board_gallery"),
		 _node("d4b", 4, 1, "normal", NORMAL_ENEMIES[1 - fourth], "board_ossuary")],
		[_node("d5a", 5, 0, "normal", NORMAL_ENEMIES[rng.randi_range(0, 1)], "board_ossuary"),
		 _node("d5b", 5, 1, "elite", "chain_warden", "board_ossuary")],
		[_node("d6", 6, 0, "normal", "shadeling", "board_training", "boss", "training_shadeling")],
		[_node("d7", 7, 0, "shop")],
		[_node("d8", 8, 0, "recovery")],
		[_node("d9", 9, 0, "guardian", "bell_keeper", "board_belfry")]
	]
	# A seeded crossover changes the first branch's event destination. Later
	# branches reconverge without changing the number of visits along any path.
	var crossover := int(rng.randi_range(0, 1))
	for index in range(layers.size()):
		for node in layers[index]:
			if index + 1 < layers.size():
				var successors: Array = layers[index + 1]
				if index == 0:
					successors = [layers[1][(int(node.lane) + crossover) % 2]]
				for successor in successors:
					node.next_ids.append(successor.id)
					graph.edges.append({"from": node.id, "to": successor.id})
			graph.nodes.append(node)
	graph.route_rng_state = rng.state
	return graph

static func _node(id: String, depth: int, lane: int, family: String, reference: String = "", board: String = "", role: String = "", encounter: String = "") -> Dictionary:
	var enemy := reference if ENEMY_NAMES.has(reference) else ""
	var event := reference if EVENT_NAMES.has(reference) else ""
	var display: String = str(ENEMY_NAMES.get(enemy, EVENT_NAMES.get(event, family.capitalize())))
	return {"id": id, "depth": depth, "lane": lane, "room_id": "room_" + family, "room_type": family,
		"room_reference": event, "enemy_id": enemy, "board_id": board, "encounter_id": encounter,
		"encounter_role": role if not role.is_empty() else family if not enemy.is_empty() else "",
		"title": display, "display_name": display, "next_ids": [], "content_pending": encounter != "training_shadeling"}

static func validate_graph(graph: Dictionary) -> Dictionary:
	var errors: Array = []
	if graph.get("version") != VERSION: errors.append("Unknown route schema version.")
	if not graph.get("seed") is int or int(graph.get("seed", -1)) < 0: errors.append("Invalid route seed.")
	if not graph.get("route_id") is String or str(graph.get("route_id", "")).is_empty(): errors.append("Missing route identity.")
	if graph.get("path_length") != PATH_LENGTH: errors.append("This route must require nine visits.")
	if not graph.get("nodes") is Array or graph.get("nodes", []).is_empty() or graph.get("nodes", []).size() > MAX_NODES:
		errors.append("Route node count is outside the bounded schema.")
		return {"ok": false, "errors": errors}
	if not graph.get("entry_node_ids") is Array or graph.get("entry_node_ids", []).is_empty() or not graph.get("edges") is Array:
		errors.append("Explicit entries and connections are required.")
		return {"ok": false, "errors": errors}
	var nodes := {}
	var guardians := 0
	var bosses := 0
	for node in graph.nodes:
		if not node is Dictionary:
			errors.append("Node must be a dictionary.")
			continue
		if not node.get("id") is String or str(node.get("id", "")).is_empty() or nodes.has(node.get("id")):
			errors.append("Node identities must be unique and nonempty.")
			continue
		nodes[node.id] = node
		if not node.get("depth") is int or int(node.get("depth", 0)) < 1 or int(node.get("depth", 0)) > PATH_LENGTH: errors.append("Invalid node depth.")
		if not node.get("lane") is int or int(node.get("lane", -1)) < 0 or int(node.get("lane", -1)) > 1: errors.append("Invalid node lane.")
		if not node.get("next_ids") is Array: errors.append("Node connections must be an array.")
		var family := str(node.get("room_id", ""))
		var role := str(node.get("encounter_role", ""))
		var enemy := str(node.get("enemy_id", ""))
		var encounter := str(node.get("encounter_id", ""))
		if not family in ROOM_IDS or node.get("room_type") != family.trim_prefix("room_"): errors.append("Unknown or inconsistent room family.")
		if family in ["room_normal", "room_elite", "room_guardian"]:
			if not node.get("board_id") in BOARD_IDS: errors.append("Unknown board reference.")
			if family == "room_normal" and role == "normal" and not enemy in NORMAL_ENEMIES: errors.append("Normal pools contain only the two normal actors.")
			elif family == "room_normal" and role == "boss":
				bosses += 1
				if enemy != "shadeling" or encounter != "training_shadeling": errors.append("The designated boss must reference Shadeling's retained fixture.")
				if node.get("depth") != 6: errors.append("Shadeling's designated boss encounter must remain at depth six.")
			elif family == "room_normal" and role != "normal": errors.append("Invalid normal-room encounter role.")
			elif family == "room_elite" and (role != "elite" or enemy != "chain_warden"): errors.append("Invalid elite reference or role.")
			elif family == "room_guardian":
				guardians += 1
				if role != "guardian" or enemy != "bell_keeper": errors.append("The guardian must be distinct from Shadeling.")
			if role != "boss" and not encounter.is_empty(): errors.append("An unauthored encounter definition cannot be invented.")
			if not str(node.get("room_reference", "")).is_empty(): errors.append("Battle rooms cannot reference an event.")
		else:
			if not enemy.is_empty() or not role.is_empty() or not encounter.is_empty() or not str(node.get("board_id", "")).is_empty(): errors.append("Service rooms cannot claim an encounter.")
			if family == "room_event" and not EVENT_NAMES.has(node.get("room_reference")): errors.append("Unknown event reference.")
			if family in ["room_shop", "room_recovery"] and not str(node.get("room_reference", "")).is_empty(): errors.append("Unknown service reference.")
	if guardians != 1 or bosses != 1: errors.append("Exactly one Shadeling boss and one separate guardian are required.")
	# Stop before traversing malformed node values.
	if not errors.is_empty(): return {"ok": false, "errors": errors}
	var expected_edges: Array = []
	var incoming := {}
	for node in nodes.values():
		var unique := {}
		for next_id in node.next_ids:
			if not next_id is String or not nodes.has(next_id) or unique.has(next_id):
				errors.append("Invalid or duplicate connection.")
				continue
			unique[next_id] = true
			if nodes[next_id].depth != node.depth + 1: errors.append("Connections must advance exactly one depth; cycles, backtracking and self-links are forbidden.")
			expected_edges.append({"from": node.id, "to": next_id})
			incoming[next_id] = true
		if node.next_ids.is_empty() and node.room_id != "room_guardian": errors.append("Nonterminal dead end.")
		if node.room_id == "room_guardian" and (not node.next_ids.is_empty() or node.depth != PATH_LENGTH): errors.append("Guardian must be the terminal ninth visit.")
	if graph.edges.size() != expected_edges.size(): errors.append("Explicit edges disagree with node connections.")
	var unique_edges: Array = []
	for edge in graph.edges:
		if not edge is Dictionary or edge.size() != 2 or not expected_edges.has(edge) or unique_edges.has(edge): errors.append("Unknown or duplicate explicit edge.")
		unique_edges.append(edge)
	var entries := {}
	for id in graph.entry_node_ids:
		if not id is String or not nodes.has(id) or entries.has(id):
			errors.append("Invalid or duplicate route entry.")
			continue
		entries[id] = true
		if nodes[id].depth != 1 or incoming.has(id): errors.append("Entries must begin at depth one without incoming links.")
	for node in nodes.values():
		if not incoming.has(node.id) and not entries.has(node.id): errors.append("Unreachable authored node.")
	if not errors.is_empty(): return {"ok": false, "errors": errors}
	var paths := _paths(nodes, graph.entry_node_ids)
	var reached := {}
	for path in paths:
		var recovered := false
		var boss_seen := false
		for id in path:
			reached[id] = true
			recovered = recovered or nodes[id].room_id == "room_recovery"
			boss_seen = boss_seen or nodes[id].encounter_role == "boss"
		if path.size() != PATH_LENGTH or nodes[path.back()].room_id != "room_guardian" or not recovered or not boss_seen:
			errors.append("Every path must visit nine rooms, include the boss and recovery, and end at the guardian.")
	if reached.size() != nodes.size(): errors.append("Unreachable authored node.")
	return {"ok": errors.is_empty(), "errors": errors}

static func _paths(nodes: Dictionary, entries: Array) -> Array:
	var queue: Array = []
	var result: Array = []
	for id in entries: queue.append([id])
	while not queue.is_empty():
		var path: Array = queue.pop_back()
		var next_ids: Array = nodes[path.back()].next_ids
		if next_ids.is_empty(): result.append(path)
		for id in next_ids:
			var extended := path.duplicate()
			extended.append(id)
			queue.append(extended)
	return result

func snapshot() -> Dictionary:
	var result := _graph.duplicate(true)
	result.merge({"status": _status, "current_node_id": _active.get("node_id", _last_node),
		"active_visit_id": _active.get("visit_id", ""), "active_visit": _active.duplicate(true),
		"visited_node_ids": _completed_ids(), "visits": _visits.duplicate(true), "visit_count": _visits.size(),
		"completed_count": _completed_ids().size(), "revision": _revision, "error": _error}, true)
	var live_nodes: Array = []
	for node in _nodes.values(): live_nodes.append(inspect(node.id))
	result.nodes = live_nodes
	return result

func inspect(node_id: String) -> Dictionary:
	if not _nodes.has(node_id): return _rejected("Unknown route node.")
	var result: Dictionary = _nodes[node_id].duplicate(true)
	# Availability is a runtime projection; retained v1 graphs are not regenerated.
	if result.room_id in ["room_shop", "room_event", "room_recovery"]: result.content_pending = false
	result.ok = true
	result.error = ""
	result.state = "locked"
	result.reason = "Complete the connected earlier rooms first."
	if _status == "defeated" and not _completed_ids().has(node_id):
		result.reason = "This run ended in defeat. This room cannot be resumed."
	elif node_id == _active.get("node_id"):
		result.state = "current"
		result.reason = "Required room choices remain." if _status == "pending_choices" else "This room is active. Resume it to continue."
	elif _completed_ids().has(node_id):
		result.state = "visited"
		result.reason = "Completed. Rooms cannot be replayed and rewards cannot be reclaimed."
	elif _status == "tower_completed":
		result.reason = "This tower run is complete."
	elif not _is_reachable(node_id):
		result.reason = "This branch was not chosen. You cannot backtrack."
	elif not _active.is_empty():
		result.reason = "Resolve the current room and all required choices first."
	elif node_id in _available_ids():
		result.state = "available"
		result.reason = "Connected next room. Inspecting does not enter it."
	elif not _last_node.is_empty() and int(result.depth) <= int(_nodes[_last_node].depth):
		result.reason = "This branch was not chosen. You cannot backtrack."
	return result

func _is_reachable(node_id: String) -> bool:
	var origin := str(_active.get("node_id", _last_node))
	if origin.is_empty(): return true
	var remaining: Array = _nodes[origin].next_ids.duplicate()
	var seen := {}
	while not remaining.is_empty():
		var next: String = remaining.pop_back()
		if next == node_id: return true
		if seen.has(next): continue
		seen[next] = true
		remaining.append_array(_nodes[next].next_ids)
	return false

func request_entry(node_id: String) -> Dictionary:
	var detail := inspect(node_id)
	if not detail.ok or detail.state != "available": return _rejected(str(detail.get("reason", detail.get("error", "Unavailable node."))))
	return {"ok": true, "error": "", "token": {"run_id": _run_id, "route_id": _graph.route_id, "node_id": node_id, "revision": _revision}}

func confirm_entry(token: Dictionary, handler: Callable = Callable()) -> Dictionary:
	var requested := preview_entry(token)
	if not requested.ok: return requested
	var node_id := str(token.get("node_id", ""))
	if not handler.is_valid():
		return _rejected(pending_message(node_id))
	var visit: Dictionary = requested.visit
	_entering = true
	var prepared: Variant = handler.call(_nodes[node_id].duplicate(true), visit.duplicate(true))
	_entering = false
	if not prepared is Dictionary or prepared.get("ok") != true:
		return _rejected(str(prepared.get("error", "The room could not be entered.")) if prepared is Dictionary else "The room handler returned an invalid result.")
	# Defend against adapters reentering or changing the model during prepare.
	if token.get("revision") != _revision or inspect(node_id).state != "available":
		return _rejected("The room changed before entry could commit.")
	_active = visit.duplicate(true)
	_visits.append(visit.duplicate(true))
	_status = "room_active"
	_revision += 1
	return {"ok": true, "error": "", "visit": visit.duplicate(true), "prepared": prepared.duplicate(true)}

func preview_entry(token: Dictionary) -> Dictionary:
	if _entering: return _rejected("A room entry is already being prepared.")
	if token.get("run_id") != _run_id or token.get("route_id") != _graph.get("route_id") or token.get("revision") != _revision:
		return _rejected("This entry confirmation is stale.")
	var node_id := str(token.get("node_id", ""))
	var requested := request_entry(node_id)
	if not requested.ok: return requested
	return {"ok": true, "error": "", "node": _nodes[node_id].duplicate(true),
		"visit": {"run_id": _run_id, "route_id": _graph.route_id, "node_id": node_id,
			"visit_id": "%s/visit-%02d/%s" % [_run_id, _visits.size() + 1, node_id],
			"status": "active", "outcome": "", "pending_choices": [], "completed_choices": []}}

func pending_message(node_id: String) -> String:
	var family: String = str(_nodes.get(node_id, {}).get("room_id", ""))
	if family in ["room_normal", "room_elite", "room_guardian"]:
		return "This encounter is not available yet. Your route choice has not been consumed."
	if family == "room_shop": return "Open this shop through its registered room handler."
	return "Open this room through its registered service handler."

func resolve(run_id: String, node_id: String, visit_id: String, outcome: String, pending_choices: Array = []) -> bool:
	if not can_resolve(run_id, node_id, visit_id, outcome, pending_choices): return false
	_active.outcome = outcome
	_active.pending_choices = pending_choices.duplicate()
	if outcome == "defeat":
		_active.status = "defeated"
		_status = "defeated"
		_store_active()
	elif pending_choices.is_empty():
		_finish_active()
	else:
		_active.status = "pending_choices"
		_status = "pending_choices"
		_store_active()
	_revision += 1
	return true

func can_resolve(run_id: String, node_id: String, visit_id: String, outcome: String, pending_choices: Array = []) -> bool:
	if not _matches(run_id, node_id, visit_id) or _status != "room_active" or not outcome in ["completed", "defeat"]: return false
	var unique := {}
	for choice in pending_choices:
		if not choice is String or choice.is_empty() or unique.has(choice): return false
		unique[choice] = true
	if outcome == "defeat" and not pending_choices.is_empty(): return false
	return true

func complete_choice(run_id: String, node_id: String, visit_id: String, choice_id: String) -> bool:
	if not can_complete_choice(run_id, node_id, visit_id, choice_id): return false
	_active.pending_choices.erase(choice_id)
	_active.completed_choices.append(choice_id)
	if _active.pending_choices.is_empty(): _finish_active()
	else: _store_active()
	_revision += 1
	return true

func can_complete_choice(run_id: String, node_id: String, visit_id: String, choice_id: String) -> bool:
	return _matches(run_id, node_id, visit_id) and _status == "pending_choices" and choice_id in _active.pending_choices

func _matches(run_id: String, node_id: String, visit_id: String) -> bool:
	return not _entering and not _active.is_empty() and run_id == _run_id and node_id == _active.node_id and visit_id == _active.visit_id

func _finish_active() -> void:
	_active.status = "completed"
	_last_node = _active.node_id
	_store_active()
	_status = "tower_completed" if _nodes[_last_node].room_id == "room_guardian" else "route_ready"
	_active = {}

func _store_active() -> void:
	_visits[-1] = _active.duplicate(true)

func _completed_ids() -> Array:
	var result: Array = []
	for visit in _visits:
		if visit.status == "completed": result.append(visit.node_id)
	return result

func _available_ids() -> Array:
	if _status != "route_ready" or not _active.is_empty(): return []
	return _graph.entry_node_ids if _last_node.is_empty() else _nodes[_last_node].next_ids

func _rejected(message: String) -> Dictionary:
	return {"ok": false, "error": message}

# Raw ownership contract: no inspect()/snapshot() presentation fields are saved.
func export_save() -> Dictionary:
	return {"version": SAVE_VERSION, "run_id": _run_id, "graph": _graph,
		"visits": _visits, "active": _active, "last_node": _last_node,
		"status": _status, "revision": _revision}.duplicate(true)

static func restore_save(data: Dictionary, expected_run_id: String, context: Dictionary = {}) -> Dictionary:
	if data.size() != 8 or not data.get("version") is int or data.version != SAVE_VERSION:
		return {"ok": false, "error": "Unsupported or malformed route save version."}
	if not data.get("run_id") is String or data.run_id != expected_run_id or expected_run_id.is_empty():
		return {"ok": false, "error": "Saved route belongs to a different run."}
	for key in ["graph", "active"]:
		if not data.get(key) is Dictionary: return {"ok": false, "error": "Saved route %s must be an object." % key}
	if not data.get("visits") is Array or not data.get("last_node") is String or not data.get("status") is String or not data.get("revision") is int or data.revision < 0:
		return {"ok": false, "error": "Saved route history, status or revision is malformed."}
	var graph: Dictionary = data.graph
	# Fixture policies are capabilities supplied by tests, never selected by data.
	var checked: Dictionary
	if context.get("allow_test_fixtures", false) and context.get("route_graph_validator") is Callable:
		checked = context.route_graph_validator.call(graph)
	else:
		if graph.size() != 8 or not graph.get("nodes") is Array: return {"ok": false, "error": "Saved production route graph structure is invalid."}
		if not graph.get("version") is String or not graph.get("path_length") is int: return {"ok": false, "error": "Saved production route schema fields are malformed."}
		for node in graph.nodes:
			if not node is Dictionary or node.size() != 14: return {"ok": false, "error": "Saved production route node structure is invalid."}
			if not node.get("depth") is int or not node.get("lane") is int: return {"ok": false, "error": "Saved production route node coordinates must use exact integers."}
			for field in ["id", "room_id", "room_type", "room_reference", "enemy_id", "board_id", "encounter_id", "encounter_role", "title", "display_name"]:
				if not node.get(field) is String: return {"ok": false, "error": "Saved production route node %s is malformed." % field}
			if not node.get("content_pending") is bool: return {"ok": false, "error": "Saved production route content availability is malformed."}
		checked = validate_graph(graph)
	if not checked.get("ok", false): return {"ok": false, "error": "Saved route graph is incompatible: " + "; ".join(checked.get("errors", []))}
	if not context.get("allow_test_fixtures", false) and graph.route_id != "%s-%d" % [VERSION, graph.seed]: return {"ok": false, "error": "Saved production route identity disagrees with its version and seed."}
	if not graph.get("path_length") is int: return {"ok": false, "error": "Saved route path length must use an exact integer."}
	if not graph.get("route_rng_state") is int: return {"ok": false, "error": "Saved route random stream is missing or invalid."}
	var restored := RuneRouteState.new()
	restored._run_id = expected_run_id
	restored._graph = graph.duplicate(true)
	for node in graph.nodes: restored._nodes[node.id] = restored._graph.nodes[restored._nodes.size()]
	restored._visits = data.visits.duplicate(true)
	restored._active = data.active.duplicate(true)
	restored._last_node = data.last_node
	restored._status = data.status
	restored._revision = data.revision
	var error := restored._validate_saved_history()
	if not error.is_empty(): return {"ok": false, "error": error}
	return {"ok": true, "error": "", "route": restored}

func _validate_saved_history() -> String:
	if _visits.size() > PATH_LENGTH: return "Saved route exceeds the allowed visit count."
	var previous := ""
	var completed := ""
	var expected_revision := 0
	var node_ids: Array = []
	for index in range(_visits.size()):
		var visit: Variant = _visits[index]
		if not visit is Dictionary or visit.size() != 8: return "Saved visit structure is invalid."
		for key in ["run_id", "route_id", "node_id", "visit_id", "status", "outcome"]:
			if not visit.get(key) is String: return "Saved visit identity or outcome is invalid."
		if visit.run_id != _run_id or visit.route_id != _graph.route_id or not _nodes.has(visit.node_id) or visit.node_id in node_ids:
			return "Saved visits contain invalid owners, nodes or repeated rooms."
		if visit.visit_id != "%s/visit-%02d/%s" % [_run_id, index + 1, visit.node_id]: return "Saved visit identity is inconsistent."
		if not visit.node_id in (_graph.entry_node_ids if previous.is_empty() else _nodes[previous].next_ids): return "Saved visits are not a connected route."
		if not visit.get("pending_choices") is Array or not visit.get("completed_choices") is Array: return "Saved visit choices are malformed."
		var choices: Array = []
		for choice in visit.pending_choices + visit.completed_choices:
			if not choice is String or choice.is_empty() or choice in choices: return "Saved visit choices are duplicated or invalid."
			choices.append(choice)
		if visit.status == "active":
			if visit.outcome != "" or not choices.is_empty(): return "Active saved visit already contains a result."
		elif visit.status == "pending_choices":
			if visit.outcome != "completed" or visit.pending_choices.is_empty(): return "Saved required-choice lock is inconsistent."
		elif visit.status == "completed":
			if visit.outcome != "completed" or not visit.pending_choices.is_empty(): return "Completed saved visit has unfinished choices."
			completed = visit.node_id
		elif visit.status == "defeated":
			if visit.outcome != "defeat" or not choices.is_empty(): return "Defeated saved visit has invalid choices."
		else: return "Unknown saved visit status."
		if index < _visits.size() - 1 and visit.status != "completed": return "A saved successor was entered before its previous room completed."
		expected_revision += 1 + (0 if visit.outcome.is_empty() else 1) + visit.completed_choices.size()
		previous = visit.node_id
		node_ids.append(visit.node_id)
	if _revision != expected_revision or _last_node != completed: return "Saved route revision or last completed room disagrees with its history."
	var last: Dictionary = _visits.back() if not _visits.is_empty() else {}
	if not last.is_empty() and last.status != "completed":
		if _active != last: return "Saved active visit disagrees with its history."
		var expected_status := "room_active" if last.status == "active" else str(last.status)
		if _status != expected_status: return "Saved route phase disagrees with its active visit."
	else:
		if not _active.is_empty(): return "A completed route history cannot retain an active visit."
		var expected_status := "tower_completed" if not completed.is_empty() and _nodes[completed].room_id == "room_guardian" else "route_ready"
		if _status != expected_status: return "Saved route completion phase is inconsistent."
	return ""

func clone_for_transaction() -> RuneRouteState:
	var candidate := RuneRouteState.new()
	candidate.publish_transaction(self)
	return candidate

func publish_transaction(candidate: RuneRouteState) -> void:
	_run_id = candidate._run_id
	_graph = candidate._graph.duplicate(true)
	_nodes = {}
	for node in _graph.nodes: _nodes[node.id] = node
	_visits = candidate._visits.duplicate(true)
	_active = candidate._active.duplicate(true)
	_last_node = candidate._last_node
	_status = candidate._status
	_revision = candidate._revision
	_error = candidate._error
