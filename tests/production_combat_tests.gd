extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")

func run(check: Callable) -> void:
	var loaded := Loader.load_setup()
	check.call(loaded.ok and loaded.setup.has("production"), "Normal loading selects validated RC-007 production rules.")
	if not loaded.ok or not loaded.setup.has("production"):
		return
	_entry_and_rotation(check, loaded.setup)
	_all_production_pairs(check, loaded.setup)
	_cleanup_and_hits(check, loaded.setup)
	_powered_temporary_cleanup(check, loaded.setup)
	_recycling_and_rejections(check, loaded.setup)
	_rng_and_isolation(check, loaded.setup)
	_transition(check, loaded.setup)
	_controller_guards(check, loaded.setup)

func _controlled(source: Dictionary, cards: Array = ["spark", "shield", "conjure", "conjure"]) -> Dictionary:
	# Detached edge-case setup: draw the entire tiny owned pool normally, so each
	# cleanup case can name its supplied cards without changing production data.
	var setup := source.duplicate(true)
	setup.erase("next_encounter")
	setup.owned_cards = cards.duplicate()
	setup.opening_hand = []
	setup.opening_draw = cards.size()
	setup.encounter.player_health = 1000
	setup.encounter.player_max_health = 1000
	setup.encounter.max_health = 1000
	setup.encounter.intents = [8]
	setup.encounter.energy_per_turn = 6
	return setup

func _uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id:
			return card.uid
	return -1

func _permanents(game: Combat) -> Array:
	var cards: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].get("temporary", false):
			cards.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].get("temporary", false):
			cards.append({"id": piece.rune_id, "uid": piece.uid})
	cards.sort_custom(func(first, second): return first.uid < second.uid)
	return cards

func _only_endpoints(game: Combat) -> bool:
	return game.board.size() == 16 and game.board.filter(func(piece): return piece.get("kind") == "begin").size() == 1 and game.board.filter(func(piece): return piece.get("kind") == "end").size() == 1 and game.board.filter(func(piece): return piece.is_empty()).size() == 14

func _endpoints(game: Combat) -> Dictionary:
	var endpoints := {}
	for cell in range(game.board.size()):
		if game.board[cell].get("kind") in ["begin", "end"]:
			endpoints[game.board[cell].kind] = {"cell": cell, "rotation": game.board[cell].rotation}
	return endpoints

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _gameplay(game: Combat) -> Dictionary:
	var value := game.snapshot()
	value.erase("log_text")
	value.random_states = [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
	value.history = game.history.duplicate(true)
	value.next_uid = game.next_uid
	return value

func _events_identified(result: Dictionary) -> bool:
	for index in range(result.events.size()):
		var event: Dictionary = result.events[index]
		if event.sequence != index or event.action_id != result.action_id or event.encounter_id != result.encounter_id:
			return false
	return true

func _pair(game: Combat, rune_id: String = "spark") -> bool:
	# The explicit witness fits every kit. It uses one physical rune before
	# Split, so output doubles while its UID and cost still occur only once.
	game.board = Circuit.empty_board()
	var prepared := game.place_rune(1, _uid(game, rune_id))
	for placement in [[2, "split", 0], [3, "corner", 0], [6, "straight", 1], [7, "straight", 1], [10, "join", 0], [11, "corner", 1]]:
		prepared = game.place_wire(placement[0], placement[1]) and prepared
		for quarter in range(placement[2]):
			prepared = game.rotate(placement[0]) and prepared
	return prepared

func _direct(game: Combat) -> void:
	game.board = []
	for cell in range(16):
		game.board.append({})
	game.board[0] = {"kind": "begin", "rotation": 0}
	game.board[1] = {"kind": "end", "rotation": 3}

func _entry_and_rotation(check: Callable, source: Dictionary) -> void:
	var game := Combat.new(source)
	var initial := game.snapshot()
	check.call(_only_endpoints(game) and game.hand.size() == 3 and game.energy == 3 and game.hand.all(func(card): return not game.catalog[card.id].temporary), "Production turn one has fourteen empty cells, a normal three-card permanent hand and three energy.")
	check.call(initial.production.version == "rc007_production_v1" and not initial.has("experiment") and initial.kit.totals == initial.stock and initial.stock == initial.stock_totals and game.last_result().is_empty(), "Opening production metadata and full selected kit are detached setup state without an action batch.")
	var expected := RandomNumberGenerator.new()
	expected.seed = int(source.encounter.seed)
	var expected_cards: Array = []
	for index in range(source.owned_cards.size()):
		expected_cards.append({"id": source.owned_cards[index], "uid": index})
	for index in range(expected_cards.size() - 1, 0, -1):
		var other := expected.randi_range(0, index)
		var previous: Dictionary = expected_cards[index]
		expected_cards[index] = expected_cards[other]
		expected_cards[other] = previous
	var expected_hand: Array = []
	for count in range(3):
		expected_hand.append(expected_cards.pop_back())
	check.call(game.hand == expected_hand and game.draw_pile == expected_cards and game.rng.state == expected.state, "Production first hand is the configured seeded normal shuffle/draw with no curated or useful-hand substitution.")
	var endpoints := _endpoints(game)
	for kind in ["begin", "end"]:
		var cell: int = endpoints[kind].cell
		var before := _gameplay(game)
		var accepted := game.rotate(cell)
		check.call(accepted and game.board[cell].rotation == (endpoints[kind].rotation + 1) % 4 and game.snapshot().stock == initial.stock, "Production %s accepts player Rotate without changing supply." % kind)
		check.call(game.execute("undo").accepted and _gameplay(game) == before, "Production %s rotation is exactly undoable without consuming randomness." % kind)
		var protected := true
		for connector in ["straight", "corner", "split", "join", "erase"]:
			protected = not game.place_wire(cell, connector) and protected
		protected = not game.place_rune(cell, game.hand[0].uid) and not game.execute("flip", {"index": cell}).accepted and protected
		check.call(protected and _gameplay(game) == before, "Production %s cannot be erased, overwritten by cards/connectors or flipped." % kind)
	game = Combat.new(_controlled(source))
	var previous := _endpoints(game)
	var result := game.execute("pass")
	var current := _endpoints(game)
	check.call(result.accepted and _only_endpoints(game) and current.begin.cell != previous.begin.cell and current.end.cell != previous.end.cell and game.snapshot().stock == game.snapshot().kit.totals, "Every later playable turn moves both endpoints and replaces stock with one full kit.")
	check.call(_types(result) == ["passed", "retaliation", "turn_cleanup", "endpoints_changed", "kit_changed", "turn_started", "reshuffled", "card_drawn", "card_drawn", "card_drawn"] and _events_identified(result), "Empty-board Pass records retaliation, cleanup, endpoint/kit changes, energy refresh and ordinary recycling/draw in mutation order.")

func _cleanup_and_hits(check: Callable, source: Dictionary) -> void:
	for command in ["cast", "pass"]:
		var game := Combat.new(_controlled(source))
		var owned := _permanents(game)
		var prepared := _pair(game)
		var spark_uid: int = game.board[1].uid
		prepared = game.place_rune(8, _uid(game, "shield")) and game.play_technique(_uid(game, "conjure")) and game.place_rune(5, _uid(game, "free_spark")) and game.play_technique(_uid(game, "conjure")) and prepared
		game.rotate(5)
		check.call(prepared and game.forecast().valid and game.forecast().damage == 12 and game.forecast().cost == 3, "Cleanup witness has amplified Spark, disconnected permanent/temporary and unused hand temporary; physical Spark/Split costs are 2+1.")
		var result := game.execute(command)
		var consumed: Array = result.events.filter(func(event): return event.type == "effect_consumed")
		var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
		var cleanup: Dictionary = result.events.filter(func(event): return event.type == "turn_cleanup")[0]
		var cleared: Array = result.events.filter(func(event): return event.type in ["effect_consumed", "temporary_expired", "board_piece_cleared"])
		check.call(result.accepted and consumed.size() == 2 and consumed.filter(func(event): return event.card.uid == spark_uid).size() == 1 and consumed.all(func(event): return event.to == "discard" and event.after == {}), "%s discards both powered/disconnected permanent UIDs exactly once despite Split amplification." % command)
		check.call(expired.size() == 1 and expired[0].cell == 5 and cleanup.expired.size() == 1 and cleanup.undo_cleared == 1, "%s deletes disconnected board and unused hand temporaries and clears the remaining Undo step." % command)
		check.call(cleared.map(func(event): return event.cell) == [1, 2, 3, 5, 6, 7, 8, 10, 11] and _permanents(game) == owned and _only_endpoints(game) and game.history.is_empty(), "%s clears every non-endpoint piece in ascending cell order and conserves permanent ownership through immediate draw." % command)
		var kinds := _types(result)
		check.call(kinds.find("retaliation") < kinds.find("effect_consumed") and kinds.find("turn_cleanup") < kinds.find("endpoints_changed") and kinds.find("endpoints_changed") < kinds.find("kit_changed") and kinds.find("kit_changed") < kinds.find("turn_started") and _events_identified(result), "%s events preserve complete cleanup and next-turn mutation ordering and action identities." % command)
		check.call(game.snapshot().stock == game.snapshot().kit.totals and game.stock_totals.values().reduce(func(total, count): return total + count, 0) == 10, "%s new-turn stock replaces the old kit without banking spent or unused pieces." % command)
		if command == "cast":
			var damages: Array = result.events.filter(func(event): return event.type == "damage")
			check.call(damages.size() == 1 and damages[0].amount == 12 and damages[0].applied == 12 and result.events[0].energy_before - result.events[0].energy_after == 3, "Aggregate amplified damage emits once and charges each powered physical piece once.")
		else:
			check.call(not kinds.has("cast") and not kinds.has("damage") and not kinds.has("shield"), "Pass creates no synthetic spell payment, damage or shielding.")
	var game := Combat.new(_controlled(source))
	check.call(_pair(game, "shield") and game.forecast().shield == 10 and game.forecast().cost == 2, "Straight Shield before Split doubles protection while paying Shield1 and Split1; Join remains zero.")
	var result := game.execute("cast")
	check.call(result.events[1].type == "damage" and result.events[1].amount == 0 and result.events[1].applied == 0 and result.events[2].type == "shield" and result.events[2].amount == 10 and result.events[3].type == "retaliation" and result.events[3].blocked == 8 and result.events[3].applied == 0, "Zero aggregate damage is emitted before shield and a fully blocked surviving-enemy retaliation.")
	game = Combat.new(_controlled(source))
	_direct(game)
	result = game.execute("cast")
	check.call(result.accepted and result.events[0].spell.cost == 0 and result.events[1].amount == 0 and result.events[1].applied == 0, "Direct adjacent endpoints can cast zero damage/cost without an effect-rune or minimum-length requirement.")
	for boundary in [["victory", "cast"], ["defeat", "cast"], ["defeat", "pass"]]:
		var outcome: String = boundary[0]
		var terminal_command: String = boundary[1]
		game = Combat.new(_controlled(source))
		_pair(game)
		if outcome == "victory": game.enemy_hp = 7
		else: game.player_hp = 1
		var endpoints := _endpoints(game)
		var kit: Dictionary = game.snapshot().kit
		var rngs := [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
		var owned := _permanents(game)
		result = game.execute(terminal_command)
		check.call(result.accepted and game.state == outcome and _only_endpoints(game) and _endpoints(game) == endpoints and game.hand.is_empty() and _permanents(game) == owned and game.snapshot().kit == kit and [game.rng.state, game.endpoint_rng.state, game.kit_rng.state] == rngs, "Terminal %s cleans all pieces and cards without unused geometry, kit, hand or random draws." % outcome)
		check.call(_types(result).back() == "battle_ended" and not _types(result).has("turn_started") and not _types(result).has("kit_changed") and not _types(result).has("card_drawn"), "Terminal %s reports cleanup then battle end with no new-turn events." % outcome)
		if outcome == "victory":
			check.call(result.events[1].amount == 12 and result.events[1].applied == 7 and not _types(result).has("retaliation") and not _types(result).has("shield"), "Lethal aggregate overkill retains requested12/applied7 and suppresses shield and retaliation.")
		else:
			var retaliation: Dictionary = result.events.filter(func(event): return event.type == "retaliation")[0]
			check.call(retaliation.amount == 8 and retaliation.applied == 1, "Lethal %s retaliation keeps requested damage separate from clamped player HP loss." % terminal_command)
		var terminal := _gameplay(game)
		check.call(not game.execute("cast").accepted and not game.execute("pass").accepted and not game.rotate(endpoints.begin.cell) and _gameplay(game) == terminal, "Repeated terminal %s commands cannot pay, clear, draw, reroll or edit." % outcome)

func _powered_temporary_cleanup(check: Callable, source: Dictionary) -> void:
	for command in ["cast", "pass"]:
		var game := Combat.new(_controlled(source, ["spark", "shield", "conjure", "conjure", "conjure"]))
		var owned := _permanents(game)
		var prepared := game.play_technique(_uid(game, "conjure")) and _pair(game, "free_spark")
		var temporary_uid: int = game.board[1].uid
		prepared = game.place_rune(8, _uid(game, "spark")) and game.place_rune(9, _uid(game, "shield")) and game.play_technique(_uid(game, "conjure")) and game.place_rune(5, _uid(game, "free_spark")) and game.play_technique(_uid(game, "conjure")) and prepared
		var result := game.execute(command)
		var expiry: Array = result.events.filter(func(event): return event.type == "temporary_expired")
		check.call(prepared and result.accepted and expiry.size() == 2 and expiry.map(func(event): return event.cell) == [1, 5] and expiry[0].before.uid == temporary_uid and expiry.all(func(event): return event.after == {}), "%s deletes powered amplified and disconnected temporary physical instances once each in cell order without replacement connectors." % command)
		check.call(_permanents(game) == owned and result.events.filter(func(event): return event.type == "effect_consumed").size() == 2 and (game.hand + game.draw_pile + game.discard_pile).all(func(card): return not game.catalog[card.id].temporary) and _only_endpoints(game), "%s also discards disconnected permanents and excludes every temporary from the next hand/piles." % command)
		check.call((command == "pass" and not _types(result).has("cast")) or (command == "cast" and result.events[0].spell.damage == 12 and result.events[0].spell.cost == 1 and result.events[0].energy_before - result.events[0].energy_after == 1), "%s preserves zero-cost temporaries and charges the physical Split only for Cast." % command)

func _all_production_pairs(check: Callable, source: Dictionary) -> void:
	var all_rotated := true
	var all_editable := true
	var all_direct := true
	var adjacent := 0
	for begin in range(16):
		for end in range(16):
			if begin == end:
				continue
			var game := Combat.new(_controlled(source))
			game.board = []
			for cell in range(16):
				game.board.append({})
			game.board[begin] = {"kind": "begin", "rotation": 0}
			game.board[end] = {"kind": "end", "rotation": 0}
			var rngs := [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
			for endpoint in [begin, end]:
				for rotation in range(4):
					all_rotated = game.rotate(endpoint) and all_rotated
				for rotation in range(4):
					all_rotated = game.execute("undo").accepted and all_rotated
			all_rotated = [game.rng.state, game.endpoint_rng.state, game.kit_rng.state] == rngs and all_rotated
			for cell in [0, 14]:
				if cell not in [begin, end]:
					all_editable = game.place_wire(cell, "straight") and game.execute("undo").accepted and all_editable
			for direction in range(4):
				if Circuit.neighbor(begin, direction) == end:
					adjacent += 1
					game.board[begin].rotation = (direction + 3) % 4
					game.board[end].rotation = (direction + 2) % 4
					var spell := game.forecast()
					all_direct = spell.valid and spell.damage == 0 and spell.cost == 0 and all_direct
	check.call(all_rotated and all_editable, "All 240 production endpoint pairs accept four directions and Undo, including off-board ports; vacated historical cells0/14 remain editable without RNG consumption.")
	check.call(all_direct and adjacent == 48, "All 48 directed neighboring production endpoint pairs support direct zero-effect connectivity when rotated to face each other.")

func _recycling_and_rejections(check: Callable, source: Dictionary) -> void:
	var single := _controlled(source, ["spark"])
	single.encounter.draw_per_turn = 3
	var game := Combat.new(single)
	var uid: int = game.hand[0].uid
	_pair(game)
	var result := game.execute("cast")
	check.call(result.accepted and game.hand == [{"id": "spark", "uid": uid}] and game.draw_pile.is_empty() and game.discard_pile.is_empty(), "A sole installed permanent may immediately recycle into the identical next hand; draws stop when both piles empty.")
	check.call(_types(result).count("reshuffled") == 1 and _types(result).count("card_drawn") == 1, "Empty-pile recycling emits only actual shuffle/draw mutations without manufactured cards.")
	game = Combat.new(_controlled(source, []))
	result = game.execute("pass")
	check.call(result.accepted and game.hand.is_empty() and not _types(result).has("reshuffled") and not _types(result).has("card_drawn") and _only_endpoints(game), "An empty permanent collection still advances with endpoints/full kit and no invented hand.")
	game = Combat.new(_controlled(source))
	game.board = Circuit.empty_board()
	game.rotate(0)
	var before := _gameplay(game)
	result = game.execute("cast")
	check.call(not result.accepted and result.events.is_empty() and _gameplay(game) == before, "Invalid Cast preserves all resources, rotations, history, kit and three random streams.")
	_pair(game)
	game.energy = 2
	before = _gameplay(game)
	result = game.execute("cast")
	check.call(not result.accepted and result.events.is_empty() and _gameplay(game) == before, "Unaffordable Cast rejects before spending, clearing, moving endpoints or drawing a kit/cards.")

func _rng_and_isolation(check: Callable, source: Dictionary) -> void:
	var setup := _controlled(source)
	var first := Combat.new(setup)
	var second := Combat.new(setup)
	var exact := first.snapshot() == second.snapshot()
	var repeated := false
	var kit_ids := {}
	var previous_kit: String = first.snapshot().kit.id
	for index in range(30):
		var left := first.execute("pass")
		var right := second.execute("pass")
		exact = left == right and _gameplay(first) == _gameplay(second) and exact
		var kit_id: String = first.snapshot().kit.id
		kit_ids[kit_id] = true
		repeated = kit_id == previous_kit or repeated
		previous_kit = kit_id
	check.call(exact and repeated and kit_ids.size() == 3, "Fresh identical setup/commands reproduce thirty turns across all three kits, including allowed consecutive kit repeats.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	var endpoint_state := first.endpoint_rng.state
	var kit_state := first.kit_rng.state
	first._draw(10)
	first.rng.randi()
	var left := first.execute("pass")
	var right := second.execute("pass")
	check.call(endpoint_state != first.endpoint_rng.state and kit_state != first.kit_rng.state and _endpoints(first) == _endpoints(second) and first.snapshot().kit == second.snapshot().kit and first.endpoint_rng.state == second.endpoint_rng.state and first.kit_rng.state == second.kit_rng.state, "Extra card-stream work cannot change the next endpoint pair or kit.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	first.kit_rng.randi()
	first.execute("pass")
	second.execute("pass")
	check.call(first.hand == second.hand and first.draw_pile == second.draw_pile and first.rng.state == second.rng.state and _endpoints(first) == _endpoints(second) and first.endpoint_rng.state == second.endpoint_rng.state, "Extra kit-stream work cannot perturb card draws or endpoint selection.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	first.endpoint_rng.randi()
	first.execute("pass")
	second.execute("pass")
	check.call(first.hand == second.hand and first.draw_pile == second.draw_pile and first.rng.state == second.rng.state and first.snapshot().kit == second.snapshot().kit and first.kit_rng.state == second.kit_rng.state, "Extra endpoint-stream work cannot perturb card draws or kit selection.")
	first = Combat.new(setup)
	second = Combat.new(setup)
	for count in range(4):
		first.rotate(_endpoints(first).begin.cell)
	for count in range(4):
		first.execute("undo")
	first.snapshot()
	first.forecast()
	var restored: bool = _gameplay(first) == _gameplay(second)
	left = first.execute("pass")
	right = second.execute("pass")
	check.call(restored and left.after == right.after and _gameplay(first) == _gameplay(second) and left.action_id > right.action_id, "Endpoint edits/Undo, snapshots and forecasting cannot alter the later random sequence; accepted edit identities remain monotonic.")
	var expected_endpoint := RandomNumberGenerator.new()
	var expected_kit := RandomNumberGenerator.new()
	expected_endpoint.state = first.endpoint_rng.state
	expected_kit.state = first.kit_rng.state
	expected_endpoint.randi_range(0, 239)
	expected_endpoint.randi_range(0, 3)
	expected_endpoint.randi_range(0, 3)
	var chosen := Rules.select_kit(setup.production.kits, expected_kit)
	first.reset()
	check.call(first.endpoint_rng.state == expected_endpoint.state and first.kit_rng.state == expected_kit.state and first.snapshot().kit == chosen and _only_endpoints(first), "Ordinary Restart continues endpoint/kit streams and samples from the full first-turn domain without reseeding.")
	var retained := source.duplicate(true)
	first = Combat.new(source)
	var snapshot := first.snapshot()
	snapshot.production.kits.kits.clear()
	snapshot.kit.totals.straight = 999
	source.production.endpoint_rotation = "mutated"
	check.call(first.snapshot().production == retained.production and first.snapshot().kit.totals.straight < 999, "Production options and selected kit snapshot/input collections are detached from the live model.")
	source.production = retained.production
	first = Combat.new(setup)
	var result := first.execute("pass")
	var before := _gameplay(first)
	var played := [0]
	for index in range(2):
		Immediate.new().present(result, func(): played[0] += 1)
	result.after.kit.totals.corner = 999
	result.events.clear()
	check.call(played[0] == 2 and _gameplay(first) == before and not first.last_result().events.is_empty(), "Presentation replay and consumer mutation cannot reapply a kit/reset or change retained outcomes.")

func _with_successor(source: Dictionary) -> Dictionary:
	var setup := _controlled(source)
	var target := setup.duplicate(true)
	target.owned_cards.reverse() # Compatible multiset order cannot reassign UIDs.
	target.encounter.id = "rc007_transition_target"
	target.encounter.title = "RC-007 TRANSITION QA"
	target.encounter.max_health = 45
	target.encounter.intents = [3, 7]
	target.encounter.energy_per_turn = 4
	target.encounter.draw_per_turn = 2
	target.opening_draw = 2
	setup.next_encounter = target
	return setup

func _transition(check: Callable, source: Dictionary) -> void:
	var setup := _with_successor(source)
	check.call(Loader.validate_transition(setup, setup.next_encounter).ok, "A compatible explicit production successor validates before model transition.")
	var game := Combat.new(setup)
	var before := _gameplay(game)
	check.call(not game.execute("next_encounter").accepted and _gameplay(game) == before, "Premature production encounter entry is rejected without consuming any stream.")
	_pair(game)
	game.player_hp = 17
	game.enemy_hp = 1
	game.execute("cast")
	var owned := _permanents(game)
	game.discard_pile.reverse() # Transition must reconcile by UID, not zone order.
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.state = game.rng.state
	var expected_cards := owned.duplicate(true)
	for index in range(expected_cards.size() - 1, 0, -1):
		var other := expected_rng.randi_range(0, index)
		var previous: Dictionary = expected_cards[index]
		expected_cards[index] = expected_cards[other]
		expected_cards[other] = previous
	var expected_hand := [expected_cards.pop_back(), expected_cards.pop_back()]
	var generation: int = game.snapshot().encounter_id
	var previous_action: int = game.last_result().action_id
	before = _gameplay(game)
	check.call(game.snapshot().can_advance and not game.execute("next_encounter", {"setup": setup.next_encounter}).accepted and _gameplay(game) == before, "Victory enables only the configured successor; caller override arguments cannot replace it.")
	var result := game.execute("next_encounter")
	check.call(result.accepted and game.player_hp == 17 and game.encounter.player_max_health == 1000 and game.enemy_hp == 45 and game.energy == 4 and game.turn == 1 and game.hand == expected_hand and game.draw_pile == expected_cards and game.rng.state == expected_rng.state, "Encounter entry carries current/max HP without healing, shuffles UID-ordered instances with continuing RNG, and uses next enemy/energy/draw values.")
	check.call(_permanents(game) == owned and _only_endpoints(game) and game.history.is_empty() and game.snapshot().stock == game.snapshot().kit.totals and game.snapshot().encounter_number == 2 and not game.snapshot().can_advance, "The successor starts endpoints-only with a fresh full kit and every original permanent instance exactly once.")
	check.call(_types(result) == ["encounter_transition", "card_drawn", "card_drawn"] and result.encounter_id == generation + 1 and result.action_id > previous_action and _events_identified(result) and result.events[0].permanents == owned and result.events[0].energy_after == 4, "Transition commits one new presentation generation and describes reconciled ownership/setup before actual draw events.")
	before = _gameplay(game)
	check.call(not game.execute("next_encounter").accepted and _gameplay(game) == before, "Repeated production transition cannot duplicate reconciliation or reroll the successor.")
	for fault in ["catalog", "ownership", "duplicate_uid", "changed_uid"]:
		game = Combat.new(setup)
		_pair(game)
		game.enemy_hp = 1
		game.execute("cast")
		if fault == "catalog": game._setup.next_encounter.catalog.spark.value = 999
		elif fault == "ownership": game._setup.next_encounter.owned_cards.append("spark")
		elif fault == "duplicate_uid": game.discard_pile.append(game.discard_pile[0].duplicate(true))
		else: game.discard_pile[0].uid = 999
		before = _gameplay(game)
		result = game.execute("next_encounter")
		check.call(not result.accepted and result.events.is_empty() and _gameplay(game) == before, "Transition rejects %s before reconciliation, health changes or RNG consumption." % fault)
	game = Combat.new(setup)
	game.player_hp = 1
	game.execute("pass")
	before = _gameplay(game)
	check.call(not game.execute("next_encounter").accepted and _gameplay(game) == before, "Defeat cannot enter a configured successor.")
	var fixture := Loader.load_setup("res://data/production_transition_encounter.json")
	check.call(fixture.ok and fixture.setup.has("next_encounter") and fixture.setup.next_encounter.encounter.id == "rc007_entry_probe_next", "The shipped encounter-entry fixture resolves its compatible bounded successor through normal content loading.")
	if fixture.ok:
		game = Combat.new(fixture.setup)
		# Bring remaining cards into the fixture hand for a deterministic combat
		# boundary probe; the separate opening tests verify normal three-card draw.
		game._draw(8)
		var fixture_prepared := _pair(game)
		game.enemy_hp = 12
		game.player_hp = 17
		var fixture_owned := _permanents(game)
		var won := game.execute("cast")
		var entered := game.execute("next_encounter")
		check.call(fixture_prepared and won.accepted and entered.accepted and game.encounter.id == "rc007_entry_probe_next" and game.player_hp == 17 and game.encounter.player_max_health == 30 and game.energy == 4 and game.hand.size() == 2 and _permanents(game) == fixture_owned and _only_endpoints(game), "Shipped fixture Cast/victory/entry uses the successor's four energy/two draws while carrying17/30 HP and every permanent UID.")

func _controller_guards(check: Callable, source: Dictionary) -> void:
	var game := Combat.new(_with_successor(source))
	_pair(game)
	game.enemy_hp = 1
	var delayed := Delayed.new()
	var controller := Controller.new(game, delayed)
	check.call(controller.command("cast") and controller.is_busy() and game.state == "victory", "Production controller commits lethal cleanup while presentation retains its input lock.")
	var before := _gameplay(game)
	check.call(not controller.command("next_encounter") and not controller.command("pass") and _gameplay(game) == before, "Busy duplicate turn/transition commands cannot mutate production state or random streams.")
	delayed.complete()
	check.call(controller.command("next_encounter") and controller.is_busy() and game.snapshot().encounter_number == 2, "A completed victory presentation permits exactly one authoritative successor transition.")
	before = _gameplay(game)
	check.call(not controller.command("next_encounter") and _gameplay(game) == before, "A duplicate transition callback cannot reconcile during presentation.")
	controller.restart()
	var newer := Delayed.new()
	controller.set_presenter(newer)
	controller.command("pass")
	delayed.complete()
	check.call(controller.is_busy(), "Stale pre-Restart completion cannot unlock the newer production turn.")
	newer.complete()
	check.call(not controller.is_busy(), "The active presentation completion alone unlocks production input.")
	controller.dispose()
