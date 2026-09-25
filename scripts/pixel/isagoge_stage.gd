extends Node
## Stage 1: Porphyry's Isagoge, a silent puzzle.
## The tree room: carry five things down Porphyry's tree. Each fork is a gate marked
## with one difference (body, life, senses, reason). The "with" gate lets a thing through
## only if it has that difference; the "without" door up to an alcove only if it lacks it.
## The man in the horse mask looks like a beast but reasons, so he goes to the end.
## The statue hall: pull the marks off the statue. Accidents fall away, the property
## comes back, and taking the difference turns the man into a beast.

signal completed

const WORK_ID := "porphyry-isagoge"
const Logic := preload("res://scripts/pixel/isagoge_logic.gd")
const Pix := preload("res://scripts/pixel/pix.gd")
const Look := preload("res://scripts/pixel/look.gd")

const SPEED := 42.0
const GATES_X := [70, 130, 190, 250]
const TRUNK := Rect2(8, 104, 304, 42)
const OPEN_TOP := 112.0
const OPEN_BOTTOM := 138.0
const DOOR_LINE := 96.0
const HUMAN_SPOT := Vector2(292, 122)
const START := {"wisp": Vector2(18, 116), "stone": Vector2(18, 140), "oak": Vector2(33, 128),
	"horse": Vector2(48, 116), "masked": Vector2(48, 140)}
const WORDS := ["body", "life", "senses", "reason"]
const HALL_FLOOR := Rect2(40, 46, 240, 100)
const PEDESTAL := Rect2(144, 86, 32, 20)
const STATUE_FEET := Vector2(160, 90)
const MARK_SPOT := {"cloak": Vector2(118, 98), "wreath": Vector2(126, 62), "mask": Vector2(194, 62),
	"laugh": Vector2(202, 98), "flame": Vector2(160, 50)}

var logic := Logic.new()
var look: Look
var phase := "tree"  # tree -> hall -> done
var hero := Vector2(60, 128)
var facing := 1
var moving := false
var carried := ""
var spot := {}  # thing -> where it sits on the floor or its pedestal
var gate_flash := [0.0, 0.0, 0.0, 0.0]
var door_flash := [0.0, 0.0, 0.0, 0.0]
var gate_seen := [false, false, false, false]
var hinted := {}
var fallen: Array = []  # accidents pulled off the statue: {mark, at, t}
var laugh_away := 0.0
var words_hall: Array = []  # passing words: {text, at, t}
var t := 0.0
var _bg_tree: ImageTexture
var _bg_hall: ImageTexture


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
	for thing in START:
		spot[thing] = START[thing]
	_bg_tree = _build_tree_bg()
	_bg_hall = _build_hall_bg()
	look = Look.new()
	add_child(look)
	look.setup(_draw_world, _draw_vivid)
	look.set_saturation(0.3)


func _process(delta: float) -> void:
	t += delta
	for i in 4:
		gate_flash[i] = maxf(0.0, gate_flash[i] - delta)
		door_flash[i] = maxf(0.0, door_flash[i] - delta)
	laugh_away = maxf(0.0, laugh_away - delta)
	for f in fallen:
		f["t"] += delta
	for w in words_hall:
		w["t"] += delta
	words_hall = words_hall.filter(func(w): return w["t"] < 3.5)
	_script_lines()
	if phase == "done":
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir != Vector2.ZERO
	if moving:
		if dir.x != 0.0:
			facing = 1 if dir.x > 0.0 else -1
		_step(Vector2(dir.x, 0) * SPEED * delta)
		_step(Vector2(0, dir.y) * SPEED * delta)
	if Input.is_action_just_pressed("interact"):
		interact()


# ---------- rules in motion ----------

func _step(d: Vector2) -> void:
	var to := hero + d
	if not _walkable(to):
		return
	if phase == "tree" and carried != "" and not _gates_allow(hero, to):
		return
	hero = to


func _walkable(p: Vector2) -> bool:
	for c in [Vector2(-3, 0), Vector2(3, 0), Vector2(-3, -3), Vector2(3, -3)]:
		if not _floor(p + c):
			return false
	return true


func _floor(p: Vector2) -> bool:
	if phase != "tree":
		return HALL_FLOOR.has_point(p) and not PEDESTAL.has_point(p)
	if Rect2(HUMAN_SPOT.x - 5, HUMAN_SPOT.y - 6, 10, 7).has_point(p):
		return false
	if TRUNK.has_point(p):
		for gx in GATES_X:
			if absf(p.x - gx) < 3.0 and (p.y < OPEN_TOP or p.y > OPEN_BOTTOM):
				return false
		return true
	for i in 4:
		var ax := _alcove_x(i)
		if Rect2(ax - 5, 50, 10, 7).has_point(p):
			return false  # the pedestal
		if Rect2(ax - 20, 30, 40, 58).has_point(p) or Rect2(ax - 6, 86, 12, 20).has_point(p):
			return true
	return false


## Crossing a gate or door while carrying a thing asks the tree whether it may pass.
func _gates_allow(from: Vector2, to: Vector2) -> bool:
	for i in 4:
		var gx: float = GATES_X[i]
		if (from.x < gx) != (to.x < gx) and to.y >= OPEN_TOP and to.y <= OPEN_BOTTOM:
			if not Logic.may_pass(carried, i, true):
				_refuse(i, true)
				return false
			gate_seen[i] = true
		var ax := _alcove_x(i)
		if (from.y < DOOR_LINE) != (to.y < DOOR_LINE) and absf(to.x - ax) <= 6.0:
			if not Logic.may_pass(carried, i, false):
				_refuse(i, false)
				return false
	return true


func _refuse(fork: int, with_gate: bool) -> void:
	if with_gate:
		gate_flash[fork] = 0.6
	else:
		door_flash[fork] = 0.6
		if carried == "masked" and not hinted.has("closer"):
			hinted["closer"] = true
			look.say("Look closer.", 4.0)


func interact() -> void:
	if phase == "tree":
		_interact_tree()
	elif phase == "hall":
		_interact_hall()


func _interact_tree() -> void:
	if carried != "":
		for leaf in _pedestals():
			if hero.distance_to(_pedestals()[leaf]) < 16.0 and logic.place(carried, leaf):
				_placed(carried, leaf)
				return
		if _walkable(hero + Vector2(facing * 6, 0)):
			spot[carried] = hero + Vector2(facing * 6, 0)
		else:
			spot[carried] = hero
		carried = ""
		return
	var best := ""
	var best_d := 12.0
	for thing in spot:
		if logic.placed.has(thing):
			continue
		var d := hero.distance_to(spot[thing])
		if d < best_d:
			best = thing
			best_d = d
	carried = best


func _placed(thing: String, leaf: String) -> void:
	spot[thing] = _pedestals()[leaf] + Vector2(0, -7)
	if thing == carried:
		carried = ""
	if logic.tree_done():
		_enter_hall()


func _interact_hall() -> void:
	for mark in MARK_SPOT:
		if hero.distance_to(MARK_SPOT[mark]) > 16.0:
			continue
		if mark == "flame" and logic.removed.has("flame"):
			logic.restore("flame")
			words_hall.append({"text": "human", "at": STATUE_FEET + Vector2(0, -44), "t": 0.0})
			return
		if logic.marks_on().has(mark):
			_pull(mark)
			return


func _pull(mark: String) -> void:
	var kind := logic.pull(mark)
	match kind:
		"accident":
			fallen.append({"mark": mark, "at": MARK_SPOT[mark], "t": 0.0})
		"property":
			laugh_away = 2.0
		"difference":
			pass
	words_hall.append({"text": kind, "at": MARK_SPOT[mark] + Vector2(0, -10), "t": 0.0})
	if logic.statue_done():
		_finish()


func _enter_hall() -> void:
	phase = "hall"
	hero = Vector2(160, 136)
	carried = ""
	look.fade_in(1.6)
	look.say("Take away what does not matter.", 6.0)


func _finish() -> void:
	phase = "done"
	look.set_saturation(1.0, 3.0)
	look.say("It is still a man. Nothing else was needed.", 0.0)
	look.show_card("Stage 1 complete", "Porphyry, Isagoge (about 270 AD). Press E to play again.")
	completed.emit()


func _script_lines() -> void:
	if phase != "tree":
		return
	if not hinted.has("lost") and t > 0.8:
		hinted["lost"] = true
		look.say("Everything here has lost its place.", 3.5)
	elif not hinted.has("belongs") and t > 4.6:
		hinted["belongs"] = true
		look.say("Put each thing where it belongs.", 5.0)


# ---------- test and screenshot hooks ----------

func debug_place(thing: String) -> void:
	if logic.place(thing, Logic.home_of(thing)):
		_placed(thing, Logic.home_of(thing))


func debug_pull(mark: String) -> void:
	_pull(mark)


# ---------- layout helpers ----------

static func _alcove_x(i: int) -> float:
	return GATES_X[i] - 30.0


func _pedestals() -> Dictionary:
	var out := {Logic.LAST_LEAF: HUMAN_SPOT}
	for i in 4:
		out[Logic.FORKS[i]["without"]] = Vector2(_alcove_x(i), 57)
	return out


# ---------- drawing ----------

func _draw_world(ci: CanvasItem) -> void:
	if phase == "tree":
		ci.draw_texture(_bg_tree, Vector2.ZERO)
		_draw_gates(ci)
	else:
		ci.draw_texture(_bg_hall, Vector2.ZERO)
		_draw_pedestal(ci, PEDESTAL)
	var order: Array = []
	if phase == "tree":
		for thing in spot:
			if thing != carried and not logic.placed.has(thing):
				order.append([spot[thing].y, "thing", thing])
		for leaf in _pedestals():
			var p: Vector2 = _pedestals()[leaf]
			_draw_pedestal(ci, Rect2(p.x - 5, p.y - 7, 10, 8))
	else:
		for f in fallen:
			var drop := minf(1.0, f["t"] / 0.5)
			var a := clampf(1.0 - (f["t"] - 1.5) / 2.0, 0.0, 1.0)
			if a > 0.0:
				Pix.sprite(ci, Pix.ICON[f["mark"]], Pix.ICON_PAL, f["at"] + Vector2(0, 14 * drop), 1, false, a)
		if logic.statue_kind() == "beast":
			Pix.sprite(ci, Pix.THING["horse"], Pix.THING_PAL, STATUE_FEET, 2)
	order.append([hero.y, "hero", ""])
	order.sort_custom(func(a, b): return a[0] < b[0])
	for o in order:
		if o[1] == "hero":
			_draw_hero(ci)
		else:
			_draw_thing(ci, o[2], spot[o[2]])


func _draw_vivid(ci: CanvasItem) -> void:
	if phase == "tree":
		for thing in logic.placed:
			_draw_thing(ci, thing, spot[thing])
			Pix.text(ci, Vector2(_pedestals()[logic.placed[thing]].x, _leaf_word_y(logic.placed[thing])),
				logic.placed[thing], 6, Pix.P["ghost"])
		for i in 4:
			var gx: float = GATES_X[i]
			if gate_seen[i]:
				Pix.text(ci, Vector2(gx, 154), WORDS[i], 6, Pix.P["ghostD"])
			if gate_flash[i] > 0.0:
				var c: Color = Pix.P["bars"]
				c.a = gate_flash[i] / 0.6
				for yy in range(int(OPEN_TOP), int(OPEN_BOTTOM), 3):
					ci.draw_rect(Rect2(gx - 1, yy, 2, 2), c)
			if door_flash[i] > 0.0:
				var c2: Color = Pix.P["bars"]
				c2.a = door_flash[i] / 0.6
				var ax := _alcove_x(i)
				for xx in range(int(ax - 6), int(ax + 6), 3):
					ci.draw_rect(Rect2(xx, DOOR_LINE - 1, 2, 2), c2)
		_draw_masked_flame(ci)
	else:
		_draw_statue(ci)


## The man in the mask keeps a tiny flame of reason: the one warm thing in the gray.
func _draw_masked_flame(ci: CanvasItem) -> void:
	var at: Vector2 = hero + Vector2(0, -15) if carried == "masked" else spot["masked"]
	if logic.placed.has("masked"):
		return  # placed things are drawn in full colour anyway
	var flick := 1 if sin(t * 9.0) > 0.0 else 0
	ci.draw_rect(Rect2(at.x, at.y - 14 - flick, 1, 2), Pix.P["emberL"])
	ci.draw_rect(Rect2(at.x, at.y - 12, 1, 1), Pix.P["ember"])


func _leaf_word_y(leaf: String) -> float:
	return 150.0 if leaf == Logic.LAST_LEAF else 26.0


func _draw_hero(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(hero.x - 3, hero.y, 7, 1), Color(0, 0, 0, 0.35))
	var frame: int = (int(t * 7.0) % 2) if moving else 0
	Pix.sprite(ci, Pix.HERO[frame], Pix.HERO_PAL, hero + Vector2(0, 1), 1, facing < 0)
	if carried != "":
		_draw_thing(ci, carried, hero + Vector2(0, -15))


func _draw_thing(ci: CanvasItem, thing: String, at: Vector2) -> void:
	if thing == "wisp":
		var bob := sin(t * 2.0) * 1.5
		var glow: Color = Pix.P["ghost"]
		glow.a = 0.25
		ci.draw_circle(at + Vector2(0, -6 + bob), 4.0, glow)
		ci.draw_circle(at + Vector2(0, -6 + bob), 2.0, Pix.P["ghost"])
		ci.draw_rect(Rect2(at.x - 1, at.y - 7 + bob, 1, 1), Color.WHITE)
		return
	Pix.sprite(ci, Pix.THING[thing], Pix.THING_PAL, at)


func _draw_gates(ci: CanvasItem) -> void:
	for i in 4:
		var gx: float = GATES_X[i]
		for r in [Rect2(gx - 3, 98, 7, 14), Rect2(gx - 3, 138, 7, 9)]:
			ci.draw_rect(r, Pix.P["stone"])
			ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), Pix.P["stoneL"])
			ci.draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), Pix.P["stoneDD"])
		Pix.sprite(ci, Pix.ICON[WORDS[i]], Pix.ICON_PAL, Vector2(gx, 110))
		# the "without" door: the same mark, faded and struck through
		var ax := _alcove_x(i)
		var at := Vector2(ax + 13, 101)
		Pix.sprite(ci, Pix.ICON[WORDS[i]], Pix.ICON_PAL, at, 1, false, 0.4)
		for k in 7:
			ci.draw_rect(Rect2(at.x - 3 + k, at.y - 1 - k, 1, 1), Pix.P["bars"])


func _draw_pedestal(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Pix.P["stoneL"])
	ci.draw_rect(Rect2(r.position.x, r.position.y + 3, r.size.x, r.size.y - 3), Pix.P["stone"])
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Pix.P["stoneDD"])


func _draw_statue(ci: CanvasItem) -> void:
	var on := logic.marks_on()
	if logic.statue_kind() == "human":
		Pix.sprite(ci, Pix.MAN, Pix.MAN_PAL, STATUE_FEET, 2)
		for mark in ["cloak", "wreath", "mask"]:
			if on.has(mark):
				Pix.sprite(ci, {"cloak": Pix.MAN_CLOAK, "wreath": Pix.MAN_WREATH, "mask": Pix.MAN_MASK}[mark],
					Pix.MAN_PAL, STATUE_FEET, 2)
	for mark in MARK_SPOT:
		if not on.has(mark) and mark != "flame":
			continue
		var at: Vector2 = MARK_SPOT[mark]
		if mark == "laugh" and laugh_away > 0.0:
			at += Vector2(sin((2.0 - laugh_away) / 2.0 * PI) * 22.0, 6.0)
		var a := 1.0 if on.has(mark) else 0.55 + 0.35 * sin(t * 5.0)
		Pix.sprite(ci, Pix.ICON[mark], Pix.ICON_PAL, at + Vector2(0, sin(t * 1.6 + at.x) * 1.0), 1, false, a)
	var col: Color = Pix.P["ghostD"]
	Pix.text(ci, Vector2(160, 118), "genus: animal", 6, col)
	Pix.text(ci, Vector2(160, 126), "species: " + logic.statue_kind(), 6, col)
	for w in words_hall:
		var c: Color = Pix.P["ghost"]
		c.a = clampf(1.0 - (w["t"] - 2.0) / 1.5, 0.0, 1.0)
		Pix.text(ci, w["at"] + Vector2(0, -w["t"] * 3.0), w["text"], 6, c)
	if phase == "done":
		var glow: Color = Pix.P["gold"]
		glow.a = 0.25 + 0.1 * sin(t * 2.0)
		ci.draw_circle(STATUE_FEET + Vector2(0, -18), 26.0, glow)


# ---------- backgrounds ----------

func _build_tree_bg() -> ImageTexture:
	var img := Image.create(Pix.W, Pix.H, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y in Pix.H:
		for x in Pix.W:
			var p := Vector2(x + 0.5, y + 0.5)
			var c: Color = Pix.P["void"]
			if _floor_shape(p):
				c = _slab(x, y, rng)
			elif _wall_face(x, y):
				c = _blocks(x, y, rng)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _floor_shape(p: Vector2) -> bool:
	if TRUNK.has_point(p):
		return true
	for i in 4:
		var ax := _alcove_x(i)
		if Rect2(ax - 20, 30, 40, 58).has_point(p) or Rect2(ax - 6, 86, 12, 20).has_point(p):
			return true
	return false


func _wall_face(x: int, y: int) -> bool:
	if y >= 92 and y < 104 and x >= 8 and x < 312:
		return true
	for i in 4:
		var ax := _alcove_x(i)
		if y >= 18 and y < 30 and x >= ax - 20 and x < ax + 20:
			return true
	return false


func _slab(x: int, y: int, rng: RandomNumberGenerator) -> Color:
	var bx := x % 10
	var by := y % 8
	if bx == 0 or by == 0:
		return Pix.P["stoneDD"]
	var tone := ((x / 10) * 7 + (y / 8) * 13) % 5
	var c: Color = Pix.P["stoneD"] if tone < 3 else Pix.P["stone"]
	if rng.randf() < 0.06:
		c = Pix.P["stoneDD"]
	return c


func _blocks(x: int, y: int, rng: RandomNumberGenerator) -> Color:
	var row := y / 6
	var off := 6 if row % 2 else 0
	if (y % 6) == 5 or ((x + off) % 12) == 11:
		return Pix.P["stoneDD"]
	if rng.randf() < 0.04:
		return Pix.P["void"]  # broken
	return Pix.P["stoneL"] if (y % 6) == 0 else Pix.P["stone"]


func _build_hall_bg() -> ImageTexture:
	var img := Image.create(Pix.W, Pix.H, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in Pix.H:
		for x in Pix.W:
			var c: Color = Pix.P["void"]
			if HALL_FLOOR.has_point(Vector2(x, y)):
				var ring := Vector2((x - 160) / 1.6, y - 96).length()
				c = _slab(x, y, rng)
				if absf(ring - 34.0) < 1.5:
					c = Pix.P["stoneL"]
			elif y >= 32 and y < 46 and x >= 40 and x < 280:
				c = _blocks(x, y, rng)
				if (x - 40) % 40 < 6:
					c = Pix.P["stoneL"] if (x - 40) % 40 < 2 else Pix.P["stone"]  # broken columns
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
