extends SceneTree
## Standalone generated-raster surface sheet; never part of playable Combat.
const Surface = preload("res://scenes/ui/theme/combat_surface.gd")

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	root.size = Vector2i(720, 1180)
	root.content_scale_size = Vector2i(720,1180)
	var back := ColorRect.new()
	back.color = Color("0c1727")
	back.size = Vector2(720,1180)
	root.add_child(back)
	_add("stats",Rect2(10,10,700,52))
	_add("board",Rect2(10,66,450,435))
	_add("ribbon",Rect2(40,75,390,45))
	for y in 3:
		for x in 3:
			_add("socket",Rect2(45+x*132,130+y*115,125,108))
	_add("deck",Rect2(495,85,70,135))
	_add("parchment",Rect2(480,240,150,42))
	_add("pause",Rect2(635,240,62,50))
	_add("health",Rect2(478,305,222,32))
	_add("card_damage",Rect2(475,355,105,145))
	_add("card_technique",Rect2(592,355,105,145))
	_add("toolbar",Rect2(10,508,700,96))
	for x in 5:
		_add("slot",Rect2(145+x*94,516,85,80))
	_add("parchment",Rect2(23,535,110,49))
	_add("forecast",Rect2(25,625,670,66))
	_add("caption",Rect2(25,715,670,34))
	_add("nav",Rect2(25,750,670,83))
	_add("card_shield",Rect2(25,847,140,160))
	_add("card_mixed",Rect2(175,847,140,160))
	_add("button",Rect2(335,850,180,60))
	_add("cast",Rect2(335,925,360,72))
	_add("heading",Rect2(25,1025,670,55))
	_add("caption",Rect2(25,1100,670,34))
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-016/image-rework")
	image.save_png("res://output/qa/rc-016/image-rework/combat-surface-sheet.png")
	print("Combat surfaces rendered: ",image.get_size())
	quit()

func _add(style: String, rect: Rect2) -> void:
	var node := Surface.new()
	node.kind = style
	node.art_scale = .856
	node.position = rect.position
	node.size = rect.size
	root.add_child(node)
