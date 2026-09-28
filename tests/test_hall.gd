extends "res://tests/test_base.gd"
## The Hall: rooms follow the reading list, books are searchable, and the author's
## request to Claude is built from real passages (network calls are not made here).

const Content := preload("res://scripts/content.gd")
const Library := preload("res://scripts/hall/library.gd")
const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")
const Hall := preload("res://scripts/hall/hall.gd")
const Beat := preload("res://scripts/hall/beat.gd")


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


## The books whose places are built so far; every other gateway on the Shore is sealed.
const OPEN_WORKS := ["porphyry-isagoge", "aristotle-categories", "aristotle-the-rest-of-the-organon", "rhetorica-ad-herennium", "euclid-elements",
	"homer-the-iliad", "hesiod-theogony", "sappho-fragments", "aeschylus-the-oresteia", "sophocles-the-theban-plays", "euripides-the-tragedies", "aristophanes-the-comedies", "herodotus-the-histories", "thucydides-the-peloponnesian-war", "the-pre-socratics", "plato-republic",
	"aristotle-nicomachean-ethics"]
## The places built in sprints 4 to 6 (places_greek.gd), each tested like the villa and the Lyceum.
const NEW_PLACES := ["rhetorica-ad-herennium", "euclid-elements", "homer-the-iliad", "hesiod-theogony", "sappho-fragments",
	"aeschylus-the-oresteia", "sophocles-the-theban-plays", "euripides-the-tragedies",
	"aristophanes-the-comedies", "herodotus-the-histories", "thucydides-the-peloponnesian-war",
	"the-pre-socratics", "plato-republic"]


func test_rooms_follow_the_reading_list() -> void:
	var c := Content.new()
	check(c.load_all(), "content loads")
	var doors := Rooms.doors()
	check_eq(doors.map(func(d): return d["work"]), c.work_order, "doors come straight from the reading list")
	check_eq(doors.size(), 16, "one door for every Greek work")
	check_eq(doors[0]["work"], "porphyry-isagoge", "the first door is the Isagoge")
	check(doors[0]["open"] and doors[1]["open"], "the Isagoge and the Categories have their places")
	for d in doors:
		check_eq(d["open"], OPEN_WORKS.has(d["work"]), "%s is %s" % [d["work"], "open" if OPEN_WORKS.has(d["work"]) else "sealed for now"])
	var room := Rooms.room("porphyry-isagoge")
	check(room["facts"].size() >= 4, "the room has facts on its walls")
	for f in room["facts"]:
		check(str(f).length() <= 140, "fact is short: %s" % f)


func test_the_shore_has_a_gateway_per_book() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("hub")
	check_eq(hall.here, "hub", "Greece's hub is the Shore")
	var gates: Array = hall.interactables.filter(func(i): return i["kind"] == "gate" and not i["to"] in ["nexus", "asset_test"])
	var places: Array = Rooms.doors().filter(func(d): return Rooms.room(d["work"]).get("area_of", "") == "")
	check_eq(gates.size(), 14, "one gateway for every place (Aristotle's three books share one)")
	check_eq(gates.map(func(g): return g["to"]), places.map(func(d): return d["work"]), "gateways follow the reading list")
	for g in gates:
		check_eq(g["open"], OPEN_WORKS.has(g["to"]), "the gateway to %s is %s" % [g["to"], "open" if OPEN_WORKS.has(g["to"]) else "sealed"])
	hall.free()


func test_porphyrys_villa_has_everything() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("hub")
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
	hall.travel("hub")
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
	for work in ["porphyry-isagoge", "aristotle-categories"]:
		check(music.ZONES.has(Rooms.room(work).get("zone", "")), "%s's place has a zone with its own sound" % work)
	for z in music.ZONES:
		for layer in music.ZONES[z]["layers"]:
			check(ResourceLoader.exists(music.file_for(layer["file"])), "%s has its sound file %s" % [z, layer["file"]])
	var tunes := func(z: String) -> Array:
		return music.plan(z, _all_back(z)).filter(func(l): return l["music"]).map(func(l): return l["file"])
	for z in ["sicily", "athens"]:
		for f in tunes.call(z):
			check(not tunes.call("shore").has(f), "%s's music is its own, not the Shore's (%s)" % [z, f])


func test_you_can_sit_and_watch_the_sunset() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for place in ["hub", "porphyry-isagoge", "nexus"]:
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
	hall.travel("hub")
	check(hall.birds.size() >= 5, "swallows circle over the Shore")
	check(hall.sway.size() >= 7, "the Shore's trees stir in the breeze")
	var p0: Vector3 = hall.birds[0]["node"].position
	hall._animate_life(0.5)
	check(hall.birds[0]["node"].position.distance_to(p0) > 0.1, "the swallows fly")
	hall.progress.learn("porphyry-isagoge", _ids("porphyry-isagoge"))
	hall.travel("porphyry-isagoge")
	check(hall.birds.size() >= 3, "birds over the restored villa too")
	hall.free()


func test_the_toad_follows_you_everywhere() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("hub")
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
	hall.progress.learn("porphyry-isagoge", _ids("porphyry-isagoge"))
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
const Music := preload("res://scripts/pixel/music.gd")


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
	hall.progress.data = {"works": {}}
	hall.travel("plato-republic")
	hall._open_ask("plato-republic")
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


func test_aristotles_lyceum_is_ready() -> void:
	var room := Rooms.room("aristotle-categories")
	check_eq(room.get("place", ""), "lyceum", "the Categories are taught at the Lyceum")
	check_eq(room.get("zone", ""), "athens", "with Athens' own music")
	check_eq(room.get("lesson", []).size(), 6, "a six-point lesson")
	for f in ["athens_ghost", "athens_pipes", "birds", "stream"]:
		check(FileAccess.file_exists(Music.file_for(f)), "%s.wav is rendered" % f)
	var book := Library.load_book("aristotle-categories")
	check(book != null and book.chunks.size() > 10, "the Categories are in the library")
	if book:
		var hits: Array = book.search("primary substance individual man horse", 3)
		check(hits.size() > 0 and str(hits[0]["where"]).contains("Chap. 5"), "chapter 5 answers about substance")
	check(FileAccess.file_exists("res://content/maps/335bc.json") and FileAccess.file_exists("res://assets/maps/335bc.png"), "the map of 335 BC is drawn")


func test_aristotle_walks_his_walkway() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("aristotle-categories")
	check(hall.here_name.contains("Lyceum"), "you are at the Lyceum")
	check(not hall.people.is_empty() and hall.people[0].has("path"), "Aristotle is there, and he walks")
	var author: Array = hall.interactables.filter(func(i): return i["kind"] == "author" and not i.has("work"))
	check(author.size() == 1 and author[0].has("follow"), "you talk to him wherever he is")
	check_eq(hall.areas.map(func(a): return a["work"]), ["aristotle-the-rest-of-the-organon", "aristotle-nicomachean-ethics"],
		"the Organon has its hill and the Ethics its grove")
	var root: Node3D = hall.people[0]["root"]
	hall.player.position = Vector3(0, 0.05, 40)  # far away: he keeps walking
	var before := root.position
	for i in 30:
		hall._animate_people(0.1)
	check(root.position.distance_to(before) > 0.5, "he paces when left alone")
	hall.player.position = root.position + root.global_transform.basis.z * 2.0  # in front of him
	var here := root.position
	for i in 30:
		hall._animate_people(0.1)
	check(root.position.distance_to(here) < 0.05, "he stops to talk when you come near")
	hall.free()


func test_the_macedonians_march_in_step() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("aristotle-categories")
	check_eq(hall.squads.size(), 1, "a block of soldiers drills on the meadow")
	var sq: Dictionary = hall.squads[0]
	check_eq(sq["legs"].size(), 32, "sixteen men, in rows and files")
	var start: Vector3 = sq["root"].position
	for i in 20:
		hall._animate_squads(0.1)
	check(sq["root"].position.distance_to(start) > 1.5, "they march")
	check(absf(sq["legs"][0].rotation.x) > 0.01, "in step")
	check(hall.interactables.any(func(i): return i["kind"] == "person" and i["note"].contains("sarissa")), "you can learn who they are")
	var shield: Material = preload("res://scripts/hall/textures.gd").material("shield")
	check(shield is StandardMaterial3D and shield.albedo_texture != null, "the sun of Macedon is on the shield")
	hall.free()


# ---------- lost places, brought back by understanding ----------



static func _ids(work: String) -> Array:
	return Rooms.room(work)["lesson"].map(func(p): return p["id"])


## Everything that can come back in a zone's place, in order.
static func _all_back(zone: String) -> Array:
	for work in ["porphyry-isagoge", "aristotle-categories"]:
		if Rooms.room(work).get("zone", "") == zone:
			return Rooms.room(work)["restores"].map(func(r): return r["what"])
	return []


static func _db(plan: Array, file: String) -> float:
	for layer in plan:
		if layer["file"] == file:
			return layer["db"]
	return -999.0


func test_every_place_starts_lost() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for work in ["porphyry-isagoge", "aristotle-categories"]:
		hall.travel(work)
		check_eq(hall.restored_here, [], "%s starts lost to the world" % work)
		check(hall.teacher.get("shade", false), "%s is only a pale shade" % Rooms.room(work)["author"])
		var author: Array = hall.interactables.filter(func(i): return i["kind"] == "author" and not i.has("work"))
		check(author.size() == 1 and author[0]["text"].contains("shade"), "you speak with his shade")
	check(hall.squads[0].get("undead", false), "Alexander's men march on, undead")
	check(hall.interactables.any(func(i): return i.get("note", "").contains("sarissa") and i["note"].contains("forgotten")), "the dead soldiers are explained")
	hall.travel("porphyry-isagoge")
	check_eq(hall.people.size(), 1, "the copyist's stool is empty")
	hall.free()


func test_each_point_understood_brings_a_piece_back() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for work in ["porphyry-isagoge", "aristotle-categories"]:
		var ids := _ids(work)
		var restores: Array = Rooms.room(work)["restores"]
		check_eq(restores.size(), ids.size(), "one piece of %s for each lesson point" % work)
		for k in ids.size() + 1:
			hall.progress.data = {"works": {}}
			hall.progress.learn(work, ids.slice(0, k))
			hall.travel(work)
			check_eq(hall.restored_here, restores.slice(0, k).map(func(r): return r["what"]), "%s: %d points understood, %d pieces back" % [work, k, k])
		check(not hall.teacher.is_empty() and not hall.teacher.get("shade", false), "%s is himself again" % Rooms.room(work)["author"])
		if work == "aristotle-categories":
			check(not hall.squads[0].get("undead", true), "the soldiers are men again")
		else:
			check_eq(hall.people.size(), 2, "the copyist is back at work")
	hall.free()


func test_the_music_tells_you_how_much_is_restored() -> void:
	var files := func(z: String, back: Array) -> Array:
		return Music.plan(z, back).map(func(l): return l["file"])
	var lost: Array = files.call("athens", [])
	check(lost.has("athens_ghost") and lost.has("wind"), "a lost place: a faint echo of its tune, and the wind")
	for f in ["athens_pipes", "athens_drone", "athens_walk", "athens_drum", "birds", "stream"]:
		check(not lost.has(f), "%s is silent while the Lyceum is lost" % f)
	for z in ["sicily", "athens"]:
		var all_back := _all_back(z)
		check_eq(all_back.size(), 6, "%s has six pieces to bring back" % z)
		for k in range(1, all_back.size() + 1):
			var before: Array = files.call(z, all_back.slice(0, k - 1))
			var after: Array = files.call(z, all_back.slice(0, k))
			before.sort()
			after.sort()
			check(before != after, "%s: bringing back '%s' changes what you hear" % [z, all_back[k - 1]])
		var whole: Array = files.call(z, all_back)
		check(not whole.has(z + "_ghost"), "%s: the echo is gone once the place is whole" % z)
		check(_db(Music.plan(z, all_back.slice(0, 3)), z + "_ghost") < _db(Music.plan(z, []), z + "_ghost"), "%s: the echo fades as life returns" % z)
		check(_db(Music.plan(z, []), "wind") > _db(Music.plan(z, all_back), "wind"), "%s: the wind is louder in the lost place" % z)
	check(files.call("athens", ["water"]).has("stream"), "the stream is heard when it runs again")
	check(files.call("athens", _all_back("athens")).has("athens_drum"), "the living soldiers bring their drum")
	check(Music.plan("shore", []).any(func(l): return l["file"] == "shore"), "the Shore keeps its own theme")


func test_restoration_happens_before_your_eyes() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("aristotle-categories")
	var stand := Vector3(-4.0, 0.05, 3.0)
	hall.player.position = stand
	hall._open_ask("aristotle-categories")
	check(hall._ask_room.get("state", "").contains("pale shade"), "he knows his school has faded and he is a shade")
	check(hall._talk["aristotle-categories"].contains(Rooms.room("aristotle-categories")["greeting_lost"].left(20)), "and greets you from the ruin")
	hall._on_judged("aristotle-categories", ["ten_questions"])
	check_eq(hall.restored_here, [], "nothing changes while you talk")
	hall._close_panels()
	check_eq(hall.restored_here, ["water"], "when you turn from him, the first piece comes back")
	check(hall.player.position.distance_to(stand) < 0.01, "and you are still standing where you were")
	check(hall._quip.contains("Ilissos"), "you are told what came back")
	check_eq(hall.progress.visits("aristotle-categories"), 1, "it doesn't count as another visit")
	var body := AuthorAI.build_request(hall._ask_room, [], "Hello", [])
	check(body["system"].contains(hall._ask_room["state"]), "the teacher is told what state his place is in")
	check(not body["system"].contains("Plotinus"), "Aristotle is not told about Porphyry's study")
	hall.free()


# ---------- review fixes: restoring safely, and honestly ----------

const Places := preload("res://scripts/hall/places.gd")


func _lyceum_hall() -> Node:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("aristotle-categories")
	return hall


func test_an_understanding_judged_after_you_walk_away_still_restores() -> void:
	var hall := _lyceum_hall()
	hall._open_ask("aristotle-categories")
	hall._close_panels()
	hall._on_judged("aristotle-categories", ["ten_questions"])
	check_eq(hall.restored_here, ["water"], "the piece comes back even though the talk had ended")
	check_eq(hall._restore_pending, "", "and nothing is left waiting")
	hall.free()


func test_leaving_the_place_cancels_what_was_waiting() -> void:
	var hall := _lyceum_hall()
	hall._open_ask("aristotle-categories")
	hall._on_judged("aristotle-categories", ["ten_questions"])
	check_eq(hall._restore_pending, "aristotle-categories", "a piece waits for the talk to end")
	hall.travel("hub")
	hall._close_panels()
	check_eq(hall.here, "hub", "closing a panel later does not drag you back")
	check_eq(hall._restore_pending, "", "the waiting piece was dropped when you left")
	hall.free()


func test_no_restoring_in_the_middle_of_a_fade() -> void:
	var hall := _lyceum_hall()
	hall.progress.learn("aristotle-categories", ["ten_questions"])
	hall.travelling = true
	hall._restore()
	check_eq(hall.restored_here, [], "nothing is rebuilt while a fade is running")
	check_eq(hall._restore_pending, "aristotle-categories", "it waits instead")
	var t := InputEventKey.new()
	t.physical_keycode = KEY_T
	t.pressed = true
	hall._unhandled_input(t)
	check(not hall._read_panel.visible, "the tablet does not open in the middle of a fade")
	hall.travelling = false
	hall._close_panels()
	check_eq(hall.restored_here, ["water"], "and it comes back once the fade is over")
	hall.free()


func test_a_place_without_a_restore_list_is_whole() -> void:
	check(Places.back({}, 0).has("sun") and Places.back({}, 0).has("teacher"), "nothing to restore means nothing is missing")
	check_eq(Places.saturation({}, 0), 1.0, "and it is in full colour")


func test_the_teacher_is_told_how_far_his_place_is_back() -> void:
	var hall := _lyceum_hall()
	hall._open_ask("aristotle-categories")
	check(hall._ask_room["state"].contains("pale shade"), "lost: he is a shade")
	hall._close_panels()
	hall.progress.learn("aristotle-categories", _ids("aristotle-categories").slice(0, 5))
	hall.travel("aristotle-categories")
	hall._open_ask("aristotle-categories")
	var state: String = hall._ask_room["state"]
	check(state.contains("you are yourself") and not state.contains("pale shade"), "five pieces back: he knows he is himself")
	check(state.contains("It is morning in Athens.") and state.contains("Never promise"), "and how things stand, with no promise")
	hall.free()


func test_old_points_in_a_save_restore_nothing() -> void:
	var hall := _lyceum_hall()
	hall.progress.learn("aristotle-categories", ["a_point_that_no_longer_exists", "ten_questions"])
	check_eq(hall._stage("aristotle-categories"), 1, "only points of the current lesson count")
	hall.free()


func test_no_birds_over_a_dead_place() -> void:
	var hall := _lyceum_hall()
	check(hall.birds.is_empty(), "no swallows over the dead Lyceum")
	hall.progress.learn("aristotle-categories", _ids("aristotle-categories").slice(0, 2))
	hall.travel("aristotle-categories")
	check(not hall.birds.is_empty(), "the birds return with the leaves")
	hall.free()


func test_a_shade_keeps_his_chair() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.travel("porphyry-isagoge")
	var meshes: Array = hall.teacher["root"].find_children("*", "MeshInstance3D", true, false)
	var chair: Array = meshes.filter(func(m): return m.has_meta("keep"))
	var wood: Material = preload("res://scripts/hall/textures.gd").material("wood")
	check(chair.size() == 1 and chair[0].material_override == wood, "his chair stays wood while he is a shade")
	var shade: Material = meshes.filter(func(m): return not m.has_meta("keep"))[0].material_override
	check(shade != wood and shade.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "the man himself is the shade")
	hall.free()


func test_the_whole_walkway_has_one_roof() -> void:
	var holder := Node3D.new()
	var stoa: Node3D = Kit.stoa(holder, Vector3.ZERO, 0.0, 34.0, 5.0, true)
	var roofs: Array = stoa.get_children().filter(func(n): return n is MeshInstance3D and absf(n.position.y - 4.45) < 0.01)
	check_eq(roofs.size(), 1, "one roof, no overlapping strips to flicker")
	holder.free()


func test_music_layers_say_when_they_are_loud() -> void:
	for z in Music.ZONES:
		for layer in Music.ZONES[z]["layers"]:
			check(not layer.has("lost_db"), "%s/%s: no hidden rule about the sun" % [z, layer["file"]])
			check(layer.has("loud_db") == layer.has("loud_until"), "%s/%s: loud_db and loud_until go together" % [z, layer["file"]])


func test_each_book_has_its_own_ground_and_its_own_aristotle() -> void:
	var hall := _lyceum_hall()
	hall._check_area()
	check_eq(hall.area, "aristotle-categories", "at the Lyceum you are in the Categories")
	for w in ["aristotle-the-rest-of-the-organon", "aristotle-nicomachean-ethics"]:
		var a: Dictionary = hall.areas.filter(func(x): return x["work"] == w)[0]
		hall.player.position = Vector3(a["c"].x, 5.1, a["c"].y)
		hall._check_area()
		check_eq(hall.area, w, "standing on its ground puts you in %s" % w)
		var seen: Array = hall.people.filter(func(p): return p.has("area") and p["root"].visible)
		check(seen.size() == 1 and seen[0]["area"] == w, "and only that book's Aristotle is there")
		check_eq(hall._tablet_text().contains(Rooms.room(w)["book"]), true, "the tablet is that book's")
	hall.free()


## The lesson stones (sprint 3): every point of every lesson in Greece has its own scene, and
## reading it shows the plain summary of that point.
func test_every_lesson_point_has_its_stone() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for place in ["porphyry-isagoge", "aristotle-categories"]:
		hall.travel(place)
		var works: Array = [place]
		if place == "aristotle-categories":
			works.append_array(["aristotle-the-rest-of-the-organon", "aristotle-nicomachean-ethics"])
		for work in works:
			for p in Rooms.room(work)["lesson"]:
				var stones: Array = hall.interactables.filter(func(i): return i.get("id", "") == p["id"] and i.get("work", place) == work)
				check(not stones.is_empty(), "%s: a stone for '%s'" % [work, p["id"]])
				check(stones.any(func(i): return i["note"] == p["point"]), "%s: the '%s' stone reads its point" % [work, p["id"]])
	hall.free()


## Zen (Theoros): reading a lesson stone counts its point, and a piece of the place comes back
## when you turn from the stone. Student (Mathetes): the stone is only there to read.
func test_in_zen_a_stone_mends_the_world_and_in_student_it_does_not() -> void:
	for mode in ["student", "zen"]:
		var hall := _lyceum_hall()
		hall.progress.data = {"works": {}}
		hall.progress.set_mode("greece", mode)
		var stone: Dictionary = hall.interactables.filter(func(i): return i.get("id", "") == "ten_questions")[0]
		hall.activate(stone)
		check(hall._read_panel.visible, "%s: the stone is read" % mode)
		hall._close_panels()
		if mode == "zen":
			check(hall.progress.understood("aristotle-categories").has("ten_questions"), "zen: the point counts")
			check_eq(hall.restored_here, ["water"], "zen: the Ilissos runs again")
		else:
			check(hall.progress.understood("aristotle-categories").is_empty(), "student: the stone counts nothing")
			check_eq(hall.restored_here, [], "student: nothing comes back")
		hall.free()


func test_a_zen_stone_on_the_hill_mends_the_hill() -> void:
	var hall := _lyceum_hall()
	hall.progress.data = {"works": {}}
	hall.progress.set_mode("greece", "zen")
	var stone: Dictionary = hall.interactables.filter(func(i): return i.get("id", "") == "premise")[0]
	hall.activate(stone)
	hall._close_panels()
	check(hall.progress.understood("aristotle-the-rest-of-the-organon").has("premise"), "the Organon's point counts")
	check(hall.progress.understood("aristotle-categories").is_empty(), "and not the Categories'")
	check_eq(hall.backs.get("aristotle-the-rest-of-the-organon", []), ["water"], "the hill's stream runs")
	hall.free()


## An area's life facts sit together on one stone at its entrance, next to its banner.
func test_an_areas_facts_are_on_the_stone_by_its_banner() -> void:
	var hall := _lyceum_hall()
	for w in ["aristotle-the-rest-of-the-organon", "aristotle-nicomachean-ethics"]:
		check(hall.interactables.filter(func(i): return i["kind"] == "fact" and i.get("work", "") == w).is_empty(), "%s: no separate fact stones" % w)
		var markers: Array = hall.interactables.filter(func(i): return i.get("work", "") == w and i["text"].begins_with("Read the stone: The"))
		check_eq(markers.size(), 1, "%s: one stone by the banner" % w)
		for f in Rooms.room(w)["facts"]:
			check(markers[0]["note"].contains(f), "%s: the stone carries '%s'" % [w, f.left(30)])
	hall.free()


## The waterway (BB1): once the Ilissos runs, a boat rows between the Lyceum, the hill of the Organon
## and the grove of the Ethics; at each landing you choose where to go, and F steps you ashore. On
## the dry bed the boat lies stranded.
func test_the_boat_rows_you_to_all_three_places() -> void:
	var hall := _lyceum_hall()
	check(hall.interactables.filter(func(i): return i["kind"] == "ferry").is_empty(), "no boat to take on a dry bed")
	check(hall.interactables.any(func(i): return i.get("note", "").contains("dry bed of the Ilissos")), "the stranded boat is explained")
	hall.progress.learn("aristotle-categories", ["ten_questions"])
	hall.travel("aristotle-categories")
	var ferries: Array = hall.interactables.filter(func(i): return i["kind"] == "ferry")
	check_eq(ferries.size(), 6, "from each of the three landings, a way to each of the other two")
	for leg in [["lyceum", "hill", "aristotle-the-rest-of-the-organon"], ["hill", "grove", "aristotle-nicomachean-ethics"],
			["grove", "lyceum", "aristotle-categories"]]:
		var take: Dictionary = ferries.filter(func(i): return i["from"] == leg[0] and i["to"] == leg[1])[0]
		check(take["text"].contains(Places.LANDINGS[leg[1]]["name"]), "the landing says where it goes: %s" % take["text"])
		hall.activate(take)
		check(hall.player.seated, "%s: you sit in the boat" % leg[0])
		for k in 120:
			hall._animate_boats(0.5)
		var boat: Dictionary = take["boat"]
		var there: Vector3 = Places.LANDINGS[leg[1]]["at"]
		check(boat["root"].position.distance_to(there) < 0.1, "it rows you from %s to %s" % [leg[0], leg[1]])
		check(Vector2(hall.player.position.x, hall.player.position.z).distance_to(Vector2(there.x, there.z)) < 0.1, "carrying you with it")
		hall.stand_up()
		check(not hall.player.seated, "F steps you ashore at %s" % leg[1])
		hall._check_area()
		check_eq(hall.area, leg[2], "and you are in %s's place" % leg[2])
	# stepping out mid-river puts you on a bank, and the boat waits there
	var take: Dictionary = ferries.filter(func(i): return i["from"] == "lyceum" and i["to"] == "grove")[0]
	hall.activate(take)
	for k in 6:
		hall._animate_boats(0.5)
	hall.stand_up()
	check(absf(hall.player.position.x - 8.0) > 1.5, "mid-river, you step onto a bank, out of the water")
	var left: Vector3 = take["boat"]["root"].position
	hall._animate_boats(0.5)
	check_eq(take["boat"]["root"].position, left, "the boat waits where you left it")
	hall.free()


## Sprint 4's places: each starts lost with its teacher a shade, has every point on a stone (or a
## beat), a book to read, a map, a way home, and comes back piece by piece until it is whole.
func test_the_new_places_are_built_like_the_first() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for work in NEW_PLACES:
		var room := Rooms.room(work)
		check(Library.load_book(work) != null, "%s: the book is there to read" % work)
		hall.progress.data = {"works": {}}
		hall.travel(work)
		check_eq(hall.here, work, "%s: its place is built" % work)
		check_eq(hall.restored_here, [], "%s starts lost to the world" % work)
		check(hall.teacher.get("shade", false), "%s: the teacher is a shade" % work)
		var kinds: Array = hall.interactables.map(func(i): return i["kind"])
		for k in ["author", "book", "map", "gate"]:
			check(kinds.has(k), "%s has its %s" % [work, k])
		var home: String = "urbs" if room.get("world", "greece") == "rome" else "hub"  # the Shore, or the city of Rome
		check(hall.interactables.any(func(i): return i["kind"] == "gate" and i["to"] == home), "%s: a way back to %s" % [work, home])
		check_eq(hall.interactables.filter(func(i): return i["kind"] == "fact").size(), room["facts"].size(), "%s: a stone for each fact" % work)
		for p in room["lesson"]:
			var stones: Array = hall.interactables.filter(func(i): return i.get("id", "") == p["id"] and i.get("work", work) == work)
			check(stones.any(func(i): return i["note"] == p["point"]), "%s: the '%s' point is on a stone or a beat" % [work, p["id"]])
		for it in hall.interactables.filter(func(i): return i["kind"] == "beat"):
			check(not Beat.find(work, it["beat"]).is_empty(), "%s: the beat '%s' is written" % [work, it["beat"]])
		var ids := _ids(work)
		var restores: Array = room["restores"]
		for k in ids.size() + 1:
			hall.progress.data = {"works": {}}
			hall.progress.learn(work, ids.slice(0, k))
			hall.travel(work)
			check_eq(hall.restored_here, restores.slice(0, k).map(func(r): return r["what"]), "%s: %d points, %d pieces back" % [work, k, k])
		check(not hall.teacher.get("shade", false), "%s: the teacher is himself again" % work)
		var zone: String = room["zone"]
		var all_back: Array = restores.map(func(r): return r["what"])
		for k in range(1, all_back.size() + 1):
			var before: Array = Music.plan(zone, all_back.slice(0, k - 1)).map(func(l): return l["file"])
			var after: Array = Music.plan(zone, all_back.slice(0, k)).map(func(l): return l["file"])
			before.sort()
			after.sort()
			check(before != after, "%s: bringing back '%s' changes what you hear" % [work, all_back[k - 1]])
		check(not Music.plan(zone, all_back).any(func(l): return l["file"] == zone + "_ghost"), "%s: the echo is gone once it is whole" % work)
	hall.free()


## The memory walk (the Rhetorica): you set five images on five places in the memory house, go to
## court, walk the places again, and speak; for a Theoros that counts the last point.
func test_the_memory_walk_can_be_walked() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}}
	hall.progress.set_mode("rome", "zen")
	hall.travel("rhetorica-ad-herennium")
	var it: Dictionary = hall.interactables.filter(func(i): return i["kind"] == "beat" and i["beat"] == "memory_walk")[0]
	hall.activate(it)
	check(hall.beat != null, "the walk begins")
	var shown := 0
	for guard in 400:
		if hall.beat == null:
			break
		var mark: Variant = hall.beat.next_mark()
		if mark != null:
			hall.player.position = Vector3(mark.x, hall.player.position.y, mark.z)
		elif hall.beat.kind() in ["line", "act"]:
			hall.beat.press(hall.player)
		if hall.beat:
			shown = it["cast"].values().filter(func(n): return n.visible).size()
			hall._play_beat(0.1, true)  # holding F
	check(hall.beat == null, "the walk ends")
	check_eq(shown, 5, "five images were set on five places")
	check(hall._read_panel.visible and hall._read_text.text.contains("golden hand"), "its point is read")
	hall._close_panels()
	check(hall.progress.understood("rhetorica-ad-herennium").has("order"), "and it counts")
	check(it["cast"].values().all(func(n): return not is_instance_valid(n) or not n.visible), "the images are gone again, for next time")
	hall.free()


## Plays a beat to its end the way a player would: walking to each mark, pressing and holding F.
## Returns how many steps it took (or -1 if it never ended).
static func _play_through(hall: Node, it: Dictionary) -> int:
	hall.activate(it)
	for guard in 1000:
		if hall.beat == null:
			return guard
		var mark: Variant = hall.beat.next_mark()
		if mark != null:
			hall.player.position = Vector3(mark.x, hall.player.position.y, mark.z)
		elif hall.beat.kind() in ["line", "act"]:
			hall.beat.press(hall.player)
		if hall.beat:
			hall._play_beat(0.1, true)
	return -1


## The Republic's heart: at the table on the Academy's terrace you found the city in speech with
## Socrates, one step of the argument at a time, and each step's buildings rise on the board below
## as you play it; the city is kept; its stones and the soul over it wait until it has got that
## far; after the just city it falls, regime by regime; and then it can be founded again.
func test_the_city_in_speech_rises_step_by_step_at_the_academy() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	var work := "plato-republic"
	hall.progress.data = {"works": {}}
	hall.progress.set_mode("greece", "zen")
	hall.travel(work)
	var find := func(id: String) -> Dictionary:
		return hall.interactables.filter(func(i): return i.get("id", "") == id)[0]
	hall.activate(find.call("one_work"))
	check(not hall.progress.understood(work).has("one_work"), "the city of pigs is not read before it is founded")
	hall._close_panels()
	hall.activate(find.call("soul"))
	check(hall.beat == null, "the soul does not rise over a city that is not yet just")
	hall._close_panels()
	check(hall.interactables.all(func(i): return i["kind"] != "council"), "there is no council game any more")
	for step in range(1, 10):
		var talk: Array = hall.interactables.filter(func(i): return i.has("city_to"))
		check_eq(talk.size(), 1, "one step of the argument waits at the table (%d)" % step)
		if talk.is_empty():
			break
		check_eq(int(talk[0]["city_to"]), step, "and it is the next one")
		check(not Beat.find(work, talk[0]["beat"]).is_empty(), "its talk is written: %s" % talk[0]["beat"])
		var hidden: Array = talk[0]["cast"].values()
		if step <= 5:
			check(not hidden.is_empty() and hidden.all(func(n): return not (n as Node3D).visible), "what step %d builds waits hidden" % step)
		check(_play_through(hall, talk[0]) >= 0, "step %d plays to its end" % step)
		hall._close_panels()
		check_eq(hall.city_stage(), step, "the city has come to step %d, and is kept" % step)
		check_eq(hall.here, work, "the Academy is built again round it")
		if step == 5:
			check(hall.progress.understood(work).has("one_work") and hall.progress.understood(work).has("just_city"),
				"for a Theoros the city of pigs and the just city count as they are reached")
			check(_play_through(hall, find.call("soul")) >= 0, "now the soul can be looked into")
			hall._close_panels()
			check(hall.progress.understood(work).has("soul"), "and it counts")
	var again: Array = hall.interactables.filter(func(i): return i["kind"] == "city_again")
	check_eq(again.size(), 1, "after tyranny, the city can be founded again")
	if not again.is_empty():
		hall.activate(again[0])
		check_eq(hall.city_stage(), 0, "and it is back to the bare site")
	hall.free()


## The Rhetorica is the first zone of Rome: its place is laid out on the map of Republican Rome
## (rome_map.gd), everything you can reach stands inside its zone and a fence runs round it, and
## the rest of the city's zones wait on the same map, sealed, for the Rome world.
func test_the_rhetorica_is_the_first_zone_of_rome() -> void:
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	var zones: Array = RomeMap.data()["zones"]
	check(zones.size() >= 8, "Rome is laid out in zones (%d)" % zones.size())
	check_eq(zones.filter(func(z): return z["opens_with"] != null).map(func(z): return z["id"]), ["palatine_forum"],
		"only the Forum under the Palatine is open, with the Rhetorica")
	check_eq(Rooms.room("rhetorica-ad-herennium").get("rome_zone", ""), "palatine_forum", "the room knows its zone")
	check(RomeMap.data()["wall"]["gates"].size() >= 12, "the Servian wall has its gates")
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}}
	hall.travel("rhetorica-ad-herennium")
	var outline: Array = RomeMap.outline("palatine_forum")
	var outside: Array = hall.interactables.filter(func(i): return not RomeMap.inside(outline, i["pos"]))
	check(outside.is_empty(), "everything to do stands inside the zone: %s" % str(outside.map(func(i): return i.get("text", ""))))
	check(RomeMap.inside(outline, hall.player.position), "you arrive inside it")
	check(not RomeMap.inside(outline, RomeMap.landmark("circus_maximus")), "the Circus Maximus is beyond it, not yet open")
	hall.free()


## The Rhetorica has left Greece for Rome: it is not on the Shore or among the Nexus's columns, but
## the first book of Rome's own reading list, in the Rome world.
func test_the_rhetorica_is_rome_s_book() -> void:
	check(not Rooms.doors().any(func(d): return d["work"] == "rhetorica-ad-herennium"), "not a Greek door")
	var rome := Rooms.doors_of("rome")
	check_eq(rome.map(func(d): return d["work"]), ["rhetorica-ad-herennium"], "Rome's reading list begins with it")
	check_eq(Rooms.room("rhetorica-ad-herennium").get("world", ""), "rome", "its room is in the Rome world")
	check(Rooms.doors().any(func(d): return d["work"] == "porphyry-isagoge"), "the Isagoge stays in Greece")


## The city of Rome is the Rome world's hub: the whole city, paved in brick with no grass, full of
## people who talk, its monuments telling their stories, the Rhetorica's gateway in the Forum, and
## the navel of the city letting the years pass through its four ages to the emptied city and back.
func test_rome_is_a_city_that_lives_through_its_ages() -> void:
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	var Tex: GDScript = load("res://scripts/hall/textures.gd")
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}}
	hall.travel("urbs")
	check_eq(hall.here, "urbs", "the city is a place of its own")
	check_eq(hall._world_of("urbs"), "rome", "in the Rome world")
	check_eq(hall.rome_age(), 0, "it begins in the Republic")
	check(hall.here_name.contains("50 BC"), "the corner says when: %s" % hall.here_name)
	var gate: Array = hall.interactables.filter(func(i): return i["kind"] == "gate" and i["to"] == "rhetorica-ad-herennium")
	check(gate.size() == 1 and gate[0]["open"], "the Rhetorica's gateway is open")
	check(RomeMap.inside(RomeMap.outline("palatine_forum"), gate[0]["pos"]), "and it stands in the Rhetorica's zone")
	var people_then: int = hall.people.size()
	check(people_then >= 120, "the Republic's streets are full (%d people)" % people_then)
	var talkers: Array = hall.interactables.filter(func(i): return i["kind"] == "person")
	check(talkers.size() >= 60, "and they talk (%d)" % talkers.size())
	check(talkers.all(func(i): return str(i["note"]).length() > 10), "every one of them has something to say")
	check(hall.interactables.filter(func(i): return i["kind"] == "statue").size() >= 25, "the monuments tell their stories")
	var ground: Array = hall.world.find_children("Ground", "MeshInstance3D", true, false)
	check(ground.size() == 1 and ground[0].material_override == Tex.material("cobble"), "the ground is the city's brick paving")
	check(not hall.regions.is_empty(), "the city has its regions")
	var navel: Dictionary = hall.interactables.filter(func(i): return i["kind"] == "rome_age")[0]
	var names: Array = [hall.here_name]
	for k in 3:
		hall.activate(hall.interactables.filter(func(i): return i["kind"] == "rome_age")[0])
		names.append(hall.here_name)
		check_eq(hall.here, "urbs", "still in the city after the years pass")
	check_eq(hall.rome_age(), 3, "through the Empire and the late Empire to the fall")
	check(names[1].contains("150") and names[2].contains("330") and names[3].contains("552"), "each age says its year: %s" % str(names))
	check(hall.people.size() < people_then / 3, "the emptied city has few people left (%d)" % hall.people.size())
	var fallen: Array = hall.world.find_children("Ground", "MeshInstance3D", true, false)
	check(fallen.size() == 1 and fallen[0].material_override == Tex.material("rubble"), "its ground is rubble")
	hall.activate(hall.interactables.filter(func(i): return i["kind"] == "rome_age")[0])
	check_eq(hall.rome_age(), 0, "and the navel brings you back to the Republic")
	check(navel["note"] != "", "the navel says what it is")
	hall.travel("rhetorica-ad-herennium")
	check_eq(hall.here, "rhetorica-ad-herennium", "through the gateway, the Rhetorica's Forum")
	check(hall.interactables.any(func(i): return i["kind"] == "gate" and i["to"] == "urbs"), "and a way back into the city")
	hall.free()


## Each monument stands from the year it was built, as a ruin from its fall, and is gone after.
func test_the_monuments_keep_their_years() -> void:
	var RomeMap: GDScript = load("res://scripts/hall/rome_map.gd")
	var by_id := {}
	for m in RomeMap.city_data()["monuments"]:
		by_id[m["id"]] = m
	for want in ["saturn", "jupiter", "venus_genetrix", "mars_ultor", "venus_roma", "mars_in_circo", "castor", "vesta", "concord",
			"colosseum", "pantheon", "trajan_column", "caracalla_baths", "lateran", "st_peter", "circus", "pompey"]:
		check(by_id.has(want), "Rome has %s" % want)
	check_eq(RomeMap.state(by_id["colosseum"], -50), "", "no Colosseum in the Republic")
	check_eq(RomeMap.state(by_id["colosseum"], 150), "whole", "the Colosseum under the Antonines")
	check_eq(RomeMap.state(by_id["colosseum"], 552), "ruin", "and cracked by 552")
	check_eq(RomeMap.state(by_id["curia_hostilia"], 150), "gone", "the old Senate House is gone under the emperors")
	check_eq(RomeMap.state(by_id["lateran"], 150), "", "no churches before Constantine")
	check_eq(RomeMap.state(by_id["lateran"], 552), "whole", "the Lateran stands in the emptied city")
	for m in RomeMap.city_data()["monuments"]:
		check(int(m.get("ruin", 9999)) > int(m["from"]) and int(m.get("gone", 9999)) > int(m["from"]), "%s falls after it is built" % m["id"])


## Every beat of every new place can be played to its end, and in Zen each counts its point.
func test_every_beat_of_the_new_places_plays_to_its_end() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	for work in NEW_PLACES:
		hall.progress.data = {"works": {}}
		hall.progress.set_mode("greece", "zen")
		hall.progress.set_mode("rome", "zen")
		hall.travel(work)
		var beats: Array = hall.interactables.filter(func(i): return i["kind"] == "beat")
		for k in beats.size():
			var it: Dictionary = hall.interactables.filter(func(i): return i["kind"] == "beat")[k]  # the place is rebuilt as it mends
			if it.has("needs_city"):
				continue  # played once the city is far enough on (test_the_city_in_speech_is_governed_at_the_academy)
			check(_play_through(hall, it) >= 0, "%s/%s plays to its end" % [work, it["beat"]])
			hall._close_panels()
			if it.has("id"):
				check(hall.progress.understood(work).has(it["id"]), "%s/%s counts '%s'" % [work, it["beat"], it["id"]])
	hall.free()


## The Odyssey's voyage: from every landing the black ship sails to every other, and you step
## ashore on each island; at the edge of Ocean the dead come for the blood while you are near.
func test_the_black_ship_sails_home_by_every_island() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	hall.progress.data = {"works": {}}
	hall.travel("homer-the-iliad")
	var sea: Dictionary = load("res://scripts/hall/places_greek.gd").SEA
	var ferries: Array = hall.interactables.filter(func(i): return i["kind"] == "ferry")
	check_eq(ferries.size(), sea.size() * (sea.size() - 1), "from each landing, a way to each of the others")
	for leg in [["troy", "cyclops"], ["cyclops", "sirens"], ["sirens", "ocean"], ["ocean", "ithaca"], ["ithaca", "troy"]]:
		var take: Dictionary = ferries.filter(func(i): return i["from"] == leg[0] and i["to"] == leg[1])[0]
		hall.activate(take)
		for k in 200:
			hall._animate_boats(0.5)
		var there: Vector3 = sea[leg[1]]["at"]
		check(take["boat"]["root"].position.distance_to(there) < 0.1, "it sails from %s to %s" % leg)
		hall.stand_up()
		check(not hall.player.seated, "you step ashore at %s" % leg[1])
	var c: Dictionary = hall.creep[0]
	var before: float = c["node"].global_position.distance_to(c["trench"])
	hall.player.position = c["trench"] + Vector3(0, 0.05, 8.0)
	for k in 20:
		hall._animate_creep(0.5)
	check(c["node"].global_position.distance_to(c["trench"]) < before, "the dead come toward the blood while you are near")
	hall.free()
