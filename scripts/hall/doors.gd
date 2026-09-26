extends RefCounted
## LOCAL STUB for the world builder's tests. Never commit: the doors builder writes the real one.

const Kit := preload("res://scripts/hall/kit.gd")


static func build(parent: Node3D, at: Vector3, yaw: float, style: String, state: String) -> Dictionary:
	var g := Kit.group(parent, at, yaw)
	var sealed := state == "sealed"
	var mat := "voidstone" if style == "surreal" else "marble"
	for x in [-1.4, 1.4]:
		Kit.box(g, Vector3(x, 2.4, 0), Vector3(0.6, 4.8, 0.6), mat, not sealed)
	Kit.box(g, Vector3(0, 5.1, 0), Vector3(3.6, 0.6, 0.8), mat, false)
	Kit.box(g, Vector3(0, 0.1, 0.4), Vector3(4.0, 0.2, 1.6), mat, false)
	Kit.box(g, Vector3(0, 5.6, 0), Vector3(3.0, 0.4, 0.7), mat, false)
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 4.4)
	Kit.mesh(g, q, "void" if sealed else ("glow_cold" if state == "cold" else "glow"), Vector3(0, 2.4, -0.1))
	if style == "surreal":
		Kit.mesh(g, q, "daysky", Vector3(0, 2.4, -0.05))
	var loose: Array = []
	var n := 3 if sealed else (1 if state == "cold" and style == "greek" else 0)
	for k in n:
		var b := Kit.group(g, Vector3(-1.5 + 1.5 * k, 6.2 + 0.3 * k, 0.5))
		Kit.box(b, Vector3.ZERO, Vector3(0.6, 0.6, 0.6), mat, false)
		loose.append(b)
	if state == "warm":
		Kit.blob(g, Vector3(0, 5.8, 0), 0.25, "fire", Vector3(1, 1.6, 1), 5)
	var light: OmniLight3D = null
	if not sealed:
		light = OmniLight3D.new()
		light.position = Vector3(0, 2.2, 1.2)
		light.light_color = Color("b8c4d8") if state == "cold" else Color("ffd49a")
		light.light_energy = 0.6 if state == "cold" else 1.4
		light.omni_range = 6.0 if state == "cold" else 7.0
		g.add_child(light)
	return {"root": g, "light": light, "loose": loose}
