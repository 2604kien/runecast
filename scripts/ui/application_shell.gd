extends Control
## Gameplay owner. Durable checkpoints use the explicit model save contracts.
const RunState = preload("res://scripts/core/run_state.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const CombatScene = preload("res://scenes/main.tscn")
const Ui = preload("res://scenes/ui/theme/components.gd")
const AudioOptions = preload("res://scripts/ui/audio_options.gd")
const AudioSettings = preload("res://scripts/audio/audio_settings.gd")
const AudioCoordinator = preload("res://scripts/audio/audio_coordinator.gd")
const TouchRouter = preload("res://scripts/ui/touch_router.gd")
const RouteMap = preload("res://scripts/ui/route_map.gd")
const CollectionViewer = preload("res://scripts/ui/collection_viewer.gd")
const RewardViewer = preload("res://scripts/ui/reward_viewer.gd")
const ShopViewer = preload("res://scripts/ui/shop_viewer.gd")
const StoreViewer = preload("res://scripts/ui/store_viewer.gd")
const ServiceViewer = preload("res://scripts/ui/service_viewer.gd")
const RunReview = preload("res://scripts/ui/run_review.gd")
const ProgressionState = preload("res://scripts/core/progression_state.gd")
const LocalSave = preload("res://scripts/core/local_save.gd")

signal screen_changed(screen: String)
var settings_path := AudioSettings.DEFAULT_PATH
var save_path := "user://runecast-save.json"
# Only isolated harnesses inject trusted fixture registries. Save data cannot
# supply paths, callbacks, fixture policies or executable resources.
var persistence_context: Dictionary = {}
var save_store: RefCounted
var run_state: RunState
var combat_scene: Control
var map_screen: Control
var home: Control
var new_run_button: Button
var continue_button: Button
var options_button: Button
var recovery_button: Button
var recovery_retry_button: Button
var options: AudioOptions
var confirmation: Control
var confirmation_text: Label
var confirmation_confirm: Button
var confirmation_cancel: Button
var route_menu: Control
var route_menu_resume: Button
var route_menu_options: Button
var route_menu_store: Button
var route_menu_quit: Button
var route_menu_collection: Button
var result_reward_button: Button
var collection_screen: Control
var reward_screen: Control
var shop_screen: Control
var store_screen: Control
var service_screen: Control
var run_review: Control
var progression: RefCounted
var audio: Node
var audio_settings: Dictionary = {}
var startup_error := ""
var _tower: TextureRect
var _logo: TextureRect
var _actions: VBoxContainer
var _confirmation_panel: PanelContainer
var _confirmation_title: Label
var _route_menu_panel: PanelContainer
var _route_menu_generation := -1
var _route_menu_origin := ""
var _gestures: Node
var _pending_action := ""
var _pending_seed := -1
var _transitioning := false
var _closed := false
var _generation := 0
var _last_back_frame := -1
var _audio_dispatch := 0
var _battle_changed_callback: Callable
var _battle_home_callback: Callable
var _battle_map_callback: Callable
var _battle_menu_callback: Callable
var _battle_collection_callback: Callable
var _pending_entry: Dictionary = {}
var _entry_generation := -1
var _map_generation := 0
var _development := false
var _pending_result_identity: Dictionary = {}
var _save_revision := 0
var _save_status := "empty"
var _recovery_available := false
var _failed_transaction: Dictionary = {}
var _trusted_fixture_contexts: Array = []
var _review_generation := 0
var _pending_abandon: Dictionary = {}
var _pending_store: Dictionary = {}

func _ready() -> void:
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Existing harnesses deliberately launch Combat. Keep their exact interface,
	# including --capture, and do not route them through run state or Home.
	for argument in OS.get_cmdline_user_args():
		if argument == "--experiment" or argument == "--capture" or argument.begins_with("--encounter=") or argument.begins_with("--board-example="):
			_development = true
	if _development:
		combat_scene = CombatScene.instantiate()
		combat_scene.settings_path = settings_path
		add_child(combat_scene)
		return
	_build_home()
	_build_confirmation()
	_build_route_menu()
	collection_screen = CollectionViewer.new()
	add_child(collection_screen)
	collection_screen.close_requested.connect(close_collection)
	reward_screen = RewardViewer.new()
	add_child(reward_screen)
	reward_screen.close_requested.connect(close_rewards)
	reward_screen.choose_requested.connect(_choose_reward)
	reward_screen.skip_requested.connect(_skip_reward)
	reward_screen.gold_requested.connect(_claim_reward_gold)
	run_review = RunReview.new()
	add_child(run_review)
	run_review.action_requested.connect(_review_action)
	store_screen = StoreViewer.new()
	add_child(store_screen)
	store_screen.purchase_requested.connect(_store_purchase_requested)
	store_screen.close_requested.connect(close_store)
	options = AudioOptions.new()
	add_child(options)
	options.setting_changed.connect(_change_option)
	options.close_requested.connect(close_options)
	_gestures = TouchRouter.new()
	_gestures.mobile_only = true
	add_child(_gestures)
	for button in [continue_button, new_run_button, options_button, recovery_button, recovery_retry_button, confirmation_confirm, confirmation_cancel,
		route_menu_resume, route_menu_options, route_menu_quit, route_menu_collection, route_menu_store, result_reward_button]:
		_gestures.register_target(button, button.pressed.emit)
	_gestures.register_scroll(_confirmation_panel.get_meta("rc_body_scroll"))
	_gestures.register_scroll(_route_menu_panel.get_meta("rc_body_scroll"))
	options.register_gestures(_gestures)
	collection_screen.register_gestures(_gestures)
	reward_screen.register_gestures(_gestures)
	run_review.register_gestures(_gestures)
	store_screen.register_gestures(_gestures)
	_apply_touch_policy(self)
	_load_settings()
	_load_persistence()
	_start_home_audio()
	_refresh_home()
	resized.connect(_fit_home)
	get_viewport().size_changed.connect(func():
		_fit_route_menu.call_deferred()
		_fit_confirmation.call_deferred()
	)
	_fit_home()

func _build_home() -> void:
	home = Control.new()
	home.name = "Home"
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tower = TextureRect.new()
	_tower.texture = preload("res://assets/environments/home/home_tower.png")
	_tower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(_tower)
	_tower.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo = TextureRect.new()
	_logo.texture = preload("res://assets/ui/wordmark.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(_logo)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 12)
	home.add_child(_actions)
	continue_button = Ui.menu_action("Continue", true, Vector2(0, 64))
	new_run_button = Ui.menu_action("New Run", false, Vector2(0, 64))
	options_button = Ui.menu_action("Options", false, Vector2(0, 64))
	recovery_button = Ui.menu_action("Save recovery", false, Vector2(0, 64))
	for button in [continue_button, new_run_button, options_button, recovery_button]: _actions.add_child(button)
	continue_button.pressed.connect(continue_run)
	new_run_button.pressed.connect(request_new_run)
	options_button.pressed.connect(open_options)
	recovery_button.pressed.connect(open_save_recovery)
	recovery_button.hide()

func _build_confirmation() -> void:
	confirmation = Control.new()
	confirmation.name = "Confirmation"
	confirmation.z_index = 120
	confirmation.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirmation)
	confirmation.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.9)
	confirmation.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmation_panel = Ui.modal("New Run", "", 280, 340, "Replace session")
	confirmation.add_child(_confirmation_panel)
	# Hidden, unlaid-out labels briefly measure at one pixel wide. Refit after
	# wrapping settles so that transient text minima cannot stretch the modal.
	_confirmation_panel.minimum_size_changed.connect(func(): _fit_confirmation.call_deferred())
	_confirmation_title = _confirmation_panel.get_child(0).get_child(0)
	confirmation_text = _confirmation_panel.get_meta("rc_body_scroll").get_child(0)
	confirmation_confirm = _confirmation_panel.get_meta("rc_confirm")
	confirmation_cancel = _confirmation_panel.get_meta("rc_close")
	confirmation_cancel.text = "Cancel"
	confirmation_confirm.pressed.connect(_confirm_pending)
	confirmation_cancel.pressed.connect(cancel_confirmation)
	result_reward_button = Ui.menu_action("Review rewards", true, Vector2(0, 52))
	confirmation_confirm.get_parent().add_child(result_reward_button)
	confirmation_confirm.get_parent().move_child(result_reward_button, 0)
	result_reward_button.pressed.connect(open_rewards)
	result_reward_button.hide()
	recovery_retry_button = Ui.menu_action("Retry loading", false, Vector2(0, 52))
	confirmation_confirm.get_parent().add_child(recovery_retry_button)
	recovery_retry_button.pressed.connect(retry_load_save)
	recovery_retry_button.hide()
	Ui.prepare_popup_content(_confirmation_panel)
	confirmation.hide()

func _apply_touch_policy(node: Node) -> void:
	if node is Control: node.focus_mode = Control.FOCUS_NONE
	if node is BaseButton: node.shortcut = null
	for child in node.get_children(): _apply_touch_policy(child)

func _build_route_menu() -> void:
	route_menu = Control.new()
	route_menu.name = "RouteMenu"
	route_menu.z_index = 105
	route_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(route_menu)
	route_menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.88)
	route_menu.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_route_menu_panel = Ui.modal("Menu", "Resume keeps this battle unchanged. Quit to Home discards battle progress; Continue replays its entry.", 280, 430, "Resume Combat")
	route_menu.add_child(_route_menu_panel)
	route_menu_resume = _route_menu_panel.get_meta("rc_confirm")
	route_menu_quit = _route_menu_panel.get_meta("rc_close")
	route_menu_quit.text = "Quit to Home"
	var footer: Control = route_menu_resume.get_parent()
	route_menu_options = Ui.menu_action("Options", false, Vector2(0, 52))
	route_menu_store = Ui.menu_action("Store", false, Vector2(0, 52))
	Ui.apply_states(route_menu_store, {"unavailable": true})
	footer.add_child(route_menu_options)
	footer.add_child(route_menu_store)
	footer.move_child(route_menu_options, 1)
	footer.move_child(route_menu_store, 2)
	route_menu_collection = Ui.menu_action("Collection", false, Vector2(0, 52))
	footer.add_child(route_menu_collection)
	footer.move_child(route_menu_collection, 2)
	route_menu_collection.pressed.connect(open_collection)
	footer.add_theme_constant_override("separation", 14)
	for button in [route_menu_resume, route_menu_options, route_menu_collection, route_menu_store, route_menu_quit]:
		button.custom_minimum_size.y = 68
	route_menu_resume.pressed.connect(_close_route_menu)
	route_menu_options.pressed.connect(open_options)
	route_menu_store.pressed.connect(open_store)
	route_menu_quit.pressed.connect(_route_menu_home)
	_route_menu_panel.minimum_size_changed.connect(func(): _fit_route_menu.call_deferred())
	Ui.prepare_popup_content(_route_menu_panel)
	route_menu.hide()

func _fit_route_menu() -> void:
	if _closed or _route_menu_panel == null: return
	Ui.fit_popup_overlay(route_menu, _route_menu_panel, Vector2(560, 660), Vector2(280, 430))

func _fit_home() -> void:
	if home == null: return
	var scale_factor := clampf(size.x / 720.0, 0.55, 1.0)
	var width := minf(440.0, size.x - 48.0)
	_logo.size = Vector2(minf(size.x * 0.85, 612.0), minf(size.x * 0.32, 230.0))
	_logo.position = Vector2((size.x - _logo.size.x) / 2.0, maxf(8.0, size.y * 0.018))
	_actions.add_theme_constant_override("separation", maxi(8, int(14 * scale_factor)))
	for button in [continue_button, new_run_button, options_button, recovery_button]:
		button.custom_minimum_size.y = maxf(50.0, 82.0 * scale_factor)
		button.add_theme_font_size_override("font_size", maxi(20, int(30 * scale_factor)))
	_actions.size.x = width
	_actions.size.y = _actions.get_combined_minimum_size().y
	_actions.position = Vector2((size.x - width) / 2.0, maxf(_logo.position.y + _logo.size.y, size.y - _actions.size.y - maxf(20.0, size.y * 0.035)))
	_fit_confirmation()
	_fit_route_menu()

func _fit_confirmation() -> void:
	if _closed or _confirmation_panel == null: return
	Ui.fit_popup_overlay(confirmation, _confirmation_panel, Vector2(560, 480))

func _restore_save_payload(payload: Dictionary) -> Dictionary:
	if payload.keys().size() != 2 or not payload.get("profile") is Dictionary or not payload.get("run") is Dictionary:
		return {"ok": false, "error": "The saved profile/run envelope is malformed."}
	var loaded: Dictionary = ContentLoader.load_setup()
	if not loaded.ok: return {"ok": false, "error": "Saved content is unavailable: " + "; ".join(loaded.errors)}
	var restored_profile: Dictionary = ProgressionState.restore_save(payload.profile, loaded.setup.catalog, bool(persistence_context.get("allow_test_fixtures", false)))
	if not restored_profile.ok: return restored_profile
	var restored_run: Variant = null
	if not payload.run.is_empty():
		var restored: Dictionary = RunState.restore_save(payload.run, loaded.setup, restored_profile.profile)
		# Explicit test callers can replace their fixture mid-suite. Keep earlier
		# trusted registries so its validated previous copy stays recoverable.
		if not persistence_context.is_empty() and not persistence_context in _trusted_fixture_contexts:
			_trusted_fixture_contexts.append(persistence_context.duplicate(true))
		if not restored.ok:
			for context in _trusted_fixture_contexts:
				restored = RunState.restore_save(payload.run, loaded.setup, restored_profile.profile, context)
				if restored.ok: break
		if not restored.ok: return restored
		restored_run = restored.run
	return {"ok": true, "error": "", "profile": restored_profile.profile, "run": restored_run,
		"migrated": not payload.run.is_empty() and int(payload.run.get("version", 1)) < RunState.SAVE_VERSION}

func _load_persistence() -> void:
	if save_store == null: save_store = LocalSave.new(save_path, _restore_save_payload)
	_accept_loaded_save(save_store.load())

func _accept_loaded_save(loaded: Dictionary) -> void:
	_save_status = str(loaded.get("status", "invalid"))
	_recovery_available = bool(loaded.get("recovery_available", false))
	if not loaded.get("ok", false):
		startup_error = "Saved progress could not be opened.\n" + str(loaded.get("error", "Unknown save error."))
		return
	_save_revision = int(loaded.get("revision", 0))
	if _save_status == "empty":
		run_state = null
		progression = null
		startup_error = ""
		return
	var restored := _restore_save_payload(loaded.payload)
	if not restored.ok:
		_save_status = "invalid"
		startup_error = "Saved progress could not be restored.\n" + str(restored.error)
		return
	if restored.get("migrated", false) and restored.run != null:
		_transitioning = true
		_commit_transaction(restored.run, "migrate")
		return
	run_state = restored.run
	progression = restored.profile
	startup_error = ""
	_generation += 1

func open_save_recovery() -> void:
	if _closed or _transitioning or _save_status != "invalid" or confirmation.visible or options.visible or combat_scene != null or map_screen != null: return
	var explanation := startup_error + "\n\nThe original file is preserved. New Run is unavailable until this save is recovered or repaired."
	explanation += "\n\nA validated previous copy is available. Recovering preserves the unreadable original for diagnosis." if _recovery_available else "\n\nNo validated previous copy is available. Correct or restore the file externally, then Retry loading."
	_show_confirmation("recover_save", "Saved progress needs attention", explanation, "Recover previous save" if _recovery_available else "Retry loading", false)
	confirmation_cancel.text = "Return Home"
	recovery_retry_button.visible = _recovery_available
	_fit_confirmation.call_deferred()

func retry_load_save() -> void:
	if _closed or _transitioning: return
	if not _failed_transaction.is_empty():
		# Explicitly choosing Reload abandons only the uncommitted intent. The
		# current file is validated before any restored owner is published.
		_transitioning = true
		var loaded: Dictionary = save_store.load()
		_return_home()
		_failed_transaction.clear()
		_accept_loaded_save(loaded)
		if _failed_transaction.is_empty(): _dismiss_confirmation()
		_transitioning = false
		_refresh_home()
		if _save_status == "invalid": open_save_recovery()
		return
	if combat_scene != null or map_screen != null: return
	_transitioning = true
	_load_persistence()
	if _failed_transaction.is_empty(): _dismiss_confirmation()
	_transitioning = false
	_refresh_home()
	if _save_status == "invalid": open_save_recovery()

func recover_previous_save() -> void:
	if _closed or _transitioning or _pending_action != "recover_save" or not confirmation.visible: return
	if not _recovery_available:
		retry_load_save()
		return
	_transitioning = true
	_accept_loaded_save(save_store.recover_previous())
	if _failed_transaction.is_empty(): _dismiss_confirmation()
	_transitioning = false
	_refresh_home()
	if _save_status == "invalid": open_save_recovery()

func _persist_candidate(candidate: RunState) -> Dictionary:
	if save_store == null or _save_status == "invalid": return {"ok": false, "error": "Recover the existing save before changing progress."}
	var candidate_profile: RefCounted = candidate.profile_state()
	if candidate_profile == null: return {"ok": false, "error": "This run has no persistent definition profile."}
	var payload := {"profile": candidate_profile.export_save(), "run": candidate.export_save()}
	var saved: Dictionary = save_store.commit(payload, _save_revision)
	if saved.get("ok", false):
		_save_revision = int(saved.revision)
		_save_status = "valid"
		startup_error = ""
	return saved

func _stage_current() -> Dictionary:
	if run_state == null: return {"ok": false, "error": "There is no active run."}
	return run_state.clone_for_transaction()

# Every fallible gameplay operation works on a detached candidate. The file
# commit precedes publication to any run/profile owner or success feedback.
func _commit_transaction(candidate: RunState, action: String, details: Dictionary = {}) -> bool:
	var saved := _persist_candidate(candidate)
	if not saved.get("ok", false):
		if details.get("scene") != null:
			_dispose_candidate_scene(details.scene)
			details.erase("scene")
		_failed_transaction = {"candidate": candidate, "action": action, "details": details.duplicate(true), "revision": _save_revision,
			"run_id": run_state.snapshot().run_id if run_state != null else "", "error": str(saved.get("error", "The save could not be committed."))}
		_transitioning = false
		_show_save_failure()
		return false
	_publish_transaction(candidate, action, details)
	return true

func _show_save_failure() -> void:
	if _failed_transaction.is_empty(): return
	if reward_screen.visible: reward_screen.hide()
	if combat_scene != null: combat_scene.set_shell_modal(true)
	if map_screen != null: map_screen.set_blocked(true)
	if service_screen != null: service_screen.set_blocked(true)
	if store_screen.visible: store_screen.set_blocked(true)
	_show_confirmation("retry_save", "Progress was not saved", str(_failed_transaction.error) + "\n\nExisting saved progress is preserved. Retry saves this same intended action; it does not draw a new offer or grant it twice. Reload abandons this unsaved action and opens the committed file. Closing the application keeps only saved progress.", "Retry saving", false)
	confirmation_cancel.text = "Return Home"
	recovery_retry_button.text = "Reload saved progress"
	recovery_retry_button.show()
	_fit_confirmation.call_deferred()

func retry_save() -> void:
	if _closed or _transitioning or _failed_transaction.is_empty(): return
	var pending := _failed_transaction
	if pending.revision != _save_revision or pending.run_id != (run_state.snapshot().run_id if run_state != null else ""):
		pending.error = "This pending action no longer owns the current save. Return Home and reload saved progress."
		_show_save_failure()
		return
	_transitioning = true
	var details: Dictionary = pending.details.duplicate(true)
	if pending.action in ["entry", "continue"]:
		var attached := _prepare_battle_scene(pending.candidate.current_battle(), details.get("setup", {}))
		if not attached.ok:
			pending.error = attached.error
			_transitioning = false
			_show_save_failure()
			return
		details.scene = attached.scene
	elif pending.action == "shop_entry":
		var attached := _prepare_shop_scene(pending.candidate.shop_snapshot())
		if not attached.ok:
			pending.error = attached.error
			_transitioning = false
			_show_save_failure()
			return
		details.scene = attached.scene
	elif pending.action == "service_entry":
		var attached := _prepare_service_scene(pending.candidate.service_snapshot())
		if not attached.ok:
			pending.error = attached.error
			_transitioning = false
			_show_save_failure()
			return
		details.scene = attached.scene
	_commit_transaction(pending.candidate, str(pending.action), details)

func _publish_transaction(candidate: RunState, action: String, details: Dictionary) -> void:
	_failed_transaction.clear()
	if action in ["new_run", "migrate"]:
		candidate.publish_profile_owner(progression)
		run_state = candidate
	else: run_state.publish_transaction(candidate)
	progression = run_state.profile_state()
	match action:
		"migrate":
			_generation += 1
			_dismiss_confirmation()
			_transitioning = false
			_refresh_home()
		"new_run":
			_close_run_review()
			_discard_map()
			_detach_battle()
			_detach_shop()
			_detach_service()
			_generation += 1
			_dismiss_confirmation()
			_transitioning = false
			open_map()
		"entry", "continue":
			_discard_map()
			_dismiss_confirmation()
			_activate_battle_scene(details.scene)
			_transitioning = false
		"shop_entry":
			_discard_map()
			_dismiss_confirmation()
			_activate_shop_scene(details.scene)
			_transitioning = false
		"service_entry":
			_discard_map()
			_dismiss_confirmation()
			_activate_service_scene(details.scene)
			_transitioning = false
		"service_resolve":
			_dismiss_confirmation()
			_detach_service()
			home.show()
			# A committed choice cues only once; reopening a saved room is silent.
			_feedback("ui_confirm")
			_transitioning = false
			open_map()
		"shop_purchase", "shop_remove", "shop_upgrade", "shop_relic":
			_dismiss_confirmation()
			if shop_screen == null:
				var attached := _prepare_shop_scene(run_state.shop_snapshot())
				if attached.ok: _activate_shop_scene(attached.scene)
				else: _show_shop_open_failure()
			else:
				shop_screen.present(run_state.shop_snapshot(), _collection_catalog())
				shop_screen.set_blocked(false)
			if action == "shop_purchase" and audio != null:
				audio.reward_committed(str(details.receipt.get("transaction_id", "")), details.receipt)
			elif action in ["shop_remove", "shop_upgrade", "shop_relic"]: _feedback("ui_confirm")
			_transitioning = false
			_restore_overlay_caller()
		"shop_leave":
			_dismiss_confirmation()
			_detach_shop()
			home.show()
			_transitioning = false
			open_map()
		"store_purchase":
			_dismiss_confirmation()
			# Retry may be reached from Home after a failed purchase. Rebuild the
			# same between-room navigation only after its candidate is durable.
			if map_screen == null: _present_map()
			if not route_menu.visible: _open_route_menu("map", _map_generation, false)
			store_screen.present(run_state.store_snapshot(), _collection_catalog())
			if map_screen != null: map_screen.set_snapshot(run_state.snapshot())
			_update_route_menu_actions()
			if not details.receipt.get("granted_card", {}).is_empty() and audio != null:
				audio.reward_committed(str(details.receipt.get("transaction_id", "")), details.receipt)
			else: _feedback("ui_confirm")
			_transitioning = false
			_restore_overlay_caller()
		"outcome":
			var owner: Node = combat_scene.audio if combat_scene != null else audio
			if owner != null: owner.result_committed(details.get("identity", {}), str(details.get("outcome", "")))
			_dismiss_confirmation()
			_transitioning = false
			if run_state.snapshot().status == "result_pending": _show_encounter_result()
		"reward":
			_dismiss_confirmation()
			var receipt: Dictionary = details.receipt
			var owner: Node = combat_scene.audio if combat_scene != null else audio
			if owner != null: owner.reward_committed(str(receipt.get("transaction_id", "")), receipt)
			var record: Dictionary = run_state.reward_snapshot(details.identity)
			if record.get("status") == "resolved":
				var next: Dictionary = run_state.pending_reward()
				if not next.is_empty(): record = next
			_transitioning = false
			if details.get("result_open", false): _show_encounter_result()
			reward_screen.present(_reward_display_record(record), _collection_catalog())
			_gestures.process_mode = Node.PROCESS_MODE_INHERIT
			_gestures.set_modal(reward_screen)
			_transitioning = false
			_refresh_home()
		"acknowledge":
			_detach_battle()
			_dismiss_confirmation()
			_load_settings()
			_start_home_audio()
			home.show()
			_refresh_home()
			_transitioning = false
			if run_state.snapshot().get("final_results_ready", false): _show_final_results()
			else: open_map()
		"home", "final_home", "abandon":
			_return_home()
			_transitioning = false
		_:
			_transitioning = false
			_refresh_home()

func _refresh_home() -> void:
	var state := run_state.snapshot() if run_state != null else {}
	var final_ready := bool(state.get("final_results_ready", false))
	var can_continue := not state.is_empty() and (bool(state.can_continue) or final_ready)
	continue_button.text = "Retry saving" if not _failed_transaction.is_empty() else "View results" if final_ready else "Continue"
	Ui.apply_states(continue_button, {"unavailable": _save_status == "invalid" or (not can_continue and _failed_transaction.is_empty())})
	Ui.apply_states(new_run_button, {"unavailable": _save_status == "invalid" or not _failed_transaction.is_empty()})
	recovery_button.visible = _save_status == "invalid"
	_fit_home.call_deferred()

func request_new_run(seed: int = -1) -> void:
	if _closed or _transitioning or combat_scene != null or shop_screen != null or service_screen != null or map_screen != null or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible: return
	if _save_status == "invalid" or not _failed_transaction.is_empty(): return
	if run_review.visible and not run_review.final_review: return
	_pending_seed = seed
	if run_state != null:
		_show_confirmation("new_run", "Replace this saved run?", "Starting a New Run replaces this run and its battle-entry checkpoint after the replacement is saved successfully. Cancel keeps the current run unchanged.\n\nPermanent rune unlocks and Options are retained.", "Replace run")
	else:
		_start_new_run()

func confirm_new_run() -> void:
	if _pending_action != "new_run" or not confirmation.visible or _closed or _transitioning or collection_screen.visible or reward_screen.visible: return
	_start_new_run()

func _start_new_run() -> void:
	if _closed or _transitioning or combat_scene != null: return
	_transitioning = true
	var loaded: Dictionary = ContentLoader.load_setup()
	if not loaded.ok:
		startup_error = "Cannot start run.\n" + "\n".join(loaded.errors)
		_transitioning = false
		_dismiss_confirmation()
		_refresh_home()
		return
	var selected_seed := _pending_seed
	if selected_seed < 0:
		var seed_source := RandomNumberGenerator.new()
		seed_source.randomize()
		selected_seed = seed_source.randi_range(0, 2147483647)
	var candidate_profile: RefCounted = progression.clone_for_transaction() if progression != null else ProgressionState.new(loaded.setup.catalog)
	var replacement := RunState.new(loaded.setup, selected_seed, true, Callable(), null, ProgressionState.production_rules(), candidate_profile)
	if replacement.snapshot().status == "invalid":
		startup_error = "Cannot start run. " + str(replacement.snapshot().error)
		_transitioning = false
		_dismiss_confirmation()
		_refresh_home()
		return
	# Build and durably save the replacement before releasing the prior run.
	_commit_transaction(replacement, "new_run")

func continue_run() -> void:
	if _closed or _transitioning or combat_scene != null or shop_screen != null or service_screen != null or map_screen != null or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or run_review.visible: return
	if not _failed_transaction.is_empty():
		retry_save()
		return
	if run_state == null or _save_status == "invalid": return
	if run_state.snapshot().get("final_results_ready", false):
		_show_final_results()
		return
	if not run_state.snapshot().can_continue: return
	var state := run_state.snapshot()
	if state.get("mode", "") == "route":
		if state.status == "room_active" and not run_state.shop_snapshot().is_empty():
			_open_saved_shop()
		elif state.status == "room_active" and not run_state.service_snapshot().is_empty():
			_open_saved_service()
		elif state.status == "result_pending":
			_show_encounter_result()
		elif state.status in ["battle", "replay_pending"]:
			_continue_route_battle()
		else:
			open_map()
			if state.status == "pending_choices": open_rewards()
		return
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		_transitioning = false
		return
	var entered: Dictionary = staged.run.continue_battle()
	if entered.ok:
		var attached := _prepare_battle_scene(entered.combat)
		if attached.ok:
			_commit_transaction(staged.run, "continue", {"scene": attached.scene})
			return
		entered = attached
	else:
		startup_error = "Cannot continue this saved run. " + str(entered.get("error", ""))
	_refresh_home()
	_transitioning = false

func _create_battle_scene() -> Control:
	return CombatScene.instantiate()

# A hidden real scene is attached before the route visit is committed. Its
# controller/presenter/resources are ready, while audio and input remain inert.
func _prepare_battle_scene(model, setup: Dictionary = {}) -> Dictionary:
	var candidate := _create_battle_scene()
	if candidate == null:
		return {"ok": false, "error": "The Combat scene could not be constructed.", "scene": null}
	if candidate.is_queued_for_deletion() or candidate.get_parent() != null or not candidate.has_method("activate_entry") or not candidate.has_method("prepare_for_exit"):
		candidate.queue_free()
		return {"ok": false, "error": "The Combat scene resources are incompatible. Your route choice has not been consumed.", "scene": null}
	candidate.battle_model = model
	candidate.run_managed = true
	candidate.entry_setup = setup.duplicate(true)
	candidate.entry_prepared = true
	candidate.setup_path = ContentLoader.DEFAULT_ENCOUNTER
	candidate.settings_path = settings_path
	candidate.hide()
	add_child(candidate)
	if candidate.is_queued_for_deletion() or candidate.get_parent() != self or not candidate.is_inside_tree() or not candidate.is_node_ready() or candidate.controller == null or not candidate.startup_error.is_empty() or candidate.battle_model != model:
		_dispose_candidate_scene(candidate)
		return {"ok": false, "error": "The Combat scene could not be attached. Your route choice has not been consumed.", "scene": null}
	if candidate.audio != null: candidate.audio.defer_terminal_results = true
	return {"ok": true, "error": "", "scene": candidate}

func _dispose_candidate_scene(candidate: Control) -> void:
	if candidate == null or not is_instance_valid(candidate): return
	candidate.prepare_for_exit()
	if candidate.get_parent() != null: candidate.get_parent().remove_child(candidate)
	candidate.queue_free()

func _attach_battle(model, setup: Dictionary = {}) -> bool:
	var prepared := _prepare_battle_scene(model, setup)
	if not prepared.ok: return false
	_activate_battle_scene(prepared.scene)
	return true

func _activate_battle_scene(candidate: Control) -> void:
	_generation += 1
	_stop_home_audio()
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	home.hide()
	combat_scene = candidate
	combat_scene.show()
	combat_scene.activate_entry()
	if combat_scene.audio != null: combat_scene.audio.defer_terminal_results = true
	# Keep application overlays above the injected scene.
	move_child(confirmation, -1)
	move_child(options, -1)
	_battle_changed_callback = _battle_changed.bind(_generation)
	_battle_home_callback = _battle_home_requested.bind(_generation)
	_battle_map_callback = _battle_map_requested.bind(_generation)
	_battle_menu_callback = _battle_menu_requested.bind(_generation)
	_battle_collection_callback = _battle_collection_requested.bind(_generation)
	combat_scene.controller.changed.connect(_battle_changed_callback)
	combat_scene.home_requested.connect(_battle_home_callback)
	combat_scene.map_requested.connect(_battle_map_callback)
	combat_scene.menu_requested.connect(_battle_menu_callback)
	combat_scene.collection_requested.connect(_battle_collection_callback)
	screen_changed.emit("combat")

func _continue_route_battle() -> void:
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		startup_error = "Cannot restore this saved run. " + str(staged.error)
		_refresh_home()
		_transitioning = false
		return
	var prepared: Dictionary = staged.run.prepare_continue_battle()
	var candidate: Dictionary = prepared
	var scene: Control
	if prepared.ok:
		var attached := _prepare_battle_scene(prepared.combat, prepared.setup)
		if attached.ok:
			scene = attached.scene
			var committed: Dictionary = staged.run.commit_continue_battle(prepared)
			if committed.ok:
				_commit_transaction(staged.run, "continue", {"scene": scene, "setup": prepared.setup})
				return
			else:
				_dispose_candidate_scene(scene)
				prepared = committed
		else:
			prepared = attached
	if not prepared.ok:
		staged.run.cancel_prepared_battle(candidate)
		startup_error = "Cannot continue this saved run. " + str(prepared.get("error", ""))
		_refresh_home()
	_transitioning = false

func _battle_map_requested(token: int) -> void:
	if token == _generation: open_map()

func _battle_collection_requested(token: int) -> void:
	if token == _generation: open_collection()

func _battle_menu_requested(feedback: bool, token: int) -> void:
	if token != _generation or _closed or _transitioning or combat_scene == null or map_screen != null: return
	if confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or route_menu.visible: return
	if combat_scene.inspector.visible or combat_scene.options.visible or combat_scene.dialog.visible: return
	_open_route_menu("combat", token, feedback)

func _collection_catalog() -> Dictionary:
	if combat_scene != null: return combat_scene.controller.snapshot().get("catalog", {}).duplicate(true)
	return ContentLoader.load_setup().get("setup", {}).get("catalog", {}).duplicate(true)

func _create_shop_scene() -> Control:
	return ShopViewer.new()

func _open_saved_shop() -> void:
	if _closed or _transitioning or run_state == null or shop_screen != null: return
	if run_state.snapshot().status != "room_active" or run_state.snapshot().get("is_terminal", false): return
	_transitioning = true
	var attached := _prepare_shop_scene(run_state.shop_snapshot())
	if attached.ok:
		_dismiss_confirmation()
		_activate_shop_scene(attached.scene)
	else:
		_show_shop_open_failure()
	_transitioning = false

func _show_shop_open_failure() -> void:
	_show_confirmation("retry_shop_open", "Shop unavailable", "The shop could not be opened. Your saved visit is safe. Try again.", "Retry", false)
	confirmation_cancel.text = "Return Home"

func _prepare_shop_scene(record: Dictionary) -> Dictionary:
	if record.is_empty() or record.get("status") != "active" or record.get("identity", {}).is_empty():
		return {"ok": false, "error": "This shop visit is unavailable."}
	var candidate := _create_shop_scene()
	if candidate == null:
		return {"ok": false, "error": "The shop could not be opened. Try entering again."}
	if candidate.get_parent() != null or not candidate.has_method("present") or not candidate.has_method("prepare_for_exit"):
		candidate.queue_free()
		return {"ok": false, "error": "The shop could not be opened. Try entering again."}
	candidate.hide()
	add_child(candidate)
	if not candidate.is_inside_tree() or not candidate.is_node_ready() or candidate.gestures == null or candidate.panel == null:
		_dispose_candidate_scene(candidate)
		return {"ok": false, "error": "The shop could not be opened. Try entering again."}
	var catalog := _collection_catalog()
	for slot in record.get("slots", []):
		if not catalog.has(str(slot.get("definition_id", ""))):
			_dispose_candidate_scene(candidate)
			return {"ok": false, "error": "A shop item is unavailable. Your room choice is unchanged."}
	candidate.present(record, catalog)
	candidate.set_blocked(true)
	return {"ok": true, "scene": candidate, "error": ""}

func _confirm_shop_entry(candidate: RunState) -> void:
	var prepared: Dictionary = candidate.prepare_route_shop(_pending_entry)
	var result: Dictionary = prepared
	if prepared.get("ok", false):
		var display_record: Dictionary = prepared.shop.duplicate(true)
		var resources := candidate.snapshot()
		display_record.gold = resources.gold
		display_record.owned_cards = resources.owned_cards
		var attached := _prepare_shop_scene(display_record)
		if attached.ok:
			result = candidate.commit_route_shop(prepared)
			if result.get("ok", false):
				_commit_transaction(candidate, "shop_entry", {"scene": attached.scene})
				return
			_dispose_candidate_scene(attached.scene)
		else:
			result = attached
		candidate.cancel_prepared_shop(prepared)
	_dismiss_confirmation()
	if map_screen != null:
		map_screen.set_blocked(false)
		map_screen.report_entry_error(str(result.get("error", "The shop could not be opened.")))
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	_transitioning = false

func _activate_shop_scene(candidate: Control) -> void:
	_generation += 1
	home.hide()
	shop_screen = candidate
	shop_screen.present(run_state.shop_snapshot(), _collection_catalog())
	shop_screen.show()
	shop_screen.set_sound_enabled(bool(audio_settings.enabled))
	shop_screen.set_blocked(false)
	shop_screen.purchase_requested.connect(_purchase_shop_rune)
	shop_screen.remove_requested.connect(_remove_shop_rune)
	shop_screen.upgrade_requested.connect(_upgrade_shop_rune)
	shop_screen.relic_purchase_requested.connect(_purchase_shop_relic)
	shop_screen.leave_requested.connect(_leave_shop)
	shop_screen.map_requested.connect(open_map)
	shop_screen.menu_requested.connect(_shop_menu_requested.bind(_generation))
	shop_screen.sound_requested.connect(_shop_sound_requested.bind(_generation))
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	for overlay in [route_menu, collection_screen, reward_screen, confirmation, options]: move_child(overlay, -1)
	screen_changed.emit("shop")

func _shop_menu_requested(token: int) -> void:
	if token != _generation or not _shop_navigation_allowed(): return
	_open_route_menu("shop", token)

func _shop_sound_requested(token: int) -> void:
	if token != _generation or not _shop_navigation_allowed(): return
	_change_option("enabled", not bool(audio_settings.enabled))
	shop_screen.set_sound_enabled(bool(audio_settings.enabled))

func _shop_navigation_allowed() -> bool:
	return not _closed and not _transitioning and shop_screen != null and map_screen == null \
		and not shop_screen.inspection.visible and not confirmation.visible and not options.visible \
		and not route_menu.visible and not collection_screen.visible and not reward_screen.visible

func _purchase_shop_rune(identity: Dictionary, slot_id: String) -> void:
	_shop_action("purchase", identity, slot_id)

func _remove_shop_rune(identity: Dictionary, uid: int) -> void:
	_shop_action("remove", identity, "", uid)

func _upgrade_shop_rune(identity: Dictionary, uid: int) -> void:
	_shop_action("upgrade", identity, "", uid)

func _purchase_shop_relic(identity: Dictionary, slot_id: String) -> void:
	_shop_action("relic", identity, slot_id)

func _leave_shop(identity: Dictionary) -> void:
	_shop_action("leave", identity)

func _shop_action(action: String, identity: Dictionary, slot_id: String = "", uid: int = -1) -> void:
	if _closed or _transitioning or run_state == null or shop_screen == null or map_screen != null or not _failed_transaction.is_empty(): return
	if confirmation.visible or options.visible or route_menu.visible or collection_screen.visible or reward_screen.visible: return
	if identity != shop_screen.presentation.get("identity", {}): return
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		shop_screen.report_error(str(staged.error))
		_transitioning = false
		return
	var receipt: Dictionary = {}
	match action:
		"purchase": receipt = staged.run.buy_shop_rune(identity, slot_id)
		"remove": receipt = staged.run.remove_shop_rune(identity, uid)
		"upgrade": receipt = staged.run.upgrade_shop_rune(identity, uid)
		"relic": receipt = staged.run.buy_shop_relic(identity, slot_id)
		"leave": receipt = staged.run.leave_shop(identity)
	if not receipt.get("ok", false):
		shop_screen.report_error(str(receipt.get("error", "This action is unavailable.")))
		_transitioning = false
		return
	shop_screen.set_blocked(true)
	_commit_transaction(staged.run, "shop_" + action, {"identity": identity.duplicate(true), "receipt": receipt})

func _detach_shop() -> void:
	if shop_screen == null: return
	var previous := shop_screen
	shop_screen = null
	_generation += 1
	previous.prepare_for_exit()
	remove_child(previous)
	previous.queue_free()

func _create_service_scene() -> Control:
	return ServiceViewer.new()

func _open_saved_service() -> void:
	if _closed or _transitioning or run_state == null or service_screen != null: return
	if run_state.snapshot().status != "room_active" or run_state.snapshot().get("is_terminal", false): return
	_transitioning = true
	var attached := _prepare_service_scene(run_state.service_snapshot())
	if attached.ok:
		_dismiss_confirmation()
		_activate_service_scene(attached.scene)
	else:
		_show_confirmation("retry_service_open", "Room unavailable", "This room could not be opened. Your saved visit is safe. Try again.", "Retry", false)
		confirmation_cancel.text = "Return Home"
	_transitioning = false

func _prepare_service_scene(record: Dictionary) -> Dictionary:
	if record.is_empty() or record.get("status") != "active" or record.get("identity", {}).is_empty() or not record.get("room_type") in ["event", "recovery"]:
		return {"ok": false, "error": "This room visit is unavailable."}
	if not record.get("choices") is Array or record.choices.is_empty() or str(record.get("title", "")).is_empty():
		return {"ok": false, "error": "This room's choices are unavailable. Your route choice is unchanged."}
	var candidate := _create_service_scene()
	if candidate == null:
		return {"ok": false, "error": "The room could not be opened. Try entering again."}
	if candidate.is_queued_for_deletion() or candidate.get_parent() != null or not candidate.has_method("present") or not candidate.has_method("prepare_for_exit"):
		candidate.queue_free()
		return {"ok": false, "error": "The room could not be opened. Try entering again."}
	candidate.hide()
	add_child(candidate)
	if candidate.is_queued_for_deletion() or not candidate.is_inside_tree() or not candidate.is_node_ready() or candidate.gestures == null or candidate.panel == null:
		_dispose_candidate_scene(candidate)
		return {"ok": false, "error": "The room could not be opened. Try entering again."}
	candidate.present(record, _collection_catalog())
	candidate.set_blocked(true)
	return {"ok": true, "scene": candidate, "error": ""}

func _confirm_service_entry(candidate: RunState) -> void:
	var prepared: Dictionary = candidate.prepare_route_service(_pending_entry)
	var result: Dictionary = prepared
	if prepared.get("ok", false):
		var attached := _prepare_service_scene(prepared.service)
		if attached.ok:
			result = candidate.commit_route_service(prepared)
			if result.get("ok", false):
				_commit_transaction(candidate, "service_entry", {"scene": attached.scene})
				return
			_dispose_candidate_scene(attached.scene)
		else:
			result = attached
		candidate.cancel_prepared_service(prepared)
	_dismiss_confirmation()
	if map_screen != null:
		map_screen.set_blocked(false)
		map_screen.report_entry_error(str(result.get("error", "The room could not be opened.")))
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	_transitioning = false

func _activate_service_scene(candidate: Control) -> void:
	_generation += 1
	home.hide()
	service_screen = candidate
	service_screen.present(run_state.service_snapshot(), _collection_catalog())
	service_screen.show()
	service_screen.set_sound_enabled(bool(audio_settings.enabled))
	service_screen.set_blocked(false)
	service_screen.choice_requested.connect(_service_choice_requested.bind(_generation))
	service_screen.targeted_choice_requested.connect(_service_targeted_choice_requested.bind(_generation))
	service_screen.map_requested.connect(_service_map_requested.bind(_generation))
	service_screen.menu_requested.connect(_service_menu_requested.bind(_generation))
	service_screen.sound_requested.connect(_service_sound_requested.bind(_generation))
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	for overlay in [route_menu, collection_screen, reward_screen, confirmation, options]: move_child(overlay, -1)
	screen_changed.emit(str(service_screen.presentation.room_type))

func _service_choice_requested(identity: Dictionary, choice_id: String, token: int) -> void:
	if token == _generation: _resolve_service_choice(identity, choice_id)

func _service_targeted_choice_requested(identity: Dictionary, choice_id: String, target: Variant, token: int) -> void:
	if token == _generation: _resolve_service_choice(identity, choice_id, target)

func _service_map_requested(token: int) -> void:
	if token == _generation and _service_navigation_allowed(): open_map()

func _service_menu_requested(token: int) -> void:
	if token != _generation or not _service_navigation_allowed(): return
	_open_route_menu("service", token)

func _service_sound_requested(token: int) -> void:
	if token != _generation or not _service_navigation_allowed(): return
	_change_option("enabled", not bool(audio_settings.enabled))
	service_screen.set_sound_enabled(bool(audio_settings.enabled))

func _service_navigation_allowed() -> bool:
	return not _closed and not _transitioning and service_screen != null and map_screen == null \
		and not service_screen.inspection.visible and not confirmation.visible and not options.visible \
		and not route_menu.visible and not collection_screen.visible and not reward_screen.visible

func _resolve_service_choice(identity: Dictionary, choice_id: String, target: Variant = null) -> void:
	if _closed or _transitioning or run_state == null or service_screen == null or map_screen != null or not _failed_transaction.is_empty(): return
	if confirmation.visible or options.visible or route_menu.visible or collection_screen.visible or reward_screen.visible: return
	if identity != service_screen.presentation.get("identity", {}): return
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		service_screen.report_error(str(staged.error))
		_transitioning = false
		return
	var result: Dictionary = staged.run.resolve_service(identity, choice_id, target)
	if not result.get("ok", false):
		service_screen.report_error(str(result.get("error", "This choice is unavailable.")))
		_transitioning = false
		return
	service_screen.set_blocked(true)
	_commit_transaction(staged.run, "service_resolve", {"identity": identity.duplicate(true), "receipt": result.get("receipt", {}).duplicate(true)})

func _detach_service() -> void:
	if service_screen == null: return
	var previous := service_screen
	service_screen = null
	_generation += 1
	previous.prepare_for_exit()
	remove_child(previous)
	previous.queue_free()

func open_store() -> void:
	if _closed or _transitioning or run_state == null or store_screen.visible or not _failed_transaction.is_empty(): return
	if not route_menu.visible or not _route_menu_caller_valid() or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or run_review.visible: return
	var record: Dictionary = run_state.store_snapshot()
	if not record.get("enabled", false): return
	store_screen.present(record, _collection_catalog())
	_restore_overlay_caller()
	_feedback("ui_confirm")
	screen_changed.emit("store")

func close_store() -> void:
	if _closed or _transitioning or not store_screen.visible or confirmation.visible or not _failed_transaction.is_empty(): return
	store_screen.hide()
	_pending_store.clear()
	_update_route_menu_actions()
	_restore_overlay_caller()
	_feedback("ui_back")
	screen_changed.emit("menu")

func _store_purchase_requested(identity: Dictionary, kind: String, definition_id: String) -> void:
	if _closed or _transitioning or run_state == null or not store_screen.visible or not _failed_transaction.is_empty(): return
	if confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or not _route_menu_caller_valid(): return
	var record: Dictionary = run_state.store_snapshot()
	if not record.get("enabled", false) or identity != record.get("identity", {}) or identity != store_screen.presentation.get("identity", {}): return
	if kind not in ["rune", "relic"]: return
	var selected: Dictionary = {}
	for item in record.get("runes" if kind == "rune" else "relics", []):
		if item.get("definition_id") == definition_id: selected = item
	if selected.is_empty() or not selected.get("enabled", false): return
	_pending_store = {"identity": identity.duplicate(true), "kind": kind, "definition_id": definition_id,
		"map_generation": _map_generation, "menu_generation": _route_menu_generation}
	var benefit := str(selected.get("description", ""))
	if kind == "rune":
		var card := preload("res://scripts/ui/collection_data.gd").definition_card(_collection_catalog(), definition_id)
		benefit = "%s\nEnergy: %d\n\nOne rank-zero copy for later battles. Run only." % [str(card.get("inspection", card.get("description", benefit))), int(card.get("cost", 0))]
	else:
		benefit += "\n\nUnique relic · run only."
	store_screen.set_blocked(true)
	_show_confirmation("store_purchase", "Buy %s?" % str(selected.name),
		"%d Gold · %d remaining\n\n%s\n\nUses this run's Store %s purchase." % [int(selected.cost), int(record.gold) - int(selected.cost), benefit, kind],
		"Buy · %d Gold" % int(selected.cost))

func confirm_store_purchase() -> void:
	if _closed or _transitioning or run_state == null or not confirmation.visible or _pending_action != "store_purchase" or _pending_store.is_empty(): return
	if not store_screen.visible or not route_menu.visible or not _route_menu_caller_valid() or not _failed_transaction.is_empty(): return
	if _pending_store.map_generation != _map_generation or _pending_store.menu_generation != _route_menu_generation: return
	var request := _pending_store.duplicate(true)
	var staged := _stage_current()
	if not staged.get("ok", false):
		_dismiss_confirmation()
		store_screen.report_error(str(staged.get("error", "This purchase is unavailable.")))
		_restore_overlay_caller()
		return
	var candidate: RunState = staged.run
	var receipt: Dictionary = candidate.purchase_store_rune(request.identity, request.definition_id) if request.kind == "rune" else candidate.purchase_store_relic(request.identity, request.definition_id)
	if not receipt.get("ok", false):
		_dismiss_confirmation()
		store_screen.present(run_state.store_snapshot(), _collection_catalog())
		store_screen.report_error(str(receipt.get("error", "This purchase is unavailable.")))
		_restore_overlay_caller()
		return
	_transitioning = true
	_commit_transaction(candidate, "store_purchase", {"receipt": receipt})

func open_collection() -> void:
	if _closed or _transitioning or run_state == null or collection_screen.visible or reward_screen.visible or confirmation.visible or options.visible or run_review.visible or store_screen.visible: return
	if combat_scene != null:
		if combat_scene.controller == null or combat_scene.controller.is_busy() or combat_scene.inspector.visible or combat_scene.options.visible or combat_scene.dialog.visible: return
		combat_scene.set_shell_modal(true)
	if map_screen != null: map_screen.set_blocked(true)
	if shop_screen != null: shop_screen.set_blocked(true)
	if service_screen != null: service_screen.set_blocked(true)
	var live: Dictionary = combat_scene.controller.snapshot() if combat_scene != null else {}
	collection_screen.present(run_state.snapshot(), _collection_catalog(), live)
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(collection_screen)
	screen_changed.emit("collection")

func close_collection() -> void:
	if _closed or _transitioning or not collection_screen.visible: return
	collection_screen.hide()
	_restore_overlay_caller()

func open_rewards() -> void:
	if _closed or _transitioning or run_state == null or reward_screen.visible or collection_screen.visible or options.visible or route_menu.visible or run_review.visible: return
	if confirmation.visible and _pending_action != "encounter_result": return
	var record: Dictionary = run_state.pending_reward()
	if record.is_empty(): return
	if combat_scene != null:
		if combat_scene.controller == null or combat_scene.controller.is_busy(): return
		combat_scene.set_shell_modal(true)
	if map_screen != null: map_screen.set_blocked(true)
	reward_screen.present(_reward_display_record(record), _collection_catalog())
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(reward_screen)
	screen_changed.emit("rewards")

func close_rewards() -> void:
	if _closed or _transitioning or not reward_screen.visible: return
	reward_screen.hide()
	if run_state.snapshot().get("final_results_ready", false):
		_show_final_results()
		return
	if confirmation.visible and _pending_action == "encounter_result": _show_encounter_result(true)
	if map_screen != null:
		var state := run_state.snapshot()
		state.can_resume_room = state.status in ["battle", "replay_pending", "result_pending", "pending_choices"]
		map_screen.set_snapshot(state)
	_restore_overlay_caller()

func _restore_overlay_caller() -> void:
	_last_back_frame = Engine.get_process_frames()
	_gestures.cancel_pending(true)
	if confirmation.visible:
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_gestures.set_modal(confirmation)
	elif store_screen.visible:
		store_screen.set_blocked(false)
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_gestures.set_modal(store_screen)
	elif route_menu.visible:
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_gestures.set_modal(route_menu)
	elif run_review.visible:
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_gestures.set_modal(run_review)
	elif map_screen != null:
		_gestures.set_modal(null)
		_gestures.process_mode = Node.PROCESS_MODE_DISABLED
		map_screen.set_blocked(false)
	elif combat_scene != null:
		_gestures.set_modal(null)
		_gestures.process_mode = Node.PROCESS_MODE_DISABLED
		combat_scene.set_shell_modal(false)
	elif shop_screen != null:
		_gestures.set_modal(null)
		_gestures.process_mode = Node.PROCESS_MODE_DISABLED
		shop_screen.set_blocked(false)
	elif service_screen != null:
		_gestures.set_modal(null)
		_gestures.process_mode = Node.PROCESS_MODE_DISABLED
		service_screen.set_blocked(false)
	else:
		_gestures.set_modal(null)
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_refresh_home()

func _choose_reward(identity: Dictionary, definition_id: String) -> void:
	_reward_action("choose", identity, definition_id)

func _skip_reward(identity: Dictionary) -> void:
	_reward_action("skip", identity)

func _claim_reward_gold(identity: Dictionary) -> void:
	_reward_action("gold", identity)

func _reward_action(action: String, identity: Dictionary, definition_id: String = "") -> void:
	if _closed or _transitioning or run_state == null or not reward_screen.visible or not _failed_transaction.is_empty(): return
	if identity != reward_screen.presentation.get("identity", {}): return
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		reward_screen.report_error(str(staged.error))
		_transitioning = false
		return
	var receipt: Dictionary
	match action:
		"choose": receipt = staged.run.choose_reward(identity, definition_id)
		"skip": receipt = staged.run.skip_reward(identity)
		"gold": receipt = staged.run.claim_reward_gold(identity)
	if not receipt.get("ok", false):
		reward_screen.report_error(str(receipt.get("error", "This choice could not be committed.")))
		_transitioning = false
		return
	_commit_transaction(staged.run, "reward", {"identity": identity.duplicate(true), "receipt": receipt,
		"result_open": confirmation.visible and _pending_action == "encounter_result"})

func _reward_display_record(record: Dictionary) -> Dictionary:
	var view := record.duplicate(true)
	view.rune_status = record.get("resolution", "pending")
	view.gold = record.get("gold_amount", 0)
	var lines: Array[String] = []
	var unlock: bool = record.get("kind") == "definition_unlock"
	match str(record.get("resolution", "pending")):
		"chosen": lines.append("Rune claimed: %s · new owned UID %d." % [str(record.get("chosen_id", "")).capitalize(), record.get("granted_uid", -1)])
		"unlocked": lines.append("Definition unlocked: %s. Future rewards, shops and Store entries; starter unchanged." % str(record.get("chosen_id", "")).capitalize())
		"exhausted": lines.append("No new implemented definition remains to unlock. No permanent award or compensation.")
		"skipped": lines.append("Rune choice skipped. No card was granted.")
		_: lines.append("Unlock one new definition." if unlock else "Choose one rune for this run, or Skip.")
	if int(view.gold) > 0: lines.append("%d Gold %s." % [view.gold, "claimed" if record.get("gold_claimed", false) else "available separately"])
	else: lines.append("No Gold payout is configured.")
	view.summary = "\n".join(lines)
	return view

func _reward_result_text(result: Dictionary) -> String:
	var records: Array = result.get("rewards", [])
	if records.is_empty():
		var no_award := "No Gold, runes, healing, relics, perks or permanent unlocks were granted."
		var policy := str(result.get("reward_policy", ""))
		return no_award + ("\n" + policy if not policy.is_empty() else "")
	var lines: Array[String] = []
	for record in records:
		if record.get("status") == "unavailable":
			lines.append(str(record.get("error", "Reward policy unavailable; choice remains pending.")))
		else:
			lines.append(str(_reward_display_record(record).summary))
	return "\n".join(lines)

# The caller stays alive below this screen. In particular, Combat keeps its
# controller, preparation, scroll, selection and audio coordinator.
func open_map() -> void:
	if _closed or _transitioning or run_state == null or map_screen != null or confirmation.visible or options.visible or route_menu.visible or collection_screen.visible or reward_screen.visible or run_review.visible: return
	if run_state.snapshot().get("final_results_ready", false):
		_show_final_results()
		return
	if run_state.snapshot().status == "result_pending":
		_show_encounter_result()
		return
	_present_map()

# Private presentation seam also used while a successful Store Retry retains
# the publication lock. Reentrant screen/audio callbacks cannot enter rooms.
func _present_map() -> void:
	if combat_scene != null:
		if combat_scene.controller == null or combat_scene.controller.is_busy(): return
		if combat_scene.inspector.visible or combat_scene.options.visible or combat_scene.menu.visible or combat_scene.dialog.visible: return
		combat_scene.set_shell_modal(true)
	if shop_screen != null:
		if shop_screen.inspection.visible: return
		shop_screen.set_blocked(true)
	if service_screen != null:
		if service_screen.inspection.visible: return
		service_screen.set_blocked(true)
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	_map_generation += 1
	map_screen = RouteMap.new()
	add_child(map_screen)
	map_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var state := run_state.snapshot()
	state.can_resume_room = combat_scene != null or shop_screen != null or service_screen != null or state.status in ["battle", "replay_pending", "result_pending", "pending_choices"] or not run_state.shop_snapshot().is_empty() or not run_state.service_snapshot().is_empty()
	map_screen.set_snapshot(state)
	map_screen.set_sound_enabled(combat_scene.sound_enabled if combat_scene != null else bool(audio_settings.enabled))
	map_screen.close_requested.connect(_map_close_requested.bind(_map_generation))
	map_screen.resume_requested.connect(_map_resume_requested.bind(_map_generation))
	map_screen.entry_requested.connect(_map_entry_requested.bind(_map_generation))
	map_screen.menu_requested.connect(_map_menu_requested.bind(_map_generation))
	map_screen.sound_requested.connect(_map_sound_requested.bind(_map_generation))
	map_screen.details_requested.connect(_map_details_requested.bind(_map_generation))
	move_child(confirmation, -1)
	move_child(options, -1)
	screen_changed.emit("map")

func _map_close_requested(token: int) -> void:
	if token == _map_generation: close_map()

func _map_resume_requested(token: int) -> void:
	if token != _map_generation or _closed or _transitioning or confirmation.visible or options.visible or route_menu.visible or run_review.visible: return
	if run_state.snapshot().status == "pending_choices":
		open_rewards()
		return
	close_map()
	if combat_scene == null and shop_screen == null and service_screen == null: continue_run()

func _map_entry_requested(node_id: String, token: int) -> void:
	if token == _map_generation: request_node_entry(node_id)

func _map_menu_requested(token: int) -> void:
	if not _map_navigation_allowed(token): return
	_open_route_menu("map", token)

func _map_details_requested(token: int) -> void:
	if not _map_navigation_allowed(token) or run_state == null: return
	if combat_scene != null and combat_scene.controller.is_busy(): return
	map_screen.set_blocked(true)
	_review_generation += 1
	_pending_abandon.clear()
	var requested: Dictionary = run_state.abandonment_request()
	if requested.get("ok", false): _pending_abandon = requested.token.duplicate(true)
	run_review.present(run_state.snapshot(), {"run_id": run_state.snapshot().run_id, "generation": _review_generation}, false)
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(run_review)
	screen_changed.emit("run_details")

func _show_final_results() -> void:
	if _closed or _transitioning or run_state == null or not run_state.snapshot().get("final_results_ready", false): return
	# An ending is already durable here. A read-only review never reconstructs
	# Combat, refreshes room offerings, or sends a finished run to the Map.
	_dismiss_route_menu()
	_discard_map()
	_detach_battle()
	_detach_shop()
	_detach_service()
	_dismiss_confirmation()
	reward_screen.hide()
	collection_screen.hide()
	home.show()
	_load_settings()
	_start_home_audio()
	_review_generation += 1
	run_review.present(run_state.snapshot(), {"run_id": run_state.snapshot().run_id, "generation": _review_generation}, true)
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(run_review)
	screen_changed.emit("results")

func _review_action(action: String, identity: Dictionary) -> void:
	if _closed or _transitioning or run_state == null or not run_review.visible or confirmation.visible or options.visible: return
	if identity != {"run_id": run_state.snapshot().run_id, "generation": _review_generation}: return
	if not _failed_transaction.is_empty(): return
	if run_review.final_review:
		if action == "new_run": request_new_run()
		elif action == "home":
			if run_state.snapshot().terminal.get("acknowledged", false):
				_return_home()
				return
			var staged := _stage_current()
			if not staged.ok or not staged.run.acknowledge_final_result(run_state.snapshot().terminal.identity): return
			_transitioning = true
			_commit_transaction(staged.run, "final_home")
		return
	if action == "close":
		_close_run_review()
		_restore_overlay_caller()
	elif action == "pending":
		_close_run_review()
		_restore_overlay_caller()
		if run_state.snapshot().status == "result_pending": _show_encounter_result()
		else: open_rewards()
	elif action == "abandon" and not _pending_abandon.is_empty():
		_show_confirmation("abandon", "Abandon this run?", "This ends the current run and loses its run-only progress, Gold, rune upgrades and relics. Previously committed permanent rune unlocks and Options remain.\n\nDuring Combat, history uses the saved battle-entry checkpoint. Current turn progress is not saved. Cancel keeps this run unchanged.", "Abandon Run")

func confirm_abandon() -> void:
	if _closed or _transitioning or _pending_action != "abandon" or not confirmation.visible or not run_review.visible or run_review.final_review: return
	if run_state == null or _pending_abandon.is_empty() or not _failed_transaction.is_empty(): return
	var staged := _stage_current()
	if not staged.ok: return
	var result: Dictionary = staged.run.abandon_run(_pending_abandon)
	if not result.get("ok", false):
		_dismiss_confirmation()
		_close_run_review()
		_restore_overlay_caller()
		return
	_transitioning = true
	_commit_transaction(staged.run, "abandon")

func _close_run_review() -> void:
	_review_generation += 1
	_pending_abandon.clear()
	if run_review != null: run_review.hide()

func _open_route_menu(origin: String, token: int, feedback: bool = true) -> void:
	_route_menu_origin = origin
	_route_menu_generation = token
	var menu_body: Label = _route_menu_panel.get_meta("rc_body_scroll").get_child(0)
	menu_body.text = "Resume returns to this shop. Quit to Home keeps this visit, stock and purchases; Continue returns here." if run_state != null and not run_state.shop_snapshot().is_empty() else "Resume keeps this battle unchanged. Quit to Home discards battle progress; Continue replays its entry."
	if run_state != null and not run_state.service_snapshot().is_empty():
		menu_body.text = "Resume returns to this room. Quit to Home keeps this visit open; Continue returns to the same choices."
	if run_state != null and run_state.snapshot().status == "route_ready":
		menu_body.text = "Resume returns to the Map. Quit to Home keeps your saved progress."
	if run_state != null and not run_state.store_snapshot().get("enabled", false):
		menu_body.text += "\n\nStore: " + str(run_state.store_snapshot().get("error", "Finish the current room and its rewards first."))
	if map_screen != null: map_screen.set_blocked(true)
	if combat_scene != null: combat_scene.set_shell_modal(true)
	if shop_screen != null: shop_screen.set_blocked(true)
	if service_screen != null: service_screen.set_blocked(true)
	_update_route_menu_actions()
	route_menu.show()
	_route_menu_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	_gestures.cancel_pending(true)
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(route_menu)
	_fit_route_menu()
	if feedback: _feedback("ui_confirm")

func _route_menu_caller_valid() -> bool:
	if _route_menu_origin == "map": return map_screen != null and _route_menu_generation == _map_generation
	if _route_menu_origin == "combat": return combat_scene != null and map_screen == null and _route_menu_generation == _generation
	if _route_menu_origin == "shop": return shop_screen != null and map_screen == null and _route_menu_generation == _generation
	if _route_menu_origin == "service": return service_screen != null and map_screen == null and _route_menu_generation == _generation
	return false

func _update_route_menu_actions() -> void:
	var busy: bool = combat_scene != null and (combat_scene.controller == null or combat_scene.controller.is_busy())
	Ui.apply_states(route_menu_collection, {"disabled": busy})
	Ui.apply_states(route_menu_quit, {"disabled": busy})
	var available: bool = run_state != null and run_state.store_snapshot().get("enabled", false) and _failed_transaction.is_empty()
	# A stable label prevents a wrapped unavailable suffix moving the fixed
	# action rows on narrow windows. Disabled styling and body copy state why.
	route_menu_store.text = "Store"
	Ui.apply_states(route_menu_store, {"unavailable": not available, "disabled": busy})

func _map_sound_requested(token: int) -> void:
	if not _map_navigation_allowed(token): return
	if combat_scene != null:
		combat_scene._toggle_sound()
		map_screen.set_sound_enabled(combat_scene.sound_enabled)
	else:
		_change_option("enabled", not bool(audio_settings.enabled))
		map_screen.set_sound_enabled(bool(audio_settings.enabled))

func _map_navigation_allowed(token: int) -> bool:
	return not _closed and not _transitioning and token == _map_generation and map_screen != null \
		and not confirmation.visible and not options.visible and not route_menu.visible and not map_screen.inspection.visible \
		and not collection_screen.visible and not reward_screen.visible and not run_review.visible

func _close_route_menu() -> void:
	if _closed or _transitioning or not route_menu.visible or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or store_screen.visible or not _route_menu_caller_valid(): return
	_dismiss_route_menu()
	_restore_overlay_caller()
	_feedback("ui_back")

func _dismiss_route_menu() -> void:
	route_menu.hide()
	_gestures.cancel_pending(true)
	_route_menu_generation = -1
	_route_menu_origin = ""

func _route_menu_home() -> void:
	if _closed or _transitioning or not route_menu.visible or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or store_screen.visible or not _route_menu_caller_valid(): return
	if combat_scene != null:
		request_home()
	else:
		_show_confirmation("home", "Quit to Home?", "Your run and its saved checkpoint will remain available. Continue returns to this room or the Map.\n\nPermanent rune unlocks and Options are retained.", "Quit to Home")

func close_map() -> void:
	if _closed or _transitioning or map_screen == null or confirmation.visible or options.visible or route_menu.visible or collection_screen.visible or reward_screen.visible or run_review.visible: return
	_discard_map()
	_last_back_frame = Engine.get_process_frames()
	if combat_scene != null:
		combat_scene.set_shell_modal(false)
		screen_changed.emit("combat")
	elif shop_screen != null:
		shop_screen.set_blocked(false)
		screen_changed.emit("shop")
	elif service_screen != null:
		service_screen.set_blocked(false)
		screen_changed.emit(str(service_screen.presentation.room_type))
	else:
		_gestures.process_mode = Node.PROCESS_MODE_INHERIT
		_gestures.set_modal(null)
		_refresh_home()
		screen_changed.emit("home")

func _discard_map() -> void:
	if map_screen == null: return
	var old_map := map_screen
	map_screen = null
	_map_generation += 1
	old_map.set_blocked(true)
	old_map.hide()
	old_map.queue_free()
	_pending_entry.clear()
	_entry_generation = -1

func request_node_entry(node_id: String) -> void:
	if _closed or _transitioning or map_screen == null or run_state == null or confirmation.visible or combat_scene != null or shop_screen != null or service_screen != null or options.visible or route_menu.visible or collection_screen.visible or reward_screen.visible or run_review.visible or not _failed_transaction.is_empty(): return
	var requested: Dictionary = run_state.request_room_entry(node_id)
	if not requested.ok:
		map_screen.report_entry_error(str(requested.error))
		return
	_pending_entry = requested.token.duplicate(true)
	_entry_generation = _generation
	var detail: Dictionary = run_state.inspect_node(node_id)
	map_screen.set_blocked(true)
	_show_confirmation("route_entry", "Enter this room?", "Enter %s?\n%s · %s\n\nRoom availability is checked when you confirm. If its content is not available, your route and choice remain unchanged." % [str(detail.get("title", node_id)), str(detail.get("encounter_role", detail.get("room_type", ""))).capitalize(), str(detail.get("board_id", ""))], "Enter room")

func confirm_node_entry() -> void:
	if _closed or _transitioning or map_screen == null or run_state == null or _pending_action != "route_entry" or not confirmation.visible: return
	if _entry_generation != _generation:
		cancel_confirmation()
		return
	_transitioning = true
	var staged := _stage_current()
	if not staged.ok:
		map_screen.report_entry_error(str(staged.error))
		_transitioning = false
		return
	if run_state.inspect_node(str(_pending_entry.get("node_id", ""))).get("room_type") == "shop":
		_confirm_shop_entry(staged.run)
		return
	if run_state.inspect_node(str(_pending_entry.get("node_id", ""))).get("room_type") in ["recovery", "event"]:
		_confirm_service_entry(staged.run)
		return
	var prepared: Dictionary = staged.run.prepare_route_battle(_pending_entry)
	var result: Dictionary = prepared
	if prepared.ok:
		var attached := _prepare_battle_scene(prepared.combat, prepared.setup)
		if attached.ok:
			result = staged.run.commit_route_battle(prepared)
			if result.ok:
				_commit_transaction(staged.run, "entry", {"scene": attached.scene, "setup": prepared.setup})
				return
			else:
				_dispose_candidate_scene(attached.scene)
		else:
			result = attached
		if not result.ok: staged.run.cancel_prepared_battle(prepared)
	_dismiss_confirmation()
	if map_screen != null:
		map_screen.set_blocked(false)
		map_screen.report_entry_error(str(result.get("error", "")))
	_gestures.process_mode = Node.PROCESS_MODE_DISABLED
	_transitioning = false

func _battle_home_requested(token: int) -> void:
	if token == _generation: request_home()

func _battle_changed(token: int) -> void:
	if _closed or _transitioning or token != _generation or combat_scene == null or combat_scene.controller.is_busy() or not _failed_transaction.is_empty(): return
	if route_menu.visible: _update_route_menu_actions()
	var battle_state: Dictionary = combat_scene.controller.snapshot()
	if battle_state.state in ["victory", "defeat"]:
		var staged := _stage_current()
		if not staged.ok: return
		if staged.run.resolve_battle(combat_scene.battle_model):
			_transitioning = true
			var identity: Dictionary = run_state.snapshot().active_battle
			if identity.is_empty(): identity = {"run_id": run_state.snapshot().run_id, "route_id": "standalone",
				"node_id": "fixture_shadeling", "visit_id": str(run_state.snapshot().run_id) + "/standalone", "generation": 1}
			_commit_transaction(staged.run, "outcome", {"identity": identity, "outcome": battle_state.state})

func _show_encounter_result(refresh: bool = false) -> void:
	if _closed or _transitioning or run_state == null: return
	var state := run_state.snapshot()
	if state.status != "result_pending" or (confirmation.visible and not refresh): return
	var result: Dictionary = state.pending_result
	_pending_result_identity = result.identity.duplicate(true)
	if route_menu.visible: options.hide()
	_dismiss_route_menu()
	if combat_scene != null:
		combat_scene.menu.hide()
		combat_scene.set_shell_modal(true)
	var victory := str(result.outcome) == "victory"
	var tower_complete: bool = victory and str(result.get("role", "")) == "guardian" and state.route.get("status") == "tower_completed"
	var final_outcome: bool = not state.get("terminal", {}).is_empty()
	var body := "%s\n%s · %s\n\nHealth %d / %d · Run Gold %d\n\n" % [str(result.get("encounter_name", "Encounter")), str(result.get("enemy_name", "Enemy")), str(result.get("role", "")).capitalize(), state.player_hp, state.player_max_hp, state.gold]
	if victory:
		body += "The guardian is defeated and the tower is complete. " if tower_complete else "This encounter is complete. "
		if not result.get("pending_choices", []).is_empty():
			body += "Required room choices are still pending. Successors stay locked until those choices are resolved."
		else:
			body += "View the final run results." if tower_complete else "Return to Map to inspect the route."
	else:
		body += "The run has ended in defeat. No successor is unlocked."
	body += "\n\n" + _reward_result_text(result)
	_show_confirmation("encounter_result", "Tower complete" if tower_complete else "Encounter won" if victory else "Run defeated", body, "View run results" if final_outcome else "Return to Map")
	confirmation_cancel.text = "Return Home"
	result_reward_button.visible = not run_state.pending_reward().is_empty()
	_fit_confirmation.call_deferred()

func acknowledge_encounter_result() -> void:
	if _closed or _transitioning or run_state == null or _pending_action != "encounter_result" or not confirmation.visible or reward_screen.visible or collection_screen.visible: return
	var staged := _stage_current()
	if not staged.ok or not staged.run.acknowledge_result(_pending_result_identity): return
	_transitioning = true
	_commit_transaction(staged.run, "acknowledge")

func request_home() -> void:
	if _closed or _transitioning or combat_scene == null or _development or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or combat_scene.controller.is_busy(): return
	if map_screen != null and (not route_menu.visible or not _route_menu_caller_valid()): return
	_battle_changed(_generation)
	if not _failed_transaction.is_empty(): return
	if combat_scene.controller.snapshot().state != "playing":
		if run_state.snapshot().status == "result_pending":
			_show_encounter_result()
			return
		if not run_state.snapshot().status in ["encounter_won", "defeated"]:
			combat_scene.dialog.title = "Encounter result unavailable"
			combat_scene.dialog.dialog_text = "This encounter result could not be committed. The current session has been retained."
			combat_scene._show_native_popup(combat_scene.dialog, Vector2(560, 360))
			return
		_return_home()
		return
	combat_scene.menu.hide()
	combat_scene.set_shell_modal(true)
	_show_confirmation("home", "Quit to Home?", "Current battle progress will be discarded. Continue replays the saved entry with the same health, cards, endpoints and random state.\n\nThe saved run and permanent rune unlocks remain available after restarting the application.", "Quit to Home")

func confirm_home() -> void:
	if _closed or _transitioning or _pending_action != "home" or not confirmation.visible: return
	if combat_scene == null:
		_return_home()
		return
	_transitioning = true
	var staged := _stage_current()
	if staged.ok and staged.run.quit_to_home(combat_scene.battle_model):
		_commit_transaction(staged.run, "home")
		return
	_transitioning = false

func _return_home() -> void:
	var already_transitioning := _transitioning
	_transitioning = true
	_close_run_review()
	reward_screen.hide()
	collection_screen.hide()
	store_screen.hide()
	_pending_store.clear()
	options.hide()
	_dismiss_route_menu()
	_discard_map()
	_detach_battle()
	_detach_shop()
	_detach_service()
	_dismiss_confirmation()
	_load_settings()
	home.show()
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	_gestures.set_modal(null)
	_start_home_audio()
	_refresh_home()
	screen_changed.emit("home")
	_transitioning = already_transitioning

func _detach_battle() -> void:
	_generation += 1
	if combat_scene == null: return
	var old_scene := combat_scene
	combat_scene = null
	if old_scene.controller != null and _battle_changed_callback.is_valid() and old_scene.controller.changed.is_connected(_battle_changed_callback):
		old_scene.controller.changed.disconnect(_battle_changed_callback)
	if _battle_home_callback.is_valid() and old_scene.home_requested.is_connected(_battle_home_callback):
		old_scene.home_requested.disconnect(_battle_home_callback)
	if _battle_map_callback.is_valid() and old_scene.map_requested.is_connected(_battle_map_callback):
		old_scene.map_requested.disconnect(_battle_map_callback)
	if _battle_menu_callback.is_valid() and old_scene.menu_requested.is_connected(_battle_menu_callback):
		old_scene.menu_requested.disconnect(_battle_menu_callback)
	if _battle_collection_callback.is_valid() and old_scene.collection_requested.is_connected(_battle_collection_callback):
		old_scene.collection_requested.disconnect(_battle_collection_callback)
	old_scene.prepare_for_exit()
	remove_child(old_scene)
	old_scene.queue_free()
	_battle_changed_callback = Callable()
	_battle_home_callback = Callable()
	_battle_map_callback = Callable()
	_battle_menu_callback = Callable()
	_battle_collection_callback = Callable()

func _show_confirmation(action: String, title: String, body: String, confirm_label: String, feedback: bool = true) -> void:
	_pending_action = action
	_confirmation_title.text = title
	confirmation_text.text = body
	confirmation_confirm.text = confirm_label
	confirmation_cancel.text = "Cancel"
	result_reward_button.hide()
	recovery_retry_button.hide()
	recovery_retry_button.text = "Retry loading"
	_confirmation_panel.get_meta("rc_body_scroll").scroll_vertical = 0
	confirmation.show()
	_gestures.process_mode = Node.PROCESS_MODE_INHERIT
	move_child(_gestures, -1)
	_gestures.set_modal(confirmation)
	_fit_home()
	if feedback: _feedback("ui_confirm")

func _confirm_pending() -> void:
	if _pending_action == "new_run": confirm_new_run()
	elif _pending_action == "home": confirm_home()
	elif _pending_action == "route_entry": confirm_node_entry()
	elif _pending_action == "encounter_result": acknowledge_encounter_result()
	elif _pending_action == "retry_save": retry_save()
	elif _pending_action == "retry_shop_open": _open_saved_shop()
	elif _pending_action == "retry_service_open": _open_saved_service()
	elif _pending_action == "recover_save": recover_previous_save()
	elif _pending_action == "abandon": confirm_abandon()
	elif _pending_action == "store_purchase": confirm_store_purchase()

func cancel_confirmation() -> void:
	if _closed or _transitioning or not confirmation.visible or collection_screen.visible or reward_screen.visible: return
	if _pending_action in ["encounter_result", "retry_save"]:
		_return_home()
		return
	_dismiss_confirmation()
	_restore_overlay_caller()
	_feedback("ui_back")

func _dismiss_confirmation() -> void:
	_pending_action = ""
	_pending_seed = -1
	_pending_entry.clear()
	_entry_generation = -1
	_pending_result_identity.clear()
	_pending_store.clear()
	recovery_retry_button.hide()
	confirmation.hide()
	_gestures.cancel_pending(true)
	_gestures.set_modal(null)

func open_options() -> void:
	if _closed or _transitioning or confirmation.visible or options.visible or collection_screen.visible or reward_screen.visible or run_review.visible or store_screen.visible: return
	if (map_screen != null or combat_scene != null or shop_screen != null or service_screen != null) and (not route_menu.visible or not _route_menu_caller_valid()): return
	if combat_scene != null: audio_settings = combat_scene.audio_settings.duplicate(true)
	options.set_values(audio_settings)
	options.body_scroll.scroll_vertical = 0
	options.show()
	_gestures.set_modal(options)
	_feedback("ui_confirm")

func close_options() -> void:
	if _closed or options == null or not options.visible: return
	options.hide()
	_restore_overlay_caller()
	if map_screen != null: map_screen.set_sound_enabled(bool(audio_settings.enabled))
	if shop_screen != null: shop_screen.set_sound_enabled(bool(audio_settings.enabled))
	if service_screen != null: service_screen.set_sound_enabled(bool(audio_settings.enabled))
	_feedback("ui_back")

func _load_settings() -> void:
	audio_settings = AudioSettings.load_values(settings_path)
	if "--reduced-motion" in OS.get_cmdline_user_args(): audio_settings.reduced_motion = true
	options.set_values(audio_settings)

func _change_option(key: String, value: Variant) -> void:
	if _closed or not AudioSettings.DEFAULTS.has(key) or audio_settings.get(key) == value: return
	if combat_scene != null:
		combat_scene._change_option(key, value)
		audio_settings = combat_scene.audio_settings.duplicate(true)
		options.set_values(audio_settings)
		if map_screen != null: map_screen.set_sound_enabled(bool(audio_settings.enabled))
		return
	audio_settings[key] = value
	audio_settings = AudioSettings.normalize(audio_settings)
	options.set_values(audio_settings)
	if audio != null: audio.apply_settings(audio_settings)
	var saved_values := audio_settings.duplicate()
	if key != "reduced_motion": saved_values.reduced_motion = AudioSettings.load_values(settings_path).reduced_motion
	var error := AudioSettings.save_values(saved_values, settings_path)
	if error != OK: push_warning("Options could not be saved: " + error_string(error))
	if not key.ends_with("_volume"): _feedback("ui_confirm")

func _start_home_audio() -> void:
	if audio != null: return
	audio = AudioCoordinator.new()
	# The shell owns non-battle audio across Home, Map and service rooms. Home
	# artwork is hidden in a shop; its visibility must not mute committed cues.
	add_child(audio)
	audio.apply_settings(audio_settings)
	audio.set_context("screen_home", false)

func _stop_home_audio() -> void:
	if audio == null: return
	audio.dispose()
	audio.get_parent().remove_child(audio)
	audio.queue_free()
	audio = null

func _feedback(cue: String) -> void:
	if combat_scene != null and not _closed:
		combat_scene._ui_feedback(cue, {"modal": "application"})
		return
	if audio == null or _closed: return
	_audio_dispatch += 1
	audio.ui_feedback(cue, _audio_dispatch, {"screen": "home"})

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready() or _closed or _development: return
	# Combat owns its Back path. Shell handles only its own visible overlays.
	if combat_scene != null and map_screen == null and not confirmation.visible and not route_menu.visible and not options.visible and not collection_screen.visible and not reward_screen.visible: return
	var frame := Engine.get_process_frames()
	if frame == _last_back_frame: return
	_last_back_frame = frame
	if reward_screen.visible: close_rewards()
	elif collection_screen.visible: collection_screen.dismiss_top()
	elif confirmation.visible: cancel_confirmation()
	elif options.visible: close_options()
	elif store_screen.visible: close_store()
	elif route_menu.visible: _close_route_menu()
	elif run_review.visible: run_review.dismiss_top()
	elif map_screen != null: map_screen.dismiss_top()
	elif shop_screen != null: shop_screen.dismiss_top()
	elif service_screen != null: service_screen.dismiss_top()

func _exit_tree() -> void:
	_closed = true
	_generation += 1
	if _gestures != null: _gestures.cancel_pending(true)
	if combat_scene != null: combat_scene.prepare_for_exit()
	if shop_screen != null: shop_screen.prepare_for_exit()
	if service_screen != null: service_screen.prepare_for_exit()
	if audio != null: audio.dispose()
