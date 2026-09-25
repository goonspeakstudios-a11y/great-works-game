extends RefCounted
## Plays one story scene beat by beat. Pure logic: the world shows each beat.
## Beats: {say, line} dialogue, {move, to} an actor walks, {learn} an idea is taught.

var scene: Dictionary
var index := -1
var learned: Array[String] = []


func start(scene_data: Dictionary) -> void:
	scene = scene_data
	index = -1
	learned.clear()


## Moves to the next beat and returns it, or {} when the scene is over.
func next() -> Dictionary:
	index += 1
	if index >= scene["beats"].size():
		return {}
	var beat: Dictionary = scene["beats"][index]
	if beat.has("learn"):
		learned.append(beat["learn"])
	return beat


func is_done() -> bool:
	return index >= scene["beats"].size()


static func beat_kind(beat: Dictionary) -> String:
	for k in ["say", "move", "learn"]:
		if beat.has(k):
			return k
	return ""


## Index of the first chapter step not yet completed; steps.size() when finished.
static func current_step(chapter: Dictionary, done: Array) -> int:
	for i in chapter["steps"].size():
		if not chapter["steps"][i]["id"] in done:
			return i
	return chapter["steps"].size()


## Ideas taught by the chapter's scenes before step `upto`.
static func ideas_taught(chapter: Dictionary, upto: int) -> Array:
	var out: Array = []
	for i in mini(upto, chapter["steps"].size()):
		var step: Dictionary = chapter["steps"][i]
		for beat in step.get("beats", []):
			if beat.has("learn"):
				out.append(beat["learn"])
	return out
