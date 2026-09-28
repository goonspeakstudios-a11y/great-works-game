extends RefCounted
## You in Rome, as the city knows you (docs/rome-activities-plan.md, section 1), kept in the save
## under "rome_standing":
##   fides     your word, as the city knows it (-20 to 20): kept promises, honest dealing
##   coin      your purse, counted in the age's own coin (asses, sestertii, folles, nummi)
##   dignitas  your standing (0 to 20): offices, a patron's favour, the census
##   class     the census class you are enrolled in (0, counted by head, to 6, the knights)
##   ledger    what you did when virtue cost something: [{age, key, text}], never scored
##   goods     what you carry: {thing: count}
##   collected the sets you are gathering: {set: [ids]} (the exempla, the coins, the masks...)
##   rites     the recurring rites you have played: {rite: [ages]} (the Nexus's frieze)
##   done      small things done once: {key: true}
##   quests    how far you are in the regulars' stories: {quest: step} (urbs_quests.gd)
##
## Prices and wages are written against the first age's coin and grow with the ages, prices
## faster than wages: the same purse buys less and less as the city falls.

const AGES := ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]
## The everyday coin of each age: [one, many].
const COINS := {"heroic": ["as", "asses"], "early": ["as", "asses"], "republic": ["sestertius", "sestertii"],
	"empire": ["sestertius", "sestertii"], "late": ["follis", "folles"], "collapse": ["nummus", "nummi"],
	"fall": ["nummus", "nummi"]}
## How many of the age's coins a thing costs, for each one it cost in 280 BC.
const PRICE := {"heroic": 1.0, "early": 1.0, "republic": 2.0, "empire": 3.0, "late": 12.0, "collapse": 30.0, "fall": 60.0}
## How many of the age's coins a day's work pays, for each one it paid in 280 BC.
const WAGE := {"heroic": 1.0, "early": 1.0, "republic": 2.0, "empire": 3.0, "late": 8.0, "collapse": 15.0, "fall": 20.0}
## The census classes, from the poorest (counted by head) to the knights.
const CLASSES := ["counted by head (capite censi)", "the fifth class", "the fourth class", "the third class",
	"the second class", "the first class", "the equestrian order"]
## What a purse must hold (as in 280 BC's coin) for each census class above the lowest.
const CENSUS := [20, 50, 100, 200, 400, 1000]
const FIDES := [-20, 20]
const DIGNITAS := [0, 20]
const START := {"fides": 0, "coin": 12, "dignitas": 0, "class": 0, "ledger": [], "goods": {}, "collected": {}, "rites": {},
	"done": {}, "quests": {}}

var progress: RefCounted
var age := "heroic"


static func open(the_progress: RefCounted, the_age: String) -> RefCounted:
	var s: RefCounted = load("res://scripts/hall/urbs_standing.gd").new()
	s.progress = the_progress
	s.age = the_age if AGES.has(the_age) else "heroic"
	return s


## The kept record, filled in with defaults where a save lacks them (or holds something wrong).
func data() -> Dictionary:
	var d: Variant = progress.data.get("rome_standing")
	if not d is Dictionary:
		d = {}
		progress.data["rome_standing"] = d
	for k: String in START:
		var want: Variant = START[k]
		if not d.has(k) or typeof(d[k]) != typeof(want) and not (want is int and d[k] is float):
			d[k] = want.duplicate(true) if (want is Array or want is Dictionary) else want
	return d


func fides() -> int:
	return int(data()["fides"])


func coin() -> int:
	return int(data()["coin"])


func dignitas() -> int:
	return int(data()["dignitas"])


func census_class() -> int:
	return clampi(int(data()["class"]), 0, CLASSES.size() - 1)


## The class your purse puts you in, declared honestly.
func honest_class() -> int:
	var k := 0
	for need: int in CENSUS:
		if coin() >= price(need):
			k += 1
	return k


## "1 as", "3 sestertii".
func money(n: int) -> String:
	var c: Array = COINS[age]
	return "%d %s" % [n, c[0] if n == 1 else c[1]]


## A price written in 280 BC's coin, in this age's.
func price(base: int) -> int:
	return maxi(1, roundi(base * float(PRICE[age])))


## A day's pay written in 280 BC's coin, in this age's.
func wage(base: int) -> int:
	return maxi(0, roundi(base * float(WAGE[age])))


## Words with the age's money in them: {coin}, {coins}, and {price:N} (N as in 280 BC).
func fill(text: String) -> String:
	var c: Array = COINS[age]
	text = text.replace("{coins}", str(c[1])).replace("{coin}", str(c[0]))
	var at := text.find("{price:")
	while at >= 0:
		var close := text.find("}", at)
		if close < 0:
			break
		var n := int(text.substr(at + 7, close - at - 7))
		text = text.left(at) + money(price(n)) + text.substr(close + 1)
		at = text.find("{price:")
	return text


## Something done: {fides, coin, dignitas, class, census (declared: 0 honest, 1 more, -1 less),
## pay (a price as in 280 BC, taken from your purse),
## earn (a wage as in 280 BC), ledger (text) with ledger_key, give/take (a thing), collect [set, id],
## once (a key)}. Returns what changed, in a few words ("" if nothing did).
func apply(fx: Dictionary) -> String:
	var d := data()
	var said: Array = []
	var coin_before := int(d["coin"])
	if fx.has("fides"):
		var f := int(fx["fides"])
		d["fides"] = clampi(int(d["fides"]) + f, FIDES[0], FIDES[1])
		if f != 0:
			said.append("%s%d fides" % ["+" if f > 0 else "", f])
	if fx.has("dignitas"):
		var g := int(fx["dignitas"])
		d["dignitas"] = clampi(int(d["dignitas"]) + g, DIGNITAS[0], DIGNITAS[1])
		if g != 0:
			said.append("%s%d dignitas" % ["+" if g > 0 else "", g])
	if fx.has("class"):
		d["class"] = clampi(int(fx["class"]), 0, CLASSES.size() - 1)
		said.append("enrolled in %s" % CLASSES[int(d["class"])])
	if fx.has("census"):  # declared to the censors: honestly (0), or a class more (1) or less (-1)
		d["class"] = clampi(honest_class() + int(fx["census"]), 0, CLASSES.size() - 1)
		said.append("enrolled in %s" % CLASSES[int(d["class"])])
	if fx.has("coin"):
		d["coin"] = maxi(0, int(d["coin"]) + int(fx["coin"]))
	if fx.has("pay"):
		d["coin"] = maxi(0, int(d["coin"]) - price(int(fx["pay"])))
	if fx.has("earn"):
		d["coin"] = int(d["coin"]) + wage(int(fx["earn"]))
	var moved := int(d["coin"]) - coin_before
	if moved != 0:
		said.append("%s%s" % ["+" if moved > 0 else "-", money(absi(moved))])
	if fx.has("give"):
		var goods: Dictionary = d["goods"]
		goods[str(fx["give"])] = int(goods.get(str(fx["give"]), 0)) + 1
		said.append("you have %s" % fx["give"])
	if fx.has("take"):
		var goods: Dictionary = d["goods"]
		var t := str(fx["take"])
		if int(goods.get(t, 0)) > 0:
			goods[t] = int(goods[t]) - 1
			if int(goods[t]) == 0:
				goods.erase(t)
			said.append("you hand over %s" % t)
	if fx.has("ledger"):
		ledger(str(fx.get("ledger_key", fx["ledger"])), str(fx["ledger"]))
	if fx.has("collect"):
		var pair: Array = fx["collect"]
		if collect(str(pair[0]), str(pair[1])):
			said.append("remembered")
	if fx.has("once"):
		(d["done"] as Dictionary)[str(fx["once"])] = true
	return ", ".join(said)


## Whether a condition holds: {fides, coin, dignitas, class (each: at least), price (can pay, as
## in 280 BC), below_fides, has (a thing), done (a key), not_done, age: [ages]}.
func has(cond: Dictionary) -> bool:
	var d := data()
	if cond.has("fides") and int(d["fides"]) < int(cond["fides"]):
		return false
	if cond.has("below_fides") and int(d["fides"]) >= int(cond["below_fides"]):
		return false
	if cond.has("coin") and int(d["coin"]) < int(cond["coin"]):
		return false
	if cond.has("price") and int(d["coin"]) < price(int(cond["price"])):
		return false
	if cond.has("dignitas") and int(d["dignitas"]) < int(cond["dignitas"]):
		return false
	if cond.has("class") and census_class() < int(cond["class"]):
		return false
	if cond.has("has") and int((d["goods"] as Dictionary).get(str(cond["has"]), 0)) <= 0:
		return false
	if cond.has("done") and not (d["done"] as Dictionary).has(str(cond["done"])):
		return false
	if cond.has("not_done") and (d["done"] as Dictionary).has(str(cond["not_done"])):
		return false
	if cond.has("age") and not (cond["age"] as Array).has(age):
		return false
	return true


## Writes a choice into the Ledger, once for each thing in each age.
func ledger(key: String, text: String) -> void:
	var list: Array = data()["ledger"]
	for e: Dictionary in list:
		if e["key"] == key and e["age"] == age:
			return
	list.append({"age": age, "key": key, "text": text})


## Adds to a collection; true if it was new.
func collect(set: String, id: String) -> bool:
	var sets: Dictionary = data()["collected"]
	if not sets.has(set):
		sets[set] = []
	if (sets[set] as Array).has(id):
		return false
	(sets[set] as Array).append(id)
	return true


func collected(set: String) -> Array:
	return (data()["collected"] as Dictionary).get(set, [])


## A recurring rite played in this age (for the frieze).
func played(rite: String) -> void:
	var rites: Dictionary = data()["rites"]
	if not rites.has(rite):
		rites[rite] = []
	if not (rites[rite] as Array).has(age):
		(rites[rite] as Array).append(age)


func goods() -> Dictionary:
	return data()["goods"]


## What people make of your fides: how they greet you.
func name_for() -> String:
	var f := fides()
	if f >= 12:
		return "a man of his word, known for it"
	if f >= 5:
		return "trusted"
	if f > -5:
		return "a stranger"
	if f > -12:
		return "not to be trusted"
	return "a known cheat"


## The tablet's page on you.
func summary() -> String:
	var d := data()
	var lines: Array = ["[color=#e0b660]Yourself[/color]",
		"Fides: %d (%s)" % [fides(), name_for()],
		"Purse: %s" % money(coin()),
		"Dignitas: %d" % dignitas(),
		"Census: %s" % CLASSES[census_class()]]
	var things: Array = []
	for g: String in d["goods"]:
		things.append("%s x%d" % [g, int(d["goods"][g])] if int(d["goods"][g]) > 1 else g)
	if not things.is_empty():
		lines.append("You carry: %s" % ", ".join(things))
	return "\n".join(lines)


## What Rome has brought back to the Nexus, read from the save without changing it: the sets
## completed (content/rome/collections.json), the Ledger, the rites played in all seven ages (the
## frieze), and whether Rome is complete (every set, every rite in every age).
static func nexus_state(the_progress: RefCounted) -> Dictionary:
	var d: Variant = the_progress.data.get("rome_standing") if the_progress else null
	if not d is Dictionary:
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/collections.json"))
	var sets: Dictionary = (parsed as Dictionary).get("sets", {}) if parsed is Dictionary else {}
	var have: Dictionary = (d as Dictionary).get("collected", {})
	var done: Array = []
	for k: String in sets:
		var got: Array = have.get(k, [])
		if (sets[k]["ids"] as Array).all(func(id: String) -> bool: return got.has(id)):
			done.append(k)
	var rites: Dictionary = (d as Dictionary).get("rites", {})
	var frieze: Array = []
	for r: String in rites:
		if (rites[r] as Array).size() >= AGES.size():
			frieze.append(r)
	var all_rites: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/rites.json"))
	var rite_count: int = ((all_rites as Dictionary).get("rites", {}) as Dictionary).size() if all_rites is Dictionary else 10
	return {"sets": done, "ledger": (d as Dictionary).get("ledger", []), "frieze": frieze, "rites": rites,
		"complete": done.size() == sets.size() and not sets.is_empty() and frieze.size() >= rite_count, "all_sets": sets}
