extends SceneTree
## Ask an author one question from the command line, the same way the game does.
## Costs a fraction of a cent per run (Claude Haiku 4.5).
## godot --headless --path . --script res://tools/ask_author.gd -- porphyry-isagoge "What is a genus?"

const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Library := preload("res://scripts/hall/library.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")

var _started := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var work := args[0] if args.size() > 0 else "porphyry-isagoge"
	var question := args[1] if args.size() > 1 else "What is your book about?"
	var author := AuthorAI.new()
	root.add_child(author)
	author.answered.connect(_on_answer)
	_started = Time.get_ticks_msec()
	print("Q: ", question)
	author.ask.call_deferred(Rooms.room(work), Library.load_book(work), question)  # once it is in the tree


func _on_answer(reply: Dictionary) -> void:
	print("(%.1f s)" % ((Time.get_ticks_msec() - _started) / 1000.0))
	if reply["error"] != "":
		print("ERROR: ", reply["error"])
	else:
		print("A: ", reply["text"])
		for q in reply["quotes"]:
			print("  QUOTE [", q["where"], "]: ", q["text"].left(200))
	quit(0 if reply["error"] == "" else 1)
