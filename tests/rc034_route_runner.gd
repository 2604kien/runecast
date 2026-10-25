extends SceneTree
## Production registry, original-history compatibility and durable entry boundaries.
const Route = preload("res://scripts/core/route_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Resolver = preload("res://scripts/core/encounter_resolver.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Save = preload("res://scripts/core/local_save.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
var checks := 0
var failures: Array = []
var assertions: Array = []
var setup: Dictionary
var directory := "res://output/qa/rc-034/route"

class ReentrantResolver extends Resolver:
	var callback: Callable
	func resolve(node: Dictionary, entry: Dictionary) -> Dictionary:
		if callback.is_valid(): callback.call()
		return super(node, entry)

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-root="): directory = argument.trim_prefix("--save-root=")
	setup = Loader.load_setup().setup
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	_graphs()
	_entries()
	_legacy()
	_transactions()
	FileAccess.open(directory.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures.size(), "assertions": assertions, "engine": Engine.get_version_info().string}, "\t"))
	print("RC-034 route: %d checks, %d failures" % [checks, failures.size()])
	await process_frame
	quit(0 if failures.is_empty() else 1)

func fresh(seed: int = 42, resolver = null):
	return Run.new(setup, seed, true, Callable(), resolver, Profile.production_rules(), Profile.new(setup.catalog))

func payload(subject) -> Dictionary:
	return {"profile": subject.profile_state().export_save(), "run": subject.export_save()}

func validate(value: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(value.get("profile", {}), setup.catalog)
	return profile if not profile.ok else Run.restore_save(value.get("run", {}), setup, profile.profile)

func _graphs() -> void:
	var coverage := {}
	for seed in range(64):
		var graph := Route.generate(seed)
		check(Route.validate_graph(graph).ok and graph == Route.generate(seed), "Seed %d reproduces the same bounded registered route." % seed)
		var normals := true
		for node in graph.nodes:
			if node.encounter_role == "normal":
				normals = normals and node.enemy_id in ["wickling", "stone_sentinel"]
				coverage[node.encounter_id + "/" + node.board_id] = true
			if not node.enemy_id.is_empty(): check(Resolver.supported_node(node) and not node.content_pending, "Seed %d %s binds exact available actor, encounter, role and board." % [seed, node.id])
		check(normals, "Seed %d normal pool excludes boss, elite and guardian." % seed)
		var paths := Route._paths(_index(graph.nodes), graph.entry_node_ids)
		check(paths.size() == 8 and paths.all(func(path): return path.size() == 9 and path[5] == "d6" and path[8] == "d9"), "Seed %d preserves eight paths with Shadeling sixth and Bell Keeper ninth." % seed)
	check(coverage.size() == 4, "Deterministic normal coverage includes both actors on both Gallery and Ossuary.")
	for kind in ["empty", "mixed", "actor", "role", "board", "fixture", "path"]:
		var graph := Route.generate(42)
		match kind:
			"empty": graph.nodes[0].encounter_id = ""
			"mixed":
				for node in graph.nodes:
					if node.encounter_role == "normal": node.encounter_id = ""
			"actor": graph.nodes[0].enemy_id = "shadeling"
			"role": graph.nodes[0].encounter_role = "boss"
			"board": graph.nodes[0].board_id = "board_training"
			"fixture": graph.nodes[0].encounter_id = "rc007_entry_probe_next"
			"path": graph.nodes[0].encounter_id = "res://tests/fixtures/rc033/encounter.json"
		check(not Route.validate_graph(graph).ok and not Route.validate_graph(graph, true).ok, "Rejects %s graph as neither new production nor complete original planned graph." % kind)

func _index(nodes: Array) -> Dictionary:
	var result := {}
	for node in nodes: result[node.id] = node
	return result

func _entries() -> void:
	var covered := {}
	for seed in range(8):
		for id in ["d1a", "d1b"]:
			var subject = fresh(seed)
			var node: Dictionary = subject.inspect_node(id)
			var key: String = node.encounter_id + "/" + node.board_id
			if covered.has(key): continue
			covered[key] = true
			var before: Dictionary = subject.export_save()
			var request: Dictionary = subject.request_room_entry(id)
			check(request.ok and subject.export_save() == before and not node.content_pending, "%s inspection/request consumes no visit or resources." % key)
			var prepared: Dictionary = subject.prepare_route_battle(request.token)
			check(prepared.ok and subject.commit_route_battle(prepared).ok, "%s enters through production registration." % key)
			if not prepared.ok: continue
			var game = subject.current_battle()
			var opening: Dictionary = game.snapshot()
			var saved := payload(subject)
			var restored := validate(saved)
			check(restored.ok, "%s exact committed entry restores: %s" % [key, restored.get("error", "")])
			if restored.ok:
				check(restored.run.continue_battle().ok and restored.run.current_battle().snapshot() == opening, "%s restart replays identical cards/endpoints/kits/health/announced attack." % key)
			check(not subject.commit_route_battle(prepared).ok and not subject.prepare_route_battle(request.token).ok and subject.export_save() == saved.run, "%s duplicate and stale entry cannot consume another visit." % key)
			var controller := Controller.new(game)
			check(controller.command("pass"), "%s legal Pass changes the live battle." % key)
			var live: Dictionary = game.snapshot()
			check(subject.continue_battle().combat == game and game.snapshot() == live, "%s live Resume keeps the same battle." % key)
			check(subject.export_save() == saved.run, "%s live turn never overwrites committed entry checkpoint." % key)
			controller.dispose()
			for fault in ["board", "signature", "path", "excluded", "role"]:
				var corrupt: Dictionary = saved.duplicate(true)
				match fault:
					"board": corrupt.run.content.board_id = "board_belfry"
					"signature": corrupt.run.content.signature = "0".repeat(64)
					"path": corrupt.run.content.encounter_id = "res://data/production_encounter.json"
					"excluded": corrupt.run.content.encounter_id = "rc007_entry_probe_next"
					"role": corrupt.run.route.graph.nodes[0].encounter_role = "guardian"
				check(not validate(corrupt).ok, "%s restore rejects forged %s." % [key, fault])
	check(covered.size() == 4, "Opening-entry save/replay exercises all four normal combinations.")
	for field in ["enemy_id", "encounter_id", "encounter_role", "board_id"]:
		var subject = fresh()
		subject._route._nodes.d1a[field] = "mismatched"
		var before: Dictionary = subject.export_save()
		check(not subject.prepare_route_battle(subject.request_room_entry("d1a").token).ok and subject.export_save() == before, "Mismatched %s rejects before visit/resource/entry counters change." % field)
	var resolver := ReentrantResolver.new()
	var subject = fresh(42, resolver)
	var token: Dictionary = subject.request_room_entry("d1b").token
	resolver.callback = func(): check(not subject.prepare_route_battle(token).ok, "Reentrant resolver cannot prepare another entry.")
	var prepared: Dictionary = subject.prepare_route_battle(token)
	check(prepared.ok and subject.commit_route_battle(prepared).ok and subject.route_snapshot().visit_count == 1, "Outer validated entry still commits exactly one visit.")
	resolver.callback = Callable()

func _legacy() -> void:
	for version in [1, 2, 3, 5]:
		var family := "rc028" if version == 1 else "rc029" if version == 2 else "rc030" if version == 3 else "rc032"
		var path := "res://tests/fixtures/%s/production-v%d.json" % [family, version]
		var original := FileAccess.get_file_as_bytes(path)
		var loaded := Save.new(path, validate).load()
		check(loaded.ok, "Genuine production v%d envelope validates without rewriting original bytes: %s" % [version, loaded.get("error", "")])
		if not loaded.ok: continue
		var restored := validate(loaded.payload)
		var raw: Dictionary = loaded.payload.run.route
		var expected: Dictionary = raw.duplicate(true)
		for node in expected.graph.nodes:
			if node.encounter_role in ["normal", "elite", "guardian"]: node.encounter_id = node.enemy_id
			node.content_pending = false
		check(restored.ok and restored.migrated and restored.run.export_save().route == expected, "Genuine v%d hydrates only IDs/availability after original validation; identities, visits, selections, events, edges and RNG unchanged." % version)
		check(FileAccess.get_file_as_bytes(path) == original and restored.run.snapshot().rng_states == loaded.payload.run.rng_states, "Genuine v%d source bytes and all three random streams remain unchanged." % version)
		var once := payload(restored.run)
		check(validate(once).ok and not validate(once).migrated and validate(once).run.export_save() == once.run, "Genuine v%d promotion is idempotent and can enter registered production content." % version)
		check(restored.run.prepare_route_battle(restored.run.request_room_entry("d1b").token).ok, "Genuine v%d previously planned opening now prepares a real encounter." % version)
		var mixed: Dictionary = loaded.payload.duplicate(true)
		mixed.run.route.graph.nodes[0].encounter_id = mixed.run.route.graph.nodes[0].enemy_id
		check(not validate(mixed).ok, "Genuine v%d cannot use mixed historical/current IDs to bypass compatibility." % version)
		# Build a valid signed historical unvisited abandonment specimen through
		# the ordinary abandonment API. This is synthetic boundary coverage;
		# genuine predecessor envelopes above retain original provenance.
		if version != 5: continue
		var terminal = fresh(42)
		var old_route: Dictionary = raw.duplicate(true)
		old_route.run_id = terminal.snapshot().run_id
		terminal._route = Route.restore_save(old_route, old_route.run_id).route
		check(terminal.abandon_run(terminal.abandonment_request().token).ok, "Historical planned checkpoint receives a real signed abandonment boundary.")
		var signed := payload(terminal)
		var terminal_restored := validate(signed)
		check(terminal_restored.ok and terminal_restored.run.export_save() == signed.run and not terminal_restored.migrated, "Genuine signed historical shape remains exact and terminal; no hydration invalidates its fingerprint.")
		for fault in ["signature", "rng", "event", "history"]:
			var corrupt: Dictionary = signed.duplicate(true)
			match fault:
				"signature": corrupt.run.terminal.identity.checkpoint_signature = "f".repeat(64)
				"rng": corrupt.run.route.graph.route_rng_state += 1
				"event": corrupt.run.route.graph.nodes[2].room_reference = "event_lost_satchel"
				"history": corrupt.run.route.revision += 1
			check(not validate(corrupt).ok, "Rejects forged historical %s before any graph hydration or terminal signing." % fault)

func _transactions() -> void:
	var subject = fresh(42)
	var location := directory.path_join("transaction-%d.json" % Time.get_ticks_usec())
	var store := Save.new(location, validate)
	var loaded := store.load()
	var first := store.commit(payload(subject), loaded.revision)
	check(first.ok, "Initial production route is durably saved.")
	if not first.ok: return
	var before := payload(subject)
	var candidate = subject.clone_for_transaction().run
	var prepared: Dictionary = candidate.prepare_route_battle(candidate.request_room_entry("d1b").token)
	check(prepared.ok and candidate.commit_route_battle(prepared).ok, "Detached entry candidate holds real Wickling without publishing it.")
	var retained := payload(candidate)
	for point in ["write", "flush", "close", "backup", "replace"]:
		store.failure_point = point
		check(not store.commit(retained, first.revision).ok and payload(subject) == before and payload(candidate) == retained, "Failed %s retains prior run and identical entry Retry candidate." % point)
		var durable := Save.new(location, validate).load()
		check(durable.ok and durable.payload == before, "Fresh restart after failed %s sees only prior durable route." % point)
	store.failure_point = ""
	var retried := store.commit(retained, first.revision)
	check(retried.ok, "Identical entry candidate Retry succeeds.")
	if retried.ok: subject.publish_transaction(candidate)
	var durable := Save.new(location, validate).load()
	check(durable.ok and durable.payload == retained and payload(subject) == retained, "Only successful save publishes new encounter ownership and replay checkpoint.")
