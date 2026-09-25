extends CanvasLayer
## Full-screen recall question. Call ask(); emits finished(correct) after the
## player has seen the feedback and pressed continue.

signal finished(correct: bool)

const Recall := preload("res://scripts/recall.gd")
const SECONDS := 12.0
const GOLD := Color(0.95, 0.78, 0.3)
const DIM := Color(0.65, 0.68, 0.75)
const BAD := Color(0.9, 0.5, 0.45)

var prompt: Dictionary = {}
var idea: Dictionary = {}
var time_left := 0.0
var waiting := false  # true while the question is open
var box: VBoxContainer
var bar: ProgressBar


func _init() -> void:
	layer = 10


func ask(for_idea: Dictionary, pool: Array, rng: RandomNumberGenerator) -> void:
	idea = for_idea
	prompt = Recall.build(idea, pool, rng)
	time_left = SECONDS
	waiting = true
	_build()
	_text("RECALL", 28, GOLD)
	_text(prompt["question"], 22, Color.WHITE)
	bar = ProgressBar.new()
	bar.max_value = SECONDS
	bar.value = SECONDS
	bar.show_percentage = false
	box.add_child(bar)
	for n in prompt["options"].size():
		var b := Button.new()
		b.text = prompt["options"][n]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(answer.bind(n))
		box.add_child(b)


func _process(delta: float) -> void:
	if not waiting:
		return
	time_left -= delta
	if bar:
		bar.value = time_left
	if time_left <= 0.0:
		answer(-1)


## choice -1 means the time ran out.
func answer(choice: int) -> void:
	if not waiting:
		return
	waiting = false
	var correct := Recall.is_correct(prompt, choice)
	for c in box.get_children():
		c.queue_free()
	if correct:
		_text("Right. Full power.", 28, GOLD)
	else:
		_text("Out of time." if choice < 0 else "Not quite.", 28, BAD)
		_text("The answer: %s" % prompt["options"][prompt["answer"]], 20, Color.WHITE)
		_text("%s: %s" % [idea["name"], idea["summary"]], 18, DIM)
		_text("The card plays at half power, and this idea will come back soon.", 16, DIM)
	var b := Button.new()
	b.text = "Play the card"
	b.custom_minimum_size = Vector2(220, 48)
	b.pressed.connect(func():
		queue_free()
		finished.emit(correct))
	box.add_child(b)


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 160
	box.offset_right = -160
	box.offset_top = 80
	box.add_theme_constant_override("separation", 12)
	shade.add_child(box)


func _text(t: String, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	box.add_child(l)
