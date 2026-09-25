extends SceneTree
## Runs every test_ method in SUITES and exits non-zero on any failure.
## godot --headless --path . --script res://tests/run_tests.gd

const SUITES := [
	"res://tests/test_memory.gd",
	"res://tests/test_recall.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_story.gd",
	"res://tests/test_save.gd",
	"res://tests/test_content.gd",
	"res://tests/test_characters.gd",
	"res://tests/test_flow.gd",
	"res://tests/test_hall.gd",
]


var _started := false


## Tests run on the first frame so nodes added to the tree get a real _ready.
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_run_all()
	return false


func _run_all() -> void:
	var errors := preload("res://tests/error_counter.gd").new()
	OS.add_logger(errors)
	var passed := 0
	var failed := 0
	for path in SUITES:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAIL ", path.get_file(), " - the test file does not load (see the parse error above)")
			continue
		for m in script.get_script_method_list():
			if not m["name"].begins_with("test_"):
				continue
			var suite = script.new()
			errors.take()
			suite.call(m["name"])
			var logged := errors.take()
			if logged.size() > suite.allowed_errors:
				for e in logged:
					suite.failures.append("engine error: " + e)
			var label := "%s::%s" % [path.get_file().get_basename(), m["name"]]
			if suite.failures.is_empty():
				passed += 1
				print("PASS ", label)
			else:
				failed += 1
				for f in suite.failures:
					print("FAIL ", label, " - ", f)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
