extends RefCounted
## More building blocks for the Greek places still to come, the things each book's own ground
## needs: Homer's camp, forge, bow and bed, the underworld's trench and the Sirens' rock; Hesiod's
## jar, Prometheus's crag, the Muses' spring and the five ages; Sappho's orchard, shrine and
## sparrow chariot; and on through the tragedians, the historians and the philosophers.
## Same rules as kit.gd: a group faces +Z; each piece builds whole or lost to the world (flags
## `alive`, `whole`, `lit`, `flowing`) and returns what the Hall needs to bring it to life.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")


# ---------- shared ----------

## A low mist lying on the ground over a patch `size` across: the underworld, a cave, a battlefield
## at dawn. Grey sprites that drift slowly and never rise far.
static func ground_fog(parent: Node3D, centre: Vector3, size: float) -> CPUParticles3D:
	var p := Kit._drift(parent, centre + Vector3(0, 0.3, 0), 40, 12.0, 3.0, "mist", Vector3(1, 0.05, 0), 180.0, Vector2(0.05, 0.2))
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size / 2.0, 0.2, size / 2.0)
	p.preprocess = 12.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	return p


## A funeral bier: a couch on a stand with a body laid out on it under a shroud, the feet toward
## the door (+Z), as Patroclus lay in Achilles' hut and the dead of the first year of the war lay
## before Pericles spoke. `body` false leaves it empty (the empty bier carried for the missing).
## Lost: the shroud grey and the frame rotted.
static func bier(parent: Node3D, at: Vector3, yaw: float, body: bool = true, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if whole else "deadwood"
	Kit.box(g, Vector3(0, 0.75, 0), Vector3(0.9, 0.1, 2.1), wood)
	for p: Vector3 in [Vector3(-0.38, 0.37, -0.95), Vector3(0.38, 0.37, -0.95), Vector3(-0.38, 0.37, 0.95), Vector3(0.38, 0.37, 0.95)]:
		Kit.box(g, p, Vector3(0.08, 0.74, 0.08), wood, false)
	Kit.box(g, Vector3(0, 0.84, 0), Vector3(0.85, 0.08, 2.0), "#6a2e34" if whole else "#4a4648", false)  # the cover
	if body:
		Kit.blob(g, Vector3(0, 0.98, 0.1), 0.2, "#e8e2d2" if whole else "ashbed", Vector3(1.3, 0.6, 4.5), 7)  # under the shroud
		Kit.blob(g, Vector3(0, 1.0, -0.75), 0.13, "#e8e2d2" if whole else "ashbed", Vector3(1.0, 0.9, 1.1), 6)  # the head


## A pithos: a great storage jar taller than a child, sunk a little in the ground; with `open`
## its lid lies beside it (Pandora's jar, with only Hope left inside). Lost: cracked open, its
## pieces round it.
static func pithos(parent: Node3D, at: Vector3, open: bool = false, whole: bool = true) -> void:
	var g := Kit.group(parent, at)
	if not whole:
		Kit.cylinder(g, Vector3.ZERO, 0.35, 0.6, "clay", true, 10, 0.45)
		Greek._sherds(g, Vector3.ZERO, 1.0, 6, 0.3)
		return
	Kit.cylinder(g, Vector3.ZERO, 0.3, 0.5, "clay", true, 10, 0.5)
	Kit.cylinder(g, Vector3(0, 0.5, 0), 0.5, 0.6, "clay", false, 10, 0.3)
	Kit.cylinder(g, Vector3(0, 1.1, 0), 0.22, 0.12, "clay", false, 10, 0.25)
	for k in 3:  # the rope pattern pressed round its belly
		Kit.cylinder(g, Vector3(0, 0.45 + k * 0.18, 0), 0.51 - absf(k - 1) * 0.04, 0.03, "#8e5638", false, 10)
	if open:
		Kit.cylinder(g, Vector3(0.6, 0, 0.3), 0.26, 0.06, "clay", false, 10)
	else:
		Kit.cylinder(g, Vector3(0, 1.22, 0), 0.26, 0.06, "clay", false, 10)


## A small Greek shrine: a naiskos of two columns in front of a cella, a pediment, and the god's
## statue inside, with an altar before it. `god` is who stands inside (a People WHO name). Lost:
## a column down, the statue gone, the altar broken. Faces +Z.
static func shrine(parent: Node3D, at: Vector3, yaw: float, god: String = "aphrodite", whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.25, 0), Vector3(4.0, 0.5, 5.0), "marble")
	Kit.box(g, Vector3(0, 2.3, -1.0), Vector3(3.6, 3.6, 3.0), "marble")
	Kit.box(g, Vector3(0, 1.6, 0.52), Vector3(1.4, 2.2, 0.05), "dark", false)  # the doorway
	for x: float in [-1.4, 1.4]:
		Kit.column(g, Vector3(x, 0.5, 1.8), 3.5, not whole and x > 0.0)
	Kit.box(g, Vector3(0, 4.3, 0.4), Vector3(4.0, 0.4, 3.8) if whole else Vector3(2.4, 0.4, 3.8), "marble", false)
	if whole:
		Kit.mesh(g, Greek._prism(2.3, 0.4, 3), "marble", Vector3(0, 5.05, 2.0), Vector3(-PI / 2.0, 0, 0), Vector3(1.0, 1.0, 0.45))
		var statue := People.figure(g, Vector3(0, 0.5, -1.2), 0.0, god)
		for mi in statue["root"].find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = Kit.Tex.material("marble")
	Greek.altar(g, Vector3(0, 0, 4.0), PI, "greek", false, whole)
	return g


# ---------- Homer: the camp before Troy ----------

## Achilles' hut in the camp by the ships (Iliad 24): a lodge of pine logs thatched with reeds
## from the meadow, a great courtyard fenced with close-set stakes, its door barred by a single
## pine beam, a hearth, and couches heaped with fleeces. Faces +Z (the door). Lost: the roof
## fallen in, the fence broken down. Returns {"root", "hearth": its light or null, "couch": where
## Achilles sits, "door": the courtyard gate} (the spots in the parent's space).
static func achaean_hut(parent: Node3D, at: Vector3, yaw: float, whole: bool = true, lit: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if whole else "deadwood"
	const W := 8.0
	const D := 7.0
	for side: float in [-1.0, 1.0]:  # the log walls
		for k in 5:
			Kit.mesh(g, Kit._cyl(0.2, D), wood, Vector3(side * W / 2.0, 0.2 + k * 0.38, -D / 2.0 - 1.0), Vector3(PI / 2.0, 0, 0))
		var wall := BoxShape3D.new()
		wall.size = Vector3(0.4, 2.0, D)
		Kit.solid(g, wall, Vector3(side * W / 2.0, 1.0, -D / 2.0 - 1.0))
	for k in 5:
		Kit.mesh(g, Kit._cyl(0.2, W), wood, Vector3(0, 0.2 + k * 0.38, -D - 1.0), Vector3(0, 0, PI / 2.0))
	Kit.box(g, Vector3(0, 1.0, -D - 1.0), Vector3(W, 2.0, 0.4), wood, true)
	for side: float in [-1.0, 1.0]:  # the front: logs either side of the door
		Kit.box(g, Vector3(side * (1.2 + (W / 2.0 - 1.2) / 2.0), 1.0, -1.0), Vector3(W / 2.0 - 1.2, 2.0, 0.4), wood)
	if whole:
		for side: float in [-1.0, 1.0]:  # the reed thatch
			Kit.box(g, Vector3(side * W / 4.0, 3.0, -D / 2.0 - 1.0), Vector3(W / 2.0 + 1.2, 0.3, D + 1.2), "#b0a070", false,
				Vector3(0, 0, -side * 0.5))
	else:
		Kit.box(g, Vector3(-1.0, 0.5, -D / 2.0 - 1.0), Vector3(W / 2.0, 0.3, D * 0.7), "#6e6250", false, Vector3(0.1, 0.3, 0.35))
	var hearth := Kit.hearth(g, Vector3(0, 0, -D / 2.0 - 1.0), lit)
	for x: float in [-2.6, 2.6]:  # couches with fleeces
		Kit.box(g, Vector3(x, 0.35, -D / 2.0 - 1.5), Vector3(1.0, 0.5, 2.2), wood)
		Kit.blob(g, Vector3(x, 0.65, -D / 2.0 - 1.5), 0.4, "#dcd4c0" if whole else "ashbed", Vector3(1.2, 0.35, 2.4), 6)
	var n := 22
	for k in n:  # the fence of stakes round the courtyard in front
		var a := PI * (k + 0.5) / n
		var p := Vector3(cos(a) * 7.0, 0, sin(a) * 6.0 - 1.0)
		if absf(p.x) < 1.2 and p.z > 3.0:
			continue  # the gate
		if not whole and k % 3 == 1:
			Kit.box(g, p + Vector3(0, 0.1, 0.5), Vector3(0.14, 0.14, 1.6), "deadwood", false, Vector3(0, a, 0))
			continue
		Kit.box(g, p + Vector3(0, 0.9, 0), Vector3(0.18, 1.8, 0.18), wood)
	if whole:  # the pine beam that bars the gate, raised
		Kit.box(g, Vector3(1.6, 1.0, 4.9), Vector3(0.25, 0.25, 2.6), "wood", false, Vector3(0, 0.5, 0.2))
	return {"root": g, "hearth": hearth, "couch": g.transform * Vector3(2.6, 0, -D / 2.0 - 1.5), "door": g.transform * Vector3(0, 0, 5.0)}


## A war chariot of the heroes: a light car on two four-spoked wheels, a pole and yoke, and its
## team of `horses` in front (+Z). Lost: a wheel off and the horses bones. Returns the horses.
static func chariot(parent: Node3D, at: Vector3, yaw: float, horses: int = 2, whole: bool = true) -> Array:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if whole else "deadwood"
	Kit.box(g, Vector3(0, 0.75, 0), Vector3(1.2, 0.08, 0.9), wood, false)  # the floor of the car
	Kit.box(g, Vector3(0, 1.05, 0.42), Vector3(1.2, 0.6, 0.06), wood, false)  # its front rail
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.6, 1.0, 0.1), Vector3(0.06, 0.5, 0.6), wood, false)
		var wheel := Kit.group(g, Vector3(side * 0.75, 0.6, -0.2) if whole or side < 0.0 else Vector3(side * 1.4, 0.06, 0.4))
		wheel.rotation.z = PI / 2.0 if whole or side < 0.0 else 0.0  # upright on its axle, or fallen flat
		Kit.mesh(wheel, TorusMesh.new(), wood, Vector3.ZERO, Vector3.ZERO, Vector3(0.6, 0.6, 0.6))
		for k in 2:  # four spokes as two bars
			Kit.box(wheel, Vector3.ZERO, Vector3(0.04, 0.04, 1.05), wood, false, Vector3(0, k * PI / 2.0, 0))
	Kit.box(g, Vector3(0, 0.75, 1.6), Vector3(0.08, 0.08, 2.6), wood, false, Vector3(-0.15, 0, 0))  # the pole
	Kit.box(g, Vector3(0, 1.3, 2.8), Vector3(1.6, 0.1, 0.1), wood, false)  # the yoke
	var team: Array = []
	for k in horses:
		var x := (k - (horses - 1) / 2.0) * 0.8
		team.append(Greek.beast(g, Vector3(x, 0, 3.0), 0.0, "horse", "", 1.0, whole))
	var body := BoxShape3D.new()
	body.size = Vector3(1.5, 1.4, 1.0)
	Kit.solid(g, body, Vector3(0, 0.7, 0))
	return team


## The shield Hephaestus made for Achilles (Iliad 18), laid flat and large enough to walk: the
## sun, moon and stars at the centre; round them a city at peace (a wedding, a trial) and a city at
## war; the ploughed field, the harvest, the vineyard, the herd attacked by lions; the dancing
## floor; and Ocean running round the rim. `radius` in metres (12 to walk it, 0.5 to hang it).
## Lost: its gold and silver tarnished, its figures worn away, Ocean dry. Returns the rings'
## centre distances by name ("sky", "cities", "fields", "dance", "ocean"), in the shield's scale.
static func shield_of_achilles(parent: Node3D, at: Vector3, yaw: float, radius: float = 12.0, whole: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var u := radius / 12.0  # everything below is laid out for a 12 m shield
	var gold := "gold" if whole else "verdigris"
	var rings := {"sky": 2.0 * u, "cities": 4.5 * u, "fields": 7.0 * u, "dance": 9.2 * u, "ocean": 11.0 * u}
	Kit.cylinder(g, Vector3(0, -0.02, 0), radius, 0.08, "bronze" if whole else "verdigris", false, 24)
	Kit.cylinder(g, Vector3(0, 0.0, 0), rings["ocean"] + 0.9 * u, 0.07, "water" if whole else "drybed", false, 24)
	Kit.cylinder(g, Vector3(0, 0.01, 0), rings["ocean"] - 0.9 * u, 0.07, "bronze" if whole else "verdigris", false, 24)
	Kit.cylinder(g, Vector3(0, 0.02, 0), rings["dance"] - 0.9 * u, 0.07, "#b8b8c0" if whole else "ashbed", false, 24)  # silver
	Kit.cylinder(g, Vector3(0, 0.03, 0), rings["fields"] - 1.1 * u, 0.07, "furrows" if whole else "drybed", false, 24)
	Kit.cylinder(g, Vector3(0, 0.04, 0), rings["cities"] - 1.2 * u, 0.07, "bronze" if whole else "verdigris", false, 24)
	Kit.cylinder(g, Vector3(0, 0.05, 0), rings["sky"], 0.07, "#1e2a4a" if whole else "dark", false, 16)  # the heavens
	Kit.blob(g, Vector3(0, 0.12 * u, 0), 0.5 * u, gold, Vector3(1, 0.3, 1), 8)  # the sun
	Kit.blob(g, Vector3(1.1 * u, 0.1 * u, 0.6 * u), 0.3 * u, "#e8e8f0" if whole else "ashbed", Vector3(1, 0.3, 1), 8)  # the moon
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	for k in 12:  # the stars: the Pleiades, the Hyades, Orion, the Bear
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.6, 1.8) * u
		Kit.blob(g, Vector3(cos(a) * r, 0.1 * u, sin(a) * r), 0.07 * u, gold)
	for k in 14:  # the two cities: houses in two clusters, one ringed by an army
		var a := (k * TAU / 14.0) + (0.0 if k < 7 else 0.4)
		var r: float = rings["cities"] + rng.randf_range(-0.6, 0.6) * u
		Kit.box(g, Vector3(cos(a) * r, 0.25 * u, sin(a) * r), Vector3(0.5, 0.4, 0.5) * u, "#b8b8c0" if whole else "ashbed", false,
			Vector3(0, a, 0))
	if whole:
		for k in 16:  # the vineyard's rows and the herd along the fields' ring
			var a := k * TAU / 16.0
			Kit.blob(g, Vector3(cos(a), 0, sin(a)) * rings["fields"] + Vector3(0, 0.2 * u, 0), 0.25 * u,
				"#4a2a4a" if k % 2 else "#9a8266", Vector3(1, 0.7, 1.3), 5)
		for k in 20:  # the dancers, hands joined round the dancing floor
			var a := k * TAU / 20.0
			Kit.cylinder(g, Vector3(cos(a), 0, sin(a)) * rings["dance"] + Vector3(0, 0.08, 0), 0.12 * u, 0.7 * u, gold, false, 6)
	return rings


## Hephaestus's forge (Iliad 18): the great anvil on its block, the bellows (he set twenty
## working), crucibles of bronze, tin, gold and silver in the fire, the hammer and tongs, and the
## golden handmaidens he made to help him. Faces +Z. Lost: the fire out, the bellows slack, the
## gold maids gone green. Returns the fire's light (or null).
static func forge(parent: Node3D, at: Vector3, yaw: float, lit: bool = true) -> OmniLight3D:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.6, -2.0), Vector3(3.0, 1.2, 1.6), "stone")  # the hearth of the forge
	if lit:
		for k in 5:
			Kit.blob(g, Vector3(-1.0 + k * 0.5, 1.35, -2.0), 0.25, "fire", Vector3(1.0, 1.4, 1.0), 5)
	else:
		Kit.box(g, Vector3(0, 1.25, -2.0), Vector3(2.6, 0.1, 1.2), "ashbed", false)
	for k in 4:  # crucibles in the fire
		Kit.cylinder(g, Vector3(-1.1 + k * 0.7, 1.2, -1.7), 0.15, 0.2, "clay", false, 8, 0.2)
		if lit:
			Kit.cylinder(g, Vector3(-1.1 + k * 0.7, 1.4, -1.7), 0.16, 0.02, ["bronze", "#c0c0c8", "gold", "#e0e0e8"][k], false, 8)
	for side: float in [-1.0, 1.0]:  # the bellows, goatskins either side
		for k in 2:
			Kit.blob(g, Vector3(side * 2.0, 0.5, -2.4 + k * 0.8), 0.35, "#8a6a4a", Vector3(1.0, 0.6 if lit else 0.25, 1.4), 6)
	Kit.box(g, Vector3(0, 0.4, 0.5), Vector3(0.6, 0.8, 0.6), "wood")  # the anvil block
	Kit.box(g, Vector3(0, 0.95, 0.5), Vector3(0.9, 0.3, 0.4), "iron" if lit else "rust", false)  # the anvil
	Kit.box(g, Vector3(0.5, 1.12, 0.5), Vector3(0.1, 0.08, 0.35), "wood", false, Vector3(0, 0.3, 0))  # the hammer
	for side: float in [-1.0, 1.0]:  # the golden handmaidens
		var maid := Kit.walker(g, Vector3(side * 2.2, 0, 1.2), -side * 0.6, {"robe": "a08040", "skin": "a08040", "hair_color": "a08040"})
		for mi in maid["root"].find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = Kit.Tex.material("gold" if lit else "verdigris")
	if not lit:
		return null
	var l := OmniLight3D.new()
	l.position = Vector3(0, 2.0, -1.2)
	l.light_color = Color("ff9040")
	l.light_energy = 2.2
	l.omni_range = 9.0
	g.add_child(l)
	return l


## The contest of the bow (Odyssey 21): Odysseus's great bow on its peg and the twelve axe-heads
## set up in a line in a trench, their handle-holes lined up so an arrow can pass through them
## all. Faces +Z (the archer shoots along -X). Lost: the axes toppled and rusted. Returns the
## spot where the archer stands (in the parent's space).
static func bow_and_axes(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Vector3:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(-3.0, 0.02, 0), Vector3(7.0, 0.04, 0.4), "drybed", false)  # the trench
	for k in 12:
		var axe := Kit.group(g, Vector3(-k * 0.55, 0, 0))
		if not whole:
			axe.rotation = Vector3(0, 0.4 * (k % 3), 1.3)
			axe.position.y = 0.05
		Kit.box(axe, Vector3(0, 0.45, 0), Vector3(0.05, 0.9, 0.05), "wood" if whole else "deadwood", false)  # the handle
		Kit.box(axe, Vector3(0, 1.0, 0), Vector3(0.04, 0.22, 0.3), "iron" if whole else "rust", false)  # the head
		Kit.box(axe, Vector3(0, 1.0, 0), Vector3(0.05, 0.07, 0.07), "dark", false)  # the hole the arrow goes through
	var peg := Kit.group(g, Vector3(3.5, 0, -1.5))
	Kit.box(peg, Vector3(0, 1.0, 0), Vector3(0.15, 2.0, 0.15), "wood")
	for k in 5:  # the bow, unstrung, hung on its peg
		var t := (k - 2) / 2.0
		Kit.box(peg, Vector3(0.12 - 0.06 * t * t, 1.4 + 0.25 * t, 0.1), Vector3(0.04, 0.28, 0.04), "#5a3a22" if whole else "deadwood",
			false, Vector3(0, 0, t * 0.35))
	return g.transform * Vector3(2.0, 0, 0)


## Odysseus's bed (Odyssey 23), the sign only he and Penelope know: he built the bedroom round a
## living olive, cut its trunk off as one bedpost and built the bed from it, so it can never be
## moved. The olive's crown still spreads over the roof. Dead: the olive bare, the bed grey.
## Returns the olive's crown.
static func olive_bed(parent: Node3D, at: Vector3, yaw: float, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	var wood := "wood" if alive else "deadwood"
	Kit.box(g, Vector3(0, 0.45, 0), Vector3(2.0, 0.12, 1.4), wood)
	Kit.box(g, Vector3(0, 0.55, 0), Vector3(1.9, 0.1, 1.3), "#cfc4a8" if alive else "ashbed", false)
	Kit.box(g, Vector3(-0.2, 0.62, 0.1), Vector3(1.4, 0.06, 1.32), "#5a1a3a" if alive else "#4a4648", false)  # purple blankets
	for p: Vector3 in [Vector3(0.95, 0.25, 0.65), Vector3(-0.95, 0.25, 0.65), Vector3(-0.95, 0.25, -0.65)]:
		Kit.box(g, p, Vector3(0.1, 0.5, 0.1), wood, false)
	# the fourth post is the olive itself, rooted and rising on through the roof
	var olive := Kit.olive(g, Vector3(0.95, 0, -0.65), 2.2, alive)
	Kit.box(g, Vector3(0.95, 0.8, -0.65), Vector3(0.12, 0.08, 0.12), "gold" if alive else "verdigris", false)  # inlaid gold
	return olive


## The pit Odysseus dug at the edge of the world (Odyssey 11), a forearm's length each way, the
## blood of the black ram and ewe poured into it, the carcasses beside it, and his sword drawn to
## keep the dead back until Teiresias has drunk. Lost: the blood dried black. Returns the pit's
## centre (in the parent's space).
static func blood_trench(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Vector3:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, -0.05, 0), Vector3(1.2, 0.1, 1.2), "dark", false)
	Kit.box(g, Vector3(0, 0.0, 0), Vector3(1.0, 0.04, 1.0), "#5a0808" if whole else "#1a0a0a", false)  # the blood
	for side: float in [-1.0, 1.0]:  # the ram and the ewe on their sides
		var sheep := Greek.beast(g, Vector3(side * 1.4, 0.3, 0.4), side * 0.4, "sheep", "#2a2622" if whole else "", 1.0, whole)
		(sheep["root"] as Node3D).rotation.z = PI / 2.0
	var sword := Kit.group(g, Vector3(0.9, 0, -0.9), 0.6)
	sword.rotation.z = 0.25
	Kit.box(sword, Vector3(0, 0.45, 0), Vector3(0.05, 0.7, 0.012), "bronze" if whole else "verdigris", false)
	Kit.box(sword, Vector3(0, 0.08, 0), Vector3(0.18, 0.04, 0.04), "wood", false)
	return g.transform * Vector3.ZERO


## The Sirens' island (Odyssey 12): a rock in the sea with a flowery meadow on top where the
## two Sirens sit singing, and round them heaps of men's bones with the skin shrivelling on them.
## Lost: the Sirens dead grey things, the meadow ash. Returns the Sirens.
static func sirens_rock(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Array:
	var g := Kit.group(parent, at, yaw)
	Kit.cylinder(g, Vector3(0, -8.0, 0), 12.0, 10.0, "rock", true, 9, 8.0)
	Kit.cylinder(g, Vector3(0, 1.95, 0), 7.8, 0.1, "grass" if whole else "ashbed", false, 9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	if whole:
		for k in 20:  # the meadow's flowers
			var a := rng.randf() * TAU
			Kit.blob(g, Vector3(cos(a), 0, sin(a)) * rng.randf_range(1.0, 7.0) + Vector3(0, 2.1, 0), 0.12,
				["#e8d0d8", "#e0b640", "#c8c8e8"][k % 3])
	for k in 14:  # the bones
		var a := rng.randf_range(-0.8, 0.8) + PI / 2.0
		var r := rng.randf_range(4.0, 7.0)
		Kit.mesh(g, Kit._cyl(0.06, 0.6), "bone", Vector3(cos(a) * r, 2.1, sin(a) * r), Vector3(PI / 2.0, rng.randf() * TAU, 0))
		if k % 4 == 0:
			Kit.blob(g, Vector3(cos(a) * r + 0.3, 2.15, sin(a) * r), 0.13, "bone")
	var sirens: Array = []
	for x: float in [-1.5, 1.5]:
		sirens.append(People.siren(g, Vector3(x, 2.0, 1.5), 0.0, whole))
	return sirens


# ---------- Hesiod ----------

## Prometheus bound to his crag (Theogony, Works and Days): a figure chained to a high rock by
## bronze fetters, the eagle perched over him that comes each day for his liver. Lost: the
## chains snapped, the rock bare but for the eagle's bones. Faces +Z.
static func prometheus_rock(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.cylinder(g, Vector3(0, 0, -0.8), 3.0, 7.0, "rock", true, 7, 1.2)
	if whole:
		var titan := People.figure(g, Vector3(0, 2.0, 1.9), 0.0, "elpenor")  # a man's shape, cast in a titan's skin
		(titan["root"] as Node3D).scale = Vector3.ONE * 1.3
		for mi in titan["root"].find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = Kit.Tex.material("#b8906a")
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 0.7, 4.0, 1.95), Vector3(0.9, 0.06, 0.06), "bronze", false, Vector3(0, 0, side * 0.5))  # the chains
		var eagle := Kit.group(g, Vector3(0.9, 5.2, 1.3))
		Kit.blob(eagle, Vector3.ZERO, 0.25, "#3a2a1e", Vector3(0.8, 1.0, 1.3), 6)
		Kit.blob(eagle, Vector3(0, 0.25, 0.25), 0.1, "#e8e0cc")
		for side: float in [-1.0, 1.0]:
			Kit.box(eagle, Vector3(side * 0.45, 0.1, 0), Vector3(0.7, 0.04, 0.35), "#3a2a1e", false, Vector3(0, 0, side * 0.6))
	else:
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 1.0, 3.2, 1.9), Vector3(0.4, 0.06, 0.06), "verdigris", false, Vector3(0, 0, side * 1.2))
		Kit.blob(g, Vector3(0.6, 0.15, 1.5), 0.15, "bone")


## The Hippocrene, the Horse's Spring on Helicon where the Muses dance: water welling in a rock
## basin under the hoofprint Pegasus stamped in the stone. Lost: dry, the basin cracked.
static func hippocrene(parent: Node3D, at: Vector3, flowing: bool = true) -> void:
	var g := Kit.group(parent, at)
	Kit.cylinder(g, Vector3.ZERO, 1.8, 0.5, "rock", true, 9, 1.6)
	Kit.cylinder(g, Vector3(0, 0.46, 0), 1.3, 0.06, "water" if flowing else "drybed", false, 9)
	Kit.box(g, Vector3(0.4, 0.52, -0.9), Vector3(0.5, 0.02, 0.4), "dark", false)  # the hoofprint in the rim
	Kit.box(g, Vector3(0.4, 0.53, -0.9), Vector3(0.3, 0.02, 0.22), "rock", false)
	if flowing:
		var p := Kit._drift(g, Vector3(0, 0.55, 0), 6, 1.2, 0.08, "water", Vector3.UP, 20.0, Vector2(0.4, 0.8))
		p.gravity = Vector3(0, -2.0, 0)


## The five ages of men (Works and Days 106-201) carved as a frieze of five panels, each in its
## metal: gold (who lived like gods), silver (the long foolish childhood), bronze (made of ash
## trees, all war), the heroes (who fell at Thebes and Troy), and iron (ours: toil by day, sorrow
## by night). Each panel shows its people as figures in relief. Lost: cracked, the last panels
## fallen. Faces +Z. Returns the panels' centres (in the parent's space).
static func ages_frieze(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Array:
	var g := Kit.group(parent, at, yaw)
	var metals := ["gold", "#c0c0c8", "bronze", "marble", "#6a6a70"]
	var out: Array = []
	for k in 5:
		var x := (k - 2) * 2.4
		var panel := Kit.group(g, Vector3(x, 0, 0))
		if not whole and k >= 3:
			panel.rotation.x = -PI / 2.0 + 0.1
			panel.position = Vector3(x, 0.15, 1.2)
		Kit.box(panel, Vector3(0, 1.4, 0), Vector3(2.2, 2.0, 0.3), "stone")
		Kit.box(panel, Vector3(0, 1.4, 0.16), Vector3(1.9, 1.7, 0.04), metals[k] if whole else "ashbed", false)
		for f in 3:  # its people
			var fx := -0.6 + f * 0.6
			Kit.box(panel, Vector3(fx, 1.3, 0.2), Vector3(0.18, 0.7 - k * 0.06, 0.04), "stone", false)
			Kit.blob(panel, Vector3(fx, 1.75 - k * 0.03, 0.2), 0.09, "stone", Vector3(1, 1, 0.4))
		out.append(g.transform * Vector3(x, 0, 1.2))
	return out


# ---------- Sappho ----------

## An apple tree, as in Sappho's orchard: a short crooked trunk, a round crown, red apples, and
## one left on the topmost bough that the pickers could not reach (fr. 105). Dead: bare. Returns
## the crown.
static func apple_tree(parent: Node3D, at: Vector3, size: float = 1.0, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at, at.x * 1.1 + at.z * 0.7)
	var wood := "trunk" if alive else "deadwood"
	Kit.cylinder(g, Vector3.ZERO, 0.16 * size, 1.4 * size, wood, true, 6, 0.12 * size)
	var crown := Kit.group(g, Vector3(0, 1.3 * size, 0))
	if not alive:
		Kit._bare(crown, size, [Vector3(0.8, 1.0, 0.2), Vector3(-0.7, 0.9, -0.3), Vector3(0.1, 1.4, 0.6)])
		return crown
	Kit.blob(crown, Vector3(0, 0.9 * size, 0), 1.2 * size, "plane", Vector3(1.2, 0.85, 1.2), 7)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 7.0 + at.z * 3.0)
	for k in 8:
		var a := rng.randf() * TAU
		Kit.blob(crown, Vector3(cos(a) * 1.25, rng.randf_range(0.4, 1.3), sin(a) * 1.25) * size, 0.09 * size, "#a82a1a")
	Kit.blob(crown, Vector3(0.1, 2.05, 0) * size, 0.1 * size, "#c8301a")  # the one on the topmost bough
	return crown


## Aphrodite's chariot in Sappho's first poem: a small golden car drawn down the sky by a team of
## swift sparrows, their wings a blur. Lost: the car tarnished and empty of birds. Faces +Z (the
## way they fly). Returns the sparrows (for the Hall to beat their wings).
static func sparrow_chariot(parent: Node3D, at: Vector3, yaw: float, whole: bool = true) -> Array:
	var g := Kit.group(parent, at, yaw)
	var gold := "gold" if whole else "verdigris"
	Kit.box(g, Vector3(0, 0.3, 0), Vector3(0.7, 0.05, 0.5), gold, false)
	Kit.box(g, Vector3(0, 0.5, 0.24), Vector3(0.7, 0.4, 0.04), gold, false)
	for side: float in [-1.0, 1.0]:
		Kit.mesh(g, TorusMesh.new(), gold, Vector3(side * 0.4, 0.25, -0.05), Vector3(0, 0, PI / 2.0), Vector3(0.25, 0.25, 0.25))
	Kit.box(g, Vector3(0, 0.3, 0.9), Vector3(0.03, 0.03, 1.3), gold, false)  # the pole
	var birds: Array = []
	if not whole:
		return birds
	for k in 8:  # the sparrows, in pairs
		var bird := Kit.group(g, Vector3((k % 2 - 0.5) * 0.3, 0.35 + (k / 2) * 0.05, 1.2 + (k / 2) * 0.35))
		Kit.blob(bird, Vector3.ZERO, 0.06, "#7a5a3a", Vector3(1.0, 0.9, 1.4), 5)
		for side: float in [-1.0, 1.0]:
			Kit.box(bird, Vector3(side * 0.08, 0.02, 0), Vector3(0.12, 0.01, 0.06), "#5a4028", false, Vector3(0, 0, side * 0.4))
		birds.append(bird)
	return birds
