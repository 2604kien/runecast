extends RefCounted

const Circuit = preload("res://scripts/core/circuit.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const OPTIONS := {"version": "rc007_production_v1", "split_cost": 1, "join_cost": 0, "damage_mode": "aggregate"}
const CATALOG := {
	"spark": {"type": "rune", "effect": "damage", "value": 6, "cost": 2},
	"shield": {"type": "rune", "effect": "shield", "value": 5, "cost": 1},
	"free_spark": {"type": "rune", "effect": "damage", "value": 6, "cost": 0}
}

func run(check: Callable) -> void:
	_geometry(check)
	_aggregation(check)
	_invalid_graphs(check)
	_historical_isolation(check)
	_controller_resolution(check)

func _geometry(check: Callable) -> void:
	var splits := [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]]
	var joins := [[0, 1, 2], [1, 2, 3], [0, 2, 3], [0, 1, 3]]
	for turn in range(4):
		check.call(Circuit.logical_ports({"kind": "split", "rotation": turn}) == splits[turn], "Split rotation %d uses its explicit three logical edges, independent of fork tips." % turn)
		check.call(Circuit.logical_ports({"kind": "join", "rotation": turn}) == joins[turn], "Join rotation %d has three logical edges, not the trident's decorative tips." % turn)
	var board := _diamond()
	board[1] = _rune("spark", 2, 100)
	board[9] = _rune("shield", 0, 101)
	for turn in range(4):
		var result := Circuit.evaluate(board, CATALOG, OPTIONS)
		check.call(result.valid and result.damage == 12 and result.shield == 5 and result.cost == 4, "Clockwise board rotation %d preserves the undirected diamond, upstream amplification and one downstream effect." % turn)
		check.call(result.active.size() == 10 and result.reached.size() == 10, "Rotated graph %d visits each of its ten physical pieces exactly once." % turn)
		board = _rotate_board(board)
	var direct := _board({0: _piece("begin", 0), 1: _piece("end", 3)})
	var direct_result := Circuit.evaluate(direct, CATALOG, OPTIONS)
	check.call(direct_result.valid and direct_result.damage == 0 and direct_result.shield == 0 and direct_result.cost == 0 and direct_result.active == [0, 1], "Adjacent compatible Begin/End retain the accepted zero-damage, zero-cost cast.")
	var reversed_route := _board({0: _piece("begin", 0), 1: _rune("spark", 2, 7), 2: _piece("corner", 0), 6: _piece("straight", 3), 10: _piece("straight", 1), 14: _piece("end", 0)})
	var result := Circuit.evaluate(reversed_route, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 6 and result.cost == 2, "Rune and Straight may be entered through their historical output ports.")
	check.call(not Circuit.evaluate(reversed_route, CATALOG).valid, "The same reversed-label route remains invalid under the historical directed contract.")
	reversed_route[2].reversed = true
	reversed_route[6].reversed = true
	check.call(Circuit.evaluate(reversed_route, CATALOG, OPTIONS) == result, "Historical reversed flags cannot alter production geometry, validity, effects or cost.")
	check.call(Circuit.logical_ports({"kind": "rune", "rotation": 0}) == [1, 3] and Circuit.logical_ports({"kind": "corner", "rotation": 0}) == [2, 3], "Production effect and Corner geometry remains straight W/E and corner W/S.")
	var alternate_stem := _board({1: _piece("corner", 3), 2: _piece("split", 0), 3: _piece("corner", 0), 5: _rune("spark", 3, 1), 6: _piece("begin", 3), 7: _piece("straight", 1), 9: _piece("corner", 2), 10: _piece("join", 1), 11: _piece("corner", 1), 14: _piece("end", 0)})
	result = Circuit.evaluate(alternate_stem, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 6 and result.cost == 3, "Split receives from its south historical output and departs west/east; Join receives east/west and departs south without fixed stem polarity.")

func _aggregation(check: Callable) -> void:
	# The diamond is 0-1-2, branches 2-6-10 and 2-3-7-11-10,
	# then 10-9-8. The Join's historical output is an arriving edge;
	# its actual departure is a historical input. Neither label controls flow.
	var board := _diamond()
	board[1] = _rune("spark", 0, 1)
	var result := Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 12 and result.shield == 0 and result.cost == 3, "One Spark before the fork contributes 6 to each branch: 12 damage, physical Spark2 plus Split1 cost.")
	check.call(result.active == [0, 1, 2, 3, 6, 7, 11, 10, 9, 8], "Cell-sorted topological order executes the Join only after both branches and the shared tail once.")
	board[1] = _piece("straight", 0)
	board[9] = _rune("spark", 0, 1)
	result = Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 6 and result.cost == 3, "One shared Spark after the rejoin adds 6 once, despite belonging to two complete simple paths.")
	board[1] = _rune("free_spark", 0, 2)
	board[6] = _rune("shield", 1, 3)
	result = Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 18 and result.shield == 5 and result.cost == 4, "Free Spark upstream doubles to12, one branch Shield adds5, shared downstream Spark adds6; physical cost is 0+1+1+2=4.")
	board[9] = _piece("straight", 0)
	board[1] = _rune("shield", 0, 2)
	board[6] = _piece("straight", 1)
	result = Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 0 and result.shield == 10 and result.cost == 2, "Split amplifies shield as well as damage, with one physical Shield cost.")
	# A closed isolated square and an isolated paid Split are stock/cleanup
	# concerns, not spell contributions or grounds to reject the active route.
	board = _board({0: _piece("begin", 0), 1: _rune("spark", 0, 1), 2: _piece("end", 3), 5: _piece("corner", 3), 6: _piece("corner", 0), 9: _piece("corner", 2), 10: _piece("corner", 1), 12: _piece("split", 0)})
	var before := var_to_bytes(board)
	result = Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(result.valid and result.damage == 6 and result.cost == 2 and result.reached == [0, 1, 2], "Disconnected cycles and open paid pieces are inactive and cost nothing.")
	check.call(var_to_bytes(board) == before, "Evaluation does not rotate, normalize or mutate the board.")
	result.reached.append(15)
	result.active.clear()
	var fresh := Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(fresh.active == [0, 1, 2] and fresh.reached == [0, 1, 2] and var_to_bytes(board) == before, "Returned component and execution lists are detached from the board and future evaluation.")

func _invalid_graphs(check: Callable) -> void:
	var board := _diamond()
	board[7] = {}
	var result := _invalid(check, board, "Open connection at row 1, column 4.", "A missing branch rejects the complete circuit with stable first-open-cell feedback.")
	check.call(result.reached == [0, 1, 2, 3, 6, 8, 9, 10, 11], "Invalid forecasts still expose the complete matched Begin component for read-only inspection.")
	board = _diamond()
	board[8].rotation = 0
	_invalid(check, board, "Open connection at row 3, column 2.", "An End with incompatible geometry is incomplete even when its neighboring wire exists.")
	board = _diamond()
	board[2] = _piece("join", 1)
	_invalid(check, board, "Join at row 1, column 3 must merge two routes into one.", "A zero-cost Join cannot substitute for the physical paid Split at a fork.")
	board = _diamond()
	board[10] = _piece("split", 2)
	_invalid(check, board, "Split at row 3, column 3 must branch one route into two.", "A Split cannot merge two arrivals even when all three undirected ports match.")
	# This closed Wheatstone graph has simple paths 0-1-5-6-10-14
	# and 0-1-2-6-5-9-10-14. They cross the same 5/6 edge in opposite
	# directions, unlike the valid ordinary branch/rejoin diamond above.
	board = _board({0: _piece("begin", 0), 1: _piece("split", 0), 2: _piece("corner", 0), 5: _piece("split", 3), 6: _piece("join", 2), 9: _piece("corner", 2), 10: _piece("join", 2), 14: _piece("end", 0)})
	_invalid(check, board, "Feedback crosses a connection at row 2, column 2 in both directions.", "A fully connected cross-link with conflicting simple-path directions rejects rather than repeatedly triggering runes.")
	# Begin0-Split1-End2 has a side stem 1-5-9 into the closed square
	# 9-10-14-13-9. The square cannot reach End without revisiting9/1.
	board = _board({0: _piece("begin", 0), 1: _piece("split", 0), 2: _piece("end", 3), 5: _piece("straight", 1), 9: _piece("join", 0), 10: _piece("corner", 0), 13: _piece("corner", 2), 14: _piece("corner", 1)})
	_invalid(check, board, "A powered branch at row 1, column 2 cannot reach End without revisiting a piece.", "A closed dangling loop is not silently dropped from an otherwise complete Begin-End route.")
	board = _diamond()
	board[1] = _rune("spark", 0, 1)
	board[9] = _rune("missing", 0, 2)
	_invalid(check, board, "Unknown effect rune.", "An unknown downstream rune cannot expose partially accumulated damage or paid-piece costs.")
	board = _board({0: _piece("begin", 3), 15: _piece("end", 0)})
	_invalid(check, board, "Open connection at row 1, column 1.", "An outward-facing Begin is a deterministic incomplete route.")
	board[3] = _piece("begin", 0)
	_invalid(check, board, "A production board requires exactly one Begin and End.", "Duplicate endpoints reject before graph traversal.")
	board.resize(15)
	_invalid(check, board, "A production board requires sixteen cells.", "Malformed board dimensions reject before indexing endpoints.")

func _historical_isolation(check: Callable) -> void:
	var board := Circuit.demo_board()
	var baseline := Circuit.evaluate(board, CATALOG)
	check.call(baseline.valid and baseline.damage == 12 and baseline.cost == 1 and not baseline.has("reached"), "The explicit historical directed demo retains its aggregate result and original result shape.")
	var historical := Circuit.evaluate(board, CATALOG, {"version": "rc005_v1", "damage_mode": "multi_hit"})
	check.call(historical.valid and historical.hits == [6, 6] and not historical.has("reached"), "Historical multi-hit experiments retain their two copied hit contributions.")
	board[1].rotation = 2
	check.call(not Circuit.evaluate(board, CATALOG).valid, "Historical directed fixtures continue enforcing their input/output labels.")
	var migrated := Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(migrated.valid and migrated.damage == 12 and migrated.cost == 1, "The production profile alone accepts the same physically compatible reversed rune.")

func _controller_resolution(check: Callable) -> void:
	var loaded := Loader.load_setup()
	check.call(loaded.ok and loaded.setup.has("production"), "Undirected resolution integration starts with the validated production profile.")
	if not loaded.ok or not loaded.setup.has("production"):
		return
	# This controlled pool is normally drawn in full. It supplies exactly the
	# named permanent UIDs, while Conjure creates both temporary test instances
	# through its real command. It is not a change to starter balance/draws.
	var setup: Dictionary = loaded.setup.duplicate(true)
	setup.erase("next_encounter")
	setup.owned_cards = ["spark", "shield", "conjure", "conjure"]
	setup.opening_hand = []
	setup.opening_draw = 4
	setup.encounter.energy_per_turn = 4
	setup.encounter.player_health = 30
	setup.encounter.player_max_health = 30
	setup.encounter.max_health = 32
	setup.encounter.intents = [8]
	var game := Combat.new(setup)
	var owned := _owned_instances(game)
	var controller := Controller.new(game)
	var prepared := _prepare_controller_route(game, controller)
	check.call(prepared.ok, "Actual placement/rotation/Conjure commands build the reversed-port diamond within every finite kit.")
	if not prepared.ok:
		controller.dispose()
		return
	var forecast: Dictionary = controller.snapshot().forecast
	check.call(forecast == game.forecast() and forecast.valid and forecast.damage == 18 and forecast.shield == 5 and forecast.cost == 4, "Controller preview and Combat agree: upstream Free Spark12 plus shared downstream Spark6, branch Shield5, physical cost4.")
	check.call(not Circuit.evaluate(game.board, game.catalog, {"version": "rc006_free_endpoints_v1"}).valid, "The same movable-endpoint graph is rejected by historical port polarity, so integration really requires undirected entry through old outputs.")
	game.energy = 3
	var before := _gameplay(game)
	check.call(not controller.command("cast") and not controller.is_busy() and _gameplay(game) == before, "One energy short rejects without payment, RNG advance, card movement, cleanup or controller lock.")
	check.call(not game.last_result().accepted and game.last_result().events.is_empty() and game.log_text == "Need 4 energy; you have 3.", "Insufficient-energy rejection emits no partial cast/damage/cleanup events and states the actual cost.")
	game.energy = 4
	check.call(controller.command("rotate", {"index": 6}), "A legal edit can temporarily disconnect the controlled route.")
	before = _gameplay(game)
	check.call(not before.forecast.valid and not controller.command("cast") and _gameplay(game) == before and game.last_result().events.is_empty(), "Invalid-graph Cast is also immutable and emits no partial effects through the real controller.")
	for quarter in range(3):
		controller.command("rotate", {"index": 6})
	forecast = controller.snapshot().forecast
	var delayed := Delayed.new()
	check.call(controller.set_presenter(delayed) and forecast.valid, "The restored authoritative route can resolve through a delayed presentation consumer.")
	check.call(controller.command("cast") and controller.is_busy(), "Exactly four energy authorizes the complete reversed-port spell once.")
	var result := game.last_result()
	check.call(result.accepted and result.before.forecast == forecast and result.events[0].type == "cast" and result.events[0].spell == forecast, "The accepted cast event carries exactly the previewed authoritative forecast, including its physical execution list.")
	check.call(result.events.filter(func(event): return event.type == "cast").size() == 1 and result.events[0].energy_before == 4 and result.events[0].energy_after == 0, "One physical Split1, Shield1 and Spark2 charge exactly once; the generated Free Spark costs zero.")
	var damage: Array = result.events.filter(func(event): return event.type == "damage")
	var shielding: Array = result.events.filter(func(event): return event.type == "shield")
	var retaliation: Array = result.events.filter(func(event): return event.type == "retaliation")
	check.call(damage.size() == 1 and damage[0].amount == 18 and damage[0].applied == 18 and shielding.size() == 1 and shielding[0].amount == 5 and retaliation.size() == 1 and retaliation[0].blocked == 5 and retaliation[0].applied == 3 and game.enemy_hp == 14 and game.player_hp == 27, "One aggregate damage event and one downstream Spark contribution agree with preview; one Shield blocks5 of the incoming8.")
	_assert_route_cleanup(check, game, result, prepared, owned)
	check.call(game.turn == 2 and game.energy == 4 and game.hand.size() == 3 and game.snapshot().stock == game.snapshot().kit.totals, "Successful nonterminal resolution rebuilds endpoints, restores the configured energy, normally draws3 and replaces finite stock.")
	before = _gameplay(game)
	check.call(not controller.command("cast") and not controller.command("pass") and not controller.command("rotate", {"index": 0}) and _gameplay(game) == before, "Busy presentation rejects duplicate cast/pass/edit without applying the same forecast again.")
	delayed.complete()
	delayed.complete()
	check.call(not controller.is_busy() and _gameplay(game) == before and delayed.batches.size() == 1, "Repeated completion callbacks unlock once and cannot repay, redamage, redraw or repeat cleanup.")
	controller.dispose()
	for outcome in ["victory", "defeat"]:
		game = Combat.new(setup)
		owned = _owned_instances(game)
		controller = Controller.new(game)
		prepared = _prepare_controller_route(game, controller)
		if outcome == "victory": game.enemy_hp = 12
		else: game.player_hp = 2
		var rng_before := [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
		check.call(prepared.ok and controller.command("cast") and game.state == outcome, "The reversed-port shared-effect route resolves the real %s boundary." % outcome)
		result = game.last_result()
		_assert_route_cleanup(check, game, result, prepared, owned)
		var types: Array = result.events.map(func(event): return event.type)
		check.call(game.turn == 1 and game.energy == 0 and game.hand.is_empty() and rng_before == [game.rng.state, game.endpoint_rng.state, game.kit_rng.state] and types.back() == "battle_ended" and not types.has("turn_started") and not types.has("card_drawn") and not types.has("kit_changed"), "Terminal %s performs ownership cleanup without another hand, endpoint/kit selection or RNG consumption." % outcome)
		if outcome == "victory":
			check.call(result.events[1].amount == 18 and result.events[1].applied == 12 and game.player_hp == 30 and not types.has("shield") and not types.has("retaliation"), "Lethal previewed18 applies only remaining12 HP, suppressing shield and retaliation.")
		else:
			retaliation = result.events.filter(func(event): return event.type == "retaliation")
			check.call(game.enemy_hp == 14 and game.player_hp == 0 and retaliation.size() == 1 and retaliation[0].amount == 3 and retaliation[0].applied == 2, "Defeat preserves shield5 and requested3/applied2 retaliation without retriggering the shared rune.")
		before = _gameplay(game)
		check.call(not controller.command("cast") and not controller.command("pass") and not controller.command("rotate", {"index": 0}) and _gameplay(game) == before and not controller.can_edit(), "Terminal %s controller guards reject duplicate actions and retain all permanent UIDs unchanged." % outcome)
		controller.dispose()

func _prepare_controller_route(game: Combat, controller: Controller) -> Dictionary:
	# Supply explicit endpoints for this bounded integration fixture, then use
	# real controller edits. No authored production opening or RNG is changed.
	game.board = _board({0: _piece("begin", 0), 8: _piece("end", 1)})
	var prepared := controller.command("technique", {"uid": _hand_uid(game, "conjure")})
	var temporary_uid := _hand_uid(game, "free_spark")
	var shield_uid := _hand_uid(game, "shield")
	var spark_uid := _hand_uid(game, "spark")
	for entry in [[1, temporary_uid, 2], [6, shield_uid, 3], [9, spark_uid, 0]]:
		prepared = controller.command("place_rune", {"index": entry[0], "uid": entry[1]}) and prepared
		for quarter in range(entry[2]):
			prepared = controller.command("rotate", {"index": entry[0]}) and prepared
	for entry in [[2, "split", 0], [3, "corner", 0], [7, "straight", 1], [10, "join", 3], [11, "corner", 1]]:
		prepared = controller.command("place_wire", {"index": entry[0], "kind": entry[1]}) and prepared
		for quarter in range(entry[2]):
			prepared = controller.command("rotate", {"index": entry[0]}) and prepared
	prepared = controller.command("technique", {"uid": _hand_uid(game, "conjure")}) and prepared
	return {"ok": prepared, "temporary_uid": temporary_uid, "unused_temporary_uid": _hand_uid(game, "free_spark"), "shield_uid": shield_uid, "spark_uid": spark_uid}

func _assert_route_cleanup(check: Callable, game: Combat, result: Dictionary, prepared: Dictionary, owned: Array) -> void:
	var consumed: Array = result.events.filter(func(event): return event.type == "effect_consumed")
	var expired: Array = result.events.filter(func(event): return event.type == "temporary_expired")
	var cleanup: Array = result.events.filter(func(event): return event.type == "turn_cleanup")
	check.call(consumed.size() == 2 and consumed.filter(func(event): return event.card.uid == prepared.spark_uid).size() == 1 and consumed.filter(func(event): return event.card.uid == prepared.shield_uid).size() == 1 and consumed.all(func(event): return event.to == "discard" and event.after == {}), "Reversed-port resolution discards the physical shared Spark and branch Shield once each.")
	check.call(expired.size() == 1 and expired[0].cell == 1 and expired[0].before.uid == prepared.temporary_uid and expired[0].after == {} and cleanup.size() == 1 and cleanup[0].expired.size() == 1 and cleanup[0].expired[0].uid == prepared.unused_temporary_uid, "Amplified temporary expires once from its cell and the unused generated temporary expires once from hand.")
	check.call(_owned_instances(game) == owned and (game.hand + game.draw_pile + game.discard_pile).all(func(card): return not game.catalog[card.id].temporary) and game.board.filter(func(piece): return piece.is_empty()).size() == 14 and game.history.is_empty(), "Cleanup conserves every permanent UID across zones, excludes temporary UIDs from piles, clears history and leaves only endpoints.")

func _hand_uid(game: Combat, id: String) -> int:
	for card in game.hand:
		if card.id == id: return card.uid
	return -1

func _owned_instances(game: Combat) -> Array:
	var owned: Array = []
	for card in game.hand + game.draw_pile + game.discard_pile:
		if not game.catalog[card.id].temporary: owned.append(card.duplicate(true))
	for piece in game.board:
		if piece.get("kind") == "rune" and not game.catalog[piece.rune_id].temporary:
			owned.append({"id": piece.rune_id, "uid": piece.uid})
	owned.sort_custom(func(first, second): return first.uid < second.uid)
	return owned

func _gameplay(game: Combat) -> Dictionary:
	var value := game.snapshot()
	value.erase("log_text")
	value.random_states = [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
	value.history = game.history.duplicate(true)
	value.next_uid = game.next_uid
	return value

func _invalid(check: Callable, board: Array, message: String, description: String) -> Dictionary:
	var before := var_to_bytes(board)
	var result := Circuit.evaluate(board, CATALOG, OPTIONS)
	check.call(not result.valid and result.message == message, description)
	check.call(result.damage == 0 and result.shield == 0 and result.cost == 0 and result.active.is_empty(), "Invalid graph exposes no partial effects, charge or execution list: " + description)
	check.call(Circuit.evaluate(board, CATALOG, OPTIONS) == result and var_to_bytes(board) == before, "Repeated rejection is deterministic and leaves the source board unchanged: " + description)
	return result

func _piece(kind: String, rotation: int) -> Dictionary:
	return {"kind": kind, "rotation": rotation}

func _rune(id: String, rotation: int, uid: int) -> Dictionary:
	return {"kind": "rune", "rotation": rotation, "rune_id": id, "uid": uid}

func _board(placements: Dictionary) -> Array:
	var board: Array = []
	for index in range(16):
		board.append(placements.get(index, {}).duplicate(true))
	return board

func _diamond() -> Array:
	return _board({0: _piece("begin", 0), 1: _piece("straight", 0), 2: _piece("split", 0), 3: _piece("corner", 0), 6: _piece("straight", 1), 7: _piece("straight", 1), 8: _piece("end", 1), 9: _piece("straight", 0), 10: _piece("join", 3), 11: _piece("corner", 1)})

func _rotate_board(board: Array) -> Array:
	var rotated := _board({})
	for index in range(16):
		if board[index].is_empty(): continue
		var x: int = index % 4
		var y: int = index / 4
		var next := x * 4 + 3 - y
		rotated[next] = board[index].duplicate(true)
		rotated[next].rotation = (int(board[index].rotation) + 1) % 4
	return rotated
