extends Node2D

var mode := "symbols"
var canvas_size := Vector2(1200,1390)
var issues: Array = []
var text_checks := 0
var font_report: Dictionary = {}
var texture_report: Dictionary = {}
var fonts: Dictionary = {}
var textures: Dictionary = {}
var cream := Color("fff0c5")
var gold := Color("edbc66")
var indigo := Color("102033")
var ink := Color("111b27")
var teal := Color("58e8dc")
var names := ["begin","end","straight","corner","split","join","spark","shield","focus","conjure","temporary_marker","remove","rotate","menu","map","guide","sound_on","sound_off","health","energy","attack","draw_pile","discard_pile","pause"]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for pair in [["labels","ui/labels"],["location","ui/location"],["title","display/title"]]:
		var f = load("res://assets/fonts/"+pair[1]+".tres")
		if f == null:
			issues.append("Font failed " + pair[0])
			return
		fonts[pair[0]] = f
		font_report[pair[0]] = {"family":f.get_font_name(),"variation":str(f.variation_opentype),"base":f.base_font.resource_path,"system_fallback":f.base_font.allow_system_fallback}
		if f.get_font_name() != "Noto Serif": issues.append("Unexpected font: "+f.get_font_name())
	for n in names:
		var folder := "resources/"
		if n in ["begin","end","straight","corner","split","join"]: folder = "circuit/"
		elif n in ["spark","shield","focus","conjure"]: folder = "runes/core/"
		elif n in ["menu","map","guide","sound_on","sound_off"]: folder = "navigation/"
		elif n in ["remove","rotate"]: folder = "editing/"
		elif n == "temporary_marker": folder = ""
		var t = load("res://assets/icons/"+folder+n+".svg")
		if t == null:
			issues.append("Missing SVG " + n)
			continue
		textures[n] = t
		var bitmap:Image = t.get_image()
		var rotations:Array = []
		for turn in 4:
			var edges:Array = []
			for side in 4:
				for pixel in bitmap.get_width():
					var p := Vector2i(pixel,0) if side==0 else Vector2i(bitmap.get_width()-1,pixel) if side==1 else Vector2i(pixel,bitmap.get_height()-1) if side==2 else Vector2i(0,pixel)
					if bitmap.get_pixelv(p).a > 0.05:
						edges.append(side)
						break
			var expected:Array = []
			if n == "straight": expected = [(1+turn)%4,(3+turn)%4]
			elif n == "corner": expected = [(2+turn)%4,(3+turn)%4]
			expected.sort()
			if edges != expected: issues.append("Imported edge mismatch "+n+" turn="+str(turn)+" "+str(edges))
			rotations.append({"turn":turn,"edge_indices":edges,"expected":expected})
			bitmap.rotate_90(CLOCKWISE)
		texture_report[n] = {"width":t.get_width(),"height":t.get_height(),"mipmaps":bitmap.has_mipmaps(),"alpha_bounds":str(bitmap.get_used_rect()),"quarter_turn_edges":rotations}
		if t.get_width() != 256 or t.get_height() != 256: issues.append("Unexpected raster size " + n)
	for n in ["board-stone","parchment","amber","navy"]:
		textures[n] = load("res://materials/"+n+".png")
	queue_redraw()

func txt(x:float,y:float,s:String,fs:int=20,role:String="labels",color:Color=Color("fff0c5"),limit:float=-1) -> void:
	var f: FontVariation = fonts[role]
	var extent := f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
	if limit < 0: limit = canvas_size.x-x-18
	if extent.x > limit+0.5: issues.append("Text width "+s+" "+str(extent.x)+" > "+str(limit))
	if y-f.get_ascent(fs) < -1 or y+f.get_descent(fs) > canvas_size.y: issues.append("Text vertical clipping: "+s)
	for c in s:
		if not f.base_font.has_char(c.unicode_at(0)): issues.append("Uncovered glyph "+c)
	text_checks += 1
	draw_string_outline(f,Vector2(x,y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,2,ink)
	draw_string(f,Vector2(x,y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func box(r:Rect2,fill:Color=Color("172c41"),border:Color=Color("8f7041")) -> void:
	draw_rect(r,fill)
	draw_rect(r,border,false,1.5)

func icon(n:String,x:float,y:float,size_:float,turn:int=0,mono:bool=false,tint:Color=Color.WHITE) -> void:
	if not textures.has(n): return
	var t:Texture2D = textures[n]
	if mono:
		var tr := Sprite2D.new()
		tr.texture = t
		tr.position = Vector2(x,y)
		tr.centered = false
		tr.scale = Vector2.ONE * size_ / float(t.get_width())
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/icons/symbol_tint.gdshader")
		mat.set_shader_parameter("appearance_mode",1)
		mat.set_shader_parameter("ink",tint)
		if tint == ink: mat.set_shader_parameter("monochrome_paper",Color("e8d5aa"))
		tr.material = mat
		add_child(tr)
	else:
		draw_set_transform(Vector2(x+size_/2,y+size_/2),turn*PI/2,Vector2.ONE)
		draw_texture_rect(t,Rect2(-size_/2,-size_/2,size_,size_),false,tint)
		draw_set_transform(Vector2.ZERO)

func material(n:String,r:Rect2) -> void:
	if textures.has(n) and textures[n] != null: draw_texture_rect(textures[n],r,false)
	else: draw_rect(r,indigo)

func heading(title_:String,subtitle:String) -> void:
	draw_rect(Rect2(Vector2.ZERO,canvas_size),Color("0b1727"))
	txt(28,44,title_,28,"title")
	txt(28,76,subtitle,16,"location",gold)
	draw_line(Vector2(28,94),Vector2(canvas_size.x-28,94),gold,1)

func _draw() -> void:
	if fonts.size()!=3 or textures.size()<24: return
	match mode:
		"symbols": symbols()
		"states-and-rotations": states()
		"typography": typography()
		"rotations-72": rotations_small()
		"action-states": action_states()
		_: layout()

func symbols() -> void:
	heading("RC-012  /  Core symbol library","Godot imports · 24 / 32 / 48 px · colour & monochrome on indigo, stone and parchment")
	for i in names.size():
		var x := 28.0 + (i%6)*192
		var y := 115.0 + (i/6)*292
		box(Rect2(x,y,181,274))
		txt(x+10,y+27,names[i].replace("_"," ").capitalize(),16,"labels",cream,162)
		for j in 3:
			var sz: int = [24,32,48][j]
			icon(names[i],x+14+j*51,y+46,sz)
			txt(x+16+j*51,y+114,str(sz),13)
		material("board-stone",Rect2(x+9,y+128,163,57))
		icon(names[i],x+22,y+133,48,0,true,cream)
		icon(names[i],x+98,y+133,48)
		material("parchment",Rect2(x+9,y+197,163,57))
		icon(names[i],x+22,y+201,48,0,true,ink)
		icon(names[i],x+98,y+201,48)
	txt(28,1323,"Outlined silhouettes share one SVG each. State borders and text remain separate.",18)
	txt(28,1355,"Reference-guided production assets · supplied artwork approval does not approve this reconstruction.",16,"location",gold)

func state_frame(r:Rect2,state:String) -> void:
	if state == "selected":
		draw_rect(r.grow(-3),teal,false,3)
		draw_polyline(PackedVector2Array([r.position+Vector2(7,13),r.position+Vector2(12,18),r.position+Vector2(22,7)]),cream,3,true)
	elif state == "focused":
		for x in range(int(r.position.x+4),int(r.end.x-3),10):
			draw_line(Vector2(x,r.position.y+3),Vector2(minf(x+5,r.end.x-3),r.position.y+3),cream,2)
			draw_line(Vector2(x,r.end.y-3),Vector2(minf(x+5,r.end.x-3),r.end.y-3),cream,2)
		for y in range(int(r.position.y+4),int(r.end.y-3),10):
			draw_line(Vector2(r.position.x+3,y),Vector2(r.position.x+3,minf(y+5,r.end.y-3)),cream,2)
			draw_line(Vector2(r.end.x-3,y),Vector2(r.end.x-3,minf(y+5,r.end.y-3)),cream,2)
	elif state == "disabled":
		draw_rect(r,Color(0.1,0.15,0.2,0.48))
		draw_line(r.position+Vector2(7,8),r.position+Vector2(23,8),cream,3)
	elif state == "unavailable":
		draw_circle(r.position+Vector2(14,14),8,cream,false,2,true)
		draw_line(r.position+Vector2(9,19),r.position+Vector2(19,9),cream,2,true)
	elif state == "invalid":
		draw_rect(r.grow(-3),Color("efb092"),false,2)
		draw_line(r.position+Vector2(7,7),r.position+Vector2(21,21),cream,3,true)
		draw_line(r.position+Vector2(7,21),r.position+Vector2(21,7),cream,3,true)

func cell(n:String,x:float,y:float,sz:float,turn:int=0,state:String="normal",ports:bool=false) -> void:
	var r := Rect2(x,y,sz,sz)
	material("board-stone",r)
	draw_rect(r,gold,false,2)
	if ports or n in ["begin","end"]:
		draw_set_transform(Vector2(x+sz/2,y+sz/2),turn*PI/2,Vector2.ONE)
		if n in ["begin","end"]:
			var direction := Vector2.RIGHT if n=="begin" else Vector2.UP
			draw_line(direction*sz/2,direction*sz*0.25,gold,sz/16,true)
		else:
			for sign_ in [-1,1]:
				draw_line(Vector2(sign_*sz/2,0),Vector2(sign_*sz*0.27,0),gold,sz/16,true)
				draw_line(Vector2(sign_*(sz/2-4),-5),Vector2(sign_*(sz/2-4),5),cream,2,true)
		draw_set_transform(Vector2.ZERO)
	var glyph := sz if n in ["straight","corner"] else sz*0.65
	icon(n,x+(sz-glyph)/2,y+(sz-glyph)/2,glyph,0 if n in ["begin","end"] else turn)
	if n in ["begin","end"]:
		var fs := 20 if sz>100 else 13
		var width_:float = fonts.labels.get_string_size(n.to_upper(),0,-1,fs).x
		var south_port := (n=="begin" and turn==1) or (n=="end" and turn==2)
		txt(x+(sz-width_)/2,y+fs+3 if south_port else y+sz-7,n.to_upper(),fs,"labels",cream,sz)
	state_frame(r,state)

func states() -> void:
	heading("RC-012  /  States & quarter turns","137 / 72 px cells · blunt ports · decorative fork/trident tips do not define connectivity")
	var st := ["normal","selected","focused","disabled","unavailable","invalid"]
	for i in 6:
		var x := 30.0+i*194
		txt(x,125,st[i].capitalize(),17)
		cell("spark",x,145,137,0,st[i],true)
		cell("spark",x+32,310,72,0,st[i],true)
	txt(30,421,"Shared glyphs rotate about (64,64); labels stay upright. Endpoint ports are separate live strokes.",18)
	var kinds := ["begin","end","straight","corner","split","join"]
	for j in 6:
		var x := 30.0+j*194
		txt(x,462,kinds[j].capitalize(),18)
		for turn in 4:
			var y := 482.0+turn*194
			cell(kinds[j],x,y,137,turn)
			txt(x+40,y+165,str(turn*90)+"°",16)
	txt(30,1299,"Split and Join are isolated silhouettes here: their visual tips are not a new port-count contract.",18)
	txt(30,1341,"Selection check · focus dashes · disabled dash · unavailable slash · invalid cross",18)
	txt(30,1383,"State markers are corner overlays. No rune names, values, cost badges or TEMP appear inside cells.",17)
	txt(30,1422,"Undirected evaluator / no-cast behavior: RC-016A. These specimens do not execute circuits.",17,"location",gold)

func rotations_small() -> void:
	heading("RC-012 / 72 px rotations","Native small cells · four clockwise quarter turns")
	var kinds := ["begin","end","straight","corner","split","join"]
	for j in 6:
		var x := 20.0+j*116
		txt(x,128,kinds[j].capitalize(),14)
		for turn in 4:
			var y := 150.0+turn*148
			cell(kinds[j],x,y,72,turn)
			txt(x+18,y+101,str(turn*90)+"°",15)
	txt(20,778,"Only BEGIN and END label cells. Decoration does not declare graph ports.",15)
	txt(20,815,"Exact cell-edge centers: N(64,0), E(128,64), S(64,128), W(0,64).",15)

func action_states() -> void:
	heading("RC-012 / Shared action & navigation states","Same imported glyphs · neutral shape markers supplement colour · live labels")
	var states_ := ["normal","selected","focused","disabled","unavailable","invalid"]
	for i in 6:
		var y := 127.0+i*130
		txt(28,y+19,states_[i].capitalize(),18)
		for j in 4:
			var x := 200.0+j*239
			var r := Rect2(x,y-7,215,86)
			material("navy",r)
			var n:String = ["remove","rotate","sound_on","sound_off"][j]
			icon(n,x+21,y+13,40)
			txt(x+76,y+42,["Remove","Rotate","Sound on","Sound off"][j],18,"labels",cream,130)
			state_frame(r,states_[i])
	txt(28,943,"Applicability is consumer-owned: selected wiring/navigation, focus, disabled or unavailable actions.",18)
	txt(28,981,"The invalid treatment is a specimen for rejected actions; no retired gameplay controls are introduced.",17)
	txt(28,1018,"Sound state uses waves versus a cross, with live on/off labels; colour alone is never the signal.",17)

func card(x:float,y:float,w:float,h:float,n:String,small:bool=false) -> void:
	var fs := 16 if small else 20
	material("amber" if n in ["Spark","Free Spark"] else "navy",Rect2(x,y,w,h))
	draw_rect(Rect2(x,y,w,h),gold,false,2)
	var glyph := "spark" if n in ["Spark","Free Spark"] else "conjure" if n=="Conjure Spark" else n.to_lower()
	icon("energy",x+9,y+9,27)
	txt(x+39,y+31,"0" if n in ["Free Spark","Conjure Spark"] else "2" if n=="Spark" else "1",19)
	icon(glyph,x+w/2-24,y+36,48)
	txt(x+12,y+111,n,fs,"title",cream,w-24)
	var role_ := "RUNE" if n in ["Spark","Free Spark","Shield"] else "TECHNIQUE"
	txt(x+12,y+141,role_,13,"labels",gold,w-24)
	var effect := "Add 6 damage." if n in ["Spark","Free Spark"] else "Add 5 shield." if n=="Shield" else "Draw 2 cards." if n=="Focus" else "Create a Free Spark."
	if n=="Conjure Spark" and small:
		txt(x+12,y+168,"Create a",14,"labels",cream,w-24)
		txt(x+12,y+192,"Free Spark.",14,"labels",cream,w-24)
	else:
		txt(x+12,y+168,effect,14 if small else 18,"labels",cream,w-24)
	if n == "Free Spark":
		icon("temporary_marker",x+10,y+181,24)
		txt(x+40,y+201,"Expires this turn",12 if small else 16,"labels",cream,w-50)

func typography() -> void:
	heading("RC-012  /  Live typography","Noto Serif 2.015 · one variable binary · width 100 · outlined serif · Godot FontVariation")
	txt(30,145,"Title / large action · weight 700",16,"location",gold)
	txt(30,208,"CAST     Continue     Resume",44,"title")
	txt(30,256,"Labels / values · weight 600",16,"location",gold)
	txt(30,306,"Remove   Rotate   Draw   Discard",28)
	txt(30,347,"0  6  8  1    24 / 30    32 / 32    0 / 6    Incoming: 8",25)
	txt(30,393,"Location · weight 500",16,"location",gold)
	txt(30,437,"Floor 3 · Ashen Crypt",26,"location")
	txt(30,493,"Real variation comparison / identical string and size",16,"location",gold)
	for i in 3:
		txt(30,538+i*44,["500","600","700"][i],17,"location",gold)
		txt(100,538+i*44,"Rune Cast  0681",28,["location","labels","title"][i])
	card(30,675,215,224,"Spark")
	card(267,675,215,224,"Free Spark")
	card(504,675,215,224,"Shield")
	card(741,675,229,224,"Focus")
	txt(30,945,"Free Spark shares the sun; cost 0, name, hourglass and lifetime identify its card.",18)
	txt(30,991,"Long-label and numeral checks · 16 px / 20 px",16,"location",gold)
	txt(30,1031,"Conjure Spark created a free Spark · Draw 8 · Discard 5",20)
	txt(30,1066,"Unavailable: no remaining stock.  Focused selection.  Cast ends turn.",16)
	txt(30,1111,"0123456789  0/6  0/8  1/1  + − × ÷  ( ) [ ] : ; , . ! ? ' “ ” — …",20)
	material("parchment",Rect2(30,1144,940,110))
	txt(50,1189,"Tower Map · Choose your next encounter",24,"labels",cream)
	txt(50,1230,"BEGIN / END are the only live labels inside board cells.",18)
	txt(30,1304,"SIL OFL 1.1 included. This selected practical font is not an identification of the reference face.",16)
	txt(30,1343,"No system fallback in this preview; coverage and resource identity are checked per live string.",16)

func layout() -> void:
	var narrow := canvas_size.x < 400
	var compact := canvas_size.x < 600
	var margin := 18.0
	var w := canvas_size.x-2*margin
	draw_rect(Rect2(Vector2.ZERO,canvas_size),Color("0b1727"))
	txt(margin,32,"RC-012 / import specimen",18 if compact else 28,"title")
	txt(margin,61,"Native type & symbols" if narrow else "Isolated components · live type · not gameplay",14 if compact else 18,"location",gold)
	if mode.ends_with("cards"):
		card(18,82,157,221,"Free Spark",true)
		card(185,82,157,221,"Conjure Spark",true)
		controls(18,321,w,true)
		txt(18,610,"Second native page / card detail & controls",12,"location",gold)
		return
	var y := 94.0
	icon("health",margin,y-10,32)
	txt(margin+40,y+15,"24/30",20)
	icon("energy",margin+w*0.51,y-10,32)
	txt(margin+w*0.51+40,y+15,"3/3",20)
	y += 61
	var sz := 72.0 if narrow else 90.0 if compact else 137.0
	var gap := 6.0
	var start := (canvas_size.x-(sz*3+gap*2))/2
	for i in 3: cell(["begin","spark","end"][i],start+i*(sz+gap),y,sz,0,"normal",i==1)
	y += sz+31
	txt(margin,y,"Only BEGIN / END text in cells",14 if compact else 22)
	y += 40
	for i in 4:
		var cw := w/4
		icon(["straight","corner","split","join"][i],margin+i*cw+(cw-32)/2,y,32)
		txt(margin+i*cw+4,y+56,["Straight","Corner","Split","Join"][i],13 if compact else 20,"labels",cream,cw-6)
	y += 86
	if narrow:
		controls(margin,y,w,true)
	else:
		var cw := (w-20)/3
		for i in 3: card(margin+i*(cw+10),y,cw,219,["Spark","Shield","Focus"][i],compact)
		y += 249
		icon("draw_pile",margin,y-16,28)
		txt(margin+35,y+7,"Draw 8",16 if compact else 22)
		icon("discard_pile",canvas_size.x/2,y-16,28)
		txt(canvas_size.x/2+35,y+7,"Discard 5",16 if compact else 22)
		y += 45
		txt(margin,y,"Conjure Spark created a free Spark",14 if compact else 22)
		controls(margin,y+25,w,compact)
		if not compact: txt(margin,canvas_size.y-30,"Asset QA only · no evaluator or production scene changes",18,"location",gold)

func controls(x:float,y:float,w:float,small:bool) -> void:
	var fs := 16 if small else 24
	icon("remove",x,y,28)
	txt(x+35,y+24,"Remove",fs)
	icon("rotate",x+w/2,y,28)
	txt(x+w/2+35,y+24,"Rotate",fs)
	y += 43
	box(Rect2(x,y,w,56))
	txt(x+10,y+24,"12 damage · 0 shield · Cost 1",14 if small else 22)
	txt(x+10,y+47,"Incoming: 8",14 if small else 20)
	y += 68
	var poly := PackedVector2Array([Vector2(x+20,y),Vector2(x+w-20,y),Vector2(x+w,y+28),Vector2(x+w-20,y+56),Vector2(x+20,y+56),Vector2(x,y+28)])
	draw_colored_polygon(poly,Color("09656b"))
	poly.append(poly[0])
	draw_polyline(poly,gold,3,true)
	txt(x+w/2-60,y+37,"CAST  1",28,"title")
	y += 78
	txt(x+w/2-58,y,"Cast ends turn",14)
	y += 17
	for i in 4:
		var cw := w/4
		icon(["menu","map","guide","sound_on"][i],x+i*cw+(cw-26)/2,y,26)
		txt(x+i*cw+8,y+44,["Menu","Map","Guide","Sound"][i],13 if small else 20,"labels",cream,cw-12)
