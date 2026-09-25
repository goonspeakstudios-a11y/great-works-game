extends Node
## Base for guided-story stages. A memory plays in colour: characters talk one short
## line at a time, the player makes simple choices and sometimes walks somewhere.
## Stages override setup() and story(), and use await say(), await choose(),
## await walk_to() and await pause().
## With auto = true (tests) every line, choice and walk resolves at once, so a whole
## stage runs synchronously. auto_until = N stops auto after N lines (for screenshots).

signal completed
signal _advance
signal _picked(index: int)
signal _arrived

const Look := preload("res://scripts/pixel/look.gd")
const Pix := preload("res://scripts/pixel/pix.gd")
const Art := preload("res://scripts/pixel/art.gd")

const WALK_SPEED := 52.0
const GRAY := 0.15

var auto := false
var auto_until := -1
var auto_pick: Callable = func(_options: Array) -> int: return 0
var look: Look
var phase := "story"  # story -> done
var t := 0.0
var bg: Texture2D
var cast := {}  # id -> actor dictionary (see Art.actor)
var hero := ""  # the cast member the player walks
var place_note := ""
var choice_left := false  # put choices on the left, for stages with something to read on the right
var card_title := ""
var card_sub := ""
var said: Array = []  # every line spoken, in order (tests read this)
var picks: Array = []  # every option chosen, in order
var walking := false
var _target := Vector2.ZERO
var _radius := 8.0
var _waiting := false
var _wait_from := 0.0
var _choices: Container


static func ensure_actions() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	}
	var pads := {"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN, "interact": JOY_BUTTON_A}
	var sticks := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in binds:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.3)
		for key in binds[action]:
			var k := InputEventKey.new()
			k.physical_keycode = key
			InputMap.action_add_event(action, k)
		var b := InputEventJoypadButton.new()
		b.button_index = pads[action]
		InputMap.action_add_event(action, b)
		if sticks.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = sticks[action][0]
			m.axis_value = sticks[action][1]
			InputMap.action_add_event(action, m)


func _ready() -> void:
	ensure_actions()
	look = Look.new()
	add_child(look)
	look.setup(_draw_world, _draw_vivid)
	look.set_saturation(GRAY)
	setup()
	look.note.text = place_note
	_run()


func _run() -> void:
	await pause(0.8)
	look.set_saturation(1.0, 2.5)
	await story()
	look.speak("", "")
	look.set_saturation(GRAY, 3.0)
	await pause(1.5)
	phase = "done"
	look.show_card(card_title, card_sub)
	look.say("Press E to continue.")
	completed.emit()


## Stages build their background and cast here.
func setup() -> void:
	pass


## Stages tell their story here.
func story() -> void:
	pass


# ---------- story verbs ----------

func say(who: String, words: String) -> void:
	if auto and auto_until >= 0 and said.size() >= auto_until:
		auto = false
	said.append(words)
	look.speak(cast[who]["name"] if cast.has(who) else who, words)
	if auto:
		return
	_waiting = true
	_wait_from = t
	await _advance


func choose(options: Array) -> int:
	var i := 0
	if auto:
		i = auto_pick.call(options)
	else:
		_show_choices(options)
		i = await _picked
	picks.append(options[i])
	return i


## Lets the player walk the hero until they reach target.
func walk_to(target: Vector2, radius: float = 8.0) -> void:
	if auto:
		cast[hero]["at"] = target
		return
	_target = target
	_radius = radius
	walking = true
	await _arrived


func pause(seconds: float) -> void:
	if auto:
		return
	await get_tree().create_timer(seconds).timeout


func show_actor(id: String, on: bool = true) -> void:
	cast[id]["visible"] = on


## Where the hero may stand while walking; stages with walking override this.
func can_stand(_p: Vector2) -> bool:
	return true


# ---------- input and motion ----------

func _process(delta: float) -> void:
	t += delta
	if not walking:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var a: Dictionary = cast[hero]
	for step in [Vector2(dir.x, 0), Vector2(0, dir.y)]:
		var to: Vector2 = a["at"] + step * WALK_SPEED * delta
		if can_stand(to):
			a["at"] = to
	a["moving"] = dir != Vector2.ZERO
	if a["at"].distance_to(_target) <= _radius:
		walking = false
		a["moving"] = false
		_arrived.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _choices and event is InputEventKey and event.pressed and event.physical_keycode == KEY_E:
		for i in _choices.get_child_count():
			if (_choices.get_child(i) as Button).has_focus():
				_pick(i)
				get_viewport().set_input_as_handled()
				return
	if not _waiting or t - _wait_from < 0.2:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("interact"):
		_waiting = false
		get_viewport().set_input_as_handled()
		_advance.emit()


func _show_choices(options: Array) -> void:
	var two := options.size() > 5
	var grid := GridContainer.new()
	grid.columns = 2 if two else 1
	grid.add_theme_constant_override("v_separation", 1)
	grid.add_theme_constant_override("h_separation", 2)
	var width := 150.0
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(width, 11)
		b.add_theme_font_size_override("font_size", 7)
		b.add_theme_color_override("font_color", Pix.P["bone"])
		b.add_theme_color_override("font_focus_color", Pix.P["gold"])
		b.add_theme_color_override("font_hover_color", Pix.P["gold"])
		var normal := Look.panel_style(0.9)
		normal.content_margin_top = 1
		normal.content_margin_bottom = 1
		var lit := normal.duplicate()
		lit.border_color = Pix.P["gold"]
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", lit)
		b.add_theme_stylebox_override("focus", lit)
		b.add_theme_stylebox_override("pressed", lit)
		b.pressed.connect(_pick.bind(i))
		grid.add_child(b)
	var rows := ceili(options.size() / 2.0) if two else options.size()
	var w := width * (2 if two else 1) + (2 if two else 0)
	grid.position = Vector2(10.0 if choice_left else Pix.W - 10 - w, Look.BOX_TOP - 14 - rows * 12)
	look.ui.add_child(grid)
	_choices = grid
	(grid.get_child(0) as Button).grab_focus()


func _pick(i: int) -> void:
	if not _choices:
		return
	_choices.queue_free()
	_choices = null
	_picked.emit(i)


# ---------- drawing ----------

func _draw_world(ci: CanvasItem) -> void:
	if bg:
		ci.draw_texture(bg, Vector2.ZERO)
	draw_scene(ci)
	var ids := cast.keys().filter(func(id): return cast[id]["visible"])
	ids.sort_custom(func(a, b): return cast[a]["at"].y < cast[b]["at"].y)
	for id in ids:
		var a: Dictionary = cast[id]
		var bob := 1.0 if a.get("moving", false) and int(t * 8.0) % 2 == 0 else 0.0
		ci.draw_rect(Rect2(a["at"].x - 4 * a["scale"], a["at"].y, 8 * a["scale"], 1), Color(0, 0, 0, 0.3))
		Pix.sprite(ci, a["rows"], a["pal"], a["at"] - Vector2(0, bob), a["scale"], false, a["alpha"])
	draw_front(ci)


func _draw_vivid(ci: CanvasItem) -> void:
	draw_memory(ci)


## Props under the cast.
func draw_scene(_ci: CanvasItem) -> void:
	pass


## Things over the cast (boards, diagrams).
func draw_front(_ci: CanvasItem) -> void:
	pass


## Things that keep their colour even when the world turns gray.
func draw_memory(_ci: CanvasItem) -> void:
	pass
