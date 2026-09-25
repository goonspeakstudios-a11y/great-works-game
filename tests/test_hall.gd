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
	check_eq(content.size(), 5, "four passages plus the question")
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


func test_rooms_never_overlap() -> void:
	check(Hall.SECTION >= 2.0 * (Hall.ROOM_HALF + Hall.WALL), "neighbouring rooms fit side by side")


func test_every_fact_gets_its_own_plaque() -> void:
	var spots: Array = Hall.fact_spots(8, -10.0, 7.6, -5.0)
	var seen := {}
	for s in spots:
		seen[str(s)] = true
	check_eq(seen.size(), 8, "eight facts, eight places")


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


func test_hall_builds_without_errors() -> void:
	var hall: Node = Hall.new()
	hall.offline = true
	(Engine.get_main_loop() as SceneTree).root.add_child(hall)
	check(hall.interactables.size() >= 7, "the room has things to read and someone to ask")
	check(hall.interactables.any(func(i): return i["kind"] == "author"), "the author can be asked")
	hall.free()
