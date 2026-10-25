extends RefCounted
## Detached presentation only. Run ownership supplies instances; a live Combat
## snapshot supplies locations, never ownership or the next UID allocator.
const InspectionData = preload("res://scripts/ui/inspection_data.gd")
const InstanceEffects = preload("res://scripts/core/instance_effects.gd")
const RelicPolicy = preload("res://scripts/core/relic_policy.gd")
const ZONE_NAMES := {"hand": "Hand", "draw_pile": "Draw pile", "discard_pile": "Discard pile"}

static func describe(run_snapshot: Dictionary, catalog: Dictionary, live_snapshot: Dictionary = {}) -> Dictionary:
	var locations := {}
	var temporary: Array = []
	var zone_counts := {"hand": 0, "draw_pile": 0, "discard_pile": 0, "installed": 0}
	for zone in ZONE_NAMES:
		for card in live_snapshot.get(zone, []):
			_add_location(card, zone, ZONE_NAMES[zone], catalog, locations, temporary, zone_counts)
	var board: Array = live_snapshot.get("board", [])
	for index in board.size():
		var piece: Dictionary = board[index]
		if piece.get("kind") == "rune":
			_add_location(InstanceEffects.card_from_piece(piece), "installed",
				"Installed · row %d, column %d" % [index / 4 + 1, index % 4 + 1], catalog, locations, temporary, zone_counts)
	var groups := {}
	var owned_count := 0
	var definitions := {}
	var has_live := not live_snapshot.is_empty()
	for instance in run_snapshot.get("owned_cards", []):
		var id := str(instance.get("id", ""))
		var definition: Dictionary = catalog.get(id, {})
		if definition.is_empty() or definition.get("temporary", false): continue
		definitions[id] = true
		var rank := int(instance.get("upgrade_rank", 0))
		var group_key := id + ":" + str(rank)
		if not groups.has(group_key): groups[group_key] = {"id": id, "upgrade_rank": rank, "card": instance_card(catalog, instance), "instances": []}
		var uid := int(instance.get("uid", -1))
		var location: Dictionary = locations.get(uid, {})
		# Matching both UID and definition prevents stale zones mislabeling an
		# instance. A new reward is owned without entering the settled hand.
		var zone := str(location.get("zone", "")) if location.get("id") == id else ""
		groups[group_key].instances.append({"id": id, "uid": uid, "upgrade_rank": rank, "zone": zone,
			"location": str(location.label) if not zone.is_empty() else "Run collection · next encounter" if has_live else "Run collection"})
		owned_count += 1
	var ordered: Array = groups.values()
	ordered.sort_custom(func(a, b): return str(a.card.name).naturalnocasecmp_to(str(b.card.name)) < 0)
	for group in ordered:
		group.instances.sort_custom(func(a, b): return int(a.uid) < int(b.uid))
		group.count = group.instances.size()
	temporary.sort_custom(func(a, b): return int(a.uid) < int(b.uid))
	var unlocked: Array = []
	var relics: Array = []
	for id in run_snapshot.get("relics", []):
		var relic: Dictionary = RelicPolicy.definitions().get(str(id), {})
		if not relic.is_empty(): relics.append(relic.duplicate(true))
	for id in run_snapshot.get("profile", {}).get("unlocked_definition_ids", []):
		var rune: Dictionary = catalog.get(id, {})
		if rune.is_empty() or rune.get("temporary", false): continue
		unlocked.append({"id": str(id), "name": str(rune.name)})
	return {"run_id": str(run_snapshot.get("run_id", "")), "owned_count": owned_count,
		"definition_count": definitions.size(), "groups": ordered, "temporary": temporary, "relics": relics,
		"unlocked_definitions": unlocked, "has_profile": not run_snapshot.get("profile", {}).is_empty(),
		"has_live": has_live, "battle_active": live_snapshot.get("state") == "playing", "zone_counts": zone_counts}.duplicate(true)

static func definition_card(catalog: Dictionary, id: String) -> Dictionary:
	return instance_card(catalog, {"id": id, "upgrade_rank": 0})

static func instance_card(catalog: Dictionary, instance: Dictionary) -> Dictionary:
	var rune: Dictionary = InstanceEffects.resolve(catalog, instance).get("definition", {})
	if rune.is_empty(): return {}
	var icon := str(rune.get("effect", "")) if rune.get("type") == "technique" else "shield" if rune.get("effect") == "shield" else "spark"
	if icon == "draw": icon = "focus"
	return {"id": str(instance.get("id", instance.get("rune_id", ""))), "uid": int(instance.get("uid", -1)), "upgrade_rank": int(instance.get("upgrade_rank", 0)), "name": InspectionData.display_name(rune), "cost": int(rune.cost), "icon": icon,
		"kind": "technique" if rune.get("type") == "technique" else str(rune.get("effect", "mixed")),
		"type": str(rune.get("type", "rune")), "description": InspectionData._effect({"catalog": catalog}, rune),
		"inspection": InspectionData.detail_effect({"catalog": catalog}, rune),
		"temporary": bool(rune.get("temporary", false)), "compact": true, "compact_height": 176}

static func upgrade_text(catalog: Dictionary, instance: Dictionary) -> String:
	var preview := InstanceEffects.upgrade_preview(catalog, instance)
	if not preview.get("ok", false): return str(preview.get("error", "This copy cannot be upgraded."))
	return "Before: %s\nAfter: %s\n\nEnergy and ports stay unchanged. One upgrade for this copy." % [InstanceEffects.effect_summary(preview.before), InstanceEffects.effect_summary(preview.after)]

static func _add_location(card: Dictionary, zone: String, label: String, catalog: Dictionary, locations: Dictionary, temporary: Array, counts: Dictionary) -> void:
	var id := str(card.get("id", ""))
	var rune: Dictionary = catalog.get(id, {})
	if rune.is_empty(): return
	var uid := int(card.get("uid", -1))
	var item := {"id": id, "uid": uid, "upgrade_rank": int(card.get("upgrade_rank", 0)), "zone": zone, "label": label}
	if rune.get("temporary", false):
		item.card = definition_card(catalog, id)
		temporary.append(item)
	else:
		locations[uid] = item
		counts[zone] = int(counts[zone]) + 1
