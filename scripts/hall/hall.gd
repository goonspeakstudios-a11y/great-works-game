extends Node
## The Hall of Greece: a dark, low-resolution 3D hall with one door per book on the
## reading list, in order. Open rooms hold short facts on the walls, the book itself on a
## lectern (read a real passage), and the author's portrait: walk up and ask them anything
## about their book. Everything 3D renders at 320x180 and is scaled up for the retro look.
## Controls: WASD/arrows walk, left/right arrows or mouse turn (click to capture the mouse),
## E to read or ask, Esc to close a panel / free the mouse / quit.

const Rooms := preload("res://scripts/hall/rooms.gd")
const Library := preload("res://scripts/hall/library.gd")
const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Portrait := preload("res://scripts/hall/portrait.gd")
const Tex := preload("res://scripts/hall/textures.gd")
const Player := preload("res://scripts/hall/player.gd")
const Music := preload("res://scripts/pixel/music.gd")

const RES := Vector2i(320, 180)
const SECTION := 9.0  # door to door; must fit a whole room (see ROOM_HALF)
const HALL_W := 2.0  # half width
const HEIGHT := 4.0
const DOOR_W := 2.0
const DOOR_H := 3.0
const START_Z := -2.0
const REACH := 1.7
const ROOM_HALF := 4.0  # a room reaches this far either side of its door
const ROOM_DEPTH := 7.6
const WALL := 0.4
const QUIT_WINDOW := 2.0

var offline := false  # tests: no music, no mouse capture
var doors: Array = []
var interactables: Array = []  # {kind, pos, text, work}
var player: CharacterBody3D
var world: Node3D
var author: AuthorAI
var books := {}  # work -> Library
var target := {}
var torches: Array = []

var _view: SubViewport
var _ui: CanvasLayer
var _prompt: Label
var _where: Label
var _read_panel: PanelContainer
var _read_text: RichTextLabel
var _ask_panel: Panel
var _ask_portrait: TextureRect
var _ask_name: Label
var _ask_life: Label
var _answer: RichTextLabel
var _question_box: LineEdit
var _suggestions: Array = []
var _ask_room: Dictionary = {}
var _ask_work := ""
var _t := 0.0
var _args := {}
var _frames := 0
var _ok := false
var _talk := {}  # work -> what has been said in that room, as shown in the panel
var _mouse_was_captured := false
var _quit_armed := -100.0


static func ensure_actions() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"strafe_left": [KEY_A], "strafe_right": [KEY_D],
		"turn_left": [KEY_LEFT, KEY_Q], "turn_right": [KEY_RIGHT],
		"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
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
	if not InputMap.action_get_events("interact").any(func(e): return e is InputEventJoypadButton):
		var b := InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_A
		InputMap.action_add_event("interact", b)


func _ready() -> void:
	ensure_actions()
	doors = Rooms.doors()
	if doors.is_empty():
		push_error("Could not load the reading list.")
		return
	_build_view()
	_build_hall()
	for i in doors.size():
		if doors[i]["open"]:
			_build_room(i)
	_build_ui()
	author = AuthorAI.new()
	author.answered.connect(_on_answer)
	add_child(author)
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if _args.has("shot"):
		offline = true
		_stage_shot(_args.get("view", "hall"))
	if not offline:
		add_child(Music.new())
	_ok = true


## Screenshot mode for checking the look without playing:
##   godot --path . -- --shot=C:/out.png --view=hall|door|room|read|ask
func _stage_shot(view: String) -> void:
	var dz := door_z(0)
	match view:
		"door":
			player.position = Vector3(0.6, 0.05, dz)
			player.rotation.y = PI / 2.0
		"room", "read", "ask":
			player.position = Vector3(-6.0, 0.05, dz)
			player.rotation.y = PI / 2.0
	if view == "read":
		activate(interactables.filter(func(i): return i["kind"] == "fact")[2])
	elif view == "ask":
		_open_ask(doors[0]["work"])
		_talk[doors[0]["work"]] = "[color=#a6c8cc]You:[/color] What's the difference between genus and species?\n\n[color=#e0b660]Porphyry:[/color] Think of it as a ladder: substance, then body, then living body, then animal, then man. Each step down is narrower. So 'animal' is the genus of 'man', and 'man' is a species of 'animal'.\n\n[i][color=#a89878]From the book (Isagoge, Chap. II): \"Substance indeed, is itself genus, under this is body, under body animated body, under which is animal...\"[/color][/i]"
		_answer.text = _talk[doors[0]["work"]]


# ---------- building the 3D world ----------

func _build_view() -> void:
	_view = SubViewport.new()
	_view.size = RES
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_view)
	world = Node3D.new()
	_view.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("09080c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("5a6070")
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color("0b0a10")
	env.fog_density = 0.06
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	player = Player.new()
	player.position = Vector3(0, 0.05, -0.8)
	world.add_child(player)
	player.camera.current = true


func _box(center: Vector3, size: Vector3, mat: String, solid: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = Tex.material(mat)
	mi.position = center
	world.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		body.position = center
		world.add_child(body)
	return mi


func _light(at: Vector3, col: Color, energy: float, reach: float, flicker: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	world.add_child(l)
	if flicker:
		torches.append({"light": l, "base": energy, "seed": randf() * 10.0})
	return l


static func door_z(i: int) -> float:
	return START_Z - SECTION * i - SECTION / 2.0


func _build_hall() -> void:
	var n := doors.size()
	var end_z := START_Z - SECTION * n
	# the entrance stretch, the far end, and the walls behind you and ahead
	_box(Vector3(0, -0.1, START_Z / 2.0), Vector3(HALL_W * 2, 0.2, -START_Z), "floor")
	_box(Vector3(0, HEIGHT + 0.1, START_Z / 2.0), Vector3(HALL_W * 2, 0.2, -START_Z), "ceiling")
	for x in [-HALL_W - 0.2, HALL_W + 0.2]:
		_box(Vector3(x, HEIGHT / 2.0, START_Z / 2.0), Vector3(0.4, HEIGHT, -START_Z), "wall")
	_box(Vector3(0, HEIGHT / 2.0, 0.2), Vector3(HALL_W * 2 + 0.8, HEIGHT, 0.4), "wall")
	_box(Vector3(0, HEIGHT / 2.0, end_z - 0.2), Vector3(HALL_W * 2 + 0.8, HEIGHT, 0.4), "wall")
	for i in n:
		var z0 := START_Z - SECTION * i
		var zc := z0 - SECTION / 2.0
		var dz := door_z(i)
		_box(Vector3(0, -0.1, zc), Vector3(HALL_W * 2, 0.2, SECTION), "floor")
		_box(Vector3(0, HEIGHT + 0.1, zc), Vector3(HALL_W * 2, 0.2, SECTION), "ceiling")
		_box(Vector3(HALL_W + 0.2, HEIGHT / 2.0, zc), Vector3(0.4, HEIGHT, SECTION), "wall")
		var piece := (SECTION - DOOR_W) / 2.0
		for pz in [z0 - piece / 2.0, z0 - SECTION + piece / 2.0]:
			_box(Vector3(-HALL_W - 0.2, HEIGHT / 2.0, pz), Vector3(0.4, HEIGHT, piece), "wall")
		_box(Vector3(-HALL_W - 0.2, (DOOR_H + HEIGHT) / 2.0, dz), Vector3(0.4, HEIGHT - DOOR_H, DOOR_W), "wall")
		_box(Vector3(-HALL_W - WALL / 2.0, -0.1, dz), Vector3(WALL + 0.02, 0.2, DOOR_W), "floor")
		if doors[i]["open"]:
			_light(Vector3(-HALL_W + 0.3, 2.6, dz + 1.3), Color("ffa050"), 1.6, 6.0, true)
		else:
			_box(Vector3(-HALL_W - 0.9, DOOR_H / 2.0, dz), Vector3(1.0, DOOR_H, DOOR_W), "void")
			for k in 5:
				_box(Vector3(-HALL_W - 0.2, DOOR_H / 2.0, dz - 0.8 + k * 0.4), Vector3(0.06, DOOR_H, 0.06), "bars", false)
			_box(Vector3(-HALL_W - 0.2, DOOR_H / 2.0, dz), Vector3(0.1, DOOR_H, DOOR_W), "bars", true).visible = false
			_light(Vector3(-HALL_W + 0.4, 2.8, dz), Color("6a7a9a"), 0.35, 4.0)
		var state := "open. Walk in." if doors[i]["open"] else "sealed for now."
		interactables.append({"kind": "door", "pos": Vector3(-HALL_W + 0.6, 0, dz), "work": doors[i]["work"],
			"text": "%d. %s, %s" % [doors[i]["number"], doors[i]["name"], state]})


func _build_room(i: int) -> void:
	var work: String = doors[i]["work"]
	var room := Rooms.room(work)
	var dz := door_z(i)
	var x0 := -HALL_W - WALL
	var x1 := x0 - ROOM_DEPTH
	var cx := (x0 + x1) / 2.0
	var depth := ROOM_DEPTH
	var half := ROOM_HALF
	_box(Vector3(cx, -0.1, dz), Vector3(depth, 0.2, half * 2), "floor")
	_box(Vector3(cx, HEIGHT + 0.1, dz), Vector3(depth, 0.2, half * 2), "ceiling")
	_box(Vector3(x1 - 0.2, HEIGHT / 2.0, dz), Vector3(0.4, HEIGHT, half * 2), "room_wall")
	for sz in [dz - half - WALL / 2.0, dz + half + WALL / 2.0]:
		_box(Vector3(cx, HEIGHT / 2.0, sz), Vector3(depth + WALL, HEIGHT, WALL), "room_wall")
	_light(Vector3(x1 + 1.0, 2.8, dz - 2.4), Color("ffa860"), 1.4, 7.0, true)
	_light(Vector3(x1 + 1.0, 2.8, dz + 2.4), Color("ffa860"), 1.4, 7.0, true)
	_light(Vector3(cx + 1.5, 3.2, dz), Color("c8b090"), 0.5, 6.0)
	# the author's portrait on the far wall
	var tex := Portrait.make(room.get("portrait", {}))
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.2, 1.6)
	quad.mesh = qm
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = tex
	pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pm.emission_enabled = true
	pm.emission_texture = tex
	pm.emission_energy_multiplier = 0.25
	quad.material_override = pm
	quad.position = Vector3(x1 + 0.03, 1.9, dz)
	quad.rotation.y = PI / 2.0
	world.add_child(quad)
	for f in [[Vector3(0, 0.85, 0), Vector3(0.08, 0.1, 1.4)], [Vector3(0, -0.85, 0), Vector3(0.08, 0.1, 1.4)],
			[Vector3(0, 0, 0.65), Vector3(0.08, 1.8, 0.1)], [Vector3(0, 0, -0.65), Vector3(0.08, 1.8, 0.1)]]:
		_box(Vector3(x1 + 0.04, 1.9, dz) + f[0], f[1], "gold", false)
	interactables.append({"kind": "author", "pos": Vector3(x1 + 1.4, 0, dz), "work": work,
		"text": "Ask %s about the %s" % [room["author"], room["book"]]})
	# facts on plaques along the two side walls
	var facts: Array = room.get("facts", [])
	var spots := fact_spots(facts.size(), x1, depth, dz)
	for k in facts.size():
		var at: Vector3 = spots[k]
		var north := at.z < dz
		_box(Vector3(at.x, 1.6, at.z), Vector3(1.0, 0.66, 0.05), "plaque", false)
		interactables.append({"kind": "fact", "pos": Vector3(at.x, 0, at.z + (0.9 if north else -0.9)), "work": work,
			"text": facts[k]})
	# the book itself on a lectern
	_box(Vector3(cx + 0.8, 0.5, dz), Vector3(0.5, 1.0, 0.5), "wood")
	_box(Vector3(cx + 0.8, 1.05, dz), Vector3(0.45, 0.06, 0.6), "page", false)
	interactables.append({"kind": "book", "pos": Vector3(cx + 1.5, 0, dz), "work": work,
		"text": "Open the %s and read a page" % room["book"]})


## Where each fact's plaque hangs: split between the two side walls, evenly spaced,
## so every fact has its own place however many there are.
static func fact_spots(n: int, x1: float, depth: float, dz: float) -> Array:
	var out: Array = []
	var north := ceili(n / 2.0)
	for k in n:
		var on_north := k < north
		var count := north if on_north else n - north
		var j := k if on_north else k - north
		var px := x1 + 1.2 + (j + 0.5) * (depth - 1.6) / maxi(1, count)
		var pz := dz - ROOM_HALF + 0.05 if on_north else dz + ROOM_HALF - 0.05
		out.append(Vector3(px, 0, pz))
	return out


# ---------- interface ----------

static func _style(alpha: float = 0.92, border: Color = Color("3a3542")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.03, 0.045, alpha)
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


static func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_ui() -> void:
	var screen := TextureRect.new()
	screen.texture = _view.get_texture()
	screen.size = Vector2(RES)
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	var dot := ColorRect.new()
	dot.color = Color(0.9, 0.85, 0.7, 0.5)
	dot.size = Vector2(1, 1)
	dot.position = Vector2(RES) / 2.0
	_ui.add_child(dot)
	_where = _label(6, Color("a6c8cc"))
	_where.text = "The Hall of Greece"
	_where.position = Vector2(5, 3)
	_ui.add_child(_where)
	_prompt = _label(8, Color("e8dcc0"))
	_prompt.position = Vector2(10, 150)
	_prompt.size = Vector2(RES.x - 20, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui.add_child(_prompt)
	# reading panel: one fact or one page
	_read_panel = PanelContainer.new()
	_read_panel.add_theme_stylebox_override("panel", _style())
	_read_panel.position = Vector2(30, 24)
	_read_panel.custom_minimum_size = Vector2(260, 0)
	_read_panel.size = Vector2(260, 0)
	_read_panel.hide()
	_ui.add_child(_read_panel)
	_read_text = RichTextLabel.new()
	_read_text.bbcode_enabled = true
	_read_text.fit_content = true
	_read_text.custom_minimum_size = Vector2(248, 0)
	_read_text.add_theme_font_size_override("normal_font_size", 8)
	_read_text.add_theme_font_size_override("italics_font_size", 7)
	_read_text.add_theme_color_override("default_color", Color("e8dcc0"))
	_read_panel.add_child(_read_text)
	_build_ask_panel()


func _build_ask_panel() -> void:
	_ask_panel = Panel.new()
	_ask_panel.add_theme_stylebox_override("panel", _style(0.95))
	_ask_panel.position = Vector2(6, 6)
	_ask_panel.size = Vector2(RES.x - 12, RES.y - 12)
	_ask_panel.hide()
	_ui.add_child(_ask_panel)
	_ask_portrait = TextureRect.new()
	_ask_portrait.position = Vector2(8, 8)
	_ask_portrait.size = Vector2(48, 64)
	_ask_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ask_panel.add_child(_ask_portrait)
	_ask_name = _label(8, Color("e0b660"))
	_ask_name.position = Vector2(8, 74)
	_ask_name.size = Vector2(56, 10)
	_ask_panel.add_child(_ask_name)
	_ask_life = _label(5, Color("a6c8cc"))
	_ask_life.position = Vector2(8, 85)
	_ask_life.size = Vector2(60, 8)
	_ask_panel.add_child(_ask_life)
	var hint := _label(5, Color("8a8074"))
	hint.text = "Esc to leave"
	hint.position = Vector2(8, 150)
	_ask_panel.add_child(hint)
	_answer = RichTextLabel.new()
	_answer.bbcode_enabled = true
	_answer.position = Vector2(66, 8)
	_answer.size = Vector2(236, 98)
	_answer.scroll_following = false
	_answer.add_theme_font_size_override("normal_font_size", 7)
	_answer.add_theme_font_size_override("italics_font_size", 6)
	_answer.add_theme_color_override("default_color", Color("e8dcc0"))
	_ask_panel.add_child(_answer)
	for k in 4:
		var b := Button.new()
		b.position = Vector2(66 + (k % 2) * 119, 108 + (k / 2) * 13)
		b.custom_minimum_size = Vector2(117, 11)
		b.size = Vector2(117, 11)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 5)
		b.add_theme_stylebox_override("normal", _style(0.9))
		b.add_theme_stylebox_override("hover", _style(0.9, Color("e0b660")))
		b.add_theme_stylebox_override("focus", _style(0.9, Color("e0b660")))
		b.add_theme_color_override("font_color", Color("d6ccba"))
		b.pressed.connect(func(): _send(b.text))
		_ask_panel.add_child(b)
		_suggestions.append(b)
	_question_box = LineEdit.new()
	_question_box.position = Vector2(66, 137)
	_question_box.size = Vector2(236, 16)
	_question_box.placeholder_text = "Type your own question, then Enter"
	_question_box.add_theme_font_size_override("font_size", 7)
	_question_box.add_theme_stylebox_override("normal", _style(0.9, Color("5a5060")))
	_question_box.add_theme_stylebox_override("focus", _style(0.9, Color("e0b660")))
	_question_box.text_submitted.connect(func(q: String): _send(q))
	_ask_panel.add_child(_question_box)


func _open_ask(work: String) -> void:
	_ask_work = work
	_ask_room = Rooms.room(work)
	_ask_portrait.texture = Portrait.make(_ask_room.get("portrait", {}))
	_ask_name.text = _ask_room["author"]
	_ask_life.text = _ask_room["life"]
	var qs: Array = _ask_room.get("questions", [])
	for k in _suggestions.size():
		_suggestions[k].visible = k < qs.size()
		if k < qs.size():
			_suggestions[k].text = qs[k]
	_answer.text = _talk.get(work, "[i]%s looks up.[/i]\n\nAsk me anything about my book. I'll answer from what I actually wrote." % _ask_room["author"])
	_mouse_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_ask_panel.show()
	_set_frozen(true)
	_question_box.grab_focus()


func _send(question: String) -> void:
	question = question.strip_edges()
	if question == "" or author.busy:
		return
	_question_box.text = ""
	_talk[_ask_work] = "%s\n\n[i]%s is thinking...[/i]" % [_you(question), _ask_room["author"]]
	_answer.text = _talk[_ask_work]
	author.ask(_ask_work, _ask_room, _book(_ask_work), question)


static func _you(question: String) -> String:
	return "[color=#a6c8cc]You:[/color] %s" % _esc(question)


## Shows an answer in the room it belongs to, even if the player has walked off meanwhile.
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


static func _shorten(s: String, n: int) -> String:
	s = s.replace("\n", " ").strip_edges()
	return s if s.length() <= n else s.left(n).rstrip(" ,;") + "..."


func _book(work: String) -> RefCounted:
	if not books.has(work):
		books[work] = Library.load_book(work)
	return books[work]


func _show_read(text: String) -> void:
	_read_text.text = text + "\n\n[i][color=#8a8074]E to close[/color][/i]"
	_read_panel.size = Vector2(260, 0)
	_mouse_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_read_panel.show()
	_set_frozen(true)


func _set_frozen(on: bool) -> void:
	player.frozen = on
	if on and not offline:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Closing a panel puts the mouse back the way it was, so looking around just continues.
func _close_panels() -> void:
	_read_panel.hide()
	_ask_panel.hide()
	_question_box.release_focus()
	player.frozen = false
	if _mouse_was_captured and not offline:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	for tch in torches:
		tch["light"].light_energy = tch["base"] * (0.85 + 0.15 * sin(_t * 9.0 + tch["seed"]) * sin(_t * 3.7 + tch["seed"]))
	if player == null or player.frozen:
		_prompt.text = ""
		return
	target = _nearest()
	if _t - _quit_armed < QUIT_WINDOW:
		_prompt.text = "Press Esc again to leave the Hall."
	elif target.is_empty():
		_prompt.text = ""
	elif target["kind"] == "door":
		_prompt.text = target["text"]
	else:
		_prompt.text = "E: " + target["text"]


func _nearest() -> Dictionary:
	var best := {}
	var best_d := INF
	var here := player.global_position
	for it in interactables:
		var to: Vector3 = it["pos"] - here
		to.y = 0.0
		var d := to.length()
		if d > (2.2 if it["kind"] == "door" else REACH):
			continue
		if d > 0.3 and player.facing().dot(to.normalized()) < 0.2:
			continue
		if d < best_d:
			best = it
			best_d = d
	return best


func activate(it: Dictionary) -> void:
	match it.get("kind", ""):
		"fact":
			_show_read(it["text"])
		"book":
			var book := _book(it["work"])
			if book:
				var p: Dictionary = book.random_passage()
				_show_read("[i]%s, %s[/i]\n\n%s" % [p["where"], book.translation, _esc(_shorten(p["text"], 700))])
		"author":
			_open_ask(it["work"])


## Esc is handled here, before the text box can swallow it.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if not _ok or _t - _quit_armed < QUIT_WINDOW:
			get_tree().quit()
		elif _read_panel.visible or _ask_panel.visible:
			_close_panels()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_quit_armed = _t


func _unhandled_input(event: InputEvent) -> void:
	if not _ok:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not player.frozen:
		player.look(event.screen_relative)  # real mouse movement, whatever the window scale
		return
	if event is InputEventMouseButton and event.pressed and not player.frozen and not offline:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if _ask_panel.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _read_panel.visible:
			_close_panels()
		elif not target.is_empty():
			activate(target)
