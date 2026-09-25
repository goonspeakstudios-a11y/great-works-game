extends "res://tests/test_base.gd"

const Run := preload("res://scripts/run.gd")
const Memory := preload("res://scripts/memory.gd")

const REGION := {
	"enemies": [{"name": "A"}, {"name": "B"}, {"name": "C"}],
	"boss": {"name": "Boss"},
}


func test_steps_end_in_boss_with_one_rest() -> void:
	var r := Run.new()
	r.start(REGION, ["x"])
	var types: Array = r.steps.map(func(s): return s["type"])
	check_eq(types, ["fight", "reward", "fight", "reward", "rest", "fight", "reward", "boss"], "step order")
	check_eq(r.current()["enemy"]["name"], "A", "first fight")


func test_finishes_after_last_step() -> void:
	var r := Run.new()
	r.start(REGION, [])
	for i in r.steps.size():
		check(not r.is_finished(), "not finished at step %d" % i)
		r.advance()
	check(r.is_finished(), "finished after boss")


func test_reward_options_skip_deck_and_heal_caps() -> void:
	var r := Run.new()
	r.start(REGION, ["a", "b"])
	var opts: Array = r.reward_options(["a", "b", "c", "d"], Memory.new(), 0, seeded())
	check_eq(opts.size(), 2, "only ideas not in the deck")
	check(not "a" in opts and not "b" in opts, "deck ideas excluded")
	r.hp = 45
	r.heal(100)
	check_eq(r.hp, r.max_hp, "heal caps at max")
