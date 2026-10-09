extends RefCounted

const Inspect = preload("res://scripts/ui/inspection_data.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Experiments = preload("res://scripts/core/experiments.gd")
const Circuit = preload("res://scripts/core/circuit.gd")

func run(check: Callable) -> void:
	_descriptions_and_purity(check)
	_live_values(check)
	_profiles_and_power(check)
	_availability(check)

func _descriptions_and_purity(check: Callable) -> void:
	var model := Combat.new(Loader.load_setup().setup)
	var state := _model_state(model)
	var snapshot := model.snapshot()
	var retained := snapshot.duplicate(true)
	for card in snapshot.hand:
		var description := Inspect.describe_hand(snapshot, int(card.uid))
		check.call(description.title == snapshot.catalog[card.id].name and description.text.contains("Energy:"), "Hand inspection reads the current owned card's name and energy cost.")
	for index in range(snapshot.board.size()):
		check.call(not Inspect.describe_cell(snapshot, index).is_empty(), "Every production board cell has a safe touch-inspection description (%d)." % index)
	for kind in ["straight", "corner", "split", "join", "erase"]:
		var description := Inspect.describe_tool(snapshot, kind)
		check.call(not description.is_empty() and description.text.contains("energy"), "The %s tool has an accessible cost/behavior description." % kind)
		for index in range(snapshot.board.size()):
			Inspect.placement(snapshot, index, kind)
			for action in ["rotate", "flip", "erase", "undo"]:
				Inspect.edit_action(snapshot, index, action)
	check.call(snapshot == retained and _model_state(model) == state, "Inspection and previews preserve their input snapshot, all gameplay state, three RNG streams, UID allocation and Undo history.")
	check.call(Inspect.describe_hand(snapshot, -99).is_empty() and Inspect.describe_cell(snapshot, -1).is_empty() and Inspect.describe_cell(snapshot, 16).is_empty(), "Missing cards and out-of-range cells return no stale inspection content.")
	check.call(Inspect.describe_hand({}, 0).is_empty() and Inspect.describe_tool({}, "split").is_empty() and not Inspect.placement({}, 0, "straight").allowed and not Inspect.edit_action({}, 0, "rotate").allowed, "Unavailable startup content is safe for all inspector and preview helpers.")

func _live_values(check: Callable) -> void:
	var model := Combat.new(Loader.load_setup().setup)
	var snapshot := model.snapshot()
	# Detached display fixtures intentionally change the supplied definitions to
	# prove that inspection has no copied card or balance constants.
	snapshot.hand = [{"id": "spark", "uid": 1001}, {"id": "shield", "uid": 1002}, {"id": "focus", "uid": 1003}, {"id": "conjure", "uid": 1004}, {"id": "free_spark", "uid": 1005}]
	snapshot.catalog.spark.name = "Live Ember"
	snapshot.catalog.spark.value = 17
	snapshot.catalog.spark.cost = 9
	snapshot.catalog.shield.value = 13
	snapshot.catalog.focus.value = 7
	snapshot.catalog.focus.cost = 4
	snapshot.catalog.conjure.value = 3
	snapshot.catalog.free_spark.name = "Fleeting Ember"
	var rune := Inspect.describe_hand(snapshot, 1001)
	check.call(rune.title == "Live Ember" and rune.text.contains("17 damage") and rune.text.contains("Energy: 9") and rune.text.contains("paid once on a valid Cast"), "Hand rune inspection displays supplied live name, value, cost and casting payment time.")
	check.call(rune.text.contains("input West; output East") and rune.text.contains("Permanent") and rune.text.contains("even if disconnected"), "Hand rune inspection explains unrotated ports, permanent ownership and full-reset cleanup.")
	check.call(Inspect.describe_hand(snapshot, 1002).text.contains("13 shield"), "Shield inspection reads its live effect value.")
	var focus := Inspect.describe_hand(snapshot, 1003)
	check.call(focus.text.contains("7 cards") and focus.text.contains("Energy: 4") and focus.text.contains("paid immediately") and focus.text.contains("Ports: none") and focus.text.contains("clears Undo"), "Technique inspection describes draw value, immediate payment, no board ports and its Undo boundary.")
	var conjure := Inspect.describe_hand(snapshot, 1004)
	check.call(conjure.text.contains("3 temporary Fleeting Ember") and conjure.text.contains("Inspection does not activate"), "Conjure inspection reads its live count and generated rune name without activating it.")
	check.call(Inspect.describe_hand(snapshot, 1005).text.contains("Temporary") and Inspect.describe_hand(snapshot, 1005).text.contains("Unused in hand, it disappears"), "Temporary hand inspection explains its lifetime and absence from permanent piles.")
	snapshot.production.split_cost = 4
	snapshot.production.join_cost = 3
	snapshot.stock.split = 1
	snapshot.stock_totals.split = 5
	check.call(Inspect.describe_tool(snapshot, "split").text.contains("Energy: 4") and Inspect.describe_tool(snapshot, "split").text.contains("1 available / 5 total"), "Connector inspection reads current profile costs and both stock quantities.")
	check.call(Inspect.describe_tool(snapshot, "join").text.contains("Energy: 3"), "Join inspection reads the configured cost rather than assuming zero.")
	snapshot.board[5] = {"kind": "rune", "rune_id": "spark", "uid": 1001, "rotation": 1}
	var installed := Inspect.describe_cell(snapshot, 5)
	check.call(installed.text.contains("17 damage") and installed.text.contains("Energy: 9") and installed.text.contains("input North; output South"), "Installed rune inspection uses the current piece rotation and current card definition.")
	snapshot.board[6] = {"kind": "corner", "rotation": 1, "reversed": true}
	check.call(Inspect.describe_cell(snapshot, 6).text.contains("input West; output North"), "Wire inspection includes both rotation and Flip when computing actual ports.")
	var hand_before: Array = snapshot.hand.duplicate(true)
	check.call(not Inspect.technique_action(snapshot, 1003).allowed and Inspect.technique_action(snapshot, 1003).reason.contains("Need 4"), "Technique activation availability reads live energy.")
	snapshot.energy = 4
	check.call(Inspect.technique_action(snapshot, 1003).allowed and not Inspect.technique_action(snapshot, 1001).allowed and not Inspect.technique_action(snapshot, 999).allowed and snapshot.hand == hand_before, "Technique availability validates the current UID/type without consuming or changing any card.")

func _profiles_and_power(check: Callable) -> void:
	var legacy := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup).snapshot()
	check.call(Inspect.connector_cost(legacy, "split") == legacy.forecast.cost and Inspect.connector_cost(legacy, "join") == 0, "Legacy connector costs come from the core evaluator when the snapshot omits profile defaults.")
	check.call(Inspect.describe_tool(legacy, "straight").text.contains("unlimited") and Inspect.describe_tool(legacy, "straight").text.contains("Stays installed"), "Historical unlimited wires keep their original stock and cleanup descriptions.")
	check.call(Inspect.describe_cell(legacy, 1).text.contains("leaves a straight wire"), "Historical temporary expiry remains a straight wire.")
	check.call(Inspect.describe_cell(legacy, 2).text.contains("Powered from Begin."), "A powered installed Split is inspectable.")
	check.call(Inspect.describe_cell(legacy, 10).text.contains("Both inputs") and Inspect.describe_cell(legacy, 10).text.contains("ports: input North / East; output South"), "Installed Join inspection explains both inputs and actual output.")
	check.call(Inspect.describe_cell(legacy, 0).text.contains("input none; output East") and Inspect.describe_cell(legacy, 14).text.contains("input North; output none"), "Both endpoint descriptions expose their current directions.")
	legacy.board[7] = {}
	legacy.forecast = Circuit.evaluate(legacy.board, legacy.catalog)
	check.call(Inspect.power_text(legacy, 1).contains("Powered from Begin; the circuit is incomplete"), "An incomplete circuit still reports connected upstream runes as powered.")
	check.call(Inspect.power_text(legacy, 10).contains("Partially connected"), "A Join with one missing powered input is distinguished from a fully powered piece.")
	legacy.board[8] = {"kind": "rune", "rune_id": "shield", "uid": 999, "rotation": 0}
	check.call(Inspect.describe_cell(legacy, 8).text.contains("Disconnected from Begin") and Inspect.describe_cell(legacy, 8).text.contains("remains after Cast/Pass"), "Disconnected permanent runes retain the historical persistent rule.")
	var consumed := Combat.new(Experiments.load_setup("effects", "treatment").setup).snapshot()
	check.call(Inspect.describe_cell(consumed, 1).text.contains("powered rune enters discard") and Inspect.describe_cell(consumed, 1).text.contains("Disconnected runes and Pass keep it installed"), "Consumed experiment inspection keeps its powered-only Cast cleanup and persistent Pass behavior.")
	for variant in ["retained", "empty"]:
		var expiry := Combat.new(Experiments.load_setup("expiry", variant).setup).snapshot()
		check.call(Inspect.describe_cell(expiry, 3).text.contains("leaves a corner wire" if variant == "retained" else "leaving an empty cell"), "Temporary inspection honors the %s experiment expiry geometry." % variant)
	var ports := Combat.new(Experiments.load_setup("ports", "treatment").setup).snapshot()
	check.call(Inspect.describe_cell(ports, 3).text.contains("input West; output South"), "Historical corner effect ports remain visible without imposing production geometry.")
	var split := Combat.new(Experiments.load_setup("split_cost", "treatment").setup).snapshot()
	check.call(Inspect.describe_tool(split, "split").text.contains("Energy: 2"), "Historical experiment Split cost overrides remain visible.")

func _availability(check: Callable) -> void:
	var loaded := Loader.load_setup()
	var model := Combat.new(loaded.setup)
	var snapshot := model.snapshot()
	var endpoint := -1
	var empty := -1
	for index in range(16):
		if snapshot.board[index].get("kind") == "begin":
			endpoint = index
		elif snapshot.board[index].is_empty():
			empty = index
	check.call(Inspect.placement(snapshot, empty, "straight").allowed and not snapshot.forecast.valid, "A legal construction step remains eligible while the production circuit is incomplete.")
	check.call(not Inspect.placement(snapshot, endpoint, "straight").allowed and not Inspect.edit_action(snapshot, endpoint, "erase").allowed and not Inspect.edit_action(snapshot, endpoint, "flip").allowed, "Protected endpoints reject replacement, erase and Flip previews.")
	check.call(Inspect.edit_action(snapshot, endpoint, "rotate").allowed and not Inspect.edit_action(snapshot, empty, "rotate").allowed, "Production endpoints support Rotate but empty cells do not.")
	check.call(not Inspect.edit_action(snapshot, empty, "undo").allowed and not Inspect.edit_action(snapshot, empty, "erase").allowed, "Undo reflects actual history and erase avoids an empty-cell no-op.")
	model.rotate(endpoint)
	check.call(Inspect.edit_action(model.snapshot(), endpoint, "undo").allowed, "A real endpoint rotation immediately makes Undo available.")
	model.undo()
	check.call(not Inspect.edit_action(model.snapshot(), endpoint, "undo").allowed and model.snapshot().board == snapshot.board, "Endpoint Undo restores geometry and the availability boundary.")
	var capacity: int = snapshot.stock.split
	var installed: Array[int] = []
	for index in range(16):
		if model.board[index].is_empty() and installed.size() < capacity:
			model.place_wire(index, "split")
			installed.append(index)
	var exhausted := model.snapshot()
	check.call(exhausted.stock.split == 0 and not Inspect.placement(exhausted, empty, "split").allowed, "Exhausted finite stock prevents another placement and supplies a reason.")
	check.call(Inspect.placement(exhausted, installed[0], "split").allowed, "Replacing an installed connector with its own kind is legal even when no spare stock remains.")
	model.place_wire(installed[0], "erase")
	check.call(Inspect.placement(model.snapshot(), empty, "split").allowed and Inspect.describe_tool(model.snapshot(), "split").text.contains("1 available"), "Erase refunds stock immediately in placement and inspection data.")
	model.undo()
	check.call(not Inspect.placement(model.snapshot(), empty, "split").allowed, "Undo restores the exhausted-stock preview immediately.")
	var legacy := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup).snapshot()
	check.call(not Inspect.edit_action(legacy, 0, "rotate").allowed and Inspect.edit_action(legacy, 3, "flip").allowed and not Inspect.edit_action(legacy, 2, "flip").allowed, "Historical endpoint locks and per-piece Flip permissions remain profile-correct.")
	var blocked := Combat.new(Experiments.load_setup("blocked", "treatment").setup).snapshot()
	check.call(not Inspect.placement(blocked, 6, "straight").allowed and not Inspect.edit_action(blocked, 6, "rotate").allowed and Inspect.describe_cell(blocked, 6).text.contains("protects"), "Historical blocked cells remain uneditable and inspectable.")
	snapshot.state = "victory"
	check.call(not Inspect.placement(snapshot, empty, "straight").allowed and not Inspect.edit_action(snapshot, endpoint, "rotate").allowed and not Inspect.technique_action(snapshot, 0).allowed, "Terminal snapshots reject all availability previews without changing state.")
	# Compare placement predictions against the authoritative operation on fresh
	# deterministic models, including endpoint protection and finite stock.
	var matches := true
	for kind in ["straight", "corner", "split", "join"]:
		for index in range(16):
			var probe := Combat.new(loaded.setup)
			var preview := Inspect.placement(probe.snapshot(), index, kind)
			matches = preview.allowed == probe.place_wire(index, kind) and matches
	check.call(matches, "Connector eligibility agrees with authoritative placement across every cell and connector type.")

func _model_state(model: Combat) -> Dictionary:
	return {"snapshot": model.snapshot(), "rng": model.rng.state, "endpoint_rng": model.endpoint_rng.state,
		"kit_rng": model.kit_rng.state, "history": model.history.duplicate(true), "next_uid": model.next_uid,
		"last_result": model.last_result()}
