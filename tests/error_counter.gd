extends Logger
## Counts engine and script errors so the test runner can fail a test that
## hit one, even if the test's own checks never ran.

var _lock := Mutex.new()
var messages: Array[String] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	_lock.lock()
	messages.append("%s (%s:%d %s)" % [rationale if rationale else code, file.get_file(), line, function])
	_lock.unlock()


func take() -> Array[String]:
	_lock.lock()
	var out := messages.duplicate()
	messages.clear()
	_lock.unlock()
	return out
