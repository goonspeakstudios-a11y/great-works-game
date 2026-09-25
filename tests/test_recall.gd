extends "res://tests/test_base.gd"

const Recall := preload("res://scripts/recall.gd")


func _pool() -> Array:
	var out: Array = []
	for i in 6:
		out.append({"id": "i%d" % i, "name": "Name %d" % i, "clue": "Clue %d" % i,
			"source": "Source %d" % (i % 3)})
	return out


func test_each_kind_has_one_right_answer_among_four() -> void:
	var pool := _pool()
	for kind in Recall.KINDS:
		var p := Recall.build(pool[0], pool, seeded(), kind)
		check_eq(p["options"].size(), 4 if kind != "source_of_name" else 3, "%s option count" % kind)
		check(p["answer"] >= 0, "%s has the right answer in options" % kind)
		check_eq(p["options"].size(), _unique(p["options"]), "%s options are distinct" % kind)
		check(Recall.is_correct(p, p["answer"]), "%s answer checks correct" % kind)
		check(not Recall.is_correct(p, (p["answer"] + 1) % p["options"].size()), "%s wrong choice fails" % kind)


func test_name_from_clue_shows_clue_and_answer_is_name() -> void:
	var pool := _pool()
	var p := Recall.build(pool[2], pool, seeded(), "name_from_clue")
	check_eq(p["question"], "Clue 2", "question is the clue")
	check_eq(p["options"][p["answer"]], "Name 2", "answer is the name")


func test_source_falls_back_when_all_sources_match() -> void:
	var pool: Array = []
	for i in 4:
		pool.append({"id": "i%d" % i, "name": "N%d" % i, "clue": "C%d" % i, "source": "Same"})
	var p := Recall.build(pool[0], pool, seeded(), "source_of_name")
	check_eq(p["kind"], "name_from_clue", "falls back to naming")


func _unique(a: Array) -> int:
	var d := {}
	for x in a:
		d[x] = true
	return d.size()
