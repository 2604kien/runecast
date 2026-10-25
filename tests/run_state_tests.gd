extends RefCounted

const RunState = preload("res://scripts/core/run_state.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Circuit = preload("res://scripts/core/circuit.gd")

func run(check: Callable) -> void:
	var setup: Dictionary = Loader.load_setup().setup
	_defaults(check, setup)
	_replay_and_isolation(check, setup)
	_entry_contract(check, setup)
	_outcomes(check, setup)
	_rejected_handoffs(check, setup)

func _defaults(check: Callable, setup: Dictionary) -> void:
	var run := RunState.new(setup, 42)
	var initial := run.snapshot()
	check.call(initial.status == "ready" and initial.player_hp == 30 and initial.player_max_hp == 30 and initial.gold == 0 and initial.relics.is_empty(), "RC-024: new run starts ready with 30/30 HP, zero run Gold and no relics.")
	var counts := {}
	for card in initial.owned_cards: counts[card.id] = int(counts.get(card.id, 0)) + 1
	check.call(counts == {"spark": 2, "shield": 2, "focus": 2, "conjure": 2} and initial.owned_cards.map(func(card): return card.uid) == range(8), "RC-024: eight run-owned instances have distinct stable UIDs and the accepted two-of-each starter.")
	check.call(not initial.session_only and not initial.tower_completed and initial.completed_encounters.is_empty() and initial.current_encounter_id == setup.encounter.id, "RC-028: persistent run snapshot retains its bounded encounter and no tower completion.")
	var detached := run.snapshot()
	detached.owned_cards[0].id = "free_spark"
	detached.rng_states.cards = 0
	detached.relics.append("invented")
	detached.completed_encounters.append("invented")
	check.call(run.snapshot() == initial, "RC-024: nested run snapshots cannot mutate ownership, streams, relics or progression.")
	var input := setup.duplicate(true)
	var isolated := RunState.new(input)
	input.catalog.spark.value = 999
	input.owned_cards.clear()
	check.call(isolated.enter_battle().ok and isolated.current_battle().snapshot().catalog.spark.value == setup.catalog.spark.value, "RC-024: construction detaches validated content from subsequent caller mutation.")
	check.call(RunState.new(setup, -1).snapshot().status == "invalid", "RC-024: invalid seeds reject before battle construction.")
	check.call(RunState.new(Loader.load_setup(Loader.LEGACY_ENCOUNTER).setup).snapshot().status == "invalid", "RC-024: legacy training remains isolated and cannot become the run fixture.")
	check.call(RunState.new(Loader.load_setup("res://data/production_transition_encounter.json").setup).snapshot().status == "invalid", "RC-024: the run shell cannot silently opt into the development successor route.")

func _replay_and_isolation(check: Callable, setup: Dictionary) -> void:
	var first := RunState.new(setup, 872)
	var other := RunState.new(setup, 872)
	var initial := first.snapshot()
	check.call(initial.run_id != other.snapshot().run_id and initial.owned_cards == other.snapshot().owned_cards and initial.rng_states == other.snapshot().rng_states, "RC-024: same-seed independent runs have separate identities but reproducible run-local cards and streams.")
	var entered := first.enter_battle()
	var game: Combat = entered.combat
	var twin: Combat = other.enter_battle().combat
	var opening := game.snapshot()
	var opening_handoff := game.run_handoff()
	check.call(entered.ok and opening == twin.snapshot() and first.current_battle() == game and first.snapshot().owned_cards == initial.owned_cards, "RC-024: entry lends all original run instances to an identical seeded production opening.")
	check.call(opening.board.filter(func(piece): return piece.is_empty()).size() == 14 and opening.hand.size() == 3 and opening.stock_totals.values().reduce(func(total, count): return total + count, 0) == 10, "RC-024: run entry retains endpoints-only starts, normal three-card draw and a finite ten-piece kit.")
	var before := first.snapshot()
	check.call(not first.enter_battle().ok and first.snapshot() == before and first.current_battle() == game, "RC-024: repeated entry rejects atomically without changing identity or streams.")
	check.call(first.continue_battle().combat == game and game.snapshot() == opening and game.run_handoff() == opening_handoff, "RC-024: Resume returns the exact active battle without reset or RNG consumption.")
	game.pass_turn()
	var after_pass := game.snapshot()
	var after_streams: Dictionary = game.run_handoff().rng_states
	check.call(first.snapshot().player_hp == after_pass.player_hp and first.snapshot().rng_states == after_streams and first.snapshot().owned_cards == initial.owned_cards, "RC-024: run snapshot reflects authoritative live battle HP/streams while ownership remains run-local.")
	check.call(twin.snapshot() == opening and other.snapshot().player_hp == 30, "RC-024: play in one run cannot consume another run's streams or health.")
	before = first.snapshot()
	check.call(not first.quit_to_home(twin) and first.snapshot() == before, "RC-024: a different run's battle cannot leave or mutate this run.")
	check.call(first.quit_to_home(game) and first.snapshot().status == "replay_pending" and first.current_battle() == null, "RC-024: confirmed Quit detaches battle and retains a session-only replay entry.")
	check.call(first.snapshot().player_hp == initial.player_hp and first.snapshot().rng_states == initial.rng_states and first.snapshot().owned_cards == initial.owned_cards, "RC-024: quitting restores the pre-battle committed HP/cards/streams without sampling a new opening.")
	before = first.snapshot()
	check.call(not first.quit_to_home(game) and not first.resolve_battle(game) and first.snapshot() == before, "RC-024: duplicate or stale exit/outcome calls leave the replay checkpoint untouched.")
	var replay: Combat = first.continue_battle().combat
	check.call(replay != game and replay.snapshot() == opening and replay.run_handoff() == opening_handoff, "RC-024: Continue creates an exact checkpoint replay, including all three RNG states and permanent UIDs.")
	game.pass_turn()
	check.call(replay.snapshot() == opening and first.current_battle() == replay, "RC-024: an orphaned old model cannot alter the replacement battle.")
	replay.pass_turn()
	check.call(replay.snapshot() == after_pass and replay.run_handoff().rng_states == after_streams, "RC-024: checkpoint replay reproduces the next hand, endpoint pair, kit and HP without rerolls.")
	before = first.snapshot()
	check.call(not first.resolve_battle(game) and not first.quit_to_home(game) and first.snapshot() == before, "RC-024: stale model callbacks cannot resolve or abandon the current replay.")
	var previous_rng: Dictionary = replay.run_handoff().rng_states
	replay.reset()
	check.call(replay.snapshot().encounter_id == 2 and replay.player_hp == 30 and replay.run_handoff().rng_states != previous_rng and replay.run_handoff().owned_cards == initial.owned_cards, "RC-024: ordinary Restart advances generation/continued RNG while retaining entry HP and run-owned identities.")
	check.call(first.quit_to_home(replay) and first.continue_battle().combat.snapshot() == opening, "RC-024: Quit after ordinary Restart still replays the committed encounter entry, never the rerolled restart.")

func _entry(run: RunState) -> Dictionary:
	var value := run.snapshot()
	return {"version": 1, "run_id": value.run_id, "seed": value.seed,
		"encounter_id": value.current_encounter_id, "owned_cards": value.owned_cards,
		"player_hp": value.player_hp, "player_max_hp": value.player_max_hp,
		"next_uid": 8, "rng_states": value.rng_states}

func _entry_contract(check: Callable, setup: Dictionary) -> void:
	var run := RunState.new(setup)
	var entry := _entry(run)
	entry.player_hp = 17
	entry.player_max_hp = 43
	for card in entry.owned_cards: card.uid += 20
	entry.next_uid = 80
	var created := Combat.create_for_run(setup, entry)
	var game: Combat = created.combat
	check.call(created.ok and game.player_hp == 17 and game.snapshot().player_max_hp == 43 and game.run_handoff().owned_cards == entry.owned_cards, "RC-024: model-owned handoff carries current/max HP and nondefault UIDs without healing or reallocating instances.")
	var expected := game.snapshot()
	entry.owned_cards[0].id = "free_spark"
	entry.rng_states.cards = 0
	check.call(game.snapshot() == expected and game.run_handoff().ok, "RC-024: accepted handoff is detached from its caller's card and stream dictionaries.")
	var handoff := game.run_handoff()
	handoff.owned_cards.clear()
	handoff.rng_states.endpoints = 0
	check.call(game.run_handoff().owned_cards.size() == 8 and game.snapshot() == expected, "RC-024: returned combat handoffs are detached model values, separate from presentation snapshots.")
	for fault in ["temporary", "duplicate", "missing", "encounter", "rng", "hp", "next_uid", "exhausted_uid", "seed", "extra_card_fields"]:
		entry = _entry(run)
		match fault:
			"temporary": entry.owned_cards[0].id = "free_spark"
			"duplicate": entry.owned_cards[0].uid = entry.owned_cards[1].uid
			"missing": entry.owned_cards.pop_back()
			"encounter": entry.encounter_id = "unknown"
			"rng": entry.rng_states.erase("kits")
			"hp": entry.player_hp = 31
			"next_uid": entry.next_uid = 2
			"exhausted_uid": entry.next_uid = 9223372036854775807
			"seed": entry.seed = -1
			"extra_card_fields": entry.owned_cards[0].temporary = true
		var untouched := entry.duplicate(true)
		var before := run.snapshot()
		var refused := Combat.create_for_run(setup, entry)
		check.call(not refused.ok and refused.combat == null and entry == untouched and run.snapshot() == before, "RC-024: incompatible %s handoff rejects without partial state or stream mutation." % fault)

func _win(game: Combat) -> bool:
	# A bounded terminal probe uses actual technique/cast/cleanup transitions.
	# Bring existing instances into hand; do not allocate replacement owned cards.
	game.hand.append_array(game.draw_pile)
	game.draw_pile.clear()
	game.board = Circuit.empty_board()
	var conjure: Dictionary = game.hand.filter(func(card): return card.id == "conjure")[0]
	if not game.play_technique(conjure.uid): return false
	var spark: Dictionary = game.hand.filter(func(card): return card.id == "spark")[0]
	if not game.place_rune(1, spark.uid): return false
	for placement in [[2, "split", 0], [3, "corner", 0], [6, "straight", 1], [7, "straight", 1], [10, "join", 0], [11, "corner", 1]]:
		if not game.place_wire(placement[0], placement[1]): return false
		for quarter in range(placement[2]):
			if not game.rotate(placement[0]): return false
	game.enemy_hp = 1
	return game.cast()

func _outcomes(check: Callable, setup: Dictionary) -> void:
	var run := RunState.new(setup)
	var before := run.snapshot()
	var game: Combat = run.enter_battle().combat
	check.call(not run.resolve_battle(game) and run.snapshot().status == "battle", "RC-024: a nonterminal battle cannot commit an encounter outcome.")
	game.player_hp = 17
	check.call(_win(game) and game.run_handoff().ok and game.state == "victory", "RC-024: actual lethal Cast completes production cleanup with a generated temporary present.")
	var outcome := game.run_handoff()
	check.call(outcome.owned_cards == before.owned_cards and outcome.owned_cards.all(func(card): return card.id != "free_spark"), "RC-024: generated Free Spark never becomes a run-owned card at the terminal boundary.")
	check.call(not run.quit_to_home(game) and run.resolve_battle(game), "RC-024: completed battle commits its outcome instead of discarding it into replay.")
	var committed := run.snapshot()
	check.call(committed.status == "encounter_won" and committed.player_hp == 17 and committed.player_max_hp == 30 and committed.owned_cards == before.owned_cards and committed.rng_states == outcome.rng_states, "RC-024: victory commits exact remaining HP, permanent identities and continued RNG once.")
	check.call(committed.completed_encounters == [setup.encounter.id] and not committed.tower_completed and not committed.can_continue and committed.gold == 0 and committed.relics.is_empty(), "RC-024: Shadeling fixture victory is encounter progress only, with no tower victory, rewards or invented route.")
	check.call(not run.resolve_battle(game) and not run.enter_battle().ok and not run.continue_battle().ok and run.snapshot() == committed, "RC-024: duplicate outcomes and repeated completed-fixture entry are atomic rejections.")
	run = RunState.new(setup)
	game = run.enter_battle().combat
	while game.state == "playing": game.pass_turn()
	check.call(run.resolve_battle(game) and run.snapshot().status == "defeated" and run.snapshot().player_hp == 0 and run.snapshot().owned_cards == before.owned_cards and run.snapshot().completed_encounters.is_empty(), "RC-024: defeat commits zero HP and unchanged permanent ownership without completion or replay.")

func _rejected_handoffs(check: Callable, setup: Dictionary) -> void:
	for fault in ["duplicate", "missing", "changed_uid", "changed_id", "catalog", "ownership", "health", "early_terminal", "zero_player_playing", "zero_enemy_playing", "regressed_uid", "exhausted_uid", "temporary_draw", "temporary_discard"]:
		var run := RunState.new(setup)
		var game: Combat = run.enter_battle().combat
		match fault:
			"duplicate": game.hand.append(game.hand[0].duplicate(true))
			"missing": game.hand.pop_back()
			"changed_uid": game.hand[0].uid = 100
			"changed_id": game.hand[0].id = "shield" if game.hand[0].id != "shield" else "spark"
			"catalog": game.catalog.spark.value = 999
			"ownership": game.owned_cards.append("spark")
			"health": game.encounter.player_max_health = 999
			"early_terminal": game.state = "victory"
			"zero_player_playing": game.player_hp = 0
			"zero_enemy_playing": game.enemy_hp = 0
			"regressed_uid": game.next_uid = 2
			"exhausted_uid": game.next_uid = 9223372036854775807
			"temporary_draw": game.draw_pile.append(game._card("free_spark"))
			"temporary_discard": game.discard_pile.append(game._card("free_spark"))
		var before := run.snapshot()
		var combat_before := game.snapshot()
		var streams_before := [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]
		check.call(not game.run_handoff().ok and not run.resolve_battle(game) and not run.quit_to_home(game) and run.snapshot() == before and game.snapshot() == combat_before and streams_before == [game.rng.state, game.endpoint_rng.state, game.kit_rng.state], "RC-024: live %s corruption rejects before outcome, exit, identity or RNG mutation." % fault)
