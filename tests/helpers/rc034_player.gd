extends RefCounted
## Excluded verification player. Reads snapshots, then issues only ordinary
## controller commands. No HP, hand, energy, endpoints, stock or RNG writes.
const Circuit = preload("res://scripts/core/circuit.gd")
const Effects = preload("res://scripts/core/instance_effects.gd")
static var topologies: Dictionary = {}
var defense_weight := 2.5
var last_plan: Dictionary = {}

func _init() -> void:
	if topologies.is_empty():
		topologies = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rc034/play-topologies.json"))

func prepare(controller) -> Dictionary:
	var state: Dictionary = controller.snapshot()
	if state.state != "playing": return {}
	for attempt in 16:
		state = controller.snapshot()
		var uid := -1
		for card in state.hand:
			if card.id == "conjure":
				uid = int(card.uid)
				break
		if uid < 0 and state.energy >= 2:
			var effects: int = state.hand.filter(func(card): return card.id in ["spark", "free_spark", "shield"]).size()
			if effects < 3:
				for card in state.hand:
					if card.id == "focus":
						uid = int(card.uid)
						break
		if uid < 0: break
		if not controller.command("technique", {"uid": uid}): return {"error": "technique rejected"}
		if controller.is_busy(): return {"error": "Use immediate verifier presenter for preparation"}
	state = controller.snapshot()
	var begin := -1
	var end := -1
	for cell in 16:
		if state.board[cell].get("kind") == "begin": begin = cell
		if state.board[cell].get("kind") == "end": end = cell
	var cards: Array = []
	for card in state.hand:
		var definition: Dictionary = Effects.resolve(state.catalog, card).definition
		if definition.type != "rune": continue
		var effect: Dictionary = Effects.contributions(definition)
		cards.append({"uid": card.uid, "cost": definition.cost, "damage": effect.damage, "shield": effect.shield})
	var assignments: Array = []
	_assign(cards, 0, int(state.energy), [], [], 0, 0, 0, assignments)
	var best := {}
	var best_score := -INF
	for shape in topologies["%d:%d" % [begin, end]]:
		if shape.corners > state.stock.corner or shape.splits > state.stock.split or shape.splits > state.stock.join: continue
		var singles: Array = shape.slots.filter(func(slot): return int(slot[1]) == 1)
		var doubles: Array = shape.slots.filter(func(slot): return int(slot[1]) == 2)
		for assignment in assignments:
			if assignment.cost + shape.splits > state.energy or assignment.one.size() > singles.size() or assignment.two.size() > doubles.size(): continue
			if shape.slots.size() - assignment.one.size() - assignment.two.size() > state.stock.straight: continue
			var damage: int = assignment.damage + (2 if assignment.damage > 0 and "relic_ember_lens" in state.relics else 0)
			var shield: int = assignment.shield + (2 if assignment.shield > 0 and "relic_ward_seal" in state.relics else 0)
			var score: float = mini(damage, state.enemy_hp) * 2.0 + mini(shield, state.intent) * defense_weight - shape.pieces.size() * 0.001
			if damage >= state.enemy_hp: score += 10000.0
			elif state.intent - shield >= state.player_hp: score -= 10000.0
			if score <= best_score: continue
			best_score = score
			var placed := {}
			for index in assignment.one.size(): placed[int(singles[index][0])] = assignment.one[index]
			for index in assignment.two.size(): placed[int(doubles[index][0])] = assignment.two[index]
			best = {"shape": shape, "placed": placed, "damage": damage, "shield": shield, "cost": assignment.cost + int(shape.splits)}
	if best.is_empty(): return {}
	for piece in best.shape.pieces:
		var cell := int(piece.cell)
		if best.placed.has(cell):
			if not controller.command("place_rune", {"index": cell, "uid": best.placed[cell]}): return {"error": "rune rejected"}
		elif not piece.kind in ["begin", "end"]:
			if not controller.command("place_wire", {"index": cell, "kind": piece.kind}): return {"error": "wire rejected"}
		var ports: Array = piece.ports.map(func(port): return int(port))
		for rotation in 4:
			if Circuit.logical_ports(controller.snapshot().board[cell]) == ports: break
			if not controller.command("rotate", {"index": cell}): return {"error": "rotation rejected"}
	var forecast: Dictionary = controller.snapshot().forecast
	if not forecast.valid or forecast.cost != best.cost or forecast.damage != best.damage or forecast.shield != best.shield:
		return {"error": "Planned circuit disagrees with the real shared evaluator"}
	last_plan = best
	return best

func _assign(cards: Array, index: int, energy: int, one: Array, two: Array, cost: int, damage: int, shield: int, result: Array) -> void:
	if index == cards.size():
		result.append({"one": one.duplicate(), "two": two.duplicate(), "cost": cost, "damage": damage, "shield": shield})
		return
	_assign(cards, index + 1, energy, one, two, cost, damage, shield, result)
	var card: Dictionary = cards[index]
	if cost + card.cost > energy: return
	one.append(card.uid)
	_assign(cards, index + 1, energy, one, two, cost + card.cost, damage + card.damage, shield + card.shield, result)
	one.pop_back()
	two.append(card.uid)
	_assign(cards, index + 1, energy, one, two, cost + card.cost, damage + 2 * card.damage, shield + 2 * card.shield, result)
	two.pop_back()

func play_turn(controller) -> bool:
	var plan := prepare(controller)
	if plan.has("error"):
		push_error(str(plan.error))
		return false
	return controller.command("pass" if plan.is_empty() else "cast")
