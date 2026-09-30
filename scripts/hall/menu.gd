extends PanelContainer
## The Esc menu: volume, walking speed and mouse speed (kept between games in
## user://settings.cfg), and buttons to go back to the game or quit. The toad opens it too, with
## something to say at the top; for a Theoros (Zen) it also offers the way back to the Nexus.

const PATH := "user://settings.cfg"

var player: CharacterBody3D
var resume := Callable()  # what "Back to the game" does
var switch_mode := Callable()  # changes the way you walk this world
var go_nexus := Callable()  # the toad's offer: back to the Nexus
var go_home := Callable()  # the toad's other offer, in Rome: home, the walk done in a fade
var _mode_button: Button
var _nexus_button: Button
var _home_button: Button
var _title: Label
var _sliders := {}


func _init() -> void:
	hide()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = Label.new()
	_title.text = "PAUSED"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(280, 0)
	box.add_child(_title)
	var version := Label.new()
	var show_version := func() -> void:
		version.text = preload("res://scripts/version.gd").label()
		var updater: Node = get_node_or_null("/root/Updater") if is_inside_tree() else null
		if updater and updater.status != "":
			version.text += "\n" + updater.status
	show_version.call()
	visibility_changed.connect(show_version)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.modulate = Color(1, 1, 1, 0.55)
	box.add_child(version)
	_slider(box, "volume", "Volume", 0.0, 1.0, 0.8)
	_slider(box, "walk", "Walking speed", 0.5, 2.0, 1.0)
	_slider(box, "look", "Mouse speed", 0.25, 3.0, 1.0)
	_mode_button = Button.new()
	_mode_button.pressed.connect(func() -> void: if switch_mode.is_valid(): switch_mode.call())
	_mode_button.hide()
	box.add_child(_mode_button)
	_nexus_button = Button.new()
	_nexus_button.pressed.connect(func() -> void: if go_nexus.is_valid(): go_nexus.call())
	_nexus_button.hide()
	box.add_child(_nexus_button)
	_home_button = Button.new()
	_home_button.pressed.connect(func() -> void: if go_home.is_valid(): go_home.call())
	_home_button.hide()
	box.add_child(_home_button)
	for b in [["Back to the game", _on_resume], ["Quit", _on_quit]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.pressed.connect(b[1])
		box.add_child(btn)


## The line for the way you walk this world ("" hides it, as in the Nexus).
func show_mode(text: String) -> void:
	_mode_button.text = text
	_mode_button.visible = text != ""


## What the menu says at the top: the toad's words, or PAUSED when Esc opened it.
func speak(text: String) -> void:
	_title.text = text if text != "" else "PAUSED"


## The toad's offer of the way back to the Nexus ("" hides it).
func show_nexus(text: String) -> void:
	_nexus_button.text = text
	_nexus_button.visible = text != ""


## The toad's offer of the way home, in Rome ("" hides it).
func show_home(text: String) -> void:
	_home_button.text = text
	_home_button.visible = text != ""


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
