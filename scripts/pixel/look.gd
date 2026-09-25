extends Node
## The haunted look every stage shares, as layers from back to front:
##   world (drawn by the stage) -> gray filter -> vivid (always in colour)
##   -> ash and vignette -> fade -> text: a dialog box with the speaker's name,
##   a small note in the corner, and a centre card.

const Pix := preload("res://scripts/pixel/pix.gd")
const Painter := preload("res://scripts/pixel/painter.gd")

const GRAY_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float sat = 0.3;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	float cool = 1.0 - sat;
	vec3 g = mix(vec3(l), c, sat) * vec3(1.0 - 0.05 * cool, 1.0, 1.0 + 0.08 * cool) * (1.0 - 0.08 * cool);
	COLOR = vec4(g, 1.0);
}
"""
const BOX_TOP := 142.0

var world: Node2D
var vivid: Node2D
var ui: CanvasLayer
var line: Label
var speaker: Label
var note: Label
var card: Label
var card_sub: Label
var _gray: ShaderMaterial
var _fade: ColorRect
var _box: PanelContainer
var _line_left := 0.0
var _ash: Array = []
var _sat_tween: Tween


func setup(draw_world: Callable, draw_vivid: Callable) -> void:
	world = Painter.new()
	world.paint = draw_world
	add_child(world)
	_gray = ShaderMaterial.new()
	_gray.shader = Shader.new()
	_gray.shader.code = GRAY_SHADER
	var gray_rect := ColorRect.new()
	gray_rect.size = Vector2(Pix.W, Pix.H)
	gray_rect.material = _gray
	gray_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer(1).add_child(gray_rect)
	vivid = Painter.new()
	vivid.paint = draw_vivid
	_layer(2).add_child(vivid)
	var fx := Painter.new()
	fx.paint = _draw_fx
	_layer(3).add_child(fx)
	var vignette := TextureRect.new()
	vignette.texture = _vignette()
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer(3).add_child(vignette)
	ui = _layer(10)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = Vector2(Pix.W, Pix.H)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)
	_build_text()
	for i in 50:
		_ash.append({"p": Vector2(randf() * Pix.W, randf() * Pix.H), "s": randf_range(3, 9),
			"ph": randf() * TAU, "c": Pix.P["bone"] if randf() < 0.2 else Pix.P["ash"]})
	fade_in(1.2)


func _process(delta: float) -> void:
	if _line_left > 0.0:
		_line_left -= delta
		if _line_left <= 0.0:
			say("")


func _layer(n: int) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.layer = n
	add_child(l)
	return l


static func panel_style(alpha: float = 0.92) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.035, 0.03, 0.045, alpha)
	box.border_color = Color("3a3542")
	box.set_border_width_all(1)
	box.content_margin_left = 7
	box.content_margin_right = 7
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box


func _build_text() -> void:
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", panel_style())
	_box.position = Vector2(10, BOX_TOP)
	_box.size = Vector2(Pix.W - 20, 34)
	_box.custom_minimum_size = Vector2(Pix.W - 20, 34)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.hide()
	ui.add_child(_box)
	line = label(9, Pix.P["bone"])
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_box.add_child(line)
	speaker = label(8, Pix.P["gold"])
	speaker.position = Vector2(14, BOX_TOP - 11)
	speaker.size = Vector2(200, 10)
	ui.add_child(speaker)
	note = label(6, Pix.P["ghost"])
	note.position = Vector2(Pix.W - 170, 3)
	note.size = Vector2(166, 10)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(note)
	card = label(16, Pix.P["bone"])
	card.position = Vector2(0, 50)
	card.size = Vector2(Pix.W, 24)
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(card)
	card_sub = label(8, Pix.P["ghost"])
	card_sub.position = Vector2(0, 76)
	card_sub.size = Vector2(Pix.W, 14)
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(card_sub)


static func label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A line from a character (who = "" for the narrator).
func speak(who: String, words: String) -> void:
	speaker.text = who
	line.text = words
	_box.visible = words != ""
	_line_left = 0.0


## One short line with no speaker; seconds > 0 hides it again after that long.
func say(words: String, seconds: float = 0.0) -> void:
	speak("", words)
	_line_left = seconds


func show_card(title: String, sub: String) -> void:
	card.text = title
	card_sub.text = sub


func set_saturation(value: float, seconds: float = 0.0) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		if _sat_tween:
			_sat_tween.kill()
		_gray.set_shader_parameter("sat", value)
		return
	if _sat_tween:
		_sat_tween.kill()
	var from: float = _gray.get_shader_parameter("sat")
	_sat_tween = create_tween()
	_sat_tween.tween_method(func(v: float): _gray.set_shader_parameter("sat", v), from, value, seconds)


func fade_in(seconds: float) -> void:
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, seconds)


func _draw_fx(ci: CanvasItem) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var dt := get_process_delta_time()
	for a in _ash:
		a["p"] += Vector2(sin(t * 0.8 + a["ph"]) * 4.0 - 2.0, a["s"]) * dt
		if a["p"].y > Pix.H:
			a["p"] = Vector2(randf() * Pix.W, -2)
		if a["p"].x < 0:
			a["p"].x += Pix.W
		var c: Color = a["c"]
		c.a = 0.5
		ci.draw_rect(Rect2(floorf(a["p"].x), floorf(a["p"].y), 1, 1), c)


static func _vignette() -> ImageTexture:
	var img := Image.create(Pix.W, Pix.H, false, Image.FORMAT_RGBA8)
	for y in Pix.H:
		for x in Pix.W:
			var nx := (x - Pix.W / 2.0) / (Pix.W / 2.0)
			var ny := (y - Pix.H / 2.0) / (Pix.H / 2.0)
			var v := maxf(0.0, Vector2(nx * 0.8, ny).length() - 0.78) / 0.6
			if v > Pix.dith(x, y):
				img.set_pixel(x, y, Color(0.02, 0.02, 0.035, minf(1.0, 0.45 + v * 0.6)))
	return ImageTexture.create_from_image(img)
