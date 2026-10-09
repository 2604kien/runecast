extends RefCounted

# RC-007 preserves these historical assertions using the explicit legacy fixture.
# Production defaults are covered separately by production_*_tests.gd.

const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")

func _setup(options: Dictionary = {}) -> Dictionary:
	var value: Dictionary = Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup
	value.experiment = {"scenario_id": "test_core", "variant_id": "control", "version": "rc005_v1",
		"seed": 42, "effects": "persistent", "split_cost": 1, "damage_mode": "aggregate",
		"expiry": "straight", "transfer": "none"}
	value.experiment.merge(options, true)
	return value

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

func _types(result: Dictionary) -> Array:
	return result.events.map(func(event): return event.type)

func _enemy_hits(result: Dictionary) -> Array:
	return result.events.filter(func(event): return event.type == "damage" and event.target == "enemy")

func run(check: Callable) -> void:
	_consumption(check)
	_geometry(check)
	_split_and_hits(check)
	_expiry(check)
	_transfer(check)
	_replay_and_isolation(check)

func _consumption(check: Callable) -> void:
	for mode in ["persistent", "consumed"]:
		var game := Combat.new(_setup({"effects": mode}))
		var owned := _permanents(game)
		var spark_uid: int = game.hand[0].uid
		var shield_uid: int = game.hand[1].uid
		game.place_rune(1, spark_uid)
		game.place_rune(12, shield_uid)
		var result := game.execute("cast")
		check.call(result.accepted and game.enemy_hp == 20 and game.player_hp == 22, mode + " resolves the same powered effects and retaliation.")
		check.call(_permanents(game) == owned and game.board[12].uid == shield_uid, mode + " preserves all permanent UIDs and disconnected installed effects.")
		if mode == "consumed":
			check.call(game.board[1] == {"kind": "straight", "rotation": 0} and game.discard_pile.has({"id": "spark", "uid": spark_uid}), "Only the powered permanent enters discard and leaves its matching connector.")
			check.call(_types(result).slice(0, 6) == ["cast", "damage", "shield", "retaliation", "effect_consumed", "turn_cleanup"], "Consumption follows retaliation and precedes hand cleanup and drawing.")
			check.call(result.events[4].card.uid == spark_uid and result.events[4].cell == 1 and result.events[4].after == game.board[1], "Consumption event records the exact instance and geometry.")
		else:
			check.call(game.board[1].uid == spark_uid and not _types(result).has("effect_consumed"), "Persistent control keeps the powered permanent installed.")
		game = Combat.new(_setup({"effects": mode}))
		game.place_rune(1, game.hand[0].uid)
		result = game.execute("pass")
		check.call(game.board[1].kind == "rune" and not _types(result).has("effect_consumed"), mode + " does not consume an effect on Pass.")

	var setup := _setup({"effects": "consumed"})
	setup.encounter.max_health = 7
	var game := Combat.new(setup)
	var owned := _permanents(game)
	game.place_rune(1, game.hand[0].uid)
	var result := game.execute("cast")
	check.call(_types(result) == ["cast", "damage", "effect_consumed", "turn_cleanup", "battle_ended"] and game.state == "victory", "Lethal consumed cast performs consumption and cleanup before victory without retaliation.")
	check.call(_permanents(game) == owned, "Consumption on victory conserves permanent instances without a next-turn draw.")

	setup = _corner_setup({"effects": "consumed"})
	setup.catalog.spark.port_shape = "corner"
	game = Combat.new(setup)
	var spark_uid: int = game.hand[0].uid
	game.place_rune(3, spark_uid)
	result = game.execute("cast")
	check.call(result.accepted and game.board[3] == {"kind": "corner", "rotation": 0} and game.forecast().valid, "Consumed alternate-port permanent leaves its actual elbow shape and preserves circuit connectivity.")
	game = Combat.new(_corner_setup({"effects": "consumed"}))
	game.place_rune(1, game.hand[0].uid)
	result = game.execute("cast")
	check.call(_types(result).slice(0, 7) == ["cast", "damage", "shield", "retaliation", "effect_consumed", "temporary_expired", "turn_cleanup"], "Permanent consumption precedes installed temporary expiry in a mixed cast.")

func _geometry(check: Callable) -> void:
	var setup := _setup()
	setup.board = []
	for index in range(16):
		setup.board.append({})
	setup.board[12] = {"kind": "begin", "rotation": 3}
	setup.board[8] = {"kind": "rune", "rotation": 3, "rune_id": "free_spark"}
	setup.board[4] = {"kind": "straight", "rotation": 3}
	setup.board[0] = {"kind": "end", "rotation": 2}
	setup.board[5] = {"kind": "blocked", "rotation": 0}
	var game := Combat.new(setup)
	check.call(game.forecast().valid and game.forecast().damage == 6 and game.forecast().cost == 0, "Experimental Begin/End placement and orientation determine the powered circuit.")
	check.call(not Circuit.evaluate(game.board, game.catalog).valid, "Alternate endpoint evaluation requires explicit experimental options.")
	var before := game.snapshot()
	var rejected := true
	for index in [0, 12, 5]:
		for command in ["place_wire", "place_rune", "rotate", "flip"]:
			var result := game.execute(command, {"index": index, "kind": "erase", "uid": game.hand[0].uid})
			rejected = rejected and not result.accepted and result.events.is_empty()
	check.call(rejected and game.snapshot() == before, "Every editor command protects actual endpoints and blocked cells with no history changes.")
	check.call(game.place_wire(14, "corner"), "The former End socket is editable when the experimental End moved.")
	game.undo()
	check.call(game.snapshot().board == before.board, "Undo preserves moved protected geometry.")
	game.board[4] = {"kind": "blocked", "rotation": 0}
	check.call(not game.forecast().valid and not game.execute("cast").accepted, "A blocked cell interrupts actual connectivity and cannot be cast through.")
	for rotation in range(4):
		var ports := Circuit.ports({"kind": "rune", "port_shape": "corner", "rotation": rotation})
		check.call(ports.input == [(3 + rotation) % 4] and ports.output == [(2 + rotation) % 4], "Alternate rune rotation %d exposes the actual elbow ports." % rotation)
	setup = _corner_setup()
	var corner_game := Combat.new(setup)
	check.call(corner_game.forecast().valid and corner_game.forecast().damage == 6, "Alternate effect on the right Split branch has a known valid solution.")
	corner_game.rotate(3)
	check.call(not corner_game.forecast().valid, "Rotating the alternate rune changes evaluated connectivity.")
	corner_game.undo()
	check.call(corner_game.forecast().valid, "Undo restores alternate rune ports and connectivity.")
	corner_game.play_technique(corner_game.hand[2].uid)
	corner_game.place_rune(3, corner_game.hand.back().uid)
	check.call(corner_game.board[3].port_shape == "corner" and corner_game.forecast().valid, "Newly installed generated runes inherit catalog port shape.")

func _split_and_hits(check: Callable) -> void:
	for split_cost in [1, 2]:
		var setup := _setup({"split_cost": split_cost})
		setup.inventory = {"split": 2, "join": 2}
		setup.encounter.energy_per_turn = 6
		var game := Combat.new(setup)
		game.place_rune(1, game.hand[0].uid)
		check.call(game.place_wire(6, "join") and game.place_wire(7, "split") and game.rotate(7), "Two-pair inventory permits the nested-branch solution at Split cost %d." % split_cost)
		var spell := game.forecast()
		check.call(spell.valid and spell.damage == 18 and spell.cost == 2 + 2 * split_cost, "Two-pair solution delivers three copies and charges each powered Split once at cost %d." % split_cost)
		check.call(game.stock("split") == 0 and game.stock("join") == 0, "Both installed pairs consume the bounded inventory.")
		game.energy = spell.cost - 1
		check.call(not game.execute("cast").accepted and game.enemy_hp == 32, "The separate Split price produces authoritative affordability rejection.")
		game.energy = spell.cost
		check.call(game.execute("cast").accepted and game.enemy_hp == 14, "An affordable two-pair cast applies its predicted total.")
	var control := Combat.new(_setup())
	check.call(not control.place_wire(6, "join") and not control.place_wire(7, "split"), "The one-pair control cannot install the second pair.")

	var setup := _corner_setup({"damage_mode": "multi_hit"})
	setup.catalog.free_spark.value = 3
	var game := Combat.new(setup)
	game.place_rune(1, game.hand[0].uid)
	var spell := game.forecast()
	check.call(spell.damage == 15 and spell.hits == [6, 3, 6], "Split copies contribution lists and Join concatenates right-branch arrival before down-branch arrival.")
	var result := game.execute("cast")
	var hits := _enemy_hits(result)
	check.call(hits.map(func(hit): return hit.amount) == [6, 3, 6] and hits.map(func(hit): return hit.hit_index) == [0, 1, 2], "Multi-hit damage emits ordered inspectable per-hit events.")
	check.call(hits.map(func(hit): return hit.health_after) == [26, 23, 17] and game.enemy_hp == 17, "Ordered hits reconcile with the same aggregate total.")
	check.call(hits.all(func(hit): return hit.hit_count == 3) and _types(result).slice(0, 6) == ["cast", "damage", "damage", "damage", "shield", "retaliation"], "The whole hit sequence resolves before one ordinary shield/retaliation phase.")
	setup.experiment.damage_mode = "aggregate"
	var aggregate := Combat.new(setup)
	aggregate.place_rune(1, aggregate.hand[0].uid)
	var aggregate_result := aggregate.execute("cast")
	check.call(_enemy_hits(aggregate_result).size() == 1 and aggregate.enemy_hp == game.enemy_hp and aggregate.player_hp == game.player_hp, "Aggregate and multi-hit are mechanically equal for the no-armor fixture.")
	setup.experiment.damage_mode = "multi_hit"
	setup.encounter.max_health = 7
	game = Combat.new(setup)
	game.place_rune(1, game.hand[0].uid)
	result = game.execute("cast")
	hits = _enemy_hits(result)
	check.call(hits.size() == 2 and hits[1].amount == 3 and hits[1].applied == 1 and game.state == "victory", "Lethal multi-hit stops before remaining contributions and clamps actual applied damage.")
	check.call(not _types(result).has("retaliation") and _types(result).back() == "battle_ended", "Lethal multi-hit still performs cleanup and victory without retaliation.")
	game = Combat.new(_setup({"damage_mode": "multi_hit"}))
	game.place_rune(1, game.hand[1].uid)
	result = game.execute("cast")
	check.call(result.events[0].spell.hits.is_empty() and _enemy_hits(result).is_empty() and game.enemy_hp == 32 and game.player_hp == 30, "A shield-only multi-hit cast emits no damage hits and retains ordinary shielding.")
	setup = _setup({"damage_mode": "multi_hit"})
	setup.inventory = {"split": 2, "join": 2}
	setup.encounter.energy_per_turn = 6
	game = Combat.new(setup)
	game.place_rune(1, game.hand[0].uid)
	game.place_wire(6, "join")
	game.place_wire(7, "split")
	game.rotate(7)
	check.call(game.forecast().hits == [6, 6, 6] and game.forecast().damage == 18, "Nested two-pair traversal propagates ordered contributions without losing or double-counting a path.")

func _corner_setup(options: Dictionary = {}) -> Dictionary:
	var value := _setup(options)
	value.catalog.free_spark.port_shape = "corner"
	value.board[1] = {"kind": "straight", "rotation": 0}
	value.board[3] = {"kind": "rune", "rotation": 0, "rune_id": "free_spark", "port_shape": "corner"}
	return value

func _expiry(check: Callable) -> void:
	for mode in ["straight", "retained", "empty"]:
		for command in ["cast", "pass"]:
			var game := Combat.new(_corner_setup({"expiry": mode}))
			var owned := _permanents(game)
			game.play_technique(game.hand[2].uid)
			game.place_rune(12, game.hand.back().uid)
			game.rotate(12)
			game.rotate(12)
			# A separate unused hand temporary must expire by the same cleanup.
			game.hand.append(game._card("free_spark"))
			var result := game.execute(command)
			check.call(result.accepted and _types(result).count("temporary_expired") == 2, "%s/%s expires connected and disconnected installed temporaries." % [mode, command])
			var expected_connected := {} if mode == "empty" else {"kind": "corner" if mode == "retained" else "straight", "rotation": 0}
			var expected_disconnected := {} if mode == "empty" else {"kind": "corner" if mode == "retained" else "straight", "rotation": 2}
			check.call(game.board[3] == expected_connected and game.board[12] == expected_disconnected, "%s/%s applies the exact shape and preserves orientation when a connector remains." % [mode, command])
			check.call(game.forecast().valid == (mode == "retained"), "%s/%s leaves the documented circuit repair requirement." % [mode, command])
			var cleanup: Dictionary = result.events.filter(func(event): return event.type == "turn_cleanup")[0]
			check.call(cleanup.expired.size() == 1 and not (game.hand + game.draw_pile + game.discard_pile).any(func(card): return card.id == "free_spark"), "%s/%s removes unused hand temporaries without entering piles." % [mode, command])
			check.call(_permanents(game) == owned, "%s/%s temporary expiry conserves every permanent instance." % [mode, command])

func _transfer(check: Callable) -> void:
	for mode in ["reset", "retain"]:
		var setup := _setup({"transfer": mode})
		setup.encounter.max_health = 12
		setup.owned_cards = ["spark", "shield", "conjure", "focus"]
		var game := Combat.new(setup)
		var owned := _permanents(game)
		check.call(not game.execute("next_encounter").accepted and not game.snapshot().can_advance, mode + " cannot advance before first victory.")
		var spark_uid: int = game.hand[0].uid
		var shield_uid: int = game.hand[1].uid
		game.place_rune(1, spark_uid)
		game.place_rune(4, shield_uid)
		game.place_wire(12, "corner")
		game.rotate(12)
		game.pass_turn()
		game.cast()
		check.call(game.state == "victory" and game.snapshot().can_advance and game.player_hp == 22, mode + " first battle completes with carried damage and an available transition.")
		check.call(not game.execute("next_encounter", {"board": []}).accepted and game.log_text.contains("same fixed board geometry") and game.snapshot().encounter_number == 1, mode + " rejects incompatible second-board override requests explicitly.")
		var prior := game.snapshot()
		var next_uid: int = game.next_uid
		var result := game.execute("next_encounter")
		check.call(result.accepted and result.before == prior and result.after == game.snapshot() and _types(result) == ["encounter_transition"], mode + " transition resolves once through the authoritative command boundary.")
		check.call(game.snapshot().encounter_number == 2 and game.state == "playing" and game.enemy_hp == 12 and game.player_hp == 22 and game.energy == 3 and game.turn == 1 and game.history.is_empty(), mode + " resets enemy/turn/energy/history while carrying health.")
		check.call(_permanents(game) == owned and game.next_uid == next_uid, mode + " transfer carries each permanent UID exactly once without allocating cards.")
		check.call(not (game.hand + game.draw_pile + game.discard_pile).any(func(card): return card.id == "free_spark") and not game.board.any(func(piece): return piece.get("rune_id") == "free_spark"), mode + " never recreates opening temporaries or transfers them into ownership.")
		if mode == "retain":
			check.call(game.board[1].uid == spark_uid and game.board[4].uid == shield_uid and game.board[12] == prior.board[12], "Retain carries installed permanent instances and selected disconnected topology.")
			check.call(game.hand.map(func(card): return card.id) == ["conjure"] and game.draw_pile.map(func(card): return card.id) == ["focus"], "Retain reconstructs only eligible curated cards and excludes installed instances.")
		else:
			check.call(game.board[1] == {"kind": "straight", "rotation": 0} and game.board[4].is_empty() and game.board[12].is_empty(), "Reset rebuilds initial connector topology without reinstalling initial runes.")
			check.call(game.hand.map(func(card): return card.id) == ["spark", "shield", "conjure"] and game.draw_pile.map(func(card): return card.id) == ["focus"], "Reset reconstructs the curated hand from existing permanent instances.")
		check.call(game.discard_pile.is_empty() and result.encounter_id > prior.encounter_id and result.events[0].encounter_id == result.encounter_id, mode + " transfer clears discard and advances event generation.")
		var after := game.snapshot()
		var rng_after: int = game.rng.state
		check.call(not game.execute("next_encounter").accepted and game.snapshot() == after and game.rng.state == rng_after, mode + " duplicate transition is rejected without state or RNG change.")
		game.enemy_hp = 0
		game.state = "victory"
		check.call(not game.snapshot().can_advance and not game.execute("next_encounter").accepted, mode + " second victory cannot start a third encounter.")
		game.reset()
		check.call(game.snapshot().encounter_number == 1 and game.player_hp == 30 and game.board[1].rune_id == "free_spark", mode + " ordinary Restart rebuilds the first encounter with its normal fixture.")
	var normal := Combat.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup)
	normal.enemy_hp = 1
	normal.cast()
	check.call(not normal.execute("next_encounter").accepted, "Normal gameplay never enables the paired encounter command.")
	for mode in ["reset", "retain"]:
		var setup := _setup({"transfer": mode})
		setup.encounter.max_health = 12
		setup.board[1].rune_id = "spark"
		setup.opening_hand = []
		setup.opening_draw = 3
		var game := Combat.new(setup)
		var owned := _permanents(game)
		game.cast()
		var result := game.execute("next_encounter")
		check.call(result.accepted and _types(result) == ["encounter_transition", "card_drawn", "card_drawn", "card_drawn"] and game.hand.size() == 3, mode + " honors opening-draw policy after transition and reports the actual ordered draws.")
		check.call(_permanents(game) == owned and game.draw_pile.size() == (4 if mode == "retain" else 5), mode + " opening draws reserve retained cards without duplicating or losing permanent ownership.")

func _replay_and_isolation(check: Callable) -> void:
	var setup := _setup({"damage_mode": "multi_hit", "transfer": "retain"})
	var first := Combat.new(setup)
	var second := Combat.new(setup)
	check.call(first.snapshot() == second.snapshot() and first.rng.state == second.rng.state, "Fresh experimental models replay the exact same setup and seed.")
	var override := Combat.new(setup, 123)
	check.call(override.snapshot().experiment.seed == 123 and override.encounter.seed == 123 and setup.experiment.seed == 42, "Seed overrides update the reported experiment seed without mutating its source configuration.")
	first.cast()
	second.cast()
	check.call(first.last_result() == second.last_result() and first.rng.state == second.rng.state, "Matched commands reproduce complete ordered experimental outcomes and draws.")
	var exposed := first.snapshot()
	exposed.experiment.expiry = "empty"
	exposed.forecast.hits.clear()
	setup.experiment.damage_mode = "aggregate"
	check.call(first.snapshot().experiment.damage_mode == "multi_hit" and first.snapshot().experiment.expiry == "straight", "Input and snapshot experimental configuration cannot mutate model strategy.")
	first.reset()
	check.call(first.snapshot().experiment.damage_mode == "multi_hit", "Restart retains the private experiment configuration copy.")
	var replay := Combat.new(_setup({"damage_mode": "multi_hit", "transfer": "retain"}))
	check.call(replay.draw_pile.map(func(card): return card.uid) == [7, 5, 8, 4, 6] and first.draw_pile != replay.draw_pile, "Exact replay reseeds a new model while normal Restart continues RNG.")
	setup = _setup({"transfer": "reset"})
	setup.encounter.max_health = 12
	first = Combat.new(setup)
	second = Combat.new(setup)
	first.cast()
	second.cast()
	var continued_state: int = first.rng.state
	first.execute("next_encounter")
	second.execute("next_encounter")
	check.call(first.snapshot() == second.snapshot() and first.rng.state == second.rng.state and first.rng.state != continued_state, "Paired transfers shuffle the reconciled deck reproducibly using the continued RNG stream.")
