extends RefCounted
## Rules of stage 1 (Porphyry's Isagoge), with no drawing.
## The tree: each fork splits a genus by one difference. A thing may pass the "with"
## gate only if it has that difference, and the "without" door only if it lacks it.
## The statue: accidents come off and stay off, the property always comes back, and
## taking away the difference changes the species.

const FORKS := [
	{"genus": "substance", "difference": "body", "without": "spirit"},
	{"genus": "body", "difference": "life", "without": "stone"},
	{"genus": "living", "difference": "senses", "without": "plant"},
	{"genus": "animal", "difference": "reason", "without": "beast"},
]
const LAST_LEAF := "human"
const THINGS := {
	"wisp": {"body": false},
	"stone": {"body": true, "life": false},
	"oak": {"body": true, "life": true, "senses": false},
	"horse": {"body": true, "life": true, "senses": true, "reason": false},
	"masked": {"body": true, "life": true, "senses": true, "reason": true},  # a man in a horse mask
}
const MARKS := {"cloak": "accident", "wreath": "accident", "mask": "accident",
	"laugh": "property", "flame": "difference"}

var placed := {}  # thing -> leaf
var removed := {}  # mark -> true


static func home_of(thing: String) -> String:
	for fork in FORKS:
		if not THINGS[thing].get(fork["difference"], false):
			return fork["without"]
	return LAST_LEAF


## Whether the thing reaches fork i at all, and if so whether it may go this way.
static func may_pass(thing: String, fork: int, with_difference: bool) -> bool:
	var traits: Dictionary = THINGS[thing]
	for i in fork:
		if not traits.get(FORKS[i]["difference"], false):
			return false  # it left the tree at an earlier fork
	return traits.get(FORKS[fork]["difference"], false) == with_difference


func place(thing: String, leaf: String) -> bool:
	if placed.has(thing) or home_of(thing) != leaf:
		return false
	placed[thing] = leaf
	return true


func tree_done() -> bool:
	return placed.size() == THINGS.size()


## Pulls a mark off the statue and returns its kind. The property does not stay off.
func pull(mark: String) -> String:
	var kind: String = MARKS[mark]
	if kind != "property":
		removed[mark] = true
	return kind


func restore(mark: String) -> void:
	removed.erase(mark)


func marks_on() -> Array:
	return MARKS.keys().filter(func(m): return not removed.has(m))


func statue_kind() -> String:
	return "beast" if removed.has("flame") else "human"


func statue_done() -> bool:
	for m in MARKS:
		if MARKS[m] == "accident" and not removed.has(m):
			return false
	return statue_kind() == "human"
