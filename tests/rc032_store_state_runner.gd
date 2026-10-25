extends SceneTree
## Excluded Store model verification. Income overrides below are explicitly
## test-only boundary scenarios, never production payout or balance decisions.
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const Relics = preload("res://scripts/core/relic_policy.gd")
var destination := "res://output/qa/rc-032-store/model"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-root="): destination = argument.trim_prefix("--output-root=")
	setup = Loader.load_setup().setup
	DirAccess.make_dir_recursive_absolute(destination)
	_boundaries_and_allowances()
	_exact_prices()
	_relics_and_full_history()
	_hostile_receipts()
	FileAccess.open(destination.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  "))
	print("RC-032 Store model: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, label: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": label})
	if not ok:
		failures += 1
		push_error(label)

func _new(income: int = 250):
	var rules: Dictionary = Fixture.reward_rules()
	for rule in rules.rules:
		if rule.encounter_role == "normal": rule.gold = income
	return Run.new(setup, 42, true, func(id, seed): return Fixture.FixtureRoute.new(id, seed), Fixture.FixtureResolver.new(), rules, Profile.new(setup.catalog, ["spark", "shield"]))

func _win(subject, branch: String = "normal", acknowledge: bool = true) -> bool:
	var entered: Dictionary = Fixture.enter_next(subject, branch)
	if not entered.ok or not entered.has("combat") or not Fixture.win_combat(entered.combat) or not subject.resolve_battle(entered.combat): return false
	return Fixture.finish_rewards(subject, acknowledge).ok

func _restore(subject, data: Dictionary = {}) -> Dictionary:
	var encoded := Save.encode_document({"run": subject.export_save() if data.is_empty() else data}, 1)
	if not encoded.ok: return encoded
	var decoded := Save.decode_document(encoded.text)
	if not decoded.ok: return decoded
	return Run.restore_save(decoded.payload.run, setup, subject.profile_state().clone_for_transaction(), Fixture.context_for(subject))

func _roundtrip(subject, label: String) -> void:
	var restored := _restore(subject)
	check(restored.ok and restored.run.export_save() == subject.export_save(), label + ": " + str(restored.get("error", "")))
	if restored.ok: check(restored.run.store_snapshot() == subject.store_snapshot(), label + " retains catalogue, allowances and identity.")

func _assert_closed(subject, label: String) -> void:
	var before: Dictionary = subject.export_save()
	var store: Dictionary = subject.store_snapshot()
	check(not store.enabled and not store.error.is_empty(), label + " is browse-only.")
	check(not subject.purchase_store_rune(store.identity, "spark").ok and not subject.purchase_store_relic(store.identity, "relic_heart_stone").ok and before == subject.export_save(), label + " rejects both direct purchases without mutation.")

func _boundaries_and_allowances() -> void:
	var subject = _new()
	var original: Dictionary = subject.export_save()
	var store: Dictionary = subject.store_snapshot()
	check(original.version == 6 and original.size() == 34 and original.store == {"version": 2, "policy_id": "rc035_store_v2", "transactions": []}, "New v6 run contains only its empty expanded-catalogue Store authority.")
	check(store.enabled and store.gold == 0 and store.runes.size() == 2 and store.relics.size() == 6, "Initial unvisited Map permits browsing with two fixture unlocked runes and all six relic definitions.")
	check(store.runes.all(func(slot): return not slot.enabled and slot.cost == 45) and store.relics.all(func(slot): return not slot.enabled and slot.cost == 90), "Zero Gold disables every priced slot without closing the between-room boundary.")
	check(subject.export_save() == original and not subject.purchase_store_rune(store.identity, "spark").ok, "Repeated browsing and insufficient funds do not mutate authority or consume allowance.")
	var stale: Dictionary = store.identity
	var requested: Dictionary = subject.request_room_entry(Fixture.next_node(subject))
	var prepared: Dictionary = subject.prepare_route_battle(requested.token)
	check(prepared.ok, "Prepare a genuine first battle.")
	_assert_closed(subject, "Prepared entry")
	var entered: Dictionary = subject.commit_route_battle(prepared)
	check(entered.ok, "Commit genuine first battle.")
	_assert_closed(subject, "Live combat")
	var restored := _restore(subject)
	check(restored.ok, "Interrupted entry restores.")
	if restored.ok: _assert_closed(restored.run, "Interrupted replay checkpoint")
	check(Fixture.win_combat(entered.combat) and subject.resolve_battle(entered.combat), "Commit real victory before any supply purchase.")
	_assert_closed(subject, "Pending result and rewards")
	check(Fixture.finish_rewards(subject, false).ok, "Settle rewards while retaining result acknowledgement.")
	_assert_closed(subject, "Unacknowledged resolved encounter")
	check(subject.acknowledge_result(subject.snapshot().pending_result.identity), "Acknowledge the independent encounter result.")
	check(subject.store_snapshot().enabled and not subject.purchase_store_rune(stale, "spark").ok, "Settled room enables purchases but rejects an earlier Map confirmation.")
	store = subject.store_snapshot()
	check(not subject.purchase_store_rune(store.identity, "focus").ok and not subject.purchase_store_rune(store.identity, "echo").ok and not subject.purchase_store_relic(store.identity, "missing").ok, "Locked, temporary or unknown definitions cannot be purchased.")
	original = subject.export_save()
	var profile_before: Dictionary = subject.profile_state().export_save()
	var clone: Dictionary = subject.clone_for_transaction()
	var bought: Dictionary = clone.run.purchase_store_rune(store.identity, "spark")
	check(bought.ok and subject.export_save() == original and clone.run._gold == original.gold - 45, "Purchase mutates only its detached clone until durable publication.")
	check(bought.granted_card == {"id": "spark", "uid": original.next_uid, "upgrade_rank": 0}, "Duplicate definition purchase allocates a fresh rank-zero owned UID.")
	check(clone.run._rng_states == original.rng_states and clone.run._reward_rng.state == original.reward_rng_state and clone.run._shop_rng.state == original.shop_rng_state and clone.run._route.export_save() == original.route, "Menu purchase does not consume any RNG stream or alter route visits/revision.")
	subject.publish_transaction(clone.run)
	check(subject.profile_state().export_save() == profile_before and subject.store_snapshot().rune_purchased, "Published supply uses run ownership and leaves persistent eligibility unchanged.")
	_roundtrip(subject, "Rank-zero Store purchase roundtrip")
	check(not subject.purchase_store_rune(subject.store_snapshot().identity, "shield").ok and not subject.purchase_store_relic(store.identity, "relic_heart_stone").ok, "Global rune allowance and stale pre-purchase identity both reject.")
	check(Fixture.enter_next(subject).ok, "Enter real Lost Satchel after supply acquisition.")
	_assert_closed(subject, "Active event")
	check(Fixture.finish_room(subject).ok and subject.store_snapshot().rune_purchased, "Leaving the event preserves the consumed rune allowance.")
	bought = subject.purchase_store_relic(subject.store_snapshot().identity, "relic_heart_stone")
	check(bought.ok and subject._player_hp == 34 and subject._player_max_hp == 34 and subject.store_snapshot().relic_purchased, "Heart Stone purchase at a later boundary applies its +4 HP/max hook exactly once.")
	_roundtrip(subject, "Rune then event then Heart Stone roundtrip")
	check(not subject.purchase_store_relic(subject.store_snapshot().identity, "relic_ember_lens").ok, "A different relic still cannot bypass the one-relic allowance.")
	var abandoned: Dictionary = subject.abandon_run(subject.abandonment_request().token)
	check(abandoned.ok, "Abandon a funded run with both purchases.")
	_assert_closed(subject, "Abandoned run")
	_roundtrip(subject, "Abandoned Store history roundtrip")
	var fresh = _new()
	check(fresh._gold == 0 and fresh._relics.is_empty() and fresh._owned_cards.size() == 8 and not fresh.store_snapshot().rune_purchased and not fresh.store_snapshot().relic_purchased, "New Run resets Gold, run-owned supplies and both allowances.")
	var defeated = _new()
	entered = Fixture.enter_next(defeated)
	while entered.combat.state == "playing": entered.combat.pass_turn()
	check(defeated.resolve_battle(entered.combat), "Commit actual defeat for terminal Store guard.")
	_assert_closed(defeated, "Defeat result")
	check(defeated.acknowledge_result(defeated.snapshot().pending_result.identity), "Acknowledge defeat.")
	_assert_closed(defeated, "Defeat review")
	var standalone = Run.new(setup)
	_assert_closed(standalone, "Standalone encounter")

func _exact_prices() -> void:
	for income in [44, 45, 89, 90, 134, 135]:
		var subject = _new(income)
		check(_win(subject) and subject._gold == income, "Explicit excluded fixture pays exactly %d Gold through a real reward claim." % income)
		var before: Dictionary = subject.export_save()
		var result: Dictionary = subject.purchase_store_rune(subject.store_snapshot().identity, "spark")
		check(result.ok == (income >= 45) and subject._gold == income - (45 if result.ok else 0), "Rune price accepts exact45 and rejects44; scenario %d." % income)
		if not result.ok: check(before == subject.export_save(), "Rejected below-price purchase preserves all authority.")
		var remaining: int = subject._gold
		result = subject.purchase_store_relic(subject.store_snapshot().identity, "relic_ward_seal")
		check(result.ok == (remaining >= 90) and subject._gold == remaining - (90 if result.ok else 0), "Second category needs its full90; both supplies require135, scenario %d." % income)
		_roundtrip(subject, "Exact-income scenario%d" % income)
	for income in [89, 90]:
		var subject = _new(income)
		check(_win(subject), "Fund relic-first boundary through actual result.")
		var result: Dictionary = subject.purchase_store_relic(subject.store_snapshot().identity, "relic_heart_stone")
		check(result.ok == (income == 90) and subject._gold == (0 if income == 90 else 89), "Relic-first rejects89 and accepts exact90; scenario%d." % income)
		_roundtrip(subject, "Relic-first exact-income scenario%d" % income)

func _relics_and_full_history() -> void:
	for id in Relics.ORDER:
		var subject = _new()
		check(_win(subject), "Fund %s from genuine first victory." % id)
		var before_hp: int = subject._player_hp
		var purchased: Dictionary = subject.purchase_store_relic(subject.store_snapshot().identity, id)
		check(purchased.ok and subject._player_hp == before_hp + (4 if id == "relic_heart_stone" else 0), "Existing bounded health hook applies for %s." % id)
		check(not subject.purchase_store_relic(subject.store_snapshot().identity, id).ok, "Repeated %s acquisition is rejected." % id)
		_roundtrip(subject, "All-six relic policy %s" % id)
	var subject = _new()
	check(_win(subject, "elite") and Fixture.enter_next(subject, "elite").ok and Fixture.finish_room(subject).ok, "Acquire actual Reliquary relic before Menu Store.")
	var owned: String = subject._relics[0]
	var slots: Array = subject.store_snapshot().relics.filter(func(slot): return slot.definition_id == owned)
	check(slots[0].owned and not slots[0].enabled and not subject.purchase_store_relic(subject.store_snapshot().identity, owned).ok, "Relic uniqueness spans room and Menu Store sources.")
	var another: String = Relics.eligible_pool(subject._relics)[0]
	check(subject.purchase_store_relic(subject.store_snapshot().identity, another).ok, "Room relic does not consume the separate one-purchase Store allowance.")
	_roundtrip(subject, "Reliquary then unique Store relic")
	subject = _new()
	for depth in range(1, 10):
		var entered: Dictionary = Fixture.enter_next(subject)
		check(entered.ok, "Store-interleaved full route enters visit%d." % depth)
		if not entered.ok: return
		if entered.has("combat"):
			check(Fixture.win_combat(entered.combat) and subject.resolve_battle(entered.combat), "Store-interleaved real battle%d wins." % depth)
			_assert_closed(subject, "Visit%d unresolved encounter" % depth)
			check(Fixture.finish_rewards(subject).ok, "Store-interleaved rewards%d settle." % depth)
		else:
			_assert_closed(subject, "Visit%d active route room" % depth)
			check(Fixture.finish_room(subject).ok, "Store-interleaved room%d settles through actual service/shop transactions." % depth)
		if depth == 1: check(subject.purchase_store_rune(subject.store_snapshot().identity, "spark").ok, "Full route buys rune after first encounter.")
		if depth == 3: check(subject.purchase_store_relic(subject.store_snapshot().identity, "relic_heart_stone").ok, "Full route buys Heart Stone after third visit.")
		if depth == 6: check(subject.store_snapshot().runes.size() == 3, "Free boss milestone unlock expands the fixed implemented catalogue.")
		_roundtrip(subject, "Store-interleaved visit%d" % depth)
	check(subject.final_results_ready() and subject.run_summary().completed_rooms == 9 and subject._relics.size() == 2 and subject._owned_cards.size() == 10, "Full terminal summary retains distinct Store and route-shop acquisitions.")
	_assert_closed(subject, "Guardian victory review")

func _hostile_receipts() -> void:
	var subject = _new()
	check(_win(subject) and subject.purchase_store_rune(subject.store_snapshot().identity, "spark").ok and subject.purchase_store_relic(subject.store_snapshot().identity, "relic_heart_stone").ok, "Build authoritative two-purchase hostile-save fixture.")
	_roundtrip(subject, "Two purchases at one settled boundary")
	var source: Dictionary = subject.export_save()
	check(not Run.restore_save(source, setup, subject.profile_state()).ok, "Production restore rejects excluded fixture graphs and reward rules even with valid Store receipts.")
	for field in ["version", "policy_id", "transactions"]:
		for invalid in [null, [], {}, 42, false]:
			var malformed := source.duplicate(true)
			malformed.store[field] = invalid
			check(not _restore(subject, malformed).ok, "Malformed Store policy field %s=%s rejects cleanly." % [field, str(invalid)])
	for field in source.store.transactions[0]:
		for invalid in [null, [], {}, "bad", false]:
			var corrupt := source.duplicate(true)
			corrupt.store.transactions[0][field] = invalid
			check(not _restore(subject, corrupt).ok, "Reject Store receipt %s with malformed type%s." % [field, str(invalid)])
	for field in ["after_visit_count", "route_revision", "gold_spent", "entry_gold", "result_gold", "entry_next_uid", "entry_hp", "entry_max_hp", "result_hp", "result_max_hp"]:
		var corrupt := source.duplicate(true)
		corrupt.store.transactions[0][field] += 1
		check(not _restore(subject, corrupt).ok, "Reject altered exact Store %s chronology." % field)
	for kind in ["deleted", "reordered", "duplicate", "extra", "locked", "temporary", "rank", "uid", "foreign", "future", "past"]:
		var corrupt := source.duplicate(true)
		match kind:
			"deleted": corrupt.store.transactions.clear()
			"reordered": corrupt.store.transactions.reverse()
			"duplicate": corrupt.store.transactions[1] = corrupt.store.transactions[0].duplicate(true)
			"extra": corrupt.store.transactions.append(corrupt.store.transactions[0].duplicate(true))
			"locked":
				corrupt.store.transactions[0].definition_id = "focus"
				corrupt.store.transactions[0].card.id = "focus"
				corrupt.owned_cards.back().id = "focus"
			"temporary": corrupt.store.transactions[0].eligible_rune_ids.append("echo")
			"rank":
				corrupt.store.transactions[0].card.upgrade_rank = 1
				corrupt.owned_cards.back().upgrade_rank = 1
			"uid": corrupt.store.transactions[0].card.uid = 0
			"foreign": corrupt.store.transactions[0].transaction_id = "other/store/rune"
			"future": corrupt.store.transactions[0].after_visit_count = 9
			"past": corrupt.store.transactions[0].after_visit_count = 0
		check(not _restore(subject, corrupt).ok, "Reject coordinated hostile Store history: " + kind)
	var corrupt := source.duplicate(true)
	corrupt.store.transactions[1].result_hp += 4
	corrupt.store.transactions[1].result_max_hp += 4
	corrupt.player_hp += 4
	corrupt.player_max_hp += 4
	check(not _restore(subject, corrupt).ok, "Final HP cannot conceal a doubled Heart Stone acquisition hook.")
	corrupt = source.duplicate(true)
	corrupt.store.transactions[0].result_gold += 45
	corrupt.store.transactions[1].entry_gold += 45
	corrupt.store.transactions[1].result_gold += 45
	corrupt.gold += 45
	check(not _restore(subject, corrupt).ok, "Coordinated receipt and final Gold changes cannot waive a fixed Store price.")
	corrupt = source.duplicate(true)
	corrupt.store.version = 3
	check(not _restore(subject, corrupt).ok, "Unknown Store version fails closed.")
	corrupt = source.duplicate(true)
	corrupt.store.version = 1
	corrupt.store.policy_id = "rc032_store_v1"
	check(not _restore(subject, corrupt).ok, "Historical Store semantics cannot be substituted into an expanded-catalogue run.")
	corrupt = source.duplicate(true)
	corrupt.store.policy_id = "free_supplies"
	check(not _restore(subject, corrupt).ok, "Unknown Store policy fails closed.")
	subject = _new()
	check(_win(subject) and subject.purchase_store_rune(subject.store_snapshot().identity, "spark").ok and Fixture.enter_next(subject).ok and Fixture.finish_room(subject).ok and subject.purchase_store_relic(subject.store_snapshot().identity, "relic_ward_seal").ok, "Build separated purchases with a genuine noncombat service between them.")
	corrupt = subject.export_save()
	corrupt.store.transactions[1].entry_next_uid += 1
	corrupt.next_uid += 1
	check(not _restore(subject, corrupt).ok, "A noncombat service cannot hide an unexplained allocator gap between Store purchases.")
