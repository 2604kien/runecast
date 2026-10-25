extends SceneTree
## Load only an exported payload: APK resource ZIP or iOS PCK.
## Invoke with --path <empty-directory> --main-pack <zip-or-pck> and
## --script <absolute path to this file>. The empty path prevents local fallback.
## Desktop decoding evidence only: this is not native/device acceptance.
## Optional -- --payload-label=iOS changes evidence labels, not checks.

var checks := 0
var failures := 0
var payload_label := "APK"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--payload-label="):
			payload_label = argument.trim_prefix("--payload-label=")
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	print("%s payload desktop decode probe; this is not physical-device evidence." % payload_label)
	for path in ["res://docs/audio-cue-catalogue.json", "res://docs/audio-loop-catalogue.json", "res://tests/audio_export_probe.gd", "res://tests/helpers/encounter_route_fixture.gd", "res://tests/helpers/reward_route_fixture.gd", "res://tests/helpers/encounter_player.gd", "res://tests/helpers/encounter_failure_shell.gd", "res://tests/helpers/encounter_rejected_scene.gd", "res://tests/encounter_integration_runner.gd", "res://tests/reward_integration_runner.gd", "res://tests/encounter_player_probe.gd", "res://tools/godot.ps1"]:
		check(not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".remap") and not FileAccess.file_exists(path + "c"), "Development-only dependency absent: " + path)
	for path in ["res://tests/helpers/rc032_route_fixture.gd", "res://tests/rc032_manual.gd", "res://tests/rc032_process_runner.gd", "res://tests/fixtures/rc032/enemies.json", "res://tests/fixtures/rc032/guardian.json", "res://tests/fixtures/rc031/pending-defeat-v4.json", "res://tests/fixtures/rc032/production-v5.json", "res://tests/rc032_store_process_runner.gd", "res://tests/rc032_store_migration_runner.gd"]:
		check(not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".remap") and not FileAccess.file_exists(path + "c"), "RC-032 fixtures and predecessor specimens remain excluded: " + path)
	for path in ["res://tests/fixtures/rc033/enemies.json", "res://tests/fixtures/rc033/encounter.json", "res://tests/fixtures/rc033/loadouts.json", "res://tests/helpers/rc033_fixture.gd", "res://tests/rc033_manual.gd", "res://tests/rc033_ui_runner.gd"]:
		check(not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".remap") and not FileAccess.file_exists(path + "c"), "RC-033 framework fixtures and QA remain excluded: " + path)
	var catalogue = load("res://scripts/audio/audio_catalogue.gd")
	check(catalogue != null, "Shipped GDScript audio metadata loads without documentation")
	if catalogue == null:
		_finish()
		return
	check(catalogue.SFX.size() == 21, "Exactly 21 SFX metadata entries")
	for entry in catalogue.SFX.values():
		var stream = load(entry.runtime_path)
		check(stream is AudioStreamWAV and stream.get_length() > 0.0, "Packed WAV imports and decodes: " + entry.runtime_path)
	check(catalogue.LOOPS.home_exploration.runtime_path == "" and catalogue.LOOPS.combat.runtime_path == "", "Pending music has no loadable path")
	var crypt = load(catalogue.LOOPS.crypt.runtime_path)
	check(crypt is AudioStreamOggVorbis, "Crypt remains a compressed Vorbis resource")
	if crypt is AudioStreamOggVorbis:
		check(crypt.loop and is_zero_approx(crypt.loop_offset), "Crypt retains full-file looping at zero offset")
		check(crypt.get_length() > 0.0, "Packed crypt has nonzero decoded duration")
	var font = load("res://assets/fonts/ui/NotoSerif-Variable.ttf")
	check(font is FontFile and font.get_height(24) > 0.0, "Packed Noto Serif font loads")
	for path in ["res://assets/fonts/ATTRIBUTION.txt", "res://assets/fonts/ui/OFL.NotoSerif.txt"]:
		check(FileAccess.file_exists(path) and not FileAccess.get_file_as_string(path).is_empty(), "Required font attribution exists: " + path)
	for path in ["res://assets/ui/combat/reference/approved-atlas.png", "res://assets/ui/combat/reference/status-frame.png", "res://assets/ui/combat/reference/icons.png", "res://assets/environments/crypt/reference/arena.png", "res://assets/environments/home/home_tower.png", "res://assets/ui/wordmark.png", "res://assets/ui/map/parchment.png"]:
		var texture = load(path)
		check(texture is Texture2D and texture.get_width() > 0, "Live reference texture decodes: " + path)
	for path in ["res://assets/enemies/shadeling/attachments.tres", "res://assets/enemies/shadeling/motion.tres", "res://assets/ui/rune_cast_theme.tres", "res://assets/ui/styles/modal_panel.tres", "res://scenes/vfx/combat_feedback_style.tres"]:
		check(load(path) is Resource, "Production resource loads: " + path)
	var packed = load("res://scenes/main.tscn")
	check(packed is PackedScene, "Production scene loads")
	if not packed is PackedScene:
		_finish()
		return
	var scene = packed.instantiate()
	scene.settings_path = "user://export-payload-probe-settings.cfg"
	root.add_child(scene)
	await process_frame
	check(scene.startup_error == "" and scene.controller != null, "Packed production definitions and runtime start playable combat")
	if scene.controller != null:
		var intent_snapshot: Dictionary = scene.controller.snapshot()
		check(intent_snapshot.enemy_action.amount == 8 and intent_snapshot.enemy_action.sequence == [8, 12, 6] and intent_snapshot.enemy_action.sequence_index == 0, "Packed Shadeling keeps its authoritative opening attack and repeating sequence")
		check(scene.arena.intent_button is Button and not scene.arena.intent_button.disabled, "Packed intent has a touch inspection affordance")
		scene._inspect_intent()
		check(scene.inspector.visible and scene.inspector_text.text.contains("8"), "Packed intent inspection opens the established read-only popup")
		check(scene.controller.snapshot() == intent_snapshot, "Packed intent inspection does not mutate Combat")
	check(scene.audio != null, "Production audio coordinator exists")
	if scene.audio != null:
		check(scene.audio._ambience.player.stream is AudioStreamOggVorbis, "Production coordinator selects packed crypt")
		scene.audio.dispose()
	scene.queue_free()
	await process_frame
	# The normal entry is Home, while main.tscn intentionally remains the isolated
	# Combat fixture above. Exercise both from the exact shipped payload.
	check(load("res://scripts/core/run_state.gd") is GDScript, "Run-owned state model is packaged")
	check(load("res://scripts/core/store_policy.gd") is GDScript, "Between-room Store transaction policy is packaged")
	check(load("res://scripts/ui/store_viewer.gd") is GDScript, "Between-room Store presentation is packaged")
	check(load("res://scripts/ui/run_review.gd") is GDScript, "Final results and run-details presentation are packaged")
	check(load("res://scripts/core/local_save.gd") is GDScript, "Versioned durable save transaction owner is packaged")
	check(load("res://scripts/core/shop_policy.gd") is GDScript, "Registered shop policy is packaged separately from Combat configuration")
	check(load("res://scripts/core/instance_effects.gd") is GDScript, "Shared validated per-instance upgrade resolver is packaged")
	check(load("res://scripts/core/relic_policy.gd") is GDScript, "Six bounded run relic hooks are packaged")
	check(load("res://scripts/core/service_policy.gd") is GDScript, "Versioned current and historical service policies are packaged")
	check(load("res://scripts/ui/service_viewer.gd") is GDScript, "Integrated service room screen is packaged")
	check(load("res://scripts/ui/shop_viewer.gd") is GDScript, "Route shop main screen is packaged")
	check(load("res://scripts/core/progression_state.gd") is GDScript, "Persistent definition unlock ownership is packaged")
	check(load("res://scripts/core/route_state.gd") is GDScript, "Versioned route model is packaged")
	check(load("res://scripts/core/encounter_resolver.gd") is GDScript, "Bounded encounter resolver is packaged")
	check(load("res://scripts/ui/reward_viewer.gd") is GDScript, "Reward transaction presentation is packaged")
	check(load("res://scripts/ui/collection_viewer.gd") is GDScript, "Read-only collection viewer is packaged")
	check(load("res://scripts/ui/collection_data.gd") is GDScript, "Detached collection presentation data is packaged")
	check(load("res://scripts/ui/route_map.gd") is GDScript, "Live route Map is packaged")
	check(load("res://scripts/ui/route_map_node.gd") is GDScript, "Live Map node states are packaged")
	check(load("res://scripts/ui/route_map_chrome.gd") is GDScript, "Map frame and scenery renderer are packaged")
	check(load("res://scenes/ui/theme/navigation_bar.gd") is GDScript, "Shared Combat and Map navigation is packaged")
	check(load("res://scenes/ui/theme/modal_panel.gd") is GDScript, "Shared navy modal panel renderer is packaged")
	check(load("res://scenes/ui/theme/combat_surface.gd") is GDScript, "Current navigation corner mask and navy surfaces are packaged")
	var navigation_script = load("res://scenes/ui/theme/navigation_bar.gd")
	var navigation = navigation_script.new()
	navigation.size = Vector2(640, 82)
	root.add_child(navigation)
	navigation.set_selected("map")
	await process_frame
	var nav_surface = navigation.get_meta("combat_surface")
	check(navigation.size.y == 82 and navigation_script.BUTTON_HEIGHT == 82, "Packed shared navigation preserves the 82-pixel contract")
	check(nav_surface.get_geometry().mask_polygon.size() == 8, "Packed navigation includes the corrected eight-corner silhouette")
	var modal_style = load("res://assets/ui/styles/modal_panel.tres")
	check(modal_style.get_script() == load("res://scenes/ui/theme/modal_panel.gd"), "Packed modal style binds the shared navy-body renderer")
	navigation.queue_free()
	await process_frame
	check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/application.tscn", "Exported project launches the application shell")
	var application_pack = load("res://scenes/application.tscn")
	check(application_pack is PackedScene, "Application shell scene loads")
	if not application_pack is PackedScene:
		call_deferred("_finish")
		return
	var application = application_pack.instantiate()
	application.settings_path = "user://export-shell-probe-settings.cfg"
	application.save_path = "user://export-shell-probe-save.json"
	root.add_child(application)
	await process_frame
	check(application.home.is_visible_in_tree() and application.combat_scene == null and application.run_state == null, "Packed application starts at Home without an active session")
	check(_playing_loops(application) == 0, "Initial Home has no crypt ambience or substitute music")
	application.request_new_run(24024)
	await process_frame
	check(application.run_state != null and application.combat_scene == null and application.map_screen != null and application.map_screen.visible, "Packed New Run opens its authoritative fresh Map")
	if application.map_screen == null:
		application.queue_free()
		await process_frame
		call_deferred("_finish")
		return
	var route_snapshot: Dictionary = application.run_state.snapshot()
	check(application.run_state.route_snapshot().visit_count == 0, "Packed New Run does not fabricate visited rooms")
	check(_playing_loops(application) == 0, "Home-to-Map does not start unrelated crypt ambience")
	application.map_screen.menu_requested.emit()
	application.open_store()
	await process_frame
	check(not application.route_menu_store.disabled and application.store_screen.visible, "Packed settled Map opens Store through the default application shell")
	var supplies: Dictionary = application.store_screen.presentation
	check(supplies == application.run_state.store_snapshot() and supplies.enabled and supplies.relics.size() == 6 and supplies.runes.size() == 4, "Packed Store displays the authoritative four unlocked runes and six relics")
	check(supplies.runes.all(func(item): return item.cost == 45 and not item.enabled) and supplies.relics.all(func(item): return item.cost == 90 and not item.enabled), "Packed Store preserves accepted prices and disables unaffordable purchases")
	application._store_purchase_requested(supplies.identity, "rune", "spark")
	application.confirm_store_purchase()
	check(application.run_state.snapshot() == route_snapshot and not application.confirmation.visible, "Packed zero-Gold Store rejects purchase callbacks without ownership or route mutation")
	application.close_store()
	check(not application.store_screen.visible and application.route_menu.visible, "Packed Store Back preserves its retained Map Menu")
	application._close_route_menu()
	var entry_node: String = application.run_state.route_snapshot().entry_node_ids[0]
	application.map_screen.inspect_node(entry_node)
	application.request_node_entry(entry_node)
	check(application.confirmation.visible, "Packed Map offers separate room entry confirmation")
	application.confirm_node_entry()
	check(application.run_state.snapshot() == route_snapshot and application.combat_scene == null, "Packed unsupported room reports pending without consuming route state")
	application.close_map()
	application.continue_run()
	check(application.map_screen.visible and application.run_state.snapshot() == route_snapshot, "Packed Continue reopens the same deterministic route")
	application.close_map()
	application.queue_free()
	await process_frame
	application = application_pack.instantiate()
	application.settings_path = "user://export-shell-probe-settings.cfg"
	application.save_path = "user://export-shell-probe-save.json"
	root.add_child(application)
	await process_frame
	check(application.run_state != null and application.run_state.snapshot() == route_snapshot, "Packaged save owner restores the exact persisted route and profile in a new shell")
	application.continue_run()
	check(application.map_screen != null and application.map_screen.visible, "Packaged persisted Continue opens the restored Map")
	application.close_map()
	# This decode probe, excluded from production exports, injects the explicit
	# standalone encounter to retain RC-024 checkpoint/audio lifetime coverage.
	var run_script = load("res://scripts/core/run_state.gd")
	var content_loader = load("res://scripts/core/content_loader.gd")
	var resolver = load("res://scripts/core/encounter_resolver.gd").new()
	var combat_script = load("res://scripts/core/combat.gd")
	application.run_state = run_script.new(content_loader.load_setup().setup, 24024)
	application.persistence_context = application.run_state.restore_context_for_tests()
	var owned_entry: Dictionary = application.run_state._entry_data()
	for selection in [
		{"encounter_id": "training_shadeling", "enemy_id": "shadeling", "encounter_role": "boss", "board_id": "board_gallery"},
		{"encounter_id": "rc007_entry_probe_next", "enemy_id": "dev_calibration_wisp", "encounter_role": "development", "board_id": "board_ossuary"}
	]:
		var resolved: Dictionary = resolver.resolve(selection, owned_entry)
		check(resolved.get("ok", false), "Packed resolver loads one supported encounter: " + selection.encounter_id)
		if resolved.get("ok", false):
			var candidate: Dictionary = combat_script.create_for_run(resolved.setup, resolved.entry)
			check(candidate.ok, "Packed encounter constructs a real run-owned Combat model")
			if candidate.ok:
				var battle: Dictionary = candidate.combat.snapshot()
				check(battle.encounter.enemy_id == selection.enemy_id and battle.encounter.board_id == selection.board_id and battle.encounter.encounter_role == selection.encounter_role, "Packed encounter preserves selected enemy, board and role")
				check(candidate.combat.run_handoff().owned_cards == owned_entry.owned_cards and battle.player_hp == 30 and battle.encounter.player_max_health == 30, "Packed selected loadout keeps authoritative run health and original permanent instances")
			check(resolved.pending_choices == ["encounter_rewards"], "Packed production resolver retains required choices without granting rewards")
	check(application.run_state._entry_data() == owned_entry, "Packed encounter preparation leaves the committed run entry unchanged")
	var entered: Dictionary = application.run_state.enter_battle()
	check(entered.ok, "Isolated standalone battle fixture enters through the shipped model")
	if not entered.ok:
		application.queue_free()
		await process_frame
		call_deferred("_finish")
		return
	application._attach_battle(entered.combat)
	await process_frame
	var combat = application.combat_scene
	var entry_snapshot: Dictionary = combat.controller.snapshot()
	application.open_collection()
	await process_frame
	check(application.collection_screen.visible and application.collection_screen.presentation.owned_count == 8, "Packed collection shows eight authoritative starter instances")
	application.close_collection()
	check(application.combat_scene == combat and combat.controller.snapshot() == entry_snapshot, "Packed collection closes without recreating or mutating Combat")
	check(combat.audio != null and combat.audio.loop_snapshot().ambience.cue == "crypt", "Application Combat selects packed crypt ambience")
	var ambience_starts: int = combat.audio.loop_starts.ambience
	application.open_map()
	check(application.map_screen.visible and application.combat_scene == combat, "Packed active-battle Map retains the exact Combat scene")
	application.close_map()
	check(combat.controller.snapshot() == entry_snapshot and combat.audio.loop_starts.ambience == ambience_starts, "Packed Map returns without replaying entry or restarting ambience")
	application.request_home()
	check(application.confirmation.visible and application.combat_scene == combat, "Quit-to-Home explains replay before disposing Combat")
	application.confirm_home()
	await process_frame
	check(application.combat_scene == null and application.home.is_visible_in_tree() and application.run_state != null, "Confirmed Home return retains the session without an active Combat scene")
	check(_playing_loops(application) == 0, "Returning Home disposes crypt ambience")
	application.continue_run()
	await process_frame
	check(application.combat_scene != null and application.combat_scene.controller != null, "Persistent Continue starts the retained encounter")
	check(application.combat_scene != null and application.combat_scene.controller.snapshot() == entry_snapshot, "Packed Continue replays the unchanged encounter-entry state")
	application.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	# Let this coroutine release its local resource references before shutdown.
	call_deferred("_finish")

func _playing_loops(node: Node) -> int:
	var count := 0
	if node is AudioStreamPlayer and node.playing and node.stream is AudioStreamOggVorbis:
		count += 1
	for child in node.get_children():
		count += _playing_loops(child)
	return count

func _finish() -> void:
	print("%d %s payload desktop decode checks, %d failures" % [checks, payload_label, failures])
	quit(0 if failures == 0 else 1)
