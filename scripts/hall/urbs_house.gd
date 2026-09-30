extends RefCounted
## Your house in the city of Rome, in each age (content/rome/home.json, written from
## tools/rome_acts/home.py): an atrium house on the north side of the Argiletum, laid out on one
## floor plan (ROOMS, WALLS, DOORS), which builds the house in the world and draws its plan on the
## Plan panel. Its front, with two shops and the entrance, is toward the street (+Z).
##
## It changes with the ages: tufa and a hearth in the atrium in 280 BC; painted, mosaicked and
## mortgaged by 50 BC; marble and slaves by AD 150; doors bricked up in AD 384; looted and its roof
## holed in AD 455; roofless and broken in AD 552. Your wife and your household are in it (a wife in
## every age, each worse than the last, and then none), with the household gods, your bed, the
## strongbox, supper in the dining room, and the plan of the house on the tablinum wall.

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const FILE := "res://content/rome/home.json"
const HEIGHT := 3.4

## The rooms, as rectangles [x0, z0, x1, z1] in the house's own metres (x across, +z toward the street).
const ROOMS := {
	"shops": [-8.0, 8.0, 8.0, 12.0],
	"fauces": [-2.0, 8.0, 2.0, 12.0],
	"atrium": [-5.0, -2.0, 5.0, 8.0],
	"bedroom_children": [-8.0, 3.0, -5.0, 8.0],
	"bedroom_store": [5.0, 3.0, 8.0, 8.0],
	"ala": [-8.0, -2.0, -5.0, 3.0],
	"kitchen": [5.0, -2.0, 8.0, 3.0],
	"triclinium": [-8.0, -6.0, -2.5, -2.0],
	"tablinum": [-2.5, -6.0, 2.5, -2.0],
	"cubiculum": [2.5, -6.0, 8.0, -2.0],
	"garden": [-8.0, -12.0, 8.0, -6.0],
}
## What the plan calls each room.
const NAMES := {"shops": "shop", "fauces": "entrance", "atrium": "atrium", "bedroom_children": "children's room",
	"bedroom_store": "store", "ala": "wing (the gods)", "kitchen": "kitchen", "triclinium": "dining room", "tablinum": "tablinum",
	"cubiculum": "your bedroom", "garden": "garden"}
const IMPLUVIUM := [-1.2, 1.8, 1.2, 4.2]
## The walls, as segments [x0, z0, x1, z1]; the gaps between them are doorways.
const WALLS := [
	[-8.0, 12.0, -7.2, 12.0], [-2.8, 12.0, -1.0, 12.0], [1.0, 12.0, 2.8, 12.0], [7.2, 12.0, 8.0, 12.0],  # the street front
	[-8.0, -12.0, -8.0, 12.0], [8.0, -12.0, 8.0, 12.0], [-8.0, -12.0, 8.0, -12.0],  # sides and back
	[-8.0, 8.0, -2.0, 8.0], [2.0, 8.0, 8.0, 8.0], [-2.0, 8.0, -2.0, 12.0], [2.0, 8.0, 2.0, 12.0],  # shops and entrance
	[-5.0, 3.0, -5.0, 5.0], [-5.0, 6.2, -5.0, 8.0], [-8.0, 3.0, -5.0, 3.0],  # the children's room
	[5.0, 3.0, 5.0, 5.0], [5.0, 6.2, 5.0, 8.0], [5.0, 3.0, 8.0, 3.0],  # the store
	[5.0, -2.0, 5.0, 0.0], [5.0, 1.2, 5.0, 3.0],  # the kitchen
	[-8.0, -2.0, -4.5, -2.0], [-3.3, -2.0, -2.5, -2.0], [2.5, -2.0, 3.3, -2.0], [4.5, -2.0, 8.0, -2.0],  # the back rooms' fronts
	[-2.5, -6.0, -2.5, -2.0], [2.5, -6.0, 2.5, -2.0],
	[-8.0, -6.0, -1.0, -6.0], [1.0, -6.0, 8.0, -6.0],  # to the garden
]
## Doors that are bricked up in an age: [age, x0, z0, x1, z1].
const BRICKED := [["late", -1.0, -6.0, 1.0, -6.0], ["late", 2.5, -2.0, 4.5, -2.0],
	["heroic", -7.2, 12.0, -2.8, 12.0], ["heroic", 2.8, 12.0, 7.2, 12.0]]  # no shops yet in 280 BC: a blank wall to the street

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE)) if FileAccess.file_exists(FILE) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


static func wife(age: String) -> Dictionary:
	return data().get("wives", {}).get(age, {})


static func household(age: String) -> Array:
	return data().get("household", {}).get(age, [])


## What a room is like in an age (home.json "rooms"), or "".
static func room_note(room: String, age: String) -> String:
	var key: String = {"bedroom_children": "", "bedroom_store": "", "ala": "", "fauces": "", "shops": "shops"}.get(room, room)
	return str(data().get("rooms", {}).get(key, {}).get("notes", {}).get(age, ""))


static func walls_for(age: String) -> Array:
	var out: Array = WALLS.duplicate()
	for b: Array in BRICKED:
		if b[0] == age:
			out.append(b.slice(1))
	return out


## Builds the house at `at` (its centre, on the ground) facing `yaw` (its front to the street), and
## returns its interactables.
static func build(world: Node3D, age: String, at: Vector3, yaw: float) -> Array:
	var g := Kit.group(world, at, yaw)
	g.name = "YourHouse"
	var basis := Basis(Vector3.UP, yaw)
	var here := func(x: float, z: float) -> Vector3:
		var p := at + basis * Vector3(x, 0, z)
		p.y = at.y
		return p
	var rng := RandomNumberGenerator.new()
	rng.seed = 509 + AGES.find(age)
	var fallen := age == "fall"
	var looted := age == "collapse"
	var wall_mat: String = {"heroic": "tufa", "early": "tufa", "republic": "plaster", "empire": "fresco", "late": "plaster",
		"collapse": "plaster", "fall": "tufa"}.get(age, "plaster")
	var floor_mat: String = {"heroic": "r_dirt", "early": "r_dirt", "republic": "mosaic", "empire": "mosaic", "late": "mosaic",
		"collapse": "mosaic", "fall": "rubble"}.get(age, "r_dirt")
	# the floor, deep enough to meet the ground wherever it slopes
	Kit.box(g, Vector3(0, -0.3, 2.0), Vector3(16.2, 0.7, 20.2), floor_mat)
	Kit.box(g, Vector3(0, -0.3, -9.0), Vector3(16.2, 0.66, 6.0), "r_dirt")  # the garden's earth
	# the walls
	for w: Array in walls_for(age):
		var a := Vector2(float(w[0]), float(w[1]))
		var b := Vector2(float(w[2]), float(w[3]))
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var h := HEIGHT
		if fallen:
			if rng.randf() < 0.3:
				continue  # gone altogether
			h = rng.randf_range(0.6, 2.4)
		elif looted and rng.randf() < 0.1:
			h = rng.randf_range(1.8, 2.8)
		var mid := (a + b) / 2.0
		var along := (b - a).normalized()
		var size := Vector3(length + 0.3, h + 1.0, 0.3) if absf(along.x) > 0.5 else Vector3(0.3, h + 1.0, length + 0.3)
		Kit.box(g, Vector3(mid.x, h / 2.0 - 0.5, mid.y), size, wall_mat)
	# the roof over every room but the garden, round the opening over the pool
	if not fallen:
		for id: String in ROOMS:
			if id in ["garden", "atrium"]:
				continue
			if looted and id in ["triclinium", "cubiculum"]:
				continue  # fallen in
			_roof(g, ROOMS[id])
		var at_r: Array = ROOMS["atrium"]
		for part: Array in [[at_r[0], at_r[1], at_r[2], IMPLUVIUM[1]], [at_r[0], IMPLUVIUM[3], at_r[2], at_r[3]],
				[at_r[0], IMPLUVIUM[1], IMPLUVIUM[0], IMPLUVIUM[3]], [IMPLUVIUM[2], IMPLUVIUM[1], at_r[2], IMPLUVIUM[3]]]:
			_roof(g, part)
	# the pool under the opening
	var pool := Vector3((IMPLUVIUM[0] + IMPLUVIUM[2]) / 2.0, 0.06, (IMPLUVIUM[1] + IMPLUVIUM[3]) / 2.0)
	Kit.box(g, pool, Vector3(2.4, 0.12, 2.4), "marble" if age in ["republic", "empire", "late"] else "stone", false)
	Kit.box(g, pool + Vector3(0, 0.08, 0), Vector3(2.0, 0.04, 2.0),
		"water" if age in ["heroic", "early", "republic", "empire", "late"] else ("drybed" if looted else "rubble"), false)
	_furnish(g, age, rng)
	# the household gods in the wing, against the side wall
	Rome.lararium(g, Vector3(-7.6, 0, 0.5), PI / 2.0, not (fallen or looted))
	var out: Array = []
	var note := str(data().get("house", {}).get(age, ""))
	out.append({"kind": "activity", "pos": here.call(-6.0, 0.5), "scene": "lararium", "age_scene": true, "text": "Keep the household gods"})
	out.append({"kind": "activity", "pos": here.call(5.0, -4.6), "scene": "sleep", "age_scene": true,
		"text": "Sleep until morning" if not fallen else "Sleep in the corner where the roof still holds"})
	out.append({"kind": "chest", "pos": here.call(0.0, -4.8), "text": "Open the strongbox", "note": note})
	out.append({"kind": "activity", "pos": here.call(-1.4, -4.8), "scene": "purse", "age_scene": true, "text": "Look at the coin in your purse"})
	out.append({"kind": "plan", "pos": here.call(1.4, -5.2), "view": "house", "text": "Look at the plan of the house"})
	out.append({"kind": "activity", "pos": here.call(-5.2, -4.0), "scene": "cena", "age_scene": true,
		"text": "Sit down to supper with your family" if not fallen else "Stand in the empty dining room"})
	if age == "heroic":
		out.append({"kind": "activity", "pos": here.call(-3.0, 6.2), "scene": "bread", "age_scene": true, "rite": "bread",
			"text": "The bread: grind your grain and bake your bread"})
	for id: String in ROOMS:
		var n := room_note(id, age)
		if n == "" or id in ["tablinum"]:
			continue
		var r: Array = ROOMS[id]
		var c: Vector3 = here.call((r[0] + r[2]) / 2.0 + (1.5 if id == "atrium" else 0.0), (r[1] + r[3]) / 2.0 + (2.5 if id == "atrium" else 0.0))
		out.append({"kind": "look", "pos": c, "text": "Look at %s" % str(data()["rooms"][id if id != "shops" else "shops"]["name"]).to_lower(),
			"note": "[b]%s[/b], %s\n\n%s" % [data()["rooms"][id]["name"], _when(age), n]})
	# your wife, and the household
	var w := wife(age)
	if not w.is_empty():
		var wat: Array = w["where"]
		var who := _person(g, Vector3(float(wat[0]), 0, float(wat[1])), deg_to_rad(float(w.get("yaw", 0))), str(w["robe"]), "f",
			bool(w.get("jewel", false)), 1.0, rng)
		out.append({"kind": "wife", "pos": here.call(float(wat[0]), float(wat[1])), "follow": who["root"], "age": age,
			"text": "Talk to %s, your wife" % w["name"]})
	for h: Array in household(age):
		var kind := str(h[0])
		var hp := Vector3(float(h[3]), 0, float(h[4]))
		if kind == "dog":
			_dog(g, hp)
		else:
			_person(g, hp, rng.randf() * TAU, "8a7a68" if kind == "slave" else "b8a888", "m" if h[1] in ["Marcus", "Lucius", "Gaius", "the eunuch", "the steward"] else "f",
				false, 0.62 if kind == "child" else (0.9 if kind == "youth" else 1.0), rng)
		out.append({"kind": "person", "pos": here.call(hp.x, hp.z), "text": "Look at %s" % h[1], "note": str(h[2])})
	return out


const AGES := ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]


static func _when(age: String) -> String:
	return {"heroic": "280 BC", "early": "201 BC", "republic": "about 50 BC", "empire": "about AD 150", "late": "AD 384",
		"collapse": "AD 455", "fall": "AD 552"}.get(age, "")


static func _roof(g: Node3D, r: Array) -> void:
	var w := float(r[2]) - float(r[0])
	var d := float(r[3]) - float(r[1])
	var mid := Vector3((float(r[0]) + float(r[2])) / 2.0, HEIGHT, (float(r[1]) + float(r[3])) / 2.0)
	Kit.box(g, mid + Vector3(0, 0.16, 0), Vector3(w + 0.3, 0.14, d + 0.3), "r_roof", false)  # the tiles
	Kit.box(g, mid + Vector3(0, 0.04, 0), Vector3(w + 0.2, 0.08, d + 0.2), "wood", false)  # the ceiling under them


## The furniture of each age: the hearth and the loom, couches, the strongbox, the garden.
static func _furnish(g: Node3D, age: String, rng: RandomNumberGenerator) -> void:
	var old := age in ["heroic", "early"]
	var rich := age in ["republic", "empire", "late"]
	if age == "heroic":
		Kit.cylinder(g, Vector3(-3.0, 0, 5.4), 0.6, 0.35, "stone", true, 8)  # the hearth
		Kit.blob(g, Vector3(-3.0, 0.4, 5.4), 0.2, "fire", Vector3(1.0, 1.6, 1.0), 5)
		Kit.cylinder(g, Vector3(-1.6, 0, 6.4), 0.3, 0.45, "stone", true, 8)  # the quern
	if age in ["heroic", "early", "republic"]:  # the loom, upright, with its weights
		for x: float in [2.4, 4.0]:
			Kit.box(g, Vector3(x, 1.0, 6.8), Vector3(0.1, 2.0, 0.1), "wood", false)
		Kit.box(g, Vector3(3.2, 2.0, 6.8), Vector3(1.8, 0.1, 0.1), "wood", false)
		Kit.box(g, Vector3(3.2, 1.3, 6.8), Vector3(1.5, 1.2, 0.02), "#c8b890" if age != "republic" else "#b86a2a", false)
		for k in 6:
			Kit.blob(g, Vector3(2.6 + k * 0.24, 0.5, 6.8), 0.05, "clay")
	if not old and age != "fall":  # the strongbox in the tablinum
		Kit.box(g, Vector3(0, 0.4, -5.2), Vector3(1.2, 0.8, 0.7), "bronze" if age != "collapse" else "deadwood")
	if age == "early":  # the ancestor's mask in its cupboard in the wing
		Kit.box(g, Vector3(-6.5, 1.3, -1.7), Vector3(1.4, 1.6, 0.4), "wood", false)
		Kit.blob(g, Vector3(-6.5, 1.4, -1.45), 0.13, "#d8c8a0", Vector3(0.8, 1.0, 0.5), 6)
	# the dining room: stools and a table, then couches, then a broken one, then nothing
	if old:
		Kit.box(g, Vector3(-5.2, 0.4, -4.0), Vector3(1.4, 0.8, 0.9), "wood")
		for p: Vector2 in [Vector2(-6.4, -4.0), Vector2(-4.0, -4.0), Vector2(-5.2, -5.0)]:
			Kit.cylinder(g, Vector3(p.x, 0, p.y), 0.2, 0.45, "wood", false, 6)
	elif rich:
		var cloth: String = {"republic": "#8a3a2a", "empire": "#5a1e4a", "late": "#c8b4d0"}[age]
		for c: Array in [[-7.4, -4.0, 0.9, 2.6], [-5.2, -5.5, 2.6, 0.9], [-3.1, -4.0, 0.9, 2.6]]:
			Kit.box(g, Vector3(c[0], 0.35, c[1]), Vector3(c[2], 0.7, c[3]), "wood")
			Kit.box(g, Vector3(c[0], 0.74, c[1]), Vector3(c[2] - 0.1, 0.1, c[3] - 0.1), cloth, false)
		Kit.cylinder(g, Vector3(-5.2, 0, -4.0), 0.45, 0.6, "marble" if age != "republic" else "wood", true, 8)
		if age == "empire":
			for k in 3:
				Kit.blob(g, Vector3(-5.4 + k * 0.25, 0.66, -4.0), 0.1, "gold", Vector3(1.0, 0.4, 1.0), 6)
	elif age == "collapse":
		Kit.box(g, Vector3(-5.6, 0.25, -4.4), Vector3(2.4, 0.5, 0.9), "deadwood", true, Vector3(0, 0.4, 0.3))
	# your bed
	if age != "fall":
		var bed_h := 0.5 if age != "collapse" else 0.15
		Kit.box(g, Vector3(6.2, bed_h / 2.0, -4.4), Vector3(1.2, bed_h, 2.2), "wood" if age != "collapse" else "#6a5e50")
		if age != "collapse":
			Kit.box(g, Vector3(6.2, bed_h + 0.06, -4.4), Vector3(1.1, 0.12, 2.1), "#b8a888" if not rich else "#d8ccb0", false)
	# a statue in the atrium, then a broken one
	if age == "empire":
		Kit.cylinder(g, Vector3(2.4, 0, 1.0), 0.35, 0.7, "marble", true, 8)
		Kit.cylinder(g, Vector3(2.4, 0.7, 1.0), 0.18, 1.3, "bronze", false, 6, 0.12)
		Kit.blob(g, Vector3(2.4, 2.15, 1.0), 0.14, "bronze")
	elif age == "late":
		Kit.box(g, Vector3(2.4, 1.8, 7.84), Vector3(0.7, 0.7, 0.02), "#6a2a2a", false)  # a chi-rho painted where the satyr stood
	elif age == "collapse":
		Kit.cylinder(g, Vector3(2.4, 0, 1.0), 0.35, 0.7, "marble", true, 8)
		Kit.blob(g, Vector3(3.0, 0.1, 1.6), 0.14, "bronze")
	# the garden
	match age:
		"heroic", "early":
			for row in 4:
				for k in 7:
					Kit.blob(g, Vector3(-6.5 + k * 1.1, 0.12, -10.8 + row * 0.9), 0.16, "#5a7a3a", Vector3(1.0, 0.6, 1.0), 5)
			_fig(g, Vector3(5.5, 0, -10.0), 1.0)
		"republic", "empire":
			for k in 6:
				Kit.box(g, Vector3(-6.0 + k * 2.4, 0.35, -7.0), Vector3(1.2, 0.7, 0.6), "#3a5a30", false)
			Kit.cylinder(g, Vector3(0, 0, -9.0), 0.25, 0.9, "marble", true, 8)
			Kit.blob(g, Vector3(0, 1.1, -9.0), 0.2, "marble")
			if age == "empire":
				Kit.cylinder(g, Vector3(3.5, 0, -9.5), 0.9, 0.5, "marble", true, 10)
				Kit.box(g, Vector3(3.5, 0.45, -9.5), Vector3(1.2, 0.05, 1.2), "water", false)
		"late", "collapse":
			for k in 12:
				Kit.blob(g, Vector3(rng.randf_range(-7.0, 7.0), 0.2, rng.randf_range(-11.5, -6.5)), rng.randf_range(0.2, 0.45), "#4a5a34", Vector3(1.2, 0.8, 1.2), 5)
		"fall":
			for k in 18:
				Kit.blob(g, Vector3(rng.randf_range(-7.5, 7.5), 0.25, rng.randf_range(-11.5, -6.5)), rng.randf_range(0.3, 0.6), "#3e4a2e", Vector3(1.3, 0.9, 1.3), 5)
			_fig(g, Vector3(5.5, 0, -10.0), 1.4)
			for k in 10:
				Kit.blob(g, Vector3(rng.randf_range(-7.0, 7.0), 0.2, rng.randf_range(-5.0, 10.0)), rng.randf_range(0.3, 0.7), "rubble", Vector3(1.3, 0.6, 1.1), 5)
	# a lamp inside, while anyone lives here
	if age != "fall":
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 2.6, 2.0)
		lamp.light_color = Color("ffb070")
		lamp.light_energy = 0.9 if age != "collapse" else 0.4
		lamp.omni_range = 9.0
		g.add_child(lamp)


static func _fig(g: Node3D, at: Vector3, s: float) -> void:
	Kit.cylinder(g, at, 0.15 * s, 1.4 * s, "trunk", false, 6)
	Kit.blob(g, at + Vector3(0, 1.8 * s, 0), 1.1 * s, "leaves", Vector3(1.2, 0.8, 1.2), 6)


## A member of the household (dressed as places_rome dresses the city's people), scaled for a child.
static func _person(g: Node3D, at: Vector3, yaw: float, robe: String, gender: String, jewel: bool, scale: float,
		rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = load("res://scripts/hall/places_rome.gd")._dressed(g, at, yaw, {"robe": robe}, gender, rng)
	(p["root"] as Node3D).scale = Vector3.ONE * scale
	if jewel:
		Kit.blob(p["head"], Vector3(0.16, -0.06, 0.0), 0.035, "gold")
		Kit.blob(p["head"], Vector3(-0.16, -0.06, 0.0), 0.035, "gold")
		Kit.box(p["root"], Vector3(0, 1.32, 0.15), Vector3(0.3, 0.04, 0.03), "gold", false)
	return p


static func _dog(g: Node3D, at: Vector3) -> void:
	var root := Kit.group(g, at)
	Kit.box(root, Vector3(0, 0.2, 0), Vector3(0.16, 0.16, 0.36), "#e8e0d0", false)
	Kit.box(root, Vector3(0, 0.3, 0.2), Vector3(0.14, 0.14, 0.16), "#e8e0d0", false)
	Kit.box(root, Vector3(0, 0.34, 0.12), Vector3(0.17, 0.03, 0.03), "gold", false)
