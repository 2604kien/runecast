extends SceneTree
## RC-032: genuine predecessor bytes; every stage runs in a fresh OS process.
const Run = preload("res://scripts/core/run_state.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Save = preload("res://scripts/core/local_save.gd")
const ServiceFixture = preload("res://tests/helpers/service_route_fixture.gd")
const ShopFixture = preload("res://tests/helpers/shop_route_fixture.gd")
const RewardFixture = preload("res://tests/helpers/reward_route_fixture.gd")
const RewardTests = preload("res://tests/reward_state_tests.gd")
const ItemFixture = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
var directory := ""
var fixture := ""
var stage := ""
var setup: Dictionary
var context: Dictionary = {}
var evidence: Dictionary = {}
var checks := 0
var failures := 0
var assertions: Array = []

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): directory = arg.trim_prefix("--save-root=")
		if arg.begins_with("--fixture="): fixture = arg.trim_prefix("--fixture=")
		if arg.begins_with("--stage="): stage = arg.trim_prefix("--stage=")
	if directory.is_empty() or fixture.is_empty() or stage.is_empty():
		quit(2)
		return
	setup = Loader.load_setup().setup
	context = _context()
	DirAccess.make_dir_recursive_absolute(directory)
	var evidence_path := directory.path_join("expected.bin")
	if FileAccess.file_exists(evidence_path): evidence = bytes_to_var(FileAccess.get_file_as_bytes(evidence_path))
	var path := directory.path_join("active.json")
	if stage == "import":
		var family := "rc028" if fixture.ends_with("v1") else "rc029" if fixture.ends_with("v2") else "rc030" if fixture.ends_with("v3") else "rc031"
		var source := "res://tests/fixtures/%s/%s.json" % [family, fixture]
		check(DirAccess.copy_absolute(source, path) == OK, "Copies genuine predecessor envelope without alteration.")
		evidence.original = FileAccess.get_file_as_bytes(source)
	var store := Save.new(path, validate)
	var loaded: Dictionary = store.load()
	if stage == "recover":
		check(not loaded.ok and loaded.recovery_available, "Damaged current retains a validated genuine predecessor backup.")
		var recovered: Dictionary = store.recover_previous()
		check(recovered.ok, "Explicit previous-copy recovery succeeds: " + str(recovered.get("error", "")))
		check(FileAccess.get_file_as_bytes(path) == evidence.original, "Recovery preserves exact original predecessor bytes.")
		if recovered.ok:
			check(FileAccess.get_file_as_string(recovered.preserved_path) == "RC-032 isolated damage specimen", "Recovery preserves unreadable current bytes separately.")
	else:
		check(loaded.ok, "Fresh process validates checkpoint: " + str(loaded.get("error", "")))
		if loaded.ok:
			var restored := validate(loaded.payload)
			check(restored.ok, "Restores detached owners: " + str(restored.get("error", "")))
			if restored.ok: _exercise(store, loaded, restored.run)
	FileAccess.open(evidence_path, FileAccess.WRITE).store_buffer(var_to_bytes(evidence))
	FileAccess.open(directory.path_join(stage + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"fixture": fixture, "stage": stage, "checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-032 migration %s/%s: %d checks, %d failures" % [fixture, stage, checks, failures])
	quit(0 if failures == 0 else 1)

func _context() -> Dictionary:
	if fixture.begins_with("production-"): return {}
	if fixture.ends_with("v4"):
		if fixture in ["ranked-history-v4", "active-reliquary-v4", "ranked-relic-shop-v4"]: return ItemFixture.context_for(ItemFixture.new_run(15))
		return ShopFixture.context_for(RewardFixture.new_run(42))
	if fixture == "reward-v1": return ShopFixture.context_for(RewardFixture.new_run())
	if fixture == "pending-reward-v2": return RewardTests.new()._boss_run(Profile.new(setup.catalog, ["spark"]), true).restore_context_for_tests()
	if fixture.ends_with("v1") or fixture.ends_with("v2") or fixture == "pending-reward-v3": return ShopFixture.context_for(ShopFixture.new_run())
	var variant := "recovery"
	for label in ["desk", "reliquary", "satchel", "tithe"]:
		if label in fixture: variant = label
	return ServiceFixture.context_for(ServiceFixture.new_run(42, variant))

func validate(payload: Dictionary) -> Dictionary:
	var profile := Profile.restore_save(payload.get("profile", {}), setup.catalog, not context.is_empty())
	return profile if not profile.ok else Run.restore_save(payload.get("run", {}), setup, profile.profile, context)

func _without_new_zero_fields(value: Variant) -> Variant:
	if value is Dictionary:
		var clean := {}
		for key in value:
			if key == "upgrade_rank" and value[key] == 0: continue
			if key == "relics" and value[key] == []: continue
			clean[key] = _without_new_zero_fields(value[key])
		return clean
	if value is Array:
		var clean: Array = []
		for item in value: clean.append(_without_new_zero_fields(item))
		return clean
	return value

func _exercise(store, loaded: Dictionary, subject) -> void:
	var current: Dictionary = subject.export_save()
	var payload := {"profile": subject.profile_state().export_save(), "run": current}
	if stage == "import":
		check(loaded.payload.run.version in [1, 2, 3, 4], "Fixture is an actual supported predecessor.")
		evidence.legacy = loaded.payload
		evidence.promoted = payload
		for key in loaded.payload.run:
			if key in ["version", "shop_policy_id", "service_policy_id"]: continue
			var expected: Variant = preload("res://tests/helpers/legacy_route_shape.gd").expected_hydration(loaded.payload.run[key]) if key == "route" and fixture.begins_with("production-") else loaded.payload.run[key]
			check(_without_new_zero_fields(current[key]) == _without_new_zero_fields(expected), "Migration preserves predecessor field " + key + ", allowing only registered planned-route ID/availability hydration.")
		check(current.version == Run.SAVE_VERSION and current.version > 4, "Detached candidate uses the new current model version.")
		check(payload.profile == loaded.payload.profile, "Migration leaves permanent definition unlocks unchanged.")
		if loaded.payload.run.version < 4:
			check(current.relics.is_empty(), "Migration never manufactures relic acquisition.")
			for card in current.owned_cards: check(card.get("upgrade_rank", -1) == 0, "Legacy UID %d explicitly becomes unupgraded." % card.uid)
		else:
			check(current.relics == loaded.payload.run.relics and current.owned_cards == loaded.payload.run.owned_cards, "Genuine v4 retains exact ranked physical copies and unique relics.")
		if loaded.payload.run.version >= 3:
			for key in ["service_records", "health_boundary", "battle_health_records"]:
				check(current[key] == loaded.payload.run[key], "Real chronological " + key + " survives exactly, without a replacement health anchor.")
		if current.status == "replay_pending":
			var entered: Dictionary = subject.continue_battle()
			check(entered.ok, "Real predecessor interrupted battle can replay.")
			if entered.ok: evidence.opening = entered.combat.snapshot()
	elif stage.begins_with("fail-"):
		store.failure_point = stage.trim_prefix("fail-")
		var failed: Dictionary = store.commit(payload, loaded.revision)
		check(not failed.ok, "Injected migration write failure rejects publication.")
		check(FileAccess.get_file_as_bytes(store.path) == evidence.original, "Failed migration retains exact predecessor bytes.")
		check(payload == evidence.promoted, "Retry candidate has identical ranks, ownership, policies, health and RNG.")
	elif stage == "migrate":
		var saved: Dictionary = store.commit(payload, loaded.revision)
		check(saved.ok, "Migration uses ordinary validated durable commit: " + str(saved.get("error", "")))
		check(FileAccess.get_file_as_bytes(store.path + ".previous") == evidence.original, "Backup validator accepts and preserves original predecessor bytes.")
	elif stage in ["restart", "recovered"]:
		check(payload == evidence.promoted, "Fresh process reproduces exact promoted candidate.")
		check(loaded.payload.run.version == (Run.SAVE_VERSION if stage == "restart" else evidence.legacy.run.version), "Current bytes retain expected promoted/recovered model version.")
		if evidence.has("opening"):
			var entered: Dictionary = subject.continue_battle()
			check(entered.ok and entered.combat.snapshot() == evidence.opening, "Entry replay exactly reproduces cards, endpoints, kits, health and RNG.")
		var service: Dictionary = subject.service_snapshot()
		if not service.is_empty():
			check(service.status == "active", "Retained unresolved service remains active.")
			if evidence.legacy.run.version < 4:
				for item in service.get("choices", []):
					if item.choice_id in ["refine_rune", "open_reliquary"]: check(not item.eligible, "Old service retains its gated item policy without fresh offerings.")
		if stage == "recovered" and not service.is_empty():
			var clone: Dictionary = subject.clone_for_transaction()
			var left: Dictionary = clone.run.resolve_service(service.identity, "leave")
			check(left.ok, "Recovered historical service still completes using its recorded policy.")
			if left.ok:
				var saved: Dictionary = store.commit({"profile": clone.profile.export_save(), "run": clone.run.export_save()}, loaded.revision)
				check(saved.ok, "Post-migration historical service transaction validates and saves.")
	elif stage == "damage":
		FileAccess.open(store.path, FileAccess.WRITE).store_string("RC-032 isolated damage specimen")
		check(FileAccess.get_file_as_bytes(store.path + ".previous") == evidence.original, "Damage exercise leaves genuine predecessor backup intact.")
