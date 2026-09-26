extends "res://tests/test_base.gd"
## The Hall: rooms follow the reading list, books are searchable, and the author's
## request to Claude is built from real passages (network calls are not made here).

const Content := preload("res://scripts/content.gd")
const Library := preload("res://scripts/hall/library.gd")
const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")
const Hall := preload("res://scripts/hall/hall.gd")


func test_isagoge_book_is_loaded_in_passages() -> void:
	var book := Library.load_book("porphyry-isagoge")
	check(book != null, "the Isagoge corpus loads")
	if book == null:
		return
	check(book.chunks.size() >= 20, "the whole book is there (%d passages)" % book.chunks.size())
	for c in book.chunks:
		check(str(c["text"]).split(" ").size() <= 420, "passage %s is short enough" % c["id"])
	check(book.chunks.any(func(c): return str(c["text"]).contains("Chrysaorius")), "the opening address is included")


func test_search_finds_the_right_passages() -> void:
	var book := Library.load_book("porphyry-isagoge")
	var hits: Array = book.search("What is the difference between genus and species?", 4)
	check_eq(hits.size(), 4, "four passages come back")
	check(str(hits[0]["text"]).to_lower().contains("genus"), "the best passage talks about genus")
	var accident: Array = book.search("what is an accident", 3)
	check(str(accident[0]["text"]).to_lower().contains("accident"), "accident questions find accident passages")
	var vague: Array = book.search("hello there", 3)
	check_eq(vague.size(), 3, "a vague question still gets passages (the opening)")


func test_request_is_grounded_in_the_book() -> void:
	var room := Rooms.room("porphyry-isagoge")
	var book := Library.load_book("porphyry-isagoge")
	var passages: Array = book.search("What is a property?", 4)
	var body := AuthorAI.build_request(room, passages, "What is a property?", [])
	check_eq(body["model"], "claude-haiku-4-5", "uses the cheap model")
	check(str(body["system"]).contains("Porphyry"), "speaks as Porphyry")
	var content: Array = body["messages"][-1]["content"]
	check_eq(content.size(), 6, "four passages, the question, and the keep-it-short note")
	for i in 4:
		check_eq(content[i]["type"], "document", "passage %d is a document" % i)
		check(content[i]["citations"]["enabled"], "citations are on for passage %d" % i)
	check_eq(content[4]["text"], "What is a property?", "the question comes last")
	var follow := AuthorAI.build_request(room, passages, "And an accident?", [["What is a property?", "Laughing."]])
	check_eq(follow["messages"].size(), 3, "an earlier exchange is kept for follow-ups")


func test_reply_shows_answer_and_quotes() -> void:
	var sample := {"content": [
		{"type": "text", "text": "A property always comes with a kind. "},
		{"type": "text", "text": "Only people can laugh.", "citations": [
			{"type": "char_location", "cited_text": "to be capable of laughing is peculiar to man", "document_title": "Isagoge, Chap. IV"}]},
		{"type": "text", "text": " That is what I meant."}], "stop_reason": "end_turn"}
	var reply := AuthorAI.parse_reply(sample)
	check_eq(reply["text"], "A property always comes with a kind. Only people can laugh. That is what I meant.", "text is joined")
	check_eq(reply["quotes"].size(), 1, "one quote from the book")
	check_eq(reply["quotes"][0]["where"], "Isagoge, Chap. IV", "the quote says where it's from")
	var refused := AuthorAI.parse_reply({"content": [], "stop_reason": "refusal"})
	check(str(refused["text"]).length() > 0, "a refusal still gives the player a line")


func test_reply_survives_null_citations_and_empty_text() -> void:
	var reply := AuthorAI.parse_reply({"content": [{"type": "text", "text": "Hi.", "citations": null}], "stop_reason": "end_turn"})
	check_eq(reply["text"], "Hi.", "a text block with citations: null is fine")
	var none := AuthorAI.parse_reply({"content": null, "stop_reason": "end_turn"})
	check(str(none["error"]) != "", "an empty reply becomes a friendly message, not a blank")


func test_each_author_remembers_only_their_own_talk() -> void:
	var a := AuthorAI.new()
	a.remember("porphyry-isagoge", "Q1", {"text": "A1", "quotes": [], "error": ""})
	a.remember("porphyry-isagoge", "Q2", {"text": "", "quotes": [], "error": "lost"})
	check_eq(a.history_for("porphyry-isagoge").size(), 1, "failed or empty replies are not remembered")
	check_eq(a.history_for("aristotle-categories").size(), 0, "another author starts fresh")
	a.free()


func test_asking_without_a_book_does_not_jam_the_author() -> void:
	var a := AuthorAI.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	var got: Array = []
	a.answered.connect(func(r): got.append(r))
	a.ask("porphyry-isagoge", Rooms.room("porphyry-isagoge"), null, "Hello?")
	check_eq(got.size(), 1, "the player hears back")
	check(not a.busy, "the author is free for the next question")
	a.free()


func test_book_pages_fit_the_screen() -> void:
	var book := Library.load_book("porphyry-isagoge")
	for c in book.chunks:
		var page: String = Hall.excerpt(c["text"], 360)
		check(page.length() <= 370, "page from %s fits (%d chars)" % [c["where"], page.length()])


func test_plural_filler_words_are_ignored() -> void:
	var ws: Array = Library.words("What books did you write? Answers please")
	check(not ws.has("book") and not ws.has("answer"), "plural filler words are dropped: %s" % str(ws))


func test_rooms_follow_the_reading_list() -> void:
	var c := Content.new()
	check(c.load_all(), "content loads")
	var doors := Rooms.doors()
	check_eq(doors.map(func(d): return d["work"]), c.work_order, "doors come straight from the reading list")
	check_eq(doors.size(), 17, "one door for every Greek work")
	check_eq(doors[0]["work"], "porphyry-isagoge", "the first door is the Isagoge")
	check(doors[0]["open"], "the Isagoge room is open")
	check(not doors[1]["open"], "the rest are sealed for now")
	var room := Rooms.room("porphyry-isagoge")
	check(room["facts"].size() >= 4, "the room has facts on its walls")
	for f in room["facts"]:
		check(str(f).length() <= 140, "fact is short: %s" % f)


func test_the_shore_has_a_gateway_per_book() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	check_eq(hall.here, "hub", "you start on the Shore")
	var gates: Array = hall.interactables.filter(func(i): return i["kind"] == "gate")
	check_eq(gates.size(), 17, "one gateway for every Greek work")
	check_eq(gates.map(func(g): return g["to"]), Rooms.doors().map(func(d): return d["work"]), "gateways follow the reading list")
	check(gates[0]["open"] and not gates[1]["open"], "the Isagoge is open, the rest not yet")
	hall.free()


func test_porphyrys_villa_has_everything() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.activate(hall.interactables[0])
	check_eq(hall.here, "porphyry-isagoge", "the first gateway leads to Porphyry's place")
	var kinds := {}
	for i in hall.interactables:
		kinds[i["kind"]] = kinds.get(i["kind"], 0) + 1
	for k in ["author", "book", "map", "tree", "gate"]:
		check(kinds.has(k), "the villa has a %s" % k)
	check_eq(kinds.get("statue", 0), 2, "busts of Aristotle and Plotinus")
	check_eq(kinds.get("fact", 0), Rooms.room("porphyry-isagoge")["facts"].size(), "a stone for every fact")
	var back: Array = hall.interactables.filter(func(i): return i["kind"] == "gate")
	hall.activate(back[0])
	check_eq(hall.here, "hub", "the gateway leads back to the Shore")
	hall.free()


func test_the_map_of_270_ad_is_ready() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/maps/270ad.json"))
	check(data is Dictionary, "map data loads")
	var tex := load("res://assets/maps/270ad.png") as Texture2D
	check(tex != null, "map image loads")
	check(data["regions"].size() >= 4, "Rome, the Gallic and Palmyrene empires, Persia")
	for p in data["pins"]:
		check(p["at"][0] >= 0 and p["at"][0] < data["size"][0] and p["at"][1] >= 0 and p["at"][1] < data["size"][1],
			"%s is on the map" % p["name"])


func test_the_test_run_script_compiles() -> void:
	var demo := load("res://scripts/hall/demo.gd") as GDScript
	check(demo != null and demo.can_instantiate(), "the self-playing test run loads")


func test_controls_match_the_players_layout() -> void:
	Hall.ensure_actions()
	var keys := func(action: String) -> Array:
		return InputMap.action_get_events(action).filter(func(e): return e is InputEventKey).map(func(e): return e.physical_keycode)
	check(keys.call("interact").has(KEY_F), "F is use")
	check(not keys.call("interact").has(KEY_E), "E is no longer use")
	check(keys.call("turn_left").has(KEY_Q) and keys.call("turn_right").has(KEY_E), "Q and E turn left and right")
	check(keys.call("sprint").has(KEY_SHIFT), "Shift sprints")


func test_nothing_steals_the_mouse_while_walking() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	var centre := Vector2(Hall.UI) / 2.0
	var stack: Array = [hall]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is Control and n.is_visible_in_tree() and n.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			check(not n.get_global_rect().grow(0.5).has_point(centre), "%s would catch mouse look at the centre" % n.name)
	hall.free()


const Progress := preload("res://scripts/hall/progress.gd")


func test_porphyry_has_a_lesson_plan() -> void:
	var lesson: Array = Rooms.room("porphyry-isagoge")["lesson"]
	check(lesson.size() >= 4 and lesson.size() <= 8, "a short lesson plan")
	var ids := {}
	for p in lesson:
		check(p.has("id") and p.has("label") and p.has("point"), "each point has an id, label and plain point")
		ids[p["id"]] = true
	check_eq(ids.size(), lesson.size(), "point ids are unique")


func test_the_teacher_knows_what_is_left_to_teach() -> void:
	var room := Rooms.room("porphyry-isagoge")
	var passages: Array = Library.load_book("porphyry-isagoge").search("genus", 4)
	var body := AuthorAI.build_request(room, passages, "Teach me the next thing", [], ["why"], 2)
	var system: String = body["system"]
	check(system.contains("always comes with a kind"), "the lesson points are in his instructions")
	check(system.contains("Already understood: Why he wrote it"), "he knows what you've understood")
	check(system.contains("in their own words"), "he asks you to explain things back")
	check(system.contains("visit number 2"), "he remembers you've been before")


func test_the_understanding_check_only_counts_real_points() -> void:
	var room := Rooms.room("porphyry-isagoge")
	var req := AuthorAI.build_judge_request(room, "A genus is the family, like animal, and a species is a kind in it, like human.", "A genus is the wide family...", [])
	check(str(req["messages"][0]["content"]).contains("judge only this"), "only the student's own words are judged")
	check(not AuthorAI.worth_judging("OK I think I get it"), "a short 'I get it' isn't checked")
	check(not AuthorAI.worth_judging("Teach me the next thing"), "a request isn't checked")
	check(AuthorAI.worth_judging("So a genus is the family and a species is a kind inside it"), "a real explanation is checked")
	check_eq(req["model"], "claude-haiku-4-5", "the check uses the cheap model")
	check_eq(req["output_config"]["format"]["type"], "json_schema", "the check answers in a fixed shape")
	var got := AuthorAI.parse_judgement({"content": [{"type": "text", "text": "{\"understood\": [\"genus_species\", \"made_up\"]}"}]}, room)
	check_eq(got, ["genus_species"], "unknown point ids are ignored")
	check_eq(AuthorAI.parse_judgement({"content": [{"type": "text", "text": "not json"}]}, room), [], "a garbled check counts nothing")


func test_progress_is_remembered_and_mastery_is_earned() -> void:
	var path := "user://test_progress.json"
	var p: RefCounted = Progress.open(path)
	p.data = {"works": {}}
	var lesson: Array = Rooms.room("porphyry-isagoge")["lesson"]
	check_eq(p.learn("porphyry-isagoge", ["why", "why", "difference"]), ["why", "difference"], "new points are counted once")
	check(not p.check_mastery("porphyry-isagoge", lesson), "not mastered with points left")
	p.visit("porphyry-isagoge")
	p.save()
	var again: RefCounted = Progress.open(path)
	check_eq(again.understood("porphyry-isagoge"), ["why", "difference"], "understanding survives a restart")
	check_eq(again.visits("porphyry-isagoge"), 1, "visits are remembered")
	again.learn("porphyry-isagoge", lesson.map(func(x): return x["id"]))
	check(again.check_mastery("porphyry-isagoge", lesson), "every point understood means mastered")
	check(not again.check_mastery("porphyry-isagoge", lesson), "mastery is only announced once")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_mastery_lights_the_gateway_and_restores_the_temple() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	var before: int = hall.restored_columns
	hall.progress.learn("porphyry-isagoge", Rooms.room("porphyry-isagoge")["lesson"].map(func(x): return x["id"]))
	hall.progress.check_mastery("porphyry-isagoge", Rooms.room("porphyry-isagoge")["lesson"])
	hall.travel("hub")
	check(hall.interactables[0].get("mastered", false), "gateway 1 shows the book is mastered")
	check_eq(hall.restored_columns, before + 1, "a column of the temple stands again")
	hall.free()


func test_porphyry_sits_at_his_desk() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("porphyry-isagoge")
	check(hall.teacher.has("head") and is_instance_valid(hall.teacher["head"]), "Porphyry is there in person")
	hall.free()


const Worlds := preload("res://scripts/hall/worlds.gd")
const Kit := preload("res://scripts/hall/kit.gd")


func test_the_world_sharpens_as_history_moves_on() -> void:
	check_eq(Worlds.render_size("greece", Vector2i(1280, 720)), Vector2i(320, 180), "Greece is PS1-sharp")
	check_eq(Worlds.render_size("rome", Vector2i(1280, 720)), Vector2i(640, 360), "Rome is PS2-sharp")
	check(Worlds.detail("rome") > Worlds.detail("greece"), "Rome's shapes are rounder than Greece's")
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	check_eq(hall._view.size, Vector2i(320, 180), "the Shore renders at Greece's size")
	var holder := Node3D.new()
	Kit.detail = 2
	var col: MeshInstance3D = Kit.cylinder(holder, Vector3.ZERO, 1.0, 1.0, "stone", false, 8)
	check_eq((col.mesh as CylinderMesh).radial_segments, 16, "more detail means more sides")
	Kit.detail = 1
	holder.free()
	hall.free()


func test_every_zone_has_its_own_music_and_sounds() -> void:
	var music := preload("res://scripts/pixel/music.gd")
	check(music.ZONES.has("shore"), "the Shore has its sound")
	var zone: String = Rooms.room("porphyry-isagoge").get("zone", "")
	check(music.ZONES.has(zone), "Porphyry's place has a zone with its own sound")
	check(music.ZONES["shore"]["music"][0] != music.ZONES[zone]["music"][0], "Sicily's track is not the Shore's")
	for z in music.ZONES:
		var names: Array = [music.ZONES[z]["music"][0]] + music.ZONES[z]["sounds"].keys()
		for n in names:
			check(ResourceLoader.exists(music.file_for(n)), "%s has its sound file %s" % [z, n])


func test_you_can_sit_and_watch_the_sunset() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for place in ["hub", "porphyry-isagoge"]:
		hall.travel(place)
		var seats: Array = hall.interactables.filter(func(i): return i["kind"] == "seat")
		check(seats.size() >= 1, "%s has somewhere to sit" % place)
		if seats.is_empty():
			continue
		hall.activate(seats[0])
		check(hall.player.seated, "sitting down on the %s bench" % place)
		check(hall.player.position.distance_to(seats[0]["seat"]) < 0.5, "you sit on the bench itself")
		hall.stand_up()
		check(not hall.player.seated, "standing up again")
	hall.free()


func test_the_places_are_alive() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	check(hall.birds.size() >= 5, "swallows circle over the Shore")
	check(hall.sway.size() >= 7, "the Shore's trees stir in the breeze")
	var p0: Vector3 = hall.birds[0]["node"].position
	hall._animate_life(0.5)
	check(hall.birds[0]["node"].position.distance_to(p0) > 0.1, "the swallows fly")
	hall.travel("porphyry-isagoge")
	check(hall.birds.size() >= 3, "birds over the villa too")
	hall.free()


func test_the_toad_follows_you_everywhere() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	check(not hall.toad.is_empty(), "a fat toad keeps you company")
	hall.player.position += Vector3(6, 0, 0)
	var before: float = hall.toad["root"].position.distance_to(hall.player.position)
	for i in 30:
		hall._animate_life(0.1)
	check(hall.toad["root"].position.distance_to(hall.player.position) < before - 2.0, "the toad hops after you")
	hall.travel("porphyry-isagoge")
	hall._animate_life(0.1)
	check(hall.toad["root"].position.distance_to(hall.player.position) < 4.0, "the toad comes through the gateway with you")
	hall.free()


func test_the_villa_feels_lived_in() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("porphyry-isagoge")
	var names := {}
	for n in hall.world.get_children():
		names[str(n.get_meta("prop", ""))] = true
	for prop in ["amphora", "lamp", "table", "rug", "lyre", "plant", "bed", "hearth"]:
		check(names.has(prop), "the villa has a %s" % prop)
	check_eq(hall.people.size(), 2, "Porphyry and his copyist are both there in person")
	check(hall.interactables.any(func(i): return i["kind"] == "person" and i["note"].contains("wax tablet")), "she can tell you how books were made")
	hall.free()


const Lettering := preload("res://scripts/hall/lettering.gd")


func test_the_lettering_is_hand_cut_not_the_default() -> void:
	for f in [Lettering.LAPIDARY, Lettering.SCRIBE]:
		check(f is Font and f != ThemeDB.fallback_font, "lettering of our own, not the engine's")
	for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;'\"-!?()/&":
		check(Lettering.LAPIDARY.has_char(c.unicode_at(0)), "the inscription capitals can cut '%s'" % c)
		check(Lettering.SCRIBE.has_char(c.unicode_at(0)), "the scribe's hand can write '%s'" % c)
	check(Lettering.LAPIDARY.get_string_size("ROME", HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.TITLE).x > Lettering.SCRIBE.get_string_size("ROME", HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY).x, "capitals are cut larger than the reading hand")
	check_eq(Hall.UI, Vector2i(640, 360), "words get twice the pixels the world does")
	check_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 640, "the window agrees")


func test_every_word_on_screen_uses_our_lettering() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("porphyry-isagoge")
	hall._open_ask("porphyry-isagoge")
	var cheap: Array = []
	var stack: Array = [hall._ui]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is RichTextLabel:
			for item in ["normal_font", "bold_font", "italics_font", "bold_italics_font"]:
				if n.get_theme_font(item) == ThemeDB.fallback_font:
					cheap.append("%s.%s" % [n.name, item])
		elif n is Label or n is Button or n is LineEdit:
			if n.get_theme_font("font") == ThemeDB.fallback_font:
				cheap.append(n.name)
	check_eq(cheap.size(), 0, "no cheap lettering anywhere: %s" % str(cheap))
	check(hall._answer.get_content_height() <= hall._answer.size.y, "the teacher's greeting fits the page (%d of %d)" % [hall._answer.get_content_height(), hall._answer.size.y])
	hall.free()
