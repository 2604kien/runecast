extends Node

# Distances are in logical viewport pixels, independent of desktop window scale.
const LONG_PRESS_SECONDS := 0.45
const MOVE_THRESHOLD := 18.0
const EMULATED_DEVICE := -1

# Tests disable automatic timing and advance the very same hold path explicitly.
var automatic_timing := true
var _targets: Array[Dictionary] = []
var _scrolls: Array[WeakRef] = []
var _gesture: Dictionary = {}
var _touches: Dictionary = {}
var _generation := 0
var _modal: WeakRef
var _suspended := false
var _disposed := false
var _suppress_emulated_mouse := false

func register_target(control: Control, tap: Callable, inspect: Callable = Callable()) -> void:
	_prune_targets()
	for entry in _targets:
		if entry.control.get_ref() == control:
			entry.tap = tap
			entry.inspect = inspect
			return
	_targets.append({"control": weakref(control), "tap": tap, "inspect": inspect})

func register_scroll(scroll: ScrollContainer) -> void:
	for reference in _scrolls:
		if reference.get_ref() == scroll:
			return
	_scrolls.append(weakref(scroll))

func cancel_pending() -> void:
	_generation += 1
	# Keep the physical stream until release: dismiss/refresh must not click through.
	if not _gesture.is_empty():
		_gesture.cancelled = true
		_gesture.target = null
		_gesture.tap = Callable()
		_gesture.inspect = Callable()

func set_modal(control: Control = null) -> void:
	cancel_pending()
	_modal = weakref(control) if control != null else null

func set_suspended(value: bool) -> void:
	cancel_pending()
	_suspended = value

func _process(delta: float) -> void:
	if automatic_timing:
		advance_time(delta)

func advance_time(seconds: float) -> void:
	if _disposed or _gesture.is_empty() or _gesture.cancelled or _gesture.moved or _gesture.inspected:
		return
	if _gesture.generation != _generation or (_gesture.target != null and not _valid_target(_gesture.target)):
		cancel_pending()
		return
	_gesture.elapsed += maxf(seconds, 0.0)
	if _gesture.elapsed >= LONG_PRESS_SECONDS and _gesture.inspect.is_valid():
		var action: Callable = _gesture.inspect
		_gesture.inspected = true
		action.call()

func _input(event: InputEvent) -> void:
	if _disposed:
		return
	if _route_modal_keys(event):
		get_viewport().set_input_as_handled()
		return
	var handled := false
	if event is InputEventScreenTouch:
		if event.device == EMULATED_DEVICE:
			# A real mouse event remains the only owner of mouse-to-touch emulation.
			handled = true
		else:
			handled = _touch(event)
	elif event is InputEventScreenDrag:
		if event.device == EMULATED_DEVICE:
			handled = true
		elif _gesture.get("kind", "") == "touch" and event.index == _gesture.id:
			_move(event.position)
			handled = true
		elif _touches.has(event.index):
			handled = bool(_touches[event.index])
	elif event is InputEventMouseButton:
		if event.device == EMULATED_DEVICE:
			handled = _suppress_emulated_mouse
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not _touches.is_empty():
				handled = true
			elif event.pressed:
				_suppress_emulated_mouse = false
				handled = not _gesture.is_empty() or _begin("mouse", 0, event.position)
			elif _gesture.get("kind", "") == "mouse":
				_finish(event.position, false)
				handled = true
	elif event is InputEventMouseMotion:
		if event.device == EMULATED_DEVICE:
			handled = _suppress_emulated_mouse
		elif _gesture.get("kind", "") == "mouse":
			_move(event.position)
			handled = true
	# Native modal Windows route their own viewport. Suspend consumes background
	# viewport input rather than leaving a path through to its ordinary Buttons.
	if handled or _suspended:
		get_viewport().set_input_as_handled()

func _touch(event: InputEventScreenTouch) -> bool:
	if event.pressed:
		var first := _touches.is_empty()
		var captured := false
		if first and _gesture.is_empty():
			captured = _suspended or _begin("touch", event.index, event.position)
			_suppress_emulated_mouse = captured
		else:
			# A second finger cannot steal ownership, including after the first lifts.
			captured = true
			if _gesture.get("kind", "") == "mouse":
				_suppress_emulated_mouse = true
		_touches[event.index] = captured
		return captured
	var handled := bool(_touches.get(event.index, false))
	_touches.erase(event.index)
	if _gesture.get("kind", "") == "touch" and event.index == _gesture.id:
		_finish(event.position, event.canceled)
		return true
	return handled

func _begin(kind: String, pointer_id: int, position: Vector2) -> bool:
	if _suspended or not _gesture.is_empty():
		return false
	var entry := _target_at(position)
	var target: Control = entry.get("control_node")
	var horizontal := _scroll_at(position, target, true)
	var vertical := _scroll_at(position, target, false)
	if target == null and horizontal == null and vertical == null:
		return false
	# Editable fields, native selectors and scrollbars keep their own GUI routing.
	if target == null and _native_control_at(get_parent(), position):
		return false
	_gesture = {
		"kind": kind, "id": pointer_id, "origin": position, "position": position,
		"target": weakref(target) if target != null else null,
		"tap": entry.get("tap", Callable()), "inspect": entry.get("inspect", Callable()),
		"horizontal": weakref(horizontal) if horizontal != null else null,
		"vertical": weakref(vertical) if vertical != null else null,
		"scroll": null, "scroll_start": 0.0, "axis": "",
		"elapsed": 0.0, "generation": _generation,
		"moved": false, "inspected": false, "cancelled": false,
	}
	if target != null and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus()
	return true

func _move(position: Vector2) -> void:
	if _gesture.is_empty():
		return
	_gesture.position = position
	if _gesture.cancelled or _gesture.inspected or _gesture.generation != _generation:
		return
	var displacement: Vector2 = position - _gesture.origin
	if not _gesture.moved and displacement.length() >= MOVE_THRESHOLD:
		_gesture.moved = true
		_gesture.axis = "horizontal" if absf(displacement.x) > absf(displacement.y) else "vertical"
		_gesture.scroll = _gesture[_gesture.axis]
		var scroll := _scroll_ref(_gesture.scroll)
		if scroll != null:
			_gesture.scroll_start = float(scroll.scroll_horizontal if _gesture.axis == "horizontal" else scroll.scroll_vertical)
	if _gesture.moved:
		var scroll := _scroll_ref(_gesture.scroll)
		if scroll != null:
			if _gesture.axis == "horizontal":
				scroll.scroll_horizontal = roundi(_gesture.scroll_start - displacement.x)
			else:
				scroll.scroll_vertical = roundi(_gesture.scroll_start - displacement.y)

func _finish(position: Vector2, cancelled: bool) -> void:
	_move(position)
	var pending := _gesture
	_gesture = {}
	if cancelled or pending.cancelled or pending.moved or pending.inspected or pending.generation != _generation:
		return
	if not _valid_target(pending.target):
		return
	var target: Control = pending.target.get_ref()
	if _contains(target, position) and pending.tap.is_valid():
		pending.tap.call()

func _target_at(position: Vector2) -> Dictionary:
	_prune_targets()
	for index in range(_targets.size() - 1, -1, -1):
		var entry := _targets[index]
		var control: Control = entry.control.get_ref()
		if _allowed(control) and _contains(control, position):
			var found := entry.duplicate()
			found.control_node = control
			return found
	return {}

func _scroll_at(position: Vector2, target: Control, horizontal: bool) -> ScrollContainer:
	var ancestor: Node = target
	while ancestor != null:
		if ancestor is ScrollContainer and _scroll_available(ancestor, horizontal) and _allowed(ancestor):
			return ancestor
		ancestor = ancestor.get_parent()
	var chosen: ScrollContainer
	var depth := -1
	for reference in _scrolls:
		var scroll := _scroll_ref(reference)
		if scroll == null or not _allowed(scroll) or not _contains(scroll, position) or not _scroll_available(scroll, horizontal):
			continue
		var candidate_depth := scroll.get_path().get_name_count()
		if candidate_depth > depth:
			chosen = scroll
			depth = candidate_depth
	return chosen

func _scroll_available(scroll: ScrollContainer, horizontal: bool) -> bool:
	return (scroll.horizontal_scroll_mode if horizontal else scroll.vertical_scroll_mode) != ScrollContainer.SCROLL_MODE_DISABLED

func _scroll_ref(reference: WeakRef) -> ScrollContainer:
	if reference == null:
		return null
	var scroll = reference.get_ref()
	return scroll if is_instance_valid(scroll) and not scroll.is_queued_for_deletion() else null

func _valid_target(reference: WeakRef) -> bool:
	if reference == null:
		return false
	var control = reference.get_ref()
	return is_instance_valid(control) and not control.is_queued_for_deletion() and _allowed(control) and control.is_visible_in_tree()

func _allowed(control: Control) -> bool:
	# Native Window children receive input in their own viewport, never here.
	if not control.is_inside_tree() or control.get_viewport() != get_viewport():
		return false
	if _modal == null:
		return true
	var modal = _modal.get_ref()
	return is_instance_valid(modal) and (control == modal or modal.is_ancestor_of(control))

func _route_modal_keys(event: InputEvent) -> bool:
	if _suspended or _modal == null or not (event is InputEventKey or event is InputEventAction):
		return false
	var modal = _modal.get_ref()
	if not is_instance_valid(modal) or not modal.is_visible_in_tree():
		return false
	var focused := get_viewport().gui_get_focus_owner()
	var step := 0
	if event.is_action_pressed("ui_focus_next"):
		step = 1
	elif event.is_action_pressed("ui_focus_prev"):
		step = -1
	elif focused == null or focused is BaseButton or not _allowed(focused):
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			step = 1
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			step = -1
	var background_accept := event.is_action("ui_accept") and (focused == null or not _allowed(focused))
	if step == 0 and not background_accept:
		return false
	var candidates: Array[Control] = []
	for entry in _targets:
		if not _valid_target(entry.control):
			continue
		var control: Control = entry.control.get_ref()
		if control.focus_mode != Control.FOCUS_NONE and not (control is BaseButton and control.disabled):
			candidates.append(control)
	if not candidates.is_empty():
		var index := candidates.find(focused)
		var next := posmod(index + step, candidates.size()) if index >= 0 else 0
		candidates[next].grab_focus()
	return true

func _contains(control: Control, position: Vector2) -> bool:
	if not control.is_visible_in_tree() or not control.get_global_rect().has_point(position):
		return false
	var ancestor := control.get_parent()
	while ancestor is Control:
		if ancestor.clip_contents and not ancestor.get_global_rect().has_point(position):
			return false
		ancestor = ancestor.get_parent()
	return true

func _native_control_at(node: Node, position: Vector2) -> bool:
	if (node is Window and node != get_viewport()) or (node is Control and not node.is_visible_in_tree()):
		return false
	for child in node.get_children():
		if _native_control_at(child, position):
			return true
	return node is Control and _allowed(node) and (node is BaseButton or node is LineEdit or node is TextEdit or node is Range) and _contains(node, position)

func _prune_targets() -> void:
	for index in range(_targets.size() - 1, -1, -1):
		var control = _targets[index].control.get_ref()
		if not is_instance_valid(control) or control.is_queued_for_deletion():
			_targets.remove_at(index)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		cancel_pending()
		# The OS may never deliver release after switching applications. A later
		# foreground touch must be allowed to start a fresh physical sequence.
		_gesture.clear()
		_touches.clear()
		_suppress_emulated_mouse = true

func _exit_tree() -> void:
	_disposed = true
	cancel_pending()
	_targets.clear()
	_scrolls.clear()
	_touches.clear()
	_gesture.clear()
