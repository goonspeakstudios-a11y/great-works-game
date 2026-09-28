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

## How each kind of person looks, and what they are called when you go to listen.
const LOOKS := {
	"merchant": [{"robe": "8a6a4a", "hair_color": "3a2a1e", "who": "a shopkeeper"}, {"robe": "a07a4a", "beard": "short", "who": "a stallholder"},
		{"robe": "6a5a3a", "hair_color": "2a1e14", "who": "a seller"}],
	"plebeian": [{"robe": "7a6a58", "who": "a citizen of the plebs"}, {"robe": "8a7054", "beard": "short", "who": "a workman"},
		{"robe": "5a5448", "hair_color": "2a1e14", "who": "a porter", "load": true}, {"robe": "9a8a6a", "who": "a townswoman", "long_hair": true}],
	"peregrinus": [{"robe": "3a5a8a", "beard": "short", "who": "a Greek"}, {"robe": "6a7a3a", "hair_color": "a8743a", "who": "a Gaul", "long_hair": true},
		{"robe": "8a2a4a", "who": "a Syrian", "headcloth": true}, {"robe": "e8e2d2", "skin": "8a5e3a", "who": "an Egyptian"},
		{"robe": "d8d0c0", "beard": "long", "who": "a Jew of the city"}, {"robe": "7a6a5a", "beard": "long", "hair_color": "c8a060", "who": "a German"}],
	"cleric": [{"robe": "2a2622", "beard": "short", "who": "a priest"}, {"robe": "5a4a3a", "who": "a monk", "hood": true}],
}
## Where the city crowds together in each age: [map position, share of the people].
const HOTSPOTS := {
	"republic": [[[0, 10], 0.3], [[-290, -367], 0.15], [[522, 367], 0.15], [[41, -600], 0.08], [[-760, 200], 0.1],
		[[-560, -700], 0.1], [[260, -200], 0.12]],
	"empire": [[[0, 10], 0.22], [[560, -222], 0.15], [[522, 367], 0.12], [[-290, -367], 0.1], [[-688, 710], 0.12],
		[[-20, 300], 0.1], [[41, -600], 0.08], [[260, -200], 0.11]],
	"late": [[[0, 10], 0.22], [[560, -222], 0.15], [[522, 367], 0.12], [[-290, -367], 0.08], [[-688, 710], 0.12],
		[[-20, 300], 0.08], [[1698, -700], 0.1], [[260, -200], 0.13]],
	"fall": [[[-800, 450], 0.5], [[-688, 710], 0.15], [[0, 10], 0.15], [[1698, -700], 0.2]],
}
## What the patrol is in each age, and how its men are dressed.
const PATROLS := {
	"republic": {"who": "a lictor of the praetor", "robe": "e8e2d2", "fasces": true},
	"empire": {"who": "a watchman of the vigiles", "robe": "7a3a2a", "helmet": "bronze"},
	"late": {"who": "a soldier of the Urban Prefect", "robe": "8a2a2a", "helmet": "iron"},
	"fall": {"who": "a soldier of the Emperor's garrison", "robe": "5a5a6a", "helmet": "iron"},
}
## The music of the city in each age: which of the Rome zone's layers play (music.gd).
const MUSIC := {"republic": ["lamps", "sun", "teacher", "walkway"], "empire": ["lamps", "sun", "teacher", "walkway"],
	"late": ["lamps", "sun", "teacher"], "fall": []}


static func urbs(world: Node3D, doors: Array, progress: RefCounted, age_index: int) -> Dictionary:
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
	out.append({"kind": "rome_age", "pos": navel, "to": age_index + 1, "text": str(age.get("navel", "Let the years pass")),
		"note": str(c["navel"].get("note", ""))})
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
	_people(world, c, age, fab, people, out)
	_cull(people)
	var birds: Array = Kit.flock(world, Vector3(0, 0, 0), 9 if id != "fall" else 4, 40.0, 26.0)
	var regions: Array = []
	var ab: Dictionary = c.get("abitato", {})
	for r: Dictionary in c.get("regions", []):
		var name: String = r.get(id if r.has(id) else ("republic" if id == "republic" else "empire"), "")
		var centre := RomeMap.at(r["at"])
		if id == "fall" and centre.distance_to(RomeMap.at(ab.get("at", [0, 0]))) > RomeMap.span(float(ab.get("radius", 500))):
			name += ", empty"
		regions.append({"c": Vector2(centre.x, centre.z), "r": RomeMap.span(float(r["r"])), "name": name})
	return {"name": "Rome, %s" % age["when"], "interactables": out, "spawn": arrival + Vector3(0, 0.05, 0),
		"yaw": Places.look_yaw(arrival_to - arrival), "spots": spots, "flicker": flicker, "people": people, "squads": squads,
		"restored": 0, "sway": [], "birds": birds, "back": MUSIC.get(id, []), "arrivals": arrivals, "regions": regions,
		"age": id, "line": str(age.get("line", ""))}


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


## The people of the city in its age: at stalls, on patrol, walking the streets, standing in
## knots to argue. Each will say something of their own time when you listen.
static func _people(world: Node3D, c: Dictionary, age: Dictionary, fab: Dictionary, people: Array, out: Array) -> void:
	var id: String = age["id"]
	var lines: Dictionary = c.get("people", {}).get(id, {})
	var talks: Array = c.get("talks", {}).get(id, [])
	var total := int(age.get("people", 100))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41 + total
	var streets: Array = fab["streets"]
	var fall := id == "fall"
	var abitato := RomeMap.at(c.get("abitato", {}).get("at", [-800, 450]))
	var ground := func(q: Vector3) -> float: return RomeMap.ground(q)
	# a spot on a street near one of the places where the city crowds together in this age
	var hot: Array = HOTSPOTS.get(id, HOTSPOTS["empire"])
	var weight := 0.0
	for h: Array in hot:
		weight += float(h[1])
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
			if Vector2(p.x - centre.x, p.z - centre.z).length() > 110.0:
				continue
			var dir := (b - a).normalized()
			var side := Vector3(dir.z, 0, -dir.x) * rng.randf_range(-2.4, 2.4)
			var q := p + side
			q.y = RomeMap.ground(q)
			return {"at": q, "dir": dir}
		return {}
	var say := func(kind: String) -> String:
		var list: Array = lines.get(kind, [])
		return str(list[rng.randi() % list.size()]) if not list.is_empty() else ""
	var listen := func(person: Dictionary, who: String, line: String) -> void:
		if line == "":
			return
		out.append({"kind": "person", "pos": person["root"].position,
			"follow": person["root"], "text": "Listen to %s" % who, "note": "[i]%s[/i]\n\n\"%s\"" % [_title(who), line]})
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

	# shopkeepers at their stalls along the streets
	var stalls: Array = fab.get("stalls", [])
	var n_merchants := int(total * (0.16 if not fall else 0.1))
	for k in mini(n_merchants, stalls.size()):
		var spot: Vector3 = stalls[rng.randi() % stalls.size()]
		if not fall and Vector2(spot.x, spot.z).length() > 420.0 and rng.randf() < 0.5:
			spot = stalls[rng.randi() % stalls.size()]
		spot.y = RomeMap.ground(spot)
		var yaw := rng.randf() * TAU
		_stall(world, spot, yaw, rng)
		var look: Dictionary = LOOKS["merchant"][rng.randi() % LOOKS["merchant"].size()]
		var p := _person(world, spot + Basis(Vector3.UP, yaw) * Vector3(0, 0, -1.0), yaw, look)
		people.append(p)
		listen.call(p, look["who"], say.call("merchant"))

	# the patrols, walking the streets in step
	var patrol: Dictionary = PATROLS[id]
	for k in (3 if not fall else 2):
		var spot: Dictionary = street_spot.call()
		if spot.is_empty():
			continue
		var path: Array = walk_path.call(spot)
		for j in (4 if not fall else 3):
			var look := {"robe": patrol["robe"], "hair_color": "2a1e14", "helmet": patrol.get("helmet", ""), "fasces": patrol.get("fasces", false)}
			var offset := Vector3(0.9 * (j % 2) - 0.45, 0, -1.6 * (j / 2))
			var p := _person(world, (path[0] as Vector3) + offset, 0.0, look)
			p["path"] = path.map(func(q: Vector3) -> Vector3: return q + offset)
			p["speed"] = 1.3
			p["ground"] = ground
			people.append(p)
			if j == 0:
				listen.call(p, patrol["who"], say.call("patrol"))
		if id == "republic":  # the praetor they walk before
			var mag := Rome.togatus(world, (path[0] as Vector3) + Vector3(0, 0, -4.0), 0.0, {"praetexta": true, "hair_color": "4a3a2a"})
			mag["path"] = path.map(func(q: Vector3) -> Vector3: return q + Vector3(0, 0, -4.0))
			mag["speed"] = 1.3
			mag["ground"] = ground
			people.append(mag)

	# senators and the rich, with their clients at their heels
	for k in int(total * (0.1 if not fall else 0.07)):
		var spot: Dictionary = street_spot.call()
		if spot.is_empty():
			continue
		var path: Array = walk_path.call(spot)
		var lead := Rome.togatus(world, path[0], 0.0, {"stripe": true, "beard": "none" if id == "republic" else "short",
			"hair_color": "d0ccc4" if rng.randf() < 0.4 else "3a2a1e", "scroll": rng.randf() < 0.3})
		lead["path"] = path
		lead["speed"] = 0.9
		lead["ground"] = ground
		people.append(lead)
		listen.call(lead, "a senator" if id != "fall" else "one of the last senators", say.call("patrician"))
		for j in rng.randi_range(1, 2):
			var off := Vector3(0.8 * (j * 2 - 3), 0, -1.4)
			var client := Rome.togatus(world, (path[0] as Vector3) + off, 0.0, {"hair_color": "2a1e14"})
			client["path"] = path.map(func(q: Vector3) -> Vector3: return q + off)
			client["speed"] = 0.9
			client["ground"] = ground
			people.append(client)

	# knots of people arguing, where people gather: by the monuments and the fountains
	var gathering: Array = (fab["monuments"] as Array).filter(func(s: Dictionary) -> bool: return s["state"] == "whole").map(
		func(s: Dictionary) -> Vector3: return _front(s))
	gathering.append_array(fab.get("fountains", []))
	gathering.shuffle()
	var n_talks := 10 if not fall else 4
	for k in mini(n_talks, gathering.size()):
		if talks.is_empty():
			break
		var at: Vector3 = gathering[k] + Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(2.0, 4.0))
		if fall and at.distance_to(abitato) > 300.0 and k > 1:
			continue
		at.y = RomeMap.ground(at)
		var talk: Array = talks[k % talks.size()]
		var who: Array = []
		for j in talk.size():
			var a := TAU * j / talk.size()
			var look: Dictionary = _any_look(rng, id)
			var p := _person(world, at + Vector3(cos(a), 0, sin(a)) * 0.9, 0.0, look)
			p["root"].rotation.y = Kit.face_yaw(p["root"].position, at)
			people.append(p)
			who.append(p)
		out.append({"kind": "person", "pos": at, "text": "Listen to them talking", "note": "\n".join(talk)})

	# the rest: the plebs, strangers, the clergy, some walking and some standing about
	var placed := people.size()
	var kinds := ["plebeian", "plebeian", "plebeian", "peregrinus"]
	if id in ["late", "fall"]:
		kinds.append("cleric")
	if fall:
		kinds = ["plebeian", "cleric", "cleric", "peregrinus"]
	for k in maxi(0, total - placed):
		var spot: Dictionary = street_spot.call()
		if spot.is_empty():
			continue
		var kind: String = kinds[rng.randi() % kinds.size()]
		var look: Dictionary = LOOKS[kind][rng.randi() % LOOKS[kind].size()]
		var p := _person(world, spot["at"], rng.randf() * TAU, look)
		if rng.randf() < 0.55:
			p["path"] = walk_path.call(spot)
			p["speed"] = rng.randf_range(0.8, 1.3)
			p["ground"] = ground
		people.append(p)
		if rng.randf() < 0.6:
			listen.call(p, look["who"], say.call(kind))


## A crowd far down the street is not drawn, and casts no shadows.
static func _cull(people: Array) -> void:
	for p: Dictionary in people:
		for mi: Node in (p["root"] as Node3D).find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = 140.0
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Someone to stand in a knot of talkers: whoever the age has most of.
static func _any_look(rng: RandomNumberGenerator, age: String) -> Dictionary:
	var kinds := ["plebeian", "plebeian", "peregrinus", "merchant"]
	if age in ["late", "fall"]:
		kinds.append("cleric")
	var kind: String = kinds[rng.randi() % kinds.size()]
	return LOOKS[kind][rng.randi() % LOOKS[kind].size()]


## A person of the city: a walker (kit.gd's) in their clothes, with what marks them out: a helmet,
## the lictor's fasces, a load on the head, a headcloth, a hood, long hair.
static func _person(world: Node3D, at: Vector3, yaw: float, look: Dictionary) -> Dictionary:
	var p := Kit.walker(world, at, yaw, look)
	var head: Node3D = p["head"]
	var root: Node3D = p["root"]
	var helmet: String = look.get("helmet", "")
	if helmet != "":
		Kit.blob(head, Vector3(0, 0.16, -0.01), 0.16, helmet, Vector3(1.0, 0.75, 1.05), 8)
		Kit.box(head, Vector3(0, 0.33, -0.01), Vector3(0.03, 0.08, 0.22), "#8a2a2a", false)  # the crest
	if look.get("fasces", false):
		Rome.fasces(root, Vector3(0.36, 0.0, 0.18), true)
	if look.get("load", false):
		Kit.box(head, Vector3(0, 0.36, 0), Vector3(0.5, 0.3, 0.4), "wicker", false)
	if look.get("headcloth", false):
		Kit.blob(head, Vector3(0, 0.14, -0.03), 0.17, "#e8e0d0", Vector3(1.0, 0.9, 1.1), 8)
	if look.get("hood", false):
		Kit.blob(head, Vector3(0, 0.12, -0.05), 0.19, "#" + str(look.get("robe", "5a4a3a")), Vector3(1.0, 1.1, 1.1), 8)
	if look.get("long_hair", false):
		Kit.box(head, Vector3(0, -0.05, -0.12), Vector3(0.24, 0.3, 0.08), "#" + str(look.get("hair_color", "5a4a3a")), false)
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
