extends RefCounted
## The Nexus: the first place, a dark and starry realm of the mind above every world, lying in
## pieces. Islands of stone hang in nothing. On the Heart in the middle stands the cracked base
## of the Tower of the Reformed Man, under the ghost of the Tower that once stood. Round it hangs
## one door per world, each in its world's style. Only Greece's door is joined to the Heart, by
## a broken bridge; the other nine drift out of reach, sealed, except where a world's hub is built
## (Rome's city): its stele on the rim takes you there. Understanding mends it: every idea
## lights a star, every book mastered raises a column, and the named pieces in content/nexus.json
## come back in order (the altar fire, the path, Greece's warm door, colour, the shades' song,
## the Greek tier).
##
## build() returns what every place returns (Places), plus:
##   "arrivals": {from: [spot, yaw]}, "drift": what the Hall floats and turns (Kit.drifting),
##   "ground": where you can stand, discs {"c": Vector2, "r"} and rects {"rect": Rect2} in x/z,
##   "rails": the invisible rails round that ground, as x/z segments {"a", "b"},
##   "columns": the works whose columns stand, and "looks": what the pieces changed.

const Kit := preload("res://scripts/hall/kit.gd")
const Places := preload("res://scripts/hall/places.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")
const Doors := preload("res://scripts/hall/doors.gd")

const FILE := "res://content/nexus.json"
const WORLDS_FILE := "res://content/worlds.json"

const SPAWN := Vector3(8.9, 0.05, 6.47)
const ARRIVAL := Vector3(0, 0.05, -29.5)  # on Greece's island, coming back from the Shore
const HEART_R := 16.0
const GREEK_AT := Vector3(0, 0, -31)
const GREEK_R := 6.0
const DOOR_AT := Vector3(0, 0, -34)
const BRIDGE_FROM := Vector3(0, 0, -15.2)
const BRIDGE_TO := Vector3(0, 0, -25.2)
const BRIDGE_W := 3.2
const PLINTH_TOP := 1.05
const SLOTS := 16  # one column for each Greek book (the Rhetorica is Rome's)
const SLOT_R := 4.9
const POINTS_PER_BOOK := 6  # about as many ideas as a book's lesson has today (for_stage)

## Each world's door style, for a worlds.json that does not name one yet.
const STYLES := {"greece": "greek", "rome": "roman", "bible": "israelite", "late_antiquity": "byzantine",
	"medieval": "gothic", "judaism_islam": "moorish", "asia": "torii", "renaissance": "palladian",
	"modern_mind": "modern", "modern_imagination": "surreal"}
## Where each later world's island hangs, in ring order after Greece: [metres out, height, tilt in degrees].
const RING := [[38.0, 5.0, 5.0], [42.0, -7.0, 7.0], [40.0, 10.0, 4.0], [45.0, -4.0, 6.0], [41.0, 14.0, 8.0],
	[47.0, -10.0, 5.0], [40.0, 7.0, 7.0], [44.0, -5.0, 4.0], [48.0, 18.0, 25.0]]
## The ruins of the later worlds, far behind their doors: [bearing, metres out, height, kind, size].
const WRECKS := [[40.0, 230.0, -20.0, "aqueduct", 1.0], [76.0, 260.0, 30.0, "ziggurat", 1.1],
	[112.0, 210.0, -40.0, "dome", 0.9], [148.0, 290.0, 15.0, "spire", 1.25], [184.0, 240.0, -25.0, "minaret", 1.0],
	[220.0, 270.0, 35.0, "pagoda", 1.1], [292.0, 250.0, -10.0, "clock", 1.0]]
## Far clouds of colour: [where, size, tint].
const NEBULAE := [[Vector3(60, 120, -700), 500.0, "3c3450"], [Vector3(-600, 200, -400), 450.0, "2c3c44"],
	[Vector3(520, -150, -480), 550.0, "463a40"], [Vector3(0, 460, 300), 600.0, "3c3450"],
	[Vector3(-420, -340, 360), 400.0, "2c3c44"], [Vector3(660, 110, 240), 450.0, "463a40"]]
## Rivers of faint light through the void: [from, to].
const RIVERS := [[Vector3(-300, -40, -80), Vector3(300, -40, -80)], [Vector3(0, 110, -300), Vector3(0, 110, 300)],
	[Vector3(-150, -60, 200), Vector3(150, 20, 320)]]
## Where the three mourning shades sit at the edge (bearings, 14 m out).
const MOURNERS := [18.0, 198.0, 270.0]
## Dark cracks across the Heart, clear of the plinth: [bearing, metres out, length, turn from the rim's line].
const CRACKS := [[62.0, 10.5, 5.5, 0.5], [148.0, 11.5, 4.5, -0.4], [205.0, 9.8, 6.5, 0.9], [262.0, 12.2, 4.0, -0.6],
	[330.0, 10.0, 7.0, 0.25]]
const HAND_AT := Vector3(-9.53, 0, -5.5)

static var _content: Dictionary = {}


## content/nexus.json: the name, the first line, the hint, the rule, the pieces that come back
## (with what each needs and the line that tells you), the colour at each stage, and the news lines.
static func content() -> Dictionary:
	if _content.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if data is Dictionary:
			_content = data
		else:
			push_error("Bad or missing %s" % FILE)
	return _content


## What you have mended so far: "points", the lesson points understood (only those still in their
## book's lesson), and "mastered", the works mastered, in reading order. Reads the save without
## adding anything to it.
static func now(progress: RefCounted, doors: Array) -> Dictionary:
	var points := 0
	var mastered: Array = []
	var works: Dictionary = progress.data.get("works", {}) if progress else {}
	for d in doors:
		var work: String = d["work"]
		var entry: Variant = works.get(work, {})
		if not entry is Dictionary:
			continue
		var ids: Array = Rooms.room(work).get("lesson", []).map(func(p: Dictionary) -> String: return p["id"])
		for id in entry.get("understood", []):
			if ids.has(id):
				points += 1
		if entry.get("mastered", false) == true:
			mastered.append(work)
	var out := {"points": points, "mastered": mastered}
	var rome: Dictionary = load("res://scripts/hall/urbs_standing.gd").nexus_state(progress) if progress else {}
	if not rome.is_empty():
		out["rome"] = rome
	return out


## The named pieces that are back, in order. Each needs every earlier piece back too, so they
## return one after another however they were earned.
static func back(state: Dictionary) -> Array:
	var points := int(state.get("points", 0))
	var books: int = (state.get("mastered", []) as Array).size()
	var out: Array = []
	for r in content().get("restores", []):
		var need: Dictionary = r.get("need", {})
		if points < int(need.get("points", 0)) or books < int(need.get("books", 0)):
			break
		out.append(r["what"])
	return out


## A made-up state with exactly the first k pieces back, for screenshots and auditions: just
## enough ideas and books (the first books on the reading list), counting about POINTS_PER_BOOK
## ideas for each book mastered so the stars look right.
static func for_stage(k: int, doors: Array) -> Dictionary:
	var restores: Array = content().get("restores", [])
	var points := 0
	var books := 0
	for r in restores.slice(0, clampi(k, 0, restores.size())):
		points = maxi(points, int(r["need"].get("points", 0)))
		books = maxi(books, int(r["need"].get("books", 0)))
	var mastered: Array = doors.slice(0, books).map(func(d: Dictionary) -> String: return d["work"])
	var state := {"points": maxi(points, books * POINTS_PER_BOOK), "mastered": mastered}
	if back(state).size() != k:
		state["points"] = points
	return state


## The furthest world you have begun (an idea understood in one of its books) that has a hub:
## the Nexus takes its sharpness (Greece, or Rome once a Roman book is begun).
static func world_reached(progress: RefCounted) -> String:
	var worlds := _worlds({})
	var order: Array = worlds.keys()
	if order.is_empty():
		return "greece"
	var best := 0
	var works: Dictionary = progress.data.get("works", {}) if progress else {}
	for work in works:
		var entry: Variant = works[work]
		if not entry is Dictionary or (entry.get("understood", []) as Array).is_empty():
			continue
		var w: String = Rooms.room(work).get("world", "greece")
		var i := order.find(w)
		if i > best and _hub(worlds, w) != "":
			best = i
	return order[best]


## The worlds in ring order: the ones given, or content/worlds.json when none are.
static func _worlds(worlds: Dictionary) -> Dictionary:
	if not worlds.is_empty():
		return worlds
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORLDS_FILE))
	return data if data is Dictionary else {"greece": {"name": "Greece"}}


## Where a world's door leads: its hub ("hub" for Greece's Shore, "urbs" for the city of Rome), or ""
## while it has none.
static func _hub(worlds: Dictionary, id: String) -> String:
	return str(worlds.get(id, {}).get("hub", "hub" if id == "greece" else ""))


## Builds a world's door at the sharpness of its own world (capped at 3), then puts it back.
static func _door(parent: Node3D, at: Vector3, yaw: float, id: String, worlds: Dictionary, state: String) -> Dictionary:
	var keep := Kit.detail
	Kit.detail = mini(int(worlds.get(id, {}).get("detail", 1)), 3)
	var style := str(worlds.get(id, {}).get("door", STYLES.get(id, "greek")))
	var d: Dictionary = Doors.build(parent, at, yaw, style, state)
	Kit.detail = keep
	return d


## Drift entries for the loose blocks of a door: each bobs a little and turns slowly.
static func _loose(d: Dictionary, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for n in d.get("loose", []):
		if n is Node3D:
			out.append(Kit.drifting(n, rng.randf_range(0.12, 0.3), rng.randf_range(6.0, 11.0), rng.randf() * TAU,
				Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * deg_to_rad(rng.randf_range(3.0, 8.0))))
	return out


## The Nexus as far as `state` ({"points", "mastered"}) has mended it. `worlds` gives the doors,
## in ring order (Worlds.all(); empty reads content/worlds.json); `doors` is the reading list
## (Rooms.doors()), whose first 17 books are the columns.
static func build(world: Node3D, worlds: Dictionary, doors: Array, state: Dictionary) -> Dictionary:
	var c := content()
	worlds = _worlds(worlds)
	var b := back(state)
	var points := int(state.get("points", 0))
	var mastered: Array = state.get("mastered", [])
	var sats: Array = c.get("saturation", [0.2])
	var saturation: float = sats[mini(b.size(), sats.size() - 1)]
	var ember := b.has("ember")
	var whole := b.has("path")
	var warm := b.has("greek_door")
	var colour := b.has("colour")
	var lifted := b.has("shades")
	var tier_whole := b.has("greek_tier")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var drift: Array = []
	var flicker: Array = []
	var spots := {"arrival": ARRIVAL, "tower": Vector3.ZERO}
	var gates: Array = []  # interactables, gathered in the order they are listed
	var others: Array = []
	var shades: Array = []
	var columns_seen: Array = []
	var arrivals := {"hub": [ARRIVAL, PI]}

	# the void: dark, dead stars, one warm star per idea
	Kit.the_void(world, saturation)
	Kit.void_stars(world, 700, 71)
	Kit.idea_stars(world, points)

	# the Heart, its rails, the bridge and Greece's island
	Kit.shard(world, Vector3.ZERO, HEART_R, 26.0, true, "voidstone", 13, 14)
	var rails: Array = Kit.rim(world, Vector3.ZERO, 15.2, [Vector2(0.0, BRIDGE_W)])
	var bridge := Kit.span(world, BRIDGE_FROM, BRIDGE_TO, BRIDGE_W, whole)
	rails.append_array(bridge["rails"])
	drift.append_array(bridge["drift"])
	var greek_island := Kit.shard(world, GREEK_AT, GREEK_R, 12.0, true, "voidstone", 31, 12)
	for k in 3:  # chunks hanging under it
		var chunk := Kit.group(world, GREEK_AT + Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-15.0, -11.0), rng.randf_range(-3.0, 3.0)))
		Kit.blob(chunk, Vector3.ZERO, rng.randf_range(0.6, 1.1), "voidstone", Vector3(1.2, 0.8, 1.0), 5)
		drift.append(Kit.drifting(chunk, rng.randf_range(0.4, 0.8), rng.randf_range(10.0, 18.0), rng.randf() * TAU,
			Vector3(0, deg_to_rad(rng.randf_range(2.0, 4.0)), 0)))
	greek_island.name = "Greece"
	rails.append_array(Kit.rim(world, GREEK_AT, 5.5, [Vector2(180.0, BRIDGE_W)]))
	var ground: Array = [{"c": Vector2.ZERO, "r": 15.55}, {"c": Vector2(GREEK_AT.x, GREEK_AT.z), "r": 5.75},
		{"rect": Rect2(-1.75, BRIDGE_TO.z - 0.4, 3.5, BRIDGE_FROM.z - BRIDGE_TO.z + 0.8)}]

	# Greece's door, cold until a book is mastered, and the thread of light to the altar
	var ids: Array = worlds.keys()
	var first: String = ids[0] if not ids.is_empty() else "greece"
	var greek := _door(world, DOOR_AT, 0.0, first, worlds, "warm" if warm else "cold")
	if greek.get("light") is OmniLight3D:
		flicker.append(greek["light"])
	drift.append_array(_loose(greek, rng))
	gates.append({"kind": "gate", "pos": Vector3(0, 0, -31.6), "world": first, "to": _hub(worlds, first), "open": true,
		"text": str(worlds.get(first, {}).get("name", "Greece"))})
	spots["greece"] = Vector3(0, 0, -31.6)
	if warm:
		Kit.current(world, Vector3(0, 1.6, -33.2), Vector3(0, 1.9, -0.9), "mote_gold", 80, 17.0, Vector2(2.0, 2.0), false, 0.18)
	else:  # the thread breaks: it dies away after six metres
		Kit.current(world, Vector3(0, 1.6, -33.2), Vector3(0, 1.9, -0.9), "mote", 24, 3.0, Vector2(2.0, 2.0), false, 0.18)

	# the base of the Tower: a plinth you walk round, 17 column slots, the altar and its beam
	for step in [[6.5, 0.0], [6.0, 0.35], [5.6, 0.7]]:
		Kit.cylinder(world, Vector3(0, step[1], 0), step[0], 0.35, "voidstone", false, 12)
	var slope := CylinderMesh.new()  # an unseen gentle slope over the steps, so you walk straight up
	slope.top_radius = 5.5
	slope.bottom_radius = 6.9
	slope.height = PLINTH_TOP
	Kit.solid(world, slope.create_convex_shape(), Vector3(0, PLINTH_TOP / 2.0, 0))
	var standing: Array = []
	for k in SLOTS:
		var work: String = doors[k]["work"] if k < doors.size() else ""
		var up := work != "" and mastered.has(work)
		standing.append(up)
		var bearing := k * 360.0 / SLOTS
		Kit.column(world, Kit.sky_point(bearing, 0.0, SLOT_R) + Vector3(0, PLINTH_TOP, 0), 4.2, not up)
		if up:
			columns_seen.append(work)
			var title := _title(doors[k])
			others.append({"kind": "look", "pos": Kit.sky_point(bearing, 0.0, 7.2), "text": "Look at the column of the %s" % title,
				"note": "%s. Its column stands." % title})
	var tower := Kit.tower(world, Vector3(0, PLINTH_TOP, 0), standing, tier_whole)
	Kit.box(world, Vector3(0, 1.45, 0), Vector3(1.6, 0.8, 1.6), "stone", false)  # the altar
	var beam_q := QuadMesh.new()
	beam_q.size = Vector2(3.0 if ember else 1.2, 400.0)
	var beam := Kit.mesh(world, beam_q, "beam" if ember else "beam_faint", Vector3(0, 1.85 + 200.0, 0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ember:
		for p in [Vector3(0, 2.1, 0), Vector3(0.22, 2.0, 0.12), Vector3(-0.18, 2.02, -0.12)]:
			Kit.blob(world, p, 0.26, "fire", Vector3(1.0, 1.6, 1.0), 5)
		var sparks := Kit._drift(world, Vector3(0, 2.2, 0), 12, 2.5, 0.06, "fire", Vector3.UP, 25.0, Vector2(0.6, 1.2))
		sparks.gravity = Vector3(0, 0.2, 0)
		var fire := OmniLight3D.new()
		fire.position = Vector3(0, 2.8, 0)
		fire.light_color = Color("ff9a48")
		fire.light_energy = 1.6
		fire.omni_range = 10.0
		world.add_child(fire)
		flicker.append(fire)

	# the nine sealed doors, adrift out of reach, each with its stele on the rim and a broken way
	var clear: Array = [[DOOR_AT + Vector3(0, 3, 0), 8.0]]  # where near debris must not hang
	var step_deg := 360.0 / maxi(ids.size(), 1)
	for i in range(1, ids.size()):
		var id: String = ids[i]
		var bearing := i * step_deg
		var ring: Array = RING[(i - 1) % RING.size()]
		var at := Kit.sky_point(bearing, 0.0, ring[0]) + Vector3(0, ring[1], 0)
		var frag := Kit.group(world, at, Kit.face_yaw(at, Vector3(0, at.y, 0)))
		var lean := deg_to_rad(ring[2])
		frag.rotation.x = lean * (0.6 if i % 2 == 0 else -0.6)
		frag.rotation.z = lean * (0.8 if i % 3 == 0 else -0.8)
		Kit.shard(frag, Vector3.ZERO, 5.0, rng.randf_range(8.0, 11.0), false, "voidstone", 100 + i, 12)
		var hub := _hub(worlds, id)  # a world with its hub built opens its door: its stele takes you there
		var d := _door(frag, Vector3(0, 0, -0.5), 0.0, id, worlds, "sealed" if hub == "" else "cold")
		var cold := OmniLight3D.new()
		cold.position = Vector3(0, 2.5, 3.0)
		cold.light_color = Color("8a94b0")
		cold.light_energy = 0.35
		cold.omni_range = 10.0
		frag.add_child(cold)
		Kit.unsolid(frag)
		drift.append(Kit.drifting(frag, 0.8, rng.randf_range(20.0, 30.0), rng.randf() * TAU, Vector3.ZERO, deg_to_rad(3.0)))
		drift.append_array(_loose(d, rng))
		clear.append([at + Vector3(0, 3, 0), 8.0])
		var stele_at := Kit.sky_point(bearing, 0.0, 14.3)
		var reader := Kit.stele(world, stele_at, Kit.face_yaw(stele_at, Vector3.ZERO))
		gates.append({"kind": "gate", "pos": reader, "world": id, "to": hub, "open": hub != "",
			"text": str(worlds[id].get("name", id))})
		if hub != "":  # coming back from that world, you stand at its stele, facing the Heart
			arrivals[hub] = [stele_at.lerp(Vector3.ZERO, 0.12) + Vector3(0, 0.05, 0), Places.look_yaw(-stele_at)]
		drift.append_array(Kit.stub(world, bearing, at))
		for r in [21.0, 24.5, 28.0, 31.5]:
			clear.append([Kit.sky_point(bearing, 0.0, r) + Vector3(0, lerpf(0.0, at.y, (r - 17.5) / (ring[0] - 17.5)), 0), 4.0])

	# what Rome has brought back, round its stele: the heroes, the dedication, the treasury, the
	# masks, the choir, the frieze of the rites and the Ledger
	var rome_i := ids.find("rome")
	if rome_i > 0 and state.has("rome"):
		others.append_array(_rome_pieces(world, rome_i * step_deg, state["rome"]))

	# the Heart's own ruin: cracks, a broken parapet, loose rocks drifting off the edge
	for cr in CRACKS:
		_crack(world, cr[0], cr[1], cr[2], cr[3])
	var gap_bearings: Array = [0.0, 300.0]  # the bridge, and behind the stone hand
	for i in range(1, ids.size()):
		gap_bearings.append(i * step_deg)
	for k in 28:
		var bearing := k * 360.0 / 28.0
		if gap_bearings.any(func(g: float) -> bool: return absf(angle_difference(deg_to_rad(g), deg_to_rad(bearing))) < deg_to_rad(6.5)):
			continue
		var h := 0.6 if rng.randf() < 0.6 else rng.randf_range(0.3, 0.55)
		Kit.box(world, Kit.sky_point(bearing, 0.0, 15.5) + Vector3(0, h / 2.0, 0), Vector3(3.3, h, 0.5), "voidstone", false,
			Vector3(0, -deg_to_rad(bearing), rng.randf_range(-0.05, 0.05)))
	for k in 8:
		var bearing := rng.randf_range(20.0, 340.0)
		var rock := Kit.group(world, Kit.sky_point(bearing, 0.0, rng.randf_range(17.0, 20.0)) + Vector3(0, rng.randf_range(-1.0, 2.0), 0))
		Kit.blob(rock, Vector3.ZERO, rng.randf_range(0.3, 0.7), "voidstone", Vector3(1.3, 0.8, 1.0), 5)
		drift.append(Kit.drifting(rock, rng.randf_range(0.2, 0.5), rng.randf_range(8.0, 16.0), rng.randf() * TAU,
			Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * deg_to_rad(rng.randf_range(2.0, 6.0))))
	var dust := Kit._drift(world, Vector3(0, 0.2, 0), 30 if colour else 60, 14.0, 0.1, "ash", Vector3.UP, 30.0, Vector2(0.2, 0.5))
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	dust.emission_ring_axis = Vector3.UP
	dust.emission_ring_radius = 15.3
	dust.emission_ring_inner_radius = 14.5
	dust.emission_ring_height = 0.2
	dust.preprocess = 14.0
	dust.radial_accel_min = 0.08
	dust.radial_accel_max = 0.15

	# what hangs round it: near pieces, a far cloud of rock, rivers of light, nebulae, far wrecks
	drift.append_array(_near_debris(world, ground, clear))
	var cloud := Kit.debris(world, 29, 140, 60.0, 120.0, -50.0, 60.0)
	drift.append(Kit.drifting(cloud, 0.0, 60.0, 0.0, Vector3(0, deg_to_rad(0.5), 0)))
	for river in RIVERS:
		Kit.current(world, river[0], river[1], "mote", 150, 40.0, Vector2(3.0, 6.0))
	for n in NEBULAE:
		Kit.nebula(world, n[0], n[1], Color(n[2]))
	for w in WRECKS:
		var wreck := Kit.far_wreck(world, Kit.sky_point(w[0], 0.0, w[1]) + Vector3(0, w[2], 0), w[3], w[4])
		drift.append(Kit.drifting(wreck, 2.0, rng.randf_range(40.0, 60.0), rng.randf() * TAU, Vector3.ZERO, deg_to_rad(2.0)))

	# the rule, the stone hand, the mourning shades, the bench
	var rule_at := Vector3(6.9, 0, 3.2)
	var rule_reader := Kit.stele(world, rule_at, Kit.face_yaw(rule_at, SPAWN))
	var lines: Array = [{"kind": "fact", "pos": rule_reader, "text": str(c.get("rule", ""))}]
	spots["rule"] = rule_reader
	Kit.stone_hand(world, HAND_AT, Kit.face_yaw(HAND_AT, Vector3.ZERO))
	var hand_look := Vector3(-7.97, 0, -4.6)
	lines.append({"kind": "look", "pos": hand_look, "text": "Look at the stone hand",
		"note": "The stone hand of the man who crowned the Tower. It still reaches up."})
	spots["hand"] = hand_look
	for m in MOURNERS:
		if tier_whole and m == MOURNERS[0]:
			continue  # the shade nearest Greece is at peace
		var at := Kit.sky_point(m, 0.0, 14.0)
		Kit.mourner(world, at, Kit.face_yaw(at, Vector3.ZERO if lifted else at * 2.0), lifted)
		var note := "A shade sits at the edge. It has turned back toward the Tower, and it sings." if lifted \
			else "A shade sits at the broken edge, head bowed. Whatever it knew, it has forgotten."
		shades.append({"kind": "look", "pos": at - at.normalized() * 1.6, "text": "Look at the shade", "note": note})
	var bench := Places.seat(world, Vector3(-10.92, 0, 7.94), Vector3(-0.809, 0, 0.588), "Sit and look into the dark")
	spots["bench"] = bench["pos"]

	for body in world.find_children("Rails*", "StaticBody3D", true, false):
		body.free()  # the edges are open: step off and the void gives you back where you came in
	var out: Array = gates + lines + shades + others + [bench]
	var looks := {"saturation": saturation, "bridge": "whole" if whole else "broken", "greek_door": "warm" if warm else "cold",
		"shades": "lifted" if lifted else "bowed", "ember": ember, "stars": clampi(points, 0, 800), "dust": dust.amount,
		"ghost_columns": tower["ghost_columns"]}
	return {"name": str(c.get("name", "The Nexus")), "interactables": out, "spawn": SPAWN,
		"yaw": Places.look_yaw(Vector3(-2, 0, -24) - SPAWN), "pitch": 0.15, "spots": spots, "flicker": flicker,
		"people": [], "sway": [], "birds": [], "back": b, "restored": 0, "arrivals": arrivals,
		"drift": drift, "ground": ground, "rails": rails, "columns": columns_seen, "looks": looks}


## Rome's pieces on the Heart, about its stele at `bearing`: each complete set of what you gathered
## in the city brings its piece back (content/rome/collections.json); the frieze gains a panel for
## each recurring rite played in all seven ages; the Ledger stands as soon as there is anything in it,
## written, never scored, and is carved when Rome is complete.
static func _rome_pieces(world: Node3D, bearing: float, rome: Dictionary) -> Array:
	const Rome := preload("res://scripts/hall/kit_rome.gd")
	var out: Array = []
	var sets: Array = rome.get("sets", [])
	var all_sets: Dictionary = rome.get("all_sets", {})
	var place := func(off: float, r: float) -> Vector3: return sky_rim(bearing + off, r)
	var facing := func(at: Vector3) -> float: return Kit.face_yaw(at, Vector3.ZERO)
	if sets.has("exempla"):
		for off: float in [-6.0, 6.0]:
			var at: Vector3 = place.call(off, 13.0)
			Kit.cylinder(world, at, 0.45, 0.6, "marble", true, 8)
			var who: Dictionary = Rome.togatus(world, at + Vector3(0, 0.6, 0), facing.call(at),
				{"robe": "e8e4dc", "skin": "e8e4dc", "hair_color": "e8e4dc", "beard": "short"})
			Kit.unsolid(who["root"])
		out.append({"kind": "look", "pos": place.call(0.0, 12.2), "text": "Look at the heroes of Rome",
			"note": "Horatius and Decius Mus in marble, by Rome's door. %s" % all_sets.get("exempla", {}).get("line", "")})
	if sets.has("inscriptions"):
		var at: Vector3 = place.call(-10.0, 11.0)
		Kit.box(world, at + Vector3(0, 0.5, 0), Vector3(1.6, 1.0, 0.3), "marble", true, Vector3(0, facing.call(at), 0))
		out.append({"kind": "look", "pos": at + (Vector3.ZERO - at).normalized() * 1.0, "text": "Read Rome's dedication",
			"note": "SENATUS POPULUSQUE ROMANUS\n\nThe Senate and the People of Rome. Every inscription you read in the city, from the Black Stone to a tile that said only ROMA."})
	if sets.has("coins"):
		var at: Vector3 = place.call(18.0, 12.5)
		Kit.box(world, at + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.6), "bronze", true, Vector3(0, facing.call(at), 0))
		for k in 7:
			Kit.blob(world, at + Vector3(-0.3 + k * 0.1, 0.66, 0), 0.05, "gold" if k < 3 else "bronze", Vector3(1.0, 0.3, 1.0), 6)
		out.append({"kind": "look", "pos": at + (Vector3.ZERO - at).normalized() * 1.0, "text": "Look at Rome's treasury",
			"note": "Seven coins on the chest, one for each age: the heavy bronze as, the silver denarius, the moneyers' denarius, the sestertius, the washed bronze, the tiny nummus, and the follis of an emperor who never came, beside a Goth king's copper."})
	if sets.has("masks"):
		var at: Vector3 = place.call(-16.0, 11.5)
		Kit.box(world, at + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 0.3), "stone", true, Vector3(0, facing.call(at), 0))
		for k in 3:
			var m: Vector3 = at + (Vector3.ZERO - at).normalized() * 0.2 + Vector3(0, 1.2, 0) + Basis(Vector3.UP, facing.call(at)) * Vector3(-0.6 + k * 0.6, 0, 0)
			Kit.blob(world, m, 0.14, "#d8c8a0", Vector3(0.8, 1.0, 0.5), 6)
		out.append({"kind": "look", "pos": at + (Vector3.ZERO - at).normalized() * 1.2, "text": "Look at the ancestors' masks",
			"note": "The wax faces in their niches, each with its label: consul, censor, triumphed. The ones that melted are here too, somehow."})
	if sets.has("voices"):
		for k in 5:
			var at: Vector3 = place.call(-8.0 + k * 4.0, 10.2)
			var g := Kit.group(world, at, facing.call(at))
			Kit.cylinder(g, Vector3.ZERO, 0.18, 0.9, "#b8a888", false, 6, 0.12)
			Kit.blob(g, Vector3(0, 1.05, 0), 0.12, "#c8a078")
		out.append({"kind": "look", "pos": place.call(0.0, 9.5), "text": "Listen to the choir",
			"note": "The families of the city, all their ages together: the farmer and the beggar, the soldier and the gladiator, the senator with his salt cellar and the one with his masks, the fishwives, the barbers. They are singing the old calendar's names."})
	var frieze: Array = rome.get("frieze", [])
	if not (rome.get("rites", {}) as Dictionary).is_empty():
		var at: Vector3 = place.call(12.0, 11.8)
		var yaw: float = facing.call(at)
		Kit.box(world, at + Vector3(0, 0.45, 0), Vector3(3.2, 0.9, 0.35), "stone", true, Vector3(0, yaw, 0))
		for k in frieze.size():
			Kit.box(world, at + Vector3(0, 0.5, 0) + Basis(Vector3.UP, yaw) * Vector3(-1.4 + k * 0.31, 0, 0.19), Vector3(0.26, 0.6, 0.04), "marble", false,
				Vector3(0, yaw, 0))
		var lines: Array = []
		for r: String in rome.get("rites", {}):
			var ages: Array = rome["rites"][r]
			lines.append("%s: %s" % [r.capitalize(), "carved, in all seven ages" if frieze.has(r) else "%d of seven ages" % ages.size()])
		out.append({"kind": "look", "pos": at + (Vector3.ZERO - at).normalized() * 1.0, "text": "Look at the frieze of the rites",
			"note": "[b]The frieze of the rites[/b]\n\nThe same rite, seven times, from the age of heroes to the emptied city.\n\n%s" % "\n".join(lines)})
	var ledger: Array = rome.get("ledger", [])
	if not ledger.is_empty():
		var at: Vector3 = place.call(-22.0, 12.0)
		var reader := Kit.stele(world, at, facing.call(at))
		var carved: bool = rome.get("complete", false)
		var by_age := {}
		for e: Dictionary in ledger:
			if not by_age.has(e["age"]):
				by_age[e["age"]] = []
			(by_age[e["age"]] as Array).append(str(e["text"]))
		var text: Array = ["[b]The Ledger[/b]%s" % ("" if carved else " (still being written)"),
			"What you did in Rome when it cost something. No score."]
		for age: String in ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]:
			if by_age.has(age):
				text.append("[i]%s[/i]\n%s" % [age.capitalize(), "\n".join(by_age[age])])
		if carved:
			text.append("Carved. Rome's lesson is that nobody else will keep the record.")
		out.append({"kind": "look", "pos": reader, "text": "Read the Ledger", "note": "\n\n".join(text)})
	return out


## A point on the Heart, `r` metres out along a bearing.
static func sky_rim(bearing: float, r: float) -> Vector3:
	return Kit.sky_point(bearing, 0.0, r)


## A book's short title for its column: "Isagoge", "Iliad" (the leading "The" left to the sentence).
static func _title(door: Dictionary) -> String:
	var room := Rooms.room(door["work"])
	var t: String = room.get("book", "")
	if t == "":
		var name: String = door.get("name", "")
		t = name.substr(name.find(", ") + 2) if name.contains(", ") else name
	return t.substr(4) if t.to_lower().begins_with("the ") else t


## A dark crack across the Heart: three thin zigzag strokes, `length` long in all, centred `r`
## out at `bearing`, turned `turn` radians off the rim's line.
static func _crack(world: Node3D, bearing: float, r: float, length: float, turn: float) -> void:
	var mid := Kit.sky_point(bearing, 0.0, r)
	var along := -deg_to_rad(bearing) + turn
	var dir := Vector3(cos(along), 0, -sin(along))
	for k in 3:
		var a := along + (0.35 if k % 2 == 0 else -0.35)
		var at := mid + dir * ((k - 1) * length / 3.0)
		Kit.box(world, at + Vector3(0, 0.005, 0), Vector3(length / 3.0 + 0.1, 0.02, 0.25 - 0.05 * k), "#0b0b10", false, Vector3(0, a, 0))


## True when `at` is well clear of all ground (6 m, seen from above) and of every point in
## `clear` ([point, how far]).
static func _clear_of(at: Vector3, ground: Array, clear: Array) -> bool:
	var flat := Vector2(at.x, at.z)
	for g in ground:
		if g.has("rect"):
			if (g["rect"] as Rect2).grow(6.0).has_point(flat):
				return false
		elif flat.distance_to(g["c"]) < g["r"] + 6.0:
			return false
	for c in clear:
		if at.distance_to(c[0]) < c[1]:
			return false
	return true


## Twenty-four pieces of the broken place hanging near the Heart: 18 rocks, three column drums, a
## capital, a cornice block and an arch stone. None hangs over ground, beside a door, or in the
## first view of Greece's door. Each bobs and tumbles slowly. Returns their drift entries.
static func _near_debris(world: Node3D, ground: Array, clear: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	var eye := SPAWN + Vector3(0, 1.55, 0)
	var sight := (DOOR_AT + Vector3(0, 3, 0) - eye).normalized()
	var kinds: Array = []
	for i in 18:
		kinds.append("rock")
	kinds.append_array(["drum", "drum", "drum", "capital", "cornice", "voussoir"])
	var out: Array = []
	var tries := 0
	while out.size() < kinds.size() and tries < 5000:
		tries += 1
		var at := Kit.sky_point(rng.randf() * 360.0, 0.0, rng.randf_range(20.0, 42.0)) + Vector3(0, rng.randf_range(-14.0, 16.0), 0)
		if not _clear_of(at, ground, clear) or (at - eye).normalized().dot(sight) > cos(deg_to_rad(12.0)):
			continue
		var piece := Kit.group(world, at)
		piece.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		match kinds[out.size()]:
			"rock":
				Kit.blob(piece, Vector3.ZERO, rng.randf_range(0.3, 1.2), "voidstone", Vector3(1.3, 0.8, 1.0), 5)
			"drum":
				Kit.cylinder(piece, Vector3(0, -0.4, 0), 0.32, 0.8, "marble", false, 8)
			"capital":
				Kit.box(piece, Vector3(0, 0.1, 0), Vector3(0.95, 0.36, 0.95), "marble", false)
				Kit.cylinder(piece, Vector3(0, -0.3, 0), 0.3, 0.22, "marble", false, 8, 0.45)
			"cornice":
				Kit.box(piece, Vector3.ZERO, Vector3(2.0, 0.5, 0.8), "marble", false)
				Kit.box(piece, Vector3(0, 0.3, 0.12), Vector3(2.0, 0.12, 0.7), "marble", false)
			"voussoir":
				Kit.cylinder(piece, Vector3(0, -0.45, 0), 0.35, 0.9, "marble", false, 4, 0.55)
		var spin := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() \
			* deg_to_rad(rng.randf_range(2.0, 6.0))
		out.append(Kit.drifting(piece, rng.randf_range(0.4, 1.2), rng.randf_range(12.0, 30.0), rng.randf() * TAU, spin))
	return out
