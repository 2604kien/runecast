extends RefCounted
## Compare predecessor fields while permitting only explicit new zero state.
static func strip_new_defaults(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			if key == "upgrade_rank" and value[key] == 0: continue
			if key == "relics" and value[key] == []: continue
			result[key] = strip_new_defaults(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(strip_new_defaults(item))
		return result
	return value
