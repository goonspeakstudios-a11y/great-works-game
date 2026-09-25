extends RefCounted
## One run through a region: fights, rewards, a rest, then the boss.
## Holds what carries between steps (deck and hit points).

const START_HP := 50
const START_DECK := 8
const REWARD_CHOICES := 3
const REST_HEAL := 15
const NO_REWARD_HEAL := 8

var region: Dictionary
var steps: Array = []  # {type: fight|reward|rest|boss, enemy?}
var index := 0
var deck: Array = []
var hp := START_HP
var max_hp := START_HP


func start(region_data: Dictionary, starting_deck: Array) -> void:
	region = region_data
	deck = starting_deck.duplicate()
	hp = START_HP
	max_hp = START_HP
	index = 0
	steps.clear()
	var enemies: Array = region["enemies"]
	for i in enemies.size():
		steps.append({"type": "fight", "enemy": enemies[i]})
		steps.append({"type": "reward"})
		if i == enemies.size() - 2:
			steps.append({"type": "rest"})
	steps.append({"type": "boss", "enemy": region["boss"]})


func current() -> Dictionary:
	return steps[index] if index < steps.size() else {}


func advance() -> void:
	index += 1


func is_finished() -> bool:
	return index >= steps.size()


## Ideas the player could add: not already in the deck, most in need of review first.
func reward_options(all_ids: Array, memory, now: int, rng: RandomNumberGenerator) -> Array:
	var fresh: Array = all_ids.filter(func(id): return not id in deck)
	return memory.pick(fresh, REWARD_CHOICES, now, rng)


func add_card(id: String) -> void:
	if not id in deck:
		deck.append(id)


func heal(n: int) -> void:
	hp = mini(hp + n, max_hp)
