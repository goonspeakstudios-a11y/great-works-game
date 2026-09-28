extends RefCounted
## Ancient Rome as one city, laid out on Shepherd's plan of Republican Rome
## (content/rome/republican_rome.json), shrunk by the file's scale. The city opens a zone at a
## time: a zone is walked in, fenced round, while the rest of Rome stands about it to be seen and
## not yet entered (the hills, the Tiber and its island, the Servian wall and its gates, the Circus,
## the Capitol's temple, and roofs everywhere). The Rhetorica's place is the first zone, the Forum
## under the Palatine; when the Rome world is built its zones open round it on the same map.
## Map positions are real metres [east, north] of the Forum; world positions are game metres, with
## north toward -Z and the Forum at the world's origin.

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const FILE := "res://content/rome/republican_rome.json"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if parsed is Dictionary:
			_data = parsed
		else:
			push_error("republican_rome.json does not parse")
	return _data


## Where a map position (real metres east and north of the Forum) stands in the world.
static func at(p: Array) -> Vector3:
	var s: float = data().get("scale", 0.35)
	return Vector3(float(p[0]) * s, 0, -float(p[1]) * s)


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


## How high the ground stands at a world point: the hills are low domes.
static func ground(p: Vector3) -> float:
	var h := 0.0
	for hill: Dictionary in data().get("hills", []):
		var c := at(hill["at"])
		var r := span(hill["radius"])
		var d := Vector2(p.x - c.x, p.z - c.z).length()
		if d < r:
			h = maxf(h, span(hill["height"]) * sqrt(1.0 - (d / r) * (d / r)))
	return h


## The ground: a wide flat plain the zone is walked on, solid.
static func plain(world: Node3D, whole: bool) -> void:
	Kit.box(world, Vector3(0, -0.5, 0), Vector3(2400.0, 1.0, 2400.0), "earth" if whole else "ashbed", true)


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
			Kit.box(world, p + Vector3(0, 0.45, 0), Vector3(0.25, 0.9, 0.25), "marble", false)
		Kit.box(world, (a + b) / 2.0 + Vector3(0, 0.75, 0), Vector3(0.04, 0.04, length), "#8a2a2a", false,
			Vector3(0, Kit.face_yaw(a, b), 0))
	return pts


## The rest of Rome round an open zone, from the map: the hills, the Tiber and its island, the
## Servian wall with its gates, the Circus Maximus, the Temple of Jupiter on the Capitol, the Theatre
## of Pompey on the Campus Martius, and roofs across the city (none inside the open zone, where the
## place itself is built). `whole` is whether the place is back from being lost.
static func city(world: Node3D, open_zone: String, whole: bool) -> void:
	var d := data()
	var open := outline(open_zone)
	for hill: Dictionary in d.get("hills", []):
		Kit.hill(world, at(hill["at"]), span(hill["radius"]), span(hill["height"]), "grass" if whole else "ashbed")
	# the Tiber, and the island in it
	var course: Array = d["tiber"]["course"]
	for i in course.size() - 1:
		var a := at(course[i])
		var b := at(course[i + 1])
		Kit.box(world, (a + b) / 2.0 + Vector3(0, 0.05, 0), Vector3(span(d["tiber"]["width"]), 0.1, a.distance_to(b) + span(60)),
			"water" if whole else "drybed", false, Vector3(0, Kit.face_yaw(a, b), 0))
	var isle: Dictionary = d["tiber"]["island"]
	Kit.cylinder(world, at(isle["at"]), span(isle["radius"]), 0.4, "stone", false, 10)
	# the Servian wall and its gates
	var gates: Array = d["wall"]["gates"]
	var wall_h := span(d["wall"]["height"])
	for i in gates.size():
		var a := at(gates[i]["at"])
		var b := at(gates[(i + 1) % gates.size()]["at"])
		a.y = ground(a)
		b.y = ground(b)
		var mid := (a + b) / 2.0
		var gap := 6.0  # the gateway
		var length := maxf(0.0, Vector2(a.x - b.x, a.z - b.z).length() - gap)
		Kit.box(world, mid + Vector3(0, wall_h / 2.0, 0), Vector3(1.4, wall_h, length), "stone" if whole else "ashbed", false,
			Vector3(0, Kit.face_yaw(a, b), 0))
		for side: float in [-1.0, 1.0]:  # the towers either side of each gate
			var t := a + (b - a).normalized() * (gap / 2.0 + 1.0) * side
			Kit.box(world, Vector3(t.x, ground(t) + wall_h * 0.6, t.z), Vector3(2.6, wall_h * 1.2, 2.6), "stone", false)
	# the Circus Maximus, in the valley between the Palatine and the Aventine
	var cm: Dictionary = d["circus_maximus"]
	var axis := Vector3(float(cm["axis"][0]), 0, -float(cm["axis"][1])).normalized()
	var cc := at(cm["at"])
	var cy := atan2(axis.x, axis.z)
	Kit.box(world, cc + Vector3(0, 0.05, 0), Vector3(span(cm["width"]), 0.1, span(cm["length"])), "sand", false, Vector3(0, cy, 0))
	for side: float in [-1.0, 1.0]:  # the stands
		var off := Vector3(axis.z, 0, -axis.x) * span(cm["width"]) * 0.55 * side
		Kit.box(world, cc + off + Vector3(0, 1.8, 0), Vector3(span(20), 3.6, span(cm["length"])), "stone", false, Vector3(0, cy, 0))
	Kit.box(world, cc + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, span(cm["length"]) * 0.6), "marble", false, Vector3(0, cy, 0))  # the spina
	# the Temple of Jupiter on the Capitol, the Theatre of Pompey on the Campus Martius
	var jupiter := landmark("temple_of_jupiter")
	Rome.temple(world, Vector3(jupiter.x, ground(jupiter) - 0.3, jupiter.z), PI * 0.8, whole)
	var pompey := landmark("theatre_of_pompey")
	Kit.cylinder(world, pompey, span(75), span(25), "stone", false, 14, span(70))
	# roofs across the city, inside the wall and a little outside it, never in the open zone
	var ring: Array = gates.map(func(g: Dictionary) -> Vector3: return at(g["at"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 753  # ab urbe condita
	var placed := 0
	for i in 2600:
		if placed >= 420:
			break
		var p := Vector3(rng.randf_range(-600.0, 520.0), 0, rng.randf_range(-640.0, 460.0))
		var within := inside(ring, p)
		if not within and rng.randf() > 0.12:
			continue
		if inside(open, p) or open.any(func(q: Vector3) -> bool: return Vector2(q.x - p.x, q.z - p.z).length() < 8.0):
			continue
		if _on_the_river(p) or _near_monument(p):
			continue
		var w := rng.randf_range(3.0, 7.0)
		var h := rng.randf_range(2.5, 7.0) if within else rng.randf_range(2.0, 3.5)
		var yaw := rng.randf() * TAU
		var y := ground(p)
		Kit.box(world, Vector3(p.x, y + h / 2.0, p.z), Vector3(w, h, w * rng.randf_range(0.7, 1.4)), "plaster" if whole else "ashbed", false,
			Vector3(0, yaw, 0))
		if whole:
			Kit.box(world, Vector3(p.x, y + h + 0.2, p.z), Vector3(w + 0.4, 0.4, w * 1.4 + 0.4), "roof", false, Vector3(0, yaw, 0))
		placed += 1


static func _on_the_river(p: Vector3) -> bool:
	var course: Array = data()["tiber"]["course"]
	var half := span(data()["tiber"]["width"]) * 0.8
	for i in course.size() - 1:
		var a := at(course[i])
		var b := at(course[i + 1])
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(p) < half:
			return true
	return false


static func _near_monument(p: Vector3) -> bool:
	var cm := at(data()["circus_maximus"]["at"])
	if cm.distance_to(p) < span(330):
		return true
	return landmark("temple_of_jupiter").distance_to(p) < 14.0 or landmark("theatre_of_pompey").distance_to(p) < span(90)
