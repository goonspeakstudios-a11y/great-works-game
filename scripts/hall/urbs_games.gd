extends RefCounted
## The games of the city, as rules only (urbs_games_view.gd draws them and takes your moves):
##   Tali         knucklebones: four bones, the Venus wins, the Dog loses; loaded bones if you dare
##   Terni        terni lapilli: three stones each, three in a row, placed and then moved
##   Latrunculi   the soldiers' game: rook moves on eight by eight, taken by being surrounded
##   Duodecim     duodecim scripta: three rows of twelve, three dice, five men each, a lone man hit
##                goes back to the start (the Basilica Julia's steps have the boards cut in them)
##   Haggle       buying or selling at a stall: each side has a limit it will not show
##   Changer      the money changer's test: ring, weigh and cut the coins, and see what they are
##   Race         seven laps of the Circus: the reins, the whip, the turning posts
## Each is played against the city (a simple, fair opponent), with a seed so tests are repeatable.

const FACTIONS := ["Greens", "Blues", "Reds", "Whites"]


# ---------- knucklebones ----------

class Tali extends RefCounted:
	## The sides a bone lands on: 1 (the dog side, narrow), 3, 4, 6 (narrow).
	const SIDES := [1, 3, 4, 6]
	const ODDS := [0.1, 0.4, 0.4, 0.1]
	var rng := RandomNumberGenerator.new()
	var rounds := [0, 0]  # you, them
	var need := 3
	var you: Array = []
	var them: Array = []
	var over := false
	var won := false
	var caught := false
	var cheated := 0

	func _init(seed_value: int = 1) -> void:
		rng.seed = seed_value

	func _bone(loaded: bool) -> int:
		if loaded:
			return [6, 6, 4, 3, 1][rng.randi() % 5] if rng.randf() < 0.6 else SIDES[rng.randi() % 4]
		var r := rng.randf()
		var acc := 0.0
		for k in 4:
			acc += float(ODDS[k])
			if r < acc:
				return SIDES[k]
		return 4

	func _four(loaded: bool) -> Array:
		var out: Array = []
		for k in 4:
			out.append(_bone(loaded))
		return out

	## "venus", "dog" or "" for an ordinary throw.
	static func name_of(bones: Array) -> String:
		var s := bones.duplicate()
		s.sort()
		if s == [1, 3, 4, 6]:
			return "venus"
		if s == [1, 1, 1, 1]:
			return "dog"
		return ""

	static func worth(bones: Array) -> int:
		match name_of(bones):
			"venus":
				return 100
			"dog":
				return -1
		var t := 0
		for b: int in bones:
			t += b
		return t

	## One round: both throw. `loaded`: your own bones, weighted. Returns what happened.
	func throw(loaded: bool = false) -> String:
		if over:
			return ""
		if loaded:
			cheated += 1
			if rng.randf() < 0.12 + 0.08 * cheated:
				caught = true
				over = true
				won = false
				return "He catches your wrist and turns the bone over. Loaded. The whole tavern has seen it."
		you = _four(loaded)
		them = _four(false)
		var a := worth(you)
		var b := worth(them)
		var line := "You throw %s%s. He throws %s%s. " % [you, _call(you), them, _call(them)]
		if a > b:
			rounds[0] += 1
			line += "Your round."
		elif b > a:
			rounds[1] += 1
			line += "His round."
		else:
			line += "Even. Throw again."
		if rounds[0] >= need or rounds[1] >= need:
			over = true
			won = rounds[0] >= need
		return line

	static func _call(bones: Array) -> String:
		match name_of(bones):
			"venus":
				return ", the Venus!"
			"dog":
				return ", the Dog"
		return ""


# ---------- three stones in a row ----------

class Terni extends RefCounted:
	const LINES := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
	var board: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]  # 1 you, 2 them
	var placed := [0, 0]
	var turn := 1
	var moves := 0
	var over := false
	var winner := 0
	var rng := RandomNumberGenerator.new()

	func _init(seed_value: int = 1) -> void:
		rng.seed = seed_value

	static func adjacent(a: int, b: int) -> bool:
		if a == b:
			return false
		return absi(a % 3 - b % 3) <= 1 and absi(a / 3 - b / 3) <= 1

	static func line_of(b: Array, who: int) -> bool:
		for l: Array in LINES:
			if b[l[0]] == who and b[l[1]] == who and b[l[2]] == who:
				return true
		return false

	## Every legal move for `who` on `b` with `done` stones placed: [from, to] (from -1 to place).
	static func legal(b: Array, who: int, done: int) -> Array:
		var out: Array = []
		if done < 3:
			for k in 9:
				if b[k] == 0:
					out.append([-1, k])
			return out
		for f in 9:
			if b[f] != who:
				continue
			for t in 9:
				if b[t] == 0 and adjacent(f, t):
					out.append([f, t])
		return out

	func play(from: int, to: int) -> bool:
		if over:
			return false
		var ok := legal(board, turn, placed[turn - 1]).any(func(m: Array) -> bool: return m[0] == from and m[1] == to)
		if not ok:
			return false
		if from >= 0:
			board[from] = 0
		else:
			placed[turn - 1] += 1
		board[to] = turn
		moves += 1
		if line_of(board, turn):
			over = true
			winner = turn
		elif moves >= 40:
			over = true
			winner = 0
		turn = 3 - turn
		if not over and legal(board, turn, placed[turn - 1]).is_empty():
			over = true
			winner = 3 - turn
		return true

	## The city's move: a win if there is one, else block yours, else the best by a short look ahead.
	func their_move() -> Array:
		var best: Array = []
		var best_v := -INF
		for m: Array in legal(board, 2, placed[1]):
			var v := _value(board.duplicate(), placed.duplicate(), m, 2, 3) + rng.randf() * 0.2
			if v > best_v:
				best_v = v
				best = m
		return best

	static func _value(b: Array, p: Array, m: Array, who: int, depth: int) -> float:
		if m[0] >= 0:
			b[m[0]] = 0
		else:
			p[who - 1] += 1
		b[m[1]] = who
		if line_of(b, who):
			return 10.0 if who == 2 else -10.0
		if depth <= 0:
			return 0.0
		var other := 3 - who
		var replies := legal(b, other, p[other - 1])
		if replies.is_empty():
			return 5.0 if who == 2 else -5.0
		var out := INF if other == 1 else -INF
		for r: Array in replies:
			var v := _value(b.duplicate(), p.duplicate(), r, other, depth - 1) * 0.9
			out = minf(out, v) if other == 1 else maxf(out, v)
		return out


# ---------- the soldiers' game ----------

class Latrunculi extends RefCounted:
	const N := 8
	var board: Array = []  # N*N: 0 empty, 1 you (bottom), 2 them (top)
	var turn := 1
	var moves := 0
	var over := false
	var winner := 0
	var taken := [0, 0]  # taken by you, by them
	var rng := RandomNumberGenerator.new()

	func _init(seed_value: int = 1) -> void:
		rng.seed = seed_value
		board.resize(N * N)
		board.fill(0)
		for x in N:
			board[x] = 2
			board[(N - 1) * N + x] = 1

	func count(who: int) -> int:
		return board.count(who)

	static func moves_of(b: Array, who: int) -> Array:
		var out: Array = []
		for f in b.size():
			if b[f] != who:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var x: int = f % N + d.x
				var y: int = f / N + d.y
				while x >= 0 and x < N and y >= 0 and y < N and b[y * N + x] == 0:
					out.append([f, y * N + x])
					x += d.x
					y += d.y
		return out

	## Moves a man and takes whatever it now shuts in between itself and another of its own.
	static func apply_move(b: Array, m: Array) -> int:
		var who: int = b[m[0]]
		b[m[1]] = who
		b[m[0]] = 0
		var took := 0
		var x: int = m[1] % N
		var y: int = m[1] / N
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ax := x + d.x
			var ay := y + d.y
			var bx := x + d.x * 2
			var by := y + d.y * 2
			if bx < 0 or bx >= N or by < 0 or by >= N:
				continue
			if b[ay * N + ax] == 3 - who and b[by * N + bx] == who:
				b[ay * N + ax] = 0
				took += 1
		return took

	func play(m: Array) -> bool:
		if over or not moves_of(board, turn).any(func(o: Array) -> bool: return o == m):
			return false
		var took := apply_move(board, m)
		taken[turn - 1] += took
		moves += 1
		turn = 3 - turn
		if count(1) <= 1 or count(2) <= 1 or moves_of(board, turn).is_empty() or moves >= 120:
			over = true
			var a := count(1)
			var b := count(2)
			if moves_of(board, turn).is_empty() and a > 1 and b > 1:
				winner = 3 - turn
			else:
				winner = 1 if a > b else (2 if b > a else 0)
		return true

	## The city's move: what takes most, then what leaves its men safest, with a little chance.
	func their_move() -> Array:
		var best: Array = []
		var best_v := -INF
		for m: Array in moves_of(board, 2):
			var b := board.duplicate()
			var v := float(apply_move(b, m)) * 10.0
			var worst := 0
			for r: Array in moves_of(b, 1):
				var bb := b.duplicate()
				worst = maxi(worst, apply_move(bb, r))
			v -= float(worst) * 8.0
			v += float(m[1] / N) * 0.15  # forward
			v += rng.randf()
			if v > best_v:
				best_v = v
				best = m
		return best


# ---------- twelve lines ----------

class Duodecim extends RefCounted:
	const POINTS := 36
	const MEN := 5
	## Where each man is: 0 waiting to come on, 1 to 36 on the board, 37 borne off. [yours, theirs]
	var men: Array = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
	var dice: Array = []
	var turn := 0  # 0 you, 1 them
	var over := false
	var winner := -1
	var rng := RandomNumberGenerator.new()
	var events: Array = []

	func _init(seed_value: int = 1) -> void:
		rng.seed = seed_value

	func roll() -> Array:
		dice = [rng.randi_range(1, 6), rng.randi_range(1, 6), rng.randi_range(1, 6)]
		return dice

	func _count_at(side: int, p: int) -> int:
		return (men[side] as Array).count(p)

	## Whether `side` may move man `k` by `pips`: not onto a point the other side holds with two.
	func can_move(side: int, k: int, pips: int) -> bool:
		var at: int = men[side][k]
		if at > POINTS:
			return false
		var to := at + pips
		if to > POINTS:
			return (men[side] as Array).all(func(p: int) -> bool: return p > 24)  # bear off only from the last row
		return _count_at(1 - side, to) < 2

	func options(side: int) -> Array:
		var out: Array = []
		for d in dice.size():
			var seen := {}
			for k in MEN:
				var at: int = men[side][k]
				if seen.has(at):
					continue
				seen[at] = true
				if can_move(side, k, int(dice[d])):
					out.append([d, k])
		return out

	## Moves man `k` of `side` by die `d`. A lone man of the other side on the point goes back to the start.
	func move(side: int, d: int, k: int) -> bool:
		if over or d < 0 or d >= dice.size() or not can_move(side, k, int(dice[d])):
			return false
		var to: int = int(men[side][k]) + int(dice[d])
		dice.remove_at(d)
		if to > POINTS:
			men[side][k] = POINTS + 1
		else:
			men[side][k] = to
			if _count_at(1 - side, to) == 1:
				var i := (men[1 - side] as Array).find(to)
				men[1 - side][i] = 0
				events.append("%s hit on point %d, back to the start." % ["Your man is" if side == 1 else "His man is", to])
		if (men[side] as Array).all(func(p: int) -> bool: return p > POINTS):
			over = true
			winner = side
		return true

	## Ends a side's turn when it has no dice or no moves left.
	func turn_done() -> bool:
		return over or dice.is_empty() or options(turn).is_empty()

	func next_turn() -> void:
		turn = 1 - turn
		roll()

	## The city's move with one die: bear off, hit, make a pair, keep men safe, else run the hindmost.
	func their_step() -> bool:
		var best: Array = []
		var best_v := -INF
		for o: Array in options(1):
			var at: int = men[1][o[1]]
			var to := at + int(dice[o[0]])
			var v := float(to) * 0.05
			if to > POINTS:
				v += 8.0
			elif _count_at(0, to) == 1:
				v += 6.0
			if to <= POINTS and _count_at(1, to) >= 1:
				v += 2.0
			if _count_at(1, at) == 2:
				v -= 1.5  # breaks a pair
			v += rng.randf() * 0.5
			if v > best_v:
				best_v = v
				best = o
		if best.is_empty():
			return false
		return move(1, best[0], best[1])

	func home(side: int) -> int:
		return (men[side] as Array).filter(func(p: int) -> bool: return p > POINTS).size()


# ---------- the market ----------

class Haggle extends RefCounted:
	## `buying`: you buy (they sell), else you sell (they buy). `value`: what it is worth, in the
	## age's coin. `fides`: yours (trusted people get better prices and are believed).
	var buying := true
	var value := 10
	var ask := 0  # what they say now
	var limit := 0  # the most they'll pay, or the least they'll take (hidden)
	var patience := 4
	var over := false
	var price := 0  # the deal, if one was struck
	var lied := false
	var caught_lying := false
	var rng := RandomNumberGenerator.new()

	func _init(is_buying: bool, worth: int, fides: int, seed_value: int = 1) -> void:
		rng.seed = seed_value
		buying = is_buying
		value = maxi(1, worth)
		var trust := clampf(float(fides) * 0.015, -0.2, 0.2)
		if buying:
			limit = maxi(1, roundi(value * (rng.randf_range(0.72, 0.92) - trust)))
			ask = maxi(limit + 1, roundi(value * rng.randf_range(1.3, 1.5)))
		else:
			limit = maxi(1, roundi(value * (rng.randf_range(1.05, 1.25) + trust)))
			ask = maxi(1, roundi(value * rng.randf_range(0.5, 0.65)))
		patience = 3 + rng.randi_range(0, 2)

	## What you might say now: [[label, amount]], amount -1 for words, not money.
	func offers() -> Array:
		if over:
			return []
		var out: Array = []
		if buying:
			out.append(["Offer %d" % maxi(1, roundi(ask * 0.6)), maxi(1, roundi(ask * 0.6))])
			out.append(["Offer %d" % maxi(1, roundi(ask * 0.8)), maxi(1, roundi(ask * 0.8))])
		else:
			out.append(["Ask %d" % roundi(ask * 1.6 + 1), roundi(ask * 1.6 + 1)])
			out.append(["Ask %d" % roundi(ask * 1.25 + 1), roundi(ask * 1.25 + 1)])
		out.append(["Take it at %d" % ask, ask])
		return out

	## You name a sum. Returns their answer.
	func offer(amount: int) -> String:
		if over:
			return ""
		var deal := amount >= limit if buying else amount <= limit
		if amount == ask or deal:
			over = true
			price = amount
			return "Done. %d it is." % amount if amount != ask else "Done."
		patience -= 1
		if patience <= 0:
			over = true
			price = 0
			return "No. Go and try somewhere else, then." if buying else "No. I'll buy elsewhere."
		var gap := (ask - limit) if buying else (limit - ask)
		var step := maxi(1, roundi(gap * rng.randf_range(0.25, 0.45)))
		ask = ask - step if buying else ask + step
		return ["Robbery! %d, and I'm giving it away.", "You'll ruin me. %d.", "For you, %d. Last word.", "%d. Look at the quality."][rng.randi() % 4] % ask

	## A lie ("I saw it cheaper at the Forum Boarium" / "It was caught this morning").
	func lie(fides: int) -> String:
		if over:
			return ""
		lied = true
		if rng.randf() < 0.45 + clampf(fides * 0.02, -0.3, 0.3):
			var cut := maxi(1, roundi(absi(ask - limit) * 0.4))
			ask = ask - cut if buying else ask + cut
			return "They look at you a long moment. \"Fine. %d.\"" % ask
		caught_lying = true
		patience -= 1
		ask = ask + maxi(1, roundi(ask * 0.1)) if buying else maxi(1, ask - maxi(1, roundi(ask * 0.1)))
		if patience <= 0:
			over = true
			return "\"Liar.\" They turn away from you."
		return "\"Is that so? Then go and buy it there.\" The price goes up: %d." % ask

	## You walk away. Sometimes they call you back.
	func walk() -> String:
		if over:
			return ""
		over = true
		if rng.randf() < 0.45:
			over = false
			ask = limit + (1 if buying else -1) * rng.randi_range(0, 1)
			ask = maxi(1, ask)
			return "\"Wait! Wait. %d, and may the gods forgive me.\"" % ask
		return "You walk away. No one calls you back."


# ---------- the money changer's table ----------

class Changer extends RefCounted:
	## A tray of coins of the age: some good, some plated (a copper core under a skin of silver),
	## some light. Test them: ring (a good coin rings clear), weigh, cut (it shows the core, and a
	## good coin is spoiled). Then take the good and refuse the bad.
	var coins: Array = []  # {good: bool, plated: bool, light: bool, rung, weighed, cut, judged: ""}
	var standard := 3.9  # grams
	var name := "denarius"
	var fineness := ""
	var rng := RandomNumberGenerator.new()

	func _init(age: String, seed_value: int = 1) -> void:
		rng.seed = seed_value
		var ages := {
			"republic": ["denarius", 3.9, "nearly pure silver (about 95 parts in a hundred)"],
			"empire": ["denarius", 3.4, "silver, but debased since Nero: about three parts in four"],
			"late": ["follis", 3.0, "copper with a wash of silver on it, a few parts in a hundred at most"],
		}
		var a: Array = ages.get(age, ages["republic"])
		name = a[0]
		standard = a[1]
		fineness = a[2]
		for k in 6:
			var r := rng.randf()
			var c := {"good": true, "plated": false, "light": false, "rung": "", "weighed": 0.0, "cut": false, "judged": ""}
			if r < 0.25:
				c["good"] = false
				c["plated"] = true
			elif r < 0.4:
				c["good"] = false
				c["light"] = true
			coins.append(c)

	func ring(k: int) -> String:
		var c: Dictionary = coins[k]
		var clear: bool = not c["plated"] if rng.randf() < 0.8 else c["plated"]  # a ring can mislead
		c["rung"] = "clear" if clear else "dull"
		return "It rings %s on the table." % c["rung"]

	func weigh(k: int) -> String:
		var c: Dictionary = coins[k]
		var w := standard * (rng.randf_range(0.97, 1.02) if not c["light"] else rng.randf_range(0.8, 0.9))
		if c["plated"]:
			w *= rng.randf_range(0.93, 1.0)
		c["weighed"] = snappedf(w, 0.01)
		return "It weighs %.2f grams (a good %s should be about %.1f)." % [c["weighed"], name, standard]

	func cut(k: int) -> String:
		var c: Dictionary = coins[k]
		c["cut"] = true
		return "You nick the edge with the chisel: %s" % ("copper under the silver. A plated fake." if c["plated"] else "the same metal all through.")

	func judge(k: int, take: bool) -> String:
		var c: Dictionary = coins[k]
		c["judged"] = "take" if take else "refuse"
		return "Taken." if take else "Refused."

	## How many you judged rightly, and what the good coins you cut cost you.
	func reckon() -> Dictionary:
		var right := 0
		var spoiled := 0
		for c: Dictionary in coins:
			if (c["judged"] == "take") == bool(c["good"]) and c["judged"] != "":
				right += 1
			if c["cut"] and c["good"]:
				spoiled += 1
		return {"right": right, "of": coins.size(), "spoiled": spoiled}


# ---------- the Circus ----------

class Race extends RefCounted:
	## Four teams run `laps` laps of the spina, anticlockwise; the turns at the metae are where
	## races are lost. s: how far round (1.0 a lap), lane: 0 the inside rail to 1 the outside.
	const TURNS := [[0.44, 0.56], [0.94, 1.06]]
	const TOP := 0.16  # laps a second, at best
	var laps := 7
	var cars: Array = []  # {name, s, lane, v, want, stamina, crashed, you}
	var you := -1
	var over := false
	var order: Array = []  # finishing order, by index
	var fixed := -1  # a race fixed for one team (the collapse)
	var t := 0.0
	var rng := RandomNumberGenerator.new()
	var news: Array = []

	func _init(driving: bool, lap_count: int = 7, seed_value: int = 1, fixed_for: int = -1) -> void:
		rng.seed = seed_value
		laps = lap_count
		fixed = fixed_for
		for k in 4:
			cars.append({"name": FACTIONS[k], "s": -0.01 * k, "lane": 0.15 + 0.22 * k, "v": 0.0,
				"want": rng.randf_range(0.85, 0.97), "stamina": 1.0, "crashed": false, "you": driving and k == 0,
				"skill": rng.randf_range(0.8, 1.0)})
		you = 0 if driving else -1

	static func in_turn(s: float) -> bool:
		var f := fposmod(s, 1.0)
		return (f > TURNS[0][0] and f < TURNS[0][1]) or f > TURNS[1][0] or f < TURNS[1][1] - 1.0

	## How fast a team may take a turn in its lane before the chariot goes over.
	static func safe(lane: float) -> float:
		return 0.62 + 0.3 * lane

	## Moment to moment. For your team: steer (-1 inside, 1 outside), whip (bool), rein (bool).
	func step(delta: float, steer: float = 0.0, whip: bool = false, rein: bool = false) -> void:
		if over:
			return
		t += delta
		for k in cars.size():
			var c: Dictionary = cars[k]
			if c["crashed"] or c["s"] >= laps:
				continue
			var turning := in_turn(float(c["s"]))
			var lane: float = c["lane"]
			var want: float = c["want"]
			if c["you"]:
				c["lane"] = clampf(lane + steer * delta * 0.8, 0.0, 1.0)
				if whip and float(c["stamina"]) > 0.05:
					want = 1.12
					c["stamina"] = maxf(0.0, float(c["stamina"]) - delta * 0.18)
				elif rein:
					want = 0.5
				else:
					want = 0.88
					c["stamina"] = minf(1.0, float(c["stamina"]) + delta * 0.05)
			else:
				var ahead_turn := in_turn(float(c["s"]) + 0.06)
				var careful: float = safe(lane) * float(c["skill"]) if ahead_turn or turning else 1.05 * float(c["skill"])
				if fixed >= 0:
					careful *= 1.08 if k == fixed else 0.9
				want = minf(want, careful)
				c["lane"] = lerpf(lane, 0.1 + 0.2 * k * 0.3, delta * 0.3)
			var tired := 0.75 + 0.25 * float(c["stamina"])
			c["v"] = lerpf(float(c["v"]), want * tired, delta * 1.2)
			if turning and float(c["v"]) > safe(float(c["lane"])) + 0.06:
				if rng.randf() < delta * 3.0 * (float(c["v"]) - safe(float(c["lane"]))) * 6.0:
					c["crashed"] = true
					news.append("The %s go over at the turning post. Shipwreck!" % c["name"])
					continue
			var longer := 1.0 + (0.3 * float(c["lane"]) if turning else 0.0)  # the outside of a turn is further
			c["s"] = float(c["s"]) + float(c["v"]) * TOP * delta / longer
			if float(c["s"]) >= laps and not order.has(k):
				order.append(k)
		for a in cars.size():  # locked wheels: two teams side by side slow each other
			for b in range(a + 1, cars.size()):
				var ca: Dictionary = cars[a]
				var cb: Dictionary = cars[b]
				if ca["crashed"] or cb["crashed"]:
					continue
				if absf(float(ca["s"]) - float(cb["s"])) < 0.006 and absf(float(ca["lane"]) - float(cb["lane"])) < 0.12:
					ca["v"] = float(ca["v"]) * 0.97
					cb["v"] = float(cb["v"]) * 0.97
		var running := cars.filter(func(c: Dictionary) -> bool: return not c["crashed"] and float(c["s"]) < laps)
		if running.is_empty() or (you >= 0 and (cars[you]["crashed"] or order.has(you))):
			over = true
			for k in cars.size():
				if not order.has(k) and not cars[k]["crashed"]:
					order.append(k)

	func lap_of(k: int) -> int:
		return clampi(int(floor(float(cars[k]["s"]))) + 1, 1, laps)

	## The team out in front (or that finished first).
	func leader() -> int:
		if not order.is_empty():
			return order[0]
		var best := 0
		for k in cars.size():
			if not cars[k]["crashed"] and float(cars[k]["s"]) > float(cars[best]["s"]):
				best = k
		return best
