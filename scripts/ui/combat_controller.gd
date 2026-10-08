extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const Presentation = preload("res://scripts/ui/combat_presentation.gd")

signal changed
signal presentation_started(result: Dictionary)

var _combat: Combat
var _presenter: Presentation
var _busy := false
var _closed := false
var _transitioning := false
var _token := 0

func _init(combat: Combat, presenter: Presentation = null) -> void:
	_combat = combat
	_presenter = presenter if presenter != null else Presentation.new()

func snapshot() -> Dictionary:
	return _combat.snapshot()

func is_busy() -> bool:
	return _busy

func can_edit() -> bool:
	return not _closed and not _busy and not _transitioning and _combat.state == "playing"

func set_presenter(presenter: Presentation) -> bool:
	if _closed or _busy or _transitioning or presenter == null:
		return false
	_presenter = presenter
	return true

func command(name: String, arguments: Dictionary = {}) -> bool:
	if not can_edit():
		return false
	# Lock before model execution or any signal/callback can reenter this method.
	_busy = true
	_token += 1
	var token := _token
	var result := _combat.execute(name, arguments)
	if not result.accepted or not name in ["cast", "pass", "technique"]:
		_busy = false
		changed.emit()
		return result.accepted
	changed.emit()
	if not _is_active(token):
		return true
	presentation_started.emit(result.duplicate(true))
	if not _is_active(token):
		return true
	# A retained callback must neither retain a dead controller nor target a new action.
	var owner: WeakRef = weakref(self)
	var completed := func():
		var controller = owner.get_ref()
		if controller != null:
			controller._complete(token)
	_presenter.present(result.duplicate(true), completed)
	return true

func _is_active(token: int) -> bool:
	return not _closed and not _transitioning and _busy and token == _token

func _complete(token: int) -> void:
	if not _is_active(token):
		return
	_busy = false
	changed.emit()

func _cancel_pending() -> void:
	# Invalidate first: cancel() is allowed to invoke its old completion synchronously.
	_token += 1
	var was_busy := _busy
	_busy = false
	if was_busy:
		_presenter.cancel()

func cancel_presentation() -> void:
	if _closed or _transitioning:
		return
	_transitioning = true
	_cancel_pending()
	_transitioning = false
	if _closed:
		return
	changed.emit()

func restart() -> bool:
	if _closed or _transitioning:
		return false
	_transitioning = true
	_cancel_pending()
	if _closed:
		_transitioning = false
		return false
	_combat.reset()
	_transitioning = false
	changed.emit()
	return true

func dispose() -> void:
	if _closed:
		return
	_closed = true
	_cancel_pending()
