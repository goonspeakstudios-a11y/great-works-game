extends Control
## Prototype screens, built in code: title, new ideas, fights with recall
## prompts, rewards, rest, results, and the Library. Placeholder look on purpose.

const Content := preload("res://scripts/content.gd")
const Memory := preload("res://scripts/memory.gd")
const Recall := preload("res://scripts/recall.gd")
const Combat := preload("res://scripts/combat.gd")
const Run := preload("res://scripts/run.gd")
const Save := preload("res://scripts/save.gd")

const RECALL_SECONDS := 12.0
const WEAK_POWER := 0.5
const GOLD_POWER := 1.5
const BG := Color(0.07, 0.08, 0.12)
const GOLD := Color(0.95, 0.78, 0.3)
const DIM := Color(0.65, 0.68, 0.75)

var content := Content.new()
var memory := Memory.new()
var save_data := Save.blank()
var save_path := Save.DEFAULT_PATH  # tests point this elsewhere
var rng := RandomNumberGenerator.new()
var run: Run
var combat: Combat
var fight_log: Array[String] = []
var run_right := 0
var run_wrong := 0

var screen: VBoxContainer
var overlay: Control
var prompt: Dictionary = {}
var prompt_card := -1
var prompt_idea := ""
var time_left := 0.0
var timer_bar: ProgressBar


func _ready() -> void:
	rng.randomize()
	var t := Theme.new()
	t.default_font_size = 20
	theme = t
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	screen = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 14)
	margin.add_child(screen)

	if not content.load_all():
		_label("Could not load the game content. Check the content folder.", 24)
		return
	var problems := content.validate()
	if not problems.is_empty():
		push_error("Content problems:\n" + "\n".join(problems))
	save_data = Save.load_save(save_path)
	memory.from_dict(save_data["memory"])
	show_title()


func _process(delta: float) -> void:
	if prompt.is_empty() or prompt_card < 0:
		return
	time_left -= delta
	if timer_bar:
		timer_bar.value = time_left
	if time_left <= 0.0:
		_answer(-1)


# ---------- helpers ----------

func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _clear() -> void:
	for c in screen.get_children():
		c.queue_free()


func _label(text: String, size: int = 20, color: Color = Color.WHITE, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	(parent if parent else screen).add_child(l)
	return l


func _button(text: String, action: Callable, parent: Node = null) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 48)
	b.pressed.connect(action)
	(parent if parent else screen).add_child(b)
	return b


func _row(parent: Node = null) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	(parent if parent else screen).add_child(h)
	return h


func _persist() -> void:
	save_data["memory"] = memory.to_dict()
	Save.write_save(save_data, save_path)


func _effects_text(idea: Dictionary, power: float = 1.0) -> String:
	var parts: Array[String] = []
	for e in idea["effects"]:
		parts.append("%s %d" % [str(e["kind"]).capitalize(), Combat.amount(e, power)])
	return ", ".join(parts)


func _memory_text(id: String) -> String:
	if memory.is_new(id):
		return "new"
	var b := memory.box(id)
	return "memory %s%s" % ["#".repeat(b), ".".repeat(Memory.MAX_BOX - b)]


# ---------- title and library ----------

func show_title() -> void:
	_clear()
	_label("GREAT WORKS", 48, GOLD)
	_label("A journey through the great books, where remembering is power.", 22, DIM)
	var stats: Dictionary = save_data["stats"]
	var known := 0
	for id in content.ideas:
		if not memory.is_new(id):
			known += 1
	_label("Runs: %d   Wins: %d   Ideas met: %d of %d" % [int(stats["runs"]), int(stats["wins"]), known, content.ideas.size()], 18, DIM)
	_button("Begin the journey", start_run)
	_button("The Library", func(): show_library(show_title))
	_button("Quit", func(): get_tree().quit())


func show_library(back: Callable) -> void:
	_clear()
	_label("THE LIBRARY", 36, GOLD)
	_button("Back", back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for id in content.idea_ids():
		var idea: Dictionary = content.ideas[id]
		var gold := memory.is_gold(id)
		_label("%s   [%s]" % [idea["name"], _memory_text(id)], 22, GOLD if gold else Color.WHITE, list)
		_label(idea["source"], 16, DIM, list)
		if memory.is_new(id):
			_label("You have not met this idea yet.", 18, DIM, list)
		else:
			_label(idea["summary"], 18, Color.WHITE, list)
			var work: Dictionary = content.works.get(idea["work"], {})
			_label("Read the real thing: %s. %s" % [idea["passage"], work.get("edition", "")], 16, DIM, list)
		list.add_child(HSeparator.new())


# ---------- run flow ----------

func start_run() -> void:
	run = Run.new()
	run_right = 0
	run_wrong = 0
	var region: Dictionary = content.regions[0]
	var deck := memory.pick(content.idea_ids(region["id"]), Run.START_DECK, _now(), rng)
	run.start(region, deck)
	var fresh := deck.filter(func(id): return memory.is_new(id))
	_clear()
	_label(region["title"].to_upper(), 36, GOLD)
	_label(region["intro"], 20)
	_button("Set out", func(): show_new_ideas(fresh, next_step))


func show_new_ideas(ids: Array, then: Callable) -> void:
	if ids.is_empty():
		then.call()
		return
	_clear()
	_label("NEW IDEAS", 32, GOLD)
	_label("Read these now. You will be asked to recall them to play them at full power.", 18, DIM)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in ids:
		var idea: Dictionary = content.ideas[id]
		_label("%s  (%s)" % [idea["name"], idea["source"]], 22, GOLD, list)
		_label(idea["summary"], 18, Color.WHITE, list)
		_label("Card: cost %d. %s" % [int(idea["cost"]), _effects_text(idea)], 16, DIM, list)
		list.add_child(HSeparator.new())
	_button("I have read them", then)


func next_step() -> void:
	if run.is_finished():
		show_result(true)
		return
	var step := run.current()
	match step["type"]:
		"fight", "boss":
			start_fight(step["enemy"])
		"reward":
			show_reward()
		"rest":
			show_rest()


func _finish_step() -> void:
	run.advance()
	next_step()


func show_reward() -> void:
	var options := run.reward_options(content.idea_ids(run.region["id"]), memory, _now(), rng)
	_clear()
	_label("CHOOSE AN IDEA TO ADD", 30, GOLD)
	if options.is_empty():
		run.heal(Run.NO_REWARD_HEAL)
		_label("Your deck holds every idea in this region. You rest a moment (+%d HP)." % Run.NO_REWARD_HEAL, 20)
		_button("Continue", _finish_step)
		return
	var row := _row()
	for id in options:
		var idea: Dictionary = content.ideas[id]
		var b := _button("%s\nCost %d: %s\n(%s)" % [idea["name"], int(idea["cost"]), _effects_text(idea), _memory_text(id)],
			func():
				run.add_card(id)
				show_new_ideas([id] if memory.is_new(id) else [], _finish_step), row)
		b.custom_minimum_size = Vector2(300, 140)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button("Skip", _finish_step)


func show_rest() -> void:
	_clear()
	_label("A QUIET SHORE", 30, GOLD)
	_label("HP %d / %d" % [run.hp, run.max_hp], 20)
	_button("Rest (+%d HP)" % Run.REST_HEAL, func():
		run.heal(Run.REST_HEAL)
		_finish_step())
	_button("Visit the Library first", func(): show_library(show_rest))


func show_result(won: bool) -> void:
	var stats: Dictionary = save_data["stats"]
	stats["runs"] = int(stats["runs"]) + 1
	if won:
		stats["wins"] = int(stats["wins"]) + 1
	_persist()
	_clear()
	_label("VICTORY" if won else "DEFEAT", 44, GOLD if won else Color(0.9, 0.4, 0.4))
	_label("Recalled right: %d   Missed: %d" % [run_right, run_wrong], 22)
	_label("Missed ideas come back sooner. Mastered ones turn gold and hit harder.", 18, DIM)
	_button("Back to the title", show_title)
	_button("The Library", func(): show_library(show_title))


# ---------- combat ----------

func start_fight(foe: Dictionary) -> void:
	combat = Combat.new()
	combat.start(run.deck, foe, run.hp, run.max_hp, content.ideas, rng)
	fight_log = ["%s stands in your way." % foe["name"]]
	render_combat()


func render_combat() -> void:
	_clear()
	if combat.is_won():
		run.hp = combat.hp
		_label("%s is defeated." % combat.enemy["name"], 30, GOLD)
		_button("Continue", _finish_step)
		return
	if combat.is_lost():
		show_result(false)
		return
	var intent := combat.current_intent()
	_label(combat.enemy["name"], 30, Color(0.9, 0.5, 0.45))
	_label("HP %d / %d   Block %d   Next: %s %d" % [combat.enemy_hp, int(combat.enemy["hp"]),
		combat.enemy_block, str(intent["kind"]).capitalize(), int(intent["value"])], 20)
	screen.add_child(HSeparator.new())
	for line in fight_log.slice(maxi(0, fight_log.size() - 4)):
		_label(line, 17, DIM)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(spacer)
	_label("You   HP %d / %d   Block %d   Strength %d   Energy %d / %d" % [combat.hp, combat.max_hp,
		combat.block, combat.strength, combat.energy, Combat.ENERGY_PER_TURN], 20, GOLD)
	var hand_row := _row()
	for i in combat.hand.size():
		var id: String = combat.hand[i]
		var idea: Dictionary = content.ideas[id]
		var tag := "GOLD" if memory.is_gold(id) else ("RECALL" if memory.is_due(id, _now()) else "known")
		var b := _button("%s\nCost %d\n%s\n[%s]" % [idea["name"], int(idea["cost"]), _effects_text(idea), tag],
			_on_card.bind(i), hand_row)
		b.custom_minimum_size = Vector2(210, 170)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = not combat.can_play(i)
		if memory.is_gold(id):
			b.add_theme_color_override("font_color", GOLD)
	_button("End turn", func():
		fight_log.append(combat.end_turn())
		render_combat())


func _on_card(i: int) -> void:
	if not combat.can_play(i):
		return
	var id: String = combat.hand[i]
	if memory.is_due(id, _now()):
		_show_recall(i, id)
	else:
		_play(i, GOLD_POWER if memory.is_gold(id) else 1.0)


func _play(i: int, power: float) -> void:
	fight_log.append(combat.play(i, power))
	render_combat()


func _show_recall(i: int, id: String) -> void:
	prompt_card = i
	prompt_idea = id
	prompt = Recall.build(content.ideas[id], content.ideas.values(), rng)
	time_left = RECALL_SECONDS
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 160
	box.offset_right = -160
	box.offset_top = 80
	box.add_theme_constant_override("separation", 12)
	overlay.add_child(box)
	_label("RECALL", 28, GOLD, box)
	_label(prompt["question"], 22, Color.WHITE, box)
	timer_bar = ProgressBar.new()
	timer_bar.max_value = RECALL_SECONDS
	timer_bar.value = RECALL_SECONDS
	timer_bar.show_percentage = false
	box.add_child(timer_bar)
	for n in prompt["options"].size():
		var b := _button(prompt["options"][n], _answer.bind(n), box)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _answer(choice: int) -> void:
	if prompt_card < 0:
		return
	var i := prompt_card
	var id := prompt_idea
	prompt_card = -1
	var correct := Recall.is_correct(prompt, choice)
	var was_gold := memory.is_gold(id)
	memory.record(id, correct, _now())
	_persist()
	var box: VBoxContainer = overlay.get_child(0)
	for c in box.get_children():
		c.queue_free()
	var idea: Dictionary = content.ideas[id]
	if correct:
		run_right += 1
		_label("Right. Full power.", 28, GOLD, box)
	else:
		run_wrong += 1
		_label("Out of time." if choice < 0 else "Not quite.", 28, Color(0.9, 0.5, 0.45), box)
		_label("The answer: %s" % prompt["options"][prompt["answer"]], 20, Color.WHITE, box)
		_label("%s: %s" % [idea["name"], idea["summary"]], 18, DIM, box)
		_label("The card plays at half power, and this idea will come back soon.", 16, DIM, box)
	var power := (GOLD_POWER if was_gold else 1.0) if correct else WEAK_POWER
	_button("Play the card", func():
		overlay.queue_free()
		overlay = null
		prompt = {}
		_play(i, power), box)
