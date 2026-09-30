extends Panel
## The plan of the city of Rome, and of your house, drawn from the same data the world is built from
## (city.json, republican_rome.json, urbs_house.gd), with north at the top, so the directions people
## give (urbs_plan.gd) can be followed on it.
##
## Drawn the way a map is meant to be read (a hierarchy, few labels far out and more close in, a
## halo under every word, nothing written over anything else, one colour to a class, a legend):
##   - the ground in faint relief, the Tiber and the city's other waters in blue, the walls in ink;
##   - the streets as cased roads, the main ones wider, named only when close enough to read;
##   - every monument standing in the age as an icon of its kind (a temple's pediment, a civic
##     block, a ring for the games, a blue disc for the baths and waters, a diamond for a column
##     or an arch, a cross for a church), whole in its colour, a ruin in grey outline; the
##     landmarks bigger and named first, the rest named as room allows or under the mouse;
##   - your house as a gold house in a ring, the way home in gold along the streets; you as a red
##     arrow the way you face; where you have been sent in purple, with the way there;
##   - the regions in capitals, faint, yielding to everything else;
##   - every word at the lettering's own size (Scribe 13, Lapidary 14: the bitmap faces blur at any
##     other), with a parchment halo, and never over another.
## Three zooms: the whole city, a quarter (750 m across), a street (320 m). The arrows move the
## map, C brings it back on you, H closes it in on your house, the wheel zooms, the mouse names
## whatever is under it in a tooltip. Keys: 1 the city, 2 your house, Z zoom, F or Esc close.
##
## Opened with M it is the live map: a smaller map in the corner, following you as you walk (it
## does not stop you), close in on where you are, with the icons but no names but yours and your
## house's; M again, or Esc, puts it away. The plan of the house on the tablinum wall, and the
## Marble Plan, open it large and still.

const RomeMap := preload("res://scripts/hall/rome_map.gd")
const House := preload("res://scripts/hall/urbs_house.gd")
const Plan := preload("res://scripts/hall/urbs_plan.gd")
const Lettering := preload("res://scripts/hall/lettering.gd")
const W := 640
const H := 360
const TITLE_H := 22
const FOOT_H := 18
const KEY_W := 150  # the key, in a column down the right of the plan (the city is square; the screen is not)
# the palette: parchment and ink, and one colour to a class of thing
const PARCHMENT := Color("e2d3ac")
const HALO := Color("efe3c4")
const INK := Color("2e2418")
const FAINT := Color("7a6a4c")
const WATER := Color("4f7aa0")
const WATER_EDGE := Color("2f5474")
const STREET := Color("f6ecd2")
const STREET_EDGE := Color("6a5a3e")
const WALL := Color("3a2c1c")
const TEMPLE := Color("a8321e")
const CIVIC := Color("6a4a2a")
const GAMES := Color("5c2d6a")
const BATHS := Color("2c6a86")
const RUIN := Color("8a8072")
const GOLD := Color("c8921e")
const YOU := Color("d0341e")
const ERRAND := Color("8a2a6a")
const REGULAR := Color("2e5a8a")
const GREEN := Color("4a7a3a")
const RED := TEMPLE  # kept for the house plan
const SPANS := [0.0, 750.0, 320.0]  # map metres across the map at each zoom (0: the whole city fitted)
const LIVE_SPANS := [450.0, 900.0]
const TEMPLES := ["temple", "round_temple", "double_temple", "shrine", "altar", "altar_open", "pantheon"]
const CIVICS := ["basilica", "curia", "hall", "vaulted_hall", "tabularium", "palace", "houses", "markets", "portico", "forum"]
const GAMES_KINDS := ["amphitheatre", "theatre", "circus", "open_circus", "stadium", "ludus"]
const WATERS := ["baths", "fountain_cone", "lacus", "cloaca"]
const GREENS := ["fig", "rock", "cave", "hut"]
const RELIEF := "res://assets/maps/rome_relief.png"

var view := "city"  # or "house"
var zoom := 0  # 0 the city, 1 a quarter, 2 a street (the live map: 0 close, 1 wider)
var zoomed: bool:  # kept for those who only ask for near or far
	get:
		return zoom > 0
	set(v):
		zoom = 1 if v else 0
var pan := Vector2.ZERO  # how far the arrows have moved the map from what it is centred on, in map metres
var live := false  # the live map: in the corner, following you, while you walk
var age := "heroic"
var year := -280
var you := Vector3.ZERO  # the player, in the world
var facing := 0.0  # the player's yaw
var landmarks: Array = []  # {name, pos}: the city's monuments with stories
var marks: Array = []  # {name, pos, kind}: your house, regulars, where you've been sent
var highlight := ""  # a place named in an errand
var regions: Array = []  # {c: Vector2 world, name}
var route: Array = []  # the way to where you've been sent, as world points along the streets (urbs_plan.way)
var home := Vector3.INF  # your house, for the way home
var on_home := false  # H: the plan closed in on your house
var _home_way: Array = []  # the way home along the streets from where it was last worked out
var _home_from := Vector3.INF
var _title: Label
var _hint: Label
var _under := ""
var _mouse := Vector2(-1, -1)
var _canvas: Control
var _labels: Array = []  # where words have been written this time, so none is written over another
var _relief: Texture2D


class Canvas extends Control:
	var panel: Panel

	func _draw() -> void:
		panel.call("_paint", self)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			panel.call("_hover", (event as InputEventMouseMotion).position)
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			var b := (event as InputEventMouseButton).button_index
			if b == MOUSE_BUTTON_WHEEL_UP or b == MOUSE_BUTTON_WHEEL_DOWN:
				panel.call("_wheel", 1 if b == MOUSE_BUTTON_WHEEL_UP else -1, (event as InputEventMouseButton).position)


func build(style: Callable, label: Callable) -> void:
	add_theme_stylebox_override("panel", style.call(0.97, Color("7a6040")))
	position = Vector2.ZERO
	size = Vector2(W, H)
	hide()
	_title = label.call(Color("e0b660"), true)
	_title.position = Vector2(10, 3)
	add_child(_title)
	_hint = label.call(Color("c8b890"))
	_hint.position = Vector2(10, H - FOOT_H)
	_hint.size = Vector2(W - 20, 16)
	add_child(_hint)
	_canvas = Canvas.new()
	_canvas.panel = self
	_canvas.position = Vector2(6, TITLE_H)
	_canvas.size = Vector2(W - 12, H - TITLE_H - FOOT_H)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.clip_contents = true
	add_child(_canvas)


func open(what: String, walking: bool = false) -> void:
	view = what
	live = walking
	zoom = 0
	pan = Vector2.ZERO
	on_home = false
	if live:
		size = Vector2(300, 230)
		position = Vector2(W - size.x - 6, 26)
		self_modulate = Color(1, 1, 1, 0.94)
		_canvas.position = Vector2(6, 20)
		_canvas.size = size - Vector2(12, 20 + FOOT_H)
	else:
		size = Vector2(W, H)
		position = Vector2.ZERO
		self_modulate = Color.WHITE
		_canvas.position = Vector2(6, TITLE_H)
		_canvas.size = size - Vector2(12, TITLE_H + FOOT_H)
	_hint.position = Vector2(10, size.y - FOOT_H)
	_hint.size = Vector2(size.x - 20, 16)
	show()
	refresh()


## Where you are now, for the live map.
func follow(at: Vector3, yaw: float) -> void:
	if at.distance_to(you) < 0.05 and absf(yaw - facing) < 0.01:
		return
	you = at
	facing = yaw
	_canvas.queue_redraw()


func refresh() -> void:
	var when := str(RomeMap.ages()[maxi(0, ["heroic", "early", "republic", "empire", "late", "collapse", "fall"].find(age))]["when"]) \
		if not RomeMap.ages().is_empty() else ""
	var scale_name: String = ["the city", "a quarter", "a street"][zoom] if not live else ["close", "wider"][zoom % 2]
	_title.text = ("The plan of Rome, %s: %s" % [when, scale_name]) if view == "city" else ("Your house, %s" % when)
	var keys := "Z zoom   arrows move   C on you   H your house   2 your house   F close" if view == "city" else "1 the city   F close"
	if live:
		keys = "M put away   Z %s   H home" % ("wider" if zoom == 0 else "closer")
		_title.text = "Rome, %s" % when
	_hint.text = keys
	_canvas.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var step: float = (float(SPANS[zoom]) if zoom > 0 else 1400.0) / 4.0
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			view = "city"
		KEY_2:
			view = "house"
		KEY_Z:
			zoom = (zoom + 1) % (2 if live else 3)
			pan = Vector2.ZERO
		KEY_C:
			pan = Vector2.ZERO
			on_home = false
		KEY_H:
			view = "city"
			on_home = not on_home
			pan = Vector2.ZERO
			if zoom == 0:
				zoom = 1
		KEY_LEFT:
			pan.x -= step
		KEY_RIGHT:
			pan.x += step
		KEY_UP:
			pan.y += step
		KEY_DOWN:
			pan.y -= step
		_:
			return
	get_viewport().set_input_as_handled()
	refresh()


## The wheel zooms, keeping what is under the mouse where it is.
func _wheel(dir: int, at: Vector2) -> void:
	if view != "city" or live:
		return
	var before := _frame()
	var under := _unpx(before, at)
	zoom = clampi(zoom + dir, 0, 2)
	if zoom == 0:
		pan = Vector2.ZERO
	else:
		var after := _frame()
		pan += under - _unpx(after, at)
	refresh()


# ---------- the city ----------

## Where the map is drawn on the canvas: all of it but the key's column down the right.
func _map_area() -> Rect2:
	return Rect2(Vector2.ZERO, _canvas.size - Vector2(0.0 if live else KEY_W, 0))


## The map's frame: map metres to the canvas, north up.
func _frame() -> Dictionary:
	var area := _map_area()
	var subject := home if on_home and home != Vector3.INF else you
	if zoom > 0 or live:
		var span: float = LIVE_SPANS[zoom % 2] if live else SPANS[zoom]
		var s := minf(area.size.x, area.size.y) / span
		return {"s": s, "c": Plan.to_map(subject) + pan, "o": area.position + area.size / 2.0}
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Array in RomeMap.city_data().get("outer", []):
		lo = Vector2(minf(lo.x, float(p[0])), minf(lo.y, float(p[1])))
		hi = Vector2(maxf(hi.x, float(p[0])), maxf(hi.y, float(p[1])))
	var s2 := minf(area.size.x / (hi.x - lo.x), area.size.y / (hi.y - lo.y)) * 0.96
	return {"s": s2, "c": (lo + hi) / 2.0 + pan, "o": area.position + area.size / 2.0}


func _px(f: Dictionary, m: Vector2) -> Vector2:
	return f["o"] + Vector2(m.x - f["c"].x, -(m.y - f["c"].y)) * float(f["s"])


func _pxa(f: Dictionary, p: Array) -> Vector2:
	return _px(f, Vector2(float(p[0]), float(p[1])))


func _unpx(f: Dictionary, px: Vector2) -> Vector2:
	var d: Vector2 = (px - (f["o"] as Vector2)) / float(f["s"])
	return Vector2((f["c"] as Vector2).x + d.x, (f["c"] as Vector2).y - d.y)


func _paint(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), PARCHMENT)
	if view == "house":
		_paint_house(c)
	else:
		_paint_city(c)


func _paint_city(c: Control) -> void:
	_labels = []
	var f := _frame()
	var area := _map_area()
	var city := RomeMap.city_data()
	var data := RomeMap.data()
	var s := float(f["s"])
	var close := zoom >= 1 or live  # near enough for the streets to be roads and the small things to show
	# the ground in relief, faint: it is there for the hills, not to be read
	var hm := RomeMap.height_map()
	if _relief == null and FileAccess.file_exists(RELIEF):
		var img := Image.load_from_file(RELIEF)
		if img:
			_relief = ImageTexture.create_from_image(img)
	if _relief and not hm.has("none"):
		var x0 := float(hm["x0"])
		var y0 := float(hm["y0"])
		var pxm := float(hm["px"])
		var tl := _px(f, Vector2(x0, y0 + (int(hm["h"]) - 1) * pxm))
		var br := _px(f, Vector2(x0 + (int(hm["w"]) - 1) * pxm, y0))
		c.draw_texture_rect(_relief, Rect2(tl, br - tl), false, Color(1, 1, 1, 0.38))
	var line := func(pts: Array, col: Color, w: float, closed: bool = false) -> void:
		var ps := PackedVector2Array()
		for p: Array in pts:
			ps.append(_pxa(f, p))
		if closed and ps.size() > 1:
			ps.append(ps[0])
		if ps.size() > 1:
			c.draw_polyline(ps, col, w, true)
	# where you can walk: a dotted edge
	var edge: Array = city.get("walkable", [])
	for i in edge.size():
		c.draw_dashed_line(_pxa(f, edge[i]), _pxa(f, edge[(i + 1) % edge.size()]), Color(FAINT, 0.7), 1.0, 4.0)
	# the waters: the Tiber cased in a darker blue, the island, the marsh, the lakes and the brooks of the age
	var tiber: Dictionary = data.get("tiber", {})
	var tw := maxf(3.0, float(tiber.get("width", 100)) * s)
	line.call(tiber.get("course", []), WATER_EDGE, tw + 2.0)
	line.call(tiber.get("course", []), WATER, tw)
	var isle: Variant = tiber.get("island")
	if isle is Dictionary and (isle as Dictionary).has("at"):
		c.draw_circle(_pxa(f, isle["at"]), maxf(3.0, float(isle.get("radius", 40)) * s), PARCHMENT)
	for w: Dictionary in RomeMap.waters(year):
		if w["kind"] == "stream":
			var ps := PackedVector2Array()
			for p: Vector3 in w["points"]:
				ps.append(_px(f, Plan.to_map(p)))
			c.draw_polyline(ps, WATER, maxf(1.5, float(w["width"]) / 0.35 * s), true)
		else:
			var at := _px(f, Plan.to_map(w["at"]))
			var r := maxf(2.0, float(w["r"]) / 0.35 * s)
			c.draw_circle(at, r, WATER if w["kind"] != "marsh" else Color("6a8a78"))
			c.draw_arc(at, r, 0, TAU, 24, WATER_EDGE, 1.0)
	# the walls: the Servian in ink, Aurelian's thinner far out
	var gates: Array = data.get("wall", {}).get("gates", [])
	if year < 537:
		line.call(gates.map(func(gt: Dictionary) -> Array: return gt["at"]), WALL, 3.0 if close else 2.0, true)
	if year >= 271 and city.has("aurelian_wall"):
		line.call(city["aurelian_wall"], Color(WALL, 0.7), 2.0, true)
	# the streets: cased roads, the main ones wider (far out, lines: the casing would swallow them)
	var roads: Array = city.get("roads", [])
	var road_w := func(r: Dictionary) -> float:
		var main := float(r["width"]) >= 5.0
		if not close:
			return 2.5 if main else 1.5
		return (7.0 if main else 4.5) if zoom < 2 or live else (11.0 if main else 7.0)
	if close:
		for r: Dictionary in roads:
			line.call(r["points"], STREET_EDGE, road_w.call(r) + 2.0)
	for r: Dictionary in roads:
		line.call(r["points"], STREET if close else STREET_EDGE, road_w.call(r))
	# the ways: home in gold, where you have been sent in purple
	if way_home().size() > 1:
		var hs := PackedVector2Array()
		for p: Vector3 in _home_way:
			hs.append(_px(f, Plan.to_map(p)))
		c.draw_polyline(hs, Color(INK, 0.35), 5.0, true)
		c.draw_polyline(hs, GOLD, 3.0, true)
	if route.size() > 1:
		var ps := PackedVector2Array()
		for p: Vector3 in route:
			ps.append(_px(f, Plan.to_map(p)))
		c.draw_polyline(ps, Color(INK, 0.35), 4.5, true)
		c.draw_polyline(ps, ERRAND, 2.5, true)
	# the gates, named close in
	if year < 537 and close and not live:
		for gt: Dictionary in gates:
			var p := _pxa(f, gt["at"])
			c.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), WALL)
			if zoom >= 2 and gt.has("name"):
				_label(c, p + Vector2(6, 0), str(gt["name"]), INK)
	# the monuments: an icon of each kind, the landmarks bigger; named by rank as room allows
	var named: Array = []  # [rank, name, px, radius]
	for m: Dictionary in city.get("monuments", []):
		var st := RomeMap.state(m, year)
		if st == "" or st == "gone":
			continue
		var big: bool = m.get("landmark", false) or RomeMap.footprint(m) >= 14.0
		if not close and not big:
			continue
		var at := _pxa(f, m["at"])
		if not Rect2(area.position - Vector2(12, 12), area.size + Vector2(24, 24)).has_point(at):
			continue
		var sz := (8.0 if big else 5.0) if zoom < 2 else (11.0 if big else 7.0)
		_icon(c, at, str(m["kind"]), st == "whole", sz)
		if not m.has("note"):
			continue
		var rank := (10.0 if m.get("landmark", false) else 0.0) + RomeMap.footprint(m)
		if zoom == 0 and not live and not m.get("landmark", false):
			continue
		if zoom == 1 and not big:
			continue
		if live and not (m.get("landmark", false) and zoom == 0):
			continue
		named.append([rank, _short(str(m["name"])), at, sz / 2.0 + 2.0])
	# your house, the regulars, where you have been sent
	for mk: Dictionary in marks:
		var p := _px(f, Plan.to_map(mk["pos"]))
		match str(mk["kind"]):
			"house":
				_house_glyph(c, p)
				_labels.append(Rect2(p - Vector2(11, 12), Vector2(22, 22)))
				named.append([100.0, "Your house", p, 12.0])
			"regular":
				c.draw_circle(p, 3.5, HALO)
				c.draw_circle(p, 2.5, REGULAR)
				if zoom >= 2:
					named.append([1.0, str(mk["name"]), p, 5.0])
			"sent":
				c.draw_arc(p, 8.0, 0, TAU, 20, HALO, 4.0)
				c.draw_arc(p, 8.0, 0, TAU, 20, ERRAND, 2.0)
				named.append([90.0, str(mk["name"]), p, 10.0])
	if highlight != "":
		for l: Dictionary in landmarks:
			if str(l["name"]) == highlight:
				var p := _px(f, Plan.to_map(l["pos"]))
				c.draw_arc(p, 9.0, 0, TAU, 20, HALO, 4.0)
				c.draw_arc(p, 9.0, 0, TAU, 20, ERRAND, 2.0)
				named.append([95.0, _short(highlight), p, 11.0])
	# you: an arrow the way you face, haloed, named
	var me := _px(f, Plan.to_map(you))
	var ahead := Vector2(-sin(facing), -cos(facing))  # world -Z is north, up on the plan
	var side := Vector2(-ahead.y, ahead.x)
	var tri := PackedVector2Array([me + ahead * 10.0, me - ahead * 6.0 + side * 6.0, me - ahead * 3.0, me - ahead * 6.0 - side * 6.0])
	c.draw_colored_polygon(PackedVector2Array([me + ahead * 13.0, me - ahead * 9.0 + side * 9.0, me - ahead * 5.0, me - ahead * 9.0 - side * 9.0]), HALO)
	c.draw_colored_polygon(tri, YOU)
	_labels.append(Rect2(me - Vector2(11, 11), Vector2(22, 22)))
	named.append([200.0, "You", me, 13.0])
	if live and home != Vector3.INF and home.distance_to(you) > 40.0:  # which way home lies, when it is off the live map
		var hp := _px(f, Plan.to_map(home))
		if not area.has_point(hp):
			var dir := (hp - me).normalized()
			var tip := me + dir * 30.0
			c.draw_line(me + dir * 16.0, tip, HALO, 5.0)
			c.draw_line(me + dir * 16.0, tip, GOLD, 2.5)
			c.draw_colored_polygon(PackedVector2Array([tip + dir * 6.0, tip - dir * 2.0 + Vector2(-dir.y, dir.x) * 5.0, tip - dir * 2.0 - Vector2(-dir.y, dir.x) * 5.0]), GOLD)
	# north, and a scale of five hundred paces: their room is taken before any name is written
	var n := Vector2(area.end.x - 22, area.position.y + 24)
	var bar := 500.0 * Plan.PACE * s
	if bar > area.size.x * 0.6:
		bar /= 5.0
	var b0 := Vector2(area.end.x - 16 - bar, area.end.y - 12)
	_labels.append(Rect2(n - Vector2(14, 20), Vector2(28, 56)))
	_labels.append(Rect2(b0 - Vector2(4, 20), Vector2(bar + 8, 26)))
	# the names, by rank, each where it fits, none over another: you, your house and the errand
	# first, then the landmarks, then the streets (the directions are given by them), then the rest
	named.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var name_of := func(entry: Array) -> void:
		var col := INK
		match str(entry[1]):
			"You":
				col = YOU
			"Your house":
				col = GOLD.darkened(0.25)
		if float(entry[0]) >= 90.0 and float(entry[0]) < 100.0:
			col = ERRAND
		_label_by(c, entry[2], float(entry[3]), str(entry[1]), col)
	for entry: Array in named:
		if float(entry[0]) >= 10.0:
			name_of.call(entry)
	if zoom >= 1 and not live:
		var by_width := roads.duplicate()
		by_width.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["width"]) > float(b["width"]))
		for r: Dictionary in by_width:
			_street_name(c, f, r)
	for entry: Array in named:
		if float(entry[0]) < 10.0:
			name_of.call(entry)
	# the regions, in capitals, faint, wherever nothing else is written
	if zoom <= 1 and not live:
		for r: Dictionary in regions:
			var p := _px(f, Plan.to_map(Vector3(r["c"].x, 0, r["c"].y)))
			var name := _short(str(r["name"]).split(", ")[-1]).to_upper()
			_label(c, p - Vector2(Lettering.width(name, true) / 2.0, -5), name, Color(FAINT, 0.85), true)
	c.draw_line(n + Vector2(0, 12), n - Vector2(0, 12), HALO, 5.0)
	c.draw_line(n + Vector2(0, 12), n - Vector2(0, 12), INK, 2.0)
	c.draw_colored_polygon(PackedVector2Array([n - Vector2(0, 17), n - Vector2(6, 8), n + Vector2(6, -8)]), INK)
	_text(c, n + Vector2(-5, 30), "N", INK, true)
	c.draw_line(b0, b0 + Vector2(bar, 0), HALO, 5.0)
	c.draw_line(b0, b0 + Vector2(bar, 0), INK, 2.0)
	for x: float in [0.0, bar]:
		c.draw_line(b0 + Vector2(x, -4), b0 + Vector2(x, 4), INK, 2.0)
	_text(c, b0 + Vector2(0, -6), "500 paces" if bar > area.size.x * 0.12 else "100 paces", INK)
	if not live:
		_legend(c, area)
	if _under != "" and _mouse.x >= 0.0 and not live:  # what is under the mouse, in a slip beside it
		var tw2 := Lettering.width(_under) + 12.0
		var at := _mouse + Vector2(14, 10)
		if at.x + tw2 > c.size.x:
			at.x = _mouse.x - tw2 - 6.0
		if at.y + 18.0 > area.end.y:
			at.y = _mouse.y - 22.0
		c.draw_rect(Rect2(at, Vector2(tw2, 18)), HALO)
		c.draw_rect(Rect2(at, Vector2(tw2, 18)), INK, false, 1.0)
		c.draw_string(Lettering.SCRIBE, at + Vector2(6, 13), _under, HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY, INK)


## A monument's icon: a pediment for a temple, a block for a civic building, a ring for the games,
## a blue disc for the baths and waters, a diamond for a column, an arch or a tomb, a cross for a
## church, a green dot for a tree or a hut. Whole in its colour; a ruin in grey outline.
func _icon(c: Control, p: Vector2, kind: String, whole: bool, sz: float) -> void:
	var h := sz / 2.0
	if kind in TEMPLES:
		var col := TEMPLE if whole else RUIN
		var body := Rect2(p + Vector2(-h, -h * 0.2), Vector2(sz, h * 1.1))
		var roof := PackedVector2Array([p + Vector2(-h - 1.0, -h * 0.2), p + Vector2(0, -h - 1.5), p + Vector2(h + 1.0, -h * 0.2)])
		c.draw_rect(body.grow(1.0), HALO)
		if whole:
			c.draw_rect(body, col)
			c.draw_colored_polygon(roof, col)
		else:
			c.draw_rect(body, col, false, 1.0)
			c.draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2], roof[0]]), col, 1.0)
	elif kind in CIVICS:
		var col := CIVIC if whole else RUIN
		var body := Rect2(p - Vector2(h, h * 0.7), Vector2(sz, sz * 0.7))
		c.draw_rect(body.grow(1.0), HALO)
		c.draw_rect(body, col, whole, 1.0)
	elif kind in GAMES_KINDS:
		var col := GAMES if whole else RUIN
		c.draw_circle(p, h + 1.0, HALO)
		if whole:
			c.draw_circle(p, h, col)
			c.draw_circle(p, h * 0.45, HALO)
		else:
			c.draw_arc(p, h, 0, TAU, 16, col, 1.0)
	elif kind in WATERS:
		var col := BATHS if whole else RUIN
		c.draw_circle(p, h + 1.0, HALO)
		if whole:
			c.draw_circle(p, h, col)
			c.draw_circle(p + Vector2(-h * 0.3, -h * 0.3), h * 0.25, HALO)
		else:
			c.draw_arc(p, h, 0, TAU, 16, col, 1.0)
	elif kind == "church":
		var col := INK if whole else RUIN
		c.draw_line(p + Vector2(0, -h - 1), p + Vector2(0, h + 1), HALO, 4.0)
		c.draw_line(p + Vector2(-h * 0.7, -h * 0.3), p + Vector2(h * 0.7, -h * 0.3), HALO, 4.0)
		c.draw_line(p + Vector2(0, -h - 1), p + Vector2(0, h + 1), col, 2.0)
		c.draw_line(p + Vector2(-h * 0.7, -h * 0.3), p + Vector2(h * 0.7, -h * 0.3), col, 2.0)
	elif kind in GREENS:
		c.draw_circle(p, h * 0.7 + 1.0, HALO)
		c.draw_circle(p, h * 0.7, GREEN if whole else RUIN)
	else:  # a column, an obelisk, an arch, a tomb, statues, the rostra: a diamond
		var col := INK if whole else RUIN
		var d := PackedVector2Array([p + Vector2(0, -h), p + Vector2(h * 0.7, 0), p + Vector2(0, h), p + Vector2(-h * 0.7, 0)])
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -h - 1.5), p + Vector2(h * 0.7 + 1.5, 0), p + Vector2(0, h + 1.5), p + Vector2(-h * 0.7 - 1.5, 0)]), HALO)
		if whole:
			c.draw_colored_polygon(d, col)
		else:
			c.draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), col, 1.0)


## Your house: a gold house with a roof and a door, in a ring, seen at once.
func _house_glyph(c: Control, p: Vector2) -> void:
	c.draw_arc(p, 12.0, 0, TAU, 24, HALO, 4.0)
	c.draw_arc(p, 12.0, 0, TAU, 24, GOLD, 2.0)
	c.draw_rect(Rect2(p - Vector2(6, 1), Vector2(12, 8)), GOLD)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(0, -8), p + Vector2(8, -1)]), GOLD)
	c.draw_rect(Rect2(p - Vector2(6, 1), Vector2(12, 8)), INK, false, 1.0)
	c.draw_polyline(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(0, -8), p + Vector2(8, -1)]), INK, 1.0)
	c.draw_rect(Rect2(p + Vector2(-2, 2), Vector2(4, 5)), INK)


## A street's name along its longest stretch in view, upright, if the stretch is long enough to
## carry it and nothing is written there yet.
func _street_name(c: Control, f: Dictionary, r: Dictionary) -> void:
	var pts: Array = r["points"]
	var txt := _short(str(r["name"]))
	var tw := Lettering.width(txt)
	var area := _map_area()
	var inner := Rect2(area.position + Vector2(24, 24), area.size - Vector2(48, 48))
	# the runs of stretches that keep near enough to one line, in view; the longest carries the name
	var runs: Array = []  # [length, [px points]]
	var run: Array = []
	var run_l := 0.0
	for i in pts.size() - 1:
		var pa := _pxa(f, pts[i])
		var pb := _pxa(f, pts[i + 1])
		var clipped := _clip(pa, pb, inner)  # a stretch running off the map is named on the part of it in view
		var seen := not clipped.is_empty()
		if seen:
			pa = clipped[0]
			pb = clipped[1]
		var bends := run.size() >= 2 and absf(angle_difference((pb - pa).angle(), ((run[-1] as Vector2) - (run[-2] as Vector2)).angle())) > 0.4
		if not seen or bends:
			if run.size() >= 2:
				runs.append([run_l, run])
			run = [pa, pb] if seen else []
			run_l = pa.distance_to(pb) if seen else 0.0
			continue
		if run.is_empty():
			run = [pa]
		run.append(pb)
		run_l += pa.distance_to(pb)
	if run.size() >= 2:
		runs.append([run_l, run])
	runs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	# tried along the longest runs, at the middle first and then either side of it, until it fits
	for run_entry: Array in runs.slice(0, 3):
		if float(run_entry[0]) < tw + 10.0:
			break
		var line: Array = run_entry[1]
		var total := float(run_entry[0])
		for frac: float in [0.5, 0.35, 0.65, 0.2, 0.8]:
			var along := total * frac
			if along < tw / 2.0 + 4.0 or along > total - tw / 2.0 - 4.0:
				continue
			var mid: Vector2 = line[0]
			var ang := 0.0
			var walked := 0.0
			for i in line.size() - 1:
				var seg := (line[i] as Vector2).distance_to(line[i + 1])
				if walked + seg >= along:
					mid = (line[i] as Vector2).lerp(line[i + 1], (along - walked) / maxf(seg, 0.001))
					ang = ((line[i + 1] as Vector2) - (line[i] as Vector2)).angle()
					break
				walked += seg
			if ang > PI / 2.0 or ang < -PI / 2.0:
				ang += PI
			var dir := Vector2(cos(ang), sin(ang))
			var perp := Vector2(-dir.y, dir.x)
			# the room the words take, as the box round their slant
			var corners: Array = [mid - dir * tw / 2.0 - perp * 8.0, mid + dir * tw / 2.0 - perp * 8.0, mid + dir * tw / 2.0 + perp * 5.0, mid - dir * tw / 2.0 + perp * 5.0]
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for q: Vector2 in corners:
				lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
				hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
			var box := Rect2(lo, hi - lo)
			if box.position.x < area.position.x or box.end.x > area.end.x or box.position.y < area.position.y or box.end.y > area.end.y:
				continue
			if _labels.any(func(o: Rect2) -> bool: return o.intersects(box)):
				continue
			_labels.append(box)
			c.draw_set_transform(mid, ang)
			_text(c, Vector2(-tw / 2.0, -3), txt, Color("4a3820"))
			c.draw_set_transform(Vector2.ZERO)
			return


## The part of a stretch that lies in a box: [a, b], or nothing if none of it does.
static func _clip(a: Vector2, b: Vector2, box: Rect2) -> Array:
	var inside := func(p: Vector2) -> bool: return box.has_point(p)
	if inside.call(a) and inside.call(b):
		return [a, b]
	var hits: Array = []
	for edge: Array in [[box.position, Vector2(box.end.x, box.position.y)], [Vector2(box.end.x, box.position.y), box.end],
			[box.end, Vector2(box.position.x, box.end.y)], [Vector2(box.position.x, box.end.y), box.position]]:
		var h: Variant = Geometry2D.segment_intersects_segment(a, b, edge[0], edge[1])
		if h != null:
			hits.append(h)
	if inside.call(a) and hits.size() >= 1:
		return [a, hits[0]]
	if inside.call(b) and hits.size() >= 1:
		return [hits[0], b]
	if hits.size() >= 2:
		return [hits[0], hits[1]]
	return []


## The key, in the column down the right: what each mark is.
func _legend(c: Control, area: Rect2) -> void:
	var x0 := area.end.x
	c.draw_rect(Rect2(Vector2(x0, 0), Vector2(c.size.x - x0, c.size.y)), Color("cbb98e"))
	c.draw_line(Vector2(x0, 0), Vector2(x0, c.size.y), INK, 1.0)
	_text(c, Vector2(x0 + 12, 20), "KEY", INK, true)
	var items: Array = [["you", "you"], ["house", "your house"], ["temple", "temple, shrine"], ["basilica", "civic building"],
		["circus", "games"], ["baths", "baths, water"], ["column", "column, arch, tomb"], ["church", "church"],
		["ruin", "ruin"], ["home", "the way home"], ["errand", "an errand"], ["regular", "someone you know"]]
	var y := 42.0
	for it: Array in items:
		var p := Vector2(x0 + 18, y - 4)
		match str(it[0]):
			"you":
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(4, 4), p, p + Vector2(-4, 4)]), YOU)
			"house":
				c.draw_rect(Rect2(p - Vector2(4, 0), Vector2(8, 5)), GOLD)
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(0, -5), p + Vector2(5, 0)]), GOLD)
			"ruin":
				_icon(c, p, "temple", false, 7.0)
			"home":
				c.draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), GOLD, 3.0)
			"errand":
				c.draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), ERRAND, 2.5)
			"regular":
				c.draw_circle(p, 2.5, REGULAR)
			_:
				_icon(c, p, str(it[0]), true, 7.0)
		c.draw_string(Lettering.SCRIBE, Vector2(x0 + 32, y), str(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY, INK)
		y += 19.0
	if _under != "":  # what the mouse is on, written out in full here too
		var words: PackedStringArray = _under.split(" ")
		var lines: Array = [""]
		for w: String in words:
			var trial: String = (str(lines[-1]) + " " + w).strip_edges()
			if Lettering.width(trial) > float(c.size.x - x0) - 20.0 and str(lines[-1]) != "":
				lines.append(w)
			else:
				lines[-1] = trial
		y += 6.0
		for l: String in lines:
			c.draw_string(Lettering.SCRIBE, Vector2(x0 + 12, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, Lettering.BODY, Color("4a3820"))
			y += 15.0


## The way home along the streets from about where you are (worked out again once you have walked
## a dozen paces from where it was last worked out).
func way_home() -> Array:
	if home != Vector3.INF and (_home_from == Vector3.INF or _home_from.distance_to(you) > 12.0):
		_home_from = you
		_home_way = Plan.way(you, home)
	return _home_way


## Words at the lettering's own size, with a parchment halo under them so they read over anything.
func _text(c: Control, at: Vector2, text: String, col: Color, capitals: bool = false) -> void:
	var font: Font = Lettering.LAPIDARY if capitals else Lettering.SCRIBE
	var fs: int = Lettering.TITLE if capitals else Lettering.BODY
	for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]:
		c.draw_string(font, at + d, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HALO)
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## A label at a spot (its baseline's left end), unless it would lie over one already written or
## off the map. True if written.
func _label(c: Control, at: Vector2, text: String, col: Color, capitals: bool = false) -> bool:
	var w := Lettering.width(text, capitals)
	var h := 14.0
	var area := _map_area()
	var r := Rect2(at - Vector2(0, h - 3.0), Vector2(w, h))
	if r.position.x < area.position.x or r.end.x > area.end.x or r.position.y < area.position.y or r.end.y > area.end.y:
		return false
	for o: Rect2 in _labels:
		if o.intersects(r):
			return false
	_labels.append(r)
	_text(c, at, text, col, capitals)
	return true


## A point's name beside its mark, tried where a map puts names: upper right, upper left, lower
## right, lower left, then right, left, above, below; left out if none is free.
func _label_by(c: Control, p: Vector2, clear: float, text: String, col: Color) -> bool:
	var w := Lettering.width(text)
	var tries: Array = [Vector2(clear, -2), Vector2(-clear - w, -2), Vector2(clear, 12), Vector2(-clear - w, 12),
		Vector2(clear, 5), Vector2(-clear - w, 5), Vector2(-w / 2.0, -clear - 3), Vector2(-w / 2.0, clear + 12)]
	for t: Vector2 in tries:
		if _label(c, p + t, text, col):
			return true
	return false


static func Lettering_width(font: Font, text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


static func _short(name: String) -> String:
	return name.trim_prefix("the ").trim_prefix("The ")


func _hover(at: Vector2) -> void:
	_mouse = at
	if view != "city":
		_under = _house_room_at(at)
		refresh()
		return
	var f := _frame()
	var best := ""
	var best_d := 12.0
	for mk: Dictionary in marks:
		var d := _px(f, Plan.to_map(mk["pos"])).distance_to(at)
		if d < best_d:
			best_d = d
			best = str(mk["name"])
	for m: Dictionary in RomeMap.city_data().get("monuments", []):
		var st := RomeMap.state(m, year)
		if st == "" or st == "gone":
			continue
		var d := _pxa(f, m["at"]).distance_to(at)
		if d < best_d:
			best_d = d
			best = str(m["name"]) + (" (a ruin)" if st == "ruin" else "")
	for r: Dictionary in RomeMap.city_data().get("roads", []):
		var pts: Array = r["points"]
		for i in pts.size() - 1:
			var a := _pxa(f, pts[i])
			var b := _pxa(f, pts[i + 1])
			var q := Geometry2D.get_closest_point_to_segment(at, a, b)
			if q.distance_to(at) < best_d * 0.6:
				best_d = q.distance_to(at) / 0.6
				best = str(r["name"])
	if best == "":
		for w: Dictionary in RomeMap.waters(year):
			if w["kind"] != "stream" and _px(f, Plan.to_map(w["at"])).distance_to(at) < float(w["r"]) / 0.35 * float(f["s"]):
				best = str(w["name"])
	if best != _under:
		_under = best
	_canvas.queue_redraw()


# ---------- the house ----------
func _house_frame() -> Dictionary:
	var s := minf((_canvas.size.y - 40.0) / 24.0, 12.0)
	return {"s": s, "o": Vector2(20 + 8.0 * s, 16 + 12.0 * s)}


## A house position (x across, +z toward the street) on the plan: the street at the bottom.
func _hpx(f: Dictionary, x: float, z: float) -> Vector2:
	return f["o"] + Vector2(x, z) * float(f["s"])


func _paint_house(c: Control) -> void:
	var f := _house_frame()
	var font: Font = Lettering.SCRIBE
	var fs: int = Lettering.BODY
	var fallen := age == "fall"
	for id: String in House.ROOMS:
		var r: Array = House.ROOMS[id]
		var a := _hpx(f, r[0], r[1])
		var b := _hpx(f, r[2], r[3])
		var col := Color("c8b890") if id != "garden" else Color("a8a070")
		if fallen:
			col = col.darkened(0.2)
		c.draw_rect(Rect2(a, b - a), col)
		if id != "shops":
			var name: String = House.NAMES.get(id, id)
			c.draw_string(font, (a + b) / 2.0 - Vector2(Lettering.width(name) / 2.0, -4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	for x: float in [-5.0, 5.0]:
		c.draw_string(font, _hpx(f, x - 1.6, 10.4), "shop", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var imp := House.IMPLUVIUM
	c.draw_rect(Rect2(_hpx(f, imp[0], imp[1]), Vector2(imp[2] - imp[0], imp[3] - imp[1]) * float(f["s"])), WATER if age in ["heroic", "early", "republic", "empire", "late"] else Color("9a9080"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 509 + ["heroic", "early", "republic", "empire", "late", "collapse", "fall"].find(age)
	for w: Array in House.walls_for(age):
		var broken := fallen and rng.randf() < 0.3
		var bricked := House.BRICKED.any(func(bk: Array) -> bool: return bk[0] == age and bk.slice(1) == w)
		var col := RED if bricked else INK
		var a := _hpx(f, w[0], w[1])
		var b := _hpx(f, w[2], w[3])
		if broken:
			c.draw_dashed_line(a, b, Color(INK, 0.5), 2.0, 4.0)
		else:
			c.draw_line(a, b, col, 3.0)
	var street_y := _hpx(f, 0, 12.0).y + 12.0
	c.draw_string(font, Vector2(_hpx(f, -8, 12).x, street_y), "the street: the Argiletum, down to the Forum (south-west)", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FAINT)
	var tx := _hpx(f, 8.0, 0).x + 18.0  # what the house is like now, and the room under the mouse
	var note := str(House.data().get("house", {}).get(age, ""))
	if _under != "":
		note = _under
	c.draw_multiline_string(font, Vector2(tx, 24), note, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - tx - 12, fs, 12, INK)
	var bricked_note := "Red: doorways bricked up." if House.BRICKED.any(func(bk: Array) -> bool: return bk[0] == age) else ""
	if age == "heroic":
		bricked_note = "Red: no shops yet, a blank wall to the street."
	if fallen:
		bricked_note = "Dashed: walls fallen. No roof."
	if bricked_note != "":
		c.draw_string(font, Vector2(tx, c.size.y - 10), bricked_note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FAINT)


func _house_room_at(at: Vector2) -> String:
	var f := _house_frame()
	for id: String in House.ROOMS:
		var r: Array = House.ROOMS[id]
		if Rect2(_hpx(f, r[0], r[1]), Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1])) * float(f["s"])).has_point(at):
			var n := House.room_note(id, age)
			var name: String = House.NAMES.get(id, id)
			return "%s: %s" % [name.capitalize(), n] if n != "" else name.capitalize()
	return ""
