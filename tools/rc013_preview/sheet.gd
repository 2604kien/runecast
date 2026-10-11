extends Control

const Ui = preload("res://scenes/ui/theme/components.gd")
var mode := "components"
var canvas_size := Vector2(450,1000)
var scroll_fraction := 0.0
var logical_size: Vector2
var scroll: ScrollContainer
var column: VBoxContainer
var specimen: Control
var hand_scroll: ScrollContainer
var hand_end := false
var issues: Array = []
var checks: Array = []
var menu_panel: PanelContainer
var menu_content: VBoxContainer
var menu_clearance_checks: Array = []

func _ready() -> void:
	theme = load("res://assets/ui/rune_cast_theme.tres")
	size = canvas_size
	var factor := 1.6 if canvas_size.x == 720 else 1.0
	logical_size = canvas_size / factor
	var page := Control.new()
	page.size = logical_size
	page.scale = Vector2.ONE * factor
	add_child(page)
	var bg := ColorRect.new()
	bg.color = Color("0c1524")
	bg.size = logical_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(14,14)
	scroll.size = logical_size - Vector2(28,28)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	match mode:
		"components": components()
		"states": states()
		"cards": cards()
		"home-save", "home-empty", "home-invalid": home()
		"menu-open", "menu-locked": menu(page)
		"options": options()
		"map": map_states()
		"replace", "dialog": dialog(page)
		"wordmark": wordmark_sizes()
	await get_tree().process_frame
	await get_tree().process_frame
	if scroll_fraction > 0:
		scroll.scroll_vertical = int(maxf(0, column.size.y-scroll.size.y)*scroll_fraction)
	if hand_end and hand_scroll:
		hand_scroll.scroll_horizontal=100000
	await get_tree().process_frame

func heading(title:String, subtitle:String="") -> void:
	column.add_child(Ui.label(title,"title",24))
	if not subtitle.is_empty(): column.add_child(Ui.label(subtitle,"body",14))

func section(title:String) -> void:
	column.add_child(Ui.label(title,"title",19))

func row(parent:Node=null) -> HBoxContainer:
	if parent==null: parent=column
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation",8)
	parent.add_child(r)
	return r

func full(control:Control, parent:Node=null) -> Control:
	if parent==null: parent=column
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	return control

func components() -> void:
	heading("Rune Cast · UI theme", "Painted components / live presentation specimen")
	var top := row()
	full(Ui.status_bar("Health",30,30),top)
	full(Ui.status_bar("Energy",3,3,"energy"),top)
	var pause := Ui.navigation("pause", "Pause")
	pause.custom_minimum_size.x = 64
	top.add_child(pause)
	section("Clean board · exact edge ports")
	var board := GridContainer.new()
	board.columns = 4
	board.add_theme_constant_override("h_separation",6)
	board.add_theme_constant_override("v_separation",6)
	column.add_child(board)
	var extent := floorf((logical_size.x - 50 - 18)/4.0)
	var glyphs := ["begin","spark","split","corner","","","straight","straight","","","join","corner","","","end",""]
	for i in 16:
		var endpoint := String(glyphs[i]).to_upper() if glyphs[i] in ["begin","end"] else ""
		var s := Ui.socket(glyphs[i],{"powered":i in [0,1,2,3,6,7,10,11,14]},endpoint,extent,1 if i in [6,7] else 0)
		board.add_child(s)
	column.add_child(Ui.label("Only BEGIN / END are labelled. No board values or badges.","body",13))
	section("Finite wiring stock")
	var tools := GridContainer.new()
	tools.columns = 2
	tools.add_theme_constant_override("h_separation",8)
	tools.add_theme_constant_override("v_separation",8)
	column.add_child(tools)
	for data in [["straight","Straight",4,6],["corner","Corner",0,2],["split","Split",0,1],["join","Join",0,1]]:
		full(Ui.stock_tool(data[0],data[1],data[2],data[3]),tools)
	var edits := row()
	for name in ["remove","rotate"]: full(Ui.navigation(name,name.capitalize()),edits)
	column.add_child(Ui.label("Spark placed. Two energy committed.","body",14))
	section("Detailed hand / live piles")
	var piles := row()
	full(Ui.pile("draw",5,Vector2(120,148)),piles)
	full(Ui.pile("discard",0,Vector2(120,148)),piles)
	hand()
	section("Permanent forecast")
	full(Ui.forecast({"damage":6,"shield":0,"cost":3,"incoming":8},2))
	full(Ui.cast_button({"valid":true,"affordable":true,"cost":3}))
	var nav := GridContainer.new()
	nav.columns=2
	column.add_child(nav)
	for name in ["menu","map","guide","sound_on"]: full(Ui.navigation(name,"Sound" if name=="sound_on" else name.capitalize()),nav)
	column.add_child(Ui.label("Samples use the 6 / 2 / 1 / 1 kit. Presentation only.","body",13))

func hand(stress:bool=false) -> void:
	var strip := ScrollContainer.new()
	hand_scroll=strip
	strip.custom_minimum_size.y = 350
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(strip)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation",10)
	strip.add_child(r)
	var samples := [{"name":"Spark","cost":2,"icon":"spark","type":"RUNE","description":"Add 6 damage.","value":"6 damage"},{"name":"Shield","cost":1,"icon":"shield","kind":"shield","type":"RUNE","description":"Add 5 shield.","value":"5 shield"},{"name":"Focus","cost":1,"icon":"focus","kind":"technique","type":"TECHNIQUE","description":"Draw 2 cards.","value":"Draw 2"},{"name":"Conjure Spark","cost":0,"icon":"conjure","kind":"technique","type":"TECHNIQUE","description":"Create 1 Free Spark in your hand.","value":"Create 1"}]
	var order := [0,1,3,0,1,2,2,3] if stress else [0,1,2]
	for i in order:
		var d:Dictionary=samples[i]
		r.add_child(Ui.card(d,{},186))

func states() -> void:
	heading("Material & state gallery","Shared paint · independent shape feedback")
	for name in ["normal","pressed","focused","selected","disabled","invalid","unavailable","focused + selected","focused + unavailable"]:
		column.add_child(Ui.label(name.capitalize(),"body",14))
		var state: Dictionary = {}
		for key in name.split(" + "): state[key]=true
		full(Ui.action("Continue",true,Vector2(200,54),state))
		full(Ui.action("Options",false,Vector2(200,48),state))
	section("Cast availability")
	for d in [{"valid":true,"affordable":true,"cost":3},{"valid":false,"affordable":true,"cost":0,"reason":"Connect BEGIN to END."},{"valid":true,"affordable":false,"cost":4,"reason":"Needs 4 energy; 3 available."}]: full(Ui.cast_button(d))
	section("Sound states")
	var sound := row()
	full(Ui.navigation("sound_on","Sound on"),sound)
	full(Ui.navigation("sound_off","Sound off"),sound)
	section("Board states / non-colour cues")
	var grid := GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	column.add_child(grid)
	for state in [{},{"selected":true},{"focused":true},{"powered":true},{"invalid":true},{"unavailable":true},{"selected":true,"focused":true},{"unavailable":true,"focused":true},{"disabled":true}]:
		var box := VBoxContainer.new()
		grid.add_child(box)
		box.add_child(Ui.socket("spark",state,"",72))
		box.add_child(Ui.label("Normal" if state.is_empty() else " + ".join(state.keys()),"body",12))

func cards() -> void:
	heading("Detailed cards","Eight-card hand stress specimen · scroll horizontally.")
	hand(true)
	section("Temporary / upgraded / unavailable")
	for d in [{"name":"Free Spark","cost":0,"icon":"spark","type":"RUNE","description":"Add 6 damage. Expires at the end of this turn.","value":"6 damage","temporary":true},{"name":"Bright Spark","cost":2,"icon":"spark","type":"RUNE","description":"Add 8 damage. Proposed upgrade presentation.","value":"8 damage","upgraded":true},{"name":"Conjure Spark — long label specimen","cost":0,"icon":"conjure","kind":"technique","type":"TECHNIQUE","description":"Create a Free Spark in your hand. This deliberately long explanation demonstrates the reusable detailed card layout without hiding its cost, type, value or lifetime text.","value":"Create 1"}]:
		full(Ui.card(d,{"focused":true,"selected":true} if d.get("temporary",false) else {"unavailable":true} if d.get("icon")=="conjure" else {},logical_size.x-56))
	section("Empty and populated piles")
	var r := row()
	full(Ui.pile("draw",0,Vector2(110,108)),r)
	full(Ui.pile("discard",5,Vector2(110,108)),r)

func logo(parent:Node, width:float) -> void:
	var img := TextureRect.new()
	img.texture = load("res://assets/ui/wordmark.png")
	img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size=Vector2(width,width*0.42)
	img.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(img)

func home() -> void:
	logo(column, logical_size.x-40)
	heading("Home", "Isolated screen state · tower art is RC-015")
	var spacer := Control.new()
	spacer.custom_minimum_size.y=42 if logical_size.x>400 else 16
	column.add_child(spacer)
	var can_continue := mode=="home-save"
	var copy := "Ashen Crypt · Floor 1\n30 / 30 health · saved run available" if can_continue else "No saved run yet. Start a new journey." if mode=="home-empty" else "This save could not be read. Start a new run or return later."
	full(Ui.label(copy,"location",18))
	full(Ui.action("Continue",true,Vector2(240,64),{"unavailable":not can_continue}))
	full(Ui.action("New Run",false,Vector2(240,64)))
	full(Ui.action("Options",false,Vector2(240,64)))
	column.add_child(Ui.label("New Run asks before replacing an available save.","body",14))

func menu(page:Control) -> void:
	heading("Menu overlay specimen","Store access is separate from shop rooms." if mode=="menu-open" else "Unavailable-state example; access rules are not yet specified.")
	for i in 4: full(Ui.action("Floor 1 · Ashen Crypt",false,Vector2(200,100)))
	var scrim := Panel.new()
	scrim.add_theme_stylebox_override("panel",load("res://assets/ui/scrim.tres"))
	scrim.size=logical_size
	scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(scrim)
	var panel := PanelContainer.new()
	panel.theme_type_variation="RCMenu"
	menu_panel=panel
	panel.position=Vector2(22,92)
	panel.size=Vector2(logical_size.x-44,0)
	page.add_child(panel)
	var content := VBoxContainer.new()
	menu_content=content
	content.add_theme_constant_override("separation",14)
	panel.add_child(content)
	var title := Ui.label("MENU","title",28)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	for name in ["Resume","Options","Store","Quit"]:
		full(Ui.action(name,name=="Resume",Vector2(200,56),{"unavailable":name=="Store" and mode=="menu-locked"}),content)
		if name=="Store" and mode=="menu-locked": content.add_child(Ui.label("Store is currently unavailable.","body",14))

func options() -> void:
	heading("Options", "Shared settings · preview values")
	full(Ui.settings_toggle("Sound",true))
	full(Ui.settings_toggle("Sound",false))
	full(Ui.settings_slider("Music volume",70))
	full(Ui.settings_slider("Effects volume",85))
	full(Ui.settings_toggle("Reduced motion",true))
	full(Ui.settings_toggle("High contrast",false))
	full(Ui.status_bar("Health",18,30))
	full(Ui.status_bar("Energy",0,3,"energy"))
	full(Ui.status_bar("Energy",3,3,"energy"))
	full(Ui.action("Close",false,Vector2(180,52),{"focused":true}))
	column.add_child(Ui.label("Settings callbacks belong to the screen. These controls do not save preferences or change audio buses.","body",14))

func map_states() -> void:
	heading("Map node treatments", "Neutral glyph samples · route content is RC-041")
	var panel := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color=Color("e4cf9f")
	for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: paper.set_content_margin(edge,18)
	panel.add_theme_stylebox_override("panel",paper)
	column.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",22)
	panel.add_child(v)
	for state in ["current","available","completed","locked"]:
		var r := row(v)
		r.add_child(Ui.map_node(state,"spark",78))
		var l := Ui.label(state.capitalize(),"body",18)
		l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		l.add_theme_color_override("font_color",Color("152333"))
		l.add_theme_constant_override("outline_size",0)
		l.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		r.add_child(l)
	column.add_child(Ui.label("Turquoise pointer, gold ring, completion check and barred lock remain distinct without relying on colour alone.","body",15))
	full(Ui.action("Close",false,Vector2(160,52)))

func dialog(page:Control) -> void:
	heading("Confirmation" if mode=="replace" else "Scrollable detail", "Fixed footer · body scrolls independently")
	var dim := ColorRect.new()
	dim.color=Color(0.01,0.02,0.05,0.58)
	dim.size=logical_size
	dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(dim)
	var body := "A run is already saved in Ashen Crypt. Starting a new run replaces that save.\n\nKeep playing your current run, or confirm that you want to start again."
	if mode=="dialog": body="Conjure Spark\nCost 0 · Technique\nCreate 1 Free Spark in your hand.\n\nFree Spark\nCost 0 · Rune · 6 damage\nExpires at the end of this turn.\n\n" + "Long detail text remains readable within its own scrolling body. Labels and values remain live. Selection and focused states can coexist.\n\n".repeat(8)
	var h := minf(600,logical_size.y-110)
	specimen=Ui.modal("Replace saved run?" if mode=="replace" else "Card details",body,logical_size.x-32,h,"Start New Run" if mode=="replace" else "")
	specimen.position=Vector2(16,76)
	page.add_child(specimen)

func wordmark_sizes() -> void:
	heading("Rune Cast wordmark","Separate identity asset · ordinary labels stay live")
	logo(column,logical_size.x-40)
	section("Compact header / 200 px")
	logo(column,200)
	section("Live text fallback")
	column.add_child(Ui.label("Rune Cast","title",28))
	column.add_child(Ui.label("Custom editable serif paths and geometric crest; follows the approved Home direction without identifying its unknown typeface.","body",14))

func inspect_layout(node:Node=self) -> void:
	if node==self and menu_panel:
		inspect_menu_clearance()
	if node is Label and node.is_visible_in_tree():
		var l:Label=node
		var overflow := l.size.y+1 < l.get_minimum_size().y
		if overflow: issues.append("Clipped label: "+l.text)
		var ancestor:Node=l.get_parent()
		while ancestor!=null and ancestor!=self:
			if ancestor is ScrollContainer: break
			if ancestor is BaseButton or ancestor is PanelContainer:
				if not ancestor.get_global_rect().grow(1).encloses(l.get_global_rect()):
					issues.append("Text leaves its containing surface: "+l.text)
			ancestor=ancestor.get_parent()
		checks.append({"text":l.text,"size":[l.size.x,l.size.y],"minimum":[l.get_minimum_size().x,l.get_minimum_size().y],"font_size":l.get_theme_font_size("font_size"),"overflow":overflow})
	if node is BaseButton and node.is_visible_in_tree():
		if node.size.x<44 or node.size.y<44: issues.append("Small target: "+node.name+" "+str(node.size))
	for child in node.get_children(): inspect_layout(child)

func inspect_menu_clearance() -> void:
	# The painted bezel occupies 24px; require a visible 8px gutter beyond it.
	var safe := Rect2(Vector2(32,32),menu_panel.size-Vector2(64,64))
	if not Rect2(Vector2.ZERO,logical_size).encloses(menu_panel.get_rect()):
		issues.append("Menu frame leaves the viewport")
	for child in menu_content.get_children():
		if not child is Control: continue
		var rect := Rect2(menu_content.position+child.position,child.size)
		var caption:String=child.text if child is Label or child is BaseButton else str(child.name)
		var clearances := [rect.position.x-24,rect.position.y-24,menu_panel.size.x-rect.end.x-24,menu_panel.size.y-rect.end.y-24]
		var passed := safe.grow(0.01).encloses(rect)
		menu_clearance_checks.append({"control":caption,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"clearance_ltrb":clearances,"passed":passed})
		if not passed: issues.append("Menu content touches painted border: "+caption)
