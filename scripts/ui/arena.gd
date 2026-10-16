extends Control
## Presentation only: the owner supplies a detached combat snapshot.
## RC-017 owns event-driven motion; this consumer never starts the local study.
const Ui = preload("res://scenes/ui/theme/components.gd")
const CRYPT = preload("res://assets/environments/crypt/environment.tscn")
const SHADELING = preload("res://assets/enemies/shadeling/character.tscn")
const CROP := Rect2(0, 60, 841, 450)
const FOOT := Vector2(446, 368)
const POSE_ENVELOPE := Rect2(272, 56, 348, 336)

## The generated painted strip remains a ProgressBar with the live Range
## contract. Only the fill fraction is computed here; artwork stays in the skin.
class BossHealthBar extends ProgressBar:
	var surface: Control

	func _ready() -> void:
		add_theme_stylebox_override("background", StyleBoxEmpty.new())
		add_theme_stylebox_override("fill", StyleBoxEmpty.new())
		surface = Ui.CombatSurface.new()
		surface.name = "PaintedHealth"
		surface.set("kind", "health")
		add_child(surface, false, Node.INTERNAL_MODE_BACK)
		surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		set_meta("combat_surface", surface)
		set_meta("rc_skin", surface)
		value_changed.connect(func(_value: float): _refresh_fill())
		_refresh_fill()

	func _refresh_fill() -> void:
		surface.set("fill_ratio", clampf((value - min_value) / maxf(max_value - min_value, 1.0), 0.0, 1.0))

var enemy_id := ""
var enemy_name := ""
var enemy_hp := 0
var enemy_max_hp := 1
var attack := 0
var battle_state := "unavailable"
var compact := false
var lighting_preset := "base_cool"
## Normal Combat explicitly enables reference artwork; isolated consumers keep
## the delivered RC-014/015 presentation and its existing coordinate contract.
var reference_art := false
var reference_bleed := 0.0

var art_clip: Control
var environment: Node2D
var actor: Node2D
var role_label: Label
var name_label: Label
var intent_label: Label
var intent_icon: TextureRect
var health_bar: ProgressBar
var health_label: Label
var stage_scale := 1.0
var art_scale := 1.0
var status_role_font: FontVariation
var status_name_font: FontVariation
var status_value_font: FontVariation

func _ready() -> void:
	theme = Ui.THEME
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_clip = Control.new()
	art_clip.name = "ArtCrop"
	art_clip.clip_contents = true
	art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_clip)
	environment = CRYPT.instantiate()
	environment.name = "Crypt"
	environment.reference_art = reference_art
	# Delivered layers use -20/-10. Lift their shared root so the opaque arena
	# backing stays behind both layers without changing their relative ordering.
	environment.z_index = 20
	art_clip.add_child(environment)
	# The actor is a sibling of the environment, outside its lighting shader.
	actor = SHADELING.instantiate()
	actor.reference_neutral = reference_art
	actor.z_index = 21
	art_clip.add_child(actor)
	actor.show_pose(&"neutral")
	intent_icon = Ui.combat_icon("attack", Vector2.ZERO)
	intent_icon.name = "IntentIcon"
	intent_icon.z_index = 22
	add_child(intent_icon)
	intent_label = _label("Intent", "value")
	role_label = _label("EnemyRole", "body")
	role_label.add_theme_color_override("font_color", Color("ffcf2f"))
	name_label = _label("EnemyName", "body")
	name_label.add_theme_color_override("font_color", Color("fffdf3"))
	# The painted reference has taller, compact status lettering. A condensed
	# face preserves its measured name/number width as the readable size grows.
	status_role_font = Ui.COMBAT_BODY_FONT.duplicate()
	status_role_font.variation_opentype = {"width": 100.0, "weight": 700.0}
	status_name_font = Ui.COMBAT_BODY_FONT.duplicate()
	status_name_font.variation_opentype = {"width": 62.5, "weight": 600.0}
	status_name_font.spacing_top = -4
	status_name_font.spacing_bottom = -4
	status_value_font = Ui.COMBAT_VALUE_FONT.duplicate()
	status_value_font.variation_opentype = {"width": 80.0, "weight": 600.0}
	status_value_font.spacing_top = -4
	status_value_font.spacing_bottom = -4
	health_bar = BossHealthBar.new()
	health_bar.name = "EnemyHealth"
	health_bar.z_index = 22
	health_bar.theme_type_variation = "RCHealth"
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar)
	health_label = _label("EnemyHealthValue", "value")
	health_label.add_theme_color_override("font_color", Color("fffdf3"))
	resized.connect(_layout)
	refresh()

func _label(node_name: String, role: String) -> Label:
	var result := Ui.combat_label("", role)
	result.name = node_name
	result.z_index = 22
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.add_theme_color_override("font_outline_color", Color("100e13"))
	result.add_theme_constant_override("outline_size", 3)
	add_child(result)
	return result

func recommended_height(width: float) -> float:
	if compact:
		return 90.0
	var k := maxf(width, 1.0) / CROP.size.x
	# Preserve the existing arena allocation while moving its status back up
	# beside the visible neutral feet. Future motion retains the full crop and
	# pose envelope, but unused pose clearance must not push this UI downward.
	var allocation_role := maxf(14, Ui.COMBAT_BODY_FONT.get_height(maxi(12, roundi(16 * k))))
	var allocation_name := maxf(18, Ui.COMBAT_BODY_FONT.get_height(maxi(14, roundi(24 * k))))
	return ceilf(maxf(CROP.size.y * k, POSE_ENVELOPE.end.y * k + 2 + allocation_role + allocation_name + maxf(18, 28 * k) + 3))

func refresh() -> void:
	if not is_node_ready() or art_clip == null:
		return
	_sync_values()
	_layout()

func _sync_values() -> void:
	if art_clip == null:
		return
	art_clip.visible = not compact
	actor.visible = not compact and enemy_id == "shadeling"
	role_label.text = "BOSS" if enemy_id == "shadeling" and not reference_art else ""
	role_label.visible = not role_label.text.is_empty()
	name_label.text = enemy_name
	intent_icon.visible = battle_state == "playing"
	intent_label.text = str(attack) if battle_state == "playing" else battle_state.to_upper()
	intent_label.add_theme_color_override("font_color", Color("fffdf3") if battle_state == "playing" else Ui.GOLD)
	health_bar.max_value = maxi(enemy_max_hp, 1)
	health_bar.value = clampi(enemy_hp, 0, maxi(enemy_max_hp, 1))
	health_label.text = "%d/%d" % [enemy_hp, enemy_max_hp]
	environment.set_lighting(StringName(lighting_preset))

func _layout() -> void:
	if art_clip == null or size.x <= 0:
		return
	stage_scale = size.x / CROP.size.x
	custom_minimum_size.y = recommended_height(size.x)
	var k := stage_scale
	var bleed := maxf(reference_bleed, 0.0) if reference_art else 0.0
	art_scale = (size.x + bleed * 2.0) / CROP.size.x
	art_clip.position = Vector2(-bleed, 0)
	art_clip.size = Vector2(size.x + bleed * 2.0, CROP.size.y * art_scale)
	environment.position = -CROP.position * art_scale
	environment.scale = Vector2.ONE * art_scale
	actor.position = FOOT * art_scale
	actor.scale = Vector2.ONE * 0.75 * art_scale
	if compact:
		_layout_compact()
		return
	var intent_size := maxi(20, roundi(42 * k))
	intent_label.add_theme_font_size_override("font_size", intent_size)
	var icon_height := maxf(24, 47 * k)
	var icon_width := icon_height * intent_icon.texture.get_width() / intent_icon.texture.get_height()
	var text_width := Ui.COMBAT_VALUE_FONT.get_string_size(intent_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, intent_size).x
	var gap := maxf(4, 8 * k)
	var intent_height := maxf(icon_height, Ui.COMBAT_VALUE_FONT.get_height(intent_size))
	var intent_y := maxf(2, 46 * k)
	var group_left := (size.x - icon_width - gap - text_width) * 0.5
	intent_icon.position = Vector2(group_left, intent_y + (intent_height - icon_height) / 2)
	intent_icon.size = Vector2(icon_width, icon_height)
	intent_label.position = Vector2(group_left + icon_width + gap, intent_y)
	intent_label.size = Vector2(text_width, intent_height)
	if battle_state != "playing":
		intent_label.position.x = 8
		intent_label.size.x = size.x - 16
	_layout_status(_status_top(k), _name_height(k), _health_height(k), k)

func _status_top(k: float) -> float:
	# Removing the role must not pull the name up over the actor's feet.
	return (FOOT.y + 6) * k + (_role_height(k) if reference_art else 0.0)

func _name_height(k: float) -> float:
	return maxf(18, status_name_font.get_height(maxi(14, roundi(28 * k))))

func _role_height(k: float) -> float:
	return maxf(14, Ui.COMBAT_BODY_FONT.get_height(maxi(12, roundi(16 * k))))

func _health_height(k: float) -> float:
	return maxf(18, maxf(30 * k, status_value_font.get_height(maxi(16, roundi(32 * k)))))

func _layout_status(top: float, row_height: float, bar_height: float, k: float) -> void:
	# Keep the measured status lanes stable; size the glyphs to the normalized
	# reference instead of letting the line box dictate their visible scale.
	var font_size := maxi(14, roundi((24 if compact else 26) * k))
	name_label.add_theme_font_override("font", Ui.COMBAT_BODY_FONT if compact else status_name_font)
	name_label.add_theme_font_size_override("font_size", font_size)
	role_label.add_theme_font_override("font", Ui.COMBAT_BODY_FONT if compact else status_role_font)
	role_label.add_theme_font_size_override("font_size", maxi(12, roundi(16 * k)))
	var role_height := _role_height(k) if role_label.visible else 0.0
	role_label.position = Vector2(0, top)
	role_label.size = Vector2(size.x, role_height)
	name_label.position = Vector2(0, top + role_height)
	name_label.size = Vector2(size.x, row_height)
	var health_width := minf(size.x - 32, maxf(132, 232 * k))
	health_bar.position = Vector2((size.x - health_width) / 2, top + role_height + row_height)
	health_bar.size = Vector2(health_width, bar_height)
	health_label.add_theme_font_override("font", Ui.COMBAT_VALUE_FONT if compact else status_value_font)
	health_label.add_theme_font_size_override("font_size", maxi(16, roundi((26 if compact else 30) * k)))
	health_label.position = health_bar.position
	health_label.size = health_bar.size

func _layout_compact() -> void:
	intent_label.add_theme_font_size_override("font_size", 16)
	intent_icon.position = Vector2(size.x / 2 - 32, 38)
	intent_icon.size = Vector2(24, 24)
	intent_label.position = Vector2(size.x / 2 - 4, 37)
	intent_label.size = Vector2(42, 24)
	if battle_state != "playing":
		intent_label.position.x = 8
		intent_label.size.x = size.x - 16
	_layout_status(0, 20, 22, minf(stage_scale, 0.6))
	health_bar.position.y = 62
	health_label.position.y = 62

func _draw() -> void:
	# Retain compatibility with existing callers that assign fields then redraw.
	# The normal Combat owner calls refresh() explicitly for immediate geometry.
	if art_clip != null:
		_sync_values()
		_layout()

func get_geometry() -> Dictionary:
	var status_rect := Rect2()
	if role_label != null and health_bar != null and health_label != null:
		var status_top := role_label.position.y
		var status_bottom := maxf(health_bar.get_rect().end.y, health_label.get_rect().end.y)
		status_rect = Rect2(Vector2(0, status_top), Vector2(size.x, status_bottom - status_top))
	return {
		"crop": CROP,
		"art_rect": art_clip.get_rect() if art_clip != null else Rect2(),
		"scale": stage_scale,
		"art_scale": art_scale,
		"foot": art_clip.position + FOOT * art_scale if art_clip != null else FOOT * art_scale,
		"actor_scale": 0.75 * art_scale,
		"pose_envelope": Rect2((art_clip.position if art_clip != null else Vector2.ZERO) + POSE_ENVELOPE.position * art_scale, POSE_ENVELOPE.size * art_scale),
		"status_rect": status_rect,
		"lighting_preset": environment.preset if environment != null else lighting_preset,
		"compact": compact,
		"reference_art": reference_art,
		"reference_bleed": reference_bleed if reference_art else 0.0
	}
