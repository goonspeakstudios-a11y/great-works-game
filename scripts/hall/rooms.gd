extends RefCounted
## Which rooms the Hall has and what is inside them. Doors come from the reading list
## (works.json, in order); what a room holds comes from content/greece/rooms.json.

const ROOMS_FILE := "res://content/greece/rooms.json"
const WORKS_FILE := "res://content/greece/works.json"

static var _rooms: Dictionary = {}


static func all_rooms() -> Dictionary:
	if _rooms.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOMS_FILE))
		if data is Dictionary:
			_rooms = data
		else:
			push_error("Bad or missing %s" % ROOMS_FILE)
	return _rooms


static func room(work_id: String) -> Dictionary:
	return all_rooms().get(work_id, {})


## One door per work, in reading-list order (straight from works.json). A door is open
## once its room is written.
static func doors() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORKS_FILE))
	if not data is Dictionary:
		push_error("Bad or missing %s" % WORKS_FILE)
		return []
	var out: Array = []
	for w in data["works"]:
		var name: String = w["title"] if w["author"] == "" else "%s, %s" % [w["author"], w["title"]]
		out.append({"work": w["id"], "number": out.size() + 1, "name": name, "open": room(w["id"]).get("open", false)})
	return out
