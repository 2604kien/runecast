extends RefCounted

const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const ProductionContent = preload("res://tests/production_content_tests.gd")

static func documents(damage: int = 40, shield: int = 0) -> Dictionary:
	var source := ProductionContent.documents()
	source.enemies.append({"id": "rc033_core_target", "name": "RC-033 core fixture", "max_health": 80,
		"intents": [8, 12, 16], "phase_two": {"health_threshold": 40, "intents": [12, 16, 20]}})
	source.runes.append({"id": "rc033_probe", "name": "RC-033 probe", "symbol": "*", "cost": 1,
		"type": "rune", "effect": "damage_shield", "value": {"damage": damage, "shield": shield}, "color": "#efb553"})
	source.encounter.id = "rc033_core_encounter"
	source.encounter.enemy_id = "rc033_core_target"
	source.loadouts[0].max_health = 1000
	source.loadouts[0].current_health = 1000
	source.loadouts[0].energy_per_turn = 20
	source.loadouts[0].owned_cards = ["rc033_probe", "rc033_probe", "rc033_probe", "rc033_probe", "rc033_probe", "rc033_probe", "rc033_probe", "rc033_probe"]
	return source

static func validated(source: Dictionary) -> Dictionary:
	return Loader.validate_documents(source, {}, null, Rules.production_options(Rules.load_rules().rules))

static func entry(setup: Dictionary, rank: int = 0, relics: Array = []) -> Dictionary:
	var cards: Array = []
	for id in setup.owned_cards:
		cards.append({"id": id, "uid": cards.size(), "upgrade_rank": rank})
	var streams := {}
	for key in ["cards", "endpoints", "kits"]:
		var random := RandomNumberGenerator.new()
		random.seed = 42
		streams[key] = random.state
	return {"version": 1, "run_id": "rc033_core_run", "encounter_id": setup.encounter.id, "seed": 42,
		"owned_cards": cards, "next_uid": cards.size(), "relics": relics.duplicate(),
		"player_hp": setup.encounter.player_health, "player_max_hp": setup.encounter.player_max_health,
		"rng_states": streams, "battle_identity": {"run_id": "rc033_core_run", "route_id": "rc033_route",
			"node_id": "guardian", "visit_id": "visit_1", "generation": 1}}

static func prepare(game: Combat, split: bool = false) -> bool:
	# A controlled circuit topology isolates model boundaries; cards are genuine
	# dealt instances and all placement/payment/consumption uses ordinary commands.
	game.board = Circuit.demo_board() if split else Circuit.empty_board()
	if not split:
		game.board[14] = {}
		game.board[0] = {"kind": "begin", "rotation": 0}
		game.board[2] = {"kind": "end", "rotation": 3}
	game.board[1] = {}
	return game.place_rune(1, game.hand[0].uid)

func run(check: Callable) -> void:
	_validation(check)
	_legacy(check)
	_boundaries(check)
	_shields_and_terminal(check)
	_rejections_and_detachment(check)
	_run_and_replay(check)
	_upgrades(check)
	_successors(check)

func _new(source: Dictionary) -> Combat:
	return Combat.new(validated(source).setup)

func _events(result: Dictionary, kind: String) -> Array:
	return result.events.filter(func(event): return event.type == kind)

func _rng(game: Combat) -> Array:
	return [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]

func _validation(check: Callable) -> void:
	var source := documents()
	var original := source.duplicate(true)
	var loaded := validated(source)
	check.call(loaded.ok and loaded.setup.encounter.phase_two == {"health_threshold": 40, "intents": [12, 16, 20]} and source == original, "RC-033: optional phase data validates and normalizes without mutating raw documents.")
	var invalid: Array = [
		["phase array", func(d): d.enemies[-1].phase_two = []],
		["phase null", func(d): d.enemies[-1].phase_two = null],
		["phase bool", func(d): d.enemies[-1].phase_two = true],
		["phase string", func(d): d.enemies[-1].phase_two = "40"],
		["missing threshold", func(d): d.enemies[-1].phase_two.erase("health_threshold")],
		["missing next sequence", func(d): d.enemies[-1].phase_two.erase("intents")],
		["third phase", func(d): d.enemies[-1].phase_two.phase_two = {"health_threshold": 20, "intents": [99]}],
		["phase metadata", func(d): d.enemies[-1].phase_two.type = "guardian"],
		["alternate phases", func(d): d.enemies[-1].phases = []],
		["structured attack", func(d): d.enemies[-1].phase_two.intents = [{"damage": 12}]],
		["empty attacks", func(d): d.enemies[-1].phase_two.intents = []],
		["too many attacks", func(d): d.enemies[-1].phase_two.intents = range(101)],
		["sequence string", func(d): d.enemies[-1].phase_two.intents = "12,16,20"],
		["fractional attack", func(d): d.enemies[-1].phase_two.intents[0] = 1.5],
		["boolean attack", func(d): d.enemies[-1].phase_two.intents[0] = true],
		["negative attack", func(d): d.enemies[-1].phase_two.intents[0] = -1],
		["huge attack", func(d): d.enemies[-1].phase_two.intents[0] = Loader.MAX_HEALTH + 1],
		["nonfinite attack", func(d): d.enemies[-1].phase_two.intents[0] = INF],
		["null attack", func(d): d.enemies[-1].phase_two.intents[0] = null],
		["fractional threshold", func(d): d.enemies[-1].phase_two.health_threshold = 40.5],
		["boolean threshold", func(d): d.enemies[-1].phase_two.health_threshold = true],
		["zero threshold", func(d): d.enemies[-1].phase_two.health_threshold = 0],
		["negative threshold", func(d): d.enemies[-1].phase_two.health_threshold = -1],
		["maximum threshold", func(d): d.enemies[-1].phase_two.health_threshold = 80],
		["excess threshold", func(d): d.enemies[-1].phase_two.health_threshold = 81],
		["malformed maximum", func(d): d.enemies[-1].max_health = []],
		["fractional maximum", func(d): d.enemies[-1].max_health = 80.5],
		["empty first sequence", func(d): d.enemies[-1].intents = []],
		["fractional first attack", func(d): d.enemies[-1].intents[0] = 1.5],
		["unsupported action", func(d): d.enemies[-1].intents[0] = {"defend": 10}]
	]
	for specimen in invalid:
		var raw := source.duplicate(true)
		specimen[1].call(raw)
		var before := raw.duplicate(true)
		var result := validated(raw)
		check.call(not result.ok and result.setup.is_empty() and not result.errors.is_empty() and raw == before, "RC-033: rejects %s before publication with actionable errors and untouched input." % specimen[0])
	var zeroes := source.duplicate(true)
	zeroes.enemies[-1].intents = [0.0, 8.0]
	zeroes.enemies[-1].phase_two.intents = [0.0, Loader.MAX_HEALTH]
	zeroes.enemies[-1].phase_two.health_threshold = 1.0
	loaded = validated(zeroes)
	check.call(loaded.ok and loaded.setup.encounter.intents == [0, 8] and loaded.setup.encounter.phase_two.intents == [0, Loader.MAX_HEALTH] and loaded.setup.encounter.phase_two.health_threshold is int, "RC-033: JSON-compatible whole-number values normalize; zero attacks and threshold one remain valid.")

func _legacy(check: Callable) -> void:
	for path in [Loader.DEFAULT_ENCOUNTER, Loader.LEGACY_ENCOUNTER]:
		var loaded := Loader.load_setup(path)
		var setup: Dictionary = loaded.setup
		check.call(loaded.ok and setup.encounter.max_health == 32 and setup.encounter.intents == [8, 12, 6] and not setup.encounter.has("phase_two"), "RC-033: %s retains Shadeling identity, HP, sequence and no-phase configuration shape." % path)
		setup.encounter.player_health = 1000
		setup.encounter.player_max_health = 1000
		var game := Combat.new(setup)
		for index in range(9):
			var action := game.enemy_action()
			check.call(game.intent() == [8, 12, 6][index % 3] and action.amount == game.intent() and action.sequence_index == index % 3 and action.phase == 1 and action.phase_count == 1 and not action.has("health_threshold"), "RC-033: legacy first intent and wrap %d remain truthful." % index)
			var result := game.execute("pass")
			check.call(_events(result, "enemy_phase_changed").is_empty() and _events(result, "retaliation")[0].incoming == action.amount, "RC-033: legacy Pass resolves its announced scalar and has no phase event.")

func _boundaries(check: Callable) -> void:
	for position in range(3):
		for damage in [39, 40, 41]:
			var source := documents(damage)
			var game := _new(source)
			for skip in range(position): game.execute("pass")
			var immutable := game.encounter.duplicate(true)
			check.call(prepare(game), "RC-033: boundary probe places a real dealt card.")
			var announced := game.enemy_action()
			var result := game.execute("cast")
			var transition: bool = damage >= 40
			var phases := _events(result, "enemy_phase_changed")
			check.call(result.accepted and game.enemy_hp == 80 - damage and _events(result, "retaliation")[0].incoming == [8, 12, 16][position], "RC-033: position %d HP%d retains original announced retaliation after damage." % [position, game.enemy_hp])
			check.call(game.enemy_action().phase == (2 if transition else 1) and phases.size() == (1 if transition else 0) and game.encounter == immutable, "RC-033: just-above/exact/below threshold %d transitions only when eligible without config mutation." % game.enemy_hp)
			if transition:
				check.call(game.intent() == 12 and game.enemy_action().sequence_index == 0 and phases[0].before == announced and phases[0].after == game.enemy_action() and phases[0].enemy_hp == game.enemy_hp, "RC-033: phase two begins at index zero independently of the prior turn modulo.")
				var types: Array = result.events.map(func(event): return event.type)
				check.call(types.find("retaliation") < types.find("turn_cleanup") and types.find("turn_cleanup") < types.find("enemy_phase_changed") and types.find("enemy_phase_changed") < types.find("endpoints_changed") and types.find("endpoints_changed") < types.find("kit_changed") and types.find("kit_changed") < types.find("turn_started") and types.find("turn_started") < types.find("card_drawn"), "RC-033: old retaliation, cleanup, committed phase change, geometry, kit, turn and draws stay ordered.")
				for expected in [16, 20, 12, 16, 20, 12]:
					var old := game.intent()
					var next := game.execute("pass")
					check.call(game.intent() == expected and _events(next, "enemy_phase_changed").is_empty() and _events(next, "retaliation")[0].incoming == old and _events(next, "turn_started")[0].enemy_action == game.enemy_action(), "RC-033: phase two advances/wraps without retrigger and publishes the same next action.")
			var plain := source.duplicate(true)
			plain.enemies[-1].erase("phase_two")
			var comparison := _new(plain)
			for skip in range(position): comparison.execute("pass")
			prepare(comparison)
			comparison.execute("cast")
			if transition:
				for skip in range(6): comparison.execute("pass")
			check.call(_rng(game) == _rng(comparison) and game.hand == comparison.hand and game.draw_pile == comparison.draw_pile, "RC-033: deterministic phase cycling consumes no additional card, geometry or kit RNG.")

func _shields_and_terminal(check: Callable) -> void:
	for shield in [0, 3, 8, 30]:
		var game := _new(documents(40, shield))
		prepare(game)
		var result := game.execute("cast")
		var hit: Dictionary = _events(result, "retaliation")[0]
		check.call(hit.incoming == 8 and hit.blocked == mini(shield, 8) and hit.applied == maxi(0, 8 - shield) and game.intent() == 12 and game.enemy_action().phase == 2, "RC-033: threshold crossing uses old attack with zero/partial/full/over shielding %d." % shield)
	var zero_source := documents(0, 8)
	zero_source.enemies[-1].intents = [0]
	var zero := _new(zero_source)
	prepare(zero)
	var result := zero.execute("cast")
	check.call(result.accepted and _events(result, "damage").size() == 1 and _events(result, "damage")[0].amount == 0 and _events(result, "damage")[0].applied == 0 and _events(result, "retaliation")[0].incoming == 0 and zero.enemy_action().phase == 1 and _events(result, "enemy_phase_changed").is_empty(), "RC-033: zero damage still emits one aggregate damage; zero intent retaliates harmlessly without phase change.")
	zero_source = documents(40)
	zero_source.enemies[-1].intents = [0]
	zero_source.enemies[-1].phase_two.intents = [0, 1]
	zero = _new(zero_source)
	prepare(zero)
	zero.execute("cast")
	check.call(zero.player_hp == 1000 and zero.intent() == 0 and zero.enemy_action().phase == 2, "RC-033: zero attacks are supported in both phase sequences.")
	for damage in [80, 120]:
		var game := _new(documents(damage, 20))
		prepare(game)
		var streams := _rng(game)
		result = game.execute("cast")
		check.call(result.accepted and game.state == "victory" and game.enemy_hp == 0 and _events(result, "damage")[0].amount == damage and _events(result, "damage")[0].applied == 80 and _events(result, "shield").is_empty() and _events(result, "retaliation").is_empty() and _events(result, "enemy_phase_changed").is_empty(), "RC-033: lethal/overkill %d clamps actual loss and suppresses shield, retaliation and transition." % damage)
		check.call(game.enemy_action().phase == 1 and game.turn == 1 and _rng(game) == streams and _events(result, "turn_started").is_empty() and _events(result, "card_drawn").is_empty(), "RC-033: enemy lethal skips all next-turn state and RNG work.")
	var fatal_source := documents(40)
	fatal_source.loadouts[0].current_health = 8
	var fatal := _new(fatal_source)
	prepare(fatal)
	var fatal_rng := _rng(fatal)
	result = fatal.execute("cast")
	check.call(fatal.state == "defeat" and fatal.enemy_hp == 40 and fatal.player_hp == 0 and fatal.enemy_action().phase == 1 and _events(result, "enemy_phase_changed").is_empty() and _events(result, "turn_started").is_empty() and _rng(fatal) == fatal_rng, "RC-033: player lethal old retaliation suppresses transition and all next-turn work.")

func _rejections_and_detachment(check: Callable) -> void:
	var game := _new(documents())
	var initial := game.enemy_action()
	var streams := _rng(game)
	var before_turn := game.turn
	var result := game.execute("cast")
	check.call(not result.accepted and game.enemy_action() == initial and _rng(game) == streams and game.turn == before_turn, "RC-033: invalid Cast cannot advance phase/index/turn or RNG.")
	prepare(game)
	game.energy = 0
	result = game.execute("cast")
	check.call(not result.accepted and game.enemy_action() == initial and _rng(game) == streams and game.turn == before_turn and game.enemy_hp == 80, "RC-033: unaffordable Cast cannot alter intent, phase, health, turn or RNG.")
	game.energy = 20
	for count in range(20):
		var snapshot := game.snapshot()
		snapshot.enemy_action.sequence[0] = 999
		snapshot.enemy_action.next_sequence[0] = 999
		snapshot.enemy_action.amount = 999
		snapshot.encounter.phase_two.health_threshold = 1
	check.call(game.enemy_action() == initial and _rng(game) == streams and game.turn == before_turn and game.encounter.phase_two.health_threshold == 40, "RC-033: repeated detached snapshot inspection cannot mutate configuration, announced action or RNG.")
	result = game.execute("cast")
	var phase: Dictionary = _events(result, "enemy_phase_changed")[0]
	phase.after.sequence[0] = 999
	phase.after.next_sequence[0] = 999
	phase.before.amount = 999
	check.call(game.intent() == 12 and game.enemy_action().sequence == [12, 16, 20] and _events(game.last_result(), "enemy_phase_changed")[0].before.amount == 8, "RC-033: nested event payloads and retained last result are detached from callers and authority.")

func _run_and_replay(check: Callable) -> void:
	var setup: Dictionary = validated(documents()).setup
	var run_entry := entry(setup)
	var first_result := Combat.create_for_run(setup, run_entry)
	var second_result := Combat.create_for_run(setup, run_entry)
	check.call(first_result.ok and second_result.ok, "RC-033: phased configuration enters via validated production run ownership.")
	if not first_result.ok or not second_result.ok: return
	var first: Combat = first_result.combat
	var second: Combat = second_result.combat
	var opening := first.snapshot()
	for game in [first, second]:
		game.execute("pass")
		game.execute("pass")
		prepare(game)
	var before := first.snapshot()
	var result := first.execute("cast")
	var replay := second.execute("cast")
	check.call(before.enemy_action.amount == 16 and result == replay and first.snapshot() == second.snapshot() and _rng(first) == _rng(second), "RC-033: identical battle-entry/RNG and action sequence reproduce phase crossing and events exactly.")
	check.call(first.run_handoff().ok and first.encounter == setup.encounter and first.run_handoff().battle_identity == run_entry.battle_identity, "RC-033: switching phase keeps immutable configuration and run handoff identity valid.")
	prepare(first)
	var prepared := first.snapshot()
	var resume_reference := first
	check.call(resume_reference.snapshot() == prepared and resume_reference.enemy_action().phase == 2 and resume_reference.intent() == 12 and resume_reference.snapshot().undo_count > 0, "RC-033: retaining the live Combat owner preserves phase and prepared card/Undo state.")
	first.reset()
	check.call(first.enemy_action().phase == 1 and first.enemy_action().sequence_index == 0 and first.intent() == 8 and first.turn == 1 and first.enemy_hp == 80 and first.run_handoff().ok, "RC-033: ordinary reset initializes phase/index/announcement and keeps run ownership valid.")
	var fresh := Combat.create_for_run(setup, run_entry)
	check.call(fresh.ok and fresh.combat.snapshot() == opening, "RC-033: battle-entry replay reconstructs original phase one rather than saving mid-turn phase.")

func _upgrades(check: Callable) -> void:
	for id in ["spark", "cinder_guard"]:
		var source := documents()
		source.runes = Loader.read_document("res://tests/fixtures/rc035/runes-before.json").document
		source.runes.append_array(Loader.read_document("res://tests/fixtures/rc031/upgrade_framework_runes.json").document)
		source.loadouts[0].owned_cards.fill(id)
		var setup: Dictionary = validated(source).setup
		var run_entry := entry(setup, 1, ["relic_ember_lens", "relic_ward_seal"])
		var made := Combat.create_for_run(setup, run_entry)
		check.call(made.ok, "RC-033: upgraded %s run fixture validates." % id)
		if not made.ok: continue
		var game: Combat = made.combat
		var damage := 18 if id == "spark" else 14
		var shield := 0 if id == "spark" else 10
		for cast in range(3):
			prepare(game, true)
			var spell := game.forecast()
			var old_intent := game.intent()
			var result := game.execute("cast")
			check.call(result.accepted and spell.damage == damage and spell.shield == shield and spell.cost == 3 and _events(result, "damage").size() == 1 and _events(result, "damage")[0].amount == damage and _events(result, "retaliation")[0].incoming == old_intent, "RC-033: upgraded %s Split/Join aggregates and charges physical pieces once before final relic bonuses and announced retaliation." % id)
		check.call(game.enemy_action().phase == 2 and game.intent() == 12 and game.enemy_action().sequence_index == 0 and game.run_handoff().ok, "RC-033: upgraded %s threshold crossing starts phase two without altering rank/relic ownership." % id)

func _successors(check: Callable) -> void:
	for phased in [false, true]:
		var source := documents()
		var first: Dictionary = validated(source).setup
		source.encounter.id = "rc033_successor"
		if not phased: source.enemies[-1].erase("phase_two")
		var successor: Dictionary = validated(source).setup
		first.next_encounter = successor
		check.call(Loader.validate_transition(first, successor).ok, "RC-033: supported successor phase=%s validates." % phased)
		var game := Combat.new(first)
		for cast in range(2):
			prepare(game)
			game.execute("cast")
		check.call(game.state == "victory" and game.enemy_action().phase == 2, "RC-033: successor fixture completes prior battle in phase two.")
		var result := game.execute("next_encounter")
		check.call(result.accepted and game.enemy_action().phase == 1 and game.enemy_action().phase_count == (2 if phased else 1) and game.enemy_action().sequence_index == 0 and game.intent() == 8 and game.turn == 1 and game.enemy_hp == 80, "RC-033: successor phase=%s always enters at phase-one first intent." % phased)
