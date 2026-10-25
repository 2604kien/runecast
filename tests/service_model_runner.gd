extends SceneTree
## Exact policy boundaries plus genuine battle/service histories and hostile saves.
const Fixture = preload("res://tests/helpers/service_route_fixture.gd")
const Run = preload("res://scripts/core/run_state.gd")
const Policy = preload("res://scripts/core/service_policy.gd")
const Loader = preload("res://scripts/core/content_loader.gd")
const Profile = preload("res://scripts/core/progression_state.gd")
const DESTINATION := "res://output/qa/rc-030/model"
var checks := 0
var failures := 0
var assertions: Array = []
var setup: Dictionary

func check(condition: bool, message: String) -> void:
	checks += 1
	assertions.append({"pass": condition, "description": message})
	if not condition:
		failures += 1
		push_error(message)

func restore(subject, data: Dictionary = {}) -> Dictionary:
	return Run.restore_save(subject.export_save() if data.is_empty() else data, setup, subject.profile_state().clone_for_transaction(), Fixture.context_for(subject))

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	setup = Loader.load_setup().setup
	_policy()
	_full_health()
	_tithe_boundaries()
	for variant in ["recovery", "satchel", "tithe", "reliquary", "desk"]: _room(variant)
	_unknown()
	_future_income()
	FileAccess.open(DESTINATION.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "assertions": assertions}, "  ") + "\n")
	print("RC-030 service models: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _policy() -> void:
	var recovery: Dictionary = Policy.definition("room_recovery")
	check(Policy.validate_definition(recovery).is_empty(), "Registered recovery definition validates.")
	for hp in [1, 8, 9, 20, 25, 29, 30]:
		var choice: Dictionary = Policy.choices(recovery, hp, 30, 0)[0]
		check(choice.hp_delta == mini(10, 30 - hp) and choice.gold_delta == 0 and choice.eligible == (hp < 30), "Recovery policy previews exactly capped gain at %d HP." % hp)
	var tithe: Dictionary = Policy.definition("room_event", "event_blood_tithe")
	for hp in [1, 8, 9, 30]:
		var choice: Dictionary = Policy.choices(tithe, hp, 30, 0)[0]
		check(choice.hp_delta == -8 and choice.gold_delta == 40 and choice.eligible == (hp > 8), "Tithe policy rejects <=8 HP and leaves one HP at 9; input %d." % hp)
	var invalid: Array = []
	var data := recovery.duplicate(true)
	data.choices.pop_back()
	invalid.append(data)
	data = recovery.duplicate(true)
	data.choices[0].effect = "script"
	invalid.append(data)
	data = recovery.duplicate(true)
	data.choices[0].gold = -9223372036854775807 - 1
	invalid.append(data)
	data = recovery.duplicate(true)
	data.choices[0].amount = 10.0
	invalid.append(data)
	data = recovery.duplicate(true)
	data.choices[1].choice_id = data.choices[0].choice_id
	invalid.append(data)
	data = recovery.duplicate(true)
	data.id = "unknown"
	invalid.append(data)
	data = recovery.duplicate(true)
	data.choices[-1].gold = 1
	invalid.append(data)
	for malformed in invalid: check(not Policy.validate_definition(malformed).is_empty() and Policy.choices(malformed, 20, 30, 0).is_empty(), "Malformed declarative policy rejects before preparation or effect evaluation.")
	check(Policy.definition("room_event", "unknown").is_empty() and Policy.definition("room_recovery", "event_lost_satchel").is_empty(), "Unknown event and mismatched recovery reference cannot dispatch.")

func _full_health() -> void:
	# A separate authored first-room fixture exercises full HP without inventing
	# a previous victory, health change or persisted legacy record.
	var subject = Fixture.new_run()
	for node in subject._route._graph.nodes:
		if node.depth == 1: subject._route._service(node, "recovery", "")
	var token: Dictionary = subject.request_room_entry("d1a").token
	check(not subject.confirm_room_entry(token, func(_node, _visit): return {"ok": true}).ok, "Generic entry cannot bypass recovery preparation.")
	var entry: Dictionary = Fixture.enter_service(subject, "d1a")
	check(entry.ok, "Authored first recovery enters at unchanged starter 30/30.")
	var snapshot: Dictionary = subject.service_snapshot()
	var original: Dictionary = subject.export_save()
	check(not snapshot.choices[0].eligible and snapshot.choices[0].hp_delta == 0 and not subject.resolve_service(snapshot.identity, "recover").ok and subject.export_save() == original, "Full health rejects recovery with no record, route or resource change.")
	check(not subject.resolve_service(snapshot.identity, "refine_rune").ok and subject.export_save() == original, "Unavailable upgrade cannot consume a full-health visit.")
	check(subject.resolve_service(snapshot.identity, "leave").ok and subject.snapshot().player_hp == 30 and restore(subject).ok, "Explicit free Leave remains usable and round-trips the full-health room.")

func _room(variant: String) -> void:
	var subject = Fixture.new_run(42, variant)
	check(Fixture.win_battle(subject).ok, "Actual supported battle earns %s room access and carries its damage." % variant)
	var before: Dictionary = subject.export_save()
	var node_id: String = Fixture.next_node(subject)
	var token: Dictionary = subject.request_room_entry(node_id).token
	var candidate: Dictionary = subject.prepare_route_service(token)
	check(candidate.ok and subject.route_snapshot().visit_count == before.route.visits.size(), "Service preparation validates without consuming a visit.")
	var preview: Dictionary = candidate.service
	subject.cancel_prepared_service(candidate)
	check(not subject.commit_route_service(candidate).ok and subject.route_snapshot().visit_count == before.route.visits.size(), "Canceled service attachment leaves the visit unconsumed.")
	candidate = subject.prepare_route_service(token)
	check(candidate.service == preview, "Preparing again retains selected event identity and exact outcomes.")
	check(subject.commit_route_service(candidate).ok, "Prepared %s screen can durably stage room entry." % variant)
	var service: Dictionary = subject.service_snapshot()
	var initial: Dictionary = subject.export_save()
	check(service.definition_id == ("recovery" if variant == "recovery" else Fixture.VARIANTS[variant]), "Dispatch uses the retained route-assigned event ID.")
	check(subject._player_hp == before.player_hp and subject._player_max_hp == before.player_max_hp and subject._owned_cards == before.owned_cards and subject._next_uid == before.next_uid, "Room entry preserves authoritative health, ownership and allocator.")
	for field in ["rng_states", "reward_rng_state", "shop_rng_state"]: check(initial[field] == before[field], "Service entry preserves %s." % field)
	check(initial.route.graph.route_rng_state == before.route.graph.route_rng_state, "Event entry never samples the retained route stream.")
	var restarted: Dictionary = restore(subject)
	check(restarted.ok and restarted.run.export_save() == initial, "Active service round-trips its exact retained state: " + str(restarted.get("error", "")))
	if variant == "recovery": _fuzz_service_paths(subject)
	check(not subject.resolve_room(service.identity.run_id, service.identity.node_id, service.identity.visit_id, "completed") and not subject.complete_room_choice(service.identity.run_id, service.identity.node_id, service.identity.visit_id, "leave") and subject.export_save() == initial, "Generic completion APIs cannot bypass the authoritative service transaction.")
	var stale: Dictionary = service.identity.duplicate(true)
	stale.visit_id += "stale"
	check(not subject.resolve_service(stale, "leave").ok and subject.export_save() == initial, "Stale service identity cannot consume or grant a choice.")
	subject._service_transaction = true
	check(not subject.resolve_service(service.identity, "leave").ok and not subject.clone_for_transaction().ok, "Reentrant service resolution and clone reject.")
	subject._service_transaction = false
	if variant in ["reliquary", "desk"]:
		check(service.choices[0].eligible == (variant == "desk") and not subject.resolve_service(service.identity, service.choices[0].choice_id).ok and subject.export_save() == initial, "Item event retains identity; an unfunded reliquary or missing exact upgrade target rejects without payment.")
	var choice_id: String = "leave" if variant in ["reliquary", "desk"] else service.choices[0].choice_id
	var detached: Dictionary = subject.clone_for_transaction()
	var resolution: Dictionary = detached.run.resolve_service(service.identity, choice_id)
	check(resolution.ok and subject.export_save() == initial, "Detached service transaction grants no premature benefit.")
	subject.publish_transaction(detached.run)
	var after: Dictionary = subject.export_save()
	check(after.route.visits.back().status == "completed" and after.service_records.back().receipt.choice_id == choice_id, "Exactly one committed choice completes the visit and records its stable identity.")
	check(after.player_hp == before.player_hp + resolution.hp_delta and after.gold == before.gold + resolution.gold_delta and after.player_max_hp == before.player_max_hp, "Health/Gold effect and unchanged maximum publish atomically with the receipt.")
	check(not subject.resolve_service(service.identity, choice_id).ok and not subject.resolve_service(service.identity, "leave").ok and not subject.request_room_entry(node_id).ok and subject.export_save() == after, "Repeated benefit, second Leave and completed-room reentry reject without mutation.")
	check(restore(subject).ok, "Resolved service retains valid Gold and HP history.")
	if variant == "recovery": _fuzz_service_paths(subject)
	_corruptions(subject)
	var battle: Dictionary = subject.prepare_route_battle(subject.request_room_entry(Fixture.next_node(subject)).token)
	check(battle.ok and subject.commit_route_battle(battle).ok, "The next real encounter accepts carried service resources.")
	check(subject._entry_checkpoint.player_hp == after.player_hp and subject._entry_checkpoint.player_max_hp == after.player_max_hp, "Next battle entry uses the exact healed or tithed health.")
	var replay: Dictionary = restore(subject)
	check(replay.ok and replay.run._entry_checkpoint == subject._entry_checkpoint, "Fresh restore replays the same next-battle health boundary: " + str(replay.get("error", "")))

func _tithe_boundaries() -> void:
	# Isolated model parameter specimens, deliberately not saved gameplay. This
	# tests exact 8/9-HP confirmation boundaries without manufacturing victories
	# or claiming an invented predecessor health history is a valid migration.
	for hp in [8, 9]:
		var subject = Fixture.new_run(42, "tithe")
		for node in subject._route._graph.nodes:
			if node.depth == 1: subject._route._service(node, "event", "event_blood_tithe")
		subject._player_hp = hp
		check(Fixture.enter_service(subject, "d1a").ok, "Isolated %d-HP model specimen prepares the authoritative tithe action." % hp)
		var service: Dictionary = subject.service_snapshot()
		var before: Dictionary = subject.export_save()
		var resolved: Dictionary = subject.resolve_service(service.identity, "blood_tithe")
		if hp == 8:
			check(not resolved.ok and subject.export_save() == before, "Authoritative Tithe rejects exactly 8 HP without consuming the choice or gaining Gold.")
			check(subject.resolve_service(service.identity, "leave").ok and subject._player_hp == 8 and subject._gold == 0, "Leave remains free after the 8-HP rejection.")
		else:
			check(resolved.ok and subject._player_hp == 1 and subject._gold == 40 and subject._route._visits.back().status == "completed", "Authoritative Tithe at exactly 9 HP atomically survives at 1 HP, grants 40 Gold and completes.")
			var committed: Dictionary = subject.export_save()
			check(not subject.resolve_service(service.identity, "blood_tithe").ok and subject.export_save() == committed, "The 9-HP Tithe receipt cannot apply twice.")
		var after: Dictionary = subject.export_save()
		for field in ["player_max_hp", "owned_cards", "next_uid", "rng_states", "reward_rng_state", "shop_rng_state"]:
			check(after[field] == before[field], "Exact Tithe boundary preserves %s." % field)
		check(not restore(subject).ok, "Parameter specimen cannot masquerade as a valid saved starter or fabricated health history.")

func _corruptions(subject) -> void:
	var original: Dictionary = subject.export_save()
	for field in ["version", "identity", "policy_id", "definition_id", "room_id", "status", "entry_hp", "entry_max_hp", "entry_gold", "receipt"]:
		var data := original.duplicate(true)
		data.service_records.back()[field] = null
		check(not restore(subject, data).ok, "Reject malformed service field %s." % field)
	for field in ["hp_delta", "gold_delta", "result_hp", "result_max_hp", "result_gold", "choice_id", "transaction_id"]:
		var data := original.duplicate(true)
		data.service_records.back().receipt[field] = 99 if field in ["hp_delta", "gold_delta", "result_hp", "result_max_hp", "result_gold"] else "wrong"
		check(not restore(subject, data).ok, "Reject altered committed service receipt %s." % field)
	var data := original.duplicate(true)
	data.service_records.append(data.service_records.back().duplicate(true))
	check(not restore(subject, data).ok, "Reject duplicate service visit receipts.")
	data = original.duplicate(true)
	data.service_records.back().extra = "script"
	check(not restore(subject, data).ok, "Reject extra fields outside the bounded service schema.")
	data = original.duplicate(true)
	data.battle_health_records[0].result_hp -= 1
	check(not restore(subject, data).ok, "Reject discontinuity between the prior battle result and service entry.")
	data = original.duplicate(true)
	data.health_boundary.source_version = 2
	data.health_boundary.visit_count = data.route.visits.size()
	data.health_boundary.player_hp = data.player_hp
	data.battle_health_records = []
	check(not restore(subject, data).ok, "Legacy boundary cannot slide beyond new service visits to conceal health changes.")
	data = original.duplicate(true)
	data.player_hp = maxi(1, data.player_hp - 1)
	check(not restore(subject, data).ok, "Reject final HP inconsistent with the service receipt.")
	data = original.duplicate(true)
	data.battle_health_records = []
	check(not restore(subject, data).ok, "Reject missing battle boundaries after the starter anchor.")

func _unknown() -> void:
	var subject = Fixture.new_run(42, "unknown")
	check(Fixture.win_battle(subject).ok, "Unknown-event fixture still earns entry access through a genuine battle.")
	var before: Dictionary = subject.export_save()
	var prepared: Dictionary = subject.prepare_route_service(subject.request_room_entry(Fixture.next_node(subject)).token)
	check(not prepared.ok and subject.export_save() == before, "Unknown selected event fails preparation without consuming the visit or sampling randomness.")

func _fuzz_service_paths(subject) -> void:
	var original: Dictionary = subject.export_save()
	var paths: Array = []
	for key in ["service_policy_id", "service_records", "health_boundary", "battle_health_records"]:
		paths.append([key])
		_collect_paths(original[key], [key], paths)
	for path in paths:
		var source: Variant = original
		for key in path: source = source[key]
		var data := original.duplicate(true)
		var target: Variant = data
		for index in range(path.size() - 1): target = target[path[index]]
		target[path.back()] = null if source is Dictionary or source is Array else []
		check(not restore(subject, data).ok, "Malformed nested service/health field rejects cleanly: " + str(path))

func _collect_paths(value: Variant, prefix: Array, result: Array) -> void:
	if value is Dictionary:
		for key in value:
			var path := prefix.duplicate()
			path.append(key)
			result.append(path)
			_collect_paths(value[key], path, result)
	elif value is Array:
		for index in range(value.size()):
			var path := prefix.duplicate()
			path.append(index)
			result.append(path)
			_collect_paths(value[index], path, result)

func _future_income() -> void:
	var subject = Fixture.new_run(42, "satchel")
	for node in subject._route._graph.nodes:
		if node.depth == 2: subject._route._service(node, "shop", "")
		elif node.depth == 3: subject._route._service(node, "event", "event_lost_satchel")
	check(Fixture.win_battle(subject).ok and Fixture.enter_shop(subject).ok, "Future-income probe earns an unfunded shop through a real battle.")
	var shop: Dictionary = subject.shop_snapshot()
	check(not subject.buy_shop_rune(shop.identity, shop.slots[0].slot_id).ok, "A present shop cannot spend income from a future event.")
	check(subject.leave_shop(shop.identity).ok, "The unfunded earlier shop can be left normally.")
	for choice in ["take_gold", "blood_tithe"]:
		check(Fixture.enter_service(subject).ok, "Later event opens after preceding completion.")
		check(subject.resolve_service(subject.service_snapshot().identity, choice).ok, "Later event commits its own actual Gold income.")
	check(subject._gold == 60 and restore(subject).ok, "Twenty plus forty later Gold validates at its chronological visits.")
	var data: Dictionary = subject.export_save()
	var historical: Dictionary = data.shop_records[0]
	var card := {"id": historical.slots[0].definition_id, "uid": historical.entry_next_uid, "upgrade_rank": 0}
	historical.slots[0].sold = true
	historical.slots[0].granted_uid = card.uid
	historical.transactions.push_front({"transaction_id": subject._shop_key(historical.identity) + "/" + historical.slots[0].slot_id, "kind": "purchase", "slot_id": historical.slots[0].slot_id, "gold_spent": 30, "card": card})
	data.owned_cards.append(card)
	data.next_uid += 1
	data.gold -= 30
	check(not restore(subject, data).ok, "Save validation rejects an earlier purchase funded only by future event income.")
