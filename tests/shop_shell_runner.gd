extends SceneTree
## Actual configured root Window, durable shell transaction and touch geometry.
const Shell = preload("res://scripts/ui/application_shell.gd")
const Fixture = preload("res://tests/helpers/shop_route_fixture.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const LocalSave = preload("res://scripts/core/local_save.gd")
const DESTINATION := "res://output/qa/rc-029/shell"
var checks := 0
var failures := 0
var assertions: Array = []
var _capture := false

class CheckShell extends "res://scripts/ui/application_shell.gd":
	var fail_shop_scene_once := false
	func _create_shop_scene() -> Control:
		if fail_shop_scene_once:
			fail_shop_scene_once = false
			return null
		return super._create_shop_scene()

class MigrationShell extends "res://scripts/ui/application_shell.gd":
	var startup_failure := "replace"
	func _load_persistence() -> void:
		if save_store == null:
			save_store = LocalSave.new(save_path, _restore_save_payload)
			save_store.failure_point = startup_failure
		super._load_persistence()

func _initialize() -> void:
	_capture = "--capture-shop" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 8: await process_frame
	if _capture: await RenderingServer.frame_post_draw

func new_shell(path: String, context: Dictionary) -> Control:
	var app := CheckShell.new()
	app.settings_path = path + ".settings.cfg"
	app.save_path = path
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
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(720, 1600), "Shop capture uses the real unchanged configured root stretch and logical resolution.")
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await exercise(dimensions)
	await migration_and_failure_restart()
	FileAccess.open(DESTINATION.path_join("results-capture.json" if _capture else "results-headless.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Configured root Window 450x1000 and 360x640, real Wisp-earned Gold, actual durable shop shell transactions; no device acceptance."}, "  ") + "\n")
	print("RC-029 shop shell: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func exercise(dimensions: Vector2i) -> void:
	var tag := "%dx%d" % [dimensions.x, dimensions.y]
	var path := DESTINATION.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var run = Fixture.new_run()
	check(Fixture.win_first(run).ok, tag + " fixture earns Gold through supported battle and ordinary reward claims.")
	var context: Dictionary = Fixture.context_for(run)
	var app := new_shell(path, context)
	await settle()
	app.run_state = run
	app.progression = run.profile_state()
	check(app._persist_candidate(run).ok, tag + " genuine pre-shop run is durably saved before UI entry.")
	app.continue_run()
	await settle()
	check(app.map_screen != null and app.shop_screen == null, tag + " pre-shop Continue returns to route Map.")
	var node_id: String = run.route_snapshot().nodes.filter(func(n): return n.state == "available")[0].id
	var before_entry: Dictionary = run.export_save()
	app.request_node_entry(node_id)
	app.cancel_confirmation()
	check(run.export_save() == before_entry and app.shop_screen == null, tag + " entry cancellation consumes no visit or stock.")
	app.request_node_entry(node_id)
	app.save_store.failure_point = "replace"
	app.confirm_node_entry()
	await settle()
	check(run.export_save() == before_entry and app.shop_screen == null and app.confirmation.visible and app._failed_transaction.action == "shop_entry", tag + " failed entry preserves Map and route before durable publication.")
	var staged_stock: Dictionary = app._failed_transaction.candidate.shop_snapshot()
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(app.shop_screen != null and app.combat_scene == null and app.map_screen == null and run.shop_snapshot() == staged_stock, tag + " entry Retry opens the exact staged shop as main screen.")
	if app.shop_screen == null:
		app.queue_free()
		await settle()
		return
	var shop: Control = app.shop_screen
	var stock: Dictionary = run.shop_snapshot()
	var identity: Dictionary = stock.identity
	var slot: String = stock.slots[0].slot_id
	var profile_before: Dictionary = run.profile_state().export_save()
	var original: Dictionary = run.export_save()
	await capture(app, "shop-" + tag)
	shop.scroll.scroll_vertical = 100000
	await settle()
	await capture(app, "services-" + tag)
	shop.scroll.scroll_vertical = 0
	await settle()
	shop.inspect_slot(slot)
	await settle()
	check(shop.inspection.visible and shop.modal_action.text.begins_with("Buy"), tag + " item inspection is reachable without a transaction.")
	await capture(app, "item-inspection-" + tag)
	shop.dismiss_top()
	check(run.export_save() == original and not shop.inspection.visible, tag + " closing inspection does not mean Leave.")
	shop.open_removal()
	await settle()
	check(shop.selection_buttons.size() == 8, tag + " removal selection presents each owned UID separately.")
	await capture(app, "removal-selection-" + tag)
	shop.select_removal(0)
	await settle()
	check(shop.inspection.visible and shop.modal_action.text == "Remove · 40 Gold", tag + " exact-card confirmation shows selected copy, price and resulting count.")
	await capture(app, "removal-confirmation-" + tag)
	shop.dismiss_top()
	shop.confirm_removal()
	check(run.export_save() == original, tag + " removal cancellation preserves collection, Gold and allowance.")
	app.open_map()
	await settle()
	check(app.map_screen != null and run.export_save() == original, tag + " Map inspection keeps the same active shop.")
	app.close_map()
	await settle()
	check(app.shop_screen == shop and app.map_screen == null and run.export_save() == original, tag + " Map Back resumes the same shop without consuming stock.")
	app._shop_menu_requested(app._generation)
	await settle()
	check(app.route_menu.visible and app.route_menu_resume.text == "Resume Combat", tag + " shared Menu preserves the approved literal Resume Combat label.")
	var menu_instance: int = app.route_menu.get_instance_id()
	var menu_rect: Rect2 = root.get_final_transform() * app._route_menu_panel.get_global_rect()
	var menu_body: Label = app._route_menu_panel.get_meta("rc_body_scroll").get_child(0)
	check(menu_body.text == "Resume returns to this shop. Quit to Home keeps this visit, stock and purchases; Continue returns here.\n\nStore: Buy supplies between rooms, after the current room is complete.", tag + " shop Menu retains its visit/stock explanation and explains the separate Store's between-room eligibility.")
	check(app.route_menu_store.disabled, tag + " an active route shop keeps the separate Store unavailable until the room is complete.")
	app.route_menu_store.pressed.emit()
	app.open_store()
	check(not app.store_screen.visible and app.shop_screen == shop and run.export_save() == original, tag + " disabled and direct Store callbacks cannot interrupt the active shop or alter its stock, allowance or Gold.")
	if dimensions == Vector2i(450, 1000): check(menu_rect.is_equal_approx(Rect2(24, 170, 402, 660)), tag + " shop caller retains the exact approved shared Menu panel geometry.")
	await capture(app, "shop-menu-" + tag)
	app._close_route_menu()
	app.open_map()
	await settle()
	var active_map: Control = app.map_screen
	app._map_menu_requested(app._map_generation)
	await settle()
	check(app.route_menu.visible and app.route_menu.get_instance_id() == menu_instance and (root.get_final_transform() * app._route_menu_panel.get_global_rect()).is_equal_approx(menu_rect) and app.route_menu_resume.text == "Resume Combat" and menu_body.text.begins_with("Resume returns to this shop."), tag + " Map-over-Shop uses the same caller-aware Menu, geometry and literal action label.")
	await capture(app, "shop-map-menu-" + tag)
	app.route_menu_resume.pressed.emit()
	await settle()
	check(app.map_screen == active_map and not app.route_menu.visible and run.export_save() == original, tag + " Menu Resume retains its exact Map-over-Shop caller without completing the room.")
	app.close_map()
	await settle()
	app._return_home()
	await settle()
	check(app.home.visible and app.shop_screen == null and run.export_save() == original, tag + " Home retains the active visit and stock.")
	app.fail_shop_scene_once = true
	app.continue_run()
	await settle()
	check(app.shop_screen == null and app.confirmation.visible and app.confirmation_confirm.text == "Retry" and run.export_save() == original, tag + " saved-shop attachment failure exposes Retry and preserves visit and stock.")
	app._confirm_pending()
	await settle()
	check(app.shop_screen != null and run.export_save() == original, tag + " Continue deliberately dispatches service-room resume.")
	shop = app.shop_screen
	app.save_store.failure_point = "flush"
	app._purchase_shop_rune(identity, slot)
	await settle()
	check(run.export_save() == original and app.confirmation.visible and cue_count(app.audio, "reward") == 0, tag + " failed purchase publishes no debit, stock change, card or acquisition cue.")
	await capture(app, "save-failure-" + tag)
	var intended_uid: int = app._failed_transaction.candidate.shop_snapshot().slots[0].granted_uid
	var reentrant := [0]
	app.audio.cue_started.connect(func(record):
		if record.get("cue") == "reward":
			reentrant[0] += 1
			app._purchase_shop_rune(identity, stock.slots[1].slot_id)
			app._remove_shop_rune(identity, 1)
			app._leave_shop(identity))
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.snapshot().gold == 70 and run.snapshot().owned_cards.size() == 9 and run.snapshot().owned_cards.back().uid == intended_uid and run.snapshot().next_uid == intended_uid + 1, tag + " Retry preserves exactly one staged UID and debit.")
	check(cue_count(app.audio, "reward") == 1 and reentrant[0] == 1 and run.route_snapshot().status == "room_active" and not run.shop_snapshot().removal.used, tag + " success audio fires once after save and rejects reentrant purchase/removal/Leave: cues=%d callbacks=%d phase=%s removed=%s" % [cue_count(app.audio, "reward"), reentrant[0], run.route_snapshot().status, run.shop_snapshot().removal.used])
	await capture(app, "sold-" + tag)
	var bought: Dictionary = run.export_save()
	app._purchase_shop_rune(identity, slot)
	app._remove_shop_rune(identity, -99)
	check(run.export_save() == bought, tag + " double purchase and stale selected UID reject without mutation.")
	shop.open_removal()
	shop.select_removal(0)
	app.save_store.failure_point = "backup"
	shop.confirm_removal()
	await settle()
	check(run.export_save() == bought and app.confirmation.visible, tag + " failed removal keeps exact owned cards and service allowance.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(run.snapshot().gold == 30 and run.snapshot().owned_cards.size() == 8 and run.shop_snapshot().removal.used and run.snapshot().owned_cards.filter(func(c): return c.uid == 0).is_empty(), tag + " removal Retry charges once and removes only the chosen UID.")
	check(run.profile_state().export_save() == profile_before, tag + " shop transactions preserve permanent unlocks.")
	var second: String = stock.slots[1].slot_id
	app._purchase_shop_rune(identity, second)
	await settle()
	check(run.snapshot().gold == 0 and run.snapshot().owned_cards.size() == 9, tag + " exact-price purchase reaches zero Gold.")
	var funded_out: Dictionary = run.export_save()
	app._purchase_shop_rune(identity, stock.slots[2].slot_id)
	await settle()
	check(run.export_save() == funded_out and not shop.status_label.text.is_empty(), tag + " insufficient Gold preserves inventory and gives concise feedback.")
	await capture(app, "insufficient-gold-" + tag)
	# A fresh shell instance loads exact stock; OS-process coverage is separate.
	app.queue_free()
	await settle()
	app = new_shell(path, context)
	await settle()
	run = app.run_state
	check(run != null and run.export_save() == funded_out and cue_count(app.audio, "reward") == 0, tag + " restored receipts never replay acquisition audio.")
	app.continue_run()
	await settle()
	check(app.shop_screen != null and run.shop_snapshot().slots[0].sold and run.shop_snapshot().removal.used, tag + " restored Continue retains sold stock and once-used service.")
	app.save_store.failure_point = "close"
	app._leave_shop(identity)
	await settle()
	check(run.export_save() == funded_out and app.shop_screen != null and run.inspect_node("d3").state == "locked", tag + " failed Leave retains the active room and successor lock.")
	app.save_store.failure_point = ""
	app.retry_save()
	await settle()
	check(app.shop_screen == null and app.map_screen != null and run.inspect_node("d3").state == "available", tag + " Leave Retry retires shop once and returns to unlocked Map.")
	var left: Dictionary = run.export_save()
	app._purchase_shop_rune(identity, stock.slots[2].slot_id)
	app._remove_shop_rune(identity, 1)
	app._leave_shop(identity)
	check(run.export_save() == left, tag + " stale callbacks from retired shop cannot transact.")
	app.queue_free()
	await settle()

func cue_count(owner: Node, cue: String) -> int:
	return owner.trace.filter(func(record): return record.get("cue") == cue).size()

func migration_and_failure_restart() -> void:
	var path := DESTINATION.path_join("restart-failed-" + str(Time.get_ticks_usec()) + ".json")
	var run = Fixture.new_run()
	check(Fixture.win_first(run).ok and Fixture.enter_shop(run).ok, "Restart-failure shell is funded only through genuine battle and enters its real shop.")
	var context: Dictionary = Fixture.context_for(run)
	var app := new_shell(path, context)
	await settle()
	app.run_state = run
	app.progression = run.profile_state()
	check(app._persist_candidate(run).ok, "Active shop checkpoint is durable before the failed purchase.")
	app.continue_run()
	await settle()
	var original: Dictionary = run.export_save()
	var stock: Dictionary = run.shop_snapshot()
	app.save_store.failure_point = "replace"
	app._purchase_shop_rune(stock.identity, stock.slots[0].slot_id)
	await settle()
	var intended_uid: int = app._failed_transaction.candidate.shop_snapshot().slots[0].granted_uid
	check(run.export_save() == original and not app._failed_transaction.is_empty(), "Unsaved purchase retains only an in-memory candidate before shutdown.")
	app.queue_free()
	await settle()
	app = new_shell(path, context)
	await settle()
	run = app.run_state
	check(run.export_save() == original and app._failed_transaction.is_empty() and not run.shop_snapshot().slots[0].sold, "New shell after failure restores old Gold and unsold stock, discarding the unsaved intent.")
	app.continue_run()
	await settle()
	app._purchase_shop_rune(stock.identity, stock.slots[0].slot_id)
	await settle()
	check(run.snapshot().gold == 70 and run.snapshot().owned_cards.size() == 9 and run.shop_snapshot().slots[0].granted_uid == intended_uid and cue_count(app.audio, "reward") == 1, "Fresh user input after restart buys the same retained slot once with the unchanged allocator.")
	app.queue_free()
	await settle()
	var migration_path := DESTINATION.path_join("startup-migration-" + str(Time.get_ticks_usec()) + ".json")
	var source := "res://tests/fixtures/rc028/production-v1.json"
	check(DirAccess.copy_absolute(source, migration_path) == OK, "Startup migration starts from actual RC-028 production bytes.")
	var original_bytes := FileAccess.get_file_as_bytes(migration_path)
	var migrating := MigrationShell.new()
	migrating.save_path = migration_path
	migrating.settings_path = migration_path + ".settings.cfg"
	root.add_child(migrating)
	migrating.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	check(migrating.run_state == null and migrating._failed_transaction.action == "migrate" and migrating.confirmation.visible and FileAccess.get_file_as_bytes(migration_path) == original_bytes, "Failed startup migration publishes no owner, preserves v1 bytes and exposes Retry.")
	var migrated_intent: Dictionary = migrating._failed_transaction.candidate.export_save()
	migrating.save_store.failure_point = ""
	migrating.retry_save()
	await settle()
	check(migrating.run_state != null and migrating.run_state.export_save() == migrated_intent and not migrating.continue_button.disabled, "Startup migration Retry publishes the same converted model and enables Continue.")
	check(FileAccess.get_file_as_bytes(migration_path + ".previous") == original_bytes, "Startup migration validates and retains real v1 predecessor as previous copy.")
	migrating.queue_free()
	await settle()
	FileAccess.open(migration_path, FileAccess.WRITE).store_string("damaged-current")
	app = new_shell(migration_path, {})
	await settle()
	check(app.run_state == null and app._recovery_available and app.continue_button.disabled, "Corrupt migrated current blocks Continue and offers validated v1 previous-copy recovery.")
	app.open_save_recovery()
	app.save_store.failure_point = "replace"
	app.recover_previous_save()
	await settle()
	check(app.run_state == null and app._save_status == "invalid", "Failed recovery promotion preserves blocked state and never publishes a candidate.")
	app.save_store.failure_point = ""
	app.retry_load_save()
	await settle()
	check(app._recovery_available, "Retry loading revalidates the previous copy after failed recovery promotion.")
	app.recover_previous_save()
	await settle()
	check(app.run_state != null and app.run_state.export_save() == migrated_intent and not app.continue_button.disabled, "Successful v1 previous-copy recovery migrates and resumes the original exact identities: " + app.startup_error + " retry=" + str(app._failed_transaction.get("error", "")))
	app.queue_free()
	await settle()

func capture(app: Control, filename: String) -> void:
	if not _capture: return
	await settle()
	var bounds := root.get_final_transform() * root.get_visible_rect()
	var controls: Array = []
	if app.confirmation.visible:
		controls = [app.confirmation_confirm, app.confirmation_cancel]
	elif app.route_menu.visible:
		controls = [app.route_menu_resume, app.route_menu_quit, app.route_menu_options]
	elif app.shop_screen.inspection.visible:
		controls = [app.shop_screen.modal_action, app.shop_screen.modal_close]
		check(bounds.encloses(root.get_final_transform() * app.shop_screen.panel.get_global_rect()), filename + " popup lies within configured content bounds.")
	else:
		controls = [app.shop_screen.leave_button]
		check(app.shop_screen._title.visible and not app.shop_screen._title.text.is_empty() and app.shop_screen.balance.get_line_count() == 1, filename + " keeps the shop title and Gold balance on one readable header line.")
		check(bounds.encloses(root.get_final_transform() * app.shop_screen._header.get_global_rect()) and not app.shop_screen._header.get_global_rect().intersects(app.shop_screen.scroll.get_global_rect()), filename + " header fits and does not overlap stock.")
	for button in controls:
		if button.is_visible_in_tree(): check(bounds.encloses(root.get_final_transform() * button.get_global_rect()), filename + " keeps " + button.text + " reachable.")
	check(root.get_texture().get_image().save_png(DESTINATION.path_join(filename + ".png")) == OK, filename + " actual root screenshot saved.")
