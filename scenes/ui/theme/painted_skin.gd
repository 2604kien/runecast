extends Control
## Painted frame renderer with independent source/destination slice margins.
## Decorations never alter the parent's rectangular pointer target.
var texture: Texture2D
var source_caps := Vector4(24, 24, 24, 24)
var destination_caps := Vector4(12, 12, 12, 12)
var proportional_caps := false
var tint := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if texture == null or size.x <= 0 or size.y <= 0:
		return
	var src := Vector2(texture.get_size())
	var dst := destination_caps
	if proportional_caps:
		var ratio := size.y / src.y
		dst = source_caps * ratio
	dst.x = minf(dst.x, size.x * 0.45)
	dst.z = minf(dst.z, size.x * 0.45)
	dst.y = minf(dst.y, size.y * 0.45)
	dst.w = minf(dst.w, size.y * 0.45)
	var sx := [0.0, source_caps.x, src.x - source_caps.z, src.x]
	var sy := [0.0, source_caps.y, src.y - source_caps.w, src.y]
	var dx := [0.0, dst.x, size.x - dst.z, size.x]
	var dy := [0.0, dst.y, size.y - dst.w, size.y]
	for y in 3:
		for x in 3:
			draw_texture_rect_region(texture,
				Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y]),
				Rect2(sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y]), tint)
