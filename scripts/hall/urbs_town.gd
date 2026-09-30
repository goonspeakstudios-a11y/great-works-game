extends RefCounted
## The city's calendar and its small life, round you (content/rome/town.json): the days go by, with
## a market every eighth day and festivals in their season; at their hours a funeral, a wedding or a
## sacrifice goes by along its street, a senator speaks from the Rostra, the crier cries the
## auctions; some days it rains. Pigeons rise from the Forum when you run through them, dogs trot
## after people, the trades are heard at their doors (the smith's hammer, the loom), smoke goes up
## from the bakeries' ovens, and the regulars you come to know keep their places.
##
## urbs_life.gd calls step() every frame. People it brings (a procession, a crowd) are citizens like
## the rest (places_rome.gd's `spawn`), and go again when their time is over.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const RomeMap := preload("res://scripts/hall/rome_map.gd")
const FILE := "res://content/rome/town.json"

static var _data := {}

var age := "republic"
var day := 0
var world: Node3D
var life: RefCounted  # urbs_life.gd: its hour, its bubbles
var spawn: Callable  # (job, at, yaw) -> a citizen's person dictionary, added to the city
var unspawn: Callable  # (person) -> gone from the city
var streets: Array = []
var sound := true  # off in tests
var raining := false
var _rain_from := 25.0
var _rain_to := 25.0
var _rain: CPUParticles3D
var _events := {}  # event id -> {people: [], ends, path?}
var _pigeons: Array = []  # {node, home, flying}
var _smoke: Array = []
var _players: Array = []  # AudioStreamPlayer3D, each on one sound at a time
var _emitters: Array = []  # [person, sound file]
var _sound_scan := 0.0
var region := ""  # the part of the city you are in (hall.gd's corner name), for its sound bed
var burnt: Array = []  # where the quarters burnt (rome_map.gd), for the smoke over them in 455
var _beds: Array = []  # two AudioStreamPlayers, the region's bed crossfading between them
var _bed_on := 0
var _bed_file := ""

## The sound under each part of the city (docs/rome-city-notes.md 2.2): the Forum's crowd, the
## Subura's hammering, the Palatine's birds, the river port's gulls, the Campus's wind. By a word of
## the region's name; the emptied city has only wind and crickets.
const BEDS := {"forum": "crowd", "subura": "forge", "palat": "birds", "boarium": "gulls", "port": "gulls", "emporium": "gulls",
	"tiber": "gulls", "river": "gulls", "campus": "wind", "capitol": "wind", "aventin": "sheep", "esquil": "loom", "caeli": "birds",
	"quirinal": "birds", "viminal": "loom", "lateran": "birds", "vatican": "gulls", "circus": "crowd", "velabr": "crowd"}
var _cry := 0.0
var rng := RandomNumberGenerator.new()


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = parsed if parsed is Dictionary else {}
	return _data


func setup(the_world: Node3D, the_age: String, the_day: int, people: Array) -> void:
	world = the_world
	age = the_age
	day = the_day
	rng.seed = 1000 + day
	_plan_rain()
	_pigeons_in_forum()
	_dogs(people)
	_herds(people)
	_cats()
	for p: Dictionary in people:
		if p.has("citizen"):
			var sfx: String = data().get("sounds", {}).get(p["citizen"]["job"], "")
			if sfx != "":
				_emitters.append([p, sfx])
				if sfx in ["fire", "forge"] and _smoke.size() < 12 and age != "fall":
					_smoke.append(_plume((p["root"] as Node3D).position + Vector3(0, 13.0, 0)))
	if age == "collapse":  # the smoke still going up from the burnt quarters, seen across the city
		for k in mini(16, burnt.size()):
			var at: Vector3 = burnt[k * burnt.size() / mini(16, burnt.size())]
			_smoke.append(_plume(at + Vector3(0, 9.0, 0), 3.0))


## The sound bed of the region you are in (BEDS), by a word of its name; "" for none.
static func bed_for(region_name: String, the_age: String, hour: float) -> String:
	var n := region_name.to_lower()
	if the_age == "fall":
		return "wind" if hour >= 6.0 and hour < 20.0 else "crickets"
	if hour < 6.0 or hour >= 21.0:
		return "crickets"
	for word: String in BEDS:
		if n.contains(word):
			var bed: String = BEDS[word]
			if bed == "crowd" and (hour < 7.0 or the_age == "collapse"):
				return "wind"
			return bed
	return "birds"


## Today: a market day, a festival, or an ordinary day.
func market_day() -> bool:
	return day % int(data().get("market_every", 8)) == 0


func festival() -> Dictionary:
	var year := int(data().get("year_days", 24))
	for f: Dictionary in data().get("festivals", []):
		if int(f["day"]) == day % year and (f["ages"] as Array).has(age):
			return f
	return {}


## What people have to say about today, if today is anything: a festival, a market day, the rain.
func today_news() -> String:
	var f := festival()
	if not f.is_empty():
		return str(f["news"])
	if market_day() and age != "fall":
		return "It's market day. The country people are in with their carts. The Forum Boarium's heaving."
	if raining:
		return "This rain! The gutters are rivers and the Tiber's rising."
	return ""


func _plan_rain() -> void:
	raining = false
	if rng.randf() < float(data().get("rain", {}).get("chance", 0.3)):
		_rain_from = rng.randf_range(8.0, 17.0)
		_rain_to = _rain_from + rng.randf_range(1.0, 2.5)
	else:
		_rain_from = 25.0
		_rain_to = 25.0


## A new day at midnight: the calendar moves on.
func next_day() -> void:
	day += 1
	rng.seed = 1000 + day
	_plan_rain()


func step(delta: float, at: Vector3, hour: float, moving: bool) -> void:
	var wet := hour >= _rain_from and hour < _rain_to
	if wet != raining:
		raining = wet
		_set_rain(wet)
		if wet:
			_cry_near(at, data()["rain"]["cries"])
	if _rain:
		_rain.global_position = at + Vector3(0, 14.0, 0)
	_run_events(hour, at)
	_scare_pigeons(delta, at, moving)
	for s: Node in _smoke:
		if is_instance_valid(s):
			(s as CPUParticles3D).emitting = hour > 5.0 and hour < 20.0
	if sound:
		_sound_scan -= delta
		if _sound_scan <= 0.0:
			_sound_scan = 0.5
			_sounds(at, hour)
			_bed(hour)
		for k in _beds.size():  # the beds crossfade over a few seconds
			var pl: AudioStreamPlayer = _beds[k]
			var want := -16.0 if k == _bed_on and pl.playing else -60.0
			pl.volume_db = move_toward(pl.volume_db, want, delta * 12.0)
			if pl.volume_db <= -59.0 and pl.playing and k != _bed_on:
				pl.stop()


# ---------- the day's events ----------

func _run_events(hour: float, at: Vector3) -> void:
	var f := festival()
	var want := {}
	if not f.is_empty() and hour >= 8.0 and hour < 20.0:
		want["festival"] = {"kind": "gathering", "at": f["at"], "crowd": f["crowd"], "speaker": "proletarius", "cries": f["cries"]}
	for e: Dictionary in data().get("events", []):
		if not (e["ages"] as Array).has(age):
			continue
		if e["kind"] == "procession":
			if day % int(e.get("every", 1)) == 0 and hour >= float(e["hour"]) and hour < float(e["hour"]) + 0.12:
				want[e["id"]] = e
			elif _events.has(e["id"]) and _events[e["id"]].get("walking", false):
				want[e["id"]] = e  # a procession goes on to the end of its street
		elif hour >= float(e["from"]) and hour < float(e["to"]) and (not e.get("market", false) or market_day()) \
				and day % int(e.get("every", 1)) == 0:
			want[e["id"]] = e
	for id: String in _events.keys():
		if not want.has(id):
			for p: Dictionary in _events[id]["people"]:
				unspawn.call(p)
			_events.erase(id)
	for id: String in want:
		if not _events.has(id):
			_events[id] = _begin(want[id])
	_cry -= 1.0 / 60.0
	if _cry <= 0.0:
		_cry = 2.5
		for id: String in _events:
			var ev: Dictionary = _events[id]
			var who: Array = ev["people"]
			if who.is_empty():
				continue
			var p: Dictionary = who[rng.randi() % who.size()]
			var root: Node3D = p["root"]
			if is_instance_valid(root) and root.global_position.distance_to(at) < 30.0:
				var cries: Variant = ev["cries"]
				var list: Array = cries.get(age, []) if cries is Dictionary else cries
				if not list.is_empty():
					life.say(root, str(list[rng.randi() % list.size()]))
			if ev.get("walking", false):
				var lead: Dictionary = who[0]
				if int(lead.get("leg", 0)) >= (lead["path"] as Array).size() - 1:
					ev["walking"] = false  # at the end of its street: it will be gone


## Brings an event's people: a procession along its street in file, or a crowd round a speaker.
func _begin(e: Dictionary) -> Dictionary:
	var people: Array = []
	var cries: Variant = e.get("cries", [])
	if e["kind"] == "procession":
		var road: Array = streets[clampi(int(e.get("road", 0)), 0, streets.size() - 1)]
		var crew: Array = e["crew"]
		for k in crew.size():
			var offset := Vector3(0.9 * ((k % 2) * 2 - 1), 0, 0)
			var path: Array = road.map(func(q: Vector3) -> Vector3: return q + offset)
			var first: Vector3 = path[0]
			var condemned: bool = crew[k] == "condemned"  # a slave carrying his crossbeam out to the gate
			var p: Dictionary = spawn.call("servus" if condemned else crew[k], first - (path[1] - first).normalized() * (k / 2) * 1.8, 0.0)
			if condemned:
				var beam := Kit.box(p["root"], Vector3(0, 1.45, -0.1), Vector3(1.9, 0.16, 0.16), "deadwood", false)
				beam.rotation.z = 0.05
				(p["citizen"] as Dictionary)["title"] = "condemned man"
				(p["citizen"] as Dictionary)["regular_lines"] = ["...", "Water. Please.", "Tell my wife. On the Aventine. Tell her."]
			p["path"] = path
			p["speed"] = 0.8
			p["leg"] = 1
			p["shift"] = "always"
			if e.get("torches", false) and k % 2 == 0:
				_torch(p)
			people.append(p)
		if e.get("ox", false) and not people.is_empty():
			var ox := _ox((people[0]["root"] as Node3D).position + Vector3(0, 0, 1.5))
			ox["path"] = people[0]["path"]
			ox["speed"] = 0.8
			ox["leg"] = 1
			ox["ground"] = people[0].get("ground")
			life.people.append(ox)
			people.append(ox)
		return {"people": people, "cries": cries, "walking": true}
	var centre := RomeMap.on_ground(e["at"])
	var speaker: Dictionary = spawn.call(str(e.get("speaker", "proletarius")), centre, 0.0)
	speaker["shift"] = "always"
	people.append(speaker)
	var n := int(e.get("crowd", 6))
	for k in n:
		var a := TAU * k / n
		var spot := centre + Vector3(cos(a), 0, sin(a)) * rng.randf_range(2.5, 4.5)
		spot.y = RomeMap.ground(spot)
		var p: Dictionary = spawn.call(["proletarius", "servus", "ancilla", "matrona", "peregrinus", "cliens"][rng.randi() % 6],
			spot, Kit.face_yaw(spot, centre))
		p["shift"] = "always"
		people.append(p)
	return {"people": people, "cries": cries}


func _torch(p: Dictionary) -> void:
	var hand: Node3D = p["hand"]
	Kit.box(hand, Vector3(0.3, 1.6, 0.4), Vector3(0.06, 0.7, 0.06), "wood", false)
	var flame := Kit.blob(hand, Vector3(0.3, 2.0, 0.4), 0.12, "fire", Vector3(1.0, 1.6, 1.0), 5)
	var light := OmniLight3D.new()
	light.light_color = Color("ff9a48")
	light.omni_range = 7.0
	light.light_energy = 1.2
	flame.add_child(light)


## The ox for the sacrifice: white, garlanded, going quietly. Walks like a person (legs, head).
func _ox(at: Vector3) -> Dictionary:
	var root := Kit.group(world, at)
	Kit.box(root, Vector3(0, 1.1, 0), Vector3(0.9, 0.9, 2.0), "#e8e2d6", false)
	var head := Kit.group(root, Vector3(0, 1.3, 1.1))
	Kit.box(head, Vector3(0, 0, 0.2), Vector3(0.5, 0.5, 0.6), "#e8e2d6", false)
	Kit.box(head, Vector3(0, 0.3, 0.2), Vector3(0.9, 0.08, 0.08), "#c8b890", false)  # the horns
	Kit.box(head, Vector3(0, -0.1, -0.1), Vector3(0.62, 0.12, 0.2), "#c83a3a", false)  # the garland
	var legs: Array = []
	for x: float in [-0.3, 0.3]:
		var leg := Kit.group(root, Vector3(x, 0.7, 0.6 if x < 0.0 else -0.6))
		Kit.box(leg, Vector3(0, -0.35, 0), Vector3(0.18, 0.7, 0.18), "#d8d2c6", false)
		legs.append(leg)
	return {"root": root, "head": head, "hand": Kit.group(root, Vector3.ZERO), "legs": legs}


# ---------- rain ----------

func _set_rain(on: bool) -> void:
	if on and _rain == null:
		_rain = CPUParticles3D.new()
		_rain.amount = 900
		_rain.lifetime = 1.2
		_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_rain.emission_box_extents = Vector3(26, 0.5, 26)
		_rain.direction = Vector3(0.1, -1, 0)
		_rain.spread = 3.0
		_rain.initial_velocity_min = 16.0
		_rain.initial_velocity_max = 20.0
		_rain.gravity = Vector3(0, -9.8, 0)
		var drop := QuadMesh.new()
		drop.size = Vector2(0.03, 0.5)
		_rain.mesh = drop
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.75, 0.8, 0.9, 0.45)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		_rain.material_override = m
		world.add_child(_rain)
	if _rain:
		_rain.emitting = on


# ---------- birds and dogs ----------

func _pigeons_in_forum() -> void:
	var centre := RomeMap.at([0, 10])
	for k in (16 if age != "fall" else 6):
		var home := centre + Vector3(rng.randf_range(-14, 14), 0.05, rng.randf_range(-8, 8))
		var bird := Kit.group(world, home, rng.randf() * TAU)
		Kit.blob(bird, Vector3(0, 0.12, 0), 0.1, "#8a8a94", Vector3(1.0, 0.9, 1.5), 5)
		Kit.blob(bird, Vector3(0, 0.22, 0.12), 0.055, "#5a6a70", Vector3.ONE, 5)
		_pigeons.append({"node": bird, "home": home, "fly": 0.0, "dir": Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()})


## Pigeons peck about the Forum; run through them and they clatter up and away, and drift back.
func _scare_pigeons(delta: float, at: Vector3, moving: bool) -> void:
	for b: Dictionary in _pigeons:
		var node: Node3D = b["node"]
		if not is_instance_valid(node):
			continue
		if b["fly"] <= 0.0 and moving and Vector2(node.position.x - at.x, node.position.z - at.z).length() < 4.0:
			b["fly"] = 6.0
		if b["fly"] > 0.0:
			b["fly"] -= delta
			var up: float = b["fly"] - 3.0  # up and away for three seconds, then back down home
			if up > 0.0:
				node.position += ((b["dir"] as Vector3) * 5.0 + Vector3(0, 4.0, 0)) * delta
			else:
				node.position = node.position.lerp(b["home"], minf(1.0, delta * 1.2))
		else:
			node.position.y = (b["home"] as Vector3).y + absf(sin(Time.get_ticks_msec() / 250.0 + node.position.x)) * 0.02
			node.rotation.x = 0.4 * maxf(0.0, sin(Time.get_ticks_msec() / 400.0 + node.position.z))  # pecking


## A few dogs trotting along the streets.
func _dogs(people: Array) -> void:
	if streets.is_empty():
		return
	for k in (6 if age != "fall" else 3):
		var road: Array = streets[rng.randi() % streets.size()]
		var i := rng.randi_range(0, road.size() - 2)
		var a: Vector3 = road[i]
		var b: Vector3 = road[i + 1]
		var root := Kit.group(world, a)
		var coat: String = ["#6a4a2a", "#3a3028", "#a88a5a", "#d8ccb8"][rng.randi() % 4]
		Kit.box(root, Vector3(0, 0.42, 0), Vector3(0.28, 0.3, 0.75), coat, false)
		var head := Kit.group(root, Vector3(0, 0.62, 0.42))
		Kit.box(head, Vector3(0, 0, 0.08), Vector3(0.22, 0.22, 0.3), coat, false)
		Kit.box(head, Vector3(0, 0.14, -0.02), Vector3(0.2, 0.1, 0.06), coat, false)  # the ears
		var legs: Array = []
		for z: float in [0.25, -0.25]:
			var leg := Kit.group(root, Vector3(0, 0.3, z))
			Kit.box(leg, Vector3(0, -0.15, 0), Vector3(0.24, 0.3, 0.08), coat, false)
			legs.append(leg)
		var dog := {"root": root, "head": head, "hand": Kit.group(root, Vector3.ZERO), "legs": legs, "path": [a, b, a],
			"speed": 1.6, "ground": func(q: Vector3) -> float: return RomeMap.ground(q)}
		people.append(dog)


## Cats on the doorsteps and the counters, sitting, as cats do (kit_greek's dog, small, in a
## cat's colours). They do not move; the dogs do.
func _cats() -> void:
	if streets.is_empty():
		return
	var coats := ["#8a8078", "#c88a4a", "#2a2624", "#d8d0c0", "#6a5a4a"]
	for k in (30 if age != "fall" else 8):
		var road: Array = streets[rng.randi() % streets.size()]
		var i := rng.randi_range(0, road.size() - 2)
		var a: Vector3 = road[i]
		var b: Vector3 = road[i + 1]
		var p := a.lerp(b, rng.randf())
		var dir := (b - a).normalized()
		var side := Vector3(dir.z, 0, -dir.x) * (rng.randf_range(3.5, 5.0) * (1.0 if rng.randf() < 0.5 else -1.0))  # by the house fronts
		p += side
		p.y = RomeMap.ground(p)
		var cat: Dictionary = Greek.beast(world, p, rng.randf() * TAU, "dog", coats[rng.randi() % coats.size()], 0.32)
		Kit.unsolid(cat["root"])
		(cat["root"] as Node3D).scale.y *= 0.9
		for leg: Node3D in cat["legs"]:
			leg.rotation.x = -1.1 if leg.position.z < 0.0 else 0.0  # sitting on its haunches


## Livestock and carts in the streets (docs/rome-city-notes.md 2.3): a flock of sheep driven down
## the Vicus Tuscus to the cattle market and back by a shepherd, while Rome still has a cattle
## market; and a muleteer's cart with its two mules going up and down the Via Lata.
func _herds(people: Array) -> void:
	if streets.is_empty() or not spawn.is_valid():
		return
	var roads: Array = RomeMap.city_data().get("roads", [])
	var index := func(name: String) -> int:
		for i in roads.size():
			if str(roads[i]["name"]) == name:
				return i
		return -1
	var ground := func(q: Vector3) -> float: return RomeMap.ground(q)
	var loop_of := func(i: int) -> Array:
		var path: Array = (streets[i] as Array).duplicate()
		var back := path.duplicate()
		back.reverse()
		return path + back.slice(1, back.size() - 1)
	var tuscus: int = index.call("the Vicus Tuscus")
	if age in ["heroic", "early", "republic", "empire"] and tuscus >= 0 and tuscus < streets.size():
		var loop: Array = loop_of.call(tuscus)
		var shepherd: Dictionary = spawn.call("proletarius", loop[0], 0.0)
		shepherd["path"] = loop
		shepherd["speed"] = 0.7
		shepherd["shift"] = "day"
		shepherd["ground"] = ground
		shepherd.erase("leg")
		(shepherd["citizen"] as Dictionary)["title"] = "shepherd"
		Kit.box(shepherd["hand"], Vector3(0.3, 0.9, 0.3), Vector3(0.05, 1.8, 0.05), "wood", false)  # the crook
		for k in 6:
			var off := Vector3(rng.randf_range(-1.6, 1.6), 0, -1.5 - k * 0.7)
			var sheep := _sheep((loop[0] as Vector3) + off)
			sheep["path"] = loop.map(func(q: Vector3) -> Vector3: return q + off)
			sheep["speed"] = 0.7
			sheep["shift"] = "day"
			sheep["ground"] = ground
			people.append(sheep)
	var lata: int = index.call("the Via Lata")
	if age != "fall" and lata >= 0 and lata < streets.size():
		var loop: Array = loop_of.call(lata)
		var cart := _cart(loop[0])
		cart["path"] = loop
		cart["speed"] = 1.1
		cart["shift"] = "always"
		cart["ground"] = ground
		people.append(cart)
		var driver: Dictionary = spawn.call("mulio", (loop[0] as Vector3) + Vector3(1.4, 0, 0), 0.0)
		driver["path"] = loop.map(func(q: Vector3) -> Vector3: return q + Vector3(1.4, 0, 0))
		driver["speed"] = 1.1
		driver["shift"] = "always"
		driver["ground"] = ground


## A sheep (kit_greek's beast), walking like a person (legs, head).
func _sheep(at: Vector3) -> Dictionary:
	var b: Dictionary = Greek.beast(world, at, 0.0, "sheep", "", 0.8)
	Kit.unsolid(b["root"])
	b["hand"] = Kit.group(b["root"], Vector3.ZERO)
	return b


## A mule cart: two mules (kit_greek's horse, small and brown) in the traces, a two-wheeled cart
## with its load under a cloth behind them. Walks like a person (the mules' legs swing).
func _cart(at: Vector3) -> Dictionary:
	var root := Kit.group(world, at)
	var legs: Array = []
	for x: float in [-0.55, 0.55]:  # the mules
		var mule: Dictionary = Greek.beast(root, Vector3(x, 0, 1.7), 0.0, "horse", "#6a5040", 0.8)
		Kit.unsolid(mule["root"])
		legs.append_array(mule["legs"])
	Kit.box(root, Vector3(0, 0.95, 0.6), Vector3(1.4, 0.08, 1.4), "wood", false)  # the shafts
	Kit.box(root, Vector3(0, 1.1, -0.6), Vector3(1.6, 0.6, 1.8), "wood", false)  # the cart's body
	Kit.blob(root, Vector3(0, 1.6, -0.6), 0.7, "#c8b890", Vector3(1.1, 0.5, 1.2), 6)  # the load under its cloth
	for x: float in [-0.95, 0.95]:
		var wheel := Kit.cylinder(root, Vector3(x, 0.0, -0.6), 0.6, 0.12, "wood", false, 10)
		wheel.rotation = Vector3(0, 0, PI / 2.0)
		wheel.position = Vector3(x, 0.6, -0.6)
	var head := Kit.group(root, Vector3(0, 1.35, 2.5))
	return {"root": root, "head": head, "hand": Kit.group(root, Vector3.ZERO), "legs": legs, "cart": true}


# ---------- sounds and smoke ----------

## The trades heard at their doors: the three nearest, each on a player of its own, loud as you near.
func _sounds(at: Vector3, hour: float) -> void:
	if _players.is_empty():
		for k in 3:
			var pl := AudioStreamPlayer3D.new()
			pl.unit_size = 4.0
			pl.max_distance = 26.0
			pl.volume_db = -6.0
			pl.bus = "Master"
			world.add_child(pl)
			_players.append(pl)
	var near: Array = []
	for e: Array in _emitters:
		var p: Dictionary = e[0]
		var root: Node3D = p["root"]
		if not is_instance_valid(root) or not root.visible:
			continue
		var d := root.global_position.distance_to(at)
		var open: bool = (hour >= 7.0 and hour < 19.0) or (e[1] == "crowd" and hour >= 17.0)
		if d < 24.0 and open:
			near.append([d, root.global_position, e[1]])
	near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for k in _players.size():
		var pl: AudioStreamPlayer3D = _players[k]
		if k >= near.size():
			pl.stop()
			continue
		var file := "res://assets/music/%s.wav" % near[k][2]
		if pl.stream == null or pl.stream.resource_path != file:
			var s: Variant = load(file) if ResourceLoader.exists(file) else null
			if s is AudioStreamWAV:
				var w: AudioStreamWAV = (s as AudioStreamWAV).duplicate()
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_end = int(w.get_length() * w.mix_rate)
				w.resource_path = file
				pl.stream = w
				pl.play()
		pl.global_position = near[k][1] + Vector3(0, 1.5, 0)


## The region's sound bed, under the trades' sounds: started when the region (or the hour) changes,
## the old one fading as the new comes up.
func _bed(hour: float) -> void:
	var file := bed_for(region, age, hour)
	if file == _bed_file:
		return
	_bed_file = file
	if _beds.is_empty():
		for k in 2:
			var pl := AudioStreamPlayer.new()
			pl.volume_db = -60.0
			pl.bus = "Master"
			world.add_child(pl)
			_beds.append(pl)
	_bed_on = 1 - _bed_on
	var pl: AudioStreamPlayer = _beds[_bed_on]
	pl.stop()
	if file == "":
		return
	var path := "res://assets/music/%s.wav" % file
	var s: Variant = load(path) if ResourceLoader.exists(path) else null
	if s is AudioStreamWAV:
		var w: AudioStreamWAV = (s as AudioStreamWAV).duplicate()
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = int(w.get_length() * w.mix_rate)
		pl.stream = w
		pl.volume_db = -60.0
		pl.play()


## A thin plume of smoke over an oven or a forge; `size` above 1 for the smoke of a burnt quarter.
func _plume(at: Vector3, size: float = 1.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = int(14 * size)
	p.lifetime = 6.0 * size
	p.direction = Vector3(0.2, 1, 0)
	p.spread = 12.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.4 * size
	p.gravity = Vector3(0.15, 0.05, 0)
	p.scale_amount_min = 1.0 * size
	p.scale_amount_max = 2.6 * size
	var puff := SphereMesh.new()
	puff.radius = 0.6
	puff.height = 1.2
	puff.radial_segments = 6
	puff.rings = 3
	p.mesh = puff
	p.material_override = load("res://scripts/hall/textures.gd").material("smoke")
	p.position = at
	world.add_child(p)
	return p


func _cry_near(at: Vector3, list: Array) -> void:
	for p: Dictionary in life.people:
		if p.has("citizen") and is_instance_valid(p["root"]) and (p["root"] as Node3D).visible and (p["root"] as Node3D).global_position.distance_to(at) < 12.0:
			life.say(p["root"], str(list[rng.randi() % list.size()]))
			return
