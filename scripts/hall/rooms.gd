extends RefCounted
## Which rooms the Hall has and what is inside them. Doors come from the reading list
## (works.json, in order); what a room holds comes from content/greece/rooms.json.

const ROOMS_FILE := "res://content/greece/rooms.json"

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


## One door per work, in reading-list order. A door is open once its room is written.
static func doors(content: RefCounted) -> Array:
	var out: Array = []
	for i in content.work_order.size():
		var id: String = content.work_order[i]
		var w: Dictionary = content.works[id]
		var name: String = w["title"] if w["author"] == "" else "%s, %s" % [w["author"], w["title"]]
		out.append({"work": id, "number": i + 1, "name": name, "open": room(id).get("open", false)})
	return out
