extends "res://scripts/ui/application_shell.gd"
## Failure injection stays in excluded tests, never normal play.
var fail_next_scene := false
var invalid_next_scene := false
var reject_attached_scene := false

func _create_battle_scene() -> Control:
	if fail_next_scene:
		fail_next_scene = false
		return null
	if invalid_next_scene:
		invalid_next_scene = false
		return Control.new()
	if reject_attached_scene:
		reject_attached_scene = false
		return preload("res://tests/helpers/encounter_rejected_scene.gd").new()
	return super._create_battle_scene()
