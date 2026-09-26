extends PanelContainer
## The question each world asks when you first enter it: who you are here. Two answers, in the
## world's own words (worlds.json "modes"): the Zen way (read the stones and the world mends) and
## the Student way (only real understanding, shown to the teacher, mends it). No way out but to
## choose; it can be changed later in the Esc menu.

signal chosen(mode: String)  # "zen" or "student"

var _title: Label
var _buttons := {}  # mode -> Button
var _notes := {}  # mode -> Label


func _init() -> void:
	hide()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(420, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	for mode in ["zen", "student"]:
		var b := Button.new()
		b.pressed.connect(func() -> void: chosen.emit(mode))
		box.add_child(b)
		var note := Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(400, 0)
		box.add_child(note)
		_buttons[mode] = b
		_notes[mode] = note


## Fills the question in from a world's "modes" entry: {"ask", "zen": {name, line}, "student": {...}}.
func ask(modes: Dictionary) -> void:
	_title.text = str(modes.get("ask", "Who are you here?"))
	for mode in _buttons:
		var m: Dictionary = modes.get(mode, {})
		_buttons[mode].text = str(m.get("name", mode.capitalize()))
		_notes[mode].text = str(m.get("line", ""))
	show()
	_buttons["zen"].grab_focus()
