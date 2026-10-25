class_name RuneStorePolicy
extends RefCounted

# Menu supplies are a fixed, run-only catalogue. Route shops keep their own
# stock, allowances and lower prices; this policy consumes no random stream.
const VERSION := 2
const POLICY_ID := "rc035_store_v2"
const LEGACY_POLICY_ID := "rc032_store_v1"
const RUNE_PRICE := 45
const RELIC_PRICE := 90

static func empty_state(legacy: bool = false) -> Dictionary:
	return {"version": 1 if legacy else VERSION, "policy_id": LEGACY_POLICY_ID if legacy else POLICY_ID, "transactions": []}

static func validate_structure(value: Variant) -> String:
	if not value is Dictionary or value.size() != 3 or not value.get("version") is int or not value.version in [1, VERSION] or not value.get("policy_id") is String or value.policy_id != (LEGACY_POLICY_ID if value.version == 1 else POLICY_ID) or not value.get("transactions") is Array or value.transactions.size() > 2:
		return "Saved Store policy or allowance is malformed."
	var kinds := {}
	for receipt in value.transactions:
		if not receipt is Dictionary or receipt.size() != 16: return "Saved Store receipt structure is invalid."
		for field in ["transaction_id", "kind", "definition_id"]:
			if not receipt.get(field) is String: return "Saved Store identity must be text."
		if not receipt.kind in ["rune", "relic"] or kinds.has(receipt.kind): return "Saved Store repeats a per-run purchase allowance."
		kinds[receipt.kind] = true
		for field in ["after_visit_count", "route_revision", "gold_spent", "entry_gold", "result_gold", "entry_next_uid", "entry_hp", "entry_max_hp", "result_hp", "result_max_hp"]:
			if not receipt.get(field) is int or receipt[field] < 0: return "Saved Store counters must be nonnegative exact integers."
		for field in ["eligible_rune_ids", "eligible_relic_ids"]:
			if not receipt.get(field) is Array: return "Saved Store catalogue must be an array."
			var seen := {}
			for id in receipt[field]:
				if not id is String or seen.has(id): return "Saved Store catalogue must contain unique definition IDs."
				seen[id] = true
		if not receipt.get("card") is Dictionary: return "Saved Store card must be an object."
		if receipt.kind == "rune":
			if receipt.card.size() != 3 or not receipt.card.get("id") is String or not receipt.card.get("uid") is int or not receipt.card.get("upgrade_rank") is int or receipt.card.upgrade_rank != 0:
				return "Saved Store rune must be an exact rank-zero instance."
		elif not receipt.card.is_empty(): return "Saved Store relic cannot grant a rune."
	return ""
