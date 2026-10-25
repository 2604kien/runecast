extends SceneTree
## Excluded RC-035 desktop evidence. The Combat gallery declares its enlarged
## initial collection/draw/health before construction. Store resources are earned
## by a genuine Wisp fixture victory. The milestone journey uses ordinary RC-034
## production resources and commands, with no fabricated victory or award.
const Loader = preload("res://scripts/core/content_loader.gd")
const Combat = preload("res://scripts/core/combat.gd")
const Effects = preload("res://scripts/core/instance_effects.gd")
const Inspect = preload("res://scripts/ui/inspection_data.gd")
const Collection = preload("res://scripts/ui/collection_data.gd")
const Shell = preload("res://scripts/ui/application_shell.gd")
const Fixture = preload("res://tests/helpers/rc035_catalogue_fixture.gd")
const Shop = preload("res://tests/helpers/shop_route_fixture.gd")
const Rooms = preload("res://tests/helpers/upgrade_relic_route_fixture.gd")
const Journey = preload("res://tests/helpers/rc034_journey.gd")
const Player = preload("res://tests/helpers/rc034_player.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Ui = preload("res://scenes/ui/theme/components.gd")
const OUT := "res://output/qa/rc-035/ui"
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []
var capturing := false

func _initialize() -> void:
	capturing = "--capture-rc035" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(value: bool, description: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": description})
	if not value:
		failures += 1
		push_error(description)

func settle() -> void:
	for frame in 7: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(name: String, panel: Control = null, action: Control = null) -> void:
	await settle()
	var bounds := root.get_final_transform() * root.get_visible_rect()
	if panel != null:
		check(bounds.encloses(root.get_final_transform() * panel.get_global_rect()), name + ": panel fits actual viewport.")
	if action != null:
		check(bounds.encloses(root.get_final_transform() * action.get_global_rect()), name + ": fixed action is reachable.")
	if capturing: check(root.get_texture().get_image().save_png(OUT.path_join(name + ".png")) == OK, name + ": actual renderer screenshot saved.")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		check(root.size == dimensions, "Actual configured %dx%d window." % [dimensions.x, dimensions.y])
		await gallery(dimensions)
		await store_and_upgrade(dimensions)
		await production_unlock(dimensions)
	var suffix := "capture" if capturing else "headless"
	FileAccess.open(OUT.path_join("results-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions,
		"scope": "Explicit prelaunch gallery fixture; genuine fixture-funded Store/refinement; ordinary-resource real Shadeling milestone. Desktop sizes only, no device acceptance."}, "  ") + "\n")
	FileAccess.open(OUT.path_join("commands-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  ") + "\n")
	print("RC-035 UI: %d checks, %d failures" % [checks, failures])
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)

func gallery(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var setup: Dictionary = Loader.load_setup("res://data/production_stone_sentinel_encounter.json").setup
	setup.owned_cards = Fixture.IDS.duplicate()
	setup.opening_draw = Fixture.IDS.size()
	setup.encounter.player_health = 400
	setup.encounter.player_max_health = 400
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = setup
	scene.battle_model = Combat.new(setup, 42)
	scene.settings_path = OUT.path_join("gallery-" + tag + ".cfg")
	root.add_child(scene)
	scene.animation_presenter.automatic_timing = false
	await settle()
	check(scene.game.hand.size() == 12 and scene.game.draw_pile.is_empty(), tag + ": explicit prelaunch gallery draws all twelve owned definitions.")
	for id in Fixture.IDS:
		var matching: Array = scene.game.hand.filter(func(card): return card.id == id)
		check(matching.size() == 1, tag + ": actual hand has " + id)
		if matching.is_empty(): continue
		var card: Dictionary = matching[0]
		var button: Button = scene.hand_box.get_children().filter(func(child): return child.get_meta("uid", -1) == card.uid)[0]
		var description: Label = button.find_child("Description", true, false)
		var lane: ScrollContainer = button.find_child("DescriptionScroll", true, false)
		var title: Label = button.find_child("Title", true, false)
		var font: Font = title.get_theme_font("font")
		check(font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x <= title.size.x, tag + ": full hand name fits: " + id)
		check(description.get_combined_minimum_size().y <= lane.size.y, tag + ": all essential effect copy visible without nested scroll: " + id)
		check(button.get_node_or_null("Category") == null, tag + ": no category row: " + id)
		if id in ["cinder_guard", "ward_spark", "deep_focus", "twin_conjure"]:
			scene.hand_scroll.ensure_control_visible(button)
			await capture("hand-" + id + "-" + tag)
			var before: Dictionary = scene.controller.snapshot()
			scene._inspect_hand(card.uid)
			await capture("inspect-" + id + "-" + tag, scene.inspector_panel, scene.inspector_close)
			check(scene.controller.snapshot() == before, tag + ": Info is read-only for " + id)
			if id == "twin_conjure": check(scene.inspector_text.text.contains("2 temporary Free Sparks") and scene.inspector_text.text.contains("disappear after Cast or Pass"), tag + ": full Twin Conjure generation and expiry inspection.")
			scene._close_inspector(false)
	var twin: Dictionary = scene.game.hand.filter(func(card): return card.id == "twin_conjure")[0]
	check(scene.controller.command("technique", {"uid": twin.uid}), tag + ": actual guarded Twin Conjure activates.")
	scene.animation_presenter.finish()
	await settle()
	var generated: Array = scene.game.hand.filter(func(card): return card.id == "free_spark")
	check(generated.size() == 2 and generated[0].uid != generated[1].uid and scene.game.energy == 2, tag + ": two distinct temporary UIDs and one immediate energy payment.")
	scene.hand_scroll.scroll_horizontal = 10000
	await capture("larger-hand-generated-" + tag)
	scene._inspect_pile("discard_pile")
	await capture("discard-inspection-" + tag, scene.inspector_panel, scene.inspector_close)
	check(scene.inspector_text.text.contains("Twin Conjure") and scene.inspector_text.text.contains("2 temporary Free Spark"), tag + ": actual discarded technique retains its complete identity and count.")
	scene._close_inspector(false)
	var deep: Dictionary = scene.game.hand.filter(func(card): return card.id == "deep_focus")[0]
	check(scene.controller.command("technique", {"uid": deep.uid}), tag + ": actual guarded Deep Focus activates.")
	scene.animation_presenter.finish()
	await settle()
	check(scene.game.energy == 0 and scene.battle_model.last_result().events.any(func(event): return event.type == "reshuffled"), tag + ": Deep Focus handles short pile by reshuffling played techniques.")
	check(scene.controller.command("pass"), tag + ": ordinary Pass cleans up the large hand.")
	scene.animation_presenter.finish()
	await settle()
	check(not (scene.game.hand + scene.game.draw_pile + scene.game.discard_pile).any(func(card): return card.id == "free_spark"), tag + ": generated cards vanish instead of becoming owned pile entries.")
	scene._inspect_pile("draw_pile")
	await capture("draw-inspection-" + tag, scene.inspector_panel, scene.inspector_close)
	check(not scene.game.draw_pile.is_empty() and scene.inspector_text.text.contains("damage"), tag + ": actual recycled draw pile displays effects.")
	scene._close_inspector(false)
	scene.queue_free()
	await settle()

func shell_for(run, path: String, context: Dictionary) -> Control:
	var app := Shell.new()
	app.save_path = path
	app.settings_path = path + ".cfg"
	app.persistence_context = context
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.run_state = run
	app.progression = run.profile_state()
	check(app._persist_candidate(run).get("ok", false), "Authentic pre-UI boundary saves through normal validator.")
	return app

func store_and_upgrade(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var run = Fixture.new_run()
	check(Shop.win_first(run).ok, tag + ": genuine Wisp fixture battle earns explicitly configured 500 Gold.")
	var context: Dictionary = Shop.context_for(run)
	var app := shell_for(run, OUT.path_join("store-" + tag + "-" + str(Time.get_ticks_usec()) + ".json"), context)
	await settle()
	app.continue_run()
	await settle()
	app.map_screen.menu_requested.emit()
	app.open_store()
	await settle()
	check(app.store_screen.purchase_buttons.size() == 18, tag + ": expanded Store shows twelve eligible runes and six relics.")
	await capture("store-expanded-top-" + tag, app.store_screen.panel, app.store_screen.close_button)
	app.store_screen.scroll.ensure_control_visible(app.store_screen.purchase_buttons["rune:cinder_guard"])
	await capture("store-expanded-mixed-" + tag, app.store_screen.panel, app.store_screen.close_button)
	app.store_screen.scroll.ensure_control_visible(app.store_screen.purchase_buttons["rune:twin_conjure"])
	await capture("store-expanded-techniques-" + tag, app.store_screen.panel, app.store_screen.close_button)
	app.store_screen.purchase_buttons["rune:twin_conjure"].pressed.emit()
	await capture("store-twin-confirmation-" + tag, app._confirmation_panel, app.confirmation_confirm)
	check(app.confirmation_text.text.contains("2 temporary Free Sparks") and app.confirmation_text.text.contains("disappear after Cast or Pass"), tag + ": Store confirmation explains actual count, temporary behavior and price.")
	app.cancel_confirmation()
	app.store_screen.scroll.scroll_vertical = 10000
	await capture("store-relics-" + tag, app.store_screen.panel, app.store_screen.close_button)
	app.store_screen.purchase_buttons["rune:cinder_guard"].pressed.emit()
	await capture("store-mixed-confirmation-" + tag, app._confirmation_panel, app.confirmation_confirm)
	app.confirm_store_purchase()
	await settle()
	check(run.snapshot().owned_cards.any(func(card): return card.id == "cinder_guard" and card.upgrade_rank == 0), tag + ": Store commits a fresh mixed rune copy through the shell.")
	app.close_store()
	app._close_route_menu()
	await settle()
	var node_id: String = run.route_snapshot().nodes.filter(func(node): return node.state == "available")[0].id
	app.request_node_entry(node_id)
	app.confirm_node_entry()
	await settle()
	check(app.service_screen != null, tag + ": real next recovery service opens for refinement.")
	if app.service_screen != null:
		var target: Dictionary = run.snapshot().owned_cards.filter(func(card): return card.id == "cinder_guard")[0]
		app.service_screen.select_choice("refine_rune")
		await settle()
		app.service_screen.select_upgrade(target.uid)
		await capture("mixed-upgrade-preview-" + tag, app.service_screen.panel, app.service_screen.modal_action)
		app.service_screen.confirm_choice()
		await settle()
		check(run.snapshot().owned_cards.any(func(card): return card.uid == target.uid and card.upgrade_rank == 1), tag + ": exact purchased UID receives supported refinement.")
		app.open_collection()
		await settle()
		var upgraded: Array = app.collection_screen.presentation.groups.filter(func(group): return group.id == "cinder_guard")
		if not upgraded.is_empty(): app.collection_screen._inspect_group(upgraded[0])
		await capture("mixed-upgraded-collection-" + tag, app.collection_screen.panel, app.collection_screen.close_button)
		check(not upgraded.is_empty() and upgraded[0].card.description.contains("6 damage and 4 shield"), tag + ": collection resolves both upgraded contributions.")
	app.queue_free()
	await settle()
	await upgraded_combat(run, tag)

func upgraded_combat(run, tag: String) -> void:
	# An explicit prelaunch gallery opening draws the real acquired collection;
	# UID, rank, health and random streams come from the supported transactions.
	var setup: Dictionary = Loader.load_setup("res://data/production_stone_sentinel_encounter.json").setup
	var entry: Dictionary = run._entry_data()
	entry.encounter_id = setup.encounter.id
	setup.owned_cards = entry.owned_cards.map(func(card): return card.id)
	setup.opening_draw = setup.owned_cards.size()
	var made := Combat.create_for_run(setup, entry)
	check(made.ok, tag + ": real purchased/refined UID validates in a new production-enemy Combat entry.")
	if not made.ok: return
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.entry_setup = setup
	scene.battle_model = made.combat
	scene.settings_path = OUT.path_join("upgraded-combat-" + tag + ".cfg")
	root.add_child(scene)
	scene.animation_presenter.automatic_timing = false
	await settle()
	var card: Dictionary = scene.game.hand.filter(func(item): return item.id == "cinder_guard")[0]
	var button: Button = scene.hand_box.get_children().filter(func(child): return child.get_meta("uid", -1) == card.uid)[0]
	scene.hand_scroll.ensure_control_visible(button)
	var title: Label = button.find_child("Title", true, false)
	check(title.text == "Cinder Guard +" and title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x <= title.size.x, tag + ": full upgraded name and plus marker fit the actual hand card.")
	await capture("upgraded-mixed-hand-" + tag)
	scene._inspect_hand(card.uid)
	await capture("upgraded-mixed-inspection-" + tag, scene.inspector_panel, scene.inspector_close)
	check(scene.inspector_text.text.contains("6 damage and 4 shield") and scene.inspector_text.text.contains("copy %d" % card.uid), tag + ": full inspection links effective mixed values to purchased/refined UID.")
	scene._close_inspector(false)
	scene.queue_free()
	await settle()

func production_unlock(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var run = Journey.new_run(1)
	for depth in range(1, 7):
		var entered := Journey.enter(run, Journey.next_node(run, "normal"))
		check(entered.ok, tag + ": production milestone journey enters visit %d." % depth)
		if not entered.ok: return
		if entered.has("combat"):
			var controller := Controller.new(entered.combat)
			var player := Player.new()
			var commands: Array = []
			controller.command_resolved.connect(func(outcome): commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted}))
			for turn in 80:
				if entered.combat.state != "playing": break
				check(player.play_turn(controller), tag + ": ordinary legal production turn.")
			controller.dispose()
			check(entered.combat.state == "victory" and run.resolve_battle(entered.combat), tag + ": real production victory at depth %d." % depth)
			traces.append({"size": tag, "depth": depth, "commands": commands, "hp": entered.combat.player_hp})
			if depth < 6: check(Journey.finish_rewards(run).ok, tag + ": earlier ordinary reward resolves.")
		else: check(Journey.finish_room(run).ok, tag + ": actual event resolves.")
	var rune_records: Array = run.snapshot().reward_records.filter(func(record): return record.status == "pending" and record.kind == "run_card")
	for record in rune_records:
		check(run.skip_reward(record.identity).ok, tag + ": ordinary boss rune choice resolves before permanent choice.")
		if not record.gold_claimed: check(run.claim_reward_gold(record.identity).ok, tag + ": zero-Gold component settles without income.")
	var app := shell_for(run, OUT.path_join("milestone-" + tag + "-" + str(Time.get_ticks_usec()) + ".json"), {})
	await settle()
	app.continue_run()
	app.open_rewards()
	await settle()
	var reward: Dictionary = run.pending_reward()
	check(reward.get("kind") == "definition_unlock" and reward.get("offered_ids", []).size() > 0, tag + ": real Shadeling milestone offers still-locked implemented definitions.")
	if reward.get("kind") == "definition_unlock" and not reward.get("offered_ids", []).is_empty():
		await capture("production-unlock-" + tag, app.reward_screen.panel, app.reward_screen.close_button)
		var selected := str(reward.offered_ids[0])
		app.reward_screen.scroll.ensure_control_visible(app.reward_screen.choose_buttons[selected])
		await capture("production-unlock-action-" + tag, app.reward_screen.panel, app.reward_screen.close_button)
		var owned: Array = run.snapshot().owned_cards
		app.reward_screen.choose_buttons[selected].pressed.emit()
		await settle()
		check(selected in run.snapshot().profile.unlocked_definition_ids and run.snapshot().owned_cards == owned, tag + ": selecting real unlock grants eligibility without owned copy.")
	app.queue_free()
	await settle()
