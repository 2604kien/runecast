extends Node2D
## Optional SOURCE-PART stress specimen. The delivered runtime scene uses whole poses.
const PACK = "res://assets/enemies/shadeling/parts/"
const FOOT = Vector2(256,448)
const ARM_PIVOT = Vector2(183.20951509606584,176.92955169258917)
const ITEM_PIVOT = Vector2(114.37145471180236,177.58828911253426)
const NECK_PIVOT = Vector2(237,208)
var arm: Node2D
var item: Node2D
var head: Node2D

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	for layer in ["shoulder_underlap","neck_underlap","body_cloak"]:
		part(self,layer,-FOOT)
	head=Node2D.new()
	head.position=NECK_PIVOT-FOOT
	add_child(head)
	part(head,"head_hood",-NECK_PIVOT)
	arm=Node2D.new()
	arm.position=ARM_PIVOT-FOOT
	add_child(arm)
	part(arm,"lantern_arm",-ARM_PIVOT)
	item=Node2D.new()
	item.position=ITEM_PIVOT-ARM_PIVOT
	arm.add_child(item)
	for layer in ["lantern_glass_backing","lantern_shell","lantern_glass_light","flame"]:
		part(item,layer,-ITEM_PIVOT)

func part(parent: Node2D, name: String, offset: Vector2) -> void:
	var sprite:=Sprite2D.new()
	sprite.name=name
	sprite.centered=false
	sprite.position=offset
	sprite.texture=load(PACK+name+".png")
	parent.add_child(sprite)

func sample(amount: float) -> void:
	arm.rotation=deg_to_rad(4.0*amount)
	item.rotation=deg_to_rad(3.0*amount)
	head.rotation=deg_to_rad(-2.0*amount)
