extends Node2D
## Top-left origin in 841x570 export/composition coordinates.
## Transform this root once. Add actor/UI as siblings, never children of layers.
const CANVAS_SIZE := Vector2(841, 570)
const COMPARISON_CROP := Rect2(0, 60, 841, 450)
@export var lighting: Resource = preload("res://assets/environments/crypt/lighting.tres")
@export_enum("base_cool", "warm_candle", "dark") var preset := "base_cool"
var _material: ShaderMaterial

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/environments/crypt/lighting.gdshader")
	$Background.material = _material
	$Floor.material = _material
	set_lighting(StringName(preset))

func set_lighting(value: StringName) -> bool:
	if not lighting.has_preset(value): return false
	preset = String(value)
	if _material != null: _material.set_shader_parameter("tone", lighting.get_tone(value))
	return true

func get_layer_nodes() -> Array:
	return [$Background, $Floor]
