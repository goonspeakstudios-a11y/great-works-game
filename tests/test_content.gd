extends "res://tests/test_base.gd"

const Content := preload("res://scripts/content.gd")


func test_real_content_loads_and_is_valid() -> void:
	var c := Content.new()
	check(c.load_all(), "content loads")
	check_eq(c.works.size(), 11, "all 11 Greek works imported")
	check(c.ideas.size() >= 12, "region one has its ideas")
	for e in c.validate():
		failures.append(e)


func test_validator_catches_bad_idea() -> void:
	var c := Content.new()
	c.works = {"w": {}}
	c.regions = [{"id": "r", "ideas": [], "enemies": [], "boss": {"id": "b", "hp": 5, "intents": []}}]
	c.ideas = {"x": {"id": "x", "name": "Hubris", "clue": "Hubris is pride", "summary": "s",
		"source": "s", "work": "missing", "passage": "p", "cost": 5,
		"effects": [{"kind": "fly", "value": 0}]}}
	var errors := "\n".join(c.validate())
	for needle in ["needs at least", "no enemies", "no intents", "not in works.json",
			"cost must be", "unknown effect", "must be positive", "gives away the name"]:
		check(errors.contains(needle), "validator reports '%s'" % needle)
