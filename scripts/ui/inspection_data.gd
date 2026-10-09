extends RefCounted

# Read-only presentation helpers. Inputs are detached controller snapshots; this
# file has no model/controller reference and never executes a gameplay command.
const Circuit = preload("res://scripts/core/circuit.gd")
const DIRECTIONS := ["North", "East", "South", "West"]
const TOOL_NAMES := {"straight": "Straight wire", "corner": "Corner wire", "split": "Split", "join": "Join", "erase": "Erase"}

static func describe_hand(snapshot: Dictionary, uid: int) -> Dictionary:
	var card := _hand_card(snapshot, uid)
	var rune: Dictionary = snapshot.get("catalog", {}).get(card.get("id", ""), {})
	if card.is_empty() or rune.is_empty():
		return {}
	var technique: bool = rune.get("type") == "technique"
	var lines: Array[String] = ["Technique - in hand" if technique else "Effect rune - in hand", _effect(snapshot, rune)]
	if technique:
		lines.append("Energy: %d, paid immediately when activated. Inspection does not activate it." % int(rune.cost))
		lines.append("Ports: none; techniques do not occupy board cells.")
		lines.append("Permanent card. Activation sends it to discard and clears Undo. If unplayed, Cast/Pass sends it to discard.")
	else:
		lines.append("Energy: %d, paid once on a valid Cast if powered. Placement costs no energy." % int(rune.cost))
		lines.append("Unrotated " + _ports({"kind": "rune", "port_shape": rune.get("port_shape", "straight")}))
		lines.append("Placement keeps the target's rotation. Use Rotate after placing.")
		lines.append(_rune_cleanup(snapshot, rune, {}, false))
	return {"title": str(rune.name), "text": "\n\n".join(lines), "uid": uid, "kind": str(rune.type)}

static func describe_cell(snapshot: Dictionary, index: int) -> Dictionary:
	var board: Array = snapshot.get("board", [])
	if index < 0 or index >= board.size():
		return {}
	var piece: Dictionary = board[index]
	var location := "Row %d, column %d" % [index / 4 + 1, index % 4 + 1]
	if piece.is_empty():
		return {"title": "Empty cell", "text": location + "\n\nChoose a rune or connector, then tap an eligible cell. The circuit may stay incomplete while you build.", "index": index, "kind": "empty"}
	var kind: String = piece.get("kind", "")
	if kind == "blocked":
		return {"title": "Blocked cell", "text": location + "\n\nThis profile protects this cell. It cannot hold, rotate or erase a piece.", "index": index, "kind": kind}
	var lines: Array[String] = [location]
	var title := str(TOOL_NAMES.get(kind, kind.capitalize()))
	if kind == "rune":
		var rune: Dictionary = snapshot.get("catalog", {}).get(piece.get("rune_id", ""), {})
		if rune.is_empty():
			return {}
		title = str(rune.name)
		lines.append("Installed effect rune. " + _effect(snapshot, rune))
		lines.append("Energy: %d, paid once on a valid Cast if powered. Editing costs no energy." % int(rune.cost))
		lines.append(_rune_cleanup(snapshot, rune, piece, true))
	elif kind in ["begin", "end"]:
		lines.append("Endpoint. Starts a zero-value signal." if kind == "begin" else "Endpoint. Releases the combined incoming spell.")
		lines.append("No energy cost. Cannot be erased, replaced or flipped.")
		lines.append("Rotate is available." if _rules(snapshot).get("endpoint_rotation", "fixed") == "player" else "Rotation is locked in this profile.")
		lines.append("Moves to a new position and direction next turn." if _rules(snapshot).get("endpoint_policy", "fixed") in ["random_any_cells", "random_each_turn"] else "Stays in its socket after Cast/Pass.")
	else:
		lines.append(_connector_effect(kind))
		lines.append("Energy: %d, paid once on a valid Cast if powered. Editing costs no energy." % connector_cost(snapshot, kind))
		lines.append(_stock_text(snapshot, kind))
		lines.append(_connector_cleanup(snapshot))
	lines.append(_ports(piece))
	lines.append(power_text(snapshot, index))
	return {"title": title, "text": "\n\n".join(lines), "index": index, "kind": kind}

static func describe_tool(snapshot: Dictionary, kind: String) -> Dictionary:
	if not TOOL_NAMES.has(kind) or snapshot.is_empty():
		return {}
	if kind == "erase":
		return {"title": "Erase", "text": "Editing tool. Tap an occupied editable cell to remove its piece.\n\nNo energy cost. Runes return to hand; connectors refund their stock. Begin, End and blocked cells are protected. Undo can restore an erase.", "kind": kind}
	var lines: Array[String] = ["Connector tool. " + _connector_effect(kind),
		"Energy: %d, paid once on a valid Cast if powered. Placement costs no energy." % connector_cost(snapshot, kind),
		_stock_text(snapshot, kind), "New placement " + _ports({"kind": kind}),
		"Rotate changes direction." + (" Flip reverses input and output." if kind in ["straight", "corner"] else " Flip is unavailable for this piece."),
		_connector_cleanup(snapshot)]
	return {"title": str(TOOL_NAMES[kind]), "text": "\n\n".join(lines), "kind": kind}

static func placement(snapshot: Dictionary, index: int, tool: String = "", uid: int = -1) -> Dictionary:
	var reason := _editable_reason(snapshot, index)
	if reason != "":
		return _availability(false, reason)
	if uid >= 0:
		var card := _hand_card(snapshot, uid)
		if card.is_empty():
			return _availability(false, "That card is no longer in hand.")
		if snapshot.get("catalog", {}).get(card.id, {}).get("type") != "rune":
			return _availability(false, "Techniques activate from hand; they cannot be placed.")
		return _availability(true, "Eligible placement; the circuit may remain incomplete.")
	if not TOOL_NAMES.has(tool):
		return _availability(false, "Select a rune or connector first.")
	if tool == "erase":
		return edit_action(snapshot, index, "erase")
	var totals: Dictionary = snapshot.get("stock_totals", {})
	if totals.has(tool) and int(snapshot.get("stock", {}).get(tool, 0)) <= 0 and snapshot.board[index].get("kind") != tool:
		return _availability(false, "You own %d %s. No stock available; erase or replace an installed one first." % [int(totals[tool]), tool])
	return _availability(true, "Eligible placement; the circuit may remain incomplete.")

static func edit_action(snapshot: Dictionary, index: int, action: String) -> Dictionary:
	if snapshot.is_empty():
		return _availability(false, "No encounter is available.")
	if snapshot.get("state") != "playing":
		return _availability(false, "The battle has ended.")
	if action == "undo":
		return _availability(int(snapshot.get("undo_count", 0)) > 0, "Undo the last edit." if int(snapshot.get("undo_count", 0)) > 0 else "No edits to undo; techniques and turns clear Undo.")
	var board: Array = snapshot.get("board", [])
	if index < 0 or index >= board.size():
		return _availability(false, "Select a board piece first.")
	var piece: Dictionary = board[index]
	if action == "rotate" and piece.get("kind") in ["begin", "end"]:
		var allowed: bool = _rules(snapshot).get("endpoint_rotation", "fixed") == "player"
		return _availability(allowed, "Rotate endpoint clockwise." if allowed else "Endpoint rotation is locked in this profile.")
	var reason := _editable_reason(snapshot, index)
	if reason != "":
		return _availability(false, reason)
	if piece.is_empty():
		return _availability(false, "This cell is empty.")
	if action == "flip":
		var allowed: bool = piece.get("kind") in ["straight", "corner"]
		return _availability(allowed, "Reverse this wire's input and output." if allowed else "Only Straight and Corner wires support Flip.")
	if action in ["rotate", "erase"]:
		return _availability(true, "Rotate clockwise." if action == "rotate" else "Return this piece to hand or stock.")
	return _availability(false, "Unknown editing action.")

static func technique_action(snapshot: Dictionary, uid: int) -> Dictionary:
	if snapshot.is_empty() or snapshot.get("state") != "playing":
		return _availability(false, "The battle is not available for activation.")
	var card := _hand_card(snapshot, uid)
	var rune: Dictionary = snapshot.get("catalog", {}).get(card.get("id", ""), {})
	if card.is_empty() or rune.get("type") != "technique":
		return _availability(false, "That technique is no longer in hand.")
	var cost := int(rune.get("cost", 0))
	if int(snapshot.get("energy", 0)) < cost:
		return _availability(false, "Need %d energy; you have %d." % [cost, int(snapshot.get("energy", 0))])
	return _availability(true, "Activate for %d energy." % cost)

static func connector_cost(snapshot: Dictionary, kind: String) -> int:
	if not kind in ["split", "join"]:
		return 0
	var rules := _rules(snapshot)
	if rules.has(kind + "_cost"):
		return int(rules[kind + "_cost"])
	# Legacy snapshots omit default costs. Ask the core evaluator using a new,
	# valid reference circuit with one of each connector and no effect rune.
	# Only the other connector's contribution is suppressed; no balance default
	# is copied into the view and the input snapshot remains untouched.
	var options := rules.duplicate(true)
	options["join_cost" if kind == "split" else "split_cost"] = 0
	var board := Circuit.demo_board()
	board[1] = {"kind": "straight", "rotation": 0}
	return int(Circuit.evaluate(board, {}, options).cost)

static func power_text(snapshot: Dictionary, index: int) -> String:
	var board: Array = snapshot.get("board", [])
	if index < 0 or index >= board.size() or board[index].is_empty():
		return ""
	# Forecast.active is empty on an incomplete circuit. This monotonic walk
	# reports actual matched input connectivity without rejecting intermediate
	# construction or propagating through a Join with a missing input.
	var powered := {}
	var arrivals := {}
	for cell in range(board.size()):
		if board[cell].get("kind") == "begin":
			powered[cell] = true
	var changed := true
	while changed:
		changed = false
		for cell in powered.keys():
			for direction in Circuit.ports(board[cell]).output:
				var next := Circuit.neighbor(cell, int(direction))
				if next < 0 or next >= board.size() or board[next].is_empty():
					continue
				var inputs: Array = Circuit.ports(board[next]).input
				var incoming: int = (int(direction) + 2) % 4
				if not inputs.has(incoming):
					continue
				if not arrivals.has(next):
					arrivals[next] = []
				if not arrivals[next].has(incoming):
					arrivals[next].append(incoming)
				if arrivals[next].size() == inputs.size() and not powered.has(next):
					powered[next] = true
					changed = true
	if powered.has(index):
		return "Powered from Begin." if snapshot.get("forecast", {}).get("valid", false) else "Powered from Begin; the circuit is incomplete and cannot Cast yet."
	if arrivals.has(index):
		return "Partially connected from Begin. Every Join input must be powered."
	return "Disconnected from Begin; contributes no effect or casting cost."

static func _hand_card(snapshot: Dictionary, uid: int) -> Dictionary:
	for card in snapshot.get("hand", []):
		if int(card.get("uid", -1)) == uid:
			return card
	return {}

static func _rules(snapshot: Dictionary) -> Dictionary:
	var production: Dictionary = snapshot.get("production", {})
	return production if not production.is_empty() else snapshot.get("experiment", {})

static func _effect(snapshot: Dictionary, rune: Dictionary) -> String:
	var value := int(rune.get("value", 0))
	match rune.get("effect"):
		"damage": return "Adds %d damage to the signal." % value
		"shield": return "Adds %d shield against the surviving enemy's attack." % value
		"draw": return "Draws up to %d cards immediately." % value
		"conjure":
			var generated: Dictionary = snapshot.get("catalog", {}).get(rune.get("generated_rune_id", ""), {})
			return "Creates %d temporary %s in hand immediately." % [value, generated.get("name", "runes")]
	return "Effect unavailable."

static func _ports(piece: Dictionary) -> String:
	var ports := Circuit.ports(piece)
	var inputs: Array[String] = []
	var outputs: Array[String] = []
	for direction in ports.input:
		inputs.append(DIRECTIONS[direction])
	for direction in ports.output:
		outputs.append(DIRECTIONS[direction])
	return "ports: input %s; output %s." % [" / ".join(inputs) if not inputs.is_empty() else "none", " / ".join(outputs) if not outputs.is_empty() else "none"]

static func _rune_cleanup(snapshot: Dictionary, rune: Dictionary, piece: Dictionary, installed: bool) -> String:
	var rules := _rules(snapshot)
	if rune.get("temporary", false):
		var text := "Temporary: never enters the permanent collection, draw pile or discard."
		if not installed:
			text += " Unused in hand, it disappears after Cast/Pass."
		if rules.get("board_reset", "none") == "each_turn" or rules.get("expiry", "straight") == "empty":
			return text + " Installed, it disappears after Cast/Pass, leaving an empty cell."
		var shape := "straight"
		if rules.get("expiry", "straight") == "retained":
			shape = str(piece.get("port_shape", rune.get("port_shape", "straight")))
		return text + " Installed, it expires after Cast/Pass and leaves a %s wire." % shape
	var text := "Permanent card."
	if not installed:
		text += " Unplayed in hand, Cast/Pass sends it to discard."
	if rules.get("board_reset", "none") == "each_turn":
		return text + " Installed, Cast/Pass sends it to discard and clears the cell, even if disconnected."
	if rules.get("effects", "persistent") == "consumed":
		return text + " On a valid Cast, a powered rune enters discard and leaves a matching wire. Disconnected runes and Pass keep it installed."
	return text + " Installed, it remains after Cast/Pass in this profile."

static func _connector_effect(kind: String) -> String:
	match kind:
		"split": return "Copies the incoming signal into both outgoing branches."
		"join": return "Adds arriving signals. Both inputs must be powered."
		_: return "Carries the signal from its input to its output."

static func _stock_text(snapshot: Dictionary, kind: String) -> String:
	var totals: Dictionary = snapshot.get("stock_totals", {})
	if not totals.has(kind):
		return "Stock: unlimited in this profile."
	return "Stock: %d available / %d total. Installed pieces reserve stock even when disconnected; erase or replacement refunds it." % [int(snapshot.get("stock", {}).get(kind, 0)), int(totals[kind])]

static func _connector_cleanup(snapshot: Dictionary) -> String:
	if _rules(snapshot).get("board_reset", "none") == "each_turn":
		return "Cast/Pass clears this connector." + (" The next turn supplies a new kit; unused stock does not carry over." if not snapshot.get("production", {}).is_empty() else " Its stock becomes available again.")
	return "Stays installed after Cast/Pass in this profile. Erase returns it to stock."

static func _editable_reason(snapshot: Dictionary, index: int) -> String:
	if snapshot.is_empty():
		return "No encounter is available."
	if snapshot.get("state") != "playing":
		return "The battle has ended."
	var board: Array = snapshot.get("board", [])
	if index < 0 or index >= board.size():
		return "Choose a cell on the board."
	var kind: String = board[index].get("kind", "")
	if kind in ["begin", "end"]:
		return "Begin and End are protected; select the endpoint to inspect or Rotate it."
	if kind == "blocked":
		return "This cell is blocked in the active profile."
	if _rules(snapshot).is_empty() and index in [Circuit.BEGIN, Circuit.END]:
		return "This endpoint socket is protected in the active profile."
	return ""

static func _availability(allowed: bool, reason: String) -> Dictionary:
	return {"allowed": allowed, "reason": reason}
