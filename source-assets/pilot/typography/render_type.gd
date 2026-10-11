extends SceneTree
const OUTPUT := "C:/Dev/RuneCast/output/art/rc-011/pilot-type.png"
const SVG_OUTPUT := "C:/Dev/RuneCast/source-assets/pilot/typography/pilot-type.svg"
const EVIDENCE := "C:/Dev/RuneCast/source-assets/pilot/typography/fallback-evidence.json"

class Sheet extends Control:
	var font: Font
	var svg: PackedStringArray = []
	var measurements: Array = []
	var ink := Color("#eee0bf")
	var muted := Color("#adb9c9")
	var gold := Color("#d6ad67")
	func rect(x: float,y: float,w: float,h: float,c: String,border: String="") -> void:
		draw_rect(Rect2(x,y,w,h),Color(c))
		if border != "": draw_rect(Rect2(x,y,w,h),Color(border),false,1)
		svg.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="%s"/>' % [x,y,w,h,c,border if border!="" else "none"])
	func text_at(x: float,y: float,value: String,px: int=20,c: Color=Color("#eee0bf"),record: bool=false) -> void:
		draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,c)
		svg.append('<text x="%s" y="%s" font-family="%s, sans-serif" font-size="%s" fill="#%s">%s</text>' % [x,y,font.get_font_name().xml_escape(),px,c.to_html(false),value.xml_escape()])
		if record:
			measurements.append({"string":value,"size_px":px,"width_px":font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x,"height_px":font.get_height(px)})
	func line(x:float,y:float,w:float) -> void:
		draw_line(Vector2(x,y),Vector2(x+w,y),Color("#394357"),1)
		svg.append('<path d="M %s %s h %s" stroke="#394357"/>' % [x,y,w])
	func _draw() -> void:
		svg.clear()
		measurements.clear()
		rect(0,0,1100,1360,"#101b2b")
		rect(32,32,4,80,"#d6ad67")
		text_at(52,63,"RUNE CAST / TYPE DIRECTION",32,ink)
		text_at(52,93,"RC-011 · 1 image pixel = 1 logical design pixel · desktop evidence",17,muted)
		text_at(52,122,"ACTUAL RENDER: Godot fallback / " + font.get_font_name() + " / " + font.get_font_style_name(),16,gold)
		text_at(52,151,"Noto candidate binaries are not acquired. Samples below use the current engine fallback.",17,muted)
		line(48,174,1004)
		text_at(48,205,"ROLE / CHOSEN DIRECTION",14,gold)
		text_at(447,205,"ACTUAL-SIZE FALLBACK SPECIMEN",14,gold)
		var roles = [
			["Display title", "Noto Serif SemiBold · 32 px", "Training Crypt",32],
			["Primary / large action", "Noto Serif SemiBold · 28 px", "CAST   /   Resume   /   Continue",28],
			["General UI / body", "Noto Sans Regular · 20 px", "Cancel selection   ·   Details / Pass",20],
			["Inspector body", "Noto Sans Regular · 23 px", "Inspect before you commit.",23],
			["Compact labels", "Noto Sans SemiBold · 15 px", "Spark     Free Spark     Conjure Spark",15],
			["Values / finite stock", "Noto Sans SemiBold · 21 px", "0 / 6     32 / 32     6  0  8  1",21]
		]
		var y := 241
		for r in roles:
			text_at(48,y,r[0],20,ink)
			text_at(48,y+24,r[1],15,muted)
			text_at(447,y+10,r[2],r[3],ink,true)
			line(48,y+44,1004)
			y += 76
		text_at(48,740,"CONTROL FIT / FIXED BOUNDS; TEXT REMAINS EDITABLE",15,gold)
		rect(48,764,66,50,"#20334b","#d6ad67")
		text_at(58,794,"Rotate",15,ink,true)
		text_at(48,837,"66 × 50",14,muted)
		rect(143,764,188,58,"#20334b","#d6ad67")
		text_at(159,798,"Cancel selection",20,ink,true)
		text_at(143,847,"188 × 58 · 20 px",14,muted)
		rect(353,764,168,64,"#11616a","#d6ad67")
		text_at(369,802,"Details / Pass",20,ink,true)
		text_at(353,853,"168 × 64 · 20 px",14,muted)
		rect(550,764,312,64,"#20334b","#d6ad67")
		text_at(566,802,"Confirm Pass / enemy acts",20,ink,true)
		text_at(550,853,"312 × 64 · 20 px; retain full label",14,muted)
		rect(890,764,142,92,"#20334b","#d6ad67")
		text_at(902,790,"Conjure Spark",15,ink,true)
		text_at(905,837,"1",21,ink,true)
		text_at(890,880,"142 × 92",14,muted)
		text_at(48,916,"NATIVE 360-WIDE INSPECTOR / 23 PX BODY + SCROLL",15,gold)
		rect(48,938,328,335,"#162735","#d6ad67")
		text_at(70,977,"Free Spark",28,ink,true)
		var body_lines = ["6 damage. Cost 0.","Temporary rune; cleared", "after Cast or Pass.","Input W · output E.","Rotate changes ports."]
		for i in range(body_lines.size()): text_at(70,1023+i*33,body_lines[i],23,ink,true)
		rect(357,997,5,199,"#0a1520")
		rect(357,997,5,88,"#8797a8")
		rect(64,1209,296,48,"#20334b","#d6ad67")
		text_at(187,1240,"Close",20,ink)
		text_at(417,950,"NUMERAL / PUNCTUATION CHECK",15,gold)
		text_at(417,994,"6  0  8  1     0 / 6     32 / 32",21,ink,true)
		text_at(417,1033,"0 O    1 I    5 S    ×  –  '    →",21,ink,true)
		text_at(417,1080,"14 px: Spark  /  15 px: Free Spark",14,ink,true)
		text_at(417,1113,"18 px: 0 / 6   32 / 32   6 0 8 1",18,ink,true)
		text_at(417,1153,"Small board labels remain a device review item.",17,muted)
		text_at(417,1180,"Narrow layout scrolls; full inspector text is never",17,muted)
		text_at(417,1205,"uniformly shrunk to fit. The baseline font is not",17,muted)
		text_at(417,1230,"evidence of Noto Serif appearance or font clearance.",17,muted)
		line(48,1300,1004)
		text_at(48,1328,"Source: Noto official project + Google Fonts OFL pages · exact binaries/licence package: RC-012",15,muted)

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var sheet := Sheet.new()
	sheet.font = ThemeDB.fallback_font
	# Existing engine fallback only; retained to reproduce review art, never runtime adoption.
	var font_copy := FileAccess.open("res://engine-fallback-preview-only.woff2",FileAccess.WRITE)
	font_copy.store_buffer((sheet.font as FontFile).data)
	font_copy.close()
	sheet.size = Vector2(1100,1360)
	root.size = Vector2i(1100,1360)
	root.add_child(sheet)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUTPUT.get_base_dir())
	var err := image.save_png(OUTPUT)
	var f := FileAccess.open(SVG_OUTPUT,FileAccess.WRITE)
	f.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="1360" viewBox="0 0 1100 1360"><title>RC-011 typography source — editable live text; PNG is authoritative fallback render</title><metadata>Fallback family: %s; no font file embedded. Replacement on systems lacking this family may change metrics.</metadata>%s</svg>' % [sheet.font.get_font_name().xml_escape(),"\n".join(sheet.svg)])
	f.close()
	var font_evidence = {"engine":Engine.get_version_info(),"fallback_font_class":sheet.font.get_class(),"fallback_family":sheet.font.get_font_name(),"fallback_style":sheet.font.get_font_style_name(),"actual_source":"ThemeDB.fallback_font from existing pinned engine","candidate_fonts_obtained":false,"standalone_font_files_written":true,"font_file_purpose":"engine-fallback-preview-only.woff2 preserves existing engine bytes for isolated SVG/raster review reproduction; not an acquired or cleared production font","capture_dimensions":[image.get_width(),image.get_height()],"save_error":err,"measurements":sheet.measurements}
	f = FileAccess.open(EVIDENCE,FileAccess.WRITE)
	f.store_string(JSON.stringify(font_evidence,"  "))
	f.close()
	print(JSON.stringify({"image":OUTPUT,"dimensions":[image.get_width(),image.get_height()],"family":sheet.font.get_font_name(),"save_error":err}))
	quit(err)
