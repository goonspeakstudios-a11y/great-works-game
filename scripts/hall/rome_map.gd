extends RefCounted
## Ancient Rome as one city, laid out on Shepherd's plan of Republican Rome
## (content/rome/republican_rome.json) and grown through its ages from content/rome/city.json,
## shrunk by the plan's scale. Map positions are real metres [east, north] of the Forum; world
## positions are game metres, with north toward -Z and the Forum at the world's origin.
##
## fabric() builds the city itself in one of its ages: the ground (one sheet of herringbone brick
## over the seven hills, no grass anywhere; broken rubble once the city is emptied), the Tiber in
## its bed with the island and the bridges, the Servian wall and later Aurelian's, the paved
## streets, the aqueducts, every monument standing in that year (whole, or a ruin), and between
## them thousands of blocks of houses and flats on crooked streets and alleys. The Rome world's hub
## (places_rome.gd) walks it; the Rhetorica's place (places_greek.gd) stands in its first zone,
## fenced round, with the rest of the Republic's city about it.

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Urbs := preload("res://scripts/hall/kit_urbs.gd")
const FILE := "res://content/rome/republican_rome.json"
const CITY_FILE := "res://content/rome/city.json"

const RIVER_BED := -2.6
const WATER := -1.0
const BANK := 5.0  # the slope from the street down to the water
const ISLE_ARM := 13.0  # each arm of the river round the island
const CELL := 4.0  # the ground's grid
const PITCH := 15.0  # one block of houses and its share of the streets round it
const LANE := 3.6  # the width of a lane between the blocks

## How far round each kind of monument the houses keep back (world metres, at size 1).
const FOOTPRINT := {"temple": 16.0, "double_temple": 42.0, "round_temple": 8.0, "hall": 10.0, "curia": 14.0,
	"basilica": 30.0, "vaulted_hall": 32.0, "rostra": 8.0, "shrine": 5.0, "arch": 10.0, "column": 5.0, "markets": 36.0,
	"amphitheatre": 100.0, "colossus": 6.0, "fountain_cone": 9.0, "ludus": 24.0, "baths": 70.0, "palace": 62.0,
	"houses": 50.0, "circus": 118.0, "obelisk": 4.0, "open_circus": 55.0, "theatre": 42.0, "pantheon": 30.0,
	"stadium": 52.0, "altar": 10.0, "mausoleum": 30.0, "church": 50.0, "comitium": 12.0, "cloaca": 6.0, "beak_column": 3.0,
	"lupanar": 8.0, "catasta": 4.0, "gibbets": 10.0, "puticuli": 14.0,
	"lacus": 5.0, "fig": 4.0, "milliarium": 3.0, "statues": 10.0, "tomb": 6.0, "altar_open": 9.0, "hut": 7.0, "cave": 8.0,
	"rock": 10.0, "tower": 6.0, "portico": 22.0}

const CORRIDOR := 60.0  # how far past a street's end the monument it runs at may stand, for its view corridor
const JUNCTION_END := 50.0  # a street's end this near another street is a junction with it (urbs_plan joins them)
const LANDMARK_LOW := 70.0  # within this of a landmark the flats are kept to three storeys

static var _data := {}
static var _city := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if parsed is Dictionary:
			_data = parsed
		else:
			push_error("republican_rome.json does not parse")
	return _data


## content/rome/city.json: the ages, the monuments and their years, the streets, the bridges, the
## regions and what the people say.
static func city_data() -> Dictionary:
	if _city.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CITY_FILE))
		if parsed is Dictionary:
			_city = parsed
			_city["roads"] = _bend_roads(_city.get("roads", []), _city.get("monuments", []))
		else:
			push_error("city.json does not parse")
	return _city


## A street's name as the Romans would have cut it, when city.json gives none: capitals, V for U.
static func street_latin(name: String) -> String:
	return name.trim_prefix("the ").split(" and ")[0].to_upper().replace("U", "V").replace("J", "I")


## The named streets bent as streets are, once, when the city is read (every part of the game reads
## them from here, so the map, the way-finding, the walkers and the blocks agree): each run sampled
## every fifteen map metres and swayed sideways by two slow waves, the sway dying out at a street's
## ends, at its junctions with other streets, over the river (where the bridges are), within the
## Forum and against the monuments; a corner between two runs bevelled unless a street meets there.
## A street marked "straight" (the Via Lata, the Via Appia, the Via Recta) keeps its line. The
## points stay map metres east and north of the Forum, denser than the plan's.
static func _bend_roads(roads: Array, monuments: Array) -> Array:
	var lines: Array = []
	for r: Dictionary in roads:
		lines.append((r["points"] as Array).map(func(p: Array) -> Vector2: return Vector2(float(p[0]), float(p[1]))))
	var scale: float = data().get("scale", 0.35)
	var out: Array = []
	for i in roads.size():
		var r: Dictionary = roads[i]
		var pts: Array = lines[i]
		if r.get("straight", false) or pts.size() < 2:
			out.append(r)
			continue
		var pins: Array = [pts[0], pts[-1]]  # where the sway is nothing: the ends and the junctions
		for j in roads.size():
			if j == i:
				continue
			var q: Array = lines[j]
			for e in q.size():  # a point of the other street on this one
				var reach := 40.0 if (e == 0 or e == q.size() - 1) else 12.0
				for k in pts.size() - 1:
					var near: Vector2 = Geometry2D.get_closest_point_to_segment(q[e], pts[k], pts[k + 1])
					if near.distance_to(q[e]) < reach:
						pins.append(near)
			for k in pts.size() - 1:  # the streets crossing
				for m in q.size() - 1:
					var x: Variant = Geometry2D.segment_intersects_segment(pts[k], pts[k + 1], q[m], q[m + 1])
					if x != null:
						pins.append(x as Vector2)
		var pinned := func(p: Vector2) -> bool:
			for pin: Vector2 in pins:
				if pin.distance_to(p) < 20.0:
					return true
			return false
		var path: Array = [pts[0]]  # the corners bevelled where no street meets
		for k in range(1, pts.size() - 1):
			var v: Vector2 = pts[k]
			if pinned.call(v):
				path.append(v)
				continue
			var a: Vector2 = pts[k - 1]
			var b: Vector2 = pts[k + 1]
			var cut := minf(25.0, 0.35 * minf(v.distance_to(a), v.distance_to(b)))
			path.append(v + (a - v).normalized() * cut)
			path.append(v + (b - v).normalized() * cut)
		path.append(pts[-1])
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(r["name"]))
		var amp := 4.0 + 0.6 * float(r.get("width", 4.0))
		var ph1 := rng.randf() * TAU
		var ph2 := rng.randf() * TAU
		var bent: Array = []
		var along := 0.0
		for k in path.size() - 1:
			var a: Vector2 = path[k]
			var b: Vector2 = path[k + 1]
			var length := a.distance_to(b)
			var dir := (b - a) / maxf(length, 0.001)
			var normal := Vector2(-dir.y, dir.x)
			var steps := maxi(1, int(length / 15.0))
			for s in range(0 if k == 0 else 1, steps + 1):
				var t := float(s) / steps
				var p := a.lerp(b, t)
				var here := along + t * length
				var env := 1.0
				for pin: Vector2 in pins:
					env = minf(env, clampf((pin.distance_to(p) - 10.0) / 50.0, 0.0, 1.0))
				env = minf(env, clampf((p.length() - 120.0) / 200.0, 0.0, 1.0))  # the Forum's streets keep their lines
				env = minf(env, clampf((river_edge(at([p.x, p.y])) - 10.0) / 25.0, 0.0, 1.0))  # straight over the bridges
				for mon: Dictionary in monuments:
					if not mon.has("at") or not mon.has("kind"):
						continue
					var keep := footprint(mon) / scale + 12.0
					env = minf(env, clampf((Vector2(float(mon["at"][0]), float(mon["at"][1])).distance_to(p) - keep) / 40.0, 0.0, 1.0))
				env = env * env * (3.0 - 2.0 * env)
				var off := amp * env * (0.7 * sin(TAU * here / 260.0 + ph1) + 0.3 * sin(TAU * here / 90.0 + ph2))
				var bp := p + normal * off
				bent.append([bp.x, bp.y])
			along += length
		var rr := r.duplicate()
		rr["points"] = bent
		out.append(rr)
	return out


static func ages() -> Array:
	return city_data().get("ages", [])


## Where a map position (real metres east and north of the Forum) stands in the world.
static func at(p: Array) -> Vector3:
	var s: float = data().get("scale", 0.35)
	return Vector3(float(p[0]) * s, 0, -float(p[1]) * s)


## A map position standing on the ground.
static func on_ground(p: Array) -> Vector3:
	var w := at(p)
	w.y = ground(w)
	return w


## A distance on the map, in the world.
static func span(metres: float) -> float:
	return metres * float(data().get("scale", 0.35))


static func landmark(id: String) -> Vector3:
	return at(data()["landmarks"][id]["at"])


## One of the seven hills (republican_rome.json "hills"), by name: [its centre (world), its radius].
static func hill(name: String) -> Array:
	for h: Dictionary in data().get("hills", []):
		if str(h["name"]) == name:
			return [at(h["at"]), span(float(h.get("radius", 150)))]
	return [Vector3.ZERO, 0.0]


static func zone(id: String) -> Dictionary:
	for z: Dictionary in data().get("zones", []):
		if z["id"] == id:
			return z
	return {}


## A zone's outline in the world: its polygon, or a ring of points round its centre.
static func outline(id: String) -> Array:
	var z := zone(id)
	if z.has("polygon"):
		return z["polygon"].map(func(p: Array) -> Vector3: return at(p))
	var out: Array = []
	for k in 16:
		var a := TAU * k / 16.0
		out.append(at(z["at"]) + Vector3(cos(a), 0, sin(a)) * span(z["radius"]))
	return out


## Whether a world point (x, z) lies inside a closed outline.
static func inside(points: Array, p: Vector3) -> bool:
	var hit := false
	var j := points.size() - 1
	for i in points.size():
		var a: Vector3 = points[i]
		var b: Vector3 = points[j]
		if (a.z > p.z) != (b.z > p.z) and p.x < (b.x - a.x) * (p.z - a.z) / (b.z - a.z) + a.x:
			hit = not hit
		j = i
	return hit


## The walls of the city you can walk in: the line Aurelian's wall will follow.
static func walkable() -> Array:
	return (city_data().get("walkable", []) as Array).map(func(p: Array) -> Vector3: return at(p))


# ---------- the ground ----------

static func _isle() -> Vector3:
	return at(data()["tiber"]["island"]["at"])


static func _isle_r() -> float:
	return span(float(data()["tiber"]["island"]["radius"])) * 0.55


static func _half_width() -> float:
	return span(float(data()["tiber"]["width"])) / 2.0


## How far a world point is from the edge of the Tiber (negative in the water), counting the two
## arms of the river round the island.
static func river_edge(p: Vector3) -> float:
	var course: Array = data()["tiber"]["course"]
	var best := INF
	for i in course.size() - 1:
		best = minf(best, _to_segment(p, at(course[i]), at(course[i + 1])))
	var e := best - _half_width()
	var di := Vector2(p.x - _isle().x, p.z - _isle().z).length()
	return minf(e, di - (_isle_r() + ISLE_ARM))


static func _to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return (ap - ab * t).length()


static var _heights := PackedFloat32Array()  # the height map (content/rome/height.json), metres above the sea
static var _hmeta := {}


## The ground of Rome as generated by tools/make_rome_height.py: the seven hills and the valleys
## from their real shapes and heights, every street graded into it, every monument's ground
## levelled. Loaded once; empty if the file is missing (then the old round hills stand in).
static func height_map() -> Dictionary:
	if _hmeta.is_empty():
		var path := "res://content/rome/height.json"
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if not parsed is Dictionary:
			_hmeta = {"none": true}
			return _hmeta
		var meta: Dictionary = parsed
		var raw := Marshalls.base64_to_raw(str(meta["data"]))
		var n := int(meta["w"]) * int(meta["h"])
		_heights.resize(n)
		var off := float(meta["offset"])
		for k in n:
			_heights[k] = float(raw.decode_u16(k * 2)) / 100.0 - off
		meta.erase("data")
		_hmeta = meta
	return _hmeta


## The height of the ground above the sea at a map position (metres east, north of the Forum),
## between the four nearest cells of the height map.
static func height_at(x: float, y: float) -> float:
	var m := height_map()
	if m.has("none"):
		return float(data().get("floor", 12.0))
	var w := int(m["w"])
	var hh := int(m["h"])
	var fx := clampf((x - float(m["x0"])) / float(m["px"]), 0.0, w - 1.001)
	var fy := clampf((y - float(m["y0"])) / float(m["px"]), 0.0, hh - 1.001)
	var i := int(fx)
	var j := int(fy)
	var tx := fx - i
	var ty := fy - j
	var a := lerpf(_heights[j * w + i], _heights[j * w + i + 1], tx)
	var b := lerpf(_heights[(j + 1) * w + i], _heights[(j + 1) * w + i + 1], tx)
	return lerpf(a, b, ty)


## How high the ground stands at a world point: the height map, the Forum's floor at nought and
## heights shrunk as the map is (so slopes are as steep as they were), and the streets falling to
## the river between its quays; the island stands in the middle of it.
static func ground(p: Vector3) -> float:
	var h := 0.0
	var m := height_map()
	if not m.has("none"):
		var s: float = data().get("scale", 0.35)
		h = (height_at(p.x / s, -p.z / s) - float(m.get("floor", 12.0))) * s
	else:
		for hill: Dictionary in data().get("hills", []):
			var c := at(hill["at"])
			var r := span(hill["radius"])
			var d := Vector2(p.x - c.x, p.z - c.z).length()
			if d < r:
				h = maxf(h, span(hill["height"]) * (0.5 + 0.5 * cos(PI * d / r)))
	var e := river_edge(p)
	if e < BANK:
		h = lerpf(RIVER_BED, h, smoothstep(0.0, 1.0, clampf(e / BANK, 0.0, 1.0)))
	var di := Vector2(p.x - _isle().x, p.z - _isle().z).length()
	if di < _isle_r() + 4.0:
		h = maxf(h, lerpf(RIVER_BED, 0.4, clampf((_isle_r() + 4.0 - di) / 4.0, 0.0, 1.0)))
	return h


## The ground as one sheet over the whole city (and a flat plain beyond it), solid: a grid of
## CELL metres following ground(). `mat`: "cobble" (the paved city) or "rubble" (the emptied one).
static func terrain(world: Node3D, mat: String) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var outer: Array = (city_data().get("outer", []) as Array).map(func(q: Array) -> Vector3: return at(q))
	for p: Vector3 in (outer if not outer.is_empty() else walkable()):
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	lo -= Vector2(120, 120)
	hi += Vector2(120, 120)
	var noise := FastNoiseLite.new()  # patches of the ground: dusty, trodden dark, sun-bleached
	noise.seed = 21
	noise.frequency = 0.018
	var grain := FastNoiseLite.new()
	grain.seed = 5
	grain.frequency = 0.11
	var cols := int((hi.x - lo.x) / CELL) + 1
	var rows := int((hi.y - lo.y) / CELL) + 1
	var heights := PackedFloat32Array()
	heights.resize(cols * rows)
	for j in rows:
		for i in cols:
			heights[j * cols + i] = ground(Vector3(lo.x + i * CELL, 0, lo.y + j * CELL))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	verts.resize(cols * rows)
	normals.resize(cols * rows)
	colours.resize(cols * rows)
	for j in rows:
		for i in cols:
			var k := j * cols + i
			verts[k] = Vector3(lo.x + i * CELL, heights[k], lo.y + j * CELL)
			var n := noise.get_noise_2d(verts[k].x, verts[k].z) + 0.35 * grain.get_noise_2d(verts[k].x, verts[k].z)
			var col := Color(1.0, 0.97, 0.92).lerp(Color(0.78, 0.74, 0.7), clampf(0.5 - n, 0.0, 1.0))
			if n > 0.45:
				col = col.lerp(Color(1.08, 1.02, 0.92), n - 0.45)  # bleached where the sun sits all day
			if heights[k] > 4.0:
				col = col.lerp(Color(1.0, 0.94, 0.86), 0.3)  # the hills' lighter, drier ground
			colours[k] = col
			var hx := heights[j * cols + mini(i + 1, cols - 1)] - heights[j * cols + maxi(i - 1, 0)]
			var hz := heights[mini(j + 1, rows - 1) * cols + i] - heights[maxi(j - 1, 0) * cols + i]
			normals[k] = Vector3(-hx, 2.0 * CELL, -hz).normalized()
	var idx := PackedInt32Array()
	for j in rows - 1:
		for i in cols - 1:
			var a := j * cols + i
			idx.append_array([a, a + 1, a + cols, a + 1, a + cols + 1, a + cols])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var sheet := Kit.mesh(world, am, mat, Vector3.ZERO)
	sheet.material_override = tinted(mat)  # the patches of the ground tint its texture
	sheet.name = "Ground"
	# the same ground to walk on: a height map, one unit a cell, scaled up evenly to CELL metres
	var shape := HeightMapShape3D.new()
	shape.map_width = cols
	shape.map_depth = rows
	var scaled := PackedFloat32Array()
	scaled.resize(heights.size())
	for k in heights.size():
		scaled[k] = heights[k] / CELL
	shape.map_data = scaled
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.scale = Vector3.ONE * CELL
	cs.position = Vector3(lo.x + (cols - 1) * CELL / 2.0, 0, lo.y + (rows - 1) * CELL / 2.0)
	body.add_child(cs)
	world.add_child(body)
	# beyond the sheet, the plain of the Campagna, flat and dusty
	for side: Array in [[Vector3(0, -0.2, lo.y - 1500.0), Vector3(6000, 0.2, 3000)], [Vector3(0, -0.2, hi.y + 1500.0), Vector3(6000, 0.2, 3000)],
			[Vector3(lo.x - 1500.0, -0.2, 0), Vector3(3000, 0.2, 6000)], [Vector3(hi.x + 1500.0, -0.2, 0), Vector3(3000, 0.2, 6000)]]:
		Kit.box(world, side[0], side[1], "drybed", false)


## The kept-for-the-Rhetorica ground: the sheet of brick (or, lost, of rubble).
static func plain(world: Node3D, whole: bool) -> void:
	terrain(world, "r_ground" if whole else "rubble")


## What the traffic leaves on a paved street: the wheels' ruts worn in the stones a cart's gauge
## apart, stepping stones across it every so often (the Pompeian way over the wet and the dung),
## and an iron grate over the drain at the kerb now and then.
static func _street_wear(world: Node3D, pts: Array, width: float, fallen: bool) -> void:
	var cum: Array = [0.0]
	for i in pts.size() - 1:
		cum.append(float(cum[-1]) + Vector2((pts[i + 1] as Vector3).x - (pts[i] as Vector3).x, (pts[i + 1] as Vector3).z - (pts[i] as Vector3).z).length())
	var total := float(cum[-1])
	var along_at := func(t: float) -> Array:  # [point, direction] at t metres along
		var i := 0
		while i < cum.size() - 2 and float(cum[i + 1]) < t:
			i += 1
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var f := clampf((t - float(cum[i])) / maxf(float(cum[i + 1]) - float(cum[i]), 0.001), 0.0, 1.0)
		var dir := b - a
		dir.y = 0.0
		return [a.lerp(b, f), dir.normalized()]
	for side: float in [-0.7, 0.7]:  # the ruts
		var rut: Array = []
		for i in pts.size():
			var dir: Vector3 = (pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)
			dir.y = 0.0
			dir = dir.normalized()
			rut.append((pts[i] as Vector3) + Vector3(dir.z, 0, -dir.x) * side)
		ribbon(world, rut, 0.16, "#38383e", 0.125)
	var t := 26.0
	while t < total - 8.0:  # stepping stones across, and a grate at the kerb between
		var here: Array = along_at.call(t)
		var p: Vector3 = here[0]
		var dir: Vector3 = here[1]
		var across := Vector3(dir.z, 0, -dir.x)
		var n := maxi(2, int(width / 1.3))
		for k in n:
			var q := p + across * ((k - (n - 1) / 2.0) * 1.25)
			q.y = ground(q) + 0.12
			Kit.box(world, q + Vector3(0, 0.13, 0), Vector3(0.55, 0.26, 0.5), "travertine" if not fallen else "rubble", false, Vector3(0, atan2(dir.x, dir.z), 0))
		var g: Array = along_at.call(t + 34.0)
		if t + 34.0 < total - 8.0:
			var gp: Vector3 = g[0]
			var gd: Vector3 = g[1]
			var kerb := gp + Vector3(gd.z, 0, -gd.x) * (width / 2.0 - 0.45)
			kerb.y = ground(kerb) + 0.17
			var yaw := atan2(gd.x, gd.z)
			Kit.box(world, kerb, Vector3(0.55, 0.04, 0.8), "iron", false, Vector3(0, yaw, 0))
			for sl in 3:
				Kit.box(world, kerb + Basis(Vector3.UP, yaw) * Vector3(-0.15 + sl * 0.15, 0.01, 0), Vector3(0.06, 0.05, 0.62), "dark", false, Vector3(0, yaw, 0))
		t += 70.0


## A strip laid on the ground along a line of world points (a street, the river): `width` wide,
## `lift` above the ground (or at the fixed height `y` when given).
static func ribbon(world: Node3D, points: Array, width: float, mat: String, lift: float = 0.12, y: float = NAN) -> MeshInstance3D:
	var dense: Array = []
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var n := maxi(1, int(a.distance_to(b) / 2.0))
		for k in n:
			dense.append(a.lerp(b, float(k) / n))
	dense.append(points[-1])
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for i in dense.size():
		var p: Vector3 = dense[i]
		var dir: Vector3 = ((dense[mini(i + 1, dense.size() - 1)] as Vector3) - (dense[maxi(i - 1, 0)] as Vector3))
		dir.y = 0.0
		dir = dir.normalized()
		var side := Vector3(dir.z, 0, -dir.x) * width / 2.0
		for s: Vector3 in [p + side, p - side]:
			var h := y if not is_nan(y) else ground(s) + lift
			verts.append(Vector3(s.x, h, s.z))
		if i > 0:
			var a := (i - 1) * 2
			idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := Kit.mesh(world, am, mat, Vector3.ZERO)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A zone's fence: an unseen wall along its outline, and low marble posts with a cord between them,
## so its edge can be seen: the rest of the city waits beyond it.
static func fence(world: Node3D, id: String) -> Array:
	var pts := outline(id)
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var length := a.distance_to(b)
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.5, 8.0, length)
		Kit.solid(world, shape, (a + b) / 2.0 + Vector3(0, 4.0, 0), Vector3(0, Kit.face_yaw(a, b), 0))
		var n := int(length / 4.0)
		for k in n + 1:
			var p := a.lerp(b, float(k) / maxf(1.0, n))
			Kit.box(world, p + Vector3(0, ground(p) + 0.45, 0), Vector3(0.25, 0.9, 0.25), "marble", false)
		var mid := (a + b) / 2.0
		Kit.box(world, mid + Vector3(0, ground(mid) + 0.75, 0), Vector3(0.04, 0.04, length), "#8a2a2a", false,
			Vector3(0, Kit.face_yaw(a, b), 0))
	return pts


# ---------- the city ----------

## Whether a monument stands in `year`, and whole: "gone", "ruin", "whole" or "" (not yet built).
## A site scripted through its states (city.json "states", by the age's id: tools/make_rome_sites.py)
## says for itself in each age it is present in.
static func state(m: Dictionary, year: int) -> String:
	if year < int(m.get("from", -800)):
		return ""
	if m.has("gone") and year >= int(m["gone"]):
		return "gone"
	var scripted: Dictionary = m.get("states", {}).get(age_id_for(year), {})
	if not scripted.is_empty():
		return str(scripted.get("state", "whole"))
	if m.has("ruin") and year >= int(m["ruin"]):
		return "ruin"
	return "whole"


## The id of the age whose year this is ("" for a year that is no age's, like the Rhetorica's 85 BC).
static func age_id_for(year: int) -> String:
	for a: Dictionary in ages():
		if int(a.get("year", 0)) == year:
			return str(a["id"])
	return ""


## A monument as it is in an age: its own entry, with the age's scripted state laid over it (the
## note the player reads there, and the "variant" the builder shows). The entry itself is untouched.
static func staged(m: Dictionary, age_id: String) -> Dictionary:
	var scripted: Dictionary = m.get("states", {}).get(age_id, {})
	if scripted.is_empty():
		return m
	var out := m.duplicate()
	for k: String in ["note", "variant", "style"]:
		if scripted.has(k):
			out[k] = scripted[k]
	return out


## Which way a monument faces: "forum" (toward the middle of the Forum) or a compass bearing in
## degrees (0 north, 90 east), as a yaw for a group that faces +Z.
static func facing(m: Dictionary, where: Vector3) -> float:
	var f: Variant = m.get("face", 0)
	if m.get("kind", "") in ["circus", "obelisk"] and m.get("id", "") in ["circus", "circus_obelisk"]:
		var axis: Array = data()["circus_maximus"]["axis"]
		var v := Vector3(float(axis[0]), 0, -float(axis[1])).normalized()
		return atan2(v.x, v.z)
	if f is String:
		return Kit.face_yaw(where, at([0, 0]))
	var b := deg_to_rad(float(f))
	return atan2(sin(b), -cos(b))


## How far round a monument the houses keep back.
static func footprint(m: Dictionary) -> float:
	if m["kind"] == "forum":
		return maxf(span(float(m.get("w", 60))), span(float(m.get("d", 100)))) / 2.0 + 4.0
	return float(FOOTPRINT.get(m["kind"], 12.0)) * float(m.get("size", 1.0))


## The city of Rome in one of its ages (an entry of city.json's "ages"). `opts`:
##   "skip": a zone's outline to leave empty (where a book's own place is built),
##   "lost": the Rhetorica's place before it is mended (the city about it grey and fallen),
##   "clear": world points the houses keep clear of (where you arrive, the gateways),
##   "blocks": false to leave out the houses (for quick tests), "no_terrain": the ground is laid already.
## Returns {"flicker": lights, "monuments": [{m, at, yaw, state}], "streets": [[world points]...],
## "stalls": spots for stalls along the streets, "fountains": spots of the street fountains,
## "doors": [spot, yaw] before shops, "banks": spots along the river, "flames": the night's lamps}.
static func fabric(world: Node3D, age: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var c := city_data()
	var year := int(age.get("year", -50))
	var lost: bool = opts.get("lost", false)
	var fallen: bool = age.get("id", "") == "fall" or lost
	var skip: Array = opts.get("skip", [])
	var flicker: Array = []
	if not opts.get("no_terrain", false):
		terrain(world, "rubble" if fallen else "r_ground")
	# the feasibility map, laid over the ground first: void beyond the city's edge, then everything
	# built painted on it in order, so each thing placed after finds only free ground
	var outer_pts: Array = (c.get("outer", []) as Array).map(func(q: Array) -> Vector3: return at(q))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q: Vector3 in outer_pts:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.z))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.z))
	_occ = Occupancy.new()
	_occ.setup(lo, hi)
	_occ.paint_poly(outer_pts, Occupancy.FREE)
	if not skip.is_empty():
		_occ.paint_poly(skip, Occupancy.VOID)
		for q: Vector3 in skip:
			_occ.paint_disc(q, 12.0, Occupancy.VOID)
	for q: Vector3 in opts.get("clear", []):
		_occ.paint_disc(q, 16.0, Occupancy.VOID)
	# the soft kinds first (the open squares, the groves, the waters' banks, the Forum's paving),
	# the hard kinds over them, so a street through a grove is still a street on the map
	for o: Dictionary in c.get("open", []):
		if o.has("until") and year >= int(o["until"]):
			continue
		_occ.paint_disc(at(o["at"]), span(float(o["r"])), Occupancy.OPEN)
	for g: Dictionary in groves(year):
		_occ.paint_disc(g["at"], float(g["r"]), Occupancy.GROVE)
	for wt: Dictionary in waters(year):
		if wt["kind"] == "stream":
			_occ.paint_line(wt["points"], float(wt["width"]) / 2.0 + 3.0, Occupancy.BANK)
			_occ.paint_line(wt["points"], float(wt["width"]) / 2.0, Occupancy.WATER)
		else:
			_occ.paint_disc(wt["at"], float(wt["r"]) + 5.0, Occupancy.BANK)
			_occ.paint_disc(wt["at"], float(wt["r"]), Occupancy.WATER)
	var forum := at([0, 0])
	if skip.is_empty() or not inside(skip, forum):
		_occ.paint_box(forum, Basis(Vector3.UP, -0.617 + PI / 2.0), 70.0, 30.0, Occupancy.OPEN, 1.0)
	_monuments = []
	_river(world, year, fallen)
	var bridges := _bridges(world, year, fallen)
	for deck: Array in bridges:
		_occ.paint_band(deck[0], deck[1], float(deck[2]) / 2.0 + 0.6, Occupancy.ROAD)
	_servian_wall(world, year, lost)
	_edges(world, year)
	var streets: Array = []
	var paving: Dictionary = streets_data().get("paving", {})
	for r: Dictionary in c.get("roads", []):
		var pts: Array = (r["points"] as Array).map(func(p: Array) -> Vector3: return on_ground(p))
		var mat := str(paving.get(str(r["name"]), "basalt"))
		if mat == "travertine" and year < -200:
			mat = "basalt"  # the Sacred Way was paved in marble only under the emperors' fathers
		ribbon(world, pts, float(r["width"]), mat if mat != "earth" else "path")
		_occ.paint_line(pts, float(r["width"]) / 2.0 + 0.6, Occupancy.ROAD)  # the street and its kerb
		streets.append(pts)
		if year >= -200 and year < 537 and not lost and mat != "earth":  # the gutter along the kerb, running with the basins' overflow
			for i in pts.size() - 1:
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[i + 1]
				var n := Vector3((b - a).normalized().z, 0, -(b - a).normalized().x) * (float(r["width"]) / 2.0 - 0.3)
				ribbon(world, [a + n, b + n], 0.35, "water", 0.16)
			_street_wear(world, pts, float(r["width"]), fallen)
	for a: Dictionary in c.get("aqueducts", []):
		if year < int(a["year"]):
			continue
		var from := on_ground(a["from"])
		var to := on_ground(a["to"])
		var base := Vector3(0, minf(from.y, to.y), 0)
		Rome.aqueduct(world, Vector3(from.x, base.y, from.z), Vector3(to.x, base.y, to.z), int(a.get("tiers", 1)), year < 537 and not lost)
		_occ.paint_band(from, to, 2.5, Occupancy.MONUMENT)
	var standing: Array = []
	var age_id := str(age.get("id", age_id_for(year)))
	for entry: Dictionary in c.get("monuments", []):
		var st := state(entry, year)
		if st == "" or st == "gone":
			continue
		var m := staged(entry, age_id)
		var where := on_ground(m["at"])
		if m["id"] == "aesculapius":
			where = Vector3(_isle().x, 0.4, _isle().z)
		if not skip.is_empty() and inside(skip, where):
			continue
		var yaw := facing(m, where)
		var before := world.get_child_count()
		var light := Urbs.build(world, m, where, yaw, st == "whole" and not lost, span(1.0), year)
		if light:
			flicker.append(light)
		var built: Array = []
		for k in range(before, world.get_child_count()):
			built.append(world.get_child(k))
		_paint_monument(world, built, where, yaw)
		standing.append({"m": m, "at": where, "yaw": yaw, "state": st})
	if skip.is_empty() or not inside(skip, forum):  # the Forum's paving of travertine slabs
		Kit.box(world, forum + Vector3(0, 0.03, 0), Vector3(70.0, 0.06, 30.0), "paving", false, Vector3(0, -0.617 + PI / 2.0, 0))
	# the view corridors, from each street's end to the monument it runs at, under the monuments
	for r: Dictionary in c.get("roads", []):
		var pts: Array = r["points"]
		for end: Vector3 in [at(pts[0]), at(pts[pts.size() - 1])]:
			var target := Vector3.INF
			var best := CORRIDOR
			for st: Dictionary in standing:
				var dd: float = Vector2(st["at"].x - end.x, st["at"].z - end.z).length()
				if dd < best and (st["m"] as Dictionary).has("note"):
					best = dd
					target = st["at"]
			if target != Vector3.INF and best > 4.0:
				_occ.paint_band(end, target, float(r["width"]) / 2.0 + 2.0, Occupancy.OPEN)
	for r: Dictionary in c.get("roads", []):  # the streets again over the corridors: open ground round them, the street still the street
		_occ.paint_line((r["points"] as Array).map(func(p: Array) -> Vector3: return at(p)), float(r["width"]) / 2.0 + 0.6, Occupancy.ROAD)
	for deck: Array in bridges:
		_occ.paint_band(deck[0], deck[1], float(deck[2]) / 2.0 + 0.6, Occupancy.ROAD)
	for mb: Array in _monuments:
		_occ.paint_box(mb[0], mb[1], float(mb[2]), float(mb[3]), Occupancy.MONUMENT, 1.5)
	var out := {"flicker": flicker, "monuments": standing, "streets": streets, "bridges": bridges, "stalls": [], "fountains": [],
		"clear": opts.get("clear", []), "doors": [], "banks": [], "flames": [], "compita": [], "tombs": [], "waters": [], "lacus": []}
	if opts.get("blocks", true):
		_road_tombs(world, c, year, age_id, standing, skip, out)
		_blocks(world, age, standing, streets, skip, lost, out)
		_compita(world, c, age_id, skip, out)
		_street_basins(world, c, year, lost, standing, skip, out)
		_corners(world, c, skip)
	return out


## The streets' names painted on the corners at their junctions (the Romans did not; you need
## them): on a house wall a few paces along each street from the crossing, a whitewashed panel with
## the name in red capitals, in Latin (city.json "latin"), the letters the shops' notices used.
## Where no house stands at the corner there is no name.
static func _corners(world: Node3D, c: Dictionary, skip: Array) -> void:
	var edge := walkable()
	var halves := {}
	var latin := {}
	for r: Dictionary in c.get("roads", []):
		halves[str(r["name"])] = float(r["width"]) / 2.0
		latin[str(r["name"])] = str(r.get("latin", street_latin(str(r["name"]))))
	var n := 0
	var placed: Array = []  # where a name stands already
	for j: Dictionary in junctions(c):
		var p: Vector3 = j["at"]
		if not inside(edge, p) or (not skip.is_empty() and inside(skip, p)):
			continue
		for name: String in j["streets"]:
			var dir := _street_dir(c, name, p)
			if dir == Vector3.ZERO or _occ == null:
				continue
			var half: float = float(halves.get(name, 2.0))
			var text: String = latin[name]
			var wide := 0.27 * text.length() + 0.5
			var found := false
			for along: float in [8.0, 12.0, 16.0, 20.0, 24.0, 28.0]:
				for sgn: float in [1.0, -1.0]:
					var side := Vector3(dir.z, 0, -dir.x) * sgn
					var base := Vector3(p.x, 0, p.z) + dir * along
					var bi := _box_at(base + side * (half + 2.2))  # the house beside the street here
					if bi < 0:
						continue
					var t := _hit_box(bi, base, side)  # to its wall
					if t < half + 0.4 or t > half + 3.4:
						continue
					var wall := true  # the same wall behind the panel's whole width, nothing before it
					for dx: float in [-wide / 2.0, wide / 2.0]:
						if _box_at(base + dir * dx + side * (t + 0.35)) != bi or _occ.kind_at(base + dir * dx + side * (t - 0.35)) == Occupancy.HOUSE:
							wall = false
					if not wall:
						continue
					var q := base + side * (t - 0.04)
					if _near_name(placed, q, wide / 2.0 + 2.5):
						continue
					placed.append(q)
					q.y = ground(q) + 4.78  # over the shop signs, under the first storey's windows
					var g := Kit.group(world, q, atan2(-side.x, -side.z))
					g.name = "Corner%d" % n
					n += 1
					Kit.box(g, Vector3(0, 0, -0.03), Vector3(wide, 0.56, 0.04), "#efe8d8", false)
					g.add_child(_name_label(text, 44))
					found = true
					break
				if found:
					break
			if found:
				continue
			# no house wall at this corner (the Forum's streets run between monuments): a cippus of
			# travertine on the kerb, the name cut in it in two lines, as the boundary stones were
			for along: float in [6.0, 10.0, 14.0]:
				if found:
					break
				for sgn: float in [1.0, -1.0]:
					var side := Vector3(dir.z, 0, -dir.x) * sgn
					var q := Vector3(p.x, 0, p.z) + dir * along + side * (half + 1.1)
					# on open ground, or on a monument's margin (its footprint is painted a pace and a half wide), not in it
					if not _occ.disc_free(q, 0.8, (1 << Occupancy.OPEN) | (1 << Occupancy.GROVE) | (1 << Occupancy.MONUMENT)) or _in_monument(q, 0.7) or _near_name(placed, q, 2.5):
						continue
					q.y = ground(q)
					var g := Kit.group(world, q, atan2(-side.x, -side.z))
					g.name = "Corner%d" % n
					n += 1
					Kit.box(g, Vector3(0, 0.55, 0), Vector3(1.1, 1.1, 0.45), "travertine", false)
					Kit.box(g, Vector3(0, 1.14, 0), Vector3(1.2, 0.08, 0.55), "travertine", false)  # its cap
					var label := _name_label(text.replace(" ", "\n"), 22)
					label.position = Vector3(0, 0.62, 0.23)
					g.add_child(label)
					_occ.paint_disc(q, 0.8, Occupancy.FURNITURE)
					placed.append(q)
					found = true
					break


## Whether a point stands in a monument's own footprint (the built meshes' bounds), grown by `margin`.
static func _in_monument(p: Vector3, margin: float) -> bool:
	for m: Array in _monuments:
		var local: Vector3 = (m[1] as Basis).transposed() * (Vector3(p.x, 0, p.z) - Vector3((m[0] as Vector3).x, 0, (m[0] as Vector3).z))
		if absf(local.x) < float(m[2]) / 2.0 + margin and absf(local.z) < float(m[3]) / 2.0 + margin:
			return true
	return false


## Whether a name already stands within `reach` of a point (two streets' names would sit on one another).
static func _near_name(placed: Array, q: Vector3, reach: float) -> bool:
	for o: Vector3 in placed:
		if Vector2(o.x - q.x, o.z - q.z).length() < reach:
			return true
	return false


## A street's name in the game's own capitals, red, for a panel or a stone.
static func _name_label(text: String, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = load("res://scripts/hall/lettering.gd").LAPIDARY
	label.font_size = size
	label.pixel_size = 0.0075
	label.modulate = Color("9a2a1a")
	label.outline_size = 0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector3(0, 0, 0.01)
	return label


## The house or plot standing on a point (an index into _obbs), or -1.
static func _box_at(p: Vector3) -> int:
	var key := Vector2i(floori(p.x / BIN), floori(p.z / BIN))
	for i: int in _cells.get(key, []):
		var o: Array = _obbs[i]
		var local: Vector3 = (o[1] as Basis).transposed() * (p - o[0])
		if absf(local.x) <= float(o[2]) / 2.0 and absf(local.z) <= float(o[3]) / 2.0:
			return i
	return -1


## How far from `from` along `dir` (level) a box's wall is met, or -1 when it is not (or `from` is inside).
static func _hit_box(i: int, from: Vector3, dir: Vector3) -> float:
	var o: Array = _obbs[i]
	var bt: Basis = (o[1] as Basis).transposed()
	var lf := bt * (Vector3(from.x, 0, from.z) - Vector3((o[0] as Vector3).x, 0, (o[0] as Vector3).z))
	var ld := bt * Vector3(dir.x, 0, dir.z)
	var tmin := -INF
	var tmax := INF
	for axis in 2:
		var pos := lf.x if axis == 0 else lf.z
		var vel := ld.x if axis == 0 else ld.z
		var h := float(o[2]) / 2.0 if axis == 0 else float(o[3]) / 2.0
		if absf(vel) < 1e-6:
			if absf(pos) > h:
				return -1.0
			continue
		var t1 := (-h - pos) / vel
		var t2 := (h - pos) / vel
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
	if tmax < tmin or tmax < 0.0 or tmin <= 0.0:
		return -1.0
	return tmin


## Which way a named street runs away from a point on it (the direction of its nearest segment,
## pointing away from the point's nearer end).
static func _street_dir(c: Dictionary, name: String, p: Vector3) -> Vector3:
	for r: Dictionary in c.get("roads", []):
		if str(r["name"]) != name:
			continue
		var pts: Array = (r["points"] as Array).map(func(q: Array) -> Vector3: return at(q))
		var best := INF
		var dir := Vector3.ZERO
		for i in pts.size() - 1:
			var d := _to_segment(p, pts[i], pts[i + 1])
			if d < best:
				best = d
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[i + 1]
				dir = (b - a) if p.distance_to(b) > p.distance_to(a) else (a - b)
				dir.y = 0.0
		return dir.normalized()
	return Vector3.ZERO


static var _streets := {}
static var _burnt: Array = []  # where the houses burnt, while the blocks are built (out["burnt"])
static var _obbs: Array = []  # every house, plot and ruin built this time: [centre, basis, w, d], for the audit
static var _bands: Array = []  # the streets, lanes and corridors: [a, b, half + 3], for the audit
static var _monuments: Array = []  # the monuments' real footprints: [centre, basis, w, d], for the audit
static var _occ: RefCounted = null  # the feasibility map (urbs_occupancy.gd) of the city last built
const Occupancy := preload("res://scripts/hall/urbs_occupancy.gd")
const Houses := preload("res://scripts/hall/textures_houses.gd")
const TexSet := preload("res://scripts/hall/textures.gd")
const Citizen := preload("res://scripts/hall/citizen.gd")
## The trades a shop (taberna) can be: [the job in people.json, the picture on its sign, its weight].
## A street's shops are drawn from those of them the age has (the job's "ages").
const TRADES := [["pistor", "bread", 3], ["vinarius", "wine", 2], ["caupo", "wine", 2], ["popinarius", "cup", 2], ["lanius", "knife", 2],
	["faber", "hammer", 2], ["sutor", "shoe", 2], ["vestiarius", "cloth", 2], ["fullo", "cloth", 1], ["tonsor", "shears", 2],
	["medicus", "cup", 1], ["nummularius", "scales", 1], ["librarius", "roll", 1], ["figulus", "pot", 2], ["cetarius", "fish", 2],
	["olearius", "wine", 1], ["unguentarius", "wine", 1], ["lucernarius", "pot", 1], ["crustularius", "bread", 1]]
static var _trade_bags := {}
static var _lamps: Array = []  # the lamps by the house doors, lit at dusk (the flames multimesh)
const STALL_ON := [Occupancy.FREE, Occupancy.ROAD, Occupancy.LANE, Occupancy.OPEN, Occupancy.GROVE]  # where a stall may be set out
static var _last_trees: Array = []  # what was planted, after the culling (for the audit, tools/audit_rome.gd)


const BIN := 16.0  # the boxes are also kept by bin, for the exact check behind the map
static var _cells := {}  # Vector2i -> [box index]


## Files a house, plot or ruin among the built: on the map, and by bin for the audit and the
## exact check.
static func _register(c: Vector3, b: Basis, w: float, d: float) -> void:
	var idx := _obbs.size()
	_obbs.append([c, b, w, d])
	_occ.paint_box(c, b, w, d, Occupancy.HOUSE)
	var r := Vector2(w, d).length() / 2.0
	for i in range(floori((c.x - r) / BIN), floori((c.x + r) / BIN) + 1):
		for j in range(floori((c.z - r) / BIN), floori((c.z + r) / BIN) + 1):
			var key := Vector2i(i, j)
			if not _cells.has(key):
				_cells[key] = []
			_cells[key].append(idx)


## Whether a box may be built: free on the map (grown by `grow`), and, since a corner clip thinner
## than a cell can slip between the cells' centres, not into any box already built near it.
static func _fits(c: Vector3, b: Basis, w: float, d: float, grow: float) -> bool:
	if not _occ.box_free(c, b, w, d, grow):
		return false
	var r := Vector2(w, d).length() / 2.0 + grow
	var seen := {}
	for i in range(floori((c.x - r) / BIN), floori((c.x + r) / BIN) + 1):
		for j in range(floori((c.z - r) / BIN), floori((c.z + r) / BIN) + 1):
			for idx: int in _cells.get(Vector2i(i, j), []):
				if seen.has(idx):
					continue
				seen[idx] = true
				var o: Array = _obbs[idx]
				if Vector2((o[0] as Vector3).x - c.x, (o[0] as Vector3).z - c.z).length() > r + Vector2(float(o[2]), float(o[3])).length() / 2.0:
					continue
				if _sat(c, b, w, d, o[0], o[1], float(o[2]), float(o[3]), 0.0):
					return false
	return true


## The footprint of a monument just built: the smallest box in its own frame round every mesh
## under `nodes` (its group and whatever else the builder hung on the world), painted on the map.
static func _paint_monument(world: Node3D, nodes: Array, where: Vector3, yaw: float) -> void:
	var inv := Basis(Vector3.UP, -yaw)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for n: Node in nodes:
		var meshes: Array = n.find_children("*", "MeshInstance3D", true, false)
		if n is MeshInstance3D:
			meshes.append(n)
		for mi: Node in meshes:
			var xf: Transform3D = (mi as Node3D).transform
			var up: Node = mi.get_parent()
			while up != null and up != world:
				xf = (up as Node3D).transform * xf
				up = up.get_parent()
			var aabb: AABB = (mi as MeshInstance3D).get_aabb()
			for k in 8:
				var corner := xf * aabb.get_endpoint(k)
				var local := inv * (corner - where)
				lo = Vector2(minf(lo.x, local.x), minf(lo.y, local.z))
				hi = Vector2(maxf(hi.x, local.x), maxf(hi.y, local.z))
	if lo.x > hi.x:
		return
	var b := Basis(Vector3.UP, yaw)
	var centre := where + b * Vector3((lo.x + hi.x) / 2.0, 0, (lo.y + hi.y) / 2.0)
	var w := hi.x - lo.x
	var d := hi.y - lo.y
	_monuments.append([centre, b, w, d])
	_occ.paint_box(centre, b, w, d, Occupancy.MONUMENT, 1.5)


## The audit's own reading of a box against the streets, lanes and corridors: each band near it
## walked at a pace's step through the part within the box's reach.
static func _box_on_road(c: Vector3, b: Basis, w: float, d: float, margin: float = 0.0, corridors: bool = true) -> bool:
	var bt := b.transposed()
	var cc := Vector3(c.x, 0, c.z)
	var span_all := Vector2(w, d).length() / 2.0
	for r: Array in _bands:
		if r.size() >= 4 and not corridors:
			continue
		var hw := float(r[2]) - 3.0 + margin
		var a: Vector3 = r[0]
		var e: Vector3 = r[1]
		var ab := Vector2(e.x - a.x, e.z - a.z)
		var length := ab.length()
		if length < 0.01:
			continue
		var dirv := ab / length
		var ac := Vector2(c.x - a.x, c.z - a.z)
		var tc := ac.dot(dirv)
		var perp := absf(ac.cross(dirv))
		var span_r := span_all + hw
		if perp > span_r or tc - span_r > length or tc + span_r < 0.0:
			continue
		var half_chord := sqrt(maxf(0.0, span_r * span_r - perp * perp))
		var t0 := clampf(tc - half_chord, 0.0, length)
		var t1 := clampf(tc + half_chord, 0.0, length)
		var n := maxi(2, int((t1 - t0) / 1.0) + 1)
		for k in n:
			var t := t0 + (t1 - t0) * float(k) / float(n - 1)
			var q := Vector3(a.x + dirv.x * t, 0, a.z + dirv.y * t)
			var local := bt * (q - cc)
			if absf(local.x) <= w / 2.0 + hw and absf(local.z) <= d / 2.0 + hw:
				return true
	return false



## Whether two boxes on the ground overlap (each grown by `margin` all round), by the separating
## axis test on the two boxes' own axes.
static func _sat(c1: Vector3, b1: Basis, w1: float, d1: float, c2: Vector3, b2: Basis, w2: float, d2: float, margin: float = 0.0) -> bool:
	var axes: Array = [Vector2(b1.x.x, b1.x.z), Vector2(b1.z.x, b1.z.z), Vector2(b2.x.x, b2.x.z), Vector2(b2.z.x, b2.z.z)]
	var dc := Vector2(c2.x - c1.x, c2.z - c1.z)
	for ax: Vector2 in axes:
		var a := ax.normalized()
		var e1 := absf(a.dot(Vector2(b1.x.x, b1.x.z))) * (w1 / 2.0 + margin) + absf(a.dot(Vector2(b1.z.x, b1.z.z))) * (d1 / 2.0 + margin)
		var e2 := absf(a.dot(Vector2(b2.x.x, b2.x.z))) * (w2 / 2.0 + margin) + absf(a.dot(Vector2(b2.z.x, b2.z.z))) * (d2 / 2.0 + margin)
		if absf(a.dot(dc)) > e1 + e2:
			return false
	return true


## content/rome/streets.json: the epitaphs, the shops' signs, the crossroads shrines, the paving.
static func streets_data() -> Dictionary:
	if _streets.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/streets.json"))
		_streets = parsed if parsed is Dictionary else {"none": true}
	return _streets


## The junctions of the named streets: where a point of one lies on another, and where two cross.
## [{at, streets: [names]}].
static func junctions(c: Dictionary) -> Array:
	var out: Array = []
	var roads: Array = c.get("roads", [])
	var add := func(p: Vector3, a: String, b: String) -> void:
		for o: Dictionary in out:
			if (o["at"] as Vector3).distance_to(p) < 16.0:
				for name: String in [a, b]:
					if not (o["streets"] as Array).has(name):
						o["streets"].append(name)
				return
		out.append({"at": p, "streets": [a, b]})
	var lines: Array = roads.map(func(r: Dictionary) -> Array: return (r["points"] as Array).map(func(p: Array) -> Vector3: return at(p)))
	for i in roads.size():
		var pts: Array = lines[i]
		for j in roads.size():
			if j == i:
				continue
			var q: Array = lines[j]
			for e in pts.size():  # a point of one street on the other (its ends, near enough, as the plan joins them)
				var p: Vector3 = pts[e]
				var reach := JUNCTION_END if e == 0 or e == pts.size() - 1 else 7.0
				for k in q.size() - 1:
					if _to_segment(p, q[k], q[k + 1]) < reach:
						add.call(p, str(roads[i]["name"]), str(roads[j]["name"]))
						break
			if j < i:
				continue
			for m in pts.size() - 1:  # the streets crossing
				for k in q.size() - 1:
					var x: Variant = Geometry2D.segment_intersects_segment(Vector2(pts[m].x, pts[m].z), Vector2(pts[m + 1].x, pts[m + 1].z),
						Vector2(q[k].x, q[k].z), Vector2(q[k + 1].x, q[k + 1].z))
					if x != null:
						add.call(Vector3((x as Vector2).x, 0, (x as Vector2).y), str(roads[i]["name"]), str(roads[j]["name"]))
	return out


## The crossroads shrines: at every second junction, on the corner, the Lares of the crossing in
## the age's state (streets.json "compita"). out["compita"]: [{at, yaw, streets, style}].
static func _compita(world: Node3D, c: Dictionary, age_id: String, skip: Array, out: Dictionary) -> void:
	var st: Dictionary = streets_data().get("compita", {}).get(age_id, {})
	if st.is_empty():
		return
	var style := str(st.get("style", "lares"))
	var edge := walkable()
	var named: Array = []  # the named streets' stretches: [a, b, half-width]
	for r: Dictionary in c.get("roads", []):
		var pts: Array = (r["points"] as Array).map(func(pp: Array) -> Vector3: return at(pp))
		for i in pts.size() - 1:
			named.append([pts[i], pts[i + 1], float(r["width"]) / 2.0])
	var k := 0
	for j: Dictionary in junctions(c):
		k += 1
		if k % 2 == 0:
			continue
		var p: Vector3 = j["at"]
		if not inside(edge, p) or (not skip.is_empty() and inside(skip, p)):
			continue
		var q := Vector3.INF  # on the corner: of twelve spots round the crossing, one on the pavement and in no house
		var best := INF
		for s in 12:
			var a := TAU * (s + 0.5 * (k % 2)) / 12.0
			for reach: float in [3.5, 5.0, 7.0, 9.0, 12.0]:
				var cand := p + Vector3(cos(a), 0, sin(a)) * reach
				var off := INF
				for r: Array in named:
					off = minf(off, _to_segment(cand, r[0], r[1]) - float(r[2]))
				if off < 0.5 or not _occ.disc_free(cand, 1.2, Occupancy.ALLOW_FURNITURE):
					continue  # in a house, a lane, a tree
				if off < best:
					best = off
					q = cand
		if q == Vector3.INF:
			continue
		q.y = ground(q)
		_occ.paint_disc(q, 1.2, Occupancy.FURNITURE)
		var yaw := atan2(p.x - q.x, p.z - q.z)
		var g := Kit.group(world, q, yaw)
		g.name = "Compitum%d" % k
		Urbs.compitum(g, style)
		out["compita"].append({"at": q, "yaw": yaw, "streets": j["streets"], "style": style})


## The street basins (lacus): a trough with a running spout every fifty-odd paces along the named
## streets you can walk, on the pavement against the house fronts, alternating sides, from the
## first aqueducts (a few in 280 BC, when only the Appia ran); dry once they are cut. out["lacus"]:
## [pos], and out["waters"] gets each as a place of the sound of water.
static func _street_basins(world: Node3D, c: Dictionary, year: int, lost: bool, standing: Array, skip: Array, out: Dictionary) -> void:
	var edge := walkable()
	var flowing := year < 537 and not lost
	var gap := 45.0 if year >= -200 else 140.0
	var stalls: Array = out.get("stalls", [])
	var compita: Array = (out.get("compita", []) as Array).map(func(cp: Dictionary) -> Vector3: return cp["at"])
	var n := 0
	for r: Dictionary in c.get("roads", []):
		var pts: Array = (r["points"] as Array).map(func(p: Array) -> Vector3: return at(p))
		var half := float(r["width"]) / 2.0
		var cum: Array = [0.0]  # the street walked whole by arc length (its points are dense where it bends)
		for i in pts.size() - 1:
			cum.append(float(cum[-1]) + Vector2((pts[i + 1] as Vector3).x - (pts[i] as Vector3).x, (pts[i + 1] as Vector3).z - (pts[i] as Vector3).z).length())
		var total := float(cum[-1])
		var along := 25.0 + float(n % 3) * 9.0
		while along < total - 10.0:
			var i := 0
			while i < cum.size() - 2 and float(cum[i + 1]) < along:
				i += 1
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var dir := b - a
			dir.y = 0.0
			dir = dir.normalized()
			var across := Vector3(dir.z, 0, -dir.x)
			var p: Vector3 = a.lerp(b, clampf((along - float(cum[i])) / maxf(float(cum[i + 1]) - float(cum[i]), 0.001), 0.0, 1.0))
			along += gap
			var side := 1.0 if n % 2 == 0 else -1.0
			var q := p + across * side * (half + 0.9)
			n += 1
			if not inside(edge, q) or river_edge(q) < 8.0 or (not skip.is_empty() and inside(skip, q)):
				continue
			var found := false  # slid along the street to the nearest house front, either way
			for slide: float in [0.0, 3.0, -3.0, 6.0, -6.0, 9.0, -9.0, 12.0, -12.0, 15.0, -15.0]:
				var qq := q + dir * slide
				if _occ.kind_at(qq) == Occupancy.FREE and _occ.kind_at(qq + across * side * 1.6) == Occupancy.HOUSE:
					q = qq
					found = true
					break
			if not found:
				continue
			if standing.any(func(s: Dictionary) -> bool: return Vector2(s["at"].x - q.x, s["at"].z - q.z).length() < footprint(s["m"]) + 3.0):
				continue
			for si in range(stalls.size() - 1, -1, -1):  # a basin takes its place over a stall
				if Vector2((stalls[si] as Vector3).x - q.x, (stalls[si] as Vector3).z - q.z).length() < 2.6:
					stalls.remove_at(si)
			if compita.any(func(cp: Vector3) -> bool: return Vector2(cp.x - q.x, cp.z - q.z).length() < 10.0):
				continue
			q.y = ground(q)
			var g := Kit.group(world, q, atan2(-across.x * side, -across.z * side))
			g.name = "Lacus%d" % out["lacus"].size()
			Rome.lacus(g, Vector3.ZERO, 0.0, flowing)
			_occ.paint_disc(q, 1.3, Occupancy.FURNITURE)
			out["lacus"].append(q)
			if flowing:
				out["waters"].append([q, "trickle"])  # the thin fall of the spout, not a fountain's splash


## The tombs along the roads outside the gates: every so many paces on the stretch of each road
## beyond the Servian wall, alternating sides, an altar tomb or now and then a great drum, broken
## once the city falls. out["tombs"]: [{at, yaw, kind}].
static func _road_tombs(world: Node3D, c: Dictionary, year: int, age_id: String, standing: Array, skip: Array, out: Dictionary) -> void:
	var servian: Array = (data()["wall"]["gates"] as Array).map(func(g: Dictionary) -> Vector3: return at(g["at"]))
	var outer: Array = (c.get("outer", []) as Array).map(func(q: Array) -> Vector3: return at(q))
	var whole := age_id not in ["collapse", "fall"]
	var n := 0
	for r: Dictionary in c.get("roads", []):
		var pts: Array = (r["points"] as Array).map(func(p: Array) -> Vector3: return at(p))
		var half := float(r["width"]) / 2.0 * span(1.0) + 4.5
		var along := 0.0
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var dir := (b - a)
			dir.y = 0.0
			var length := dir.length()
			dir = dir.normalized()
			var t := 0.0
			while t < length:
				var p := a + dir * t
				t += 22.0
				along += 22.0
				if inside(servian, p) or not inside(outer, p) or river_edge(p) < 12.0:
					continue
				if not skip.is_empty() and inside(skip, p):
					continue
				var side := 1.0 if n % 2 == 0 else -1.0
				var q := p + Vector3(dir.z, 0, -dir.x) * side * half
				if standing.any(func(s: Dictionary) -> bool: return Vector2(s["at"].x - q.x, s["at"].z - q.z).length() < footprint(s["m"]) + 4.0):
					continue
				if year < -200 and n % 3 != 0:
					n += 1
					continue  # fewer in the small city
				q.y = ground(q)
				var kind := "round" if n % 9 == 4 and year > -100 else "altar"
				var g := Kit.group(world, q, atan2(p.x - q.x, p.z - q.z))
				g.name = "Tomb%d" % n
				var epitaphs: Array = streets_data().get("epitaphs", [])
				var which := n % maxi(1, epitaphs.size())
				Rome.tomb(g, Vector3.ZERO, 0.0, kind, whole, str(epitaphs[which].get("latin", "")) if not epitaphs.is_empty() else "")
				_occ.paint_disc(q, 4.5, Occupancy.FURNITURE)
				out["tombs"].append({"at": q, "yaw": g.rotation.y, "kind": kind, "road": str(r["name"]), "epitaph": which})
				n += 1
				if n > 90:
					return


## The Tiber: its water between the quays (low and brown once the city is emptied), round the
## island, and an unseen wall along each bank so you keep to the streets and the bridges.
static func _river(world: Node3D, year: int, fallen: bool) -> void:
	var course: Array = (data()["tiber"]["course"] as Array).map(func(p: Array) -> Vector3: return at(p))
	var mat := "water" if not fallen else "#4a4a3a"
	_occ.paint_line(course, _half_width() + 9.0, Occupancy.BANK)  # the bank, where nothing is built but the quays
	_occ.paint_line(course, _half_width() + BANK * 0.7, Occupancy.WATER)
	_occ.paint_disc(_isle(), _isle_r() + ISLE_ARM + BANK * 0.7, Occupancy.WATER)
	ribbon(world, course, _half_width() * 2.0 + BANK * 1.4, mat, 0.0, WATER)
	var disc := Kit.cylinder(world, Vector3(_isle().x, WATER - 0.05, _isle().z), _isle_r() + ISLE_ARM + BANK * 0.7, 0.05, mat, false, 20)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.cylinder(world, Vector3(_isle().x, RIVER_BED, _isle().z), _isle_r() + 1.0, 3.0, "travertine", false, 18)  # the island's ship-shaped quay


## The bridges standing in `year`, each across the river at its place (the island's two from the
## island to either bank). Returns their decks as [from, to, width] (world), so the bank's unseen
## wall leaves them open.
static func _bridges(world: Node3D, year: int, fallen: bool) -> Array:
	var out: Array = []
	var course: Array = (data()["tiber"]["course"] as Array).map(func(p: Array) -> Vector3: return at(p))
	for b: Dictionary in city_data().get("bridges", []):
		if year < int(b.get("from", -800)):
			continue
		var broken := b.has("ruin") and year >= int(b["ruin"])
		var where := at(b["at"])
		var dir := Vector3.ZERO
		var from := Vector3.ZERO
		var to := Vector3.ZERO
		if b.get("island", false):
			var out_dir := (where - _isle()).normalized()
			from = _isle() + out_dir * (_isle_r() - 1.5)
			to = _isle() + out_dir * (_isle_r() + ISLE_ARM + BANK + 3.0)
		else:
			var best := INF
			var near := Vector3.ZERO
			for i in course.size() - 1:
				var a: Vector3 = course[i]
				var bb: Vector3 = course[i + 1]
				var ab := bb - a
				var t := clampf((where - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				var q := a + ab * t
				if q.distance_to(where) < best:
					best = q.distance_to(where)
					near = q
					dir = ab.normalized()
			var across := Vector3(dir.z, 0, -dir.x)
			var half := _half_width() + BANK + 3.0
			from = near - across * half
			to = near + across * half
		var width := 7.0
		var mid := (from + to) / 2.0
		var length := Vector2(to.x - from.x, to.z - from.z).length()
		var g := Kit.group(world, Vector3(mid.x, 0, mid.z), atan2(to.x - from.x, to.z - from.z))
		var wood: bool = b.get("material", "") == "wood"
		var deck := "wood" if wood else "travertine"
		if broken:  # the middle spans fallen into the river
			for s: float in [-1.0, 1.0]:
				Kit.box(g, Vector3(0, -0.15, s * length * 0.35), Vector3(width, 0.3, length * 0.3), deck)
			continue
		Kit.box(g, Vector3(0, -0.15, 0), Vector3(width, 0.3, length), deck)
		Kit.box(g, Vector3(0, 0.02, 0), Vector3(width - 1.6, 0.06, length), "basalt" if not wood else "wood", false)
		for s: float in [-1.0, 1.0]:  # the parapets
			Kit.box(g, Vector3(s * (width / 2.0 - 0.3), 0.55, 0), Vector3(0.6, 1.1, length), deck)
		var piers := maxi(1, int(length / 12.0))
		for k in piers + 1:  # piers and arches (wooden trestles for the Sublician)
			var z := -length / 2.0 + length * k / piers
			if wood:
				for x: float in [-2.5, 0.0, 2.5]:
					Kit.box(g, Vector3(x, RIVER_BED / 2.0 - 0.3, z), Vector3(0.4, -RIVER_BED, 0.4), "wood", false)
			else:
				Kit.box(g, Vector3(0, RIVER_BED / 2.0 - 0.4, z), Vector3(width, -RIVER_BED, 2.6), deck, false)
		if not fallen and not wood:
			Kit.box(g, Vector3(0, -0.5, 0), Vector3(width + 0.2, 0.4, length), "#8a7e66", false)
		out.append([from, to, width, b])
	_banks(world, out)
	return out


## The unseen wall along both banks of the Tiber, with the bridges left open.
static func _banks(world: Node3D, decks: Array) -> void:
	var course: Array = (data()["tiber"]["course"] as Array).map(func(p: Array) -> Vector3: return at(p))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector3 in course:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	lo -= Vector2(60, 60)
	hi += Vector2(60, 60)
	const STEP := 3.0
	var nx := int((hi.x - lo.x) / STEP)
	var nz := int((hi.y - lo.y) / STEP)
	var wet := func(x: float, z: float) -> bool: return river_edge(Vector3(x, 0, z)) < 0.8 and ground(Vector3(x, 0, z)) < WATER + 0.3
	for j in nz:
		for i in nx:
			var x := lo.x + i * STEP
			var z := lo.y + j * STEP
			if not wet.call(x, z):
				continue
			var shore := false
			for d: Vector2 in [Vector2(STEP, 0), Vector2(-STEP, 0), Vector2(0, STEP), Vector2(0, -STEP)]:
				if not wet.call(x + d.x, z + d.y):
					shore = true
					break
			if not shore:
				continue
			var p := Vector3(x, 0, z)
			var on_bridge := false
			for deck: Array in decks:
				if _to_segment(p, deck[0], deck[1]) < float(deck[2]) / 2.0 + 1.5:
					on_bridge = true
					break
			if on_bridge:
				continue
			var shape := BoxShape3D.new()
			shape.size = Vector3(STEP, 6.0, STEP)
			Kit.solid(world, shape, Vector3(x, WATER + 2.0, z))


## The Servian wall of the Republic, with a tower each side of every gate. Under the emperors the
## city has spilled over it: it stands only in stretches, built into houses.
static func _servian_wall(world: Node3D, year: int, lost: bool) -> void:
	var d := data()
	var gates: Array = d["wall"]["gates"]
	var wall_h := span(d["wall"]["height"]) * 1.4
	var centre := at([0, 0])
	for i in gates.size():
		var a := on_ground(gates[i]["at"])
		var b := on_ground(gates[(i + 1) % gates.size()]["at"])
		var gap := 7.0
		var dir := (b - a)
		dir.y = 0.0
		_occ.paint_band(a, b, 9.0, Occupancy.WALL)  # the wall, its agger and the way along it
		var length := dir.length() - gap
		if length <= 0.0:
			continue
		var n := maxi(1, int(length / 10.0))
		var inward := Vector3(dir.z, 0, -dir.x).normalized()
		if inward.dot(centre - a) < 0.0:
			inward = -inward
		for k in n:  # in lengths that step with the ground
			var p := a + dir.normalized() * (gap / 2.0 + length * (k + 0.5) / n)
			var h := wall_h if year < 0 else wall_h * 0.75  # under the emperors, lower, and built against
			Kit.box(world, Vector3(p.x, ground(p) + h / 2.0 - 1.0, p.z), Vector3(3.0, h + 2.0, length / n + 0.3), "tufa" if not lost else "rubble", true,
				Vector3(0, atan2(dir.x, dir.z), 0))
			if i < 4:  # the agger on the east: the great earth rampart behind the wall, with its ditch outside
				var q := p + inward * 7.0
				Kit.box(world, Vector3(q.x, ground(q) + 1.2, q.z), Vector3(11.0, 4.4, length / n + 0.3), "earth", true, Vector3(0, atan2(dir.x, dir.z), 0))
		for side: float in [1.0]:
			var t := a + dir.normalized() * (gap / 2.0 + 1.3) * side
			Kit.box(world, Vector3(t.x, ground(t) + wall_h * 0.7 - 1.0, t.z), Vector3(4.0, wall_h * 1.4 + 2.0, 4.0), "tufa")


## The edge of the city: where you can walk, a line of boundary stones (the pomerium's cippi) and
## an unseen wall; from AD 275, far off round the whole city, Aurelian's wall of brick with square
## towers and a gate where each road leaves.
static func _edges(world: Node3D, year: int) -> void:
	var pts := walkable()
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var dir := b - a
		var length := dir.length()
		var yaw := atan2(dir.x, dir.z)
		var n := maxi(1, int(length / 12.0))
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n)
			var y := ground(p)
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0, 14.0, length / n + 0.4)
			Kit.solid(world, shape, Vector3(p.x, y + 5.0, p.z), Vector3(0, yaw, 0))
			if y > WATER and k % 2 == 0:
				Kit.box(world, Vector3(p.x, y + 0.6, p.z), Vector3(0.5, 1.2, 0.5), "travertine", false)  # a boundary stone
	if year < int(city_data().get("aurelian_wall", {}).get("from", 275)):
		return
	var outer: Array = (city_data().get("outer", []) as Array).map(func(q: Array) -> Vector3: return at(q))
	var h := float(city_data().get("aurelian_wall", {}).get("height", 10))
	for i in outer.size():
		var a: Vector3 = outer[i]
		var b: Vector3 = outer[(i + 1) % outer.size()]
		var dir := b - a
		var yaw := atan2(dir.x, dir.z)
		var n := maxi(1, int(dir.length() / 14.0))
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n)
			var y := ground(p)
			if y < WATER:
				continue  # where the line crosses the river
			Kit.box(world, Vector3(p.x, y + h / 2.0 - 1.0, p.z), Vector3(3.2, h + 2.0, dir.length() / n + 0.2), "brick", false, Vector3(0, yaw, 0))
			if k % 2 == 0:
				Kit.box(world, Vector3(p.x, y + h * 0.65 - 1.0, p.z) - Vector3(dir.z, 0, -dir.x).normalized() * 2.0,
					Vector3(5.0, h * 1.3 + 2.0, 5.0), "brick", false, Vector3(0, yaw, 0))
		for s: float in [-1.0, 1.0]:  # the gate at the corner: two round towers
			var q := a + dir.normalized() * 5.0 * s
			Kit.cylinder(world, Vector3(q.x, ground(q) - 1.0, q.z), 3.2, h * 1.4 + 1.0, "travertine", false, 10)


static var _glass: StandardMaterial3D
static var _tints := {}


## The windows' glass (dark shutters by day, lamplight by night: urbs_life.gd sets how bright).
static func window_glass() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = Color("2a1e14")
		_glass.emission_enabled = true
		_glass.emission = Color("ffb060")
		_glass.emission_energy_multiplier = 0.0
		_glass.roughness = 0.9
	return _glass


## A texture that takes each instance's colour (a MultiMesh's), so one plaster can be ochre, rose,
## cream or blue-grey from house to house.
static func tinted(kind: String) -> Material:
	if not _tints.has(kind):
		var base: Material = load("res://scripts/hall/textures.gd").material(kind)
		if not base is StandardMaterial3D:  # water and the like: a shader, worn as it is
			_tints[kind] = base
			return base
		var m: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
		m.vertex_color_use_as_albedo = true
		_tints[kind] = m
	return _tints[kind]


## The colours of plaster in each age: creams and whites under the Republic, ochres, roses and reds
## under the emperors, all of it duller and dirtier later.
const PLASTER := {
	"heroic": ["d8c8a0", "c8b890", "b8a880", "e0d4b8"],
	"collapse": ["b0a090", "a89484", "c0b4a0", "988878"],
	"early": ["e8dcc0", "d8c8a0", "c8b890", "f0e8d4", "b8a880"],
	"republic": ["f2ead8", "ece0c4", "e8d4a8", "f4f0e6", "d8c8a8", "e8c8a0"],
	"empire": ["e0b070", "d8907a", "f0e4c8", "c8704e", "ecd898", "b8c4c8", "f4f0e8", "d8a878"],
	"late": ["c8a878", "b88a74", "d8ccb4", "a8745a", "c8c0a8", "a8b0b0"],
	"fall": ["a89a88", "9a8a7a", "b0a898", "8a7e70"],
}


## The houses and flats: blocks on a crooked grid, each block split into two or three houses of
## their own height and kind, so the roofline jumps and the walls change colour door by door.
##   - Flats (insulae): a ground storey of shops behind arches, storeys of plaster or brick above
##     with their windows, a top storey set back, a tiled roof or a roof terrace (some with a
##     garden and a pergola), wooden balconies, awnings over the shops and wares set out.
##   - On the hills and here and there below, the houses of the rich (domus): two storeys round a
##     courtyard garden with its tree and its pool.
##   - By the river, warehouses (horrea); along some streets, single-storey rows of shops.
##   - In the emptied city most are broken walls without roofs, overgrown; people live only in the
##     bend of the river.
## Beyond where you can walk the city goes on to Aurelian's line, simpler, not solid. Trees stand in
## the squares, the courtyards, the roof gardens, on the hills and along the river. Drawn in
## MultiMeshes (one per mesh and surface, each house its own colour).
static func _blocks(world: Node3D, age: Dictionary, standing: Array, streets: Array, skip: Array, lost: bool, out: Dictionary) -> void:
	var c := city_data()
	var id: String = age.get("id", "republic")
	var year := int(age.get("year", -50))
	var fallen: bool = id == "fall" or lost
	var republic := year < -30
	var old := id in ["heroic", "early"]  # the small city of tufa and timber, with fields inside its wall
	var forum := at([0, 0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 753 + year
	var edge := walkable()
	var outer: Array = (c.get("outer", []) as Array).map(func(q: Array) -> Vector3: return at(q))
	var clear: Array = out.get("clear", [])
	var servian: Array = (data()["wall"]["gates"] as Array).map(func(g: Dictionary) -> Vector3: return at(g["at"]))
	var opens: Array = []
	for o: Dictionary in c.get("open", []):
		if o.has("until") and year >= int(o["until"]):
			continue
		opens.append([at(o["at"]), span(float(o["r"]))])
	var keep_off: Array = standing.map(func(s: Dictionary) -> Array: return [s["at"], footprint(s["m"])])
	var wooded := groves(year)  # the sacred groves, the woods, the orchards and the gardens (green.json)
	var pools: Array = []  # the ponds, marshes and lakes: [centre, radius]
	var roads: Array = []
	for w: Dictionary in waters(year):
		if w["kind"] == "stream":  # a stream is a corridor nothing is built across, its banks left green
			var pts: Array = w["points"]
			for i in pts.size() - 1:
				roads.append([pts[i], pts[i + 1], float(w["width"]) / 2.0 + 3.0, true])
		else:
			pools.append([w["at"], float(w["r"]) + 3.0])
	var lines: Array = []  # the streets and lanes to line with houses, whole: {pts (world), half}
	for r: Dictionary in c.get("roads", []):
		var pts: Array = r["points"]
		for i in pts.size() - 1:
			roads.append([at(pts[i]), at(pts[i + 1]), float(r["width"]) / 2.0 + 3.0])
		lines.append({"pts": pts.map(func(q: Array) -> Vector3: return at(q)), "half": float(r["width"]) / 2.0})
		# the view corridor: from each end of the street to the monument it runs at (the Sacred Way
		# to the Capitol, the Argiletum to the Senate House), so nothing is built across the sight line
		for end: Vector3 in [at(pts[0]), at(pts[pts.size() - 1])]:
			var target := Vector3.INF
			var best := CORRIDOR
			for s: Dictionary in standing:
				var d: float = Vector2(s["at"].x - end.x, s["at"].z - end.z).length()
				if d < best and (s["m"] as Dictionary).has("note"):
					best = d
					target = s["at"]
			if target != Vector3.INF and best > 4.0:
				roads.append([end, target, float(r["width"]) / 2.0 + 3.0, true])  # a corridor, not a street to line
	var landmarks: Array = standing.filter(func(s: Dictionary) -> bool: return (s["m"] as Dictionary).get("landmark", false)).map(
		func(s: Dictionary) -> Vector3: return s["at"])
	var ab: Dictionary = c.get("abitato", {})
	var abitato := at(ab.get("at", [-800, 450]))
	var abitato_r := span(float(ab.get("radius", 500)))
	var palette: Array = PLASTER.get(id, PLASTER["empire"])
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector3 in outer:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	var parts := {}  # "mesh|material" -> [[transform, colour], ...]
	_burnt = []
	_roosts = []
	_pools = []
	_springs = []
	_obbs = []
	_cells = {}
	_lamps = []
	var named: Array = []  # the named streets' stretches, [a, b, half + 3], for the lanes' mouths
	for r: Array in roads:
		if r.size() < 4:
			named.append(r)
	# the lanes between the blocks: unpaved streets along the bent grid every third row and column,
	# each laid only where its whole length is free of the map, broken at the named streets (and
	# opening into them), the squares, the monuments, the water and the wall; the houses front onto
	# them like the named streets (so the city is blocks of houses between streets)
	for lane: Array in _lanes(lo, hi, outer, named):
		var pts: Array = lane.map(func(q: Vector3) -> Vector3: return Vector3(q.x, ground(q), q.z))
		ribbon(world, pts, LANE, "path" if not fallen else "rubble", 0.1)
		_occ.paint_line(lane, LANE / 2.0 + 0.6, Occupancy.LANE)
		for i in pts.size() - 1:
			roads.append([lane[i], lane[i + 1], LANE / 2.0 + 3.0])
		lines.append({"pts": lane, "half": LANE / 2.0})
	_bands = roads
	var add := func(kind: String, mat: String, xf: Transform3D, col: Color = Color.WHITE) -> void:
		var key := kind + "|" + mat
		if not parts.has(key):
			parts[key] = []
		parts[key].append([xf, col])
	for line: Dictionary in lines:  # what the animals leave in the lanes: dung, and straw fallen from the loads
		if absf(float(line["half"]) - LANE / 2.0) > 0.01:
			continue
		var lpts: Array = line["pts"]
		for i in lpts.size() - 1:
			if rng.randf() > (0.35 if not fallen else 0.1):
				continue
			var q: Vector3 = (lpts[i] as Vector3).lerp(lpts[i + 1], rng.randf())
			q += Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0))
			q.y = ground(q) + 0.1
			if rng.randf() < 0.55:
				add.call("rock", "#4a3a26", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(0.3, 0.1, 0.26)), q + Vector3(0, 0.03, 0)))
			else:
				add.call("box", "#c8b070", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(0.7, 0.02, 0.45)), q + Vector3(0, 0.01, 0)))
	var trees: Array = []  # [where, kind, size]
	if id in ["late", "collapse", "fall"]:  # weeds in the gutters of the streets no aedile keeps
		for line: Dictionary in lines:
			if absf(float(line["half"]) - LANE / 2.0) < 0.01:
				continue
			var spts: Array = line["pts"]
			var shalf := float(line["half"])
			for i in spts.size() - 1:
				var a: Vector3 = spts[i]
				var bq: Vector3 = spts[i + 1]
				var dirv := (bq - a)
				dirv.y = 0.0
				var seg := dirv.length()
				dirv = dirv.normalized()
				var t: float = rng.randf_range(0.0, 6.0)
				while t < seg:
					if rng.randf() < 0.6:
						var q := a + dirv * t + Vector3(dirv.z, 0, -dirv.x) * (shalf - 0.3) * (1.0 if rng.randf() < 0.5 else -1.0)
						q.y = ground(q) + 0.12
						trees.append([q, "grass", rng.randf_range(0.6, 1.0), true])
					t += rng.randf_range(4.0, 9.0)
	var doors: Array = out.get("doors", [])
	var taken := {}
	# raising a house on a plot found free: a ruin in the emptied city or the lost world, a plain
	# block far off, a domus on the hills and here and there, else the block split into houses
	var raise := func(p: Vector3, basis: Basis, w: float, d: float, far: bool, street_half: float, roll2: float, hill: bool) -> void:
		var yaw := basis.get_euler().y
		var ruin: bool = lost or (fallen and (p.distance_to(abitato) > abitato_r or roll2 < 0.3))
		if not far:
			var shape := BoxShape3D.new()
			shape.size = Vector3(w, 14.0 if not ruin else 6.0, d)
			Kit.solid(world, shape, Vector3(p.x, ground(p) + 2.0, p.z), Vector3(0, yaw, 0))
		if ruin:
			_ruin(add, p, basis, w, d, rng, trees, fallen and not lost and p.distance_to(abitato) < abitato_r * 1.3)
			return
		if far:
			_far_house(add, p, basis, w, d, rng, palette, republic, old)
			return
		var near_river := river_edge(p) < 40.0
		if hill or (roll2 < 0.1 and not near_river):
			_domus(add, p, basis, w, d, rng, palette, trees)
			return
		# the block split into two or three houses side by side along its length
		var lots := 1 if w < 11.0 else (2 if w < 20.0 else 3)
		var x0 := -w / 2.0
		for k in lots:
			var lw := w / lots
			var centre := p + basis * Vector3(x0 + lw * (k + 0.5), 0, 0)
			var kind := "insula"
			if near_river and rng.randf() < 0.5:
				kind = "horreum"
			elif rng.randf() < 0.12:
				kind = "row"
			var floors := rng.randi_range(2, 4) if republic else rng.randi_range(3, 6)
			if old:
				floors = 1 if rng.randf() < 0.55 else 2
			if fallen:
				floors = rng.randi_range(1, 2)
			if floors > 3 and landmarks.any(func(l: Vector3) -> bool: return Vector2(l.x - centre.x, l.z - centre.z).length() < LANDMARK_LOW):
				floors = 3  # kept low round the landmarks, so they show over the roofs
			_house(add, centre, basis, lw - 0.3, d, floors, kind, rng, palette, republic, fallen, trees, doors, id, street_half)
	# the streets lined first, house against house along both sides of every named street and
	# lane, each with its front a step from the kerb, so every street has walls; the gaps left
	# (a square, a garden) are where the age leaves them
	for line: Dictionary in lines:
		var pts: Array = line["pts"]
		var half: float = line["half"]
		var cum: Array = [0.0]  # the distance along the line to each point
		for i in pts.size() - 1:
			var seg := Vector2((pts[i + 1] as Vector3).x - (pts[i] as Vector3).x, (pts[i + 1] as Vector3).z - (pts[i] as Vector3).z).length()
			cum.append(float(cum[-1]) + seg)
		var length := float(cum[-1])
		if length < 12.0:
			continue
		var along := func(t: float) -> Array:  # [the point on the line at t, the direction there]
			var i := 0
			while i < cum.size() - 2 and float(cum[i + 1]) < t:
				i += 1
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var seg := maxf(float(cum[i + 1]) - float(cum[i]), 0.001)
			var f := clampf((t - float(cum[i])) / seg, 0.0, 1.0)
			var dir := b - a
			dir.y = 0.0
			return [Vector3(a.x, 0, a.z).lerp(Vector3(b.x, 0, b.z), f), dir.normalized()]
		for side: float in [-1.0, 1.0]:
			var t := 3.0 + rng.randf_range(0.0, 4.0)
			var last_stall := -INF
			while t < length - 3.0:
				var w := rng.randf_range(9.5, 13.5)
				if rng.randf() < 0.15:
					w += 5.0
				if t + w > length - 3.0:
					w = length - 3.0 - t
					if w < 6.0:
						break
				var d := rng.randf_range(8.0, 10.0)
				var mid: Array = along.call(t + w / 2.0)
				var dir: Vector3 = mid[1]
				var n := Vector3(dir.z, 0, -dir.x)
				var p: Vector3 = (mid[0] as Vector3) + n * side * (half + 1.6 + d / 2.0)
				var far := not inside(edge, p)
				var y := ground(p)
				var hill := y > 4.0
				if half > 2.0 and not far and not fallen and rng.randf() < 0.08:  # a little square off the street, with its fountain
					var sq: Vector3 = (mid[0] as Vector3) + n * side * (half + 6.6)
					if _occ.disc_free(sq, 5.0):
						sq.y = ground(sq)
						out["fountains"].append(sq)
						_occ.paint_disc(sq, 3.0, Occupancy.FURNITURE)
						t += 12.0
						continue
				var keep := 0.92
				if republic and not inside(servian, p):
					keep = 0.5 if not old else 0.3
				if hill:
					keep = 0.8
				if fallen and not lost:
					keep = 0.4 if p.distance_to(abitato) < abitato_r else 0.15
				if old and (hill or p.distance_to(forum) > 95.0) and inside(servian, p):
					keep = 0.35  # the fields of the small city's hills, a farmhouse among them
				if far and rng.randf() < 0.3:
					t += w + 2.0
					continue
				if rng.randf() > keep:
					t += w + 2.0
					continue
				var yaw := atan2(-n.x * side, -n.z * side)  # the house's front (+Z) toward the street
				var basis := Basis(Vector3.UP, yaw)
				var built := false
				if _occ.kind_at(p) != Occupancy.VOID:
					# the house as drawn, else narrower (up to a lane's mouth), else shallower, its front still at the kerb
					for trial: Array in [[w, d], [w * 0.75, d], [w * 0.5, d], [w, d * 0.7], [w * 0.5, d * 0.7]]:
						var ww: float = trial[0]
						var dd: float = trial[1]
						if ww < 6.0:
							continue
						var m2: Array = along.call(t + ww / 2.0)
						var dir2: Vector3 = m2[1]
						var n2 := Vector3(dir2.z, 0, -dir2.x)
						var pp: Vector3 = (m2[0] as Vector3) + n2 * side * (half + 1.6 + dd / 2.0)
						var b2 := Basis(Vector3.UP, atan2(-n2.x * side, -n2.z * side))
						if not _fits(pp, b2, ww, dd, 0.25):
							continue
						_register(pp, b2, ww, dd)
						raise.call(pp, b2, ww, dd, far, half, rng.randf(), hill)
						built = true
						# a stall set up on the pavement before the shops, oftener on the named streets than in the lanes
						if not far and not fallen and rng.randf() < (0.14 if half > 2.0 else 0.08):
							var st: Vector3 = (m2[0] as Vector3) + n2 * side * (half + 0.9)
							if _occ.kind_at(st) in STALL_ON:
								out["stalls"].append(st)
								_occ.paint_disc(st, 1.3, Occupancy.FURNITURE)
								last_stall = t
						t += ww + rng.randf_range(0.0, 1.2)
						break
				if not built:
					if not fallen and not far and half > 2.0 and t - last_stall > 30.0 and rng.randf() < 0.5:  # no room for a house: a stall on the kerb now and then
						var stall := (mid[0] as Vector3) + n * side * (half + 0.9)
						if _occ.kind_at(stall) in STALL_ON:
							out["stalls"].append(stall)
							_occ.paint_disc(stall, 1.3, Occupancy.FURNITURE)
							last_stall = t
					t += 2.0
	for j in int((hi.y - lo.y) / PITCH) + 1:
		for i in int((hi.x - lo.x) / PITCH) + 1:
			if taken.has(Vector2i(i, j)):
				continue
			var bx := lo.x + i * PITCH
			var bz := lo.y + j * PITCH
			var bend := _warp(bx, bz)
			var p := Vector3(bx + bend.x + rng.randf_range(-1.0, 1.0), 0, bz + bend.y + rng.randf_range(-1.0, 1.0))
			var roll := rng.randf()
			var roll2 := rng.randf()
			var here: int = _occ.kind_at(p)
			if here == Occupancy.VOID or here == Occupancy.WALL or here == Occupancy.WATER:
				continue
			var far := not inside(edge, p)  # beyond where you walk: seen, not visited
			if far and roll < (0.35 if not old else 0.6):
				continue
			if here == Occupancy.BANK:  # the river's or a pond's bank: trees along it, reeds at the water
				if roll < 0.4:
					trees.append([p, "round" if roll2 < 0.6 else ("olive" if roll2 < 0.8 else "pine"), rng.randf_range(0.8, 1.2)])
				if not far and river_edge(p) < 9.0:
					_plant(trees, rng, p, "reeds", 3, 5.0, 0.8, 1.3)
					_plant(trees, rng, p, "grass", 2, 6.0)
				continue
			if here == Occupancy.OPEN:  # a square, the Campus: a plane now and then, grass
				if roll < 0.14:
					trees.append([p, "round", rng.randf_range(0.9, 1.3)])
				if not far and roll2 < 0.5:
					_plant(trees, rng, p, "grass", 3, 7.0)
				continue
			if here == Occupancy.MONUMENT:  # a monument's ground: the sacred grove by the temple
				if roll < 0.3:
					trees.append([p + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4)), "cypress" if roll2 < 0.7 else "round", rng.randf_range(0.9, 1.2)])
				continue
			if here == Occupancy.GROVE:
				var grove: Dictionary = {}
				for g: Dictionary in wooded:
					if Vector2(p.x - (g["at"] as Vector3).x, p.z - (g["at"] as Vector3).z).length() < float(g["r"]):
						grove = g
						break
				if not grove.is_empty():
					_grove_cell(world, trees, rng, p, str(grove["kind"]), far, fallen, add)
				continue
			if here != Occupancy.FREE:
				continue  # a street, a lane, a house lined along one, a fountain, a tomb
			var w := rng.randf_range(9.5, 12.5)
			var d := rng.randf_range(9.5, 12.5)
			var yaw := 0.0
			var y := ground(p)
			var hill := y > 4.0
			var outer_hill := old and (hill or p.distance_to(forum) > 95.0) and inside(servian, p)  # the Esquiline, the Caelian, the Aventine's back
			var keep := 0.9
			if republic and not inside(servian, p):
				keep = 0.45 if not old else 0.25
			if hill:
				keep = 0.8
			if fallen and not lost:  # the emptied city: open ground, a few ruins, the huts by the river
				keep = 0.4 if p.distance_to(abitato) < abitato_r else 0.15
			if roll > keep:  # a little square: a fountain, a tree, or a garden on the hills
				var kind := _hill_tree(p, y, roll2)
				if fallen:  # the emptied city grown over
					if roll2 < 0.4:
						trees.append([p, "bush" if roll2 < 0.2 else kind, rng.randf_range(0.7, 1.2)])
					if not far:
						_plant(trees, rng, p, "grass", 5, 7.0, 0.8, 1.4)
						_plant(trees, rng, p, "bush", 1, 6.0, 0.6, 1.0)
				elif kind == "rock":  # the Capitol's bare face
					add.call("rock", "rock", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(rng.randf_range(3.0, 6.0), rng.randf_range(1.5, 3.0), rng.randf_range(3.0, 6.0))), Vector3(p.x, y + 0.2, p.z)))
					_plant(trees, rng, p, "grass", 3, 6.0)
				elif roll2 < 0.35 and not far and not hill and _occ.disc_free(p, 3.5):
					out["fountains"].append(p)
					_occ.paint_disc(p, 3.0, Occupancy.FURNITURE)
					trees.append([p + Vector3(3.5, 0, 2.5), "round", rng.randf_range(0.9, 1.2)])  # the plane over the fountain
				elif roll2 < 0.8 or hill:
					trees.append([p, kind, rng.randf_range(0.8, 1.3)])
					if hill:  # the hills' gardens: a clump, bushes, the grass between
						_plant(trees, rng, p, "cypress" if kind == "cypress" or roll2 < 0.5 else "pine", 2, 6.0, 0.8, 1.2)
						_plant(trees, rng, p, "round" if roll2 < 0.5 else "olive", 1, 6.0, 0.7, 1.0)
						_plant(trees, rng, p, "bush", 2, 6.0)
					else:
						_plant(trees, rng, p, "bush", 1, 4.0)
						_plant(trees, rng, p, "flowers", 2, 4.0)
					if not far:
						_plant(trees, rng, p, "grass", 4, 7.0)
				continue
			var along := _warp(bx + 1.0, bz) - bend  # which way the bent grid's rows run here
			yaw = atan2(-along.y, 1.0 + along.x) + rng.randf_range(-0.03, 0.03)
			var basis := Basis(Vector3.UP, yaw)
			if outer_hill and roll2 < 0.66:  # fields inside the wall, a farmhouse among them
				if rng.randf() < 0.5:
					var p2 := p + basis * Vector3(PITCH / 2.0, 0, 0)
					if _fits(p2, basis, w + PITCH, d, 0.5):
						taken[Vector2i(i + 1, j)] = true
						w += PITCH
						p = p2
				var fits := false
				for shrink: float in [1.0, 0.8, 0.65]:
					if _fits(p, basis, w * shrink, d * shrink, 0.5):
						w *= shrink
						d *= shrink
						fits = true
						break
				if not fits:
					continue
				_register(p, basis, w, d)
				_plot(add, p, basis, w, d, rng, palette, trees, doors, far)
				continue
			if rng.randf() < 0.22 and not hill and not old:  # a long block over two cells, the alley between built over
				var p2 := p + basis * Vector3(PITCH / 2.0, 0, 0)
				if _fits(p2, basis, w + PITCH, d, 0.5):
					taken[Vector2i(i + 1, j)] = true
					w += PITCH
					p = p2
			# a block between the rows lined along the streets and lanes takes what room is left: it
			# is built smaller if it must, and not at all under six paces
			var fitted := false
			for shrink: float in [1.0, 0.85, 0.72, 0.6, 0.5]:
				var ww := w * shrink
				var dd := d * shrink
				if ww < 6.0 or dd < 6.0:
					break
				if _fits(p, basis, ww, dd, 0.5):
					w = ww
					d = dd
					fitted = true
					break
			if not fitted:
				continue  # into a house already built, a street, or a monument's ground
			_register(p, basis, w, d)
			if hill and rng.randf() < 0.45:  # the yard behind a hill house: a fig, a cypress
				trees.append([p + basis * Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0, -(d / 2.0 + 1.5)), "round" if rng.randf() < 0.5 else ("cypress" if rng.randf() < 0.6 else "olive"), rng.randf_range(0.6, 0.9)])
			elif not hill and rng.randf() < (0.4 if not far else 0.2):  # a pine or a cypress in the yard behind, grown up over the roofs
				var tall := rng.randf() < 0.55
				trees.append([p + basis * Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0, -(d / 2.0 + 1.6)), "pine" if tall else "cypress",
					rng.randf_range(1.8, 2.4)])
			raise.call(p, basis, w, d, far, 0.0, roll2, hill)
	for tomb: Dictionary in out.get("tombs", []):  # a cypress either side of each tomb along the roads
		var tb := Basis(Vector3.UP, float(tomb["yaw"]))
		for side: float in [-1.0, 1.0]:
			if rng.randf() < 0.7:
				trees.append([(tomb["at"] as Vector3) + tb * Vector3(side * 2.6, 0, -0.5), "cypress", rng.randf_range(0.8, 1.1)])
	out["doors"] = doors
	out["burnt"] = _burnt.duplicate()
	for pool: Vector3 in _pools:
		out["waters"].append([pool, "fountain"])
	for spring: Vector3 in _springs:
		out["waters"].append([spring, "stream"])
	if not fallen:  # the pigeons on the ridges and parapets
		for r: Array in _roosts:
			var at: Vector3 = r[0]
			var bb: Basis = r[1]
			for k in int(r[2]):
				var q := at + bb * Vector3(rng.randf_range(-1.2, 1.2), 0.1, rng.randf_range(-0.2, 0.2))
				var turn := bb * Basis(Vector3.UP, rng.randf_range(-0.6, 0.6))
				add.call("box", "#8a8a94", Transform3D(turn.scaled_local(Vector3(0.16, 0.14, 0.3)), q))
				add.call("box", "#5a6a70", Transform3D(turn.scaled_local(Vector3(0.1, 0.1, 0.12)), q + turn * Vector3(0, 0.09, 0.14)))
	out["shops"] = _draw(world, parts)
	# the street fountains, with a lamp on a post by each
	var flames := MultiMesh.new()
	flames.transform_format = MultiMesh.TRANSFORM_3D
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.16
	flame_mesh.height = 0.4
	flames.mesh = flame_mesh
	var fountains: Array = out["fountains"]
	flames.instance_count = fountains.size() + _lamps.size()
	for k in _lamps.size():  # the little flames of the door lamps
		flames.set_instance_transform(fountains.size() + k, Transform3D(Basis.IDENTITY.scaled(Vector3(0.45, 0.45, 0.45)), _lamps[k]))
	for k in fountains.size():
		var f: Vector3 = fountains[k]
		var y := ground(f)
		Rome.fountain(world, Vector3(f.x, y, f.z), rng.randf() * TAU, year < 537 and not lost)
		if year < 537 and not lost:
			out["waters"].append([Vector3(f.x, y, f.z), "fountain"])
		Kit.box(world, Vector3(f.x + 1.6, y + 1.3, f.z), Vector3(0.12, 2.6, 0.12), "bronze", false)
		flames.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(f.x + 1.6, y + 2.75, f.z)))
	var fmi := MultiMeshInstance3D.new()
	fmi.name = "Flames"
	fmi.multimesh = flames
	fmi.material_override = load("res://scripts/hall/textures.gd").material("fire")
	fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(fmi)
	out["flames"] = [fmi]
	# where the river folk work: along the banks inside the city
	var banks: Array = []
	var course: Array = (data()["tiber"]["course"] as Array).map(func(q: Array) -> Vector3: return at(q))
	var reeds: Array = []  # the reeds at the water's edge, both banks, the whole way through the city
	for i in course.size() - 1:
		var a: Vector3 = course[i]
		var b: Vector3 = course[i + 1]
		var along := (b - a).normalized()
		var across := Vector3(along.z, 0, -along.x)
		var t := 0.0
		while t < a.distance_to(b):
			var q := a + along * t
			t += 7.0
			for s: float in [-1.0, 1.0]:
				for off in range(6, 40, 2):
					var r := q + across * s * float(off)
					if river_edge(r) > 1.2:
						if inside(edge, r) and skip.is_empty():
							reeds.append([r + across * s * rng.randf_range(0.0, 1.5), "reeds", rng.randf_range(0.8, 1.3)])
							if rng.randf() < 0.5:
								reeds.append([r + across * s * 2.5 + along * rng.randf_range(-2.0, 2.0), "reeds", rng.randf_range(0.7, 1.1)])
						break
	trees.append_array(reeds)
	_waters(world, year, fallen, trees, rng, out)
	# nothing grows through a house, in a street or under a pergola (a fourth entry marks a tree
	# planted where it belongs inside a plot: a garden's, a ruin's, a field's, a roof's)
	var grown: Array = []
	for t: Array in trees:
		if t.size() > 3:
			grown.append(t)
			continue
		var q: Vector3 = t[0]
		var kind: String = t[1]
		var trunked := kind in ["pine", "cypress", "round", "olive"]
		if trunked:
			if not _occ.disc_free(q, 1.0, Occupancy.ALLOW_PLANT):
				continue
		else:
			var allow: int = Occupancy.ALLOW_PLANT | ((1 << Occupancy.WATER) if kind == "reeds" else 0)
			if not _occ.disc_free(q, 0.5, allow):  # a pace round it, so a tuft is not sunk into a house's corner between two cells
				continue
		grown.append(t)
	trees = grown
	_last_trees = trees
	for t: Array in trees:  # the trunks, so what is set out after (a basin, a shrine) keeps off them
		if t[1] in ["pine", "cypress", "round", "olive"]:
			_occ.paint_disc(t[0], 0.7, Occupancy.TREE)
	_trees(world, trees, fallen)
	for i in course.size() - 1:
		var a: Vector3 = course[i]
		var b: Vector3 = course[i + 1]
		var across := Vector3((b - a).normalized().z, 0, -(b - a).normalized().x)
		for k in int(a.distance_to(b) / 20.0):
			for s: float in [-1.0, 1.0]:
				var q := a.lerp(b, (k + 0.5) / int(a.distance_to(b) / 20.0)) + across * s * (_half_width() + BANK + 3.0)
				if inside(edge, q) and ground(q) > -0.3:
					banks.append(q)
	out["banks"] = banks


## One house of a block, in the house set's textures (textures_houses.gd). `kind`: "insula" (flats
## over shops), "horreum" (a warehouse), "row" (a single storey of shops). The kit changes with the
## age (docs/rome-city-notes.md 2.1):
##   heroic, early: low houses of tufa blocks or plaster over timber, one or two storeys under wide
##     eaves of tiles or thatch, a blank wall to the street and a door in it, no shops;
##   republic: the first tall insulae, shops under the flats, balconies;
##   empire: brick-faced concrete, arcaded shops, up to six storeys, roof gardens;
##   late: the same blocks patched, windows bricked up, the tall ones half-empty;
##   collapse: roofs burnt to their beams, doors off, scaffolding no one finishes;
##   fall: what is left is a ruin (_ruin), with huts in it by the river.
## The life on the fronts: shop bays with their counters and pots (shut at night, urbs_life.gd),
## doors with a lamp, windows with frames, open shutters and a pot of flowers, washing on lines
## across the street (`street_w`, the street's half-width, when the house is lined up on one),
## vines up the walls, pigeons on the ridges (_roosts).
static func _house(add: Callable, c: Vector3, b: Basis, w: float, d: float, floors: int, kind: String, rng: RandomNumberGenerator,
		palette: Array, republic: bool, fallen: bool, trees: Array, doors: Array, age_id: String = "republic", street_w: float = 0.0) -> void:
	var y := ground(c)
	var low := minf(y, minf(ground(c + b * Vector3(w / 2.0, 0, d / 2.0)), ground(c - b * Vector3(w / 2.0, 0, d / 2.0)))) - 1.0
	var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
	var old := age_id in ["heroic", "early"]
	var late := age_id == "late"
	# the burnt quarters of 455; and in every age a house or two in each quarter gutted by the fires Rome never lacked
	var burnt := (age_id == "collapse" and rng.randf() < 0.3) or (age_id in ["republic", "empire", "late"] and rng.randf() < 0.008)
	if burnt:
		_burnt.append(Vector3(c.x, y + floors * 4.0, c.z))
	if old and kind != "horreum":
		_old_house(add, c, b, w, d, floors, rng, tint, low, doors, street_w)
		return
	var brick := not republic and rng.randf() < 0.4
	var wall := "h_brick" if brick else ("h_plaster_worn" if late or burnt else "h_plaster")
	var wall_tint := Color.WHITE if brick else (tint if not burnt else tint.darkened(0.5))
	if kind == "horreum":  # a warehouse: plain brick, a few small high windows, a flat roof, a big door
		var h := 8.0
		add.call("box", "h_brick", Transform3D(b.scaled_local(Vector3(w, y + h - low, d)), Vector3(c.x, (low + y + h) / 2.0, c.z)))
		add.call("box", "r_slab", Transform3D(b.scaled_local(Vector3(w + 0.3, 0.3, d + 0.3)), Vector3(c.x, y + h + 0.15, c.z)))
		for s: float in [1.0, -1.0]:
			for k in maxi(1, int(w / 4.0)):
				var x := -w / 2.0 + (k + 0.5) * w / maxi(1, int(w / 4.0))
				add.call("quad", "h_window_small", _face(b, c, Vector3(x, y + 6.0 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(0.8, 0.9)))
			add.call("quad", "h_door", _face(b, c, Vector3(0, y + 1.6 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(2.6, 3.2)))
		return
	var ground_h := 4.0
	# the ground storey, and its bays: shops, doors, blank wall
	add.call("box", wall, Transform3D(b.scaled_local(Vector3(w, y + ground_h - low, d)), Vector3(c.x, (low + y + ground_h) / 2.0, c.z)), wall_tint)
	add.call("box", "#8a8074", Transform3D(b.scaled_local(Vector3(w + 0.04, 0.9, d + 0.04)), Vector3(c.x, y + 0.45, c.z)), tint.darkened(0.35))  # the damp at the foot
	var shops := 0
	for s: float in [1.0, -1.0]:
		shops += _bays(add, c, b, w, d, y, s, kind, rng, fallen, late, burnt, doors, age_id)
		if d > 7.0:  # and along the sides, fewer: a door, a shut shop, a barred window
			shops += _bays(add, c, b, w, d, y, s, kind, rng, fallen, late, burnt, doors, age_id, true)
	var top := y + ground_h
	if kind == "row" or floors <= 1:  # a row of shops: a lean-to of tiles
		add.call("prism", _roof_of(age_id, burnt), Transform3D(b.scaled_local(Vector3(w + 0.6, 1.6, d + 0.8)), Vector3(c.x, top + 0.8, c.z)))
		_ridge(add, c, b, w, d, top + 1.6, rng)
	else:
		var upper := (floors - 1) * 4.0
		var setback := floors >= 4 and rng.randf() < 0.35
		if setback:
			upper -= 4.0
		add.call("box", wall, Transform3D(b.scaled_local(Vector3(w, upper, d)), Vector3(c.x, top + upper / 2.0, c.z)), wall_tint)
		if late or burnt:  # plaster patched over the brick
			for k in rng.randi_range(1, 3):
				var s := 1.0 if rng.randf() < 0.5 else -1.0
				add.call("quad", "h_brick", _face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), top + rng.randf_range(2.0, maxf(2.1, upper - 2.0)) - c.y,
					s * (d / 2.0 + 0.04)), s, Vector2(rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 3.0))))
		for f in int(upper / 4.0):  # the windows, storey by storey
			_windows(add, c, b, w, d, top + f * 4.0 + 1.9, rng, 0.35 if late else (0.2 if burnt else 0.0), not burnt and not late)
		if street_w > 0.0 and floors >= 3 and rng.randf() < (0.35 if not late else 0.15) and not burnt:  # washing across the street
			_washing(add, c, b, w, d, top + 4.0 + rng.randf_range(0.0, 2.0), street_w, rng)
		top += upper
		if burnt:  # the roof gone to its charred beams, the top storey open
			for k in maxi(2, int(w / 2.2)):
				add.call("box", "#2a2622", Transform3D(b.scaled_local(Vector3(0.25, 0.3, d + 0.6)), Vector3(c.x, top + 0.4, c.z) + b * Vector3(-w / 2.0 + (k + 0.5) * w / maxi(2, int(w / 2.2)), 0, 0)))
			add.call("box", "#2a2622", Transform3D(b.scaled_local(Vector3(w + 0.4, 0.2, 0.25)), Vector3(c.x, top + 0.4, c.z)))
			if rng.randf() < 0.4:  # scaffolding no one finishes
				var s := 1.0 if rng.randf() < 0.5 else -1.0
				for x: float in [-w * 0.3, 0.0, w * 0.3]:
					add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.18, top - y + 2.0, 0.18)), Vector3(c.x, (y + top + 2.0) / 2.0, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 1.0))))
				add.call("box", "wood", Transform3D(b.scaled_local(Vector3(w * 0.7, 0.12, 1.2)), Vector3(c.x, top - 1.0, c.z) + b * Vector3(0, 0, s * (d / 2.0 + 0.7))))
			return
		if setback:  # a top storey set back, lighter, often timber-framed
			var tw := w - 1.8
			var td := d - 1.8
			var tint2 := Color("#" + str(palette[rng.randi() % palette.size()]))
			add.call("box", "h_timber" if rng.randf() < 0.5 else "h_plaster", Transform3D(b.scaled_local(Vector3(tw, 3.4, td)), Vector3(c.x, top + 1.7, c.z)), tint2)
			_windows(add, c, b, tw, td, top + 1.6, rng, 0.0, true)
			add.call("box", "r_slab", Transform3D(b.scaled_local(Vector3(w, 0.25, d)), Vector3(c.x, top + 0.12, c.z)))  # the terrace round it
			top += 3.4
		if rng.randf() < 0.6 or republic:  # a tiled roof
			var rw := w + 0.8 if not setback else w - 1.0
			var rd := d + 0.8 if not setback else d - 1.0
			add.call("prism", _roof_of(age_id, false), Transform3D(b.scaled_local(Vector3(rw, 2.2, rd)), Vector3(c.x, top + 1.1, c.z)))
			_ridge(add, c, b, rw, rd, top + 2.2, rng)
			if rng.randf() < 0.3:  # a patch of the roof re-tiled: newer tiles on the mossy roofs of the late city, older ones before
				var ps := 1.0 if rng.randf() < 0.5 else -1.0
				var slope := atan2(2.2, rd / 2.0)
				var patch := Vector3(c.x, top, c.z) + b * Vector3(rng.randf_range(-rw * 0.3, rw * 0.3), 1.1 + 0.06, ps * rd * 0.25)
				add.call("box", "h_roof" if late else "h_roof", Transform3D((b * Basis(Vector3.RIGHT, -slope * ps)).scaled_local(Vector3(rng.randf_range(1.6, 2.8), 0.06, 1.4)), patch),
					Color.WHITE if late else Color(0.84, 0.78, 0.72))
		else:  # a roof terrace with its parapet, sometimes a garden and a pergola on it
			add.call("box", "r_slab", Transform3D(b.scaled_local(Vector3(w + 0.3, 0.3, d + 0.3)), Vector3(c.x, top + 0.15, c.z)))
			add.call("box", "h_plaster", Transform3D(b.scaled_local(Vector3(w + 0.3, 0.8, 0.25)), Vector3(c.x, top, c.z) + b * Vector3(0, 0.55, d / 2.0)), tint)
			add.call("box", "h_plaster", Transform3D(b.scaled_local(Vector3(w + 0.3, 0.8, 0.25)), Vector3(c.x, top, c.z) + b * Vector3(0, 0.55, -d / 2.0)), tint)
			if rng.randf() < 0.55 and not fallen:
				for k in rng.randi_range(2, 4):  # planters of box and myrtle, and a little tree in a pot
					var q := Vector3(c.x, top, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0.5, rng.randf_range(-d * 0.35, d * 0.35))
					add.call("box", "terracotta", Transform3D(b.scaled_local(Vector3(1.4, 0.6, 0.6)), q))
					add.call("box", "leaves", Transform3D(b.scaled_local(Vector3(1.3, 0.5, 0.5)), q + Vector3(0, 0.5, 0)))
				trees.append([Vector3(c.x, top + 0.3, c.z) + b * Vector3(w * 0.2, 0, 0), "round", 0.45, true])
				for x: float in [-1.0, 1.0]:  # the pergola's posts and beams, a vine over it
					for z: float in [-1.0, 1.0]:
						add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.15, 2.4, 0.15)), Vector3(c.x, top, c.z) + b * Vector3(x * w * 0.25 - w * 0.15, 1.2, z * d * 0.2)))
				add.call("box", "leaves", Transform3D(b.scaled_local(Vector3(w * 0.55, 0.25, d * 0.45)), Vector3(c.x, top, c.z) + b * Vector3(-w * 0.15, 2.5, 0)))
			if rng.randf() < 0.5:
				_roost(c + b * Vector3(rng.randf_range(-w * 0.4, w * 0.4), 0, d / 2.0), top + 0.8, rng)
		if floors >= 3 and rng.randf() < 0.45 and not fallen:  # a wooden balcony along the second storey
			var s := 1.0 if rng.randf() < 0.5 else -1.0
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(w * 0.8, 0.2, 1.1)), Vector3(c.x, y, c.z) + b * Vector3(0, 8.0, s * (d / 2.0 + 0.55))))
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(w * 0.8, 0.8, 0.08)), Vector3(c.x, y, c.z) + b * Vector3(0, 8.5, s * (d / 2.0 + 1.08))))
			for k in 3:  # pots and washing on it
				add.call("box", "terracotta", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.35, 0.35, 0.35)),
					Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 8.3, s * (d / 2.0 + 0.8))))
				add.call("box", "leaves", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.4, 0.3, 0.4)),
					Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 8.65, s * (d / 2.0 + 0.8))))
			for k in rng.randi_range(2, 4):
				add.call("quad", "h_cloth", _face(b, c, Vector3(rng.randf_range(-w * 0.35, w * 0.35), 8.9 + y - c.y, s * (d / 2.0 + 1.12)), s, Vector2(0.7, 0.8)),
					TUNICS[rng.randi() % TUNICS.size()])
	var prop_chance: float = {"late": 0.22, "collapse": 0.4, "empire": 0.05, "republic": 0.05}.get(age_id, 0.0)
	if floors >= 2 and not burnt and rng.randf() < prop_chance:  # a wall shored up with timber props from the pavement
		var ps := 1.0 if rng.randf() < 0.5 else -1.0
		var px := rng.randf_range(-w * 0.3, w * 0.3)
		var lean := atan2(2.3, 5.6)
		for k in 2:
			var foot := Vector3(c.x, y, c.z) + b * Vector3(px + k * 1.4, 0, ps * (d / 2.0 + 2.3))
			var mid := foot + b * Vector3(0, 2.9, -ps * 1.15)
			add.call("box", "wood", Transform3D((b * Basis(Vector3.RIGHT, lean * ps)).scaled_local(Vector3(0.22, 6.1, 0.22)), mid))
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(1.9, 0.14, 0.14)), Vector3(c.x, y + 3.0, c.z) + b * Vector3(px + 0.7, 0, ps * (d / 2.0 + 1.1))))  # the brace between them
	if rng.randf() < 0.14 and not burnt:  # a vine up the wall
		var s := 1.0 if rng.randf() < 0.5 else -1.0
		add.call("quad", "h_vine", _face(b, c, Vector3(rng.randf_range(-w * 0.4, w * 0.4), y + 2.6 - c.y, s * (d / 2.0 + 0.05)), s, Vector2(1.3, 5.0)))
	for s: float in [1.0, -1.0]:  # before the shops: a step of slabs, an awning, wares
		if rng.randf() < 0.55:
			add.call("box", "r_slab", Transform3D(b.scaled_local(Vector3(w, 0.1, 1.5)), Vector3(c.x, y + 0.02, c.z) + b * Vector3(0, 0, s * (d / 2.0 + 0.75))))
		if fallen:
			continue
		if rng.randf() < (0.35 if age_id in ["republic", "empire"] else 0.15) and age_id not in ["heroic", "early"]:  # election notices and scratched words by the shop doors
			var notice_age := age_id if age_id in ["republic", "empire"] else "late"
			var notice_n: int = (TexSet.notices(notice_age) as Array).size()
			add.call("quad", "graffiti_%s_%d" % [notice_age, rng.randi() % maxi(1, notice_n)],
				_face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), 2.9 + y - c.y, s * (d / 2.0 + 0.05)), s, Vector2(1.8, 0.8)))
		if shops > 0 and rng.randf() < (0.4 if not late else 0.2):
			add.call("box", "awning", Transform3D(b * Basis(Vector3.RIGHT, 0.35 * s).scaled_local(Vector3(w * 0.6, 0.06, 1.8)),
				Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.15, w * 0.15), 3.3, s * (d / 2.0 + 0.9))))
			for k in rng.randi_range(2, 5):
				var q := Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0, s * (d / 2.0 + rng.randf_range(0.5, 1.4)))
				if rng.randf() < 0.6:
					add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY, q + Vector3(0, 0.45, 0)))
				else:
					add.call("box", "wood", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(0.7, 0.6, 0.7)), q + Vector3(0, 0.3, 0)))


## The colours washing is dyed: the undyed wool of most tunics, and the reds, blues and ochres of
## the rest.
const TUNICS := [Color("eee6d8"), Color("e8dcc0"), Color("c86a4a"), Color("7a8ab0"), Color("c8a860"), Color("a86a7a"), Color("8aa080")]

## The roof of an age: new tiles, mossy old ones in the late city, holes when burnt.
static func _roof_of(age_id: String, burnt: bool) -> String:
	if burnt:
		return "h_roof_broken"
	return "h_roof_moss" if age_id in ["late", "collapse", "fall"] else "h_roof"


## The ridge of a tiled roof: a line of cover tiles, and now and then the pigeons sitting on it.
static func _ridge(add: Callable, c: Vector3, b: Basis, rw: float, rd: float, top: float, rng: RandomNumberGenerator) -> void:
	var along_x := rw >= rd  # the prism's ridge runs along its longer side
	add.call("box", "#8a4a30", Transform3D(b.scaled_local(Vector3(rw if along_x else 0.3, 0.22, 0.3 if along_x else rd)), Vector3(c.x, top - 0.05, c.z)))
	if rng.randf() < 0.18:
		var t := rng.randf_range(-0.4, 0.4)
		_roost(c + b * (Vector3(rw * t, 0, 0) if along_x else Vector3(0, 0, rd * t)), top + 0.1, rng, b)


static var _roosts: Array = []  # [where, basis]: where the pigeons sit, built after the houses


static func _roost(at: Vector3, top: float, rng: RandomNumberGenerator, b: Basis = Basis.IDENTITY) -> void:
	_roosts.append([Vector3(at.x, top, at.z), b, rng.randi_range(1, 4)])


## Washing on a line from the house across the street to the house opposite, at storey height.
static func _washing(add: Callable, c: Vector3, b: Basis, w: float, d: float, h: float, street_w: float, rng: RandomNumberGenerator) -> void:
	var length := 2.0 * (street_w + 1.6) + 0.3
	var x := rng.randf_range(-w * 0.3, w * 0.3)
	var start := Vector3(c.x, 0, c.z) + b * Vector3(x, h, d / 2.0)
	add.call("box", "#4a3a2a", Transform3D(b.scaled_local(Vector3(0.03, 0.03, length)), start + b * Vector3(0, 0, length / 2.0)))
	var n := int(length / 0.95)
	for k in n:
		if rng.randf() < 0.25:
			continue
		var z := d / 2.0 + 0.5 + k * 0.95
		add.call("quad", "h_cloth", Transform3D((b * Basis(Vector3.UP, PI / 2.0)).scaled_local(Vector3(0.75, rng.randf_range(0.6, 1.0), 1.0)),
			Vector3(c.x, 0, c.z) + b * Vector3(x, h - 0.45, z)), TUNICS[rng.randi() % TUNICS.size()])


## The bays of a ground storey's face `s`: a shop (its bay in the house set, a counter of stone
## before it with pots on it, the shutters put up at night by urbs_life.gd), a door (its lamp
## beside it), or blank wall. Returns how many shops.
static func _bays(add: Callable, c: Vector3, b: Basis, w: float, d: float, y: float, s: float, kind: String, rng: RandomNumberGenerator,
		fallen: bool, late: bool, burnt: bool, doors: Array, age_id: String, side: bool = false) -> int:
	if side:  # the same along a side face: swap the axes, and fewer shops there
		var along := d
		var across := w
		var turned := b * Basis(Vector3.UP, PI / 2.0 * s)
		var cc := c
		return _bays(add, cc, turned, along, across, y, 1.0, "side" if kind != "row" else "row_side", rng, fallen, late, burnt, doors, age_id)
	var n := maxi(1, int(w / 3.6))
	var bw := w / n
	var shops := 0
	for k in n:
		var x := -w / 2.0 + (k + 0.5) * bw
		var roll := rng.randf()
		var shop: bool = kind == "row" or (roll < (0.6 if not kind.ends_with("side") else 0.2))
		var door: bool = not shop and roll < (0.8 if not kind.ends_with("side") else 0.45)
		if late and shop and rng.randf() < 0.35:  # a shop shut up for good
			add.call("quad", "h_shop_shut", _face(b, c, Vector3(x, y + 1.9 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(minf(bw - 0.3, 3.4), 3.7)))
			continue
		if shop and not fallen:
			shops += 1
			var trade: Array = _trade_for(age_id, rng)  # [job, picture]
			add.call("quad", "h_shop", _face(b, c, Vector3(x, y + 1.9 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(minf(bw - 0.3, 3.4), 3.7)))
			add.call("box", "travertine", Transform3D(b.scaled_local(Vector3(minf(bw - 1.2, 2.4), 0.95, 0.5)), Vector3(c.x, y + 0.47, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 0.25))))
			_wares(add, c, b, x, s, d, y, str(trade[1]) if not trade.is_empty() else "wine", rng)
			if rng.randf() < 0.6:
				_sign(add, c, b, w, d, y, s, rng, x, str(trade[1]) if not trade.is_empty() else "")
			if not trade.is_empty() and doors.size() < 1800:  # the shop's door, for its keeper (places_rome.gd)
				var at_shop := Vector3(c.x, 0, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 1.1))
				at_shop.y = ground(at_shop)
				doors.append([at_shop, atan2((b * Vector3(0, 0, s)).x, (b * Vector3(0, 0, s)).z), str(trade[0])])
			if rng.randf() < 0.22 and not late:  # a vine trained over the front on two poles
				var out_to := s * (d / 2.0 + 1.35)
				for px: float in [-bw * 0.4, bw * 0.4]:
					add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.12, 3.1, 0.12)), Vector3(c.x, y + 1.55, c.z) + b * Vector3(x + px, 0, out_to)))
				add.call("box", "wood", Transform3D(b.scaled_local(Vector3(bw * 0.8 + 0.2, 0.08, 0.08)), Vector3(c.x, y + 3.1, c.z) + b * Vector3(x, 0, out_to)))
				add.call("quad", "g_canopy", Transform3D((b * Basis(Vector3.RIGHT, -PI / 2.0)).scaled_local(Vector3(bw * 0.9, 1.5, 1.0)),
					Vector3(c.x, y + 3.25, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 0.7))))
		elif door or (shop and fallen):
			var which := "h_door" if roll < 0.72 else ("h_door_red" if roll < 0.76 else "h_door_green")
			if burnt:
				add.call("quad", "dark", _face(b, c, Vector3(x, y + 1.4 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(1.4, 2.8)))  # off its hinges
			else:
				add.call("quad", which, _face(b, c, Vector3(x, y + 1.4 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(1.5, 2.9)))
				add.call("box", "bronze", Transform3D(b.scaled_local(Vector3(0.12, 0.3, 0.2)), Vector3(c.x, y + 2.6, c.z) + b * Vector3(x + 1.0, 0, s * (d / 2.0 + 0.1))))  # the lamp
				if not fallen:
					_lamps.append(Vector3(c.x, y + 2.84, c.z) + b * Vector3(x + 1.0, 0, s * (d / 2.0 + 0.22)))
				add.call("box", "r_slab", Transform3D(b.scaled_local(Vector3(1.6, 0.07, 0.5)), Vector3(c.x, y + 0.035, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 0.25))))  # the threshold
				add.call("box", "#a8a094", Transform3D(b.scaled_local(Vector3(0.9, 0.075, 0.28)), Vector3(c.x, y + 0.036, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 0.25))))  # worn hollow by the feet
				if rng.randf() < 0.4:  # a bush of box or a rose in a pot by the door
					var pot := Vector3(c.x, y, c.z) + b * Vector3(x - 1.0, 0, s * (d / 2.0 + 0.45))
					add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.9, 0.55, 0.9)), pot + Vector3(0, 0.25, 0)))
					var potted := "g_flowers" if rng.randf() < 0.5 else "g_bush"
					add.call("quad", potted, _face(b, c, Vector3(x - 1.0, y + 0.85 - c.y, s * (d / 2.0 + 0.45)), s, Vector2(0.9, 0.8)))
					add.call("quad", potted, _face(b, c, Vector3(x - 1.0, y + 0.85 - c.y, s * (d / 2.0 + 0.45)), s, Vector2(0.9, 0.8), true))
			if rng.randf() < 0.4 and doors.size() < 900 and not fallen:
				var at_door := Vector3(c.x, 0, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 1.1))
				at_door.y = ground(at_door)
				doors.append([at_door, atan2((b * Vector3(0, 0, s)).x, (b * Vector3(0, 0, s)).z), ""])
		elif rng.randf() < 0.3:  # blank wall, a window low in it
			add.call("quad", "h_window_small", _face(b, c, Vector3(x, y + 2.6 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(0.8, 0.9)))
	return shops


## A trade for a shop of the age, drawn by weight from the trades whose job the age has: [job, picture].
static func _trade_for(age_id: String, rng: RandomNumberGenerator) -> Array:
	var key := "late" if age_id == "collapse" else age_id
	if not _trade_bags.has(key):
		var bag: Array = []
		for t: Array in TRADES:
			var j: Dictionary = Citizen.job(str(t[0]))
			if j.is_empty() or not (j.get("ages", []) as Array).has(key):
				continue
			for k in int(t[2]):
				bag.append([t[0], t[1]])
		_trade_bags[key] = bag
	var bag: Array = _trade_bags[key]
	return bag[rng.randi() % bag.size()] if not bag.is_empty() else []


## The wares of a trade set out on its counter (and, for the butcher, hung from the lintel): loaves,
## jars and cups, joints and a cleaver, tools on an anvil, shoes, bolts of cloth, the barber's shears,
## mirror and stool, the changer's scales and coins, rolls, pots, fish.
static func _wares(add: Callable, c: Vector3, b: Basis, x: float, s: float, d: float, y: float, picture: String, rng: RandomNumberGenerator) -> void:
	var top := y + 0.95
	var out := s * (d / 2.0 + 0.25)
	var at := func(dx: float, dy: float, dz: float = 0.0) -> Vector3:
		return Vector3(c.x, top + dy, c.z) + b * Vector3(x + dx, 0, out + s * dz)
	match picture:
		"bread":
			for k in rng.randi_range(3, 5):
				add.call("box", "#c8a060", Transform3D((b * Basis(Vector3.UP, rng.randf_range(-0.4, 0.4))).scaled_local(Vector3(0.28, 0.13, 0.2)), at.call(-0.8 + k * 0.4, 0.07, rng.randf_range(-0.1, 0.1))))
		"wine":
			for k in rng.randi_range(2, 3):
				add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.6, 0.6, 0.6)), at.call(-0.6 + k * 0.6, 0.25)))
			add.call("disc", "#8a6a4a", Transform3D(b.scaled_local(Vector3(0.12, 0.09, 0.12)), at.call(0.9, 0.05)))
		"cup":
			add.call("disc", "iron", Transform3D(b.scaled_local(Vector3(0.45, 0.28, 0.45)), at.call(-0.5, 0.14)))  # the pot of stew
			for k in 3:
				add.call("disc", "#8a6a4a", Transform3D(b.scaled_local(Vector3(0.12, 0.1, 0.12)), at.call(0.2 + k * 0.3, 0.05, rng.randf_range(-0.1, 0.1))))
		"knife":
			add.call("box", "iron", Transform3D((b * Basis(Vector3.UP, 0.3)).scaled_local(Vector3(0.35, 0.03, 0.1)), at.call(0.4, 0.02)))  # the cleaver
			add.call("box", "#a03a2a", Transform3D(b.scaled_local(Vector3(0.4, 0.12, 0.25)), at.call(-0.5, 0.06)))  # a joint on the block
			for k in 2:  # joints hung from the lintel
				add.call("box", "#a03a2a", Transform3D(b.scaled_local(Vector3(0.18, 0.4, 0.14)), Vector3(c.x, y + 2.9, c.z) + b * Vector3(x - 0.9 + k * 0.5, 0, s * (d / 2.0 + 0.2))))
		"hammer":
			add.call("box", "iron", Transform3D(b.scaled_local(Vector3(0.5, 0.25, 0.22)), at.call(-0.5, 0.12)))  # a small anvil
			for k in 3:
				add.call("box", "iron", Transform3D((b * Basis(Vector3.UP, rng.randf_range(-0.5, 0.5))).scaled_local(Vector3(0.4, 0.04, 0.05)), at.call(0.3 + k * 0.25, 0.02)))
		"shoe":
			for k in 4:
				add.call("box", "#5a3a22", Transform3D((b * Basis(Vector3.UP, rng.randf_range(-0.3, 0.3))).scaled_local(Vector3(0.12, 0.09, 0.28)), at.call(-0.75 + k * 0.5, 0.05)))
		"cloth":
			for k in 3:
				add.call("box", TUNICS[(k * 2 + rng.randi() % 2) % TUNICS.size()].to_html(false).insert(0, "#"), Transform3D(b.scaled_local(Vector3(0.7, 0.12, 0.25)), at.call(-0.6 + k * 0.6, 0.06)))
		"shears":
			add.call("box", "iron", Transform3D((b * Basis(Vector3.UP, 0.6)).scaled_local(Vector3(0.28, 0.02, 0.08)), at.call(0.3, 0.02)))
			add.call("disc", "bronze", Transform3D(b.scaled_local(Vector3(0.16, 0.02, 0.16)), at.call(-0.4, 0.01)))  # the mirror
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.36, 0.45, 0.36)), Vector3(c.x, y + 0.22, c.z) + b * Vector3(x + 1.2, 0, s * (d / 2.0 + 0.9))))  # the stool on the pavement
		"scales":
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.05, 0.4, 0.05)), at.call(0.5, 0.2)))
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.6, 0.03, 0.03)), at.call(0.5, 0.4)))
			for dx: float in [0.2, 0.8]:
				add.call("disc", "bronze", Transform3D(b.scaled_local(Vector3(0.14, 0.02, 0.14)), at.call(dx, 0.2)))
			for k in 4:
				add.call("disc", "bronze", Transform3D(b.scaled_local(Vector3(0.06, 0.05, 0.06)), at.call(-0.8 + k * 0.18, 0.025)))
		"roll":
			for k in 4:
				add.call("box", "parchment", Transform3D(b.scaled_local(Vector3(0.26, 0.05, 0.05)), at.call(-0.7 + k * 0.4, 0.03, rng.randf_range(-0.12, 0.12))))
		"pot":
			for k in 2:
				add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.5, 0.5, 0.5)), at.call(-0.7 + k * 0.5, 0.2)))
			for k in 2:
				add.call("disc", "terracotta", Transform3D(b.scaled_local(Vector3(0.24, 0.2, 0.24)), at.call(0.3 + k * 0.45, 0.1)))
		"fish":
			for k in 5:
				add.call("box", "#8a9aa8", Transform3D((b * Basis(Vector3.UP, rng.randf_range(-0.6, 0.6))).scaled_local(Vector3(0.36, 0.05, 0.11)), at.call(-0.8 + k * 0.4, 0.03, rng.randf_range(-0.12, 0.12))))
		_:
			for j in rng.randi_range(1, 3):
				add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.6, 0.6, 0.6)), at.call(rng.randf_range(-0.8, 0.8), 0.25)))


## A shop's sign: a painted board hung out over the pavement from an iron bracket, edge-on to the
## front so it reads from along the street both ways, with what the shop sells painted on it, the
## Romans' way (a wine jar, a loaf, a knife, a shoe, a bolt of cloth, a pot, a fish).
static func _sign(add: Callable, c: Vector3, b: Basis, w: float, d: float, y: float, s: float, rng: RandomNumberGenerator, x: float = NAN,
		picture: String = "") -> void:
	if is_nan(x):
		x = rng.randf_range(-w * 0.35, w * 0.35)
	var trade: String = picture if picture != "" else Houses.SIGNS[rng.randi() % Houses.SIGNS.size()]
	var base := Vector3(c.x, y, c.z)
	var out := s * (d / 2.0 + 0.7)  # the board's middle, out from the wall
	add.call("box", "iron", Transform3D(b.scaled_local(Vector3(0.05, 0.05, 1.3)), base + b * Vector3(x, 4.35, s * (d / 2.0 + 0.65))))  # the bracket's arm
	add.call("box", "iron", Transform3D((b * Basis(Vector3.RIGHT, -0.36 * s)).scaled_local(Vector3(0.04, 0.04, 1.28)), base + b * Vector3(x, 4.12, s * (d / 2.0 + 0.6))))  # its brace
	for hang: float in [0.3, 1.1]:  # the two hangers
		add.call("box", "iron", Transform3D(b.scaled_local(Vector3(0.03, 0.1, 0.03)), base + b * Vector3(x, 4.32, s * (d / 2.0 + hang))))
	add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.05, 0.75, 1.0)), base + b * Vector3(x, 3.9, out)))  # the board's edges
	for side: float in [1.0, -1.0]:  # the picture on both faces
		add.call("quad", "h_sign_" + trade, _face(b, c, Vector3(x + side * 0.03, y + 3.9 - c.y, out), side, Vector2(1.0, 0.75), true))


## A window on a face: a quad of glass (a dark shutter by day, lamplight by night) facing out along
## the house's `s` side. `local` is from the house's centre.
static func _face(b: Basis, c: Vector3, local: Vector3, s: float, size: Vector2, side: bool = false) -> Transform3D:
	var turn := b * (Basis(Vector3.UP, PI / 2.0 * s) if side else (Basis.IDENTITY if s > 0.0 else Basis(Vector3.UP, PI)))
	return Transform3D(turn.scaled_local(Vector3(size.x, size.y, 1.0)), c + b * local)


## A storey's windows round a house, at height `h`: each its wooden frame and sill, the pane
## behind it (a dark shutter by day, lamplight by night), and on some the shutters open, a pot of
## flowers on the sill. `bricked`: the share of them bricked up (the late city).
static func _windows(add: Callable, c: Vector3, b: Basis, w: float, d: float, h: float, rng: RandomNumberGenerator, bricked: float = 0.0,
		lively: bool = true) -> void:
	var y := h - c.y
	for s: float in [1.0, -1.0]:
		var n := maxi(1, int(w / 3.2))
		for k in n:
			if rng.randf() < 0.15:
				continue
			var x := -w / 2.0 + (k + 0.5) * w / n
			_window(add, c, b, Vector3(x, y, s * (d / 2.0 + 0.03)), s, false, rng, bricked, lively)
		var m := maxi(1, int(d / 3.6))
		for k in m:
			if rng.randf() < 0.3:
				continue
			var z := -d / 2.0 + (k + 0.5) * d / m
			_window(add, c, b, Vector3(s * (w / 2.0 + 0.03), y, z), s, true, rng, bricked, lively)


static func _window(add: Callable, c: Vector3, b: Basis, local: Vector3, s: float, side: bool, rng: RandomNumberGenerator, bricked: float,
		lively: bool) -> void:
	if rng.randf() < bricked:
		add.call("quad", "h_brick", _face(b, c, local, s, Vector2(1.0, 1.4), side))
		return
	var out := Vector3(0, 0, s * 0.015) if not side else Vector3(s * 0.015, 0, 0)  # a little proud of the wall
	add.call("quad", "glass", _face(b, c, local, s, Vector2(0.8, 1.1), side))
	add.call("quad", "h_window", _face(b, c, local + out, s, Vector2(1.05, 1.5), side))
	if not lively:
		return
	var roll := rng.randf()
	var turn := b * (Basis(Vector3.UP, PI / 2.0 * s) if side else (Basis.IDENTITY if s > 0.0 else Basis(Vector3.UP, PI)))
	if roll < 0.45:  # the shutters open, a leaf each side standing out from the wall
		for e: float in [-1.0, 1.0]:
			var hinge := c + b * local + turn * Vector3(e * 0.55, 0, 0)
			var leaf := turn * Basis(Vector3.UP, -e * 1.15)
			add.call("quad", "h_shutter", Transform3D(leaf.scaled_local(Vector3(0.5, 1.4, 1.0)), hinge + leaf * Vector3(e * 0.25, 0, 0)))
	if roll > 0.7:  # a pot of flowers on the sill
		var sill := c + b * local + turn * Vector3(rng.randf_range(-0.25, 0.25), -0.6, 0.2)
		add.call("box", "terracotta", Transform3D(turn.scaled_local(Vector3(0.3, 0.28, 0.3)), sill))
		add.call("box", "leaves", Transform3D(turn.scaled_local(Vector3(0.36, 0.22, 0.36)), sill + Vector3(0, 0.24, 0)))
		add.call("box", TUNICS[2 + rng.randi() % 3].to_html(false).insert(0, "#"), Transform3D(turn.scaled_local(Vector3(0.18, 0.1, 0.18)), sill + Vector3(0, 0.38, 0)))


## A house of the early city: one or two storeys of tufa blocks, or plaster over a timber frame,
## under a wide-eaved roof of tiles or thatch; a blank wall to the street with a door in it and a
## few small barred windows high up; a lean-to shed, a woodpile, a bench by the door; no shops.
static func _old_house(add: Callable, c: Vector3, b: Basis, w: float, d: float, floors: int, rng: RandomNumberGenerator, tint: Color,
		low: float, doors: Array, street_w: float = 0.0) -> void:
	var y := ground(c)
	var h := 4.2 if floors <= 1 else 7.2
	var tufa := rng.randf() < 0.55
	add.call("box", "h_tufa" if tufa else "h_timber", Transform3D(b.scaled_local(Vector3(w, y + h - low, d)), Vector3(c.x, (low + y + h) / 2.0, c.z)),
		Color.WHITE if tufa else tint)
	var thatch := rng.randf() < 0.35
	add.call("prism", "wicker" if thatch else "h_roof", Transform3D(b.scaled_local(Vector3(w + 1.8, 2.6 if thatch else 2.0, d + 1.8)), Vector3(c.x, y + h + (1.3 if thatch else 1.0), c.z)))
	if not thatch:
		_ridge(add, c, b, w + 1.8, d + 1.8, y + h + 2.0, rng)
	for s: float in [1.0, -1.0]:
		for k in 2:  # small windows, high, barred
			if rng.randf() < 0.4:
				continue
			add.call("quad", "h_window_small", _face(b, c, Vector3(-w * 0.25 + k * w * 0.5, y + h - 1.3 - c.y, s * (d / 2.0 + 0.04)), s, Vector2(0.7, 0.8)))
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var dx := rng.randf_range(-w * 0.3, w * 0.3)
	add.call("quad", "h_door", _face(b, c, Vector3(dx, y + 1.3 - c.y, side * (d / 2.0 + 0.04)), side, Vector2(1.3, 2.5)))
	if rng.randf() < 0.5:  # a bench by the door
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(1.4, 0.08, 0.4)), Vector3(c.x, y + 0.45, c.z) + b * Vector3(dx + 1.4, 0, side * (d / 2.0 + 0.3))))
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.08, 0.45, 0.35)), Vector3(c.x, y + 0.22, c.z) + b * Vector3(dx + 0.8, 0, side * (d / 2.0 + 0.3))))
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.08, 0.45, 0.35)), Vector3(c.x, y + 0.22, c.z) + b * Vector3(dx + 2.0, 0, side * (d / 2.0 + 0.3))))
	if rng.randf() < 0.4:  # a lean-to shed against one end, and the woodpile under it
		var e := 1.0 if rng.randf() < 0.5 else -1.0
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(2.4, 2.2, d * 0.6)), Vector3(c.x, y + 1.1, c.z) + b * Vector3(e * (w / 2.0 + 1.2), 0, 0)))
		add.call("box", "wicker", Transform3D((b * Basis(Vector3(0, 0, 1), -e * 0.35)).scaled_local(Vector3(3.0, 0.15, d * 0.65)), Vector3(c.x, y + 2.5, c.z) + b * Vector3(e * (w / 2.0 + 1.3), 0, 0)))
		for k in 5:
			add.call("box", "trunk", Transform3D((b * Basis(Vector3.UP, PI / 2.0)).scaled_local(Vector3(0.9, 0.2, 0.2)), Vector3(c.x, y + 0.1 + (k / 3) * 0.2, c.z) + b * Vector3(e * (w / 2.0 + 2.6), 0, -0.4 + (k % 3) * 0.25)))
	if rng.randf() < 0.12:
		add.call("quad", "h_vine", _face(b, c, Vector3(rng.randf_range(-w * 0.4, w * 0.4), y + 2.2 - c.y, -side * (d / 2.0 + 0.05)), -side, Vector2(1.2, 4.0)))
	if rng.randf() < 0.3 and doors.size() < 900:
		var at_door := Vector3(c.x, 0, c.z) + b * Vector3(dx, 0, side * (d / 2.0 + 1.1))
		at_door.y = ground(at_door)
		doors.append([at_door, atan2((b * Vector3(0, 0, side)).x, (b * Vector3(0, 0, side)).z)])


## A field inside the wall in the early ages: a vegetable plot in rows, a vineyard on its posts, or
## a pasture behind a fence, and now and then the farmhouse among them.
static func _plot(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, palette: Array, trees: Array,
		doors: Array, far: bool) -> void:
	var y := ground(c)
	var roll := rng.randf()
	if roll < 0.2 and not far:  # the farmhouse, small, and its fig
		var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
		_old_house(add, c + b * Vector3(-w * 0.2, 0, 0), b, w * 0.5, d * 0.6, 1, rng, tint, y - 1.5, doors)
		trees.append([c + b * Vector3(w * 0.3, 0, d * 0.2), "round", 0.8, true])
		return
	if roll < 0.5:  # vegetables in rows
		add.call("box", "furrows", Transform3D(b.scaled_local(Vector3(w, 0.16, d)), Vector3(c.x, y + 0.02, c.z)))
		for k in int(d / 1.6):
			add.call("box", "leaves", Transform3D(b.scaled_local(Vector3(w * 0.9, 0.35, 0.5)), Vector3(c.x, y + 0.3, c.z) + b * Vector3(0, 0, -d / 2.0 + (k + 0.5) * 1.6)))
		return
	if roll < 0.75:  # a vineyard
		add.call("box", "earth", Transform3D(b.scaled_local(Vector3(w, 0.12, d)), Vector3(c.x, y + 0.02, c.z)))
		for k in int(w / 2.4):
			var x := -w / 2.0 + (k + 0.5) * 2.4
			for j in 3:
				add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.12, 1.8, 0.12)), Vector3(c.x, y + 0.9, c.z) + b * Vector3(x, 0, -d / 2.0 + 1.0 + j * (d - 2.0) / 2.0)))
			add.call("box", "leaves", Transform3D(b.scaled_local(Vector3(0.7, 1.2, d - 1.6)), Vector3(c.x, y + 1.4, c.z) + b * Vector3(x, 0, 0)))
		return
	add.call("box", "grass", Transform3D(b.scaled_local(Vector3(w, 0.12, d)), Vector3(c.x, y + 0.02, c.z)))  # pasture, fenced
	for s: float in [1.0, -1.0]:
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(w, 0.1, 0.1)), Vector3(c.x, y + 0.9, c.z) + b * Vector3(0, 0, s * d / 2.0)))
		for k in int(w / 3.0) + 1:
			add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.12, 1.1, 0.12)), Vector3(c.x, y + 0.55, c.z) + b * Vector3(-w / 2.0 + k * w / maxi(1, int(w / 3.0)), 0, s * d / 2.0)))
	if rng.randf() < 0.35:  # the pond the sheep drink at
		var pc := c + b * Vector3(rng.randf_range(-w * 0.25, w * 0.25), 0, rng.randf_range(-d * 0.25, d * 0.25))
		add.call("disc", "earth", Transform3D(Basis.IDENTITY.scaled_local(Vector3(4.6, 0.14, 4.6)), Vector3(pc.x, y + 0.05, pc.z)))
		add.call("disc", "water", Transform3D(Basis.IDENTITY.scaled_local(Vector3(3.4, 0.1, 3.4)), Vector3(pc.x, y + 0.12, pc.z)))
		for k in 6:
			var a := TAU * k / 6.0
			trees.append([pc + Vector3(cos(a) * 1.9, 0, sin(a) * 1.9), "reeds", rng.randf_range(0.6, 0.9), true])
	for k in rng.randi_range(2, 4):  # the sheep
		add.call("box", "#e0d8c8", Transform3D(b.scaled_local(Vector3(0.9, 0.5, 0.5)), Vector3(c.x, y + 0.45, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0, rng.randf_range(-d * 0.35, d * 0.35))))
	if rng.randf() < 0.5:
		trees.append([c + b * Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0, rng.randf_range(-d * 0.3, d * 0.3)), "round", rng.randf_range(0.7, 1.0), true])


## A house of the rich: two storeys of drafted stucco with a painted dado round a courtyard garden
## with its tree and its pool, tiled roofs on the four wings, a door with a porch to the street and
## a lamp by it; few windows, and those high and small.
static func _domus(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, palette: Array, trees: Array) -> void:
	var y := ground(c)
	var low := y - 1.5
	var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
	var t := 3.6  # a wing's depth
	var h := 7.0
	var wings := [[Vector3(0, 0, d / 2.0 - t / 2.0), Vector3(w, 0, t)], [Vector3(0, 0, -d / 2.0 + t / 2.0), Vector3(w, 0, t)],
		[Vector3(w / 2.0 - t / 2.0, 0, 0), Vector3(t, 0, d - 2.0 * t)], [Vector3(-w / 2.0 + t / 2.0, 0, 0), Vector3(t, 0, d - 2.0 * t)]]
	for wing: Array in wings:
		var q: Vector3 = c + b * (wing[0] as Vector3)
		var size: Vector3 = wing[1]
		add.call("box", "h_stucco", Transform3D(b.scaled_local(Vector3(size.x, y + h - low, size.z)), Vector3(q.x, (low + y + h) / 2.0, q.z)), tint)
		add.call("box", "#8a3a2a", Transform3D(b.scaled_local(Vector3(size.x + 0.04, 1.3, size.z + 0.04)), Vector3(q.x, y + 0.65, q.z)))  # the painted dado
		add.call("box", "#c8a060", Transform3D(b.scaled_local(Vector3(size.x + 0.04, 0.2, size.z + 0.04)), Vector3(q.x, y + 1.4, q.z)))  # and its band
		add.call("prism", "h_roof", Transform3D(b.scaled_local(Vector3(size.x + 0.6, 1.8, size.z + 0.6)) if size.x > size.z else
			(b * Basis(Vector3.UP, PI / 2.0)).scaled_local(Vector3(size.z + 0.6, 1.8, size.x + 0.6)), Vector3(q.x, y + h + 0.9, q.z)))
	add.call("box", "g_turf", Transform3D(b.scaled_local(Vector3(w - 2.0 * t - 1.6, 0.3, d - 2.0 * t - 1.6)), Vector3(c.x, y + 0.15, c.z)))  # the garden
	add.call("box", "water", Transform3D(b.scaled_local(Vector3(1.8, 0.1, 1.2)), Vector3(c.x, y + 0.32, c.z) + b * Vector3(-1.0, 0, 0)))
	trees.append([c + b * Vector3(1.2, 0, 0.5), "round" if rng.randf() < 0.6 else "cypress", 0.7, true])
	trees.append([c + b * Vector3(-1.4, 0, -1.2), "olive" if rng.randf() < 0.5 else "cypress", 0.6, true])
	for k in 3:
		trees.append([Vector3(c.x, y + 0.3, c.z) + b * Vector3(rng.randf_range(-1.8, 1.8), 0, rng.randf_range(-1.6, 1.6)), "flowers" if k < 2 else "bush", 0.6, true])
	_roost(c + b * Vector3(0, 0, d / 2.0 + 0.2), y + h + 1.8, rng, b)
	for s: float in [1.0, -1.0]:  # a few small windows high up
		for k in 2:
			add.call("quad", "h_window_small", _face(b, c, Vector3(-w * 0.25 + k * w * 0.5, 5.2 + y - c.y, s * (d / 2.0 + 0.04)), s, Vector2(0.7, 0.9)))
	add.call("quad", "h_door_red" if rng.randf() < 0.5 else "h_door", _face(b, c, Vector3(0, y + 1.5 - c.y, d / 2.0 + 0.04), 1.0, Vector2(1.7, 3.0)))
	for x: float in [-1.3, 1.3]:  # the porch
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(0.2, 3.2, 0.2)), Vector3(c.x, y + 1.6, c.z) + b * Vector3(x, 0, d / 2.0 + 1.3)))
	add.call("box", "h_roof", Transform3D((b * Basis(Vector3.RIGHT, 0.3)).scaled_local(Vector3(3.4, 0.2, 1.8)), Vector3(c.x, y + 3.4, c.z) + b * Vector3(0, 0, d / 2.0 + 0.8)))
	add.call("box", "bronze", Transform3D(b.scaled_local(Vector3(0.12, 0.3, 0.2)), Vector3(c.x, y + 2.7, c.z) + b * Vector3(1.2, 0, d / 2.0 + 0.1)))  # the lamp


## A house far off, beyond where you walk: a plain block and its roof.
static func _far_house(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, palette: Array, republic: bool,
		old: bool = false) -> void:
	var y := ground(c)
	var h := rng.randf_range(6.0, 10.0) if republic else rng.randf_range(8.0, 20.0)
	if old:
		h = rng.randf_range(4.0, 6.5)
	var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
	add.call("box", "r_wall" if not old or rng.randf() < 0.5 else "tufa", Transform3D(b.scaled_local(Vector3(w, h + 1.0, d)), Vector3(c.x, y + h / 2.0 - 0.5, c.z)), tint)
	add.call("prism", "r_roof", Transform3D(b.scaled_local(Vector3(w + 0.8 + (1.0 if old else 0.0), 2.2, d + 0.8 + (1.0 if old else 0.0))), Vector3(c.x, y + h + 1.1, c.z)))


## A house fallen to ruin: broken walls without a roof, sometimes one wall still high, bushes and a
## tree growing in it, a vine over the broken brick. `hut`: someone lives in it, in a hut of wood
## and thatch inside the walls.
static func _ruin(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, trees: Array, hut: bool = false) -> void:
	var y := ground(c)
	if hut and rng.randf() < 0.5:
		var hp := c + b * Vector3(rng.randf_range(-w * 0.15, w * 0.15), 0, rng.randf_range(-d * 0.15, d * 0.15))
		add.call("box", "wood", Transform3D(b.scaled_local(Vector3(3.6, 2.4, 3.0)), Vector3(hp.x, y + 1.2, hp.z)))
		add.call("prism", "wicker", Transform3D(b.scaled_local(Vector3(4.2, 1.4, 3.6)), Vector3(hp.x, y + 3.1, hp.z)))
		add.call("quad", "h_door", Transform3D(b.scaled_local(Vector3(0.9, 1.7, 1.0)), Vector3(hp.x, y + 0.9, hp.z) + b * Vector3(0, 0, 1.52)))
	for wall: Array in [[Vector3(0, 0, d / 2.0), Vector3(w, 0, 0.8)], [Vector3(0, 0, -d / 2.0), Vector3(w, 0, 0.8)],
			[Vector3(w / 2.0, 0, 0), Vector3(0.8, 0, d)], [Vector3(-w / 2.0, 0, 0), Vector3(0.8, 0, d)]]:
		if rng.randf() < 0.25:
			continue
		var h := rng.randf_range(0.8, 4.5) if rng.randf() < 0.85 else rng.randf_range(6.0, 11.0)
		var q: Vector3 = c + b * (wall[0] as Vector3)
		var size: Vector3 = wall[1]
		add.call("box", "h_brick", Transform3D(b.scaled_local(Vector3(size.x, h + 1.0, size.z)), Vector3(q.x, y + h / 2.0 - 0.5, q.z)))
		if h > 3.0 and rng.randf() < 0.4:
			var along_x := size.x > size.z
			var s := 1.0 if rng.randf() < 0.5 else -1.0
			var local := (wall[0] as Vector3) + (Vector3(0, y + 1.8 - c.y, s * 0.42) if along_x else Vector3(s * 0.42, y + 1.8 - c.y, 0))
			add.call("quad", "h_vine", _face(b, c, local, s, Vector2(1.2, 3.4), not along_x))
	add.call("box", "rubble", Transform3D(b.scaled_local(Vector3(w * 0.8, 0.8, d * 0.6)), Vector3(c.x, y + 0.1, c.z)))
	if rng.randf() < 0.45:
		trees.append([c + b * Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-2, 2)), "bush" if rng.randf() < 0.6 else "round", rng.randf_range(0.6, 1.1), true])


## Draws all the houses' parts: one MultiMesh for each mesh and surface, each part its own colour.
## Returns the shop fronts' MultiMeshInstance (urbs_life.gd puts their shutters up at night), or null.
static func _draw(world: Node3D, parts: Dictionary) -> MultiMeshInstance3D:
	var shops: MultiMeshInstance3D = null
	for key: String in parts:
		var kind := key.split("|")[0]
		var mat := key.split("|")[1]
		var items: Array = parts[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		match kind:
			"prism":
				var pm := PrismMesh.new()
				pm.size = Vector3.ONE
				mm.mesh = pm
			"disc":
				var dm := CylinderMesh.new()
				dm.top_radius = 0.5
				dm.bottom_radius = 0.5
				dm.height = 1.0
				dm.radial_segments = 14
				dm.rings = 1
				mm.mesh = dm
			"quad":
				var q := QuadMesh.new()
				q.size = Vector2.ONE
				mm.mesh = q
			"amphora":
				var cm := CylinderMesh.new()
				cm.top_radius = 0.12
				cm.bottom_radius = 0.18
				cm.height = 0.9
				cm.radial_segments = 6
				cm.rings = 1
				mm.mesh = cm
			"rock":
				var sm := SphereMesh.new()
				sm.radius = 0.5
				sm.height = 1.0
				sm.radial_segments = 7
				sm.rings = 4
				mm.mesh = sm
			_:
				mm.mesh = BoxMesh.new()
		mm.instance_count = items.size()
		for k in items.size():
			mm.set_instance_transform(k, items[k][0])
			mm.set_instance_color(k, items[k][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Houses_%s_%s" % [kind, mat]
		mmi.multimesh = mm
		if mat == "glass":
			mmi.material_override = window_glass()
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			mmi.material_override = tinted(mat)
		if key == "quad|h_shop":
			shops = mmi
		world.add_child(mmi)
	return shops


## The city's trees and everything else that grows, all in a few MultiMeshes: each tree a trunk
## and two or three crossed quads of leaves (textures_green.gd), so a crown is a mass of leaves
## against the sky and not a green ball. Kinds: "pine" (the stone pine, a tall bare trunk and a
## flat crown), "cypress" (a dark spire), "round" (plane, fig, oak, laurel), "olive", "bush",
## "reeds", "grass" and "flowers" (tufts on the ground). [where, kind, size].
static func _trees(world: Node3D, trees: Array, fallen: bool) -> void:
	var trunks: Array = []
	var quads := {"g_crown": [], "g_pine": [], "g_cypress": [], "g_olive": [], "g_bush": [], "g_reeds": [], "g_grass": [], "g_flowers": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = 1723
	var cross := func(tex: String, at: Vector3, w: float, h: float, n: int) -> void:
		var yaw := rng.randf() * TAU
		for k in n:
			quads[tex].append(Transform3D(Basis(Vector3.UP, yaw + PI * k / n).scaled_local(Vector3(w, h, 1.0)), at))
	for t: Array in trees:
		var p: Vector3 = t[0]
		var kind: String = t[1]
		var s: float = t[2]
		var y := p.y if p.y > 0.5 else ground(p)
		var lean := Basis(Vector3(1, 0, 0), rng.randf_range(-0.05, 0.05)) * Basis(Vector3(0, 0, 1), rng.randf_range(-0.05, 0.05))
		match kind:
			"pine":
				trunks.append(Transform3D(lean.scaled_local(Vector3(0.7, 9.0, 0.7) * s), Vector3(p.x, y + 4.5 * s, p.z)))
				cross.call("g_pine", Vector3(p.x, y + 9.6 * s, p.z), 8.0 * s, 4.0 * s, 3)
			"cypress":
				trunks.append(Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.4, 1.0, 0.4) * s), Vector3(p.x, y + 0.5 * s, p.z)))
				cross.call("g_cypress", Vector3(p.x, y + 5.0 * s, p.z), 2.0 * s, 10.0 * s, 2)
			"olive":
				trunks.append(Transform3D(lean.scaled_local(Vector3(0.6, 2.4, 0.6) * s), Vector3(p.x, y + 1.2 * s, p.z)))
				cross.call("g_olive", Vector3(p.x, y + 3.6 * s, p.z), 4.6 * s, 3.4 * s, 3)
			"bush":
				cross.call("g_bush", Vector3(p.x, y + 0.8 * s, p.z), 2.4 * s, 1.6 * s, 2)
			"reeds":
				cross.call("g_reeds", Vector3(p.x, y + 0.9 * s, p.z), 1.8 * s, 1.8 * s, 2)
			"grass":
				cross.call("g_grass", Vector3(p.x, y + 0.35 * s, p.z), 1.1 * s, 0.7 * s, 2)
			"flowers":
				cross.call("g_flowers", Vector3(p.x, y + 0.4 * s, p.z), 1.1 * s, 0.8 * s, 2)
			_:
				trunks.append(Transform3D(lean.scaled_local(Vector3(0.6, 3.2, 0.6) * s), Vector3(p.x, y + 1.6 * s, p.z)))
				cross.call("g_olive" if fallen else "g_crown", Vector3(p.x, y + 4.5 * s, p.z), 5.4 * s, 4.6 * s, 3)
	var draw := func(xfs: Array, mesh: Mesh, mat: String, name: String, shadows: bool) -> void:
		if xfs.is_empty():
			return
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for k in xfs.size():
			mm.set_instance_transform(k, xfs[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = name
		mmi.multimesh = mm
		mmi.material_override = load("res://scripts/hall/textures.gd").material(mat)
		if not shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(mmi)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.4
	trunk.bottom_radius = 0.5
	trunk.height = 1.0
	trunk.radial_segments = 6
	trunk.rings = 1
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	draw.call(trunks, trunk, "g_bark", "TreeTrunks", true)
	draw.call(quads["g_pine"], quad, "g_pine", "TreePines", true)
	draw.call(quads["g_cypress"], quad, "g_cypress", "TreeCypresses", true)
	draw.call(quads["g_crown"], quad, "g_crown", "TreeCrowns", true)
	draw.call(quads["g_olive"], quad, "g_olive", "TreeOlives", true)
	draw.call(quads["g_bush"], quad, "g_bush", "Bushes", true)
	draw.call(quads["g_reeds"], quad, "g_reeds", "Reeds", false)
	draw.call(quads["g_grass"], quad, "g_grass", "Grass", false)
	draw.call(quads["g_flowers"], quad, "g_flowers", "Flowers", false)


## Puts `n` of `kind` down round `p`, within `spread` metres, each its own size.
static func _plant(trees: Array, rng: RandomNumberGenerator, p: Vector3, kind: String, n: int, spread: float, lo: float = 0.8, hi: float = 1.2) -> void:
	for k in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * spread
		trees.append([p + Vector3(cos(a) * d, 0, sin(a) * d), kind, rng.randf_range(lo, hi)])


static var _green := {}
static var _pools: Array = []  # the garden pools built this time, for the sound of them
static var _springs: Array = []  # and the groves' springs


## content/rome/green.json: the sacred groves, the woods on the hills, the orchards and the
## pleasure gardens, each with its years.
static func green_data() -> Dictionary:
	if _green.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/green.json"))
		_green = parsed if parsed is Dictionary else {"groves": []}
	return _green


## The waters besides the Tiber in `year` (green.json "waters"): ponds, marshes and lakes as
## [{at (world), r (world), kind, name}], streams as [{points (world), width (world), kind, name}].
static func waters(year: int) -> Array:
	var out: Array = []
	for w: Dictionary in green_data().get("waters", []):
		if w.has("from") and year < int(w["from"]):
			continue
		if w.has("until") and year >= int(w["until"]):
			continue
		if w.has("points"):
			out.append({"points": (w["points"] as Array).map(func(q: Array) -> Vector3: return at(q)), "width": span(float(w["width"])),
				"kind": "stream", "name": str(w.get("name", ""))})
		else:
			out.append({"at": at(w["at"]), "r": span(float(w["r"])), "kind": str(w["kind"]), "name": str(w.get("name", ""))})
	return out


## Lays the waters in: a pond, lake or marsh as a sheet of water in a bank of earth, reeds round
## its edge (and through a marsh), a stream as a ribbon of water in its bed between reeds. Dry
## once the city is emptied. Adds the reeds and bushes to `trees`, and the waters' edges to
## out["waters"] ([pos, "stream"]) for the sound of them.
static func _waters(world: Node3D, year: int, fallen: bool, trees: Array, rng: RandomNumberGenerator, out: Dictionary) -> void:
	var mat := "water" if not fallen else "drybed"
	for w: Dictionary in waters(year):
		if w["kind"] == "stream":
			var pts: Array = w["points"]
			var width: float = w["width"]
			var bed := ribbon(world, pts, width + 3.0, "earth", 0.03)
			bed.name = "StreamBed"
			var water := ribbon(world, pts, width, mat, 0.08)
			water.name = "Stream"
			for i in pts.size() - 1:
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[i + 1]
				var dir := (b - a).normalized()
				var across := Vector3(dir.z, 0, -dir.x)
				var t := 0.0
				while t < a.distance_to(b):
					var q := a + dir * t
					out["waters"].append([q, "stream"])
					for side: float in [-1.0, 1.0]:
						if rng.randf() < 0.8:
							trees.append([q + across * side * (width / 2.0 + rng.randf_range(0.3, 1.6)), "reeds", rng.randf_range(0.8, 1.3)])
						if rng.randf() < 0.15:
							trees.append([q + across * side * (width / 2.0 + rng.randf_range(2.5, 5.0)), "round" if rng.randf() < 0.6 else "bush", rng.randf_range(0.8, 1.2)])
					t += 5.0
			continue
		var c: Vector3 = w["at"]
		var r: float = w["r"]
		var y := ground(c)
		var bank := CylinderMesh.new()
		bank.top_radius = r + 2.5
		bank.bottom_radius = r + 3.0
		bank.height = 0.12
		bank.radial_segments = 24
		var bm := Kit.mesh(world, bank, "earth" if w["kind"] != "marsh" else "g_turf", Vector3(c.x, y + 0.02, c.z))
		bm.name = "Bank"
		var sheet := CylinderMesh.new()
		sheet.top_radius = r
		sheet.bottom_radius = r
		sheet.height = 0.1
		sheet.radial_segments = 24
		var wm := Kit.mesh(world, sheet, mat if w["kind"] != "marsh" or fallen else "marsh", Vector3(c.x, y + 0.1, c.z))
		wm.name = "Pond"
		var n := int(TAU * r / 2.2)
		for k in n:  # reeds round the edge
			var a := TAU * k / n + rng.randf_range(-0.1, 0.1)
			var d := r + rng.randf_range(-0.6, 1.2)
			if rng.randf() < 0.75:
				trees.append([c + Vector3(cos(a) * d, 0, sin(a) * d), "reeds", rng.randf_range(0.8, 1.3)])
			if k % 4 == 0:
				out["waters"].append([c + Vector3(cos(a) * r, 0, sin(a) * r), "stream"])
			if k % 6 == 0 and rng.randf() < 0.7:
				trees.append([c + Vector3(cos(a) * (r + 4.0), 0, sin(a) * (r + 4.0)), "round" if w["kind"] == "lake" else "bush", rng.randf_range(0.8, 1.2)])
		if w["kind"] == "marsh":  # reeds through it, and tussocks
			for k in int(r * r / 12.0):
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * r
				trees.append([c + Vector3(cos(a) * d, y + 0.12, sin(a) * d), "reeds" if rng.randf() < 0.7 else "grass", rng.randf_range(0.7, 1.2)])
		if w["kind"] == "lake" and not fallen:  # a quay of travertine on the near side, steps down to the water
			Kit.box(world, Vector3(c.x, y + 0.25, c.z + r + 1.0), Vector3(12.0, 0.5, 2.0), "travertine")


## The groves standing in `year`: [{at (world), r (world), kind, name}].
static func groves(year: int) -> Array:
	var out: Array = []
	for g: Dictionary in green_data().get("groves", []):
		if g.has("from") and year < int(g["from"]):
			continue
		if g.has("until") and year >= int(g["until"]):
			continue
		out.append({"at": at(g["at"]), "r": span(float(g["r"])), "kind": str(g["kind"]), "name": str(g.get("name", ""))})
	return out


## Plants one cell of a grove: oaks and a cypress in a sacred grove, pines and oaks thick in a
## wood, fruit trees in rows in an orchard, and in the pleasure gardens the whole set with
## flowers, box and a pergola now and then. `street_half` keeps the trees off a street the cell
## lies against.
static func _grove_cell(world: Node3D, trees: Array, rng: RandomNumberGenerator, p: Vector3, kind: String, far: bool, fallen: bool,
		add: Callable) -> void:
	var y := ground(p)
	match kind:
		"sacred":
			_plant(trees, rng, p, "round", 3, 6.0, 0.9, 1.4)
			if rng.randf() < 0.4:
				_plant(trees, rng, p, "cypress", 1, 5.0, 1.0, 1.3)
			if rng.randf() < 0.15 and not far and _occ.disc_free(p, 3.0, Occupancy.ALLOW_FURNITURE):  # the grove's spring, which runs whatever the aqueducts do
				Rome.spring(world, Vector3(p.x, y, p.z), true)
				_occ.paint_disc(p, 2.5, Occupancy.FURNITURE)
				_plant(trees, rng, p, "reeds", 4, 3.0)
				_springs.append(Vector3(p.x, y, p.z))
		"wood":
			_plant(trees, rng, p, "pine" if y > 8.0 or rng.randf() < 0.5 else "round", 3, 6.5, 0.9, 1.3)
			_plant(trees, rng, p, "round", 1, 6.0, 0.7, 1.0)
			_plant(trees, rng, p, "bush", 2, 6.0)
		"orchard":
			for i in 2:
				for j in 2:
					trees.append([p + Vector3(-3.5 + i * 7.0 + rng.randf_range(-0.5, 0.5), 0, -3.5 + j * 7.0 + rng.randf_range(-0.5, 0.5)),
						"olive" if rng.randf() < 0.6 else "round", rng.randf_range(0.7, 0.9)])
		_:  # horti
			if y < 4.0 and not fallen:
				add.call("box", "g_turf", Transform3D(Basis.IDENTITY.scaled_local(Vector3(14.0, 0.5, 14.0)), Vector3(p.x, y - 0.15, p.z)))
			if rng.randf() < 0.2 and not fallen and _occ.disc_free(p, 4.5, Occupancy.ALLOW_FURNITURE):  # a pool in its rim of travertine, with a jet in the middle of it
				var pb := Basis(Vector3.UP, rng.randf() * TAU)
				add.call("box", "travertine", Transform3D(pb.scaled_local(Vector3(7.0, 0.5, 5.0)), Vector3(p.x, y + 0.2, p.z)))
				add.call("box", "water", Transform3D(pb.scaled_local(Vector3(6.2, 0.12, 4.2)), Vector3(p.x, y + 0.42, p.z)))
				_occ.paint_box(Vector3(p.x, y, p.z), pb, 7.0, 5.0, Occupancy.FURNITURE, 0.5)
				if not far:
					Rome.jet(world, Vector3(p.x, y + 0.45, p.z), Vector3(0, 1, 0), 2.2, 14)
					_pools.append(Vector3(p.x, y, p.z))
			var roll := rng.randf()
			_plant(trees, rng, p, "pine" if roll < 0.35 else ("cypress" if roll < 0.6 else "round"), 2, 6.0, 0.9, 1.3)
			_plant(trees, rng, p, "olive", 1, 6.0, 0.8, 1.0)
			_plant(trees, rng, p, "bush", 2, 6.0, 0.8, 1.2)
			_plant(trees, rng, p, "flowers", 3, 6.5)
			if not far and rng.randf() < 0.14 and not fallen and _occ.disc_free(p, 4.5, Occupancy.ALLOW_FURNITURE):
				var pyaw := rng.randf() * TAU
				Rome.pergola(world, Vector3(p.x, y, p.z), pyaw, 6.0)
				_occ.paint_box(Vector3(p.x, y, p.z), Basis(Vector3.UP, pyaw), 6.4, 3.2, Occupancy.FURNITURE, 0.5)
	if not far:
		_plant(trees, rng, p, "grass", 3 if fallen else 4, 7.0, 0.8, 1.3)


## What grows on a hill, so the hills can be told apart from any street: stone pines on the ridges,
## cypresses on the Palatine, the fig and the plane in the valleys, and on the Capitol's face
## toward the Forum bare rock ("rock", drawn as an outcrop).
static func _hill_tree(p: Vector3, y: float, roll: float) -> String:
	var capitol := hill("Capitoline")
	var palatine := hill("Palatine")
	if y > 4.0 and Vector2(p.x - capitol[0].x, p.z - capitol[0].z).length() < capitol[1] * 1.3 and roll < 0.7:
		return "rock"
	if Vector2(p.x - palatine[0].x, p.z - palatine[0].z).length() < palatine[1] * 1.15 and roll < 0.65:
		return "cypress"
	if y > 8.0 and roll < 0.75:
		return "pine"
	if y > 4.0:
		return "pine" if roll < 0.45 else "round"
	return "round"


## The lanes between the blocks: along the bent grid, every third row and every third column, as
## polylines of world points (no height). Each stretch is laid only where its whole width is free
## of the map (a grove is no bar), so a lane never runs through a monument, a square, the water,
## the wall or a named street; where it meets a named street it opens into it, its end brought to
## the kerb. `named` are the named streets' stretches [a, b, half + 3].
static func _lanes(lo: Vector2, hi: Vector2, outer: Array, named: Array) -> Array:
	var out: Array = []
	var half := LANE / 2.0 + 0.5
	var ok := func(p: Vector3) -> bool:
		if not inside(outer, p):
			return false
		var k: int = _occ.kind_at(p)
		return k == Occupancy.FREE or k == Occupancy.GROVE
	var mouth := func(from: Vector3) -> Vector3:  # where a lane from `from` meets the kerb of the nearest street, or INF
		var r := _nearest_road(from, named)
		if int(r["k"]) < 0 or r["n"] == Vector3.ZERO:
			return Vector3.INF
		var m: Vector3 = (r["q"] as Vector3) + (r["n"] as Vector3) * (float(r["half"]) + 0.4)
		if m.distance_to(from) > PITCH * 1.5:
			return Vector3.INF
		if _occ.band_free(from, m, half, Occupancy.ALLOW_LANE | (1 << Occupancy.ROAD)):
			return m
		return Vector3.INF
	var lay := func(points: Array) -> void:  # one grid line's samples in order: cut into the runs that are free
		var run: Array = []
		var prev := Vector3.INF
		var prev_ok := false
		for p: Vector3 in points:
			var free: bool = ok.call(p)
			if free and prev_ok and _occ.band_free(prev, p, half, Occupancy.ALLOW_LANE):
				run.append(p)
			else:
				if run.size() >= 1:
					var end: Vector3 = mouth.call(run[-1])  # the run's end opened into the street it stopped at
					if end != Vector3.INF and _occ.kind_at(p) == Occupancy.ROAD:
						run.append(end)
					if run.size() > 1:
						out.append(run)
				run = []
				if free:
					run = [p]
					if prev_ok == false and prev != Vector3.INF and _occ.kind_at(prev) == Occupancy.ROAD:
						var start: Vector3 = mouth.call(p)  # the run begins at the street it comes from
						if start != Vector3.INF:
							run = [start, p]
			prev = p
			prev_ok = free
		if run.size() > 1:
			out.append(run)
	var rows := int((hi.y - lo.y) / PITCH) + 1
	var cols := int((hi.x - lo.x) / PITCH) + 1
	for j in range(0, rows, 3):  # along the rows
		var z0 := lo.y + j * PITCH - PITCH / 2.0
		var points: Array = []
		for i in cols + 1:
			var x := lo.x + i * PITCH - PITCH / 2.0
			var bend := _warp(x, z0)
			points.append(Vector3(x + bend.x, 0, z0 + bend.y))
		lay.call(points)
	for i in range(0, cols, 3):  # and the columns
		var x0 := lo.x + i * PITCH - PITCH / 2.0
		var points: Array = []
		for j in rows + 1:
			var z := lo.y + j * PITCH - PITCH / 2.0
			var bend := _warp(x0, z)
			points.append(Vector3(x0 + bend.x, 0, z + bend.y))
		lay.call(points)
	return out


## The street nearest a point: {k: its index in `roads`, d: how far, q: the nearest point on it,
## t: metres along its segment, dir: the segment's direction, n: the normal toward `p`, half: the
## street's half-width (the road entries carry half-width + 3)}.
static func _nearest_road(p: Vector3, roads: Array) -> Dictionary:
	var best := {"k": -1, "d": INF, "q": p, "t": 0.0, "dir": Vector3.ZERO, "n": Vector3.ZERO, "half": 0.0}
	for k in roads.size():
		var r: Array = roads[k]
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var ap := Vector2(p.x - a.x, p.z - a.z)
		var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		var q := Vector2(a.x, a.z) + ab * t
		var d := Vector2(p.x, p.z).distance_to(q)
		if d < float(best["d"]):
			var n := Vector2(p.x, p.z) - q
			if n.length() < 0.01:
				n = Vector2(-ab.y, ab.x)
			best = {"k": k, "d": d, "q": Vector3(q.x, 0, q.y), "t": t * ab.length(), "dir": Vector3(ab.x, 0, ab.y).normalized(),
				"n": Vector3(n.normalized().x, 0, n.normalized().y), "half": float(r[2]) - 3.0}
	return best


## How the grid of blocks is bent at a point: two slow waves each way, so streets wander and
## quarters lie at their own angles, as in a city that grew and was never planned.
static func _warp(x: float, z: float) -> Vector2:
	return Vector2(11.0 * sin(z * 0.021 + 0.7) + 6.0 * sin((x + z) * 0.013 + 2.1),
		11.0 * sin(x * 0.019 + 1.9) + 6.0 * sin((x - z) * 0.015 + 0.4))


static func hill_at(p: Vector3) -> bool:
	return ground(p) > 4.0


## Kept for the Rhetorica's place: the Republic's city round its zone.
static func city(world: Node3D, open_zone: String, whole: bool) -> void:
	var republic: Dictionary = ages()[0] if not ages().is_empty() else {"id": "republic", "year": -50}
	var copy := republic.duplicate()
	copy["year"] = -85  # the Rhetorica's own years
	fabric(world, copy, {"skip": outline(open_zone), "lost": not whole, "no_terrain": true})
