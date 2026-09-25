extends RefCounted
## Gray-block builders for the placeholder 3D look. Everything here is
## replaced by real models later; keep call sites using these helpers.


static func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func mesh(m: Mesh, color: Color, pos: Vector3, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material(color, emission)
	mi.position = pos
	return mi


## A solid box the player bumps into.
static func solid_box(size: Vector3, color: Color, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	var bm := BoxMesh.new()
	bm.size = size
	body.add_child(mesh(bm, color, Vector3.ZERO))
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	return body


## A tent: box walls with a prism roof.
static func tent(width: float, depth: float, color: Color, pos: Vector3) -> Node3D:
	var t := solid_box(Vector3(width, 2.2, depth), color, pos + Vector3(0, 1.1, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(width + 0.6, 1.6, depth + 0.6)
	t.add_child(mesh(roof, color.darkened(0.25), Vector3(0, 1.9, 0)))
	return t


## A standing person: body, head, and a floating name.
static func figure(display_name: String, color: Color) -> Node3D:
	var root := Node3D.new()
	if display_name != "":
		root.name = display_name.validate_node_name()
	var body := CapsuleMesh.new()
	body.radius = 0.32
	body.height = 1.45
	root.add_child(mesh(body, color, Vector3(0, 0.72, 0)))
	var head := SphereMesh.new()
	head.radius = 0.2
	head.height = 0.4
	root.add_child(mesh(head, Color(0.85, 0.72, 0.6), Vector3(0, 1.62, 0)))
	var nose := BoxMesh.new()  # shows which way the figure faces
	nose.size = Vector3(0.08, 0.08, 0.12)
	root.add_child(mesh(nose, Color(0.85, 0.72, 0.6), Vector3(0, 1.6, -0.22)))
	if display_name == "":
		return root
	var tag := Label3D.new()
	tag.text = display_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.1, 0)
	tag.font_size = 48
	tag.pixel_size = 0.006
	tag.outline_size = 12
	root.add_child(tag)
	return root


static func label3d(text: String, pos: Vector3, size: int = 64, color: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 14
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l
