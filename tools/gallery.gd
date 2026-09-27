extends SceneTree
## Renders the kit's pieces one at a time, each framed by the camera on its own, for checking
## the look without building a place. Needs a display (on a server: xvfb-run).
##   godot --path . --script res://tools/gallery.gd -- --out=C:/shots [name ...]
## With no names it renders every piece, whole and lost to the world ("name" and "name_lost").
## --list prints the names. --size=640x360 sets the image.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Areas := preload("res://scripts/hall/kit_greek_areas.gd")
## Every piece a place can bring back: an area set piece is built with all of them, or none.
const ALL_BACK := ["water", "leaves", "lamps", "walkway", "sun", "teacher", "household", "soldiers"]

var _view: SubViewport
var _stage: Node3D
var _camera: Camera3D


## Every piece by name: [the world's detail, how to build it on a stage, whole or lost to the
## world]. Each is rendered both ways: "name" whole, "name_lost" lost.
static func pieces() -> Dictionary:
	return {
		# Greece, the places still to come
		"horse": [1, func(s: Node3D, w: bool): Greek.beast(s, Vector3.ZERO, 1.9, "horse", "", 1.0, w)],
		"ox": [1, func(s: Node3D, w: bool): Greek.beast(s, Vector3.ZERO, 1.9, "ox", "", 1.0, w)],
		"sheep_goat_dog_wolf": [1, func(s: Node3D, w: bool):
			for k in 4:
				Greek.beast(s, Vector3(-2.4 + k * 1.6, 0, 0), 1.9, ["sheep", "goat", "dog", "wolf"][k], "", 1.0, w)],
		"plough_team": [1, func(s: Node3D, w: bool):
			Greek.field(s, Vector3(0, 0, -3), Vector2(8, 8), 0.0, w)
			Greek.plough_team(s, Vector3.ZERO, 0.5, w)],
		"hoplites": [1, func(s: Node3D, w: bool):
			Greek.hoplite(s, Vector3(-0.6, 0, 0), "sparta", not w)
			Greek.hoplite(s, Vector3(0.6, 0, 0), "athens", not w)],
		"phalanx": [1, func(s: Node3D, w: bool): Greek.phalanx(s, Vector3.ZERO, 3, 6, "sparta", not w)],
		"immortals": [1, func(s: Node3D, w: bool):
			Greek.immortal(s, Vector3(-0.6, 0, 0), not w)
			Greek.immortal(s, Vector3(0.6, 0, 0), not w)],
		"achaeans": [1, func(s: Node3D, w: bool):
			Greek.achaean(s, Vector3(-0.6, 0, 0), not w)
			Greek.achaean(s, Vector3(0.6, 0, 0), not w)],
		"trireme": [1, func(s: Node3D, w: bool): Greek.ship(s, Vector3.ZERO, 0.9, "trireme", true, true, w)],
		"black_ship": [1, func(s: Node3D, w: bool): Greek.ship(s, Vector3.ZERO, 0.9, "pentekonter", false, false, w)],
		"troy_wall": [1, func(s: Node3D, w: bool): Greek.troy_wall(s, Vector3.ZERO, 0.0, 30.0, true, w)],
		"wooden_horse": [1, func(s: Node3D, w: bool): Greek.wooden_horse(s, Vector3.ZERO, 1.9, w)],
		"lion_gate": [1, func(s: Node3D, w: bool): Greek.lion_gate(s, Vector3.ZERO, 0.0, w)],
		"theatre": [1, func(s: Node3D, w: bool): Greek.theatre(s, Vector3.ZERO, PI, 12, w)],
		"masks": [1, func(s: Node3D, w: bool):
			Greek.mask(s, Vector3(-0.4, 1.0, 0), 0.0, "tragic", 2.0, w)
			Greek.mask(s, Vector3(0.4, 1.0, 0), 0.0, "comic", 2.0, w)],
		"actors": [1, func(s: Node3D, w: bool):
			Greek.actor(s, Vector3(-0.5, 0, 0), 0.0, "tragic", "6a2a3a", not w)
			Greek.actor(s, Vector3(0.5, 0, 0), 0.0, "comic", "8a6a2a", not w)],
		"crane": [1, func(s: Node3D, w: bool): Greek.crane(s, Vector3.ZERO, PI / 2.0, true, w)],
		"delphi": [1, func(s: Node3D, w: bool):
			Greek.tripod(s, Vector3(-0.9, 0, 0), true, w)
			Greek.omphalos(s, Vector3(0.9, 0, 0), w)],
		"pharos": [1, func(s: Node3D, w: bool): Greek.pharos(s, Vector3.ZERO, 1.0, w)],
		"sand_tray": [1, func(s: Node3D, w: bool): Greek.sand_tray(s, Vector3.ZERO, 0.0, w)],
		"cave": [1, func(s: Node3D, w: bool): Greek.cave(s, Vector3.ZERO, 0.0, w)],
		"herm_altar_bema": [1, func(s: Node3D, w: bool):
			Greek.herm(s, Vector3(-2.5, 0, 0), 0.0, "marble", w)
			Greek.altar(s, Vector3(0, 0, 0), 0.0, "greek", w, w)
			Greek.bema(s, Vector3(2.8, 0, 0), 0.0, w)],
		"loom": [1, func(s: Node3D, w: bool): Greek.loom(s, Vector3.ZERO, 0.0, 0.45, "#e8e0d0", w)],
		"symposium": [1, func(s: Node3D, w: bool):
			Greek.kline(s, Vector3(0, 0, 0), 0.0, w)
			Greek.krater(s, Vector3(1.6, 0, 0.6), w)
			Greek.barbitos(s, Vector3(-1.4, 0, 0.6), 0.3, w)],
		"farm": [1, func(s: Node3D, w: bool):
			Greek.threshing_floor(s, Vector3(-3, 0, 0), 3.0, w)
			Greek.hives(s, Vector3(2, 0, 0), 0.0, 5, w)],
		# e1 props: the Rhetorica's court and memory images, Euclid's Alexandria
		"court": [1, func(s: Node3D, w: bool):
			Rome.tribunal(s, Vector3(0, 0, -3), 0.0, w)
			Rome.subsellia(s, Vector3(-5, 0, 0), PI / 2.0, 5.0, 2, w)
			Greek.clepsydra(s, Vector3(3, 0, 1), w)],
		"memory_images": [1, func(s: Node3D, w: bool):
			for k in 5:
				Rome.memory_image(s, Vector3(-4.0 + k * 2.0, 0, 0), 0.0, ["poison", "bloodied", "crowned", "smeared", "golden_hand"][k], w)],
		"armarium_palm": [1, func(s: Node3D, w: bool):
			Greek.armarium(s, Vector3(-1.5, 0, 0), 0.0, w)
			Greek.date_palm(s, Vector3(2.0, 0, 0), 7.0, w)],
		"construction": [1, func(s: Node3D, w: bool): Greek.construction(s, Vector3.ZERO, 0.0, 5.0, w)],
		"tiled_squares": [1, func(s: Node3D, w: bool): Greek.tiled_squares(s, Vector3.ZERO, 0.0, 1.0, w)],
		# e1 areas
		"area_law_court": [1, func(s: Node3D, w: bool): Areas.law_court(s, Vector3.ZERO, 0.0, ALL_BACK if w else [])],
		"area_memory_house": [1, func(s: Node3D, w: bool): Areas.memory_house(s, Vector3.ZERO, 0.0, ALL_BACK if w else [])],
		"area_museum_court": [1, func(s: Node3D, w: bool): Areas.museum_court(s, Vector3.ZERO, 0.0, ALL_BACK if w else [])],
		"area_prop_one": [1, func(s: Node3D, w: bool): Areas.prop_one(s, Vector3.ZERO, 0.0, ALL_BACK if w else [])],
		"area_prop_forty_seven": [1, func(s: Node3D, w: bool): Areas.prop_forty_seven(s, Vector3.ZERO, 0.0, ALL_BACK if w else [])],
		# Rome
		"stone_pines": [2, func(s: Node3D, w: bool):
			Rome.stone_pine(s, Vector3(-4, 0, 0), 1.0, w)
			Rome.stone_pine(s, Vector3(4, 0, 0), 0.8, w)],
		"temple": [2, func(s: Node3D, w: bool): Rome.temple(s, Vector3.ZERO, 0.0, w)],
		"triumphal_arch": [2, func(s: Node3D, w: bool): Rome.triumphal_arch(s, Vector3.ZERO, 0.0, true, w)],
		"aqueduct": [2, func(s: Node3D, w: bool): Rome.aqueduct(s, Vector3(-30, 0, 0), Vector3(30, 0, 0), 2, w)],
		"rostra": [2, func(s: Node3D, w: bool): Rome.rostra(s, Vector3.ZERO, 0.0, w)],
		"via": [2, func(s: Node3D, w: bool):
			Rome.via(s, Vector3(0, 0, 20), Vector3(0, 0, -20), 4.2, w)
			Rome.milestone(s, Vector3(3.2, 0, 2), -PI / 2.0, w)
			Rome.tomb(s, Vector3(-9, 0, -6), PI / 2.0, "round", w)
			Rome.tomb(s, Vector3(-6, 0, 6), PI / 2.0, "altar", w)],
		"legionaries": [2, func(s: Node3D, w: bool):
			Rome.legionary(s, Vector3(-0.6, 0, 0), not w)
			Rome.legionary(s, Vector3(0.6, 0, 0), not w)],
		"century": [2, func(s: Node3D, w: bool): Rome.century(s, Vector3.ZERO, 3, 6, not w)],
		"standards": [2, func(s: Node3D, w: bool):
			Rome.aquila(s, Vector3(-1.0, 0, 0), w)
			Rome.fasces(s, Vector3(0, 0, 0), w)
			Rome.sella(s, Vector3(1.2, 0, 0), 0.0, w)],
		"togati": [2, func(s: Node3D, w: bool):
			Rome.togatus(s, Vector3(-0.6, 0, 0), 0.0, {"stripe": true, "beard": "none", "hair_color": "4a3a2a"}, not w)
			Rome.togatus(s, Vector3(0.6, 0, 0), 0.0, {"praetexta": true, "scroll": true, "beard": "short", "hair_color": "8a8278"}, not w)],
		"house": [2, func(s: Node3D, w: bool): Rome.atrium(s, Vector3.ZERO, 0.0, w)],
		"triclinium": [2, func(s: Node3D, w: bool): Rome.triclinium(s, Vector3.ZERO, 0.0, w)],
		"lararium_fountain": [2, func(s: Node3D, w: bool):
			Rome.lararium(s, Vector3(-1.5, 0, 0), 0.0, w)
			Rome.fountain(s, Vector3(1.5, 0, 0), 0.0, w)
			Greek.altar(s, Vector3(4.2, 0, 0), 0.0, "roman", false, w)],
		"pergola": [2, func(s: Node3D, w: bool): Rome.pergola(s, Vector3.ZERO, 0.0, 6.0, w)],
		"insula": [2, func(s: Node3D, w: bool): Rome.insula(s, Vector3.ZERO, 0.0, 4, 14.0, w)],
		"she_wolf": [2, func(s: Node3D, w: bool): Rome.she_wolf(s, Vector3.ZERO, 1.9, w)],
		"equestrian": [2, func(s: Node3D, w: bool): Rome.equestrian(s, Vector3.ZERO, 1.6, w)],
		"capsa_and_tablets": [2, func(s: Node3D, w: bool): Rome.capsa(s, Vector3.ZERO, w)],
		"colosseum": [2, func(s: Node3D, w: bool): Rome.colosseum(s, Vector3.ZERO, 1.0, w)],
		"pantheon": [2, func(s: Node3D, w: bool): Rome.pantheon(s, Vector3.ZERO, 0.0, 1.0, w)],
		"gateway": [2, func(s: Node3D, w: bool):
			Rome.gateway(s, Vector3(-3, 0, 0), 0.0, w, w)
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
	var every: Array = []
	for n in all:
		every.append_array([n, n + "_lost"])
	if args.has("list"):
		print("\n".join(every))
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
	var names: Array = args["names"] if not args["names"].is_empty() else every
	var failed := 0
	for name in names:
		var whole: bool = not str(name).ends_with("_lost")
		var base := str(name).trim_suffix("_lost")
		if not all.has(base):
			push_error("No piece called %s (try --list)" % name)
			failed += 1
			continue
		_stage = Node3D.new()
		_view.add_child(_stage)
		Kit.detail = all[base][0]
		Kit.sunset(_stage, "morning")
		Kit.box(_stage, Vector3(0, -0.05, 0), Vector3(400, 0.1, 400), "earth", false)
		var holder := Node3D.new()
		_stage.add_child(holder)
		all[base][1].call(holder, whole)
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
## see all of it (leaving out anything far off in the distance, like the Pharos over an area).
func _frame(holder: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		if b.get_center().length() > 150.0 and b.size.length() < 400.0 and not first:
			continue
		box = b if first else box.merge(b)
		first = false
	var centre := box.get_center()
	var radius := maxf(0.5, box.size.length() / 2.0)
	var dir := Vector3(0.55, 0.42, 1.0).normalized()
	_camera.position = centre + dir * radius * 1.9
	_camera.look_at(centre, Vector3.UP)
