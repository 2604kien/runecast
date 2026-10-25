extends RefCounted
## Provisional roster values. Service policies never enter Combat configuration.
const LEGACY_POLICY_ID := "rc030_services_v1"
const POLICY_ID := "rc031_services_v2"
const RECOVERY_HEAL := 10
const SATCHEL_GOLD := 20
const TITHE_HP := 8
const TITHE_GOLD := 40
const RELIQUARY_PRICE := 15
const MAX_AMOUNT := 1000

static func definition(room_id: String, reference: String = "", policy_id: String = POLICY_ID) -> Dictionary:
	if not policy_id in [POLICY_ID, LEGACY_POLICY_ID]: return {}
	var leave := {"choice_id": "leave", "label": "Leave", "effect": "leave", "amount": 0, "gold": 0}
	var result: Dictionary = {}
	if room_id == "room_recovery" and reference.is_empty():
		result = {"id": "recovery", "room_id": room_id, "title": "Recovery", "premise": "Rest before the next ascent.", "choices": [
			{"choice_id": "recover", "label": "Recover", "effect": "heal", "amount": RECOVERY_HEAL, "gold": 0},
			{"choice_id": "refine_rune", "label": "Refine Rune", "effect": "upgrade_unavailable", "amount": 0, "gold": 0}, leave]}
	elif room_id == "room_event":
		var events := {
			"event_lost_satchel": {"title": "Lost Satchel", "premise": "A forgotten satchel holds a few coins.", "choice": {"choice_id": "take_gold", "label": "Take the Gold", "effect": "gold", "amount": 0, "gold": SATCHEL_GOLD}},
			"event_blood_tithe": {"title": "Blood Tithe", "premise": "A stone basin offers wealth for a little blood.", "choice": {"choice_id": "blood_tithe", "label": "Pay the Tithe", "effect": "tithe", "amount": TITHE_HP, "gold": TITHE_GOLD}},
			"event_sealed_reliquary": {"title": "Sealed Reliquary", "premise": "An ancient relic lies behind a sealed lid.", "choice": {"choice_id": "open_reliquary", "label": "Open Reliquary", "effect": "relic_unavailable", "amount": 0, "gold": -RELIQUARY_PRICE}},
			"event_etched_desk": {"title": "Etched Desk", "premise": "Old tools await a rune to refine.", "choice": {"choice_id": "refine_rune", "label": "Refine Rune", "effect": "upgrade_unavailable", "amount": 0, "gold": 0}}}
		if events.has(reference):
			var event: Dictionary = events[reference]
			result = {"id": reference, "room_id": room_id, "title": event.title, "premise": event.premise, "choices": [event.choice, leave]}
	if policy_id == POLICY_ID:
		for choice in result.get("choices", []):
			if choice.effect == "upgrade_unavailable": choice.effect = "upgrade"
			if choice.effect == "relic_unavailable": choice.effect = "relic"
	return result.duplicate(true) if validate_definition(result).is_empty() else {}

static func validate_definition(data: Dictionary) -> String:
	if data.size() != 5: return "The room definition is unavailable."
	for field in ["id", "room_id", "title", "premise"]:
		if not data.get(field) is String or data[field].is_empty(): return "The room definition is malformed."
	if data.room_id == "room_recovery" and data.id != "recovery": return "Unknown recovery definition."
	if data.room_id == "room_event" and not data.id in ["event_lost_satchel", "event_blood_tithe", "event_sealed_reliquary", "event_etched_desk"]: return "Unknown event definition."
	if not data.room_id in ["room_recovery", "room_event"] or not data.get("choices") is Array or data.choices.size() < 2 or data.choices.size() > 3: return "The room choices are malformed."
	var seen := {}
	var has_leave := false
	for choice in data.choices:
		if not choice is Dictionary or choice.size() != 5: return "The room choice is malformed."
		for field in ["choice_id", "label", "effect"]:
			if not choice.get(field) is String or choice[field].is_empty(): return "The room choice identity is malformed."
		if seen.has(choice.choice_id): return "The room repeats a choice identity."
		seen[choice.choice_id] = true
		if not choice.get("amount") is int or not choice.get("gold") is int or choice.amount < 0 or choice.amount > MAX_AMOUNT or choice.gold < -MAX_AMOUNT or choice.gold > MAX_AMOUNT: return "The room choice amount is invalid."
		match choice.effect:
			"leave":
				if choice.choice_id != "leave" or choice.amount != 0 or choice.gold != 0: return "Leave must be free."
				has_leave = true
			"heal":
				if choice.amount <= 0 or choice.gold != 0: return "Healing must be free."
			"gold":
				if choice.amount != 0 or choice.gold <= 0: return "Gold income is malformed."
			"tithe":
				if choice.amount <= 0 or choice.gold <= 0: return "The tithe is malformed."
			"upgrade_unavailable", "upgrade":
				if choice.amount != 0 or choice.gold != 0: return "The upgrade is malformed."
			"relic_unavailable", "relic":
				if choice.amount != 0 or choice.gold >= 0: return "The relic price is malformed."
			_: return "The room effect is unsupported."
	return "" if has_leave else "The room needs a free Leave option."

static func choices(data: Dictionary, hp: int, max_hp: int, gold: int, recovery_bonus: int = 0) -> Array:
	if not validate_definition(data).is_empty(): return []
	var result: Array = []
	for choice in data.choices:
		var item := {"choice_id": choice.choice_id, "label": choice.label, "effect": choice.effect, "description": "", "eligible": true, "reason": "", "hp_delta": 0, "gold_delta": 0}
		match choice.effect:
			"leave": item.description = "Complete this room without a benefit."
			"heal":
				item.hp_delta = mini(choice.amount + recovery_bonus, max_hp - hp)
				item.description = "Restore %d HP (%d to %d / %d). Free." % [item.hp_delta, hp, hp + item.hp_delta, max_hp]
				if hp >= max_hp: item.reason = "Health is already full."
			"gold":
				item.gold_delta = choice.gold
				item.description = "Gain %d Gold." % choice.gold
			"tithe":
				item.hp_delta = -choice.amount
				item.gold_delta = choice.gold
				item.description = "Lose %d HP and gain %d Gold." % [choice.amount, choice.gold]
				if hp <= choice.amount: item.reason = "Requires more than %d HP." % choice.amount
			"upgrade_unavailable":
				item.description = "Upgrade one owned rune. Free."
				item.reason = "Rune refinement is unavailable."
			"relic_unavailable":
				item.description = "Pay %d Gold for a relic." % -choice.gold
				item.reason = "Relic offerings are unavailable."
			"upgrade": item.description = "Upgrade one eligible owned rune. Free."
			"relic":
				item.gold_delta = choice.gold
				item.description = "Choose one relic for %d Gold." % -choice.gold
				if gold < -choice.gold: item.reason = "Not enough Gold."
		if item.gold_delta > 0 and gold > 9223372036854775807 - item.gold_delta: item.reason = "Gold cannot be added."
		item.eligible = item.reason.is_empty()
		result.append(item)
	return result
