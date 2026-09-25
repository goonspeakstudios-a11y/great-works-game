extends "res://tests/test_base.gd"

const Combat := preload("res://scripts/combat.gd")

const IDEAS := {
	"hit": {"id": "hit", "name": "Hit", "cost": 1, "effects": [{"kind": "attack", "value": 8}]},
	"wall": {"id": "wall", "name": "Wall", "cost": 1, "effects": [{"kind": "block", "value": 7}]},
	"rage": {"id": "rage", "name": "Rage", "cost": 1, "effects": [{"kind": "strength", "value": 2}]},
	"big": {"id": "big", "name": "Big", "cost": 3, "effects": [{"kind": "attack", "value": 30}]},
	"work": {"id": "work", "name": "Work", "cost": 0, "effects": [{"kind": "energy", "value": 1}]},
}
const FOE := {"name": "Foe", "hp": 20, "intents": [{"kind": "attack", "value": 10}, {"kind": "block", "value": 5}]}


func _fight(deck: Array) -> Combat:
	var c := Combat.new()
	c.start(deck, FOE, 40, 50, IDEAS, seeded())
	return c


func _play(c: Combat, id: String, power: float = 1.0) -> String:
	return c.play(c.hand.find(id), power)


func test_start_draws_hand_and_energy() -> void:
	var c := _fight(["hit", "hit", "wall", "wall", "rage", "work", "hit"])
	check_eq(c.hand.size(), Combat.HAND_SIZE, "hand size")
	check_eq(c.energy, Combat.ENERGY_PER_TURN, "energy")


func test_power_scales_attack_and_weak_floor() -> void:
	check_eq(Combat.amount({"kind": "attack", "value": 8}, 1.0), 8, "normal")
	check_eq(Combat.amount({"kind": "attack", "value": 8}, 0.5), 4, "weak")
	check_eq(Combat.amount({"kind": "attack", "value": 8}, 1.5), 12, "gold")
	check_eq(Combat.amount({"kind": "attack", "value": 1}, 0.5), 1, "weak attack never zero")
	check_eq(Combat.amount({"kind": "energy", "value": 1}, 0.5), 0, "weak energy can be zero")


func test_strength_adds_to_attacks() -> void:
	var c := _fight(["hit", "rage", "wall", "wall", "wall"])
	_play(c, "rage")
	_play(c, "hit")
	check_eq(c.enemy_hp, 20 - 10, "8 + 2 strength")


func test_block_absorbs_enemy_attack() -> void:
	var c := _fight(["wall", "wall", "wall", "wall", "wall"])
	_play(c, "wall")
	c.end_turn()
	check_eq(c.hp, 40 - 3, "10 attack minus 7 block")


func test_enemy_block_absorbs_player_attack() -> void:
	var c := _fight(["hit", "hit", "hit", "hit", "hit", "hit", "hit", "hit", "hit", "hit"])
	c.end_turn()        # enemy attacks
	c.end_turn()        # enemy braces for 5
	_play(c, "hit")
	check_eq(c.enemy_hp, 20 - 3, "8 attack minus 5 enemy block")


func test_cannot_play_without_energy() -> void:
	var c := _fight(["big", "big", "hit", "hit", "hit"])
	var i: int = c.hand.find("hit")
	c.play(i, 1.0)
	check(not c.can_play(c.hand.find("big")), "3-cost card with 2 energy")


func test_discard_reshuffles_when_draw_pile_empty() -> void:
	var c := _fight(["hit", "wall", "rage"])
	check_eq(c.hand.size(), 3, "small deck draws all")
	c.end_turn()
	check_eq(c.hand.size(), 3, "hand refilled from discard")


func test_win_and_loss() -> void:
	var c := _fight(["big", "big", "big", "big", "big"])
	_play(c, "big")
	check(c.is_won(), "30 damage beats 20 hp")
	check(not c.can_play(0), "no plays after the fight ends")
	var d := _fight(["work", "work", "work", "work", "work"])
	for t in 4:
		d.end_turn()
		d.end_turn()
	check(d.is_lost(), "no defense loses eventually")
