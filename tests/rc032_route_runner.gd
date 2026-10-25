extends SceneTree
## Real complete-route checks. All navigation, Combat and receipts use public
## gameplay APIs; this excluded verifier never edits progression or resources.
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
var checks := 0
var failures := 0
var assertions: Array = []
var output := "res://output/qa/rc-032/routes"
var histories: Array = []
var command_traces: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": message})
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): output = arg.trim_prefix("--save-root=")
	DirAccess.make_dir_recursive_absolute(output)
	for branch in ["normal", "elite"]:
		for exhausted in [false, true]:
			_route(branch, exhausted)
	FileAccess.open(output.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "histories": histories}, "  ") + "\n")
	FileAccess.open(output.path_join("legal-command-traces.json"), FileAccess.WRITE).store_string(JSON.stringify(command_traces, "  ") + "\n")
	print("RC-032 complete routes: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _restore(subject, context: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(subject.profile_state().export_save(), Loader.load_setup().setup.catalog, true)
	return Run.restore_save(subject.export_save(), Loader.load_setup().setup, profile.profile, context) if profile.ok else profile

func _route(branch: String, exhausted: bool) -> void:
	var tag := branch + ("-exhausted" if exhausted else "-unlocks")
	var subject = Fixture.new_run(42, exhausted)
	var context := Fixture.context_for(subject)
	var history: Array = []
	check(subject.snapshot().player_hp == 30 and subject.snapshot().gold == 0 and subject.snapshot().owned_cards.size() == 8, tag + ": fixture starts unchanged 30 HP, zero Gold and eight real cards.")
	check(subject.route_snapshot().visits.is_empty(), tag + ": Home New Run candidate has an entirely unvisited map.")
	for depth in range(1, 10):
		var before: Dictionary = subject.export_save()
		var id := Fixture.next_node(subject, branch)
		var node: Dictionary = subject.inspect_node(id)
		check(subject.export_save() == before, tag + ": inspection is pure at depth %d." % depth)
		check(node.get("depth") == depth, tag + ": exactly the next route depth is reachable.")
		var entered := Fixture.enter_next(subject, branch)
		check(entered.ok, tag + ": explicit room entry succeeds at depth %d: %s" % [depth, entered.get("error", "")])
		if not entered.ok: return
		var restored := _restore(subject, context)
		check(restored.ok, tag + ": entry checkpoint validates: " + str(restored.get("error", "")))
		if not restored.ok: return
		if entered.has("combat"):
			var opening: Dictionary = entered.combat.snapshot()
			var replay: Dictionary = restored.run.continue_battle()
			check(replay.ok and replay.combat.snapshot() == opening, tag + ": interrupted entry reconstructs exact Combat snapshot.")
			check(subject.continue_battle().combat == entered.combat, tag + ": live Resume retains the same Combat model.")
			var commands: Array = []
			check(Fixture.win_combat(entered.combat, commands), tag + ": legal commands defeat " + node.enemy_id)
			command_traces.append({"variant": tag, "visit": depth, "node": id, "enemy": node.enemy_id, "commands": commands})
			check(not commands.is_empty() and commands.all(func(command): return command.accepted) and commands.any(func(command): return command.command == "cast"), tag + ": every logged controller action is accepted and includes genuine casts.")
			if entered.combat.state != "victory": return
			check(subject.resolve_battle(entered.combat), tag + ": real terminal handoff commits once.")
			check(not subject.resolve_battle(entered.combat), tag + ": duplicate battle callback is rejected.")
			if depth == 6:
				check(not subject.snapshot().tower_completed, tag + ": Shadeling is distinct from the final guardian and does not complete the tower.")
			if depth == 9:
				check(not subject.snapshot().tower_completed, tag + ": required guardian choices lock completed-tower state.")
				if branch == "elite":
					var resources: Dictionary = subject.export_save()
					check(subject.acknowledge_result(subject.snapshot().pending_result.identity), tag + ": guardian result acknowledgement can precede awards.")
					check(subject.snapshot().owned_cards == resources.owned_cards and subject.snapshot().gold == resources.gold, tag + ": acknowledgement grants nothing.")
					check(not subject.snapshot().tower_completed, tag + ": acknowledgement cannot bypass pending choices.")
			var settled := Fixture.finish_rewards(subject, true, branch == "elite")
			check(settled.ok, tag + ": real rewards and independent acknowledgement resolve: " + str(settled.get("error", "")))
			if not settled.ok: return
		else:
			var room_result := Fixture.finish_room(subject)
			check(room_result.ok, tag + ": actual item/service transaction resolves: " + str(room_result.get("error", "")))
			if not room_result.ok: return
		var settled_restore := _restore(subject, context)
		check(settled_restore.ok, tag + ": chronological owned collection/HP/Gold validates after depth %d: %s" % [depth, settled_restore.get("error", "")])
		if not settled_restore.ok: return
		history.append({"depth": depth, "node": id, "family": node.room_type, "encounter": node.encounter_id, "hp": subject.snapshot().player_hp, "gold": subject.snapshot().gold, "cards": subject.snapshot().owned_cards.size(), "relics": subject.snapshot().relics})
	var state: Dictionary = subject.snapshot()
	var families: Array = history.map(func(visit): return visit.family)
	check(families == ["normal", "event", "normal", "normal", branch, "normal", "shop", "recovery", "guardian"], tag + ": nine legal visits preserve the intended normal/elite branch and room-family order.")
	check(history[5].encounter == "training_shadeling" and history[8].encounter == "rc032_calibration_guardian" and history[5].encounter != history[8].encounter, tag + ": designated Shadeling boss and final fixture guardian have separate committed encounter identities.")
	check(state.tower_completed and state.route.visit_count == 9 and state.route.completed_count == 9, tag + ": exactly nine completed visits settle the fixture tower.")
	check(state.completed_encounters.size() == 6, tag + ": repeated calibration definition IDs count as six separate battle victories.")
	check(state.owned_cards.filter(func(card): return card.uid == 0 and card.upgrade_rank == 1).size() == 1, tag + ": paid shop upgrade carries its exact UID to final collection.")
	check(state.owned_cards.size() == 9 and state.owned_cards.all(func(card): return card.id != "free_spark"), tag + ": real shop purchase adds one owned card; generated temporaries are excluded.")
	check(state.relics.size() == (1 if branch == "normal" else 2), tag + ": actual shop and optional Reliquary relics remain owned.")
	check(state.summary.entered_rooms == 9 and state.summary.completed_rooms == 9 and state.summary.defeated_enemy_count == 6, tag + ": final summary derives exact room/victory counts from history.")
	check(state.summary.owned_cards.filter(func(card): return card.uid == 0 and card.upgrade_rank == 1 and card.effect_summary.contains("8")).size() == 1, tag + ": summary uses the shared resolver for upgraded Spark's actual eight damage.")
	var unlocks: Array = state.reward_records.filter(func(record): return record.kind == "definition_unlock" and record.resolution == "unlocked")
	var empty_awards: Array = state.reward_records.filter(func(record): return record.kind == "definition_unlock" and record.resolution == "exhausted")
	check(unlocks.size() == (0 if exhausted else 2) and empty_awards.size() == (2 if exhausted else 0), tag + ": permanent definition award receipts distinguish real unlocks and exhausted no-award milestones.")
	check(state.summary.permanent_awards.size() == unlocks.size(), tag + ": summary includes only this run's actually committed permanent awards.")
	check(not subject.request_room_entry("d9").ok and not subject.continue_battle().ok, tag + ": terminal gameplay entry and Resume reject.")
	for reward in state.reward_records:
		check(not subject.claim_reward_gold(reward.identity).ok and not subject.choose_reward(reward.identity, "spark").ok, tag + ": terminal receipts cannot pay twice.")
	histories.append({"variant": tag, "visits": history, "final": state})
