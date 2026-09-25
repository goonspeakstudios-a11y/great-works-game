extends "res://tests/test_base.gd"
## Drives the real game screen: start a run, play a card, answer its recall prompt.

const PATH := "user://test_flow_save.json"


func _game() -> Control:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var m: Control = load("res://scenes/main.tscn").instantiate()
	m.save_path = PATH
	(Engine.get_main_loop() as SceneTree).root.add_child(m)
	if m.screen == null:  # the runner has no frames, so _ready can be deferred
		m._ready()
	m.start_run()
	m.next_step()
	return m


func _play_first_card(m: Control, answer_right: bool) -> String:
	var i := -1
	for n in m.combat.hand.size():
		if m.combat.can_play(n):
			i = n
			break
	var id: String = m.combat.hand[i]
	m._on_card(i)
	check(m.overlay != null, "a new idea asks for recall")
	var right: int = m.prompt["answer"]
	m._answer(right if answer_right else (right + 1) % m.prompt["options"].size())
	var box: Node = m.overlay.get_child(0)
	var play_button: Button = box.get_child(box.get_child_count() - 1)
	play_button.pressed.emit()
	return id


func test_right_answer_plays_card_and_saves_memory() -> void:
	var m := _game()
	check_eq(m.run.current()["type"], "fight", "run opens with a fight")
	var id := _play_first_card(m, true)
	check(id in m.combat.discard, "played card went to the discard pile")
	check_eq(m.memory.box(id), 1, "idea moved up a box")
	check_eq(m.run_right, 1, "right answer counted")
	var saved: Dictionary = preload("res://scripts/save.gd").load_save(PATH)
	check(saved["memory"].has(id), "memory written to the save file")
	m.free()


func test_wrong_answer_counts_miss_and_stays_due() -> void:
	var m := _game()
	var id := _play_first_card(m, false)
	check_eq(m.run_wrong, 1, "miss counted")
	check(m.memory.is_due(id, m._now()), "missed idea is due again")
	m.free()
