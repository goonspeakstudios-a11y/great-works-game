extends RefCounted
## Which rooms the Hall has and what is inside them. Each world has its reading list
## (content/<world>/works.json, in order) and its rooms (content/<world>/rooms.json). Greece's list
## gives the Shore's doors and the Nexus's columns; Rome's books stand in the city's zones.

const ROOMS_FILES := ["res://content/greece/rooms.json", "res://content/rome/rooms.json"]
const WORKS_FILE := "res://content/greece/works.json"
const WORKS_FILES := {"greece": "res://content/greece/works.json", "rome": "res://content/rome/works.json"}

static var _rooms: Dictionary = {}


static func all_rooms() -> Dictionary:
	if _rooms.is_empty():
		for file: String in ROOMS_FILES:
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
			if data is Dictionary:
				_rooms.merge(data)
			else:
				push_error("Bad or missing %s" % file)
	return _rooms


static func room(work_id: String) -> Dictionary:
	return all_rooms().get(work_id, {})


## Greece's doors: one per work, in reading-list order (straight from its works.json). A door is
## open once its room is written.
static func doors() -> Array:
	return doors_of("greece")


## One door per work of a world's reading list, in order.
static func doors_of(world: String) -> Array:
	var file: String = WORKS_FILES.get(world, "")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file)) if file != "" else null
	if not data is Dictionary:
		push_error("Bad or missing works for %s" % world)
		return []
	var out: Array = []
	for w in data["works"]:
		var name: String = w["title"] if w["author"] == "" else "%s, %s" % [w["author"], w["title"]]
		out.append({"work": w["id"], "number": out.size() + 1, "name": name, "open": room(w["id"]).get("open", false),
			"age": w.get("age", ""), "zone": w.get("rome_zone", "")})
	return out
