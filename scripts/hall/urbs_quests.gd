extends RefCounted
## The regulars' stories across the ages (content/rome/quests.json, written by
## tools/make_rome_activities.py): in each age each of the city's regulars has a small task for you,
## step by step. How far you are in each is kept in your Standing, under "quests" ({id: step}).
##   {"talk": line}             talk to them; `give` hands you a thing
##   {"go": place, "name": ...} walk there: a map position, {"monument": id, "at": ...}, or "room"
##   {"scene": def}             a scene, played at once
##   {"bring": thing, "line"}   bring them a thing
## When the last step is done the quest's reward is given, and its voice joins the collection.

const RomeMap := preload("res://scripts/hall/rome_map.gd")
const Activities := preload("res://scripts/hall/urbs_activities.gd")
const REACH := 9.0  # how near a place you must come

static var _all := {}


static func all() -> Dictionary:
	if _all.is_empty():
		var path := "res://content/rome/quests.json"
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_all = (parsed as Dictionary).get("quests", {}) if parsed is Dictionary else {}
	return _all


## The quest a regular has for you in an age ("" if none).
static func for_regular(regular: String, age: String) -> String:
	var id := "%s_%s" % [regular, age]
	return id if all().has(id) else ""


static func _state(standing: RefCounted) -> Dictionary:
	var d: Dictionary = standing.data()
	if not d.get("quests") is Dictionary:
		d["quests"] = {}
	return d["quests"]


## How far you are: -1 not begun, the step you are on, or the number of steps once done.
static func at(standing: RefCounted, id: String) -> int:
	return int(_state(standing).get(id, -1))


static func steps(id: String) -> Array:
	return all().get(id, {}).get("steps", [])


static func done(standing: RefCounted, id: String) -> bool:
	return at(standing, id) >= steps(id).size() and not steps(id).is_empty()


static func current(standing: RefCounted, id: String) -> Dictionary:
	var k := at(standing, id)
	var list := steps(id)
	return list[k] if k >= 0 and k < list.size() else {}


static func kind(step: Dictionary) -> String:
	for k: String in ["talk", "go", "scene", "bring"]:
		if step.has(k):
			return k
	return ""


## Moves the quest on past its current step (or begins it). Returns what finishing it gave ("" if
## it is not finished yet).
static func advance(standing: RefCounted, id: String) -> String:
	var k := maxi(at(standing, id), 0)
	var step: Dictionary = steps(id)[k] if k < steps(id).size() else {}
	if step.has("give"):
		standing.apply({"give": step["give"]})
	if kind(step) == "bring":
		standing.apply({"take": step["bring"]})
	_state(standing)[id] = k + 1
	if k + 1 >= steps(id).size():
		var q: Dictionary = all()[id]
		var said: String = standing.apply(q.get("reward", {}))
		standing.collect("voices", "%s_%s" % [q["regular"], q["age"]])
		return said if said != "" else "done"
	return ""


## Where a "go" step leads, in the world: your room, before a monument standing in this age
## (`fronts`: id -> where to stand), or a map position.
static func target(step: Dictionary, room: Vector3, fronts: Dictionary) -> Variant:
	var to: Variant = step.get("go")
	if to is String and to == "room":
		return room
	if to is Dictionary:
		var m := str((to as Dictionary).get("monument", ""))
		if fronts.has(m):
			return fronts[m]
		return RomeMap.on_ground((to as Dictionary).get("at", [0, 0]))
	if to is Array:
		return RomeMap.on_ground(to)
	return null


## The quests begun and not finished in this age, for the tablet: "Title: hint".
static func hints(standing: RefCounted, age: String) -> Array:
	var out: Array = []
	for id: String in all():
		if str(all()[id]["age"]) != age:
			continue
		var k := at(standing, id)
		if k < 0 or k >= steps(id).size():
			continue
		out.append("%s: %s" % [all()[id]["title"], str(steps(id)[k].get("hint", ""))])
	return out
