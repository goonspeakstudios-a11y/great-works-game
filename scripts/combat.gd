extends RefCounted
## One fight: the player's deck of idea cards against a single enemy.
## Pure rules, no UI. `power` scales a card: 1.0 normal, 0.5 after a wrong
## recall, 1.5 for a mastered (gold) idea.

const HAND_SIZE := 5
const ENERGY_PER_TURN := 3
const SCALED := ["attack", "block", "heal"]  # at least 1 even when weakened

var ideas: Dictionary
var rng: RandomNumberGenerator

var hp: int
var max_hp: int
var block := 0
var strength := 0
var energy := 0

var enemy: Dictionary = {}
var enemy_hp := 0
var enemy_block := 0
var intent_index := 0

var draw_pile: Array = []
var hand: Array = []
var discard: Array = []
var turn := 0


func start(deck: Array, foe: Dictionary, player_hp: int, player_max_hp: int, all_ideas: Dictionary, random: RandomNumberGenerator) -> void:
	ideas = all_ideas
	rng = random
	hp = player_hp
	max_hp = player_max_hp
	enemy = foe
	enemy_hp = int(foe["hp"])
	draw_pile = deck.duplicate()
	_shuffle(draw_pile)
	start_turn()


func start_turn() -> void:
	turn += 1
	block = 0
	energy = ENERGY_PER_TURN
	draw(HAND_SIZE)


func draw(n: int) -> void:
	for i in n:
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile = discard
			discard = []
			_shuffle(draw_pile)
		hand.append(draw_pile.pop_back())


func cost(id: String) -> int:
	return int(ideas[id]["cost"])


func can_play(hand_index: int) -> bool:
	return hand_index >= 0 and hand_index < hand.size() and cost(hand[hand_index]) <= energy and not is_over()


## Plays a card and returns a short log line. Call can_play first.
func play(hand_index: int, power: float) -> String:
	var id: String = hand[hand_index]
	hand.remove_at(hand_index)
	energy -= cost(id)
	var parts: Array[String] = []
	for e in ideas[id]["effects"]:
		var v := amount(e, power)
		match e["kind"]:
			"attack":
				var dealt := _hit_enemy(v + strength)
				parts.append("dealt %d" % dealt)
			"block":
				block += v
				parts.append("+%d block" % v)
			"heal":
				var before := hp
				hp = mini(hp + v, max_hp)
				parts.append("healed %d" % (hp - before))
			"draw":
				draw(v)
				parts.append("drew %d" % v)
			"strength":
				strength += v
				parts.append("+%d strength" % v)
			"energy":
				energy += v
				parts.append("+%d energy" % v)
	discard.append(id)
	return "%s: %s" % [ideas[id]["name"], ", ".join(parts) if parts else "no effect"]


static func amount(effect: Dictionary, power: float) -> int:
	var base := int(effect["value"])
	if effect["kind"] in SCALED:
		return maxi(1, roundi(base * power))
	return floori(base * power)


func current_intent() -> Dictionary:
	var intents: Array = enemy["intents"]
	return intents[intent_index % intents.size()]


## Ends the player's turn: discard the hand, the enemy acts, a new turn starts.
func end_turn() -> String:
	discard.append_array(hand)
	hand.clear()
	var line := enemy_act()
	if not is_over():
		start_turn()
	return line


func enemy_act() -> String:
	enemy_block = 0
	var intent := current_intent()
	intent_index += 1
	var v := int(intent["value"])
	if intent["kind"] == "attack":
		var absorbed := mini(block, v)
		block -= absorbed
		hp = maxi(hp - (v - absorbed), 0)
		return "%s attacks for %d (%d blocked)" % [enemy["name"], v, absorbed]
	enemy_block += v
	return "%s braces (+%d block)" % [enemy["name"], v]


func _hit_enemy(n: int) -> int:
	var absorbed := mini(enemy_block, n)
	enemy_block -= absorbed
	var dealt := n - absorbed
	enemy_hp = maxi(enemy_hp - dealt, 0)
	return dealt


func is_won() -> bool:
	return enemy_hp <= 0


func is_lost() -> bool:
	return hp <= 0


func is_over() -> bool:
	return is_won() or is_lost()


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
