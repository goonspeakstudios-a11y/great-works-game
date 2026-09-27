extends RefCounted
## Building blocks for the Greek places still to come, on top of kit.gd's: animals, the
## hoplites of Sparta and Athens and the Persians they fought, Homer's Achaeans and their black
## ships, a trireme, the walls of Troy and its wooden horse, the Lion Gate of Mycenae, the
## theatre of Dionysus with its masks and crane, Delphi's tripod and navel stone, the Pharos of
## Alexandria, Euclid's sand tray, Plato's cave, Penelope's loom, the symposium couch and its
## pots, Hesiod's plough and fields, a herm, an altar, a speaker's platform.
## Same rules as kit.gd: a group faces +Z; things return what the Hall needs to bring them to
## life (legs to walk, oars to row, lights to flicker, shadows to move).

const Kit := preload("res://scripts/hall/kit.gd")


# ---------- animals ----------

## Each animal's build, in metres: body length, height at the shoulder, body girth, neck length
## and lift (0 flat, 1 upright), how far the face tilts down (radians), head size and muzzle
## length, and the colours of its coat, its dark parts (hooves, mane), horns and nose.
const BEASTS := {
	"horse": {"len": 1.7, "leg": 0.95, "girth": 0.36, "neck": 0.75, "lift": 0.75, "tilt": 0.9, "head": 0.2, "muzzle": 0.4,
		"coat": "#8a5a3a", "dark": "#2a1e16", "nose": "#3a2a20", "tail": 0.8, "mane": true},
	"ox": {"len": 1.8, "leg": 0.75, "girth": 0.5, "neck": 0.45, "lift": 0.25, "tilt": 0.45, "head": 0.24, "muzzle": 0.28,
		"coat": "#9a8266", "dark": "#2a221c", "horn": "#e0d4b8", "nose": "#4a3a30", "tail": 0.7, "horns": "ox"},
	"sheep": {"len": 0.95, "leg": 0.42, "girth": 0.34, "neck": 0.25, "lift": 0.4, "tilt": 0.4, "head": 0.12, "muzzle": 0.14,
		"coat": "#dcd4c0", "dark": "#2e2824", "nose": "#2e2824", "tail": 0.12, "wool": true},
	"goat": {"len": 0.9, "leg": 0.5, "girth": 0.24, "neck": 0.3, "lift": 0.7, "tilt": 0.5, "head": 0.11, "muzzle": 0.16,
		"coat": "#5a4a3e", "dark": "#2a221c", "nose": "#2a221c", "tail": 0.1, "horns": "goat", "beard": true},
	"dog": {"len": 0.8, "leg": 0.45, "girth": 0.2, "neck": 0.22, "lift": 0.8, "tilt": 0.1, "head": 0.1, "muzzle": 0.14,
		"coat": "#8a6a44", "dark": "#2a2018", "nose": "#141010", "tail": 0.35},
	"wolf": {"len": 1.05, "leg": 0.6, "girth": 0.24, "neck": 0.28, "lift": 0.55, "tilt": 0.2, "head": 0.13, "muzzle": 0.18,
		"coat": "#7a7266", "dark": "#3a3632", "nose": "#141010", "tail": 0.45},
}


## An animal standing on four legs, facing +Z: "horse", "ox", "sheep", "goat", "dog" or "wolf".
## `mat` casts it in one stuff instead (bronze for a statue, wood for the horse of Troy); `scale`
## sizes it up. Returns {"root", "legs": [front right, front left, hind right, hind left],
## "head", "tail"}: legs are hips that swing about X, so the Hall can walk it.
static func beast(parent: Node3D, at: Vector3, yaw: float, kind: String, mat: String = "", scale: float = 1.0) -> Dictionary:
	var b: Dictionary = BEASTS.get(kind, BEASTS["dog"])
	var coat: String = mat if mat != "" else str(b["coat"])
	var dark: String = mat if mat != "" else str(b["dark"])
	var nose: String = mat if mat != "" else str(b["nose"])
	var horn: String = mat if mat != "" else str(b.get("horn", b["dark"]))
	var root := Kit.group(parent, at, yaw)
	root.scale = Vector3.ONE * scale
	var length: float = b["len"]
	var leg: float = b["leg"]
	var girth: float = b["girth"]
	var body_y := leg + girth * 0.55
	Kit.blob(root, Vector3(0, body_y, 0), girth, coat, Vector3(1.0, 0.95, length / (girth * 2.0)), 8)
	if b.get("wool", false):
		Kit.blob(root, Vector3(0, body_y + 0.03, 0), girth * 1.15, coat, Vector3(1.05, 0.95, length / (girth * 2.2)), 7)
	var legs: Array = []
	for end: float in [1.0, -1.0]:  # front, then hind
		for side: float in [-1.0, 1.0]:
			var hip := Kit.group(root, Vector3(girth * 0.55 * side, body_y - girth * 0.3, end * length * 0.36))
			Kit.mesh(hip, Kit._cyl(girth * 0.2, leg), coat, Vector3(0, -leg / 2.0 + girth * 0.15, 0))
			Kit.box(hip, Vector3(0, -leg + girth * 0.18, 0.02), Vector3(girth * 0.36, girth * 0.22, girth * 0.42), dark, false)
			legs.append(hip)
	# the neck rises from the chest to the head; `lift` is how upright it stands (0 flat, 1 up)
	var lift: float = b["lift"]
	var neck_len: float = b["neck"]
	var chest := Vector3(0, body_y + girth * 0.3, length * 0.45)
	var neck_dir := Vector3(0, lift, 1.0 - lift * 0.6).normalized()
	var neck_top := chest + neck_dir * neck_len
	Kit.mesh(root, Kit._cyl(girth * 0.42, neck_len + girth * 0.4), coat, (chest + neck_top) / 2.0,
		Quaternion(Vector3.UP, neck_dir).get_euler())
	if b.get("mane", false):
		Kit.box(root, (chest + neck_top) / 2.0 + Vector3(0, girth * 0.35, -girth * 0.2), Vector3(girth * 0.18, neck_len * 0.9, girth * 0.35),
			dark, false, Quaternion(Vector3.UP, neck_dir).get_euler())
	var head := Kit.group(root, neck_top)
	head.rotation.x = float(b["tilt"])
	var hs: float = b["head"]
	var muzzle: float = b["muzzle"]
	Kit.blob(head, Vector3(0, 0, 0), hs, coat, Vector3(0.9, 1.0, 1.1), 7)
	Kit.blob(head, Vector3(0, -hs * 0.35, muzzle * 0.75), hs * 0.72, nose if kind in ["horse", "ox"] else coat,
		Vector3(0.85, 0.8, muzzle / hs * 1.1), 6)
	Kit.box(head, Vector3(0, -hs * 0.3, muzzle * 0.75 + muzzle * 0.55), Vector3(hs * 0.5, hs * 0.25, 0.02), nose, false)
	for side: float in [-1.0, 1.0]:
		Kit.box(head, Vector3(hs * 0.55 * side, hs * 0.8, -hs * 0.2), Vector3(hs * 0.25, hs * 0.6, hs * 0.12), coat, false,
			Vector3(-0.3, 0, 0.4 * side))  # ears
		Kit.blob(head, Vector3(hs * 0.62 * side, hs * 0.2, hs * 0.45), hs * 0.12, "#141010" if mat == "" else mat)  # eyes
		match b.get("horns", ""):
			"ox":  # out to the side, then curving up and forward
				Kit.box(head, Vector3(hs * 1.05 * side, hs * 0.75, 0), Vector3(hs * 1.1, hs * 0.16, hs * 0.16), horn, false,
					Vector3(0, 0, 0.25 * side))
				Kit.box(head, Vector3(hs * 1.6 * side, hs * 1.15, hs * 0.15), Vector3(hs * 0.14, hs * 0.6, hs * 0.14), horn, false,
					Vector3(0.3, 0, -0.35 * side))
			"goat":  # swept back over the neck
				Kit.box(head, Vector3(hs * 0.3 * side, hs * 1.1, -hs * 0.5), Vector3(hs * 0.14, hs * 1.1, hs * 0.14), horn, false,
					Vector3(-0.9, 0, 0.12 * side))
	if b.get("beard", false):
		Kit.box(head, Vector3(0, -hs * 1.0, muzzle * 0.6), Vector3(hs * 0.2, hs * 0.6, hs * 0.2), dark, false)
	var tail := Kit.group(root, Vector3(0, body_y + girth * 0.4, -length * 0.5))
	var tail_len: float = b["tail"]
	Kit.box(tail, Vector3(0, -tail_len / 2.0, -0.04), Vector3(girth * 0.14, tail_len, girth * 0.14),
		dark if kind == "horse" else coat, false, Vector3(0.25, 0, 0))
	var body := BoxShape3D.new()
	body.size = Vector3(girth * 2.2, body_y + girth, length + muzzle)
	Kit.solid(root, body, Vector3(0, (body_y + girth) / 2.0, muzzle * 0.3))
	return {"root": root, "legs": legs, "head": head, "tail": tail}


## Hesiod's plough team: two oxen under a wooden yoke drawing an ard (a scratch plough), the
## ploughman's handle behind. Faces +Z. Returns the two oxen.
static func plough_team(parent: Node3D, at: Vector3, yaw: float) -> Array:
	var g := Kit.group(parent, at, yaw)
	var oxen: Array = []
	for side: float in [-0.75, 0.75]:
		oxen.append(beast(g, Vector3(side, 0, 1.4), 0.0, "ox"))
	Kit.box(g, Vector3(0, 1.3, 2.25), Vector3(2.2, 0.14, 0.16), "wood", false)  # the yoke on their necks
	Kit.box(g, Vector3(0, 0.95, 0.4), Vector3(0.1, 0.1, 3.8), "wood", false, Vector3(-0.2, 0, 0))  # the pole
	Kit.box(g, Vector3(0, 0.18, -1.45), Vector3(0.12, 0.12, 0.9), "wood", false, Vector3(0.35, 0, 0))  # the share-beam
	Kit.box(g, Vector3(0, 0.08, -1.05), Vector3(0.08, 0.06, 0.3), "#6a6a6a", false, Vector3(0.5, 0, 0))  # the iron tip
	Kit.box(g, Vector3(0, 0.75, -1.9), Vector3(0.08, 1.2, 0.08), "wood", false, Vector3(-0.5, 0, 0))  # the handle
	return oxen


# ---------- soldiers ----------

## A hoplite: bronze Corinthian helmet with its crest, a bronze bell cuirass over a tunic, greaves,
## the big round shield (hoplon) on the left arm, and an ash spear (dory) upright in his right
## hand. "sparta": crimson cloak and tunic, the lambda on the shield, the crest across the helmet.
## "athens": a white tunic, the owl on a black shield, the crest front to back. Undead: bones,
## green bronze, a snapped spear, a cold light in the eyes. Faces +Z. Returns his two legs.
static func hoplite(parent: Node3D, at: Vector3, kind: String = "sparta", undead: bool = false) -> Array:
	var g := Kit.group(parent, at)
	var sparta := kind == "sparta"
	var skin := "bone" if undead else "#c8a078"
	var metal := "verdigris" if undead else "bronze"
	var cloth := "#3e2a2a" if undead else ("#8a1e1a" if sparta else "#e0d6c0")
	var limb := 0.045 if undead else 0.075
	var legs: Array = []
	for side: float in [-1.0, 1.0]:
		var hip := Kit.group(g, Vector3(0.1 * side, 0.82, 0))
		Kit.mesh(hip, Kit._cyl(limb, 0.78), skin, Vector3(0, -0.39, 0))
		Kit.box(hip, Vector3(0, -0.52, 0.02), Vector3(0.15, 0.44, 0.16), metal, false)  # greave
		Kit.box(hip, Vector3(0, -0.8, 0.06), Vector3(0.13, 0.05, 0.25), "#3a3028" if undead else "#6a4a34", false)
		legs.append(hip)
	Kit.cylinder(g, Vector3(0, 0.66, 0), 0.23, 0.26, cloth, false, 8, 0.22)  # the tunic's skirt
	Kit.cylinder(g, Vector3(0, 0.92, 0), 0.22, 0.56, metal, false, 8, 0.25)  # the bell cuirass
	Kit.blob(g, Vector3(0, 1.5, 0), 0.25, metal, Vector3(1.25, 0.5, 0.85), 8)
	if sparta:  # the red cloak down the back
		Kit.box(g, Vector3(0, 1.0, -0.2), Vector3(0.5, 1.0, 0.05), cloth, false, Vector3(0.1, 0, 0))
	Kit.mesh(g, Kit._cyl(limb * 0.8, 0.5), skin, Vector3(0.28, 1.2, 0))
	Kit.mesh(g, Kit._cyl(limb * 0.8, 0.45), skin, Vector3(-0.28, 1.25, 0.1), Vector3(-1.2, 0, 0))
	var shield := Kit.group(g, Vector3(-0.3, 1.15, 0.32), -0.25)  # held before him, a little to the left
	var face := QuadMesh.new()
	face.size = Vector2(0.9, 0.9)
	Kit.mesh(shield, face, "hoplon_dead" if undead else ("hoplon_sparta" if sparta else "hoplon_athens"), Vector3(0, 0, 0.01))
	Kit.mesh(shield, Kit._cyl(0.44, 0.06), metal, Vector3(0, 0, -0.03), Vector3(PI / 2.0, 0, 0))
	if undead:
		Kit.box(g, Vector3(0.36, 1.4, 0.05), Vector3(0.04, 2.0, 0.04), "deadwood", false, Vector3(0, 0, -0.08))
	else:
		Kit.box(g, Vector3(0.36, 1.5, 0.05), Vector3(0.04, 2.8, 0.04), "wood", false)  # the dory
		Kit.box(g, Vector3(0.36, 3.0, 0.05), Vector3(0.06, 0.28, 0.02), "bronze", false)  # its leaf-shaped head
	var head := Kit.group(g, Vector3(0, 1.68, 0.02))
	Kit.blob(head, Vector3(0, 0.06, 0), 0.12 if undead else 0.13, skin, Vector3(1.0, 1.1, 1.0), 7)
	Kit.blob(head, Vector3(0, 0.1, -0.01), 0.155, metal, Vector3(1.0, 1.25, 1.05), 7)  # the helmet, down over the face
	Kit.box(head, Vector3(0, 0.04, 0.14), Vector3(0.05, 0.12, 0.04), "dark", false)  # the T of the eye-slits and mouth
	Kit.box(head, Vector3(0, 0.1, 0.14), Vector3(0.18, 0.035, 0.04), "dark", false)
	if undead:
		for x: float in [-0.05, 0.05]:
			Kit.box(head, Vector3(x, 0.1, 0.165), Vector3(0.016, 0.016, 0.006), "soulfire", false)
	var crest := "#3a2a2a" if undead else ("#8a1e1a" if sparta else "#2a2a2a")
	var across := Vector3(0.36, 0.1, 0.05) if sparta else Vector3(0.05, 0.1, 0.36)
	Kit.box(head, Vector3(0, 0.3, 0), across, crest, false)  # the horsehair crest
	return legs


## A block of hoplites in rows and files, shields overlapping: the phalanx. Same shape as
## kit.gd's squad, so the Hall marches it the same way.
static func phalanx(parent: Node3D, at: Vector3, rows: int, files: int, kind: String = "sparta", undead: bool = false) -> Dictionary:
	var root := Kit.group(parent, at)
	var legs: Array = []
	for r in rows:
		for f in files:
			legs.append_array(hoplite(root, Vector3((f - (files - 1) / 2.0) * 0.9, 0, -r * 1.1), kind, undead))
	return {"root": root, "legs": legs, "leg": 0, "speed": 0.8 if undead else 1.1, "step": 0.0, "undead": undead}


## One of the Persian Immortals: a long robe with rosettes, trousers, a soft felt cap (the
## tiara) tied under the chin, a dark curled beard, a wicker shield and a short spear with a
## golden pomegranate for a butt, a bow case on the hip. Faces +Z. Returns his two legs.
static func immortal(parent: Node3D, at: Vector3, undead: bool = false) -> Array:
	var g := Kit.group(parent, at)
	var skin := "bone" if undead else "#b88a64"
	var robe := "#3a3a44" if undead else "persian"
	var felt := "#6a6660" if undead else "#e0d6c0"
	var legs: Array = []
	for side: float in [-1.0, 1.0]:
		var hip := Kit.group(g, Vector3(0.1 * side, 0.82, 0))
		Kit.mesh(hip, Kit._cyl(0.08, 0.78), "#3a3028" if undead else "#6a3a2a", Vector3(0, -0.39, 0))  # trousers
		Kit.box(hip, Vector3(0, -0.8, 0.06), Vector3(0.13, 0.06, 0.25), "#2a221c", false)
		legs.append(hip)
	Kit.cylinder(g, Vector3(0, 0.45, 0), 0.3, 1.1, robe, false, 8, 0.2)  # the long robe
	Kit.blob(g, Vector3(0, 1.52, 0), 0.24, robe, Vector3(1.25, 0.5, 0.85), 8)
	Kit.mesh(g, Kit._cyl(0.07, 0.5), robe, Vector3(0.28, 1.2, 0))
	Kit.mesh(g, Kit._cyl(0.07, 0.45), robe, Vector3(-0.28, 1.25, 0.1), Vector3(-1.2, 0, 0))
	Kit.box(g, Vector3(-0.36, 1.1, 0.3), Vector3(0.55, 0.85, 0.05), "#4a4436" if undead else "wicker", false, Vector3(0, -0.3, 0))  # spara
	Kit.box(g, Vector3(0.36, 1.35, 0.05), Vector3(0.04, 2.1, 0.04), "deadwood" if undead else "wood", false)
	if not undead:
		Kit.box(g, Vector3(0.36, 2.45, 0.05), Vector3(0.05, 0.22, 0.02), "#b8b8c0", false)  # the iron head
		Kit.blob(g, Vector3(0.36, 0.28, 0.05), 0.06, "gold")  # the golden pomegranate
	Kit.box(g, Vector3(0.28, 0.95, -0.12), Vector3(0.12, 0.5, 0.2), "#5a3a24", false, Vector3(0, 0, 0.25))  # the bow case
	var head := Kit.group(g, Vector3(0, 1.68, 0.02))
	Kit.blob(head, Vector3(0, 0.06, 0), 0.13, skin, Vector3(1.0, 1.1, 1.0), 7)
	Kit.blob(head, Vector3(0, 0.16, -0.02), 0.155, felt, Vector3(1.05, 0.95, 1.05), 7)  # the tiara
	Kit.box(head, Vector3(0, 0.0, 0.03), Vector3(0.3, 0.22, 0.2), felt, false)  # its flaps round the jaw
	if undead:
		for x: float in [-0.045, 0.045]:
			Kit.box(head, Vector3(x, 0.07, 0.125), Vector3(0.016, 0.016, 0.006), "soulfire", false)
	else:
		Kit.blob(head, Vector3(0, -0.04, 0.09), 0.09, "#1e1812", Vector3(1.0, 1.3, 0.6), 6)  # the curled beard
	return legs


## A warrior of Homer's Achaeans (the Bronze Age): a boar's-tusk helmet (rows of white plates on
## a leather cap), a leather kilt, a great body shield of ox-hide shaped like a figure eight
## slung before him, and a long spear. Faces +Z. Returns his two legs.
static func achaean(parent: Node3D, at: Vector3, undead: bool = false) -> Array:
	var g := Kit.group(parent, at)
	var skin := "bone" if undead else "#c49070"
	var hide := "#4a4038" if undead else "#9a7a5a"
	var legs: Array = []
	for side: float in [-1.0, 1.0]:
		var hip := Kit.group(g, Vector3(0.1 * side, 0.82, 0))
		Kit.mesh(hip, Kit._cyl(0.045 if undead else 0.075, 0.78), skin, Vector3(0, -0.39, 0))
		Kit.box(hip, Vector3(0, -0.8, 0.06), Vector3(0.13, 0.05, 0.25), "#5a3a24", false)
		legs.append(hip)
	Kit.cylinder(g, Vector3(0, 0.6, 0), 0.25, 0.36, "#6a4a30" if not undead else "#3a3028", false, 8, 0.22)  # the kilt
	Kit.cylinder(g, Vector3(0, 0.96, 0), 0.21, 0.5, skin if not undead else "#4a4038", false, 8, 0.24)
	Kit.blob(g, Vector3(0, 1.5, 0), 0.24, skin if not undead else "#4a4038", Vector3(1.25, 0.5, 0.85), 8)
	Kit.mesh(g, Kit._cyl(0.06, 0.5), skin, Vector3(0.28, 1.2, 0))
	var shield := Kit.group(g, Vector3(-0.05, 0.95, 0.38))  # the figure-eight, from chin to shin
	for y: float in [0.35, -0.35]:
		Kit.blob(shield, Vector3(0, y, 0), 0.4, hide, Vector3(1.0, 1.0, 0.25), 8)
	Kit.box(shield, Vector3(0, 0, 0.02), Vector3(0.05, 1.3, 0.12), "#5a4430", false)  # the rib down its middle
	Kit.box(g, Vector3(0.36, 1.7, 0.05), Vector3(0.04, 3.4, 0.04), "deadwood" if undead else "wood", false)
	Kit.box(g, Vector3(0.36, 3.45, 0.05), Vector3(0.06, 0.3, 0.02), "verdigris" if undead else "bronze", false)
	var head := Kit.group(g, Vector3(0, 1.68, 0.02))
	Kit.blob(head, Vector3(0, 0.06, 0), 0.13, skin, Vector3(1.0, 1.1, 1.0), 7)
	for k in 4:  # the tusk plates, row on row, narrowing to the top
		Kit.cylinder(head, Vector3(0, 0.08 + k * 0.07, -0.01), 0.15 - k * 0.03, 0.07, "bone", false, 8, 0.14 - k * 0.03)
	Kit.box(head, Vector3(0, 0.42, -0.01), Vector3(0.04, 0.12, 0.04), hide, false)  # the knob on top
	if undead:
		for x: float in [-0.045, 0.045]:
			Kit.box(head, Vector3(x, 0.07, 0.125), Vector3(0.016, 0.016, 0.006), "soulfire", false)
	else:
		Kit.blob(head, Vector3(0, -0.04, 0.09), 0.085, "#3a2a1e", Vector3(1.0, 1.2, 0.6), 6)
	return legs


# ---------- ships ----------

## A Greek warship, bow toward +Z. "trireme": 36 m, three banks of oars, the bronze ram, the
## outrigger, painted eyes and the stern curling up. "pentekonter": Homer's black ship, 24 m,
## one bank. With `sail` the mast is up with its square linen sail; with `oars` false they are
## shipped (the ship drawn up on a beach). The hull is solid; its deck is at about 2.2 m.
## Returns {"root", "oars": [each oar's pivot, which rows about Y]}.
static func ship(parent: Node3D, at: Vector3, yaw: float, kind: String = "trireme", sail: bool = false,
		oars: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var trireme := kind == "trireme"
	var length := 36.0 if trireme else 24.0
	var beam := 5.0 if trireme else 3.6
	var pitch := "#24201c"  # the black of pitch
	if trireme:  # decked over
		Kit.box(g, Vector3(0, 1.1, 0), Vector3(beam, 2.2, length * 0.7), pitch)
	else:  # open, the rowers on benches across it
		Kit.box(g, Vector3(0, 0.7, 0), Vector3(beam, 1.4, length * 0.7), pitch)
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * (beam / 2.0 - 0.08), 1.8, 0), Vector3(0.16, 0.8, length * 0.7), pitch)
		for k in 12:
			Kit.box(g, Vector3(0, 1.75, -length * 0.3 + k * (length * 0.6 / 11.0)), Vector3(beam - 0.3, 0.1, 0.3), "wood", false)
	for end: float in [1.0, -1.0]:  # the hull narrows fore and aft in three steps
		for k in 3:
			var w := beam * (0.8 - k * 0.22)
			var z := end * (length * 0.35 + (k + 0.5) * length * 0.05)
			Kit.box(g, Vector3(0, 1.1 + (0.2 * k if end < 0.0 else 0.0), z),  # the stern rises a little
				Vector3(w, 2.2 - k * 0.3, length * 0.05), pitch)
	Kit.box(g, Vector3(0, 2.24 if trireme else 1.42, 0), Vector3(beam - 0.4, 0.08, length * 0.85 if trireme else length * 0.7),
		"wood", false)  # the deck, or the floor of the open hull
	Kit.box(g, Vector3(0, 0.35, length * 0.52), Vector3(0.5, 0.5, 1.8), "bronze", false)  # the ram at the waterline
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.9, 1.6, length * 0.44), Vector3(0.1, 0.5, 0.5), "#e8e0cc", false)  # the eyes
		Kit.box(g, Vector3(side * 0.95, 1.6, length * 0.44), Vector3(0.05, 0.22, 0.22), "#1a1410", false)
		if trireme:  # the outrigger the top bank rows from
			Kit.box(g, Vector3(side * (beam / 2.0 + 0.35), 2.0, 0), Vector3(0.7, 0.3, length * 0.6), "wood", false)
	# the aphlaston: the stern sweeps up and back, then curls forward over the steersman
	var curl := 1.6 if trireme else 1.2
	var centre := Vector3(0, 2.2 + curl, -length * 0.5)
	for k in 9:
		var th := deg_to_rad(lerpf(-90.0, 160.0, k / 8.0))
		Kit.box(g, centre + Vector3(0, sin(th), -cos(th)) * curl, Vector3(maxf(0.25, beam * 0.35 - k * 0.12), 0.45, 0.3), pitch, false,
			Vector3(th, 0, 0))
	for side: float in [-1.0, 1.0]:  # the painted band along the sheer
		Kit.box(g, Vector3(side * (beam / 2.0 + 0.01), 1.9, 0), Vector3(0.02, 0.25, length * 0.7), "#8a2a1a", false)
	Kit.box(g, Vector3(0, 3.4, length * 0.5), Vector3(0.2, 2.4, 0.3), pitch, false, Vector3(0.35, 0, 0))  # the stem post
	for side: float in [-1.0, 1.0]:  # the steering oars at the stern
		Kit.box(g, Vector3(side * (beam / 2.0 + 0.1), 1.2, -length * 0.42), Vector3(0.08, 3.0, 0.3), "wood", false, Vector3(0.6, 0, 0))
	if sail:
		Kit.cylinder(g, Vector3(0, 2.2, length * 0.05), 0.14, 10.0, "wood", false, 6)
		Kit.box(g, Vector3(0, 11.6, length * 0.05), Vector3(beam * 1.6, 0.14, 0.14), "wood", false)  # the yard
		Kit.box(g, Vector3(0, 8.6, length * 0.05 + 0.15), Vector3(beam * 1.5, 5.8, 0.06), "#e0d6c0", false)
	var pivots: Array = []
	var banks := 3 if trireme else 1
	var per := 17 if trireme else 12
	for side: float in [-1.0, 1.0]:
		for bank in banks:
			for k in per:
				var z := -length * 0.3 + k * (length * 0.6 / (per - 1))
				var pivot := Kit.group(g, Vector3(side * (beam / 2.0 + (0.7 if trireme and bank == 2 else 0.0)), 0.9 + bank * 0.55, z))
				var reach := 4.2 + bank * 0.8
				if oars:  # out over the water, blades down
					Kit.box(pivot, Vector3(side * reach / 2.0, -0.4 - bank * 0.25, 0), Vector3(reach, 0.06, 0.06), "wood", false,
						Vector3(0, 0, side * -(0.25 + bank * 0.08)))
				else:  # shipped: drawn in along the side
					Kit.box(pivot, Vector3(side * 0.05, 0.35, 0), Vector3(0.06, 0.06, reach * 0.8), "wood", false)
				pivots.append(pivot)
	return {"root": g, "oars": pivots}


# ---------- Troy and Mycenae ----------

## A stretch of the walls of Troy along X of the group, `length` long: a sloping stone footing,
## a sheer upper wall with a walk and battlements, and (with `gate`) a gate tower in the middle
## with its dark opening, the Scaean Gate. Solid. Faces +Z (the plain). Returns the spot on the
## plain just before the gate.
static func troy_wall(parent: Node3D, at: Vector3, yaw: float, length: float, gate: bool = true) -> Vector3:
	var g := Kit.group(parent, at, yaw)
	var gap := 4.0 if gate else 0.0
	for side: float in [-1.0, 1.0]:
		var seg := (length - gap) / 2.0
		var cx := side * (gap / 2.0 + seg / 2.0)
		Kit.box(g, Vector3(cx, 2.0, 0.6), Vector3(seg, 4.0, 3.4), "stone", true, Vector3(-0.12, 0, 0))  # the battered footing
		Kit.box(g, Vector3(cx, 6.5, -0.2), Vector3(seg, 5.0, 2.4), "stone")
		var n := int(seg / 1.4)
		for k in n:  # the battlements
			Kit.box(g, Vector3(cx - seg / 2.0 + 0.7 + k * 1.4, 9.4, 0.8), Vector3(0.8, 0.8, 0.4), "stone", false)
	if gate:
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 3.6, 5.5, 0.5), Vector3(3.2, 11.0, 4.6), "stone")  # the towers either side
		Kit.box(g, Vector3(0, 8.5, 0.5), Vector3(4.0, 5.0, 4.6), "stone", false)  # over the gate
		Kit.box(g, Vector3(0, 3.0, 2.3), Vector3(3.0, 6.0, 0.2), "dark", false)  # the dark opening
		var door := BoxShape3D.new()
		door.size = Vector3(3.0, 6.0, 1.0)
		Kit.solid(g, door, Vector3(0, 3.0, 2.0))
	return at + Vector3(sin(yaw), 0, cos(yaw)) * 3.0


## The wooden horse the Greeks left on the shore: a horse of planks, ten metres high, on a
## wheeled platform, with the trapdoor in its belly. Faces +Z.
static func wooden_horse(parent: Node3D, at: Vector3, yaw: float) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.5, 0), Vector3(3.6, 0.4, 8.0), "wood")
	for x: float in [-1.9, 1.9]:
		for z: float in [-3.0, 3.0]:
			Kit.mesh(g, _prism(0.55, 0.3, 8), "wood", Vector3(x, 0.55, z), Vector3(0, 0, PI / 2.0))
	var horse := beast(g, Vector3(0, 0.7, 0), 0.0, "horse", "wood", 5.0)
	Kit.box(g, Vector3(0, 4.55, 0.3), Vector3(1.2, 0.05, 1.6), "dark", false)  # the trapdoor, under the belly
	return horse


## The Lion Gate of Mycenae, Agamemnon's door: two huge upright stones and a lintel in walls of
## Cyclopean boulders, and over it the triangle carved with two lions rearing at a column. Faces +Z.
static func lion_gate(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := Kit.group(parent, at, yaw)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 1.9, 1.6, 0), Vector3(0.9, 3.2, 1.8), "stone")  # the door jambs
		var rng := RandomNumberGenerator.new()
		rng.seed = int(side * 7) + 20
		for row in 4:  # the Cyclopean wall of great rough blocks
			for k in 3:
				var s := rng.randf_range(1.3, 1.8)
				Kit.box(g, Vector3(side * (3.0 + k * 1.7), 0.8 + row * 1.5, rng.randf_range(-0.2, 0.2)),
					Vector3(s, 1.5, 2.2), "rock", true, Vector3(0, rng.randf_range(-0.05, 0.05), rng.randf_range(-0.04, 0.04)))
	Kit.box(g, Vector3(0, 3.55, 0), Vector3(4.8, 1.0, 2.0), "stone")  # the lintel, one stone of twenty tons
	var relief := Kit.group(g, Vector3(0, 4.05, 0.7))
	Kit.mesh(relief, _prism(1.8, 0.4, 3), "tufa", Vector3(0, 0.9, 0), Vector3(-PI / 2.0, 0, 0))  # the triangle, point up
	Kit.cylinder(relief, Vector3(0, 0.2, 0.25), 0.12, 1.4, "tufa", false, 6, 0.18)  # the column
	for side: float in [-1.0, 1.0]:
		Kit.blob(relief, Vector3(side * 0.55, 0.55, 0.25), 0.3, "tufa", Vector3(0.8, 1.6, 0.5), 6)  # a rearing lion
		Kit.blob(relief, Vector3(side * 0.38, 1.25, 0.28), 0.14, "tufa", Vector3(1.0, 1.0, 0.8), 6)
	var dark := QuadMesh.new()
	dark.size = Vector2(2.9, 3.1)
	Kit.mesh(g, dark, "dark", Vector3(0, 1.55, -0.3))


# ---------- the theatre ----------

## The theatre of Dionysus below the Acropolis: a round orchestra of beaten earth with the altar
## of the god in its middle, the seats rising in rows round more than half of it (toward -Z),
## aisles of steps between the wedges, and the stage building (skene) across the front (+Z) with
## its three doors and a low colonnade. In ruin (whole = false) rows are broken and the skene is
## down to its footings. Returns {"root", "altar", "doors": [three door centres], "crane_at"}
## (in the group's space).
static func theatre(parent: Node3D, at: Vector3, yaw: float, rows: int = 12, whole: bool = true) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	const ORCHESTRA := 9.0
	Kit.cylinder(g, Vector3(0, -0.02, 0), ORCHESTRA + 0.3, 0.06, "marble", false, 16)  # the stone ring of its edge
	Kit.cylinder(g, Vector3(0, -0.01, 0), ORCHESTRA, 0.06, "earth", false, 16)
	Kit.box(g, Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), "marble")  # the thymele, the god's altar
	var arc_from := deg_to_rad(-200.0)  # the seats wrap from here to arc_to, round the back (-Z)
	var arc_to := deg_to_rad(20.0)
	var aisles := [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for r in rows:
		var radius := ORCHESTRA + 1.2 + r * 0.9
		var h := 0.4 * (r + 1)
		var arc := (arc_to - arc_from) * radius
		var n := int(arc / 1.6)
		for k in n:
			var u := (k + 0.5) / n
			if aisles.any(func(a: float) -> bool: return absf(u - a) < 0.8 / arc):
				continue  # leave the aisle clear
			if not whole and rng.randf() < 0.3 + r * 0.03:
				continue
			var a := lerpf(arc_from, arc_to, u)
			var p := Vector3(cos(a), 0, sin(a)) * radius
			Kit.box(g, p + Vector3(0, h / 2.0, 0), Vector3(0.95, h, arc / n + 0.05), "stone", true, Vector3(0, -a, 0))
	for a_u in aisles:  # the stairs up each aisle: a steep ramp to walk
		var a: float = lerpf(arc_from, arc_to, a_u)
		var inner := ORCHESTRA + 0.8
		var outer := ORCHESTRA + 1.2 + rows * 0.9
		var mid := (inner + outer) / 2.0
		var run := outer - inner
		var rise := 0.4 * rows
		var slope := atan2(rise, run)
		Kit.box(g, Vector3(cos(a), 0, sin(a)) * mid + Vector3(0, rise / 2.0, 0), Vector3(sqrt(run * run + rise * rise), 0.2, 0.8),
			"stone", true, Vector3(0, -a, slope))
	var skene_z := ORCHESTRA + 2.5
	var doors: Array = []
	if whole:
		Kit.box(g, Vector3(0, 3.0, skene_z + 1.5), Vector3(16.0, 6.0, 3.0), "stone")
		Kit.box(g, Vector3(0, 6.15, skene_z + 1.5), Vector3(16.6, 0.3, 3.4), "roof", false)
		for x: float in [-4.5, 0.0, 4.5]:  # the three doors, the middle one the palace's
			var w := 1.8 if x == 0.0 else 1.3
			Kit.box(g, Vector3(x, 1.4 if x != 0.0 else 1.6, skene_z - 0.02), Vector3(w, 2.8 if x != 0.0 else 3.2, 0.1), "dark", false)
			doors.append(Vector3(x, 0, skene_z - 0.5))
		Kit.box(g, Vector3(0, 0.3, skene_z - 1.2), Vector3(16.0, 0.6, 2.2), "stone")  # the low stage before it
		for k in 9:  # the proskenion's columns
			Kit.column(g, Vector3(-8.0 + k * 2.0, 0.6, skene_z - 2.2), 2.6)
		Kit.box(g, Vector3(0, 3.35, skene_z - 2.2), Vector3(16.6, 0.3, 0.6), "marble", false)
	else:
		for x: float in [-7.0, -3.5, 0.0, 3.5, 7.0]:
			Kit.box(g, Vector3(x, 0.4, skene_z + 1.5), Vector3(2.4, 0.8 + absf(x) * 0.05, 3.0), "stone")
		Kit.fallen_column(g, Vector3(2.0, 0, skene_z - 3.0), 1.3)
	return {"root": g, "altar": Vector3.ZERO, "doors": doors, "crane_at": Vector3(7.5, 6.3, skene_z + 1.5)}


## A theatre mask, faced +Z: "tragic" (pale, the brows drawn up in grief, the mouth wide and
## turned down, a tall crown of hair, the onkos) or "comic" (ruddy, a grinning trumpet mouth,
## a snub nose). `size` 1.0 is worn on a head; hung on a wall it can be larger.
static func mask(parent: Node3D, at: Vector3, yaw: float, kind: String = "tragic", size: float = 1.0) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	g.scale = Vector3.ONE * size
	var comic := kind == "comic"
	var face := "#c8805a" if comic else "#e8dcc4"
	var hair := "#3a2418" if comic else "#2a1c14"
	Kit.blob(g, Vector3.ZERO, 0.16, face, Vector3(1.0, 1.25, 0.45), 8)
	Kit.blob(g, Vector3(0, 0.14 if not comic else 0.1, -0.04), 0.17, hair, Vector3(1.05, 0.6 if comic else 1.3, 0.6), 8)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.055, 0.05, 0.065), Vector3(0.05, 0.035, 0.02), "dark", false)  # eye holes
		Kit.box(g, Vector3(side * 0.055, 0.1, 0.07), Vector3(0.07, 0.015, 0.015), hair, false,
			Vector3(0, 0, side * (-0.25 if comic else 0.45)))  # the brows
	Kit.box(g, Vector3(0, -0.01, 0.075), Vector3(0.03, 0.06 if not comic else 0.04, 0.03), face, false)  # nose
	if comic:
		Kit.box(g, Vector3(0, -0.1, 0.07), Vector3(0.14, 0.05, 0.02), "dark", false)  # the grin
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 0.075, -0.08, 0.07), Vector3(0.04, 0.03, 0.02), "dark", false, Vector3(0, 0, side * 0.5))
	else:
		Kit.box(g, Vector3(0, -0.11, 0.07), Vector3(0.08, 0.06, 0.02), "dark", false)  # the open, grieving mouth
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 0.05, -0.13, 0.07), Vector3(0.035, 0.03, 0.02), "dark", false, Vector3(0, 0, side * -0.5))
	return g


## An actor of tragedy or comedy: a long robe, the mask on his face, the tall boots of tragedy
## (kothornoi). A walker, so he can pace the stage. Returns what kit.gd's walker returns.
static func actor(parent: Node3D, at: Vector3, yaw: float, kind: String = "tragic", robe: String = "6a2a3a") -> Dictionary:
	var w := Kit.walker(parent, at, yaw, {"robe": robe, "skin": "c8a078", "hair_color": "2a1c14"})
	mask(w["head"], Vector3(0, 0.09, 0.075), 0.0, kind, 1.0)
	if kind == "tragic":
		for hip in w["legs"]:
			Kit.box(hip, Vector3(0, -0.8, 0.04), Vector3(0.16, 0.14, 0.3), "#2a1c14", false)
	return w


## The theatre's crane (mechane): a timber mast with a swinging arm and a rope, for the god who
## arrives from above to settle everything, or Socrates hung in a basket to think about the sky.
## Faces +Z; the arm reaches forward. Returns the hanging load (its basket, or empty for a god).
static func crane(parent: Node3D, at: Vector3, yaw: float, basket: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 3.0, 0), Vector3(0.35, 6.0, 0.35), "wood")
	var arm := Kit.group(g, Vector3(0, 5.8, 0))
	Kit.box(arm, Vector3(0, 0, 2.2), Vector3(0.25, 0.25, 5.0), "wood", false, Vector3(-0.15, 0, 0))
	Kit.box(arm, Vector3(0, -1.2, 4.3), Vector3(0.03, 2.4, 0.03), "#c8b890", false)  # the rope
	var hung := Kit.group(arm, Vector3(0, -2.4, 4.3))
	if basket:
		Kit.cylinder(hung, Vector3(0, -0.6, 0), 0.45, 0.6, "wicker", false, 8, 0.55)
		for k in 3:
			var a := TAU * k / 3.0
			Kit.box(hung, Vector3(cos(a) * 0.25, 0.1, sin(a) * 0.25), Vector3(0.02, 0.5, 0.02), "#c8b890", false,
				Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5))
	Kit.box(g, Vector3(0, 0.2, -0.8), Vector3(0.9, 0.4, 0.9), "stone", false)  # the counterweight
	return hung


# ---------- Delphi and Alexandria ----------

## Apollo's tripod at Delphi, where the Pythia sat: a bronze cauldron on three tall legs, ring
## handles on its lip, and (with `vapour`) the breath rising from the chasm under it.
static func tripod(parent: Node3D, at: Vector3, vapour: bool = false) -> void:
	var g := Kit.group(parent, at)
	for k in 3:
		var a := TAU * k / 3.0
		Kit.box(g, Vector3(cos(a) * 0.38, 0.85, sin(a) * 0.38), Vector3(0.06, 1.75, 0.06), "bronze", false,
			Vector3(sin(a) * 0.12, 0, -cos(a) * 0.12))
	Kit.cylinder(g, Vector3(0, 1.55, 0), 0.25, 0.4, "bronze", false, 10, 0.5)  # the bowl
	for k in 3:
		var a := TAU * k / 3.0 + PI / 3.0
		Kit.mesh(g, TorusMesh.new(), "bronze", Vector3(cos(a) * 0.48, 2.05, sin(a) * 0.48), Vector3(PI / 2.0, a, 0),
			Vector3.ONE * 0.1)
	var body := CylinderShape3D.new()
	body.radius = 0.5
	body.height = 2.0
	Kit.solid(g, body, Vector3(0, 1.0, 0))
	if vapour:
		var p := Kit._drift(g, Vector3(0, 0.3, 0), 8, 5.0, 0.8, "smoke", Vector3.UP, 12.0, Vector2(0.3, 0.6))
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.8


## The omphalos, the navel of the world at Delphi: a stone like an egg on a plinth, wrapped in a
## carved net of woollen fillets.
static func omphalos(parent: Node3D, at: Vector3) -> void:
	var g := Kit.group(parent, at)
	Kit.box(g, Vector3(0, 0.2, 0), Vector3(1.2, 0.4, 1.2), "stone")
	Kit.blob(g, Vector3(0, 0.95, 0), 0.5, "marble", Vector3(1.0, 1.4, 1.0), 10)
	for k in 3:  # the net: rings round it, and bands over the top
		Kit.cylinder(g, Vector3(0, 0.55 + k * 0.28, 0), 0.52 - absf(k - 1) * 0.06, 0.04, "stone", false, 10)
	for a: float in [0.0, PI / 2.0]:
		Kit.box(g, Vector3(0, 1.15, 0), Vector3(0.04, 0.6, 0.98), "stone", false, Vector3(0, a, 0))


## The Pharos of Alexandria seen across the harbour: a square tower on a wide base, then an
## octagon, then a round lantern with the fire burning at the top and a statue of Zeus above.
## `size` 1.0 is about 110 m high. Not solid. Returns its fire's light, for the Hall to flicker.
static func pharos(parent: Node3D, at: Vector3, size: float = 1.0) -> OmniLight3D:
	var g := Kit.group(parent, at)
	g.scale = Vector3.ONE * size
	Kit.box(g, Vector3(0, 4.0, 0), Vector3(40.0, 8.0, 40.0), "stone", false)  # the platform
	Kit.box(g, Vector3(0, 37.0, 0), Vector3(20.0, 58.0, 20.0), "marble", false)  # the square tower
	for k in 6:  # its rows of windows
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 10.05, 16.0 + k * 8.0, 0), Vector3(0.2, 2.2, 1.4), "dark", false)
	Kit.box(g, Vector3(0, 66.5, 0), Vector3(22.0, 1.0, 22.0), "marble", false)
	Kit.cylinder(g, Vector3(0, 67.0, 0), 8.0, 26.0, "marble", false, 8, 7.0)  # the octagon
	Kit.cylinder(g, Vector3(0, 93.0, 0), 4.5, 8.0, "marble", false, 12, 4.0)  # the round lantern
	for k in 8:
		var a := TAU * k / 8.0
		Kit.box(g, Vector3(cos(a) * 4.3, 97.0, sin(a) * 4.3), Vector3(1.2, 6.0, 0.4), "fire", false, Vector3(0, -a + PI / 2.0, 0))
	Kit.cylinder(g, Vector3(0, 101.0, 0), 4.8, 1.0, "marble", false, 12)
	Kit.cylinder(g, Vector3(0, 102.0, 0), 1.0, 5.0, "bronze", false, 6, 0.7)  # Zeus the Saviour
	Kit.blob(g, Vector3(0, 107.6, 0), 0.8, "bronze")
	var l := OmniLight3D.new()
	l.position = Vector3(0, 97.0, 0)
	l.light_color = Color("ffb060")
	l.light_energy = 3.0
	l.omni_range = 60.0
	g.add_child(l)
	return l


## Euclid's sand tray (abax): a board of fine sand on legs with the Elements' first
## proposition drawn in it (two circles through each other's centres, and the equal-sided
## triangle on the line between them), a pair of dividers and a straightedge beside it. Faces +Z.
static func sand_tray(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.82, 0), Vector3(1.6, 0.08, 1.1), "wood")
	for p: Vector3 in [Vector3(-0.72, 0.4, -0.48), Vector3(0.72, 0.4, -0.48), Vector3(-0.72, 0.4, 0.48), Vector3(0.72, 0.4, 0.48)]:
		Kit.box(g, p, Vector3(0.08, 0.8, 0.08), "wood", false)
	Kit.box(g, Vector3(0, 0.87, 0), Vector3(1.45, 0.02, 0.95), "sand", false)
	var body := BoxShape3D.new()
	body.size = Vector3(1.6, 0.9, 1.1)
	Kit.solid(g, body, Vector3(0, 0.45, 0))
	const R := 0.3
	var y := 0.885
	var groove := "#8a7450"
	for c: Vector3 in [Vector3(-R / 2.0, y, 0.05), Vector3(R / 2.0, y, 0.05)]:
		for k in 28:  # each circle as a ring of little marks
			var a := TAU * k / 28.0
			Kit.box(g, c + Vector3(cos(a), 0, sin(a)) * R, Vector3(0.012, 0.004, 2.0 * PI * R / 28.0 + 0.004), groove, false,
				Vector3(0, -a, 0))
	var pts := [Vector3(-R / 2.0, y, 0.05), Vector3(R / 2.0, y, 0.05), Vector3(0, y, 0.05 - R * sqrt(3.0) / 2.0)]
	for i in 3:  # the triangle
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 3]
		Kit.box(g, (a + b) / 2.0, Vector3(0.014, 0.005, a.distance_to(b)), groove, false, Vector3(0, atan2(b.x - a.x, b.z - a.z), 0))
	for side: float in [-1.0, 1.0]:  # the dividers, open, lying on the board's rim
		Kit.box(g, Vector3(0.55 + side * 0.04, 0.9, -0.3), Vector3(0.012, 0.012, 0.3), "bronze", false, Vector3(0, side * 0.15, 0))
	Kit.box(g, Vector3(-0.5, 0.9, -0.35), Vector3(0.5, 0.015, 0.04), "wood", false, Vector3(0, 0.3, 0))  # the straightedge


# ---------- Plato ----------

## The cave of the Republic, seen from its mouth (+Z) looking in (-Z): the prisoners chained on a
## bench facing the back wall, the low wall behind them, bearers walking behind that wall with
## things held up on poles, the fire behind the bearers, and the shadows the things throw on the
## back wall; a steep way climbs to the daylight behind it all. The rock encloses it. Returns
## {"root", "fire", "bearers": [{node, from, to}], "shadows": [{node, bearer}]}: the Hall walks
## the bearers along X and keeps each shadow under its bearer's thing.
static func cave(parent: Node3D, at: Vector3, yaw: float) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	const W := 16.0
	Kit.box(g, Vector3(0, -0.1, 0), Vector3(W, 0.2, 22.0), "cave")  # the floor
	Kit.box(g, Vector3(0, 4.0, -9.5), Vector3(W, 8.0, 1.0), "cave")  # the back wall
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * (W / 2.0 + 0.5), 4.0, 0), Vector3(1.0, 8.0, 22.0), "cave")
	Kit.box(g, Vector3(0, 8.2, -1.0), Vector3(W + 2.0, 0.6, 18.0), "cave")  # the roof
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for k in 12:  # hanging rock
		Kit.blob(g, Vector3(rng.randf_range(-7, 7), 7.6, rng.randf_range(-9, 6)), rng.randf_range(0.5, 1.2), "cave",
			Vector3(1.0, 1.4, 1.0), 5)
	# the prisoners: on a bench, facing the wall, bound at the neck and legs
	Kit.box(g, Vector3(0, 0.25, -3.5), Vector3(8.0, 0.5, 0.6), "cave")
	for k in 5:
		var x := -3.2 + k * 1.6
		var p := Kit.group(g, Vector3(x, 0.5, -3.5), PI)  # facing -Z, the wall
		Kit.box(p, Vector3(0, 0.25, 0), Vector3(0.45, 0.2, 0.5), "#5a5248", false)  # lap
		Kit.cylinder(p, Vector3(0, 0.3, -0.05), 0.2, 0.55, "#5a5248", false, 8, 0.16)
		Kit.blob(p, Vector3(0, 0.95, -0.05), 0.2, "#5a5248", Vector3(1.3, 0.5, 0.8), 8)
		Kit.blob(p, Vector3(0, 1.2, 0.0), 0.12, "#a8947c", Vector3(1.0, 1.15, 1.0), 7)
		Kit.box(p, Vector3(0, 1.06, 0), Vector3(0.5, 0.05, 0.05), "#3a3a3e", false)  # the bar at the neck
		Kit.box(p, Vector3(0, 0.05, 0.28), Vector3(0.5, 0.05, 0.05), "#3a3a3e", false)  # the chain at the legs
	Kit.box(g, Vector3(0, 0.55, 0.5), Vector3(W - 1.0, 1.1, 0.4), "stone")  # the low wall, like a puppet screen
	var fire := Kit.hearth(g, Vector3(0, 0, 5.0), true)
	for x: float in [-3.0, 3.0]:
		Kit.hearth(g, Vector3(x, 0, 5.2), true)
	var things := ["horse", "jar", "man", "tree"]
	var bearers: Array = []
	var shadows: Array = []
	for k in things.size():
		var from := Vector3(-6.5 + k * 3.5, 0, 2.2)
		var b := Kit.walker(g, from, PI / 2.0, {"robe": "5a4a3a", "skin": "a8947c"})
		var pole := Kit.group(b["root"], Vector3(0.3, 0, 0.2))
		Kit.box(pole, Vector3(0, 1.8, 0), Vector3(0.04, 1.6, 0.04), "wood", false)
		_idol(pole, Vector3(0, 2.75, 0), things[k], "wood")
		bearers.append({"node": b["root"], "from": -6.5, "to": 6.5, "legs": b["legs"]})
		var sh := Kit.group(g, Vector3(from.x, 0, -8.95))  # thrown big on the wall by the fire behind
		sh.scale = Vector3(2.2, 2.2, 0.02)
		_idol(sh, Vector3(0, 1.9, 0), things[k], "shadow")
		shadows.append({"node": sh, "bearer": k})
	var light := QuadMesh.new()  # the daylight at the top of the way out
	light.size = Vector2(4.0, 3.0)
	Kit.mesh(g, light, "daysky", Vector3(0, 6.2, 10.9), Vector3(0, PI, 0))
	Kit.box(g, Vector3(0, 2.6, 8.5), Vector3(4.0, 0.3, 6.0), "cave", true, Vector3(-0.75, 0, 0))  # the steep way up
	return {"root": g, "fire": fire, "bearers": bearers, "shadows": shadows}


## A small figure carried on a pole in the cave (or its shadow): a horse, a jar, a man, a tree.
static func _idol(parent: Node3D, at: Vector3, thing: String, mat: String) -> void:
	match thing:
		"horse":
			Kit.box(parent, at, Vector3(0.1, 0.22, 0.55), mat, false)
			Kit.box(parent, at + Vector3(0, 0.22, 0.28), Vector3(0.08, 0.3, 0.12), mat, false, Vector3(0.4, 0, 0))
			for z: float in [-0.2, 0.2]:
				Kit.box(parent, at + Vector3(0, -0.22, z), Vector3(0.06, 0.25, 0.06), mat, false)
		"jar":
			Kit.blob(parent, at, 0.18, mat, Vector3(1.0, 1.3, 1.0), 6)
			Kit.box(parent, at + Vector3(0, 0.28, 0), Vector3(0.1, 0.14, 0.1), mat, false)
		"man":
			Kit.box(parent, at, Vector3(0.1, 0.45, 0.2), mat, false)
			Kit.blob(parent, at + Vector3(0, 0.33, 0), 0.08, mat)
		"tree":
			Kit.box(parent, at + Vector3(0, -0.1, 0), Vector3(0.05, 0.4, 0.05), mat, false)
			Kit.blob(parent, at + Vector3(0, 0.22, 0), 0.22, mat, Vector3(1.0, 0.8, 1.0), 6)


## A herm: a square pillar with a bearded head of Hermes on top, set up at crossroads, gates and
## the Academy's paths. Faces +Z.
static func herm(parent: Node3D, at: Vector3, yaw: float, mat: String = "marble") -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.7, 0), Vector3(0.36, 1.4, 0.32), mat)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.22, 1.2, 0), Vector3(0.1, 0.12, 0.14), mat, false)  # the stumps of the arms
	Kit.blob(g, Vector3(0, 1.62, 0.02), 0.16, mat, Vector3(1.0, 1.2, 1.1), 8)
	Kit.blob(g, Vector3(0, 1.45, 0.1), 0.12, mat, Vector3(1.0, 1.5, 0.7), 6)  # the beard
	Kit.blob(g, Vector3(0, 1.72, -0.02), 0.16, mat, Vector3(1.05, 0.7, 1.1), 8)  # the hair


# ---------- the house and its work ----------

## A warp-weighted loom, Penelope's, leaning against a wall (-Z): two uprights, the cloth beam at
## the top with the web wound on it, the warp threads hanging in rows, the heddle bar, and the
## clay weights that keep them taut. `woven` is how far down the web has grown (0 to 1). Faces +Z.
static func loom(parent: Node3D, at: Vector3, yaw: float, woven: float = 0.4, cloth: String = "#e8e0d0") -> void:
	var g := Kit.group(parent, at, yaw)
	var frame := Kit.group(g, Vector3.ZERO)
	frame.rotation.x = -0.18  # it leans back against the wall
	for x: float in [-0.95, 0.95]:
		Kit.box(frame, Vector3(x, 1.2, 0), Vector3(0.1, 2.4, 0.1), "wood", false)
	Kit.mesh(frame, Kit._cyl(0.07, 2.1), "wood", Vector3(0, 2.25, 0), Vector3(0, 0, PI / 2.0))  # the cloth beam
	var web := 1.9 * clampf(woven, 0.0, 1.0)
	if web > 0.0:
		Kit.box(frame, Vector3(0, 2.2 - web / 2.0, 0.02), Vector3(1.7, web, 0.02), cloth, false)
	var threads := 24
	for k in threads:  # the warp, from the web down to the weights
		var x := -0.8 + k * (1.6 / (threads - 1))
		var top := 2.2 - web
		Kit.box(frame, Vector3(x, (top + 0.35) / 2.0, 0.03), Vector3(0.006, top - 0.35, 0.006), "#d8d0b8", false)
	Kit.box(frame, Vector3(0, 1.0, 0.1), Vector3(1.9, 0.05, 0.05), "wood", false)  # the heddle bar
	for k in 8:  # the loom weights, in pairs
		Kit.cylinder(frame, Vector3(-0.72 + k * 0.205, 0.2, 0.03), 0.06, 0.16, "clay", false, 6, 0.03)
	var body := BoxShape3D.new()
	body.size = Vector3(2.1, 2.4, 0.5)
	Kit.solid(g, body, Vector3(0, 1.2, -0.2))


## A symposium couch (kline): a wooden frame on tall legs, a mattress, cushions to lean on at its
## head (+X end), and the low three-legged table in front with a cup. Long side along X, facing +Z.
static func kline(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.7, 0), Vector3(2.0, 0.1, 0.9), "wood", false)
	for p: Vector3 in [Vector3(-0.92, 0.33, -0.38), Vector3(0.92, 0.33, -0.38), Vector3(-0.92, 0.33, 0.38), Vector3(0.92, 0.33, 0.38)]:
		Kit.box(g, p, Vector3(0.1, 0.66, 0.1), "wood", false)
	Kit.box(g, Vector3(0, 0.82, 0), Vector3(1.9, 0.14, 0.85), "#d8c8a0", false)
	Kit.box(g, Vector3(0, 0.9, 0), Vector3(1.9, 0.04, 0.87), "#6a2e4a", false)  # a purple cover
	Kit.blob(g, Vector3(0.75, 1.02, 0), 0.2, "#b8863a", Vector3(1.0, 0.8, 1.6), 6)  # the cushions
	Kit.box(g, Vector3(0.98, 1.05, 0), Vector3(0.08, 0.35, 0.85), "wood", false)  # the headrest
	var body := BoxShape3D.new()
	body.size = Vector3(2.0, 0.95, 0.9)
	Kit.solid(g, body, Vector3(0, 0.47, 0))
	Kit.box(g, Vector3(0, 0.5, 0.8), Vector3(0.9, 0.05, 0.45), "wood", false)  # the table
	for p: Vector3 in [Vector3(-0.35, 0.25, 0.65), Vector3(0.35, 0.25, 0.65), Vector3(0, 0.25, 0.95)]:
		Kit.box(g, p, Vector3(0.05, 0.5, 0.05), "wood", false)
	kylix(g, Vector3(0.15, 0.53, 0.8))


## A krater, the great bowl where wine was mixed with water, painted black-figure, on a stand.
static func krater(parent: Node3D, at: Vector3) -> void:
	var g := Kit.group(parent, at)
	Kit.cylinder(g, Vector3.ZERO, 0.2, 0.3, "stone", false, 8, 0.14)
	Kit.cylinder(g, Vector3(0, 0.3, 0), 0.12, 0.12, "blackfigure", false, 10, 0.2)
	Kit.cylinder(g, Vector3(0, 0.42, 0), 0.2, 0.45, "blackfigure", false, 10, 0.33)  # the bell
	Kit.cylinder(g, Vector3(0, 0.87, 0), 0.33, 0.04, "#1a1410", false, 10)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.28, 0.62, 0), Vector3(0.06, 0.06, 0.2), "#1a1410", false)  # the handles
	var body := CylinderShape3D.new()
	body.radius = 0.33
	body.height = 0.9
	Kit.solid(g, body, Vector3(0, 0.45, 0))


## A kylix, the shallow drinking cup on a stem with two handles.
static func kylix(parent: Node3D, at: Vector3) -> void:
	var g := Kit.group(parent, at)
	Kit.cylinder(g, Vector3.ZERO, 0.04, 0.01, "#1a1410", false, 8)
	Kit.cylinder(g, Vector3(0, 0.01, 0), 0.015, 0.04, "#1a1410", false, 6)
	Kit.cylinder(g, Vector3(0, 0.05, 0), 0.05, 0.035, "blackfigure", false, 10, 0.1)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.11, 0.075, 0), Vector3(0.03, 0.012, 0.012), "#1a1410", false)


## Sappho's barbitos: the lyre with long arms and a deep voice, standing on its sound box.
static func barbitos(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := Kit.group(parent, at, yaw)
	Kit.blob(g, Vector3(0, 0.12, 0), 0.14, "#6a4a2a", Vector3(1.1, 0.9, 0.5), 6)  # the shell
	for side: float in [-1.0, 1.0]:  # the long arms, bowing in then out
		Kit.box(g, Vector3(0.1 * side, 0.45, 0), Vector3(0.035, 0.55, 0.035), "wood", false, Vector3(0, 0, -0.12 * side))
		Kit.box(g, Vector3(0.1 * side, 0.85, 0), Vector3(0.035, 0.3, 0.035), "wood", false, Vector3(0, 0, 0.3 * side))
	Kit.box(g, Vector3(0, 0.98, 0), Vector3(0.38, 0.035, 0.035), "wood", false)
	for k in 7:
		Kit.box(g, Vector3(-0.09 + k * 0.03, 0.58, 0.03), Vector3(0.005, 0.8, 0.005), "#e8e0c8", false)


# ---------- the farm (Hesiod) ----------

## A ploughed field, `size` metres, its furrows running along X (not solid: you walk it).
static func field(parent: Node3D, at: Vector3, size: Vector2, yaw: float = 0.0) -> void:
	Kit.box(parent, at + Vector3(0, 0.02, 0), Vector3(size.x, 0.04, size.y), "furrows", false, Vector3(0, yaw, 0))


## A threshing floor: a round of flat stones with a low kerb, where the oxen trod the grain out.
static func threshing_floor(parent: Node3D, at: Vector3, radius: float = 5.0) -> void:
	Kit.cylinder(parent, at, radius, 0.08, "paving", false, 14)
	for k in 20:
		var a := TAU * k / 20.0
		Kit.box(parent, at + Vector3(cos(a), 0, sin(a)) * radius + Vector3(0, 0.15, 0), Vector3(2.0 * PI * radius / 20.0, 0.3, 0.3),
			"stone", false, Vector3(0, -a + PI / 2.0, 0))


## Clay beehives as the Greeks kept them: long tubes laid on their sides in a stack, the bees'
## doors toward +Z.
static func hives(parent: Node3D, at: Vector3, yaw: float, count: int = 5) -> void:
	var g := Kit.group(parent, at, yaw)
	for k in count:
		var row := 0 if k < (count + 1) / 2 else 1
		var col := k if row == 0 else k - (count + 1) / 2
		var x := (col - (count + 1) / 4.0) * 0.5 + row * 0.25
		Kit.mesh(g, _prism(0.2, 0.8, 8), "clay", Vector3(x, 0.22 + row * 0.42, 0), Vector3(PI / 2.0, 0, 0))
		Kit.mesh(g, _prism(0.06, 0.02, 6), "dark", Vector3(x, 0.22 + row * 0.42, 0.4), Vector3(PI / 2.0, 0, 0))
	var body := BoxShape3D.new()
	body.size = Vector3(0.5 * count / 2.0 + 0.6, 0.9, 0.9)
	Kit.solid(g, body, Vector3(0, 0.45, 0))


# ---------- sacred and civic ----------

## An altar: a stone block with rolled ends. "greek" plain; "roman" with a garland and horns at
## the corners. `lit` burns an offering on it; returns the fire's light (or null).
static func altar(parent: Node3D, at: Vector3, yaw: float, style: String = "greek", lit: bool = false) -> OmniLight3D:
	var g := Kit.group(parent, at, yaw)
	var stone := "marble" if style == "roman" else "stone"
	Kit.box(g, Vector3(0, 0.1, 0), Vector3(1.6, 0.2, 1.0), stone)
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(1.3, 0.8, 0.8), stone)
	Kit.box(g, Vector3(0, 1.05, 0), Vector3(1.45, 0.1, 0.9), stone, false)
	for side: float in [-1.0, 1.0]:  # the bolsters rolled at each end
		Kit.mesh(g, _prism(0.13, 0.9, 8), stone, Vector3(side * 0.62, 1.2, 0), Vector3(PI / 2.0, 0, 0))
	if style == "roman":
		for side: float in [-1.0, 1.0]:
			Kit.box(g, Vector3(side * 0.66, 1.28, 0.42), Vector3(0.1, 0.2, 0.1), stone, false)  # the horns
		for k in 5:  # the garland swinging across the front
			var u := k / 4.0
			Kit.blob(g, Vector3(-0.5 + u, 0.8 - sin(u * PI) * 0.18, 0.42), 0.08, "olive", Vector3(1.4, 1.0, 0.7), 5)
	if not lit:
		return null
	for p: Vector3 in [Vector3(0, 1.25, 0), Vector3(0.12, 1.2, 0.08)]:
		Kit.blob(g, p, 0.18, "fire", Vector3(1.0, 1.6, 1.0), 5)
	var smoke := Kit._drift(g, Vector3(0, 1.5, 0), 6, 4.0, 0.7, "smoke", Vector3.UP, 8.0, Vector2(0.5, 0.8))
	smoke.scale_amount_max = 1.6
	var l := OmniLight3D.new()
	l.position = Vector3(0, 1.8, 0)
	l.light_color = Color("ff9a48")
	l.light_energy = 1.4
	l.omni_range = 6.0
	g.add_child(l)
	return l


## A speaker's platform (bema), like the one cut from the rock of the Pnyx where Athens met:
## a block with steps up its back (-Z), the speaker facing +Z.
static func bema(parent: Node3D, at: Vector3, yaw: float) -> Vector3:
	var g := Kit.group(parent, at, yaw)
	Kit.box(g, Vector3(0, 0.6, 0), Vector3(2.4, 1.2, 2.0), "rock")
	for k in 3:
		Kit.box(g, Vector3(0, 0.2 + k * 0.4, -1.2 - (2 - k) * 0.35), Vector3(1.0, 0.4 + k * 0.4, 0.35), "rock", true)
	return at + Vector3(0, 1.2, 0)


## A cylinder of `sides` sides centred on its middle (for wheels, beams and hives turned on
## their side, and triangles), `depth` long.
static func _prism(radius: float, depth: float, sides: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = depth
	c.radial_segments = sides if sides == 3 else sides * Kit.detail
	c.rings = 1
	return c
