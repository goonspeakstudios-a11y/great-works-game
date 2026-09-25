extends Node
## Plays a module's music: the drone-and-chords loop, wind, and distant bells at
## random moments and pitches. Reverb lives on the Music bus. Files come from
## tools/make_music.py.

const BUS := "Music"
const BELL_NOTES := [1.0, 1.1892, 1.3348, 1.4983, 1.7818]  # D minor pentatonic above D5

var _bell: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_bus()
	_player("res://assets/music/e1_loop.wav", -8.0)
	_player("res://assets/music/wind.wav", -16.0)
	_bell = _player("res://assets/music/bell.wav", -14.0, false)
	var timer := Timer.new()
	timer.wait_time = 7.0
	timer.timeout.connect(_ring)
	add_child(timer)
	timer.start()


func _player(path: String, db: float, play: bool = true) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = db
	p.bus = BUS
	add_child(p)
	if play:
		p.play()
	return p


func _ring() -> void:
	if _rng.randf() < 0.65:
		_bell.pitch_scale = BELL_NOTES[_rng.randi() % BELL_NOTES.size()]
		_bell.play()


static func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, "Master")
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.95
	verb.damping = 0.55
	verb.spread = 1.0
	verb.wet = 0.55
	verb.dry = 0.6
	AudioServer.add_bus_effect(i, verb)
