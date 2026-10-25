extends SceneTree
## Excluded RC-032 authoritative lifecycle and hostile-terminal verification.
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Fixture = preload("res://tests/helpers/encounter_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const ServiceFixture = preload("res://tests/helpers/service_route_fixture.gd")
const Integration = preload("res://tests/encounter_integration_tests.gd")
const FullFixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const DESTINATION := "res://output/qa/rc-032/state"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary

func _initialize() -> void:
	setup = Loader.load_setup().setup
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	_abandonment()
	_pending_and_defeat()
	_summary()
	_guardian_orders()
	_transaction_boundaries()
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  "))
	print("RC-032 authoritative lifecycle: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, label: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": label})
	if not ok:
		failures += 1
		push_error(label)

func _enter(subject, node: String = "d1a"):
	var requested: Dictionary = subject.request_room_entry(node)
	if not requested.ok: return null
	var prepared: Dictionary = subject.prepare_route_battle(requested.token)
	if not prepared.ok: return null
	var result: Dictionary = subject.commit_route_battle(prepared)
	return result.combat if result.ok else null

func _restore(subject, data: Dictionary = {}) -> Dictionary:
	# Exercise canonical JSON sorting and lossless exact integer encoding too.
	var encoded := Save.encode_document({"run": subject.export_save() if data.is_empty() else data}, 1)
	if not encoded.ok: return encoded
	var decoded := Save.decode_document(encoded.text)
	if not decoded.ok: return decoded
	return Run.restore_save(decoded.payload.run, setup, subject.profile_state().clone_for_transaction(), subject.restore_context_for_tests())

func _abandonment() -> void:
	var subject = Fixture.new_run()
	var original: Dictionary = subject.export_save()
	var request: Dictionary = subject.abandonment_request()
	check(request.ok and subject.export_save() == original, "Viewing abandonment confirmation changes no committed state; dismissal is cancellation.")
	var detached: Dictionary = subject.clone_for_transaction()
	check(detached.run.abandon_run(request.token).ok and subject.export_save() == original, "Detached abandonment does not dispose or publish the previous owner.")
	var ended = detached.run
	check(ended.snapshot().status == "abandoned" and ended.run_summary().entered_rooms == 0 and ended.run_summary().player_hp == 30, "Fresh abandonment has a distinct outcome, zero fabricated visits and unchanged HP.")
	var restored := _restore(ended)
	check(restored.ok and restored.run.export_save() == ended.export_save(), "Fresh abandoned boundary restores exactly: " + str(restored.get("error", "")))
	check(not ended.abandon_run(request.token).ok and not ended.request_room_entry("d1a").ok and not ended.prepare_continue_battle().ok, "Abandoned run rejects duplicate abandonment, entry and replay.")
	check(ended.acknowledge_final_result(ended.snapshot().terminal.identity) and not ended.acknowledge_final_result(ended.snapshot().terminal.identity), "Final acknowledgement commits once and never grants anything.")
	check(_restore(ended).ok, "Acknowledged abandonment retains a valid checkpoint fingerprint.")
	for field in ["version", "outcome", "identity", "boundary_status", "acknowledged"]:
		for value in [null, [], {}, 42, "malformed", false]:
			if field == "acknowledged" and value is bool: continue
			var corrupt: Dictionary = ended.export_save()
			corrupt.terminal[field] = value
			check(not _restore(ended, corrupt).ok, "Reject malformed terminal %s=%s." % [field, str(value)])
	var corrupt: Dictionary = ended.export_save()
	corrupt.terminal.identity.checkpoint_signature = "forged"
	check(not _restore(ended, corrupt).ok, "Reject abandonment metadata not matching the retained authority.")
	corrupt = ended.export_save()
	corrupt.terminal.outcome = "defeat"
	check(not _restore(ended, corrupt).ok, "Abandonment cannot be reclassified as defeat.")
	subject = Fixture.new_run()
	request = subject.abandonment_request()
	var game = _enter(subject)
	check(game != null and not subject.abandon_run(request.token).ok, "Entering a room invalidates an old abandonment confirmation.")
	request = subject.abandonment_request()
	original = subject.export_save()
	var original_live: Dictionary = game.snapshot()
	game.pass_turn()
	check(game.player_hp < original.player_hp and subject.export_save() == original, "Live Combat advances while the durable abandonment boundary remains its exact entry.")
	detached = subject.clone_for_transaction()
	check(detached.run.abandon_run(request.token).ok and subject.current_battle() == game and game.snapshot() != original_live, "Preparing live abandonment retains the authoritative live scene until publication.")
	ended = detached.run
	check(ended.run_summary().player_hp == original.player_hp and ended.run_summary().entered_rooms == 1 and ended.run_summary().completed_rooms == 0 and ended.run_summary().defeated_enemy_count == 0, "Live abandonment summarizes committed entry HP and entered-but-uncompleted visit.")
	check(ended.export_save().entry_checkpoint == original.entry_checkpoint and ended.route_snapshot().visits == original.route.visits, "Live abandonment preserves checkpoint RNG and route history without mid-turn persistence.")
	restored = _restore(ended)
	check(restored.ok and restored.run.run_summary() == ended.run_summary(), "Abandoned battle survives JSON restart with the same truthful summary: " + str(restored.get("error", "")))
	if restored.ok:
		var snapshot: Dictionary = restored.run.export_save()
		check(not restored.run.continue_battle().ok and not restored.run.resolve_battle(game) and not restored.run.quit_to_home(game) and restored.run.export_save() == snapshot, "Restored abandoned checkpoint is read-only despite retained exact replay data.")
		var active: Dictionary = snapshot.active_battle
		check(not restored.run.resolve_room(active.run_id, active.node_id, active.visit_id, "completed") and not restored.run.complete_room_choice(active.run_id, active.node_id, active.visit_id, "anything"), "Direct generic callbacks cannot fabricate completion after abandonment.")
		check(not restored.run.prepare_relic_acquisition("relic_heart_stone").ok, "Terminal acquisition seam rejects all new relic acquisition.")

func _pending_and_defeat() -> void:
	var subject = ShopFixture.new_run()
	var game = _enter(subject)
	check(Integration.new()._win(game) and not subject.abandonment_request().ok, "Uncommitted terminal Combat must resolve its outcome before abandonment.")
	check(subject.resolve_battle(game) and not subject.abandonment_request().ok, "Unacknowledged battle result blocks abandonment.")
	var result: Dictionary = subject.snapshot().pending_result
	var reward: Dictionary = subject.pending_reward()
	check(subject.acknowledge_result(result.identity) and not subject.abandonment_request().ok, "Acknowledgement grants nothing and unresolved reward components still block abandonment.")
	check(subject.skip_reward(reward.identity).ok and not subject.abandonment_request().ok, "Resolving the rune choice alone cannot silently forfeit outstanding Gold.")
	check(subject.claim_reward_gold(reward.identity).ok and subject.abandonment_request().ok, "Abandonment becomes available after every required component and result settles.")
	var token: Dictionary = subject.abandonment_request().token
	check(ShopFixture.enter_shop(subject).ok and not subject.abandon_run(token).ok, "Entering a supported shop invalidates the prior confirmation.")
	var identity: Dictionary = subject.shop_snapshot().identity
	token = subject.abandonment_request().token
	check(subject.buy_shop_rune(identity, "rune-1").ok and not subject.abandon_run(token).ok, "A purchase invalidates abandonment even without changing route revision.")
	check(subject.abandon_run(subject.abandonment_request().token).ok and _restore(subject).ok, "Active shop can abandon with receipts and stock retained for validation.")
	check(not subject.buy_shop_rune(identity, "rune-2").ok and not subject.leave_shop(identity).ok and not subject.upgrade_shop_rune(identity, 0).ok, "Terminal shop rejects purchases, upgrades and Leave.")
	subject = Fixture.new_run()
	game = _enter(subject)
	while game.state == "playing": game.pass_turn()
	check(subject.resolve_battle(game) and subject.snapshot().is_terminal and not subject.snapshot().final_results_ready, "Committed real defeat is terminal while its encounter acknowledgement remains pending.")
	check(subject.run_summary().outcome == "defeat" and subject.run_summary().entered_rooms == 1 and subject.run_summary().completed_rooms == 0 and subject.run_summary().defeated_enemy_count == 0, "Defeat summary records entry without fabricating victory or completion.")
	check(_restore(subject).ok and not subject.abandonment_request().ok, "Pending defeat restores and cannot be reclassified as abandonment.")
	check(subject.acknowledge_result(subject.snapshot().pending_result.identity) and subject.snapshot().final_results_ready and not subject.snapshot().can_continue, "Defeat acknowledgement exposes final review without enabling active continuation.")
	check(subject.acknowledge_final_result(subject.snapshot().terminal.identity) and _restore(subject).ok, "Final defeat acknowledgement survives restart without extra resources.")
	var corrupt: Dictionary = subject.export_save()
	corrupt.terminal.outcome = "victory"
	check(not _restore(subject, corrupt).ok, "A defeat cannot claim tower victory by changing terminal metadata.")
	corrupt = subject.export_save()
	corrupt.terminal = {}
	check(not _restore(subject, corrupt).ok, "A current terminal save cannot omit its explicit outcome.")

func _summary() -> void:
	var subject = Fixture.new_run()
	var game = _enter(subject)
	check(Integration.new()._win(game) and subject.resolve_battle(game), "Summary first encounter uses legal battle actions.")
	check(subject.acknowledge_result(subject.snapshot().pending_result.identity), "First summary fixture result settles without rewards.")
	var node: String = subject.route_snapshot().nodes.filter(func(item): return item.state == "available")[0].id
	game = _enter(subject, node)
	check(Integration.new()._win(game) and subject.resolve_battle(game), "Summary repeated encounter uses another actual battle outcome.")
	var summary: Dictionary = subject.run_summary()
	check(summary.defeated_enemy_count == 2 and summary.defeated_enemies[0].encounter_id == summary.defeated_enemies[1].encounter_id and summary.defeated_enemies[0].visit_id != summary.defeated_enemies[1].visit_id, "Repeated enemy definitions count as separate victories by visit identity.")
	check(summary.owned_cards.size() == 8 and summary.owned_cards.all(func(card): return not card.effective_definition.get("temporary", false)), "Final owned collection excludes every generated temporary card.")
	check(summary.permanent_awards.is_empty() and subject.profile_state().snapshot().unlocked_definition_ids.size() == 4, "Summary does not misreport pre-existing profile unlocks as this run's awards.")
	check(not subject.snapshot().is_terminal and summary.outcome == "in_progress" and _restore(subject).ok, "Non-guardian victories remain in progress and summaries reconstruct on restore.")

func _guardian_orders() -> void:
	for acknowledge_first in [false, true]:
		for unlock_first in [false, true]:
			var subject = FullFixture.new_run()
			var played: Dictionary = FullFixture.play_to_guardian_pending(subject, "elite" if unlock_first else "normal")
			check(played.ok, "Complete legal nine-visit route reaches guardian choices: " + str(played.get("error", "")))
			if not played.ok: continue
			var result: Dictionary = subject.snapshot().pending_result
			check(result.role == "guardian" and not subject.snapshot().is_terminal and not subject.snapshot().tower_completed and not subject.abandonment_request().ok, "Guardian outcome is committed while all required choices remain distinct from final victory.")
			check(_restore(subject).ok, "Guardian pending result/rewards restore without replay.")
			var original: Dictionary = subject.export_save()
			if acknowledge_first:
				check(subject.acknowledge_result(result.identity) and subject.export_save().owned_cards == original.owned_cards and subject.export_save().gold == original.gold, "Early result acknowledgement grants no card or Gold.")
			var rewards: Array = subject.snapshot().reward_records.filter(func(record): return record.status == "pending")
			if unlock_first: rewards.reverse()
			var first: Dictionary = rewards[0]
			var claim: Dictionary = subject.choose_reward(first.identity, first.offered_ids[0]) if first.kind == "definition_unlock" else subject.skip_reward(first.identity)
			check(claim.ok and not subject.snapshot().is_terminal and not subject.snapshot().final_results_ready, "One guardian component cannot prematurely complete the tower.")
			check(_restore(subject).ok, "Partial guardian choice order restores from exact receipts.")
			check(FullFixture.finish_rewards(subject, false, unlock_first).ok and subject.snapshot().is_terminal and subject.snapshot().terminal.outcome == "victory", "Last required guardian choice establishes the distinct final victory.")
			if not acknowledge_first:
				check(not subject.snapshot().final_results_ready and subject.acknowledge_result(result.identity), "Late acknowledgement stays independently reachable after all guardian awards settle.")
			check(subject.snapshot().final_results_ready and subject.snapshot().tower_completed, "Completed tower review opens only after guardian choices and encounter acknowledgement.")
			var summary: Dictionary = subject.run_summary()
			check(summary.entered_rooms == 9 and summary.completed_rooms == 9 and summary.defeated_enemy_count == 6 and summary.outcome == "victory", "Final summary derives exactly nine entered/completed rooms and six actual enemy victories.")
			check(summary.permanent_awards.size() == 2 and summary.permanent_awards[0].definition_id != summary.permanent_awards[1].definition_id, "Only the boss and guardian's two committed definition unlocks appear in the summary.")
			check(summary.owned_cards.any(func(card): return card.upgrade_rank == 1 and card.effect_summary == "8 damage") and not summary.relics.is_empty(), "Final collection resolves its exact upgraded instance through shared effects and preserves relics.")
			var restored := _restore(subject)
			check(restored.ok and restored.run.run_summary() == summary, "Final ranked/relic/award summary reconstructs after lossless restart: " + str(restored.get("error", "")))
			check(not subject.choose_reward(first.identity, first.offered_ids[0]).ok and not subject.skip_reward(first.identity).ok and not subject.abandonment_request().ok and not subject.prepare_continue_battle().ok, "Completed guardian rejects duplicate rewards, abandonment and gameplay replay.")
			var corrupt: Dictionary = subject.export_save()
			corrupt.terminal.identity.node_id = "d6"
			check(not _restore(subject, corrupt).ok, "Shadeling's designated boss cannot substitute for the final guardian identity.")
			var unproven: Dictionary = subject.clone_for_transaction()
			unproven.run._terminal.clear()
			unproven.run._battle_health_records.erase(unproven.run._shop_key(unproven.run._shop_identity(subject._route._visits.back())))
			unproven.run._ensure_terminal()
			check(unproven.run._terminal.is_empty() and not _restore(unproven.run).ok, "A structural guardian completion without its actual committed battle boundary cannot establish terminal victory.")
			check(subject.acknowledge_final_result(subject.snapshot().terminal.identity) and _restore(subject).ok and subject.run_summary() == summary, "Final acknowledgement is durable and leaves the entire final summary unchanged.")
	var exhausted = FullFixture.new_run(42, true)
	var played: Dictionary = FullFixture.play_to_guardian_pending(exhausted)
	check(played.ok and FullFixture.finish_rewards(exhausted).ok, "Exhausted permanent pools still complete the legal guardian route.")
	check(exhausted.run_summary().permanent_awards.is_empty() and exhausted.snapshot().profile.unlocked_definition_ids.size() == 4 and exhausted.run_summary().owned_cards.size() == 9, "Exhausted awards grant no compensation, no definition copies, and no invented summary awards.")
	check(_restore(exhausted).ok, "Exhausted guardian receipts and terminal state reconstruct on restart.")

func _transaction_boundaries() -> void:
	var subject = Fixture.new_run()
	var before: Dictionary = subject.snapshot()
	var entry: Dictionary = subject.request_room_entry("d1a")
	var prepared: Dictionary = subject.prepare_route_battle(entry.token)
	check(prepared.ok and subject.snapshot() == before and not subject.abandonment_request().ok, "Prepared entry keeps the committed snapshot unchanged while rejecting reentrant abandonment.")
	subject.cancel_prepared_battle(prepared)
	check(subject.abandonment_request().ok, "Canceling prepared entry restores abandonment eligibility without entering a visit.")
	for variant in ["recovery", "satchel", "tithe", "reliquary", "desk"]:
		subject = ServiceFixture.new_run(42, variant)
		var won: Dictionary = ServiceFixture.win_battle(subject)
		var entered: Dictionary = ServiceFixture.enter_service(subject)
		check(won.ok and entered.ok, "Real predecessor fixture opens active " + variant + " for abandonment.")
		var service: Dictionary = subject.service_snapshot()
		var original: Dictionary = subject.export_save()
		check(subject.abandon_run(subject.abandonment_request().token).ok and _restore(subject).ok, "Abandoned " + variant + " retains its authentic retained offering and entry receipt.")
		check(subject.export_save().service_records == original.service_records and subject.route_snapshot().visits == original.route.visits and not subject.resolve_service(service.identity, "leave").ok, "Abandonment never completes " + variant + " and rejects a later Leave callback.")
	var standalone = Run.new(setup, 42)
	var entered: Dictionary = standalone.enter_battle()
	while entered.combat.state == "playing": entered.combat.pass_turn()
	check(standalone.resolve_battle(entered.combat) and standalone.snapshot().final_results_ready and standalone.run_summary().outcome == "defeat" and _restore(standalone).ok, "Retained standalone real defeat also exposes validated read-only final results.")
	var active = Fixture.new_run()
	var corrupt: Dictionary = active.export_save()
	corrupt.terminal = {"version": 1, "outcome": "victory", "identity": {}, "boundary_status": "tower_completed", "acknowledged": false}
	check(not _restore(active, corrupt).ok, "An untouched route cannot claim victory through invented terminal metadata.")
	corrupt = active.export_save()
	corrupt.summary = {"outcome": "victory", "defeated_enemy_count": 99}
	check(not _restore(active, corrupt).ok, "Unrecognized persisted summary metadata is rejected; all displayed statistics derive from authority.")
