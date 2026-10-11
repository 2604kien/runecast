extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output := ProjectSettings.globalize_path("res://../../../../art/rc-012")
	var report_path := ProjectSettings.globalize_path("res://../godot-render-results.json")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=").strip_edges()
		if arg.begins_with("--report="): report_path = arg.trim_prefix("--report=").strip_edges()
	DirAccess.make_dir_recursive_absolute(output)
	var jobs := [
		["symbols",1200,1390], ["states-and-rotations",1200,1460], ["rotations-72",720,840],
		["typography",1000,1400], ["action-states",1200,1040], ["layout-720x1600",720,1600],
		["layout-450x1000",450,1000], ["layout-360x640",360,640],
		["layout-360x640-cards",360,640]
	]
	var results: Array = []
	var errors: Array = []
	var sheet_script = load("res://sheet.gd")
	if sheet_script == null:
		quit(1)
		return
	for job in jobs:
		var vp := SubViewport.new()
		vp.size = Vector2i(job[1], job[2])
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		var sheet = sheet_script.new()
		sheet.mode = job[0]
		sheet.canvas_size = Vector2(job[1], job[2])
		vp.add_child(sheet)
		await process_frame
		await RenderingServer.frame_post_draw
		await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var save_error := img.save_png(output.path_join(job[0] + ".png"))
		if save_error != OK: errors.append("PNG save failed: " + job[0])
		errors.append_array(sheet.issues)
		results.append({"file":job[0]+".png","width":img.get_width(),"height":img.get_height(),"live_text_checks":sheet.text_checks,"issues":sheet.issues,"fonts":sheet.font_report,"textures":sheet.texture_report})
		vp.queue_free()
		await process_frame
	var report := {"task":"RC-012","result":"PASS" if errors.is_empty() else "FAIL","engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"sheets":results,"errors":errors,"scope":"Actual offscreen SubViewport GL rendering; isolated imported copies; no gameplay/device acceptance"}
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  ")+"\n")
	print("RC012_RENDER ",report.result," sheets=",results.size()," errors=",errors)
	quit(0 if errors.is_empty() else 1)
