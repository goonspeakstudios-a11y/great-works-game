extends RefCounted
## The places you can walk: the Shore (the hub, a clifftop temple ruin over the sea at
## sunset, with one stone gateway per book in reading-list order) and each book's own
## place, set where and when it was written. Every builder returns what the Hall needs:
##   {"name", "interactables", "spawn", "yaw", "spots": {name: Vector3}, "flicker": [lights],
##    "teacher": {root, head, hand} or {}, "restored": columns standing again on the Shore}
## Interactable kinds: gate, fact, statue, map, tree, book, author.

const Kit := preload("res://scripts/hall/kit.gd")

const GATE_RADIUS := 25.0
const GATE_START_DEG := -26.0
const GATE_STEP_DEG := 14.5


## Facing a direction d with the player's forward (-Z turned by yaw).
static func look_yaw(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


static func gate_spot(i: int) -> Vector3:
	var a := deg_to_rad(GATE_START_DEG + GATE_STEP_DEG * i)
	return Vector3(cos(a), 0, sin(a)) * GATE_RADIUS


static func hub(world: Node3D, doors: Array, progress: RefCounted = null) -> Dictionary:
	Kit.sunset(world, "dusk")
	Kit.sea(world, -10.0)
	Kit.plateau(world, 34.0)
	# what was lost: a broken colossus, its fallen head, temples on far headlands, and the
	# empty foundation where the Tower of the Reformed Man will rise
	Kit.colossus_legs(world, Vector3(-13, 0, -8), 0.6)
	Kit.fallen_head(world, Vector3(14, 0, 12), -2.3)
	Kit.far_ruin(world, Vector3(190, -10, -110), 1.0)
	Kit.far_ruin(world, Vector3(-210, -10, -40), 1.3)
	Kit.far_ruin(world, Vector3(70, -10, 230), 0.9)
	Kit.tower_site(world, Vector3(-150, -10, -250))
	Kit.cylinder(world, Vector3(0, -0.02, 0), 7.0, 0.1, "paving", false, 12)
	var flicker: Array = [Kit.brazier(world, Vector3.ZERO)]
	var restored: int = progress.mastered_count() if progress else 0
	Kit.temple_ruin(world, Vector3(0, 0, -19), 0.0, restored)
	var out: Array = []
	var spots := {}
	for i in doors.size():
		var at := gate_spot(i)
		var d: Dictionary = doors[i]
		var mastered: bool = progress != null and progress.is_mastered(d["work"])
		var light := Kit.gateway(world, at, Kit.face_yaw(at, Vector3.ZERO), d["open"], mastered)
		if light:
			flicker.append(light)
		var stand := at * (1.0 - 1.8 / GATE_RADIUS)
		spots["gate%d" % i] = stand
		out.append({"kind": "gate", "pos": stand, "to": d["work"], "open": d["open"], "mastered": mastered,
			"text": "%d. %s%s" % [d["number"], d["name"], " (mastered)" if mastered else ""]})
		var between := deg_to_rad(GATE_START_DEG + GATE_STEP_DEG * (i + 0.5))
		if i < doors.size() - 1:
			Kit.cypress(world, Vector3(cos(between), 0, sin(between)) * 29.5, 6.0 + (i % 3))
	for p in [Vector3(8, 0, 4), Vector3(-10, 0, 6), Vector3(5, 0, 15), Vector3(-7, 0, 15),
			Vector3(13, 0, -4), Vector3(-17, 0, 1), Vector3(-1, 0, 19)]:
		Kit.olive(world, p, 1.0 + fmod(p.x * 0.37, 0.4))
	for p in [Vector3(20, 0, 12), Vector3(-19, 0, 13), Vector3(8, 0, -27), Vector3(-9, 0, -27), Vector3(16, 0, 19)]:
		Kit.rock(world, p, 0.9)
	var spawn := Vector3(0, 0.05, 5.0)
	return {"name": "The Shore of the Great Works", "interactables": out, "spawn": spawn,
		"yaw": look_yaw(gate_spot(0) - spawn), "spots": spots, "flicker": flicker, "teacher": {}, "restored": restored}


static func place(world: Node3D, work: String, room: Dictionary) -> Dictionary:
	match room.get("place", ""):
		"villa":
			return villa(world, work, room)
	push_error("No place built for %s" % work)
	return hub(world, [])


## Porphyry's villa at Lilybaeum in Sicily, 270 AD: a path of inscribed stones up from the
## gateway, a colonnaded courtyard with a pool, and his study with his portrait, desk and
## scrolls, the busts of Aristotle and Plotinus, the map of the world, and his Tree.
static func villa(world: Node3D, work: String, room: Dictionary) -> Dictionary:
	Kit.sunset(world)
	Kit.sea(world, -10.0)
	Kit.plateau(world, 40.0)
	Kit.mountain(world, Vector3(230, -10, -320), 150.0, 125.0, true)  # Etna, far off
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	# arrival: the way back to the Shore, and a path north to the villa
	var gate_at := Vector3(0, 0, 27)
	flicker.append(Kit.gateway(world, gate_at, Kit.face_yaw(gate_at, Vector3.ZERO), true))
	out.append({"kind": "gate", "pos": Vector3(0, 0, 25.3), "to": "hub", "open": true, "text": "Back to the Shore"})
	Kit.box(world, Vector3(0, 0.01, 12.5), Vector3(3.0, 0.02, 25.0), "path", false)
	var facts: Array = room.get("facts", [])
	for k in facts.size():
		var side := -1.0 if k % 2 == 0 else 1.0
		var at := Vector3(2.7 * side, 0, 21.0 - k * 2.9)
		var reader := Vector3(0.9 * side, 0, at.z)
		Kit.stele(world, at, Kit.face_yaw(at, reader))
		spots["fact%d" % k] = reader
		out.append({"kind": "fact", "pos": reader, "text": facts[k]})
	for z in [23.0, 17.0, 11.0, 5.0]:
		for x in [-5.0, 5.0]:
			Kit.cypress(world, Vector3(x, 0, z), 6.5)
	# the courtyard
	Kit.box(world, Vector3(0, 0.01, -6), Vector3(15.5, 0.02, 13.5), "paving", false)
	for x in [-7.0, -4.3, -1.7, 1.7, 4.3, 7.0]:
		Kit.column(world, Vector3(x, 0, 0), 4.0)
	for z in [-3.0, -6.0, -9.0, -12.0]:
		Kit.column(world, Vector3(-7, 0, z), 4.0)
		Kit.column(world, Vector3(7, 0, z), 4.0)
	Kit.box(world, Vector3(0, 4.15, 0), Vector3(15.0, 0.3, 2.4), "roof", false)
	for x in [-7.0, 7.0]:
		Kit.box(world, Vector3(x, 4.15, -6), Vector3(2.4, 0.3, 14.4), "roof", false)
	Kit.box(world, Vector3(0, 0.2, -6), Vector3(4.6, 0.4, 3.6), "marble")
	Kit.box(world, Vector3(0, 0.36, -6), Vector3(4.0, 0.04, 3.0), "water", false)
	Kit.olive(world, Vector3(4.2, 0, -9.0), 0.9)
	Kit.olive(world, Vector3(-4.0, 0, -3.2), 0.8)
	# the study, open to the courtyard
	Kit.box(world, Vector3(0, 2.1, -18.2), Vector3(10.8, 4.2, 0.4), "plaster")
	for x in [-5.2, 5.2]:
		Kit.box(world, Vector3(x, 2.1, -15.1), Vector3(0.4, 4.2, 6.6), "plaster")
	Kit.box(world, Vector3(0, 4.35, -15.1), Vector3(11.2, 0.3, 7.0), "roof", false)
	Kit.box(world, Vector3(0, 0.02, -15.1), Vector3(10.0, 0.02, 6.2), "stone", false)
	for x in [-2.6, 2.6]:
		Kit.column(world, Vector3(x, 0, -12.2), 4.2)
	Kit.scroll_shelf(world, Vector3(0, 0, -17.78), 0.0)
	flicker.append(Kit.desk(world, Vector3(0, 0, -15.8), PI, false))
	var teacher := Kit.teacher(world, Vector3(0, 0, -16.6), 0.0, room.get("portrait", {}))
	out.append({"kind": "author", "pos": Vector3(0, 0, -14.1), "text": "Talk to %s" % room["author"]})
	spots["author"] = Vector3(0, 0, -14.1)
	var statues: Array = room.get("statues", [])
	for k in statues.size():
		var sx := -2.6 if k == 0 else 2.6
		Kit.bust(world, Vector3(sx, 0, -17.2), 0.0, statues[k])
		out.append({"kind": "statue", "pos": Vector3(sx, 0, -15.6), "text": "Look at the bust of %s" % statues[k]["name"],
			"note": statues[k]["note"]})
		spots["statue%d" % k] = Vector3(sx, 0, -15.6)
	if room.has("map"):
		var tex := load("res://assets/maps/%s.png" % room["map"]) as Texture2D
		if tex:
			Kit.board(world, Vector3(-4.97, 2.2, -15.1), PI / 2.0, Vector2(2.9, 2.0), tex)
			out.append({"kind": "map", "pos": Vector3(-3.7, 0, -15.1), "map": room["map"], "text": "Study the map of the world in 270 AD",
				"note": room.get("map_note", "")})
			spots["map"] = Vector3(-3.7, 0, -15.1)
	if room.get("tree", false):
		Kit.board(world, Vector3(4.97, 2.2, -15.6), -PI / 2.0, Vector2(1.5, 1.8), tree_relief())
		out.append({"kind": "tree", "pos": Vector3(3.7, 0, -15.6), "text": "Look at Porphyry's Tree"})
		spots["tree"] = Vector3(3.7, 0, -15.6)
	Kit.box(world, Vector3(3.9, 0.5, -13.3), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(world, Vector3(3.9, 1.05, -13.3), Vector3(0.45, 0.06, 0.6), "parchment", false)
	out.append({"kind": "book", "pos": Vector3(3.9, 0, -12.1), "text": "Read a page of the %s" % room["book"]})
	spots["book"] = Vector3(3.9, 0, -12.1)
	for p in [Vector3(-12, 0, -8), Vector3(12, 0, -6), Vector3(-11, 0, 8), Vector3(12, 0, 10), Vector3(-15, 0, -20)]:
		Kit.olive(world, p, 1.1)
	for p in [Vector3(-9, 0, -20), Vector3(9, 0, -20)]:
		Kit.cypress(world, p, 7.5)
	for i in [0, 1]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(-3.4 + i * 6.8, 3.2, -15.2)
		lamp.light_color = Color("ffb870")
		lamp.light_energy = 0.8
		lamp.omni_range = 5.0
		world.add_child(lamp)
	spots["study"] = Vector3(0, 0, -11.0)
	var spawn := Vector3(0, 0.05, 23.5)
	return {"name": "%s - %s" % [room.get("where", ""), room.get("when", "")], "interactables": out, "spawn": spawn,
		"yaw": 0.0, "spots": spots, "flicker": flicker, "teacher": teacher, "restored": 0}


## Porphyry's Tree carved in marble: a trunk of kinds with a branch off each level.
static func tree_relief() -> ImageTexture:
	var img := Image.create(40, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color("d6ccb8"))
	var cut := Color("8a7e68")
	for y in range(4, 44):
		img.set_pixel(12, y, cut)
	for level in 5:
		var y := 6 + level * 9
		img.fill_rect(Rect2i(9, y - 2, 7, 5), cut)
		if level < 4:
			for x in range(16, 28):
				img.set_pixel(x, y + 4, cut)
			img.fill_rect(Rect2i(27, y + 2, 6, 4), cut)
	for x in 40:
		img.set_pixel(x, 0, Color("a89c84"))
		img.set_pixel(x, 47, Color("a89c84"))
	return ImageTexture.create_from_image(img)
