extends SceneTree
## Configured-window popup content fitting, height caps and engine-native input.
const Fixture = preload("res://tests/helpers/reward_route_fixture.gd")
const Player = preload("res://tests/helpers/encounter_player.gd")
const Immediate = preload("res://scripts/ui/combat_presentation.gd")
const Settings = preload("res://scripts/audio/audio_settings.gd")
const OUT := "res://output/qa/popup-autofit"
var checks := 0
var failures := 0
var assertions: Array = []
var measurements: Array = []
var fit := 1.0

func _initialize(): call_deferred("run")
func check(ok: bool, description: String, evidence: Variant = null):
	checks += 1
	assertions.append({"pass":ok,"description":description,"evidence":evidence})
	if not ok:
		failures += 1
		push_error(description + (" " + str(evidence) if evidence != null else ""))
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.gui_embed_subwindows = true
	Input.use_accumulated_input = false
	Input.emulate_mouse_from_touch = true
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS and root.content_scale_size == Vector2i(720,1600), "Actual project canvas_items stretch stays enabled.")
	for dimensions in [Vector2i(450,1000),Vector2i(720,1600),Vector2i(360,640)]:
		if "--only-450" in OS.get_cmdline_user_args() and dimensions.x != 450: continue
		await exercise(dimensions)
		await saved_run_surfaces(dimensions)
	FileAccess.open(OUT.path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"assertions":assertions,"measurements":measurements,"scope":"Popup content growth up to 660 design pixels, wrapping before scrollbars, fixed footer allocation and approved Menu pixel regression. Real New Run, save failure/recovery, dynamic moderate/long content and open-popup resize. Actual root Window preserves 720x1600 logical canvas stretch. Direct render PNGs exclude letterbox bars: 360x640 window has 288x640 content with 36px side margins. Real engine touch-to-mouse input; isolated settings and unique RC028 saves. Rewards follow a genuine fixed-seed fixture victory. Intentional missing-encounter startup error exercises the real error dialog; its plain diagnostic is expected. No native build or physical-device claim."},"  ")+"\n")
	print("%d popup autofit checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func exercise(dimensions: Vector2i):
	root.size = dimensions
	await settle()
	var tag := "%dx%d" % [dimensions.x,dimensions.y]
	var area := root.get_final_transform() * root.get_visible_rect()
	fit = minf(1.0,minf(area.size.x/360.0,area.size.y/640.0))
	var app: Control = load("res://scenes/application.tscn").instantiate()
	app.settings_path = OUT.path_join("settings-"+tag+".cfg")
	app.save_path = OUT.path_join("save-"+tag+"-"+str(Time.get_ticks_usec())+".json")
	var settings: Dictionary = Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion = true
	Settings.save_values(settings,app.settings_path)
	root.add_child(app)
	await settle()
	app.run_state = Fixture.new_run(42)
	app.persistence_context = app.run_state.restore_context_for_tests()
	app.open_map()
	await settle()
	var map: Control = app.map_screen
	var route_before: Dictionary = app.run_state.snapshot()
	await tap(map.menu_button)
	measure(app._route_menu_panel, tag+" Menu", [app.route_menu_resume,app.route_menu_options,app.route_menu_collection,app.route_menu_store,app.route_menu_quit])
	await capture("menu-"+tag)
	if dimensions.x == 450:
		var reference := Image.load_from_file("res://output/qa/gameplay-menu/combat-menu-450x1000.png")
		var current := root.get_texture().get_image()
		reference.convert(Image.FORMAT_RGBA8)
		current.convert(Image.FORMAT_RGBA8)
		var crop := Rect2i(48,194,354,612)
		check(current.get_region(crop).get_data() == reference.get_region(crop).get_data(), "450x1000 Menu opaque content remains byte-identical to the approved large gameplay reference.")
	await tap(app.route_menu_options)
	measure(app.options.panel,tag+" Options",[app.options.close_button])
	await capture("options-"+tag)
	var values: Dictionary = app.audio_settings.duplicate(true)
	var slider: HSlider = app.options.sliders.music_volume
	await reveal(app.options.body_scroll,slider)
	check(pixel_rect(slider).size.y >= 68*fit-0.1,tag+" Music slider has the same physical target height as Menu.",pixel_rect(slider))
	await tap_fraction(slider,0.25)
	check(absf(app.audio_settings.music_volume-0.25)<0.08 and app.audio_settings.sfx_volume==values.sfx_volume,tag+" Native Music slider changes only Music volume.",app.audio_settings.music_volume)
	var toggle: Button = app.options.toggles.enabled
	await reveal(app.options.body_scroll,toggle)
	await tap(toggle)
	check(app.audio_settings.enabled != values.enabled,tag+" Native Sound toggle changes its value.")
	await tap(toggle)
	check(app.audio_settings.enabled == values.enabled,tag+" Native Sound toggle restores its original value.")
	await swipe(app.options.body_scroll,tag+" Options")
	await capture("options-scrolled-"+tag)
	await reveal(app.options.body_scroll,slider)
	slider.value = values.music_volume*100.0
	await tap(app.options.close_button)
	await tap(app.route_menu_collection)
	var collection: Control = app.collection_screen
	measure(collection.panel,tag+" Collection",[collection.close_button])
	await capture("collection-"+tag)
	await reveal(collection.body_scroll,collection.card_buttons[0])
	var list_offset: int = collection.body_scroll.scroll_vertical
	await tap(collection.card_buttons[0])
	check(collection.detail_visible,tag+" Native Collection card opens its detail popup.")
	measure(collection.panel,tag+" Collection detail",[collection.close_button])
	await capture("collection-detail-"+tag)
	await swipe(collection.body_scroll,tag+" Collection detail")
	await tap(collection.close_button)
	check(not collection.detail_visible and collection.visible and collection.body_scroll.scroll_vertical==list_offset,tag+" Detail Back restores the same Collection list and scroll.")
	await swipe(collection.body_scroll,tag+" Collection list")
	await capture("collection-scrolled-"+tag)
	await tap(collection.close_button)
	await tap(app.route_menu_resume)
	check(app.run_state.snapshot()==route_before and app.map_screen==map,tag+" Options and Collection inspection preserve the route and owned cards.")
	await tap(map.help_button)
	measure(map.inspection_panel,tag+" Map Guide",[map.inspection_close])
	await capture("map-guide-"+tag)
	await swipe(map.inspection_panel.get_meta("rc_body_scroll"),tag+" Map Guide")
	await capture("map-guide-scrolled-"+tag)
	await tap(map.inspection_close)
	var first: String = app.run_state.route_snapshot().nodes.filter(func(node):return node.state=="available")[0].id
	map.inspect_node(first)
	await settle()
	measure(map.inspection_panel,tag+" Room inspection",[map.inspection_action,map.inspection_close])
	await capture("room-inspection-"+tag)
	await tap(map.inspection_action)
	measure(app._confirmation_panel,tag+" Entry confirmation",[app.confirmation_confirm,app.confirmation_cancel])
	if dimensions.x != 360: check_body_fits(app._confirmation_panel,tag+" Entry confirmation")
	await capture("entry-confirmation-"+tag)
	await tap(app.confirmation_cancel)
	check(app.run_state.snapshot()==route_before,tag+" Entry Cancel leaves the visit unconsumed.")
	await tap(map.inspection_action)
	await tap(app.confirmation_confirm)
	var scene: Control = app.combat_scene
	check(scene!=null,tag+" Native confirmed entry attaches actual Combat.")
	if scene==null:
		app.queue_free()
		await settle()
		return
	scene._select_tool("straight")
	scene.page_scroll.scroll_vertical=100000
	await settle()
	var battle: Dictionary = scene.controller.snapshot()
	var owned: Dictionary = app.run_state.snapshot()
	var selected := [scene.selected_tool,scene.selected_uid,scene.selected_cell]
	var offset: int = scene.page_scroll.scroll_vertical
	await tap(scene.combat_navigation.buttons.guide)
	check(scene.dialog.visible,tag+" Native Combat Guide opens.")
	measure(scene.dialog.get_meta("rc_popup_panel"),tag+" Combat Guide",[scene.dialog.get_ok_button()])
	await capture("combat-guide-"+tag)
	await swipe(scene.guide_text.get_parent(),tag+" Combat Guide")
	await capture("combat-guide-scrolled-"+tag)
	await tap(scene.dialog.get_ok_button())
	check(not scene.dialog.visible and scene.page_scroll.scroll_vertical==offset,tag+" Native Guide OK closes and preserves Combat scroll.")
	scene._inspect_tool("straight")
	await settle()
	measure(scene.inspector_panel,tag+" Tool inspector",[scene.inspector_close])
	await capture("tool-inspector-"+tag)
	await swipe(scene.inspector_scroll,tag+" Tool inspector")
	await tap(scene.inspector_close)
	await reveal(scene.page_scroll,scene.turn_pass_button)
	offset=scene.page_scroll.scroll_vertical
	await tap(scene.turn_pass_button)
	measure(scene.inspector_panel,tag+" Pass confirmation",[scene.inspector_confirm_pass,scene.inspector_close])
	await capture("pass-confirmation-"+tag)
	await tap(scene.inspector_close)
	check(scene.page_scroll.scroll_vertical==offset,tag+" Native Pass Cancel preserves Combat scroll.")
	await reveal(scene.page_scroll,scene.combat_navigation.buttons.menu)
	offset=scene.page_scroll.scroll_vertical
	await tap(scene.combat_navigation.buttons.menu)
	await tap(app.route_menu_quit)
	measure(app._confirmation_panel,tag+" Quit confirmation",[app.confirmation_confirm,app.confirmation_cancel])
	if dimensions.x != 360: check_body_fits(app._confirmation_panel,tag+" Quit confirmation")
	await capture("quit-confirmation-"+tag)
	await tap(app.confirmation_cancel)
	await tap(app.route_menu_resume)
	check(scene.controller.snapshot()==battle and app.run_state.snapshot()==owned and [scene.selected_tool,scene.selected_uid,scene.selected_cell]==selected and scene.page_scroll.scroll_vertical==offset,
		tag+" Modal inspection and cancellation preserve battle, RNG, ownership, selection and underlying scroll.")
	scene.controller.set_presenter(Immediate.new())
	var player := Player.new()
	for turn in range(40):
		if scene.controller.snapshot().state!="playing":break
		if not player.play_turn(scene.controller):break
	await settle()
	check(app.run_state.snapshot().pending_result.get("outcome")=="victory",tag+" Ordinary fixed-seed fixture commands produce a genuine reward-bearing victory.")
	if app.run_state.snapshot().pending_result.get("outcome")=="victory":
		measure(app._confirmation_panel,tag+" Victory result",[app.result_reward_button,app.confirmation_confirm,app.confirmation_cancel])
		await capture("victory-result-"+tag)
		await tap(app.result_reward_button)
		var reward: Control = app.reward_screen
		var reward_before: Dictionary = app.run_state.snapshot()
		measure(reward.panel,tag+" Rewards",[reward.gold_button,reward.skip_button,reward.close_button])
		await capture("rewards-"+tag)
		await swipe(reward.scroll,tag+" Rewards")
		await capture("rewards-scrolled-"+tag)
		await tap(reward.close_button)
		check(app.run_state.snapshot()==reward_before,tag+" Native reward Close preserves all unresolved choices and RNG.")
		await tap(app.result_reward_button)
		var choose: Button = reward.choose_buttons.values()[0]
		await reveal(reward.scroll,choose)
		check(pixel_rect(choose).size.y>=68*fit-0.1,tag+" Scrolled reward choice keeps the Menu physical target size.")
		await tap(choose)
		check(app.run_state.pending_reward().resolution=="chosen",tag+" Native reward choice commits through its scaled control.")
		var gold_before: int = app.run_state.snapshot().gold
		await tap(reward.gold_button)
		check(app.run_state.snapshot().gold==gold_before+7,tag+" Native fixture Gold action commits its configured payout once.")
		measure(reward.panel,tag+" Reward receipt",[reward.close_button])
		await capture("reward-receipt-"+tag)
		await tap(reward.close_button)
	app.queue_free()
	await settle()
	await error_surface(tag)
	await record_surface(tag)

func saved_run_surfaces(dimensions: Vector2i):
	var tag := "%dx%d" % [dimensions.x,dimensions.y]
	var path := OUT.path_join("recovery-"+tag+"-"+str(Time.get_ticks_usec())+".json")
	var app := fresh_shell(path)
	await settle()
	app.request_new_run(42)
	await settle()
	check(app.run_state!=null and app.map_screen!=null and FileAccess.file_exists(path),tag+" New Run fixture creates a real isolated saved run.")
	app.close_map()
	await settle()
	var original: Dictionary=app.run_state.export_save()
	var committed := FileAccess.get_file_as_string(path)
	await tap(app.new_run_button)
	check(app.confirmation.visible and app._pending_action=="new_run",tag+" Native New Run opens the real replacement confirmation.")
	measure(app._confirmation_panel,tag+" New Run replacement",[app.confirmation_confirm,app.confirmation_cancel])
	if dimensions.x != 360: check_body_fits(app._confirmation_panel,tag+" New Run replacement")
	await capture("replacement-confirmation-"+tag)
	await tap(app.confirmation_cancel)
	check(app.run_state.export_save()==original and FileAccess.get_file_as_string(path)==committed,tag+" Native replacement Cancel preserves the exact saved run and disk bytes.")
	await dynamic_content(app,dimensions,tag)
	app.save_store.failure_point="replace"
	app.request_new_run(43)
	await settle()
	await tap(app.confirmation_confirm)
	check(app._pending_action=="retry_save",tag+" Real injected save failure opens its actionable confirmation.")
	measure(app._confirmation_panel,tag+" Save failure",[app.confirmation_confirm,app.confirmation_cancel,app.recovery_retry_button])
	await capture("save-failure-"+tag)
	await swipe(app._confirmation_panel.get_meta("rc_body_scroll"),tag+" Save failure")
	await capture("save-failure-scrolled-"+tag)
	app.save_store.failure_point=""
	await tap(app.confirmation_confirm)
	check(app.map_screen!=null and app._failed_transaction.is_empty(),tag+" Native Retry saves the retained replacement once.")
	app.queue_free()
	await settle()
	FileAccess.open(path,FileAccess.WRITE).store_string("{\"truncated\":")
	app=fresh_shell(path)
	await settle()
	await tap(app.recovery_button)
	check(app.confirmation.visible and app._recovery_available,tag+" Native recovery opens with a validated previous save.")
	measure(app._confirmation_panel,tag+" Save recovery",[app.confirmation_confirm,app.confirmation_cancel,app.recovery_retry_button])
	await capture("recovery-confirmation-"+tag)
	await swipe(app._confirmation_panel.get_meta("rc_body_scroll"),tag+" Save recovery")
	await capture("recovery-scrolled-"+tag)
	await tap(app.confirmation_confirm)
	check(app.run_state!=null and app.run_state.export_save()==original and not app.confirmation.visible,tag+" Native Recover restores the exact original run through the capped popup.")
	app.queue_free()
	await settle()

func fresh_shell(path: String) -> Control:
	var app: Control=load("res://scenes/application.tscn").instantiate()
	app.save_path=path
	app.settings_path=path+".settings.cfg"
	var settings: Dictionary=Settings.DEFAULTS.duplicate(true)
	settings.reduced_motion=true
	Settings.save_values(settings,app.settings_path)
	root.add_child(app)
	return app

func dynamic_content(app: Control,dimensions: Vector2i,tag: String):
	var panel: PanelContainer=app._confirmation_panel
	var scroll: ScrollContainer=panel.get_meta("rc_body_scroll")
	app._show_confirmation("qa_layout","Ready to continue","Inspection keeps the saved run unchanged.","Continue",false)
	await settle()
	var short_height:=pixel_rect(panel).size.y
	check_body_fits(panel,tag+" Short dynamic confirmation")
	var moderate := "Inspection keeps the saved run unchanged. Read every instruction before continuing."
	app._show_confirmation("qa_layout","Content needs more room",moderate+"\n\n"+moderate+"\n\n"+moderate,"Continue",false)
	await settle()
	measure(panel,tag+" Moderate confirmation",[app.confirmation_confirm,app.confirmation_cancel])
	if dimensions.x!=360:
		check_body_fits(panel,tag+" Moderate confirmation")
		check(pixel_rect(panel).size.y>short_height and pixel_rect(panel).size.y<660*fit,tag+" Moderate content grows only as far as needed below the Menu cap.",pixel_rect(panel))
	await capture("dynamic-moderate-"+tag)
	var paragraphs: Array[String]=[]
	for index in range(12):paragraphs.append("Paragraph %d. Inspection keeps the saved run unchanged. All remaining instructions must remain reachable by scrolling." % [index+1])
	app._show_confirmation("qa_layout","Read the complete saved progress explanation", "\n\n".join(paragraphs),"Continue after reading",false)
	app.recovery_retry_button.text="Reload saved progress"
	app.recovery_retry_button.show()
	app._fit_confirmation()
	await settle()
	measure(panel,tag+" Dynamic long confirmation",[app.confirmation_confirm,app.confirmation_cancel,app.recovery_retry_button])
	var bar:=scroll.get_v_scroll_bar()
	check(absf(pixel_rect(panel).size.y-660*fit)<0.8 and bar.max_value>bar.page,tag+" Long content grows to the Menu cap and retains useful scrolling.",pixel_rect(panel))
	await capture("dynamic-long-"+tag)
	for swipe_index in range(4):await swipe(scroll,tag+" Dynamic long body")
	check(scroll.scroll_vertical>=bar.max_value-bar.page-1,tag+" Native scrolling reaches the last paragraph without moving fixed actions.")
	await capture("dynamic-long-scrolled-"+tag)
	if dimensions.x==450:
		root.size=Vector2i(360,640)
		await settle()
		fit=0.8
		measure(panel,"450x1000 resized narrow long confirmation",[app.confirmation_confirm,app.confirmation_cancel,app.recovery_retry_button])
		await capture("dynamic-resized-narrow")
		root.size=dimensions
		await settle()
		fit=1.0
		measure(panel,"450x1000 restored long confirmation",[app.confirmation_confirm,app.confirmation_cancel,app.recovery_retry_button])
	app._show_confirmation("qa_layout","Ready to continue","Inspection keeps the saved run unchanged.","Continue",false)
	await settle()
	check_body_fits(panel,tag+" Restored short confirmation")
	check(absf(pixel_rect(panel).size.y-short_height)<0.8 and scroll.scroll_vertical==0,tag+" Replacing a long title/body/action set restores the short height and scroll origin.")
	await capture("dynamic-short-restored-"+tag)
	await tap(app.confirmation_cancel)

func check_body_fits(panel: PanelContainer,label: String):
	var scroll: ScrollContainer=panel.get_meta("rc_body_scroll")
	var bar:=scroll.get_v_scroll_bar()
	check(bar.max_value<=bar.page+1 and not bar.visible and pixel_rect(scroll).grow(0.8).encloses(pixel_rect(scroll.get_child(0))),label+" shows its entire body without clipping or an unnecessary scrollbar.",{"body":pixel_rect(scroll.get_child(0)),"viewport":pixel_rect(scroll),"scroll_max":bar.max_value,"scroll_page":bar.page})

func record_surface(tag: String):
	var scene: Control=load("res://scenes/main.tscn").instantiate()
	scene.experiment_mode=true
	scene.setup_path="res://data/encounter.json"
	scene.experiment_record_path=OUT.path_join("local-record-"+tag+".json")
	scene.settings_path=OUT.path_join("record-settings-"+tag+".cfg")
	Settings.save_values(Settings.DEFAULTS,scene.settings_path)
	root.add_child(scene)
	await settle()
	var before: Dictionary=scene.controller.snapshot()
	scene._open_menu()
	await settle()
	measure(scene.menu.get_meta("rc_popup_panel"),tag+" Development Menu",[scene.menu.get_cancel_button(),scene.options_button])
	await capture("development-menu-"+tag)
	await swipe(scene.menu.get_meta("rc_body_scroll"),tag+" Development Menu")
	await capture("development-menu-scrolled-"+tag)
	await tap(scene.menu.get_cancel_button())
	check(not scene.menu.visible and scene.controller.snapshot()==before,tag+" Native development Menu Resume preserves the battle after scrolling extra actions.")
	scene._inspect_experiment_record()
	await settle()
	check(scene.record_dialog.visible and scene.record_error.is_empty(),tag+" Actual local record popup opens after a successful isolated export.")
	measure(scene.record_dialog.get_meta("rc_popup_panel"),tag+" Local record",[scene.record_dialog.get_ok_button()])
	await capture("local-record-"+tag)
	await tap(scene.record_dialog.get_ok_button())
	check(not scene.record_dialog.visible and scene.controller.snapshot()==before,tag+" Native record OK closes without changing the battle.")
	scene.queue_free()
	await settle()

func error_surface(tag: String):
	var scene: Control=load("res://scenes/main.tscn").instantiate()
	scene.setup_path="res://tests/fixtures/popup-missing-encounter.json"
	scene.settings_path=OUT.path_join("error-"+tag+".cfg")
	Settings.save_values(Settings.DEFAULTS,scene.settings_path)
	root.add_child(scene)
	await settle()
	check(scene.controller==null and not scene.startup_error.is_empty(),tag+" Intentional missing content reaches the actual startup error state.")
	scene._show_map()
	await settle()
	check(scene.dialog.visible and scene.dialog.title=="Map unavailable",tag+" Actual startup error opens its native popup.")
	measure(scene.dialog.get_meta("rc_popup_panel"),tag+" Startup error",[scene.dialog.get_ok_button()])
	if tag!="360x640":check_body_fits(scene.dialog.get_meta("rc_popup_panel"),tag+" Startup error")
	await capture("startup-error-"+tag)
	await tap(scene.dialog.get_ok_button())
	check(not scene.dialog.visible,tag+" Native error OK closes its scaled popup.")
	scene.queue_free()
	await settle()

func canvas_transform(control: Control) -> Transform2D:
	var transform:=root.get_final_transform()
	var window:=control.get_window()
	if window!=root:
		transform*=Transform2D(0.0,Vector2(window.position))*window.get_final_transform()
	return transform*control.get_global_transform_with_canvas()
func pixel_rect(control: Control) -> Rect2:
	return canvas_transform(control)*Rect2(Vector2.ZERO,control.size)
func measure(panel: PanelContainer,label: String,actions: Array):
	var bounds:=pixel_rect(panel)
	var area:=root.get_final_transform()*root.get_visible_rect()
	var content:=pixel_rect(panel.get_child(0))
	var padding:=[content.position.x-bounds.position.x,content.position.y-bounds.position.y,bounds.end.x-content.end.x,bounds.end.y-content.end.y]
	var scroll_geometry: Dictionary={}
	if panel.has_meta("rc_body_scroll"):
		var body_scroll: ScrollContainer=panel.get_meta("rc_body_scroll")
		var viewport_rect:=pixel_rect(body_scroll)
		var scrollbar:=body_scroll.get_v_scroll_bar()
		var right_edge:=pixel_rect(scrollbar).position.x if scrollbar.visible else viewport_rect.end.x
		var body_rect:=pixel_rect(body_scroll.get_child(0))
		scroll_geometry={"viewport":viewport_rect,"body":body_rect,"scrollbar_visible":scrollbar.visible,"readable_right_edge":right_edge}
		check(body_rect.end.x<=right_edge+0.8,label+" wraps content before the scrollbar without horizontal clipping.",scroll_geometry)
	check(panel.is_visible_in_tree() and area.grow(0.8).encloses(bounds),label+" fits inside the actual rendered content area.",bounds)
	check(bounds.size.y<=660*fit+0.8,label+" never exceeds the shared Menu height cap.",bounds.size.y)
	check(absf(padding[0]-36*fit)<0.8 and absf(padding[2]-36*fit)<0.8 and absf(padding[1]-40*fit)<0.8 and absf(padding[3]-40*fit)<0.8,label+" matches Menu content padding at its physical fit scale.",padding)
	var bad_fonts: Array=[]
	var text_count:=0
	for node in panel.find_children("*","Control",true,false):
		if not node.is_visible_in_tree():continue
		if not (node is Label or node is Button or node is LineEdit or node is TextEdit):continue
		if node is Button and node.text.is_empty():continue
		var expected:=18.0 if node is Button else 22.0 if node.theme_type_variation=="RCTitle" else 16.0
		var actual:float=node.get_theme_font_size("font_size")*canvas_transform(node).get_scale().y
		text_count+=1
		if absf(actual-expected*fit)>0.08:bad_fonts.append({"text":node.text.left(60),"actual":actual,"expected":expected*fit})
	check(text_count>0 and bad_fonts.is_empty(),label+" uses Menu title22/body16/action18 physical typography.",bad_fonts)
	var footer_bottom:=0.0
	for button in actions:
		if not button.is_visible_in_tree():continue
		var rect:=pixel_rect(button)
		footer_bottom=maxf(footer_bottom,rect.end.y)
		check(area.grow(0.8).encloses(rect) and rect.size.y>=68*fit-0.1,label+" keeps a reachable Menu-size fixed action: "+button.text,rect)
	if footer_bottom>0:
		check(absf(bounds.end.y-footer_bottom-40*fit)<0.8,label+" gives grown space to its content while keeping the footer at the bottom inset.",{"panel_bottom":bounds.end.y,"footer_bottom":footer_bottom,"fit":fit})
	measurements.append({"label":label,"physical_window":root.size,"content_image_size":root.get_texture().get_image().get_size(),"letterbox_origin":root.get_final_transform().origin,"fit_scale":fit,"panel":bounds,"padding_ltrb":padding,"text_count":text_count,"font_mismatches":bad_fonts,"scroll_geometry":scroll_geometry})
func tap(control: Control):await tap_point(pixel_rect(control).get_center())
func tap_fraction(control: Control,fraction: float):
	var rect:=pixel_rect(control)
	await tap_point(Vector2(rect.position.x+rect.size.x*fraction,rect.get_center().y))
func tap_point(point: Vector2):
	for pressed in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.position=point
		event.pressed=pressed
		Input.parse_input_event(event)
	await settle()
func reveal(scroll: ScrollContainer,control: Control):
	scroll.ensure_control_visible(control)
	await settle()
func swipe(scroll: ScrollContainer,label: String):
	var bar:=scroll.get_v_scroll_bar()
	if bar.max_value<=bar.page:return
	var before:=scroll.scroll_vertical
	var rect:=pixel_rect(scroll)
	var point:=Vector2(rect.get_center().x,rect.end.y-8)
	var travel:=minf(150,rect.size.y-16)
	for step in range(10):
		var press:=InputEventScreenTouch.new()
		press.position=point
		press.pressed=true
		Input.parse_input_event(press)
		var drag:=InputEventScreenDrag.new()
		drag.position=point-Vector2(0,travel)
		drag.relative=Vector2(0,-travel)
		Input.parse_input_event(drag)
		var release:=InputEventScreenTouch.new()
		release.position=drag.position
		release.pressed=false
		Input.parse_input_event(release)
		await process_frame
	await settle()
	check(scroll.scroll_vertical>before or scroll.scroll_vertical>=bar.max_value-bar.page-1,label+" accepts native scrolling through its overflow.",scroll.scroll_vertical)
func settle():
	for frame in 10:await process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
func capture(name: String):
	check(DisplayServer.get_name()!="headless","Popup capture uses the real renderer.")
	if DisplayServer.get_name()!="headless":check(root.get_texture().get_image().save_png(OUT.path_join(name+".png"))==OK,name+" direct root render captured.")
