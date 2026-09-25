extends RefCounted
## A 48x64 pixel portrait of an author, painted in code from a few settings
## (skin, hair style and colour, beard, robe). Lit from the left, dark background.

const W := 48
const H := 64
const HEAD := Vector2(24, 27)
const RX := 9.5
const RY := 12.5


static func make(p: Dictionary) -> ImageTexture:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var skin := Color(p.get("skin", "c49a78"))
	var hair := Color(p.get("hair_color", "3a2a1e"))
	var beard := Color(p.get("beard_color", p.get("hair_color", "3a2a1e")))
	var robe := Color(p.get("robe", "4a4a5a"))
	var trim := Color(p.get("trim", "8a7a50"))
	var style: String = p.get("hair", "short")
	var beard_style: String = p.get("beard", "none")
	for y in H:
		for x in W:
			img.set_pixel(x, y, _background(x, y))
	for y in range(44, H):  # shoulders and robe
		var half := 13.0 + (y - 44) * 0.9
		for x in W:
			if absf(x - 23.5) <= half:
				var c := robe.darkened(0.25) if x > 23.5 + half * 0.4 else robe
				if absi(x - (8 + (y - 44))) <= 1:
					c = trim
				img.set_pixel(x, y, c)
	for y in range(37, 47):  # neck
		for x in range(20, 28):
			img.set_pixel(x, y, skin.darkened(0.25 if x > 24 else 0.12))
	for y in H:  # head, shaded on the right
		for x in W:
			var d := _in_head(x, y)
			if d <= 1.0:
				var c := skin
				if x > 27:
					c = skin.darkened(0.22)
				elif x < 19 and y < 30:
					c = skin.lightened(0.08)
				img.set_pixel(x, y, c)
	for ey in range(25, 30):  # ears
		img.set_pixel(14, ey, skin.darkened(0.1))
		img.set_pixel(34, ey, skin.darkened(0.3))
	_hair(img, style, hair)
	for x in [19, 20, 27, 28]:  # brows and eyes
		img.set_pixel(x, 22, hair.darkened(0.3) if style != "bald" else skin.darkened(0.4))
	for ex in [19, 27]:
		img.set_pixel(ex, 24, Color("e8e0d0"))
		img.set_pixel(ex + 1, 24, Color("1a1410"))
	for ny in range(24, 31):  # nose
		img.set_pixel(24, ny, skin.darkened(0.18))
	img.set_pixel(23, 31, skin.darkened(0.3))
	img.set_pixel(24, 31, skin.darkened(0.3))
	if p.get("old", false):
		for x in range(18, 30, 2):
			img.set_pixel(x, 18, skin.darkened(0.2))
		img.set_pixel(18, 26, skin.darkened(0.2))
		img.set_pixel(30, 26, skin.darkened(0.3))
	for x in range(21, 28):  # mouth
		img.set_pixel(x, 34, Color("6a3a2e"))
	_beard(img, beard_style, beard)
	return ImageTexture.create_from_image(img)


static func _in_head(x: int, y: int) -> float:
	return Vector2((x + 0.5 - HEAD.x) / RX, (y + 0.5 - HEAD.y) / RY).length()


static func _background(x: int, y: int) -> Color:
	var base := Color("241f2c").lerp(Color("141118"), float(y) / H)
	var edge := Vector2((x - W / 2.0) / (W / 2.0), (y - H / 2.0) / (H / 2.0)).length()
	return base.darkened(clampf(edge - 0.6, 0.0, 0.5))


static func _hair(img: Image, style: String, c: Color) -> void:
	if style == "bald":
		return
	for y in H:
		for x in W:
			var d := _in_head(x, y)
			var top := y < 19 and d <= 1.08
			var sides := y >= 19 and y < 27 and d <= 1.08 and d >= 0.82
			var back := style == "long" and y >= 19 and y < 44 and absf(x + 0.5 - HEAD.x) >= 8 and absf(x + 0.5 - HEAD.x) <= 12
			if style == "receding":
				top = y < 19 and d <= 1.08 and d >= 0.7 and y > 14
			if top or sides or back:
				img.set_pixel(x, y, c.darkened(0.2) if x > 27 else c)


static func _beard(img: Image, style: String, c: Color) -> void:
	if style == "none":
		return
	var bottom := 50 if style == "long" else 40
	for y in range(31, bottom):
		for x in W:
			var in_face := _in_head(x, y) <= 1.05 and y >= 32
			var below := y >= 38 and absf(x + 0.5 - HEAD.x) <= (9.0 - (y - 38) * 0.6)
			if in_face or below:
				if y == 34 and x >= 22 and x <= 26:
					continue  # keep a hint of the mouth
				img.set_pixel(x, y, c.darkened(0.18) if x > 27 else c)
	for x in range(20, 29):  # moustache
		img.set_pixel(x, 32, c.darkened(0.1))
