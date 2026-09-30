extends SceneTree
## Counts what is built into what in the city of Rome: houses into houses, into streets, into the
## monuments' ground; trees in houses or streets; basins without a house behind; shrines in
## houses. Run it after any change to rome_map.gd's blocks; every count should be zero.
##   godot --headless --path . --script res://tools/audit_rome.gd -- [--age=N]

func _initialize() -> void:
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	var which := 3
	var map_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--age="):
			which = int(a.trim_prefix("--age="))
		elif a.begins_with("--map="):
			map_path = a.trim_prefix("--map=")
	var age: Dictionary = RomeMap.ages()[which]
	var world := Node3D.new()
	root.add_child(world)
	var t0 := Time.get_ticks_msec()
	var fab: Dictionary = RomeMap.fabric(world, age, {"no_terrain": true})
	var took := Time.get_ticks_msec() - t0
	var obbs: Array = RomeMap._obbs
	var bands: Array = RomeMap._bands
	var monuments: Array = RomeMap._monuments
	var trees: Array = RomeMap._last_trees
	var occ: RefCounted = RomeMap._occ
	if map_path != "":
		occ.dump(map_path)
	print("%s: %d houses and plots, %d street stretches, %d monuments, %d plants, built in %d ms" % [age["id"], obbs.size(), bands.size(), monuments.size(), trees.size(), took])
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
		var bad_road: bool = RomeMap._box_on_road(o[0], o[1], o[2], o[3], -0.2)
		var bad_keep := false
		for m: Array in monuments:
			if Vector2(m[0].x - o[0].x, m[0].z - o[0].z).length() > Vector2(m[2], m[3]).length() / 2.0 + Vector2(o[2], o[3]).length() / 2.0:
				continue
			if RomeMap._sat(o[0], o[1], o[2], o[3], m[0], m[1], m[2], m[3], -0.1):
				bad_keep = true
		if bad_road:
			house_road += 1
		if bad_keep:
			house_keep += 1
	print("houses over a street or a lane: %d; into a monument: %d" % [house_road, house_keep])
	# the lanes and streets themselves: through a monument, in the water, across the Forum's paving
	var lane_mon := 0
	var lane_water := 0
	var lane_open := 0
	var lanes := 0
	var forum: Vector3 = RomeMap.at([0, 0])
	var forum_b := Basis(Vector3.UP, -0.617 + PI / 2.0)
	for r: Array in bands:
		if r.size() >= 4 or absf(float(r[2]) - 3.0 - RomeMap.LANE / 2.0) > 0.01:
			continue  # the lanes only: the named streets run to the monuments and over the bridges by design
		lanes += 1
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var mid := (a + b) / 2.0
		var dirv := (b - a)
		dirv.y = 0.0
		var length := dirv.length()
		if length < 0.1:
			continue
		var bb := Basis(Vector3.UP, atan2(dirv.normalized().x, dirv.normalized().z) + PI / 2.0)  # the band as a box: x along it
		var half: float = float(r[2]) - 3.0
		var hit_m := false
		for m: Array in monuments:
			if Vector2(m[0].x - mid.x, m[0].z - mid.z).length() > Vector2(m[2], m[3]).length() / 2.0 + length / 2.0 + half:
				continue
			if RomeMap._sat(mid, bb, length, half * 2.0, m[0], m[1], m[2], m[3], -0.1):
				hit_m = true
				break
		if hit_m:
			lane_mon += 1
		var in_water := false
		for f: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			if RomeMap.river_edge(a.lerp(b, f)) < 0.0:
				in_water = true
		if in_water:
			lane_water += 1
		if RomeMap._sat(mid, bb, length, half * 2.0, forum, forum_b, 70.0, 30.0, -0.1):
			lane_open += 1
	print("lane stretches (of %d) through a monument: %d; in the water: %d; across the Forum's paving: %d" % [lanes, lane_mon, lane_water, lane_open])
	var lined := 0
	var touching := 0
	for i in obbs.size():
		var a: Array = obbs[i]
		var best := INF
		for j in obbs.size():
			if j == i:
				continue
			var b: Array = obbs[j]
			if Vector2(a[0].x - b[0].x, a[0].z - b[0].z).length() > 30.0:
				continue
			var gap: float = Vector2(a[0].x - b[0].x, a[0].z - b[0].z).length() - float(a[2]) / 2.0 - float(b[2]) / 2.0
			best = minf(best, gap)
		if best < 1.5:
			touching += 1
		lined += 1
	print("houses with a neighbour within a pace and a half: %d of %d" % [touching, lined])
	print("stalls: %d" % (fab.get("stalls", []) as Array).size())
	var tree_house := 0
	var tree_road := 0
	for t: Array in trees:
		if t.size() > 3:
			continue
		var q: Vector3 = t[0]
		var in_house := false
		for o: Array in obbs:
			if Vector2(o[0].x - q.x, o[0].z - q.z).length() > Vector2(o[2], o[3]).length() / 2.0:
				continue
			var local: Vector3 = (o[1] as Basis).transposed() * (q - o[0])
			if absf(local.x) < float(o[2]) / 2.0 - 0.2 and absf(local.z) < float(o[3]) / 2.0 - 0.2:
				in_house = true
				break
		if in_house:
			tree_house += 1
		if RomeMap._box_on_road(q, Basis.IDENTITY, 0.2, 0.2, -0.2, false):
			tree_road += 1
	print("plants in a house: %d; in a street: %d" % [tree_house, tree_road])
	var in_box := func(q: Vector3, margin: float) -> bool:
		for o: Array in obbs:
			if Vector2(o[0].x - q.x, o[0].z - q.z).length() > Vector2(o[2], o[3]).length() / 2.0 + margin:
				continue
			var local: Vector3 = (o[1] as Basis).transposed() * (q - o[0])
			if absf(local.x) < float(o[2]) / 2.0 + margin and absf(local.z) < float(o[3]) / 2.0 + margin:
				return true
		return false
	var lacus_free := 0
	for q: Vector3 in fab.get("lacus", []):
		if in_box.call(q, 0.0):
			lacus_free += 1
	print("basins inside a house: %d of %d" % [lacus_free, (fab.get("lacus", []) as Array).size()])
	var comp_in := 0
	for cp: Dictionary in fab.get("compita", []):
		if in_box.call(cp["at"], 0.3) or RomeMap._box_on_road(cp["at"], Basis.IDENTITY, 0.2, 0.2, -0.2, false):
			comp_in += 1
	print("shrines in a house or a street: %d of %d" % [comp_in, (fab.get("compita", []) as Array).size()])
	var tomb_in := 0
	for tb: Dictionary in fab.get("tombs", []):
		if in_box.call(tb["at"], 0.0):
			tomb_in += 1
	print("tombs inside a house: %d of %d" % [tomb_in, (fab.get("tombs", []) as Array).size()])
	var fountain_in := 0
	for fq: Vector3 in fab.get("fountains", []):
		if in_box.call(fq, 1.5):
			fountain_in += 1
	print("fountains inside a house: %d of %d" % [fountain_in, (fab.get("fountains", []) as Array).size()])
	quit()
