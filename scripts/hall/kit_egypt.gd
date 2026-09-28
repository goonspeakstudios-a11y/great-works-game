extends RefCounted
## Egypt, for Alexandria, where the Ptolemies ruled as pharaohs and Euclid taught in their Museum:
## pyramids on the desert's edge, obelisks, a temple pylon, papyrus-bundle columns and an Egyptian
## portico, the lion-bodied sphinx, a colossal striding pharaoh, papyrus reeds, a lotus pool and
## dunes. Each faces +Z of its group. Lost (whole = false): the casing stripped, the obelisk fallen,
## the pylon broken, the sphinx sanded up to the shoulders, the colossus toppled.

const Kit := preload("res://scripts/hall/kit.gd")


## A square frustum `w` by `d` at the foot, `h` high, its top `top` times the size of its foot (a
## pylon tower, a battered wall). Not solid; returns its node.
static func _frustum(parent: Node3D, at: Vector3, w: float, d: float, h: float, top: float, mat: String) -> Node3D:
	var s := Kit.group(parent, at)
	s.scale = Vector3(w, 1.0, d)
	var r := Kit.group(s, Vector3.ZERO, PI / 4.0)
	Kit.cylinder(r, Vector3.ZERO, sqrt(0.5), h, mat, false, 4, sqrt(0.5) * top)
	return s


## An unseen box to walk into, `size` round `center`.
static func _block(parent: Node3D, center: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	Kit.solid(parent, shape, center)


## A pyramid `base` metres square and `height` high, standing on the ground at `at`: white casing
## and a gilded capstone. Lost, the casing is gone and the stepped core shows. Not solid (they stand
## far off on the horizon).
static func pyramid(parent: Node3D, at: Vector3, base: float, height: float, yaw: float = 0.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	if whole:
		_frustum(g, Vector3.ZERO, base, base, height * 0.95, 0.05, "casing")
		_frustum(g, Vector3(0, height * 0.95, 0), base * 0.05, base * 0.05, height * 0.05, 0.0, "gold")
	else:
		const STEPS := 9
		for k in STEPS:
			var f := float(k) / STEPS
			_frustum(g, Vector3(0, height * 0.9 * f, 0), base * (1.0 - f), base * (1.0 - f), height * 0.9 / STEPS,
				(1.0 - f - 0.7 / STEPS) / (1.0 - f), "limestone")
	return g


## An obelisk `height` metres high on its base: a tapering shaft cut with hieroglyphs and a gilded
## pyramidion. Lost, it lies broken on the ground beside its stump.
static func obelisk(parent: Node3D, at: Vector3, height: float = 14.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at)
	var w := height * 0.1
	Kit.box(g, Vector3(0, 0.45, 0), Vector3(w * 1.8, 0.9, w * 1.8), "limestone")
	if whole:
		_frustum(g, Vector3(0, 0.9, 0), w, w, height * 0.9, 0.68, "hieroglyphs")
		_frustum(g, Vector3(0, 0.9 + height * 0.9, 0), w * 0.68, w * 0.68, height * 0.1, 0.0, "gold")
		_block(g, Vector3(0, 0.9 + height * 0.45, 0), Vector3(w, height * 0.9, w))
	else:
		_frustum(g, Vector3(0, 0.9, 0), w, w, height * 0.18, 0.93, "hieroglyphs")
		var fallen := Kit.group(g, Vector3(w * 1.6, w * 0.45, height * 0.1), 0.35)
		fallen.rotation.x = PI / 2.0
		_frustum(fallen, Vector3.ZERO, w * 0.93, w * 0.93, height * 0.6, 0.75, "hieroglyphs")
	return g


## A temple pylon, `width` across and `height` high: two battered towers carved and painted with
## reliefs, a painted cornice on each, flagstaffs with pennants against their faces, and between
## them the tall gate with the winged sun over it. Faces +Z. Lost, one tower is half down, the
## lintel lies in the gateway and the flags are gone.
static func pylon(parent: Node3D, at: Vector3, yaw: float, width: float = 26.0, height: float = 13.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	var tw := width * 0.4
	const D := 4.0
	var gate := width - tw * 2.0
	for side: float in [-1.0, 1.0]:
		var x := side * (width / 2.0 - tw / 2.0)
		var h := height if whole or side < 0.0 else height * 0.5
		_frustum(g, Vector3(x, 0, 0), tw, D, h, 0.82, "hieroglyphs")
		_block(g, Vector3(x, h / 2.0, 0), Vector3(tw * 0.9, h, D * 0.9))
		Kit.box(g, Vector3(x, h + 0.25, 0), Vector3(tw * 0.9, 0.5, D * 0.95), "egypt_band", false)  # the cornice
		if whole:
			for k in 2:  # the flagstaffs, set in niches in the tower's face
				var fx := x + (-tw * 0.22 + k * tw * 0.44)
				Kit.cylinder(g, Vector3(fx, 0, D / 2.0 + 0.2), 0.12, h + 5.0, "wood", false, 6)
				Kit.box(g, Vector3(fx + 0.9, h + 4.0, D / 2.0 + 0.2), Vector3(1.6, 0.5, 0.04),
					"#a02820" if k == 0 else "#24407a", false)
	var gh := height * 0.72
	for side: float in [-1.0, 1.0]:  # the gate's jambs
		Kit.box(g, Vector3(side * (gate / 2.0 + 0.2), gh / 2.0, 0), Vector3(0.6, gh, D * 0.8), "limestone")
	if whole:
		Kit.box(g, Vector3(0, gh + 0.5, 0), Vector3(gate + 1.2, 1.0, D * 0.8), "limestone")  # the lintel
		Kit.box(g, Vector3(0, gh + 0.5, D * 0.4 + 0.03), Vector3(gate * 0.9, 0.5, 0.04), "egypt_band", false)  # the wings
		Kit.cylinder(g, Vector3(0, gh + 0.3, D * 0.4 + 0.05), 0.35, 0.05, "gold", false, 12)
	else:
		Kit.box(g, Vector3(1.0, 0.5, 2.5), Vector3(gate + 1.2, 1.0, D * 0.8), "limestone", true, Vector3(0, 0.5, 0.2))
	return g


## A papyrus-bundle column `height` high: a round base, a tapering shaft bound with painted bands
## under the capital, the open papyrus capital, and a square abacus on top. Lost, only a stump.
static func column(parent: Node3D, at: Vector3, height: float = 6.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at)
	Kit.cylinder(g, Vector3.ZERO, 0.6, 0.3, "limestone", true, 10)
	if not whole:
		Kit.cylinder(g, Vector3(0, 0.3, 0), 0.44, height * 0.3, "limestone", true, 8, 0.42)
		return g
	var shaft := height * 0.7
	Kit.cylinder(g, Vector3(0, 0.3, 0), 0.44, shaft, "limestone", true, 8, 0.36)
	Kit.cylinder(g, Vector3(0, 0.3 + shaft - 0.7, 0), 0.38, 0.6, "egypt_band", false, 8)  # the bands that bind the bundle
	Kit.cylinder(g, Vector3(0, 0.3 + shaft, 0), 0.36, height * 0.2, "#3a8a6a", false, 8, 0.78)  # the open capital
	Kit.cylinder(g, Vector3(0, 0.3 + shaft + height * 0.2 - 0.25, 0), 0.8, 0.25, "egypt_band", false, 8)
	Kit.box(g, Vector3(0, height - 0.15, 0), Vector3(1.0, 0.3, 1.0), "limestone", false)  # the abacus
	return g


## An Egyptian portico `length` long and `depth` deep, facing +Z: a back wall carved with
## hieroglyphs, a row of papyrus columns along the front, the architrave with its painted cornice,
## a flat roof. Shaped like Kit.stoa (the same group and length). Lost, half the columns are
## stumps, the wall is low in places and the roof stands over only part of it.
static func portico(parent: Node3D, at: Vector3, yaw: float, length: float, depth: float = 5.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	const H := 5.0
	Kit.box(g, Vector3(0, 0.06, 0), Vector3(length + 0.6, 0.12, depth + 0.6), "limestone", false)
	var n := int(length / 3.2) + 1
	for i in n:  # the back wall, in sections, and the columns along the front
		var x := -length / 2.0 + length * i / float(n - 1)
		var standing := whole or i % 3 != 1
		if i < n - 1:
			var mid := x + length / float(n - 1) / 2.0
			var wall := H if whole or i % 4 != 2 else 1.8
			Kit.box(g, Vector3(mid, wall / 2.0, -depth / 2.0), Vector3(length / float(n - 1) + 0.02, wall, 0.5), "hieroglyphs")
			if whole or i % 2 == 0:
				Kit.box(g, Vector3(mid, H + 0.35, 0), Vector3(length / float(n - 1) + 0.02, 0.3, depth + 0.8), "limestone", false)  # the roof
				Kit.box(g, Vector3(mid, H + 0.15, depth / 2.0 - 0.4), Vector3(length / float(n - 1) + 0.02, 0.5, 0.8), "egypt_band", false)
		column(g, Vector3(x, 0.12, depth / 2.0 - 0.4), H, standing)
	return g


## A sphinx lying on its plinth, `size` times life size of a small temple sphinx (4 m long): a
## lion's body with its paws stretched forward and a king's head in the striped nemes. Lost, the
## sand has drifted up to its shoulders.
static func sphinx(parent: Node3D, at: Vector3, yaw: float, size: float = 1.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	g.scale = Vector3.ONE * size
	Kit.box(g, Vector3(0, 0.35, 0), Vector3(1.4, 0.7, 3.4), "limestone")
	Kit.blob(g, Vector3(0, 1.05, -0.4), 0.6, "casing", Vector3(0.9, 0.75, 2.0), 8)  # the body
	Kit.blob(g, Vector3(0, 1.05, -1.2), 0.55, "casing", Vector3(1.15, 0.85, 0.9), 8)  # the haunch
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.32, 0.82, 0.95), Vector3(0.26, 0.24, 1.1), "casing", false)  # the forepaws
	Kit.box(g, Vector3(0, 1.35, 0.5), Vector3(0.8, 0.9, 0.55), "casing", false)  # the chest
	Kit.blob(g, Vector3(0, 2.0, 0.72), 0.26, "#c8a878", Vector3(1.0, 1.15, 1.0), 7)  # the face
	Kit.box(g, Vector3(0, 2.12, 0.6), Vector3(0.74, 0.5, 0.42), "nemes", false)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.3, 1.66, 0.74), Vector3(0.14, 0.5, 0.1), "nemes", false)  # the lappets
	Kit.box(g, Vector3(0, 1.66, 0.9), Vector3(0.08, 0.26, 0.06), "#24407a", false)  # the beard
	if not whole:
		Kit.blob(g, Vector3(0, 0.7, -0.3), 1.2, "sand", Vector3(1.3, 0.85, 2.3), 8)
	return g


## A colossal pharaoh `height` metres tall on his plinth, striding with the left foot forward, in
## the kilt, the broad collar and the double crown of Upper and Lower Egypt, in red granite: the
## Ptolemies set such statues of themselves by the harbour of Alexandria. Lost, he has fallen and
## lies on his back beside the plinth.
static func colossus(parent: Node3D, at: Vector3, yaw: float, height: float = 9.0, whole: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	var k := height / 9.0
	Kit.box(g, Vector3(0, 0.6 * k, 0), Vector3(2.4 * k, 1.2 * k, 3.0 * k), "limestone")
	var body := Kit.group(g, Vector3(0, 1.2 * k, 0))
	if not whole:
		body.position = Vector3(3.0 * k, 0.5 * k, 0)
		body.rotation.z = PI / 2.0
	body.scale = Vector3.ONE * k
	const GRANITE := "#9a5a48"
	Kit.box(body, Vector3(-0.32, 1.5, 0.35), Vector3(0.44, 3.0, 0.55), GRANITE, false)  # the left leg, forward
	Kit.box(body, Vector3(0.32, 1.5, -0.15), Vector3(0.44, 3.0, 0.55), GRANITE, false)
	Kit.box(body, Vector3(0, 3.5, 0), Vector3(1.4, 1.2, 0.9), "casing", false)  # the kilt
	Kit.box(body, Vector3(0, 4.1, 0), Vector3(1.42, 0.16, 0.92), "gold", false)  # its belt
	Kit.box(body, Vector3(0, 5.1, 0), Vector3(1.5, 1.9, 0.8), GRANITE, false)  # the chest
	Kit.box(body, Vector3(0, 5.8, 0.02), Vector3(1.3, 0.5, 0.82), "egypt_band", false)  # the broad collar
	for side: float in [-1.0, 1.0]:
		Kit.box(body, Vector3(side * 0.95, 4.9, 0), Vector3(0.36, 2.3, 0.45), GRANITE, false)  # the arms at his sides
	Kit.blob(body, Vector3(0, 6.55, 0.05), 0.38, GRANITE, Vector3(1.0, 1.15, 1.0), 7)
	Kit.box(body, Vector3(0, 6.5, -0.1), Vector3(1.0, 0.7, 0.6), "nemes", false)
	Kit.cylinder(body, Vector3(0, 6.85, 0), 0.34, 0.5, "#a02820", false, 8, 0.4)  # the red crown
	Kit.cylinder(body, Vector3(0, 7.3, 0), 0.24, 0.8, "#f0ece0", false, 8, 0.12)  # the white crown in it
	if whole:
		_block(g, Vector3(0, 4.0 * k, 0), Vector3(1.6 * k, 8.0 * k, 1.2 * k))
	else:
		_block(g, Vector3(3.0 * k, 0.6 * k, 0), Vector3(7.0 * k, 1.2 * k, 1.6 * k))
	return g


## A clump of papyrus: tall green stalks, each with its umbel of fine rays at the top.
static func papyrus(parent: Node3D, at: Vector3, alive: bool = true, count: int = 9) -> Node3D:
	var g := Kit.group(parent, at)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 13.0 + at.z * 7.0)
	for i in count:
		var p := Vector3(rng.randf_range(-0.7, 0.7), 0, rng.randf_range(-0.7, 0.7))
		var h := rng.randf_range(1.6, 2.6)
		var lean := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		Kit.box(g, p + Vector3(0, h / 2.0, 0), Vector3(0.04, h, 0.04), "#5a8a3a" if alive else "withered", false, lean)
		Kit.blob(g, p + Vector3(lean.z * h * 0.5, h, -lean.x * h * 0.5), 0.2, "#7aa04a" if alive else "withered", Vector3(1.0, 0.6, 1.0), 6)
	return g


## A lotus pool: still water in a stone rim, round leaves and blue lotus flowers on it, and papyrus
## at its edges. Dry and cracked when the water is not back. Returns the pool's node.
static func lotus_pool(parent: Node3D, at: Vector3, radius: float = 3.0, water: bool = true, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at)
	Kit.cylinder(g, Vector3.ZERO, radius + 0.4, 0.25, "limestone", false, 16)
	Kit.cylinder(g, Vector3(0, 0.02, 0), radius, 0.24, "water" if water else "drybed", false, 16)
	if water and alive:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 9:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.3, radius - 0.4)
			var p := Vector3(cos(a) * r, 0.27, sin(a) * r)
			Kit.cylinder(g, p, 0.3, 0.02, "#3a7a3a", false, 8)
			if i % 2 == 0:
				Kit.blob(g, p + Vector3(0.05, 0.08, 0), 0.1, "#6a8ad8", Vector3(1.0, 0.8, 1.0), 5)
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		papyrus(g, Vector3(cos(a), 0, sin(a)) * (radius + 0.9), alive, 6)
	return g


## A dune: a long low swell of sand, `radius` metres across.
static func dune(parent: Node3D, at: Vector3, radius: float, yaw: float = 0.0) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.blob(g, Vector3.ZERO, radius, "dune", Vector3(1.0, 0.16, 0.55), 10)
