extends RefCounted

const Fixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Route = preload("res://scripts/core/route_state.gd")
const Resolver = preload("res://scripts/core/encounter_resolver.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")

class BrokenResolver extends "res://scripts/core/encounter_resolver.gd":
	func _load(_node: Dictionary, _path: String) -> Dictionary:
		return {"ok": false, "errors": ["Explicit missing-content probe."]}

class ReentrantResolver extends "res://scripts/core/encounter_resolver.gd":
	var callback: Callable
	func resolve(node: Dictionary, entry: Dictionary) -> Dictionary:
		callback.call()
		return super(node, entry)

class AlteredEntryResolver extends Fixture.FixtureResolver:
	func resolve(node: Dictionary, entry: Dictionary) -> Dictionary:
		var result := super(node, entry)
		result.entry.player_hp = 1
		result.entry.rng_states.cards = 0
		result.entry.next_uid = 999
		return result

func run(check: Callable) -> void:
	_selection(check)
	_entry_failures(check)
	_transfer(check)
	_replay(check)
	_pending_and_defeat(check)

func _candidate(run, node_id: String = "d1a") -> Dictionary:
	return run.prepare_route_battle(run.request_room_entry(node_id).token)

func _enter(run, node_id: String = "d1a"):
	var candidate := _candidate(run, node_id)
	if not candidate.ok: return null
	return run.commit_route_battle(candidate).get("combat")

func _win(game) -> bool:
	var player := Player.new()
	var controller := Controller.new(game)
	for turn in range(40):
		if game.state != "playing": break
		if not player.play_turn(controller): return false
	controller.dispose()
	return game.state == "victory"

func _selection(check: Callable) -> void:
	var run := Run.new(Loader.load_setup().setup, 42, true)
	# The real normal roster is now registered. An unregistered substitution
	# retains the original unavailable-content/no-consumption boundary coverage.
	run._route._nodes.d1a.encounter_id = "unregistered_rc026_probe"
	var before: Dictionary = run.snapshot()
	var unavailable: Dictionary = run.prepare_route_battle(run.request_room_entry("d1a").token)
	check.call(not unavailable.ok and "not available" in unavailable.error and run.snapshot() == before, "RC-026/034: unregistered production encounter is explanatory and consumes no visit or run state.")
	var boss: Dictionary = run.inspect_node("d6")
	check.call(boss.enemy_id == "shadeling" and boss.encounter_role == "boss" and boss.depth == 6 and not boss.content_pending, "RC-026: Shadeling remains the supported depth-six boss; guardian stays separate.")
	var entry: Dictionary = run._entry_data()
	var resolved := Resolver.new().resolve(boss, entry)
	check.call(resolved.ok and resolved.setup.encounter.id == "training_shadeling" and resolved.setup.encounter.board_id == boss.board_id and resolved.setup.encounter.enemy_id == boss.enemy_id, "RC-026: selected production boss resolves its actual enemy, board and definition.")
	for key in ["enemy_id", "encounter_role", "board_id", "encounter_id"]:
		var wrong := boss.duplicate(true)
		wrong[key] = "missing"
		check.call(not Resolver.new().resolve(wrong, entry).ok and run.snapshot() == before, "RC-026: incompatible selected %s rejects before run mutation." % key)
	check.call(not Loader.load_selected_encounter("res://data/production_transition_encounter.json", "board_training").ok, "RC-026: route resolver rejects old chained definitions instead of expanding route progression.")
	var fixture = Fixture.new_run()
	check.call(not Route.validate_graph(fixture.route_snapshot()).ok and Route.validate_graph(Route.generate(42)).ok, "RC-026: test-only Wisp substitution cannot pass the unchanged production graph validator.")

func _entry_failures(check: Callable) -> void:
	var run = Fixture.new_run()
	var before: Dictionary = run.snapshot()
	var requested: Dictionary = run.request_room_entry("d1a")
	for field in ["run_id", "route_id", "node_id", "revision"]:
		var stale: Dictionary = requested.token.duplicate()
		stale[field] = -1 if field == "revision" else "wrong"
		check.call(not run.prepare_route_battle(stale).ok and run.snapshot() == before, "RC-026: stale %s candidate rejects without consuming route or streams." % field)
	var candidate: Dictionary = run.prepare_route_battle(requested.token)
	check.call(candidate.ok and run.snapshot() == before and run.current_battle() == null, "RC-026: full model construction leaves committed HP, collection, UID, RNG, route and checkpoint untouched.")
	check.call(not run.prepare_route_battle(requested.token).ok and not run.confirm_room_entry(requested.token, func(_n, _v): return {"ok": true}).ok, "RC-026: repeated or reentrant entry cannot allocate a second active candidate.")
	run.cancel_prepared_battle(candidate)
	check.call(run.snapshot() == before and not run.commit_route_battle(candidate).ok, "RC-026: failed scene attachment cancels the candidate and preserves a usable route.")
	candidate = run.prepare_route_battle(requested.token)
	var wrong_metadata: Dictionary = candidate.duplicate(true)
	wrong_metadata.setup.encounter.title = "Unrelated encounter label"
	check.call(not run.commit_route_battle(wrong_metadata).ok and run.snapshot() == before, "RC-026: altered scene configuration metadata cannot commit an unrelated view.")
	candidate.combat.pass_turn()
	check.call(not run.commit_route_battle(candidate).ok and run.snapshot() == before, "RC-026: mutated candidate cannot commit an already-played opening.")
	run.cancel_prepared_battle(candidate)
	candidate = run.prepare_route_battle(requested.token)
	var entered: Dictionary = run.commit_route_battle(candidate)
	check.call(entered.ok and run.snapshot().route.visit_count == 1 and run.current_battle() == candidate.combat, "RC-026: prepared model commits one unique visit and one initial draw.")
	var active: Dictionary = run.snapshot()
	check.call(not run.commit_route_battle(candidate).ok and not run.confirm_room_entry(requested.token).ok and run.snapshot() == active, "RC-026: duplicate commit and rejected route calls preserve composed active battle status.")
	var broken := Run.new(Loader.load_setup().setup, 42, true,
		func(id, seed): return Fixture.FixtureRoute.new(id, seed), BrokenResolver.new())
	before = broken.snapshot()
	check.call(not _candidate(broken).ok and broken.snapshot() == before, "RC-026: loader failure preserves route eligibility and all committed values.")
	var resolver := ReentrantResolver.new()
	var reentrant := Run.new(Loader.load_setup().setup, 42, true,
		func(id, seed): return Fixture.FixtureRoute.new(id, seed), resolver)
	var token: Dictionary = reentrant.request_room_entry("d1a").token
	var attempt := {"rejected": false}
	resolver.callback = func(): attempt.rejected = not reentrant.prepare_route_battle(token).ok
	candidate = reentrant.prepare_route_battle(token)
	check.call(candidate.ok and attempt.rejected and reentrant.route_snapshot().visit_count == 0, "RC-026: resolver reentrancy is rejected while outer candidate stays uncommitted.")
	reentrant.cancel_prepared_battle(candidate)
	resolver.callback = Callable()
	var authoritative := Run.new(Loader.load_setup().setup, 42, true,
		func(id, seed): return Fixture.FixtureRoute.new(id, seed), AlteredEntryResolver.new())
	candidate = _candidate(authoritative)
	check.call(candidate.ok and candidate.combat.player_hp == 30 and candidate.combat.next_uid == 8 and candidate.combat.snapshot() == _candidate(Fixture.new_run()).combat.snapshot(), "RC-026: resolver cannot replace authoritative carried health, allocator or random streams.")
	authoritative.cancel_prepared_battle(candidate)

func _transfer(check: Callable) -> void:
	var run = Fixture.new_run()
	var initial: Dictionary = run.snapshot()
	var first = _enter(run)
	check.call(first != null and first.encounter.enemy_id == "dev_calibration_wisp" and first.encounter.board_id == "board_gallery" and first.encounter.energy_per_turn == 4 and first.encounter.draw_per_turn == 2, "RC-026: first real fixture battle resolves Wisp, gallery and existing 4-energy/2-draw configuration.")
	if first == null: return
	var first_identity: Dictionary = run.snapshot().active_battle
	check.call(_win(first) and first.run_handoff().ok, "RC-026: first encounter genuinely wins through legal controller commands and terminal cleanup.")
	var handoff: Dictionary = first.run_handoff()
	check.call(handoff.next_uid > initial.next_uid and handoff.player_hp < initial.player_hp and handoff.owned_cards == initial.owned_cards, "RC-026: actual play takes damage and generates temporaries without changing permanent ownership.")
	var terminal_route: Dictionary = run.route_snapshot()
	var original: Dictionary = first.discard_pile[0].duplicate()
	first.discard_pile[0].uid = 99999
	var corrupt: Dictionary = run.snapshot()
	check.call(not run.resolve_battle(first) and run.snapshot() == corrupt and run.route_snapshot() == terminal_route, "RC-026: a corrupt terminal handoff retains recoverable battle/result state without partial route commit.")
	first.discard_pile[0] = original
	check.call(run.resolve_battle(first) and run.snapshot().status == "result_pending" and run.snapshot().route.completed_count == 1, "RC-026: matching real terminal outcome commits run and route together, retaining acknowledgement.")
	var result: Dictionary = run.snapshot()
	check.call(result.player_hp == handoff.player_hp and result.player_max_hp == 30 and result.next_uid == handoff.next_uid and result.rng_states == handoff.rng_states and result.gold == 0 and result.relics.is_empty(), "RC-026: outcome retains exact health, UID allocator and all streams without rewards or healing.")
	check.call(not run.resolve_battle(first) and not run.resolve_room(first_identity.run_id, first_identity.node_id, first_identity.visit_id, "completed") and not run.complete_room_choice(first_identity.run_id, first_identity.node_id, first_identity.visit_id, "encounter_rewards") and run.snapshot() == result, "RC-026: duplicate terminal and stale route callbacks cannot overwrite pending result or unlock again.")
	check.call(not run.acknowledge_result({}) and run.snapshot() == result, "RC-026: wrong result identity cannot acknowledge another visit.")
	check.call(run.acknowledge_result(result.pending_result.identity) and run.snapshot().status == "route_ready", "RC-026: explicit reward-free fixture acknowledgement returns to progression.")
	var next: String = run.inspect_node("d1a").next_ids[0]
	var candidate: Dictionary = _candidate(run, next)
	var second = candidate.combat
	var expected_entry: Dictionary = run._entry_data()
	expected_entry.encounter_id = second.encounter.id
	expected_entry.battle_identity = candidate.identity
	var expected: Dictionary = Combat.create_for_run(candidate.setup, expected_entry)
	check.call(expected.ok and expected.combat.snapshot() == second.snapshot() and run.commit_route_battle(candidate).ok, "RC-026: next battle uses ascending original UIDs and exactly the normal shuffle/draw from continuing streams.")
	var second_identity: Dictionary = run.snapshot().active_battle
	check.call(second.encounter.id == first.encounter.id and second_identity.visit_id != first_identity.visit_id and second_identity.generation != first_identity.generation, "RC-026: repeated encounter definition has a distinct node, visit and active model generation.")
	check.call(second.player_hp == handoff.player_hp and second.encounter.player_max_health == 30 and second.energy == 3 and second.hand.size() == 3 and second.encounter.board_id == "board_ossuary", "RC-026: second loadout changes energy/draw and selected board without adopting its starting health.")
	check.call(second.turn == 1 and second.history.is_empty() and second.discard_pile.is_empty() and second.board.filter(func(piece): return piece.is_empty()).size() == 14 and second.run_handoff().owned_cards == initial.owned_cards, "RC-026: next encounter has only endpoints, fresh kit, clean zones and no temporary carryover.")
	var before: Dictionary = run.snapshot()
	check.call(not run.resolve_battle(first) and not run.quit_to_home(first) and run.snapshot() == before, "RC-026: prior encounter callbacks cannot complete or quit the second battle.")
	check.call(_win(second) and run.resolve_battle(second), "RC-026: a second consecutive real Combat victory commits through the same route boundary.")
	check.call(run.snapshot().route.completed_count == 2 and run.snapshot().completed_encounters == [first.encounter.id, second.encounter.id] and not run.snapshot().tower_completed, "RC-026: two wins record two visits, never a boss or tower completion shortcut.")
	check.call(run.route_snapshot().route_rng_state == initial.route.route_rng_state, "RC-026: both Combats leave independent route RNG unchanged.")

func _replay(check: Callable) -> void:
	var run = Fixture.new_run()
	var game = _enter(run)
	var opening: Dictionary = game.snapshot()
	var identity: Dictionary = run.snapshot().active_battle
	var route: Dictionary = run.route_snapshot()
	game.pass_turn()
	var after: Dictionary = game.snapshot()
	var after_rng: Dictionary = game.run_handoff().rng_states
	check.call(run.continue_battle().combat == game and game.snapshot() == after, "RC-026: live Resume returns exact model and preparation without RNG consumption.")
	check.call(run.quit_to_home(game) and run.snapshot().status == "replay_pending" and run.route_snapshot() == route, "RC-026: confirmed Quit retains node/visit and entry checkpoint without route changes.")
	var pending: Dictionary = run.snapshot()
	check.call(not run.resolve_room(identity.run_id, identity.node_id, identity.visit_id, "completed") and not run.confirm_room_entry({}).ok and run.snapshot() == pending, "RC-026: rejected route calls cannot erase replay ownership.")
	var replay_candidate: Dictionary = run.prepare_continue_battle()
	check.call(replay_candidate.ok and run.snapshot() == pending and replay_candidate.combat.snapshot() == opening, "RC-026: exact replay prepares the stored opening without advancing committed state.")
	run.cancel_prepared_battle(replay_candidate)
	check.call(run.snapshot() == pending and not run.commit_continue_battle(replay_candidate).ok, "RC-026: replay attachment failure leaves the same replay checkpoint recoverable.")
	replay_candidate = run.prepare_continue_battle()
	check.call(run.commit_continue_battle(replay_candidate).ok, "RC-026: attached replay commits once.")
	var replay = run.current_battle()
	check.call(replay != game and replay.snapshot() == opening and run.snapshot().active_battle.visit_id == identity.visit_id and run.snapshot().active_battle.generation != identity.generation and run.route_snapshot() == route, "RC-026: replay replaces model generation while preserving exact entry, selected node and same visit.")
	replay.pass_turn()
	check.call(replay.snapshot() == after and replay.run_handoff().rng_states == after_rng, "RC-026: replay reproduces subsequent cards, endpoints and kit stream sequence.")
	var before: Dictionary = run.snapshot()
	check.call(not run.resolve_battle(game) and not run.quit_to_home(game) and run.snapshot() == before, "RC-026: orphaned replay callbacks cannot mutate the current battle.")

func _pending_and_defeat(check: Callable) -> void:
	var run = Fixture.new_run(42, true)
	var game = _enter(run)
	check.call(_win(game) and run.resolve_battle(game), "RC-026: production reward policy commits a real victory with pending choices.")
	var result: Dictionary = run.snapshot()
	var identity: Dictionary = result.pending_result.identity
	check.call(result.pending_result.pending_choices == ["encounter_rewards"] and result.route.status == "pending_choices" and result.route.completed_count == 0 and result.route.nodes.filter(func(node): return node.state == "available").is_empty(), "RC-026: required choices remain pending; no rewards are invented and successors stay locked.")
	check.call(run.acknowledge_result(identity) and run.snapshot().status == "pending_choices" and not run.prepare_continue_battle().ok, "RC-026: acknowledged pending choices cannot replay terminal battle.")
	check.call(not run.complete_room_choice(identity.run_id, identity.node_id, identity.visit_id, "encounter_rewards") and run.snapshot().status == "pending_choices", "RC-027: unresolved reward requirements cannot bypass their authoritative transaction through the generic choice API.")
	run = Fixture.new_run()
	game = _enter(run)
	var before: Dictionary = run.snapshot()
	game.hand.append(game.hand[0].duplicate(true))
	check.call(not run.resolve_battle(game) and run.route_snapshot() == before.route and run.snapshot().status == "battle", "RC-026: corrupt handoff rejects atomically without unlocking its route.")
	game.hand.pop_back()
	while game.state == "playing": game.pass_turn()
	check.call(run.resolve_battle(game) and run.snapshot().pending_result.outcome == "defeat" and run.snapshot().route.completed_count == 0 and run.snapshot().player_hp == 0, "RC-026: actual Pass defeat commits zero HP and no completed visit.")
	result = run.snapshot()
	check.call(run.acknowledge_result(result.pending_result.identity) and run.snapshot().status == "defeated" and not run.snapshot().can_continue and run.route_snapshot().nodes.filter(func(node): return node.state == "available").is_empty(), "RC-026: acknowledged defeat ends continuation and never unlocks successors.")
