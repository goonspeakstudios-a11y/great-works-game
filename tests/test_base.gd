extends RefCounted
## Minimal test base: each test_ method calls check(); failures are collected.

var failures: Array[String] = []
var allowed_errors := 0  # set by tests that expect push_error on purpose


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func check_eq(got: Variant, want: Variant, msg: String) -> void:
	if got != want:
		failures.append("%s: got %s, want %s" % [msg, str(got), str(want)])


func seeded(seed_value: int = 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
