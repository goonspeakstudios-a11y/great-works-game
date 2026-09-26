extends PanelContainer
## The Esc menu: volume, walking speed and mouse speed (kept between games in
## user://settings.cfg), and buttons to go back to the game or quit.

const PATH := "user://settings.cfg"

var player: CharacterBody3D
var resume := Callable()  # what "Back to the game" does
var _sliders := {}


func _init() -> void:
	hide()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_slider(box, "volume", "Volume", 0.0, 1.0, 0.8)
	_slider(box, "walk", "Walking speed", 0.5, 2.0, 1.0)
	_slider(box, "look", "Mouse speed", 0.25, 3.0, 1.0)
	for b in [["Back to the game", _on_resume], ["Quit", _on_quit]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.pressed.connect(b[1])
		box.add_child(btn)


func _slider(box: VBoxContainer, key: String, text: String, lo: float, hi: float, start: float) -> void:
	var label := Label.new()
	label.text = text
	box.add_child(label)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = start
	s.custom_minimum_size = Vector2(260, 16)
	s.value_changed.connect(func(_v: float) -> void: apply())
	box.add_child(s)
	_sliders[key] = s


## Reads the saved settings (if any) and puts them into effect.
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in _sliders:
			var v: Variant = cfg.get_value("game", key, _sliders[key].value)
			if v is float or v is int:
				_sliders[key].set_value_no_signal(float(v))
	apply()


func apply() -> void:
	var vol: float = _sliders["volume"].value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(0, vol <= 0.001)
	if player:
		player.speed_scale = _sliders["walk"].value
		player.look_scale = _sliders["look"].value


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in _sliders:
		cfg.set_value("game", key, _sliders[key].value)
	if cfg.save(PATH) != OK:
		push_warning("Could not save settings to %s" % PATH)


func _on_resume() -> void:
	save_settings()
	if resume.is_valid():
		resume.call()


func _on_quit() -> void:
	save_settings()
	get_tree().quit()
