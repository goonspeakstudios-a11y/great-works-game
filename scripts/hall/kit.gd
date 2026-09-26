extends RefCounted
## Building blocks for the Greek places: low-poly shapes with pixel textures. Ground,
## cliffs, sea and a sunset sky; columns, temple ruins, olive and cypress trees, rocks;
## steles, gateways, marble busts, a writing desk, a fire, a far mountain.
## A "group" is a Node3D placed at a spot and turned by yaw; its front faces local +Z,
## so yaw = atan2(dx, dz) turns it to face a point (dx, dz) away.

const Tex := preload("res://scripts/hall/textures.gd")

## How round curved shapes are: 1 in Greece (chunky), higher in later, sharper worlds.
static var detail := 1


static func face_yaw(from: Vector3, to: Vector3) -> float:
	return atan2(to.x - from.x, to.z - from.z)


static func group(parent: Node3D, at: Vector3, yaw: float = 0.0) -> Node3D:
	var g := Node3D.new()
	g.position = at
	g.rotation.y = yaw
	parent.add_child(g)
	return g


static func mesh(parent: Node3D, m: Mesh, mat: String, at: Vector3, rot: Vector3 = Vector3.ZERO,
		scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Tex.material(mat)
	mi.position = at
	mi.rotation = rot
	mi.scale = scale
	parent.add_child(mi)
	return mi


static func solid(parent: Node3D, shape: Shape3D, at: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	body.position = at
	body.rotation = rot
	parent.add_child(body)


static func box(parent: Node3D, center: Vector3, size: Vector3, mat: String, is_solid: bool = true,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := mesh(parent, bm, mat, center, rot)
	if is_solid:
		var s := BoxShape3D.new()
		s.size = size
		solid(parent, s, center, rot)
	return mi


## A cylinder standing on base (its bottom centre). top_radius < 0 means same as radius.
static func cylinder(parent: Node3D, base: Vector3, radius: float, height: float, mat: String,
		is_solid: bool = true, sides: int = 8, top_radius: float = -1.0) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.bottom_radius = radius
	cm.top_radius = radius if top_radius < 0.0 else top_radius
	cm.height = height
	cm.radial_segments = sides * detail
	cm.rings = 1
	var mi := mesh(parent, cm, mat, base + Vector3(0, height / 2.0, 0))
	if is_solid:
		var s := CylinderShape3D.new()
		s.radius = maxf(radius, cm.top_radius)
		s.height = height
		solid(parent, s, base + Vector3(0, height / 2.0, 0))
	return mi


static func blob(parent: Node3D, center: Vector3, radius: float, mat: String, squash: Vector3 = Vector3.ONE,
		sides: int = 6) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = sides * detail
	sm.rings = maxi(3, sides * detail / 2)
	return mesh(parent, sm, mat, center, Vector3.ZERO, squash)


# ---------- land, sea and sky ----------

## Evening light over the sea. "golden" (the places you visit, like memories): a warm low sun,
## a violet-to-amber sky. "dusk" (the Shore, the lonely present): the sun almost gone, a deeper
## sky, the first stars.
static func sunset(parent: Node3D, mood: String = "golden") -> DirectionalLight3D:
	var dusk := mood == "dusk"
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("1a2248") if dusk else Color("2a3a6e")
	sky_mat.sky_horizon_color = Color("d8845e") if dusk else Color("f0aa74")
	sky_mat.sky_curve = 0.09 if dusk else 0.12
	sky_mat.ground_horizon_color = Color("a0604c") if dusk else Color("b8765a")
	sky_mat.ground_bottom_color = Color("141a28") if dusk else Color("1a2230")
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("686c8e") if dusk else Color("7c7a92")
	env.ambient_light_energy = 0.6 if dusk else 0.65
	env.fog_enabled = true
	env.fog_light_color = Color("8e7488") if dusk else Color("c89a84")
	env.fog_density = 0.0022
	env.fog_sky_affect = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-4.0 if dusk else -9.0, -100.0, 0.0)  # low in the west, shining east
	sun.light_color = Color("ff9a6a") if dusk else Color("ffc896")
	sun.light_energy = 0.8 if dusk else 1.15
	if dusk:
		stars(parent)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	parent.add_child(sun)
	return sun


## The first stars, high in the east away from the last of the sun.
static func stars(parent: Node3D) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := BoxMesh.new()
	q.size = Vector3(3.2, 3.2, 3.2)
	mm.mesh = q
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	mm.instance_count = 110
	for i in mm.instance_count:
		var az := rng.randf_range(-PI * 0.35, PI * 1.35)  # everywhere but the sunset
		var el := rng.randf_range(0.28, 1.35)
		var d := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)) * 760.0
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.6, 1.3)), d))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.96, 0.88)
	mat.disable_fog = true
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


static func sea(parent: Node3D, y: float) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(1600, 1600)
	mesh(parent, pm, "sea", Vector3(0, y, 0))


## A round clifftop to walk on, with rocky tiers below it and a low wall round the edge.
static func plateau(parent: Node3D, radius: float, top: String = "earth", wall: bool = true) -> void:
	cylinder(parent, Vector3(0, -40, 0), radius, 40.0, "rock", true, 14)
	cylinder(parent, Vector3(0, -0.05, 0), radius - 0.4, 0.1, top, false, 14)
	cylinder(parent, Vector3(0, -46, 0), radius + 7.0, 40.0, "rock", false, 11)
	cylinder(parent, Vector3(0, -56, 0), radius + 16.0, 40.0, "rock", false, 9)
	if wall:
		var n := 28
		for i in n:
			var a := TAU * i / n
			var at := Vector3(cos(a), 0, sin(a)) * (radius - 1.0)
			var seg := 2.0 * PI * (radius - 1.0) / n + 0.1
			box(parent, at + Vector3(0, 0.45, 0), Vector3(seg, 0.9, 0.5), "stone", true, Vector3(0, -a + PI / 2.0, 0))


static func mountain(parent: Node3D, at: Vector3, radius: float, height: float, smoke: bool) -> void:
	cylinder(parent, at, radius, height, "rock", false, 10, radius * 0.08)
	cylinder(parent, at + Vector3(0, height * 0.78, 0), radius * 0.3, height * 0.22, "snow", false, 10, radius * 0.08)
	if smoke:
		var p := CPUParticles3D.new()
		p.position = at + Vector3(0, height + 2.0, 0)
		p.amount = 14
		p.lifetime = 14.0
		p.preprocess = 14.0
		var q := QuadMesh.new()
		q.size = Vector2(14, 14)
		p.mesh = q
		p.material_override = Tex.material("smoke")
		p.direction = Vector3(0.6, 1, 0)
		p.spread = 12.0
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 3.5
		p.gravity = Vector3.ZERO
		p.scale_amount_min = 1.0
		p.scale_amount_max = 2.5
		parent.add_child(p)


# ---------- architecture ----------

static func column(parent: Node3D, base: Vector3, height: float = 4.0, broken: bool = false) -> void:
	box(parent, base + Vector3(0, 0.12, 0), Vector3(0.9, 0.24, 0.9), "marble")
	var shaft := height * (0.45 if broken else 1.0) - 0.6
	cylinder(parent, base + Vector3(0, 0.24, 0), 0.32, shaft, "marble", true, 8, 0.28)
	if not broken:
		box(parent, base + Vector3(0, 0.24 + shaft + 0.18, 0), Vector3(0.95, 0.36, 0.95), "marble", false)


static func fallen_column(parent: Node3D, at: Vector3, yaw: float, length: float = 2.6) -> void:
	var g := group(parent, at, yaw)
	for k in 3:
		var drum := CylinderMesh.new()
		drum.top_radius = 0.3
		drum.bottom_radius = 0.3
		drum.height = length / 3.0 - 0.08
		drum.radial_segments = 8 * detail
		mesh(g, drum, "marble", Vector3(0, 0.3, (k - 1) * length / 3.0), Vector3(PI / 2.0, 0, 0.2 * k))
	var s := BoxShape3D.new()
	s.size = Vector3(0.6, 0.6, length)
	solid(g, s, Vector3(0, 0.3, 0))


## Columns of the Shore's temple that lie broken until books are mastered, in the order
## they stand up again.
const BROKEN_COLUMNS := [2, 5, 7, 9]


## A temple left standing in pieces: three steps, a ring of columns, some broken or fallen.
## Each mastered book puts one broken column back up (restored = how many).
static func temple_ruin(parent: Node3D, at: Vector3, yaw: float, restored: int = 0) -> void:
	var g := group(parent, at, yaw)
	for k in 3:
		box(g, Vector3(0, 0.15 + k * 0.3, 0), Vector3(12.0 - k * 0.8, 0.3, 8.0 - k * 0.8), "marble")
	var top := Vector3(0, 0.9, 0)
	var broken: Array = BROKEN_COLUMNS.slice(mini(restored, BROKEN_COLUMNS.size()))
	var spots: Array = []
	for x in [-4.5, -2.7, -0.9, 0.9, 2.7, 4.5]:
		spots.append(Vector3(x, 0, -2.8))
		spots.append(Vector3(x, 0, 2.8))
	spots.append(Vector3(-4.5, 0, 0))
	spots.append(Vector3(4.5, 0, 0))
	for i in spots.size():
		column(g, top + spots[i], 4.2, i in broken)
	box(g, top + Vector3(-1.8, 4.3, -2.8), Vector3(6.4, 0.5, 0.9), "marble", false)
	box(g, top + Vector3(3.6, 4.3, 2.8), Vector3(2.8, 0.5, 0.9), "marble", false)
	fallen_column(g, Vector3(1.5, 0, 5.4), 1.2)
	fallen_column(g, Vector3(-6.8, 0, 1.0), 0.3)


## "Two vast and trunkless legs of stone": all that stands of a colossus, on its pedestal.
static func colossus_legs(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.9, 0), Vector3(4.6, 1.8, 3.2), "stone")
	box(g, Vector3(0, 1.95, 0), Vector3(4.9, 0.3, 3.5), "marble", false)
	for x in [-0.95, 0.95]:
		box(g, Vector3(x, 2.35, 0.35), Vector3(1.1, 0.5, 1.8), "marble", false)  # feet
		cylinder(g, Vector3(x, 2.1, 0.0), 0.6, 3.2, "marble", false, 8, 0.72)  # shins
		cylinder(g, Vector3(x, 5.3, 0.0), 0.72, 1.4, "marble", false, 8, 0.85)  # knees and thighs
		for k in 3:  # the broken top
			box(g, Vector3(x + (k - 1) * 0.3, 6.7 + (k % 2) * 0.25, 0.1 * k), Vector3(0.4, 0.5, 0.5), "marble", false,
				Vector3(0.4 * k, 0.7, 0.3))
	for p in [Vector3(-3.2, 0.3, 2.4), Vector3(2.8, 0.25, -2.6), Vector3(3.4, 0.4, 1.8)]:
		box(g, p, Vector3(0.9, 0.6, 0.7), "marble", true, Vector3(0.2, p.x, 0.3))


## A giant marble head lying on its side, half sunk in the earth.
static func fallen_head(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	var head := group(g, Vector3(0, 0.9, 0))
	head.rotation = Vector3(0.1, 0, 1.25)
	blob(head, Vector3.ZERO, 1.9, "marble", Vector3(1.0, 1.2, 1.05), 8)
	blob(head, Vector3(0, 0.95, -0.25), 1.8, "marble", Vector3(1.05, 0.7, 1.05), 8)
	blob(head, Vector3(0, -1.2, 0.55), 1.3, "marble", Vector3(1.0, 1.1, 0.8), 6)  # the beard
	box(head, Vector3(0, 0.05, 1.95), Vector3(0.45, 0.8, 0.45), "marble", false)  # the nose
	box(head, Vector3(-0.6, 0.45, 1.75), Vector3(0.7, 0.18, 0.3), "stone", false)
	box(head, Vector3(0.6, 0.45, 1.75), Vector3(0.7, 0.18, 0.3), "stone", false)
	var s := SphereShape3D.new()
	s.radius = 2.1
	solid(g, s, Vector3(0, 0.9, 0))


## A far headland across the sea with a ruined temple on it: the silhouette of what was.
static func far_ruin(parent: Node3D, at: Vector3, size: float) -> void:
	cylinder(parent, at + Vector3(0, -30, 0), 28.0 * size, 38.0, "rock", false, 7, 18.0 * size)
	var top := at + Vector3(0, 8.0, 0)
	box(parent, top + Vector3(0, 0.6, 0), Vector3(16, 1.2, 9) * size, "marble", false)
	for i in 6:
		var h := (7.0 if i % 3 != 1 else 3.5) * size
		cylinder(parent, top + Vector3((-6.0 + i * 2.4) * size, 1.2, 0), 0.7 * size, h, "marble", false, 6)
	box(parent, top + Vector3(-3.6 * size, 1.2 + 7.0 * size, 0), Vector3(8, 1.1, 2) * size, "marble", false)


## Where the Tower of the Reformed Man will rise: an empty foundation on a far island, and a
## faint beam of light. Tiers are added as whole worlds are mastered.
static func tower_site(parent: Node3D, at: Vector3) -> void:
	cylinder(parent, at + Vector3(0, -30, 0), 34.0, 38.0, "rock", false, 8, 26.0)
	var top := at + Vector3(0, 8.0, 0)
	for i in 16:
		var a := TAU * i / 16.0
		box(parent, top + Vector3(cos(a), 0, sin(a)) * 11.0 + Vector3(0, 1.0, 0), Vector3(4.4, 2.0, 1.6), "stone", false,
			Vector3(0, -a, 0))
	var q := QuadMesh.new()
	q.size = Vector2(9, 220)
	var beam := mesh(parent, q, "beam", top + Vector3(0, 110, 0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## An olive tree; returns its crown (branches and leaves), which the breeze can stir.
static func olive(parent: Node3D, at: Vector3, size: float = 1.0) -> Node3D:
	var g := group(parent, at, at.x * 1.7 + at.z)
	cylinder(g, Vector3.ZERO, 0.2 * size, 1.1 * size, "trunk", true, 6, 0.15 * size)
	var crown := group(g, Vector3(0, 1.0 * size, 0))
	mesh(crown, _cyl(0.14 * size, 1.0 * size), "trunk", Vector3(0.18, 0.45, 0) * size, Vector3(0, 0, -0.5))
	for p in [Vector3(0.5, 1.3, 0.1), Vector3(-0.4, 1.1, 0.3), Vector3(0.1, 1.6, -0.4), Vector3(0.7, 0.9, -0.5)]:
		blob(crown, p * size, 0.85 * size, "olive", Vector3(1.2, 0.75, 1.1))
	return crown


## A cypress; returns its green spire, which the breeze can stir.
static func cypress(parent: Node3D, at: Vector3, height: float = 7.0) -> Node3D:
	cylinder(parent, at, 0.16, 0.8, "trunk", true, 5)
	var spire := group(parent, at + Vector3(0, 0.6, 0))
	cylinder(spire, Vector3.ZERO, 0.8, height, "cypress", false, 6, 0.05)
	return spire


static func rock(parent: Node3D, at: Vector3, size: float) -> void:
	blob(parent, at + Vector3(0, size * 0.3, 0), size, "rock", Vector3(1.3, 0.7, 1.0), 5)
	var s := SphereShape3D.new()
	s.radius = size * 0.8
	solid(parent, s, at + Vector3(0, size * 0.3, 0))


## A standing stone with a bronze plaque; returns where a reader stands.
static func stele(parent: Node3D, at: Vector3, yaw: float) -> Vector3:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.1, 0), Vector3(1.0, 0.2, 0.5), "stone")
	box(g, Vector3(0, 1.0, 0), Vector3(0.75, 1.7, 0.22), "marble")
	box(g, Vector3(0, 1.2, 0.12), Vector3(0.5, 0.36, 0.03), "plaque", false)
	return g.to_global(Vector3(0, 0, 1.1)) if g.is_inside_tree() else at + Vector3(sin(yaw), 0, cos(yaw)) * 1.1


## A stone gateway. Open ones glow with the light of the place beyond; a mastered one
## also burns with a flame on top.
static func gateway(parent: Node3D, at: Vector3, yaw: float, open: bool, mastered: bool = false) -> OmniLight3D:
	var g := group(parent, at, yaw)
	for x in [-1.5, 1.5]:
		box(g, Vector3(x, 1.8, 0), Vector3(0.6, 3.6, 0.6), "marble")
	box(g, Vector3(0, 3.85, 0), Vector3(3.9, 0.5, 0.75), "marble", false)
	box(g, Vector3(0, 0.08, 0), Vector3(3.8, 0.16, 1.2), "stone", false)
	if mastered:
		cylinder(g, Vector3(0, 4.1, 0), 0.35, 0.2, "bronze", false, 8, 0.5)
		for p in [Vector3(0, 4.5, 0), Vector3(0.12, 4.4, 0.08)]:
			blob(g, p, 0.2, "fire", Vector3(1.0, 1.7, 1.0), 5)
	if open:
		var q := QuadMesh.new()
		q.size = Vector2(2.4, 3.4)
		mesh(g, q, "glow", Vector3(0, 1.75, 0))
		var l := OmniLight3D.new()
		l.position = Vector3(0, 2.0, 1.0)
		l.light_color = Color("ffd49a")
		l.light_energy = 1.4
		l.omni_range = 7.0
		g.add_child(l)
		return l
	for s in [[Vector3(-0.5, 0.35, 0), 0.7], [Vector3(0.45, 0.3, 0.1), 0.6], [Vector3(0.0, 0.9, -0.05), 0.5]]:
		box(g, s[0], Vector3(s[1], s[1], s[1]), "stone", true, Vector3(0.3, s[1] * 2.0, 0.2))
	var bar := BoxShape3D.new()
	bar.size = Vector3(2.4, 3.4, 0.3)
	solid(g, bar, Vector3(0, 1.7, 0))
	return null


## A marble bust on a pedestal, shaped by a few settings (beard, bald).
static func bust(parent: Node3D, at: Vector3, yaw: float, look: Dictionary) -> void:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.55, 0), Vector3(0.6, 1.1, 0.6), "marble")
	box(g, Vector3(0, 1.13, 0), Vector3(0.72, 0.06, 0.72), "marble", false)
	blob(g, Vector3(0, 1.36, 0), 0.34, "marble", Vector3(1.4, 0.6, 0.85), 8)
	mesh(g, _cyl(0.1, 0.24), "marble", Vector3(0, 1.58, 0))
	blob(g, Vector3(0, 1.82, 0), 0.19, "marble", Vector3(1.0, 1.2, 1.1), 8)
	if not look.get("bald", false):
		blob(g, Vector3(0, 1.93, -0.03), 0.2, "marble", Vector3(1.05, 0.8, 1.1), 8)
	match look.get("beard", "none"):
		"long":
			blob(g, Vector3(0, 1.63, 0.1), 0.16, "marble", Vector3(1.0, 1.5, 0.7), 6)
		"short":
			blob(g, Vector3(0, 1.7, 0.1), 0.14, "marble", Vector3(1.1, 0.8, 0.7), 6)
	box(g, Vector3(0, 1.8, 0.2), Vector3(0.05, 0.1, 0.06), "marble", false)


## A teacher sitting at a desk, facing the room: robe, arms on the desk, a head that can
## turn toward a visitor. Returns {"root", "head", "hand"} so the Hall can bring him to life.
static func teacher(parent: Node3D, at: Vector3, yaw: float, look: Dictionary) -> Dictionary:
	var robe := "#" + str(look.get("robe", "2e3a5a"))
	var skin := "#" + str(look.get("skin", "c49a78"))
	var hair := "#" + str(look.get("beard_color", look.get("hair_color", "d0ccc4")))
	var root := group(parent, at, yaw)
	box(root, Vector3(0, 0.25, -0.05), Vector3(0.45, 0.5, 0.45), "wood")
	box(root, Vector3(0, 0.6, 0.15), Vector3(0.5, 0.22, 0.55), robe, false)
	box(root, Vector3(0, 0.3, 0.4), Vector3(0.44, 0.52, 0.2), robe, false)
	cylinder(root, Vector3(0, 0.62, -0.02), 0.25, 0.62, robe, false, 8, 0.2)
	blob(root, Vector3(0, 1.28, 0), 0.28, robe, Vector3(1.35, 0.55, 0.8), 8)
	var hand: Node3D = group(root, Vector3.ZERO)
	for x in [-0.24, 0.24]:
		mesh(root, _cyl(0.08, 0.5), robe, Vector3(x, 1.08, 0.18), Vector3(-1.1, 0, 0))
	blob(root, Vector3(-0.2, 0.92, 0.42), 0.07, skin)
	blob(hand, Vector3(0.2, 0.92, 0.42), 0.07, skin)
	var head: Node3D = group(root, Vector3(0, 1.52, 0.02))
	blob(head, Vector3(0, 0.08, 0), 0.14, skin, Vector3(1.0, 1.15, 1.05), 8)
	blob(head, Vector3(0, 0.16, -0.04), 0.14, hair, Vector3(1.05, 0.75, 1.05), 8)
	if look.get("beard", "none") != "none":
		blob(head, Vector3(0, -0.06, 0.07), 0.12, hair, Vector3(1.0, 1.5 if look.get("beard") == "long" else 0.9, 0.7), 6)
	box(head, Vector3(0, 0.07, 0.14), Vector3(0.04, 0.07, 0.04), skin, false)
	var body := BoxShape3D.new()
	body.size = Vector3(0.6, 1.6, 0.9)
	solid(root, body, Vector3(0, 0.8, 0.15))
	return {"root": root, "head": head, "hand": hand}


## A shelf of scrolls for the wall behind a writer.
static func scroll_shelf(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	for y in [0.9, 1.5, 2.1]:
		box(g, Vector3(0, y, 0), Vector3(1.8, 0.06, 0.35), "wood", false)
		for k in 7:
			mesh(g, _cyl(0.06, 0.32), "parchment", Vector3(-0.72 + k * 0.24, y + 0.09, 0), Vector3(PI / 2.0, 0, 0))
	for x in [-0.92, 0.92]:
		box(g, Vector3(x, 1.25, 0), Vector3(0.06, 2.5, 0.35), "wood", false)


## Swallows circling over a spot. Returns their state for the Hall to fly them.
static func flock(parent: Node3D, center: Vector3, count: int, radius: float, height: float) -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 13 + center.z * 7) + count
	for i in count:
		var bird := Node3D.new()
		parent.add_child(bird)
		box(bird, Vector3.ZERO, Vector3(0.1, 0.07, 0.3), "#2a2630", false)
		var wings: Array = []
		for side in [-1.0, 1.0]:
			var w := group(bird, Vector3(0.05 * side, 0.02, 0.02))
			box(w, Vector3(0.22 * side, 0, 0), Vector3(0.42, 0.02, 0.14), "#2a2630", false)
			wings.append(w)
		out.append({"node": bird, "wings": wings, "center": center, "r": radius * rng.randf_range(0.5, 1.1),
			"h": height + rng.randf_range(-2.0, 2.5), "speed": rng.randf_range(0.35, 0.7) * (1 if i % 2 else -1),
			"angle": rng.randf() * TAU, "phase": rng.randf() * TAU})
	return out


## Your companion: a fat, warty toad, facing +Z. Returns {"root", "body", "throat"} so the
## Hall can make it hop along, breathe, and puff up.
static func toad(parent: Node) -> Dictionary:
	var root := Node3D.new()
	parent.add_child(root)
	var body := group(root, Vector3.ZERO)
	blob(body, Vector3(0, 0.17, 0), 0.24, "#7e8646", Vector3(1.25, 0.72, 1.2), 8)  # the fat back
	blob(body, Vector3(0, 0.12, 0.08), 0.2, "#b8ac78", Vector3(1.2, 0.55, 1.05), 8)  # pale belly
	for p in [Vector3(-0.14, 0.27, 0.0), Vector3(0.12, 0.29, -0.1), Vector3(0.02, 0.31, 0.1), Vector3(-0.05, 0.26, -0.16)]:
		blob(body, p, 0.035, "#56602e")  # warts
	for side in [-1.0, 1.0]:
		blob(body, Vector3(0.1 * side, 0.3, 0.2), 0.065, "#7e8646")  # eye bumps
		blob(body, Vector3(0.11 * side, 0.33, 0.24), 0.035, "#d8a830")  # gold eyes
		blob(body, Vector3(0.115 * side, 0.335, 0.265), 0.015, "#101008")
		blob(body, Vector3(0.24 * side, 0.06, 0.16), 0.07, "#62683a", Vector3(1.0, 0.5, 1.4))  # front feet
		blob(body, Vector3(0.26 * side, 0.08, -0.14), 0.1, "#62683a", Vector3(1.0, 0.6, 1.5))  # hind legs
	box(body, Vector3(0, 0.17, 0.28), Vector3(0.2, 0.012, 0.02), "#2a2a18", false)  # the wide mouth
	var throat := blob(body, Vector3(0, 0.12, 0.24), 0.07, "#c8bc88", Vector3(1.3, 0.8, 0.8))
	return {"root": root, "body": body, "throat": throat}


## Moths drifting around a lamp.
static func moths(parent: Node3D, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = 6
	p.lifetime = 3.0
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	p.mesh = q
	p.material_override = Tex.material("moth")
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.5
	p.gravity = Vector3.ZERO
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	parent.add_child(p)


## Fireflies blinking low over a patch of ground at dusk.
static func fireflies(parent: Node3D, center: Vector3, size: float) -> void:
	var p := CPUParticles3D.new()
	p.position = center + Vector3(0, 1.0, 0)
	p.amount = 18
	p.lifetime = 5.0
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	p.mesh = q
	p.material_override = Tex.material("firefly")
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size, 0.8, size)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.gravity = Vector3.ZERO
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.8, 1.0, 0.4, 0.0))
	ramp.set_color(1, Color(0.8, 1.0, 0.4, 0.0))
	ramp.add_point(0.3, Color(0.85, 1.0, 0.45, 1.0))
	ramp.add_point(0.55, Color(0.85, 1.0, 0.45, 0.1))
	ramp.add_point(0.75, Color(0.85, 1.0, 0.45, 0.9))
	p.color_ramp = ramp
	parent.add_child(p)


## A marble bench facing +Z of its group; returns where a sitter's feet go.
static func bench(parent: Node3D, at: Vector3, yaw: float) -> Vector3:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.46, 0), Vector3(1.9, 0.12, 0.55), "marble")
	for x in [-0.72, 0.72]:
		box(g, Vector3(x, 0.2, 0), Vector3(0.3, 0.4, 0.45), "marble", false)
	return at


## A writing desk with scrolls, an open scroll, an oil lamp and a stool.
static func desk(parent: Node3D, at: Vector3, yaw: float, with_stool: bool = true) -> OmniLight3D:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.78, 0), Vector3(1.7, 0.08, 0.85), "wood")
	for p in [Vector3(-0.75, 0.37, -0.35), Vector3(0.75, 0.37, -0.35), Vector3(-0.75, 0.37, 0.35), Vector3(0.75, 0.37, 0.35)]:
		box(g, p, Vector3(0.08, 0.74, 0.08), "wood", false)
	var body := BoxShape3D.new()
	body.size = Vector3(1.7, 0.85, 0.85)
	solid(g, body, Vector3(0, 0.42, 0))
	for k in 4:
		mesh(g, _cyl(0.05, 0.42), "parchment", Vector3(-0.55 + k * 0.12, 0.87, -0.2), Vector3(0, 0, PI / 2.0))
	box(g, Vector3(0.25, 0.83, 0.1), Vector3(0.55, 0.01, 0.34), "parchment", false)
	box(g, Vector3(0.62, 0.86, -0.2), Vector3(0.12, 0.08, 0.08), "bronze", false)
	if with_stool:
		box(g, Vector3(0, 0.25, 0.75), Vector3(0.45, 0.5, 0.45), "wood", false)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.62, 1.05, -0.2)
	lamp.light_color = Color("ffb060")
	lamp.light_energy = 0.9
	lamp.omni_range = 4.0
	g.add_child(lamp)
	return lamp


## A stone brazier with a fire that the Hall flickers.
static func brazier(parent: Node3D, at: Vector3) -> OmniLight3D:
	cylinder(parent, at, 0.5, 0.9, "stone", true, 8)
	cylinder(parent, at + Vector3(0, 0.9, 0), 0.4, 0.25, "bronze", false, 8, 0.65)
	for p in [Vector3(0, 1.3, 0), Vector3(0.15, 1.2, 0.1), Vector3(-0.12, 1.22, -0.08)]:
		blob(parent, at + p, 0.22, "fire", Vector3(1.0, 1.6, 1.0), 5)
	var embers := CPUParticles3D.new()
	embers.position = at + Vector3(0, 1.3, 0)
	embers.amount = 12
	embers.lifetime = 2.5
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	embers.mesh = q
	embers.material_override = Tex.material("fire")
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.initial_velocity_min = 0.6
	embers.initial_velocity_max = 1.2
	embers.gravity = Vector3(0.3, 0.1, 0)
	parent.add_child(embers)
	var l := OmniLight3D.new()
	l.position = at + Vector3(0, 1.8, 0)
	l.light_color = Color("ff9a48")
	l.light_energy = 2.0
	l.omni_range = 9.0
	parent.add_child(l)
	return l


## A framed picture or map hung facing +Z of its group.
static func board(parent: Node3D, at: Vector3, yaw: float, size: Vector2, tex: Texture2D) -> void:
	var g := group(parent, at, yaw)
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = 0.3
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	g.add_child(mi)
	for f in [[Vector3(0, size.y / 2.0 + 0.05, 0), Vector3(size.x + 0.2, 0.1, 0.08)],
			[Vector3(0, -size.y / 2.0 - 0.05, 0), Vector3(size.x + 0.2, 0.1, 0.08)],
			[Vector3(size.x / 2.0 + 0.05, 0, 0), Vector3(0.1, size.y + 0.2, 0.08)],
			[Vector3(-size.x / 2.0 - 0.05, 0, 0), Vector3(0.1, size.y + 0.2, 0.08)]]:
		box(g, f[0], f[1], "gold", false)


static func _cyl(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 6 * detail
	c.rings = 1
	return c
