extends RefCounted
## Excluded verification player: chooses legal moves on the sampled board.
## Never writes model state, substitutes endpoints, searches seeds or forces HP.
const Circuit = preload("res://scripts/core/circuit.gd")
var _paths: Array = []

func prepare(controller) -> Dictionary:
	var state: Dictionary = controller.snapshot()
	if state.state != "playing": return {}
	# Techniques are real commands and consume the normal hand/energy streams.
	for attempt in 8:
		state = controller.snapshot()
		var uid := -1
		for card in state.hand:
			if card.id == "conjure":
				uid = card.uid
				break
		if uid < 0:
			var effects: int = state.hand.filter(func(card): return card.id in ["spark", "free_spark", "shield"]).size()
			if effects < 3 and state.energy >= 2:
				for card in state.hand:
					if card.id == "focus":
						uid = card.uid
						break
		if uid < 0: break
		if not controller.command("technique", {"uid": uid}): return {}
		if controller.is_busy(): return {}
	state = controller.snapshot()
	var begin := -1
	var end := -1
	for cell in range(16):
		if state.board[cell].get("kind") == "begin": begin = cell
		if state.board[cell].get("kind") == "end": end = cell
	_paths = []
	_walk([begin], end)
	var effects: Array = state.hand.filter(func(card): return card.id in ["spark", "free_spark", "shield"])
	var best := {}
	var score := -1.0
	for path in _paths:
		var straight_cells: Array = []
		var corners := 0
		for index in range(1, path.size() - 1):
			if (_direction(path[index], path[index - 1]) + 2) % 4 == _direction(path[index], path[index + 1]):
				straight_cells.append(path[index])
			else: corners += 1
		if corners > int(state.stock.corner): continue
		for mask in range(1 << effects.size()):
			var selected: Array = []
			var cost := 0
			var damage := 0
			var shield := 0
			for index in range(effects.size()):
				if (mask & (1 << index)) == 0: continue
				var card: Dictionary = effects[index]
				selected.append(card)
				cost += 2 if card.id == "spark" else 1 if card.id == "shield" else 0
				if card.id == "shield": shield += 5
				else: damage += 6
			if cost > int(state.energy) or selected.size() > straight_cells.size() or straight_cells.size() - selected.size() > int(state.stock.straight): continue
			var value: float = damage * 2.0 + mini(shield, int(state.intent)) * 1.5 - path.size() * 0.001
			if damage >= int(state.enemy_hp): value += 1000.0
			if value > score:
				score = value
				best = {"path": path, "cards": selected, "straight_cells": straight_cells, "damage": damage, "shield": shield}
	if best.is_empty(): return {}
	var path: Array = best.path
	for index in range(path.size()):
		var cell: int = path[index]
		var edges: Array = []
		if index > 0: edges.append(_direction(cell, path[index - 1]))
		if index + 1 < path.size(): edges.append(_direction(cell, path[index + 1]))
		edges.sort()
		if index > 0 and index < path.size() - 1:
			var slot: int = best.straight_cells.find(cell)
			if slot >= 0 and slot < best.cards.size():
				if not controller.command("place_rune", {"index": cell, "uid": best.cards[slot].uid}): return {}
			elif not controller.command("place_wire", {"index": cell, "kind": "straight" if slot >= 0 else "corner"}): return {}
		for rotation in range(4):
			if Circuit.logical_ports(controller.snapshot().board[cell]) == edges: break
			if not controller.command("rotate", {"index": cell}): return {}
	return best

func play_turn(controller) -> bool:
	var plan := prepare(controller)
	return controller.command("pass" if plan.is_empty() else "cast")

func _walk(path: Array, end: int) -> void:
	if path.back() == end:
		_paths.append(path.duplicate())
		return
	for direction in range(4):
		var next := Circuit.neighbor(path.back(), direction)
		if next < 0 or next in path: continue
		path.append(next)
		_walk(path, end)
		path.pop_back()

func _direction(first: int, second: int) -> int:
	for direction in range(4):
		if Circuit.neighbor(first, direction) == second: return direction
	return -1
