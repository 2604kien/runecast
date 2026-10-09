class_name RuneExperiments
extends RefCounted

# RC-005 fixtures and an explicitly versioned RC-006 follow-up. No normal overrides.
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const VERSION := Loader.EXPERIMENT_VERSION
const DEFAULT_SEED := 42
const SCENARIOS := [
	{"id": "effects", "title": "A · Effect lifetime", "variants": ["control", "treatment", "full_reset", "moving_endpoints", "free_endpoints"]},
	{"id": "split_inventory", "title": "B1 · Split inventory", "variants": ["control", "treatment"]},
	{"id": "split_cost", "title": "B2 · Split cost", "variants": ["control", "treatment"]},
	{"id": "endpoints", "title": "C1 · Endpoint placement", "variants": ["control", "treatment"]},
	{"id": "blocked", "title": "C2 · Blocked cell", "variants": ["control", "treatment"]},
	{"id": "ports", "title": "C3 · Effect ports", "variants": ["control", "treatment"]},
	{"id": "hits", "title": "D · Damage hits", "variants": ["control", "treatment"]},
	{"id": "expiry", "title": "E · Temporary expiry", "variants": ["control", "retained", "empty"]},
	{"id": "encounters", "title": "F · Encounter transfer", "variants": ["control", "treatment"]}
]

static func list_scenarios() -> Array:
	return SCENARIOS.duplicate(true)

static func load_setup(scenario_id: Variant, variant_id: Variant, seed: Variant = DEFAULT_SEED) -> Dictionary:
	var source := documents(scenario_id, variant_id, seed)
	if not source.ok:
		return {"ok": false, "errors": source.errors, "setup": {}}
	return Loader.validate_documents(source.documents, {}, source.experiment)

# Raw detached fixtures are exposed for validation tests, never passed directly
# to Combat. Scenario selection and seed are validated before definitions exist.
static func documents(scenario_id: Variant, variant_id: Variant, seed: Variant = DEFAULT_SEED) -> Dictionary:
	var selected := Loader.experiment_options(scenario_id, variant_id, seed)
	if not selected.ok:
		return {"ok": false, "errors": selected.errors, "documents": {}, "experiment": {}}
	var source := Loader.read_document(Loader.DEFINITION_PATHS.runes)
	if not source.ok:
		return {"ok": false, "errors": source.errors, "documents": {}, "experiment": {}}
	if not source.document is Array or not source.document.all(func(item): return item is Dictionary):
		return {"ok": false, "errors": ["res://data/runes.json: expected an array of rune definition objects"], "documents": {}, "experiment": {}}
	var runes: Array = source.document.duplicate(true)
	var placements := _one_pair()
	var inventory := {"split": 1, "join": 1}
	var enemy_health := 36
	var full_reset: bool = scenario_id == "effects" and variant_id in ["full_reset", "moving_endpoints", "free_endpoints"]
	if full_reset:
		placements = [{"cell": 0, "kind": "begin"}, {"cell": 14, "kind": "end"}]
	if scenario_id == "split_inventory" and variant_id == "treatment":
		inventory = {"split": 2, "join": 2}
	if scenario_id == "split_cost":
		inventory = {"split": 2, "join": 2}
		placements = _two_pairs()
	if scenario_id == "endpoints" and variant_id == "treatment":
		for piece in placements:
			piece.cell = 15 - int(piece.cell)
			piece.rotation = (int(piece.get("rotation", 0)) + 2) % 4
	if scenario_id in ["blocked", "ports", "expiry"]:
		placements = _simple_path()
	if scenario_id == "blocked" and variant_id == "treatment":
		placements.append({"cell": 6, "kind": "blocked"})
	if scenario_id == "ports" and variant_id == "treatment":
		# Preserve the same complete path, effect amount, ownership and cost.
		# Accommodating the corner moves its initial instance to the turn at 3.
		_set_rune_field(runes, "spark", "port_shape", "corner")
		_replace(placements, 1, {"cell": 1, "kind": "straight"})
		_replace(placements, 3, {"cell": 3, "kind": "rune", "rune_id": "spark"})
	if scenario_id == "expiry":
		# Same corner-port dependency in all three expiry variants, including
		# the generated hand card from the existing Conjure technique.
		_set_rune_field(runes, "free_spark", "port_shape", "corner")
		_replace(placements, 3, {"cell": 3, "kind": "rune", "rune_id": "free_spark"})
		placements.append({"cell": 8, "kind": "rune", "rune_id": "free_spark", "rotation": 2})
	if scenario_id == "encounters":
		enemy_health = 24
	var loadout := {"id": "rc005_collection", "max_health": 40, "current_health": 40,
		"energy_per_turn": 6, "draw_per_turn": 3,
		"owned_cards": ["spark", "shield", "conjure", "spark", "shield", "focus", "focus", "conjure"],
		"opening_policy": "curated", "opening_hand": ["spark", "shield", "conjure"], "inventory": inventory}
	var fixture_id := "rc006_effects_full_reset" if full_reset else "rc005_" + str(scenario_id)
	if scenario_id == "effects" and variant_id == "moving_endpoints":
		fixture_id = "rc006_effects_moving_endpoints"
	if scenario_id == "effects" and variant_id == "free_endpoints":
		fixture_id = "rc006_effects_free_endpoints"
	var summary := rule_summary(scenario_id, variant_id)
	var data := {"runes": runes,
		"boards": [{"id": fixture_id + "_board", "width": 4, "height": 4, "placements": placements}],
		"enemies": [{"id": "rc005_probe", "name": "Experiment Wisp", "max_health": enemy_health, "intents": [3]}],
		"loadouts": [loadout],
		"encounter": {"id": fixture_id, "enemy_id": "rc005_probe", "board_id": fixture_id + "_board",
			"loadout_id": "rc005_collection", "title": "RC-006 FOLLOW-UP" if full_reset else "RC-005 EXPERIMENT", "help_text": summary,
			"opening_log": summary, "seed": int(seed)}}
	return {"ok": true, "errors": [], "documents": data, "experiment": selected.setup}

static func rule_summary(scenario_id: String, variant_id: String) -> String:
	match scenario_id:
		"effects":
			if variant_id == "free_endpoints":
				return "Every turn starts with Begin and End at random, different cells; they can be neighbors. Click Begin or End, then use Rotate to turn it. Cast or Pass clears other pieces: permanents to discard, temporaries gone. Normal draws can repeat."
			if variant_id == "moving_endpoints":
				return "Cast or Pass clears the board: permanents to discard, temporaries gone. Each new turn moves both endpoints and may rotate them; a route is always possible. First turn uses the familiar positions. Normal draws can repeat cards."
			if variant_id == "full_reset":
				return "Begin and End only at turn start. Cast or Pass clears all other pieces; installed permanent cards enter discard and temporary cards vanish. Normal draws can repeat cards."
			return "Powered permanent effects stay installed after Cast." if variant_id == "control" else "Cast consumes powered permanent effects into discard; matching wires replace them. Pass keeps them."
		"split_inventory":
			return "One Split/Join pair; each powered Split costs 1." if variant_id == "control" else "Two Split/Join pairs; each powered Split costs 1. Join costs 0. Installed pieces count against the available supply."
		"split_cost":
			return "Two installed pairs: 18 damage, each Split costs 1 (total 4)." if variant_id == "control" else "Two installed pairs: 18 damage, each Split costs 2 (total 6). Focus competes for casting energy."
		"endpoints":
			return "Begin cell 0, End cell 14; endpoints are protected." if variant_id == "control" else "Board rotated 180 degrees: Begin cell 15, End cell 1. Endpoint ports and protection move with them."
		"blocked":
			return "All non-endpoint cells editable; simple right-edge path." if variant_id == "control" else "Cell 6 is blocked: no placement, rotation or path through it. Right-edge path remains valid."
		"ports":
			return "Spark has straight ports, installed at cell 1." if variant_id == "control" else "Spark has corner ports, installed at cell 3 on the same path. Rotate changes its actual ports."
		"hits":
			return "12 total damage is one aggregate hit." if variant_id == "control" else "12 total damage is two ordered 6-damage hits; stop on lethal. Shield is still one total."
		"expiry":
			var replacement := "straight wire" if variant_id == "control" else ("matching corner wire" if variant_id == "retained" else "empty cell")
			return "Corner temporaries at cells 3 and 8 expire to %s after Cast or Pass. Conjure tests unused hand expiry." % replacement
		"encounters":
			return "Two 24-HP encounters. Next rebuilds starting wires; installed effects return to the card pool. Health carries." if variant_id == "control" else "Two 24-HP encounters. Next retains topology and installed permanent instances. Health carries; hand is rebuilt."
	return "Unknown experimental comparison."

# Facilitator/test reference only: do not expose solutions in participant copy
# before a free attempt. Cell indices are zero-based, row-major. Actions can be
# issued through the authoritative command path to build the bounded witnesses.
static func known_solution_actions(scenario_id: String, variant_id: String, seed: int = DEFAULT_SEED) -> Array:
	if scenario_id == "effects" and variant_id == "free_endpoints":
		return _free_endpoint_solution(seed)
	if scenario_id == "effects" and variant_id in ["full_reset", "moving_endpoints"]:
		# Curated opening Spark is UID 0; start empty, build a six-damage path.
		return [{"command": "place_rune", "arguments": {"index": 1, "uid": 0}},
			{"command": "place_wire", "arguments": {"index": 2, "kind": "corner"}},
			{"command": "place_wire", "arguments": {"index": 6, "kind": "straight"}},
			{"command": "rotate", "arguments": {"index": 6}},
			{"command": "place_wire", "arguments": {"index": 10, "kind": "straight"}},
			{"command": "rotate", "arguments": {"index": 10}}]
	if scenario_id == "split_inventory" and variant_id == "treatment":
		return [{"command": "place_wire", "arguments": {"index": 6, "kind": "join"}},
			{"command": "place_wire", "arguments": {"index": 7, "kind": "split"}},
			{"command": "rotate", "arguments": {"index": 7}}]
	return []

static func _free_endpoint_solution(seed: int) -> Array:
	var loaded := load_setup("effects", "free_endpoints", seed)
	if not loaded.ok:
		return []
	var game := Combat.new(loaded.setup)
	var begin := -1
	var end := -1
	for cell in range(game.board.size()):
		if game.board[cell].get("kind") == "begin":
			begin = cell
		elif game.board[cell].get("kind") == "end":
			end = cell
	var path := _rune_route([begin], end, false)
	assert(not path.is_empty(), "Every distinct endpoint pair must support a straight rune socket.")
	var actions: Array = []
	_append_rotations(actions, begin, int(game.board[begin].rotation), (_route_direction(begin, path[1]) + 3) % 4)
	_append_rotations(actions, end, int(game.board[end].rotation), _route_direction(end, path[-2]))
	var rune_installed := false
	for step in range(1, path.size() - 1):
		var cell: int = path[step]
		var input := _route_direction(cell, path[step - 1])
		var output := _route_direction(cell, path[step + 1])
		var straight: bool = (input + 2) % 4 == output
		var kind := "straight" if straight else "corner"
		var rotation := 0
		var reversed := false
		var matched := false
		for flipped in [false, true]:
			for candidate in range(4):
				var ports := Circuit.ports({"kind": kind, "rotation": candidate, "reversed": flipped})
				if ports.input == [input] and ports.output == [output]:
					rotation = candidate
					reversed = flipped
					matched = true
					break
			if matched:
				break
		assert(matched, "A simple grid path needs only straight or corner connectors.")
		if straight and not rune_installed:
			# Opening Spark is UID 0. Every other interior cell uses free wire.
			actions.append({"command": "place_rune", "arguments": {"index": cell, "uid": 0}})
			rune_installed = true
		else:
			actions.append({"command": "place_wire", "arguments": {"index": cell, "kind": kind}})
			if reversed:
				actions.append({"command": "flip", "arguments": {"index": cell}})
		_append_rotations(actions, cell, 0, rotation)
	return actions

static func _append_rotations(actions: Array, cell: int, before: int, after: int) -> void:
	for _step in range((after - before + 4) % 4):
		actions.append({"command": "rotate", "arguments": {"index": cell}})

static func _route_direction(from_cell: int, to_cell: int) -> int:
	for direction in range(4):
		if Circuit.neighbor(from_cell, direction) == to_cell:
			return direction
	return -1

static func _rune_route(path: Array, end: int, has_straight: bool) -> Array:
	# Facilitator-only search: allow a detour for adjacent endpoints so a real
	# Spark socket can fit. This does not bias selection or prefill the board.
	var current: int = path[-1]
	if current == end:
		return path if has_straight else []
	for direction in range(4):
		var next := Circuit.neighbor(current, direction)
		if next < 0 or path.has(next):
			continue
		var straight: bool = has_straight or (path.size() > 1 and _route_direction(path[-2], current) == direction)
		var extended := path.duplicate()
		extended.append(next)
		var route := _rune_route(extended, end, straight)
		if not route.is_empty():
			return route
	return []

static func _one_pair() -> Array:
	return [{"cell": 0, "kind": "begin"}, {"cell": 1, "kind": "rune", "rune_id": "spark"},
		{"cell": 2, "kind": "split"}, {"cell": 3, "kind": "corner"},
		{"cell": 6, "kind": "straight", "rotation": 1}, {"cell": 7, "kind": "straight", "rotation": 1},
		{"cell": 8, "kind": "rune", "rune_id": "shield"},
		{"cell": 10, "kind": "join"}, {"cell": 11, "kind": "corner", "rotation": 1},
		{"cell": 14, "kind": "end"}]

static func _two_pairs() -> Array:
	var result := _one_pair()
	_replace(result, 6, {"cell": 6, "kind": "join"})
	_replace(result, 7, {"cell": 7, "kind": "split", "rotation": 1})
	return result

static func _simple_path() -> Array:
	return [{"cell": 0, "kind": "begin"}, {"cell": 1, "kind": "rune", "rune_id": "spark"},
		{"cell": 2, "kind": "straight"}, {"cell": 3, "kind": "corner"},
		{"cell": 7, "kind": "straight", "rotation": 1},
		{"cell": 10, "kind": "corner", "rotation": 3, "reversed": true},
		{"cell": 11, "kind": "corner", "rotation": 1}, {"cell": 14, "kind": "end"}]

static func _set_rune_field(runes: Array, id: String, field: String, value: Variant) -> void:
	for rune in runes:
		if rune.get("id") == id:
			rune[field] = value

static func _replace(placements: Array, cell: int, replacement: Dictionary) -> void:
	for index in range(placements.size()):
		if placements[index].cell == cell:
			placements[index] = replacement
			return
