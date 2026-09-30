extends RefCounted
## The house set: the textures of Rome's houses (rome_map.gd's blocks), in the hall's pixel style
## (64 pixels to a 4 m tile, a couple of dozen colours each, the pale ones tinted per house).
## Textures.material("h_<name>") makes a material of each; make() below is what it calls.
##
## Walls (world-tiled, 4 m a tile):
##   h_plaster        lime plaster, mottled, a damp band at the foot, a hairline crack, a chip or two
##   h_plaster_worn   the same, patched, with the brick showing through where it has fallen
##   h_brick          Roman brick facing: thin bricks each its own red, a yellow bonding course
##   h_tufa           opus quadratum: big blocks of tufa, pitted, wet at the foot
##   h_timber         opus craticium: plaster panels in a frame of dark timbers with a brace
##   h_stucco         drafted stucco of the good houses: incised blocks, a red dado, an ochre band
## Roofs (world-tiled):
##   h_roof           curved tiles over flat ones, each its own terracotta, a little moss and lichen
##   h_roof_moss      the same, older: mossier, darker, a tile or two slipped
##   h_roof_broken    burnt or fallen: holes to the rafters
## Fronts (one image to one quad, its own UVs):
##   h_shop           a shop bay: the arched opening, shutters folded back, the counter and its pots
##   h_shop_shut      the same bay shut for the night: planks across it and a bar
##   h_door           a house door: planks, iron bands and studs, a stone frame and a threshold
##   h_door_red, h_door_green   painted
##   h_window         a window's wooden frame and its sill (the middle clear, for the glass behind)
##   h_window_small   a small high window of the old houses, barred
##   h_shutter        one leaf of a shutter, planks and crossbars
##   h_cloth          washing on a line, pale (tinted the colours of tunics), with its folds
##   h_vine           a vine climbing a wall (clear round the leaves)
##   h_sign           a shop's painted board: a frame and a pale field for its picture

const TILE := 64


## What Textures.material needs for `kind`: the texture, and whether it tiles over the world
## (scale, 0.25 = 4 m a tile) or lies on its quad ("uv"), and whether it has clear parts ("cut").
static func make(kind: String) -> Dictionary:
	match kind:
		"h_plaster":
			return {"tex": plaster(false), "scale": 0.25}
		"h_plaster_worn":
			return {"tex": plaster(true), "scale": 0.25}
		"h_brick":
			return {"tex": brick(), "scale": 0.25}
		"h_tufa":
			return {"tex": tufa(), "scale": 0.25}
		"h_timber":
			return {"tex": timber(), "scale": 0.25}
		"h_stucco":
			return {"tex": stucco(), "scale": 0.25}
		"h_roof":
			return {"tex": roof(0), "scale": 0.5}
		"h_roof_moss":
			return {"tex": roof(1), "scale": 0.5}
		"h_roof_broken":
			return {"tex": roof(2), "scale": 0.5}
		"h_shop":
			return {"tex": shop(false), "uv": true}
		"h_shop_shut":
			return {"tex": shop(true), "uv": true}
		"h_door":
			return {"tex": door(Color("6a4a2a"), Color("5e4024")), "uv": true}
		"h_door_red":
			return {"tex": door(Color("8a3a2a"), Color("7a3224")), "uv": true}
		"h_door_green":
			return {"tex": door(Color("4a6a3a"), Color("405c32")), "uv": true}
		"h_window":
			return {"tex": window(false), "uv": true, "cut": true}
		"h_window_small":
			return {"tex": window(true), "uv": true, "cut": true}
		"h_shutter":
			return {"tex": shutter(), "uv": true}
		"h_cloth":
			return {"tex": cloth(), "uv": true, "cut": true}
		"h_vine":
			return {"tex": vine(), "uv": true, "cut": true}
		"h_sign":
			return {"tex": signboard(), "uv": true}
	return {}


static func _img(w: int = TILE, h: int = TILE) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## A few tones of one colour, picked by chance: the mottling of every real surface.
static func _mottle(rng: RandomNumberGenerator, c: Color, dark: float = 0.06, light: float = 0.05) -> Color:
	var n := rng.randf()
	if n < 0.18:
		return c.darkened(dark)
	if n > 0.9:
		return c.lightened(light)
	return c


# ---------- walls ----------

static func plaster(worn: bool) -> ImageTexture:
	var img := _img()
	var rng := _rng(311 if not worn else 313)
	var base := Color("e6dfd0")
	for y in TILE:
		for x in TILE:
			img.set_pixel(x, y, _mottle(rng, base, 0.05, 0.04))  # (the damp at the foot is a band of geometry: the tile repeats up the wall)
	# a hairline crack wandering down
	var cx := rng.randi_range(8, 56)
	for y in range(rng.randi_range(2, 12), rng.randi_range(30, 50)):
		cx = clampi(cx + rng.randi_range(-1, 1), 1, 62)
		img.set_pixel(cx, y, base.darkened(0.3))
	# chips, and where worn, patches down to the brick
	var patches := 2 if not worn else 6
	for k in patches:
		var px := rng.randi_range(0, 60)
		var py := rng.randi_range(4, 48)
		var pw := rng.randi_range(3, 6 if not worn else 14)
		var ph := rng.randi_range(2, 4 if not worn else 9)
		for dy in ph:
			for dx in pw:
				if rng.randf() < 0.15 and (dx == 0 or dx == pw - 1 or dy == 0 or dy == ph - 1):
					continue  # a ragged edge
				var xx := (px + dx) % TILE
				var yy := (py + dy) % TILE
				var brickish := Color("b07050") if ((yy / 3) % 2 == 0) != ((xx / 6) % 2 == 0) else Color("a4664a")
				if yy % 3 == 0:
					brickish = Color("c8b498")
				img.set_pixel(xx, yy, brickish if worn or rng.randf() < 0.5 else Color("cfc4ac"))
	if worn:  # streaks of grime running down from the sills
		for k in 4:
			var sx := rng.randi_range(2, 60)
			for y in range(rng.randi_range(10, 20), rng.randi_range(30, 56)):
				img.set_pixel(sx, y, img.get_pixel(sx, y).darkened(0.12))
	return ImageTexture.create_from_image(img)


static func brick() -> ImageTexture:
	var img := _img()
	var rng := _rng(317)
	var reds := [Color("a45034"), Color("9a4830"), Color("b05a3c"), Color("8e4630"), Color("a85838"), Color("b46448")]
	var mortar := Color("c8b89c")
	var course_h := 4
	var brick_w := 12
	for y in TILE:
		var course := y / course_h
		var bonding := course % 8 == 7
		var off := (brick_w / 2) if course % 2 == 1 else 0
		for x in TILE:
			var c: Color
			if bonding:
				c = Color("d4b880") if y % course_h != 0 and (x + off) % 24 != 0 else mortar
				c = _mottle(rng, c, 0.08, 0.04)
			elif y % course_h == 0 or (x + off) % brick_w == 0:
				c = mortar
			else:
				var which: int = (course * 7 + (x + off) / brick_w) % reds.size()
				c = _mottle(rng, reds[which], 0.1, 0.06)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func tufa() -> ImageTexture:
	var img := _img()
	var rng := _rng(331)
	var face := Color("c4b48a")
	var joint := Color("8e8264")
	var rows := 6
	var row_h := TILE / rows  # 10 px, about 65 cm
	var block_w := 21
	for y in TILE:
		var row := y / row_h
		var off := (block_w / 2) if row % 2 == 1 else 0
		for x in TILE:
			var c: Color
			if y % row_h == 0 or (x + off) % block_w == 0:
				c = joint
			else:
				var which: int = (row * 5 + (x + off) / block_w) % 3
				c = _mottle(rng, [face, face.darkened(0.06), face.lightened(0.04)][which], 0.05, 0.05)
				if rng.randf() < 0.05:
					c = c.darkened(0.25)  # the pits in the stone
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func timber() -> ImageTexture:
	var img := _img()
	var rng := _rng(337)
	var panel := Color("dfd3b8")
	var beam := Color("5a3e28")
	for y in TILE:
		for x in TILE:
			var c := _mottle(rng, panel, 0.05, 0.03)
			if x % 16 < 3 or y >= 60 or y < 3:  # the uprights a metre apart, the sill and the head beam
				c = _mottle(rng, beam, 0.1, 0.05)
			elif y >= 30 and y < 33:
				c = _mottle(rng, beam, 0.1, 0.05)  # the rail at mid height
			else:
				var px := x % 16
				var py := y % 30
				if absi(px - 3 - py * 10 / 30) < 2 and py < 27:  # a brace across each lower panel
					c = beam
			if y >= 56 and y < 60:
				c = c.lerp(Color("a89c84"), 0.4)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func stucco() -> ImageTexture:
	var img := _img()
	var rng := _rng(347)
	var cream := Color("e8dcc4")
	var ochre := Color("c8a060")
	var red := Color("8a3a2a")
	for y in TILE:
		for x in TILE:
			var c := _mottle(rng, cream, 0.04, 0.03)  # (the red dado and its ochre band are geometry: the tile repeats up the wall)
			var row := y / 16
			var off := 16 if row % 2 == 1 else 0
			if y % 16 == 0 or (x + off) % 32 == 0:
				c = cream.darkened(0.18)  # the drafted joints, cut into the stucco
			elif y % 16 == 1 or (x + off) % 32 == 1:
				c = cream.lightened(0.05)  # the lit edge of each block
			if rng.randf() < 0.01:
				c = ochre.lerp(cream, 0.5)
			if rng.randf() < 0.004:
				c = red.lerp(cream, 0.6)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# ---------- roofs ----------

## 0 new, 1 old and mossy, 2 broken.
static func roof(state: int) -> ImageTexture:
	var img := _img()
	var rng := _rng(353 + state)
	var tones := [Color("a4563a"), Color("b0604a"), Color("984e34"), Color("ac5c3e"), Color("9c5236")]
	if state == 1:
		tones = [Color("8e4c34"), Color("966044"), Color("7e4630"), Color("8c5240"), Color("866a58")]
	for y in TILE:
		var row := y / 16  # a tile a row, 1 m long at 0.5
		for x in TILE:
			var col := x / 8  # a tile across, 0.5 m
			var t: Color = tones[(row * 3 + col * 5) % tones.size()]
			var c := _mottle(rng, t, 0.08, 0.05)
			var cx := x % 8
			if cx < 3:  # the round cover tile: lit on one side, shadowed on the other
				c = t.lightened(0.14) if cx == 1 else (t.darkened(0.16) if cx == 0 else t.lightened(0.04))
			elif cx == 7:
				c = t.darkened(0.3)  # the shadow under the next cover tile
			if y % 16 == 0 or y % 16 == 15:
				c = c.darkened(0.28)  # the overlap of the row above
			if state >= 1 and rng.randf() < (0.14 if state == 1 else 0.06):
				c = Color("6a7a4a") if rng.randf() < 0.7 else Color("c8c0a0")  # moss, lichen
			elif state == 0 and rng.randf() < 0.03:
				c = Color("c8c0a0") if rng.randf() < 0.5 else Color("6a7a4a")
			img.set_pixel(x, y, c)
	if state == 1:  # a tile or two slipped
		for k in 2:
			var sx := rng.randi_range(0, 7) * 8
			var sy := rng.randi_range(0, 3) * 16 + 4
			for dy in 6:
				for dx in 7:
					img.set_pixel((sx + dx) % TILE, (sy + dy) % TILE, Color("5a4030"))
	if state == 2:  # holes to the rafters, the tiles round them blackened
		for k in 5:
			var hx := rng.randi_range(0, 56)
			var hy := rng.randi_range(0, 52)
			var hw := rng.randi_range(6, 14)
			var hh := rng.randi_range(6, 12)
			for dy in hh + 4:
				for dx in hw + 4:
					var xx := (hx + dx - 2) % TILE
					var yy := (hy + dy - 2) % TILE
					var inside := dx >= 2 and dx < hw + 2 and dy >= 2 and dy < hh + 2
					img.set_pixel(xx, yy, (Color("2a2018") if (yy % 5 != 0) else Color("4a3a2a")) if inside else img.get_pixel(xx, yy).darkened(0.45))
	return ImageTexture.create_from_image(img)


# ---------- fronts ----------

## A shop bay: brick jambs, the arch of stone over the opening, and inside it either the shop at
## its business (shutters folded back, the counter with its pots) or the shutters up for the night.
static func shop(shut: bool) -> ImageTexture:
	var img := _img()
	var rng := _rng(359)
	var jamb := Color("a45034")
	var mortar := Color("c8b89c")
	var stone := Color("cbbfa4")
	var dark := Color("1c1410")
	for y in TILE:
		for x in TILE:
			var c := jamb if (y % 4 != 0 and (x + (3 if (y / 4) % 2 else 0)) % 8 != 0) else mortar
			c = _mottle(rng, c, 0.08, 0.04)
			var dx := x - 32
			var top := 6
			var inside := absi(dx) < 21 and y >= top and (y > top + 8 or dx * dx + (y - top - 8) * (y - top - 8) < 21 * 21)
			var arch := not inside and absi(dx) < 25 and y >= top - 4 and (y <= top + 8 and dx * dx + (y - top - 8) * (y - top - 8) < 25 * 25)
			if arch:
				c = stone.darkened(0.12) if (absi(dx) + y) % 5 == 0 else stone  # the voussoirs
			if y < 4:
				c = Color("a83a2a") if x % 9 in [2, 3, 5, 6] and y > 0 and y < 3 else Color("e4d8b8")  # the painted notice over the arch
			if inside:
				if shut:
					c = Color("6a4a2a") if (x % 5) != 0 else Color("4a3220")  # the planks
					if y >= 34 and y < 37:
						c = Color("3a2a1a")  # the bar
					if rng.randf() < 0.05:
						c = c.darkened(0.15)
				else:
					c = dark
					if absi(dx) >= 15:
						c = Color("6a4a2a") if (y % 6) != 0 else Color("4a3220")  # the shutters folded back at the jambs
					elif y >= 40:
						c = Color("a08a68") if (y % 6 != 0 and x % 7 != 0) else Color("7a6848")  # the counter of masonry
						if y >= 40 and y < 44 and absi(dx) < 14:
							c = Color("c8b090")  # its top slab
					if y >= 33 and y < 41 and absi(dx) < 14:  # the pots on the counter, and a stack of loaves
						var on := (dx + 14) % 9
						if on < 4:
							c = Color("8a4a30") if y < 40 else Color("6e3a24")
						elif on > 5 and y > 36:
							c = Color("c8a060")
					if y >= 12 and y < 30 and absi(dx) < 14 and rng.randf() < 0.04:
						c = Color("3a2c20")  # the goods hung in the dark inside
			if y >= 61:
				c = Color("d0c6b0") if x % 21 != 0 else Color("9a9078")  # the threshold slabs
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## A house door, 32 x 64 (1.6 by 2.8 m or so).
static func door(plank: Color, plank2: Color) -> ImageTexture:
	var img := _img(32, 64)
	var rng := _rng(367)
	var frame := Color("c4b494")
	for y in 64:
		for x in 32:
			var c: Color
			if x < 3 or x >= 29 or y < 4:
				c = _mottle(rng, frame, 0.06, 0.04)  # the stone jambs and lintel
			elif y >= 61:
				c = Color("a89a80")  # the threshold, worn
			else:
				c = _mottle(rng, plank if ((x - 3) / 5) % 2 == 0 else plank2, 0.08, 0.04)
				if (x - 3) % 5 == 0:
					c = c.darkened(0.3)  # the joint between planks
				if y in [18, 19, 44, 45]:
					c = Color("3a3a3c")  # the iron bands
					if (x - 4) % 6 == 0:
						c = Color("6a6a6c")  # the studs
				if x >= 22 and x < 25 and y >= 32 and y < 34:
					c = Color("8a7a3a")  # the ring
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## A window's frame and sill, the middle clear (the pane behind it is the night's lamplight). Small:
## the high barred window of the old houses.
static func window(small: bool) -> ImageTexture:
	var img := _img(32, 48)
	var rng := _rng(373)
	var wood := Color("7a5a3a")
	for y in 48:
		for x in 32:
			var c := Color(0, 0, 0, 0)
			if x < 3 or x >= 29 or y < 3:
				c = _mottle(rng, wood, 0.1, 0.05)
			elif y >= 42:
				c = Color("c8bca0") if y < 46 else Color("a8a088")  # the sill, and the grime under it
			elif small and (x - 3) % 7 == 3:
				c = Color("3a3a3c")  # the bars
			elif not small and y >= 21 and y < 24:
				c = wood.darkened(0.1)  # the transom
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func shutter() -> ImageTexture:
	var img := _img(16, 48)
	var rng := _rng(379)
	for y in 48:
		for x in 16:
			var c := _mottle(rng, Color("6a4a2a") if (x / 4) % 2 == 0 else Color("5e4024"), 0.08, 0.04)
			if x % 4 == 0:
				c = c.darkened(0.3)
			if y in [8, 9, 38, 39]:
				c = Color("4a3220")
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Washing on the line: a tunic's worth of cloth, pale, tinted by the house; the folds and the pegs.
static func cloth() -> ImageTexture:
	var img := _img(32, 32)
	var rng := _rng(383)
	for y in 32:
		for x in 32:
			var c := Color(0, 0, 0, 0)
			if y >= 2 and x >= 2 and x < 30 and (y < 30 or x % 6 > 1):  # a ragged hem
				c = Color("eee6d8")
				if (x + y / 4) % 7 == 0:
					c = c.darkened(0.1)  # the folds
				if y < 4 and x % 8 == 4:
					c = Color("8a6a4a")  # the pegs
			elif y < 2 and x % 8 == 4:
				c = Color("8a6a4a")
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func vine() -> ImageTexture:
	var img := _img(32, 64)
	var rng := _rng(389)
	var stem_x := 16
	for y in range(63, -1, -1):
		stem_x = clampi(stem_x + rng.randi_range(-1, 1), 4, 27)
		img.set_pixel(stem_x, y, Color("5a4a2a"))
		if rng.randf() < 0.45:  # a leaf out to one side
			var side := -1 if rng.randf() < 0.5 else 1
			var lx := stem_x + side * rng.randi_range(2, 5)
			var leaf := Color("4a6a34") if rng.randf() < 0.6 else Color("5a7a3a")
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if absi(dx) + absi(dy) <= 3 and lx + dx >= 0 and lx + dx < 32 and y + dy >= 0 and y + dy < 64:
						img.set_pixel(lx + dx, y + dy, leaf if (dx + dy) % 2 == 0 else leaf.darkened(0.12))
			img.set_pixel(clampi(stem_x + side, 0, 31), y, Color("5a4a2a"))
	return ImageTexture.create_from_image(img)


static func signboard() -> ImageTexture:
	var img := _img(32, 24)
	var rng := _rng(397)
	for y in 24:
		for x in 32:
			var c := _mottle(rng, Color("e8dcc0"), 0.05, 0.03)
			if x < 2 or x >= 30 or y < 2 or y >= 22:
				c = _mottle(rng, Color("6a4a2a"), 0.1, 0.05)
			elif x < 3 or x >= 29 or y < 3 or y >= 21:
				c = Color("a83a2a")  # the painted border
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
