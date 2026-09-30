extends SceneTree
## Counts what is built into what in the city of Rome: houses into houses, into streets, into the
## monuments' ground; trees in houses or streets; basins without a house behind; shrines in
## houses. Run it after any change to rome_map.gd's blocks; every count should be zero.
##   godot --headless --path . --script res://tools/audit_rome.gd -- [--age=N]

func _initialize() -> void:
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	var which := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--age="):
			which = int(a.trim_prefix("--age="))
	var age: Dictionary = RomeMap.ages()[which]
	var world := Node3D.new()
	root.add_child(world)
	var fab: Dictionary = RomeMap.fabric(world, age, {"no_terrain": true})
	var obbs: Array = RomeMap._obbs
	var bands: Array = RomeMap._bands
	var keep: Array = RomeMap._keep
	var trees: Array = RomeMap._last_trees
	print("%s: %d houses and plots, %d street stretches, %d monuments and tombs, %d plants" % [age["id"], obbs.size(), bands.size(), keep.size(), trees.size()])
	var house_house := 0
	var examples: Array = []
	for i in obbs.size():
		var a: Array = obbs[i]
		for j in range(i + 1, obbs.size()):
			var b: Array = obbs[j]
			if Vector2(a[0].x - b[0].x, a[0].z - b[0].z).length() > Vector2(a[2], a[3]).length() / 2.0 + Vector2(b[2], b[3]).length() / 2.0:
				continue
			if RomeMap._sat(a[0], a[1], a[2], a[3], b[0], b[1], b[2], b[3], -0.1):
				house_house += 1
				if examples.size() < 3:
					examples.append([a[0], b[0]])
	print("houses built into houses: %d %s" % [house_house, str(examples)])
	var house_road := 0
	var house_keep := 0
	for o: Array in obbs:
		var bad_road := false
		var bad_keep := false
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var q: Vector3 = o[0] + (o[1] as Basis) * Vector3(sx * o[2] / 2.0, 0, sz * o[3] / 2.0)
				if RomeMap._on_road(q, -0.2):
					bad_road = true
				for k: Array in keep:
					if Vector2(q.x - k[0].x, q.z - k[0].z).length() < float(k[1]) - 0.2:
						bad_keep = true
		if bad_road:
			house_road += 1
		if bad_keep:
			house_keep += 1
	print("houses with a corner in a street: %d; on a monument's or a tomb's ground: %d" % [house_road, house_keep])
	var tree_house := 0
	var tree_road := 0
	for t: Array in trees:
		if t.size() > 3:
			continue
		if RomeMap._in_obb(t[0], -0.2):
			tree_house += 1
		if RomeMap._on_road(t[0], -0.2):
			tree_road += 1
	print("plants in a house: %d; in a street: %d" % [tree_house, tree_road])
	var lacus_free := 0
	for q: Vector3 in fab.get("lacus", []):
		if RomeMap._in_obb(q, 0.0):
			lacus_free += 1
	print("basins inside a house: %d of %d" % [lacus_free, (fab.get("lacus", []) as Array).size()])
	var comp_in := 0
	for cp: Dictionary in fab.get("compita", []):
		if RomeMap._in_obb(cp["at"], 0.3) or RomeMap._on_road(cp["at"], -0.2):
			comp_in += 1
	print("shrines in a house or a street: %d of %d" % [comp_in, (fab.get("compita", []) as Array).size()])
	var tomb_in := 0
	for tb: Dictionary in fab.get("tombs", []):
		if RomeMap._in_obb(tb["at"], 0.0):
			tomb_in += 1
	print("tombs inside a house: %d of %d" % [tomb_in, (fab.get("tombs", []) as Array).size()])
	var fountain_in := 0
	for fq: Vector3 in fab.get("fountains", []):
		if RomeMap._in_obb(fq, 1.5):
			fountain_in += 1
	print("fountains inside a house: %d of %d" % [fountain_in, (fab.get("fountains", []) as Array).size()])
	quit()
