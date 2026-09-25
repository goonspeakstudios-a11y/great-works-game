extends Node3D
## The walkable 3D chapter: the camp at Troy. Shows a glowing marker at the
## next story step; walking into it and pressing E plays the scene or asks
## main to start the card-table fight.

signal idea_learned(id: String)
signal step_finished(id: String)
signal fight_requested(step: Dictionary)

const Blocks := preload("res://scripts/world/blocks.gd")
const Story := preload("res://scripts/story.gd")
const Player := preload("res://scripts/world/player.gd")

const REACH := 2.4
const MOVE_SECONDS := 1.8
const GOLD := Color(0.95, 0.78, 0.3)
const DIM := Color(0.75, 0.78, 0.85)
const SAND := Color(0.56, 0.48, 0.34)
const DAY_SUN := 0.85
const DAY_AMBIENT := 0.45

var chapter: Dictionary
var ideas: Dictionary
var done: Array           # step ids finished; shared with the save file

var player: CharacterBody3D
var rig: Node3D
var follow_cam: Camera3D
var scene_cam: Camera3D
var cam_goal_pos := Vector3.ZERO
var cam_goal_look := Vector3.ZERO
var cam_look := Vector3.ZERO
var env: Environment
var sun: DirectionalLight3D
var actors: Dictionary = {}   # actor id -> Node3D
var marker: Node3D
var story := Story.new()
var in_scene := false
var busy := false             # a move beat is animating

var hud: CanvasLayer
var hint: Label
var talk_panel: PanelContainer
var talk_name: Label
var talk_line: Label
var learn_panel: PanelContainer
var learn_text: Label
var banner: Label


func setup(chapter_data: Dictionary, all_ideas: Dictionary, done_steps: Array) -> void:
	chapter = chapter_data
	ideas = all_ideas
	done = done_steps


func _ready() -> void:
	_build_environment()
	_build_camp()
	_build_actors()
	_build_player()
	_build_hud()
	refresh()


func _process(delta: float) -> void:
	if rig and player:
		rig.global_position = rig.global_position.lerp(player.global_position, clampf(10.0 * delta, 0, 1))
	if in_scene:
		scene_cam.global_position = scene_cam.global_position.lerp(cam_goal_pos, clampf(3.0 * delta, 0, 1))
		cam_look = cam_look.lerp(cam_goal_look, clampf(3.0 * delta, 0, 1))
		scene_cam.look_at(cam_look)
		return
	var step := current_step()
	if step.is_empty() or marker == null:
		hint.text = ""
		return
	hint.text = "Press E: %s" % step["title"] if near_marker() else "Walk to the glowing light: %s" % step["title"]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if in_scene and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_E]:
			advance()
		elif not in_scene and event.physical_keycode == KEY_E and near_marker():
			begin_step()
	elif in_scene and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


# ---------- story flow ----------

func current_step() -> Dictionary:
	var i := Story.current_step(chapter, done)
	return chapter["steps"][i] if i < chapter["steps"].size() else {}


func near_marker() -> bool:
	return marker != null and player.global_position.distance_to(marker.global_position) <= REACH


## Places the marker for the next step, or shows the ending.
func refresh() -> void:
	if marker:
		marker.queue_free()
		marker = null
	var step := current_step()
	if step.is_empty():
		banner.text = "End of the first slice. Thank you for playing.\nThe Library on the title screen holds every idea you learned."
		banner.show()
		return
	var at: Array = step["at"]
	marker = Node3D.new()
	var glow := CylinderMesh.new()
	glow.top_radius = 1.1
	glow.bottom_radius = 1.1
	glow.height = 0.08
	marker.add_child(Blocks.mesh(glow, GOLD, Vector3(0, 0.05, 0), 2.5))
	var light := OmniLight3D.new()
	light.light_color = GOLD
	light.omni_range = 5.0
	light.light_energy = 2.0
	light.position.y = 1.0
	marker.add_child(light)
	marker.add_child(Blocks.label3d(step["title"], Vector3(0, 2.6, 0), 72, GOLD))
	marker.position = Vector3(at[0], 0, at[1])
	add_child(marker)


## Starts the current step: a fight goes to main, a scene plays here.
func begin_step() -> void:
	var step := current_step()
	if step.is_empty() or in_scene:
		return
	if step["type"] == "fight":
		fight_requested.emit(step)
		return
	in_scene = true
	player.enabled = false
	hint.text = ""
	marker.hide()
	_set_night(step.get("night", false))
	for id in step.get("cast", {}):
		var p: Array = step["cast"][id]
		var a: Node3D = actors[id]
		a.position = Vector3(p[0], 0, p[1])
		a.show()
	var center := _cast_center(step)
	for id in step.get("cast", {}):
		_face(actors[id], center)
	scene_cam.global_position = follow_cam.global_position
	cam_look = center + Vector3(0, 1.2, 0)
	scene_cam.make_current()
	story.start(step)
	advance()


## Shows the next beat, or ends the scene.
func advance() -> void:
	if not in_scene or busy:
		return
	learn_panel.hide()
	var beat := story.next()
	if beat.is_empty():
		_end_scene()
		return
	match Story.beat_kind(beat):
		"say":
			_show_line(beat)
		"move":
			_move_actor(beat)
		"learn":
			_show_learn(beat["learn"])


## Called by main when the card-table fight ends.
func fight_finished(won: bool) -> void:
	var step := current_step()
	if won and step.get("type", "") == "fight":
		done.append(step["id"])
		step_finished.emit(step["id"])
		refresh()


func _end_scene() -> void:
	var step := current_step()
	in_scene = false
	talk_panel.hide()
	learn_panel.hide()
	follow_cam.make_current()
	player.enabled = true
	_set_night(false)
	done.append(step["id"])
	step_finished.emit(step["id"])
	refresh()


func _show_line(beat: Dictionary) -> void:
	var who: String = beat["say"]
	talk_panel.show()
	talk_line.text = beat["line"]
	if who == "narrator":
		talk_name.text = ""
		_frame_wide()
	else:
		talk_name.text = chapter["actors"][who]["name"]
		_frame_speaker(actors[who])


func _move_actor(beat: Dictionary) -> void:
	busy = true
	talk_panel.hide()
	var a: Node3D = actors[beat["move"]]
	var to := Vector3(beat["to"][0], 0, beat["to"][1])
	_face(a, to)
	_frame_wide()
	var tw := create_tween()
	tw.tween_property(a, "position", to, MOVE_SECONDS)
	tw.finished.connect(func():
		busy = false
		advance())


func _show_learn(id: String) -> void:
	var idea: Dictionary = ideas[id]
	talk_panel.hide()
	var effects: Array[String] = []
	for e in idea["effects"]:
		effects.append("%s %d" % [str(e["kind"]).capitalize(), int(e["value"])])
	learn_text.text = "IDEA LEARNED\n%s\n\n%s\n\nNew card: cost %d. %s" % [idea["name"], idea["summary"], int(idea["cost"]), ", ".join(effects)]
	learn_panel.show()
	idea_learned.emit(id)


# ---------- camera ----------

func _cast_center(step: Dictionary) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for id in step.get("cast", {}):
		sum += actors[id].position
		n += 1
	return sum / maxf(n, 1)


func _frame_wide() -> void:
	var center := _cast_center(story.scene)
	var away := (player.global_position - center)
	away.y = 0
	away = away.normalized() if away.length() > 0.1 else Vector3(0, 0, 1)
	cam_goal_pos = center + away * 8.0 + Vector3(0, 4.0, 0)
	cam_goal_look = center + Vector3(0, 1.0, 0)


func _frame_speaker(a: Node3D) -> void:
	var facing := -a.global_transform.basis.z
	facing.y = 0
	var side := facing.cross(Vector3.UP).normalized() * 0.9
	cam_goal_pos = a.global_position + facing.normalized() * 3.2 + side + Vector3(0, 1.9, 0)
	cam_goal_look = a.global_position + Vector3(0, 1.5, 0)


func _face(a: Node3D, target: Vector3) -> void:
	var t := Vector3(target.x, a.global_position.y, target.z)
	if a.global_position.distance_to(t) > 0.05:
		a.look_at(t, Vector3.UP)


func _set_night(on: bool) -> void:
	env.background_energy_multiplier = 0.15 if on else 1.0
	env.ambient_light_energy = 0.12 if on else DAY_AMBIENT
	sun.light_energy = 0.1 if on else DAY_SUN
	sun.light_color = Color(0.55, 0.62, 0.9) if on else Color(1.0, 0.95, 0.85)


# ---------- building ----------

func _build_environment() -> void:
	env = Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.5, 0.8)
	sky_mat.sky_horizon_color = Color(0.8, 0.75, 0.65)
	sky_mat.ground_horizon_color = Color(0.8, 0.75, 0.65)
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ambient_light_energy = DAY_AMBIENT
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	sun.light_energy = DAY_SUN
	add_child(sun)


func _build_camp() -> void:
	add_child(Blocks.solid_box(Vector3(140, 1, 120), SAND, Vector3(0, -0.5, 10)))
	var sea := PlaneMesh.new()
	sea.size = Vector2(300, 120)
	add_child(Blocks.mesh(sea, Color(0.15, 0.35, 0.55), Vector3(0, 0.02, -80)))
	# Agamemnon's and Achilles' tents, and a scatter of others.
	add_child(Blocks.tent(6, 5, Color(0.6, 0.25, 0.3), Vector3(0, 0, -4)))
	add_child(Blocks.tent(5, 4, Color(0.75, 0.65, 0.4), Vector3(16, 0, -4)))
	for p in [Vector3(-9, 0, -2), Vector3(-15, 0, 3), Vector3(8, 0, 6), Vector3(24, 0, 2), Vector3(-20, 0, -6)]:
		add_child(Blocks.tent(3.5, 3, Color(0.7, 0.66, 0.58), p))
	# Beached ships along the shore, bows toward the sea.
	for i in 9:
		var x := -28.0 + i * 7.0
		var ship := Blocks.solid_box(Vector3(2.2, 1.4, 9), Color(0.35, 0.25, 0.18), Vector3(x, 0.7, -16), deg_to_rad(randf_range(-6, 6)))
		var mast := CylinderMesh.new()
		mast.top_radius = 0.08
		mast.bottom_radius = 0.1
		mast.height = 6
		ship.add_child(Blocks.mesh(mast, Color(0.3, 0.22, 0.15), Vector3(0, 3.5, 0)))
		add_child(ship)
	# The walls of Troy across the plain.
	add_child(Blocks.solid_box(Vector3(70, 9, 4), Color(0.72, 0.68, 0.6), Vector3(0, 4.5, 64)))
	for x in [-30, -10, 10, 30]:
		add_child(Blocks.solid_box(Vector3(5, 13, 5), Color(0.68, 0.64, 0.56), Vector3(x, 6.5, 64)))
	add_child(Blocks.label3d("TROY", Vector3(0, 16, 64), 200, Color(0.95, 0.9, 0.8)))


func _build_actors() -> void:
	for id in chapter["actors"]:
		var data: Dictionary = chapter["actors"][id]
		var c: Array = data["color"]
		var a := Blocks.figure(data["name"], Color(c[0], c[1], c[2]))
		add_child(a)
		actors[id] = a
		if data["home"] == null:
			a.hide()
			a.position = Vector3(0, -50, 0)
		else:
			a.position = Vector3(data["home"][0], 0, data["home"][1])


func _build_player() -> void:
	player = Player.new()
	var s: Array = chapter["player_start"]
	player.position = Vector3(s[0], 0.1, s[1])
	add_child(player)
	rig = Node3D.new()
	rig.position = player.position
	add_child(rig)
	player.rig = rig
	follow_cam = Camera3D.new()
	follow_cam.position = Vector3(0, 4.5, 7.5)
	follow_cam.rotation_degrees.x = -24
	rig.add_child(follow_cam)
	follow_cam.make_current()
	scene_cam = Camera3D.new()
	add_child(scene_cam)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	hint = _hud_label(22, GOLD, null, false)
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.position.y = 24
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _hud_label(16, DIM, null, false)
	help.text = "WASD move   Q/E or right-drag turn   E interact   Space next"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(16, -32)
	talk_panel = _panel(Control.PRESET_BOTTOM_WIDE, 170)
	var v := VBoxContainer.new()
	talk_panel.add_child(v)
	talk_name = _hud_label(24, GOLD, v)
	talk_line = _hud_label(22, Color.WHITE, v)
	var more := _hud_label(15, DIM, v)
	more.text = "Space or click to continue"
	learn_panel = _panel(Control.PRESET_CENTER, 0)
	learn_panel.custom_minimum_size = Vector2(640, 0)
	learn_text = _hud_label(21, Color.WHITE, learn_panel)
	banner = _hud_label(26, GOLD)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.hide()


func _hud_label(size: int, color: Color, parent: Node = null, wrap: bool = true) -> Label:
	var l := Label.new()
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	(parent if parent else hud).add_child(l)
	return l


func _panel(preset: int, height: int) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.9)
	sb.border_color = GOLD.darkened(0.3)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", sb)
	hud.add_child(p)
	p.set_anchors_and_offsets_preset(preset)
	if preset == Control.PRESET_BOTTOM_WIDE:
		p.offset_top = -height - 20
		p.offset_bottom = -20
		p.offset_left = 80
		p.offset_right = -80
	elif preset == Control.PRESET_CENTER:
		p.grow_horizontal = Control.GROW_DIRECTION_BOTH
		p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.hide()
	return p
