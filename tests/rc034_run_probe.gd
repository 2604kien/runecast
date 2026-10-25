extends SceneTree
const Journey = preload("res://tests/helpers/rc034_journey.gd")
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/qa/rc-034/play/runs")
	var summary: Array = []
	for branch in ["normal", "elite"]:
		for seed in range(64):
			var result := Journey.play(seed, branch)
			var target := "res://output/qa/rc-034/play/runs/%s-%d.json" % [branch, seed]
			FileAccess.open(target, FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
			summary.append({"branch": branch, "seed": seed, "outcome": result.get("outcome", "error"), "depth": result.get("depth", 0), "error": result.get("error", ""), "evidence": target})
			print("%s seed%d: %s depth%d %s" % [branch, seed, result.get("outcome", "error"), result.get("depth", 0), result.get("error", "")])
			if result.has("error"):
				quit(1)
				return
			if result.outcome == "victory": break
	FileAccess.open("res://output/qa/rc-034/play/run-summary.json", FileAccess.WRITE).store_string(JSON.stringify(summary, "  "))
	quit()
