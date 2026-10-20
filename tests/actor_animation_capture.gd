extends SceneTree
## Supplemental RC-017 compositing/clearance evidence; actual Combat sequences
## are captured separately by the production presentation integration tests.

const Arena = preload("res://scripts/ui/arena.gd")
const DESTINATION := "res://output/qa/rc-017/actor"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(841, 590)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var arena := Arena.new()
	arena.reference_art = true
	arena.enemy_id = "shadeling"
	arena.enemy_name = "Shadeling"
	arena.enemy_hp = 32
	arena.enemy_max_hp = 32
	arena.attack = 8
	arena.battle_state = "playing"
	arena.size = Vector2(841, 490)
	viewport.add_child(arena)
	await process_frame
	await process_frame
	var prefix := "before-" if "--baseline" in OS.get_cmdline_user_args() else ""
	arena.actor.show_pose(&"neutral")
	await _save(viewport, prefix + "neutral")
	arena.actor.show_pose(&"attack")
	await _save(viewport, prefix + "attack")
	arena.actor.show_pose(&"hit")
	await _save(viewport, prefix + "hit")
	arena.actor.pose_root.hide()
	await _save(viewport, prefix + "revealed-scenery")
	if prefix.is_empty():
		# In the fully clean center the composited environment must equal the
		# empty plate alone, including outside the old actor's polygon. This
		# catches both a baked duplicate and the old silhouette-shaped seam.
		await RenderingServer.frame_post_draw
		var revealed := viewport.get_texture().get_image()
		arena.environment.get_layer_nodes()[1].hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var empty_plate := viewport.get_texture().get_image()
		var maximum_error := 0.0
		var samples := 0
		for y in range(35, 386):
			for x in range(281, 569):
				var difference := revealed.get_pixel(x, y) - empty_plate.get_pixel(x, y)
				maximum_error = maxf(maximum_error, maxf(absf(difference.r), maxf(absf(difference.g), absf(difference.b))))
				samples += 1
		var report := FileAccess.open(DESTINATION.path_join("scenery-proof.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify({"samples": samples, "maximum_rgb_error": maximum_error, "pass": maximum_error <= 1.0 / 255.0, "method": "Actual Godot composite versus existing clean plate only throughout fixed center; includes points outside the old neutral silhouette."}, "  ") + "\n")
		assert(maximum_error <= 1.0 / 255.0, "Scenery retains pixels outside the clean plate inside the cleared center")
		arena.environment.get_layer_nodes()[1].show()
		arena.actor.pose_root.show()
		arena.actor.show_pose(&"neutral")
		var overlay := Control.new()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 24
		arena.add_child(overlay)
		overlay.draw.connect(func():
			# Shared stage guard boxes, not silhouettes or proposed actor sizes.
			var envelopes := [Rect2(272, 56, 348, 336), Rect2(278, 56, 336, 336)]
			for i in envelopes.size():
				overlay.draw_rect(envelopes[i], Color(0.25 + i * 0.65, 1.0 - i * 0.35, 0.9 - i * 0.65), false, 2.0)
			var font := ThemeDB.fallback_font
			var labels := ["SHADELING complete pose envelope", "PROXY ONLY: future packs use this stage guard", "Wickling / Stone Sentinel / Chain Warden / Bell Keeper", "No future silhouettes or sizes are approved by these boxes."]
			for i in labels.size():
					overlay.draw_string(font, Vector2(18, 500 + i * 20), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			overlay.draw_line(Vector2(200, 368), Vector2(685, 368), Color(1, 0.8, 0.1), 1.0)
		)
		overlay.queue_redraw()
		await _save(viewport, "future-proxy-clearance")
	viewport.queue_free()
	await process_frame
	quit()

func _save(viewport: SubViewport, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(DESTINATION.path_join(name + ".png"))
