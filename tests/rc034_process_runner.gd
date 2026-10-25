extends SceneTree
## Two independent processes. Every checkpoint comes from an ordinary production
## route using legal controller and room/reward APIs; no manufactured visits.
const Journey = preload("res://tests/helpers/rc034_journey.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Save = preload("res://scripts/core/local_save.gd")
var directory := "res://output/qa/rc-034/process"
var stage := "prepare"
var setup: Dictionary
var records: Array = []
var checks := 0
var assertions: Array = []
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): directory = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
	setup = Loader.load_setup().setup
	call_deferred("_run")

func validate(value: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(value.get("profile", {}), setup.catalog)
	return profile if not profile.ok else Run.restore_save(value.get("run", {}), setup, profile.profile)

func payload(subject) -> Dictionary:
	return {"profile": subject.profile_state().export_save(), "run": subject.export_save()}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	if stage == "prepare":
		for selection in [{"seed": 1, "branch": "normal"}, {"seed": 6, "branch": "elite"}]: _journey(selection.seed, selection.branch)
		FileAccess.open(directory.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes({"process_id": OS.get_process_id(), "records": records}))
	elif stage == "restart": _restart()
	else: check(false, "Unknown lifecycle stage.")
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "stage": stage, "process_id": OS.get_process_id(), "engine": Engine.get_version_info().string, "checkpoint_count": records.size()}, "\t"))
	print("RC-034 process %s: %d checks, %d failures; %d checkpoints" % [stage, checks, failures, records.size()])
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _retain(subject, label: String, extra: Dictionary = {}) -> Dictionary:
	var path := directory.path_join(label + ".json")
	var store := Save.new(path, validate)
	var initial := store.load()
	check(initial.ok and initial.status == "empty", label + " uses a fresh isolated location.")
	if not initial.ok or initial.status != "empty": return {}
	var saved := payload(subject)
	var written := store.commit(saved, initial.revision)
	check(written.ok, label + " durably validates exact production configuration/history: " + str(written.get("error", "")))
	var record := {"label": label, "path": path, "payload": saved, "run_snapshot": subject.snapshot()}
	record.merge(extra, true)
	records.append(record)
	return record

func _journey(seed: int, branch: String) -> void:
	var subject = Journey.new_run(seed)
	var prefix := "%s-seed%d" % [branch, seed]
	_retain(subject, prefix + "-map")
	for depth in range(1, 10):
		var id := Journey.next_node(subject, branch)
		var entered := Journey.enter(subject, id)
		check(entered.ok, "%s depth%d enters through ordinary production room API." % [prefix, depth])
		if not entered.ok: return
		var label := "%s-d%d" % [prefix, depth]
		if entered.has("combat"):
			var game = entered.combat
			var commands: Array = []
			var controller := Controller.new(game)
			controller.command_resolved.connect(func(outcome):
				check(outcome.accepted, "%s legal %s accepted." % [label, outcome.command])
				if outcome.accepted: commands.append({"command": outcome.command, "arguments": outcome.arguments.duplicate(true)}))
			var entry := _retain(subject, label + "-entry", {"opening": game.snapshot(), "commands": commands})
			var player := Player.new()
			for turn in 80:
				if game.state != "playing": break
				if not player.play_turn(controller):
					check(false, label + " legal player failed.")
					controller.dispose()
					return
			entry.terminal_snapshot = game.snapshot()
			controller.dispose()
			check(game.state in ["victory", "defeat"] and subject.resolve_battle(game), label + " resolves only its actual terminal Combat outcome.")
			_retain(subject, label + "-pending-outcome")
			var offer: Dictionary = subject.pending_reward()
			if not offer.is_empty():
				var definition := Journey.choose_card(offer)
				var chosen: Dictionary = subject.choose_reward(offer.identity, definition) if not definition.is_empty() else subject.skip_reward(offer.identity)
				check(chosen.ok, label + " resolves real retained run-copy offer.")
				_retain(subject, label + "-reward-receipt")
			check(Journey.finish_rewards(subject).ok, label + " finishes every required choice and separate result acknowledgement.")
			_retain(subject, label + "-settled")
			if game.state == "defeat": break
		else:
			_retain(subject, label + "-active-service")
			check(Journey.finish_room(subject).ok, label + " commits actual shop/service decision.")
			_retain(subject, label + "-settled")
	var final: Dictionary = subject.snapshot()
	check(final.status == ("tower_completed" if branch == "normal" else "defeated") and final.route.visit_count == 9, prefix + " preserves observed final outcome after all nine visits.")
	_retain(subject, prefix + "-final")

func _restart() -> void:
	var expected: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(directory.path_join("expected.bin")))
	check(expected.process_id != OS.get_process_id(), "Restart runs in a different operating-system process.")
	records = expected.records
	var enemies := {}
	for record in records:
		var label: String = record.label
		var loaded := Save.new(record.path, validate).load()
		check(loaded.ok and loaded.payload == record.payload, label + " loads original durable bytes with exact int64 resources, IDs and RNG.")
		if not loaded.ok: continue
		var restored := validate(loaded.payload)
		check(restored.ok and not restored.migrated, label + " restores current production ownership without migration.")
		if not restored.ok: continue
		var subject = restored.run
		check(payload(subject) == record.payload, label + " re-exports identical committed checkpoint, policies and receipts.")
		if record.has("opening"):
			var entered: Dictionary = subject.continue_battle()
			check(entered.ok and entered.combat.snapshot() == record.opening, label + " reconstructs exact entry rather than any mid-turn state.")
			if not entered.ok: continue
			enemies[subject.snapshot().current_encounter_id] = true
			var controller := Controller.new(entered.combat)
			var accepted := true
			for command in record.commands:
				if not controller.command(command.command, command.arguments):
					accepted = false
					break
			check(accepted and entered.combat.snapshot() == record.terminal_snapshot, label + " exact recorded controller replay reproduces terminal result, phase, health and all random streams.")
			controller.dispose()
		elif subject.final_results_ready():
			var before: Dictionary = subject.export_save()
			check(not subject.continue_battle().ok and not subject.request_room_entry("d1a").ok and subject.export_save() == before, label + " terminal review cannot replay encounters or consume visits.")
	check(enemies.size() == 5, "Fresh-process replay covers both normals, Chain Warden, Shadeling and Bell Keeper.")
