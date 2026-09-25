extends "res://scripts/pixel/guided.gd"
## Stage 2: Aristotle's Categories, played as a witness report.
## Athens, the Lyceum, about 335 BC. A purse is stolen. Everything you can say about
## anything answers one of ten questions; you ask the witness all ten and the report
## fills in. Nine answers are about the thief; only one is the thief himself: that
## one, the thing itself, is substance, and everything else depends on it.
## Answers use Aristotle's own examples (four cubits, pale, in the market, yesterday,
## sitting, has shoes on, cutting, being cut).

const WORK_ID := "aristotle-categories"
const REPORT := Rect2(162, 18, 150, 104)
const QUESTIONS := [
	{"q": "What was it?", "slot": "What it is", "a": "A man! A grown man.", "fill": "a man",
		"aside": "Mark that answer. It isn't like the others."},
	{"q": "How big was he?", "slot": "How much", "a": "Four cubits tall, I'd say.", "fill": "four cubits tall"},
	{"q": "What was he like?", "slot": "What sort", "a": "Pale. And clever-looking.", "fill": "pale, clever"},
	{"q": "Compared to what?", "slot": "Compared to", "a": "Taller than you! Twice as fast as me.", "fill": "taller than you",
		"aside": "'Taller' only means something next to someone else."},
	{"q": "Where was he?", "slot": "Where", "a": "In the market, by my stall.", "fill": "in the market"},
	{"q": "When was this?", "slot": "When", "a": "Just now! And yesterday too, I think.", "fill": "just now"},
	{"q": "What position was he in?", "slot": "Position", "a": "Crouching. Hiding behind the melons.", "fill": "crouching"},
	{"q": "What did he have on?", "slot": "Has on", "a": "Sandals. New ones.", "fill": "sandals"},
	{"q": "What was he doing?", "slot": "Doing", "a": "Cutting my purse strings!", "fill": "cutting a purse"},
	{"q": "What was done to him?", "slot": "Done to", "a": "He got hit by a cabbage. I threw it.", "fill": "hit by a cabbage"},
]

var report := {}  # slot -> what the witness said
var report_on := false


func setup() -> void:
	card_title = "Stage 2 complete"
	card_sub = "Aristotle, Categories (about 350 BC)"
	place_note = "Athens, the Lyceum, about 335 BC"
	bg = Art.lyceum()
	choice_left = true
	cast = {
		"you": Art.actor("You", "short", "none", Art.pal("1e1a18", "a89a7a", "7a6e56", "6a5a44"), Vector2(38, 138)),
		"aristotle": Art.actor("Aristotle", "short", "short", Art.pal("5a3a24", "7a5a3a", "5a402a", "c8b890"), Vector2(74, 138)),
		"witness": Art.actor("Market woman", "wrap", "none", Art.pal("6a5a7a", "5a4a6a", "3e3450", "8a7a9a"), Vector2(112, 140)),
		"guard": Art.actor("Guard", "wrap", "short", Art.pal("8a3a2a", "6a4a2a", "4a321c", "c09040", "1e1a18"), Vector2(146, 139)),
		"thief": Art.actor("Thief", "short", "none", Art.pal("2a2018", "5a5a50", "3a3a34", "3a3a34"), Vector2(130, 141)),
	}
	for id in ["witness", "guard", "thief"]:
		show_actor(id, false)


func story() -> void:
	await say("aristotle", "Today's question: how many kinds of things can you say about something?")
	await say("you", "Hundreds? Thousands?")
	await say("aristotle", "Ten. Only ten.")
	show_actor("witness")
	await say("witness", "Thief! Stop, thief! He took my purse!")
	show_actor("guard")
	await say("guard", "Which way did he go? What did he look like? Speak up!")
	await say("witness", "He was... oh, it was awful! He was just... awful!")
	await say("aristotle", "She needs better questions. Go on. Ask her the ten.")
	report_on = true
	var open := QUESTIONS.duplicate()
	while not open.is_empty():
		var i: int = await choose(open.map(func(e): return e["q"]))
		var e: Dictionary = open[i]
		open.remove_at(i)
		await say("you", e["q"])
		report[e["slot"]] = e["fill"]
		await say("witness", e["a"])
		if e.has("aside"):
			await say("aristotle", e["aside"])
	await say("guard", "That's everything. I'll find him.")
	show_actor("guard", false)
	await say("aristotle", "Now look at the report. Nine of those answers are about the man.")
	await say("aristotle", "Only one of them is the man himself.")
	await say("aristotle", "Take the man away, and 'pale' or 'crouching' has nothing left to belong to.")
	await say("aristotle", "The thing itself comes first. I call it substance.")
	await say("aristotle", "Everything else is said about it: how big, what sort, where, when.")
	show_actor("guard")
	show_actor("thief")
	cast["guard"]["at"] = Vector2(150, 139)
	cast["thief"]["at"] = Vector2(130, 141)
	await say("guard", "Caught him. Cabbage and all.")
	await say("witness", "That's him! Tall, pale, new sandals!")
	await say("aristotle", "You knew him by the other nine. But he was there before any of them.")
	await say("aristotle", "Ten questions cover anything there is. Try them on your supper tonight.")


func draw_front(ci: CanvasItem) -> void:
	if not report_on:
		return
	ci.draw_rect(REPORT.grow(1), Color("5a4028"))
	ci.draw_rect(REPORT, Pix.P["parchment"])
	Pix.text(ci, Vector2(REPORT.get_center().x, REPORT.position.y + 10), "REPORT: THE PURSE THIEF", 7, Pix.P["ink"], true, false)
	for i in QUESTIONS.size():
		var slot: String = QUESTIONS[i]["slot"]
		var y := REPORT.position.y + 20 + i * 9
		var key_col := Color("7a2a1a") if i == 0 else Color("6a5a40")
		Pix.text(ci, Vector2(REPORT.position.x + 5, y), slot + ":", 6, key_col, false, false)
		if report.has(slot):
			Pix.text(ci, Vector2(REPORT.position.x + 58, y), report[slot], 6, Pix.P["ink"], false, false)
		else:
			ci.draw_rect(Rect2(REPORT.position.x + 58, y, 80, 1), Color("b0a080"))
