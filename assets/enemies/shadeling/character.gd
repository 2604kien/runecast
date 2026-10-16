extends Node2D
## Isolated RC-014 illustration and deterministic feasibility study.
## No combat model, intent selection, controller completion, or gameplay callbacks.

signal preview_state_finished(state_name: StringName)

const FOOT := Vector2(256, 448)
const CANVAS := Vector2i(512, 512)
const DURATIONS := {&"idle": 2.4, &"attack": 0.9, &"hit": 0.65, &"defeat": 1.25}
const POSES := [&"neutral", &"attack", &"hit"]
const MARKERS := {
	&"head": "Head", &"body_center": "BodyCenter",
	&"attack_origin": "AttackOrigin", &"lantern_pivot": "LanternPivot",
}
## The approved neutral uses original atlas pixels behind a shared silhouette
## mask. The arena's scenery excludes that same outline, keeping this actor a
## separate foot-local layer without regenerating its face, cloak or lantern.
const REFERENCE_ATLAS = preload("res://assets/ui/combat/reference/approved-atlas.png")
const REFERENCE_SHADER = preload("res://assets/enemies/shadeling/reference/approved_actor.gdshader")
const REFERENCE_NEUTRAL_SIZE := Vector2(841, 1870)
const REFERENCE_SOURCE_RECT := Rect2(285, 145, 295, 290)
const REFERENCE_FOOT := Vector2(446, 428)
const REFERENCE_TEXTURE_SCALE := 1.0 / 0.75
const REFERENCE_TEXTURE_POSITION := (REFERENCE_SOURCE_RECT.position - REFERENCE_FOOT) * REFERENCE_TEXTURE_SCALE
const REFERENCE_ATTACHMENTS := {
	&"head": Vector2(425, 199), &"body_center": Vector2(432, 290),
	&"attack_origin": Vector2(327, 211), &"lantern_pivot": Vector2(332, 233),
}

## Opt-in feasibility playback. Scene instances otherwise start as static neutral.
@export var autoplay_preview := false
@export var reduced_motion := false
## A separate optional vector contact shadow, never baked into the pose alpha.
@export var show_contact_shadow := false
## Normal Combat opts into this neutral; isolated RC-014 specimens keep theirs.
@export var reference_neutral := false
## Resource metadata is exportable without adding a nonresource JSON filter.
@export var attachment_data: Resource

var _state: StringName = &"idle"
var _elapsed := 0.0
var _active_pose: StringName = &""
var _active_reference_neutral := false
var _pose_cache: Dictionary = {}
var _attachments: Dictionary = {}
var _base_path := ""
var _last_sample: Dictionary = {}
var _completed := false
var _reference_material: ShaderMaterial

@onready var pose_root: Node2D = $PoseRoot
@onready var pose_sprite: Sprite2D = $PoseRoot/FullPose
@onready var contact_shadow: Polygon2D = $ContactShadow

func _ready() -> void:
	_base_path = get_script().resource_path.get_base_dir()
	if attachment_data != null:
		_attachments = attachment_data.get_meta("poses", {})
	contact_shadow.visible = show_contact_shadow
	sample_state(&"idle", 0.0, reduced_motion)
	if autoplay_preview:
		play_state(&"idle", reduced_motion)

func _process(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	if not _apply_sample(_state, _elapsed, reduced_motion):
		set_process(false)
		return
	if _state != &"idle" and _elapsed >= float(DURATIONS[_state]):
		set_process(false)
		if not _completed:
			_completed = true
			preview_state_finished.emit(_state)

## Start an optional local study, replacing any previous local study.
## RC-017 must own event sequencing, cancellation and controller completion.
func play_state(state_name: StringName, use_reduced_motion := false) -> bool:
	if not sample_state(state_name, 0.0, use_reduced_motion):
		return false
	set_process(true)
	return true

## Seek to a deterministic frame in seconds; does not emit completion signals.
## Attack/hit settle to neutral at their endpoints. Defeat stays invisible.
func sample_state(state_name: StringName, seconds: float, use_reduced_motion := false) -> bool:
	if not DURATIONS.has(state_name) or not is_finite(seconds):
		return false
	if not _apply_sample(state_name, maxf(0.0, seconds), use_reduced_motion):
		return false
	set_process(false)
	_state = state_name
	_elapsed = maxf(0.0, seconds)
	reduced_motion = use_reduced_motion
	_completed = false
	return true

## Static exported pose, with every transform reset about the shared foot.
func show_pose(pose_name: StringName) -> bool:
	if not POSES.has(pose_name) or not _set_pose(pose_name):
		return false
	set_process(false)
	pose_root.transform = Transform2D.IDENTITY
	pose_root.modulate = Color.WHITE
	contact_shadow.modulate = Color.WHITE
	_state = &"idle" if pose_name == &"neutral" else pose_name
	_elapsed = 0.0
	_completed = false
	_last_sample = {"state": String(_state), "pose": String(pose_name), "time": 0.0,
		"rotation": 0.0, "scale": [1.0, 1.0], "opacity": 1.0,
		"reduced_motion": reduced_motion, "static_pose": true}
	return true

## Stop on the current visual; this is not an RC-017 presentation cancellation.
func stop_preview() -> void:
	set_process(false)

func get_state() -> StringName:
	return _state

func get_pose() -> StringName:
	return _active_pose

func get_visual_sample() -> Dictionary:
	return _last_sample.duplicate(true)

## Foot is the root origin. Other coordinates track the current pose/study.
func get_attachment_position(attachment: StringName, global_coordinates := false) -> Vector2:
	if attachment == &"foot":
		return global_position if global_coordinates else Vector2.ZERO
	if not MARKERS.has(attachment):
		push_warning("Unknown Shadeling attachment: " + String(attachment))
		return global_position if global_coordinates else Vector2.ZERO
	var marker: Marker2D = pose_root.get_node(MARKERS[attachment])
	return marker.global_position if global_coordinates else to_local(marker.global_position)

## Optional caller-owned residency choice. Default retains only active texture.
## No body/arm/lantern part textures are loaded by this whole-pose scene.
func warm_poses(pose_names: Array[StringName] = [&"neutral", &"attack", &"hit"]) -> bool:
	for pose_name in pose_names:
		if not POSES.has(pose_name):
			return false
	for pose_name in pose_names:
		var texture := _load_pose(pose_name)
		if texture == null:
			return false
		_pose_cache[_texture_key(pose_name)] = texture
	return true

func clear_pose_cache() -> void:
	_pose_cache.clear()

func get_retained_pose_names() -> Array[StringName]:
	var result: Array[StringName] = []
	for pose_name in POSES:
		if pose_name == _active_pose or _pose_cache.has(_texture_key(pose_name)):
			result.append(pose_name)
	return result

func _load_pose(pose_name: StringName) -> Texture2D:
	var key := _texture_key(pose_name)
	if _pose_cache.has(key):
		return _pose_cache[key]
	if key == &"reference_neutral":
		return REFERENCE_ATLAS
	var relative_path := String(pose_name) + ".png"
	return ResourceLoader.load(_base_path.path_join(relative_path),
		"Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D

func _texture_key(pose_name: StringName) -> StringName:
	return &"reference_neutral" if reference_neutral and pose_name == &"neutral" else pose_name

func _set_pose(pose_name: StringName) -> bool:
	var use_reference := reference_neutral and pose_name == &"neutral"
	if _active_pose == pose_name and _active_reference_neutral == use_reference:
		return true
	var texture := _load_pose(pose_name)
	if texture == null or (not use_reference and texture.get_size() != Vector2(CANVAS)):
		push_error("Shadeling pose texture has unexpected dimensions: " + String(pose_name))
		return false
	if use_reference and (texture.get_width() <= 0 or texture.get_height() <= 0):
		push_error("Shadeling approved neutral requires its atlas texture")
		return false
	var points: Dictionary = _attachments.get(String(pose_name), {})
	for attachment in MARKERS:
		if not points.has(String(attachment)):
			push_error("Shadeling missing attachment " + String(attachment) + " in " + String(pose_name))
			return false
	pose_sprite.texture = texture
	pose_sprite.position = REFERENCE_TEXTURE_POSITION if use_reference else -FOOT
	pose_sprite.region_enabled = use_reference
	pose_sprite.region_filter_clip_enabled = use_reference
	if use_reference:
		var import_ratio := texture.get_size() / REFERENCE_NEUTRAL_SIZE
		pose_sprite.region_rect = Rect2(REFERENCE_SOURCE_RECT.position * import_ratio, REFERENCE_SOURCE_RECT.size * import_ratio)
		if _reference_material == null:
			_reference_material = ShaderMaterial.new()
			_reference_material.shader = REFERENCE_SHADER
		pose_sprite.material = _reference_material
	else:
		pose_sprite.material = null
	# Import limits may resize the unchanged source PNG. Normalize its source
	# coordinates to the imported texture so foot/visible geometry stays fixed.
	pose_sprite.scale = REFERENCE_NEUTRAL_SIZE / texture.get_size() * REFERENCE_TEXTURE_SCALE if use_reference else Vector2.ONE
	_active_pose = pose_name
	_active_reference_neutral = use_reference
	for attachment in MARKERS:
		var point: Array = points[String(attachment)]
		var marker: Marker2D = pose_root.get_node(MARKERS[attachment])
		marker.position = ((REFERENCE_ATTACHMENTS[attachment] - REFERENCE_FOOT) * REFERENCE_TEXTURE_SCALE
			if use_reference else Vector2(float(point[0]), float(point[1])) - FOOT)
	return true

func _apply_sample(state_name: StringName, seconds: float, restrained: bool) -> bool:
	var duration: float = DURATIONS[state_name]
	var t := clampf(seconds / duration, 0.0, 1.0)
	var pose: StringName = &"neutral"
	var angle := 0.0
	var stretch := 1.0
	var opacity := 1.0
	var shadow_opacity := 1.0
	match state_name:
		&"idle":
			if not restrained:
				stretch += 0.004 * sin(fmod(seconds, duration) / duration * TAU)
		&"attack":
			if t >= 0.2 and t < 0.8:
				pose = &"attack"
			if not restrained:
				if t < 0.2:
					angle = lerpf(0.0, -0.018, smoothstep(0.0, 0.2, t))
				elif t < 0.8:
					# Wide attack painting uses the available horizontal envelope.
					# Compress about the foot; never swing its lantern off-canvas.
					stretch = 1.0 - 0.012 * sin(PI * inverse_lerp(0.2, 0.8, t))
		&"hit":
			if t < 0.75:
				pose = &"hit"
			if not restrained:
				angle = -0.028 * sin(PI * t)
			opacity = 1.0 - (0.06 if restrained else 0.10) * sin(PI * t)
		&"defeat":
			pose = &"hit"
			var collapse := smoothstep(0.0, 1.0, t)
			if not restrained:
				angle = 0.06 * collapse
				stretch = lerpf(1.0, 0.65, collapse)
			opacity = 1.0 - smoothstep(0.18, 1.0, t)
			shadow_opacity = 1.0 - smoothstep(0.0, 1.0, t)
	if not _set_pose(pose):
		return false
	pose_root.position = Vector2.ZERO
	pose_root.rotation = angle
	pose_root.scale = Vector2(1.0, stretch)
	pose_root.modulate = Color(1.0, 1.0, 1.0, opacity)
	contact_shadow.modulate = Color(1.0, 1.0, 1.0, shadow_opacity)
	_last_sample = {"state": String(state_name), "pose": String(pose), "time": seconds,
		"rotation": angle, "scale": [1.0, stretch], "opacity": opacity,
		"reduced_motion": restrained, "static_pose": false}
	return true
