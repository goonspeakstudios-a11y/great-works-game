extends Node
## The author as a teacher. Each thing the player says goes to Claude Haiku 4.5 (the cheap
## model) with the author's lesson plan, what the player already understands, and the
## passages of the author's own book that match (citations on, so the answer quotes the
## real text). After each reply, a second small call checks which lesson points the player
## has now shown they understand, in their own words. About half a cent per exchange.
## The API key is read from the ANTHROPIC_API_KEY environment variable or from
## user://secrets.cfg ([anthropic] api_key = "..."), never from the project folder.

signal answered(reply: Dictionary)
signal judged(work: String, understood: Array)

const MODEL := "claude-haiku-4-5"
const URL := "https://api.anthropic.com/v1/messages"
const MAX_TOKENS := 350
const JUDGE_TOKENS := 200
const PASSAGES := 4
const KEEP_EXCHANGES := 4
const SECRETS := "user://secrets.cfg"
## Sent right after the question, where the model heeds it most.
const BRIEF := "(Answer in two or three short, plain sentences: 60 words at most.)"
const RULES := """How to speak:
- Speak as yourself, in the first person, warm and a little weary, like an old teacher at the end of a long day.
- Use plain, simple words a twelve-year-old could follow. One everyday example helps.
- Keep it short: two or three short sentences, at most 60 words. No greeting or scene-setting. Plain text only: no lists, headings, asterisks or other formatting.
- The visitor is a stranger from a much later age who has come to learn from you. Don't call them by a name.
- Base what you say on the passages from your book given with each message, and cite them. Explain them in your own simple words; don't repeat the old translation's wording, since the visitor sees the quotes separately.
- If those passages don't cover it, say so plainly and give only the simple gist you are sure of. Never invent a quotation.
- If asked about things beyond your book, your life and your times, say kindly that it is outside what you wrote, and steer back to the lesson."""
const TEACHING := """You are this visitor's teacher. Your goal is that they walk away truly understanding every point below, in plain words:
%s

Already understood: %s
Still to teach: %s
This is their visit number %d.

How to teach:
- Answer what they ask first, briefly.
- Then lead gently toward the first point still to teach. One point at a time, with one everyday example.
- Use the things in your study when they help: your tree carved on the wall, the busts of Aristotle and Plotinus, the map of the world.
- After you explain a point, ask them to put it in their own words, for example: "Tell me in your own words: what is a genus?" Or ask them for an example of their own. If they get it, tell them warmly. If not, explain it another way. Never grade them or lecture.
- If they seem lost, go simpler. If they say "next", move on.
- When every point is understood, tell them warmly that they have it all, and say a fond goodbye."""
const JUDGE := """You check a student's understanding for their teacher. Judge ONLY the student's latest message.
List the ids of the lesson points that this message itself states correctly in the student's own words, or shows with a correct example of their own.
If the message is a request ("teach me", "next"), a question, or a short agreement ("ok", "I see", "got it"), return an empty list.
Never count anything the teacher said. Being told something is not understanding it.

Lesson points:
%s

Already understood: %s"""

var histories := {}  # work -> [question, answer] pairs, newest last
var busy := false
var _http: HTTPRequest
var _judge_http: HTTPRequest
var _question := ""
var _work := ""
var _room := {}
var _understood: Array = []


static func api_key() -> String:
	var env := OS.get_environment("ANTHROPIC_API_KEY")
	if env != "":
		return env
	var cfg := ConfigFile.new()
	if cfg.load(SECRETS) == OK:
		return str(cfg.get_value("anthropic", "api_key", ""))
	return ""


static func _labels(room: Dictionary, ids: Array, want: bool) -> String:
	var out: Array = []
	for p in room.get("lesson", []):
		if ids.has(p["id"]) == want:
			out.append(p["label"])
	return ", ".join(out) if not out.is_empty() else "none"


static func build_request(room: Dictionary, passages: Array, question: String, past: Array,
		understood: Array = [], visit: int = 1) -> Dictionary:
	var system := "%s\n\nYour book, in brief: %s\n\n%s" % [room["persona"], room["summary"], RULES]
	if room.has("lesson"):
		var points := "\n".join(room["lesson"].map(func(p): return "- %s: %s" % [p["label"], p["point"]]))
		system += "\n\n" + TEACHING % [points, _labels(room, understood, true), _labels(room, understood, false), visit]
	var messages: Array = []
	for pair in past.slice(maxi(0, past.size() - KEEP_EXCHANGES)):
		messages.append({"role": "user", "content": pair[0]})
		messages.append({"role": "assistant", "content": pair[1]})
	var content: Array = []
	for p in passages:
		content.append({
			"type": "document",
			"source": {"type": "text", "media_type": "text/plain", "data": p["text"]},
			"title": p["where"],
			"citations": {"enabled": true},
		})
	content.append({"type": "text", "text": question})
	content.append({"type": "text", "text": BRIEF})
	messages.append({"role": "user", "content": content})
	return {"model": MODEL, "max_tokens": MAX_TOKENS, "system": system, "messages": messages}


## Worth checking at all? Requests and short replies can't show understanding (and cost nothing to skip).
static func worth_judging(student_line: String) -> bool:
	var line := student_line.to_lower().strip_edges()
	for opener in ["teach me", "ok", "okay", "yes", "yeah", "i see", "i think i get", "got it", "sure", "next"]:
		if line.begins_with(opener):
			return false
	return line.split(" ", false).size() >= 6


## A small follow-up call: does the student's latest message show they understand any point?
static func build_judge_request(room: Dictionary, student_line: String, teacher_before: String, understood: Array) -> Dictionary:
	var lesson: Array = room.get("lesson", [])
	var points := "\n".join(lesson.map(func(p): return "- %s: %s" % [p["id"], p["point"]]))
	var talk := "The teacher had just said (context only, never counts): %s\n\nThe student's latest message (judge only this): %s" % [
		teacher_before if teacher_before != "" else "(nothing yet)", student_line]
	return {
		"model": MODEL,
		"max_tokens": JUDGE_TOKENS,
		"system": JUDGE % [points, ", ".join(understood) if not understood.is_empty() else "none"],
		"messages": [{"role": "user", "content": talk}],
		"output_config": {"format": {"type": "json_schema", "schema": {
			"type": "object",
			"properties": {"understood": {"type": "array", "items": {"type": "string",
				"enum": lesson.map(func(p): return p["id"])}}},
			"required": ["understood"],
			"additionalProperties": false,
		}}},
	}


static func parse_judgement(data: Dictionary, room: Dictionary) -> Array:
	var valid: Array = room.get("lesson", []).map(func(p): return p["id"])
	for block in data.get("content", []):
		if block is Dictionary and block.get("type", "") == "text":
			var json := JSON.new()  # quietly ignores a garbled answer
			if json.parse(str(block.get("text", ""))) == OK and json.data is Dictionary and json.data.get("understood") is Array:
				return json.data["understood"].filter(func(id): return valid.has(id))
	return []


## Turns the API's reply into what the player sees: the answer, and the quotes it rests on.
static func parse_reply(data: Dictionary) -> Dictionary:
	if data.get("stop_reason", "") == "refusal":
		return {"text": "I would rather not speak of that. Ask me about my book.", "quotes": [], "error": ""}
	var text := ""
	var quotes: Array = []
	var seen := {}
	var blocks: Variant = data.get("content", [])
	for block in (blocks if blocks is Array else []):
		if not block is Dictionary or block.get("type", "") != "text":
			continue
		text += str(block.get("text", ""))
		var cites: Variant = block.get("citations", [])
		for c in (cites if cites is Array else []):
			var q := str(c.get("cited_text", "")).strip_edges()
			if q != "" and not seen.has(q):
				seen[q] = true
				quotes.append({"text": q, "where": str(c.get("document_title", ""))})
	text = text.replace("*", "").strip_edges()  # no markdown in the game's text
	if text == "":
		return {"text": "", "quotes": [], "error": "I have nothing to say to that. Try asking another way."}
	return {"text": text, "quotes": quotes, "error": ""}


func history_for(work: String) -> Array:
	return histories.get(work, [])


## Keeps a question and its answer for follow-ups, unless the answer failed or was empty.
func remember(work: String, question: String, reply: Dictionary) -> void:
	if reply["error"] != "" or str(reply["text"]).strip_edges() == "":
		return
	if not histories.has(work):
		histories[work] = []
	histories[work].append([question, reply["text"]])


func ask(work: String, room: Dictionary, book: RefCounted, question: String, understood: Array = [],
		visit: int = 1) -> void:
	if busy:
		return
	if book == null or not room.has("persona") or not room.has("summary"):
		_reply(work, question, {"text": "", "quotes": [], "error": "My room isn't finished yet, so I can't answer from my book."})
		return
	var key := api_key()
	if key == "":
		_reply(work, question, {"text": "", "quotes": [], "error": "I can't speak yet: no API key was found. See the README."})
		return
	if _http == null:
		_http = _new_http(_on_done)
		_judge_http = _new_http(_on_judged)
	var body := build_request(room, book.search(question, PASSAGES), question, history_for(work), understood, visit)
	busy = true
	_question = question
	_work = work
	_room = room
	_understood = understood.duplicate()
	var err := _http.request(URL, _headers(key), HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		busy = false
		_reply(work, question, {"text": "", "quotes": [], "error": "My voice is lost in the fog (could not send, error %d)." % err})


func _new_http(done: Callable) -> HTTPRequest:
	var h := HTTPRequest.new()
	h.timeout = 45.0
	h.request_completed.connect(done)
	add_child(h)
	return h


static func _headers(key: String) -> PackedStringArray:
	return PackedStringArray(["content-type: application/json", "x-api-key: " + key, "anthropic-version: 2023-06-01"])


func _on_done(result: int, code: int, _headers_in: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		_reply(_work, _question, {"text": "", "quotes": [], "error": "My voice is lost in the fog. Is the internet reachable? (result %d)" % result})
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if code != 200 or not data is Dictionary:
		var why := "status %d" % code
		if data is Dictionary and data.has("error"):
			why = str(data["error"].get("message", why))
		push_warning("Author request failed: " + why)
		_reply(_work, _question, {"text": "", "quotes": [], "error": "Something went wrong reaching me (%s)." % why})
		return
	var reply := parse_reply(data)
	if data.get("stop_reason", "") != "refusal":
		remember(_work, _question, reply)
	_reply(_work, _question, reply)
	if reply["error"] == "" and _room.has("lesson") and worth_judging(_question):
		var past := history_for(_work)
		var before: String = past[past.size() - 2][1] if past.size() >= 2 else ""
		var judge := build_judge_request(_room, _question, before, _understood)
		if _judge_http.request(URL, _headers(api_key()), HTTPClient.METHOD_POST, JSON.stringify(judge)) != OK:
			push_warning("Could not send the understanding check")


func _on_judged(result: int, code: int, _headers_in: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("Understanding check failed (result %d, status %d)" % [result, code])
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary:
		judged.emit(_work, parse_judgement(data, _room))


## Every answer says which author and question it belongs to, so the panel can't mix them up.
func _reply(work: String, question: String, reply: Dictionary) -> void:
	reply["work"] = work
	reply["question"] = question
	answered.emit(reply)
