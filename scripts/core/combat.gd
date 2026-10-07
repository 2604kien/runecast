class_name RuneCombat
extends RefCounted

const Circuit = preload("res://scripts/core/circuit.gd")
var catalog: Dictionary
var encounter: Dictionary
var board: Array
var hand: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var history: Array = []
var player_hp := 30
var enemy_hp := 32
var energy := 3
var turn := 1
var state := "playing"
var log_text := "A free Spark is loaded. Cast it or edit the circuit."
var next_uid := 1
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 42) -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/runes.json"))
	encounter = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounter.json"))
	rng.seed = seed_value
	reset()

func reset() -> void:
	board = Circuit.demo_board()
	hand.clear()
	draw_pile.clear()
	discard_pile.clear()
	history.clear()
	next_uid = 1
	player_hp = int(encounter.player_health)
	enemy_hp = int(encounter.max_health)
	energy = int(encounter.energy_per_turn)
	turn = 1
	state = "playing"
	log_text = "A free Spark is loaded. Cast it or edit the circuit."
	for id in ["spark", "shield", "conjure"]:
		hand.append(_card(id))
	for id in ["spark", "shield", "focus", "focus", "conjure"]:
		draw_pile.append(_card(id))
	_shuffle(draw_pile)

func _card(id: String) -> Dictionary:
	var card := {"id": id, "uid": next_uid}
	next_uid += 1
	return card

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var previous: Dictionary = cards[i]
		cards[i] = cards[j]
		cards[j] = previous

func intent() -> int:
	return int(encounter.intents[(turn - 1) % encounter.intents.size()])

func forecast() -> Dictionary:
	return Circuit.evaluate(board, catalog)

func stock(kind: String) -> int:
	var count := 0
	for piece in board:
		if piece.get("kind") == kind:
			count += 1
	return maxi(0, 1 - count)

func _remember() -> void:
	history.append({"board": board.duplicate(true), "hand": hand.duplicate(true)})
	if history.size() > 32:
		history.pop_front()

func _editable(index: int) -> bool:
	return state == "playing" and index >= 0 and index < 16 and index != Circuit.BEGIN and index != Circuit.END

func _return_rune(index: int) -> void:
	var piece: Dictionary = board[index]
	if piece.get("kind") == "rune":
		hand.append({"id": piece.rune_id, "uid": piece.uid})

func place_wire(index: int, kind: String) -> bool:
	if not _editable(index) or not ["straight", "corner", "split", "join", "erase"].has(kind):
		return false
	if kind in ["split", "join"] and stock(kind) == 0 and board[index].get("kind") != kind:
		log_text = "You own one %s. Move the installed piece first." % kind
		return false
	_remember()
	_return_rune(index)
	board[index] = {} if kind == "erase" else {"kind": kind, "rotation": 0}
	return true

func place_rune(index: int, uid: int) -> bool:
	if not _editable(index):
		return false
	var hand_index := -1
	for i in range(hand.size()):
		if hand[i].uid == uid:
			hand_index = i
			break
	if hand_index == -1:
		return false
	var card: Dictionary = hand[hand_index]
	if catalog[card.id].type != "rune":
		return false
	_remember()
	hand.remove_at(hand_index)
	_return_rune(index)
	var rotation: int = board[index].get("rotation", 0)
	board[index] = {"kind": "rune", "rotation": rotation, "rune_id": card.id, "uid": card.uid}
	return true

func rotate(index: int) -> bool:
	if not _editable(index) or board[index].is_empty():
		return false
	_remember()
	board[index].rotation = (int(board[index].rotation) + 1) % 4
	return true

func undo() -> void:
	if history.is_empty() or state != "playing":
		return
	var previous: Dictionary = history.pop_back()
	board = previous.board
	hand = previous.hand

func flip(index: int) -> void:
	if not _editable(index) or not board[index].get("kind") in ["straight", "corner"]:
		return
	_remember()
	board[index].reversed = not board[index].get("reversed", false)

func play_technique(uid: int) -> bool:
	if state != "playing":
		return false
	for i in range(hand.size()):
		var card: Dictionary = hand[i]
		var rune: Dictionary = catalog[card.id]
		if card.uid != uid or rune.type != "technique":
			continue
		if energy < int(rune.cost):
			log_text = "Not enough energy for %s." % rune.name
			return false
		energy -= int(rune.cost)
		hand.remove_at(i)
		discard_pile.append(card)
		# Drawing reveals information, so utility actions commit earlier edits.
		history.clear()
		if rune.effect == "draw":
			_draw(int(rune.value))
			log_text = "Focus drew up to two cards."
		else:
			hand.append(_card("free_spark"))
			log_text = "Conjure Spark created a temporary free Spark."
		return true
	return false

func _draw(amount: int) -> void:
	for count in range(amount):
		if draw_pile.is_empty() and not discard_pile.is_empty():
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(draw_pile)
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())

func cast() -> bool:
	if state != "playing":
		return false
	var spell := forecast()
	if not spell.valid:
		log_text = spell.message
		return false
	if spell.cost > energy:
		log_text = "Need %d energy; you have %d." % [spell.cost, energy]
		return false
	energy -= spell.cost
	enemy_hp = maxi(0, enemy_hp - int(spell.damage))
	var damage_taken := 0
	if enemy_hp > 0:
		damage_taken = maxi(0, intent() - int(spell.shield))
		player_hp = maxi(0, player_hp - damage_taken)
	log_text = "Cast %d damage, %d shield. Received %d damage." % [spell.damage, spell.shield, damage_taken]
	_end_turn()
	return true

func pass_turn() -> void:
	if state != "playing":
		return
	player_hp = maxi(0, player_hp - intent())
	log_text = "Passed. Received %d damage." % intent()
	_end_turn()

func _end_turn() -> void:
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if piece.get("kind") == "rune" and catalog[piece.rune_id].get("temporary", false):
			board[index] = {"kind": "straight", "rotation": piece.rotation}
	for card in hand:
		if not catalog[card.id].get("temporary", false):
			discard_pile.append(card)
	hand.clear()
	history.clear()
	if enemy_hp <= 0:
		state = "victory"
		log_text += " Victory! Use Menu to restart."
	elif player_hp <= 0:
		state = "defeat"
		log_text += " Defeat. Use Menu to restart."
	else:
		turn += 1
		energy = int(encounter.energy_per_turn)
		_draw(int(encounter.draw_per_turn))

