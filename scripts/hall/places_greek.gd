extends RefCounted
## The places of the Greek books from the fourth on, built like places.gd's villa and Lyceum (the
## same returned dictionary, the same lost-to-whole pieces, a lesson stone with a scene for every
## point) out of the kits made for them: kit_rome.gd, kit_greek.gd, the areas in
## kit_greek_areas.gd, and their people and props. Where a book is played, its moments are beats
## (beat.gd, content/greece/beats.json): an interactable {"kind": "beat"} that also carries its
## lesson point, so it counts like a stone.
##   domus()   #4 the Rhetorica ad Herennium: a house in Rome, its memory house, the court in the Forum
##   museum()  #5 Euclid: the Museum at Alexandria, Proposition 1 on the sand, Proposition 47 in tiles
##   troy()    #6 Homer: the camp by the ships, the walls of Troy, and the voyage home to Ithaca

const Kit := preload("res://scripts/hall/kit.gd")
const Places := preload("res://scripts/hall/places.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Areas := preload("res://scripts/hall/kit_greek_areas.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")


## A place's name as the corner shows it.
static func _name(room: Dictionary) -> String:
	return "%s - %s" % [room.get("where", ""), room.get("when", "")]


## The gateway back to the Shore at the south end, and the path north from it with the room's facts
## on steles either side. Returns the path's far end.
static func _arrival(world: Node3D, room: Dictionary, out: Array, spots: Dictionary, flicker: Array, gate_z: float,
		path_to: float, path_mat: String = "path") -> void:
	var gate_at := Vector3(0, 0, gate_z)
	flicker.append(Kit.gateway(world, gate_at, Kit.face_yaw(gate_at, Vector3(0, 0, path_to)), true))
	out.append({"kind": "gate", "pos": Vector3(0, 0, gate_z - 1.7), "to": "hub", "open": true, "text": "Back to the Shore"})
	Kit.box(world, Vector3(0, 0.01, (gate_z + path_to) / 2.0), Vector3(3.0, 0.02, gate_z - path_to), path_mat, false)
	var facts: Array = room.get("facts", [])
	for k in facts.size():
		var side := -1.0 if k % 2 == 0 else 1.0
		var at := Vector3(2.7 * side, 0, gate_z - 4.0 - k * 2.9)
		var reader := Vector3(0.9 * side, 0, at.z)
		Kit.stele(world, at, Kit.face_yaw(at, reader))
		spots["fact%d" % k] = reader
		out.append({"kind": "fact", "pos": reader, "text": facts[k]})


## The teacher, as himself or his shade, with the interactable to talk to him.
static func _teacher(world: Node3D, room: Dictionary, b: Array, stage: int, at: Vector3, yaw: float, talk_at: Vector3,
		out: Array, spots: Dictionary, verb: String = "Talk to") -> Dictionary:
	var t := Kit.teacher(world, at, yaw, room.get("portrait", {}))
	if not b.has("teacher"):
		Places._haunt(t, stage)
	out.append({"kind": "author", "pos": talk_at, "text": "%s %s" % [verb, Places._who(room, b)]})
	spots["author"] = talk_at
	return t


## The room's busts, its map on a board, and the book on its stand.
static func _study(world: Node3D, room: Dictionary, out: Array, spots: Dictionary, busts: Array, map_at: Vector3,
		map_yaw: float, map_read: Vector3, book_at: Vector3, book_read: Vector3) -> void:
	var statues: Array = room.get("statues", [])
	for k in mini(statues.size(), busts.size()):
		var at: Vector3 = busts[k][0]
		Kit.bust(world, at, busts[k][1], statues[k])
		out.append({"kind": "statue", "pos": busts[k][2], "text": "Look at the bust of %s" % statues[k]["name"], "note": statues[k]["note"]})
		spots["statue%d" % k] = busts[k][2]
	if room.has("map"):
		var tex := load("res://assets/maps/%s.png" % room["map"]) as Texture2D
		if tex:
			Kit.board(world, map_at, map_yaw, Vector2(2.9, 2.0), tex)
			out.append({"kind": "map", "pos": map_read, "map": room["map"], "text": "Study the map of the world in %s" % room.get("when", "").trim_prefix("about "),
				"note": room.get("map_note", "")})
			spots["map"] = map_read
	Kit.box(world, book_at + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(world, book_at + Vector3(0, 1.05, 0), Vector3(0.45, 0.06, 0.6), "parchment", false)
	out.append({"kind": "book", "pos": book_read, "text": "Read a page of the %s" % room["book"]})
	spots["book"] = book_read


## A lesson stone: something to look at that carries a point of the lesson.
static func _stone(out: Array, work: String, room: Dictionary, id: String, at: Vector3, text: String) -> Dictionary:
	var it := {"kind": "look", "pos": at, "work": work, "id": id, "text": text, "note": Places._lesson(room, id).get("point", "")}
	out.append(it)
	return it


# ---------- #4 the Rhetorica ad Herennium ----------

## A house in Rome, about 85 BC, where the unnamed Author writes for Gaius Herennius. The path from
## the gateway runs north to the street door of an atrium house: the rain pool under the opening in
## the roof, the household shrine, the busts, the map, and the tablinum at the back where he sits at
## his desk. West along the street is a memory house, a quiet peristyle whose colonnade is marked
## out in twenty places, the first four holding their striking images; east is a court in the
## Forum, the praetor on his tribunal, the jurors on their benches, the water clock, the crowd.
## Lost, the roof of the atrium has fallen into the dry pool, the court's portico is down, the lamps
## are cold and the crowd are shades; it comes back piece by piece.
static func domus(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 8), 34.0)
	var ab: Array = b.duplicate()  # what the kit pieces see: the garden is green once the water is back
	if b.has("water"):
		ab.append("leaves")
	var leaves := ab.has("leaves")
	var lamps := b.has("lamps")
	Kit.plateau(world, 70.0, "earth", false)
	Rome.far_city(world, Vector3.ZERO, 85.0, 170.0, 60, 85)  # Rome all round, roofs to the hills
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 10), 5, 14.0, 12.0) if leaves else []
	_arrival(world, room, out, spots, flicker, 42.0, 20.0, "basalt")
	Kit.box(world, Vector3(0, 0.01, 24.0), Vector3(76.0, 0.02, 4.0), "basalt", false)  # the street, west to east
	Rome.fountain(world, Vector3(5.0, 0, 26.6), PI, b.has("water"))
	sway.append(Rome.pergola(world, Vector3(-10.0, 0, 30.0), 0.0, 6.0, leaves))
	for p: Vector3 in [Vector3(-14, 0, 34), Vector3(12, 0, 33), Vector3(-6, 0, 36)]:
		sway.append(Rome.stone_pine(world, p, 0.9, leaves))

	# the house: the atrium, and the tablinum where he sits at his desk
	var house := Vector3(0, 0, 12)
	Rome.atrium(world, house, 0.0, b.has("water"))
	flicker.append(Kit.desk(world, Vector3(0, 0, 3.7), PI, false, lamps))
	var author := _teacher(world, room, b, stage, Vector3(0, 0, 2.9), 0.0, Vector3(0, 0, 5.8), out, spots)
	people.append(author)
	Rome.capsa(world, Vector3(1.3, 0, 2.6), b.has("teacher"))
	Rome.lararium(world, Vector3(-5.6, 0, 10.5), PI / 2.0, b.has("household"))
	for x: float in [-4.6, 4.6]:
		flicker.append(Kit.lamp_stand(world, Vector3(x, 0, 14.8), lamps))
	_study(world, room, out, spots, [[Vector3(-4.6, 0, 6.2), 0.0, Vector3(-4.6, 0, 7.8)], [Vector3(4.6, 0, 6.2), 0.0, Vector3(4.6, 0, 7.8)]],
		Vector3(-3.9, 2.3, 18.95), PI, Vector3(-3.9, 0, 17.4), Vector3(3.9, 0, 17.6), Vector3(3.9, 0, 16.4))
	spots["atrium"] = house + Vector3(0, 0, 5.0)

	# the memory house, west along the street
	var mem_at := Vector3(-30, 0, 6)
	var mem := Areas.memory_house(world, mem_at, 0.0, ab)
	flicker.append_array(mem["flicker"])
	sway.append_array(mem["sway"])
	Kit.box(world, Vector3(-30, 0.012, 20.0), Vector3(3.0, 0.02, 4.0), "basalt", false)  # up to its door
	# the east court in the Forum
	var court_at := Vector3(30, 0, 4)
	var court := Areas.law_court(world, court_at, 0.0, ab)
	flicker.append_array(court["flicker"])
	people.append_array(court["people"])
	Kit.box(world, Vector3(30, 0.012, 18.5), Vector3(3.0, 0.02, 7.0), "basalt", false)

	flicker.append_array(_domus_lessons(world, work, room, out, spots, mem, court, b))
	out.append(Places.seat(world, Vector3(-10.0, 0, 28.0), Vector3(0, 0, 1), "Sit under the vine"))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 39.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": people, "restored": 0, "sway": sway, "birds": birds, "back": b}


## The Rhetorica's six stones: the five tasks and the six parts of a speech in the court, the three
## styles by its way in, the places and the images in the memory house, and the walk through it
## (a beat: build your own memory house, then go to court and walk it again).
static func _domus_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, mem: Dictionary,
		court: Dictionary, b: Array) -> Array:
	var flicker: Array = []

	# the five tasks: five plinths in an arc before the tribunal, each with its sign
	var fc := Vector3(30, 0, 1.2)
	for k in 5:
		var a := deg_to_rad(200.0 + k * 35.0)
		var p := fc + Vector3(cos(a), 0, -sin(a) * 0.6) * 3.0
		if k != 3:
			Kit.box(world, p + Vector3(0, 0.45, 0), Vector3(0.5, 0.9, 0.5), "marble")
		var on := p + Vector3(0, 0.9, 0)
		match k:
			0:  # invention: a lamp, to find things by
				Kit.cylinder(world, on, 0.12, 0.08, "clay", false, 8, 0.06)
				if b.has("lamps"):
					Kit.blob(world, on + Vector3(0.1, 0.12, 0), 0.04, "fire", Vector3(1.0, 1.6, 1.0), 5)
			1:  # arrangement: three tablets set in order
				for j in 3:
					Kit.box(world, on + Vector3(-0.15 + j * 0.15, 0.08, 0), Vector3(0.1, 0.16, 0.02), "wood", false)
			2:  # style: a wreath
				Kit.mesh(world, TorusMesh.new(), "olive", on + Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(0.2, 0.3, 0.2))
			3:  # memory: the golden hand on its post
				Rome.memory_image(world, p, 0.0, "golden_hand", b.has("household"))
			4:  # delivery: a speaker's raised hand
				Places._figure(world, on, 0.0, "#e8e2d2", 0.3)
	_stone(out, work, room, "five_canons", fc + Vector3(0, 0, 1.2), "Look at the five plinths")
	spots["five_canons"] = fc + Vector3(0, 0, 1.2)

	# the six parts of a speech: six small steles across the floor where the advocate walks
	for k in 6:
		var at := Vector3(24.5 + k * 2.2, 0, 7.4)
		Kit.stele(world, at, 0.0)
	_stone(out, work, room, "parts_of_speech", Vector3(30, 0, 9.0), "Walk the six stones of a speech")
	spots["parts_of_speech"] = Vector3(30, 0, 9.0)

	# the three styles: three speakers by the court's way in, grand on a high plinth, middle on a
	# low one, simple on the ground
	var sc := Vector3(21.0, 0, 21.0)
	for k in 3:
		var h: float = [1.2, 0.5, 0.0][k]
		var p := sc + Vector3(k * 1.8, 0, 0)
		if h > 0.0:
			Kit.box(world, p + Vector3(0, h / 2.0, 0), Vector3(1.0, h, 1.0), "marble")
		Rome.togatus(world, p + Vector3(0, h, 0), 0.0, [{"praetexta": true, "beard": "none", "hair_color": "3a2a1e"},
			{"stripe": true, "beard": "none", "hair_color": "5a4a3a"}, {"beard": "short", "hair_color": "4a3a2a"}][k], not b.has("household"))
	_stone(out, work, room, "three_styles", sc + Vector3(1.8, 0, 2.0), "Look at the three speakers")
	spots["three_styles"] = sc + Vector3(1.8, 0, 2.0)

	# the places: a stele at the memory house's door, and the colonnade itself
	var loci: Array = mem["loci"]
	var door := Vector3(-30, 0, 18.0)
	Kit.stele(world, door + Vector3(-2.2, 0, 0), PI / 2.0)
	_stone(out, work, room, "places", door + Vector3(-1.0, 0, 0), "Read the stone at the door")
	spots["places"] = door + Vector3(-1.0, 0, 0)

	# the images: the first four places hold theirs
	var img_at: Vector3 = (loci[1] + loci[2]) / 2.0
	var inward := (Vector3(-30, 0, 6) - img_at).normalized()
	_stone(out, work, room, "images", img_at + inward * 1.6, "Look at the strange images")
	spots["images"] = img_at + inward * 1.6

	# walking the places: your own five images, set and walked (the memory walk)
	var cast := {}
	var marks := {"court": Vector3(30, 0, 7.4)}
	var kinds := ["burning", "goat", "ear", "knife", "crowned_ass"]
	for k in 5:
		var at: Vector3 = loci[5 + k]
		marks["loc%d" % k] = at
		var node := _strange(world, at + (Vector3(-30, 0, 6) - at).normalized() * 0.8, kinds[k])
		node.visible = false
		cast["img%d" % k] = node
	out.append({"kind": "beat", "pos": door + Vector3(0, 0, -1.0), "work": work, "id": "order", "beat": "memory_walk",
		"text": "Build your own memory house", "note": Places._lesson(room, "order").get("point", ""), "cast": cast, "marks": marks})
	spots["order"] = door + Vector3(0, 0, -1.0)
	return flicker


## One of your own strange images for the memory walk: a burning man, a goat in a toga, a huge ear,
## a bloody knife, a donkey with a crown. Hidden until you set it.
static func _strange(world: Node3D, at: Vector3, kind: String) -> Node3D:
	var g := Kit.group(world, at)
	match kind:
		"burning":
			Places._figure(g, Vector3.ZERO, 0.0, "#6a5a4a")
			for p: Vector3 in [Vector3(0, 1.3, 0), Vector3(0.2, 1.7, 0.1), Vector3(-0.2, 1.6, -0.1)]:
				Kit.blob(g, p, 0.25, "fire", Vector3(1.0, 1.8, 1.0), 5)
		"goat":
			Greek.beast(g, Vector3.ZERO, 0.0, "goat")
			Kit.box(g, Vector3(0, 0.75, 0), Vector3(0.5, 0.3, 0.8), "toga", false, Vector3(0, 0, 0.2))
		"ear":
			Kit.blob(g, Vector3(0, 1.0, 0), 0.5, "#d0a080", Vector3(0.35, 1.3, 0.9), 8)
			Kit.blob(g, Vector3(0.1, 1.0, 0), 0.25, "#8a5a40", Vector3(0.3, 1.0, 0.6), 6)
		"knife":
			Kit.box(g, Vector3(0, 0.45, 0), Vector3(0.5, 0.9, 0.5), "stone")
			Kit.box(g, Vector3(0, 0.95, 0), Vector3(0.06, 0.02, 0.5), "iron", false)
			Kit.blob(g, Vector3(0, 0.92, 0.1), 0.12, "#8a1010", Vector3(1.4, 0.2, 1.4), 6)
		"crowned_ass":
			Greek.beast(g, Vector3.ZERO, 0.0, "horse", "", 0.7)
			Kit.mesh(g, TorusMesh.new(), "gold", Vector3(0, 1.45, 0.75), Vector3.ZERO, Vector3(0.12, 0.25, 0.12))
	Kit.unsolid(g)
	return g


# ---------- #5 Euclid, the Elements ----------

## Where a node stands in the world's space (the kits nest their pieces in groups).
static func _in_world(node: Node3D, world: Node3D) -> Vector3:
	var t := node.transform
	var up := node.get_parent()
	while up != null and up != world and up is Node3D:
		t = (up as Node3D).transform * t
		up = up.get_parent()
	return t.origin


## The Museum at Alexandria, about 300 BC: the court with its colonnades, cabinets of book rolls,
## date palms and sand trays, where Euclid sits drawing; west, open sand with Proposition 1 pegged
## out at walking size, two circles and a triangle; east, a terrace with the three squares of
## Proposition 47 in tiles. Lost, the palms are dead, the colonnades broken, sand drifts over the
## figures, and the scholars are shades.
static func museum(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 8), 34.0)  # the low sun, so the figures on the sand show
	Kit.plateau(world, 70.0, "earth", false)
	Kit.sea(world, -2.0)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 6), 5, 16.0, 12.0) if b.has("leaves") else []
	_arrival(world, room, out, spots, flicker, 44.0, 25.0, "paving")

	var court := Areas.museum_court(world, Vector3(0, 0, 8), 0.0, b)
	flicker.append_array(court["flicker"])
	sway.append_array(court["sway"])
	people.append_array(court["people"])
	Greek.sand_tray(world, Vector3(0, 0, 1.6), 0.0, b.has("teacher"))
	var euclid := _teacher(world, room, b, stage, Vector3(0, 0, 0.3), 0.0, Vector3(0, 0, 3.2), out, spots)
	people.push_front(euclid)
	_study(world, room, out, spots, [[Vector3(-8.5, 0, 22.0), PI, Vector3(-8.5, 0, 20.4)], [Vector3(8.5, 0, 22.0), PI, Vector3(8.5, 0, 20.4)]],
		Vector3(-15.2, 2.2, 4.5), PI / 2.0, Vector3(-13.6, 0, 4.5), Vector3(9.5, 0, 17.0), Vector3(9.5, 0, 15.8))

	var one := Areas.prop_one(world, Vector3(-38, 0, 6), 0.0, b)
	flicker.append_array(one["flicker"])
	sway.append_array(one["sway"])
	Kit.box(world, Vector3(-19.5, 0.012, 22.0), Vector3(33.0, 0.02, 2.6), "paving" if b.has("walkway") else "sand", false)
	var tiles := Areas.prop_forty_seven(world, Vector3(38, 0, 6), 0.0, b)
	flicker.append_array(tiles["flicker"])
	sway.append_array(tiles["sway"])
	Kit.box(world, Vector3(19.5, 0.012, 22.0), Vector3(33.0, 0.02, 2.6), "paving" if b.has("walkway") else "sand", false)

	flicker.append_array(_museum_lessons(world, work, room, out, spots, one, tiles, b))
	out.append(Places.seat(world, Vector3(0, 0, 30.0), Vector3(0, 0, 1), "Sit and look out to sea"))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 41.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": people, "restored": 0, "sway": sway, "birds": birds, "back": b}


## Euclid's six stones: the definitions, the postulates and the common notions in the court, the
## bridge of asses in its floor, and the two propositions played on the sand and on the tiles.
static func _museum_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, one: Dictionary,
		tiles: Dictionary, b: Array) -> Array:
	var flicker: Array = []
	var whole := b.has("walkway")

	# definitions: a point (a bronze bead on a plinth), a line (a cord between two pegs), a circle
	# (a ring of pebbles round a peg)
	var dc := Vector3(-5.5, 0, 4.0)
	Kit.box(world, dc + Vector3(-1.4, 0.45, 0), Vector3(0.4, 0.9, 0.4), "marble")
	Kit.blob(world, dc + Vector3(-1.4, 0.93, 0), 0.03, "bronze")
	for x: float in [-0.5, 0.9]:
		Kit.cylinder(world, dc + Vector3(x, 0, 0), 0.03, 0.5, "wood", false, 6)
	Kit.box(world, dc + Vector3(0.2, 0.45, 0), Vector3(1.4, 0.015, 0.015), "#c8b890", false)
	Kit.cylinder(world, dc + Vector3(0.2, 0, 1.4), 0.03, 0.3, "wood", false, 6)
	for k in 16:
		var a := TAU * k / 16.0
		Kit.blob(world, dc + Vector3(0.2 + cos(a) * 0.8, 0.04, 1.4 + sin(a) * 0.8), 0.05, "stone")
	_stone(out, work, room, "definitions", dc + Vector3(0, 0, 2.8), "Look at the point, the line and the circle")

	# postulates: a straightedge and dividers on a table, and a line ruled straight out across the
	# court and through the gateway (a line may be produced as far as you like)
	var pc := Vector3(5.5, 0, 4.0)
	Kit.box(world, pc + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 0.7), "wood" if whole else "deadwood")
	Kit.box(world, pc + Vector3(0, 0.81, 0.1), Vector3(1.0, 0.02, 0.05), "wood", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(world, pc + Vector3(0.1 * side, 0.82, -0.12), Vector3(0.02, 0.01, 0.35), "bronze", false, Vector3(0, side * 0.3, 0))
	Kit.box(world, Vector3(2.2, 0.035, 26.0), Vector3(0.04, 0.01, 40.0), "#3a3226", false)
	_stone(out, work, room, "postulates", pc + Vector3(0, 0, 1.6), "Look at the straightedge and the dividers")

	# common notions: a balance with two equal weights, and a third just like them beside it
	var nc := Vector3(5.5, 0, 12.0)
	Kit.box(world, nc + Vector3(0, 0.4, 0), Vector3(0.5, 0.8, 0.5), "marble")
	Kit.box(world, nc + Vector3(0, 1.1, 0), Vector3(0.04, 0.6, 0.04), "bronze", false)
	Kit.box(world, nc + Vector3(0, 1.4, 0), Vector3(0.9, 0.03, 0.03), "bronze", false)
	for x: float in [-0.42, 0.42]:
		Kit.cylinder(world, nc + Vector3(x, 1.1, 0), 0.12, 0.02, "bronze", false, 8)
		Kit.cylinder(world, nc + Vector3(x, 1.12, 0), 0.05, 0.08, "iron", false, 6)
	Kit.cylinder(world, nc + Vector3(0.4, 0.8, 0.3), 0.05, 0.08, "iron", false, 6)
	_stone(out, work, room, "common_notions", nc + Vector3(-1.6, 0, 0), "Look at the balance")

	# the bridge of asses: an isosceles triangle cut into the court's floor, its base angles marked
	var ic := Vector3(-5.5, 0, 13.0)
	var apex := ic + Vector3(0, 0, -2.2)
	for q: Vector3 in [ic + Vector3(-1.2, 0, 1.2), ic + Vector3(1.2, 0, 1.2)]:
		Kit.box(world, (apex + q) / 2.0 + Vector3(0, 0.04, 0), Vector3(0.05, 0.02, apex.distance_to(q)), "#3a3226", false,
			Vector3(0, atan2(q.x - apex.x, q.z - apex.z), 0))
		Kit.blob(world, q + Vector3(0, 0.04, -0.25), 0.15, "#8a1e1a", Vector3(1.0, 0.1, 1.0), 6)  # the equal angles
	Kit.box(world, ic + Vector3(0, 0.04, 1.2), Vector3(2.4, 0.02, 0.05), "#3a3226", false)
	_stone(out, work, room, "pons_asinorum", ic + Vector3(0, 0, 2.6), "Look at the triangle in the floor")

	# Proposition 1, pegged out on the sand: drive the pegs, walk the circles, find the third corner
	var corners: Array = one["corners"]
	var a: Vector3 = corners[0]
	var bb: Vector3 = corners[1]
	var c: Vector3 = corners[2]
	var marks := {"A": a, "B": bb, "C": c, "circle_a": _around(a, a.distance_to(bb)), "circle_b": _around(bb, a.distance_to(bb))}
	out.append({"kind": "beat", "pos": (a + bb) / 2.0 + (a + bb - c * 2.0).normalized() * 2.0, "work": work, "id": "prop_one",
		"beat": "rope_and_pegs", "text": "Peg out the first proposition", "note": Places._lesson(room, "prop_one").get("point", ""),
		"marks": marks})

	# Proposition 47 in tiles: step on every tile of each square and count
	var sq: Dictionary = tiles["squares"]
	var routes := {}
	for n in [3, 4, 5]:
		routes["sq%d" % n] = (sq[n] as Array).map(func(t): return _in_world(t, world))
	var t0: Vector3 = (routes["sq3"] as Array)[0] if not (routes["sq3"] as Array).is_empty() else Vector3(38, 0, 6)
	out.append({"kind": "beat", "pos": Vector3(38, 0, 13.5), "work": work, "id": "prop_47", "beat": "count_the_tiles",
		"text": "Count the three squares", "note": Places._lesson(room, "prop_47").get("point", ""), "marks": routes})
	spots["prop_47"] = t0
	return flicker


## Points round a circle on the ground, for walking it.
static func _around(centre: Vector3, r: float, count: int = 12) -> Array:
	var pts: Array = []
	for k in count + 1:
		var a := TAU * k / count
		pts.append(centre + Vector3(cos(a), 0, sin(a)) * r)
	return pts


# ---------- #6 Homer, the Iliad and the Odyssey ----------

## An island in the sea: a rock rising out of the water, flat on top, with an unseen fence round
## its edge (as the plateau has) so no one walks off into the sea.
static func _island(world: Node3D, centre: Vector3, radius: float, top: String) -> void:
	Kit.cylinder(world, centre + Vector3(0, -30, 0), radius, 30.0, "rock", true, 14)
	Kit.cylinder(world, centre + Vector3(0, -0.1, 0), radius - 0.3, 0.1, top, false, 14)  # flush with the ground, so floors built on it show
	Kit.cylinder(world, centre + Vector3(0, -34, 0), radius + 5.0, 30.0, "rock", false, 11)
	var n := 24
	for i in n:
		var a := TAU * i / n
		var at := centre + Vector3(cos(a), 0, sin(a)) * (radius - 0.8)
		var fence := BoxShape3D.new()
		fence.size = Vector3(2.0 * PI * (radius - 0.8) / n + 0.2, 8.0, 0.5)
		Kit.solid(world, fence, at + Vector3(0, 4.0, 0), Vector3(0, -a + PI / 2.0, 0))


## The sea voyage of the Odyssey: the landings the black ship sails between, always by way of the
## open sea at SEA_JUNCTION. "off" is the step ashore; each landing lists where its ferry stones
## stand (one for each other landing).
const SEA_JUNCTION := Vector3(0, -0.4, -150)
const SEA := {
	"troy": {"name": "the beach of Troy", "at": Vector3(0, -0.4, -104), "off": Vector3(0, 0, 6.5)},
	"cyclops": {"name": "the island of the Cyclops", "at": Vector3(-86, -0.4, -200), "off": Vector3(-6.5, 0, 0)},
	"sirens": {"name": "the Sirens' strait", "at": Vector3(-18, -0.4, -168), "off": Vector3(0, 0, -5.0)},
	"ocean": {"name": "the edge of Ocean", "at": Vector3(0, -0.4, -262), "off": Vector3(0, 0, -6.5)},
	"ithaca": {"name": "Ithaca", "at": Vector3(86, -0.4, -200), "off": Vector3(6.5, 0, 0)},
}


## The plain of Troy and the way home, as Homer sings it: Homer by a fire in the camp; the black
## ships drawn up on the beach, the place of assembly, Achilles' hut, Hephaestus's forge with the
## great shield laid out to walk; the walls of Troy with the Scaean gate and the springs; and from
## the beach a black ship sailing to the Cyclops' island, past the Sirens, to the edge of Ocean
## where the dead come to the blood, and home to Ithaca. Each point is a beat, played as the
## scene's hero (Achilles, Hector, Priam, Odysseus). Lost: the ships rotten, the walls down, the
## Achaeans and the Cyclops dead, the fires cold, the sea grey.
static func troy(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, -20), 60.0)
	Kit.plateau(world, 100.0, "sand", false)
	Kit.sea(world, -0.4)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, -40), 6, 20.0, 14.0) if b.has("leaves") else []
	_arrival(world, room, out, spots, flicker, 26.0, -16.0, "path")

	# Homer by his fire, between the camp and the city
	var fire := Kit.hearth(world, Vector3(0, 0, -21.0), b.has("lamps"))
	if fire:
		flicker.append(fire)
	var homer := _teacher(world, room, b, stage, Vector3(0, 0, -23.0), 0.0, Vector3(0, 0, -19.4), out, spots, "Sit with")
	Kit.lyre(world, Vector3(0.7, 0.9, -22.8), 0.0)
	_study(world, room, out, spots, [], Vector3(-4.2, 1.6, -24.0), 0.3, Vector3(-3.6, 0, -21.8), Vector3(3.6, 0, -22.0), Vector3(3.6, 0, -20.8))

	# the camp by the ships (Iliad 1), Achilles' hut (9, 24), the forge (18), the walls (6, 22)
	var camp := Areas.ships(world, Vector3(0, 0, -70), 0.0, b)
	var hut := Areas.achilles_hut(world, Vector3(50, 0, -45), 0.0, b)
	var smithy := Areas.forge(world, Vector3(-52, 0, -42), 0.0, b)
	var city := Areas.walls(world, Vector3(0, 0, 60), PI, b)
	for a: Dictionary in [camp, hut, smithy, city]:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
		squads.append_array(a["squads"])
	# Andromache and the nurse with the boy, and the old oak, before the Scaean gate
	var gate := Vector3(0, 0, 62.0)
	var andromache := People.figure(world, gate + Vector3(-1.6, 0, 1.0), PI, "andromache", not b.has("household"))
	people.append(andromache)
	sway.append(Kit.plane_tree(world, gate + Vector3(9.0, 0, -4.0), 1.2, b.has("leaves")))

	# the voyage home
	var islands := {"cyclops": [Vector3(-120, 0, -200), 32.0, "rock"],
		"sirens": [Vector3(-18, 0, -176), 6.0, "rock"], "ocean": [Vector3(0, 0, -300), 36.0, "ashbed"],
		"ithaca": [Vector3(120, 0, -200), 32.0, "grass" if b.has("leaves") else "ashbed"]}
	for k in islands:
		_island(world, islands[k][0], islands[k][1], islands[k][2])
	var cave := Areas.cyclops_cave(world, Vector3(-122, 0, -200), PI / 2.0, b)
	var dead := Areas.underworld(world, Vector3(0, 0, -305), 0.0, b)
	var home := Areas.ithaca_hall(world, Vector3(124, 0, -200), -PI / 2.0, b)
	var strait := Areas.sirens(world, Vector3(-40, 0, -150), PI, b)
	for a: Dictionary in [cave, dead, home, strait]:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
	var boats: Array = []
	var ship := Greek.ship(world, SEA["troy"]["at"] + Vector3(0, -1.2, 0), PI, "pentekonter", b.has("walkway"), false, b.has("walkway"))
	ship["speed"] = 10.0
	ship["junction"] = SEA_JUNCTION
	ship["landings"] = SEA
	ship["landing"] = "troy"
	ship["route"] = []
	ship["root"].position.y = SEA["troy"]["at"].y
	boats.append(ship)
	for from in SEA:
		var at: Vector3 = SEA[from]["at"]
		var ashore: Vector3 = Vector3(at.x, 0, at.z) + SEA[from]["off"]
		var side := Vector3(SEA[from]["off"].z, 0, -SEA[from]["off"].x).normalized()
		var k := 0
		for to in SEA:
			if to == from:
				continue
			out.append({"kind": "ferry", "pos": ashore + side * (-3.0 + k * 2.0), "boat": ship, "from": from, "to": to,
				"text": "Sail to %s" % SEA[to]["name"]})
			k += 1
	if not b.has("water"):
		out.append({"kind": "look", "pos": Vector3(4.0, 0, -97.0), "text": "Look at the sea",
			"note": "The sea is grey and still, as if it had forgotten how to move. The black ship waits at the water's edge all the same."})

	flicker.append_array(_troy_beats(world, work, room, out, spots, camp, hut, smithy, city, cave, dead, home, strait, b))
	out.append(Places.seat(world, Vector3(10.0, 0, -95.0), Vector3(0, 0, -1), "Sit and look out to sea"))
	var creep: Array = []
	for s in dead["shades"]:
		creep.append({"node": s["node"], "home": s["home"], "trench": Areas._at(dead["root"], dead["trench"]) if dead["trench"] is Vector3 else s["trench"]})
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 23.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [homer] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads,
		"boats": boats, "creep": creep, "back": b}


## Homer's eight points, each a beat seen through its hero's eyes, and the two moments that are not
## points (the Sirens, the dead at the trench).
static func _troy_beats(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, camp: Dictionary,
		hut: Dictionary, smithy: Dictionary, city: Dictionary, cave: Dictionary, dead: Dictionary, home: Dictionary,
		strait: Dictionary, b: Array) -> Array:
	var flicker: Array = []
	var beat := func(area: Dictionary, name: String, id: String, script: String, text: String, cast: Dictionary = {},
			marks: Dictionary = {}, after: String = "") -> Dictionary:
		var at: Vector3 = area["beats"][name]["at"]
		var it := {"kind": "beat", "pos": at, "start": at, "work": work, "beat": script, "text": text, "cast": cast, "marks": marks}
		if id != "":
			it["id"] = id
			it["note"] = Places._lesson(room, id).get("point", "")
		else:
			it["after"] = after
		out.append(it)
		spots[script] = at
		return it

	# Iliad 1: Athena, who comes behind you and seizes your hair
	var quarrel: Vector3 = camp["beats"]["athena_seizes_hair"]["at"]
	var athena := People.figure(world, quarrel + Vector3(0, 0, 1.4), PI, "athena", not b.has("teacher"))
	athena["root"].visible = false
	beat.call(camp, "athena_seizes_hair", "menis", "menis", "Stand in the assembly as Achilles", {"athena": athena["root"]})

	# Iliad 6: the helmet laid on the ground
	var gate_at := Vector3(0, 0, 62.0)
	var helmet := Kit.group(world, gate_at + Vector3(0.8, 0, 0.6))
	Kit.blob(helmet, Vector3(0, 0.12, 0), 0.16, "bronze" if b.has("walkway") else "verdigris", Vector3(1.0, 1.1, 1.1), 7)
	Kit.box(helmet, Vector3(0, 0.3, 0), Vector3(0.04, 0.12, 0.32), "#2a2a2a", false)
	helmet.visible = false
	out.append({"kind": "beat", "pos": gate_at, "start": gate_at, "work": work, "id": "kleos", "beat": "kleos",
		"text": "Meet Andromache at the gate, as Hector", "cast": {"helmet": helmet}, "marks": {},
		"note": Places._lesson(room, "kleos").get("point", "")})
	spots["kleos"] = gate_at

	# Iliad 9 and 24, at Achilles' hut
	beat.call(hut, "embassy", "time", "time", "Receive the embassy, as Achilles")
	beat.call(hut, "through_the_camp", "pity", "pity", "Go to Achilles by night, as Priam", {}, {"hut": hut["beats"]["kneel"]["at"]})

	# Iliad 18: the shield, laid out to walk ring by ring
	var shield: Vector3 = smithy["beats"]["the_armour"]["at"]
	var rings := {}
	for k in 4:
		var r: float = [2.5, 5.0, 8.0, 10.5][k]
		var a := 0.6 + k * 1.3
		rings["ring%d" % k] = shield + Vector3(cos(a), 0, sin(a)) * r
	beat.call(smithy, "the_armour", "shield", "shield", "Walk the shield, as Achilles", {}, rings)

	# Iliad 22: along the wall after Hector, past the springs
	var chase := [Vector3(34, 0, 60), Vector3(-34, 0, 60), Vector3(-22, 0, 56.5)]
	beat.call(city, "three_times_round", "fate", "fate", "Chase Hector round the walls, as Achilles", {},
		{"chase": chase.slice(0, 2), "springs": chase[2]})

	# Odyssey 9: the stone, the great ram, the way out
	var rams: Array = cave["rams"]
	var mouth := (cave["root"] as Node3D).transform * Vector3(0, 0, 22.0)
	beat.call(cave, "nobody", "metis", "metis", "Face the Cyclops, as Odysseus", {"stone": cave["stone"]},
		{"ram": _in_world(rams[0]["root"], world), "mouth": mouth})

	# Odyssey 21-23: the bow, and the bed
	beat.call(home, "string_the_bow", "nostos", "nostos", "Take up the bow, as Odysseus", {}, {"bed": home["beats"]["the_bed"]["at"]})

	# not points: the Sirens, and the dead at the trench (the place's horror)
	var mast := Vector3(-18, 0, -178)
	Kit.cylinder(world, mast, 0.14, 7.0, "wood" if b.has("walkway") else "deadwood", true, 6)  # a mast set up on the rock
	Kit.box(world, mast + Vector3(0, 2.2, 0), Vector3(1.6, 0.1, 0.1), "wood" if b.has("walkway") else "deadwood", false)
	out.append({"kind": "beat", "pos": mast + Vector3(0, 0, 1.0), "start": mast + Vector3(0, 0, 0.6), "face": Vector3(-60, 0, -140),
		"work": work, "beat": "sirens", "text": "Hear the Sirens, bound to the mast", "cast": {}, "marks": {},
		"after": "The song is gone astern. Circe told you: whoever hears the Sirens without being bound never sees home again."})
	beat.call(dead, "hold_the_sword", "", "trench", "Hold the dead back from the blood, as Odysseus", {}, {},
		"The dead go back into the dark. Teiresias has told you the way home, and what it will cost.")
	return flicker
