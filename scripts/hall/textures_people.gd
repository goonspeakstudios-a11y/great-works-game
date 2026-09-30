extends RefCounted
## The people set: the textures of everyone who walks the places (kit.gd's walker and all who
## are built on it: Rome's citizens, the togati, Homer's heroes, the teachers), in the hall's
## pixel style. Each is made in the person's own colour, so the folds of a tunic are shades of
## its dye and a face is drawn on its own skin. Textures.material("c_<name>#rrggbb") makes a
## material of each (the colour quantised, so a crowd shares a few dozen textures); make() below
## is what it calls.
##
## Cloth (one image round a cylinder or over a sphere, its own UVs):
##   c_tunic    the woven tunic: the weave, four soft folds round it, the belt at the waist
##   c_skirt    the tunic below the belt: its folds and the hem's embroidered border
##   c_toga     undyed wool, the folds running slantwise as the toga is thrown
##   c_dress    the long dress of the women (the stola, the chiton): narrow pleats, a deep hem
##   c_cloak    a cloak's coarse wool, plain
## Skin and hair:
##   c_skin     skin, mottled
##   c_face     the face on the head's sphere: eyes, brows, the mouth, the cheeks, the chin's shadow
##   c_hair     hair, in strands
## Leather and linen (tiled over the world):
##   c_leather  the sandals' and belts' leather, stitched
##   c_linen    an apron's or a headcloth's fine linen

const TILE := 64


## What Textures.material needs for `kind` ("tunic", "face"...) in `tint`: the texture and whether
## it lies on its mesh ("uv") or tiles over the world ("scale").
static func make(kind: String, tint: Color) -> Dictionary:
	match kind:
		"tunic":
			return {"tex": tunic(tint), "uv": true}
		"skirt":
			return {"tex": skirt(tint), "uv": true}
		"toga":
			return {"tex": toga(tint), "uv": true}
		"dress":
			return {"tex": dress(tint), "uv": true}
		"cloak":
			return {"tex": cloak(tint), "uv": true}
		"skin":
			return {"tex": skin(tint), "uv": true}
		"face":
			return {"tex": face(tint), "uv": true}
		"hair":
			return {"tex": hair(tint), "uv": true}
		"leather":
			return {"tex": leather(), "scale": 4.0}
		"linen":
			return {"tex": linen(), "scale": 3.0}
	return {}


## The material name for `kind` in `hex`, its colour rounded to sixteen steps a channel: what a
## walker asks for, so two tunics dyed nearly alike share one texture.
static func key(kind: String, hex: String) -> String:
	var c := Color("#" + hex.trim_prefix("#"))
	var q := Color(roundf(c.r * 15.0) / 15.0, roundf(c.g * 15.0) / 15.0, roundf(c.b * 15.0) / 15.0)
	return "c_%s#%s" % [kind, q.to_html(false)]


static func _img(w: int = TILE, h: int = TILE) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	return img


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## The weave: every other thread a touch lighter, and a few slubs.
static func _weave(rng: RandomNumberGenerator, c: Color, x: int, y: int, amount: float = 0.04) -> Color:
	var out := c
	if y % 2 == 0:  # the weft, a thread lighter
		out = out.lightened(amount * 0.6)
	if x % 3 == 0:  # the warp, a thread darker
		out = out.darkened(amount * 0.4)
	var n := rng.randf()
	if n < 0.03:
		out = out.darkened(0.08)
	elif n > 0.97:
		out = out.lightened(0.05)
	return out


## A fold's shading round a cylinder: `folds` soft dark valleys with a bright ridge beside each.
static func _fold(x: int, folds: int, depth: float, shift: float = 0.0) -> float:
	var t := fmod(float(x) / TILE * folds + shift, 1.0)
	var valley := pow(maxf(0.0, sin(t * PI)), 3.0)  # deep in the middle of each fold
	var ridge := pow(maxf(0.0, sin((t + 0.35) * PI)), 12.0) * 0.5
	return 1.0 - depth * valley + depth * ridge


static func tunic(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(401)
	var belt := Color("5a4030")
	for y in TILE:
		for x in TILE:
			var shade := _fold(x, 4, 0.22)
			var px := Color(c.r * shade, c.g * shade, c.b * shade)
			px = _weave(rng, px, x, y)
			if y >= 52 and y <= 58:  # the belt
				px = belt.lightened(0.08) if y == 52 or y == 58 else belt
				if x % 16 == 8 and y >= 54 and y <= 56:
					px = Color("a08850")  # a stud
			elif y > 58:  # the cloth blousing over the belt
				px = px.darkened(0.1)
			elif y < 3:  # the neck's shadow under the shoulders
				px = px.darkened(0.2)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func skirt(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(403)
	var border := c.darkened(0.35)
	var thread := Color("d8c890") if c.get_luminance() < 0.6 else Color("8a6a40")
	for y in TILE:
		for x in TILE:
			var shade := _fold(x, 5, 0.24, 0.3)
			var px := Color(c.r * shade, c.g * shade, c.b * shade)
			px = _weave(rng, px, x, y)
			if y >= 56:  # the hem: a dark border with an embroidered line in it
				px = border
				if y == 58 or (y == 60 and x % 4 < 2):
					px = thread
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func toga(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(405)
	for y in TILE:
		for x in TILE:
			var shade := _fold(x + y / 2, 3, 0.16, 0.1)  # the folds slant as the cloth is thrown
			shade *= 1.0 - 0.06 * pow(maxf(0.0, sin(float(y) / TILE * PI * 2.0)), 2.0)
			var px := Color(c.r * shade, c.g * shade, c.b * shade)
			px = _weave(rng, px, x, y, 0.03)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func dress(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(407)
	var border := c.darkened(0.4)
	for y in TILE:
		for x in TILE:
			var shade := _fold(x, 8, 0.2)
			var px := Color(c.r * shade, c.g * shade, c.b * shade)
			px = _weave(rng, px, x, y, 0.03)
			if y >= 58:  # the deep hem, a band of the darker dye
				px = border if y != 58 else border.lightened(0.15)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func cloak(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(409)
	for y in TILE:
		for x in TILE:
			var shade := _fold(x, 2, 0.14, 0.5)
			var px := Color(c.r * shade, c.g * shade, c.b * shade)
			img.set_pixel(x, y, _weave(rng, px, x, y, 0.06))
	return ImageTexture.create_from_image(img)


static func skin(c: Color) -> ImageTexture:
	var img := _img(32, 32)
	var rng := _rng(411)
	for y in 32:
		for x in 32:
			var n := rng.randf()
			var px := c
			if n < 0.12:
				px = c.darkened(0.05)
			elif n > 0.92:
				px = c.lightened(0.04)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


## The face, drawn for a sphere whose seam (u = 0) is the front: the features straddle the
## image's left and right edges. The eyes sit a little above the middle, the mouth below.
static func face(c: Color) -> ImageTexture:
	var w := 64
	var h := 32
	var img := _img(w, h)
	var rng := _rng(413)
	var dark := c.darkened(0.55)
	var blush := Color(minf(1.0, c.r * 1.05), c.g * 0.88, c.b * 0.86)
	for y in h:
		for x in w:
			var px := c
			var n := rng.randf()
			if n < 0.1:
				px = c.darkened(0.05)
			elif n > 0.93:
				px = c.lightened(0.04)
			if y >= 26:  # the shadow under the chin
				px = px.darkened(0.12 + 0.03 * (y - 26))
			img.set_pixel(x, y, px)
	var col := func(k: int) -> int: return posmod(k, w)
	for side: int in [-1, 1]:
		var ex: int = col.call(side * 4)  # the eye's inner corner is 4 columns from the front seam
		var ex2: int = col.call(side * 5)
		for yy in [13, 14]:
			img.set_pixel(ex, yy, Color("f2eee6"))
			img.set_pixel(ex2, yy, Color("f2eee6"))
		img.set_pixel(ex, 14, Color("2a1e14"))  # the iris, looking a little toward you
		img.set_pixel(col.call(side * 3), 14, dark.darkened(0.2))  # the eye's inner shadow
		for k in range(3, 7):  # the brow
			img.set_pixel(col.call(side * k), 11, dark)
		img.set_pixel(col.call(side * 6), 12, dark.lightened(0.1))
		for yy in range(15, 18):  # the cheek
			img.set_pixel(col.call(side * 7), yy, blush)
			img.set_pixel(col.call(side * 8), yy, blush)
		img.set_pixel(col.call(side * 9), 16, blush.darkened(0.06))
	for k in range(-2, 3):  # the mouth
		img.set_pixel(col.call(k), 21, Color("8a4a3e"))
	img.set_pixel(col.call(-3), 20, dark.lightened(0.1))
	img.set_pixel(col.call(3), 20, dark.lightened(0.1))
	for k in range(-1, 2):
		img.set_pixel(col.call(k), 22, c.darkened(0.2))  # the lower lip's shadow
	for k in range(-1, 2):  # the shadow the nose casts (the nose itself is a box on the head)
		img.set_pixel(col.call(k), 17, c.darkened(0.16))
		img.set_pixel(col.call(k), 18, c.darkened(0.1))
	return ImageTexture.create_from_image(img)


static func hair(c: Color) -> ImageTexture:
	var img := _img()
	var rng := _rng(415)
	var strands: Array = []
	for x in TILE:
		strands.append(rng.randf_range(-0.16, 0.12))
	for y in TILE:
		for x in TILE:
			var wave := int(sin(float(y) / TILE * PI * 3.0 + x * 0.2) * 1.5)
			var s: float = strands[posmod(x + wave, TILE)]
			var px := c.lightened(s) if s > 0.0 else c.darkened(-s)
			if rng.randf() < 0.04:
				px = px.darkened(0.2)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func leather() -> ImageTexture:
	var img := _img(32, 32)
	var rng := _rng(417)
	var base := Color("6a4a34")
	for y in 32:
		for x in 32:
			var px := base
			var n := rng.randf()
			if n < 0.2:
				px = base.darkened(0.1)
			elif n > 0.9:
				px = base.lightened(0.08)
			if (y == 4 or y == 27) and x % 3 != 2:  # the stitching
				px = Color("c8b088")
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func linen() -> ImageTexture:
	var img := _img(32, 32)
	var rng := _rng(419)
	var base := Color("e2d8c4")
	for y in 32:
		for x in 32:
			img.set_pixel(x, y, _weave(rng, base, x, y, 0.035))
	return ImageTexture.create_from_image(img)
