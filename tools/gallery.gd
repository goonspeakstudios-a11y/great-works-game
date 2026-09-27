extends SceneTree
## Renders the kit's pieces one at a time, each framed by the camera on its own, for checking
## the look without building a place. Needs a display (on a server: xvfb-run).
##   godot --path . --script res://tools/gallery.gd -- --out=C:/shots [name ...]
## With no names it renders every piece. --list prints the names. --size=640x360 sets the image.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")

var _view: SubViewport
var _stage: Node3D
var _camera: Camera3D


## Every piece by name: [the world's detail, how to build it on a stage].
static func pieces() -> Dictionary:
	return {
		# Greece, the places still to come
		"horse": [1, func(s: Node3D): Greek.beast(s, Vector3.ZERO, 1.9, "horse")],
		"ox": [1, func(s: Node3D): Greek.beast(s, Vector3.ZERO, 1.9, "ox")],
		"sheep_goat_dog_wolf": [1, func(s: Node3D):
			for k in 4:
				Greek.beast(s, Vector3(-2.4 + k * 1.6, 0, 0), 1.9, ["sheep", "goat", "dog", "wolf"][k])],
		"plough_team": [1, func(s: Node3D):
			Greek.field(s, Vector3(0, 0, -3), Vector2(8, 8))
			Greek.plough_team(s, Vector3.ZERO, 0.5)],
		"hoplites": [1, func(s: Node3D):
			Greek.hoplite(s, Vector3(-1.2, 0, 0), "sparta")
			Greek.hoplite(s, Vector3(0, 0, 0), "athens")
			Greek.hoplite(s, Vector3(1.2, 0, 0), "sparta", true)],
		"phalanx": [1, func(s: Node3D): Greek.phalanx(s, Vector3.ZERO, 3, 6, "sparta")],
		"immortals": [1, func(s: Node3D):
			Greek.immortal(s, Vector3(-0.6, 0, 0))
			Greek.immortal(s, Vector3(0.6, 0, 0), true)],
		"achaeans": [1, func(s: Node3D):
			Greek.achaean(s, Vector3(-0.6, 0, 0))
			Greek.achaean(s, Vector3(0.6, 0, 0), true)],
		"trireme": [1, func(s: Node3D): Greek.ship(s, Vector3.ZERO, 0.9, "trireme", true)],
		"black_ship": [1, func(s: Node3D): Greek.ship(s, Vector3.ZERO, 0.9, "pentekonter", false, false)],
		"troy_wall": [1, func(s: Node3D): Greek.troy_wall(s, Vector3.ZERO, 0.0, 30.0)],
		"wooden_horse": [1, func(s: Node3D): Greek.wooden_horse(s, Vector3.ZERO, 1.9)],
		"lion_gate": [1, func(s: Node3D): Greek.lion_gate(s, Vector3.ZERO, 0.0)],
		"theatre": [1, func(s: Node3D): Greek.theatre(s, Vector3.ZERO, PI)],
		"theatre_ruin": [1, func(s: Node3D): Greek.theatre(s, Vector3.ZERO, PI, 12, false)],
		"masks": [1, func(s: Node3D):
			Greek.mask(s, Vector3(-0.4, 1.0, 0), 0.0, "tragic", 2.0)
			Greek.mask(s, Vector3(0.4, 1.0, 0), 0.0, "comic", 2.0)],
		"actors": [1, func(s: Node3D):
			Greek.actor(s, Vector3(-0.5, 0, 0), 0.0, "tragic")
			Greek.actor(s, Vector3(0.5, 0, 0), 0.0, "comic", "8a6a2a")],
		"crane": [1, func(s: Node3D): Greek.crane(s, Vector3.ZERO, PI / 2.0)],
		"delphi": [1, func(s: Node3D):
			Greek.tripod(s, Vector3(-0.9, 0, 0), true)
			Greek.omphalos(s, Vector3(0.9, 0, 0))],
		"pharos": [1, func(s: Node3D): Greek.pharos(s, Vector3.ZERO)],
		"sand_tray": [1, func(s: Node3D): Greek.sand_tray(s, Vector3.ZERO, 0.0)],
		"cave": [1, func(s: Node3D): Greek.cave(s, Vector3.ZERO, 0.0)],
		"herm_altar_bema": [1, func(s: Node3D):
			Greek.herm(s, Vector3(-2.5, 0, 0), 0.0)
			Greek.altar(s, Vector3(0, 0, 0), 0.0, "greek", true)
			Greek.bema(s, Vector3(2.8, 0, 0), 0.0)],
		"loom": [1, func(s: Node3D): Greek.loom(s, Vector3.ZERO, 0.0, 0.45)],
		"symposium": [1, func(s: Node3D):
			Greek.kline(s, Vector3(0, 0, 0), 0.0)
			Greek.krater(s, Vector3(1.6, 0, 0.6))
			Greek.barbitos(s, Vector3(-1.4, 0, 0.6), 0.3)],
		"farm": [1, func(s: Node3D):
			Greek.threshing_floor(s, Vector3(-3, 0, 0), 3.0)
			Greek.hives(s, Vector3(2, 0, 0), 0.0)],
		# Rome
		"stone_pines": [2, func(s: Node3D):
			Rome.stone_pine(s, Vector3(-4, 0, 0), 1.0)
			Rome.stone_pine(s, Vector3(4, 0, 0), 0.8, false)],
		"temple": [2, func(s: Node3D): Rome.temple(s, Vector3.ZERO, 0.0)],
		"temple_ruin": [2, func(s: Node3D): Rome.temple(s, Vector3.ZERO, 0.0, false)],
		"triumphal_arch": [2, func(s: Node3D): Rome.triumphal_arch(s, Vector3.ZERO, 0.0)],
		"aqueduct": [2, func(s: Node3D): Rome.aqueduct(s, Vector3(-30, 0, 0), Vector3(30, 0, 0), 2)],
		"rostra": [2, func(s: Node3D): Rome.rostra(s, Vector3.ZERO, 0.0)],
		"via": [2, func(s: Node3D):
			Rome.via(s, Vector3(0, 0, 20), Vector3(0, 0, -20))
			Rome.milestone(s, Vector3(3.2, 0, 2), -PI / 2.0)
			Rome.tomb(s, Vector3(-9, 0, -6), PI / 2.0, "round")
			Rome.tomb(s, Vector3(-6, 0, 6), PI / 2.0, "altar")],
		"legionaries": [2, func(s: Node3D):
			Rome.legionary(s, Vector3(-0.6, 0, 0))
			Rome.legionary(s, Vector3(0.6, 0, 0), true)],
		"century": [2, func(s: Node3D): Rome.century(s, Vector3.ZERO, 3, 6)],
		"standards": [2, func(s: Node3D):
			Rome.aquila(s, Vector3(-1.0, 0, 0))
			Rome.fasces(s, Vector3(0, 0, 0))
			Rome.sella(s, Vector3(1.2, 0, 0), 0.0)],
		"togati": [2, func(s: Node3D):
			Rome.togatus(s, Vector3(-0.6, 0, 0), 0.0, {"stripe": true, "beard": "none", "hair_color": "4a3a2a"})
			Rome.togatus(s, Vector3(0.6, 0, 0), 0.0, {"praetexta": true, "scroll": true, "beard": "short", "hair_color": "8a8278"})],
		"house": [2, func(s: Node3D): Rome.atrium(s, Vector3.ZERO, 0.0)],
		"triclinium": [2, func(s: Node3D): Rome.triclinium(s, Vector3.ZERO, 0.0)],
		"lararium_fountain": [2, func(s: Node3D):
			Rome.lararium(s, Vector3(-1.5, 0, 0), 0.0)
			Rome.fountain(s, Vector3(1.5, 0, 0), 0.0)
			Greek.altar(s, Vector3(4.2, 0, 0), 0.0, "roman")],
		"pergola": [2, func(s: Node3D): Rome.pergola(s, Vector3.ZERO, 0.0, 6.0)],
		"she_wolf": [2, func(s: Node3D): Rome.she_wolf(s, Vector3.ZERO, 1.9)],
		"equestrian": [2, func(s: Node3D): Rome.equestrian(s, Vector3.ZERO, 1.6)],
		"capsa_and_tablets": [2, func(s: Node3D): Rome.capsa(s, Vector3.ZERO)],
		"colosseum": [2, func(s: Node3D): Rome.colosseum(s, Vector3.ZERO, 1.0)],
		"pantheon": [2, func(s: Node3D): Rome.pantheon(s, Vector3.ZERO, 0.0, 1.0)],
		"gateway": [2, func(s: Node3D):
			Rome.gateway(s, Vector3(-3, 0, 0), 0.0, true, true)
			Rome.gateway(s, Vector3(3, 0, 0), 0.0, false)],
	}


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var out := {"names": []}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			out[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
		elif a.begins_with("--"):
			out[a.substr(2)] = true
		else:
			out["names"].append(a)
	return out


func _run() -> void:
	var args := _args()
	var all := pieces()
	if args.has("list"):
		print("\n".join(all.keys()))
		quit()
		return
	var out_dir := str(args.get("out", "user://gallery"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var size := Vector2i(640, 360)
	if args.has("size"):
		var wh := str(args["size"]).split("x")
		size = Vector2i(int(wh[0]), int(wh[1]))
	_view = SubViewport.new()
	_view.size = size
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_view)
	_camera = Camera3D.new()
	_camera.fov = 55.0
	_camera.far = 4000.0
	_view.add_child(_camera)
	_camera.current = true
	var names: Array = args["names"] if not args["names"].is_empty() else all.keys()
	var failed := 0
	for name in names:
		if not all.has(name):
			push_error("No piece called %s (try --list)" % name)
			failed += 1
			continue
		_stage = Node3D.new()
		_view.add_child(_stage)
		Kit.detail = all[name][0]
		Kit.sunset(_stage, "morning")
		Kit.box(_stage, Vector3(0, -0.05, 0), Vector3(400, 0.1, 400), "earth", false)
		var holder := Node3D.new()
		_stage.add_child(holder)
		all[name][1].call(holder)
		for i in 3:
			await process_frame
		_frame(holder)
		for i in 8:
			await process_frame
		var path := out_dir.path_join("%s.png" % name)
		_view.get_texture().get_image().save_png(path)
		print("Wrote ", path)
		_stage.queue_free()
		await process_frame
	Kit.detail = 1
	quit(1 if failed else 0)


## Puts the camera in front of the piece, a little to the right and above, far enough back to
## see all of it.
func _frame(holder: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var centre := box.get_center()
	var radius := maxf(0.5, box.size.length() / 2.0)
	var dir := Vector3(0.55, 0.42, 1.0).normalized()
	_camera.position = centre + dir * radius * 1.9
	_camera.look_at(centre, Vector3.UP)
