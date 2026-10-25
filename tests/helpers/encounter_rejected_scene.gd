extends "res://scripts/ui/main.gd"
## Exercises rejection after real controller/UI/resource construction.
func _ready() -> void:
	super._ready()
	queue_free()
