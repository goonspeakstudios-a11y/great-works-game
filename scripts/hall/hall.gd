extends Node
## The world of the Great Works, in low-resolution 3D (320x180, scaled up for the retro look).
## You start on the Shore: a clifftop temple ruin over the sea at sunset, with a stone
## gateway for every book on the reading list, in order. An open gateway takes you to the
## book's own place and time (Porphyry's villa in Sicily, 270 AD, for the Isagoge): facts on
## inscribed stones, the map of the world then, busts, the book itself, and the author to
## talk to. Controls: WASD/arrows walk, Shift sprints, Q/E or left/right arrows turn, the
## mouse looks all around, F reads, asks or enters, Esc closes a panel / frees the mouse /
## twice quits.

const Rooms := preload("res://scripts/hall/rooms.gd")
const Places := preload("res://scripts/hall/places.gd")
const Library := preload("res://scripts/hall/library.gd")
const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Portrait := preload("res://scripts/hall/portrait.gd")
const Player := preload("res://scripts/hall/player.gd")
const Progress := preload("res://scripts/hall/progress.gd")
const Music := preload("res://scripts/pixel/music.gd")

const RES := Vector2i(320, 180)
const REACH := 1.8
const GATE_REACH := 2.4
const QUIT_WINDOW := 2.0
const FADE := 0.9
const TEACH_BUTTONS := ["Teach me the next thing", "Say that more simply", "Give me an example", "Why does this matter?"]

var offline := false  # tests: no music, no mouse capture, instant travel
var doors: Array = []
var here := ""  # "hub" or a work id
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
var restored_columns := 0

var _view: SubViewport
var _ui: CanvasLayer
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
var _t := 0.0
var _args := {}
var _frames := 0
var _ok := false
var _talk := {}  # work -> what has been said there, as shown in the panel
var _quit_armed := -100.0


static func ensure_actions() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"strafe_left": [KEY_A], "strafe_right": [KEY_D],
		"turn_left": [KEY_LEFT, KEY_Q], "turn_right": [KEY_RIGHT, KEY_E],
		"interact": [KEY_F, KEY_ENTER],
		"sprint": [KEY_SHIFT],
		"tablet": [KEY_T, KEY_TAB],
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
	author = AuthorAI.new()
	author.answered.connect(_on_answer)
	author.judged.connect(_on_judged)
	add_child(author)
	_load_place("hub")
	if not offline:
		add_child(Music.new())
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # look around straight away
	_ok = true
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
##   godot --path . -- --shot=C:/out.png --view=hub|gate|villa|path|study|map|tree|ask|read
func _stage_shot(view: String) -> void:
	if view != "hub" and view != "gate":
		_load_place(doors[0]["work"])
	match view:
		"gate":
			_stand(spots["gate0"], Places.gate_spot(0))
		"path":
			_stand(Vector3(0, 0, 19), Vector3(0, 0, 0))
		"villa":
			_stand(Vector3(0, 0, 8), Vector3(0, 0, -10))
		"study", "ask":
			_stand(spots["study"], Vector3(0, 0, -18))
		"map":
			_stand(spots["map"], spots["map"] + Vector3(-5, 0, 0))
			activate(interactables.filter(func(i): return i["kind"] == "map")[0])
		"tree":
			activate(interactables.filter(func(i): return i["kind"] == "tree")[0])
		"read":
			_stand(spots["fact1"], spots["fact1"] + Vector3(5, 0, 0))
			activate(interactables.filter(func(i): return i["kind"] == "fact")[1])
	if view == "ask":
		_open_ask(doors[0]["work"])
		_talk[doors[0]["work"]] = _you("What's the difference between genus and species?") + "\n\n[color=#e0b660]Porphyry:[/color] Genus is the wide family, like animal. Species is one kind inside it, like human. What splits them is the difference: being able to reason."
		_answer.text = _talk[doors[0]["work"]]


func _stand(at: Vector3, look_at: Vector3) -> void:
	player.position = Vector3(at.x, 0.05, at.z)
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


## Walk through a gateway: fade out, build the other place, fade in.
func travel(to: String) -> void:
	if travelling:
		return
	if offline:
		_load_place(to)
		return
	travelling = true
	player.frozen = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE)
	await out.finished
	_load_place(to)
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, FADE * 1.5)
	await back.finished
	player.frozen = false
	travelling = false


func _load_place(to: String) -> void:
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()
	var built: Dictionary = Places.hub(world, doors, progress) if to == "hub" else Places.place(world, to, Rooms.room(to))
	if to != "hub":
		progress.visit(to)
		progress.save()
	here = to
	teacher = built.get("teacher", {})
	restored_columns = built.get("restored", 0)
	here_name = built["name"]
	interactables = built["interactables"]
	spots = built["spots"]
	flicker.clear()
	for l in built["flicker"]:
		if l:
			flicker.append({"light": l, "base": l.light_energy, "seed": randf() * 10.0})
	player.position = built["spawn"]
	player.rotation.y = built["yaw"]
	player.velocity = Vector3.ZERO
	target = {}
	if _where:
		_where.text = here_name


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
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE  # the locked mouse sits right here
	_ui.add_child(dot)
	_where = _label(6, Color("f0d8b0"))
	_where.position = Vector2(5, 3)
	_ui.add_child(_where)
	_prompt = _label(8, Color("f4ead6"))
	_prompt.position = Vector2(10, 146)
	_prompt.size = Vector2(RES.x - 20, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui.add_child(_prompt)
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
	_build_map_panel()
	_build_tree_panel()
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(RES)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)


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
	_lessons = RichTextLabel.new()
	_lessons.bbcode_enabled = true
	_lessons.position = Vector2(6, 95)
	_lessons.size = Vector2(60, 56)
	_lessons.scroll_active = false
	_lessons.add_theme_font_size_override("normal_font_size", 5)
	_lessons.add_theme_color_override("default_color", Color("8a8074"))
	_ask_panel.add_child(_lessons)
	var hint := _label(5, Color("8a8074"))
	hint.text = "Esc to leave  T: tablet"
	hint.position = Vector2(8, 155)
	_ask_panel.add_child(hint)
	_answer = RichTextLabel.new()
	_answer.bbcode_enabled = true
	_answer.position = Vector2(66, 8)
	_answer.size = Vector2(236, 98)
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


func _build_map_panel() -> void:
	_map_panel = Panel.new()
	_map_panel.add_theme_stylebox_override("panel", _style(0.96))
	_map_panel.position = Vector2(4, 4)
	_map_panel.size = Vector2(RES.x - 8, RES.y - 8)
	_map_panel.hide()
	_ui.add_child(_map_panel)
	_map_title = _label(8, Color("e0b660"))
	_map_title.position = Vector2(8, 3)
	_map_panel.add_child(_map_title)
	_map_image = TextureRect.new()
	_map_image.position = Vector2(6, 14)
	_map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_panel.add_child(_map_image)
	_map_marks = Control.new()
	_map_marks.position = _map_image.position
	_map_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_marks)
	_map_note = _label(6, Color("e8dcc0"))
	_map_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_panel.add_child(_map_note)
	_map_note.position = Vector2(228, 16)
	_map_note.custom_minimum_size = Vector2(80, 0)
	_map_note.size = Vector2(80, 130)
	var hint := _label(5, Color("8a8074"))
	hint.text = "F to close"
	hint.position = Vector2(RES.x - 44, 162)
	_map_panel.add_child(hint)


func _open_map(it: Dictionary) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/maps/%s.json" % it["map"]))
	if not data is Dictionary:
		return
	_map_image.texture = load("res://assets/maps/%s.png" % it["map"])
	_map_title.text = data["title"]
	_map_note.text = it.get("note", "")
	for c in _map_marks.get_children():
		c.queue_free()
	for r in data["regions"]:
		_mark(Vector2(r["label"][0], r["label"][1]), r["name"], Color("fff4e0"), 5, true)
	for o in data["others"]:
		_mark(Vector2(o["label"][0], o["label"][1]), o["name"], Color("4a3e2c"), 4, true)
	for p in data["pins"]:
		var at := Vector2(p["at"][0], p["at"][1])
		var dot := ColorRect.new()
		dot.color = Color("ffe070") if p["main"] else Color("f4f0e8")
		dot.size = Vector2(3, 3) if p["main"] else Vector2(2, 2)
		dot.position = at - dot.size / 2.0
		_map_marks.add_child(dot)
		_mark(at + Vector2(3, -4), p["name"], Color("ffe070") if p["main"] else Color("f4f0e8"), 4, false)
	_show_panel(_map_panel)


func _mark(at: Vector2, text: String, col: Color, size: int, centred: bool) -> void:
	var l := _label(size, col)
	l.text = text
	_map_marks.add_child(l)
	var w := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	l.position = at - (Vector2(w / 2.0, 3) if centred else Vector2.ZERO)


## Porphyry's Tree, the book's most famous picture: follow the family down, adding one
## difference at a time, until you reach a human, and then single people.
class TreeCanvas extends Control:
	const ROWS := [["Substance", "", "not bodily: spirit"], ["Body", "bodily", "not living: stone"],
		["Living body", "alive", "cannot feel: plant"], ["Animal", "feels", "cannot reason: beast"],
		["Human", "reasons", ""], ["Socrates, Plato...", "", ""]]

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var ink := Color("e8dcc0")
		var gold := Color("e0b660")
		var dim := Color("a89878")
		for i in ROWS.size():
			var y := 14.0 + i * 20.0
			var x := 70.0
			if i > 0:
				draw_line(Vector2(x + 8, y - 16), Vector2(x + 8, y - 6), dim, 1.0)
				if ROWS[i][1] != "":
					draw_string(font, Vector2(x + 12, y - 8), "+ " + ROWS[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, gold)
			draw_string(font, Vector2(x, y + 4), ROWS[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
			if ROWS[i][2] != "":
				draw_line(Vector2(x + 60, y + 1), Vector2(x + 120, y + 1), dim, 1.0)
				draw_string(font, Vector2(x + 124, y + 4), ROWS[i][2], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, dim)


func _build_tree_panel() -> void:
	_tree_panel = Panel.new()
	_tree_panel.add_theme_stylebox_override("panel", _style(0.96))
	_tree_panel.position = Vector2(4, 4)
	_tree_panel.size = Vector2(RES.x - 8, RES.y - 8)
	_tree_panel.hide()
	_ui.add_child(_tree_panel)
	var title := _label(8, Color("e0b660"))
	title.text = "Porphyry's Tree"
	title.position = Vector2(8, 3)
	_tree_panel.add_child(title)
	var canvas := TreeCanvas.new()
	canvas.position = Vector2(0, 14)
	canvas.size = Vector2(RES.x - 8, 124)
	_tree_panel.add_child(canvas)
	var note := _label(5, Color("e8dcc0"))
	note.text = "To say what a human is, walk down the family and add one difference at each step: a living body that feels and reasons. The genus is the family; the species is where you stop."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tree_panel.add_child(note)
	note.position = Vector2(8, 138)
	note.custom_minimum_size = Vector2(RES.x - 64, 0)
	note.size = Vector2(RES.x - 64, 30)
	var hint := _label(5, Color("8a8074"))
	hint.text = "F to close"
	hint.position = Vector2(RES.x - 44, 158)
	_tree_panel.add_child(hint)


func _open_ask(work: String) -> void:
	_ask_work = work
	_ask_room = Rooms.room(work)
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


## His first words: a greeting the first time, a welcome back that picks up where you left off.
func _greeting(work: String) -> String:
	var room := Rooms.room(work)
	var have: Array = progress.understood(work)
	if progress.is_mastered(work):
		return "You again, my friend. You know my little book as well as I do now. Ask me anything."
	if have.is_empty():
		return room.get("greeting", "Ask me anything about my book.")
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
	var fresh: Array = progress.learn(work, ids)
	if fresh.is_empty():
		return
	var room := Rooms.room(work)
	var names: Array = room.get("lesson", []).filter(func(p): return fresh.has(p["id"])).map(func(p): return p["label"])
	var note := "\n\n[color=#a6c8cc]On your tablet: %s[/color]" % ", ".join(names)
	if progress.check_mastery(work, room.get("lesson", [])):
		note += "\n\n[i][color=#e0b660]%s[/color][/i]\n[color=#e0b660]You have mastered the %s. Its gateway on the Shore now burns.[/color]" % [
			_esc(room.get("gift", "")), room.get("book", "book")]
	progress.save()
	_talk[work] = _talk.get(work, "") + note
	if _ask_panel.visible and _ask_work == work:
		_answer.text = _talk[work]
		_refresh_lessons()


## Your wax tablet: what you have understood, in plain words.
func _tablet_text() -> String:
	if here == "hub":
		return "[color=#e0b660]Your tablet[/color]\n\nBooks mastered: %d of %d." % [progress.mastered_count(), doors.size()]
	var room := Rooms.room(here)
	var have: Array = progress.understood(here)
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
	_read_panel.size = Vector2(260, 0)
	_show_panel(_read_panel)


func _show_panel(p: Control) -> void:
	p.show()
	player.frozen = true
	if not offline:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _any_panel() -> bool:
	return _read_panel.visible or _ask_panel.visible or _map_panel.visible or _tree_panel.visible


## Closing a panel puts the mouse back the way it was, so looking around just continues.
func _close_panels() -> void:
	for p in [_read_panel, _ask_panel, _map_panel, _tree_panel]:
		p.hide()
	_question_box.release_focus()
	player.frozen = false
	if not offline:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # straight back to looking around


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
	_animate_teacher(delta)
	if player.frozen:
		_prompt.text = ""
		return
	target = _nearest()
	if _t - _quit_armed < QUIT_WINDOW:
		_prompt.text = "Press Esc again to leave."
	elif target.is_empty():
		_prompt.text = ""
	elif target["kind"] == "gate" and not target["open"]:
		_prompt.text = target["text"] + "\n(not open yet)"
	elif target["kind"] == "gate":
		_prompt.text = target["text"] + ("\nF: Enter" if target["to"] != "hub" else "\nF: Go")
	else:
		_prompt.text = "F: " + target["text"]


## He breathes, writes when alone, and looks up and turns toward you when you come near.
func _animate_teacher(delta: float) -> void:
	if teacher.is_empty() or not is_instance_valid(teacher["head"]):
		return
	var root: Node3D = teacher["root"]
	var head: Node3D = teacher["head"]
	root.scale.y = 1.0 + 0.008 * sin(_t * 1.6)
	var to: Vector3 = root.to_local(player.global_position)
	var near := to.length() < 6.0 and to.z > 0.0
	var want_yaw := clampf(atan2(to.x, to.z), -0.9, 0.9) if near else 0.0
	var want_pitch := -0.12 if near else 0.35 + 0.05 * sin(_t * 0.7)
	head.rotation.y = lerpf(head.rotation.y, want_yaw, delta * 3.0)
	head.rotation.x = lerpf(head.rotation.x, want_pitch, delta * 3.0)
	var hand: Node3D = teacher["hand"]
	hand.position = Vector3(0.03 * sin(_t * 7.0), 0.0, 0.02 * sin(_t * 3.5)) if not near else hand.position.lerp(Vector3.ZERO, delta * 4.0)


func _nearest() -> Dictionary:
	var best := {}
	var best_d := INF
	var at := player.global_position
	for it in interactables:
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
	return best


func activate(it: Dictionary) -> void:
	match it.get("kind", ""):
		"fact":
			_show_read(it["text"])
		"statue":
			_show_read(it["note"])
		"map":
			_open_map(it)
		"tree":
			_show_panel(_tree_panel)
		"book":
			var book := _book(here)
			if book:
				var p: Dictionary = book.random_passage()
				_show_read("[i]%s, %s[/i]\n\n%s" % [p["where"], book.translation, _esc(excerpt(p["text"], 360))])
		"author":
			_open_ask(here)
		"gate":
			if it["open"]:
				travel(it["to"])


## Mouse look and Esc are handled here, before anything on screen can swallow them.
func _input(event: InputEvent) -> void:
	if _ok and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not player.frozen:
		player.look(event.screen_relative)  # real mouse movement, whatever the window scale
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if not _ok or _t - _quit_armed < QUIT_WINDOW:
			get_tree().quit()
		elif _any_panel():
			_close_panels()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_quit_armed = _t


func _unhandled_input(event: InputEvent) -> void:
	if not _ok:
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
	if _ask_panel.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _read_panel.visible or _map_panel.visible or _tree_panel.visible:
			_close_panels()
		elif not target.is_empty() and not travelling:
			activate(target)
