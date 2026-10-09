class_name RuneCircuit
extends RefCounted

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

static func evaluate(board: Array, catalog: Dictionary, options: Dictionary = {}) -> Dictionary:
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
			var rune: Dictionary = catalog.get(piece.rune_id, {})
			if rune.is_empty() or rune.get("type") != "rune":
				result.message = "Unknown effect rune."
				return result
			signal_value[rune.effect] += int(rune.value)
			if rune.effect == "damage" and int(rune.value) > 0:
				signal_value.hits.append(int(rune.value))
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

