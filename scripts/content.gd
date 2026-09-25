extends RefCounted
## Loads works, ideas, enemies and bosses from the JSON files in content/.

const CONTENT_DIR := "res://content/greece"
const EFFECT_KINDS := ["attack", "block", "heal", "draw", "strength", "energy"]
const INTENT_KINDS := ["attack", "block"]
const MIN_IDEAS_PER_REGION := 4  # recall prompts need 3 wrong options

var works: Dictionary = {}   # work id -> work
var ideas: Dictionary = {}   # idea id -> idea (with "region" added)
var regions: Array = []      # region dictionaries, in index order


static func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s (error %d)" % [path, FileAccess.get_open_error()])
		return null
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null:
		push_error("Bad JSON in %s" % path)
	return data


func load_all(dir: String = CONTENT_DIR) -> bool:
	var w: Variant = read_json(dir + "/works.json")
	var index: Variant = read_json(dir + "/index.json")
	if w == null or index == null:
		return false
	for work in w["works"]:
		works[work["id"]] = work
	for file_name in index["regions"]:
		var r: Variant = read_json(dir + "/" + file_name)
		if r == null:
			return false
		regions.append(r)
		for idea in r["ideas"]:
			idea["region"] = r["id"]
			ideas[idea["id"]] = idea
	return true


func idea_ids(region_id: String = "") -> Array:
	var out: Array = []
	for id in ideas:
		if region_id == "" or ideas[id]["region"] == region_id:
			out.append(id)
	return out


## Returns a list of human-readable problems; empty means the content is good.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var names := {}
	for r in regions:
		var rid: String = r.get("id", "?")
		if r.get("ideas", []).size() < MIN_IDEAS_PER_REGION:
			errors.append("%s: needs at least %d ideas" % [rid, MIN_IDEAS_PER_REGION])
		if r.get("enemies", []).is_empty():
			errors.append("%s: has no enemies" % rid)
		if not r.has("boss"):
			errors.append("%s: has no boss" % rid)
		for foe in r.get("enemies", []) + ([r["boss"]] if r.has("boss") else []):
			errors.append_array(_validate_foe(rid, foe))
	for id in ideas:
		errors.append_array(_validate_idea(ideas[id]))
		var n: String = ideas[id].get("name", "")
		if names.has(n):
			errors.append("%s: duplicate name '%s'" % [id, n])
		names[n] = true
	return errors


func _validate_idea(idea: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var id: String = idea.get("id", "?")
	for key in ["name", "clue", "summary", "source", "work", "passage"]:
		if str(idea.get(key, "")).strip_edges() == "":
			errors.append("%s: missing %s" % [id, key])
	if not works.has(idea.get("work", "")):
		errors.append("%s: work '%s' is not in works.json" % [id, idea.get("work", "")])
	var cost: int = int(idea.get("cost", -1))
	if cost < 0 or cost > 3:
		errors.append("%s: cost must be 0-3" % id)
	var effects: Array = idea.get("effects", [])
	if effects.is_empty():
		errors.append("%s: has no effects" % id)
	for e in effects:
		if not e.get("kind", "") in EFFECT_KINDS:
			errors.append("%s: unknown effect '%s'" % [id, e.get("kind", "")])
		if int(e.get("value", 0)) <= 0:
			errors.append("%s: effect value must be positive" % id)
	# The clue is shown when the player must name the idea, so it cannot contain the name.
	var core_name: String = str(idea.get("name", "")).split(" (")[0].to_lower()
	if core_name != "" and str(idea.get("clue", "")).to_lower().contains(core_name):
		errors.append("%s: clue gives away the name" % id)
	return errors


func _validate_foe(rid: String, foe: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var fid: String = foe.get("id", "?")
	if int(foe.get("hp", 0)) <= 0:
		errors.append("%s/%s: hp must be positive" % [rid, fid])
	if foe.get("intents", []).is_empty():
		errors.append("%s/%s: has no intents" % [rid, fid])
	for i in foe.get("intents", []):
		if not i.get("kind", "") in INTENT_KINDS or int(i.get("value", 0)) <= 0:
			errors.append("%s/%s: bad intent %s" % [rid, fid, str(i)])
	return errors
