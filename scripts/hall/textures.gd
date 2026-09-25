extends RefCounted
## Small pixel textures for the Hall (stone, floor, wood, plaques) and the materials that
## use them. Textures repeat in world space, so any box can use them without UVs.

static var _cache := {}


static func material(kind: String) -> StandardMaterial3D:
	if _cache.has(kind):
		return _cache[kind]
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	match kind:
		"wall":
			m.albedo_texture = _blocks(Color("4a4450"), Color("2a262e"), 16, 8)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(0.5, 0.5, 0.5)
		"room_wall":
			m.albedo_texture = _blocks(Color("6a5a48"), Color("3a3028"), 16, 8)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(0.5, 0.5, 0.5)
		"floor":
			m.albedo_texture = _blocks(Color("3a3640"), Color("1e1c22"), 16, 16)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(0.5, 0.5, 0.5)
		"ceiling":
			m.albedo_color = Color("121016")
		"wood":
			m.albedo_texture = _grain(Color("5a4028"), Color("3e2c1c"))
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
		"plaque":
			m.albedo_texture = _plaque()
		"bars":
			m.albedo_color = Color("2a2a2e")
			m.metallic = 0.6
			m.roughness = 0.5
		"void":
			m.albedo_color = Color("050407")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"gold":
			m.albedo_color = Color("a08040")
			m.metallic = 0.7
			m.roughness = 0.4
		"page":
			m.albedo_color = Color("d8c8a0")
	_cache[kind] = m
	return m


static func _blocks(face: Color, mortar: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = w * 31 + h
	for y in 32:
		for x in 32:
			var row := y / h
			var off := (w / 2) if row % 2 else 0
			var c := face
			if y % h == 0 or (x + off) % w == 0:
				c = mortar
			else:
				var n := rng.randf()
				c = face.darkened(0.12) if n < 0.25 else (face.lightened(0.06) if n > 0.9 else face)
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	return t


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
