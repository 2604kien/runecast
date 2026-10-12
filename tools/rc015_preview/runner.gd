extends SceneTree

const PACK = "res://assets/enemies/shadeling/"
const DURATIONS = {"idle":2.4,"attack":0.9,"hit":0.65,"defeat":1.25}
var output: String
var errors: Array=[]
var sheets: Array=[]
var checks: Array=[]

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func check(condition: bool, description: String) -> void:
	checks.append({"check":description,"pass":condition})
	if not condition: errors.append(description)

func run() -> void:
	output=ProjectSettings.globalize_path("res://../../../art/rc-015")
	var report_path=ProjectSettings.globalize_path("res://../godot-render-results.json")
	var include_home := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
		if arg=="--crypt-only": include_home=false
	DirAccess.make_dir_recursive_absolute(output)
	var imported: Array=[]
	probe_imports("res://assets/environments",imported)
	var settings = load("res://assets/environments/crypt/lighting.tres")
	check(settings.PRESETS.size()==3,"Exactly three lighting presets")
	check(not settings.has_preset(&"extra"),"Unknown lighting preset rejected")
	for layer in ["background","floor"]:
		await render_sheet("crypt-layer-"+layer,"layer",Vector2i(841,570),{"layer":layer})
	await render_sheet("crypt-recomposed","recomposed",Vector2i(841,570))
	await render_sheet("crypt-overlap-crop-guides","guides",Vector2i(841,570))
	for crop_y in [0,60,120]:
		await render_sheet("crypt-art-overscan-y%d"%crop_y,"overscan",Vector2i(841,450),{"crop_y":crop_y})
	for width in [720,450,360]:
		var size := Vector2i(width,roundi(width*450.0/841.0))
		for preset in ["base_cool","warm_candle","dark"]:
			await render_sheet("crypt-%s-%d"%[preset,width],"arena",size,{"preset":preset})
		for sample in [["idle",0.6],["attack",0.46],["hit",0.18],["defeat",0.68],["defeat",1.25]]:
			await render_sheet("crypt-motion-%d-%s-%03d"%[width,sample[0],int(sample[1]*100)],"arena",size,{"state":sample[0],"seconds":sample[1]})
		await render_sheet("crypt-motion-guides-%d"%width,"arena",size,{"state":"attack","seconds":0.46,"guides":true})
	var envelope=await measure_envelope()
	if include_home:
		for height in [1280,1600,1720]:
			for composed in [false,true]:
				await render_sheet("home-%d-%s"%[height,"composed" if composed else "clean"],"home",Vector2i(720,height),{"composed":composed})
	var report={
		"task":"RC-015","result":"PASS" if errors.is_empty() else "FAIL","home_included":include_home,
		"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),"sheets":sheets,"checks":checks,
		"envelope":envelope,"imported_resources":imported,"errors":errors,
		"mapping":{"source_composition":[841,1870],"environment_export":[841,570],"environment_master":[1682,1140],"arena_crop":[0,60,841,450],"source_foot":[446,428],"crop_foot":[446,368],"source_runtime_texture_scale":0.75,"uniform_scale":"output_width / 841; rounded viewport height does not alter transform","default_only_presentation_acceptance":true,"raw_art_crop_y_support":[0,120],"horizontal_overscan":0},
		"scope":"Actual isolated Godot SubViewport imports and rendering; reusable environment scene plus unchanged RC-014 actor and RC-013 theme/fonts/wordmark. UI uses fixed specimen values, not gameplay binding. Art-only overscan endpoint crops do not approve alternate actor/UI layouts. No physical device acceptance."
	}
	var file=FileAccess.open(report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	print("RC015_RENDER ",report.result," sheets=",sheets.size()," checks=",checks.size()," errors=",errors)
	quit(0 if errors.is_empty() else 1)

func render_sheet(filename: String, mode: String, size: Vector2i, options: Dictionary={}) -> void:
	var vp := SubViewport.new()
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
	check(image.save_png(output.path_join(filename+".png"))==OK,"Saved "+filename)
	var entry={"file":filename+".png","mode":mode,"width":size.x,"height":size.y,"actors":sheet.actors.size(),"live_labels":sheet.labels.size(),"live_controls":sheet.controls.size(),"options":options}
	if mode=="arena":
		var actor: Node2D=sheet.actors[0]
		var transform := actor.get_global_transform_with_canvas()
		entry["actor_foot"]=[transform.origin.x,transform.origin.y]
		entry["actor_scale"]=[transform.get_scale().x,transform.get_scale().y]
		entry["visual_sample"]=actor.get_visual_sample()
		check(transform.origin.distance_to(Vector2(446,368)*size.x/841.0)<0.001,filename+" common foot")
		check(absf(transform.get_scale().x-0.75*size.x/841.0)<0.00001,filename+" retained actor scale")
		check(absf(transform.get_scale().x-transform.get_scale().y)<0.00001,filename+" uniform actor scale")
		check(actor.modulate==Color.WHITE and actor.material==null,filename+" actor untinted")
		for label in sheet.labels: check(label.modulate==Color.WHITE and label.material==null,filename+" UI untinted: "+label.text)
	if sheet.environment:
		var layers: Array=sheet.environment.get_layer_nodes()
		check(layers[0].transform==layers[1].transform,filename+" aligned layer transforms")
		check(layers[0].material==layers[1].material,filename+" shared layer material")
		var before=sheet.environment.preset
		check(not sheet.environment.set_lighting(&"extra") and sheet.environment.preset==before,filename+" invalid preset preserves scene")
	if mode=="home":
		entry["cover"]=sheet.cover
		for control in sheet.controls:
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(control.get_rect()),filename+" controls within viewport")
	sheets.append(entry)
	vp.queue_free()
	await process_frame

func measure_envelope() -> Dictionary:
	var vp := SubViewport.new()
	vp.size=Vector2i(512,512)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var actor=load(PACK+"character.tscn").instantiate()
	vp.add_child(actor)
	actor.position=Vector2(256,448)
	var union := Rect2i()
	var samples: Array=[]
	var visible_count=0
	for reduced in [false,true]:
		for state in ["idle","attack","hit","defeat"]:
			for i in 17:
				var elapsed=float(DURATIONS[state])*i/16
				check(actor.sample_state(state,elapsed,reduced),"Valid state sample "+state)
				await settle()
				var bounds: Rect2i=vp.get_texture().get_image().get_used_rect()
				if bounds.has_area():
					union=bounds if visible_count==0 else union.merge(bounds)
					visible_count+=1
					check(Rect2i(24,32,464,448).encloses(bounds),"Declared motion envelope "+state)
					var local := Rect2(Vector2(254,32)+Vector2(bounds.position)*0.75,Vector2(bounds.size)*0.75)
					check(Rect2(0,0,841,450).encloses(local),"Default crop contains full motion "+state)
				if state=="defeat" and i==16: check(not bounds.has_area(),"Stable invisible defeat endpoint")
				samples.append({"state":state,"seconds":elapsed,"reduced_motion":reduced,"bounds":[bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y]})
	vp.queue_free()
	await process_frame
	return {"bounds":[union.position.x,union.position.y,union.end.x,union.end.y],"sample_count":samples.size(),"samples":samples,"allowed_bounds":[24,32,488,480],"alpha_threshold":"Godot Image.get_used_rect nonzero alpha"}

func probe_imports(path: String, results: Array) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension() not in ["png","tscn","tres"]: continue
		var resource=load(path.path_join(file))
		check(resource!=null,"Imported "+path.path_join(file))
		if resource==null: continue
		var entry={"path":path.path_join(file),"type":resource.get_class()}
		if resource is Texture2D:
			entry["width"]=resource.get_width()
			entry["height"]=resource.get_height()
		results.append(entry)
	for folder in DirAccess.get_directories_at(path): probe_imports(path.path_join(folder),results)
