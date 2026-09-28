extends RefCounted
## A beat: one moment of a book played in the first person, as the scene's hero (Achilles with his
## hand on his sword, Priam kneeling), or as yourself in a hands-on activity (walking the memory
## house, pegging out Euclid's circles). A beat is a list of steps from content/greece/beats.json:
##   {"line": text}                      one short line on screen; F goes on
##   {"act": text, "hold": secs}         the one thing you do: press F, or hold it for `hold` seconds
##   {"go": mark, "text": text}          walk to a mark (or through a list of marks, in order)
##   {"look": name}                      the view turns to someone or a mark
##   {"swap": "left"|"right", "what": w} what a hand holds changes (People._held: sword, spear, ...)
##   {"move": name, "by": [x,y,z], "turn": deg, "tilt": deg, "secs": s}   someone or something moves
##   {"show": name} / {"hide": name}     someone or something appears or goes
##   {"eye": metres}                     your eyes drop (kneeling) or rise
##   {"wait": secs}
## There is no failing a beat: you can only go on, or leave it with Esc and come back. Everything a
## beat moved is put back when it ends, so it can be played again.

const People := preload("res://scripts/hall/kit_greek_people.gd")
const FILE := "res://content/greece/beats.json"
const KINDS := ["line", "act", "go", "look", "swap", "move", "show", "hide", "eye", "wait"]
const REACH := 1.6  # how near a mark you must come
const TURN_SECS := 0.6

var work := ""
var id := ""  # the lesson point it plays (empty: a moment that is not a point, like the Sirens)
var hero := ""  # whose eyes (People.HEROES), or "" for yourself
var title := ""
var steps: Array = []
var cast := {}  # name -> Node3D, given by the place
var marks := {}  # name -> Vector3 or an Array of them, in the world's space
var step := -1
var done := false
var arms := {}  # People.hero_arms, while the beat plays
var _t := 0.0
var _held := 0.0
var _waypoint := 0
var _saved := {}  # Node3D -> Transform3D, to put back
var _shown := {}  # Node3D -> whether it was visible, to put back
var _move := {}  # {node, from, to, secs}
var _turn := {}  # {from, to}
var _eye := 0.0


## Every beat of every book, as written in beats.json: {work: {beat: {hero, title, steps}}}.
static func all() -> Dictionary:
	if not FileAccess.file_exists(FILE):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if not data is Dictionary:
		push_error("beats.json does not parse")
		return {}
	return data


static func find(for_work: String, name: String) -> Dictionary:
	return all().get(for_work, {}).get(name, {})


## What is wrong with a beat as written (nothing, if it is sound).
static func problems(def: Dictionary) -> Array:
	var out: Array = []
	if not def.has("steps") or (def["steps"] as Array).is_empty():
		out.append("no steps")
		return out
	if def.get("hero", "") != "" and not People.HEROES.has(def["hero"]):
		out.append("no such hero: %s" % def["hero"])
	var acts := 0
	for s in def["steps"]:
		var kinds: Array = KINDS.filter(func(k): return (s as Dictionary).has(k))
		if kinds.size() != 1:
			out.append("a step must be one of %s: %s" % [KINDS, s])
		elif kinds[0] == "act" or kinds[0] == "go":
			acts += 1
		if s.has("line") and str(s["line"]).length() > 140:
			out.append("a line is too long to read at once: %s" % str(s["line"]).left(40))
	if acts == 0:
		out.append("nothing to do: a beat needs at least one act or go")
	return out


func _init(def: Dictionary, for_work: String, point: String, cast_nodes: Dictionary = {}, mark_spots: Dictionary = {}) -> void:
	work = for_work
	id = point
	hero = def.get("hero", "")
	title = def.get("title", "")
	steps = def.get("steps", [])
	cast = cast_nodes
	marks = mark_spots


## Begin: the hero's arms come up in front of your eyes, and the first step starts.
func start(player: Node3D) -> void:
	if hero != "":
		arms = People.hero_arms(player.camera, hero)
	step = -1
	done = false
	_next(player)


## Put everything back: the arms go, your eyes return, whatever moved is where it was.
func finish(player: Node3D) -> void:
	if not arms.is_empty() and is_instance_valid(arms["root"]):
		arms["root"].get_parent().remove_child(arms["root"])
		arms["root"].free()
	arms = {}
	player.camera.position.y -= _eye
	_eye = 0.0
	for node in _saved:
		if is_instance_valid(node):
			(node as Node3D).transform = _saved[node]
	_saved = {}
	for node in _shown:
		if is_instance_valid(node):
			(node as Node3D).visible = _shown[node]
	_shown = {}


func current() -> Dictionary:
	return steps[step] if step >= 0 and step < steps.size() else {}


func kind() -> String:
	var s := current()
	for k in KINDS:
		if s.has(k):
			return k
	return ""


## Only while you have somewhere to walk may you walk.
func free_to_walk() -> bool:
	return kind() == "go"


func prompt() -> String:
	var s := current()
	match kind():
		"line":
			return "%s\n(F)" % s["line"]
		"act":
			if float(s.get("hold", 0.0)) > 0.0:
				var bar := int(clampf(_held / float(s["hold"]), 0.0, 1.0) * 10.0)
				return "Hold F: %s  %s" % [s["act"], "|".repeat(bar)]
			return "F: %s" % s["act"]
		"go":
			return str(s.get("text", "Walk on"))
	return ""


## F pressed: a line goes on, a quick act is done.
func press(player: Node3D) -> void:
	var s := current()
	if kind() == "line" or (kind() == "act" and float(s.get("hold", 0.0)) <= 0.0):
		_next(player)


## Moment to moment: holding F, walking to marks, things moving and the view turning.
func update(delta: float, player: Node3D, holding: bool) -> void:
	if done:
		return
	_t += delta
	var s := current()
	match kind():
		"act":
			var need := float(s.get("hold", 0.0))
			if need > 0.0:
				_held = _held + delta if holding else maxf(0.0, _held - delta * 2.0)
				if _held >= need:
					_next(player)
		"go":
			var route := _route(s["go"])
			if route.is_empty():
				_next(player)
				return
			var p: Vector3 = route[mini(_waypoint, route.size() - 1)]
			if Vector2(player.global_position.x - p.x, player.global_position.z - p.z).length() < REACH:
				_waypoint += 1
				if _waypoint >= route.size():
					_next(player)
		"look":
			var k := minf(1.0, _t / TURN_SECS)
			player.rotation.y = lerp_angle(_turn["from"], _turn["to"], k)
			if k >= 1.0:
				_next(player)
		"move":
			var k := minf(1.0, _t / maxf(0.01, float(_move["secs"])))
			var node: Node3D = _move["node"]
			if is_instance_valid(node):
				node.transform = (_move["from"] as Transform3D).interpolate_with(_move["to"], smoothstep(0.0, 1.0, k))
			if k >= 1.0:
				_next(player)
		"wait":
			if _t >= float(s["wait"]):
				_next(player)


## The next mark to walk to, for a marker in the world (or none).
func next_mark() -> Variant:
	if kind() != "go":
		return null
	var route := _route(current()["go"])
	return route[mini(_waypoint, route.size() - 1)] if not route.is_empty() else null


func _route(name: Variant) -> Array:
	var names: Array = name if name is Array else [name]
	var out: Array = []
	for n in names:
		var m: Variant = marks.get(n, null)
		if m is Vector3:
			out.append(m)
		elif m is Array:
			out.append_array(m)
	return out


func _next(player: Node3D) -> void:
	step += 1
	_t = 0.0
	_held = 0.0
	_waypoint = 0
	if step >= steps.size():
		done = true
		return
	var s := current()
	match kind():
		"swap":
			_swap(str(s["swap"]), str(s.get("what", "")))
			_next(player)
		"show", "hide":
			var node: Node3D = cast.get(s.get("show", s.get("hide", "")), null)
			if node:
				if not _shown.has(node):
					_shown[node] = node.visible
				node.visible = kind() == "show"
			_next(player)
		"eye":
			_eye += float(s["eye"])
			player.camera.position.y += float(s["eye"])
			_next(player)
		"look":
			var at: Variant = _where(str(s["look"]))
			if at == null:
				_next(player)
				return
			var to: Vector3 = (at as Vector3) - player.global_position
			_turn = {"from": player.rotation.y, "to": atan2(-to.x, -to.z)}
		"move":
			var node: Node3D = cast.get(s["move"], null)
			if node == null:
				_next(player)
				return
			if not _saved.has(node):
				_saved[node] = node.transform
			var to := node.transform
			var by: Array = s.get("by", [0, 0, 0])
			to.origin += Vector3(by[0], by[1], by[2])
			to.basis = to.basis.rotated(Vector3.UP, deg_to_rad(float(s.get("turn", 0.0))))
			to.basis = to.basis * Basis(Vector3.RIGHT, deg_to_rad(float(s.get("tilt", 0.0))))
			_move = {"node": node, "from": node.transform, "to": to, "secs": float(s.get("secs", 1.0))}


func _where(name: String) -> Variant:
	var node: Node3D = cast.get(name, null)
	if node and is_instance_valid(node):
		return node.global_position
	var m: Variant = marks.get(name, null)
	if m is Array and not (m as Array).is_empty():
		return m[0]
	return m


func _swap(side: String, what: String) -> void:
	if arms.is_empty():
		return
	var i := 0 if side == "left" else 1
	var hand: Node3D = arms["hands"][i]
	var old: Node3D = arms["held"][i]
	if is_instance_valid(old):
		hand.remove_child(old)
		old.free()
	arms["held"][i] = People._held(hand, what, -1.0 if i == 0 else 1.0)
