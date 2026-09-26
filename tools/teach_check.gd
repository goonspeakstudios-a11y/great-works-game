extends SceneTree
## Play a short lesson with an author from the command line, the way the game does:
## each student line gets the teacher's reply, then the understanding check.
## About a cent per line (Claude Haiku 4.5). Nothing is saved.
## godot --headless --path . --script res://tools/teach_check.gd -- porphyry-isagoge "Teach me the next thing" "..."

const AuthorAI := preload("res://scripts/hall/author_ai.gd")
const Library := preload("res://scripts/hall/library.gd")
const Rooms := preload("res://scripts/hall/rooms.gd")

var _author: Node
var _work := ""
var _lines: Array = []
var _understood: Array = []
var _waiting_judge := false
var _last_line := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_work = args[0] if args.size() > 0 else "porphyry-isagoge"
	_lines = Array(args.slice(1)) if args.size() > 1 else ["Teach me the next thing"]
	_author = AuthorAI.new()
	root.add_child(_author)
	_author.answered.connect(_on_answer)
	_author.judged.connect(_on_judged)
	_next.call_deferred()


func _next() -> void:
	if _lines.is_empty():
		print("UNDERSTOOD NOW: ", _understood)
		quit(0)
		return
	var line: String = _lines.pop_front()
	_last_line = line
	print("\nSTUDENT: ", line)
	_author.ask(_work, Rooms.room(_work), Library.load_book(_work), line, _understood, 1)


func _on_answer(reply: Dictionary) -> void:
	print(Rooms.room(_work)["author"].to_upper(), ": ", reply["text"] if reply["error"] == "" else "ERROR " + reply["error"])
	_waiting_judge = reply["error"] == "" and AuthorAI.worth_judging(_last_line)
	if not _waiting_judge:
		_next.call_deferred()


func _on_judged(_w: String, ids: Array) -> void:
	for id in ids:
		if not _understood.has(id):
			_understood.append(id)
	print("   check -> understood: ", ids)
	_next.call_deferred()
