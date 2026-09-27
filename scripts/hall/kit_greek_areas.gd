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
## here (the place builds him from rooms.json); his spot is.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")


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

## The court of the Museum at Alexandria, about 300 BC: a garden of date palms inside colonnades,
## library cabinets of papyrus rolls under them, scholars at sand trays, and the Pharos over the
## roofs to the north (-Z). The definitions, postulates and common notions have their stones round
## the garden.
static func museum_court(parent: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var area := _area(g)
	var whole := back.has("walkway")
	const S := 26.0
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(S + 8.0, 0.04, S + 8.0), "paving", false)
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(S - 8.0, 0.04, S - 8.0), "grass" if back.has("leaves") else "ashbed", false)
	for side in range(1, 4):  # colonnades on three sides; the fourth (+Z) is the way in
		var a := side * PI / 2.0
		Kit.stoa(g, Vector3(sin(a), 0, cos(a)) * (S / 2.0), a + PI, S, 5.0, whole)
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
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(24.0, 0.04, 22.0), "paving", false)
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
