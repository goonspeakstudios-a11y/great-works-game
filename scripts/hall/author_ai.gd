extends Node
## The author you can talk to. Each question goes to Claude Haiku 4.5 (the cheap model)
## together with the passages of the author's own book that match it, with citations on,
## so the answer quotes the real text. Costs about half a cent per question.
## The API key is read from the ANTHROPIC_API_KEY environment variable or from
## user://secrets.cfg ([anthropic] api_key = "..."), never from the project folder.

signal answered(reply: Dictionary)

const MODEL := "claude-haiku-4-5"
const URL := "https://api.anthropic.com/v1/messages"
const MAX_TOKENS := 500
const PASSAGES := 4
const KEEP_EXCHANGES := 2
const SECRETS := "user://secrets.cfg"
const RULES := """How to answer:
- Speak as yourself, in the first person, warm and a little weary, like an old teacher in a quiet ruin.
- Use plain, simple words a twelve-year-old could follow. One everyday example helps.
- Keep it short: two to five sentences, never more than 100 words. Plain text only: no lists, headings, asterisks or other formatting.
- The visitor is a stranger from a much later age, not one of your students. Don't call them by a name.
- Base what you say on the passages from your book given with the question, and cite them.
- If those passages don't cover it, say so plainly and give only the simple gist you are sure of. Never invent a quotation.
- If asked about things beyond your book, your life and your times, say kindly that it is outside what you wrote, and steer back to the book."""

var history: Array = []  # [question, answer] pairs, newest last
var busy := false
var _http: HTTPRequest
var _question := ""


static func api_key() -> String:
	var env := OS.get_environment("ANTHROPIC_API_KEY")
	if env != "":
		return env
	var cfg := ConfigFile.new()
	if cfg.load(SECRETS) == OK:
		return str(cfg.get_value("anthropic", "api_key", ""))
	return ""


static func build_request(room: Dictionary, passages: Array, question: String, past: Array) -> Dictionary:
	var system := "%s\n\nYour book, in brief: %s\n\n%s" % [room["persona"], room["summary"], RULES]
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
	messages.append({"role": "user", "content": content})
	return {"model": MODEL, "max_tokens": MAX_TOKENS, "system": system, "messages": messages}


## Turns the API's reply into what the player sees: the answer, and the quotes it rests on.
static func parse_reply(data: Dictionary) -> Dictionary:
	if data.get("stop_reason", "") == "refusal":
		return {"text": "I would rather not speak of that. Ask me about my book.", "quotes": [], "error": ""}
	var text := ""
	var quotes: Array = []
	var seen := {}
	for block in data.get("content", []):
		if block.get("type", "") != "text":
			continue
		text += str(block.get("text", ""))
		for c in block.get("citations", []):
			var q := str(c.get("cited_text", "")).strip_edges()
			if q != "" and not seen.has(q):
				seen[q] = true
				quotes.append({"text": q, "where": str(c.get("document_title", ""))})
	return {"text": text.strip_edges(), "quotes": quotes, "error": ""}


func ask(room: Dictionary, book: RefCounted, question: String) -> void:
	if busy:
		return
	var key := api_key()
	if key == "":
		answered.emit({"text": "", "quotes": [], "error": "I can't speak yet: no API key was found. See the README."})
		return
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 45.0
		_http.request_completed.connect(_on_done)
		add_child(_http)
	busy = true
	_question = question
	var body := build_request(room, book.search(question, PASSAGES), question, history)
	var headers := PackedStringArray(["content-type: application/json", "x-api-key: " + key,
		"anthropic-version: 2023-06-01"])
	var err := _http.request(URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		busy = false
		answered.emit({"text": "", "quotes": [], "error": "My voice is lost in the fog (could not send, error %d)." % err})


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		answered.emit({"text": "", "quotes": [], "error": "My voice is lost in the fog. Is the internet reachable? (result %d)" % result})
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if code != 200 or not data is Dictionary:
		var why := "status %d" % code
		if data is Dictionary and data.has("error"):
			why = str(data["error"].get("message", why))
		push_warning("Author request failed: " + why)
		answered.emit({"text": "", "quotes": [], "error": "Something went wrong reaching me (%s)." % why})
		return
	var reply := parse_reply(data)
	history.append([_question, reply["text"]])
	answered.emit(reply)
