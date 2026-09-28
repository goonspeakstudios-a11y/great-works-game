extends Panel
## The activity panel: a scene of the city (urbs_scene.gd) played on screen. Its title and where
## it happens at the top, what has been said so far, and below it whatever the moment asks for:
## up to four choices (keys 1 to 4, or the mouse), a bar to hold F on or to stop a swinging mark
## on (F or Space), a line to copy words into, or a game at the table (urbs_games_view.gd).
## When the scene ends, F or the one choice left closes it (`closed`).

signal closed

const W := 568
const H := 328
const TEXT_H := 150
const LINES_SHOWN := 40

var scene: RefCounted  # urbs_scene.gd
var standing: RefCounted  # urbs_standing.gd, for the purse in the corner
var _title: Label
var _where: Label
var _purse: Label
var _text: RichTextLabel
var _bar: Bar
var _line: LineEdit
var _buttons: Array = []
var _hint: Label
var _game_host: Control
var _game_view: Control
var _hold_button: Button
var _shown := -1  # how many lines were drawn last time
var _last_kind := ""


## The bar under the words: a swinging mark and its zone, or how far F has been held.
class Bar extends Control:
	var mode := ""  # "timing" or "hold"
	var pos := 0.0
	var zone := Vector2.ZERO
	var fill := 0.0

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.08, 0.07, 0.09, 0.95))
		draw_rect(r, Color("5a5060"), false, 2.0)
		if mode == "timing":
			draw_rect(Rect2(zone.x * size.x, 2, (zone.y - zone.x) * size.x, size.y - 4), Color("e0b660"))
			draw_rect(Rect2(pos * size.x - 2, 0, 4, size.y), Color("f4ead6"))
		elif mode == "hold":
			draw_rect(Rect2(2, 2, (size.x - 4) * clampf(fill, 0.0, 1.0), size.y - 4), Color("c86a3a"))


func build(style: Callable, label: Callable) -> void:
	add_theme_stylebox_override("panel", style.call(0.95, Color("7a6040")))
	position = Vector2((640 - W) / 2.0, (360 - H) / 2.0)
	size = Vector2(W, H)
	hide()
	_title = label.call(Color("e0b660"), true)
	_title.position = Vector2(12, 6)
	add_child(_title)
	_where = label.call(Color("a6c8cc"))
	_where.position = Vector2(12, 24)
	add_child(_where)
	_purse = label.call(Color("c8b890"))
	_purse.position = Vector2(W - 220, 6)
	_purse.size = Vector2(208, 16)
	_purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_purse)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.position = Vector2(12, 42)
	_text.size = Vector2(W - 24, TEXT_H)
	_text.add_theme_color_override("default_color", Color("f0e6d0"))
	add_child(_text)
	_game_host = Control.new()
	_game_host.position = Vector2(12, 42)
	_game_host.size = Vector2(W - 24, 196)
	_game_host.hide()
	add_child(_game_host)
	_bar = Bar.new()
	_bar.position = Vector2(12, 198)
	_bar.size = Vector2(W - 24, 18)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.hide()
	add_child(_bar)
	_line = LineEdit.new()
	_line.position = Vector2(12, 196)
	_line.size = Vector2(W - 24, 22)
	_line.placeholder_text = "Write it here, then Enter"
	_line.add_theme_stylebox_override("normal", style.call(0.9, Color("5a5060")))
	_line.add_theme_stylebox_override("focus", style.call(0.9, Color("e0b660")))
	_line.text_submitted.connect(_on_typed)
	_line.hide()
	add_child(_line)
	for k in 4:
		var b := Button.new()
		b.position = Vector2(12, 224 + k * 23)
		b.size = Vector2(W - 24, 21)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_stylebox_override("normal", style.call(0.9))
		b.add_theme_stylebox_override("hover", style.call(0.9, Color("e0b660")))
		b.add_theme_stylebox_override("focus", style.call(0.9, Color("e0b660")))
		b.add_theme_stylebox_override("disabled", style.call(0.6))
		b.add_theme_color_override("font_color", Color("d6ccba"))
		b.add_theme_color_override("font_disabled_color", Color("6a6258"))
		b.pressed.connect(_on_button.bind(k))
		add_child(b)
		_buttons.append(b)
	_hold_button = Button.new()
	_hold_button.position = Vector2(12, 224)
	_hold_button.size = Vector2(W - 24, 21)
	_hold_button.text = "Hold (or hold F)"
	_hold_button.add_theme_stylebox_override("normal", style.call(0.9))
	_hold_button.add_theme_stylebox_override("pressed", style.call(0.9, Color("e0b660")))
	_hold_button.hide()
	add_child(_hold_button)
	_hint = label.call(Color("8a8074"))
	_hint.position = Vector2(W - 150, H - 18)
	_hint.size = Vector2(140, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "Esc to leave"
	add_child(_hint)


## Opens on a scene, started.
func open(the_scene: RefCounted, the_standing: RefCounted) -> void:
	scene = the_scene
	standing = the_standing
	_title.text = scene.title
	_where.text = scene.where
	_shown = -1
	_last_kind = ""
	_drop_game()
	scene.start()
	show()
	refresh()


func _drop_game() -> void:
	if is_instance_valid(_game_view):
		_game_view.queue_free()
	_game_view = null
	_game_host.hide()


## Draws the scene as it stands.
func refresh() -> void:
	if scene == null:
		return
	var v: Dictionary = scene.view()
	var k: String = v["kind"]
	if scene.lines.size() != _shown:
		_shown = scene.lines.size()
		var out: Array = []
		for line: String in scene.lines.slice(maxi(0, scene.lines.size() - LINES_SHOWN)):
			var safe := line.replace("[", "[lb]")
			if line.begins_with("> "):
				out.append("[color=#8a8074]%s[/color]" % safe)
			elif line.begins_with("(") and line.ends_with(")"):
				out.append("[color=#a6c8cc]%s[/color]" % safe)
			else:
				out.append(safe)
		_text.text = "\n".join(out)
	if standing:
		_purse.text = "%s  |  fides %d" % [standing.money(standing.coin()), standing.fides()]
	var opts: Array = v.get("options", [])
	var on: Array = v.get("enabled", [])
	if scene.done:
		opts = ["Leave"]
		on = [true]
	for n in _buttons.size():
		var b: Button = _buttons[n]
		b.visible = n < opts.size() and k != "play"
		if b.visible:
			b.text = "%d  %s" % [n + 1, opts[n]]
			b.disabled = not bool(on[n]) if n < on.size() else false
	_bar.visible = k in ["timing", "hold", "still"]
	_hold_button.visible = k == "hold"
	if k == "timing":
		_bar.mode = "timing"
		_bar.pos = float(v["bar"])
		_bar.zone = v["zone"]
	elif k in ["hold", "still"]:
		_bar.mode = "hold"
		_bar.fill = float(v.get("hold", 0.0))
	_bar.queue_redraw()
	_line.visible = k == "type"
	if k == "type" and _last_kind != "type":
		_line.text = ""
		_line.grab_focus()
	if k == "play" and _game_view == null:
		_start_game(v["game"])
	_text.size.y = TEXT_H if k != "play" else 0.0
	_text.visible = k != "play"
	var hints := {"timing": "F or Space when the mark is in the gold", "hold": "Hold F", "still": "Keep still. Touch nothing.",
		"say": "F to go on"}
	_hint.text = "F to close" if scene.done else str(hints.get(k, "Esc to leave"))
	_last_kind = k


func _start_game(g: Dictionary) -> void:
	var View: GDScript = load("res://scripts/hall/urbs_games_view.gd")
	_game_view = View.new()
	_game_view.size = _game_host.size
	_game_host.add_child(_game_view)
	_game_host.show()
	_game_view.ended.connect(_on_game_ended)
	_game_view.begin(str(g["game"]), g.get("opts", {}), standing)


func _on_game_ended(did_win: bool, line: String) -> void:
	_drop_game()
	scene.game_over(did_win, line)
	refresh()


func _process(delta: float) -> void:
	if not visible or scene == null or scene.done:
		return
	var holding := _hold_button.button_pressed or Input.is_action_pressed("interact") or Input.is_physical_key_pressed(KEY_SPACE)
	if scene.kind() == "still":
		holding = Input.is_anything_pressed()
	scene.update(delta, holding and scene.kind() in ["hold", "still"])
	refresh()


func _on_button(k: int) -> void:
	if scene == null:
		return
	if scene.done:
		closed.emit()
		return
	scene.choose(k)
	refresh()


func _on_typed(text: String) -> void:
	if scene == null or scene.kind() != "type":
		return
	_line.release_focus()
	scene.typed(text)
	refresh()


## Whether the panel is taking the keys for a line of words or a game.
func typing() -> bool:
	return _line.has_focus() or (_game_view != null and _game_view.visible)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or scene == null or not event is InputEventKey or not event.pressed or event.echo:
		return
	if _line.has_focus() or _game_view != null:
		return
	var key := (event as InputEventKey).physical_keycode
	if scene.done:
		if key in [KEY_F, KEY_ENTER, KEY_SPACE, KEY_1]:
			get_viewport().set_input_as_handled()
			closed.emit()
		return
	var n := key - KEY_1
	if n >= 0 and n < 4:
		get_viewport().set_input_as_handled()
		scene.choose(n)
	elif key in [KEY_F, KEY_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		scene.press()
	elif scene.kind() == "still" and key != KEY_ESCAPE:
		scene.press()
	refresh()
