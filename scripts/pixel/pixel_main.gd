extends Node
## Entry point of the pixel game. Plays the stages in reading-list order; this test
## build has stage 1 (the Isagoge) only. Esc quits, F11 toggles fullscreen.
## Screenshot mode for checking the look without playing:
##   godot --path . -- --shot=C:/out.png --state=tree|carry|refuse|hall|beast|done

const Content := preload("res://scripts/content.gd")
const Stage := preload("res://scripts/pixel/isagoge_stage.gd")
const Music := preload("res://scripts/pixel/music.gd")
const SHOT_FRAMES := 150

var stage: Stage
var args := {}
var frames := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var content := Content.new()
	if not content.load_all():
		push_error("Could not load the game content.")
		return
	if content.work_order[0] != Stage.WORK_ID:
		push_error("The reading list no longer starts with the Isagoge; stage 1 needs updating.")
	if not args.has("shot"):
		add_child(Music.new())
	_start()


func _start() -> void:
	stage = Stage.new()
	add_child(stage)
	if args.has("shot"):
		_stage_shot(args.get("state", "tree"))


func _process(_delta: float) -> void:
	if not args.has("shot"):
		return
	frames += 1
	if frames == SHOT_FRAMES:
		get_viewport().get_texture().get_image().save_png(args["shot"])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.physical_keycode == KEY_F11:
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if stage and stage.phase == "done" and stage.t > 0.0 and event.is_action_pressed("interact"):
		stage.queue_free()
		_start()


func _stage_shot(state: String) -> void:
	match state:
		"carry":
			stage.carried = "masked"
			stage.hero = Vector2(222, 110)
		"refuse":
			stage.carried = "masked"
			stage.hero = Vector2(222, 104)
			stage._refuse(3, false)
			stage.gate_seen = [true, true, true, false]
			stage.debug_place("wisp")
			stage.debug_place("stone")
			stage.debug_place("oak")
		"hall", "beast", "done":
			for thing in Stage.Logic.THINGS:
				stage.debug_place(thing)
			if state == "beast":
				stage.debug_pull("cloak")
				stage.debug_pull("flame")
			elif state == "done":
				for mark in ["cloak", "wreath", "mask"]:
					stage.debug_pull(mark)
