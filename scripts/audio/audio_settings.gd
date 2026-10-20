extends RefCounted
## Audio preferences share the existing ConfigFile with accessibility and future
## options. Loading old files is read-only; the next user edit writes missing defaults.
const DEFAULT_PATH := "user://settings.cfg"
const DEFAULTS := {
	"enabled": true, "music_volume": 1.0, "sfx_volume": 1.0,
	"music_muted": false, "sfx_muted": false, "reduced_motion": false,
}

static func normalize(values: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in DEFAULTS:
		var value = values.get(key, DEFAULTS[key])
		if key.ends_with("_volume"):
			result[key] = clampf(float(value), 0.0, 1.0) if (value is float or value is int) and is_finite(float(value)) else DEFAULTS[key]
		else:
			result[key] = value if value is bool else DEFAULTS[key]
	return result

static func load_values(path: String = DEFAULT_PATH) -> Dictionary:
	var config := ConfigFile.new()
	var values := DEFAULTS.duplicate()
	if config.load(path) == OK:
		for key in DEFAULTS:
			values[key] = config.get_value("accessibility" if key == "reduced_motion" else "audio", key, DEFAULTS[key])
	return normalize(values)

static func save_values(values: Dictionary, path: String = DEFAULT_PATH) -> Error:
	var config := ConfigFile.new()
	var error := config.load(path)
	# A corrupt/unreadable file must not erase unrelated settings.
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return error
	var safe := normalize(values)
	for key in DEFAULTS:
		config.set_value("accessibility" if key == "reduced_motion" else "audio", key, safe[key])
	return config.save(path)
