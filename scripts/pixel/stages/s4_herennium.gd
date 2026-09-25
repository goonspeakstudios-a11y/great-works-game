extends "res://scripts/pixel/guided.gd"
## Stage 4: Rhetorica ad Herennium (I.2-4, the five steps and the parts of a speech;
## III.16-24, the art of memory).
## Rome, about 85 BC. Your friend Gaius is on trial for stealing a goat and you must
## speak for him. Your teacher walks you through the five steps, then the memory
## trick: leave a strange picture in each room of your house. In court your mind goes
## blank, so you walk the house again in your head and every picture is waiting.

const WORK_ID := "rhetorica-ad-herennium"
const ROOMS := ["Doorway", "Atrium", "Kitchen", "Dining room", "Garden"]
const SPOTS := [
	{"img": "trumpet", "at": Vector2(38, 74), "to": Vector2(38, 100), "part": "opening",
		"place": "A trumpet blasting in your doorway. That's your opening: 'Romans, hear me!'",
		"speech": "Romans, hear me! My friend Gaius is no thief."},
	{"img": "goat", "at": Vector2(97, 92), "to": Vector2(97, 118), "part": "the story",
		"place": "A goat swimming in your pool. That's the story: a goat went missing.",
		"speech": "A goat went missing from Titus's yard. That much is true."},
	{"img": "cloud", "at": Vector2(159, 70), "to": Vector2(159, 100), "part": "proof",
		"place": "A storm cloud smashing your pots. The storm broke the fence, not a man.",
		"speech": "But the fence was broken by the storm, not by any man."},
	{"img": "toga_goat", "at": Vector2(221, 90), "to": Vector2(221, 104), "part": "proof",
		"place": "Goats at your dinner table, in togas. Gaius owns five goats already.",
		"speech": "Gaius already owns five goats. Why would he steal a sixth?"},
	{"img": "baker", "at": Vector2(282, 92), "to": Vector2(282, 116), "part": "strongest proof",
		"place": "A giant baker in your garden, covered in flour. He saw Gaius at his ovens all morning.",
		"speech": "And the baker saw Gaius at his ovens all morning long!"},
]

var scene := "study"  # study, house, court, mind
var placed := 0
var recalled := 0
var next_spot := -1
var _bgs := {}


func setup() -> void:
	card_title = "Stage 4 complete"
	card_sub = "Rhetorica ad Herennium (about 85 BC), author unknown"
	place_note = "Rome, about 85 BC"
	var toga := ["d8d2c4", "aca494"]
	cast = {
		"teacher": Art.actor("Teacher", "bald", "short", Art.pal("c49a78", toga[0], toga[1], "b0a890", "9a948a"), Vector2(70, 138)),
		"you": Art.actor("You", "short", "none", Art.pal("3a2a1e", toga[0], toga[1], "c8c0b0"), Vector2(110, 138)),
		"walker": Art.actor("You", "short", "none", Art.pal("3a2a1e", toga[0], toga[1], "c8c0b0"), Vector2(22, 104), 1),
		"judge": Art.actor("Judge", "short", "short", Art.pal("8a8a8a", toga[0], toga[1], "6a2a5a", "8a8a8a"), Vector2(160, 98)),
		"gaius": Art.actor("Gaius", "short", "none", Art.pal("7a3a1a", "9a8a6a", "6e6250", "6e6250"), Vector2(196, 140)),
		"titus": Art.actor("Titus", "bald", "long", Art.pal("c49a78", "6a5a3a", "4a3e28", "4a3e28", "3a2a1e"), Vector2(262, 140)),
	}
	hero = "walker"
	var house := Art.house()
	_bgs = {"study": Art.roman_room(), "house": house, "mind": house, "court": Art.court()}
	_scene("study")


func _scene(s: String) -> void:
	scene = s
	bg = _bgs[s]
	var who: Array = {"study": ["teacher", "you"], "house": ["walker"], "mind": ["walker"],
		"court": ["judge", "gaius", "titus", "you", "teacher"]}[s]
	for id in cast:
		show_actor(id, id in who)
	if s == "court":
		cast["you"]["at"] = Vector2(120, 140)
		cast["teacher"]["at"] = Vector2(40, 146)
	if s in ["house", "mind"]:
		cast["walker"]["at"] = Vector2(22, 104)


func can_stand(p: Vector2) -> bool:
	for r in Art.HOUSE_ROOMS:
		if Rect2(r).grow(-3).has_point(p) or Rect2(r.end.x - 3, 78, 10, 16).has_point(p):
			return true
	return Rect2(9, 78, 6, 16).has_point(p)


func story() -> void:
	await say("teacher", "Tomorrow you speak in court for Gaius. Half of Rome will be watching.")
	await say("you", "I'll forget everything. I always do.")
	await say("teacher", "Then we do it properly. Every speech is built in five steps.")
	await say("teacher", "Find what to say. Put it in order. Pick your words. Remember it. Deliver it.")
	await say("teacher", "First, what do we know? The fence was broken by last night's storm.")
	await say("teacher", "Gaius already owns five goats. And the baker saw him at his ovens all morning.")
	await say("teacher", "Now the order: open, tell what happened, prove it, answer the other side, close.")
	await say("teacher", "Save your strongest proof for last. The baker goes last.")
	await say("teacher", "Words: plain ones. Now the part everyone gets wrong. Remembering it.")
	await say("teacher", "Picture your own house. In each room, leave a strange picture for one part of the speech.")
	await say("teacher", "The stranger the picture, the better it sticks. Go on, walk through.")
	_scene("house")
	for i in SPOTS.size():
		next_spot = i
		await walk_to(SPOTS[i]["to"], 10.0)
		placed = i + 1
		await say("teacher", SPOTS[i]["place"])
	next_spot = -1
	await say("teacher", "Good. Tomorrow, walk the house again in your head. Every picture will be waiting.")
	_scene("court")
	await say("judge", "Titus says Gaius stole his goat. Who speaks for Gaius?")
	await say("you", "I do.")
	await say("", "Your mind goes blank. Then you remember the house.")
	_scene("mind")
	look.set_saturation(0.25, 1.0)
	for i in SPOTS.size():
		next_spot = i
		await walk_to(SPOTS[i]["to"], 10.0)
		recalled = i + 1
		await say("you", SPOTS[i]["speech"])
	next_spot = -1
	_scene("court")
	look.set_saturation(1.0, 1.0)
	await say("", "The crowd murmurs. Titus stares at his feet.")
	await say("judge", "Gaius is free to go.")
	await say("gaius", "You didn't forget a single thing!")
	await say("teacher", "Of course not. You walked it.")
	await say("teacher", "People have used this trick for two thousand years. It works in your house tonight.")


func draw_scene(ci: CanvasItem) -> void:
	if scene in ["house", "mind"]:
		for i in ROOMS.size():
			var r: Rect2i = Art.HOUSE_ROOMS[i]
			Pix.text(ci, Vector2(r.get_center().x, 38), ROOMS[i], 6, Pix.P["bone"])


func draw_memory(ci: CanvasItem) -> void:
	if scene not in ["house", "mind"]:
		return
	var shown := placed if scene == "house" else recalled
	for i in shown:
		var s: Dictionary = SPOTS[i]
		if s["img"] == "toga_goat":
			for dx in [-16, 16]:
				Art.prop(ci, "toga_goat", s["at"] + Vector2(dx, 4), 2)
		Art.prop(ci, s["img"], s["at"], 3 if s["img"] == "baker" else 2)
		Pix.text(ci, s["at"] + Vector2(0, 8), s["part"], 5, Pix.P["gold"])
	if next_spot >= 0:
		var at: Vector2 = SPOTS[next_spot]["to"]
		var a := 0.5 + 0.4 * sin(t * 5.0)
		ci.draw_arc(at, 6.0, 0.0, TAU, 16, Color(Pix.P["gold"], a), 1.0)
