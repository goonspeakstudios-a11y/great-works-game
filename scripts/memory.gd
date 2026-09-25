extends RefCounted
## Spaced review with Leitner boxes. Box 0 = never answered, 5 = mastered.
## A right answer moves an idea up a box and pushes its next review further out;
## a wrong answer drops it to box 1 and makes it due again right away.

const INTERVALS := [0, 600, 86400, 259200, 604800, 1814400]  # seconds, indexed by box
const MAX_BOX := 5
const GOLD_BOX := 4

var records: Dictionary = {}  # idea id -> {box, due, right, wrong}


func _rec(id: String) -> Dictionary:
	return records.get(id, {"box": 0, "due": 0, "right": 0, "wrong": 0})


func box(id: String) -> int:
	return int(_rec(id)["box"])


func is_new(id: String) -> bool:
	return not records.has(id)


func is_due(id: String, now: int) -> bool:
	return int(_rec(id)["due"]) <= now


func is_gold(id: String) -> bool:
	return box(id) >= GOLD_BOX


func record(id: String, correct: bool, now: int) -> void:
	var r := _rec(id).duplicate()
	if correct:
		r["box"] = mini(int(r["box"]) + 1, MAX_BOX)
		r["due"] = now + INTERVALS[r["box"]]
		r["right"] = int(r["right"]) + 1
	else:
		r["box"] = 1
		r["due"] = now
		r["wrong"] = int(r["wrong"]) + 1
	records[id] = r


## Picks up to `count` ids, most in need of review first: due before not-due,
## then lower boxes, then the longest overdue. Ties break randomly.
func pick(ids: Array, count: int, now: int, rng: RandomNumberGenerator) -> Array:
	var keyed: Array = []
	for id in ids:
		var r := _rec(id)
		keyed.append([0 if int(r["due"]) <= now else 1, int(r["box"]), int(r["due"]), rng.randf(), id])
	keyed.sort_custom(func(a, b):
		for i in 4:
			if a[i] != b[i]:
				return a[i] < b[i]
		return false)
	var out: Array = []
	for k in keyed.slice(0, count):
		out.append(k[4])
	return out


func to_dict() -> Dictionary:
	return records.duplicate(true)


func from_dict(data: Dictionary) -> void:
	records = data.duplicate(true)
