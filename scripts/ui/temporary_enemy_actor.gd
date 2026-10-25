extends Node2D
## RC-034 temporary presentation; RC-037–040 own the character packs.
## Foot-local attachment and deterministic presentation API matches the actor
## seam. This shared geometric token owns no combat state, RNG or callbacks.
const IDS := ["wickling", "stone_sentinel", "chain_warden", "bell_keeper"]
const ATTACK_CONTACT := 0.5
const COLORS := {
	"wickling": Color("e7a064"), "stone_sentinel": Color("a7c1c5"),
	"chain_warden": Color("b1a3cd"), "bell_keeper": Color("dfc378"),
}
const ATTACHMENTS := {&"foot": Vector2.ZERO, &"head": Vector2(0, -268),
	&"body_center": Vector2(0, -170), &"attack_origin": Vector2(0, -170),
	&"lantern_pivot": Vector2(0, -170)}
var enemy_id := ""
var pose_root: Node2D
var _last_sample: Dictionary = {}

class Token extends Node2D:
	var identity := ""
	func _draw() -> void:
		var tint: Color = COLORS.get(identity, Color("a7c1c5"))
		draw_set_transform(Vector2(0, -8), 0, Vector2(1, 0.16))
		draw_circle(Vector2.ZERO, 83, Color(0.02, 0.04, 0.07, 0.6))
		draw_set_transform(Vector2.ZERO)
		var body := PackedVector2Array([Vector2(-82, -238), Vector2(0, -300), Vector2(82, -238),
			Vector2(82, -74), Vector2(0, -18), Vector2(-82, -74)])
		draw_colored_polygon(body, Color("162735"))
		var outline := body.duplicate()
		outline.append(body[0])
		draw_polyline(outline, tint, 4, true)
		draw_line(Vector2(-54, -89), Vector2(54, -89), tint.darkened(0.45), 2, true)
		draw_circle(Vector2(0, -178), 54, tint.darkened(0.78))
		match identity:
			"wickling":
				draw_colored_polygon(PackedVector2Array([Vector2(0,-224),Vector2(26,-187),Vector2(23,-160),Vector2(0,-143),Vector2(-25,-161),Vector2(-28,-184),Vector2(-10,-171)]), tint)
				draw_line(Vector2(0,-168), Vector2(0,-132), tint, 5, true)
			"stone_sentinel":
				draw_rect(Rect2(-31,-214,62,72), tint, false, 5)
				draw_line(Vector2(-31,-184), Vector2(31,-184), tint, 4, true)
				draw_line(Vector2(0,-214), Vector2(0,-184), tint, 4, true)
				draw_line(Vector2(-15,-184), Vector2(-15,-142), tint, 4, true)
			"chain_warden":
				for center in [Vector2(-15,-194), Vector2(15,-164)]:
					draw_arc(center, 22, 0, TAU, 40, tint, 6, true)
				draw_line(Vector2(-7,-186), Vector2(7,-172), tint, 6, true)
			"bell_keeper":
				draw_arc(Vector2(0,-187), 27, PI, TAU, 36, tint, 5, true)
				draw_polyline(PackedVector2Array([Vector2(-27,-187),Vector2(-31,-158),Vector2(-39,-149),Vector2(39,-149),Vector2(31,-158),Vector2(27,-187)]), tint, 5, true)
				draw_circle(Vector2(0,-138), 7, tint)
				draw_line(Vector2(0,-224), Vector2(0,-214), tint, 5, true)

func _ready() -> void:
	pose_root = Token.new()
	pose_root.name = "PoseRoot"
	pose_root.identity = enemy_id
	add_child(pose_root)
	reset_presentation()

func configure(identity: String) -> void:
	if enemy_id == identity: return
	enemy_id = identity
	if pose_root != null:
		pose_root.identity = identity
		pose_root.queue_redraw()
		reset_presentation()

func warm_poses(_names: Array[StringName] = []) -> bool:
	return true

func show_pose(pose: StringName) -> bool:
	return sample_presentation(&"idle" if pose == &"neutral" else pose, 0.0)

func set_idle_enabled(_enabled: bool, _reduced := false) -> void:
	# An intentionally still temporary target; presenter owns all transients.
	pass

func sample_presentation(state_name: StringName, progress: float, reduced := false) -> bool:
	if state_name not in [&"idle", &"attack", &"hit", &"defeat"] or not is_finite(progress): return false
	if pose_root == null: return false
	var t := clampf(progress, 0.0, 1.0)
	var pulse := sin(PI * t)
	var tint := Color.WHITE
	var opacity := 1.0
	var angle := 0.0
	var stretch := Vector2.ONE
	if state_name == &"attack":
		tint = Color.WHITE.lerp(Color("ffe2a2"), pulse * 0.8)
		if not reduced: stretch = Vector2.ONE * (1.0 + 0.035 * pulse)
	elif state_name == &"hit":
		tint = Color.WHITE.lerp(Color("ff9076"), pulse * 0.75)
		if not reduced: angle = -0.025 * pulse
	elif state_name == &"defeat":
		opacity = 1.0 - smoothstep(0.0, 1.0, t)
		if not reduced: stretch.y = lerpf(1.0, 0.78, t)
	pose_root.rotation = angle
	pose_root.scale = stretch
	pose_root.modulate = Color(tint.r, tint.g, tint.b, opacity)
	_last_sample = {"state": String(state_name), "progress": t, "rotation": angle,
		"scale": [stretch.x, stretch.y], "opacity": opacity, "reduced_motion": reduced,
		"temporary_art": true, "enemy_id": enemy_id}
	return true

func reset_presentation(battle_state := "playing", reduced := false) -> void:
	sample_presentation(&"defeat" if battle_state == "victory" else &"idle", 1.0 if battle_state == "victory" else 0.0, reduced)

func get_visual_sample() -> Dictionary:
	return _last_sample.duplicate(true)

func get_attachment_position(attachment: StringName, global_coordinates := false) -> Vector2:
	var point: Vector2 = ATTACHMENTS.get(attachment, Vector2.ZERO)
	if pose_root != null: point = pose_root.transform * point
	return to_global(point) if global_coordinates else point

func attack_contact_fraction() -> float:
	return ATTACK_CONTACT
