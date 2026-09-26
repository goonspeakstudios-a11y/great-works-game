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
## The sky and light of a place: "golden" (late sun), "dusk" (the last light, first stars),
## "morning" (a clear bright day, the sun climbing in the east) or "ashen" (a place lost to the
## world: a low grey sky, a weak cold sun, thick haze).
const MOODS := {
	"golden": {"top": "2a3a6e", "horizon": "f0aa74", "curve": 0.12, "ground": "b8765a", "bottom": "1a2230",
		"ambient": "7c7a92", "ambient_energy": 0.65, "fog": "c89a84", "fog_density": 0.0022,
		"sun": [-9.0, -100.0], "sun_color": "ffc896", "sun_energy": 1.15, "stars": false},
	"dusk": {"top": "1a2248", "horizon": "d8845e", "curve": 0.09, "ground": "a0604c", "bottom": "141a28",
		"ambient": "686c8e", "ambient_energy": 0.6, "fog": "8e7488", "fog_density": 0.0022,
		"sun": [-4.0, -100.0], "sun_color": "ff9a6a", "sun_energy": 0.8, "stars": true},
	"morning": {"top": "2c5aa8", "horizon": "c8d8e8", "curve": 0.16, "ground": "a8b090", "bottom": "3a4a3a",
		"ambient": "8a94a0", "ambient_energy": 0.8, "fog": "d0dce8", "fog_density": 0.0011,
		"sun": [-38.0, 70.0], "sun_color": "fff4e0", "sun_energy": 1.3, "stars": false},
	"ashen": {"top": "3a3e4c", "horizon": "8c8a90", "curve": 0.1, "ground": "5c5a5a", "bottom": "1c1e24",
		"ambient": "6c7080", "ambient_energy": 0.6, "fog": "7e7e86", "fog_density": 0.0045,
		"sun": [-22.0, 60.0], "sun_color": "b8bccc", "sun_energy": 0.45, "stars": false},
}


## `saturation` below 1 drains the colour out of everything: a place fading from the world.
static func sunset(parent: Node3D, mood: String = "golden", saturation: float = 1.0) -> DirectionalLight3D:
	var m: Dictionary = MOODS.get(mood, MOODS["golden"])
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(m["top"])
	sky_mat.sky_horizon_color = Color(m["horizon"])
	sky_mat.sky_curve = m["curve"]
	sky_mat.ground_horizon_color = Color(m["ground"])
	sky_mat.ground_bottom_color = Color(m["bottom"])
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(m["ambient"])
	env.ambient_light_energy = m["ambient_energy"]
	env.fog_enabled = true
	env.fog_light_color = Color(m["fog"])
	env.fog_density = m["fog_density"]
	env.fog_sky_affect = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if saturation < 1.0:
		env.adjustment_enabled = true
		env.adjustment_saturation = saturation
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(m["sun"][0], m["sun"][1], 0.0)
	sun.light_color = Color(m["sun_color"])
	sun.light_energy = m["sun_energy"]
	if m["stars"]:
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
		var p := _drift(parent, at + Vector3(0, height + 2.0, 0), 14, 14.0, 14.0, "smoke", Vector3(0.6, 1, 0), 12.0, Vector2(2.0, 3.5))
		p.preprocess = 14.0
		p.scale_amount_min = 1.0
		p.scale_amount_max = 2.5


## The common ground of every drifting effect (smoke, moths, fireflies, embers): flat
## sprites launched along a direction with some spread, floating free of gravity.
static func _drift(parent: Node3D, at: Vector3, amount: int, lifetime: float, size: float, mat: String,
		direction: Vector3, spread: float, speed: Vector2) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = amount
	p.lifetime = lifetime
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	p.mesh = q
	p.material_override = Tex.material(mat)
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = Vector3.ZERO
	parent.add_child(p)
	return p


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
static func olive(parent: Node3D, at: Vector3, size: float = 1.0, alive: bool = true) -> Node3D:
	var g := group(parent, at, at.x * 1.7 + at.z)
	var wood := "trunk" if alive else "deadwood"
	cylinder(g, Vector3.ZERO, 0.2 * size, 1.1 * size, wood, true, 6, 0.15 * size)
	var crown := group(g, Vector3(0, 1.0 * size, 0))
	mesh(crown, _cyl(0.14 * size, 1.0 * size), wood, Vector3(0.18, 0.45, 0) * size, Vector3(0, 0, -0.5))
	if not alive:
		_bare(crown, size, [Vector3(0.5, 1.1, 0.1), Vector3(-0.4, 0.9, 0.3), Vector3(0.1, 1.4, -0.4), Vector3(0.6, 0.8, -0.5)])
		return crown
	for p in [Vector3(0.5, 1.3, 0.1), Vector3(-0.4, 1.1, 0.3), Vector3(0.1, 1.6, -0.4), Vector3(0.7, 0.9, -0.5)]:
		blob(crown, p * size, 0.85 * size, "olive", Vector3(1.2, 0.75, 1.1))
	return crown


## Bare dead branches reaching out to the given tips, each with a crooked twig.
static func _bare(crown: Node3D, size: float, tips: Array) -> void:
	for tip in tips:
		var d: Vector3 = tip * size
		mesh(crown, _cyl(0.045 * size, d.length()), "deadwood", d / 2.0, Quaternion(Vector3.UP, d.normalized()).get_euler())
		var off := Vector3(-d.z, 0.5 * size, d.x).normalized() * 0.5 * size
		mesh(crown, _cyl(0.025 * size, off.length()), "deadwood", d * 0.6 + off / 2.0, Quaternion(Vector3.UP, off.normalized()).get_euler())


## A cypress; returns its green spire (or, dead, a thin brown one), which the breeze can stir.
static func cypress(parent: Node3D, at: Vector3, height: float = 7.0, alive: bool = true) -> Node3D:
	cylinder(parent, at, 0.16, 0.8, "trunk" if alive else "deadwood", true, 5)
	var spire := group(parent, at + Vector3(0, 0.6, 0))
	if alive:
		cylinder(spire, Vector3.ZERO, 0.8, height, "cypress", false, 6, 0.05)
	else:
		cylinder(spire, Vector3.ZERO, 0.45, height * 0.8, "withered", false, 5, 0.03)
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
	box(root, Vector3(0, 0.25, -0.05), Vector3(0.45, 0.5, 0.45), "wood").set_meta("keep", true)  # his chair stays a chair when he is a shade
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


## The household's copyist: a woman on a stool in a long cream stola with a shawl, her hair
## in a bun, a wax tablet in her lap and a stylus in her writing hand. Faces +Z of its group.
## Returns {"root", "head", "hand"} like the teacher, so the Hall can bring her to life too.
static func scribe(parent: Node3D, at: Vector3, yaw: float) -> Dictionary:
	var stola := "#e8e0d0"
	var shawl := "#8a5a6a"
	var skin := "#d4a888"
	var hair := "#3a2418"
	var root := group(parent, at, yaw)
	box(root, Vector3(0, 0.22, -0.05), Vector3(0.4, 0.45, 0.4), "wood")  # the stool
	box(root, Vector3(0, 0.56, 0.15), Vector3(0.46, 0.2, 0.55), stola, false)  # lap
	box(root, Vector3(0, 0.28, 0.4), Vector3(0.42, 0.52, 0.2), stola, false)  # the skirt falls to the floor
	cylinder(root, Vector3(0, 0.6, -0.02), 0.21, 0.6, stola, false, 8, 0.17)
	blob(root, Vector3(0, 1.22, 0), 0.24, shawl, Vector3(1.35, 0.5, 0.85), 8)
	var hand: Node3D = group(root, Vector3.ZERO)
	for x in [-0.2, 0.2]:
		mesh(root, _cyl(0.065, 0.46), stola, Vector3(x, 1.04, 0.16), Vector3(-1.15, 0, 0))
	blob(root, Vector3(-0.17, 0.9, 0.38), 0.06, skin)
	blob(hand, Vector3(0.17, 0.92, 0.38), 0.06, skin)
	box(root, Vector3(-0.02, 0.9, 0.34), Vector3(0.3, 0.02, 0.22), "#4a3420", false, Vector3(-0.5, 0, 0))  # the wax tablet
	box(root, Vector3(-0.02, 0.912, 0.34), Vector3(0.24, 0.006, 0.16), "#1e1c14", false, Vector3(-0.5, 0, 0))
	mesh(hand, _cyl(0.008, 0.16), "bronze", Vector3(0.17, 0.97, 0.4), Vector3(-0.9, 0, 0.4))  # the stylus
	var head: Node3D = group(root, Vector3(0, 1.46, 0.02))
	blob(head, Vector3(0, 0.08, 0), 0.13, skin, Vector3(0.95, 1.15, 1.0), 8)
	blob(head, Vector3(0, 0.15, -0.03), 0.13, hair, Vector3(1.05, 0.8, 1.05), 8)
	blob(head, Vector3(0, 0.12, -0.13), 0.08, hair)  # the bun
	box(head, Vector3(0, 0.07, 0.13), Vector3(0.035, 0.06, 0.035), skin, false)
	var body := BoxShape3D.new()
	body.size = Vector3(0.6, 1.5, 0.9)
	solid(root, body, Vector3(0, 0.75, 0.15))
	return {"root": root, "head": head, "hand": hand}


## A wooden bed with a mattress, a dark wool blanket and a pillow; long side along X.
static func bed(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	g.set_meta("prop", "bed")
	box(g, Vector3(0, 0.34, 0), Vector3(2.0, 0.12, 0.95), "wood", false)
	for p in [Vector3(-0.92, 0.15, -0.4), Vector3(0.92, 0.15, -0.4), Vector3(-0.92, 0.15, 0.4), Vector3(0.92, 0.15, 0.4)]:
		box(g, p, Vector3(0.08, 0.3, 0.08), "wood", false)
	box(g, Vector3(0, 0.47, 0), Vector3(1.9, 0.14, 0.85), "#cfc4a8", false)
	box(g, Vector3(-0.3, 0.57, 0), Vector3(1.1, 0.06, 0.87), "#6a2e34", false)
	blob(g, Vector3(0.75, 0.58, 0), 0.12, "#e0d8c4", Vector3(1.6, 0.5, 1.1), 6)
	var body := BoxShape3D.new()
	body.size = Vector3(2.0, 0.6, 0.95)
	solid(g, body, Vector3(0, 0.3, 0))


## A hearth on the floor: a ring of stones, a fire, embers and smoke, and firewood beside
## it. Returns the firelight for the Hall to flicker (cold: grey ash and charred ends, no light).
static func hearth(parent: Node3D, at: Vector3, lit: bool = true) -> OmniLight3D:
	var g := group(parent, at)
	g.set_meta("prop", "hearth")
	cylinder(g, Vector3.ZERO, 0.6, 0.22, "stone", false, 8, 0.55)
	cylinder(g, Vector3(0, 0.22, 0), 0.4, 0.02, "dark", false, 8)
	for k in 3:
		mesh(g, _cyl(0.06, 0.5), "wood", Vector3(0.85, 0.06 + k * 0.1, -0.2 + k * 0.05), Vector3(PI / 2.0, 0, 0.2 * k))
	var body := CylinderShape3D.new()
	body.radius = 0.6
	body.height = 0.4
	solid(g, body, Vector3(0, 0.2, 0))
	if not lit:
		blob(g, Vector3(0, 0.24, 0), 0.3, "ashbed", Vector3(1.0, 0.25, 1.0), 6)
		for k in 2:
			mesh(g, _cyl(0.05, 0.4), "dark", Vector3(-0.1 + k * 0.2, 0.28, 0), Vector3(PI / 2.0, 0, 0.6 * k))
		return null
	for p in [Vector3(0, 0.36, 0), Vector3(0.12, 0.3, 0.08), Vector3(-0.1, 0.32, -0.06)]:
		blob(g, p, 0.16, "fire", Vector3(1.0, 1.5, 1.0), 5)
	var embers := _drift(g, Vector3(0, 0.4, 0), 10, 2.0, 0.05, "fire", Vector3.UP, 20.0, Vector2(0.5, 1.0))
	embers.gravity = Vector3(0, 0.2, 0)
	var smoke := _drift(g, Vector3(0, 0.6, 0), 5, 3.5, 0.6, "smoke", Vector3.UP, 8.0, Vector2(0.4, 0.7))
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.4
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.9, 0)
	l.light_color = Color("ff9a48")
	l.light_energy = 1.6
	l.omni_range = 7.0
	g.add_child(l)
	return l


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
	var p := _drift(parent, at, 6, 3.0, 0.05, "moth", Vector3.UP, 180.0, Vector2(0.2, 0.5))
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0


## Fireflies blinking low over a patch of ground at dusk.
static func fireflies(parent: Node3D, center: Vector3, size: float) -> void:
	var p := _drift(parent, center + Vector3(0, 1.0, 0), 18, 5.0, 0.07, "firefly", Vector3.UP, 180.0, Vector2(0.05, 0.2))
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size, 0.8, size)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.8, 1.0, 0.4, 0.0))
	ramp.set_color(1, Color(0.8, 1.0, 0.4, 0.0))
	ramp.add_point(0.3, Color(0.85, 1.0, 0.45, 1.0))
	ramp.add_point(0.55, Color(0.85, 1.0, 0.45, 0.1))
	ramp.add_point(0.75, Color(0.85, 1.0, 0.45, 0.9))
	p.color_ramp = ramp


# ---------- lost to the world ----------

## Grey ash drifting down over a lost place.
static func ash(parent: Node3D, center: Vector3, size: float) -> void:
	var p := _drift(parent, center + Vector3(0, 9.0, 0), 70, 10.0, 0.06, "ash", Vector3.DOWN, 25.0, Vector2(0.5, 1.0))
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size, 1.0, size)
	p.preprocess = 10.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0


## A shade: the person under `node` turns pale, cold and half see-through (things marked "keep",
## like his chair, stay as they are). The more of his place is restored, the more solid he
## becomes (alpha).
static func shade(node: Node, alpha: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.78, 0.86, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.35, 0.42, 0.55)
	m.emission_energy_multiplier = 0.5
	m.roughness = 1.0
	for c in node.find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("keep"):
			continue
		(c as MeshInstance3D).material_override = m
		(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- Athens: the Lyceum ----------

## A plane tree: tall pale trunk, a broad light-green crown (dead: bare grey branches).
## Returns the crown for the breeze.
static func plane_tree(parent: Node3D, at: Vector3, size: float = 1.0, alive: bool = true) -> Node3D:
	var g := group(parent, at, at.x * 1.3 + at.z * 0.7)
	var bark := "bark" if alive else "deadwood"
	cylinder(g, Vector3.ZERO, 0.34 * size, 4.6 * size, bark, true, 7, 0.26 * size)
	for a in [0.6, 2.7, 4.6]:
		box(g, Vector3(cos(a) * 0.9 * size, 4.4 * size, sin(a) * 0.9 * size), Vector3(0.22, 1.6, 0.22) * size, bark, false, Vector3(0.3 * sin(a), 0, 0.3 * cos(a)))
	var crown := group(g, Vector3(0, 5.2 * size, 0))
	if not alive:
		_bare(crown, size, [Vector3(2.2, 1.6, 0.4), Vector3(-1.8, 1.9, -0.9), Vector3(0.3, 2.6, 1.6), Vector3(-0.6, 1.2, 2.2), Vector3(1.2, 2.2, -1.9)])
		return crown
	blob(crown, Vector3.ZERO, 2.6 * size, "plane", Vector3(1.25, 0.8, 1.15), 7)
	blob(crown, Vector3(1.4 * size, 0.7 * size, 0.6 * size), 1.7 * size, "plane", Vector3(1.1, 0.8, 1.0), 6)
	blob(crown, Vector3(-1.3 * size, 0.5 * size, -0.9 * size), 1.6 * size, "plane", Vector3(1.0, 0.75, 1.1), 6)
	blob(crown, Vector3(0.2 * size, 1.4 * size, 0.0), 1.5 * size, "plane", Vector3(1.1, 0.7, 1.1), 6)
	return crown


## A stoa, the covered walkway: a back wall, a floor, a row of columns along the open side
## (+Z of its group) and a roof. Runs along X for `length`. In ruin (whole = false) most of the
## roof is down, the wall has fallen low in places, and two columns in three are broken stumps
## or lie fallen on the grass.
static func stoa(parent: Node3D, at: Vector3, yaw: float, length: float, depth: float, whole: bool = true) -> Node3D:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.06, 0), Vector3(length + 0.6, 0.12, depth + 0.6), "paving", false)
	for x in [-length / 2.0, length / 2.0]:
		box(g, Vector3(x, 2.1, -0.4), Vector3(0.4, 4.2, depth - 0.8), "stone")
	if whole:
		box(g, Vector3(0, 2.1, -depth / 2.0), Vector3(length + 0.6, 4.2, 0.4), "stone")
		box(g, Vector3(0, 4.45, 0), Vector3(length + 1.2, 0.3, depth + 1.0), "roof", false)
		box(g, Vector3(0, 4.15, depth / 2.0 - 0.5), Vector3(length + 0.6, 0.3, 0.7), "marble", false)  # the beam over the columns
	else:  # in ruin: the wall has fallen low in two sections, the roof stands over only two
		const SECTIONS := 6
		var seg := (length + 0.6) / SECTIONS
		for i in SECTIONS:
			var x := -(length + 0.6) / 2.0 + seg * (i + 0.5)
			var wall_h := 1.6 + 0.5 * (i % 2) if i in [1, 2] else 4.2
			box(g, Vector3(x, wall_h / 2.0, -depth / 2.0), Vector3(seg, wall_h, 0.4), "stone")
			if i in [0, 3]:
				box(g, Vector3(x, 4.45, 0), Vector3(seg, 0.3, depth + 1.0), "roof", false)
				box(g, Vector3(x, 4.15, depth / 2.0 - 0.5), Vector3(seg, 0.3, 0.7), "marble", false)
		# a slab of the fallen roof across the back of the walkway, where the fifth section's roof was
		box(g, Vector3(7.0, 0.4, -depth / 2.0 + 1.0), Vector3(2.8, 0.3, 1.4), "roof", false, Vector3(0.12, 0.2, 0.3))
	var n := int(length / 3.0)
	for k in n + 1:
		var cx := -length / 2.0 + k * (length / n)
		var cz := depth / 2.0 - 0.5
		if whole or k % 3 == 0:
			column(g, Vector3(cx, 0.12, cz), 4.0)
		elif k % 3 == 1:
			column(g, Vector3(cx, 0.12, cz), 4.0, true)
		else:  # fallen outward onto the grass
			box(g, Vector3(cx, 0.24, cz), Vector3(0.9, 0.24, 0.9), "marble")
			fallen_column(g, Vector3(cx + 0.3, 0, cz + 1.5), 0.25, 2.8)
	return g


## The Ilissos: a stream in a shallow bed with rocky banks, from one point to another (dry,
## a cracked bed of stones, until it is restored).
static func stream(parent: Node3D, from: Vector3, to: Vector3, width: float, flowing: bool = true) -> void:
	var mid := (from + to) / 2.0
	var length := from.distance_to(to)
	var g := group(parent, Vector3(mid.x, 0, mid.z), atan2(to.x - from.x, to.z - from.z))
	box(g, Vector3(0, 0.03, 0), Vector3(width, 0.06, length), "water" if flowing else "drybed", false)
	for side in [-1.0, 1.0]:
		box(g, Vector3(side * (width / 2.0 + 0.35), 0.12, 0), Vector3(0.7, 0.24, length), "rock", false)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(length)
	for k in int(length / 4.0):
		blob(g, Vector3(rng.randf_range(-width * 0.4, width * 0.4), 0.02, -length / 2.0 + k * 4.0 + rng.randf_range(0, 3)),
			rng.randf_range(0.12, 0.28), "rock", Vector3(1.4, 0.6, 1.0), 5)


## A plank footbridge over the stream, crossing along X of its group.
static func bridge(parent: Node3D, at: Vector3, yaw: float, length: float) -> void:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.34, 0), Vector3(length, 0.12, 1.5), "wood")
	for z in [-0.8, 0.8]:
		box(g, Vector3(0, 0.85, z), Vector3(length, 0.06, 0.06), "wood", false)
		for x in [-length / 2.0 + 0.2, 0.0, length / 2.0 - 0.2]:
			box(g, Vector3(x, 0.62, z), Vector3(0.07, 0.55, 0.07), "wood", false)
	for x in [-length / 2.0 + 0.4, length / 2.0 - 0.4]:
		box(g, Vector3(x, 0.15, 0), Vector3(0.3, 0.3, 1.5), "stone", false)


## Athens itself, far off: the Acropolis rock with the Parthenon on top, and the city below.
static func acropolis(parent: Node3D, at: Vector3) -> void:
	cylinder(parent, at, 62.0, 38.0, "rock", false, 9, 46.0)
	var top := at + Vector3(0, 38.0, 0)
	box(parent, top + Vector3(0, 0.8, 0), Vector3(36.0, 1.6, 17.0), "marble", false)
	for k in 8:
		for z in [-7.0, 7.0]:
			cylinder(parent, top + Vector3(-15.75 + k * 4.5, 1.6, z), 1.0, 9.0, "marble", false, 6)
	for z in [-3.5, 0.0, 3.5]:
		for x in [-15.75, 15.75]:
			cylinder(parent, top + Vector3(x, 1.6, z), 1.0, 9.0, "marble", false, 6)
	box(parent, top + Vector3(0, 11.4, 0), Vector3(36.0, 1.6, 17.0), "marble", false)
	for side in [-1.0, 1.0]:
		box(parent, top + Vector3(0, 13.6, side * 4.6), Vector3(37.0, 0.5, 10.0), "roof", false, Vector3(-side * 0.42, 0, 0))
	for p in [Vector3(-22, 0, 6), Vector3(20, 0, -4), Vector3(-8, 0, -12)]:
		box(parent, top + p + Vector3(0, 3.0, 0), Vector3(9.0, 6.0, 6.0), "marble", false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 40:  # the houses of the city around the rock
		var a := rng.randf() * TAU
		var r := rng.randf_range(70.0, 130.0)
		box(parent, at + Vector3(cos(a) * r, 2.0, sin(a) * r), Vector3(rng.randf_range(5, 9), 4.0, rng.randf_range(5, 9)), "plaster", false, Vector3(0, a, 0))


## A standing teacher who can walk: legs that swing, a cloak, a hand raised to make a point,
## a head that turns. Faces +Z of its group. Returns {"root", "head", "hand", "legs"}.
static func walker(parent: Node3D, at: Vector3, yaw: float, look: Dictionary) -> Dictionary:
	var robe := "#" + str(look.get("robe", "8a6a4a"))
	var skin := "#" + str(look.get("skin", "c8a078"))
	var hair := "#" + str(look.get("beard_color", look.get("hair_color", "5a4a3a")))
	var root := group(parent, at, yaw)
	var legs: Array = []
	for side in [-1.0, 1.0]:
		var hip := group(root, Vector3(0.11 * side, 0.86, 0))
		mesh(hip, _cyl(0.085, 0.8), robe, Vector3(0, -0.4, 0))
		box(hip, Vector3(0, -0.83, 0.06), Vector3(0.14, 0.06, 0.26), "#6a4a34", false)  # sandal
		legs.append(hip)
	cylinder(root, Vector3(0, 0.8, 0), 0.25, 0.78, robe, false, 8, 0.2)
	blob(root, Vector3(0, 1.56, 0), 0.26, robe, Vector3(1.3, 0.55, 0.85), 8)
	box(root, Vector3(0.05, 1.3, 0.2), Vector3(0.44, 0.08, 0.12), robe, false, Vector3(0, 0, 0.55))  # the fold of the cloak
	mesh(root, _cyl(0.065, 0.55), robe, Vector3(-0.3, 1.2, 0), Vector3(0.15, 0, 0))
	blob(root, Vector3(-0.3, 0.9, 0.04), 0.06, skin)
	var hand: Node3D = group(root, Vector3.ZERO)
	mesh(hand, _cyl(0.065, 0.4), robe, Vector3(0.3, 1.32, 0.16), Vector3(-1.3, 0, 0))
	blob(hand, Vector3(0.3, 1.38, 0.36), 0.06, skin)
	var head: Node3D = group(root, Vector3(0, 1.72, 0.02))
	blob(head, Vector3(0, 0.08, 0), 0.14, skin, Vector3(1.0, 1.15, 1.05), 8)
	blob(head, Vector3(0, 0.17, -0.04), 0.14, hair, Vector3(1.05, 0.7, 1.05), 8)
	if look.get("beard", "none") != "none":
		blob(head, Vector3(0, -0.05, 0.07), 0.11, hair, Vector3(1.0, 1.4 if look.get("beard") == "long" else 0.9, 0.7), 6)
	box(head, Vector3(0, 0.07, 0.14), Vector3(0.04, 0.07, 0.04), skin, false)
	var body := BoxShape3D.new()
	body.size = Vector3(0.6, 1.9, 0.6)
	solid(root, body, Vector3(0, 0.95, 0))
	return {"root": root, "head": head, "hand": hand, "legs": legs}


## A Macedonian foot soldier of Philip and Alexander: bare legs and greaves, a red tunic under
## a linen cuirass, a bronze helmet with its peak and crest, the small shield with the sun on
## his left arm, and the sarissa (a pike near six metres long) upright in his right hand.
## Undead, he is bones in rotten linen, his bronze gone green, his pike snapped, a cold light
## in his empty eyes. Faces +Z. Returns his two legs, for marching.
static func soldier(parent: Node3D, at: Vector3, undead: bool = false) -> Array:
	var g := group(parent, at)
	var skin := "bone" if undead else "#c8a078"
	var metal := "verdigris" if undead else "bronze"
	var linen := "#8a8474" if undead else "#e8e0d0"
	var limb := 0.045 if undead else 0.075
	var legs: Array = []
	for side in [-1.0, 1.0]:
		var hip := group(g, Vector3(0.1 * side, 0.82, 0))
		mesh(hip, _cyl(limb, 0.78), skin, Vector3(0, -0.39, 0))
		box(hip, Vector3(0, -0.5, 0.0), Vector3(0.14, 0.4, 0.15), metal, false)  # greave
		box(hip, Vector3(0, -0.8, 0.06), Vector3(0.13, 0.05, 0.25), "#3a3028" if undead else "#6a4a34", false)  # sandal
		legs.append(hip)
	cylinder(g, Vector3(0, 0.72, 0), 0.22, 0.32, "#3e2a2a" if undead else "#8a2a2a", false, 8, 0.22)  # tunic
	cylinder(g, Vector3(0, 1.0, 0), 0.23, 0.5, linen, false, 8, 0.2)  # linen cuirass
	blob(g, Vector3(0, 1.52, 0), 0.24, linen, Vector3(1.25, 0.5, 0.85), 8)
	mesh(g, _cyl(limb * 0.8, 0.5), skin, Vector3(0.28, 1.2, 0))  # right arm down, on the sarissa
	mesh(g, _cyl(limb * 0.8, 0.45), skin, Vector3(-0.28, 1.25, 0.08), Vector3(-1.2, 0, 0))  # left arm behind the shield
	var shield := group(g, Vector3(-0.42, 1.15, 0.14), -PI / 2.0 + 0.5)  # faces left and a little forward
	var face := QuadMesh.new()
	face.size = Vector2(0.72, 0.72)
	mesh(shield, face, "shield_dead" if undead else "shield", Vector3.ZERO)
	mesh(shield, _cyl(0.35, 0.05), metal, Vector3(0, 0, -0.03), Vector3(PI / 2.0, 0, 0))
	if undead:  # the sarissa snapped off, its head green with age
		box(g, Vector3(0.38, 1.75, 0.05), Vector3(0.04, 3.4, 0.04), "deadwood", false, Vector3(0, 0, -0.06))
		box(g, Vector3(0.48, 3.5, 0.05), Vector3(0.05, 0.3, 0.05), "verdigris", false, Vector3(0, 0, -0.06))
	else:
		box(g, Vector3(0.36, 2.6, 0.05), Vector3(0.04, 5.2, 0.04), "wood", false)  # the sarissa
		box(g, Vector3(0.36, 5.35, 0.05), Vector3(0.05, 0.35, 0.05), "bronze", false)
	var head := group(g, Vector3(0, 1.68, 0.02))
	blob(head, Vector3(0, 0.06, 0), 0.12 if undead else 0.13, skin, Vector3(1.0, 1.1, 1.0), 7)
	blob(head, Vector3(0, 0.2, -0.02), 0.145, metal, Vector3(1.05, 0.9, 1.05), 7)  # the helmet
	box(head, Vector3(0, 0.34, 0.05), Vector3(0.08, 0.14, 0.1), metal, false, Vector3(0.5, 0, 0))  # its forward peak
	box(head, Vector3(0, 0.32, -0.05), Vector3(0.03, 0.12, 0.3), "#3a2a2a" if undead else "#8a2a2a", false)  # the crest
	if undead:  # empty eye sockets with a cold light deep in them, and the grin of the skull
		for x in [-0.045, 0.045]:
			box(head, Vector3(x, 0.07, 0.112), Vector3(0.05, 0.04, 0.02), "dark", false)
			box(head, Vector3(x, 0.07, 0.124), Vector3(0.016, 0.016, 0.006), "soulfire", false)
		box(head, Vector3(0, -0.02, 0.108), Vector3(0.08, 0.02, 0.02), "dark", false)
	return legs


## A block of soldiers in rows and files, one metre apart, who march together as one node
## (the dead ones slower). Returns {"root", "legs", "leg", "speed", "step", "undead"}; give it
## a "path" and the Hall marches it.
static func squad(parent: Node3D, at: Vector3, rows: int, files: int, undead: bool = false) -> Dictionary:
	var root := group(parent, at)
	var legs: Array = []
	for r in rows:
		for f in files:
			legs.append_array(soldier(root, Vector3((f - (files - 1) / 2.0) * 1.0, 0, -r * 1.1), undead))
	return {"root": root, "legs": legs, "leg": 0, "speed": 0.8 if undead else 1.25, "step": 0.0, "undead": undead}


# ---------- the comforts of a lived-in house ----------

## A clay storage jar, leaning a little if asked.
static func amphora(parent: Node3D, at: Vector3, lean: float = 0.0) -> void:
	var g := group(parent, at, at.x + at.z)
	g.set_meta("prop", "amphora")
	g.rotation.z = lean
	cylinder(g, Vector3(0, 0.05, 0), 0.1, 0.12, "clay", false, 8, 0.2)  # foot
	cylinder(g, Vector3(0, 0.17, 0), 0.2, 0.42, "clay", false, 8, 0.24)  # belly
	cylinder(g, Vector3(0, 0.59, 0), 0.24, 0.22, "clay", false, 8, 0.11)  # shoulder
	cylinder(g, Vector3(0, 0.81, 0), 0.11, 0.16, "clay", false, 8, 0.14)  # neck and lip
	for side in [-1.0, 1.0]:
		box(g, Vector3(0.24 * side, 0.74, 0), Vector3(0.06, 0.22, 0.06), "clay", false, Vector3(0, 0, 0.35 * side))
	var body := CylinderShape3D.new()
	body.radius = 0.24
	body.height = 0.9
	solid(g, body, Vector3(0, 0.45, 0))


## A tall bronze lamp stand with a small flame; returns its light for the Hall to flicker
## (unlit: cold green bronze, no flame, no light).
static func lamp_stand(parent: Node3D, at: Vector3, lit: bool = true) -> OmniLight3D:
	var g := group(parent, at)
	g.set_meta("prop", "lamp")
	var metal := "bronze" if lit else "verdigris"
	cylinder(g, Vector3.ZERO, 0.16, 0.05, metal, false, 8)
	cylinder(g, Vector3(0, 0.05, 0), 0.03, 1.25, metal, false, 6)
	cylinder(g, Vector3(0, 1.3, 0), 0.05, 0.08, metal, false, 8, 0.12)  # the oil dish
	var body := CylinderShape3D.new()
	body.radius = 0.16
	body.height = 1.4
	solid(g, body, Vector3(0, 0.7, 0))
	if not lit:
		return null
	blob(g, Vector3(0, 1.44, 0), 0.05, "fire", Vector3(1.0, 1.7, 1.0), 5)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 1.6, 0)
	l.light_color = Color("ffb060")
	l.light_energy = 0.7
	l.omni_range = 4.0
	g.add_child(l)
	return l


## A low table laid with bread, a jug of wine and two cups.
static func table(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	g.set_meta("prop", "table")
	box(g, Vector3(0, 0.6, 0), Vector3(1.1, 0.06, 0.7), "wood", false)
	for p in [Vector3(-0.48, 0.29, -0.28), Vector3(0.48, 0.29, -0.28), Vector3(-0.48, 0.29, 0.28), Vector3(0.48, 0.29, 0.28)]:
		box(g, p, Vector3(0.06, 0.58, 0.06), "wood", false)
	var body := BoxShape3D.new()
	body.size = Vector3(1.1, 0.65, 0.7)
	solid(g, body, Vector3(0, 0.32, 0))
	blob(g, Vector3(-0.28, 0.68, 0.05), 0.12, "#c8a060", Vector3(1.3, 0.7, 1.0), 6)  # a round loaf
	blob(g, Vector3(-0.1, 0.66, -0.16), 0.07, "#b89050", Vector3(1.2, 0.6, 1.0), 5)  # a torn piece
	cylinder(g, Vector3(0.28, 0.63, -0.12), 0.09, 0.26, "clay", false, 8, 0.05)  # the jug
	cylinder(g, Vector3(0.28, 0.89, -0.12), 0.05, 0.05, "clay", false, 8, 0.06)
	for p in [Vector3(0.15, 0.63, 0.2), Vector3(0.42, 0.63, 0.18)]:
		cylinder(g, p, 0.045, 0.09, "clay", false, 8, 0.06)
		cylinder(g, p + Vector3(0, 0.07, 0), 0.04, 0.02, "#4a1e2c", false, 8)  # wine


## A woollen rug on the floor (a plane the size given, wearing the rug's own weave).
static func rug(parent: Node3D, at: Vector3, size: Vector2, yaw: float = 0.0) -> void:
	var g := group(parent, at, yaw)
	g.set_meta("prop", "rug")
	var pm := PlaneMesh.new()
	pm.size = size
	mesh(g, pm, "rug", Vector3(0, 0.025, 0))


## A lyre hung on a wall, facing +Z of its group.
static func lyre(parent: Node3D, at: Vector3, yaw: float) -> void:
	var g := group(parent, at, yaw)
	g.set_meta("prop", "lyre")
	blob(g, Vector3(0, -0.22, 0), 0.14, "wood", Vector3(1.2, 0.9, 0.5), 6)  # the tortoise-shell sound box
	for side in [-1.0, 1.0]:  # the two curving arms
		box(g, Vector3(0.14 * side, 0.02, 0), Vector3(0.04, 0.3, 0.04), "wood", false, Vector3(0, 0, -0.25 * side))
		box(g, Vector3(0.2 * side, 0.26, 0), Vector3(0.04, 0.2, 0.04), "wood", false, Vector3(0, 0, 0.3 * side))
	box(g, Vector3(0, 0.36, 0), Vector3(0.5, 0.04, 0.04), "wood", false)  # the crossbar
	for k in 7:
		box(g, Vector3(-0.15 + k * 0.05, 0.08, 0.02), Vector3(0.008, 0.55, 0.008), "#e8e0c8", false)


## A potted plant: a clay pot with a green head of leaves.
static func plant(parent: Node3D, at: Vector3, alive: bool = true) -> Node3D:
	var g := group(parent, at, at.x * 2.0 + at.z)
	g.set_meta("prop", "plant")
	cylinder(g, Vector3.ZERO, 0.16, 0.34, "clay", false, 8, 0.22)
	var crown := group(g, Vector3(0, 0.48, 0))
	var leaf := "olive" if alive else "withered"
	blob(crown, Vector3.ZERO, 0.24 if alive else 0.15, leaf, Vector3(1.0, 0.9, 1.0), 6)
	for k in (5 if alive else 3):
		var a := k * 1.26
		box(crown, Vector3(cos(a) * 0.22, 0.05 + (k % 2) * 0.06, sin(a) * 0.22), Vector3(0.22, 0.02, 0.07), leaf, false,
			Vector3(0.3 if alive else 0.9, -a, 0))
	var body := CylinderShape3D.new()
	body.radius = 0.24
	body.height = 0.8
	solid(g, body, Vector3(0, 0.4, 0))
	return crown


## A marble bench facing +Z of its group; returns where a sitter's feet go.
static func bench(parent: Node3D, at: Vector3, yaw: float) -> Vector3:
	var g := group(parent, at, yaw)
	box(g, Vector3(0, 0.46, 0), Vector3(1.9, 0.12, 0.55), "marble")
	for x in [-0.72, 0.72]:
		box(g, Vector3(x, 0.2, 0), Vector3(0.3, 0.4, 0.45), "marble", false)
	return at


## A writing desk with scrolls, an open scroll, an oil lamp and a stool.
static func desk(parent: Node3D, at: Vector3, yaw: float, with_stool: bool = true, lit: bool = true) -> OmniLight3D:
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
	if not lit:
		return null
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
	var embers := _drift(parent, at + Vector3(0, 1.3, 0), 12, 2.5, 0.06, "fire", Vector3.UP, 25.0, Vector2(0.6, 1.2))
	embers.gravity = Vector3(0.3, 0.1, 0)  # the draught carries them a little
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


# ---------- the Nexus ----------

## How see-through the ghost of the Tower is (0.14 to 0.22 reads well at 320x180).
const GHOST_ALPHA := 0.18


## The dark of the Nexus: no sky, horizon or sun, only a near-black background that far things
## fade into (the fog is the very same colour), faint cold starlight, and the colour drained to
## `saturation`. Returns the starlight. (Named the_void: "void" is a GDScript word.)
static func the_void(parent: Node3D, saturation: float) -> DirectionalLight3D:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("07070b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("50526a")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = saturation
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-70.0, 30.0, 0.0)
	light.light_color = Color("9aa0c0")
	light.light_energy = 0.4
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 60.0
	parent.add_child(light)
	return light


## A point `r` metres out at bearing `b` (degrees clockwise from north, north being -Z) and
## elevation `el` (degrees above the level).
static func sky_point(b: float, el: float, r: float) -> Vector3:
	var br := deg_to_rad(b)
	var er := deg_to_rad(el)
	return Vector3(cos(er) * sin(br), sin(er), -cos(er) * cos(br)) * r


## Specks of light far out in the void, all one MultiMesh: unlit, never fogged, no shadows.
static func _specks(parent: Node3D, mm: MultiMesh) -> MultiMeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func _cube_multimesh(count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	mm.mesh = cube
	mm.instance_count = count
	return mm


## Dead stars: `count` grey specks on a far sphere, above and below you alike. They never change.
static func void_stars(parent: Node3D, count: int, seed_value: int) -> MultiMeshInstance3D:
	var mm := _cube_multimesh(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var reach := sin(deg_to_rad(80.0))
	for i in count:
		var el := rad_to_deg(asin(rng.randf_range(-reach, reach)))  # spread evenly over the sphere
		var at := sky_point(rng.randf() * 360.0, el, 780.0)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(6.0, 10.0)), at))
		var v := rng.randf_range(0.9, 1.1)
		mm.set_instance_color(i, Color(0.541 * v, 0.557 * v, 0.612 * v))  # #8a8e9c, a little lighter or darker
	return _specks(parent, mm)


## Idea stars: one warm star for each idea understood (`lit` of the 800 places show), strewn round
## the sky by the golden angle. Place 0 hangs straight above the Tower as seen from Greece's door.
static func idea_stars(parent: Node3D, lit: int) -> MultiMeshInstance3D:
	const SLOTS := 800
	var mm := _cube_multimesh(SLOTS)
	for k in SLOTS:
		var at := sky_point(180.0 + 137.508 * k, 18.0 + 40.0 * fposmod(0.618034 * k, 1.0), 700.0)
		mm.set_instance_transform(k, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 10.0), at))
		mm.set_instance_color(k, Color("ffe2a8"))
	mm.visible_instance_count = clampi(lit, 0, SLOTS)
	return _specks(parent, mm)


## A faint cloud of colour far out in the void: a flat square turned to face the centre (not a
## billboard), see-through, never fogged.
static func nebula(parent: Node3D, at: Vector3, size: float, tint: Color) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.albedo_texture = Tex._cloud(int(absf(at.x) + absf(at.y) * 3.0 + absf(at.z) * 7.0))
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.35)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var out := at.normalized()
	mi.transform = Transform3D(Basis.looking_at(out, Vector3.UP if absf(out.y) < 0.95 else Vector3.BACK), at)
	parent.add_child(mi)
	return mi


## A slow river of faint light, from one point toward another. Along the way (the default),
## motes appear anywhere on it, in a box 2 m either side of its line; otherwise every mote sets
## out from `from` (a thread). They fade in and out, never fogged. `speed` is (slowest, fastest).
static func current(parent: Node3D, from: Vector3, to: Vector3, mat: String, amount: int, lifetime: float,
		speed: Vector2, along: bool = true, size: float = 2.5) -> CPUParticles3D:
	var length := from.distance_to(to)
	var x := (to - from) / maxf(length, 0.001)  # local X runs down the river
	var up := Vector3.UP if absf(x.y) < 0.95 else Vector3.RIGHT
	var z := x.cross(up).normalized()
	var p := CPUParticles3D.new()
	p.transform = Transform3D(Basis(x, z.cross(x), z), (from + to) / 2.0 if along else from)
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	p.mesh = q
	p.material_override = Tex.material(mat)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(length / 2.0, 2.0, 2.0) if along else Vector3(0.05, 0.08, 0.05)
	p.direction = Vector3(1, 0, 0)
	p.spread = 2.0 if along else 0.5
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = Vector3.ZERO
	if along:
		p.scale_amount_min = 1.0
		p.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color.WHITE)
	ramp.add_point(0.75, Color.WHITE)
	p.color_ramp = ramp
	parent.add_child(p)
	return p


## One entry for the Hall to drift: `node` bobs `bob` metres up and down over `period` seconds
## (from `phase`, in radians), tumbles steadily at `spin` radians a second, and swings its yaw
## `sway` radians on the same beat. "base" and "rot" keep where it started.
static func drifting(node: Node3D, bob: float, period: float, phase: float, spin: Vector3 = Vector3.ZERO,
		sway: float = 0.0) -> Dictionary:
	return {"node": node, "base": node.position, "rot": node.rotation, "bob": bob, "period": period, "phase": phase,
		"spin": spin, "sway": sway}


## An island of rock torn loose and hanging in the void: a flat top (its top at `at`, `sides`
## corners round, solid if asked), an upside-down cone of rock tapering `depth` metres down,
## lumps on its flanks and three spikes hanging below. Returns its group.
static func shard(parent: Node3D, at: Vector3, radius: float, depth: float, is_solid: bool, mat: String,
		seed_value: int, sides: int = 12) -> Node3D:
	var g := group(parent, at)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	cylinder(g, Vector3(0, -0.8, 0), radius, 0.8, mat, is_solid, sides)
	var cone := cylinder(g, Vector3(0, -depth, 0), radius * 0.156, depth - 0.8, mat, false, sides, radius - 0.5)
	cone.rotation.y = rng.randf() * TAU
	var inner := cylinder(g, Vector3(rng.randf_range(-0.15, 0.15) * radius, -depth * 0.8, rng.randf_range(-0.15, 0.15) * radius),
		radius * 0.1, depth * 0.8 - 0.8, mat, false, maxi(5, sides / 2), radius * 0.8)
	inner.rotation.y = rng.randf() * TAU
	for k in 3:  # hanging spikes
		var a := rng.randf() * TAU
		var off := Vector3(cos(a), 0, sin(a)) * radius * rng.randf_range(0.3, 0.45)
		var length := depth * rng.randf_range(0.32, 0.46)
		cylinder(g, off + Vector3(0, -0.8 - length, 0), radius * 0.012, length, mat, false, 5, radius * rng.randf_range(0.07, 0.1))
	for k in 5:  # lumps that break the cone's outline
		var a := rng.randf() * TAU
		var down := rng.randf_range(0.1, 0.55)
		var reach := lerpf(radius - 0.5, radius * 0.156, down) * 0.95
		blob(g, Vector3(cos(a) * reach, -0.8 - depth * down, sin(a) * reach), radius * rng.randf_range(0.1, 0.2), mat,
			Vector3(1.2, 0.8, 1.0), 5)
	return g


## A cloud of rock chunks far out in the void (1.5 to 4 m each, between `r_min` and `r_max`
## out and `y_min` to `y_max` high), all one MultiMesh so the whole set can turn as one.
static func debris(parent: Node3D, seed_value: int, count: int, r_min: float, r_max: float, y_min: float,
		y_max: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var lump := SphereMesh.new()
	lump.radius = 0.5
	lump.height = 1.0
	lump.radial_segments = 5
	lump.rings = 3
	mm.mesh = lump
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var a := rng.randf() * TAU
		var r := rng.randf_range(r_min, r_max)
		var size := rng.randf_range(1.5, 4.0)
		var basis := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		basis = basis.scaled(Vector3(size * rng.randf_range(0.8, 1.3), size * rng.randf_range(0.5, 0.9), size))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(cos(a) * r, rng.randf_range(y_min, y_max), sin(a) * r)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Tex.material("voidstone")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


## One invisible rail box (1.2 m tall, 0.3 thick) from a to b on the ground, as a shape of
## `body`; returns it as an x/z segment {"a", "b"}.
static func _rail(body: StaticBody3D, a: Vector3, b: Vector3) -> Dictionary:
	var d := b - a
	var s := BoxShape3D.new()
	s.size = Vector3(Vector2(d.x, d.z).length(), 1.2, 0.3)
	var cs := CollisionShape3D.new()
	cs.shape = s
	cs.position = (a + b) / 2.0 + Vector3(0, 0.6, 0)
	cs.rotation.y = atan2(-d.z, d.x)
	body.add_child(cs)
	return {"a": Vector2(a.x, a.z), "b": Vector2(b.x, b.z)}


static func _rail_body(parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Rails"
	parent.add_child(body)
	return body


## Invisible rails round the edge of a round island, so nobody walks off into the void: chords of
## 2 m or less at `radius` round `center`, leaving the gaps given as Vector2(bearing in degrees,
## width in metres). Returns the rails as x/z segments {"a", "b"}.
static func rim(parent: Node3D, center: Vector3, radius: float, gaps: Array = []) -> Array:
	var cuts: Array = []
	for gap in gaps:
		var half := asin(clampf((gap as Vector2).y / 2.0 / radius, 0.0, 1.0))
		var b := fposmod(deg_to_rad((gap as Vector2).x), TAU)
		cuts.append([b - half, b + half])
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var spans: Array = []
	if cuts.is_empty():
		spans.append([0.0, TAU])
	for i in cuts.size():
		var start: float = cuts[i][1]
		var end: float = cuts[(i + 1) % cuts.size()][0]
		while end <= start:
			end += TAU
		spans.append([start, end])
	var body := _rail_body(parent)
	var out: Array = []
	for arc in spans:
		var n := maxi(1, ceili((arc[1] - arc[0]) * radius / 1.9))
		for k in n:
			var a0: float = lerpf(arc[0], arc[1], float(k) / n)
			var a1: float = lerpf(arc[0], arc[1], float(k + 1) / n)
			out.append(_rail(body, center + Vector3(sin(a0), 0, -cos(a0)) * radius,
				center + Vector3(sin(a1), 0, -cos(a1)) * radius))
	return out


## Invisible rails down both sides of a way from `from` to `to`, `half_width` either side of its
## middle, in pieces of 2 m or less. Returns them as x/z segments {"a", "b"}.
static func rails(parent: Node3D, from: Vector3, to: Vector3, half_width: float) -> Array:
	var d := to - from
	d.y = 0.0
	var side := Vector3(-d.z, 0, d.x).normalized() * half_width
	var n := maxi(1, ceili(d.length() / 1.9))
	var body := _rail_body(parent)
	var out: Array = []
	for s in [side, -side]:
		for k in n:
			out.append(_rail(body, from + s + d * (float(k) / n), from + s + d * (float(k + 1) / n)))
	return out


## A stone way from one island to another, `width` wide, its walking surface at the height of
## `from` (one invisible solid box, reaching a little onto each island) with rails nobody sees
## down both sides. Broken: six cracked slabs, each askew, with chipped edges, and five loose slabs
## drifting beside and below. Whole: one smooth slab with low kerbs.
## Returns {"drift": [...], "rails": [...]}.
static func span(parent: Node3D, from: Vector3, to: Vector3, width: float, whole: bool) -> Dictionary:
	var length := from.distance_to(to)
	var dir := (to - from) / length
	var g := group(parent, (from + to) / 2.0, face_yaw(from, to))  # local +Z runs from -> to
	var walk := BoxShape3D.new()
	walk.size = Vector3(width, 0.3, length + 0.8)
	solid(g, walk, Vector3(0, -0.15, 0))
	var drift: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 97
	if whole:
		box(g, Vector3(0, -0.2, 0), Vector3(width, 0.4, length), "marble", false)
		for x in [-1.0, 1.0]:
			box(g, Vector3(x * (width / 2.0 - 0.15), 0.15, 0), Vector3(0.3, 0.3, length), "marble", false)
	else:
		for k in 6:
			var z := -length / 2.0 + 0.125 + 0.75 + k * 1.65
			var slab := group(g, Vector3(rng.randf_range(-0.12, 0.12), -0.19, z))
			slab.rotation = Vector3(rng.randf_range(-0.03, 0.03), deg_to_rad(rng.randf_range(-5.0, 5.0)), deg_to_rad(rng.randf_range(-3.0, 3.0)))
			var chip := rng.randf_range(0.3, 0.7)  # one corner broken away
			var side := -1.0 if k % 2 == 0 else 1.0
			box(slab, Vector3(-side * 0.25, 0, 0), Vector3(width - 0.5, 0.3, 1.5), "marble", false)
			box(slab, Vector3(side * (width / 2.0 - 0.25), 0, -chip / 2.0), Vector3(0.5, 0.3, 1.5 - chip), "marble", false)
			box(slab, Vector3(side * (width / 2.0 - 0.1), -0.02, 0.75 - chip / 2.0), Vector3(0.2, 0.2, chip * 0.6), "marble", false)
		for k in 5:  # loose slabs, fallen away beside and below
			var s := -1.0 if k % 2 == 0 else 1.0
			var at := Vector3(s * rng.randf_range(2.6, 4.5), rng.randf_range(-5.5, -1.2), -length / 2.0 + 1.0 + k * 2.0)
			var loose := group(g, at)
			loose.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
			box(loose, Vector3.ZERO, Vector3(rng.randf_range(1.1, 1.6), 0.3, rng.randf_range(1.0, 1.5)), "marble", false)
			drift.append(drifting(loose, rng.randf_range(0.2, 0.5), rng.randf_range(9.0, 16.0), rng.randf() * TAU,
				Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * deg_to_rad(rng.randf_range(2.0, 5.0))))
	var r := rails(parent, from - dir * 0.6, to + dir * 0.6, width / 2.0 + 0.15)
	return {"drift": drift, "rails": r}


## Where a way once ran out from the edge of the Heart to a later world's island: a slab jutting
## from the rim with a jagged end, then four loose slabs strung out toward the island, rising or
## sinking to its height. Nothing here is solid. Returns the drift entries of the loose slabs.
static func stub(parent: Node3D, bearing: float, frag_at: Vector3) -> Array:
	var out_dir := Vector3(sin(deg_to_rad(bearing)), 0, -cos(deg_to_rad(bearing)))
	var yaw := face_yaw(Vector3.ZERO, out_dir)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(bearing * 7.0) + 5
	var g := group(parent, out_dir * 17.5 + Vector3(0, -0.15, 0), yaw)
	box(g, Vector3.ZERO, Vector3(2.4, 0.3, 3.0), "voidstone", false)
	for k in 3:  # the jagged end
		var l := rng.randf_range(0.2, 0.8)
		box(g, Vector3(-0.8 + k * 0.8, -0.02, 1.5 + l / 2.0), Vector3(0.8, 0.26, l), "voidstone", false, Vector3(0.1 * k, 0, 0))
	var far := Vector2(frag_at.x, frag_at.z).length()
	var drift: Array = []
	for r in [21.0, 24.5, 28.0, 31.5]:
		var t := clampf((r - 17.5) / maxf(far - 17.5, 1.0), 0.0, 1.0)
		var slab := group(parent, out_dir * r + Vector3(0, lerpf(-0.15, frag_at.y, t), 0), yaw + rng.randf_range(-0.3, 0.3))
		slab.rotation.x = rng.randf_range(-0.25, 0.25)
		slab.rotation.z = rng.randf_range(-0.3, 0.3)
		box(slab, Vector3.ZERO, Vector3(rng.randf_range(1.8, 2.4), 0.3, rng.randf_range(1.6, 2.6)), "voidstone", false)
		drift.append(drifting(slab, rng.randf_range(0.3, 0.7), rng.randf_range(14.0, 24.0), rng.randf() * TAU,
			Vector3(0, 0, 0), deg_to_rad(rng.randf_range(2.0, 5.0))))
	return drift


## The ruin of a later world adrift far out in the void, on its own rock: "aqueduct", "ziggurat",
## "dome", "spire", "minaret", "pagoda" or "clock" (a clock tower). Plain shapes only: at this
## distance, through the fog, they are silhouettes. `size` scales it (1 = about 30 m tall on a
## rock of radius 20). Returns its group, for drifting.
static func far_wreck(parent: Node3D, at: Vector3, kind: String, size: float) -> Node3D:
	var g := group(parent, at, face_yaw(at, Vector3(0, at.y, 0)))
	g.scale = Vector3.ONE * size
	shard(g, Vector3.ZERO, 20.0, 34.0, false, "voidstone", int(at.x * 3.0 + at.z), 9)
	match kind:
		"aqueduct":  # arches on piers, the run broken off at one end
			for i in 5:
				if i == 3:
					box(g, Vector3(-12.0 + i * 6.0, 3.0, 0), Vector3(2.4, 6.0, 2.4), "#d8ccb0", false)
					continue
				box(g, Vector3(-12.0 + i * 6.0, 8.0, 0), Vector3(2.4, 16.0, 2.4), "#d8ccb0", false)
			box(g, Vector3(-6.0, 17.5, 0), Vector3(15.0, 3.0, 2.8), "#d8ccb0", false)
			box(g, Vector3(10.5, 17.0, 0), Vector3(5.0, 2.4, 2.8), "#d8ccb0", false, Vector3(0, 0, -0.25))
			for i in 2:
				box(g, Vector3(-9.0 + i * 6.0, 23.0, 0), Vector3(1.6, 8.0, 1.8), "#d8ccb0", false)
			box(g, Vector3(-6.0, 27.5, 0), Vector3(9.0, 1.4, 2.0), "#d8ccb0", false)
		"ziggurat":  # stepped terraces of mud brick, one corner fallen
			for i in 4:
				box(g, Vector3(0, 3.5 + i * 7.0, 0), Vector3(28.0 - i * 7.0, 7.0, 28.0 - i * 7.0), "#c8a878", false)
			box(g, Vector3(9.0, 1.5, 9.0), Vector3(10.0, 3.0, 10.0), "#8a4a34", false, Vector3(0.2, 0.4, 0.3))
			box(g, Vector3(0, 12.0, 11.0), Vector3(4.0, 24.0, 3.0), "#c8a878", false, Vector3(-0.5, 0, 0))  # the great stair
		"dome":  # a drum in bands of brick and stone, under a leaded dome split open
			for i in 4:
				cylinder(g, Vector3(0, i * 3.5, 0), 11.0, 3.5, "#8a4a34" if i % 2 == 0 else "#e0d4b8", false, 12)
			blob(g, Vector3(0, 14.0, 0), 11.0, "#6a6e74", Vector3(1.0, 0.7, 1.0), 10)
			box(g, Vector3(4.0, 19.0, 3.0), Vector3(5.0, 8.0, 5.0), "#07070b", false, Vector3(0.3, 0.5, 0.2))
			cylinder(g, Vector3(0, 21.0, 0), 1.2, 4.0, "#6a6e74", false, 6, 0.4)
		"spire":  # a Gothic tower whose spire snapped part way up
			box(g, Vector3(0, 11.0, 0), Vector3(9.0, 22.0, 9.0), "#8a8a86", false)
			cylinder(g, Vector3(0, 22.0, 0), 4.2, 12.0, "#6a6e74", false, 8, 1.2)
			box(g, Vector3(3.0, 35.0, 1.0), Vector3(1.4, 5.0, 1.4), "#6a6e74", false, Vector3(0.4, 0, 0.6))
			for p in [Vector3(-4.5, 22.0, -4.5), Vector3(4.5, 22.0, -4.5), Vector3(-4.5, 22.0, 4.5)]:
				cylinder(g, p, 0.8, 5.0, "#8a8a86", false, 4, 0.05)
		"minaret":  # a slender tower with a balcony, leaning
			var m := group(g, Vector3.ZERO)
			m.rotation.z = 0.12
			cylinder(m, Vector3.ZERO, 3.2, 4.0, "#e0d4b8", false, 8)
			cylinder(m, Vector3(0, 4.0, 0), 2.2, 20.0, "#e0d4b8", false, 8, 1.9)
			cylinder(m, Vector3(0, 23.0, 0), 3.0, 1.0, "#9a3a2a", false, 8)
			cylinder(m, Vector3(0, 24.0, 0), 1.5, 4.0, "#e0d4b8", false, 8)
			blob(m, Vector3(0, 28.5, 0), 1.6, "#2e6a70", Vector3(1.0, 1.3, 1.0), 6)
		"pagoda":  # five storeys under dark eaves, the top ones gone askew
			for i in 5:
				var w := 12.0 - i * 1.8
				var tier := group(g, Vector3(0, i * 6.0, 0))
				if i >= 3:
					tier.rotation = Vector3(0.08 * (i - 2), 0.3 * (i - 2), 0.1)
					tier.position.x = (i - 2) * 1.2
				box(tier, Vector3(0, 2.5, 0), Vector3(w, 5.0, w), "#b8402c", false)
				box(tier, Vector3(0, 5.3, 0), Vector3(w + 5.0, 0.8, w + 5.0), "#1a1616", false)
			cylinder(g, Vector3(2.4, 30.0, 0), 0.4, 7.0, "#6a6e74", false, 6, 0.1)
		"clock":  # a clock tower of concrete and steel, its face stopped, its top torn off
			box(g, Vector3(0, 13.0, 0), Vector3(7.0, 26.0, 7.0), "#9a9690", false)
			var face := cylinder(g, Vector3(0, 20.0, 3.6), 2.6, 0.3, "#e0d4b8", false, 12)
			face.rotation.x = PI / 2.0
			box(g, Vector3(0.6, 20.0, 3.9), Vector3(0.25, 2.2, 0.1), "#1a1616", false, Vector3(0, 0, 0.6))
			box(g, Vector3(-0.4, 20.3, 3.9), Vector3(0.25, 1.4, 0.1), "#1a1616", false, Vector3(0, 0, -1.2))
			box(g, Vector3(1.5, 27.5, 0), Vector3(4.0, 3.0, 7.0), "#2a2c30", false, Vector3(0, 0, 0.3))
	return g


## The ghost of the Tower of the Reformed Man, above its broken base at `at` (the top of the
## plinth): for each of the 17 column slots not `standing`, the missing upper part of its
## column; the beam blocks between the column tops; nine rough tiers of piers, each with its cap
## ring; and on top the Reformed Man himself, four times life size. All one see-through shade
## (GHOST_ALPHA) with no collision. Once `tier_whole`, the Greek tier's beams stand in solid
## marble with a warm light inside, and only the tiers above are ghosts.
## Returns {"root", "ghost_columns": how many ghost column tops there are, "light"}.
static func tower(parent: Node3D, at: Vector3, standing: Array, tier_whole: bool) -> Dictionary:
	var g := group(parent, at)
	var ghost := group(g, Vector3.ZERO)
	var n := standing.size()
	var ghosts := 0
	for k in n:
		if standing[k] or tier_whole:
			continue
		var p := sky_point(k * 360.0 / n, 0.0, 4.9)
		cylinder(ghost, p + Vector3(0, 1.53, 0), 0.3, 2.31, "marble", false, 8, 0.28)
		box(ghost, p + Vector3(0, 4.02, 0), Vector3(0.95, 0.36, 0.95), "marble", false)
		ghosts += 1
	var beams := group(g, Vector3.ZERO) if tier_whole else ghost
	for k in n:
		var b := (k + 0.5) * 360.0 / n
		box(beams, sky_point(b, 0.0, 4.9 * cos(PI / n)) + Vector3(0, 4.5, 0), Vector3(1.9, 0.6, 0.9), "marble", false,
			Vector3(0, -deg_to_rad(b), 0))
	for i in range(1, 10):
		var y0 := 5.0 + (i - 1) * 4.4
		var r := 5.2 - 0.2 * i
		for j in 12:
			var b := j * 30.0 + (15.0 if i % 2 == 0 else 0.0)
			box(ghost, sky_point(b, 0.0, r) + Vector3(0, y0 + 1.8, 0), Vector3(0.6, 3.6, 0.6), "marble", false,
				Vector3(0, -deg_to_rad(b), 0))
		cylinder(ghost, Vector3(0, y0 + 3.6, 0), r + 0.4, 0.5, "marble", false, 12)
	var crown := group(ghost, Vector3(0, 44.6, 0))
	crown.scale = Vector3.ONE * 4.0
	walker(crown, Vector3.ZERO, 0.0, {"beard": "long"})
	unsolid(g)
	shade(ghost, GHOST_ALPHA)
	var light: OmniLight3D = null
	if tier_whole:
		light = OmniLight3D.new()
		light.position = Vector3(0, 2.6, 0)
		light.light_color = Color("ffcf8a")
		light.light_energy = 0.8
		light.omni_range = 8.0
		g.add_child(light)
	return {"root": g, "ghost_columns": ghosts, "light": light}


## A giant marble hand rising from a heap of rubble, reaching up: the forearm out of the ground,
## a palm, four fingers of two joints each and a thumb, curled a little. About 4.5 m tall; its
## palm faces +Z of its group.
static func stone_hand(parent: Node3D, at: Vector3, yaw: float) -> Node3D:
	var g := group(parent, at, yaw)
	for r in [[Vector3(-1.0, 0, 0.5), 0.55], [Vector3(1.0, 0, -0.35), 0.5], [Vector3(0.3, 0, 1.1), 0.4], [Vector3(-0.5, 0, -1.0), 0.45]]:
		rock(g, r[0], r[1])
	fallen_column(g, Vector3(1.3, 0, 1.2), 0.9, 2.0)
	var hand := group(g, Vector3.ZERO)
	hand.rotation = Vector3(-0.12, 0, 0.1)
	cylinder(hand, Vector3(0, -0.3, 0), 0.6, 2.1, "marble", false, 8, 0.5)  # the forearm
	box(hand, Vector3(0, 2.3, 0), Vector3(1.3, 1.1, 0.5), "marble", false)  # the palm
	var lengths := [0.8, 0.95, 0.9, 0.7]
	for k in 4:
		var finger := group(hand, Vector3(-0.48 + k * 0.32, 2.85, 0))
		finger.rotation = Vector3(0.12 + 0.05 * k, 0, 0.06 * (1.5 - k))
		var l: float = lengths[k]
		box(finger, Vector3(0, l / 2.0, 0), Vector3(0.27, l, 0.32), "marble", false)
		var tip := group(finger, Vector3(0, l, 0))
		tip.rotation.x = 0.3 + 0.08 * k
		box(tip, Vector3(0, l * 0.38, 0), Vector3(0.25, l * 0.76, 0.3), "marble", false)
	var thumb := group(hand, Vector3(0.66, 1.95, 0.1))
	thumb.rotation = Vector3(0.3, 0, -0.75)
	box(thumb, Vector3(0, 0.35, 0), Vector3(0.3, 0.7, 0.34), "marble", false)
	var thumb_tip := group(thumb, Vector3(0, 0.7, 0))
	thumb_tip.rotation.x = 0.4
	box(thumb_tip, Vector3(0, 0.25, 0), Vector3(0.28, 0.5, 0.32), "marble", false)
	var wrist := BoxShape3D.new()
	wrist.size = Vector3(1.4, 3.0, 1.0)
	solid(g, wrist, Vector3(0, 1.5, 0))
	return g


## A mourning shade sitting on a stone at the broken edge, facing +Z of its group: a teacher's
## body, pale and half see-through, on a seat of plain stone, its head bowed (or, `lifted`,
## raised). Returns its parts {"root", "head", "hand"}.
static func mourner(parent: Node3D, at: Vector3, yaw: float, lifted: bool) -> Dictionary:
	var who := teacher(parent, at, yaw, {"robe": "8a8e9c", "skin": "b0b4c0", "hair_color": "c0c4cc", "beard": "short"})
	for c in (who["root"] as Node).find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("keep"):
			(c as MeshInstance3D).material_override = Tex.material("stone")
	(who["head"] as Node3D).rotation.x = -0.1 if lifted else 0.6
	shade(who["root"], 0.3)
	return who


## Takes every collision body out from under `node`: it can still be seen but never touched (a
## ghost, a drifting piece, anything in a group that moves or is scaled).
static func unsolid(node: Node) -> void:
	for c in node.find_children("*", "CollisionObject3D", true, false):
		if is_instance_valid(c):
			c.get_parent().remove_child(c)
			c.free()


## Stones laid round an arch in the parent's X/Y plane: `count` blocks from `from_deg` to `to_deg`
## (counter-clockwise from +X, so 0 to 180 is the top half) with their inner faces on `radius`
## round `centre`. `block` is each stone's size (along the curve, outward, deep); the materials
## in `mats` take turns. No collision. Returns the stones.
static func arch(parent: Node3D, centre: Vector3, radius: float, from_deg: float, to_deg: float, count: int,
		block: Vector3, mats: Array) -> Array:
	var out: Array = []
	for i in count:
		var a := deg_to_rad(lerpf(from_deg, to_deg, (i + 0.5) / count))
		var p := centre + Vector3(cos(a), sin(a), 0) * (radius + block.y / 2.0)
		out.append(box(parent, p, block, mats[i % mats.size()], false, Vector3(0, 0, a - PI / 2.0)))
	return out


static func _cyl(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 6 * detail
	c.rings = 1
	return c
