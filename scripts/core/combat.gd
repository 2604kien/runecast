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
var owned_cards: Array = []
var stock_totals: Dictionary = {}
var player_hp := 0
var enemy_hp := 0
var energy := 0
var turn := 1
var state := "playing"
var log_text := ""
var next_uid := 0
var rng := RandomNumberGenerator.new()
var _setup: Dictionary
var _encounter_id := 0
var _action_id := 0
var _events: Array = []
var _last_result: Dictionary = {}

func _init(validated_setup: Dictionary, seed_override: Variant = null) -> void:
	# Loading/validation belong to the caller. Keep a private restart template and
	# separate active copies, so input edits and gameplay cannot rewrite setup.
	_setup = validated_setup.duplicate(true)
	assert(seed_override == null or (seed_override is int and seed_override >= 0 and seed_override <= 2147483647), "A seed override must be an integer in [0, 2147483647].")
	if seed_override != null:
		_setup.encounter.seed = seed_override
	rng.seed = int(_setup.encounter.seed)
	reset()

func reset() -> void:
	_encounter_id += 1
	_events = []
	_last_result = {}
	catalog = _setup.catalog.duplicate(true)
	encounter = _setup.encounter.duplicate(true)
	board = _setup.board.duplicate(true)
	owned_cards = _setup.owned_cards.duplicate()
	stock_totals = _setup.inventory.duplicate(true)
	hand.clear()
	draw_pile.clear()
	discard_pile.clear()
	history.clear()
	next_uid = 0
	player_hp = int(encounter.player_health)
	enemy_hp = int(encounter.max_health)
	energy = int(encounter.energy_per_turn)
	turn = 1
	state = "playing"
	log_text = encounter.opening_log
	var remaining := owned_cards.duplicate()
	# Tutorial/generated setup runes are outside permanent ownership. Allocate
	# these first to retain training's Free Spark UID 0 and hand UIDs 1, 2, 3.
	for piece in board:
		if piece.get("kind") == "rune" and catalog[piece.rune_id].get("temporary", false):
			piece.uid = _card(piece.rune_id).uid
	for id in _setup.opening_hand:
		remaining.erase(id)
		hand.append(_card(id))
	for piece in board:
		if piece.get("kind") == "rune" and not catalog[piece.rune_id].get("temporary", false):
			remaining.erase(piece.rune_id)
			piece.uid = _card(piece.rune_id).uid
	for id in remaining:
		draw_pile.append(_card(id))
	_shuffle(draw_pile)
	_draw(int(_setup.opening_draw))
	# Initial dealing is setup, not an action or a presentation batch.
	_events.clear()

# The UI receives values, never references to authoritative collections.
func snapshot() -> Dictionary:
	return {
		"encounter_id": _encounter_id, "board": board, "hand": hand,
		"draw_pile": draw_pile, "discard_pile": discard_pile,
		"catalog": catalog, "encounter": encounter, "player_hp": player_hp,
		"enemy_hp": enemy_hp, "energy": energy, "turn": turn, "state": state,
		"player_max_hp": encounter.player_max_health, "enemy_max_hp": encounter.max_health,
		"enemy_name": encounter.name, "energy_per_turn": encounter.energy_per_turn,
		"draw_per_turn": encounter.draw_per_turn, "stock_totals": stock_totals,
		"owned_cards": owned_cards, "encounter_content_id": encounter.id,
		"encounter_title": encounter.title, "encounter_help_text": encounter.help_text,
		"log_text": log_text, "intent": intent(), "forecast": forecast(),
		"stock": {"split": stock("split"), "join": stock("join")},
		"undo_count": history.size()
	}.duplicate(true)

func last_result() -> Dictionary:
	return _last_result.duplicate(true)

# Commands resolve synchronously exactly once. Events only describe that work.
func execute(command: String, arguments: Dictionary = {}) -> Dictionary:
	var before := snapshot()
	_events = []
	_last_result = {}
	var accepted := false
	match command:
		"cast": accepted = _cast()
		"pass": accepted = _pass_turn()
		"technique": accepted = _play_technique(int(arguments.get("uid", -1)))
		"place_wire": accepted = _place_wire(int(arguments.get("index", -1)), str(arguments.get("kind", "")))
		"place_rune": accepted = _place_rune(int(arguments.get("index", -1)), int(arguments.get("uid", -1)))
		"rotate": accepted = _rotate(int(arguments.get("index", -1)))
		"flip": accepted = _flip(int(arguments.get("index", -1)))
		"undo": accepted = _undo()
	if accepted:
		_action_id += 1
	_last_result = {
		"accepted": accepted, "command": command, "action_id": _action_id if accepted else 0,
		"encounter_id": _encounter_id, "turn": before.turn,
		"before": before, "after": snapshot(), "events": _events if accepted else []
	}.duplicate(true)
	return last_result()

func _record(type: String, values: Dictionary = {}) -> void:
	var event := values.duplicate(true)
	event.type = type
	event.sequence = _events.size()
	event.action_id = _action_id + 1
	event.encounter_id = _encounter_id
	_events.append(event)

# Compatibility entry points preserve the foundation's bool/void returns.
func place_wire(index: int, kind: String) -> bool:
	return execute("place_wire", {"index": index, "kind": kind}).accepted

func place_rune(index: int, uid: int) -> bool:
	return execute("place_rune", {"index": index, "uid": uid}).accepted

func rotate(index: int) -> bool:
	return execute("rotate", {"index": index}).accepted

func flip(index: int) -> void:
	execute("flip", {"index": index})

func undo() -> void:
	execute("undo")

func play_technique(uid: int) -> bool:
	return execute("technique", {"uid": uid}).accepted

func cast() -> bool:
	return execute("cast").accepted

func pass_turn() -> void:
	execute("pass")

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
	return maxi(0, int(stock_totals.get(kind, 0)) - count)

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

func _place_wire(index: int, kind: String) -> bool:
	if not _editable(index) or not ["straight", "corner", "split", "join", "erase"].has(kind):
		return false
	if kind in ["split", "join"] and stock(kind) == 0 and board[index].get("kind") != kind:
		log_text = "You own %d %s." % [stock_totals[kind], kind]
		if stock_totals[kind] > 0:
			log_text += " Move an installed piece first."
		return false
	_remember()
	_return_rune(index)
	board[index] = {} if kind == "erase" else {"kind": kind, "rotation": 0}
	return true

func _place_rune(index: int, uid: int) -> bool:
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

func _rotate(index: int) -> bool:
	if not _editable(index) or board[index].is_empty():
		return false
	_remember()
	board[index].rotation = (int(board[index].rotation) + 1) % 4
	return true

func _undo() -> bool:
	if history.is_empty() or state != "playing":
		return false
	var previous: Dictionary = history.pop_back()
	board = previous.board
	hand = previous.hand
	return true

func _flip(index: int) -> bool:
	if not _editable(index) or not board[index].get("kind") in ["straight", "corner"]:
		return false
	_remember()
	board[index].reversed = not board[index].get("reversed", false)
	return true

func _play_technique(uid: int) -> bool:
	if state != "playing":
		return false
	for i in range(hand.size()):
		var card: Dictionary = hand[i]
		var rune: Dictionary = catalog[card.id]
		if card.uid != uid:
			continue
		if rune.type != "technique" or not rune.effect in ["draw", "conjure"]:
			log_text = "Unsupported technique type/effect for %s." % card.id
			return false
		if rune.effect == "conjure":
			var target: Dictionary = catalog.get(rune.get("generated_rune_id", ""), {})
			if target.get("type") != "rune" or not target.get("temporary", false) or target.get("cost") != 0:
				log_text = "Invalid generated rune for %s." % card.id
				return false
		if energy < int(rune.cost):
			log_text = "Not enough energy for %s." % rune.name
			return false
		var energy_before := energy
		var undo_before := history.size()
		energy -= int(rune.cost)
		hand.remove_at(i)
		discard_pile.append(card)
		# Drawing reveals information, so utility actions commit earlier edits.
		history.clear()
		_record("technique", {"card": card, "cost": int(rune.cost),
			"energy_before": energy_before, "energy_after": energy,
			"from": "hand", "to": "discard", "undo_cleared": undo_before})
		match rune.effect:
			"draw":
				_draw(int(rune.value))
				log_text = "%s drew up to %d cards." % [rune.name, rune.value]
			"conjure":
				for count in range(int(rune.value)):
					hand.append(_card(rune.generated_rune_id))
					_record("card_created", {"card": hand.back(), "to": "hand"})
				log_text = "%s created %d temporary %s." % [rune.name, rune.value, catalog[rune.generated_rune_id].name]
		return true
	return false

func _draw(amount: int) -> void:
	for count in range(amount):
		if draw_pile.is_empty() and not discard_pile.is_empty():
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(draw_pile)
			_record("reshuffled", {"cards": draw_pile, "from": "discard", "to": "draw"})
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
		_record("card_drawn", {"card": hand.back(), "from": "draw", "to": "hand",
			"draw_remaining": draw_pile.size(), "hand_size": hand.size()})

func _cast() -> bool:
	if state != "playing":
		return false
	var spell := forecast()
	if not spell.valid:
		log_text = spell.message
		return false
	if spell.cost > energy:
		log_text = "Need %d energy; you have %d." % [spell.cost, energy]
		return false
	var energy_before := energy
	energy -= spell.cost
	_record("cast", {"source": "player", "spell": spell,
		"energy_before": energy_before, "energy_after": energy})
	var health_before := enemy_hp
	enemy_hp = maxi(0, enemy_hp - int(spell.damage))
	_record("damage", {"source": "player", "target": "enemy", "amount": int(spell.damage),
		"applied": health_before - enemy_hp, "health_before": health_before, "health_after": enemy_hp})
	var damage_taken := 0
	if enemy_hp > 0:
		_record("shield", {"target": "player", "amount": int(spell.shield)})
		damage_taken = _retaliate(int(spell.shield))
	log_text = "Cast %d damage, %d shield. Received %d damage." % [spell.damage, spell.shield, damage_taken]
	_end_turn()
	return true

func _pass_turn() -> bool:
	if state != "playing":
		return false
	_record("passed", {"source": "player"})
	_retaliate(0)
	log_text = "Passed. Received %d damage." % intent()
	_end_turn()
	return true

func _retaliate(shield: int) -> int:
	var incoming := intent()
	var damage_taken := maxi(0, incoming - shield)
	var health_before := player_hp
	player_hp = maxi(0, player_hp - damage_taken)
	_record("retaliation", {"source": "enemy", "target": "player", "incoming": incoming,
		"blocked": mini(incoming, shield), "amount": damage_taken, "applied": health_before - player_hp,
		"health_before": health_before, "health_after": player_hp})
	return damage_taken

func _end_turn() -> void:
	for index in range(board.size()):
		var piece: Dictionary = board[index]
		if piece.get("kind") == "rune" and catalog[piece.rune_id].get("temporary", false):
			board[index] = {"kind": "straight", "rotation": piece.rotation}
			_record("temporary_expired", {"cell": index, "before": piece, "after": board[index]})
	var discarded: Array = []
	var expired: Array = []
	var undo_before := history.size()
	for card in hand:
		if not catalog[card.id].get("temporary", false):
			discard_pile.append(card)
			discarded.append(card)
		else:
			expired.append(card)
	hand.clear()
	history.clear()
	_record("turn_cleanup", {"discarded": discarded, "expired": expired,
		"hand_after": [], "undo_cleared": undo_before})
	if enemy_hp <= 0:
		state = "victory"
		log_text += " Victory! Use Menu to restart."
		_record("battle_ended", {"state": state, "player_hp": player_hp, "enemy_hp": enemy_hp})
	elif player_hp <= 0:
		state = "defeat"
		log_text += " Defeat. Use Menu to restart."
		_record("battle_ended", {"state": state, "player_hp": player_hp, "enemy_hp": enemy_hp})
	else:
		var energy_before := energy
		turn += 1
		energy = int(encounter.energy_per_turn)
		_record("turn_started", {"turn_before": turn - 1, "turn_after": turn,
			"energy_before": energy_before, "energy_after": energy, "intent": intent()})
		_draw(int(encounter.draw_per_turn))

