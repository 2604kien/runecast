extends SceneTree
## Each stage is launched by a NEW OS process. All files live under --save-root.
const Save = preload("res://scripts/core/local_save.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const RewardTests = preload("res://tests/reward_state_tests.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")

class GuardianRoute extends RewardTests.BossFixtureRoute:
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		# Explicit terminal-boundary fixture, not an implemented guardian/tower.
		_graph.route_id = "rc028_guardian_boundary_fixture-%d" % seed
		_nodes.d1a.room_id = "room_guardian"
		_nodes.d1a.room_type = "guardian"

var destination := ""
var stage := ""
var scenario := ""
var checks := 0
var failures := 0
var assertions: Array = []
var context: Dictionary = {}
var setup: Dictionary
var store
var subject
var profile
var revision := 0
var evidence: Dictionary = {}

func check(value: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": message})
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): destination = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
		if argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
	if destination.is_empty() or stage.is_empty() or scenario.is_empty():
		push_error("An explicit isolated save root, stage and scenario are required.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	setup = Loader.load_setup().setup
	context = _fixture_context() if scenario != "production" else {}
	store = Save.new(destination.path_join("active.json"), _validate)
	if FileAccess.file_exists(destination.path_join("expected.bin")):
		evidence = bytes_to_var(FileAccess.get_file_as_bytes(destination.path_join("expected.bin")))
	var loaded: Dictionary = store.load()
	check(loaded.ok, "Load validates coherent payload: " + str(loaded.get("error", "")))
	if not loaded.ok:
		_finish()
		return
	revision = int(loaded.get("revision", 0))
	if loaded.status == "valid":
		var restored := _restore(loaded.payload)
		check(restored.ok, "Fresh process restores model owners: " + str(restored.get("error", "")))
		if not restored.ok:
			_finish()
			return
		profile = restored.profile
		subject = restored.run
	_run_stage()
	_finish()

func _new_run(owner = null):
	if scenario == "production": return Run.new(setup, 9007199254740993, true, Callable(), null, Profile.production_rules(), owner if owner != null else Profile.new(setup.catalog))
	if scenario == "unlock" or scenario == "exhausted": return RewardTests.new()._boss_run(owner if owner != null else Profile.new(setup.catalog, ["spark"] if scenario == "unlock" else Profile.INITIAL_IDS))
	if scenario == "guardian": return Run.new(setup, 42, true, func(id, seed): return GuardianRoute.new(id, seed), RewardTests.RewardResolver.new(), Profile.production_rules(), owner if owner != null else Profile.new(setup.catalog))
	return Fixture.new_run(42)

func _fixture_context() -> Dictionary:
	var registry = _new_run()
	var result: Dictionary = registry.restore_context_for_tests()
	for id in ["d1a", "d2a", "d2b"]:
		var resolved: Dictionary = registry._resolver.resolve(registry._route._nodes[id], registry._entry_data())
		if resolved.get("ok", false): result.setups[Run.content_signature(resolved.setup)] = resolved.setup
	return result

func _restore(payload: Dictionary) -> Dictionary:
	var p: Dictionary = Profile.restore_save(payload.get("profile", {}), setup.catalog, scenario != "production")
	if not p.ok: return p
	if payload.get("run", {}).is_empty(): return {"ok": true, "profile": p.profile, "run": null}
	var r: Dictionary = Run.restore_save(payload.run, setup, p.profile, context)
	if not r.ok: return r
	return {"ok": true, "profile": p.profile, "run": r.run}

func _validate(payload: Dictionary) -> Dictionary:
	return _restore(payload)

func _save() -> bool:
	var payload := {"profile": profile.export_save(), "run": subject.export_save() if subject != null else {}}
	var committed: Dictionary = store.commit(payload, revision)
	check(committed.ok, "Durable candidate committed: " + str(committed.get("error", "")))
	if committed.ok: revision = committed.revision
	return committed.ok

func _enter(id: String = "d1a"):
	var requested: Dictionary = subject.request_room_entry(id)
	check(requested.ok, "Selected room has a fresh entry token.")
	if not requested.ok: return null
	var prepared: Dictionary = subject.prepare_route_battle(requested.token)
	check(prepared.ok, "Exact selected encounter prepares successfully.")
	if not prepared.ok: return null
	var committed: Dictionary = subject.commit_route_battle(prepared)
	check(committed.ok, "Prepared battle entry commits exactly one visit.")
	return committed.get("combat")

func _resume():
	var result: Dictionary = subject.continue_battle()
	check(result.ok, "Interrupted battle replays committed entry.")
	return result.get("combat")

func _run_stage() -> void:
	match stage:
		"new":
			check(subject == null, "Isolated fresh process has no active run.")
			subject = _new_run()
			profile = subject.profile_state()
			# Legal allocator gaps include generated temporaries; these explicit
			# fixture counters also exercise integers beyond JSON float precision.
			if scenario != "production":
				subject._next_uid = 9007199254740993
				subject._candidate_sequence = 9007199254740995
				subject._battle_generation = 9007199254740997
			evidence.exact = {"seed": subject.snapshot().seed, "next_uid": subject.snapshot().next_uid, "rng": subject.snapshot().rng_states}
			evidence.run_id = subject.snapshot().run_id
			evidence.route = subject.route_snapshot()
			_save()
		"route":
			check(subject.snapshot().run_id == evidence.run_id and subject.route_snapshot() == evidence.route, "Fresh route preserves run ID, raw graph, visits and random state across OS restart.")
			check(subject.snapshot().seed == evidence.exact.seed and subject.snapshot().next_uid == evidence.exact.next_uid and subject.snapshot().rng_states == evidence.exact.rng, "Seeds, RNG state and allocator beyond 2^53 restore exactly as native integers.")
			if scenario == "production":
				var before: Dictionary = subject.export_save()
				check(not subject.prepare_route_battle(subject.request_room_entry("d1a").token).ok and subject.export_save() == before, "Missing production content stays unavailable without consuming the saved choice.")
			else:
				var game = _enter()
				if game == null: return
				evidence.opening = game.snapshot()
				evidence.entry_handoff = game.run_handoff()
				_save()
		"interrupt":
			check(subject.snapshot().status == "replay_pending" and subject.route_snapshot().visit_count == 1, "Process restart retains selected visit and marks exact entry replay.")
			var game = _resume()
			if game == null: return
			check(game.snapshot() == evidence.opening, "Restored opening matches every live value before interruption.")
			var controller := Controller.new(game)
			var player := Player.new()
			check(player.play_turn(controller), "Ordinary played turn advances cards, endpoints and connector streams.")
			controller.dispose()
			check(game.run_handoff().rng_states != evidence.entry_handoff.rng_states and game.next_uid > evidence.entry_handoff.next_uid, "Interruption includes RNG advancement and temporary-card allocator gaps.")
			_save()
		"win":
			var game = _resume()
			if game == null: return
			check(game.snapshot() == evidence.opening, "Interrupted partial damage and temporaries do not carry into restored entry.")
			check(Integration.new()._win(game) and subject.resolve_battle(game), "Genuine ordinary Combat victory produces one authoritative result.")
			evidence.offer = subject.pending_reward()
			evidence.terminal = subject.snapshot()
			evidence.next_uid = subject.snapshot().next_uid
			_save()
		"result":
			check(subject.snapshot() == evidence.terminal and subject.current_battle() == null, "Committed victory opens pending result without replaying resolved Combat.")
			check(subject.pending_reward() == evidence.offer and subject.route_snapshot().status == "pending_choices", "Offer identity, eligible pool, offered IDs and successor lock survive restart.")
			check(subject.acknowledge_result(subject.snapshot().pending_result.identity), "Acknowledgement is a separate durable mutation.")
			_save()
		"first_claim":
			check(subject.snapshot().status == "pending_choices" and subject.pending_reward() == evidence.offer, "Acknowledged result restores direct pending-choice flow with exact offer.")
			var reward: Dictionary = subject.pending_reward()
			var result: Dictionary
			if scenario == "gold_first": result = subject.claim_reward_gold(reward.identity)
			elif scenario in ["unlock", "exhausted", "guardian", "skip"]: result = subject.skip_reward(reward.identity)
			else: result = subject.choose_reward(reward.identity, reward.offered_ids[0])
			check(result.ok, "First reward component commits once.")
			evidence.first = subject.snapshot()
			evidence.claim = result
			_save()
		"fail_claim":
			var before: Dictionary = subject.export_save()
			var cloned: Dictionary = subject.clone_for_transaction()
			check(cloned.ok, "A failed write stages all reward owners in a detached candidate.")
			var candidate = cloned.run
			var reward: Dictionary = subject.pending_reward()
			check(candidate.choose_reward(reward.identity, reward.offered_ids[0]).ok, "The intended reward is selected once before the injected durable failure.")
			evidence.failed_intent = {"profile": cloned.profile.export_save(), "run": candidate.export_save()}
			evidence.committed_before_failure = before
			store.failure_point = scenario.trim_prefix("failure_")
			var rejected: Dictionary = store.commit(evidence.failed_intent, revision)
			check(not rejected.ok and subject.export_save() == before, "Injected " + store.failure_point + " failure publishes no grant, allocator, receipt, route or profile change.")
		"retry_claim":
			check(subject.export_save() == evidence.committed_before_failure and subject.pending_reward() == evidence.offer, "Fresh process after interrupted " + scenario + " restores only the valid committed owners and stable offering.")
			var intended := _restore(evidence.failed_intent)
			check(intended.ok, "Retained intended candidate remains independently valid for Retry.")
			subject = intended.run
			profile = intended.profile
			_save()
			evidence.first = subject.snapshot()
		"claim_gold":
			check(subject.snapshot() == evidence.first and subject.snapshot().owned_cards.size() == 9, "Retry grant appears exactly once across the next restart.")
			var reward: Dictionary = subject.pending_reward()
			check(not subject.choose_reward(reward.identity, reward.offered_ids[0]).ok, "Already retried rune transaction cannot allocate a second instance.")
			check(subject.claim_reward_gold(reward.identity).ok, "Independent Gold component remains claimable after failed rune write and retry.")
			evidence.settled = subject.snapshot()
			_save()
		"second_claim":
			check(subject.snapshot() == evidence.first, "Partial reward claim restores with exact Gold, UID allocator and receipts.")
			var reward: Dictionary = subject.pending_reward()
			if scenario in ["exhausted", "guardian"]:
				check(reward.is_empty() and subject.snapshot().reward_records[1].resolution == "exhausted", "Exhausted milestone receipt remains settled with no compensation.")
				check(subject.snapshot().gold == 0 and subject.snapshot().owned_cards.size() == 8, "Exhaustion does not award Gold or owned copies.")
			elif scenario == "unlock":
				check(reward.kind == "definition_unlock" and not reward.offered_ids[0] in profile.snapshot().unlocked_definition_ids, "Fixture retains one genuine still-locked definition offer.")
				check(subject.choose_reward(reward.identity, reward.offered_ids[0]).ok, "Permanent acquisition unlocks definition without allocating a copy.")
			else:
				var result: Dictionary = subject.choose_reward(reward.identity, reward.offered_ids[0]) if scenario == "gold_first" else subject.claim_reward_gold(reward.identity)
				check(result.ok, "Second independently ordered reward component commits once.")
			evidence.settled = subject.snapshot()
			_save()
		"settled":
			check(subject.snapshot() == evidence.settled, "Settled reward receipts and ownership survive another process restart.")
			check(not subject.choose_reward(evidence.offer.identity, evidence.offer.offered_ids[0]).ok and not subject.claim_reward_gold(evidence.offer.identity).ok, "Old transaction identities cannot duplicate cards, Gold or unlocks.")
			if scenario == "guardian":
				check(subject.snapshot().status == "tower_completed" and not subject.snapshot().can_continue, "Terminal fixture completion never becomes playable after restart.")
			elif scenario in ["gold_first", "rune_first", "skip"] or scenario.begins_with("failure_"):
				var next_id: String = subject.inspect_node("d1a").next_ids[0]
				var game = _enter(next_id)
				if game == null: return
				var cards: Array = game.snapshot().hand + game.snapshot().draw_pile + game.snapshot().discard_pile
				check(cards.filter(func(card): return card.uid == evidence.next_uid).size() == (0 if scenario == "skip" else 1), "Awarded UID enters the next actual encounter exactly once; Skip adds none.")
				_save()
		"new_again":
			var previous_id: String = subject.snapshot().run_id
			var unlocks: Array = profile.snapshot().unlocked_definition_ids
			subject = _new_run(profile)
			profile = subject.profile_state()
			check(subject.snapshot().run_id != previous_id and subject.snapshot().owned_cards.size() == 8, "New Run obtains collision-resistant identity and unchanged eight-card starter.")
			check(profile.snapshot().unlocked_definition_ids == unlocks, "Profile definition acquisition survives restart and New Run.")
			evidence.new_profile = profile.snapshot()
			_save()
		"profile":
			check(profile.snapshot() == evidence.new_profile and subject.snapshot().owned_cards.size() == 8, "New run restores persistent eligibility without stored copies.")
		"retire_profile":
			check(profile.snapshot() == evidence.new_profile, "Profile-only checkpoint begins with the already persisted definition eligibility.")
			subject = null
			_save()
		"profile_only":
			check(subject == null and profile.snapshot() == evidence.new_profile, "A fresh OS process restores a valid profile without an active run or defaulted unlocks.")
			subject = _new_run(profile)
			profile = subject.profile_state()
			check(subject.snapshot().owned_cards.size() == 8 and profile.snapshot() == evidence.new_profile, "New Run from the profile-only save retains unlocks and exactly eight starter instances.")
			_save()
		"defeat":
			var game = _resume()
			if game == null: return
			while game.state == "playing": game.pass_turn()
			check(subject.resolve_battle(game), "Genuine defeat durably retains result without victory rewards.")
			_save()
		"defeated":
			check(subject.snapshot().pending_result.outcome == "defeat" and subject.snapshot().reward_records.is_empty(), "Fresh process restores defeat result with no rewards.")
			check(subject.acknowledge_result(subject.snapshot().pending_result.identity), "Defeat acknowledgement settles terminal route.")
			_save()
		"terminal":
			check(subject.snapshot().status == "defeated" and not subject.snapshot().can_continue and subject.current_battle() == null, "Acknowledged defeat cannot reopen Combat or rewards across restart.")
		_:
			check(false, "Unknown process stage: " + stage)

func _finish() -> void:
	FileAccess.open(destination.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(destination.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"scenario": scenario, "stage": stage, "process_id": OS.get_process_id(), "checks": checks, "failures": failures, "assertions": assertions}, "  "))
	print("RC-028 process %s/%s: %d checks, %d failures" % [scenario, stage, checks, failures])
	quit(0 if failures == 0 else 1)
