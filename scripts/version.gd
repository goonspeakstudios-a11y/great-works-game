extends RefCounted
## The game's version, and the build number GitHub Actions stamps into res://build.txt
## (0 when run from the editor or the project folder).

const VERSION := "0.4.0"


static func build() -> int:
	var f := FileAccess.open("res://build.txt", FileAccess.READ)
	return int(f.get_as_text().strip_edges()) if f else 0


static func label() -> String:
	var b := build()
	return "Great Works v%s" % VERSION + (" (build %d)" % b if b > 0 else " (dev)")
