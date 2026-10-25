extends SceneTree
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const RunState = preload("res://scripts/core/run_state.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
var checks := 0
var failures := 0
var assertions: Array = []
const DESTINATION := "res://output/qa/rc-027/collection"

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": description})
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	var setup: Dictionary = Loader.load_setup().setup
	var observed_temporary := false
	var observed_installed := false
	for seed in range(12):
		var run := RunState.new(setup, seed)
		var ownership := run.snapshot()
		var model: Combat = run.enter_battle().combat
		var initial: Dictionary = model.snapshot()
		var before_rng: Array = [model.rng.state, model.endpoint_rng.state, model.kit_rng.state, model.next_uid]
		var display := CollectionData.describe(ownership, initial.catalog, initial)
		check(display.owned_count == 8 and display.definition_count == 4 and display.groups.all(func(group): return group.count == 2), "Seed %d: owned copies use instance ownership, not three-card hand or catalogue size." % seed)
		check(display.zone_counts.hand == initial.hand.size() and display.zone_counts.draw_pile == initial.draw_pile.size() and display.zone_counts.discard_pile == 0, "Seed %d: detached live hand/draw locations are accurate." % seed)
		check(model.snapshot() == initial and [model.rng.state, model.endpoint_rng.state, model.kit_rng.state, model.next_uid] == before_rng, "Seed %d: collection inspection leaves model and every stream/allocator unchanged." % seed)
		display.groups[0].instances[0].uid = 9999
		display.groups[0].card.name = "Changed presentation"
		check(model.snapshot() == initial and ownership.owned_cards == model.run_handoff().owned_cards, "Seed %d: nested presentation edits cannot alter model or ownership." % seed)
		for card in model.snapshot().hand:
			if card.id == "conjure":
				check(model.play_technique(card.uid), "Seed %d: actual Conjure creates a battle-only temporary." % seed)
				break
		var live: Dictionary = model.snapshot()
		for card in live.hand:
			if live.catalog[card.id].type != "rune" or live.catalog[card.id].get("temporary", false): continue
			for index in live.board.size():
				if live.board[index].is_empty():
					check(model.place_rune(index, card.uid), "Seed %d: actual permanent rune is installed through normal editing." % seed)
					observed_installed = true
					break
			break
		live = model.snapshot()
		display = CollectionData.describe(ownership, live.catalog, live)
		var located := 0
		var installed := 0
		for group in display.groups:
			for instance in group.instances:
				if instance.zone != "": located += 1
				if instance.zone == "installed": installed += 1
		check(display.owned_count == 8 and located == 8 and display.zone_counts.installed == installed, "Seed %d: every original instance occurs once across hand/draw/discard/installed." % seed)
		if not display.temporary.is_empty():
			observed_temporary = true
			check(display.temporary.all(func(item): return item.id == "free_spark" and item.card.temporary) and display.groups.all(func(group): return group.id != "free_spark"), "Seed %d: generated Free Spark is explicitly separate and never inflates owned copies." % seed)
		model.pass_turn()
		check(model.turn == 2, "Seed %d: accepted Pass reaches normal cleanup." % seed)
		live = model.snapshot()
		display = CollectionData.describe(ownership, live.catalog, live)
		check(display.owned_count == 8 and display.temporary.is_empty() and display.zone_counts.installed == 0 and display.zone_counts.discard_pile == live.discard_pile.size(), "Seed %d: collection remains correct after cleanup and ordinary draw." % seed)
		var before: Dictionary = ownership.duplicate(true)
		var no_live := CollectionData.describe(ownership, live.catalog)
		check(not no_live.has_live and no_live.temporary.is_empty() and no_live.groups.all(func(group): return group.instances.all(func(instance): return instance.location == "Run collection")) and ownership == before, "Seed %d: out-of-battle collection never invents live locations or changes run ownership." % seed)
	check(observed_temporary and observed_installed, "Coverage includes actual generated temporary and installed permanent cards.")
	check(not CollectionData.describe({"owned_cards": [], "profile": {}}, setup.catalog).has_profile, "An absent fixture profile does not display invented empty across-run ownership.")
	var profile_source := {"run_id": "profile", "owned_cards": [], "profile": {"unlocked_definition_ids": ["spark", "shield", "focus", "conjure"], "session_only": true}}
	var profile_display := CollectionData.describe(profile_source, setup.catalog)
	check(profile_display.owned_count == 0 and profile_display.groups.is_empty() and profile_display.unlocked_definitions.size() == 4, "Profile definition unlocks are separate from run-owned copies.")
	profile_display.unlocked_definitions[0].name = "Changed"
	check(profile_source.profile.unlocked_definition_ids == ["spark", "shield", "focus", "conjure"] and setup.catalog.spark.name == "Spark", "Profile display remains detached from progression and catalogue.")
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("%d RC-027 collection checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
