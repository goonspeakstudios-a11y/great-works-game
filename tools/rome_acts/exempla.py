"""The exempla: the heroes' stories, where they happened (docs/rome-activities-plan.md, 4 Era I and 3.12).
In the age of heroes the great ones are played (exemplum_<id>); in every age each is told by someone at
its place (tell_<id>_<age>), in the manner of that age: proudly by the farmers of 280 BC, to recruits
in 201 BC, in a candidate's speech in 50 BC, by a guide at a statue under the Empire, as a schoolboy's
exercise in AD 384, for a coin in AD 455, half-remembered in AD 552. Hearing or playing one adds it
to the collection of exempla.

Sources: Livy 1.13 (the Sabine women), 2.10 (Horatius), 2.12 (Scaevola), 2.13 (Cloelia), 3.26
(Cincinnatus), 5.27 (Camillus and the schoolmaster), 7.6 (Curtius), 8.7 (Torquatus), 8.9 (the devotio);
Plutarch, Pyrrhus 19-21 (Appius, Fabricius); Cicero, On Old Age 55 and Plutarch, Cato 2 (Curius);
Cicero, On Duties 3.99-100 (Regulus); Livy 1.57-59 (Lucretia).
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, pick, gain, iff, scene)

AGES = ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]

# id: name, where (map [east, north]), the story told in two or three lines, a question on it, and
# whether it is played in the age of heroes.
EXEMPLA = {
    "horatius": {"name": "Horatius at the bridge", "at": [-540, -490], "played": True,
                 "story": "Porsenna's Etruscans took the Janiculum and came down on the wooden bridge. Horatius Cocles held its far end, alone at the last, while the Romans cut it down behind him. When it fell he prayed to Father Tiber and swam home in his armour through their spears.",
                 "ask": ["What did he hold the bridge for?", ["Long enough for the bridge to be cut down behind him", "To win a crown", "To kill the king"], 0]},
    "scaevola": {"name": "Mucius Scaevola", "at": [-500, -460], "played": True,
                 "story": "Gaius Mucius crossed to Porsenna's camp to kill the king, and killed his secretary by mistake. Before the king, threatened with fire, he thrust his right hand into the altar flames and held it there. The king let him go. They called him Scaevola, left-handed.",
                 "ask": ["What did Mucius tell the king?", ["That three hundred young Romans had sworn to do what he had tried", "That he was sorry", "That Rome would pay"], 0]},
    "cloelia": {"name": "Cloelia", "at": [250, -150], "played": True,
                "story": "Cloelia, a girl given as a hostage to Porsenna, slipped out of his camp and led the other girls across the Tiber, swimming, under his spears. He demanded her back, and then honoured her, and let her choose half the hostages to go free. She chose the young boys. Her statue on horseback stands at the top of the Sacred Way.",
                "ask": ["Whom did she choose to set free?", ["The youngest boys", "Her friends", "The strongest men"], 0]},
    "sabines": {"name": "The Sabine women", "at": [-20, -10], "played": True,
                "story": "The Romans had carried off the Sabines' daughters for wives. When the Sabines came to take them back and the armies met in the Forum, the women ran between the lines with their hair loose and their babies in their arms, and begged their fathers and their husbands not to kill each other. The two peoples became one.",
                "ask": ["What did the women ask?", ["To turn their anger on them, not on each other", "To be taken home", "To be paid"], 0]},
    "curtius": {"name": "Marcus Curtius", "at": [18, 8], "played": True,
                "story": "A chasm opened in the Forum, and the seers said it must be given what Rome's strength was made of. Marcus Curtius, a young soldier, said Rome's strength was arms and courage, and rode into it in full armour. It closed over him. The pool of Curtius marks the place.",
                "ask": ["What did he say Rome's strength was?", ["Arms and courage", "Gold", "The gods"], 0]},
    "decius": {"name": "Decius Mus", "at": [-700, 380], "played": True,
               "story": "When the line broke at Veseris, the consul Decius Mus vowed himself and the enemy's army to the gods below, with the pontiff's words, and rode alone into the Latins. His son did the same against the Gauls at Sentinum. The legions won both times.",
               "ask": ["Whom did Decius give to the gods below with himself?", ["The enemy's army", "His son", "His horse"], 0]},
    "appius": {"name": "Appius Claudius the Blind", "at": [-45, 75], "played": True,
               "story": "When King Pyrrhus offered peace after beating the legions, the Senate was ready to take it. Old Appius Claudius, blind, was carried into the Senate House by his sons, and said Rome would not talk peace while a foreign army stood in Italy. The Senate sent the king's ambassador home.",
               "ask": ["What did Appius say he now wished?", ["That he were deaf as well as blind", "That he were young", "That he had never built his road"], 0]},
    "fabricius": {"name": "Fabricius and the King", "at": [60, 45], "played": True,
                  "story": "King Pyrrhus offered Fabricius gold, and he would not take it. Next day the King hid his biggest elephant behind a curtain and had it drawn back, and the beast trumpeted over Fabricius's head. He did not move. \"Your gold did not move me yesterday,\" he said, \"nor does your beast today.\"",
                  "ask": ["What did Fabricius do when the King's own doctor offered to poison him?", ["Sent the King a letter warning him", "Paid the doctor", "Nothing"], 0]},
    "curius": {"name": "Curius and his turnips", "at": [520, 700], "played": True,
               "story": "The Samnites sent envoys with gold to Manius Curius, who had beaten them. They found him at his hearth, roasting turnips. He sent them away: it was no glory to have gold, he said, but to rule those who had it.",
               "ask": ["Where did the envoys find him?", ["At his hearth, cooking turnips", "In the Senate House", "At the baths"], 0]},
    "cincinnatus": {"name": "Cincinnatus at the plough", "at": [-560, -300], "played": False,
                    "story": "When an army was trapped by the Aequi, the Senate's envoys found Cincinnatus ploughing his four acres across the Tiber. His wife brought his toga; they named him dictator. He saved the army, triumphed, and gave up his power on the sixteenth day, and went back to his plough.",
                    "ask": ["How long did he keep the power he was given?", ["Sixteen days", "Sixteen years", "For life"], 0]},
    "camillus": {"name": "Camillus and the schoolmaster", "at": [-150, 140], "played": False,
                 "story": "Besieging Falerii, Camillus was brought the town's noble boys by their schoolmaster, who had led them out to sell them. Camillus had the traitor stripped, his hands tied, and gave the boys rods to whip him home. Falerii surrendered, beaten by Roman good faith.",
                 "ask": ["What conquered Falerii?", ["Roman good faith", "Hunger", "A trick"], 0]},
    "torquatus": {"name": "Manlius Torquatus", "at": [-560, 520], "played": False,
                  "story": "The consul Manlius Torquatus forbade single combat. His son, challenged, fought and won. The father had his son beheaded before the army, for disobeying. From then on, Livy says, the orders of a Manlius were a byword for grim discipline.",
                  "ask": ["What did his son do wrong?", ["He fought against orders", "He ran", "He lost"], 0]},
    "regulus": {"name": "Regulus", "at": [-30, 70], "played": False,
                "story": "Taken by the Carthaginians, Regulus was sent to Rome on his oath to argue for an exchange of prisoners. He argued against it in the Senate, and then, keeping his oath, went back to Carthage, knowing they would kill him. They did.",
                "ask": ["Why did he go back?", ["He had sworn to", "He was afraid", "He had family there"], 0]},
    "lucretia": {"name": "Lucretia and Brutus", "at": [60, -40], "played": False,
                 "story": "Lucretia, raped by the king's son, told her husband and her father, made them swear vengeance, and killed herself. Brutus drew the knife from her body and swore on it to drive out the kings. Rome has had no king since.",
                 "ask": ["What did Brutus swear on the knife?", ["To drive the kings out of Rome", "To kill the king's son", "To become king"], 0]},
}

FRAME = {
    "heroic": "An old farmer tells it, as if it were his grandfather's story. Perhaps it was.",
    "early": "A centurion tells it to recruits the way it has always been told, to make men of them.",
    "republic": "A candidate tells it from the steps, in the middle of a speech about himself.",
    "empire": "A statue with an inscription; a guide tells it to visitors from Gaul, who are more impressed than the Romans.",
    "late": "A schoolmaster sets it as an exercise: praise the hero in a hundred words. The boys yawn.",
    "collapse": "A guide tells it for a coin, and gets the ending wrong, and nobody minds.",
    "fall": "An old man half remembers it. He isn't sure it happened in Rome.",
}
AFTER = {
    "heroic": "\"That's who we are,\" he says. He means it as a plain fact.",
    "early": "The recruits are quiet afterwards. They believe it. They are about to find out whether they are it.",
    "republic": "The crowd applauds the candidate. He has just said that he is that kind of man.",
    "empire": "The Emperor put the statue up. The heroes serve the Emperor now.",
    "late": "One boy writes that the hero would be a saint now. The master gives him a good mark.",
    "collapse": "The guide asks for another coin for the moral.",
    "fall": "\"Something like that,\" he says. \"It was a long time ago.\"",
}

S = {}
for eid, e in EXEMPLA.items():
    q = e["ask"]
    for age in AGES:
        S["tell_%s_%s" % (eid, age)] = scene(
            e["name"], "Where it happened",
            say(FRAME[age]),
            say(e["story"]),
            pick(q[0], q[1], q[2]),
            end(AFTER[age]),
            collect=["exempla", eid],
        )

# ---------- played in the age of heroes ----------

S["exemplum_horatius"] = scene(
    "Horatius at the bridge", "The Sublician bridge, as the old men tell it",
    say("The Janiculum has fallen. The Etruscans are coming down to the bridge at a run. The guards drop their shields and run past you into the city."),
    ask("You are Horatius Cocles. Two men have stayed with you: Spurius Lartius and Titus Herminius.",
        opt("\"Cut the bridge down behind us. We'll hold this end.\"", say="Behind you, the axes start.")),
    timing("The first Etruscans come at you on the narrow bridge. Take their blows on your shield.", hits=3, speed=1.1, zone=0.22,
           miss="A spear scrapes your helmet.", good=["Held.", "Held.", "Held."], spare=4),
    ask("The bridge is nearly cut. Send your two companions back while there's still a plank to cross?",
        opt("\"Go! Now!\"", say="Lartius and Herminius run back over the last timbers. You are alone.")),
    hold("Hold the bridge alone. Glare at the Etruscan nobles one by one, and dare them.", secs=5.0,
         done="They hesitate. Nobody wants to be first. Then the spears come, and stick in your shield."),
    say("With a crash the bridge goes into the river behind you. A cheer goes up from the Roman bank."),
    rite("Pray, before you jump.", ["Father Tiber", "holy one", "receive these arms", "and this soldier", "in your kindly stream"],
         ["and this gold", "angry river"], restart="The words matter. Begin again.", done="You jump, armour and all."),
    hold("Swim for the Roman bank through the spears.", secs=5.0, done="You climb out on the Roman side, alive."),
    end("The city gives you as much land as you can plough round in a day, and puts your statue in the Comitium. Everyone gives you what food they can spare, though they are hungry."),
    collect=["exempla", "horatius"],
)

S["exemplum_scaevola"] = scene(
    "Mucius Scaevola", "Porsenna's camp across the Tiber, as the old men tell it",
    say("The city is besieged and starving. You are Gaius Mucius, a young noble. The Senate has let you go: across the river, into the enemy's camp, a knife under your tunic."),
    still("Wait in the crowd round the king's tribunal. Don't draw attention.", secs=5.0, broke="A soldier glances at you. You look away.",
          done="It's pay day. Two men sit on the tribunal, dressed alike, handing out the soldiers' pay."),
    say("You don't dare ask which is the king. You strike the one who seems to give the orders."),
    say("It is the king's secretary. The guards seize you and drag you before Porsenna."),
    ask("\"Who are you?\" the king says.",
        opt("\"I am a Roman citizen. My name is Gaius Mucius.\"",
            say="\"I came to kill my enemy, and I am as ready to die as to kill. To act and to suffer bravely is the Roman way.\"")),
    say("The king, furious and frightened, orders fires lit round you, to make you tell him what plots there are."),
    hold("You thrust your right hand into the fire on the altar. Hold it there.", secs=8.0,
         done="You hold it there as if you felt nothing. The king jumps up from his seat."),
    say("\"Go,\" says Porsenna. \"You are braver against yourself than against me.\""),
    ask("As a return for his mercy, you tell him:",
        opt("\"Three hundred of us have sworn to do what I tried, one after another.\"",
            say="The king sends ambassadors to Rome to make peace.")),
    end("You have lost your right hand's use. Rome calls you Scaevola: left-handed. Your family will carry the name for centuries."),
    collect=["exempla", "scaevola"],
)

S["exemplum_cloelia"] = scene(
    "Cloelia", "Porsenna's camp by the Tiber, as the old men tell it",
    say("You are Cloelia, a girl of a good family, given to King Porsenna as a hostage for the peace. His camp is by the Tiber."),
    still("At night, lead the other girls past the guards. Slowly. Not a sound.", secs=6.0, broke="A guard stirs. Everyone freezes.",
          done="You are at the bank."),
    hold("Swim, and bring them with you across the Tiber, under the spears.", secs=6.0, done="On the Roman bank, every girl alive."),
    say("The king is furious and demands you back. Rome sends you back, keeping faith. The king is so impressed he honours you, and lets you choose half the hostages to set free."),
    ask("Whom do you choose?",
        opt("The youngest boys", say="The ones most in danger. Everyone agrees you chose well.", fides=1),
        opt("Your friends", say="That is not what the story says she did. But it's what you did."),
    ),
    end("They put up a statue of you on horseback at the top of the Sacred Way: a thing never before given to a woman."),
    collect=["exempla", "cloelia"],
)

S["exemplum_sabines"] = scene(
    "The Sabine women", "The Forum valley, as the old men tell it",
    say("You are a Sabine woman, carried off by the Romans a year ago, and a Roman wife now, with a baby. Your father's army and your husband's army are killing each other in the marshy valley between the hills."),
    hold("Let your hair down, take the baby, and run out between the lines.", secs=5.0, done="The spears stop."),
    ask("Everyone is looking at you. Whom do you speak to?",
        opt("Your father", say="\"Don't make me a widow. Don't make my son an orphan.\""),
        opt("Your husband", say="\"Don't kill my father. Don't make me an orphan.\""),
        opt("Both", say="\"If you hate this marriage, turn your anger on us. We are the cause of the war. Better we die than live without one of you.\""),
    ),
    say("The shouting dies. The generals come forward. They make peace, and more than peace: one people, two kings, one city."),
    end("The valley where they fought will be drained and paved. It will be the Forum."),
    collect=["exempla", "sabines"],
)

S["exemplum_curtius"] = scene(
    "Marcus Curtius", "The Forum, as the old men tell it",
    say("The ground of the Forum has opened: a chasm, and no one can fill it. The seers say it must be given whatever Rome's strength is made of, if the Republic is to last."),
    pick("You are Marcus Curtius, a young soldier. What is Rome's strength made of?",
         ["Arms and courage", "Gold and silver", "Grain"], 0,
         yes="Nothing is more Roman than arms and courage.", no="You think again. Arms and courage."),
    say("You arm yourself fully, mount your horse, and face the temples and the Capitol. You raise your hands to the gods above and the gods below."),
    hold("Ride into the chasm.", secs=4.0, done="The crowd throws offerings and grain in after you. The earth closes."),
    end("The spot is called the pool of Curtius. People throw coins in it for luck, a thousand years later."),
    collect=["exempla", "curtius"],
)

S["exemplum_decius"] = scene(
    "The devotion of Decius Mus", "The battle at Veseris, as the veterans tell it",
    say("You are the consul Publius Decius Mus. Your wing is breaking. You shout for the pontiff Marcus Valerius: \"We need the gods' help. Tell me the words to devote myself for the legions.\""),
    rite("He tells you what to do. Do it in its order.",
         ["Put on your purple-bordered toga", "Veil your head", "Put your hand under the toga to your chin", "Stand on a spear laid under your feet"],
         ["Take off your helmet", "Kneel"], restart="The pontiff: \"Again, and exactly.\"", done="You are ready."),
    rite("Say the gods' names after him, in their order.",
         ["Janus", "Jupiter", "Father Mars", "Quirinus", "Bellona", "the Lares", "the new gods", "the gods of this land",
          "the gods of the dead"],
         ["Venus", "Apollo"], restart="A slip. From the beginning.",
         done="\"...I devote the legions and the auxiliaries of the enemy, with myself, to the gods of the dead and to Earth.\""),
    hold("Gird your toga the Gabine way, mount, and ride into the thick of the enemy.", secs=5.0,
         done="You are seen by both armies, more than a man, sent from heaven to turn the gods' anger onto the enemy."),
    end("You fall under a cloud of spears. Where you fell, the Latins break. Forty-five years later your son will do the same at Sentinum, and his son, they say, at Asculum."),
    collect=["exempla", "decius"],
)

S["exemplum_appius"] = scene(
    "Appius Claudius the Blind", "The Senate House, 280 BC",
    say("Pyrrhus has beaten the legions at Heraclea. His ambassador Cineas is in Rome, charming the senators, offering peace and gifts. The Senate is ready to accept."),
    say("Old Appius Claudius, who built the road to Capua and the first aqueduct, is blind and has not left his house in years. He sends for his litter."),
    hold("Help his sons carry him through the Forum to the Senate House.", secs=4.0, done="The Senate falls silent as he is carried in."),
    say("\"Until now I have been sorry I was blind. Now I wish I were deaf too. Where is that talk of Rome's glory? Let the King go home, and then we will talk of peace.\""),
    ask("The Senate votes. How do you vote?",
        opt("No peace while the King is in Italy", say="The Senate sends Cineas home with that answer.",
            ledger="Voted with Appius: no peace while the enemy stood in Italy.", ledger_key="appius"),
        opt("Take the peace", say="You are outvoted, almost alone. Cineas goes home and tells the King the Senate is an assembly of kings.",
            ledger="Voted to take Pyrrhus's peace.", ledger_key="appius"),
    ),
    end("Cineas tells Pyrrhus that fighting the Romans is like fighting the Hydra: for every army cut down, another grows."),
    collect=["exempla", "appius"],
)

S["exemplum_fabricius"] = scene(
    "Fabricius and the King", "King Pyrrhus's tent, as the old men tell it",
    say("You are Gaius Fabricius, come to the King about the prisoners. You are poor, and he knows it."),
    ask("The King has gold set before you. \"A gift, between friends.\"",
        opt("Refuse it", say="\"If I am honest, why would you want to corrupt me? If I am not, why would you want me?\""),
        opt("Take it", say="That is not the story. But it is what you did. The King smiles: now he knows what Rome costs.", fides=-5,
            ledger="Took King Pyrrhus's gold.", ledger_key="fabricius_gold", then="took"),
    ),
    say("Next day the King receives you again. Behind a curtain, unseen, stands his largest elephant."),
    still("The curtain is drawn back. The elephant raises its trunk over your head and trumpets. Do not move.", secs=6.0,
          broke="You flinch. You gather yourself and stand still again.",
          done="You turn to the King, smiling. \"Your gold did not move me yesterday, nor does your beast today.\""),
    end("Later the King's own doctor will offer to poison him. You will send the King a letter to warn him. He will release his Roman prisoners without ransom."),
    label("took"),
    end("The gold is heavy. You will be a rich man, and no one will ever tell your story."),
    collect=["exempla", "fabricius"],
)

S["exemplum_curius"] = scene(
    "Curius and his turnips", "A farmhouse, as the old men tell it",
    say("You are Manius Curius, who has beaten the Samnites and the Sabines and triumphed twice. You live on a small farm and do your own work."),
    timing("Roast turnips in the embers of your hearth.", hits=2, speed=0.8, zone=0.25, miss="Burnt at the edge. You eat it anyway.",
           good=["Soft.", "Done."]),
    say("Samnite envoys arrive with a great weight of gold, to win you over."),
    ask("They set it down by your hearth.",
        opt("Send them away", say="\"I would rather rule men who have gold than have it myself. Take it home.\""),
        opt("Offer them a turnip", say="They take one, puzzled, and go home with the gold.", fides=1),
    ),
    end("Cato, a hundred years from now, will visit the little house and go home and dig his own garden."),
    collect=["exempla", "curius"],
)

SCENES = S

SPOTS = []
for eid, e in EXEMPLA.items():
    told = [a for a in AGES if not (e["played"] and a == "heroic")]
    if e["played"]:
        SPOTS.append({"scene": "exemplum_" + eid, "text": "Stand where %s happened" % e["name"], "at": e["at"], "ages": ["heroic"],
                      "id": "exemplum_" + eid})
    SPOTS.append({"scene": "tell_" + eid, "text": "Hear the story of %s" % e["name"], "at": e["at"], "ages": told, "id": "tell_" + eid})
