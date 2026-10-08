extends RefCounted

const Experiments = preload("res://scripts/core/experiments.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Combat = preload("res://scripts/core/combat.gd")

func run(check: Callable) -> void:
	var scenarios := Experiments.list_scenarios()
	check.call(scenarios.size() == 9, "Six experiment families expose nine bounded comparisons.")
	var seen := {}
	var count := 0
	for scenario in scenarios:
		check.call(not seen.has(scenario.id) and scenario.variants == Loader.EXPERIMENT_VARIANTS[scenario.id], "Scenario %s has a stable unique ID and supported variant list." % scenario.id)
		seen[scenario.id] = true
		for variant in scenario.variants:
			count += 1
			var loaded := Experiments.load_setup(scenario.id, variant)
			check.call(loaded.ok and loaded.errors.is_empty(), "%s/%s validates without partial configuration." % [scenario.id, variant])
			if not loaded.ok:
				continue
			var game := Combat.new(loaded.setup)
			check.call(game.forecast().valid and game.forecast().cost <= game.energy, "%s/%s opens with a valid affordable circuit." % [scenario.id, variant])
			for action in Experiments.known_solution_actions(scenario.id, variant):
				check.call(game.execute(action.command, action.arguments).accepted, "%s/%s known solution command %s is accepted." % [scenario.id, variant, action.command])
			var spell := game.forecast()
			check.call(spell.valid and spell.cost <= game.energy, "%s/%s known solution remains valid and affordable." % [scenario.id, variant])
			if scenario.id == "split_cost" or (scenario.id == "split_inventory" and variant == "treatment"):
				var active_splits := 0
				var active_joins := 0
				for cell in spell.active:
					active_splits += 1 if game.board[cell].get("kind") == "split" else 0
					active_joins += 1 if game.board[cell].get("kind") == "join" else 0
				check.call(active_splits == 2 and active_joins == 2 and spell.damage == 18, "%s/%s witness powers both extra pieces and three copies of upstream Spark." % [scenario.id, variant])
	check.call(count == 19, "The bounded matrix contains exactly nineteen variants, not a combinatorial suite.")
	scenarios[0].variants.clear()
	check.call(Experiments.list_scenarios()[0].variants == ["control", "treatment"], "Scenario metadata is detached from catalog constants.")
	var lifetime_control: Dictionary = Experiments.load_setup("effects", "control").setup
	var lifetime_treatment: Dictionary = Experiments.load_setup("effects", "treatment").setup
	check.call(_matched(lifetime_control, lifetime_treatment), "Effect lifetime pair holds board, ownership, hand, enemy, energy and seed constant.")
	var stock_control: Dictionary = Experiments.load_setup("split_inventory", "control").setup
	var stock_treatment: Dictionary = Experiments.load_setup("split_inventory", "treatment").setup
	check.call(_matched(stock_control, stock_treatment, ["inventory"]) and stock_control.inventory == {"split": 1, "join": 1} and stock_treatment.inventory == {"split": 2, "join": 2}, "Inventory comparison changes allowance without preinstalling a different layout or changing cost.")
	var cost_control: Dictionary = Experiments.load_setup("split_cost", "control").setup
	var cost_treatment: Dictionary = Experiments.load_setup("split_cost", "treatment").setup
	check.call(_matched(cost_control, cost_treatment) and cost_control.experiment.split_cost == 1 and cost_treatment.experiment.split_cost == 2, "Cost comparison holds the two-pair layout and allowance fixed.")
	var expiry_control: Dictionary = Experiments.load_setup("expiry", "control").setup
	check.call(_matched(expiry_control, Experiments.load_setup("expiry", "retained").setup) and _matched(expiry_control, Experiments.load_setup("expiry", "empty").setup), "All three expiry variants hold the alternate-port dependency and initial cards fixed.")
	check.call(expiry_control.board[3].port_shape == "corner" and expiry_control.board[8].port_shape == "corner" and expiry_control.board[8].rotation == 2 and expiry_control.catalog.free_spark.port_shape == "corner", "Alternate ports normalize from rune definitions to powered and disconnected temporary pieces.")
	var detached := Experiments.load_setup("expiry", "retained")
	detached.setup.board[3].port_shape = "straight"
	detached.setup.experiment.expiry = "empty"
	detached.setup.catalog.free_spark.port_shape = "straight"
	check.call(Experiments.load_setup("expiry", "retained").setup.board[3].port_shape == "corner", "Returned setup edits cannot mutate future experiment loads.")
	var alternate_seed := Experiments.load_setup("effects", "control", 731)
	check.call(alternate_seed.ok and alternate_seed.setup.encounter.seed == 731 and alternate_seed.setup.experiment.seed == 731, "Requested seeds agree between encounter and experiment identity.")
	var bad_selections := [["missing", "control", 42], ["effects", "missing", 42], ["expiry", "treatment", 42], [true, "control", 42], ["effects", {}, 42], ["effects", "control", -1], ["effects", "control", 2147483648], ["effects", "control", 0.5], ["effects", "control", "42"], ["effects", "control", true]]
	for selection in bad_selections:
		var bad := Experiments.load_setup(selection[0], selection[1], selection[2])
		check.call(not bad.ok and bad.setup.is_empty() and not bad.errors.is_empty(), "Unknown or malformed experiment selection is rejected: %s." % str(selection))
	for malformed in [null, [], true, {}, {"scenario_id": "effects", "variant_id": "control", "seed": 42}]:
		var bad := Loader.validate_experiment(malformed)
		check.call(not bad.ok and bad.setup.is_empty(), "An incomplete or malformed explicit experiment context fails closed.")
	var modifications := [
		["unknown option", func(e): e.unknown_rule = true],
		["wrong version", func(e): e.version = "rc005_v2"],
		["wrong version type", func(e): e.version = 1],
		["arbitrary Split cost", func(e): e.split_cost = 3],
		["boolean Split cost", func(e): e.split_cost = true],
		["wrong effect mode", func(e): e.effects = "sometimes"],
		["wrong damage type", func(e): e.damage_mode = {}],
		["wrong expiry mode", func(e): e.expiry = "retained"],
		["unmatched transfer", func(e): e.transfer = "retain"],
		["missing option", func(e): e.erase("effects")]
	]
	for entry in modifications:
		var raw := Experiments.documents("effects", "control")
		entry[1].call(raw.experiment)
		var invalid := Loader.validate_documents(raw.documents, {}, raw.experiment)
		check.call(not invalid.ok and invalid.setup.is_empty(), "Experimental validation rejects %s rather than mixing options." % entry[0])
	for scenario in ["endpoints", "blocked", "ports", "expiry"]:
		var variant := "control" if scenario == "expiry" else "treatment"
		var raw := Experiments.documents(scenario, variant)
		check.call(not Loader.validate_documents(raw.documents).ok, "%s geometry extension cannot enter normal content validation." % scenario)
	var raw := Experiments.documents("ports", "treatment")
	var cases := [
		["unknown port shape", func(d): d.runes[0].port_shape = "tee"],
		["wrong port shape type", func(d): d.runes[0].port_shape = ["corner"]],
		["technique ports", func(d): d.runes[2].port_shape = "corner"],
		["per-placement port override", func(d): d.boards[0].placements[1].port_shape = "corner"],
		["mismatched seed", func(d): d.encounter.seed = 43],
		["embedded experiment", func(d): d.encounter.experiment = raw.experiment],
		["document experiment override", func(d): d.experiment = raw.experiment]
	]
	for entry in cases:
		var data: Dictionary = raw.documents.duplicate(true)
		entry[1].call(data)
		check.call(not Loader.validate_documents(data, {}, raw.experiment).ok, "Experimental definitions reject %s." % entry[0])
	var endpoints := Experiments.documents("endpoints", "treatment")
	endpoints.documents.boards[0].placements.append({"cell": 4, "kind": "begin"})
	check.call(not Loader.validate_documents(endpoints.documents, {}, endpoints.experiment).ok, "Alternate geometry still requires exactly one protected Begin and End.")
	endpoints = Experiments.documents("endpoints", "treatment")
	endpoints.documents.boards[0].placements[0].rotation = 0
	check.call(not Loader.validate_documents(endpoints.documents, {}, endpoints.experiment).ok, "An alternate endpoint cannot point out of bounds.")
	var blocked := Experiments.documents("blocked", "treatment")
	blocked.documents.boards[0].placements.back().rotation = 1
	check.call(not Loader.validate_documents(blocked.documents, {}, blocked.experiment).ok, "Blocked cells reject meaningless rotation data.")
	var wrong_context := Experiments.documents("blocked", "treatment")
	check.call(not Loader.validate_documents(wrong_context.documents, {}, Loader.experiment_options("effects", "control").setup).ok, "A valid unrelated experiment context does not enable blocked cells.")

func _matched(first: Dictionary, second: Dictionary, except: Array = []) -> bool:
	for field in ["board", "catalog", "owned_cards", "opening_hand", "opening_draw", "inventory"]:
		if not field in except and first[field] != second[field]:
			return false
	for field in ["seed", "name", "max_health", "intents", "player_health", "player_max_health", "energy_per_turn", "draw_per_turn"]:
		if first.encounter[field] != second.encounter[field]:
			return false
	return true
