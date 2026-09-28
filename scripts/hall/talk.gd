extends Panel
## Talking with someone in the city: a box along the bottom of the screen with their name and
## trade, what they have said, a row of things to ask, and a line to type your own. Picking a topic
## or pressing Enter sends `said` (the topic's id, or "" and the text); the Hall answers with
## show_reply(). Keys 1 to 6 pick the topics. Someone whose trade gives you something to do (a day's
## work, a purchase, a game) has a seventh button for it (key 7), which sends the topic "act".

signal said(topic: String, text: String)

const W := 616
const H := 200
const TOPIC_W := 196

var _name: Label
var _trade: Label
var _text: RichTextLabel
var _line: LineEdit
var _buttons: Array = []
var _topics: Array = []
var _action: Button
var _log := ""


func build(style: Callable, label: Callable, topics: Array) -> void:
	add_theme_stylebox_override("panel", style.call(0.94, Color("7a6040")))
	position = Vector2(12, 360 - H - 8)
	size = Vector2(W, H)
	hide()
	_name = label.call(Color("e0b660"), true)
	_name.position = Vector2(12, 6)
	add_child(_name)
	_trade = label.call(Color("a6c8cc"))
	_trade.position = Vector2(12, 24)
	add_child(_trade)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.position = Vector2(12, 42)
	_text.size = Vector2(W - 24, 62)
	_text.add_theme_color_override("default_color", Color("f0e6d0"))
	add_child(_text)
	_topics = topics
	for k in topics.size():
		var b := Button.new()
		b.position = Vector2(12 + (k % 3) * (TOPIC_W + 4), 108 + (k / 3) * 22)
		b.size = Vector2(TOPIC_W, 20)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%d  %s" % [k + 1, topics[k]["label"]]
		b.add_theme_stylebox_override("normal", style.call(0.9))
		b.add_theme_stylebox_override("hover", style.call(0.9, Color("e0b660")))
		b.add_theme_stylebox_override("focus", style.call(0.9, Color("e0b660")))
		b.add_theme_color_override("font_color", Color("d6ccba"))
		var id: String = topics[k]["id"]
		b.pressed.connect(func() -> void: said.emit(id, topics[k]["label"]))
		add_child(b)
		_buttons.append(b)
	_action = Button.new()
	_action.position = Vector2(12, 152)
	_action.size = Vector2(W - 24, 20)
	_action.clip_text = true
	_action.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_action.add_theme_stylebox_override("normal", style.call(0.9, Color("7a6040")))
	_action.add_theme_stylebox_override("hover", style.call(0.9, Color("e0b660")))
	_action.add_theme_stylebox_override("focus", style.call(0.9, Color("e0b660")))
	_action.add_theme_color_override("font_color", Color("f0d8b0"))
	_action.pressed.connect(func() -> void: said.emit("act", _action.text.substr(3)))
	_action.hide()
	add_child(_action)
	_line = LineEdit.new()
	_line.position = Vector2(12, 176)
	_line.size = Vector2(W - 120, 20)
	_line.placeholder_text = "Say something, then Enter"
	_line.add_theme_stylebox_override("normal", style.call(0.9, Color("5a5060")))
	_line.add_theme_stylebox_override("focus", style.call(0.9, Color("e0b660")))
	_line.text_submitted.connect(_on_line)
	add_child(_line)
	var hint: Label = label.call(Color("8a8074"))
	hint.text = "Esc to go"
	hint.position = Vector2(W - 96, 178)
	add_child(hint)


## Opens on someone: their name, their trade, their first words, and what you can do with them.
func open(who: String, trade: String, first: String, action: String = "") -> void:
	_action.visible = action != ""
	_action.text = "7  " + action
	_name.text = who
	_trade.text = trade
	_log = "[color=#e0b660]%s:[/color] %s" % [who.split(" ")[0], first]
	_text.text = _log
	_line.text = ""
	show()


func show_you(line: String) -> void:
	_log += "\n[color=#8a8074]You: %s[/color]" % line
	_text.text = _log


func show_reply(who: String, line: String) -> void:
	_log += "\n[color=#e0b660]%s:[/color] %s" % [who.split(" ")[0], line]
	_text.text = _log


func typing() -> bool:
	return _line.has_focus()


func release() -> void:
	_line.release_focus()


func _on_line(text: String) -> void:
	if text.strip_edges() == "":
		return
	_line.text = ""
	said.emit("", text)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or _line.has_focus() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var k: int = (event as InputEventKey).physical_keycode - KEY_1
	if k >= 0 and k < _topics.size():
		get_viewport().set_input_as_handled()
		said.emit(_topics[k]["id"], _topics[k]["label"])
	elif k == 6 and _action.visible:
		get_viewport().set_input_as_handled()
		said.emit("act", _action.text.substr(3))
	elif (event as InputEventKey).physical_keycode == KEY_ENTER or (event as InputEventKey).physical_keycode == KEY_T:
		get_viewport().set_input_as_handled()
		_line.grab_focus()
