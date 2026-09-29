extends RefCounted
## The plan of the city of Rome, and the way through it (content/rome/city.json): the streets as a
## network, routes along them, and directions in words that match the plan (the Plan panel,
## urbs_plan_panel.gd, draws the same streets with north at the top). Directions name the streets
## to take, the way each runs (north, south-east...), how far in paces, what you pass where you
## turn, and which side of you the place is when you get there.
##
## Map positions are metres east and north of the Forum; world positions are the game's (north is
## -Z). A Roman pace (passus) is 1.48 metres.

const RomeMap := preload("res://scripts/hall/rome_map.gd")
const STEP := 18.0  # map metres between the points a street is walked by
const JOIN := 40.0  # points of two streets this close meet
const REACH := 160.0  # a street's end is joined to the nearest point of another this far off
const PACE := 1.48
const POINTS := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]

static var _graph := {}  # {pts: [Vector2 map], road: [name], edges: [[i, cost]...]}


## The streets as a graph: every street walked in points STEP apart, joined along each street, where
## streets cross or meet, and each street's ends to the nearest other street.
static func graph() -> Dictionary:
	if not _graph.is_empty():
		return _graph
	var pts: Array = []
	var road: Array = []
	var edges: Array = []
	var ends: Array = []
	for r: Dictionary in RomeMap.city_data().get("roads", []):
		var line: Array = r["points"]
		var first := pts.size()
		for i in line.size() - 1:
			var a := Vector2(float(line[i][0]), float(line[i][1]))
			var b := Vector2(float(line[i + 1][0]), float(line[i + 1][1]))
			var n := maxi(1, int(ceil(a.distance_to(b) / STEP)))
			for k in n:
				pts.append(a.lerp(b, float(k) / n))
				road.append(str(r["name"]))
				edges.append([])
		var last: Array = line[line.size() - 1]
		pts.append(Vector2(float(last[0]), float(last[1])))
		road.append(str(r["name"]))
		edges.append([])
		for k in range(first, pts.size() - 1):
			_link(edges, pts, k, k + 1)
		ends.append(first)
		ends.append(pts.size() - 1)
	for i in pts.size():  # crossings
		for j in range(i + 1, pts.size()):
			if road[i] != road[j] and (pts[i] as Vector2).distance_to(pts[j]) < JOIN:
				_link(edges, pts, i, j)
	for e: int in ends:  # a street's end runs on into the nearest other street
		var best := -1
		var best_d := REACH
		for j in pts.size():
			if road[j] == road[e]:
				continue
			var d := (pts[e] as Vector2).distance_to(pts[j])
			if d < best_d:
				best_d = d
				best = j
		if best >= 0:
			_link(edges, pts, e, best)
	_join_all(pts, edges)
	_graph = {"pts": pts, "road": road, "edges": edges}
	return _graph


## Joins every separate piece of the network to the rest, by its nearest pair of points, until all
## the streets are one network (a street outside the others, like the Appian Way inside the Capene
## Gate, is reached across whatever lies between).
static func _join_all(pts: Array, edges: Array) -> void:
	for guard in 50:
		var part := {0: true}
		var todo: Array = [0]
		while not todo.is_empty():
			var u: int = todo.pop_back()
			for e: Array in edges[u]:
				if not part.has(e[0]):
					part[e[0]] = true
					todo.append(e[0])
		if part.size() == pts.size():
			return
		var best := [-1, -1]
		var best_d := INF
		for i in pts.size():
			if part.has(i):
				continue
			for j: int in part:
				var d := (pts[i] as Vector2).distance_to(pts[j])
				if d < best_d:
					best_d = d
					best = [i, j]
		_link(edges, pts, best[0], best[1])


static func _link(edges: Array, pts: Array, a: int, b: int) -> void:
	var d := (pts[a] as Vector2).distance_to(pts[b])
	(edges[a] as Array).append([b, d])
	(edges[b] as Array).append([a, d])


## A world position as a map position (metres east, north of the Forum).
static func to_map(p: Vector3) -> Vector2:
	var s: float = RomeMap.data().get("scale", 0.35)
	return Vector2(p.x / s, -p.z / s)


static func nearest_point(m: Vector2) -> int:
	var g := graph()
	var best := 0
	var best_d := INF
	for i in (g["pts"] as Array).size():
		var d := m.distance_to(g["pts"][i])
		if d < best_d:
			best_d = d
			best = i
	return best


## The way along the streets from `a` to `b` (map positions): the points of the graph walked. It
## ends at the point from which the rest of the way, off the street, is shortest all told (a walk
## off the street counted twice, as it is through houses and yards).
static func route(a: Vector2, b: Vector2) -> Array:
	var g := graph()
	var pts: Array = g["pts"]
	var start := nearest_point(a)
	var dist := {start: 0.0}
	var prev := {}
	var open: Array = [start]
	var shut := {}
	while not open.is_empty():
		var best_k := 0
		for k in open.size():
			if float(dist[open[k]]) < float(dist[open[best_k]]):
				best_k = k
		var u: int = open.pop_at(best_k)
		shut[u] = true
		for e: Array in g["edges"][u]:
			var v: int = e[0]
			if shut.has(v):
				continue
			var nd := float(dist[u]) + float(e[1])
			if not dist.has(v) or nd < float(dist[v]):
				dist[v] = nd
				prev[v] = u
				if not open.has(v):
					open.append(v)
	var goal := start
	var goal_cost := INF
	for v: int in dist:
		var cost := float(dist[v]) + 2.0 * b.distance_to(pts[v])
		if cost < goal_cost:
			goal_cost = cost
			goal = v
	var out: Array = [goal]
	while out[0] != start and prev.has(out[0]):
		out.push_front(prev[out[0]])
	return out


## The compass point a map direction heads toward.
static func compass(d: Vector2) -> String:
	if d.length() < 0.001:
		return "on"
	var a := fposmod(atan2(d.x, d.y), TAU)  # 0 = north, clockwise
	return POINTS[int(round(a / (TAU / 8.0))) % 8]


static func paces(metres: float) -> int:
	return int(round(metres / PACE / 10.0)) * 10 if metres > 60.0 else maxi(5, int(round(metres / PACE / 5.0)) * 5)


## What stands nearest a map position (landmarks as {name, pos} in the world), within `r` map metres.
static func near(m: Vector2, landmarks: Array, r: float = 70.0, but: String = "") -> String:
	var best := ""
	var best_d := r
	for l: Dictionary in landmarks:
		if str(l["name"]) == but:
			continue
		var d := m.distance_to(to_map(l["pos"]))
		if d < best_d:
			best_d = d
			best = str(l["name"])
	return best


## The legs of a way: [{road, from, to (map), metres}], the street changing at each.
static func legs(path: Array) -> Array:
	var g := graph()
	var raw: Array = []
	for k in path.size() - 1:
		var i: int = path[k]
		var j: int = path[k + 1]
		var name: String = g["road"][j]
		var a: Vector2 = g["pts"][i]
		var b: Vector2 = g["pts"][j]
		if not raw.is_empty() and raw[-1]["road"] == name:
			raw[-1]["to"] = b
			raw[-1]["metres"] = float(raw[-1]["metres"]) + a.distance_to(b)
		else:
			raw.append({"road": name, "from": a, "to": b, "metres": a.distance_to(b)})
	# a few steps along another street where two cross are not worth saying: fold them in
	var out: Array = []
	if raw.size() > 1 and float(raw[0]["metres"]) < 45.0:
		raw[1]["from"] = raw[0]["from"]
		raw[1]["metres"] = float(raw[1]["metres"]) + float(raw[0]["metres"])
		raw.pop_front()
	for l: Dictionary in raw:
		if float(l["metres"]) < 45.0 and not out.is_empty():
			out[-1]["to"] = l["to"]
			out[-1]["metres"] = float(out[-1]["metres"]) + float(l["metres"])
		elif not out.is_empty() and out[-1]["road"] == l["road"]:
			out[-1]["to"] = l["to"]
			out[-1]["metres"] = float(out[-1]["metres"]) + float(l["metres"])
		else:
			out.append(l.duplicate())
	return out


## Directions from `from` to `to` (world positions) for a place called `name`: the streets, their
## headings, the paces, what you pass where you turn, and the side the place is on. In the emptied
## city, the monuments you pass are ruins, and said so.
static func directions(from: Vector3, to: Vector3, name: String, landmarks: Array, age: String = "") -> String:
	var a := to_map(from)
	var b := to_map(to)
	if a.distance_to(b) < 90.0:
		return "%s is just there, %s of you, about %d paces." % [_cap(name), compass(b - a), paces(a.distance_to(b))]
	var g := graph()
	var path := route(a, b)
	var parts: Array = []
	var onto: Vector2 = g["pts"][path[0]]
	if a.distance_to(onto) > 30.0:
		parts.append("go %s to %s (%d paces)" % [compass(onto - a), g["road"][path[0]], paces(a.distance_to(onto))])
	var ls := legs(path)
	var ruined := age == "fall"
	var named := ""
	for k in ls.size():
		var l: Dictionary = ls[k]
		var turn_at := near(l["to"], landmarks, 70.0, name)
		if turn_at == named:
			turn_at = ""
		elif turn_at != "":
			named = turn_at
		var said := "%s %s %s for %d paces" % ["take" if k == 0 else "then", l["road"], compass(l["to"] - l["from"]), paces(float(l["metres"]))]
		if k < ls.size() - 1 and turn_at != "":
			said += ", to %s%s" % ["the ruins of " if ruined and not turn_at.begins_with("the ruins") else "", turn_at]
		parts.append(said)
	var end: Vector2 = g["pts"][path[-1]]
	var last_dir: Vector2 = (ls[-1]["to"] - ls[-1]["from"]) if not ls.is_empty() else (end - a)
	var off := b - end
	var side := ""
	if off.length() > 12.0 and last_dir.length() > 0.001:
		var cross := last_dir.x * off.y - last_dir.y * off.x
		side = "on your left" if cross > 0.0 else "on your right"
	var tail := "%s is %s" % [name, side if side != "" else "there"]
	if off.length() > 40.0:
		tail += ", %d paces %s of the street" % [paces(off.length()), compass(off)]
	parts.append(tail)
	return _cap("; ".join(parts)) + "."


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


## Where you are, in words: the street you're on or nearest, and which way the Forum lies.
static func whereabouts(at: Vector3) -> String:
	var m := to_map(at)
	var g := graph()
	var i := nearest_point(m)
	var d := m.distance_to(g["pts"][i])
	var street := ("on %s" % g["road"][i]) if d < 30.0 else ("%d paces from %s" % [paces(d), g["road"][i]])
	var forum := Vector2.ZERO - m
	return "You are %s. The Forum is %s%s." % [street, "" if forum.length() < 60.0 else "%d paces " % paces(forum.length()),
		"here" if forum.length() < 60.0 else "to the " + compass(forum)]


## Where you are, as someone in the street would say it: "This is the Argiletum. The Forum's
## south-west of here, about 400 paces."
static func local_words(at: Vector3) -> String:
	var m := to_map(at)
	var g := graph()
	var i := nearest_point(m)
	var d := m.distance_to(g["pts"][i])
	var here := ("This is %s." % g["road"][i]) if d < 30.0 else ("%s is just %s of here." % [_cap(g["road"][i]), compass(g["pts"][i] - m)])
	var forum := Vector2.ZERO - m
	if forum.length() < 80.0:
		return here + " The Forum's right here."
	return here + " The Forum's %s of here, about %d paces." % [compass(forum), paces(forum.length())]


## The place someone asks the way to, from what they typed: one of `landmarks` (by the distinctive
## words of its name), or your house. {} if none is named.
static func asked_for(text: String, landmarks: Array, house: Vector3) -> Dictionary:
	var t := text.to_lower()
	if t.contains("my house") or t.contains("home"):
		return {"name": "your house", "pos": house}
	var skip := ["the", "temple", "of", "and", "great", "house", "houses", "on", "forum", "baths", "arch", "column", "church", "basilica"]
	var best := {}
	var best_n := 0
	for l: Dictionary in landmarks:
		var n := 0
		for w: String in str(l["name"]).to_lower().replace(",", "").replace("(", "").replace(")", "").split(" "):
			if w.length() > 3 and not skip.has(w) and t.contains(w):
				n += 1
		if n > best_n:
			best_n = n
			best = l
	return best
