extends "res://tests/test_base.gd"

const Logic := preload("res://scripts/pixel/isagoge_logic.gd")
const Content := preload("res://scripts/content.gd")
const Stage := preload("res://scripts/pixel/isagoge_stage.gd")


func test_every_thing_has_one_home_on_the_tree() -> void:
	var want := {"wisp": "spirit", "stone": "stone", "oak": "plant", "horse": "beast", "masked": "human"}
	for thing in want:
		check_eq(Logic.home_of(thing), want[thing], "%s's home" % thing)


func test_gates_follow_the_difference_not_the_look() -> void:
	# fork 3 splits animals by reason: the horse goes "without", the masked man "with".
	check(Logic.may_pass("horse", 3, false), "horse takes the no-reason door")
	check(not Logic.may_pass("horse", 3, true), "horse cannot take the reason gate")
	check(Logic.may_pass("masked", 3, true), "the man in the horse mask still reasons")
	check(not Logic.may_pass("masked", 3, false), "the mask does not make him a beast")
	check(not Logic.may_pass("wisp", 0, true), "a wisp has no body")
	check(Logic.may_pass("stone", 0, true), "a stone has a body")


func test_things_below_a_fork_cannot_use_it() -> void:
	# The stone left the tree at fork 1, so later forks do not apply to it.
	check(not Logic.may_pass("stone", 2, true), "stone never reaches the senses fork")
	check(not Logic.may_pass("stone", 2, false), "stone never reaches the senses fork either way")


func test_placing_fills_the_tree() -> void:
	var t := Logic.new()
	check(not t.place("horse", "human"), "wrong pedestal refuses")
	for thing in Logic.THINGS:
		check(t.place(thing, Logic.home_of(thing)), "%s placed at home" % thing)
	check(t.tree_done(), "tree complete after five")
	check(not t.place("horse", "beast"), "cannot place twice")


func test_statue_accidents_fall_property_returns_difference_changes_kind() -> void:
	var t := Logic.new()
	check_eq(t.statue_kind(), "human", "starts as a man")
	check_eq(t.pull("cloak"), "accident", "cloak is an accident")
	check(not t.marks_on().has("cloak"), "cloak stays off")
	check_eq(t.pull("laugh"), "property", "laughing is a property")
	check(t.marks_on().has("laugh"), "the property comes back")
	check_eq(t.pull("flame"), "difference", "reason is the difference")
	check_eq(t.statue_kind(), "beast", "without reason he is a beast")
	check(not t.statue_done(), "not done without reason")
	t.restore("flame")
	check_eq(t.statue_kind(), "human", "reason back, man back")
	t.pull("wreath")
	check(not t.statue_done(), "mask still on")
	t.pull("mask")
	check(t.statue_done(), "only what he is remains")


func test_first_stage_is_the_isagoge() -> void:
	var c := Content.new()
	check(c.load_all(), "content loads")
	check_eq(c.work_order[0], Stage.WORK_ID, "stage 1 plays the first work on the list")


func test_stage_can_be_solved_start_to_finish() -> void:
	var stage := Stage.new()
	var root := (Engine.get_main_loop() as SceneTree).root
	root.add_child(stage)
	var finished := [false]
	stage.completed.connect(func(): finished[0] = true)
	for thing in Logic.THINGS:
		stage.debug_place(thing)
	check_eq(stage.phase, "hall", "tree done opens the statue hall")
	for mark in ["cloak", "wreath", "mask"]:
		stage.debug_pull(mark)
	check_eq(stage.phase, "done", "stripping the accidents ends the stage")
	check(finished[0], "completed signal fired")
	stage.free()
