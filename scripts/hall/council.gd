extends Panel
## The council table of the city in speech (city.gd): where you govern, a season at a time. The
## city's measures along the top with what it needs next; its people on the left (what they are
## made of, once tried; their traits; the work you give them); the laws in the middle; the season's
## trouble on the right, with what Socrates says to each thing you do; and at the bottom, the end of
## the season (and, once the city is just, the passing of the generations). Esc closes it.

signal acted  # the city changed (the Hall saves it, and counts what it has learned)

const Lettering := preload("res://scripts/hall/lettering.gd")
const METAL_COLOURS := {"gold": Color("e0b660"), "silver": Color("c8ccd4"), "bronze": Color("c07838"), "iron": Color("8a8a90")}
const ROLE_NAMES := {"": "no work", "auxiliary": "soldier", "ruler": "ruler"}

var city: RefCounted
var _title: Label
var _goal: Label
var _meters: RichTextLabel
var _people: VBoxContainer
var _laws: VBoxContainer
var _trouble: RichTextLabel
var _choices: VBoxContainer
var _socrates: RichTextLabel
var _end: Button
var _generations: Button
var _trials: Label


func _init() -> void:
	hide()
	position = Vector2(8, 8)
	size = Vector2(624, 344)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.045, 0.96)
	style.border_color = Color("5a4a2a")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel", style)
	_title = _label(Vector2(10, 6), Vector2(600, 18))
	Lettering.capitals(_title)
	_goal = _label(Vector2(10, 24), Vector2(604, 30))
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.modulate = Color("a6c8cc")
	_meters = _rich(Vector2(10, 54), Vector2(604, 18))
	_meters.scroll_active = false
	_people = _column(Vector2(8, 76), Vector2(300, 228), "THE PEOPLE")
	_laws = _column(Vector2(312, 76), Vector2(146, 228), "THE LAWS")
	var right := _label(Vector2(466, 76), Vector2(150, 16))
	right.text = "THIS SEASON"
	Lettering.capitals(right)
	_trouble = _rich(Vector2(466, 94), Vector2(150, 86))
	_choices = VBoxContainer.new()
	_choices.position = Vector2(466, 182)
	_choices.size = Vector2(150, 46)
	add_child(_choices)
	_socrates = _rich(Vector2(466, 230), Vector2(150, 76))
	_end = _button("End the season", Vector2(10, 310), Vector2(150, 24), _on_end)
	_generations = _button("Let the generations pass", Vector2(166, 310), Vector2(180, 24), _on_generations)
	_trials = _label(Vector2(354, 314), Vector2(150, 18))
	var esc := _label(Vector2(520, 314), Vector2(96, 18))
	esc.text = "Esc to rise"
	esc.modulate = Color("8a8074")


func _label(at: Vector2, sz: Vector2) -> Label:
	var l := Label.new()
	l.position = at
	l.size = sz
	l.clip_text = true
	add_child(l)
	return l


func _rich(at: Vector2, sz: Vector2) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.position = at
	r.size = sz
	r.add_theme_color_override("default_color", Color("e8dcc0"))
	add_child(r)
	return r


func _button(text: String, at: Vector2, sz: Vector2, then: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = sz
	b.pressed.connect(then)
	add_child(b)
	return b


func _column(at: Vector2, sz: Vector2, heading: String) -> VBoxContainer:
	var h := _label(at, Vector2(sz.x, 16))
	h.text = heading
	Lettering.capitals(h)
	var scroll := ScrollContainer.new()
	scroll.position = at + Vector2(0, 18)
	scroll.size = sz - Vector2(0, 18)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(sz.x - 12, 0)
	box.add_theme_constant_override("separation", 2)
	scroll.add_child(box)
	return box


## Sit down at the table with this city.
func open(c: RefCounted) -> void:
	city = c
	_say(city.log.back() if not city.log.is_empty() else "")
	refresh()
	show()


## What Socrates says (or what happened), under the season's trouble.
func _say(text: String) -> void:
	_socrates.text = "[color=#e0b660]Socrates:[/color] " + text if text != "" else ""


func refresh() -> void:
	_title.text = "Season %d  -  %s" % [city.season, city.stage_name()]
	_goal.text = city.stage_goal()
	var m: Dictionary = city.meters
	var need: int = city.land_needed()
	_meters.text = "Food %d ([color=%s]%+d[/color])   Land %d of %d needed   Luxury %d   Rich and poor %d   Unity %d   Justice %d   Army %d" % [
		m["food"], "#9ab98a" if city.food_made() >= city.food_eaten() else "#d08a4a", city.food_made() - city.food_eaten(),
		m["land"], need, m["luxury"], m["gap"], m["unity"], city.justice(), city.defence()]
	for c in _people.get_children():
		c.queue_free()
	for p in city.people:
		_people.add_child(_person_row(p))
	for c in _laws.get_children():
		c.queue_free()
	for l in city.data()["laws"]:
		var b := Button.new()
		var passed: bool = city.laws.has(l["id"])
		var why: String = city.cannot_pass(l["id"])
		b.text = ("In force: " if passed else "") + str(l["name"])
		b.disabled = passed or why != ""
		b.tooltip_text = str(l["socrates"]) if passed or why == "" else why
		b.clip_text = true
		b.custom_minimum_size = Vector2(134, 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_law.bind(l["id"]))
		_laws.add_child(b)
	for c in _choices.get_children():
		c.queue_free()
	if city.event.is_empty():
		_trouble.text = "[color=#8a8074]A quiet season.[/color]" if city.stage <= city.JUST_CITY else "[color=#8a8074]The laws no longer hold.[/color]"
	else:
		_trouble.text = "[color=#e0b660]%s[/color]\n%s" % [city.event["title"], city.event["text"]]
		for k in city.event["choices"].size():
			var b := Button.new()
			b.text = city.event["choices"][k]["text"]
			b.clip_text = true
			b.custom_minimum_size = Vector2(146, 20)
			b.pressed.connect(_on_answer.bind(k))
			_choices.add_child(b)
	_end.disabled = city.cannot_end() != "" or city.stage > city.JUST_CITY
	_end.tooltip_text = city.cannot_end()
	_generations.visible = city.stage >= city.JUST_CITY and city.stage < city.LAST_STAGE
	_trials.text = "Trials left: %d" % city.trials_left


## One of the city's people: name and age, what they are made of (once tried), their traits, the
## work you give them, and a trial.
func _person_row(p: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var name := Label.new()
	name.text = "%s, %s" % [p["name"], "child" if int(p["age"]) < city.COMES_OF_AGE else ("woman" if p["sex"] == "f" else "man")]
	name.custom_minimum_size = Vector2(96, 18)
	name.clip_text = true
	name.tooltip_text = ", ".join(p["traits"])
	row.add_child(name)
	var metal := Label.new()
	metal.text = str(p["metal"]) if p["known"] else "? " + str(p["traits"][0])
	metal.modulate = METAL_COLOURS.get(p["metal"], Color.WHITE) if p["known"] else Color("8a8074")
	metal.custom_minimum_size = Vector2(80, 18)
	metal.clip_text = true
	metal.tooltip_text = ", ".join(p["traits"])
	row.add_child(metal)
	if int(p["age"]) >= city.COMES_OF_AGE:
		var work := OptionButton.new()
		var roles: Array = [""] + city.roles_open()
		if not roles.has(p["role"]):
			roles.append(p["role"])
		for r in roles:
			work.add_item(ROLE_NAMES.get(r, r))
			work.set_item_metadata(work.item_count - 1, r)
		work.selected = roles.find(p["role"])
		work.custom_minimum_size = Vector2(76, 18)
		work.clip_text = true
		work.item_selected.connect(func(i: int) -> void: _on_role(int(p["id"]), str(work.get_item_metadata(i))))
		row.add_child(work)
	if not p["known"]:
		var try := Button.new()
		try.text = "Try"
		try.disabled = city.trials_left <= 0
		try.pressed.connect(_on_try.bind(int(p["id"])))
		row.add_child(try)
	return row


func _on_try(id: int) -> void:
	_say(city.trial(id))
	_after()


func _on_role(id: int, role: String) -> void:
	var why: String = city.assign(id, role)
	var p: Dictionary = city.person(id)
	if why != "":
		_say(why)
	elif p["known"] and not city.fits(p) and role != "":
		_say("Is %s made for that work? A soul set to the wrong work does it badly, and the city suffers (434a-b)." % p["name"])
	else:
		_say("%s: %s." % [p["name"], ROLE_NAMES.get(role, role)])
	_after()


func _on_law(id: String) -> void:
	var said: Dictionary = city.pass_law(id)
	if said.has("error"):
		_say(said["error"])
	else:
		var text: String = said["socrates"]
		if said.get("objection", "") != "":
			text = "[i]%s[/i]\n%s" % [said["objection"], text]
		_say(text)
	_after()


func _on_answer(k: int) -> void:
	_say(city.answer(k))
	_after()


func _on_end() -> void:
	var happened: Array = city.end_season()
	_say(" ".join(happened) if not happened.is_empty() else "The season passes quietly.")
	_after()


func _on_generations() -> void:
	_say(city.let_generations_pass() + " Everything that has come into being must decay (546a).")
	_after()


func _after() -> void:
	acted.emit()
	refresh()
