extends RefCounted
## What there is to do in the city of Rome, and where (content/rome/activities.json and the scene
## files, written by tools/make_rome_activities.py; docs/rome-activities-plan.md):
##   your house on the Argiletum, and your family in it (urbs_house.gd)
##   the recurring rites (rites.json): the vote, the games, the funeral, the levy, the court, the
##     bread, the sacrifice, the triumph, the Saturnalia, the morning call, each at its place and
##     hour in each age, the same rite decaying from age to age
##   the spots: the augurs on the Arx, the boards on the Basilica steps, the baths, the fire, the
##     night streets, the races, the census, the heroes' stories where they happened
##   an offering at any temple still standing
##   and what to ask the people of each trade (trades.json "jobs"): a day's work, a purchase, a game
## Every one of them is a scene (urbs_scene.gd) played in the activity panel (urbs_panel.gd).

const Kit := preload("res://scripts/hall/kit.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const RomeMap := preload("res://scripts/hall/rome_map.gd")
const Scene := preload("res://scripts/hall/urbs_scene.gd")
const House := preload("res://scripts/hall/urbs_house.gd")
const FILE := "res://content/rome/activities.json"
const MONUMENT_CLEAR := 4.0  # a spot inside a monument's footprint is moved out to this far past its edge

static var _data := {}
static var _scenes := {}
static var _files := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = parsed if parsed is Dictionary else {}
		if _data.is_empty():
			push_error("activities.json does not parse")
	return _data


static func _file(name: String) -> Dictionary:
	if not _files.has(name):
		var path := "res://content/rome/%s.json" % name
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_files[name] = parsed if parsed is Dictionary else {}
	return _files[name]


static func scenes() -> Dictionary:
	if _scenes.is_empty():
		_scenes = Scene.all()
	return _scenes


## A scene as it is in an age: "<id>_<age>" if there is one, else "<id>" ({} if neither).
static func scene_def(id: String, age: String) -> Dictionary:
	var all := scenes()
	if all.has(id + "_" + age):
		return all[id + "_" + age]
	return all.get(id, {})


static func scene_id(id: String, age: String) -> String:
	return id + "_" + age if scenes().has(id + "_" + age) else id


## A scene with {name} words filled in (an offering's god and temple).
static func filled(def: Dictionary, subs: Dictionary) -> Dictionary:
	if subs.is_empty():
		return def
	var text := JSON.stringify(def)
	for k: String in subs:
		text = text.replace("{%s}" % k, str(subs[k]).replace("\"", "\\\""))
	var out: Variant = JSON.parse_string(text)
	return out if out is Dictionary else def


static func rites() -> Dictionary:
	return _file("rites").get("rites", {})


static func jobs() -> Dictionary:
	return _file("trades").get("jobs", {})


## What to ask someone of this trade in this age: {label, scene} ({} if nothing).
static func job_action(job: String, age: String) -> Dictionary:
	var j: Variant = jobs().get(job)
	if not j is Array:
		return {}
	var a: Array = j
	if a.size() > 2 and not (a[2] as Array).has(age):
		return {}
	if scene_def(str(a[1]), age).is_empty():
		return {}
	return {"label": str(a[0]), "scene": str(a[1])}


# ---------- the calendar ----------

## Whether `h` is within [from, to), which may wrap past midnight.
static func in_hours(h: float, from: float, to: float) -> bool:
	return h >= from and h < to if from <= to else h >= from or h < to


## Whether something with a time ({every, offset, from, to, festival}) is on now.
static func on_now(when: Dictionary, day: int, h: float, festival: String = "") -> bool:
	if when.has("festival"):
		if festival != str(when["festival"]):
			return false
	elif when.has("every") and posmod(day - int(when.get("offset", 0)), maxi(1, int(when["every"]))) != 0:
		return false
	return in_hours(h, float(when.get("from", 0.0)), float(when.get("to", 24.0)))


## The next time it is on, from `day` at hour `h`: [days from now, hour] (festivals by the town's year).
static func next_on(when: Dictionary, day: int, h: float, year_days: int = 24, festival_day: int = -1) -> Array:
	var from := float(when.get("from", 0.0))
	for ahead in range(0, 60):
		var d := day + ahead
		var ok := true
		if when.has("festival"):
			ok = festival_day >= 0 and posmod(d, year_days) == festival_day
		elif when.has("every"):
			ok = posmod(d - int(when.get("offset", 0)), maxi(1, int(when["every"]))) == 0
		if not ok:
			continue
		if ahead == 0 and on_now(when, d, h, "" if not when.has("festival") else str(when["festival"])):
			return [0, h]
		if ahead == 0 and h >= from:
			continue
		return [ahead, from]
	return [0, h]


## The festival's day in the town's year (town.json), or -1.
static func festival_day(name: String) -> int:
	var town: Dictionary = load("res://scripts/hall/urbs_town.gd").data()
	for f: Dictionary in town.get("festivals", []):
		if str(f["name"]) == name:
			return int(f["day"])
	return -1


## What is on today and tomorrow, for the tablet.
static func today(age: String, day: int, h: float) -> Array:
	var out: Array = []
	var year := int(load("res://scripts/hall/urbs_town.gd").data().get("year_days", 24))
	for id: String in rites():
		var r: Dictionary = rites()[id]
		var a: Dictionary = r["ages"].get(age, {})
		if a.is_empty():
			continue
		var when := _when(r)
		var fday := festival_day(str(r.get("festival", ""))) if r.has("festival") else -1
		var next: Array = next_on(when, day, h, year, fday)
		var hh := int(next[1])
		var at := "%d:%02d" % [hh, int((float(next[1]) - hh) * 60.0)]
		if int(next[0]) == 0:
			out.append("%s: today, %s. %s." % [r["name"], "now" if on_now(when, day, h, str(r.get("festival", ""))) else "from " + at, a["text"]])
		elif int(next[0]) == 1:
			out.append("%s: tomorrow from %s." % [r["name"], at])
	return out


static func _when(r: Dictionary) -> Dictionary:
	var w := {}
	for k: String in ["every", "offset", "from", "to", "festival"]:
		if r.has(k):
			w[k] = r[k]
	return w


# ---------- placing it in the city ----------

## Where your house is (its centre and corners), and the spots of this age, for the city's houses to
## keep clear of.
static func clearings(age: String) -> Array:
	var at := RomeMap.at(data()["room"]["at"])
	var yaw := Kit.face_yaw(at, RomeMap.at(data()["room"]["toward"]))
	var out: Array = [at]
	for c: Vector2 in [Vector2(-8, -12), Vector2(8, -12), Vector2(-8, 12), Vector2(8, 12), Vector2(-8, 0), Vector2(8, 0)]:
		out.append(at + Basis(Vector3.UP, yaw) * Vector3(c.x, 0, c.y))
	for id: String in rites():
		var a: Dictionary = rites()[id]["ages"].get(age, {})
		if a.has("at"):
			out.append(RomeMap.at(a["at"]))
	for sp: Dictionary in data().get("spots", []):
		if (sp.get("ages", []) as Array).has(age) and sp.has("at"):
			out.append(RomeMap.at(sp["at"]))
	return out


## Builds your house and puts every activity of the age in the city: interactables of kind
## "activity" ({scene, subs?, rite?, when?}), "chest", added to `out`. `front`: where to stand before
## a standing monument (places_rome's _front).
static func place(world: Node3D, age: String, fab: Dictionary, out: Array, spots: Dictionary, front: Callable) -> void:
	var standing := {}
	for s: Dictionary in fab.get("monuments", []):
		standing[str(s["m"]["id"])] = s
	var r: Dictionary = data()["room"]
	var room_at := RomeMap.on_ground(r["at"])
	var room_yaw := Kit.face_yaw(room_at, RomeMap.on_ground(r["toward"]))
	for it: Dictionary in House.build(world, age, room_at, room_yaw):
		if it.get("age_scene", false):
			it["scene"] = scene_id(str(it["scene"]), age)
		if it.has("rite") and rites().has(str(it["rite"])):
			it["when"] = _when(rites()[str(it["rite"])])
		out.append(it)
	spots["room"] = room_at
	for id: String in rites():
		var rite: Dictionary = rites()[id]
		var a: Dictionary = rite["ages"].get(age, {})
		if a.is_empty():
			continue
		if a.get("room", false):
			continue  # in your house (urbs_house.gd)
		var at := _spot(a, standing, front, fab)
		out.append({"kind": "activity", "pos": at, "scene": scene_id(id, age), "rite": id, "when": _when(rite),
			"text": "%s: %s" % [rite["name"], a["text"]]})
		spots["rite_" + id] = at
	for sp: Dictionary in data().get("spots", []):
		if not (sp.get("ages", []) as Array).has(age):
			continue
		var at := _spot(sp, standing, front, fab)
		var it := {"kind": "activity", "pos": at, "scene": scene_id(str(sp["scene"]), age), "text": str(sp["text"])}
		var when := _when(sp)
		if not when.is_empty():
			it["when"] = when
			it["name"] = str(sp["text"])
		out.append(it)
		spots[str(sp.get("id", sp["scene"]))] = at
	var peace: Dictionary = standing.get("peace", {})
	if age == "late" and not peace.is_empty() and peace["state"] == "whole":  # the Severan Marble Plan, on the Temple of Peace's wall
		out.append({"kind": "plan", "view": "city", "pos": front.call(peace),
			"text": "Look at the Marble Plan of Rome, cut on the wall of the Temple of Peace under Septimius Severus"})
	if age in data().get("offering_ages", []):
		var gods: Dictionary = data().get("temples", {})
		for id: String in gods:
			var s: Dictionary = standing.get(id, {})
			if s.is_empty() or s["state"] != "whole":
				continue
			var at: Vector3 = front.call(s)
			var side := Vector3(cos(float(s["yaw"])), 0, -sin(float(s["yaw"]))) * 2.2  # beside the monument's own stone
			at += side
			at.y = RomeMap.ground(at)
			out.append({"kind": "activity", "pos": at, "scene": "offering", "subs": {"god": gods[id], "temple": str(s["m"]["name"])},
				"text": "Make an offering to %s" % gods[id]})


## A spot's place: before its monument if that stands, else its map position, moved out of any
## monument it would stand inside.
static func _spot(a: Dictionary, standing: Dictionary, front: Callable, fab: Dictionary) -> Vector3:
	if a.has("monument") and standing.has(str(a["monument"])):
		var s: Dictionary = standing[str(a["monument"])]
		if s["state"] == "whole" or not a.has("at"):
			return front.call(s)
	var p := RomeMap.on_ground(a.get("at", [0, 0]))
	for s: Dictionary in fab.get("monuments", []):
		var c: Vector3 = s["at"]
		var r := RomeMap.footprint(s["m"]) * 0.6
		var d := Vector2(p.x - c.x, p.z - c.z)
		if d.length() < r:
			var away := d.normalized() if d.length() > 0.01 else Vector2(0, 1)
			var q := Vector2(c.x, c.z) + away * (r + MONUMENT_CLEAR)
			p = Vector3(q.x, 0, q.y)
			p.y = RomeMap.ground(p)
	return p
