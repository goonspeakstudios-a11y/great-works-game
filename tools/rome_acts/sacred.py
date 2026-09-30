"""Rites done exactly (religio): the lararium in your house every morning, the augurs on the Arx, the
haruspex's liver, the curse tablet at the fountain, and small offerings at any temple still standing
(docs/rome-activities-plan.md, 3.5). Also sleeping in your house.
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, typing, pick, gain, pay, iff, scene,
                     hour)

S = {}

_LAR = ["Wash your hands", "Lay a garland on the shrine", "Drop salted meal into the lamp's flame", "Pour a drop of wine",
        "Say: be kind to this house"]
_LAR_WRONG = ["Spit on the hearth", "Say: give me money", "Turn your back on the shrine"]

S["lararium_heroic"] = scene(
    "The household gods", "Your house, 280 BC",
    say("A niche by the hearth: the Lar of the family, dancing with his drinking horn; the Penates who keep the store cupboard; the snake of the house's Genius painted below."),
    rite("Every morning, before anything else, the small rite.", _LAR, _LAR_WRONG,
         restart="You stop, and begin again. Postumia is watching from the loom, and says the words with you.",
         done="The flame takes the meal with a small crackle. The house is kept."),
    gain(once="lararium"),
    end("It is small and it is daily, and it ties this house to every Roman house since the kings."),
)

S["lararium_early"] = scene(
    "The household gods", "Your house, 201 BC",
    say("Every house in Rome prayed harder after Cannae. Sulpicia lost two brothers there. She stands behind you and makes sure you do it exactly."),
    rite("The morning rite.", _LAR, _LAR_WRONG, restart="You begin again. It must be right.",
         done="The Lar dances in the lamplight. The house is kept."),
    gain(once="lararium"),
    end("Duty to the gods, to the family, to Rome: it is one duty, begun here, at the hearth."),
)

S["lararium_republic"] = scene(
    "The household gods", "Your house, about 50 BC",
    say("The shrine is painted now, like everything Valeria paid for. She doesn't come to it. The boy's nurse does, for luck."),
    rite("The morning rite.", _LAR, _LAR_WRONG, strict=False, slack="You slip, and go on anyway. Who's to know?",
         done="The flame takes the meal. From Valeria's room, laughter."),
    gain(once="lararium"),
    end("Valeria's Egyptian has his own gods. She keeps them in her bedroom."),
)

S["lararium_empire"] = scene(
    "The household gods", "Your house, about AD 150",
    say("Beside the Lares Flavia has put a silver bust of the Emperor. Everyone has one. It seems wise."),
    rite("The morning rite.", _LAR, _LAR_WRONG, strict=False, slack="You slip and go on.",
         done="The flame takes the meal. The Emperor's bust looks on."),
    gain(once="lararium"),
    end("Flavia has not come to the household gods in years. The slaves do, for luck, when she isn't looking."),
)

S["lararium_late"] = scene(
    "The household gods", "Your house, AD 384",
    say("The Emperor's laws are against sacrifice. They don't yet name the little household gods; in a few years they will, down to a pinch of incense in a shrine."),
    say("Rufina is a Christian, and pays the bishop. She has seen your shrine."),
    ask("She says nothing. She looks at the Lar, and at you.",
        opt("Keep it, and do the rite", then="rite"),
        opt("Put it away in the chest", say="You wrap the Lar in a cloth and put him away. The niche is empty.",
            ledger="Put away the household gods.", ledger_key="lararium_put_away", then="end"),
    ),
    label("rite"),
    rite("The morning rite, quietly.", _LAR, _LAR_WRONG, restart="You begin again, more quietly.",
         done="The flame takes the meal. Rufina has shut her door."),
    gain(once="lararium", ledger="Kept the household gods when your wife turned away.", ledger_key="lararium_kept"),
    label("end"),
    end("Everything is changing in Rome. Some things you choose to keep."),
)

S["lararium_collapse"] = scene(
    "The household gods", "Your house, AD 455",
    iff({"done": "lar_sold"}, "sold"),
    say("The Lar is behind a curtain. The Vandals didn't want him: bronze too little to bother with."),
    rite("The morning rite, behind the curtain.", _LAR, _LAR_WRONG, strict=False,
         slack="You slip, and go on. There's no one left to be exact for.", done="The flame takes the meal."),
    gain(once="lararium"),
    end("The house is half empty. Nobody has come to mend the door. Nobody will."),
    label("sold"),
    say("The niche is empty. Galla sold him with the candlesticks."),
    end("You leave a pinch of meal in the empty niche anyway."),
)

S["lararium_fall"] = scene(
    "The household gods", "What is left of your house, AD 552",
    iff({"done": "lar_sold"}, "sold"),
    say("The roof fell in the second siege. The niche is still there, and the painted snake, and the Lar in his cloth at the bottom of the chest."),
    hold("Set him in the niche and pour the last of the water for him.", secs=3.0, done="He dances, as he always did, in the rubble."),
    gain(once="lararium", ledger="Kept the household gods in the ruined city.", ledger_key="lararium_last"),
    end("A thousand years of mornings, and this one."),
    label("sold"),
    say("The niche is there, and the painted snake. The Lar is not: your wife sold him a hundred years ago, in another life."),
    still("Stand before the empty niche.", secs=5, done="There is nothing to keep."),
    end("A thousand years of mornings, and none left."),
)

_SLEEP = {"heroic": "You sleep on a straw mattress. At first light the cocks crow all over the seven hills.",
          "early": "You sleep. At first light the carts are already on the Sacred Way.",
          "republic": "You sleep, as much as anyone sleeps in the Subura: the drunks, the dogs, a fight on the stairs.",
          "empire": "You sleep, badly. Carts are only allowed in the city at night, and they are all under your window.",
          "late": "You sleep. Before dawn you hear the psalms from the church at the end of the street.",
          "collapse": "You sleep with a knife under the mattress, like everyone.",
          "fall": "You sleep in the corner where the roof still holds. Owls in the Forum."}
for age, line in _SLEEP.items():
    S["sleep_" + age] = scene("Sleep", "Your house", say(line), hour(6.0), end("Morning."))

# ---------- the augurs ----------

_AUGURY = [
    pick("You stand in the augurs' place on the Arx, facing south. An eagle crosses from your left, from the east. For a Roman augur, is that a good sign?",
         ["Yes: for Romans the left is the lucky side", "No: the left is always unlucky", "Birds mean nothing"], 0,
         yes="Yes. The Greeks face north and call the right lucky; the Romans face south, and it's the left.",
         no="A Roman augur faces south, and the left, the east, is the lucky side."),
    pick("A raven calls on your right, and a crow on your left. What is that?",
         ["Favourable: raven right, crow left", "Unfavourable", "Nothing: only eagles count"], 0,
         yes="Favourable. The augurs' books say so.", no="The books say: a raven on the right and a crow on the left is favourable."),
]

S["augury_heroic"] = scene(
    "The augurs", "The Arx, 280 BC",
    say("Nothing public is done in Rome without the auspices: no vote, no battle, no law. The augur marks out a square of sky with his curved staff."),
    *_AUGURY,
    iff({"score": 2}, "right"),
    end("The augur tells the consul the gods allow it. He was watching you. You'll learn."),
    label("right"),
    gain(dignitas=1),
    end("The augur nods at you. The consul may go ahead. The gods and Rome agree."),
)
S["augury_early"] = scene("The augurs", "The Arx, 201 BC",
                          say("The consul waits for the sign before he marches for Macedonia. In this war the gods are listened to."),
                          *_AUGURY, iff({"score": 2}, "right"), end("The augur takes the sign. The legions march."),
                          label("right"), gain(dignitas=1), end("The augur takes the sign, and nods at you. The legions march."))
S["augury_republic"] = scene(
    "The augurs", "The Arx, about 50 BC",
    say("A consul who wants to stop an assembly announces he is watching the sky for signs. Then no vote may be held. Bibulus stopped Caesar that way for a year, sitting at home."),
    *_AUGURY,
    ask("A tribune's man asks you to report thunder on the left: it will stop tomorrow's vote.",
        opt("Report it", coin=4, fides=-2, say="You report thunder. There was none. The vote is stopped.",
            ledger="Reported a false omen to stop a vote.", ledger_key="false_omen"),
        opt("Refuse", fides=1, say="He finds someone else."),
    ),
    end("The auspices still decide everything. That's why everyone lies about them."),
)
S["augury_empire"] = scene("The augurs", "The Arx, about AD 150",
                           say("The augurs are still appointed: noble young men, and the Emperor is one. It's an honour, like a seat at the games."),
                           *_AUGURY, end("The augur has a dinner to go to. He thanks you for your company."))

# ---------- the haruspex ----------

_LIVER = [
    pick("The haruspex holds up a sheep's liver. The bronze liver of Piacenza shows its regions, each a god's. The lobe called the head is missing. What does that mean?",
         ["Disaster: a liver without its head", "Good fortune", "A long journey"], 0,
         yes="Disaster. Before Marcellus died in ambush, his victim's liver had no head.",
         no="A liver without its head means disaster: Marcellus's had none the day before he died."),
    pick("The gall bladder is swollen on the enemy's side. What does he tell the general?",
         ["Good: harm to the enemy", "Bad: harm to us", "Nothing"], 0,
         yes="Harm on the enemy's side is harm to the enemy.", no="The enemy's side: harm to the enemy. Good."),
]

S["haruspicy"] = scene(
    "The haruspex", "By the temple",
    say("The haruspex is an Etruscan, as they always are. The Senate sends for his order when there are prodigies: a calf with two heads, a statue sweating blood."),
    *_LIVER,
    iff({"score": 2}, "right"),
    end("\"Stick to your trade,\" the haruspex says. \"Leave the gods' livers to us.\""),
    label("right"),
    end("The haruspex looks at you with more respect. \"Your grandmother was from Tarquinii?\" he asks."),
)
S["haruspicy_late"] = scene(
    "The haruspex", "By the temple, AD 384",
    say("The haruspex is not allowed into private houses: Constantine's law. He may read livers only in public, at the temples, for the state. Few ask him now."),
    *_LIVER,
    end("He wraps the liver in a cloth. \"My father had the Senate's ear,\" he says. \"I have this.\""),
)

# ---------- the curse tablet ----------

S["curse_tablet"] = scene(
    "The curse tablet", "At the fountain",
    say("A woman stops you. A man cheated her of her savings and she can't write. She has a sheet of lead and a nail."),
    ask("\"Write it for me,\" she says. \"Name him to the gods below. Then we fold it and nail it, and drop it in the water.\"",
        opt("Write it", then="write"),
        opt("Refuse", say="\"Then I'll find someone who can,\" she says.", then="end"),
    ),
    label("write"),
    typing("I bind Gaius Vettius, his hands, his tongue, his sleep, to the gods below.", secs=45,
           good="The letters are clear. The gods will read them.", fair="Clear enough for the gods.",
           bad="Scratchy. She says the gods can read a scratch, if it's meant."),
    hold("Fold the lead, and drive the nail through it.", secs=2.5, done="She drops it into the fountain. It sinks at once."),
    gain(ledger="Wrote a curse tablet and dropped it in a fountain.", ledger_key="curse"),
    label("end"),
    end("There are thousands of them in the wells and fountains of Rome. The gods below must be very busy."),
)

# ---------- an offering at a temple ----------

S["offering"] = scene(
    "An offering", "{temple}",
    say("The keeper of {temple} sells small offerings at the steps: incense, a cake, a clay figure of a body part to be healed."),
    ask("What do you offer to {god}?",
        opt("A pinch of incense", pay=1, say="The smoke goes up past the columns.", need={"price": 1}, then="done"),
        opt("A honey cake", pay=1, say="You lay it on the altar. A priest will eat it later.", need={"price": 1}, then="done"),
        opt("A vow: something if your wish is granted", say="You say it quietly. The keeper nods: a vow is a contract.",
            ledger="Made a vow at a temple.", ledger_key="vow", then="done"),
        opt("Nothing", then="end"),
    ),
    label("done"),
    gain(fides=0, once="offering"),
    label("end"),
    end("{god} has been here longer than anyone's grandfather's grandfather. The steps are worn by knees."),
)

SCENES = S
