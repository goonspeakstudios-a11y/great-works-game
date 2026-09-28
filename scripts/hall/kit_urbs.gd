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
## fora, whose size is their place in the city). Returns a light to flicker, or null.
static func build(parent: Node3D, m: Dictionary, at: Vector3, yaw: float, whole: bool, span: float) -> OmniLight3D:
	var size := float(m.get("size", 1.0))
	var g := Kit.group(parent, at + Vector3(0, float(m.get("raised", 0.0)), 0), yaw)
	g.name = str(m.get("id", "monument"))
	var light: OmniLight3D = null
	match str(m["kind"]):
		"temple":
			g.scale = Vector3.ONE * size
			Rome.temple(g, Vector3.ZERO, 0.0, whole)
		"double_temple":
			double_temple(g, size, whole)
		"round_temple":
			light = round_temple(g, size, whole, bool(m.get("fire", false)) and whole)
		"hall":
			hall(g, size, whole)
		"tabularium":
			tabularium(g, whole)
		"curia":
			curia(g, whole)
		"basilica":
			basilica(g, size, whole)
		"vaulted_hall":
			vaulted_hall(g, size, whole)
		"rostra":
			Rome.rostra(g, Vector3.ZERO, 0.0, whole)
		"shrine":
			shrine(g, whole)
		"arch":
			Rome.triumphal_arch(g, Vector3.ZERO, 0.0, true, whole)
		"forum":
			forum(g, float(m.get("w", 60.0)) * span, float(m.get("d", 100.0)) * span, whole)
		"column":
			column_monument(g, size, whole)
		"markets":
			markets(g, whole)
		"amphitheatre":
			Rome.colosseum(g, Vector3.ZERO, size, whole)
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
			circus(g, span, whole)
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
static func round_temple(g: Node3D, size: float, whole: bool, fire: bool) -> OmniLight3D:
	var r := 4.5 * size
	Kit.cylinder(g, Vector3.ZERO, r + 0.6, 1.2, "marble" if whole else "tufa", true, 18)
	Kit.cylinder(g, Vector3(0, 1.2, 0), r * 0.62, 6.0 * size, "marble", true, 16)
	var n := 16 if whole else 7
	for k in n:
		var a := TAU * k / 16.0
		Rome.column(g, Vector3(cos(a) * r, 1.2, sin(a) * r), 7.0 * size, 0.28 * size)
	if whole:
		Kit.cylinder(g, Vector3(0, 1.2 + 7.0 * size, 0), r + 0.4, 0.6, "marble", false, 18)
		Kit.cylinder(g, Vector3(0, 1.8 + 7.0 * size, 0), r + 0.6, 2.4 * size, "bronze", false, 18, 0.5)
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
static func curia(g: Node3D, whole: bool) -> void:
	Kit.box(g, Vector3(0, 0.5, 1.0), Vector3(12.0, 1.0, 20.0), "travertine" if whole else "rubble")
	Kit.box(g, Vector3(0, 8.0, 0), Vector3(11.0, 14.0, 18.0), "brick")
	Kit.box(g, Vector3(0, 4.0, 9.02), Vector3(2.6, 5.4, 0.1), "bronze" if whole else "dark", false)
	for k in 3:
		Kit.box(g, Vector3(0, 11.5, 9.02), Vector3(1.4 + k * 0.0, 2.6, 0.1), "dark", false)
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
static func circus(g: Node3D, span: float, whole: bool) -> void:
	var length := 600.0 * span
	var width := 140.0 * span
	Kit.box(g, Vector3(0, 0.05, 0), Vector3(width, 0.1, length), "sand", false)
	Kit.box(g, Vector3(0, 0.8, 0), Vector3(3.0, 1.6, length * 0.62), "marble")  # the spina
	for z: float in [-length * 0.31, length * 0.31]:  # the turning posts, three cones each
		for k in 3:
			Kit.cylinder(g, Vector3(-0.8 + k * 0.8, 1.6, z), 0.4, 3.0, "gold" if whole else "bronze", false, 8, 0.05)
	var sections := 16
	for side: float in [-1.0, 1.0]:
		for k in sections:
			if not whole and k % 3 == 1:
				continue
			var z := -length / 2.0 + length * (k + 0.5) / sections
			var h := 12.0 if whole else 4.0 + 3.0 * float(k % 2)
			var sg := Kit.group(g, Vector3(side * (width / 2.0 + 6.0), 0, z), 0.0)
			Kit.box(sg, Vector3(0, h / 2.0, 0), Vector3(12.0, h, length / sections + 0.1), "brick")
			if whole:
				Kit.box(sg, Vector3(-side * 3.0, h + 0.2, 0), Vector3(6.0, 0.4, length / sections + 0.1), "marble", false)
				Kit.box(sg, Vector3(side * 6.02, h * 0.5, 0), Vector3(0.1, 3.0, 2.4), "dark", false)
	var end := Kit.group(g, Vector3(0, 0, length / 2.0 + 6.0), 0.0)  # the curved east end
	for k in 9:
		var a := PI * (k + 0.5) / 9.0
		var p := Vector3(cos(a) * (width / 2.0 + 6.0), 0, sin(a) * width * 0.4)
		if whole or k % 2 == 0:
			Kit.box(end, p + Vector3(0, 5.0, 0), Vector3(12.0, 10.0, 8.0), "brick", true, Vector3(0, -a, 0))
	for k in 12:  # the starting gates
		Kit.box(g, Vector3(-width / 2.0 + width * (k + 0.5) / 12.0, 3.0, -length / 2.0 - 2.0), Vector3(width / 12.0 - 1.0, 6.0, 3.0),
			"marble" if whole else "rubble", k % 3 == 0)


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
