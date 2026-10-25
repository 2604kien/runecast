extends RefCounted

const Run = preload("res://scripts/core/run_state.gd")
const Fixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const Profile = preload("res://scripts/core/progression_state.gd")

class BossFixtureRoute extends Fixture.FixtureRoute:
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		# Excluded boundary fixture: actual supported Shadeling as the opening
		# boss. No visits are manufactured and no complete tower is claimed.
		_graph.route_id = "rc027_boss_boundary_fixture-%d" % seed
		var node: Dictionary = _nodes.d1a
		node.encounter_id = "training_shadeling"
		node.encounter_role = "boss"
		node.enemy_id = "shadeling"
		node.title = "FIXTURE · Shadeling milestone boundary"
		node.display_name = node.title

class RejectChoiceRoute extends Fixture.FixtureRoute:
	func complete_choice(_run_id: String, _node_id: String, _visit_id: String, _choice_id: String) -> bool:
		return false

class RejectBossChoiceRoute extends BossFixtureRoute:
	func complete_choice(_run_id: String, _node_id: String, _visit_id: String, _choice_id: String) -> bool:
		return false

class ReentrantChoiceRoute extends Fixture.FixtureRoute:
	var callback: Callable
	func complete_choice(run_id: String, node_id: String, visit_id: String, choice_id: String) -> bool:
		if callback.is_valid(): callback.call()
		return super(run_id, node_id, visit_id, choice_id)

class RewardResolver extends Fixture.FixtureResolver:
	func _choices(_node: Dictionary) -> Array:
		return ["encounter_rewards"]

func policy(ids: Array = ["spark", "shield", "focus", "conjure"], gold: int = 0) -> Dictionary:
	return {"policy_id": "rc027_explicit_core_test", "rules": [{"encounter_role": "development",
		"encounter_id": "rc007_entry_probe_next", "choice_id": "encounter_rewards",
		"eligible_ids": ids, "offer_count": 3, "gold": gold, "allow_skip": true}]}

func make_run(rules: Dictionary):
	return Run.new(Loader.load_setup().setup, 42, true,
		func(run_id, seed): return Fixture.FixtureRoute.new(run_id, seed), RewardResolver.new(), rules)

func win(run, node: String = "d1a"):
	var candidate: Dictionary = run.prepare_route_battle(run.request_room_entry(node).token)
	if not candidate.ok: return null
	var game = run.commit_route_battle(candidate).combat
	if not Integration.new()._win(game): return null
	return game if run.resolve_battle(game) else null

func run(check: Callable) -> void:
	var subject = make_run(policy())
	var before: Dictionary = subject.snapshot()
	check.call(not subject.choose_reward({}, "spark").ok and subject.snapshot() == before, "RC-027: premature claim rejects without mutation or RNG.")
	var battle = win(subject)
	check.call(battle != null, "RC-027: genuine Combat victory commits before reward offering.")
	if battle == null: return
	var offer: Dictionary = subject.pending_reward()
	check.call(offer.status == "pending" and offer.offered_ids.size() == 3 and not "free_spark" in offer.offered_ids, "RC-027: explicit policy creates three unique implemented permanent options.")
	var handoff: Dictionary = battle.run_handoff()
	check.call(subject.snapshot().next_uid == handoff.next_uid and handoff.next_uid > 8, "RC-027: terminal transfer retains temporary-consumed allocator before rewards.")
	before = subject.snapshot()
	for attempt in 4:
		var detached: Dictionary = subject.pending_reward()
		detached.offered_ids.clear()
		var detached_state: Dictionary = subject.snapshot()
		detached_state.reward_records.clear()
		check.call(subject.pending_reward() == offer and subject.snapshot() == before, "RC-027: inspection and detached mutations preserve authoritative offering and every RNG.")
	for field in ["run_id", "route_id", "node_id", "visit_id", "choice_id"]:
		var stale: Dictionary = offer.identity.duplicate()
		stale[field] = "stale"
		check.call(not subject.choose_reward(stale, offer.offered_ids[0]).ok and not subject.skip_reward(stale).ok and subject.snapshot() == before, "RC-027: stale %s rejects atomically." % field)
	check.call(not subject.choose_reward(offer.identity, "free_spark").ok and subject.snapshot() == before, "RC-027: generated temporary definition cannot be awarded.")
	check.call(not subject.complete_room_choice(offer.identity.run_id, offer.identity.node_id, offer.identity.visit_id, offer.identity.choice_id) and subject.snapshot() == before, "RC-027: generic choice callback cannot bypass reward transaction.")
	var original: Array = before.owned_cards.duplicate(true)
	var claimed: Dictionary = subject.choose_reward(offer.identity, offer.offered_ids[0])
	check.call(claimed.ok and claimed.granted_card.uid == handoff.next_uid and subject.snapshot().owned_cards.slice(0, 8) == original, "RC-027: choosing preserves all original instances and grants authoritative fresh UID.")
	check.call(subject.snapshot().status == "result_pending" and subject.route_snapshot().status == "route_ready" and subject.snapshot().pending_result.reward_summary.cards == [claimed.granted_card], "RC-027: reward commit and route completion succeed while separate result acknowledgement remains pending.")
	before = subject.snapshot()
	check.call(not subject.choose_reward(offer.identity, offer.offered_ids[0]).ok and not subject.skip_reward(offer.identity).ok and not subject.claim_reward_gold(offer.identity).ok and subject.snapshot() == before, "RC-027: repeated callbacks grant no resources and preserve settled record.")
	check.call(battle.run_handoff() == handoff, "RC-027: new reward never enters settled Combat zones.")
	var result_identity: Dictionary = before.pending_result.identity
	check.call(subject.acknowledge_result(result_identity), "RC-027: result acknowledgement after claim remains separate.")
	var successor: String = subject.inspect_node("d1a").next_ids[0]
	var next: Dictionary = subject.prepare_route_battle(subject.request_room_entry(successor).token)
	var second = subject.commit_route_battle(next).combat
	check.call(second.run_handoff().owned_cards == subject.snapshot().owned_cards and second.run_handoff().owned_cards.count(claimed.granted_card) == 1, "RC-027: next real encounter carries awarded instance once through ordinary shuffle/draw.")
	check.call(Integration.new()._win(second) and subject.resolve_battle(second), "RC-027: awarded collection completes the second genuine encounter.")
	var second_offer: Dictionary = subject.pending_reward()
	check.call(second_offer.identity.visit_id != offer.identity.visit_id and subject.snapshot().reward_records.size() == 2, "RC-027: repeated encounter definition owns distinct visit reward identities.")
	check.call(not subject.choose_reward(offer.identity, offer.offered_ids[0]).ok, "RC-027: previous visit callbacks cannot resolve the current offering.")
	var repeat = make_run(policy())
	win(repeat)
	check.call(repeat.pending_reward().offered_ids == offer.offered_ids and repeat.snapshot().reward_rng_state == before.reward_rng_state, "RC-027: fixed seed reproduces offering independently of run identity.")
	var no_rewards = Fixture.new_run()
	win(no_rewards)
	check.call(no_rewards.snapshot().rng_states == handoff.rng_states and repeat.snapshot().rng_states == handoff.rng_states and repeat.route_snapshot().route_rng_state == no_rewards.route_snapshot().route_rng_state, "RC-027: reward sampling never consumes battle or route RNG streams.")
	_small_empty_gold(check)
	_disabled_and_replay(check)
	_milestones_and_profile(check)
	_atomic_commit(check)

func _small_empty_gold(check: Callable) -> void:
	for ids in [["spark", "spark", "free_spark", "unknown"], ["free_spark", "unknown"]]:
		var subject = make_run(policy(ids))
		win(subject)
		var offer: Dictionary = subject.pending_reward()
		check.call(offer.offered_ids == (["spark"] if "spark" in ids else []), "RC-027: small/empty pools filter temporary, unknown and duplicate IDs without option padding.")
		var before: Dictionary = subject.snapshot()
		check.call(subject.skip_reward(offer.identity).ok and subject.snapshot().owned_cards == before.owned_cards and subject.snapshot().next_uid == before.next_uid and subject.snapshot().gold == 0, "RC-027: explicit Skip grants nothing, including with an empty pool.")
	for gold_first in [true, false]:
		var subject = make_run(policy(["spark"], 7))
		win(subject)
		var offer: Dictionary = subject.pending_reward()
		var first: Dictionary = subject.claim_reward_gold(offer.identity) if gold_first else subject.skip_reward(offer.identity)
		check.call(first.ok and subject.route_snapshot().status == "pending_choices", "RC-027: only one component resolved retains successor lock.")
		var before: Dictionary = subject.snapshot()
		var duplicate: Dictionary = subject.claim_reward_gold(offer.identity) if gold_first else subject.skip_reward(offer.identity)
		check.call(not duplicate.ok and subject.snapshot() == before, "RC-027: duplicate component claim is atomic while other component remains pending.")
		var last: Dictionary = subject.skip_reward(offer.identity) if gold_first else subject.claim_reward_gold(offer.identity)
		check.call(last.ok and subject.route_snapshot().status == "route_ready" and subject.snapshot().gold == 7 and subject.snapshot().owned_cards.size() == 8 and subject.reward_snapshot(offer.identity).claims.size() == 2, "RC-027: explicit Gold payout and Skip settle independently, once each.")

func _disabled_and_replay(check: Callable) -> void:
	var disabled = make_run({})
	var before_rng: int = disabled.snapshot().reward_rng_state
	win(disabled)
	var offer: Dictionary = disabled.pending_reward()
	var before: Dictionary = disabled.snapshot()
	check.call(offer.status == "unavailable" and offer.offered_ids.is_empty() and disabled.snapshot().reward_rng_state == before_rng, "RC-027: absent policy leaves informative pending choice without RNG or fabricated award.")
	check.call(not disabled.skip_reward(offer.identity).ok and not disabled.choose_reward(offer.identity, "spark").ok and disabled.snapshot() == before, "RC-027: unavailable production policy cannot be implicitly skipped or claimed.")
	var subject = make_run(policy())
	var candidate: Dictionary = subject.prepare_route_battle(subject.request_room_entry("d1a").token)
	var game = subject.commit_route_battle(candidate).combat
	var old_identity: Dictionary = subject.snapshot().active_battle
	check.call(subject.quit_to_home(game), "RC-027: live battle Quit preserves exact replay checkpoint before any reward.")
	game = subject.continue_battle().combat
	check.call(subject.snapshot().active_battle.generation != old_identity.generation and subject.snapshot().reward_records.is_empty(), "RC-027: replay generation does not create a reward record.")
	check.call(Integration.new()._win(game) and subject.resolve_battle(game) and subject.snapshot().reward_records.size() == 1, "RC-027: replay victory generates exactly one visit offering.")
	var defeat = make_run(policy(["spark"], 7))
	candidate = defeat.prepare_route_battle(defeat.request_room_entry("d1a").token)
	game = defeat.commit_route_battle(candidate).combat
	while game.state == "playing": game.pass_turn()
	check.call(game.state == "defeat" and defeat.resolve_battle(game) and defeat.snapshot().reward_records.is_empty() and defeat.snapshot().gold == 0, "RC-027: real defeat creates no victory reward or Gold.")
	var wrong_role := policy()
	wrong_role.rules[0].encounter_role = "normal"
	subject = make_run(wrong_role)
	before_rng = subject.snapshot().reward_rng_state
	win(subject)
	check.call(subject.pending_reward().status == "unavailable" and subject.snapshot().reward_rng_state == before_rng, "RC-027: room_normal dispatch family never substitutes for an explicit encounter role policy.")

func _boss_run(profile):
	return Run.new(Loader.load_setup().setup, 42, true,
		func(run_id, seed): return BossFixtureRoute.new(run_id, seed), RewardResolver.new(), Profile.production_rules(), profile)

func _milestones_and_profile(check: Callable) -> void:
	var profile = Profile.new(Loader.load_setup().setup.catalog)
	var subject = _boss_run(profile)
	check.call(win(subject) != null, "RC-027: actual Shadeling victory reaches explicit boss milestone policy.")
	var records: Array = subject.snapshot().reward_records
	check.call(records.size() == 2 and records[1].kind == "definition_unlock" and records[1].resolution == "exhausted" and records[1].claims.size() == 1, "RC-027: all current definitions unlocked produces an explicit once-only exhausted milestone record.")
	check.call(subject.snapshot().owned_cards.size() == 8 and subject.snapshot().gold == 0 and profile.snapshot().unlocked_definition_ids.size() == 4 and subject.route_snapshot().status == "pending_choices", "RC-027: exhausted milestone gives no compensation and keeps the run-rune choice required.")
	var run_offer: Dictionary = subject.pending_reward()
	check.call(subject.skip_reward(run_offer.identity).ok and subject.route_snapshot().status == "route_ready", "RC-027: exhausted milestone plus explicit run Skip completes only this fixture boss visit.")
	profile = Profile.new(Loader.load_setup().setup.catalog, ["spark"])
	for index in 3:
		subject = _boss_run(profile)
		check.call(win(subject) != null, "RC-027: explicit narrowed-profile fixture earns another real boss victory.")
		run_offer = subject.pending_reward()
		check.call(run_offer.eligible_ids == profile.snapshot().unlocked_definition_ids and run_offer.offered_ids.all(func(id): return id in profile.snapshot().unlocked_definition_ids), "RC-027: profile eligibility includes acquired definitions in run rewards while starter remains unchanged.")
		check.call(subject.skip_reward(run_offer.identity).ok and subject.route_snapshot().status == "pending_choices", "RC-027: milestone acquisition remains required after run choice resolves.")
		var unlock: Dictionary = subject.pending_reward()
		var before: Dictionary = subject.snapshot()
		check.call(unlock.kind == "definition_unlock" and unlock.offered_ids.size() == 1 and not unlock.offered_ids[0] in profile.snapshot().unlocked_definition_ids and not subject.skip_reward(unlock.identity).ok, "RC-027: milestone offers exactly one still-locked definition, without implicit Skip.")
		var claim: Dictionary = subject.choose_reward(unlock.identity, unlock.offered_ids[0])
		check.call(claim.ok and claim.claim.component == "definition_unlock" and claim.claim.unlocked_definition_id == unlock.offered_ids[0] and subject.snapshot().owned_cards == before.owned_cards and subject.snapshot().next_uid == before.next_uid, "RC-027: definition acquisition commits without granting stored or run-owned copies or consuming UID.")
		var after: Dictionary = subject.snapshot()
		check.call(not subject.choose_reward(unlock.identity, unlock.offered_ids[0]).ok and subject.snapshot() == after, "RC-027: repeated permanent acquisition cannot duplicate unlocks or mutate settled claims.")
		var fresh = _boss_run(profile)
		check.call(fresh.snapshot().profile.unlocked_definition_ids.size() == index + 2 and fresh.snapshot().owned_cards.size() == 8, "RC-027: shared session profile survives New Run with unchanged starter, separate ownership.")
		var detached: Dictionary = fresh.snapshot()
		detached.profile.unlocked_definition_ids.clear()
		check.call(profile.snapshot().unlocked_definition_ids.size() == index + 2, "RC-027: profile presentation snapshots cannot mutate authoritative unlocks.")
	subject = _boss_run(profile)
	win(subject)
	check.call(subject.snapshot().reward_records[1].resolution == "exhausted" and subject.snapshot().gold == 0, "RC-027: repeated milestone after all unlocks is exhausted without duplicate award or compensation.")

func _atomic_commit(check: Callable) -> void:
	var subject = Run.new(Loader.load_setup().setup, 42, true,
		func(run_id, seed): return RejectChoiceRoute.new(run_id, seed), RewardResolver.new(), policy())
	win(subject)
	var offer: Dictionary = subject.pending_reward()
	var before: Dictionary = subject.snapshot()
	check.call(not subject.choose_reward(offer.identity, offer.offered_ids[0]).ok and subject.snapshot() == before, "RC-027: rejected final choice commit grants no card, allocator increment, claim record or route completion.")
	var profile = Profile.new(Loader.load_setup().setup.catalog, ["spark"])
	subject = Run.new(Loader.load_setup().setup, 42, true,
		func(run_id, seed): return RejectBossChoiceRoute.new(run_id, seed), RewardResolver.new(), Profile.production_rules(), profile)
	win(subject)
	offer = subject.snapshot().reward_records[1]
	before = subject.snapshot()
	check.call(not subject.choose_reward(offer.identity, offer.offered_ids[0]).ok and subject.snapshot() == before and profile.snapshot().unlocked_definition_ids == ["spark"], "RC-027: rejected milestone choice commit leaves session profile and all run/claim state unchanged.")
	var holder := {}
	subject = Run.new(Loader.load_setup().setup, 42, true, func(run_id, seed):
		var route := ReentrantChoiceRoute.new(run_id, seed)
		holder.route = route
		return route, RewardResolver.new(), policy())
	win(subject)
	offer = subject.pending_reward()
	before = subject.snapshot()
	var observed := {"rejected": false, "unchanged": false}
	holder.route.callback = func():
		observed.rejected = not subject.choose_reward(offer.identity, offer.offered_ids[0]).ok
		observed.unchanged = subject.snapshot() == before
	var claim: Dictionary = subject.choose_reward(offer.identity, offer.offered_ids[0])
	check.call(claim.ok and observed.rejected and observed.unchanged and subject.snapshot().owned_cards.size() == 9 and subject.reward_snapshot(offer.identity).claims.size() == 1, "RC-027: reentrant reward callback rejects before mutation while the outer transaction commits exactly once.")
	holder.route.callback = Callable()
