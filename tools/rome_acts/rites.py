"""The recurring rites of Rome: the same rite played in every age, its rules the same, what people
do with them decaying (docs/rome-activities-plan.md, section 2). Each rite has a place and a time in
each age (RITES) and a scene for each age (SCENES, ids "<rite>_<age>").

Money is written as in 280 BC (Standing.price and .wage turn it into each age's coin).
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, pick, gain, pay, wage, iff, play,
                     scene, hour)

# Where and when: at (a map position [east, north] of the Forum, metres), from/to (hours), every
# (days) and offset. "festival": held only on that festival's day (town.json).
RITES = {
    "vote": {"name": "The vote", "every": 5, "offset": 1, "from": 7.0, "to": 14.0, "ages": {
        "heroic": {"at": [-600, 520], "text": "Go down to the Campus with your century to vote"},
        "early": {"at": [-600, 520], "text": "Go down to the Campus: the centuries vote on war with Macedon"},
        "republic": {"at": [-600, 520], "text": "Go down to the voting pens on the Campus"},
        "empire": {"at": [-570, 520], "text": "Go into the Saepta for the elections"},
        "late": {"at": [30, 60], "text": "Call at the Prefect's office"},
        "collapse": {"at": [-45, 30], "text": "Hear the proclamation at the Rostra"},
        "fall": {"at": [10, 70], "text": "Look for the vote"},
    }},
    "games": {"name": "The games", "every": 4, "offset": 2, "from": 12.0, "to": 18.0, "ages": {
        "heroic": {"at": [-760, 430], "text": "Watch the horse races for Mars on the Campus"},
        "early": {"at": [41, -560], "text": "Go to the Roman Games"},
        "republic": {"at": [10, -10], "text": "Go to the candidate's gladiators in the Forum"},
        "empire": {"at": [560, -130], "text": "Spend the day at the Flavian Amphitheatre"},
        "late": {"at": [560, -130], "text": "Go to the amphitheatre with your friends"},
        "collapse": {"at": [41, -560], "text": "Go to the races in the Circus"},
        "fall": {"at": [41, -560], "text": "Walk into the Circus Maximus"},
    }},
    "funeral": {"name": "The funeral", "every": 3, "offset": 0, "from": 9.0, "to": 13.0, "ages": {
        "heroic": {"at": [980, 420], "text": "Go to a soldier's pyre on the Esquiline"},
        "early": {"at": [-45, 12], "text": "Join a great man's funeral at the Rostra"},
        "republic": {"at": [-30, 60], "text": "Follow Clodius's mourners into the Forum"},
        "empire": {"at": [470, -880], "text": "Walk in a rich freedman's funeral on the Appian Way"},
        "late": {"at": [470, -880], "text": "Go down to the catacombs on the Appian Way"},
        "collapse": {"at": [980, 420], "text": "Help at the burial pits on the Esquiline"},
        "fall": {"at": [-760, 400], "text": "Help the corpse bearers by the river"},
    }},
    "levy": {"name": "The levy", "every": 6, "offset": 3, "from": 7.0, "to": 12.0, "ages": {
        "heroic": {"at": [-170, 60], "text": "Answer the levy on the Capitol"},
        "early": {"at": [-170, 60], "text": "Answer the levy on the Capitol"},
        "republic": {"at": [40, 10], "text": "Hear the recruiter in the Forum"},
        "empire": {"at": [-700, 420], "text": "Go to the recruiting officer on the Campus"},
        "late": {"at": [40, 25], "text": "Hear the recruit tax cried in the Forum"},
        "collapse": {"at": [140, -330], "text": "Go up to the palace gate"},
        "fall": {"at": [-850, 500], "text": "Watch the garrison changing"},
    }},
    "court": {"name": "The court", "every": 2, "offset": 1, "from": 9.0, "to": 13.0, "ages": {
        "heroic": {"at": [-40, 50], "text": "Go to the consul's judgement in the Comitium"},
        "early": {"at": [-40, 50], "text": "Go to the praetor's tribunal"},
        "republic": {"at": [45, 40], "text": "Go to the trial by the Basilica Aemilia"},
        "empire": {"at": [10, 70], "text": "Go to the treason hearing"},
        "late": {"at": [60, 20], "text": "Go to the Prefect's court"},
        "collapse": {"at": [700, 100], "text": "Go to the bishop's hearing at the church of the Chains"},
        "fall": {"at": [700, 100], "text": "Go to the deacon's hearing"},
    }},
    "bread": {"name": "The bread", "every": 2, "offset": 0, "from": 6.5, "to": 11.0, "ages": {
        "heroic": {"room": True, "text": "Grind your grain and bake your bread"},
        "early": {"at": [-330, -330], "text": "Buy the aediles' cheap grain in the cattle market"},
        "republic": {"at": [-540, 150], "text": "Go to the grain dole"},
        "empire": {"at": [-560, 200], "text": "Queue for the grain at the Portico of Minucius"},
        "late": {"at": [15, 5], "text": "Take your bread from the steps"},
        "collapse": {"at": [-330, -330], "text": "Go to the granaries in the cattle market"},
        "fall": {"at": [60, -95], "text": "Queue for the Church's bread"},
    }},
    "sacrifice": {"name": "The sacrifice", "every": 1, "offset": 0, "from": 7.0, "to": 12.0, "ages": {
        "heroic": {"at": [-190, 60], "text": "Offer the sacrifice to Jupiter on the Capitol"},
        "early": {"at": [-190, 60], "text": "Offer the sacrifice to Jupiter on the Capitol"},
        "republic": {"at": [-190, 60], "text": "Attend the sacrifice to Jupiter on the Capitol"},
        "empire": {"at": [133, 12], "text": "Offer incense at the Temple of Antoninus and Faustina"},
        "late": {"at": [650, 780], "text": "Knock at the old senator's house on the Quirinal"},
        "collapse": {"at": [700, 100], "text": "Go to the church of the Chains"},
        "fall": {"at": [-76, 30], "text": "Go to the Temple of Saturn"},
    }},
    "triumph": {"name": "The triumph", "every": 8, "offset": 5, "from": 10.0, "to": 15.0, "ages": {
        "heroic": {"at": [60, -15], "text": "Watch the triumph go up the Sacred Way"},
        "early": {"at": [60, -15], "text": "Watch Scipio's triumph go up the Sacred Way"},
        "republic": {"at": [-560, 420], "text": "Go out to the general waiting on the Campus"},
        "empire": {"at": [60, -15], "text": "Hear the victory cried on the Sacred Way"},
        "late": {"at": [-20, 290], "text": "Walk through Trajan's Forum"},
        "collapse": {"at": [-400, -280], "text": "Go down to the river where the Vandals are loading"},
        "fall": {"at": [60, -15], "text": "Stand on the Sacred Way"},
    }},
    "saturnalia": {"name": "The Saturnalia", "festival": "the Saturnalia", "from": 8.0, "to": 23.0, "ages": {
        "heroic": {"at": [-60, 45], "text": "Keep the Saturnalia at the Temple of Saturn"},
        "early": {"at": [-60, 45], "text": "Keep the Saturnalia at the Temple of Saturn"},
        "republic": {"at": [-60, 45], "text": "Keep the Saturnalia"},
        "empire": {"at": [-60, 45], "text": "Keep the Saturnalia"},
        "late": {"at": [600, 900], "text": "Go to the Saturnalia dinner at Praetextatus's house"},
        "collapse": {"at": [-60, 45], "text": "Go to the Saturnalia in the Forum"},
        "fall": {"at": [-60, 45], "text": "Ask about the Saturnalia"},
    }},
    "salutatio": {"name": "The morning call", "every": 1, "offset": 0, "from": 5.5, "to": 9.5, "ages": {
        "heroic": {"at": [120, -330], "text": "Call on your patron at dawn"},
        "early": {"at": [120, -330], "text": "Call on your patron at dawn"},
        "republic": {"at": [120, -330], "text": "Join the clients at your patron's door"},
        "empire": {"at": [900, 330], "text": "Run the morning round of the great houses"},
        "late": {"at": [900, -480], "text": "Wait at the great house on the Caelian"},
        "collapse": {"at": [900, -480], "text": "Go to your patron's house on the Caelian"},
        "fall": {"at": [900, -480], "text": "Go to where your patron's house was"},
    }},
}

S = {}

# ---------- the vote ----------

S["vote_heroic"] = scene(
    "The vote", "The Campus Martius, 280 BC",
    say("A red flag flies on the Janiculum while the people are on the Campus: if it comes down, an enemy is near. Today it flies. The centuries gather by the river."),
    say("The candidates walk among you in whitened togas, no tunic underneath, so you can see their scars. Publius Decius Mus shows you his. His father and his grandfather died for the legions."),
    say("There are no voting tablets. When your century is called, each man gives his vote aloud to the teller at the gangway, before his neighbours."),
    ask("The teller looks at you. Whose names do you give?",
        opt("Decius Mus, and Sulpicius Saverrio", say="The teller marks two dots by their names. The man behind you nods.", dignitas=1),
        opt("Decius, and a man of your own tribe", say="The teller marks it. Your tribe's man will not win, but your neighbours saw you name him.", dignitas=1),
        opt("Ask the man behind you who to name", say="He tells you, loud enough for everyone. You give his names. Nobody minds: you are new to Rome."),
    ),
    say("By midday the first centuries have voted, and then the next. Nobody has been paid. A farmer shouts his vote like a war cry and the Campus laughs."),
    end("Decius Mus is elected consul for the coming year, against Pyrrhus. Men say he will do what his father did at Sentinum, and his grandfather at Veseris. They say it proudly."),
)

S["vote_early"] = scene(
    "The vote on war", "The Campus Martius, 200 BC",
    say("Hannibal is beaten. Now the consul asks the centuries to declare war on King Philip of Macedon, who helped him."),
    say("The centuries vote by their census class, the knights and the first class first. You vote where the censors put you."),
    iff({"class": 1}, "votes"),
    say("You are counted by head: all the men with no property vote in a single century, the last to be called."),
    say("The first class votes. Then the second. The matter is settled before the fifth class is called. Your century is not called at all."),
    go("result"),
    label("votes"),
    ask("Your century is called. The men around you have buried sons from Cannae to Zama. Many of them are weary of war. How do you vote?",
        opt("For war: Philip helped Hannibal", say="You say it aloud: \"Uti rogas\", as you ask.", ledger="Voted for war with Macedon when the tired centuries voted against it.", ledger_key="vote_macedon"),
        opt("Against war: Italy has bled enough", say="You say \"Antiquo\": I keep things as they were. Many say it with you."),
    ),
    label("result"),
    say("The centuries vote NO. Almost all of them. After sixteen years of Hannibal, the people will not have another war."),
    say("The Senate does not accept it. The consul Sulpicius calls the people together and speaks: if we do not go to Macedonia, Macedonia will come to Italy, as Hannibal came."),
    say("The centuries vote again. This time they vote for war. The Senate thanks them. Nobody is paid to change his vote. They change it for Rome."),
    end("War is declared on Macedon. The men who voted no are enrolled for it all the same, and they go."),
)

S["vote_republic"] = scene(
    "The consular elections", "The voting pens on the Campus, about 50 BC",
    say("The elections for next year's consuls. Caesar's man, Servius Galba, stands against Lentulus Crus, the Senate's. Caesar's friends are canvassing every tribe for Galba."),
    say("On the way to the Campus a man falls into step beside you, friendly. He is a divisor, a candidate's paymaster. He knows your tribe."),
    ask("\"Lentulus remembers his friends,\" he says, and shows you a purse. \"All he asks is your tablet.\"",
        opt("Take the money", say="He counts it into your hand, and writes your name down. Now he knows your name.", coin=8, fides=-1,
            ledger="Sold your vote in the consular elections.", ledger_key="sold_vote"),
        opt("Refuse him", say="He shrugs. There are thirty thousand others."),
        opt("Take it, and vote as you like", say="He smiles as he pays you. He has done this before. He knows how many of you do that.", coin=8, fides=-2,
            ledger="Took a candidate's money and voted against him.", ledger_key="sold_vote"),
    ),
    say("At the pens there are men with clubs by the gangways, hired by one side or the other. Since Clodius and Milo, every faction has its gang. A tribune has seen bad omens and wants the voting stopped."),
    ask("The crowd pushes. A club comes down on someone ahead of you.",
        opt("Push through to the gangway", then="through"),
        opt("Go home", say="You go home. The voting goes on without you, or doesn't.", then="home"),
    ),
    label("through"),
    timing("Get through the crush to the gangway before it closes.", hits=2, speed=1.2, zone=0.22,
           miss="An elbow in your ribs. You lose your place.", done="You reach the gangway."),
    ask("You are given a wax tablet. Write the name.",
        opt("Galba", say="You write GALBA and drop it in the basket."),
        opt("Lentulus", say="You write LENTULUS and drop it in the basket."),
        opt("Leave it blank", say="You drop it in blank. It is the only honest thing in the basket."),
    ),
    label("home"),
    end("Lentulus is elected. Galba, who was popular, loses; they say the Senate's money beat Caesar's. In a year Lentulus will be consul when Caesar crosses the Rubicon."),
)

S["vote_empire"] = scene(
    "The elections", "The Saepta Julia, about AD 150",
    say("The Saepta were built for voting. Now the colonnades are full of shops: slaves, gold, Corinthian bronzes. The elections are held in one corner."),
    say("The Senate chose the magistrates weeks ago, from the Emperor's list. Today the people are only told. A herald reads the names."),
    ask("After each name the crowd shouts on cue: \"Feliciter!\" Good luck! A man near you is watching who shouts.",
        opt("Shout with them", say="\"Feliciter!\" Your voice is lost in thousands. The man looks away, satisfied."),
        opt("Keep silent", say="You say nothing. The man looks at you a moment longer than he should.",
            ledger="Kept silent when the crowd acclaimed the Emperor's magistrates.", ledger_key="silent_acclaim"),
    ),
    say("It is over in an hour. The crowd goes back to the shops."),
    end("The consuls are men the Emperor chose, as the Emperor's grandfather's consuls were. No one has voted in Rome for a hundred and thirty years, and no one misses it."),
)

S["vote_late"] = scene(
    "An office for sale", "The Prefect's office, AD 384",
    say("There are no elections. There are offices, and they are bought: from the palace, from the Prefect's staff, from the men who can put your name before them."),
    say("A clerk of the Prefect's office takes you aside. A place is open among the clerks. It comes with a salary, freedom from certain taxes, and the fees people pay to have their papers moved."),
    ask("\"The price is the price,\" he says. \"Everyone pays it. Then everyone pays you.\"",
        opt("Buy the post", pay=20, dignitas=3, say="You pay. He writes your name. In a month the fees will have paid you back, from people poorer than you.",
            ledger="Bought a clerk's post in the Prefect's office.", ledger_key="bought_office", need={"price": 20}),
        opt("Say you'll think about it", say="He smiles. \"Of course.\" He knows you can't afford it."),
        opt("Tell him it's corrupt", say="He looks at you as if you had said the sky was up. \"It's the law,\" he says, and it very nearly is.", fides=1),
    ),
    end("Outside, a man with a petition has waited in the rain since dawn. His papers will move when he pays."),
)

S["vote_collapse"] = scene(
    "The new Emperor", "The Rostra, AD 455",
    say("A herald on the Rostra reads a letter. There is a new Emperor: Avitus, a Gaul, proclaimed at Arles by his friends and the King of the Goths. The Senate has agreed."),
    say("The last Emperor, Maximus, reigned less than three months. When the Vandals came he fled, and the crowd stoned him in the street and threw him in the Tiber. The Vandals spent fourteen days taking what they liked."),
    ask("The herald stops. The soldiers at the steps look at the crowd. It is time to cheer.",
        opt("Cheer", say="You cheer. Some cheer. Some laugh. A man is taking bets on how long this one lasts."),
        opt("Bet on how long he lasts", pay=2, then="bet", need={"price": 2}),
        opt("Walk away", say="You walk away. Nobody stops you. Nobody much is watching."),
    ),
    go("done"),
    label("bet"),
    say("\"Under a year,\" you say. The bookmaker writes it on a tablet. \"Everyone says under a year,\" he complains. \"Say something interesting.\""),
    gain(say="A year from now Avitus will be deposed and made a bishop. You will have won.", coin=4,
         ledger="Bet on how long the Emperor would last.", ledger_key="bet_emperor"),
    label("done"),
    end("The Senate will go on meeting. The Emperor will stay in Gaul, among the Goths, until they want another one."),
)

S["vote_fall"] = scene(
    "No vote", "The Senate House, AD 552",
    say("The doors of the Senate House are shut. There are few senators left: the Goths killed the ones they caught in Campania, and King Teias killed the three hundred noble children they held as hostages."),
    say("An old man sits on the steps. He was a senator's clerk, once."),
    ask("\"You're looking for the elections?\" he says. \"There's nothing to vote on. Narses sends orders from Ravenna. The Emperor is in Constantinople. We sign.\"",
        opt("Ask where the voting pens were", say="\"On the Campus. The Saepta. There are fishermen's huts in it now.\""),
        opt("Ask what the Senate does", say="\"It keeps its name. That's all a name needs.\""),
    ),
    end("There will be no Senate at all in fifty years. Nobody will notice the day it stops."),
)

# ---------- the games ----------

S["games_heroic"] = scene(
    "The Equirria", "The Campus Martius, 280 BC",
    say("The horse races for Mars, on the open grass of the Campus by the river. No stands: the farmers stand in the grass, the boys up in the trees."),
    say("A farmer beside you bets a ham on the grey pair. He looks at you. \"You want the bay? I'll take your as on it.\""),
    play("race", win="won", lose="lost", say="The pairs line up at a rope.", bet=True, stake=1, laps=3),
    label("won"),
    end("The farmer gives you your winnings and a slap on the back. \"Mars likes you. Come and fight the King with us.\""),
    label("lost"),
    end("\"Mars didn't like your horses,\" the farmer says, not unkindly. He shares his ham with you anyway."),
)

S["games_early"] = scene(
    "The Roman Games", "The Circus Maximus, 201 BC",
    say("A wooden stage in front of the Circus for a comedy by Plautus. There are no seats: everyone stands, senators among farmers. In a few years the senators will take the front for themselves."),
    say("On stage the braggart soldier boasts of the thousands he has killed. His hanger-on flatters him, and keeps a running count."),
    pick("The hanger-on turns to the crowd for the line that gets the laugh. What is it?",
         ["\"And the elephant in India: you broke its leg with your fist!\"", "\"You are a very brave man.\"", "\"Please, master, do not beat me.\""], 0,
         yes="The crowd roars. Everyone there has seen real elephants now: Pyrrhus's, Hannibal's.",
         no="No: \"And the elephant in India: you broke its leg with your fist!\" The crowd roars."),
    say("Then the chariots. Four teams, seven laps."),
    play("race", win="won", lose="lost", bet=True, stake=1, laps=5),
    label("won"),
    end("You won. The man beside you lost at Cannae and has one arm. He laughs with you as if he'd won himself."),
    label("lost"),
    end("You lost. The man beside you shrugs. \"We came back from Cannae,\" he says. \"You'll come back from this.\""),
)

S["games_republic"] = scene(
    "A candidate's games", "The Forum, about 50 BC",
    say("A man standing for office gives games in his dead father's honour: twenty pairs of gladiators, in wooden stands in the Forum. His father has been dead nine years. The election is next month."),
    ask("At the entrance his freedmen hand out bread, and seats go to men who will vote for him.",
        opt("Take the bread and a seat", say="You eat his bread in his seat. His freedman writes down your tribe.", fides=-1,
            ledger="Took a candidate's bread and a seat at his games.", ledger_key="candidate_bread"),
        opt("Stand at the back", say="You stand at the back with the slaves and the foreigners. You see as well."),
    ),
    say("A Thracian and a Gaul fight until the Thracian falls, and lifts a finger for mercy. The giver of the games looks at the crowd."),
    ask("The crowd shouts. \"Mitte!\" Let him go. \"Iugula!\" Cut his throat.",
        opt("\"Mitte!\"", say="He fought well. The crowd agrees, this time. He is let go."),
        opt("\"Iugula!\"", say="You shout it with the others. The Gaul does it quickly, as he was trained.",
            ledger="Shouted for the kill at the games.", ledger_key="shouted_kill"),
        opt("Say nothing", say="You say nothing. The decision is made without you."),
    ),
    end("The candidate will win. The games cost him more than the office pays, and he will make it back in a province."),
)

S["games_empire"] = scene(
    "A day at the Flavian Amphitheatre", "The Colosseum, about AD 150",
    say("Fifty thousand people, seated by rank: senators at the front, women and slaves at the top. The awning is drawn over. Saffron water is sprayed on the crowd."),
    say("The morning: beasts. Lions from Africa, bears from Dalmatia, an ostrich; men with spears kill them for hours. The crowd cheers each kill."),
    say("Midday: the condemned. Criminals, runaways, men of no rank, sent out without armour to kill each other or be killed by beasts. It is the lunch hour. Many people eat."),
    ask("Seneca once came at midday expecting some wit and some rest, and found pure murder. \"Kill him! Lash him! Burn him!\" the crowd shouts.",
        opt("Stay and watch", say="You stay. After an hour you notice you have stopped noticing.",
            ledger="Stayed and watched the midday killings in the arena.", ledger_key="stayed_midday"),
        opt("Leave, as Seneca did", say="You push along the row to the stairs. People curse you for blocking the view.",
            ledger="Left the arena at the midday killings.", ledger_key="left_midday", then="left"),
    ),
    say("The afternoon: the gladiators. Pairs of famous men, and the crowd knows their records. The women scratch their names on walls."),
    end("As you go out, a man is selling pieces of a gladiator's liver as medicine for epilepsy. He does good business."),
    label("left"),
    end("Outside it is quiet. You can hear the roar behind you when someone dies. You can hear it all the way to the Esquiline."),
)

S["games_late"] = scene(
    "Alypius at the games", "The amphitheatre, AD 384",
    say("Your friends are going to the gladiators and they are taking Alypius, a young man from Africa, a friend of the teacher Augustine. Alypius has sworn off the games. He hates them."),
    ask("\"Come on,\" they say. \"Drag him. He'll close his eyes.\"",
        opt("Take his arm and drag him in", say="He says: \"You can drag my body there, but you cannot make me look.\"",
            ledger="Dragged Alypius to the games.", ledger_key="alypius"),
        opt("Let him go home", say="You let go of his arm. The others drag him anyway.", fides=1),
    ),
    still("In your seats, Alypius shuts his eyes. Watch him. Keep still.", secs=6,
          broke="He opens one eye at you and shuts it again.",
          done="A man falls in the arena. The whole crowd roars."),
    say("Alypius opens his eyes to see what the roar was. He sees the blood. He does not look away."),
    say("He shouts with them. He is on his feet. When you leave, he is already asking when the next games are."),
    end("Years later, Augustine will write it down: he was not the man who had come in, but one of the crowd. You were there."),
)

S["games_collapse"] = scene(
    "The races", "The Circus Maximus, AD 455",
    say("The Vandals have been gone a month. They took the Empress, the gold roof tiles from Jupiter's temple, the Jews' candlestick from Jerusalem. The races are on."),
    say("The priest Salvian wrote it of Carthage, and it is true of Rome: the Roman people is dying, and laughing."),
    say("A man sidles up. \"The Blues' horses were fed last night. Special feed. You understand me.\""),
    ask("He wants a coin for the tip.",
        opt("Pay him and back the Blues", pay=1, then="fixed", need={"price": 1},
            ledger="Bet on a race you were told was fixed.", ledger_key="fixed_race"),
        opt("Bet as you like", then="fair"),
        opt("Just watch", then="watch"),
    ),
    label("fixed"),
    play("race", win="won", lose="lost", bet=True, stake=3, laps=5, fixed=1),
    label("fair"),
    play("race", win="won", lose="lost", bet=True, stake=3, laps=5),
    label("watch"),
    play("race", win="over", lose="over", laps=5),
    label("won"),
    end("You won. Outside the Circus a woman is trying to sell her son to anyone, for bread. The law allows it in a famine."),
    label("lost"),
    end("You lost. The crowd is happy anyway. Someone starts a chant against the Emperor, then one for him."),
    label("over"),
    end("The crowd goes home cheerful. There is no grain from Africa, and there will not be."),
)

S["games_fall"] = scene(
    "The empty Circus", "The Circus Maximus, AD 552",
    say("The last races were three years ago. King Totila held them, a Goth, to show he was Rome's lord now. Half the stands were empty. The horses were thin."),
    still("Stand on the track by the turning posts and listen.", secs=8, broke="A crow gets up from the stands.",
          done="Wind. The cry of a goatherd on the Aventine. Nothing else."),
    end("Grass grows through the sand. There will never be another race here."),
)

# ---------- the funeral ----------

S["funeral_heroic"] = scene(
    "A soldier's pyre", "The Esquiline, 280 BC",
    say("A farmer-soldier died of his wounds from the Samnite war. His comrades carry him out of the city on a bier, feet first, with pipers."),
    rite("You are his tent-mate. Do the last things for him, in their order.",
         ["Call his name three times", "Carry him out feet first", "Light the pyre with your face turned away",
          "Quench the ashes with wine", "Gather his bones into the urn", "Say: may the earth lie light on you"],
         ["Light the pyre looking into his face", "Carry him out head first", "Leave his bones on the pyre"],
         restart="The old women stop wailing and look at you. His mother shows you the order again, from the beginning.",
         done="Sit tibi terra levis. May the earth lie light on you."),
    say("His centurion speaks. He says the man was never out of the line, and never in debt. That is all, and it is a great deal."),
    end("They bury the urn by the road, where people walking past will read his name. It is how a Roman lives on."),
)

S["funeral_early"] = scene(
    "The funeral of a great man", "The Rostra, 201 BC",
    say("A man of the Caecilii is dead. The family's ancestors walk in front of the bier: men chosen to look like them, wearing their wax masks and the robes of their offices, riding in chariots."),
    ask("The family needs one more man to wear a mask. Whose?",
        opt("Lucius Caecilius Metellus", say="The consul who took the Carthaginians' elephants at Panormus, and went into the burning temple of Vesta to save the Palladium, and lost his sight."),
        opt("A consul whose name you don't know", say="They tell you: an ancestor from the Samnite wars. You wear his face. You don't know what he did. Nobody will ask you."),
    ),
    say("At the Rostra the ancestors sit on ivory chairs in a row. The dead man is stood up before the crowd, propped upright, as if he were alive."),
    say("His son speaks the praise of his father, and then of each ancestor in turn, from the oldest, and each one's deeds."),
    pick("Polybius, a Greek hostage in Rome, will write about this. What does he say it does to young men who watch it?",
         ["It makes them want to endure anything for the good fame of brave men", "It makes them sad", "It makes them want to be rich"], 0,
         yes="Yes: no young man who sees it would not wish to be one of them. That is why Rome wins its wars.",
         no="Polybius says: it makes young men wish to endure anything to win the glory of brave men."),
    end("The mask goes back into its wooden cupboard in the atrium, with a label saying who he was and what he did. You were him, for an hour."),
    collect=["masks", "metellus"],
)

S["funeral_republic"] = scene(
    "Clodius's funeral", "The Forum, 52 BC",
    say("Clodius, the people's tribune and gang leader, has been killed on the Appian Way by Milo's gang. His widow Fulvia showed his wounds to the crowd all night."),
    say("Now the crowd carries his body down into the Forum. A clerk named Sextus Cloelius leads them to the Senate House."),
    ask("They are dragging out the senators' benches and the clerks' tables and records to build his pyre in the Senate House itself.",
        opt("Carry a bench", say="You carry a bench. Someone pours oil on it.", ledger="Helped burn the Senate House for Clodius's pyre.", ledger_key="burned_curia"),
        opt("Stand back and watch", say="You watch from the Comitium."),
        opt("Try to stop them", say="A man hits you in the mouth. You taste blood and stand back.", fides=2,
            ledger="Tried to stop the crowd burning the Senate House.", ledger_key="burned_curia"),
    ),
    say("The fire takes the roof. The Senate House of Rome, from the time of the kings, burns down with Clodius inside it."),
    end("The Senate meets elsewhere. Pompey is made sole consul to restore order, with his soldiers in the Forum. The Republic asks one man to save it."),
)

S["funeral_empire"] = scene(
    "A rich freedman's funeral", "The Appian Way, about AD 150",
    say("A rich freedman is dead, a former slave who made millions. His tomb on the Appian Way is already built: marble, his portrait, ships, his coins, his dog."),
    say("His heirs have hired mourning women, paid by the wail. The chief mourner beats time."),
    ask("\"You've a good sad face,\" she says. \"Walk with us and wail. A few coins at the tomb.\"",
        opt("Wail for pay", then="wail"),
        opt("Walk behind, and don't", say="You walk behind in silence, the only one who isn't paid.", then="tomb"),
    ),
    label("wail"),
    timing("Wail with the others, on the beat.", hits=3, speed=1.1, zone=0.2, miss="Out of time. She glares at you.",
           good=["\"Oh, he is gone!\"", "\"Who will feed us now?\"", "\"Oh, the good master!\""], done="She nods: you'll do."),
    wage(1, per=1, say="She pays you at the tomb."),
    label("tomb"),
    say("His epitaph is cut already. It says he began with nothing, left thirty million, and never listened to a philosopher."),
    end("His dog is on the tomb and his slaves are freed in his will, so they can mourn him as Roman citizens. It was the best thing he ever bought."),
)

S["funeral_late"] = scene(
    "The catacombs", "The Appian Way, AD 384",
    say("A poor neighbour's child has died of the fever. The Christians bury their dead underground, in galleries dug into the soft rock outside the walls, near their martyrs."),
    say("The fossor, the digger, holds a lamp. The bishop Damasus has had fine verses cut for the martyrs, in beautiful letters. The rich pay to lie near them."),
    ask("\"Near the martyr is dear,\" says the fossor. \"Further along is cheaper. Out by the air shaft, nearly free.\"",
        opt("Pay for a place near the martyr", pay=6, fides=2, say="The child will lie near the saint. The mother kisses your hands.",
            ledger="Paid for a poor neighbour's child to lie near the martyrs.", ledger_key="catacomb", need={"price": 6}),
        opt("Pay for a cheap place", pay=2, fides=1, say="A niche in the far gallery, a tile across it, a name scratched in the plaster.", need={"price": 2}),
        opt("Leave it to the family", say="They take the place by the air shaft. It is all they can pay."),
    ),
    end("The tile says: IN PACE. Above, on the road, the old pagan tombs of the rich freedmen stand empty in the sun."),
)

S["funeral_collapse"] = scene(
    "The burial pits", "The Esquiline, AD 455",
    say("After the Vandals, the dead are brought out in carts. There is no one to pay for graves, and no family left for many. They go into the old pits on the Esquiline."),
    hold("Take the feet of the next one and carry him to the pit.", secs=3.5, done="You lay him down with the others."),
    ask("On his hand there is a ring the Vandals missed. Gold.",
        opt("Take the ring", coin=6, say="It comes off easily. No one sees. Or everyone sees and nobody cares.",
            ledger="Took a gold ring from a dead man at the burial pits.", ledger_key="ring"),
        opt("Leave it", say="You leave it. The man with the next cart takes it."),
        opt("Give it to the priest for the poor", fides=1, say="The priest weighs it in his hand and puts it in his sleeve. You will never know."),
    ),
    end("Crows on the pits. The gardens of Maecenas were here once. Before that, the pits. Rome has come back to where it began."),
)

S["funeral_fall"] = scene(
    "The corpse bearers", "By the river, AD 552",
    say("At night the vespillones carry out the dead no one claims. There are many. The fever came with the river water when the aqueducts were cut."),
    ask("One of the bearers is old and can't lift. \"Take his end,\" the other says.",
        opt("Take it", then="carry"),
        opt("Walk on", say="You walk on. They manage, somehow, or they leave him there till morning.", then="end"),
    ),
    label("carry"),
    hold("Carry him down to the boat.", secs=4.0, done="You set him down in the boat with the others."),
    gain(say="The old bearer thanks you with the only thing he has: your name, said aloud, in the dark.", fides=1,
         ledger="Carried the unclaimed dead at night.", ledger_key="vespillo"),
    label("end"),
    end("The boat goes down the river in the dark. In the city of a million people, there are a few tens of thousands left."),
)

# ---------- the levy ----------

S["levy_heroic"] = scene(
    "The levy", "The Capitol, 280 BC",
    say("King Pyrrhus has landed with twenty thousand men and elephants. The consul has named the day, and every man of military age has come up to the Capitol."),
    say("The tribunes of the soldiers call the tribes by lot. Four men at a time are brought forward, and the tribunes choose, in turn."),
    ask("Your tribe is called. The men around you are farmers; half of them fought the Samnites.",
        opt("Step forward", say="You step forward. A tribune looks at your shoulders and picks you.", then="oath", dignitas=1,
            ledger="Stood forward at the levy against Pyrrhus.", ledger_key="levy"),
        opt("Stay back in the crowd", say="Nobody picks you. The men who are picked look at you as they pass.", fides=-2,
            ledger="Hung back at the levy against Pyrrhus.", ledger_key="levy"),
    ),
    end("The legions march south without you. At Heraclea they will lose to the elephants, and not break."),
    label("oath"),
    rite("One man says the oath for all, and each man after him says: \"Idem in me.\" The same for me. Say it in its order.",
         ["Raise your right hand", "Swear to obey the consul", "Swear to do what he orders", "Say: Idem in me"],
         ["Swear to obey your tribe", "Say your own name"],
         restart="The tribune stops you. \"Again. Properly.\"", done="You are a soldier of Rome."),
    end("You march south with the consul Laevinus. The King will win his battles, and say: another such victory and I am lost."),
)

S["levy_early"] = scene(
    "The levy and the oath", "The Capitol, 200 BC",
    say("The consul needs two legions for Macedonia. Only men with property may serve: they have something to lose, and they buy their own arms."),
    iff({"class": 1}, "enrolled"),
    say("You are counted by head. You have no property. The tribunes pass you over: Rome does not arm the poor."),
    end("You watch the others march out. In a hundred years a consul named Marius will take the poor into the legions, and the legions will belong to whoever pays them."),
    label("enrolled"),
    say("The censors have you on their roll. The tribunes pick you by tribe."),
    rite("Since Cannae, every man swears the oath himself, word for word. Swear it.",
         ["Not to leave for flight or fear", "Not to leave the ranks", "Except to take up or fetch a weapon",
          "Or to strike an enemy, or to save a citizen"],
         ["Except to save yourself", "Not to fight without pay"],
         restart="The tribune stops you. \"The words, soldier. All of them, in their order.\"",
         done="You are sworn. The oath binds until the consul releases you."),
    gain(dignitas=1, ledger="Swore the soldier's oath for the war with Macedon.", ledger_key="levy"),
    end("You march out through the Porta Capena. Behind you the city goes on as if you had never been in it. That is what you are for."),
)

S["levy_republic"] = scene(
    "The recruiter", "The Forum, about 50 BC",
    say("A centurion of Pompey's is taking men. There is going to be war with Caesar, everyone knows it."),
    say("He does not ask about your property. He asks if you are fit, and if you want pay, and land when it's over. The land will come from the general, not from Rome."),
    ask("\"Pompey the Great looks after his men,\" he says. \"Who looks after you now?\"",
        opt("Sign for Pompey", say="You give your name. He gives you a coin to drink the general's health. Not the Republic's: the general's.",
            coin=2, ledger="Signed on for a general's pay against other Romans.", ledger_key="levy"),
        opt("Ask what the war is for", say="He looks at you. \"For Pompey,\" he says, as if you were simple."),
        opt("Walk away", say="Down the street, one of Caesar's men is saying the same things."),
    ),
    end("In a year, Roman legions will kill each other in Greece, in Africa, in Spain. Each man will have sworn his oath to his general."),
)

S["levy_empire"] = scene(
    "The recruiting officer", "The Campus Martius, about AD 150",
    say("A recruiting officer of the legions sits at a table with a clerk. He looks at your teeth, your eyes, your height, your hands."),
    say("Twenty-five years. Pay, bread, a roof, a sword. No marriage while you serve. A plot of land or a lump of money at the end, if you are alive."),
    ask("\"The frontier on the Danube,\" he says, \"or Britain. Both cold.\"",
        opt("Sign for twenty-five years", say="The clerk writes your name, your father's name, your marks. \"Come back with a letter from a man who knows you.\"",
            ledger="Signed for twenty-five years in the legions.", ledger_key="levy"),
        opt("Walk on", say="Almost no one from Rome itself signs. The legions are Gauls and Spaniards and Syrians now, who have never seen the city."),
    ),
    end("Rome is defended by men who will never see it, and Rome is glad not to see them."),
)

S["levy_late"] = scene(
    "The recruit tax", "The Forum, AD 384",
    say("A crier reads the Emperor's order: the landowners must send recruits, or pay the recruit tax in gold instead. Most pay. The army takes Goths instead, whole tribes, under their own chiefs."),
    say("Your landlord's tenant, a young man, has cut off his own thumb so he can't be taken. There is a law for it now: a maimed man is taken anyway, and his landlord must send two like him for one whole man."),
    ask("The Prefect's men are asking whether anyone knows a young man with no thumb.",
        opt("Say nothing", say="You say nothing. So does everyone.", fides=1,
            ledger="Kept silent about a man who maimed himself to escape the army.", ledger_key="thumb"),
        opt("Point him out", say="They take him. You are paid a small sum. Your neighbours stop talking when you come in.", coin=3, fides=-4,
            ledger="Informed on a man who maimed himself to escape the army.", ledger_key="thumb"),
    ),
    end("The Goths who killed an Emperor at Adrianople six years ago now defend the Empire, for pay, under their own kings."),
)

S["levy_collapse"] = scene(
    "The palace guard", "The Palatine, AD 455",
    say("At the palace gate the guards are Goths and Sueves. They talk among themselves in their own language. Their commander chooses the Emperor's friends."),
    say("When the Vandals came up the river in June, no one manned the walls. There was no army. The Emperor Maximus ran, and the crowd killed him."),
    ask("A guard asks you, in bad Latin, where the wine shops are.",
        opt("Tell him the way", say="He thanks you and goes. He is a boy, younger than you."),
        opt("Send him the wrong way", say="He goes. Later you hear he came back and beat a shopkeeper for lying to him.", fides=-1),
    ),
    end("Pope Leo went out to meet the Vandal king unarmed and begged him not to burn the city or kill. That was the defence of Rome."),
)

S["levy_fall"] = scene(
    "The garrison", "The Campus, AD 552",
    say("Narses's army took the city this summer, the fifth time Rome has changed hands in this war: Lombards, Heruls, Huns, Armenians, Persians. There is not a Roman among them."),
    say("The garrison changes at the old tomb of Hadrian, which is a fortress now. They threw its statues down on the Goths in the first siege."),
    end("No one has asked a Roman to fight for Rome in a hundred years. There is no one to ask."),
)

# ---------- the court ----------

S["court_heroic"] = scene(
    "The consul's judgement", "The Comitium, 280 BC",
    say("Two farmers from the Esquiline quarrel over a boundary. The Twelve Tables are on bronze on the Rostra for anyone to read."),
    pick("The consul asks what the Tables say about boundaries between fields.", [
        "A strip five feet wide is left between them, and no one may own it",
        "The richer man decides",
        "The gods decide by lot",
    ], 0, yes="The consul nods. Five feet, by law, since before anyone's grandfather.",
         no="The consul corrects you: a five-foot strip, owned by no one."),
    ask("One of them asks you to swear you saw the other move a boundary stone. You didn't.",
        opt("Swear the truth: you saw nothing", say="He curses you. The consul thanks you.", fides=2),
        opt("Swear what he wants", say="The consul looks at you a long time. He believes you. That is worse.", fides=-3,
            ledger="Swore falsely in the consul's court.", ledger_key="false_witness"),
    ),
    end("The consul gives his judgement and goes home to his dinner of turnips. He will not be paid for it. No one has ever thought he should be."),
)

S["court_early"] = scene(
    "The praetor's tribunal", "The Comitium, 200 BC",
    say("A neighbour is suing a man who cut down his vines. You speak for him. The law is the Twelve Tables, and the forms of action: the words must be the law's words exactly."),
    pick("The Tables speak of cutting down another man's trees. Which word must he use for his vines?",
         ["\"Trees\" (arbores), as the law says", "\"Vines\" (vites), since they were vines", "Either will do"], 0,
         yes="Right. A man who said \"vines\" lost his case, because the law says trees.",
         no="Wrong: he must say \"trees\". A man who said \"vines\" lost his case for it."),
    iff({"score": 1}, "won"),
    end("Your neighbour loses the case for your word. The praetor is sorry. The law is the law, and it does not bend. That is why it holds."),
    label("won"),
    gain(fides=1, say="The praetor grants the action. Your neighbour will have twenty-five asses for each tree."),
    end("The law is hard and it is the same for everyone. Men complain of it. They will miss it."),
)

S["court_republic"] = scene(
    "A trial for extortion", "The Forum, about 50 BC",
    say("A former governor is on trial for robbing his province. You were there: you saw his men take the temple treasures."),
    say("Before you testify, a man in a good cloak takes you aside. He is from the defence."),
    ask("\"Memory is a strange thing,\" he says. \"A little money helps it.\"",
        opt("Take the money and remember nothing", coin=12, fides=-3, say="You say you saw nothing clearly.",
            ledger="Took money to change your testimony.", ledger_key="bribed_witness"),
        opt("Testify to what you saw", fides=2, say="You tell it plainly. The defence counsel makes you look a fool, a liar, a foreigner."),
    ),
    say("The jury is senators, knights and treasury tribunes. Everyone knows how many have been bought. At one trial a senator asked the jurors why they had wanted guards: were they afraid of being robbed of their bribes?"),
    end("The governor is acquitted by a few votes. Verres said it: a governor needs three years' plunder, one to keep, one for his friends, one to buy his jury."),
)

S["court_empire"] = scene(
    "A treason hearing", "Before the Senate House, about AD 150",
    say("An informer is gathering witnesses. A man in a wine shop said something about the Emperor. The law of treason covers words."),
    ask("\"You were there,\" the informer says. \"You heard him. A quarter of his property goes to the accusers.\"",
        opt("Inform against him", coin=20, fides=-5, say="He is ruined. You are paid. People are polite to you, and afraid of you.",
            ledger="Informed against a man for treason.", ledger_key="informer"),
        opt("Say you heard nothing", fides=1, say="The informer writes your name down."),
        opt("Warn the man", fides=3, say="You find him at his house and tell him. He goes white. He leaves the city that night.",
            ledger="Warned a man that an informer was after him.", ledger_key="informer"),
    ),
    end("This Emperor is mild and the law is not used much. But it is there, the informers are there, and everyone knows both."),
)

S["court_late"] = scene(
    "The Prefect's court", "The Forum, AD 384",
    say("A man who could not pay his tax arrears is being beaten with lead-weighted whips in front of the Prefect's court. His wife watches. He owes almost nothing."),
    ask("The officer shouts that the arrears will be paid or the flogging will go on.",
        opt("Pay his arrears", pay=10, fides=3, say="You pay. The officer writes a receipt. The man is carried home.",
            ledger="Paid a stranger's tax arrears to stop his flogging.", ledger_key="arrears", need={"price": 10}),
        opt("Walk on", say="You walk on. The sound follows you down the street.",
            ledger="Walked past a man flogged for his taxes.", ledger_key="arrears"),
    ),
    end("The rich are exempt, or settle with the collectors. The poor pay, or run, or sell their children. It is legal."),
)

S["court_collapse"] = scene(
    "The bishop's hearing", "The church of the Chains, AD 455",
    say("The Empress Eudoxia built this church for the chains of Saint Peter. The bishop hears disputes here now: the courts hardly sit."),
    say("A widow says a man took her dead husband's house in the confusion after the Vandals. He says her husband sold it to him before."),
    ask("The man asks you to swear on the chains of Peter that you saw the sale. You didn't.",
        opt("Swear the truth", fides=2, say="The widow keeps her house. The man will remember your face."),
        opt("Swear his lie on the chains", coin=8, fides=-4, say="The bishop looks at you and says nothing. The widow is put out.",
            ledger="Swore a lie on Saint Peter's chains.", ledger_key="false_witness"),
    ),
    end("The bishop's judgement is the only judgement left that people fear, and it is not the sword they fear."),
)

S["court_fall"] = scene(
    "The deacon's hearing", "The church of the Chains, AD 552",
    say("The Pope has been kept in Constantinople for years by the Emperor. The deacons judge what little needs judging: who may have a ruined house, who owes bread to whom."),
    end("A goat is given back to its owner. It is the only case today."),
)

# ---------- the bread ----------

S["bread_heroic"] = scene(
    "Your bread", "Your room in the Subura, 280 BC",
    say("There are no bakers in Rome yet. Every house grinds its own grain and bakes its own bread. The Roman farmer lives on porridge and bread."),
    timing("Turn the quern: push the handle round as the stone comes to you.", hits=3, speed=0.9, zone=0.22,
           miss="The stone sticks.", good=["The flour comes.", "Coarse, but it comes.", "Enough for a loaf."]),
    hold("Knead the dough.", secs=3.0, done="It is ready."),
    say("You bake it under a clay cover in the embers of the hearth, as your grandmother would have."),
    gain(give="a loaf"),
    end("Hard bread, and a little salt. It is the food of the men who beat the Samnites."),
)

S["bread_early"] = scene(
    "The aediles' grain", "The cattle market, 200 BC",
    say("The aediles are selling grain from Africa cheaply, four asses a measure: Scipio's grain, won with the war."),
    ask("The queue is long and orderly. The aedile's clerk takes your coins.",
        opt("Buy a measure", pay=4, say="A measure of African wheat, poured into your sack.", give="a measure of grain", need={"price": 4}),
        opt("Buy for a widow in the queue as well", pay=8, fides=2, say="She says the gods will see it. The aedile's clerk writes nothing: it is nobody's business but yours.",
            give="a measure of grain", need={"price": 8}),
        opt("Just watch", say="No one is fed for nothing. No one expects to be."),
    ),
    end("Rome feeds itself with what it has won. For now, that feels like justice."),
)

S["bread_republic"] = scene(
    "The grain dole", "The Campus Martius, about 50 BC",
    say("Since Clodius's law, the grain is free for every citizen on the list: three hundred thousand of them. The list is full of the dead and the invented."),
    say("You are not a citizen. A man from the Clodian gang sells places on the list: a dead man's name."),
    ask("\"He won't need it,\" the man says. \"He's been dead two years.\"",
        opt("Buy the dead man's place", pay=4, fides=-2, say="You take the dead man's grain every month under his name.",
            give="a measure of grain", ledger="Bought a dead man's place on the grain list.", ledger_key="grain_list", need={"price": 4}),
        opt("Buy your grain at the market", pay=2, say="The market price is low: the free grain keeps it low.", give="a measure of grain", need={"price": 2}),
        opt("Walk away", say="The gang man shrugs. Four years from now Caesar will cut the list in half."),
    ),
    end("The citizens of Rome no longer work to eat. The men who feed them own them."),
)

S["bread_empire"] = scene(
    "The corn dole", "The Portico of Minucius, about AD 150",
    say("Two hundred thousand citizens have a ticket, the tessera, with their day and their doorway. Forty-five arches: you go to your number on your day."),
    say("The grain comes from Egypt and Africa in the great ships to Ostia, then up the river on barges. The Emperor feeds Rome, and Rome knows who feeds it."),
    ask("Your neighbour the barber has lent you his ticket: he's ill.",
        opt("Collect his grain for him", say="You queue at arch 32. The clerk looks at the ticket, not at you. Five measures.", fides=1, give="a measure of grain"),
        opt("Collect it and keep some", say="You keep a measure. He will never know.", fides=-2, give="a measure of grain",
            ledger="Kept part of a sick neighbour's grain.", ledger_key="grain_neighbour"),
    ),
    end("Bread and circuses, Juvenal says: the people that once gave commands and legions now want only two things."),
)

S["bread_late"] = scene(
    "Bread from the steps", "The Forum, AD 384",
    say("The bread comes baked now, from the steps: loaves handed down to those with the right to them. Pork and oil too, in their season."),
    say("The bakers are bound to their trade by law, and their sons after them. A baker's son is running away to the Church."),
    ask("He hides behind you in the queue. The bakers' guild master is looking for him.",
        opt("Hide him", fides=2, say="You stand in front of him until the guild master passes. He runs.",
            ledger="Hid a baker's son running from his hereditary trade.", ledger_key="baker_son"),
        opt("Point him out", coin=2, fides=-2, say="They take him back to the ovens. He will die a baker. His son too.",
            ledger="Gave back a baker's son to his hereditary trade.", ledger_key="baker_son"),
    ),
    end("Everyone is bound to something: the baker to the oven, the farmer to the soil, the councillor to his tax bill. The Empire holds still by chaining everyone in place."),
)

S["bread_collapse"] = scene(
    "The empty granaries", "The cattle market, AD 455",
    say("The Vandals have held Africa for sixteen years. The grain ships do not come. Now they have been to Rome as well."),
    say("A crowd has gathered at the granaries. There is nothing in them. Someone throws a stone at the Prefect's man."),
    ask("The crowd surges toward the doors.",
        opt("Join the riot", say="You break in with them. There are rats and dust. A man is crushed against the doors.",
            ledger="Joined the bread riot.", ledger_key="riot"),
        opt("Give your bread to a child", take="a loaf", fides=2, need={"has": "a loaf"}, say="She eats it in three bites and looks at you for more.",
            ledger="Gave your bread away in the famine.", ledger_key="famine_bread"),
        opt("Go home", say="You go home. You are lucky to have one."),
    ),
    end("Grain costs what gold used to cost. People are eating nettles. The rich are leaving for their estates, or for Constantinople."),
)

S["bread_fall"] = scene(
    "The Church's bread", "Holy Mary the Old, AD 552",
    say("The deacons hand out bread at the church in the old Palatine guardhouse. The Church feeds Rome now: the Church's estates in Sicily send what they can."),
    ask("A deacon asks your name for his list.",
        opt("Give your name", say="He writes it. You take the bread. It is dark and has grit in it.", give="a loaf"),
        opt("Give a false name, to take twice", say="He looks at you. He knows. He gives it to you anyway.", give="a loaf", fides=-1,
            ledger="Took the Church's bread twice under another name.", ledger_key="church_bread"),
    ),
    end("In the siege they ate grass and dogs, and some ate worse. This bread is a miracle, and it tastes of the grit in it."),
)

# ---------- the sacrifice ----------

_SACRIFICE = ["Veil your head with your toga", "Wash your hands", "Sprinkle the salted meal on the ox's head",
              "Pour wine on its brow", "Draw the knife along its back", "The attendant strikes", "The diviner reads the entrails",
              "Burn the god's share on the altar"]
_SACRIFICE_WRONG = ["Uncover your head", "Wash your feet", "Sprinkle salt on the altar"]

S["sacrifice_heroic"] = scene(
    "The sacrifice to Jupiter", "The Capitol, 280 BC",
    say("A white ox, garlanded, for Jupiter Best and Greatest, for the war against the King. A piper plays so no ill-omened word is heard."),
    rite("Do it exactly. The gods hear only what is done right.", _SACRIFICE, _SACRIFICE_WRONG,
         restart="A slip. The piper stops. It all begins again from the veiling, as the law of the gods requires.",
         done="The liver is whole, the heart is sound: litatio. The god accepts."),
    iff({"random": 0.3}, "omen"),
    end("Everyone eats the meat after. It is the best meal of the year for half the people on the Capitol."),
    label("omen"),
    end("As the smoke goes up an eagle crosses from the right, high over the Tiber. Everyone sees it. Everyone knows what it means."),
)

S["sacrifice_early"] = scene(
    "The sacrifice to Jupiter", "The Capitol, 200 BC",
    say("The consuls sacrifice before they leave for Macedonia, on the Capitol, before the whole city. After Cannae, no one takes the gods lightly."),
    iff({"random": 0.35}, "bolt"),
    go("rite"),
    label("bolt"),
    say("The ox pulls away from the altar and bellows. A bad sign. It is led round, calmed, and the rite begins again from the start."),
    label("rite"),
    rite("Do it exactly, as the pontiffs say.", _SACRIFICE, _SACRIFICE_WRONG,
         restart="A slip. The piper stops. The pontiff says the prayer again from the first word.",
         done="The god accepts. The consuls may go."),
    end("A people that won through Cannae thanks the gods for it, and means every word."),
)

S["sacrifice_republic"] = scene(
    "The sacrifice to Jupiter", "The Capitol, about 50 BC",
    say("The chief pontiff is Julius Caesar, who is in Gaul; his deputy sacrifices. Old Cato said two diviners could hardly pass each other without laughing."),
    rite("Do it as it is written.", _SACRIFICE, _SACRIFICE_WRONG, strict=False,
         slack="A slip. The priest waves it on. Nobody starts again any more.", done="The god accepts. Or someone says so."),
    end("The forms are kept perfectly by men who believe in nothing, and used to stop elections when their side is losing."),
)

S["sacrifice_empire"] = scene(
    "Incense for the Emperor", "The Temple of Antoninus and Faustina, about AD 150",
    say("The Senate made the Empress Faustina a goddess, and her husband built her a temple on the Sacred Way. When he dies, he will be a god in it too."),
    say("Beside you in line is a man who will not burn the incense. A Christian. The officials have noticed."),
    ask("The official asks you: does this man worship the Emperor's genius or not? You heard him say he won't.",
        opt("Say what you heard", coin=3, fides=-3, say="They take him away. He does not resist. He looks almost glad.",
            ledger="Denounced a Christian who would not burn incense.", ledger_key="christian"),
        opt("Say he's only slow", fides=2, say="The official doesn't care enough to argue. He lets the man go. The man looks at you, puzzled.",
            ledger="Covered for a Christian who would not burn incense.", ledger_key="christian"),
        opt("Say nothing", say="The man is taken aside to be asked again, and again."),
    ),
    rite("Now your turn.", ["Take a pinch of incense", "Drop it on the coals", "Say: for the Emperor's genius"],
         ["Say: for Jupiter", "Pour it on the ground"], strict=False, slack="Close enough, the official says.",
         done="The smoke goes up. You have shown you are loyal. That is all it was for."),
    end("A god who was a man, and his wife who was a woman. Nobody here thinks it strange. Or nobody says so."),
)

S["sacrifice_late"] = scene(
    "The old rite", "A senator's house on the Quirinal, AD 384",
    say("The Emperor's laws forbid sacrifice. In the house of an old senator, Praetextatus, priest of half the gods of Rome, the old rites are done behind shut doors."),
    ask("A servant lets you in. \"You have come to honour the gods of your fathers?\"",
        opt("Yes", then="rite"),
        opt("No, and go", say="You leave. There is a church being built at the end of the street.", then="end"),
    ),
    label("rite"),
    rite("A lamb, not an ox. A small altar in a courtyard. Do it exactly.", _SACRIFICE[:4] + ["Draw the knife along its back", "Burn the god's share on the altar"],
         _SACRIFICE_WRONG, restart="The old senator stops. \"Again. We are the last who know how. We will not do it badly.\"",
         done="It is done correctly, perhaps for the last time in this house."),
    still("Someone knocks at the street door. Nobody move.", secs=6, broke="A cup clinks. Everyone freezes.",
          done="The knocking stops. Footsteps go away."),
    gain(ledger="Sacrificed with the old senators when the law forbade it.", ledger_key="secret_sacrifice"),
    label("end"),
    end("The senator will be dead before the year is out. His wife will set up his monument, listing his priesthoods, the longest list in Rome."),
)

S["sacrifice_collapse"] = scene(
    "The relics", "The church of the Chains, AD 455",
    say("No one sacrifices now. At the church of the chains of Saint Peter, a man is selling small things in cloth: strips that have touched the saint's tomb, dust from the martyrs' graves."),
    ask("\"Against fever, against the Vandals, against the evil eye,\" he says. \"Blessed by a priest. One coin.\"",
        opt("Buy one", pay=1, give="a relic", say="You hang it round your neck. It does not hurt. It may help.", need={"price": 1}),
        opt("Ask if it's real", say="\"As real as your money,\" he says."),
        opt("Walk on", say="Inside, the real chains hang in the dark, and people kiss them."),
    ),
    end("There are more relics sold in a day than there are bones in all the martyrs' graves. Everyone knows. Everyone buys."),
)

S["sacrifice_fall"] = scene(
    "The empty temple", "The Temple of Saturn, AD 552",
    say("The Temple of Saturn still stands, its columns and its inscription. There is no altar, no priest, no god. The treasury that was kept under it is long empty."),
    ask("You have a little wine.",
        opt("Pour it on the step, the old way", then="pour"),
        opt("Drink it", say="It is sour, and it is yours.", then="end"),
    ),
    label("pour"),
    hold("Pour it slowly, and say the old words, alone.", secs=3.0, done="The wine runs down the step into the dust."),
    gain(ledger="Kept the old rite alone in the empty city.", ledger_key="alone_rite"),
    label("end"),
    end("The Senate and the People of Rome restored this temple after it burned, says the inscription. There is no one left to restore it again."),
)

# ---------- the triumph ----------

S["triumph_heroic"] = scene(
    "A triumph", "The Sacred Way, 280 BC",
    say("The consul Tiberius Coruncanius triumphs over the Etruscans of Volsinii and Vulci. His face is painted red like Jupiter's statue; he wears the god's purple and gold."),
    say("Behind him his soldiers march and sing, and the songs are rude: about his baldness, his meanness, his love affairs. It is their right on this one day."),
    ask("The soldiers look at the crowd for someone to join in.",
        opt("Shout \"Io triumphe!\"", say="\"Io triumphe!\" The whole Sacred Way takes it up."),
        opt("Join the rude song", say="You sing about the consul's bald head. He laughs, and so do the soldiers."),
    ),
    end("At the top of the Capitol he lays his laurel in Jupiter's lap. Tomorrow he will be a farmer again, and one day the first plebeian chief pontiff."),
)

S["triumph_early"] = scene(
    "Scipio's triumph", "The Sacred Way, 201 BC",
    say("Scipio triumphs over Carthage and Hannibal: silver by the wagon, Numidian captives, and they call him Africanus now."),
    say("A slave stands behind him in the chariot, holding the golden crown over his head, and speaks into his ear all the way up to the Capitol."),
    pick("What does the slave keep telling him?",
         ["Look behind you: remember you are a man", "Remember the Senate", "Remember your debts"], 0,
         yes="\"Respice post te. Hominem te memento.\" Look behind you. Remember you are a man.",
         no="The slave says: look behind you, remember you are a man."),
    end("The greatest man in Rome is reminded he is mortal, and it works, mostly. In twenty years the Senate will put him on trial and he will leave Rome forever."),
)

S["triumph_republic"] = scene(
    "The general who waits", "The Campus Martius, about 50 BC",
    say("Cicero is back from governing Cilicia and wants a triumph for beating some hill tribes. A general who asks for one may not enter the city until it's decided, or he loses his command."),
    say("So he waits outside the walls with his lictors and their laurelled fasces, while the Senate talks about Caesar and Pompey instead."),
    ask("One of his lictors, bored, asks if you think the great man will get his triumph.",
        opt("\"Of course\"", say="\"That's what he says,\" the lictor says."),
        opt("\"Not while Caesar and Pompey are at each other\"", say="The lictor nods. \"I've got a wife in the Subura. I haven't seen her in a month. Across the road.\""),
    ),
    end("He never gets it. The civil war comes. He waits outside the gates until it is no use waiting. Pompey had three triumphs; Caesar will have four in a month."),
)

S["triumph_empire"] = scene(
    "The Emperor's victory", "The Sacred Way, about AD 150",
    say("The crier says the Emperor has won in Britain: a new wall beyond the old one. There will be games. There is a new coin with Britannia on it, sitting on a rock."),
    say("The Emperor never left Italy. His governor did the fighting. There is no triumph: only the Emperors have triumphs now, and this one does not travel."),
    ask("A money changer offers you one of the new coins at a little over its value.",
        opt("Buy it", pay=1, collect=["coins", "britannia"], say="Britannia, head in hand, on a rock, conquered. You put it in your purse.", need={"price": 1}),
        opt("Ask where Britain is", say="\"At the end of the world,\" he says. \"It rains.\""),
    ),
    end("The frontier is a thousand miles away, and a wall. Rome is safe, and it has stopped thinking about how."),
)

S["triumph_late"] = scene(
    "The Emperor's visit", "Trajan's Forum, AD 384",
    say("No Emperor comes. An old man remembers the last time one did: Constantius, twenty-seven years ago, his first sight of Rome."),
    say("\"He stood in his carriage like a statue,\" the old man says. \"He never turned his head. He never wiped his face or spat. Then he saw Trajan's Forum, and he stopped.\""),
    pick("\"There was a Persian prince with him. The Emperor said he would make a horse like Trajan's. And the prince said...?\"",
         ["\"First build a stable like this one for it\"", "\"Persia has finer horses\"", "\"It is too cold to build\""], 0,
         yes="\"And then he said what pleased him most in Rome: that he'd learned men die here too.\"",
         no="\"He said: first build a stable like this one. And that what pleased him most was to learn that men die here too.\""),
    end("The Emperor went away, and never came back. Nor did any Emperor, much. Rome is a museum the Empire visits."),
)

S["triumph_collapse"] = scene(
    "The Vandals' procession", "The river port, AD 455",
    say("For fourteen days the Vandals have been taking what they like, calmly, by list. Now the carts go down to their ships in the river: gold, silver, the candlestick from the Temple of Jerusalem, half the gilded tiles from Jupiter's roof."),
    say("The Empress Eudoxia and her daughters go with them, as captives. So do thousands of others, for the slave markets of Carthage."),
    ask("A Vandal overseer points at you: carry this sack to the boat, for a coin.",
        opt("Carry it", coin=1, say="It is heavy with plates. You carry Rome's silver to Carthage for a coin.",
            ledger="Carried the Vandals' plunder to their ships for pay.", ledger_key="vandal_loot"),
        opt("Refuse", say="He shrugs and points at someone else. There are plenty of others."),
        opt("Hide a chalice from the cart", fides=2, say="You slip it under your cloak. Later you give it back to the church it came from.",
            ledger="Hid a chalice from the Vandals.", ledger_key="vandal_loot"),
    ),
    end("A procession in the old style, up the old road: but going away, and it is not Rome's."),
)

S["triumph_fall"] = scene(
    "No triumph", "The Sacred Way, AD 552",
    say("Narses the eunuch has taken Rome back for the Emperor Justinian. He sent the keys of the city to Constantinople. There was no procession."),
    say("Goats graze by the Arch of Titus. Someone is cutting stones from the Temple of Venus and Rome for his house."),
    end("Rome has been taken five times in this war. Nobody lays laurels in Jupiter's lap. The roof tiles are in Carthage."),
)

# ---------- the Saturnalia ----------

_GIFT = ask("It's the custom to give a small gift: a wax candle, a little clay doll.",
            opt("Give a candle to a slave", pay=1, fides=1, say="He takes it with both hands. For a day, you are equals.", need={"price": 1}),
            opt("Give nothing", say="Everyone else gives something. You feel it."))

S["saturnalia_heroic"] = scene(
    "The Saturnalia", "The Temple of Saturn, 280 BC",
    say("The feast of Saturn, when the world was young and no one was a master. The priest unties the woollen bonds from the god's statue feet."),
    say("For a day the slaves eat with their masters, dice are allowed, and everyone shouts \"Io Saturnalia!\""),
    _GIFT,
    play("tali", win="won", lose="lost", say="Dice are legal today. A farmer challenges you.", stake=1),
    label("won"),
    end("You won. The farmer's slave, at the head of the table, crowns you king of the feast."),
    label("lost"),
    end("You lost. The farmer laughs and pours you wine. Tomorrow he will be the master again."),
)

S["saturnalia_early"] = scene(
    "The Saturnalia", "The Temple of Saturn, 200 BC",
    say("Since the disaster at Lake Trasimene, the Saturnalia is kept with a public banquet in the Greek way, and the cry of \"Io Saturnalia!\" all day and night."),
    _GIFT,
    play("tali", win="won", lose="lost", say="Dice are legal today.", stake=1),
    label("won"),
    end("You won, and the slave who is king of the feast orders you to sing. Everyone sings."),
    label("lost"),
    end("You lost. A slave cuffs his master's ear, and everyone laughs, including the master."),
)

S["saturnalia_republic"] = scene(
    "The Saturnalia", "About 50 BC",
    say("The only honest day of the year: a slave may tell his master what he thinks of him."),
    say("A slave named Davus tells his master he is a slave himself: to his lusts, his ambition, his fear of what people say."),
    ask("His master turns to you. \"Is he right?\"",
        opt("\"Yes\"", say="The master laughs. Then he doesn't.", fides=1),
        opt("\"It's the Saturnalia. Everyone's right today.\"", say="Everyone laughs. It's the safest thing anyone says all day."),
    ),
    play("tali", win="won", lose="lost", stake=2),
    label("won"),
    end("You win at dice. Tomorrow dice are illegal again, and the lictors will fine men for what everyone does."),
    label("lost"),
    end("You lose at dice. Tomorrow the master will be master and the slave a slave, and nobody will remember anything said."),
)

S["saturnalia_empire"] = scene(
    "The Saturnalia", "About AD 150",
    say("The Saturnalia lasts a week now. The city is drunk. Seneca said December used to be a month; now it is the whole year."),
    say("The rich give gifts that are jokes: a toothpick, a cheap clay doll, or a slave. The Emperor gives presents to the crowd."),
    _GIFT,
    play("duodecim", win="won", lose="lost", say="On the steps of the Basilica Julia, men play at twelve lines. One waves you over.", stake=2),
    label("won"),
    end("You win. He pays you and starts again with someone else. The boards are cut in the steps of the Basilica; they will be there in two thousand years."),
    label("lost"),
    end("You lose. Everyone loses at something this week."),
)

S["saturnalia_late"] = scene(
    "The Saturnalia dinner", "The house of Praetextatus, AD 384",
    say("The last great pagans of Rome keep the Saturnalia at dinner: Praetextatus, Symmachus, Flavianus, men of books and old rites. They talk of Virgil, of the gods, of the old calendar."),
    say("Someday a man named Macrobius will write their talk down, so that it will seem it lasted forever."),
    ask("A guest asks you why Saturn's feast has the slaves waited on by their masters.",
        opt("Because under Saturn there were no masters", say="\"Well said.\" The guest raises his cup."),
        opt("Because it is the custom", say="\"That is also true,\" the guest says, and it is the Roman answer."),
    ),
    end("Down the street the Christians keep a feast of their own, eight days later, and call it the birthday of Christ, on the Unconquered Sun's own day."),
)

S["saturnalia_collapse"] = scene(
    "The Saturnalia", "The Forum, AD 455",
    say("The Church forbids it. The crowd keeps it anyway, a mob in masks, the old cry gone ragged: \"Io Saturnalia!\" Someone is dressed as the Emperor. Someone is dressed as a Vandal."),
    ask("A masked man pushes dice into your hand.",
        opt("Play", then="play"),
        opt("Push through the crowd home", say="Someone steals your cloak on the way.", then="end"),
    ),
    label("play"),
    play("tali", win="end", lose="end", stake=2),
    label("end"),
    end("The masters don't serve the slaves. There are fewer masters, and fewer slaves, and all of them hungry."),
)

S["saturnalia_fall"] = scene(
    "The Saturnalia", "AD 552",
    say("An old woman remembers it: when she was small, her grandmother would give the slaves wine and they'd shout the old words in the street. \"Io Saturnalia.\" She says it softly."),
    end("There are no slaves in the house and no house. There is the old woman, and the words."),
)

# ---------- the morning call ----------

S["salutatio_heroic"] = scene(
    "The morning call", "Your patron's house on the Palatine, 280 BC",
    say("Your patron, Caecilius, is a senator and a farmer. His house is on the Palatine and his fields are an hour's walk."),
    say("\"How are your crops?\" he asks, and means it. He knows the price of seed. He will speak for you if you're wronged; you will stand by him if he needs you."),
    ask("He asks you to walk down with him to the Forum.",
        opt("Walk with him", dignitas=1, say="You walk at his side. People greet him as a man, not as a lord."),
        opt("Say you have work", say="\"Then work,\" he says. \"That's what we're for.\""),
    ),
    end("The bond between a patron and his client is sacred: the Twelve Tables curse the patron who wrongs his client."),
)

S["salutatio_early"] = scene(
    "The morning call", "Your patron's house on the Palatine, 200 BC",
    say("Quintus Caecilius has more clients now; after the war he has land in Campania. At dawn thirty men wait in his atrium."),
    say("He greets each by name. The poorer ones are given a little basket of food."),
    ask("He asks if you'll speak for his cousin at the elections.",
        opt("Yes", dignitas=1, fides=1, say="He thanks you. The bond is honoured both ways."),
        opt("Ask what's in it for you", say="He looks at you. \"My friendship,\" he says. It is meant to be enough, and it is.", fides=-1),
    ),
    gain(give="a basket of food"),
    end("A client's loyalty and a patron's protection: the old pairing holds, for now."),
)

S["salutatio_republic"] = scene(
    "The morning call", "Your patron's house on the Palatine, about 50 BC",
    say("A hundred clients at the door before dawn. Caecilius is standing for office. A slave, the nomenclator, whispers each name in his ear so he can greet you as a friend."),
    ask("\"My friend!\" he says. He has never met you. \"You'll walk me down to the Forum?\"",
        opt("Walk in his escort", dignitas=1, say="A crowd around a candidate shows he matters. You are part of the crowd."),
        opt("Go to his rival's door instead", coin=2, say="His rival pays better. Many of the same faces are there.", fides=-1),
    ),
    end("His brother wrote him a handbook: be everyone's friend, promise everything, remember every name, or have a slave who does."),
)

S["salutatio_empire"] = scene(
    "The morning round", "The great houses on the Esquiline, about AD 150",
    say("Before dawn, in your toga, you run from door to door. At each one you wait with the others to greet the great man, and are given the sportula: a little money instead of dinner."),
    timing("Get from one house to the next before the doors close.", hits=3, speed=1.2, zone=0.2,
           miss="The door is shut. The steward says come back tomorrow.", good=["In time.", "In time, just.", "In time."]),
    wage(1, per=1, say="A hundred farthings at each door that opens."),
    end("The poet Martial did this all his life, and hated it, and did it every morning. The toga is hot and the coins are small."),
)

S["salutatio_late"] = scene(
    "The great house", "The Caelian, AD 384",
    say("The noble's steward keeps the clients waiting in the street all morning. The noble has fifty servants and never learns a client's name."),
    still("Wait. Do not complain. Complaining gets your name crossed off.", secs=7, broke="The steward looks at you. You stand still.",
          done="At noon the steward says the master will not be receiving."),
    say("Ammianus writes: a man greeted warmly on his first visit is asked the next day who he is and where he comes from. After years, he is still a stranger."),
    end("You go home with nothing. Tomorrow you will come back, because there is nowhere else to go."),
)

S["salutatio_collapse"] = scene(
    "The empty house", "The Caelian, AD 455",
    say("Your patron's house is shut. He has gone to his estates in Sicily, or to Constantinople, before the Vandals come back."),
    say("His steward sells the furniture at the door to anyone who'll buy."),
    end("The bond of patron and client lasted a thousand years. It ended with a steward selling chairs."),
)

S["salutatio_fall"] = scene(
    "Where the house was", "The Caelian, AD 552",
    say("The house is a shell. Goats in the atrium. A family lives in the servants' rooms and has never heard of the Caecilii."),
    end("No patrons, no clients. There is the Church, and the Emperor's governor in Ravenna, and hunger."),
)

SCENES = S
