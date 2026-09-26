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
		"beam":
			m.albedo_color = Color(1.0, 0.85, 0.6, 0.13)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"dark":
			m.albedo_color = Color("1a1612")
		"plaque":
			m.albedo_texture = _plaque()
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
