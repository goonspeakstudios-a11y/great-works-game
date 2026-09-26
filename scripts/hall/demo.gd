extends Node
## A self-playing test run of the Hall: walks down the hall to the first room, reads a
## plaque, opens the book, asks the author two real questions (live, so it costs about
## a cent), saves a screenshot at each step, writes the conversation down, then quits.
##   godot --path . -- --demo [--shots=C:/folder]

const QUESTIONS := ["What is your book about?", "What is an accident?"]

var hall: Node
var shots_dir := "user://test_run"
var _log: PackedStringArray = []
var _last_reply := {}


func run() -> void:
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var p: CharacterBody3D = hall.player
	var dz: float = hall.door_z(0)
	_note("Test run started.")
	await _wait(2.0)
	await _shot("01_hall", "The Hall of Greece, from the entrance.")
	await _walk(Vector3(0, p.position.y, dz), 3.0)
	await _turn(PI / 2.0, 0.8)
	await _wait(1.2)
	await _shot("02_door", "At door 1: " + hall._prompt.text)
	await _walk(Vector3(-4.2, p.position.y, dz), 2.0)
	var fact: Dictionary = hall.interactables.filter(func(i): return i["kind"] == "fact")[1]
	await _walk(Vector3(fact["pos"].x, p.position.y, fact["pos"].z + 0.3), 1.8)
	await _turn(0.0, 0.8)
	await _wait(0.8)
	await _use("03_plaque", "Reading a plaque.")
	await _walk(Vector3(-4.6, p.position.y, dz), 1.8)
	await _turn(PI / 2.0, 0.8)
	await _wait(0.8)
	await _use("04_book", "Opening the book on the lectern: a real page.")
	await _walk(Vector3(-8.3, p.position.y, dz), 1.8)
	await _wait(0.8)
	await _shot("05_portrait", "Porphyry's portrait.")
	hall.activate(hall.target)
	await _wait(1.5)
	hall.author.answered.connect(func(r: Dictionary): _last_reply = r)
	for i in QUESTIONS.size():
		await _type(QUESTIONS[i])
		var started := Time.get_ticks_msec()
		hall._send(QUESTIONS[i])
		while hall.author.busy:
			await get_tree().process_frame
		var secs := (Time.get_ticks_msec() - started) / 1000.0
		_note("Q: %s\nA (%.1f s): %s" % [QUESTIONS[i], secs, _last_reply.get("text", "") if _last_reply.get("error", "") == "" else "ERROR " + _last_reply["error"]])
		for q in _last_reply.get("quotes", []):
			_note("   quote [%s]: %s" % [q["where"], q["text"]])
		await _wait(1.0)
		await _shot("%02d_answer" % (6 + i), "Porphyry answers: " + QUESTIONS[i])
		await _wait(6.0)
	hall._close_panels()
	hall._prompt.text = "Test run complete."
	_note("Test run complete.")
	var f := FileAccess.open(shots_dir.path_join("transcript.txt"), FileAccess.WRITE)
	f.store_string("\n".join(_log))
	f.close()
	await _wait(3.0)
	get_tree().quit()


func _use(name: String, caption: String) -> void:
	hall.activate(hall.target)
	await _wait(1.0)
	await _shot(name, caption + " " + _plain(hall._read_text.text))
	await _wait(3.0)
	hall._close_panels()


func _walk(to: Vector3, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(hall.player, "position", to, seconds).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _turn(yaw: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(hall.player, "rotation:y", yaw, seconds).set_trans(Tween.TRANS_SINE)
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
	_note("[%s] %s" % [name, caption])


func _note(line: String) -> void:
	_log.append(line)
	print(line)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


static func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]*\\]").sub(bbcode, "", true).replace("\n", " ").strip_edges()
