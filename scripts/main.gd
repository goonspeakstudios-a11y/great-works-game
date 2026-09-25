extends Node
## Owns the save and switches between the title menu, the 3D world, and the
## 3D card table.
## Screenshot mode for checking the look without playing:
##   godot --path . -- --shot=C:/out.png --state=world|scene|learn|table|recall [--beats=N]

const Content := preload("res://scripts/content.gd")
const Memory := preload("res://scripts/memory.gd")
const Save := preload("res://scripts/save.gd")
const Story := preload("res://scripts/story.gd")
const World := preload("res://scripts/world/world.gd")
const CardTable := preload("res://scripts/table/card_table.gd")

const BG := Color(0.07, 0.08, 0.12)
const GOLD := Color(0.95, 0.78, 0.3)
const DIM := Color(0.65, 0.68, 0.75)
const TABLE_HP := 40
const SHOT_FRAMES := 90

var content := Content.new()
var memory := Memory.new()
var save_data := Save.blank()
var save_path := Save.DEFAULT_PATH  # tests and screenshots point this elsewhere
var rng := RandomNumberGenerator.new()
var chapter: Dictionary

var menu: Control
var screen: VBoxContainer
var world: Node3D
var table: Node3D
var args := {}
var frames := 0


func _ready() -> void:
	rng.randomize()
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("save"):
		save_path = args["save"]
	_build_menu()
	if not content.load_all() or content.stories.is_empty():
		_label("Could not load the game content. Check the content folder.", 24)
		return
	var problems := content.validate()
	if not problems.is_empty():
		push_error("Content problems:\n" + "\n".join(problems))
	chapter = content.stories[0]
	save_data = Save.load_save(save_path)
	memory.from_dict(save_data["memory"])
	show_title()
	if args.has("shot"):
		_stage_shot(args.get("state", "world"))


func _process(_delta: float) -> void:
	if not args.has("shot"):
		return
	frames += 1
	if frames == SHOT_FRAMES:
		get_viewport().get_texture().get_image().save_png(args["shot"])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and world and world.is_inside_tree() and not world.in_scene:
		remove_child(world)
		show_title()


func persist() -> void:
	save_data["memory"] = memory.to_dict()
	Save.write_save(save_data, save_path)


func done_steps() -> Array:
	var story: Dictionary = save_data["story"]
	if not story.has(chapter["id"]):
		story[chapter["id"]] = []
	return story[chapter["id"]]


# ---------- menus ----------

func _build_menu() -> void:
	var t := Theme.new()
	t.default_font_size = 20
	menu = Control.new()
	menu.theme = t
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	menu.add_child(margin)
	screen = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 14)
	margin.add_child(screen)


func _clear() -> void:
	for c in screen.get_children():
		c.queue_free()


func _label(text: String, size: int = 20, color: Color = Color.WHITE, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	(parent if parent else screen).add_child(l)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 48)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(action)
	screen.add_child(b)
	return b


func show_title() -> void:
	menu.show()
	_clear()
	_label("GREAT WORKS", 52, GOLD)
	_label("A journey through the great books, where remembering is power.", 22, DIM)
	_label("Ideas learned: %d of %d" % [save_data["met"].size(), content.ideas.size()], 18, DIM)
	var started := not done_steps().is_empty()
	_button("Continue the journey" if started else "Begin the journey", enter_world)
	_button("The Library", show_library)
	if started:
		_button("Replay the chapter", func():
			done_steps().clear()
			persist()
			world = null
			enter_world())
	_button("Quit", func(): get_tree().quit())


func show_library() -> void:
	_clear()
	_label("THE LIBRARY", 36, GOLD)
	_button("Back", show_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for id in content.idea_ids():
		var idea: Dictionary = content.ideas[id]
		if not save_data["met"].has(id):
			_label("? ? ?   (not learned yet)", 20, DIM, list)
			list.add_child(HSeparator.new())
			continue
		var b := memory.box(id)
		_label("%s   [memory %s%s]" % [idea["name"], "#".repeat(b), ".".repeat(Memory.MAX_BOX - b)], 22,
			GOLD if memory.is_gold(id) else Color.WHITE, list)
		_label(idea["source"], 16, DIM, list)
		_label(idea["summary"], 18, Color.WHITE, list)
		_label("Want more? Read it yourself: %s" % idea["passage"], 16, DIM, list)
		list.add_child(HSeparator.new())


# ---------- world and table ----------

func enter_world() -> void:
	menu.hide()
	if world == null:
		world = World.new()
		world.setup(chapter, content.ideas, done_steps())
		world.idea_learned.connect(func(id: String):
			save_data["met"][id] = true
			persist())
		world.step_finished.connect(func(_id: String): persist())
		world.fight_requested.connect(start_fight)
	if not world.is_inside_tree():
		add_child(world)
		world.follow_cam.make_current()


func start_fight(step: Dictionary) -> void:
	var upto: int = chapter["steps"].find(step)
	var deck := Story.ideas_taught(chapter, upto)
	remove_child(world)
	table = CardTable.new()
	var learned: Array = save_data["met"].keys().map(func(id): return content.ideas[id])
	table.setup(step, deck, content.ideas, memory, rng, TABLE_HP, TABLE_HP, learned)
	table.memory_changed.connect(persist)
	table.fight_over.connect(end_fight)
	add_child(table)


func end_fight(won: bool) -> void:
	table.queue_free()
	table = null
	add_child(world)
	world.follow_cam.make_current()
	world.fight_finished(won)


# ---------- screenshots ----------

func _stage_shot(state: String) -> void:
	enter_world()
	if state in ["scene", "learn"]:
		world.begin_step()
		for i in int(args.get("beats", "0")):
			world.advance()
	elif state in ["table", "recall"]:
		start_fight(chapter["steps"][2])
		if state == "recall":
			table.on_card(0)
