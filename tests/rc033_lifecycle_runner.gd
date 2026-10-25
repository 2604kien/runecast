extends SceneTree
## Run with --stage=prepare, then --stage=restart in a fresh pinned Godot process.
## expected.bin is comparison evidence only; owners restore from the real v6 save.
const Fixture = preload("res://tests/helpers/rc033_lifecycle_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
var directory := "res://output/qa/rc-033/lifecycle"
var stage := "prepare"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary
var context: Dictionary
var evidence: Dictionary = {}

func check(ok: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": ok, "description": description})
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): directory = argument.trim_prefix("--save-root=")
		if argument.begins_with("--stage="): stage = argument.trim_prefix("--stage=")
	call_deferred("_run")

func payload(subject) -> Dictionary:
	return {"profile": subject.profile_state().export_save(), "run": subject.export_save()}

func validate(value: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(value.get("profile", {}), setup.catalog, true)
	return profile if not profile.ok else Run.restore_save(value.get("run", {}), setup, profile.profile, context)

func _run() -> void:
	setup = Loader.load_setup().setup
	context = Fixture.context_for(Fixture.new_run())
	DirAccess.make_dir_recursive_absolute(directory)
	if stage == "prepare": _prepare()
	elif stage == "restart": _restart()
	else: check(false, "Unsupported lifecycle stage.")
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "process_id": OS.get_process_id(), "stage": stage, "engine": Engine.get_version_info().string}, "\t"))
	print("RC-033 lifecycle %s: %d checks, %d failures" % [stage, checks, failures])
	context.clear()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _prepare() -> void:
	var subject = Fixture.new_run()
	var requested: Dictionary = subject.request_room_entry("d1a")
	check(requested.ok, "Explicit fixture route permits only the normal room entry API.")
	if not requested.ok: return
	var candidate: Dictionary = subject.prepare_route_battle(requested.token)
	check(candidate.ok, "Validated phase content constructs the uncommitted production Combat candidate.")
	if not candidate.ok: return
	check(candidate.setup.encounter.max_health == 80 and candidate.setup.encounter.phase_two.health_threshold == 74 and candidate.setup.encounter.intents == [8, 12, 16] and candidate.setup.encounter.phase_two.intents == [12, 16, 20], "Lifecycle fixture labels its independent high threshold and retains both roster sequences.")
	check(candidate.combat.player_hp == 30 and candidate.combat.encounter.player_max_health == 30 and candidate.combat.owned_cards == setup.owned_cards and candidate.combat.energy == 3, "Lifecycle uses genuine 30 HP, ordinary energy and eight-card starter; no resource/HP injection.")
	check(subject.commit_route_battle(candidate).ok, "Run commits one valid encounter entry.")
	var game = subject.current_battle()
	var opening: Dictionary = game.snapshot()
	var original: Dictionary = subject.export_save()
	var store := Save.new(directory.path_join("active.json"), validate)
	var loaded := store.load()
	check(loaded.ok and loaded.status == "empty", "Fresh isolated save location is empty.")
	if not loaded.ok or loaded.status != "empty": return
	var written := store.commit(payload(subject), loaded.revision)
	check(written.ok, "Entry checkpoint writes through the validated rc028_local_v1 durable transaction: " + str(written.get("error", "")))
	if not written.ok: return
	var durable_bytes := FileAccess.get_file_as_bytes(store.path)
	var commands: Array = []
	var controller := Controller.new(game)
	controller.command_resolved.connect(func(outcome):
		if outcome.accepted: commands.append({"command": outcome.command, "arguments": outcome.arguments.duplicate(true)}))
	var plan: Dictionary = Player.new().prepare(controller)
	check(not plan.is_empty() and game.forecast().valid and game.forecast().damage >= 6, "Legal planner constructs a real affordable standard-rune circuit from the dealt hand and sampled kit.")
	if plan.is_empty():
		controller.dispose()
		return
	check(controller.command("cast"), "Accepted real Cast crosses the lifecycle threshold.")
	var result: Dictionary = game.last_result()
	var retaliation: Array = result.events.filter(func(event): return event.type == "retaliation")
	check(game.enemy_hp <= 74 and game.state == "playing" and game.enemy_action().phase == 2 and game.intent() == 12 and retaliation.size() == 1 and retaliation[0].incoming == 8, "Original announced 8 retaliates before surviving phase two begins at 12.")
	check(game.run_handoff().ok and subject.snapshot().player_hp == game.player_hp, "Run accepts phased battle handoff without changing immutable configuration.")
	# Prepare the next board with a genuine editable endpoint orientation. This
	# preserves a real Undo entry and tests preparation without another attack.
	var begin: int = game.board.find(game.board.filter(func(piece): return piece.get("kind") == "begin")[0])
	check(controller.command("rotate", {"index": begin}), "Next-turn preparation uses a legal endpoint rotation command.")
	var prepared: Dictionary = game.snapshot()
	var random_states: Dictionary = game.run_handoff().rng_states
	check(prepared.undo_count > 0 and prepared.enemy_action.phase == 2 and not prepared.hand.is_empty(), "Phase two retains board preparation, hand and Undo state.")
	for count in range(10):
		var resumed: Dictionary = subject.continue_battle()
		check(resumed.ok and resumed.combat == game and game.snapshot() == prepared and game.run_handoff().rng_states == random_states, "Repeated live Resume preserves the exact phase-two model, preparation and RNG.")
	var live: Dictionary = subject.prepare_continue_battle()
	check(live.ok and live.combat == game and subject.commit_continue_battle(live).ok and game.snapshot() == prepared, "Staged live Resume used by the shell retains the same prepared phase-two owner.")
	var after_resume: Dictionary = subject.export_save()
	# Candidate bookkeeping may advance, but persisted entry/content/ownership
	# remain identical and no phase/index/action field is written to the envelope.
	check(after_resume.entry_checkpoint == original.entry_checkpoint and after_resume.content == original.content and after_resume.rng_states == original.rng_states and after_resume.owned_cards == original.owned_cards and after_resume.player_hp == 30 and not after_resume.has("enemy_action") and not after_resume.entry_checkpoint.has("enemy_action"), "Disk contract retains original entry/RNG/HP/ownership and immutable phase config signature, never mid-turn phase state.")
	check(FileAccess.get_file_as_bytes(store.path) == durable_bytes, "Playing, inspection-independent snapshots and live Resume perform no disk save.")
	evidence = {"opening": opening, "prepared": prepared, "rng": random_states, "commands": commands,
		"payload": Save.decode_document(durable_bytes.get_string_from_utf8()).payload,
		"durable_bytes": durable_bytes, "phase_cast": result, "prepare_process_id": OS.get_process_id()}
	FileAccess.open(directory.path_join("expected.bin"), FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(directory.path_join("legal-commands.json"), FileAccess.WRITE).store_string(JSON.stringify(commands, "\t"))
	controller.dispose()
	check(subject.quit_to_home(game) and subject.snapshot().status == "replay_pending", "Confirmed Quit discards live phase/preparation while preserving the battle-entry checkpoint.")
	var replay: Dictionary = subject.continue_battle()
	check(replay.ok and replay.combat != game and replay.combat.snapshot() == opening, "Quit/Continue starts the same visit from exact phase-one opening.")
	if replay.ok:
		_replay(replay.combat)
		var before: Dictionary = subject.export_save()
		check(not subject.quit_to_home(game) and not subject.resolve_battle(game) and subject.export_save() == before, "Old phase-two model callbacks cannot quit or resolve the replacement generation.")
	check(FileAccess.get_file_as_bytes(store.path) == durable_bytes, "Quit and replay retain existing durable bytes until a supported checkpoint transaction.")

func _replay(game) -> void:
	var controller := Controller.new(game)
	for command in evidence.commands:
		check(controller.command(command.command, command.arguments), "Exact recorded replay command remains accepted: " + str(command.command))
	check(game.snapshot() == evidence.prepared and game.run_handoff().rng_states == evidence.rng and game.enemy_action().phase == 2 and game.intent() == 12, "Replayed commands reproduce complete phase-two preparation, health, hand, board, kit and all RNG streams.")
	controller.dispose()

func _restart() -> void:
	var expected := directory.path_join("expected.bin")
	check(FileAccess.file_exists(expected), "Fresh process has independent comparison evidence.")
	if not FileAccess.file_exists(expected): return
	evidence = bytes_to_var(FileAccess.get_file_as_bytes(expected))
	check(evidence.prepare_process_id != OS.get_process_id(), "Restart verification runs in a genuinely distinct Godot process.")
	var store := Save.new(directory.path_join("active.json"), validate)
	var loaded := store.load()
	check(loaded.ok and loaded.status == "valid", "Fresh save owner validates durable run/profile/envelope.")
	if not loaded.ok: return
	check(FileAccess.get_file_as_bytes(store.path) == evidence.durable_bytes and loaded.payload == evidence.payload, "Only unchanged original checkpoint bytes supply restored state.")
	check(loaded.payload.run.version == 6 and loaded.payload.profile.version == 1 and Save.SCHEMA == "rc028_local_v1", "Run v6, profile v1 and local envelope version are unchanged.")
	var restored := validate(loaded.payload)
	check(restored.ok and restored.run.current_battle() == null and restored.run.snapshot().status == "replay_pending", "Process restart restores battle-entry replay ownership, without a mid-turn model.")
	if not restored.ok: return
	var entered: Dictionary = restored.run.continue_battle()
	check(entered.ok and entered.combat.snapshot() == evidence.opening and entered.combat.enemy_action().phase == 1 and entered.combat.intent() == 8, "Fresh process rebuilds original phase-one first intent and exact opening resources.")
	if entered.ok: _replay(entered.combat)
	var production := Run.restore_save(loaded.payload.run, setup, restored.run.profile_state().clone_for_transaction())
	check(not production.ok, "Excluded lifecycle content cannot restore without explicit fixture registration.")
	var original_context := context
	context = context.duplicate(true)
	context.resolver = Fixture.FixtureResolver.new(73)
	for registered in context.setups.values():
		if registered.encounter.has("phase_two"): registered.encounter.phase_two.health_threshold = 73
	check(not validate(loaded.payload).ok, "Changing registered threshold rejects the original configuration signature instead of weakening save validation.")
	context = original_context
	var corrupt: Dictionary = loaded.payload.duplicate(true)
	corrupt.run.content.signature = "0".repeat(64)
	check(not validate(corrupt).ok, "Forged content signatures do not discard or reinterpret original phase configuration.")
	corrupt = loaded.payload.duplicate(true)
	corrupt.run.enemy_action = evidence.prepared.enemy_action
	check(not validate(corrupt).ok, "Unsupported persisted mid-turn phase/action state is rejected.")
	check(FileAccess.get_file_as_bytes(store.path) == evidence.durable_bytes, "Read-only hostile-save checks preserve genuine durable progress.")
