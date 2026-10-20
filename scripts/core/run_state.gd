class_name RuneRunState
extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")

# Session-only run ownership. This is intentionally neither a profile nor a save
# system. Card identity is the pair (run_id, uid); temporary UIDs stay in Combat.
static var _identity_sequence := 0
var _run_id := ""
var _status := "ready"
var _seed := 42
var _setup: Dictionary = {}
var _owned_cards: Array = []
var _player_hp := 30
var _player_max_hp := 30
var _gold := 0
var _relics: Array = []
var _next_uid := 0
var _rng_states: Dictionary = {}
var _entry_checkpoint: Dictionary = {}
var _combat: Combat
var _completed_encounters: Array = []
var _error := ""

func _init(validated_setup: Dictionary, seed: int = 42) -> void:
	_identity_sequence += 1
	_run_id = "run-%d-%d" % [Time.get_ticks_usec(), _identity_sequence]
	_seed = seed
	_setup = validated_setup.duplicate(true)
	# The controlled production fixture uses the accepted scoped starter. Later
	# permanent acquisition, eligibility, rewards and route policies remain open.
	var baseline: Array = ["spark", "spark", "shield", "shield", "focus", "focus", "conjure", "conjure"]
	var supplied: Array = _setup.get("owned_cards", []).duplicate()
	baseline.sort()
	supplied.sort()
	if supplied != baseline or _setup.get("encounter", {}).get("player_health") != 30 or _setup.get("encounter", {}).get("player_max_health") != 30:
		_status = "invalid"
		_error = "A new run requires the accepted eight-card, 30/30 starter."
		return
	for id in _setup.owned_cards:
		_owned_cards.append({"id": id, "uid": _next_uid})
		_next_uid += 1
	for stream in ["cards", "endpoints", "kits"]:
		var generator := RandomNumberGenerator.new()
		generator.seed = seed ^ (0x52434D45 if stream == "endpoints" else 0x52434B49 if stream == "kits" else 0)
		_rng_states[stream] = generator.state
	_error = Combat.validate_run_entry(_setup, _entry_data())
	if not _error.is_empty(): _status = "invalid"

# Live HP and RNG are read through the model's verified handoff while a battle
# owns transient play. The private committed values remain the entry boundary
# until an outcome commits, allowing Quit to replay without healing the checkpoint.
func snapshot() -> Dictionary:
	var live := _combat.run_handoff() if _status == "battle" and _combat != null else {}
	var use_live: bool = live.get("ok", false)
	return {"run_id": _run_id, "status": _status, "seed": _seed,
		"owned_cards": _owned_cards, "player_hp": live.player_hp if use_live else _player_hp,
		"player_max_hp": _player_max_hp, "gold": _gold, "relics": _relics,
		"rng_states": live.rng_states if use_live else _rng_states,
		"current_node_id": "fixture_shadeling", "current_encounter_id": _setup.get("encounter", {}).get("id", ""),
		"completed_encounters": _completed_encounters,
		"can_continue": _status in ["ready", "battle", "replay_pending"],
		"session_only": true, "tower_completed": false,
		"error": _error if live.is_empty() or use_live else live.error}.duplicate(true)

func current_battle() -> Combat:
	return _combat

func enter_battle() -> Dictionary:
	if _status != "ready" or _combat != null:
		return _rejected("This run cannot enter the fixture again.")
	var checkpoint := _entry_data()
	var entered := Combat.create_for_run(_setup, checkpoint)
	if not entered.ok: return entered
	_entry_checkpoint = checkpoint.duplicate(true)
	_combat = entered.combat
	_status = "battle"
	return entered

func continue_battle() -> Dictionary:
	if _status == "ready": return enter_battle()
	if _status == "battle" and _combat != null:
		return {"ok": true, "error": "", "combat": _combat}
	if _status != "replay_pending" or _combat != null or _entry_checkpoint.is_empty():
		return _rejected("There is no replayable battle in this session.")
	var entered := Combat.create_for_run(_setup, _entry_checkpoint)
	if not entered.ok: return entered
	_combat = entered.combat
	_status = "battle"
	return entered

# Invoke only after the user confirms the explained loss of battle progress.
# No input is sampled and no stream changes until Continue recreates entry.
func quit_to_home(battle: Combat) -> bool:
	if _status != "battle" or battle == null or battle != _combat:
		return false
	var handoff := battle.run_handoff()
	if not handoff.ok or handoff.state != "playing": return false
	_combat = null
	_status = "replay_pending"
	return true

# The shell waits for terminal presentation to settle before calling this.
# Identity, conservation, health and outcome validation all precede commit.
func resolve_battle(battle: Combat) -> bool:
	if _status != "battle" or battle == null or battle != _combat:
		return false
	var handoff := battle.run_handoff()
	if not handoff.ok or handoff.run_id != _run_id or handoff.encounter_id != _setup.encounter.id or not handoff.state in ["victory", "defeat"]:
		return false
	if handoff.owned_cards != _owned_cards or handoff.player_max_hp != _player_max_hp:
		return false
	_player_hp = handoff.player_hp
	_rng_states = handoff.rng_states.duplicate(true)
	_next_uid = handoff.next_uid
	_status = "encounter_won" if handoff.state == "victory" else "defeated"
	if handoff.state == "victory": _completed_encounters.append(handoff.encounter_id)
	_entry_checkpoint.clear()
	_combat = null
	return true

func _entry_data() -> Dictionary:
	return {"version": 1, "run_id": _run_id, "encounter_id": _setup.get("encounter", {}).get("id", ""),
		"seed": _seed, "player_hp": _player_hp, "player_max_hp": _player_max_hp,
		"owned_cards": _owned_cards, "next_uid": _next_uid, "rng_states": _rng_states}.duplicate(true)

func _rejected(message: String) -> Dictionary:
	return {"ok": false, "error": message, "combat": null}
