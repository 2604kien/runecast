class_name RuneRunState
extends RefCounted

const Combat = preload("res://scripts/core/combat.gd")
const RouteState = preload("res://scripts/core/route_state.gd")
const EncounterResolver = preload("res://scripts/core/encounter_resolver.gd")
const ProgressionState = preload("res://scripts/core/progression_state.gd")

# Card identity is the pair (run_id, uid); temporary UIDs stay in Combat.
# Native int64 values in this contract must be losslessly encoded by the store.
const SAVE_VERSION := 6
const InstanceEffects = preload("res://scripts/core/instance_effects.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
const ShopPolicy = preload("res://scripts/core/shop_policy.gd")
const ServicePolicy = preload("res://scripts/core/service_policy.gd")
const StorePolicy = preload("res://scripts/core/store_policy.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const TRANSACTION_FIELDS := ["_run_id", "_status", "_seed", "_setup", "_owned_cards", "_player_hp", "_player_max_hp", "_gold", "_relics", "_next_uid", "_rng_states", "_entry_checkpoint", "_completed_encounters", "_error", "_route_mode", "_candidate_sequence", "_battle_generation", "_active_battle", "_pending_result", "_battle_choices", "_reward_policy", "_reward_rules", "_reward_records", "_prepared", "_shop_records", "_service_records", "_health_boundary", "_battle_health_records", "_terminal", "_store"]
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
var _route: RouteState
var _route_mode := false
var _resolver: RefCounted
var _prepared: Dictionary = {}
var _preparing := false
var _candidate_sequence := 0
var _battle_generation := 0
var _active_battle: Dictionary = {}
var _pending_result: Dictionary = {}
var _battle_choices: Array = []
var _reward_policy := ""
var _reward_rules: Dictionary = {}
var _reward_records: Dictionary = {}
var _reward_rng := RandomNumberGenerator.new()
var _reward_transaction := false
var _shop_records: Dictionary = {}
var _shop_rng := RandomNumberGenerator.new()
var _shop_transaction := false
var _service_records: Dictionary = {}
var _health_boundary: Dictionary = {}
var _battle_health_records: Dictionary = {}
var _service_transaction := false
var _profile: ProgressionState
var _terminal: Dictionary = {}
var _store: Dictionary = StorePolicy.empty_state()

func _init(validated_setup: Dictionary = {}, seed: int = 42, route_mode: bool = false, route_factory: Callable = Callable(), resolver: RefCounted = null, reward_rules: Dictionary = {}, profile: ProgressionState = null) -> void:
	# Empty construction is reserved for detached restore/transaction owners.
	if validated_setup.is_empty(): return
	_run_id = "run-" + Crypto.new().generate_random_bytes(16).hex_encode()
	_seed = seed
	_route_mode = route_mode
	_resolver = resolver if resolver != null else EncounterResolver.new()
	_setup = validated_setup.duplicate(true)
	_reward_rules = reward_rules.duplicate(true)
	_profile = profile if profile != null else ProgressionState.new(_setup.get("catalog", {}))
	_reward_rng.seed = seed ^ 0x52435257
	_shop_rng.seed = seed ^ ShopPolicy.RNG_SALT
	_health_boundary = {"source_version": 0, "visit_count": 0, "player_hp": 30, "player_max_hp": 30}
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
		_owned_cards.append({"id": id, "uid": _next_uid, "upgrade_rank": 0})
		_next_uid += 1
	for stream in ["cards", "endpoints", "kits"]:
		var generator := RandomNumberGenerator.new()
		generator.seed = seed ^ (0x52434D45 if stream == "endpoints" else 0x52434B49 if stream == "kits" else 0)
		_rng_states[stream] = generator.state
	_error = Combat.validate_run_entry(_setup, _entry_data())
	if not _error.is_empty(): _status = "invalid"
	elif route_mode:
		_route = route_factory.call(_run_id, seed) if route_factory.is_valid() else RouteState.new(_run_id, seed)
		_sync_route_status()

# Live HP and RNG are read through the model's verified handoff while a battle
# owns transient play. The private committed values remain the entry boundary
# until an outcome commits, allowing Quit to replay without healing the checkpoint.
func snapshot() -> Dictionary:
	var live := _combat.run_handoff() if _status == "battle" and _combat != null else {}
	var use_live: bool = live.get("ok", false)
	var route := route_snapshot()
	var current_node := str(route.get("current_node_id", ""))
	var current_encounter := str(_setup.get("encounter", {}).get("id", ""))
	if _route_mode:
		current_encounter = str(_route.inspect(current_node).get("encounter_id", "")) if _route != null else ""
	return {"run_id": _run_id, "status": _status, "seed": _seed,
		"owned_cards": _owned_cards, "player_hp": live.player_hp if use_live else _player_hp,
		"player_max_hp": _player_max_hp, "gold": _gold, "relics": _relics,
		"rng_states": live.rng_states if use_live else _rng_states, "next_uid": live.next_uid if use_live else _next_uid,
		"current_node_id": current_node if _route_mode else "fixture_shadeling", "current_encounter_id": current_encounter,
		"completed_encounters": _completed_encounters,
		"can_continue": _status in ["ready", "battle", "replay_pending", "result_pending", "route_ready", "room_active", "pending_choices"],
		"session_only": false, "tower_completed": _status == "tower_completed",
		"terminal": _terminal, "is_terminal": not _terminal.is_empty(), "final_results_ready": final_results_ready(),
		"can_abandon": abandonment_error(false).is_empty(), "abandonment_error": abandonment_error(false), "summary": run_summary(),
		"mode": "route" if _route_mode else "standalone", "route": route,
		"active_battle": _active_battle, "pending_result": _pending_result,
		"reward_records": _reward_records.values(), "reward_rng_state": _reward_rng.state,
		"shop": shop_snapshot(), "shop_rng_state": _shop_rng.state, "service": service_snapshot(),
		"profile": _profile.snapshot() if _profile != null else {},
		"error": _error if live.is_empty() or use_live else live.error}.duplicate(true)

func route_snapshot() -> Dictionary:
	return _route.snapshot() if _route != null else {}

func inspect_node(node_id: String) -> Dictionary:
	var result := _route.inspect(node_id) if _route != null else _rejected("This standalone encounter has no tower route.")
	if not _terminal.is_empty() and result.get("ok", false):
		result.state = "visited" if result.state == "visited" else "locked"
		result.reason = "This run has ended. Open run results to review its history."
	return result

func request_room_entry(node_id: String) -> Dictionary:
	if _preparing or not _prepared.is_empty() or (_route_mode and _status != "route_ready"):
		return _rejected("Resolve or resume the current encounter first.")
	return _route.request_entry(node_id) if _route != null else _rejected("This standalone encounter has no tower route.")

func confirm_room_entry(token: Dictionary, handler: Callable = Callable()) -> Dictionary:
	if _route == null: return _rejected("This standalone encounter has no tower route.")
	if _route.inspect(str(token.get("node_id", ""))).get("room_id") in ["room_shop", "room_event", "room_recovery"]: return _rejected("Prepare the service room before entering.")
	if _preparing or not _prepared.is_empty() or _status != "route_ready": return _rejected("A battle or result already owns this route.")
	var result := _route.confirm_entry(token, handler)
	_sync_route_status()
	return result

func resolve_room(run_id: String, node_id: String, visit_id: String, outcome: String, pending_choices: Array = []) -> bool:
	if _route == null or not _terminal.is_empty(): return false
	if _route.inspect(node_id).get("room_id") in ["room_shop", "room_event", "room_recovery"]: return false
	if _preparing or not _prepared.is_empty() or not _active_battle.is_empty() or not _pending_result.is_empty(): return false
	var resolved := _route.resolve(run_id, node_id, visit_id, outcome, pending_choices)
	_sync_route_status()
	return resolved

func complete_room_choice(run_id: String, node_id: String, visit_id: String, choice_id: String) -> bool:
	if _route == null: return false
	if _route.inspect(node_id).get("room_id") in ["room_shop", "room_event", "room_recovery"]: return false
	# Reward choices may only complete in their authoritative transaction. This
	# also protects an unresolved production policy from a generic skip callback.
	if choice_id == "encounter_rewards": return false
	for record in _reward_records.values():
		if record.identity.visit_id == visit_id and record.identity.choice_id == choice_id: return false
	if _preparing or not _prepared.is_empty() or _status != "pending_choices": return false
	var completed := _route.complete_choice(run_id, node_id, visit_id, choice_id)
	_sync_route_status()
	return completed

func _sync_route_status() -> void:
	if _terminal.get("outcome") == "abandoned": return
	if _route == null: return
	_ensure_terminal()
	# Route status is only one component. Rejected calls must never erase a
	# battle, replay checkpoint or unacknowledged result.
	if not _pending_result.is_empty():
		_status = "result_pending"
		return
	if not _active_battle.is_empty():
		_status = "battle" if _combat != null else "replay_pending"
		return
	var route := _route.snapshot()
	_status = str(route.status)
	_error = str(route.error)

func current_battle() -> Combat:
	return _combat

func prepare_route_battle(token: Dictionary) -> Dictionary:
	if _route == null or _status != "route_ready" or _preparing or not _prepared.is_empty() or _combat != null:
		return _rejected("Another room, battle or entry already owns this run.")
	var preview := _route.preview_entry(token)
	if not preview.ok: return preview
	_preparing = true
	var resolved: Dictionary = _resolver.resolve(preview.node, _entry_data())
	_preparing = false
	if not resolved.get("ok", false): return resolved
	if not _route.preview_entry(token).ok or _status != "route_ready": return _rejected("The route changed during encounter preparation.")
	var candidate_setup: Dictionary = resolved.setup
	if candidate_setup.catalog != _setup.catalog: return _rejected("The encounter rune catalog is incompatible with this run.")
	var choices: Variant = resolved.get("pending_choices", [])
	if not choices is Array: return _rejected("The encounter choice policy is invalid.")
	var unique_choices := {}
	for choice in choices:
		if not choice is String or choice.is_empty() or unique_choices.has(choice): return _rejected("The encounter choice policy is invalid.")
		unique_choices[choice] = true
	_battle_generation += 1
	var identity := _visit_identity(preview.visit, _battle_generation)
	var entry: Dictionary = _entry_data()
	entry.encounter_id = str(candidate_setup.encounter.id)
	entry.battle_identity = identity.duplicate(true)
	var built := Combat.create_for_run(candidate_setup, entry)
	if not built.ok: return built
	return _store_candidate("route", built.combat, candidate_setup, entry, identity,
		{"token": token.duplicate(true), "choices": choices.duplicate(),
		"reward_policy": str(resolved.get("reward_policy", ""))})

func _store_candidate(kind: String, model: Combat, setup: Dictionary, entry: Dictionary, identity: Dictionary, extra: Dictionary = {}) -> Dictionary:
	_candidate_sequence += 1
	_prepared = {"ok": true, "error": "", "candidate_id": _candidate_sequence, "kind": kind,
		"combat": model, "setup": setup.duplicate(true), "entry": entry.duplicate(true),
		"identity": identity.duplicate(true), "opening": model.snapshot(), "handoff": model.run_handoff()}
	_prepared.merge(extra.duplicate(true))
	return _public_candidate()

func _public_candidate() -> Dictionary:
	return {"ok": true, "error": "", "candidate_id": _prepared.candidate_id,
		"combat": _prepared.combat, "setup": _prepared.setup.duplicate(true), "identity": _prepared.identity.duplicate(true)}

func _valid_candidate(candidate: Dictionary, kind: String) -> bool:
	return not _prepared.is_empty() and _prepared.kind == kind and candidate.get("candidate_id") == _prepared.candidate_id \
		and candidate.get("combat") == _prepared.combat and candidate.get("setup") == _prepared.setup \
		and candidate.get("identity") == _prepared.identity and _prepared.combat.snapshot() == _prepared.opening \
		and _prepared.combat.run_handoff() == _prepared.handoff

func cancel_prepared_battle(candidate: Dictionary) -> void:
	if not _prepared.is_empty() and candidate.get("candidate_id") == _prepared.candidate_id and candidate.get("combat") == _prepared.combat:
		_prepared.clear()

func commit_route_battle(candidate: Dictionary) -> Dictionary:
	if not _valid_candidate(candidate, "route") or _status != "route_ready" or _combat != null:
		return _rejected("This prepared encounter is stale or changed before attachment.")
	var accepted := _route.confirm_entry(_prepared.token, func(_node, visit):
		return {"ok": _visit_identity(visit, int(_prepared.identity.generation)) == _prepared.identity})
	if not accepted.ok: return accepted
	_setup = _prepared.setup.duplicate(true)
	_entry_checkpoint = _prepared.entry.duplicate(true)
	_active_battle = _prepared.identity.duplicate(true)
	_record_battle_health_entry(_shop_identity(_active_battle))
	_battle_choices = _prepared.choices.duplicate()
	_reward_policy = str(_prepared.reward_policy)
	_combat = _prepared.combat
	_prepared.clear()
	_status = "battle"
	return {"ok": true, "error": "", "combat": _combat, "identity": _active_battle.duplicate(true)}

func prepare_continue_battle() -> Dictionary:
	if not _prepared.is_empty() or _preparing: return _rejected("A battle is already being prepared.")
	if _status == "battle" and _combat != null:
		return _store_candidate("live", _combat, _setup, _entry_checkpoint, _active_battle)
	if _status != "replay_pending" or _combat != null or _entry_checkpoint.is_empty():
		return _rejected("There is no replayable battle in this session.")
	var checkpoint := _entry_checkpoint.duplicate(true)
	var identity := _active_battle.duplicate(true)
	if _route_mode:
		if not _matches_active_visit(): return _rejected("The replay no longer matches its active visit.")
		_battle_generation += 1
		identity.generation = _battle_generation
		checkpoint.battle_identity = identity.duplicate(true)
	var entered := Combat.create_for_run(_setup, checkpoint)
	if not entered.ok: return entered
	return _store_candidate("replay", entered.combat, _setup, checkpoint, identity)

func commit_continue_battle(candidate: Dictionary) -> Dictionary:
	if _valid_candidate(candidate, "live") and _status == "battle" and _combat == candidate.combat:
		_prepared.clear()
		return {"ok": true, "error": "", "combat": _combat}
	if not _valid_candidate(candidate, "replay") or _status != "replay_pending" or _combat != null:
		return _rejected("The replay candidate is stale.")
	if _route_mode and not _matches_active_visit(): return _rejected("The replay visit changed.")
	_combat = _prepared.combat
	_active_battle = _prepared.identity.duplicate(true)
	_entry_checkpoint = _prepared.entry.duplicate(true)
	_prepared.clear()
	_status = "battle"
	return {"ok": true, "error": "", "combat": _combat, "identity": _active_battle.duplicate(true)}

func _visit_identity(visit: Dictionary, generation: int) -> Dictionary:
	return {"run_id": visit.run_id, "route_id": visit.route_id, "node_id": visit.node_id, "visit_id": visit.visit_id, "generation": generation}

func _matches_active_visit() -> bool:
	if _route == null or _active_battle.is_empty(): return false
	var route := _route.snapshot()
	var visit: Dictionary = route.active_visit
	return route.get("route_id") == _active_battle.get("route_id") and not visit.is_empty() \
		and _visit_identity(visit, int(_active_battle.generation)) == _active_battle

func enter_battle() -> Dictionary:
	if _route_mode: return _rejected("Route battles require the RC-026 room adapter.")
	if _status != "ready" or _combat != null:
		return _rejected("This run cannot enter the fixture again.")
	var checkpoint := _entry_data()
	var entered := Combat.create_for_run(_setup, checkpoint)
	if not entered.ok: return entered
	_entry_checkpoint = checkpoint.duplicate(true)
	_record_battle_health_entry(_standalone_health_identity())
	_combat = entered.combat
	_status = "battle"
	return entered

func continue_battle() -> Dictionary:
	if _status == "ready": return enter_battle()
	if _status == "battle" and _combat != null:
		return {"ok": true, "error": "", "combat": _combat}
	if _route_mode:
		var prepared := prepare_continue_battle()
		return commit_continue_battle(prepared) if prepared.ok else prepared
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
	if _status != "battle" or battle == null or battle != _combat or not _prepared.is_empty():
		return false
	var handoff := battle.run_handoff()
	if not handoff.ok or handoff.state != "playing": return false
	if _route_mode and (not _matches_active_visit() or handoff.get("battle_identity") != _active_battle): return false
	_combat = null
	_status = "replay_pending"
	return true

# The shell waits for terminal presentation to settle before calling this.
# Identity, conservation, health and outcome validation all precede commit.
func resolve_battle(battle: Combat) -> bool:
	if _status != "battle" or battle == null or battle != _combat or not _prepared.is_empty():
		return false
	var handoff := battle.run_handoff()
	if not handoff.ok or handoff.run_id != _run_id or handoff.encounter_id != _setup.encounter.id or not handoff.state in ["victory", "defeat"]:
		return false
	if handoff.owned_cards != _owned_cards or handoff.player_max_hp != _player_max_hp or handoff.get("relics", []) != _relics:
		return false
	if _route_mode:
		if not _matches_active_visit() or handoff.get("battle_identity") != _active_battle: return false
		var choices: Array = _battle_choices.duplicate() if handoff.state == "victory" else []
		if handoff.state == "victory" and "encounter_rewards" in choices:
			var rule := _select_reward_rule("encounter_rewards", str(_setup.encounter.id), str(_setup.encounter.get("encounter_role", "")))
			if rule.get("ok", false) and rule.rule.get("permanent_unlock", false) and not "permanent_unlock" in choices:
				choices.append("permanent_unlock")
		var outcome := "completed" if handoff.state == "victory" else "defeat"
		if not _route.can_resolve(_run_id, str(_active_battle.node_id), str(_active_battle.visit_id), outcome, choices): return false
		# All validation precedes either owner's commit. Route.resolve has no
		# callbacks; once accepted the following assignments cannot fail.
		if not _route.resolve(_run_id, str(_active_battle.node_id), str(_active_battle.visit_id), outcome, choices): return false
		_pending_result = {"identity": _active_battle.duplicate(true), "outcome": handoff.state,
			"encounter_id": handoff.encounter_id, "encounter_name": str(_setup.encounter.title),
			"enemy_name": str(_setup.encounter.name), "role": str(_setup.encounter.get("encounter_role", "")),
			"player_hp": handoff.player_hp, "player_max_hp": handoff.player_max_hp,
			"pending_choices": choices, "reward_policy": _reward_policy}
	var health_key := _shop_key(_shop_identity(_active_battle) if _route_mode else _standalone_health_identity())
	if _battle_health_records.has(health_key):
		_battle_health_records[health_key].result_hp = handoff.player_hp
		_battle_health_records[health_key].outcome = handoff.state
	_player_hp = handoff.player_hp
	_rng_states = handoff.rng_states.duplicate(true)
	_next_uid = handoff.next_uid
	_status = "encounter_won" if handoff.state == "victory" else "defeated"
	if handoff.state == "victory": _completed_encounters.append(handoff.encounter_id)
	_entry_checkpoint.clear()
	_combat = null
	if _route_mode:
		_active_battle.clear()
		if handoff.state == "victory": _create_reward_records()
		_sync_route_status()
	else: _ensure_terminal()
	return true

func acknowledge_result(identity: Dictionary) -> bool:
	if _pending_result.is_empty() or _status != "result_pending" or identity != _pending_result.identity: return false
	_pending_result.clear()
	_sync_route_status()
	return true

# Ending metadata records the boundary, never a second copy of the summary.
# Required guardian choices settle before victory; acknowledgement grants nothing.
func _expected_terminal() -> Dictionary:
	var phase := _route._status if _route != null else _status
	if not phase in ["tower_completed", "defeated"]: return {}
	if phase == "tower_completed":
		if _route == null or _route._visits.is_empty(): return {}
		var visit: Dictionary = _route._visits.back()
		var node: Dictionary = _route._nodes[visit.node_id]
		if node.room_id != "room_guardian" or node.encounter_role != "guardian" or node.depth != RouteState.PATH_LENGTH or visit.outcome != "completed" or not visit.pending_choices.is_empty() or node.encounter_id.is_empty(): return {}
		if _completed_encounters.is_empty() or _completed_encounters.back() != node.encounter_id: return {}
		var battle: Dictionary = _battle_health_records.get(_shop_key(_shop_identity(visit)), {})
		var retained_legacy: bool = _health_boundary.get("source_version", 0) in [1, 2] and _health_boundary.get("visit_count", 0) >= _route._visits.size()
		if battle.get("outcome") != "victory" and not retained_legacy: return {}
	elif _player_hp != 0: return {}
	var identity := _visit_identity(_route._visits.back(), _battle_generation) if _route != null and not _route._visits.is_empty() else _standalone_health_identity()
	return {"version": 1, "outcome": "victory" if phase == "tower_completed" else "defeat", "identity": identity,
		"boundary_status": phase, "acknowledged": false}

func _ensure_terminal() -> void:
	if _terminal.is_empty(): _terminal = _expected_terminal()

func final_results_ready() -> bool:
	return not _terminal.is_empty() and _pending_result.is_empty() and pending_reward().is_empty()

func acknowledge_final_result(identity: Dictionary) -> bool:
	if not final_results_ready() or _terminal.acknowledged or identity != _terminal.identity: return false
	_terminal.acknowledged = true
	return true

func abandonment_error(include_transient: bool = true) -> String:
	if not _terminal.is_empty() or _status in ["tower_completed", "defeated", "encounter_won", "abandoned", "invalid"]:
		return "This run has already ended and cannot be abandoned."
	if not _pending_result.is_empty() or not pending_reward().is_empty() or (_route != null and _route._status == "pending_choices"):
		return "Review the battle result and resolve every required reward choice before abandoning this run."
	if include_transient and (_preparing or not _prepared.is_empty() or _reward_transaction or _shop_transaction or _service_transaction):
		return "Finish the current operation before abandoning this run."
	if _combat != null:
		var handoff := _combat.run_handoff()
		if not handoff.get("ok", false) or handoff.get("state") != "playing": return "Review the battle result before abandoning this run."
	return ""

func _abandonment_token(boundary_status: String = "", source_version: int = SAVE_VERSION) -> Dictionary:
	var checkpoint := export_save()
	checkpoint.terminal = {}
	if not boundary_status.is_empty(): checkpoint.status = boundary_status
	# Verify genuine predecessor fingerprints using their exact original shape.
	# Only after that succeeds does migration sign the new empty-Store boundary.
	if source_version == 5:
		checkpoint.version = 5
		checkpoint.erase("store")
	return {"run_id": _run_id, "checkpoint_signature": JSON.stringify(checkpoint, "", true, true).sha256_text()}

func abandonment_request() -> Dictionary:
	var error := abandonment_error()
	if not error.is_empty(): return _rejected(error)
	return {"ok": true, "error": "", "token": _abandonment_token()}

func abandon_run(token: Dictionary) -> Dictionary:
	var requested := abandonment_request()
	if not requested.ok: return requested
	if token != requested.token: return _rejected("This abandonment confirmation is stale. Review the run again.")
	var boundary := "replay_pending" if _status == "battle" else _status
	_terminal = {"version": 1, "outcome": "abandoned", "identity": token.duplicate(true), "boundary_status": boundary, "acknowledged": false}
	# Retain the last committed checkpoint for validation/history. No mid-turn
	# resources or fabricated completion are adopted, and the model cannot resume.
	_combat = null
	_status = "abandoned"
	return {"ok": true, "error": "", "terminal": _terminal.duplicate(true)}

func run_summary() -> Dictionary:
	var visits: Array = []
	var enemies: Array = []
	var completed := 0
	if _route != null:
		for visit in _route._visits:
			var node: Dictionary = _route._nodes[visit.node_id]
			visits.append({"visit_id": visit.visit_id, "node_id": visit.node_id, "title": node.display_name,
				"room_type": node.room_type, "status": visit.status, "outcome": visit.outcome})
			if visit.status == "completed": completed += 1
			if visit.outcome == "completed" and not str(node.encounter_id).is_empty():
				enemies.append({"visit_id": visit.visit_id, "encounter_id": node.encounter_id, "enemy_id": node.enemy_id, "name": node.display_name})
	elif not _entry_checkpoint.is_empty() or _status in ["encounter_won", "defeated"] or _terminal.get("outcome") == "defeat":
		var won := _status == "encounter_won"
		visits.append({"visit_id": _standalone_health_identity().visit_id, "node_id": "standalone", "title": _setup.encounter.title,
			"room_type": "standalone", "status": "completed" if won else "defeated" if _player_hp == 0 else "active", "outcome": "completed" if won else "defeat" if _player_hp == 0 else ""})
		if won:
			completed = 1
			enemies.append({"visit_id": visits[0].visit_id, "encounter_id": _setup.encounter.id, "enemy_id": _setup.encounter.enemy_id, "name": _setup.encounter.name})
	var cards: Array = []
	for instance in _owned_cards:
		var resolved := InstanceEffects.resolve(_setup.get("catalog", {}), instance)
		if not resolved.ok or resolved.definition.get("temporary", false): continue
		var card: Dictionary = instance.duplicate(true)
		card.name = str(resolved.definition.get("name", instance.id))
		card.effect_summary = InstanceEffects.effect_summary(resolved.definition)
		card.effective_definition = resolved.definition
		cards.append(card)
	var awards: Array = []
	for record in _reward_records.values():
		if record.kind != "definition_unlock" or record.resolution != "unlocked": continue
		for claim in record.claims:
			if claim.component == "definition_unlock":
				awards.append({"definition_id": record.chosen_id, "name": str(_setup.catalog.get(record.chosen_id, {}).get("name", record.chosen_id)),
					"transaction_id": claim.transaction_id, "visit_id": record.identity.visit_id})
	return {"run_id": _run_id, "outcome": _terminal.get("outcome", "in_progress"), "entered_rooms": visits.size(), "completed_rooms": completed,
		"visits": visits, "defeated_enemies": enemies, "defeated_enemy_count": enemies.size(), "owned_cards": cards,
		"relics": _relics.duplicate(), "permanent_awards": awards, "player_hp": _player_hp, "player_max_hp": _player_max_hp, "gold": _gold}.duplicate(true)

# RC-027 policy injection is explicit: owner-approved production rules and
# excluded fixture rules are supplied separately by their respective callers.
# The schema describes explicit encounter roles/IDs, never dispatch families.
# Reward RNG belongs to the run and is not passed through Combat's three streams.
# These detached records are an RC-028 handoff, not a disk/save format.
func pending_reward() -> Dictionary:
	if _route == null: return {}
	var visit: Dictionary = _route.snapshot().active_visit
	if visit.is_empty(): return {}
	for record in _reward_records.values():
		if record.identity.visit_id == visit.visit_id and record.status != "resolved":
			return record.duplicate(true)
	return {}

func reward_snapshot(identity: Dictionary = {}) -> Dictionary:
	if identity.is_empty(): return pending_reward()
	var record: Dictionary = _reward_records.get(_reward_key(identity), {})
	return record.duplicate(true) if record.get("identity") == identity else {}

func _reward_identity(battle_identity: Dictionary, choice_id: String) -> Dictionary:
	return {"run_id": battle_identity.run_id, "route_id": battle_identity.route_id,
		"node_id": battle_identity.node_id, "visit_id": battle_identity.visit_id, "choice_id": choice_id}

func _reward_key(identity: Dictionary) -> String:
	return JSON.stringify([identity.get("run_id"), identity.get("route_id"), identity.get("node_id"), identity.get("visit_id"), identity.get("choice_id")])

func _select_reward_rule(choice_id: String, encounter_id: String = "", role: String = "") -> Dictionary:
	if encounter_id.is_empty(): encounter_id = str(_pending_result.get("encounter_id", ""))
	if role.is_empty(): role = str(_pending_result.get("role", ""))
	if _reward_rules.is_empty(): return {"ok": false, "error": "No reward policy was supplied for this run. This required choice remains pending."}
	if not _reward_rules.get("policy_id") is String or str(_reward_rules.policy_id).is_empty() or not _reward_rules.get("rules") is Array:
		return {"ok": false, "error": "The supplied reward policy is invalid. This choice remains pending."}
	var selected: Array = []
	for candidate in _reward_rules.rules:
		if not candidate is Dictionary: return {"ok": false, "error": "The supplied reward rule is invalid."}
		if candidate.get("encounter_id") == encounter_id and candidate.get("encounter_role") == role and candidate.get("choice_id") == choice_id:
			selected.append(candidate)
	if selected.size() != 1: return {"ok": false, "error": "No unique approved reward rule covers this encounter role and choice. This choice remains pending."}
	var rule: Dictionary = selected[0].duplicate(true)
	if not rule.get("eligible_ids") is Array or not rule.get("offer_count") is int or rule.offer_count < 1 or rule.offer_count > 3 \
		or not rule.get("gold") is int or rule.gold < 0 or rule.gold > 1000000 or not rule.get("allow_skip") is bool:
		return {"ok": false, "error": "The supplied reward quantities or choice policy are invalid."}
	if rule.has("permanent_unlock") and not rule.permanent_unlock is bool: return {"ok": false, "error": "The permanent acquisition policy is invalid."}
	var eligible: Array = []
	var unlocked: Array = _profile.snapshot().unlocked_definition_ids if _profile != null else []
	for id in rule.eligible_ids:
		if not id is String: return {"ok": false, "error": "Reward eligibility must contain definition IDs."}
		if _valid_reward_definition(id) and not id in eligible and (_profile == null or id in unlocked): eligible.append(id)
	eligible.sort()
	rule.eligible_ids = eligible
	return {"ok": true, "rule": rule, "policy_id": _reward_rules.policy_id}

func _valid_reward_definition(id: String) -> bool:
	if id == "free_spark" or not _setup.catalog.has(id): return false
	var definition: Dictionary = _setup.catalog[id].duplicate(true)
	if definition.get("temporary", false): return false
	var errors: Array = []
	preload("res://scripts/core/content_loader.gd")._validate_rune(definition, "reward", errors, _setup.get("production", {}))
	return errors.is_empty()

func _create_reward_records() -> void:
	# Called only after terminal transfer committed next_uid, HP and battle RNG.
	# An unavailable policy preserves the required choice without sampling RNG.
	for choice_id in _pending_result.pending_choices:
		var identity := _reward_identity(_pending_result.identity, choice_id)
		var key := _reward_key(identity)
		if _reward_records.has(key): continue
		if choice_id == "permanent_unlock":
			_create_unlock_record(identity)
			continue
		var selected := _select_reward_rule(choice_id)
		var record := {"identity": identity, "kind": "run_card", "status": "unavailable", "policy_id": "", "offered_ids": [],
			"eligible_ids": [], "resolution": "pending", "chosen_id": "", "granted_uid": -1,
			"allow_skip": false, "gold_amount": 0, "gold_claimed": false, "claims": [], "error": str(selected.get("error", ""))}
		if selected.ok:
			var rule: Dictionary = selected.rule
			var offered: Array = rule.eligible_ids.duplicate()
			# Partial Fisher-Yates; no repeated displayed options, no synthetic fill.
			for index in range(mini(int(rule.offer_count), offered.size())):
				if index + 1 < offered.size():
					var other := _reward_rng.randi_range(index, offered.size() - 1)
					var held: Variant = offered[index]
					offered[index] = offered[other]
					offered[other] = held
			offered.resize(mini(int(rule.offer_count), offered.size()))
			record.merge({"status": "pending", "policy_id": selected.policy_id, "offered_ids": offered,
				"eligible_ids": rule.eligible_ids, "allow_skip": rule.allow_skip,
				"gold_amount": rule.gold, "gold_claimed": rule.gold == 0, "error": ""}, true)
		_reward_records[key] = record
	_refresh_result_rewards()

func _create_unlock_record(identity: Dictionary) -> void:
	var selected := _select_reward_rule("encounter_rewards")
	var record := {"identity": identity, "kind": "definition_unlock", "status": "unavailable", "policy_id": "",
		"offered_ids": [], "eligible_ids": [], "resolution": "pending", "chosen_id": "", "granted_uid": -1,
		"allow_skip": false, "gold_amount": 0, "gold_claimed": true, "claims": [], "error": "Permanent acquisition requires a session profile and an explicit milestone policy."}
	if selected.ok and selected.rule.get("permanent_unlock", false) and _profile != null:
		var locked: Array = []
		for id in _setup.catalog:
			if _valid_reward_definition(id) and ProgressionState.validate_unlock(_profile, id): locked.append(id)
		locked.sort()
		record.status = "pending"
		record.policy_id = selected.policy_id
		record.eligible_ids = locked.duplicate()
		record.error = ""
		if locked.is_empty():
			# Exhaustion is an explicit, once-only milestone result: no duplicate
			# unlock, card, currency or compensation, and no random draw.
			if _route.complete_choice(identity.run_id, identity.node_id, identity.visit_id, identity.choice_id):
				record.status = "resolved"
				record.resolution = "exhausted"
				record.claims.append({"transaction_id": _reward_key(identity) + "/definition_unlock",
					"component": "definition_unlock", "resolution": "exhausted", "card": {}, "gold": 0})
			else:
				record.status = "unavailable"
				record.error = "The milestone no longer owns its required choice. No award was committed."
		else:
			var index := _reward_rng.randi_range(0, locked.size() - 1) if locked.size() > 1 else 0
			record.offered_ids = [locked[index]]
	_reward_records[_reward_key(identity)] = record

func _refresh_result_rewards() -> void:
	if _pending_result.is_empty(): return
	var records: Array = []
	for record in _reward_records.values():
		if record.identity.visit_id == _pending_result.identity.visit_id: records.append(record.duplicate(true))
	_pending_result.rewards = records
	var visit: Dictionary = _route.snapshot().active_visit
	_pending_result.pending_choices = visit.get("pending_choices", []).duplicate()
	# Presentation can accurately derive resources from committed claims even
	# while another required transaction keeps the visit locked.
	var cards: Array = []
	var unlocks: Array = []
	var paid := 0
	for record in records:
		if record.resolution == "chosen": cards.append({"id": record.chosen_id, "uid": record.granted_uid, "upgrade_rank": 0})
		if record.resolution == "unlocked": unlocks.append(record.chosen_id)
		if record.gold_claimed: paid += int(record.gold_amount)
	_pending_result.reward_summary = {"cards": cards, "unlocked_definition_ids": unlocks, "gold": paid, "pending": not _pending_result.pending_choices.is_empty()}

func _reward_request(identity: Dictionary) -> Dictionary:
	if _reward_transaction or _preparing or not _prepared.is_empty() or _route == null or not _status in ["result_pending", "pending_choices"]:
		return _rejected("There is no claimable reward at this boundary.")
	var record := reward_snapshot(identity)
	if record.is_empty() or record.status != "pending": return _rejected("This reward identity is stale, unavailable or already resolved.")
	if identity.run_id != _run_id or identity.route_id != _route.snapshot().route_id \
		or not _route.can_complete_choice(identity.run_id, identity.node_id, identity.visit_id, identity.choice_id):
		return _rejected("This reward no longer owns its required room choice.")
	return {"ok": true, "record": record}

func choose_reward(identity: Dictionary, definition_id: String) -> Dictionary:
	var request := _reward_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.resolution != "pending" or not definition_id in record.offered_ids or not definition_id in record.eligible_ids or not _valid_reward_definition(definition_id):
		return _rejected("Choose an eligible card from this unresolved offering.")
	if record.kind == "definition_unlock":
		if _profile == null or not ProgressionState.validate_unlock(_profile, definition_id): return _rejected("This definition is no longer eligible to unlock.")
		record.resolution = "unlocked"
		record.chosen_id = definition_id
		return _commit_reward(record, "definition_unlock")
	if _next_uid < 0 or _owned_cards.any(func(card): return card.uid >= _next_uid):
		return _rejected("The authoritative card allocator is invalid.")
	var card := {"id": definition_id, "uid": _next_uid, "upgrade_rank": 0}
	record.resolution = "chosen"
	record.chosen_id = definition_id
	record.granted_uid = _next_uid
	return _commit_reward(record, "rune", card)

func skip_reward(identity: Dictionary) -> Dictionary:
	var request := _reward_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.resolution != "pending" or not record.allow_skip: return _rejected("This rune choice cannot be skipped.")
	record.resolution = "skipped"
	return _commit_reward(record, "rune")

func claim_reward_gold(identity: Dictionary) -> Dictionary:
	var request := _reward_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.gold_claimed or record.gold_amount <= 0: return _rejected("There is no unclaimed Gold payout for this choice.")
	record.gold_claimed = true
	return _commit_reward(record, "gold")

func _commit_reward(record: Dictionary, component: String, card: Dictionary = {}) -> Dictionary:
	var identity: Dictionary = record.identity
	var complete: bool = record.resolution != "pending" and record.gold_claimed
	var transaction_id := _reward_key(identity) + "/" + component
	var gold_paid: int = int(record.gold_amount) if component == "gold" else 0
	var claim := {"transaction_id": transaction_id, "component": component,
		"resolution": record.resolution if component in ["rune", "definition_unlock"] else "claimed", "card": card.duplicate(true), "gold": gold_paid}
	if component == "definition_unlock": claim.unlocked_definition_id = record.chosen_id
	record.claims.append(claim)
	if complete: record.status = "resolved"
	# No callbacks occur inside this transaction. The route validates first;
	# after that commit only assignments remain, so a rejected completion never
	# grants a card/Gold or records a partial claim. Result_pending is deliberate:
	# the route can resolve while the independent acknowledgement remains open.
	_reward_transaction = true
	if complete and not _route.complete_choice(identity.run_id, identity.node_id, identity.visit_id, identity.choice_id):
		_reward_transaction = false
		return _rejected("The required choice changed before the reward could commit.")
	if component == "definition_unlock": ProgressionState.commit_validated_unlock(_profile, str(record.chosen_id))
	if not card.is_empty():
		_owned_cards.append(card.duplicate(true))
		_next_uid += 1
	_gold += gold_paid
	_reward_records[_reward_key(identity)] = record.duplicate(true)
	_refresh_result_rewards()
	_sync_route_status()
	_reward_transaction = false
	return {"ok": true, "error": "", "record": record.duplicate(true), "claim": claim.duplicate(true),
		"granted_card": card.duplicate(true), "gold_granted": gold_paid, "transaction_id": transaction_id}

func _entry_data() -> Dictionary:
	return {"version": 1, "run_id": _run_id, "encounter_id": _setup.get("encounter", {}).get("id", ""),
		"seed": _seed, "player_hp": _player_hp, "player_max_hp": _player_max_hp,
		"owned_cards": _owned_cards, "next_uid": _next_uid, "rng_states": _rng_states, "relics": _relics}.duplicate(true)

func _rejected(message: String) -> Dictionary:
	return {"ok": false, "error": message, "combat": null}

func profile_state() -> ProgressionState:
	return _profile

# New Run stages a detached profile, then adopts the existing application
# profile owner only after persistence succeeds.
func publish_profile_owner(owner: ProgressionState) -> void:
	if owner == null or _profile == null or owner == _profile: return
	owner.publish_transaction(_profile)
	_profile = owner

# Clone the authoritative owners without touching Combat, allocating cards,
# sampling randomness, or calling a content adapter. Live scene identity is
# retained; only a successful durable commit permits publish_transaction().
func clone_for_transaction() -> Dictionary:
	if _preparing or _reward_transaction or _shop_transaction or _service_transaction: return _rejected("A state transaction is already in progress.")
	var candidate := RuneRunState.new()
	for field in TRANSACTION_FIELDS:
		var value: Variant = get(field)
		candidate.set(field, value.duplicate(true) if value is Dictionary or value is Array else value)
	candidate._combat = _combat
	candidate._resolver = _resolver
	candidate._route = _route.clone_for_transaction() if _route != null else null
	candidate._profile = _profile.clone_for_transaction() if _profile != null else null
	candidate._reward_rng.state = _reward_rng.state
	candidate._shop_rng.state = _shop_rng.state
	return {"ok": true, "error": "", "run": candidate, "profile": candidate._profile}

func publish_transaction(candidate: RuneRunState) -> void:
	for field in TRANSACTION_FIELDS:
		var value: Variant = candidate.get(field)
		set(field, value.duplicate(true) if value is Dictionary or value is Array else value)
	_combat = candidate._combat
	_resolver = candidate._resolver
	if _route != null and candidate._route != null: _route.publish_transaction(candidate._route)
	else: _route = candidate._route
	if _profile != null and candidate._profile != null: _profile.publish_transaction(candidate._profile)
	else: _profile = candidate._profile
	_reward_rng.state = candidate._reward_rng.state
	_shop_rng.state = candidate._shop_rng.state

static func content_signature(setup: Dictionary) -> String:
	var configuration := setup.duplicate(true)
	# Owned instances have a separate validated authority and can grow after entry.
	configuration.erase("owned_cards")
	return JSON.stringify(configuration).sha256_text()

func export_save() -> Dictionary:
	var pending := _pending_result.duplicate(true)
	# These are result presentation projections, reconstructed from receipts.
	pending.erase("rewards")
	pending.erase("reward_summary")
	return {"version": SAVE_VERSION, "run_id": _run_id,
		"status": "replay_pending" if _status == "battle" else _status, "seed": _seed,
		"content": {"encounter_id": _setup.get("encounter", {}).get("id", ""),
			"board_id": _setup.get("encounter", {}).get("board_id", ""), "signature": content_signature(_setup)},
		"route_mode": _route_mode, "route": _route.export_save() if _route != null else {},
		"owned_cards": _owned_cards, "player_hp": _player_hp, "player_max_hp": _player_max_hp,
		"gold": _gold, "relics": _relics, "next_uid": _next_uid, "rng_states": _rng_states,
		"entry_checkpoint": _entry_checkpoint, "completed_encounters": _completed_encounters,
		"candidate_sequence": _candidate_sequence, "battle_generation": _battle_generation,
		"active_battle": _active_battle, "pending_result": pending, "battle_choices": _battle_choices,
		"reward_policy": _reward_policy, "policy_id": _reward_rules.get("policy_id", ""),
		"reward_records": _reward_records.values(), "reward_rng_state": _reward_rng.state,
		"shop_policy_id": ShopPolicy.POLICY_ID, "shop_records": _shop_records.values(), "shop_rng_state": _shop_rng.state,
		"service_policy_id": ServicePolicy.POLICY_ID, "service_records": _service_records.values(),
		"health_boundary": _health_boundary, "battle_health_records": _battle_health_records.values(), "terminal": _terminal, "store": _store}.duplicate(true)

# This local capability is for excluded test callers only. It never appears in
# exported data, and production loading always uses an empty context.
func restore_context_for_tests() -> Dictionary:
	var graph: Dictionary = _route._graph.duplicate(true) if _route != null else {}
	return {"allow_test_fixtures": true, "resolver": _resolver, "reward_rules": _reward_rules.duplicate(true),
		"setups": {content_signature(_setup): _setup.duplicate(true)},
		"route_graph_validator": func(saved): return {"ok": saved == graph, "errors": ["Fixture graph differs from its explicitly registered graph."] if saved != graph else []}}

static func restore_save(data: Dictionary, validated_setup: Dictionary, profile: ProgressionState, context: Dictionary = {}) -> Dictionary:
	var structure := _validate_save_structure(data, context.get("allow_test_fixtures", false) == true)
	if not structure.is_empty(): return {"ok": false, "error": structure}
	var fixture: bool = context.get("allow_test_fixtures", false) == true
	var rules: Dictionary = context.get("reward_rules", {}) if fixture else ProgressionState.production_rules()
	if data.policy_id != rules.get("policy_id", ""):
		# A standalone retained fixture has no reward policy or route.
		if not (not data.route_mode and data.policy_id.is_empty()): return {"ok": false, "error": "Saved reward policy is unavailable or incompatible with this application."}
		else: rules = {}
	if profile != null:
		var profile_validation := ProgressionState.restore_save(profile.export_save(), validated_setup.get("catalog", {}), fixture)
		if not profile_validation.ok: return profile_validation
	elif not fixture and data.route_mode:
		return {"ok": false, "error": "A production route requires its persistent definition profile."}
	var candidate := RuneRunState.new()
	candidate._run_id = data.run_id
	candidate._status = data.status
	candidate._terminal = data.terminal.duplicate(true) if data.version >= 5 else {}
	candidate._store = data.store.duplicate(true) if data.version >= 6 else StorePolicy.empty_state()
	# Abandonment retains its exact validated checkpoint rather than pretending
	# an unfinished room completed or converting live damage into saved history.
	if data.status == "abandoned":
		if candidate._terminal.get("outcome") != "abandoned": return {"ok": false, "error": "Saved abandonment has no matching terminal boundary."}
		candidate._status = candidate._terminal.boundary_status
	candidate._seed = data.seed
	candidate._profile = profile
	candidate._route_mode = data.route_mode
	candidate._reward_rules = rules.duplicate(true)
	candidate._resolver = context.get("resolver", EncounterResolver.new()) if fixture else EncounterResolver.new()
	if data.route_mode:
		var route_result := RouteState.restore_save(data.route, data.run_id, context if fixture else {})
		if not route_result.ok: return route_result
		candidate._route = route_result.route
		if candidate._route._graph.seed != data.seed: return {"ok": false, "error": "Run and route seeds disagree."}
	elif not data.route.is_empty(): return {"ok": false, "error": "A standalone run cannot carry a route."}
	var selected := candidate._restore_content(data, validated_setup, context if fixture else {})
	if not selected.ok: return selected
	candidate._setup = selected.setup
	for field in ["owned_cards", "player_hp", "player_max_hp", "gold", "relics", "next_uid", "rng_states", "entry_checkpoint", "completed_encounters", "candidate_sequence", "battle_generation", "active_battle", "pending_result", "battle_choices", "reward_policy"]:
		var value: Variant = data[field]
		candidate.set("_" + field, value.duplicate(true) if value is Array or value is Dictionary else value)
	candidate._reward_rng.state = data.reward_rng_state
	for record in data.reward_records:
		if not record is Dictionary or not record.get("identity") is Dictionary: return {"ok": false, "error": "Saved reward record has no valid identity."}
		var key := candidate._reward_key(record.identity)
		if candidate._reward_records.has(key): return {"ok": false, "error": "Saved rewards repeat a transaction identity."}
		candidate._reward_records[key] = record.duplicate(true)
	candidate._shop_rng.seed = data.seed ^ ShopPolicy.RNG_SALT
	if data.version >= 2:
		candidate._shop_rng.state = data.shop_rng_state
		for record in data.shop_records:
			if not record is Dictionary or not record.get("identity") is Dictionary: return {"ok": false, "error": "Saved shop has no valid identity."}
			var key := candidate._shop_key(record.identity)
			if candidate._shop_records.has(key): return {"ok": false, "error": "Saved shops repeat a visit identity."}
			candidate._shop_records[key] = record.duplicate(true)
	if data.version >= 3:
		candidate._health_boundary = data.health_boundary.duplicate(true)
		for record in data.service_records:
			if not record is Dictionary or not record.get("identity") is Dictionary: return {"ok": false, "error": "Saved service identity is malformed."}
			var key := candidate._shop_key(record.identity)
			if candidate._service_records.has(key): return {"ok": false, "error": "Saved services repeat a visit identity."}
			candidate._service_records[key] = record.duplicate(true)
		for record in data.battle_health_records:
			if not record is Dictionary or not record.get("identity") is Dictionary: return {"ok": false, "error": "Saved battle health identity is malformed."}
			var key := candidate._shop_key(record.identity)
			if candidate._battle_health_records.has(key): return {"ok": false, "error": "Saved battle health repeats a visit identity."}
			candidate._battle_health_records[key] = record.duplicate(true)
	if data.version < 4:
		var legacy_cards_error := candidate._normalize_legacy_cards()
		if not legacy_cards_error.is_empty(): return {"ok": false, "error": legacy_cards_error}
	# Predecessors are checked using their original supported states before an
	# explicit current-HP boundary is established. No historical HP is invented.
	var error := candidate._validate_store_boundaries()
	if not error.is_empty(): return {"ok": false, "error": error}
	error = candidate._validate_restored_state(fixture, data.version == 1)
	if not error.is_empty(): return {"ok": false, "error": error}
	if data.version < 3: candidate._establish_legacy_health_boundary(data.version)
	else:
		error = candidate._validate_health_history()
		if not error.is_empty(): return {"ok": false, "error": error}
	candidate._status = data.status
	if data.version < 5: candidate._ensure_terminal()
	error = candidate._validate_terminal(data.version)
	if not error.is_empty(): return {"ok": false, "error": error}
	if data.version == 5 and candidate._terminal.get("outcome") == "abandoned":
		candidate._terminal.identity = candidate._abandonment_token(candidate._terminal.boundary_status)
	candidate._refresh_result_rewards()
	return {"ok": true, "error": "", "run": candidate, "migrated": data.version < SAVE_VERSION}

func _validate_terminal(source_version: int = SAVE_VERSION) -> String:
	if _terminal.get("outcome") == "abandoned":
		if _status != "abandoned" or not _terminal.boundary_status in ["ready", "route_ready", "room_active", "replay_pending"]:
			return "Saved abandonment does not reference an eligible unfinished checkpoint."
		if not _pending_result.is_empty() or not pending_reward().is_empty() or (_route != null and _route._status in ["pending_choices", "tower_completed", "defeated"]):
			return "Saved abandonment cannot conceal pending choices or a completed ending."
		if _player_hp <= 0 or _terminal.identity != _abandonment_token(_terminal.boundary_status, source_version): return "Saved abandonment identity differs from its committed checkpoint."
		return ""
	var expected := _expected_terminal()
	if expected.is_empty():
		if not _terminal.is_empty() or _status == "abandoned" or (_route != null and _route._status == "tower_completed"):
			return "Saved terminal outcome has no validated final battle history."
		return ""
	if _terminal.is_empty(): return "Saved final battle is missing its terminal outcome."
	for field in ["version", "outcome", "identity", "boundary_status"]:
		if _terminal.get(field) != expected[field]: return "Saved terminal outcome differs from its authoritative battle history."
	if _terminal.acknowledged and not final_results_ready(): return "Saved final results were acknowledged before required results or choices settled."
	return ""

static func _validate_save_structure(data: Dictionary, fixture: bool = false) -> String:
	if not data.get("version") is int or not data.version in [1, 2, 3, 4, 5, SAVE_VERSION] or data.size() != (25 if data.version == 1 else 28 if data.version == 2 else 34 if data.version == 6 else 33 if data.version == 5 else 32): return "Unsupported or malformed run save version."
	if data.version >= 6:
		var store_error := StorePolicy.validate_structure(data.get("store"))
		if not store_error.is_empty(): return store_error
	if data.version >= 5:
		if not data.get("terminal") is Dictionary: return "Saved terminal boundary must be an object."
		if not data.terminal.is_empty():
			var terminal: Dictionary = data.terminal
			if terminal.size() != 5 or not terminal.get("version") is int or terminal.version != 1 or not terminal.get("outcome") is String or not terminal.outcome in ["victory", "defeat", "abandoned"] or not terminal.get("identity") is Dictionary or not terminal.get("boundary_status") is String or not terminal.get("acknowledged") is bool: return "Saved terminal boundary structure is invalid."
	for key in ["run_id", "status", "reward_policy", "policy_id"]:
		if not data.get(key) is String: return "Saved run %s must be text." % key
	if not data.run_id.begins_with("run-") or data.run_id.length() != 36: return "Saved run identity is invalid."
	for character in data.run_id.trim_prefix("run-"):
		if not character in "0123456789abcdef": return "Saved run identity is invalid."
	for key in ["seed", "player_hp", "player_max_hp", "gold", "next_uid", "candidate_sequence", "battle_generation", "reward_rng_state"]:
		if not data.get(key) is int: return "Saved run %s must be an exact integer." % key
	if data.seed < 0 or data.player_max_hp <= 0 or data.player_max_hp > ContentLoader.MAX_HEALTH or data.player_hp < 0 or data.player_hp > data.player_max_hp:
		return "Saved run seed or health is outside its supported range."
	if data.gold < 0 or data.next_uid < 8 or data.next_uid == 9223372036854775807 or data.candidate_sequence < 0 or data.battle_generation < 0: return "Saved run counters are invalid."
	if not data.get("route_mode") is bool: return "Saved run mode is invalid."
	for key in ["content", "route", "rng_states", "entry_checkpoint", "active_battle", "pending_result"]:
		if not data.get(key) is Dictionary: return "Saved run %s must be an object." % key
	for key in ["owned_cards", "relics", "completed_encounters", "battle_choices", "reward_records"]:
		if not data.get(key) is Array: return "Saved run %s must be an array." % key
	if data.version < 4 and not data.relics.is_empty(): return "Legacy saves cannot contain relics."
	if not RelicPolicy.validate_owned(data.relics).is_empty(): return "Saved relic ownership is invalid."
	if data.owned_cards.size() < (8 if data.version == 1 else ShopPolicy.MIN_OWNED) or data.owned_cards.size() > ContentLoader.MAX_CARDS or data.reward_records.size() > 32: return "Saved ownership or reward count exceeds its bounded schema."
	if data.version >= 2:
		if not data.get("shop_policy_id") is String or not data.shop_policy_id in ([ShopPolicy.POLICY_ID, ShopPolicy.LEGACY_POLICY_ID] if data.version >= 4 else [ShopPolicy.LEGACY_POLICY_ID]) or not data.get("shop_rng_state") is int or not data.get("shop_records") is Array or data.shop_records.size() > RouteState.PATH_LENGTH:
			return "Saved shop schema or registered policy is invalid."
	if data.version >= 3:
		if not data.get("service_policy_id") is String or not data.service_policy_id in ([ServicePolicy.POLICY_ID, ServicePolicy.LEGACY_POLICY_ID] if data.version >= 4 else [ServicePolicy.LEGACY_POLICY_ID]) or not data.get("service_records") is Array or data.service_records.size() > RouteState.PATH_LENGTH or not data.get("health_boundary") is Dictionary or not data.get("battle_health_records") is Array or data.battle_health_records.size() > RouteState.PATH_LENGTH:
			return "Saved service or health history schema is invalid."
	var seen_uids := {}
	for card in data.owned_cards:
		if not card is Dictionary or card.size() != (3 if data.version >= 4 else 2) or not card.get("id") is String or not card.get("uid") is int: return "Saved owned card structure is invalid."
		if data.version >= 4 and (not card.get("upgrade_rank") is int or not card.upgrade_rank in [0, 1]): return "Saved upgrade rank is invalid."
		if card.uid < 0 or card.uid >= data.next_uid or seen_uids.has(card.uid): return "Saved owned card identities are duplicated or outside the allocator."
		seen_uids[card.uid] = true
	if not data.active_battle.is_empty():
		if data.active_battle.size() != 5 or not data.active_battle.get("generation") is int or data.active_battle.generation <= 0: return "Saved active battle identity is invalid."
		for key in ["run_id", "route_id", "node_id", "visit_id"]:
			if not data.active_battle.get(key) is String or data.active_battle[key].is_empty(): return "Saved active battle identity is incomplete."
	if not data.entry_checkpoint.is_empty():
		for key in ["version", "seed", "player_hp", "player_max_hp", "next_uid"]:
			if not data.entry_checkpoint.get(key) is int: return "Saved checkpoint %s must be an exact integer." % key
		for key in ["run_id", "encounter_id"]:
			if not data.entry_checkpoint.get(key) is String: return "Saved checkpoint identity is malformed."
		if not data.entry_checkpoint.get("owned_cards") is Array or not data.entry_checkpoint.get("rng_states") is Dictionary: return "Saved checkpoint resources are malformed."
		if data.entry_checkpoint.has("battle_identity"):
			var identity: Variant = data.entry_checkpoint.battle_identity
			if not identity is Dictionary or identity.size() != 5 or not identity.get("generation") is int: return "Saved checkpoint battle identity is malformed."
			for key in ["run_id", "route_id", "node_id", "visit_id"]:
				if not identity.get(key) is String: return "Saved checkpoint battle identity is incomplete."
	if data.rng_states.size() != 3: return "Saved run requires exactly three battle random streams."
	for stream in ["cards", "endpoints", "kits"]:
		if not data.rng_states.get(stream) is int: return "Saved battle random stream is not an exact integer."
	if data.content.size() != 3: return "Saved content reference is malformed."
	for key in ["encounter_id", "board_id", "signature"]:
		if not data.content.get(key) is String or data.content[key].is_empty(): return "Saved content reference is incomplete."
	for choice in data.battle_choices:
		if not choice is String or choice.is_empty() or data.battle_choices.count(choice) != 1: return "Saved battle choices are invalid."
	for encounter in data.completed_encounters:
		if not encounter is String or (not fixture and not EncounterResolver.SOURCES.has(encounter)): return "Saved completion references unavailable content."
	return ""

func _restore_content(data: Dictionary, base_setup: Dictionary, context: Dictionary) -> Dictionary:
	var ref: Dictionary = data.content
	var candidates: Array = [base_setup.duplicate(true)]
	var fixture: bool = context.get("allow_test_fixtures", false)
	if fixture:
		for setup in context.get("setups", {}).values(): candidates.append(setup.duplicate(true))
	elif ref.encounter_id != "training_shadeling": return _rejected("Saved encounter is not registered for production loading.")
	if not ref.board_id in RouteState.BOARD_IDS: return _rejected("Saved board identity is unavailable.")
	var entry := {"version": 1, "run_id": data.run_id, "encounter_id": ref.encounter_id, "seed": data.seed,
		"player_hp": maxi(1, data.player_hp), "player_max_hp": data.player_max_hp,
		"owned_cards": data.owned_cards, "next_uid": data.next_uid, "rng_states": data.rng_states, "relics": data.relics}
	if _route != null:
		for node in _route._graph.nodes:
			if node.encounter_id == ref.encounter_id and node.board_id == ref.board_id:
				var resolved: Dictionary = _resolver.resolve(node, entry)
				if resolved.get("ok", false): candidates.append(resolved.setup)
	for setup in candidates:
		if setup.get("encounter", {}).get("id") == ref.encounter_id and setup.encounter.get("board_id") == ref.board_id and content_signature(setup) == ref.signature:
			if setup.get("catalog") != base_setup.get("catalog"): return _rejected("Saved encounter catalogue is incompatible.")
			setup.owned_cards = data.owned_cards.map(func(card): return card.id)
			return {"ok": true, "error": "", "setup": setup.duplicate(true)}
	return _rejected("Saved encounter configuration no longer matches registered content; progress was preserved.")

func _validate_restored_state(fixture: bool, legacy: bool = false) -> String:
	var allowed := ["route_ready", "room_active", "pending_choices", "replay_pending", "result_pending", "tower_completed", "defeated"] if _route_mode else ["ready", "replay_pending", "encounter_won", "defeated"]
	if not _status in allowed: return "Saved run phase is unsupported."
	if _player_max_hp != _maximum_for_relics(_relics): return "Saved maximum health disagrees with relic ownership."
	if not fixture and _status == "room_active" and (legacy or _route == null or (not _shop_records.has(_shop_key(_shop_identity(_route._active))) and not _service_records.has(_shop_key(_shop_identity(_route._active))))): return "Saved active room has no supported battle-entry checkpoint or service handler."
	if not _pending_result.is_empty() and not _pending_result.get("outcome") is String: return "Saved pending outcome is malformed."
	if (_status == "defeated" or (_pending_result.get("outcome") == "defeat")) != (_player_hp == 0): return "Saved defeat and health disagree."
	var ownership_setup := _setup.duplicate(true)
	var ids: Array = []
	for card in _owned_cards:
		if not card is Dictionary or not card.get("id") is String or not card.get("uid") is int: return "Saved owned card is malformed."
		ids.append(card.id)
	ownership_setup.owned_cards = ids
	var entry := _entry_data()
	entry.player_hp = maxi(1, _player_hp)
	var ownership_error := Combat.validate_run_entry(ownership_setup, entry)
	if not ownership_error.is_empty(): return ownership_error
	var starter: Array = ["spark", "shield", "conjure", "spark", "shield", "focus", "focus", "conjure"]
	if legacy:
		for index in range(8):
			if _owned_cards[index] != {"id": starter[index], "uid": index, "upgrade_rank": 0}: return "Saved run starter instances have changed."
	if _status == "replay_pending":
		if _entry_checkpoint.size() != (11 if _route_mode else 10): return "Saved battle checkpoint structure is invalid."
		var checkpoint_setup := _setup.duplicate(true)
		checkpoint_setup.owned_cards = ids
		var checkpoint_error := Combat.validate_run_entry(checkpoint_setup, _entry_checkpoint)
		if not checkpoint_error.is_empty(): return "Saved battle entry: " + checkpoint_error
		for key in ["run_id", "seed", "owned_cards", "player_hp", "player_max_hp", "next_uid", "rng_states", "relics"]:
			if _entry_checkpoint.get(key) != _entry_data().get(key): return "Saved battle entry disagrees with committed run resources."
		if _route_mode and (not _matches_active_visit() or _entry_checkpoint.get("battle_identity") != _active_battle or _active_battle.get("generation") != _battle_generation): return "Saved battle entry no longer owns its route visit."
		if _route_mode:
			var node: Dictionary = _route._nodes[_active_battle.node_id]
			if node.encounter_id != _setup.encounter.id or node.board_id != _setup.encounter.board_id or node.enemy_id != _setup.encounter.enemy_id or node.encounter_role != _setup.encounter.get("encounter_role", ""): return "Saved battle configuration differs from its selected route node."
			var resolved: Dictionary = _resolver.resolve(node, _entry_checkpoint)
			if not resolved.get("ok", false) or resolved.get("pending_choices", []) != _battle_choices or str(resolved.get("reward_policy", "")) != _reward_policy: return "Saved battle choice policy differs from its registered encounter."
		if not _pending_result.is_empty(): return "An unresolved battle cannot also have a committed result."
	else:
		if not _entry_checkpoint.is_empty() or not _active_battle.is_empty(): return "Resolved saved phase retains an active battle checkpoint."
	if _route_mode:
		if _status == "replay_pending" and _route._status != "room_active": return "Saved battle route is no longer active."
		if _status == "result_pending":
			var error := _validate_pending_result()
			if not error.is_empty(): return error
		elif not _pending_result.is_empty(): return "Saved result acknowledgement is inconsistent."
		elif _status != "replay_pending" and _status != _route._status: return "Saved run and route phases disagree."
		var victories: Array = []
		for visit in _route._visits:
			var visited_node: Dictionary = _route._nodes[visit.node_id]
			# New excluded encounters require an explicit live resolver capability,
			# not merely a fixture flag or an encounter ID claimed by saved data.
			if fixture and not str(visited_node.encounter_id).is_empty() and not EncounterResolver.SOURCES.has(visited_node.encounter_id):
				var validation_entry := _entry_data()
				validation_entry.player_hp = maxi(1, _player_hp)
				var registered: Dictionary = _resolver.resolve(visited_node, validation_entry)
				if not registered.get("ok", false): return "Saved fixture encounter has no validated registration."
				var encounter: Dictionary = registered.get("setup", {}).get("encounter", {})
				if encounter.get("id") != visited_node.encounter_id or encounter.get("enemy_id") != visited_node.enemy_id or encounter.get("board_id") != visited_node.board_id or encounter.get("encounter_role") != visited_node.encounter_role or registered.get("setup", {}).get("catalog") != _setup.catalog:
					return "Saved fixture encounter differs from its explicit registered content."
			if not fixture:
				var node: Dictionary = _route._nodes[visit.node_id]
				if not legacy and node.room_id in ["room_shop", "room_event", "room_recovery"]:
					if not (visit.pending_choices + visit.completed_choices).is_empty() or visit.outcome == "defeat": return "Saved shop has an unsupported outcome or choices."
					continue
				if node.encounter_id != "training_shadeling" or node.enemy_id != "shadeling" or node.encounter_role != "boss": return "Saved visited room requires content that is not available in this production version."
				var expected: Array = []
				if visit.outcome == "completed": expected = ["encounter_rewards", "permanent_unlock"]
				var actual: Array = visit.pending_choices + visit.completed_choices
				actual.sort()
				expected.sort()
				if actual != expected: return "Saved required choices differ from the registered encounter and milestone policy."
			if visit.outcome == "completed":
				var encounter: String = _route._nodes[visit.node_id].encounter_id
				if not encounter.is_empty(): victories.append(encounter)
		if victories != _completed_encounters: return "Saved completed encounters disagree with route outcomes."
	elif not _pending_result.is_empty() or not _reward_records.is_empty(): return "Standalone run contains route-only results or rewards."
	return _validate_saved_rewards(fixture, legacy)

func _validate_pending_result() -> String:
	if _pending_result.size() != 10 or not _pending_result.get("identity") is Dictionary or _route._visits.is_empty(): return "Saved pending result structure is invalid."
	for key in ["player_hp", "player_max_hp"]:
		if not _pending_result.get(key) is int: return "Saved pending result health must use exact integers."
	if not _pending_result.get("pending_choices") is Array: return "Saved pending result choices are malformed."
	for key in ["outcome", "encounter_id", "encounter_name", "enemy_name", "role", "reward_policy"]:
		if not _pending_result.get(key) is String: return "Saved pending result metadata is malformed."
	var identity: Dictionary = _pending_result.identity
	var visit: Dictionary = _route._visits.back()
	if not identity.get("generation") is int or identity.generation <= 0 or identity.generation != _battle_generation or identity != _visit_identity(visit, identity.generation): return "Saved result identity disagrees with its completed battle."
	var outcome := "defeat" if visit.outcome == "defeat" else "victory" if visit.outcome == "completed" else ""
	if _pending_result.get("outcome") != outcome or outcome.is_empty(): return "Saved result disagrees with its route outcome."
	if _pending_result.get("encounter_id") != _setup.encounter.id or _route._nodes[visit.node_id].encounter_id != _setup.encounter.id: return "Saved result encounter differs from its selected room."
	# Terminal presentation retains the raw combat boundary. Later acquisition
	# hooks have their own chronological health receipts rather than rewriting it.
	var raw_health: Dictionary = _battle_health_records.get(_shop_key(_shop_identity(identity)), {})
	if not raw_health.is_empty() and (not raw_health.get("result_hp") is int or not raw_health.get("player_max_hp") is int): return "Saved raw battle health is malformed."
	var result_hp: int = raw_health.get("result_hp", _player_hp)
	var result_max_hp: int = raw_health.get("player_max_hp", _player_max_hp)
	if _pending_result.get("player_hp") != result_hp or _pending_result.get("player_max_hp") != result_max_hp or _pending_result.get("pending_choices") != visit.pending_choices: return "Saved result resources or required choices disagree with the raw battle boundary."
	if _pending_result.get("encounter_name") != _setup.encounter.title or _pending_result.get("enemy_name") != _setup.encounter.name or _pending_result.get("role") != _setup.encounter.get("encounter_role", "") or _pending_result.get("reward_policy") != _reward_policy: return "Saved result metadata differs from selected content."
	return ""

func _validate_saved_rewards(_fixture: bool, legacy: bool = false) -> String:
	var transactions := {}
	var awarded := {}
	var paid := 0
	for record in _reward_records.values():
		if record.size() != 14: return "Saved reward record structure is invalid."
		for key in ["kind", "status", "policy_id", "resolution", "chosen_id", "error"]:
			if not record.get(key) is String: return "Saved reward %s must be text." % key
		for key in ["offered_ids", "eligible_ids", "claims"]:
			if not record.get(key) is Array: return "Saved reward %s must be an array." % key
		if not record.get("granted_uid") is int or not record.get("gold_amount") is int or not record.get("allow_skip") is bool or not record.get("gold_claimed") is bool:
			return "Saved reward quantities are malformed."
		var identity: Dictionary = record.identity
		if identity.size() != 5 or not identity.get("run_id") is String or not identity.get("route_id") is String or identity.run_id != _run_id or _route == null or identity.route_id != _route._graph.route_id:
			return "Saved reward belongs to an invalid run or route."
		for key in ["node_id", "visit_id", "choice_id"]:
			if not identity.get(key) is String or identity[key].is_empty(): return "Saved reward identity is incomplete."
		var visit := {}
		for item in _route._visits:
			if item.visit_id == identity.visit_id: visit = item
		if visit.is_empty() or visit.node_id != identity.node_id or visit.outcome != "completed": return "Saved reward has no matching victorious visit."
		var all_choices: Array = visit.pending_choices + visit.completed_choices
		if not identity.choice_id in all_choices: return "Saved reward has no matching required room choice."
		if record.status == "resolved":
			if not identity.choice_id in visit.completed_choices: return "Saved reward receipt did not complete its required choice."
		elif not identity.choice_id in visit.pending_choices: return "Saved unresolved reward lost its required choice lock."
		if not record.status in ["pending", "resolved", "unavailable"] or not record.kind in ["run_card", "definition_unlock"]: return "Saved reward kind or status is unsupported."
		if (record.kind == "definition_unlock") != (identity.choice_id == "permanent_unlock"): return "Saved reward kind and choice disagree."
		var node: Dictionary = _route._nodes[visit.node_id]
		var selected := _select_reward_rule("encounter_rewards" if record.kind == "definition_unlock" else identity.choice_id, node.encounter_id, node.encounter_role)
		if record.status == "unavailable":
			if record.policy_id != "" or record.resolution != "pending" or record.chosen_id != "" or record.granted_uid != -1 or not record.claims.is_empty() or not record.offered_ids.is_empty() or not record.eligible_ids.is_empty() or record.gold_amount != 0:
				return "Saved unavailable reward contains an unauthorized grant."
			if selected.ok and (record.kind == "run_card" or _profile != null): return "Saved unavailable reward contradicts its registered policy."
			continue
		if not selected.ok or record.policy_id != selected.policy_id: return "Saved reward policy is unavailable or incompatible."
		var rule: Dictionary = selected.rule
		if record.kind == "run_card" and (record.gold_amount != rule.gold or record.allow_skip != rule.allow_skip): return "Saved reward amount differs from its registered policy."
		if record.kind == "definition_unlock" and (not rule.get("permanent_unlock", false) or record.gold_amount != 0 or not record.gold_claimed or record.allow_skip or _profile == null): return "Saved definition unlock has no valid milestone policy."
		var seen: Array = []
		for id in record.eligible_ids:
			if not id is String or id in seen or not _valid_reward_definition(id): return "Saved reward eligibility contains invalid or duplicate definitions."
			if record.kind == "run_card" and (not id in rule.eligible_ids or (_profile != null and not id in _profile._unlocked)): return "Saved run reward definition is not unlocked and eligible."
			seen.append(id)
		var unlocked_at_entry: Array = _profile._unlocked.duplicate() if _profile != null else []
		# Undo this run's same/later milestone claims to recover historical
		# eligibility. Already unlocked definitions from earlier runs remain.
		var visit_index: int = _route._visits.find(visit)
		for other in _reward_records.values():
			if other.get("kind") == "definition_unlock" and other.get("resolution") == "unlocked" and other.get("identity") is Dictionary:
				for index in range(visit_index, _route._visits.size()):
					if _route._visits[index].visit_id == other.identity.get("visit_id"): unlocked_at_entry.erase(other.get("chosen_id"))
		var expected_eligible: Array = []
		if record.kind == "run_card":
			# Rules are registered locally; obtain their raw IDs before current
			# profile filtering, then apply the historical owner above.
			for raw in _reward_rules.rules:
				if raw.get("encounter_id") == node.encounter_id and raw.get("encounter_role") == node.encounter_role and raw.get("choice_id") == identity.choice_id:
					for id in raw.eligible_ids:
						if _valid_reward_definition(id) and not id in expected_eligible and (_profile == null or id in unlocked_at_entry): expected_eligible.append(id)
		else:
			for id in ProgressionState.INITIAL_IDS:
				if _valid_reward_definition(id) and not id in unlocked_at_entry: expected_eligible.append(id)
		expected_eligible.sort()
		if record.eligible_ids != expected_eligible: return "Saved reward eligibility disagrees with the profile at its committed milestone."
		if record.offered_ids.size() > (1 if record.kind == "definition_unlock" else int(rule.offer_count)): return "Saved reward offering exceeds its policy."
		seen = []
		for id in record.offered_ids:
			if not id is String or id in seen or not id in record.eligible_ids: return "Saved reward offering contains invalid or duplicate definitions."
			seen.append(id)
		if record.offered_ids.size() != mini(record.eligible_ids.size(), 1 if record.kind == "definition_unlock" else int(rule.offer_count)): return "Saved reward offering is incomplete."
		if not record.resolution in (["pending", "chosen", "skipped"] if record.kind == "run_card" else ["pending", "unlocked", "exhausted"]): return "Saved reward resolution is invalid."
		if record.resolution in ["chosen", "unlocked"]:
			if not record.chosen_id in record.offered_ids: return "Saved chosen definition was not offered."
		elif record.chosen_id != "" or record.granted_uid != -1: return "An unchosen saved reward contains a grant."
		if record.resolution == "skipped" and not record.allow_skip: return "Saved reward was skipped against policy."
		if record.resolution == "unlocked" and (not record.chosen_id in _profile._unlocked or record.granted_uid != -1): return "Saved unlock receipt disagrees with profile ownership."
		if record.resolution == "pending" and record.kind == "definition_unlock":
			for id in record.eligible_ids:
				if id in _profile._unlocked: return "Saved pending milestone offers an already unlocked definition."
		if record.resolution == "exhausted" and (not record.eligible_ids.is_empty() or not record.offered_ids.is_empty()): return "Saved exhausted milestone still has eligible definitions."
		if record.resolution == "chosen":
			var card := {"id": record.chosen_id, "uid": record.granted_uid, "upgrade_rank": 0}
			if record.granted_uid < 8 or record.granted_uid >= _next_uid or (legacy and not card in _owned_cards) or awarded.has(record.granted_uid): return "Saved card receipt disagrees with owned instances."
			awarded[record.granted_uid] = card
		var expected: Array = []
		var key := _reward_key(identity)
		if record.kind == "run_card" and record.resolution != "pending":
			expected.append({"transaction_id": key + "/rune", "component": "rune", "resolution": record.resolution,
				"card": {"id": record.chosen_id, "uid": record.granted_uid, "upgrade_rank": 0} if record.resolution == "chosen" else {}, "gold": 0})
		if record.kind == "definition_unlock" and record.resolution != "pending":
			var claim := {"transaction_id": key + "/definition_unlock", "component": "definition_unlock", "resolution": record.resolution, "card": {}, "gold": 0}
			if record.resolution == "unlocked": claim.unlocked_definition_id = record.chosen_id
			expected.append(claim)
		if record.gold_amount == 0 and not record.gold_claimed: return "Zero-Gold saved reward incorrectly requires a claim."
		if record.gold_amount > 0 and record.gold_claimed:
			expected.append({"transaction_id": key + "/gold", "component": "gold", "resolution": "claimed", "card": {}, "gold": record.gold_amount})
			paid += record.gold_amount
		if record.claims.size() != expected.size(): return "Saved reward receipts disagree with resolved components."
		for claim in record.claims:
			if not claim is Dictionary or not claim in expected or transactions.has(claim.get("transaction_id")): return "Saved reward receipt is invalid or duplicated."
			if not claim.get("gold") is int or not claim.get("card") is Dictionary: return "Saved receipt quantities are malformed."
			if not claim.card.is_empty() and (not claim.card.get("uid") is int or not claim.card.get("id") is String): return "Saved receipt card identity is malformed."
			transactions[claim.transaction_id] = true
		if (record.status == "resolved") != (record.resolution != "pending" and record.gold_claimed): return "Saved reward completion does not match its component receipts."
	if legacy:
		if _gold != paid: return "Saved Gold disagrees with its configured reward receipts."
		for card in _owned_cards.slice(8):
			if not awarded.has(card.uid) or awarded[card.uid] != card: return "Saved acquired instance has no committed reward receipt."
	else:
		var history_error := _validate_shop_history()
		if not history_error.is_empty(): return history_error
	if _route != null:
		for visit in _route._visits:
			for choice in visit.pending_choices + visit.completed_choices:
				if choice in ["encounter_rewards", "permanent_unlock"] and not _reward_records.has(_reward_key(_reward_identity(visit, choice))): return "Saved required reward choice is missing its retained offering or receipt."
	return ""

# Shop ownership is retained by visit. Only explicit Leave resolves the route;
# shopping never alters battle checkpoints, profile unlocks or route revisions.
func _shop_identity(visit: Dictionary) -> Dictionary:
	return {"run_id": visit.get("run_id", ""), "route_id": visit.get("route_id", ""), "node_id": visit.get("node_id", ""), "visit_id": visit.get("visit_id", "")}

func _shop_key(identity: Dictionary) -> String:
	return JSON.stringify([identity.get("run_id"), identity.get("route_id"), identity.get("node_id"), identity.get("visit_id")])

func _shop_eligible(unlocked: Array) -> Array:
	var eligible: Array = []
	for id in ShopPolicy.INITIAL_IDS:
		if id in unlocked and _valid_reward_definition(id): eligible.append(id)
	eligible.sort()
	return eligible

func prepare_route_shop(token: Dictionary) -> Dictionary:
	if _route == null or _status != "route_ready" or _preparing or not _prepared.is_empty() or _combat != null:
		return _rejected("Resolve the current room first.")
	var preview := _route.preview_entry(token)
	if not preview.ok: return preview
	if preview.node.get("room_id") != "room_shop": return _rejected("This room is not a shop.")
	var identity := _shop_identity(preview.visit)
	if _shop_records.has(_shop_key(identity)): return _rejected("This shop has already been entered.")
	var eligible := _shop_eligible(_profile._unlocked if _profile != null else [])
	var rng := RandomNumberGenerator.new()
	rng.state = _shop_rng.state
	var slots: Array = []
	for id in ShopPolicy.offerings(eligible, rng):
		slots.append({"slot_id": "rune-%d" % (slots.size() + 1), "definition_id": id, "price": ShopPolicy.RUNE_PRICE, "sold": false, "granted_uid": -1})
	var record := {"version": 2, "identity": identity, "policy_id": ShopPolicy.POLICY_ID, "eligibility_version": ShopPolicy.ELIGIBILITY_VERSION,
		"eligible_ids": eligible, "slots": slots, "removal": {"price": ShopPolicy.REMOVAL_PRICE, "used": false, "removed_card": {}},
		"transactions": [], "status": "active", "rng_before": _shop_rng.state, "rng_after": rng.state, "entry_next_uid": _next_uid,
		"relic_offering": _relic_offering(identity, "shop", _relics, 1), "upgrade": {"price": ShopPolicy.UPGRADE_PRICE, "used": false, "card": {}}}
	_candidate_sequence += 1
	_prepared = {"kind": "shop", "candidate_id": _candidate_sequence, "token": token.duplicate(true), "identity": identity.duplicate(true), "shop": record}
	return {"ok": true, "error": "", "candidate_id": _candidate_sequence, "identity": identity.duplicate(true), "shop": record.duplicate(true)}

# This fixed Menu catalogue is independent of route-shop stock and RNG. The
# shell applies these operations to a clone, saves it, then publishes it.
func _store_boundary_error() -> String:
	if not _terminal.is_empty() or _status in ["tower_completed", "defeated", "abandoned", "encounter_won", "invalid"]: return "This run has ended. Store purchases are closed."
	if _route == null or not _route_mode: return "Start a tower run to buy supplies."
	if _preparing or not _prepared.is_empty() or _reward_transaction or _shop_transaction or _service_transaction: return "Finish the current operation before buying supplies."
	if not _pending_result.is_empty() or not pending_reward().is_empty() or _route._status == "pending_choices": return "Review the result and resolve every reward before buying supplies."
	if _status != "route_ready" or _route._status != "route_ready" or not _route._active.is_empty() or _combat != null or not _active_battle.is_empty() or not _entry_checkpoint.is_empty(): return "Buy supplies between rooms, after the current room is complete."
	return ""

func _store_identity() -> Dictionary:
	return {"run_id": _run_id, "checkpoint_signature": JSON.stringify(export_save(), "", true, true).sha256_text()}

func _store_purchased(kind: String) -> bool:
	return _store.transactions.any(func(receipt): return receipt.kind == kind)

func _store_item_error(kind: String, id: String, boundary_error: String) -> String:
	if not boundary_error.is_empty(): return boundary_error
	if kind == "rune" and not id in _shop_eligible(_profile._unlocked if _profile != null else []): return "This rune definition is not unlocked."
	if kind == "relic" and not id in RelicPolicy.ORDER: return "This relic is unavailable."
	if kind == "relic" and id in _relics: return "Already owned in this run."
	if _store_purchased(kind): return "Your one %s purchase for this run is used." % kind
	if kind == "rune" and (_owned_cards.size() >= ContentLoader.MAX_CARDS or _next_uid >= 9223372036854775806): return "This run cannot carry another rune."
	if _gold < (StorePolicy.RUNE_PRICE if kind == "rune" else StorePolicy.RELIC_PRICE): return "Not enough Gold."
	return ""

func store_snapshot() -> Dictionary:
	var error := _store_boundary_error()
	var result := {"identity": _store_identity(), "enabled": error.is_empty(), "error": error, "gold": _gold,
		"rune_purchased": _store_purchased("rune"), "relic_purchased": _store_purchased("relic"),
		"runes": [], "relics": [], "transactions": _store.transactions.duplicate(true)}
	for id in _shop_eligible(_profile._unlocked if _profile != null else []):
		var reason := _store_item_error("rune", id, error)
		var definition: Dictionary = _setup.catalog[id]
		result.runes.append({"definition_id": id, "name": str(definition.get("name", id)), "description": str(definition.get("description", "")), "cost": StorePolicy.RUNE_PRICE, "enabled": reason.is_empty(), "error": reason})
	for id in RelicPolicy.ORDER:
		var reason := _store_item_error("relic", id, error)
		var definition: Dictionary = RelicPolicy.DEFINITIONS[id]
		result.relics.append({"definition_id": id, "name": definition.name, "description": definition.description, "cost": StorePolicy.RELIC_PRICE, "enabled": reason.is_empty(), "error": reason, "owned": id in _relics})
	return result

func purchase_store_rune(identity: Dictionary, definition_id: String) -> Dictionary:
	return _purchase_store(identity, "rune", definition_id)

func purchase_store_relic(identity: Dictionary, definition_id: String) -> Dictionary:
	return _purchase_store(identity, "relic", definition_id)

func _purchase_store(identity: Dictionary, kind: String, definition_id: String) -> Dictionary:
	var error := _store_item_error(kind, definition_id, _store_boundary_error())
	if not error.is_empty(): return _rejected(error)
	if identity != _store_identity(): return _rejected("This Store confirmation is stale. Review the supplies again.")
	var health := {"player_hp": _player_hp, "player_max_hp": _player_max_hp}
	if kind == "relic":
		var acquired := prepare_relic_acquisition(definition_id)
		if not acquired.ok: return acquired
		health = acquired.health
	var cost: int = StorePolicy.RUNE_PRICE if kind == "rune" else StorePolicy.RELIC_PRICE
	var card := {"id": definition_id, "uid": _next_uid, "upgrade_rank": 0} if kind == "rune" else {}
	var receipt := {"transaction_id": _run_id + "/store/" + kind, "kind": kind, "definition_id": definition_id,
		"after_visit_count": _route._visits.size(), "route_revision": _route._revision,
		"eligible_rune_ids": _shop_eligible(_profile._unlocked if _profile != null else []), "eligible_relic_ids": RelicPolicy.eligible_pool(_relics),
		"card": card.duplicate(true), "gold_spent": cost, "entry_gold": _gold, "result_gold": _gold - cost,
		"entry_next_uid": _next_uid, "entry_hp": _player_hp, "entry_max_hp": _player_max_hp,
		"result_hp": health.player_hp, "result_max_hp": health.player_max_hp}
	# Validation is complete and no callbacks occur during this atomic mutation.
	if kind == "rune":
		_owned_cards.append(card.duplicate(true))
		_next_uid += 1
	else: _relics.append(definition_id)
	_gold -= cost
	_player_hp = health.player_hp
	_player_max_hp = health.player_max_hp
	_store.transactions.append(receipt)
	return {"ok": true, "error": "", "transaction_id": receipt.transaction_id, "claim": receipt.duplicate(true),
		"granted_card": card.duplicate(true), "relic_id": definition_id if kind == "relic" else "", "gold_spent": cost, "store": store_snapshot()}

func _validate_store_boundaries() -> String:
	if _store.transactions.is_empty(): return ""
	if _route == null or not _route_mode: return "Standalone saves cannot contain Store purchases."
	var prior := -1
	for receipt in _store.transactions:
		var count: int = receipt.after_visit_count
		if receipt.transaction_id != _run_id + "/store/" + receipt.kind: return "Saved Store transaction belongs to a different run."
		if count < prior or count > _route._visits.size() or count < int(_health_boundary.get("visit_count", 0)): return "Saved Store receipt is outside its chronological boundary."
		var revision := 0
		for index in range(count):
			var visit: Dictionary = _route._visits[index]
			if visit.status != "completed" or visit.outcome != "completed" or not visit.pending_choices.is_empty(): return "Saved Store purchase precedes a settled room."
			if _route._nodes[visit.node_id].room_id == "room_guardian": return "Saved Store purchase follows the final guardian."
			revision += 2 + visit.completed_choices.size()
		if receipt.route_revision != revision: return "Saved Store purchase references a different route revision."
		if count == _route._visits.size() and not _pending_result.is_empty(): return "Saved Store purchase precedes the encounter acknowledgement."
		prior = count
	return ""

func _apply_store_history(count: int, owned: Array, relics: Array, ever: Dictionary, balance: int, allocator: int) -> Dictionary:
	var visits: Array = _route._visits if _route != null else []
	var exact_allocator := _store_allocator_is_exact(count)
	for receipt in _store.transactions:
		if receipt.after_visit_count != count: continue
		var unlocked: Array = _profile._unlocked.duplicate() if _profile != null else []
		for reward in _reward_records.values():
			if reward.kind != "definition_unlock" or reward.resolution != "unlocked": continue
			for index in range(count, visits.size()):
				if visits[index].visit_id == reward.identity.visit_id: unlocked.erase(reward.chosen_id)
		if receipt.eligible_rune_ids != _shop_eligible(unlocked) or receipt.eligible_relic_ids != RelicPolicy.eligible_pool(relics): return _rejected("Saved Store catalogue differs from ownership and unlocks at purchase.")
		var price: int = StorePolicy.RUNE_PRICE if receipt.kind == "rune" else StorePolicy.RELIC_PRICE
		if receipt.gold_spent != price or receipt.entry_gold != balance or balance < price or receipt.result_gold != balance - price: return _rejected("Saved Store spending disagrees with preceding income or its fixed price.")
		if receipt.entry_next_uid < allocator or receipt.entry_next_uid > _next_uid or (exact_allocator and receipt.entry_next_uid != allocator): return _rejected("Saved Store allocation is discontinuous with preceding ownership.")
		if receipt.entry_max_hp != _maximum_for_relics(relics): return _rejected("Saved Store maximum health differs from preceding relic ownership.")
		allocator = receipt.entry_next_uid
		if receipt.kind == "rune":
			if not receipt.definition_id in receipt.eligible_rune_ids or receipt.card != {"id": receipt.definition_id, "uid": allocator, "upgrade_rank": 0}: return _rejected("Saved Store rune differs from its unlocked definition or allocated copy.")
			if ever.has(allocator) or allocator >= _next_uid or owned.size() >= ContentLoader.MAX_CARDS: return _rejected("Saved Store rune reuses a UID or exceeds capacity.")
			owned.append(receipt.card.duplicate(true))
			ever[allocator] = receipt.card.duplicate(true)
			allocator += 1
		else:
			if not receipt.definition_id in receipt.eligible_relic_ids: return _rejected("Saved Store relic is unavailable or already owned.")
			relics.append(receipt.definition_id)
		balance -= price
		exact_allocator = true
	return {"ok": true, "balance": balance, "allocator": allocator}

# Temporary battle cards can legitimately advance the allocator beyond the
# last owned UID. A retained purchase/shop/reward captures a new exact floor;
# crossing only noncombat rooms after that cannot explain another UID gap.
func _store_allocator_is_exact(count: int) -> bool:
	if _route == null: return true
	var anchor := 0
	for receipt in _store.transactions:
		if receipt.after_visit_count < count: anchor = maxi(anchor, receipt.after_visit_count)
	for index in range(count):
		var visit: Dictionary = _route._visits[index]
		if _route._nodes[visit.node_id].room_id == "room_shop": anchor = maxi(anchor, index + 1)
		for reward in _reward_records.values():
			if reward.identity.visit_id == visit.visit_id and reward.resolution == "chosen": anchor = maxi(anchor, index + 1)
	for index in range(anchor, count):
		if not _route._nodes[_route._visits[index].node_id].room_id in ["room_shop", "room_event", "room_recovery"]: return false
	return true

func _apply_store_health(count: int, hp: int, max_hp: int) -> Dictionary:
	for receipt in _store.transactions:
		if receipt.after_visit_count != count: continue
		if hp <= 0 or receipt.entry_hp != hp or receipt.entry_max_hp != max_hp: return _rejected("Saved Store health is discontinuous with the preceding boundary.")
		var health := RelicPolicy.acquire_health(receipt.definition_id, hp, max_hp) if receipt.kind == "relic" else {"player_hp": hp, "player_max_hp": max_hp}
		if receipt.result_hp != health.player_hp or receipt.result_max_hp != health.player_max_hp: return _rejected("Saved Store acquisition health differs from its item hook.")
		hp = health.player_hp
		max_hp = health.player_max_hp
	return {"ok": true, "hp": hp, "max_hp": max_hp}

func cancel_prepared_shop(candidate: Dictionary) -> void:
	if _prepared.get("kind") == "shop" and candidate.get("candidate_id") == _prepared.candidate_id and candidate.get("identity") == _prepared.identity:
		_prepared.clear()

func commit_route_shop(candidate: Dictionary) -> Dictionary:
	if _status != "route_ready" or _prepared.get("kind") != "shop" or candidate.get("candidate_id") != _prepared.get("candidate_id") or candidate.get("identity") != _prepared.get("identity") or candidate.get("shop") != _prepared.get("shop"):
		return _rejected("This shop entry is stale.")
	var accepted := _route.confirm_entry(_prepared.token, func(node, visit):
		return {"ok": node.room_id == "room_shop" and _shop_identity(visit) == _prepared.identity})
	if not accepted.ok: return accepted
	var record: Dictionary = _prepared.shop.duplicate(true)
	_shop_records[_shop_key(record.identity)] = record
	_shop_rng.state = record.rng_after
	_prepared.clear()
	_sync_route_status()
	return {"ok": true, "error": "", "identity": record.identity.duplicate(true), "shop": shop_snapshot()}

func shop_snapshot(identity: Dictionary = {}) -> Dictionary:
	if identity.is_empty():
		if _route == null or _route._active.is_empty(): return {}
		identity = _shop_identity(_route._active)
	var record: Dictionary = _shop_records.get(_shop_key(identity), {})
	if record.get("identity") != identity: return {}
	var result := record.duplicate(true)
	result.gold = _gold
	result.owned_cards = _owned_cards.duplicate(true)
	result.remove_used = record.removal.used
	result.removal_price = record.removal.price
	result.can_remove = record.status == "active" and not record.removal.used and _owned_cards.size() > ShopPolicy.MIN_OWNED
	result.relic_slots = []
	result.upgrade = record.get("upgrade", {"price": ShopPolicy.UPGRADE_PRICE, "used": true, "card": {}}).duplicate(true)
	result.upgrade.targets = eligible_upgrade_targets() if record.version == 2 else []
	result.upgrade.reason = "" if not result.upgrade.used and not result.upgrade.targets.is_empty() else "No eligible upgrade remains for this visit."
	if _gold < result.upgrade.price: result.upgrade.reason = "Not enough Gold."
	result.upgrade.eligible = record.status == "active" and result.upgrade.reason.is_empty()
	result.upgrade.enabled = result.upgrade.eligible
	for id in record.get("relic_offering", {}).get("offered_ids", []):
		var sold: bool = id in _relics
		result.relic_slots.append({"slot_id": "relic-1", "definition_id": id, "price": ShopPolicy.RELIC_PRICE, "sold": sold, "eligible": record.status == "active" and not sold and _gold >= ShopPolicy.RELIC_PRICE, "reason": "Acquired" if sold else "Not enough Gold." if _gold < ShopPolicy.RELIC_PRICE else ""})
	result.relic_available = not result.relic_slots.is_empty()
	result.upgrade_available = record.version == 2 and not result.upgrade.used
	return result

func _shop_request(identity: Dictionary) -> Dictionary:
	if _shop_transaction or _reward_transaction or _service_transaction or _preparing or not _prepared.is_empty() or _status != "room_active" or _route == null or _combat != null or not _active_battle.is_empty() or not _pending_result.is_empty():
		return _rejected("There is no active shop.")
	var record: Dictionary = _shop_records.get(_shop_key(identity), {})
	if identity.size() != 4 or record.get("identity") != identity or record.get("status") != "active" or not record.get("policy_id") in [ShopPolicy.POLICY_ID, ShopPolicy.LEGACY_POLICY_ID]:
		return _rejected("This shop action is no longer available.")
	if _shop_identity(_route._active) != identity or not _route.can_resolve(identity.run_id, identity.node_id, identity.visit_id, "completed"):
		return _rejected("This shop visit is no longer active.")
	return {"ok": true, "record": record.duplicate(true)}

func buy_shop_rune(identity: Dictionary, slot_id: String) -> Dictionary:
	var request := _shop_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	var slot := {}
	for offered in record.slots:
		if offered.slot_id == slot_id: slot = offered
	if slot.is_empty() or slot.sold: return _rejected("This rune is no longer available.")
	if slot.price != ShopPolicy.RUNE_PRICE or not slot.definition_id in record.eligible_ids or not slot.definition_id in _shop_eligible(_profile._unlocked if _profile != null else []):
		return _rejected("This rune is no longer eligible.")
	if _gold < slot.price: return _rejected("Not enough Gold.")
	if _owned_cards.size() >= ContentLoader.MAX_CARDS: return _rejected("Your collection is full.")
	if _next_uid < 8 or _next_uid >= 9223372036854775806 or _owned_cards.any(func(card): return card.uid >= _next_uid): return _rejected("The card allocator is unavailable.")
	var card := {"id": slot.definition_id, "uid": _next_uid, "upgrade_rank": 0}
	var receipt := _shop_receipt(identity, "purchase", slot_id, card, slot.price)
	_shop_transaction = true
	slot.sold = true
	slot.granted_uid = _next_uid
	record.transactions.append(receipt)
	_owned_cards.append(card.duplicate(true))
	_next_uid += 1
	_gold -= int(slot.price)
	_shop_records[_shop_key(identity)] = record
	_shop_transaction = false
	return {"ok": true, "error": "", "granted_card": card.duplicate(true), "gold_spent": slot.price, "transaction_id": receipt.transaction_id, "claim": receipt.duplicate(true), "shop": shop_snapshot(identity)}

func purchase_shop_rune(identity: Dictionary, slot_id: String) -> Dictionary:
	return buy_shop_rune(identity, slot_id)

func remove_shop_rune(identity: Dictionary, uid: int) -> Dictionary:
	var request := _shop_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.removal.used or record.removal.price != ShopPolicy.REMOVAL_PRICE: return _rejected("Removal has already been used here.")
	if _owned_cards.size() <= ShopPolicy.MIN_OWNED: return _rejected("Keep at least four runes.")
	var card := {}
	for owned in _owned_cards:
		if owned.uid == uid: card = owned.duplicate(true)
	if card.is_empty() or not _valid_reward_definition(card.id): return _rejected("That rune is no longer in your collection.")
	if _gold < record.removal.price: return _rejected("Not enough Gold.")
	var receipt := _shop_receipt(identity, "removal", "remove", card, record.removal.price)
	_shop_transaction = true
	record.removal.used = true
	record.removal.removed_card = card.duplicate(true)
	record.transactions.append(receipt)
	_owned_cards.erase(card)
	_gold -= int(record.removal.price)
	_shop_records[_shop_key(identity)] = record
	_shop_transaction = false
	return {"ok": true, "error": "", "removed_card": card, "gold_spent": record.removal.price, "transaction_id": receipt.transaction_id, "claim": receipt.duplicate(true), "shop": shop_snapshot(identity)}

func leave_shop(identity: Dictionary) -> Dictionary:
	var request := _shop_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	_shop_transaction = true
	if not _route.resolve(identity.run_id, identity.node_id, identity.visit_id, "completed"):
		_shop_transaction = false
		return _rejected("This shop visit is no longer active.")
	var receipt := _shop_receipt(identity, "leave", "leave", {}, 0)
	record.status = "left"
	record.transactions.append(receipt)
	_shop_records[_shop_key(identity)] = record
	_sync_route_status()
	_shop_transaction = false
	return {"ok": true, "error": "", "transaction_id": receipt.transaction_id, "claim": receipt}

func _shop_receipt(identity: Dictionary, kind: String, slot_id: String, card: Dictionary, price: int) -> Dictionary:
	return {"transaction_id": _shop_key(identity) + "/" + slot_id, "kind": kind, "slot_id": slot_id, "card": card.duplicate(true), "gold_spent": price}

# Reconstruct resources in visit order from immutable reward and shop receipts.
# Removed starter/reward/purchase instances remain in history, and every UID
# stays spent forever. Temporary Combat allocations are permitted as gaps only.
func prepare_route_service(token: Dictionary) -> Dictionary:
	if _route == null or _status != "route_ready" or _preparing or not _prepared.is_empty() or _combat != null or _service_transaction:
		return _rejected("Resolve the current room first.")
	var preview := _route.preview_entry(token)
	if not preview.ok: return preview
	var definition := ServicePolicy.definition(str(preview.node.get("room_id", "")), str(preview.node.get("room_reference", "")))
	if definition.is_empty(): return _rejected("This room definition is unavailable or malformed.")
	var identity := _shop_identity(preview.visit)
	if _service_records.has(_shop_key(identity)): return _rejected("This room has already been entered.")
	var record := {"version": 2, "identity": identity, "policy_id": ServicePolicy.POLICY_ID,
		"room_id": definition.room_id, "definition_id": definition.id, "status": "active",
		"entry_hp": _player_hp, "entry_max_hp": _player_max_hp, "entry_gold": _gold, "receipt": {},
		"relic_offering": _relic_offering(identity, "service", _relics, 2) if definition.id == "event_sealed_reliquary" else {}}
	_candidate_sequence += 1
	_prepared = {"kind": "service", "candidate_id": _candidate_sequence, "token": token.duplicate(true), "identity": identity.duplicate(true), "record": record}
	return {"ok": true, "error": "", "candidate_id": _candidate_sequence, "identity": identity.duplicate(true), "service": _service_projection(record)}

func cancel_prepared_service(candidate: Dictionary) -> void:
	if _prepared.get("kind") == "service" and candidate.get("candidate_id") is int and candidate.get("identity") is Dictionary and candidate.candidate_id == _prepared.candidate_id and candidate.identity == _prepared.identity: _prepared.clear()

func commit_route_service(candidate: Dictionary) -> Dictionary:
	if not candidate.get("candidate_id") is int or not candidate.get("identity") is Dictionary or not candidate.get("service") is Dictionary: return _rejected("This room entry is malformed.")
	if _status != "route_ready" or _prepared.get("kind") != "service" or candidate.get("candidate_id") != _prepared.get("candidate_id") or candidate.get("identity") != _prepared.get("identity") or candidate.get("service") != _service_projection(_prepared.get("record", {})):
		return _rejected("This room entry is stale.")
	var record: Dictionary = _prepared.record.duplicate(true)
	if record.entry_hp != _player_hp or record.entry_max_hp != _player_max_hp or record.entry_gold != _gold: return _rejected("The run changed before this room could open.")
	var accepted := _route.confirm_entry(_prepared.token, func(node, visit):
		var definition := ServicePolicy.definition(str(node.room_id), str(node.room_reference))
		return {"ok": definition.get("id") == record.definition_id and _shop_identity(visit) == record.identity})
	if not accepted.ok: return accepted
	_service_records[_shop_key(record.identity)] = record
	_prepared.clear()
	_sync_route_status()
	return {"ok": true, "error": "", "identity": record.identity.duplicate(true), "service": service_snapshot()}

func service_snapshot(identity: Dictionary = {}) -> Dictionary:
	if identity.is_empty():
		if _route == null or _route._active.is_empty(): return {}
		identity = _shop_identity(_route._active)
	var record: Dictionary = _service_records.get(_shop_key(identity), {})
	return _service_projection(record) if record.get("identity") == identity else {}

func _service_projection(record: Dictionary) -> Dictionary:
	if record.is_empty(): return {}
	var definition := ServicePolicy.definition(str(record.room_id), "" if record.room_id == "room_recovery" else str(record.definition_id), str(record.policy_id))
	if definition.is_empty(): return {}
	var result := record.duplicate(true)
	result.room_type = "recovery" if record.room_id == "room_recovery" else "event"
	result.title = definition.title
	result.premise = definition.premise
	result.player_hp = _player_hp
	result.player_max_hp = _player_max_hp
	result.gold = _gold
	result.choices = ServicePolicy.choices(definition, _player_hp, _player_max_hp, _gold, RelicPolicy.recovery_amount(_relics, 0))
	result.offered_relics = record.get("relic_offering", {}).get("offered_ids", []).duplicate()
	for choice in result.choices:
		if choice.effect == "upgrade":
			choice.targets = eligible_upgrade_targets()
			if choice.targets.is_empty():
				choice.eligible = false
				choice.reason = "No eligible runes remain."
		if choice.effect == "relic":
			choice.offered_relics = result.offered_relics.duplicate()
			if choice.offered_relics.is_empty():
				choice.eligible = false
				choice.reason = "No unowned relics remain."
	if record.status != "active":
		for choice in result.choices:
			choice.eligible = false
			choice.reason = "This room is complete."
	return result

func resolve_service(identity: Dictionary, choice_id: String, target: Variant = null) -> Dictionary:
	if _service_transaction or _shop_transaction or _reward_transaction or _preparing or not _prepared.is_empty() or _status != "room_active" or _route == null or _combat != null or not _active_battle.is_empty() or not _pending_result.is_empty(): return _rejected("There is no active service room.")
	var key := _shop_key(identity)
	var record: Dictionary = _service_records.get(key, {})
	if identity.size() != 4 or record.get("identity") != identity or record.get("status") != "active" or not record.get("policy_id") in [ServicePolicy.POLICY_ID, ServicePolicy.LEGACY_POLICY_ID] or _shop_identity(_route._active) != identity: return _rejected("This room choice is stale or already resolved.")
	if record.entry_hp != _player_hp or record.entry_max_hp != _player_max_hp or record.entry_gold != _gold: return _rejected("The room resources no longer match their entry.")
	var choice := {}
	for option in _service_projection(record).get("choices", []):
		if option.choice_id == choice_id: choice = option
	if choice.is_empty() or not choice.eligible: return _rejected(str(choice.get("reason", "This choice is unavailable.")))
	if not _route.can_resolve(identity.run_id, identity.node_id, identity.visit_id, "completed"): return _rejected("This room visit is no longer active.")
	var upgrade := {}
	var relic_id := ""
	var health := {"player_hp": _player_hp + choice.hp_delta, "player_max_hp": _player_max_hp}
	if choice.effect == "upgrade":
		if not target is int: return _rejected("Choose one exact owned rune.")
		var card := _owned_card(target)
		if card.is_empty() or not InstanceEffects.eligible(_setup.catalog, card): return _rejected("That rune no longer has an eligible upgrade.")
		upgrade = {"card": card.duplicate(true), "previous_rank": 0, "new_rank": 1}
	elif choice.effect == "relic":
		if not target is String or not target in choice.offered_relics: return _rejected("Choose a retained relic offering.")
		var acquisition := prepare_relic_acquisition(target)
		if not acquisition.ok: return acquisition
		relic_id = target
		health = acquisition.health
	elif target != null: return _rejected("This choice does not accept a target.")
	var receipt := {"transaction_id": key + "/" + str(record.policy_id) + "/" + choice_id,
		"choice_id": choice_id, "hp_delta": health.player_hp - _player_hp, "gold_delta": choice.gold_delta,
		"result_hp": health.player_hp, "result_max_hp": health.player_max_hp, "result_gold": _gold + choice.gold_delta}
	if record.version == 2:
		receipt.upgrade = upgrade
		receipt.relic_id = relic_id
	_service_transaction = true
	if not _route.resolve(identity.run_id, identity.node_id, identity.visit_id, "completed"):
		_service_transaction = false
		return _rejected("The room changed before completion.")
	if not upgrade.is_empty(): _owned_card(target).upgrade_rank = 1
	if not relic_id.is_empty(): _relics.append(relic_id)
	_player_hp = receipt.result_hp
	_player_max_hp = receipt.result_max_hp
	_gold = receipt.result_gold
	record.status = "resolved"
	record.receipt = receipt
	_service_records[key] = record
	_sync_route_status()
	_service_transaction = false
	return {"ok": true, "error": "", "record": record.duplicate(true), "receipt": receipt.duplicate(true), "hp_delta": receipt.hp_delta, "gold_delta": receipt.gold_delta}

func _validate_service_record(record: Dictionary, visit: Dictionary, balance: int, owned: Array, relics: Array) -> String:
	var modern: bool = record.get("version") is int and record.version == 2
	if record.size() != (11 if modern else 10): return "Saved service record structure is invalid."
	var node: Dictionary = _route._nodes[visit.node_id]
	var expected_policy := ServicePolicy.POLICY_ID if modern else ServicePolicy.LEGACY_POLICY_ID
	var definition := ServicePolicy.definition(str(node.room_id), str(node.room_reference), expected_policy)
	if definition.is_empty(): return "Saved service definition is unavailable or malformed."
	var identity := _shop_identity(visit)
	for field in ["policy_id", "room_id", "definition_id", "status"]:
		if not record.get(field) is String: return "Saved service metadata must be text."
	if record.get("identity") != identity or not record.get("version") is int or record.version != (2 if modern else 1) or record.policy_id != expected_policy or record.room_id != node.room_id or record.definition_id != definition.id: return "Saved service identity or registered policy is invalid."
	for field in ["entry_hp", "entry_max_hp", "entry_gold"]:
		if not record.get(field) is int: return "Saved service resources must be exact integers."
	if record.entry_hp <= 0 or record.entry_hp > record.entry_max_hp or record.entry_max_hp != _maximum_for_relics(relics) or record.entry_gold != balance: return "Saved service entry resources disagree with their history."
	if modern:
		var expected_offering := _relic_offering(identity, "service", relics, 2) if definition.id == "event_sealed_reliquary" else {}
		if not record.get("relic_offering") is Dictionary or record.relic_offering != expected_offering: return "Saved service relic offering differs from its retained random policy."
	if not record.get("receipt") is Dictionary or not record.status in ["active", "resolved"]: return "Saved service resolution is malformed."
	if not (visit.pending_choices + visit.completed_choices).is_empty() or visit.outcome == "defeat": return "Saved service has unsupported route choices or outcome."
	if (record.status == "resolved") != (visit.status == "completed") or (record.status == "active" and (visit.status != "active" or _shop_identity(_route._active) != identity)): return "Saved service completion disagrees with its visit."
	if record.status == "active": return "" if record.receipt.is_empty() else "An unresolved service contains a benefit receipt."
	var receipt: Dictionary = record.receipt
	if receipt.size() != (9 if modern else 7) or not receipt.get("choice_id") is String or not receipt.get("transaction_id") is String: return "Saved service receipt structure is invalid."
	for field in ["hp_delta", "gold_delta", "result_hp", "result_max_hp", "result_gold"]:
		if not receipt.get(field) is int: return "Saved service receipt resources must be exact integers."
	var choice := {}
	for option in ServicePolicy.choices(definition, record.entry_hp, record.entry_max_hp, record.entry_gold, RelicPolicy.recovery_amount(relics, 0)):
		if option.choice_id == receipt.choice_id: choice = option
	if choice.is_empty() or not choice.eligible: return "Saved service choice was unavailable at entry."
	var expected_health := {"player_hp": record.entry_hp + choice.hp_delta, "player_max_hp": record.entry_max_hp}
	if modern:
		if not receipt.get("upgrade") is Dictionary or not receipt.get("relic_id") is String: return "Saved service item receipt is malformed."
		if choice.effect == "upgrade":
			var error := _apply_historical_upgrade(receipt.upgrade, owned)
			if not error.is_empty(): return error
		elif not receipt.upgrade.is_empty(): return "A non-upgrade service contains an upgrade."
		if choice.effect == "relic":
			if not receipt.relic_id in record.relic_offering.offered_ids or receipt.relic_id in relics: return "Saved service relic was unavailable at acquisition."
			expected_health = RelicPolicy.acquire_health(receipt.relic_id, record.entry_hp, record.entry_max_hp)
			relics.append(receipt.relic_id)
		elif not receipt.relic_id.is_empty(): return "A non-relic service contains an acquisition."
	if receipt.transaction_id != _shop_key(identity) + "/" + expected_policy + "/" + receipt.choice_id or receipt.hp_delta != expected_health.player_hp - record.entry_hp or receipt.gold_delta != choice.gold_delta: return "Saved service receipt differs from its registered choice."
	if receipt.result_hp != expected_health.player_hp or receipt.result_max_hp != expected_health.player_max_hp or receipt.result_gold != balance + choice.gold_delta or receipt.result_hp <= 0: return "Saved service outcome violates capped healing, nonlethal costs or resource continuity."
	return ""

func _standalone_health_identity() -> Dictionary:
	return {"run_id": _run_id, "route_id": "", "node_id": "fixture_shadeling", "visit_id": "standalone"}

func _record_battle_health_entry(identity: Dictionary) -> void:
	_battle_health_records[_shop_key(identity)] = {"identity": identity.duplicate(true), "entry_hp": _player_hp, "player_max_hp": _player_max_hp, "result_hp": -1, "outcome": ""}

func _establish_legacy_health_boundary(version: int) -> void:
	var count: int = _route._visits.size() if _route != null else (1 if _status in ["encounter_won", "defeated"] else 0)
	if _status == "replay_pending" and _route != null: count -= 1
	_health_boundary = {"source_version": version, "visit_count": count, "player_hp": _player_hp, "player_max_hp": _player_max_hp}
	if _status == "replay_pending": _record_battle_health_entry(_shop_identity(_active_battle) if _route_mode else _standalone_health_identity())

func _validate_health_history() -> String:
	if _health_boundary.size() != 4: return "Saved health boundary is malformed."
	for field in ["source_version", "visit_count", "player_hp", "player_max_hp"]:
		if not _health_boundary.get(field) is int: return "Saved health boundary must use exact integers."
	if not _health_boundary.source_version in [0, 1, 2] or _health_boundary.visit_count < 0 or _health_boundary.player_max_hp != 30 or _health_boundary.player_hp < 0 or _health_boundary.player_hp > 30: return "Saved health boundary is unsupported."
	if _health_boundary.source_version == 0 and (_health_boundary.visit_count != 0 or _health_boundary.player_hp != 30): return "A new run must start with its authoritative starter health."
	var hp: int = _health_boundary.player_hp
	var max_hp: int = _health_boundary.player_max_hp
	var seen := {}
	var visits: Array = _route._visits if _route != null else []
	if _route == null:
		if not _service_records.is_empty(): return "Standalone saves cannot contain service visits."
		if _health_boundary.visit_count > 1: return "Standalone health boundary exceeds its encounter."
		if _health_boundary.visit_count == 0 and (_status != "ready" or not _battle_health_records.is_empty()):
			var identity := _standalone_health_identity()
			var record: Dictionary = _battle_health_records.get(_shop_key(identity), {})
			var error := _validate_battle_health_record(record, identity, hp, max_hp, _status == "replay_pending", "defeat" if _status == "defeated" else "victory")
			if not error.is_empty(): return error
			hp = record.entry_hp if record.outcome.is_empty() else record.result_hp
			seen[_shop_key(identity)] = true
	else:
		if _health_boundary.visit_count > visits.size(): return "Saved health boundary exceeds its route history."
		for index in range(visits.size()):
			var visit: Dictionary = visits[index]
			var node: Dictionary = _route._nodes[visit.node_id]
			var identity := _shop_identity(visit)
			var key := _shop_key(identity)
			if index < _health_boundary.visit_count:
				if node.room_id in ["room_event", "room_recovery"] or _battle_health_records.has(key): return "A legacy health boundary cannot conceal new service or battle records."
				if _shop_records.get(key, {}).get("version", 1) != 1: return "A legacy health boundary cannot conceal new item shops."
				continue
			var store_health := _apply_store_health(index, hp, max_hp)
			if not store_health.ok: return store_health.error
			hp = store_health.hp
			max_hp = store_health.max_hp
			if node.room_id in ["room_event", "room_recovery"]:
				var service: Dictionary = _service_records.get(key, {})
				if service.get("entry_hp") != hp or service.get("entry_max_hp") != max_hp: return "Saved service health is discontinuous with the preceding boundary."
				if service.status == "resolved":
					hp = service.receipt.result_hp
					max_hp = service.receipt.result_max_hp
			elif node.room_id == "room_shop":
				for receipt in _shop_records.get(key, {}).get("transactions", []):
					if receipt.kind != "relic": continue
					if receipt.entry_hp != hp or receipt.entry_max_hp != max_hp: return "Saved shop acquisition health is discontinuous."
					var expected := RelicPolicy.acquire_health(receipt.relic_id, hp, max_hp)
					if receipt.result_hp != expected.player_hp or receipt.result_max_hp != expected.player_max_hp: return "Saved relic acquisition health differs from its hook."
					hp = expected.player_hp
					max_hp = expected.player_max_hp
			else:
				var record: Dictionary = _battle_health_records.get(key, {})
				var error := _validate_battle_health_record(record, identity, hp, max_hp, visit.status == "active", "defeat" if visit.outcome == "defeat" else "victory")
				if not error.is_empty(): return error
				seen[key] = true
				if not record.outcome.is_empty(): hp = record.result_hp
	var final_store_health := _apply_store_health(visits.size(), hp, max_hp)
	if not final_store_health.ok: return final_store_health.error
	hp = final_store_health.hp
	max_hp = final_store_health.max_hp
	if seen.size() != _battle_health_records.size(): return "Saved battle health has no matching post-boundary encounter."
	if hp != _player_hp or max_hp != _player_max_hp: return "Saved current health differs from its authoritative history."
	return ""

func _validate_battle_health_record(record: Dictionary, identity: Dictionary, hp: int, max_hp: int, active: bool, outcome: String) -> String:
	if record.size() != 5 or record.get("identity") != identity or not record.get("outcome") is String: return "Saved battle health boundary is missing or malformed."
	for field in ["entry_hp", "player_max_hp", "result_hp"]:
		if not record.get(field) is int: return "Saved battle health must use exact integers."
	if record.entry_hp != hp or hp <= 0 or record.player_max_hp != max_hp: return "Saved battle entry health is discontinuous."
	if active:
		if record.result_hp != -1 or record.outcome != "" or _entry_checkpoint.get("player_hp") != hp or _entry_checkpoint.get("player_max_hp") != record.player_max_hp: return "Saved active battle health differs from its replay checkpoint."
	else:
		if record.outcome != outcome or record.result_hp < 0 or record.result_hp > record.entry_hp or (record.result_hp == 0) != (outcome == "defeat"): return "Saved battle result health or outcome is invalid."
	return ""

func _validate_shop_history() -> String:
	var owned: Array = []
	var relics: Array = []
	var ever := {}
	var starter := ["spark", "shield", "conjure", "spark", "shield", "focus", "focus", "conjure"]
	for index in range(starter.size()):
		var card := {"id": starter[index], "uid": index, "upgrade_rank": 0}
		owned.append(card)
		ever[index] = card
	var balance := 0
	var allocator_floor := 8
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed ^ ShopPolicy.RNG_SALT
	var visited_shops := 0
	var visited_services := 0
	var transaction_ids := {}
	var visits: Array = _route._visits if _route != null else []
	for visit_index in range(visits.size()):
		var store_history := _apply_store_history(visit_index, owned, relics, ever, balance, allocator_floor)
		if not store_history.ok: return store_history.error
		balance = store_history.balance
		allocator_floor = store_history.allocator
		var visit: Dictionary = visits[visit_index]
		var identity := _shop_identity(visit)
		var key := _shop_key(identity)
		var node: Dictionary = _route._nodes[visit.node_id]
		if node.room_id in ["room_event", "room_recovery"]:
			visited_services += 1
			var service: Dictionary = _service_records.get(key, {})
			var service_error := _validate_service_record(service, visit, balance, owned, relics)
			if not service_error.is_empty(): return service_error
			if service.status == "resolved": balance = service.receipt.result_gold
		elif _service_records.has(key): return "Saved service is attached to a different room type."
		if _route._nodes[visit.node_id].room_id != "room_shop":
			if _shop_records.has(key): return "Saved shop is attached to a different room type."
			for reward in _reward_records.values():
				if reward.identity.visit_id != visit.visit_id: continue
				if reward.resolution == "chosen":
					var card := {"id": reward.chosen_id, "uid": reward.granted_uid, "upgrade_rank": 0}
					if ever.has(card.uid) or card.uid < allocator_floor or card.uid >= _next_uid or owned.size() >= ContentLoader.MAX_CARDS: return "Saved reward acquisition violates ownership chronology or capacity."
					owned.append(card)
					ever[card.uid] = card
					allocator_floor = card.uid + 1
				if reward.gold_claimed: balance += int(reward.gold_amount)
			continue
		visited_shops += 1
		var record: Dictionary = _shop_records.get(key, {})
		var modern: bool = record.get("version") is int and record.version == 2
		if record.size() != (14 if modern else 12): return "Saved shop record structure is invalid."
		if modern and (not record.get("relic_offering") is Dictionary or not record.get("upgrade") is Dictionary): return "Saved shop item offerings or upgrade allowance are malformed."
		if record.get("identity") != identity or not record.get("version") is int or record.version != (2 if modern else 1) or not record.get("policy_id") is String or record.policy_id != (ShopPolicy.POLICY_ID if modern else ShopPolicy.LEGACY_POLICY_ID) or not record.get("eligibility_version") is int or record.eligibility_version != ShopPolicy.ELIGIBILITY_VERSION: return "Saved shop identity or policy is invalid."
		for field in ["rng_before", "rng_after", "entry_next_uid"]:
			if not record.get(field) is int: return "Saved shop counters must use exact integers."
		for field in ["eligible_ids", "slots", "transactions"]:
			if not record.get(field) is Array: return "Saved shop offerings or receipts are malformed."
		if not record.get("removal") is Dictionary or record.removal.size() != 3 or not record.removal.get("price") is int or not record.removal.get("used") is bool or not record.removal.get("removed_card") is Dictionary: return "Saved removal service is malformed."
		if not record.get("status") is String or not record.status in ["active", "left"] or record.transactions.size() > ShopPolicy.STOCK_COUNT + (4 if modern else 2): return "Saved shop status or transaction count is invalid."
		if not (visit.pending_choices + visit.completed_choices).is_empty() or visit.outcome == "defeat": return "Saved shop has unsupported room choices or outcome."
		if (record.status == "left") != (visit.status == "completed") or (record.status == "active" and (visit.status != "active" or _shop_identity(_route._active) != identity)): return "Saved shop completion disagrees with its route visit."
		var unlocked: Array = _profile._unlocked.duplicate() if _profile != null else []
		for reward in _reward_records.values():
			if reward.kind != "definition_unlock" or reward.resolution != "unlocked": continue
			for later in range(visit_index, visits.size()):
				if visits[later].visit_id == reward.identity.visit_id: unlocked.erase(reward.chosen_id)
		var eligible := _shop_eligible(unlocked)
		if record.eligible_ids != eligible: return "Saved shop eligibility differs from the profile at entry."
		if record.rng_before != rng.state: return "Saved shop random stream chain is inconsistent."
		var offered := ShopPolicy.offerings(eligible, rng)
		if record.rng_after != rng.state or record.slots.size() != offered.size(): return "Saved shop stock differs from its deterministic offering."
		var expected_slots: Array = []
		for id in offered:
			expected_slots.append({"slot_id": "rune-%d" % (expected_slots.size() + 1), "definition_id": id, "price": ShopPolicy.RUNE_PRICE, "sold": false, "granted_uid": -1})
		for slot in record.slots:
			if not slot is Dictionary or slot.size() != 5 or not slot.get("price") is int or not slot.get("sold") is bool or not slot.get("granted_uid") is int: return "Saved shop slot structure is invalid."
		if record.entry_next_uid < allocator_floor or record.entry_next_uid > _next_uid: return "Saved shop entry allocator is inconsistent with acquisition history."
		if _store.transactions.any(func(receipt): return receipt.after_visit_count <= visit_index) and (_store_allocator_is_exact(visit_index) or _store.transactions.any(func(receipt): return receipt.after_visit_count == visit_index)) and record.entry_next_uid != allocator_floor: return "Saved shop allocator differs from the preceding Store purchase."
		if visit_index > 0 and _route._nodes[visits[visit_index - 1].node_id].room_id == "room_shop" and record.entry_next_uid != allocator_floor: return "Saved consecutive shops contain an unexplained allocator gap."
		allocator_floor = record.entry_next_uid
		var removal := {"price": ShopPolicy.REMOVAL_PRICE, "used": false, "removed_card": {}}
		var upgrade := {"price": ShopPolicy.UPGRADE_PRICE, "used": false, "card": {}}
		if modern and record.get("relic_offering") != _relic_offering(identity, "shop", relics, 1): return "Saved shop relic offering differs from its retained random policy."
		var left := false
		for receipt in record.transactions:
			if not receipt is Dictionary or not receipt.get("card") is Dictionary or not receipt.get("gold_spent") is int: return "Saved shop receipt structure is invalid."
			for field in ["transaction_id", "kind", "slot_id"]:
				if not receipt.get(field) is String: return "Saved shop receipt identity is malformed."
			var receipt_size := 7 if receipt.kind == "upgrade" else 10 if receipt.kind == "relic" else 5
			if receipt.size() != receipt_size or (not modern and receipt_size != 5): return "Saved shop receipt structure is invalid."
			if left or receipt.transaction_id != key + "/" + receipt.slot_id or transaction_ids.has(receipt.transaction_id): return "Saved shop receipt is duplicated, stale or after Leave."
			transaction_ids[receipt.transaction_id] = true
			if not receipt.card.is_empty() and (receipt.card.size() != 3 or not receipt.card.get("id") is String or not receipt.card.get("uid") is int or not receipt.card.get("upgrade_rank") is int or not receipt.card.upgrade_rank in [0, 1]): return "Saved shop receipt card identity is malformed."
			if receipt.kind == "purchase":
				var slot := {}
				for candidate in expected_slots:
					if candidate.slot_id == receipt.slot_id: slot = candidate
				if slot.is_empty() or slot.sold or receipt.gold_spent != ShopPolicy.RUNE_PRICE or receipt.card != {"id": slot.definition_id, "uid": allocator_floor, "upgrade_rank": 0}: return "Saved purchase differs from its offered slot, price or allocated instance."
				if ever.has(allocator_floor) or allocator_floor >= _next_uid or owned.size() >= ContentLoader.MAX_CARDS: return "Saved purchase violates ownership capacity or reuses a UID."
				slot.sold = true
				slot.granted_uid = allocator_floor
				owned.append(receipt.card.duplicate(true))
				ever[allocator_floor] = receipt.card.duplicate(true)
				allocator_floor += 1
			elif receipt.kind == "removal":
				if receipt.slot_id != "remove" or removal.used or receipt.gold_spent != ShopPolicy.REMOVAL_PRICE or not receipt.card in owned or owned.size() <= ShopPolicy.MIN_OWNED: return "Saved removal violates exact ownership, price or its service allowance."
				removal.used = true
				removal.removed_card = receipt.card.duplicate(true)
				owned.erase(receipt.card)
			elif receipt.kind == "upgrade":
				if receipt.slot_id != "upgrade" or upgrade.used or receipt.gold_spent != ShopPolicy.UPGRADE_PRICE: return "Saved upgrade violates its price or visit allowance."
				var error := _apply_historical_upgrade({"card": receipt.card, "previous_rank": receipt.get("previous_rank"), "new_rank": receipt.get("new_rank")}, owned)
				if not error.is_empty(): return error
				upgrade.used = true
				upgrade.card = receipt.card.duplicate(true)
			elif receipt.kind == "relic":
				if receipt.slot_id != "relic-1" or receipt.gold_spent != ShopPolicy.RELIC_PRICE or not receipt.card.is_empty() or not receipt.get("relic_id") is String or not receipt.relic_id in record.relic_offering.offered_ids or receipt.relic_id in relics: return "Saved relic violates unique ownership, stock or price."
				for field in ["entry_hp", "entry_max_hp", "result_hp", "result_max_hp"]:
					if not receipt.get(field) is int: return "Saved relic health must use exact integers."
				relics.append(receipt.relic_id)
			elif receipt.kind == "leave":
				if receipt.slot_id != "leave" or receipt.gold_spent != 0 or not receipt.card.is_empty(): return "Saved Leave receipt is invalid."
				left = true
			else: return "Saved shop service is unsupported."
			if receipt.gold_spent < 0 or balance < receipt.gold_spent: return "Saved shop spending precedes sufficient configured income."
			balance -= int(receipt.gold_spent)
		if record.slots != expected_slots or record.removal != removal or (modern and record.get("upgrade") != upgrade) or left != (record.status == "left"): return "Saved stock or service usage disagrees with committed transactions."
	var final_store := _apply_store_history(visits.size(), owned, relics, ever, balance, allocator_floor)
	if not final_store.ok: return final_store.error
	balance = final_store.balance
	allocator_floor = final_store.allocator
	if not _store.transactions.is_empty() and (_store_allocator_is_exact(visits.size()) or _store.transactions.back().after_visit_count == visits.size()) and _next_uid != allocator_floor: return "Saved allocator differs from its final Store purchase."
	if visited_shops != _shop_records.size(): return "Saved shop has no matching route visit."
	if visited_services != _service_records.size(): return "Saved service has no matching route visit."
	if _shop_rng.state != rng.state: return "Saved shop random stream disagrees with retained stock."
	if _next_uid < allocator_floor: return "Saved allocator would recycle an acquired instance."
	if not visits.is_empty() and _route._nodes[visits.back().node_id].room_id == "room_shop" and _next_uid != allocator_floor: return "Saved shop allocator disagrees with its committed purchases."
	if owned != _owned_cards: return "Saved ownership disagrees with starter, acquisitions, upgrades and removals."
	if relics != _relics: return "Saved relic ownership disagrees with chronological acquisitions."
	if balance != _gold: return "Saved Gold disagrees with income minus committed spending."
	return ""

# A pure acquisition seam for later reward policies. Callers must retain the
# resulting grant in an authoritative room/reward receipt before publication.
func prepare_relic_acquisition(relic_id: String) -> Dictionary:
	if not _terminal.is_empty(): return _rejected("A finished run cannot acquire relics.")
	if _combat != null or not _active_battle.is_empty() or _status in ["battle", "replay_pending"]: return _rejected("Relics can only be acquired outside combat.")
	if not relic_id in RelicPolicy.eligible_pool(_relics): return _rejected("This relic is unavailable or already owned.")
	if _player_hp <= 0: return _rejected("A defeated run cannot acquire relics.")
	return {"ok": true, "error": "", "relic_id": relic_id, "health": RelicPolicy.acquire_health(relic_id, _player_hp, _player_max_hp)}

static func _maximum_for_relics(relics: Array) -> int:
	return int(RelicPolicy.acquire_health("relic_heart_stone", 30, 30).player_max_hp) if "relic_heart_stone" in relics else 30

func eligible_upgrade_targets() -> Array:
	return _owned_cards.filter(func(card): return InstanceEffects.eligible(_setup.catalog, card)).duplicate(true)

func _owned_card(uid: int) -> Dictionary:
	for card in _owned_cards:
		if card.uid == uid: return card
	return {}

# Separate, explicitly versioned per-visit stream. It consumes none of the
# established route, cards, endpoints, kits, reward or rune-stock randomness.
func _relic_offering(identity: Dictionary, source: String, relics: Array, count: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	var material := "%s|%d|%s|%s|%s" % [RelicPolicy.OFFER_RANDOM_VERSION, _seed, identity.get("node_id", ""), str(identity.get("visit_id", "")).get_slice("/visit-", 1), source]
	rng.seed = material.sha256_text().left(15).hex_to_int()
	var before := rng.state
	var offered := RelicPolicy.offer(relics, count, rng)
	return {"version": RelicPolicy.OFFER_RANDOM_VERSION, "eligible_ids": RelicPolicy.eligible_pool(relics), "offered_ids": offered, "rng_before": before, "rng_after": rng.state}

func upgrade_shop_rune(identity: Dictionary, uid: int) -> Dictionary:
	var request := _shop_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.version != 2 or record.upgrade.used: return _rejected("No upgrade remains for this visit.")
	var card := _owned_card(uid)
	if card.is_empty() or not InstanceEffects.eligible(_setup.catalog, card): return _rejected("That exact rune has no eligible upgrade.")
	if _gold < ShopPolicy.UPGRADE_PRICE: return _rejected("Not enough Gold.")
	var receipt := _shop_receipt(identity, "upgrade", "upgrade", card, ShopPolicy.UPGRADE_PRICE)
	receipt.previous_rank = 0
	receipt.new_rank = 1
	_shop_transaction = true
	record.upgrade.used = true
	record.upgrade.card = card.duplicate(true)
	record.transactions.append(receipt)
	card.upgrade_rank = 1
	_gold -= ShopPolicy.UPGRADE_PRICE
	_shop_records[_shop_key(identity)] = record
	_shop_transaction = false
	return {"ok": true, "error": "", "upgraded_card": card.duplicate(true), "gold_spent": ShopPolicy.UPGRADE_PRICE, "claim": receipt.duplicate(true), "transaction_id": receipt.transaction_id, "shop": shop_snapshot(identity)}

func buy_shop_relic(identity: Dictionary, slot_id: String = "relic-1") -> Dictionary:
	var request := _shop_request(identity)
	if not request.ok: return request
	var record: Dictionary = request.record
	if record.version != 2 or slot_id != "relic-1" or record.relic_offering.offered_ids.is_empty(): return _rejected("This relic slot is unavailable.")
	var relic_id: String = record.relic_offering.offered_ids[0]
	var acquired := prepare_relic_acquisition(relic_id)
	if not acquired.ok: return acquired
	if _gold < ShopPolicy.RELIC_PRICE: return _rejected("Not enough Gold.")
	var receipt := _shop_receipt(identity, "relic", slot_id, {}, ShopPolicy.RELIC_PRICE)
	receipt.merge({"relic_id": relic_id, "entry_hp": _player_hp, "entry_max_hp": _player_max_hp, "result_hp": acquired.health.player_hp, "result_max_hp": acquired.health.player_max_hp})
	_shop_transaction = true
	_relics.append(relic_id)
	_player_hp = acquired.health.player_hp
	_player_max_hp = acquired.health.player_max_hp
	_gold -= ShopPolicy.RELIC_PRICE
	record.transactions.append(receipt)
	_shop_records[_shop_key(identity)] = record
	_shop_transaction = false
	return {"ok": true, "error": "", "relic_id": relic_id, "gold_spent": ShopPolicy.RELIC_PRICE, "claim": receipt.duplicate(true), "transaction_id": receipt.transaction_id, "shop": shop_snapshot(identity)}

func _apply_historical_upgrade(receipt: Dictionary, owned: Array) -> String:
	if receipt.size() != 3 or not receipt.get("card") is Dictionary or not receipt.get("previous_rank") is int or not receipt.get("new_rank") is int or receipt.previous_rank != 0 or receipt.new_rank != 1: return "Saved upgrade receipt has invalid ranks."
	if not receipt.card in owned or not InstanceEffects.eligible(_setup.catalog, receipt.card): return "Saved upgrade target was unavailable at its acquisition position."
	owned[owned.find(receipt.card)].upgrade_rank = 1
	return ""

func _normalize_legacy_cards() -> String:
	var groups: Array = [_owned_cards]
	if not _entry_checkpoint.is_empty():
		groups.append(_entry_checkpoint.get("owned_cards", []))
		if _entry_checkpoint.has("relics"): return "Legacy battle checkpoint contains unsupported relics."
		_entry_checkpoint.relics = []
	for reward in _reward_records.values():
		for claim in reward.get("claims", []):
			if claim is Dictionary and claim.get("card") is Dictionary and not claim.card.is_empty(): groups.append([claim.card])
	for shop in _shop_records.values():
		if shop.get("version") != 1 or shop.get("policy_id") != ShopPolicy.LEGACY_POLICY_ID: return "Legacy shop policy is unsupported."
		for receipt in shop.get("transactions", []):
			if receipt is Dictionary and receipt.get("card") is Dictionary and not receipt.card.is_empty(): groups.append([receipt.card])
		if shop.get("removal") is Dictionary and shop.removal.get("removed_card") is Dictionary and not shop.removal.removed_card.is_empty(): groups.append([shop.removal.removed_card])
	for service in _service_records.values():
		if service.get("version") != 1 or service.get("policy_id") != ServicePolicy.LEGACY_POLICY_ID: return "Legacy service policy is unsupported."
	for cards in groups:
		for card in cards:
			if not card is Dictionary or card.size() != 2 or not card.get("id") is String or not card.get("uid") is int: return "Legacy card instance structure is malformed."
			card.upgrade_rank = 0
	return ""
