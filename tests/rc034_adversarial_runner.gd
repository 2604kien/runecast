extends SceneTree
## Exact selected-content binding regression. Genuine legal first victory;
## only detached serialized copies are corrupted for rejection checks.
const Loader = preload("res://scripts/core/content_loader.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Resolver = preload("res://scripts/core/encounter_resolver.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Journey = preload("res://tests/helpers/rc034_journey.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
var checks := 0
var failures: Array = []

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	var run = Journey.new_run(0)
	var unvisited: Dictionary = run.export_save()
	var future: Dictionary = Resolver.new().resolve(run.inspect_node("d9"), run._entry_data())
	var premature: Dictionary = unvisited.duplicate(true)
	premature.content = {"encounter_id": "bell_keeper", "board_id": "board_belfry", "signature": Run.content_signature(future.setup)}
	check(not _restore(premature, run.profile_state()).ok, "Unvisited route cannot claim a future selected battle configuration")
	var entered: Dictionary = Journey.enter(run, "d1a")
	check(entered.ok, "Enter genuine first production visit")
	if not entered.ok: _finish(); return
	var controller := Controller.new(entered.combat)
	var player := Player.new()
	for turn in 60:
		if entered.combat.state != "playing": break
		check(player.play_turn(controller), "Only legal controller actions prepare and resolve this turn")
	controller.dispose()
	check(entered.combat.state == "victory" and run.resolve_battle(entered.combat), "Genuine ordinary-resource victory enters pending reward boundary")
	if run.snapshot().pending_result.is_empty(): _finish(); return
	var original: Dictionary = run.export_save()
	check(_restore(original, run.profile_state()).ok, "Unchanged pending result restores")
	var current: Dictionary = run.inspect_node("d1a")
	var other: Dictionary = {}
	for node in run.route_snapshot().nodes:
		if node.encounter_id == current.encounter_id and node.board_id != current.board_id:
			other = node
			break
	check(not other.is_empty(), "Seed supplies another registered board for the same enemy")
	if other.is_empty(): _finish(); return
	var resolved: Dictionary = Resolver.new().resolve(other, run._entry_data())
	check(resolved.ok, "Alternative content tuple is itself valid but belongs to another visit")
	var forged: Dictionary = original.duplicate(true)
	forged.content.board_id = other.board_id
	forged.content.signature = Run.content_signature(resolved.setup)
	check(not _restore(forged, run.profile_state()).ok, "Pending outcome rejects same enemy content from a different board/visit")
	check(Journey.finish_rewards(run).ok, "Real required reward claim and result acknowledgement settle first victory")
	var settled: Dictionary = run.export_save()
	check(_restore(settled, run.profile_state()).ok, "Unchanged settled boundary restores")
	forged = settled.duplicate(true)
	forged.content.board_id = other.board_id
	forged.content.signature = Run.content_signature(resolved.setup)
	check(not _restore(forged, run.profile_state()).ok, "Settled boundary retains exact last selected battle board")
	forged.content = {"encounter_id": "bell_keeper", "board_id": "board_belfry", "signature": Run.content_signature(future.setup)}
	check(not _restore(forged, run.profile_state()).ok, "Settled boundary cannot substitute a different future enemy with a valid registered signature")
	_finish()

func _restore(data: Dictionary, profile: RefCounted) -> Dictionary:
	return Run.restore_save(data, Loader.load_setup().setup, profile.clone_for_transaction())

func _finish() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-034/adversarial")
	FileAccess.open("res://output/qa/rc-034/adversarial/results.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "failure_count": failures.size()}, "\t"))
	print("RC-034 adversarial: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
