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
	check(hall.world.find_child("YourHouse", true, false) != null, "your house is built in the Subura")
	var acts: Array = hall.interactables.filter(func(i): return i["kind"] == "activity")
	check(acts.size() >= 20, "things to do all over the city (%d)" % acts.size())
	var lar: Array = acts.filter(func(i): return str(i["scene"]).begins_with("lararium"))
	check(lar.size() == 1, "the household gods in your house")
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


func test_the_regulars_have_their_stories_in_every_age() -> void:
	var Quests: GDScript = load("res://scripts/hall/urbs_quests.gd")
	var all: Dictionary = Quests.all()
	check(all.size() >= 30, "the five families have their stories (%d)" % all.size())
	for qid: String in all:
		var steps: Array = all[qid]["steps"]
		check(Quests.kind(steps[0]) == "talk", "%s begins with a talk" % qid)
		for st: Dictionary in steps:
			check(Quests.kind(st) != "", "%s: every step is a kind" % qid)
			if Quests.kind(st) == "go":
				check(Quests.target(st, Vector3.ONE, {}) != null, "%s: its place is somewhere" % qid)
			if Quests.kind(st) == "scene":
				var def: Dictionary = st["scene"]
				check(Scene.problems(def).is_empty(), "%s: its scene is sound: %s" % [qid, Scene.problems(def)])
				var sc: RefCounted = Scene.new(def, "quest", fresh(str(all[qid]["age"])), 5)
				sc.standing.apply({"coin": 500, "give": "a purse for the Prefect"})
				sc.start()
				check(autoplay(sc) >= 0, "%s: its scene plays through" % qid)
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}, "rome_hour": 10.0, "rome_day": 1}
	hall.travel("urbs")
	var numisius: Array = hall.interactables.filter(func(i): return i["kind"] == "citizen" and i["citizen"].get("regular", "") == "baker")
	check(numisius.size() == 1, "Numisius is in his place")
	hall.activate(numisius[0])
	check(hall._talk_panel._log.contains("levy"), "he asks for your help with the harvest before the levy")
	hall._close_panels()
	var you: RefCounted = hall.standing()
	check_eq(Quests.at(you, "baker_heroic"), 1, "the story has begun")
	var field: Vector3 = Quests.target(Quests.current(you, "baker_heroic"), Vector3.ZERO, hall._fronts)
	hall.player.position = field
	hall._check_quest_places()
	check(hall._activity.visible, "at his field the harvest begins")
	check(autoplay(hall._activity.scene) >= 0, "and is brought in")
	hall._close_panels()
	check_eq(Quests.at(you, "baker_heroic"), 3, "and he waits to hear it")
	var coin_before: int = you.coin()
	hall.activate(numisius[0])
	hall._close_panels()
	check(Quests.done(you, "baker_heroic"), "the story is done")
	check(you.collected("voices").has("baker_heroic"), "and his voice remembered")
	check(you.has({"has": "a loaf"}) or you.coin() >= coin_before, "and he gives what he can")
	hall.activate(numisius[0])
	check(not hall._talk_panel._log.contains("levy's called"), "after, he talks of other things")
	hall._close_panels()

	hall._start_scene("errand_merchant")
	check(autoplay(hall._activity.scene) >= 0, "an errand is given")
	check(not hall._errand.is_empty() and str(hall._errand["text"]).contains("paces"), "with directions by the streets: %s" % hall._errand.get("text", ""))
	hall._close_panels()
	var before: int = hall.standing().coin()
	hall.player.position = hall._errand["pos"]
	hall._check_errand()
	check(hall._errand.is_empty(), "delivered where it was going")
	check(hall.standing().coin() > before, "and paid")
	hall.free()


func test_the_collections_gather_across_the_city() -> void:
	var sets: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/collections.json")) as Dictionary)["sets"]
	for want: String in ["exempla", "inscriptions", "coins", "masks", "voices"]:
		check(sets.has(want) and not (sets[want]["ids"] as Array).is_empty(), "the %s are a set" % want)
	var scenes: Dictionary = Scene.all()
	var gives := {}
	for id: String in scenes:
		var c: Variant = scenes[id].get("collect")
		if c is Array:
			gives["%s/%s" % [c[0], c[1]]] = true
	for want: String in ["exempla", "inscriptions", "coins"]:
		for piece: String in sets[want]["ids"]:
			check(gives.has("%s/%s" % [want, piece]), "%s: %s can be found" % [want, piece])
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}, "rome_hour": 10.0}
	hall.travel("urbs")
	var horatius: Array = hall.interactables.filter(func(i): return i["kind"] == "activity" and i["scene"] == "exemplum_horatius")
	check(horatius.size() == 1, "in the age of heroes you can stand where Horatius held the bridge")
	hall.activate(horatius[0])
	autoplay(hall._activity.scene)
	hall._close_panels()
	check(hall.standing().collected("exempla").has("horatius"), "and his story is yours")
	var purse: Array = hall.interactables.filter(func(i): return i["kind"] == "activity" and str(i["scene"]).begins_with("purse"))
	hall.activate(purse[0])
	autoplay(hall._activity.scene)
	hall._close_panels()
	check(hall.standing().collected("coins").has("heroic"), "the coin in your purse, for the age of heroes")
	hall.free()


func test_what_rome_gathers_comes_back_to_the_nexus() -> void:
	var Nexus: GDScript = load("res://scripts/hall/nexus.gd")
	var Rooms: GDScript = load("res://scripts/hall/rooms.gd")
	var p: RefCounted = Progress.open("")
	p.data = {"works": {}}
	var bare: Dictionary = Nexus.now(p, Rooms.doors())
	check(not bare.has("rome"), "nothing of Rome before you have been there")
	var s: RefCounted = Standing.open(p, "republic")
	s.apply({"ledger": "Sold your vote in the consular elections.", "ledger_key": "sold_vote"})
	s.played("vote")
	var sets: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://content/rome/collections.json")) as Dictionary)["sets"]
	for id: String in sets["exempla"]["ids"]:
		s.collect("exempla", id)
	for age: String in AGES:
		s.collect("coins", age)
	var state: Dictionary = Nexus.now(p, Rooms.doors())
	check(state.has("rome") and (state["rome"]["sets"] as Array).has("exempla") and (state["rome"]["sets"] as Array).has("coins"), "complete sets are counted")
	check(not (state["rome"]["sets"] as Array).has("masks"), "and incomplete ones are not")
	var world := Node3D.new()
	var built: Dictionary = Nexus.build(world, {}, Rooms.doors(), state)
	var texts: Array = built["interactables"].map(func(i): return str(i["text"]))
	check(texts.has("Look at the heroes of Rome"), "the heroes stand by Rome's door")
	check(texts.has("Look at Rome's treasury"), "the treasury is back")
	check(not texts.has("Look at the ancestors' masks"), "the masks are not, yet")
	var ledger: Array = built["interactables"].filter(func(i): return i["text"] == "Read the Ledger")
	check(ledger.size() == 1 and str(ledger[0]["note"]).contains("Sold your vote") and str(ledger[0]["note"]).contains("still being written"),
		"the Ledger stands, being written")
	check(texts.has("Look at the frieze of the rites"), "and the frieze of the rites begins")
	world.free()



func test_the_plan_and_the_directions_agree() -> void:
	var Plan: GDScript = load("res://scripts/hall/urbs_plan.gd")
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	check_eq(Plan.compass(Vector2(0, 1)), "north", "north is up the map")
	check_eq(Plan.compass(Vector2(1, 0)), "east", "east")
	check_eq(Plan.compass(Vector2(-1, -1)), "south-west", "south-west")
	var g: Dictionary = Plan.graph()
	check((g["pts"] as Array).size() > 200, "the streets are walked in points")
	var names := {}
	for r: String in g["road"]:
		names[r] = true
	# every street can be reached from the Forum
	var from: int = Plan.nearest_point(Vector2.ZERO)
	for r: String in names:
		var i: int = (g["road"] as Array).find(r)
		var path: Array = Plan.route(g["pts"][from], g["pts"][i])
		var joined := true
		for k in path.size() - 1:
			joined = joined and (g["edges"][path[k]] as Array).any(func(e: Array) -> bool: return e[0] == path[k + 1])
		check(joined and (g["pts"][path[-1]] as Vector2).distance_to(g["pts"][i]) < 1.0, "%s can be reached from the Forum" % r)
	var house: Vector3 = RomeMap.on_ground([507, 409])
	var forum: Vector3 = RomeMap.on_ground([0, 10])
	var said: String = Plan.directions(forum, house, "your house", [])
	check(said.contains("Argiletum") and said.contains("north-east") and said.contains("paces"), "from the Forum home: up the Argiletum, north-east: %s" % said)
	var back: String = Plan.directions(house, forum, "the Forum", [])
	check(back.contains("south-west"), "and back down again, south-west: %s" % back)
	check(Plan.whereabouts(house).contains("Forum is") and Plan.whereabouts(house).contains("south-west"), "where you are, and the Forum's way: %s" % Plan.whereabouts(house))
	var castor := {"name": "the Temple of Castor and Pollux", "pos": RomeMap.on_ground([41, -45])}
	check_eq(Plan.asked_for("Where is the temple of Castor?", [castor], house).get("name", ""), castor["name"], "asking the way to a temple finds it")
	check_eq(Plan.asked_for("How do I get home?", [castor], house).get("name", ""), "your house", "and home")


func test_your_house_and_your_wife_in_every_age() -> void:
	var House: GDScript = load("res://scripts/hall/urbs_house.gd")
	var wives: Array = []
	for age: String in AGES:
		var w: Dictionary = House.wife(age)
		if age == "fall":
			check(w.is_empty(), "in AD 552 there is no wife")
			check(House.household(age).is_empty(), "and no family")
			continue
		check(not w.is_empty() and str(w["name"]) != "", "a wife in %s" % age)
		check(not wives.has(w["name"]), "a different woman in each age")
		wives.append(w["name"])
		for topic: String in ["who", "work", "life", "news", "gods", "around"]:
			check(str(w["topics"].get(topic, "")).length() > 10, "%s answers '%s'" % [w["name"], topic])
		check((w["lines"] as Array).size() >= 4, "%s has her news, visit by visit" % w["name"])
		check(not Activities.scene_def("cena", age).is_empty(), "supper in %s" % age)
	check(House.household("heroic").size() > House.household("republic").filter(func(h: Array) -> bool: return h[0] == "child").size(), "fewer children as the ages go")
	check(House.household("empire").filter(func(h: Array) -> bool: return h[0] == "child").is_empty(), "none at all under the Empire")
	check(House.walls_for("late").size() > House.WALLS.size(), "doors bricked up in AD 384")
	for id: String in House.ROOMS:
		var r: Array = House.ROOMS[id]
		check(r[0] < r[2] and r[1] < r[3], "%s is a room" % id)
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for age_i in [0, 2, 5, 6]:
		hall.progress.data = {"works": {}, "rome_reached": 6, "rome_age": age_i, "rome_hour": 18.0}
		hall.travel("urbs")
		var age: String = AGES[age_i]
		var home: Node3D = hall.world.find_child("YourHouse", true, false)
		check(home != null, "your house stands in %s" % age)
		var wife: Array = hall.interactables.filter(func(i): return i["kind"] == "wife")
		if age == "fall":
			check(wife.is_empty(), "no wife in the broken house")
			check(home.find_children("*", "OmniLight3D", true, false).is_empty(), "and no lamp lit")
		else:
			check(wife.size() == 1, "your wife is at home in %s" % age)
			hall.activate(wife[0])
			check(hall._talk_panel.visible and hall._talk_panel._log.contains(str(House.wife(age)["lines"][0]).left(20)), "she tells you her news")
			hall._on_said("life", "How's life?")
			check(hall._talk_panel._log.contains(str(House.wife(age)["topics"]["life"]).left(15)), "and answers as herself")
			hall._on_said("act", "")
			check(hall._activity.visible and str(hall._activity.scene.id).begins_with("cena"), "supper with the family")
			check(autoplay(hall._activity.scene) >= 0, "which plays through")
			hall._close_panels()
		var plan: Array = hall.interactables.filter(func(i): return i["kind"] == "plan" and i.get("view", "") == "house")
		check(plan.size() == 1, "the plan of the house hangs in the tablinum")
		hall.activate(plan[0])
		check(hall._plan.visible and hall._plan.view == "house", "and shows the house")
		hall._close_panels()
		hall._open_plan("city")
		check(hall._plan.visible and hall._plan.marks.any(func(m): return m["kind"] == "house"), "the plan of the city marks your house")
		hall._close_panels()
	hall.free()


func test_a_sold_household_god_stays_sold() -> void:
	var s := fresh("collapse")
	var sc: RefCounted = Scene.new(Activities.scene_def("cena", "collapse"), "cena_collapse", s, 1)
	sc.start()
	autoplay(sc, 0)
	check(s.has({"done": "lar_sold"}), "Galla sells the Lar")
	var fall: RefCounted = Standing.open(s.progress, "fall")
	var lar: RefCounted = Scene.new(Activities.scene_def("lararium", "fall"), "lararium_fall", fall, 1)
	lar.start()
	autoplay(lar)
	check(lar.lines.any(func(l: String) -> bool: return l.contains("sold him")), "and in AD 552 the niche is empty")
