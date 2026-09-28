extends "res://tests/test_base.gd"
## The city in speech (the Republic's game, sprint 5): founding, trials, the one-work rule, laws in
## the book's order, troubles answered, seasons passing, the stages from the bare site to the just
## city, and the fall regime by regime. The city keeps as a plain dictionary.

const City := preload("res://scripts/hall/city.gd")


## A careful founder: try everyone, give each the work their metal fits (a trade until the city has
## soldiers and rulers), pass the next law the book gives, answer each trouble the first way, and
## end the season. Returns the season the city became just (or -1).
static func _govern(city: RefCounted, seasons: int) -> int:
	var order := ["one_work", "luxuries", "war_for_land", "curriculum", "women_guardians", "noble_lie", "no_property",
		"censor_poets", "philosopher_kings", "common_families"]
	for s in seasons:
		for p in city.people:
			if not p["known"]:
				city.trial(p["id"])
		for p in city.adults():
			if not p["known"]:
				continue
			var want := "farmer"
			match str(p["metal"]):
				"gold":
					want = "ruler"
				"silver":
					want = "auxiliary"
				"bronze", "iron":  # enough bread first, then the other trades
					if city.food_made() < city.food_eaten() + 6 and p["role"] != "farmer":
						want = "farmer"
					elif p["role"] != "":
						want = p["role"]
					else:
						want = ["builder", "weaver", "cobbler", "smith", "herdsman", "farmer"][int(p["id"]) % 6]
			if city.assign(p["id"], want) != "":
				city.assign(p["id"], ["farmer", "builder", "weaver", "cobbler"][int(p["id"]) % 4])
		if city.stage == 2 and city.with_role("auxiliary").size() < 2:  # an army, even of the wrong metal, for now
			for p in city.adults():
				if p["sex"] == "m" and p["role"] != "auxiliary" and city.with_role("auxiliary").size() < 2:
					city.assign(p["id"], "auxiliary")
		for id in order:
			if city.cannot_pass(id) == "":
				city.pass_law(id)
				break
		if not city.event.is_empty():
			city.answer(0 if city.event.get("id", "") != "bodyguard" else 1)
		if city.stage >= City.JUST_CITY:
			return city.season
		city.end_season()
	return -1


func test_a_city_is_founded_on_the_bare_site() -> void:
	var city := City.found(7)
	check_eq(city.stage, 0, "the bare site")
	check_eq(city.people.size(), 10, "ten founders")
	check(city.people.all(func(p): return not p["known"]), "no one's metal is known yet")
	check(city.people.all(func(p): return (p["traits"] as Array).size() == 2), "each shows two traits")
	check_eq(city.justice(), 0, "no one has a work yet, so there is no justice yet")


func test_trials_reveal_metals_two_a_season() -> void:
	var city := City.found(7)
	check(city.trial(city.people[0]["id"]).contains(city.people[0]["metal"]), "a trial shows what someone is made of")
	city.trial(city.people[1]["id"])
	check_eq(city.trial(city.people[2]["id"]), "No more trials this season.", "two a season")
	city.end_season()
	check_eq(city.trials_left, City.TRIALS_A_SEASON, "and two more the next")


func test_laws_come_in_the_books_order() -> void:
	var city := City.found(7)
	check(city.cannot_pass("luxuries") != "", "no luxuries before there is a city")
	check(city.cannot_pass("philosopher_kings") != "", "no philosopher-kings on the bare site")
	var said: Dictionary = city.pass_law("one_work")
	check(said.get("socrates", "").contains("370"), "Socrates gives his reason, with where it is in the book")
	check(city.cannot_pass("luxuries") != "", "one law a season")
	check(city.assign(city.people[0]["id"], "ruler") != "", "no rulers before the city needs them")


func test_a_careful_founder_reaches_the_just_city() -> void:
	var city := City.found(11)
	var season := _govern(city, 120)
	check(season > 0, "the city becomes just (season %d, stage %d, justice %d, unity %d, food %d)" % [season, city.stage,
		city.justice(), city.meters["unity"], city.meters["food"]])
	check(city.justice() >= 80, "each doing their own work")
	check(not city.with_role("ruler").is_empty() and city.with_role("ruler").all(func(p): return p["metal"] == "gold"), "gold rules")
	var lines: Array = []
	for k in 4:
		lines.append(city.let_generations_pass())
	check_eq(city.stage, City.LAST_STAGE, "then the generations pass, and it falls to tyranny")
	check(lines[0].contains("timocracy") and lines[3].contains("tyranny"), "regime by regime")


func test_a_misfit_is_unjust_and_a_bodyguard_makes_a_tyrant() -> void:
	var city := City.found(3)
	city.pass_law("one_work")
	var gold: Array = city.people.filter(func(p): return p["metal"] == "gold")
	city.assign(gold[0]["id"], "cobbler")
	check(not City.fits(gold[0]), "gold at the cobbler's bench does not fit")
	city.event = {"id": "bodyguard", "title": "A champion asks for a bodyguard", "choices": [
		{"text": "Give him his guard", "effects": {"unity": 5, "tyrant": 1}, "socrates": "566b"}]}
	city.answer(0)
	city.end_season()
	check_eq(city.event.get("id", ""), "tyranny", "the bodyguard becomes an army")


func test_the_city_keeps_as_a_dictionary() -> void:
	var city := City.found(5)
	_govern(city, 6)
	var copy := City.from_dict(JSON.parse_string(JSON.stringify(city.to_dict())))
	check_eq(copy.stage, city.stage, "the stage")
	check_eq(copy.people.size(), city.people.size(), "the people")
	check_eq(copy.laws, city.laws, "the laws")
	check_eq(copy.justice(), city.justice(), "and so its justice")
	var a: Array = city.end_season()
	var b: Array = copy.end_season()
	check_eq(b, a, "and it goes on the same way")
