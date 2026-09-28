"""What you gather in Rome (docs/rome-activities-plan.md, 3.12 and 7): the heroes' stories, the
inscriptions read in each age, a coin of each age, the ancestors' masks, and the regulars' voices.
Each complete set brings a piece of Rome back to the Nexus.

Also the scenes that gather them: reading an inscription where it stands (inscription_<id>), and
looking at the coin in your purse in each age (purse_<age>).
"""

from .common import say, end, pick, gain, scene
from . import exempla, quests

AGES = ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]

# Inscriptions: id -> name, where (map position, or a monument), the ages you can read it in, the
# words, and a line on what they say.
INSCRIPTIONS = {
    "lapis_niger": {"name": "the Black Stone", "at": [-40, 60], "ages": ["heroic", "early", "republic"],
                    "text": "QUOI HON... SAKROS ES... RECEI... KALATOREM",
                    "note": "Under a black stone in the Comitium, the oldest writing in Rome, running up and down like a plough: whoever harms this place is cursed, it says, and it names a king. Nobody can quite read it any more."},
    "tables": {"name": "the Twelve Tables", "at": [-50, 28], "ages": ["heroic", "early", "republic"],
               "text": "SI IN IUS VOCAT, ITO. NI IT, ANTESTAMINO. IGITUR EM CAPITO.",
               "note": "The law of Rome on bronze by the Rostra: if a man is summoned to court, he shall go. If he does not go, let a witness be called; then let him be seized. Schoolboys learn it by heart."},
    "graffito": {"name": "a wall in the Subura", "at": [520, 350], "ages": ["republic", "empire"],
                 "text": "VOTE FOR GAIUS JULIUS POLYBIUS FOR AEDILE: HE BRINGS GOOD BREAD. / SUCCESSUS THE WEAVER LOVES THE INNKEEPER'S SLAVE GIRL. / I AM AMAZED, O WALL, THAT YOU HAVE NOT FALLEN DOWN UNDER SO MUCH WRITING.",
                 "note": "Election notices painted in red, scratched over with jokes, insults, love and prices. These very lines turn up on the walls of Pompeii; the walls of Rome say the same. Everyone reads a little, and everyone writes on walls."},
    "pantheon": {"name": "the Pantheon's porch", "monument": "pantheon", "at": [-688, 690], "ages": ["empire", "late", "collapse", "fall"],
                 "text": "M·AGRIPPA·L·F·COS·TERTIVM·FECIT",
                 "note": "Marcus Agrippa, son of Lucius, consul for the third time, made this. Hadrian rebuilt the whole temple, and put Agrippa's name back on it, not his own."},
    "titus": {"name": "the Arch of Titus", "monument": "titus", "at": [273, -150], "ages": ["empire", "late", "collapse", "fall"],
              "text": "SENATUS POPULUSQUE ROMANUS DIVO TITO DIVI VESPASIANI F. VESPASIANO AUGUSTO",
              "note": "The Senate and People of Rome, to the deified Titus. Inside the arch, in relief, his soldiers carry the candlestick from the Temple of Jerusalem in triumph."},
    "trajan_column": {"name": "the base of Trajan's Column", "monument": "trajan_column", "at": [-75, 385], "ages": ["empire", "late", "collapse", "fall"],
                      "text": "...AD DECLARANDUM QUANTAE ALTITUDINIS MONS ET LOCUS TANTIS OPERIBUS SIT EGESTUS",
                      "note": "The column is as tall as the hill that was dug away to make the Forum, the inscription says. The most beautiful letters ever cut in Rome."},
    "severus": {"name": "the Arch of Septimius Severus", "monument": "sep_severus", "at": [-41, 75], "ages": ["late", "collapse", "fall"],
                "text": "...OB REM PUBLICAM RESTITUTAM IMPERIUMQUE POPULI ROMANI PROPAGATUM...",
                "note": "For the Republic restored and the Empire extended. Look closely at the fourth line: the name of his son Geta has been chiselled out, after his brother had him killed, and new words cut over the holes."},
    "constantine": {"name": "the Arch of Constantine", "monument": "constantine", "at": [447, -250], "ages": ["late", "collapse", "fall"],
                    "text": "INSTINCTU DIVINITATIS MENTIS MAGNITUDINE",
                    "note": "By the prompting of the divinity and the greatness of his mind: which divinity, it does not say. Half the sculptures on it were taken from older monuments, emperors' heads recut as Constantine."},
    "damasus": {"name": "a martyr's verses", "at": [470, -890], "ages": ["late", "collapse", "fall"],
                "text": "HIC CONGESTA IACET QUAERIS SI TURBA PIORUM",
                "note": "Here lies, if you seek them, a crowd of the holy. Pope Damasus's verses for the martyrs, cut by his calligrapher Filocalus in letters no one had seen before, with little curls."},
    "saturn": {"name": "the Temple of Saturn's front", "monument": "saturn", "at": [-76, 40], "ages": ["late", "collapse", "fall"],
               "text": "SENATUS POPULUSQUE ROMANUS INCENDIO CONSUMPTUM RESTITUIT",
               "note": "The Senate and People of Rome restored what fire had consumed. The columns they put back were odd ones, taken from other buildings."},
    "phocas_hope": {"name": "a tile in a ruin", "at": [60, 10], "ages": ["fall"],
                    "text": "ROMA",
                    "note": "Someone has scratched the word on a broken tile and propped it up against a column. That is all."},
    "tomb_road": {"name": "a tomb on the road", "at": [470, -900], "ages": ["republic", "empire"],
                  "text": "STRANGER, WHAT I HAVE TO SAY IS SHORT: STAND AND READ IT. HERE IS THE UNLOVELY TOMB OF A LOVELY WOMAN. HER PARENTS NAMED HER CLAUDIA. SHE LOVED HER HUSBAND WITH HER HEART. SHE KEPT THE HOUSE. SHE WORKED THE WOOL. I HAVE SPOKEN. GO.",
                  "note": "Tombs line the roads out of Rome, and they talk to you as you pass: stranger, stop, read. It is the only way the dead can go on being in company."},
}

# The coin in your purse in each age.
COINS = {
    "heroic": "A heavy bronze as, cast in a mould, not struck, with a head on each side. It weighs as much as a small stone. Rome has only just begun to make money at all; your grandfather paid in lumps of bronze by weight.",
    "early": "A silver denarius, new since the war with Hannibal: helmeted Roma on the front and the Twins, Castor and Pollux, riding with their spears on the back. Nearly pure silver.",
    "republic": "A denarius. The young moneyers put their own ancestors on it now, to advertise the family: a triumph, a temple, a famous great-grandfather. It is still good silver.",
    "empire": "A brass sestertius of Antoninus: the Emperor's calm bearded head, and on the back a goddess with her attributes. The silver denarius beside it in your purse is about three parts silver in four, and falling.",
    "late": "A little bronze coin with the Emperor's head and a wash of silver that rubs off in a week. The gold solidus, seventy-two to the pound, is the only money anyone trusts. You have never held one.",
    "collapse": "A tiny bronze nummus, smaller than your fingernail, the Emperor's name round it and no one can read it. You need hundreds for a loaf.",
    "fall": "A big copper follis of the Emperor Justinian, marked M: forty nummi. Beside it, a copper of the Goth king Totila, struck in Rome, with his name: BADUILA. Two kings in one purse, and neither buys bread.",
}

SETS = {
    "exempla": {"name": "The exempla", "ids": list(exempla.EXEMPLA.keys()),
                "piece": "the statues", "line": "The heroes of Rome stand again by Rome's door in the Nexus."},
    "inscriptions": {"name": "The inscriptions", "ids": list(INSCRIPTIONS.keys()),
                     "piece": "the dedication", "line": "Rome's dedication is cut on its stone in the Nexus."},
    "coins": {"name": "The coins", "ids": AGES, "piece": "the treasury", "line": "Rome's treasury is back under its stone in the Nexus: seven coins, from bronze to nothing."},
    "masks": {"name": "The masks", "ids": ["metellus", "caecilii"], "piece": "the niches",
              "line": "The ancestors' masks hang in their niches in the Nexus."},
    "voices": {"name": "The voices", "ids": ["%s_%s" % (q["regular"], q["age"]) for q in quests.QUESTS.values()],
               "piece": "the choir", "line": "The voices of Rome's families sing together in the Nexus."},
}

S = {}
for iid, ins in INSCRIPTIONS.items():
    S["inscription_" + iid] = scene(
        "An inscription", ins["name"][0].upper() + ins["name"][1:],
        say(ins["text"]),
        say(ins["note"]),
        end("You say the words over to yourself, the way Romans read: aloud."),
        collect=["inscriptions", iid],
    )
for age, text in COINS.items():
    S["purse_" + age] = scene("The coin in your purse", "Your room", say(text), end("You put it back."), collect=["coins", age])

SCENES = S

SPOTS = []
for iid, ins in INSCRIPTIONS.items():
    sp = {"scene": "inscription_" + iid, "text": "Read %s" % ins["name"], "at": ins["at"], "ages": ins["ages"], "id": "inscription_" + iid}
    if "monument" in ins:
        sp["monument"] = ins["monument"]
    SPOTS.append(sp)
