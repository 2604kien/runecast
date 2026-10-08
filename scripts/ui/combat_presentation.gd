extends RefCounted

# RC-017 can override these two methods. The batch is detached model output;
# completion is a notification, never permission to apply gameplay effects.
func present(_result: Dictionary, completed: Callable) -> void:
	completed.call()

func cancel() -> void:
	pass
