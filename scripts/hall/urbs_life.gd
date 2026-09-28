extends RefCounted
## The life of the city while you walk it: the day going round (the sun crossing from the Esquiline
## to the Janiculum, the sky warming and cooling, dusk, the stars, the lamps in the windows at
## night), the people coming out by day and going home at dark (the watch and the carters and the
## late drinkers out instead), and what people say out loud as you pass: a greeting, a seller's
## cry, a curse when you walk into them.
##
## The Hall calls step() every frame; it returns "day" or "night" when the music should change.

const Citizen := preload("res://scripts/hall/citizen.gd")

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
var env: Environment
var sun: DirectionalLight3D
var sky: ProceduralSkyMaterial
var stars: Node3D
var windows: StandardMaterial3D  # the windows' glass: lit from within at night
var flames: Array = []  # braziers and torches, lit at dusk
var people: Array = []  # {root, citizen?, shift}
var rng := RandomNumberGenerator.new()
var _phase := ""
var _shown := ""
var _bubbles: Array = []  # {label, until}
var _heard := {}  # person index -> when they may speak again
var _t := 0.0
var _scan := 0.0
var _last_at := Vector3.ZERO


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
	return [phase()]


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
	hour = fmod(hour + delta * 24.0 / DAY_SECONDS, 24.0)
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
		_voices(at, (at - _last_at).length() / 0.2)
		_last_at = at
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


## The sky, the sun and the lamps for this hour (and the age's gloom).
func _apply() -> void:
	var a: Array = SKY[0]
	var b: Array = SKY[1]
	for i in SKY.size() - 1:
		if hour >= float(SKY[i][0]) and hour <= float(SKY[i + 1][0]):
			a = SKY[i]
			b = SKY[i + 1]
			break
	var t := clampf((hour - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0])), 0.0, 1.0)
	var mix := func(k: int) -> Color:
		var c := Color(str(a[k])).lerp(Color(str(b[k])), t)
		return c.lerp(Color(c.get_luminance(), c.get_luminance(), c.get_luminance() * 1.05), gloom * 0.6).darkened(gloom * 0.25)
	if sky:
		sky.sky_top_color = mix.call(1)
		sky.sky_horizon_color = mix.call(2)
		sky.ground_horizon_color = mix.call(3)
		sky.ground_bottom_color = (mix.call(3) as Color).darkened(0.5)
	if env:
		env.fog_light_color = mix.call(4)
		env.fog_density = 0.0009 + 0.0022 * gloom + (0.001 if phase() == "night" else 0.0)
		env.ambient_light_color = mix.call(5)
		env.ambient_light_energy = lerpf(float(a[6]), float(b[6]), t) * (1.0 - 0.3 * gloom)
	if sun:
		var day := clampf((hour - 6.0) / 13.0, 0.0, 1.0)
		var up := sin(day * PI)
		if phase() == "night":  # the moon, high and small
			sun.rotation_degrees = Vector3(-55.0, 200.0, 0.0)
		else:
			sun.rotation_degrees = Vector3(-(6.0 + 64.0 * up), 90.0 - 180.0 * day, 0.0)
		sun.light_color = mix.call(7)
		sun.light_energy = lerpf(float(a[8]), float(b[8]), t) * (1.0 - 0.35 * gloom)
	var dark := 1.0 - clampf(minf(hour - DAWN, DUSK - hour), 0.0, 1.0) if hour > DAWN - 1.0 and hour < DUSK + 1.0 else 1.0
	if windows:
		windows.emission_energy_multiplier = 1.4 * dark * (1.0 - 0.6 * gloom)
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
	for i in people.size():
		var p: Dictionary = people[i]
		var root: Node3D = p["root"]
		if not is_instance_valid(root) or not root.visible or not p.has("citizen"):
			continue
		var d := Vector2(root.global_position.x - at.x, root.global_position.z - at.z).length()
		if d > 9.0 or _t < float(_heard.get(i, 0.0)):
			continue
		var c: Dictionary = p["citizen"]
		var line := ""
		if d < 1.1 and speed > 1.5:
			line = Citizen.react(c, "bump", rng)
			_heard[i] = _t + 5.0
		elif d < 4.0 and rng.randf() < 0.35:
			line = Citizen.react(c, "night" if phase() == "night" else "greet", rng)
			_heard[i] = _t + 25.0
		elif d < 9.0 and not (Citizen.job(c["job"]).get("call", []) as Array).is_empty() and rng.randf() < 0.08:
			line = Citizen.react(c, "call", rng)
			_heard[i] = _t + 12.0
		else:
			_heard[i] = _t + 1.5
		if line != "":
			say(root, line)


## A line of speech over someone's head, fading after a few seconds.
func say(root: Node3D, line: String) -> void:
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
