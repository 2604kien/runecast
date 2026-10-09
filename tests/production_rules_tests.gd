extends RefCounted

# RC-007 preserves these historical assertions using the explicit legacy fixture.
# Production defaults are covered separately by production_*_tests.gd.

const Rules = preload("res://scripts/core/production_rules.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const ContentTests = preload("res://tests/content_loading_tests.gd")

func run(check: Callable) -> void:
	var loaded := Rules.load_rules()
	check.call(loaded.ok and loaded.errors.is_empty(), "Owner-selected connector kits load through validated production definitions.")
	if not loaded.ok:
		return
	_definition_validation(check, loaded.rules)
	_isolation(check, loaded.rules)
	_sampling(check, loaded.rules)
	_finite_inventory_validation(check)
	_finite_editing(check, loaded.rules)
	_legacy_inventory(check)

func _definition_validation(check: Callable, rules: Dictionary) -> void:
	var ids: Array = []
	var definitions_correct := true
	for kit in rules.kits:
		ids.append(kit.id)
		var total := 0
		for kind in Rules.CONNECTOR_KINDS:
			total += kit.totals[kind]
		definitions_correct = total == 10 and kit.weight == 1 and kit.totals == Rules.KIT_TOTALS[kit.id] and definitions_correct
	check.call(definitions_correct and ids == ["extra_straights", "extra_corners", "extra_branches"] and rules.balance == "provisional", "Production data contains exactly 6/2/1/1, 4/4/1/1 and 4/2/2/2 with equal weights and provisional balance.")
	for document in [null, [], 1, "kits"]:
		var rejected := Rules.validate_rules(document)
		check.call(not rejected.ok and rejected.rules.is_empty() and not rejected.errors.is_empty(), "A non-object production rule document cannot produce partial rules.")
	var cases := [
		["missing version", func(d): d.erase("version")],
		["unsupported version", func(d): d.version = "future"],
		["unknown rule", func(d): d.split_cost = 2],
		["invented balance approval", func(d): d.balance = "validated"],
		["missing kits", func(d): d.erase("kits")],
		["non-array kits", func(d): d.kits = {}],
		["missing kit", func(d): d.kits.pop_back()],
		["extra kit", func(d): d.kits.append(d.kits[0].duplicate(true))],
		["non-object kit", func(d): d.kits[0] = null],
		["unknown kit field", func(d): d.kits[0].reroll = true],
		["missing kit ID", func(d): d.kits[0].erase("id")],
		["unknown kit ID", func(d): d.kits[0].id = "unselected"],
		["non-string kit ID", func(d): d.kits[0].id = 4],
		["duplicate kit ID", func(d): d.kits[1] = d.kits[0].duplicate(true)],
		["missing weight", func(d): d.kits[0].erase("weight")],
		["unequal probability", func(d): d.kits[0].weight = 2],
		["zero probability", func(d): d.kits[0].weight = 0],
		["boolean probability", func(d): d.kits[0].weight = true],
		["string probability", func(d): d.kits[0].weight = "1"],
		["nonfinite probability", func(d): d.kits[0].weight = INF],
		["missing totals", func(d): d.kits[0].erase("totals")],
		["non-object totals", func(d): d.kits[0].totals = []],
		["missing connector", func(d): d.kits[0].totals.erase("straight")],
		["unknown connector", func(d): d.kits[0].totals.portal = 1],
		["unselected ten-piece combination", func(d): d.kits[0].totals = {"straight": 5, "corner": 3, "split": 1, "join": 1}],
		["extra connector", func(d): d.kits[0].totals.straight = 7],
		["negative count", func(d): d.kits[0].totals.straight = -1],
		["fractional count", func(d): d.kits[0].totals.straight = 6.5],
		["boolean count", func(d): d.kits[0].totals.straight = true],
		["string count", func(d): d.kits[0].totals.straight = "6"],
		["nonfinite count", func(d): d.kits[0].totals.straight = NAN]
	]
	for entry in cases:
		var document := rules.duplicate(true)
		entry[1].call(document)
		var retained := var_to_bytes(document)
		var rejected := Rules.validate_rules(document, "kit_fixture")
		check.call(not rejected.ok and rejected.rules.is_empty() and not rejected.errors.is_empty() and str(rejected.errors[0]).begins_with("kit_fixture"), "Invalid %s is rejected with source diagnostics and no partial rules." % entry[0])
		check.call(var_to_bytes(document) == retained, "Rejecting %s does not normalize or repair the source payload." % entry[0])
	var integral := rules.duplicate(true)
	integral.kits[0].weight = 1.0
	integral.kits[0].totals.straight = 6.0
	var normalized := Rules.validate_rules(integral)
	check.call(normalized.ok and normalized.rules.kits[0].weight is int and normalized.rules.kits[0].totals.straight is int and integral.kits[0].totals.straight is float, "Integral JSON numbers normalize into detached integer kit quantities.")
	for path in ["res://tests/fixtures/missing_production_rules.json", "res://tests/fixtures/malformed_content.json"]:
		var rejected := Rules.load_rules(path)
		check.call(not rejected.ok and rejected.rules.is_empty() and str(rejected.errors[0]).begins_with(path), "Unreadable or malformed kit definitions fail with their file path and no fallback supply.")

func _isolation(check: Callable, rules: Dictionary) -> void:
	var source := rules.duplicate(true)
	var retained := source.duplicate(true)
	var validated := Rules.validate_rules(source)
	validated.rules.kits[0].totals.straight = 999
	validated.rules.kits.pop_back()
	check.call(source == retained and Rules.load_rules().rules == rules, "Returned normalized kit definitions cannot mutate source dictionaries or loaded data.")
	var kit_rng := RandomNumberGenerator.new()
	kit_rng.seed = 42
	var selected := Rules.select_kit(rules, kit_rng)
	selected.totals.straight = 999
	selected.id = "changed"
	check.call(rules == retained and Rules.validate_rules(rules).ok, "Selected kit state is detached from the validated definitions.")

func _sampling(check: Callable, rules: Dictionary) -> void:
	var first := RandomNumberGenerator.new()
	var second := RandomNumberGenerator.new()
	var reference := RandomNumberGenerator.new()
	first.seed = 42
	second.seed = 42
	reference.seed = 42
	var card_rng := RandomNumberGenerator.new()
	var endpoint_rng := RandomNumberGenerator.new()
	card_rng.seed = 37
	endpoint_rng.seed = 99
	var card_state := card_rng.state
	var endpoint_state := endpoint_rng.state
	var seen := {}
	var repeated := false
	var previous := ""
	var exact := true
	for draw in range(128):
		var left := Rules.select_kit(rules, first)
		var right := Rules.select_kit(rules, second)
		var index := reference.randi_range(0, 2)
		exact = left == right and left == rules.kits[index] and first.state == second.state and first.state == reference.state and exact
		seen[left.id] = true
		repeated = left.id == previous or repeated
		previous = left.id
	check.call(exact, "The same supplied seed reproduces 128 kit selections with exactly one bounded RNG draw each.")
	check.call(seen.size() == 3 and repeated, "All selected kits occur and consecutive repeated kits remain allowed without novelty rerolls.")
	check.call(card_rng.state == card_state and endpoint_rng.state == endpoint_state, "Sampling kits has no access to or effect on separate card and endpoint random streams.")
	var before := first.state
	var exposed := rules.duplicate(true)
	exposed.kits[0].totals.straight = 1
	Rules.validate_rules(exposed)
	Rules.load_rules()
	check.call(first.state == before, "Reading and rejecting rules does not consume the caller's random stream.")

func _finite_documents(totals: Dictionary) -> Dictionary:
	var documents := ContentTests.documents()
	documents.boards[0].placements = [{"cell": 0, "kind": "begin"}, {"cell": 14, "kind": "end"}]
	documents.loadouts[0].inventory = totals.duplicate(true)
	return documents

func _finite_inventory_validation(check: Callable) -> void:
	var source := _finite_documents(Rules.KIT_TOTALS.extra_straights)
	var retained := source.duplicate(true)
	var loaded := Loader.validate_documents(source)
	check.call(loaded.ok and loaded.setup.inventory == Rules.KIT_TOTALS.extra_straights and source == retained, "Four-type finite inventory validates without mutating content documents.")
	for kind in ["straight", "corner"]:
		var partial := source.duplicate(true)
		partial.loadouts[0].inventory.erase(kind)
		var invalid := Loader.validate_documents(partial)
		check.call(not invalid.ok and invalid.setup.is_empty(), "A partial finite inventory missing %s is rejected before model initialization." % kind)
		for quantity in [-1, 15, 1.5, "6", true, null, INF]:
			var malformed := source.duplicate(true)
			malformed.loadouts[0].inventory[kind] = quantity
			invalid = Loader.validate_documents(malformed)
			check.call(not invalid.ok and invalid.setup.is_empty(), "Malformed finite %s quantity %s cannot initialize a model." % [kind, str(quantity)])
		var overinstalled := source.duplicate(true)
		overinstalled.loadouts[0].inventory[kind] = 0
		overinstalled.boards[0].placements.append({"cell": 4, "kind": kind})
		invalid = Loader.validate_documents(overinstalled)
		check.call(not invalid.ok and invalid.setup.is_empty(), "A starting %s exceeding finite supply is rejected like a starting Split/Join." % kind)
	var zero := source.duplicate(true)
	zero.loadouts[0].inventory = {"straight": 0, "corner": 0, "split": 0, "join": 0}
	loaded = Loader.validate_documents(zero)
	var game := Combat.new(loaded.setup)
	var unavailable := true
	for kind in Rules.CONNECTOR_KINDS:
		unavailable = not game.place_wire(4, kind) and game.stock(kind) == 0 and unavailable
	check.call(loaded.ok and unavailable and game.board[4].is_empty() and game.history.is_empty(), "Explicit zero stock forbids each connector without a hidden unlimited-wire bypass.")
	loaded = Loader.validate_documents(source)
	game = Combat.new(loaded.setup)
	loaded.setup.inventory.straight = 999
	var snapshot := game.snapshot()
	snapshot.stock_totals.corner = 999
	snapshot.stock.straight = 999
	check.call(game.stock_totals == Rules.KIT_TOTALS.extra_straights and game.stock("straight") == 6 and game.stock("corner") == 2, "Finite totals and availability are detached from setup inputs and exported snapshots.")

func _gameplay(snapshot: Dictionary) -> Dictionary:
	var value := snapshot.duplicate(true)
	value.erase("log_text")
	return value

func _finite_editing(check: Callable, rules: Dictionary) -> void:
	var cells: Array = []
	for cell in range(16):
		if cell not in [0, 14]:
			cells.append(cell)
	for kit in rules.kits:
		var loaded := Loader.validate_documents(_finite_documents(kit.totals))
		var game := Combat.new(loaded.setup)
		var initial := game.snapshot()
		check.call(initial.stock == kit.totals and initial.stock_totals == kit.totals, "%s exposes available and total quantities for all four connector types." % kit.id)
		var installed := {}
		var cursor := 0
		var prepared := true
		for kind in Rules.CONNECTOR_KINDS:
			installed[kind] = []
			for count in range(kit.totals[kind]):
				installed[kind].append(cells[cursor])
				prepared = game.place_wire(cells[cursor], kind) and prepared
				cursor += 1
		check.call(prepared and cursor == 10 and game.snapshot().stock.values().all(func(value): return value == 0), "%s permits exactly its ten supplied pieces, including pieces disconnected from Begin." % kit.id)
		for kind in Rules.CONNECTOR_KINDS:
			var before := game.snapshot()
			var history := game.history.duplicate(true)
			var card_rng := game.rng.state
			var endpoint_rng := game.endpoint_rng.state
			var rejected := game.execute("place_wire", {"index": cells[cursor], "kind": kind})
			check.call(not rejected.accepted and rejected.events.is_empty() and _gameplay(game.snapshot()) == _gameplay(before) and game.history == history and game.rng.state == card_rng and game.endpoint_rng.state == endpoint_rng, "%s exhausted %s rejects placement without changing board, hand, inventory, history or random streams." % [kit.id, kind])
			var cell: int = installed[kind][0]
			before = game.snapshot()
			var same_kind := game.place_wire(cell, kind)
			var same_stock: bool = game.snapshot().stock == before.stock
			var undone := game.execute("undo")
			check.call(same_kind and same_stock and undone.accepted and game.snapshot() == before, "%s replacing an installed %s with its own type requires no extra stock and Undo is exact." % [kit.id, kind])
			var erased := game.place_wire(cell, "erase")
			var returned: bool = game.stock(kind) == 1
			undone = game.execute("undo")
			check.call(erased and returned and undone.accepted and game.snapshot() == before, "%s erasing %s returns one piece and Undo reserves it again." % [kit.id, kind])
			var rotated := game.rotate(cell)
			var stable: bool = game.snapshot().stock == before.stock
			undone = game.execute("undo")
			check.call(rotated and stable and undone.accepted and game.snapshot() == before, "%s rotating %s spends no supply and Undo restores its board state." % [kit.id, kind])
			if kind in ["straight", "corner"]:
				var flipped := game.execute("flip", {"index": cell})
				stable = game.snapshot().stock == before.stock
				undone = game.execute("undo")
				check.call(flipped.accepted and stable and undone.accepted and game.snapshot() == before, "%s flipping %s spends no supply and Undo restores its direction." % [kit.id, kind])
		# Installing a card refunds the displaced connector. Replacing the card
		# then returns its permanent instance to hand and reserves the wire again.
		for kind in Rules.CONNECTOR_KINDS:
			var cell: int = installed[kind][0]
			var uid: int = game.hand[0].uid
			var before := game.snapshot()
			var placed := game.place_rune(cell, uid)
			var refunded: bool = game.stock(kind) == 1 and game.board[cell].uid == uid and not game.hand.any(func(card): return card.uid == uid)
			var replaced := game.place_wire(cell, kind)
			var conserved: bool = game.stock(kind) == 0 and game.hand.filter(func(card): return card.uid == uid).size() == 1
			var undone_twice: bool = game.execute("undo").accepted and game.execute("undo").accepted
			check.call(placed and refunded and replaced and conserved and undone_twice and game.snapshot() == before, "%s rune/%s replacement and two Undo steps conserve the permanent UID and reserve/refund exactly one connector." % [kit.id, kind])
		var corner_cell: int = installed.corner[0]
		var straight_cell: int = installed.straight[0]
		game.place_wire(corner_cell, "erase")
		var before := game.snapshot()
		var replaced := game.place_wire(straight_cell, "corner")
		var exchanged: bool = game.stock("straight") == 1 and game.stock("corner") == 0
		var undone := game.execute("undo")
		check.call(replaced and exchanged and undone.accepted and game.snapshot() == before, "%s swapping connector types returns the old type, reserves the new one and supports exact Undo." % kit.id)

func _legacy_inventory(check: Callable) -> void:
	var loaded := Loader.load_setup(Loader.LEGACY_ENCOUNTER)
	var game := Combat.new(loaded.setup)
	var snapshot := game.snapshot()
	check.call(snapshot.stock.keys() == ["split", "join"] and snapshot.stock_totals == {"split": 1, "join": 1}, "Legacy setups retain their historical two-type inventory and snapshot shape.")
	var accepted := true
	for cell in [4, 5, 8, 9, 12, 13, 15]:
		accepted = game.place_wire(cell, "straight") and accepted
	check.call(accepted, "Explicit legacy two-type fixtures preserve their historical unlimited basic-wire editing semantics.")
