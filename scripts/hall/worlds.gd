extends RefCounted
## How sharp each world is. History moves forward and the picture sharpens with it:
## Greece renders at 320x180 with chunky shapes (PS1-like), Rome at 640x360 (PS2-like),
## and so on (content/worlds.json). A render size of 0 means the window's own size.

const FILE := "res://content/worlds.json"
const DEFAULT := {"name": "Greece", "render": [320, 180], "detail": 1}

static var _worlds: Dictionary = {}


static func settings(world: String) -> Dictionary:
	if _worlds.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_worlds = data if data is Dictionary else {}
	return _worlds.get(world, DEFAULT)


static func render_size(world: String, window: Vector2i) -> Vector2i:
	var r: Array = settings(world).get("render", DEFAULT["render"])
	return window if r[0] <= 0 else Vector2i(r[0], r[1])


static func detail(world: String) -> int:
	return int(settings(world).get("detail", 1))


## Every world, in ring order: name, sharpness, door style and (Greece only, so far) its hub.
static func all() -> Dictionary:
	settings("greece")
	return _worlds
