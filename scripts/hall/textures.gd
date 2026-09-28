extends RefCounted
## Small pixel textures and the materials that use them. Most textures repeat in world
## space (triplanar), so any shape can wear them without UVs.

static var _cache := {}


static func material(kind: String) -> Material:
	if _cache.has(kind):
		return _cache[kind]
	if kind.begins_with("#"):  # a plain colour, e.g. "#2e3a5a" for a robe
		var c := StandardMaterial3D.new()
		c.albedo_color = Color(kind)
		c.roughness = 1.0
		_cache[kind] = c
		return c
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	var world_tex := func(tex: Texture2D, scale: float) -> void:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(scale, scale, scale)
	if kind.begins_with("ph_"):  # a CC0 Poly Haven texture, e.g. "ph_marble_tiles" (assets/polyhaven)
		var path := "res://assets/polyhaven/textures/%s.png" % kind.substr(3)
		if ResourceLoader.exists(path):
			world_tex.call(load(path), 0.25)
		else:
			push_warning("missing texture " + path)
			m.albedo_color = Color("ff00ff")
		_cache[kind] = m
		return m
	match kind:
		"marble":
			world_tex.call(_noise(Color("e4dccb"), Color("cfc5b0"), Color("f2ece0"), 11), 0.5)
		"stone":
			world_tex.call(_blocks(Color("b8ab92"), Color("7e7260"), 16, 8), 0.5)
		"rock":
			world_tex.call(_noise(Color("7a6a58"), Color("5e5044"), Color("948270"), 5), 0.25)
		"earth":
			world_tex.call(_noise(Color("8a8658"), Color("747048"), Color("9c986a"), 7), 0.35)
		"path":
			world_tex.call(_noise(Color("b09a74"), Color("9a8662"), Color("c0ac86"), 9), 0.35)
		"paving":
			world_tex.call(_blocks(Color("c4bcaa"), Color("948c7c"), 16, 16), 0.5)
		"plaster":
			world_tex.call(_plaster(), 0.25)
		"roof":
			world_tex.call(_blocks(Color("a8583a"), Color("7a3a24"), 8, 4), 0.5)
		"wood":
			world_tex.call(_grain(Color("5a4028"), Color("3e2c1c")), 1.0)
		"trunk":
			m.albedo_color = Color("4a3a2a")
		"olive":
			world_tex.call(_noise(Color("6e7c5c"), Color("566448"), Color("8a9874"), 3), 1.0)
		"cypress":
			world_tex.call(_noise(Color("2e4428"), Color("243620"), Color("3a5432"), 4), 1.0)
		"bronze":
			m.albedo_color = Color("8a6a3a")
			m.metallic = 0.6
			m.roughness = 0.45
		"gold":
			m.albedo_color = Color("a08040")
			m.metallic = 0.7
			m.roughness = 0.4
		"parchment":
			m.albedo_color = Color("d8c8a0")
		"water":
			m.albedo_color = Color("2a5068")
			m.roughness = 0.12
			m.metallic = 0.35
		"sea":
			m.albedo_color = Color("24445e")
			m.roughness = 0.08
			m.metallic = 0.4
		"snow":
			m.albedo_color = Color("e8e4e0")
		"smoke":
			m.albedo_color = Color(0.45, 0.42, 0.42, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		"fire":
			m.albedo_color = Color("ffb050")
			m.emission_enabled = true
			m.emission = Color("ff8a30")
			m.emission_energy_multiplier = 2.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"glow":
			m.albedo_color = Color(1.0, 0.86, 0.6, 0.55)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"moth":
			m.albedo_color = Color("e8e0cc")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		"firefly":
			m.vertex_color_use_as_albedo = true
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.disable_fog = true
		"beam":
			m.albedo_color = Color(1.0, 0.85, 0.6, 0.13)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"dark":
			m.albedo_color = Color("1a1612")
		"clay":
			world_tex.call(_noise(Color("a86a48"), Color("8e5638"), Color("b87c58"), 13), 0.5)
		"deadwood":
			world_tex.call(_noise(Color("7a746c"), Color("5e5852"), Color("908a82"), 19), 0.5)
		"withered":
			world_tex.call(_noise(Color("6e6250"), Color("564c3e"), Color("857866"), 23), 1.0)
		"drybed":
			world_tex.call(_noise(Color("9a8a70"), Color("6e6250"), Color("aa9c84"), 29), 0.4)
		"ashbed":
			world_tex.call(_noise(Color("8a8886"), Color("6a6866"), Color("a4a2a0"), 31), 1.0)
		"bone":
			world_tex.call(_noise(Color("d8d0b4"), Color("b8ae90"), Color("e8e2cc"), 37), 1.0)
		"verdigris":
			world_tex.call(_noise(Color("5e7c62"), Color("46604a"), Color("7a9a7a"), 41), 1.0)
		"soulfire":
			m.albedo_color = Color("a8f0e0")
			m.emission_enabled = true
			m.emission = Color("7ae8d0")
			m.emission_energy_multiplier = 3.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"ash":
			m.albedo_color = Color("c4c0bc")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		"plane":
			world_tex.call(_noise(Color("7c9a58"), Color("607c44"), Color("98b070"), 6), 1.0)
		"bark":
			world_tex.call(_noise(Color("a09a88"), Color("7e7868"), Color("c0b8a4"), 17), 0.5)
		"rug":
			m.albedo_texture = _rug()  # spans the rug's own surface, not the world
		"plaque":
			m.albedo_texture = _plaque()
		"shield", "shield_dead":
			m.albedo_texture = _shield() if kind == "shield" else _shield(Color("26342c"), Color("5e7c62"), Color("76865a"), Color("4e5e46"))
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		# the Nexus
		"voidstone":  # the dark stone the broken realm of the mind is made of
			world_tex.call(_blocks(Color("3a3c46"), Color("24252c"), 16, 8), 0.5)
		"void":  # a door onto nothing: near-black with a few grey specks
			m.albedo_texture = _void()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"glow_cold":  # an open door whose world has gone cold
			m.albedo_color = Color(0.72, 0.78, 0.88, 0.5)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"daysky":  # blue daylight with one cloud, the only blue in the Nexus
			m.albedo_texture = _daysky()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"mote", "mote_gold":  # faint drifting light: rivers in the void, the thread to the altar
			m.albedo_color = Color(0.72, 0.70, 0.82, 0.3) if kind == "mote" else Color(1.0, 0.85, 0.55, 0.6)
			m.vertex_color_use_as_albedo = true  # lets a particle's colour ramp fade it in and out
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			m.disable_fog = true
		"beam_faint":  # the thread of a beam over a cold altar
			m.albedo_color = Color(1.0, 0.85, 0.6, 0.06)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Rome
		"travertine":  # the cream limestone of Rome's great buildings, pitted in thin streaks
			world_tex.call(_travertine(), 0.5)
		"tufa":  # the soft yellow-grey volcanic stone of the early city
			world_tex.call(_noise(Color("a89a6a"), Color("8a7e52"), Color("bcae80"), 43), 0.4)
		"brick":  # long, thin Roman bricks in pale mortar (opus latericium)
			world_tex.call(_blocks(Color("9a4a32"), Color("cbbd9c"), 16, 4), 0.5)
		"reticulatum":  # a net of small square stones set on the diagonal (opus reticulatum)
			world_tex.call(_reticulate(Color("b0a078"), Color("8a7c5c"), Color("d0c4a4")), 0.5)
		"cobble":  # the city's floor: small bricks set on edge in herringbone (opus spicatum)
			world_tex.call(_herringbone(Color("7a4c3a"), Color("6a4032"), Color("857260")), 0.35)
		"rubble":  # the emptied city's floor: broken brick, mortar dust and stone chips
			world_tex.call(_rubble(), 0.35)
		"insula", "insula_ochre", "insula_rose", "insula_white":  # a block of flats: its storeys of windows
			world_tex.call(_storeys(kind), 0.25)
		# Rome's city, sharper than Greece: 64-pixel textures, and pale ones meant to be tinted
		"r_ground":  # the city's streets: beaten earth and grit with worn-in cobbles
			world_tex.call(_r_ground(Color("786c5e"), 181), 0.25)
		"r_dirt":  # darker trodden dirt, puddle-stained
			world_tex.call(_r_ground(Color("6e6050"), 191), 0.3)
		"r_wall":  # lime plaster over brick, pale, to be tinted any colour; a stone course each storey
			world_tex.call(_r_wall(), 0.25)
		"r_brick":  # bare brick facing (opus testaceum) with bonding courses
			world_tex.call(_r_brick(), 0.25)
		"r_shop":  # a row of shop fronts: arched openings, wooden shutters, a counter
			world_tex.call(_r_shop(), 0.25)
		"r_roof":  # rows of curved tiles (imbrices) over flat ones (tegulae)
			world_tex.call(_r_roof(), 0.5)
		"r_slab":  # travertine slabs of a pavement or a shop's step
			world_tex.call(_r_slab(), 0.3)
		"leaves":  # a garden's leaves: box, myrtle, vines
			world_tex.call(_noise(Color("4a6a34"), Color("36522a"), Color("6a8a44"), 197), 1.0)
		"awning":  # a shop's striped awning
			world_tex.call(_stripes(Color("a8342a"), Color("e0d0b0")), 1.0)
		"terracotta":
			world_tex.call(_noise(Color("b0643e"), Color("94502e"), Color("c47a52"), 131), 1.0)
		"basalt":  # the dark polygonal blocks of a paved Roman road
			world_tex.call(_polygons(Color("4c4c50"), Color("2c2c30"), 71), 0.8)
		"mosaic":  # a floor of small white stones with a black pattern
			world_tex.call(_mosaic(), 0.5)
		"fresco":  # a painted Pompeian wall: black frieze, red panels framed in yellow, black dado
			world_tex.call(_fresco(), 0.25)
		"porphyry":  # the purple stone only emperors used
			world_tex.call(_noise(Color("6a2a3a"), Color("521e2c"), Color("b8909a"), 47), 1.0)
		"giallo":  # giallo antico, the yellow marble of Numidia
			world_tex.call(_noise(Color("d8b870"), Color("c09c50"), Color("e8d090"), 53), 0.5)
		"pine":  # the dark flat crown of an Italian stone pine
			world_tex.call(_noise(Color("3e5a34"), Color("2e4628"), Color("56704a"), 59), 1.0)
		"toga":  # undyed wool, the citizen's white
			world_tex.call(_noise(Color("e8e2d2"), Color("d6cfbe"), Color("f2eee2"), 61), 2.0)
		"iron":  # polished iron plate: the legionary's armour and helmet
			m.albedo_color = Color("8a8e94")
			m.metallic = 0.6
			m.roughness = 0.45
		"rust":  # the same iron after the world was lost
			world_tex.call(_noise(Color("6a4430"), Color("4e3224"), Color("845a3c"), 109), 1.0)
		"scutum", "scutum_dead":  # the legionary's curved shield: red, gold wings and thunderbolts
			m.albedo_texture = _scutum(kind == "scutum_dead")
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Greece, the places still to come
		"hoplon_sparta", "hoplon_athens", "hoplon_dead":  # a hoplite's round shield and its device
			m.albedo_texture = _hoplon(kind.trim_prefix("hoplon_"))
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"persian":  # the Immortals' robes: blue, with a lattice of yellow rosettes
			world_tex.call(_rosettes(), 2.0)
		"wicker":  # woven osier, the Persian shield (spara) and baskets
			world_tex.call(_weave(Color("b09060"), Color("7a6040")), 2.0)
		"blackfigure":  # a painted pot: black glaze, a key band, black figures on orange clay
			world_tex.call(_blackfigure(), 1.5)
		"papyrus":  # a sheet of papyrus, its fibres crossing
			world_tex.call(_papyrus(), 2.0)
		"sand":
			world_tex.call(_noise(Color("d8c49a"), Color("c4ae82"), Color("e8d8b4"), 67), 0.35)
		"dune":  # the open desert, a warmer, deeper sand than the beach
			world_tex.call(_noise(Color("d6b47a"), Color("c09a62"), Color("e6c890"), 97), 0.18)
		"limestone":  # Egyptian dressed limestone in coursed blocks
			world_tex.call(_blocks(Color("dcc8a0"), Color("b09a70"), 8, 4), 0.5)
		"casing":  # the smooth white Tura limestone of a pyramid's casing
			world_tex.call(_noise(Color("ece0c0"), Color("ddd0aa"), Color("f8f0dc"), 91), 0.3)
		"hieroglyphs":  # a wall or shaft cut with columns of painted hieroglyphs
			world_tex.call(_hieroglyphs(), 0.6)
		"egypt_band":  # painted bands of blue, gold, red and green, for cornices, capitals and collars
			world_tex.call(_egypt_band(), 1.2)
		"nemes":  # the pharaoh's striped headcloth, gold and blue
			world_tex.call(_nemes(), 4.0)
		"grass":  # greener ground than the dry earth of Attica: Troy's plain, the Boeotian fields
			world_tex.call(_noise(Color("6e8a48"), Color("58743a"), Color("86a05a"), 73), 0.35)
		"furrows":  # a ploughed field, the ridges running along X
			world_tex.call(_furrows(), 0.5)
		"cave":  # the dark rock of Plato's cave
			world_tex.call(_noise(Color("4a4038"), Color("3a322c"), Color("5a5046"), 79), 0.3)
		"mist":  # ground mist: a soft grey cloud that fades out at its edges
			m.albedo_texture = _cloud(71)
			m.albedo_color = Color(0.72, 0.72, 0.76, 0.4)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		"shadow":  # a shadow cast on the cave wall
			m.albedo_color = Color(0.02, 0.02, 0.03, 0.6)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[kind] = m
	return m


## Speckled texture from three tones: stone, earth, leaves.
static func _noise(base: Color, dark: Color, light: Color, seed_value: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in 32:
		for x in 32:
			var n := rng.randf()
			img.set_pixel(x, y, dark if n < 0.22 else (light if n > 0.88 else base))
	return ImageTexture.create_from_image(img)


static func _blocks(face: Color, mortar: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = w * 31 + h
	for y in 32:
		for x in 32:
			var off := (w / 2) if (y / h) % 2 else 0
			var c := face
			if y % h == 0 or (x + off) % w == 0:
				c = mortar
			else:
				var n := rng.randf()
				c = face.darkened(0.1) if n < 0.25 else (face.lightened(0.06) if n > 0.9 else face)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Roman wall paint: dark red below, warm cream above (the texture spans 4 m of wall).
static func _plaster() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in 32:
		for x in 32:
			var c := Color("d8ccb0") if y < 20 else Color("8a3a2a")
			if y == 20 or y == 21:
				c = Color("c8a060")
			if rng.randf() < 0.12:
				c = c.darkened(0.08)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _grain(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			img.set_pixel(x, y, b if (y + (x / 5)) % 4 == 0 else a)
	return ImageTexture.create_from_image(img)


## A woollen rug: a crimson field with a small diamond weave, framed by a Greek key.
static func _rug() -> ImageTexture:
	const W := 64
	const H := 40
	const UNIT := ["########", ".......#", "#####..#", "#...#..#", "#.###..#", "#......#"]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var field := Color("7a2a2a")
	var weave := Color("6a2424")
	var cream := Color("e0cfa8")
	for y in H:
		for x in W:
			img.set_pixel(x, y, weave if (x + y) % 8 == 0 or (x - y) % 8 == 0 else field)
	for y in 6:  # the key runs along the top and bottom edges
		for x in W:
			if UNIT[y][x % 8] == "#":
				img.set_pixel(x, y + 1, cream)
				img.set_pixel(x, H - 2 - y, cream)
	for x in 6:  # and, turned on its side, up the two ends
		for y in H:
			if UNIT[x][y % 8] == "#":
				img.set_pixel(x + 1, y, cream)
				img.set_pixel(W - 2 - x, y, cream)
	for x in W:
		img.set_pixel(x, 0, cream)
		img.set_pixel(x, H - 1, cream)
	for y in H:
		img.set_pixel(0, y, cream)
		img.set_pixel(W - 1, y, cream)
	return ImageTexture.create_from_image(img)


## A Macedonian shield: a bronze rim round a blue field bearing the sixteen-rayed sun of
## the Argead kings (the star of Vergina), in gold. Round; the corners are cut away. The dead
## men's shields are the same, gone green and black with age.
static func _shield(field := Color("2a3a7a"), rim := Color("8a6a3a"), gold := Color("e0b640"),
		boss := Color("a8862a")) -> ImageTexture:
	const N := 40
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := (N - 1) / 2.0
	for y in N:
		for x in N:
			var dx := x - c
			var dy := y - c
			var r := sqrt(dx * dx + dy * dy)
			if r > c:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := rim if r > c - 2.5 else field
			var a := atan2(dy, dx)
			var k := roundf(a / (TAU / 16.0))
			var off := absf(a - k * (TAU / 16.0))  # angle away from the nearest ray
			var reach := (c - 4.0) if int(k) % 2 == 0 else (c - 8.0)
			if r <= 3.2 or (r > 2.0 and r < reach and off < 0.16 * (1.0 - r / reach) + 0.04):
				col = gold
			if r <= 1.2:
				col = boss
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## Nothing, seen through a sealed door: near-black, with a few grey specks of far stars.
static func _void() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("06060a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for k in 8:
		img.set_pixel(rng.randi_range(1, 30), rng.randi_range(1, 30), Color("4a4c58").lightened(rng.randf_range(0.0, 0.3)))
	return ImageTexture.create_from_image(img)


## A patch of blue daylight: deeper blue overhead, paler near the bottom, with one white cloud.
static func _daysky() -> ImageTexture:
	const W := 32
	const H := 48
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var top := Color("4a7cc4")
	var low := Color("a8c8ec")
	for y in H:
		var c := top.lerp(Color("6a9ad8"), clampf(y / 24.0, 0.0, 1.0)).lerp(low, clampf((y - 24.0) / 24.0, 0.0, 1.0))
		for x in W:
			img.set_pixel(x, y, c)
	for puff in [[Vector2(11, 28), 4.0], [Vector2(16, 26), 5.0], [Vector2(21, 28), 3.6], [Vector2(15, 29.5), 4.2]]:
		var at: Vector2 = puff[0]
		var r: float = puff[1]
		for y in range(int(at.y - r), int(at.y + r) + 1):
			for x in range(int(at.x - r * 1.4), int(at.x + r * 1.4) + 1):
				if x < 0 or x >= W or y < 0 or y >= H:
					continue
				var d := Vector2((x - at.x) / 1.4, y - at.y).length()
				if d <= r:
					img.set_pixel(x, y, Color("dfe4ee") if y > at.y + r * 0.45 else Color("f6f8fc"))
	return ImageTexture.create_from_image(img)


## A soft cloud for the nebulae: white value noise in the alpha, fading out toward a round edge.
## The nebula tints it.
static func _cloud(seed_value: int) -> ImageTexture:
	const N := 64
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var coarse: Array = []  # 9x9 lattice (8 px cells) and 17x17 (4 px cells) of random values
	var fine: Array = []
	for i in 81:
		coarse.append(rng.randf())
	for i in 289:
		fine.append(rng.randf())
	var sample := func(grid: Array, side: int, cell: float, x: float, y: float) -> float:
		var gx := x / cell
		var gy := y / cell
		var ix := mini(int(gx), side - 2)
		var iy := mini(int(gy), side - 2)
		var fx := smoothstep(0.0, 1.0, gx - ix)
		var fy := smoothstep(0.0, 1.0, gy - iy)
		var a: float = lerpf(grid[iy * side + ix], grid[iy * side + ix + 1], fx)
		var b: float = lerpf(grid[(iy + 1) * side + ix], grid[(iy + 1) * side + ix + 1], fx)
		return lerpf(a, b, fy)
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := (N - 1) / 2.0
	for y in N:
		for x in N:
			var n: float = 0.65 * sample.call(coarse, 9, 8.0, x, y) + 0.35 * sample.call(fine, 17, 4.0, x, y)
			var r := Vector2(x - c, y - c).length() / c
			var fall := pow(clampf(1.0 - r, 0.0, 1.0), 1.3)
			var a := clampf((n - 0.2) * 1.7, 0.0, 1.0) * fall
			var v := 0.75 + 0.25 * n  # a little lighter where it is thickest
			img.set_pixel(x, y, Color(v, v, v, a))
	return ImageTexture.create_from_image(img)


static func _plaque() -> ImageTexture:
	var img := Image.create(24, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color("8a7a58"))
	for x in 24:
		img.set_pixel(x, 0, Color("5a4a30"))
		img.set_pixel(x, 15, Color("5a4a30"))
	for y in 16:
		img.set_pixel(0, y, Color("5a4a30"))
		img.set_pixel(23, y, Color("5a4a30"))
	for line in [4, 7, 10]:
		for x in range(4, 20 if line != 10 else 14):
			img.set_pixel(x, line, Color("3a2e1e"))
	return ImageTexture.create_from_image(img)


# ---------- Rome ----------

## Travertine: warm cream, with short dark pores lying along the bedding.
static func _travertine() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	var base := Color("dcd0b4")
	for y in 32:
		for x in 32:
			img.set_pixel(x, y, base.darkened(0.05) if rng.randf() < 0.2 else base)
	for k in 22:
		var y := rng.randi_range(0, 31)
		var x0 := rng.randi_range(0, 31)
		for dx in rng.randi_range(2, 5):
			img.set_pixel((x0 + dx) % 32, y, Color("a89a7c"))
	return ImageTexture.create_from_image(img)


## The city's ground, 64 px to 4 m: grit in two tones, with here and there a worn cobble and a
## brick shard pressed in, so it reads as trodden earth, not a pattern.
static func _r_ground(base: Color, seed_value: int) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in 64:
		for x in 64:
			var n := rng.randf()
			var c := base
			if n < 0.25:
				c = base.darkened(0.08)
			elif n > 0.93:
				c = base.lightened(0.1)
			img.set_pixel(x, y, c)
	for k in 18:  # cobbles and shards
		var cx := rng.randi_range(0, 63)
		var cy := rng.randi_range(0, 63)
		var r := rng.randi_range(1, 3)
		var tint := base.lightened(0.07) if rng.randf() < 0.55 else (base.lerp(Color("7a5444"), 0.5) if rng.randf() < 0.4 else base.darkened(0.12))
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy <= r * r:
					img.set_pixel((cx + dx + 64) % 64, (cy + dy + 64) % 64, tint)
	return ImageTexture.create_from_image(img)


## Plaster, near white so it takes a tint (ochre, rose, blue-grey, cream), slightly mottled, with a
## thin stone course and a darker band at the foot of each storey.
static func _r_wall() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 211
	for y in 64:
		for x in 64:
			var c := Color("ece6da")
			var n := rng.randf()
			if n < 0.2:
				c = c.darkened(0.05)
			elif n < 0.24:
				c = c.darkened(0.12)
			if y >= 61:
				c = Color("d8d0c0")  # the string course
			elif y >= 56:
				c = c.darkened(0.08)  # splash and grime at the floor line
			img.set_pixel(x, y, c)
	for k in 5:  # patches where the plaster is worn to the brick
		var cx := rng.randi_range(0, 60)
		var cy := rng.randi_range(4, 50)
		for dy in rng.randi_range(2, 5):
			for dx in rng.randi_range(3, 7):
				img.set_pixel((cx + dx) % 64, (cy + dy) % 64, Color("b8866a") if (dx + dy) % 3 else Color("a87a60"))
	return ImageTexture.create_from_image(img)


static func _r_brick() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 223
	for y in 64:
		for x in 64:
			var course := y / 4
			var off := 6 if course % 2 else 0
			var c := Color("9a5238")
			if y % 4 == 0 or (x + off) % 12 == 0:
				c = Color("c4b496")
			else:
				var n := rng.randf()
				c = c.darkened(0.12) if n < 0.2 else (c.lightened(0.08) if n > 0.9 else c)
			if y >= 60:
				c = Color("b0a48a")  # a bonding course of big tiles
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## The ground storey's shop fronts, 4 m to a tile: a brick arch over each opening, the wooden
## shutters folded back, the dark shop inside, and the step.
static func _r_shop() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 227
	for y in 64:
		for x in 64:
			var c := Color("a4583c") if (y % 4 != 0 and (x + (3 if (y / 4) % 2 else 0)) % 8 != 0) else Color("c4b496")
			var dx := x - 32
			var inside := absi(dx) < 20 and y > 10 and (y > 20 or dx * dx + (y - 20) * (y - 20) < 400)
			if inside:
				c = Color("21170f") if absi(dx) < 14 else Color("5a3c22")  # the dark shop, the shutters
				if y > 44 and absi(dx) < 14:
					c = Color("8a7458")  # the counter
			if absi(dx) >= 20 and absi(dx) < 23 and y > 10 and y < 21 and (dx * dx + (y - 20) * (y - 20) >= 400):
				c = Color("c8baa0")  # the arch's stones
			if y >= 60:
				c = Color("d0c6b0")  # the step
			if rng.randf() < 0.05:
				c = c.darkened(0.1)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _r_roof() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 229
	for y in 64:
		for x in 64:
			var col := x % 8
			var c := Color("a4563a")
			if col < 3:
				c = Color("b8684a") if col == 1 else Color("944a30")  # the round cover tile
			elif col == 7:
				c = Color("6e3622")
			if y % 16 == 0:
				c = c.darkened(0.25)
			if rng.randf() < 0.06:
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _r_slab() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 233
	for y in 64:
		for x in 64:
			var c := Color("d6ccb4")
			if y % 32 == 0 or (x + (16 if (y / 32) % 2 else 0)) % 32 == 0:
				c = Color("9a9078")
			elif rng.randf() < 0.18:
				c = c.darkened(0.06)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Opus spicatum: small bricks laid on edge in a herringbone, in pale mortar.
static func _herringbone(face: Color, dark: Color, mortar: Color) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 127
	for y in 32:
		for x in 32:
			var u := (x + y) % 16  # two diagonal courses, each brick 8 px long and 4 wide
			var v := (x - y + 64) % 16
			var c := face
			if (u < 8 and v % 4 == 0) or (u >= 8 and (x + y) % 4 == 0):
				c = mortar
			elif rng.randf() < 0.2:
				c = dark
			elif rng.randf() < 0.08:
				c = face.lightened(0.06)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## The ground of a city gone to ruin: dust, broken brick and chips of marble.
static func _rubble() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 139
	for y in 32:
		for x in 32:
			var n := rng.randf()
			var c := Color("8a7a66")
			if n < 0.2:
				c = Color("6e604e")
			elif n > 0.92:
				c = Color("c8bca8")
			img.set_pixel(x, y, c)
	for k in 26:  # brick shards
		var x0 := rng.randi_range(0, 31)
		var y0 := rng.randi_range(0, 31)
		var tint := Color("8e4a34") if rng.randf() < 0.7 else Color("a89c86")
		for dx in rng.randi_range(2, 4):
			for dy in rng.randi_range(1, 2):
				img.set_pixel((x0 + dx) % 32, (y0 + dy) % 32, tint)
	return ImageTexture.create_from_image(img)


## One storey of an apartment block (4 m of wall): its face (brick, or plaster in ochre, rose or
## white), a window with its wooden shutter, and a string course of stone under the next floor.
static func _storeys(kind: String) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.length() * 7 + 151
	var face: Color = {"insula": Color("9a4a32"), "insula_ochre": Color("c89a5a"), "insula_rose": Color("b8766a"),
		"insula_white": Color("d8cebc")}[kind]
	for y in 32:
		for x in 32:
			var c := face
			if kind == "insula" and (y % 4 == 0 or (x + (4 if (y / 4) % 2 else 0)) % 8 == 0):
				c = Color("c8b898")  # mortar between the bricks
			elif rng.randf() < 0.15:
				c = face.darkened(0.1)
			if y >= 30:
				c = Color("d0c4a8")  # the string course
			elif x >= 12 and x <= 19 and y >= 8 and y <= 19:
				c = Color("1c1612") if x > 13 else Color("5a4028")  # the window, a shutter folded back
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _stripes(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			img.set_pixel(x, y, a if (x / 4) % 2 == 0 else b)
	return ImageTexture.create_from_image(img)


## Opus reticulatum: square stones turned 45 degrees, in thin mortar lines.
static func _reticulate(face: Color, mortar: Color, light: Color) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 89
	for y in 32:
		for x in 32:
			var c := face
			if (x + y) % 8 == 0 or (x - y + 32) % 8 == 0:
				c = mortar
			elif (x + y) % 8 == 1 and (x - y + 32) % 8 != 1:
				c = light  # the lit lower-left edge of each stone
			elif rng.randf() < 0.2:
				c = face.darkened(0.08)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Polygonal paving: stones of irregular shape (the cells round scattered points, wrapping at
## the edges so the tile repeats), their joints dark.
static func _polygons(face: Color, joint: Color, seed_value: int) -> ImageTexture:
	const N := 32
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts: Array = []
	for k in 11:
		pts.append(Vector2(rng.randf() * N, rng.randf() * N))
	var shade: Array = []
	for k in pts.size():
		shade.append(face.lightened(rng.randf_range(-0.08, 0.1)))
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var best := 1e9
			var second := 1e9
			var which := 0
			for k in pts.size():
				var d: Vector2 = Vector2(x + 0.5, y + 0.5) - pts[k]
				d = Vector2(fposmod(d.x + N / 2.0, N) - N / 2.0, fposmod(d.y + N / 2.0, N) - N / 2.0)
				var l: float = d.length()
				if l < best:
					second = best
					best = l
					which = k
				elif l < second:
					second = l
			img.set_pixel(x, y, joint if second - best < 1.1 else shade[which])
	return ImageTexture.create_from_image(img)


## A black-and-white mosaic floor: white tesserae with faint grout, a black diamond in each
## square and a black line round it.
static func _mosaic() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 97
	var white := Color("e8e2d4")
	var black := Color("26241f")
	for y in 32:
		for x in 32:
			var c := white.darkened(rng.randf_range(0.0, 0.07))
			if x % 2 == 1 and y % 2 == 1:
				c = c.darkened(0.12)  # the grout between the stones
			var d := absi(x - 16) + absi(y - 16)
			if d >= 9 and d <= 10:
				c = black
			if d <= 3:
				c = black
			if x <= 1 or y <= 1:
				c = black
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## A Pompeian painted wall (the texture spans 4 m of wall): a black frieze with a white line,
## red panels framed in yellow, a black dado.
static func _fresco() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for y in 32:
		for x in 32:
			var c := Color("9a2a22")
			if y < 6:
				c = Color("1e1a18") if y != 4 else Color("d8d0c0")
			elif y >= 25:
				c = Color("1e1a18") if y != 26 else Color("7a5a2a")
			elif x % 16 in [1, 2] or y in [7, 23]:
				c = Color("d0a040")
			elif x % 16 == 8 and y > 10 and y < 20:
				c = Color("2a4a3a")  # a slender painted candelabrum between the panels
			if rng.randf() < 0.1:
				c = c.darkened(0.08)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## The legionary's scutum (spans the shield's face): red, a bronze rim and boss, gold eagle
## wings spread from the boss and thunderbolts above and below. The dead men's are faded brown
## and green.
static func _scutum(dead: bool) -> ImageTexture:
	const W := 24
	const H := 40
	var field := Color("5a3a2a") if dead else Color("9a1e1a")
	var gold := Color("76865a") if dead else Color("e0b640")
	var rim := Color("5e7c62") if dead else Color("a07a3a")
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cx := (W - 1) / 2.0
	var cy := (H - 1) / 2.0
	for y in H:
		for x in W:
			var c := field
			var dx := x - cx
			var dy := y - cy
			if x == 0 or y == 0 or x == W - 1 or y == H - 1:
				c = rim
			elif Vector2(dx, dy).length() < 3.2:
				c = rim  # the boss
			elif absf(dy) < 2.5 - absf(dx) * 0.12 and absf(dx) > 3.0 and absf(dx) < 10.0:
				c = gold  # the wings
			elif absf(dx) < 1.0 and absf(dy) > 5.0 and absf(dy) < 16.0:
				c = gold  # the thunderbolt's shaft
			elif absf(dy) > 8.0 and absf(dy) < 15.0 and absi(int(absf(dx)) - int((absf(dy) - 8.0) * 0.6)) == 0:
				c = gold  # its forked zigzags
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# ---------- Greece: the places still to come ----------

## A hoplite's round shield: a bronze rim and a device on the face. "sparta": bronze with the red
## lambda of Lacedaemon. "athens": black, with Athena's owl in white. "dead": green and black.
static func _hoplon(device: String) -> ImageTexture:
	const N := 40
	var field: Color = {"sparta": Color("b08a44"), "athens": Color("1e1c1a"), "dead": Color("3a4436")}.get(device, Color("b08a44"))
	var rim := Color("5e7c62") if device == "dead" else Color("8a6a3a")
	var mark: Color = {"sparta": Color("8a1e1a"), "athens": Color("e8e0cc"), "dead": Color("5a6a4a")}.get(device, Color("8a1e1a"))
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := (N - 1) / 2.0
	for y in N:
		for x in N:
			var dx := x - c
			var dy := y - c
			var r := sqrt(dx * dx + dy * dy)
			if r > c:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := rim if r > c - 3.0 else field
			if r <= c - 3.0:
				if device in ["sparta", "dead"]:
					# the lambda: two strokes meeting at the top, like an upturned V
					var u := (dy + 12.0) / 24.0
					if u >= 0.0 and u <= 1.0 and absf(absf(dx) - u * 10.0) < 1.6:
						col = mark
				else:
					var body := Vector2(dx / 7.0, (dy - 3.0) / 10.0).length() < 1.0
					var ears := dy < -6.0 and dy > -10.0 and absf(dx) > 3.0 and absf(dx) < 7.0 and absf(dx) - 3.0 > -(dy + 6.0)
					var eye := Vector2(absf(dx) - 3.0, dy + 3.0).length() < 1.8
					if (body or ears) and not eye:
						col = mark
					elif eye:
						col = Color("e0b640")
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## Persian court robes: blue, with a lattice of yellow rosettes.
static func _rosettes() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var c := Color("2a4a6a")
			var d := Vector2(x - 7.5, y - 7.5)
			if d.length() < 2.6:
				c = Color("e0b640") if d.length() > 1.0 else Color("f0e0b0")
			elif (x + y) % 16 == 0 or (x - y + 16) % 16 == 0:
				c = Color("223c58")
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Columns of hieroglyphs on pale stone: registers divided by thin lines, each full of small
## signs painted blue, red, green, ochre and black.
static func _hieroglyphs() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 311
	var paint := [Color("2a5a8a"), Color("a03020"), Color("3a7a5a"), Color("c08a30"), Color("2a2218")]
	img.fill(Color("d8c49a"))
	for y in 32:
		for x in 32:
			if rng.randf() < 0.1:
				img.set_pixel(x, y, Color("cbb68a"))
	for col in 4:
		var x0 := col * 8
		for y in 32:
			img.set_pixel(x0, y, Color("8a7450"))  # the line between registers
		var y0 := 1
		while y0 < 30:
			var h := rng.randi_range(2, 4)
			var w := rng.randi_range(2, 5)
			var c: Color = paint[rng.randi() % paint.size()]
			var shape := rng.randi() % 3
			for yy in h:
				for xx in w:
					var keep := shape == 0 or (shape == 1 and (xx + yy) % 2 == 0) or (shape == 2 and (yy == 0 or xx == 0 or xx == w - 1))
					if keep and y0 + yy < 32:
						img.set_pixel(x0 + 2 + xx, y0 + yy, c)
			y0 += h + 2
	return ImageTexture.create_from_image(img)


## Egyptian painted bands, horizontal: blue, gold, red, green, each edged in black.
static func _egypt_band() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var bands := [Color("2a5a9a"), Color("d8a840"), Color("a8342a"), Color("3a8a6a")]
	for y in 16:
		for x in 16:
			var c: Color = bands[(y / 4) % 4]
			if y % 4 == 3:
				c = Color("1a1410")
			elif y % 4 == 1 and x % 4 == 0:
				c = c.lightened(0.3)  # a row of small painted marks
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## The nemes headcloth: stripes of gold and deep blue.
static func _nemes() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			img.set_pixel(x, y, Color("d8b048") if (y / 2) % 2 == 0 else Color("24407a"))
	return ImageTexture.create_from_image(img)


## Woven osier: strands passing over and under.
static func _weave(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var over := ((x / 4) + (y / 4)) % 2 == 0
			var edge := (y % 4 == 0) if over else (x % 4 == 0)
			img.set_pixel(x, y, b if edge else (a if over else a.darkened(0.15)))
	return ImageTexture.create_from_image(img)


## Black-figure pottery: black glaze at the top, a key band, orange clay with black figures
## (a row of walking silhouettes), black at the foot.
static func _blackfigure() -> ImageTexture:
	const UNIT := ["########", ".......#", "#####..#", "#...#..#", "#.###..#", "#......#"]
	var clay := Color("c8703a")
	var black := Color("1a1410")
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var c := clay
			if y < 5 or y >= 28:
				c = black
			elif y >= 6 and y < 12:
				c = black if UNIT[y - 6][x % 8] == "#" else clay
			elif y >= 14 and y < 27:
				var fx := x % 16
				var head := Vector2(fx - 8, y - 15.5).length() < 1.6
				var trunk := fx >= 7 and fx <= 9 and y >= 17 and y <= 21
				var legs := y > 21 and (absi(fx - 8 - (y - 21) / 2) == 0 or absi(fx - 8 + (y - 21) / 2) == 0)
				var spear := fx == 11 and y >= 14
				if head or trunk or legs or spear:
					c = black
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Papyrus: pale yellow, the fibres of its two layers faint across and down.
static func _papyrus() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 103
	for y in 16:
		for x in 16:
			var c := Color("e0d0a0")
			if y % 3 == 0:
				c = c.darkened(0.06)
			if x % 5 == 0:
				c = c.darkened(0.04)
			if rng.randf() < 0.08:
				c = c.darkened(0.1)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## A ploughed field: dark furrows and lighter ridges running along X.
static func _furrows() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 107
	for y in 32:
		for x in 32:
			var c: Color = [Color("5a4430"), Color("6e5438"), Color("86684a"), Color("6e5438")][(y / 2) % 4]
			if rng.randf() < 0.15:
				c = c.darkened(0.1)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
