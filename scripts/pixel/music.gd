extends Node
## Each zone's music and sounds, as layers. The Nexus, where the game begins: a slow prelude on
## glass chimes, heard at first only as an echo in the void. The Shore: its slow, grand theme,
## waves far below, wind, the fire, and distant bells. A book's place starts lost to the world,
## and you hear it: only the faint echo of its tune and the wind. Each piece of the place you
## bring back by understanding brings back its own layer (the stream, the birds, the walking
## bass, the warm drone, the teacher's own melody, the soldiers' drum), until the whole track
## plays and the echo is gone. Layers of one track loop in step. Passing a gateway crossfades
## between zones; sitting down swells the music a little. Files come from tools/make_music.py;
## reverb lives on the Music bus.

const BUS := "Music"
const FADE := 2.5
const SILENT := -60.0
const SWELL := 4.0
const DUCK := 3.0  # dB the music gives way to a voice
const BELL_NOTES := [1.0, 1.1892, 1.3348, 1.4983, 1.7818]  # D minor pentatonic above D5
## zone -> its layers. Each is a loop: its "file", its volume "db", whether it is "music" (music
## layers start in step and swell when you sit), "needs" (the piece of the place that must be
## back before it is heard), "until" (the piece whose return silences it), "fade" (dB it drops
## for each piece back), and "loud_db" with "loud_until" (louder until that piece is back).
const ZONES := {
	# The Nexus: always the sunken echo of its prelude and the void's breath, the same however
	# much is mended (the healed layers nexus_drone/bass/arp/pad/voices are kept but unused).
	"nexus": {"bells": false, "layers": [
		{"file": "nexus_ghost", "db": -9.0, "music": true},
		{"file": "void", "db": -13.0}]},
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
		{"file": "wind", "db": -24.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# Athens is peeled back under its melody (BB1, 2026-09-27: "slightly too oppressive and constant"):
	# the pipes lead, the walking bass, drone and drum sit well under them.
	"athens": {"bells": false, "layers": [
		{"file": "athens_ghost", "db": -13.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "athens_walk", "db": -15.0, "music": true, "needs": "walkway"},
		{"file": "athens_drone", "db": -16.0, "music": true, "needs": "sun"},
		{"file": "athens_pipes", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "athens_drum", "db": -16.0, "music": true, "needs": "soldiers"},
		{"file": "stream", "db": -22.0, "needs": "water"},
		{"file": "birds", "db": -20.0, "needs": "leaves"},
		{"file": "wind", "db": -27.0, "loud_db": -20.0, "loud_until": "sun"}]},
	# The places still to come, ready for when they are built (their music is made; which piece
	# brings back which layer follows the Lyceum: the ghost until the teacher, the drone with the
	# sun, the melody with the teacher, the soldiers' drum with the soldiers).
	# Rome: the cornu's pedal, the water organ, a tibia, the legion's drum and horn calls.
	"rome": {"bells": false, "layers": [
		{"file": "rome_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "rome_organ", "db": -10.0, "music": true, "needs": "lamps"},
		{"file": "rome_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "rome_tibia", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "rome_march", "db": -11.0, "music": true, "needs": "walkway"},  # the Forum's life, once its court stands
		{"file": "crowd", "db": -24.0, "needs": "household"},
		{"file": "fountain", "db": -26.0, "needs": "water"},
		{"file": "birds", "db": -24.0, "needs": "leaves"},
		{"file": "wind", "db": -26.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# The city of Rome, the Rome world's hub: a town theme, bright as a village square on a fine
	# day (ocarina, marimba, plucked bass, shaker), the crowd and the birds by day; by night the
	# same tune on a music box, the fountains and the crickets. Its "back" is the hour: "day" or
	# "night" (urbs_life.gd).
	"urbs": {"bells": false, "layers": [
		{"file": "urbs_bass", "db": -11.0, "music": true, "needs": "day"},
		{"file": "urbs_keys", "db": -9.0, "music": true, "needs": "day"},
		{"file": "urbs_lead", "db": -10.0, "music": true, "needs": "day"},
		{"file": "urbs_perc", "db": -13.0, "music": true, "needs": "day"},
		{"file": "urbs_night", "db": -8.0, "music": true, "needs": "night"},
		{"file": "crowd", "db": -23.0, "needs": "day"},
		{"file": "birds", "db": -25.0, "needs": "day"},
		{"file": "crickets", "db": -22.0, "needs": "night"},
		{"file": "fountain", "db": -30.0},
		{"file": "wind", "db": -32.0}]},
	# The late Empire: the same tune in F minor and a little out of true; a thinner crowd.
	"urbs_late": {"bells": false, "layers": [
		{"file": "urbs_late_bass", "db": -12.0, "music": true, "needs": "day"},
		{"file": "urbs_late_keys", "db": -11.0, "music": true, "needs": "day"},
		{"file": "urbs_late_lead", "db": -11.0, "music": true, "needs": "day"},
		{"file": "urbs_late_perc", "db": -17.0, "music": true, "needs": "day"},
		{"file": "urbs_late_night", "db": -9.0, "music": true, "needs": "night"},
		{"file": "crowd", "db": -29.0, "needs": "day"},
		{"file": "crickets", "db": -22.0, "needs": "night"},
		{"file": "wind", "db": -24.0}]},
	# The emptied city: only the echo of Rome's old tune, the wind, and the crickets at night.
	"urbs_fall": {"bells": false, "layers": [
		{"file": "rome_ghost", "db": -9.0, "music": true},
		{"file": "crickets", "db": -24.0, "needs": "night"},
		{"file": "wind", "db": -17.0}]},
	# Troy (Homer): a phorminx to the hexameter, the bard's hum, the camp's slow war drum, the sea.
	"troy": {"bells": false, "layers": [
		{"file": "troy_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "troy_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "troy_voice", "db": -10.0, "music": true, "needs": "household"},
		{"file": "troy_phorminx", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "troy_drum", "db": -10.0, "music": true, "needs": "soldiers"},
		{"file": "waves", "db": -20.0, "needs": "water"},  # the sea moves again
		{"file": "birds", "db": -24.0, "needs": "leaves"},
		{"file": "fire", "db": -26.0, "needs": "lamps"},  # the fires along the ships
		{"file": "hooves", "db": -27.0, "needs": "walkway"},  # chariots on the plain
		{"file": "wind", "db": -24.0, "loud_db": -15.0, "loud_until": "sun"}]},
	# The theatre (the tragedians): the aulos over its drone pipe, the chorus, the heart drum.
	"theatre": {"bells": false, "layers": [
		{"file": "theatre_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "theatre_drum", "db": -12.0, "music": true, "needs": "walkway"},
		{"file": "theatre_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "theatre_aulos", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "theatre_chorus", "db": -10.0, "music": true, "needs": "household"},
		{"file": "fire", "db": -26.0, "needs": "lamps"},  # the beacon, the torches
		{"file": "cicadas", "db": -24.0, "needs": "leaves"},
		{"file": "wind", "db": -26.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# Lesbos (Sappho): the barbitos to the Sapphic stanza, a woman's voice, the sea below.
	"lesbos": {"bells": false, "layers": [
		{"file": "lesbos_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "lesbos_low", "db": -9.0, "music": true, "needs": "lamps"},
		{"file": "lesbos_drone", "db": -9.0, "music": true, "needs": "sun"},
		{"file": "lesbos_barbitos", "db": -9.0, "music": true, "needs": "teacher"},
		{"file": "lesbos_voice", "db": -10.0, "music": true, "needs": "household"},
		{"file": "waves", "db": -21.0},
		{"file": "stream", "db": -25.0, "needs": "water"},  # the cold water through the apple boughs (fr. 2)
		{"file": "birds", "db": -24.0, "needs": "leaves"},
		{"file": "wind", "db": -24.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# Alexandria (Euclid): the tetraktys on a kithara, the monochord, gulls over the harbour.
	"alexandria": {"bells": false, "layers": [
		{"file": "alexandria_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "alexandria_low", "db": -9.0, "music": true, "needs": "walkway"},
		{"file": "alexandria_drone", "db": -9.0, "music": true, "needs": "sun"},
		{"file": "alexandria_kithara", "db": -9.0, "music": true, "needs": "teacher"},
		{"file": "alexandria_monochord", "db": -10.0, "music": true, "needs": "lamps"},
		{"file": "gulls", "db": -26.0, "needs": "sun"},
		{"file": "birds", "db": -25.0, "needs": "leaves"},
		{"file": "crowd", "db": -28.0, "needs": "household"},
		{"file": "waves", "db": -22.0},
		{"file": "wind", "db": -25.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# The Academy (Plato): the enharmonic pipe, the Sirens of Er, the Fates; the Cephisus nearby.
	"academy": {"bells": false, "layers": [
		{"file": "academy_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "academy_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "academy_spheres", "db": -10.0, "music": true, "needs": "lamps"},
		{"file": "academy_pipe", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "academy_voices", "db": -10.0, "music": true, "needs": "household"},
		{"file": "stream", "db": -23.0, "needs": "water"},
		{"file": "birds", "db": -22.0, "needs": "leaves"},
		{"file": "crowd", "db": -27.0, "needs": "walkway"},  # the city in speech, peopled
		{"file": "salpinx", "db": -28.0, "needs": "soldiers"},  # its guardians
		{"file": "wind", "db": -26.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# Helicon (Hesiod): a shepherd's pipe, the nine Muses, the flock on the mountain, their spring.
	"helicon": {"bells": false, "layers": [
		{"file": "helicon_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "helicon_low", "db": -9.0, "music": true, "needs": "lamps"},
		{"file": "helicon_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "helicon_pipe", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "helicon_muses", "db": -10.0, "music": true, "needs": "household"},
		{"file": "stream", "db": -24.0, "needs": "water"},
		{"file": "flock", "db": -22.0, "needs": "leaves"},
		{"file": "wind", "db": -24.0, "loud_db": -15.0, "loud_until": "sun"}]},
	# Sardis and Thermopylae (Herodotus): Croesus's kithara in the Lydian mode; the Spartans' march.
	"sardis": {"bells": false, "layers": [
		{"file": "sardis_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "sardis_low", "db": -9.0, "music": true, "needs": "lamps"},
		{"file": "sardis_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "sardis_kithara", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "sardis_march", "db": -11.0, "music": true, "needs": "soldiers"},
		{"file": "birds", "db": -25.0, "needs": "leaves"},
		{"file": "crowd", "db": -25.0, "needs": "household"},
		{"file": "wind", "db": -25.0, "loud_db": -16.0, "loud_until": "sun"}]},
	# Athens at war (Thucydides): the funeral in the Kerameikos, the lament, the pyres.
	"kerameikos": {"bells": false, "layers": [
		{"file": "kerameikos_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "kerameikos_drum", "db": -11.0, "music": true, "needs": "walkway"},
		{"file": "kerameikos_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "kerameikos_aulos", "db": -10.0, "music": true, "needs": "teacher"},
		{"file": "kerameikos_lament", "db": -10.0, "music": true, "needs": "household"},
		{"file": "crickets", "db": -26.0, "needs": "leaves"},
		{"file": "fire", "db": -26.0, "needs": "lamps"},
		{"file": "wind", "db": -24.0, "loud_db": -15.0, "loud_until": "sun"}]},
	# Ephesus and Elea (the Pre-Socratics): Heraclitus's river and fire, Parmenides' one tone.
	"ephesus": {"bells": false, "layers": [
		{"file": "ephesus_ghost", "db": -9.0, "music": true, "until": "teacher", "fade": 1.5},
		{"file": "ephesus_one", "db": -11.0, "music": true, "needs": "walkway"},
		{"file": "ephesus_drone", "db": -10.0, "music": true, "needs": "sun"},
		{"file": "ephesus_flux", "db": -9.0, "music": true, "needs": "teacher"},
		{"file": "ephesus_lyre", "db": -9.0, "music": true, "needs": "household"},
		{"file": "stream", "db": -22.0, "needs": "water"},
		{"file": "fire", "db": -27.0, "needs": "lamps"},
		{"file": "wind", "db": -25.0, "loud_db": -16.0, "loud_until": "sun"}]},
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
		if layer.has("loud_until") and not back.has(layer["loud_until"]):
			db = layer["loud_db"]
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


## Something is speaking over the music (the grail voice): it dips a little to make room.
func duck(on: bool) -> void:
	for p in _players:
		if p["music"] and is_instance_valid(p["player"]):
			_fade(p, p["db"] + _swell - (DUCK if on else 0.0), 2.0 if on else 3.5)


## Where the zone's music has got to in its loop, in seconds (0 when none is playing).
func position() -> float:
	return _music_position()


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
