extends RefCounted

# Independently measured coordinates in the unchanged generated PNG. These
# constants deliberately do not read CombatSurface's implementation geometry.
const SOURCE_PATH := "res://assets/ui/combat/reference/status-frame.png"
const SOURCE_HASH := "20c72868838eb163dbc83cabe4e989488fa330d756cccd2dde180fff113da573"
const SOURCE_SIZE := Vector2(1987,791)
const SOURCE_X := [20.0,683.5,1302.5,1968.0]
const SOURCE_Y := [270.0,314.0,458.0,502.0]

static func source_comparison(picture: Image, imported: Image) -> Dictionary:
	var source_scale := Vector2(imported.get_size())/SOURCE_SIZE
	var target_x := [0.0,picture.get_width()/3.0,picture.get_width()*2/3.0,float(picture.get_width())]
	var target_y := [0.0,8.0,picture.get_height()-8.0,float(picture.get_height())]
	var count := 0
	var total := 0.0
	var worst := 0.0
	for y in picture.get_height():
		for x in picture.get_width():
			var point := Vector2(x+0.5,y+0.5)
			var column := 0 if point.x < target_x[1] else 1 if point.x < target_x[2] else 2
			var row := 0 if point.y < target_y[1] else 1 if point.y < target_y[2] else 2
			var source := Vector2(lerpf(SOURCE_X[column],SOURCE_X[column+1],inverse_lerp(target_x[column],target_x[column+1],point.x)),lerpf(SOURCE_Y[row],SOURCE_Y[row+1],inverse_lerp(target_y[row],target_y[row+1],point.y)))
			var expected := _bilinear(imported,source*source_scale-Vector2(0.5,0.5))
			# The generated painting has nearopaque253/255 pixels throughout.
			# Ignore exterior antialiasing, but retain its actual alpha bytes.
			if expected.a < 0.98: continue
			var actual := picture.get_pixel(x,y)
			var error := color_error(actual,expected)
			total += error
			worst = maxf(worst,error)
			count += 1
	return {"samples":count,"mean_rgb_error":total/maxi(count,1),"maximum_rgb_error":worst}

static func _bilinear(picture: Image, point: Vector2) -> Color:
	var x := clampi(floori(point.x),0,picture.get_width()-2)
	var y := clampi(floori(point.y),0,picture.get_height()-2)
	return picture.get_pixel(x,y).lerp(picture.get_pixel(x+1,y),point.x-x).lerp(picture.get_pixel(x,y+1).lerp(picture.get_pixel(x+1,y+1),point.x-x),point.y-y)

static func is_gold(color: Color) -> bool:
	return color.a > 0.90 and color.r > 0.18 and color.r > color.g*1.03 and color.g > color.b*1.15

static func color_error(first: Color, second: Color) -> float:
	return maxf(absf(first.r-second.r),maxf(absf(first.g-second.g),absf(first.b-second.b)))

static func perimeter_continuity(picture: Image) -> Dictionary:
	var width := picture.get_width()
	var height := picture.get_height()
	var scale := height/54.0
	var vertical_band := ceili(8*scale)
	var side_band := maxi(ceili(width*60.0/1948.0),ceili(8*scale))
	var corner_x := ceili(width*100.0/1948.0)
	var corner_y := ceili(12*scale)
	var missing := {"top":0,"bottom":0,"left":0,"right":0}
	for x in range(corner_x,width-corner_x):
		var top := false
		var bottom := false
		for inset in vertical_band:
			top = top or is_gold(picture.get_pixel(x,inset))
			bottom = bottom or is_gold(picture.get_pixel(x,height-1-inset))
		if not top: missing.top += 1
		if not bottom: missing.bottom += 1
	for y in range(corner_y,height-corner_y):
		var left := false
		var right := false
		for inset in side_band:
			left = left or is_gold(picture.get_pixel(inset,y))
			right = right or is_gold(picture.get_pixel(width-1-inset,y))
		if not left: missing.left += 1
		if not right: missing.right += 1
	# Check the joints as well as each straight side. A flood from outside
	# must not reach any face; disconnected gold marks cannot pass this test.
	var seen := PackedByteArray()
	seen.resize(width*height)
	var frontier: Array[Vector2i] = []
	for x in width:
		frontier.append(Vector2i(x,0))
		frontier.append(Vector2i(x,height-1))
	for y in range(1,height-1):
		frontier.append(Vector2i(0,y))
		frontier.append(Vector2i(width-1,y))
	var index := 0
	while index < frontier.size():
		var point := frontier[index]
		index += 1
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height: continue
		var offset := point.y*width+point.x
		if seen[offset] or is_gold(picture.get_pixelv(point)): continue
		seen[offset] = 1
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: frontier.append(point+step)
	var enclosed := true
	for sixth in [1,3,5]: enclosed = enclosed and seen[(height/2)*width+roundi(width*sixth/6.0)] == 0
	var complete := enclosed
	for count in missing.values(): complete = complete and count == 0
	return {"complete":complete,"encloses_face":enclosed,"missing_gold_segments":missing,"exterior_reachable_pixels":seen.count(1)}
