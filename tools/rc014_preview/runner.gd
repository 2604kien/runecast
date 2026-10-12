extends SceneTree

const PACK = "res://assets/enemies/shadeling/"
const DURATIONS = {"idle":2.4,"attack":0.9,"hit":0.65,"defeat":1.25}
var output: String
var errors: Array=[]
var sheets: Array=[]

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func run() -> void:
	output=ProjectSettings.globalize_path("res://../../../art/rc-014")
	var report_path=ProjectSettings.globalize_path("res://../godot-render-results.json")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
	DirAccess.make_dir_recursive_absolute(output)
	var imported: Array=[]
	probe_imports(PACK,imported)
	var envelope=await measure_envelope()
	var part_envelope=await measure_part_envelope()
	var behavior: Dictionary={"result":"NOT_RUN"}
	if FileAccess.file_exists("res://test_shadeling.gd"):
		behavior=await load("res://test_shadeling.gd").new().run(self)
		if behavior.get("result","")!="PASS": errors.append("Character behavioral checks failed")
	var files: Array=[]
	for pose in ["neutral","attack","hit"]: files.append(PACK+pose+".png")
	for path in DirAccess.get_files_at(PACK+"parts"):
		if path.ends_with(".png"): files.append(PACK+"parts/"+path)
	await render_sheet("pose-sheet","poses",Vector2i(1200,520))
	await render_sheet("alpha-backgrounds","alpha",Vector2i(1200,94+files.size()*270),{"files":files})
	await render_sheet("anchor-envelope","overlay",Vector2i(1200,576),{"envelope":envelope.bounds})
	await render_sheet("arena-design-720","arena",Vector2i(720,385))
	await render_sheet("arena-desktop-450","arena",Vector2i(450,241))
	# Retain the established filename; this is now a proportional arena crop.
	await render_sheet("arena-native-360","arena",Vector2i(360,193))
	await render_sheet("motion-comparison","comparison",Vector2i(1200,688))
	await render_sheet("part-underlap-stress","parts",Vector2i(1200,902))
	var sequences: Array=[]
	for reduced in [false,true]:
		var folder="reduced-motion-frames" if reduced else "motion-frames"
		DirAccess.make_dir_recursive_absolute(output.path_join(folder))
		var frames: Array=[]
		var index=0
		for state in ["idle","attack","hit","defeat"]:
			var count=16 if state=="idle" else 10
			for i in count:
				var elapsed=float(DURATIONS[state])*i/(count-1)
				var filename=folder+"/frame-%03d"%index
				await render_sheet(filename,"motion",Vector2i(360,360),{"state":state,"elapsed":elapsed,"reduced":reduced},false)
				frames.append({"file":filename+".png","state":state,"sample_seconds":elapsed,"duration_ms":int(round(float(DURATIONS[state])*1000/count))})
				index+=1
		sequences.append({"reduced_motion":reduced,"frames":frames,"duration_seconds":5.2,"format":"actual Godot PNG sequence; GIF convenience derivative"})
	var report={"task":"RC-014","result":"PASS" if errors.is_empty() else "FAIL","engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"sheets":sheets,"sequences":sequences,"envelope":envelope,"part_envelope":part_envelope,"behavior":behavior,"imported_resources":imported,"errors":errors,"mapping":{"source_composition":[841,1870],"arena_crop":[0,60,841,450],"source_foot":[446,428],"crop_foot":[446,368],"source_runtime_texture_scale":0.75,"design_scale":0.75*720/841,"desktop_scale":0.75*450/841,"native_scale":0.75*360/841,"native_foot":[446.0*360/841,368.0*360/841],"native_viewport":[360,193],"native_framing":"Uniform arena crop; legacy filename retained, not a full native-phone layout"},"scope":"Isolated actual Godot SubViewport rendering. Arena crops only; live-style labels read from fixture values, not game binding. No physical device acceptance."}
	var f=FileAccess.open(report_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  ")+"\n")
	print("RC014_RENDER ",report.result," sheets=",sheets.size()," sequence_frames=92 errors=",errors)
	quit(0 if errors.is_empty() else 1)

func render_sheet(filename: String, mode: String, size: Vector2i, options: Dictionary={}, record: bool=true) -> void:
	var vp:=SubViewport.new()
	vp.size=size
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sheet=load("res://sheet.gd").new()
	sheet.mode=mode
	sheet.canvas_size=Vector2(size)
	sheet.options=options
	vp.add_child(sheet)
	await settle()
	var image=vp.get_texture().get_image()
	if image.save_png(output.path_join(filename+".png"))!=OK: errors.append("Image write failed: "+filename)
	if record:
		var entry={"file":filename+".png","mode":mode,"width":size.x,"height":size.y,"actors":sheet.actors.size(),"live_labels":sheet.labels.size()}
		if mode=="arena":
			var actor_transform: Transform2D=sheet.actors[0].get_global_transform_with_canvas()
			entry["actor_foot"]=[actor_transform.origin.x,actor_transform.origin.y]
			entry["actor_scale"]=[actor_transform.get_scale().x,actor_transform.get_scale().y]
		sheets.append(entry)
	vp.queue_free()
	await process_frame

func measure_envelope() -> Dictionary:
	var vp:=SubViewport.new()
	vp.size=Vector2i(512,512)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var actor=load(PACK+"character.tscn").instantiate()
	vp.add_child(actor)
	actor.position=Vector2(256,448)
	var union:=Rect2i()
	var samples: Array=[]
	var visible_count=0
	for reduced in [false,true]:
		for state in ["idle","attack","hit","defeat"]:
			for i in 17:
				var elapsed=float(DURATIONS[state])*i/16
				if not actor.sample_state(state,elapsed,reduced): errors.append("Invalid sample "+state)
				await settle()
				var image=vp.get_texture().get_image()
				var bounds: Rect2i=image.get_used_rect()
				if bounds.has_area():
					union=bounds if visible_count==0 else union.merge(bounds)
					visible_count+=1
					if not Rect2i(24,32,464,448).encloses(bounds): errors.append("Motion exceeds allowed filtered-alpha envelope: "+state+" at "+str(elapsed)+" "+str(bounds))
				samples.append({"state":state,"seconds":elapsed,"reduced_motion":reduced,"bounds":[bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y],"visual":actor.get_visual_sample()})
	vp.queue_free()
	await process_frame
	return {"bounds":[union.position.x,union.position.y,union.end.x,union.end.y],"samples":samples,"sample_count":samples.size(),"alpha_threshold":"Godot Image.get_used_rect nonzero alpha","allowed_bounds":[24,32,488,480],"filter_margin_note":"24px horizontal exterior allows Lanczos/bilinear antialias tails; exported strong alpha>16 remains inside32..480"}

func probe_imports(path: String, results: Array) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension() not in ["png","tscn"]: continue
		var resource=load(path.path_join(file))
		if resource==null:
			errors.append("Cannot load imported resource "+path.path_join(file))
			continue
		var entry={"path":path.path_join(file),"type":resource.get_class()}
		if resource is Texture2D:
			entry["width"]=resource.get_width()
			entry["height"]=resource.get_height()
		results.append(entry)
	for folder in DirAccess.get_directories_at(path): probe_imports(path.path_join(folder),results)

func measure_part_envelope() -> Dictionary:
	var vp:=SubViewport.new()
	vp.size=Vector2i(512,512)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rig=load("res://parts_study.gd").new()
	vp.add_child(rig)
	rig.position=Vector2(256,448)
	var union:=Rect2i()
	var samples: Array=[]
	for i in 17:
		var amount=-1.0+i/8.0
		rig.sample(amount)
		await settle()
		var rect: Rect2i=vp.get_texture().get_image().get_used_rect()
		union=rect if i==0 else union.merge(rect)
		if not Rect2i(24,32,464,448).encloses(rect): errors.append("Source-part stress exceeds canvas margin at "+str(amount))
		samples.append({"amount":amount,"bounds":[rect.position.x,rect.position.y,rect.end.x,rect.end.y]})
	vp.queue_free()
	await process_frame
	return {"bounds":[union.position.x,union.position.y,union.end.x,union.end.y],"sample_count":samples.size(),"samples":samples,"arm_degrees":[-4,4],"lantern_relative_degrees":[-3,3],"hood_degrees":[-2,2],"scope":"Source-part feasibility only; not loaded by default whole-pose character scene"}
