extends RefCounted
## Errands across the city (docs/rome-activities-plan.md, 3.3): a message or a parcel to take to a
## place, with directions given the Roman way, by what stands near it ("the Temple of Castor, past
## the Temple of Vesta, toward the Regia"), never a mark on a map. In the emptied city the landmarks
## are ruins, and the directions say what used to be there. Paid on arrival, less if you are slow.

const Plan := preload("res://scripts/hall/urbs_plan.gd")
const MIN_AWAY := 50.0  # an errand goes somewhere at least this far off
const MAX_AWAY := 320.0
const WALK := 2.4  # metres a second, for the time allowed
const SPARE := 60.0  # seconds more than the walk


## A landmark to take something to, not too near and not too far from `from`.
static func pick(landmarks: Array, from: Vector3, rng: RandomNumberGenerator) -> Dictionary:
	var big: Array = landmarks.filter(func(l: Dictionary) -> bool: return not l.get("minor", false))  # not to a street's fountain or shrine
	var ok: Array = big.filter(func(l: Dictionary) -> bool:
		var d := Vector2(l["pos"].x - from.x, l["pos"].z - from.z).length()
		return d >= MIN_AWAY and d <= MAX_AWAY)
	if ok.is_empty():
		ok = big
	return ok[rng.randi() % ok.size()] if not ok.is_empty() else {}


## The directions to `to`: by the two landmarks nearest it.
static func describe(to: Dictionary, landmarks: Array, age: String) -> String:
	var at: Vector3 = to["pos"]
	var others: Array = landmarks.filter(func(l: Dictionary) -> bool: return l["name"] != to["name"])
	others.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return at.distance_to(a["pos"]) < at.distance_to(b["pos"]))
	var gone := age == "fall"
	var name := str(to["name"])
	var place := ("what's left of %s" % name) if gone else name
	if others.size() < 2:
		return "%s." % place
	var a := str(others[0]["name"])
	var b := str(others[1]["name"])
	if gone:
		return "%s, past where %s was, toward the ruins of %s." % [place, a, b]
	return "%s, past %s, toward %s." % [place, a, b]


## A new errand: {name, pos, what, text, pay (as in 280 BC), limit (seconds), fides}. The text is
## what you are told: where it goes, as people say it, and the way there by the streets (urbs_plan.gd).
static func make(to: Dictionary, landmarks: Array, from: Vector3, age: String, pay: int, what: String) -> Dictionary:
	var d := Vector2(to["pos"].x - from.x, to["pos"].z - from.z).length()
	return {"name": str(to["name"]), "pos": to["pos"], "pay": pay, "limit": d / WALK + SPARE, "fides": 1, "what": what,
		"text": "Take %s to %s %s" % [what, describe(to, landmarks, age), Plan.directions(from, to["pos"], str(to["name"]), landmarks, age)]}


## Arrived? Returns what it pays ({earn, fides}) and a line, or {} if not there yet.
static func arrive(errand: Dictionary, at: Vector3, took: float) -> Dictionary:
	var p: Vector3 = errand["pos"]
	if Vector2(at.x - p.x, at.z - p.z).length() > 12.0:
		return {}
	var late := took > float(errand["limit"])
	var pay := int(errand["pay"])
	return {"fx": {"earn": maxi(1, pay / 2) if late else pay, "fides": 0 if late else int(errand["fides"])},
		"line": "You deliver it at %s. %s" % [errand["name"], "Late. They pay you, grudgingly." if late else "In good time. They pay you."]}
