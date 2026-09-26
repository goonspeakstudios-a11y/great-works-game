extends RefCounted
## What the player has learned, kept between visits in user://progress.json:
## for each work, which lesson points they have shown they understand, how many times
## they have visited, and whether the work is mastered (every point understood).

const PATH := "user://progress.json"

var data := {"works": {}}
var path := PATH  # "" keeps progress in memory only (tests)


static func open(at: String = PATH) -> RefCounted:
	var p: RefCounted = load("res://scripts/hall/progress.gd").new()
	p.path = at
	if at != "" and FileAccess.file_exists(at):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(at))
		if d is Dictionary and d.get("works") is Dictionary:
			p.data = d
		else:
			push_warning("Progress file %s is damaged; starting fresh" % at)
	return p


func save() -> void:
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save progress to %s" % path)
		return
	f.store_string(JSON.stringify(data, " "))


func _work(work: String) -> Dictionary:
	if not data["works"].has(work):
		data["works"][work] = {"understood": [], "visits": 0, "mastered": false}
	return data["works"][work]


func understood(work: String) -> Array:
	return _work(work)["understood"]


## Adds points the player has shown they understand; returns the ones that are new.
func learn(work: String, ids: Array) -> Array:
	var have: Array = _work(work)["understood"]
	var fresh: Array = []
	for id in ids:
		if not have.has(id) and not fresh.has(id):
			fresh.append(id)
	have.append_array(fresh)
	return fresh


func visits(work: String) -> int:
	return _work(work)["visits"]


func visit(work: String) -> void:
	_work(work)["visits"] += 1


func is_mastered(work: String) -> bool:
	return data["works"].has(work) and data["works"][work].get("mastered", false)


## Marks the work mastered once every lesson point is understood; true the first time.
func check_mastery(work: String, lesson: Array) -> bool:
	if is_mastered(work) or lesson.is_empty():
		return false
	var have := understood(work)
	if lesson.all(func(p): return have.has(p["id"])):
		_work(work)["mastered"] = true
		return true
	return false


func mastered_count() -> int:
	return data["works"].values().filter(func(w): return w.get("mastered", false)).size()
