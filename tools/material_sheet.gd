extends SceneTree
## Dumps every material of the city of Rome (scripts/hall/textures.gd) as a swatch, for the dev
## material sheet (tools/dev_maps.py tiles and labels them). Materials with no texture, only a
## colour, are written as a flat swatch of that colour.
##   godot --headless --path . --script res://tools/material_sheet.gd -- --out=DIR

const KINDS := ["r_ground", "r_dirt", "r_wall", "r_brick", "r_shop", "r_roof", "r_slab", "cobble", "rubble", "basalt", "paving",
	"travertine", "tufa", "brick", "reticulatum", "plaster", "fresco", "mosaic", "marble", "stone", "wood", "roof", "terracotta",
	"insula", "insula_white", "awning", "leaves", "pine", "trunk", "bronze", "gold", "iron", "rust", "clay", "wicker", "toga",
	"graffiti_republic", "porphyry", "giallo", "water", "drybed", "deadwood",
	"h_plaster", "h_plaster_worn", "h_brick", "h_tufa", "h_timber", "h_stucco", "h_roof", "h_roof_moss", "h_roof_broken",
	"h_shop", "h_shop_shut", "h_door", "h_door_red", "h_door_green", "h_window", "h_window_small", "h_shutter", "h_cloth",
	"h_vine", "h_sign"]


func _initialize() -> void:
	var out := "."
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var Tex: GDScript = load("res://scripts/hall/textures.gd")
	var done: Array = []
	for k: String in KINDS:
		var m: Material = Tex.material(k)
		var img: Image
		if m is StandardMaterial3D and (m as StandardMaterial3D).albedo_texture:
			img = (m as StandardMaterial3D).albedo_texture.get_image()
			if img.is_compressed():
				img.decompress()
			var col: Color = (m as StandardMaterial3D).albedo_color
			if col != Color.WHITE:  # the tint the material puts on its texture
				for y in img.get_height():
					for x in img.get_width():
						img.set_pixel(x, y, img.get_pixel(x, y) * col)
		else:
			img = Image.create(64, 64, false, Image.FORMAT_RGB8)
			img.fill((m as StandardMaterial3D).albedo_color if m is StandardMaterial3D else Color.MAGENTA)
		img.resize(256, 256, Image.INTERPOLATE_NEAREST if img.get_width() <= 64 else Image.INTERPOLATE_BILINEAR)
		img.save_png("%s/mat_%s.png" % [out, k])
		done.append(k)
	print("materials: ", done.size())
	quit()
