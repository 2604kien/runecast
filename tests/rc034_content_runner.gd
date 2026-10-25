extends SceneTree

const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Resolver = preload("res://scripts/core/encounter_resolver.gd")
const ProductionContent = preload("res://tests/production_content_tests.gd")
const SPECS := [
	["wickling", "normal", 26, [6, 6, 10], ["board_gallery", "board_ossuary"]],
	["stone_sentinel", "normal", 42, [5, 13, 5], ["board_gallery", "board_ossuary"]],
	["chain_warden", "elite", 58, [8, 8, 18], ["board_ossuary"]],
	["bell_keeper", "guardian", 80, [8, 12, 16], ["board_belfry"]]
]
var checks := 0
var failures: Array = []

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	var original: Dictionary = Loader.load_setup().setup
	var profile = Profile.new(original.catalog)
	var run = Run.new(original, 42, false, Callable(), null, Profile.production_rules(), profile)
	var entry: Dictionary = run._entry_data()
	var resolver = Resolver.new()
	for spec in SPECS:
		var path := "res://data/production_%s_encounter.json" % spec[0]
		var loaded: Dictionary = Loader.load_setup(path)
		check(loaded.ok, "Production loader validates " + spec[0])
		if not loaded.ok: continue
		var setup: Dictionary = loaded.setup
		check(setup.encounter.id == spec[0] and setup.encounter.enemy_id == spec[0] and setup.encounter.max_health == spec[2] and setup.encounter.intents == spec[3], "Authored stable identity and provisional values: " + spec[0])
		check(setup.owned_cards == original.owned_cards and setup.opening_draw == 3 and setup.encounter.player_health == 30 and setup.encounter.player_max_health == 30 and setup.encounter.energy_per_turn == 3 and setup.encounter.draw_per_turn == 3 and setup.production == original.production, "Shared ordinary resources and production rules remain unchanged: " + spec[0])
		check(not setup.has("experiment") and not setup.has("next_encounter"), "Production selection contains one real enemy: " + spec[0])
		if spec[0] == "bell_keeper":
			check(setup.encounter.phase_two == {"health_threshold": 40, "intents": [12, 16, 20]}, "Bell Keeper has only the accepted 40-HP phase threshold")
		else:
			check(not setup.encounter.has("phase_two"), "Normal and elite encounters have no extra phases: " + spec[0])
		for board in spec[4]:
			var node := {"encounter_id": spec[0], "enemy_id": spec[0], "encounter_role": spec[1], "board_id": board}
			var resolved: Dictionary = resolver.resolve(node, entry)
			check(resolved.ok and resolved.setup.encounter.board_id == board and resolved.setup.encounter.encounter_role == spec[1], "Trusted resolver accepts exact production binding: %s / %s" % [spec[0], board])
			if not resolved.ok: continue
			var battle = Combat.create_for_run(resolved.setup, resolved.entry).combat
			check(battle.snapshot().enemy_hp == spec[2] and battle.intent() == spec[3][0] and battle.snapshot().enemy_action.phase == 1 and battle.snapshot().enemy_action.sequence_index == 0, "Every board begins at the first announced attack: %s / %s" % [spec[0], board])
			var first: Dictionary = battle.snapshot()
			for attack in spec[3]:
				check(battle.intent() == attack, "Legal Pass observes authored attack sequence: %s / %s" % [spec[0], board])
				battle.pass_turn()
				if battle.state != "playing": break
			check(Combat.create_for_run(resolved.setup, resolved.entry).combat.snapshot() == first, "Entry reconstruction reproduces selected board, resources and announcement: %s / %s" % [spec[0], board])
			for field in ["enemy_id", "encounter_role", "board_id", "encounter_id"]:
				var wrong := node.duplicate(true)
				wrong[field] = "res://tests/fixtures/rc033/encounter.json"
				check(not resolver.resolve(wrong, entry).ok and run._entry_data() == entry, "Mismatched or path-shaped %s rejects without consuming resources: %s" % [field, spec[0]])
		var selected: Dictionary = run._select_reward_rule("encounter_rewards", spec[0], spec[1])
		check(selected.ok and selected.policy_id == Profile.REWARD_POLICY_ID and selected.rule.gold == 0 and selected.rule.offer_count == 3 and selected.rule.allow_skip and selected.rule.eligible_ids == ["conjure", "focus", "shield", "spark"], "Exact role gets initially unlocked duplicate-ownable run choices and explicit zero Gold: " + spec[0])
		check(selected.rule.get("permanent_unlock", false) == (spec[1] == "guardian"), "Only guardian addition receives the permanent milestone: " + spec[0])
		for role in ["normal", "elite", "boss", "guardian", "development"]:
			if role == spec[1]: continue
			check(not run._select_reward_rule("encounter_rewards", spec[0], role).ok, "Wrong reward role rejects: %s / %s" % [spec[0], role])
		check(not run._select_reward_rule("elite_relic", spec[0], spec[1]).ok, "No unapproved relic reward family: " + spec[0])
	_historical(original, run)
	_small_pools(original)
	var result := {"checks": checks, "failures": failures, "failure_count": failures.size(), "engine": Engine.get_version_info().string,
		"scope": "Production content, exact role/board/reward policy, ordinary Pass sequencing and entry reconstruction; no victory or full-run balance claim."}
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-034/content")
	var file := FileAccess.open("res://output/qa/rc-034/content/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("RC-034 content: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _historical(original: Dictionary, run: RefCounted) -> void:
	var documents: Dictionary = ProductionContent.documents()
	var current := Loader.validate_documents(documents, {}, null, original.production)
	documents.enemies = documents.enemies.filter(func(enemy): return enemy.id in ["shadeling", "dev_calibration_wisp"])
	var previous := Loader.validate_documents(documents, {}, null, original.production)
	check(current.ok and previous.ok and current.setup == previous.setup, "Adding unrelated enemy definitions leaves the exact normalized Shadeling configuration/signature unchanged")
	check(original.encounter.max_health == 32 and original.encounter.intents == [8, 12, 6] and not original.encounter.has("phase_two"), "Preserved Shadeling baseline and no invented dodge/phase metadata")
	var rule: Dictionary = Profile.production_rules(true).rules[0]
	check(rule == {"encounter_role": "boss", "encounter_id": "training_shadeling", "choice_id": "encounter_rewards", "eligible_ids": Profile.INITIAL_IDS.duplicate(), "offer_count": 3, "gold": 0, "allow_skip": true, "permanent_unlock": true}, "Historical Shadeling reward policy shape and identity remain unchanged")
	check(Profile.production_rules(true).policy_id == "rc027_owner_2026_10_22" and Profile.production_rules(true).rules.size() == 5, "Historical policy preserves old receipt semantics and exactly four added role-bound rules")
	check(Profile.production_rules().policy_id == "rc035_rewards_v2" and Profile.production_rules().rules[0].eligible_ids == Profile.REGISTERED_IDS, "Expanded policy explicitly registers twelve definitions while the profile filters current offers")
	check(not run._select_reward_rule("encounter_rewards", "dev_calibration_wisp", "development").ok and not run._select_reward_rule("encounter_rewards", "dev_rc033_phase_probe", "guardian").ok, "No calibration or observation enemy acquires a production reward policy")
	var fixture: Dictionary = Loader.load_setup("res://data/production_transition_encounter.json")
	check(fixture.ok and fixture.setup.next_encounter.encounter.enemy_id == "dev_calibration_wisp" and fixture.setup.next_encounter.encounter.max_health == 45 and fixture.setup.next_encounter.encounter.intents == [3, 7, 5], "Historical explicit development successor remains reproducible")

func _small_pools(original: Dictionary) -> void:
	for unlocked in [["spark"], []]:
		var profile = Profile.new(original.catalog, unlocked)
		var run = Run.new(original, 42, false, Callable(), null, Profile.production_rules(), profile)
		for spec in SPECS:
			var selected: Dictionary = run._select_reward_rule("encounter_rewards", spec[0], spec[1])
			check(selected.ok and selected.rule.eligible_ids == unlocked and selected.rule.allow_skip, "Small/empty supported definition pools stay bounded and skippable: %s / %s" % [spec[0], str(unlocked)])
