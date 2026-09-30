extends RefCounted
## Building blocks for Rome (a sharper world than Greece: Kit.detail 2 rounds its curves more).
## Trees: the Italian stone pine. Buildings: a temple on its podium, a triumphal arch with its
## bronze chariot, an aqueduct, the Rostra, a paved road with milestones and tombs, a house's
## atrium with its pool, a dining room, a household shrine, a street fountain, a vine pergola,
## an apartment block, the Colosseum and the Pantheon, a far city. People: legionaries and their
## century, citizens in the toga. Things: the eagle standard, the fasces, the curule chair, the
## she-wolf, Marcus Aurelius on his horse, a box of book rolls with wax tablets. And the Roman
## gateway for Rome's own hub. Same rules as kit.gd: a group faces +Z.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")


# ---------- trees ----------

## An Italian stone pine: a tall bare trunk leaning a little, forking at the top into a broad,
## flat, dark umbrella of a crown. Dead: the umbrella is bare grey spokes. Returns the crown.
static func stone_pine(parent: Node3D, at: Vector3, size: float = 1.0, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at, at.x * 1.1 + at.z * 0.9)
	var bark := "#6a4a3a" if alive else "deadwood"
	var trunk := Kit.group(g, Vector3.ZERO)
	trunk.rotation.z = 0.08
	Kit.cylinder(trunk, Vector3.ZERO, 0.3 * size, 7.5 * size, bark, true, 7, 0.22 * size)
	var crown := Kit.group(trunk, Vector3(0, 7.5 * size, 0))
	for a: float in [0.3, 2.4, 4.4]:  # the fork: three limbs reaching out and up
		var d := Vector3(cos(a) * 1.6, 1.3, sin(a) * 1.6) * size
		Kit.mesh(crown, Kit._cyl(0.12 * size, d.length()), bark, d / 2.0, Quaternion(Vector3.UP, d.normalized()).get_euler())
	if not alive:
		for k in 7:
			var a := TAU * k / 7.0
			var d := Vector3(cos(a) * 3.6, 1.6, sin(a) * 3.6) * size
			Kit.mesh(crown, Kit._cyl(0.05 * size, d.length()), "deadwood", d / 2.0, Quaternion(Vector3.UP, d.normalized()).get_euler())
		return crown
	Kit.leaves(crown, "g_pine", Vector3(0, 2.2 * size, 0), 9.0 * size, 4.4 * size)
	return crown


# ---------- temples, arches, water ----------

## A column with a flaring leafy capital (Corinthian, to the eye at this size) on a base.
static func column(parent: Node3D, base: Vector3, height: float, radius: float, mat: String = "marble") -> void:
	Kit.cylinder(parent, base, radius * 1.35, radius * 0.6, mat, true, 8)
	Kit.cylinder(parent, base + Vector3(0, radius * 0.6, 0), radius, height - radius * 2.6, mat, true, 10, radius * 0.88)
	Kit.cylinder(parent, base + Vector3(0, height - radius * 2.0, 0), radius * 0.9, radius * 1.6, mat, false, 10, radius * 1.3)
	Kit.box(parent, base + Vector3(0, height - radius * 0.2, 0), Vector3(radius * 3.0, radius * 0.4, radius * 3.0), mat, false)


## A Roman temple: a high podium with a stair only at the front, the porch of columns, a pediment,
## and the cella (the god's room) behind with its tall door. Three styles carry the city's descent
## (docs/rome-city-notes.md 2.1):
##   "etruscan": the old Italic temple of the kings and the early Republic: a podium of tufa, a deep
##     porch of four widely spaced wooden columns with plain Tuscan capitals, stuccoed walls, a
##     painted terracotta roof with wide eaves, terracotta gods along the ridge and a chariot at the
##     peak; in ruin only the tufa podium and the stumps of the posts.
##   "greek": the marble temple of the late Republic: columns all round (peripteral), close-set,
##     sculpture in the pediment.
##   "imperial" (the default): Corinthian, six across and two deep on a tall marble podium.
## `variant`: "gilded" (the roof of gilt bronze tiles), "stripped" (half of them torn off, the
## rafters bare), "odd_columns" (a porch re-columned with columns of different stones and heights),
## "kiln" (a lime kiln beside the podium, burning the temple's marble).
## In ruin only three columns stand, carrying a piece of their beam, on a podium stripped of its
## marble. Faces +Z. Returns where you stand at the top of the stair.
static func temple(parent: Node3D, at: Vector3, yaw: float, whole: bool = true, style: String = "imperial", variant: String = "") -> Vector3:
	var g := Kit.group(parent, at, yaw)
	const W := 14.0
	const D := 24.0
	const H := 3.5  # the podium
	var etruscan := style == "etruscan"
	var stone := "tufa" if etruscan or not whole else "marble"
	Kit.box(g, Vector3(0, H / 2.0, -2.0), Vector3(W, H, D - 4.0), stone)
	for k in 12:  # the stair up the front
		var h := H * (k + 1) / 12.0
		Kit.box(g, Vector3(0, h / 2.0, D / 2.0 - 4.0 + 4.0 - k * 0.33), Vector3(W - 3.0, h, 0.34), stone)
	var top := H
	var col_h := 11.0 if not etruscan else 8.5
	var r := 0.6
	if variant == "kiln":
		Kit.cylinder(g, Vector3(10.5, 0, 0), 2.2, 3.4, "brick", true, 10, 1.4)
		Kit.box(g, Vector3(10.5, 0.8, 2.15), Vector3(1.0, 1.4, 0.2), "dark", false)  # its mouth
		for k in 5:  # the marble waiting to be burnt
			Kit.box(g, Vector3(9.0 + (k % 3) * 1.4, 0.35, 4.0 + (k / 3) * 1.2), Vector3(1.2, 0.7, 0.8), "marble", false, Vector3(0, 0.3 * k, 0))
	if not whole:
		if etruscan:
			for x: float in [-5.25, -1.75, 1.75]:
				Kit.cylinder(g, Vector3(x, top, 5.5), 0.5, 1.2, "deadwood", false, 8)
			Kit.box(g, Vector3(0, top + 0.6, -5.0), Vector3(W - 1.4, 1.2, 12.0), "rubble", false)
			return g.to_global(Vector3(0, top, 7.0)) if g.is_inside_tree() else at + Vector3(0, top, 0)
		for x: float in [-5.0, -2.5, 0.0]:
			column(g, Vector3(x, top, 5.5), col_h, r)
		Kit.box(g, Vector3(-2.5, top + col_h + 0.7, 5.5), Vector3(7.0, 1.4, 1.8), "marble", false)
		Kit.fallen_column(g, Vector3(4.0, top, 2.0), 1.1, 5.0)
		return g.to_global(Vector3(0, top, 7.0)) if g.is_inside_tree() else at + Vector3(0, top, 0)
	if etruscan:
		for x: float in [-5.25, -1.75, 1.75, 5.25]:  # four wooden posts across, two rows deep
			for z: float in [6.0, 2.6]:
				_tuscan(g, Vector3(x, top, z), col_h, 0.5)
		Kit.box(g, Vector3(0, top + col_h / 2.0, -5.0), Vector3(W - 1.4, col_h, 12.0), "plaster")  # the stuccoed cella
		Kit.box(g, Vector3(0, top + 1.0, -5.0), Vector3(W - 1.3, 2.0, 12.1), "#8a2a22", false)  # its painted dado
		Kit.box(g, Vector3(0, top + 3.0, 1.06), Vector3(2.6, 6.0, 0.1), "wood", false)  # the door
		var eave := top + col_h
		Kit.box(g, Vector3(0, eave + 0.5, -2.0), Vector3(W + 0.4, 1.0, D - 3.0), "wood", false)  # the beams
		Kit.box(g, Vector3(0, eave + 0.5, 8.55), Vector3(W + 0.4, 0.9, 0.1), "#c8603a", false)  # the painted terracotta plaques
		_pediment(g, Vector3(0, eave + 1.0, 8.2), W + 0.4, 2.2, 0.8)
		for side: float in [-1.0, 1.0]:  # the roof, wide-eaved, terracotta
			Kit.box(g, Vector3(side * 4.4, eave + 2.3, -2.0), Vector3(9.6, 0.35, D + 1.0), "terracotta", false, Vector3(0, 0, -side * 0.3))
		for k in 5:  # the gods along the ridge, and the chariot at the peak
			Kit.blob(g, Vector3(0, eave + 4.0, -9.0 + k * 3.5), 0.45, "#c8603a", Vector3(0.8, 1.6, 0.8), 6)
		Kit.box(g, Vector3(0, eave + 4.2, 7.4), Vector3(1.8, 0.8, 1.4), "#c8603a", false)
		for x: float in [-1.0, -0.33, 0.33, 1.0]:
			Kit.blob(g, Vector3(x, eave + 4.6, 8.4), 0.35, "#c8603a", Vector3(0.6, 1.0, 1.6), 5)
		return g.to_global(Vector3(0, top, 7.0)) if g.is_inside_tree() else at + Vector3(0, top, 0)
	var greek := style == "greek"
	var odd := variant == "odd_columns"
	var fronts: Array = [-5.5, -3.3, -1.1, 1.1, 3.3, 5.5]
	if odd:
		fronts = [-5.6, -4.0, -2.4, -0.8, 0.8, 2.4, 4.0, 5.6]
	for k in fronts.size():
		var x: float = fronts[k]
		var mat := "marble"
		var h := col_h
		if odd:
			mat = ["#8a8a8a", "#b89090", "marble", "#7a7a80"][k % 4]
			h = col_h - 0.7 + 0.35 * (k % 3)
		column(g, Vector3(x, top, 6.0), h, r if not odd else r * 0.9, mat)
		if odd and h < col_h:
			Kit.box(g, Vector3(x, top + h + (col_h - h) / 2.0, 6.0), Vector3(1.4, col_h - h, 1.4), "brick", false)  # the shim under the beam
	if greek:
		for x: float in [-5.5, 5.5]:  # the colonnade down both sides and across the back
			for z: float in [3.8, 1.6, -0.6, -2.8, -5.0, -7.2, -9.4]:
				column(g, Vector3(x, top, z), col_h, r)
		for x: float in [-3.3, -1.1, 1.1, 3.3]:
			column(g, Vector3(x, top, -9.4), col_h, r)
	else:
		for x: float in [-5.5, 5.5]:
			column(g, Vector3(x, top, 3.2), col_h, r)
	Kit.box(g, Vector3(0, top + col_h / 2.0, -5.0), Vector3(W - 1.4 if not greek else W - 4.0, col_h, 12.0), "marble")  # the cella
	Kit.box(g, Vector3(0, top + 3.5, 1.06), Vector3(3.0, 7.0, 0.1), "bronze", false)  # its door
	var eave := top + col_h
	Kit.box(g, Vector3(0, eave + 0.6, -2.0), Vector3(W + 0.4, 1.2, D - 3.0), "marble", false)  # the entablature
	Kit.box(g, Vector3(0, eave + 0.8, 8.55), Vector3(W + 0.4, 0.5, 0.1), "#b8a888" if not odd else "plaque", false)  # its frieze band, or the inscription
	_pediment(g, Vector3(0, eave + 1.2, 8.1), W + 0.4, 2.55, 0.8)
	if greek:  # the sculpture in the pediment
		for k in 5:
			Kit.blob(g, Vector3(-4.0 + k * 2.0, eave + 1.7 + 0.5 * (1.0 - absf(k - 2.0) / 2.0), 8.6), 0.4, "#d8d0c0", Vector3(0.7, 1.0 + 0.6 * (1.0 - absf(k - 2.0) / 2.0), 0.4), 5)
	var tiles := "roof"
	if variant == "gilded" or variant == "stripped":
		tiles = "gold"
	for side: float in [-1.0, 1.0]:  # the roof, low-pitched
		if variant == "stripped" and side > 0.0:
			for k in 6:  # the rafters bare where the tiles were taken
				Kit.box(g, Vector3(side * 3.6, eave + 2.5, -10.0 + k * 3.4), Vector3(7.6, 0.25, 0.3), "wood", false, Vector3(0, 0, -side * 0.34))
			continue
		Kit.box(g, Vector3(side * 3.6, eave + 2.6, -2.0), Vector3(7.6, 0.35, D - 2.4), tiles, false, Vector3(0, 0, -side * 0.34))
	return g.to_global(Vector3(0, top, 7.0)) if g.is_inside_tree() else at + Vector3(0, top, 0)


## A Tuscan column of the old temples: a wooden shaft on a stone base under a plain round capital
## and a square abacus.
static func _tuscan(parent: Node3D, base: Vector3, height: float, radius: float) -> void:
	Kit.cylinder(parent, base, radius * 1.3, radius * 0.5, "tufa", true, 8)
	Kit.cylinder(parent, base + Vector3(0, radius * 0.5, 0), radius, height - radius * 1.7, "wood", true, 8, radius * 0.85)
	Kit.cylinder(parent, base + Vector3(0, height - radius * 1.2, 0), radius * 0.85, radius * 0.7, "wood", false, 8, radius * 1.2)
	Kit.box(parent, base + Vector3(0, height - radius * 0.25, 0), Vector3(radius * 2.8, radius * 0.5, radius * 2.8), "wood", false)


## A triumphal arch like Titus's: one tall bay between piers faced with columns, the attic above
## carrying its inscription, and the bronze four-horse chariot of the triumph on top. Faces +Z;
## you walk through it along Z. Lost: the chariot gone for its bronze, the inscription torn out,
## half the attic fallen and two columns missing.
static func triumphal_arch(parent: Node3D, at: Vector3, yaw: float, chariot: bool = true, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	if not whole:
		chariot = false
	const W := 13.5
	const DEPTH := 4.8
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 4.9, 6.2, 0), Vector3(3.7, 12.4, DEPTH), "marble")
		for z: float in [DEPTH / 2.0 + 0.3, -DEPTH / 2.0 - 0.3]:
			for x: float in [side * 3.4, side * 6.4]:
				Kit.box(g, Vector3(x, 0.7, z), Vector3(1.2, 1.4, 1.2), "marble")  # the column's pedestal
				if whole or not (side > 0.0 and z > 0.0):
					column(g, Vector3(x, 1.4, z), 11.0, 0.38)
	Kit.arch(g, Vector3(0, 8.4, DEPTH / 2.0 + 0.01), 3.05, 0.0, 180.0, 11, Vector3(0.9, 0.9, 0.2), ["marble"])
	Kit.arch(g, Vector3(0, 8.4, -DEPTH / 2.0 - 0.01), 3.05, 0.0, 180.0, 11, Vector3(0.9, 0.9, 0.2), ["marble"])
	Kit.box(g, Vector3(0, 11.95, 0), Vector3(6.2, 0.9, DEPTH), "marble", false)  # over the crown of the vault
	Kit.box(g, Vector3(0, 12.9, 0), Vector3(W + 0.6, 1.0, DEPTH + 1.4), "marble", false)  # the cornice
	if whole:
		Kit.box(g, Vector3(0, 15.4, 0), Vector3(W - 1.0, 4.0, DEPTH), "marble", false)  # the attic
		Kit.box(g, Vector3(0, 15.4, DEPTH / 2.0 + 0.02), Vector3(7.5, 2.4, 0.05), "plaque", false)  # SENATVS POPVLVSQVE ROMANVS
	else:
		Kit.box(g, Vector3(-3.0, 14.4, 0), Vector3(W * 0.5, 2.0, DEPTH), "marble", false)
		Kit.box(g, Vector3(-2.2, 14.4, DEPTH / 2.0 + 0.02), Vector3(3.6, 1.2, 0.05), "dark", false)  # where the letters were
	if chariot:
		var top := Kit.group(g, Vector3(0, 17.4, 0))
		for k in 4:
			Greek.beast(top, Vector3(-1.5 + k * 1.0, 0, 0.8), 0.0, "horse", "bronze", 0.9)
		Kit.box(top, Vector3(0, 0.9, -1.4), Vector3(1.6, 1.0, 1.2), "bronze", false)  # the car
		Kit.cylinder(top, Vector3(0, 1.4, -1.5), 0.3, 1.6, "bronze", false, 8, 0.2)  # the victor in it
		Kit.blob(top, Vector3(0, 3.2, -1.5), 0.3, "bronze")
		Kit.unsolid(top)


## An aqueduct striding from one point to another on arches: piers every 6 m, `tiers` rows of
## arches one on another, and the covered water channel along the top. Solid piers. Lost: broken
## into standing lengths with gaps between, the channel dry and open.
static func aqueduct(parent: Node3D, from: Vector3, to: Vector3, tiers: int = 1, whole: bool = true) -> Node3D:
	var mid := (from + to) / 2.0
	var length := from.distance_to(to)
	var g := Kit.group(parent, mid, atan2(to.x - from.x, to.z - from.z) - PI / 2.0)  # the run lies along X
	const SPAN := 6.0
	const TIER := 9.0
	var n := int(length / SPAN)
	for t in tiers:
		var base := t * TIER
		for k in n + 1:
			var x := -n * SPAN / 2.0 + k * SPAN
			var standing := whole or k % 4 != 2  # lost: every fourth pier fallen, taking its arches
			if standing:
				Kit.box(g, Vector3(x, base + (TIER - 2.2) / 2.0, 0), Vector3(1.6, TIER - 2.2, 2.4), "tufa")
			else:
				Kit.box(g, Vector3(x, 0.5, 1.5), Vector3(1.6, 1.0, 2.4), "tufa", true, Vector3(0.2, 0.3, 1.2))
			if k < n and (whole or (standing and (k + 1) % 4 != 2)):
				Kit.arch(g, Vector3(x + SPAN / 2.0, base + TIER - 4.7, 0), 2.2, 0.0, 180.0, 9, Vector3(0.9, 0.7, 2.4), ["tufa", "brick"])
				if not whole:
					Kit.box(g, Vector3(x + SPAN / 2.0, base + TIER - 1.1, 0), Vector3(SPAN + 1.6, 2.2, 2.4), "tufa", false)
		if whole:
			Kit.box(g, Vector3(0, base + TIER - 1.1, 0), Vector3(n * SPAN + 1.6, 2.2, 2.4), "tufa", false)
	var top := tiers * TIER
	if whole:
		Kit.box(g, Vector3(0, top + 0.8, 0), Vector3(n * SPAN + 1.6, 1.6, 2.0), "brick", false)  # the channel's walls
		Kit.box(g, Vector3(0, top + 1.7, 0), Vector3(n * SPAN + 1.8, 0.2, 2.2), "tufa", false)  # its cover
	return g


## The Rostra in the Forum: a high platform faced with the bronze beaks of captured warships,
## with a balustrade, and steps up its back (-Z). Faces +Z. Lost: the beaks torn off (their green
## stumps left), the balustrade broken. `variant` (the site through its ages): "beaks" or "" (the
## Republic's, of tufa and travertine), "caesar" (Caesar's and Augustus's: longer, faced with
## marble, columns with the emperors' statues on its back), "stripped" (the beaks prised off, their
## sockets empty), "pulpit" (a stump with a wooden pulpit on it). Returns where a speaker stands.
static func rostra(parent: Node3D, at: Vector3, yaw: float, whole: bool = true, variant: String = "") -> Vector3:
	var g := Kit.group(parent, at, yaw)
	var caesar := variant == "caesar"
	var pulpit := variant == "pulpit"
	var w := 24.0 if caesar else 20.0
	var beaks := whole and variant in ["", "beaks", "caesar"]
	Kit.box(g, Vector3(0, 1.6, 0), Vector3(w, 3.2, 8.0), "marble" if caesar else ("travertine" if not pulpit else "brick"))
	Kit.box(g, Vector3(0, 0.25, 4.1), Vector3(w + 0.4, 0.5, 0.3), "marble", false)
	if pulpit:
		Kit.box(g, Vector3(0, 3.35, 0), Vector3(w, 0.3, 8.0), "rubble", false)
		Kit.box(g, Vector3(0, 4.0, 2.4), Vector3(1.6, 1.6, 1.2), "wood")
		Kit.box(g, Vector3(0, 4.9, 3.0), Vector3(1.8, 0.1, 0.5), "wood", false, Vector3(0.4, 0, 0))  # the lectern
	var n := 9 if caesar else 7
	for k in n:  # the beaks
		var x := -(n - 1) * 1.35 + k * 2.7
		var beak := Kit.group(g, Vector3(x, 1.6, 4.0))
		if not beaks:
			if variant == "stripped":
				Kit.box(beak, Vector3(0, 0, 0.02), Vector3(0.6, 0.5, 0.1), "dark", false)  # the socket
			else:
				Kit.box(beak, Vector3(0, 0, 0.1), Vector3(0.5, 0.4, 0.2), "verdigris", false)
			continue
		Kit.box(beak, Vector3(0, 0, 0.5), Vector3(0.7, 0.5, 1.0), "bronze", false)
		Kit.box(beak, Vector3(0, 0.4, 0.35), Vector3(0.5, 0.3, 0.7), "bronze", false, Vector3(-0.3, 0, 0))
		for fin: float in [-0.18, 0.18]:
			Kit.box(beak, Vector3(0, fin, 1.05), Vector3(0.9, 0.1, 0.25), "bronze", false)  # the ram's blades
	for k in int(w):  # the balustrade
		if (whole and not pulpit) or k % 3 == 0:
			Kit.box(g, Vector3(-w / 2.0 + 0.5 + k, 3.7, 3.8), Vector3(0.15, 1.0, 0.15), "marble", false)
	if whole and not pulpit:
		Kit.box(g, Vector3(0, 4.25, 3.8), Vector3(w, 0.12, 0.3), "marble", false)
	if caesar:  # the emperors on their columns along the back
		for x: float in [-9.0, -4.5, 0.0, 4.5, 9.0]:
			Kit.box(g, Vector3(x, 3.6, -3.0), Vector3(1.0, 0.8, 1.0), "marble", false)
			Kit.cylinder(g, Vector3(x, 4.0, -3.0), 0.25, 2.6, "marble", false, 8)
			Kit.cylinder(g, Vector3(x, 6.6, -3.0), 0.2, 1.4, "bronze" if whole else "verdigris", false, 8, 0.16)
			Kit.blob(g, Vector3(x, 8.2, -3.0), 0.2, "bronze" if whole else "verdigris")
	for k in 8:
		Kit.box(g, Vector3(0, 0.2 + k * 0.4, -4.2 - (7 - k) * 0.35), Vector3(4.0, 0.4 + k * 0.4, 0.35), "travertine")
	return g.to_global(Vector3(0, 3.2, 2.5)) if g.is_inside_tree() else at + Vector3(0, 3.2, 0)


## A paved Roman road from one point to another: dark basalt blocks, raised kerbs, and packed
## gravel walks either side. Walkable (not solid above the ground). Lost: dust and dry earth have
## drifted over it in long patches.
static func via(parent: Node3D, from: Vector3, to: Vector3, width: float = 4.2, whole: bool = true) -> void:
	var mid := (from + to) / 2.0
	var length := from.distance_to(to)
	var g := Kit.group(parent, Vector3(mid.x, 0, mid.z), atan2(to.x - from.x, to.z - from.z))
	Kit.box(g, Vector3(0, 0.04, 0), Vector3(width, 0.08, length), "basalt", false)
	if not whole:
		for k in int(length / 8.0):
			Kit.box(g, Vector3((k % 3 - 1) * 0.8, 0.09, -length / 2.0 + 4.0 + k * 8.0), Vector3(width * 0.7, 0.02, 4.5), "drybed", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * (width / 2.0 + 0.2), 0.12, 0), Vector3(0.4, 0.24, length), "stone", false)
		Kit.box(g, Vector3(side * (width / 2.0 + 1.4), 0.03, 0), Vector3(2.0, 0.06, length), "path", false)


## A milestone: a short column on a square base, the miles to Rome cut in a band. Lost: fallen
## off its base into the grass.
static func milestone(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.2, 0), Vector3(0.8, 0.4, 0.8), "stone")
	if not whole:
		Kit.mesh(g, Greek._prism(0.3, 1.6, 10), "travertine", Vector3(0.2, 0.3, 1.3), Vector3(PI / 2.0, 0.4, 0))
		return
	Kit.cylinder(g, Vector3(0, 0.4, 0), 0.3, 1.6, "travertine", true, 10)
	Kit.box(g, Vector3(0, 1.4, 0.29), Vector3(0.36, 0.3, 0.03), "plaque", false)


## A tomb beside the road. "round": a great drum on a square base with a frieze of garlands
## and ox skulls (like Caecilia Metella's on the Appian Way), 20 m across. "altar": a tall
## altar-shaped monument on steps, with an inscription and an urn on top. Faces +Z (the road).
## Lost: the round one's mound gone and its frieze broken; the altar one's urn fallen.
static func tomb(parent: Node3D, at: Vector3, yaw: float, kind: String = "altar", whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	if kind == "round":
		Kit.box(g, Vector3(0, 3.0, 0), Vector3(22.0, 6.0, 22.0), "tufa")
		Kit.cylinder(g, Vector3(0, 6.0, 0), 10.0, 11.0, "travertine", true, 16)
		Kit.cylinder(g, Vector3(0, 15.0, 0), 10.2, 1.6, "marble", false, 16)  # the frieze
		for k in 16:
			if not whole and k % 3 != 0:
				continue
			var a := TAU * k / 16.0
			Kit.blob(g, Vector3(cos(a) * 10.25, 15.8, sin(a) * 10.25), 0.35, "bone", Vector3(1.0, 1.0, 0.5), 5)
		Kit.box(g, Vector3(0, 13.0, 10.1), Vector3(3.0, 1.2, 0.1), "plaque", false)
		if whole:
			Kit.cylinder(g, Vector3(0, 17.0, 0), 9.6, 3.0, "earth", false, 16, 4.0)  # the earth mound it was crowned with
		return
	for k in 2:
		Kit.box(g, Vector3(0, 0.2 + k * 0.4, 0), Vector3(3.0 - k * 0.5, 0.4, 3.0 - k * 0.5), "stone")
	Kit.box(g, Vector3(0, 2.1, 0), Vector3(1.8, 2.6, 1.8), "marble")
	Kit.box(g, Vector3(0, 2.3, 0.92), Vector3(1.2, 0.9, 0.04), "plaque", false)  # D M: to the spirits of the dead
	Kit.box(g, Vector3(0, 3.5, 0), Vector3(2.1, 0.2, 2.1), "marble", false)
	for side: float in [-1.0, 1.0]:
		Kit.mesh(g, Greek._prism(0.18, 2.0, 8), "marble", Vector3(side * 0.8, 3.75, 0), Vector3(PI / 2.0, 0, 0))
	var urn := Kit.group(g, Vector3(0, 3.6, 0) if whole else Vector3(1.4, 0.35, 1.5))
	if not whole:
		urn.rotation = Vector3(0, 0.6, PI / 2.0)
	Kit.cylinder(urn, Vector3.ZERO, 0.25, 0.5, "marble", false, 10, 0.4)  # the urn
	Kit.blob(urn, Vector3(0, 0.65, 0), 0.25, "marble", Vector3(1.0, 0.6, 1.0), 8)


# ---------- people ----------

## A legionary of the emperors: iron plate armour in bands (lorica segmentata) over a red tunic,
## the iron helmet with its neck guard and cheek pieces, the curved red shield (scutum) with its
## wings and thunderbolts, the heavy javelin (pilum) upright, the short sword on his right hip,
## hobnailed boots. Undead: bones, rust, a faded shield, the pilum bent. Faces +Z. Returns his legs.
static func legionary(parent: Node3D, at: Vector3, undead: bool = false) -> Array:
	var g := Kit.group(parent, at)
	var skin := "bone" if undead else "#c49a78"
	var iron := "rust" if undead else "iron"
	var tunic := "#4a2a2a" if undead else "#9a1e1a"
	var limb := 0.045 if undead else 0.075
	var legs: Array = []
	for side: float in [-1.0, 1.0]:
		var hip := Kit.group(g, Vector3(0.1 * side, 0.82, 0))
		Kit.mesh(hip, Kit._cyl(limb, 0.78), skin, Vector3(0, -0.39, 0))
		Kit.box(hip, Vector3(0, -0.76, 0.05), Vector3(0.14, 0.14, 0.26), "#3a2a1c", false)  # the caligae
		legs.append(hip)
	Kit.cylinder(g, Vector3(0, 0.62, 0), 0.23, 0.3, tunic, false, 8, 0.22)
	for k in 5:  # the bands of the plate armour
		Kit.cylinder(g, Vector3(0, 0.9 + k * 0.1, 0), 0.235 - absf(k - 2) * 0.005, 0.09, iron, false, 10)
	for side: float in [-1.0, 1.0]:  # the shoulder plates
		Kit.blob(g, Vector3(side * 0.22, 1.47, 0), 0.13, iron, Vector3(1.0, 0.6, 1.1), 7)
	Kit.blob(g, Vector3(0, 1.48, 0), 0.2, iron, Vector3(1.2, 0.45, 0.9), 8)
	for k in 4:  # the studded straps hanging before the groin
		Kit.box(g, Vector3(-0.06 + k * 0.04, 0.72, 0.23), Vector3(0.025, 0.28, 0.01), "#4a3424", false)
	Kit.box(g, Vector3(0.24, 0.85, 0.05), Vector3(0.06, 0.5, 0.08), "#4a3424", false, Vector3(0.15, 0, 0))  # the gladius
	Kit.mesh(g, Kit._cyl(limb * 0.8, 0.5), skin, Vector3(0.3, 1.2, 0))
	Kit.mesh(g, Kit._cyl(limb * 0.8, 0.45), skin, Vector3(-0.28, 1.25, 0.1), Vector3(-1.2, 0, 0))
	var shield := Kit.group(g, Vector3(-0.28, 1.0, 0.36), -0.15)
	var face := QuadMesh.new()
	face.size = Vector2(0.66, 1.1)
	Kit.mesh(shield, face, "scutum_dead" if undead else "scutum", Vector3(0, 0, 0.02))
	for side: float in [-1.0, 1.0]:  # its curve: the edges bend back
		Kit.box(shield, Vector3(side * 0.36, 0, -0.06), Vector3(0.08, 1.1, 0.14), "#5a3a2a" if undead else "#7a1614", false,
			Vector3(0, side * 0.6, 0))
	if undead:
		Kit.box(g, Vector3(0.36, 1.1, 0.05), Vector3(0.035, 1.2, 0.035), "deadwood", false)
		Kit.box(g, Vector3(0.45, 1.85, 0.05), Vector3(0.015, 0.5, 0.015), "rust", false, Vector3(0, 0, -0.6))  # bent iron
	else:
		Kit.box(g, Vector3(0.36, 1.2, 0.05), Vector3(0.035, 1.3, 0.035), "wood", false)  # the pilum's shaft
		Kit.box(g, Vector3(0.36, 2.15, 0.05), Vector3(0.015, 0.6, 0.015), "iron", false)  # its long iron shank
	var head := Kit.group(g, Vector3(0, 1.68, 0.02))
	Kit.blob(head, Vector3(0, 0.06, 0), 0.12 if undead else 0.13, skin, Vector3(1.0, 1.1, 1.0), 7)
	Kit.blob(head, Vector3(0, 0.16, -0.02), 0.15, iron, Vector3(1.05, 0.8, 1.05), 8)  # the bowl
	Kit.box(head, Vector3(0, 0.07, -0.16), Vector3(0.3, 0.04, 0.14), iron, false, Vector3(0.35, 0, 0))  # the neck guard
	Kit.box(head, Vector3(0, 0.2, 0.14), Vector3(0.26, 0.03, 0.04), iron, false)  # the brow ridge
	for side: float in [-1.0, 1.0]:
		Kit.box(head, Vector3(side * 0.12, 0.0, 0.05), Vector3(0.03, 0.16, 0.12), iron, false)  # cheek pieces
	if undead:
		for x: float in [-0.045, 0.045]:
			Kit.box(head, Vector3(x, 0.07, 0.124), Vector3(0.016, 0.016, 0.006), "soulfire", false)
	return legs


## A block of legionaries (a real century was 80 men, ten ranks of eight), marching as one node.
## Same shape as kit.gd's squad, so the Hall marches it the same way.
static func century(parent: Node3D, at: Vector3, rows: int = 10, files: int = 8, undead: bool = false) -> Dictionary:
	var root := Kit.group(parent, at)
	var legs: Array = []
	for r in rows:
		for f in files:
			legs.append_array(legionary(root, Vector3((f - (files - 1) / 2.0) * 0.9, 0, -r * 1.0), undead))
	return {"root": root, "legs": legs, "leg": 0, "speed": 0.8 if undead else 1.35, "step": 0.0, "undead": undead}


## A Roman citizen in the toga, over his tunic. A walker (kit.gd's), so he can pace and turn and
## raise his hand. `look` as the walker's, plus: "stripe" (the broad purple stripe of a senator
## on his tunic), "praetexta" (the purple-bordered toga of a magistrate), "scroll" (a book roll
## in his left hand). Undead: a pale shade of himself. Returns what the walker returns.
static func togatus(parent: Node3D, at: Vector3, yaw: float, look: Dictionary, undead: bool = false) -> Dictionary:
	var shaped := look.duplicate()
	shaped["robe"] = "e8e2d2"
	shaped["cloth"] = "toga"
	var w := Kit.walker(parent, at, yaw, shaped)
	var root: Node3D = w["root"]
	var fold := Kit.group(root, Vector3.ZERO)
	# the sinus: the great curve of cloth hanging across the front from the left shoulder
	Kit.box(fold, Vector3(0.02, 1.05, 0.2), Vector3(0.5, 0.1, 0.12), "toga", false, Vector3(0, 0, -0.6))
	Kit.box(fold, Vector3(-0.05, 0.85, 0.21), Vector3(0.44, 0.1, 0.1), "toga", false, Vector3(0, 0, -0.35))
	Kit.box(fold, Vector3(-0.1, 1.5, 0.12), Vector3(0.16, 0.12, 0.12), "toga", false)  # the umbo, the pouch of folds
	Kit.box(fold, Vector3(-0.34, 0.95, 0.02), Vector3(0.14, 0.9, 0.2), "toga", false)  # the end hanging from the left arm
	if look.get("praetexta", false):
		Kit.box(fold, Vector3(0.02, 1.05, 0.265), Vector3(0.5, 0.03, 0.01), "#5a1a4a", false, Vector3(0, 0, -0.6))
		Kit.box(fold, Vector3(-0.34, 0.95, 0.125), Vector3(0.03, 0.9, 0.01), "#5a1a4a", false)
	if look.get("stripe", false):  # the latus clavus, seen on the tunic at the right of the chest
		Kit.box(fold, Vector3(0.14, 1.3, 0.2), Vector3(0.05, 0.4, 0.02), "#5a1a4a", false)
	if look.get("scroll", false):
		Kit.mesh(fold, Kit._cyl(0.04, 0.26), "parchment", Vector3(-0.3, 0.9, 0.12), Vector3(0, 0, PI / 2.0))
	if undead:
		Kit.shade(root, 0.4)
	return w


# ---------- the signs of office ----------

## The eagle standard of a legion: a staff with a spike, the gold eagle with wings raised in a
## wreath at the top. Lost: the eagle taken (as Varus's were), the staff snapped.
static func aquila(parent: Node3D, at: Vector3, whole: bool = true) -> void:
	var g := Kit.group(parent, at)
	if not whole:
		Kit.box(g, Vector3(0, 0.7, 0), Vector3(0.05, 1.4, 0.05), "deadwood")
		Kit.box(g, Vector3(0.6, 0.05, 0.3), Vector3(0.05, 1.2, 0.05), "deadwood", false, Vector3(0, 0.5, PI / 2.0))
		return
	Kit.box(g, Vector3(0, 1.35, 0), Vector3(0.05, 2.7, 0.05), "wood")
	Kit.box(g, Vector3(0, 2.75, 0), Vector3(0.35, 0.08, 0.08), "gold", false)  # the crossbar
	Kit.blob(g, Vector3(0, 3.0, 0), 0.12, "gold", Vector3(0.9, 1.4, 1.0), 6)  # the eagle's body
	Kit.blob(g, Vector3(0, 3.22, 0.07), 0.06, "gold")
	Kit.box(g, Vector3(0, 3.19, 0.14), Vector3(0.03, 0.03, 0.06), "gold", false)  # its beak
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.18, 3.18, -0.02), Vector3(0.28, 0.08, 0.03), "gold", false, Vector3(0, 0, side * 0.7))
		Kit.box(g, Vector3(side * 0.26, 3.4, -0.02), Vector3(0.14, 0.24, 0.03), "gold", false, Vector3(0, 0, side * 0.3))
	Kit.mesh(g, TorusMesh.new(), "olive", Vector3(0, 3.1, 0), Vector3(PI / 2.0, 0, 0), Vector3.ONE * 0.28)  # the wreath


## The fasces: a bundle of elm rods bound with red straps round an axe, carried before a
## magistrate by his lictor as the sign that he could punish and put to death. Lost: its straps
## rotted, the rods fallen apart on the ground and the axe rusted.
static func fasces(parent: Node3D, at: Vector3, whole: bool = true) -> void:
	var g := Kit.group(parent, at)
	if not whole:
		for k in 8:
			Kit.mesh(g, Kit._cyl(0.025, 1.5), "deadwood", Vector3(-0.3 + k * 0.08, 0.03, 0.1 * (k % 3)), Vector3(PI / 2.0, 0.2 * k, 0))
		Kit.box(g, Vector3(0.4, 0.02, -0.2), Vector3(0.22, 0.02, 0.2), "rust", false)
		return
	for k in 8:
		var a := TAU * k / 8.0
		Kit.cylinder(g, Vector3(cos(a) * 0.07, 0, sin(a) * 0.07), 0.025, 1.5, "#8a6a44", false, 5)
	for y: float in [0.3, 0.75, 1.2]:
		Kit.cylinder(g, Vector3(0, y, 0), 0.105, 0.05, "#9a1e1a", false, 8)
	Kit.cylinder(g, Vector3(0, 1.5, 0), 0.02, 0.3, "wood", false, 5)
	Kit.box(g, Vector3(0.12, 1.65, 0), Vector3(0.22, 0.2, 0.02), "iron", false)  # the axe blade
	var body := CylinderShape3D.new()
	body.radius = 0.12
	body.height = 1.8
	Kit.solid(g, body, Vector3(0, 0.9, 0))


## The curule chair (sella curulis): the ivory folding stool of the high magistrates, on
## crossed curved legs. Faces +Z. Lost: folded shut and lying on its side, yellowed.
static func sella(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	var ivory := "#e8dcc0" if whole else "#9a9280"
	if not whole:
		g.rotation.z = PI / 2.0
		g.position.y += 0.3
	for x: float in [-0.3, 0.3]:
		for tilt: float in [-0.55, 0.55]:
			Kit.box(g, Vector3(x, 0.3, 0), Vector3(0.05, 0.7, 0.05), ivory, false, Vector3(tilt, 0, 0))
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(0.7, 0.06, 0.45), ivory, false)
	Kit.box(g, Vector3(0, 0.65, 0), Vector3(0.64, 0.05, 0.4), "#6a1a2a", false)  # the cushion
	var body := BoxShape3D.new()
	body.size = Vector3(0.7, 0.66, 0.5)
	Kit.solid(g, body, Vector3(0, 0.33, 0))


# ---------- the house ----------

## The atrium of a Roman house (domus): walls painted red and black, a mosaic floor, the roof
## sloping in on four sides to the square opening to the sky (compluvium) over the marble pool
## that catches the rain (impluvium), the tablinum (the master's room) open at the back (-Z),
## the door to the street at the front (+Z), and small bedrooms along the sides. Solid walls.
## Lost (whole = false): the roof has fallen in round the opening, its tiles on the floor, and the
## pool is dry. Returns {"root", "pool": its centre, "tablinum": the tablinum's middle, "door": the
## street door} (in the group's space).
static func atrium(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	const W := 12.0
	const D := 14.0
	const H := 5.0
	Kit.box(g, Vector3(0, 0.05, 0), Vector3(W, 0.1, D), "mosaic", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * (W / 2.0 + 0.2), H / 2.0, 0), Vector3(0.4, H, D + 0.8), "fresco")
		for z: float in [-3.5, 0.5, 4.0]:  # the bedroom doors along the sides
			Kit.box(g, Vector3(side * (W / 2.0 - 0.01), 1.2, z), Vector3(0.05, 2.4, 1.2), "dark", false)
	for x: float in [-3.9, 3.9]:  # the front wall, with the street door between
		Kit.box(g, Vector3(x, H / 2.0, D / 2.0 + 0.2), Vector3(4.2, H, 0.4), "fresco")
	Kit.box(g, Vector3(0, H - 0.8, D / 2.0 + 0.2), Vector3(3.6, 1.6, 0.4), "fresco", false)
	Kit.box(g, Vector3(0, H / 2.0, -D / 2.0 - 3.2), Vector3(W, H, 0.4), "fresco")  # the tablinum's back wall
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 3.9, H / 2.0, -D / 2.0), Vector3(4.2, H, 0.4), "fresco")
		Kit.box(g, Vector3(side * 2.2, H / 2.0, -D / 2.0 - 1.6), Vector3(0.4, H, 3.2), "fresco")
	Kit.box(g, Vector3(0, 0.05, -D / 2.0 - 1.6), Vector3(4.0, 0.1, 3.2), "mosaic", false)
	Kit.box(g, Vector3(0, H + 0.2, -D / 2.0 - 1.6), Vector3(4.8, 0.4, 3.6), "roof", false)
	# the inward-sloping roof round the opening; the opening is a quarter of the room across
	const OPEN := Vector2(4.0, 5.0)
	var slope := 0.28
	Kit.box(g, Vector3(0, H + 0.1, (D + OPEN.y) / 4.0), Vector3(W + 0.8, 0.25, (D - OPEN.y) / 2.0 + 0.4), "roof", false,
		Vector3(-slope, 0, 0))
	if whole:
		Kit.box(g, Vector3(0, H + 0.1, -(D + OPEN.y) / 4.0), Vector3(W + 0.8, 0.25, (D - OPEN.y) / 2.0 + 0.4), "roof", false,
			Vector3(slope, 0, 0))
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * (W + OPEN.x) / 4.0, H + 0.1, 0), Vector3((W - OPEN.x) / 2.0 + 0.4, 0.25, OPEN.y), "roof", false,
				Vector3(0, 0, side * slope))
	else:  # the fallen roof: slabs of tiles on the floor, one still hanging from the wall
		Kit.box(g, Vector3(-3.5, 0.4, -4.0), Vector3(4.0, 0.25, 3.0), "roof", false, Vector3(0.2, 0.3, 0.25))
		Kit.box(g, Vector3(3.8, 0.3, 1.0), Vector3(3.0, 0.25, 3.5), "roof", false, Vector3(-0.15, 0.1, -0.2))
		Kit.box(g, Vector3(5.0, H - 1.2, 0), Vector3(2.5, 0.25, OPEN.y), "roof", false, Vector3(0, 0, 1.0))
	Kit.box(g, Vector3(0, 0.15, 0), Vector3(OPEN.x + 0.4, 0.3, OPEN.y + 0.4), "marble", false)  # the pool's rim
	Kit.box(g, Vector3(0, 0.2, 0), Vector3(OPEN.x - 0.2, 0.22, OPEN.y - 0.2), "water" if whole else "drybed", false)
	var rim := BoxShape3D.new()
	rim.size = Vector3(OPEN.x + 0.4, 0.4, OPEN.y + 0.4)
	Kit.solid(g, rim, Vector3(0, 0.2, 0))
	Kit.box(g, Vector3(0, 0.5, OPEN.y / 2.0 + 1.2), Vector3(1.4, 0.9, 0.7), "marble")  # the cartibulum, a marble table
	return {"root": g, "pool": Vector3.ZERO, "tablinum": Vector3(0, 0, -D / 2.0 - 1.6), "door": Vector3(0, 0, D / 2.0 + 0.4)}


## A dining room (triclinium): three broad couches round three sides of a low round table laid
## with bread, fruit, a jug and cups, on a mosaic floor. The open side is +Z. Lost: the covers
## grey, the table bare and knocked askew, the cups on the floor.
static func triclinium(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.03, 0), Vector3(6.0, 0.06, 6.0), "mosaic", false)
	for i in 3:  # left, back, right: each sloping up toward the table, where the diner leaned
		var yaw_i: float = [PI / 2.0, 0.0, -PI / 2.0][i]
		var c := Kit.group(g, [Vector3(-1.9, 0, 0), Vector3(0, 0, -1.9), Vector3(1.9, 0, 0)][i], yaw_i)
		Kit.box(c, Vector3(0, 0.45, 0), Vector3(3.2, 0.5, 1.3), "wood")
		Kit.box(c, Vector3(0, 0.76, 0), Vector3(3.1, 0.16, 1.25), "#6a2e34" if whole else "#4a4648", false, Vector3(-0.12, 0, 0))
		if not whole:
			continue
		for x: float in [-1.0, 0.0, 1.0]:  # a cushion for each of its three diners
			Kit.blob(c, Vector3(x, 0.9, 0.45), 0.2, "#c8a050", Vector3(1.4, 0.6, 1.0), 6)
	if not whole:
		Kit.cylinder(g, Vector3(0.3, 0, 0.4), 0.6, 0.06, "marble", true, 12).rotation.z = 0.25
		for p: Vector3 in [Vector3(0.9, 0.05, 1.0), Vector3(-0.6, 0.05, 1.3)]:
			Kit.mesh(g, Greek._prism(0.045, 0.08, 8), "verdigris", p, Vector3(PI / 2.0, 0, 0))
		return
	Kit.cylinder(g, Vector3(0, 0, 0), 0.08, 0.55, "bronze", false, 6)
	Kit.cylinder(g, Vector3(0, 0.55, 0), 0.6, 0.06, "marble", true, 12)
	Kit.blob(g, Vector3(-0.2, 0.68, 0.1), 0.12, "#c8a060", Vector3(1.3, 0.7, 1.0), 6)  # bread
	for p: Vector3 in [Vector3(0.15, 0.66, -0.15), Vector3(0.25, 0.66, -0.05), Vector3(0.1, 0.68, -0.05)]:
		Kit.blob(g, p, 0.05, "#6a2a5a")  # grapes and figs
	Kit.cylinder(g, Vector3(0.3, 0.61, 0.2), 0.08, 0.24, "bronze", false, 8, 0.05)  # the wine jug
	for p: Vector3 in [Vector3(-0.35, 0.61, -0.25), Vector3(0.0, 0.61, 0.35)]:
		Kit.cylinder(g, p, 0.045, 0.08, "#b8b8c0", false, 8, 0.06)  # silver cups


## The household shrine (lararium): a little temple front on a pedestal against the wall (-Z),
## with the two dancing Lares and the Genius of the house as bronze statuettes, an offering
## bowl, and the house's snake painted below. Lost: the gods of the house gone, the bowl empty
## and cracked, the niche cold.
static func lararium(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(1.2, 1.2, 0.6), "fresco")
	Kit.box(g, Vector3(0, 1.25, 0.05), Vector3(1.3, 0.1, 0.7), "marble", false)
	Kit.box(g, Vector3(0, 1.75, -0.2), Vector3(1.1, 0.9, 0.2), "#1e1a18", false)  # the niche's dark back
	for x: float in [-0.5, 0.5]:
		Kit.cylinder(g, Vector3(x, 1.3, 0.2), 0.05, 0.9, "marble", false, 8)
	_pediment(g, Vector3(0, 2.2, 0.15), 1.3, 0.35, 0.2)
	if not whole:
		Kit.box(g, Vector3(0, 1.32, 0.25), Vector3(0.18, 0.03, 0.09), "clay", false, Vector3(0, 0.3, 0.2))  # half the bowl
		return
	for x: float in [-0.3, 0.3]:  # the Lares, each dancing with a drinking horn raised
		Kit.cylinder(g, Vector3(x, 1.3, 0.0), 0.05, 0.35, "bronze", false, 6, 0.03)
		Kit.blob(g, Vector3(x, 1.72, 0.0), 0.05, "bronze")
		Kit.box(g, Vector3(x + signf(x) * 0.07, 1.72, 0.0), Vector3(0.02, 0.16, 0.02), "bronze", false, Vector3(0, 0, -signf(x) * 0.6))
	Kit.cylinder(g, Vector3(0, 1.3, -0.05), 0.06, 0.45, "bronze", false, 6, 0.04)  # the Genius, veiled, pouring
	Kit.blob(g, Vector3(0, 1.82, -0.05), 0.055, "bronze")
	Kit.cylinder(g, Vector3(0, 1.3, 0.25), 0.08, 0.04, "clay", false, 8, 0.1)  # the offering bowl
	Kit.box(g, Vector3(0, 0.55, 0.31), Vector3(0.8, 0.06, 0.01), "#4a6a3a", false, Vector3(0, 0, 0.2))  # the snake
	Kit.box(g, Vector3(0.1, 0.62, 0.31), Vector3(0.5, 0.05, 0.01), "#4a6a3a", false, Vector3(0, 0, -0.3))


## A street fountain (lacus): a basin of four upright stone slabs, and a pillar at its back (-Z)
## with a carved face whose mouth pours a steady stream into it. Lost: dry, the basin cracked
## and full of dust.
static func fountain(parent: Node3D, at: Vector3, yaw: float, flowing: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.9, 0.45, 0), Vector3(0.2, 0.9, 1.6), "basalt")
		Kit.box(g, Vector3(0, 0.45, side * 0.7), Vector3(2.0, 0.9, 0.2), "basalt")
	Kit.box(g, Vector3(0, 0.6 if flowing else 0.3, 0), Vector3(1.6, 0.05, 1.2), "water" if flowing else "drybed", false)
	Kit.box(g, Vector3(0, 0.8, -0.95), Vector3(0.6, 1.6, 0.4), "basalt")
	Kit.blob(g, Vector3(0, 1.3, -0.72), 0.16, "stone", Vector3(1.0, 1.2, 0.5), 6)  # the face
	Kit.box(g, Vector3(0, 1.22, -0.64), Vector3(0.05, 0.03, 0.05), "bronze", false)  # the spout
	if flowing:
		Kit.box(g, Vector3(0, 0.92, -0.58), Vector3(0.04, 0.6, 0.04), "water", false, Vector3(-0.15, 0, 0))  # the stream


## A vine pergola: two rows of posts along X, beams across, the vine's leaves over the top and
## grapes hanging through. `length` along X. You walk under it. Dead: the vine withered to a few
## brown tangles, no grapes, the timbers grey. Returns the leaves (for the breeze).
static func pergola(parent: Node3D, at: Vector3, yaw: float, length: float = 6.0, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if alive else "deadwood"
	var n := int(length / 2.0)
	for k in n + 1:
		var x := -length / 2.0 + k * (length / n)
		for z: float in [-1.4, 1.4]:
			Kit.cylinder(g, Vector3(x, 0, z), 0.08, 2.5, wood, true, 6)
		Kit.box(g, Vector3(x, 2.55, 0), Vector3(0.1, 0.1, 3.2), wood, false)
	for z: float in [-1.4, 1.4]:
		Kit.box(g, Vector3(0, 2.5, z), Vector3(length + 0.4, 0.1, 0.1), wood, false)
	var leaves := Kit.group(g, Vector3(0, 2.75, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(length * 10)
	for k in int(length * (2.0 if alive else 0.6)):
		Kit.blob(leaves, Vector3(rng.randf_range(-length / 2.0, length / 2.0), rng.randf_range(-0.05, 0.15), rng.randf_range(-1.5, 1.5)),
			rng.randf_range(0.5, 0.8) * (1.0 if alive else 0.5), "plane" if alive else "withered", Vector3(1.2, 0.35, 1.0), 6)
	if not alive:
		return leaves
	for k in int(length):
		var p := Vector3(rng.randf_range(-length / 2.0, length / 2.0), 2.35, rng.randf_range(-1.2, 1.2))
		Kit.blob(g, p, 0.1, "#4a2a4a", Vector3(1.0, 1.5, 1.0), 5)
	return leaves


## An apartment block (insula) on a street: shops with wide openings on the ground floor, brick
## storeys above with small windows and a wooden balcony, a tiled roof. Faces +Z (the street).
## Lost: the roof and the top storey gone, the balcony fallen into the street.
static func insula(parent: Node3D, at: Vector3, yaw: float, floors: int = 4, width: float = 14.0, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	const STOREY := 3.2
	const DEPTH := 10.0
	if not whole:
		floors = maxi(1, floors - 1)
	var h := floors * STOREY
	Kit.box(g, Vector3(0, h / 2.0, 0), Vector3(width, h, DEPTH), "brick")
	var shops := int(width / 3.5)
	for k in shops:
		var x := -width / 2.0 + (k + 0.5) * (width / shops)
		Kit.box(g, Vector3(x, 1.3, DEPTH / 2.0 + 0.01), Vector3(2.4, 2.6, 0.05), "dark", false)
		Kit.box(g, Vector3(x, 2.75, DEPTH / 2.0 + 0.03), Vector3(2.8, 0.3, 0.08), "wood", false)  # the shop's lintel
	for f in range(1, floors):
		for k in shops * 2:
			var x := -width / 2.0 + (k + 0.5) * (width / (shops * 2))
			Kit.box(g, Vector3(x, f * STOREY + 1.4, DEPTH / 2.0 + 0.01), Vector3(0.6, 0.9, 0.05), "dark", false)
	if not whole:  # the balcony down in the street, the roof open to the sky
		Kit.box(g, Vector3(0, 0.3, DEPTH / 2.0 + 1.8), Vector3(width * 0.8, 0.12, 1.4), "deadwood", false, Vector3(0.3, 0, 0.1))
		return
	Kit.box(g, Vector3(0, STOREY + 0.1, DEPTH / 2.0 + 0.7), Vector3(width * 0.8, 0.12, 1.4), "wood", false)  # the balcony
	for k in 4:
		Kit.box(g, Vector3(-width * 0.4 + k * width * 0.8 / 3.0, STOREY * 0.5, DEPTH / 2.0 + 1.3), Vector3(0.14, STOREY, 0.14), "wood", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(0, h + 0.9, side * DEPTH / 4.0), Vector3(width + 0.6, 0.25, DEPTH / 2.0 + 0.9), "roof", false,
			Vector3(side * 0.34, 0, 0))


# ---------- the law court (Rhetorica ad Herennium) ----------

## The praetor's tribunal: a raised platform of stone with steps at its front (+Z), the curule
## chair on it, a railing round it, and the spear (hasta) planted beside it as the sign of the
## court. Lost: its corner fallen, the chair and spear gone. Returns where the judge sits.
static func tribunal(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Vector3:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.75, 0), Vector3(5.0, 1.5, 3.4), "travertine")
	for k in 4:  # the steps up its front, the last one level with the top
		var h := 1.5 * (k + 1) / 4.0
		Kit.box(g, Vector3(0, h / 2.0, 1.85 + (3 - k) * 0.3), Vector3(2.4, h, 0.3), "travertine")
	if not whole:
		Kit.box(g, Vector3(2.2, 0.3, 1.4), Vector3(1.2, 0.6, 1.0), "travertine", true, Vector3(0.3, 0.4, 0.5))  # the fallen corner
		return g.transform * Vector3(0, 1.5, -0.4)
	sella(g, Vector3(0, 1.5, -0.4), 0.0)
	for x: float in [-2.4, 2.4]:
		Kit.box(g, Vector3(x, 1.95, 0), Vector3(0.08, 0.9, 3.4), "bronze", false)
	Kit.box(g, Vector3(1.7, 2.8, -1.2), Vector3(0.05, 2.6, 0.05), "wood", false)  # the hasta
	Kit.box(g, Vector3(1.7, 4.2, -1.2), Vector3(0.08, 0.3, 0.03), "iron", false)
	return g.transform * Vector3(0, 1.5, -0.4)


## The benches of a court (subsellia): plain wooden benches without backs, in `rows` rows along X,
## each a step higher, for the jurors or the advocates and their friends. Faces +Z. Lost: broken
## boards, a bench fallen on its side.
static func subsellia(parent: Node3D, at: Vector3, yaw: float, length: float = 6.0, rows: int = 2, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if whole else "deadwood"
	for r in rows:
		var z := -r * 0.9
		var y := r * 0.3
		if r > 0:
			Kit.box(g, Vector3(0, y / 2.0, z), Vector3(length, y, 0.9), "stone")  # the step it stands on
		var bench := Kit.group(g, Vector3(0, y, z))
		if not whole and r == rows - 1:
			bench.rotation.x = 1.4
			bench.position.z += 0.4
		Kit.box(bench, Vector3(0, 0.45, 0), Vector3(length, 0.08, 0.4), wood, false)
		for x: float in [-length / 2.0 + 0.2, 0.0, length / 2.0 - 0.2]:
			Kit.box(bench, Vector3(x, 0.22, 0), Vector3(0.1, 0.44, 0.34), wood, false)
		var seat := BoxShape3D.new()
		seat.size = Vector3(length, 0.5, 0.4)
		Kit.solid(g, seat, Vector3(0, y + 0.25, z))


## One of the striking pictures the Rhetorica ad Herennium tells you to set in each place of a
## memory house (III.33-37): things out of the ordinary stay in the mind. "poison": the man lying
## sick in bed, and at his side the accused with a cup in his right hand, tablets in his left, and
## a ram's testicles on his fourth finger (for the witnesses: testes); "bloodied": a man in a
## toga stained with blood; "crowned": a figure in a gold crown and a purple cloak; "smeared": a
## figure daubed with red paint; "golden_hand": the golden hand on a post that marks every fifth
## place (III.31). Faces +Z. Lost: pale shades of themselves, the hand gone green.
static func memory_image(parent: Node3D, at: Vector3, yaw: float, kind: String, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	match kind:
		"poison":
			Kit.bed(g, Vector3(0, 0, -0.6), 0.0)
			Kit.blob(g, Vector3(-0.1, 0.72, -0.6), 0.22, "#6a5a4a", Vector3(3.2, 0.7, 1.4), 7)  # the sick man under his blanket
			Kit.blob(g, Vector3(0.75, 0.78, -0.6), 0.12, "#c8a078")
			var w := Kit.walker(g, Vector3(0.2, 0, 0.5), PI, {"robe": "5a4a6a"})
			Greek.kylix(w["hand"], Vector3(0.3, 1.38, 0.42))
			Kit.box(w["root"], Vector3(-0.32, 0.95, 0.12), Vector3(0.18, 0.02, 0.14), "#4a3420", false)  # the tablets
			for dx: float in [-0.03, 0.03]:
				Kit.blob(w["hand"], Vector3(0.3 + dx, 1.32, 0.4), 0.035, "#b89a80")  # on the fourth finger
			if not whole:
				Kit.shade(g, 0.35)
		"bloodied", "crowned", "smeared":
			var look := {"robe": "e8e2d2" if kind == "bloodied" else ("5a1a4a" if kind == "crowned" else "8a6a4a"),
				"skin": "a83a2a" if kind == "smeared" else "c8a078"}
			var w := Kit.walker(g, Vector3.ZERO, 0.0, look)
			var head: Node3D = w["head"]
			match kind:
				"bloodied":
					for p: Vector3 in [Vector3(0.1, 1.2, 0.24), Vector3(-0.08, 0.9, 0.25), Vector3(0.05, 0.6, 0.25)]:
						Kit.box(w["root"], p, Vector3(0.14, 0.12, 0.02), "#8a1010", false, Vector3(0, 0, p.x * 4.0))
				"crowned":
					Kit.mesh(head, TorusMesh.new(), "gold", Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.18, 0.3, 0.18))
				"smeared":
					for p: Vector3 in [Vector3(0.1, 1.3, 0.24), Vector3(-0.12, 1.0, 0.25)]:
						Kit.box(w["root"], p, Vector3(0.2, 0.1, 0.02), "#a83a2a", false, Vector3(0, 0, 0.5))
			if not whole:
				Kit.shade(g, 0.35)
		"golden_hand":
			Kit.box(g, Vector3(0, 0.8, 0), Vector3(0.12, 1.6, 0.12), "stone")
			var metal := "gold" if whole else "verdigris"
			Kit.box(g, Vector3(0, 1.75, 0), Vector3(0.18, 0.22, 0.06), metal, false)  # the palm
			for k in 4:
				Kit.box(g, Vector3(-0.065 + k * 0.043, 1.95, 0), Vector3(0.03, 0.18, 0.04), metal, false)  # the fingers
			Kit.box(g, Vector3(0.11, 1.78, 0), Vector3(0.04, 0.12, 0.04), metal, false, Vector3(0, 0, -0.7))  # the thumb
	return g


# ---------- statues ----------

## The she-wolf who suckled Romulus and Remus: the bronze wolf on a marble plinth, the twins
## beneath her. Faces +Z. Lost: green with age, and the twins gone from under her.
static func she_wolf(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(1.2, 1.2, 2.0), "marble")
	var wolf := Greek.beast(g, Vector3(0, 1.2, 0), 0.0, "wolf", "bronze", 1.1, whole)
	if not whole:
		return wolf
	for x: float in [-0.12, 0.14]:  # the twins, kneeling under her, faces turned up
		Kit.blob(g, Vector3(x, 1.35, 0.05 + x), 0.1, "bronze", Vector3(1.0, 1.3, 1.0), 6)
		Kit.blob(g, Vector3(x, 1.52, 0.1 + x), 0.07, "bronze")
	return wolf


## Marcus Aurelius on his horse, as he still rides on the Capitol: the bronze horse stepping out,
## its right foreleg raised, the emperor bearded and cloaked, his right arm stretched out over the
## people. On a marble plinth. Faces +Z. Lost: green with age, and the emperor thrown from his
## horse, lying on the plinth. Returns {"horse", "rider"}.
static func equestrian(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var metal := "bronze" if whole else "verdigris"
	Kit.box(g, Vector3(0, 1.1, 0), Vector3(2.2, 2.2, 4.2), "marble")
	Kit.box(g, Vector3(0, 2.25, 0), Vector3(2.4, 0.1, 4.4), "marble", false)
	var horse := Greek.beast(g, Vector3(0, 2.3, 0), 0.0, "horse", "bronze", 1.35, whole)
	(horse["legs"][0] as Node3D).rotation.x = -0.9  # the right foreleg lifted
	var rider := Kit.group(g, Vector3(0, 2.3 + 2.05, 0.05) if whole else Vector3(0.7, 2.6, -1.2))
	if not whole:
		rider.rotation = Vector3(0.2, 0.6, 1.4)
	Kit.box(rider, Vector3(0, 0.1, 0), Vector3(0.5, 0.3, 0.6), metal, false)  # seat and thighs
	for side: float in [-1.0, 1.0]:
		Kit.box(rider, Vector3(side * 0.34, -0.3, 0.1), Vector3(0.12, 0.7, 0.14), metal, false, Vector3(0.2, 0, 0))
	Kit.cylinder(rider, Vector3(0, 0.2, 0), 0.24, 0.75, metal, false, 8, 0.2)
	Kit.blob(rider, Vector3(0, 0.95, 0), 0.26, metal, Vector3(1.3, 0.55, 0.85), 8)
	Kit.box(rider, Vector3(-0.1, 0.65, -0.2), Vector3(0.55, 0.7, 0.08), metal, false, Vector3(0.2, 0, 0))  # the cloak
	Kit.box(rider, Vector3(-0.45, 1.05, 0.25), Vector3(0.1, 0.1, 0.75), metal, false, Vector3(0.25, 0.5, 0))  # the right arm held out
	Kit.blob(rider, Vector3(-0.62, 1.14, 0.55), 0.07, metal)
	Kit.blob(rider, Vector3(0, 1.25, 0.02), 0.14, metal, Vector3(1.0, 1.15, 1.05), 8)
	Kit.blob(rider, Vector3(0, 1.12, 0.09), 0.12, metal, Vector3(1.0, 1.1, 0.7), 6)  # the philosopher's beard
	return {"horse": horse, "rider": rider}


## A box of book rolls (capsa), with its lid off and a label on each roll; beside it a set of
## wax tablets bound as a little book, a stylus, an inkpot and a reed pen. Lost: the box tipped
## over, the rolls spilled out grey and rotten, the tablets' wax gone.
static func capsa(parent: Node3D, at: Vector3, whole: bool = true) -> void:
	var g := Kit.group(parent, at)
	if not whole:
		Kit.mesh(g, Greek._prism(0.22, 0.45, 10), "#4a3a30", Vector3(0, 0.22, 0), Vector3(PI / 2.0, 0.3, 0))
		for k in 5:
			Kit.mesh(g, Kit._cyl(0.045, 0.3), "ashbed", Vector3(0.1 + k * 0.1, 0.05, 0.35 + (k % 2) * 0.1), Vector3(0, 0.3 * k, PI / 2.0))
		Kit.box(g, Vector3(-0.45, 0.02, 0.1), Vector3(0.3, 0.04, 0.22), "deadwood", false, Vector3(0, 0.3, 0))
		return
	Kit.cylinder(g, Vector3.ZERO, 0.22, 0.45, "#6a3a24", true, 10)
	Kit.cylinder(g, Vector3(0, 0.44, 0), 0.23, 0.03, "bronze", false, 10)
	for k in 7:
		var a := TAU * k / 7.0
		var p := Vector3(cos(a) * 0.12, 0.3, sin(a) * 0.12)
		var tall := 0.28 + (k % 3) * 0.04
		Kit.cylinder(g, p, 0.045, tall, "parchment", false, 6)
		Kit.box(g, p + Vector3(0.05, tall - 0.04, 0), Vector3(0.01, 0.06, 0.03), "#9a1e1a", false)  # the title tag
	Kit.cylinder(g, Vector3(0.35, 0, 0.2), 0.24, 0.1, "#6a3a24", false, 10)  # the lid, set down
	var tablets := Kit.group(g, Vector3(-0.45, 0, 0.1), 0.3)
	for k in 3:
		Kit.box(tablets, Vector3(0, 0.015 + k * 0.03, 0), Vector3(0.3, 0.025, 0.22), "#4a3420", false)
	Kit.box(tablets, Vector3(0, 0.1, 0), Vector3(0.24, 0.005, 0.16), "#1e1c14", false)  # the black wax, open
	Kit.box(tablets, Vector3(0.05, 0.11, 0.12), Vector3(0.16, 0.01, 0.01), "bronze", false, Vector3(0, 0.4, 0))  # the stylus
	Kit.cylinder(g, Vector3(-0.1, 0, -0.35), 0.05, 0.08, "bronze", false, 8)  # the inkpot
	Kit.box(g, Vector3(-0.05, 0.12, -0.33), Vector3(0.01, 0.2, 0.01), "#c8b890", false, Vector3(0, 0, -0.4))  # the reed pen


## A pediment's triangle standing on `base` (the middle of its bottom edge): `width` across,
## `rise` high, `depth` thick, facing +Z.
static func _pediment(parent: Node3D, base: Vector3, width: float, rise: float, depth: float) -> void:
	var r := width / sqrt(3.0)  # a triangle of that width has its corners on a circle this big
	var squash := rise / (1.5 * r)
	Kit.mesh(parent, Greek._prism(r, depth, 3), "marble", base + Vector3(0, 0.5 * r * squash, 0), Vector3(-PI / 2.0, 0, 0),
		Vector3(1.0, 1.0, squash))


# ---------- the city seen from afar ----------

## The Colosseum as seen across the city: an oval of four storeys, three of arches and the
## attic above with its windows and masts for the awning. About 190 x 156 m and 48 m high at
## `size` 1. Not solid. Lost: the outer ring fallen along its southern side (-Z), as it stands today.
static func colosseum(parent: Node3D, at: Vector3, size: float = 1.0, whole: bool = true) -> void:
	var g := Kit.group(parent, at)
	g.scale = Vector3.ONE * size
	const A := 94.0
	const B := 78.0
	var n := 64
	for k in n:
		var t := TAU * (k + 0.5) / n
		var p := Vector3(cos(t) * A, 0, sin(t) * B)
		var normal := Vector3(cos(t) / A, 0, sin(t) / B).normalized()
		var yaw := atan2(normal.x, normal.z)
		var seg := Vector3(cos(TAU * (k + 1) / n) * A, 0, sin(TAU * (k + 1) / n) * B).distance_to(
			Vector3(cos(TAU * k / n) * A, 0, sin(TAU * k / n) * B))
		var panel := Kit.group(g, p, yaw)
		var fallen := not whole and sin(t) < -0.2  # the side toward -Z
		var high := 48.0 if not fallen else 30.0 - 12.0 * absf(cos(t))
		Kit.box(panel, Vector3(0, high / 2.0, -2.0), Vector3(seg + 0.3, high, 4.0), "travertine", false)
		for storey in (3 if not fallen else 2):
			Kit.box(panel, Vector3(0, 4.2 + storey * 11.0, 0.02), Vector3(seg * 0.55, 7.0, 0.1), "dark", false)
		if fallen:
			continue
		Kit.box(panel, Vector3(0, 42.0, 0.02), Vector3(seg * 0.2, 1.8, 0.1), "dark", false)  # the attic's window
		if k % 2 == 0:
			Kit.box(panel, Vector3(0, 50.0, -0.5), Vector3(0.3, 5.0, 0.3), "wood", false)  # a mast for the awning
	Kit.box(g, Vector3(0, 0.1, 0), Vector3(A * 1.6, 0.2, B * 1.6), "sand", false)  # the arena's floor


## The Pantheon: a porch of eight columns under a pediment, the great round drum behind, and
## the dome with its open eye (oculus). 43 m across at `size` 1. The drum is solid. Faces +Z.
## Lost: three columns of the porch gone, and the inscription.
static func pantheon(parent: Node3D, at: Vector3, yaw: float, size: float = 1.0, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	g.scale = Vector3.ONE * size
	const R := 22.0
	Kit.cylinder(g, Vector3.ZERO, R, 22.0, "brick", true, 20)
	Kit.cylinder(g, Vector3(0, 21.5, 0), R + 0.8, 1.2, "travertine", false, 20)  # the cornice
	var dome := Kit.blob(g, Vector3(0, 22.0, 0), R, "#7e7a74", Vector3(1.0, 1.0, 1.0), 16)  # lead on the dome
	dome.scale = Vector3(1.0, 0.95, 1.0)
	Kit.cylinder(g, Vector3(0, 22.0 + R * 0.95 - 0.8, 0), 4.5, 1.0, "dark", false, 14)  # the oculus
	Kit.box(g, Vector3(0, 11.0, R + 3.0), Vector3(22.0, 22.0, 8.0), "brick")  # the block joining porch and drum
	for x: float in [-14.0, -10.0, -6.0, -2.0, 2.0, 6.0, 10.0, 14.0]:
		if whole or not x in [-10.0, 6.0, 14.0]:
			column(g, Vector3(x, 0, R + 12.0), 14.0, 0.75, "giallo" if absf(x) < 3.0 else "marble")
	Kit.box(g, Vector3(0, 15.0, R + 8.5), Vector3(33.0, 2.2, 9.5), "marble", false)  # the entablature
	Kit.box(g, Vector3(0, 15.0, R + 13.3), Vector3(20.0, 0.9, 0.1), "plaque" if whole else "dark", false)  # M AGRIPPA L F COS TERTIVM FECIT
	_pediment(g, Vector3(0, 16.1, R + 12.6), 33.0, 7.4, 1.0)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 8.25, 19.9, R + 8.5), Vector3(18.0, 0.4, 10.0), "roof", false, Vector3(0, 0, -side * 0.42))


## A city of red roofs round a point, for the far distance: `count` blocks of houses and
## apartment blocks between `near` and `far` metres out. Not solid.
static func far_city(parent: Node3D, at: Vector3, near: float, far: float, count: int = 60, seed_value: int = 17) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in count:
		var a := rng.randf() * TAU
		var r := rng.randf_range(near, far)
		var w := rng.randf_range(8.0, 16.0)
		var d := rng.randf_range(8.0, 14.0)
		var h := rng.randf_range(5.0, 16.0)
		var p := at + Vector3(cos(a) * r, 0, sin(a) * r)
		Kit.box(parent, p + Vector3(0, h / 2.0, 0), Vector3(w, h, d), "plaster" if k % 3 else "brick", false, Vector3(0, a, 0))
		Kit.box(parent, p + Vector3(0, h + 0.4, 0), Vector3(w + 0.6, 0.8, d + 0.6), "roof", false, Vector3(0, a, 0))


# ---------- Rome's hub ----------

## Rome's gateway to a book's place (Greece's is kit.gd's gateway): an arch of dressed stone on
## two piers, with a keystone. Open ones glow with the light of the place beyond; a mastered one
## burns with a flame in a bronze bowl on top; a closed one is blocked with fallen stones. Same
## returns as kit.gd's gateway: the glow's light, or null.
static func gateway(parent: Node3D, at: Vector3, yaw: float, open: bool, mastered: bool = false) -> OmniLight3D:
	var g := Kit.group(parent, at, yaw)
	for x: float in [-1.75, 1.75]:
		Kit.box(g, Vector3(x, 1.7, 0), Vector3(0.8, 3.4, 0.9), "travertine")
		Kit.box(g, Vector3(x, 3.45, 0), Vector3(1.0, 0.1, 1.0), "marble", false)  # the impost
	Kit.arch(g, Vector3(0, 3.5, 0), 1.35, 0.0, 180.0, 9, Vector3(0.62, 0.6, 0.9), ["travertine", "marble"])
	Kit.box(g, Vector3(0, 5.2, 0.05), Vector3(0.5, 0.75, 1.0), "marble", false)  # the keystone
	Kit.box(g, Vector3(0, 5.75, 0), Vector3(4.4, 0.5, 1.0), "travertine", false)
	Kit.box(g, Vector3(0, 0.08, 0), Vector3(4.4, 0.16, 1.4), "basalt", false)
	if mastered:
		Kit.cylinder(g, Vector3(0, 6.0, 0), 0.3, 0.25, "bronze", false, 8, 0.5)
		for p: Vector3 in [Vector3(0, 6.45, 0), Vector3(0.12, 6.35, 0.08)]:
			Kit.blob(g, p, 0.2, "fire", Vector3(1.0, 1.7, 1.0), 5)
	if open:
		var q := QuadMesh.new()
		q.size = Vector2(2.7, 4.8)
		Kit.mesh(g, q, "glow", Vector3(0, 2.4, 0))
		var l := OmniLight3D.new()
		l.position = Vector3(0, 2.2, 1.0)
		l.light_color = Color("ffd49a")
		l.light_energy = 1.4
		l.omni_range = 7.0
		g.add_child(l)
		return l
	for s in [[Vector3(-0.6, 0.4, 0), 0.8], [Vector3(0.55, 0.35, 0.1), 0.7], [Vector3(0.0, 1.0, -0.05), 0.6]]:
		Kit.box(g, s[0], Vector3(s[1], s[1], s[1]), "travertine", true, Vector3(0.3, s[1] * 2.0, 0.2))
	var bar := BoxShape3D.new()
	bar.size = Vector3(2.7, 4.8, 0.3)
	Kit.solid(g, bar, Vector3(0, 2.4, 0))
	return null
