extends RefCounted
## The city of Rome: the Rome world's hub. Where Greece has its Shore of gateways, Rome has the
## whole city (rome_map.gd), walked street by street, in one of four ages (content/rome/city.json):
## the Republic about 50 BC in the morning, the Empire about AD 150 at noon, the late Empire about
## AD 330 in the golden afternoon, and the emptied city of AD 552 at nightfall. Its books stand in
## its zones behind Roman gateways (the Rhetorica's in the Forum, under the Palatine). The navel
## of the city, by the Rostra, lets the years pass.
##
## The city is full of its people, and every one of them will talk: shopkeepers at their stalls
## and doors, the patrols (the praetor's lictors, then the watch, then the prefect's soldiers, then
## the Emperor's garrison), senators with their clients, the plebs, strangers from every province,
## and in the later ages the clergy; and knots of people arguing, whom you can stand and listen to.
## Every monument that has a story tells it. The corner names the region you are in.

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Places := preload("res://scripts/hall/places.gd")
const RomeMap := preload("res://scripts/hall/rome_map.gd")
const Citizen := preload("res://scripts/hall/citizen.gd")
const Life := preload("res://scripts/hall/urbs_life.gd")
const Town := preload("res://scripts/hall/urbs_town.gd")

## Where the city crowds together in each age: [map position, share of the people].
const HOTSPOTS := {
	"republic": [[[0, 10], 0.3], [[-290, -367], 0.15], [[522, 367], 0.15], [[41, -600], 0.08], [[-760, 200], 0.1],
		[[-560, -700], 0.1], [[260, -200], 0.12]],
	"empire": [[[0, 10], 0.22], [[560, -222], 0.15], [[522, 367], 0.12], [[-290, -367], 0.1], [[-688, 710], 0.12],
		[[-20, 300], 0.1], [[41, -600], 0.08], [[260, -200], 0.11]],
	"late": [[[0, 10], 0.22], [[560, -222], 0.15], [[522, 367], 0.12], [[-290, -367], 0.08], [[-688, 710], 0.12],
		[[-20, 300], 0.08], [[260, -200], 0.13]],
	"fall": [[[-800, 450], 0.5], [[-688, 710], 0.2], [[0, 10], 0.3]],
}
## Who keeps the streets in each age (a job in people.json), walking in step.
const PATROLS := {"republic": "lictor", "empire": "vigil", "late": "miles", "fall": "miles"}
## The jobs most of the city is at, met more often than the rest.
const COMMON := ["proletarius", "servus", "ancilla", "peregrinus", "baiulus", "matrona", "aquarius", "mendicus"]
## When each kind of person is out: the carters by night, the watch and the innkeepers always.
const SHIFTS := {"mulio": "night", "caupo": "always", "lictor": "day", "vigil": "always", "miles": "always"}
## How far each age has fallen: greyer, darker, thicker air (urbs_life.gd).
const GLOOM := {"republic": 0.0, "empire": 0.05, "late": 0.3, "fall": 0.65}
## The music zone of each age (music.gd): the town by day and night, then the same tune gone
## wrong, then only its echo.
const ZONE := {"republic": "urbs", "empire": "urbs", "late": "urbs_late", "fall": "urbs_fall"}


## The city in the age `age_index`. `reached`: the last age the Roman books have brought you to;
## the navel passes the years only that far.
static func urbs(world: Node3D, doors: Array, progress: RefCounted, age_index: int, reached: int = 3) -> Dictionary:
	var c := RomeMap.city_data()
	var ages := RomeMap.ages()
	var age: Dictionary = ages[clampi(age_index, 0, ages.size() - 1)]
	var id: String = age["id"]
	Kit.sunset(world, str(age.get("mood", "morning")))
	for we: Node in world.find_children("*", "WorldEnvironment", true, false):  # a city seen far down its streets
		var env: Environment = (we as WorldEnvironment).environment
		env.fog_density *= 0.4 if id != "fall" else 0.8
		env.tonemap_exposure = 0.9
	var out: Array = []
	var spots := {}
	var arrival := RomeMap.on_ground(c["arrival"]["at"])
	var arrival_to := RomeMap.on_ground(c["arrival"]["toward"])
	var navel := RomeMap.on_ground(c["navel"]["at"])
	var clear: Array = [arrival, navel]
	for work: String in c.get("gates", {}):
		clear.append(RomeMap.on_ground(c["gates"][work]["at"]))
	var fab := RomeMap.fabric(world, age, {"clear": clear})
	var flicker: Array = fab["flicker"]

	# the navel of the city: the years pass here
	Kit.cylinder(world, navel, 1.6, 1.4, "brick", true, 12)
	Kit.cylinder(world, navel + Vector3(0, 1.4, 0), 1.8, 0.25, "marble", false, 12)
	if reached > 0:
		var to := age_index + 1 if age_index < reached else 0
		out.append({"kind": "rome_age", "pos": navel, "to": to,
			"text": str(age.get("navel", "Let the years pass")) if to != 0 else "Go back to the Republic",
			"note": str(c["navel"].get("note", ""))})
	else:  # the first act: the years have not begun to pass
		out.append({"kind": "statue", "pos": navel, "text": "Look at the navel of the city",
			"note": "[b]The Navel of the City[/b]\n\n%s\n\nThe years have not begun to pass. Rome is young and loud and full of itself." % c["navel"].get("note", "")})
	spots["navel"] = navel

	# the gateways to Rome's books, in their zones
	var arrivals := {"nexus": [arrival + Vector3(0, 0.05, 0), Places.look_yaw(arrival_to - arrival)]}
	for d: Dictionary in doors:
		var g: Dictionary = c.get("gates", {}).get(d["work"], {})
		if g.is_empty():
			continue
		var at := RomeMap.on_ground(g["at"])
		var toward := RomeMap.on_ground(g["toward"])
		var mastered: bool = progress != null and progress.is_mastered(d["work"])
		var light := Rome.gateway(world, at, Kit.face_yaw(at, toward), d["open"], mastered)
		if light:
			flicker.append(light)
		var room: Dictionary = load("res://scripts/hall/rooms.gd").room(d["work"])
		out.append({"kind": "gate", "pos": at + (toward - at).normalized() * 1.2, "to": d["work"], "open": d["open"],
			"text": "%s: %s, %s" % [d["name"], room.get("where", ""), room.get("when", "")]})
		arrivals[d["work"]] = [at + (toward - at).normalized() * 3.0 + Vector3(0, 0.05, 0), Places.look_yaw(toward - at)]
		spots[d["work"]] = at

	# what the monuments tell you
	for s: Dictionary in fab["monuments"]:
		var m: Dictionary = s["m"]
		if not m.has("note"):
			continue
		var note := str(m["note"])
		if s["state"] == "ruin" and id == "fall":
			note = str(m.get("fall", note + " Now it is a ruin."))
		elif id == "fall" and m.has("fall"):
			note = str(m["fall"])
		var pos := _front(s)
		out.append({"kind": "statue", "pos": pos, "text": "Look at %s" % m["name"],
			"note": "[b]%s[/b], %s\n\n%s" % [_title(str(m["name"])), age["when"], note]})

	var people: Array = []
	var squads: Array = []
	var regions: Array = _regions(c, id)
	var homes: Array = regions.map(func(r: Dictionary) -> String: return str(r["name"]).split(", ")[-1])
	var life := Life.new()
	var spawn: Callable = _people(world, c, age, fab, people, out, homes, life)
	var town := Town.new()
	town.streets = fab["streets"]
	town.life = life
	town.spawn = func(job: String, at: Vector3, yaw: float) -> Dictionary:
		var p: Dictionary = spawn.call(job, at, yaw)
		_cull([p])
		return p
	town.unspawn = func(p: Dictionary) -> void:
		people.erase(p)
		for k in range(out.size() - 1, -1, -1):
			if out[k].get("follow") == p["root"]:
				out.remove_at(k)
		if is_instance_valid(p["root"]):
			(p["root"] as Node3D).queue_free()
	town.sound = DisplayServer.get_name() != "headless"
	_regulars(spawn, id, out)
	town.setup(world, id, int(progress.data.get("rome_day", 1)) if progress != null else 1, people)
	life.town = town
	if progress != null:
		if not progress.data.has("rome_met"):
			progress.data["rome_met"] = {}
		life.met = progress.data["rome_met"]
	_cull(people)
	var sky := Node3D.new()  # the stars, over the city at night
	world.add_child(sky)
	Kit.stars(sky)
	life.stars = sky
	life.windows = RomeMap.window_glass()
	life.flames = fab.get("flames", [])
	var start: float = float(progress.data.get("rome_hour", 8.0)) if progress != null else 8.0
	life.setup(world, start, float(GLOOM.get(id, 0.0)))
	var landmarks: Array = (fab["monuments"] as Array).filter(func(m: Dictionary) -> bool: return (m["m"] as Dictionary).has("note")).map(
		func(m: Dictionary) -> Dictionary: return {"name": str(m["m"]["name"]), "pos": m["at"]})
	var birds: Array = Kit.flock(world, Vector3(0, 0, 0), 9 if id != "fall" else 4, 40.0, 26.0)
	return {"name": "Rome, %s" % age["when"], "interactables": out, "spawn": arrival + Vector3(0, 0.05, 0),
		"yaw": Places.look_yaw(arrival_to - arrival), "spots": spots, "flicker": flicker, "people": people, "squads": squads,
		"restored": 0, "sway": fab.get("sway", []), "birds": birds, "back": [life.phase()], "arrivals": arrivals, "regions": regions,
		"age": id, "line": str(age.get("line", "")), "life": life, "landmarks": landmarks, "zone": ZONE.get(id, "urbs")}


## The regions of the city in an age, named as they were then (in the emptied city, the empty ones).
static func _regions(c: Dictionary, id: String) -> Array:
	var out: Array = []
	var ab: Dictionary = c.get("abitato", {})
	for r: Dictionary in c.get("regions", []):
		var name: String = r.get(id if r.has(id) else ("republic" if id == "republic" else "empire"), "")
		var centre := RomeMap.at(r["at"])
		if id == "fall" and centre.distance_to(RomeMap.at(ab.get("at", [0, 0]))) > RomeMap.span(float(ab.get("radius", 500))):
			name += ", empty"
		out.append({"c": Vector2(centre.x, centre.z), "r": RomeMap.span(float(r["r"])), "name": name})
	return out


## "the Temple of Saturn" -> "The Temple of Saturn".
static func _title(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


## Where you stand to look at a monument: before its front, clear of it.
static func _front(s: Dictionary) -> Vector3:
	var m: Dictionary = s["m"]
	var at: Vector3 = s["at"]
	var yaw: float = s["yaw"]
	var ahead := Vector3(sin(yaw), 0, cos(yaw))
	var dist := RomeMap.footprint(m) - 3.0
	match str(m["kind"]):
		"temple":
			dist = 14.5 * float(m.get("size", 1.0)) + 1.5
		"forum":
			dist = RomeMap.span(float(m.get("d", 100))) / 2.0 + 2.0
		"circus":
			ahead = Vector3(ahead.z, 0, -ahead.x)
			dist = RomeMap.span(140.0) / 2.0 + 16.0
		"obelisk", "column", "colossus", "shrine", "fountain_cone", "rostra":
			dist = RomeMap.footprint(m) + 1.0
	var p := at + ahead * dist
	p.y = RomeMap.ground(p)
	return p


## The people of the city in its age, every one a citizen with a name and a trade who will talk
## (citizen.gd): shopkeepers at their stalls and doors, the patrol walking in step, senators with
## their clients at their heels, people at their work at the river and the temples, people walking
## and standing about, and knots of them arguing by the monuments and the fountains.
static func _people(world: Node3D, c: Dictionary, age: Dictionary, fab: Dictionary, people: Array, out: Array, homes: Array,
		life: RefCounted) -> Callable:
	var id: String = age["id"]
	var talks: Array = c.get("talks", {}).get(id, [])
	var total := int(age.get("people", 100))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41 + total
	var streets: Array = fab["streets"]
	var ground := func(q: Vector3) -> float: return RomeMap.ground(q)
	var hot: Array = HOTSPOTS.get(id, HOTSPOTS["empire"])
	var weight := 0.0
	for h: Array in hot:
		weight += float(h[1])
	var edge := RomeMap.walkable()
	# a spot on a street near one of the places where the city crowds together in this age
	var street_spot := func() -> Dictionary:
		var pick := rng.randf() * weight
		var centre := Vector3.ZERO
		for h: Array in hot:
			pick -= float(h[1])
			if pick <= 0.0:
				centre = RomeMap.at(h[0])
				break
		for tries in 60:
			var pts: Array = streets[rng.randi() % streets.size()]
			var k := rng.randi_range(0, pts.size() - 2)
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[k + 1]
			var p := a.lerp(b, rng.randf())
			if Vector2(p.x - centre.x, p.z - centre.z).length() > 110.0 or not RomeMap.inside(edge, p):
				continue
			var dir := (b - a).normalized()
			var q := p + Vector3(dir.z, 0, -dir.x) * rng.randf_range(-2.4, 2.4)
			q.y = RomeMap.ground(q)
			return {"at": q, "dir": dir}
		return {}
	var walk_path := func(spot: Dictionary) -> Array:  # up and down a stretch of the street
		var at: Vector3 = spot["at"]
		var dir: Vector3 = spot["dir"]
		var reach := rng.randf_range(12.0, 40.0)
		var path: Array = []
		var n := int(reach / 6.0)
		for i in range(-n, n + 1):
			var q := at + dir * (reach * i / maxf(n, 1))
			q.y = RomeMap.ground(q)
			path.append(q)
		var back := path.duplicate()
		back.reverse()
		return path + back.slice(1, back.size() - 1)
	# someone of a trade, dressed for it, named, and ready to talk
	var citizen := func(job_id: String, at: Vector3, yaw: float) -> Dictionary:
		var who := Citizen.make(rng, job_id, id, homes)
		var p := _dressed(world, at, yaw, Citizen.job(job_id).get("look", {}), who["gender"], rng)
		p["citizen"] = who
		p["shift"] = SHIFTS.get(job_id, "night" if rng.randf() < 0.05 else "day")
		p["lot"] = rng.randf()
		p["ground"] = ground
		people.append(p)
		out.append({"kind": "citizen", "pos": at, "follow": p["root"], "citizen": who,
			"text": "Talk to %s, the %s" % [who["call"], who["title"]]})
		return p
	var jobs: Array = Citizen.jobs_for(id).filter(func(j: Dictionary) -> bool: return j["place"] != "patrol")
	var bag: Array = []
	for j: Dictionary in jobs:
		for k in (4 if COMMON.has(j["id"]) else 1):
			bag.append(j)

	# the patrol, walking the streets in step
	var patrol_job: String = PATROLS[id]
	for k in (3 if id != "fall" else 2):
		var spot: Dictionary = street_spot.call()
		if spot.is_empty():
			continue
		var path: Array = walk_path.call(spot)
		for j in (4 if id != "fall" else 3):
			var offset := Vector3(0.9 * (j % 2) - 0.45, 0, -1.6 * (j / 2))
			var p: Dictionary = citizen.call(patrol_job, (path[0] as Vector3) + offset, 0.0)
			p["path"] = path.map(func(q: Vector3) -> Vector3: return q + offset)
			p["speed"] = 1.3
			p["ground"] = ground
		if id == "republic":  # the praetor they walk before
			var mag := Rome.togatus(world, (path[0] as Vector3) + Vector3(0, 0, -4.0), 0.0, {"praetexta": true, "hair_color": "4a3a2a"})
			mag["path"] = path.map(func(q: Vector3) -> Vector3: return q + Vector3(0, 0, -4.0))
			mag["speed"] = 1.3
			mag["ground"] = ground
			people.append(mag)

	# knots of people talking together, by the monuments and the fountains
	var gathering: Array = (fab["monuments"] as Array).filter(func(s: Dictionary) -> bool: return s["state"] == "whole").map(
		func(s: Dictionary) -> Vector3: return _front(s))
	gathering.append_array(fab.get("fountains", []))
	gathering = gathering.filter(func(q: Vector3) -> bool: return RomeMap.inside(edge, q))
	gathering.shuffle()
	for k in mini(12 if id != "fall" else 3, gathering.size()):
		if talks.is_empty():
			break
		var at: Vector3 = gathering[k] + Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(2.0, 4.0))
		at.y = RomeMap.ground(at)
		var talk: Array = talks[k % talks.size()]
		for j in talk.size():
			var a := TAU * j / talk.size()
			var job: Dictionary = bag[rng.randi() % bag.size()]
			var spot := at + Vector3(cos(a), 0, sin(a)) * 0.95
			var p: Dictionary = citizen.call(job["id"], spot, Kit.face_yaw(spot, at))
			p["shift"] = "day"
		out.append({"kind": "person", "pos": at, "text": "Listen to them talking", "note": "\n".join(talk)})

	# everyone else, at their trades
	var stalls: Array = fab.get("stalls", [])
	var shops: Array = fab.get("doors", [])
	var temples: Array = (fab["monuments"] as Array).filter(func(s: Dictionary) -> bool: return s["m"]["kind"] == "temple" and s["state"] == "whole")
	var banks: Array = fab.get("banks", [])
	var guard := 0
	while people.size() < total and guard < total * 4:
		guard += 1
		var job: Dictionary = bag[rng.randi() % bag.size()]
		match str(job["place"]):
			"stall":
				if stalls.is_empty():
					continue
				var at: Vector3 = stalls.pop_at(rng.randi() % stalls.size())
				if not RomeMap.inside(edge, at):
					continue
				at.y = RomeMap.ground(at)
				var yaw := rng.randf() * TAU
				_stall(world, at, yaw, rng)
				citizen.call(job["id"], at + Basis(Vector3.UP, yaw) * Vector3(0, 0, -1.0), yaw)
			"door":
				if shops.is_empty():
					continue
				var door: Array = shops.pop_at(rng.randi() % shops.size())
				citizen.call(job["id"], door[0], door[1])
			"river":
				if banks.is_empty():
					continue
				var bank: Vector3 = banks[rng.randi() % banks.size()] + Vector3(rng.randf_range(-6.0, 6.0), 0, rng.randf_range(-6.0, 6.0))
				bank.y = RomeMap.ground(bank)
				citizen.call(job["id"], bank, rng.randf() * TAU)
			"temple":
				if temples.is_empty():
					continue
				var front := _front(temples[rng.randi() % temples.size()]) + Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(-2.0, 2.0))
				front.y = RomeMap.ground(front)
				citizen.call(job["id"], front, rng.randf() * TAU)
			_:  # walking the street, or standing about in it
				var spot: Dictionary = street_spot.call()
				if spot.is_empty():
					continue
				var p: Dictionary = citizen.call(job["id"], spot["at"], rng.randf() * TAU)
				if job["place"] == "walk" or rng.randf() < 0.3:
					p["path"] = walk_path.call(spot)
					p["speed"] = rng.randf_range(0.8, 1.3)
					p["ground"] = ground
				if job["id"] == "senator" and id != "fall":  # and his clients at his heels
					for j in rng.randi_range(1, 2):
						var off := Vector3(0.8 * (j * 2 - 3), 0, -1.4)
						var client: Dictionary = citizen.call("cliens" if id != "fall" else "servus", (spot["at"] as Vector3) + off, 0.0)
						if p.has("path"):
							client["path"] = (p["path"] as Array).map(func(q: Vector3) -> Vector3: return q + off)
							client["speed"] = p["speed"]
							client["ground"] = ground
	life.people = people
	return citizen


## The regulars (town.json): the same few people in the same places, visit after visit, and their
## families after them in the later ages.
static func _regulars(spawn: Callable, age: String, out: Array) -> void:
	for r: Dictionary in Town.data().get("regulars", []):
		var names: Dictionary = r["names"]
		if not names.has(age):
			continue
		var at := RomeMap.on_ground(r["at"])
		var p: Dictionary = spawn.call(str(r.get("jobs", {}).get(age, r["job"])), at, 0.0)
		var who: Dictionary = p["citizen"]
		who["id"] = "regular_%s_%s" % [r["id"], age]
		who["name"] = names[age]
		who["call"] = str(names[age]).split(" ")[0].trim_suffix(",")
		who["regular"] = r["id"]
		who["regular_lines"] = r["lines"].get(age, [])
		p["shift"] = "day"
		p.erase("path")
		for it: Dictionary in out:
			if it.get("follow") == p["root"]:
				it["text"] = "Talk to %s, the %s" % [who["call"], who["title"]]


## A crowd far down the street is not drawn, and casts no shadows.
static func _cull(people: Array) -> void:
	for p: Dictionary in people:
		for mi: Node in (p["root"] as Node3D).find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = 140.0
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A person dressed for their trade (people.json's "look"): the toga for citizens on business,
## a tunic of their trade's colour (no two quite the same), and what marks them out: an apron, a
## tray, a load on the head, a scroll, a helmet, the lictor's fasces, a headcloth, a hood, long hair.
static func _dressed(world: Node3D, at: Vector3, yaw: float, look: Dictionary, gender: String, rng: RandomNumberGenerator) -> Dictionary:
	var shade := Color("#" + str(look.get("robe", "7a6a58")))
	shade = shade.lightened(rng.randf_range(0.0, 0.15)) if rng.randf() < 0.5 else shade.darkened(rng.randf_range(0.0, 0.15))
	var hair: String = ["2a1e14", "3a2a1e", "4a3a2a", "5a4a3a", "8a7a6a", "c8c0b0"][rng.randi() % 6]
	var skin: String = ["c8a078", "b88a64", "d8b08a", "a07850", "8a6040"][rng.randi() % 5]
	var dress := {"robe": shade.to_html(false), "hair_color": hair, "skin": skin,
		"beard": look.get("beard", "short" if gender == "m" and rng.randf() < 0.3 else "none")}
	var p: Dictionary
	if look.get("toga", false) and gender == "m":
		dress["stripe"] = look.get("stripe", false)
		dress["scroll"] = rng.randf() < 0.3
		p = Rome.togatus(world, at, yaw, dress)
	else:
		p = Kit.walker(world, at, yaw, dress)
	var head: Node3D = p["head"]
	var root: Node3D = p["root"]
	var hand: Node3D = p["hand"]
	if gender == "f" or look.get("long_hair", false):
		Kit.box(head, Vector3(0, -0.02, -0.12), Vector3(0.26, 0.26, 0.08), "#" + hair, false)
		Kit.blob(head, Vector3(0, 0.12, -0.14), 0.07, "#" + hair)  # hair in a knot
		Kit.cylinder(root, Vector3(0, 0.05, 0), 0.27, 0.8, "#" + shade.to_html(false), false, 8, 0.24)  # the long dress
	if look.get("apron", false):
		Kit.box(root, Vector3(0, 0.75, 0.2), Vector3(0.36, 0.6, 0.03), "#d8ccb0", false)
	if look.get("tray", false):
		Kit.box(hand, Vector3(0.3, 1.36, 0.42), Vector3(0.5, 0.05, 0.34), "wood", false)
		for k in 3:
			Kit.cylinder(hand, Vector3(0.18 + k * 0.12, 1.39, 0.42), 0.035, 0.03, "#8a4a2a", false, 6)
	if look.get("load", false):
		Kit.box(head, Vector3(0, 0.36, 0), Vector3(0.5, 0.3, 0.4), "wicker", false)
	if look.get("scroll", false):
		Kit.mesh(root, Kit._cyl(0.04, 0.26), "parchment", Vector3(-0.3, 0.9, 0.12), Vector3(0, 0, PI / 2.0))
	var helmet: String = look.get("helmet", "")
	if helmet != "":
		Kit.blob(head, Vector3(0, 0.16, -0.01), 0.16, helmet, Vector3(1.0, 0.75, 1.05), 8)
		Kit.box(head, Vector3(0, 0.33, -0.01), Vector3(0.03, 0.08, 0.22), "#8a2a2a", false)  # the crest
	if look.get("fasces", false):
		Rome.fasces(root, Vector3(0.36, 0.0, 0.18), true)
	if look.get("headcloth", false):
		Kit.blob(head, Vector3(0, 0.14, -0.03), 0.17, "#e8e0d0", Vector3(1.0, 0.9, 1.1), 8)
	if look.get("hood", false):
		Kit.blob(head, Vector3(0, 0.12, -0.05), 0.19, "#" + shade.to_html(false), Vector3(1.0, 1.1, 1.1), 8)
	return p


## A market stall: a trestle table under a striped awning on poles, laid with its wares (fruit,
## fish, pots, cloth, bread), a basket or two beside it.
static func _stall(world: Node3D, at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var g := Kit.group(world, at, yaw)
	Kit.box(g, Vector3(0, 0.8, 0), Vector3(2.2, 0.1, 0.9), "wood")
	for x: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(x, 0.4, 0), Vector3(0.1, 0.8, 0.8), "wood", false)
		Kit.box(g, Vector3(x, 1.3, -0.5), Vector3(0.08, 2.6, 0.08), "wood", false)
	Kit.box(g, Vector3(0, 2.5, -0.1), Vector3(2.5, 0.05, 1.5), "awning", false, Vector3(0.25, 0, 0))
	var wares: Array = [["#c8402a", 0.09], ["#e0a030", 0.08], ["#6a8a3a", 0.09], ["#8a9aa8", 0.12], ["#c8b080", 0.11], ["#7a3a5a", 0.07]]
	var ware: Array = wares[rng.randi() % wares.size()]
	for k in 10:
		Kit.blob(g, Vector3(-0.9 + (k % 5) * 0.45, 0.9, -0.2 + (k / 5) * 0.4), float(ware[1]), ware[0], Vector3(1.0, 0.8, 1.0), 5)
	Kit.cylinder(g, Vector3(1.4, 0, 0.3), 0.3, 0.5, "wicker", false, 8)
	if rng.randf() < 0.5:
		Kit.amphora(g, Vector3(-1.5, 0, 0.2))
