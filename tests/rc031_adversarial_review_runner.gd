extends SceneTree

# Independent hostile-save review; separate from the implementation's tests.
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const ServiceFixture = preload("res://tests/helpers/service_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
var checks := 0
var failures: Array = []
var records: Array = []

func _initialize() -> void:
	var shop = ShopFixture.new_run(42, 300)
	ShopFixture.win_first(shop)
	ShopFixture.enter_shop(shop)
	var shop_identity: Dictionary = shop.shop_snapshot().identity
	var active: Dictionary = shop.export_save()
	for value in [null, [], "bad", 1, {}, false]:
		_reject(shop, active, "relic offering shape %s" % str(value), func(data): data.shop_records[0].relic_offering = value)
		_reject(shop, active, "upgrade slot shape %s" % str(value), func(data): data.shop_records[0].upgrade = value)
	for field in ["version", "eligible_ids", "offered_ids", "rng_before", "rng_after"]:
		for value in [null, [], {}, "bad", false]:
			_reject(shop, active, "relic offering %s=%s" % [field, str(value)], func(data): data.shop_records[0].relic_offering[field] = value)
	_reject(shop, active, "upgrade slot floating price", func(data): data.shop_records[0].upgrade.price = 35.0)
	_reject(shop, active, "upgrade slot integer used flag", func(data): data.shop_records[0].upgrade.used = 0)
	shop.upgrade_shop_rune(shop_identity, 0)
	var upgraded: Dictionary = shop.export_save()
	for field in ["previous_rank", "new_rank"]:
		for value in [null, [], {}, "1", false, 1.0, -1, 2]:
			_reject(shop, upgraded, "shop upgrade receipt %s=%s" % [field, str(value)], func(data): data.shop_records[0].transactions[0][field] = value)
	for field in ["id", "uid", "upgrade_rank"]:
		for value in [null, [], {}, false, 0.0, "0", -1, 2]:
			_reject(shop, upgraded, "shop upgrade card %s=%s" % [field, str(value)], func(data): data.shop_records[0].transactions[0].card[field] = value)
	_reject(shop, upgraded, "shop upgrade snapshot card floating rank", func(data): data.shop_records[0].upgrade.card.upgrade_rank = 0.0)
	shop.buy_shop_relic(shop_identity)
	var acquired: Dictionary = shop.export_save()
	for field in ["entry_hp", "entry_max_hp", "result_hp", "result_max_hp", "relic_id"]:
		for value in [null, [], {}, false, "1", 34.0]:
			_reject(shop, acquired, "shop relic receipt %s=%s" % [field, str(value)], func(data): data.shop_records[0].transactions[1][field] = value)
	for value in [[], null, "relic_heart_stone", {}, ["relic_unknown"], ["relic_heart_stone", "relic_heart_stone"]]:
		_reject(shop, acquired, "relic ownership shape %s" % str(value), func(data): data.relics = value)
	var service = ServiceFixture.new_run(42, "recovery")
	ServiceFixture.win_battle(service)
	ServiceFixture.enter_service(service)
	service.resolve_service(service.service_snapshot().identity, "refine_rune", 0)
	var refined: Dictionary = service.export_save()
	for value in [null, [], "bad", 1, false]:
		_reject(service, refined, "service relic offering shape %s" % str(value), func(data): data.service_records[0].relic_offering = value)
	for value in [null, [], {}, 1, "bad", false]:
		_reject(service, refined, "service upgrade receipt shape %s" % str(value), func(data): data.service_records[0].receipt.upgrade = value)
	for field in ["previous_rank", "new_rank", "card"]:
		for value in [null, [], {}, 1, "bad", false, 1.0]:
			if field == "new_rank" and value is int and value == 1: continue
			_reject(service, refined, "service upgrade receipt %s=%s" % [field, str(value)], func(data): data.service_records[0].receipt.upgrade[field] = value)
	for field in ["id", "uid", "upgrade_rank"]:
		for value in [null, [], {}, false, 0.0, "0", -1, 2]:
			_reject(service, refined, "service upgrade card %s=%s" % [field, str(value)], func(data): data.service_records[0].receipt.upgrade.card[field] = value)
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-031/review")
	FileAccess.open("res://output/qa/rc-031/review/results.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "records": records}, "\t"))
	print("RC-031 adversarial review: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _reject(subject, original: Dictionary, label: String, mutation: Callable) -> void:
	var changed := original.duplicate(true)
	mutation.call(changed)
	var result := Run.restore_save(changed, Loader.load_setup().setup, subject.profile_state().clone_for_transaction(), subject.restore_context_for_tests())
	checks += 1
	var rejected: bool = result.has("ok") and not result.ok
	records.append({"label": label, "rejected": rejected, "error": result.get("error", "missing result")})
	if not rejected:
		failures.append(label)
		push_error("Malformed save accepted: " + label)
