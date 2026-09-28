extends Node
## The world of the Great Works, in low-resolution 3D (320x180 for Greece, scaled up for the
## retro look; the words on screen get twice those pixels and the game's own lettering).
## You start on the Shore: a clifftop temple ruin over the sea at sunset, with a stone
## gateway for every book on the reading list, in order. An open gateway takes you to the
## book's own place and time (Porphyry's villa in Sicily, 270 AD, for the Isagoge): facts on
## inscribed stones, the map of the world then, busts, the book itself, and the author to
## talk to. Controls: WASD/arrows walk, Shift sprints, Q/E or left/right arrows turn, the
## mouse looks all around, F reads, asks or enters, Esc closes a panel / frees the mouse /
## twice quits.

const Rooms := preload("res://scripts/hall/rooms.gd")
const Places := preload("res://scripts/hall/places.gd")
const Nexus := preload("res://scripts/hall/nexus.gd")
const Menu := preload("res://scripts/hall/menu.gd")
const Choice := preload("res://scripts/hall/choice.gd")
const Library := preload("res://scripts/hall/library.gd")
const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Portrait := preload("res://scripts/hall/portrait.gd")
const Player := preload("res://scripts/hall/player.gd")
const Progress := preload("res://scripts/hall/progress.gd")
const Worlds := preload("res://scripts/hall/worlds.gd")
const Kit := preload("res://scripts/hall/kit.gd")
const Music := preload("res://scripts/pixel/music.gd")
const Lettering := preload("res://scripts/hall/lettering.gd")
const Beat := preload("res://scripts/hall/beat.gd")

const RES := Vector2i(320, 180)  # Greece's picture; other worlds set their own (Worlds)
const UI := Vector2i(640, 360)  # the interface: words get twice the pixels the world does
const READ_W := 520
const ASK_COL := 168  # where the teacher's words start, right of the portrait column
const ASK_W := 436
const MAP_SCALE := 2.0
const THROAT := Vector3(1.3, 0.8, 0.8)  # the toad's throat at rest, as Kit.toad shaped it
const REACH := 1.8
const GATE_REACH := 2.4
const QUIT_WINDOW := 2.0
const FADE := 0.9
const BLINK_EVERY := 45.0
const FALL_Y := -20.0  # below this you are falling through the void, for as long as you like
const FALL_ASK := 10.0  # seconds of falling before you are asked if you are ready to stop
const FALL_MAX := 30.0  # how fast you fall, at most (m/s)
const FALL_DARK := 300.0  # seconds of falling until the stars, the light and the music are all gone
const FALL_WRAP := [-1200.0, 4000.0]  # below the first, you are lifted by the second: the fall has no floor
const GRAIL_AFTER := 60.0  # AUDITION (BB1 is listening): back to 1800.0, half an hour in the Nexus, all visits together
const GRAIL_FILE := "res://assets/music/grail_voice.wav"  # "What is the secret of the grail? Who does it serve?"
const GRAIL_SLOTS := [0.0, 24.0]  # it speaks only as the prelude's loop (48 s) turns to C minor or D flat
const NEWS_DELAY := 1.5  # seconds in the Nexus before what you mended elsewhere comes back
const TEACH_BUTTONS := ["Teach me the next thing", "Say that more simply", "Give me an example", "Why does this matter?"]

var offline := false  # tests: no music, no mouse capture, instant travel
var doors: Array = []
var here := ""  # "nexus", "hub" or a work id
var areas: Array = []  # other books with ground in this place: {work, c: Vector2, r, name}
var backs := {}  # work -> the pieces of its part of this place that are back
var area := ""  # the book whose ground you stand on (here, or one of the areas)
var here_name := ""
var interactables: Array = []
var spots := {}
var player: CharacterBody3D
var world: Node3D
var author: AuthorAI
var books := {}  # work -> Library
var target := {}
var flicker: Array = []  # {light, base, seed}
var travelling := false
var progress: RefCounted  # what the player has learned (Progress)
var teacher := {}  # the author in person, if this place has one: {root, head, hand}
var people: Array = []  # everyone here in person, the teacher first
var squads: Array = []  # soldiers marching a circuit: {root, legs, path, leg, speed, step, undead}
var restored_here: Array = []  # the pieces of this place that are back (Places.back)
var _restore_pending := ""  # the place whose next piece comes back when the talk (or a fade) ends
var restored_columns := 0
var music: Node  # the zone's music and sounds (none in tests)
var birds: Array = []  # swallows: {node, wings, center, r, h, speed, angle, phase}
var sway: Array = []  # tree crowns the breeze stirs
var blink: Array = []  # the far toad's eyes, which close once every BLINK_EVERY seconds
var drift: Array = []  # things hanging in the void that bob and turn (Kit.drifting)
var ground: Array = []  # where you can stand, if the place says (the Nexus): discs and rects in x/z
var creep: Array = []  # the dead of the underworld: {node, home, trench}; they come for the blood while you are near
var _arrival: Array = [Vector3.ZERO, 0.0]  # where you came in, and facing which way
var _falling_since := -1.0  # when you went over the edge (-1: on solid ground)
var _fall_fx: Node3D  # the stars rushing past while you fall
var _fall_sky: Array = []  # the star shells, which sink with you so they never run out
var _grail: AudioStreamPlayer  # the voice in the Nexus, once it has begun
var _grail_last_pos := -1.0  # where the music was last frame, to catch it crossing a slot
var _hint := ""  # the one goal, shown when nothing else is
var _nexus_due := -1.0  # when what you mended elsewhere comes back in the Nexus (-1: nothing waiting)
var toad := {}  # your companion through every world: {root, body, throat}
var _toad_hop := 0.0
var _toad_moving := false  # lazy follow: sits until you get well ahead, then hops to its spot
var toad_hold := false  # screenshots: keep the toad where it was put
var _toad_puff := 0.0
var _quip := ""
var _quip_until := 0.0
const TOAD_QUIPS := ["The toad puffs up proudly.", "The toad blinks at you, very slowly.",
	"The toad lets out a deep, satisfied croak.", "The toad shuffles closer to your foot.",
	"The toad looks out at the sea with you."]

var _view: SubViewport
var _screen: TextureRect
var _ui: CanvasLayer
var _root: Control  # everything on screen hangs here and wears the game's lettering
var _prompt: Label
var _where: Label
var _fade: ColorRect
var _read_panel: PanelContainer
var _read_text: RichTextLabel
var _ask_panel: Panel
var _ask_portrait: TextureRect
var _ask_name: Label
var _ask_life: Label
var _answer: RichTextLabel
var _question_box: LineEdit
var _suggestions: Array = []
var _lessons: RichTextLabel
var _ask_room: Dictionary = {}
var _ask_work := ""
var _map_panel: Panel
var _map_image: TextureRect
var _map_marks: Control
var _map_title: Label
var _map_note: Label
var _tree_panel: Panel
var _menu: PanelContainer  # Esc: volume, speeds, quit (Menu)
var _choice: PanelContainer  # a world asks who you are there (Choice)
var _t := 0.0
var _args := {}
var _frames := 0
var _ok := false
var _talk := {}  # work -> what has been said there, as shown in the panel
var _quit_armed := -100.0
var _seat := {}  # the bench you are sitting on
var boats: Array = []  # boats on the waterway: {root, oars, speed, junction, landings, landing, route, to}
var _riding := {}  # the boat you are sitting in
var _mouse_before := Input.MOUSE_MODE_CAPTURED  # how the mouse was before a panel opened
var beat: RefCounted = null  # the moment being played, as its hero or as yourself (Beat)
var _beat_it := {}  # the interactable that started it
var _beat_mark: Node3D  # the glow over where a beat asks you to walk


static func ensure_actions() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"strafe_left": [KEY_A], "strafe_right": [KEY_D],
		"turn_left": [KEY_LEFT, KEY_Q], "turn_right": [KEY_RIGHT, KEY_E],
		"interact": [KEY_F, KEY_ENTER],
		"sprint": [KEY_SHIFT],
		"tablet": [KEY_T, KEY_TAB],
		"jump": [KEY_SPACE],
	}
	var pad_axes := {"move_forward": [JOY_AXIS_LEFT_Y, -1.0], "move_back": [JOY_AXIS_LEFT_Y, 1.0],
		"strafe_left": [JOY_AXIS_LEFT_X, -1.0], "strafe_right": [JOY_AXIS_LEFT_X, 1.0],
		"turn_left": [JOY_AXIS_RIGHT_X, -1.0], "turn_right": [JOY_AXIS_RIGHT_X, 1.0]}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.25)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		if pad_axes.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = pad_axes[action][0]
			m.axis_value = pad_axes[action][1]
			InputMap.action_add_event(action, m)
	for pair in [["interact", JOY_BUTTON_A], ["sprint", JOY_BUTTON_LEFT_STICK]]:
		if not InputMap.action_get_events(pair[0]).any(func(e): return e is InputEventJoypadButton):
			var b := InputEventJoypadButton.new()
			b.button_index = pair[1]
			InputMap.action_add_event(pair[0], b)


func _ready() -> void:
	ensure_actions()
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if _args.has("shot"):
		offline = true
	doors = Rooms.doors()
	if doors.is_empty():
		push_error("Could not load the reading list.")
		return
	progress = Progress.open("" if offline else Progress.PATH)
	_build_view()
	_build_ui()
	_menu = Menu.new()
	_menu.player = player
	_menu.resume = _close_panels
	_root.add_child(_menu)
	_menu.load_settings()
	_menu.switch_mode = _switch_mode
	_choice = Choice.new()
	_choice.chosen.connect(_on_chosen)
	_root.add_child(_choice)
	author = AuthorAI.new()
	author.answered.connect(_on_answer)
	author.judged.connect(_on_judged)
	add_child(author)
	if not offline:
		music = Music.new()
		add_child(music)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # look around straight away
	var back_to: String = load("res://scripts/hall/live.gd").resume if _args.has("live") else ""
	if back_to == "" and _args.has("live"):
		back_to = _args.get("resume", "")  # after F6
	_load_place(back_to if back_to != "" else ("hub" if _args.has("demo") else "nexus"))
	_ok = true
	if _args.has("live"):  # watch the files and rebuild as they change (Live)
		var live: Node = load("res://scripts/hall/live.gd").new()
		live.hall = self
		add_child(live)
	if _args.has("shot"):
		_stage_shot(_args.get("view", "hub"))
	elif _args.has("demo"):
		var demo: Node = load("res://scripts/hall/demo.gd").new()
		demo.hall = self
		if _args.get("shots", "") != "":
			demo.shots_dir = _args["shots"]
		demo.ask = not _args.has("no-ask")
		add_child(demo)
		demo.run()


## Screenshot mode for checking the look without playing:
##   godot --path . -- --shot=C:/out.png --view=nexus|hub|assets|assets_mid|props|gate|ruins|head|toad|villa|path|study|hut|map|tree|ask|read|lyceum|walk|march|lyceum_map|hill|grove|stones|yard|garden|garden_w [--stage=0-6]
## Any book's place from any spot: --view=place --work=<work id> --at=x,y,z --look=x,y,z [--stage=N]
func _stage_shot(view: String) -> void:
	if view == "place" and _args.has("stage"):
		var w: String = _args.get("work", "")
		progress.learn(w, Rooms.room(w).get("lesson", []).slice(0, int(_args["stage"])).map(func(p): return p["id"]))
	elif _args.has("stage"):  # --stage=N: see the places with N pieces brought back
		for d in doors.slice(0, 2):
			progress.learn(d["work"], Rooms.room(d["work"]).get("lesson", []).slice(0, int(_args["stage"])).map(func(p): return p["id"]))
		if view in ["hill", "grove"]:  # the two areas past the Lyceum keep their own stage
			var extra: String = Places.ORGANON if view == "hill" else Places.ETHICS
			progress.learn(extra, Rooms.room(extra).get("lesson", []).slice(0, int(_args["stage"])).map(func(p): return p["id"]))
	if view in ["lyceum", "walk", "lyceum_map", "march", "hill", "grove", "stones", "yard"]:
		_load_place(doors[1]["work"])
	elif view in ["hub", "gate", "ruins", "head", "toad"]:
		_load_place("hub")
	elif view in ["assets", "assets_mid", "props"]:
		_load_place("asset_test")
	elif view == "place":
		_load_place(_args.get("work", doors[0]["work"]))
	elif view != "nexus":  # the Nexus is where the game starts
		_load_place(doors[0]["work"])
	match view:
		"place":
			_stand(_vec(_args.get("at", "0,0,20")), _vec(_args.get("look", "0,0,0")))
			if _args.has("beat"):  # --beat=<name> [--press=N]: start that beat and go N steps into it
				var it: Array = interactables.filter(func(i): return i["kind"] == "beat" and i["beat"] == _args["beat"])
				if not it.is_empty():
					activate(it[0])
					for k in int(_args.get("press", "0")):
						if beat == null:
							break
						var mark: Variant = beat.next_mark()
						if mark != null:
							player.position = Vector3(mark.x, player.position.y, mark.z)
						beat.press(player)
						_play_beat(2.0, true)
		"assets":
			_stand(Vector3(0, 0, 1.5), Vector3(0, 0, -20))
		"assets_mid":
			_stand(Vector3(0, 0, -40), Vector3(0, 0, -60))
		"props":
			_stand(Vector3(0, 0, -89), Vector3(0, 0, -100))
		"lyceum":
			_stand(Vector3(1.5, 0, 16), Vector3(-6, 0, -8))
		"walk":
			_stand(Vector3(-6.5, 0, 9.5), Vector3(-6.5, 0, -10))
			people[0]["root"].position = Vector3(-6.5, 0, 4.0)
			people[0]["root"].rotation.y = 0.0
		"march":
			_stand(Vector3(33.2, 0, 14.0), Vector3(30.5, 0, 16.6))  # close, on their shield side
		"lyceum_map":
			_stand(spots["map"], spots["map"] + Vector3(-5, 0, 0))
			activate(interactables.filter(func(i): return i["kind"] == "map")[0])
		"gate":
			_stand(spots["gate0"], Places.gate_spot(0))
		"ruins":
			_stand(Vector3(3, 0, 8), Vector3(-60, 0, -95))
		"head":
			_stand(Vector3(6, 0, 3), Vector3(14, 0, 12))
		"toad":
			_stand(Vector3(-27.5, 0, 3.0), Vector3(-40, 0, 3.0))
			toad_hold = true
			toad["root"].position = Vector3(-28.9, 0.02, 3.35)
			toad["root"].rotation.y = PI * 0.62
			player.camera.rotation.x = -0.42
		"path":
			_stand(Vector3(0, 0, 19), Vector3(0, 0, 0))
		"villa":
			_stand(Vector3(0, 0, 8), Vector3(0, 0, -10))
		"study", "ask":
			_stand(spots["study"], Vector3(0, 0, -18))
		"hut":
			_stand(Vector3(4.2, 0, -19.0), Vector3(1.6, 0, -21.6))
		"map":
			_stand(spots["map"], spots["map"] + Vector3(-5, 0, 0))
			activate(interactables.filter(func(i): return i["kind"] == "map")[0])
		"tree":
			activate(interactables.filter(func(i): return i["kind"] == "tree")[0])
		"read":
			_stand(spots["fact1"], spots["fact1"] + Vector3(5, 0, 0))
			activate(interactables.filter(func(i): return i["kind"] == "fact")[1])
		"hill":
			_stand(Places.ORGANON_AT + Vector3(1.5, Places.HILL_TOP, -1.5), Places.ORGANON_AT + Vector3(3.5, Places.HILL_TOP, -7.8))
		"grove":
			_stand(Places.ETHICS_AT + Vector3(0, 0, 15), Places.ETHICS_AT)
		"stones":  # the ring of the ten kinds, by the way in
			_stand(Vector3(-1.5, 0, 23.5), Vector3(-7, 0, 19.5))
		"yard":  # the lesson stones behind the walkway
			_stand(Vector3(-12.5, 0, 13.5), Vector3(-17, 0, -4))
		"garden":  # the villa's lesson stones in the gardens
			_stand(Vector3(6.0, 0, 22.0), Vector3(17.0, 0, 5.0))
		"garden_w":
			_stand(Vector3(-6.0, 0, 21.0), Vector3(-18.0, 0, 4.0))
	if view == "ask":
		_open_ask(doors[0]["work"])
		_talk[doors[0]["work"]] = _you("What's the difference between genus and species?") + "\n\n[color=#e0b660]Porphyry:[/color] Genus is the wide family, like animal. Species is one kind inside it, like human. What splits them is the difference: being able to reason."
		_answer.text = _talk[doors[0]["work"]]


static func _vec(text: String) -> Vector3:
	var n := text.split(",")
	return Vector3(float(n[0]), float(n[1]), float(n[2])) if n.size() == 3 else Vector3.ZERO


func _stand(at: Vector3, look_at: Vector3) -> void:
	player.position = Vector3(at.x, at.y + 0.05, at.z)
	player.rotation.y = Places.look_yaw(look_at - at)


# ---------- the world and travel ----------

func _build_view() -> void:
	_view = SubViewport.new()
	_view.size = RES
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	world = Node3D.new()
	_view.add_child(world)
	player = Player.new()
	_view.add_child(player)
	player.camera.current = true
	toad = Kit.toad(_view)


## Walk through a gateway: fade out, build the other place, fade in.
func travel(to: String) -> void:
	if travelling:
		return
	if offline:
		_load_place(to)
		return
	await _fade_through(Color.BLACK, FADE, FADE * 1.5, _load_place.bind(to))


## Covers the screen in a colour, runs `build` while it is covered, and uncovers it again.
## Only one at a time (travelling), and the player cannot move meanwhile.
func _fade_through(color: Color, out_s: float, in_s: float, build: Callable) -> void:
	travelling = true
	player.frozen = true
	_fade.color = Color(color.r, color.g, color.b, 0.0)
	var cover := create_tween()
	cover.tween_property(_fade, "color:a", color.a, out_s)
	await cover.finished
	build.call()
	var uncover := create_tween()
	uncover.tween_property(_fade, "color:a", 0.0, in_s)
	await uncover.finished
	_fade.color = Color(0, 0, 0, 0)
	player.frozen = _any_panel()
	travelling = false


func _load_place(to: String, keep: bool = false) -> void:
	if beat:
		_end_beat(false)
	var held := _where_everyone_is() if keep else {}
	var area_target := ""
	if not to in ["hub", "nexus"] and Rooms.room(to).get("area_of", "") != "":
		area_target = to  # a book that is part of another's place: go there, to its ground
		to = Rooms.room(to)["area_of"]
	var from := here
	if not keep:
		_restore_pending = ""  # a piece of the place you are leaving waits for your return
		if from == "nexus" and to != "nexus":
			_leave_nexus()
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()
	var world_id: String = "greece"
	if to == "nexus":
		world_id = Nexus.world_reached(progress)
	elif not to in ["hub", "asset_test"]:
		world_id = Rooms.room(to).get("world", "greece")
	_view.size = Worlds.render_size(world_id, DisplayServer.window_get_size())
	Kit.detail = Worlds.detail(world_id)
	var built: Dictionary
	if to == "nexus":
		built = Nexus.build(world, Worlds.all(), doors, _nexus_shown(keep))
	elif to == "hub":
		built = Places.hub(world, doors, progress)
	elif to == "asset_test":
		built = Places.asset_test(world)
	else:
		var stages := {}
		for d in doors:
			if Rooms.room(d["work"]).get("area_of", "") == to:
				stages[d["work"]] = _stage(d["work"])
		built = Places.place(world, to, Rooms.room(to), _stage(to), stages)
	if not to in ["hub", "nexus", "asset_test"] and not keep:
		progress.visit(to)
		progress.save()
	here = to
	restored_here = built.get("back", [])
	areas = built.get("areas", [])
	backs = built.get("backs", {})
	area = ""  # worked out again on the next frame
	if music:
		music.play(_zone(to), restored_here)
	people = built.get("people", [])
	squads = built.get("squads", [])
	boats = built.get("boats", [])
	teacher = people[0] if not people.is_empty() else {}
	restored_columns = built.get("restored", 0)
	here_name = built["name"]
	interactables = built["interactables"]
	spots = built["spots"]
	birds = built.get("birds", [])
	sway = built.get("sway", [])
	blink = built.get("blink", [])
	drift = built.get("drift", [])
	ground = built.get("ground", [])
	creep = built.get("creep", [])
	flicker.clear()
	for l in built["flicker"]:
		if l:
			flicker.append({"light": l, "base": l.light_energy, "seed": randf() * 10.0})
	player.stand()
	_seat = {}
	_riding = {}
	if music:
		music.swell(false)
	if keep:
		_put_back(held)
	else:
		_arrival = built.get("arrivals", {}).get(from, [built["spawn"], built["yaw"]])
		player.position = _arrival[0]
		player.rotation.y = _arrival[1]
		for a in areas:
			if a["work"] == area_target:
				player.position = Vector3(a["c"].x, 0.05, a["c"].y + a["r"] - 3.0)
		_toad_to_heel()
	player.velocity = Vector3.ZERO
	target = {}
	if _where:
		_where.text = here_name
	if to == "nexus" and not keep:
		_arrive_in_nexus()
	if not keep:
		_ask_mode()


## The book whose ground you are standing on: one of this place's areas, or the place's own book.
func _work_here() -> String:
	var at := Vector2(player.position.x, player.position.z)
	for a in areas:
		if at.distance_to(a["c"]) <= a["r"]:
			return a["work"]
	return here


## Crossing from one book's ground to another's: its name in the corner, its teacher at his age,
## and its music as far as its part of the place is back.
func _check_area() -> void:
	var now := _work_here()
	if now == area:
		return
	area = now
	for p in people:
		if p.has("area") and is_instance_valid(p["root"]):
			p["root"].visible = p["area"] == area
	var name := here_name
	for a in areas:
		if a["work"] == area:
			name = a["name"]
	if _where:
		_where.text = name
	if music and not here in ["hub", "nexus"]:
		music.play(_zone(area), backs.get(area, restored_here))


## The world a place belongs to ("" for the Nexus, which is above them all).
func _world_of(place: String) -> String:
	if place == "nexus":
		return ""
	if place == "hub":
		return "greece"
	return str(Rooms.room(place).get("world", "greece"))


## The first time you enter a world, it asks who you are there, in its own words.
func _ask_mode() -> void:
	var w := _world_of(here)
	if w == "" or progress.mode(w) != "" or offline or _args.has("demo"):
		return
	var modes: Dictionary = Worlds.settings(w).get("modes", {})
	if modes.is_empty():
		return
	_choice.ask(modes)
	_show_panel(_choice)


func _on_chosen(mode: String) -> void:
	progress.set_mode(_world_of(here), mode)
	progress.save()
	_choice.hide()
	_close_panels()


## The name of the way you walk this world, in its own words: "Theoros", "Mathetes".
func _mode_name(w: String, mode: String) -> String:
	return str(Worlds.settings(w).get("modes", {}).get(mode, {}).get("name", mode.capitalize()))


func _mode_line() -> String:
	var w := _world_of(here)
	var mode: String = progress.mode(w) if w != "" else ""
	if mode == "":
		return ""
	var other := "student" if mode == "zen" else "zen"
	return "You are %s. Be %s instead" % [_mode_name(w, mode), _mode_name(w, other)]


## From the Esc menu: the other way, for this world, from now on. Nothing mended is undone.
func _switch_mode() -> void:
	var w := _world_of(here)
	if w == "" or progress.mode(w) == "":
		return
	progress.set_mode(w, "student" if progress.mode(w) == "zen" else "zen")
	progress.save()
	_menu.show_mode(_mode_line())


func _zone(place: String) -> String:
	if place == "hub":
		return "shore"
	if place == "nexus":
		return "nexus"
	return Rooms.room(place).get("zone", "shore")


# ---------- the Nexus ----------

## What the Nexus shows as you step in: what it showed you last time, so what you mended elsewhere
## comes back before your eyes; or all of it, once that has been shown (keep).
func _nexus_shown(keep: bool) -> Dictionary:
	var now := Nexus.now(progress, doors)
	if keep or not _behind(now):
		return now
	var seen: Dictionary = progress.nexus()
	return {"points": seen["points"], "mastered": seen["mastered"]}


## True when you have mended more than the Nexus has shown you yet.
func _behind(now: Dictionary) -> bool:
	var seen: Dictionary = progress.nexus()
	return int(seen["points"]) < int(now["points"]) or (seen["mastered"] as Array).size() < (now["mastered"] as Array).size()


func _arrive_in_nexus() -> void:
	var c := Nexus.content()
	_hint = "" if progress.nexus()["entered"] else str(c.get("hint", ""))
	if not progress.nexus()["entered"]:
		_quip = str(c.get("first", ""))
		_quip_until = _t + 6.0
	var now := Nexus.now(progress, doors)
	if _behind(now):
		_nexus_due = _t + NEWS_DELAY
	else:
		_nexus_due = -1.0
		_remember_nexus(now)


## Time in the Nexus adds up across visits. After half an hour a voice begins asking, over the
## music, again and again while you stay.
func _nexus_clock(delta: float) -> void:
	if here != "nexus" or offline:
		return
	var seen: Dictionary = progress.nexus()
	seen["seconds"] = float(seen["seconds"]) + delta
	if seen["seconds"] < GRAIL_AFTER or not ResourceLoader.exists(GRAIL_FILE):
		return
	if _grail == null:
		_grail = AudioStreamPlayer.new()
		_grail.stream = load(GRAIL_FILE)
		_grail.volume_db = -3.0
		_grail.bus = Music.BUS  # in the same echoing space as the prelude
		_grail.finished.connect(func() -> void: if music: music.duck(false))
		add_child(_grail)
	var pos: float = music.position() if music else 0.0
	var crossed := false
	for slot in GRAIL_SLOTS:
		if _grail_last_pos >= 0.0 and ((_grail_last_pos < slot and pos >= slot) or (slot == 0.0 and pos < _grail_last_pos)):
			crossed = true
	_grail_last_pos = pos
	if crossed and not _grail.playing:
		_grail.play()
		if music:
			music.duck(true)


## Out through a door: you have found the way, so the hint is done with.
func _leave_nexus() -> void:
	if _grail:
		_grail.stop()
		_grail_last_pos = -1.0
		if music:
			music.duck(false)
	progress.save()  # keeps the time spent here
	_nexus_due = -1.0
	_hint = ""
	if not progress.nexus()["entered"]:
		progress.nexus()["entered"] = true
		progress.save()


func _remember_nexus(state: Dictionary) -> void:
	var seen: Dictionary = progress.nexus()
	if int(seen["points"]) == int(state["points"]) and seen["mastered"] == state["mastered"]:
		return
	seen["points"] = int(state["points"])
	seen["mastered"] = (state["mastered"] as Array).duplicate()
	progress.save()


## What you mended elsewhere comes back now: the Nexus is rebuilt round you as it truly stands,
## and up to three lines say what returned (the last two pieces, then the stars and columns).
func _nexus_catch_up() -> void:
	_nexus_due = -1.0
	if here != "nexus":
		return
	var seen: Dictionary = progress.nexus().duplicate(true)
	var before := restored_here.duplicate()
	if offline:
		_load_place("nexus", true)
	else:
		await _fade_through(Color(1.0, 0.94, 0.8, 0.6), 0.5, 1.8, _load_place.bind("nexus", true))
	var now := Nexus.now(progress, doors)
	var c := Nexus.content()
	var pieces: Array = []
	for r in c.get("restores", []):
		if restored_here.has(r["what"]) and not before.has(r["what"]):
			pieces.append(r["line"])
	var sky: Array = []
	var stars := int(now["points"]) - int(seen["points"])
	if stars > 0:
		sky.append(str(c.get("star", "")) if stars == 1 else str(c.get("stars", "")).format({"n": stars}))
	var k: int = (now["mastered"] as Array).size()
	var cols := k - (seen["mastered"] as Array).size()
	if cols > 0:
		sky.append((str(c.get("column", "")) if cols == 1 else str(c.get("columns", ""))).format({"n": cols, "k": k}))
	var lines: Array = pieces.slice(maxi(0, pieces.size() - 2))
	if not sky.is_empty():
		lines.append(" ".join(sky))
	if not lines.is_empty():
		_quip = "\n".join(lines)
		_quip_until = _t + 7.0
	_remember_nexus(now)


## Over the edge: you fall through endless dark, stars rushing past, until you say you are
## ready to stop. The world wraps round you far below so the fall never ends.
func _catch_fall() -> void:
	if _falling_since < 0.0:
		if player.position.y > FALL_Y:
			return
		if here != "nexus":  # only the Nexus opens onto the void; anywhere else, straight back
			player.position = _arrival[0]
			player.rotation.y = _arrival[1]
			player.velocity = Vector3.ZERO
			return
		_falling_since = _t
		_fall_sky = world.find_children("*", "MultiMeshInstance3D", true, false)
		_fall_fx = Node3D.new()
		player.add_child(_fall_fx)
		for layer in [["mote", 160, 0.08], ["mote_gold", 40, 0.14], ["ash", 60, 0.5]]:
			var p := Kit._drift(_fall_fx, Vector3(0, -30, 0), layer[1], 2.2, layer[2], layer[0], Vector3.UP, 4.0, Vector2(24.0, 34.0))
			p.local_coords = true
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(14, 2, 14)
			p.preprocess = 2.0
	player.velocity.y = maxf(player.velocity.y, -FALL_MAX)
	if player.position.y < FALL_WRAP[0]:  # far below everything but the stars, which come with you
		player.position.y += FALL_WRAP[1]
	for sky in _fall_sky:
		if is_instance_valid(sky):
			sky.position.y = minf(0.0, player.position.y)
	_fall_fade(clampf((_t - _falling_since) / FALL_DARK, 0.0, 1.0))


## How far the long fall has gone into the dark (0 to 1): the rushing stars thin out, the
## picture sinks to black and the music dies away, all slowly, as if from very far off.
func _fall_fade(k: float) -> void:
	var gone := k * k  # slow at first, then the last of it goes
	for env in world.find_children("*", "WorldEnvironment", true, false):
		if env.environment:
			env.environment.adjustment_brightness = 1.0 - gone
	if is_instance_valid(_fall_fx):
		for p in _fall_fx.get_children():
			(p as CPUParticles3D).scale_amount_min = maxf(0.0, 1.0 - gone)  # they dwindle to nothing
			(p as CPUParticles3D).scale_amount_max = maxf(0.0, 1.0 - gone)
	var bus := AudioServer.get_bus_index(Music.BUS)
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(1.0 - gone, 0.0001)))


func _ready_to_land() -> bool:
	return _falling_since >= 0.0 and _t - _falling_since >= FALL_ASK


## You said you were ready: back on the ground where you came in.
func _stop_falling() -> void:
	var land := func() -> void:
		_falling_since = -1.0
		if is_instance_valid(_fall_fx):
			_fall_fx.queue_free()
		_fall_fade(0.0)
		for sky in _fall_sky:
			if is_instance_valid(sky):
				sky.position.y = 0.0
		_fall_sky = []
		player.position = _arrival[0]
		player.rotation.y = _arrival[1]
		player.velocity = Vector3.ZERO
	if offline:
		land.call()
	else:
		await _fade_through(Color.BLACK, 1.2, 1.5, land)


static func _on_ground(shapes: Array, p: Vector2) -> bool:
	for g in shapes:
		if g.has("rect"):
			if (g["rect"] as Rect2).has_point(p):
				return true
		elif p.distance_to(g["c"]) <= g["r"]:
			return true
	return false


## The nearest point to `p` that is on the ground, `inset` metres in from its edge (`p` itself
## when it is on the ground already, or when the place has no edges).
static func _to_ground(shapes: Array, p: Vector2, inset: float = 0.5) -> Vector2:
	if shapes.is_empty() or _on_ground(shapes, p):
		return p
	var best := p
	var best_d := INF
	for g in shapes:
		var q: Vector2
		if g.has("rect"):
			var r: Rect2 = (g["rect"] as Rect2).grow(-inset)
			q = Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
		else:
			q = g["c"] + (p - g["c"]).limit_length(maxf(0.0, g["r"] - inset))
		if p.distance_to(q) < best_d:
			best = q
			best_d = p.distance_to(q)
	return best


## How many pieces of a book's place are back: one for each lesson point understood.
func _stage(work: String) -> int:
	var room := Rooms.room(work)
	var ids: Array = room.get("lesson", []).map(func(p): return p["id"])
	var have: int = progress.understood(work).filter(func(id): return ids.has(id)).size()
	return mini(have, room.get("restores", []).size())


## Where you, the people and the soldiers are, so a place can be rebuilt around you.
func _where_everyone_is() -> Dictionary:
	var at := func(d: Dictionary) -> Array:
		return [d["root"].position, d["root"].rotation.y, d.get("leg", 0)] if is_instance_valid(d.get("root")) else []
	return {"player": [player.position, player.rotation.y], "people": people.map(at), "squads": squads.map(at), "boats": boats.map(at)}


func _put_back(held: Dictionary) -> void:
	player.position = held["player"][0]
	player.rotation.y = held["player"][1]
	for group in [["people", people], ["squads", squads], ["boats", boats]]:
		var was: Array = held.get(group[0], [])
		for i in mini(was.size(), group[1].size()):
			if was[i].is_empty():
				continue
			group[1][i]["root"].position = was[i][0]
			group[1][i]["root"].rotation.y = was[i][1]
			group[1][i]["leg"] = was[i][2]


## What you came to understand brings a piece of this place back: a wash of warm light, and
## there it is, with a line saying what returned.
func _restore() -> void:
	_restore_pending = ""
	if travelling:
		_restore_pending = here  # after the fade that is running
		return
	var before := backs.duplicate(true)
	if before.is_empty():
		before = {here: restored_here.duplicate()}
	if offline:
		_load_place(here, true)
	else:
		await _fade_through(Color(1.0, 0.94, 0.8, 0.85), 0.6, 1.8, _load_place.bind(here, true))
	var after := backs if not backs.is_empty() else {here: restored_here}
	var lines: Array = []
	for w in after:
		for r in Rooms.room(w).get("restores", []):
			if after[w].has(r["what"]) and not before.get(w, []).has(r["what"]):
				lines.append(r["line"])
	if not lines.is_empty():
		_quip = "\n".join(lines)
		_quip_until = _t + 6.0
	if _restore_pending == here and not _any_panel():
		_restore()


# ---------- interface ----------

static func _style(alpha: float = 0.92, border: Color = Color("3a3542")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.03, 0.045, alpha)
	s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


## A label in the scribe's hand, or in inscription capitals for names and titles.
static func _label(col: Color, capitals: bool = false) -> Label:
	var l := Label.new()
	if capitals:
		Lettering.capitals(l)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The interface draws at UI (640x360) over the world picture, whatever size that world renders
## at: Greece's 320x180 is doubled to fill it, sharper worlds fit it exactly.
func _build_ui() -> void:
	_screen = TextureRect.new()
	_screen.texture = _view.get_texture()
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.size = Vector2(UI)
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_root = Control.new()
	_root.theme = Lettering.theme()
	_root.size = Vector2(UI)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	var dot := ColorRect.new()
	dot.color = Color(0.9, 0.85, 0.7, 0.5)
	dot.size = Vector2(2, 2)
	dot.position = Vector2(UI) / 2.0 - Vector2(1, 1)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE  # the locked mouse sits right here
	_root.add_child(dot)
	_where = _label(Color("f0d8b0"), true)
	_where.position = Vector2(10, 6)
	_root.add_child(_where)
	_prompt = _label(Color("f4ead6"), true)
	_prompt.position = Vector2(20, 284)
	_prompt.size = Vector2(UI.x - 40, 68)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_prompt)
	_read_panel = PanelContainer.new()
	_read_panel.add_theme_stylebox_override("panel", _style())
	_read_panel.position = Vector2(60, 48)
	_read_panel.custom_minimum_size = Vector2(READ_W, 0)
	_read_panel.size = Vector2(READ_W, 0)
	_read_panel.hide()
	_root.add_child(_read_panel)
	_read_text = RichTextLabel.new()
	_read_text.bbcode_enabled = true
	_read_text.fit_content = true
	_read_text.custom_minimum_size = Vector2(READ_W - 24, 0)
	_read_text.add_theme_color_override("default_color", Color("e8dcc0"))
	_read_panel.add_child(_read_text)
	_build_ask_panel()
	_build_map_panel()
	_build_tree_panel()
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(UI)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)


func _build_ask_panel() -> void:
	_ask_panel = Panel.new()
	_ask_panel.add_theme_stylebox_override("panel", _style(0.95))
	_ask_panel.position = Vector2(12, 12)
	_ask_panel.size = Vector2(UI.x - 24, UI.y - 24)
	_ask_panel.hide()
	_root.add_child(_ask_panel)
	_ask_portrait = TextureRect.new()
	_ask_portrait.position = Vector2(16, 16)
	_ask_portrait.size = Vector2(96, 128)
	_ask_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ask_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_ask_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ask_panel.add_child(_ask_portrait)
	_ask_name = _label(Color("e0b660"), true)
	_ask_name.position = Vector2(16, 148)
	_ask_name.size = Vector2(112, 20)
	_ask_panel.add_child(_ask_name)
	_ask_life = _label(Color("a6c8cc"))
	_ask_life.position = Vector2(16, 170)
	_ask_life.size = Vector2(120, 16)
	_ask_panel.add_child(_ask_life)
	_lessons = RichTextLabel.new()
	_lessons.bbcode_enabled = true
	_lessons.position = Vector2(12, 190)
	_lessons.size = Vector2(ASK_COL - 12, 120)
	_lessons.scroll_active = false
	_lessons.add_theme_color_override("default_color", Color("8a8074"))
	_ask_panel.add_child(_lessons)
	var hint := _label(Color("8a8074"))
	hint.text = "Esc to leave"
	hint.position = Vector2(16, 316)
	_ask_panel.add_child(hint)
	_answer = RichTextLabel.new()
	_answer.bbcode_enabled = true
	_answer.position = Vector2(ASK_COL, 16)
	_answer.size = Vector2(ASK_W, 196)
	_answer.add_theme_color_override("default_color", Color("e8dcc0"))
	_ask_panel.add_child(_answer)
	for k in 4:
		var b := Button.new()
		b.position = Vector2(ASK_COL + (k % 2) * (ASK_W / 2 + 2), 216 + (k / 2) * 26)
		b.custom_minimum_size = Vector2(ASK_W / 2 - 2, 22)
		b.size = Vector2(ASK_W / 2 - 2, 22)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_stylebox_override("normal", _style(0.9))
		b.add_theme_stylebox_override("hover", _style(0.9, Color("e0b660")))
		b.add_theme_stylebox_override("focus", _style(0.9, Color("e0b660")))
		b.add_theme_color_override("font_color", Color("d6ccba"))
		b.pressed.connect(func(): _send(b.text))
		_ask_panel.add_child(b)
		_suggestions.append(b)
	_question_box = LineEdit.new()
	_question_box.position = Vector2(ASK_COL, 274)
	_question_box.size = Vector2(ASK_W, 32)
	_question_box.placeholder_text = "Type your own question, then Enter"
	_question_box.add_theme_stylebox_override("normal", _style(0.9, Color("5a5060")))
	_question_box.add_theme_stylebox_override("focus", _style(0.9, Color("e0b660")))
	_question_box.text_submitted.connect(func(q: String): _send(q))
	_ask_panel.add_child(_question_box)


func _build_map_panel() -> void:
	_map_panel = Panel.new()
	_map_panel.add_theme_stylebox_override("panel", _style(0.96))
	_map_panel.position = Vector2(8, 8)
	_map_panel.size = Vector2(UI.x - 16, UI.y - 16)
	_map_panel.hide()
	_root.add_child(_map_panel)
	_map_title = _label(Color("e0b660"), true)
	_map_title.position = Vector2(16, 6)
	_map_panel.add_child(_map_title)
	_map_image = TextureRect.new()
	_map_image.position = Vector2(12, 28)
	_map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_image.stretch_mode = TextureRect.STRETCH_SCALE
	_map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_panel.add_child(_map_image)
	_map_marks = Control.new()
	_map_marks.position = _map_image.position
	_map_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_marks)
	_map_note = _label(Color("e8dcc0"))
	_map_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_panel.add_child(_map_note)
	_map_note.position = Vector2(456, 32)
	_map_note.custom_minimum_size = Vector2(160, 0)
	_map_note.size = Vector2(160, 260)
	var hint := _label(Color("8a8074"))
	hint.text = "F to close"
	hint.position = Vector2(UI.x - 88, 324)
	_map_panel.add_child(hint)


## The map is drawn at MAP_SCALE times its pixel size; names and pins follow.
func _open_map(it: Dictionary) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/maps/%s.json" % it["map"]))
	if not data is Dictionary:
		return
	var tex: Texture2D = load("res://assets/maps/%s.png" % it["map"])
	_map_image.texture = tex
	_map_image.size = tex.get_size() * MAP_SCALE
	_map_title.text = data["title"]
	_map_note.text = it.get("note", "")
	for c in _map_marks.get_children():
		c.queue_free()
	for r in data["regions"]:
		_mark(Vector2(r["label"][0], r["label"][1]) * MAP_SCALE, r["name"], Color("fff4e0"), true, true)
	for o in data["others"]:
		_mark(Vector2(o["label"][0], o["label"][1]) * MAP_SCALE, o["name"], Color("4a3e2c"), false, true)
	for p in data["pins"]:
		var at := Vector2(p["at"][0], p["at"][1]) * MAP_SCALE
		var dot := ColorRect.new()
		dot.color = Color("ffe070") if p["main"] else Color("f4f0e8")
		dot.size = Vector2(6, 6) if p["main"] else Vector2(4, 4)
		dot.position = at - dot.size / 2.0
		_map_marks.add_child(dot)
		var col := Color("ffe070") if p["main"] else Color("f4f0e8")
		match p.get("side", "right"):  # where the name sits so neighbours do not collide
			"left":
				_mark(at + Vector2(-6 - Lettering.width(p["name"]), -8), p["name"], col, false, false)
			"above":
				_mark(at + Vector2(0, -16), p["name"], col, false, true)
			"below":
				_mark(at + Vector2(0, 12), p["name"], col, false, true)
			_:
				_mark(at + Vector2(6, -8), p["name"], col, false, false)
	_show_panel(_map_panel)


## A name on the map; a long inscription breaks onto two lines so it stays over its land.
func _mark(at: Vector2, text: String, col: Color, capitals: bool, centred: bool) -> void:
	var l := _label(col, capitals)
	var lines: Array = [text]
	if capitals and Lettering.width(text, true) > 160 and text.contains(" "):
		var cut := text.rfind(" ", text.length() / 2 + 2)
		lines = [text.left(cut), text.substr(cut + 1)]
	l.text = "\n".join(lines)
	if centred:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_marks.add_child(l)
	var w := 0.0
	for line in lines:
		w = maxf(w, Lettering.width(line, capitals))
	l.position = at - (Vector2(w / 2.0, 7) if centred else Vector2.ZERO)


## Porphyry's Tree, the book's most famous picture: follow the family down, adding one
## difference at a time, until you reach a human, and then single people.
class TreeCanvas extends Control:
	const ROWS := [["Substance", "", "not bodily: spirit"], ["Body", "bodily", "not living: stone"],
		["Living body", "alive", "cannot feel: plant"], ["Animal", "feels", "cannot reason: beast"],
		["Human", "reasons", ""], ["Socrates, Plato...", "", ""]]

	func _draw() -> void:
		var ink := Color("e8dcc0")
		var gold := Color("e0b660")
		var dim := Color("a89878")
		for i in ROWS.size():
			var y := 28.0 + i * 40.0
			var x := 140.0
			if i > 0:
				draw_line(Vector2(x + 16, y - 32), Vector2(x + 16, y - 12), dim, 2.0)
				if ROWS[i][1] != "":
					draw_string(Lettering.SCRIBE, Vector2(x + 24, y - 16), "+ " + ROWS[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY, gold)
			draw_string(Lettering.LAPIDARY, Vector2(x, y + 8), ROWS[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.TITLE, ink)
			if ROWS[i][2] != "":
				draw_line(Vector2(x + 190, y + 2), Vector2(x + 250, y + 2), dim, 2.0)
				draw_string(Lettering.SCRIBE, Vector2(x + 258, y + 8), ROWS[i][2], HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY, dim)


func _build_tree_panel() -> void:
	_tree_panel = Panel.new()
	_tree_panel.add_theme_stylebox_override("panel", _style(0.96))
	_tree_panel.position = Vector2(8, 8)
	_tree_panel.size = Vector2(UI.x - 16, UI.y - 16)
	_tree_panel.hide()
	_root.add_child(_tree_panel)
	var title := _label(Color("e0b660"), true)
	title.text = "Porphyry's Tree"
	title.position = Vector2(16, 6)
	_tree_panel.add_child(title)
	var canvas := TreeCanvas.new()
	canvas.position = Vector2(0, 28)
	canvas.size = Vector2(UI.x - 16, 248)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tree_panel.add_child(canvas)
	var note := _label(Color("e8dcc0"))
	note.text = "To say what a human is, walk down the family and add one difference at each step: a living body that feels and reasons. The genus is the family; the species is where you stop."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tree_panel.add_child(note)
	note.position = Vector2(16, 278)
	note.custom_minimum_size = Vector2(UI.x - 128, 0)
	note.size = Vector2(UI.x - 128, 60)
	var hint := _label(Color("8a8074"))
	hint.text = "F to close"
	hint.position = Vector2(UI.x - 88, 316)
	_tree_panel.add_child(hint)


func _open_ask(work: String) -> void:
	_ask_work = work
	_ask_room = Rooms.room(work).duplicate()
	_ask_room["state"] = _state_note(work)
	_ask_portrait.texture = Portrait.make(_ask_room.get("portrait", {}))
	_ask_name.text = _ask_room["author"]
	_ask_life.text = _ask_room["life"]
	var qs: Array = TEACH_BUTTONS if _ask_room.has("lesson") else _ask_room.get("questions", [])
	for k in _suggestions.size():
		_suggestions[k].visible = k < qs.size()
		if k < qs.size():
			_suggestions[k].text = qs[k]
	if not _talk.has(work):
		_talk[work] = "[color=#e0b660]%s:[/color] %s" % [_ask_room["author"], _esc(_greeting(work))]
	_answer.text = _talk[work]
	_refresh_lessons()
	_show_panel(_ask_panel)
	_question_box.grab_focus()


func _send(question: String) -> void:
	question = question.strip_edges()
	if question == "" or author.busy:
		return
	_question_box.text = ""
	_talk[_ask_work] = "%s\n\n[i]%s is thinking...[/i]" % [_you(question), _ask_room["author"]]
	_answer.text = _talk[_ask_work]
	author.ask(_ask_work, _ask_room, _book(_ask_work), question, progress.understood(_ask_work), progress.visits(_ask_work))


## What the teacher is told about his place as it is now: lost, partly back, or whole.
func _state_note(work: String) -> String:
	var room := Rooms.room(work)
	var restores: Array = room.get("restores", [])
	if restores.is_empty():
		return ""
	var home: String = room.get("home", "home")
	var stage := _stage(work)
	if stage >= restores.size():
		return "Where you are now: your %s is alive. That is simply how it is." % home
	var back: Array = restores.slice(0, stage)
	var himself := back.any(func(r): return r["what"] == "teacher")
	var note := "Where you are now: your %s has faded almost out of the world, and %s." % [
		home, "you are yourself" if himself else "you are only a pale shade of yourself"]
	if not back.is_empty():
		note += " As it stands: %s" % " ".join(back.map(func(r): return r["line"]))
	return note + " That is simply how things are. Never promise the visitor it will change or say what would change it; never hope aloud. You may remark on it once, flatly, in a few words."


## His first words: a greeting the first time, a welcome back that picks up where you left off.
func _greeting(work: String) -> String:
	var room := Rooms.room(work)
	var have: Array = progress.understood(work)
	if progress.is_mastered(work):
		return "You again, my friend. You know my little book as well as I do now. Ask me anything."
	if have.is_empty():
		return room.get("greeting_lost", room.get("greeting", "Ask me anything about my book."))
	var done: Array = room.get("lesson", []).filter(func(p): return have.has(p["id"])).map(func(p): return p["label"])
	return "Back again? Last time you came to understand: %s. Shall we go on?" % ", ".join(done).to_lower()


## The lesson points under the portrait: gold once you understand them.
func _refresh_lessons() -> void:
	var lesson: Array = _ask_room.get("lesson", [])
	if lesson.is_empty():
		_lessons.text = ""
		return
	var have: Array = progress.understood(_ask_work)
	var lines: Array = ["[color=#a6c8cc]Lesson %d / %d[/color]" % [have.size(), lesson.size()]]
	for p in lesson:
		lines.append(("[color=#e0b660]+ %s[/color]" if have.has(p["id"]) else "- %s") % p["label"])
	_lessons.text = "\n".join(lines)


## The understanding check came back: fill the tablet, and celebrate mastery.
func _on_judged(work: String, ids: Array) -> void:
	var note := _learned(work, ids)
	if note == "":
		return
	_talk[work] = _talk.get(work, "") + note
	if _ask_panel.visible and _ask_work == work:
		_answer.text = _talk[work]
		_refresh_lessons()


## Points newly understood (through the teacher, or a stone in Zen): fill the tablet, bring a piece
## of this place back when you turn away, and celebrate mastery. Returns the lines that say so, or
## "" if nothing was new.
func _learned(work: String, ids: Array) -> String:
	var fresh: Array = progress.learn(work, ids)
	if fresh.is_empty():
		return ""
	var room := Rooms.room(work)
	var names: Array = room.get("lesson", []).filter(func(p): return fresh.has(p["id"])).map(func(p): return p["label"])
	var note := "\n\n[color=#a6c8cc]On your tablet: %s[/color]" % ", ".join(names)
	if (work == here or Rooms.room(work).get("area_of", "") == here) and not Rooms.room(work).get("restores", []).is_empty():
		note += "\n[i][color=#a6c8cc]Something in this place stirs.[/color][/i]"
		_restore_pending = here  # it comes back when you turn from the talk
		if not _any_panel():
			_restore()  # the check came back after you had already walked away
	if progress.check_mastery(work, room.get("lesson", [])):
		note += "\n\n[i][color=#e0b660]%s[/color][/i]\n[color=#e0b660]You have mastered the %s. Its gateway on the Shore now burns.[/color]" % [
			_esc(room.get("gift", "")), room.get("book", "book")]
	progress.save()
	return note


## Your wax tablet: what you have understood, in plain words.
func _tablet_text() -> String:
	if here == "hub":
		return "[color=#e0b660]Your tablet[/color]\n\nBooks mastered: %d of %d." % [progress.mastered_count(), doors.size()]
	if here == "nexus":
		var now := Nexus.now(progress, doors)
		return "[color=#e0b660]Your tablet: %s[/color]\n\n%s\n\nIdeas understood: %d\nBooks mastered: %d of %d" % [
			here_name, Nexus.content().get("rule", ""), now["points"], (now["mastered"] as Array).size(), Nexus.SLOTS]
	var w := _work_here()
	var room := Rooms.room(w)
	var have: Array = progress.understood(w)
	var lines: Array = ["[color=#e0b660]Your tablet: %s[/color]" % room.get("book", "")]
	for p in room.get("lesson", []):
		lines.append(("+ %s" % p["point"]) if have.has(p["id"]) else ("[color=#8a8074]- %s: not yet[/color]" % p["label"]))
	return "\n\n".join(lines)


static func _you(question: String) -> String:
	return "[color=#a6c8cc]You:[/color] %s" % _esc(question)


## Shows an answer with the author it belongs to, even if the player has walked off meanwhile.
func _on_answer(reply: Dictionary) -> void:
	var work: String = reply["work"]
	var who: String = Rooms.room(work).get("author", "The author")
	var out := _you(reply["question"])
	if reply["error"] != "":
		out += "\n\n[color=#c08070]%s[/color]" % _esc(reply["error"])
	else:
		out += "\n\n[color=#e0b660]%s:[/color] %s" % [who, _esc(reply["text"])]
		for q in reply["quotes"].slice(0, 2):
			out += "\n\n[i][color=#a89878]From the book (%s): \"%s\"[/color][/i]" % [q["where"], _esc(_shorten(q["text"], 220))]
	_talk[work] = out
	if _ask_panel.visible and _ask_work == work:
		_answer.text = out


static func _esc(s: String) -> String:
	return s.replace("[", "[lb]")


## Whole sentences from the start of a passage, up to about n characters, so a page fits the screen.
static func excerpt(s: String, n: int) -> String:
	s = s.replace("\n", " ").strip_edges()
	if s != "" and s[0] == s[0].to_lower() and s[0] != s[0].to_upper():  # starts mid-sentence
		var start := s.find(". ")
		if start > 0 and start < s.length() / 2:
			s = s.substr(start + 2)
	if s.length() <= n:
		return s
	var cut := s.left(n).rfind(". ")
	return s.left(cut + 1) + " ..." if cut > n / 3 else _shorten(s, n)


static func _shorten(s: String, n: int) -> String:
	s = s.replace("\n", " ").strip_edges()
	return s if s.length() <= n else s.left(n).rstrip(" ,;") + "..."


func _book(work: String) -> RefCounted:
	if not books.has(work):
		books[work] = Library.load_book(work)
	return books[work]


func _show_read(text: String) -> void:
	_read_text.text = text + "\n\n[i][color=#8a8074]F to close[/color][/i]"
	_read_panel.size = Vector2(READ_W, 0)
	_show_panel(_read_panel)


func _show_panel(p: Control) -> void:
	if not _any_panel():
		_mouse_before = Input.mouse_mode
	p.show()
	_where.hide()  # the place name would poke out above the panel
	player.frozen = true
	if not offline:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _any_panel() -> bool:
	return _read_panel.visible or _ask_panel.visible or _map_panel.visible or _tree_panel.visible or _menu.visible or _choice.visible


## Closing a panel puts the mouse back the way it was, so looking around just continues.
func _close_panels() -> void:
	if _menu.visible:
		_menu.save_settings()
	for p in [_read_panel, _ask_panel, _map_panel, _tree_panel, _menu]:
		p.hide()
	_where.show()
	_question_box.release_focus()
	player.frozen = false
	if not offline:
		Input.mouse_mode = _mouse_before
	var due := _restore_pending != "" and _restore_pending == here
	_restore_pending = ""
	if due:
		_restore()


# ---------- moment to moment ----------

func _process(delta: float) -> void:
	_t += delta
	if not _ok:
		return
	if _args.has("shot"):
		_frames += 1
		if _frames == 90:
			get_viewport().get_texture().get_image().save_png(_args["shot"])
			get_tree().quit()
	for f in flicker:
		if is_instance_valid(f["light"]):
			f["light"].light_energy = f["base"] * (0.85 + 0.15 * sin(_t * 9.0 + f["seed"]) * sin(_t * 3.7 + f["seed"]))
	_check_area()
	_animate_people(delta)
	_animate_life(delta)
	_catch_fall()
	_nexus_clock(delta)
	if _nexus_due > 0.0 and _t >= _nexus_due and not travelling and not _any_panel():
		_nexus_catch_up()
	if beat and not _any_panel():
		_play_beat(delta)
		return
	if player.frozen:
		_prompt.text = ""
		return
	if player.seated:
		_prompt.text = "F: Step ashore" if not _riding.is_empty() else "F: Stand up"
		return
	if _falling_since >= 0.0:
		_prompt.text = "Are you ready to stop falling?
F: Yes" if _ready_to_land() else ""
		return
	target = _nearest()
	if _t < _quip_until:
		_prompt.text = _quip
	elif _t - _quit_armed < QUIT_WINDOW:
		_prompt.text = "Press Esc again to leave."
	elif target.is_empty():
		_prompt.text = _hint
	elif target["kind"] == "gate" and not target["open"]:
		_prompt.text = target["text"] + "\n(not open yet)"
	elif target["kind"] == "gate":
		_prompt.text = target["text"] + ("\nF: Enter" if target["to"] != "hub" else "\nF: Go")
	else:
		_prompt.text = "F: " + target["text"]


## Swallows wheel overhead, the trees stir, and the toad hops along after you.
func _animate_life(delta: float) -> void:
	_animate_creep(delta)
	for b in birds:
		b["angle"] += b["speed"] * delta
		var a: float = b["angle"]
		var node: Node3D = b["node"]
		node.position = b["center"] + Vector3(cos(a) * b["r"], b["h"] + sin(a * 2.0 + b["phase"]) * 0.6, sin(a) * b["r"])
		var heading := Vector3(-sin(a), 0, cos(a)) * signf(b["speed"])
		node.rotation.y = atan2(heading.x, heading.z)
		var flap := sin(_t * 14.0 + b["phase"]) * 0.7
		b["wings"][0].rotation.z = -flap
		b["wings"][1].rotation.z = flap
	for i in sway.size():
		if is_instance_valid(sway[i]):
			sway[i].rotation.z = sin(_t * 0.9 + i * 1.3) * 0.03
			sway[i].rotation.x = cos(_t * 0.7 + i * 0.9) * 0.02
	var lid := fmod(_t, BLINK_EVERY)
	var shut := sin(lid / 0.6 * PI) if lid < 0.6 else 0.0  # down and up again in 0.6 s
	for eye in blink:
		if is_instance_valid(eye):
			eye.scale.y = 1.0 - 0.9 * shut
	for d in drift:
		var node: Node3D = d["node"]
		if not is_instance_valid(node):
			continue
		var w: float = TAU / maxf(d["period"], 0.1)
		node.position = d["base"] + Vector3(0, sin(_t * w + d["phase"]) * d["bob"], 0)
		node.rotation = d["rot"] + d["spin"] * _t + Vector3(0, 0, sin(_t * w * 0.5 + d["phase"]) * d["sway"])
	_animate_squads(delta)
	_animate_boats(delta)
	_animate_toad(delta)


## Soldiers march their circuit in step, the whole block turning at each corner.
## The dead at the edge of Ocean (Odyssey 11): while you are near, they drift in from the dark toward
## the blood in the trench, and stop at its edge; while you hold the sword over it (a beat), they
## shrink back to where they stood. Far off, they wait.
func _animate_creep(delta: float) -> void:
	for c in creep:
		var node: Node3D = c["node"]
		if not is_instance_valid(node):
			continue
		var trench: Vector3 = c["trench"]
		var near := Vector2(player.global_position.x - trench.x, player.global_position.z - trench.z).length() < 30.0
		var home: Vector3 = c["home"]
		var want := home
		if near and beat == null:
			want = trench + (home - trench).normalized() * 2.2
		var to := want - node.global_position
		to.y = 0.0
		if to.length() < 0.05:
			continue
		var speed := 1.6 if beat != null else 0.45
		node.global_position += to.normalized() * minf(to.length(), speed * delta)
		node.rotation.y = lerp_angle(node.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 2.0))


func _animate_squads(delta: float) -> void:
	for sq in squads:
		var root: Node3D = sq["root"]
		if not is_instance_valid(root) or not sq.has("path"):
			continue
		var goal: Vector3 = sq["path"][sq["leg"]]
		var d := goal - root.position
		d.y = 0.0
		if d.length() < 0.3:
			sq["leg"] = (sq["leg"] + 1) % sq["path"].size()
			continue
		root.position += d.normalized() * minf(d.length(), sq["speed"] * delta)
		root.rotation.y = lerp_angle(root.rotation.y, atan2(d.x, d.z), minf(1.0, delta * 2.0))
		var dead: bool = sq.get("undead", false)
		sq["step"] += delta * (3.8 if dead else 5.5)  # the dead drag their feet
		for j in sq["legs"].size():
			sq["legs"][j].rotation.x = sin(sq["step"] + (j % 2) * PI) * (0.32 if dead else 0.5)


## A walking teacher paces between the points of his path; when you come close he stops,
## turns to you, and waits, then walks on when you leave.
func _walk(person: Dictionary, to: Vector3, delta: float, t: float) -> void:
	var root: Node3D = person["root"]
	var legs: Array = person.get("legs", [])
	var k := minf(1.0, delta * 4.0)
	if to.length() < 4.0 and to.z > -0.5:
		var face := player.global_position - root.position
		root.rotation.y = lerp_angle(root.rotation.y, atan2(face.x, face.z), k)
		for leg in legs:
			leg.rotation.x = lerpf(leg.rotation.x, 0.0, k)
		return
	var path: Array = person["path"]
	var leg_i: int = person.get("leg", 0)
	var goal: Vector3 = path[leg_i]
	var d := goal - root.position
	d.y = 0.0
	if d.length() < 0.25:
		person["leg"] = (leg_i + 1) % path.size()
		return
	root.position += d.normalized() * minf(d.length(), person.get("speed", 1.0) * delta)
	root.rotation.y = lerp_angle(root.rotation.y, atan2(d.x, d.z), k)
	for j in legs.size():
		legs[j].rotation.x = sin(t * 6.0 + j * PI) * 0.45


## Where the toad wants to be: about two paces from you, on its own side of you. Only where
## you stand matters, not which way you look, so turning round leaves it sitting.
func _toad_spot() -> Vector3:
	var away: Vector3 = toad["root"].position - player.position
	away.y = 0.0
	if away.length() < 0.1:
		away = Basis(Vector3.UP, player.rotation.y) * Vector3(1, 0, 1)
	var want: Vector3 = player.position + away.normalized() * (1.2 if player.seated else 2.0)
	var on := _to_ground(ground, Vector2(want.x, want.z))
	return Vector3(on.x, 0.02, on.y)


## Through a gateway the toad is simply there with you.
func _toad_to_heel() -> void:
	if toad.is_empty() or toad_hold:
		return
	var behind := Basis(Vector3.UP, player.rotation.y) * Vector3(1.2, 0, 1.6)  # behind you and to the right
	var on := _to_ground(ground, Vector2(player.position.x + behind.x, player.position.z + behind.z))
	toad["root"].position = Vector3(on.x, 0.02, on.y)
	_toad_moving = false


## The toad keeps a couple of paces behind you and to the right; it sits until you get well ahead, then hops to catch up, and faces you when
## you stop. After a gateway it is simply there with you.
func _animate_toad(delta: float) -> void:
	if toad.is_empty():
		return
	var root: Node3D = toad["root"]
	var body: Node3D = toad["body"]
	if toad_hold:
		toad["throat"].scale = THROAT * (1.0 + 0.15 * maxf(0.0, sin(_t * 2.2)))
		return
	var want := _toad_spot()
	var flat := Vector3(want.x - root.position.x, 0, want.z - root.position.z)
	var d := flat.length()
	if d > 1.8:
		_toad_moving = true
	elif d < 0.4:
		_toad_moving = false
	if d > 14.0:
		root.position = Vector3(want.x, 0.02, want.z)
	elif _toad_moving:
		var speed := 2.6 if d < 4.0 else 5.2
		root.position += flat.normalized() * minf(d, speed * delta)
		var stay := _to_ground(ground, Vector2(root.position.x, root.position.z))
		root.position = Vector3(stay.x, 0.02, stay.y)
		_toad_hop += delta * 7.0
		body.position.y = absf(sin(_toad_hop)) * 0.18
		root.rotation.y = lerp_angle(root.rotation.y, atan2(flat.x, flat.z), minf(1.0, delta * 8.0))
	else:
		body.position.y = lerpf(body.position.y, 0.0, minf(1.0, delta * 8.0))
		var look := player.global_position - root.position
		root.rotation.y = lerp_angle(root.rotation.y, atan2(look.x, look.z), minf(1.0, delta * 2.0))
	_toad_puff = maxf(0.0, _toad_puff - delta * 0.8)
	toad["throat"].scale = THROAT * (1.0 + 0.15 * maxf(0.0, sin(_t * 2.2)) + _toad_puff)
	body.scale = Vector3.ONE * (1.0 + _toad_puff * 0.25)


func pat_toad() -> void:
	_toad_puff = 0.9
	_quip = TOAD_QUIPS[randi() % TOAD_QUIPS.size()]
	_quip_until = _t + 2.5
	if music:
		music.croak()


## Everyone present breathes, writes when left alone, and looks up and turns toward you
## when you come near.
func _animate_people(delta: float) -> void:
	for i in people.size():
		var person: Dictionary = people[i]
		if not is_instance_valid(person["head"]):
			continue
		var root: Node3D = person["root"]
		var head: Node3D = person["head"]
		var t := _t + i * 1.7  # each at their own moment
		root.scale.y = 1.0 + 0.008 * sin(t * 1.6)
		var to: Vector3 = root.to_local(player.global_position)
		var near := to.length() < 6.0 and to.z > 0.0
		if person.has("path"):
			_walk(person, to, delta, t)
		var want_yaw := clampf(atan2(to.x, to.z), -0.9, 0.9) if near else 0.0
		var want_pitch := -0.12 if near else 0.35 + 0.05 * sin(t * 0.7)
		var k := minf(1.0, delta * 3.0)
		head.rotation.y = lerpf(head.rotation.y, want_yaw, k)
		head.rotation.x = lerpf(head.rotation.x, want_pitch, k)
		var hand: Node3D = person["hand"]
		hand.position = Vector3(0.03 * sin(t * 7.0), 0.0, 0.02 * sin(t * 3.5)) if not near else hand.position.lerp(Vector3.ZERO, minf(1.0, delta * 4.0))


func _nearest() -> Dictionary:
	var best := {}
	var best_d := INF
	var at := player.global_position
	for it in interactables:
		if it.has("follow") and is_instance_valid(it["follow"]):
			it["pos"] = it["follow"].global_position  # someone who moves about
		var to: Vector3 = it["pos"] - at
		to.y = 0.0
		var d := to.length()
		if d > (GATE_REACH if it["kind"] == "gate" else REACH):
			continue
		if d > 0.3 and player.facing().dot(to.normalized()) < 0.2:
			continue
		if d < best_d:
			best = it
			best_d = d
	if not toad.is_empty():
		var to_toad: Vector3 = toad["root"].position - at
		to_toad.y = 0.0
		if to_toad.length() < minf(best_d, 1.6) and (to_toad.length() < 0.5 or player.facing().dot(to_toad.normalized()) > 0.2):
			best = {"kind": "toad", "pos": toad["root"].position, "text": "Pat the toad"}
	return best


func activate(it: Dictionary) -> void:
	match it.get("kind", ""):
		"fact":
			_show_read(it["text"])
		"statue", "person":
			_show_read(it["note"])
		"look":
			_read_stone(it)
		"map":
			_open_map(it)
		"tree":
			_show_panel(_tree_panel)
		"book":
			var book := _book(it.get("work", here))
			if book:
				var p: Dictionary = book.random_passage()
				_show_read("[i]%s, %s[/i]\n\n%s" % [p["where"], book.translation, _esc(excerpt(p["text"], 360))])
		"author":
			_open_ask(it.get("work", here))
		"gate":
			if it["open"]:
				travel(it["to"])
		"seat":
			sit(it)
		"ferry":
			take_boat(it)
		"toad":
			pat_toad()
		"beat":
			_start_beat(it)


## Something to look at, and the lesson stones among them. For a Theoros (Zen) a stone's point
## counts as understood as you read it, and a piece of the place comes back when you turn from it;
## for a Mathetes (Student) it is only there to read: the teacher must hear it in your own words.
func _read_stone(it: Dictionary) -> void:
	_show_read(it["note"])  # open first, so what comes back waits until you turn away
	if it.has("id") and progress.mode(_world_of(here)) == "zen":
		var note := _learned(it.get("work", here), [it["id"]])
		if note != "":
			_show_read(it["note"] + note)


## A beat: a moment of the book played in the first person, as its hero (Beat). You stand where
## it happens, the hero's arms come up before your eyes, and the moment goes one short line and one
## act at a time. When it ends its point is read like a lesson stone's: for a Theoros it counts,
## and a piece of the place comes back when you turn away.
func _start_beat(it: Dictionary) -> void:
	var def := Beat.find(it.get("work", here), it["beat"])
	if def.is_empty():
		push_error("No beat %s for %s" % [it["beat"], it.get("work", here)])
		return
	if it.has("start"):
		var at: Vector3 = it["start"]
		player.position = Vector3(at.x, player.position.y, at.z)
		if it.has("face"):
			var to: Vector3 = it["face"] - at
			player.rotation.y = atan2(-to.x, -to.z)
	_beat_it = it
	beat = Beat.new(def, it.get("work", here), it.get("id", ""), it.get("cast", {}), it.get("marks", {}))
	beat.start(player)
	if _where and beat.title != "":
		_where.text = beat.title
	_beat_mark = Kit.group(world, Vector3.ZERO)
	Kit.cylinder(_beat_mark, Vector3(0, 0, 0), 0.35, 3.0, "glow", false, 8, 0.05)
	Kit.unsolid(_beat_mark)
	_beat_mark.hide()


func _play_beat(delta: float, holding: bool = false) -> void:
	beat.update(delta, player, holding or Input.is_action_pressed("interact"))
	if beat.done:
		_end_beat(true)
		return
	player.frozen = not beat.free_to_walk()
	var mark: Variant = beat.next_mark()
	if is_instance_valid(_beat_mark):
		_beat_mark.visible = mark != null
		if mark != null:
			_beat_mark.position = mark
	_prompt.text = beat.prompt()


## The moment ends: finished (its point is read, and counts for a Theoros) or left with Esc.
func _end_beat(finished: bool) -> void:
	var it := _beat_it
	beat.finish(player)
	beat = null
	_beat_it = {}
	if is_instance_valid(_beat_mark):
		_beat_mark.queue_free()
	player.frozen = _any_panel()
	if _where:
		_where.text = here_name
	_prompt.text = ""
	if finished and it.has("id") and it.has("note"):
		_read_stone(it)
	elif finished and it.has("after"):
		_show_read(it["after"])


## Sit on a bench: the view settles on the sea, the music rises a little.
func sit(it: Dictionary) -> void:
	_seat = it
	player.sit(it["seat"], Places.look_yaw(it["look"] - it["seat"]))
	if music:
		music.swell(true)


func stand_up() -> void:
	if not _riding.is_empty():  # step ashore: onto the landing, or the nearer bank mid-river
		var boat := _riding
		var off := Vector3.ZERO
		if boat["landing"] != "":
			off = boat["landings"][boat["landing"]]["off"]
		else:
			var heading := Vector3(sin(boat["root"].rotation.y), 0, cos(boat["root"].rotation.y))
			off = Vector3(heading.z, 0, -heading.x) * 2.0
		boat["route"] = []  # it waits where you left it
		_riding = {}
		player.stand(off)
		return
	var away := Vector3.ZERO
	if not _seat.is_empty():
		away = (_seat["seat"] - _seat["look"])
		away.y = 0.0
		away = away.normalized() * 0.9  # step back off the bench, away from the view
	_seat = {}
	player.stand(away)
	if music:
		music.swell(false)


## Take the boat from a landing to another: it is waiting at the landing you are at (the landings
## are far apart, and a boat left anywhere else is brought round), you sit on its thwart, and it rows
## you there by way of the junction.
func take_boat(it: Dictionary) -> void:
	var boat: Dictionary = it["boat"]
	var at: Vector3 = boat["landings"][it["from"]]["at"]
	var junction: Vector3 = boat["junction"]
	boat["root"].position = at
	boat["root"].rotation.y = atan2(junction.x - at.x, junction.z - at.z)
	boat["route"] = [junction, boat["landings"][it["to"]]["at"]]
	boat["to"] = it["to"]
	boat["landing"] = ""
	_riding = boat
	player.sit(at, Places.look_yaw(junction - at))


## The boat you are in rows on to its landing, carrying you with it, and rests there.
func _animate_boats(delta: float) -> void:
	for boat in boats:
		var root: Node3D = boat["root"]
		if not is_instance_valid(root) or boat.get("route", []).is_empty():
			continue
		var d: Vector3 = boat["route"][0] - root.position
		d.y = 0.0
		if d.length() < 0.05:
			boat["route"].pop_front()
			if boat["route"].is_empty():  # there: it rests at the landing
				boat["landing"] = boat["to"]
				for oar in boat["oars"]:
					oar.rotation.y = 0.0
			continue
		root.position += d.normalized() * minf(d.length(), boat["speed"] * delta)
		root.rotation.y = lerp_angle(root.rotation.y, atan2(d.x, d.z), minf(1.0, delta * 2.0))
		var stroke := sin(_t * 2.4) * 0.55
		boat["oars"][0].rotation.y = stroke
		boat["oars"][1].rotation.y = -stroke
		if is_same(boat, _riding):
			player.position = Vector3(root.position.x, player.position.y, root.position.z)


## Mouse look and Esc are handled here, before anything on screen can swallow them.
func _input(event: InputEvent) -> void:
	if _ok and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not player.frozen:
		player.look(event.screen_relative)  # real mouse movement, whatever the window scale
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if not _ok:
			get_tree().quit()
		elif _choice.visible:
			pass  # a world's question has to be answered
		elif beat and not _any_panel():
			_end_beat(false)  # leave the moment; it can be played again
		elif _any_panel():
			_close_panels()
		else:
			_menu.show_mode(_mode_line())
			_show_panel(_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not _ok or travelling:  # nothing opens in the middle of a fade
		return
	if event is InputEventMouseButton and event.pressed and not player.frozen and not offline:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("tablet") and not _ask_panel.visible:
		get_viewport().set_input_as_handled()
		if _read_panel.visible:
			_close_panels()
		else:
			_show_read(_tablet_text())
		return
	if _ask_panel.visible or _menu.visible or _choice.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if beat and not _any_panel():
			beat.press(player)
		elif _read_panel.visible or _map_panel.visible or _tree_panel.visible:
			_close_panels()
		elif player.seated:
			stand_up()
		elif _falling_since >= 0.0:
			if _ready_to_land():
				_stop_falling()
		elif not target.is_empty() and not travelling:
			activate(target)


## Quitting keeps what the save has gathered since the last door (the time spent in the Nexus).
func _exit_tree() -> void:
	if progress and not offline:
		progress.save()
