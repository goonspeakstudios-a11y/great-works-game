extends "res://scripts/pixel/guided.gd"
## Stage 5: Euclid's Elements, Book I.
## Alexandria, about 300 BC. A builder needs perfect corners for a temple. Euclid starts
## from a few rules no one can doubt and builds with rope and pegs: the equal-sided
## triangle of Proposition 1 (you swing the two circles yourself), then Proposition 47:
## the squares on the two short sides of a square-cornered triangle fill the square on
## the long side exactly (3, 4, 5). Ends with "no royal road to geometry".

const WORK_ID := "euclid-elements"
const A := Vector2(140, 102)
const B := Vector2(180, 102)
const U := 8.0  # one rope knot on the squares diagram
const SQ3 := Vector2(64, 70)  # top-left corners of the three squares
const SQ4 := Vector2(104, 62)
const SQ5 := Vector2(176, 54)
const TRI := Vector2(240, 90)  # the right angle of the 3-4-5 triangle

var circle_a := 0.0
var circle_b := 0.0
var triangle := false
var squares := false
var fill := 0.0


func setup() -> void:
	card_title = "Stage 5 complete"
	card_sub = "Euclid, Elements, Book I (about 300 BC)"
	place_note = "Alexandria, about 300 BC"
	bg = Art.site()
	cast = {
		"master": Art.actor("Master builder", "bald", "short", Art.pal("c49a78", "7a6a4a", "54482e", "54482e", "3a2a1e"), Vector2(40, 140)),
		"you": Art.actor("You", "short", "none", Art.pal("2a1e14", "9a8a6a", "6e6250", "6e6250"), Vector2(96, 140)),
		"euclid": Art.actor("Euclid", "short", "long", Art.pal("a8a49c", "3a5a6a", "284050", "c8b890"), Vector2(280, 140)),
		"messenger": Art.actor("Messenger", "short", "none", Art.pal("1e1a18", "6a3a2a", "4a281c", "c09040"), Vector2(300, 142)),
	}
	hero = "you"
	show_actor("euclid", false)
	show_actor("messenger", false)


func can_stand(p: Vector2) -> bool:
	return Rect2(60, 60, 200, 84).has_point(p)


func story() -> void:
	await say("master", "The temple's corners must be perfect. If they're off, the whole thing leans.")
	await say("you", "But how can anyone be sure a corner is perfect?")
	show_actor("euclid")
	await say("euclid", "By starting with things no one can doubt. Then taking one sure step at a time.")
	await say("master", "Master Euclid! Please, show the boy.")
	await say("euclid", "A few rules first. Between any two points, you can draw a straight line.")
	await say("euclid", "Around any point, you can draw a circle.")
	await say("euclid", "And things equal to the same thing are equal to each other.")
	await say("euclid", "That's enough to start. Make me a triangle with three equal sides.")
	await say("euclid", "Take the rope. Walk to peg A, and swing it around through B.")
	await walk_to(A + Vector2(0, 16), 9.0)
	await _grow(func(v: float): circle_a = v)
	await say("euclid", "Now walk to peg B, and swing it around through A.")
	await walk_to(B + Vector2(0, 16), 9.0)
	await _grow(func(v: float): circle_b = v)
	await say("euclid", "Where the two circles cross, put a peg. Call it C.")
	await walk_to(_c() + Vector2(0, 16), 9.0)
	triangle = true
	await say("euclid", "There. Now, why is it perfect?")
	await say("euclid", "A to C is the same rope as A to B. So is B to C.")
	await say("euclid", "Both equal A to B. Things equal to the same thing are equal to each other.")
	await say("euclid", "So all three sides are equal. Not a guess. A proof. It will be true forever.")
	cast["you"]["at"] = Vector2(96, 140)
	await say("master", "But the square corners, Master Euclid!")
	await say("euclid", "For those, take a rope with twelve equal knots. Make sides of three, four and five.")
	circle_a = 0.0
	circle_b = 0.0
	triangle = false
	squares = true
	await say("euclid", "Now picture a square on each side. Nine, sixteen, and twenty-five.")
	await say("euclid", "Watch the two small squares.")
	await _grow(func(v: float): fill = v, 2.5)
	await say("euclid", "They fill the big square exactly. Every square-cornered triangle does this.")
	await say("you", "So if my rope makes three, four, five, the corner is square!")
	await say("euclid", "Exactly. Every step is sure, because the step before it was sure.")
	await say("euclid", "Further on is a proof so many students failed, they call it the bridge of fools.")
	show_actor("messenger")
	await say("messenger", "Master Euclid! The king wants to learn geometry. Quickly, and the easy way.")
	await say("euclid", "Tell the king there is no royal road to geometry.")
	await say("", "Or so the story goes. The great Library is gone. His proofs are still taught.")


func _grow(setter: Callable, seconds: float = 1.2) -> void:
	if auto:
		setter.call(1.0)
		return
	var tw := create_tween()
	tw.tween_method(setter, 0.0, 1.0, seconds)
	await tw.finished


func _c() -> Vector2:
	return (A + B) / 2.0 + Vector2(0, -A.distance_to(B) * sqrt(3.0) / 2.0)


func draw_scene(ci: CanvasItem) -> void:
	var rope: Color = Pix.P["rope"]
	var r := A.distance_to(B)
	if not squares:
		if circle_a > 0.0:
			ci.draw_arc(A, r, 0.0, TAU * circle_a, 64, rope, 1.0)
		if circle_b > 0.0:
			ci.draw_arc(B, r, PI, PI + TAU * circle_b, 64, rope, 1.0)
		ci.draw_line(A, B, rope, 1.0)
		if triangle:
			ci.draw_line(A, _c(), Pix.P["gold"], 1.0)
			ci.draw_line(B, _c(), Pix.P["gold"], 1.0)
			ci.draw_line(A, B, Pix.P["gold"], 1.0)
		for p in ([A, B, _c()] if triangle else [A, B]):
			ci.draw_rect(Rect2(p.x - 1, p.y - 3, 2, 4), Color("5a4028"))
		Pix.text(ci, A + Vector2(-8, 3), "A", 6, Pix.P["ink"], true, false)
		Pix.text(ci, B + Vector2(8, 3), "B", 6, Pix.P["ink"], true, false)
		if triangle:
			Pix.text(ci, _c() + Vector2(0, -4), "C", 6, Pix.P["ink"], true, false)
		return
	_draw_grid(ci, SQ3, 3, true)
	_draw_grid(ci, SQ4, 4, true)
	_draw_grid(ci, SQ5, 5, false)
	Pix.text(ci, Vector2(100, 84), "+", 8, Pix.P["ink"], true, false)
	Pix.text(ci, Vector2(158, 84), "=", 8, Pix.P["ink"], true, false)
	for n in [[SQ3, "9"], [SQ4, "16"], [SQ5, "25"]]:
		var size: float = {"9": 3, "16": 4, "25": 5}[n[1]] * U
		Pix.text(ci, n[0] + Vector2(size / 2.0, size + 9), n[1], 6, Pix.P["ink"], true, false)
	var t3 := TRI + Vector2(0, -3 * U)
	var t4 := TRI + Vector2(4 * U, 0)
	for seg in [[TRI, t3], [TRI, t4], [t3, t4]]:
		ci.draw_line(seg[0], seg[1], rope, 1.0)
	ci.draw_rect(Rect2(TRI.x, TRI.y - 4, 4, 4), Color(Pix.P["rope"], 0.6), false)
	Pix.text(ci, TRI + Vector2(-5, -12), "3", 6, Pix.P["ink"], true, false)
	Pix.text(ci, TRI + Vector2(16, 8), "4", 6, Pix.P["ink"], true, false)
	Pix.text(ci, TRI + Vector2(19, -14), "5", 6, Pix.P["ink"], true, false)
	# tiles fly from the two small squares into the big one, one after another
	var sources: Array = []
	for i in 9:
		sources.append(SQ3 + Vector2(i % 3, i / 3) * U)
	for i in 16:
		sources.append(SQ4 + Vector2(i % 4, i / 4) * U)
	for i in 25:
		var start: Vector2 = sources[i]
		var goal := SQ5 + Vector2(i % 5, i / 5) * U
		var k := clampf(fill * 1.6 - i * 0.024, 0.0, 1.0)
		var col := Color("c86a3a") if i < 9 else Color("4a7a9a")
		ci.draw_rect(Rect2(start.lerp(goal, k) + Vector2(1, 1), Vector2(U - 2, U - 2)), col)


func _draw_grid(ci: CanvasItem, top_left: Vector2, n: int, _solid: bool) -> void:
	for i in n + 1:
		ci.draw_line(top_left + Vector2(i * U, 0), top_left + Vector2(i * U, n * U), Color("8a6a40"), 1.0)
		ci.draw_line(top_left + Vector2(0, i * U), top_left + Vector2(n * U, i * U), Color("8a6a40"), 1.0)
