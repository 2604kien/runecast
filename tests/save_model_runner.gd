extends SceneTree
## Isolated model contract checks; no normal save or settings path is touched.
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
var checks := 0
var failures := 0
var setup: Dictionary

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func restore(subject, data: Dictionary = {}) -> Dictionary:
	return Run.restore_save(subject.export_save() if data.is_empty() else data, setup,
		subject.profile_state().clone_for_transaction(), subject.restore_context_for_tests())

func _initialize() -> void:
	setup = Loader.load_setup().setup
	var profile = Profile.new(setup.catalog)
	var production = Run.new(setup, 9007199254740993, true, Callable(), null, Profile.production_rules(), profile)
	var exported: Dictionary = production.export_save()
	check(production.snapshot().status == "route_ready", "Large exact seed creates a supported route.")
	var result: Dictionary = Run.restore_save(exported, setup, profile)
	check(result.ok and result.run.export_save() == exported, "Production fresh route restores without new IDs, route or random streams.")
	check(Run.new(setup)._run_id != Run.new(setup)._run_id, "Run identities use independent random entropy.")
	var serialized: Variant = bytes_to_var(var_to_bytes(exported))
	check(serialized.seed == 9007199254740993 and serialized == exported, "Native model contract retains int64 seed and random stream bits.")
	var wide := exported.duplicate(true)
	wide.next_uid = 9007199254740995
	wide.candidate_sequence = 9007199254740997
	wide.battle_generation = 9007199254740999
	wide.rng_states.cards = -9223372036854775807
	wide.reward_rng_state = 9223372036854775806
	result = Run.restore_save(wide, setup, profile)
	check(result.ok and result.run.export_save() == wide, "Allocator gaps, counters and signed random states retain every int64 bit.")
	for corrupt in [[], ["spark", "spark"], ["spark", "shield", "focus", "conjure", "free_spark"], ["unknown"]]:
		var data := profile.export_save()
		data.unlocked_definition_ids = corrupt
		check(not Profile.restore_save(data, setup.catalog).ok, "Malformed production profile is rejected without defaults.")
	var narrow = Profile.new(setup.catalog, ["spark"])
	check(not Profile.restore_save(narrow.export_save(), setup.catalog).ok and Profile.restore_save(narrow.export_save(), setup.catalog, true).ok, "Narrowed profile requires explicit isolated fixture capability.")
	for key in exported:
		var data := exported.duplicate(true)
		data.erase(key)
		check(not Run.restore_save(data, setup, profile).ok, "Missing authoritative field %s rejects." % key)
	for mutation in [
		{"status": "battle"}, {"version": 99}, {"run_id": "bad"}, {"seed": 42.0},
		{"policy_id": "rc027_reward_enabled_test_v1"}, {"relics": ["unknown"]}, {"gold": 1},
		{"owned_cards": ["bad"]}, {"active_battle": {"run_id": "bad"}},
		{"completed_encounters": ["unregistered"]}]:
		var data := exported.duplicate(true)
		data.merge(mutation, true)
		check(not Run.restore_save(data, setup, profile).ok, "Invalid authoritative field %s rejects." % mutation.keys()[0])
	for field in ["title", "content_pending", "next_ids"]:
		var malformed := exported.duplicate(true)
		malformed.route.graph.nodes[0].erase(field)
		check(not Run.restore_save(malformed, setup, profile).ok, "Incomplete raw production node %s rejects before publication." % field)
	var malformed := exported.duplicate(true)
	malformed.content.encounter_id = "res://tests/helpers/reward_route_fixture.gd"
	check(not Run.restore_save(malformed, setup, profile).ok, "Saved content cannot select an executable or arbitrary resource path.")
	_fuzz_structure(production, true)
	var subject = Fixture.new_run()
	var context: Dictionary = subject.restore_context_for_tests()
	check(not Run.restore_save(subject.export_save(), setup, subject.profile_state()).ok, "Production restore rejects fixture route/policy.")
	result = restore(subject)
	check(result.ok and result.run.export_save() == subject.export_save(), "Explicit fixture route restores its raw graph.")
	var candidate: Dictionary = subject.prepare_route_battle(subject.request_room_entry("d1a").token)
	var battle = subject.commit_route_battle(candidate).combat
	var before: Dictionary = subject.export_save()
	result = restore(subject)
	check(result.ok, "Committed battle restores its entry: " + str(result.get("error")))
	if result.ok:
		var continued: Dictionary = result.run.prepare_continue_battle()
		check(continued.ok and continued.combat.snapshot() == battle.snapshot(), "Interrupted battle recreates exact entry configuration and random opening.")
	var changed_entry := before.duplicate(true)
	changed_entry.entry_checkpoint.next_uid += 1
	check(not restore(subject, changed_entry).ok, "Battle checkpoint cannot disagree with the authoritative allocator.")
	changed_entry = before.duplicate(true)
	changed_entry.active_battle.erase("generation")
	check(not restore(subject, changed_entry).ok, "Incomplete active battle identity rejects before ownership lookup.")
	_fuzz_structure(subject)
	var clone: Dictionary = subject.clone_for_transaction()
	check(clone.ok and clone.run.current_battle() == battle and clone.profile != subject.profile_state(), "Transaction clone preserves live Combat and isolates the profile.")
	check(Integration.new()._win(battle), "Real actions reach a terminal outcome.")
	check(subject.export_save() == before, "Live Combat draws and temporary UID gaps do not overwrite authoritative entry.")
	check(clone.run.resolve_battle(battle) and subject.export_save() == before and subject.current_battle() == battle, "Detached outcome does not publish before durable success.")
	subject.publish_transaction(clone.run)
	check(subject.current_battle() == null and subject.snapshot().status == "result_pending", "Publishing outcome advances the existing run owner.")
	result = restore(subject)
	check(result.ok and result.run.export_save() == subject.export_save(), "Pending victory retains exact offers, entry allocator and route locks: " + str(result.get("error")))
	if not result.ok:
		print("RC-028 save models: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var offer: Dictionary = subject.pending_reward()
	var changed_pool: Dictionary = subject.export_save()
	changed_pool.reward_records[0].eligible_ids.pop_back()
	check(not restore(subject, changed_pool).ok, "Retained reward eligibility must match the historical profile policy.")
	_fuzz_structure(subject)
	for gold_first in [true, false]:
		var split = restore(subject).run
		var first: Dictionary = split.claim_reward_gold(offer.identity) if gold_first else split.choose_reward(offer.identity, offer.offered_ids[0])
		check(first.ok, "First independent reward component commits.")
		var partial: Dictionary = restore(split)
		check(partial.ok and partial.run.export_save() == split.export_save(), "Partial reward round-trips in either claim order: " + str(partial.get("error")))
		if partial.ok:
			var resumed = partial.run
			var last: Dictionary = resumed.choose_reward(offer.identity, offer.offered_ids[0]) if gold_first else resumed.claim_reward_gold(offer.identity)
			check(last.ok and restore(resumed).ok and resumed.snapshot().gold == 7, "Second component preserves exactly one grant and receipt.")
	var rejected: Dictionary = subject.export_save()
	rejected.owned_cards[1].uid = rejected.owned_cards[0].uid
	check(not restore(subject, rejected).ok, "Duplicate owned UID rejects.")
	rejected = subject.export_save()
	rejected.route.visits[0].visit_id = "foreign"
	check(not restore(subject, rejected).ok, "Inconsistent visit identity rejects.")
	rejected = subject.export_save()
	rejected.reward_records[0].claims.append({"transaction_id": "forged"})
	check(not restore(subject, rejected).ok, "Forged reward receipt rejects.")
	rejected = subject.export_save()
	rejected.reward_records.clear()
	check(not restore(subject, rejected).ok, "Required reward lock cannot lose its retained offer.")
	var skip = restore(subject).run
	check(skip.skip_reward(offer.identity).ok and skip.claim_reward_gold(offer.identity).ok and skip.acknowledge_result(skip.snapshot().pending_result.identity), "Skip, Gold and independent result acknowledgement settle.")
	check(restore(skip).ok and skip.snapshot().status == "route_ready", "Acknowledged result resumes route without replaying a resolved battle.")
	_fuzz_structure(skip)
	check(context.allow_test_fixtures, "Fixture capability is explicit and separate from saved bytes.")
	print("RC-028 save models: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _fuzz_structure(subject, production_restore: bool = false) -> void:
	var valid: Dictionary = subject.export_save()
	var paths: Array = []
	_collect_paths(valid, [], paths)
	for path in paths:
		var source: Variant = valid
		for key in path: source = source[key]
		# A dictionary/array is always the wrong type for primitive ownership
		# fields, and null is always wrong for the explicit container schema.
		var replacement: Variant = null if source is Dictionary or source is Array else []
		var data := valid.duplicate(true)
		var target: Variant = data
		for index in range(path.size() - 1): target = target[path[index]]
		target[path.back()] = replacement
		var result: Dictionary = Run.restore_save(data, setup, subject.profile_state()) if production_restore else restore(subject, data)
		check(not result.ok, "Malformed nested save field rejects cleanly: " + str(path))

func _collect_paths(value: Variant, prefix: Array, result: Array) -> void:
	if value is Dictionary:
		for key in value:
			var path := prefix.duplicate()
			path.append(key)
			result.append(path)
			_collect_paths(value[key], path, result)
	elif value is Array:
		for index in range(value.size()):
			var path := prefix.duplicate()
			path.append(index)
			result.append(path)
			_collect_paths(value[index], path, result)
