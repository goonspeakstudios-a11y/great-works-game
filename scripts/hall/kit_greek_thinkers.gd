extends RefCounted
## Ready-made areas for the philosophers' places: the Pre-Socratics (Heraclitus's Ephesus,
## Parmenides' road to the goddess), Plato (the court, Cephalus's house, Gyges' chasm, the sun and
## the divided line, the cave, Er's meadow, Agathon's dinner, the prison) and Aristotle's extras
## (the household to the city, the theatre of the Poetics), and the Republic's mini-game board, the
## city in speech. Same contract as kit_greek_areas.gd, whose helpers they share: each is built as
## far as its place is restored (`back`, Places.back()), faces +Z, and returns {"root", "spots":
## {"teacher", "book", "seat", "facts", "stones"}, "people", "flicker", "sway", "birds", "squads"},
## with the spots in the parent's space.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")
const Areas := preload("res://scripts/hall/kit_greek_areas.gd")


## A plain house of the city, `size` across: whitewashed walls, a tiled roof, a dark door on +Z.
## Lost: roofless and grey. Returns its node.
static func _house(g: Node3D, at: Vector3, yaw: float, size: float, whole: bool) -> Node3D:
	var h := Kit.group(g, at, yaw)
	Kit.box(h, Vector3(0, size * 0.35, 0), Vector3(size, size * 0.7, size * 0.8), "plaster" if whole else "ashbed")
	Kit.box(h, Vector3(0, size * 0.25, size * 0.41), Vector3(size * 0.22, size * 0.5, 0.04), "dark", false)
	if whole:
		Kit.box(h, Vector3(0, size * 0.75, 0), Vector3(size * 1.1, size * 0.12, size * 0.9), "roof", false)
	return h


## A tent of the camp: a ridge of canvas on the ground, its ends open. Faces +Z.
static func _tent(g: Node3D, at: Vector3, yaw: float, whole: bool) -> Node3D:
	var t := Kit.group(g, at, yaw)
	var r := 2.4 / sqrt(3.0)
	var squash := 1.8 / (1.5 * r)
	Kit.mesh(t, Greek._prism(r, 3.0, 3), "#d8d0b8" if whole else "#6a6866", Vector3(0, 0.5 * r * squash, 0), Vector3(-PI / 2.0, 0, 0),
		Vector3(1.0, 1.0, squash))
	return t


## A still, glowing stuff for the soul's three parts.
static func _glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


# ---------- e4: the Pre-Socratics ----------

## Ephesus, about 500 BC (Heraclitus): the river Cayster running past with stepping stones across it
## ("into the same rivers we step and do not step", B49a), the ever-living fire on the bank, a
## corner of the Artemision, and before the temple the boys at knucklebones Heraclitus preferred to
## the city's politics ("a lifetime is a child playing, moving pieces", B52). Behind, a stair climbs
## the hill: "the way up and the way down is one and the same" (B60). Returns, besides the usual,
## "river": its two ends, and "stepping": the stepping stones in order across.
static func ephesus(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(64.0, 0.04, 56.0), "grass" if back.has("leaves") else "ashbed", false)
	var from := Vector3(-32.0, 0, 5.0)
	var to := Vector3(32.0, 0, 3.0)
	Kit.stream(g, from, to, 5.0, back.has("water"))
	area["river"] = [Areas._at(g, from), Areas._at(g, to)]
	var stepping: Array = []
	for k in 5:
		var p := Vector3(0.4 * (k % 2), 0, 1.8 + k * 1.2)
		Kit.cylinder(g, p, 0.45, 0.22, "stone", true, 7)
		stepping.append(Areas._at(g, p))
	area["stepping"] = stepping
	Kit.box(g, Vector3(-2.0, 0.6, -17.0), Vector3(40.0, 1.2, 12.0), "marble")  # the temple's platform
	for k in 7:
		Props.artemision_column(g, Vector3(-20.0 + k * 6.0, 1.2, -12.0), 0.0, 14.0, whole or k % 3 == 0)
	for k in 4:
		Props.artemision_column(g, Vector3(-20.0 + k * 6.0, 1.2, -19.0), 0.0, 14.0, whole or k % 2 == 0)
	var fire := Props.ever_fire(g, Vector3(9.0, 0, 11.0), back.has("lamps"))
	if fire:
		area["flicker"].append(fire)
	for k in 4:  # the boys at knucklebones on the temple steps
		var p := Vector3(-6.5 + (k % 2) * 1.3, 0, -3.8 + (k / 2) * 1.3)
		Areas._person(area, g, p, Vector3(-5.85, 0, -3.15), "child", back)
	for k in 5:
		Kit.blob(g, Vector3(-5.85 + (k - 2) * 0.08, 0.04, -3.15 + (k % 2) * 0.1), 0.03, "bone")
	for k in 10:  # the way up and the way down
		Kit.box(g, Vector3(24.0, 0.2 + k * 0.4, -6.0 - k * 1.0), Vector3(3.0, 0.4 + k * 0.8, 1.0), "stone")
	area["sway"].append(Kit.plane_tree(g, Vector3(-16.0, 0, 14.0), 1.1, back.has("leaves")))
	area["sway"].append(Kit.cypress(g, Vector3(18.0, 0, 16.0), 8.0, back.has("leaves")))
	return Areas._spots(area, g, back, Vector3(-3.5, 0, -2.5), Vector3(0, 0, 15.0), 5.5,
		[Vector3(14.0, 0, 18.0), Vector3(17.0, 0, 18.0)], Vector3(-18.0, 0, 20.0), PI / 2.0, Vector3(-12.0, 0, 22.0), PI)


## Parmenides' poem (B1-B8) on the hill above Elea: the road along which the mares carry him in the
## chariot, the Heliades leading with their veils thrown back; the gates of Night and Day, Justice
## beside them with the keys; beyond, the goddess who takes his hand, and the way of truth running
## straight to the still sphere, while the way of mortals' opinion turns off and wanders into mist,
## where men "two-headed, knowing nothing" drift about (B6). The town and the sea below. Returns,
## besides the usual, "gates" (Props.great_gates), "truth" and "opinion": each way's points in order.
static func elea(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(64.0, 0.04, 80.0), "grass" if back.has("leaves") else "ashbed", false)
	Kit.box(g, Vector3(0, 0.03, 18.0), Vector3(5.0, 0.04, 34.0), "path", false)  # the road of the goddess
	Props.chariot(g, Vector3(0, 0, 16.0), PI, 2, whole)
	Areas._person(area, g, Vector3(0, 0.35, 17.4), Vector3(0, 0.35, 10.0), "parmenides", back, "teacher")  # standing in the car
	for k in 3:  # the daughters of the Sun, leading
		Areas._person(area, g, Vector3(-1.5 + k * 1.5, 0, 9.0 - (k % 2) * 0.8), Vector3(0, 0, 0), "heliad", back)
	area["gates"] = Props.great_gates(g, Vector3.ZERO, 0.0, back.has("sun"), whole)
	Areas._person(area, g, Vector3(6.2, 0, 2.5), Vector3(0, 0, 8.0), "dike", back)
	Areas._person(area, g, Vector3(0, 0, -9.0), Vector3(0, 0, 0), "goddess", back, "teacher")
	var truth: Array = []
	for k in 8:  # the way of truth, straight
		var p := Vector3(0, 0, -3.0 - k * 3.5)
		Kit.box(g, p + Vector3(0, 0.03, 0), Vector3(3.0, 0.04, 3.6), "marble" if whole else "stone", false)
		truth.append(Areas._at(g, p))
	area["truth"] = truth
	Props.sphere(g, Vector3(0, 0, -34.0), 3.0, whole)
	var opinion: Array = []
	for k in 10:  # the way of opinion, turning off and wandering
		var p := Vector3(3.0 + k * 2.4, 0, -14.0 - k * 1.3 + sin(k * 1.3) * 3.0)
		Kit.box(g, p + Vector3(0, 0.025, 0), Vector3(2.4, 0.04, 2.4), "path", false, Vector3(0, k * 0.7, 0))
		opinion.append(Areas._at(g, p))
	area["opinion"] = opinion
	Props.ground_fog(g, Vector3(18.0, 0, -22.0), 16.0)
	for k in 5:  # mortals wandering, turned this way and that
		var p := Vector3(12.0 + k * 3.2, 0, -18.0 - (k % 3) * 3.0)
		Areas._folk(area, g, p, p + Vector3(sin(k * 2.1), 0, cos(k * 2.1)), {"robe": ["6a5a4a", "8a6a4a", "4a4a5a"][k % 3]}, back)
	Rome.far_city(g, Vector3(0, 0, 80.0), 14.0, 28.0, 18, 540)  # Elea, far off by the sea
	return Areas._spots(area, g, back, Vector3(-2.5, 0, -7.0), Vector3(-16.0, 0, -8.0), 5.5,
		[Vector3(-9.0, 0, 8.0), Vector3(-9.0, 0, 11.0)], Vector3(-20.0, 0, 6.0), PI / 2.0, Vector3(-18.0, 0, 12.0), PI)



# ---------- e4: Plato ----------

## The court where Socrates was tried, 399 BC (the Apology): a walled enclosure with the jurors on
## rows of wooden benches (a few of the 501 here), the speaker's platform before them, the water
## clock that timed each side, the voting urns, the kleroterion at the entrance where the jurors
## were allotted that morning, and the crowd outside the wooden barrier. Meletus accuses; Socrates
## answers. Returns, besides the usual, "urns" (where the votes are cast) and "platform".
static func court(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 4.0), Vector3(40.0, 0.04, 40.0), "paving" if whole else "ashbed", false)
	for side: float in [-1.0, 1.0]:  # the enclosure's low walls
		Kit.box(g, Vector3(side * 15.0, 1.0, 0), Vector3(0.6, 2.0, 22.0), "stone")
	Kit.box(g, Vector3(0, 1.0, -11.0), Vector3(30.6, 2.0, 0.6), "stone")
	for x: float in [-10.0, 10.0]:  # the barrier across the front, open in the middle
		Kit.box(g, Vector3(x, 0.55, 11.0), Vector3(10.0, 1.1, 0.15), "wood" if whole else "deadwood")
	area["platform"] = Areas._at(g, Greek.bema(g, Vector3(0, 0, -7.0), 0.0, whole))
	Areas._person(area, g, Vector3(1.8, 0, -6.0), Vector3(0, 0, 4.0), "socrates", back, "teacher")
	Areas._person(area, g, Vector3(-4.0, 0, -6.5), Vector3(0, 0, 4.0), "meletus", back)
	Greek.clepsydra(g, Vector3(4.5, 0, -7.0), back.has("water"))
	area["urns"] = Areas._at(g, Props.voting_urns(g, Vector3(8.0, 0, -8.0), 0.0, whole))
	for row in 4:  # the jurors' benches, facing the platform
		for col in 4:
			var p := Vector3(-9.0 + col * 6.0, 0, -1.0 + row * 2.6)
			Kit.bench(g, p, PI)
			if (row + col) % 2 == 0:
				Areas._person(area, g, p + Vector3(-0.6, 0, 0.1), p + Vector3(-0.6, 0, -4.0), "juror", back, "household", "sit")
				Areas._person(area, g, p + Vector3(0.6, 0, 0.1), p + Vector3(0.6, 0, -4.0), "juror", back, "household", "sit",
					["a89c84", "8a7a64", "c8b89a"][(row + col) % 3])
	Props.kleroterion(g, Vector3(-12.0, 0, 13.0), 0.0, whole)
	for k in 8:  # the crowd outside the barrier
		var p := Vector3(-12.0 + k * 3.4, 0, 13.5 + (k % 2) * 1.2)
		Areas._folk(area, g, p, Vector3(0, 0, -5.0), {"robe": ["e8e2d2", "8a6a4a", "6a5a4a", "c8b89a"][k % 4], "beard": "short"}, back)
	return Areas._spots(area, g, back, Vector3(0, 0, 9.0), Vector3(0, 0, 19.0), 4.5,
		[Vector3(-17.0, 0, 16.0), Vector3(-17.0, 0, 19.0)], Vector3(17.0, 0, 17.0), -PI / 2.0, Vector3(12.0, 0, 21.0), PI)


## Cephalus's house in the Piraeus, the evening of Bendis's first festival (Republic I.327-354): a
## courtyard with the altar where the old man has just sacrificed, and Cephalus himself, garlanded,
## on a cushioned chair; round him on benches the company: Polemarchus, Glaucon and Adeimantus, and
## Thrasymachus gathered "like a wild beast" to spring. Beyond the wall the harbour and its ships,
## and on the road outside the torch race on horseback promised for that night. Returns, besides the
## usual, "torches": the riders' lights, and "door": the house door Socrates is brought in by.
static func cephalus_house(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(46.0, 0.04, 44.0), "earth" if back.has("leaves") else "ashbed", false)
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(18.0, 0.04, 16.0), "mosaic" if whole else "paving", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 9.0, 2.0, 0), Vector3(0.5, 4.0, 16.0), "plaster")
		Kit.box(g, Vector3(side * 5.2, 2.0, 8.0), Vector3(7.6, 4.0, 0.5), "plaster")  # the front, the door between
	Kit.box(g, Vector3(0, 2.0, -8.0), Vector3(18.5, 4.0, 0.5), "plaster")
	area["door"] = Areas._at(g, Vector3(0, 0, 9.0))
	var altar := Greek.altar(g, Vector3(0, 0, -5.0), 0.0, "greek", back.has("lamps"), whole)
	if altar:
		area["flicker"].append(altar)
	Kit.box(g, Vector3(-3.5, 0.25, -3.5), Vector3(0.8, 0.5, 0.8), "wood" if whole else "deadwood")  # his chair
	Kit.box(g, Vector3(-3.5, 0.55, -3.5), Vector3(0.75, 0.1, 0.75), "#6a2e34" if whole else "#4a4648", false)  # its cushion
	Areas._person(area, g, Vector3(-3.5, 0.1, -3.5), Vector3(0, 0, 1.0), "cephalus", back, "household", "sit")
	var company := [["polemarchus", Vector3(3.5, 0, -3.0)], ["thrasymachus", Vector3(4.5, 0, 1.0)],
		["glaucon", Vector3(-4.5, 0, 2.0)], ["adeimantus", Vector3(-2.5, 0, 4.0)]]
	for c: Array in company:
		var p: Vector3 = c[1]
		Kit.bench(g, p + (p - Vector3(0, 0, 1.0)).normalized() * 0.6, Kit.face_yaw(p, Vector3(0, 0, 1.0)))
		Areas._person(area, g, p, Vector3(0, 0, 1.0), str(c[0]), back, "household", "" if c[0] == "thrasymachus" else "sit")
	Kit.box(g, Vector3(0, -0.3, -40.0), Vector3(90.0, 0.5, 40.0), "sea", false)  # the harbour
	for k in 3:
		Greek.ship(g, Vector3(-24.0 + k * 22.0, -1.0, -34.0), PI / 2.0, "trireme", false, true, whole)
	var torches: Array = []
	for k in 3:  # the torch race along the road, passing the torch from rider to rider
		var p := Vector3(-14.0 + k * 11.0, 0, 20.0)
		Greek.beast(g, p, PI / 2.0, "horse", "", 1.0, back.has("household"))
		Areas._folk(area, g, p + Vector3(0, 1.0, 0), p + Vector3(5.0, 1.0, 0), {"robe": "e8e2d2"}, back)
		if back.has("lamps"):
			Kit.blob(g, p + Vector3(0.4, 3.0, 0.3), 0.18, "fire", Vector3(1.0, 1.6, 1.0), 5)
			var l := OmniLight3D.new()
			l.position = p + Vector3(0.4, 3.2, 0.3)
			l.light_color = Color("ff9a48")
			l.light_energy = 1.4
			l.omni_range = 9.0
			g.add_child(l)
			torches.append(l)
			area["flicker"].append(l)
	area["torches"] = torches
	Kit.box(g, Vector3(0, 0.03, 20.0), Vector3(46.0, 0.04, 4.0), "path", false)
	area["sway"].append(Kit.olive(g, Vector3(-6.0, 0, -2.0), 0.8, back.has("leaves")))
	return Areas._spots(area, g, back, Vector3(1.5, 0, 2.0), Vector3(0, 0, 14.0), 4.2,
		[Vector3(-14.0, 0, 12.0), Vector3(-17.0, 0, 12.0)], Vector3(15.0, 0, 11.0), -PI / 2.0, Vector3(12.0, 0, 15.0), PI)


## The ring of Gyges (Republic II.359c-360d): hill pasture in Lydia after a storm and an earthquake
## have split the ground; down in the chasm the hollow bronze horse with the ring inside; the flock
## grazing above; at the edge of the pasture the shepherds at their monthly meeting where Gyges,
## turning the bezel inward, vanished from their talk; and on its hill beyond, the king's palace.
## The pasture is a hill `TOP` metres high with the chasm cut down through it to the ground, and a
## track climbs to it from the front (+Z), so the chasm shows on any floor. Returns, besides the
## usual, "ring" (the ring's node), "chasm": the top and the foot of the way down, and "horse_door".
static func gyges(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	const TOP := 6.0
	var turf := "grass" if back.has("leaves") else "ashbed"
	# the hill round a chasm from x -5 to 5 and z -14 to 4
	var blocks := [[Vector3(-17.5, 0, 0), Vector3(25.0, 0, 56.0)], [Vector3(17.5, 0, 0), Vector3(25.0, 0, 56.0)],
		[Vector3(0, 0, -21.0), Vector3(10.0, 0, 14.0)], [Vector3(0, 0, 16.0), Vector3(10.0, 0, 24.0)]]
	for b: Array in blocks:
		var c: Vector3 = b[0]
		var size: Vector3 = b[1]
		Kit.box(g, c + Vector3(0, TOP / 2.0, 0), Vector3(size.x, TOP, size.z), "rock")
		Kit.box(g, c + Vector3(0, TOP + 0.02, 0), Vector3(size.x, 0.04, size.z), turf, false)
	Kit.box(g, Vector3(0, 0.02, -5.0), Vector3(10.0, 0.04, 18.0), "cave", false)  # the chasm's floor
	Kit.box(g, Vector3(0, TOP / 2.0, 36.0), Vector3(4.0, 0.4, 17.2), "path", true, Vector3(atan2(TOP, 16.0), 0, 0))  # the track up
	Kit.box(g, Vector3(0, TOP / 2.0, 1.15), Vector3(3.0, 0.4, 8.8), "rock", true, Vector3(-0.76, 0, 0))  # the way down
	area["chasm"] = [Areas._at(g, Vector3(0, TOP, 5.0)), Areas._at(g, Vector3(0, 0, -2.5))]
	var horse := Props.bronze_horse(g, Vector3(-1.5, 0, -8.0), 0.0, whole)
	area["ring"] = horse["ring"]
	area["horse_door"] = Areas._at(g, horse["door"])
	for k in 7:  # the flock
		var p := Vector3(14.0 + (k % 4) * 2.2, TOP, -12.0 + (k / 4) * 2.5)
		Greek.beast(g, p, k * 0.9, "sheep", "", 1.0, back.has("leaves"))
	area["sway"].append(Kit.plane_tree(g, Vector3(-18.0, TOP, 8.0), 1.0, back.has("leaves")))
	area["sway"].append(Kit.olive(g, Vector3(18.0, TOP, 16.0), 1.0, back.has("leaves")))
	var meeting := Vector3(-16.0, TOP, 12.0)
	var ring_of := _circle(meeting, 2.2, 5)
	for k in ring_of.size():  # the shepherds' meeting, Gyges among them
		Areas._person(area, g, ring_of[k], meeting, "gyges" if k == 0 else "herdsman", back)
	Kit.cylinder(g, Vector3(0, 0, -44.0), 14.0, 12.0, "rock", true, 10, 9.0)  # the king's hill
	Props.palace_front(g, Vector3(0, 12.0, -44.0), 0.0, whole)
	return Areas._spots(area, g, back, Vector3(-10.0, TOP, 6.0), Vector3(16.0, TOP, 10.0), 4.5,
		[Vector3(-22.0, TOP, -8.0), Vector3(-22.0, TOP, -5.0)], Vector3(-24.0, TOP, 2.0), PI / 2.0, Vector3(-20.0, TOP, 20.0), PI)


## `count` points round a circle, in the same space as `centre`.
static func _circle(centre: Vector3, radius: float, count: int) -> Array:
	var out: Array = []
	for k in count:
		var a := TAU * k / count
		out.append(centre + Vector3(cos(a), 0, sin(a)) * radius)
	return out


## The sun and the divided line (Republic VI.507-511) as a terrace road, cut in four lengths in
## Plato's proportion (a line cut unequally, and each part cut again in the same ratio: here 1 : 2),
## walked from the dim end to the bright: images (shadows on the ground and still pools), the things
## themselves (a living tree, a horse, a made bowl), the mathematicals (the square and its diagonal
## inlaid, the circle, a sand tray: reasoning down from hypotheses), and the forms (a white terrace
## open to the sky, and the sun over it, the image of the good, "beyond being"). Returns, besides the
## usual, "segments": [{"name", "from", "to"}] in walking order.
static func the_line(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(30.0, 0.04, 64.0), "grass" if back.has("leaves") else "ashbed", false)
	var parts := [["images", 6.0, "path"], ["things", 12.0, "paving"], ["mathematicals", 12.0, "marble"], ["forms", 24.0, "#f4f2ec"]]
	var z := 27.0
	var segments: Array = []
	for part: Array in parts:
		var length: float = part[1]
		var width := 4.0 if part[0] != "forms" else 14.0
		Kit.box(g, Vector3(0, 0.03, z - length / 2.0), Vector3(width, 0.04, length), str(part[2]) if whole else "stone", false)
		Kit.box(g, Vector3(2.3, 0.05, z - length / 2.0), Vector3(0.06, 0.04, length - 0.2), "bronze" if whole else "verdigris", false)  # the line
		Kit.box(g, Vector3(2.3, 0.3, z), Vector3(0.12, 0.5, 0.12), "stone")  # the mark where each part begins
		segments.append({"name": part[0], "from": Areas._at(g, Vector3(0, 0, z)), "to": Areas._at(g, Vector3(0, 0, z - length))})
		z -= length
	area["segments"] = segments
	# images: shadows lying on the ground, and still pools that hold reflections
	for k in 3:
		Kit.box(g, Vector3(-1.0 + k * 1.0, 0.06, 24.5 - k * 0.8), Vector3(0.5, 0.01, 1.8), "shadow", false, Vector3(0, 0.3 * k, 0))
	for x: float in [-4.0, 4.0]:
		Kit.cylinder(g, Vector3(x, 0.02, 24.0), 1.3, 0.05, "water" if back.has("water") else "drybed", false, 12)
	# things: a tree, a beast, a thing made
	area["sway"].append(Kit.olive(g, Vector3(-4.5, 0, 16.0), 0.9, back.has("leaves")))
	Greek.beast(g, Vector3(4.5, 0, 17.0), -0.4, "horse", "", 1.0, back.has("leaves"))
	Greek.krater(g, Vector3(3.2, 0, 12.0), whole)
	# the mathematicals: the square and its diagonal, the circle, and a tray to reason in
	var sq := Kit.group(g, Vector3(0, 0.06, 3.0))
	for k in 4:
		var a := k * PI / 2.0
		Kit.box(sq, Vector3(sin(a), 0, cos(a)) * 1.5, Vector3(3.0, 0.01, 0.06), "dark", false, Vector3(0, a + PI / 2.0, 0))
	Kit.box(sq, Vector3.ZERO, Vector3(4.24, 0.01, 0.06), "dark", false, Vector3(0, PI / 4.0, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 1.2
	ring.outer_radius = 1.28
	Kit.mesh(g, ring, "dark", Vector3(0, 0.06, -1.0), Vector3.ZERO, Vector3(1.0, 0.1, 1.0))
	Greek.sand_tray(g, Vector3(-5.0, 0, 6.0), PI / 2.0, whole)
	# the forms: the bright terrace, and the sun over it
	for k in 6:
		Kit.column(g, Vector3(-6.5 + (k % 2) * 13.0, 0, -8.0 - (k / 2) * 8.0), 5.0, not whole and k % 3 == 1)
	if back.has("sun"):
		Kit.blob(g, Vector3(0, 40.0, -90.0), 7.0, "fire", Vector3.ONE, 12)
		var l := OmniLight3D.new()
		l.position = Vector3(0, 12.0, -24.0)
		l.light_color = Color("fff0c8")
		l.light_energy = 1.6
		l.omni_range = 30.0
		g.add_child(l)
	return Areas._spots(area, g, back, Vector3(-1.5, 0, 9.0), Vector3(0, 0, -17.0), 4.5,
		[Vector3(8.0, 0, 22.0), Vector3(8.0, 0, 25.0)], Vector3(-9.0, 0, 20.0), PI / 2.0, Vector3(9.0, 0, -26.0), -PI / 2.0)


## The cave (Republic VII.514-521) as a whole place: the hill it runs into, round 1's cave within
## (the prisoners, the wall, the bearers, the fire, the shadows), the steep rough way up, and outside
## in the sun the world the freed prisoner comes out into: trees, still water, beasts, the sky. The
## outside ground stands level with the top of the way up. Returns, besides the usual, what
## Greek.cave returns ("fire", "bearers", "shadows"), "mouth": where the way up comes out, "pool".
static func cave(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	const TOP := 4.8
	var inside := Greek.cave(g, Vector3.ZERO, 0.0, back.has("lamps"))
	for key in ["fire", "bearers", "shadows"]:
		area[key] = inside[key]
	if inside["fire"]:
		area["flicker"].append(inside["fire"])
	Kit.box(g, Vector3(0, 11.5, -1.0), Vector3(26.0, 6.0, 22.0), "rock")  # the hill over it
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 12.0, 4.0, 0), Vector3(6.0, 8.0, 22.0), "rock")
		Kit.box(g, Vector3(side * 6.0, TOP / 2.0, 11.5), Vector3(8.0, TOP, 1.0), "rock")  # either side of the way out
	Kit.box(g, Vector3(0, TOP / 2.0, 26.0), Vector3(44.0, TOP, 28.0), "rock")  # the world above, level with the way out
	Kit.box(g, Vector3(0, TOP + 0.02, 26.0), Vector3(44.0, 0.04, 28.0), "grass" if back.has("leaves") else "ashbed", false)
	area["mouth"] = Areas._at(g, Vector3(0, TOP, 12.5))
	var pool := Vector3(7.0, TOP, 22.0)
	Kit.cylinder(g, pool + Vector3(0, 0.03, 0), 2.6, 0.05, "water" if back.has("water") else "drybed", false, 14)
	area["pool"] = Areas._at(g, pool)
	area["sway"].append(Kit.olive(g, Vector3(10.0, TOP, 20.0), 1.0, back.has("leaves")))
	area["sway"].append(Kit.plane_tree(g, Vector3(-12.0, TOP, 30.0), 1.1, back.has("leaves")))
	Greek.beast(g, Vector3(14.0, TOP, 28.0), 2.2, "horse", "", 1.0, back.has("leaves"))
	for k in 3:
		Greek.beast(g, Vector3(-4.0 + k * 1.8, TOP, 34.0), k * 1.1, "goat", "", 1.0, back.has("leaves"))
	area["birds"].append_array(Kit.flock(g, Vector3(0, TOP + 12.0, 26.0), 5, 8.0, 2.0) if back.has("sun") else [])
	return Areas._spots(area, g, back, Vector3(0, TOP, 16.0), Vector3(-8.0, TOP, 24.0), 4.5,
		[Vector3(10.0, TOP, 33.0), Vector3(13.0, TOP, 33.0)], Vector3(-16.0, TOP, 34.0), PI / 2.0, Vector3(0, TOP, 37.0), PI)


## The myth of Er (Republic X.614-621): the meadow where the souls gather, two openings in the earth
## side by side and two in the sky above them, the judges sitting between; souls coming up dusty
## from under the earth and down clean from heaven, and camping in the meadow; far off the spindle
## of Necessity in its column of light, Necessity behind it and the three Fates on thrones round it,
## and before them Lachesis's prophet with the lots and the patterns of lives spread on the ground;
## off to the side the plain of Lethe. Er himself lies on his pyre in the world above, on the
## twelfth day, when he woke. Every soul is a shade. Returns, besides the usual, "whorls" and
## "speeds" (the spindle's), "lives": where the patterns of lives lie, and "banks": Lethe's near bank.
static func er(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(64.0, 0.04, 72.0), "grass" if back.has("leaves") else "ashbed", false)
	for x: float in [-10.0, -4.0]:  # the openings in the earth, and over them those in the sky
		Kit.cylinder(g, Vector3(x, 0.02, 14.0), 2.0, 0.05, "dark", false, 12)
		for k in 8:
			var a := TAU * k / 8.0
			Kit.blob(g, Vector3(x + cos(a) * 2.2, 0.2, 14.0 + sin(a) * 2.2), 0.4, "rock", Vector3(1.2, 0.7, 1.0), 5)
		Kit.cylinder(g, Vector3(x, 14.0, 14.0), 2.0, 0.1, "glow" if whole else "glow_cold", false, 12)
	for k in 3:  # the judges, sitting between
		var p := Vector3(-9.0 + k * 1.5, 0, 10.0)
		Kit.box(g, p + Vector3(0, 0.25, -0.3), Vector3(0.8, 0.5, 0.8), "stone")
		Areas._person(area, g, p + Vector3(0, 0.1, -0.3), Vector3(-7.5, 0, 16.0), "juror", back, "household", "sit", "e8e2d2")
	var rng := RandomNumberGenerator.new()
	rng.seed = 614
	for k in 14:  # the souls: the dusty from under the earth, the clean from heaven, camping in the meadow
		var from_earth := k % 2 == 0
		var p := Vector3(rng.randf_range(-14.0, 14.0), 0, rng.randf_range(16.0, 30.0))
		var w := Kit.walker(g, p, rng.randf() * TAU, {"robe": "8a8274" if from_earth else "f0ece0", "skin": "c8c0b4"})
		Kit.shade(w["root"], 0.45)
		w["shade"] = true
		area["people"].append(w)
	var spindle := Props.spindle_of_necessity(g, Vector3(0, 0, -24.0), whole)
	area["whorls"] = spindle["whorls"]
	area["speeds"] = spindle["speeds"]
	Areas._person(area, g, Vector3(0, 0, -31.0), Vector3(0, 0, -24.0), "necessity", back, "teacher", "sit")
	var fates := [["clotho", Vector3(-7.0, 0, -20.5)], ["lachesis", Vector3(0, 0, -16.5)], ["atropos", Vector3(7.0, 0, -20.5)]]
	for f: Array in fates:
		var p: Vector3 = f[1]
		var yaw_f := Kit.face_yaw(p, Vector3(0, 0, -24.0)) + PI
		Kit.box(g, p + Vector3(0, 0.3, 0) - Vector3(sin(yaw_f), 0, cos(yaw_f)) * 0.2, Vector3(1.0, 0.6, 1.0), "marble")  # the throne
		Kit.box(g, p + Vector3(0, 1.4, 0) - Vector3(sin(yaw_f), 0, cos(yaw_f)) * 0.6, Vector3(1.0, 2.2, 0.2), "marble", false,
			Vector3(0, yaw_f, 0))
		Areas._person(area, g, p + Vector3(0, 0.25, 0), p + Vector3(sin(yaw_f), 0, cos(yaw_f)), str(f[0]), back, "teacher", "sit")
	Areas._person(area, g, Vector3(0, 0, -11.0), Vector3(0, 0, 0), "prophet", back, "teacher")
	var lives: Array = []
	for k in 12:  # the patterns of lives, many more than the souls
		var a := deg_to_rad(200.0 + k * 140.0 / 11.0)
		var p := Vector3(cos(a) * 5.0, 0.03, -9.5 - sin(a) * 2.5)
		Kit.box(g, p, Vector3(0.9, 0.02, 0.6), "papyrus" if whole else "ashbed", false, Vector3(0, a, 0))
		lives.append(Areas._at(g, p))
	area["lives"] = lives
	area["banks"] = Props.plain_of_lethe(g, Vector3(34.0, 0, -8.0), -PI / 2.0, 26.0, back.has("water"))
	var pyre := Props.pyre(g, Vector3(-24.0, 0, 26.0), 0.4, back.has("lamps"), true)  # Er on his pyre, about to wake
	if pyre:
		area["flicker"].append(pyre)
	return Areas._spots(area, g, back, Vector3(4.0, 0, 6.0), Vector3(10.0, 0, 6.0), 4.5,
		[Vector3(-20.0, 0, 4.0), Vector3(-20.0, 0, 7.0)], Vector3(-22.0, 0, -4.0), PI / 2.0, Vector3(14.0, 0, 30.0), PI)


## Agathon's house the night after his first victory, 416 BC (the Symposium): the men's dining room,
## seven couches round the walls with a table at each, the mixing bowl in the middle, lamps, the
## flute girl sent off to play to the women; the guests reclining (Agathon, Phaedrus, Eryximachus,
## Aristophanes); Socrates late, standing lost in thought in the neighbour's porch; and at the
## street door Alcibiades arriving drunk, crowned with ivy, on the flute girl's arm. Returns, besides
## the usual, "couches": each couch's place, and "door".
static func symposium(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(36.0, 0.04, 34.0), "paving" if whole else "ashbed", false)
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(11.0, 0.04, 9.0), "mosaic" if whole else "stone", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 5.75, 1.9, 0), Vector3(0.5, 3.8, 9.0), "fresco")
		Kit.box(g, Vector3(side * 3.4, 1.9, 4.75), Vector3(4.2, 3.8, 0.5), "fresco")  # the front, the door between
	Kit.box(g, Vector3(0, 1.9, -4.75), Vector3(12.0, 3.8, 0.5), "fresco")
	if whole:
		Kit.box(g, Vector3(0, 3.9, 0), Vector3(12.5, 0.2, 10.0), "roof", false)
	area["door"] = Areas._at(g, Vector3(0, 0, 5.6))
	var couches: Array = []
	var places := [[Vector3(-3.0, 0, -3.6), 0.0], [Vector3(0, 0, -3.6), 0.0], [Vector3(3.0, 0, -3.6), 0.0],
		[Vector3(-4.7, 0, -0.8), PI / 2.0], [Vector3(-4.7, 0, 2.2), PI / 2.0], [Vector3(4.7, 0, -0.8), -PI / 2.0],
		[Vector3(4.7, 0, 2.2), -PI / 2.0]]
	var guests := ["agathon", "phaedrus", "eryximachus", "aristophanes", "", "", ""]
	for k in places.size():
		var p: Vector3 = places[k][0]
		var y: float = places[k][1]
		Greek.kline(g, p, y, whole)
		couches.append(Areas._at(g, p))
		if guests[k] != "":
			var foot := p + Vector3(-0.8 * cos(y), 0, 0.8 * sin(y))  # the feet at the couch's low end, the head at its rest
			Areas._person(area, g, foot, foot + Vector3(sin(y), 0, cos(y)), guests[k], back, "household", "recline")
	area["couches"] = couches
	Greek.krater(g, Vector3(0, 0, 0.5), whole)
	for p: Vector3 in [Vector3(-5.0, 0, -4.0), Vector3(5.0, 0, -4.0)]:
		var l := Kit.lamp_stand(g, p, back.has("lamps"))
		if l:
			area["flicker"].append(l)
	Areas._person(area, g, Vector3(0.4, 0, 7.0), Vector3(0, 0, 4.0), "alcibiades", back)
	Areas._person(area, g, Vector3(1.2, 0, 7.3), Vector3(0, 0, 4.0), "flute_girl", back)
	for x: float in [-11.0, -8.0]:  # the neighbour's porch
		Kit.column(g, Vector3(x, 0, 8.0), 3.4, not whole and x < -10.0)
	if whole:
		Kit.box(g, Vector3(-9.5, 3.5, 7.0), Vector3(4.5, 0.25, 3.0), "roof", false)
	Kit.box(g, Vector3(-9.5, 1.7, 5.6), Vector3(4.5, 3.4, 0.4), "plaster")
	Areas._person(area, g, Vector3(-9.5, 0, 7.2), Vector3(-9.5, 0, 12.0), "socrates", back, "teacher")
	return Areas._spots(area, g, back, Vector3(3.0, 0, 10.0), Vector3(0, 0, 15.0), 4.5,
		[Vector3(-12.0, 0, 13.0), Vector3(-12.0, 0, 16.0)], Vector3(12.0, 0, 12.0), -PI / 2.0, Vector3(9.0, 0, 19.0), PI)


## The prison on the last day (the Phaedo): the cell off a small court, Socrates' friends round him
## (Phaedo on a low stool by the bed, Crito, and others), Xanthippe with the baby being taken home,
## the servant of the Eleven at the door with the cup, and the evening sun on the hills ("the sun is
## still upon the mountains", 116e). Returns, besides the usual, "cell" (Props.prison_cell's spots)
## and "cup".
static func prison(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 2.0), Vector3(40.0, 0.04, 36.0), "paving" if whole else "ashbed", false)
	for side: float in [-1.0, 1.0]:  # the court's walls
		Kit.box(g, Vector3(side * 11.0, 2.0, 0), Vector3(0.5, 4.0, 16.0), "stone")
	Kit.box(g, Vector3(-7.0, 2.0, -8.0), Vector3(8.5, 4.0, 0.5), "stone")
	Kit.box(g, Vector3(7.0, 2.0, -8.0), Vector3(8.5, 4.0, 0.5), "stone")
	var cell := Props.prison_cell(g, Vector3(0, 0, -4.0), 0.0, whole)
	area["cell"] = {"bed": Areas._at(g, cell["bed"]), "door": Areas._at(g, cell["door"]), "window": Areas._at(g, cell["window"]),
		"bath": Areas._at(g, cell["bath"])}
	area["cup"] = Props.hemlock_cup(g, Vector3(0.9, 0, -6.0), 0.0, whole)
	Areas._person(area, g, Vector3(-1.2, 0.05, -5.5), Vector3(0, 0, -2.0), "socrates", back, "teacher", "sit")
	Areas._person(area, g, Vector3(-0.6, -0.15, -3.9), Vector3(-1.2, 0, -5.5), "phaedo", back, "household", "sit")
	Areas._person(area, g, Vector3(0.6, 0, -4.2), Vector3(-1.2, 0, -5.5), "crito", back)
	for k in 2:
		Areas._folk(area, g, Vector3(-2.2 + k * 3.6, 0, -2.2), Vector3(-1.2, 0, -5.5), {"robe": ["6a5a4a", "8a7a5a"][k], "beard": "short"}, back)
	Areas._person(area, g, Vector3(0.6, 0, -0.2), Vector3(0, 0, -5.0), "jailer", back)
	Areas._person(area, g, Vector3(6.0, 0, 5.0), Vector3(8.0, 0, 12.0), "xanthippe", back)
	Kit.hill(g, Vector3(-30.0, 0, -70.0), 30.0, 14.0, "earth")  # the hills in the evening sun
	Kit.hill(g, Vector3(35.0, 0, -80.0), 26.0, 10.0, "earth")
	return Areas._spots(area, g, back, Vector3(3.0, 0, 1.5), Vector3(0, 0, 5.5), 4.0,
		[Vector3(-8.0, 0, 1.0), Vector3(-8.0, 0, 4.0)], Vector3(8.0, 0, -2.0), -PI / 2.0, Vector3(-7.0, 0, -5.5), PI / 2.0)


# ---------- e4: Aristotle ----------

## Aristotle's Politics I.2 as ground to walk: in a colonnade the model of the three steps
## (Props.household_to_city), and out in the land the same three at full size: the household (a
## farmhouse, the ox and plough, the man, his wife and a slave at their work), a village of a few
## houses along the track beyond it, and the walled city on its hill further off. Returns, besides
## the usual, "stages" (the model's) and "steps": where each of the three stands at full size.
static func politics(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 14.0), Vector3(70.0, 0.04, 80.0), "grass" if back.has("leaves") else "ashbed", false)
	Kit.stoa(g, Vector3(0, 0, -8.0), 0.0, 24.0, 6.0, whole)
	area["stages"] = Props.household_to_city(g, Vector3(0, 0, -8.5), 0.0, whole)["stages"]
	var household := Vector3(-16.0, 0, 12.0)
	_house(g, household + Vector3(0, 0, -3.0), 0.0, 5.0, whole)
	Greek.field(g, household + Vector3(6.0, 0, 3.0), Vector2(8.0, 8.0), 0.0, back.has("leaves"))
	Greek.plough_team(g, household + Vector3(6.0, 0, 3.0), 0.0, back.has("leaves"))
	Areas._person(area, g, household + Vector3(-1.0, 0, 1.0), household + Vector3(0, 0, 4.0), "farmer", back)
	Areas._person(area, g, household + Vector3(1.0, 0, 0.5), household + Vector3(0, 0, 4.0), "weaver", back)
	Areas._folk(area, g, household + Vector3(-2.5, 0, 2.0), household + Vector3(6.0, 0, 3.0), {"robe": "8a7a5a", "hair_color": "2a1e16"}, back)
	var village := Vector3(10.0, 0, 30.0)
	for k in 5:
		var a := TAU * k / 5.0
		_house(g, village + Vector3(cos(a) * 5.0, 0, sin(a) * 4.0), -a + PI / 2.0, 4.0, whole)
	Kit.box(g, Vector3(-3.0, 0.03, 21.0), Vector3(3.0, 0.04, 26.0), "path", false, Vector3(0, -0.6, 0))  # the track between
	var city := Vector3(-8.0, 0, 52.0)
	Kit.cylinder(g, city, 12.0, 4.0, "rock", true, 12, 10.0)
	for k in 16:
		var a := TAU * k / 16.0
		if whole or k % 4 != 1:
			Kit.box(g, city + Vector3(cos(a) * 9.5, 5.2, sin(a) * 9.5), Vector3(4.0, 2.4, 0.8), "stone", true, Vector3(0, -a + PI / 2.0, 0))
	for k in 9:
		_house(g, city + Vector3(-5.0 + (k % 3) * 4.0, 4.0, -4.0 + (k / 3) * 4.0), 0.0, 2.5, whole)
	Props.shrine(g, city + Vector3(0, 4.0, -6.5), 0.0, "athena", whole)
	area["steps"] = [Areas._at(g, household), Areas._at(g, village), Areas._at(g, city)]
	return Areas._spots(area, g, back, Vector3(2.0, 0, -5.0), Vector3(0, 0, 4.0), 5.0,
		[Vector3(10.0, 0, 2.0), Vector3(13.0, 0, 2.0)], Vector3(-8.0, 0, -6.5), 0.0, Vector3(8.0, 0, -6.0), 0.0)


## Aristotle's Poetics as a place: round 1's theatre of Dionysus with a tragedy under way, the actors
## masked before the skene's doors, the chorus of fifteen in the orchestra round the god's altar in
## rows of three, the crane standing ready over the stage for the god from the machine. The six
## parts of tragedy (plot, character, thought, diction, song, spectacle) have their stones round
## the orchestra. Returns, besides the usual, "doors" (the skene's, in the parent's space),
## "chorus" and "crane_at".
static func poetics(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	var th := Greek.theatre(g, Vector3.ZERO, 0.0, 12, whole)
	area["doors"] = (th["doors"] as Array).map(func(p: Vector3) -> Vector3: return Areas._at(g, p))
	area["crane_at"] = Areas._at(g, th["crane_at"])
	Greek.crane(g, Vector3(7.5, 0.6, 12.2), -PI / 2.0, false, whole)
	var undead := not back.has("household")
	for k in 3:  # the three actors on the stage
		var w := Greek.actor(g, Vector3(-3.0 + k * 3.0, 0.6, 10.0), PI, "tragic", ["6a2a3a", "2a3a5a", "e8e2d2"][k], undead)
		w["shade"] = undead
		area["people"].append(w)
	var chorus: Array = []
	for k in 15:  # the chorus in rows of three, facing the audience
		var w := Greek.actor(g, Vector3(-1.5 + (k % 3) * 1.5, 0, -3.0 + (k / 3) * 1.3), PI, "tragic", "5a4a6a", undead)
		w["shade"] = undead
		chorus.append(w)
		area["people"].append(w)
	area["chorus"] = chorus
	return Areas._spots(area, g, back, Vector3(-5.0, 0, 6.0), Vector3(0, 0, 1.0), 7.2,
		[Vector3(24.0, 0, 14.0), Vector3(24.0, 0, 17.0)], Vector3(-24.0, 0, 15.0), PI / 2.0, Vector3(-20.0, 0, 19.0), PI)


# ---------- the Republic's mini-game: the city in speech ----------

## What each order is made of, in the Republic's myth of the metals (III.415a): gold in the rulers,
## silver in their auxiliaries, bronze and iron in the farmers and craftsmen. The soul's three parts
## glow in the same colours: reason in the head, spirit in the chest, appetite in the belly.
const ORDERS := {"guardians": Color("f0c850"), "auxiliaries": Color("d0d8e8"), "producers": Color("c07838")}

## Where each stage's additions stand on the board, in its own space: the Hall raises them there
## with a fade when the talk reaches that stage.
const SLOTS := [
	[],
	[Vector3(-8, 0, 6), Vector3(-10, 0, -1), Vector3(-6, 0, -7), Vector3(6, 0, -7), Vector3(10, 0, -1), Vector3(8, 0, 6), Vector3(0, 0, 9)],
	[Vector3(-4, 0, 2), Vector3(4, 0, 2), Vector3(-13, 0, 8), Vector3(13, 0, 8), Vector3(27, 0, -8)],
	[Vector3(27, 0, 2), Vector3(27, 0, -3), Vector3(31, 0, 2)],
	[Vector3(-15, 0, -11), Vector3(14, 0, -12), Vector3(0, 1.5, -14)],
	[Vector3(0, 0, 0)],
]


## The city in speech (Republic II-IV), the board for the Republic's mini-game: a hillside site that
## grows as the talk builds it. `stage` 0 is the bare site with its boundary stones; 1 the city of
## pigs, where each does one work (farmer, builder, weaver, cobbler, smith, herdsman, merchant, a
## house and workshop each) and they feast on leaves and barley cakes (369b-372d); 2 the fevered
## city, with couches, cooks, painters, doctors, swine, and the boundary pushed out onto the
## neighbours' land (372e-373e); 3 the army, camped on the land it took (373e-374e); 4 the guardians,
## with their common houses, their training ground and their educators, the rulers on the height
## (375-417); 5 the just city, walled, each order in its place, which turns round into the soul
## (434d-441c): a tall figure over the city, its belly, chest and head glowing bronze, silver and gold.
## Returns, besides the usual, "stage", "slots": where the next stage's additions go (in the parent's
## space; none at 5), "added": {stage: the nodes that stage raised, in order}, "buildings": every building raised so far, "orders": {"producers",
## "auxiliaries", "guardians"}: each order's people and troops, and "soul": {"root", "parts":
## {"appetite", "spirit", "reason"}}, hidden until stage 5.
static func city_in_speech(parent: Node3D, at: Vector3, yaw: float, stage: int, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := Areas._area(g)
	var whole := back.has("walkway")
	stage = clampi(stage, 0, 5)
	area["stage"] = stage
	var buildings: Array = []
	var orders := {"producers": [], "auxiliaries": [], "guardians": []}
	Kit.box(g, Vector3(0, 0.01, 4.0), Vector3(72.0, 0.04, 72.0), "earth" if stage == 0 or not back.has("leaves") else "grass", false)
	Kit.cylinder(g, Vector3(0, 0, -14.0), 7.0, 1.5, "rock", true, 12, 6.0)  # the height, where the rulers will live
	var bound := 18.0 if stage < 2 else 30.0  # the boundary stones, pushed out once the city wants more land
	for k in 10:
		var a := TAU * k / 10.0
		Kit.box(g, Vector3(cos(a) * bound, 0.5, sin(a) * bound * 0.8), Vector3(0.4, 1.0, 0.3), "stone")
	var added := {}  # stage -> the nodes that stage raised on the board, in order
	var mark := g.get_child_count()
	if stage >= 1:  # the city of pigs: one man, one work
		var trades := ["farmer", "builder", "weaver", "cobbler", "smith", "herdsman", "merchant"]
		for k in trades.size():
			var p: Vector3 = SLOTS[1][k]
			var face := Vector3(0, 0, 2.0)
			buildings.append(_house(g, p - (face - p).normalized() * 2.2, Kit.face_yaw(p, face), 3.2, whole))
			orders["producers"].append(Areas._person(area, g, p, face, trades[k], back))
		Greek.field(g, Vector3(-11.0, 0, 11.0), Vector2(6.0, 5.0), 0.3, back.has("leaves"))
		for k in 4:
			Greek.beast(g, Vector3(12.0 + k * 1.3, 0, 11.0 + (k % 2)), 2.5, "sheep", "", 1.0, back.has("leaves"))
		for k in 4:  # their feast on strewn leaves, with barley cakes and wine
			var a := TAU * k / 4.0 + 0.4
			Kit.box(g, Vector3(cos(a) * 1.6, 0.06, 3.0 + sin(a) * 1.6), Vector3(1.8, 0.1, 0.7), "#5a7a3a" if back.has("leaves") else "withered",
				false, Vector3(0, -a, 0))
		Kit.cylinder(g, Vector3(0, 0, 3.0), 0.3, 0.5, "clay", false, 8, 0.2)
	added[1] = g.get_children().slice(mark)
	mark = g.get_child_count()
	if stage >= 2:  # the fevered city
		for k in 2:
			var p: Vector3 = SLOTS[2][k]
			Greek.kline(g, p, PI if k else 0.0, whole)
		Greek.krater(g, Vector3(0, 0, 2.0), whole)
		var more := [["painter", SLOTS[2][2]], ["cook", SLOTS[2][3]], ["doctor", Vector3(-5.0, 0, 13.0)]]
		for m: Array in more:
			var p: Vector3 = m[1]
			buildings.append(_house(g, p + Vector3(0, 0, -2.4), 0.0, 3.4, whole))
			orders["producers"].append(Areas._person(area, g, p, p + Vector3(0, 0, 3.0), str(m[0]), back))
		for k in 3:
			Greek.beast(g, Vector3(-16.0 + k * 1.4, 0, 2.0 + (k % 2) * 1.2), k * 1.3, "pig", "", 1.0, back.has("leaves"))
		for p: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(-15, 0, -6), Vector3(15, 0, -6), Vector3(0, 0, -4.5)]:  # more houses crowding in
			buildings.append(_house(g, p, 0.0, 2.8, whole))
		Greek.field(g, SLOTS[2][4], Vector2(8.0, 8.0), 0.0, back.has("leaves"))  # the neighbours' land
	added[2] = g.get_children().slice(mark)
	mark = g.get_child_count()
	if stage >= 3:  # the army, camped on the land it took
		for k in 3:
			buildings.append(_tent(g, SLOTS[3][k], PI / 2.0, whole))
		var army := Greek.phalanx(g, Vector3(29.0, 0, 9.0), 2, 5, "athens", not back.has("soldiers"))
		area["squads"].append(army)
		orders["auxiliaries"].append(army)
	added[3] = g.get_children().slice(mark)
	mark = g.get_child_count()
	if stage >= 4:  # the guardians: common houses, the training ground, the educators, the rulers on the height
		var mess := Kit.group(g, SLOTS[4][0])
		Kit.box(mess, Vector3(0, 1.6, 0), Vector3(10.0, 3.2, 4.0), "plaster" if whole else "ashbed")
		if whole:
			Kit.box(mess, Vector3(0, 3.35, 0), Vector3(10.6, 0.3, 4.6), "roof", false)
		buildings.append(mess)
		var track := Kit.group(g, SLOTS[4][1])
		Kit.box(track, Vector3(0, 0.03, 0), Vector3(12.0, 0.04, 3.0), "sand", false)
		for x: float in [-6.0, 6.0]:
			Kit.box(track, Vector3(x, 0.6, 0), Vector3(0.2, 1.2, 0.2), "stone")  # the turning posts
		Kit.box(track, Vector3(0, 0.03, 4.0), Vector3(5.0, 0.04, 5.0), "sand", false)  # the wrestling floor
		buildings.append(track)
		for k in 2:
			Areas._person(area, g, SLOTS[4][1] + Vector3(-4.0 + k * 8.0, 0, 4.0), SLOTS[4][1] + Vector3(0, 0, 4.0), "educator", back, "teacher")
		var young := Greek.phalanx(g, SLOTS[4][1] + Vector3(0, 0, -3.0), 1, 4, "athens", not back.has("soldiers"))
		area["squads"].append(young)
		orders["auxiliaries"].append(young)
		for k in 3:
			var p: Vector3 = SLOTS[4][2] + Vector3(-1.5 + k * 1.5, 0, 1.5)
			orders["guardians"].append(Areas._person(area, g, p, Vector3(0, 0, 4.0), "ruler", back, "teacher"))
	added[4] = g.get_children().slice(mark)
	mark = g.get_child_count()
	if stage >= 5:  # the just city: its wall round it, the temple on the height
		for k in 24:
			var a := TAU * k / 24.0
			if absf(wrapf(a - PI / 2.0, -PI, PI)) < 0.2:
				continue  # the gate, toward +Z
			if not whole and k % 5 == 2:
				continue
			Kit.box(g, Vector3(cos(a) * 25.0, 1.6, sin(a) * 25.0), Vector3(6.6, 3.2, 1.0), "stone", true, Vector3(0, -a + PI / 2.0, 0))
		buildings.append(Props.shrine(g, Vector3(0, 1.5, -17.0), 0.0, "athena", whole))
		added[5] = g.get_children().slice(mark)
	area["added"] = added
	# the soul: the city turned round, one person, a head of gold, a chest of silver, a belly of bronze
	const S := 14.0  # the soul stands this many times a man's height, over the whole city
	var soul := Kit.group(g, Vector3(0, 0, -36.0))
	var body := Kit.walker(soul, Vector3.ZERO, 0.0, {"robe": "d8d4cc", "skin": "e8e0d4", "hair_color": "c8c4bc"})
	(body["root"] as Node3D).scale = Vector3.ONE * S
	Kit.shade(body["root"], 0.3)
	var parts := {}
	var at_part := {"appetite": [Vector3(0, 0.95, 0.07) * S, 0.16 * S, "producers"], "spirit": [Vector3(0, 1.39, 0.09) * S, 0.15 * S, "auxiliaries"],
		"reason": [Vector3(0, 1.8, 0.07) * S, 0.13 * S, "guardians"]}
	for part: String in at_part:
		var spec: Array = at_part[part]
		var c: Color = ORDERS[spec[2]]
		var node := Kit.group(soul, spec[0])
		var ball := Kit.blob(node, Vector3.ZERO, spec[1], "fire", Vector3.ONE, 10)
		ball.material_override = _glow(c)
		var l := OmniLight3D.new()
		l.light_color = c
		l.light_energy = 2.0
		l.omni_range = 2.0 * S
		node.add_child(l)
		parts[part] = node
	Kit.unsolid(soul)
	soul.visible = stage >= 5
	area["soul"] = {"root": soul, "parts": parts}
	area["buildings"] = buildings
	area["orders"] = orders
	area["slots"] = (SLOTS[stage + 1] if stage < 5 else []).map(func(p: Vector3) -> Vector3: return Areas._at(g, p))
	return Areas._spots(area, g, back, Vector3(3.0, 0, 27.0), Vector3(0, 0, 32.0), 4.5,
		[Vector3(-26.0, 0, 30.0), Vector3(-23.0, 0, 32.0)], Vector3(26.0, 0, 30.0), -PI / 2.0, Vector3(18.0, 0, 35.0), PI)
