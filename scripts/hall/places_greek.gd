extends RefCounted
## The places of the Greek books from the fourth on, built like places.gd's villa and Lyceum (the
## same returned dictionary, the same lost-to-whole pieces, a lesson stone with a scene for every
## point) out of the kits made for them: kit_rome.gd, kit_greek.gd, the areas in
## kit_greek_areas.gd, and their people and props. Where a book is played, its moments are beats
## (beat.gd, content/greece/beats.json): an interactable {"kind": "beat"} that also carries its
## lesson point, so it counts like a stone.
##   domus()  #4 the Rhetorica ad Herennium: a house in Rome, its memory house, the court in the Forum

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
