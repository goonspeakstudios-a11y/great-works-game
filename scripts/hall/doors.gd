extends RefCounted
## The doors of the Nexus, one per world, each in its world's style: a Greek temple front, a Roman
## arch, the bronze pillars of Solomon's temple, a Byzantine arch of banded brick, a Gothic pointed
## arch, a Moorish horseshoe arch, a Japanese torii, a Palladian window, a plain modern frame, and a
## surreal frame hung crooked with daylight inside it.
##
## Every door frames the same opening (2.2 m wide, 4.4 m high, centred 2.4 m up) so what fills it
## lies in the same place: "void" when sealed, a cold glow, or a warm one. A sealed door is out of
## reach (nothing solid) and three of its blocks float loose above it; an open door gives light.
## build() returns {"root", "light" (OmniLight3D or null), "loose" (the floating blocks)}.

const Kit := preload("res://scripts/hall/kit.gd")

const RED := "#9c3328"
const BRICK := "#8a5a44"
const TILE := "#2f6f73"
const CONCRETE := "#8d8a86"
const STEEL := "#3c4048"


static func build(parent: Node3D, at: Vector3, yaw: float, style: String, state: String) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var sealed := state == "sealed"
	var solid := not sealed
	var mat := _stone(style)
	match style:
		"roman":
			_roman(g, solid)
		"israelite":
			_israelite(g, solid)
		"byzantine":
			_byzantine(g, solid)
		"gothic":
			_gothic(g, solid)
		"moorish":
			_moorish(g, solid)
		"torii":
			_torii(g, solid)
		"palladian":
			_palladian(g, solid)
		"modern":
			_modern(g, solid)
		"surreal":
			_surreal(g, solid)
		_:
			_greek(g, solid)
	Kit.box(g, Vector3(0, 0.1, 0.4), Vector3(4.0, 0.2, 1.6), mat, false)  # the threshold
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 4.4)
	Kit.mesh(g, q, "void" if sealed else ("glow_cold" if state == "cold" else "glow"), Vector3(0, 2.4, -0.1))
	if style == "surreal":
		Kit.mesh(g, q, "daysky", Vector3(0, 2.4, -0.05))
	var loose: Array = []
	var n := 3 if sealed else (1 if state == "cold" and style == "greek" else 0)
	for k in n:
		var b := Kit.group(g, Vector3(-1.5 + 1.5 * k, 6.6 + 0.3 * k, 0.5))
		Kit.box(b, Vector3.ZERO, Vector3(0.6, 0.6, 0.6), mat, false)
		loose.append(b)
	if state == "warm":
		Kit.blob(g, Vector3(0, 6.2, 0.2), 0.25, "fire", Vector3(1, 1.6, 1), 5)
	var light: OmniLight3D = null
	if not sealed:
		light = OmniLight3D.new()
		light.position = Vector3(0, 2.2, 1.2)
		light.light_color = Color("b8c4d8") if state == "cold" else Color("ffd49a")
		light.light_energy = 0.6 if state == "cold" else 1.4
		light.omni_range = 6.0 if state == "cold" else 7.0
		g.add_child(light)
	return {"root": g, "light": light, "loose": loose}


## What a style's threshold and loose blocks are made of.
static func _stone(style: String) -> String:
	match style:
		"surreal":
			return "voidstone"
		"byzantine":
			return BRICK
		"modern":
			return CONCRETE
		"torii":
			return "stone"
		"israelite":
			return "stone"
	return "marble"


## Two uprights either side of the opening.
static func _posts(g: Node3D, w: float, h: float, mat: String, solid: bool, x: float = 1.45) -> void:
	for side in [-x, x]:
		Kit.box(g, Vector3(side, h / 2.0, 0), Vector3(w, h, w), mat, solid)


static func _greek(g: Node3D, solid: bool) -> void:
	for side in [-1.45, 1.45]:
		Kit.cylinder(g, Vector3(side, 0.2, 0), 0.3, 4.6, "marble", solid, 8)
		Kit.box(g, Vector3(side, 4.9, 0), Vector3(0.8, 0.2, 0.8), "marble", false)  # capitals
	Kit.box(g, Vector3(0, 5.2, 0), Vector3(3.8, 0.4, 0.8), "marble", false)  # architrave
	Kit.box(g, Vector3(0, 5.55, 0), Vector3(4.0, 0.3, 0.9), "marble", false)  # cornice
	Kit.cylinder(g, Vector3(0, 5.7, -0.45), 2.1, 0.9, "marble", false, 3).rotation = Vector3(PI / 2.0, 0, 0)  # pediment


static func _roman(g: Node3D, solid: bool) -> void:
	_posts(g, 0.9, 4.6, "marble", solid, 1.55)
	Kit.arch(g, Vector3(0, 4.6, 0), 1.1, 0.0, 180.0, 7, Vector3(0.7, 0.55, 0.9), ["marble"])
	Kit.box(g, Vector3(0, 5.95, 0.05), Vector3(0.45, 0.6, 1.0), "marble", false)  # keystone
	Kit.box(g, Vector3(0, 6.5, 0), Vector3(4.0, 0.6, 1.0), "marble", false)  # attic
	for side in [-1.95, 1.95]:
		Kit.cylinder(g, Vector3(side, 0.2, 0.5), 0.18, 4.4, "marble", false, 8)  # engaged columns


static func _israelite(g: Node3D, solid: bool) -> void:
	for side in [-1.55, 1.55]:  # Jachin and Boaz
		Kit.cylinder(g, Vector3(side, 0.3, 0.3), 0.32, 4.5, "bronze", solid, 8)
		Kit.blob(g, Vector3(side, 5.05, 0.3), 0.5, "bronze", Vector3(1.0, 0.8, 1.0), 6)  # the bowls
	_posts(g, 0.5, 4.6, "stone", solid, 1.2)
	Kit.box(g, Vector3(0, 4.85, 0), Vector3(3.0, 0.5, 0.7), "wood", false)  # cedar lintel
	Kit.box(g, Vector3(0, 5.3, 0), Vector3(3.4, 0.4, 0.8), "stone", false)
	Kit.box(g, Vector3(0, 5.6, 0.1), Vector3(1.8, 0.2, 0.2), "gold", false)


static func _byzantine(g: Node3D, solid: bool) -> void:
	_posts(g, 0.9, 4.6, BRICK, solid, 1.55)
	Kit.arch(g, Vector3(0, 4.6, 0), 1.1, 0.0, 180.0, 9, Vector3(0.5, 0.5, 0.9), [BRICK, "marble"])
	var lunette := QuadMesh.new()
	lunette.size = Vector2(1.6, 0.8)
	Kit.mesh(g, lunette, "gold", Vector3(0, 5.1, 0.46))  # a gold mosaic over the door
	Kit.box(g, Vector3(0, 6.4, 0), Vector3(4.0, 0.3, 1.0), BRICK, false)
	Kit.blob(g, Vector3(0, 6.55, 0), 0.9, "bronze", Vector3(1.0, 0.7, 1.0), 8)  # a little dome
	Kit.cylinder(g, Vector3(0, 7.1, 0), 0.04, 0.6, "gold", false, 4)  # its cross-staff


static func _gothic(g: Node3D, solid: bool) -> void:
	_posts(g, 0.8, 4.6, "stone", solid, 1.5)
	Kit.arch(g, Vector3(1.1, 4.6, 0), 2.2, 90.0, 180.0, 4, Vector3(0.6, 0.5, 0.8), ["stone"])  # the left half
	Kit.arch(g, Vector3(-1.1, 4.6, 0), 2.2, 0.0, 90.0, 4, Vector3(0.6, 0.5, 0.8), ["stone"])  # meets it in a point
	for side in [-2.2, 2.2]:  # buttresses, each crowned with a pinnacle
		Kit.box(g, Vector3(side, 2.8, -0.2), Vector3(0.5, 5.6, 1.2), "stone", false)
		Kit.cylinder(g, Vector3(side, 5.6, -0.2), 0.3, 1.4, "stone", false, 4, 0.0)
	Kit.cylinder(g, Vector3(0, 7.2, 0.3), 0.55, 0.15, "glow", false, 8).rotation = Vector3(PI / 2.0, 0, 0)  # rose


static func _moorish(g: Node3D, solid: bool) -> void:
	_posts(g, 0.8, 3.9, "plaster", solid, 1.5)
	Kit.arch(g, Vector3(0, 4.3, 0), 1.1, -30.0, 210.0, 11, Vector3(0.45, 0.5, 0.8), [RED, "plaster"])  # horseshoe
	Kit.box(g, Vector3(0, 6.4, 0.1), Vector3(3.9, 0.3, 0.7), TILE, false)  # the alfiz frame round it
	for side in [-1.8, 1.8]:
		Kit.box(g, Vector3(side, 4.6, 0.1), Vector3(0.3, 3.8, 0.7), TILE, false)
	Kit.box(g, Vector3(0, 0.6, 0.4), Vector3(3.9, 0.4, 0.2), TILE, false)  # the tiled dado


static func _torii(g: Node3D, solid: bool) -> void:
	for side in [-1.5, 1.5]:
		Kit.cylinder(g, Vector3(side, 0.2, 0), 0.22, 5.2, RED, solid, 8)
		Kit.cylinder(g, Vector3(side, 0.0, 0), 0.3, 0.4, "#222222", false, 8)  # black feet
	Kit.box(g, Vector3(0, 4.4, 0), Vector3(3.8, 0.3, 0.3), RED, false)  # nuki, the tie beam
	Kit.box(g, Vector3(0, 5.3, 0), Vector3(4.4, 0.3, 0.45), RED, false)  # shimaki
	Kit.box(g, Vector3(0, 5.6, 0), Vector3(5.0, 0.3, 0.55), "#222222", false)  # kasagi, the black top
	for side in [-2.45, 2.45]:  # its upswept ends
		Kit.box(g, Vector3(side, 5.72, 0), Vector3(0.5, 0.3, 0.55), "#222222", false, Vector3(0, 0, 0.35 * signf(side)))
	Kit.box(g, Vector3(0, 4.85, 0.05), Vector3(0.5, 0.6, 0.1), "gold", false)  # the name plaque


static func _palladian(g: Node3D, solid: bool) -> void:
	for x in [-2.7, -1.35, 1.35, 2.7]:
		Kit.cylinder(g, Vector3(x, 0.2, 0), 0.18, 3.6, "plaster", solid, 8)
	Kit.box(g, Vector3(-2.0, 3.9, 0), Vector3(1.8, 0.3, 0.6), "plaster", false)  # the flat side lintels
	Kit.box(g, Vector3(2.0, 3.9, 0), Vector3(1.8, 0.3, 0.6), "plaster", false)
	Kit.arch(g, Vector3(0, 4.05, 0), 1.2, 0.0, 180.0, 7, Vector3(0.6, 0.35, 0.6), ["plaster"])
	Kit.box(g, Vector3(0, 5.8, 0), Vector3(6.2, 0.3, 0.8), "plaster", false)
	Kit.cylinder(g, Vector3(0, 5.95, -0.4), 3.2, 0.8, "plaster", false, 3).rotation = Vector3(PI / 2.0, 0, 0)


static func _modern(g: Node3D, solid: bool) -> void:
	_posts(g, 0.3, 5.0, CONCRETE, solid, 1.25)
	Kit.box(g, Vector3(0, 5.0, 0), Vector3(3.6, 0.3, 0.6), CONCRETE, false)
	Kit.box(g, Vector3(0, 5.4, 0.8), Vector3(4.6, 0.12, 2.2), CONCRETE, false)  # a thin cantilevered slab
	Kit.box(g, Vector3(1.9, 2.7, 0.8), Vector3(0.08, 5.4, 0.08), STEEL, false)  # one steel post
	Kit.box(g, Vector3(0, 0.3, 0.9), Vector3(4.6, 0.05, 2.0), STEEL, false)


static func _surreal(g: Node3D, solid: bool) -> void:
	var frame := Kit.group(g, Vector3.ZERO)
	frame.rotation.z = deg_to_rad(6.0)  # hung crooked
	_posts(frame, 0.35, 4.8, "voidstone", solid, 1.3)
	Kit.box(frame, Vector3(0, 4.9, 0), Vector3(3.0, 0.35, 0.5), "voidstone", false)
	Kit.box(frame, Vector3(0, 0.05, 0), Vector3(3.0, 0.1, 0.5), "voidstone", false)
	Kit.blob(g, Vector3(2.2, 3.2, 0.6), 0.35, "gold", Vector3(1.0, 1.4, 0.4), 6)  # a drip of melted gold
	Kit.box(g, Vector3(-2.3, 6.0, 0.3), Vector3(0.7, 0.9, 0.05), "daysky", false, Vector3(0, 0.4, 0.3))  # a stray pane of sky
