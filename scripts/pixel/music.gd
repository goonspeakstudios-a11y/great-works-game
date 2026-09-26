extends Node
## Each zone's music and sounds, as layers. The Shore: its slow, grand theme, waves far below,
## wind, the fire, and distant bells. A book's place starts lost to the world, and you hear it:
## only the faint echo of its tune and the wind. Each piece of the place you bring back by
## understanding brings back its own layer (the stream, the birds, the walking bass, the warm
## drone, the teacher's own melody, the soldiers' drum), until the whole track plays and the
## echo is gone. Layers of one track loop in step. Passing a gateway crossfades between zones;
## sitting down swells the music a little. Files come from tools/make_music.py; reverb lives on
## the Music bus.

const BUS := "Music"
const FADE := 2.5
const SILENT := -60.0
const SWELL := 4.0
const BELL_NOTES := [1.0, 1.1892, 1.3348, 1.4983, 1.7818]  # D minor pentatonic above D5
## zone -> its layers. Each is a loop: its "file", its volume "db", whether it is "music" (music
## layers start in step and swell when you sit), "needs" (the piece of the place that must be
## back before it is heard), "until" (the piece whose return silences it), "fade" (dB it drops
## for each piece back) and "lost_db" (its volume until the sun comes back).
const ZONES := {
	"shore": {"bells": true, "layers": [
		{"file": "shore", "db": -8.0, "music": true},
		{"file": "waves", "db": -15.0}, {"file": "wind", "db": -18.0}, {"file": "fire", "db": -22.0}]},
	"sicily": {"bells": false, "layers": [
		{"file": "sicily_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "sicily_low", "db": -9.0, "music": true, "needs": "lamps"},
		{"file": "sicily_drone", "db": -9.0, "music": true, "needs": "sun"},
		{"file": "sicily_lyre", "db": -9.0, "music": true, "needs": "teacher"},
		{"file": "fountain", "db": -26.0, "needs": "water"},
		{"file": "cicadas", "db": -22.0, "needs": "leaves"},
		{"file": "fire", "db": -30.0, "needs": "household"},
		{"file": "waves", "db": -24.0},
		{"file": "wind", "db": -24.0, "lost_db": -16.0}]},
	"athens": {"bells": false, "layers": [
		{"file": "athens_ghost", "db": -10.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "athens_walk", "db": -10.0, "music": true, "needs": "walkway"},
		{"file": "athens_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "athens_pipes", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "athens_drum", "db": -10.0, "music": true, "needs": "soldiers"},
		{"file": "stream", "db": -22.0, "needs": "water"},
		{"file": "birds", "db": -20.0, "needs": "leaves"},
		{"file": "wind", "db": -27.0, "lost_db": -17.0}]},
}

var zone := ""
var _players: Array = []  # {file, player, db, music, tween}: one fade at a time per player
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


## Which layers a zone plays, and how loud, with these pieces of its place back.
static func plan(to: String, back: Array) -> Array:
	var out: Array = []
	for layer in ZONES.get(to, {}).get("layers", []):
		if layer.get("needs", "") != "" and not back.has(layer["needs"]):
			continue
		if layer.get("until", "") != "" and back.has(layer["until"]):
			continue
		var db: float = layer["db"] - layer.get("fade", 0.0) * back.size()
		if layer.has("lost_db") and not back.has("sun"):
			db = layer["lost_db"]
		out.append({"file": layer["file"], "db": db, "music": layer.get("music", false)})
	return out


## Moves to what a zone should sound like now: layers that stay are only turned up or down,
## layers no longer wanted fade out, new ones fade in (music in step with what is playing).
func play(to: String, back: Array = []) -> void:
	if not ZONES.has(to):
		return
	zone = to
	var want := {}
	for layer in plan(to, back):
		want[layer["file"]] = layer
	var keep: Array = []
	for p in _players:
		if want.has(p["file"]):
			p["db"] = want[p["file"]]["db"]
			_fade(p, p["db"] + (_swell if p["music"] else 0.0), FADE)
			keep.append(p)
			want.erase(p["file"])
		else:
			_fade(p, SILENT, FADE).tween_callback(p["player"].queue_free)
	_players = keep
	var at := _music_position()
	for f in want:
		_start(want[f], at)
	_bells_on = ZONES[to].get("bells", false)


## Where the music that is still playing has got to, so a returning layer comes in in step.
func _music_position() -> float:
	for p in _players:
		if p["music"] and p["player"].playing:
			return p["player"].get_playback_position()
	return 0.0


func _start(layer: Dictionary, at: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _looping(load(file_for(layer["file"])))
	p.bus = BUS
	p.volume_db = SILENT
	add_child(p)
	p.play(at if layer["music"] else _rng.randf() * 4.0)
	var entry := {"file": layer["file"], "player": p, "db": layer["db"], "music": layer["music"], "tween": null}
	_players.append(entry)
	_fade(entry, layer["db"] + (_swell if layer["music"] else 0.0), FADE)


## Every layer loops, whatever its import settings say.
static func _looping(stream: AudioStream) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	return stream


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
