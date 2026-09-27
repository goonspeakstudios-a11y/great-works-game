extends RefCounted
## The people of the Greek places still to come, and the arms you see when you play a hero.
## Homer is played as the scene's hero (Achilles, Hector at the gate, Priam kneeling, Telemachus,
## Odysseus): `hero_arms` hangs that hero's forearms and what he holds in front of the player's
## camera. `figure` builds a named person as a walker (kit.gd's), so the Hall can walk and turn
## them; a figure who is `undead` is a pale shade (Kit.shade), as are all the dead of the
## underworld. The Cyclops and the Sirens are their own builders.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")

## Each hero's arms: skin, sleeve, and what each hand holds.
const HEROES := {
	"achilles": {"skin": "#c8a078", "sleeve": "bronze", "left": "shield", "right": "spear"},
	"hector": {"skin": "#b88a64", "sleeve": "#6a2a2a", "left": "helmet", "right": "spear"},
	"priam": {"skin": "#c8b09a", "sleeve": "#4a4450", "left": "", "right": ""},
	"telemachus": {"skin": "#d0a880", "sleeve": "#8a6a44", "left": "", "right": "spear"},
	"odysseus": {"skin": "#b8906a", "sleeve": "#7a3a24", "left": "bow", "right": "arrow"},
	"odysseus_bound": {"skin": "#b8906a", "sleeve": "#7a3a24", "left": "rope", "right": "rope"},
}


## The hero's forearms and what he holds, hung low in front of `camera` (which looks down -Z):
## Achilles' ash spear and his shield, Hector's spear and the crested helmet in his hand, Priam's
## empty old hands, Telemachus's spear, Odysseus's bow and an arrow, or his wrists bound to the
## mast for the Sirens. No collision and no shadows. Returns {"root", "hands": [left, right],
## "held": [what the left holds, what the right holds]}, so the Hall can raise, lower and swap them.
static func hero_arms(camera: Node3D, hero: String) -> Dictionary:
	var h: Dictionary = HEROES.get(hero, HEROES["achilles"])
	var root := Kit.group(camera, Vector3(0, -0.28, -0.45))
	var hands: Array = []
	var held: Array = []
	for side: float in [-1.0, 1.0]:
		var hand := Kit.group(root, Vector3(0.24 * side, 0, 0))
		Kit.mesh(hand, Kit._cyl(0.045, 0.34), str(h["sleeve"]), Vector3(0, -0.02, 0.12), Vector3(PI / 2.0 - 0.25, 0, 0))  # the forearm
		Kit.blob(hand, Vector3(0, 0.02, -0.07), 0.05, str(h["skin"]), Vector3(1.0, 0.8, 1.3), 6)  # the hand
		var what: String = h["left" if side < 0.0 else "right"]
		held.append(_held(hand, what, side))
		hands.append(hand)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.unsolid(root)
	return {"root": root, "hands": hands, "held": held}


## What a hero's hand holds, built in the hand's space.
static func _held(hand: Node3D, what: String, side: float) -> Node3D:
	var g := Kit.group(hand, Vector3(0, 0, -0.07))
	match what:
		"spear":  # upright past the shoulder, slanting forward
			Kit.box(g, Vector3(0, 0.5, -0.1), Vector3(0.025, 1.6, 0.025), "wood", false, Vector3(-0.35, 0, 0))
			Kit.box(g, Vector3(0, 1.28, -0.38), Vector3(0.04, 0.16, 0.012), "bronze", false, Vector3(-0.35, 0, 0))
		"shield":  # the great round shield across the left of the view
			Kit.mesh(g, Greek._prism(0.3, 0.04, 12), "bronze", Vector3(-0.1, 0.02, -0.08), Vector3(PI / 2.0, 0, 0.3))
			Kit.mesh(g, Greek._prism(0.07, 0.05, 8), "gold", Vector3(-0.1, 0.02, -0.11), Vector3(PI / 2.0, 0, 0.3))
		"helmet":  # held by its cheek pieces, its horsehair crest nodding
			Kit.blob(g, Vector3(0, 0.08, -0.02), 0.11, "bronze", Vector3(1.0, 1.1, 1.1), 7)
			Kit.box(g, Vector3(0, 0.23, -0.02), Vector3(0.03, 0.1, 0.24), "#2a2a2a", false)
		"bow":  # held upright, its curve of horn and wood
			for k in 5:
				var t := (k - 2) / 2.0
				Kit.box(g, Vector3(-0.04 * t * t, 0.15 * t, 0), Vector3(0.025, 0.17, 0.025), "#5a3a22", false, Vector3(0, 0, t * 0.35))
			Kit.box(g, Vector3(0.03, 0, 0.0), Vector3(0.004, 0.62, 0.004), "#d8d0b8", false)  # the string
		"arrow":
			Kit.box(g, Vector3(0, 0.02, -0.18), Vector3(0.008, 0.008, 0.5), "wood", false)
			Kit.box(g, Vector3(0, 0.02, -0.44), Vector3(0.02, 0.02, 0.05), "bronze", false)
		"rope":  # the cord round the wrists and the mast
			Kit.mesh(g, TorusMesh.new(), "#c8b890", Vector3(0, 0, 0.02), Vector3(0, 0, PI / 2.0), Vector3(0.06, 0.08, 0.06))
			Kit.box(g, Vector3(-side * 0.12, 0, 0.1), Vector3(0.24, 0.02, 0.02), "#c8b890", false)
	return g


## Who is who: the robe, skin, hair and beard of each named person, how tall they stand, and what
## they carry or wear. "props" name the extras `figure` adds.
const WHO := {
	"agamemnon": {"robe": "5a1a3a", "skin": "c09070", "hair_color": "2a1e16", "beard": "long", "props": ["crown", "sceptre"]},
	"athena": {"robe": "d8cfa8", "skin": "e0c0a0", "hair_color": "3a2418", "size": 1.25, "props": ["helmet", "aegis", "spear", "owl"]},
	"thetis": {"robe": "4a7a7a", "skin": "e8d0c0", "hair_color": "1e2a2a", "props": ["veil"]},
	"briseis": {"robe": "8a2a2a", "skin": "d0a080", "hair_color": "1a1410", "props": ["veil"]},
	"phoenix": {"robe": "6a5a4a", "skin": "c8a888", "hair_color": "e0dcd4", "beard": "long", "props": ["staff"]},
	"ajax": {"robe": "5a4a3a", "skin": "b88a64", "hair_color": "2a1e16", "beard": "short", "size": 1.18, "props": ["tower_shield"]},
	"odysseus": {"robe": "7a3a24", "skin": "b8906a", "hair_color": "5a3a22", "beard": "short", "props": ["pilos"]},
	"hector": {"robe": "6a2a2a", "skin": "b88a64", "hair_color": "2a1e16", "beard": "short", "props": ["helmet", "spear"]},
	"andromache": {"robe": "6a5a8a", "skin": "d8b090", "hair_color": "1a1410", "props": ["veil", "baby"]},
	"priam": {"robe": "3a3440", "skin": "c8b09a", "hair_color": "e8e4dc", "beard": "long", "props": ["crown"]},
	"hermes": {"robe": "8a7a5a", "skin": "d0a878", "hair_color": "4a3018", "props": ["petasos", "caduceus"]},
	"penelope": {"robe": "3a4a6a", "skin": "d8b898", "hair_color": "2a1e16", "props": ["veil"]},
	"eurycleia": {"robe": "5a5048", "skin": "c0a890", "hair_color": "c8c4bc", "props": ["veil"]},
	"telemachus": {"robe": "8a6a44", "skin": "d0a880", "hair_color": "5a3a22", "props": ["spear"]},
	"suitor": {"robe": "7a5a2a", "skin": "c8a078", "hair_color": "3a2a1e", "beard": "short", "props": ["cup"]},
	"teiresias": {"robe": "4a4a4a", "skin": "b8b0a8", "hair_color": "e8e4dc", "beard": "long", "props": ["staff"]},
	"anticleia": {"robe": "4a4450", "skin": "c0b0a0", "hair_color": "c8c4bc", "props": ["veil"]},
	"elpenor": {"robe": "6a5a4a", "skin": "c8a078", "hair_color": "3a2a1e", "props": []},
	"achilles_shade": {"robe": "8a7a5a", "skin": "c8a078", "hair_color": "b8904a", "props": ["spear"]},
	"aphrodite": {"robe": "e8d0d8", "skin": "e8c8b0", "hair_color": "b8904a", "props": ["veil", "girdle"]},
	"muse": {"robe": "d8cfa8", "skin": "e0c0a0", "hair_color": "3a2418", "props": ["veil"]},
	"pandora": {"robe": "e0d8c4", "skin": "e0c0a0", "hair_color": "8a6a3a", "props": ["crown"]},
	"kronos": {"robe": "2a2a30", "skin": "8a8078", "hair_color": "3a3a3a", "beard": "long", "size": 2.2, "props": ["sickle"]},
}


## A named person of the Greek places, standing, facing +Z: see WHO for who there is. A walker,
## so the Hall can walk, turn and bring them to life; with `undead` a pale shade (always so for
## the dead of the underworld). With `pose` "kneel" they kneel (Priam before Achilles); `robe`
## dresses them in another colour (the nine Muses, each in her own). Returns what kit.gd's walker
## returns.
static func figure(parent: Node3D, at: Vector3, yaw: float, who: String, undead: bool = false, pose: String = "",
		robe: String = "") -> Dictionary:
	var w_def: Dictionary = WHO.get(who, WHO["elpenor"])
	var look := {"robe": robe if robe != "" else w_def["robe"], "skin": w_def["skin"], "hair_color": w_def["hair_color"], "beard": w_def.get("beard", "none")}
	var w := Kit.walker(parent, at, yaw, look)
	var root: Node3D = w["root"]
	var head: Node3D = w["head"]
	var hand: Node3D = w["hand"]
	root.scale = Vector3.ONE * float(w_def.get("size", 1.0))
	for prop in w_def["props"]:
		match prop:
			"crown":
				Kit.mesh(head, TorusMesh.new(), "gold", Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.16, 0.25, 0.16))
			"sceptre", "staff":
				Kit.box(root, Vector3(0.36, 0.95, 0.12), Vector3(0.035, 1.9, 0.035), "wood" if prop == "staff" else "gold", false)
				if prop == "sceptre":
					Kit.blob(root, Vector3(0.36, 1.92, 0.12), 0.05, "gold")
			"helmet":
				Kit.blob(head, Vector3(0, 0.2, -0.02), 0.155, "bronze", Vector3(1.05, 0.9, 1.1), 7)
				Kit.box(head, Vector3(0, 0.38, -0.02), Vector3(0.04, 0.12, 0.32), "#2a2a2a" if who != "athena" else "#8a1e1a", false)
			"aegis":  # the goatskin cape of scales with the Gorgon's head on the breast
				Kit.box(root, Vector3(0, 1.4, 0.2), Vector3(0.5, 0.35, 0.05), "verdigris", false)
				Kit.blob(root, Vector3(0, 1.4, 0.24), 0.07, "gold")
			"spear":
				Kit.box(root, Vector3(0.38, 1.3, 0.1), Vector3(0.035, 2.6, 0.035), "wood", false)
				Kit.box(root, Vector3(0.38, 2.68, 0.1), Vector3(0.05, 0.2, 0.015), "bronze", false)
			"owl":
				Kit.blob(root, Vector3(-0.3, 1.66, 0), 0.07, "#8a7a64", Vector3(1.0, 1.3, 1.0), 6)
				for x: float in [-0.025, 0.025]:
					Kit.blob(root, Vector3(-0.3 + x, 1.71, 0.06), 0.015, "#e0b640")
			"veil":
				Kit.blob(head, Vector3(0, 0.12, -0.06), 0.17, str(w_def["robe"]) if who != "anticleia" else "#6a6470",
					Vector3(1.1, 1.1, 1.1), 7)
			"tower_shield":
				Kit.box(root, Vector3(-0.2, 0.95, 0.35), Vector3(0.7, 1.5, 0.08), "#9a7a5a", false, Vector3(0, -0.2, 0))
			"pilos":  # the sailor's conical felt cap
				Kit.cylinder(head, Vector3(0, 0.14, -0.02), 0.14, 0.2, "#8a7a5a", false, 8, 0.05)
			"baby":
				Kit.blob(root, Vector3(0.05, 1.25, 0.22), 0.09, "#e8e0d0", Vector3(1.4, 0.8, 0.9), 6)
				Kit.blob(root, Vector3(0.16, 1.28, 0.22), 0.05, "#e0b890")
			"petasos":
				Kit.cylinder(head, Vector3(0, 0.2, -0.02), 0.22, 0.03, "#8a7a5a", false, 10)
				for x: float in [-0.16, 0.16]:
					Kit.box(head, Vector3(x, 0.26, -0.02), Vector3(0.02, 0.1, 0.12), "#e8e4dc", false, Vector3(0.3, 0, signf(x) * 0.5))
			"caduceus":
				Kit.box(root, Vector3(0.36, 1.1, 0.14), Vector3(0.025, 1.0, 0.025), "gold", false)
				Kit.mesh(root, TorusMesh.new(), "gold", Vector3(0.36, 1.62, 0.14), Vector3(PI / 2.0, 0, 0), Vector3(0.07, 0.1, 0.07))
			"cup":
				Greek.kylix(hand, Vector3(0.3, 1.38, 0.42))
			"girdle":  # Aphrodite's embroidered band
				Kit.cylinder(root, Vector3(0, 1.05, 0), 0.23, 0.06, "gold", false, 8)
			"sickle":
				Kit.box(root, Vector3(0.36, 1.4, 0.2), Vector3(0.03, 0.5, 0.03), "wood", false)
				for k in 4:
					Kit.box(root, Vector3(0.36 + 0.07 * k, 1.7 + 0.04 * k - 0.02 * k * k, 0.2), Vector3(0.1, 0.03, 0.02), "#9a9aa0", false,
						Vector3(0, 0, -0.4 * k))
	if pose == "kneel":
		for hip in w["legs"]:
			(hip as Node3D).rotation.x = -1.4  # thighs forward
		root.position.y -= 0.45 * root.scale.y
	if undead or who in ["teiresias", "anticleia", "elpenor", "achilles_shade"]:
		Kit.shade(root, 0.35 if undead else 0.5)
		w["shade"] = true
	return w


## Polyphemus the Cyclops: a shepherd giant three and a half times a man's height, shaggy, with
## one eye in the middle of his brow and a club cut from a green olive trunk. `blinded`: the eye
## a burnt wound. Lost to the world (alive = false): a heap of giant's bones. Faces +Z. Returns
## what a walker returns, with "eye" (the eye's node).
static func cyclops(parent: Node3D, at: Vector3, yaw: float, blinded: bool = false, alive: bool = true) -> Dictionary:
	if not alive:
		var g := Kit.group(parent, at, yaw)
		Kit.blob(g, Vector3(0, 0.8, 0), 1.0, "bone", Vector3(1.2, 0.6, 2.0), 7)
		Kit.blob(g, Vector3(0, 1.0, 2.4), 0.6, "bone", Vector3(1.0, 1.0, 1.1), 7)  # the skull
		Kit.box(g, Vector3(0, 1.2, 2.95), Vector3(0.3, 0.25, 0.1), "dark", false)  # its one socket
		for k in 4:
			Kit.mesh(g, Kit._cyl(0.12, 2.4), "bone", Vector3(-1.2 + k * 0.8, 0.2, -1.4), Vector3(PI / 2.0, 0.3 * k, 0))
		return {"root": g, "head": g, "hand": g, "legs": [], "eye": g}
	var w := Kit.walker(parent, at, yaw, {"robe": "4a3a2a", "skin": "8a6a4a", "hair_color": "1e1812", "beard": "long"})
	var root: Node3D = w["root"]
	root.scale = Vector3.ONE * 3.5
	var head: Node3D = w["head"]
	Kit.blob(root, Vector3(0, 1.3, -0.05), 0.33, "#3a2a1e", Vector3(1.3, 0.8, 0.9), 7)  # the sheepskins on his back
	var eye := Kit.group(head, Vector3(0, 0.12, 0.13))
	if blinded:
		Kit.box(eye, Vector3.ZERO, Vector3(0.07, 0.05, 0.02), "#4a0a0a", false)
	else:
		Kit.blob(eye, Vector3.ZERO, 0.045, "#e8e0cc")
		Kit.blob(eye, Vector3(0, 0, 0.03), 0.02, "#1a1410")
	Kit.box(root, Vector3(0.38, 0.9, 0.1), Vector3(0.09, 1.7, 0.09), "wood", false, Vector3(0.1, 0, 0))  # the olive club
	w["eye"] = eye
	return w


## A Siren as the Greeks made them: a bird with a woman's head, perched and singing. Lost: a
## grey dead bird-thing among the bones. Faces +Z.
static func siren(parent: Node3D, at: Vector3, yaw: float, alive: bool = true) -> Node3D:
	var g := Kit.group(parent, at, yaw)
	var feathers := "#6a5a4a" if alive else "#5a5856"
	Kit.blob(g, Vector3(0, 0.45, 0), 0.3, feathers, Vector3(0.9, 0.8, 1.3), 7)
	for side: float in [-1.0, 1.0]:
		Kit.box(g, Vector3(side * 0.28, 0.55, -0.05), Vector3(0.06, 0.3, 0.55), feathers, false, Vector3(0.3, 0, side * 0.4))
		Kit.box(g, Vector3(side * 0.08, 0.1, 0.05), Vector3(0.03, 0.2, 0.03), "#b8943a", false)  # the talons
	Kit.box(g, Vector3(0, 0.4, -0.45), Vector3(0.3, 0.06, 0.4), feathers, false, Vector3(-0.4, 0, 0))  # the tail
	var skin := "#e0c0a0" if alive else "bone"
	Kit.blob(g, Vector3(0, 0.95, 0.18), 0.15, skin, Vector3(1.0, 1.15, 1.0), 7)
	Kit.blob(g, Vector3(0, 1.04, 0.14), 0.15, "#3a2418" if alive else "#5a5856", Vector3(1.05, 0.8, 1.05), 7)
	Kit.box(g, Vector3(0, 0.9, 0.32), Vector3(0.05, 0.03, 0.01), "#6a2a2a" if alive else "dark", false)  # the singing mouth
	return g
