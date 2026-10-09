extends RefCounted

const Router = preload("res://scripts/ui/touch_router.gd")

# Synthetic viewport events exercise Godot's _input -> GUI path. They are not
# physical-device evidence. Timing advances the production hold path explicitly.
func run(check: Callable, tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 500)
	viewport.handle_input_locally = true
	tree.root.add_child(viewport)
	var host := Control.new()
	host.size = Vector2(400, 500)
	viewport.add_child(host)
	var page := ScrollContainer.new()
	page.size = Vector2(400, 500)
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.add_child(page)
	var body := Control.new()
	body.custom_minimum_size = Vector2(380, 1200)
	page.add_child(body)
	var hand := ScrollContainer.new()
	hand.position = Vector2(20, 80)
	hand.size = Vector2(350, 100)
	hand.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(hand)
	var row := Control.new()
	row.custom_minimum_size = Vector2(1200, 85)
	hand.add_child(row)
	var card := _button(row, Vector2.ZERO, Vector2(160, 80))
	var far_card := _button(row, Vector2(850, 0), Vector2(160, 80))
	var board := _button(body, Vector2(20, 230), Vector2(150, 100))
	var disabled := _button(body, Vector2(210, 230), Vector2(140, 100))
	disabled.disabled = true
	var native := LineEdit.new()
	native.position = Vector2(20, 360)
	native.size = Vector2(250, 50)
	body.add_child(native)
	var router := Router.new()
	router.automatic_timing = false
	host.add_child(router)
	var count := {"tap": 0, "inspect": 0, "far": 0, "board": 0, "disabled": 0, "close": 0}
	var tap := func(): count.tap += 1
	var inspect := func(): count.inspect += 1
	card.pressed.connect(tap)
	board.pressed.connect(func(): count.board += 1)
	router.register_target(card, tap, inspect)
	router.register_target(far_card, func(): count.far += 1, inspect)
	router.register_target(board, func(): count.board += 1, inspect)
	router.register_target(disabled, Callable(), func(): count.disabled += 1)
	router.register_scroll(page)
	router.register_scroll(hand)
	await tree.process_frame
	await tree.process_frame
	var position := card.get_global_rect().get_center()
	_touch(viewport, position, true)
	router.advance_time(Router.LONG_PRESS_SECONDS - 0.01)
	_touch(viewport, position, false)
	check.call(count.tap == 1 and count.inspect == 0, "Synthetic short touch taps exactly once before the long-press threshold.")
	_touch(viewport, position, true)
	router.advance_time(Router.LONG_PRESS_SECONDS)
	router.advance_time(10)
	_touch(viewport, position, false)
	check.call(count.tap == 1 and count.inspect == 1, "Synthetic long press inspects once and suppresses both short tap and repeat inspection.")
	_touch(viewport, position, true)
	_drag(viewport, position - Vector2(85, 2))
	router.advance_time(1)
	var hand_moved := hand.scroll_horizontal > 0
	_touch(viewport, position, false)
	check.call(count.tap == 1 and count.inspect == 1 and hand_moved and page.scroll_vertical == 0, "Synthetic horizontal hand scrolling cancels tap/inspection even after the finger returns to its origin.")
	hand.scroll_horizontal = 0
	await tree.process_frame
	position = card.get_global_rect().get_center()
	_touch(viewport, position, true)
	_drag(viewport, position - Vector2(2, 60))
	_touch(viewport, position - Vector2(2, 60), false)
	check.call(page.scroll_vertical > 0 and hand.scroll_horizontal == 0 and count.tap == 1, "Synthetic dominant vertical motion over a card scrolls the page without selecting the card.")
	page.scroll_vertical = 0
	await tree.process_frame
	position = board.get_global_rect().get_center()
	_touch(viewport, position, true)
	_drag(viewport, position - Vector2(0, 70))
	router.advance_time(1)
	_touch(viewport, position - Vector2(0, 70), false)
	check.call(page.scroll_vertical > 0 and count.board == 0 and count.inspect == 1, "Synthetic board drag scrolls the page without placement or inspection.")
	page.scroll_vertical = 0
	await tree.process_frame
	position = card.get_global_rect().get_center()
	_touch(viewport, position, true, 0)
	_touch(viewport, position, true, 1)
	_touch(viewport, position, false, 1)
	_touch(viewport, position, false, 0)
	check.call(count.tap == 2, "Synthetic secondary finger cannot produce a second tap.")
	_touch(viewport, position, true, 0)
	_touch(viewport, position, true, 1)
	_touch(viewport, position, false, 0)
	_touch(viewport, position, true, 2)
	_touch(viewport, position, false, 2)
	_touch(viewport, position, false, 1)
	check.call(count.tap == 3, "Synthetic remaining secondary pointers cannot take ownership after the primary lifts.")
	_touch(viewport, position, true)
	_mouse(viewport, position, true, Router.EMULATED_DEVICE)
	_touch(viewport, position, false)
	_mouse(viewport, position, false, Router.EMULATED_DEVICE)
	check.call(count.tap == 4, "Synthetic touch plus emulated mouse processes one physical gesture once.")
	_mouse(viewport, position, true)
	_touch(viewport, position, true, 0, false, Router.EMULATED_DEVICE)
	_touch(viewport, position, false, 0, false, Router.EMULATED_DEVICE)
	_mouse(viewport, position, false)
	check.call(count.tap == 5, "Synthetic real mouse plus emulated touch preserves exactly one desktop click.")
	_touch(viewport, position, true)
	router.cancel_pending()
	router.advance_time(1)
	_touch(viewport, position, false)
	check.call(count.tap == 5 and count.inspect == 1, "Synthetic cancellation invalidates the pending hold and swallows its eventual release.")
	_touch(viewport, position, true)
	_touch(viewport, position, false, 0, true)
	check.call(count.tap == 5 and count.inspect == 1, "Synthetic OS pointer cancellation cannot activate a card.")
	_touch(viewport, disabled.get_global_rect().get_center(), true)
	router.advance_time(Router.LONG_PRESS_SECONDS)
	_touch(viewport, disabled.get_global_rect().get_center(), false)
	check.call(count.disabled == 1, "Synthetic long press can inspect an unavailable disabled control.")
	# A fully off-screen card cannot be hit through its clipping ScrollContainer.
	_touch(viewport, far_card.get_global_rect().get_center(), true)
	_touch(viewport, far_card.get_global_rect().get_center(), false)
	check.call(count.far == 0, "Synthetic off-screen cards are excluded by ancestor clipping.")
	hand.scroll_horizontal = 820
	await tree.process_frame
	var far_position := far_card.get_global_rect().get_center()
	_touch(viewport, far_position, true)
	_touch(viewport, far_position, false)
	check.call(count.far == 1, "Synthetic larger-hand scrolling makes a formerly off-screen card selectable.")
	_touch(viewport, far_position, true)
	router.advance_time(Router.LONG_PRESS_SECONDS)
	_touch(viewport, far_position, false)
	check.call(count.inspect == 2 and count.far == 1, "Synthetic larger-hand card remains inspectable without selecting it.")
	hand.scroll_horizontal = 0
	await tree.process_frame
	var modal := Control.new()
	modal.size = Vector2(400, 500)
	host.add_child(modal)
	var modal_scroll := ScrollContainer.new()
	modal_scroll.position = Vector2(20, 20)
	modal_scroll.size = Vector2(350, 280)
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(modal_scroll)
	var modal_body := Control.new()
	modal_body.custom_minimum_size = Vector2(330, 1000)
	modal_scroll.add_child(modal_body)
	var close := _button(modal, Vector2(20, 350), Vector2(150, 80))
	router.register_scroll(modal_scroll)
	router.register_target(close, func():
		count.close += 1
		modal.hide()
		router.set_modal()
	)
	router.set_modal(modal)
	await tree.process_frame
	board.grab_focus()
	_key(viewport, KEY_ENTER, true)
	_key(viewport, KEY_ENTER, false)
	_action(viewport, "ui_focus_next")
	_action(viewport, "ui_down")
	check.call(viewport.gui_get_focus_owner() == close and count.close == 0 and count.board == 0, "Synthetic modal keyboard focus stays inside the inspector and cannot activate a previously focused background button.")
	_touch(viewport, Vector2(150, 220), true)
	_drag(viewport, Vector2(150, 140))
	_touch(viewport, Vector2(150, 140), false)
	check.call(modal_scroll.scroll_vertical > 0 and page.scroll_vertical == 0 and count.board == 0, "Synthetic inspector scrolling affects only its own content, never the background board/page.")
	_touch(viewport, close.get_global_rect().get_center(), true)
	_touch(viewport, close.get_global_rect().get_center(), false)
	check.call(count.close == 1 and count.board == 0 and count.tap == 5, "Synthetic modal dismissal consumes its release without clicking background controls.")
	position = card.get_global_rect().get_center()
	_touch(viewport, position, true)
	router.set_suspended(true)
	router.advance_time(1)
	_mouse(viewport, board.get_global_rect().get_center(), true)
	_mouse(viewport, board.get_global_rect().get_center(), false)
	board.grab_focus()
	_key(viewport, KEY_ENTER, true)
	_key(viewport, KEY_ENTER, false)
	check.call(count.board == 0, "Synthetic root-viewport input cannot bypass native-dialog suspension through GUI mouse or keyboard activation.")
	router.set_suspended(false)
	_touch(viewport, position, false)
	check.call(count.tap == 5 and count.inspect == 2, "Synthetic native-dialog suspension cancels pending gestures across dismiss/resume.")
	_touch(viewport, Vector2(370, 430), true)
	router.advance_time(1)
	_drag(viewport, Vector2(370, 370))
	_touch(viewport, Vector2(370, 370), false)
	check.call(page.scroll_vertical > 0, "Synthetic scrolling from blank page space still works after holding before movement.")
	page.scroll_vertical = 0
	await tree.process_frame
	position = card.get_global_rect().get_center()
	_touch(viewport, position, true)
	card.queue_free()
	await tree.process_frame
	router.advance_time(1)
	_touch(viewport, position, false)
	check.call(count.tap == 5 and count.inspect == 2, "Synthetic freed-card callback cannot run after hand rebuild.")
	hand.scroll_horizontal = 820
	await tree.process_frame
	far_position = far_card.get_global_rect().get_center()
	_touch(viewport, far_position, true, 0)
	_touch(viewport, far_position, true, 1)
	router.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	router.advance_time(1)
	_mouse(viewport, far_position, false, Router.EMULATED_DEVICE)
	_touch(viewport, far_position, true)
	router.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	router.advance_time(1)
	_touch(viewport, far_position, true)
	_touch(viewport, far_position, false)
	check.call(count.far == 2 and count.inspect == 2, "Synthetic application/native-window focus loss cancels pointers even when the OS drops their releases, then accepts a fresh foreground touch.")
	_mouse(viewport, far_position, true)
	_mouse(viewport, far_position, true)
	_mouse(viewport, far_position, false)
	check.call(count.far == 3, "Synthetic repeated mouse-down remains one routed click without a second GUI press.")
	_mouse(viewport, far_position, true)
	_touch(viewport, far_position, true, 3)
	_mouse(viewport, far_position, true, Router.EMULATED_DEVICE)
	_mouse(viewport, far_position, false, Router.EMULATED_DEVICE)
	_touch(viewport, far_position, false, 3)
	_mouse(viewport, far_position, false)
	check.call(count.far == 4, "Synthetic touch during a held real mouse gesture cannot steal ownership or duplicate its click through emulation.")
	far_card.pressed.connect(func(): count.far += 1)
	far_card.grab_focus()
	_key(viewport, KEY_ENTER, true)
	_key(viewport, KEY_ENTER, false)
	check.call(count.far == 5, "Synthetic keyboard Enter retains the native focused Button activation path.")
	_touch(viewport, far_position, true)
	_mouse(viewport, board.get_global_rect().get_center(), true, Router.EMULATED_DEVICE)
	_touch(viewport, far_position, false)
	_mouse(viewport, board.get_global_rect().get_center(), false, Router.EMULATED_DEVICE)
	check.call(count.far == 6 and count.board == 0, "Synthetic emulated mouse release outside the original touch target cannot click another control.")
	_touch(viewport, far_position, true)
	far_card.hide()
	router.advance_time(1)
	far_card.show()
	_touch(viewport, far_position, false)
	check.call(count.far == 6 and count.inspect == 2, "Synthetic hidden target cancels its pending action even if it reappears before release.")
	_touch(viewport, far_position, true)
	_drag(viewport, far_position + Vector2(Router.MOVE_THRESHOLD, 0))
	router.advance_time(1)
	_touch(viewport, far_position, false)
	check.call(count.far == 6 and count.inspect == 2, "Synthetic movement exactly at the centralized threshold cancels tap and hold.")
	_touch(viewport, board.get_global_rect().get_center(), true)
	host.remove_child(router)
	router.advance_time(1)
	check.call(count.board == 0 and count.inspect == 2, "Router teardown discards retained gestures and late timing is harmless.")
	router.free()
	viewport.queue_free()
	await tree.process_frame

func _button(parent: Node, position: Vector2, extent: Vector2) -> Button:
	var button := Button.new()
	button.position = position
	button.size = extent
	parent.add_child(button)
	return button

func _touch(viewport: Viewport, position: Vector2, pressed: bool, index: int = 0, cancelled: bool = false, device: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	event.canceled = cancelled
	event.device = device
	viewport.push_input(event, true)

func _drag(viewport: Viewport, position: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = position
	event.index = index
	viewport.push_input(event, true)

func _mouse(viewport: Viewport, position: Vector2, pressed: bool, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.device = device
	viewport.push_input(event, true)

func _key(viewport: Viewport, keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	viewport.push_input(event, true)

func _action(viewport: Viewport, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	viewport.push_input(event, true)
