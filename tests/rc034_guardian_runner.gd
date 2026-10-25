extends SceneTree
## Supplemental mechanics probes only. Bell Keeper's shipped definition and
## production rules stay unchanged. Before construction, isolated documents
## give this probe 1000 HP and eight explicit variable-damage test cards. These
## are not route content or production playability evidence. Generated boards,
## stock, placement, payment, Cast and Pass still use legal controller actions.
const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Documents = preload("res://tests/production_content_tests.gd")
const Walk = preload("res://tests/helpers/rc033_fixture.gd")
const PATH := "res://data/production_bell_keeper_encounter.json"
const DESTINATION := "res://output/qa/rc-034/guardian"
var checks := 0
var failures := 0
var assertions: Array = []
var cases: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _probe(damage: int, shield := 0, hp := 1000) -> Dictionary:
	var source := Documents.documents()
	source.encounter = Loader.read_document(PATH).document
	source.runes.append({"id": "rc034_boundary_probe", "name": "Excluded mechanics probe", "symbol": "*", "cost": 1,
		"type": "rune", "effect": "damage_shield", "value": {"damage": damage, "shield": shield}, "color": "#efb553"})
	source.loadouts[0].max_health = 1000
	source.loadouts[0].current_health = hp
	source.loadouts[0].owned_cards.fill("rc034_boundary_probe")
	var source_before := source.duplicate(true)
	var loaded := Loader.validate_documents(source, {}, null, Rules.production_options(Rules.load_rules().rules))
	check(loaded.ok and source == source_before, "Supplemental probe validates before launch without mutating source documents.")
	var base := Loader.load_setup(PATH)
	for key in ["id", "enemy_id", "board_id", "max_health", "intents", "phase_two"]:
		check(loaded.setup.encounter[key] == base.setup.encounter[key], "Probe retains shipped Bell Keeper " + key + ".")
	var game := Combat.new(loaded.setup)
	var controller := Controller.new(game)
	var commands: Array = []
	controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
	return {"game": game, "controller": controller, "commands": commands, "entry": game.snapshot(),
		"probe": {"damage": damage, "shield": shield, "player_health": hp, "player_max_health": 1000}}

func _prepare(controller) -> bool:
	var snapshot: Dictionary = controller.snapshot()
	var begin := -1
	var end := -1
	for cell in 16:
		if snapshot.board[cell].get("kind") == "begin": begin = cell
		elif snapshot.board[cell].get("kind") == "end": end = cell
	var paths: Array = []
	Walk._walk([begin], end, paths)
	paths.sort_custom(func(first, second): return first.size() < second.size())
	var selected: Array = []
	var rune_cell := -1
	for path in paths:
		var straights: Array = []
		var corners := 0
		for index in range(1, path.size() - 1):
			if (Walk._direction(path[index], path[index - 1]) + 2) % 4 == Walk._direction(path[index], path[index + 1]): straights.append(path[index])
			else: corners += 1
		if not straights.is_empty() and straights.size() - 1 <= int(snapshot.stock.straight) and corners <= int(snapshot.stock.corner):
			selected = path
			rune_cell = straights[0]
			break
	if selected.is_empty(): return false
	for index in selected.size():
		var cell: int = selected[index]
		var ports: Array = []
		if index > 0: ports.append(Walk._direction(cell, selected[index - 1]))
		if index + 1 < selected.size(): ports.append(Walk._direction(cell, selected[index + 1]))
		ports.sort()
		if index > 0 and index < selected.size() - 1:
			if cell == rune_cell:
				if not controller.command("place_rune", {"index": cell, "uid": snapshot.hand[0].uid}): return false
			elif not controller.command("place_wire", {"index": cell, "kind": "straight" if (ports[0] + 2) % 4 == ports[1] else "corner"}): return false
		for rotation in 4:
			if Circuit.logical_ports(controller.snapshot().board[cell]) == ports: break
			if not controller.command("rotate", {"index": cell}): return false
	return controller.snapshot().forecast.valid

func _events(result: Dictionary, type: String) -> Array:
	return result.events.filter(func(event): return event.type == type)

func _rng(game) -> Array:
	return [game.rng.state, game.endpoint_rng.state, game.kit_rng.state]

func _retain(probe: Dictionary, label: String) -> void:
	cases.append({"label": label, "probe": probe.probe, "entry": probe.entry, "commands": probe.commands,
		"final": probe.controller.snapshot(), "last_result": probe.game.last_result()})
	probe.controller.dispose()

func _run() -> void:
	_thresholds()
	_shields()
	_terminal()
	_rejections()
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks,
		"failures": failures, "assertions": assertions, "scope": "Supplemental enhanced pre-launch mechanics probes; not production balance"}, "  ") + "\n")
	FileAccess.open(DESTINATION.path_join("probe-commands.json"), FileAccess.WRITE).store_string(JSON.stringify(cases, "  ") + "\n")
	print("RC-034 guardian: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _thresholds() -> void:
	for position in 3:
		for damage in [39, 40, 41]:
			var p := _probe(damage)
			var c = p.controller
			var g = p.game
			for skip in position: check(c.command("pass"), "Legal Pass advances phase-one sequence.")
			var immutable: Dictionary = g.encounter.duplicate(true)
			check(_prepare(c), "Generated board supports legally prepared boundary probe.")
			var before: Dictionary = c.snapshot()
			check(c.command("cast"), "Boundary Cast accepted.")
			var result: Dictionary = g.last_result()
			var crossed: bool = damage >= 40
			var phases := _events(result, "enemy_phase_changed")
			check(g.enemy_hp == 80 - damage and _events(result, "retaliation")[0].incoming == [8,12,16][position], "HP just above/at/below 40 preserves the announced retaliation at every sequence index.")
			check(g.encounter == immutable and phases.size() == (1 if crossed else 0) and g.enemy_action().phase == (2 if crossed else 1), "Only threshold crossing transitions; enemy configuration stays immutable.")
			check(_events(result, "damage").size() == 1 and _events(result, "damage")[0].amount == damage and _events(result, "damage")[0].applied == damage and result.events[0].spell.cost == 1, "One aggregate requested/applied damage and one physical rune cost.")
			if crossed:
				check(g.intent() == 12 and g.enemy_action().sequence_index == 0 and phases[0].before == before.enemy_action, "Every crossing starts phase two at first attack after preserving detached announcement.")
				var types: Array = result.events.map(func(event): return event.type)
				check(types.find("retaliation") < types.find("turn_cleanup") and types.find("turn_cleanup") < types.find("enemy_phase_changed") and types.find("enemy_phase_changed") < types.find("endpoints_changed") and types.find("kit_changed") < types.find("turn_started"), "Old attack and cleanup precede committed phase event and next-turn generation.")
				for expected in [16,20,12,16,20,12]:
					var old: int = g.intent()
					check(c.command("pass"), "Phase-two Pass is accepted.")
					var next: Dictionary = g.last_result()
					check(g.intent() == expected and _events(next, "retaliation")[0].incoming == old and _events(next, "enemy_phase_changed").is_empty(), "Phase two wraps without repeating threshold transition.")
			_retain(p, "threshold-position-%d-damage-%d" % [position, damage])

func _shields() -> void:
	for shield in [0,3,8,30]:
		var p := _probe(40, shield)
		check(_prepare(p.controller) and p.controller.command("cast"), "Threshold shield probe uses legal construction/Cast.")
		var result: Dictionary = p.game.last_result()
		var retaliation: Dictionary = _events(result, "retaliation")[0]
		check(retaliation.incoming == 8 and retaliation.blocked == mini(shield,8) and retaliation.applied == maxi(0,8-shield), "Zero/partial/full/excess shield blocks the old eight damage.")
		check(p.game.enemy_hp == 40 and p.game.intent() == 12 and p.game.enemy_action().phase == 2, "Shielding does not alter threshold or next announcement.")
		_retain(p, "shield-%d" % shield)

func _terminal() -> void:
	for damage in [80,120]:
		var p := _probe(damage,20)
		check(_prepare(p.controller), "Lethal probe prepares legal generated-board circuit.")
		var streams := _rng(p.game)
		check(p.controller.command("cast"), "Lethal Cast accepted.")
		var result: Dictionary = p.game.last_result()
		check(result.after.state == "victory" and result.after.enemy_hp == 0 and _events(result,"damage")[0].amount == damage and _events(result,"damage")[0].applied == 80, "Lethal/overkill keeps requested damage distinct from actual 80 HP loss.")
		check(not result.events.any(func(event): return event.type in ["shield","retaliation","enemy_phase_changed","turn_started","endpoints_changed","kit_changed","card_drawn"]), "Enemy lethal suppresses shield, retaliation, phase and all next-turn work.")
		check(_rng(p.game) == streams and result.after.turn == 1 and result.after.enemy_action.phase == 1, "Enemy lethal preserves phase/turn and random streams.")
		check(not p.controller.command("pass") and not p.controller.command("cast"), "Terminal guardian rejects gameplay callbacks.")
		_retain(p, "lethal-%d" % damage)
	var p := _probe(40,0,8)
	check(_prepare(p.controller), "Fatal retaliation probe prepares legally from explicit eight-HP entry.")
	var streams := _rng(p.game)
	check(p.controller.command("cast"), "Fatal retaliation Cast accepted.")
	var result: Dictionary = p.game.last_result()
	check(result.after.state == "defeat" and result.after.enemy_hp == 40 and result.after.player_hp == 0 and result.after.enemy_action.phase == 1, "Old eight attack kills player exactly at threshold without transitioning guardian.")
	check(_events(result,"turn_cleanup").size() == 1 and not result.events.any(func(event): return event.type in ["enemy_phase_changed","turn_started","endpoints_changed","kit_changed","card_drawn"]) and _rng(p.game) == streams, "Player defeat permits normal cleanup but suppresses every next-turn operation.")
	_retain(p,"player-defeat-at-threshold")

func _rejections() -> void:
	var p := _probe(40)
	var state: Dictionary = p.controller.snapshot()
	var streams := _rng(p.game)
	check(not p.controller.command("cast"), "Incomplete actual generated board rejects Cast.")
	check(p.game.enemy_action() == state.enemy_action and _rng(p.game) == streams and p.game.enemy_hp == 80, "Rejected action preserves phase, attack, HP and all random streams.")
	check(_prepare(p.controller), "Prepare real probe card after rejected action.")
	var detached: Dictionary = p.controller.snapshot()
	detached.enemy_action.next_sequence[0] = 999
	detached.encounter.phase_two.health_threshold = 1
	check(p.game.enemy_action().next_sequence == [12,16,20] and p.game.encounter.phase_two.health_threshold == 40, "Inspection snapshots cannot mutate actual guardian schema.")
	_retain(p,"rejection-and-detachment")
