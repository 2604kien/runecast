extends RefCounted
const Settings = preload("res://scripts/audio/audio_settings.gd")

func run(check: Callable, tree: SceneTree) -> void:
	var path := "res://output/qa/rc-020/settings-test-%d.cfg" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var config := ConfigFile.new()
	config.set_value("audio", "enabled", false)
	config.set_value("audio", "future_audio_key", "keep")
	config.set_value("accessibility", "reduced_motion", true)
	config.set_value("accessibility", "high_contrast", true)
	config.set_value("unrelated", "seed", 314)
	check.call(config.save(path) == OK, "Audio migration fixture saves to an isolated test path.")
	var values := Settings.load_values(path)
	check.call(not values.enabled and values.music_volume == 1.0 and values.sfx_volume == 1.0,
		"Legacy audio.enabled remains the master preference; independent levels default to full catalogue gain.")
	check.call(not values.music_muted and not values.sfx_muted and values.reduced_motion,
		"Migration defaults both individual mutes off and preserves reduced motion.")
	config.load(path)
	check.call(not config.has_section_key("audio", "music_volume"), "Opening settings performs read-only migration without rewriting preferences.")
	values.music_volume = 0.37
	values.sfx_volume = 0.62
	values.sfx_muted = true
	check.call(Settings.save_values(values, path) == OK, "New independent audio settings persist.")
	check.call(Settings.load_values(path) == values, "All independent audio fields round-trip without losing muted levels.")
	config.load(path)
	check.call(config.get_value("audio", "future_audio_key") == "keep" and config.get_value("accessibility", "high_contrast") and config.get_value("unrelated", "seed") == 314,
		"Saving audio and reduced-motion controls preserves unknown audio, accessibility and other-section keys.")
	var sanitized := Settings.normalize({"music_volume": -0.5, "sfx_volume": 4.0, "enabled": "false", "music_muted": "yes", "reduced_motion": true})
	check.call(sanitized.music_volume == 0.0 and sanitized.sfx_volume == 1.0 and sanitized.enabled and not sanitized.music_muted and sanitized.reduced_motion,
		"Out-of-range levels clamp and malformed preference types return safe defaults.")
	check.call(Settings.normalize({"music_volume": NAN, "sfx_volume": INF}).music_volume == 1.0 and Settings.normalize({"sfx_volume": INF}).sfx_volume == 1.0,
		"Nonfinite persisted levels never reach the mixer.")
	values.enabled = true
	values.sfx_muted = false
	values.reduced_motion = false
	Settings.save_values(values, path)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = path
	tree.root.add_child(scene)
	await tree.process_frame
	scene.audio.trace_enabled = true
	check.call(scene.sound_enabled and scene.audio_settings.music_volume == 0.37 and scene.audio_settings.sfx_volume == 0.62,
		"The actual Combat scene loads independent preferences before creating its single audio owner.")
	scene.set_reduced_motion(true)
	scene._toggle_sound()
	check.call(scene.reduced_motion and not Settings.load_values(path).reduced_motion,
		"A runtime reduced-motion override is not persisted by an unrelated Sound change.")
	scene.set_reduced_motion(false)
	scene._toggle_sound()
	var coordinator_id: int = scene.audio.get_instance_id()
	var loop_starts: Dictionary = scene.audio.loop_starts.duplicate()
	scene._open_menu()
	scene.menu.custom_action.emit("options")
	check.call(scene.options.visible and not scene.menu.visible and not scene._can_edit(), "Menu Options opens the reusable surface and prevents background gameplay input.")
	check.call(scene.options.sliders.music_volume.value == 37 and scene.options.sliders.sfx_volume.value == 62,
		"Reused Options sliders display the stored independent levels.")
	var count_before: int = scene.audio.trace.size()
	scene.options.set_values(scene.audio_settings)
	scene._refresh()
	check.call(scene.audio.trace.size() == count_before and scene.audio.get_instance_id() == coordinator_id,
		"Rebinding options and refreshing Combat creates no UI cue or replacement audio coordinator.")
	var initial_state: Dictionary = scene.controller.snapshot()
	scene._cast()
	scene._cell_pressed(0)
	check.call(scene.controller.snapshot() == initial_state, "Options keeps direct background action handlers from changing combat.")
	scene.options.sliders.music_volume.value = 24
	scene.options.sliders.sfx_volume.value = 71
	check.call(is_equal_approx(scene.audio_settings.music_volume, 0.24) and is_equal_approx(scene.audio_settings.sfx_volume, 0.71) and scene.audio.trace.size() == count_before,
		"Actual volume controls save their own values without generating repeated slider-preview cues.")
	scene.options.toggles.music_muted.button_pressed = true
	check.call(scene.audio_settings.music_muted and not scene.audio_settings.sfx_muted and scene.audio_settings.music_volume == 0.24,
		"The Music mute control preserves its level and leaves SFX independent.")
	scene.options.toggles.sfx_muted.button_pressed = true
	check.call(scene.audio_settings.sfx_muted and scene.audio.active_voice_count() == 0, "The SFX mute control immediately clears active effects.")
	scene._toggle_sound()
	check.call(not scene.sound_enabled and scene.audio_settings.music_volume == 0.24 and scene.audio_settings.sfx_volume == 0.71 and scene.audio_settings.music_muted and scene.audio_settings.sfx_muted,
		"The existing Sound shortcut is a master mute that preserves both levels and individual mute choices.")
	count_before = scene.audio.trace.size()
	scene._toggle_sound()
	check.call(scene.sound_enabled and scene.audio.active_voice_count() == 0 and scene.audio.trace.size() == count_before,
		"Master unmute honors an individually muted SFX channel without replaying old effects.")
	scene.options.toggles.reduced_motion.button_pressed = true
	check.call(scene.reduced_motion and scene.animation_presenter.reduced_motion and scene.audio_settings.reduced_motion,
		"Options reduced motion updates both presentation and audio arbitration without changing Sound.")
	scene._close_options()
	check.call(scene.menu.visible and not scene.options.visible, "Closing Options returns to its existing Menu without navigating away from Combat.")
	scene._open_options()
	check.call(scene.options.sliders.music_volume.value == 24 and scene.options.sliders.sfx_volume.value == 71 and scene.options.toggles.sfx_muted.button_pressed,
		"Reopening Options retains levels and mutes.")
	check.call(scene.audio.loop_starts == loop_starts, "Menu and Options do not restart the compatible crypt ambience loop.")
	check.call(Settings.load_values(path) == scene.audio_settings, "Playable Options changes persist in the existing ConfigFile format.")
	config.load(path)
	check.call(config.get_value("unrelated", "seed") == 314 and config.get_value("accessibility", "high_contrast"),
		"Playable control changes preserve unrelated preferences.")
	# Godot's audio thread releases stopped stream playback objects asynchronously.
	scene.audio.dispose()
	await tree.create_timer(0.15).timeout
	scene.queue_free()
	await tree.process_frame
	DirAccess.remove_absolute(path)
