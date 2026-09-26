extends Node
## Live mode (--live): the game watches its own scripts and content while you play. When a file
## changes, the changed scripts are reloaded in place, the cached content is dropped, and the
## place you are standing in is rebuilt round you, so a change shows up without restarting.
## F5 rebuilds the place by hand.

const Rooms := preload("res://scripts/hall/rooms.gd")
const Worlds := preload("res://scripts/hall/worlds.gd")
const Nexus := preload("res://scripts/hall/nexus.gd")
const Tex := preload("res://scripts/hall/textures.gd")

const DIRS := ["res://scripts/hall", "res://scripts/pixel", "res://content", "res://content/greece"]
const EVERY := 0.5  # seconds between looks

var hall: Node
var _seen := {}  # path -> modified time
var _wait := 0.0


func _ready() -> void:
	_changed()  # note how everything is now


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = EVERY
	var changed := _changed()
	if not changed.is_empty():
		apply(changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		apply([])


## The files that changed since the last look.
func _changed() -> Array:
	var out: Array = []
	for dir in DIRS:
		for f in DirAccess.get_files_at(dir):
			if not (f.ends_with(".gd") or f.ends_with(".json")):
				continue
			var path: String = dir.path_join(f)
			var t := FileAccess.get_modified_time(ProjectSettings.globalize_path(path))
			if _seen.has(path) and _seen[path] != t:
				out.append(path)
			_seen[path] = t
	return out


func apply(changed: Array) -> void:
	for path in changed:
		if path.ends_with(".gd"):
			var sc := load(path) as GDScript
			if sc:
				sc.source_code = FileAccess.get_file_as_string(path)
				var err := sc.reload(true)
				if err != OK:
					push_warning("Live: could not reload %s (%s)" % [path, error_string(err)])
	Rooms._rooms = {}
	Worlds._worlds = {}
	Nexus._content = {}
	Tex._cache = {}
	if hall and not hall.travelling:
		hall.doors = Rooms.doors()
		hall._load_place(hall.here, true)
		hall._quip = "Live: rebuilt (%s)" % (", ".join(changed.map(func(p: String) -> String: return p.get_file())) if not changed.is_empty() else "F5")
		hall._quip_until = hall._t + 3.0
