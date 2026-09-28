extends RefCounted
## A scene in the city of Rome: one of its rites, trades, choices or played moments, written as a
## list of steps in content/rome (rites.json, sacred.json, trades.json, scenes.json) and played in
## the activity panel (urbs_panel.gd). The same engine plays the vote in every age, a day at the
## baker's oven, the sacrifice done word for word, and Scaevola's hand in the fire.
##
## Steps (each a dictionary with one of these keys):
##   {"say": text}                             a line; F goes on
##   {"ask": text, "options": [option...]}     a choice; every option can cost (see below)
##   {"rite": text, "order": [acts], "wrong": [acts], "strict": bool, "restart": text, "slack": text, "done": text}
##                                             each act of a rite in its order, picked from three;
##                                             a slip and (strict) it all begins again, as the Romans did
##   {"hold": text, "secs": n, "done": text}   hold F
##   {"still": text, "secs": n, "broke": text} do nothing at all for n seconds (a key pressed begins it again)
##   {"timing": text, "hits": n, "speed": s, "zone": w, "miss": text, "done": text}
##                                             a mark swings along a bar: F while it is in the zone
##   {"type": text, "secs": n}                 copy the words out
##   {"pick": question, "options": [...], "right": k, "yes": text, "no": text}
##                                             a question with one right answer
##   {"pay": n, "else": label}                 a price as in 280 BC (Standing.price); not enough: go to else
##   {"gain": effects, "line": text}           effects (Standing.apply)
##   {"wage": n, "per": m}                     a day's pay (as in 280 BC), m more for each point scored
##   {"if": condition, "to": label}            Standing.has, or {score, restarts, random, won}
##   {"play": game, "opts": {}, "win": label, "lose": label, "line": text}   a game at the table (urbs_games.gd)
##   {"label": name} / {"go": name}            a place in the steps, and a jump to it
##   {"hour": h}                               the scene ends at this hour of the day (sleep, waiting)
##   {"end": text}                             the end
## An option: {"text", "say": what follows, "then": label, "need": condition, + effects (fides, coin,
## dignitas, pay, earn, ledger, ledger_key, give, take, collect, once, class)}.

const KINDS := ["say", "ask", "rite", "hold", "still", "timing", "type", "pick", "pay", "gain", "wage", "if", "play",
	"label", "go", "hour", "end"]
const WAITS := ["say", "ask", "rite", "hold", "still", "timing", "type", "pick", "play"]

var id := ""
var title := ""
var where := ""
var steps: Array = []
var labels := {}
var standing: RefCounted  # urbs_standing.gd
var i := -1
var done := false
var score := 0
var restarts := 0
var won := false
var hour := -1.0  # the hour the scene ends at, if it moves the day on
var lines: Array = []  # everything said so far, oldest first
var game := {}  # the game the scene waits on: {game, opts}
var rng := RandomNumberGenerator.new()
var _rite_at := 0
var _rite_opts: Array = []
var _held := 0.0
var _still := 0.0
var _broke := false
var _bar := 0.0
var _dir := 1.0
var _zone := Vector2(0.4, 0.6)
var _hits := 0
var _tries := 0
var _t := 0.0


## Every scene written for Rome: {id: def} from all its files.
static func all() -> Dictionary:
	var out := {}
	for f: String in ["rites", "sacred", "trades", "scenes", "exempla"]:
		var path := "res://content/rome/%s.json" % f
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			push_error("%s does not parse" % path)
			continue
		var scenes: Variant = (parsed as Dictionary).get("scenes", {})
		if scenes is Dictionary:
			out.merge(scenes)
	return out


static func problems(def: Dictionary) -> Array:
	var out: Array = []
	var st: Array = def.get("steps", [])
	if st.is_empty():
		return ["no steps"]
	var names := {}
	for s: Dictionary in st:
		if s.has("label"):
			names[s["label"]] = true
	var ends := 0
	for s: Dictionary in st:
		var kinds: Array = KINDS.filter(func(k: String) -> bool: return s.has(k))
		if kinds.size() != 1:
			out.append("a step must be exactly one of the kinds: %s" % str(s).left(80))
			continue
		var k: String = kinds[0]
		if k == "end":
			ends += 1
		for key: String in ["go", "to", "else", "win", "lose"]:
			if s.has(key) and not names.has(str(s[key])):
				out.append("no label %s" % s[key])
		if k == "if" and not s.has("to"):
			out.append("an if goes nowhere: %s" % str(s).left(60))
		if k == "ask":
			var opts: Array = s.get("options", [])
			if opts.is_empty() or opts.size() > 4:
				out.append("a choice needs one to four options: %s" % str(s["ask"]).left(40))
			for o: Dictionary in opts:
				if not o.has("text"):
					out.append("an option without words")
				if o.has("then") and not names.has(str(o["then"])):
					out.append("no label %s" % o["then"])
		if k == "rite" and (s.get("order", []) as Array).size() < 2:
			out.append("a rite needs its acts in order")
		if k == "pick" and int(s.get("right", -1)) >= (s.get("options", []) as Array).size():
			out.append("a question's right answer is not among its options")
	if ends == 0:
		out.append("no end")
	return out


func _init(def: Dictionary, scene_id: String, the_standing: RefCounted, seed_value: int = 0) -> void:
	id = scene_id
	title = str(def.get("title", ""))
	where = str(def.get("where", ""))
	steps = def.get("steps", [])
	standing = the_standing
	rng.seed = seed_value if seed_value != 0 else hash(scene_id) + Time.get_ticks_msec()
	for k in steps.size():
		if (steps[k] as Dictionary).has("label"):
			labels[steps[k]["label"]] = k


func start() -> void:
	i = -1
	done = false
	_advance()


func current() -> Dictionary:
	return steps[i] if i >= 0 and i < steps.size() else {}


func kind() -> String:
	var s := current()
	for k: String in KINDS:
		if s.has(k):
			return k
	return ""


func _fill(text: String) -> String:
	return standing.fill(text) if standing else text


func _say(text: String) -> void:
	if text != "":
		lines.append(_fill(text))


## Goes to the next step (or a label's), running the steps that need nothing from you.
func _advance(to: String = "") -> void:
	if to != "":
		if not labels.has(to):
			push_error("scene %s: no label %s" % [id, to])
			done = true
			return
		i = int(labels[to])
	else:
		i += 1
	var guard := 0
	while not done and guard < 500:
		guard += 1
		if i >= steps.size():
			done = true
			return
		var s := current()
		var k := kind()
		_t = 0.0
		match k:
			"label":
				i += 1
				continue
			"go":
				i = int(labels.get(s["go"], steps.size()))
				continue
			"end":
				_say(str(s["end"]))
				done = true
				return
			"gain":
				_say(str(s.get("line", "")))
				_note(standing.apply(s["gain"]) if standing else "")
				i += 1
				continue
			"pay":
				var n := int(s["pay"])
				if standing and standing.has({"price": n}):
					_note(standing.apply({"pay": n}))
					i += 1
				elif s.has("else"):
					_say(str(s.get("short", "You haven't the money.")))
					i = int(labels[s["else"]])
				else:
					_say(str(s.get("short", "You haven't the money.")))
					i += 1
				continue
			"wage":
				var pay := int(s["wage"]) + int(s.get("per", 0)) * score
				_say(str(s.get("line", "")))
				_note(standing.apply({"earn": pay}) if standing else "")
				i += 1
				continue
			"if":
				i = int(labels[s["to"]]) if test(s["if"]) else i + 1
				continue
			"hour":
				hour = float(s["hour"])
				i += 1
				continue
			"say":
				_say(str(s["say"]))
			"ask":
				_say(str(s["ask"]))
			"pick":
				_say(str(s["pick"]))
			"rite":
				_say(str(s["rite"]))
				_rite_at = 0
				_rite_opts = _rite_choices()
			"hold":
				_say(str(s["hold"]))
				_held = 0.0
			"still":
				_say(str(s["still"]))
				_still = 0.0
				_broke = false
			"timing":
				_say(str(s["timing"]))
				_hits = 0
				_tries = 0
				_bar = 0.0
				_dir = 1.0
				_new_zone()
			"type":
				_say("Copy it out: \"%s\"" % s["type"])
			"play":
				_say(str(s.get("line", "")))
				game = {"game": str(s["play"]), "opts": s.get("opts", {})}
		return


func _note(line: String) -> void:
	if line != "":
		lines.append("(%s)" % line)


## A condition: the Standing's, or the scene's own {score, restarts, random, won, lost}.
func test(cond: Dictionary) -> bool:
	if cond.has("score") and score < int(cond["score"]):
		return false
	if cond.has("below_score") and score >= int(cond["below_score"]):
		return false
	if cond.has("restarts") and restarts < int(cond["restarts"]):
		return false
	if cond.has("random") and rng.randf() >= float(cond["random"]):
		return false
	if cond.has("won") and not won:
		return false
	if cond.has("lost") and won:
		return false
	var rest := cond.duplicate()
	for k: String in ["score", "below_score", "restarts", "random", "won", "lost"]:
		rest.erase(k)
	return rest.is_empty() or (standing != null and standing.has(rest))


## What the panel shows now: {kind, options: [text], enabled: [bool], hold, bar, zone, type, game}.
func view() -> Dictionary:
	var s := current()
	var k := kind() if not done else "end"
	var v := {"kind": k, "options": [], "enabled": []}
	match k:
		"say":
			v["options"] = ["Go on"]
			v["enabled"] = [true]
		"ask":
			for o: Dictionary in s.get("options", []):
				var ok: bool = not o.has("need") or standing == null or standing.has(o["need"])
				var t := _fill(str(o["text"]))
				if o.has("pay"):
					t += " (%s)" % standing.money(standing.price(int(o["pay"]))) if standing else ""
				v["options"].append(t)
				v["enabled"].append(ok)
		"pick":
			for o: Variant in s.get("options", []):
				v["options"].append(_fill(str(o)))
				v["enabled"].append(true)
		"rite":
			v["options"] = _rite_opts.duplicate()
			v["enabled"] = _rite_opts.map(func(_o: String) -> bool: return true)
		"hold":
			v["hold"] = clampf(_held / maxf(0.1, float(s.get("secs", 3.0))), 0.0, 1.0)
		"still":
			v["hold"] = clampf(_still / maxf(0.1, float(s.get("secs", 5.0))), 0.0, 1.0)
		"timing":
			v["bar"] = _bar
			v["zone"] = _zone
			v["hits"] = [_hits, int(s.get("hits", 3))]
		"type":
			v["type"] = str(s["type"])
		"play":
			v["game"] = game
	return v


## F (or Space): a line goes on; the swinging mark is stopped; stillness is broken.
func press() -> void:
	match kind():
		"say":
			_advance()
		"timing":
			_hit()
		"still":
			_break_still()


## A choice picked (options, a rite's acts, a question's answers).
func choose(k: int) -> void:
	var s := current()
	match kind():
		"say":
			_advance()
		"ask":
			var opts: Array = s.get("options", [])
			if k < 0 or k >= opts.size():
				return
			var o: Dictionary = opts[k]
			if o.has("need") and standing and not standing.has(o["need"]):
				return
			lines.append("> " + _fill(str(o["text"])))
			if o.has("pay") and standing and not standing.has({"price": int(o["pay"])}):
				_say("You haven't the money.")
				return
			_say(str(o.get("say", "")))
			var fx := o.duplicate()
			for key: String in ["text", "say", "then", "need"]:
				fx.erase(key)
			if standing and not fx.is_empty():
				_note(standing.apply(fx))
			_advance(str(o.get("then", "")))
		"pick":
			var opts: Array = s.get("options", [])
			if k < 0 or k >= opts.size():
				return
			lines.append("> " + _fill(str(opts[k])))
			if k == int(s.get("right", 0)):
				score += 1
				_say(str(s.get("yes", "Right.")))
			else:
				_say(str(s.get("no", "No.")))
			_advance()
		"rite":
			_rite_pick(k)


## Moment to moment: holding F, keeping still, the mark swinging.
func update(delta: float, holding: bool) -> void:
	if done:
		return
	_t += delta
	var s := current()
	match kind():
		"hold":
			_held = _held + delta if holding else maxf(0.0, _held - delta * 1.5)
			if _held >= float(s.get("secs", 3.0)):
				_say(str(s.get("done", "")))
				_advance()
		"still":
			if holding:
				_break_still()
				return
			_still += delta
			if _still >= float(s.get("secs", 5.0)):
				_say(str(s.get("done", "")))
				_advance()
		"timing":
			_bar += _dir * delta * float(s.get("speed", 1.0)) * (1.0 + 0.15 * _hits)
			if _bar >= 1.0:
				_bar = 1.0
				_dir = -1.0
			elif _bar <= 0.0:
				_bar = 0.0
				_dir = 1.0


func _break_still() -> void:
	_still = 0.0
	if not _broke:
		_broke = true
		_say(str(current().get("broke", "You moved. Begin again.")))


func _new_zone() -> void:
	var w := float(current().get("zone", 0.18))
	var c := rng.randf_range(w / 2.0 + 0.05, 1.0 - w / 2.0 - 0.05)
	_zone = Vector2(c - w / 2.0, c + w / 2.0)


func _hit() -> void:
	var s := current()
	var need := int(s.get("hits", 3))
	_tries += 1
	if _bar >= _zone.x and _bar <= _zone.y:
		_hits += 1
		score += 1
		var good: Array = s.get("good", [])
		if not good.is_empty():
			_say(str(good[(_hits - 1) % good.size()]))
	else:
		_say(str(s.get("miss", "Too soon, or too late.")))
	if _hits >= need or _tries >= need + int(s.get("spare", 2)):
		_say(str(s.get("done", "")))
		_advance()
	else:
		_new_zone()


## Your copy of the words: the nearer to the text (and the quicker), the better.
func typed(text: String) -> void:
	if kind() != "type":
		return
	var want := str(current()["type"])
	var same := similarity(text, want)
	var quick := _t <= float(current().get("secs", 40.0))
	var points := roundi(same * 4.0) + (1 if quick and same > 0.8 else 0)
	score += points
	lines.append("> " + text)
	if same > 0.95:
		_say(str(current().get("good", "A clean copy.")))
	elif same > 0.7:
		_say(str(current().get("fair", "Some slips. It will pass.")))
	else:
		_say(str(current().get("bad", "Full of mistakes. It will have to be done again.")))
	_advance()


## How alike two lines are (0 to 1), letter by letter, ignoring case.
static func similarity(a: String, b: String) -> float:
	a = a.strip_edges().to_lower()
	b = b.strip_edges().to_lower()
	if b == "":
		return 1.0 if a == "" else 0.0
	var n := a.length()
	var m := b.length()
	var row: Array = range(m + 1)
	for x in n:
		var prev: int = row[0]
		row[0] = x + 1
		for y in m:
			var keep: int = row[y + 1]
			row[y + 1] = mini(mini(row[y + 1] + 1, row[y] + 1), prev + (0 if a[x] == b[y] else 1))
			prev = keep
	return clampf(1.0 - float(row[m]) / float(maxi(n, m)), 0.0, 1.0)


## The game at the table is over.
func game_over(did_win: bool, line: String = "") -> void:
	if kind() != "play":
		return
	won = did_win
	game = {}
	_say(line)
	var s := current()
	var to := str(s.get("win", "")) if did_win else str(s.get("lose", ""))
	_advance(to)


## The three acts offered at each moment of a rite: the right one, and two wrong (often a later
## act done too soon, the commonest slip).
func _rite_choices() -> Array:
	var s := current()
	var order: Array = s["order"]
	var right: String = order[_rite_at]
	var pool: Array = (s.get("wrong", []) as Array).duplicate()
	for later: String in order.slice(_rite_at + 1):
		pool.append(later)
	pool = pool.filter(func(p: String) -> bool: return p != right)
	var out: Array = [right]
	while out.size() < 3 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	for k in range(out.size() - 1, 0, -1):  # shuffled
		var j := rng.randi() % (k + 1)
		var tmp: String = out[k]
		out[k] = out[j]
		out[j] = tmp
	return out


func _rite_pick(k: int) -> void:
	if k < 0 or k >= _rite_opts.size():
		return
	var s := current()
	var order: Array = s["order"]
	var picked: String = _rite_opts[k]
	lines.append("> " + picked)
	if picked == order[_rite_at]:
		_rite_at += 1
	elif s.get("strict", true):
		restarts += 1
		_say(str(s.get("restart", "A slip. The piper stops, and the rite begins again from the first word.")))
		_rite_at = 0
	else:
		_say(str(s.get("slack", "A slip. No one minds. No one is watching.")))
		_rite_at += 1
	if _rite_at >= order.size():
		_say(str(s.get("done", "")))
		_advance()
	else:
		_rite_opts = _rite_choices()
