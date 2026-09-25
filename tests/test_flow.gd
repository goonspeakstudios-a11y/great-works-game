extends "res://tests/test_base.gd"
## Drives the real game: walk the chapter's scenes, fight at the card table,
## answer recall prompts, and check what lands in the save file.
## The runner has no frames, so _ready is called by hand where Godot defers it.

const Save := preload("res://scripts/save.gd")
const PATH := "user://test_flow_save.json"


func _game() -> Node:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var m: Node = load("res://scenes/main.tscn").instantiate()
	m.save_path = PATH
	(Engine.get_main_loop() as SceneTree).root.add_child(m)
	if m.menu == null:
		m._ready()
	m.enter_world()
	if m.world.player == null:
		m.world._ready()
	return m


func _open_table(m: Node) -> Node3D:
	m.world.begin_step()
	if m.table and m.table.hud == null:
		m.table._ready()
	return m.table


## Plays the current scene to its end. Move beats wait on a tween, so finish them by hand.
func _play_scene(m: Node) -> void:
	var w: Node3D = m.world
	w.begin_step()
	var guard := 0
	while w.in_scene and guard < 100:
		guard += 1
		if w.busy:
			w.finish_move(w.story.scene["beats"][w.story.index])
		w.advance()
	check(not w.in_scene, "scene ended")


func _answer_open_prompt(t: Node3D, right: bool) -> void:
	for c in t.get_children():
		if c.has_method("ask") and c.waiting:
			var a: int = c.prompt["answer"]
			c.answer(a if right else (a + 1) % c.prompt["options"].size())
			c.finished.emit(right)
			c.queue_free()


func test_scenes_teach_ideas_then_fight_uses_them() -> void:
	var m := _game()
	_play_scene(m)
	check(m.save_data["met"].has("time") and m.save_data["met"].has("menis"), "quarrel teaches two ideas")
	check_eq(m.done_steps(), ["quarrel"], "quarrel recorded")
	_play_scene(m)
	check_eq(m.save_data["met"].size(), 4, "embassy teaches two more")
	check_eq(Save.load_save(PATH)["story"]["troy"], ["quarrel", "embassy"], "progress saved to disk")
	var t := _open_table(m)
	check(t != null, "fight step opens the card table")
	check(not m.world.is_inside_tree(), "world is set aside during the fight")
	check_eq(t.deck.size(), 4, "deck is the four ideas taught so far")
	m.free()


func test_table_recall_then_win_returns_to_world() -> void:
	var m := _game()
	_play_scene(m)
	_play_scene(m)
	var t := _open_table(m)
	var id: String = t.combat.hand[0]
	t.on_card(0)
	check(t.recalling, "a learned-but-unreviewed idea asks for recall")
	_answer_open_prompt(t, true)
	check_eq(m.memory.box(id), 1, "right answer moved the idea up")
	check(not t.recalling, "back to the table")
	t.combat.enemy_hp = 0
	t.render()
	t.fight_over.emit(true)
	check(m.table == null, "table closed")
	check(m.world.is_inside_tree(), "back in the world")
	check_eq(m.done_steps(), ["quarrel", "embassy", "hector"], "fight recorded")
	_play_scene(m)
	check_eq(m.done_steps().size(), 4, "chapter finished")
	check(m.world.current_step().is_empty(), "no steps left")
	m.free()


func test_wrong_recall_weakens_and_stays_due() -> void:
	var m := _game()
	_play_scene(m)
	_play_scene(m)
	var t := _open_table(m)
	var id: String = t.combat.hand[0]
	t.on_card(0)
	_answer_open_prompt(t, false)
	check_eq(m.memory.box(id), 1, "wrong answer sits in box 1")
	check(m.memory.is_due(id, t._now()), "and comes back right away")
	m.free()


func test_losing_the_fight_lets_you_retry() -> void:
	var m := _game()
	_play_scene(m)
	_play_scene(m)
	_open_table(m)
	m.table.fight_over.emit(false)
	check_eq(m.done_steps(), ["quarrel", "embassy"], "fight not recorded on a loss")
	check_eq(m.world.current_step()["id"], "hector", "fight is still next")
	m.free()


func test_priam_kneels_after_walking_in() -> void:
	var m := _game()
	for i in 3:
		if m.world.current_step()["type"] == "fight":
			m.world.fight_finished(true)
		else:
			_play_scene(m)
	_play_scene(m)
	check_eq(m.world.actors["priam"].current, "Fixing_Kneeling", "Priam ends kneeling")
	check_eq(m.world.actors["achilles"].position, Vector3(16, 0, 1), "Achilles back at his tent")
	m.free()
