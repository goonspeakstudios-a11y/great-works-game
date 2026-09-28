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
##   academy() #7 Plato's Republic: the grove, the council table over the city in speech, and round it
##             the Republic's scenes (Cephalus's house, Gyges' chasm, the line, the cave, Er's meadow)
##             with Socrates' trial, Agathon's dinner and the prison
##   ascra()   #7 Hesiod: the farm at Ascra and Mount Helicon above it, the Muses, Chaos, Kronos
##   lesbos()  #8 Sappho: her garden above the sea on Lesbos, and the torn poems
##   argos()   #9 Aeschylus: the house of Atreus, the hill of Ares, and the theatre it was played in
##   thebes()  #10 Sophocles: Thebes in the plague, where three roads meet, Antigone's tomb, the theatre

const Kit := preload("res://scripts/hall/kit.gd")
const Places := preload("res://scripts/hall/places.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Areas := preload("res://scripts/hall/kit_greek_areas.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")
const Thinkers := preload("res://scripts/hall/kit_greek_thinkers.gd")
const City := preload("res://scripts/hall/city.gd")


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
		"text": "Meet Andromache at the gate, as Hector", "cast": {"helmet": helmet}, "marks": {"andromache": gate_at + Vector3(-1.6, 1.5, 1.0)},
		"note": Places._lesson(room, "kleos").get("point", "")})
	spots["kleos"] = gate_at

	# Iliad 9 and 24, at Achilles' hut
	beat.call(hut, "embassy", "time", "time", "Receive the embassy, as Achilles")
	var kneel: Vector3 = hut["beats"]["kneel"]["at"]
	var achilles := People.figure(world, kneel + Vector3(0, 0, -1.3), 0.0, "achilles", not b.has("teacher"), "sit")
	achilles["root"].visible = false  # in his own hut he is you, except when Priam comes
	beat.call(hut, "through_the_camp", "pity", "pity", "Go to Achilles by night, as Priam", {"achilles": achilles["root"]}, {"hut": kneel})

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


# ---------- #7 Plato, the Republic ----------

## What of the board goes as the city falls after the just city (Republic VIII-IX), a piece a
## regime: the lamps of learning (timocracy), the green of the land, drained for gold (oligarchy),
## the order of its walls and ways (democracy), and its people, shades under the tyrant.
const FALLS := ["lamps", "leaves", "walkway", "household"]
## How each part of the soul over the city burns as it falls, [light, size]: honour rules reason,
## then wealth, then every desire alike, then the worst desire alone.
const DECLINE := {
	6: {"reason": [0.8, 0.8], "spirit": [3.6, 1.3], "appetite": [2.0, 1.0]},
	7: {"reason": [0.5, 0.7], "spirit": [1.2, 0.9], "appetite": [3.4, 1.3]},
	8: {"reason": [1.4, 0.95], "spirit": [1.4, 0.95], "appetite": [1.4, 0.95]},
	9: {"reason": [0.15, 0.5], "spirit": [0.5, 0.75], "appetite": [5.0, 1.8]},
}


## A way across the ground from one spot to the next, under any floor it runs into.
static func _way(world: Node3D, points: Array) -> void:
	for k in points.size() - 1:
		var a: Vector3 = points[k]
		var c: Vector3 = points[k + 1]
		Kit.box(world, (a + c) / 2.0 + Vector3(0, 0.012, 0), Vector3(3.0, 0.02, a.distance_to(c) + 3.0), "path", false,
			Vector3(0, Kit.face_yaw(a, c), 0))


## The Academy, about 380 BC: Plato's grove of olives outside Athens, where he sits on a curved
## bench by the spring; before him the council table, where you sit with Socrates, Glaucon and
## Adeimantus and found the city in speech (city.gd, council.gd), and beyond it the board where
## the city stands as far as you have governed it, the soul rising over it once it is just and
## burning down with it as it falls. Round about stand the Republic's scenes: Cephalus's house in
## the Piraeus, Gyges' chasm, the divided line, the cave, Er's meadow, and with them the court
## where Socrates was tried, Agathon's dinner and the prison. `city_stage` is the city's stage
## (City.stage: 0 the bare site to 5 the just city, then 6 to 9 its fall). Lost, the olives are
## dead, the herms broken, the city's people and Socrates' company shades.
static func academy(world: Node3D, work: String, room: Dictionary, stage: int = 0, city_stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 70), 60.0)
	Kit.plateau(world, 150.0, "earth", false)
	Kit.sea(world, -0.4)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 118), 6, 18.0, 14.0) if b.has("leaves") else []
	var take := func(a: Dictionary) -> void:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
		squads.append_array(a["squads"])
		birds.append_array(a["birds"])
	_arrival(world, room, out, spots, flicker, 146.0, 124.0, "path")

	# the grove of Academus: the olives, the herms at the way in, the spring, and Plato on his bench
	var rng := RandomNumberGenerator.new()
	rng.seed = 387
	var clear := [Vector3(14, 0, 122), Vector3(8.6, 0, 112.4), Vector3(-8.6, 0, 112.0), Vector3(17, 0, 113)]  # the spring, the book, the map, the seat
	for k in 22:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(10.0, 30.0), 0, rng.randf_range(100.0, 138.0))
		if clear.any(func(c: Vector3) -> bool: return c.distance_to(p) < 4.0):
			continue
		sway.append(Kit.olive(world, p, rng.randf_range(1.1, 1.6), b.has("leaves")))
	for x: float in [-2.6, 2.6]:
		Greek.herm(world, Vector3(x, 0, 124.0), 0.0, "marble", b.has("walkway"))
	var spring := Vector3(14.0, 0, 122.0)
	Kit.cylinder(world, spring + Vector3(0, 0.02, 0), 2.2, 0.05, "water" if b.has("water") else "drybed", false, 14)
	for k in 12:
		var a := TAU * k / 12.0
		Kit.blob(world, spring + Vector3(cos(a) * 2.4, 0.15, sin(a) * 2.4), 0.3, "stone", Vector3(1.3, 0.6, 1.0), 5)
	var exedra := Vector3(0, 0, 114.0)
	for k in 7:  # the curved marble bench behind him
		var a := deg_to_rad(200.0 + k * 140.0 / 6.0)
		Kit.box(world, exedra + Vector3(cos(a), 0, sin(a)) * 3.4 + Vector3(0, 0.23, 0), Vector3(1.7, 0.46, 0.55), "marble", true,
			Vector3(0, -a + PI / 2.0, 0))
	var plato := _teacher(world, room, b, stage, Vector3(0, 0, 113.6), 0.0, Vector3(0, 0, 116.2), out, spots)
	_study(world, room, out, spots, [[Vector3(-4.8, 0, 115.0), 0.0, Vector3(-4.8, 0, 116.6)], [Vector3(4.8, 0, 115.0), 0.0, Vector3(4.8, 0, 116.6)]],
		Vector3(-8.6, 1.6, 112.0), 0.35, Vector3(-8.0, 0, 113.8), Vector3(8.6, 0, 112.4), Vector3(8.6, 0, 113.6))
	out.append(Places.seat(world, Vector3(17.0, 0, 113.0), Vector3(0, 0, 1), "Sit in the shade of the olives"))

	# the terrace above the board, "the hillside" where you walk with Socrates, and on it the council
	# table where he and the brothers found the city with you
	const UP := 6.0
	Kit.box(world, Vector3(0, UP / 2.0, 90.0), Vector3(26.0, UP, 12.0), "stone")
	Kit.box(world, Vector3(0, UP + 0.02, 90.0), Vector3(26.0, 0.04, 12.0), "paving" if b.has("walkway") else "ashbed", false)
	Kit.box(world, Vector3(0, UP / 2.0, 103.0), Vector3(4.0, 0.4, sqrt(14.0 * 14.0 + UP * UP)), "path", true, Vector3(atan2(UP, 14.0), 0, 0))
	var tc := Vector3(0, UP, 88.5)
	var wood := "wood" if b.has("walkway") else "deadwood"
	Kit.box(world, tc + Vector3(0, 0.72, 0), Vector3(3.2, 0.08, 1.3), wood)
	for p: Vector3 in [Vector3(-1.4, 0.35, -0.5), Vector3(1.4, 0.35, -0.5), Vector3(-1.4, 0.35, 0.5), Vector3(1.4, 0.35, 0.5)]:
		Kit.box(world, tc + p, Vector3(0.1, 0.7, 0.1), wood, false)
	for k in 4:  # the counters: gold, silver, bronze and iron
		Kit.blob(world, tc + Vector3(-1.0 + k * 0.25, 0.8, 0.25), 0.05, ["gold", "#c8ccd4", "bronze", "iron"][k])
	Kit.box(world, tc + Vector3(0.7, 0.77, 0.1), Vector3(0.5, 0.02, 0.35), "wood", false)  # a wax tablet
	Kit.box(world, tc + Vector3(0.7, 0.785, 0.1), Vector3(0.42, 0.01, 0.28), "#3a2a1e", false)
	for c: Array in [["socrates", Vector3(-1.4, 0, -1.2)], ["glaucon", Vector3(2.3, 0, -0.4)], ["adeimantus", Vector3(-2.3, 0, 0.3)]]:
		var at: Vector3 = tc + c[1]
		people.append(People.figure(world, at, Kit.face_yaw(at, tc), str(c[0]), not b.has("household")))
	Kit.bench(world, tc + Vector3(0, 0, 1.3), PI)  # your seat, facing the board
	out.append({"kind": "council", "pos": tc + Vector3(0, 0, 2.2), "work": work, "text": "Sit at the council table and govern the city"})
	spots["council"] = tc + Vector3(0, 0, 2.2)

	# the city in speech, as far as you have governed it; as it falls, the board loses its pieces
	var board_back: Array = b.duplicate()
	if city_stage > City.JUST_CITY:
		for piece in FALLS.slice(0, city_stage - City.JUST_CITY):
			board_back.erase(piece)
	var board := Thinkers.city_in_speech(world, Vector3(0, 0, 44), 0.0, mini(city_stage, City.JUST_CITY), board_back)
	take.call(board)
	_fall(board["soul"], city_stage)
	flicker.append_array(_academy_lessons(world, work, room, out, spots, board, b, take))

	_way(world, [Vector3(0, 0, 124), Vector3(0, 0, 108)])
	_way(world, [Vector3(0, 0, 108), Vector3(-20, 0, 100), Vector3(-44, 0, 90), Vector3(-104, 0, 62)])  # to Cephalus's house
	_way(world, [Vector3(-44, 0, 90), Vector3(-44, 0, -46), Vector3(-6, 0, -56)])  # past the line, to Er's meadow
	_way(world, [Vector3(-44, 0, 2), Vector3(-104, 0, 0)])  # to the court
	_way(world, [Vector3(-44, 0, -46), Vector3(-104, 0, -54)])  # to the prison
	_way(world, [Vector3(0, 0, 108), Vector3(20, 0, 100), Vector3(44, 0, 92), Vector3(75, 0, 116)])  # to the cave
	_way(world, [Vector3(44, 0, 92), Vector3(44, 0, 18), Vector3(90, 0, 16)])  # to Gyges' pasture
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 143.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [plato] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads, "back": b}


## The soul over the city as the city falls: each part brighter or dimmer, bigger or smaller, by
## DECLINE; under the tyrant, appetite burns alone and dark red.
static func _fall(soul: Dictionary, city_stage: int) -> void:
	if not DECLINE.has(city_stage):
		return
	var parts: Dictionary = soul["parts"]
	for part: String in DECLINE[city_stage]:
		var node: Node3D = parts[part]
		var spec: Array = DECLINE[city_stage][part]
		node.scale = Vector3.ONE * float(spec[1])
		for l in node.find_children("*", "OmniLight3D", false, false):
			(l as OmniLight3D).light_energy = float(spec[0])
	if city_stage == City.LAST_STAGE:
		var appetite: Node3D = parts["appetite"]
		for mi in appetite.find_children("*", "MeshInstance3D", false, false):
			var m := Thinkers._glow(Color("a01818"))
			(mi as MeshInstance3D).material_override = m
		for l in appetite.find_children("*", "OmniLight3D", false, false):
			(l as OmniLight3D).light_color = Color("c02020")


## The Republic's eight points round the board: the argument at Cephalus's house, Gyges' ring, the
## city of pigs and the just city on the board (once you have governed it so far), the soul over it,
## the line, the cave and Er; and the three scenes that are not points: the trial, the dinner, the
## cup.
static func _academy_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, board: Dictionary,
		b: Array, take: Callable) -> Array:
	var flicker: Array = []
	var note := func(id: String) -> String: return Places._lesson(room, id).get("point", "")
	var beat := func(id: String, script: String, at: Vector3, text: String, cast: Dictionary, marks: Dictionary) -> Dictionary:
		var it := {"kind": "beat", "pos": at, "work": work, "beat": script, "text": text, "cast": cast, "marks": marks}
		if id != "":
			it["id"] = id
			it["note"] = note.call(id)
		out.append(it)
		spots[script] = at
		return it

	# Book I: what justice is, argued at Cephalus's house in the Piraeus
	var ceph := Thinkers.cephalus_house(world, Vector3(-115, 0, 60), PI / 2.0, b)
	take.call(ceph)
	var ca: Vector3 = ceph["spots"]["teacher"]
	Kit.stele(world, ca + Vector3(0, 0, -1.0), Kit.face_yaw(ca + Vector3(0, 0, -1.0), ca))
	_stone(out, work, room, "justice", ca, "Listen to the argument at Cephalus's house")
	spots["justice"] = ca

	# Book II: the ring of Gyges, down in the chasm and back among the shepherds
	var gy := Thinkers.gyges(world, Vector3(90, 0, -30), 0.0, b)
	take.call(gy)
	var chasm: Array = gy["chasm"]
	var shepherd: Node3D = gy["people"][0]["root"]
	beat.call("gyges", "gyges", chasm[0], "Go down into the chasm, as Gyges", {"gyges": shepherd},
		{"chasm": chasm, "horse": gy["horse_door"], "meeting": Areas._at(gy["root"], Vector3(-16.0, 6.0, 15.4))})

	# Books II-IV: the city of pigs and the just city, on the board you build at the table
	var lines := {
		"one_work": [Vector3(-39.5, 0, 62.0), Vector3(-38.0, 0, 62.0), "Look at the city of pigs",
			"Only the boundary stones stand here yet. Sit at the council table and found the city: the board shows it as far as you have governed it."],
		"just_city": [Vector3(39.5, 0, 62.0), Vector3(38.0, 0, 62.0), "Look at the just city",
			"The city is not yet just. Govern it at the council table until each order does its own work."],
	}
	for id: String in lines:
		var spec: Array = lines[id]
		Kit.stele(world, spec[0], Kit.face_yaw(spec[0], spec[1]))
		var it := _stone(out, work, room, id, spec[1], spec[2])
		it["needs_city"] = 1 if id == "one_work" else City.JUST_CITY
		it["not_yet"] = spec[3]
		spots[id] = spec[1]

	# Book IV: the city turned round into the soul
	var parts: Dictionary = board["soul"]["parts"]
	var soul_marks := {}
	for part: String in parts:
		soul_marks[part] = _in_world(parts[part], world)
	var sa := Vector3(-26.0, 0, 18.0)
	Kit.stele(world, sa + Vector3(-1.2, 0, 0.6), Kit.face_yaw(sa + Vector3(-1.2, 0, 0.6), sa))
	var soul: Dictionary = beat.call("soul", "the_soul", sa, "Look up into the soul", {}, soul_marks)
	soul["start"] = sa
	soul["face"] = Vector3(0, 0, 8.0)
	soul["needs_city"] = City.JUST_CITY
	soul["not_yet"] = "The soul rises over the city only when the city is just. Govern it at the council table until it is."

	# Book VI: the divided line, walked from the shadows to the sun
	var line := Thinkers.the_line(world, Vector3(-62, 0, -10), 0.0, b)
	take.call(line)
	var lm := {"sun": Areas._at(line["root"], Vector3(0, 40.0, -90.0)), "pool": Areas._at(line["root"], Vector3(4.0, 0, 24.0))}
	for seg: Dictionary in line["segments"]:
		lm[seg["name"]] = (seg["from"] + seg["to"]) / 2.0
	beat.call("line", "the_line", (line["segments"][0]["from"] as Vector3) + Vector3(0, 0, 1.2), "Walk the divided line", {}, lm)

	# Book VII: the cave, and a way up onto its hill from the grove
	var cave := Thinkers.cave(world, Vector3(75, 0, 58), 0.0, b)
	take.call(cave)
	var cr: Node3D = cave["root"]
	Kit.box(cr, Vector3(0, 2.4, 48.0), Vector3(5.0, 0.4, 16.7), "path", true, Vector3(atan2(4.8, 16.0), 0, 0))
	var bench := Areas._at(cr, Vector3(0, 0, -2.2))
	var foot := Areas._at(cr, Vector3(0, 0, 4.2))
	var mouth: Vector3 = cave["mouth"]
	var den: Dictionary = beat.call("cave", "cave", Areas._at(cr, Vector3(5.0, 0, -1.6)), "Sit down among the prisoners", {},
		{"fire": Areas._at(cr, Vector3(0, 1.0, 5.0)), "wall": Areas._at(cr, Vector3(0, 3.0, -9.0)), "up": [foot, mouth],
		"pool": cave["pool"], "down": [mouth, foot, bench]})
	den["start"] = bench
	den["face"] = Areas._at(cr, Vector3(0, 0, -9.0))

	# Book X: Er's meadow, the lots, the lives and the river
	var meadow := Thinkers.er(world, Vector3(-5, 0, -95), 0.0, b)
	take.call(meadow)
	var lives: Array = meadow["lives"]
	var banks: Array = meadow["banks"]
	beat.call("er", "er", meadow["spots"]["teacher"], "Stand among the souls in the meadow", {},
		{"prophet": Areas._at(meadow["root"], Vector3(0, 0, -8.6)), "lives": [lives[2], lives[5], lives[8]],
		"lethe": Areas._at(meadow["root"], banks[2])})

	# not points: the trial, the dinner, the last day
	var court := Thinkers.court(world, Vector3(-110, 0, -18), 0.0, b)
	take.call(court)
	var trial: Dictionary = beat.call("", "apology", court["spots"]["teacher"], "Stand trial, as Socrates", {"socrates": court["people"][0]["root"]},
		{"platform": court["platform"], "urns": court["urns"]})
	trial["after"] = "Plato was in the court that day. Everything he wrote afterwards is, in a way, an answer to it."
	var dinner := Thinkers.symposium(world, Vector3(-50, 0, 102), 0.0, b)
	take.call(dinner)
	out.append({"kind": "look", "pos": dinner["spots"]["teacher"], "text": "Listen to Socrates at Agathon's dinner",
		"note": "Socrates tells the guests what Diotima taught him about love: begin from one beautiful body and climb, \"using these as steps only, and from one going on to two, and from two to all fair forms, and from fair forms to fair practices, and from fair practices to fair notions, until from fair notions he arrives at the notion of absolute beauty.\""})
	spots["symposium"] = dinner["spots"]["teacher"]
	var jail := Thinkers.prison(world, Vector3(-110, 0, -72), 0.0, b)
	take.call(jail)
	var cell: Dictionary = jail["cell"]
	var last: Dictionary = beat.call("", "the_cup", jail["spots"]["teacher"], "Spend the last day, as Socrates",
		{"socrates": jail["people"][0]["root"], "cup": jail["cup"]}, {"walk": [cell["window"], cell["door"]], "bed": cell["bed"]})
	last["after"] = "Phaedo told it afterwards to Echecrates. Plato, he said, was ill, and was not there."
	return flicker


# ---------- #7 Hesiod, the Theogony and the Works and Days ----------

## Ascra under Mount Helicon, about 700 BC: Hesiod by the way in, his farm (the plough team in
## the field, the threshing floor, the hives, the great jar, the frieze of the five ages, and far
## off Prometheus on his crag), and above it the high meadow of Helicon where the Muses dance round
## the Horse's Spring, with the gap of Chaos at its edge and Kronos in stone with his sickle. The
## peak of Helicon stands behind. Lost, the field is dust, the spring dry, the Muses shades.
static func ascra(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 0), 50.0)
	Kit.plateau(world, 90.0, "earth", false)
	Kit.mountain(world, Vector3(-20, -12, -230), 130.0, 110.0, false)  # Helicon's peak
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 10), 5, 18.0, 14.0) if b.has("leaves") else []
	var take := func(a: Dictionary) -> void:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
		squads.append_array(a["squads"])
		birds.append_array(a["birds"])
	_arrival(world, room, out, spots, flicker, 80.0, 60.0, "path")

	# Hesiod by the way in, on a stone, with his laurel staff
	Kit.box(world, Vector3(0, 0.25, 55.4), Vector3(0.9, 0.5, 0.7), "stone")
	var hesiod := _teacher(world, room, b, stage, Vector3(0, 0, 55.6), 0.0, Vector3(0, 0, 58.4), out, spots)
	Kit.cylinder(world, Vector3(0.6, 0, 56.0), 0.03, 1.9, "wood", false, 6)  # the staff
	sway.append(Kit.olive(world, Vector3(-3.0, 0, 53.5), 1.2, b.has("leaves")))  # the laurel over him
	_study(world, room, out, spots, [[Vector3(-4.2, 0, 57.0), 0.0, Vector3(-4.2, 0, 58.6)]],
		Vector3(-7.0, 1.6, 54.0), 0.3, Vector3(-6.4, 0, 55.8), Vector3(6.5, 0, 54.4), Vector3(6.5, 0, 55.6))
	out.append(Places.seat(world, Vector3(9.0, 0, 58.0), Vector3(0, 0, -1), "Sit and look up at Helicon"))

	var farm := Areas.farm(world, Vector3(0, 0, 22), 0.0, b)
	take.call(farm)
	var mount := Areas.helicon(world, Vector3(0, 0, -45), 0.0, b)
	take.call(mount)
	_way(world, [Vector3(0, 0, 52), Vector3(0, 0, -15)])
	flicker.append_array(_ascra_lessons(world, work, room, out, spots, farm, mount, b))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 77.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [hesiod] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads, "back": b}


## Hesiod's six points: the Muses at their spring, Chaos at its gap, the stone given to Kronos (a
## beat, as Rhea), Pandora's jar (a beat), the five ages on the farmyard wall, and the farmer's
## year (a beat: plough when the crane cries, thresh, put up the harvest).
static func _ascra_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, farm: Dictionary,
		mount: Dictionary, b: Array) -> Array:
	var flicker: Array = []
	var note := func(id: String) -> String: return Places._lesson(room, id).get("point", "")
	var stele_stone := func(id: String, at: Vector3, face: Vector3, text: String) -> void:
		Kit.stele(world, at + (at - face).normalized() * 0.9, Kit.face_yaw(at + (at - face).normalized() * 0.9, at))
		_stone(out, work, room, id, at, text)
		spots[id] = at

	var spring := Areas._at(mount["root"], Vector3.ZERO)
	stele_stone.call("muses", spring + Vector3(0, 0, 7.5), spring, "Watch the Muses dance")
	var gap := Areas._at(mount["root"], Vector3(0, 0, -19.0))
	stele_stone.call("chaos", gap + Vector3(6.5, 0, 3.0), gap, "Look into the gap of Chaos")
	var ages: Array = farm["ages"]
	var mid := Areas._at(farm["root"], ages[2])
	stele_stone.call("ages", mid + Vector3(0, 0, 1.2), mid + Vector3(0, 0, -2.0), "Read the frieze of the five ages")

	# the stone in swaddling clothes, given to Kronos in place of Zeus
	var kronos := Areas._at(mount["root"], Vector3(-9.0, 0, -15.0))
	var stone := Kit.group(world, kronos + Vector3(4.0, 0, 5.0))
	Kit.blob(stone, Vector3(0, 0.4, 0), 0.4, "rock", Vector3(0.8, 1.2, 0.8), 6)
	Kit.box(stone, Vector3(0, 0.4, 0), Vector3(0.7, 0.2, 0.5), "#d8d0b8", false)
	Kit.unsolid(stone)
	out.append({"kind": "beat", "pos": kronos + Vector3(6.0, 0, 7.5), "work": work, "id": "succession", "beat": "the_stone",
		"text": "Deceive Kronos, as Rhea", "note": note.call("succession"), "cast": {"stone": stone},
		"marks": {"stone": kronos + Vector3(4.8, 0, 5.8), "kronos": kronos + Vector3(2.0, 0, 2.6), "face": kronos + Vector3(0, 3.5, 0)}})
	spots["succession"] = kronos + Vector3(6.0, 0, 7.5)

	# Pandora's jar, standing open in the farmyard
	var jar := Areas._at(farm["root"], Vector3(4.0, 0, 4.0))
	out.append({"kind": "beat", "pos": jar + Vector3(0, 0, 2.6), "work": work, "id": "prometheus", "beat": "the_jar",
		"text": "Stand before Pandora's jar", "note": note.call("prometheus"), "cast": {},
		"marks": {"jar": jar + Vector3(0, 0, 1.2), "crag": Areas._at(farm["root"], Vector3(-30.0, 5.0, -40.0))}})
	spots["prometheus"] = jar + Vector3(0, 0, 2.6)

	# the farmer's year
	var yard: Vector3 = farm["spots"]["teacher"]
	out.append({"kind": "beat", "pos": yard, "work": work, "id": "work", "beat": "the_year", "text": "Work the farmer's year",
		"note": note.call("work"), "cast": {},
		"marks": {"plough": Areas._at(farm["root"], Vector3(-14.0, 0, -5.0)), "threshing": Areas._at(farm["root"], Vector3(12.0, 0, -4.0)),
			"hives": Areas._at(farm["root"], Vector3(16.0, 0, 6.0))}})
	spots["work"] = yard
	return flicker


# ---------- #8 Sappho ----------

## Sappho's garden above the sea on Lesbos, about 600 BC: the apple orchard round Aphrodite's
## shrine, the cold stream, the sparrow chariot in the sky, the two seats facing each other, the
## barbitos on its bench; Sappho herself at the garden's gate; the fleet far out on the sea; and,
## blown about the orchard, the torn strips of papyrus that are nearly all that is left of her.
## Lost, the orchard is bare, the stream dry, her women shades.
static func lesbos(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 0), 40.0)
	Kit.plateau(world, 60.0, "grass" if b.has("leaves") else "earth", false)
	Kit.sea(world, -9.0)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 0), 5, 14.0, 12.0) if b.has("leaves") else []
	_arrival(world, room, out, spots, flicker, 52.0, 28.0, "path")
	var garden := Areas.garden(world, Vector3(0, 0, -5), 0.0, b)
	flicker.append_array(garden["flicker"])
	sway.append_array(garden["sway"])
	people.append_array(garden["people"])

	# Sappho at the garden's gate, her barbitos beside her
	Kit.bench(world, Vector3(0, 0, 20.2), 0.0)
	var sappho := _teacher(world, room, b, stage, Vector3(0, 0, 20.0), 0.0, Vector3(0, 0, 22.8), out, spots)
	Greek.barbitos(world, Vector3(1.2, 0.5, 20.2), 0.2, b.has("teacher"))
	_study(world, room, out, spots, [[Vector3(-4.5, 0, 21.0), 0.0, Vector3(-4.5, 0, 22.6)]],
		Vector3(-7.5, 1.6, 18.5), 0.3, Vector3(-6.9, 0, 20.3), Vector3(6.5, 0, 19.0), Vector3(6.5, 0, 20.2))
	for k in 4:  # the women of her circle
		var at := Vector3(-14.0 + k * 9.0, 0, 10.0 + (k % 2) * 3.0)
		people.append(People.figure(world, at, Kit.face_yaw(at, Vector3(0, 0, 2)), "muse", not b.has("household"), "",
			["e8d0c0", "8a5a7a", "d8cfa8", "5a6a8a"][k]))
	out.append(Places.seat(world, Vector3(12.0, 0, 24.0), Vector3(0, 0, 1), "Sit and look out at the ships"))
	flicker.append_array(_lesbos_lessons(world, work, room, out, spots, garden, b))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 49.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [sappho] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads, "back": b}


## Sappho's six points: the Hymn (a beat at Aphrodite's altar), whatever one loves (looking out at
## the fleet), what love does (a beat at the two facing seats), the garden (at the cold stream),
## the pieces (a beat: gather the torn papyrus), and the singer's I (at her barbitos).
static func _lesbos_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, garden: Dictionary,
		b: Array) -> Array:
	var flicker: Array = []
	var gr: Node3D = garden["root"]
	var note := func(id: String) -> String: return Places._lesson(room, id).get("point", "")
	var stele_stone := func(id: String, at: Vector3, face: Vector3, text: String) -> void:
		Kit.stele(world, at + (at - face).normalized() * 0.9, Kit.face_yaw(at + (at - face).normalized() * 0.9, at))
		_stone(out, work, room, id, at, text)
		spots[id] = at
	stele_stone.call("what_one_loves", Vector3(-12.0, 0, 26.0), Vector3(-12.0, 0, 60.0), "Look out at the fleet")
	stele_stone.call("garden", Areas._at(gr, Vector3(-8.0, 0, 4.0)), Areas._at(gr, Vector3(-11.0, 0, 4.0)), "Listen to the cold stream")
	stele_stone.call("lyric", Areas._at(gr, Vector3(8.0, 0, 10.0)), Areas._at(gr, Vector3(8.0, 0, 8.0)), "Look at the barbitos")

	# the Hymn, at Aphrodite's altar, with the sparrow chariot coming down the sky
	var altar := Areas._at(gr, Vector3(0, 0, -4.5))
	out.append({"kind": "beat", "pos": altar + Vector3(0, 0, 2.2), "work": work, "id": "hymn", "beat": "the_hymn",
		"text": "Pray at Aphrodite's altar", "note": note.call("hymn"), "cast": {},
		"marks": {"altar": altar + Vector3(0, 0, 1.3), "chariot": Areas._at(gr, Vector3(3.0, 7.0, -6.0))}})
	spots["hymn"] = altar + Vector3(0, 0, 2.2)

	# the two seats facing each other: he sits opposite her, and she laughs
	var seat_a := Areas._at(gr, Vector3(-1.5, 0, 6.0))
	var seat_b := Areas._at(gr, Vector3(1.5, 0, 6.0))
	var man := People.figure(world, seat_b + Vector3(0.3, 0, 0), Kit.face_yaw(seat_b, seat_a), "suitor", not b.has("household"), "sit")
	var girl := People.figure(world, seat_b + Vector3(0.3, 0, 1.0), Kit.face_yaw(seat_b, seat_a), "muse", not b.has("household"), "sit",
		"e8d0c0")
	out.append({"kind": "beat", "pos": seat_a + Vector3(-1.2, 0, 1.4), "work": work, "id": "symptoms", "beat": "the_seats",
		"text": "Sit opposite them", "note": note.call("symptoms"), "cast": {"man": man["root"], "girl": girl["root"]},
		"marks": {"seat": seat_a + Vector3(-0.4, 0, 0), "girl": seat_b + Vector3(0.3, 1.2, 1.0)}})
	spots["symptoms"] = seat_a + Vector3(-1.2, 0, 1.4)

	# the pieces: torn strips of papyrus blown about the orchard, to gather
	var cast := {}
	var marks := {}
	var strips := [Vector3(-12, 0, -10), Vector3(11, 0, -14), Vector3(-6, 0, 9), Vector3(14, 0, 3), Vector3(-15, 0, 1)]
	for k in strips.size():
		var at := Areas._at(gr, strips[k])
		var strip := Kit.group(world, at, k * 1.3)
		Kit.box(strip, Vector3(0, 0.03, 0), Vector3(0.34, 0.01, 0.16), "papyrus" if b.has("walkway") else "ashbed", false)
		Kit.box(strip, Vector3(0.05, 0.036, 0), Vector3(0.2, 0.004, 0.02), "#2a2218", false)  # a line of writing
		Kit.unsolid(strip)
		cast["strip%d" % k] = strip
		marks["strip%d" % k] = at
	var gate := Areas._at(gr, Vector3(0, 0, 17.0))
	out.append({"kind": "beat", "pos": gate, "work": work, "id": "fragments", "beat": "the_pieces", "text": "Gather the torn papyrus",
		"note": note.call("fragments"), "cast": cast, "marks": marks})
	spots["fragments"] = gate
	return flicker


# ---------- #9 Aeschylus, the Oresteia ----------

## Argos and the hill of Ares: the palace of Atreus (the watchman on the roof, the beacon on the far
## height, the chariot home from Troy with Cassandra in it, the purple tapestries to the door,
## Clytemnestra on the step, the bath inside); behind it the Areopagus, with the judges, Athena,
## Orestes at the altar, the Furies and the urns; and to the west the theatre of Dionysus where the
## trilogy was played in 458 BC, Aeschylus by its orchestra. Lost, the beacon is dark, the palace
## and the theatre broken, the chorus and the judges shades.
static func argos(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 0), 50.0)
	Kit.plateau(world, 90.0, "earth", false)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 10), 5, 16.0, 14.0) if b.has("leaves") else []
	var take := func(a: Dictionary) -> void:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
		squads.append_array(a["squads"])
		birds.append_array(a["birds"])
	_arrival(world, room, out, spots, flicker, 80.0, 52.0, "path")

	# Aeschylus by the way in, with the mask of his watchman
	var poet := _teacher(world, room, b, stage, Vector3(0, 0, 45.0), 0.0, Vector3(0, 0, 47.8), out, spots)
	Greek.mask(world, Vector3(0.9, 1.0, 45.2), 0.0, "tragic", 0.6, b.has("teacher"))
	_study(world, room, out, spots, [[Vector3(-4.2, 0, 46.5), 0.0, Vector3(-4.2, 0, 48.1)]],
		Vector3(-7.0, 1.6, 43.5), 0.3, Vector3(-6.4, 0, 45.3), Vector3(6.5, 0, 44.0), Vector3(6.5, 0, 45.2))
	for p: Vector3 in [Vector3(-14, 0, 40), Vector3(15, 0, 36), Vector3(-22, 0, -48), Vector3(24, 0, -52), Vector3(-10, 0, -86)]:
		sway.append(Kit.olive(world, p, 1.2, b.has("leaves")))

	var house := Areas.argos_palace(world, Vector3(0, 0, -10), 0.0, b)
	take.call(house)
	var hill := Areas.areopagus(world, Vector3(0, 0, -62), 0.0, b)
	take.call(hill)
	var stage_of := Greek.theatre(world, Vector3(-58, 0, 5), PI / 2.0, 12, b.has("walkway"))
	for k in 6:  # the chorus of old men of Argos in the orchestra, with their staffs
		var at: Vector3 = (stage_of["root"] as Node3D).transform * Vector3(-3.0 + (k % 3) * 3.0, 0, -2.0 + (k / 3) * 2.5)
		people.append(People.figure(world, at, PI / 2.0, "phoenix", not b.has("household"), "", "5a5048"))
	_way(world, [Vector3(0, 0, 42), Vector3(0, 0, 22)])
	_way(world, [Vector3(-12, 0, 20), Vector3(-36, 0, 8)])
	_way(world, [Vector3(14, 0, -24), Vector3(14, 0, -40)])
	out.append(Places.seat(world, Vector3(20.0, 0, 44.0), Vector3(1, 0, 1), "Sit and watch the far height"))
	flicker.append_array(_argos_lessons(world, work, room, out, spots, house, hill, b))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 77.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [poet] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads, "back": b}


## The Oresteia's six points: the watchman's night (a beat), the curse at the bath, learning by
## suffering at the altar where the chorus sings, the purple tapestries (a beat, as Agamemnon),
## Cassandra in the chariot, and the court on the hill of Ares (a beat, as one of its judges).
static func _argos_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, house: Dictionary,
		hill: Dictionary, b: Array) -> Array:
	var flicker: Array = []
	var hr: Node3D = house["root"]
	var note := func(id: String) -> String: return Places._lesson(room, id).get("point", "")
	var stele_stone := func(id: String, at: Vector3, face: Vector3, text: String) -> void:
		Kit.stele(world, at + (at - face).normalized() * 0.9, Kit.face_yaw(at + (at - face).normalized() * 0.9, at))
		_stone(out, work, room, id, at, text)
		spots[id] = at
	stele_stone.call("curse", Areas._at(hr, Vector3(-6.0, 0, -2.4)), Areas._at(hr, Vector3(-6.0, 0, -5.0)), "Look at the bath")
	stele_stone.call("learning", Areas._at(hr, Vector3(8.0, 0, 4.0)), Areas._at(hr, Vector3(8.0, 0, 0.0)), "Listen to the old men of Argos")
	stele_stone.call("cassandra", Areas._at(hr, Vector3(2.4, 0, 16.0)), Areas._at(hr, Vector3(0.3, 0, 15.5)), "Look at the woman in the chariot")

	# the watchman's night: the long wait for the beacon
	var watch := Areas._at(hr, Vector3(-4.0, 0, 6.0))
	out.append({"kind": "beat", "pos": watch, "work": work, "id": "beacon", "beat": "the_watch", "text": "Keep the watchman's watch",
		"note": note.call("beacon"), "cast": {}, "marks": {"beacon": Areas._at(hr, Vector3(30.0, 10.0, 70.0)), "roof": Areas._at(hr, Vector3(0, 7.0, -6.0))}})
	spots["beacon"] = watch

	# the purple tapestries, from the chariot to the door
	var queen: Node3D = house["people"][2]["root"]
	out.append({"kind": "beat", "pos": Areas._at(hr, Vector3(-1.8, 0, 12.0)), "start": Areas._at(hr, Vector3(-0.8, 0, 12.4)),
		"face": Areas._at(hr, Vector3(0, 0, -6.0)), "work": work, "id": "tapestries", "beat": "the_tapestries",
		"text": "Come home from Troy, as Agamemnon", "note": note.call("tapestries"), "cast": {"clytemnestra": queen},
		"marks": {"door": [Areas._at(hr, Vector3(0, 0, 8.0)), Areas._at(hr, Vector3(0, 0, 2.0)), Areas._at(hr, Vector3(0, 0, -2.2))],
			"queen": Areas._at(hr, Vector3(0, 2.2, -3.5))}})
	spots["tapestries"] = Areas._at(hr, Vector3(-1.8, 0, 12.0))

	# the court on the hill of Ares
	var ar: Node3D = hill["root"]
	var urns: Vector3 = Areas._at(ar, hill["urns"]) if hill["urns"] is Vector3 else Areas._at(ar, Vector3(0, 0, -3.5))
	out.append({"kind": "beat", "pos": Areas._at(ar, Vector3(-4.0, 0, 1.0)), "work": work, "id": "court", "beat": "the_vote",
		"text": "Sit as a judge on the hill of Ares", "note": note.call("court"), "cast": {},
		"marks": {"urns": urns + Vector3(0, 0, 1.2), "athena": Areas._at(ar, Vector3(0, 2.0, -6.0)), "orestes": Areas._at(ar, Vector3(0, 1.6, 4.4))}})
	spots["court"] = Areas._at(ar, Vector3(-4.0, 0, 1.0))
	return flicker


# ---------- #10 Sophocles, the Theban plays ----------

## Thebes, about 430 BC: the palace gate in the plague (the altar heaped with suppliants' branches,
## the dead in the street and burning on pyres, the Sphinx on her column, Oedipus and Jocasta on
## the step, Teiresias before them); to the east the place where three roads meet in the
## mountains, the old man's carriage overturned; to the west the unburied body of Polynices and
## the rock tomb where Antigone is walled up; behind, the theatre where the plays were given, and
## Sophocles by the way in. Lost, the city is a ruin, the chorus shades.
static func thebes(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := Places._sky(world, room, stage, "golden", Vector3(0, 0, 0), 50.0)
	Kit.plateau(world, 100.0, "earth", false)
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var people: Array = []
	var squads: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, 10), 5, 16.0, 14.0) if b.has("leaves") else []
	var take := func(a: Dictionary) -> void:
		flicker.append_array(a["flicker"])
		sway.append_array(a["sway"])
		people.append_array(a["people"])
		squads.append_array(a["squads"])
		birds.append_array(a["birds"])
	_arrival(world, room, out, spots, flicker, 88.0, 58.0, "path")
	var poet := _teacher(world, room, b, stage, Vector3(0, 0, 50.0), 0.0, Vector3(0, 0, 52.8), out, spots)
	_study(world, room, out, spots, [[Vector3(-4.2, 0, 51.5), 0.0, Vector3(-4.2, 0, 53.1)]],
		Vector3(-7.0, 1.6, 48.5), 0.3, Vector3(-6.4, 0, 50.3), Vector3(6.5, 0, 49.0), Vector3(6.5, 0, 50.2))
	for p: Vector3 in [Vector3(-14, 0, 44), Vector3(15, 0, 40), Vector3(-20, 0, 22), Vector3(22, 0, 24)]:
		sway.append(Kit.olive(world, p, 1.2, b.has("leaves")))

	var gate := Areas.thebes_gate(world, Vector3(0, 0, 5), 0.0, b)
	take.call(gate)
	var roads := Areas.crossroads(world, Vector3(52, 0, -38), 0.0, b)
	take.call(roads)
	var tomb := Areas.antigone_tomb(world, Vector3(-48, 0, -30), 0.3, b)
	take.call(tomb)
	var play := Greek.theatre(world, Vector3(0, 0, -62), 0.0, 12, b.has("walkway"))
	for k in 6:  # the chorus of Theban elders in the orchestra
		var at: Vector3 = (play["root"] as Node3D).transform * Vector3(-3.0 + (k % 3) * 3.0, 0, 1.0 + (k / 3) * 2.5)
		people.append(People.figure(world, at, 0.0, "phoenix", not b.has("household"), "", "3a3a5a"))
	_way(world, [Vector3(0, 0, 46), Vector3(0, 0, 26)])
	_way(world, [Vector3(14, 0, 18), Vector3(40, 0, -14)])
	_way(world, [Vector3(-14, 0, 18), Vector3(-42, 0, -12)])
	_way(world, [Vector3(0, 0, -12), Vector3(0, 0, -38)])
	out.append(Places.seat(world, Vector3(18.0, 0, 50.0), Vector3(0, 0, -1), "Sit and look at the palace"))
	flicker.append_array(_thebes_lessons(world, work, room, out, spots, gate, roads, tomb, play, b))
	return {"name": _name(room), "interactables": out, "spawn": Vector3(0, 0.05, 85.0), "yaw": 0.0, "spots": spots,
		"flicker": flicker, "people": [poet] + people, "restored": 0, "sway": sway, "birds": birds, "squads": squads, "back": b}


## Sophocles' six points: the search at the altar, the blind seer, the crossroads (a beat, as
## Oedipus), the recognition at the palace door (a beat), the unwritten laws (a beat, as Antigone
## with the dust), and too late, where the chorus sings in the theatre.
static func _thebes_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary, gate: Dictionary,
		roads: Dictionary, tomb: Dictionary, play: Dictionary, b: Array) -> Array:
	var flicker: Array = []
	var gr: Node3D = gate["root"]
	var note := func(id: String) -> String: return Places._lesson(room, id).get("point", "")
	var stele_stone := func(id: String, at: Vector3, face: Vector3, text: String) -> void:
		Kit.stele(world, at + (at - face).normalized() * 0.9, Kit.face_yaw(at + (at - face).normalized() * 0.9, at))
		_stone(out, work, room, id, at, text)
		spots[id] = at
	stele_stone.call("search", Areas._at(gr, Vector3(-2.6, 0, 7.4)), Areas._at(gr, Vector3(0, 0, 4.0)), "Kneel with the suppliants")
	stele_stone.call("seer", Areas._at(gr, Vector3(6.2, 0, 9.4)), Areas._at(gr, Vector3(4.0, 0, 8.0)), "Listen to Teiresias")
	var orch: Vector3 = (play["root"] as Node3D).transform * Vector3(0, 0, 6.0)
	stele_stone.call("too_late", orch + Vector3(3.5, 0, 3.0), orch, "Hear the chorus sing of man")

	# where three roads meet
	var rr: Node3D = roads["root"]
	var meet := Areas._at(rr, Vector3.ZERO)
	out.append({"kind": "beat", "pos": Areas._at(rr, Vector3(0, 0, 18.0)), "work": work, "id": "crossroads", "beat": "the_crossroads",
		"text": "Take the road from Delphi, as Oedipus", "note": note.call("crossroads"), "cast": {},
		"marks": {"meeting": meet + Vector3(0, 0, 2.0), "cart": Areas._at(rr, Vector3(3.0, 1.0, 3.0))}})
	spots["crossroads"] = Areas._at(rr, Vector3(0, 0, 18.0))

	# the recognition, at the palace door
	var door := Areas._at(gr, Vector3(0, 0, -2.0))
	var queen: Node3D = gate["people"][1]["root"]
	out.append({"kind": "beat", "pos": Areas._at(gr, Vector3(-3.5, 0, 6.0)), "work": work, "id": "recognition", "beat": "the_truth",
		"text": "Question the last witness, as Oedipus", "note": note.call("recognition"), "cast": {"jocasta": queen},
		"marks": {"altar": Areas._at(gr, Vector3(0, 0, 6.2)), "door": door, "jocasta": Areas._at(gr, Vector3(-1.5, 2.2, -3.2))}})
	spots["recognition"] = Areas._at(gr, Vector3(-3.5, 0, 6.0))

	# the dust on Polynices, and the tomb
	var tr: Node3D = tomb["root"]
	var sister: Node3D = tomb["people"][2]["root"]
	out.append({"kind": "beat", "pos": Areas._at(tr, Vector3(2.0, 0, 12.0)), "work": work, "id": "unwritten", "beat": "the_dust",
		"text": "Bury your brother, as Antigone", "note": note.call("unwritten"), "cast": {"antigone": sister},
		"marks": {"body": Areas._at(tr, Vector3(5.0, 0, 7.6)), "creon": Areas._at(tr, Vector3(-6.0, 2.0, 4.0)),
			"tomb": Areas._at(tr, Vector3(0, 0, -5.8))}})
	spots["unwritten"] = Areas._at(tr, Vector3(2.0, 0, 12.0))
	return flicker
