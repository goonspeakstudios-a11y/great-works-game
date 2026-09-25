extends "res://tests/test_base.gd"

const Save := preload("res://scripts/save.gd")
const PATH := "user://test_save.json"


func _cleanup() -> void:
	for p in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func test_missing_file_gives_blank() -> void:
	_cleanup()
	check_eq(Save.load_save(PATH), Save.blank(), "blank save")


func test_write_twice_and_read_back() -> void:
	_cleanup()
	var d := Save.blank()
	d["stats"]["runs"] = 1
	check(Save.write_save(d, PATH), "first write")
	d["stats"]["runs"] = 2
	check(Save.write_save(d, PATH), "second write replaces the first")
	check_eq(int(Save.load_save(PATH)["stats"]["runs"]), 2, "read back")
	check(not FileAccess.file_exists(PATH + ".tmp"), "temp file cleaned up")
	_cleanup()


func test_damaged_file_gives_blank() -> void:
	allowed_errors = 2  # JSON parser error + our "damaged" message
	_cleanup()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	check_eq(Save.load_save(PATH), Save.blank(), "damaged save falls back")
	_cleanup()
