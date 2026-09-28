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
const CELL := 6.0  # the ground's grid
const PITCH := 15.0  # one block of houses and its share of the streets round it

## How far round each kind of monument the houses keep back (world metres, at size 1).
const FOOTPRINT := {"temple": 16.0, "double_temple": 42.0, "round_temple": 8.0, "hall": 10.0, "curia": 14.0,
	"basilica": 30.0, "vaulted_hall": 32.0, "rostra": 8.0, "shrine": 5.0, "arch": 10.0, "column": 5.0, "markets": 36.0,
	"amphitheatre": 100.0, "colossus": 6.0, "fountain_cone": 9.0, "ludus": 24.0, "baths": 70.0, "palace": 62.0,
	"houses": 50.0, "circus": 118.0, "obelisk": 4.0, "open_circus": 55.0, "theatre": 42.0, "pantheon": 30.0,
	"stadium": 52.0, "altar": 10.0, "mausoleum": 30.0, "church": 50.0}

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
		else:
			push_error("city.json does not parse")
	return _city


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


## How high the ground stands at a world point: the hills rise gently enough to walk up, and the
## streets fall to the river between its quays; the island stands in the middle of it.
static func ground(p: Vector3) -> float:
	var h := 0.0
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
	for p: Vector3 in walkable():
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	lo -= Vector2(120, 120)
	hi += Vector2(120, 120)
	var cols := int((hi.x - lo.x) / CELL) + 1
	var rows := int((hi.y - lo.y) / CELL) + 1
	var heights := PackedFloat32Array()
	heights.resize(cols * rows)
	for j in rows:
		for i in cols:
			heights[j * cols + i] = ground(Vector3(lo.x + i * CELL, 0, lo.y + j * CELL))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	verts.resize(cols * rows)
	normals.resize(cols * rows)
	for j in rows:
		for i in cols:
			var k := j * cols + i
			verts[k] = Vector3(lo.x + i * CELL, heights[k], lo.y + j * CELL)
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
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var sheet := Kit.mesh(world, am, mat, Vector3.ZERO)
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
	terrain(world, "cobble" if whole else "rubble")


## A strip laid on the ground along a line of world points (a street, the river): `width` wide,
## `lift` above the ground (or at the fixed height `y` when given).
static func ribbon(world: Node3D, points: Array, width: float, mat: String, lift: float = 0.06, y: float = NAN) -> MeshInstance3D:
	var dense: Array = []
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var n := maxi(1, int(a.distance_to(b) / 4.0))
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
static func state(m: Dictionary, year: int) -> String:
	if year < int(m.get("from", -800)):
		return ""
	if m.has("gone") and year >= int(m["gone"]):
		return "gone"
	if m.has("ruin") and year >= int(m["ruin"]):
		return "ruin"
	return "whole"


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
## "stalls": spots for stalls along the streets, "fountains": spots of the street fountains}.
static func fabric(world: Node3D, age: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var c := city_data()
	var year := int(age.get("year", -50))
	var lost: bool = opts.get("lost", false)
	var fallen: bool = age.get("id", "") == "fall" or lost
	var skip: Array = opts.get("skip", [])
	var flicker: Array = []
	if not opts.get("no_terrain", false):
		terrain(world, "rubble" if fallen else str(age.get("ground", "cobble")))
	_river(world, year, fallen)
	var bridges := _bridges(world, year, fallen)
	_servian_wall(world, year, lost)
	_aurelian_wall(world, year)
	var streets: Array = []
	for r: Dictionary in c.get("roads", []):
		var pts: Array = (r["points"] as Array).map(func(p: Array) -> Vector3: return on_ground(p))
		ribbon(world, pts, float(r["width"]), "basalt")
		streets.append(pts)
	for a: Dictionary in c.get("aqueducts", []):
		if year < int(a["year"]):
			continue
		var from := on_ground(a["from"])
		var to := on_ground(a["to"])
		var base := Vector3(0, minf(from.y, to.y), 0)
		Rome.aqueduct(world, Vector3(from.x, base.y, from.z), Vector3(to.x, base.y, to.z), int(a.get("tiers", 1)), year < 537 and not lost)
	var standing: Array = []
	for m: Dictionary in c.get("monuments", []):
		var st := state(m, year)
		if st == "" or st == "gone":
			continue
		var where := on_ground(m["at"])
		if m["id"] == "aesculapius":
			where = Vector3(_isle().x, 0.4, _isle().z)
		if not skip.is_empty() and inside(skip, where):
			continue
		var yaw := facing(m, where)
		var light := Urbs.build(world, m, where, yaw, st == "whole" and not lost, span(1.0))
		if light:
			flicker.append(light)
		standing.append({"m": m, "at": where, "yaw": yaw, "state": st})
	var forum := at([0, 0])
	if skip.is_empty() or not inside(skip, forum):  # the Forum's paving of travertine slabs
		Kit.box(world, forum + Vector3(0, 0.03, 0), Vector3(70.0, 0.06, 30.0), "paving", false, Vector3(0, -0.617 + PI / 2.0, 0))
	var out := {"flicker": flicker, "monuments": standing, "streets": streets, "bridges": bridges, "stalls": [], "fountains": [],
		"clear": opts.get("clear", [])}
	if opts.get("blocks", true):
		_blocks(world, age, standing, streets, skip, lost, out)
	return out


## The Tiber: its water between the quays (low and brown once the city is emptied), round the
## island, and an unseen wall along each bank so you keep to the streets and the bridges.
static func _river(world: Node3D, year: int, fallen: bool) -> void:
	var course: Array = (data()["tiber"]["course"] as Array).map(func(p: Array) -> Vector3: return at(p))
	var mat := "water" if not fallen else "#4a4a3a"
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
		out.append([from, to, width])
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
	for i in gates.size():
		if year > 0 and i % 3 != 0:
			continue
		var a := on_ground(gates[i]["at"])
		var b := on_ground(gates[(i + 1) % gates.size()]["at"])
		var gap := 7.0
		var dir := (b - a)
		dir.y = 0.0
		var length := dir.length() - gap
		if length <= 0.0:
			continue
		var n := maxi(1, int(length / 10.0))
		for k in n:  # in lengths that step with the ground
			var p := a + dir.normalized() * (gap / 2.0 + length * (k + 0.5) / n)
			var h := wall_h if year < 0 else wall_h * 0.6
			Kit.box(world, Vector3(p.x, ground(p) + h / 2.0 - 1.0, p.z), Vector3(1.6, h + 2.0, length / n + 0.3), "tufa" if not lost else "rubble", true,
				Vector3(0, atan2(dir.x, dir.z), 0))
		for side: float in [1.0]:
			var t := a + dir.normalized() * (gap / 2.0 + 1.3) * side
			Kit.box(world, Vector3(t.x, ground(t) + wall_h * 0.7 - 1.0, t.z), Vector3(3.0, wall_h * 1.4 + 2.0, 3.0), "tufa")


## The edge of the city you walk in: before Aurelian, a line of boundary stones; from AD 275,
## his wall of brick with square towers, and a gate where each road leaves. Unseen walls hold you
## in either way.
static func _aurelian_wall(world: Node3D, year: int) -> void:
	var pts := walkable()
	var built := year >= int(city_data().get("aurelian_wall", {}).get("from", 275))
	var h := float(city_data().get("aurelian_wall", {}).get("height", 10))
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var dir := b - a
		var length := dir.length()
		var yaw := atan2(dir.x, dir.z)
		var n := maxi(1, int(length / 12.0))
		for k in n:
			var t := (k + 0.5) / n
			var p := a.lerp(b, t)
			var y := ground(p)
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0, 12.0, length / n + 0.4)
			Kit.solid(world, shape, Vector3(p.x, y + 5.0, p.z), Vector3(0, yaw, 0))
			if y < WATER:
				continue  # where the line crosses the river
			if built:
				Kit.box(world, Vector3(p.x, y + h / 2.0 - 1.0, p.z), Vector3(3.2, h + 2.0, length / n + 0.2), "brick", false, Vector3(0, yaw, 0))
				if k % 2 == 0:
					Kit.box(world, Vector3(p.x, y + h * 0.65 - 1.0, p.z) - Vector3(dir.z, 0, -dir.x).normalized() * 2.0,
						Vector3(5.0, h * 1.3 + 2.0, 5.0), "brick", false, Vector3(0, yaw, 0))
			elif k % 3 == 0:
				Kit.box(world, Vector3(p.x, y + 0.6, p.z), Vector3(0.5, 1.2, 0.5), "travertine", false)  # a boundary stone
		if built:  # the gate at the corner: two round towers
			for s: float in [-1.0, 1.0]:
				var q := a + dir.normalized() * 5.0 * s
				Kit.cylinder(world, Vector3(q.x, ground(q) - 1.0, q.z), 3.2, h * 1.4 + 1.0, "travertine", false, 10)


## The houses and flats: blocks on a crooked grid across the city, each turned a little to the
## lie of its quarter, so the streets between them run at odd angles and narrow into alleys; kept
## off the streets, the river, the open squares and the monuments. Drawn in a few MultiMeshes (one
## per surface) and each made solid. Shops open on the ground floors, with awnings and wares;
## balconies and fountains; on the hills, the lower houses of the rich. In the emptied city most
## of the blocks are broken walls without roofs, and people live only in the bend of the river.
static func _blocks(world: Node3D, age: Dictionary, standing: Array, streets: Array, skip: Array, lost: bool, out: Dictionary) -> void:
	var c := city_data()
	var year := int(age.get("year", -50))
	var fallen: bool = age.get("id", "") == "fall" or lost
	var republic := year < -30
	var rng := RandomNumberGenerator.new()
	rng.seed = 753 + year
	var edge := walkable()
	var clear: Array = out.get("clear", [])
	var servian: Array = (data()["wall"]["gates"] as Array).map(func(g: Dictionary) -> Vector3: return at(g["at"]))
	var opens: Array = []
	for o: Dictionary in c.get("open", []):
		if o.has("until") and year >= int(o["until"]):
			continue
		opens.append([at(o["at"]), span(float(o["r"]))])
	var keep_off: Array = standing.map(func(s: Dictionary) -> Array: return [s["at"], footprint(s["m"])])
	var roads: Array = []
	for r: Dictionary in c.get("roads", []):
		var pts: Array = r["points"]
		for i in pts.size() - 1:
			roads.append([at(pts[i]), at(pts[i + 1]), float(r["width"]) / 2.0 + 3.0])
	var ab: Dictionary = c.get("abitato", {})
	var abitato := at(ab.get("at", [-800, 450]))
	var abitato_r := span(float(ab.get("radius", 500)))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector3 in edge:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	var parts := {}  # [mesh kind, material] -> transforms
	var add := func(kind: String, mat: String, xf: Transform3D) -> void:
		var key := kind + "|" + mat
		if not parts.has(key):
			parts[key] = []
		parts[key].append(xf)
	var walls_rich := ["insula_white", "insula_ochre", "insula_rose"]
	var walls_old := ["insula_white", "insula_ochre", "tufa", "reticulatum"]
	var walls_new := ["insula", "insula", "insula", "insula_ochre", "insula_rose", "insula_white"]
	var taken := {}  # cells already covered by a long block from the cell before
	for j in int((hi.y - lo.y) / PITCH) + 1:
		for i in int((hi.x - lo.x) / PITCH) + 1:
			if taken.has(Vector2i(i, j)):
				continue
			var bx := lo.x + i * PITCH
			var bz := lo.y + j * PITCH
			var bend := _warp(bx, bz)  # the grid bends and twists, quarter by quarter
			var p := Vector3(bx + bend.x + rng.randf_range(-1.0, 1.0), 0, bz + bend.y + rng.randf_range(-1.0, 1.0))
			var roll := rng.randf()
			var roll2 := rng.randf()
			if not inside(edge, p):
				continue
			if clear.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < 16.0):
				continue
			if not skip.is_empty() and (inside(skip, p) or skip.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < 12.0)):
				continue
			if river_edge(p) < 9.0:
				continue
			if opens.any(func(o: Array) -> bool: return Vector2(p.x - o[0].x, p.z - o[0].z).length() < o[1]):
				continue
			if keep_off.any(func(o: Array) -> bool: return Vector2(p.x - o[0].x, p.z - o[0].z).length() < o[1]):
				continue
			if roads.any(func(r: Array) -> bool: return _to_segment(p, r[0], r[1]) < r[2] + 6.0):
				if roll < 0.5 and not fallen:
					out["stalls"].append(p)
				continue
			var in_old := inside(servian, p)
			var keep := 0.93
			if republic and not in_old:
				keep = 0.4
			if fallen and not lost:
				keep = 0.7 if p.distance_to(abitato) < abitato_r else 0.4
			if roll > keep:  # a little square: sometimes a fountain in it
				if roll2 < 0.35:
					out["fountains"].append(p)
				continue
			var y := ground(p)
			var hill := y > 4.0
			var along := _warp(bx + 1.0, bz) - bend  # which way the bent grid's rows run here
			var yaw := atan2(-along.y, 1.0 + along.x) + rng.randf_range(-0.03, 0.03)
			var w := rng.randf_range(9.0, 12.5)
			var d := rng.randf_range(9.0, 12.5)
			if rng.randf() < 0.22 and not hill_at(p):  # a long block over two cells, the alley between them built over
				taken[Vector2i(i + 1, j)] = true
				w += PITCH
				p += Basis(Vector3.UP, yaw) * Vector3(PITCH / 2.0, 0, 0)
			var floors := rng.randi_range(2, 4) if republic else rng.randi_range(3, 6)
			var mat: String = (walls_old if republic else walls_new)[rng.randi() % (walls_old if republic else walls_new).size()]
			if hill:  # the houses of the rich on the hills: lower, broader, plastered
				floors = 2
				w += 3.0
				d += 3.0
				mat = walls_rich[rng.randi() % walls_rich.size()]
			var ruin := false
			if fallen and not lost:
				ruin = p.distance_to(abitato) > abitato_r or roll2 < 0.3
				if not ruin:
					floors = rng.randi_range(1, 2)
					mat = "insula_white" if roll2 < 0.6 else "rubble"
			elif lost:
				ruin = true
			var h := floors * 4.0
			if ruin:
				h = rng.randf_range(0.8, 4.5)
				mat = "brick" if roll2 < 0.6 else "rubble"
			var low := minf(y, minf(ground(p + Vector3(w / 2.0, 0, d / 2.0)), ground(p - Vector3(w / 2.0, 0, d / 2.0)))) - 1.0
			var basis := Basis(Vector3.UP, yaw)
			var body_h := y + h - low
			add.call("box", mat, Transform3D(basis.scaled(Vector3(w, body_h, d)), Vector3(p.x, low + body_h / 2.0, p.z)))
			var shape := BoxShape3D.new()
			shape.size = Vector3(w, body_h, d)
			Kit.solid(world, shape, Vector3(p.x, low + body_h / 2.0, p.z), Vector3(0, yaw, 0))
			if ruin:
				if roll2 < 0.25:  # one wall still standing high
					add.call("box", mat, Transform3D(basis.scaled(Vector3(w, rng.randf_range(6.0, 12.0), 0.8)),
						Vector3(p.x, y, p.z) + basis * Vector3(0, 3.0, d / 2.0 - 0.4)))
				continue
			var top := y + h
			if hill or republic or roll2 < 0.55:  # a pitched roof of tiles
				add.call("prism", "roof", Transform3D(basis.scaled(Vector3(w + 0.8, 2.2, d + 0.8)), Vector3(p.x, top + 1.1, p.z)))
			else:  # a flat roof terrace with its parapet
				add.call("box", "roof", Transform3D(basis.scaled(Vector3(w + 0.4, 0.4, d + 0.4)), Vector3(p.x, top + 0.2, p.z)))
			if hill:
				continue
			for s: float in [1.0, -1.0]:  # the shops opening on the street on both long faces
				add.call("box", "#241a12", Transform3D(basis.scaled(Vector3(w * 0.8, 2.6, 0.1)), Vector3(p.x, y, p.z) + basis * Vector3(0, 1.3, s * (d / 2.0 + 0.03))))
				if rng.randf() < 0.35 and not fallen:  # an awning over them, and wares set out
					add.call("box", "awning", Transform3D(basis * Basis(Vector3.RIGHT, 0.35 * s).scaled(Vector3(w * 0.5, 0.06, 1.8)),
						Vector3(p.x, y, p.z) + basis * Vector3(rng.randf_range(-w * 0.2, w * 0.2), 3.0, s * (d / 2.0 + 0.9))))
					for k in rng.randi_range(2, 5):
						var at_shop := Vector3(p.x, y, p.z) + basis * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0, s * (d / 2.0 + rng.randf_range(0.5, 1.4)))
						if rng.randf() < 0.6:
							add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY, at_shop + Vector3(0, 0.45, 0)))
						else:
							add.call("box", "wood", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(0.7, 0.6, 0.7)), at_shop + Vector3(0, 0.3, 0)))
			if not republic and floors >= 3 and rng.randf() < 0.45 and not fallen:  # a wooden balcony on the second floor
				add.call("box", "wood", Transform3D(basis.scaled(Vector3(w * 0.7, 0.25, 1.2)), Vector3(p.x, y, p.z) + basis * Vector3(0, 4.2, d / 2.0 + 0.6)))
	for key: String in parts:
		var kind := key.split("|")[0]
		var mat := key.split("|")[1]
		var xfs: Array = parts[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		match kind:
			"prism":
				var pm := PrismMesh.new()
				pm.size = Vector3.ONE
				mm.mesh = pm
			"amphora":
				var cm := CylinderMesh.new()
				cm.top_radius = 0.12
				cm.bottom_radius = 0.18
				cm.height = 0.9
				cm.radial_segments = 6
				cm.rings = 1
				mm.mesh = cm
			_:
				mm.mesh = BoxMesh.new()
		mm.instance_count = xfs.size()
		for k in xfs.size():
			mm.set_instance_transform(k, xfs[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Blocks_" + kind
		mmi.multimesh = mm
		mmi.material_override = load("res://scripts/hall/textures.gd").material(mat)
		world.add_child(mmi)
	# the street fountains
	for f: Vector3 in out["fountains"]:
		Rome.fountain(world, Vector3(f.x, ground(f), f.z), rng.randf() * TAU, year < 537 and not lost)


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
