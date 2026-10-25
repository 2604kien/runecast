extends StyleBox
## Keep the existing modal rim and spacing, with the navigation bar's clean
## dark painted material replacing the old cracked-stone center.
const CombatSurface = preload("res://scenes/ui/theme/combat_surface.gd")
const FRAME = preload("res://assets/ui/styles/panel.tres")
var _rim: StyleBoxTexture = FRAME.duplicate()

func _init() -> void:
	_rim.draw_center = false
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		set_content_margin(side, FRAME.get_content_margin(side))

func _get_minimum_size() -> Vector2:
	return FRAME.get_minimum_size()

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var inset := Vector2(_rim.texture_margin_left, _rim.texture_margin_top)
	var end_inset := Vector2(_rim.texture_margin_right, _rim.texture_margin_bottom)
	var center := Rect2(rect.position + inset, (rect.size - inset - end_inset).max(Vector2.ZERO))
	if center.has_area():
		var ratio := Vector2(CombatSurface.ATLAS.get_size()) / CombatSurface.ATLAS_SIZE
		var source: Rect2 = CombatSurface.MATERIALS.nav
		RenderingServer.canvas_item_add_texture_rect_region(
			canvas_item, center, CombatSurface.ATLAS.get_rid(),
			Rect2(source.position * ratio, source.size * ratio))
	_rim.draw(canvas_item, rect)
