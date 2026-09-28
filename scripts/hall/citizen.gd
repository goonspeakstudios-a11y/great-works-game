extends RefCounted
## A citizen of Rome: someone with a name, a job, a home, a family and a mood, who talks like a
## real person of their trade and their age (content/rome/people.json), not like a scholar.
##
## make() draws one up. reply() answers the topics of the talk panel (who are you, your work,
## your life, the news, the gods, what's around here) in their own words. heard() turns whatever you
## type into one of those topics when no one is on the line to Claude. persona() is what Claude is
## told to be when someone is: the citizen, briefly, in the first person, knowing only their own
## time. react() is the short thing they say out loud as you pass or bump into them.

const FILE := "res://content/rome/people.json"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if parsed is Dictionary:
			_data = parsed
		else:
			push_error("people.json does not parse")
	return _data


## The jobs people are at in an age.
static func jobs_for(age: String) -> Array:
	return (data().get("jobs", []) as Array).filter(func(j: Dictionary) -> bool: return (j["ages"] as Array).has(age))


static func job(id: String) -> Dictionary:
	for j: Dictionary in data().get("jobs", []):
		if j["id"] == id:
			return j
	return {}


static func _pick(rng: RandomNumberGenerator, list: Array) -> Variant:
	return list[rng.randi() % list.size()] if not list.is_empty() else ""


## Someone at `job_id` in `age`, living in one of `homes` (region names).
static func make(rng: RandomNumberGenerator, job_id: String, age: String, homes: Array) -> Dictionary:
	var j := job(job_id)
	var n: Dictionary = data()["names"]
	var gender: String = j.get("gender", "m")
	if gender == "any":
		gender = "f" if rng.randf() < 0.4 else "m"
	var cls: String = j.get("class", "pleb")
	var origin := "Roman"
	var name := ""
	var call := ""  # what they'd have you call them
	var late := age in ["late", "fall"]
	if cls == "foreign" or (cls == "slave" and rng.randf() < 0.3):
		var peoples: Array = (n["foreign"] as Dictionary).keys().filter(func(k: String) -> bool: return k != "Goth" or late)
		origin = str(_pick(rng, peoples))
		name = str(_pick(rng, n["foreign"][origin][gender]))
		call = name
	elif cls == "church" or (late and rng.randf() < 0.5):
		name = str(_pick(rng, n["christian"][gender]))
		call = name
	elif cls == "slave":
		name = str(_pick(rng, n["greek_men"] if gender == "m" else n["greek_women"]))
		call = name
	elif gender == "f":
		var nomen: String = _pick(rng, n["nomina"])
		name = "%sa %s" % [nomen.trim_suffix("us"), _pick(rng, n["women_cognomina"])]
		call = name.split(" ")[0]
	elif cls == "freed":
		var patron_nomen: String = _pick(rng, n["nomina"])
		name = "%s %s %s" % [_pick(rng, n["praenomina"]), patron_nomen, _pick(rng, n["greek_men"])]
		call = name.split(" ")[2]
	else:
		name = "%s %s %s" % [_pick(rng, n["praenomina"]), _pick(rng, n["nomina"]), _pick(rng, n["cognomina"])]
		call = name.split(" ")[0] if rng.randf() < 0.5 else name.split(" ")[2]
	var kids := rng.randi_range(0, 4)
	var mood: Array = _pick(rng, data().get("moods", [["cheerful", ""]]))
	return {
		"id": "%s_%d" % [job_id, rng.randi()], "name": name, "call": call, "gender": gender, "class": cls, "origin": origin,
		"job": job_id, "title": j.get("title", job_id), "latin": j.get("latin", ""), "age": age,
		"years": rng.randi_range(17, 66), "home": str(_pick(rng, homes)) if not homes.is_empty() else "Subura",
		"partner": ("husband" if gender == "f" else "wife") if rng.randf() < 0.7 else "",
		"kids": kids, "patron": str(_pick(rng, data().get("patrons", ["the Cornelii"]))),
		"mood": mood[0], "mood_line": mood[1], "said": {},
	}


## A citizen's words with their own details filled in.
static func fill(p: Dictionary, line: String) -> String:
	var kids: int = p.get("kids", 0)
	var kid_words := "no children" if kids == 0 else ("one child" if kids == 1 else "%d children" % kids)
	return line.replace("{name}", p["name"]).replace("{home}", p["home"]).replace("{patron}", p["patron"]) \
		.replace("{partner}", p["partner"] if p["partner"] != "" else "neighbours").replace("{kids}", kid_words)


## The next of a list they have not said yet (then round again).
static func _next(p: Dictionary, key: String, list: Array) -> String:
	if list.is_empty():
		return ""
	var said: Dictionary = p["said"]
	var k: int = said.get(key, 0)
	said[key] = k + 1
	return str(list[k % list.size()])


## What they say when you first stop them.
static func greeting(p: Dictionary) -> String:
	var hello: Array = data()["reacts"]["greet"].get(p["class"], ["Salve."])
	return "%s %s" % [hello[absi(hash(p["id"])) % hello.size()], p["mood_line"]]


## Their answer to one of the talk panel's topics. `near`: the names of what stands close by.
static func reply(p: Dictionary, topic: String, near: Array = []) -> String:
	var j := job(p["job"])
	var d := data()
	match topic:
		"who":
			var who := fill(p, str(j.get("intro", "{name}.")))
			if not p["said"].has("who"):
				p["said"]["who"] = 1
				return who
			return "I told you: %s, %s. Did you forget already?" % [p["call"], p["title"]]
		"work":
			return fill(p, _next(p, "work", (j.get("work", []) as Array) + (j.get("worry", []) as Array)))
		"life":
			return fill(p, _next(p, "life", d["life"].get(p["class"], d["life"]["pleb"])))
		"news":
			return _next(p, "news", d["news"].get(p["age"], []))
		"gods":
			return _next(p, "gods", d["gods"].get(p["age"], []))
		"around":
			if near.is_empty():
				return "Around here? Houses, shops, people. It's Rome. Walk and look."
			if near.size() == 1:
				return "Just along there's %s. You can't miss it." % near[0]
			return "Just along there's %s, and past it %s. Ask anyone." % [near[0], near[1]]
		"bye":
			return str(_pick_by(p, d["reacts"]["bye"]))
	return str(_pick_by(p, d["reacts"]["puzzled"]))


static func _pick_by(p: Dictionary, list: Array) -> Variant:
	var k: int = p["said"].get("_pick", 0)
	p["said"]["_pick"] = k + 1
	return list[(absi(hash(p["id"])) + k) % list.size()]


## What you typed, as one of the topics (for when no one is on the line to Claude).
static func heard(text: String) -> String:
	var t := text.to_lower()
	var words := {
		"who": ["who", "name", "call you", "yourself"],
		"work": ["work", "job", "trade", "sell", "make", "do you do", "business", "price", "cost", "buy"],
		"life": ["life", "family", "wife", "husband", "child", "home", "live", "how are", "happy", "house"],
		"news": ["news", "happen", "heard", "rumour", "rumor", "senate", "emperor", "caesar", "war", "games"],
		"gods": ["god", "jupiter", "temple", "pray", "christ", "church", "sacrific", "religion"],
		"around": ["where", "around", "see", "way to", "near", "direction", "find", "temple of", "forum"],
		"bye": ["bye", "farewell", "vale", "goodbye", "see you"],
	}
	for topic: String in ["bye", "around", "who", "gods", "news", "work", "life"]:
		for w: String in words[topic]:
			if t.contains(w):
				return topic
	return ""


## Who Claude is to be for this citizen: the person, their time, and how to talk.
static func persona(p: Dictionary, when: String, near: Array) -> String:
	var j := job(p["job"])
	var family := "You live in the %s" % p["home"]
	if p["partner"] != "":
		family += " with your %s" % p["partner"]
	if p["kids"] > 0:
		family += " and %d children" % p["kids"]
	var who := "a %s (%s)" % [p["title"], p["latin"]]
	if p["origin"] != "Roman":
		who += ", from among the %s in Rome" % p["origin"]
	return """You are %s, %s, aged %d, in the city of Rome, %s. %s. You are %s today.
What you are like at your work: %s
How to talk:
- You are an ordinary person of your trade, not a scholar. Talk the way a %s in the street would: plain, lively, a bit of humour or complaint, about your own work, your family, prices, your neighbours, the gossip.
- One to three short sentences. First person. No lists, no formatting, no stage directions.
- You know only your own time and your own city. You have never heard of anything later. If asked about something you would not know, say so the way a person would.
- The one talking to you is a stranger, oddly dressed, with a strange accent. You may be curious, friendly, suspicious or busy, as suits you.
- Nearby just now: %s.
- Never say you are an AI or a character.""" % [p["name"], who, p["years"], when, family, p["mood"],
		" ".join((j.get("work", []) as Array).slice(0, 2)), p["title"], ", ".join(near) if not near.is_empty() else "houses and shops"]


## What they say out loud: "greet" as you come near, "bump" when you walk into them, "call" (a
## seller crying their wares), "night" (out after dark).
static func react(p: Dictionary, kind: String, rng: RandomNumberGenerator) -> String:
	var d := data()
	match kind:
		"bump":
			return str(_pick(rng, d["reacts"]["bump"]))
		"night":
			return str(_pick(rng, d["reacts"]["night"]))
		"call":
			return str(_pick(rng, job(p["job"]).get("call", [])))
	return str(_pick(rng, d["reacts"]["greet"].get(p["class"], ["Salve."])))
