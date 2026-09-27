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
