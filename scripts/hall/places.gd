extends RefCounted
## The places you can walk: the Shore (the hub, a clifftop temple ruin over the sea at
## sunset, with one stone gateway per book in reading-list order) and each book's own
## place, set where and when it was written. A book's place starts lost to the world (grey,
## dead, broken, its teacher a pale shade) and is built as far as it has been restored: one
## piece of it (the room's "restores" list, in order) for each lesson point understood.
## Every builder returns what the Hall needs:
##   {"name", "interactables", "spawn", "yaw", "spots": {name: Vector3}, "flicker": [lights],
##    "people": [{root, head, hand, ...}], "restored": columns standing again on the Shore,
##    "back": the pieces of the place that are back}
## Interactable kinds: gate, fact, statue, person, look, map, tree, book, author, seat.
## A builder may add "arrivals": {from: [spot, yaw]}, where you appear coming from that place.

const Kit := preload("res://scripts/hall/kit.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")

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
	var blink := far_toad(world, Vector3(360, -10, -624))  # 720 m out
	Kit.cylinder(world, Vector3(0, -0.02, 0), 7.0, 0.1, "paving", false, 12)
	var flicker: Array = [Kit.brazier(world, Vector3.ZERO)]
	var sway: Array = []
	var birds := Kit.flock(world, Vector3(0, 0, -2), 7, 16.0, 9.0)
	Kit.fireflies(world, Vector3(-8, 0, 10), 7.0)
	Kit.fireflies(world, Vector3(9, 0, 2), 6.0)
	var restored: int = progress.mastered_count() if progress else 0
	Kit.temple_ruin(world, Vector3(0, 0, -19), 0.0, restored)
	var out: Array = []
	var spots := {}
	var shown: Array = doors.filter(func(d: Dictionary) -> bool: return Rooms.room(d["work"]).get("area_of", "") == "")
	for i in shown.size():
		var at := gate_spot(i)
		var d: Dictionary = shown[i]
		var mastered: bool = progress != null and progress.is_mastered(d["work"])
		var light := Kit.gateway(world, at, Kit.face_yaw(at, Vector3.ZERO), d["open"], mastered)
		if light:
			flicker.append(light)
		var stand := at * (1.0 - 1.8 / GATE_RADIUS)
		spots["gate%d" % i] = stand
		out.append({"kind": "gate", "pos": stand, "to": d["work"], "open": d["open"], "mastered": mastered,
			"text": "%d. %s%s" % [d["number"], d["name"], " (mastered)" if mastered else ""]})
		var between := deg_to_rad(GATE_START_DEG + GATE_STEP_DEG * (i + 0.5))
		if i < shown.size() - 1:
			sway.append(Kit.cypress(world, Vector3(cos(between), 0, sin(between)) * 29.5, 6.0 + (i % 3)))
	for p in [Vector3(8, 0, 4), Vector3(-10, 0, 6), Vector3(5, 0, 15), Vector3(-7, 0, 15),
			Vector3(13, 0, -4), Vector3(-17, 0, 1), Vector3(-1, 0, 19)]:
		sway.append(Kit.olive(world, p, 1.0 + fmod(p.x * 0.37, 0.4)))
	for p in [Vector3(20, 0, 12), Vector3(-19, 0, 13), Vector3(8, 0, -27), Vector3(-9, 0, -27), Vector3(16, 0, 19)]:
		Kit.rock(world, p, 0.9)
	out.append(seat(world, Vector3(-29.5, 0, 3.0), Vector3(-1, 0, 0)))
	Kit.box(world, Vector3(4, 1.2, 8), Vector3(0.3, 2.4, 0.3), "ph_marble_01")
	out.append({"kind": "gate", "pos": Vector3(4, 0, 8), "to": "asset_test", "open": true, "text": "GREECE TEST ASSET ZONE"})
	out.append({"kind": "gate", "pos": Vector3.ZERO, "to": "nexus", "open": true, "text": "The brazier: back to the Nexus"})
	var spawn := Vector3(0, 0.05, 5.0)
	return {"name": "The Shore of the Great Works", "interactables": out, "spawn": spawn,
		"yaw": look_yaw(gate_spot(0) - spawn), "spots": spots, "flicker": flicker, "people": [], "restored": restored,
		"sway": sway, "birds": birds, "blink": blink}



## GREECE TEST ASSET ZONE: a sunlit stoa for judging assets. Walk up the aisle: each bay pair
## shows one material used as it would be in a place (floor, back wall, column, plinth, eave),
## code-made on the LEFT and Poly Haven (CC0) on the RIGHT; press F in the aisle to read the
## names. At the far end, a round court of Poly Haven props on plinths, each labelled.
const ASSET_PAIRS := [
	["marble", "ph_marble_01"], ["marble", "ph_white_sandstone_bricks"],
	["paving", "ph_marble_tiles"], ["paving", "ph_stone_pathway"],
	["stone", "ph_large_sandstone_blocks"], ["rock", "ph_old_stone_wall"],
	["rock", "ph_rocky_terrain"], ["rock", "ph_cliff_side"],
	["plaster", "ph_clay_plaster"], ["plaster", "ph_white_plaster_rough_01"],
	["plaster", "ph_painted_plaster_wall"], ["rug", "ph_old_mosaic_floor"],
	["paving", "ph_marble_mosaic_tiles"], ["roof", "ph_clay_roof_tiles"],
	["clay", "ph_patterned_terracotta_tiling"], ["wood", "ph_oak_wood_planks"],
	["earth", "ph_sparse_grass"], ["path", "ph_dry_ground_rocks"],
	["withered", "ph_withered_grass"], ["drybed", "ph_mud_cracked_dry_03"],
	["path", "ph_coast_sand_01"],
]
const ASSET_PROPS := [
	["marble_bust_01", 1.0], ["horse_statue_01", 1.4], ["antique_ceramic_vase_01", 0.8],
	["ceramic_vase_01", 0.6], ["ceramic_vase_02", 0.6], ["ceramic_vase_03", 0.6], ["jug_01", 0.4],
	["brass_pot_01", 0.5], ["wooden_bowl_01", 0.35], ["wicker_basket_01", 0.6],
	["wooden_candlestick", 0.5], ["wooden_stool_01", 0.6], ["boulder_01", 1.6], ["rock_07", 1.0],
	["shrub_01", 1.4], ["tree_stump_01", 0.9], ["dead_tree_trunk", 2.6],
]
const BAY := 4.0  # metres per bay along the aisle


static func asset_test(world: Node3D) -> Dictionary:
	Kit.sunset(world, "golden")
	var n := ASSET_PAIRS.size()
	var far := -BAY * n
	var court := Vector3(0, 0, far - 9.0)
	Kit.box(world, Vector3(0, -0.1, (far - 24.0) / 2.0), Vector3(24, 0.2, -far + 28), "earth")  # the aisle and the court
	Kit.box(world, Vector3(0, 0.0, far / 2.0), Vector3(3.0, 0.04, -far + 6), "paving", false)
	var out: Array = []
	var flicker: Array = []
	var sway: Array = []
	for i in n:
		var z := -BAY * i - 2.0
		for side in 2:
			_bay(world, 1.0 if side == 1 else -1.0, z, ASSET_PAIRS[i][side])
		out.append({"kind": "look", "pos": Vector3(0, 0, z), "text": "%d. %s  |  %s" % [i + 1, ASSET_PAIRS[i][0], ASSET_PAIRS[i][1]],
			"note": "LEFT, code-made: \"%s\".\nRIGHT, Poly Haven (CC0): \"%s\"." % ASSET_PAIRS[i]})
		if i % 3 == 1:
			for x in [-1.3, 1.3]:
				flicker.append(Kit.brazier(world, Vector3(x, 0, z - BAY / 2.0)))
	# the round court of props
	Kit.cylinder(world, court + Vector3(0, -0.02, 0), 8.0, 0.08, "ph_marble_mosaic_tiles", false, 24)
	var m := ASSET_PROPS.size()
	for j in m:
		var a := PI * (0.1 + 0.8 * j / float(m - 1))  # a half ring opening toward the aisle
		var at := court + Vector3(-cos(a), 0, -sin(a)) * 6.5
		Kit.box(world, at + Vector3(0, 0.35, 0), Vector3(1.0, 0.7, 1.0), "ph_white_sandstone_bricks")
		prop(world, ASSET_PROPS[j][0], at + Vector3(0, 0.7, 0), ASSET_PROPS[j][1] * 1.6, Kit.face_yaw(at, court))
		out.append({"kind": "look", "pos": at.lerp(court, 0.25), "text": ASSET_PROPS[j][0],
			"note": "Poly Haven (CC0) model \"%s\", shown 1.6x life size (about %.1f m real) so it reads at a distance." % ASSET_PROPS[j]})
	flicker.append(Kit.brazier(world, court))
	for z in [2.0, far - 1.0]:
		for x in [-7.0, 7.0]:
			sway.append(Kit.cypress(world, Vector3(x, 0, z), 6.0))
	for p in [Vector3(-9, 0, far - 12), Vector3(9, 0, far - 12), Vector3(0, 0, far - 18)]:
		sway.append(Kit.olive(world, p, 1.2))
	out.append({"kind": "gate", "pos": Vector3(0, 0, 3), "to": "hub", "open": true, "text": "Back to the Shore"})
	var spawn := Vector3(0, 0.05, 1.5)
	return {"name": "GREECE TEST ASSET ZONE", "interactables": out, "spawn": spawn, "yaw": 0.0,
		"spots": {"court": court}, "flicker": flicker, "people": [], "sway": sway}


## One material as a place would wear it: floor, back wall with an eave, a column, a plinth.
static func _bay(world: Node3D, s: float, z: float, mat: String) -> void:
	Kit.box(world, Vector3(s * 4.2, 0.03, z), Vector3(5.0, 0.06, BAY - 0.3), mat, false)
	Kit.box(world, Vector3(s * 6.9, 1.6, z), Vector3(0.4, 3.2, BAY - 0.3), mat)
	Kit.box(world, Vector3(s * 6.4, 3.3, z), Vector3(1.6, 0.16, BAY - 0.1), mat, false, Vector3(0, 0, s * 0.35))
	Kit.cylinder(world, Vector3(s * 2.1, 0, z - 1.1), 0.28, 2.8, mat, true, 10)
	Kit.box(world, Vector3(s * 4.6, 0.3, z + 0.7), Vector3(1.4, 0.6, 1.4), mat)
	Kit.box(world, Vector3(s * 4.6, 0.75, z + 0.7), Vector3(0.9, 0.3, 0.9), mat)


## A Poly Haven model standing at `at`, scaled so its longest side is `height` metres.
static func prop(world: Node3D, id: String, at: Vector3, height: float, yaw: float) -> void:
	var path := "res://assets/polyhaven/models/%s/%s.gltf" % [id, id]
	if not ResourceLoader.exists(path):
		push_warning("missing model " + path)
		return
	var node := (load(path) as PackedScene).instantiate() as Node3D
	world.add_child(node)
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY  # the mesh's transform relative to the model's root
		var up: Node = mi
		while up != node:
			t = (up as Node3D).transform * t
			up = up.get_parent()
		var b: AABB = t * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var k := height / maxf(box.size[box.get_longest_axis_index()], 0.01)  # longest side, so a fallen trunk is not huge
	node.scale = Vector3.ONE * k
	node.rotation.y = yaw
	node.position = at - Vector3(box.get_center().x, box.position.y, box.get_center().z) * k


## A toad the size of a hill, squatting in the sea at the edge of the world, three quarters of it
## above the water and turned toward the Shore; the haze nearly hides it. Returns the eyes, which
## the Hall blinks.
static func far_toad(world: Node3D, at: Vector3) -> Array:
	var g := Kit.group(world, at, Kit.face_yaw(at, Vector3(0, at.y, 0)))
	g.scale = Vector3.ONE * 1.3
	const SKIN := "#3b3a2c"
	const DARK := "#2a2a1f"
	const PALE := "#6a6448"
	const WART := "#4a4632"
	Kit.blob(g, Vector3(0, 14, 0), 40.0, SKIN, Vector3(1.3, 0.8, 1.1), 14)  # the body, a quarter under water
	Kit.blob(g, Vector3(0, 6, 22), 34.0, PALE, Vector3(1.15, 0.55, 0.8), 12)  # the pale throat and belly
	Kit.blob(g, Vector3(0, 30, 34), 26.0, SKIN, Vector3(1.3, 0.7, 1.0), 14)  # the broad flat head
	Kit.box(g, Vector3(0, 24, 58), Vector3(52, 1.4, 3), DARK, false, Vector3(0.25, 0, 0))  # the long closed mouth
	for side in [-1.0, 1.0]:
		Kit.blob(g, Vector3(side * 26, 1, 44), 10.0, SKIN, Vector3(0.8, 1.5, 0.8), 10)  # a front leg
		for toe in [-1.0, 0.0, 1.0]:  # its splayed toes, just at the waterline
			Kit.blob(g, Vector3(side * 26 + toe * 5.5, -8, 51 + absf(toe) * -1.5), 2.6, SKIN, Vector3(0.7, 0.5, 1.8), 6)
		Kit.blob(g, Vector3(side * 44, 8, -10), 20.0, SKIN, Vector3(0.9, 0.9, 1.3), 10)  # a folded hind haunch
		Kit.blob(g, Vector3(side * 26, 38, 18), 9.0, WART, Vector3(0.9, 0.55, 1.8), 8)  # the swollen gland behind the eye
		Kit.blob(g, Vector3(side * 5, 33, 58), 1.4, DARK, Vector3.ONE, 5)  # a nostril
		Kit.box(g, Vector3(side * 30, 42, 26), Vector3(3, 1.2, 10), DARK, false)  # a dark stripe over the eye
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 70:  # warts over the back and head
		var a := rng.randf_range(-PI * 0.8, PI * 0.8)
		var up := rng.randf_range(0.25, 1.0)
		var on_head := k % 4 == 0
		var p := Vector3(sin(a) * 50.0 * (1.0 - up * 0.45), 14 + up * 31.0, -cos(a) * 42.0 * (1.0 - up * 0.3)) if not on_head 			else Vector3(rng.randf_range(-26, 26), 38 + rng.randf_range(-3, 3), rng.randf_range(24, 48))
		Kit.blob(g, p, rng.randf_range(1.5, 3.8), WART if k % 3 else DARK, Vector3(1, 0.6, 1), 5)
	for k in 8:  # dark mottling on the flanks
		Kit.blob(g, Vector3((1 if k % 2 else -1) * rng.randf_range(38, 48), rng.randf_range(10, 30), rng.randf_range(-24, 20)),
			rng.randf_range(6, 10), DARK, Vector3(0.35, 0.8, 1.2), 6)
	var eyes: Array = []
	for side in [-17.0, 17.0]:
		var eye := Kit.group(g, Vector3(side, 40, 40))
		Kit.blob(eye, Vector3(0, 1.5, 0), 9.0, SKIN, Vector3(1.0, 0.75, 0.95), 12)  # the lump of the eye
		Kit.blob(eye, Vector3(0, 3.2, 5.2), 4.6, "#9a7a34", Vector3(1.0, 0.8, 0.5), 10)  # the dull gold iris
		Kit.blob(eye, Vector3(0, 3.2, 5.9), 3.6, "#b8963e", Vector3(1.0, 0.8, 0.4), 8)  # a lighter ring inside it
		Kit.box(eye, Vector3(0, 3.2, 7.4), Vector3(5.0, 1.1, 0.4), "#0b0a08", false)  # the flat pupil
		Kit.blob(eye, Vector3(1.2, 4.6, 7.3), 0.5, "#d8c890", Vector3.ONE, 4)  # a glint
		Kit.box(eye, Vector3(0, 7.4, 1.5), Vector3(12, 1.2, 6), DARK, false)  # the heavy brow
		eyes.append(eye)
	return eyes


## A bench looking out in direction `facing`, and its interactable: you stand behind it and sit.
static func seat(world: Node3D, at: Vector3, facing: Vector3, text: String = "Sit and watch the sunset") -> Dictionary:
	Kit.bench(world, at, Kit.face_yaw(at, at + facing))
	return {"kind": "seat", "pos": at - facing * 1.6, "seat": at, "look": at + facing * 100.0, "text": text}


## Every piece any place can bring back. A place with no restore list is simply whole.
const ALL_PIECES := ["water", "leaves", "lamps", "walkway", "sun", "teacher", "household", "soldiers"]


## The pieces of a place that are back, in the order they return.
static func back(room: Dictionary, stage: int) -> Array:
	var restores: Array = room.get("restores", [])
	if restores.is_empty():
		return ALL_PIECES.duplicate()
	return restores.slice(0, stage).map(func(r): return r["what"])


## How much colour a place has: almost none while it is lost, all of it once it is whole.
static func saturation(room: Dictionary, stage: int) -> float:
	var total: int = room.get("restores", []).size()
	return 1.0 if total == 0 else lerpf(0.15, 1.0, float(stage) / total)


## The sky of a book's place as far as it is restored: its own light once the sun is back,
## otherwise the ashen sky with ash falling; colour returns piece by piece. Returns the pieces back.
static func _sky(world: Node3D, room: Dictionary, stage: int, mood: String, ash_at: Vector3, ash_size: float) -> Array:
	var b := back(room, stage)
	Kit.sunset(world, mood if b.has("sun") else "ashen", saturation(room, stage))
	if not b.has("sun"):
		Kit.ash(world, ash_at, ash_size)
	return b


## What the teacher is called: himself, or his shade until he is restored.
static func _who(room: Dictionary, b: Array) -> String:
	return room["author"] if b.has("teacher") else "the shade of %s" % room["author"]


## The teacher while his place is not yet whole: a pale shade, more solid with each piece back.
static func _haunt(person: Dictionary, stage: int) -> void:
	Kit.shade(person["root"], 0.3 + 0.08 * stage)
	person["shade"] = true


static func place(world: Node3D, work: String, room: Dictionary, stage: int = 0, stages: Dictionary = {}) -> Dictionary:
	match room.get("place", ""):
		"villa":
			return villa(world, work, room, stage)
		"lyceum":
			return lyceum(world, work, room, stage, stages)
		"domus":  # the later Greek books' places are in places_greek.gd (loaded here, not preloaded: it preloads this)
			return load("res://scripts/hall/places_greek.gd").domus(world, work, room, stage)
		"museum":
			return load("res://scripts/hall/places_greek.gd").museum(world, work, room, stage)
	push_error("No place built for %s" % work)
	return hub(world, [])


## Porphyry's villa at Lilybaeum in Sicily, 270 AD: a path of inscribed stones up from the
## gateway, a colonnaded courtyard with a pool, his study (desk and scrolls, the busts of
## Aristotle and Plotinus, the map of the world, his Tree) and the household room behind it.
## It starts lost, grey and cold, and comes back a piece at a time: the pool fills, the trees
## turn green, the lamps are lit, the sun comes back, Porphyry is himself, the household is home.
static func villa(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	var b := _sky(world, room, stage, "golden", Vector3(0, 0, -2), 22.0)
	var leaves := b.has("leaves")
	var lamps := b.has("lamps")
	Kit.sea(world, -10.0)
	Kit.plateau(world, 40.0)
	Kit.mountain(world, Vector3(230, -10, -320), 150.0, 125.0, true)  # Etna, far off
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, -6), 5, 10.0, 10.0) if leaves else []  # no birds over a dead place
	if leaves:
		Kit.fireflies(world, Vector3(0, 0, -6), 5.0)
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
			sway.append(Kit.cypress(world, Vector3(x, 0, z), 6.5, leaves))
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
	Kit.box(world, Vector3(0, 0.36, -6), Vector3(4.0, 0.04, 3.0), "water" if b.has("water") else "drybed", false)
	sway.append(Kit.olive(world, Vector3(4.2, 0, -9.0), 0.9, leaves))
	sway.append(Kit.olive(world, Vector3(-4.0, 0, -3.2), 0.8, leaves))
	# the study, open to the courtyard; its back wall has a doorway at the east end
	Kit.box(world, Vector3(-1.1, 2.1, -18.2), Vector3(8.6, 4.2, 0.4), "plaster")
	Kit.box(world, Vector3(5.0, 2.1, -18.2), Vector3(0.8, 4.2, 0.4), "plaster")
	Kit.box(world, Vector3(3.9, 3.4, -18.2), Vector3(1.4, 1.6, 0.4), "plaster", false)  # the lintel
	for x in [-5.2, 5.2]:
		Kit.box(world, Vector3(x, 2.1, -15.1), Vector3(0.4, 4.2, 6.6), "plaster")
	Kit.box(world, Vector3(0, 4.35, -15.1), Vector3(11.2, 0.3, 7.0), "roof", false)
	Kit.box(world, Vector3(0, 0.02, -15.1), Vector3(10.0, 0.02, 6.2), "stone", false)
	for x in [-2.6, 2.6]:
		Kit.column(world, Vector3(x, 0, -12.2), 4.2)
	Kit.scroll_shelf(world, Vector3(0, 0, -17.78), 0.0)
	flicker.append(Kit.desk(world, Vector3(0, 0, -15.8), PI, false, lamps))
	var teacher := Kit.teacher(world, Vector3(0, 0, -16.6), 0.0, room.get("portrait", {}))
	if not b.has("teacher"):
		_haunt(teacher, stage)
	var who := _who(room, b)
	out.append({"kind": "author", "pos": Vector3(0, 0, -14.1), "text": "Talk to %s" % who})
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
		sway.append(Kit.olive(world, p, 1.1, leaves))
	for p in [Vector3(-9, 0, -20), Vector3(9, 0, -20)]:
		sway.append(Kit.cypress(world, p, 7.5, leaves))
	if lamps:
		for i in [0, 1]:
			Kit.moths(world, Vector3(-3.4 + i * 6.8, 3.0, -15.2))
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(-3.4 + i * 6.8, 3.2, -15.2)
			lamp.light_color = Color("ffb870")
			lamp.light_energy = 0.8
			lamp.omni_range = 5.0
			world.add_child(lamp)
	# a house someone lived in: a rug under the desk, lamps, jars, bread and wine, plants, a lyre
	Kit.rug(world, Vector3(0, 0.03, -14.5), Vector2(4.4, 2.8))
	flicker.append(Kit.lamp_stand(world, Vector3(-4.4, 0, -13.0), lamps))
	flicker.append(Kit.lamp_stand(world, Vector3(4.55, 0, -14.4), lamps))
	# behind the study, through the doorway: the small room the household lives in, with a
	# bed, the hearth, and the woman who copies his pages
	Kit.box(world, Vector3(2.85, 0.02, -21.0), Vector3(5.1, 0.02, 5.2), "stone", false)
	Kit.box(world, Vector3(2.85, 1.6, -23.6), Vector3(5.5, 3.2, 0.4), "plaster")
	Kit.box(world, Vector3(0.3, 1.6, -21.0), Vector3(0.4, 3.2, 5.2), "plaster")
	Kit.box(world, Vector3(5.4, 1.6, -21.0), Vector3(0.4, 3.2, 5.2), "plaster")
	Kit.box(world, Vector3(2.85, 3.35, -21.0), Vector3(5.7, 0.3, 5.6), "roof", false)
	Kit.bed(world, Vector3(3.6, 0, -22.9), 0.0)
	var home := b.has("household")
	flicker.append(Kit.hearth(world, Vector3(1.3, 0, -22.3), home))
	var people: Array = [teacher]
	if home:
		people.append(Kit.scribe(world, Vector3(1.7, 0, -20.6), Kit.face_yaw(Vector3(1.7, 0, -20.6), Vector3(3.9, 0, -18.0))))
		out.append({"kind": "person", "pos": Vector3(2.7, 0, -19.9), "text": "Ask the copyist about her work", "note": "Porphyry's copyist. In 270 AD every book is written out by hand, one copy at a time: she takes his words down on a wax tablet with a stylus (its flat end rubs the wax smooth again), then copies the fair text onto papyrus. One book can take her a month."})
	else:
		Kit.box(world, Vector3(1.7, 0.22, -20.65), Vector3(0.4, 0.45, 0.4), "wood")  # her empty stool
		Kit.box(world, Vector3(1.7, 0.46, -20.6), Vector3(0.3, 0.02, 0.22), "#4a3420", false)  # and her tablet on it
		out.append({"kind": "look", "pos": Vector3(2.7, 0, -19.9), "text": "Look at the empty stool", "note": "An empty stool by a cold hearth. On it lies a wax tablet, the wax gone hard and blank. Whoever sat here copying his pages has been gone a long time."})
	Kit.cylinder(world, Vector3(2.6, 0, -21.4), 0.22, 0.34, "wood", false, 8, 0.26)  # her basket of scrolls
	for k in 3:
		Kit.mesh(world, Kit._cyl(0.05, 0.4), "parchment", Vector3(2.5 + k * 0.1, 0.4, -21.5 + (k % 2) * 0.1), Vector3(0.2 * k, 0, 0.15))
	Kit.amphora(world, Vector3(4.9, 0, -19.0), 0.0)
	# Poly Haven (CC0) pots and baskets alongside the house's own things: a jug and a bowl for
	# the household's meals, a basket by the door (grey and dusty until the household is home)
	for p in [["jug_01", Vector3(4.95, 0, -20.1), 0.35, 0.4], ["wooden_bowl_01", Vector3(2.2, 0, -22.9), 0.28, 0.0],
			["wicker_basket_01", Vector3(0.9, 0, -19.3), 0.45, 1.2]]:
		prop(world, p[0], p[1], p[2], p[3])
	spots["hut"] = Vector3(3.9, 0, -19.4)
	Kit.amphora(world, Vector3(-4.6, 0, -17.6))
	Kit.amphora(world, Vector3(-4.1, 0, -17.7), 0.35)
	Kit.amphora(world, Vector3(-6.4, 0, -1.4))
	Kit.amphora(world, Vector3(6.4, 0, -10.6), -0.3)
	Kit.table(world, Vector3(6.0, 0, -7.6), 0.0)
	Kit.lyre(world, Vector3(4.93, 1.9, -13.2), -PI / 2.0)
	for p in [Vector3(-3.3, 0, -11.6), Vector3(3.3, 0, -11.6), Vector3(2.8, 0, -8.3), Vector3(-6.3, 0, -8.0)]:
		sway.append(Kit.plant(world, p, leaves))
	flicker.append_array(_villa_lessons(world, work, room, out, spots))
	out.append(seat(world, Vector3(-12.0, 0, -1.0), Vector3(-1, 0, 0)))
	spots["study"] = Vector3(0, 0, -11.0)
	var spawn := Vector3(0, 0.05, 23.5)
	return {"name": "%s - %s" % [room.get("where", ""), room.get("when", "")], "interactables": out, "spawn": spawn,
		"yaw": 0.0, "spots": spots, "flicker": flicker, "people": people, "restored": 0,
		"sway": sway, "birds": birds, "back": b}


## Aristotle's Lyceum outside Athens, 335 BC: a path up from the gateway between plane trees
## and the Ilissos stream, the covered walkway where he paces as he teaches (facts on its
## wall, the map of 335 BC, the busts of Plato and Alexander, the book), the closed library and
## the sacred grove for later lessons, and Alexander's men drilling on the meadow. It starts
## lost, grey and dead, and comes back a piece at a time: the stream runs, the trees leaf, the
## walkway stands whole, the morning returns, Aristotle is himself, the soldiers are men again.
static func lyceum(world: Node3D, work: String, room: Dictionary, stage: int = 0, stages: Dictionary = {}) -> Dictionary:
	var b := _sky(world, room, stage, "morning", Vector3(0, 0, -4), 26.0)
	var leaves := b.has("leaves")
	Kit.plateau(world, 112.0, "earth", false)
	Kit.acropolis(world, Vector3(-150, -10, -230))
	Kit.mountain(world, Vector3(280, -10, -160), 130.0, 75.0, false)  # Hymettus
	Kit.mountain(world, Vector3(-40, -10, -330), 40.0, 60.0, false)  # Lycabettus
	var flicker: Array = []
	var out: Array = []
	var spots := {}
	var sway: Array = []
	var birds: Array = Kit.flock(world, Vector3(0, 0, -6), 6, 14.0, 12.0) if leaves else []  # no birds over a dead place
	# arrival: the gateway back to the Shore, and the path north
	var gate_at := Vector3(0, 0, 27)
	flicker.append(Kit.gateway(world, gate_at, Kit.face_yaw(gate_at, Vector3.ZERO), true))
	out.append({"kind": "gate", "pos": Vector3(0, 0, 25.3), "to": "hub", "open": true, "text": "Back to the Shore"})
	Kit.box(world, Vector3(0, 0.01, 2.0), Vector3(3.0, 0.02, 46.0), "path", false)
	# the Ilissos along the east side, with its plane trees
	# the Ilissos, and the channel off its north end that joins the hill (west) and the grove (east)
	_waterway(world, b.has("water"))
	# a rowing boat on the waterway, and a landing at each of the three places: at a landing, choose
	# where to row to. On a dry bed the boat lies stranded on its side.
	var boats: Array = []
	if b.has("water"):
		var boat := Kit.boat(world, LANDINGS["lyceum"]["at"], PI)
		boat["speed"] = 3.0
		boat["junction"] = RIVER_JUNCTION
		boat["landings"] = LANDINGS
		boat["landing"] = "lyceum"
		boat["route"] = []
		boats.append(boat)
		for from in LANDINGS:
			var spots_here: Array = LANDINGS[from]["spots"]
			var k := 0
			for to in LANDINGS:
				if to == from:
					continue
				out.append({"kind": "ferry", "pos": spots_here[k], "boat": boat, "from": from, "to": to,
					"text": "Row to %s" % LANDINGS[to]["name"]})
				k += 1
	else:
		var wreck: Dictionary = Kit.boat(world, LANDINGS["lyceum"]["at"] + Vector3(0, 0.08, 0), PI)
		wreck["root"].rotation.z = 0.35
		out.append({"kind": "look", "pos": Vector3(6.2, 0, -4), "text": "Look at the boat",
			"note": "A boat lies on its side on the dry bed of the Ilissos, its oars shipped. There is no water to carry it."})
	spots["boat"] = Vector3(6.2, 0, -4)
	for z in [24.0, 15.0, 6.0, -3.0, -12.0, -21.0, -30.0]:
		sway.append(Kit.plane_tree(world, Vector3(12.0 + fmod(absf(z), 3.0), 0, z), 1.0 + fmod(absf(z), 5.0) * 0.06, leaves))
	for p in [Vector3(-13, 0, 20), Vector3(-15, 0, 4), Vector3(-14, 0, -10), Vector3(5, 0, 30)]:
		sway.append(Kit.plane_tree(world, p, 1.1, leaves))
	# the walkway: a stoa on the west side, open toward the path, where he paces
	var stoa_at := Vector3(-6.5, 0, -5)
	Kit.stoa(world, stoa_at, PI / 2.0, 34.0, 5.0, b.has("walkway"))
	var facts: Array = room.get("facts", [])
	for k in facts.size():
		var at := Vector3(-8.55, 0, 9.0 - k * 3.6)
		var reader := Vector3(-7.3, 0, at.z)
		Kit.stele(world, at, Kit.face_yaw(at, reader))
		spots["fact%d" % k] = reader
		out.append({"kind": "fact", "pos": reader, "text": facts[k]})
	var statues: Array = room.get("statues", [])
	for k in statues.size():
		var sz := 11.2 if k == 0 else -21.2
		Kit.bust(world, Vector3(-6.5, 0, sz), 0.0 if k == 0 else PI, statues[k])
		var stand := Vector3(-6.5, 0, sz + (-1.6 if k == 0 else 1.6))
		out.append({"kind": "statue", "pos": stand, "text": "Look at the bust of %s" % statues[k]["name"], "note": statues[k]["note"]})
		spots["statue%d" % k] = stand
	if room.has("map"):
		var tex := load("res://assets/maps/%s.png" % room["map"]) as Texture2D
		if tex:
			Kit.board(world, Vector3(-8.75, 2.2, -16.0), PI / 2.0, Vector2(2.9, 2.0), tex)
			out.append({"kind": "map", "pos": Vector3(-7.4, 0, -16.0), "map": room["map"], "text": "Study the map of the world in 335 BC",
				"note": room.get("map_note", "")})
			spots["map"] = Vector3(-7.4, 0, -16.0)
	Kit.box(world, Vector3(-8.2, 0.5, -19.6), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(world, Vector3(-8.2, 1.05, -19.6), Vector3(0.45, 0.06, 0.6), "parchment", false)
	out.append({"kind": "book", "pos": Vector3(-7.0, 0, -19.6), "text": "Read a page of the %s" % room["book"]})
	spots["book"] = Vector3(-7.0, 0, -19.6)
	# Aristotle himself, walking up and down the walkway; talk to him wherever he is
	var aristotle := Kit.walker(world, Vector3(-6.5, 0, 6.0), PI, room.get("portrait", {}))
	aristotle["path"] = [Vector3(-6.5, 0, -18.0), Vector3(-6.5, 0, 8.0)]
	aristotle["speed"] = 1.1
	aristotle["area"] = work
	if not b.has("teacher"):
		_haunt(aristotle, stage)
	var who := _who(room, b)
	out.append({"kind": "author", "pos": Vector3(-6.5, 0, 6.0), "follow": aristotle["root"], "text": "Walk with %s" % who})
	spots["author"] = Vector3(-6.5, 0, 6.0)
	# for later lessons: the library at the north end, and the grove across the stream
	Kit.box(world, Vector3(-2, 2.6, -29.5), Vector3(14.0, 5.2, 7.0), "stone")
	Kit.box(world, Vector3(-2, 5.35, -29.5), Vector3(15.0, 0.3, 8.0), "roof", false)
	Kit.box(world, Vector3(-2, 1.6, -25.85), Vector3(2.0, 3.2, 0.3), "dark", false)
	Kit.box(world, Vector3(-2, 1.5, -25.9), Vector3(1.8, 3.0, 0.16), "wood", false)
	for x in [-6.0, 2.0]:
		Kit.column(world, Vector3(x, 0, -25.4), 4.6)
	out.append({"kind": "look", "pos": Vector3(-2, 0, -24.4), "text": "Look at the library",
		"note": "The library of the Lyceum, the first great library in Greece. The logic is taught on the hill to the west; the ethics in the grove to the east."})
	for p in [Vector3(17, 0, -1), Vector3(20, 0, -8), Vector3(24, 0, -3), Vector3(19, 0, 6), Vector3(27, 0, 3), Vector3(23, 0, -12)]:
		sway.append(Kit.olive(world, p, 1.2, leaves))
	Kit.bust(world, Vector3(15.0, 0, -4), -PI / 2.0, {"beard": "long"})  # a herm of the god of the grove
	out.append({"kind": "look", "pos": Vector3(13.4, 0, -4), "text": "Look at the herm",
		"note": "A herm of Apollo Lyceus, the wolf-god the school is named for. His grove lies east, past the meadow."})
	out.append(seat(world, Vector3(4.8, 0, 8.0), Vector3(1, 0, 0), "Sit by the stream"))
	# on the meadow beyond the grove, Alexander's men drill: a block of pikemen marching a
	# circuit of the road, the sun of Macedon on every shield. Until the place is whole they
	# are the dead, still marching.
	for r in [[Vector3(30, 0.01, 0), Vector3(2.4, 0.02, 46.0)], [Vector3(38, 0.01, 0), Vector3(2.4, 0.02, 46.0)],
			[Vector3(34, 0.01, 22), Vector3(10.4, 0.02, 2.4)], [Vector3(34, 0.01, -22), Vector3(10.4, 0.02, 2.4)]]:
		Kit.box(world, r[0], r[1], "path", false)
	var living := b.has("soldiers")
	var squad := Kit.squad(world, Vector3(30, 0, 18), 4, 4, not living)
	squad["path"] = [Vector3(30, 0, -22), Vector3(38, 0, -22), Vector3(38, 0, 22), Vector3(30, 0, 22)]
	var note := "Macedonian foot soldiers, the men of Philip and now of Alexander. Each carries the sarissa, a pike nearly six metres long, and a small shield with the sixteen-rayed sun of the Argead kings. Since Chaeronea, three years ago, they are the masters of Greece; next spring they cross into Asia."
	if not living:
		note = "What is left of Philip's and Alexander's men, still drilling on the meadow long after the world has forgotten them. Their sarissas are snapped, and the sun of Macedon on their shields has gone green with age."
	out.append({"kind": "person", "pos": Vector3(30, 0, 18), "follow": squad["root"],
		"text": "Watch the Macedonians" if living else "Watch the dead march", "note": note})
	flicker.append_array(_lyceum_lessons(world, work, room, out, spots))
	spots["walk"] = Vector3(-6.5, 0, 2.0)
	spots["march"] = Vector3(22, 0, 12)
	var people: Array = [aristotle]
	var backs := {work: b}
	var areas: Array = []
	for area in [[ORGANON, ORGANON_AT, 30.0], [ETHICS, ETHICS_AT, 28.0]]:
		var aroom := Rooms.room(area[0])
		if aroom.is_empty():
			continue
		var ab := back(aroom, int(stages.get(area[0], 0)))
		backs[area[0]] = ab
		areas.append({"work": area[0], "c": Vector2(area[1].x, area[1].z), "r": area[2], "name": "%s - %s" % [aroom.get("where", ""), aroom.get("when", "")]})
		var built: Dictionary = _organon_hill(world, aroom, ab, stages.get(area[0], 0)) if area[0] == ORGANON \
			else _ethics_grove(world, aroom, ab, stages.get(area[0], 0))
		out.append_array(built["out"])
		people.append(built["teacher"])
		sway.append_array(built["sway"])
		flicker.append_array(built["flicker"])
		birds.append_array(built["birds"])
	# paths from the Lyceum out to the hill and the grove
	Kit.box(world, Vector3(-30, 0.01, -18), Vector3(44.0, 0.02, 2.4), "path", false, Vector3(0, -0.12, 0))
	Kit.box(world, Vector3(58, 0.01, -14), Vector3(34.0, 0.02, 2.4), "path", false, Vector3(0, 0.3, 0))
	var spawn := Vector3(0, 0.05, 23.5)
	return {"name": "%s - %s" % [room.get("where", ""), room.get("when", "")], "interactables": out, "spawn": spawn,
		"yaw": 0.0, "spots": spots, "flicker": flicker, "people": people, "restored": 0,
		"sway": sway, "birds": birds, "squads": [squad], "boats": boats, "back": b, "backs": backs, "areas": areas}


## The waterway (BB1): the Ilissos runs north past the Lyceum to a junction, where a channel runs
## west to the foot of the Organon hill and east to the edge of the Ethics grove. A boat rows between
## the three landings, always by way of the junction.
const RIVER_JUNCTION := Vector3(8, 0.02, -40)
const LANDINGS := {
	"lyceum": {"name": "the Lyceum", "at": Vector3(8, 0.02, -4), "off": Vector3(-2.0, 0, 0),
		"spots": [Vector3(6.0, 0, -2.6), Vector3(6.0, 0, -5.4)]},
	"hill": {"name": "the hill of the Organon", "at": Vector3(-44, 0.02, -40), "off": Vector3(-3.6, 0, 0),
		"spots": [Vector3(-47.6, 0, -38.6), Vector3(-47.6, 0, -41.4)]},
	"grove": {"name": "the grove of the Ethics", "at": Vector3(58, 0.02, -40), "off": Vector3(3.6, 0, 0),
		"spots": [Vector3(61.6, 0, -38.6), Vector3(61.6, 0, -41.4)]},
}


static func _waterway(world: Node3D, flowing: bool) -> void:
	var j := Vector3(RIVER_JUNCTION.x, 0, RIVER_JUNCTION.z)
	const W := 2.4
	Kit.stream(world, Vector3(8, 0, 34), j + Vector3(0, 0, W / 2.0), W, flowing)
	Kit.stream(world, Vector3(-46, 0, j.z), j - Vector3(W / 2.0, 0, 0), W, flowing)
	Kit.stream(world, j + Vector3(W / 2.0, 0, 0), Vector3(60, 0, j.z), W, flowing)
	# the junction itself: open water, with the bank carried across its north side
	Kit.box(world, j + Vector3(0, 0.03, 0), Vector3(W, 0.06, W), "water" if flowing else "drybed", false)
	Kit.box(world, j + Vector3(0, 0.12, -(W / 2.0 + 0.35)), Vector3(W + 1.4, 0.24, 0.7), "rock", false)
	# a mooring post at each landing
	for name in LANDINGS:
		var at: Vector3 = LANDINGS[name]["at"]
		var off: Vector3 = LANDINGS[name]["off"]
		Kit.cylinder(world, Vector3(at.x, 0, at.z) + off * 0.62 + Vector3(0, 0, 0.9), 0.1, 1.1, "wood", false, 6)


const ORGANON := "aristotle-the-rest-of-the-organon"
const ETHICS := "aristotle-nicomachean-ethics"
const ORGANON_AT := Vector3(-72, 0, -26)  # a bare hill west of the Lyceum
const ETHICS_AT := Vector3(76, 0, -24)  # the grove of Apollo, east past the meadow
const HILL_TOP := 5.0


## The lesson point with this id, or {} if the room has none by that name.
static func _lesson(room: Dictionary, id: String) -> Dictionary:
	for p in room.get("lesson", []):
		if p["id"] == id:
			return p
	return {}


## A tall pole with a cloth hanging from it, and a stone beside the way in naming the book, so you
## know where one book ends and the next begins. The stone also carries the area's life facts.
static func _marker(world: Node3D, at: Vector3, facing: Vector3, cloth: String, title: String, note: String,
		work: String, facts: Array) -> Dictionary:
	Kit.cylinder(world, at, 0.08, 6.0, "wood", false, 6)
	Kit.box(world, at + Vector3(0.6, 4.9, 0), Vector3(1.1, 1.8, 0.05), cloth, false)
	var stone := at + facing.normalized() * 1.2
	var reader := Kit.stele(world, stone, Kit.face_yaw(stone, stone + facing))
	for f in facts:
		note += "

" + str(f)
	return {"kind": "look", "pos": reader, "text": title, "note": note, "work": work}


## The hill of the Organon: a bare, clear hill of pale stone, ringed with columns, three figures of
## standing stones on top, where the young Aristotle works out how one thing follows from another.
static func _organon_hill(world: Node3D, room: Dictionary, b: Array, stage: int) -> Dictionary:
	var c := ORGANON_AT
	var top := c + Vector3(0, HILL_TOP, 0)
	var out: Array = []
	var sway: Array = []
	var flicker: Array = []
	Kit.cylinder(world, c, 26.0, HILL_TOP, "stone" if b.has("sun") else "ashbed", false, 16, 12.0)
	var slope := CylinderMesh.new()
	slope.top_radius = 12.0
	slope.bottom_radius = 26.0
	slope.height = HILL_TOP
	Kit.solid(world, slope.create_convex_shape(), c + Vector3(0, HILL_TOP / 2.0, 0))
	Kit.cylinder(world, top + Vector3(0, -0.04, 0), 11.6, 0.08, "paving", false, 16)
	for k in 10:  # the ring of columns: the terraces of the proof
		var a := TAU * k / 10.0
		Kit.column(world, top + Vector3(cos(a), 0, sin(a)) * 10.4, 3.6, not b.has("walkway"))
	for k in 3:  # the three figures, three standing stones each
		var a := TAU * k / 3.0 + 0.5
		var fc := top + Vector3(cos(a), 0, sin(a)) * 5.0
		for j in 3:
			var s := fc + Vector3(cos(a + TAU * j / 3.0), 0, sin(a + TAU * j / 3.0)) * 1.1
			if b.has("soldiers"):
				Kit.box(world, s + Vector3(0, 1.0, 0), Vector3(0.6, 2.0, 0.4), "stone", false)
			else:
				Kit.box(world, s + Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 0.6), "stone", false, Vector3(0, a + j, 0))
		if k == 0:
			out.append({"kind": "look", "pos": fc + Vector3(cos(a), 0, sin(a)) * 1.9, "work": ORGANON, "id": "figures",
				"text": "Look at the three figures", "note": _lesson(room, "figures").get("point", "")})
	for p in [Vector3(-20, 0, -14), Vector3(-24, 0, 4), Vector3(-12, 0, 20), Vector3(10, 0, 22), Vector3(22, 0, -12), Vector3(4, 0, -24)]:
		sway.append(Kit.plane_tree(world, c + p, 0.9, b.has("leaves")))
	Kit.stream(world, c + Vector3(20, 0, 8), c + Vector3(34, 0, 20), 1.6, b.has("water"))
	if b.has("sun"):
		var light := OmniLight3D.new()
		light.position = top + Vector3(0, 6, 0)
		light.light_color = Color("fff0d8")
		light.light_energy = 1.2
		light.omni_range = 24.0
		world.add_child(light)
	else:
		Kit.ash(world, top, 20.0)
	flicker.append_array(_organon_lessons(world, room, top, out))
	Kit.box(world, top + Vector3(2.5, 0.5, 0), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(world, top + Vector3(2.5, 1.05, 0), Vector3(0.45, 0.06, 0.6), "parchment", false)
	out.append({"kind": "book", "pos": top + Vector3(3.8, 0, 0), "text": "Read a page of the %s" % room["book"], "work": ORGANON})
	var young := Kit.walker(world, top + Vector3(0, 0, 3), 0.0, room.get("portrait", {}))
	young["path"] = [top + Vector3(-3.5, 0, 3.5), top + Vector3(3.5, 0, 3.5), top + Vector3(3.5, 0, -3.5), top + Vector3(-3.5, 0, -3.5)]
	young["speed"] = 1.4
	young["area"] = ORGANON
	if not b.has("teacher"):
		_haunt(young, stage)
	out.append({"kind": "author", "pos": top, "follow": young["root"], "text": "Talk with %s" % _who(room, b), "work": ORGANON})
	out.append(_marker(world, c + Vector3(30, 0, 6), Vector3(1, 0, 0.2), "#4a5a7a", "Read the stone: The Organon",
		"THE ORGANON. The tool for thinking: how one thing follows from another. Prior Analytics and Sophistical Refutations. Aristotle is young here.", ORGANON, room.get("facts", [])))
	return {"out": out, "teacher": young, "sway": sway, "flicker": flicker, "birds": []}


## The hill's other five lesson stones (the sixth, "figures", is the ring of three already
## standing by the centre): a small scene around each, spread over the open paving (sprint-03-plan.md).
static func _organon_lessons(world: Node3D, room: Dictionary, top: Vector3, out: Array) -> Array:
	var flicker: Array = []

	# premise: a single stone, carved with the plainest premise there is
	var pa := deg_to_rad(-110.0)
	var pat := top + Vector3(cos(pa), 0, sin(pa)) * 8.0
	var preader: Vector3 = Kit.stele(world, pat, Kit.face_yaw(pat, top))
	out.append({"kind": "look", "pos": preader, "work": ORGANON, "id": "premise",
		"text": "Read the stone: EVERY A IS B", "note": _lesson(room, "premise").get("point", "")})

	# syllogism: three low stones in a row; the first two carry a flame, whose light reaches the third
	var sa := deg_to_rad(-66.0)
	var sc := top + Vector3(cos(sa), 0, sin(sa)) * 8.5
	var srow := Vector3(cos(sa + PI / 2.0), 0, sin(sa + PI / 2.0))
	for j in 3:
		var sp := sc + srow * (j - 1) * 0.95
		Kit.box(world, sp + Vector3(0, 0.45, 0), Vector3(0.55, 0.9, 0.55), "stone")
		if j < 2:
			Kit.blob(world, sp + Vector3(0, 0.98, 0), 0.13, "fire", Vector3(1.0, 1.5, 1.0), 5)
	var slight := OmniLight3D.new()
	slight.position = sc + Vector3(0, 1.1, 0)
	slight.light_color = Color("ff9a48")
	slight.light_energy = 1.1
	slight.omni_range = 4.5
	world.add_child(slight)
	flicker.append(slight)
	out.append({"kind": "look", "pos": sc.lerp(top, 0.28), "work": ORGANON, "id": "syllogism",
		"text": "Look at the three stones", "note": _lesson(room, "syllogism").get("point", "")})

	# middle term: two short posts joined by a lintel, the middle stone that binds them
	var ma := deg_to_rad(-22.0)
	var mc := top + Vector3(cos(ma), 0, sin(ma)) * 8.0
	var mrow := Vector3(cos(ma + PI / 2.0), 0, sin(ma + PI / 2.0))
	for side in [-1.0, 1.0]:
		Kit.box(world, mc + mrow * side * 0.8 + Vector3(0, 0.7, 0), Vector3(0.4, 1.4, 0.4), "stone")
	Kit.box(world, mc + Vector3(0, 1.5, 0), Vector3(2.2, 0.35, 0.4), "stone", false)
	out.append({"kind": "look", "pos": mc.lerp(top, 0.28), "work": ORGANON, "id": "middle",
		"text": "Look at the lintel stone", "note": _lesson(room, "middle").get("point", "")})

	# conversion: one stone slab, read differently from either side
	var ca := deg_to_rad(22.0)
	var cc := top + Vector3(cos(ca), 0, sin(ca)) * 8.0
	Kit.box(world, cc + Vector3(0, 0.9, 0), Vector3(0.5, 1.8, 1.6), "marble", true, Vector3(0, Kit.face_yaw(cc, top), 0))
	out.append({"kind": "look", "pos": cc.lerp(top, 0.3), "work": ORGANON, "id": "conversion",
		"text": "Read the near face", "note": "Facing the hilltop: \"no A is B\" turns round to \"no B is A\"."})
	out.append({"kind": "look", "pos": cc + Vector3(cos(ca), 0, sin(ca)) * 1.6, "work": ORGANON, "id": "conversion",
		"text": "Read the far face", "note": _lesson(room, "conversion").get("point", "")})

	# fallacies: a path that looks sound and forks into a jumble of broken stone
	var fa := deg_to_rad(66.0)
	var fstart := top + Vector3(cos(fa), 0, sin(fa)) * 7.0
	var fend := top + Vector3(cos(fa), 0, sin(fa)) * 11.0
	Kit.box(world, (fstart + fend) / 2.0 + Vector3(0, 0.01, 0), Vector3(1.4, 0.02, fend.distance_to(fstart)), "path", false,
		Vector3(0, Kit.face_yaw(fstart, fend), 0))
	for p in [Vector3(0.3, 0, 0.4), Vector3(-0.5, 0, 0.2), Vector3(0.1, 0, -0.5)]:
		Kit.rock(world, fend + p, 0.45)
	out.append({"kind": "look", "pos": fstart.lerp(top, 0.35), "work": ORGANON, "id": "fallacies",
		"text": "Follow the path", "note": _lesson(room, "fallacies").get("point", "")})

	return flicker


## The grove of Apollo Lyceus: old olives round an altar and a spring, and the old Aristotle
## sitting and walking a little, near the end of his life.
static func _ethics_grove(world: Node3D, room: Dictionary, b: Array, stage: int) -> Dictionary:
	var c := ETHICS_AT
	var out: Array = []
	var sway: Array = []
	var flicker: Array = []
	Kit.cylinder(world, c + Vector3(0, -0.03, 0), 24.0, 0.06, "earth" if b.has("leaves") else "ashbed", false, 16)
	for k in 12:
		var a := TAU * k / 12.0 + 0.2
		sway.append(Kit.olive(world, c + Vector3(cos(a), 0, sin(a)) * (16.0 + fmod(k * 1.7, 4.0)), 1.4, b.has("leaves")))
	if b.has("walkway"):  # the stair of altars: the highest good, three tiers up
		for tier in 3:
			var s := 3.0 - tier * 0.6
			Kit.box(world, c + Vector3(0, 0.5 + tier * 1.0, -6), Vector3(s, 1.0, 1.6 - tier * 0.3), "marble")
		Kit.box(world, c + Vector3(0, 3.55, -6), Vector3(1.5, 0.15, 1.0), "marble", false)
	else:
		Kit.box(world, c + Vector3(0, 0.3, -6), Vector3(2.0, 0.6, 1.4), "marble")
		Kit.box(world, c + Vector3(1.8, 0.2, -5.2), Vector3(1.2, 0.4, 0.8), "marble", false, Vector3(0, 0.6, 0.2))
	out.append({"kind": "look", "pos": c + Vector3(0, 0, -4.2), "work": ETHICS, "id": "highest_good",
		"text": "Look at the altars", "note": _lesson(room, "highest_good").get("point", "")})
	Kit.stream(world, c + Vector3(-12, 0, 6), c + Vector3(-4, 0, 14), 1.4, b.has("water"))
	var birds: Array = Kit.flock(world, c, 5, 10.0, 8.0) if b.has("soldiers") else []
	flicker.append_array(_ethics_lessons(world, room, c, out))
	if b.has("sun"):
		var light := OmniLight3D.new()
		light.position = c + Vector3(0, 7, 0)
		light.light_color = Color("ffc890")
		light.light_energy = 1.3
		light.omni_range = 24.0
		world.add_child(light)
		flicker.append(light)
	else:
		Kit.ash(world, c, 20.0)
	Kit.box(world, c + Vector3(-4, 0.5, -3), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(world, c + Vector3(-4, 1.05, -3), Vector3(0.45, 0.06, 0.6), "parchment", false)
	out.append({"kind": "book", "pos": c + Vector3(-4, 0, -1.7), "text": "Read a page of the %s" % room["book"], "work": ETHICS})
	var old := Kit.walker(world, c + Vector3(2, 0, -2), PI, room.get("portrait", {}))
	old["path"] = [c + Vector3(2, 0, -3), c + Vector3(2, 0, 3)]
	old["speed"] = 0.5
	old["area"] = ETHICS
	if not b.has("teacher"):
		_haunt(old, stage)
	out.append({"kind": "author", "pos": c + Vector3(2, 0, 0), "follow": old["root"], "text": "Sit with %s" % _who(room, b), "work": ETHICS})
	out.append(_marker(world, c + Vector3(-26, 0, 6), Vector3(-1, 0, 0.2), "#5a6a4a", "Read the stone: The Ethics",
		"THE ETHICS. How to live: what happiness is, how virtue is made, the mean. The Nicomachean Ethics. Aristotle is old here.", ETHICS, room.get("facts", [])))
	return {"out": out, "teacher": old, "sway": sway, "flicker": flicker, "birds": birds}


## The grove's other five lesson stones (the sixth, "highest good", is the stair of altars at the
## centre): a small scene around each, spread through the olives clear of the stream, which runs
## northwest (sprint-03-plan.md).
static func _ethics_lessons(world: Node3D, room: Dictionary, c: Vector3, out: Array) -> Array:
	var flicker: Array = []

	# activity: a swallow resting on a branch. "One swallow does not make a spring."
	var fc := c + Vector3(14, 0, -10)
	Kit.cylinder(world, fc, 0.09, 1.4, "deadwood", false, 5)
	Kit.box(world, fc + Vector3(0.35, 1.35, 0), Vector3(0.7, 0.05, 0.05), "deadwood", false)
	Kit.blob(world, fc + Vector3(0.55, 1.42, 0), 0.05, "#2a2630", Vector3(1.2, 0.9, 1.6), 5)
	out.append({"kind": "look", "pos": fc + Vector3(-1.2, 0, 0.6), "work": ETHICS, "id": "function",
		"text": "Look at the swallow", "note": _lesson(room, "function").get("point", "")})

	# habit: a trail of worn, packed earth, worn by walking it again and again, leading to the altars
	var trail := [c + Vector3(-20, 0, -2), c + Vector3(-15, 0, -3), c + Vector3(-10, 0, -4), c + Vector3(-6, 0, -5), c + Vector3(-2, 0, -5.5)]
	for p in trail:
		Kit.cylinder(world, p + Vector3(0, -0.02, 0), 0.55, 0.03, "earth", false, 8)
	out.append({"kind": "look", "pos": trail[1] + Vector3(0, 0, 1.2), "work": ETHICS, "id": "habit",
		"text": "Look at the worn path", "note": _lesson(room, "habit").get("point", "")})

	# the mean: a stone ledge between a rash fire and a cowering, huddled shade
	var mc := c + Vector3(18, 0, 6)
	Kit.box(world, mc + Vector3(0, 0.25, 0), Vector3(4.4, 0.5, 1.3), "stone")
	flicker.append(Kit.brazier(world, mc + Vector3(-1.8, 0.5, 0)))
	Kit.rock(world, mc + Vector3(1.9, 0.5, 0.2), 0.85)
	Kit.rock(world, mc + Vector3(2.3, 0.5, -0.3), 0.55)
	out.append({"kind": "look", "pos": mc + Vector3(0, 0, 1.6), "work": ETHICS, "id": "mean",
		"text": "Stand on the ledge", "note": _lesson(room, "mean").get("point", "")})

	# pleasure as the test: a lyre left mid-song, and the glad player who was just playing it
	var lyre_at := c + Vector3(-16, 0, 9)
	Kit.rock(world, lyre_at, 0.5)
	var player_g := Kit.group(world, lyre_at + Vector3(-0.3, 0, -0.2), deg_to_rad(200))
	Kit.box(player_g, Vector3(0, 0.32, 0), Vector3(0.42, 0.55, 0.36), "#5a6a4a")
	Kit.blob(player_g, Vector3(0, 0.72, 0.02), 0.16, "#c0a080", Vector3(1.0, 1.05, 1.0), 6)
	Kit.lyre(player_g, Vector3(0.26, 0.32, 0.2), deg_to_rad(35))
	out.append({"kind": "look", "pos": lyre_at + Vector3(1.3, 0, -0.4), "work": ETHICS, "id": "pleasure_pain",
		"text": "Listen at the lyre", "note": _lesson(room, "pleasure_pain").get("point", "")})

	# contemplation: a bench at the grove's edge, facing out and away, toward the sunset
	var bench_at := c + Vector3(-20, 0, -7)
	var outward := Vector3(-20, 0, -7).normalized()
	out.append(seat(world, bench_at, outward, "Sit and watch the sun go down"))
	out.append({"kind": "look", "pos": bench_at - outward * 1.9, "work": ETHICS, "id": "contemplation",
		"text": "Think, sitting here", "note": _lesson(room, "contemplation").get("point", "")})

	return flicker


## The Lyceum's six lesson stones (sprint-03-plan.md): the ten kinds as a ring by the way in, and
## the other five in a line behind the walkway, reached round its south end, in lesson order.
static func _lyceum_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary) -> Array:
	var flicker: Array = []

	# the ten kinds: a ring of ten plinths, each with one thing on it that answers one question
	var tc := Vector3(-7.0, 0, 19.5)
	for k in 10:
		var a := TAU * k / 10.0
		var p := tc + Vector3(cos(a), 0, sin(a)) * 2.3
		Kit.box(world, p + Vector3(0, 0.45, 0), Vector3(0.5, 0.9, 0.5), "stone")
		var on := p + Vector3(0, 0.9, 0)
		match k:
			0:  # what it is: a little man
				_figure(world, on, a + PI, "#8a6a4a", 0.25)
			1:  # how much: three measures, stacked
				for j in 3:
					Kit.box(world, on + Vector3(0, 0.05 + j * 0.1, 0), Vector3(0.3 - j * 0.08, 0.1, 0.3 - j * 0.08), "bronze", false)
			2:  # what sort: a white fleece
				Kit.blob(world, on + Vector3(0, 0.1, 0), 0.16, "#f4f0e6", Vector3(1.3, 0.7, 1.0), 6)
			3:  # how it stands to others: a double and a half
				Kit.box(world, on + Vector3(-0.08, 0.15, 0), Vector3(0.14, 0.3, 0.14), "clay", false)
				Kit.box(world, on + Vector3(0.1, 0.075, 0), Vector3(0.14, 0.15, 0.14), "clay", false)
			4:  # where: a little column, the Lyceum
				Kit.cylinder(world, on, 0.05, 0.4, "marble", false, 6)
			5:  # when: a sundial
				Kit.cylinder(world, on, 0.18, 0.04, "marble", false, 10)
				Kit.box(world, on + Vector3(0, 0.12, 0), Vector3(0.02, 0.2, 0.12), "bronze", false, Vector3(0.5, 0, 0))
			6:  # what position: a little man lying down
				Kit.box(world, on + Vector3(0, 0.05, 0), Vector3(0.34, 0.1, 0.12), "#8a6a4a", false, Vector3(0, a, 0))
			7:  # what it has: a pair of sandals
				for side in [-0.06, 0.06]:
					Kit.box(world, on + Vector3(side, 0.02, 0), Vector3(0.08, 0.04, 0.22), "#6a4a2a", false)
			8:  # what it does: a hammer, mid-blow
				Kit.box(world, on + Vector3(0, 0.12, 0), Vector3(0.03, 0.24, 0.03), "wood", false, Vector3(0, 0, 0.6))
				Kit.box(world, on + Vector3(0.07, 0.22, 0), Vector3(0.14, 0.06, 0.06), "bronze", false, Vector3(0, 0, 0.6))
			9:  # what is done to it: a log, split
				for side in [-1.0, 1.0]:
					Kit.box(world, on + Vector3(side * 0.06, 0.08, 0), Vector3(0.08, 0.16, 0.28), "wood", false, Vector3(0, 0, side * 0.3))
	out.append({"kind": "look", "pos": tc + Vector3(3.5, 0, 0), "work": work, "id": "ten_questions",
		"text": "Look at the ten plinths", "note": _lesson(room, "ten_questions").get("point", "")})
	spots["kinds"] = tc + Vector3(3.5, 0, 0)

	# homonyms: a real horse, and a painted one on the back wall of the walkway
	var hc := Vector3(-11.8, 0, 9.5)
	_horse(world, Vector3(-13.6, 0, 9.5), PI / 2.0, "#6a4a30")  # looking at its picture
	Kit.board(world, Vector3(-9.26, 1.9, 9.5), -PI / 2.0, Vector2(1.8, 1.2), painted_horse())
	out.append({"kind": "look", "pos": hc, "work": work, "id": "homonyms",
		"text": "Look at the two horses", "note": _lesson(room, "homonyms").get("point", "")})
	spots["homonyms"] = hc

	# said of, present in: a statue of Socrates on a plinth, with a white sash across him
	var sc := Vector3(-17.5, 0, 1.0)
	Kit.box(world, sc + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.9), "stone")
	_figure(world, sc + Vector3(0, 0.6, 0), PI / 2.0, "marble")
	Kit.box(world, sc + Vector3(0.17, 1.55, 0), Vector3(0.04, 0.9, 0.12), "#f4f0e6", false, Vector3(0.7, 0, 0))
	out.append({"kind": "look", "pos": sc + Vector3(1.9, 0, 0), "work": work, "id": "said_of_in",
		"text": "Look at the statue of Socrates", "note": _lesson(room, "said_of_in").get("point", "")})

	# primary substance: one man, one horse, just standing there
	var pc := Vector3(-18.0, 0, -4.5)
	_figure(world, pc + Vector3(0.8, 0, 0.4), PI / 2.0, "#7a6a50")
	_horse(world, pc + Vector3(-1.0, 0, 0), 0.0, "#5a4a3a")
	out.append({"kind": "look", "pos": pc + Vector3(2.6, 0, 0), "work": work, "id": "substance",
		"text": "Look at the man and the horse", "note": _lesson(room, "substance").get("point", "")})

	# secondary substance: the same pair under a lintel, MAN carved over him and ANIMAL across both
	var lc := Vector3(-18.0, 0, -11.0)
	for x in [-2.1, 2.1]:
		Kit.box(world, lc + Vector3(x, 1.4, 0), Vector3(0.45, 2.8, 0.45), "stone")
	Kit.box(world, lc + Vector3(0, 2.95, 0), Vector3(4.8, 0.35, 0.5), "stone", false)
	Kit.box(world, lc + Vector3(0, 2.95, 0.26), Vector3(2.4, 0.2, 0.02), "plaque", false)  # ANIMAL
	Kit.box(world, lc + Vector3(0.9, 2.45, 0.02), Vector3(0.8, 0.18, 0.03), "plaque", false)  # MAN
	_figure(world, lc + Vector3(0.9, 0, 0), 0.0, "#7a6a50")
	_horse(world, lc + Vector3(-1.2, 0, -0.3), 0.0, "#5a4a3a")
	out.append({"kind": "look", "pos": lc + Vector3(0, 0, 2.2), "work": work, "id": "secondary",
		"text": "Read the lintel: MAN, ANIMAL", "note": _lesson(room, "secondary").get("point", "")})

	# the marks of substance: one man between a cold brazier and a lit one, the same man either way
	var mc := Vector3(-12.5, 0, -12.8)
	flicker.append(Kit.brazier(world, mc + Vector3(-1.6, 0, 0)))
	Kit.cylinder(world, mc + Vector3(1.6, 0, 0), 0.5, 0.9, "stone", true, 8)
	Kit.cylinder(world, mc + Vector3(1.6, 0.9, 0), 0.4, 0.25, "bronze", false, 8, 0.65)
	Kit.blob(world, mc + Vector3(1.6, 1.05, 0), 0.2, "ash", Vector3(1.4, 0.4, 1.4), 5)
	_figure(world, mc, 0.0, "#7a6a50")
	out.append({"kind": "look", "pos": mc + Vector3(0, 0, 1.7), "work": work, "id": "marks",
		"text": "Look at the man between the fires", "note": _lesson(room, "marks").get("point", "")})
	return flicker


## The villa's six lesson stones (sprint-03-plan.md): small scenes spread round the grounds in lesson
## order, crossing from side to side: two by the way in, two out on the lawns level with the house,
## and two among the olives behind it.
static func _villa_lessons(world: Node3D, work: String, room: Dictionary, out: Array, spots: Dictionary) -> Array:
	var flicker: Array = []

	# why he wrote it: a letter to his student Chrysaorius, left on a table in the garden
	var wc := Vector3(10.0, 0, 20.0)
	Kit.box(world, wc + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.6), "wood")  # a writing stand
	Kit.box(world, wc + Vector3(0.1, 0.81, 0), Vector3(0.36, 0.01, 0.46), "parchment", false, Vector3(0, 0.2, 0))
	Kit.box(world, wc + Vector3(-0.28, 0.82, 0.1), Vector3(0.02, 0.02, 0.24), "bronze", false, Vector3(0, -0.4, 0))
	out.append({"kind": "look", "pos": wc + Vector3(-1.6, 0, 0.6), "work": work, "id": "why",
		"text": "Read the letter to Chrysaorius", "note": _lesson(room, "why").get("point", "")})
	spots["letter"] = wc + Vector3(-1.6, 0, 0.6)

	# family and kind: one pen, and in it a man, a goat and a dog: three kinds, one family
	var gc := Vector3(-14.0, 0, 16.0)
	for side in [-1.0, 1.0]:
		Kit.box(world, gc + Vector3(side * 1.6, 0.35, 0), Vector3(0.08, 0.08, 3.2), "wood", false)
		Kit.box(world, gc + Vector3(0, 0.35, side * 1.6), Vector3(3.2, 0.08, 0.08), "wood", false)
		for end in [-1.0, 1.0]:
			Kit.box(world, gc + Vector3(side * 1.6, 0.3, end * 1.6), Vector3(0.12, 0.6, 0.12), "wood", false)
	_figure(world, gc + Vector3(0.6, 0, -0.5), PI / 2.0, "#6a5a7a")
	_horse(world, gc + Vector3(-0.5, 0, 0.5), 0.4, "#d8d0c0", 0.5)  # the goat
	_horse(world, gc + Vector3(0.4, 0, 0.9), -1.2, "#4a3a2a", 0.38)  # the dog
	out.append({"kind": "look", "pos": gc + Vector3(2.3, 0, 0), "work": work, "id": "genus_species",
		"text": "Look into the pen", "note": _lesson(room, "genus_species").get("point", "")})

	# what splits them: a goat grazing, and beside it a man reading
	var dc := Vector3(17.0, 0, 5.0)
	_horse(world, dc + Vector3(0.6, 0, 0.4), PI * 0.8, "#d8d0c0", 0.5)
	_figure(world, dc + Vector3(-0.4, 0, -0.3), -PI / 2.0, "#6a5a7a")
	Kit.mesh(world, Kit._cyl(0.04, 0.34), "parchment", dc + Vector3(-0.72, 1.05, -0.3), Vector3(PI / 2.0, 0, 0))
	out.append({"kind": "look", "pos": dc + Vector3(-1.9, 0, 0), "work": work, "id": "difference",
		"text": "Look at the goat and the reader", "note": _lesson(room, "difference").get("point", "")})

	# always and sometimes: a laughing mask on a post (only humans laugh), and a stool nobody sits on
	var pc := Vector3(-18.0, 0, 4.0)
	Kit.box(world, pc + Vector3(0, 0.8, -0.3), Vector3(0.12, 1.6, 0.12), "wood")
	Kit.blob(world, pc + Vector3(0.08, 1.55, -0.3), 0.2, "#e8dcc4", Vector3(0.5, 1.2, 1.0), 6)  # facing the way in
	Kit.box(world, pc + Vector3(0.19, 1.45, -0.3), Vector3(0.02, 0.05, 0.18), "dark", false)  # the grin
	Kit.box(world, pc + Vector3(0.8, 0.22, 0.4), Vector3(0.4, 0.45, 0.4), "wood")
	out.append({"kind": "look", "pos": pc + Vector3(1.9, 0, 0.2), "work": work, "id": "property_accident",
		"text": "Look at the mask and the stool", "note": _lesson(room, "property_accident").get("point", "")})

	# saying what a thing is: his tree in stone, a trunk of kinds with a branch at each level
	var tc := Vector3(15.5, 0, -13.0)
	Kit.box(world, tc + Vector3(0, 0.1, 0), Vector3(1.0, 0.2, 1.0), "stone")
	Kit.box(world, tc + Vector3(0, 1.5, 0), Vector3(0.3, 2.8, 0.3), "marble")
	for level in 4:
		var side := 1.0 if level % 2 == 0 else -1.0
		Kit.box(world, tc + Vector3(0, 0.6 + level * 0.65, side * 0.4), Vector3(0.18, 0.14, 0.55), "marble", false)
	Kit.blob(world, tc + Vector3(0, 3.0, 0), 0.2, "marble", Vector3(1.0, 0.8, 1.0), 6)
	out.append({"kind": "look", "pos": tc + Vector3(-1.7, 0, 0.3), "work": work, "id": "definition",
		"text": "Look at the stone tree", "note": _lesson(room, "definition").get("point", "")})

	# the open question: a plinth carved ANIMAL, with nothing standing on it
	var uc := Vector3(-14.5, 0, -14.0)
	Kit.box(world, uc + Vector3(0, 0.55, 0), Vector3(0.8, 1.1, 0.8), "marble")
	Kit.box(world, uc + Vector3(0.41, 0.7, 0), Vector3(0.02, 0.18, 0.5), "plaque", false)
	out.append({"kind": "look", "pos": uc + Vector3(1.7, 0, 0), "work": work, "id": "universals",
		"text": "Look at the empty plinth", "note": _lesson(room, "universals").get("point", "")})
	return flicker


## A plain standing figure in a robe (a man, or a statue of one in marble), facing yaw. At scale 1
## he is a grown man; small ones stand on plinths.
static func _figure(world: Node3D, at: Vector3, yaw: float, robe: String, scale: float = 1.0) -> Node3D:
	var g := Kit.group(world, at, yaw)
	var skin := "marble" if robe == "marble" else "#c0a080"
	Kit.box(g, Vector3(0, 0.62, 0) * scale, Vector3(0.46, 1.24, 0.3) * scale, robe, scale >= 1.0)
	Kit.box(g, Vector3(0, 1.3, 0) * scale, Vector3(0.52, 0.14, 0.3) * scale, robe, false)  # shoulders
	Kit.blob(g, Vector3(0, 1.52, 0.02) * scale, 0.14 * scale, skin, Vector3(1.0, 1.15, 1.0), 6)
	return g


## A horse standing, facing yaw (or, smaller, a goat or a dog).
static func _horse(world: Node3D, at: Vector3, yaw: float, coat: String, size: float = 1.0) -> Node3D:
	var g := Kit.group(world, at, yaw)
	g.scale = Vector3.ONE * size  # a small one does for a goat or a dog
	Kit.box(g, Vector3(0, 1.05, 0), Vector3(0.45, 0.5, 1.4), coat)
	for p in [Vector3(-0.15, 0, 0.55), Vector3(0.15, 0, 0.55), Vector3(-0.15, 0, -0.55), Vector3(0.15, 0, -0.55)]:
		Kit.cylinder(g, p, 0.06, 0.85, coat, false, 5)
	Kit.box(g, Vector3(0, 1.45, 0.75), Vector3(0.24, 0.62, 0.3), coat, false, Vector3(0.55, 0, 0))  # neck
	Kit.box(g, Vector3(0, 1.72, 1.02), Vector3(0.2, 0.2, 0.46), coat, false, Vector3(0.25, 0, 0))  # head
	Kit.box(g, Vector3(0, 1.5, 0.64), Vector3(0.05, 0.5, 0.2), "#2a2018", false, Vector3(0.55, 0, 0))  # mane
	Kit.box(g, Vector3(0, 0.95, -0.78), Vector3(0.06, 0.55, 0.08), "#2a2018", false, Vector3(-0.35, 0, 0))  # tail
	return g


## A horse painted on plaster in red-brown, the way the vase painters do it.
static func painted_horse() -> ImageTexture:
	var img := Image.create(48, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("e2d4b8"))
	var paint := Color("8a3a22")
	img.fill_rect(Rect2i(12, 12, 20, 7), paint)  # body
	for x in [13, 16, 27, 30]:
		img.fill_rect(Rect2i(x, 19, 2, 9), paint)  # legs
	img.fill_rect(Rect2i(30, 7, 4, 7), paint)  # neck
	img.fill_rect(Rect2i(32, 5, 8, 4), paint)  # head
	img.fill_rect(Rect2i(9, 12, 3, 8), paint)  # tail
	img.fill_rect(Rect2i(4, 29, 40, 1), paint)  # the ground line
	return ImageTexture.create_from_image(img)

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
