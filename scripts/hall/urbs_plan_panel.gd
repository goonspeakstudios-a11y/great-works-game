extends Panel
## The plan of the city of Rome, and of your house, drawn from the same data the world is built from
## (city.json, republican_rome.json, urbs_house.gd), with north at the top, so the directions people
## give (urbs_plan.gd) can be followed on it: the river and the island, the Servian wall and (from
## AD 271) Aurelian's, every street with its name, every monument standing in the age (ruins in grey),
## the regions, your house, the regulars' places, where you have been sent, and you. Z zooms in on
## where you stand; the mouse names what is under it. The house's plan shows its rooms as they are in
## the age, and the walls and doorways, bricked up or fallen.
##
## Keys: 1 the city, 2 your house, Z zoom, H close in on your house, F or Esc close. Your house
## is marked with a gold house and the way home is drawn in gold along the streets, on the plan
## and on the live map, so it is never lost.
##
## Opened with M it is the live map: a smaller map in the corner, following you as you walk (it does
## not stop you), close in on where you are; M again, or Esc, puts it away. The plan of the house on
## the tablinum wall, and the Marble Plan, open it large and still.

const RomeMap := preload("res://scripts/hall/rome_map.gd")
const House := preload("res://scripts/hall/urbs_house.gd")
const Plan := preload("res://scripts/hall/urbs_plan.gd")
const W := 616
const H := 336
const PARCHMENT := Color("d8c8a0")
const INK := Color("3a2e20")
const FAINT := Color("8a7a5a")
const RED := Color("8a2a1a")
const GOLD := Color("b8862a")
const WATER := Color("6a8aa0")

var view := "city"  # or "house"
var zoomed := false
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
var home := Vector3.INF  # your house, for the way home on the live map
var _home_way: Array = []  # the way home along the streets from where it was last worked out
var _home_from := Vector3.INF
var on_home := false  # H: the plan closed in on your house
var _title: Label
var _hint: Label
var _under := ""
var _canvas: Control
var _labels: Array = []
var _relief: Texture2D
const RELIEF := "res://assets/maps/rome_relief.png"  # where labels have been drawn this time, so they don't pile up


class Canvas extends Control:
	var panel: Panel

	func _draw() -> void:
		panel.call("_paint", self)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			panel.call("_hover", (event as InputEventMouseMotion).position)


func build(style: Callable, label: Callable) -> void:
	add_theme_stylebox_override("panel", style.call(0.97, Color("7a6040")))
	position = Vector2(12, 12)
	size = Vector2(W, H)
	hide()
	_title = label.call(Color("e0b660"), true)
	_title.position = Vector2(12, 6)
	add_child(_title)
	_hint = label.call(Color("a89878"))
	_hint.position = Vector2(12, H - 20)
	_hint.size = Vector2(W - 24, 16)
	add_child(_hint)
	_canvas = Canvas.new()
	_canvas.panel = self
	_canvas.position = Vector2(12, 28)
	_canvas.size = Vector2(W - 24, H - 52)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.clip_contents = true
	add_child(_canvas)


func open(what: String, walking: bool = false) -> void:
	view = what
	live = walking
	zoomed = walking
	if live:
		size = Vector2(300, 250)
		position = Vector2(640 - size.x - 8, 30)
		self_modulate = Color(1, 1, 1, 0.92)
	else:
		size = Vector2(W, H)
		position = Vector2(12, 12)
		self_modulate = Color.WHITE
	_hint.position = Vector2(12, size.y - 20)
	_hint.size = Vector2(size.x - 24, 16)
	_canvas.size = size - Vector2(24, 52)
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
	_title.text = ("The plan of Rome, %s" % when) if view == "city" else ("Your house, %s" % when)
	var keys := "1 the city   2 your house   %s   H your house   F close" % ("Z whole city" if zoomed else "Z closer") if view == "city" else "1 the city   2 your house   F close"
	if live:
		keys = "M put away   Z %s   H home" % ("whole city" if zoomed else "closer")
		_title.text = _title.text.replace("The plan of Rome", "Rome")
	_hint.text = keys + ("    " + _under if _under != "" and not live else "")
	_canvas.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			view = "city"
		KEY_2:
			view = "house"
		KEY_Z:
			zoomed = not zoomed
			on_home = false
		KEY_H:
			view = "city"
			zoomed = true
			on_home = not on_home
		_:
			return
	get_viewport().set_input_as_handled()
	refresh()


# ---------- the city ----------

## The map's frame: map metres to the canvas, north up.
func _frame() -> Dictionary:
	var size_px := _canvas.size
	if zoomed:
		var c := Plan.to_map(you if not (on_home and home != Vector3.INF) else home)
		var span := 700.0 if live else 900.0
		var s := minf(size_px.x, size_px.y) / span
		return {"s": s, "c": c, "o": size_px / 2.0}
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Array in RomeMap.city_data().get("outer", []):
		lo = Vector2(minf(lo.x, float(p[0])), minf(lo.y, float(p[1])))
		hi = Vector2(maxf(hi.x, float(p[0])), maxf(hi.y, float(p[1])))
	var s2 := minf(size_px.x / (hi.x - lo.x), size_px.y / (hi.y - lo.y)) * 0.96
	return {"s": s2, "c": (lo + hi) / 2.0, "o": size_px / 2.0}


func _px(f: Dictionary, m: Vector2) -> Vector2:
	return f["o"] + Vector2(m.x - f["c"].x, -(m.y - f["c"].y)) * float(f["s"])


func _pxa(f: Dictionary, p: Array) -> Vector2:
	return _px(f, Vector2(float(p[0]), float(p[1])))


func _paint(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), PARCHMENT)
	if view == "house":
		_paint_house(c)
	else:
		_paint_city(c)


func _paint_city(c: Control) -> void:
	_labels = []
	var f := _frame()
	var font := c.get_theme_default_font()
	var fs := c.get_theme_default_font_size()
	var city := RomeMap.city_data()
	var data := RomeMap.data()
	var hm := RomeMap.height_map()  # the ground in relief, from the same height map as the world
	if _relief == null and FileAccess.file_exists(RELIEF):
		var img := Image.load_from_file(RELIEF)  # straight from the file: the png needs no import record
		if img:
			_relief = ImageTexture.create_from_image(img)
	if _relief and not hm.has("none"):
		var x0 := float(hm["x0"])
		var y0 := float(hm["y0"])
		var px := float(hm["px"])
		var tl := _px(f, Vector2(x0, y0 + (int(hm["h"]) - 1) * px))
		var br := _px(f, Vector2(x0 + (int(hm["w"]) - 1) * px, y0))
		c.draw_texture_rect(_relief, Rect2(tl, br - tl), false)
	var line := func(pts: Array, col: Color, w: float, closed: bool = false) -> void:
		var ps := PackedVector2Array()
		for p: Array in pts:
			ps.append(_pxa(f, p))
		if closed and ps.size() > 1:
			ps.append(ps[0])
		if ps.size() > 1:
			c.draw_polyline(ps, col, w, true)
	line.call(city.get("walkable", []), Color(FAINT, 0.9) if year >= 271 else Color(FAINT, 0.25), 3.0 if year >= 271 else 1.0, true)
	var gates: Array = data.get("wall", {}).get("gates", [])
	if year < 537:
		line.call(gates.map(func(gt: Dictionary) -> Array: return gt["at"]), Color(INK, 0.6), 2.0, true)
	var tiber: Dictionary = data.get("tiber", {})
	line.call(tiber.get("course", []), WATER, maxf(3.0, float(tiber.get("width", 100)) * float(f["s"])))
	var isle: Variant = tiber.get("island")
	if isle is Dictionary and (isle as Dictionary).has("at"):
		c.draw_circle(_pxa(f, isle["at"]), maxf(3.0, float(isle.get("radius", 40)) * float(f["s"])), PARCHMENT)
	for r: Dictionary in city.get("roads", []):
		line.call(r["points"], Color("9a8a68"), maxf(1.5, float(r["width"]) * float(f["s"]) * 2.0))
	if way_home().size() > 1:  # the way home, gold, along the streets
		var hs := PackedVector2Array()
		for p: Vector3 in _home_way:
			hs.append(_px(f, Plan.to_map(p)))
		c.draw_polyline(hs, Color(GOLD, 0.75), 3.0, true)
	if route.size() > 1:  # the way to where you've been sent, faint, along the streets
		var ps := PackedVector2Array()
		for p: Vector3 in route:
			ps.append(_px(f, Plan.to_map(p)))
		c.draw_polyline(ps, Color("8a2a6a", 0.55), 2.5, true)
	for m: Dictionary in city.get("monuments", []):
		var st := RomeMap.state(m, year)
		if st == "" or st == "gone":
			continue
		var at := _pxa(f, m["at"])
		var sz := clampf(RomeMap.footprint(m) / 0.35 * float(f["s"]) * 0.6, 2.0, 18.0)
		c.draw_rect(Rect2(at - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), RED if st == "whole" else Color("8a8278"))
		if zoomed and m.has("note") and (m.get("landmark", false) or RomeMap.footprint(m) >= 9.0):  # the big things; the small ones name themselves under the mouse
			_label(c, font, at + Vector2(sz / 2.0 + 2, 4), _short(str(m["name"])), fs - 4, INK)
	if not zoomed:
		for r: Dictionary in regions:
			var p := _px(f, Plan.to_map(Vector3(r["c"].x, 0, r["c"].y)))
			var name := str(r["name"]).split(", ")[-1]
			c.draw_string(font, p - Vector2(Lettering_width(font, name, fs - 3) / 2.0, 0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 3, Color(INK, 0.45))
	for r: Dictionary in city.get("roads", []):  # street names, along their longest stretch
		var pts: Array = r["points"]
		var best := -1
		var best_l := 0.0
		var inner := Rect2(Vector2(30, 20), c.size - Vector2(60, 40))
		for i in pts.size() - 1:  # the longest stretch whose middle is in view
			var pa := _pxa(f, pts[i])
			var pb := _pxa(f, pts[i + 1])
			var l := pa.distance_to(pb)
			if l > best_l and inner.has_point((pa + pb) / 2.0):
				best_l = l
				best = i
		if best < 0:
			continue
		var a := _pxa(f, pts[best])
		var b := _pxa(f, pts[best + 1])
		var ang := (b - a).angle()
		if ang > PI / 2.0 or ang < -PI / 2.0:
			ang += PI
		c.draw_set_transform((a + b) / 2.0, ang)
		var txt := str(r["name"]).trim_prefix("the ")
		c.draw_string(font, Vector2(-Lettering_width(font, txt, fs - 4) / 2.0, -3), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, Color("5a4a30"))
		c.draw_set_transform(Vector2.ZERO)
	for mk: Dictionary in marks:
		var p := _px(f, Plan.to_map(mk["pos"]))
		match str(mk["kind"]):
			"house":  # a gold house with a roof, a ring round it, its name beside it: seen at once
				_labels.append(Rect2(p + Vector2(12, -12), Vector2(90, 18)))
				c.draw_arc(p, 13.0, 0, TAU, 24, Color(GOLD, 0.55), 2.0)
				c.draw_rect(Rect2(p - Vector2(6, 1), Vector2(12, 9)), GOLD)
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(0, -9), p + Vector2(8, -1)]), GOLD)
				c.draw_rect(Rect2(p - Vector2(6, 1), Vector2(12, 9)), INK, false, 1.0)
				c.draw_polyline(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(0, -9), p + Vector2(8, -1)]), INK, 1.0)
				c.draw_rect(Rect2(p + Vector2(-2, 3), Vector2(4, 5)), INK)  # the door
				c.draw_string(font, p + Vector2(13, 5), "Your house", HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 1, INK)
				c.draw_string(font, p + Vector2(12, 4), "Your house", HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 1, GOLD)
			"regular":
				c.draw_circle(p, 3.0, Color("3a5a8a"))
				if zoomed:
					_label(c, font, p + Vector2(5, 4), str(mk["name"]), fs - 4, Color("3a5a8a"))
			"sent":
				c.draw_arc(p, 7.0, 0, TAU, 16, Color("8a2a6a"), 2.0)
				c.draw_string(font, p + Vector2(9, 4), str(mk["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 3, Color("8a2a6a"))
	if highlight != "":
		for l: Dictionary in landmarks:
			if str(l["name"]) == highlight:
				var p := _px(f, Plan.to_map(l["pos"]))
				c.draw_arc(p, 8.0, 0, TAU, 16, Color("8a2a6a"), 2.0)
				c.draw_string(font, p + Vector2(10, 4), _short(highlight), HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 3, Color("8a2a6a"))
	var me := _px(f, Plan.to_map(you))  # you: an arrow the way you face
	var fwd := Vector2(-sin(facing), -cos(facing))  # world -Z is north, up on the plan
	var ahead := Vector2(fwd.x, fwd.y)
	var side := Vector2(-ahead.y, ahead.x)
	c.draw_colored_polygon(PackedVector2Array([me + ahead * 9.0, me - ahead * 5.0 + side * 5.0, me - ahead * 5.0 - side * 5.0]), Color("c83a2a"))
	_label(c, font, me + Vector2(8, -6), "You", fs - 2, Color("c83a2a"))
	if live and home != Vector3.INF and home.distance_to(you) > 40.0:  # which way home lies, when it is off the live map
		var hp := _px(f, Plan.to_map(home))
		if not Rect2(Vector2.ZERO, c.size).has_point(hp):
			var dir := (hp - me).normalized()
			var tip := me + dir * 26.0
			c.draw_line(me + dir * 14.0, tip, GOLD, 2.0)
			c.draw_colored_polygon(PackedVector2Array([tip + dir * 5.0, tip - dir * 2.0 + Vector2(-dir.y, dir.x) * 4.0, tip - dir * 2.0 - Vector2(-dir.y, dir.x) * 4.0]), GOLD)
			_label(c, font, tip + dir * 8.0 + Vector2(-12, 4), "home", fs - 4, GOLD)
	var n := Vector2(c.size.x - 24, 26)  # north, and a scale of five hundred paces
	c.draw_line(n + Vector2(0, 12), n - Vector2(0, 12), INK, 2.0)
	c.draw_colored_polygon(PackedVector2Array([n - Vector2(0, 16), n - Vector2(5, 8), n + Vector2(5, -8)]), INK)
	c.draw_string(font, n + Vector2(-4, 28), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var bar := 500.0 * Plan.PACE * float(f["s"])
	var b0 := Vector2(c.size.x - 20 - bar, c.size.y - 14)
	c.draw_line(b0, b0 + Vector2(bar, 0), INK, 2.0)
	c.draw_string(font, b0 + Vector2(0, -4), "500 paces", HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, INK)


## The way home along the streets from about where you are (worked out again once you have walked
## a dozen paces from where it was last worked out).
func way_home() -> Array:
	if home != Vector3.INF and (_home_from == Vector3.INF or _home_from.distance_to(you) > 12.0):
		_home_from = you
		_home_way = Plan.way(you, home)
	return _home_way


## A label, unless it would lie over one already drawn.
func _label(c: Control, font: Font, at: Vector2, text: String, fs: int, col: Color) -> void:
	var w := Lettering_width(font, text, fs)
	if at.x + w > c.size.x - 4.0:
		at.x = maxf(4.0, at.x - w - 12.0)  # off the edge: to the left of its mark instead
	var r := Rect2(at - Vector2(0, fs), Vector2(w, fs + 2))
	for o: Rect2 in _labels:
		if o.intersects(r):
			return
	_labels.append(r)
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static func Lettering_width(font: Font, text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


static func _short(name: String) -> String:
	return name.trim_prefix("the ").trim_prefix("The ")


func _hover(at: Vector2) -> void:
	if view != "city":
		_under = _house_room_at(at)
		refresh()
		return
	var f := _frame()
	var best := ""
	var best_d := 14.0
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
	if best != _under:
		_under = best
		refresh()


# ---------- the house ----------

func _house_frame() -> Dictionary:
	var s := minf((_canvas.size.y - 40.0) / 24.0, 12.0)
	return {"s": s, "o": Vector2(20 + 8.0 * s, 16 + 12.0 * s)}


## A house position (x across, +z toward the street) on the plan: the street at the bottom.
func _hpx(f: Dictionary, x: float, z: float) -> Vector2:
	return f["o"] + Vector2(x, z) * float(f["s"])


func _paint_house(c: Control) -> void:
	var f := _house_frame()
	var font := c.get_theme_default_font()
	var fs := c.get_theme_default_font_size()
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
			c.draw_string(font, (a + b) / 2.0 - Vector2(Lettering_width(font, name, fs - 4) / 2.0, -4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, INK)
	for x: float in [-5.0, 5.0]:
		c.draw_string(font, _hpx(f, x - 1.6, 10.4), "shop", HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, INK)
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
	c.draw_string(font, Vector2(_hpx(f, -8, 12).x, street_y), "the street: the Argiletum, down to the Forum (south-west)", HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, FAINT)
	var tx := _hpx(f, 8.0, 0).x + 18.0  # what the house is like now, and the room under the mouse
	var note := str(House.data().get("house", {}).get(age, ""))
	if _under != "":
		note = _under
	c.draw_multiline_string(font, Vector2(tx, 24), note, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - tx - 12, fs - 2, 12, INK)
	var bricked_note := "Red: doorways bricked up." if House.BRICKED.any(func(bk: Array) -> bool: return bk[0] == age) else ""
	if age == "heroic":
		bricked_note = "Red: no shops yet, a blank wall to the street."
	if fallen:
		bricked_note = "Dashed: walls fallen. No roof."
	if bricked_note != "":
		c.draw_string(font, Vector2(tx, c.size.y - 10), bricked_note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, FAINT)


func _house_room_at(at: Vector2) -> String:
	var f := _house_frame()
	for id: String in House.ROOMS:
		var r: Array = House.ROOMS[id]
		if Rect2(_hpx(f, r[0], r[1]), Vector2(float(r[2]) - float(r[0]), float(r[3]) - float(r[1])) * float(f["s"])).has_point(at):
			var n := House.room_note(id, age)
			var name: String = House.NAMES.get(id, id)
			return "%s: %s" % [name.capitalize(), n] if n != "" else name.capitalize()
	return ""
