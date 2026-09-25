extends "res://tests/test_base.gd"

const Story := preload("res://scripts/story.gd")

const CHAPTER := {
	"steps": [
		{"id": "a", "type": "scene", "beats": [{"say": "narrator", "line": "hi"}, {"learn": "x"}, {"move": "p", "to": [1, 2]}]},
		{"id": "f", "type": "fight"},
		{"id": "b", "type": "scene", "beats": [{"learn": "y"}]},
	],
}


func test_beats_play_in_order_and_record_learning() -> void:
	var s := Story.new()
	s.start(CHAPTER["steps"][0])
	var kinds: Array = []
	var beat := s.next()
	while not beat.is_empty():
		kinds.append(Story.beat_kind(beat))
		beat = s.next()
	check_eq(kinds, ["say", "learn", "move"], "beat order")
	check_eq(s.learned, ["x"] as Array[String], "learned ideas")
	check(s.is_done(), "done after last beat")


func test_current_step_skips_done_steps() -> void:
	check_eq(Story.current_step(CHAPTER, []), 0, "fresh start")
	check_eq(Story.current_step(CHAPTER, ["a"]), 1, "after first scene")
	check_eq(Story.current_step(CHAPTER, ["a", "f", "b"]), 3, "finished")


func test_ideas_taught_before_a_step() -> void:
	check_eq(Story.ideas_taught(CHAPTER, 1), ["x"], "deck for the fight")
	check_eq(Story.ideas_taught(CHAPTER, 3), ["x", "y"], "everything")
