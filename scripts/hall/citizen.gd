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
## A job as it is spoken of in an age: the heroes of 280 BC and the Republic of 201 BC have their
## own words for their work ("hero", "rise"); the later ages share the plainer ones.
static func _in_age(j: Dictionary, age: String) -> Dictionary:
	var key: String = {"heroic": "hero", "early": "rise"}.get(age, "")
	if key == "" or not j.has(key):
		return j
	var out := j.duplicate()
	out.merge(j[key], true)
	return out


## What each age believes of itself, for Claude playing its people: from the old virtues to their ruin.
const SPIRIT := {
	"heroic": "the age of heroes, Rome of 280 BC: a small, poor, cheerful city of farmer-soldiers. You are simple, good-humoured and utterly sure of Rome and its gods. You tell the old stories (Horatius at the bridge, Scaevola's hand in the fire, the Sabine women, Decius Mus riding to his death at Sentinum, Curius and his turnips, Fabricius and Pyrrhus's gold) as family memory. You admire the Greeks' cleverness and are not impressed by it. You speak warmly and plainly, with a farmer's humour.",
	"early": "the Republic of 201 BC, just after the victory over Hannibal. You sincerely hold the old Roman virtues: virtus (courage), pietas (duty to gods, family and Republic), fides (the word kept), gravitas, frugality, and service and sacrifice for the res publica. You are proud, pious and plain; grief and hardship are borne for Rome and not complained of. Luxury and Greek softness are suspect.",
	"republic": "the last generation of the Republic. The old virtues are praised in speeches and betrayed in practice: ambition, faction, money, gangs and generals' armies rule. You are shrewd, cynical or angry, and you know exactly who is buying whom.",
	"empire": "Rome at the height of the Empire. Peace, plenty and spectacle; the old virtues are statues in the Forum. Luxury, idleness, servility to the Emperor, informers and the arena. You are comfortable, careful and a little hollow.",
	"late": "the late Empire. A hard, taxed, regimented and frightened city; cruelty and corruption in office, the old gods forbidden, the new faith in power, trades bound by law. You are bitter, afraid or devout.",
	"collapse": "Rome in AD 455, just after the Vandals' sack. Absurd decadence and collapse: emperors murdered in months, barbarian generals choosing them, the Senate arguing precedence at the games while the grain from Africa is gone, relic sellers, charlatans, the rich in silk and the poor starving, betting on the next emperor's death. You are frantic, cynical, fatalistic or numb, and you laugh at the wrong things.",
	"fall": "the ruined city after twenty years of war, siege, famine and plague. Most of Rome is empty. You are numb, desperate, hungry, and you cling to the Church or to nothing.",
}

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
	if age == "collapse":
		age = "late"  # the same trades as the late Empire, gone to seed
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
	var late := age in ["late", "collapse", "fall"]
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
	var mood: Array = _pick(rng, data().get("moods_by_age", {}).get(age, data().get("moods", [["weary", ""]])))
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


## What they say when you first stop them: a greeting (the hour's or the weather's when `ctx`
## says what hour and weather it is, sometimes in Latin), their mood, and then, as the day and
## their standing allow, a word on the festival or the market, what they have heard of you, a
## grievance, a name dropped, with the verbal habit of their kind. `ctx`: {hour, raining, hot,
## festival, market, deeds: [what the ledger says of you]}.
static func greeting(p: Dictionary, ctx: Dictionary = {}) -> String:
	var v: Dictionary = data().get("voice", {})
	var hello: Array = data()["reacts"]["greet"].get(p["class"], ["Salve."])
	var h := absi(hash(p["id"]))
	var opener: String = hello[h % hello.size()]
	if not ctx.is_empty() and not v.is_empty():
		var by_hour := hour_line(v, ctx, h)
		if ctx.get("raining", false) and h % 3 != 0:
			opener = str(_at(v["weather"]["rain"], h))
		elif ctx.get("hot", false) and h % 4 == 0:
			opener = str(_at(v["weather"]["heat"], h))
		elif by_hour != "" and h % 5 < 2:
			opener = by_hour
		elif h % 7 == 0:
			opener = latin(p, "greet", h)
	var out := "%s %s" % [opener, p["mood_line"]]
	if v.is_empty():
		return out
	var said: Dictionary = p["said"]
	var fest := str(ctx.get("festival", ""))
	if fest != "" and not said.has("festival"):
		said["festival"] = 1
		out += " " + str(_at(v["festival"], h)).replace("{festival}", fest)
	elif ctx.get("market", false) and not said.has("market"):
		said["market"] = 1
		out += " " + str(_at(v["market"], h))
	var deeds: Array = ctx.get("deeds", [])
	if not deeds.is_empty() and not said.has("memory") and h % 2 == 0:
		said["memory"] = 1
		var deed := str(deeds[h % deeds.size()])
		out += " " + str(_at(v["memory"], h)).replace("{deed}", deed.substr(0, 1).to_lower() + deed.substr(1))
	elif h % 3 == 1 and not said.has("grievance"):
		said["grievance"] = 1
		out += " " + grievance(p, h)
	elif h % 3 == 2 and not said.has("drop"):
		said["drop"] = 1
		var drops: Array = v["drops"].get(p["age"], [])
		if not drops.is_empty():
			out += " %s, %s." % [str(_at(drops, h)), habit(p)]
	return out


static func _at(list: Array, h: int) -> Variant:
	return list[h % list.size()] if not list.is_empty() else ""


## The greeting the hour calls for, or "" when the hour is not given.
static func hour_line(v: Dictionary, ctx: Dictionary, h: int) -> String:
	if not ctx.has("hour"):
		return ""
	var hour := float(ctx["hour"])
	var when := "night"
	if hour >= 5.0 and hour < 7.5:
		when = "dawn"
	elif hour < 11.5:
		when = "morning"
	elif hour < 14.0:
		when = "noon"
	elif hour < 18.0:
		when = "afternoon"
	elif hour < 20.5:
		when = "evening"
	return str(_at(v["hours"].get(when, []), h))


## Their verbal habit: a regular's own, else their class's.
static func habit(p: Dictionary) -> String:
	if str(p.get("habit", "")) != "":
		return str(p["habit"])
	var habits: Array = data().get("voice", {}).get("habits", {}).get(p["class"], ["as they say"])
	return str(_at(habits, absi(hash(p["id"])) / 7))


## A grievance of their kind, with their habit on it now and then.
static func grievance(p: Dictionary, h: int) -> String:
	var list: Array = data().get("voice", {}).get("grievances", {}).get(p["class"], [])
	if list.is_empty():
		return ""
	var line := str(_at(list, h / 3))
	if h % 2 == 0:
		line = line.trim_suffix(".") + ", " + habit(p) + "."
	return line


## A Latin word of theirs: "greet", "bye" or "oath" (a woman's or a Christian's where it differs).
static func latin(p: Dictionary, kind: String, h: int) -> String:
	var l: Dictionary = data().get("voice", {}).get("latin", {})
	match kind:
		"greet":
			return str(_at(l.get("greet_f" if p.get("gender", "m") == "f" else "greet", ["Salve."]), h))
		"bye":
			return str(_at(l.get("bye", ["Vale."]), h))
		"oath":
			if p.get("class", "") == "church":
				return str(_at(l.get("christian_oaths", ["Christe!"]), h))
			return str(_at(l.get("oaths_f" if p.get("gender", "m") == "f" else "oaths", ["Mehercle!"]), h))
		"price":
			return str(_at(l.get("prices", ["two asses"]), h))
	return ""


## Their answer to one of the talk panel's topics. `near`: the names of what stands close by.
static func reply(p: Dictionary, topic: String, near: Array = []) -> String:
	var j := job(p["job"])
	j = _in_age(j, p["age"])
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
			var lives: Dictionary = d.get("life_" + p["age"], d["life"]) if p["age"] in ["heroic", "early"] else d["life"]
			return fill(p, _next(p, "life", lives.get(p["class"], lives["pleb"])))
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
			if absi(hash(p["id"])) % 3 == 0:
				return latin(p, "bye", absi(hash(p["id"])) / 3)
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
	j = _in_age(j, p["age"])
	var family := "You live in the %s" % p["home"]
	if p["partner"] != "":
		family += " with your %s" % p["partner"]
	if p["kids"] > 0:
		family += " and %d children" % p["kids"]
	var who := "a %s (%s)" % [p["title"], p["latin"]]
	if p["origin"] != "Roman":
		who += ", from among the %s in Rome" % p["origin"]
	var spirit: String = SPIRIT.get(p["age"], "")
	return """You are %s, %s, aged %d, in the city of Rome, %s. %s. You are %s today.
What you are like at your work: %s
The spirit of your age: %s
How to talk:
- You are an ordinary adult of your trade, not a scholar and not a comic character. Talk the way a %s in the street would: plainly, frankly, about your work, your family, your duties and troubles, your neighbours, the gossip and the politics as you see them, in the spirit of your age above. Life is hard and often short; you are used to it and do not dramatise it.
- You live with what your world takes for granted, as a person of your time would, without modern judgement and without cheerfulness put on for a stranger. Nothing sexually explicit, but you are not coy about how people live.
- One to three short sentences. First person. No lists, no formatting, no stage directions.
- You know only your own time and your own city. You have never heard of anything later. If asked about something you would not know, say so the way a person would.
- The one talking to you is a stranger, oddly dressed, with a strange accent. You may be curious, friendly, suspicious or busy, as suits you.
- Nearby just now: %s.
- Never say you are an AI or a character.""" % [p["name"], who, p["years"], when, family, p["mood"],
		" ".join((j.get("work", []) as Array).slice(0, 2)), spirit, p["title"], ", ".join(near) if not near.is_empty() else "houses and shops"]


## What they say out loud: "greet" as you come near, "bump" when you walk into them, "call" (a
## seller crying their wares), "night" (out after dark).
static func react(p: Dictionary, kind: String, rng: RandomNumberGenerator, ctx: Dictionary = {}) -> String:
	var d := data()
	var h := rng.randi()
	match kind:
		"bump":
			var line := str(_pick(rng, d["reacts"]["bump"]))
			return (latin(p, "oath", h) + " " + line) if h % 3 == 0 else line  # an oath first, now and then
		"night":
			return str(_pick(rng, d["reacts"]["night"]))
		"call":
			return str(_pick(rng, job(p["job"]).get("call", [])))
	if not ctx.is_empty() and d.has("voice"):  # the hour's or the weather's greeting, or a Latin one
		if ctx.get("raining", false) and h % 2 == 0:
			return str(_at(d["voice"]["weather"]["rain"], h))
		if h % 4 == 0:
			var line := hour_line(d["voice"], ctx, h)
			if line != "":
				return line
		if h % 5 == 0:
			return latin(p, "greet", h)
	return str(_pick(rng, d["reacts"]["greet"].get(p["class"], ["Salve."])))
