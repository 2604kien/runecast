extends RefCounted

# Synthetic pointer integration: these are real Viewport input-routing checks,
# with deterministic hold timing. They are not physical-device acceptance.
const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Router = preload("res://scripts/ui/touch_router.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")
const ProductionUI = preload("res://tests/ui_production_tests.gd")

func run_followup(check: Callable, tree: SceneTree, capture_directory: String = "") -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1600)
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	await _layout(tree)
	check.call(scene.size == Vector2(720, 1600) and scene.gestures != null, "Synthetic touch fixture runs the actual production scene in its own portrait viewport.")
	var original_setup: Dictionary = scene.initial_setup.duplicate(true)
	_seed_with_both_card_types(scene, original_setup)
	await _layout(tree)
	await _inspection(scene, viewport, tree, check, capture_directory)
	await _editing(scene, viewport, tree, check, capture_directory)
	await _details_and_modal(scene, viewport, tree, check, capture_directory)
	await _gesture_conflicts(scene, viewport, tree, check)
	await _lifecycle(scene, viewport, tree, check)
	await _large_hand(scene, viewport, tree, check, capture_directory)
	await _small_inspector(scene, viewport, tree, check, capture_directory)
	await _encounter_transition(scene, viewport, tree, check)
	await _teardown(scene, viewport, tree, check)
	await _invalid_startup(tree, check)
	await _experiment_relaunch(tree, check)

func _inspection(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable, directory: String) -> void:
	for type in ["rune", "technique"]:
		var uid := _uid(scene.game, type)
		check.call(uid >= 0, "Synthetic inspection fixture includes a real %s card." % type)
		if uid < 0: continue
		var before := _state(scene)
		await _reveal(scene, _card(scene, uid), tree)
		_hold(viewport, scene, _card(scene, uid))
		check.call(scene.inspector.visible and scene.inspector_title.text != "" and scene.inspector_text.text.to_lower().contains("energy") and _state(scene) == before, "Holding a hand %s opens live details without a command, RNG change, inventory spend or Undo step." % type)
		check.call(scene.selected_uid == -1 and not scene.inspector_text.text.is_empty(), "Long-press release suppresses selection/activation for the hand %s." % type)
		await _capture(viewport, tree, directory, "inspect-hand-%s.png" % type, check)
		await _close(scene, viewport, tree)
		check.call(not scene.inspector.visible and _state(scene) == before, "Closing the %s inspector through touch does not click through." % type)
	var technique := _uid(scene.game, "technique")
	var before := _state(scene)
	await _reveal(scene, scene.inspect_button, tree)
	_tap(viewport, scene.inspect_button)
	await _layout(tree)
	await _reveal(scene, _card(scene, technique), tree)
	_tap(viewport, _card(scene, technique))
	check.call(scene.inspect_mode and scene.inspector.visible and _state(scene) == before, "Discoverable Inspect mode turns a technique's short tap into read-only inspection.")
	await _close(scene, viewport, tree)
	scene._cancel_selection()
	await _layout(tree)
	for kind in ["straight", "corner", "split", "join"]:
		before = _state(scene)
		await _reveal(scene, scene.stock_buttons[kind], tree)
		_hold(viewport, scene, scene.stock_buttons[kind])
		check.call(scene.inspector.visible and scene.inspector_text.text.contains(str(scene.game.stock[kind])) and scene.inspector_text.text.contains(str(scene.game.stock_totals[kind])) and _state(scene) == before, "Holding %s stock shows live available/total inventory without selecting or spending it." % kind)
		await _close(scene, viewport, tree)
	var endpoints := _endpoints(scene.game.board)
	for kind in ["begin", "end"]:
		before = _state(scene)
		await _reveal(scene, scene.cells[endpoints[kind]], tree)
		_hold(viewport, scene, scene.cells[endpoints[kind]])
		check.call(scene.inspector.visible and scene.inspector_title.text.to_lower().contains(kind) and scene.inspector_text.text.to_lower().contains("direction") and _state(scene) == before, "Holding %s displays its current ports safely." % kind)
		await _close(scene, viewport, tree)

func _editing(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable, directory: String) -> void:
	scene._exact_replay()
	await _layout(tree)
	var empty := _empty_cells(scene.game.board)
	var endpoints := _endpoints(scene.game.board)
	var before := _state(scene)
	await _reveal(scene, scene.stock_buttons.straight, tree)
	_tap(viewport, scene.stock_buttons.straight)
	check.call(scene.selected_tool == "straight" and scene.stock_buttons.straight.button_pressed and scene.cells[empty[0]].preview > 0 and scene.cells[endpoints.begin].preview < 0 and _state(scene) == before, "A real tool tap selects it and paints legal sockets/protected endpoints without model mutation.")
	await _capture(viewport, tree, directory, "selected-tool-preview.png", check)
	await _reveal(scene, scene.cells[empty[0]], tree)
	_tap(viewport, scene.cells[empty[0]])
	check.call(scene.game.board[empty[0]].get("kind") == "straight" and scene.game.stock.straight == before.snapshot.stock.straight - 1 and not scene.game.forecast.valid, "Touch placement accepts a legal construction step while the circuit is incomplete.")
	await _reveal(scene, scene.cancel_button, tree)
	_tap(viewport, scene.cancel_button)
	check.call(scene.selected_tool == "" and scene.selected_uid == -1 and scene.selected_cell == -1 and scene.cells.all(func(cell): return cell.preview == 0), "Touch Cancel clears the card/tool/cell selection and all candidate overlays.")
	var uid := _uid(scene.game, "rune")
	await _layout(tree)
	await _reveal(scene, _card(scene, uid), tree)
	_tap(viewport, _card(scene, uid))
	check.call(scene.selected_uid == uid and _card(scene, uid).button_pressed, "A short rune tap visibly selects its exact UID.")
	await _layout(tree)
	await _reveal(scene, scene.cells[empty[0]], tree)
	_tap(viewport, scene.cells[empty[0]])
	check.call(scene.game.board[empty[0]].get("uid", -1) == uid and scene.selected_uid == -1 and scene.game.stock.straight == before.snapshot.stock.straight, "Installing the selected rune consumes its hand identity and immediately refunds the replaced connector.")
	before = _state(scene)
	_hold(viewport, scene, scene.cells[empty[0]])
	check.call(scene.inspector.visible and scene.inspector_text.text.to_lower().contains("disconnected") and _state(scene) == before, "An installed disconnected rune is inspectable without an edit.")
	await _close(scene, viewport, tree)
	for kind in ["straight", "corner", "split", "join"]:
		await _reveal(scene, scene.stock_buttons[kind], tree)
		_tap(viewport, scene.stock_buttons[kind])
		await _reveal(scene, scene.cells[empty[1]], tree)
		_tap(viewport, scene.cells[empty[1]])
		before = _state(scene)
		_hold(viewport, scene, scene.cells[empty[1]])
		check.call(scene.inspector.visible and scene.inspector_title.text.to_lower().contains(kind) and _state(scene) == before, "An installed %s uses the same safe long-press inspection path." % kind)
		await _close(scene, viewport, tree)
	scene._cancel_selection()
	await _layout(tree)
	await _reveal(scene, scene.cells[endpoints.begin], tree)
	_tap(viewport, scene.cells[endpoints.begin])
	before = _state(scene)
	check.call(scene.selected_cell == endpoints.begin and scene.cells[endpoints.begin].chosen and not scene.action_buttons.rotate.disabled and scene.action_buttons.flip.disabled, "Touch selects Begin visibly; Rotate is enabled and unsupported Flip is disabled.")
	await _reveal(scene, scene.action_buttons.rotate, tree)
	_tap(viewport, scene.action_buttons.rotate)
	check.call(scene.game.board[endpoints.begin].rotation == (int(before.snapshot.board[endpoints.begin].rotation) + 1) % 4 and scene.status.text.contains("Undo restores") and scene.game.stock == before.snapshot.stock, "The touch-sized Rotate control changes the selected endpoint and explains its direction without spending stock.")
	await _capture(viewport, tree, directory, "selected-rotated-endpoint.png", check)
	await _reveal(scene, scene.action_buttons.undo, tree)
	_tap(viewport, scene.action_buttons.undo)
	check.call(scene.game.board == before.snapshot.board and scene.selected_cell == -1, "Touch Undo restores endpoint geometry and clears stale selection.")
	for tool in ["straight", "erase"]:
		before = _state(scene)
		scene._select_tool(tool)
		await _reveal(scene, scene.cells[endpoints.end], tree)
		_tap(viewport, scene.cells[endpoints.end])
		check.call(scene.selected_cell == endpoints.end and scene.selected_tool == "" and _state(scene) == before and scene.status.text.to_lower().contains("protected"), "%s on End safely selects it and explains protection without a gameplay command." % tool)
	scene._exact_replay()
	await _layout(tree)
	empty = _empty_cells(scene.game.board)
	var total: int = scene.game.stock_totals.straight
	scene._select_tool("straight")
	for index in range(total):
		await _reveal(scene, scene.cells[empty[index]], tree)
		_tap(viewport, scene.cells[empty[index]])
	before = _state(scene)
	await _reveal(scene, scene.cells[empty[total]], tree)
	_tap(viewport, scene.cells[empty[total]])
	check.call(_state(scene) == before and scene.game.stock.straight == 0 and scene.cells[empty[total]].preview < 0 and scene.status.text.contains("You own"), "Exhausted stock marks empty sockets unavailable and rejects touch placement with a concise reason and no command.")
	await _capture(viewport, tree, directory, "unavailable-stock.png", check)
	scene._select_tool("erase")
	await _reveal(scene, scene.cells[empty[0]], tree)
	_tap(viewport, scene.cells[empty[0]])
	check.call(scene.game.stock.straight == 1 and scene.game.board[empty[0]].is_empty() and scene.stock_buttons.straight.text.contains("1 /"), "Touch Erase refunds one connector and refreshes finite-stock feedback immediately.")
	scene._undo()
	check.call(scene.game.stock.straight == 0 and scene.game.board[empty[0]].get("kind") == "straight" and scene.selected_tool == "", "Undo of Erase reinstalls the reserved connector and cancels the erase tool.")

func _details_and_modal(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable, directory: String) -> void:
	scene._exact_replay()
	await _layout(tree)
	scene._select_tool("straight")
	var index: int = _empty_cells(scene.game.board)[0]
	await _reveal(scene, scene.cells[index], tree)
	var before := _state(scene)
	_hold(viewport, scene, scene.cells[index])
	await _layout(tree)
	_tap(viewport, scene.cells[index])
	scene._cell_pressed(index)
	scene._cast()
	check.call(scene.inspector.visible and _state(scene) == before, "The modal consumes background board touches, and direct gameplay callbacks also respect its lock.")
	_escape(viewport)
	check.call(not scene.inspector.visible and scene.selected_tool == "straight" and _state(scene) == before, "Keyboard Escape dismisses the inspector without executing or clearing the underlying tool.")
	_escape(viewport)
	check.call(scene.selected_tool == "" and scene.selected_cell == -1 and _state(scene) == before, "A second keyboard Escape cancels the active selection without changing combat.")
	var details: Button = scene.inspect_button.get_parent().get_child(2)
	await _reveal(scene, details, tree)
	_tap(viewport, details)
	await _layout(tree)
	check.call(scene.inspector.visible and scene.inspector_pass.visible and scene.inspector_text.text.contains(scene.game.forecast.message) and _state(scene) == before, "The actual Details / Pass control explains an incomplete circuit without a permanent forecast strip or model changes.")
	_tap(viewport, scene.inspector_pass)
	await _layout(tree)
	check.call(scene.inspector_confirm_pass.visible and not scene.inspector_pass.visible and _state(scene) == before, "The first Pass touch only opens an explicit consequence confirmation.")
	await _capture(viewport, tree, directory, "pass-confirmation.png", check)
	_tap(viewport, scene.inspector_confirm_pass)
	check.call(scene.game.turn == int(before.snapshot.turn) + 1 and scene.game.player_hp == int(before.snapshot.player_hp) - int(before.snapshot.intent) and not scene.inspector.visible and scene.selected_tool == "", "Confirm Pass advances exactly one turn, applies the unshielded enemy attack and closes the modal.")
	scene._show_details()
	scene._confirm_pass_details()
	scene._restart()
	before = _state(scene)
	scene._accept_pass_details()
	check.call(_state(scene) == before and not scene.inspector.visible, "A retained Pass-confirmation callback cannot act after Restart closes its stale panel.")

func _gesture_conflicts(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable) -> void:
	scene._exact_replay()
	await _layout(tree)
	var technique := _uid(scene.game, "technique")
	await _reveal(scene, _card(scene, technique), tree)
	var point: Vector2 = _card(scene, technique).get_global_rect().get_center()
	var before := _state(scene)
	_touch(viewport, point, true)
	_drag(viewport, point + Vector2(-Router.MOVE_THRESHOLD - 12, 1), Vector2(-Router.MOVE_THRESHOLD - 12, 1))
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	_touch(viewport, point + Vector2(-Router.MOVE_THRESHOLD - 12, 1), false)
	check.call(_state(scene) == before and not scene.inspector.visible and scene.selected_uid == -1, "A horizontal movement on a real technique card cancels both its tap and pending long press, including release.")
	_touch(viewport, point, true)
	_touch(viewport, point, false, 0, true)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	check.call(_state(scene) == before and not scene.inspector.visible, "A cancelled pointer on the real hand cannot execute later.")
	var uid := _uid(scene.game, "rune")
	await _reveal(scene, _card(scene, uid), tree)
	point = _card(scene, uid).get_global_rect().get_center()
	_touch(viewport, point, true)
	_touch(viewport, point, true, 1)
	_touch(viewport, point, false, 1)
	_touch(viewport, point, false)
	_mouse(viewport, point, true, Router.EMULATED_DEVICE)
	_mouse(viewport, point, false, Router.EMULATED_DEVICE)
	check.call(scene.selected_uid == uid and _state(scene) == before, "Secondary fingers and emulated mouse events cannot duplicate the real card gesture.")
	scene._cancel_selection()
	await _layout(tree)
	await _reveal(scene, _card(scene, technique), tree)
	point = _card(scene, technique).get_global_rect().get_center()
	var card_id: String = _card_id(scene.game, technique)
	var cost: int = scene.game.catalog[card_id].cost
	_touch(viewport, point, true)
	_touch(viewport, point, true, 1)
	_touch(viewport, point, false)
	_touch(viewport, point, false, 1)
	_mouse(viewport, point, true, Router.EMULATED_DEVICE)
	_mouse(viewport, point, false, Router.EMULATED_DEVICE)
	check.call(_card_id(scene.game, technique) == "" and scene.game.energy == before.snapshot.energy - cost and scene.controller._combat._action_id == before.action_id + 1, "A short technique tap still activates exactly once despite secondary pointers and touch-to-mouse emulation.")
	check.call(scene.game.undo_count == 0 and scene.selected_uid == -1 and not scene.inspector.visible, "Technique activation commits its edit boundary and leaves no stale selection or inspector.")
	scene._exact_replay()
	await _layout(tree)
	scene._select_tool("straight")
	var index: int = _empty_cells(scene.game.board)[0]
	await _reveal(scene, scene.cells[index], tree)
	point = scene.cells[index].get_global_rect().get_center()
	before = _state(scene)
	_touch(viewport, point, true)
	_drag(viewport, point - Vector2(0, 120), Vector2(0, -120))
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	_touch(viewport, point - Vector2(0, 120), false)
	check.call(_state(scene) == before and not scene.inspector.visible, "Vertical drag beginning on an eligible board socket cannot place or inspect after release.")
	scene._cancel_selection()

func _lifecycle(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable) -> void:
	for transition in ["_pass", "_restart", "_exact_replay"]:
		scene._exact_replay()
		await _layout(tree)
		var uid := _uid(scene.game, "rune")
		scene._select_card(uid)
		scene._inspect_hand(uid)
		# An authoritative change can also originate outside the modal's controls.
		if transition == "_pass": scene.controller.command("pass")
		else: scene.call(transition)
		check.call(scene.selected_uid == -1 and scene.selected_tool == "" and scene.selected_cell == -1 and not scene.inspector.visible and not scene.inspect_mode, "%s invalidates selected hand identity, panel and inspection mode." % transition)
	scene._exact_replay()
	await _layout(tree)
	var uid := _uid(scene.game, "rune")
	await _reveal(scene, _card(scene, uid), tree)
	var point: Vector2 = _card(scene, uid).get_global_rect().get_center()
	_touch(viewport, point, true)
	scene._restart()
	var before := _state(scene)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	_touch(viewport, point, false)
	check.call(_state(scene) == before and not scene.inspector.visible and scene.selected_uid == -1, "A pending hand hold cannot inspect or select its old UID after Restart.")
	scene._exact_replay()
	await _layout(tree)
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	uid = _uid(scene.game, "rune")
	await _reveal(scene, _card(scene, uid), tree)
	point = _card(scene, uid).get_global_rect().get_center()
	_touch(viewport, point, true)
	scene._pass()
	before = _state(scene)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	_touch(viewport, point, false)
	_tap(viewport, scene.stock_buttons.straight)
	check.call(scene.controller.is_busy() and _state(scene) == before and scene.selected_uid == -1 and scene.selected_tool == "" and not scene.inspector.visible, "Presentation start cancels an in-flight hand gesture, and touch input cannot bypass busy controller guards.")
	scene._exact_replay()
	before = _state(scene)
	delayed.complete()
	check.call(not scene.controller.is_busy() and _state(scene) == before and not scene.inspector.visible, "A stale presentation callback after Exact replay cannot resurrect inspection or mutate the fresh encounter.")

func _large_hand(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable, directory: String) -> void:
	var documents := {}
	for kind in ["runes", "boards", "enemies", "loadouts", "encounter"]:
		var path := "res://data/%s.json" % kind
		if kind in ["boards", "loadouts", "encounter"]: path = "res://data/production_%s.json" % kind
		documents[kind] = JSON.parse_string(FileAccess.get_file_as_string(path))
	documents.loadouts[0].owned_cards = []
	for index in range(14): documents.loadouts[0].owned_cards.append("focus" if index % 3 == 0 else "spark")
	documents.loadouts[0].opening_draw = 14
	documents.loadouts[0].draw_per_turn = 14
	var loaded := Loader.validate_documents(documents, {}, null, scene.initial_setup.production)
	check.call(loaded.ok, "Synthetic larger-hand fixture uses independently validated content without changing shipped assets.")
	if not loaded.ok: return
	ProductionUI.new()._inject(scene, loaded.setup)
	await _layout(tree)
	await _reveal(scene, scene.hand_scroll, tree)
	var before := _state(scene)
	var start: Vector2 = scene.hand_scroll.get_global_rect().get_center()
	_touch(viewport, start, true)
	_drag(viewport, start - Vector2(440, 0), Vector2(-440, 0))
	_touch(viewport, start - Vector2(440, 0), false)
	await _layout(tree)
	check.call(scene.hand_scroll.scroll_horizontal > 0 and _state(scene) == before and scene.selected_uid == -1 and not scene.inspector.visible, "Dragging the actual fourteen-card hand scrolls horizontally without playing or selecting any card.")
	for attempt in range(4):
		_touch(viewport, start, true)
		_drag(viewport, start - Vector2(440, 0), Vector2(-440, 0))
		_touch(viewport, start - Vector2(440, 0), false)
		await _layout(tree)
	var uid: int = scene.game.hand[-1].uid
	var last: Button = _card(scene, uid)
	check.call(scene.hand_scroll.get_global_rect().encloses(last.get_global_rect()), "Repeated actual hand drags expose the last off-screen card.")
	_hold(viewport, scene, last)
	check.call(scene.inspector.visible and _state(scene) == before, "The newly exposed last card supports long-press inspection with unchanged model and RNG.")
	await _close(scene, viewport, tree)
	await _layout(tree)
	_tap(viewport, _card(scene, uid))
	check.call(scene.selected_uid == uid and _state(scene) == before, "The off-screen rune remains selectable after scrolling and dismissing its inspector.")
	await _capture(viewport, tree, directory, "large-hand-scrolled.png", check)

func _small_inspector(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable, directory: String) -> void:
	scene._cancel_selection()
	viewport.size = Vector2i(360, 640)
	await _layout(tree)
	var controls: Array = [scene.encounter_title, scene.stats, scene.hand_scroll, scene.status, scene.cast_button, scene.inspect_button, scene.cancel_button]
	controls.append_array(scene.cells)
	controls.append_array(scene.edit_buttons)
	var outside: Array[String] = []
	for control in controls:
		var rect: Rect2 = control.get_global_rect()
		if rect.position.x < 0 or rect.end.x > viewport.size.x + 1: outside.append("%s %s" % [control.name, rect])
	check.call(outside.is_empty(), "Board, text, stock, editing, inspection and hand containers remain within the smaller portrait width. " + "; ".join(outside))
	scene._select_tool("straight")
	await _layout(tree)
	scene.page_scroll.scroll_vertical += int(scene.cells[0].get_global_rect().position.y - 18)
	await _layout(tree)
	var page_before: int = scene.page_scroll.scroll_vertical
	var board_before := _state(scene)
	var board_origin: Vector2 = scene.cells[4].get_global_rect().get_center()
	_touch(viewport, board_origin, true)
	_drag(viewport, board_origin - Vector2(0, 100), Vector2(0, -100))
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS * 2)
	_touch(viewport, board_origin - Vector2(0, 100), false)
	await _layout(tree)
	check.call(scene.page_scroll.scroll_vertical > page_before and _state(scene) == board_before and not scene.inspector.visible, "A real small-screen board drag scrolls the page while cancelling selected-tool placement and inspection.")
	scene.page_scroll.scroll_vertical = page_before
	await _capture(viewport, tree, directory, "small-portrait-board.png", check)
	var before := _state(scene)
	scene._inspect_hand(int(scene.game.hand[0].uid))
	await _layout(tree)
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport.size))
	check.call(bounds.encloses(scene.inspector_panel.get_global_rect()) and bounds.encloses(scene.inspector_close.get_global_rect()), "Inspector panel and its Close touch target stay inside a 360×640 portrait viewport.")
	var background_scroll: int = scene.page_scroll.scroll_vertical
	var origin: Vector2 = scene.inspector_scroll.get_global_rect().get_center()
	_touch(viewport, origin, true)
	_drag(viewport, origin - Vector2(0, 150), Vector2(0, -150))
	_touch(viewport, origin - Vector2(0, 150), false)
	await _layout(tree)
	check.call(scene.inspector_scroll.scroll_vertical > 0 and scene.page_scroll.scroll_vertical == background_scroll and _state(scene) == before, "Small-screen inspection content scrolls through real touch routing without moving or activating background controls.")
	await _capture(viewport, tree, directory, "small-portrait-inspector.png", check)
	await _close(scene, viewport, tree)
	check.call(not scene.inspector.visible and _state(scene) == before, "Small-screen touch dismissal leaves combat and RNG unchanged.")
	scene._show_guide()
	await _layout(tree)
	var guide_scroll: ScrollContainer = scene.guide_text.get_parent()
	var guide_origin: Vector2 = guide_scroll.get_global_rect().get_center()
	_touch(scene.dialog, guide_origin, true)
	_drag(scene.dialog, guide_origin - Vector2(0, 120), Vector2(0, -120))
	_touch(scene.dialog, guide_origin - Vector2(0, 120), false)
	check.call(scene.dialog.size.x <= viewport.size.x and scene.dialog.size.y <= viewport.size.y and guide_scroll.scroll_vertical > 0 and _state(scene) == before, "The bounded native Guide scrolls through its own Window touch router without activating the background scene.")
	scene.dialog.hide()
	viewport.size = Vector2i(720, 1600)
	await _layout(tree)

func _encounter_transition(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable) -> void:
	var loaded := Loader.load_setup("res://data/production_transition_encounter.json")
	var helper := ProductionUI.new()
	var model: Combat = helper._inject(scene, loaded.setup)
	model.enemy_hp = 1
	scene._refresh()
	var built: bool = helper._build(scene, true)
	check.call(built, "Touch lifecycle transition fixture builds a real lethal production circuit.")
	if not built: return
	scene._inspect_cell(_endpoints(scene.game.board).begin)
	scene.controller.command("cast")
	check.call(scene.game.state == "victory" and not scene.inspector.visible and scene.selected_cell == -1, "Cast/terminal cleanup dismisses stale board inspection and selection.")
	scene._inspect_cell(_endpoints(scene.game.board).end)
	scene._next_production_encounter()
	check.call(scene.game.encounter_number == 2 and scene.selected_cell == -1 and not scene.inspector.visible, "Encounter transition invalidates old endpoint inspection before the next board.")
	await _layout(tree)
	var index: int = _empty_cells(scene.game.board)[0]
	await _reveal(scene, scene.cells[index], tree)
	var point: Vector2 = scene.cells[index].get_global_rect().get_center()
	_touch(viewport, point, true)
	scene._restart()
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS)
	_touch(viewport, point, false)
	check.call(not scene.inspector.visible and scene.selected_cell == -1, "A pending board hold cannot survive a scene-level encounter reset.")

func _teardown(scene: Control, viewport: SubViewport, tree: SceneTree, check: Callable) -> void:
	await _layout(tree)
	var uid: int = scene.game.hand[0].uid
	await _reveal(scene, _card(scene, uid), tree)
	var point: Vector2 = _card(scene, uid).get_global_rect().get_center()
	_touch(viewport, point, true)
	var controller = scene.controller
	var before: Dictionary = controller.snapshot()
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await _layout(tree)
	_touch(viewport, point, false)
	check.call(not controller.can_edit() and controller.snapshot() == before, "Actual scene teardown closes the controller; a retained physical release cannot mutate it.")
	viewport.queue_free()
	await tree.process_frame

func _invalid_startup(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(360, 640)
	tree.root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://tests/fixtures/rc008-deliberately-missing.json"
	viewport.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	await _layout(tree)
	_tap(viewport, scene.inspect_button)
	_hold(viewport, scene, scene.cells[0])
	scene._inspect_hand(123)
	scene._inspect_cell(0)
	scene._inspect_tool("straight")
	check.call(scene.controller == null and scene.game.is_empty() and scene.inspect_button.disabled and not scene.inspector.visible and scene.selected_cell == -1, "Invalid-content startup safely rejects routed and direct inspection without a fallback battle.")
	scene.player.stop()
	scene.player.stream = null
	viewport.queue_free()
	await tree.process_frame

func _experiment_relaunch(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1600)
	tree.root.add_child(viewport)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.setup_path = "res://data/encounter.json"
	scene.experiment_mode = true
	scene.experiment_scenario = "effects"
	scene.experiment_variant = "control"
	scene.experiment_record_path = "res://output/qa/rc-008/touch-records/relaunch-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	viewport.add_child(scene)
	scene.sound_enabled = false
	scene.gestures.automatic_timing = false
	await _layout(tree)
	scene._inspect_hand(int(scene.game.hand[0].uid))
	var relaunched: bool = scene._launch_experiment("effects", "control", 43)
	check.call(relaunched and scene.experiment_seed == 43 and not scene.inspector.visible and scene.selected_uid == -1 and scene.selected_cell == -1, "A historical experiment relaunch dismisses old inspection and selection using a separate automated record.")
	var begin: int = _endpoints(scene.game.board).begin
	scene._cell_pressed(begin)
	check.call(scene.action_buttons.rotate.disabled, "Touch editing respects the historical profile's locked endpoint permission.")
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	scene._pass()
	var reentrant_results: Array = []
	delayed.on_cancel = func(): reentrant_results.append(scene._launch_experiment("effects", "control", 99))
	relaunched = scene._launch_experiment("effects", "control", 44)
	var state_after: Dictionary = scene.controller.snapshot()
	delayed.complete()
	check.call(relaunched and reentrant_results == [false] and delayed.cancellations == 1 and scene.experiment_seed == 44 and scene.controller.snapshot() == state_after and not scene.inspector.visible, "Experiment relaunch cancels presentation once, rejects synchronous cancellation reentry and ignores its retained completion.")
	delayed.on_cancel = Callable()
	scene.player.stop()
	scene.player.stream = null
	viewport.queue_free()
	await tree.process_frame

func _state(scene: Control) -> Dictionary:
	var model = scene.controller._combat
	return {"snapshot": scene.controller.snapshot(), "rng": model.rng.state, "endpoint_rng": model.endpoint_rng.state, "kit_rng": model.kit_rng.state, "next_uid": model.next_uid, "history": model.history.duplicate(true), "action_id": model._action_id}

func _seed_with_both_card_types(scene: Control, setup: Dictionary) -> void:
	for seed_value in range(128):
		var probe := Combat.new(setup, seed_value)
		var snapshot := probe.snapshot()
		if _uid(snapshot, "rune") >= 0 and _uid(snapshot, "technique") >= 0 and not snapshot.forecast.valid:
			ProductionUI.new()._inject(scene, setup, seed_value)
			return

func _uid(snapshot: Dictionary, type: String) -> int:
	for card in snapshot.hand:
		if snapshot.catalog[card.id].type == type: return card.uid
	return -1

func _card_id(snapshot: Dictionary, uid: int) -> String:
	for card in snapshot.hand:
		if card.uid == uid: return card.id
	return ""

func _card(scene: Control, uid: int) -> Button:
	for button in scene.hand_box.get_children():
		if int(button.get_meta("uid", -1)) == uid: return button
	return null

func _endpoints(board: Array) -> Dictionary:
	var result := {}
	for index in range(board.size()):
		if board[index].get("kind") in ["begin", "end"]: result[board[index].kind] = index
	return result

func _empty_cells(board: Array) -> Array:
	var result := []
	for index in range(board.size()):
		if board[index].is_empty(): result.append(index)
	return result

func _layout(tree: SceneTree) -> void:
	await tree.process_frame
	await tree.process_frame

func _reveal(scene: Control, control: Control, tree: SceneTree) -> void:
	scene.page_scroll.ensure_control_visible(control)
	await _layout(tree)

func _close(scene: Control, viewport: SubViewport, tree: SceneTree) -> void:
	await _layout(tree)
	_tap(viewport, scene.inspector_close)
	await _layout(tree)

func _tap(viewport: SubViewport, control: Control) -> void:
	var point := control.get_global_rect().get_center()
	_touch(viewport, point, true)
	_touch(viewport, point, false)

func _hold(viewport: SubViewport, scene: Control, control: Control) -> void:
	var point := control.get_global_rect().get_center()
	_touch(viewport, point, true)
	scene.gestures.advance_time(Router.LONG_PRESS_SECONDS + 0.01)
	_touch(viewport, point, false)

func _touch(viewport: Viewport, point: Vector2, down: bool, index: int = 0, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = down
	event.canceled = cancelled
	viewport.push_input(event, true)

func _drag(viewport: Viewport, point: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = point
	event.relative = relative
	viewport.push_input(event, true)

func _mouse(viewport: SubViewport, point: Vector2, down: bool, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.device = device
	viewport.push_input(event, true)

func _escape(viewport: SubViewport) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	viewport.push_input(event, true)
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = false
	viewport.push_input(event, true)

func _capture(viewport: SubViewport, tree: SceneTree, directory: String, filename: String, check: Callable) -> void:
	if directory.is_empty(): return
	await _layout(tree)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	check.call(viewport.get_texture().get_image().save_png(directory.path_join(filename)) == OK, "Synthetic touch representative capture saved: " + filename)
