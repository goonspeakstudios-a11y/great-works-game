extends Node
## A self-playing test run: crosses the Shore to the first gateway, travels to Porphyry's
## villa, reads a stone, looks at the map, a bust, Porphyry's Tree and the book, then asks
## Porphyry two real questions (live, about a cent). Saves a screenshot at each step and
## writes down the conversation, then quits.
##   godot --path . -- --demo [--shots=C:/folder]

const Places := preload("res://scripts/hall/places.gd")
const QUESTIONS := ["What is your book about?", "What is an accident?"]
const SPEED := 3.0

var hall: Node
var shots_dir := "user://test_run"
var _log: PackedStringArray = []
var _last_reply := {}
var ask := true  # false skips the two paid questions (for checking the route)


func run() -> void:
	DirAccess.make_dir_recursive_absolute(shots_dir)
	_note("Test run started.")
	await _wait(2.5)
	await _shot("01_shore", "The Shore of the Great Works at sunset.")
	await _go([Vector3(10, 0, 1), hall.spots["gate0"]])
	await _face(Places.gate_spot(0))
	await _wait(1.0)
	await _shot("02_gateway", "Gateway 1: " + hall._prompt.text.replace("\n", " "))
	hall.activate(hall.target)
	while hall.travelling:
		await get_tree().process_frame
	await _wait(1.5)
	await _shot("03_arrival", "Arrived: " + hall.here_name)
	await _go([hall.spots["fact0"]])
	await _face(hall.spots["fact0"] + Vector3(-3, 0, 0))
	await _use("04_stone", "An inscribed stone on the path.")
	await _go([Vector3(0, 0, 8)])
	await _face(Vector3(0, 0, -10))
	await _wait(0.8)
	await _shot("05_villa", "Porphyry's villa, up the path.")
	await _go([Vector3(0, 0, 1.5), Vector3(-3.2, 0, -2.0), Vector3(-3.2, 0, -9.8), Vector3(-1.2, 0, -12.6), hall.spots["map"]])
	await _face(hall.spots["map"] + Vector3(-3, 0, 0))
	await _use("06_map", "The map of the world in 270 AD.")
	await _go([hall.spots["statue0"]])
	await _face(hall.spots["statue0"] + Vector3(0, 0, -3))
	await _use("07_bust", "The bust of Aristotle.")
	await _go([Vector3(0, 0, -14.2), hall.spots["tree"]])
	await _face(hall.spots["tree"] + Vector3(3, 0, 0))
	await _use("08_tree", "Porphyry's Tree.")
	await _go([hall.spots["book"]])
	await _face(hall.spots["book"] + Vector3(0, 0, -3))
	await _use("09_book", "A real page of the book.")
	await _go([hall.spots["author"]])
	await _face(hall.spots["author"] + Vector3(0, 0, -3))
	await _wait(0.8)
	await _shot("10_study", "Porphyry's study.")
	hall.activate(hall.target)
	await _wait(1.2)
	hall.author.answered.connect(func(r: Dictionary): _last_reply = r)
	for i in (QUESTIONS.size() if ask else 0):
		await _type(QUESTIONS[i])
		var started := Time.get_ticks_msec()
		hall._send(QUESTIONS[i])
		while hall.author.busy:
			await get_tree().process_frame
		var secs := (Time.get_ticks_msec() - started) / 1000.0
		var said: String = _last_reply.get("text", "") if _last_reply.get("error", "") == "" else "ERROR " + str(_last_reply["error"])
		_note("Q: %s\nA (%.1f s): %s" % [QUESTIONS[i], secs, said])
		for q in _last_reply.get("quotes", []):
			_note("   quote [%s]: %s" % [q["where"], q["text"]])
		await _wait(1.0)
		await _shot("%02d_answer" % (11 + i), "Porphyry answers: " + QUESTIONS[i])
		await _wait(5.0)
	hall._close_panels()
	hall._prompt.text = "Test run complete."
	_note("Test run complete.")
	var f := FileAccess.open(shots_dir.path_join("transcript.txt"), FileAccess.WRITE)
	f.store_string("\n".join(_log))
	f.close()
	await _wait(3.0)
	get_tree().quit()


func _use(name: String, caption: String) -> void:
	await _wait(0.6)
	var what: String = hall.target.get("text", "nothing in reach")
	hall.activate(hall.target)
	await _wait(1.2)
	await _shot(name, caption + " (" + what + ")")
	await _wait(3.0)
	hall._close_panels()
	await _wait(0.4)


## Walks through each point in turn at a steady pace.
func _go(points: Array) -> void:
	for p in points:
		var to := Vector3(p.x, hall.player.position.y, p.z)
		var dist: float = hall.player.position.distance_to(to)
		if dist < 0.05:
			continue
		await _face(to, 0.35)
		var tw := create_tween()
		tw.tween_property(hall.player, "position", to, dist / SPEED)
		await tw.finished


func _face(point: Vector3, seconds: float = 0.6) -> void:
	var d: Vector3 = point - hall.player.position
	var want := Places.look_yaw(d)
	var now: float = hall.player.rotation.y
	want = now + wrapf(want - now, -PI, PI)
	var tw := create_tween()
	tw.tween_property(hall.player, "rotation:y", want, seconds).set_trans(Tween.TRANS_SINE)
	await tw.finished


## Types the question into the box one letter at a time, like a player would.
func _type(question: String) -> void:
	hall._question_box.text = ""
	for c in question:
		hall._question_box.text += c
		await _wait(0.04)
	await _wait(0.4)


func _shot(name: String, caption: String) -> void:
	await RenderingServer.frame_post_draw
	hall.get_viewport().get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))
	var p: Vector3 = hall.player.position
	_note("[%s] %s   (at %.1f, %.1f facing %d deg, %d fps)" % [name, caption, p.x, p.z, roundi(rad_to_deg(hall.player.rotation.y)), Engine.get_frames_per_second()])


func _note(line: String) -> void:
	_log.append(line)
	print(line)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
