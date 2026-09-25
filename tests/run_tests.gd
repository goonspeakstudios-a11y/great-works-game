extends SceneTree
## Runs every test_ method in SUITES and exits non-zero on any failure.
## godot --headless --path . --script res://tests/run_tests.gd

const SUITES := [
	"res://tests/test_memory.gd",
	"res://tests/test_recall.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_run.gd",
	"res://tests/test_save.gd",
	"res://tests/test_content.gd",
	"res://tests/test_flow.gd",
]


func _initialize() -> void:
	var errors := preload("res://tests/error_counter.gd").new()
	OS.add_logger(errors)
	var passed := 0
	var failed := 0
	for path in SUITES:
		var script: GDScript = load(path)
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
