extends RefCounted

const ACTOR = preload("res://assets/enemies/shadeling/character.tscn")
const ENVELOPE := Rect2(-232, -416, 464, 448)
const POSE_BOUNDS := {
	&"neutral": Rect2(-202.666667, -370.666667, 349.333334, 374.666667),
	&"attack": Rect2(-227, -362, 447, 364),
	&"hit": Rect2(-171, -362, 338, 364),
}

func run(check: Callable, tree: SceneTree) -> void:
	var actor = ACTOR.instantiate()
	actor.reference_neutral = true
	tree.root.add_child(actor)
	await tree.process_frame
	actor.set_idle_enabled(false)
	var sprite: Sprite2D = actor.pose_sprite
	var atlas: Texture2D = sprite.texture
	var atlas_region := sprite.region_rect
	var atlas_scale := sprite.scale
	var atlas_position := sprite.position
	var neutral_head: Vector2 = actor.get_attachment_position(&"head")
	check.call(sprite.region_enabled and sprite.region_filter_clip_enabled and sprite.material is ShaderMaterial,
		"RC-017 production neutral starts on the approved atlas with its silhouette material.")
	check.call(neutral_head.is_equal_approx(Vector2(-28, -305.333333)) and actor.get_attachment_position(&"foot") == Vector2.ZERO,
		"RC-017 neutral head uses approved source coordinates and the shared foot stays the root origin.")
	for state in [&"attack", &"hit", &"defeat"]:
		for reduced in [false, true]:
			for phase in [0.0, 0.14, 0.28, 0.50, 0.72, 0.90, 1.0]:
				check.call(actor.sample_presentation(state, phase, reduced), "RC-017 actor accepts deterministic %s %.2f reduced=%s." % [state, phase, reduced])
				check.call(not actor.is_processing(), "RC-017 sampled actor owns no autonomous playback callback.")
				var pose: StringName = actor.get_pose()
				var bounds: Rect2 = POSE_BOUNDS[pose]
				var transformed: Rect2 = actor.pose_root.transform * bounds
				check.call(ENVELOPE.grow(0.01).encloses(transformed), "RC-017 %s %.2f retains lantern/cloak inside the declared pose envelope." % [state, phase])
				if reduced:
					check.call(actor.pose_root.transform.is_equal_approx(Transform2D.IDENTITY), "RC-017 reduced motion removes actor rotation, scaling and travel.")
					check.call(pose == &"neutral", "RC-017 reduced motion retains the neutral silhouette during attack, hit and terminal fade.")
				if pose != &"neutral":
					check.call(not sprite.region_enabled and sprite.region_rect == Rect2() and sprite.material == null and sprite.scale == Vector2.ONE and sprite.position == Vector2(-256, -448),
						"RC-017 full-texture pose clears the atlas region, mask and imported-atlas scale.")
				# Simulate effect tint, hidden sprite and transform contamination
				# before cancellation; reset must restore the full neutral contract.
				actor.pose_root.hide()
				actor.pose_root.self_modulate = Color.RED
				sprite.hide()
				sprite.modulate = Color.GREEN
				sprite.self_modulate = Color.BLUE
				sprite.rotation = 0.2
				sprite.skew = 0.1
				sprite.flip_h = true
				sprite.flip_v = true
				actor.reset_presentation("playing", true)
				check.call(sprite.texture == atlas and sprite.region_enabled and sprite.region_filter_clip_enabled and sprite.region_rect == atlas_region and sprite.scale == atlas_scale and sprite.position == atlas_position and sprite.material is ShaderMaterial,
					"RC-017 cancellation restores the approved atlas, exact region, scale, mask and placement.")
				check.call(sprite.visible and actor.pose_root.visible and sprite.modulate == Color.WHITE and sprite.self_modulate == Color.WHITE and actor.pose_root.modulate == Color.WHITE and actor.pose_root.self_modulate == Color.WHITE and is_zero_approx(sprite.rotation) and is_zero_approx(sprite.skew) and not sprite.flip_h and not sprite.flip_v,
					"RC-017 cancellation restores opacity, colour, visibility and sprite orientation.")
				check.call(actor.get_attachment_position(&"head").is_equal_approx(neutral_head) and actor.get_attachment_position(&"foot") == Vector2.ZERO,
					"RC-017 cancellation restores pose-specific attachments and the fixed foot.")
	actor.sample_presentation(&"attack", 0.5)
	actor.position = Vector2(37, 41)
	actor.scale = Vector2.ONE * 0.6
	for name in [&"head", &"body_center", &"attack_origin", &"lantern_pivot", &"foot"]:
		check.call(actor.to_global(actor.get_attachment_position(name)).is_equal_approx(actor.get_attachment_position(name, true)),
			"RC-017 %s attachment agrees in global and foot-local space after arena scaling." % name)
	actor.reset_presentation("victory")
	var terminal: Dictionary = actor.get_visual_sample()
	check.call(actor.get_state() == &"defeat" and is_zero_approx(actor.pose_root.modulate.a) and not actor.is_processing(),
		"RC-017 victory leaves the defeated enemy hidden and stopped.")
	await tree.process_frame
	check.call(actor.get_visual_sample() == terminal and is_zero_approx(actor.pose_root.modulate.a),
		"RC-017 victory cannot automatically return to idle on the next frame.")
	actor.reset_presentation("defeat")
	check.call(actor.get_pose() == &"neutral" and actor.pose_root.modulate == Color.WHITE and not actor.is_processing(),
		"RC-017 player defeat keeps the surviving enemy neutral with no idle loop.")
	actor.reset_presentation("playing")
	check.call(actor.is_processing(), "RC-017 playing starts nonblocking production idle.")
	actor._process(0.5)
	check.call(absf(actor.pose_root.scale.y - 1.0) <= 0.00401 and actor.pose_root.position == Vector2.ZERO,
		"RC-017 idle stays foot-rooted with less than three design-pixel head movement.")
	actor.reset_presentation("playing", true)
	check.call(not actor.is_processing() and actor.pose_root.transform == Transform2D.IDENTITY,
		"RC-017 reduced idle schedules no process work and restores an exact stationary pose.")
	var before_invalid: Dictionary = actor.get_visual_sample()
	check.call(not actor.sample_presentation(&"dodge", 0.5) and not actor.sample_presentation(&"hit", NAN) and actor.get_visual_sample() == before_invalid,
		"RC-017 rejects invented dodge and nonfinite sampling without altering the actor.")
	actor.reset_presentation("playing")
	tree.root.remove_child(actor)
	check.call(not actor.is_processing(), "RC-017 actor teardown stops idle immediately.")
	actor.free()
