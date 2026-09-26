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
var _players: Array = []  # {player, db, music, tween}: one fade at a time per player
var _bell: AudioStreamPlayer
var _croak: AudioStreamPlayer
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
	_croak = AudioStreamPlayer.new()
	_croak.stream = load("res://assets/music/croak.wav")
	_croak.volume_db = -6.0
	add_child(_croak)
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
		_fade(p, SILENT, FADE).tween_callback(p["player"].queue_free)
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
	var entry := {"player": p, "db": db, "music": is_music, "tween": null}
	_players.append(entry)
	_fade(entry, db + (_swell if is_music else 0.0), FADE)


## One fade at a time per player: a new one replaces whatever was still running, so a
## swell during a crossfade is not undone by the older tween finishing later.
func _fade(entry: Dictionary, to_db: float, secs: float) -> Tween:
	if entry["tween"] is Tween and entry["tween"].is_valid():
		entry["tween"].kill()
	var tw := create_tween()
	tw.tween_property(entry["player"], "volume_db", to_db, secs)
	entry["tween"] = tw
	return tw


## Sitting down lets the music rise a little over the sounds of the place.
func swell(on: bool) -> void:
	var want := SWELL if on else 0.0
	if want == _swell:
		return
	_swell = want
	for p in _players:
		if p["music"] and is_instance_valid(p["player"]):
			_fade(p, p["db"] + _swell, 1.5)


## The toad's deep croak.
func croak() -> void:
	_croak.pitch_scale = _rng.randf_range(0.85, 1.1)
	_croak.play()


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
