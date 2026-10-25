extends SceneTree
## Complete nine-visit application journeys at actual configured root sizes.
## Every entry, outcome, purchase, service and reward uses the shipped shell.
const Manual = preload("res://tests/rc032_manual.gd")
const Fixture = preload("res://tests/helpers/rc032_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const DESTINATION := "res://output/qa/rc-032/route-shell"
var capturing := false
var checks := 0
var failures := 0
var assertions: Array = []
var traces: Array = []

func _initialize() -> void:
	capturing = "--capture-rc032-route" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": value, "description": message})
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 8: await process_frame
	if capturing: await RenderingServer.frame_post_draw

func capture(app: Control, name: String) -> void:
	await settle()
	var bounds := root.get_final_transform() * root.get_visible_rect()
	var panel: PanelContainer
	var actions: Array = []
	if app.run_review.visible:
		panel = app.run_review.panel
		actions = [app.run_review.primary_button, app.run_review.secondary_button]
	elif app.reward_screen.visible:
		panel = app.reward_screen.panel
		actions = [app.reward_screen.close_button]
	elif app.confirmation.visible:
		panel = app._confirmation_panel
		actions = [app.confirmation_confirm, app.confirmation_cancel]
	if panel != null:
		check(bounds.encloses(root.get_final_transform() * panel.get_global_rect()) and panel.size.y <= 660, name + ": popup fits actual window and shared 660 px cap.")
	for button in actions:
		check(button.is_visible_in_tree() and bounds.encloses(root.get_final_transform() * button.get_global_rect()), name + ": fixed action remains reachable: " + button.text)
	if capturing:
		check(root.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png")) == OK, name + ": actual root screenshot saved.")

func create_shell(path: String, context: Dictionary) -> Control:
	var app := Manual.ManualShell.new()
	app.settings_path = path + ".settings.cfg"
	app.save_path = path
	app.persistence_context = context
	if not FileAccess.file_exists(app.settings_path):
		var values := Settings.DEFAULTS.duplicate(true)
		values.reduced_motion = true
		values.sfx_volume = 0.37
		Settings.save_values(values, app.settings_path)
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.audio.trace_enabled = true
	return app

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	root.gui_embed_subwindows = true
	for dimensions in [Vector2i(450, 1000), Vector2i(360, 640)]:
		root.size = dimensions
		await settle()
		for branch in ["normal", "elite"]: await journey(dimensions, branch)
	await create_timer(0.3).timeout
	var suffix := "capture" if capturing else "headless"
	FileAccess.open(DESTINATION.path_join("results-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions, "scope": "Full nine visits through actual Home, Map confirmation, legal controller commands, durable shell outcomes/rewards/shop/service, guardian choices and final read-only review at real configured windows. Desktop only."}, "  ") + "\n")
	FileAccess.open(DESTINATION.path_join("legal-commands-" + suffix + ".json"), FileAccess.WRITE).store_string(JSON.stringify(traces, "  ") + "\n")
	print("RC-032 route shell: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func journey(dimensions: Vector2i, branch: String) -> void:
	var tag := "%s-%dx%d" % [branch, dimensions.x, dimensions.y]
	var path := DESTINATION.path_join(tag + "-" + str(Time.get_ticks_usec()) + ".json")
	var context := Fixture.context_for(Fixture.new_run())
	var app := create_shell(path, context)
	await settle()
	check(app.home.visible and app.run_state == null, tag + ": isolated launch starts at clean Home with no automatic run.")
	app.new_run_button.pressed.emit()
	await settle()
	check(app.run_state != null and app.map_screen != null and app.run_state.route_snapshot().visit_count == 0, tag + ": Home New Run durably creates unvisited Map.")
	if app.run_state == null or app.map_screen == null:
		app.queue_free()
		await settle()
		return
	var run = app.run_state
	for depth in range(1, 10):
		if app.map_screen == null:
			check(false, tag + ": Map is available before depth %d." % depth)
			break
		var node_id := Fixture.next_node(run, branch)
		var node: Dictionary = run.inspect_node(node_id)
		var before: Dictionary = run.export_save()
		app.map_screen.inspect_node(node_id)
		await settle()
		check(run.export_save() == before, tag + ": inspecting depth %d never enters the room." % depth)
		app.map_screen.inspection_action.pressed.emit()
		await settle()
		check(app.confirmation.visible and run.export_save() == before, tag + ": room entry requires explicit confirmation.")
		if depth == 1:
			app.cancel_confirmation()
			check(run.export_save() == before, tag + ": entry cancellation preserves the unvisited route.")
			app.request_node_entry(node_id)
		app.confirmation_confirm.pressed.emit()
		await settle()
		check(run.route_snapshot().visit_count == depth, tag + ": confirmed room entry commits exactly visit %d." % depth)
		if run.route_snapshot().visit_count != depth: break
		if node.room_type in ["normal", "elite", "guardian"]:
			if not await battle(app, tag, depth, node): break
			if depth == 9:
				await capture(app, "guardian-pending-" + tag)
				check(not run.snapshot().tower_completed and not run.snapshot().final_results_ready, tag + ": guardian defeat waits for required awards.")
				if branch == "elite":
					app.confirmation_confirm.pressed.emit()
					await settle()
					check(app.map_screen != null and run.snapshot().status == "pending_choices", tag + ": acknowledgement first opens pending-choice Map.")
					app.map_screen.details_requested.emit()
					await capture(app, "guardian-pending-details-" + tag)
					check(app.run_review.visible and app.run_review.secondary_button.text == "Review pending choices" and app._pending_abandon.is_empty(), tag + ": details redirects unresolved guardian awards and offers no abandonment.")
					app.run_review.secondary_button.pressed.emit()
					await settle()
					check(app.reward_screen.visible and not app.run_review.visible, tag + ": pending details action reaches retained reward choices.")
			if not await rewards(app, tag, depth): break
			if depth == 6: check(not run.snapshot().tower_completed and not app.run_review.visible, tag + ": Shadeling alone never produces final tower results.")
		else:
			if not await room(app, tag, node): break
		var loaded: Dictionary = app.save_store.load()
		check(loaded.ok and loaded.payload.run == run.export_save(), tag + ": durable shell checkpoint equals authoritative owners after depth %d." % depth)
	check(run.snapshot().final_results_ready and app.run_review.visible and app.run_review.final_review and app.map_screen == null and app.combat_scene == null, tag + ": completed run opens final review without a dead-end Map or live Combat.")
	if run.snapshot().final_results_ready:
		var summary: Dictionary = run.run_summary()
		check(summary.entered_rooms == 9 and summary.completed_rooms == 9 and summary.defeated_enemy_count == 6, tag + ": final UI summary counts all nine visits and six distinct victories.")
		check(summary.owned_cards.size() == 9 and summary.owned_cards.any(func(card): return card.uid == 0 and card.upgrade_rank == 1 and card.effect_summary.contains("8")), tag + ": purchased owned collection and effective upgraded Spark appear in summary.")
		check(summary.permanent_awards.size() == 2 and summary.relics.size() == (1 if branch == "normal" else 2), tag + ": final UI lists this run's two definition awards and actual relic receipts.")
		await capture(app, "final-results-top-" + tag)
		var owned_heading: Array = app.run_review._body.get_children().filter(func(child): return child is Label and child.text == "Final owned runes")
		if not owned_heading.is_empty(): app.run_review.body_scroll.scroll_vertical = roundi(owned_heading[0].position.y)
		await capture(app, "final-results-runes-" + tag)
		app.run_review.body_scroll.scroll_vertical = 99999
		await capture(app, "final-results-awards-" + tag)
		var immutable: Dictionary = run.export_save()
		check(not run.request_room_entry("d9").ok and not run.continue_battle().ok and not run.abandonment_request().ok and run.export_save() == immutable, tag + ": final gameplay/reclassification attempts are pure rejections.")
		app.run_review.secondary_button.pressed.emit()
		await settle()
		check(app.home.visible and not app.run_review.visible and run.snapshot().terminal.acknowledged, tag + ": explicit final Home durably acknowledges results without granting anything.")
		check(run.run_summary() == summary, tag + ": final Home acknowledgement leaves summary and awards unchanged.")
		var durable: Dictionary = run.export_save()
		app.queue_free()
		await settle()
		app = create_shell(path, context)
		await settle()
		check(app.run_state != null and app.run_state.export_save() == durable and app.run_state.run_summary() == summary, tag + ": reconstructed shell preserves exact terminal run, ranks/relics/profile and summary.")
		app.continue_button.pressed.emit()
		await settle()
		check(app.run_review.visible and app.run_review.final_review and app.combat_scene == null and app.map_screen == null, tag + ": Home Continue reopens read-only results after restart.")
		check(app.audio.trace.filter(func(event): return event.get("cue") == "reward").is_empty(), tag + ": terminal receipt restoration emits no reward audio.")
		check(is_equal_approx(float(app.audio_settings.sfx_volume), 0.37) and app.audio_settings.reduced_motion, tag + ": persisted shared Options survive final results and restart.")
	app.queue_free()
	await settle()

func battle(app: Control, tag: String, depth: int, node: Dictionary) -> bool:
	check(app.combat_scene != null and app.map_screen == null, tag + ": battle entry owns the main screen at depth %d." % depth)
	if app.combat_scene == null: return false
	var controller = app.combat_scene.controller
	var game = app.combat_scene.battle_model
	controller.set_presenter(Immediate.new())
	var commands: Array = []
	controller.command_resolved.connect(func(outcome):
		var current: Dictionary = game.snapshot()
		commands.append({"command": outcome.command, "arguments": outcome.arguments, "accepted": outcome.accepted,
			"turn": current.turn, "state": current.state, "player_hp": current.player_hp, "enemy_hp": current.enemy_hp}))
	var player := Player.new()
	for turn in range(60):
		if controller.snapshot().state != "playing": break
		if not player.play_turn(controller):
			check(false, tag + ": legal player could not execute at depth %d." % depth)
			return false
	await settle()
	traces.append({"variant": tag, "visit": depth, "node": node.id, "enemy": node.enemy_id, "commands": commands})
	check(not commands.is_empty() and commands.all(func(command): return command.accepted) and commands.any(func(command): return command.command == "cast"), tag + ": trace proves accepted legal techniques/placement/rotation/casts at depth %d." % depth)
	check(app.run_state.snapshot().pending_result.get("outcome") == "victory" and app.confirmation.visible, tag + ": actual victory is durably committed before rewards at depth %d." % depth)
	return app.run_state.snapshot().pending_result.get("outcome") == "victory"

func rewards(app: Control, tag: String, depth: int) -> bool:
	if not app.reward_screen.visible: app.open_rewards()
	await settle()
	for step in range(6):
		var pending: Dictionary = app.run_state.pending_reward()
		if pending.is_empty(): break
		if not app.reward_screen.visible:
			check(false, tag + ": pending reward viewer remains reachable.")
			return false
		if not pending.gold_claimed:
			app.reward_screen.gold_button.pressed.emit()
		elif pending.resolution == "pending":
			if pending.kind == "definition_unlock":
				app.reward_screen.choose_buttons[pending.offered_ids[0]].pressed.emit()
			else: app.reward_screen.skip_button.pressed.emit()
		await settle()
	check(app.run_state.pending_reward().is_empty(), tag + ": all real required reward components resolve at depth %d." % depth)
	if not app.run_state.pending_reward().is_empty(): return false
	app.reward_screen.close_button.pressed.emit()
	await settle()
	if not app.run_state.snapshot().pending_result.is_empty():
		check(app.confirmation.visible, tag + ": committed battle outcome still needs independent acknowledgement.")
		app.confirmation_confirm.pressed.emit()
		await settle()
	return true

func room(app: Control, tag: String, node: Dictionary) -> bool:
	if node.room_type == "shop":
		check(app.shop_screen != null and app.map_screen == null, tag + ": shop becomes the main screen on entry.")
		if app.shop_screen == null: return false
		var shop: Dictionary = app.run_state.shop_snapshot()
		app._purchase_shop_rune(shop.identity, shop.slots[0].slot_id)
		app._upgrade_shop_rune(shop.identity, 0)
		app._purchase_shop_relic(shop.identity, "relic-1")
		await settle()
		check(app.run_state.snapshot().owned_cards.size() == 9 and app.run_state.snapshot().owned_cards[0].upgrade_rank == 1, tag + ": actual paid purchase and exact-UID upgrade commit through shell saves.")
		app.shop_screen.leave_button.pressed.emit()
		await settle()
		return app.shop_screen == null and app.map_screen != null
	check(app.service_screen != null and app.map_screen == null, tag + ": event/recovery becomes the main screen on entry.")
	if app.service_screen == null: return false
	var record: Dictionary = app.run_state.service_snapshot()
	var choice := "recover" if node.room_type == "recovery" else "take_gold" if record.definition_id == "event_lost_satchel" else "open_reliquary"
	app.service_screen.select_choice(choice)
	if choice == "open_reliquary": app.service_screen.select_relic(record.offered_relics[0])
	app.service_screen.confirm_choice()
	await settle()
	check(app.service_screen == null and app.map_screen != null, tag + ": explicit service choice commits its receipt and completes the room.")
	return app.service_screen == null and app.map_screen != null
