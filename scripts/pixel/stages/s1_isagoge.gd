extends "res://scripts/pixel/guided.gd"
## Stage 1: Porphyry's Isagoge, played as Guess Who.
## Sicily, about 270 AD. Porphyry teaches his confused student Chrysaorius how to say
## what a thing is. Each good question splits a family in two (genus, species,
## difference); a cloak only tells you which man (accident); laughing always comes
## with being human (property). It ends on the question Porphyry left open.

const WORK_ID := "porphyry-isagoge"
const TILES := ["stone", "statue", "jar", "oak", "rose", "wheat", "fish", "horse", "dog", "eagle",
	"socrates", "plato"]
const BOARD := Rect2(176, 12, 132, 80)

## Each round offers questions until one marked "next" is asked. Answers flip tiles down.
const ROUNDS := [
	[
		{"q": "Is it alive?", "a": "Yes.", "flip": ["stone", "statue", "jar"], "next": true,
			"then": ["Good. You just split everything into two families: living, and not living."]},
		{"q": "Is it big?", "a": "Big compared to what? A horse is big next to a dog, and small next to a ship.",
			"then": ["Ask about what it is."]},
		{"q": "Is he wearing a cloak?", "a": "He? Careful. First find out what kind of thing it is.", "then": []},
	],
	[
		{"q": "Can it feel, and move by itself?", "a": "Yes.", "flip": ["oak", "rose", "wheat"], "next": true,
			"then": ["Now only animals are left. Animal is the family."]},
		{"q": "Is it pretty?", "a": "That depends on who's looking. It tells you nothing about what it is.", "then": []},
	],
	[
		{"q": "Can it think and speak?", "a": "Yes.", "flip": ["fish", "horse", "dog", "eagle"], "next": true,
			"then": ["That's the one that matters. Thinking splits humans off from every other animal."]},
		{"q": "Does it have four legs?", "a": "No.", "flip": ["horse", "dog"],
			"then": ["True. But a fish has no legs either. Keep going."]},
		{"q": "Can it fly?", "a": "No.", "flip": ["eagle"],
			"then": ["Fair. But you're only crossing them off one at a time."]},
	],
	[
		{"q": "Can he laugh?", "a": "Yes. Both of them can.",
			"then": ["Only people laugh. It always comes with being human.", "But it isn't what makes you human. That's called a property."]},
		{"q": "Is he wearing a cloak?", "a": "Yes.", "flip": ["socrates"], "next": true,
			"then": ["Ha. A cloak comes and goes. It told you which man, not what he is."]},
		{"q": "Is he bald?", "a": "No.", "flip": ["socrates"], "next": true,
			"then": ["Hair comes and goes too. It told you which man, not what he is."]},
	],
]

var down := {}  # tile -> time it was flipped down
var board_on := false
var tree_rows := 0  # how much of the family tree is drawn
var tree_marks := {}  # extra labels on the tree: genus, species, difference


func setup() -> void:
	card_title = "Stage 1 complete"
	card_sub = "Porphyry, Isagoge (about 270 AD)"
	place_note = "Sicily, about 270 AD"
	bg = Art.villa()
	cast = {
		"you": Art.actor("Chrysaorius", "short", "none", Art.pal("3a2a1e", "d8d2c4", "aca494", "6a2a5a"), Vector2(56, 132)),
		"porphyry": Art.actor("Porphyry", "short", "long", Art.pal("d0ccc4", "2e3a5a", "1e2640", "a08a50"), Vector2(118, 132)),
	}


func story() -> void:
	await say("porphyry", "Chrysaorius! You look lost.")
	await say("you", "It's Aristotle's book. I can't follow a word of it.")
	await say("porphyry", "Then first, learn how to say what a thing is.")
	board_on = true
	await say("porphyry", "Let's play a game. I'm thinking of one of these twelve.")
	await say("porphyry", "Ask me yes-or-no questions until only one is left.")
	for r in ROUNDS.size():
		if r == 3:
			await say("porphyry", "Two left, and both are people.")
		await _play_round(ROUNDS[r])
	await say("you", "It's Plato!")
	await say("porphyry", "It is. And look at how you found him.")
	board_on = false
	await _tree()
	await say("porphyry", "There's one question I won't answer, though.")
	await say("porphyry", "Does 'animal' exist out there in the world? Or only in our heads?")
	await say("porphyry", "Let others argue about that one.")
	await say("", "They did. For a thousand years.")


func _play_round(round: Array) -> void:
	var open := round.duplicate()
	while true:
		var i: int = await choose(open.map(func(e): return e["q"]))
		var e: Dictionary = open[i]
		open.remove_at(i)
		await say("you", e["q"])
		for tile in e.get("flip", []):
			if not down.has(tile):
				down[tile] = t
		await say("porphyry", e["a"])
		for line in e["then"]:
			await say("porphyry", line)
		if e.get("next", false) or open.is_empty():
			return


func _tree() -> void:
	tree_rows = 5
	await say("porphyry", "Each good question split a group in two.")
	tree_marks["genus"] = true
	await say("porphyry", "The bigger group is the family. Philosophers call it the genus.")
	tree_marks["species"] = true
	await say("porphyry", "The smaller group inside it is the kind. That's the species.")
	tree_marks["difference"] = true
	await say("porphyry", "What split them is the difference. For humans, it's thinking.")
	await say("porphyry", "The cloak only told you which man. Things that come and go are accidents.")
	await say("porphyry", "And laughing always comes with being human. That's a property.")
	await say("porphyry", "So to say what anything is: name its family, then its difference.")
	await say("you", "A human is an animal that thinks.")
	await say("porphyry", "Exactly. Now you're ready for Aristotle.")


func standing() -> Array:
	return TILES.filter(func(k): return not down.has(k))


# ---------- drawing ----------

func draw_front(ci: CanvasItem) -> void:
	if board_on:
		_draw_board(ci)
	elif tree_rows > 0:
		_draw_tree(ci)


func _draw_board(ci: CanvasItem) -> void:
	for i in TILES.size():
		var k: String = TILES[i]
		var cell := Rect2(BOARD.position.x + (i % 4) * 33, BOARD.position.y + (i / 4) * 27, 31, 25)
		var flip := clampf((t - down[k]) / 0.25, 0.0, 1.0) if down.has(k) else 0.0
		if flip >= 1.0:
			ci.draw_rect(Rect2(cell.position.x, cell.end.y - 5, cell.size.x, 5), Color("2a1e14"))
			ci.draw_rect(Rect2(cell.position.x, cell.end.y - 5, cell.size.x, 1), Color("4a3624"))
			continue
		var h := cell.size.y * (1.0 - flip)
		var face := Rect2(cell.position.x, cell.end.y - h, cell.size.x, h)
		ci.draw_rect(face, Color("e8dcc0"))
		ci.draw_rect(Rect2(face.position.x, face.position.y, face.size.x, 1), Color("f8f0dc"))
		ci.draw_rect(Rect2(face.position.x, face.end.y - 1, face.size.x, 1), Color("a89878"))
		if flip < 0.5:
			Art.prop(ci, k, Vector2(cell.get_center().x, cell.end.y - 3), 2)


func _draw_tree(ci: CanvasItem) -> void:
	var rows := [["Things", "not alive"], ["Living things", "can't feel"], ["Animals", "can't think"],
		["Humans", "no cloak"], ["Plato", ""]]
	var ink := Color("e8dcc0")
	var dim := Color("a89878")
	for i in rows.size():
		var at := Vector2(182 + i * 6, 24 + i * 15)
		if i > 0:
			ci.draw_rect(Rect2(at.x - 5, at.y - 12, 1, 9), dim)
			ci.draw_rect(Rect2(at.x - 5, at.y - 4, 4, 1), dim)
		Pix.text(ci, at, rows[i][0], 8, Pix.P["gold"] if i == 4 else ink, false)
		if rows[i][1] != "":
			Pix.text(ci, Vector2(268, at.y), "- " + rows[i][1], 6, dim, false)
	if tree_marks.has("genus"):
		Pix.text(ci, Vector2(194, 61), "genus", 6, Pix.P["ghost"], false)
	if tree_marks.has("species"):
		Pix.text(ci, Vector2(200, 76), "species", 6, Pix.P["ghost"], false)
	if tree_marks.has("difference"):
		Pix.text(ci, Vector2(234, 69), "+ thinks", 6, Color("f0a050"), false)
