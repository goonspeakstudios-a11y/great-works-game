extends Control
## A game at the table, drawn inside the activity panel (urbs_panel.gd): the bones thrown, the
## boards and their men, the stall's haggling, the money changer's tray, the Circus from above.
## Moves by the mouse or the keys (shown along the bottom); the city answers after a moment.
## `ended` gives whether you won and a last line; the money (a stake, a price) is settled here,
## through the Standing, and what matters goes into the Ledger.

signal ended(won: bool, line: String)

const Games := preload("res://scripts/hall/urbs_games.gd")
const INK := Color("e8dcc0")
const GOLD := Color("e0b660")
const DIM := Color("8a8074")
const YOU := Color("f0e6d0")
const THEM := Color("7a3a2a")
const BOARD := Color("3a3024")

var kind := ""
var opts := {}
var standing: RefCounted
var game: RefCounted
var status := ""
var sub := ""  # a second line under the status
var finished := false
var rng := RandomNumberGenerator.new()
var _buttons: HBoxContainer
var _wait := 0.0  # the city thinks before it moves
var _pick := -1  # a selected man or point
var _cursor := 0
var _die := -1
var _steer := 0.0
var _bet := -1
var _stake := 0
var _selected_coin := 0
var _done_at := -1.0
var _t := 0.0


func begin(what: String, the_opts: Dictionary, the_standing: RefCounted) -> void:
	kind = what
	opts = the_opts
	standing = the_standing
	rng.seed = int(the_opts.get("seed", Time.get_ticks_usec() % 100000 + 1))
	_stake = standing.price(int(opts.get("stake", 0))) if standing else int(opts.get("stake", 0))
	_buttons = HBoxContainer.new()
	_buttons.position = Vector2(0, size.y - 22)
	_buttons.size = Vector2(size.x, 22)
	_buttons.add_theme_constant_override("separation", 4)
	add_child(_buttons)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var s := rng.randi()
	match kind:
		"tali":
			game = Games.Tali.new(s)
			status = "First to three rounds. The stake: %s." % _money(_stake)
			_set_buttons([["Throw", _tali.bind(false)], ["Throw your own bones (loaded)", _tali.bind(true)]])
		"terni":
			game = Games.Terni.new(s)
			status = "Three stones each. Put them down, then move them one step along a line. Three in a row wins."
			sub = "Click a point (or keys 1-9). Stake: %s." % _money(_stake)
		"latrunculi":
			game = Games.Latrunculi.new(s)
			status = "Your soldiers move straight, as far as they like. Shut an enemy in between two of yours and he's taken."
			sub = "Click a man, then where he goes (or arrows and F). Stake: %s." % _money(_stake)
		"duodecim":
			game = Games.Duodecim.new(s)
			(game as RefCounted).roll()
			status = "Five men each round the three lines. Pick a die (1-3), then a man (arrows, F, or click)."
			sub = "Stake: %s." % _money(_stake)
		"haggle":
			var buying: bool = opts.get("buying", true)
			var worth: int = standing.price(int(opts.get("value", 4))) if standing else int(opts.get("value", 4))
			game = Games.Haggle.new(buying, worth, standing.fides() if standing else 0, s)
			_haggle_buttons()
			status = ("%s. They want %s." if buying else "%s. They offer %s.") % [str(opts.get("item", "It")).capitalize(), _money(game.ask)]
		"changer":
			game = Games.Changer.new(standing.age if standing else "republic", s)
			status = "Six coins on the tray: %ss, which should be %s." % [game.name, game.fineness]
			sub = "Pick a coin (arrows or click), test it, then take it or refuse it."
			_set_buttons([["Ring it", _coin.bind("ring")], ["Weigh it", _coin.bind("weigh")], ["Cut it", _coin.bind("cut")],
				["Take it", _coin.bind("take")], ["Refuse it", _coin.bind("refuse")]])
		"race":
			var fixed := int(opts.get("fixed", -1))
			game = Games.Race.new(bool(opts.get("drive", false)), int(opts.get("laps", 7)), s, fixed)
			if opts.get("bet", false):
				status = "Who do you back? The stake: %s." % _money(_stake)
				var bets: Array = []
				for k in 4:
					bets.append(["The %s" % Games.FACTIONS[k], _place_bet.bind(k)])
				_set_buttons(bets)
			elif opts.get("drive", false):
				status = "You drive for the Greens. Left and right to steer (A/D), W to use the whip, S to rein in."
				sub = "Take the turning posts tight but not too fast, or the chariot goes over."
			else:
				status = "The teams come out of the starting gates."
	queue_redraw()


func _money(n: int) -> String:
	return standing.money(n) if standing else str(n)


func _set_buttons(list: Array) -> void:
	for c in _buttons.get_children():
		c.queue_free()
	for pair: Array in list:
		var b := Button.new()
		b.text = str(pair[0])
		b.clip_text = true
		b.custom_minimum_size = Vector2(minf(180.0, (size.x - 8.0) / maxf(1.0, list.size())), 20)
		b.pressed.connect(pair[1])
		_buttons.add_child(b)


## Finishes the game: settles the stake (won or lost), says the last line.
func _finish(won: bool, line: String, stake_moves: bool = true) -> void:
	if finished:
		return
	finished = true
	if standing and stake_moves and _stake > 0:
		standing.apply({"coin": _stake if won else -_stake})
		line += " (%s%s)" % ["+" if won else "-", _money(_stake)]
	_set_buttons([])
	status = line
	queue_redraw()
	_done_at = _t + (0.0 if Engine.is_editor_hint() else 0.1)
	ended.emit(won, line)


func _process(delta: float) -> void:
	_t += delta
	if finished or game == null:
		return
	match kind:
		"terni", "latrunculi":
			if game.turn == 2 and not game.over:
				_wait += delta
				if _wait > 0.5:
					_wait = 0.0
					_their_board_move()
		"duodecim":
			if game.turn == 1 and not game.over:
				_wait += delta
				if _wait > 0.45:
					_wait = 0.0
					_their_duodecim_step()
		"race":
			if opts.get("bet", false) and _bet < 0:
				return
			var whip := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
			var rein := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
			var steer := 0.0
			if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
				steer -= 1.0
			if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
				steer += 1.0
			var speedup := 1.0 if opts.get("drive", false) else 3.0  # watching goes quicker
			game.step(delta * speedup, steer, whip, rein)
			_race_news()
			if game.over:
				_race_over()
	queue_redraw()


# ---------- knucklebones ----------

func _tali(loaded: bool) -> void:
	if finished:
		return
	var line: String = game.throw(loaded)
	status = line
	sub = "Rounds: you %d, him %d." % [game.rounds[0], game.rounds[1]]
	if game.over:
		if game.caught:
			if standing:
				standing.apply({"fides": -4, "ledger": "Cheated at dice with loaded bones, and was caught at it.", "ledger_key": "loaded_bones"})
			_finish(false, line + " You pay the stake and get out before the knives come out.")
		else:
			if game.cheated > 0 and standing:
				standing.apply({"ledger": "Won at dice with loaded bones." if game.won else "Threw loaded bones at dice, and lost anyway.",
					"ledger_key": "loaded_bones"})
			_finish(game.won, line + (" The game is yours." if game.won else " The game is his."))
	queue_redraw()


# ---------- boards ----------

func _board_rect() -> Rect2:
	match kind:
		"terni":
			return Rect2(20, 6, 132, 132)
		"latrunculi":
			return Rect2(8, 4, 144, 144)
	return Rect2(0, 0, size.x, 150)


func _gui_input(event: InputEvent) -> void:
	if finished or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var at: Vector2 = (event as InputEventMouseButton).position
	match kind:
		"terni":
			var r := _board_rect()
			if r.has_point(at):
				var cell := Vector2i(int((at.x - r.position.x) / (r.size.x / 3.0)), int((at.y - r.position.y) / (r.size.y / 3.0)))
				_terni_click(cell.y * 3 + cell.x)
		"latrunculi":
			var r := _board_rect()
			if r.has_point(at):
				var n: int = Games.Latrunculi.N
				var cell := Vector2i(int((at.x - r.position.x) / (r.size.x / n)), int((at.y - r.position.y) / (r.size.y / n)))
				_cursor = cell.y * n + cell.x
				_latr_select()
		"duodecim":
			var p := _duo_point_at(at)
			if p >= 0:
				_duo_click(p)
		"changer":
			for k in 6:
				if Rect2(20 + k * 84, 30, 64, 64).has_point(at):
					_selected_coin = k
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if finished or not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	var used := true
	match kind:
		"tali":
			if key in [KEY_F, KEY_SPACE, KEY_ENTER]:
				_tali(false)
			else:
				used = false
		"terni":
			var n := key - KEY_1
			if n >= 0 and n < 9:
				_terni_click(n)
			else:
				used = false
		"latrunculi":
			var n: int = Games.Latrunculi.N
			match key:
				KEY_LEFT, KEY_A:
					_cursor = maxi(0, _cursor - 1)
				KEY_RIGHT, KEY_D:
					_cursor = mini(n * n - 1, _cursor + 1)
				KEY_UP, KEY_W:
					_cursor = maxi(0, _cursor - n)
				KEY_DOWN, KEY_S:
					_cursor = mini(n * n - 1, _cursor + n)
				KEY_F, KEY_SPACE, KEY_ENTER:
					_latr_select()
				_:
					used = false
		"duodecim":
			var d := key - KEY_1
			if d >= 0 and d < 3:
				_die = d if d < game.dice.size() else _die
			elif key in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
				_duo_cycle(1 if key in [KEY_RIGHT, KEY_D] else -1)
			elif key in [KEY_F, KEY_SPACE, KEY_ENTER]:
				_duo_move_selected()
			else:
				used = false
		"changer":
			if key in [KEY_LEFT, KEY_A]:
				_selected_coin = maxi(0, _selected_coin - 1)
			elif key in [KEY_RIGHT, KEY_D]:
				_selected_coin = mini(5, _selected_coin + 1)
			else:
				used = false
		_:
			used = false
	if used:
		get_viewport().set_input_as_handled()
		queue_redraw()


func _terni_click(p: int) -> void:
	if game.over or game.turn != 1:
		return
	if game.placed[0] < 3:
		if game.play(-1, p):
			_after_board_move()
		return
	if game.board[p] == 1:
		_pick = p
	elif _pick >= 0 and game.play(_pick, p):
		_pick = -1
		_after_board_move()


func _latr_select() -> void:
	if game.over or game.turn != 1:
		return
	if game.board[_cursor] == 1:
		_pick = _cursor
	elif _pick >= 0 and game.play([_pick, _cursor]):
		_pick = -1
		_after_board_move()


func _after_board_move() -> void:
	_wait = 0.0
	if game.over:
		_board_over()


func _their_board_move() -> void:
	var m: Array = game.their_move()
	if m.is_empty():
		game.over = true
		game.winner = 1
	elif kind == "terni":
		game.play(m[0], m[1])
	else:
		game.play(m)
	if game.over:
		_board_over()


func _board_over() -> void:
	if game.winner == 0:
		finished = true
		_set_buttons([])
		status = "A draw. The stakes stay where they were."
		ended.emit(false, status)
		return
	_finish(game.winner == 1, "You win the game." if game.winner == 1 else "He wins the game.")


# ---------- twelve lines ----------

## Where point p (1 to 36) is drawn: three rows of twelve, the path running along the bottom row
## left to right, the middle right to left, the top left to right.
func _duo_pos(p: int) -> Vector2:
	var row := (p - 1) / 12
	var col := (p - 1) % 12
	if row == 1:
		col = 11 - col
	return Vector2(64 + col * 36, 118 - row * 40)


func _duo_point_at(at: Vector2) -> int:
	for p in range(1, 37):
		if Rect2(_duo_pos(p) - Vector2(16, 16), Vector2(32, 32)).has_point(at):
			return p
	if Rect2(4, 100, 48, 36).has_point(at):
		return 0
	return -1


func _duo_click(p: int) -> void:
	if game.turn != 0 or game.over:
		return
	var k := (game.men[0] as Array).find(p)
	if k < 0:
		return
	if _die < 0:
		_die = 0
	for d in [_die] + range(game.dice.size()):
		if d < game.dice.size() and game.can_move(0, k, int(game.dice[d])):
			_die = d
			_cursor = k
			_duo_move_selected()
			return


func _duo_cycle(dir: int) -> void:
	var movable: Array = []
	for o: Array in game.options(0):
		if _die < 0 or o[0] == _die:
			if not movable.has(o[1]):
				movable.append(o[1])
	if movable.is_empty():
		return
	var i := movable.find(_cursor)
	_cursor = movable[posmod(i + dir, movable.size())]


func _duo_move_selected() -> void:
	if game.turn != 0 or game.over:
		return
	if _die < 0 or _die >= game.dice.size():
		_die = 0
	if not game.move(0, _die, _cursor):
		var any: Array = game.options(0)
		if any.is_empty():
			_duo_end_turn()
			return
		var o: Array = any.filter(func(x: Array) -> bool: return x[0] == _die)
		if o.is_empty():
			o = any
		game.move(0, o[0][0], o[0][1])
	_die = mini(_die, game.dice.size() - 1)
	sub = "; ".join(game.events.slice(maxi(0, game.events.size() - 2)))
	if game.over:
		_finish(true, "All your men are home. The game is yours.")
	elif game.turn_done():
		_duo_end_turn()


func _duo_end_turn() -> void:
	game.next_turn()
	_die = 0
	_wait = 0.0


func _their_duodecim_step() -> void:
	if game.turn_done():
		if game.over:
			_finish(game.winner == 0, "All his men are home. The game is his." if game.winner == 1 else "The game is yours.")
			return
		game.next_turn()
		_die = 0
		if game.turn_done() and not game.over:  # you have no move with that throw
			sub = "Your throw (%s) gives you no move." % str(game.dice)
			game.next_turn()
		return
	game.their_step()
	sub = "; ".join(game.events.slice(maxi(0, game.events.size() - 2)))
	if game.over:
		_finish(false, "All his men are home. The game is his.")


# ---------- the market ----------

func _haggle_buttons() -> void:
	var list: Array = []
	for o: Array in game.offers():
		list.append([o[0], _haggle_offer.bind(int(o[1]))])
	list.append(["Lie" if game.buying else "Swear it's fresh", _haggle_lie])
	list.append(["Walk away", _haggle_walk])
	_set_buttons(list)


func _haggle_offer(n: int) -> void:
	status = game.offer(n)
	_haggle_after()


func _haggle_lie() -> void:
	var said: String = ("You: \"I saw it cheaper at the Forum Boarium.\" " if game.buying else "You: \"Caught this morning, on my mother's life.\" ")
	status = said + game.lie(standing.fides() if standing else 0)
	if standing:
		standing.apply({"ledger": "Lied at the market to beat down a price." if game.buying else "Swore that yesterday's fish was caught that morning.",
			"ledger_key": "market_lie"})
		if game.caught_lying:
			standing.apply({"fides": -1})
	_haggle_after()


func _haggle_walk() -> void:
	status = game.walk()
	_haggle_after()


func _haggle_after() -> void:
	if not game.over:
		_haggle_buttons()
		queue_redraw()
		return
	var item := str(opts.get("item", "it"))
	if game.price <= 0:
		_finish(false, status, false)
		return
	if game.buying:
		if standing and standing.coin() < game.price:
			_finish(false, status + " But you haven't %s." % _money(game.price), false)
			return
		if standing:
			standing.apply({"coin": -game.price, "give": item})
		_finish(true, status + " You pay %s for %s." % [_money(game.price), item], false)
	else:
		if standing:
			standing.apply({"coin": game.price})
		_finish(true, status + " You take %s." % _money(game.price), false)


# ---------- the money changer ----------

func _coin(what: String) -> void:
	var k := _selected_coin
	var c: Dictionary = game.coins[k]
	if c["judged"] != "" and what in ["take", "refuse"]:
		return
	match what:
		"ring":
			status = game.ring(k)
		"weigh":
			status = game.weigh(k)
		"cut":
			status = game.cut(k)
		"take", "refuse":
			status = game.judge(k, what == "take")
			var left: Array = []
			for j in 6:
				if game.coins[j]["judged"] == "":
					left.append(j)
			if left.is_empty():
				var r: Dictionary = game.reckon()
				var won: bool = int(r["right"]) >= 4
				if standing:
					standing.apply({"earn": int(r["right"]) - int(r["spoiled"]) * 2, "collect": ["coins", standing.age]})
				_finish(won, "You judged %d of %d rightly%s. %s" % [r["right"], r["of"],
					", and spoiled %d good coins with the chisel" % r["spoiled"] if int(r["spoiled"]) > 0 else "",
					"The changer nods: you'll do." if won else "The changer takes the tray back, sighing."], false)
				return
			_selected_coin = left[0]
	queue_redraw()


# ---------- the Circus ----------

func _place_bet(k: int) -> void:
	_bet = k
	_set_buttons([])
	status = "You back the %s, for %s. They're off." % [Games.FACTIONS[k], _money(_stake)]


func _race_news() -> void:
	var n: Array = game.news
	if not n.is_empty():
		sub = str(n[-1])


func _race_over() -> void:
	var first: int = game.leader()
	var who := str(Games.FACTIONS[first])
	if opts.get("bet", false):
		_finish(first == _bet, "The %s win." % who)
	elif opts.get("drive", false):
		if game.cars[0]["crashed"]:
			_finish(false, "Shipwreck at the turning post. They drag you clear of the wheels.")
		else:
			_finish(first == 0, "You win! The Greens' benches go mad." if first == 0 else "The %s win. You come in %s." % [who,
				["first", "second", "third", "last"][clampi((game.order as Array).find(0), 0, 3)]])
	else:
		_finish(true, "The %s win." % who, false)


# ---------- drawing ----------

func _draw() -> void:
	if game == null:
		return
	var font := get_theme_default_font()
	var fs := get_theme_default_font_size()
	match kind:
		"tali":
			_draw_tali(font, fs)
		"terni":
			_draw_terni()
		"latrunculi":
			_draw_latr()
		"duodecim":
			_draw_duo(font, fs)
		"haggle":
			_draw_stall(font, fs)
		"changer":
			_draw_tray(font, fs)
		"race":
			_draw_race(font, fs)
	var text_x := 180.0 if kind in ["terni", "latrunculi"] else 8.0
	var text_y := 12.0 if kind in ["terni", "latrunculi"] else 142.0
	var width := size.x - text_x - 8.0
	draw_multiline_string(font, Vector2(text_x, text_y + fs), status, HORIZONTAL_ALIGNMENT_LEFT, width, fs, 3, INK)
	if sub != "":
		draw_multiline_string(font, Vector2(text_x, text_y + fs * 3 + 8), sub, HORIZONTAL_ALIGNMENT_LEFT, width, fs, 3, DIM)


func _draw_tali(font: Font, fs: int) -> void:
	for side in 2:
		var bones: Array = game.you if side == 0 else game.them
		var y := 20.0 + side * 56.0
		draw_string(font, Vector2(8, y + 26), "You" if side == 0 else "Him", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)
		for k in bones.size():
			var r := Rect2(70 + k * 50, y, 38, 38)
			draw_rect(r, Color("e8dcc8"))
			draw_rect(r, Color("5a4a3a"), false, 2.0)
			draw_string(font, r.position + Vector2(13, 26), str(bones[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("2a2018"))


func _draw_terni() -> void:
	var r := _board_rect()
	draw_rect(r, BOARD)
	var p := func(i: int) -> Vector2: return r.position + Vector2((i % 3 + 0.5) * r.size.x / 3.0, (i / 3 + 0.5) * r.size.y / 3.0)
	for l: Array in Games.Terni.LINES:
		draw_line(p.call(l[0]), p.call(l[2]), DIM, 2.0)
	for i in 9:
		var who: int = game.board[i]
		if who != 0:
			draw_circle(p.call(i), 13.0, YOU if who == 1 else THEM)
		if i == _pick:
			draw_arc(p.call(i), 17.0, 0, TAU, 20, GOLD, 2.0)


func _draw_latr() -> void:
	var r := _board_rect()
	var n: int = Games.Latrunculi.N
	var c := r.size.x / n
	for y in n:
		for x in n:
			var cell := Rect2(r.position + Vector2(x * c, y * c), Vector2(c, c))
			draw_rect(cell, BOARD if (x + y) % 2 == 0 else BOARD.lightened(0.08))
			var who: int = game.board[y * n + x]
			if who != 0:
				draw_circle(cell.get_center(), c * 0.36, YOU if who == 1 else THEM)
			if y * n + x == _pick:
				draw_rect(cell.grow(-1), GOLD, false, 2.0)
			elif y * n + x == _cursor:
				draw_rect(cell.grow(-1), DIM, false, 1.0)


func _draw_duo(font: Font, fs: int) -> void:
	draw_rect(Rect2(44, 58, 452, 120), BOARD)
	for p in range(1, 37):
		var at := _duo_pos(p)
		draw_rect(Rect2(at - Vector2(15, 17), Vector2(30, 34)), BOARD.lightened(0.06 if p % 2 == 0 else 0.0))
		for side in 2:
			var here: int = (game.men[side] as Array).count(p)
			for k in here:
				var dot := at + Vector2((side * 2 - 1) * 7, -10 + k * 7)
				draw_circle(dot, 5.0, YOU if side == 0 else THEM)
	for side in 2:
		var waiting: int = (game.men[side] as Array).count(0)
		var home: int = game.home(side)
		draw_string(font, Vector2(4, 70 + side * 40), "%s: %d to come on, %d home" % ["You" if side == 0 else "Him", waiting, home],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, YOU if side == 0 else Color("c88a6a"))
	for d in game.dice.size():
		var r := Rect2(360 + d * 34, 4, 28, 28)
		draw_rect(r, Color("e8dcc8"))
		draw_rect(r, GOLD if d == _die else Color("5a4a3a"), false, 2.0)
		draw_string(font, r.position + Vector2(9, 20), str(game.dice[d]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("2a2018"))
	if game.turn == 0 and _cursor >= 0 and _cursor < 5:
		var at_p: int = game.men[0][_cursor]
		if at_p >= 1 and at_p <= 36:
			draw_arc(_duo_pos(at_p), 18.0, 0, TAU, 16, GOLD, 2.0)
	draw_string(font, Vector2(8, 20), "Your throw" if game.turn == 0 else "His throw", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)


func _draw_stall(font: Font, fs: int) -> void:
	draw_rect(Rect2(8, 8, 200, 100), Color("5a3a24"))
	draw_rect(Rect2(8, 8, 200, 20), Color("a84a3a"))
	draw_string(font, Vector2(16, 60), str(opts.get("item", "")), HORIZONTAL_ALIGNMENT_LEFT, 180, fs, INK)
	draw_string(font, Vector2(230, 40), ("They ask: %s" if game.buying else "They offer: %s") % _money(game.ask), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)
	if standing:
		draw_string(font, Vector2(230, 64), "In your purse: %s" % _money(standing.coin()), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, DIM)


func _draw_tray(font: Font, fs: int) -> void:
	for k in 6:
		var c: Dictionary = game.coins[k]
		var at := Vector2(52 + k * 84, 62)
		draw_circle(at, 26.0, Color("c8c8c0") if not c["cut"] or c["good"] else Color("b87a4a"))
		draw_arc(at, 26.0, 0, TAU, 24, GOLD if k == _selected_coin else Color("5a5a54"), 2.0)
		var note := "?"
		if c["judged"] != "":
			note = "taken" if c["judged"] == "take" else "refused"
		elif c["cut"]:
			note = "cut"
		elif float(c["weighed"]) > 0.0:
			note = "%.2fg" % c["weighed"]
		elif c["rung"] != "":
			note = str(c["rung"])
		draw_string(font, at + Vector2(-24, 44), note, HORIZONTAL_ALIGNMENT_CENTER, 48, fs - 2, INK)


func _draw_race(font: Font, fs: int) -> void:
	var centre := Vector2(size.x / 2.0, 70)
	var rx := 200.0
	var ry := 50.0
	draw_rect(Rect2(centre - Vector2(rx + 34, ry + 22), Vector2(rx * 2 + 68, ry * 2 + 44)), Color("a88a5a"))  # the sand
	draw_rect(Rect2(centre - Vector2(rx - 30, 5), Vector2(rx * 2 - 60, 10)), Color("d8d0c0"))  # the spina
	for end: float in [-1.0, 1.0]:
		draw_circle(centre + Vector2(end * (rx - 26), 0), 6.0, GOLD)  # the turning posts
	var laps: int = game.laps
	var lead := 0
	for k in game.cars.size():
		lead = maxi(lead, int(floor(float(game.cars[k]["s"]))))
	for e in 7:  # the seven eggs and dolphins that count the laps
		var lit := e < mini(lead, 7) * 7 / maxi(laps, 1)
		draw_circle(centre + Vector2(-60 + e * 20, 0), 3.0, GOLD if lit else DIM)
	var cols := [Color("3a8a3a"), Color("3a5aa8"), Color("a83a2a"), Color("e8e8e0")]
	for k in game.cars.size():
		var c: Dictionary = game.cars[k]
		var a := -TAU * fposmod(float(c["s"]), 1.0) + PI / 2.0
		var r := 1.0 + 0.3 * float(c["lane"])
		var at := centre + Vector2(cos(a) * rx * r * 0.9, sin(a) * ry * r)
		if c["crashed"]:
			draw_rect(Rect2(at - Vector2(5, 3), Vector2(10, 6)), Color("5a4a3a"))
			continue
		draw_rect(Rect2(at - Vector2(6, 4), Vector2(12, 8)), cols[k])
		if c["you"]:
			draw_rect(Rect2(at - Vector2(8, 6), Vector2(16, 12)), GOLD, false, 1.5)
	if game.you >= 0:
		var me: Dictionary = game.cars[game.you]
		draw_string(font, Vector2(8, 16), "Lap %d of %d   The horses' wind: %d%%" % [game.lap_of(game.you), laps,
			int(float(me["stamina"]) * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
