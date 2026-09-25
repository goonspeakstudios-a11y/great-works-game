extends "res://tests/test_base.gd"

const Memory := preload("res://scripts/memory.gd")


func test_new_idea_is_due_and_box_zero() -> void:
	var m := Memory.new()
	check(m.is_new("a"), "unseen idea is new")
	check(m.is_due("a", 1000), "unseen idea is due")
	check_eq(m.box("a"), 0, "unseen box")


func test_right_answer_moves_up_and_pushes_review_out() -> void:
	var m := Memory.new()
	m.record("a", true, 1000)
	check_eq(m.box("a"), 1, "box after one right")
	check(not m.is_due("a", 1000), "not due right after a right answer")
	check(m.is_due("a", 1000 + Memory.INTERVALS[1]), "due once the interval passes")
	m.record("a", true, 5000)
	check_eq(m.box("a"), 2, "box after two right")
	check(not m.is_due("a", 5000 + Memory.INTERVALS[1]), "box 2 waits longer than box 1")


func test_wrong_answer_drops_to_box_one_and_is_due_now() -> void:
	var m := Memory.new()
	for i in 4:
		m.record("a", true, 1000)
	check(m.is_gold("a"), "four right answers make it gold")
	m.record("a", false, 2000)
	check_eq(m.box("a"), 1, "box after wrong")
	check(m.is_due("a", 2000), "due immediately after wrong")
	check(not m.is_gold("a"), "wrong answer loses gold")


func test_box_caps_at_max() -> void:
	var m := Memory.new()
	for i in 10:
		m.record("a", true, 0)
	check_eq(m.box("a"), Memory.MAX_BOX, "box cap")


func test_pick_puts_due_and_weak_first() -> void:
	var m := Memory.new()
	m.record("strong", true, 0)
	m.record("strong", true, 0)   # box 2, not due at t=100
	m.record("weak", false, 0)    # box 1, due
	var got := m.pick(["strong", "weak", "new"], 2, 100, seeded())
	check_eq(got, ["new", "weak"], "due ideas first, lowest box first")


func test_round_trip() -> void:
	var m := Memory.new()
	m.record("a", true, 10)
	var m2 := Memory.new()
	m2.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	check_eq(m2.box("a"), 1, "box survives JSON")
	check(not m2.is_due("a", 10), "due time survives JSON")
