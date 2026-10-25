extends RefCounted
## Explicit historical fixture shape. Excluded from production exports.
## Preserve old fixture signatures when production authoring fills planned IDs.
static func retain(route) -> void:
	for node in route._graph.nodes:
		if node.encounter_role in ["normal", "elite", "guardian"]: node.encounter_id = ""
		node.content_pending = node.encounter_id != "training_shadeling"

static func expected_hydration(saved_route: Dictionary) -> Dictionary:
	var expected := saved_route.duplicate(true)
	if not preload("res://scripts/core/route_state.gd").is_legacy_planned_graph(expected.get("graph", {})): return expected
	for node in expected.graph.nodes:
		if node.encounter_role in ["normal", "elite", "guardian"]: node.encounter_id = node.enemy_id
		node.content_pending = false
	return expected
