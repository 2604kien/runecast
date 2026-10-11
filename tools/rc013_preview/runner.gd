extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output := ProjectSettings.globalize_path("res://../../../../art/rc-013")
	var report_path := ProjectSettings.globalize_path("res://../godot-render-results.json")
	var menu_only := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
		if arg=="--menu-only": menu_only=true
	DirAccess.make_dir_recursive_absolute(output)
	var jobs:Array=[]
	for dimensions in [Vector2i(720,1600),Vector2i(450,1000),Vector2i(360,640)]:
		for mode in ["components","home-save","menu-locked","options","map","replace","dialog"]:
			jobs.append({"name":mode+"-"+str(dimensions.x)+"x"+str(dimensions.y),"mode":mode,"size":dimensions,"scroll":0.0})
		jobs.append({"name":"components-bottom-"+str(dimensions.x)+"x"+str(dimensions.y),"mode":"components","size":dimensions,"scroll":1.0})
	for mode in ["home-empty","home-invalid","menu-open","wordmark"]:
		jobs.append({"name":mode+"-450x1000","mode":mode,"size":Vector2i(450,1000),"scroll":0.0})
	jobs.append({"name":"states-full","mode":"states","size":Vector2i(720,4000),"scroll":0.0})
	jobs.append({"name":"cards-full","mode":"cards","size":Vector2i(720,3000),"scroll":0.0})
	jobs.append({"name":"cards-native-top","mode":"cards","size":Vector2i(360,640),"scroll":0.0})
	jobs.append({"name":"cards-native-hand-end","mode":"cards","size":Vector2i(360,640),"scroll":0.0,"hand_end":true})
	jobs.append({"name":"cards-native-bottom","mode":"cards","size":Vector2i(360,640),"scroll":1.0})
	jobs.append({"name":"components-native-middle","mode":"components","size":Vector2i(360,640),"scroll":0.48})
	if menu_only:
		jobs.clear()
		for dimensions in [Vector2i(720,1600),Vector2i(450,1000),Vector2i(360,640)]:
			for mode in ["menu-open","menu-locked"]:
				jobs.append({"name":mode+"-"+str(dimensions.x)+"x"+str(dimensions.y),"mode":mode,"size":dimensions,"scroll":0.0})
	var results:Array=[]
	var errors:Array=[]
	var source=load("res://sheet.gd")
	if source==null:
		quit(1)
		return
	for job in jobs:
		var vp := SubViewport.new()
		vp.size=job.size
		vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		var sheet=source.new()
		sheet.mode=job.mode
		sheet.canvas_size=Vector2(job.size)
		sheet.scroll_fraction=job.scroll
		sheet.hand_end=job.get("hand_end",false)
		vp.add_child(sheet)
		for i in 8:
			await process_frame
			await RenderingServer.frame_post_draw
		sheet.inspect_layout()
		errors.append_array(sheet.issues)
		var img := vp.get_texture().get_image()
		if img.save_png(output.path_join(job.name+".png"))!=OK: errors.append("Image write failed "+job.name)
		var hand_x:int=sheet.hand_scroll.scroll_horizontal if sheet.hand_scroll else 0
		if job.get("hand_end",false) and hand_x<=0: errors.append("Eight-card hand did not scroll to final card")
		results.append({"file":job.name+".png","mode":job.mode,"width":job.size.x,"height":job.size.y,"scroll":job.scroll,"actual_scroll":sheet.scroll.scroll_vertical,"hand_scroll":hand_x,"text_checks":sheet.checks,"menu_clearance_checks":sheet.menu_clearance_checks,"issues":sheet.issues})
		vp.queue_free()
		await process_frame
	var font_report:Array=[]
	for role in ["res://assets/fonts/display/title.tres","res://assets/fonts/ui/labels.tres","res://assets/fonts/ui/location.tres"]:
		var font=load(role)
		if font==null:
			errors.append("Missing font "+role)
			continue
		font.get_string_size("Rune Cast 0681",HORIZONTAL_ALIGNMENT_LEFT,-1,24)
		var axes=TextServerManager.get_primary_interface().font_get_variation_coordinates(font.get_rids()[0])
		font_report.append({"path":role,"axes":axes,"resource_axes":font.variation_opentype})
	var interaction=await interaction_checks()
	errors.append_array(interaction.errors)
	var imported:Array=[]
	probe_imports("res://assets/ui",imported,errors)
	var report={"task":"RC-013","result":"PASS" if errors.is_empty() else "FAIL","engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"sheets":results,"fonts":font_report,"imported_resources":imported,"interaction":interaction,"errors":errors,"scope":"Isolated actual Godot SubViewport renders; no main game integration or physical-device acceptance"}
	var f=FileAccess.open(report_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  ")+"\n")
	print("RC013_RENDER ",report.result," sheets=",results.size()," errors=",errors)
	quit(0 if errors.is_empty() else 1)

func probe_imports(path:String,report:Array,errors:Array) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension() not in ["png","svg","tres"]: continue
		var resource=load(path.path_join(file))
		if resource==null:
			errors.append("Cannot load imported resource "+path.path_join(file))
			continue
		var entry={"path":path.path_join(file),"type":resource.get_class()}
		if resource is Texture2D:
			entry["width"]=resource.get_width()
			entry["height"]=resource.get_height()
		report.append(entry)
	for directory in DirAccess.get_directories_at(path):
		probe_imports(path.path_join(directory),report,errors)

func interaction_checks() -> Dictionary:
	var Ui=load("res://scenes/ui/theme/components.gd")
	var errors:Array=[]
	var vp:=SubViewport.new()
	vp.size=Vector2i(360,640)
	vp.handle_input_locally=true
	root.add_child(vp)
	var host:=Control.new()
	host.size=Vector2(360,640)
	host.theme=load("res://assets/ui/rune_cast_theme.tres")
	vp.add_child(host)
	var button:Button=Ui.action("Continue",true,Vector2(280,60))
	host.add_child(button)
	button.position=Vector2(20,20)
	var events:Array=[]
	button.pressed.connect(func():events.append("pressed"))
	await process_frame
	# Click within a transparent pointed tip: rectangular hit target must survive.
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		event.position=Vector2(22,50)
		vp.push_input(event,true)
	await process_frame
	if events.size()!=1: errors.append("Pointed button edge did not emit exactly one callback")
	button.grab_focus()
	if not button.has_focus(): errors.append("Keyboard focus acquisition failed")
	for down in [true,false]:
		var event:=InputEventAction.new()
		event.action="ui_accept"
		event.pressed=down
		vp.push_input(event,true)
	await process_frame
	if events.size()!=2: errors.append("Focused action did not emit keyboard callback")
	Ui.apply_states(button,{"unavailable":true,"focused":true})
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		event.position=Vector2(150,50)
		vp.push_input(event,true)
	await process_frame
	if events.size()!=2: errors.append("Unavailable action emitted callback")
	var modal:PanelContainer=Ui.modal("Details","Readable paragraph.\n\n".repeat(60),328,430)
	host.add_child(modal)
	modal.position=Vector2(16,120)
	for i in 4: await process_frame
	var scrolls:Array=[]
	collect_type(modal,"ScrollContainer",scrolls)
	if scrolls.is_empty(): errors.append("Long modal has no ScrollContainer")
	else:
		var inner:ScrollContainer=scrolls[0]
		inner.scroll_vertical=100000
		await process_frame
		if inner.scroll_vertical<=0: errors.append("Long modal body does not scroll")
	var buttons:Array=[]
	collect_type(modal,"Button",buttons)
	var close_visible:=false
	for b in buttons:
		if b.text=="Close": close_visible=Rect2(Vector2.ZERO,Vector2(360,640)).encloses(b.get_global_rect())
	if not close_visible: errors.append("Modal Close is not accessible after body scrolling")
	vp.queue_free()
	return {"errors":errors,"pointed_edge_click":events.size()==2,"keyboard_callback":events.size()==2,"unavailable_suppressed":events.size()==2,"modal_close_visible":close_visible,"modal_scrolls":scrolls.size()}

func collect_type(node:Node,kind:String,result:Array) -> void:
	if node.is_class(kind): result.append(node)
	for child in node.get_children(): collect_type(child,kind,result)
