extends Control
## Interactive isolated specimen browser. No save, navigation or combat model.
const Sheet = preload("res://sheet.gd")
const MODES := ["components","states","cards","home-save","home-empty","home-invalid","menu-open","menu-locked","options","map","replace","dialog","wordmark"]
var picker:OptionButton
var current:Control

func _ready() -> void:
	theme=load("res://assets/ui/rune_cast_theme.tres")
	picker=OptionButton.new()
	picker.position=Vector2(14,4)
	picker.custom_minimum_size=Vector2(280,44)
	for mode in MODES: picker.add_item(mode.capitalize().replace("-"," "))
	add_child(picker)
	picker.item_selected.connect(show_specimen)
	resized.connect(func():call_deferred("show_specimen",picker.selected))
	show_specimen(0)

func show_specimen(index:int) -> void:
	if current:
		remove_child(current)
		current.queue_free()
	current=Sheet.new()
	current.mode=MODES[index]
	current.canvas_size=Vector2(maxf(size.x,320),maxf(size.y-52,400))
	current.position=Vector2(0,52)
	add_child(current)
	if MODES[index] in ["dialog","replace"]:
		await get_tree().process_frame
		if is_instance_valid(current) and current.specimen:
			var panel:Control=current.specimen
			var close:Button=panel.get_meta("rc_close")
			close.pressed.connect(func():panel.hide())
