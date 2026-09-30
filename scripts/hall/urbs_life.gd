extends RefCounted
## The life of the city while you walk it: the day going round (the sun crossing from the Esquiline
## to the Janiculum, the sky warming and cooling, dusk, the stars, the lamps in the windows at
## night), the people coming out by day and going home at dark (the watch and the carters and the
## late drinkers out instead), and what people say out loud as you pass: a greeting, a seller's
## cry, a curse when you walk into them.
##
## The Hall calls step() every frame; it returns "day" or "night" when the music should change.

const Citizen := preload("res://scripts/hall/citizen.gd")
const RomeMap := preload("res://scripts/hall/rome_map.gd")

const DAY_SECONDS := 900.0  # a whole day and night: fifteen minutes
const DAWN := 5.5
const DUSK := 20.0
## The sky through the day: [hour, top, horizon, ground, fog, ambient, ambient energy, sun colour, sun energy].
const SKY := [
	[0.0, "0a0e1e", "1c2238", "121418", "1a2030", "3a4260", 0.32, "8090c0", 0.16],
	[5.0, "141c3a", "4a4058", "2a2428", "3a3448", "4a4a68", 0.38, "a08aa0", 0.2],
	[6.5, "3a5a98", "f0a878", "a07a60", "d8b09a", "8a8898", 0.6, "ffc090", 0.85],
	[9.0, "2c5aa8", "c8d8e8", "a8a090", "d0dce8", "8a94a0", 0.8, "fff4e0", 1.3],
	[13.0, "2a64b8", "d8e4ee", "b0a490", "d8e0e8", "98a0aa", 0.85, "fff8ec", 1.35],
	[17.0, "2a3a6e", "f0aa74", "b8765a", "c89a84", "7c7a92", 0.68, "ffc896", 1.15],
	[19.0, "1a2248", "d8845e", "a0604c", "8e7488", "686c8e", 0.55, "ff9a6a", 0.7],
	[20.5, "10152e", "4a3a50", "241e24", "2a2434", "44486a", 0.38, "a08aa0", 0.22],
	[24.0, "0a0e1e", "1c2238", "121418", "1a2030", "3a4260", 0.32, "8090c0", 0.16],
]

var hour := 8.0
var gloom := 0.0  # how far the age has fallen: greyer, darker, thicker air
var haze := 0.0  # the late city's haze: the air thick and yellow in the afternoon (384)
var smoke := 0.0  # the smoke over the burnt quarters, browning the sky (455)
var long_dusk := false  # the emptied city: the evening drawn out, the sun low for hours (552)
var env: Environment
var sun: DirectionalLight3D
var sky: ProceduralSkyMaterial
var stars: Node3D
var windows: StandardMaterial3D  # the windows' glass: lit from within at night
var shops: MultiMeshInstance3D  # the shop fronts (rome_map.gd): their shutters go up at dusk and come down at dawn
var _shut := false
var flames: Array = []  # braziers and torches, lit at dusk
var people: Array = []  # {root, citizen?, shift}
var town: RefCounted  # urbs_town.gd: the calendar, the events, rain, birds, dogs, sounds
var met := {}  # a citizen's id -> how often you have talked (kept in the save)
var rng := RandomNumberGenerator.new()
var _phase := ""
var _shown := ""
var _bubbles: Array = []  # {label, until}
var _heard := {}  # person index -> when they may speak again
var _t := 0.0
var _scan := 0.0
var _last_at := Vector3.ZERO
var _speed := 0.0
var _later: Array = []  # [when, root, line]: a reply a moment after
var _steps: AudioStreamPlayer  # your footfalls, by what is underfoot
var _stride := 0.0
var _step_files := {}


func setup(world: Node3D, start_hour: float, age_gloom: float) -> void:
	hour = start_hour
	gloom = age_gloom
	rng.seed = 97
	for we: Node in world.find_children("*", "WorldEnvironment", true, false):
		env = (we as WorldEnvironment).environment
		sky = env.sky.sky_material as ProceduralSkyMaterial
	for l: Node in world.find_children("*", "DirectionalLight3D", true, false):
		sun = l as DirectionalLight3D
	_apply()


## The phase of the day at `h`: "day" or "night".
static func phase_at(h: float) -> String:
	return "day" if h >= DAWN and h < DUSK else "night"


func phase() -> String:
	return phase_at(hour)


## Which of the city's music layers play now (music.gd's "needs"): the day's or the night's.
func music_back() -> Array:
	return [phase(), "rain"] if town and town.raining else [phase()]


## Who is out at `h`: the day's people by day, the night's by night, and at the edges of the day
## only some of each.
static func out_at(shift: String, h: float, lot: float) -> bool:
	match shift:
		"always":
			return true
		"night":
			return h < DAWN + 0.5 or h >= DUSK - 1.0
	if h >= DAWN + 1.0 and h < DUSK - 1.5:
		return true
	if h >= DAWN and h < DUSK:
		return lot < 0.5  # the early and the late
	return lot < 0.08  # a few out after dark


func step(delta: float, at: Vector3) -> String:
	_t += delta
	var was := hour
	hour = fmod(hour + delta * 24.0 / DAY_SECONDS, 24.0)
	if town and hour < was:
		town.next_day()  # midnight: the calendar moves on
	_apply()
	var now := phase()
	var changed := ""
	if now != _phase:
		_phase = now
		changed = now
	var shown := "%d" % int(hour * 2.0)  # who is out changes each half hour
	if shown != _shown:
		_shown = shown
		_who_is_out()
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.2
		_speed = (at - _last_at).length() / 0.2
		_voices(at, _speed)
		_last_at = at
	_footsteps(delta, at)
	if town:
		var wet: bool = town.raining
		town.step(delta, at, hour, _speed > 1.5)
		if town.raining != wet and changed == "":
			changed = "rain" if town.raining else _phase
	for w: Array in _later.duplicate():
		if _t >= float(w[0]):
			_later.erase(w)
			if is_instance_valid(w[1]):
				say(w[1], w[2])
	for b: Dictionary in _bubbles.duplicate():
		var label: Label3D = b["label"]
		if not is_instance_valid(label):
			_bubbles.erase(b)
			continue
		var left: float = b["until"] - _t
		label.modulate.a = clampf(left, 0.0, 1.0)
		if b.has("root") and is_instance_valid(b["root"]):
			label.global_position = (b["root"] as Node3D).global_position + Vector3(0, 2.25, 0)
		if left <= 0.0:
			label.queue_free()
			_bubbles.erase(b)
	return changed


## The hour the sky is drawn for: the same as the clock, except in the emptied city, where the
## evening is drawn out (the sky of five o'clock lasts from three to nine, and dawn comes late).
func sky_hour() -> float:
	if not long_dusk:
		return hour
	if hour >= 15.0 and hour < 21.0:
		return 17.0 + (hour - 15.0) / 6.0 * 2.5  # six hours of the afternoon's last two and a half
	if hour >= 21.0:
		return 19.5 + (hour - 21.0) / 3.0 * 4.5
	if hour < 7.5:
		return hour * 5.0 / 7.5  # the night lasts till seven
	return 5.0 + (hour - 7.5) / 7.5 * 10.0


## The sky, the sun and the lamps for this hour (and the age's gloom, haze and smoke).
func _apply() -> void:
	var h := sky_hour()
	var a: Array = SKY[0]
	var b: Array = SKY[1]
	for i in SKY.size() - 1:
		if h >= float(SKY[i][0]) and h <= float(SKY[i + 1][0]):
			a = SKY[i]
			b = SKY[i + 1]
			break
	var t := clampf((h - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0])), 0.0, 1.0)
	var mix := func(k: int) -> Color:
		var c := Color(str(a[k])).lerp(Color(str(b[k])), t)
		c = c.lerp(Color(c.get_luminance(), c.get_luminance(), c.get_luminance() * 1.05), gloom * 0.6).darkened(gloom * 0.25)
		if haze > 0.0:  # yellowed, as through dust
			c = c.lerp(Color("d8c08a") * c.get_luminance() * 1.3, haze * 0.5)
		if smoke > 0.0:  # browned, as through smoke
			c = c.lerp(Color("6a5040") * (0.4 + c.get_luminance()), smoke * 0.55)
		return c
	if sky:
		sky.sky_top_color = mix.call(1)
		sky.sky_horizon_color = mix.call(2)
		sky.ground_horizon_color = mix.call(3)
		sky.ground_bottom_color = (mix.call(3) as Color).darkened(0.5)
	if env:
		env.fog_light_color = mix.call(4)
		env.fog_density = 0.0009 + 0.0022 * gloom + (0.001 if phase() == "night" else 0.0) + 0.0018 * haze + 0.003 * smoke
		env.ambient_light_color = mix.call(5)
		env.ambient_light_energy = lerpf(float(a[6]), float(b[6]), t) * (1.0 - 0.3 * gloom - 0.15 * smoke)
	if sun:
		var day := clampf((h - 6.0) / 13.0, 0.0, 1.0)
		var up := sin(day * PI)
		if phase() == "night":  # the moon, high and small
			sun.rotation_degrees = Vector3(-55.0, 200.0, 0.0)
		else:
			sun.rotation_degrees = Vector3(-(6.0 + 64.0 * up), 90.0 - 180.0 * day, 0.0)
		sun.light_color = mix.call(7)
		sun.light_energy = lerpf(float(a[8]), float(b[8]), t) * (1.0 - 0.35 * gloom - 0.2 * smoke)
	var dark := 1.0 - clampf(minf(h - DAWN, DUSK - h), 0.0, 1.0) if h > DAWN - 1.0 and h < DUSK + 1.0 else 1.0
	if windows:
		windows.emission_energy_multiplier = 1.4 * dark * (1.0 - 0.6 * gloom)
	if is_instance_valid(shops) and (dark > 0.5) != _shut:
		_shut = dark > 0.5
		shops.material_override = load("res://scripts/hall/rome_map.gd").tinted("h_shop_shut" if _shut else "h_shop")
	if stars:
		stars.visible = dark > 0.3
	for f: Node in flames:
		if is_instance_valid(f):
			(f as Node3D).visible = dark > 0.2


func _who_is_out() -> void:
	for i in people.size():
		var p: Dictionary = people[i]
		var root: Node3D = p["root"]
		if not is_instance_valid(root):
			continue
		var out := out_at(str(p.get("shift", "day")), hour, float(p.get("lot", 0.5)))
		if root.visible != out:
			root.visible = out
			root.process_mode = Node.PROCESS_MODE_INHERIT if out else Node.PROCESS_MODE_DISABLED  # and out of the way


## What people near you say: a greeting as you come up, a cry from a seller, a curse if you walk
## into them. Each speaks now and then, not all the time.
func _voices(at: Vector3, speed: float) -> void:
	for p: Dictionary in people:
		var root: Node3D = p["root"]
		if not is_instance_valid(root) or not root.visible or not p.has("citizen"):
			continue
		var i := root.get_instance_id()
		var d := Vector2(root.global_position.x - at.x, root.global_position.z - at.z).length()
		if d > 9.0 or _t < float(_heard.get(i, 0.0)):
			continue
		var c: Dictionary = p["citizen"]
		var line := ""
		if d < 1.1 and speed > 1.5:
			line = Citizen.react(c, "bump", rng)
			_heard[i] = _t + 5.0
		elif d < 4.0 and met.has(c["id"]) and rng.randf() < 0.6:  # someone you know
			line = ["Salve again, stranger!", "Ah, you! Still in Rome?", "Hello again, friend.", "You again! Good."][rng.randi() % 4]
			_heard[i] = _t + 40.0
		elif d < 4.0 and rng.randf() < 0.35:
			line = Citizen.react(c, "night" if phase() == "night" else "greet", rng, {"hour": hour, "raining": town.raining if town else false})
			_heard[i] = _t + 25.0
		elif d < 14.0 and d > 3.0 and rng.randf() < 0.03 and _chat(root, c):
			_heard[i] = _t + 30.0
		elif d < 9.0 and not (Citizen.job(c["job"]).get("call", []) as Array).is_empty() and rng.randf() < 0.08:
			line = Citizen.react(c, "call", rng)
			_heard[i] = _t + 12.0
		else:
			_heard[i] = _t + 1.5
		if line != "":
			say(root, line)


## Two people who know each other stop and pass a word or two (town.json's "chatter").
func _chat(root: Node3D, c: Dictionary) -> bool:
	var said: Variant = town.data().get("chatter", []) if town else []
	var chatter: Array = (said.get(town.age, said.get("republic", [])) if said is Dictionary else said) if town else []
	if chatter.is_empty():
		return false
	for q: Dictionary in people:
		var other: Node3D = q["root"]
		if q.has("citizen") and other != root and is_instance_valid(other) and other.visible \
				and other.global_position.distance_to(root.global_position) < 3.5:
			var pair: Array = chatter[rng.randi() % chatter.size()]
			var fill := func(line: String) -> String:
				return line.replace("{a}", str(c["call"])).replace("{b}", str(q["citizen"]["call"]))
			say(root, fill.call(str(pair[0])))
			say(other, fill.call(str(pair[1])), 1.8)
			_heard[other.get_instance_id()] = _t + 30.0
			return true
	return false


## Your footfalls as you walk: a knock on the basalt of the streets, a slap on the travertine of
## the Forum, a soft thud on the earth of the lanes and the open ground, read off the feasibility
## map underfoot (rome_map._occ), one every stride.
func _footsteps(delta: float, at: Vector3) -> void:
	if _speed < 0.6 or town == null or not town.sound or stars == null:
		_stride = 0.0
		return
	_stride += delta * _speed
	if _stride < 1.6:
		return
	_stride = 0.0
	var kind: int = RomeMap._occ.kind_at(at) if RomeMap._occ != null else -1
	var file := "step_earth"
	if kind == RomeMap.Occupancy.ROAD:
		file = "step_stone"
	elif kind == RomeMap.Occupancy.OPEN or kind == RomeMap.Occupancy.MONUMENT:
		file = "step_slab"
	if not _step_files.has(file):
		var path := "res://assets/music/%s.wav" % file
		_step_files[file] = load(path) if ResourceLoader.exists(path) else null
	if _step_files[file] == null:
		return
	if _steps == null:
		_steps = AudioStreamPlayer.new()
		_steps.bus = "Master"
		_steps.volume_db = -14.0
		stars.get_parent().add_child(_steps)
	_steps.stream = _step_files[file]
	_steps.pitch_scale = rng.randf_range(0.9, 1.12)
	_steps.play()


## A line of speech over someone's head, fading after a few seconds (after `delay`, if given).
func say(root: Node3D, line: String, delay: float = 0.0) -> void:
	if delay > 0.0:
		_later.append([_t + delay, root, line])
		return
	var label := Label3D.new()
	label.text = line
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.004
	label.modulate = Color("fff4dc")
	label.outline_modulate = Color(0.08, 0.06, 0.05, 0.9)
	label.no_depth_test = true
	label.fixed_size = false
	root.get_parent().add_child(label)
	label.global_position = root.global_position + Vector3(0, 2.25, 0)
	_bubbles.append({"label": label, "until": _t + 3.2, "root": root})
