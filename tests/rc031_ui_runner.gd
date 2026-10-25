extends SceneTree
## Authoritative durable room flows at the real configured root sizes. Captures
## use the normal renderers, isolated settings/saves and genuine fixture battles.
const Shell = preload("res://scripts/ui/application_shell.gd")
const Fixture = preload("res://tests/helpers/rc031_ui_fixture.gd")
const CollectionData = preload("res://scripts/ui/collection_data.gd")
const InspectionData = preload("res://scripts/ui/inspection_data.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/rc-031/ui"
var checks := 0
var failures := 0
var assertions: Array = []
var capturing := false

func _initialize() -> void:
	capturing = "--capture-rc031" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 8: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await settle()
	var app: Control = root.get_children().filter(func(child): return child is Shell)[0]
	var bounds := root.get_final_transform() * root.get_visible_rect()
	var panel: PanelContainer
	var controls: Array = []
	if app.confirmation.visible:
		panel = app._confirmation_panel
		controls = [app.confirmation_confirm, app.confirmation_cancel]
	elif app.collection_screen.visible:
		panel = app.collection_screen.panel
		controls = [app.collection_screen.close_button]
	elif app.shop_screen != null:
		if app.shop_screen.inspection.visible:
			panel = app.shop_screen.panel
			controls = [app.shop_screen.modal_action, app.shop_screen.modal_close]
		else: controls = [app.shop_screen.leave_button]
	elif app.service_screen != null:
		if app.service_screen.inspection.visible:
			panel = app.service_screen.panel
			controls = [app.service_screen.modal_action, app.service_screen.modal_close]
		else: controls = [app.service_screen.leave_button]
	if panel != null: check(bounds.encloses(root.get_final_transform() * panel.get_global_rect()) and panel.size.y <= 660, name + " popup fits the configured window and shared height cap.")
	for button in controls:
		if button.is_visible_in_tree(): check(bounds.encloses(root.get_final_transform() * button.get_global_rect()), name + " keeps " + button.text + " reachable.")
	if capturing:
		check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + " screenshot saved.")

func create_shell(path: String, context: Dictionary) -> Control:
	var app := Shell.new()
	app.save_path = path
	app.settings_path = path + ".settings.cfg"
	app.persistence_context = context
	var values: Dictionary = Settings.DEFAULTS.duplicate(true)
	values.reduced_motion = true
	Settings.save_values(values, app.settings_path)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.audio.trace_enabled = true
	return app

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	data_checks()
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		for variant in ["shop", "recovery", "desk", "reliquary"]:
			await room(dimensions, variant)
	FileAccess.open(DESTINATION.path_join("results-capture.json" if capturing else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Real configured-root UI; genuine fixture Wisp victory and explicit fixture Gold. Durable shop upgrades/relics and recovery/Desk/Reliquary targets, cancellation, failure/Retry and saved reopening. No physical-device acceptance."}, "  ") + "\n")
	print("RC-031 UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func data_checks() -> void:
	var catalog: Dictionary = Loader.load_setup().setup.catalog
	var original: Dictionary = catalog.duplicate(true)
	var one := {"id": "spark", "uid": 8, "upgrade_rank": 1}
	var two := {"id": "spark", "uid": 9, "upgrade_rank": 0}
	var display := CollectionData.describe({"owned_cards": [one, two], "relics": ["relic_heart_stone"]}, catalog)
	check(display.groups.size() == 2 and display.definition_count == 1 and display.owned_count == 2, "Collection separates upgraded and base copies while preserving definition/ownership counts.")
	check(display.groups.any(func(group): return group.card.name == "Spark +" and group.card.description.contains("8 damage") and group.instances[0].uid == 8), "Upgraded collection card shows exact UID and effective value.")
	check(display.groups.any(func(group): return group.card.name == "Spark" and group.card.description.contains("6 damage") and group.instances[0].uid == 9), "Unupgraded duplicate retains its own base effect.")
	check(display.relics.size() == 1 and display.relics[0].id == "relic_heart_stone", "Collection includes acquired relic inspection data.")
	var snapshot := {"catalog": catalog, "hand": [one], "production": {}}
	var detail := InspectionData.describe_hand(snapshot, 8)
	check(detail.title == "Spark +" and detail.text.contains("8 damage") and detail.text.contains("copy 8"), "Hand inspection resolves the ranked instance and identifies its copy.")
	check(CollectionData.upgrade_text(catalog, two).contains("6 damage") and CollectionData.upgrade_text(catalog, two).contains("8 damage"), "Upgrade preview shows actual before and after values.")
	check(catalog == original, "Presentation never mutates immutable base definitions.")

func room(dimensions: Vector2i, variant: String) -> void:
	var tag := "%s-%dx%d" % [variant, dimensions.x, dimensions.y]
	var path := DESTINATION.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var run = Fixture.new_run(42, variant)
	var earned: Dictionary = Fixture.win_first(run)
	check(earned.get("ok", false), tag + " reaches room through genuine supported victory and explicit fixture reward.")
	if not earned.get("ok", false): return
	var context := Fixture.context_for(run)
	var app := create_shell(path, context)
	await settle()
	app.run_state = run
	app.progression = run.profile_state()
	var persisted: Dictionary = app._persist_candidate(run)
	check(persisted.get("ok", false), tag + " persists the authentic battle/reward boundary.")
	if not persisted.get("ok", false):
		app.queue_free()
		await settle()
		return
	app.continue_run()
	await settle()
	app.request_node_entry(Fixture.next_node(run))
	app.confirm_node_entry()
	await settle()
	if variant == "shop": await shop(app, tag)
	else: await service(app, tag, variant)
	var durable: Dictionary = run.export_save()
	var profile: Dictionary = run.snapshot().profile
	app._return_home()
	app.queue_free()
	await settle()
	var restored := create_shell(path, context)
	await settle()
	check(restored.run_state != null and restored.run_state.export_save() == durable, tag + " saved reopen preserves exact ranks, relics, resources and receipt history.")
	check(restored.run_state != null and restored.run_state.snapshot().profile == profile, tag + " acquisition never changes permanent definition unlocks.")
	restored.queue_free()
	await settle()

func shop(app: Control, tag: String) -> void:
	check(app.shop_screen != null, tag + " shop opens through durable shell entry.")
	if app.shop_screen == null: return
	var run = app.run_state
	var viewer: Control = app.shop_screen
	var record: Dictionary = run.shop_snapshot()
	var original: Dictionary = run.export_save()
	var target: Dictionary = record.upgrade.targets.filter(func(card): return card.id == "spark")[0]
	await capture("choices-" + tag)
	viewer.open_upgrade()
	await capture("exact-copy-selection-" + tag)
	check(viewer.selection_buttons.has(int(target.uid)), tag + " upgrade picker identifies exact eligible UID.")
	viewer.select_upgrade(target.uid)
	await capture("upgrade-preview-" + tag)
	check(viewer.modal_action.text.contains("35"), tag + " upgrade confirmation displays policy price.")
	viewer.dismiss_top()
	viewer.confirm_upgrade()
	check(run.export_save() == original, tag + " selecting and canceling upgrade causes no transaction.")
	viewer.open_upgrade()
	viewer.select_upgrade(target.uid)
	app.save_store.failure_point = "replace"
	var cues := cue_count(app.audio)
	viewer.confirm_upgrade()
	await settle()
	check(run.export_save() == original and app._failed_transaction.get("action") == "shop_upgrade", tag + " save failure retains original owner/rank/Gold/allowance.")
	check(cue_count(app.audio) == cues, tag + " failed save emits no acquisition feedback.")
	if app._failed_transaction.is_empty(): return
	var candidate: Dictionary = app._failed_transaction.candidate.export_save()
	await capture("upgrade-save-failure-" + tag)
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.export_save() == candidate, tag + " Retry publishes the exact upgrade candidate.")
	check(cue_count(app.audio) == cues + 1, tag + " durable upgrade emits one existing confirmation cue.")
	var upgraded: Dictionary = run.snapshot().owned_cards.filter(func(card): return card.uid == target.uid)[0]
	check(upgraded.id == target.id and upgraded.upgrade_rank == 1, tag + " durable upgrade preserves definition and exact UID.")
	var settled: Dictionary = run.export_save()
	app._upgrade_shop_rune(record.identity, target.uid)
	check(run.export_save() == settled, tag + " repeated upgrade input cannot spend or rank twice.")
	viewer = app.shop_screen
	var relic_slot: Dictionary = run.shop_snapshot().relic_slots[0]
	viewer.inspect_relic(str(relic_slot.slot_id))
	await capture("relic-inspection-" + tag)
	viewer._modal_activate()
	await settle()
	check(str(relic_slot.definition_id) in run.snapshot().relics and run.snapshot().gold == 65, tag + " shop relic and upgrade prices reconcile atomically.")
	check(cue_count(app.audio) == cues + 2, tag + " durable relic purchase emits one existing confirmation cue.")
	app.open_collection()
	await settle()
	var upgraded_button: Button = app.collection_screen.card_buttons.filter(func(button): return button.get_meta("collection_group").get("upgrade_rank") == 1)[0]
	app.collection_screen.body_scroll.ensure_control_visible(upgraded_button)
	await capture("upgraded-collection-" + tag)
	check(app.collection_screen.presentation.groups.any(func(group): return group.id == "spark" and group.upgrade_rank == 1), tag + " actual acquired copy appears upgraded in collection.")
	check(app.collection_screen.relic_buttons.size() == 1, tag + " acquired relic is available through Collection.")
	upgraded_button.pressed.emit()
	await capture("upgraded-card-detail-" + tag)
	app.collection_screen.dismiss_top()
	app.collection_screen.relic_buttons[0].pressed.emit()
	await capture("owned-relic-inspection-" + tag)
	app.close_collection()
	viewer.open_removal()
	viewer.select_removal(target.uid)
	await capture("upgraded-removal-" + tag)
	viewer.dismiss_top()
	viewer.scroll.scroll_vertical = 99999
	await capture("services-" + tag)

func service(app: Control, tag: String, variant: String) -> void:
	check(app.service_screen != null, tag + " service opens through durable shell entry.")
	if app.service_screen == null: return
	var run = app.run_state
	var viewer: Control = app.service_screen
	var original: Dictionary = run.export_save()
	var record: Dictionary = run.service_snapshot()
	var choice := "open_reliquary" if variant == "reliquary" else "refine_rune"
	await capture("choices-" + tag)
	viewer.select_choice(choice)
	await capture("target-selection-" + tag)
	var target: Variant = null
	if variant == "reliquary":
		target = viewer.selection_buttons.keys()[0]
		check(viewer.selection_buttons.size() == mini(2, record.offered_relics.size()), tag + " retained distinct relic offers populate the picker.")
		viewer.select_relic(target)
	else:
		target = viewer.selection_buttons.keys()[0]
		viewer.select_upgrade(target)
		check(viewer.modal_body.text.contains("Before:") and viewer.modal_body.text.contains("After:"), tag + " free upgrade previews both effective values.")
	await capture("target-preview-" + tag)
	viewer.dismiss_top()
	viewer.confirm_choice()
	check(run.export_save() == original, tag + " target selection and cancellation leave resources and room unchanged.")
	viewer.select_choice(choice)
	if variant == "reliquary": viewer.select_relic(target)
	else: viewer.select_upgrade(target)
	app.save_store.failure_point = "replace"
	var cues := cue_count(app.audio)
	viewer.confirm_choice()
	await settle()
	check(run.export_save() == original and app._failed_transaction.get("action") == "service_resolve", tag + " failed item service save retains ownership and unresolved room.")
	check(cue_count(app.audio) == cues, tag + " failed service emits no acquisition feedback.")
	if app._failed_transaction.is_empty(): return
	var candidate: Dictionary = app._failed_transaction.candidate.export_save()
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.export_save() == candidate and app.service_screen == null and app.map_screen != null, tag + " Retry publishes exact item service and completes room once.")
	check(cue_count(app.audio) == cues + 1, tag + " durable service emits one confirmation cue.")
	if variant == "reliquary": check(str(target) in run.snapshot().relics and run.snapshot().gold == 145, tag + " selected relic and 15 Gold reconcile.")
	else:
		check(run.snapshot().owned_cards.any(func(card): return card.uid == target and card.upgrade_rank == 1), tag + " selected exact copy is upgraded.")
		check(run.snapshot().player_hp == int(original.player_hp), tag + " upgrade cannot also apply recovery healing.")
	var settled: Dictionary = run.export_save()
	app._resolve_service_choice(record.identity, choice, target)
	check(run.export_save() == settled, tag + " stale repeated target input cannot resolve a completed room.")

func cue_count(owner: Node) -> int:
	return owner.trace.filter(func(record): return record.get("cue") == "ui_confirm").size()
