extends RefCounted
## Excluded RC-035 catalogue demonstration. Explicit initial full-unlock profile;
## ordinary eight-card/30-HP starter. A real Wisp victory earns the clearly
## registered 500 fixture Gold. Nothing injects live resources or owns a new
## definition until a supported Store transaction buys its rank-zero copy.
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Base = preload("res://tests/helpers/shop_route_fixture.gd")
const Rooms = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const IDS := ["spark", "shield", "focus", "conjure", "ember", "flare", "barrier", "bulwark", "deep_focus", "twin_conjure", "cinder_guard", "ward_spark"]

static func new_run(seed: int = 42):
	var setup: Dictionary = Loader.load_setup().setup
	return Run.new(setup, seed, true, func(id, route_seed): return Rooms.FixtureRoute.new(id, route_seed, "history"),
		Base.FixtureResolver.new(), Base.reward_rules(500), Profile.new(setup.catalog, IDS))

static func purchased(id: String, seed: int = 42) -> Dictionary:
	var subject = new_run(seed)
	var won: Dictionary = Base.win_first(subject)
	if not won.ok: return won
	var result: Dictionary = subject.purchase_store_rune(subject.store_snapshot().identity, id)
	if not result.ok: return result
	return {"ok": true, "run": subject, "card": result.granted_card}

static func upgraded(id: String, seed: int = 42) -> Dictionary:
	var acquired := purchased(id, seed)
	if not acquired.ok: return acquired
	var subject = acquired.run
	var entered: Dictionary = Rooms.enter_service(subject)
	if not entered.ok: return entered
	var refined: Dictionary = subject.resolve_service(subject.service_snapshot().identity, "refine_rune", acquired.card.uid)
	if not refined.ok: return refined
	return {"ok": true, "run": subject, "card": subject._owned_card(acquired.card.uid).duplicate(true)}
