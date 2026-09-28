extends RefCounted
## Ready-made areas for the Greek places still to come: one set piece per book's ground (the
## Rhetorica's law court and memory house, Euclid's Museum and his two propositions, Homer's
## camp and hall, and so on), built from the kits' pieces so that a place is later assembled from
## a few calls. Each is built as far as its place is restored: `back` is the list of pieces back
## (Places.back(): water, leaves, lamps, walkway, sun, teacher, household, soldiers), and anything
## not back is built lost. The sky and light stay the place's own (Places._sky).
## Every set piece faces +Z and returns what places.gd's builders use:
##   {"root", "spots": {"teacher", "book", "seat", "facts": [..], "stones": [..]}, "people",
##    "flicker", "sway", "birds", "squads"}
## Spots are in the parent's space. "stones" are where the lesson stones stand, each with a small
## scene of its point round it; "facts" are where the fact steles stand. The teacher is not built
## here (the place builds him from rooms.json); his spot is. Homer's areas also return "beats":
## {name: {"at", "hero"}}, where each playable moment happens and whose eyes it is seen through
## (People.hero_arms).

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Egypt := preload("res://scripts/hall/kit_egypt.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")


## An empty result for a set piece rooted at `g`.
static func _area(g: Node3D) -> Dictionary:
	return {"root": g, "spots": {"teacher": g.position, "book": g.position, "seat": g.position, "facts": [], "stones": []},
		"people": [], "flicker": [], "sway": [], "birds": [], "squads": []}


## A spot in the area's own space, as the parent sees it.
static func _at(g: Node3D, local: Vector3) -> Vector3:
	return g.transform * local


## `count` points on an arc round `centre`, from `from_deg` to `to_deg`, in the area's own space.
static func _ring(centre: Vector3, radius: float, count: int, from_deg: float, to_deg: float) -> Array:
	var out: Array = []
	for k in count:
		var a := deg_to_rad(lerpf(from_deg, to_deg, (k + 0.5) / count))
		out.append(centre + Vector3(cos(a), 0, sin(a)) * radius)
	return out


## The same arc of spots, as the parent sees them.
static func _arc(g: Node3D, centre: Vector3, radius: float, count: int, from_deg: float, to_deg: float) -> Array:
	return _ring(centre, radius, count, from_deg, to_deg).map(func(p: Vector3) -> Vector3: return _at(g, p))


## A townsman, scholar or juror who stands about the area: a walker, a pale shade while the
## household is not back. Adds him to the area's people.
static func _folk(area: Dictionary, g: Node3D, at: Vector3, face: Vector3, look: Dictionary, back: Array) -> Dictionary:
	var w := Kit.walker(g, at, Kit.face_yaw(at, face), look)
	if not back.has("household"):
		Kit.shade(w["root"], 0.3)
		w["shade"] = true
	area["people"].append(w)
	return w


## A reading desk with the book on it; its spot is where the reader stands.
static func _book(area: Dictionary, g: Node3D, at: Vector3, yaw: float, back: Array) -> void:
	var lamp := Kit.desk(g, at, yaw, false, back.has("lamps"))
	if lamp:
		area["flicker"].append(lamp)
	area["spots"]["book"] = _at(g, at + Vector3(sin(yaw), 0, cos(yaw)) * 1.2)


# ---------- e1: the Rhetorica ad Herennium ----------

## A court in the Forum, about 85 BC: a paved floor under a portico, the praetor's tribunal at the
## back, the jurors on their benches either side, the advocates' benches, the water clock that
## times each speech, and a ring of onlookers (the corona). Stones stand round the open floor
## where the speaker walks: the five parts of the art and the six parts of a speech.
static func law_court(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(26.0, 0.04, 22.0), "paving", false)
	for k in 9:  # the portico behind the court
		var x := -12.0 + k * 3.0
		if whole or k % 3 != 1:
			Rome.column(g, Vector3(x, 0, -10.0), 6.5, 0.35, "travertine")
	if whole:
		Kit.box(g, Vector3(0, 6.8, -10.0), Vector3(26.0, 0.6, 1.2), "travertine", false)
	area["spots"]["teacher"] = _at(g, Vector3(0, 0, 1.0))
	Rome.tribunal(g, Vector3(0, 0, -6.5), 0.0, whole)
	for side: float in [-1.0, 1.0]:  # the jurors either side, facing the floor
		Rome.subsellia(g, Vector3(side * 7.5, 0, -1.0), -side * PI / 2.0, 7.0, 3, whole)
	Rome.subsellia(g, Vector3(0, 0, 6.5), PI, 6.0, 1, whole)  # the advocates' bench
	Greek.clepsydra(g, Vector3(2.5, 0, 3.5), back.has("water"))
	var ring := _ring(Vector3.ZERO, 11.0, 10, 20.0, 160.0)
	for k in ring.size():  # the corona: onlookers pressing round the court
		_folk(area, g, ring[k], Vector3.ZERO, {"robe": ["e8e2d2", "8a6a4a", "6a5a4a", "e0d6c0"][k % 4], "hair_color": "4a3a2a"}, back)
	area["spots"]["stones"] = _arc(g, Vector3(0, 0, 0.5), 4.5, 6, 200.0, 340.0) + _arc(g, Vector3(0, 0, 0.5), 4.5, 5, 20.0, 160.0)
	area["spots"]["facts"] = [_at(g, Vector3(-11.0, 0, 4.0)), _at(g, Vector3(-11.0, 0, 7.0)), _at(g, Vector3(-11.0, 0, 10.0))]
	_book(area, g, Vector3(10.0, 0, 7.0), -PI / 2.0, back)
	Kit.bench(g, Vector3(9.0, 0, 10.0), PI)
	area["spots"]["seat"] = _at(g, Vector3(9.0, 0, 10.0))
	return area


## A memory house, the art of memory of the Rhetorica (III.16-24): a quiet peristyle, well lit,
## its colonnade divided into places (loci) walked always in the same order, every fifth marked by
## a golden hand, and in the first places the striking pictures that hold what is to be
## remembered. Returns, besides the usual, "loci": the twenty places in walking order.
static func memory_house(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	const S := 20.0
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(S + 4.0, 0.04, S + 4.0), "mosaic", false)
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(S - 6.0, 0.04, S - 6.0), "earth" if back.has("leaves") else "ashbed", false)  # the garden
	for side in 4:  # the colonnade, a wall behind each side, the door in the first (+Z)
		var a := side * PI / 2.0
		var wall := Kit.group(g, Vector3(sin(a), 0, cos(a)) * (S / 2.0 + 1.5), a + PI)
		if side == 0:
			for end: float in [-1.0, 1.0]:
				Kit.box(wall, Vector3(end * ((S + 3.0) / 4.0 + 0.75), 2.2, 0), Vector3((S + 3.0) / 2.0 - 1.5, 4.4, 0.4), "fresco")
		else:
			Kit.box(wall, Vector3(0, 2.2, 0), Vector3(S + 3.0, 4.4, 0.4), "fresco")
	var loci: Array = []
	for k in 20:  # five places a side, walked round from the entrance
		var side := k / 5
		var i := k % 5
		var a := side * PI / 2.0
		var along := Vector3(cos(a), 0, -sin(a))
		var out := Vector3(sin(a), 0, cos(a))
		var p := out * (S / 2.0 - 1.0) + along * (-S / 2.0 + 2.0 + i * 4.0)
		loci.append(p)
		if whole or k % 4 != 2:
			Rome.column(g, out * (S / 2.0 - 2.5) + along * (-S / 2.0 + 4.0 + i * 4.0), 4.0, 0.25)
		if i == 4:  # every fifth place: the golden hand
			Rome.memory_image(g, p + out * 0.6, a + PI, "golden_hand", whole)
	for k in 4:  # the first places hold their pictures
		Rome.memory_image(g, loci[k], atan2(-loci[k].x, -loci[k].z), ["poison", "bloodied", "crowned", "smeared"][k],
			back.has("household"))
	for p in [Vector3(-3, 0, -3), Vector3(3, 0, 3)]:
		area["sway"].append(Kit.plant(g, p, back.has("leaves")))
	area["loci"] = loci.map(func(p: Vector3) -> Vector3: return _at(g, p))
	area["spots"]["teacher"] = _at(g, Vector3(0, 0, S / 2.0 - 3.0))
	area["spots"]["stones"] = _arc(g, Vector3.ZERO, 4.0, 6, 0.0, 360.0)
	area["spots"]["facts"] = [_at(g, Vector3(-4.0, 0, S / 2.0 + 0.9)), _at(g, Vector3(4.0, 0, S / 2.0 + 0.9))]
	_book(area, g, Vector3(0, 0, -S / 2.0 + 1.0), 0.0, back)
	Kit.bench(g, Vector3(0, 0, 1.5), 0.0)
	area["spots"]["seat"] = _at(g, Vector3(0, 0, 1.5))
	return area


# ---------- e1: Euclid ----------

## The court of the Museum at Alexandria, about 300 BC: a garden of date palms inside Egyptian porticos,
## library cabinets of papyrus rolls under them, scholars at sand trays, and the Pharos over the
## roofs to the north (-Z). The definitions, postulates and common notions have their stones round
## the garden.
static func museum_court(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	const S := 26.0
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(S + 8.0, 0.04, S + 8.0), "limestone", false)
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(S - 8.0, 0.04, S - 8.0), "grass" if back.has("leaves") else "ashbed", false)
	for side in range(1, 4):  # Egyptian porticos on three sides (the Ptolemies built in the pharaohs' manner); +Z is the way in
		var a := side * PI / 2.0
		Egypt.portico(g, Vector3(sin(a), 0, cos(a)) * (S / 2.0), a + PI, S, 5.0, whole)
		for k in 3:  # the cabinets along the back wall
			var along := Vector3(cos(a), 0, -sin(a)) * (-7.0 + k * 7.0)
			Greek.armarium(g, Vector3(sin(a), 0, cos(a)) * (S / 2.0 + 2.0) + along, a + PI, whole)
	for p: Vector3 in [Vector3(-5, 0, -5), Vector3(5, 0, -5), Vector3(-5, 0, 5), Vector3(5, 0, 5), Vector3(0, 0, -7)]:
		area["sway"].append(Greek.date_palm(g, p, 7.0 + fmod(absf(p.x + p.z), 2.0), back.has("leaves")))
	for k in 2:  # scholars at their sand trays
		var p := Vector3(-3.0 + k * 6.0, 0, 3.0)
		Greek.sand_tray(g, p, 0.0, whole)
		_folk(area, g, p + Vector3(0, 0, -1.2), p, {"robe": "e0d6c0", "hair_color": "3a2a1e", "beard": "short"}, back)
	if back.has("lamps"):
		for p in [Vector3(-9, 0, 9), Vector3(9, 0, 9), Vector3(-9, 0, -9), Vector3(9, 0, -9)]:
			area["flicker"].append(Kit.lamp_stand(g, p, true))
	var light := Greek.pharos(g, Vector3(40, 0, -260), 0.8, back.has("sun"))
	if light:
		area["flicker"].append(light)
	area["spots"]["teacher"] = _at(g, Vector3(0, 0, 0))
	area["spots"]["stones"] = _arc(g, Vector3.ZERO, 7.5, 6, 0.0, 360.0)
	area["spots"]["facts"] = [_at(g, Vector3(-6.0, 0, S / 2.0 - 2.0)), _at(g, Vector3(0, 0, S / 2.0 - 2.0)), _at(g, Vector3(6.0, 0, S / 2.0 - 2.0))]
	_book(area, g, Vector3(3.0, 0, -3.0), PI, back)
	Kit.bench(g, Vector3(-3.0, 0, -3.5), 0.0)
	area["spots"]["seat"] = _at(g, Vector3(-3.0, 0, -3.5))
	return area


## Proposition I.1 on open sand by the harbour: the equal-sided triangle laid out with pegs and a
## cord round its two circles, big enough to walk; a sand tray to try it small; stones round it.
## Returns, besides the usual, "corners": A, B and C.
static func prop_one(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.cylinder(g, Vector3(0, -0.02, 0), 16.0, 0.05, "sand", false, 16)
	area["corners"] = Greek.construction(g, Vector3.ZERO, 0.0, 6.0, whole).map(func(p: Vector3) -> Vector3: return g.transform * p)
	Greek.sand_tray(g, Vector3(-9.0, 0, 5.0), 0.6, whole)
	for p: Vector3 in [Vector3(-12, 0, -8), Vector3(12, 0, -6), Vector3(10, 0, 10)]:
		area["sway"].append(Greek.date_palm(g, p, 8.0, back.has("leaves")))
	area["spots"]["teacher"] = _at(g, Vector3(-3.0, 0, 1.5))
	area["spots"]["stones"] = _arc(g, Vector3(0, 0, -2.5), 10.0, 6, 200.0, 340.0)
	area["spots"]["facts"] = [_at(g, Vector3(12.0, 0, 2.0)), _at(g, Vector3(12.0, 0, 5.0))]
	_book(area, g, Vector3(-11.0, 0, 0.0), PI / 2.0, back)
	Kit.bench(g, Vector3(0, 0, 9.0), PI)
	area["spots"]["seat"] = _at(g, Vector3(0, 0, 9.0))
	return area


## Proposition I.47 laid out in tiles on a terrace: the right triangle of 3, 4 and 5 with its three
## squares, so that you can walk the two small squares and the big one and count them: 9 + 16 = 25.
## Returns, besides the usual, "squares": the tiles of each square, by its side.
static func prop_forty_seven(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(24.0, 0.04, 22.0), "limestone", false)
	var tiles := Greek.tiled_squares(g, Vector3(-1.5, 0, 1.0), 0.0, 1.5, whole)
	area["squares"] = tiles["squares"]
	for x: float in [-11.0, 11.0]:
		area["sway"].append(Greek.date_palm(g, Vector3(x, 0, -9.0), 7.5, back.has("leaves")))
	area["spots"]["teacher"] = _at(g, Vector3(-4.0, 0, 3.0))
	area["spots"]["stones"] = _arc(g, Vector3(0, 0, 0), 10.0, 6, 150.0, 390.0)
	area["spots"]["facts"] = [_at(g, Vector3(-10.0, 0, 8.0)), _at(g, Vector3(-7.0, 0, 9.5))]
	_book(area, g, Vector3(9.0, 0, 8.0), -PI / 2.0, back)
	Kit.bench(g, Vector3(5.0, 0, 9.0), PI)
	area["spots"]["seat"] = _at(g, Vector3(5.0, 0, 9.0))
	return area


# ---------- shared by the later areas ----------

## A named person of the area (People.figure), a pale shade while `need` is not back. Adds them
## to the area's people.
static func _person(area: Dictionary, g: Node3D, at: Vector3, face: Vector3, who: String, back: Array,
		need: String = "household", pose: String = "", robe: String = "") -> Dictionary:
	var w := People.figure(g, at, Kit.face_yaw(at, face), who, not back.has(need), pose, robe)
	area["people"].append(w)
	return w


## A band of Homer's Achaeans in rows and files, shaped like kit.gd's squad so the Hall can march
## it; the dead ones while the soldiers are not back. Adds it to the area's squads.
static func _host(area: Dictionary, g: Node3D, at: Vector3, rows: int, files: int, back: Array) -> Dictionary:
	var undead := not back.has("soldiers")
	var root := Kit.group(g, at)
	var legs: Array = []
	for r in rows:
		for f in files:
			legs.append_array(Greek.achaean(root, Vector3((f - (files - 1) / 2.0) * 1.0, 0, -r * 1.1), undead))
	var sq := {"root": root, "legs": legs, "leg": 0, "speed": 0.8 if undead else 1.1, "step": 0.0, "undead": undead}
	area["squads"].append(sq)
	return sq


## A playable moment of Homer: where it happens and whose eyes it is seen through.
static func _beat(area: Dictionary, g: Node3D, name: String, local: Vector3, hero: String) -> void:
	if not area.has("beats"):
		area["beats"] = {}
	area["beats"][name] = {"at": _at(g, local), "hero": hero}


## The usual closing spots of an area: the stones round `centre`, the facts, the book, the seat.
static func _spots(area: Dictionary, g: Node3D, back: Array, teacher: Vector3, stones_at: Vector3, stones_r: float,
		facts: Array, book: Vector3, book_yaw: float, seat: Vector3, seat_yaw: float) -> Dictionary:
	area["spots"]["teacher"] = _at(g, teacher)
	area["spots"]["stones"] = _arc(g, stones_at, stones_r, 6, 0.0, 360.0)
	area["spots"]["facts"] = facts.map(func(p: Vector3) -> Vector3: return _at(g, p))
	_book(area, g, book, book_yaw, back)
	Kit.bench(g, seat, seat_yaw)
	area["spots"]["seat"] = _at(g, seat)
	return area


# ---------- e2: Homer ----------

## The camp by the ships (Iliad 1): the black ships drawn up on the beach in a line, the huts,
## the place of assembly where Achilles and Agamemnon quarrel, the army standing round. Beats:
## the quarrel, Athena seizing Achilles by his yellow hair, Briseis led away.
static func ships(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(70.0, 0.04, 40.0), "sand", false)
	for k in 5:  # the ships, sterns to the land (+Z), bows to the sea
		Greek.ship(g, Vector3(-24.0 + k * 12.0, 0, -14.0), PI, "pentekonter", false, false, whole)
	for x: float in [-16.0, 16.0]:
		Props.achaean_hut(g, Vector3(x, 0, 14.0), PI, whole, back.has("lamps"))
	Kit.cylinder(g, Vector3(0, -0.01, 2.0), 9.0, 0.05, "path", false, 14)  # the place of assembly
	Kit.box(g, Vector3(0, 0.4, -4.5), Vector3(1.2, 0.8, 1.0), "stone")  # Agamemnon's seat
	_person(area, g, Vector3(0, 0, -3.5), Vector3(0, 0, 2.0), "agamemnon", back)
	_person(area, g, Vector3(1.2, 0, 3.6), Vector3(0, 0, 0), "athena", back, "teacher")
	_person(area, g, Vector3(-12.0, 0, 8.0), Vector3(-16.0, 0, 14.0), "briseis", back)
	for side: float in [-1.0, 1.0]:
		_host(area, g, Vector3(side * 10.0, 0, 2.0), 2, 4, back)
	_beat(area, g, "the_quarrel", Vector3(0, 0, 3.0), "achilles")
	_beat(area, g, "athena_seizes_hair", Vector3(0.4, 0, 3.4), "achilles")
	_beat(area, g, "briseis_led_away", Vector3(-15.0, 0, 9.0), "achilles")
	return _spots(area, g, back, Vector3(2.0, 0, 5.0), Vector3(0, 0, 2.0), 7.0,
		[Vector3(24.0, 0, 6.0), Vector3(24.0, 0, 9.0), Vector3(24.0, 0, 12.0)], Vector3(22.0, 0, 16.0), -PI / 2.0,
		Vector3(28.0, 0, 0.0), PI)


## The Scaean Gate (Iliad 6): the walls of Troy with the gate open, the old oak outside it, and
## Andromache running to meet Hector with their son in the nurse's arms. Beat: Hector takes off the
## helmet that frightened the child.
static func scaean_gate(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 8.0), Vector3(60.0, 0.04, 30.0), "grass" if back.has("leaves") else "ashbed", false)
	Greek.troy_wall(g, Vector3(0, 0, -6.0), 0.0, 50.0, true, whole)
	area["sway"].append(Kit.plane_tree(g, Vector3(7.0, 0, 2.0), 1.2, back.has("leaves")))  # the oak by the gate
	_person(area, g, Vector3(-1.0, 0, 1.0), Vector3(0, 0, -2.0), "andromache", back)
	_beat(area, g, "helmet_off", Vector3(0.2, 0, 2.5), "hector")
	return _spots(area, g, back, Vector3(-3.0, 0, 5.0), Vector3(0, 0, 8.0), 6.0,
		[Vector3(-18.0, 0, 4.0), Vector3(-18.0, 0, 7.0)], Vector3(15.0, 0, 8.0), -PI / 2.0, Vector3(10.0, 0, 14.0), PI)


## Achilles' hut (Iliad 9 and 24): the lodge and its fenced courtyard, the envoys at the door
## (Odysseus, old Phoenix, Ajax), and outside the gate the wagon with Priam's ransom and Hermes who
## led him through the camp. Beats: the embassy refused, and Priam kneeling to kiss the hands that
## killed his son.
static func achilles_hut(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(40.0, 0.04, 36.0), "sand", false)
	var hut := Props.achaean_hut(g, Vector3(0, 0, -2.0), 0.0, whole, back.has("lamps"))
	if hut["hearth"]:
		area["flicker"].append(hut["hearth"])
	Kit.lyre(g, Vector3(2.6, 0.75, -6.2), 0.0)  # the lyre he sang to
	for k in 3:
		_person(area, g, Vector3(-1.5 + k * 1.5, 0, -1.8), Vector3(2.6, 0, -6.5), ["odysseus", "phoenix", "ajax"][k], back)
	Props.chariot(g, Vector3(-5.0, 0, 9.0), PI, 2, whole)  # the wagon of the ransom
	Kit.box(g, Vector3(-5.0, 1.0, 9.0), Vector3(0.9, 0.5, 0.6), "wood", false)  # the chest on it
	_person(area, g, Vector3(-3.0, 0, 7.0), Vector3(0, 0, 3.0), "hermes", back, "teacher")
	_beat(area, g, "embassy", Vector3(2.6, 0, -5.5), "achilles")
	_beat(area, g, "kneel", Vector3(1.8, 0, -5.0), "priam")
	_beat(area, g, "through_the_camp", Vector3(-4.0, 0, 12.0), "priam")
	return _spots(area, g, back, Vector3(2.0, 0, 2.0), Vector3(0, 0, 10.0), 8.0,
		[Vector3(14.0, 0, 6.0), Vector3(14.0, 0, 9.0)], Vector3(12.0, 0, -8.0), -PI / 2.0, Vector3(10.0, 0, 14.0), PI)


## Hephaestus's house of bronze (Iliad 18): the god's forge, Thetis waiting, and laid out on the
## floor, large enough to walk, the shield he makes for her son. Beat: the armour given to
## Achilles.
static func forge(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(40.0, 0.04, 40.0), "bronze" if back.has("walkway") else "verdigris", false)
	var fire := Props.forge(g, Vector3(0, 0, -12.0), 0.0, back.has("lamps"))
	if fire:
		area["flicker"].append(fire)
	area["rings"] = Props.shield_of_achilles(g, Vector3(0, 0, 4.0), 0.0, 12.0, back.has("sun"))
	_person(area, g, Vector3(-6.0, 0, -9.0), Vector3(0, 0, -12.0), "thetis", back)
	_beat(area, g, "the_armour", Vector3(0, 0, 4.0), "achilles")
	return _spots(area, g, back, Vector3(3.0, 0, -8.0), Vector3(0, 0, 4.0), 14.5,
		[Vector3(-16.0, 0, -14.0), Vector3(-13.0, 0, -15.0)], Vector3(14.0, 0, -12.0), -PI / 2.0, Vector3(16.0, 0, -6.0), -PI / 2.0)


## Before the walls (Iliad 22): the long wall of Troy with its gate, the two springs outside it
## where the women washed in peacetime, one warm and one cold, the old king and queen on the wall,
## and the wagon road that runs round the city. Returns, besides the usual, "circuit": the way
## round the walls that Hector ran three times. Beats: the chase, and Hector standing at last.
static func walls(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 10.0), Vector3(90.0, 0.04, 40.0), "grass" if back.has("leaves") else "ashbed", false)
	Greek.troy_wall(g, Vector3(0, 0, -8.0), 0.0, 80.0, true, whole)
	Kit.box(g, Vector3(0, 0.03, 0.0), Vector3(80.0, 0.04, 3.0), "path", false)  # the wagon road under the wall
	for x: float in [20.0, 24.0]:  # the springs, the warm one smoking
		Kit.cylinder(g, Vector3(x, 0, 3.0), 1.4, 0.4, "stone", true, 9)
		Kit.cylinder(g, Vector3(x, 0.38, 3.0), 1.1, 0.05, "water" if back.has("water") else "drybed", false, 9)
	if back.has("water"):
		var steam := Kit._drift(g, Vector3(20.0, 0.5, 3.0), 6, 4.0, 0.8, "smoke", Vector3.UP, 10.0, Vector2(0.3, 0.6))
		steam.scale_amount_max = 1.5
	for k in 2:  # Priam and Hecuba watching from the wall
		_person(area, g, Vector3(-3.0 + k * 1.5, 9.2, -8.4), Vector3(-3.0 + k * 1.5, 9.2, 10.0), ["priam", "andromache"][k], back)
	area["circuit"] = [Vector3(-38, 0, 2), Vector3(38, 0, 2), Vector3(38, 0, -30), Vector3(-38, 0, -30)].map(
		func(p: Vector3) -> Vector3: return _at(g, p))
	_beat(area, g, "three_times_round", Vector3(-30.0, 0, 2.0), "achilles")
	_beat(area, g, "hector_stands", Vector3(22.0, 0, 6.0), "achilles")
	return _spots(area, g, back, Vector3(-4.0, 0, 8.0), Vector3(-10.0, 0, 16.0), 6.0,
		[Vector3(34.0, 0, 16.0), Vector3(34.0, 0, 19.0)], Vector3(30.0, 0, 22.0), -PI / 2.0, Vector3(8.0, 0, 20.0), PI)


## Odysseus's hall on Ithaca (Odyssey 1, 19, 21-23): the great hall with its hearth and four
## pillars, the suitors feasting on couches, the axes set up for the contest of the bow, the old
## nurse with her basin by the fire, Penelope's loom in the women's room, and the bedroom built
## round the living olive. Beats: Athena at the door (Telemachus), the scar (Odysseus), the bow,
## the bed.
static func ithaca_hall(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	const W := 16.0
	const D := 22.0
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(W, 0.04, D), "paving", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * (W / 2.0 + 0.2), 2.5, 0), Vector3(0.4, 5.0, D), "plaster")
	Kit.box(g, Vector3(0, 2.5, -D / 2.0 - 0.2), Vector3(W, 5.0, 0.4), "plaster")
	for side: float in [-1.0, 1.0]:  # the front, with the great door
		Kit.box(g, Vector3(side * (W / 4.0 + 0.9), 2.5, D / 2.0 + 0.2), Vector3(W / 2.0 - 1.8, 5.0, 0.4), "plaster")
	if whole:
		Kit.box(g, Vector3(0, 5.2, 0), Vector3(W + 1.0, 0.4, D + 1.0), "wood", false)  # the roof beams
	for p: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		Kit.cylinder(g, p, 0.3, 5.0, "wood" if whole else "deadwood", true, 8, 0.36)  # the pillars, painted red on the site
	var fire := Kit.hearth(g, Vector3(0, 0, 0), back.has("lamps"))
	if fire:
		area["flicker"].append(fire)
	for k in 6:  # the suitors on their couches down both sides
		var side := -1.0 if k % 2 == 0 else 1.0
		var z := -6.0 + (k / 2) * 5.0
		Greek.kline(g, Vector3(side * 6.0, 0, z), side * -PI / 2.0 + PI, whole)
		_person(area, g, Vector3(side * 5.2, 0, z + 1.0), Vector3(0, 0, z), "suitor", back, "household", "", ["7a5a2a", "5a3a4a", "3a5a4a"][k % 3])
	area["archer"] = Props.bow_and_axes(g, Vector3(4.0, 0, -8.0), PI, whole)
	_person(area, g, Vector3(-1.8, 0, 1.5), Vector3(0, 0, 0), "eurycleia", back)
	Kit.cylinder(g, Vector3(-1.2, 0, 1.2), 0.35, 0.25, "bronze" if whole else "verdigris", false, 10, 0.4)  # her basin
	Greek.loom(g, Vector3(-W / 2.0 + 1.0, 0, -D / 2.0 + 1.0), PI / 2.0, 0.6, "#e8e0d0", whole)
	_person(area, g, Vector3(-W / 2.0 + 2.5, 0, -D / 2.0 + 2.0), Vector3(-W / 2.0 + 1.0, 0, -D / 2.0 + 1.0), "penelope", back)
	area["sway"].append(Props.olive_bed(g, Vector3(W / 2.0 - 2.0, 0, -D / 2.0 + 2.0), PI, back.has("leaves")))
	_person(area, g, Vector3(0.8, 0, D / 2.0 - 0.8), Vector3(0, 0, 0), "athena", back, "teacher")
	_beat(area, g, "athena_at_the_door", Vector3(0, 0, D / 2.0 - 2.5), "telemachus")
	_beat(area, g, "the_scar", Vector3(-1.2, 0, 0.4), "odysseus")
	_beat(area, g, "string_the_bow", Vector3(5.5, 0, -8.0), "odysseus")
	_beat(area, g, "the_bed", Vector3(W / 2.0 - 3.0, 0, -D / 2.0 + 3.5), "odysseus")
	return _spots(area, g, back, Vector3(2.0, 0, 5.0), Vector3(0, 0, 0), 4.5,
		[Vector3(-W / 2.0 + 0.8, 0, 6.0), Vector3(-W / 2.0 + 0.8, 0, 9.0)], Vector3(W / 2.0 - 1.5, 0, 8.0), -PI / 2.0,
		Vector3(-5.0, 0, 9.5), PI / 2.0)


## The Cyclops' cave (Odyssey 9), a place of horror: a vast dark cave of the giant's flocks, pens
## of lambs and kids, racks of cheeses and pails of whey, the bones of the men he has eaten by the
## fire, the olive-wood stake hardening in the embers, the mist on the floor, and the one way out
## blocked by a stone that twenty-two wagons could not shift. Returns, besides the usual,
## "cyclops", "stone" (the door stone, for the Hall to roll) and "rams". Beats: the stake, the
## blinding, "Nobody", and out under the ram.
static func cyclops_cave(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	const R := 18.0
	Kit.cylinder(g, Vector3(0, -0.05, 0), R, 0.1, "cave", false, 14)
	var n := 20
	for k in n:  # the cave's walls, closing overhead
		var a := TAU * k / n
		if absf(a - PI / 2.0) < 0.2:
			continue  # the mouth (+Z)
		var wall := Kit.group(g, Vector3(cos(a), 0, sin(a)) * R, -a + PI / 2.0)
		Kit.box(wall, Vector3(0, 7.0, 0), Vector3(2.0 * PI * R / n + 0.4, 14.0, 2.0), "cave")
	Kit.cylinder(g, Vector3(0, 13.0, 0), R + 1.0, 2.0, "cave", false, 14, R * 0.4)  # the roof
	var stone := Kit.group(g, Vector3(0, 0, R + 0.5))  # the door stone, rolled across the mouth
	Kit.blob(stone, Vector3(0, 3.0, 0), 3.4, "rock", Vector3(1.0, 1.0, 0.6), 8)
	var door := BoxShape3D.new()
	door.size = Vector3(6.5, 6.0, 3.0)
	Kit.solid(stone, door, Vector3(0, 3.0, 0))
	area["stone"] = stone
	var fire := Kit.hearth(g, Vector3(-3.0, 0, -4.0), back.has("lamps"))
	if fire:
		area["flicker"].append(fire)
	Kit.mesh(g, Kit._cyl(0.15, 4.0), "#6a3a1a" if back.has("lamps") else "deadwood", Vector3(-2.2, 0.35, -4.2),
		Vector3(0.1, 0.4, PI / 2.0))  # the stake in the embers
	for k in 5:  # the bones of his supper
		Kit.mesh(g, Kit._cyl(0.06, 0.5), "bone", Vector3(-5.0 + k * 0.4, 0.05, -2.0 + (k % 2) * 0.5), Vector3(PI / 2.0, k * 0.9, 0))
	Kit.blob(g, Vector3(-4.2, 0.12, -1.6), 0.13, "bone")
	for k in 2:  # the pens, fenced with stones
		var c := Vector3(8.0, 0, -6.0 + k * 7.0)
		for j in 10:
			var a := TAU * j / 10.0
			Kit.box(g, c + Vector3(cos(a), 0, sin(a)) * 2.5 + Vector3(0, 0.35, 0), Vector3(1.2, 0.7, 0.6), "rock", true, Vector3(0, -a, 0))
		for j in 3:
			Greek.beast(g, c + Vector3(-0.8 + j * 0.8, 0, 0), j * 0.8, "sheep", "", 0.6, back.has("household"))  # lambs
	for k in 4:  # racks of cheeses and the pails of whey
		Kit.box(g, Vector3(-10.0, 1.0 + k * 0.5, 6.0), Vector3(3.0, 0.06, 0.8), "wood", false)
		for j in 4:
			Kit.cylinder(g, Vector3(-11.2 + j * 0.8, 1.03 + k * 0.5, 6.0), 0.25, 0.18, "#e8dcb0", false, 8)
	for j in 3:
		Kit.cylinder(g, Vector3(-6.0 + j * 0.9, 0, 8.0), 0.3, 0.5, "wood", false, 8, 0.35)
	var rams: Array = []
	for k in 6:  # the flock, the great ram among them
		rams.append(Greek.beast(g, Vector3(2.0 + (k % 3) * 1.8, 0, 6.0 + (k / 3) * 2.0), PI + 0.2 * k, "sheep", "",
			1.4 if k == 0 else 1.1, back.has("household")))
	area["rams"] = rams
	area["cyclops"] = People.cyclops(g, Vector3(0, 0, -9.0), 0.0, false, back.has("teacher"))
	Props.ground_fog(g, Vector3.ZERO, R * 1.6)
	_beat(area, g, "the_stake", Vector3(-2.0, 0, -2.5), "odysseus")
	_beat(area, g, "blind_him", Vector3(0, 0, -6.0), "odysseus")
	_beat(area, g, "nobody", Vector3(0, 0, R - 3.0), "odysseus")
	_beat(area, g, "under_the_ram", Vector3(2.0, 0, 6.0), "odysseus_bound")
	return _spots(area, g, back, Vector3(4.0, 0, 2.0), Vector3(0, 0, 2.0), 8.0,
		[Vector3(12.0, 0, 8.0), Vector3(10.0, 0, 11.0)], Vector3(-12.0, 0, -6.0), PI / 2.0, Vector3(-9.0, 0, 10.0), PI)


## The underworld at the edge of Ocean (Odyssey 11), the game's place of horror: a sunless shore
## walled in by black cliffs, the black ship drawn up, the trench of blood in the middle, a pale
## meadow of asphodel beyond, mist on the ground, and the dead crowding in out of the dark:
## Elpenor unburied, Odysseus's mother, blind Teiresias, Achilles. Returns, besides the usual,
## "shades": [{node, home, trench}] (the Hall edges each toward the trench while the sword is
## lowered) and "trench". Beats: holding the dead back with the sword, the mother who cannot be
## held, Teiresias drinking.
static func underworld(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	const R := 26.0
	Kit.cylinder(g, Vector3(0, -0.05, 0), R, 0.1, "ashbed", false, 16)
	Kit.cylinder(g, Vector3(0, -0.03, -12.0), 11.0, 0.08, "grass" if back.has("leaves") else "drybed", false, 14)  # the asphodel
	if back.has("leaves"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for k in 40:
			var a := rng.randf() * TAU
			var r := rng.randf() * 10.0
			Kit.cylinder(g, Vector3(cos(a) * r, 0, -12.0 + sin(a) * r), 0.02, 0.6, "#8a9a7a", false, 4)
			Kit.blob(g, Vector3(cos(a) * r, 0.65, -12.0 + sin(a) * r), 0.07, "#e8e4dc")
	for k in 24:  # the black cliffs round it all, and the dark overhead
		var a := TAU * k / 24.0
		if absf(a - PI / 2.0) < 0.25:
			continue  # the way from the shore
		var cliff := Kit.group(g, Vector3(cos(a), 0, sin(a)) * R, -a + PI / 2.0)
		Kit.box(cliff, Vector3(0, 12.0, 0), Vector3(2.0 * PI * R / 24.0 + 0.5, 24.0, 3.0), "cave")
	Kit.cylinder(g, Vector3(0, 24.0, 0), R + 2.0, 1.0, "dark", false, 16)
	Greek.ship(g, Vector3(0, 0, R + 10.0), PI, "pentekonter", false, false, back.has("walkway"))
	area["trench"] = Props.blood_trench(g, Vector3(0, 0, 4.0), 0.0, back.has("water"))
	Props.ground_fog(g, Vector3(0, 0, 0), R * 1.8)
	var shades: Array = []
	var named := {"elpenor": Vector3(-4.0, 0, 12.0), "anticleia": Vector3(3.0, 0, -2.0), "teiresias": Vector3(0, 0, -6.0),
		"achilles_shade": Vector3(-6.0, 0, -8.0)}
	for who in named:
		var w := _person(area, g, named[who], Vector3(0, 0, 4.0), who, back, "teacher")
		shades.append({"node": w["root"], "home": _at(g, named[who]), "trench": area["trench"], "who": who})
	for k in 16:  # the nameless dead
		var a := TAU * k / 16.0 + 0.2
		var home := Vector3(cos(a) * 12.0, 0, 4.0 + sin(a) * 10.0)
		var w := Kit.walker(g, home, Kit.face_yaw(home, Vector3(0, 0, 4.0)), {"robe": "4a4a50", "skin": "a8a4a0", "hair_color": "5a5a5a"})
		Kit.shade(w["root"], 0.22 if back.has("household") else 0.14)
		w["shade"] = true
		area["people"].append(w)
		shades.append({"node": w["root"], "home": _at(g, home), "trench": area["trench"], "who": ""})
	area["shades"] = shades
	_beat(area, g, "hold_the_sword", Vector3(0, 0, 6.0), "odysseus")
	_beat(area, g, "mother", Vector3(2.0, 0, 1.0), "odysseus")
	_beat(area, g, "teiresias_drinks", Vector3(0, 0, 5.5), "odysseus")
	return _spots(area, g, back, Vector3(1.5, 0, 8.0), Vector3(0, 0, 4.0), 18.0,
		[Vector3(-6.0, 0, R - 4.0), Vector3(6.0, 0, R - 4.0)], Vector3(9.0, 0, R - 5.0), PI, Vector3(-9.0, 0, R - 6.0), PI)


## The Sirens (Odyssey 12): the black ship under sail passing their island, the crew rowing with
## wax in their ears, and Odysseus bound upright to the mast. Returns, besides the usual, "ship"
## (its oars, for the Hall to row), "sirens" and "mast" (where the bound hero stands). The area
## is on the water: the place provides the sea. Beat: tied to the mast.
static func sirens(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var ship := Greek.ship(g, Vector3(0, -1.2, 0), 0.0, "pentekonter", back.has("walkway"), true, back.has("walkway"))
	area["ship"] = ship
	area["sirens"] = Props.sirens_rock(g, Vector3(-40.0, -1.0, 10.0), PI / 2.0, back.has("teacher"))
	for k in 6:  # the rowers, their ears stopped with wax
		var side := -1.0 if k % 2 == 0 else 1.0
		var w := Kit.walker(g, Vector3(side * 1.0, 0.45 - 1.2, -6.0 + (k / 2) * 4.0), PI, {"robe": "6a5a4a", "hair_color": "3a2a1e"})
		if not back.has("household"):
			Kit.shade(w["root"], 0.3)
			w["shade"] = true
		area["people"].append(w)
	var mast := Vector3(0, 0.3, 1.2)
	area["mast"] = _at(g, mast)
	_beat(area, g, "tied_to_the_mast", mast, "odysseus_bound")
	area["spots"]["teacher"] = _at(g, Vector3(0, 0.3, 8.0))
	area["spots"]["stones"] = _arc(g, Vector3(0, 0.3, 0), 1.2, 6, 0.0, 360.0)
	area["spots"]["facts"] = [_at(g, Vector3(0, 0.3, -9.0)), _at(g, Vector3(0, 0.3, 9.5))]
	area["spots"]["book"] = _at(g, Vector3(0, 0.3, -7.0))
	area["spots"]["seat"] = _at(g, Vector3(0, 0.3, -8.0))
	return area


# ---------- e2: Hesiod ----------

## Mount Helicon, where the Muses found the shepherd Hesiod and gave him a laurel staff and a voice
## (Theogony 1-115): a high meadow with its flock, the Horse's Spring, the nine Muses dancing
## round it, a laurel; and at the meadow's edge the gap of Chaos, where everything began, with
## Kronos in stone, sickle in hand, and the swaddled stone he swallowed in place of Zeus.
static func helicon(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	Kit.cylinder(g, Vector3(0, -3.0, 0), 30.0, 3.0, "grass" if back.has("leaves") else "ashbed", true, 16, 22.0)
	var top := Vector3(0, 0, 0)
	Props.hippocrene(g, top, back.has("water"))
	var robes := ["8a2a2a", "2a4a7a", "d8cfa8", "4a6a3a", "6a3a6a", "b8863a", "3a5a6a", "8a6a4a", "e0d8c4"]
	for k in 9:  # the nine Muses, dancing in a ring round the spring
		var a := TAU * k / 9.0
		_person(area, g, top + Vector3(cos(a), 0, sin(a)) * 4.0, top, "muse", back, "household", "", robes[k])
	area["sway"].append(Kit.olive(g, Vector3(6.0, 0, -4.0), 1.3, back.has("leaves")))  # the laurel
	for k in 7:  # the flock
		Greek.beast(g, Vector3(-9.0 + (k % 4) * 1.4, 0, 6.0 + (k / 4) * 1.6), k * 0.9, "sheep" if k % 3 else "goat", "", 1.0,
			back.has("household"))
	Kit.cylinder(g, Vector3(0, -2.0, -19.0), 5.0, 2.05, "dark", false, 12)  # the gap of Chaos
	var kronos := People.figure(g, Vector3(-9.0, 0, -15.0), 0.4, "kronos")
	for mi in kronos["root"].find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = Kit.Tex.material("stone")
	Kit.box(g, Vector3(-5.0, 0.5, -15.0), Vector3(1.0, 1.0, 1.0), "stone")
	Kit.blob(g, Vector3(-5.0, 1.35, -15.0), 0.4, "rock", Vector3(0.8, 1.2, 0.8), 6)  # the stone in swaddling clothes
	Kit.box(g, Vector3(-5.0, 1.35, -15.0), Vector3(0.7, 0.2, 0.5), "#d8d0b8", false)
	return _spots(area, g, back, Vector3(2.0, 0, 6.0), Vector3(0, 0, 0), 9.0,
		[Vector3(12.0, 0, 6.0), Vector3(12.0, 0, 9.0)], Vector3(-6.0, 0, 12.0), PI, Vector3(8.0, 0, 12.0), PI)


## A farm at Ascra in Boeotia (Works and Days): the plough team in a ploughed field, the
## threshing floor, the hives, the farmhouse, olives, Pandora's jar standing open with only Hope
## left inside, the five ages carved on the farmyard wall, and on a far crag Prometheus in chains.
static func farm(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var alive := back.has("leaves")
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(60.0, 0.04, 50.0), "earth" if alive else "ashbed", false)
	Greek.field(g, Vector3(-14.0, 0, -8.0), Vector2(20.0, 16.0), 0.0, alive)
	Greek.plough_team(g, Vector3(-14.0, 0, -8.0), PI / 2.0, back.has("household"))
	Greek.threshing_floor(g, Vector3(12.0, 0, -8.0), 5.0, whole)
	Greek.hives(g, Vector3(18.0, 0, 6.0), -PI / 2.0, 5, whole)
	var house := Props.achaean_hut(g, Vector3(0, 0, -14.0), 0.0, whole, back.has("lamps"))
	if house["hearth"]:
		area["flicker"].append(house["hearth"])
	for p: Vector3 in [Vector3(-24, 0, 12), Vector3(-18, 0, 16), Vector3(20, 0, 16)]:
		area["sway"].append(Kit.olive(g, p, 1.2, alive))
	Props.pithos(g, Vector3(4.0, 0, 4.0), true, whole)
	area["ages"] = Props.ages_frieze(g, Vector3(8.0, 0, 12.0), PI, whole)
	Props.prometheus_rock(g, Vector3(-30.0, 0, -40.0), 0.6, back.has("sun"))
	return _spots(area, g, back, Vector3(0, 0, 4.0), Vector3(0, 0, 6.0), 7.0,
		[Vector3(-4.0, 0, 16.0), Vector3(-1.0, 0, 17.0)], Vector3(4.0, 0, 8.0), PI, Vector3(-6.0, 0, 10.0), PI)


# ---------- e2: Sappho ----------

## Sappho's garden on Lesbos, above the sea (fragments 1, 2, 16, 31): an orchard of apples round
## Aphrodite's shrine, cold water murmuring through the branches, the goddess's sparrow chariot
## coming down the sky, two seats set facing each other (the man who sits opposite you), a
## barbitos left on a bench, and far out on the sea the ships some say are the loveliest thing on
## the black earth.
static func garden(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var alive := back.has("leaves")
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(40.0, 0.04, 36.0), "grass" if alive else "ashbed", false)
	Props.shrine(g, Vector3(0, 0, -12.0), 0.0, "aphrodite", whole)
	var light := Greek.altar(g, Vector3(0, 0, -4.5), PI, "greek", back.has("lamps"), whole)  # frankincense on the altar
	if light:
		area["flicker"].append(light)
	for k in 10:  # the orchard
		var a := TAU * k / 10.0 + 0.3
		area["sway"].append(Props.apple_tree(g, Vector3(cos(a) * 13.0, 0, sin(a) * 11.0), 1.0 + fmod(k * 0.37, 0.3), alive))
	Kit.stream(g, Vector3(-16.0, 0, -6.0), Vector3(-6.0, 0, 14.0), 1.0, back.has("water"))
	area["sparrows"] = Props.sparrow_chariot(g, Vector3(3.0, 7.0, -6.0), PI, back.has("sun"))
	for side: float in [-1.0, 1.0]:  # the two seats, facing
		Kit.bench(g, Vector3(side * 1.5, 0, 6.0), -side * PI / 2.0)
	Greek.barbitos(g, Vector3(8.0, 0.5, 8.0), 0.3, whole)
	for k in 3:  # the fleet far out on the sea
		Greek.ship(g, Vector3(-40.0 + k * 30.0, -10.0, 160.0), PI / 2.0, "trireme", true, true, back.has("soldiers"))
	return _spots(area, g, back, Vector3(0, 0, 3.0), Vector3(0, 0, -2.0), 6.5,
		[Vector3(-8.0, 0, 14.0), Vector3(-5.0, 0, 15.0)], Vector3(8.0, 0, 12.0), PI, Vector3(0, 0, 14.0), PI)


# ---------- e3: Aeschylus ----------

## Argos, the house of Atreus (Agamemnon): the palace front with the watchman on its roof, the
## beacon blazing on the far height, the chariot come home from Troy with Cassandra in it, the
## crimson tapestries spread from the chariot to the door, Clytemnestra waiting on the step, and
## inside, the bath with its net.
static func argos_palace(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(50.0, 0.04, 30.0), "paving" if whole else "ashbed", false)
	var palace := Props.palace_front(g, Vector3(0, 0, -6.0), 0.0, whole)
	_person(area, g, palace["roof"], Vector3(30.0, 8.0, 60.0), "watchman", back)
	var fire := Props.beacon(g, Vector3(30.0, 10.0, 70.0), back.has("lamps"))
	if fire:
		area["flicker"].append(fire)
	Kit.cylinder(g, Vector3(30.0, -20.0, 70.0), 14.0, 30.0, "rock", false, 8, 3.0)  # the height the beacon burns on
	Props.chariot(g, Vector3(0, 0, 14.0), PI, 2, back.has("household"))
	_person(area, g, Vector3(0.3, 0.75, 15.5), Vector3(0, 0, 0), "cassandra", back)
	Props.carpet(g, Vector3(0, 0, 12.0), Vector3(0, 0.62, -3.0), back.has("household"))
	_person(area, g, Vector3(0, 0.6, -3.5), Vector3(0, 0, 14.0), "clytemnestra", back)
	Props.bath(g, Vector3(-6.0, 0.6, -5.0), 0.0, whole)
	return _spots(area, g, back, Vector3(3.0, 0, 6.0), Vector3(0, 0, 6.0), 8.0,
		[Vector3(-18.0, 0, 6.0), Vector3(-18.0, 0, 9.0), Vector3(-18.0, 0, 12.0)], Vector3(16.0, 0, 8.0), -PI / 2.0,
		Vector3(12.0, 0, 16.0), PI)


## The Areopagus in Athens (Eumenides): the bare hill of Ares with its rough seats for the
## judges, Athena presiding, Orestes at the altar, the Furies crouched round him in black, the
## table with the two urns where the votes fall even.
static func areopagus(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.cylinder(g, Vector3(0, -2.0, 0), 22.0, 2.0, "rock", true, 12, 18.0)
	var seats := _ring(Vector3(0, 0, -2.0), 9.0, 12, 200.0, 340.0)
	for k in seats.size():  # the judges' seats cut in the rock, and the judges on them
		var p: Vector3 = seats[k]
		Kit.box(g, p + Vector3(0, 0.25, 0), Vector3(1.0, 0.5, 0.8), "rock", true, Vector3(0, Kit.face_yaw(p, Vector3.ZERO), 0))
		_folk(area, g, p + Vector3(0, 0, 0.6), Vector3(0, 0, 0), {"robe": "e0d6c0", "hair_color": "8a8278", "beard": "long"}, back)
	_person(area, g, Vector3(0, 0, -6.0), Vector3(0, 0, 3.0), "athena", back, "teacher")
	area["urns"] = Props.voting_urns(g, Vector3(0, 0, -3.5), 0.0, whole)
	Greek.altar(g, Vector3(0, 0, 3.0), 0.0, "greek", back.has("lamps"), whole)
	_person(area, g, Vector3(0, 0, 4.4), Vector3(0, 0, -6.0), "orestes", back)
	for k in 5:  # the Furies, crouched round him
		var a := PI * 0.2 + k * PI * 0.15
		var p := Vector3(cos(a) * 3.0, 0, 4.0 + sin(a) * 3.0)
		var f := _person(area, g, p, Vector3(0, 0, 4.4), "fury", back, "soldiers")
		(f["root"] as Node3D).rotation.x = 0.4
	return _spots(area, g, back, Vector3(-2.0, 0, 0.0), Vector3(0, 0, 0), 5.5,
		[Vector3(-14.0, 0, 6.0), Vector3(-12.0, 0, 9.0)], Vector3(12.0, 0, 6.0), -PI / 2.0, Vector3(10.0, 0, 11.0), PI)


# ---------- e3: Sophocles ----------

## The gate of Thebes in the plague (Oedipus the King): the palace front, the city's altar heaped
## with suppliants' branches, the plague's dead laid out and burning on pyres, and on her column
## the Sphinx whose riddle Oedipus answered.
static func thebes_gate(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(50.0, 0.04, 30.0), "paving" if whole else "ashbed", false)
	Props.palace_front(g, Vector3(0, 0, -6.0), 0.0, whole)
	var light := Greek.altar(g, Vector3(0, 0, 4.0), PI, "greek", back.has("lamps"), whole)
	if light:
		area["flicker"].append(light)
	for k in 6:  # the suppliants' olive branches wound with wool, laid on the altar steps
		Kit.box(g, Vector3(-1.0 + k * 0.4, 0.25, 4.8), Vector3(0.05, 0.05, 0.9), "olive", false, Vector3(0, 0.3 * k, 0))
	for k in 3:
		var fire := Props.pyre(g, Vector3(14.0 + k * 3.0, 0, 12.0), 0.3 * k, back.has("lamps"))
		if fire:
			area["flicker"].append(fire)
	for k in 4:  # the dead of the plague, laid in the street
		Kit.blob(g, Vector3(-14.0 + k * 1.2, 0.2, 12.0), 0.2, "#8a8274", Vector3(1.2, 0.7, 4.0), 6)
	area["sphinx"] = People.sphinx(g, Vector3(-18.0, 0, -2.0), 0.6, back.has("teacher"))
	_person(area, g, Vector3(1.5, 0.6, -3.0), Vector3(0, 0, 8.0), "oedipus", back)
	_person(area, g, Vector3(-1.5, 0.6, -3.2), Vector3(0, 0, 8.0), "jocasta", back)
	_person(area, g, Vector3(4.0, 0, 8.0), Vector3(1.5, 0, -3.0), "teiresias", back)
	return _spots(area, g, back, Vector3(3.0, 0, 8.0), Vector3(0, 0, 8.0), 7.0,
		[Vector3(20.0, 0, 2.0), Vector3(20.0, 0, 5.0)], Vector3(-12.0, 0, 18.0), PI, Vector3(10.0, 0, 18.0), PI)


## The place where three roads meet, in Phocis (Oedipus the King 716-813): a narrow way between
## mountains splitting three ways at a lonely crossing, a shrine-stone, the old man's carriage
## overturned in the road.
static func crossroads(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(60.0, 0.04, 60.0), "earth" if back.has("leaves") else "ashbed", false)
	for k in 3:  # the three roads
		var a := TAU * k / 3.0 + PI / 2.0
		Kit.box(g, Vector3(cos(a), 0, sin(a)) * 14.0 + Vector3(0, 0.03, 0), Vector3(2.5, 0.04, 28.0), "path", false,
			Vector3(0, -a + PI / 2.0, 0))
		var hill := Vector3(cos(a + PI / 3.0), 0, sin(a + PI / 3.0)) * 24.0
		Kit.hill(g, hill, 13.0, 12.0, "rock")  # the mountains between
	Kit.box(g, Vector3(0, 0.8, 0), Vector3(0.6, 1.6, 0.6), "stone")  # the shrine-stone at the meeting
	var cart := Kit.group(g, Vector3(3.0, 0.4, 3.0), 0.8)
	cart.rotation.z = 1.4
	Props.chariot(cart, Vector3.ZERO, 0.0, 0, whole)  # overturned
	Greek.beast(g, Vector3(6.0, 0, 6.0), 2.2, "horse", "", 1.0, back.has("household"))
	return _spots(area, g, back, Vector3(-2.0, 0, 2.0), Vector3(0, 0, 0), 6.0,
		[Vector3(-8.0, 0, 10.0), Vector3(-10.0, 0, 8.0)], Vector3(8.0, 0, -8.0), PI / 4.0, Vector3(-6.0, 0, -6.0), PI / 4.0)


## Antigone's tomb (Antigone): outside the walls the body of Polynices left unburied under a thin
## dust she scattered, the guards' post, and in the rock the tomb where Creon walls her up alive.
static func antigone_tomb(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(40.0, 0.04, 30.0), "earth" if back.has("leaves") else "ashbed", false)
	area["door"] = Props.rock_tomb(g, Vector3(0, 0, -8.0), 0.0, whole)
	Kit.blob(g, Vector3(6.0, 0.2, 6.0), 0.22, "#6a5a4a", Vector3(1.2, 0.8, 4.2), 6)  # Polynices
	Kit.box(g, Vector3(6.0, 0.32, 6.0), Vector3(0.8, 0.02, 1.6), "earth", false)  # the thin dust over him
	for k in 2:
		_person(area, g, Vector3(9.0 + k * 1.2, 0, 3.0), Vector3(6.0, 0, 6.0), "watchman", back, "soldiers")
	_person(area, g, Vector3(-1.5, 0, -5.5), Vector3(0, 0, 6.0), "antigone", back)
	_person(area, g, Vector3(-6.0, 0, 4.0), Vector3(0, 0, -6.0), "creon", back)
	return _spots(area, g, back, Vector3(-3.0, 0, 3.0), Vector3(0, 0, 4.0), 6.0,
		[Vector3(-16.0, 0, 8.0), Vector3(-16.0, 0, 11.0)], Vector3(14.0, 0, 14.0), PI, Vector3(-10.0, 0, 16.0), PI)


# ---------- e3: Euripides ----------

## Mount Cithaeron (the Bacchae): a glade under firs where the women of Thebes, maddened by the
## god, dance with their thyrsi and fawnskins, milk and honey welling from the ground, and the tall
## fir bent and let spring up again with Pentheus in its top.
static func cithaeron(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var alive := back.has("leaves")
	Kit.cylinder(g, Vector3(0, -3.0, 0), 28.0, 3.0, "grass" if alive else "ashbed", true, 14, 20.0)
	for k in 9:
		var a := TAU * k / 9.0
		Props.fir_tree(g, Vector3(cos(a), 0, sin(a)) * (14.0 + (k % 3) * 2.0), 10.0 + (k % 3) * 2.0, alive)
	var top := Props.fir_tree(g, Vector3(0, 0, -6.0), 16.0, alive)
	var p := People.figure(top, Vector3(0, -0.8, 0), 0.0, "pentheus", not back.has("household"))
	area["people"].append(p)
	for k in 8:  # the maenads, dancing round
		var a := TAU * k / 8.0
		_person(area, g, Vector3(cos(a) * 5.0, 0, 2.0 + sin(a) * 5.0), Vector3(0, 0, 2.0), "agave" if k == 0 else "maenad", back)
	Kit.cylinder(g, Vector3(3.0, 0.01, 4.0), 0.8, 0.02, "#e8e4dc" if back.has("water") else "drybed", false, 8)  # milk from the earth
	_person(area, g, Vector3(-4.0, 0, 8.0), Vector3(0, 0, 2.0), "dionysus", back, "teacher")
	return _spots(area, g, back, Vector3(-2.0, 0, 9.0), Vector3(0, 0, 2.0), 9.0,
		[Vector3(10.0, 0, 8.0), Vector3(10.0, 0, 11.0)], Vector3(-10.0, 0, 6.0), PI / 2.0, Vector3(6.0, 0, 12.0), PI)


## Pentheus's palace at Thebes (the Bacchae): the palace front split by the god's earthquake, fire
## leaping from Semele's tomb, Dionysus in his mortal shape, Pentheus dressed as a woman, the old men
## Cadmus and Teiresias in fawnskins.
static func pentheus_palace(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	Kit.box(g, Vector3(0, 0.01, 6.0), Vector3(44.0, 0.04, 28.0), "paving" if back.has("walkway") else "ashbed", false)
	var palace := Props.palace_front(g, Vector3(0, 0, -6.0), 0.0, back.has("walkway"), true)
	if palace["fire"] and back.has("lamps"):
		area["flicker"].append(palace["fire"])
	_person(area, g, Vector3(2.0, 0, 3.0), Vector3(-1.0, 0, 3.0), "dionysus", back, "teacher")
	_person(area, g, Vector3(-1.0, 0, 3.0), Vector3(2.0, 0, 3.0), "pentheus", back)
	_person(area, g, Vector3(-5.0, 0, 6.0), Vector3(0, 0, 3.0), "teiresias", back)
	return _spots(area, g, back, Vector3(4.0, 0, 7.0), Vector3(0, 0, 6.0), 7.0,
		[Vector3(16.0, 0, 6.0), Vector3(16.0, 0, 9.0)], Vector3(-14.0, 0, 12.0), PI, Vector3(10.0, 0, 16.0), PI)


# ---------- e3: Aristophanes ----------

## Strepsiades' house (the Clouds): a farmer ruined by his son's horses, awake at night in bed
## counting his debts while the son sleeps and dreams of racing; the horse in its stall, a lamp,
## the Thinkery's door across the street.
static func strepsiades_house(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(20.0, 0.04, 16.0), "paving", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 6.2, 1.7, -2.0), Vector3(0.3, 3.4, 10.0), "plaster")
	Kit.box(g, Vector3(0, 1.7, -7.0), Vector3(12.7, 3.4, 0.3), "plaster")
	if whole:
		Kit.box(g, Vector3(0, 3.5, -2.0), Vector3(13.0, 0.25, 10.5), "roof", false)
	for x: float in [-3.0, 3.0]:
		Kit.bed(g, Vector3(x, 0, -4.5), 0.0)
	_person(area, g, Vector3(-3.0, 0, -3.3), Vector3(-3.0, 0, 0), "strepsiades", back)
	var son := _person(area, g, Vector3(3.0, 0.55, -4.5), Vector3(3.0, 0.5, 0), "pheidippides", back)
	(son["root"] as Node3D).rotation = Vector3(-PI / 2.0, PI / 2.0, 0)  # asleep on his bed
	Greek.beast(g, Vector3(-4.0, 0, 5.0), PI / 2.0, "horse", "", 1.0, back.has("household"))
	var lamp := Kit.lamp_stand(g, Vector3(0, 0, -5.5), back.has("lamps"))
	if lamp:
		area["flicker"].append(lamp)
	return _spots(area, g, back, Vector3(0, 0, 0), Vector3(0, 0, 2.0), 4.0,
		[Vector3(-5.5, 0, 4.0), Vector3(-5.5, 0, 6.5)], Vector3(4.5, 0, 5.0), -PI / 2.0, Vector3(0, 0, 6.5), PI)


## The Thinkery (the Clouds): Socrates' school, his pupils bent double over the ground, the map of
## the earth, Socrates in his basket in the air, the Clouds come down as women to be the chorus,
## and the two Arguments in their cages.
static func thinkery(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 4.0), Vector3(30.0, 0.04, 24.0), "paving" if whole else "ashbed", false)
	var t := Props.thinkery(g, Vector3(0, 0, -4.0), 0.0, whole)
	area["basket"] = t["basket"]
	var soc := People.figure(t["basket"], Vector3(0, -0.9, 0), 0.0, "socrates", not back.has("teacher"))
	(soc["root"] as Node3D).scale = Vector3.ONE * 0.6
	area["people"].append(soc)
	for k in 6:  # the Clouds, come down as women
		var a := PI * 0.15 + k * PI * 0.14
		_person(area, g, Vector3(cos(a) * 9.0, 0, 4.0 + sin(a) * 6.0), Vector3(0, 0, 4.0), "cloud", back)
	area["arguments"] = Props.cages(g, Vector3(-8.0, 0, 8.0), 0.4, back.has("household"))
	_person(area, g, Vector3(2.0, 0, 5.0), Vector3(0, 0, -4.0), "strepsiades", back)
	return _spots(area, g, back, Vector3(-2.0, 0, 6.0), Vector3(0, 0, 7.0), 5.0,
		[Vector3(12.0, 0, 8.0), Vector3(12.0, 0, 11.0)], Vector3(10.0, 0, -2.0), -PI / 2.0, Vector3(-10.0, 0, 14.0), PI)


# ---------- e3: Herodotus ----------

## Sardis, Croesus's capital (Histories I.29-45, 86-87): the court where he shows Solon his
## treasuries and asks who is the happiest of men, and in the square below the pyre where, a
## captive of Cyrus, he calls out Solon's name, and the sudden rain that puts it out.
static func sardis(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 4.0), Vector3(50.0, 0.04, 36.0), "paving" if whole else "ashbed", false)
	Props.palace_front(g, Vector3(0, 0, -10.0), 0.0, whole)
	Props.gold_offering(g, Vector3(-6.0, 0, -4.0), 0.0, whole)
	_person(area, g, Vector3(0, 0, -5.0), Vector3(0, 0, 0), "croesus", back)
	_person(area, g, Vector3(0, 0, -1.0), Vector3(0, 0, -5.0), "solon", back, "teacher")
	var fire := Props.pyre(g, Vector3(10.0, 0, 10.0), 0.3, back.has("lamps"), false, 1.5)
	if fire:
		area["flicker"].append(fire)
	var captive := _person(area, g, Vector3(10.0, 2.1, 10.0), Vector3(0, 0, 0), "croesus", back, "soldiers")
	area["on_the_pyre"] = captive
	for k in 6:  # the Persian soldiers round the pyre
		var a := TAU * k / 6.0
		Greek.immortal(g, Vector3(10.0 + cos(a) * 4.0, 0, 10.0 + sin(a) * 4.0), not back.has("soldiers"))
	return _spots(area, g, back, Vector3(-3.0, 0, 2.0), Vector3(-4.0, 0, 6.0), 6.0,
		[Vector3(-20.0, 0, 6.0), Vector3(-20.0, 0, 9.0)], Vector3(-16.0, 0, 16.0), PI, Vector3(0, 0, 18.0), PI)


## Delphi, where Croesus sent to test the oracles (Histories I.46-56): the temple of Apollo on its
## terrace under the cliffs, the tripod and the navel stone, the Pythia, and Croesus's golden gifts.
static func delphi(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 4.0), Vector3(44.0, 0.04, 34.0), "paving" if whole else "ashbed", false)
	Kit.box(g, Vector3(0, 12.0, -20.0), Vector3(60.0, 24.0, 4.0), "rock")  # the Phaedriades, the shining cliffs
	Rome.temple(g, Vector3(0, 0, -8.0), 0.0, whole)
	Greek.tripod(g, Vector3(-4.0, 0, 4.0), back.has("sun"), whole)
	Greek.omphalos(g, Vector3(4.0, 0, 4.0), whole)
	_person(area, g, Vector3(-4.0, 0, 5.2), Vector3(0, 0, 10.0), "pythia", back, "teacher")
	Props.gold_offering(g, Vector3(10.0, 0, 2.0), -PI / 2.0, whole)
	for k in 3:  # Croesus's messengers, waiting for the answer
		_person(area, g, Vector3(-2.0 + k * 1.6, 0, 11.0), Vector3(-4.0, 0, 5.0), "envoy", back)
	return _spots(area, g, back, Vector3(2.0, 0, 8.0), Vector3(0, 0, 8.0), 8.0,
		[Vector3(-18.0, 0, 8.0), Vector3(-18.0, 0, 11.0)], Vector3(16.0, 0, 12.0), -PI / 2.0, Vector3(-12.0, 0, 16.0), PI)


## Thermopylae (Histories VII.201-239): the narrow pass between the mountain wall (-X) and the sea
## (+X), the Phocian wall across it, the Spartans combing their hair and exercising before the
## battle as the Persian scout saw them, and the Immortals coming up the road. Returns, besides
## the usual, the two armies in "squads".
static func thermopylae(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(14.0, 0.04, 80.0), "earth" if back.has("leaves") else "ashbed", false)
	Kit.box(g, Vector3(-12.0, 15.0, 0), Vector3(10.0, 30.0, 80.0), "rock")  # Mount Kallidromos
	Kit.box(g, Vector3(7.5, 1.5, 0), Vector3(1.0, 3.0, 80.0), "rock", false)  # the drop to the sea
	Props.phocian_wall(g, Vector3(0, 0, 0), 0.0, 14.0, whole)
	area["squads"].append(Greek.phalanx(g, Vector3(0, 0, -6.0), 3, 8, "sparta", not back.has("soldiers")))
	var immortals := Kit.group(g, Vector3(0, 0, 30.0), PI)
	var legs: Array = []
	for r in 3:
		for f in 8:
			legs.append_array(Greek.immortal(immortals, Vector3((f - 3.5) * 0.9, 0, -r * 1.1), not back.has("soldiers")))
	area["squads"].append({"root": immortals, "legs": legs, "leg": 0, "speed": 1.0, "step": 0.0, "undead": not back.has("soldiers")})
	_person(area, g, Vector3(2.0, 0, -2.0), Vector3(0, 0, 10.0), "leonidas", back, "teacher")
	return _spots(area, g, back, Vector3(-2.0, 0, -12.0), Vector3(0, 0, -16.0), 4.5,
		[Vector3(-5.0, 0, -24.0), Vector3(-5.0, 0, -21.0)], Vector3(4.0, 0, -24.0), -PI / 2.0, Vector3(4.0, 0, -28.0), 0.0)


# ---------- e3: Thucydides ----------

## The Kerameikos, the public cemetery of Athens (II.34-46): the ten cypress coffins and the empty
## bier, the grave monuments along the road, the high platform Pericles spoke from, and the
## mourners.
static func kerameikos(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(50.0, 0.04, 40.0), "earth" if back.has("leaves") else "ashbed", false)
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(6.0, 0.04, 40.0), "path", false)  # the road out of the city
	for k in 10:  # grave monuments along the road
		for side: float in [-1.0, 1.0]:
			Kit.stele(g, Vector3(side * 5.0, 0, -16.0 + k * 3.5), -side * PI / 2.0)
	area["coffins"] = Props.larnakes(g, Vector3(-12.0, 0, -2.0), PI / 2.0, whole)
	Greek.bema(g, Vector3(10.0, 0, 0), -PI / 2.0, whole)
	_person(area, g, Vector3(10.0, 1.2 if whole else 0.7, 0), Vector3(-12.0, 0, 0), "pericles", back, "teacher")
	for k in 8:  # the mourners
		var a := PI * 0.6 + k * 0.12
		_folk(area, g, Vector3(-12.0 + cos(a) * 10.0, 0, sin(a) * 10.0), Vector3(-12.0, 0, 0),
			{"robe": "2a2a2a", "hair_color": "2a1e16"}, back)
	for k in 6:
		area["sway"].append(Kit.cypress(g, Vector3(-22.0 + k * 1.5, 0, 16.0), 7.0, back.has("leaves")))
	return _spots(area, g, back, Vector3(8.0, 0, 3.0), Vector3(0, 0, -8.0), 6.0,
		[Vector3(18.0, 0, 10.0), Vector3(18.0, 0, 13.0)], Vector3(18.0, 0, -12.0), -PI / 2.0, Vector3(-18.0, 0, -14.0), 0.0)


## Athens in the plague (II.47-54): a street by a fountain where the sick lay dying of thirst,
## beds carried out into the open, the dead lying unburied, pyres of strangers' bodies, the temples
## full of the dead.
static func plague(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(40.0, 0.04, 34.0), "paving" if whole else "ashbed", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 14.0, 2.5, 0), Vector3(3.0, 5.0, 30.0), "plaster")  # the street's houses
	Rome.fountain(g, Vector3(0, 0, -6.0), 0.0, back.has("water"))
	for k in 6:  # the sick on beds carried into the street
		var p := Vector3((k % 3 - 1) * 4.0, 0, 2.0 + (k / 3) * 5.0)
		Kit.bed(g, p, PI / 2.0)
		Kit.blob(g, p + Vector3(0, 0.62, 0), 0.2, "#8a8274", Vector3(1.2, 0.6, 3.5), 6)
	for k in 5:  # the dead at the fountain's edge
		Kit.blob(g, Vector3(-3.0 + k * 1.4, 0.2, -3.8), 0.2, "#6a6258", Vector3(1.2, 0.7, 4.0), 6)
	for k in 2:
		var fire := Props.pyre(g, Vector3(-6.0 + k * 12.0, 0, 12.0), 0.5, back.has("lamps"))
		if fire:
			area["flicker"].append(fire)
	return _spots(area, g, back, Vector3(0, 0, 8.0), Vector3(0, 0, 4.0), 7.0,
		[Vector3(-11.0, 0, -8.0), Vector3(-11.0, 0, -5.0)], Vector3(11.0, 0, -10.0), -PI / 2.0, Vector3(10.0, 0, 13.0), PI)


## Corcyra in civil strife (III.82-83): a harbour town's square, the temple of Hera where the
## suppliants took refuge, houses burning, bodies in the temple precinct; words changed their
## meanings, and nothing held.
static func corcyra(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(44.0, 0.04, 36.0), "paving" if whole else "ashbed", false)
	Props.shrine(g, Vector3(0, 0, -10.0), 0.0, "hera", whole)  # Hera's temple
	for k in 5:  # the suppliants at the altar
		var a := PI * 0.2 + k * PI * 0.15
		_folk(area, g, Vector3(cos(a) * 3.0, 0, -5.0 + sin(a) * 3.0), Vector3(0, 0, -6.0), {"robe": "5a4a3a"}, back)
	for k in 3:  # the houses, one of them burning
		var p := Vector3(-16.0 + k * 16.0, 0, 12.0)
		Kit.box(g, p + Vector3(0, 2.2, 0), Vector3(8.0, 4.4, 6.0), "plaster" if k != 1 else "#2a2622")
		if k == 1 and back.has("lamps"):
			for q: Vector3 in [Vector3(-1, 4.8, 0), Vector3(1, 5.0, 1), Vector3(0, 5.2, -1)]:
				Kit.blob(g, p + q, 0.7, "fire", Vector3(1.0, 1.8, 1.0), 5)
			var l := OmniLight3D.new()
			l.position = p + Vector3(0, 6.0, 0)
			l.light_color = Color("ff9040")
			l.light_energy = 2.5
			l.omni_range = 16.0
			g.add_child(l)
			area["flicker"].append(l)
	for k in 3:
		Kit.blob(g, Vector3(6.0 + k * 1.3, 0.2, -4.0), 0.2, "#6a6258", Vector3(1.2, 0.7, 4.0), 6)
	Greek.ship(g, Vector3(0, -1.2, 40.0), PI / 2.0, "trireme", false, true, back.has("soldiers"))
	return _spots(area, g, back, Vector3(-4.0, 0, 4.0), Vector3(0, 0, 3.0), 7.0,
		[Vector3(-19.0, 0, -6.0), Vector3(-19.0, 0, -3.0)], Vector3(19.0, 0, -6.0), -PI / 2.0, Vector3(18.0, 0, 3.0), -PI / 2.0)


## Melos (V.84-116): the small island city's wall, the Athenian envoys and the Melian magistrates
## meeting in private before it, the Athenian ships in the bay and the siege wall they build right
## round the town while the talking goes on.
static func melos(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	Kit.box(g, Vector3(0, 0.01, 0), Vector3(70.0, 0.04, 50.0), "earth" if back.has("leaves") else "ashbed", false)
	Greek.troy_wall(g, Vector3(0, 0, -14.0), 0.0, 40.0, true, whole)  # the Melians' wall (a small city's)
	Rome.far_city(g, Vector3(0, 0, -40.0), 14.0, 24.0, 20, 416)
	Props.siege_wall(g, Vector3(-30.0, 0, 4.0), Vector3(30.0, 0, 4.0), back.has("soldiers"))
	for k in 2:  # the talk: two Athenians, two Melians, a table between
		_person(area, g, Vector3(-1.5 + k * 1.0, 0, -3.0), Vector3(0, 0, -6.0), "envoy", back, "teacher")
		_person(area, g, Vector3(-1.5 + k * 1.0, 0, -7.0), Vector3(0, 0, -3.0), "melian", back)
	Kit.table(g, Vector3(-1.0, 0, -5.0), PI / 2.0)
	for k in 3:
		Greek.ship(g, Vector3(-30.0 + k * 20.0, -1.2, 40.0), PI / 2.0, "trireme", false, true, back.has("soldiers"))
	area["squads"].append(Greek.phalanx(g, Vector3(18.0, 0, 10.0), 2, 6, "athens", not back.has("soldiers")))
	return _spots(area, g, back, Vector3(2.0, 0, -1.0), Vector3(0, 0, -5.0), 6.0,
		[Vector3(-24.0, 0, 12.0), Vector3(-24.0, 0, 15.0)], Vector3(-18.0, 0, 18.0), PI, Vector3(10.0, 0, 20.0), PI)
