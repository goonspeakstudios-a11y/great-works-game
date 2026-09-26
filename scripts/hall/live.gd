extends Node
## Live mode (--live): the game watches its own scripts and content while you play. When a file
## changes, the changed scripts are reloaded in place, the cached content is dropped, and the
## place you are standing in is rebuilt round you, so a change shows up without restarting.
## F5 reloads everything: every script afresh and the whole scene, back in the place you were in.
## F6 restarts the whole program by itself (taking in any new sounds first), back in the same place.

const Rooms := preload("res://scripts/hall/rooms.gd")
const Worlds := preload("res://scripts/hall/worlds.gd")
const Nexus := preload("res://scripts/hall/nexus.gd")
const Tex := preload("res://scripts/hall/textures.gd")

const DIRS := ["res://scripts/hall", "res://scripts/pixel", "res://content", "res://content/greece"]
const EVERY := 0.5  # seconds between looks
## Never swapped while running: this file, and the Hall that is running it. Swapping a script in
## the middle of one of its own calls crashes the game; a change to either asks for F6 instead.
const RUNNING := ["res://scripts/hall/live.gd", "res://scripts/hall/hall.gd"]

static var resume := ""  # the place to come back to after F5

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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F5:
			refresh()
		elif event.physical_keycode == KEY_F6:
			restart()


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


## The whole world afresh, without closing the window: every script reloaded from disk, then the
## scene built again from the start, back in the place you were in.
func refresh() -> void:
	for dir in DIRS:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and not RUNNING.has(dir.path_join(f)):
				_reload(dir.path_join(f))
	resume = hall.here if hall else ""
	get_tree().reload_current_scene()


## A full restart without touching anything: new sound and picture files are taken in, a fresh
## copy of the game is started (in the same place) and this one closes.
func restart() -> void:
	var exe := OS.get_executable_path()
	var engine_args := Array(OS.get_cmdline_args())
	var project := ProjectSettings.globalize_path("res://")
	OS.execute(exe, ["--headless", "--path", project, "--import"])
	var user_args := Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with("--resume="))
	if hall:
		user_args.append("--resume=" + hall.here)
	OS.create_process(exe, engine_args + ["--"] + user_args)
	get_tree().quit()


func _reload(path: String) -> void:
	var sc := load(path) as GDScript
	if sc:
		sc.source_code = FileAccess.get_file_as_string(path)
		var err := sc.reload(true)
		if err != OK:
			push_warning("Live: could not reload %s (%s)" % [path, error_string(err)])


func apply(changed: Array) -> void:
	for path in changed:
		if RUNNING.has(path):
			if hall:
				hall._quip = "Live: %s changed. Press F6." % path.get_file()
				hall._quip_until = hall._t + 6.0
			return
		if path.ends_with(".gd"):
			_reload(path)
	Rooms._rooms = {}
	Worlds._worlds = {}
	Nexus._content = {}
	Tex._cache = {}
	if hall and not hall.travelling:
		hall.doors = Rooms.doors()
		hall._load_place(hall.here, true)
		hall._quip = "Live: rebuilt (%s)" % (", ".join(changed.map(func(p: String) -> String: return p.get_file())) if not changed.is_empty() else "by hand")
		hall._quip_until = hall._t + 3.0
