extends "res://tests/test_base.gd"
## Beats (sprint 4): a moment of a book played in the first person, as its hero or as yourself.
## Every beat as written is sound, belongs to a lesson point of its book, can be played through
## without failing, counts its point for a Theoros and not for a Mathetes, and leaves the world as
## it found it.

const Beat := preload("res://scripts/hall/beat.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")
const Hall := preload("res://scripts/hall/hall.gd")
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Kit := preload("res://scripts/hall/kit.gd")

## A small beat with every kind of step, for the runner's own tests.
const SAMPLE := {"hero": "achilles", "title": "Achilles, a test", "steps": [
	{"line": "The son of Atreus insults you before the army."},
	{"swap": "right", "what": "sword"},
	{"act": "Draw your sword", "hold": 1.0},
	{"move": "athena", "by": [0, 0, -1.0], "secs": 0.5},
	{"look": "athena"},
	{"eye": -0.5},
	{"go": "hut", "text": "Walk back to your hut"},
	{"wait": 0.3},
	{"hide": "athena"},
	{"act": "Sheathe it"}]}


func test_every_beat_is_sound_and_belongs_to_a_lesson_point() -> void:
	var all := Beat.all()
	for work in all:
		var room := Rooms.room(work)
		check(not room.is_empty(), "%s has a room" % work)
		for name in all[work]:
			var def: Dictionary = all[work][name]
			check_eq(Beat.problems(def), [], "%s/%s is sound" % [work, name])
			var point: String = def.get("point", "")
			if point != "":
				check(room.get("lesson", []).any(func(p): return p["id"] == point), "%s/%s plays the point '%s' of its book" % [work, name, point])


func test_a_beat_plays_through_without_failing_and_puts_things_back() -> void:
	var world := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
	var player = preload("res://scripts/hall/player.gd").new()
	world.add_child(player)
	var athena := Kit.group(world, Vector3(0, 0, -3))
	var b := Beat.new(SAMPLE, "homer-the-iliad", "menis", {"athena": athena}, {"hut": Vector3(10, 0, 0)})
	check_eq(Beat.problems(SAMPLE), [], "the sample is sound")
	b.start(player)
	check(not b.arms.is_empty() and b.arms["root"].get_parent() == player.camera, "the hero's arms come up before your eyes")
	check(player.camera.find_children("*", "CollisionObject3D", true, false).is_empty(), "and touch nothing")
	check(b.prompt().contains("son of Atreus"), "one short line at a time")
	check(not b.free_to_walk(), "you stand while a line is read")
	b.press(player)
	check_eq(b.kind(), "act", "the sword is swapped into your hand and you are asked to act")
	b.press(player)
	check_eq(b.kind(), "act", "a held act does not end on a tap")
	for k in 30:
		b.update(0.05, player, true)
	check_eq(b.kind(), "move", "holding F long enough does it")
	for k in 20:
		b.update(0.05, player, false)
	check(athena.position.z < -3.9, "Athena comes")
	for k in 20:
		b.update(0.05, player, false)
	check_eq(b.kind(), "go", "the view turns to her, your eyes drop, and you are sent walking")
	check(b.free_to_walk(), "and you may walk")
	check(b.next_mark() is Vector3, "the place shows you where")
	player.position = Vector3(10, 0, 0.5)
	b.update(0.05, player, false)
	for k in 10:
		b.update(0.05, player, false)
	check(not athena.visible, "she goes")
	check_eq(b.kind(), "act", "the last act")
	b.press(player)
	check(b.done, "the beat is done: there is no failing it")
	var eye: float = player.camera.position.y
	b.finish(player)
	check(is_equal_approx(player.camera.position.y, eye + 0.5), "your eyes come back up")
	check(is_equal_approx(athena.position.z, -3.0), "Athena is put back where she stood, for the next time")
	check(b.arms.is_empty() and player.camera.get_child_count() == 0, "the arms are gone")
	world.free()


func test_a_broken_beat_is_caught() -> void:
	check(not Beat.problems({"steps": []}).is_empty(), "no steps")
	check(not Beat.problems({"steps": [{"line": "only words"}]}).is_empty(), "nothing to do")
	check(not Beat.problems({"hero": "nobody", "steps": [{"act": "x"}]}).is_empty(), "an unknown hero")
	check(not Beat.problems({"steps": [{"act": "x", "line": "y"}]}).is_empty(), "two things in one step")


## In the hall: a beat's point counts for a Theoros when it ends, and not for a Mathetes; Esc
## leaves it half done and counts nothing.
func test_a_finished_beat_counts_its_point_in_zen_only() -> void:
	for mode in ["student", "zen", "left"]:
		var hall: Node = Hall.new()
		hall.offline = true
		(Engine.get_main_loop() as SceneTree).root.add_child(hall)
		hall.travel("aristotle-categories")
		hall.progress.data = {"works": {}}
		hall.progress.set_mode("greece", "student" if mode == "student" else "zen")
		var def := {"steps": [{"line": "A line."}, {"act": "Do it"}]}
		var it := {"kind": "beat", "work": "aristotle-categories", "id": "ten_questions", "beat": "_test",
			"note": Rooms.room("aristotle-categories")["lesson"][0]["point"], "pos": Vector3.ZERO, "text": "Play"}
		hall._beat_it = it
		hall.beat = Beat.new(def, "aristotle-categories", "ten_questions")
		hall.beat.start(hall.player)
		if mode == "left":
			hall._end_beat(false)
			check(hall.beat == null and hall.progress.understood("aristotle-categories").is_empty(), "left with Esc: nothing counts")
			hall.free()
			continue
		hall.beat.press(hall.player)
		hall.beat.press(hall.player)
		hall._play_beat(0.1)
		check(hall.beat == null, "%s: the beat ends" % mode)
		check(hall._read_panel.visible, "%s: its point is read" % mode)
		hall._close_panels()
		if mode == "zen":
			check(hall.progress.understood("aristotle-categories").has("ten_questions"), "zen: the point counts")
			check_eq(hall.restored_here, ["water"], "zen: a piece comes back")
		else:
			check(hall.progress.understood("aristotle-categories").is_empty(), "student: it counts nothing")
		hall.free()
