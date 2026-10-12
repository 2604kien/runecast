extends Control

const PACK = "res://assets/enemies/shadeling/"
const INK = Color("131728")
const GOLD = Color("e6bd73")
const CREAM = Color("fff0ce")
const TEAL = Color("7de4d7")
const FOOT = Vector2(256,448)
var mode := "poses"
var canvas_size := Vector2(1200,520)
var options: Dictionary = {}
var actors: Array = []
var geometry: Array = []
var guides: Array = []
var labels: Array = []
var files: Array = []
var title_font: Font
var body_font: Font
var crypt: Texture2D

func _ready() -> void:
	size = canvas_size
	theme = load("res://assets/ui/rune_cast_theme.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_font = load("res://assets/fonts/display/title.tres")
	body_font = load("res://assets/fonts/ui/labels.tres")
	crypt = load("res://retained/crypt-background.png")
	match mode:
		"poses": build_poses()
		"alpha": build_alpha()
		"overlay": build_overlay()
		"arena": build_arena()
		"motion": build_motion()
		"comparison": build_comparison()
		"parts": build_parts()
	queue_redraw()

func text_label(copy: String, point: Vector2, extent: Vector2, font_size: int=18, centered: bool=false) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = point
	label.size = extent
	label.add_theme_font_override("font", body_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",CREAM)
	label.add_theme_color_override("font_outline_color", Color("090c18"))
	label.add_theme_constant_override("outline_size",3)
	if centered: label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	labels.append(label)
	return label

func title(copy: String, subtitle: String="") -> void:
	var heading = text_label(copy,Vector2(24,12),Vector2(canvas_size.x-48,36),26)
	heading.add_theme_font_override("font",title_font)
	if not subtitle.is_empty(): text_label(subtitle,Vector2(24,53),Vector2(canvas_size.x-48,28),14)

func actor(point: Vector2, amount: float, pose: String="neutral", state: String="", elapsed: float=0.0, reduced: bool=false):
	var instance=load(PACK+"character.tscn").instantiate()
	add_child(instance)
	instance.position=point
	instance.scale=Vector2.ONE*amount
	if state.is_empty(): instance.show_pose(pose)
	else: instance.sample_state(state,elapsed,reduced)
	actors.append(instance)
	return instance

func build_poses() -> void:
	title("Shadeling / production pose sheet", "Same 512×512 canvas · foot (256,448) · common scale 0.72 · actual Godot rendering")
	for i in 3:
		var left=24.0+i*390
		geometry.append({"type":"panel","rect":Rect2(left,96,372,390),"color":Color("1c2038")})
		var foot=Vector2(left+186,431)
		geometry.append({"type":"line","a":Vector2(left+16,foot.y),"b":Vector2(left+356,foot.y),"color":TEAL})
		actor(foot,0.72,["neutral","attack","hit"][i])
		text_label(["Neutral / idle stance","Attack / raised lantern windup","Hit / recoil"][i],Vector2(left,448),Vector2(372,30),17,true)

func build_alpha() -> void:
	title("Alpha and separated parts", "Every runtime pose/part at scale 0.42 across indigo, white, black, checkerboard and retained crypt")
	files=options.get("files",[])
	for row in files.size():
		var path: String=files[row]
		var y=94.0+row*270
		for col in 5:
			var rect=Rect2(10+col*238,y,228,250)
			geometry.append({"type":"background","rect":rect,"background":col})
			geometry.append({"type":"image","rect":Rect2(rect.position+Vector2(6,8),Vector2(215.04,215.04)),"texture":load(path)})
			text_label(path.get_file().get_basename().replace("_"," "),rect.position+Vector2(3,222),Vector2(222,22),12,true)
			if row==0: text_label(["Indigo","White","Black","Checker","Retained crypt"][col],Vector2(rect.position.x,76),Vector2(228,20),12,true)

func build_overlay() -> void:
	title("Anchor, attachments and motion envelope", "Cyan = common foot / gold = current attachments / pink = sampled visible motion union")
	for i in 3:
		var left=18.0+i*395
		var top=106.0
		var s=0.72
		var origin=Vector2(left,top)
		geometry.append({"type":"panel","rect":Rect2(origin,Vector2(512,512)*s),"color":Color("20243d")})
		geometry.append({"type":"outline","rect":Rect2(origin+Vector2(24,32)*s,Vector2(464,448)*s),"color":TEAL})
		var a=actor(origin+FOOT*s,s,["neutral","attack","hit"][i])
		geometry.append({"type":"line","a":origin+Vector2(0,448)*s,"b":origin+Vector2(512,448)*s,"color":TEAL})
		geometry.append({"type":"marker","point":origin+FOOT*s,"color":TEAL})
		for attachment in ["head","body_center","attack_origin","lantern_pivot"]:
			var point=origin+FOOT*s+a.get_attachment_position(attachment)*s
			geometry.append({"type":"marker","point":point,"color":GOLD})
			var offset={"head":Vector2(12,-23),"body_center":Vector2(12,4),"attack_origin":Vector2(-72,-34),"lantern_pivot":Vector2(-65,16)}[attachment]
			geometry.append({"type":"line","a":point,"b":point+offset+Vector2(25,8),"color":GOLD})
			text_label(attachment.replace("_"," "),point+offset,Vector2(120,20),12)
		var bounds: Array=options.get("envelope",[24,32,488,480])
		geometry.append({"type":"outline","rect":Rect2(origin+Vector2(bounds[0],bounds[1])*s,Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1])*s),"color":Color("f4a4ca")})
		text_label(["Neutral","Attack","Hit"][i]+"  /  origin remains fixed",Vector2(left,486),Vector2(370,24),16,true)
	text_label("Envelope includes normal + reduced-motion states, including attack/hit recovery and defeat fade. Guides exclude UI.",Vector2(24,526),Vector2(1150,30),14)
	for item in geometry:
		if item.type in ["outline","line","marker"]: guides.append(item)
	geometry = geometry.filter(func(item): return item.type not in ["outline","line","marker"])
	var foreground := Node2D.new()
	foreground.z_index=20
	add_child(foreground)
	foreground.draw.connect(func():
		for item in guides:
			if item.type=="outline": foreground.draw_rect(item.rect,item.color,false,1.5)
			if item.type=="line": foreground.draw_line(item.a,item.b,item.color,1.0,true)
			if item.type=="marker":
				foreground.draw_circle(item.point,3,item.color)
				foreground.draw_line(item.point-Vector2(6,0),item.point+Vector2(6,0),item.color,1,true)
				foreground.draw_line(item.point-Vector2(0,6),item.point+Vector2(0,6),item.color,1,true))
	foreground.queue_redraw()

func build_arena() -> void:
	# Narrow comparison uses the same crop and composition. Scale live UI with
	# the 450-wide specimen so fixed minimum font/control sizes cannot overlap.
	if canvas_size.x < 450.0:
		scale=Vector2.ONE*(canvas_size.x/450.0)
		canvas_size/=scale.x
		size=canvas_size
	var scale_factor=canvas_size.x/841.0
	var foot=Vector2(446,368)*scale_factor
	var actor_scale=0.75*scale_factor
	geometry.append({"type":"crypt","rect":Rect2(Vector2(0,-60*scale_factor),Vector2(canvas_size.x,1870*scale_factor))})
	actor(foot,actor_scale)
	var top=4.0*scale_factor
	var fs=int(round(25*scale_factor))
	fs=maxi(fs,14)
	var name_y=foot.y+10*scale_factor
	var role_label=text_label("BOSS",Vector2(16,name_y-18),Vector2(canvas_size.x-32,18),12,true)
	role_label.add_theme_color_override("font_color",GOLD)
	text_label("Shadeling",Vector2(16,name_y),Vector2(canvas_size.x-32,28),fs+4,true)
	text_label("8",Vector2(canvas_size.x/2-5,top+6),Vector2(40,28),fs+4)
	var attack_icon := TextureRect.new()
	attack_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	attack_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	attack_icon.texture=load("res://assets/icons/resources/attack.svg")
	attack_icon.position=Vector2(canvas_size.x/2-30,top+12)
	attack_icon.size=Vector2(18,18)
	add_child(attack_icon)
	var health_height=14 if canvas_size.x<500 else 18
	var health_y=canvas_size.y-health_height-5
	var health_width=minf(280,canvas_size.x-64)
	var bar:=ProgressBar.new()
	bar.theme_type_variation="RCHealth"
	bar.position=Vector2((canvas_size.x-health_width)/2,health_y)
	bar.size=Vector2(health_width,health_height)
	bar.max_value=32
	bar.value=32
	bar.show_percentage=false
	# Hide native percentage font minimum; the separate live label owns the value.
	bar.add_theme_font_size_override("font_size",1)
	add_child(bar)
	bar.size=Vector2(health_width,health_height)
	text_label("32 / 32",Vector2(0,health_y-2),Vector2(canvas_size.x,health_height+2),11 if canvas_size.x<500 else 13,true)

func build_motion() -> void:
	var s=canvas_size.x/841.0
	geometry.append({"type":"crypt","rect":Rect2(Vector2.ZERO,Vector2(canvas_size.x,1870*s))})
	var state: String=options.get("state","idle")
	var elapsed: float=options.get("elapsed",0.0)
	var reduced: bool=options.get("reduced",false)
	actor(Vector2(canvas_size.x/2,canvas_size.y-54),0.57,"neutral",state,elapsed,reduced)
	text_label("Shadeling  /  "+("Reduced motion" if reduced else "Motion study"),Vector2(8,8),Vector2(canvas_size.x-16,24),16,true)
	text_label(state.capitalize()+" · "+("%.2f s"%elapsed),Vector2(8,canvas_size.y-37),Vector2(canvas_size.x-16,24),15,true)

func build_comparison() -> void:
	title("Motion / reduced-motion comparison", "Deterministic scene samples · idle / attack / hit / defeat · final defeat remains hidden")
	var samples=[ ["idle",0.6],["attack",0.25],["attack",0.46],["hit",0.18],["defeat",0.68],["defeat",1.25] ]
	for row in 2:
		for col in samples.size():
			var rect=Rect2(12+col*198,92+row*290,190,270)
			geometry.append({"type":"panel","rect":rect,"color":Color("20243d")})
			actor(rect.position+Vector2(95,224),0.39,"neutral",samples[col][0],samples[col][1],row==1)
			text_label(samples[col][0]+" %.2f s"%samples[col][1],rect.position+Vector2(0,236),Vector2(190,22),13,true)
			if col==0: text_label("Reduced" if row==1 else "Normal",rect.position+Vector2(8,8),Vector2(170,22),14,true)

func build_parts() -> void:
	title("Editable part underlap stress", "Source-part proof only · arm ±4° / inherited lantern ±3° / hood ±2° · whole-pose runtime has no part seams")
	for row in 2:
		for col in 3:
			var rect=Rect2(12+col*395,94+row*400,384,386)
			geometry.append({"type":"background","rect":rect,"background":1 if row==0 else 4})
			var rig=load("res://parts_study.gd").new()
			add_child(rig)
			rig.position=rect.position+Vector2(192,327)
			rig.scale=Vector2.ONE*0.72
			rig.sample(float(col-1))
			text_label(["Arm −4° / lantern −3° / hood +2°","Rest / editable part reconstruction","Arm +4° / lantern +3° / hood −2°"][col],rect.position+Vector2(5,349),Vector2(374,28),13,true)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,canvas_size),INK)
	for item in geometry:
		match item.type:
			"panel": draw_rect(item.rect,item.color)
			"outline": draw_rect(item.rect,item.color,false,1.5)
			"line": draw_line(item.a,item.b,item.color,1.0,true)
			"marker":
				draw_circle(item.point,4,item.color)
				draw_line(item.point-Vector2(7,0),item.point+Vector2(7,0),item.color,1,true)
				draw_line(item.point-Vector2(0,7),item.point+Vector2(0,7),item.color,1,true)
			"image": draw_texture_rect(item.texture,item.rect,false)
			"crypt": draw_texture_rect(crypt,item.rect,false)
			"background":
				var r: Rect2=item.rect
				match item.background:
					0: draw_rect(r,Color("232741"))
					1: draw_rect(r,Color("f4f4f4"))
					2: draw_rect(r,Color.BLACK)
					3:
						for y in range(0,int(r.size.y),16):
							for x in range(0,int(r.size.x),16):
								var color=Color("c3c5cd") if (x/16+y/16)%2==0 else Color("747883")
								draw_rect(Rect2(r.position+Vector2(x,y),Vector2(mini(16,int(r.size.x)-x),mini(16,int(r.size.y)-y))),color)
					4: draw_texture_rect_region(crypt,r,Rect2(130,70,600,658))
