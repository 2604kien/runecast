extends "res://scenes/ui/theme/painted_skin.gd"
## Menu actions share Continue's painted gold frame. Only the face material
## changes; combat controls keep their existing independent presentation.
const FRAME = preload("res://assets/ui/buttons/primary.png")
const SECONDARY = preload("res://assets/ui/buttons/secondary.png")
const FACE_SHADER = preload("res://scenes/ui/theme/button_face.gdshader")
# Match the original primary StyleBox's clear text well. These fixed margins
# safely clear the proportional end caps at the menu's 44–82px action heights,
# without feeding the laid-out height back into the button's minimum size.
const CONTENT_MARGINS := Vector4(40, 12, 40, 12)

static func content_margins() -> Vector4:
	return CONTENT_MARGINS

static func attach(button: Button, palette: String = "secondary") -> Control:
	var previous = button.get_meta("rc_skin") if button.has_meta("rc_skin") else null
	if is_instance_valid(previous):
		button.remove_child(previous)
		previous.queue_free()
	var frame = load("res://scenes/ui/theme/button_frame.gd").new()
	frame.name = "ButtonFrame"
	frame.texture = FRAME
	frame.source_caps = Vector4(56, 18, 56, 18)
	# Preserve Continue's original aspect: each cap scales uniformly with
	# button height while only the centre strip stretches horizontally.
	frame.proportional_caps = true
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if palette != "primary":
		var face := ShaderMaterial.new()
		face.shader = FACE_SHADER
		var face_texture: Texture2D = SECONDARY
		var region := Rect2(50, 24, 412, 84)
		var dimensions := Vector2(face_texture.get_size())
		face.set_shader_parameter("face_texture", face_texture)
		face.set_shader_parameter("face_region", Vector4(region.position.x / dimensions.x, region.position.y / dimensions.y, region.size.x / dimensions.x, region.size.y / dimensions.y))
		frame.material = face
	button.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.set_meta("rc_skin", frame)
	button.set_meta("rc_button_frame", true)
	button.set_meta("rc_button_palette", palette)
	button.set_meta("rc_content_margins", CONTENT_MARGINS)
	var spacing := StyleBoxEmpty.new()
	spacing.content_margin_left = CONTENT_MARGINS.x
	spacing.content_margin_top = CONTENT_MARGINS.y
	spacing.content_margin_right = CONTENT_MARGINS.z
	spacing.content_margin_bottom = CONTENT_MARGINS.w
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, spacing)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 44)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 44)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false
	return frame

func get_content_rect() -> Rect2:
	var start := Vector2(CONTENT_MARGINS.x, CONTENT_MARGINS.y)
	return Rect2(start, Vector2(maxf(0, size.x - CONTENT_MARGINS.x - CONTENT_MARGINS.z), maxf(0, size.y - CONTENT_MARGINS.y - CONTENT_MARGINS.w)))
