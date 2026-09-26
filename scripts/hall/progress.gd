extends RefCounted
## What the player has learned, kept between visits in user://progress.json:
## for each work, which lesson points they have shown they understand, how many times
## they have visited, and whether the work is mastered (every point understood).

const PATH := "user://progress.json"
const FRESH := {"understood": [], "visits": 0, "mastered": false}

var data := {"works": {}}
var path := PATH  # "" keeps progress in memory only (tests)


## Opens the saved progress; a file from an older build (or a damaged entry) is filled in
## with defaults rather than trusted blindly.
static func open(at: String = PATH) -> RefCounted:
	var p: RefCounted = load("res://scripts/hall/progress.gd").new()
	p.path = at
	if at != "" and FileAccess.file_exists(at):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(at))
		if d is Dictionary and d.get("works") is Dictionary:
			p.data = {"works": {}}
			for work in d["works"]:
				var entry: Variant = d["works"][work]
				var fixed: Dictionary = FRESH.duplicate(true)
				if entry is Dictionary:
					if entry.get("understood") is Array:
						fixed["understood"] = entry["understood"]
					if entry.get("visits") is float or entry.get("visits") is int:  # JSON numbers load as floats
						fixed["visits"] = int(entry["visits"])
					if entry.get("mastered") is bool:
						fixed["mastered"] = entry["mastered"]
				p.data["works"][work] = fixed
		else:
			push_warning("Progress file %s is damaged; starting fresh" % at)
	return p


## Writes to a scratch file first and swaps it in, so a crash mid-write cannot lose
## everything learned so far.
func save() -> void:
	if path == "":
		return
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save progress to %s" % tmp)
		return
	f.store_string(JSON.stringify(data, " "))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_warning("Could not move %s into place (%s)" % [tmp, error_string(err)])


func _work(work: String) -> Dictionary:
	if not data["works"].has(work):
		data["works"][work] = FRESH.duplicate(true)
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
