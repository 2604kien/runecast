extends Resource
## RC-015 bounded lighting settings. Only the two crypt layers consume these.
## Keys are a fixed integration contract; edit the values, not the key set.
const PRESETS = [&"base_cool", &"warm_candle", &"dark"]
@export var base_cool := Vector3(1.0, 1.0, 1.0)
@export var warm_candle := Vector3(1.12, 1.03, 0.93)
@export var dark := Vector3(0.74, 0.80, 0.92)

func get_tone(preset: StringName) -> Vector3:
	match preset:
		&"warm_candle": return warm_candle
		&"dark": return dark
		_: return base_cool

func has_preset(preset: StringName) -> bool:
	return preset in PRESETS
