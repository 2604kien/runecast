extends Node2D
## Top-left origin in 841x570 export/composition coordinates.
## Transform this root once. Add actor/UI as siblings, never children of layers.
const CANVAS_SIZE := Vector2(841, 570)
const COMPARISON_CROP := Rect2(0, 60, 841, 450)
@export var lighting: Resource = preload("res://assets/environments/crypt/lighting.tres")
@export_enum("base_cool", "warm_candle", "dark") var preset := "base_cool"
## Full-screen Combat uses the new empty center and original visible scenery.
## Other consumers keep the existing overlapping RC-015 layers by default.
@export var reference_art := false
var _material: ShaderMaterial
var _reference_material: ShaderMaterial
var _reference_layers: Array[Sprite2D] = []

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/environments/crypt/lighting.gdshader")
	$Background.material = _material
	$Floor.material = _material
	if reference_art:
		_build_reference_layers()
	set_lighting(StringName(preset))

func _build_reference_layers() -> void:
	$Background.hide()
	$Floor.hide()
	var clean := Sprite2D.new()
	clean.name = "ReferenceCleanPlate"
	clean.texture = preload("res://assets/environments/crypt/reference/arena.png")
	clean.centered = false
	clean.position = COMPARISON_CROP.position
	clean.scale = COMPARISON_CROP.size / clean.texture.get_size()
	clean.material = _material
	clean.z_index = -20
	add_child(clean)
	_reference_layers.append(clean)
	var edges := Sprite2D.new()
	edges.name = "ReferenceVisibleScenery"
	# Region sampling retains approved architecture between the separately
	# masked actor and small live-label holes, including the original floor.
	edges.texture = preload("res://assets/ui/combat/reference/approved-atlas.png")
	edges.region_enabled = true
	edges.region_rect = COMPARISON_CROP
	edges.region_filter_clip_enabled = true
	edges.centered = false
	edges.position = COMPARISON_CROP.position
	edges.z_index = -19
	_reference_material = ShaderMaterial.new()
	_reference_material.shader = preload("res://assets/environments/crypt/reference/visible_edges.gdshader")
	edges.material = _reference_material
	add_child(edges)
	_reference_layers.append(edges)

func set_lighting(value: StringName) -> bool:
	if not lighting.has_preset(value): return false
	preset = String(value)
	if _material != null: _material.set_shader_parameter("tone", lighting.get_tone(value))
	if _reference_material != null: _reference_material.set_shader_parameter("tone", lighting.get_tone(value))
	return true

func get_layer_nodes() -> Array:
	return _reference_layers if reference_art else [$Background, $Floor]
