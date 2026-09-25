extends "res://tests/test_base.gd"
## Module 1 guided stories. Each stage runs start to finish in auto mode (every line,
## choice and walk resolves at once), so these tests play the whole module.

const Content := preload("res://scripts/content.gd")
const Main := preload("res://scripts/pixel/pixel_main.gd")
const S1 := preload("res://scripts/pixel/stages/s1_isagoge.gd")
const S2 := preload("res://scripts/pixel/stages/s2_categories.gd")
const S3 := preload("res://scripts/pixel/stages/s3_organon.gd")
const S4 := preload("res://scripts/pixel/stages/s4_herennium.gd")
const S5 := preload("res://scripts/pixel/stages/s5_euclid.gd")


func _play(script: GDScript, pick: Callable = Callable()) -> Node:
	var s: Node = script.new()
	s.auto = true
	if pick.is_valid():
		s.auto_pick = pick
	(Engine.get_main_loop() as SceneTree).root.add_child(s)
	return s


func _done(s: Node, name: String) -> void:
	check_eq(s.phase, "done", "%s plays to the end" % name)
	check(s.said.size() > 10, "%s has a story" % name)
	for line in s.said:
		check(str(line).length() <= 100, "%s line is short: %s" % [name, line])
	s.free()


func test_stages_follow_the_reading_list() -> void:
	var c := Content.new()
	check(c.load_all(), "content loads")
	var ids: Array = Main.STAGES.map(func(st): return st["script"].WORK_ID)
	check_eq(ids, c.work_order.slice(0, 5), "module 1 plays the list's first five works in order")


func test_isagoge_finds_plato_by_the_good_questions() -> void:
	var s := _play(S1)
	check_eq(s.standing(), ["plato"], "only Plato is left standing")
	check(s.picks.has("Is it alive?") and s.picks.has("Can it think and speak?"), "asked the family questions")
	check(s.said.any(func(l): return str(l).contains("genus")), "genus is named")
	check(s.said.any(func(l): return str(l).contains("accidents")), "accidents are named")
	_done(s, "Isagoge")


func test_isagoge_side_questions_still_finish() -> void:
	var s := _play(S1, func(options: Array) -> int: return options.size() - 1)
	check_eq(s.standing(), ["plato"], "the side questions still end on Plato")
	check(s.picks.has("Is it big?"), "the side question was asked")
	_done(s, "Isagoge (side questions)")


func test_categories_fills_all_ten() -> void:
	var s := _play(S2)
	check_eq(s.report.size(), 10, "the report has all ten answers")
	check(s.said.any(func(l): return str(l).contains("substance")), "substance is named")
	_done(s, "Categories")


func test_organon_coins_follow_your_choices() -> void:
	var s := _play(S3)
	check_eq(s.coins, 0, "buying everything costs all ten coins")
	_done(s, "Organon (buy)")
	var careful := _play(S3, func(options: Array) -> int: return options.size() - 1)
	check_eq(careful.coins, 10, "calling out every trick keeps all ten")
	check(careful.said.any(func(l): return str(l).contains("syllogism")), "the syllogism is named")
	_done(careful, "Organon (careful)")


func test_herennium_places_and_recalls_five_pictures() -> void:
	var s := _play(S4)
	check_eq(s.placed, 5, "five pictures placed")
	check_eq(s.recalled, 5, "five pictures recalled in court")
	check(s.said.has("Gaius is free to go."), "Gaius goes free")
	_done(s, "Herennium")


func test_euclid_builds_the_triangle_and_fills_the_square() -> void:
	var s := _play(S5)
	check(s.squares and is_equal_approx(s.fill, 1.0), "the squares were filled")
	var c: Vector2 = s._c()
	check(is_equal_approx(c.distance_to(S5.A), S5.A.distance_to(S5.B)), "C is as far from A as B is")
	check(is_equal_approx(c.distance_to(S5.B), S5.A.distance_to(S5.B)), "C is as far from B as A is")
	_done(s, "Euclid")
