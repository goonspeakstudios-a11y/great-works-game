extends Node
## Entry point of the pixel game: a title menu, then the Module 1 stages in
## reading-list order. Esc returns to the menu (or quits from it); F11 toggles fullscreen.
## Screenshot mode for checking the look without playing:
##   godot --path . -- --shot=C:/out.png --stage=1..5 [--line=N]
## --line=N plays the stage automatically up to its Nth line, then holds there.

const Content := preload("res://scripts/content.gd")
const Guided := preload("res://scripts/pixel/guided.gd")
const Music := preload("res://scripts/pixel/music.gd")
const Look := preload("res://scripts/pixel/look.gd")
const Pix := preload("res://scripts/pixel/pix.gd")
const STAGES := [
	{"script": preload("res://scripts/pixel/stages/s1_isagoge.gd"), "title": "Porphyry's Game", "work": "Porphyry, Isagoge"},
	{"script": preload("res://scripts/pixel/stages/s2_categories.gd"), "title": "The Ten Questions", "work": "Aristotle, Categories"},
	{"script": preload("res://scripts/pixel/stages/s3_organon.gd"), "title": "Tricksters in the Market", "work": "Aristotle, the Organon"},
	{"script": preload("res://scripts/pixel/stages/s4_herennium.gd"), "title": "The Memory Palace", "work": "Rhetorica ad Herennium"},
	{"script": preload("res://scripts/pixel/stages/s5_euclid.gd"), "title": "No Royal Road", "work": "Euclid, Elements"},
]
const SHOT_FRAMES := 150

var stage: Node
var current := -1
var run_all := false
var menu: CanvasLayer
var args := {}
var frames := 0


func _ready() -> void:
	Guided.ensure_actions()
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var content := Content.new()
	if not content.load_all():
		push_error("Could not load the game content.")
	elif content.work_order.slice(0, STAGES.size()) != STAGES.map(func(s): return s["script"].WORK_ID):
		push_error("Module 1 stages no longer match the reading list order.")
	if args.has("shot"):
		_play(int(args.get("stage", "1")) - 1)
		return
	add_child(Music.new())
	_show_menu()


func _process(_delta: float) -> void:
	if not args.has("shot"):
		return
	frames += 1
	if frames == SHOT_FRAMES:
		get_viewport().get_texture().get_image().save_png(args["shot"])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif event.physical_keycode == KEY_ESCAPE:
			if stage:
				_end_stage()
				_show_menu()
			else:
				get_tree().quit()
	if stage and stage.phase == "done" and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_end_stage()
		if run_all and current + 1 < STAGES.size():
			_play(current + 1)
		else:
			_show_menu()


func _play(i: int) -> void:
	if menu:
		menu.queue_free()
		menu = null
	current = i
	stage = STAGES[i]["script"].new()
	if args.has("line"):
		stage.auto = true
		stage.auto_until = int(args["line"])
	add_child(stage)


func _end_stage() -> void:
	if stage:
		stage.queue_free()
		stage = null


func _show_menu() -> void:
	menu = CanvasLayer.new()
	menu.layer = 20
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Pix.P["void"]
	bg.size = Vector2(Pix.W, Pix.H)
	menu.add_child(bg)
	var title := Look.label(20, Pix.P["bone"])
	title.text = "GREAT WORKS"
	title.position = Vector2(0, 14)
	title.size = Vector2(Pix.W, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(title)
	var sub := Look.label(8, Pix.P["ghost"])
	sub.text = "Module 1: How to Read and Argue"
	sub.position = Vector2(0, 42)
	sub.size = Vector2(Pix.W, 12)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(sub)
	var list := VBoxContainer.new()
	list.position = Vector2(70, 62)
	list.add_theme_constant_override("separation", 2)
	menu.add_child(list)
	var first := _menu_button(list, "Play the whole module", func():
		run_all = true
		_play(0))
	for i in STAGES.size():
		_menu_button(list, "%d.  %s   (%s)" % [i + 1, STAGES[i]["title"], STAGES[i]["work"]], func():
			run_all = false
			_play(i))
	_menu_button(list, "Quit", func(): get_tree().quit())
	first.grab_focus()


func _menu_button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(180, 12)
	b.add_theme_font_size_override("font_size", 7)
	b.add_theme_color_override("font_color", Pix.P["bone"])
	b.add_theme_color_override("font_focus_color", Pix.P["gold"])
	b.add_theme_color_override("font_hover_color", Pix.P["gold"])
	var normal := Look.panel_style(0.9)
	normal.content_margin_top = 1
	normal.content_margin_bottom = 1
	var lit := normal.duplicate()
	lit.border_color = Pix.P["gold"]
	for s in ["normal", "hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(s, lit if s != "normal" else normal)
	b.pressed.connect(action)
	parent.add_child(b)
	return b
