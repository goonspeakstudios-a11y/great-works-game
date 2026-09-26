extends "res://tests/test_base.gd"
## The Nexus: the first place, a broken realm of the mind above every world, mended piece by
## piece as you understand. One door per world, each in its world's style; only Greece's opens.

const Hall := preload("res://scripts/hall/hall.gd")
const Nexus := preload("res://scripts/hall/nexus.gd")
const Doors := preload("res://scripts/hall/doors.gd")
const Music := preload("res://scripts/pixel/music.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")
const Worlds := preload("res://scripts/hall/worlds.gd")
const Progress := preload("res://scripts/hall/progress.gd")

const WORLD_ORDER := ["greece", "rome", "bible", "late_antiquity", "medieval", "judaism_islam", "asia",
	"renaissance", "modern_mind", "modern_imagination"]
const STYLES := ["greek", "roman", "israelite", "byzantine", "gothic", "moorish", "torii", "palladian", "modern", "surreal"]
const PIECES := ["ember", "path", "greek_door", "colour", "shades", "greek_tier"]


func _hall() -> Node:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	return hall


func _door(hall: Node, world: String) -> Dictionary:
	return hall.interactables.filter(func(i): return i.get("world", "") == world)[0]


func _build(state: Dictionary) -> Dictionary:
	var holder := Node3D.new()
	var built := Nexus.build(holder, Worlds.all(), Rooms.doors(), state)
	built["holder"] = holder
	return built


func _ids(work: String) -> Array:
	return Rooms.room(work)["lesson"].map(func(p): return p["id"])


## Ground is a list of discs {"c": Vector2, "r": float} and rects {"rect": Rect2}, in x/z.
static func _on_ground(ground: Array, p: Vector2) -> bool:
	for g in ground:
		if g.has("rect"):
			if (g["rect"] as Rect2).has_point(p):
				return true
		elif p.distance_to(g["c"]) <= g["r"]:
			return true
	return false


## Rails are segments {"a": Vector2, "b": Vector2} in x/z.
static func _crosses_rail(rails: Array, p: Vector2, q: Vector2) -> bool:
	for r in rails:
		if Geometry2D.segment_intersects_segment(p, q, r["a"], r["b"]) != null:
			return true
	return false


func test_the_game_starts_in_the_nexus() -> void:
	var hall := _hall()
	check_eq(hall.here, "nexus", "you start in the Nexus")
	check_eq(hall.here_name, "The Nexus", "the corner says so")
	check_eq(hall._view.size, Vector2i(320, 180), "at Greece's sharpness")
	check_eq(hall.restored_here, [], "a new game finds it broken")
	check_eq(hall._quip, "Your mind lies in pieces.", "one short line on arrival")
	check_eq(hall._hint, "One door still glows. Go to it.", "and one goal")
	hall.free()


func test_a_door_per_world_in_order_and_only_greece_open() -> void:
	var hall := _hall()
	var doors: Array = hall.interactables.filter(func(i): return i.has("world"))
	check_eq(doors.map(func(d): return d["world"]), WORLD_ORDER, "one door per world, in the order of the worlds")
	if doors.size() == WORLD_ORDER.size():
		check(doors[0]["open"] and doors[0]["to"] == "hub", "Greece's door opens, onto the Shore")
		for d in doors.slice(1):
			check(not d["open"], "%s's door is sealed" % d["world"])
			check_eq(d["text"], Worlds.all()[d["world"]]["name"], "the sealed door names its world")
	hall.free()


func test_worlds_json_pins_the_ring() -> void:
	var worlds := Worlds.all()
	check_eq(worlds.keys(), WORLD_ORDER, "the worlds, in order")
	for id in worlds:
		check(STYLES.has(worlds[id].get("door", "")), "%s has a door style" % id)
		check_eq(worlds[id].get("hub", ""), "hub" if id == "greece" else "", "%s: only Greece has a hub yet" % id)


func test_every_door_style_builds() -> void:
	for style in STYLES:
		for state in ["sealed", "cold", "warm"]:
			var holder := Node3D.new()
			var d: Dictionary = Doors.build(holder, Vector3.ZERO, 0.0, style, state)
			var meshes := holder.find_children("*", "MeshInstance3D", true, false).size()
			check(meshes >= 6, "%s door (%s) is built: %d pieces" % [style, state, meshes])
			if state == "sealed":
				check_eq(d.get("loose", []).size(), 3, "%s: three blocks float loose from the sealed door" % style)
				check_eq(holder.find_children("*", "StaticBody3D", true, false).size(), 0, "%s: a sealed door is out of reach" % style)
			else:
				check(d.get("light") is OmniLight3D, "%s: an open door gives light" % style)
			holder.free()


func test_the_pieces_come_back_in_order() -> void:
	var doors := Rooms.doors()
	var first := func(n: int) -> Array: return doors.slice(0, n).map(func(d): return d["work"])
	check_eq(Nexus.back({"points": 0, "mastered": []}), [], "lost")
	check_eq(Nexus.back({"points": 1, "mastered": []}), PIECES.slice(0, 1), "the first idea kindles the fire")
	check_eq(Nexus.back({"points": 3, "mastered": []}), PIECES.slice(0, 2), "three ideas mend the path")
	check_eq(Nexus.back({"points": 12, "mastered": first.call(1)}), PIECES.slice(0, 3), "a book warms Greece's door")
	check_eq(Nexus.back({"points": 12, "mastered": first.call(2)}), PIECES.slice(0, 4), "two books bring colour back")
	check_eq(Nexus.back({"points": 0, "mastered": first.call(2)}), [], "a piece needs every earlier piece back")
	for k in 7:
		check_eq(Nexus.back(Nexus.for_stage(k, doors)), PIECES.slice(0, k), "stage %d" % k)


func test_each_piece_changes_what_you_see() -> void:
	var doors := Rooms.doors()
	var looks: Array = []
	for k in 7:
		var built := _build(Nexus.for_stage(k, doors))
		looks.append(built["looks"])
		built["holder"].free()
	for k in range(1, 7):
		check(looks[k] != looks[k - 1], "piece %d (%s) changes what you see" % [k, PIECES[k - 1]])
		check(looks[k]["saturation"] > looks[k - 1]["saturation"], "colour rises with piece %d" % k)
	check_eq(looks[0]["saturation"], 0.2, "lost, almost no colour")
	check_eq([looks[1]["bridge"], looks[2]["bridge"]], ["broken", "whole"], "the path knits whole")
	check_eq([looks[2]["greek_door"], looks[3]["greek_door"]], ["cold", "warm"], "Greece's door burns warm")
	check_eq([looks[4]["shades"], looks[5]["shades"]], ["bowed", "lifted"], "the shades lift their heads")
	check_eq([looks[3]["dust"], looks[4]["dust"]], [60, 30], "less of the place drifts away")
	check_eq([looks[0]["ember"], looks[1]["ember"]], [false, true], "the fire at the foot of the Tower")


func test_each_idea_lights_a_star_and_each_book_raises_a_column() -> void:
	var before := _build({"points": 4, "mastered": []})
	check_eq(before["looks"]["stars"], 4, "four ideas, four new stars")
	check_eq(before["columns"], [], "no column stands yet")
	check_eq(before["looks"]["ghost_columns"], 17, "seventeen ghosts of columns")
	before["holder"].free()
	var after := _build({"points": 6, "mastered": ["porphyry-isagoge"]})
	check_eq(after["columns"], ["porphyry-isagoge"], "the Isagoge's column stands again")
	check_eq(after["looks"]["ghost_columns"], 16, "and its ghost is gone")
	check(after["interactables"].any(func(i): return i["kind"] == "look" and i["text"].contains("Isagoge")), "you can look at its column")
	after["holder"].free()


func test_the_nexus_music_follows_its_pieces() -> void:
	var files := func(back: Array) -> Array:
		var f: Array = Music.plan("nexus", back).map(func(l): return l["file"])
		f.sort()
		return f
	check_eq(files.call([]), ["nexus_ghost", "void"], "lost: only the echo and the void's breath")
	for k in range(1, 6):
		check(files.call(PIECES.slice(0, k)) != files.call(PIECES.slice(0, k - 1)), "%s changes what you hear" % PIECES[k - 1])
	check(not files.call(PIECES.slice(0, 3)).has("nexus_ghost"), "the echo is gone once Greece's door is warm")
	var db := func(back: Array, file: String) -> float:
		for l in Music.plan("nexus", back):
			if l["file"] == file:
				return l["db"]
		return -999.0
	check(db.call(PIECES.slice(0, 1), "nexus_ghost") < db.call([], "nexus_ghost"), "the echo fades as pieces return")
	check(db.call([], "void") > db.call(PIECES.slice(0, 1), "void"), "the void is loudest while nothing is mended")
	var shore: Array = Music.plan("shore", []).filter(func(l): return l["music"]).map(func(l): return l["file"])
	for l in Music.plan("nexus", PIECES):
		check(ResourceLoader.exists(Music.file_for(l["file"])), "%s is rendered" % l["file"])
		if l["music"]:
			check(not shore.has(l["file"]), "%s is the Nexus's own, not the Shore's" % l["file"])


func test_you_cannot_walk_off_the_edge() -> void:
	var built := _build(Nexus.for_stage(0, Rooms.doors()))
	var ground: Array = built["ground"]
	var rails: Array = built["rails"]
	check(ground.size() >= 3 and rails.size() > 20, "there is ground and there are rails")
	var misses := 0
	for g in ground:
		if g.has("rect"):
			var r: Rect2 = g["rect"]
			for i in 40:
				var z := r.position.y + r.size.y * (i + 0.5) / 40.0
				for side in [[r.position.x + 0.4, r.position.x - 0.2], [r.end.x - 0.4, r.end.x + 0.2]]:
					var p := Vector2(side[0], z)
					var q := Vector2(side[1], z)
					if not _on_ground(ground, q) and not _crosses_rail(rails, p, q):
						misses += 1
		else:
			for i in 720:
				var dir := Vector2.from_angle(TAU * i / 720.0)
				var p: Vector2 = g["c"] + dir * (g["r"] - 1.2)
				var q: Vector2 = g["c"] + dir * (g["r"] + 0.2)
				if not _on_ground(ground, q) and not _crosses_rail(rails, p, q):
					misses += 1
	check_eq(misses, 0, "every step off an edge meets a rail")
	built["holder"].free()


func test_the_void_gives_you_back() -> void:
	var hall := _hall()
	hall.player.position = Vector3(40, -25, 40)
	hall._catch_fall()
	check(hall.player.position.distance_to(hall._arrival[0]) < 0.1, "you are put back where you arrived")
	check_eq(hall.here, "nexus", "still in the Nexus")
	hall.free()


func test_the_toad_stays_on_solid_ground() -> void:
	var hall := _hall()
	hall.player.position = Vector3(14.8, 0.05, 0.0)
	hall.player.rotation.y = 0.0  # facing north, along the rim
	for i in 30:
		hall._animate_life(0.1)
	var t: Vector3 = hall.toad["root"].position
	check(_on_ground(hall.ground, Vector2(t.x, t.z)), "the toad never hops out over the void")
	hall.free()


func test_no_fake_book_in_the_save() -> void:
	var hall := _hall()
	hall.activate(_door(hall, "greece"))
	hall.travel("nexus")
	check(not hall.progress.data["works"].has("nexus") and not hall.progress.data["works"].has("hub"), "hubs are not books")
	hall.free()


func test_progress_keeps_what_the_nexus_has_shown() -> void:
	var path := "user://test_nexus_progress.json"
	var p: RefCounted = Progress.open(path)
	p.data = {"works": {}}
	p.nexus()["points"] = 5
	p.nexus()["mastered"] = ["porphyry-isagoge"]
	p.nexus()["entered"] = true
	p.save()
	var again: RefCounted = Progress.open(path)
	check_eq(again.nexus(), {"points": 5, "mastered": ["porphyry-isagoge"], "entered": true}, "what the Nexus showed survives a restart")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"works": {}, "nexus": "garbage"}))
	f.close()
	check_eq(Progress.open(path).nexus(), {"points": 0, "mastered": [], "entered": false}, "a damaged entry starts fresh")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_the_void_has_no_sky() -> void:
	var hall := _hall()
	var envs: Array = hall.world.find_children("*", "WorldEnvironment", true, false)
	check_eq(envs.size(), 1, "one environment")
	if envs.size() == 1:
		var env: Environment = envs[0].environment
		check_eq(env.background_mode, Environment.BG_COLOR, "no sky, no horizon, no sun: only the dark")
		check_eq(env.fog_light_color, env.background_color, "far things fade into the same dark")
		check(absf(env.adjustment_saturation - 0.2) < 0.001, "almost no colour")
	hall.free()


func test_the_rift_brings_you_back_to_greeces_door() -> void:
	var hall := _hall()
	hall.activate(_door(hall, "greece"))
	check_eq(hall.here, "hub", "Greece's door leads to the Shore")
	var rift: Dictionary = hall.interactables[-1]
	check_eq(rift.get("to", ""), "nexus", "the rift is the Shore's last interactable")
	check_eq(hall.interactables[0]["to"], "porphyry-isagoge", "gateway 1 is still first")
	check(hall._nearest().get("to", "") != "nexus", "you arrive facing gateway 1, not the rift")
	hall.activate(rift)
	check_eq(hall.here, "nexus", "the rift leads back")
	check(hall.player.position.distance_to(Vector3(0, 0.05, -29.5)) < 0.1, "you arrive at Greece's door")
	check(hall.player.facing().dot(Vector3(0, 0, 1)) > 0.95, "facing the Tower")
	check(hall._nearest().get("world", "") != "greece", "the door does not prompt behind you")
	hall.free()


func test_what_you_learned_elsewhere_mends_it_when_you_return() -> void:
	var hall := _hall()
	hall.progress.learn("porphyry-isagoge", _ids("porphyry-isagoge").slice(0, 3))
	hall.travel("hub")
	hall.travel("nexus")
	check_eq(hall.restored_here, [], "you step into it as you last saw it")
	check(hall._nexus_due > 0.0, "and news is waiting")
	hall._nexus_catch_up()
	check_eq(hall.restored_here, ["ember", "path"], "then the fire and the path come back")
	check(hall._quip.contains("3 new stars"), "you are told what came back")
	check(hall._quip.split("\n").size() <= 3, "in three lines at most")
	hall.travel("hub")
	hall.travel("nexus")
	check_eq(hall._nexus_due, -1.0, "nothing is shown twice")
	hall.free()


func test_entering_greece_clears_the_hint() -> void:
	var hall := _hall()
	hall.activate(_door(hall, "greece"))
	hall.travel("nexus")
	check_eq(hall._hint, "", "you found the way; no more hint")
	hall.free()


func test_the_nexus_tablet() -> void:
	var hall := _hall()
	var text: String = hall._tablet_text()
	check(text.contains("Ideas understood: 0"), "the tablet counts your ideas")
	check(text.contains("Books mastered: 0 of 17"), "and your books")
	hall.free()


func test_you_can_sit_and_look_into_the_dark() -> void:
	var hall := _hall()
	var seats: Array = hall.interactables.filter(func(i): return i["kind"] == "seat")
	check_eq(seats.size(), 1, "one bench in the Nexus")
	if not seats.is_empty():
		hall.activate(seats[0])
		check(hall.player.seated, "you sit")
		hall.stand_up()
	hall.free()
