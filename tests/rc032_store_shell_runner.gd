extends "res://tests/rc032_route_shell_runner.gd"
## Approved Store integration through the actual shell and unchanged full-route
## fixture. Run Gold is earned by legal battles; no postlaunch resource edits.
const OUTPUT := "res://output/qa/rc-032-store/ui"
var output_root := OUTPUT
var final_summaries: Array = []
var stale_store_identity: Dictionary = {}

func _initialize() -> void:
	capturing = "--capture-rc032-store" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-root="): output_root = arg.trim_prefix("--output-root=")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_root)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		await store_journey(dimensions, "normal" if dimensions.x == 450 else "elite")
	await create_timer(0.3).timeout
	var suffix := "capture" if capturing else "headless"
	FileAccess.open(output_root.path_join("results-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "summaries": final_summaries, "scope": "Ordinary shell Store access without a test opt-in, durable transactions interleaved with legal nine-visit normal/elite fixture routes; actual configured 450x1000/360x640 windows, desktop Back simulations only."}, "  ") + "\n")
	FileAccess.open(output_root.path_join("legal-commands-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  ") + "\n")
	print("RC-032 Store shell: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(app: Control, name: String) -> void:
	await settle()
	var bounds := root.get_final_transform() * root.get_visible_rect()
	var panel: PanelContainer
	var actions: Array = []
	if app.confirmation.visible:
		panel = app._confirmation_panel
		actions = [app.confirmation_confirm, app.confirmation_cancel]
		if app.recovery_retry_button.visible: actions.append(app.recovery_retry_button)
	elif app.store_screen.visible:
		panel = app.store_screen.panel
		actions = [app.store_screen.close_button]
	elif app.run_review.visible:
		panel = app.run_review.panel
		actions = [app.run_review.primary_button, app.run_review.secondary_button]
	elif app.route_menu.visible:
		panel = app._route_menu_panel
		actions = [app.route_menu_resume, app.route_menu_store, app.route_menu_quit]
	if panel != null:
		check(bounds.encloses(root.get_final_transform() * panel.get_global_rect()) and panel.size.y <= 660, name + ": popup fits the configured window and shared height cap.")
	for action in actions:
		check(action.is_visible_in_tree() and bounds.encloses(root.get_final_transform() * action.get_global_rect()), name + ": fixed action is reachable: " + action.text)
	if capturing: check(root.get_texture().get_image().save_png(output_root.path_join(name + ".png")) == OK, name + ": screenshot saved.")

func open_catalogue(app: Control, tag: String) -> bool:
	if not app.route_menu.visible:
		if app.map_screen == null: return false
		app.map_screen.menu_requested.emit()
	var before: Dictionary = app.run_state.export_save()
	var revision: int = app._save_revision
	app._update_route_menu_actions()
	app._store_purchase_requested(app.run_state.store_snapshot().get("identity", {}), "rune", "spark")
	app.confirm_store_purchase()
	check(not app.route_menu_store.disabled and not app.store_screen.visible and app.run_state.export_save() == before and app._save_revision == revision,
		tag + ": eligible Menu enables Store while detached purchase callbacks cannot save or change ownership.")
	app.route_menu_store.pressed.emit()
	await settle()
	check(app.store_screen.visible and app.route_menu.visible and app.run_state.export_save() == before and app._save_revision == revision,
		tag + ": ordinary Store opens over the retained shared Menu without consuming or saving run resources.")
	return app.store_screen.visible

func close_catalogue(app: Control, tag: String) -> void:
	var menu: Control = app.route_menu
	var map: Control = app.map_screen
	app.store_screen.close_button.pressed.emit()
	await settle()
	check(not app.store_screen.visible and app.route_menu == menu and menu.visible and app.map_screen == map, tag + ": Store Back restores the identical Menu and Map caller.")
	app.route_menu_resume.pressed.emit()
	await settle()

func deny_store(app: Control, tag: String) -> void:
	var before: Dictionary = app.run_state.export_save()
	check(not app.run_state.store_snapshot().enabled, tag + ": authoritative Store access is unavailable at this boundary.")
	app.open_store()
	app._store_purchase_requested(stale_store_identity, "rune", "spark")
	check(not app.store_screen.visible and app.run_state.export_save() == before, tag + ": direct open and retained purchase callback cannot transact.")

func store_journey(dimensions: Vector2i, branch: String) -> void:
	var tag := "%s-%dx%d" % [branch, dimensions.x, dimensions.y]
	var path := output_root.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var context := Fixture.context_for(Fixture.new_run())
	var app := create_shell(path, context)
	await settle()
	app.new_run_button.pressed.emit()
	await settle()
	check(app.run_state != null and app.map_screen != null, tag + ": fixture starts from actual Home New Run.")
	if app.run_state == null or app.map_screen == null:
		app.queue_free()
		await settle()
		return
	var run = app.run_state
	if not await open_catalogue(app, tag):
		app.queue_free()
		await settle()
		return
	var initial: Dictionary = run.export_save()
	var catalogue: Dictionary = run.store_snapshot()
	stale_store_identity = catalogue.identity.duplicate(true)
	check(catalogue.gold == 0 and catalogue.runes.size() == 2 and catalogue.relics.size() == 6, tag + ": zero-Gold initial Map exposes only two fixture-unlocked runes and all six relic definitions.")
	check(catalogue.runes.all(func(item): return not item.enabled) and catalogue.relics.all(func(item): return not item.enabled), tag + ": insufficient Gold disables every purchase without hiding browsing.")
	await capture(app, "catalogue-zero-gold-" + tag)
	app.store_screen.purchase_buttons["rune:spark"].pressed.emit()
	check(not app.confirmation.visible and run.export_save() == initial, tag + ": unavailable zero-Gold purchase cannot open or commit a charge.")
	await close_catalogue(app, tag)
	var store_uid := -1
	for depth in range(1, 10):
		var node_id := Fixture.next_node(run, branch)
		var node: Dictionary = run.inspect_node(node_id)
		app.request_node_entry(node_id)
		app.confirmation_confirm.pressed.emit()
		await settle()
		check(run.route_snapshot().visit_count == depth, tag + ": real room entry commits visit %d." % depth)
		if run.route_snapshot().visit_count != depth: break
		if node.room_type in ["normal", "elite", "guardian"]:
			if depth == 1:
				var opening: Dictionary = app.combat_scene.controller.snapshot()
				app._battle_menu_requested(false, app._generation)
				await capture(app, "store-unavailable-combat-menu-" + tag)
				deny_store(app, tag + " active Combat")
				app.route_menu_quit.pressed.emit()
				app.confirmation_confirm.pressed.emit()
				await settle()
				check(run.snapshot().status == "replay_pending" and app.home.visible, tag + ": Quit preserves the real interrupted-entry checkpoint.")
				deny_store(app, tag + " interrupted entry")
				app.continue_button.pressed.emit()
				await settle()
				check(app.combat_scene != null and app.combat_scene.controller.snapshot() == opening, tag + ": Continue replays the exact opening after Store-denied interrupted entry.")
			else:
				deny_store(app, tag + " depth %d live battle" % depth)
				if store_uid >= 0:
					var state: Dictionary = app.combat_scene.controller.snapshot()
					var zones: Array = state.hand + state.draw_pile + state.discard_pile
					check(zones.filter(func(card): return card.uid == store_uid and card.id == "spark" and card.upgrade_rank == 0).size() == 1, tag + ": purchased rank-zero UID appears exactly once in later real Combat.")
			if not await battle(app, tag, depth, node): break
			deny_store(app, tag + " pending battle result")
			if depth == 1:
				app.confirmation_confirm.pressed.emit()
				await settle()
				check(run.snapshot().status == "pending_choices", tag + ": acknowledged result still retains required reward choice lock.")
				app.map_screen.menu_requested.emit()
				deny_store(app, tag + " pending rewards")
				app.route_menu_resume.pressed.emit()
			if not await rewards(app, tag, depth): break
			if depth == 1:
				store_uid = await purchase_rune_with_failures(app, tag)
				if store_uid < 0: break
			elif depth == 3:
				if not await purchase_relic_from_home(app, tag, path, context): break
			elif depth == 6:
				if await open_catalogue(app, tag):
					check(run.store_snapshot().runes.size() == 3, tag + ": committed boss definition unlock expands the eligible catalogue.")
					await close_catalogue(app, tag)
		else:
			if not await room_with_store(app, tag, node): break
		var durable: Dictionary = app.save_store.load()
		check(durable.ok and durable.payload.run == run.export_save(), tag + ": interleaved Store/room history remains durably valid after depth %d." % depth)
	check(run.snapshot().final_results_ready and app.run_review.visible, tag + ": legal Store-equipped nine-visit route reaches final results.")
	if run.snapshot().final_results_ready:
		deny_store(app, tag + " terminal victory")
		var summary: Dictionary = run.run_summary()
		check(summary.entered_rooms == 9 and summary.completed_rooms == 9 and summary.defeated_enemy_count == 6, tag + ": Store never fabricates route visits or victories.")
		check(summary.owned_cards.size() == 10 and summary.owned_cards.filter(func(card): return card.uid == store_uid and card.id == "spark" and card.upgrade_rank == 0).size() == 1, tag + ": final collection contains actual Store and shop rune purchases separately.")
		check(summary.relics.has("relic_heart_stone") and summary.player_max_hp == 34 and summary.permanent_awards.size() == 2, tag + ": final summary preserves unique Store health relic and actual permanent awards.")
		await capture(app, "store-equipped-final-results-" + tag)
		final_summaries.append({"variant": tag, "summary": summary})
		app.run_review.secondary_button.pressed.emit()
		await settle()
		var settled: Dictionary = run.export_save()
		app.queue_free()
		await settle()
		app = create_shell(path, context)
		await settle()
		check(app.run_state.export_save() == settled, tag + ": reconstructed terminal shell preserves Store receipts, limits, runes, relics and health.")
		app.continue_button.pressed.emit()
		await settle()
		check(app.run_review.visible and app.combat_scene == null and not app.store_screen.visible, tag + ": terminal Continue remains read-only with no Store access.")
		check(app.audio.trace.filter(func(event): return event.get("cue") == "reward").is_empty(), tag + ": restart never replays purchase reward audio.")
		app.run_review.primary_button.pressed.emit()
		app.confirmation_confirm.pressed.emit()
		await settle()
		var fresh: Dictionary = app.run_state.store_snapshot()
		check(app.run_state.snapshot().owned_cards.size() == 8 and app.run_state.snapshot().relics.is_empty() and app.run_state.snapshot().player_hp == 30 and not fresh.rune_purchased and not fresh.relic_purchased and fresh.runes.size() == 4, tag + ": confirmed New Run resets Store caps and run-only purchases while retaining all committed definition unlocks.")
		check(app.audio_settings.reduced_motion and is_equal_approx(float(app.audio_settings.sfx_volume), 0.37), tag + ": shared Options survive Store and replacement.")
	app.queue_free()
	await settle()

func purchase_rune_with_failures(app: Control, tag: String) -> int:
	if not await open_catalogue(app, tag): return -1
	var run = app.run_state
	var before: Dictionary = run.export_save()
	var uid: int = run.snapshot().next_uid
	var rune_count: int = run.snapshot().owned_cards.filter(func(card): return card.id == "spark").size()
	app._store_purchase_requested(stale_store_identity, "rune", "spark")
	check(not app.confirmation.visible and run.export_save() == before, tag + ": obsolete initial-map Store identity cannot buy after a battle.")
	app.store_screen.purchase_buttons["rune:spark"].pressed.emit()
	await capture(app, "rune-purchase-confirmation-" + tag)
	check(app.confirmation.visible and app.confirmation_text.text.contains("45 Gold") and app.confirmation_text.text.contains("rank-zero"), tag + ": confirmation states exact cost and fresh run-copy benefit.")
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	check(not app.confirmation.visible and app.store_screen.visible and run.export_save() == before, tag + ": one Back cancels only the nested purchase confirmation; duplicate same-frame Back does not close Store.")
	app.confirm_store_purchase()
	check(run.export_save() == before, tag + ": cancelled confirmation callback cannot purchase.")
	app.store_screen.purchase_buttons["rune:spark"].pressed.emit()
	await settle()
	var original_bytes := FileAccess.get_file_as_bytes(app.save_path)
	var intended: Dictionary = {}
	var cues: int = app.audio.trace.size()
	for point in ["write", "flush", "close", "backup", "replace"]:
		app.save_store.failure_point = point
		if point == "write": app.confirmation_confirm.pressed.emit()
		else: app.retry_save()
		await settle()
		check(not app._failed_transaction.is_empty() and run.export_save() == before and FileAccess.get_file_as_bytes(app.save_path) == original_bytes, tag + ": injected " + point + " failure preserves owners and exact durable file.")
		if app._failed_transaction.is_empty(): return -1
		var candidate: Dictionary = app._failed_transaction.candidate.export_save()
		if intended.is_empty(): intended = candidate
		check(candidate == intended, tag + ": failed Retry retains the identical Store purchase candidate at " + point + ".")
	check(app.audio.trace.size() == cues, tag + ": failed purchase writes emit no success audio.")
	await capture(app, "store-purchase-save-failure-" + tag)
	var reentrant := [0]
	var callback := func(_event: Dictionary):
		if reentrant[0] > 0: return
		reentrant[0] += 1
		app.close_store()
		app.request_new_run(77)
		app.continue_run()
		app.open_collection()
		app._store_purchase_requested(app.store_screen.presentation.identity, "rune", "spark")
	app.audio.cue_started.connect(callback)
	app.save_store.failure_point = ""
	app.retry_save()
	app.audio.cue_started.disconnect(callback)
	await settle()
	check(run.export_save() == intended and app.store_screen.visible and app.route_menu.visible and not app.collection_screen.visible and not app.confirmation.visible, tag + ": successful Retry publishes the identical purchase and rejects reentrant navigation/purchase.")
	check(reentrant[0] == 1, tag + ": success audio exercised one reentrant observer after durable publication.")
	check(run.snapshot().gold == before.gold - 45 and run.snapshot().owned_cards.filter(func(card): return card.id == "spark").size() == rune_count + 1 and run.snapshot().owned_cards.has({"id": "spark", "uid": uid, "upgrade_rank": 0}), tag + ":45 Gold buys one duplicate-allowed new rank-zero Spark UID.")
	var paid: Dictionary = run.export_save()
	var record: Dictionary = run.store_snapshot()
	check(record.rune_purchased and not record.relic_purchased and record.runes.all(func(item): return not item.enabled), tag + ": rune allowance is used once for the entire run; relic allowance remains independent.")
	app._store_purchase_requested(record.identity, "rune", "shield")
	app.confirm_store_purchase()
	check(run.export_save() == paid, tag + ": repeated or alternative rune callbacks cannot bypass the once-per-run limit.")
	await capture(app, "catalogue-rune-cap-used-" + tag)
	await close_catalogue(app, tag)
	return uid

func purchase_relic_from_home(app: Control, tag: String, path: String, context: Dictionary) -> bool:
	if not await open_catalogue(app, tag): return false
	var run = app.run_state
	var before: Dictionary = run.export_save()
	var button: Button = app.store_screen.purchase_buttons["relic:relic_heart_stone"]
	app.store_screen.scroll.ensure_control_visible(button)
	await capture(app, "catalogue-relics-" + tag)
	button.pressed.emit()
	await capture(app, "heart-stone-confirmation-" + tag)
	check(app.confirmation_text.text.contains("90 Gold") and app.confirmation_text.text.contains("Unique relic"), tag + ": relic confirmation shows90 Gold and unique run ownership.")
	var pending: Dictionary = app._pending_store.duplicate(true)
	app._pending_store.map_generation = app._map_generation - 1
	var revision: int = app._save_revision
	app.confirm_store_purchase()
	check(run.export_save() == before and app._save_revision == revision and app.confirmation.visible,
		tag + ": retained purchase confirmation from an obsolete Map generation cannot charge or save.")
	app._pending_store = pending
	app.save_store.failure_point = "replace"
	app.confirmation_confirm.pressed.emit()
	await settle()
	if app._failed_transaction.is_empty():
		check(false, tag + ": relic failure retains the staged purchase.")
		return false
	var intended: Dictionary = app._failed_transaction.candidate.export_save()
	app.confirmation_cancel.pressed.emit()
	await settle()
	check(app.home.visible and not app.store_screen.visible and run.export_save() == before and not app._failed_transaction.is_empty(), tag + ": failed Store purchase can return Home while retaining the exact in-memory Retry candidate.")
	var reconstructed := create_shell(path, context)
	await settle()
	check(reconstructed.run_state.export_save() == before and reconstructed._failed_transaction.is_empty(), tag + ": independently reconstructed shell sees only the last durable checkpoint, never unsaved purchase intent.")
	reconstructed.queue_free()
	await settle()
	var screen_reentry := [0]
	var screen_callback := func(screen: String):
		if screen != "map" or screen_reentry[0] > 0: return
		screen_reentry[0] += 1
		app.close_map()
		app.request_new_run(81)
		app.open_collection()
		app.continue_run()
	app.screen_changed.connect(screen_callback)
	app.save_store.failure_point = ""
	app.continue_button.pressed.emit()
	app.screen_changed.disconnect(screen_callback)
	await settle()
	check(run.export_save() == intended and app.store_screen.visible and app.route_menu.visible and app.map_screen != null, tag + ": Home Retry publishes the exact relic candidate and restores Map→Menu→Store.")
	check(screen_reentry[0] == 1 and not app.collection_screen.visible and not app.confirmation.visible, tag + ": Home Retry publication rejects reentrant navigation from the rebuilt Map screen signal.")
	check(run.snapshot().player_hp == before.player_hp + 4 and run.snapshot().player_max_hp == before.player_max_hp + 4 and run.snapshot().gold == before.gold - 90 and run.snapshot().relics.count("relic_heart_stone") == 1, tag + ": Heart Stone uses the shared health acquisition hook once for90 Gold.")
	var paid: Dictionary = run.export_save()
	app._store_purchase_requested(run.store_snapshot().identity, "relic", "relic_heart_stone")
	app.confirm_store_purchase()
	check(run.export_save() == paid and run.store_snapshot().relic_purchased, tag + ": duplicate Heart Stone cannot charge or increase health again.")
	await close_catalogue(app, tag)
	return true

func room_with_store(app: Control, tag: String, node: Dictionary) -> bool:
	var run = app.run_state
	if node.room_type == "shop":
		check(app.shop_screen != null and app.map_screen == null, tag + ": actual shop remains its own room destination.")
		if app.shop_screen == null: return false
		app._shop_menu_requested(app._generation)
		deny_store(app, tag + " active shop")
		app.route_menu_resume.pressed.emit()
		var record: Dictionary = run.shop_snapshot()
		var before: int = run.snapshot().owned_cards.size()
		app._purchase_shop_rune(record.identity, record.slots[0].slot_id)
		app._upgrade_shop_rune(record.identity, 0)
		app._purchase_shop_relic(record.identity, "relic-1")
		await settle()
		check(run.snapshot().owned_cards.size() == before + 1 and run.snapshot().owned_cards[0].upgrade_rank == 1, tag + ": shop purchase and individual upgrade remain independent of Store caps.")
		check(run.snapshot().relics.count("relic_heart_stone") == 1 and run.snapshot().player_max_hp == 34, tag + ": shop's distinct relic neither duplicates nor reapplies Store Heart Stone.")
		app.shop_screen.leave_button.pressed.emit()
		await settle()
		return app.shop_screen == null and app.map_screen != null
	check(app.service_screen != null, tag + ": real event/recovery opens.")
	if app.service_screen == null: return false
	app._service_menu_requested(app._generation)
	deny_store(app, tag + " active service")
	app.route_menu_resume.pressed.emit()
	var record: Dictionary = run.service_snapshot()
	var choice := "recover" if node.room_type == "recovery" else "take_gold" if record.definition_id == "event_lost_satchel" else "open_reliquary"
	app.service_screen.select_choice(choice)
	if choice == "open_reliquary": app.service_screen.select_relic(record.offered_relics[0])
	app.service_screen.confirm_choice()
	await settle()
	check(app.service_screen == null and app.map_screen != null, tag + ": actual service choice completes without Store access during its live visit.")
	return app.service_screen == null and app.map_screen != null
