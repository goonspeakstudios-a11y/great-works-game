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

## How far round each kind of monument the houses keep back (world metres, at size 1).
const FOOTPRINT := {"temple": 16.0, "double_temple": 42.0, "round_temple": 8.0, "hall": 10.0, "curia": 14.0,
	"basilica": 30.0, "vaulted_hall": 32.0, "rostra": 8.0, "shrine": 5.0, "arch": 10.0, "column": 5.0, "markets": 36.0,
	"amphitheatre": 100.0, "colossus": 6.0, "fountain_cone": 9.0, "ludus": 24.0, "baths": 70.0, "palace": 62.0,
	"houses": 50.0, "circus": 118.0, "obelisk": 4.0, "open_circus": 55.0, "theatre": 42.0, "pantheon": 30.0,
	"stadium": 52.0, "altar": 10.0, "mausoleum": 30.0, "church": 50.0, "comitium": 12.0, "cloaca": 6.0, "beak_column": 3.0,
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
	_river(world, year, fallen)
	var bridges := _bridges(world, year, fallen)
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
		streets.append(pts)
	for a: Dictionary in c.get("aqueducts", []):
		if year < int(a["year"]):
			continue
		var from := on_ground(a["from"])
		var to := on_ground(a["to"])
		var base := Vector3(0, minf(from.y, to.y), 0)
		Rome.aqueduct(world, Vector3(from.x, base.y, from.z), Vector3(to.x, base.y, to.z), int(a.get("tiers", 1)), year < 537 and not lost)
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
		var light := Urbs.build(world, m, where, yaw, st == "whole" and not lost, span(1.0), year)
		if light:
			flicker.append(light)
		standing.append({"m": m, "at": where, "yaw": yaw, "state": st})
	var forum := at([0, 0])
	if skip.is_empty() or not inside(skip, forum):  # the Forum's paving of travertine slabs
		Kit.box(world, forum + Vector3(0, 0.03, 0), Vector3(70.0, 0.06, 30.0), "paving", false, Vector3(0, -0.617 + PI / 2.0, 0))
	var out := {"flicker": flicker, "monuments": standing, "streets": streets, "bridges": bridges, "stalls": [], "fountains": [],
		"clear": opts.get("clear", []), "doors": [], "banks": [], "flames": [], "compita": [], "tombs": []}
	if opts.get("blocks", true):
		_blocks(world, age, standing, streets, skip, lost, out)
		_compita(world, c, age_id, skip, out)
		_road_tombs(world, c, year, age_id, standing, skip, out)
		_corners(world, c, skip)
	return out


## The streets' names painted on the corners at their junctions (the Romans did not; you need them):
## a board on the wall a few paces along each street from the crossing, red letters on plaster.
static func _corners(world: Node3D, c: Dictionary, skip: Array) -> void:
	var edge := walkable()
	var widths := {}
	for r: Dictionary in c.get("roads", []):
		widths[str(r["name"])] = float(r["width"]) / 2.0 * span(1.0)
	for j: Dictionary in junctions(c):
		var p: Vector3 = j["at"]
		if not inside(edge, p) or (not skip.is_empty() and inside(skip, p)):
			continue
		for name: String in j["streets"]:
			var dir := _street_dir(c, name, p)
			if dir == Vector3.ZERO:
				continue
			var side := Vector3(dir.z, 0, -dir.x)
			var q := p + dir * 9.0 + side * (float(widths.get(name, 1.5)) + 0.4)
			q.y = ground(q) + 3.4
			var yaw := atan2(-side.x, -side.z)
			var g := Kit.group(world, q, yaw)
			Kit.box(g, Vector3(0, 0, -0.05), Vector3(3.6, 0.7, 0.08), "plaster", false)
			var label := Label3D.new()
			label.text = name.trim_prefix("the ").split(" and ")[0].to_upper()
			label.font = load("res://scripts/hall/lettering.gd").LAPIDARY  # the game's own capitals
			label.font_size = 48
			label.pixel_size = 0.0075
			label.modulate = Color("9a2a1a")
			label.outline_size = 0
			label.position = Vector3(0, 0, 0.01)
			g.add_child(label)


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
	var k := 0
	for j: Dictionary in junctions(c):
		k += 1
		if k % 2 == 0:
			continue
		var p: Vector3 = j["at"]
		if not inside(edge, p) or (not skip.is_empty() and inside(skip, p)):
			continue
		var q := p  # on the corner: of twelve spots round the crossing, the one farthest from any street
		var best := -1.0
		for s in 12:
			var a := TAU * (s + 0.5 * (k % 2)) / 12.0
			var cand := p + Vector3(cos(a), 0, sin(a)) * 7.0
			var off := INF
			for r: Dictionary in c.get("roads", []):
				var pts: Array = (r["points"] as Array).map(func(pp: Array) -> Vector3: return at(pp))
				for i in pts.size() - 1:
					off = minf(off, _to_segment(cand, pts[i], pts[i + 1]) - float(r["width"]) / 2.0)
			if off > best:
				best = off
				q = cand
		q.y = ground(q)
		var yaw := atan2(p.x - q.x, p.z - q.z)
		var g := Kit.group(world, q, yaw)
		g.name = "Compitum%d" % k
		Urbs.compitum(g, style)
		out["compita"].append({"at": q, "yaw": yaw, "streets": j["streets"], "style": style})


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
				Rome.tomb(g, Vector3.ZERO, 0.0, kind, whole)
				out["tombs"].append({"at": q, "yaw": g.rotation.y, "kind": kind, "road": str(r["name"])})
				n += 1
				if n > 90:
					return


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
static func tinted(kind: String) -> StandardMaterial3D:
	if not _tints.has(kind):
		var m: StandardMaterial3D = (load("res://scripts/hall/textures.gd").material(kind) as StandardMaterial3D).duplicate()
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
	var roads: Array = []
	for r: Dictionary in c.get("roads", []):
		var pts: Array = r["points"]
		for i in pts.size() - 1:
			roads.append([at(pts[i]), at(pts[i + 1]), float(r["width"]) / 2.0 + 3.0])
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
				roads.append([end, target, float(r["width"]) / 2.0 + 2.0, true])  # a corridor, not a street to line
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
	var add := func(kind: String, mat: String, xf: Transform3D, col: Color = Color.WHITE) -> void:
		var key := kind + "|" + mat
		if not parts.has(key):
			parts[key] = []
		parts[key].append([xf, col])
	var trees: Array = []  # [where, kind, size]
	var doors: Array = out.get("doors", [])
	var taken := {}
	var lined := {}  # road index -> [[metres along it, house width], ...]: the houses lined up on each street
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
			if not inside(outer, p):
				continue
			var far := not inside(edge, p)  # beyond where you walk: seen, not visited
			if far and roll < (0.35 if not old else 0.6):
				continue
			if clear.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < 16.0):
				continue
			if not skip.is_empty() and (inside(skip, p) or skip.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < 12.0)):
				continue
			if river_edge(p) < 9.0:
				if river_edge(p) > 4.0 and roll < 0.25:
					trees.append([p, "round" if roll2 < 0.5 else "pine", rng.randf_range(0.8, 1.2)])  # trees along the bank
				continue
			if opens.any(func(o: Array) -> bool: return Vector2(p.x - o[0].x, p.z - o[0].z).length() < o[1]):
				if roll < 0.08:
					trees.append([p, "round", rng.randf_range(0.8, 1.2)])
				continue
			if keep_off.any(func(o: Array) -> bool: return Vector2(p.x - o[0].x, p.z - o[0].z).length() < o[1]):
				if roll < 0.12:
					trees.append([p, "cypress", rng.randf_range(0.9, 1.2)])  # the sacred groves by the temples
				continue
			# a cell near a street is lined up along it, its front a step from the kerb, so the street
			# has walls (the road entries are [a, b, half-width + 3, corridor?]); a cell on the street
			# itself, or on a view corridor, is left open, with a stall now and then
			var street := _nearest_road(p, roads)
			var snapped := false
			var w := rng.randf_range(9.5, 12.5)
			var d := rng.randf_range(9.5, 12.5)
			var yaw := 0.0
			if float(street["d"]) < float(street["half"]) + 9.0:
				var k: int = street["k"]
				var half: float = street["half"]
				var t: float = street["t"]
				var room: bool = (roads[k] as Array).size() < 4 and float(street["d"]) >= half + 1.5
				if room:  # not on top of a house already lined up on this stretch
					for other: Array in lined.get(k, []):
						if absf(float(other[0]) - t) < (float(other[1]) + w) / 2.0 + 0.8:
							room = false
							break
				if not room:
					if roll < 0.5 and not fallen and not far and (roads[k] as Array).size() < 4:
						var stall: Vector3 = street["q"] + (street["n"] as Vector3) * (half + 1.2)
						out["stalls"].append(stall)
					continue
				if not lined.has(k):
					lined[k] = []
				lined[k].append([t, w])
				var dir: Vector3 = street["dir"]
				yaw = atan2(-(street["n"] as Vector3).x, -(street["n"] as Vector3).z)  # the house's front (+Z) toward the street
				p = (street["q"] as Vector3) + (street["n"] as Vector3) * (half + 1.6 + d / 2.0)
				snapped = true
				if dir == Vector3.ZERO:
					snapped = false
			var y := ground(p)
			var hill := y > 4.0
			var outer_hill := old and (hill or p.distance_to(forum) > 95.0) and inside(servian, p)  # the Esquiline, the Caelian, the Aventine's back
			var keep := 0.93
			if republic and not inside(servian, p):
				keep = 0.45 if not old else 0.25
			if hill:
				keep = 0.8
			if fallen and not lost:  # the emptied city: open ground, a few ruins, the huts by the river
				keep = 0.4 if p.distance_to(abitato) < abitato_r else 0.15
			if roll > keep:  # a little square: a fountain, a tree, or a garden on the hills
				var kind := _hill_tree(p, y, roll2)
				if fallen:
					if roll2 < 0.25:
						trees.append([p, "bush" if roll2 < 0.12 else kind, rng.randf_range(0.7, 1.2)])
				elif kind == "rock":  # the Capitol's bare face
					add.call("rock", "rock", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(rng.randf_range(3.0, 6.0), rng.randf_range(1.5, 3.0), rng.randf_range(3.0, 6.0))), Vector3(p.x, y + 0.2, p.z)))
				elif roll2 < 0.35 and not far and not hill:
					out["fountains"].append(p)
				elif roll2 < 0.8 or hill:
					trees.append([p, kind, rng.randf_range(0.8, 1.3)])
					if hill:
						trees.append([p + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)), "cypress" if kind == "cypress" or roll2 < 0.5 else "pine", rng.randf_range(0.8, 1.1)])
				continue
			if not snapped:
				var along := _warp(bx + 1.0, bz) - bend  # which way the bent grid's rows run here
				yaw = atan2(-along.y, 1.0 + along.x) + rng.randf_range(-0.03, 0.03)
			var basis := Basis(Vector3.UP, yaw)
			if outer_hill and roll2 < 0.66:  # fields inside the wall, a farmhouse among them
				if rng.randf() < 0.5 and not snapped:
					taken[Vector2i(i + 1, j)] = true
					w += PITCH
					p += basis * Vector3(PITCH / 2.0, 0, 0)
				_plot(add, p, basis, w, d, rng, palette, trees, doors, far)
				continue
			if rng.randf() < 0.22 and not hill and not old and not snapped:  # a long block over two cells, the alley between built over
				taken[Vector2i(i + 1, j)] = true
				w += PITCH
				p += basis * Vector3(PITCH / 2.0, 0, 0)
			var ruin: bool = lost or (fallen and (p.distance_to(abitato) > abitato_r or roll2 < 0.3))
			if not far:
				var shape := BoxShape3D.new()
				shape.size = Vector3(w, 14.0 if not ruin else 6.0, d)
				Kit.solid(world, shape, Vector3(p.x, ground(p) + 2.0, p.z), Vector3(0, yaw, 0))
			if ruin:
				_ruin(add, p, basis, w, d, rng, trees, fallen and not lost and p.distance_to(abitato) < abitato_r * 1.3)
				continue
			if far:
				_far_house(add, p, basis, w, d, rng, palette, republic, old)
				continue
			var near_river := river_edge(p) < 40.0
			if hill or (roll2 < 0.1 and not near_river):
				_domus(add, p, basis, w, d, rng, palette, trees)
				continue
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
				_house(add, centre, basis, lw - 0.3, d, floors, kind, rng, palette, republic, fallen, trees, doors, id)
	out["doors"] = doors
	out["burnt"] = _burnt.duplicate()
	_draw(world, parts)
	_trees(world, trees, fallen)
	# the street fountains, with a lamp on a post by each
	var flames := MultiMesh.new()
	flames.transform_format = MultiMesh.TRANSFORM_3D
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.16
	flame_mesh.height = 0.4
	flames.mesh = flame_mesh
	var fountains: Array = out["fountains"]
	flames.instance_count = fountains.size()
	for k in fountains.size():
		var f: Vector3 = fountains[k]
		var y := ground(f)
		Rome.fountain(world, Vector3(f.x, y, f.z), rng.randf() * TAU, year < 537 and not lost)
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


## One house of a block. `kind`: "insula" (flats over shops), "horreum" (a warehouse), "row" (a
## single storey of shops). The kit changes with the age (docs/rome-city-notes.md 2.1):
##   heroic, early: low houses of tufa blocks or plaster over timber, one or two storeys under wide
##     eaves of tiles or thatch, a blank wall to the street and a door in it, no shops;
##   republic: the first tall insulae, shops under the flats, balconies;
##   empire: brick-faced concrete, arcaded shops, up to six storeys, roof gardens;
##   late: the same blocks patched, windows bricked up, the tall ones half-empty;
##   collapse: roofs burnt to their beams, doors off, scaffolding no one finishes;
##   fall: what is left is a ruin (_ruin), with huts in it by the river.
static func _house(add: Callable, c: Vector3, b: Basis, w: float, d: float, floors: int, kind: String, rng: RandomNumberGenerator,
		palette: Array, republic: bool, fallen: bool, trees: Array, doors: Array, age_id: String = "republic") -> void:
	var y := ground(c)
	var low := minf(y, minf(ground(c + b * Vector3(w / 2.0, 0, d / 2.0)), ground(c - b * Vector3(w / 2.0, 0, d / 2.0)))) - 1.0
	var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
	var brick := not republic and rng.randf() < 0.35
	var old := age_id in ["heroic", "early"]
	var late := age_id == "late"
	var burnt := age_id == "collapse" and rng.randf() < 0.3
	if burnt:
		_burnt.append(Vector3(c.x, y + floors * 4.0, c.z))
	if old and kind != "horreum":
		_old_house(add, c, b, w, d, floors, rng, tint, low, doors)
		return
	if kind == "horreum":  # a warehouse: plain brick, a few small high windows, a flat roof
		var h := 8.0
		add.call("box", "r_brick", Transform3D(b.scaled(Vector3(w, y + h - low, d)), Vector3(c.x, (low + y + h) / 2.0, c.z)))
		add.call("box", "r_slab", Transform3D(b.scaled(Vector3(w + 0.3, 0.3, d + 0.3)), Vector3(c.x, y + h + 0.15, c.z)))
		for s: float in [1.0, -1.0]:
			for k in maxi(1, int(w / 4.0)):
				var x := -w / 2.0 + (k + 0.5) * w / maxi(1, int(w / 4.0))
				add.call("quad", "glass", _face(b, c, Vector3(x, y + 6.0 - c.y, s * (d / 2.0 + 0.03)), s, Vector2(0.6, 0.6)))
			add.call("box", "wood", Transform3D(b.scaled(Vector3(2.4, 3.2, 0.1)), Vector3(c.x, y, c.z) + b * Vector3(0, 1.6, s * (d / 2.0 + 0.04))))
		return
	var ground_h := 4.0
	# the ground storey: shops behind arches
	add.call("box", "r_shop", Transform3D(b.scaled(Vector3(w, y + ground_h - low, d)), Vector3(c.x, (low + y + ground_h) / 2.0, c.z)),
		Color.WHITE.lerp(tint, 0.25))
	var top := y + ground_h
	if kind == "row" or floors <= 1:  # a row of shops: a lean-to of tiles
		add.call("prism", "r_roof", Transform3D(b.scaled(Vector3(w + 0.6, 1.6, d + 0.8)), Vector3(c.x, top + 0.8, c.z)))
	else:
		var upper := (floors - 1) * 4.0
		var setback := floors >= 4 and rng.randf() < 0.35
		if setback:
			upper -= 4.0
		add.call("box", "r_brick" if brick else "r_wall", Transform3D(b.scaled(Vector3(w, upper, d)), Vector3(c.x, top + upper / 2.0, c.z)),
			Color.WHITE if brick else (tint if not burnt else tint.darkened(0.5)))
		if late or burnt:  # plaster patched over the brick, and windows bricked up
			for k in rng.randi_range(1, 3):
				var s := 1.0 if rng.randf() < 0.5 else -1.0
				add.call("quad", "r_brick", _face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), top + rng.randf_range(2.0, upper - 2.0) - c.y,
					s * (d / 2.0 + 0.04)), s, Vector2(rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 3.0))))
		for f in int(upper / 4.0):  # the windows, storey by storey
			_windows(add, c, b, w, d, top + f * 4.0 + 1.9, rng, 0.35 if late else (0.2 if burnt else 0.0))
		top += upper
		if burnt:  # the roof gone to its charred beams, the top storey open
			for k in maxi(2, int(w / 2.2)):
				add.call("box", "#2a2622", Transform3D(b.scaled(Vector3(0.25, 0.3, d + 0.6)), Vector3(c.x, top + 0.4, c.z) + b * Vector3(-w / 2.0 + (k + 0.5) * w / maxi(2, int(w / 2.2)), 0, 0)))
			add.call("box", "#2a2622", Transform3D(b.scaled(Vector3(w + 0.4, 0.2, 0.25)), Vector3(c.x, top + 0.4, c.z)))
			if rng.randf() < 0.4:  # scaffolding no one finishes
				var s := 1.0 if rng.randf() < 0.5 else -1.0
				for x: float in [-w * 0.3, 0.0, w * 0.3]:
					add.call("box", "wood", Transform3D(b.scaled(Vector3(0.18, top - y + 2.0, 0.18)), Vector3(c.x, (y + top + 2.0) / 2.0, c.z) + b * Vector3(x, 0, s * (d / 2.0 + 1.0))))
				add.call("box", "wood", Transform3D(b.scaled(Vector3(w * 0.7, 0.12, 1.2)), Vector3(c.x, top - 1.0, c.z) + b * Vector3(0, 0, s * (d / 2.0 + 0.7))))
			for s: float in [1.0, -1.0]:  # the door off its hinges
				add.call("quad", "dark", _face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), 1.6 + y - c.y, s * (d / 2.0 + 0.04)), s, Vector2(1.4, 2.8)))
			return
		if setback:  # a top storey set back, lighter, often timber-framed
			var tw := w - 1.8
			var td := d - 1.8
			var tint2 := Color("#" + str(palette[rng.randi() % palette.size()]))
			add.call("box", "r_wall", Transform3D(b.scaled(Vector3(tw, 3.4, td)), Vector3(c.x, top + 1.7, c.z)), tint2)
			_windows(add, c, b, tw, td, top + 1.6, rng)
			add.call("box", "r_slab", Transform3D(b.scaled(Vector3(w, 0.25, d)), Vector3(c.x, top + 0.12, c.z)))  # the terrace round it
			top += 3.4
		if rng.randf() < 0.6 or republic:  # a tiled roof
			add.call("prism", "r_roof", Transform3D(b.scaled(Vector3(w + 0.8 if not setback else w - 1.0, 2.2, d + 0.8 if not setback else d - 1.0)),
				Vector3(c.x, top + 1.1, c.z)))
		else:  # a roof terrace with its parapet, sometimes a garden and a pergola on it
			add.call("box", "r_slab", Transform3D(b.scaled(Vector3(w + 0.3, 0.3, d + 0.3)), Vector3(c.x, top + 0.15, c.z)))
			add.call("box", "r_wall", Transform3D(b.scaled(Vector3(w + 0.3, 0.8, 0.25)), Vector3(c.x, top, c.z) + b * Vector3(0, 0.55, d / 2.0)), tint)
			add.call("box", "r_wall", Transform3D(b.scaled(Vector3(w + 0.3, 0.8, 0.25)), Vector3(c.x, top, c.z) + b * Vector3(0, 0.55, -d / 2.0)), tint)
			if rng.randf() < 0.55 and not fallen:
				for k in rng.randi_range(2, 4):  # planters of box and myrtle, and a little tree in a pot
					var q := Vector3(c.x, top, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0.5, rng.randf_range(-d * 0.35, d * 0.35))
					add.call("box", "terracotta", Transform3D(b.scaled(Vector3(1.4, 0.6, 0.6)), q))
					add.call("box", "leaves", Transform3D(b.scaled(Vector3(1.3, 0.5, 0.5)), q + Vector3(0, 0.5, 0)))
				trees.append([Vector3(c.x, top + 0.3, c.z) + b * Vector3(w * 0.2, 0, 0), "round", 0.45])
				for x: float in [-1.0, 1.0]:  # the pergola's posts and beams, a vine over it
					for z: float in [-1.0, 1.0]:
						add.call("box", "wood", Transform3D(b.scaled(Vector3(0.15, 2.4, 0.15)), Vector3(c.x, top, c.z) + b * Vector3(x * w * 0.25 - w * 0.15, 1.2, z * d * 0.2)))
				add.call("box", "leaves", Transform3D(b.scaled(Vector3(w * 0.55, 0.25, d * 0.45)), Vector3(c.x, top, c.z) + b * Vector3(-w * 0.15, 2.5, 0)))
		if floors >= 3 and rng.randf() < 0.45 and not fallen:  # a wooden balcony along the second storey
			var s := 1.0 if rng.randf() < 0.5 else -1.0
			add.call("box", "wood", Transform3D(b.scaled(Vector3(w * 0.8, 0.2, 1.1)), Vector3(c.x, y, c.z) + b * Vector3(0, 8.0, s * (d / 2.0 + 0.55))))
			add.call("box", "wood", Transform3D(b.scaled(Vector3(w * 0.8, 0.8, 0.08)), Vector3(c.x, y, c.z) + b * Vector3(0, 8.5, s * (d / 2.0 + 1.08))))
			for k in 3:  # pots and washing on it
				add.call("box", "terracotta", Transform3D(Basis.IDENTITY.scaled(Vector3(0.35, 0.35, 0.35)),
					Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 8.3, s * (d / 2.0 + 0.8))))
			add.call("box", "awning", Transform3D(b.scaled(Vector3(w * 0.3, 0.9, 0.04)), Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.2, w * 0.2), 9.4, s * (d / 2.0 + 1.0))))
	for s: float in [1.0, -1.0]:  # before the shops: a step of slabs, an awning, wares, a door to keep
		if rng.randf() < 0.55:
			add.call("box", "r_slab", Transform3D(b.scaled(Vector3(w, 0.1, 1.5)), Vector3(c.x, y + 0.02, c.z) + b * Vector3(0, 0, s * (d / 2.0 + 0.75))))
		if fallen:
			continue
		if rng.randf() < (0.35 if age_id in ["republic", "empire"] else 0.15) and age_id not in ["heroic", "early"]:  # election notices and scratched words by the shop doors
			add.call("quad", "graffiti_" + (age_id if age_id in ["republic", "empire"] else "late"),
				_face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), 2.9 + y - c.y, s * (d / 2.0 + 0.05)), s, Vector2(1.6, 0.8)))
		if rng.randf() < 0.45:  # the shop's painted sign over its door: a jar, a loaf, a knife, a shoe
			_sign(add, c, b, w, d, y, s, rng)
		if late and rng.randf() < 0.4:  # a shop shut up for good
			add.call("quad", "r_brick", _face(b, c, Vector3(rng.randf_range(-w * 0.3, w * 0.3), 1.6 + y - c.y, s * (d / 2.0 + 0.05)), s, Vector2(2.2, 3.0)))
			continue
		if rng.randf() < (0.4 if not late else 0.2):
			add.call("box", "awning", Transform3D(b * Basis(Vector3.RIGHT, 0.35 * s).scaled(Vector3(w * 0.6, 0.06, 1.8)),
				Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.15, w * 0.15), 3.3, s * (d / 2.0 + 0.9))))
			for k in rng.randi_range(2, 5):
				var q := Vector3(c.x, y, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0, s * (d / 2.0 + rng.randf_range(0.5, 1.4)))
				if rng.randf() < 0.6:
					add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY, q + Vector3(0, 0.45, 0)))
				else:
					add.call("box", "wood", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(0.7, 0.6, 0.7)), q + Vector3(0, 0.3, 0)))
		if rng.randf() < 0.3 and doors.size() < 900:
			var at_door := Vector3(c.x, 0, c.z) + b * Vector3(rng.randf_range(-w * 0.25, w * 0.25), 0, s * (d / 2.0 + 1.1))
			at_door.y = ground(at_door)
			doors.append([at_door, atan2((b * Vector3(0, 0, s)).x, (b * Vector3(0, 0, s)).z)])


## A shop's sign on its front: a board hung out over the door with what the shop sells on it, the
## Romans' way (a wine jar, a loaf, a knife, a shoe, a bolt of cloth, a pot, a fish).
static func _sign(add: Callable, c: Vector3, b: Basis, w: float, d: float, y: float, s: float, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-w * 0.35, w * 0.35)
	var board := Vector3(c.x, y, c.z) + b * Vector3(x, 3.5, s * (d / 2.0 + 0.5))
	add.call("box", "wood", Transform3D(b.scaled(Vector3(1.1, 0.7, 0.06)), board))
	add.call("box", "wood", Transform3D(b.scaled(Vector3(0.06, 0.06, 0.9)), Vector3(c.x, y, c.z) + b * Vector3(x, 3.9, s * (d / 2.0 + 0.25))))
	var front := board + b * Vector3(0, 0, s * 0.06)
	match rng.randi() % 7:
		0:  # a wine jar
			add.call("amphora", "terracotta", Transform3D(Basis.IDENTITY.scaled(Vector3(0.5, 0.5, 0.3)), front))
		1:  # a loaf
			add.call("box", "#c8a060", Transform3D(b.scaled(Vector3(0.5, 0.28, 0.1)), front))
		2:  # a knife
			add.call("box", "iron", Transform3D((b * Basis(Vector3(0, 0, 1), 0.5)).scaled(Vector3(0.7, 0.1, 0.04)), front))
		3:  # a shoe
			add.call("box", "#5a3a22", Transform3D(b.scaled(Vector3(0.6, 0.18, 0.1)), front + b * Vector3(0, -0.1, 0)))
			add.call("box", "#5a3a22", Transform3D(b.scaled(Vector3(0.22, 0.3, 0.1)), front + b * Vector3(-0.19, 0.1, 0)))
		4:  # a bolt of cloth
			add.call("box", "#6a3a8a", Transform3D(b.scaled(Vector3(0.7, 0.35, 0.08)), front))
		5:  # a pot
			add.call("box", "terracotta", Transform3D(b.scaled(Vector3(0.4, 0.4, 0.1)), front))
		_:  # a fish
			add.call("box", "#8a9aa8", Transform3D(b.scaled(Vector3(0.7, 0.22, 0.06)), front))
			add.call("box", "#8a9aa8", Transform3D((b * Basis(Vector3(0, 0, 1), 0.8)).scaled(Vector3(0.22, 0.22, 0.06)), front + b * Vector3(0.4, 0, 0)))


## A window on a face: a quad of glass (a dark shutter by day, lamplight by night) facing out along
## the house's `s` side. `local` is from the house's centre.
static func _face(b: Basis, c: Vector3, local: Vector3, s: float, size: Vector2, side: bool = false) -> Transform3D:
	var turn := b * (Basis(Vector3.UP, PI / 2.0 * s) if side else (Basis.IDENTITY if s > 0.0 else Basis(Vector3.UP, PI)))
	return Transform3D(turn.scaled(Vector3(size.x, size.y, 1.0)), c + b * local)


## A storey's windows round a house, at height `h`: a few to each face, not all alike. `bricked`:
## the share of them bricked up (the late city).
static func _windows(add: Callable, c: Vector3, b: Basis, w: float, d: float, h: float, rng: RandomNumberGenerator, bricked: float = 0.0) -> void:
	var y := h - c.y
	for s: float in [1.0, -1.0]:
		var n := maxi(1, int(w / 3.2))
		for k in n:
			if rng.randf() < 0.15:
				continue
			var x := -w / 2.0 + (k + 0.5) * w / n
			add.call("quad", "glass" if rng.randf() >= bricked else "r_brick", _face(b, c, Vector3(x, y, s * (d / 2.0 + 0.03)), s, Vector2(0.9, 1.3)))
		var m := maxi(1, int(d / 3.6))
		for k in m:
			if rng.randf() < 0.3:
				continue
			var z := -d / 2.0 + (k + 0.5) * d / m
			add.call("quad", "glass" if rng.randf() >= bricked else "r_brick", _face(b, c, Vector3(s * (w / 2.0 + 0.03), y, z), s, Vector2(0.9, 1.3), true))


## A house of the early city: one or two storeys of tufa blocks, or plaster over a timber frame,
## under a wide-eaved roof of tiles or thatch; a blank wall to the street with a door in it and a
## few small windows high up; a lean-to shed; no shops.
static func _old_house(add: Callable, c: Vector3, b: Basis, w: float, d: float, floors: int, rng: RandomNumberGenerator, tint: Color,
		low: float, doors: Array) -> void:
	var y := ground(c)
	var h := 4.2 if floors <= 1 else 7.2
	var tufa := rng.randf() < 0.55
	add.call("box", "tufa" if tufa else "r_wall", Transform3D(b.scaled(Vector3(w, y + h - low, d)), Vector3(c.x, (low + y + h) / 2.0, c.z)),
		Color.WHITE if tufa else tint)
	if not tufa:  # the timbers showing through the plaster
		for s: float in [1.0, -1.0]:
			for k in maxi(2, int(w / 3.0)):
				add.call("quad", "wood", _face(b, c, Vector3(-w / 2.0 + (k + 0.5) * w / maxi(2, int(w / 3.0)), y + h / 2.0 - c.y, s * (d / 2.0 + 0.02)), s, Vector2(0.22, h - 0.4)))
	var thatch := rng.randf() < 0.35
	add.call("prism", "wicker" if thatch else "r_roof", Transform3D(b.scaled(Vector3(w + 1.8, 2.6 if thatch else 2.0, d + 1.8)), Vector3(c.x, y + h + (1.3 if thatch else 1.0), c.z)))
	for s: float in [1.0, -1.0]:
		for k in 2:  # small windows, high, shuttered
			if rng.randf() < 0.4:
				continue
			add.call("quad", "glass", _face(b, c, Vector3(-w * 0.25 + k * w * 0.5, y + h - 1.3 - c.y, s * (d / 2.0 + 0.03)), s, Vector2(0.6, 0.7)))
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	add.call("box", "wood", Transform3D(b.scaled(Vector3(1.3, 2.4, 0.12)), Vector3(c.x, y + 1.2, c.z) + b * Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0, side * (d / 2.0 + 0.05))))
	if rng.randf() < 0.4:  # a lean-to shed against one end
		var e := 1.0 if rng.randf() < 0.5 else -1.0
		add.call("box", "wood", Transform3D(b.scaled(Vector3(2.4, 2.2, d * 0.6)), Vector3(c.x, y + 1.1, c.z) + b * Vector3(e * (w / 2.0 + 1.2), 0, 0)))
		add.call("box", "wicker", Transform3D((b * Basis(Vector3(0, 0, 1), -e * 0.35)).scaled(Vector3(3.0, 0.15, d * 0.65)), Vector3(c.x, y + 2.5, c.z) + b * Vector3(e * (w / 2.0 + 1.3), 0, 0)))
	if rng.randf() < 0.3 and doors.size() < 900:
		var at_door := Vector3(c.x, 0, c.z) + b * Vector3(0, 0, side * (d / 2.0 + 1.1))
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
		trees.append([c + b * Vector3(w * 0.3, 0, d * 0.2), "round", 0.8])
		return
	if roll < 0.5:  # vegetables in rows
		add.call("box", "furrows", Transform3D(b.scaled(Vector3(w, 0.16, d)), Vector3(c.x, y + 0.02, c.z)))
		for k in int(d / 1.6):
			add.call("box", "leaves", Transform3D(b.scaled(Vector3(w * 0.9, 0.35, 0.5)), Vector3(c.x, y + 0.3, c.z) + b * Vector3(0, 0, -d / 2.0 + (k + 0.5) * 1.6)))
		return
	if roll < 0.75:  # a vineyard
		add.call("box", "earth", Transform3D(b.scaled(Vector3(w, 0.12, d)), Vector3(c.x, y + 0.02, c.z)))
		for k in int(w / 2.4):
			var x := -w / 2.0 + (k + 0.5) * 2.4
			for j in 3:
				add.call("box", "wood", Transform3D(b.scaled(Vector3(0.12, 1.8, 0.12)), Vector3(c.x, y + 0.9, c.z) + b * Vector3(x, 0, -d / 2.0 + 1.0 + j * (d - 2.0) / 2.0)))
			add.call("box", "leaves", Transform3D(b.scaled(Vector3(0.7, 1.2, d - 1.6)), Vector3(c.x, y + 1.4, c.z) + b * Vector3(x, 0, 0)))
		return
	add.call("box", "grass", Transform3D(b.scaled(Vector3(w, 0.12, d)), Vector3(c.x, y + 0.02, c.z)))  # pasture, fenced
	for s: float in [1.0, -1.0]:
		add.call("box", "wood", Transform3D(b.scaled(Vector3(w, 0.1, 0.1)), Vector3(c.x, y + 0.9, c.z) + b * Vector3(0, 0, s * d / 2.0)))
		for k in int(w / 3.0) + 1:
			add.call("box", "wood", Transform3D(b.scaled(Vector3(0.12, 1.1, 0.12)), Vector3(c.x, y + 0.55, c.z) + b * Vector3(-w / 2.0 + k * w / maxi(1, int(w / 3.0)), 0, s * d / 2.0)))
	for k in rng.randi_range(2, 4):  # the sheep
		add.call("box", "#e0d8c8", Transform3D(b.scaled(Vector3(0.9, 0.5, 0.5)), Vector3(c.x, y + 0.45, c.z) + b * Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0, rng.randf_range(-d * 0.35, d * 0.35))))
	if rng.randf() < 0.5:
		trees.append([c + b * Vector3(rng.randf_range(-w * 0.3, w * 0.3), 0, rng.randf_range(-d * 0.3, d * 0.3)), "round", rng.randf_range(0.7, 1.0)])


## A house of the rich: two storeys of blank plaster round a courtyard garden with its tree and its
## pool, tiled roofs on the four wings, a door with a porch to the street.
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
		add.call("box", "r_wall", Transform3D(b.scaled(Vector3(size.x, y + h - low, size.z)), Vector3(q.x, (low + y + h) / 2.0, q.z)), tint)
		add.call("prism", "r_roof", Transform3D(b.scaled(Vector3(size.x + 0.6, 1.8, size.z + 0.6)) if size.x > size.z else
			(b * Basis(Vector3.UP, PI / 2.0)).scaled(Vector3(size.z + 0.6, 1.8, size.x + 0.6)), Vector3(q.x, y + h + 0.9, q.z)))
	add.call("box", "leaves", Transform3D(b.scaled(Vector3(w - 2.0 * t - 1.6, 0.3, d - 2.0 * t - 1.6)), Vector3(c.x, y + 0.15, c.z)))  # the garden
	add.call("box", "water", Transform3D(b.scaled(Vector3(1.8, 0.1, 1.2)), Vector3(c.x, y + 0.32, c.z) + b * Vector3(-1.0, 0, 0)))
	trees.append([c + b * Vector3(1.2, 0, 0.5), "round" if rng.randf() < 0.6 else "cypress", 0.7])
	for s: float in [1.0, -1.0]:  # a few small windows high up, and the door
		for k in 2:
			add.call("quad", "glass", _face(b, c, Vector3(-w * 0.25 + k * w * 0.5, 5.2 + y - c.y, s * (d / 2.0 + 0.03)), s, Vector2(0.6, 0.8)))
	add.call("box", "wood", Transform3D(b.scaled(Vector3(1.6, 2.8, 0.12)), Vector3(c.x, y + 1.4, c.z) + b * Vector3(0, 0, d / 2.0 + 0.05)))


## A house far off, beyond where you walk: a plain block and its roof.
static func _far_house(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, palette: Array, republic: bool,
		old: bool = false) -> void:
	var y := ground(c)
	var h := rng.randf_range(6.0, 10.0) if republic else rng.randf_range(8.0, 20.0)
	if old:
		h = rng.randf_range(4.0, 6.5)
	var tint := Color("#" + str(palette[rng.randi() % palette.size()]))
	add.call("box", "r_wall" if not old or rng.randf() < 0.5 else "tufa", Transform3D(b.scaled(Vector3(w, h + 1.0, d)), Vector3(c.x, y + h / 2.0 - 0.5, c.z)), tint)
	add.call("prism", "r_roof", Transform3D(b.scaled(Vector3(w + 0.8 + (1.0 if old else 0.0), 2.2, d + 0.8 + (1.0 if old else 0.0))), Vector3(c.x, y + h + 1.1, c.z)))


## A house fallen to ruin: broken walls without a roof, sometimes one wall still high, bushes and a
## tree growing in it. `hut`: someone lives in it, in a hut of wood and thatch inside the walls.
static func _ruin(add: Callable, c: Vector3, b: Basis, w: float, d: float, rng: RandomNumberGenerator, trees: Array, hut: bool = false) -> void:
	var y := ground(c)
	if hut and rng.randf() < 0.5:
		var hp := c + b * Vector3(rng.randf_range(-w * 0.15, w * 0.15), 0, rng.randf_range(-d * 0.15, d * 0.15))
		add.call("box", "wood", Transform3D(b.scaled(Vector3(3.6, 2.4, 3.0)), Vector3(hp.x, y + 1.2, hp.z)))
		add.call("prism", "wicker", Transform3D(b.scaled(Vector3(4.2, 1.4, 3.6)), Vector3(hp.x, y + 3.1, hp.z)))
		add.call("quad", "dark", Transform3D(b.scaled(Vector3(0.9, 1.7, 1.0)), Vector3(hp.x, y + 0.9, hp.z) + b * Vector3(0, 0, 1.52)))
	for wall: Array in [[Vector3(0, 0, d / 2.0), Vector3(w, 0, 0.8)], [Vector3(0, 0, -d / 2.0), Vector3(w, 0, 0.8)],
			[Vector3(w / 2.0, 0, 0), Vector3(0.8, 0, d)], [Vector3(-w / 2.0, 0, 0), Vector3(0.8, 0, d)]]:
		if rng.randf() < 0.25:
			continue
		var h := rng.randf_range(0.8, 4.5) if rng.randf() < 0.85 else rng.randf_range(6.0, 11.0)
		var q: Vector3 = c + b * (wall[0] as Vector3)
		var size: Vector3 = wall[1]
		add.call("box", "r_brick", Transform3D(b.scaled(Vector3(size.x, h + 1.0, size.z)), Vector3(q.x, y + h / 2.0 - 0.5, q.z)))
	add.call("box", "rubble", Transform3D(b.scaled(Vector3(w * 0.8, 0.8, d * 0.6)), Vector3(c.x, y + 0.1, c.z)))
	if rng.randf() < 0.45:
		trees.append([c + b * Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-2, 2)), "bush" if rng.randf() < 0.6 else "round", rng.randf_range(0.6, 1.1)])


## Draws all the houses' parts: one MultiMesh for each mesh and surface, each part its own colour.
static func _draw(world: Node3D, parts: Dictionary) -> void:
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
		world.add_child(mmi)


## The city's trees, all in a few MultiMeshes: the stone pine (a tall bare trunk and a flat dark
## crown), the cypress (a dark spire), the round-headed plane, fig and laurel, and bushes in the
## ruins. [where, kind, size].
static func _trees(world: Node3D, trees: Array, fallen: bool) -> void:
	var trunks: Array = []
	var crowns := {"pine": [], "cypress": [], "round": [], "bush": []}
	for t: Array in trees:
		var p: Vector3 = t[0]
		var kind: String = t[1]
		var s: float = t[2]
		var y := p.y if p.y > 0.5 else ground(p)
		var lean := Basis(Vector3(1, 0, 0), randf_range(-0.05, 0.05))
		match kind:
			"pine":
				trunks.append(Transform3D(lean.scaled(Vector3(0.35, 9.0, 0.35) * s), Vector3(p.x, y + 4.5 * s, p.z)))
				crowns["pine"].append(Transform3D(Basis.IDENTITY.scaled(Vector3(6.5, 2.0, 6.5) * s), Vector3(p.x, y + 9.4 * s, p.z)))
			"cypress":
				trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.25, 1.5, 0.25) * s), Vector3(p.x, y + 0.75 * s, p.z)))
				crowns["cypress"].append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.6, 9.0, 1.6) * s), Vector3(p.x, y + 5.5 * s, p.z)))
			"bush":
				crowns["bush"].append(Transform3D(Basis.IDENTITY.scaled(Vector3(2.2, 1.4, 2.2) * s), Vector3(p.x, y + 0.5 * s, p.z)))
			_:
				trunks.append(Transform3D(lean.scaled(Vector3(0.3, 3.4, 0.3) * s), Vector3(p.x, y + 1.7 * s, p.z)))
				crowns["round"].append(Transform3D(Basis.IDENTITY.scaled(Vector3(4.6, 3.8, 4.6) * s), Vector3(p.x, y + 4.4 * s, p.z)))
	var draw := func(xfs: Array, mesh: Mesh, mat: String, name: String) -> void:
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
		world.add_child(mmi)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.4
	trunk.bottom_radius = 0.5
	trunk.height = 1.0
	trunk.radial_segments = 6
	trunk.rings = 1
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	ball.radial_segments = 10
	ball.rings = 5
	var spire := CylinderMesh.new()
	spire.top_radius = 0.05
	spire.bottom_radius = 0.5
	spire.height = 1.0
	spire.radial_segments = 8
	spire.rings = 2
	draw.call(trunks, trunk, "trunk", "TreeTrunks")
	draw.call(crowns["pine"], ball, "pine", "TreePines")
	draw.call(crowns["cypress"], spire, "cypress", "TreeCypresses")
	draw.call(crowns["round"], ball, "olive" if fallen else "leaves", "TreeCrowns")
	draw.call(crowns["bush"], ball, "leaves", "Bushes")


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
