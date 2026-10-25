extends RefCounted
## Explicitly excluded RunState boundary fixture, using the ordinary 30 HP,
## eight-card starter. Its high 74 HP threshold isolates lifecycle behavior after
## one legal Cast; the separate playable RC-033 fixture uses the roster's 40 HP.
const Base = preload("res://tests/helpers/encounter_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Rules = preload("res://scripts/core/production_rules.gd")
const Content = preload("res://tests/production_content_tests.gd")

class FixtureRoute extends Base.FixtureRoute:
	func _init(run_id: String, seed: int) -> void:
		super(run_id, seed)
		_graph.route_id = "rc033_lifecycle_fixture-%d" % seed
		_graph.display_name = "RC-033 lifecycle fixture (threshold 74)"
		for node in _graph.nodes:
			if node.depth in [1, 2]:
				node.fixture_loadout = "starter"
				node.title = "RC-033 phase lifecycle fixture"
				node.display_name = node.title
				_nodes[node.id] = node

class FixtureResolver extends Base.FixtureResolver:
	var threshold := 74
	func _init(value: int = 74) -> void:
		threshold = value
	func _load(node: Dictionary, path: String) -> Dictionary:
		if node.get("enemy_id") != "dev_calibration_wisp": return super(node, path)
		var documents: Dictionary = Content.documents()
		documents.encounter = Loader.read_document(path).document
		documents.encounter.board_id = node.board_id
		documents.encounter.loadout_id = "starter"
		for enemy in documents.enemies:
			if enemy.id != "dev_calibration_wisp": continue
			enemy.name = "RC-033 lifecycle target"
			enemy.max_health = 80
			enemy.intents = [8, 12, 16]
			enemy.phase_two = {"health_threshold": threshold, "intents": [12, 16, 20]}
		return Loader.validate_documents(documents, {}, null, Rules.production_options(Rules.load_rules().rules))

static func new_run(seed: int = 42):
	return Run.new(Loader.load_setup().setup, seed, true,
		func(id, route_seed): return FixtureRoute.new(id, route_seed), FixtureResolver.new())

static func context_for(subject) -> Dictionary:
	var context: Dictionary = subject.restore_context_for_tests()
	for node in subject._route._graph.nodes:
		if node.encounter_id.is_empty(): continue
		var resolved: Dictionary = subject._resolver.resolve(node, subject._entry_data())
		if resolved.get("ok", false): context.setups[Run.content_signature(resolved.setup)] = resolved.setup
	return context
