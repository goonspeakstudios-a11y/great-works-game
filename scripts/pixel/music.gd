extends Node
## Each zone's music and sounds. The Shore: its slow, grand theme, waves far below, wind,
## the fire, and distant bells. Porphyry's Sicily: a plucked lyre, cicadas, the sea, the
## fountain. Passing a gateway crossfades from one zone to the next; sitting down swells
## the music a little. Files come from tools/make_music.py; reverb lives on the Music bus.

const BUS := "Music"
const FADE := 2.5
const SILENT := -60.0
const SWELL := 4.0
const BELL_NOTES := [1.0, 1.1892, 1.3348, 1.4983, 1.7818]  # D minor pentatonic above D5
## zone -> music track and ambient loops, each with its volume in dB
const ZONES := {
	"shore": {"music": ["shore", -8.0], "sounds": {"waves": -15.0, "wind": -18.0, "fire": -22.0}, "bells": true},
	"sicily": {"music": ["sicily", -9.0], "sounds": {"cicadas": -22.0, "waves": -24.0, "fountain": -26.0, "wind": -24.0}, "bells": false},
}

var zone := ""
var _players: Array = []  # [player, target dB, is_music]
var _bell: AudioStreamPlayer
var _bells_on := false
var _swell := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_bus()
	_bell = AudioStreamPlayer.new()
	_bell.stream = load("res://assets/music/bell.wav")
	_bell.volume_db = -14.0
	_bell.bus = BUS
	add_child(_bell)
	var timer := Timer.new()
	timer.wait_time = 7.0
	timer.timeout.connect(_ring)
	add_child(timer)
	timer.start()


static func file_for(name: String) -> String:
	return "res://assets/music/%s.wav" % name


## Fades out whatever is playing and fades in the zone's own music and sounds.
func play(to: String) -> void:
	if to == zone or not ZONES.has(to):
		return
	zone = to
	for p in _players:
		var old: AudioStreamPlayer = p[0]
		var tw := create_tween()
		tw.tween_property(old, "volume_db", SILENT, FADE)
		tw.tween_callback(old.queue_free)
	_players.clear()
	var spec: Dictionary = ZONES[to]
	_start(spec["music"][0], spec["music"][1], true)
	for s in spec["sounds"]:
		_start(s, spec["sounds"][s], false)
	_bells_on = spec["bells"]


func _start(name: String, db: float, is_music: bool) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load(file_for(name))
	p.bus = BUS
	p.volume_db = SILENT
	add_child(p)
	p.play(_rng.randf() * 4.0 if not is_music else 0.0)
	_players.append([p, db, is_music])
	create_tween().tween_property(p, "volume_db", db + (_swell if is_music else 0.0), FADE)


## Sitting down lets the music rise a little over the sounds of the place.
func swell(on: bool) -> void:
	_swell = SWELL if on else 0.0
	for p in _players:
		if p[2] and is_instance_valid(p[0]):
			create_tween().tween_property(p[0], "volume_db", p[1] + _swell, 1.5)


func _ring() -> void:
	if _bells_on and _rng.randf() < 0.65:
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
