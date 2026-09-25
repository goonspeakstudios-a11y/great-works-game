extends RefCounted
## Builds multiple-choice recall prompts for an idea.
## A prompt is {kind, question, options: Array[String], answer: int}.

const KINDS := ["name_from_clue", "clue_from_name", "source_of_name"]
const OPTION_COUNT := 4


static func build(idea: Dictionary, pool: Array, rng: RandomNumberGenerator, kind: String = "") -> Dictionary:
	if kind == "":
		kind = KINDS[rng.randi_range(0, KINDS.size() - 1)]
	var others: Array = pool.filter(func(o): return o["id"] != idea["id"])
	match kind:
		"clue_from_name":
			return _make(kind, "Which of these is \"%s\"?" % idea["name"],
				idea["clue"], _field(others, "clue"), rng)
		"source_of_name":
			var sources: Array = _field(others, "source").filter(func(s): return s != idea["source"])
			if sources.is_empty():
				return build(idea, pool, rng, "name_from_clue")
			return _make(kind, "Where does \"%s\" come from?" % idea["name"],
				idea["source"], sources, rng)
		_:
			return _make("name_from_clue", idea["clue"], idea["name"], _field(others, "name"), rng)


static func _field(ideas: Array, key: String) -> Array:
	var seen := {}
	for i in ideas:
		seen[i[key]] = true
	return seen.keys()


static func _make(kind: String, question: String, right: String, wrong: Array, rng: RandomNumberGenerator) -> Dictionary:
	var choices: Array = wrong.duplicate()
	_shuffle(choices, rng)
	choices = choices.slice(0, OPTION_COUNT - 1)
	choices.append(right)
	_shuffle(choices, rng)
	return {"kind": kind, "question": question, "options": choices, "answer": choices.find(right)}


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


static func is_correct(prompt: Dictionary, choice: int) -> bool:
	return choice == int(prompt["answer"])
