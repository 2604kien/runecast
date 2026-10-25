extends RefCounted
## Explicit excluded fixture registration. No production resolver/catalogue change.
## The legal planner only reads snapshots and issues ordinary controller commands.
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const PATH := "res://tests/fixtures/rc033/encounter.json"
const SOURCES := {"enemies": "res://tests/fixtures/rc033/enemies.json", "loadouts": "res://tests/fixtures/rc033/loadouts.json"}

static func load_fixture() -> Dictionary:
	return Loader.load_setup(PATH, SOURCES)

static func new_combat():
	var loaded := load_fixture()
	assert(loaded.ok, str(loaded.get("errors", [])))
	return Combat.new(loaded.setup)

static func command(controller, name: String, arguments: Dictionary = {}) -> bool:
	if not controller.command(name, arguments): return false
	var presenter = controller.get_presenter()
	if controller.is_busy() and presenter.has_method("finish"): presenter.finish()
	return not controller.is_busy()

static func prepare_spark(controller) -> Dictionary:
	var snapshot: Dictionary = controller.snapshot()
	var sparks: Array = snapshot.hand.filter(func(card): return card.id == "spark")
	if sparks.is_empty(): return {"ok": false, "error": "No owned Spark in hand."}
	var begin := -1
	var end := -1
	for cell in 16:
		if snapshot.board[cell].get("kind") == "begin": begin = cell
		elif snapshot.board[cell].get("kind") == "end": end = cell
	var paths: Array = []
	_walk([begin], end, paths)
	paths.sort_custom(func(first, second): return first.size() < second.size())
	var selected: Array = []
	var rune_cell := -1
	for path in paths:
		var straights: Array = []
		var corners := 0
		for index in range(1, path.size() - 1):
			if (_direction(path[index], path[index - 1]) + 2) % 4 == _direction(path[index], path[index + 1]): straights.append(path[index])
			else: corners += 1
		if straights.size() > 0 and straights.size() - 1 <= int(snapshot.stock.straight) and corners <= int(snapshot.stock.corner):
			selected = path
			rune_cell = straights[0]
			break
	if selected.is_empty(): return {"ok": false, "error": "No one-Spark path fits this actual kit."}
	for index in selected.size():
		var cell: int = selected[index]
		var ports: Array = []
		if index > 0: ports.append(_direction(cell, selected[index - 1]))
		if index + 1 < selected.size(): ports.append(_direction(cell, selected[index + 1]))
		ports.sort()
		if index > 0 and index < selected.size() - 1:
			if cell == rune_cell:
				if not command(controller, "place_rune", {"index": cell, "uid": sparks[0].uid}): return {"ok": false}
			else:
				var kind := "straight" if (ports[0] + 2) % 4 == ports[1] else "corner"
				if not command(controller, "place_wire", {"index": cell, "kind": kind}): return {"ok": false}
		for rotation in 4:
			if Circuit.logical_ports(controller.snapshot().board[cell]) == ports: break
			if not command(controller, "rotate", {"index": cell}): return {"ok": false}
	var result: Dictionary = controller.snapshot().forecast
	return {"ok": result.valid and result.damage == 6 and result.shield == 0, "path": selected, "rune_cell": rune_cell, "preview": result}

static func _walk(path: Array, target: int, paths: Array) -> void:
	if path.back() == target:
		paths.append(path.duplicate())
		return
	for direction in 4:
		var next := Circuit.neighbor(path.back(), direction)
		if next < 0 or next in path: continue
		path.append(next)
		_walk(path, target, paths)
		path.pop_back()

static func _direction(first: int, second: int) -> int:
	for direction in 4:
		if Circuit.neighbor(first, direction) == second: return direction
	return -1
