extends RefCounted
## The places of Rome's first module (content/rome/works.json, "Rome: Duty, Empire, and the
## Stoics"), one for each book, each in its own zone of the city of Rome (rome_map.gd,
## content/rome/republican_rome.json) and in its author's own years: the city of that age stands
## round the zone, grey rubble while the place is lost, and a fence runs round it. Inside, the
## place stands on a terrace cut into its hill (or on the flat by the river and the Forum), with
## the usual things of a book's place (places_greek.gd): the gateway back into the city with the
## facts along the way in, the teacher, his busts, map and book, a seat, and a stone or a played
## moment (a beat, content/rome/beats.json) for each of the six points of the lesson. It comes
## back piece by piece as the points are understood, like the Greek places.
##
##   casa_romuli          Livy: the hut of Romulus on the Palatine, the furrow, the Sabines, Lucretia
##   curia_pompeii        Plutarch: Pompey's portico and hall on the Campus, the Rubicon, the Ides
##   horti_maecenatis     Virgil: Maecenas's gardens on the Esquiline with the Aeneid's scenes in them
##   hortus_collinus      Lucretius: a walled garden by the Colline Gate, the sunbeam, the tombs
##   rostra_ciceronis     Cicero, On Duties: the Rostra, the Senate House and his house above the Forum
##   arx                  Cicero, the Dream: the Arx at night under the nine spheres
##   horti_transtiberini  Ovid: a garden across the Tiber, the laurel, the flood, the way down
##   domus_agricolae      Tacitus: Agricola's house on the Quirinal, the masks, the hill of Mons Graupius
##   insula_suburae       Epictetus: the house of Epaphroditus in the Subura, the lamp, the baskets
##   palatium             Marcus Aurelius: a room of the palace on the Palatine before dawn
##   emporium             Seneca: the river port and granaries under the Aventine

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Urbs := preload("res://scripts/hall/kit_urbs.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")
const RomeMap := preload("res://scripts/hall/rome_map.gd")
const Places := preload("res://scripts/hall/places.gd")
const PG := preload("res://scripts/hall/places_greek.gd")


static func build(world: Node3D, work: String, room: Dictionary, stage: int = 0) -> Dictionary:
	match room.get("place", ""):
		"casa_romuli":
			return casa_romuli(world, work, room, stage)
		"curia_pompeii":
			return curia_pompeii(world, work, room, stage)
		"horti_maecenatis":
			return horti_maecenatis(world, work, room, stage)
		"hortus_collinus":
			return hortus_collinus(world, work, room, stage)
		"rostra_ciceronis":
			return rostra_ciceronis(world, work, room, stage)
		"arx":
			return arx(world, work, room, stage)
		"horti_transtiberini":
			return horti_transtiberini(world, work, room, stage)
		"domus_agricolae":
			return domus_agricolae(world, work, room, stage)
		"insula_suburae":
			return insula_suburae(world, work, room, stage)
		"palatium":
			return palatium(world, work, room, stage)
		"emporium":
			return emporium(world, work, room, stage)
	push_error("No place built for %s" % work)
	return Places.hub(world, [])


# ---------- the frame every place shares ----------

## The sky as far as the place is restored, the city of the book's age round its zone (grey and
## fallen while the place is lost), the zone's fence, and a terrace cut into the ground at
## `centre` (map metres) of `size` (world metres) whose top is level with the highest ground under
## it, so the place stands flat on its hill. Returns the frame: the pieces back ("b"), whether the
## place is whole, the terrace's centre on its top ("c", so every local point is c + local), and
## the empty lists the place fills.
static func _frame(world: Node3D, room: Dictionary, stage: int, mood: String, zone_id: String, age_id: String, year: int,
		centre: Array, size: Vector2, top: String, stars: bool = false) -> Dictionary:
	var c := RomeMap.at(centre)
	var b := Places._sky(world, room, stage, mood, c, 60.0)
	var whole := b.has("sun")
	if stars and whole:
		Kit.stars(world)
	RomeMap.plain(world, whole)
	RomeMap.city(world, zone_id, whole, age_id, year)
	RomeMap.fence(world, zone_id)
	var h := -INF
	var i := -size.x / 2.0
	while i <= size.x / 2.0:
		var j := -size.y / 2.0
		while j <= size.y / 2.0:
			h = maxf(h, RomeMap.ground(c + Vector3(i, 0, j)))
			j += 8.0
		i += 8.0
	h += 0.1
	Kit.box(world, c + Vector3(0, h - 1.5, 0), Vector3(size.x, 3.0, size.y), top)
	c.y = h
	return {"b": b, "whole": whole, "c": c, "out": [], "spots": {}, "flicker": [], "sway": [], "people": [], "birds": [],
		"squads": []}


## The gateway back into the city at `gate` (local), the way in from it toward `to`, and the
## facts on steles along it (places_greek's arrival, turned toward the city).
static func _gate(world: Node3D, room: Dictionary, f: Dictionary, gate: Vector3, to: Vector3, mat: String = "basalt") -> void:
	var c: Vector3 = f["c"]
	PG._arrival_toward(world, room, f["out"], f["spots"], f["flicker"], c + gate, c + to, mat, "urbs")
	f["spawn"] = c + gate + (to - gate).normalized() * 3.0 + Vector3(0, 0.05, 0)
	f["yaw"] = Places.look_yaw(to - gate)


## What every builder returns to the Hall, from the frame.
static func _done(room: Dictionary, f: Dictionary, teacher: Dictionary) -> Dictionary:
	return {"name": PG._name(room), "interactables": f["out"], "spawn": f["spawn"], "yaw": f["yaw"], "spots": f["spots"],
		"flicker": f["flicker"], "people": [teacher] + f["people"], "restored": 0, "sway": f["sway"], "birds": f["birds"],
		"squads": f["squads"], "back": f["b"]}


## A lesson stone with a stele beside it, facing `face`.
static func _stele_stone(world: Node3D, f: Dictionary, work: String, room: Dictionary, id: String, at: Vector3, face: Vector3,
		text: String) -> void:
	var back := (at - face).normalized() * 0.9
	Kit.stele(world, at + back, Kit.face_yaw(at + back, at))
	PG._stone(f["out"], work, room, id, at, text)
	f["spots"][id] = at


## A played moment: where you stand to begin it, what it moves and where it goes.
static func _beat(f: Dictionary, work: String, room: Dictionary, id: String, name: String, at: Vector3, face: Vector3, text: String,
		cast: Dictionary, marks: Dictionary) -> void:
	f["out"].append({"kind": "beat", "pos": at, "start": at, "face": face, "work": work, "id": id, "beat": name, "text": text,
		"note": Places._lesson(room, id).get("point", ""), "cast": cast, "marks": marks})
	f["spots"][id] = at


## Someone of the place, a shade while the piece that brings the people back (`need`) is not.
static func _person(world: Node3D, f: Dictionary, at: Vector3, face: Vector3, who: String, need: String = "household",
		pose: String = "") -> Dictionary:
	var w := People.figure(world, at, Kit.face_yaw(at, face), who, not f["b"].has(need), pose)
	f["people"].append(w)
	return w


## A Roman in his toga, a shade while the people are not back.
static func _citizen(world: Node3D, f: Dictionary, at: Vector3, face: Vector3, look: Dictionary) -> Dictionary:
	var w := Rome.togatus(world, at, Kit.face_yaw(at, face), look, not f["b"].has("household"))
	f["people"].append(w)
	return w


## A lamp that flickers once the lamps are back.
static func _lamp(world: Node3D, f: Dictionary, at: Vector3) -> void:
	var l := Kit.lamp_stand(world, at, f["b"].has("lamps"))
	if l:
		f["flicker"].append(l)


## The teacher's study: his busts, the map and the book, laid out beside him.
static func _study(world: Node3D, room: Dictionary, f: Dictionary, at: Vector3, yaw: float) -> void:
	var c: Vector3 = f["c"]
	var side := Vector3(cos(yaw), 0, -sin(yaw))  # to the teacher's right
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	PG._study(world, room, f["out"], f["spots"],
		[[c + at - side * 4.2, yaw, c + at - side * 4.2 + fwd * 1.6], [c + at - side * 6.2, yaw, c + at - side * 6.2 + fwd * 1.6]],
		c + at + side * 6.0 + Vector3(0, 1.6, 0) - fwd * 1.5, yaw + PI, c + at + side * 6.0 + fwd * 0.2, c + at + side * 3.6 - fwd * 1.2,
		c + at + side * 3.6)


# ---------- Livy: the hut of Romulus ----------

## The Palatine in the age of heroes: the hut of Romulus in its fence, the Lupercal with the fig and
## the wolf before it, the furrow of the first wall ploughed round the hill's top with the plough
## team standing in it, the seven kings on their stones, the two armies in the valley with the
## Sabine women between them, and Lucretia on her bier in a house of Collatia with the men sworn
## round her. Lost: the hut fallen in, the fig dead, the spring dry, the furrow grown over.
static func casa_romuli(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "morning", "palatina", "heroic", -280, [44, -431], Vector2(104, 104), "earth")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	var leaves := b.has("leaves")
	_gate(world, room, f, Vector3(0, 0, 46), Vector3(0, 0, 24), "path")
	if leaves:
		f["birds"] = Kit.flock(world, c + Vector3(0, 0, -10), 5, 16.0, 12.0)

	# the hut in its precinct, Livy on a stone by its door
	var hut := Kit.group(world, c, 0.0)
	Urbs.hut(hut, whole)
	var fire := Kit.hearth(world, c + Vector3(0, 0, -0.4), b.has("lamps"))
	if fire:
		f["flicker"].append(fire)
	Kit.box(world, c + Vector3(3.4, 0.25, 7.0), Vector3(0.9, 0.5, 0.7), "stone")
	var livy := PG._teacher(world, room, b, stage, c + Vector3(3.4, 0, 7.2), 0.0, c + Vector3(3.4, 0, 10.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(3.4, 0, 7.2), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(-7.0, 0, 11.0), Vector3(0, 0, -1), "Sit on the hill and look at the hut"))

	# the Lupercal, the fig and the wolf, the spring
	var cave := Kit.group(world, c + Vector3(-24, 0, -10), PI * 0.4)
	Urbs.cave(cave)
	var fig := Kit.group(world, c + Vector3(-16, 0, -2), 0.0)
	Urbs.fig(fig, leaves)
	Rome.spring(world, c + Vector3(-28, 0, 2), b.has("water"))

	# the furrow of the first wall, ploughed round the hill, and the team that cut it
	var ring: Array = []
	for k in 25:
		var a := TAU * k / 24.0
		ring.append(c + Vector3(cos(a) * 30.0, 0.02, sin(a) * 30.0))
	RomeMap.ribbon(world, ring, 1.2, "furrows" if b.has("walkway") else "grass", 0.03, c.y)
	Greek.plough_team(world, c + Vector3(30.0, 0, 2.0), PI, whole)
	var remus := _person(world, f, c + Vector3(33.0, 0, -6.0), c, "remus")

	# the seven kings on their stones, and Tarquin the Proud at the end
	for k in 7:
		var p := c + Vector3(10.0 + k * 2.4, 0, -14.0)
		Kit.stele(world, p, 0.0)
	_person(world, f, c + Vector3(27.0, 0, -16.0), c + Vector3(10, 0, -14), "tarquin")

	# the valley: the two armies and the women between them
	var romans := Rome.century(world, c + Vector3(-13.0, 0, -34.0), 3, 5, not b.has("household"))
	romans["root"].rotation.y = -PI / 2.0
	f["squads"].append(romans)
	var sabines := Rome.century(world, c + Vector3(13.0, 0, -34.0), 3, 5, not b.has("household"))
	sabines["root"].rotation.y = PI / 2.0
	f["squads"].append(sabines)
	for k in 4:
		_person(world, f, c + Vector3(-3.0 + k * 2.0, 0, -36.0 + (k % 2) * 2.0), c + Vector3(-13, 0, -34), "sabine")

	# Lucretia's house at Collatia: the bier, and the men sworn round it
	var house := Kit.group(world, c + Vector3(26, 0, 22), -PI / 2.0)
	Kit.box(house, Vector3(0, 2.0, -3.0), Vector3(10.0, 4.0, 0.4), "plaster", true)
	for x: float in [-5.0, 5.0]:
		Kit.box(house, Vector3(x, 2.0, 0), Vector3(0.4, 4.0, 6.0), "plaster", true)
	if whole:
		Kit.box(house, Vector3(0, 4.2, 0), Vector3(10.6, 0.4, 6.6), "roof", false)
	Props.bier(world, c + Vector3(26, 0, 22), -PI / 2.0, true, whole)
	var brutus := _person(world, f, c + Vector3(26.0, 0, 24.2), c + Vector3(26, 0, 22), "brutus")
	_person(world, f, c + Vector3(23.6, 0, 22.0), c + Vector3(26, 0, 22), "collatinus")
	_person(world, f, c + Vector3(28.4, 0, 22.0), c + Vector3(26, 0, 22), "lucretius_senior")
	_lamp(world, f, c + Vector3(24.0, 0, 19.6))

	# the six points
	_stele_stone(world, f, work, room, "exemplum", c + Vector3(-3.4, 0, 20.0), c + Vector3(-3.4, 0, 30.0), "Read Livy's Preface on its stone")
	_stele_stone(world, f, work, room, "kings", c + Vector3(17.0, 0, -11.0), c + Vector3(17, 0, -14), "Read the seven kings")
	_stele_stone(world, f, work, room, "lucretia", c + Vector3(26.0, 0, 27.5), c + Vector3(26, 0, 22), "Look at Lucretia on her bier")
	_beat(f, work, room, "founding", "the_furrow", c + Vector3(30.0, 0, 6.0), c + Vector3(30, 0, 2), "Plough the first wall, as Romulus",
		{"remus": remus["root"]}, {"team": c + Vector3(30.0, 0, 3.4), "round": [c + Vector3(21.2, 0, 21.2), c + Vector3(0, 0, 30.0)],
		"remus": c + Vector3(33.0, 0, -6.0)})
	_beat(f, work, room, "sabines", "the_sabines", c + Vector3(0, 0, -26.0), c + Vector3(0, 0, -36), "Run between the armies, as Hersilia",
		{}, {"between": c + Vector3(0, 0, -34.0), "romans": c + Vector3(-11, 0, -34), "sabines": c + Vector3(11, 0, -34)})
	_beat(f, work, room, "oath", "the_oath", c + Vector3(26.0, 0, 25.4), c + Vector3(26, 0, 22), "Swear over Lucretia, as Brutus",
		{"brutus": brutus["root"]}, {"bier": c + Vector3(26, 0, 22), "men": c + Vector3(23.6, 0, 22.0)})
	return _done(room, f, livy)


# ---------- Plutarch: Pompey's portico and hall ----------

## The Campus Martius in 44 BC: the portico of Pompey with its plane trees, the hall behind it
## where the Senate met with Pompey's statue at its end and the benches round it, a platform for
## the Lupercalia with Antony holding out the diadem, and at the edge of the Campus the Rubicon, a
## stream with Caesar's eagle planted on its bank. Lost: the portico broken, the trees dead, the
## stream dry, the senators shades.
static func curia_pompeii(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "morning", "campus_martius", "republic", -44, [-900, 900], Vector2(116, 96), "paving")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 44), Vector3(0, 0, 22))
	if b.has("leaves"):
		f["birds"] = Kit.flock(world, c + Vector3(0, 0, 0), 5, 18.0, 12.0)

	# the portico, the plane trees, Plutarch under them
	var portico := Kit.group(world, c + Vector3(0, 0, -4), 0.0)
	Urbs.portico(portico, 0.9, b.has("walkway"))
	for p: Vector3 in [Vector3(-16, 0, 10), Vector3(-6, 0, 12), Vector3(8, 0, 11), Vector3(18, 0, 9)]:
		f["sway"].append(Kit.plane_tree(world, c + p, 1.2, b.has("leaves")))
	var plutarch := PG._teacher(world, room, b, stage, c + Vector3(-10.0, 0, 16.0), 0.0, c + Vector3(-10.0, 0, 18.8), f["out"], f["spots"])
	_study(world, room, f, Vector3(-10.0, 0, 16.0), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(2.0, 0, 18.0), Vector3(0, 0, -1), "Sit under the plane trees"))

	# the hall of Pompey: the statue at its end, the senators' benches, the conspirators
	var hall := Kit.group(world, c + Vector3(0, 0, -26), 0.0)
	Kit.box(hall, Vector3(0, 4.0, -8.0), Vector3(24.0, 8.0, 0.6), "brick" if whole else "ashbed")
	for x: float in [-12.0, 12.0]:
		Kit.box(hall, Vector3(x, 4.0, 0), Vector3(0.6, 8.0, 16.0), "brick" if whole else "ashbed")
	if whole:
		Kit.box(hall, Vector3(0, 8.3, 0), Vector3(25.0, 0.6, 17.0), "roof", false)
	Kit.box(hall, Vector3(0, 0.6, -6.0), Vector3(2.0, 1.2, 2.0), "marble")
	var pompey := Places._figure(hall, Vector3(0, 1.2, -6.0), 0.0, "#f2f0ea", 1.3)
	pompey.name = "pompey"
	for side: float in [-1.0, 1.0]:
		Rome.subsellia(world, c + Vector3(side * 7.0, 0, -26.0), -side * PI / 2.0, 10.0, 3, whole)
	var cast := {}
	for k in 5:
		var a := -PI * 0.5 + k * PI / 4.0 + PI / 8.0
		var p := c + Vector3(-28.0, 0, -28.0) + Vector3(cos(a) * 3.0, 0, sin(a) * 3.0)
		var w := _person(world, f, p, c + Vector3(0, 0, -28), "conspirator")
		cast["man%d" % k] = w["root"]
	for p: Vector3 in [Vector3(-2.0, 0, -30.0), Vector3(2.4, 0, -29.0), Vector3(-1.0, 0, -22.0)]:
		_person(world, f, c + p, c + Vector3(0, 0, -32), "senator")
	_lamp(world, f, c + Vector3(-9.0, 0, -32.0))
	_lamp(world, f, c + Vector3(9.0, 0, -32.0))

	# the platform of the Lupercalia, and the Rubicon at the Campus's edge
	var bema := Greek.bema(world, c + Vector3(24, 0, 2), -PI / 2.0, whole)
	var antony := _person(world, f, c + Vector3(26.0, 0, 2.0), bema, "antony")
	Kit.stream(world, c + Vector3(-50, 0, 30), c + Vector3(-28, 0, 18), 3.0, b.has("water"))
	Rome.aquila(world, c + Vector3(-36.0, 0, 28.0), whole)
	Kit.box(world, c + Vector3(-39.0, 0.3, 24.0), Vector3(3.0, 0.6, 3.5), "wood", true)  # the plank over the stream

	# the six points
	_stele_stone(world, f, work, room, "ambition", c + Vector3(-18.0, 0, 20.0), c + Vector3(-18, 0, 16), "Read of Caesar weeping before Alexander")
	_stele_stone(world, f, work, room, "clemency", c + Vector3(14.0, 0, -14.0), c + Vector3(0, 0, -26), "Read what mercy won him")
	_stele_stone(world, f, work, room, "judgement", c + Vector3(-4.0, 0, 20.0), c + Vector3(-10, 0, 16), "Read Plutarch's judgement")
	_beat(f, work, room, "rubicon", "the_rubicon", c + Vector3(-39.0, 0, 30.0), c + Vector3(-39, 0, 20), "Cross the Rubicon, as Caesar", {},
		{"bank": c + Vector3(-39.0, 0, 29.0), "far": c + Vector3(-39.0, 0, 17.0), "eagle": c + Vector3(-36.0, 1.6, 28.0)})
	_beat(f, work, room, "diadem", "the_diadem", bema + Vector3(-1.5, 0, 0), c + Vector3(26, 0, 2), "Refuse the diadem, as Caesar",
		{"antony": antony["root"]}, {"crowd": c + Vector3(16, 0, 8)})
	_beat(f, work, room, "ides", "the_ides", c + Vector3(0, 0, -20.0), c + Vector3(0, 0, -32), "Go into the Senate, as Caesar", cast,
		{"seat": c + Vector3(0, 0, -30.0), "statue": c + Vector3(0, 1.8, -32.0), "man0": c + Vector3(-25.0, 0, -28.0)})
	return _done(room, f, plutarch)


# ---------- Virgil: the gardens of Maecenas ----------

## The Esquiline about 19 BC: the terraces of Maecenas's gardens, pines and cypresses, a channel
## and a pool, Virgil on a bench under a pine; and set about the gardens the scenes of the poem:
## Troy burning with Anchises waiting to be carried, Dido's pyre by the pool, the dark grove with
## the golden bough and the Sibyl, the souls of Rome to come in a row with Anchises before them,
## and the duelling ground where Turnus kneels. Lost: the trees dead, the channel dry, the figures
## shades.
static func horti_maecenatis(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "golden", "esquilina", "republic", -19, [1150, 450], Vector2(112, 112), "earth")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	var leaves := b.has("leaves")
	_gate(world, room, f, Vector3(0, 0, 48), Vector3(0, 0, 26), "path")
	if leaves:
		f["birds"] = Kit.flock(world, c, 6, 20.0, 14.0)

	# the gardens: pines, cypresses, the pergola, the channel to the pool
	for p: Vector3 in [Vector3(-20, 0, 20), Vector3(22, 0, 24), Vector3(-36, 0, 4), Vector3(38, 0, 0), Vector3(12, 0, -44)]:
		f["sway"].append(Rome.stone_pine(world, c + p, 1.1, leaves))
	for p: Vector3 in [Vector3(-10, 0, 30), Vector3(10, 0, 30), Vector3(-44, 0, -20), Vector3(44, 0, -24)]:
		f["sway"].append(Kit.cypress(world, c + p, 8.0, leaves))
	f["sway"].append(Rome.pergola(world, c + Vector3(0, 0, 14), 0.0, 10.0, leaves))
	Kit.stream(world, c + Vector3(0, 0, 10), c + Vector3(0, 0, -12), 1.6, b.has("water"))
	Kit.cylinder(world, c + Vector3(0, 0, -16), 6.0, 0.4, "marble", true, 16)
	Kit.cylinder(world, c + Vector3(0, 0.4, -16), 5.4, 0.1, "water" if b.has("water") else "drybed", false, 16)
	Kit.bench(world, c + Vector3(6.0, 0, 22.0), PI)
	var virgil := PG._teacher(world, room, b, stage, c + Vector3(6.0, 0, 21.4), 0.0, c + Vector3(6.0, 0, 24.4), f["out"], f["spots"])
	_study(world, room, f, Vector3(6.0, 0, 21.4), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(-8.0, 0, 24.0), Vector3(0, 0, -1), "Sit under the vine and look over the city"))
	for p: Vector3 in [Vector3(-14, 0, 10), Vector3(14, 0, 8), Vector3(-6, 0, -30), Vector3(6, 0, -30)]:
		_lamp(world, f, c + p)

	# Troy burning: a wall and gate, the fires, Anchises waiting, the boy, Creusa behind
	Greek.troy_wall(world, c + Vector3(-34, 0, -10), 0.0, 20.0, true, whole)
	if b.has("lamps"):
		for p: Vector3 in [Vector3(-40, 5, -12), Vector3(-30, 4.5, -11), Vector3(-26, 3, -14)]:
			Kit.blob(world, c + p, 1.2, "fire", Vector3(1.0, 2.0, 1.0), 5)
		var glow := OmniLight3D.new()
		glow.position = c + Vector3(-34, 4, -8)
		glow.light_color = Color("ff8a30")
		glow.omni_range = 18.0
		glow.light_energy = 1.6
		world.add_child(glow)
		f["flicker"].append(glow)
	var anchises := _person(world, f, c + Vector3(-33.0, 0, -4.0), c + Vector3(-33, 0, 6), "anchises", "household", "sit")
	var ascanius := _person(world, f, c + Vector3(-31.4, 0, -3.0), c + Vector3(-33, 0, 6), "ascanius")
	var creusa := _person(world, f, c + Vector3(-35.0, 0, -6.0), c + Vector3(-33, 0, 6), "creusa")

	# Dido's pyre by the pool
	var pyre := Props.pyre(world, c + Vector3(16, 0, -16), 0.3, b.has("lamps"), false, 1.2)
	if pyre:
		f["flicker"].append(pyre)
	_person(world, f, c + Vector3(16.0, 0, -12.0), c + Vector3(16, 0, -16), "dido")

	# the dark grove: the bough on its tree, the Sibyl, the way down
	for p: Vector3 in [Vector3(-26, 0, -34), Vector3(-30, 0, -40), Vector3(-20, 0, -40), Vector3(-34, 0, -30)]:
		f["sway"].append(Kit.olive(world, c + p, 1.4, leaves))
	var tree := Kit.olive(world, c + Vector3(-26, 0, -42), 1.6, leaves)
	f["sway"].append(tree)
	var bough := Kit.group(world, c + Vector3(-25.2, 3.2, -41.2))
	Kit.box(bough, Vector3.ZERO, Vector3(0.04, 1.0, 0.04), "gold", false, Vector3(0.3, 0, 0.5))
	for k in 4:
		Kit.blob(bough, Vector3(0.1 * k - 0.15, 0.2 + k * 0.18, 0.1), 0.1, "gold", Vector3(1.8, 0.4, 1.0), 5)
	Kit.unsolid(bough)
	_person(world, f, c + Vector3(-22.0, 0, -36.0), c + Vector3(-26, 0, -42), "sibyl")
	var mouth := Kit.group(world, c + Vector3(-36, 0, -46), PI * 0.75)
	Urbs.cave(mouth)

	# the souls of Rome to come, in a row, Anchises before them
	for k in 7:
		var p := c + Vector3(20.0 + k * 2.2, 0, -36.0)
		var s := Places._figure(world, p, PI, "#d8d4e8", 1.0)
		Kit.shade(s, 0.45 if b.has("household") else 0.25)
	_person(world, f, c + Vector3(26.0, 0, -31.0), c + Vector3(26, 0, -36), "anchises")

	# the duelling ground: Turnus on his knees
	Kit.cylinder(world, c + Vector3(0, 0, -34), 7.0, 0.06, "sand", false, 16)
	var turnus := _person(world, f, c + Vector3(0, 0, -36.0), c + Vector3(0, 0, -30), "turnus", "household", "kneel")

	# the six points
	_stele_stone(world, f, work, room, "arms_and_the_man", c + Vector3(3.6, 0, 34.0), c + Vector3(0, 0, 34), "Read the poem's first line")
	_stele_stone(world, f, work, room, "dido", c + Vector3(12.0, 0, -10.0), c + Vector3(16, 0, -16), "Look at Dido's pyre")
	_stele_stone(world, f, work, room, "rome_to_come", c + Vector3(26.0, 0, -27.0), c + Vector3(26, 0, -36), "Look at the souls to come")
	_beat(f, work, room, "troy", "out_of_troy", c + Vector3(-33.0, 0, 2.0), c + Vector3(-33, 0, -4), "Carry your father out of Troy, as Aeneas",
		{"anchises": anchises["root"], "ascanius": ascanius["root"], "creusa": creusa["root"]},
		{"father": c + Vector3(-33.0, 0, -2.6), "gate": c + Vector3(-33.0, 0, 12.0), "creusa": c + Vector3(-35.0, 0, -6.0)})
	_beat(f, work, room, "golden_bough", "the_bough", c + Vector3(-22.0, 0, -32.0), c + Vector3(-26, 0, -42), "Find the golden bough, as Aeneas",
		{"bough": bough}, {"tree": c + Vector3(-25.0, 0, -40.0), "mouth": c + Vector3(-34.0, 0, -44.0), "sibyl": c + Vector3(-22.0, 0, -36.0)})
	_beat(f, work, room, "turnus", "the_belt", c + Vector3(0, 0, -30.0), c + Vector3(0, 0, -36), "Stand over Turnus, as Aeneas",
		{"turnus": turnus["root"]}, {"belt": c + Vector3(0, 1.0, -36.0)})
	return _done(room, f, virgil)


# ---------- Lucretius: a garden by the Colline Gate ----------

## A walled garden on the Quirinal about 55 BC: a vine pergola and a bench, a basin where drops
## fall and hollow the stone, a shrine of Venus; a dark room with one slit of light and the motes
## dancing in its beam; the altar at Aulis with Iphigenia before it; shelves of jars for the
## first-beginnings and the empty spaces between them; beyond the wall the road of tombs, and
## Nature on her seat rebuking the mourner. Lost: the vine withered, the basin dry, the beam gone.
static func hortus_collinus(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "noon", "collina", "republic", -55, [380, 900], Vector2(92, 92), "earth")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	var leaves := b.has("leaves")
	_gate(world, room, f, Vector3(0, 0, 40), Vector3(0, 0, 20), "path")

	# the garden wall, the pergola, the bench, the basin
	for spec: Array in [[Vector3(0, 0, -22), Vector3(40, 2.6, 0.5)], [Vector3(-20, 0, 0), Vector3(0.5, 2.6, 44)], [Vector3(20, 0, 0), Vector3(0.5, 2.6, 44)]]:
		var at: Vector3 = spec[0]
		var size: Vector3 = spec[1]
		Kit.box(world, c + at + Vector3(0, size.y / 2.0, 0), size, "plaster" if whole else "ashbed")
	f["sway"].append(Rome.pergola(world, c + Vector3(-6, 0, 8), 0.0, 8.0, leaves))
	Kit.bench(world, c + Vector3(-6.0, 0, 8.6), PI)
	var lucretius := PG._teacher(world, room, b, stage, c + Vector3(-6.0, 0, 8.0), 0.0, c + Vector3(-6.0, 0, 11.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(-6.0, 0, 8.0), 0.0)
	Kit.cylinder(world, c + Vector3(8, 0, 2), 1.4, 0.5, "travertine", true, 12)
	Kit.cylinder(world, c + Vector3(8, 0.5, 2), 1.2, 0.08, "water" if b.has("water") else "drybed", false, 12)
	if b.has("water"):
		f["flicker"].append(Rome.jet(world, c + Vector3(8, 2.2, 2), Vector3(0, -1, 0), 2.0, 6))
	f["out"].append(Places.seat(world, c + Vector3(4.0, 0, 12.0), Vector3(0, 0, -1), "Sit in the garden"))
	Props.shrine(world, c + Vector3(14, 0, 14), -PI / 2.0, "aphrodite", whole)
	for p: Vector3 in [Vector3(-14, 0, 14), Vector3(14, 0, -16)]:
		_lamp(world, f, c + p)
	_person(world, f, c + Vector3(2.0, 0, 6.0), c + Vector3(-6, 0, 8), "memmius")

	# the dark room with its beam
	var dark := Kit.group(world, c + Vector3(14, 0, -10), 0.0)
	for spec: Array in [[Vector3(0, 1.8, -4), Vector3(9, 3.6, 0.4)], [Vector3(-4.5, 1.8, 0), Vector3(0.4, 3.6, 8)], [Vector3(4.5, 1.8, 0), Vector3(0.4, 3.6, 8)],
			[Vector3(-3, 1.8, 4), Vector3(3.4, 3.6, 0.4)], [Vector3(3, 1.8, 4), Vector3(3.4, 3.6, 0.4)]]:
		var at: Vector3 = spec[0]
		var size: Vector3 = spec[1]
		Kit.box(dark, at, size, "dark" if whole else "ashbed")
	Kit.box(dark, Vector3(0, 3.7, 0), Vector3(9.4, 0.3, 8.4), "roof", false)
	if b.has("lamps"):
		Kit.box(dark, Vector3(0, 2.0, -1.0), Vector3(0.5, 0.5, 6.0), "beam_faint", false, Vector3(0.6, 0, 0))
		Kit.fireflies(dark, Vector3(0, 1.4, 0), 2.6)

	# the altar at Aulis
	var altar := Greek.altar(world, c + Vector3(-12, 0, -12), 0.0, "greek", b.has("lamps"), whole)
	if altar:
		f["flicker"].append(altar)
	_person(world, f, c + Vector3(-12.0, 0, -10.0), c + Vector3(-12, 0, -12), "iphigenia")
	_person(world, f, c + Vector3(-14.5, 0, -10.6), c + Vector3(-12, 0, -12), "calchas")
	_person(world, f, c + Vector3(-9.5, 0, -10.6), c + Vector3(-12, 0, -12), "agamemnon")

	# the shelves of jars: the first-beginnings, and the void between them
	for k in 3:
		Kit.box(world, c + Vector3(-16.0, 0.4 + k * 0.9, 4.0), Vector3(0.3, 0.05, 5.0), "wood", false)
		for j in 5:
			if (k + j) % 3 != 1:
				Kit.amphora(world, c + Vector3(-16.0, 0.42 + k * 0.9, 2.0 + j * 1.0), 0.0)

	# beyond the wall: the road of tombs, and Nature on her seat
	for k in 3:
		Rome.tomb(world, c + Vector3(-10.0 + k * 10.0, 0, -32.0), 0.0, ["altar", "aedicula", "altar"][k], whole,
			["VIXI", "FUI NON SUM NON CURO", "SOMNO AETERNO"][k])
	Kit.box(world, c + Vector3(0, 0.25, -34.5), Vector3(2.2, 0.5, 0.9), "stone")
	Kit.box(world, c + Vector3(24, 0.6, -30), Vector3(2.4, 1.2, 1.6), "marble")
	_person(world, f, c + Vector3(24.0, 1.2, -30.0), c + Vector3(24, 0, -20), "natura", "household", "sit")

	# the six points
	_stele_stone(world, f, work, room, "venus", c + Vector3(14.0, 0, 11.0), c + Vector3(14, 0, 14), "Read the hymn to Venus")
	_stele_stone(world, f, work, room, "religio", c + Vector3(-12.0, 0, -7.0), c + Vector3(-12, 0, -12), "Look at the altar at Aulis")
	_stele_stone(world, f, work, room, "nothing", c + Vector3(-13.0, 0, 4.0), c + Vector3(-16, 0, 4), "Look at the jars and the spaces")
	_stele_stone(world, f, work, room, "nature_speaks", c + Vector3(24.0, 0, -26.0), c + Vector3(24, 0, -30), "Hear Nature's rebuke")
	_beat(f, work, room, "atoms", "the_sunbeam", c + Vector3(14.0, 0, -4.0), c + Vector3(14, 0, -10), "Go into the dark room", {},
		{"door": c + Vector3(14.0, 0, -5.0), "inside": c + Vector3(14.0, 0, -10.0), "beam": c + Vector3(14.0, 2.0, -11.0)})
	_beat(f, work, room, "death", "nothing_to_us", c + Vector3(0, 0, -28.0), c + Vector3(0, 0, -34), "Lie down among the tombs", {},
		{"slab": c + Vector3(0, 0, -33.4), "tombs": c + Vector3(-10, 0, -32), "sky": c + Vector3(0, 40, -34)})
	return _done(room, f, lucretius)


# ---------- Cicero, On Duties: the Rostra and his house ----------

## The Forum in 44 BC on the city's own ground: the Rostra with the ships' beaks, the Senate House
## and the Comitium, the basilicas, the Temple of Castor, the crowd; the four stones of the
## honourable before the Rostra; the gate at the Forum's end with the Carthaginian envoys, where
## Regulus walks out; up the Via Nova Cicero's house with its atrium, his desk and his son's
## letters, a mask on a stand, and in its garden Laelius on his bench with his sons-in-law.
## Lost: the Rostra broken, the Forum unpaved, the crowd shades.
static func rostra_ciceronis(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "morning", "palatine_forum", "republic", -44, [60, -70], Vector2(1, 1), "basalt")
	var b: Array = f["b"]
	var whole: bool = f["whole"]
	var at := func(e: float, n: float) -> Vector3: return RomeMap.at([e, n])
	# the way in: along the Sacred Way from the Forum's east end, on the flat
	var gate: Vector3 = at.call(170.0, -40.0)
	var gate_to: Vector3 = at.call(120.0, -30.0)
	f["c"] = Vector3.ZERO
	_gate(world, room, f, gate, gate_to)
	Rome.via(world, gate_to, RomeMap.landmark("regia"), 4.2, whole)
	Rome.via(world, RomeMap.landmark("regia"), RomeMap.landmark("temple_of_saturn"), 4.2, whole)
	PG._forum(world, b, f["flicker"], f["people"])

	# Cicero on the Rostra, the crowd before it
	var rostra: Vector3 = RomeMap.landmark("rostra")
	var speaker := Rome.rostra(world, rostra, Kit.face_yaw(rostra, at.call(0.0, 0.0)), whole)
	var cicero := PG._teacher(world, room, b, stage, speaker, Kit.face_yaw(rostra, at.call(0.0, 0.0)), speaker + (at.call(0.0, 0.0) - rostra).normalized() * 4.0,
		f["out"], f["spots"])
	for k in 8:
		var p: Vector3 = speaker + (at.call(0.0, 0.0) - rostra).normalized() * (6.0 + (k % 3) * 2.5) + Vector3(-7.0 + k * 2.0, 0, 0)
		_citizen(world, f, p, speaker, {"beard": "short" if k % 2 else "none", "hair_color": ["3a2a1e", "5a4a3a", "8a8278"][k % 3]})
	f["out"].append(Places.seat(world, at.call(-30.0, -20.0), Vector3(1, 0, 0), "Sit on the basilica's steps and watch the Forum"))

	# the four stones of the honourable, in a row before the Rostra
	var front: Vector3 = speaker + (at.call(0.0, 0.0) - rostra).normalized() * 12.0
	for k in 4:
		var p := front + Vector3(-5.4 + k * 3.6, 0, 0)
		Kit.box(world, p + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.6), "marble")
		Rome.inscription(world, p + Vector3(0, 1.0, 0.31), [["SAPIENTIA", "IUSTITIA", "FORTITUDO", "DECORUM"][k]], 28, "8a2a1a")

	# the gate on the Forum's south side, and the Carthaginians waiting beyond it
	var east: Vector3 = at.call(-30.0, -80.0)
	var east_yaw := Kit.face_yaw(east, at.call(0.0, 0.0))
	var light := Rome.gateway(world, east, east_yaw, true)
	if light:
		f["flicker"].append(light)
	var beyond: Vector3 = east + (east - at.call(0.0, 0.0)).normalized() * 8.0
	for k in 3:
		_person(world, f, beyond + Vector3(-2.0 + k * 2.0, 0, 0), east, "carthaginian")
	var regulus := _person(world, f, east + (at.call(0.0, 0.0) - east).normalized() * 6.0, east, "regulus")

	# Cicero's house on the Via Nova, under the Palatine
	var hg := Kit.group(world, RomeMap.landmark("via_nova_houses"), PI)
	var w := func(local: Vector3) -> Vector3: return hg.transform * local
	Kit.box(hg, Vector3(0, 0.01, 12.0), Vector3(58.0, 0.02, 4.0), "basalt", false)  # the Via Nova
	Rome.atrium(hg, Vector3.ZERO, 0.0, b.has("water"))
	var desk := Kit.desk(hg, Vector3(0, 0, -8.3), PI, false, b.has("lamps"))
	if desk:
		f["flicker"].append(desk)
	Rome.capsa(hg, Vector3(1.3, 0, -9.4), whole)
	Rome.lararium(hg, Vector3(-5.6, 0, -1.5), PI / 2.0, b.has("household"))
	for x: float in [-4.6, 4.6]:
		_lamp(world, f, w.call(Vector3(x, 0, 2.8)))
	f["c"] = Vector3.ZERO
	var statues: Array = room.get("statues", [])
	for k in mini(statues.size(), 2):
		var bp: Vector3 = w.call(Vector3(-4.6 + k * 9.2, 0, -5.8))
		Kit.bust(world, bp, PI, statues[k])
		f["out"].append({"kind": "statue", "pos": w.call(Vector3(-4.6 + k * 9.2, 0, -4.2)), "text": "Look at the bust of %s" % statues[k]["name"],
			"note": statues[k]["note"]})
		f["spots"]["statue%d" % k] = w.call(Vector3(-4.6 + k * 9.2, 0, -4.2))
	var tex := load("res://assets/maps/%s.png" % room.get("map", "44bc")) as Texture2D
	if tex:
		Kit.board(world, w.call(Vector3(-3.9, 2.3, 6.95)), 0.0, Vector2(2.9, 2.0), tex)
		f["out"].append({"kind": "map", "pos": w.call(Vector3(-3.9, 0, 5.4)), "map": room["map"], "text": "Study the map of the world in 44 BC",
			"note": room.get("map_note", "")})
		f["spots"]["map"] = w.call(Vector3(-3.9, 0, 5.4))
	Kit.box(hg, Vector3(3.9, 0.5, 5.6), Vector3(0.5, 1.0, 0.5), "wood")
	Kit.box(hg, Vector3(3.9, 1.05, 5.6), Vector3(0.45, 0.06, 0.6), "parchment", false)
	f["out"].append({"kind": "book", "pos": w.call(Vector3(3.9, 0, 4.4)), "text": "Read a page of On Duties"})
	f["spots"]["book"] = w.call(Vector3(3.9, 0, 4.4))
	Greek.mask(hg, Vector3(4.2, 1.2, -1.2), PI, "tragic", 0.9, whole)  # the actor's part (I.107)
	Kit.cylinder(hg, Vector3(4.2, 0, -1.2), 0.08, 1.2, "wood", false, 6)

	# the garden behind: Laelius on his bench with Fannius and Scaevola
	Kit.bench(hg, Vector3(-12.0, 0, 18.0), PI)
	var laelius := _person(world, f, w.call(Vector3(-12.0, 0, 17.4)), w.call(Vector3(-12.0, 0, 24.0)), "laelius", "household", "sit")
	_person(world, f, w.call(Vector3(-14.4, 0, 19.6)), w.call(Vector3(-12.0, 0, 17.4)), "fannius")
	_person(world, f, w.call(Vector3(-9.6, 0, 19.6)), w.call(Vector3(-12.0, 0, 17.4)), "senator")
	f["sway"].append(Rome.pergola(hg, Vector3(-12.0, 0, 22.0), 0.0, 6.0, b.has("leaves")))
	f["sway"].append(Rome.stone_pine(hg, Vector3(-20, 0, 20), 0.9, b.has("leaves")))

	# the six points
	_stele_stone(world, f, work, room, "honestum", front + Vector3(0, 0, 0) + (at.call(0.0, 0.0) - rostra).normalized() * 2.0, front,
		"Read the four stones of the honourable")
	_stele_stone(world, f, work, room, "justice", speaker + (at.call(0.0, 0.0) - rostra).normalized() * 3.0 + Vector3(6.0, 0, 0), speaker,
		"Read the foundation of justice")
	_stele_stone(world, f, work, room, "greatness", speaker + (at.call(0.0, 0.0) - rostra).normalized() * 3.0 + Vector3(-6.0, 0, 0), speaker,
		"Read of greatness of spirit")
	_stele_stone(world, f, work, room, "decorum", w.call(Vector3(4.2, 0, -3.0)), w.call(Vector3(4.2, 0, -1.2)), "Look at the actor's mask")
	_stele_stone(world, f, work, room, "friendship", w.call(Vector3(-12.0, 0, 21.0)), w.call(Vector3(-12.0, 0, 17.4)), "Listen to Laelius")
	_beat(f, work, room, "regulus", "regulus_goes_back", east + (at.call(0.0, 0.0) - east).normalized() * 10.0, east, "Keep your word, as Regulus",
		{"regulus": regulus["root"], "laelius": laelius["root"]}, {"gate": east, "beyond": beyond, "senate": RomeMap.landmark("curia_and_comitium")})
	return _done(room, f, cicero)


# ---------- Cicero, the Dream of Scipio: the Arx at night ----------

## The Capitol's northern height about 51 BC, at night: the Temple of Juno Moneta, the augurs'
## square, the oaks, a spring below; Masinissa's couch under an awning with the old king and young
## Scipio talking; and hung over the hill the nine spheres, rings of light round a small earth,
## with Africanus standing in his light beneath them. Lost: the sky ashen and starless, the
## spheres dark, the spring dry.
static func arx(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "twilight", "capitolium", "republic", -51, [-157, 150], Vector2(84, 84), "paving", true)
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 36), Vector3(0, 0, 16))

	# the temple, the augurs' square, the oaks, the spring
	Rome.temple(world, c + Vector3(0, 0, -20), 0.0, whole, "republican")
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		Kit.box(world, c + Vector3(-20 + cos(a) * 4.0, 0.3, -2 + sin(a) * 4.0), Vector3(0.8, 0.6, 0.8), "tufa")
	Kit.box(world, c + Vector3(-20, 0.03, -2), Vector3(7.0, 0.06, 7.0), "stone", false)
	for p: Vector3 in [Vector3(-30, 0, 10), Vector3(28, 0, 12), Vector3(30, 0, -14), Vector3(-30, 0, -24)]:
		f["sway"].append(Kit.plane_tree(world, c + p, 1.1, b.has("leaves")))
	Rome.spring(world, c + Vector3(-30, 0, 26), b.has("water"))
	for p: Vector3 in [Vector3(-8, 0, 8), Vector3(8, 0, 8), Vector3(-12, 0, -8), Vector3(12, 0, -8)]:
		_lamp(world, f, c + p)
	Kit.box(world, c + Vector3(6.0, 0.25, 8.0), Vector3(0.9, 0.5, 0.7), "stone")
	var cicero := PG._teacher(world, room, b, stage, c + Vector3(6.0, 0, 8.2), 0.0, c + Vector3(6.0, 0, 11.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(6.0, 0, 8.2), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(-34.0, 0, 34.0), Vector3(-1, 0, 1), "Sit at the edge and look down at the city"))

	# Masinissa's couch under its awning, the old king and the young officer
	var awning := Kit.group(world, c + Vector3(22, 0, 2), -PI / 2.0)
	for p: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		Kit.cylinder(awning, p, 0.08, 3.0, "wood", false, 6)
	Kit.box(awning, Vector3(0, 3.05, 0), Vector3(7.0, 0.08, 7.0), "awning", false)
	Greek.kline(awning, Vector3(0, 0, -1.0), 0.0, whole)
	_person(world, f, c + Vector3(22.0, 0.45, 1.0), c + Vector3(22, 0, 8), "masinissa", "household", "recline")
	_person(world, f, c + Vector3(22.0, 0, 4.0), c + Vector3(22, 0, 1), "scipio_young", "household", "sit")

	# the nine spheres over the hill, the earth at their centre, Africanus beneath them
	var spheres := Kit.group(world, c + Vector3(0, 22, -32))
	spheres.rotation.x = 0.55
	for k in 9:
		var r := 3.0 + k * 2.4
		Kit.mesh(spheres, TorusMesh.new(), "glow" if b.has("lamps") else "glow_cold", Vector3.ZERO, Vector3(PI / 2.0, 0, 0), Vector3(r, r, r) * 0.5)
	Kit.blob(spheres, Vector3.ZERO, 1.1, "#4a6a8a", Vector3.ONE, 10)
	Kit.unsolid(spheres)
	var africanus := _person(world, f, c + Vector3(0, 0, -30.0), c + Vector3(0, 0, 0), "africanus")
	if b.has("lamps"):
		var glow := OmniLight3D.new()
		glow.position = c + Vector3(0, 2.5, -30)
		glow.light_color = Color("e8e8ff")
		glow.omni_range = 14.0
		glow.light_energy = 1.4
		world.add_child(glow)
		f["flicker"].append(glow)

	# the six points
	_stele_stone(world, f, work, room, "the_dream", c + Vector3(22.0, 0, 8.0), c + Vector3(22, 0, 1), "Listen at Masinissa's couch")
	_stele_stone(world, f, work, room, "reward", c + Vector3(0, 0, -26.0), c + Vector3(0, 0, -30), "Hear Africanus's promise")
	_stele_stone(world, f, work, room, "spheres", c + Vector3(-6.0, 0, -14.0), c + Vector3(0, 22, -32), "Look up at the spheres")
	_stele_stone(world, f, work, room, "fame", c + Vector3(-30.0, 0, 30.0), c + Vector3(-60, 0, 60), "Look down at the city")
	_stele_stone(world, f, work, room, "soul", c + Vector3(6.0, 0, -8.0), c + Vector3(0, 0, -20), "Read what moves itself")
	_beat(f, work, room, "ascent", "the_ascent", c + Vector3(0, 0, -22.0), c + Vector3(0, 0, -30), "Go up among the stars, as Scipio",
		{"africanus": africanus["root"]}, {"earth": c + Vector3(0, 22, -32), "city": c + Vector3(-80, -10, 90), "sky": c + Vector3(0, 60, -40)})
	return _done(room, f, cicero)


# ---------- Ovid: a garden across the Tiber ----------

## A garden under the Janiculum in AD 8: a laurel at its heart with Daphne half in its bark and
## Apollo reaching; a pool for the flood with Deucalion and Pyrrha and their stones; four stones
## for the ages; a cave for the way down, with Eurydice behind Orpheus; Orpheus's hill with the
## trees come to listen; and Pygmalion's workshop with the ivory girl on her stand. Lost: the
## laurel dead, the pool dry, the workshop dark.
static func horti_transtiberini(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "golden", "trans_tiberim", "republic", 8, [-1500, -330], Vector2(100, 100), "earth")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	var leaves := b.has("leaves")
	_gate(world, room, f, Vector3(0, 0, 42), Vector3(0, 0, 22), "path")
	if leaves:
		f["birds"] = Kit.flock(world, c, 5, 18.0, 12.0)

	# the laurel, Daphne and Apollo; Ovid by a bench
	var laurel := Kit.olive(world, c + Vector3(0, 0, -4), 1.5, leaves)
	f["sway"].append(laurel)
	var daphne := _person(world, f, c + Vector3(0.6, 0, -2.6), c + Vector3(0, 0, -4), "daphne")
	Kit.box(daphne["root"], Vector3(0, 0.6, 0), Vector3(0.5, 1.2, 0.5), "bark", false)  # the bark closing round her
	var apollo := _person(world, f, c + Vector3(3.6, 0, 1.0), c + Vector3(0.6, 0, -2.6), "apollo")
	Kit.bench(world, c + Vector3(-8.0, 0, 14.0), PI)
	var ovid := PG._teacher(world, room, b, stage, c + Vector3(-8.0, 0, 13.4), 0.0, c + Vector3(-8.0, 0, 16.4), f["out"], f["spots"])
	_study(world, room, f, Vector3(-8.0, 0, 13.4), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(6.0, 0, 16.0), Vector3(0, 0, -1), "Sit and look at the laurel"))
	for p: Vector3 in [Vector3(-16, 0, 6), Vector3(16, 0, 6)]:
		_lamp(world, f, c + p)

	# the flood: a pool, the two left, and the stones they throw
	Kit.cylinder(world, c + Vector3(-26, 0, -8), 9.0, 0.3, "stone", true, 16)
	Kit.cylinder(world, c + Vector3(-26, 0.3, -8), 8.4, 0.08, "water" if b.has("water") else "drybed", false, 16)
	_person(world, f, c + Vector3(-26.0, 0, 3.0), c + Vector3(-26, 0, 10), "deucalion")
	_person(world, f, c + Vector3(-23.6, 0, 3.4), c + Vector3(-23.6, 0, 10), "pyrrha")
	for k in 6:
		Kit.rock(world, c + Vector3(-28.0 + k * 1.4, 0, 7.0 + (k % 2) * 1.2), 0.3)
	for k in 2:
		var s := Places._figure(world, c + Vector3(-27.0 + k * 2.0, 0, 10.0), PI, "#8a8278", 0.6 + k * 0.2)
		Kit.shade(s, 0.6)

	# the four ages on four stones
	for k in 4:
		var p := c + Vector3(16.0 + k * 2.6, 0, 20.0)
		Kit.box(world, p + Vector3(0, 0.9, 0), Vector3(0.7, 1.8, 0.3), ["gold", "marble", "bronze", "iron"][k], false)

	# the way down: a cave, Eurydice behind Orpheus
	var cave := Greek.cave(world, c + Vector3(28, 0, -22), -PI / 2.0, b.has("lamps"))
	var cr: Node3D = cave["root"]
	var eurydice := _person(world, f, cr.transform * Vector3(0, 0, -6.0), cr.transform * Vector3(0, 0, 10.0), "eurydice")
	Kit.shade(eurydice["root"], 0.5)

	# Orpheus's hill, the trees gathered round
	Kit.hill(world, c + Vector3(26, 0, -42), 10.0, 3.0, "grass")
	for k in 6:
		var a := TAU * k / 6.0
		f["sway"].append(Kit.plane_tree(world, c + Vector3(26 + cos(a) * 12.0, 0, -42 + sin(a) * 12.0), 0.9, leaves))

	# Pygmalion's workshop: the ivory girl on her stand, the tools
	var shop := Kit.group(world, c + Vector3(-28, 0, -32), PI / 2.0)
	Kit.box(shop, Vector3(0, 2.0, -4.0), Vector3(10.0, 4.0, 0.4), "plaster" if whole else "ashbed")
	for x: float in [-5.0, 5.0]:
		Kit.box(shop, Vector3(x, 2.0, 0), Vector3(0.4, 4.0, 8.0), "plaster" if whole else "ashbed")
	if whole:
		Kit.box(shop, Vector3(0, 4.2, 0), Vector3(10.6, 0.4, 8.6), "roof", false)
	Kit.cylinder(shop, Vector3(0, 0, -1.5), 0.7, 0.4, "marble", true, 12)
	var statue := Places._figure(shop, Vector3(0, 0.4, -1.5), 0.0, "#f2f0ea", 1.0)
	var girl := _person(world, f, c + Vector3(-28.0, 0.4, -30.5), c + Vector3(-28, 0, -20), "galatea")
	girl["root"].visible = false
	Kit.table(shop, Vector3(3.5, 0, 1.0), 0.0)
	_lamp(world, f, c + Vector3(-25.0, 0, -29.0))

	# the six points
	_stele_stone(world, f, work, room, "chaos", c + Vector3(3.6, 0, 30.0), c + Vector3(0, 0, 30), "Read how it began")
	_stele_stone(world, f, work, room, "ages", c + Vector3(20.0, 0, 23.0), c + Vector3(20, 0, 20), "Read the four ages")
	_stele_stone(world, f, work, room, "flood", c + Vector3(-25.0, 0, 6.0), c + Vector3(-26, 0, 3), "Watch the stones soften")
	_beat(f, work, room, "daphne", "daphne", c + Vector3(3.6, 0, 1.0), c + Vector3(0.6, 0, -2.6), "Reach for Daphne, as Apollo",
		{"daphne": daphne["root"], "apollo": apollo["root"]}, {"her": c + Vector3(1.8, 0, -1.0), "tree": c + Vector3(0, 4, -4)})
	_beat(f, work, room, "orpheus", "looking_back", cr.transform * Vector3(0, 0, -4.0), cr.transform * Vector3(0, 0, 12.0),
		"Lead Eurydice up, as Orpheus", {"eurydice": eurydice["root"]},
		{"up": [cr.transform * Vector3(0, 0, 4.0), cr.transform * Vector3(0, 0, 11.0)], "light": cr.transform * Vector3(0, 0, 16.0),
		"eurydice": cr.transform * Vector3(0, 0, -6.0)})
	_beat(f, work, room, "pygmalion", "the_ivory_girl", c + Vector3(-28.0, 0, -27.5), c + Vector3(-28, 0, -30.5), "Touch the ivory, as Pygmalion",
		{"statue": statue, "girl": girl["root"]}, {"stand": c + Vector3(-28.0, 0, -28.6)})
	return _done(room, f, ovid)


# ---------- Tacitus: the house of Agricola ----------

## The Quirinal in AD 98: Agricola's house with the wax masks of the ancestors in its atrium and
## his own among them, Tacitus at his desk with the map; in the garden a bath and a toga on a
## stand (what the Britons took for civilisation); on the terrace a model of Mons Graupius, the
## Caledonians on the hill and the legion drawn up below; and in the street the statue of
## Domitian, three times a man's height. Lost: the masks broken, the hill bare, the legion shades.
static func domus_agricolae(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "noon", "collina", "empire", 98, [600, 1080], Vector2(96, 96), "paving")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 42), Vector3(0, 0, 22))

	# the house: the atrium, the masks, the desk and the map
	var hg := Kit.group(world, c + Vector3(0, 0, 0), 0.0)
	var w := func(local: Vector3) -> Vector3: return hg.transform * local
	Rome.atrium(hg, Vector3.ZERO, 0.0, b.has("water"))
	for k in 5:
		var m := Greek.mask(hg, Vector3(-4.0 + k * 2.0, 1.6, -6.6), 0.0, "tragic", 0.7, b.has("walkway"))
		m.name = "imago%d" % k
	Kit.box(hg, Vector3(0, 1.2, -6.6), Vector3(10.0, 0.08, 0.4), "wood", false)  # the shelf of the ancestors
	for x: float in [-5.0, 5.0]:
		_lamp(world, f, w.call(Vector3(x, 0, -6.0)))
	var tacitus := PG._teacher(world, room, b, stage, w.call(Vector3(0, 0, -8.6)), 0.0, w.call(Vector3(0, 0, -5.6)), f["out"], f["spots"])
	var desk := Kit.desk(hg, Vector3(0, 0, -9.4), PI, false, b.has("lamps"))
	if desk:
		f["flicker"].append(desk)
	_study(world, room, f, Vector3(0, 0, -8.6), 0.0)
	Rome.lararium(hg, Vector3(5.6, 0, -1.5), -PI / 2.0, b.has("household"))
	f["out"].append(Places.seat(world, c + Vector3(-12.0, 0, 16.0), Vector3(0, 0, -1), "Sit in the garden"))

	# the garden: a bath, a toga on a stand
	Props.bath(world, c + Vector3(-22, 0, -6), 0.0, whole)
	Kit.cylinder(world, c + Vector3(-22, 0, 2), 0.08, 1.8, "wood", false, 6)
	Kit.box(world, c + Vector3(-22, 1.2, 2), Vector3(0.9, 1.2, 0.3), "toga", false)
	for p: Vector3 in [Vector3(-30, 0, 12), Vector3(-30, 0, -14)]:
		f["sway"].append(Kit.plane_tree(world, c + p, 1.0, b.has("leaves")))

	# the terrace: the hill of Mons Graupius, the Caledonians on it, the legion below
	Kit.hill(world, c + Vector3(28, 0, -22), 14.0, 5.0, "grass" if b.has("leaves") else "earth")
	for k in 7:
		var a := -PI * 0.4 + k * PI * 0.8 / 6.0
		_person(world, f, c + Vector3(28 + cos(a) * 8.0, 2.6, -22 + sin(a) * 8.0 + 2.0), c + Vector3(28, 0, 0), "briton", "soldiers")
	var legion := Rome.century(world, c + Vector3(28.0, 0, 0.0), 4, 7, not b.has("soldiers"))
	legion["root"].rotation.y = PI
	f["squads"].append(legion)
	Rome.aquila(world, c + Vector3(28.0, 0, 4.0), whole)

	# the street: Domitian's statue
	Kit.box(world, c + Vector3(-24, 1.0, 26), Vector3(3.0, 2.0, 3.0), "marble")
	_person(world, f, c + Vector3(-24.0, 2.0, 26.0), c + Vector3(0, 0, 26), "domitian", "walkway")

	# the six points
	_stele_stone(world, f, work, room, "memory", w.call(Vector3(0, 0, -4.4)), w.call(Vector3(0, 0, -6.6)), "Look at the masks of the ancestors")
	_stele_stone(world, f, work, room, "moderation", c + Vector3(-20.0, 0, 26.0), c + Vector3(-24, 0, 26), "Look up at Domitian")
	_stele_stone(world, f, work, room, "civilisation", c + Vector3(-22.0, 0, 6.0), c + Vector3(-22, 0, 2), "Look at the bath and the toga")
	_stele_stone(world, f, work, room, "mons_graupius", c + Vector3(16.0, 0, -8.0), c + Vector3(28, 0, -22), "Look at the hill and the legion")
	_stele_stone(world, f, work, room, "shade", w.call(Vector3(5.6, 0, 1.0)), w.call(Vector3(5.6, 0, -1.5)), "Read Tacitus's last words at the shrine")
	_beat(f, work, room, "calgacus", "a_desert_called_peace", c + Vector3(28.0, 0, -10.0), c + Vector3(28, 0, 0), "Speak to the Caledonians, as Calgacus",
		{"eagle": legion["root"]}, {"hill": c + Vector3(28.0, 0, -12.0), "legion": c + Vector3(28, 0, 0), "sky": c + Vector3(28, 40, -40)})
	return _done(room, f, tacitus)


# ---------- Epictetus: the house of Epaphroditus ----------

## The Subura about AD 90: a tenement over a lane, the master's room with its dining couches and
## the dishes going round, the stair, the slave's iron lamp on it, a jar on a shelf, two baskets on
## a table for sorting what is ours from what is not, a mask on a stand, and a fig in the court.
## Lost: the lamp out, the fig dead, the stair fallen, the guests shades.
static func insula_suburae(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "morning", "suburana", "empire", 90, [350, 0], Vector2(84, 84), "paving")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 38), Vector3(0, 0, 18))

	# the tenement, the lane, the stair up its side
	Rome.insula(world, c + Vector3(0, 0, -16), 0.0, 3, 16.0, whole)
	Rome.insula(world, c + Vector3(-22, 0, -16), 0.0, 4, 14.0, whole)
	Rome.insula(world, c + Vector3(22, 0, -16), 0.0, 3, 14.0, whole)
	for k in 6:
		Kit.box(world, c + Vector3(10.0, 0.15 + k * 0.3, -6.0 - k * 0.8), Vector3(1.6, 0.3, 0.8), "stone" if whole else "rubble")
	_lamp(world, f, c + Vector3(11.2, 1.6, -8.4))
	Kit.cylinder(world, c + Vector3(-6, 0, 2), 1.2, 0.5, "travertine", true, 12)
	Kit.cylinder(world, c + Vector3(-6, 0.5, 2), 1.0, 0.08, "water" if b.has("water") else "drybed", false, 12)
	f["sway"].append(Kit.olive(world, c + Vector3(-14, 0, 6), 1.1, b.has("leaves")))

	# Epictetus on his stool in the court, the baskets on their table, the jar
	Kit.box(world, c + Vector3(2.0, 0.22, 4.0), Vector3(0.5, 0.44, 0.5), "wood")
	var epictetus := PG._teacher(world, room, b, stage, c + Vector3(2.0, 0, 4.2), 0.0, c + Vector3(2.0, 0, 7.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(2.0, 0, 4.2), 0.0)
	Kit.table(world, c + Vector3(-6.0, 0, 10.0), 0.0)
	for x: float in [-0.5, 0.5]:
		Kit.cylinder(world, c + Vector3(-6.0 + x, 0.8, 10.0), 0.3, 0.3, "wicker", false, 10)
	Kit.box(world, c + Vector3(-14.0, 1.4, -2.0), Vector3(0.3, 0.05, 2.0), "wood", false)
	Kit.amphora(world, c + Vector3(-14.0, 1.42, -2.0), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(8.0, 0, 10.0), Vector3(0, 0, -1), "Sit in the court"))

	# the master's room: the couches, the dishes, the guests; and a mask for the actor's part
	var room_g := Kit.group(world, c + Vector3(-22, 0, 2), 0.0)
	Rome.triclinium(room_g, Vector3.ZERO, 0.0, whole)
	_person(world, f, c + Vector3(-22.0, 0.45, 0.0), c + Vector3(-22, 0, 6), "epaphroditus", "household", "recline")
	_person(world, f, c + Vector3(-24.4, 0.45, 1.0), c + Vector3(-22, 0, 6), "guest", "household", "recline")
	_person(world, f, c + Vector3(-19.6, 0.45, 1.0), c + Vector3(-22, 0, 6), "guest", "household", "recline")
	_person(world, f, c + Vector3(-22.0, 0, 5.0), c + Vector3(-22, 0, 0), "slave")
	Greek.mask(world, c + Vector3(16.0, 1.3, 4.0), PI, "comic", 0.9, whole)
	Kit.cylinder(world, c + Vector3(16.0, 0, 4.0), 0.08, 1.3, "wood", false, 6)
	_person(world, f, c + Vector3(0.0, 0, 24.0), c + Vector3(0, 0, 30), "slave")

	# the six points
	_stele_stone(world, f, work, room, "appearances", c + Vector3(3.0, 0, 24.0), c + Vector3(0, 0, 24), "Look at the man in the lane")
	_stele_stone(world, f, work, room, "given_back", c + Vector3(-11.0, 0, -2.0), c + Vector3(-14, 0, -2), "Look at the jar on its shelf")
	_stele_stone(world, f, work, room, "price", c + Vector3(12.0, 0, -4.0), c + Vector3(11.2, 1.6, -8.4), "Look at the lamp on the stair")
	_stele_stone(world, f, work, room, "banquet", c + Vector3(-22.0, 0, 8.0), c + Vector3(-22, 0, 0), "Watch the dishes go round")
	_stele_stone(world, f, work, room, "actor", c + Vector3(16.0, 0, 7.0), c + Vector3(16, 0, 4), "Look at the mask on its stand")
	_beat(f, work, room, "power", "ours_and_not_ours", c + Vector3(-6.0, 0, 13.0), c + Vector3(-6, 0, 10), "Sort what is ours from what is not", {},
		{"left": c + Vector3(-7.4, 0, 12.0), "right": c + Vector3(-4.6, 0, 12.0)})
	return _done(room, f, epictetus)


# ---------- Marcus Aurelius: a room of the palace ----------

## The Palatine about AD 175, before dawn: a wing of the palace, a room with a camp bed, a desk and
## the tablets in Greek by one lamp, the inner court with its fountain and laurels where he goes to
## retire into himself, the guards at the door and the secretary with the day's letters, a long
## wall with the names of the dead cut on it and fading, and the terrace's edge over the sleeping
## city. Lost: the lamp out, the court dry, the names worn away.
static func palatium(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "dusk", "palatina", "empire", 175, [234, -451], Vector2(100, 84), "marble", true)
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 38), Vector3(0, 0, 18))

	# the wing: a long hall of brick with columns, the room at its end
	var brick := "brick" if whole else "ashbed"
	Kit.box(world, c + Vector3(0, 5.0, -30), Vector3(60.0, 10.0, 0.8), brick)
	for x: float in [-30.0, 30.0]:
		Kit.box(world, c + Vector3(x, 5.0, -12), Vector3(0.8, 10.0, 36.0), brick)
	for k in 11:
		Rome.column(world, c + Vector3(-25.0 + k * 5.0, 0, 6.0), 8.0, 0.45, "marble")
	if whole:
		Kit.box(world, c + Vector3(0, 9.4, -12), Vector3(61.0, 0.8, 37.0), "roof", false)
	Kit.box(world, c + Vector3(-18, 2.0, -14), Vector3(0.6, 4.0, 32.0), brick)  # the room's wall
	Kit.bed(world, c + Vector3(-25, 0, -24), PI / 2.0)
	var desk := Kit.desk(world, c + Vector3(-24, 0, -16), -PI / 2.0, true, b.has("lamps"))
	if desk:
		f["flicker"].append(desk)
	for k in 3:
		Kit.box(world, c + Vector3(-24.0, 0.84, -16.6 + k * 0.5), Vector3(0.3, 0.02, 0.4), "parchment", false)
	var marcus := PG._teacher(world, room, b, stage, c + Vector3(-24.0, 0, -20.0), -PI / 2.0, c + Vector3(-21.0, 0, -20.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(-24.0, 0, -20.0), -PI / 2.0)
	_person(world, f, c + Vector3(-20.0, 0, -6.0), c + Vector3(-24, 0, -20), "secretary")
	for x: float in [-3.0, 3.0]:
		_person(world, f, c + Vector3(x, 0, 2.0), c + Vector3(0, 0, 20), "guard")
	_person(world, f, c + Vector3(10.0, 0, -8.0), c + Vector3(0, 0, -8), "slave")

	# the inner court: the fountain, the laurels, a bench
	Rome.fountain(world, c + Vector3(6, 0, -18), 0.0, b.has("water"))
	for p: Vector3 in [Vector3(0, 0, -24), Vector3(12, 0, -24), Vector3(0, 0, -12), Vector3(12, 0, -12)]:
		f["sway"].append(Kit.olive(world, c + p, 1.0, b.has("leaves")))
	Kit.bench(world, c + Vector3(6.0, 0, -13.0), PI)
	f["out"].append(Places.seat(world, c + Vector3(6.0, 0, -13.0), Vector3(0, 0, -1), "Sit by the fountain"))
	for p: Vector3 in [Vector3(-10, 0, -26), Vector3(20, 0, -26), Vector3(-10, 0, 2), Vector3(20, 0, 2)]:
		_lamp(world, f, c + p)

	# the wall of names, fading toward its end
	var names := ["CAMILLVS", "CAESO", "VOLESVS", "DENTATVS", "SCIPIO", "CATO", "AVGVSTVS", "HADRIANVS", "ANTONINVS"]
	for k in names.size():
		Rome.inscription(world, c + Vector3(-29.5, 2.0, -28.0 + k * 3.0), [names[k]], 30 - k * 2, "8a8274" if b.has("walkway") or k < 4 else "b8b4ae")

	# the terrace's edge over the city
	Kit.box(world, c + Vector3(0, 0.5, 30), Vector3(60.0, 1.0, 0.6), "marble", true)

	# the six points
	_stele_stone(world, f, work, room, "point", c + Vector3(-24.0, 0, -12.0), c + Vector3(-24, 0, -16), "Read the tablet on the desk")
	_stele_stone(world, f, work, room, "cosmopolis", c + Vector3(0, 0, 26.0), c + Vector3(0, 0, 60), "Look out over the city")
	_stele_stone(world, f, work, room, "fade", c + Vector3(-26.0, 0, -4.0), c + Vector3(-29.5, 2, -4), "Read the names on the wall")
	_stele_stone(world, f, work, room, "short_way", c + Vector3(0, 0, 10.0), c + Vector3(0, 0, 20), "Read the stone by the door")
	_beat(f, work, room, "dawn", "begin_the_morning", c + Vector3(-25.0, 0, -22.0), c + Vector3(-25, 0, -30), "Wake before dawn, as Marcus", {},
		{"bed": c + Vector3(-25.0, 0, -24.0), "door": c + Vector3(-18.0, 0, 4.0)})
	_beat(f, work, room, "retreat", "into_yourself", c + Vector3(6.0, 0, -9.0), c + Vector3(6, 0, -18), "Retire into yourself, as Marcus", {},
		{"bench": c + Vector3(6.0, 0, -13.0), "fountain": c + Vector3(6, 1, -18)})
	return _done(room, f, marcus)


# ---------- Seneca: the river port ----------

## The river port under the Aventine about AD 49: the quay with two barges at it, porters with
## sacks, the long granary with its rows of sacks and the measuring floor with the modius on it,
## Paulinus's office with its tallies, a sundial, and a row of the wise on their plinths with a
## bench before each. Lost: the river low and grey, the granary broken, the porters shades.
static func emporium(world: Node3D, work: String, room: Dictionary, stage: int) -> Dictionary:
	var f := _frame(world, room, stage, "noon", "aventinus", "empire", 49, [-370, -800], Vector2(112, 92), "paving")
	var b: Array = f["b"]
	var c: Vector3 = f["c"]
	var whole: bool = f["whole"]
	_gate(world, room, f, Vector3(0, 0, 42), Vector3(0, 0, 22))
	if b.has("sun"):
		f["birds"] = Kit.flock(world, c + Vector3(-40, 0, 0), 6, 20.0, 10.0)

	# the quay and the river, the barges, the porters
	Kit.box(world, c + Vector3(-52, -0.3, 0), Vector3(14.0, 0.2, 92.0), "water" if b.has("water") else "drybed", false)
	Kit.box(world, c + Vector3(-45, 0.3, 0), Vector3(1.0, 0.6, 92.0), "travertine", true)
	for k in 2:
		var boat := Kit.boat(world, c + Vector3(-50.0, -0.2, -20.0 + k * 30.0), 0.0)
		f["boats"] = f.get("boats", [])
		f["boats"].append(boat)
	for k in 4:
		var p := c + Vector3(-40.0 + k * 3.0, 0, 6.0 - k * 6.0)
		var w := _person(world, f, p, c + Vector3(0, 0, -20), "porter")
		Kit.blob(w["root"], Vector3(0, 1.9, 0), 0.32, "#c8b890", Vector3(1.6, 0.9, 1.0), 6)  # the sack on his shoulders

	# the granary, the sacks, the measuring floor
	var granary := Kit.group(world, c + Vector3(0, 0, -22), 0.0)
	Urbs.portico(granary, 0.8, b.has("walkway"))
	for k in 12:
		for j in 2:
			Kit.blob(world, c + Vector3(-20.0 + k * 3.6, 0.5, -26.0 + j * 2.4), 0.6, "#c8b890", Vector3(1.4, 0.9, 1.2), 6)
	Kit.box(world, c + Vector3(0, 0.02, -8), Vector3(10.0, 0.04, 10.0), "stone", false)
	Kit.cylinder(world, c + Vector3(0, 0, -8), 0.4, 0.5, "bronze", false, 10)  # the modius
	Kit.box(world, c + Vector3(-6.0, 0.4, 4.0), Vector3(1.6, 0.8, 4.0), "#c8b890", true)  # the sacks Seneca sits on
	var seneca := PG._teacher(world, room, b, stage, c + Vector3(-6.0, 0.8, 4.0), 0.0, c + Vector3(-6.0, 0, 7.0), f["out"], f["spots"])
	_study(world, room, f, Vector3(-6.0, 0, 4.0), 0.0)
	f["out"].append(Places.seat(world, c + Vector3(-40.0, 0, 20.0), Vector3(-1, 0, 0), "Sit on the quay and watch the river"))

	# Paulinus's office, the sundial
	var office := Kit.group(world, c + Vector3(26, 0, -4), -PI / 2.0)
	Kit.box(office, Vector3(0, 2.0, -4.0), Vector3(10.0, 4.0, 0.4), "brick" if whole else "ashbed")
	for x: float in [-5.0, 5.0]:
		Kit.box(office, Vector3(x, 2.0, 0), Vector3(0.4, 4.0, 8.0), "brick" if whole else "ashbed")
	if whole:
		Kit.box(office, Vector3(0, 4.2, 0), Vector3(10.6, 0.4, 8.6), "roof", false)
	var desk := Kit.desk(office, Vector3(0, 0, -1.5), 0.0, true, b.has("lamps"))
	if desk:
		f["flicker"].append(desk)
	_person(world, f, c + Vector3(26.0, 0, -5.0), c + Vector3(20, 0, -4), "paulinus", "household", "sit")
	_person(world, f, c + Vector3(26.0, 0, 0.0), c + Vector3(26, 0, -5), "clerk")
	_lamp(world, f, c + Vector3(23.0, 0, -7.0))
	Kit.cylinder(world, c + Vector3(10, 0, 14), 0.9, 0.9, "marble", true, 12)
	Kit.box(world, c + Vector3(10, 1.3, 14), Vector3(0.04, 0.8, 0.04), "bronze", false, Vector3(0, 0, 0.6))

	# the wise on their plinths, a bench before each
	for k in 4:
		var p := c + Vector3(-30.0, 0, 24.0 - k * 6.0)
		Kit.bust(world, p, PI / 2.0, {"beard": "long"})
		Kit.bench(world, p + Vector3(3.0, 0, 0), -PI / 2.0)
	_person(world, f, c + Vector3(-27.0, 0, 18.0), c + Vector3(-30, 0, 18), "sage", "household", "sit")

	# the six points
	_stele_stone(world, f, work, room, "long_enough", c + Vector3(-40.0, 0, 26.0), c + Vector3(-45, 0, 26), "Read the first words on the quay")
	_stele_stone(world, f, work, room, "preoccupied", c + Vector3(-32.0, 0, -4.0), c + Vector3(-40, 0, 0), "Watch the porters")
	_stele_stone(world, f, work, room, "present", c + Vector3(10.0, 0, 17.0), c + Vector3(10, 0, 14), "Read the sundial")
	_stele_stone(world, f, work, room, "the_wise", c + Vector3(-24.0, 0, 12.0), c + Vector3(-30, 0, 12), "Sit with the wise")
	_stele_stone(world, f, work, room, "withdraw", c + Vector3(20.0, 0, -4.0), c + Vector3(26, 0, -5), "Read what Seneca tells Paulinus")
	_beat(f, work, room, "ledger", "the_ledger_of_years", c + Vector3(0, 0, -2.0), c + Vector3(0, 0, -8), "Count your years on the measuring floor", {},
		{"floor": c + Vector3(0, 0, -7.0), "sacks": c + Vector3(-10.0, 0, -24.0), "quay": c + Vector3(-40.0, 0, 0.0)})
	return _done(room, f, seneca)
