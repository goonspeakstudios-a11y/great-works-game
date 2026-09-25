extends Node3D
## The 3D card table: your idea cards fanned in front of you, the enemy
## across the table. Uses combat.gd for the rules and the recall overlay
## whenever a card's idea is due for review.

signal fight_over(won: bool)
signal memory_changed

const Blocks := preload("res://scripts/world/blocks.gd")
const Combat := preload("res://scripts/combat.gd")
const RecallOverlay := preload("res://scripts/ui/recall_overlay.gd")

const WEAK_POWER := 0.5
const GOLD_POWER := 1.5
const GOLD := Color(0.95, 0.78, 0.3)
const DIM := Color(0.75, 0.78, 0.85)
const BAD := Color(0.9, 0.5, 0.45)
const CARD_SIZE := Vector3(0.42, 0.6, 0.015)
const CAM_POS := Vector3(0, 1.75, 1.6)

var step: Dictionary
var deck: Array
var ideas: Dictionary
var pool: Array          # ideas used for wrong answers: only ones already learned
var memory
var rng: RandomNumberGenerator
var combat := Combat.new()
var log_lines: Array[String] = []
var recalling := false

var camera: Camera3D
var enemy_fig: Node3D
var enemy_label: Label3D
var hand_root: Node3D
var hud: CanvasLayer
var stats: Label
var log_label: Label
var end_button: Button
var result_box: VBoxContainer


func setup(step_data: Dictionary, deck_ids: Array, all_ideas: Dictionary, mem, random: RandomNumberGenerator,
		hp: int = 40, max_hp: int = 40, recall_pool: Array = []) -> void:
	step = step_data
	deck = deck_ids
	ideas = all_ideas
	pool = recall_pool if recall_pool.size() >= 4 else all_ideas.values()
	memory = mem
	rng = random
	combat.start(deck, step["enemy"], hp, max_hp, ideas, rng)
	log_lines = [step.get("intro", "%s stands across the table." % step["enemy"]["name"])]


func _ready() -> void:
	get_viewport().physics_object_picking = true
	_build_room()
	_build_hud()
	render()


func _now() -> int:
	return int(Time.get_unix_time_from_system())


# ---------- play ----------

func on_card(i: int) -> void:
	if recalling or not combat.can_play(i):
		return
	var id: String = combat.hand[i]
	if memory.is_due(id, _now()):
		recalling = true
		var overlay := RecallOverlay.new()
		add_child(overlay)
		overlay.ask(ideas[id], pool, rng)
		overlay.finished.connect(func(correct: bool):
			var was_gold: bool = memory.is_gold(id)
			memory.record(id, correct, _now())
			memory_changed.emit()
			recalling = false
			_play(i, (GOLD_POWER if was_gold else 1.0) if correct else WEAK_POWER))
	else:
		_play(i, GOLD_POWER if memory.is_gold(id) else 1.0)


func end_turn() -> void:
	if recalling or combat.is_over():
		return
	log_lines.append(combat.end_turn())
	render()


func _play(i: int, power: float) -> void:
	var hp_before := combat.enemy_hp
	log_lines.append(combat.play(i, power))
	if combat.enemy_hp < hp_before:
		_shake(enemy_fig)
	render()


# ---------- drawing ----------

func render() -> void:
	var intent := combat.current_intent()
	enemy_label.text = "%s\nHP %d / %d   Block %d\nNext: %s %d" % [combat.enemy["name"], combat.enemy_hp,
		int(combat.enemy["hp"]), combat.enemy_block, str(intent["kind"]).capitalize(), int(intent["value"])]
	stats.text = "You   HP %d / %d   Block %d   Strength %d   Energy %d / %d" % [combat.hp, combat.max_hp,
		combat.block, combat.strength, combat.energy, Combat.ENERGY_PER_TURN]
	log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4)))
	for c in hand_root.get_children():
		c.queue_free()
	var n := combat.hand.size()
	for i in n:
		_card(i, n)
	end_button.disabled = combat.is_over()
	if combat.is_over():
		_show_result()


func _card(i: int, n: int) -> Area3D:
	var id: String = combat.hand[i]
	var idea: Dictionary = ideas[id]
	var gold: bool = memory.is_gold(id)
	var playable := combat.can_play(i)
	var card := Area3D.new()
	var mid := (n - 1) / 2.0
	card.position = Vector3((i - mid) * 0.47, 1.05 - absf(i - mid) * 0.03, 0.55)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = CARD_SIZE
	shape.shape = bs
	card.add_child(shape)
	var face := BoxMesh.new()
	face.size = CARD_SIZE
	var color := GOLD if gold else Color(0.92, 0.87, 0.74)
	card.add_child(Blocks.mesh(face, color if playable else color.darkened(0.45), Vector3.ZERO))
	var tag := "GOLD" if gold else ("RECALL" if memory.is_due(id, _now()) else "known")
	var effects: Array[String] = []
	for e in idea["effects"]:
		effects.append("%s %d" % [str(e["kind"]).capitalize(), int(e["value"])])
	var text := Label3D.new()
	text.text = "%s\n\nCost %d\n%s\n\n[%s]" % [idea["name"], int(idea["cost"]), "\n".join(effects), tag]
	text.font_size = 30
	text.pixel_size = 0.0011
	text.width = 340
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.modulate = Color(0.1, 0.08, 0.06)
	text.outline_size = 0
	text.position = Vector3(0, 0, CARD_SIZE.z / 2 + 0.002)
	card.add_child(text)
	card.mouse_entered.connect(func(): card.position.y += 0.08)
	card.mouse_exited.connect(func(): card.position.y -= 0.08)
	card.input_event.connect(func(_cam, event, _pos, _normal, _shape):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			on_card(i))
	hand_root.add_child(card)
	# Face the camera, fanned slightly (needs to be in the tree first).
	card.look_at(card.position * 2.0 - CAM_POS, Vector3.UP)
	card.rotate_object_local(Vector3.FORWARD, -(i - mid) * 0.07)
	return card


func _show_result() -> void:
	if result_box.get_child_count() > 0:
		return
	var won := combat.is_won()
	var head := Label.new()
	head.text = "%s falls back." % combat.enemy["name"] if won else "You are overwhelmed."
	head.add_theme_font_size_override("font_size", 34)
	head.add_theme_color_override("font_color", GOLD if won else BAD)
	result_box.add_child(head)
	var b := Button.new()
	b.text = "Continue" if won else "Back to the camp (try again)"
	b.custom_minimum_size = Vector2(320, 52)
	b.pressed.connect(func(): fight_over.emit(won))
	result_box.add_child(b)
	result_box.show()


func _shake(node: Node3D) -> void:
	var base := node.position
	var tw := create_tween()
	for k in 4:
		tw.tween_property(node, "position", base + Vector3(rng.randf_range(-0.08, 0.08), 0, 0), 0.04)
	tw.tween_property(node, "position", base, 0.04)


# ---------- building ----------

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.22, 0.2)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	add_child(Blocks.solid_box(Vector3(20, 0.2, 20), Color(0.25, 0.2, 0.16), Vector3(0, -0.1, 0)))
	add_child(Blocks.solid_box(Vector3(2.8, 0.08, 1.9), Color(0.4, 0.27, 0.16), Vector3(0, 0.76, -0.6)))
	for x in [-1.25, 1.25]:
		var candle := CylinderMesh.new()
		candle.top_radius = 0.035
		candle.bottom_radius = 0.035
		candle.height = 0.22
		add_child(Blocks.mesh(candle, Color(0.95, 0.92, 0.8), Vector3(x, 0.91, -0.9)))
		var flame := OmniLight3D.new()
		flame.light_color = Color(1.0, 0.7, 0.4)
		flame.light_energy = 0.7
		flame.omni_range = 4.0
		flame.shadow_enabled = true
		flame.position = Vector3(x, 1.1, -0.9)
		add_child(flame)
	var key := SpotLight3D.new()
	key.position = Vector3(0, 3.2, 0.6)
	key.rotation_degrees.x = -70
	key.spot_range = 6
	key.light_energy = 0.8
	add_child(key)
	enemy_fig = Blocks.figure("", Color(0.4, 0.22, 0.2))
	enemy_fig.scale = Vector3.ONE * 1.25
	enemy_fig.position = Vector3(0, 0, -2.0)
	add_child(enemy_fig)
	enemy_label = Blocks.label3d("", Vector3(0, 2.75, -2.0), 36, Color(1, 0.85, 0.8))
	add_child(enemy_label)
	hand_root = Node3D.new()
	add_child(hand_root)
	camera = Camera3D.new()
	camera.position = CAM_POS
	add_child(camera)
	camera.look_at(Vector3(0, 1.15, -0.9), Vector3.UP)
	camera.make_current()


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	log_label = _label(18, DIM)
	log_label.position = Vector2(24, 20)
	log_label.size = Vector2(380, 200)
	stats = _label(22, GOLD, false)
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.offset_left = 24
	stats.offset_top = -52
	end_button = Button.new()
	end_button.text = "End turn"
	end_button.custom_minimum_size = Vector2(180, 52)
	end_button.pressed.connect(end_turn)
	hud.add_child(end_button)
	end_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	end_button.offset_left = -204
	end_button.offset_top = -76
	end_button.offset_right = -24
	end_button.offset_bottom = -24
	result_box = VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	hud.add_child(result_box)
	result_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_box.hide()


func _label(size: int, color: Color, wrap: bool = true) -> Label:
	var l := Label.new()
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	hud.add_child(l)
	return l
