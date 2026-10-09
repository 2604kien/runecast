extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const Controller = preload("res://scripts/ui/combat_controller.gd")
const Circuit = preload("res://scripts/core/circuit.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Delayed = preload("res://tests/delayed_presentation.gd")

func run_followup(check: Callable, tree: SceneTree, capture_directory: String = "") -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(scene)
	scene.sound_enabled = false
	await tree.process_frame
	check.call(scene.controller != null and scene.game.has("production") and scene.setup_path == Loader.DEFAULT_ENCOUNTER, "Ordinary scene launch uses the validated production setup.")
	if scene.controller == null or not scene.game.has("production"):
		scene.queue_free()
		await tree.process_frame
		return
	var setup: Dictionary = scene.initial_setup.duplicate(true)
	var initial: Dictionary = scene.controller.snapshot()
	check.call(_only_endpoints(initial.board) and initial.hand.size() == 3 and initial.energy == 3 and _stock_labels(scene), "Production opens with only two endpoints, three normally drawn cards, three energy and four finite stock labels.")
	check.call(scene.status.text.contains("Kit:") and scene.status.text.contains("Hand 3") and scene.stats.tooltip_text.contains("draw pile"), "Opening feedback shows the selected kit and actual card pile quantities.")
	scene._show_guide()
	check.call(scene.dialog.dialog_text.contains("Every playable turn starts with only Begin and End") and scene.dialog.dialog_text.contains("Click Begin or End, then Rotate") and scene.dialog.dialog_text.contains("Join costs 0") and scene.dialog.dialog_text.contains("one total damage hit") and not scene.dialog.dialog_text.contains("remain installed"), "Actual production Guide explains reset, endpoint rotation, selected costs and aggregate damage.")
	await _capture(scene, tree, capture_directory, "production-guide.png", check, false)
	scene.dialog.hide()
	scene._open_menu()
	check.call(scene.production_replay_button.visible and not scene.production_next_button.visible and scene.menu.dialog_text.contains("continuing randomness") and scene.menu.dialog_text.contains("original seed"), "Normal production menu distinguishes Restart and Exact replay without exposing an unconfigured transition.")
	scene.menu.hide()
	await _capture(scene, tree, capture_directory, "production-opening.png", check)
	await _endpoint_controls(scene, check)
	scene._exact_replay()
	_stock_exhaustion(scene, check)
	scene._exact_replay()
	check.call(scene.controller.snapshot() == initial, "Exact replay restores the same opening geometry, kit, cards and identities after edits.")
	var built := _build(scene)
	check.call(built and not scene.cast_button.disabled and scene.cast_button.text.contains("energy"), "Actual production tool, card and Rotate controls construct an affordable rune-bearing circuit.")
	if built:
		await _capture(scene, tree, capture_directory, "production-built.png", check)
		var spell: Dictionary = scene.game.forecast.duplicate(true)
		var prior: Dictionary = scene.controller.snapshot()
		scene.cast_button.pressed.emit()
		check.call(scene.game.enemy_hp == maxi(0, int(prior.enemy_hp) - int(spell.damage)) and scene.game.turn == 2 and _only_endpoints(scene.game.board) and scene.game.undo_count == 0 and _stock_labels(scene), "Cast applies its displayed spell once, then resets board/history and shows the new full kit.")
		check.call(_moved(prior.board, scene.game.board) and scene.game.hand.size() == 3 and scene.status.text.contains("Kit:") and scene.status.text.contains("Hand 3"), "Next-turn endpoint movement, normal draw and kit refresh reach the real UI.")
		await _capture(scene, tree, capture_directory, "production-turn2.png", check)
		prior = scene.controller.snapshot()
		scene.menu.custom_action.emit("pass")
		check.call(scene.game.turn == 3 and scene.game.enemy_hp == prior.enemy_hp and _only_endpoints(scene.game.board) and _moved(prior.board, scene.game.board) and _stock_labels(scene), "Menu Pass accepts an unfinished production board and enters another clean turn with moved endpoints.")
	scene.menu.confirmed.emit()
	check.call(scene.game.turn == 1 and scene.game.player_hp == initial.player_hp and scene.game.enemy_hp == initial.enemy_hp and _only_endpoints(scene.game.board) and _stock_labels(scene), "Menu Restart restores encounter health and a new endpoints-only playable opening.")
	await _busy_and_replay(scene, initial, check)
	await _adjacent(scene, setup, check, tree, capture_directory)
	await _terminal(scene, setup, check, tree, capture_directory)
	await _transition(scene, check, tree, capture_directory)
	var removed_controller: Controller = scene.controller
	var teardown := Delayed.new()
	scene.controller.set_presenter(teardown)
	scene._pass()
	var reentrant_controllers: Array = []
	teardown.on_cancel = func():
		scene._exact_replay()
		scene._restart()
		reentrant_controllers.append(scene.controller)
	scene.player.stop()
	scene.player.stream = null
	scene.queue_free()
	await tree.process_frame
	teardown.complete()
	check.call(teardown.cancellations == 1 and reentrant_controllers == [removed_controller] and not removed_controller.is_busy() and not removed_controller.command("pass"), "Production scene teardown blocks replay/restart reentry and leaves retained callbacks closed.")
	teardown.on_cancel = Callable()
	reentrant_controllers.clear()

func _endpoint_controls(scene: Control, check: Callable) -> void:
	var endpoints := _endpoints(scene.game.board)
	for kind in ["begin", "end"]:
		var cell: int = endpoints[kind]
		var before: Dictionary = scene.controller.snapshot()
		scene.stock_buttons.straight.pressed.emit()
		scene.cells[cell].pressed.emit()
		check.call(scene.selected_cell == cell and scene.selected_tool == "" and scene.selected_uid == -1 and scene.game.board == before.board and scene.cells[cell].chosen and scene.cells[cell].tooltip_text.contains("Rotate"), "Holding a connector safely selects %s with visible rotation feedback." % kind)
		_press_edit(scene, "Rotate")
		check.call(scene.game.board[cell].rotation == (int(before.board[cell].rotation) + 1) % 4 and scene.game.stock == before.stock and scene.status.text.contains("Undo restores the previous direction"), "Normal Rotate changes %s connectivity and direction feedback without spending stock." % kind)
		_press_edit(scene, "Undo")
		check.call(scene.game.board == before.board and scene.game.hand == before.hand and scene.game.stock == before.stock, "Endpoint Undo restores %s orientation together with unchanged hand and kit." % kind)
		var uid := _effect_uid(scene.game, false)
		if uid >= 0:
			scene._select_card(uid)
			scene.cells[cell].pressed.emit()
			check.call(scene.selected_uid == -1 and scene.selected_cell == cell and scene.game.board == before.board and scene.game.hand == before.hand, "Holding a rune safely selects %s without replacing it or moving the card." % kind)
		scene._select_tool("erase")
		scene.cells[cell].pressed.emit()
		_press_edit(scene, "Flip")
		check.call(scene.game.board == before.board, "%s remains protected from Erase and Flip through actual UI controls." % kind)

func _stock_exhaustion(scene: Control, check: Callable) -> void:
	var empty_cells := _empty_cells(scene.game.board)
	var total: int = scene.game.stock_totals.straight
	scene.stock_buttons.straight.pressed.emit()
	for index in range(total):
		scene.cells[empty_cells[index]].pressed.emit()
	var before: Dictionary = scene.controller.snapshot()
	scene.cells[empty_cells[total]].pressed.emit()
	check.call(scene.game.board == before.board and scene.game.stock.straight == 0 and scene.game.undo_count == before.undo_count and scene.status.text.contains("You own") and _stock_labels(scene), "Production rejects exhausted Straight stock with visible feedback and no new Undo step.")
	_press_edit(scene, "Undo")
	check.call(scene.game.stock.straight == 1 and scene.game.board[empty_cells[total - 1]].is_empty() and _stock_labels(scene), "Production Undo returns exactly one reserved Straight and refreshes its label.")

func _busy_and_replay(scene: Control, initial: Dictionary, check: Callable) -> void:
	scene._exact_replay()
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	scene.menu.custom_action.emit("pass")
	var pending: Dictionary = scene.controller.snapshot()
	scene._pass()
	scene._cast()
	scene.stock_buttons.straight.pressed.emit()
	scene.cells[_empty_cells(scene.game.board)[0]].pressed.emit()
	_press_edit(scene, "Undo")
	check.call(scene.controller.is_busy() and scene.cast_button.disabled and scene.pass_button.disabled and scene.controller.snapshot() == pending and delayed.batches.size() == 1, "Busy production UI blocks duplicate Cast/Pass, stock edits and Undo while presentation is pending.")
	delayed.on_cancel = func():
		scene._pass()
		scene._restart()
		scene._exact_replay()
	scene.menu.custom_action.emit("exact_replay")
	check.call(delayed.cancellations == 1 and scene.controller.snapshot() == initial and not scene.controller.is_busy(), "Production Exact replay safely cancels pending playback and rejects cancellation reentry.")
	var newer := Delayed.new()
	scene.controller.set_presenter(newer)
	scene._pass()
	var newer_state: Dictionary = scene.controller.snapshot()
	delayed.complete()
	check.call(scene.controller.is_busy() and scene.controller.snapshot() == newer_state and newer.batches.size() == 1, "A stale callback from before Exact replay cannot unlock or mutate a newer production action.")
	newer.complete()
	newer.complete()
	check.call(not scene.controller.is_busy() and scene.controller.snapshot() == newer_state, "Duplicate production presentation completion cannot replay resources or cleanup.")
	scene._pass()
	scene.menu.confirmed.emit()
	var restarted: Dictionary = scene.controller.snapshot()
	newer.complete()
	check.call(not scene.controller.is_busy() and scene.controller.snapshot() == restarted and _only_endpoints(scene.game.board), "Restart cancels pending production playback; its stale callback cannot alter the fresh turn.")

func _adjacent(scene: Control, setup: Dictionary, check: Callable, tree: SceneTree, capture_directory: String) -> void:
	var adjacent_seed := -1
	for seed_value in range(128):
		var probe := Combat.new(setup, seed_value)
		var pair := _endpoints(probe.board)
		if _direction(pair.begin, pair.end) >= 0:
			adjacent_seed = seed_value
			break
	check.call(adjacent_seed >= 0, "Production generation naturally includes adjacent endpoint positions without rerolls in gameplay.")
	if adjacent_seed < 0:
		return
	_inject(scene, setup, adjacent_seed)
	var pair := _endpoints(scene.game.board)
	_rotate_to(scene, pair.begin, (_direction(pair.begin, pair.end) + 3) % 4)
	_rotate_to(scene, pair.end, _direction(pair.end, pair.begin))
	check.call(_only_endpoints(scene.game.board) and not scene.cast_button.disabled and scene.game.forecast.damage == 0 and scene.game.forecast.cost == 0, "Normal endpoint controls permit a direct adjacent zero-damage, zero-cost Cast.")
	await _capture(scene, tree, capture_directory, "production-adjacent.png", check)
	var before: Dictionary = scene.controller.snapshot()
	scene.cast_button.pressed.emit()
	check.call(scene.game.turn == 2 and scene.game.enemy_hp == before.enemy_hp and scene.game.player_hp < before.player_hp and _only_endpoints(scene.game.board), "A direct adjacent Cast resolves its zero spell, retaliation and ordinary full turn reset.")

func _terminal(scene: Control, setup: Dictionary, check: Callable, tree: SceneTree, capture_directory: String) -> void:
	var model := _inject(scene, setup)
	# Deliberately tiny HP are a terminal QA seam, not shipped encounter tuning.
	model.player_hp = 1
	scene._refresh()
	scene._pass()
	check.call(scene.game.state == "defeat" and scene.game.hand.is_empty() and _only_endpoints(scene.game.board) and scene.cast_button.disabled and scene.pass_button.disabled, "Defeat UI shows terminal cleanup without an unused hand or playable actions.")
	var defeated: Dictionary = scene.controller.snapshot()
	scene._pass()
	scene._cast()
	check.call(scene.controller.snapshot() == defeated, "Terminal UI callbacks cannot spend, redraw or reset a defeated encounter.")
	await _capture(scene, tree, capture_directory, "production-defeat.png", check)
	scene.menu.confirmed.emit()
	check.call(scene.game.state == "playing" and scene.game.player_hp == setup.encounter.player_health and scene.game.hand.size() == 3 and _only_endpoints(scene.game.board), "Restart from defeat creates a fully playable clean production turn.")
	model = _inject(scene, setup)
	model.enemy_hp = 1
	scene._refresh()
	var built := _build(scene, true)
	check.call(built and scene.game.forecast.damage > 0, "Terminal QA builds a real positive-damage production circuit through UI actions.")
	if built:
		check.call(scene.cast_button.tooltip_text.contains("Incoming 0."), "A lethal production forecast visibly suppresses retaliation in the Cast tooltip.")
		var hp_before: int = scene.game.player_hp
		scene.cast_button.pressed.emit()
		check.call(scene.game.state == "victory" and scene.game.player_hp == hp_before and scene.game.hand.is_empty() and _only_endpoints(scene.game.board), "Lethal UI Cast suppresses retaliation and clears board/hand before showing victory.")
		await _capture(scene, tree, capture_directory, "production-victory.png", check)

func _transition(scene: Control, check: Callable, tree: SceneTree, capture_directory: String) -> void:
	var loaded := Loader.load_setup("res://data/production_transition_encounter.json")
	check.call(loaded.ok, "Bounded production encounter-entry fixture validates for actual UI execution.")
	if not loaded.ok:
		return
	var model := _inject(scene, loaded.setup)
	model.enemy_hp = 1
	scene._refresh()
	check.call(scene.production_next_button.visible and scene.production_next_button.disabled, "Configured development fixture shows Next encounter but rejects it before victory.")
	var built := _build(scene, true)
	check.call(built, "Encounter-entry QA builds a real positive-damage circuit before its victory.")
	if not built:
		return
	scene._cast()
	check.call(scene.game.state == "victory" and not scene.production_next_button.disabled, "Only eligible production victory enables Next encounter.")
	var hp: int = scene.game.player_hp
	var delayed := Delayed.new()
	scene.controller.set_presenter(delayed)
	scene.menu.custom_action.emit("next_encounter")
	check.call(scene.controller.is_busy() and scene.game.encounter_number == 2 and scene.game.turn == 1 and scene.game.player_hp == hp and _only_endpoints(scene.game.board) and _stock_labels(scene) and scene.production_next_button.disabled, "Next encounter carries HP into an endpoints-only first turn with a fresh full kit, under the presentation guard.")
	var transitioned: Dictionary = scene.controller.snapshot()
	scene._next_production_encounter()
	delayed.complete()
	scene._next_production_encounter()
	check.call(scene.controller.snapshot() == transitioned and delayed.batches.size() == 1 and scene.production_next_button.disabled, "Busy and repeated production Next encounter callbacks cannot reconcile cards or initialize twice.")
	await _capture(scene, tree, capture_directory, "production-next-encounter.png", check)

func _inject(scene: Control, source: Dictionary, seed_value: int = -1) -> Combat:
	var setup := source.duplicate(true)
	if seed_value >= 0:
		setup.encounter.seed = seed_value
	scene.controller.dispose()
	var model := Combat.new(setup)
	scene.initial_setup = setup.duplicate(true)
	scene.controller = Controller.new(model)
	scene.controller.changed.connect(scene._refresh)
	scene.controller.presentation_started.connect(scene._presentation_started)
	scene._clear_selection()
	scene._refresh()
	return model

func _build(scene: Control, damage_required: bool = false) -> bool:
	var uid := _effect_uid(scene.game, damage_required)
	if uid < 0:
		for card in scene.game.hand.duplicate():
			if scene.game.catalog[card.id].effect == "conjure" and scene.game.catalog[card.id].cost <= scene.game.energy:
				scene._select_card(card.uid)
				uid = _effect_uid(scene.game, damage_required)
				break
	if uid < 0:
		return false
	var pair := _endpoints(scene.game.board)
	var path := _route([pair.begin], pair.end, 0, 0, int(scene.game.stock.straight) + 1, int(scene.game.stock.corner))
	if path.is_empty():
		return false
	_rotate_to(scene, pair.begin, (_direction(path[0], path[1]) + 3) % 4)
	_rotate_to(scene, pair.end, _direction(path[-1], path[-2]))
	var installed_rune := false
	for offset in range(1, path.size() - 1):
		var cell: int = path[offset]
		var input := _direction(cell, path[offset - 1])
		var output := _direction(cell, path[offset + 1])
		if not installed_rune and (input + 2) % 4 == output:
			scene._select_card(uid)
			scene.cells[cell].pressed.emit()
			_rotate_to(scene, cell, (input + 1) % 4)
			installed_rune = true
		else:
			var piece := _piece(input, output)
			if piece.is_empty():
				return false
			scene.stock_buttons[piece.kind].pressed.emit()
			scene.cells[cell].pressed.emit()
			_rotate_to(scene, cell, piece.rotation)
			if piece.reversed:
				scene._clear_selection()
				scene.cells[cell].pressed.emit()
				_press_edit(scene, "Flip")
	return installed_rune and scene.game.forecast.valid and scene.game.forecast.cost <= scene.game.energy and (not damage_required or scene.game.forecast.damage > 0)

func _route(path: Array, end: int, straights: int, corners: int, max_straights: int, max_corners: int) -> Array:
	var current: int = path[-1]
	if current == end:
		return path if straights > 0 else []
	for direction in range(4):
		var next := Circuit.neighbor(current, direction)
		if next < 0 or path.has(next):
			continue
		var straight := path.size() > 1 and _direction(path[-2], current) == direction
		var new_straights := straights + (1 if path.size() > 1 and straight else 0)
		var new_corners := corners + (1 if path.size() > 1 and not straight else 0)
		if new_straights > max_straights or new_corners > max_corners:
			continue
		var extended := path.duplicate()
		extended.append(next)
		var found := _route(extended, end, new_straights, new_corners, max_straights, max_corners)
		if not found.is_empty():
			return found
	return []

func _piece(input: int, output: int) -> Dictionary:
	for kind in ["straight", "corner"]:
		for rotation in range(4):
			for reversed in [false, true]:
				var value := {"kind": kind, "rotation": rotation, "reversed": reversed}
				var ports := Circuit.ports(value)
				if ports.input == [input] and ports.output == [output]:
					return value
	return {}

func _rotate_to(scene: Control, cell: int, rotation: int) -> void:
	scene._clear_selection()
	scene.cells[cell].pressed.emit()
	for _step in range(4):
		if int(scene.game.board[cell].get("rotation", 0)) == rotation:
			return
		_press_edit(scene, "Rotate")

func _effect_uid(snapshot: Dictionary, damage_required: bool) -> int:
	for card in snapshot.hand:
		var rune: Dictionary = snapshot.catalog[card.id]
		if rune.type == "rune" and rune.cost <= snapshot.energy and (not damage_required or rune.effect == "damage"):
			return int(card.uid)
	return -1

func _stock_labels(scene: Control) -> bool:
	for kind in ["straight", "corner", "split", "join"]:
		if not scene.game.stock.has(kind) or scene.stock_buttons[kind].text != "%s\n%d / %d" % [kind.capitalize(), scene.game.stock[kind], scene.game.stock_totals[kind]]:
			return false
	return true

func _endpoints(board: Array) -> Dictionary:
	var found := {}
	for cell in range(board.size()):
		if board[cell].get("kind") in ["begin", "end"]:
			found[board[cell].kind] = cell
	return found

func _only_endpoints(board: Array) -> bool:
	return _endpoints(board).size() == 2 and board.filter(func(piece): return not piece.is_empty()).size() == 2

func _empty_cells(board: Array) -> Array:
	var cells := []
	for cell in range(board.size()):
		if board[cell].is_empty():
			cells.append(cell)
	return cells

func _moved(before: Array, after: Array) -> bool:
	var first := _endpoints(before)
	var second := _endpoints(after)
	return first.begin != second.begin and first.end != second.end

func _direction(from_cell: int, to_cell: int) -> int:
	for direction in range(4):
		if Circuit.neighbor(from_cell, direction) == to_cell:
			return direction
	return -1

func _press_edit(scene: Control, caption: String) -> void:
	for button in scene.edit_buttons:
		if button.text == caption:
			button.pressed.emit()
			return

func _capture(scene: Control, tree: SceneTree, directory: String, name: String, check: Callable, hide_popups: bool = true) -> void:
	if directory.is_empty():
		return
	if hide_popups:
		scene.dialog.hide()
		scene.menu.hide()
	await tree.process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	check.call(scene.get_viewport().get_texture().get_image().save_png(directory.path_join(name)) == OK, "Fresh rendered production QA screenshot saves: " + name)
