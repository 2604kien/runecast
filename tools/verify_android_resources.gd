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
	for path in ["res://docs/audio-cue-catalogue.json", "res://docs/audio-loop-catalogue.json", "res://tests/audio_export_probe.gd", "res://tools/godot.ps1"]:
		check(not FileAccess.file_exists(path), "Development-only dependency absent: " + path)
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
	for path in ["res://assets/ui/combat/reference/approved-atlas.png", "res://assets/ui/combat/reference/status-frame.png", "res://assets/ui/combat/reference/icons.png", "res://assets/environments/crypt/reference/arena.png", "res://assets/environments/home/home_tower.png", "res://assets/ui/wordmark.png"]:
		var texture = load(path)
		check(texture is Texture2D and texture.get_width() > 0, "Live reference texture decodes: " + path)
	for path in ["res://assets/enemies/shadeling/attachments.tres", "res://assets/enemies/shadeling/motion.tres", "res://assets/ui/rune_cast_theme.tres", "res://scenes/vfx/combat_feedback_style.tres"]:
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
	check(scene.audio != null, "Production audio coordinator exists")
	if scene.audio != null:
		check(scene.audio._ambience.player.stream is AudioStreamOggVorbis, "Production coordinator selects packed crypt")
		scene.audio.dispose()
	scene.queue_free()
	await process_frame
	# The normal entry is Home, while main.tscn intentionally remains the isolated
	# Combat fixture above. Exercise both from the exact shipped payload.
	check(load("res://scripts/core/run_state.gd") is GDScript, "Run-owned state model is packaged")
	check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/application.tscn", "Exported project launches the application shell")
	var application_pack = load("res://scenes/application.tscn")
	check(application_pack is PackedScene, "Application shell scene loads")
	if not application_pack is PackedScene:
		call_deferred("_finish")
		return
	var application = application_pack.instantiate()
	application.settings_path = "user://export-shell-probe-settings.cfg"
	root.add_child(application)
	await process_frame
	check(application.home.is_visible_in_tree() and application.combat_scene == null and application.run_state == null, "Packed application starts at Home without an active session")
	check(_playing_loops(application) == 0, "Initial Home has no crypt ambience or substitute music")
	application.request_new_run(24024)
	await process_frame
	check(application.run_state != null and application.combat_scene != null and application.combat_scene.controller != null, "Packed Home starts an authoritative run and playable Combat")
	if application.combat_scene == null:
		application.queue_free()
		await process_frame
		call_deferred("_finish")
		return
	var combat = application.combat_scene
	var entry_snapshot: Dictionary = combat.controller.snapshot()
	check(combat.audio != null and combat.audio.loop_snapshot().ambience.cue == "crypt", "Application Combat selects packed crypt ambience")
	application.request_home()
	check(application.confirmation.visible and application.combat_scene == combat, "Quit-to-Home explains replay before disposing Combat")
	application.confirm_home()
	await process_frame
	check(application.combat_scene == null and application.home.is_visible_in_tree() and application.run_state != null, "Confirmed Home return retains the session without an active Combat scene")
	check(_playing_loops(application) == 0, "Returning Home disposes crypt ambience")
	application.continue_run()
	await process_frame
	check(application.combat_scene != null and application.combat_scene.controller != null, "Session-only Continue starts the retained encounter")
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
