extends RefCounted
## The monuments of the city of Rome, as the city (places_rome.gd) builds them from
## content/rome/city.json: one builder per kind, each standing at a point on the ground and facing
## +Z of its group (the front, the way in), grown by `size`, whole or in ruin. Temples, arches, the
## Rostra, the Colosseum and the Pantheon come from kit_rome.gd; the rest are here: the round
## temple, the basilica, the Senate House, the imperial fora, the column, the markets, the baths,
## the palace, the theatres and the stadium, the circus, the tombs, the altar and the churches.
## Everything is sized for the shrunk map: about half real size, so the city's spaces still read.

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Egypt := preload("res://scripts/hall/kit_egypt.gd")


## Builds one monument of `kind`. `span` turns real metres of the map into the world's (for the
## fora, whose size is their place in the city). `year` picks a temple's style (temple_style) when
## the monument's "variant" (a scripted site's state in this age, rome_map.staged) does not. Returns
## a light to flicker, or null.
static func build(parent: Node3D, m: Dictionary, at: Vector3, yaw: float, whole: bool, span: float, year: int = 150) -> OmniLight3D:
	var size := float(m.get("size", 1.0))
	var variant := str(m.get("variant", ""))
	var g := Kit.group(parent, at + Vector3(0, float(m.get("raised", 0.0)), 0), yaw)
	g.name = str(m.get("id", "monument"))
	var light: OmniLight3D = null
	match str(m["kind"]):
		"temple":
			g.scale = Vector3.ONE * size
			Rome.temple(g, Vector3.ZERO, 0.0, whole, temple_style(m, year), variant, str(m.get("inscription", "")))
		"double_temple":
			double_temple(g, size, whole)
		"round_temple":
			light = round_temple(g, size, whole, bool(m.get("fire", false)) and whole and variant != "cold", variant)
		"hall":
			hall(g, size, whole)
		"tabularium":
			tabularium(g, whole)
		"curia":
			curia(g, whole, variant, year < -100)
		"comitium":
			comitium(g, whole, variant)
		"cloaca":
			cloaca(g, variant)
		"beak_column":
			beak_column(g, whole)
		"lacus":
			lacus(g, whole)
		"fig":
			fig(g, whole)
		"milliarium":
			milliarium(g, whole)
		"statues":
			statues(g, whole, int(m.get("count", 5)))
		"tomb":
			Rome.tomb(g, Vector3.ZERO, 0.0, str(m.get("tomb", "altar")), whole)
		"altar_open":
			altar_open(g, whole)
		"hut":
			hut(g, whole)
		"cave":
			cave(g)
		"rock":
			rock(g, size)
		"tower":
			tower(g, whole)
		"portico":
			portico(g, size, whole)
		"basilica":
			basilica(g, size, whole)
		"vaulted_hall":
			vaulted_hall(g, size, whole)
		"rostra":
			Rome.rostra(g, Vector3.ZERO, 0.0, whole, variant)
		"shrine":
			shrine(g, whole)
		"arch":
			Rome.triumphal_arch(g, Vector3.ZERO, 0.0, true, whole, str(m.get("inscription", "")))
		"forum":
			forum(g, float(m.get("w", 60.0)) * span, float(m.get("d", 100.0)) * span, whole)
		"column":
			column_monument(g, size, whole)
		"markets":
			markets(g, whole)
		"amphitheatre":
			Rome.colosseum(g, Vector3.ZERO, size, whole)
			amphitheatre_state(g, size, variant)
		"colossus":
			colossus(g)
		"fountain_cone":
			meta(g, whole)
		"ludus":
			ludus(g, whole)
		"baths":
			baths(g, size, whole)
		"palace":
			palace(g, size, whole)
		"houses":
			houses(g)
		"circus":
			circus(g, span, whole, variant)
		"obelisk":
			Egypt.obelisk(g, Vector3.ZERO, 16.0 * size, true)
		"open_circus":
			open_circus(g, span)
		"theatre":
			theatre(g, size, whole)
		"pantheon":
			Rome.pantheon(g, Vector3.ZERO, 0.0, size, whole)
		"stadium":
			stadium(g, span, whole)
		"altar":
			altar(g, whole)
		"mausoleum":
			mausoleum(g, size, whole, str(m.get("id", "")) == "hadrian_tomb")
		"church":
			church(g, size, whole)
		_:
			push_warning("no builder for the monument kind %s" % m["kind"])
	return light


## The style a temple is built in, in `year` (docs/rome-city-notes.md 2.1): the Etruscan temple
## (a high podium, a deep porch of widely spaced wooden columns, a painted terracotta roof) in the
## age of heroes and the early Republic; the Greek marble temple from the last century of the
## Republic; the Corinthian imperial temple for one built under the emperors. A scripted site's
## "variant" names its own.
static func temple_style(m: Dictionary, year: int) -> String:
	var v := str(m.get("style", m.get("variant", "")))
	if v in ["etruscan", "greek", "imperial"]:
		return v
	if year < -200:
		return "etruscan"
	if year < 0:
		return "greek"
	return "imperial" if int(m.get("from", -500)) >= -50 else "greek"


## The Comitium before the Senate House. "assembly" (the Republic): a round hollow of tufa steps,
## the people's place, with the Black Stone in its floor. "paved" (the emperors): a square of
## travertine with the slab of black marble over the stone and statues on columns. "broken": the
## pavement cracked and the statues down. "grass": grass in the cracks and a goat's post.
static func comitium(g: Node3D, whole: bool, variant: String) -> void:
	if variant in ["assembly", ""]:
		for k in 4:  # the steps, rising outward
			var r := 10.0 - k * 2.0
			var h := 2.0 - k * 0.5
			Kit.cylinder(g, Vector3.ZERO, r, h, "tufa", k == 0, 18)
		Kit.cylinder(g, Vector3(0, 0.02, 0), 2.2, 0.1, "travertine", false, 14)  # the floor
		Kit.box(g, Vector3(1.2, 0.12, 1.0), Vector3(1.4, 0.12, 1.8), "dark", false)  # the Black Stone
		Kit.box(g, Vector3(0, 0.6, -6.0), Vector3(3.0, 1.2, 1.2), "travertine")  # the praetor's tribunal, on the step
		Kit.box(g, Vector3(0, 1.5, -6.0), Vector3(0.8, 0.6, 0.8), "wood", false)  # his chair
		return
	Kit.box(g, Vector3(0, 0.06, 0), Vector3(22.0, 0.12, 18.0), "travertine" if variant != "grass" else "grass", false)
	Kit.box(g, Vector3(2.0, 0.14, 1.0), Vector3(2.2, 0.06, 2.8), "dark", false)  # the slab over the Black Stone
	if variant == "paved":
		for x: float in [-7.0, 0.0, 7.0]:  # honorific columns, a bronze on each
			Kit.box(g, Vector3(x, 0.5, -6.0), Vector3(1.2, 0.8, 1.2), "marble")
			Kit.cylinder(g, Vector3(x, 0.9, -6.0), 0.3, 3.2, "marble", true, 8)
			Kit.cylinder(g, Vector3(x, 4.1, -6.0), 0.24, 1.5, "bronze", false, 8, 0.2)
			Kit.blob(g, Vector3(x, 5.8, -6.0), 0.22, "bronze")
		return
	for x: float in [-7.0, 7.0]:  # the columns down, a base left standing
		Kit.box(g, Vector3(x, 0.5, -6.0), Vector3(1.2, 0.8, 1.2), "marble")
		Kit.fallen_column(g, Vector3(x + 1.5, 0.12, -3.5), 0.9, 3.0)
	if variant == "broken":
		for k in 5:
			Kit.box(g, Vector3(-8.0 + k * 4.0, 0.15, 2.0 + (k % 2) * 3.0), Vector3(1.6, 0.14, 0.4), "rubble", false, Vector3(0, 0.4 * k, 0))
		Kit.blob(g, Vector3(0.0, 0.4, -6.0), 0.5, "bronze", Vector3(1.0, 0.5, 2.6), 6)  # a statue face down
		return
	Kit.box(g, Vector3(4.0, 0.6, 4.0), Vector3(0.14, 1.2, 0.14), "wood", false)  # the goats' post
	for k in 6:
		Kit.blob(g, Vector3(-9.0 + k * 3.6, 0.2, -2.0 + (k % 3) * 2.5), 0.9, "grass", Vector3(1.0, 0.3, 1.0), 5)


## The mouth of the Great Drain in the river's bank, facing +Z (the water): a wall of tufa with
## three rings of dressed stone round the arch. "running": the water pouring out of it into the
## Tiber. "choked": rubble and mud in the mouth, the water backed up behind it.
static func cloaca(g: Node3D, variant: String) -> void:
	Kit.box(g, Vector3(0, -0.6, -1.2), Vector3(10.0, 4.8, 2.4), "tufa")  # the bank's wall, set into the bank, down into the water
	Kit.box(g, Vector3(0, 1.85, -1.2), Vector3(10.4, 0.3, 2.8), "travertine", false)  # its coping, at the bank's level
	for k in 3:
		var r := 1.7 + k * 0.7
		Kit.arch(g, Vector3(0, -0.6, 0.02 + k * 0.02), r, 0.0, 180.0, 7 + k * 2, Vector3(0.75, 0.68, 0.5), ["travertine", "tufa"])
	Kit.box(g, Vector3(0, 0.2, 0.05), Vector3(3.3, 1.6, 0.1), "dark", false)  # the dark inside
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 1.9, -0.6, 0.6), Vector3(0.5, 1.4, 1.4), "travertine", false)  # the jambs' footing
	if variant == "choked":
		Kit.box(g, Vector3(0, -0.6, 0.8), Vector3(3.4, 1.4, 2.0), "rubble", false)
		Kit.box(g, Vector3(0, -1.0, 2.6), Vector3(4.4, 0.4, 3.0), "earth", false)  # the mud fan
		for k in 5:
			Kit.box(g, Vector3(-1.6 + k * 0.8, -0.2, 2.2 + (k % 2) * 0.8), Vector3(0.1, 1.4, 0.1), "#8a8a5a", false)  # reeds
		return
	var stream := Kit.box(g, Vector3(0, -1.05, 3.6), Vector3(3.0, 0.14, 6.4), "water", false, Vector3(0.08, 0, 0))
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 3:
		Kit.blob(g, Vector3(-1.0 + k * 1.0, -0.86, 0.9), 0.3, "#e8eef0", Vector3(1.4, 0.3, 1.0), 5)  # the foam at the lip


## A crossroads shrine (compitum) at the side of a street, facing +Z: an aedicula on a base with
## its painted Lares (two dancing youths) and the snake below them, an altar before it and a
## garland over it. `style`: "lares"; "christian" (a niche with a cross and a lamp); "broken" (the
## niche smashed, the altar's top off); "base" (the block alone). Not solid.
static func compitum(g: Node3D, style: String) -> void:
	Kit.box(g, Vector3(0, 0.5, -0.4), Vector3(2.0, 1.0, 1.2), "travertine", false)
	if style == "base":
		Kit.cylinder(g, Vector3(0, 1.0, -0.4), 0.3, 0.06, "dark", false, 8)  # the hollow worn in its top
		return
	Kit.box(g, Vector3(0, 0.35, 0.6), Vector3(0.7, 0.7, 0.7), "marble", false)  # the altar
	if style == "broken":
		Kit.box(g, Vector3(0, 1.4, -0.4), Vector3(1.8, 0.8, 1.0), "rubble", false)
		Kit.box(g, Vector3(0.4, 0.75, 0.6), Vector3(0.6, 0.1, 0.5), "marble", false, Vector3(0.2, 0, 0.3))
		Kit.cylinder(g, Vector3(-0.6, 0.0, 0.9), 0.12, 0.3, "terracotta", false, 6)  # someone's jar of flowers
		Kit.blob(g, Vector3(-0.6, 0.4, 0.9), 0.14, "#c84a4a")
		return
	Kit.box(g, Vector3(0, 2.0, -0.6), Vector3(1.8, 2.0, 0.8), "plaster", false)  # the aedicula
	Kit.box(g, Vector3(0, 3.15, -0.6), Vector3(2.2, 0.3, 1.2), "roof", false)
	Kit.box(g, Vector3(0, 2.0, -0.19), Vector3(1.4, 1.5, 0.02), "#e8d8b8", false)  # the painted panel
	if style == "christian":
		Kit.box(g, Vector3(0, 2.1, -0.17), Vector3(0.08, 0.7, 0.02), "#4a3a2a", false)
		Kit.box(g, Vector3(0, 2.25, -0.17), Vector3(0.45, 0.08, 0.02), "#4a3a2a", false)
		Kit.blob(g, Vector3(0.5, 1.35, -0.2), 0.08, "terracotta")  # the lamp
		return
	for x: float in [-0.35, 0.35]:  # the Lares, painted, dancing
		Kit.blob(g, Vector3(x, 2.25, -0.17), 0.1, "#c84a2a", Vector3(1.0, 1.0, 0.2), 5)
		Kit.box(g, Vector3(x, 1.85, -0.17), Vector3(0.22, 0.6, 0.02), "#c84a2a", false, Vector3(0, 0, -x * 0.5))
	Kit.box(g, Vector3(0, 1.4, -0.17), Vector3(1.0, 0.06, 0.02), "#4a6a3a", false, Vector3(0, 0, 0.15))  # the snake
	for k in 5:  # the garland
		Kit.blob(g, Vector3(-0.6 + k * 0.3, 2.95 - 0.12 * absf(k - 2), -0.18), 0.09, "leaves")


## The column of Gaius Duilius by the Rostra: a column hung with the bronze beaks of the Carthaginian
## ships taken at Mylae in 260 BC, the first sea victory, with its inscription on the base.
static func beak_column(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.8, 0), Vector3(2.4, 1.6, 2.4), "travertine")
	Kit.box(g, Vector3(0, 0.9, 1.21), Vector3(1.6, 0.9, 0.04), "plaque" if whole else "dark", false)
	Kit.cylinder(g, Vector3(0, 1.6, 0), 0.5, 7.0 if whole else 3.0, "marble", true, 10, 0.42)
	if not whole:
		Kit.fallen_column(g, Vector3(2.0, 0.0, 1.5), 0.7, 3.5)
		return
	for k in 6:  # the beaks, three each side, up the shaft
		var a := PI * (k % 2) + 0.6
		var y := 3.0 + k * 0.9
		var beak := Kit.group(g, Vector3(cos(a) * 0.5, y, sin(a) * 0.5), a - PI / 2.0)
		Kit.box(beak, Vector3(0, 0, 0.45), Vector3(0.4, 0.3, 0.9), "bronze", false)
		Kit.box(beak, Vector3(0, 0, 0.9), Vector3(0.6, 0.08, 0.2), "bronze", false)
	Kit.cylinder(g, Vector3(0, 8.6, 0), 0.25, 1.4, "bronze", false, 8, 0.2)  # Duilius on top
	Kit.blob(g, Vector3(0, 10.2, 0), 0.22, "bronze")


## The Lacus Curtius in the middle of the Forum: the pit into which Marcus Curtius rode, fenced
## with a low wall, a puteal (well-head) and an altar, an olive and a fig and a vine beside it.
static func lacus(g: Node3D, whole: bool) -> void:
	Kit.cylinder(g, Vector3.ZERO, 3.2, 0.6, "travertine", true, 12)
	Kit.cylinder(g, Vector3(0, 0.6, 0), 2.6, 0.05, "dark" if whole else "earth", false, 12)  # the pit
	Kit.cylinder(g, Vector3(1.6, 0.6, 1.6), 0.5, 0.9, "marble", false, 10)  # the puteal
	Kit.box(g, Vector3(-1.8, 0.95, -1.4), Vector3(0.7, 0.7, 0.7), "marble", false)  # the altar
	if whole:
		Kit.box(g, Vector3(-3.0, 0.5, 2.0), Vector3(0.18, 1.0, 0.18), "wood", false)  # the vine's post
		Kit.blob(g, Vector3(-3.0, 1.3, 2.0), 0.7, "leaves", Vector3(1.0, 0.7, 1.0), 6)
		Kit.leaves(g, "g_olive", Vector3(3.6, 2.5, -1.4), 3.0, 2.4)
		Kit.cylinder(g, Vector3(3.6, 0.0, -1.4), 0.15, 1.8, "trunk", false, 6)


## The Ficus Ruminalis: the fig under which the wolf suckled the twins, replanted in the Comitium
## and kept alive, with the bronze wolf and twins under it. In ruin, a dead stump.
static func fig(g: Node3D, whole: bool) -> void:
	Kit.cylinder(g, Vector3.ZERO, 0.35, 2.4 if whole else 1.0, "trunk", true, 7, 0.28)
	if not whole:
		Rome.she_wolf(g, Vector3(0, 0, 2.4), 0.3, false)
		return
	for a: float in [0.4, 2.3, 4.2]:
		var d := Vector3(cos(a) * 1.4, 1.2, sin(a) * 1.4)
		Kit.mesh(g, Kit._cyl(0.1, d.length()), "trunk", Vector3(0, 2.4, 0) + d / 2.0, Quaternion(Vector3.UP, d.normalized()).get_euler())
	Kit.leaves(g, "g_crown", Vector3(0, 4.6, 0), 7.5, 5.2)
	Rome.she_wolf(g, Vector3(0, 0, 2.4), 0.3, whole)  # the bronze wolf and the twins under the fig (kit_rome)


## The Golden Milestone (Milliarium Aureum) of Augustus by the Rostra: a marble column plated with
## gilt bronze, the distances to the cities of the Empire on it; the roads are measured from here.
static func milliarium(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.4, 0), Vector3(2.0, 0.8, 2.0), "marble")
	Kit.cylinder(g, Vector3(0, 0.8, 0), 0.6, 2.6, "gold" if whole else "marble", true, 10)
	Kit.cylinder(g, Vector3(0, 3.4, 0), 0.8, 0.3, "marble", false, 10)
	if whole:  # its name, and the miles to the great cities cut below it
		Rome.inscription(g, Vector3(0, 2.75, 0.63), ["MILLIARIVM", "AVREVM"], 18, "3a2a1a")
		Rome.inscription(g, Vector3(0, 1.7, 0.63), ["OSTIA XVI", "CAPVA CXXXVI", "ARIMINVM CCXXII", "BRVNDISIVM CCCLX"], 12, "3a2a1a")


## A row of honorific statues on columns along the Forum: bronzes of consuls and generals,
## `count` of them, that multiplied until the censors cleared them.
static func statues(g: Node3D, whole: bool, count: int) -> void:
	for k in count:
		var x := (k - (count - 1) / 2.0) * 3.5
		Kit.box(g, Vector3(x, 0.45, 0), Vector3(1.2, 0.9, 1.2), "travertine")
		if not whole and k % 2 == 1:
			continue
		Kit.cylinder(g, Vector3(x, 0.9, 0), 0.28, 2.8, "marble", true, 8)
		if whole or k % 4 == 0:
			Kit.cylinder(g, Vector3(x, 3.7, 0), 0.22, 1.5, "bronze", false, 8, 0.18)
			Kit.blob(g, Vector3(x, 5.4, 0), 0.2, "bronze")
			Kit.box(g, Vector3(x + 0.3, 4.5, 0.2), Vector3(0.12, 0.9, 0.12), "bronze", false, Vector3(0, 0, -0.5))  # the arm out


## An open-air altar in its precinct (the Ara Maxima of Hercules, the altar of Consus dug out for
## its games): a great altar of tufa on steps inside a low wall, ash on it.
static func altar_open(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.25, 0), Vector3(12.0, 0.5, 12.0), "tufa", false)
	for k in 2:
		Kit.box(g, Vector3(0, 0.7 + k * 0.4, 0), Vector3(6.0 - k * 0.8, 0.4, 5.0 - k * 0.8), "tufa")
	Kit.box(g, Vector3(0, 2.3, 0), Vector3(4.0, 1.8, 3.0), "tufa" if whole else "rubble")
	Kit.box(g, Vector3(0, 3.3, 0), Vector3(4.4, 0.25, 3.4), "travertine", false)
	Kit.cylinder(g, Vector3(0, 3.42, 0), 0.9, 0.18, "ash", false, 10)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 6.0, 0.9, 0), Vector3(0.5, 0.8, 12.0), "tufa", false)
		Kit.box(g, Vector3(0, 0.9, side * 6.0), Vector3(12.0, 0.8, 0.5) if side < 0 else Vector3(4.0, 0.8, 0.5), "tufa", false)


## The Hut of Romulus on the Palatine: a round hut of wattle on a stone footing under a steep cone
## of thatch, kept by the priests and rebuilt whenever it burned.
static func hut(g: Node3D, whole: bool) -> void:
	Kit.cylinder(g, Vector3.ZERO, 3.2, 0.5, "tufa", true, 12)
	Kit.cylinder(g, Vector3(0, 0.5, 0), 2.8, 2.2, "wicker" if whole else "deadwood", true, 12)
	Kit.box(g, Vector3(0, 1.4, 2.7), Vector3(1.0, 1.8, 0.2), "dark", false)  # the door
	if whole:
		Kit.cylinder(g, Vector3(0, 2.7, 0), 3.6, 3.4, "#a08850", false, 12, 0.2)
	for k in 4:  # the fence of the precinct
		var a := TAU * k / 4.0 + 0.4
		Kit.box(g, Vector3(cos(a) * 6.0, 0.6, sin(a) * 6.0), Vector3(0.15, 1.2, 0.15), "wood", false)


## The Lupercal: the wolf's cave under the Palatine, a dark mouth in the rock with a fig before it.
static func cave(g: Node3D) -> void:
	Kit.blob(g, Vector3(0, 1.0, -3.0), 5.0, "rock", Vector3(1.4, 0.8, 1.0), 8)
	Kit.box(g, Vector3(0, 1.3, 1.0), Vector3(2.4, 2.6, 0.5), "dark", false)  # the mouth
	Kit.cylinder(g, Vector3(3.5, 0, 2.0), 0.2, 2.0, "trunk", false, 6)
	Kit.blob(g, Vector3(3.5, 3.0, 2.0), 1.6, "leaves", Vector3(1.0, 0.7, 1.0), 6)


## A rock (the Tarpeian, the Capitol's cliff toward the Forum): a face of bare rock, `size` high.
static func rock(g: Node3D, size: float) -> void:
	Kit.blob(g, Vector3(0, 3.0 * size, 0), 6.0 * size, "rock", Vector3(1.3, 0.9, 0.7), 7)
	Kit.blob(g, Vector3(4.0 * size, 1.5 * size, 1.0), 3.5 * size, "rock", Vector3(1.0, 0.7, 0.8), 6)
	Kit.blob(g, Vector3(-5.0 * size, 1.0 * size, 0.5), 3.0 * size, "rock", Vector3(1.0, 0.6, 0.9), 6)


## A tower of the Servian wall by a gate: square, of tufa, with a walk along its top.
static func tower(g: Node3D, whole: bool) -> void:
	var h := 12.0 if whole else 6.0
	Kit.box(g, Vector3(0, h / 2.0 - 1.0, 0), Vector3(6.0, h + 2.0, 6.0), "tufa")
	if whole:
		for k in 4:
			var a := TAU * k / 4.0
			Kit.box(g, Vector3(cos(a) * 2.7, h + 0.4, sin(a) * 2.7), Vector3(1.0, 0.8, 1.0) if k % 2 == 0 else Vector3(6.0, 0.8, 0.6), "tufa", false, Vector3(0, -a, 0))
	Kit.box(g, Vector3(0, 1.8, 3.02), Vector3(1.2, 2.4, 0.1), "dark", false)


## A portico: a long colonnade of tufa piers under a tiled roof (the Porticus Aemilia by the river
## port, of concrete vaults; the porticoes of the Campus). `size` scales its length. Faces +Z.
static func portico(g: Node3D, size: float, whole: bool) -> void:
	var l := 60.0 * size
	Kit.box(g, Vector3(0, 0.3, 0), Vector3(l, 0.6, 12.0), "travertine", false)
	var n := int(l / 5.0)
	for k in n + 1:
		var x := -l / 2.0 + l * k / n
		if not whole and k % 3 == 1:
			continue
		Kit.box(g, Vector3(x, 3.6, 5.0), Vector3(1.2, 6.0, 1.2), "tufa")
		if whole or k % 3 == 0:
			Kit.box(g, Vector3(x, 3.6, -5.0), Vector3(1.2, 6.0, 1.2), "tufa")
	if whole:
		Kit.box(g, Vector3(0, 6.9, 0), Vector3(l + 1.0, 0.6, 12.0), "tufa", false)
		_roof(g, Vector3(0, 7.2, 0), Vector3(l + 1.4, 2.4, 12.6))
	else:
		Kit.box(g, Vector3(-l / 4.0, 6.9, 0), Vector3(l / 3.0, 0.6, 12.0), "tufa", false)


## What the years have done to the amphitheatre: "cracked" (the earthquake of 443: a heap of
## fallen blocks under the south side, the prefect's props), "houses" (huts of wood and thatch in
## the outer arches, beans in the arena).
static func amphitheatre_state(g: Node3D, size: float, variant: String) -> void:
	var a := 94.0 * size
	var b := 78.0 * size
	if variant == "cracked":
		for k in 6:
			var t := -PI / 2.0 + (k - 2.5) * 0.12
			var p := Vector3(cos(t) * (a + 5.0), 0, sin(t) * (b + 5.0))
			Kit.box(g, p + Vector3(0, 0.8, 0), Vector3(3.0, 1.6, 2.4), "travertine", false, Vector3(0.3, t, 0.2))
			Kit.box(g, p + Vector3(0, 6.0, -3.0), Vector3(0.4, 12.0, 0.4), "wood", false, Vector3(0.2, 0, 0))  # the props
		return
	if variant != "houses":
		return
	for k in 9:
		var t := PI * 0.15 + k * 0.22
		var p := Vector3(cos(t) * (a - 6.0), 0, sin(t) * (b - 6.0))
		var hut := Kit.group(g, p, atan2(-p.x, -p.z))
		Kit.box(hut, Vector3(0, 1.4, 0), Vector3(4.0, 2.8, 3.4), "wood")
		var roof := PrismMesh.new()
		roof.size = Vector3(4.6, 1.4, 4.0)
		Kit.mesh(hut, roof, "#a08850", Vector3(0, 3.5, 0))
		Kit.box(hut, Vector3(0, 0.9, 1.72), Vector3(1.0, 1.8, 0.1), "dark", false)
		Kit.box(hut, Vector3(2.6, 0.4, 0), Vector3(0.6, 0.8, 0.6), "wicker", false)
	for k in 12:  # the beans
		Kit.box(g, Vector3(-30.0 + (k % 4) * 20.0, 0.5, -20.0 + (k / 4) * 20.0), Vector3(14.0, 0.8, 1.2), "leaves", false)


## Venus and Rome: two temples back to back on one platform in a colonnaded court (Hadrian's).
static func double_temple(g: Node3D, size: float, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(40.0 * size, 1.2, 70.0 * size), "marble" if whole else "tufa")
	for side: float in [-1.0, 1.0]:
		var t := Kit.group(g, Vector3(0, 1.2, side * 12.0 * size), 0.0 if side > 0.0 else PI)
		t.scale = Vector3.ONE * size
		Rome.temple(t, Vector3.ZERO, 0.0, whole)
	var n := 12
	for k in n + 1:  # the colonnades down the long sides of the court
		var z := (-33.0 + 66.0 * k / n) * size
		for x: float in [-18.0 * size, 18.0 * size]:
			if whole or k % 3 == 0:
				Rome.column(g, Vector3(x, 1.2, z), 6.0, 0.35, "giallo" if whole else "marble")


## A round temple (Vesta's, Hercules'): a ring of columns round a drum on a round podium, under a
## low cone of roof. `fire`: the sacred fire's glow inside. Returns the fire's light, or null.
## `variant` (Vesta's through the ages): "thatch" (the first house of the hearth: wooden posts, a
## drum of tufa, a cone of thatch), "stone" (tufa posts under a bronze roof), "marble" or "" (the
## marble ring of the emperors), "cold" (the fire out).
static func round_temple(g: Node3D, size: float, whole: bool, fire: bool, variant: String = "") -> OmniLight3D:
	var r := 4.5 * size
	var old := variant in ["thatch", "stone"]
	var stone := "tufa" if old or not whole else "marble"
	Kit.cylinder(g, Vector3.ZERO, r + 0.6, 1.2, stone, true, 18)
	Kit.cylinder(g, Vector3(0, 1.2, 0), r * 0.62, 6.0 * size, "plaster" if old else "marble", true, 16)
	var n := 16 if whole else 7
	for k in n:
		var a := TAU * k / 16.0
		if variant == "thatch":
			Kit.cylinder(g, Vector3(cos(a) * r, 1.2, sin(a) * r), 0.22 * size, 6.4 * size, "wood", true, 8)
		else:
			Rome.column(g, Vector3(cos(a) * r, 1.2, sin(a) * r), 7.0 * size, 0.28 * size, stone if old else "marble")
	if whole:
		Kit.cylinder(g, Vector3(0, 1.2 + 7.0 * size, 0), r + 0.4, 0.6, "wood" if old else "marble", false, 18)
		Kit.cylinder(g, Vector3(0, 1.8 + 7.0 * size, 0), r + 0.6, 2.4 * size if variant != "thatch" else 3.6 * size,
			"#a08850" if variant == "thatch" else "bronze", false, 18, 0.5)
	elif variant == "cold":
		Kit.cylinder(g, Vector3(0, 1.2, 0), 0.8, 0.3, "ash", false, 10)  # the hearth, cold
	if not fire:
		return null
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.5, 0)
	light.light_color = Color("ff9a48")
	light.light_energy = 1.4
	light.omni_range = 9.0
	g.add_child(light)
	return light


## A plain hall with a tiled roof: the Regia, the Villa Publica.
static func hall(g: Node3D, size: float, whole: bool) -> void:
	var w := 14.0 * size
	var d := 10.0 * size
	var h := 6.0 * size
	Kit.box(g, Vector3(0, h / 2.0, 0), Vector3(w, h, d), "tufa" if whole else "rubble")
	if whole:
		_roof(g, Vector3(0, h, 0), Vector3(w + 0.8, 2.4 * size, d + 0.8))
		Kit.box(g, Vector3(0, 1.8, d / 2.0 + 0.02), Vector3(1.8, 3.6, 0.1), "wood", false)


## The Tabularium: the state's record office, a high wall of grey stone on the Capitol's slope over
## the Forum, with an arcade of arches framed by half-columns along its top storey.
static func tabularium(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 8.0, -3.0), Vector3(48.0, 16.0, 8.0), "tufa")
	for k in 11:
		var x := -20.0 + 4.0 * k
		if whole or k % 3 == 0:
			Kit.arch(g, Vector3(x, 17.5, 1.1), 1.2, 0.0, 180.0, 5, Vector3(0.8, 0.5, 0.8), ["travertine"])
			Kit.box(g, Vector3(x - 2.0, 18.0, 1.1), Vector3(0.8, 5.0, 0.8), "travertine", false)
		Kit.box(g, Vector3(x, 17.0, 1.02), Vector3(2.2, 3.4, 0.1), "dark", false)
	if whole:
		Kit.box(g, Vector3(0, 21.0, -1.0), Vector3(49.0, 1.0, 5.0), "travertine", false)
		_roof(g, Vector3(0, 21.5, -1.0), Vector3(49.0, 1.6, 5.0))


## A tiled roof, pitched along X: a prism on top of `top`.
static func _roof(g: Node3D, top: Vector3, size: Vector3, mat: String = "roof") -> void:
	var p := PrismMesh.new()
	p.size = size
	Kit.mesh(g, p, mat, top + Vector3(0, size.y / 2.0, 0), Vector3(0, PI / 2.0, 0) if size.z > size.x else Vector3.ZERO)


## The Senate House: a tall plain brick hall with a pediment over its bronze doors, up a few steps.
## `variant` "burnt": the walls blackened, no roof, the scaffolding of a rebuilding up its front.
## `old`: the kings' hall of tufa, before brick.
static func curia(g: Node3D, whole: bool, variant: String = "", old: bool = false) -> void:
	var burnt := variant == "burnt"
	Kit.box(g, Vector3(0, 0.5, 1.0), Vector3(12.0, 1.0, 20.0), ("travertine" if not old else "tufa") if whole else "rubble")
	var wall := "brick" if not old else "tufa"
	Kit.box(g, Vector3(0, 8.0 if not old else 6.0, 0), Vector3(11.0, 14.0 if not old else 10.0, 18.0), wall if not burnt else "#3a3230")
	if old and not burnt:
		_roof(g, Vector3(0, 11.0, 0), Vector3(11.6, 2.6, 18.6))
		Kit.box(g, Vector3(0, 3.0, 9.02), Vector3(2.4, 4.8, 0.1), "wood", false)
		return
	Kit.box(g, Vector3(0, 4.0, 9.02), Vector3(2.6, 5.4, 0.1), "bronze" if whole and not burnt else "dark", false)
	for k in 3:
		Kit.box(g, Vector3(0, 11.5, 9.02), Vector3(1.4 + k * 0.0, 2.6, 0.1), "dark", false)
	if burnt:
		for x: float in [-4.5, -1.5, 1.5, 4.5]:  # the scaffold poles and their ledgers
			Kit.box(g, Vector3(x, 8.0, 10.2), Vector3(0.2, 16.0, 0.2), "wood", false)
		for y: float in [5.0, 10.0, 15.0]:
			Kit.box(g, Vector3(0, y, 9.7), Vector3(9.6, 0.16, 1.4), "wood", false)
		Kit.box(g, Vector3(0, 15.4, 0), Vector3(11.4, 0.8, 18.4), "wood", false)  # the new roof-beams, no tiles yet
		return
	if whole:
		Rome._pediment(g, Vector3(0, 15.0, 8.6), 11.4, 2.6, 0.8)
		_roof(g, Vector3(0, 15.0, 0), Vector3(11.4, 2.6, 18.4))


## A basilica: a long hall for the courts and business, two storeys of arcades along its front
## (+Z) under a high clerestory and a tiled roof. In ruin: the floor, the stumps of its piers, a
## few columns and a corner of wall.
static func basilica(g: Node3D, size: float, whole: bool) -> void:
	var l := 50.0 * size
	var d := 20.0
	Kit.box(g, Vector3(0, 0.4, 0), Vector3(l + 2.0, 0.8, d + 2.0), "marble" if whole else "travertine")
	var n := int(l / 5.0)
	if not whole:
		for k in n + 1:
			var x := -l / 2.0 + l * k / n
			Kit.box(g, Vector3(x, 1.2, d / 2.0 - 1.0), Vector3(1.4, 0.8 + 1.6 * float(k % 3 == 0), 1.4), "travertine")
			if k % 4 == 1:
				Rome.column(g, Vector3(x, 0.8, 0), 7.0, 0.4, "giallo")
		Kit.box(g, Vector3(-l / 2.0 + 3.0, 5.0, -d / 2.0 + 0.5), Vector3(6.0, 10.0, 1.0), "brick")
		return
	for storey in 2:
		var y := 0.8 + storey * 6.5
		for k in n:  # the piers of the arcade, and the arch between each two
			var x := -l / 2.0 + l * (k + 0.5) / n
			Kit.box(g, Vector3(x - l / n / 2.0, y + 3.0, d / 2.0), Vector3(1.2, 6.0, 1.4), "marble", storey == 0)
			Kit.arch(g, Vector3(x, y + 3.6, d / 2.0), 1.4, 0.0, 180.0, 5, Vector3(1.0, 0.6, 1.3), ["marble"])
			Kit.box(g, Vector3(x, y + 5.7, d / 2.0), Vector3(l / n, 0.6, 1.4), "marble", false)
		Kit.box(g, Vector3(l / 2.0, y + 3.0, d / 2.0), Vector3(1.2, 6.0, 1.4), "marble", storey == 0)
	Kit.box(g, Vector3(0, 8.0, -1.0), Vector3(l, 14.4, d - 2.0), "brick")  # the hall behind
	Kit.box(g, Vector3(0, 16.5, -1.0), Vector3(l * 0.8, 4.0, d * 0.5), "brick", false)  # the clerestory
	for k in 6:
		Kit.box(g, Vector3(-l * 0.33 + l * 0.66 * k / 5.0, 16.5, -1.0 + d * 0.25 + 0.02), Vector3(1.4, 2.0, 0.1), "dark", false)
	_roof(g, Vector3(0, 18.5, -1.0), Vector3(l * 0.8 + 1.0, 2.6, d * 0.5 + 1.0))
	_roof(g, Vector3(0, 14.2, -1.0), Vector3(l + 1.0, 1.6, d), "roof")


## Maxentius' basilica: a vast brick hall of three great barrel-vaulted bays a side. In ruin only
## the north aisle's three vaults stand, as they do today.
static func vaulted_hall(g: Node3D, size: float, whole: bool) -> void:
	var l := 50.0 * size
	var d := 36.0 * size
	var h := 22.0 * size
	if whole:
		Kit.box(g, Vector3(0, h / 2.0, 0), Vector3(l, h, d), "brick")
		Kit.box(g, Vector3(0, h + 3.0, 0), Vector3(l * 0.9, 6.0, d * 0.4), "brick", false)
		_roof(g, Vector3(0, h + 6.0, 0), Vector3(l * 0.9 + 1.0, 2.0, d * 0.4 + 1.0), "#7e7a74")
	var aisle := d * 0.3
	for k in 3:  # the three great bays on the side toward +Z
		var x := -l / 3.0 + l / 3.0 * k
		if not whole:
			Kit.box(g, Vector3(x - l / 6.0 + 1.0, h * 0.6, d / 2.0 - aisle / 2.0), Vector3(2.0, h * 1.2, aisle), "brick")
			Kit.box(g, Vector3(x, h * 1.1, d / 2.0 - aisle / 2.0), Vector3(l / 3.0, h * 0.2, aisle), "brick", false)
		Kit.arch(g, Vector3(x, h * 0.45, d / 2.0 + 0.02), l / 6.0 - 1.5, 0.0, 180.0, 9, Vector3(1.6, 1.0, 0.4), ["brick"])
		Kit.box(g, Vector3(x, h * 0.22, d / 2.0 + 0.02), Vector3(l / 3.0 - 3.0, h * 0.44, 0.1), "dark", false)
	if not whole:
		Kit.box(g, Vector3(l / 2.0 - 1.0, h * 0.6, d / 2.0 - aisle / 2.0), Vector3(2.0, h * 1.2, aisle), "brick")


## The shrine of Janus: a small bronze house of two arched doors, one each end.
static func shrine(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 3.0, 0), Vector3(5.0, 6.0, 7.0), "bronze" if whole else "verdigris")
	for z: float in [3.52, -3.52]:
		Kit.box(g, Vector3(0, 2.2, z), Vector3(2.4, 4.4, 0.06), "dark", false)
	Kit.cylinder(g, Vector3(0, 0, 5.0), 0.3, 1.1, "marble", false, 8)


## An imperial forum: a paved court `w` by `d`, closed by a high wall of grey stone on three sides
## (the fire wall that shut out the city), colonnades along the long sides, open at the front (+Z).
## In ruin the walls are broken low and only a few columns stand.
static func forum(g: Node3D, w: float, d: float, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(w, 0.06, d), "marble" if whole else "travertine", false)
	var wall_h := 14.0 if whole else 4.0
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * w / 2.0, wall_h / 2.0, 0), Vector3(1.2, wall_h, d), "tufa")
	Kit.box(g, Vector3(0, wall_h / 2.0, -d / 2.0), Vector3(w, wall_h, 1.2), "tufa")
	var n := maxi(3, int(d / 5.0))
	for side: float in [-1.0, 1.0]:
		var x := side * (w / 2.0 - 5.0)
		for k in n + 1:
			if not whole and k % 4 != 0:
				continue
			Rome.column(g, Vector3(x, 0.06, -d / 2.0 + 2.0 + (d - 4.0) * k / n), 7.0, 0.35, "giallo" if whole else "marble")
		if whole:
			Kit.box(g, Vector3(side * (w / 2.0 - 2.5), 7.5, 0), Vector3(5.6, 0.6, d - 2.0), "roof", false)


## A monumental column (Trajan's, Marcus Aurelius'): a pedestal, the shaft wound with its frieze
## in bands, and the emperor's gilt bronze statue on top. 30 m.
static func column_monument(g: Node3D, size: float, whole: bool) -> void:
	Kit.box(g, Vector3(0, 2.8, 0), Vector3(5.4, 5.6, 5.4), "marble")
	var h := 26.0 * size
	Kit.cylinder(g, Vector3(0, 5.6, 0), 1.9, h, "marble", true, 14, 1.7)
	for k in 12:  # the frieze's bands winding up it
		Kit.cylinder(g, Vector3(0, 5.6 + h * (k + 0.5) / 12.0, 0), 1.95 - 0.02 * k, 0.25, "#b8ae98", false, 14)
	Kit.box(g, Vector3(0, 5.6 + h + 0.4, 0), Vector3(4.4, 0.8, 4.4), "marble", false)
	if whole:
		Kit.cylinder(g, Vector3(0, 6.4 + h, 0), 0.5, 2.6, "gold", false, 8)
		Kit.blob(g, Vector3(0, 9.3 + h, 0), 0.4, "gold")


## Trajan's markets: a hemicycle of brick shops in three storeys, cut into the hill, facing +Z.
static func markets(g: Node3D, whole: bool) -> void:
	var r := 30.0
	var n := 14
	for k in n:
		var a := PI * (k + 0.5) / n
		var p := Vector3(cos(a) * r, 0, -sin(a) * r)
		var panel := Kit.group(g, p, atan2(-p.x, -p.z))
		var storeys := 3 if whole else 1 + k % 2
		for s in storeys:
			Kit.box(panel, Vector3(0, 2.5 + s * 5.0, -2.0), Vector3(r * PI / n + 0.2, 5.0, 4.0), "brick", s == 0)
			Kit.box(panel, Vector3(0, 1.8 + s * 5.0, 0.02), Vector3(2.4, 3.2, 0.1), "dark", false)
	Kit.box(g, Vector3(0, 0.03, -r * 0.4), Vector3(r * 2.0, 0.06, r * 0.9), "travertine", false)


## Nero's Colossus, made the Sun: a bronze giant with a crown of rays, on a high base.
static func colossus(g: Node3D) -> void:
	Kit.box(g, Vector3(0, 3.0, 0), Vector3(7.0, 6.0, 7.0), "travertine")
	Kit.cylinder(g, Vector3(-0.8, 6.0, 0), 0.7, 8.0, "bronze", false, 8, 0.8)
	Kit.cylinder(g, Vector3(0.8, 6.0, 0), 0.7, 8.0, "bronze", false, 8, 0.8)
	Kit.cylinder(g, Vector3(0, 14.0, 0), 1.8, 7.0, "bronze", false, 10, 1.4)
	Kit.cylinder(g, Vector3(-2.2, 15.0, 0.6), 0.45, 6.0, "bronze", false, 8)
	Kit.box(g, Vector3(2.4, 20.0, 0.4), Vector3(0.8, 5.0, 0.8), "bronze", false, Vector3(0, 0, -0.3))  # the arm raised
	Kit.blob(g, Vector3(0, 22.2, 0), 1.2, "bronze")
	for k in 7:  # the Sun's rays
		var a := PI * (k + 0.5) / 7.0
		Kit.box(g, Vector3(cos(a) * 1.8, 22.4 + sin(a) * 1.8, -0.2), Vector3(0.2, 1.6, 0.2), "gold", false, Vector3(0, 0, a - PI / 2.0))


## The Meta Sudans: a tall cone fountain in a round basin. Dry once the aqueducts are cut.
static func meta(g: Node3D, whole: bool) -> void:
	Kit.cylinder(g, Vector3.ZERO, 7.0, 0.8, "travertine", true, 18)
	Kit.cylinder(g, Vector3(0, 0.5, 0), 6.4, 0.35, "water" if whole else "drybed", false, 18)
	Kit.cylinder(g, Vector3(0, 0.8, 0), 2.2, 9.0, "brick", true, 12, 0.6)


## The gladiators' school: a small oval arena inside a court of barracks.
static func ludus(g: Node3D, whole: bool) -> void:
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 20.0, 4.0, 0), Vector3(4.0, 8.0, 36.0), "brick")
		Kit.box(g, Vector3(0, 4.0, side * 18.0), Vector3(36.0, 8.0, 4.0), "brick")
	Kit.cylinder(g, Vector3.ZERO, 12.0, 3.0, "travertine" if whole else "rubble", false, 20)
	Kit.cylinder(g, Vector3(0, 0.02, 0), 10.5, 3.05, "sand", false, 20)


## Imperial baths: a walled precinct, the great vaulted cold hall across the middle, the hot room
## under its dome at the back (-Z), wings of halls either side and the swimming pool in front.
## In ruin: roofless, the vaults broken, the pool dry.
static func baths(g: Node3D, size: float, whole: bool) -> void:
	var s := size
	var wall := 3.0 if whole else 1.6
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 60.0 * s, wall, 0), Vector3(2.0, wall * 2.0, 120.0 * s), "brick")
		Kit.box(g, Vector3(0, wall, side * 60.0 * s), Vector3(120.0 * s, wall * 2.0, 2.0), "brick")
	var h := 22.0 * s
	Kit.box(g, Vector3(0, h / 2.0, 0), Vector3(60.0 * s, h, 26.0 * s), "brick")  # the frigidarium's block
	for k in 3:  # its three cross vaults, with the great lunette windows
		var x := (-20.0 + 20.0 * k) * s
		Kit.box(g, Vector3(x, h * 0.62, 13.0 * s + 0.02), Vector3(10.0 * s, h * 0.4, 0.1), "dark", false)
		if whole:
			var v := Kit.cylinder(g, Vector3(x, h, 0), 9.0 * s, 26.0 * s, "#7e7a74", false, 10)
			v.rotation = Vector3(PI / 2.0, 0, 0)
			v.position = Vector3(x, h, 0)
	for side: float in [-1.0, 1.0]:  # the wings of halls and courts
		Kit.box(g, Vector3(side * 42.0 * s, h * 0.35, 0), Vector3(22.0 * s, h * 0.7, 40.0 * s), "brick")
	var dome_at := Vector3(0, 0, -30.0 * s)
	Kit.cylinder(g, dome_at, 16.0 * s, h * 0.8, "brick", true, 16)
	if whole:
		Kit.blob(g, dome_at + Vector3(0, h * 0.8, 0), 16.0 * s, "#7e7a74", Vector3(1.0, 0.7, 1.0), 12)
	else:
		Kit.cylinder(g, dome_at + Vector3(0, h * 0.8, 0), 15.0 * s, 3.0, "brick", false, 16, 11.0 * s)
	Kit.box(g, Vector3(0, 0.25, 26.0 * s), Vector3(50.0 * s, 0.5, 18.0 * s), "marble", false)  # the natatio
	Kit.box(g, Vector3(0, 0.4, 26.0 * s), Vector3(48.0 * s, 0.3, 16.0 * s), "water" if whole else "drybed", false)


## The palace of the Caesars on the Palatine: great brick masses of halls, courts and terraces,
## with an arcade of two storeys over the Circus. In ruin: the roofs gone, walls broken high.
static func palace(g: Node3D, size: float, whole: bool) -> void:
	var s := size
	var blocks := [[Vector3(-30, 0, -10), Vector3(40, 24, 50)], [Vector3(20, 0, -20), Vector3(40, 30, 40)],
		[Vector3(10, 0, 30), Vector3(60, 18, 30)], [Vector3(-40, 0, 40), Vector3(30, 14, 40)]]
	for b: Array in blocks:
		var p: Vector3 = b[0] * s
		var sz: Vector3 = b[1] * s
		var h := sz.y if whole else sz.y * 0.6
		Kit.box(g, p + Vector3(0, h / 2.0, 0), Vector3(sz.x, h, sz.z), "brick")
		if whole:
			Kit.box(g, p + Vector3(0, h + 0.3, 0), Vector3(sz.x + 1.0, 0.6, sz.z + 1.0), "roof", false)
	for storey in 2:  # the arcade facing the Circus (+Z)
		for k in 10:
			var x := (-45.0 + 10.0 * k) * s
			Kit.box(g, Vector3(x, 3.0 + storey * 7.0, 46.0 * s), Vector3(2.0, 6.0, 2.0), "travertine", storey == 0)
			if whole or k % 3 == 0:
				Kit.arch(g, Vector3(x + 5.0 * s, 4.0 + storey * 7.0, 46.0 * s), 3.2 * s, 0.0, 180.0, 5, Vector3(1.6, 0.8, 1.8), ["travertine"])


## The houses of the Republic's great men on the Palatine: tiled roofs over atria round gardens.
static func houses(g: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	for k in 9:
		var p := Vector3(rng.randf_range(-40.0, 40.0), 0, rng.randf_range(-35.0, 35.0))
		var w := rng.randf_range(12.0, 18.0)
		var d := rng.randf_range(14.0, 22.0)
		var h := rng.randf_range(5.0, 7.0)
		var yaw := rng.randf_range(-0.2, 0.2)
		var hg := Kit.group(g, p, yaw)
		Kit.box(hg, Vector3(0, h / 2.0, 0), Vector3(w, h, d), "insula_white")
		_roof(hg, Vector3(0, h, 0), Vector3(w + 0.8, 2.2, d + 0.8))
		Kit.box(hg, Vector3(0, 1.4, d / 2.0 + 0.02), Vector3(1.6, 2.8, 0.1), "wood", false)


## The Circus Maximus: the sand track, the spina down its middle with its turning posts, the stands
## on three sides of brick and marble, the starting gates at the west end (-Z). In ruin, the stands
## are broken into stretches and the spina's statues gone.
## `variant` through the ages: "wood" (timber stands on the slopes, an earth track and a low barrier
## of earth), "stone" (tufa stands, timber above), "marble" or "" (the emperors' circus), "cracked"
## (a stretch of the upper stands fallen and fenced), "grass" (grass over the track, the stands
## quarried).
static func circus(g: Node3D, span: float, whole: bool, variant: String = "") -> void:
	var length := 600.0 * span
	var width := 140.0 * span
	var wood := variant == "wood"
	var track := "sand"
	if wood:
		track = "earth"
	elif variant == "grass":
		track = "grass"
	Kit.box(g, Vector3(0, 0.05, 0), Vector3(width, 0.1, length), track, false)
	Kit.box(g, Vector3(0, 0.8, 0), Vector3(3.0, 1.6, length * 0.62), "earth" if wood else ("tufa" if variant == "stone" else "marble"))  # the spina
	for z: float in [-length * 0.31, length * 0.31]:  # the turning posts, three cones each
		for k in 3:
			Kit.cylinder(g, Vector3(-0.8 + k * 0.8, 1.6, z), 0.4, 3.0, "wood" if wood else ("gold" if whole else "bronze"), false, 8, 0.05)
	var sections := 16
	var stand := "brick"
	if wood:
		stand = "wood"
	elif variant == "stone":
		stand = "tufa"
	for side: float in [-1.0, 1.0]:
		for k in sections:
			if not whole and k % 3 == 1:
				continue
			if variant == "cracked" and side < 0.0 and k in [9, 10]:  # the stretch fallen in 443
				var fz := -length / 2.0 + length * (k + 0.5) / sections
				Kit.box(g, Vector3(side * (width / 2.0 + 6.0), 2.0, fz), Vector3(12.0, 4.0, length / sections), "rubble")
				for j in 4:
					Kit.box(g, Vector3(side * (width / 2.0 + 1.0), 0.6, fz - 8.0 + j * 5.0), Vector3(0.15, 1.2, 0.15), "wood", false)  # the fence
				continue
			var z := -length / 2.0 + length * (k + 0.5) / sections
			var h := 12.0 if whole else 4.0 + 3.0 * float(k % 2)
			if wood:
				h = 6.0
			elif variant == "stone":
				h = 9.0
			var sg := Kit.group(g, Vector3(side * (width / 2.0 + 6.0), 0, z), 0.0)
			if wood:  # timber tiers on posts
				for t in 3:
					Kit.box(sg, Vector3(-side * (4.0 - t * 2.0), 1.5 + t * 2.0, 0), Vector3(3.0, 0.3, length / sections + 0.1), "wood", t == 0)
					for j in 3:
						Kit.box(sg, Vector3(-side * (4.0 - t * 2.0), 0.8 + t * 1.0, -length / sections / 2.0 + 2.0 + j * (length / sections - 4.0) / 2.0),
							Vector3(0.2, 1.6 + t * 2.0, 0.2), "wood", false)
				continue
			Kit.box(sg, Vector3(0, h / 2.0, 0), Vector3(12.0, h, length / sections + 0.1), stand)
			if whole:
				Kit.box(sg, Vector3(-side * 3.0, h + 0.2, 0), Vector3(6.0, 0.4, length / sections + 0.1), "wood" if variant == "stone" else "marble", false)
				Kit.box(sg, Vector3(side * 6.02, h * 0.5, 0), Vector3(0.1, 3.0, 2.4), "dark", false)
	var end := Kit.group(g, Vector3(0, 0, length / 2.0 + 6.0), 0.0)  # the curved east end
	for k in 9:
		var a := PI * (k + 0.5) / 9.0
		var p := Vector3(cos(a) * (width / 2.0 + 6.0), 0, sin(a) * width * 0.4)
		if wood:
			Kit.box(end, p + Vector3(0, 1.5, 0), Vector3(8.0, 3.0, 6.0), "wood", true, Vector3(0, -a, 0))
		elif whole or k % 2 == 0:
			Kit.box(end, p + Vector3(0, 5.0, 0), Vector3(12.0, 10.0, 8.0), stand, true, Vector3(0, -a, 0))
	for k in 12:  # the starting gates
		var gate := "marble"
		if wood:
			gate = "wood"
		elif variant == "stone":
			gate = "tufa"
		elif not whole:
			gate = "rubble"
		Kit.box(g, Vector3(-width / 2.0 + width * (k + 0.5) / 12.0, 3.0 if not wood else 1.8, -length / 2.0 - 2.0),
			Vector3(width / 12.0 - 1.0, 6.0 if not wood else 3.6, 3.0), gate, k % 3 == 0)


## The Flaminian Circus: an open field with a low wall round it, for games and gathering triumphs.
static func open_circus(g: Node3D, span: float) -> void:
	Kit.box(g, Vector3(0, 0.02, 0), Vector3(300.0 * span, 0.04, 100.0 * span), "path", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(0, 0.6, side * 50.0 * span), Vector3(300.0 * span, 1.2, 0.8), "tufa", false)


## A stone theatre: the half bowl of seats rising to an arcaded outer wall, the orchestra, the stage
## and the tall stage front of columns (the scaenae frons), facing +Z from the stage side. In ruin
## the stage front is down and the upper seats broken.
static func theatre(g: Node3D, size: float, whole: bool) -> void:
	var r := 34.0 * size
	var rows := 10
	for k in rows:  # the cavea, in rising rings of seats
		var rr := r * (0.35 + 0.65 * (k + 1) / rows)
		if not whole and k > rows - 3:
			continue
		var n := 14
		for j in n:
			var a := PI * (j + 0.5) / n
			var p := Vector3(cos(a) * rr, 0, sin(a) * rr)
			var h := 1.0 + k * 1.5
			Kit.box(g, p + Vector3(0, h / 2.0, 0), Vector3(rr * PI / n + 0.4, h, r * 0.07), "travertine" if k < rows - 1 else "brick",
				k == rows - 1, Vector3(0, -a + PI / 2.0, 0))
	var n := 18
	for j in n:  # the outer wall, arched in three storeys
		var a := PI * (j + 0.5) / n
		var p := Vector3(cos(a), 0, sin(a)) * (r + 1.5)
		var ph := 16.0 * size if whole or j % 3 != 0 else 8.0 * size
		var panel := Kit.group(g, p, -a + PI / 2.0)
		Kit.box(panel, Vector3(0, ph / 2.0, 0), Vector3(r * PI / n + 0.6, ph, 2.0), "travertine")
		for s in int(ph / (5.0 * size)):
			Kit.box(panel, Vector3(0, 2.0 * size + s * 5.2 * size, -1.02), Vector3(r * PI / n * 0.5, 3.2 * size, 0.1), "dark", false)
	Kit.cylinder(g, Vector3(0, 0.02, 0), r * 0.33, 0.1, "marble", false, 16)  # the orchestra
	Kit.box(g, Vector3(0, 0.8, -r * 0.08), Vector3(r * 1.3, 1.6, r * 0.14), "wood", true)  # the stage
	if whole:
		Kit.box(g, Vector3(0, 9.0 * size, -r * 0.2), Vector3(r * 1.5, 18.0 * size, 3.0), "marble")  # the stage front
		for k in 9:
			Rome.column(g, Vector3(-r * 0.6 + r * 1.2 * k / 8.0, 1.6, -r * 0.2 + 1.8), 7.0 * size, 0.3)
	else:
		Kit.box(g, Vector3(-r * 0.4, 3.0, -r * 0.2), Vector3(r * 0.4, 6.0, 3.0), "marble")


## Domitian's stadium: a long track (along Z) with seats on both sides and a round end at +Z.
static func stadium(g: Node3D, span: float, whole: bool) -> void:
	var length := 250.0 * span
	var width := 55.0 * span
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(width, 0.06, length), "sand", false)
	for side: float in [-1.0, 1.0]:
		for k in 8:
			if not whole and k % 3 == 1:
				continue
			Kit.box(g, Vector3(side * (width / 2.0 + 5.0), 6.0, -length / 2.0 + length * (k + 0.5) / 8.0),
				Vector3(10.0, 12.0, length / 8.0 + 0.1), "travertine")
	for k in 7:
		var a := PI * (k + 0.5) / 7.0
		Kit.box(g, Vector3(cos(a) * (width / 2.0 + 5.0), 6.0, length / 2.0 + sin(a) * (width / 2.0 + 5.0)), Vector3(10.0, 12.0, 8.0),
			"travertine", true, Vector3(0, -a, 0))


## The Altar of Peace: a marble enclosure of carved walls on a podium, the altar inside, its doors
## on the long axis (Z).
static func altar(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 13.0), "marble")
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 5.6, 3.4, 0), Vector3(0.6, 4.4, 11.0), "marble")
		Kit.box(g, Vector3(side * 5.92, 4.2, 0), Vector3(0.06, 1.6, 10.6), "#c8bca0" if whole else "#9a9080", false)  # the procession
		Kit.box(g, Vector3(side * 3.6, 3.4, 5.5), Vector3(3.4, 4.4, 0.6), "marble")
		Kit.box(g, Vector3(side * 3.6, 3.4, -5.5), Vector3(3.4, 4.4, 0.6), "marble")
	Kit.box(g, Vector3(0, 2.0, -1.0), Vector3(5.0, 1.6, 3.0), "marble")


## A round imperial tomb: a great drum of travertine faced with marble, stepped back, and the
## emperor's bronze on top. `fortress`: Hadrian's, on its square base, with a tower.
static func mausoleum(g: Node3D, size: float, whole: bool, fortress: bool) -> void:
	var r := 22.0 * size
	if fortress:
		Kit.box(g, Vector3(0, 5.0, 0), Vector3(r * 2.6, 10.0, r * 2.6), "travertine")
		Kit.cylinder(g, Vector3(0, 10.0, 0), r, 16.0, "travertine" if whole else "brick", true, 20)
		Kit.box(g, Vector3(0, 30.0, 0), Vector3(r * 0.6, 8.0, r * 0.6), "brick")
		if whole:
			Kit.cylinder(g, Vector3(0, 34.0, 0), 1.0, 4.0, "gold", false, 8)
		else:  # a fort's battlements round the drum
			for k in 16:
				var a := TAU * k / 16.0
				Kit.box(g, Vector3(cos(a) * r, 26.5, sin(a) * r), Vector3(2.0, 1.2, 1.0), "brick", false, Vector3(0, -a, 0))
		return
	Kit.cylinder(g, Vector3.ZERO, r, 12.0, "travertine" if whole else "rubble", true, 20)
	Kit.cylinder(g, Vector3(0, 12.0, 0), r * 0.7, 8.0, "travertine" if whole else "brick", false, 18)
	Kit.cylinder(g, Vector3(0, 20.0, 0), r * 0.35, 8.0, "travertine" if whole else "brick", false, 14)
	if whole:
		Kit.cylinder(g, Vector3(0, 28.0, 0), 1.0, 4.0, "bronze", false, 8)
		Kit.blob(g, Vector3(0, 32.4, 0), 0.5, "bronze")
		for x: float in [-3.0, 3.0]:
			Egypt.obelisk(g, Vector3(x, 0, r + 4.0), 9.0, true)


## A Christian basilica (Constantine's): a long brick nave under a timber roof with lower aisles
## either side, a round apse at the back (-Z), the door at the front (+Z) behind a porch.
static func church(g: Node3D, size: float, whole: bool) -> void:
	var l := 70.0 * size
	var w := 18.0 * size
	var h := 20.0 * size
	Kit.box(g, Vector3(0, h / 2.0, 0), Vector3(w, h, l), "brick")
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * w * 0.85, h * 0.3, 0), Vector3(w * 0.7, h * 0.6, l * 0.96), "brick")
		_roof(g, Vector3(side * w * 0.85, h * 0.6, 0), Vector3(w * 0.72, 1.6 * size, l * 0.97))
		for k in 8:  # the clerestory windows
			Kit.box(g, Vector3(side * (w / 2.0 + 0.02), h * 0.8, -l * 0.4 + l * 0.8 * k / 7.0), Vector3(0.1, h * 0.14, 1.6 * size), "dark", false)
	_roof(g, Vector3(0, h, 0), Vector3(w + 1.0, 5.0 * size, l + 1.0))
	Kit.cylinder(g, Vector3(0, 0, -l / 2.0), w * 0.45, h * 0.75, "brick", true, 12)  # the apse
	Kit.box(g, Vector3(0, h * 0.2, l / 2.0 + 0.02), Vector3(3.0 * size, h * 0.4, 0.1), "wood" if whole else "dark", false)
	Kit.box(g, Vector3(0, 0.3, l / 2.0 + 10.0 * size), Vector3(w * 1.6, 0.6, 20.0 * size), "marble", false)  # the atrium's floor
	Kit.box(g, Vector3(0, 0.02, l / 2.0 + 10.0 * size), Vector3(w * 1.6, 0.04, 20.0 * size), "paving", false)
	var cross := Kit.group(g, Vector3(0, h + 5.0 * size, l / 2.0), 0.0)
	Kit.box(cross, Vector3(0, 1.2, 0), Vector3(0.3, 2.4, 0.3), "bronze", false)
	Kit.box(cross, Vector3(0, 1.6, 0), Vector3(1.4, 0.3, 0.3), "bronze", false)
