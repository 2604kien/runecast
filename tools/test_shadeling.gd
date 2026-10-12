extends RefCounted
## Focused isolated resource/state checks, callable by the RC-014 preview runner.

func run(tree: SceneTree) -> Dictionary:
	var errors: Array[String] = []
	var checks: Array[String] = []
	var packed := load("res://assets/enemies/shadeling/character.tscn") as PackedScene
	if packed == null:
		return {"result": "FAIL", "checks": [], "errors": ["Character scene cannot load"]}
	var actor = packed.instantiate()
	tree.root.add_child(actor)
	await tree.process_frame
	_check(actor.get_pose() == &"neutral", "Default scene is neutral", checks, errors)
	_check(not actor.is_processing(), "Default scene does not autoplay", checks, errors)
	_check(actor.get_retained_pose_names() == [&"neutral"], "Default retains one full pose", checks, errors)
	_check(actor.get_attachment_position(&"foot") == Vector2.ZERO, "Foot origin is exactly zero", checks, errors)
	_check(actor.get_node("PoseRoot/FullPose").position == Vector2(-256, -448), "Full canvas retains shared offset", checks, errors)
	_check(not actor.get_node("ContactShadow").visible, "Optional contact shadow starts disabled", checks, errors)
	for pose in [&"neutral", &"attack", &"hit"]:
		_check(actor.show_pose(pose), "Static pose loads: " + String(pose), checks, errors)
		var sprite: Sprite2D = actor.get_node("PoseRoot/FullPose")
		_check(sprite.texture != null and sprite.texture.get_size() == Vector2(512, 512),
			"Imported canvas is 512 square: " + String(pose), checks, errors)
		_check(actor.get_retained_pose_names() == [pose], "Pose switching releases prior scene reference: " + String(pose), checks, errors)
		_check(actor.get_node("PoseRoot").transform == Transform2D.IDENTITY,
			"Static pose resets transform: " + String(pose), checks, errors)
		for attachment in [&"head", &"body_center", &"attack_origin", &"lantern_pivot"]:
			var point: Vector2 = actor.get_attachment_position(attachment)
			_check(point.is_finite() and point.y < 0.0,
				"Finite above-foot attachment: " + String(pose) + "/" + String(attachment), checks, errors)
	var finished: Array[StringName] = []
	actor.preview_state_finished.connect(func(state: StringName): finished.append(state))
	for restrained in [false, true]:
		for state in [&"idle", &"attack", &"hit", &"defeat"]:
			var duration: float = actor.DURATIONS[state]
			for sample in [0.0, duration * 0.25, duration * 0.5, duration * 0.75, duration]:
				_check(actor.sample_state(state, sample, restrained),
					"State samples: %s %.3f reduced=%s" % [state, sample, restrained], checks, errors)
				_check(actor.get_attachment_position(&"foot") == Vector2.ZERO and actor.get_node("PoseRoot").position == Vector2.ZERO,
					"Study preserves foot origin", checks, errors)
				if restrained:
					_check(actor.get_node("PoseRoot").transform == Transform2D.IDENTITY,
						"Reduced motion has no transform movement", checks, errors)
				var first: Dictionary = actor.get_visual_sample()
				actor.sample_state(state, sample, restrained)
				_check(first == actor.get_visual_sample(), "Repeated deterministic seek is identical", checks, errors)
		_check(actor.sample_state(&"idle", 0.0, restrained), "Idle start loads", checks, errors)
		var idle_start: Transform2D = actor.get_node("PoseRoot").transform
		actor.sample_state(&"idle", actor.DURATIONS[&"idle"], restrained)
		_check(actor.get_node("PoseRoot").transform.is_equal_approx(idle_start), "Idle loop endpoint matches start", checks, errors)
		for state in [&"attack", &"hit"]:
			actor.sample_state(state, actor.DURATIONS[state], restrained)
			_check(actor.get_pose() == &"neutral" and actor.get_node("PoseRoot").transform.is_equal_approx(Transform2D.IDENTITY),
				"One-shot endpoint settles to neutral: " + String(state), checks, errors)
		actor.sample_state(&"defeat", actor.DURATIONS[&"defeat"], restrained)
		var defeated_transform: Transform2D = actor.get_node("PoseRoot").transform
		actor.sample_state(&"defeat", 100.0, restrained)
		_check(actor.get_pose() == &"hit" and actor.get_state() == &"defeat" and actor.get_node("PoseRoot").modulate.a == 0.0,
			"Defeat remains hidden without returning to idle", checks, errors)
		_check(actor.get_node("PoseRoot").transform.is_equal_approx(defeated_transform),
			"Defeat endpoint transform remains stable", checks, errors)
	_check(finished.is_empty(), "Seeking never emits playback completion", checks, errors)
	var prior: Dictionary = actor.get_visual_sample()
	_check(not actor.sample_state(&"unknown", 0.0) and prior == actor.get_visual_sample(),
		"Invalid state preserves visible state", checks, errors)
	_check(not actor.sample_state(&"idle", NAN) and prior == actor.get_visual_sample(),
		"Non-finite time is rejected", checks, errors)
	_check(not actor.show_pose(&"unknown") and prior == actor.get_visual_sample(),
		"Invalid pose preserves visible state", checks, errors)
	actor.show_pose(&"neutral")
	_check(actor.warm_poses(), "Explicit warm loads all poses", checks, errors)
	_check(actor.get_retained_pose_names().size() == 3, "Warm mode retains exactly three poses", checks, errors)
	actor.clear_pose_cache()
	_check(actor.get_retained_pose_names() == [&"neutral"], "Clearing warm cache retains only active pose", checks, errors)
	actor.play_state(&"attack")
	actor._process(10.0)
	_check(not actor.is_processing() and finished == [&"attack"], "One-shot playback stops and reports once", checks, errors)
	actor._process(10.0)
	_check(finished == [&"attack"], "Repeated end processing cannot duplicate finish", checks, errors)
	actor.play_state(&"defeat", true)
	actor._process(10.0)
	_check(actor.get_state() == &"defeat" and actor.get_node("PoseRoot").modulate.a == 0.0,
		"Reduced defeat playback ends hidden", checks, errors)
	actor.play_state(&"idle")
	actor._process(10.0)
	_check(actor.is_processing(), "Idle playback may loop", checks, errors)
	actor.stop_preview()
	_check(not actor.is_processing(), "Stopping preview holds current frame", checks, errors)
	actor.queue_free()
	await tree.process_frame
	return {"result": "PASS" if errors.is_empty() else "FAIL", "check_count": checks.size(), "checks": checks, "errors": errors}

func _check(condition: bool, description: String, checks: Array[String], errors: Array[String]) -> void:
	checks.append(description)
	if not condition:
		errors.append(description)
