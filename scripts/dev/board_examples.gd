extends RefCounted

# Development witnesses only. Every setup comes from the ordinary production
# loader, and every construction step goes through the existing controller.
# No search, reroll, free card, stock override or board mutation occurs here.
const Loader = preload("res://scripts/core/content_loader.gd")
const PATH := "res://data/board_examples.json"
const VERSION := "rc009_board_examples_v1"
const BOARD_IDS := ["board_training", "board_gallery", "board_ossuary", "board_belfry"]
const EDIT_COMMANDS := ["place_wire", "place_rune", "rotate", "flip", "undo", "technique"]

static func load_example(board_id: String, path: String = PATH) -> Dictionary:
	if not BOARD_IDS.has(board_id):
		return _failure(["Unknown authored board example: " + board_id])
	var loaded := Loader.read_document(path)
	if not loaded.ok:
		return _failure(loaded.errors)
	var validated := validate_document(loaded.document)
	if not validated.ok:
		return validated
	for example in validated.examples:
		if example.board_id != board_id:
			continue
		var setup := Loader.load_setup(example.encounter_path)
		if not setup.ok:
			return _failure(setup.errors)
		if setup.setup.encounter.board_id != board_id or int(setup.setup.encounter.seed) != int(example.seed) or setup.setup.encounter.loadout_id != "starter" or not setup.setup.has("production"):
			return _failure(["Example must match its natural production starter encounter, board and seed."])
		return {"ok": true, "errors": [], "example": example.duplicate(true), "setup": setup.setup.duplicate(true)}
	return _failure(["Missing authored board example: " + board_id])

static func validate_document(document: Variant) -> Dictionary:
	if not document is Dictionary or not document.get("version") is String or document.version != VERSION or not document.get("examples") is Array or document.examples.size() != BOARD_IDS.size():
		return _failure(["Board examples require version " + VERSION + " and exactly four examples."])
	var errors: Array = []
	var seen := {}
	for value in document.examples:
		if not value is Dictionary:
			errors.append("Every authored example must be an object.")
			continue
		var id: Variant = value.get("board_id")
		if not id is String or not BOARD_IDS.has(id) or seen.has(id):
			errors.append("Authored examples need each of the four stable board IDs exactly once.")
			continue
		seen[id] = true
		if not value.get("setup_kind") is String or value.setup_kind != "natural_starter_draw" or not value.get("purpose") is String or value.purpose.is_empty():
			errors.append(str(id) + ": expected a purpose and natural_starter_draw setup.")
		if not value.get("encounter_path") is String or value.encounter_path != "res://data/development/rc009_%s_encounter.json" % str(id).trim_prefix("board_"):
			errors.append(str(id) + ": expected the explicit RC-009 development encounter path.")
		if not _integer(value.get("seed")) or value.seed < 0 or value.seed > 2147483647:
			errors.append(str(id) + ": seed must be an integer in the production range.")
		if not value.get("commands") is Array or value.commands.is_empty():
			errors.append(str(id) + ": expected exact player commands.")
		else:
			for action in value.commands:
				if not _valid_action(action):
					errors.append(str(id) + ": malformed construction command.")
		if not value.get("expected") is Dictionary:
			errors.append(str(id) + ": expected initial, built and after_cast observations.")
		else:
			for phase in ["initial", "built", "after_cast"]:
				if not value.expected.get(phase) is Dictionary or value.expected[phase].is_empty():
					errors.append(str(id) + ": missing " + phase + " observations.")
	return {"ok": true, "errors": [], "examples": _normalize_numbers(document.examples)} if errors.is_empty() else _failure(errors)

# Godot's JSON parser represents numbers as floats. Normalize whole numbers at
# this data boundary so nested Array/Dictionary equality keeps checking exact
# snapshots, including their integer cell/UID fields, rather than coercing a
# subset of expected observations or ignoring type-sensitive array contents.
static func _normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = _normalize_numbers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_normalize_numbers(item))
		return result
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return value

static func _integer(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and value == floor(value))

static func _valid_action(action: Variant) -> bool:
	if not action is Dictionary or not action.get("command") is String or not action.command in EDIT_COMMANDS or not action.get("arguments") is Dictionary:
		return false
	var args: Dictionary = action.arguments
	match action.command:
		"undo": return args.is_empty()
		"technique": return args.size() == 1 and _integer(args.get("uid")) and args.uid >= 0
		"place_rune": return args.size() == 2 and _cell(args.get("index")) and _integer(args.get("uid")) and args.uid >= 0
		"place_wire": return args.size() == 2 and _cell(args.get("index")) and args.get("kind") in ["straight", "corner", "split", "join", "erase"]
		_: return args.size() == 1 and _cell(args.get("index"))

static func _cell(value: Variant) -> bool:
	return _integer(value) and value >= 0 and value < 16

# Facts are deliberately independent of encounter title/help and other
# presentation metadata. Full board, piles and instance IDs remain inspectable.
static func facts(snapshot: Dictionary) -> Dictionary:
	var usage := {"straight": 0, "corner": 0, "split": 0, "join": 0, "rune": 0}
	var endpoints := {}
	for cell in range(snapshot.board.size()):
		var piece: Dictionary = snapshot.board[cell]
		if usage.has(piece.get("kind")):
			usage[piece.kind] += 1
		elif piece.get("kind") in ["begin", "end"]:
			endpoints[piece.kind] = {"cell": cell, "rotation": int(piece.rotation)}
	return {"board": snapshot.board.duplicate(true), "endpoints": endpoints,
		"hand": snapshot.hand.duplicate(true), "draw_pile": snapshot.draw_pile.duplicate(true),
		"discard_pile": snapshot.discard_pile.duplicate(true), "energy": snapshot.energy,
		"player_hp": snapshot.player_hp, "enemy_hp": snapshot.enemy_hp, "intent": snapshot.intent,
		"turn": snapshot.turn, "state": snapshot.state, "undo_count": snapshot.undo_count,
		"kit_id": snapshot.kit.id, "stock": snapshot.stock.duplicate(true),
		"stock_totals": snapshot.stock_totals.duplicate(true), "physical_usage": usage,
		"forecast": snapshot.forecast.duplicate(true)}

# Call on a fresh controller with its default immediate presenter. A caller
# wishing to animate a construction can send the same commands individually.
# opening validates only; built constructs; cast additionally commits one Cast.
static func apply(controller, example: Dictionary, step: String = "built") -> Dictionary:
	if not step in ["opening", "built", "cast"]:
		return _failure(["Example step must be opening, built or cast."])
	var initial := facts(controller.snapshot())
	if initial != example.expected.initial:
		return _failure(["Authored example opening differs from its recorded natural starter setup."])
	var report := {"ok": true, "errors": [], "board_id": example.board_id, "seed": example.seed,
		"initial": initial, "built": {}, "after": initial, "last_result": {}}
	if step == "opening":
		return report
	for index in range(example.commands.size()):
		var action: Dictionary = example.commands[index]
		if not controller.command(action.command, action.arguments):
			return _failure(["%s rejected authored command %d: %s" % [example.board_id, index + 1, str(action)]])
	var built := facts(controller.snapshot())
	if built != example.expected.built:
		return _failure(["%s constructed circuit differs from its recorded result." % example.board_id])
	report.built = built
	report.after = built
	if step == "built":
		return report
	var batches: Array = []
	var capture := func(result: Dictionary): batches.append(result.duplicate(true))
	controller.presentation_started.connect(capture)
	var accepted: bool = controller.command("cast")
	controller.presentation_started.disconnect(capture)
	if not accepted or batches.is_empty():
		return _failure(["%s rejected its authored Cast." % example.board_id])
	report.last_result = batches.back()
	report.after = facts(controller.snapshot())
	if report.after != example.expected.after_cast:
		return _failure(["%s cleanup/new turn differs from its recorded result." % example.board_id])
	return report

static func _failure(errors: Array) -> Dictionary:
	return {"ok": false, "errors": errors.duplicate(), "setup": {}, "example": {}}
