"""The regulars' stories across the ages (docs/rome-activities-plan.md, section 5): the same five
families (town.json's regulars: the Numisii Felices, bakers; the soldiers who become gladiators; the
Caecilii, senators; the Fabiae, fishwives; the barbers from Sicily), each with a small task in each age
they live in. Done in order, they complete each family's voices in the collections.

A quest: {regular, age, title, steps, reward, voice}. Steps:
  {"talk": line, "hint": text}                    talk to the regular (their words are `line`)
  {"go": [east, north] | monument id, "name": place, "line": what you find, "hint": text}
                                                  walk there
  {"scene": scene}                                a scene, played at once
  {"bring": thing, "line": their words, "hint": text}  bring them a thing (it is taken)
The first step is always a talk. `give` on a talk step hands you a thing.
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, typing, pick, gain, pay, iff, play, scene)


def talk(line, hint, **extra):
    s = {"talk": line, "hint": hint}
    s.update(extra)
    return s


def walk(to, name, line, hint):
    return {"go": to, "name": name, "line": line, "hint": hint}


def bring(thing, line, hint):
    return {"bring": thing, "line": line, "hint": hint}


def play_scene(title, where, *steps):
    return {"scene": scene(title, where, *steps)}


Q = {}

# ---------- the bakers: the Numisii Felices ----------

Q["baker_heroic"] = {"regular": "baker", "age": "heroic", "title": "The harvest before the levy", "steps": [
    talk("The levy's called for Pyrrhus and my boys are going. The barley's standing in my four iugera outside the Colline Gate. Would you give me a day? I can't pay much. I can feed you.",
         "Go out to Numisius's field by the Colline Gate."),
    walk([520, 1060], "Numisius's field by the Colline Gate", "The barley is gold and heavy. His wife and his youngest are already cutting.",
         "Numisius's field, out by the Colline Gate, where the Quirinal meets the wall."),
    play_scene("The harvest", "Outside the Colline Gate, 280 BC",
               say("His wife hands you a sickle. The boys will march in two days."),
               timing("Reap, in rhythm with the others.", hits=4, speed=0.9, zone=0.22, miss="You nick your hand. Keep going.",
                      good=["A swathe.", "Another.", "Nearly.", "The last of it."]),
               hold("Bind the sheaves and stand them up to dry.", secs=4.0, done="The field is in by sunset."),
               end("His wife gives you bread and a cup of wine sitting on the sheaves. You can see the city from here, small on its hills.")),
    talk("The barley's in and the boys are off to the legion with full bellies. That's a thing done right. Come to supper when they're home.",
         "Tell Numisius the barley is in."),
], "reward": {"fides": 2, "give": "a loaf"}, "voice": "Numisius: the barley in before the levy."}

Q["baker_early"] = {"regular": "baker", "age": "early", "title": "Bread for the widow", "steps": [
    talk("There's a widow on the Aventine, Sempronia. Husband and two sons at Cannae. She won't take charity. She'll take bread from me, if you say it's owed. Tell her Felix owes her husband for flour. He didn't, but tell her.",
         "Take Felix's bread to the widow Sempronia on the Aventine.", give="a loaf"),
    walk([-330, -880], "the widow Sempronia's door on the Aventine", "A small house near the Temple of Diana. An old woman at the door with a grandson.",
         "Sempronia's house, on the Aventine near the Temple of Diana."),
    play_scene("The widow", "The Aventine, 201 BC",
               say("She looks at the loaf, and at you. \"Felix owes my husband nothing. My husband owed Felix.\""),
               ask("She knows. What do you say?",
                   opt("\"Take it for the boy.\"", say="She looks at her grandson. She takes it.", take="a loaf"),
                   opt("\"Felix says it's owed. I wouldn't argue with Felix.\"", say="She almost smiles. \"Nobody argues with Felix.\" She takes it.", take="a loaf")),
               end("\"Tell him the boy will carry a shield for Rome one day,\" she says. \"Tell him that's what his bread is for.\"")),
    talk("She took it? Good. We don't talk about what we lost. We feed what's left. That's all.", "Tell Felix the widow took the bread."),
], "reward": {"fides": 2}, "voice": "Felix: bread for the widow of Cannae."}

Q["baker_republic"] = {"regular": "baker", "age": "republic", "title": "The midwife", "steps": [
    talk("It's my girl. The baby's coming and it's wrong, too early. The midwife Sosia lives on the slope below the Aventine by the Circus. Run. Tell her Felix will pay anything.",
         "Run to the midwife Sosia, by the Circus below the Aventine."),
    walk([-240, -560], "the midwife Sosia's door by the Circus", "An old Greek woman, already putting on her cloak when she sees your face.",
         "Sosia's house, at the foot of the Aventine by the Circus Maximus."),
    play_scene("The midwife", "By the Circus, about 50 BC",
               ask("\"Felix? The baker? He pays in bread,\" she says. \"I need coin first. Three sestertii. I've been cheated before.\"",
                   opt("Pay her yourself", pay=2, need={"price": 2}, say="She takes it and goes at a run, faster than you.", fides=2,
                       ledger="Paid the midwife for a neighbour's daughter.", ledger_key="midwife"),
                   opt("Swear on your own head that Felix will pay", say="She looks at you, and goes. Your word, this time, was enough.", fides=1),
                   opt("Tell her it can wait until morning", say="She shrugs, and shuts the door.", fides=-3,
                       ledger="Told the midwife it could wait.", ledger_key="midwife")),
               end("You run back behind her through the dark streets.")),
    talk("The boy lived. She... didn't. Gods. Fourteen. The boy lived. I'll bake at night now. I don't want to think.",
         "Go back to Felix."),
], "reward": {"fides": 1}, "voice": "Felix: the night of the midwife."}

Q["baker_empire"] = {"regular": "baker", "age": "empire", "title": "The name in marble", "steps": [
    talk("Four generations in this bakery. I want the name over the door in marble: NUMISIUS FELIX, PISTOR. The marble yards are down at the river port. Get me a good price.",
         "Buy a marble lintel with the name cut, at the marble yards by the river port."),
    walk([-560, -700], "the marble yards at the river port", "Blocks from every province stacked on the wharves: Carrara white, Numidian yellow, green from Sparta.",
         "The marble yards on the wharves of the river port, below the Aventine."),
    play_scene("The marble", "The river port, about AD 150",
               say("A mason's agent will cut a lintel with the name, in good letters."),
               play("haggle", win="bought", lose="none", buying=True, item="a marble lintel", value=18),
               label("bought"), end("He'll deliver it on a cart tomorrow."),
               label("none"), end("You'll have to come back and try again.")),
    bring("a marble lintel", "There it is. NUMISIUS FELIX. It'll outlast the lot of us. That's what marble's for.",
          "Bring Felix the lintel."),
], "reward": {"fides": 1, "dignitas": 1}, "voice": "Felix: the name in marble over the door."}

Q["baker_late"] = {"regular": "baker", "age": "late", "title": "The oven tax", "steps": [
    talk("The Prefect's office says the bakery owes arrears on the oven: the state's flour we were short-weighted, and they say we owe for it. If I don't pay, my sons are flogged. Go and see what can be done. I've this much.",
         "Go to the Prefect's office in the Forum about the Felix oven.", give="a purse for the Prefect"),
    walk([30, 60], "the Prefect's office", "Clerks, petitioners, a queue out into the rain.", "The Prefect's office, by the Senate House in the Forum."),
    play_scene("The arrears", "The Prefect's office, AD 384",
               ask("The clerk reads it out. \"The arrears are what they are.\" He looks at the purse. It isn't enough.",
                   opt("Pay what she sent, and the rest yourself", pay=6, need={"price": 6}, take="a purse for the Prefect", fides=2,
                       say="He writes a receipt. The Felix oven is clear, this year.", ledger="Paid the Felix oven's arrears.", ledger_key="oven_tax"),
                   opt("Pay what she sent and bribe him for the rest", take="a purse for the Prefect", pay=2, need={"price": 2}, fides=-1,
                       say="He takes the purse and the extra and writes \"paid\". It isn't, anywhere but here.",
                       ledger="Bribed a clerk over a bakery's arrears.", ledger_key="oven_tax"),
                   opt("Pay what she sent and beg for time", take="a purse for the Prefect",
                       say="He writes \"part\". The rest will come due, with interest, and the whips.")),
               end("The law binds her family to the oven, and the oven to the state, and the state to nobody.")),
    talk("It's done, for this year. Next year it'll be something else. My grandmother's grandfather put his name up in marble. I'd put it in the river, some days.",
         "Go back to Numisia."),
], "reward": {"fides": 1}, "voice": "Numisia: the oven tax."}

Q["baker_collapse"] = {"regular": "baker", "age": "collapse", "title": "Her son in the guard", "steps": [
    talk("My son is in the palace guard now, with the Goths. Better paid than the Emperor. He hasn't been home since the Vandals. Go up to the palace gate and ask for Numisius. Tell him his mother's alive.",
         "Find Numisia's son in the guard at the palace gate on the Palatine."),
    walk([140, -330], "the palace gate on the Palatine", "Guards in trousers and fur, talking their own language.", "The palace gate, up on the Palatine."),
    play_scene("The guard", "The Palatine, AD 455",
               say("A young man comes out when you ask for Numisius. He has a Gothic name now, Vitalis, and his hair long, and he laughs when you say his mother."),
               ask("\"Tell her I'm alive,\" he says. \"And tell her not to come here.\" He gives you coins for her.",
                   opt("Take the coins to her", give="coins for Numisia", say="They're good gold. He's doing well."),
                   opt("Tell him to come home himself", say="\"Home?\" He laughs again, not unkindly. \"There isn't one.\" He gives you the coins anyway.",
                       give="coins for Numisia")),
               end("He goes back through the gate. Nobody from the palace ever goes down to the Subura except to collect.")),
    bring("coins for Numisia", "Gold. He sends gold. He was a baker's son. Well. He's alive. That's more than the oven is.",
          "Take his coins to Numisia."),
], "reward": {"fides": 1}, "voice": "Numisia: her son in the barbarians' guard."}

Q["baker_fall"] = {"regular": "baker", "age": "fall", "title": "The last Felix", "steps": [
    talk("There's an old man in that doorway, where the bakery was. Felix, he calls himself. He died in the night. Nobody will bury him. Help me carry him?",
         "Help Iohannes bury the old man in the bakery doorway."),
    play_scene("The last Felix", "The Subura, AD 552",
               hold("Carry him with Iohannes to the burial ground by the church.", secs=5.0, done="He weighs nothing. Nobody does, this year."),
               say("There is no stone. Iohannes finds a broken tile."),
               typing("FELIX", secs=20, good="You scratch the name into the tile.", fair="You scratch it, crookedly.", bad="You scratch something."),
               end("Four hundred years of bread. A tile.")),
    talk("There. He's with the rest of his family now, wherever they are. Nobody else would have. Thank you, stranger.",
         "Go back to Iohannes."),
], "reward": {"fides": 2}, "voice": "Iohannes: the last Felix buried."}

# ---------- the soldiers, who become gladiators ----------

Q["gladiator_heroic"] = {"regular": "gladiator", "age": "heroic", "title": "Against the elephants", "steps": [
    talk("Pyrrhus has elephants. None of us has ever seen one. We're drilling on the Campus against a wooden one on wheels. Come and throw a spear. You'll laugh.",
         "Go to the drill on the Campus Martius."),
    walk([-700, 420], "the drill ground on the Campus", "A great wooden beast on a cart, painted grey, with a straw man on top.", "The drill ground on the Campus Martius."),
    play_scene("The drill", "The Campus Martius, 280 BC",
               pick("Pomponius asks: where do you throw the javelin at an elephant?", ["At the driver on its back", "At its tusks", "At its feet"], 0,
                    yes="\"The driver. Kill him and the beast's just a frightened cow.\"", no="\"The driver. Kill him and the beast's just a frightened cow.\""),
               timing("Throw at the straw driver as the cart is pushed past.", hits=3, speed=1.2, zone=0.18, miss="Wide.",
                      good=["Hit!", "Hit!", "Down he goes."]),
               end("The whole century cheers every hit. Then they go home and sleep and march out in the morning.")),
    talk("See? It's just a big animal with a Greek on it. We'll manage. We always do.", "Go back to Pomponius."),
], "reward": {"fides": 1, "dignitas": 1}, "voice": "Pomponius: drilling against the elephant."}

Q["gladiator_early"] = {"regular": "gladiator", "age": "early", "title": "The land grant", "steps": [
    talk("Scipio promised us land for Africa: two iugera for every year served. My papers are to go to the treasury clerks under the Temple of Saturn. My legs aren't what they were. Would you?",
         "Take Varenus's papers to the treasury under the Temple of Saturn.", give="Varenus's papers"),
    walk({"monument": "saturn", "at": [-76, 40]}, "the treasury under the Temple of Saturn", "Clerks at tables among the strongboxes.",
         "The treasury, under the Temple of Saturn at the foot of the Capitol."),
    play_scene("The treasury", "The Temple of Saturn, 201 BC",
               pick("The clerk counts: sixteen years' service, the last years in Africa. Two iugera for each year of it. What does Varenus get?",
                    ["Thirty-two iugera", "Sixteen iugera", "Two iugera"], 0, yes="\"Thirty-two, in Apulia.\" He writes it.",
                    no="The clerk corrects you: thirty-two iugera, in Apulia."),
               gain(take="Varenus's papers"),
               end("The clerk stamps it. No fee, no bribe. The Republic pays what it owes its soldiers. For now.")),
    talk("Thirty-two iugera. My father had four. I'll grow old in Apulia, looking at the sea Hannibal came from.", "Go back to Varenus."),
], "reward": {"fides": 1}, "voice": "Varenus: the land grant for Africa."}

Q["gladiator_republic"] = {"regular": "gladiator", "age": "republic", "title": "The wooden sword", "steps": [
    talk("One more fight, the fifteenth, and they give me the wooden sword and I'm free. It's in the Forum, at a senator's funeral games. Come and shout for me. The crowd decides.",
         "Go to the games in the Forum and shout for Hilarus."),
    walk([10, -10], "the funeral games in the Forum", "Wooden stands round the pit. The sand is already dark in places.", "The Forum, where the games are."),
    play_scene("The fifteenth fight", "The Forum, about 50 BC",
               say("Hilarus the Thracian against a big Gaul. It is long. Hilarus goes down on one knee and lifts a finger."),
               ask("The giver of the games looks at the crowd. You're near the front.",
                   opt("\"Mitte!\" Let him go!", say="You shout it until your throat hurts. Others take it up. The thumb goes the right way."),
                   opt("Say nothing", say="The crowd is divided. The giver of the games takes his time. Then he lets him live.")),
               say("He's given the wooden sword. He holds it up to the stands with the hand that won't close."),
               end("Free. Crippled, forty, and free.")),
    talk("Free. I'll open a tavern in the Subura. You'll drink for nothing there, as long as I live. Hang the sword over the bar.",
         "Go back to Hilarus."),
], "reward": {"fides": 1}, "voice": "Hilarus: the wooden sword."}

Q["gladiator_empire"] = {"regular": "gladiator", "age": "empire", "title": "Hilarus's tavern", "steps": [
    talk("My grandfather drank at Hilarus's tavern in the Subura, where the old Thracian's wooden sword hung over the bar. Is it still there? Go and look, would you? I'd like to know it is.",
         "Find the old tavern of Hilarus in the Subura."),
    walk([580, 300], "the tavern of Hilarus in the Subura", "A low door, a painted sign of a Thracian's shield.", "The tavern, deep in the Subura on the Clivus Suburanus."),
    play_scene("The tavern", "The Subura, about AD 150",
               say("The wooden sword hangs over the bar, black with smoke. The keeper is the old gladiator's great-grandson."),
               play("tali", win="won", lose="lost", line="He challenges you to knucklebones for a drink: house rules.", stake=1),
               label("won"), end("\"Hilarus would have liked you,\" he says. \"He liked winners. He was one, once.\""),
               label("lost"), end("\"Hilarus always lost at the bones,\" the keeper says. \"Won everything else.\"")),
    talk("Still there. Good. Some things last. Not us, we don't last. But the sword over the bar.", "Go back to Callistus."),
], "reward": {"fides": 1}, "voice": "Callistus: the sword over the bar."}

Q["gladiator_late"] = {"regular": "gladiator", "age": "late", "title": "Nicias and the priest", "steps": [
    talk("I want to be baptised. My wife is. The priest at the church of the Subura says a man who trains men for the arena can't be. Ask him for me. I can't ask. He looks at me.",
         "Ask the priest at the church in the Subura about Nicias."),
    walk([700, 100], "the church on the Oppian", "A converted house, a painted cross, a priest sweeping.", "The church on the Oppian, above the Subura."),
    play_scene("The priest", "The Oppian, AD 384",
               say("The priest listens. \"He must give up the arena, all of it, the training too. That is the rule. It is a school of murder.\""),
               ask("\"And what will he live on?\" you ask. The priest says:",
                   opt("Hear him out", say="\"The Church will find him work. It is not much. It is clean.\"")),
               end("He gives you his blessing for Nicias, and a warning.")),
    talk("Give it up. All of it. Well. I've given up worse. Men I knew. I'll go and see him.", "Go back to Nicias."),
], "reward": {"fides": 1}, "voice": "Nicias: the last gladiator trainer goes to be baptised."}

# ---------- the senators: the Caecilii ----------

Q["senator_heroic"] = {"regular": "senator", "age": "heroic", "title": "The silver salt cellar", "steps": [
    talk("Fabricius, the censor-to-be, struck a man off the Senate for owning ten pounds of silver plate. I have one silver salt cellar, my grandmother's. It shames me. Take it to the treasury as a gift for the war, will you?",
         "Take Caecilius's silver salt cellar to the treasury under the Temple of Saturn.", give="a silver salt cellar"),
    walk({"monument": "saturn", "at": [-76, 40]}, "the treasury under the Temple of Saturn", "The quaestors' clerks, the strongboxes, the bronze tablets of the law.",
         "The treasury under the Temple of Saturn."),
    play_scene("The gift", "The Temple of Saturn, 280 BC",
               ask("The clerk weighs it. A pound of silver, for Rome.",
                   opt("Give it for the war", take="a silver salt cellar", say="He writes Caecilius's name in the list of gifts. The list is long.",
                       ledger="Carried a senator's silver to the treasury for the war.", ledger_key="salt_cellar"),
                   opt("Keep it and tell him you gave it", take="a silver salt cellar", coin=6, fides=-5,
                       say="You sell it in the Subura. Nobody will ever know. You will.",
                       ledger="Kept a senator's gift for the war.", ledger_key="salt_cellar")),
               end("Rome's treasury is a room of bronze and a little silver. Rome's wealth is its farmers.")),
    talk("Good. Now my table has clay on it like every other Roman's. It's a relief, honestly.", "Go back to Caecilius."),
], "reward": {"fides": 1, "dignitas": 1}, "voice": "Caecilius: the silver given for the war."}

Q["senator_early"] = {"regular": "senator", "age": "early", "title": "The letter from Greece", "steps": [
    talk("A Greek merchant at the river port has a letter for me, he says: from my nephew. We refused to ransom the prisoners of Cannae. Hannibal sold them. To Greece. Bring it to me.",
         "Fetch the letter from the Greek merchant at the river port."),
    walk([-560, -700], "the Greek merchant's ship at the river port", "A Rhodian ship unloading wine. The merchant has been expecting you.",
         "The river port, below the Aventine, where the Greek ships tie up."),
    play_scene("The merchant", "The river port, 201 BC",
               ask("\"The young man is a slave in Achaea,\" the merchant says. \"He paid me to bring it. It's still a coin for the carriage.\"",
                   opt("Pay for it", pay=1, need={"price": 1}, give="a letter from Greece", say="He hands you a folded tablet."),
                   opt("Say the senator will pay him", give="a letter from Greece", say="\"A Caecilius's word is good,\" he says, and hands it over.")),
               end("The tablet is sealed with a slave's thumbprint.")),
    bring("a letter from Greece", "\"...my master is not cruel. I work in his olive press. I think of the Forum every day.\" The law was right. Rome does not buy back men who surrender. He is my brother's son.",
          "Bring Caecilius the letter."),
], "reward": {"fides": 1}, "voice": "Caecilius: the letter from the slave in Greece."}

Q["senator_republic"] = {"regular": "senator", "age": "republic", "title": "The purse for the divisor", "steps": [
    talk("My son stands for the praetorship. There's a man at the voting pens on the Campus, a divisor, who'll see that the Pollian tribe votes as it should. Take him this. Don't open it.",
         "Take Caecilius's purse to the divisor at the voting pens on the Campus.", give="a heavy purse"),
    walk([-600, 520], "the voting pens on the Campus", "The divisor is where he said, sitting on an upturned bucket, affable.",
         "The voting pens on the Campus Martius."),
    play_scene("The divisor", "The Campus Martius, about 50 BC",
               ask("He holds out his hand.",
                   opt("Give him the purse", take="a heavy purse", say="He weighs it, and nods. The Pollian tribe will vote as it should.",
                       ledger="Carried a bribe for a senator's son's election.", ledger_key="divisor"),
                   opt("Keep it", take="a heavy purse", coin=15, fides=-6, say="You walk on past him. You are rich for a day, and a Caecilius's enemy for life.",
                       ledger="Stole a senator's bribe money.", ledger_key="divisor"),
                   opt("Throw it at his feet and walk away", take="a heavy purse", fides=1, say="He picks it up without surprise. He has seen honest men before, and outlived them.",
                       ledger="Delivered a bribe, and refused to be part of it.", ledger_key="divisor")),
               end("There are forty such men at the pens. Everyone knows. It is illegal. It is how things are done.")),
    talk("He took it? Then my son is a praetor, and I'm in debt for twenty years. You're a useful man. Come to my door at dawn.",
         "Go back to Caecilius Rufus."),
], "reward": {"dignitas": 1}, "voice": "Caecilius Rufus: the purse for the Pollian tribe."}

Q["senator_empire"] = {"regular": "senator", "age": "empire", "title": "A gift for the freedman", "steps": [
    talk("My cousin opened his veins. I will not follow him. There is an imperial freedman, the Emperor's secretary for petitions, who likes Corinthian bronzes. Take him this lamp, with my respects, at the palace.",
         "Take Caecilius's bronze lamp to the Emperor's freedman at the palace on the Palatine.", give="a Corinthian bronze lamp"),
    walk([149, -380], "the palace on the Palatine", "Marble halls, guards, clerks, a hundred petitioners in the anteroom.", "The palace of the Caesars on the Palatine."),
    play_scene("The anteroom", "The palace, about AD 150",
               still("Wait in the anteroom until you are called. It may be hours.", secs=7, broke="A chamberlain frowns at you.",
                     done="You are called. The freedman is a Greek, charming, very rich."),
               gain(take="a Corinthian bronze lamp"),
               end("He admires the lamp. He says the Senator's loyalty is known. It is: that is what the lamp was for.")),
    talk("He took it. Then I shall die in my bed. A Caecilius used to command armies. We send lamps.", "Go back to Caecilius."),
], "reward": {"dignitas": 1}, "voice": "Caecilius Rufus: the lamp for the Emperor's freedman."}

Q["senator_late"] = {"regular": "senator", "age": "late", "title": "The Altar of Victory", "steps": [
    talk("Symmachus has written to the Emperor to have the Altar of Victory put back in the Senate House. There is a petition of senators. And the Christians have one against. Go to the Senate House and see the names. I want to know who signed which.",
         "Go to the Senate House and see who has signed for the Altar of Victory."),
    walk({"monument": "curia_julia", "at": [8, 80]}, "the Senate House", "The empty place where the Altar stood. Two clerks, two lists.", "The Senate House in the Forum."),
    play_scene("The two lists", "The Senate House, AD 384",
               say("\"Not by one road alone can one reach so great a mystery,\" Symmachus wrote. The bishop of Milan answered that there was one road."),
               ask("The clerks look at you. \"Will you sign?\"",
                   opt("Sign for the Altar", say="Your name goes under the old families'.", ledger="Signed for the Altar of Victory.", ledger_key="altar"),
                   opt("Sign against it", say="Your name goes under the Christian senators'.", ledger="Signed against the Altar of Victory.", ledger_key="altar"),
                   opt("Sign neither", say="You copy both lists of names, as you were asked.")),
               end("The Emperor will say no. The Altar will never come back.")),
    talk("So. Half of them I grew up with. My grandson will have to choose one road. I'm glad I won't see which.", "Go back to Caecilius Rufus."),
], "reward": {"dignitas": 1}, "voice": "Caecilius Rufus: the lists of the Altar of Victory."}

Q["senator_collapse"] = {"regular": "senator", "age": "collapse", "title": "The grandson on the Vandal ships", "steps": [
    talk("My grandson was in the city when the Vandals came. The house is paid for, but he's not in it. Go down to the river where they loaded the ships. Someone may have seen him.",
         "Ask at the river where the Vandals loaded their ships about Caecilius's grandson."),
    walk([-400, -280], "the river port where the Vandals loaded", "Broken crates, an overturned cart, people still searching.", "The river bank below the cattle market, where the Vandals loaded."),
    play_scene("The river", "The river port, AD 455",
               say("A woman who hid under the wharf saw them loading the captives: young men of good family went on the third ship. For Carthage."),
               say("In Carthage the bishop Deogratias is selling the church's gold and silver to ransom Roman captives, they say, and filling the churches with beds for them."),
               end("She won't take money for telling you. She takes bread.")),
    talk("Carthage. The bishop there is ransoming them. I'll send... what do I send? I have titles. I'll send the titles. No. I'll send the silver. What's left of it.",
         "Go back to Caecilius Rufus."),
], "reward": {"fides": 1}, "voice": "Caecilius Rufus: the grandson taken to Carthage."}

Q["senator_fall"] = {"regular": "senator", "age": "fall", "title": "The masks", "steps": [
    talk("In the atrium of my house on the Caelian there's a cupboard: the masks of my ancestors, six hundred years of consuls, in wax. The roof's gone. Bring them to me before the rain gets them.",
         "Fetch the Caecilii's ancestral masks from the ruined house on the Caelian."),
    walk([900, -480], "the house of the Caecilii on the Caelian", "No roof. Goats. In the atrium, a wooden cupboard, its doors warped shut.",
         "The Caecilii's house, on the Caelian."),
    play_scene("The cupboard", "The Caelian, AD 552",
               hold("Prise the cupboard open.", secs=3.0, done="Inside, the wax faces, each with its label: consul, censor, consul, triumphed over the Samnites."),
               say("Most of them have melted into each other in the summers since the roof fell. You can read three labels."),
               gain(give="the ancestors' masks", collect=["masks", "caecilii"]),
               end("You carry them out in your arms like children.")),
    bring("the ancestors' masks", "Three left you can read. Metellus, who went into the burning temple. Rufus, who was consul with Scipio. And... a consul, of the Samnite wars. That's enough. That's enough.",
          "Bring the masks to Caecilius."),
], "reward": {"fides": 2}, "voice": "Caecilius: the last of the masks."}

# ---------- the fishwives: the Fabiae ----------

Q["fishwife_heroic"] = {"regular": "fishwife", "age": "heroic", "title": "The first fish", "steps": [
    talk("The first fish of the morning goes to Father Tiber. My legs are bad today. Take it to the river's shrine by the island, will you? He likes it fresh.",
         "Take Fabia's first fish to the river's shrine by the island.", give="the first fish"),
    walk([-560, -150], "the river's shrine by the island", "A little altar at the water, green with the river, a few scales on it already.", "The river bank by the island."),
    play_scene("Father Tiber", "The Tiber, 280 BC",
               rite("Give it to the river.", ["Wash your hands in the river", "Lay the fish on the altar", "Say: Father Tiber, take this, and be kind"],
                    ["Throw the fish in", "Eat it"], restart="You start again. The river waits.", done="A heron watches from the island."),
               gain(take="the first fish"),
               end("The river is kind today. It isn't always.")),
    talk("Good. He'll keep my man safe with the army. He always has.", "Go back to Fabia."),
], "reward": {"fides": 1}, "voice": "Fabia: the first fish for the river."}

Q["fishwife_early"] = {"regular": "fishwife", "age": "early", "title": "Her son and the fleet", "steps": [
    talk("My boy wants the fleet, like his father. Take him his father's cloak, at the ship sheds on the Campus by the river, and tell him I said go with the gods.",
         "Take Fabia's husband's cloak to her son at the ship sheds on the Campus.", give="a sailor's cloak"),
    walk([-760, 180], "the ship sheds on the Campus", "The long sheds where the warships are hauled up. Boys everywhere, eager.", "The ship sheds by the river on the Campus Martius."),
    play_scene("The ship sheds", "The Campus Martius, 201 BC",
               ask("Her son is fourteen and all elbows. He sees the cloak and knows it.",
                   opt("Give him the cloak and her blessing", take="a sailor's cloak", say="He puts it on. It is too big. He will grow into it."),
                   opt("Tell him the fleet is full", take="a sailor's cloak", fides=-2, say="He doesn't believe you. He goes the next day anyway.",
                       ledger="Lied to a boy to keep him from the fleet.", ledger_key="fleet_boy")),
               end("He will row against Philip of Macedon. He will come home, mostly.")),
    talk("He took it. Of course he took it. What else would a Roman boy do? I'll leave two fish for the river tomorrow.", "Go back to Fabia."),
], "reward": {"fides": 1}, "voice": "Fabia: the cloak for the fleet."}

Q["fishwife_republic"] = {"regular": "fishwife", "age": "republic", "title": "The moneylender", "steps": [
    talk("The lender's coming at dusk with his men, and it's not the money he wants now, it's my girl. Take her to your house, keep her there tonight. Please.",
         "Take Fabia's daughter to your house in the Subura, and keep her safe."),
    walk("room", "your house", "The girl sits in the kitchen with her knees up, not crying. Chrysis gives her bread.", "Your house in the Subura, on the Argiletum."),
    play_scene("The knock", "Your house, about 50 BC",
               still("Men on the stairs. A knock. Keep still, both of you.", secs=8, broke="The girl gasps. You hold your breath.",
                     done="The steps go away down the stairs."),
               ask("In the morning the girl asks what she should do.",
                   opt("Go home to her mother", say="She goes. The lender won't come again for a while. He'll come again."),
                   opt("Give her money to get out of Rome", pay=5, need={"price": 5}, fides=2, say="She goes to an aunt in Ostia.",
                       ledger="Paid for a girl to get away from a moneylender.", ledger_key="fabia_girl")),
               end("The law says the lender can take her in payment. He almost never needs the law.")),
    talk("She's safe. For now. I'll sell the stall if I have to. I'd sell the river.", "Go back to Fabia."),
], "reward": {"fides": 2}, "voice": "Fabia Tertulla: the night of the moneylender."}

Q["fishwife_empire"] = {"regular": "fishwife", "age": "empire", "title": "The foundling", "steps": [
    talk("Another baby by the bridge this morning, left in a basket. Alive. Nobody wants it. There's the milk column in the vegetable market, where they leave them for the wet nurses. Or... take it somewhere.",
         "Take the foundling to the milk column in the vegetable market.", give="a baby in a basket"),
    walk([-420, -120], "the milk column in the vegetable market", "A column by the Temple of Piety. Two baskets at its foot already.", "The vegetable market (Forum Holitorium), by the river."),
    play_scene("The milk column", "The vegetable market, about AD 150",
               ask("A woman is looking at the baskets. She could be a slave dealer's buyer, or a childless wife. You can't tell.",
                   opt("Leave the baby at the column", take="a baby in a basket", say="The woman lifts the basket and looks. She takes it. You will never know which she was.",
                       ledger="Left a foundling at the milk column.", ledger_key="foundling"),
                   opt("Ask her who she is first", take="a baby in a basket", fides=1, say="A fuller's wife, childless, from the Esquiline. She takes it and holds it the right way.",
                       ledger="Found a home for a foundling.", ledger_key="foundling")),
               end("Many Roman fathers expose a child they don't want. The law doesn't mind. The river minds, sometimes.")),
    talk("Better than the river. Everything's better than the river.", "Go back to Fabia."),
], "reward": {"fides": 1}, "voice": "Fabia Procula: the foundling by the bridge."}

Q["fishwife_late"] = {"regular": "fishwife", "age": "late", "title": "Wine for the river", "steps": [
    talk("The priest scolded me for pouring wine in the river. I'm baptised. But the river's older than any god. You're not a Christian, are you? Pour it for me, by the island, where I can't be seen.",
         "Pour Fabia's wine for the river by the island.", give="a cup of wine"),
    walk([-560, -150], "the river by the island", "The old altar is gone. The water is the same.", "The river bank by the island."),
    play_scene("The river", "The Tiber, AD 384",
               hold("Pour it slowly into the water.", secs=3.0, done="The red goes into the brown and away."),
               gain(take="a cup of wine"),
               end("A fisherman in a boat sees you, and nods, as if you'd done something ordinary.")),
    talk("Thank you. Don't tell the priest. He's a good man. The river doesn't know that.", "Go back to Fabia Maria."),
], "reward": {"fides": 1}, "voice": "Fabia Maria: wine for the river, in secret."}

Q["fishwife_collapse"] = {"regular": "fishwife", "age": "collapse", "title": "Her daughter", "steps": [
    talk("My daughter's in the Subura at night. She feeds us. Find her. I don't know what I want you to say. Just see she's alive.",
         "Find Fabia's daughter in the Subura."),
    walk([560, 330], "a doorway in the Subura", "She is sixteen and painted and very tired.", "A doorway in the Subura, off the Clivus Suburanus."),
    play_scene("The doorway", "The Subura, AD 455",
               ask("\"She sent you?\" the girl says. \"Tell her there's bread on Thursday.\"",
                   opt("Give her money", pay=3, need={"price": 3}, fides=1, say="She takes it without looking at it. \"It's still Thursday,\" she says."),
                   opt("Tell her to come home", say="\"And eat what?\""),
                   opt("Just tell her her mother asked", say="She looks at the street for a long time.")),
               end("A priest passes and doesn't look. A Gothic soldier passes and does.")),
    talk("She's alive. That's all I asked. That's all anyone asks now.", "Go back to Fabia."),
], "reward": {"fides": 1}, "voice": "Fabia: her daughter in the Subura."}

Q["fishwife_fall"] = {"regular": "fishwife", "age": "fall", "title": "Fire for the water", "steps": [
    talk("The river water gives the fever unless it's boiled. There's no wood. The old Forum's full of roof beams if you can pull them out. Bring me some. For the children.",
         "Pull old beams out of the Forum's ruins for Maria."),
    walk([30, 40], "the ruins in the Forum", "Fallen roofs, half-burnt beams under the rubble.", "The ruins of the Forum."),
    play_scene("The beams", "The Forum, AD 552",
               hold("Drag a beam out of the rubble.", secs=4.0, done="It comes, with a shower of plaster painted with a garland."),
               gain(give="firewood"),
               end("You carry it on your shoulder past the Senate House.")),
    bring("firewood", "A beam from the Forum. My grandmother's grandmother sold fish to the men who sat under that roof. Now it boils water for her great-great-grandchildren. It's something.",
          "Bring Maria the wood."),
], "reward": {"fides": 2}, "voice": "Maria: fire from the Forum's roofs."}

# ---------- the barbers from Sicily ----------

Q["barber_heroic"] = {"regular": "barber", "age": "heroic", "title": "The razors", "steps": [
    talk("My razors want the smith's stone. There's a smith up the Argiletum. Take them? The young men all want shaving since my father came, and the old ones glare at me.",
         "Take the barber's razors to the smith up the Argiletum.", give="a bundle of razors"),
    walk([250, 240], "the smith up the Argiletum", "A forge, a boy at the bellows, the smith like an oak.", "The smith's forge, up the Argiletum toward the Subura."),
    play_scene("The whetstone", "The Argiletum, 280 BC",
               timing("Turn the whetstone while the smith holds the blades.", hits=3, speed=1.0, zone=0.22, miss="Sparks.",
                      good=["Sharp.", "Sharper.", "Like the wind."]),
               gain(take="a bundle of razors", give="sharp razors"),
               end("\"A Roman with his face shaved,\" the smith says. \"What next. Greek hats?\"")),
    bring("sharp razors", "Beautiful. Now let the old senators glare. In fifty years they'll all be shaved.", "Bring the razors back to the barber."),
], "reward": {"fides": 1}, "voice": "The barber: razors for a people of beards."}

Q["barber_early"] = {"regular": "barber", "age": "early", "title": "Thanks to the Twins", "steps": [
    talk("I've decided to stay in Rome. They keep their word here. I want to give thanks to Castor and Pollux, the Twins who stood by Rome at Lake Regillus. Take this to their temple? I'm a Sicilian; I don't know the Roman way of it.",
         "Make an offering for Menas at the Temple of Castor and Pollux.", give="a honey cake"),
    walk({"monument": "castor", "at": [41, -30]}, "the Temple of Castor and Pollux", "The Twins' temple by the spring of Juturna, where they watered their horses after the battle.",
         "The Temple of Castor and Pollux, in the Forum by the spring."),
    play_scene("The Twins", "The Temple of Castor, 201 BC",
               rite("Offer it the Roman way.", ["Veil your head", "Lay the cake on the altar", "Say: for Menas, who stays"],
                    ["Uncover your head", "Eat the cake"], restart="The keeper corrects you, kindly. Again.", done="The keeper nods."),
               gain(take="a honey cake"),
               end("A Sicilian barber, thanking Rome's gods for letting him stay. The keeper has seen many.")),
    talk("Done the Roman way? Good. I'll be buried here, then. That's settled.", "Go back to Menas."),
], "reward": {"fides": 1}, "voice": "Menas: thanks to the Twins for Rome."}

Q["barber_republic"] = {"regular": "barber", "age": "republic", "title": "The man two chairs down", "steps": [
    talk("A young man in my chair this morning said things about Pompey. Loud. The man two chairs down heard, and he sells what he hears. The young man's gone to the Basilica Aemilia. Warn him?",
         "Warn the young man at the Basilica Aemilia."),
    walk({"monument": "basilica_aemilia", "at": [41, 40]}, "the Basilica Aemilia", "Bankers' tables, lawyers, idlers. You find him laughing with friends.",
         "The Basilica Aemilia, on the Forum."),
    play_scene("The warning", "The Basilica Aemilia, about 50 BC",
               ask("He's young and doesn't think anyone matters but him.",
                   opt("Warn him", fides=2, say="He laughs, then stops laughing. He leaves by the back."),
                   opt("Sell him to the listener yourself", coin=5, fides=-4, say="You find the man from the barber's and tell him the name. He pays.",
                       ledger="Sold a man's careless words.", ledger_key="sold_words")),
               end("Everyone in Rome is listened to by someone. Everyone knows it. Nobody stops talking.")),
    talk("You warned him? You're a strange one. Sit. The shave's free.", "Go back to Stephanus."),
], "reward": {"fides": 1}, "voice": "Stephanus: the man two chairs down."}

Q["barber_empire"] = {"regular": "barber", "age": "empire", "title": "The informer's list", "steps": [
    talk("They say there's a list of the next men to be accused, posted where the informers meet by the Senate House. They say my name's on it. I complained about the tax. Go and look? I can't.",
         "See if Stephanus's name is on the informers' list by the Senate House."),
    walk({"monument": "curia_julia", "at": [8, 70]}, "the Senate House", "A wax board on a pillar, names on it. Men reading it who pretend not to.",
         "The Senate House in the Forum."),
    play_scene("The list", "The Senate House, about AD 150",
               say("His name is on it: STEPHANUS, TONSOR, SUBURA. And a charge: words against the Emperor's majesty."),
               ask("The informer is standing near, a well-fed man. He sees you reading.",
                   opt("Pay him to rub it out", pay=10, need={"price": 10}, fides=1, say="He rubs it out with his thumb. He's done this before. It's his business.",
                       ledger="Bought a man's name off the informers' list.", ledger_key="informer_list"),
                   opt("Go and warn Stephanus to leave Rome", say="You walk away quickly.")),
               end("The Emperor is mild. The informers are not the Emperor.")),
    talk("Then I'll go to my brother in Ostia tonight. My father's chair, and his father's. Someone else will sit in it. Thank you. I mean it.",
         "Go back to Stephanus."),
], "reward": {"fides": 2}, "voice": "Stephanus the younger: his name on the list."}

Q["barber_late"] = {"regular": "barber", "age": "late", "title": "Stay a while", "steps": [
    talk("Sit. Let me shave you. There are fewer people to talk to every year, and I've four hundred years of this chair to tell someone.",
         "Sit in Stephanus's chair."),
    play_scene("The chair", "The Subura, AD 384",
               still("Keep still while he shaves you. Very still.", secs=8, broke="\"Still!\" The razor stops.",
                     done="He finishes, and wipes the blade, and talks."),
               say("\"The first barber in Rome came from Sicily. My family. They shaved the men who beat Pyrrhus, and Hannibal. They shaved Caesar's soldiers. An emperor's secretary once. And monks now.\""),
               end("\"When I'm gone, nobody will remember any of it. So now you do.\"")),
    talk("There. You'll remember it. That's enough for a barber.", "Talk to Stephanus again."),
], "reward": {"fides": 1}, "voice": "Stephanus: four hundred years in the chair."}

QUESTS = Q

for qid, q in Q.items():
    assert "talk" in q["steps"][0], qid
