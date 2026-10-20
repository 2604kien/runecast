extends RefCounted
## Existing UI regression fixtures inspect settled values. Advance the real
## production adapter deterministically, while leaving Delayed seams pending.
static func finish(scene: Control) -> void:
	if scene.controller == null: return
	var presenter = scene.controller.get_presenter()
	if presenter != null and presenter.has_method("finish"):
		presenter.finish()
