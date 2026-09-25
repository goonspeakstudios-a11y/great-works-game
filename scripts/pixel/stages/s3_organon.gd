extends "res://scripts/pixel/guided.gd"
## Stage 3: Aristotle's logic (Prior Analytics I, Sophistical Refutations 4-5).
## Athens, the Agora, about 340 BC. You have ten coins. Six sellers and tricksters try
## an argument on you; you believe it or call it out, and Aristotle explains either way.
## One argument is sound (a syllogism: the shape makes it hold). The others are tricks
## Aristotle named: the consequent (his own wet-ground example), joining words
## (the sophists' "your dog is your father"), begging the question, many questions,
## and "after, so because".

const WORK_ID := "aristotle-the-rest-of-the-organon"
const STALL := Vector2(250, 134)

const MEETINGS := [
	{"who": "baker", "prop": "bread",
		"pitch": ["Every loaf from my oven was baked this morning.", "This loaf came from my oven. So it's fresh! One coin."],
		"options": ["Buy it", "Walk away"],
		"results": [[1, "you", "It's warm. It really is fresh."], [0, "baker", "Your loss. It's still warm!"]],
		"lesson": ["That one holds. If the first two lines are true, the last one has to be.",
			"Swap the words for letters and it still works: all B are A, all C are B, so all C are A.",
			"The shape makes it hold, not the words. I call that a syllogism."]},
	{"who": "cloaker", "prop": "cloak",
		"pitch": ["When it rains, the street gets wet.", "Look, the street is wet! So it rained. A rain cloak, three coins!"],
		"options": ["Buy the cloak", "Something's off"],
		"results": [[3, "you", "Wait. There isn't a cloud in the sky."], [0, "you", "The sky is clear. Not a cloud."]],
		"lesson": ["Rain makes the street wet. But so does that fellow with the bucket.",
			"'If rain, then wet' doesn't mean 'if wet, then rain.'"]},
	{"who": "sophist", "prop": "",
		"pitch": ["Young man! Is this your dog?", "And he's a father? He has puppies?", "So he's a father, and he's yours. He's your father! You're the son of a dog!"],
		"options": ["He... has a point?", "That's a trick."],
		"results": [[0, "", "The crowd roars with laughter."], [0, "you", "Being mine and being a father are two different things!"]],
		"lesson": ["Both are true of the dog. But you can't glue them together into 'your father.'",
			"Words can be joined in ways the facts aren't. Tricksters live in that gap."]},
	{"who": "oiler", "prop": "oil",
		"pitch": ["My oil is the best in Athens!", "How do I know? Because no oil is better than mine! Two coins."],
		"options": ["Buy the oil", "That proves nothing"],
		"results": [[2, "you", "It tastes... like oil."], [0, "oiler", "Hmph. It's the best, I tell you!"]],
		"lesson": ["He proved it's the best by saying it's the best.",
			"The answer was hiding inside the question. Watch for arguments that go in a circle."]},
	{"who": "sophist", "prop": "",
		"pitch": ["A simple question. Yes or no: have you stopped cheating at dice?"],
		"options": ["Yes", "No", "I never cheated!"],
		"results": [[0, "sophist", "Aha! So you did cheat!"], [0, "sophist", "Aha! So you still cheat!"], [0, "sophist", "...A careful one. Hmph."]],
		"lesson": ["That was two questions dressed up as one. Did you cheat? Did you stop?",
			"Split them apart, and answer each one."]},
	{"who": "amuleter", "prop": "amulet",
		"pitch": ["Nikias bought my lucky amulet on Monday. On Tuesday he got rich!", "Four coins, and you'll be rich too!"],
		"options": ["Buy the amulet", "So what?"],
		"results": [[4, "you", "I don't feel any richer."], [0, "you", "The sun came up on Tuesday too."]],
		"lesson": ["It happened after, so it happened because? No.", "After is not the same as because."]},
]

var coins := 10
var seller := ""
var ware := ""


func setup() -> void:
	card_title = "Stage 3 complete"
	card_sub = "Aristotle, the Organon (about 350 BC)"
	place_note = "Athens, the Agora, about 340 BC"
	bg = Art.agora()
	cast = {
		"you": Art.actor("You", "short", "none", Art.pal("1e1a18", "a89a7a", "7a6e56", "6a5a44"), Vector2(150, 134)),
		"aristotle": Art.actor("Aristotle", "short", "short", Art.pal("5a3a24", "7a5a3a", "5a402a", "c8b890"), Vector2(112, 134)),
		"baker": Art.actor("Baker", "bald", "none", Art.pal("c49a78", "e0d8c8", "b8b0a0", "b0a080"), STALL),
		"cloaker": Art.actor("Cloak seller", "short", "short", Art.pal("3a2a1a", "3a5a8a", "2a4066", "d8d0c0"), STALL),
		"sophist": Art.actor("Sophist", "long", "short", Art.pal("2a1a14", "8a2a5a", "5e1a3c", "e0b050"), STALL),
		"oiler": Art.actor("Oil seller", "short", "none", Art.pal("5a3a1a", "4a6a3a", "344a28", "c8b890"), STALL),
		"amuleter": Art.actor("Amulet seller", "wrap", "long", Art.pal("6a2a2a", "5a3a5a", "3e283e", "e0b050", "4a3a30"), STALL),
		"bucketman": Art.actor("Man with a bucket", "short", "none", Art.pal("4a3020", "8a7a5a", "5e5240", "5e5240"), Vector2(40, 132)),
	}
	for id in ["baker", "cloaker", "sophist", "oiler", "amuleter", "bucketman"]:
		show_actor(id, false)


func story() -> void:
	await say("aristotle", "The market. Full of bargains, and full of tricks.")
	await say("aristotle", "An argument is like a bridge. A good one holds your weight. A bad one only looks like a bridge.")
	await say("aristotle", "Here are ten coins. Let's see how many you keep.")
	for m in MEETINGS:
		await _meet(m)
	await say("aristotle", "You kept %d of your ten coins. %s" % [coins, _verdict()])
	await say("aristotle", "Every trick you saw today has a name. I wrote down thirteen of them.")
	await say("aristotle", "Learn the shape of a good argument, and the bad ones stand out.")


func _meet(m: Dictionary) -> void:
	if seller != "":
		show_actor(seller, false)
	seller = m["who"]
	ware = m["prop"]
	show_actor(seller)
	show_actor("bucketman", seller == "cloaker")
	for line in m["pitch"]:
		await say(seller, line)
		if m["who"] == "sophist" and line.ends_with("your dog?"):
			await say("you", "Yes.")
		elif line.ends_with("puppies?"):
			await say("you", "Yes...")
	var i: int = await choose(m["options"])
	var r: Array = m["results"][i]
	coins -= r[0]
	await say(r[1], r[2])
	for line in m["lesson"]:
		await say("aristotle", line)


func _verdict() -> String:
	if coins >= 9:
		return "Not bad at all."
	if coins >= 5:
		return "The market got a little."
	return "The market thanks you."


func draw_scene(ci: CanvasItem) -> void:
	if ware != "":
		Art.prop(ci, ware, Vector2(222, 100), 2)
	if seller == "sophist":
		Art.prop(ci, "dog", Vector2(282, 140), 2)
	if seller == "cloaker":
		ci.draw_rect(Rect2(12, 130, 96, 5), Color(0.35, 0.45, 0.55, 0.55))  # the wet street
		ci.draw_rect(Rect2(50, 120, 7, 7), Color("6a5038"))  # his bucket


func draw_front(ci: CanvasItem) -> void:
	Art.prop(ci, "coin", Vector2(22, 30), 2)
	Pix.text(ci, Vector2(34, 27), "%d" % coins, 8, Pix.P["gold"], false)
