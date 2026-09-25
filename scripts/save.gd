extends RefCounted
## Reads and writes the save file (memory strength per idea, plus stats).
## Writes go to a temp file first so a crash cannot leave a half-written save.

const DEFAULT_PATH := "user://save.json"
const VERSION := 1


static func blank() -> Dictionary:
	return {"version": VERSION, "memory": {}, "stats": {"runs": 0, "wins": 0}}


static func load_save(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return blank()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot read save %s (error %d)" % [path, FileAccess.get_open_error()])
		return blank()
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("memory"):
		push_error("Save file %s is damaged; starting fresh" % path)
		return blank()
	var out := blank()
	out.merge(data, true)
	return out


static func write_save(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write save %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Cannot replace save %s (error %d)" % [path, err])
		return false
	return true
