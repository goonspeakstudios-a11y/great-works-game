extends RefCounted
## The city in speech (Plato, Republic II-V and VIII): the Republic's political game, played a season
## at a time at the council table. You found a city with Socrates. Its people each have a hidden metal
## (gold, silver, bronze or iron: the story of the metals, 415a) and a few traits; trials reveal the
## metal. You give each person one work (a trade, the army, or rule), pass one law a season, answer the
## season's trouble (plague, the grain cut off, the neighbours' war, the rich against the poor, a plot
## of the few, a champion who wants a bodyguard, Persian gold), and end the season. The city grows by
## the book's stages, from the bare site to the just city, where each does their own work; after that
## the generations pass, the marriage number is missed, and it declines regime by regime (Book VIII).
## Everything is in this object and can be saved as a plain dictionary (progress "city").

const FILE := "res://content/greece/republic.json"
const METALS := ["gold", "silver", "bronze", "iron"]
const JUST_CITY := 5
const LAST_STAGE := 9
const TRIALS_A_SEASON := 2
const COMES_OF_AGE := 4  # seasons until a child can be given a work
## The traits a person may show, and which metal each tends to go with (a hint, not a rule).
const TRAITS := {"loves learning": "gold", "remembers what he learns": "gold", "gentle": "gold", "spirited": "silver",
	"brave": "silver", "loves honour": "silver", "hard-working": "bronze", "clever with his hands": "bronze",
	"fond of good things": "iron", "loves money": "iron"}

var season := 1
var stage := 0
var seed_value := 380
var people: Array = []  # {id, name, sex, age, metal, traits, known, role} (role: "", a trade, "auxiliary", "ruler")
var meters := {"food": 50, "land": 40, "luxury": 0, "gap": 10, "unity": 60}
var laws: Array = []
var event := {}  # this season's trouble, until it is answered
var trials_left := TRIALS_A_SEASON
var law_this_season := false
var tyrant := false
var next_id := 1
var log: Array = []  # what happened, newest last
var _rng := RandomNumberGenerator.new()
static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if d is Dictionary:
			_data = d
		else:
			push_error("Bad or missing %s" % FILE)
	return _data


## A new city on the bare site: ten founders, men and women, their metals unknown.
static func found(seed_given: int = 380) -> RefCounted:
	var c: RefCounted = load("res://scripts/hall/city.gd").new()
	c.seed_value = seed_given
	c._rng.seed = seed_given
	for metal in ["gold", "silver", "silver", "bronze", "bronze", "bronze", "iron", "iron", "gold", "bronze"]:
		c._add_person(metal, 20 + c._rng.randi_range(0, 20))
	c.log.append("You and Socrates walk out to the bare hillside. Ten people have come to found a city with you.")
	return c


# ---------- saving ----------

func to_dict() -> Dictionary:
	return {"season": season, "stage": stage, "seed": seed_value, "rng": _rng.state, "people": people, "meters": meters,
		"laws": laws, "event": event, "trials_left": trials_left, "law_this_season": law_this_season, "tyrant": tyrant,
		"next_id": next_id, "log": log.slice(maxi(0, log.size() - 40))}


static func from_dict(d: Dictionary) -> RefCounted:
	var c: RefCounted = load("res://scripts/hall/city.gd").new()
	c.season = int(d.get("season", 1))
	c.stage = int(d.get("stage", 0))
	c.seed_value = int(d.get("seed", 380))
	c._rng.seed = c.seed_value
	if d.has("rng"):
		c._rng.state = int(d["rng"])
	c.people = (d.get("people", []) as Array).duplicate(true)
	for p in c.people:  # JSON gives numbers back as floats
		p["id"] = int(p["id"])
		p["age"] = int(p["age"])
	var m: Dictionary = d.get("meters", {})
	for k in c.meters:
		c.meters[k] = int(m.get(k, c.meters[k]))
	c.laws = (d.get("laws", []) as Array).duplicate()
	c.event = (d.get("event", {}) as Dictionary).duplicate(true)
	c.trials_left = int(d.get("trials_left", TRIALS_A_SEASON))
	c.law_this_season = bool(d.get("law_this_season", false))
	c.tyrant = bool(d.get("tyrant", false))
	c.next_id = int(d.get("next_id", c.people.size() + 1))
	c.log = (d.get("log", []) as Array).duplicate()
	return c


# ---------- people ----------

func _add_person(metal: String, age: int, sex: String = "") -> Dictionary:
	var names: Dictionary = data().get("names", {"m": ["Demeas"], "f": ["Myrrhine"]})
	if sex == "":
		sex = "f" if _rng.randf() < 0.5 else "m"
	var pool: Array = names[sex]
	var taken := people.map(func(q): return q["name"])
	var name: String = pool[_rng.randi_range(0, pool.size() - 1)]
	for k in pool.size():  # a name not yet used, if there is one
		var n: String = pool[(pool.find(name) + k) % pool.size()]
		if not taken.has(n):
			name = n
			break
	var traits: Array = []
	var fitting: Array = TRAITS.keys().filter(func(t): return TRAITS[t] == metal)
	traits.append(fitting[_rng.randi_range(0, fitting.size() - 1)])
	var other: Array = TRAITS.keys().filter(func(t): return not traits.has(t))
	traits.append(other[_rng.randi_range(0, other.size() - 1)])  # a second trait that may mislead
	var p := {"id": next_id, "name": name, "sex": sex, "age": age, "metal": metal, "traits": traits, "known": false, "role": ""}
	next_id += 1
	people.append(p)
	return p


func person(id: int) -> Dictionary:
	for p in people:
		if int(p["id"]) == id:
			return p
	return {}


func adults() -> Array:
	return people.filter(func(p): return int(p["age"]) >= COMES_OF_AGE)


func with_role(role: String) -> Array:
	return people.filter(func(p): return p["role"] == role)


func producers() -> Array:
	var trades: Array = data()["trades"] + data()["luxury_trades"]
	return people.filter(func(p): return trades.has(p["role"]))


## Whether a person is doing the work their soul fits: gold rules, silver guards, bronze and iron make.
static func fits(p: Dictionary) -> bool:
	match str(p["role"]):
		"":
			return false
		"ruler":
			return p["metal"] == "gold"
		"auxiliary":
			return p["metal"] == "silver"
	return p["metal"] in ["bronze", "iron"]


## The works a person can be given now.
func roles_open() -> Array:
	var out: Array = data()["trades"].duplicate()
	if laws.has("luxuries"):
		out.append_array(data()["luxury_trades"])
	if stage >= 2 and laws.has("war_for_land"):
		out.append("auxiliary")
	if stage >= 3 and laws.has("curriculum"):
		out.append("ruler")
	return out


## Give someone a work ("" takes it away). Returns why not, or "".
func assign(id: int, role: String) -> String:
	var p := person(id)
	if p.is_empty():
		return "There is no one by that name."
	if int(p["age"]) < COMES_OF_AGE:
		return "%s is still a child." % p["name"]
	if role != "" and not roles_open().has(role):
		return "The city has no place for that work yet."
	if role in ["auxiliary", "ruler"] and p["sex"] == "f" and not laws.has("women_guardians"):
		return "The law does not yet let women guard or rule."
	p["role"] = role
	_check_stage()
	return ""


## A trial reveals what someone is made of, as gold is tried in the fire (413d-e). Two a season.
func trial(id: int) -> String:
	var p := person(id)
	if p.is_empty():
		return "There is no one by that name."
	if trials_left <= 0:
		return "No more trials this season."
	if p["known"]:
		return "You already know what %s is made of." % p["name"]
	trials_left -= 1
	p["known"] = true
	var line := "Tried in pleasure and fear, %s proves to be %s." % [p["name"], p["metal"]]
	log.append(line)
	return line


# ---------- the measures of the city ----------

## How far each person does the work their soul fits, of all who could work: 0 to 100.
func justice() -> int:
	var all := adults()
	if all.is_empty():
		return 0
	return int(round(100.0 * all.filter(func(p): return fits(p)).size() / all.size()))


## The city's strength in war: its soldiers, better for their training.
func defence() -> int:
	var soldiers := with_role("auxiliary")
	var strength := soldiers.size() * 10 + soldiers.filter(func(p): return p["metal"] == "silver").size() * 5
	return int(strength * (1.5 if laws.has("curriculum") else 1.0))


func food_made() -> int:
	return with_role("farmer").size() * 10 + with_role("herdsman").size() * 5


func food_eaten() -> int:
	return int(ceil(people.size() * 1.2 * (1.0 + meters["luxury"] / 200.0)))


func land_needed() -> int:
	return int(ceil(people.size() * 2.0 * (1.0 + meters["luxury"] / 100.0)))


func _bump(key: String, by: int) -> void:
	meters[key] = clampi(int(meters[key]) + by, 0, 100 if key != "land" else 400)


# ---------- laws ----------

func law(id: String) -> Dictionary:
	for l in data()["laws"]:
		if l["id"] == id:
			return l
	return {}


## Why a law cannot be passed now, or "".
func cannot_pass(id: String) -> String:
	var l := law(id)
	if l.is_empty():
		return "There is no such law."
	if laws.has(id):
		return "It is already the law."
	if stage < int(l["stage"]):
		return "The city is not ready for it."
	for need in l["requires"]:
		if not laws.has(need):
			return "It needs '%s' first." % law(need).get("name", need)
	if law_this_season:
		return "One law a season."
	if stage >= JUST_CITY + 1:
		return "The laws no longer hold."
	return ""


## Pass a law: its effects, and what Socrates (and his objector) say. Returns {"error"} or
## {"socrates", "objection"}.
func pass_law(id: String) -> Dictionary:
	var why := cannot_pass(id)
	if why != "":
		return {"error": why}
	var l := law(id)
	laws.append(id)
	law_this_season = true
	for k in l["effects"]:
		_bump(k, int(l["effects"][k]))
	log.append("Law: %s." % l["name"])
	_check_stage()
	return {"socrates": l["socrates"], "objection": l.get("objection", "")}


# ---------- the season's trouble ----------

## Draw this season's trouble from those that can happen now (none is forced to repeat soon).
func _draw_event() -> void:
	if stage >= JUST_CITY + 1:
		event = {}
		return
	if tyrant:
		event = {"id": "tyranny", "title": "The bodyguard has become an army",
			"text": "The champion you gave a guard to has disarmed the people and made himself master of the city.",
			"choices": [{"text": "Endure it", "effects": {"unity": -20, "gap": 20}, "socrates": "The people, fleeing the smoke of slavery to free men, have fallen into the fire of slavery to slaves (569b-c)."}]}
		return
	var recent: Array = log.slice(maxi(0, log.size() - 12))
	var pool: Array = data()["events"].filter(func(e):
		if stage < int(e["min"]) or stage > int(e["max"]):
			return false
		if e.has("not_laws") and (e["not_laws"] as Array).any(func(x): return laws.has(x)):
			return false
		if e.has("gap_at_least") and meters["gap"] < int(e["gap_at_least"]):
			return false
		if e.has("unity_below") and meters["unity"] >= int(e["unity_below"]):
			return false
		return not recent.has("Trouble: %s." % e["title"]))
	if pool.is_empty() or _rng.randf() < 0.25:
		event = {}  # a quiet season
		return
	event = (pool[_rng.randi_range(0, pool.size() - 1)] as Dictionary).duplicate(true)


## Answer the season's trouble with one of its choices. Returns what Socrates says.
func answer(choice: int) -> String:
	if event.is_empty():
		return ""
	var c: Dictionary = event["choices"][clampi(choice, 0, event["choices"].size() - 1)]
	var said: String = c.get("socrates", "")
	log.append("Trouble: %s." % event.get("title", ""))
	for k in c["effects"]:
		match str(k):
			"deaths":
				for n in int(c["effects"][k]):
					_die()
			"battle":
				said += " " + _battle()
			"tyrant":
				tyrant = true
			"law":
				var id: String = c["effects"][k]
				if not laws.has(id):
					laws.append(id)
					for m in law(id)["effects"]:
						_bump(m, int(law(id)["effects"][m]))
			_:
				_bump(k, int(c["effects"][k]))
	if event.get("id", "") == "tyranny":
		tyrant = false
	event = {}
	_check_stage()
	return said


func _battle() -> String:
	var threat := 20 + stage * 8 + _rng.randi_range(0, 20)
	if defence() >= threat:
		_bump("unity", 5)
		log.append("The soldiers held the city.")
		return "The soldiers held. (Your strength %d against their %d.)" % [defence(), threat]
	_bump("land", -15)
	_bump("unity", -10)
	_die()
	_die()
	log.append("The city lost the battle.")
	return "They broke through. Land lost and two dead. (Your strength %d against their %d.)" % [defence(), threat]


func _die() -> void:
	var grown := adults()
	if grown.is_empty():
		return
	var p: Dictionary = grown[_rng.randi_range(0, grown.size() - 1)]
	people.erase(p)
	log.append("%s died." % p["name"])


# ---------- the season ----------

## Why the season cannot end yet, or "".
func cannot_end() -> String:
	if not event.is_empty():
		return "First answer this season's trouble."
	return ""


## End the season: food, land, the gap between rich and poor, unity; the young grow up, children
## are born (mostly like their parents, 415a-c), newcomers arrive while the city is young; then the
## next season's trouble. Returns what happened.
func end_season() -> Array:
	var said: Array = []
	if cannot_end() != "":
		return [cannot_end()]
	season += 1
	trials_left = TRIALS_A_SEASON
	law_this_season = false
	_bump("food", food_made() - food_eaten())
	if meters["food"] <= 0:
		_die()
		_bump("unity", -5)
		said.append("There was not enough bread. Someone starved.")
	if land_needed() > meters["land"]:
		_bump("unity", -5)
		said.append("The city wants more land than it has.")
	_bump("gap", int(meters["luxury"] / 40) + (-2 if laws.has("no_property") else 1) + (-1 if laws.has("one_work") else 0))
	var misfits := adults().filter(func(p): return p["role"] != "" and not fits(p)).size()
	_bump("unity", -int(meters["gap"] / 20) - misfits + (3 if justice() >= 70 else 0) + (2 if laws.has("noble_lie") else 0)
		+ (2 if meters["food"] >= 30 else 0))
	for p in people:
		p["age"] = int(p["age"]) + 1
	if season % 2 == 0 and stage >= 1:
		said.append(_birth())
	if stage <= 3 and season % 3 == 0:
		var metal: String = METALS[_rng.randi_range(0, 3)]
		said.append("%s comes to live in the city." % _add_person(metal, 20)["name"])
	_check_stage()
	_draw_event()
	for s in said:
		log.append(s)
	return said


## A child, mostly like its parents; sometimes a gold child of bronze parents, or bronze of gold
## (415a-c). With marriage by lot, the best have the most children.
func _birth() -> String:
	var grown := adults()
	var parent: Dictionary = grown[_rng.randi_range(0, grown.size() - 1)] if not grown.is_empty() else {"metal": "bronze"}
	if laws.has("common_families") and _rng.randf() < 0.5:
		var best := grown.filter(func(p): return p["metal"] in ["gold", "silver"])
		if not best.is_empty():
			parent = best[_rng.randi_range(0, best.size() - 1)]
	var metal: String = parent["metal"]
	if _rng.randf() < 0.2:
		metal = METALS[_rng.randi_range(0, 3)]
	var child := _add_person(metal, 0)
	if metal != parent["metal"]:
		return "A child is born, %s. The seers say it is not made of its parents' metal." % child["name"]
	return "A child is born, %s." % child["name"]


# ---------- the stages ----------

func _check_stage() -> void:
	var before := stage
	while stage < JUST_CITY and _stage_done(stage):
		stage += 1
	if stage != before:
		log.append("The city becomes %s." % stage_name().to_lower())


func _stage_done(s: int) -> bool:
	match s:
		0:
			return laws.has("one_work") and ["farmer", "builder", "weaver", "cobbler"].all(func(t): return not with_role(t).is_empty())
		1:
			return laws.has("luxuries")
		2:
			return laws.has("war_for_land") and with_role("auxiliary").size() >= 2
		3:
			return ["curriculum", "noble_lie", "no_property"].all(func(l): return laws.has(l)) and with_role("ruler").size() >= 2
		4:
			return laws.has("philosopher_kings") and justice() >= 80 and meters["unity"] >= 50
	return false


func stage_name() -> String:
	return data()["stages"][stage]["name"]


func stage_goal() -> String:
	return data()["stages"][stage]["goal"]


## After the just city: a generation passes, the marriage number is missed (546a-d), and the city
## falls one regime lower. Returns what happened.
func let_generations_pass() -> String:
	if stage < JUST_CITY:
		return "The city is not yet just; there is nothing yet to lose."
	if stage >= LAST_STAGE:
		return "There is no lower to fall."
	stage += 1
	match stage:
		6:
			_bump("unity", -10)
			for p in with_role("ruler"):
				if p["metal"] != "gold":
					p["role"] = "auxiliary"
		7:
			_bump("gap", 40)
			_bump("unity", -15)
		8:
			for p in people:
				p["role"] = ""
			_bump("unity", -10)
		9:
			_bump("unity", -30)
			_bump("gap", 20)
	var line := "A generation passes. The city becomes %s." % stage_name().to_lower()
	log.append(line)
	return line


## Where the board of the city stands (Thinkers.city_in_speech's stage): the just city at most.
func board_stage() -> int:
	return mini(stage, JUST_CITY)
