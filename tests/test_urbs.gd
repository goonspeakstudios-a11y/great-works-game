extends "res://tests/test_base.gd"
## The city of Rome's activities (docs/rome-activities-plan.md): your standing, the scenes (rites,
## trades, games, choices) and their engine, the games at the table, your room, and the recurring
## rites in every age.

const Hall := preload("res://scripts/hall/hall.gd")
const Progress := preload("res://scripts/hall/progress.gd")
const Standing := preload("res://scripts/hall/urbs_standing.gd")
const Scene := preload("res://scripts/hall/urbs_scene.gd")
const Games := preload("res://scripts/hall/urbs_games.gd")
const Activities := preload("res://scripts/hall/urbs_activities.gd")
const AGES := ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]


## Plays a scene through: `pick` 0 takes the first choice each time, -1 the last, and so on; the
## rites and questions are answered rightly; bars are hit, holds held, games won (or lost).
static func autoplay(scene: RefCounted, pick: int = 0, win: bool = true) -> int:
	var guard := 0
	while not scene.done and guard < 400:
		guard += 1
		var v: Dictionary = scene.view()
		match str(v["kind"]):
			"say":
				scene.press()
			"ask":
				var on: Array = v["enabled"]
				var choices: Array = []
				for k in on.size():
					if on[k]:
						choices.append(k)
				if choices.is_empty():
					return -1
				scene.choose(choices[posmod(pick, choices.size())])
			"pick":
				scene.choose(int(scene.current().get("right", 0)))
			"rite":
				var order: Array = scene.current()["order"]
				var right: String = order[scene._rite_at]
				scene.choose(scene._rite_opts.find(right))
			"hold":
				scene.update(99.0, true)
			"still":
				scene.update(99.0, false)
			"timing":
				scene._bar = (scene._zone.x + scene._zone.y) / 2.0
				scene.press()
			"type":
				scene.typed(str(scene.current()["type"]))
			"play":
				scene.game_over(win, "")
			_:
				return -1
	return guard if scene.done else -1


static func fresh(age: String = "republic") -> RefCounted:
	var p: RefCounted = Progress.open("")
	p.data = {"works": {}}
	return Standing.open(p, age)


func test_standing_keeps_fides_coin_dignitas_and_the_ledger() -> void:
	var s := fresh("republic")
	check_eq(s.coin(), 12, "you arrive with a little money")
	check_eq(s.money(1), "1 sestertius", "counted in the age's coin")
	check_eq(s.money(3), "3 sestertii", "and its plural")
	check_eq(fresh("heroic").money(2), "2 asses", "asses in the age of heroes")
	check(s.price(4) > fresh("heroic").price(4), "prices rise with the ages")
	check(fresh("fall").price(10) / maxi(1, fresh("fall").wage(10)) > 1, "and faster than wages, by the end")
	var said: String = s.apply({"fides": 2, "coin": -5, "dignitas": 1})
	check(said.contains("+2 fides") and said.contains("-5 sestertii") and said.contains("+1 dignitas"), "what changed is said: %s" % said)
	check_eq(s.fides(), 2, "fides kept")
	check_eq(s.coin(), 7, "coin spent")
	s.apply({"fides": -100, "coin": -100})
	check_eq(s.fides(), Standing.FIDES[0], "fides has a floor")
	check_eq(s.coin(), 0, "you cannot owe the purse")
	s.apply({"ledger": "Sold your vote.", "ledger_key": "sold_vote"})
	s.apply({"ledger": "Sold your vote.", "ledger_key": "sold_vote"})
	check_eq((s.data()["ledger"] as Array).size(), 1, "the Ledger writes a thing once in each age")
	check(s.has({"not_done": "x"}) and not s.has({"done": "x"}), "things done once")
	s.apply({"give": "a loaf"})
	check(s.has({"has": "a loaf"}), "you carry what you are given")
	s.apply({"take": "a loaf"})
	check(not s.has({"has": "a loaf"}), "and hand it over")
	check(s.collect("coins", "republic") and not s.collect("coins", "republic"), "a set gains a piece once")
	check_eq(s.fill("It costs {price:2} in {coins}."), "It costs 4 sestertii in sestertii.", "prices written in the words")
	s.apply({"census": 0})
	check_eq(s.census_class(), 0, "an honest census of an empty purse: counted by head")


func test_the_standing_survives_a_save_and_a_reload() -> void:
	var path := "user://test_urbs_progress.json"
	var p: RefCounted = Progress.open("")
	p.path = path
	p.data = {"works": {}, "rome_age": 3, "rome_met": {"x": 2}}
	var s: RefCounted = Standing.open(p, "empire")
	s.apply({"fides": 5, "ledger": "Warned a man.", "ledger_key": "warned"})
	p.save()
	var back: RefCounted = Progress.open(path)
	check_eq(int(back.data.get("rome_age", -1)), 3, "the city's age is kept")
	check_eq(int(Standing.open(back, "empire").fides()), 5, "and your fides")
	check_eq((Standing.open(back, "empire").data()["ledger"] as Array).size(), 1, "and the Ledger")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_every_scene_is_sound_and_plays_to_its_end() -> void:
	var all: Dictionary = Scene.all()
	check(all.size() >= 150, "the city is full of things to do (%d scenes)" % all.size())
	for id: String in all:
		var def: Dictionary = Activities.filled(all[id], {"god": "Saturn", "temple": "the Temple of Saturn"})
		var bad: Array = Scene.problems(def)
		check(bad.is_empty(), "%s: %s" % [id, bad])
		for pick: int in [0, -1, 1]:
			for win: bool in [true, false]:
				var s := fresh(id.split("_")[-1] if AGES.has(id.split("_")[-1]) else "empire")
				s.apply({"coin": 500, "class": 3})
				var sc: RefCounted = Scene.new(def, id, s, 11)
				sc.start()
				check(autoplay(sc, pick, win) >= 0, "%s plays to its end (choice %d, %s)" % [id, pick, "won" if win else "lost"])
				check(not sc.lines.any(func(l: String) -> bool: return l.contains("{")), "%s says nothing unfilled" % id)


func test_the_recurring_rites_are_held_in_every_age() -> void:
	var rites: Dictionary = Activities.rites()
	for want: String in ["vote", "games", "funeral", "levy", "court", "bread", "sacrifice", "triumph", "saturnalia", "salutatio"]:
		check(rites.has(want), "the %s is a recurring rite" % want)
		for age: String in AGES:
			check(not Activities.scene_def(want, age).is_empty(), "%s in %s" % [want, age])
			check(Activities.scene_id(want, age) == want + "_" + age, "%s has its own scene in %s" % [want, age])
	var early := fresh("early")
	var vote: RefCounted = Scene.new(Activities.scene_def("vote", "early"), "vote_early", early, 3)
	vote.start()
	autoplay(vote)
	check(vote.lines.any(func(l: String) -> bool: return l.contains("not called at all")), "the poor are not called to vote in 200 BC")
	var rich := fresh("early")
	rich.apply({"class": 5})
	var vote2: RefCounted = Scene.new(Activities.scene_def("vote", "early"), "vote_early", rich, 3)
	vote2.start()
	autoplay(vote2)
	check(vote2.lines.any(func(l: String) -> bool: return l.contains("Uti rogas")), "the first class votes aloud")
	var bought := fresh("republic")
	var sold: RefCounted = Scene.new(Activities.scene_def("vote", "republic"), "vote_republic", bought, 3)
	sold.start()
	autoplay(sold, 0)
	check((bought.data()["ledger"] as Array).any(func(e: Dictionary) -> bool: return e["key"] == "sold_vote"), "selling your vote goes in the Ledger")
	check(bought.coin() > 12, "and pays")


func test_a_rite_done_wrong_begins_again_while_the_gods_are_listened_to() -> void:
	var heroic := fresh("heroic")
	var sc: RefCounted = Scene.new(Activities.scene_def("sacrifice", "heroic"), "sacrifice_heroic", heroic, 5)
	sc.start()
	while sc.kind() != "rite":
		sc.press()
	var order: Array = sc.current()["order"]
	sc.choose(sc._rite_opts.find(order[0]))
	check_eq(sc._rite_at, 1, "the first act done")
	var wrong := -1
	for k in sc._rite_opts.size():
		if sc._rite_opts[k] != order[1]:
			wrong = k
	sc.choose(wrong)
	check_eq(sc._rite_at, 0, "a slip, and it begins again from the first act")
	check_eq(sc.restarts, 1, "counted")
	var late := fresh("republic")
	var sc2: RefCounted = Scene.new(Activities.scene_def("sacrifice", "republic"), "sacrifice_republic", late, 5)
	sc2.start()
	while sc2.kind() != "rite":
		sc2.press()
	var order2: Array = sc2.current()["order"]
	var wrong2 := -1
	for k in sc2._rite_opts.size():
		if sc2._rite_opts[k] != order2[0]:
			wrong2 = k
	sc2.choose(wrong2)
	check_eq(sc2._rite_at, 1, "by 50 BC a slip is waved on")


func test_the_games_at_the_table_keep_their_rules() -> void:
	check_eq(Games.Tali.name_of([6, 1, 4, 3]), "venus", "the Venus: all four sides different")
	check_eq(Games.Tali.name_of([1, 1, 1, 1]), "dog", "the Dog: all ones")
	check(Games.Tali.worth([1, 3, 4, 6]) > Games.Tali.worth([6, 6, 6, 4]), "the Venus beats any sum")
	var t := Games.Tali.new(4)
	var n := 0
	while not t.over and n < 100:
		t.throw(false)
		n += 1
	check(t.over and (t.rounds[0] == 3 or t.rounds[1] == 3), "knucklebones to three rounds")
	var cheat := Games.Tali.new(9)
	for k in 40:
		if cheat.over:
			break
		cheat.throw(true)
	check(cheat.caught or cheat.over, "loaded bones are found out, sooner or later")

	var tern := Games.Terni.new(1)
	check(tern.play(-1, 0) and tern.play(-1, 4) and tern.play(-1, 1), "stones are put down in turn")
	check_eq(tern.their_move(), [-1, 2], "the city blocks your row")
	var won := Games.Terni.new(1)
	won.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
	won.placed = [2, 2]
	won.turn = 1
	won.play(-1, 2)
	check(won.over and won.winner == 1, "three in a row wins")

	var l := Games.Latrunculi.new(1)
	var N: int = Games.Latrunculi.N
	l.board.fill(0)
	l.board[3 * N + 3] = 2
	l.board[3 * N + 2] = 1
	l.board[5 * N + 4] = 1
	l.board[0] = 2
	l.board[N * N - 1] = 1
	l.board[1] = 2
	check(l.play([5 * N + 4, 3 * N + 4]), "a soldier moves straight")
	check_eq(l.board[3 * N + 3], 0, "the enemy shut in between two is taken")
	check_eq(l.taken[0], 1, "and counted")
	var ai := Games.Latrunculi.new(3)
	ai.turn = 2
	check(not ai.their_move().is_empty(), "the city finds a move")

	var d := Games.Duodecim.new(2)
	d.men = [[10, 0, 0, 0, 0], [0, 0, 0, 0, 13]]
	d.dice = [3]
	check(d.move(0, 0, 0), "a man moves by a die")
	check_eq(d.men[1][4], 0, "a lone man hit goes back to the start")
	d.men = [[35, 37, 37, 37, 37], [0, 0, 0, 0, 0]]
	d.dice = [2]
	check(d.can_move(0, 0, 2), "from the last row a man is borne off")
	d.move(0, 0, 0)
	check(d.over and d.winner == 0, "all five home wins")
	d.men = [[20, 1, 1, 1, 1], [22, 22, 0, 0, 0]]
	check(not d.can_move(0, 0, 2), "two men hold a point against you")
	var play := Games.Duodecim.new(5)
	play.roll()
	var steps := 0
	while not play.over and steps < 3000:
		steps += 1
		if play.turn_done():
			play.next_turn()
			continue
		if play.turn == 1:
			play.their_step()
		else:
			var o: Array = play.options(0)
			play.move(0, o[0][0], o[0][1])
	check(play.over, "a whole game of twelve lines ends (%d moves)" % steps)

	var h := Games.Haggle.new(true, 10, 0, 3)
	check(h.ask > h.limit, "the seller asks more than he'll take")
	var rounds := 0
	while not h.over and rounds < 20:
		rounds += 1
		h.offer(h.limit)
	check(h.over and h.price == h.limit, "an offer at his limit is taken")
	var trusted := Games.Haggle.new(true, 100, 20, 8)
	var cheat_h := Games.Haggle.new(true, 100, -20, 8)
	check(trusted.limit < cheat_h.limit, "a trusted man is given a better price")

	var ch := Games.Changer.new("empire", 5)
	check_eq(ch.coins.size(), 6, "six coins on the tray")
	for k in 6:
		ch.cut(k)
		ch.judge(k, ch.coins[k]["good"])
	var r: Dictionary = ch.reckon()
	check_eq(int(r["right"]), 6, "cut open, every coin is known")
	check(int(r["spoiled"]) > 0, "but the good ones cut are spoiled")
	check(Games.Changer.new("republic", 1).fineness.contains("pure"), "the Republic's silver")
	check(Games.Changer.new("late", 1).fineness.contains("copper"), "and the late Empire's copper")

	var race := Games.Race.new(false, 2, 7)
	for k in 5000:
		if race.over:
			break
		race.step(0.05)
	check(race.over and race.order.size() >= 1, "a race is run to its end")
	var mad := Games.Race.new(true, 3, 7)
	for k in 4000:
		if mad.over:
			break
		mad.step(0.05, 1.0 if k % 40 < 20 else -1.0, true)
		if mad.cars[0]["crashed"]:
			break
	check(mad.cars[0]["crashed"] or mad.over, "whipping into every turn ends in a wreck, or at least the end")


func test_your_room_and_the_rites_are_in_the_city() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}, "rome_hour": 7.0, "rome_day": 2}
	hall.travel("urbs")
	check(hall.world.find_child("YourRoom", true, false) != null, "your room is built in the Subura")
	var acts: Array = hall.interactables.filter(func(i): return i["kind"] == "activity")
	check(acts.size() >= 20, "things to do all over the city (%d)" % acts.size())
	var lar: Array = acts.filter(func(i): return str(i["scene"]).begins_with("lararium"))
	check(lar.size() == 1, "the household gods in your room")
	hall.activate(lar[0])
	check(hall._activity.visible, "the rite opens in the activity panel")
	check(autoplay(hall._activity.scene) >= 0, "and is done")
	hall._close_panels()
	check(not hall._activity.visible, "and closes")
	check(hall.standing().has({"done": "lararium"}), "the house is kept")
	var chest: Array = hall.interactables.filter(func(i): return i["kind"] == "chest")
	check(chest.size() == 1, "a chest")
	for rite: String in ["vote", "games", "funeral", "levy", "court", "bread", "sacrifice", "triumph", "saturnalia", "salutatio"]:
		check(acts.any(func(i): return i.get("rite", "") == rite), "the %s has its place in the city" % rite)
	var offerings: Array = acts.filter(func(i): return i["scene"] == "offering")
	check(offerings.size() >= 5, "offerings at the temples (%d)" % offerings.size())
	hall.activate(offerings[0])
	check(hall._activity.scene.title == "An offering" and not hall._activity.scene.lines[0].contains("{"), "an offering names its god")
	hall._close_panels()
	var sleep: Dictionary = acts.filter(func(i): return str(i["scene"]).begins_with("sleep"))[0]
	var day_before: int = hall.life.town.day
	hall.life.hour = 22.0
	hall.activate(sleep)
	autoplay(hall._activity.scene)
	hall._close_panels()
	check_eq(hall.life.hour, 6.0, "you sleep till dawn")
	check_eq(hall.life.town.day, day_before + 1, "and it is the next day")
	var triumph: Dictionary = acts.filter(func(i): return i.get("rite", "") == "triumph")[0]
	hall.life.hour = 7.0
	hall.activate(triumph)
	check_eq(hall._activity.scene.id, "wait", "a rite not held now offers to wait for it")
	autoplay(hall._activity.scene, 0)
	hall._close_panels()
	check(hall._activity.visible and str(hall._activity.scene.id).begins_with("triumph"), "and when you've waited, it begins")
	check(Activities.on_now(triumph["when"], hall.life.town.day, hall.life.hour), "at its hour")
	autoplay(hall._activity.scene)
	hall._close_panels()
	check((hall.standing().data()["rites"] as Dictionary).has("triumph"), "the rite is remembered for the frieze")
	check(hall._tablet_text().contains("Fides"), "the tablet shows your standing")
	hall.free()


func test_the_people_of_the_city_have_work_and_wares() -> void:
	for job: String in Activities.jobs():
		var j: Array = Activities.jobs()[job]
		check(not Activities.scene_def(str(j[1]), "empire").is_empty() or not Activities.scene_def(str(j[1]), "republic").is_empty(),
			"%s has something to do" % job)
	check_eq(Activities.job_action("pistor", "heroic").get("scene", ""), "work_baker", "the baker offers work")
	check(Activities.scene_def("work_baker", "fall")["steps"][0]["say"].contains("no flour"), "until there is no flour")
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}, "rome_reached": 3, "rome_age": 3, "rome_hour": 10.0}
	hall.travel("urbs")
	var seller: Array = hall.interactables.filter(func(i): return i["kind"] == "citizen" and not Activities.job_action(str(i["citizen"]["job"]), "empire").is_empty())
	check(not seller.is_empty(), "people with work and wares are about")
	hall.activate(seller[0])
	check(hall._talk_panel._action.visible, "the talk offers what they have")
	hall._on_said("act", "")
	check(hall._activity.visible and not hall._talk_panel.visible, "and it opens as a scene")
	check(autoplay(hall._activity.scene) >= 0, "which plays through")
	hall._close_panels()
	hall.free()


func test_the_calendar_says_when_things_are_on() -> void:
	var w := {"every": 3, "offset": 1, "from": 9.0, "to": 13.0}
	check(Activities.on_now(w, 4, 10.0), "on its day at its hour")
	check(not Activities.on_now(w, 4, 14.0), "not after")
	check(not Activities.on_now(w, 5, 10.0), "not on other days")
	check_eq(Activities.next_on(w, 5, 10.0), [2, 9.0], "next time: two days on, at nine")
	check_eq(Activities.next_on(w, 4, 7.0), [0, 9.0], "later today")
	check(Activities.in_hours(23.0, 20.5, 4.5) and Activities.in_hours(2.0, 20.5, 4.5) and not Activities.in_hours(12.0, 20.5, 4.5), "the night wraps past midnight")
	check(not Activities.today("republic", 2, 8.0).is_empty(), "the tablet lists what's on")
