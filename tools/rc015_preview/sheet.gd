extends Control

const Ui = preload("res://scenes/ui/theme/components.gd")
const ENV = preload("res://assets/environments/crypt/environment.tscn")
const ACTOR = preload("res://assets/enemies/shadeling/character.tscn")
const CREAM = Color("fff0ce")
const GOLD = Color("e6bd73")
const TEAL = Color("7de4d7")
var mode := "arena"
var canvas_size := Vector2(720,385)
var options: Dictionary = {}
var actors: Array = []
var labels: Array = []
var controls: Array = []
var environment: Node2D
var cover: Dictionary = {}

func _ready() -> void:
	size = canvas_size
	theme = load("res://assets/ui/rune_cast_theme.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	match mode:
		"arena": build_arena()
		"layer", "recomposed", "guides", "overscan": build_layer()
		"home": build_home()
	queue_redraw()

func text_label(copy: String, point: Vector2, extent: Vector2, font_size: int, centered: bool=false) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = point
	label.size = extent
	label.add_theme_font_override("font",load("res://assets/fonts/ui/labels.tres"))
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",CREAM)
	label.add_theme_color_override("font_outline_color",Color("090c18"))
	label.add_theme_constant_override("outline_size",2)
	if centered: label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	labels.append(label)
	return label

func crypt(preset: String="base_cool") -> Node2D:
	var instance = ENV.instantiate()
	add_child(instance)
	instance.set_lighting(StringName(preset))
	environment = instance
	return instance

func build_arena() -> void:
	var k := canvas_size.x/841.0
	var env := crypt(options.get("preset","base_cool"))
	env.position=Vector2(0,-60*k)
	env.scale=Vector2.ONE*k
	var actor = ACTOR.instantiate()
	add_child(actor)
	actor.position=Vector2(446,368)*k
	actor.scale=Vector2.ONE*0.75*k
	actor.sample_state(options.get("state","idle"),options.get("seconds",0.0),options.get("reduced",false))
	actors.append(actor)
	# A compact row below the measured whole-motion union keeps labels off toes.
	# These are isolated UI fixtures; no game model, encounter stat or save binding.
	var name_y := 374.0*k
	var name_size := maxi(13,roundi(28*k))
	var row_height := maxf(18,30*k)
	var row_width := maxf(152,280*k)
	var row_left := (canvas_size.x-row_width)/2
	var role_width := row_width*0.25
	var role := text_label("BOSS",Vector2(row_left,name_y+row_height*0.20),Vector2(role_width,row_height),maxi(9,roundi(16*k)),true)
	role.add_theme_color_override("font_color",GOLD)
	text_label("Shadeling",Vector2(row_left+role_width,name_y),Vector2(row_width-role_width,row_height),name_size,true)
	var icon_size := maxf(14,22*k)
	var top := 4.0
	var icon := Ui.icon("attack",icon_size)
	icon.position=Vector2(canvas_size.x/2-icon_size-4,top+5)
	icon.size=Vector2.ONE*icon_size
	add_child(icon)
	text_label("8",Vector2(canvas_size.x/2+3,top),Vector2(34,28),maxi(16,roundi(27*k)))
	var health_height := maxf(11,20*k)
	var health_y := canvas_size.y-health_height-4
	var health_width := minf(canvas_size.x-48,maxf(190,380*k))
	var bar := ProgressBar.new()
	bar.theme_type_variation="RCHealth"
	bar.position=Vector2((canvas_size.x-health_width)/2,health_y)
	bar.size=Vector2(health_width,health_height)
	bar.max_value=32
	bar.value=32
	bar.show_percentage=false
	bar.add_theme_font_size_override("font_size",1)
	add_child(bar)
	bar.size=Vector2(health_width,health_height)
	controls.append(bar)
	text_label("32 / 32",Vector2(0,health_y-2),Vector2(canvas_size.x,health_height+2),maxi(10,roundi(14*k)),true)
	if options.get("guides",false): add_arena_guides(k)

func build_layer() -> void:
	if mode=="layer":
		var checker := Node2D.new()
		checker.z_index=-30
		add_child(checker)
		checker.draw.connect(func():
			for y in range(0,int(canvas_size.y),24):
				for x in range(0,int(canvas_size.x),24):
					var gray := 0.19 if (x/24+y/24)%2==0 else 0.27
					checker.draw_rect(Rect2(x,y,24,24),Color(gray,gray,gray,1)))
	var env := crypt(options.get("preset","base_cool"))
	if mode=="layer":
		env.get_node("Background").visible=options.get("layer","")=="background"
		env.get_node("Floor").visible=options.get("layer","")=="floor"
	if mode=="overscan":
		env.position.y=-float(options.get("crop_y",60))
	if mode=="guides":
		var guide := Node2D.new()
		guide.z_index=100
		add_child(guide)
		guide.draw.connect(func():
			guide.draw_rect(Rect2(0,0,841,60),Color(0.45,0.1,0.55,0.20))
			guide.draw_rect(Rect2(0,510,841,60),Color(0.45,0.1,0.55,0.20))
			guide.draw_rect(Rect2(1,60,839,450),TEAL,false,2)
			guide.draw_rect(Rect2(0,340,841,41),Color(1.0,0.6,0.2,0.15))
			guide.draw_rect(Rect2(272,116,348,336),Color("f4a4ca"),false,2)
			guide.draw_rect(Rect2(275.75,155,335.25,279),GOLD,false,1.5)
			guide.draw_line(Vector2(230,428),Vector2(650,428),TEAL,1.5)
			guide.draw_circle(Vector2(446,428),4,TEAL))
		text_label("841 × 570 shared canvas / 60 px top and bottom art overscan",Vector2(14,9),Vector2(810,30),19)
		text_label("Default comparison crop y60–510 / no horizontal overscan",Vector2(14,68),Vector2(800,27),17)
		text_label("Pink: allowed motion / gold: actual union / cyan: foot y428",Vector2(14,531),Vector2(810,28),17)
		text_label("Opaque background continues behind floor",Vector2(18,349),Vector2(790,24),16)

func add_arena_guides(k: float) -> void:
	var guide := Node2D.new()
	guide.z_index=100
	add_child(guide)
	guide.draw.connect(func():
		guide.draw_rect(Rect2(Vector2(272,56)*k,Vector2(348,336)*k),Color("f4a4ca"),false,1)
		guide.draw_rect(Rect2(Vector2(275.75,95)*k,Vector2(335.25,279)*k),GOLD,false,1)
		guide.draw_circle(Vector2(446,368)*k,3,TEAL))

func build_home() -> void:
	var tex: Texture2D=load("res://assets/environments/home/home_tower.png")
	var k := maxf(canvas_size.x/720.0,canvas_size.y/1600.0)
	var extent := Vector2(720,1600)*k
	var offset := (canvas_size-extent)/2
	var illustration := Sprite2D.new()
	illustration.texture=tex
	illustration.centered=false
	illustration.position=offset
	illustration.scale=Vector2.ONE*k
	add_child(illustration)
	cover={"scale":k,"offset":[offset.x,offset.y],"source_crop":[-offset.x/k,-offset.y/k,canvas_size.x/k,canvas_size.y/k]}
	if not options.get("composed",false): return
	var logo := TextureRect.new()
	logo.texture=load("res://assets/ui/wordmark.png")
	logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Short cover crop lifts/scales the separate wordmark clear of the tower apex.
	# The approved hierarchy permits a partially occluded moon behind the logo.
	logo.position=Vector2(80,8) if canvas_size.y<1400 else Vector2(54,35)
	logo.size=Vector2(560,210) if canvas_size.y<1400 else Vector2(612,230)
	add_child(logo)
	# Reuse RC-013 button constructor and skins with separate live labels.
	# A shorter screen moves the menu upward; only the illustration is cover-cropped.
	var button_y := minf(1110,canvas_size.y-348)
	for i in 3:
		var button := Ui.action(["Continue","New Run","Options"][i],i==0,Vector2(440,82))
		button.position=Vector2(140,button_y+i*98)
		button.size=Vector2(440,82)
		button.add_theme_font_size_override("font_size",30)
		add_child(button)
		controls.append(button)

