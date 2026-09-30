extends RefCounted
## The green set: what grows in Rome (rome_map.gd's trees, groves, gardens, banks and pots), in
## the hall's pixel style. A tree is a trunk and two or three crossed quads of one of these,
## clear round the leaves, so a crown reads as a mass of leaves and not a green ball.
## Textures.material("g_<name>") makes a material of each; make() below is what it calls.
##
## Crowns and clumps (one image to one quad, clear round the leaves):
##   g_crown     a round-headed tree: plane, fig, oak, laurel; sunlit above, dark under
##   g_pine      the Italian stone pine's flat umbrella crown, dark, on nothing
##   g_cypress   the cypress's narrow spire, for a quad five times taller than wide
##   g_olive     the olive's grey-green crown, thin, the sky through it
##   g_bush      a bush of box or myrtle, small bright leaves
##   g_reeds     a stand of reeds at the water, stalks and seed heads
##   g_grass     a tuft of grass
##   g_flowers   a clump of flowers: poppies, oleander, daisies
## Sheets (tiled over the world):
##   g_canopy    a vine's leaves over a pergola, the sky in holes between them
##   g_turf      a garden's lawn, greener than the hills, a daisy now and then
##   g_bark      a trunk's bark

const TILE := 64


## What Textures.material needs for `kind`: the texture, and whether it lies on its quad ("uv")
## with clear parts ("cut") or tiles over the world ("scale").
static func make(kind: String) -> Dictionary:
	match kind:
		"g_crown":
			return {"tex": crown(0), "uv": true, "cut": true}
		"g_pine":
			return {"tex": crown(1), "uv": true, "cut": true}
		"g_cypress":
			return {"tex": cypress(), "uv": true, "cut": true}
		"g_olive":
			return {"tex": crown(2), "uv": true, "cut": true}
		"g_bush":
			return {"tex": bush(), "uv": true, "cut": true}
		"g_reeds":
			return {"tex": reeds(), "uv": true, "cut": true}
		"g_grass":
			return {"tex": tuft(false), "uv": true, "cut": true}
		"g_flowers":
			return {"tex": tuft(true), "uv": true, "cut": true}
		"g_canopy":
			return {"tex": canopy(), "scale": 0.5, "cut": true}
		"g_turf":
			return {"tex": turf(), "scale": 0.35}
		"g_bark":
			return {"tex": bark(), "scale": 1.0}
	return {}


static func _img(w: int = TILE, h: int = TILE) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## A leaf clump: a rough disc of one green, lit from the upper left, painted over what is there.
static func _clump(img: Image, cx: int, cy: int, r: int, c: Color, rng: RandomNumberGenerator) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x - cx, y - cy).length()
			if d > r - 0.5 + rng.randf_range(-0.8, 0.6):
				continue
			var px := c
			var lit := (cx - x) * 0.4 + (cy - y) * 0.6  # toward the upper left, lighter
			if lit > r * 0.35:
				px = c.lightened(0.14)
			elif lit < -r * 0.35:
				px = c.darkened(0.16)
			if rng.randf() < 0.08:
				px = px.lightened(0.1)
			img.set_pixel(x, y, px)


## A round crown (0), the pine's flat one (1), or the olive's thin grey one (2).
static func crown(style: int) -> ImageTexture:
	var img := _img()
	var rng := _rng(501 + style)
	var greens: Array = [Color("3e6a2e"), Color("4a7a36"), Color("58883e"), Color("2e5424")]
	if style == 1:
		greens = [Color("2c4a28"), Color("34562e"), Color("3e6236"), Color("223a20")]
	elif style == 2:
		greens = [Color("6e8462"), Color("7e9470"), Color("8ea080"), Color("5a7050")]
	var n := 70 if style != 2 else 44
	for k in n:
		var cx: int
		var cy: int
		if style == 1:  # the umbrella: wide, in the upper two thirds, flat on top
			cx = rng.randi_range(4, 60)
			cy = rng.randi_range(16, 42)
			cy = mini(cy, 22 + int(absf(cx - 32) * 0.6))  # sagging toward the ends
		else:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 24.0
			cx = 32 + int(cos(a) * d * 1.05)
			cy = 30 + int(sin(a) * d * 0.95)
		_clump(img, cx, cy, rng.randi_range(4, 7) if style != 2 else rng.randi_range(3, 5), greens[rng.randi() % greens.size()], rng)
	if style == 1:  # the ragged underside where the boughs show
		for x in range(6, 58, 5):
			var y0 := 40 + int(absf(x - 32) * 0.4)
			for y in range(y0, mini(63, y0 + rng.randi_range(4, 9))):
				img.set_pixel(x, y, Color("4a3826"))
	elif style == 2:  # holes in the olive's crown
		for k in 14:
			var hx := rng.randi_range(10, 54)
			var hy := rng.randi_range(10, 50)
			for y in range(hy - 1, hy + 2):
				for x in range(hx - 1, hx + 2):
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func cypress() -> ImageTexture:
	var img := _img(32, 128)
	var rng := _rng(507)
	var dark := Color("223a1e")
	var mid := Color("2c4a26")
	var light := Color("3a5c30")
	for y in 128:
		var half := 14.0 * sin(float(y) / 128.0 * PI * 0.92 + 0.1)  # a spindle, its point at the top
		if y > 100:
			half = maxf(half, 7.0 - (y - 100) * 0.2)
		for x in 32:
			var d := absf(x - 15.5)
			if d > half + rng.randf_range(-1.2, 0.6):
				continue
			var px := mid
			if x < 13 and rng.randf() < 0.6:
				px = light
			elif x > 19 or rng.randf() < 0.3:
				px = dark
			if (y + x) % 7 == 0:
				px = px.darkened(0.12)
			img.set_pixel(x, y, px)
	for x in range(13, 19):  # the trunk showing at the foot
		for y in range(120, 128):
			img.set_pixel(x, y, Color("4a3826"))
	return ImageTexture.create_from_image(img)


static func bush() -> ImageTexture:
	var img := _img()
	var rng := _rng(509)
	var greens: Array = [Color("4e7e32"), Color("5a8c3a"), Color("6a9c46"), Color("3e6a2a")]
	for k in 60:
		var a := rng.randf() * PI  # the upper half only: a mound
		var d := sqrt(rng.randf()) * 26.0
		_clump(img, 32 + int(cos(a) * d * 1.1), 46 - int(sin(a) * d * 0.7), rng.randi_range(3, 5), greens[rng.randi() % greens.size()], rng)
	for y in range(52, 64):  # flat at the bottom, on the ground
		for x in TILE:
			if img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, Color("2e4e22") if y < 60 else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func reeds() -> ImageTexture:
	var img := _img()
	var rng := _rng(511)
	for k in 12:
		var x0 := rng.randi_range(4, 59)
		var lean := rng.randf_range(-0.12, 0.12)
		var top := rng.randi_range(2, 20)
		var c := Color("7a8a3e") if rng.randf() < 0.6 else Color("9a9a4a")
		for y in range(top, 64):
			var x := x0 + int((64 - y) * lean)
			if x < 0 or x >= TILE:
				continue
			img.set_pixel(x, y, c if y % 9 != 0 else c.darkened(0.2))
			if y < top + 8:  # the seed head
				img.set_pixel(x, y, Color("8a6a3a"))
				if x + 1 < TILE and rng.randf() < 0.5:
					img.set_pixel(x + 1, y, Color("a08050"))
	for k in 6:  # a leaf blade leaning off a stalk
		var x0 := rng.randi_range(6, 56)
		var y0 := rng.randi_range(24, 48)
		var dir := 1 if rng.randf() < 0.5 else -1
		for t in 10:
			var x := x0 + dir * t
			var y := y0 - int(t * 0.8)
			if x >= 0 and x < TILE and y >= 0:
				img.set_pixel(x, y, Color("6a8a38"))
	return ImageTexture.create_from_image(img)


## A tuft of grass, or of flowers on their stems.
static func tuft(flowering: bool) -> ImageTexture:
	var img := _img()
	var rng := _rng(513 if not flowering else 515)
	var greens: Array = [Color("6a8a3a"), Color("7a9a44"), Color("8aa450"), Color("5a7a32")]
	var petals: Array = [Color("c8302a"), Color("e06a8a"), Color("f0ece0"), Color("e8c040")]
	for k in 26:
		var x0 := rng.randi_range(20, 44)
		var lean := rng.randf_range(-0.9, 0.9)
		var top := rng.randi_range(10, 36)
		var c: Color = greens[rng.randi() % greens.size()]
		for y in range(top, 64):
			var x := x0 + int((64 - y) * lean * (1.0 - float(64 - y) / 64.0))
			if x < 0 or x >= TILE:
				continue
			img.set_pixel(x, y, c if y > 40 else c.lightened(0.08))
		if flowering and rng.randf() < 0.55:
			var fc: Color = petals[rng.randi() % petals.size()]
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var fx := x0 + int((64 - top) * lean * (1.0 - float(64 - top) / 64.0)) + dx
					var fy := top + dy
					if fx >= 0 and fx < TILE and fy >= 0 and (dx == 0 or dy == 0):
						img.set_pixel(fx, fy, fc)
			img.set_pixel(clampi(x0 + int((64 - top) * lean * (1.0 - float(64 - top) / 64.0)), 0, 63), top, fc.darkened(0.3))
	return ImageTexture.create_from_image(img)


static func canopy() -> ImageTexture:
	var img := _img()
	var rng := _rng(517)
	var greens: Array = [Color("4a7a30"), Color("5a8a3a"), Color("6a9a44"), Color("3e6a2a")]
	for k in 40:
		_clump(img, rng.randi_range(0, 63), rng.randi_range(0, 63), rng.randi_range(4, 7), greens[rng.randi() % greens.size()], rng)
	for k in 8:  # the stems between the leaves
		var x0 := rng.randi_range(0, 63)
		for y in TILE:
			var x := (x0 + int(sin(y * 0.3) * 2.0)) % TILE
			if img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, Color("6a4a2a"))
	# the image wraps: what was painted off one edge is not, so soften the seams with more clumps
	for k in 10:
		_clump(img, rng.randi_range(-3, 3) if rng.randf() < 0.5 else rng.randi_range(60, 66), rng.randi_range(0, 63), 5, greens[rng.randi() % 4], rng)
	return ImageTexture.create_from_image(img)


static func turf() -> ImageTexture:
	var img := _img()
	var rng := _rng(519)
	var base := Color("5e8a3c")
	for y in TILE:
		for x in TILE:
			var n := rng.randf()
			var px := base
			if n < 0.2:
				px = base.darkened(0.08)
			elif n > 0.85:
				px = base.lightened(0.08)
			if rng.randf() < 0.01:
				px = Color("f0ecdc") if rng.randf() < 0.7 else Color("e8c040")  # a daisy, a buttercup
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)


static func bark() -> ImageTexture:
	var img := _img(32, 32)
	var rng := _rng(521)
	var base := Color("5a4632")
	for y in 32:
		for x in 32:
			var px := base
			if (x + (y / 6) * 3) % 5 == 0:
				px = base.darkened(0.25)  # the furrows
			elif rng.randf() < 0.15:
				px = base.lightened(0.08)
			img.set_pixel(x, y, px)
	return ImageTexture.create_from_image(img)
