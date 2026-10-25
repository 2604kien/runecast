class_name RuneCircuit
extends RefCounted

const InstanceEffects = preload("res://scripts/core/instance_effects.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
const WIDTH := 4
const BEGIN := 0
const END := 14
const STEP := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

static func empty_board() -> Array:
	var board: Array = []
	for index in range(16):
		board.append({})
	board[BEGIN] = {"kind": "begin", "rotation": 0}
	board[END] = {"kind": "end", "rotation": 0}
	return board

static func demo_board() -> Array:
	var board := empty_board()
	board[1] = {"kind": "rune", "rotation": 0, "rune_id": "free_spark", "uid": 0}
	board[2] = {"kind": "split", "rotation": 0}
	board[3] = {"kind": "corner", "rotation": 0}
	board[6] = {"kind": "straight", "rotation": 1}
	board[7] = {"kind": "straight", "rotation": 1}
	board[10] = {"kind": "join", "rotation": 0}
	board[11] = {"kind": "corner", "rotation": 1}
	return board

static func ports(piece: Dictionary) -> Dictionary:
	var input: Array = []
	var output: Array = []
	match piece.get("kind", ""):
		"begin": output = [1]
		"end": input = [0]
		"straight":
			input = [3]
			output = [1]
		"rune":
			input = [3]
			output = [2] if piece.get("port_shape", "straight") == "corner" else [1]
		"corner":
			input = [3]
			output = [2]
		"split":
			input = [3]
			output = [1, 2]
		"join":
			input = [0, 1]
			output = [2]
	var rotation: int = piece.get("rotation", 0)
	if piece.get("reversed", false) and piece.get("kind") in ["straight", "corner"]:
		var previous := input
		input = output
		output = previous
	return {
		"input": input.map(func(p): return (p + rotation) % 4),
		"output": output.map(func(p): return (p + rotation) % 4)
	}

static func neighbor(index: int, direction: int) -> int:
	var position: Vector2i = Vector2i(index % WIDTH, index / WIDTH) + STEP[direction]
	if position.x < 0 or position.x >= WIDTH or position.y < 0 or position.y >= WIDTH:
		return -1
	return position.y * WIDTH + position.x

static func logical_ports(piece: Dictionary) -> Array:
	# RC-016A production geometry is independent of historical input/output
	# labels and decorative glyph tips. Reversal never changes physical ports.
	var edges: Array = []
	match piece.get("kind", ""):
		"begin": edges = [1]
		"end": edges = [0]
		"straight", "rune": edges = [1, 3]
		"corner": edges = [2, 3]
		"split": edges = [1, 2, 3]
		"join": edges = [0, 1, 2]
	var rotation: int = piece.get("rotation", 0)
	var rotated: Array = edges.map(func(edge): return (edge + rotation) % 4)
	rotated.sort()
	return rotated

static func evaluate(board: Array, catalog: Dictionary, options: Dictionary = {}) -> Dictionary:
	return RelicPolicy.final_cast(_evaluate(board, catalog, options), options.get("relics", []))

static func _evaluate(board: Array, catalog: Dictionary, options: Dictionary = {}) -> Dictionary:
	if options.get("version") is String and options.version == "rc007_production_v1":
		return _evaluate_undirected(board, catalog, options)
	var result := {"valid": false, "damage": 0, "shield": 0, "cost": 0, "message": "", "active": []}
	var begin := BEGIN
	var end := END
	if not options.is_empty() and board.size() == 16:
		var begins: Array = []
		var ends: Array = []
		for index in range(board.size()):
			if board[index].get("kind") == "begin":
				begins.append(index)
			if board[index].get("kind") == "end":
				ends.append(index)
		if begins.size() != 1 or ends.size() != 1:
			result.message = "A production board requires exactly one Begin and End." if options.get("version") == "rc007_production_v1" else "An experimental board requires exactly one Begin and End."
			return result
		begin = begins[0]
		end = ends[0]
	if board.size() != 16 or board[begin].get("kind") != "begin" or board[end].get("kind") != "end":
		result.message = "Begin and End must remain in their sockets."
		return result
	var context := {"visiting": {}, "visited": {}, "order": [], "parents": {}, "error": ""}
	_visit(begin, board, context)
	if context.error != "":
		result.message = context.error
		return result
	if not context.visited.has(end):
		result.message = "Connect Begin to End."
		return result
	for index in context.order:
		if index == begin:
			continue
		var expected: int = ports(board[index]).input.size()
		if context.parents.get(index, []).size() != expected:
			result.message = "Every input at row %d, column %d needs a powered connection." % [index / 4 + 1, index % 4 + 1]
			return result
	var order: Array = context.order.duplicate()
	order.reverse()
	var signals := {}
	for index in order:
		var signal_value := {"damage": 0, "shield": 0, "hits": []}
		for parent in context.parents.get(index, []):
			signal_value.damage += signals[parent].damage
			signal_value.shield += signals[parent].shield
			# Parent arrival follows Begin's output-port DFS order. Each branch
			# gets the entire contribution list; Join concatenates without merging.
			signal_value.hits.append_array(signals[parent].hits)
		var piece: Dictionary = board[index]
		if piece.kind == "rune":
			var resolved := InstanceEffects.resolve(catalog, piece)
			if not resolved.ok or resolved.definition.get("type") != "rune":
				result.message = "Unknown effect rune."
				result.cost = 0
				return result
			var rune: Dictionary = resolved.definition
			var values := InstanceEffects.contributions(rune)
			signal_value.damage += values.damage
			signal_value.shield += values.shield
			if int(values.damage) > 0:
				signal_value.hits.append(int(values.damage))
			result.cost += int(rune.cost)
		elif piece.kind == "split":
			result.cost += int(options.get("split_cost", 1))
		elif piece.kind == "join":
			result.cost += int(options.get("join_cost", 0))
		signals[index] = signal_value
	result.valid = true
	result.damage = signals[end].damage
	result.shield = signals[end].shield
	if options.get("damage_mode") == "multi_hit":
		result.hits = signals[end].hits.duplicate()
	result.active = order
	result.message = "Circuit complete"
	return result

static func _evaluate_undirected(board: Array, catalog: Dictionary, options: Dictionary) -> Dictionary:
	# Numeric output remains zero until the whole graph and catalog validate.
	# reached is the sorted physical Begin component even for an invalid graph;
	# active is populated only for an accepted, topologically ordered spell.
	var result := {"valid": false, "damage": 0, "shield": 0, "cost": 0, "message": "", "active": [], "reached": []}
	if board.size() != 16:
		result.message = "A production board requires sixteen cells."
		return result
	var begins: Array = []
	var ends: Array = []
	for index in range(board.size()):
		if board[index].get("kind") == "begin": begins.append(index)
		if board[index].get("kind") == "end": ends.append(index)
	if begins.size() != 1 or ends.size() != 1:
		result.message = "A production board requires exactly one Begin and End."
		return result
	var begin: int = begins[0]
	var end: int = ends[0]
	var graph := {}
	var pending: Array = [begin]
	var seen := {begin: true}
	while not pending.is_empty():
		var index: int = pending.pop_front()
		var adjacent: Array = []
		for direction in logical_ports(board[index]):
			var next := neighbor(index, int(direction))
			if next < 0 or not logical_ports(board[next]).has((int(direction) + 2) % 4):
				continue
			adjacent.append(next)
			if not seen.has(next):
				seen[next] = true
				pending.append(next)
		adjacent.sort()
		graph[index] = adjacent
	var reached: Array = seen.keys()
	reached.sort()
	result.reached = reached.duplicate()
	# Evaluate errors in cell/compass order, independent of dictionary order or
	# which path first discovered a shared downstream piece.
	for index in reached:
		for direction in logical_ports(board[index]):
			var next := neighbor(index, int(direction))
			if not graph[index].has(next):
				result.message = "Open connection at row %d, column %d." % [index / 4 + 1, index % 4 + 1]
				return result
	if not seen.has(end):
		result.message = "Connect Begin to End."
		return result
	var routes := {"directions": {}, "count": 0}
	_collect_simple_routes(begin, end, graph, 1 << begin, [begin], routes)
	if routes.count == 0:
		result.message = "Connect Begin to End."
		return result
	for index in reached:
		for next in graph[index]:
			if int(next) <= int(index): continue
			var key: int = int(index) * 16 + int(next)
			if routes.directions.get(key, 0) == 3:
				result.message = "Feedback crosses a connection at row %d, column %d in both directions." % [index / 4 + 1, index % 4 + 1]
				return result
	var parents := {}
	var children := {}
	for index in reached:
		parents[index] = []
		children[index] = []
	for index in reached:
		for next in graph[index]:
			if int(next) <= int(index): continue
			var key: int = int(index) * 16 + int(next)
			var direction: int = routes.directions.get(key, 0)
			if direction == 0:
				result.message = "A powered branch at row %d, column %d cannot reach End without revisiting a piece." % [index / 4 + 1, index % 4 + 1]
				return result
			var from: int = index if direction == 1 else next
			var to: int = next if direction == 1 else index
			children[from].append(to)
			parents[to].append(from)
	for index in reached:
		parents[index].sort()
		children[index].sort()
		var kind: String = board[index].kind
		var incoming: int = parents[index].size()
		var outgoing: int = children[index].size()
		if kind == "split" and (incoming != 1 or outgoing != 2):
			result.message = "Split at row %d, column %d must branch one route into two." % [index / 4 + 1, index % 4 + 1]
			return result
		if kind == "join" and (incoming != 2 or outgoing != 1):
			result.message = "Join at row %d, column %d must merge two routes into one." % [index / 4 + 1, index % 4 + 1]
			return result
		if (kind == "begin" and (incoming != 0 or outgoing != 1)) or (kind == "end" and (incoming != 1 or outgoing != 0)) or (kind in ["straight", "corner", "rune"] and (incoming != 1 or outgoing != 1)):
			result.message = "Invalid route at row %d, column %d." % [index / 4 + 1, index % 4 + 1]
			return result
	var remaining := {}
	var ready: Array = []
	for index in reached:
		remaining[index] = parents[index].size()
		if remaining[index] == 0: ready.append(index)
	var order: Array = []
	while not ready.is_empty():
		ready.sort()
		var index: int = ready.pop_front()
		order.append(index)
		for next in children[index]:
			remaining[next] -= 1
			if remaining[next] == 0: ready.append(next)
	if order.size() != reached.size():
		result.message = "Feedback cannot revisit an earlier piece."
		return result
	var signals := {}
	var cost := 0
	for index in order:
		var signal_value := {"damage": 0, "shield": 0}
		for parent in parents[index]:
			signal_value.damage += signals[parent].damage
			signal_value.shield += signals[parent].shield
		var piece: Dictionary = board[index]
		if piece.kind == "rune":
			var resolved := InstanceEffects.resolve(catalog, piece)
			if not resolved.ok or resolved.definition.get("type") != "rune":
				result.message = "Unknown effect rune."
				return result
			var rune: Dictionary = resolved.definition
			var values := InstanceEffects.contributions(rune)
			signal_value.damage += values.damage
			signal_value.shield += values.shield
			cost += int(rune.cost)
		elif piece.kind == "split":
			cost += int(options.get("split_cost", 1))
		elif piece.kind == "join":
			cost += int(options.get("join_cost", 0))
		signals[index] = signal_value
	result.valid = true
	result.damage = signals[end].damage
	result.shield = signals[end].shield
	result.cost = cost
	result.active = order
	result.message = "Circuit complete"
	return result

static func _collect_simple_routes(index: int, end: int, graph: Dictionary, visited: int, path: Array, routes: Dictionary) -> void:
	# The board has only sixteen cells. A path never revisits a physical piece;
	# collecting its edge directions does not execute runes or duplicate costs.
	if index == end:
		routes.count += 1
		for offset in range(path.size() - 1):
			var from: int = path[offset]
			var to: int = path[offset + 1]
			var key: int = mini(from, to) * 16 + maxi(from, to)
			var direction := 1 if from < to else 2
			routes.directions[key] = int(routes.directions.get(key, 0)) | direction
		return
	for next in graph[index]:
		if visited & (1 << int(next)): continue
		path.append(next)
		_collect_simple_routes(int(next), end, graph, visited | (1 << int(next)), path, routes)
		path.pop_back()

static func _visit(index: int, board: Array, context: Dictionary) -> void:
	if context.error != "":
		return
	if context.visiting.has(index):
		context.error = "Loops cannot feed back into an earlier piece."
		return
	if context.visited.has(index):
		return
	context.visiting[index] = true
	for direction in ports(board[index]).output:
		var next := neighbor(index, direction)
		if next < 0 or board[next].is_empty() or not ports(board[next]).input.has((direction + 2) % 4):
			context.error = "Open connection at row %d, column %d." % [index / 4 + 1, index % 4 + 1]
			return
		if not context.parents.has(next):
			context.parents[next] = []
		context.parents[next].append(index)
		_visit(next, board, context)
	context.visiting.erase(index)
	context.visited[index] = true
	context.order.append(index)

