"""The ten scripted sites of Rome, each through its seven states (docs/rome-city-notes.md 2.1):
what stands there in each age, how it looks ("variant", read by kit_urbs.build), and the note the
player reads there. Merged into content/rome/city.json as each monument's "states" (and the
Sublician bridge's), keyed by the age id. The general rule (from, ruin, gone) still decides the
ages a site is present in; a state here overrides it for that age, and its note replaces the
monument's note in that age.

    python3 tools/make_rome_sites.py
"""

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
CITY = os.path.join(ROOT, "content", "rome", "city.json")

AGES = ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]

# New monuments the sites need (the Comitium and the Cloaca's mouth), the Forum's furniture (the
# things that were not buildings: the Lacus Curtius, the fig, Duilius's column, the Golden
# Milestone, the statues on columns), and the age of heroes' twenty structures (notes 2.3).
# Added if missing; their place and years are this file's.
NEW = [
    {"id": "comitium", "name": "the Comitium", "kind": "comitium", "at": [-36, 46], "face": 200, "from": -700,
     "note": "The Comitium: the stepped hollow before the Senate House where the people met in assembly."},
    {"id": "cloaca", "name": "the mouth of the Great Drain", "kind": "cloaca", "at": [-502, -392], "face": 265, "from": -600,
     "note": "The mouth of the Cloaca Maxima, where the drain the Tarquins built comes out into the Tiber."},
    # the Forum's furniture
    {"id": "lacus_curtius", "name": "the Lacus Curtius", "kind": "lacus", "at": [12, -14], "face": 0, "from": -700, "ruin": 455,
     "note": "A fenced pit in the middle of the Forum with an altar and a well-head, and three stories: a chasm opened here and Marcus Curtius rode into it in full armour, since Rome's best thing was arms and a brave man; or a Sabine, Mettius Curtius, floundered here in the marsh; or lightning struck. Every year the people throw a coin in for the Emperor's health.",
     "fall": "A ring of stones in the grass where the pit was. The last coins in it are Justinian's."},
    {"id": "ficus", "name": "the fig of the Forum", "kind": "fig", "at": [-22, 38], "face": 0, "from": -700, "ruin": 455,
     "note": "The Ficus Ruminalis: a fig planted in the Comitium as the image of the one by the river under which the wolf suckled Romulus and Remus, the bronze wolf and twins beneath it, the twins added in 296 BC. When it withers it is an omen, and the priests plant another.",
     "fall": "A dead fig stump in the Comitium's grass. The bronze wolf was carried off, or is in the Lateran; nobody is sure which."},
    {"id": "columna_rostrata", "name": "the column of Duilius", "kind": "beak_column", "at": [-50, 44], "face": 0, "from": -260, "ruin": 455,
     "note": "The Columna Rostrata: a column by the Rostra hung with the bronze beaks of the Carthaginian ships Gaius Duilius took at Mylae in 260 BC, the first sea victory Rome ever won, with a fleet built in sixty days on the model of a wrecked Punic ship. Its inscription, in the old spelling, counts the ships and the gold. He was allowed a torch-bearer and a flute-player to walk him home from dinner for the rest of his life."},
    {"id": "milliarium", "name": "the Golden Milestone", "kind": "milliarium", "at": [-74, 30], "face": 0, "from": -20, "ruin": 455,
     "note": "The Milliarium Aureum, set up by Augustus in 20 BC when he took charge of the roads: a marble column sheathed in gilt bronze, with the distances to the great cities of the Empire cut on it. Every road begins here; every milestone counts from it."},
    {"id": "forum_statues", "name": "the statues of the Forum", "kind": "statues", "at": [30, 18], "face": 180, "from": -320, "ruin": 455, "count": 5,
     "note": "Bronzes of consuls and generals on columns along the Forum's edge, set up by the Senate for a victory or by a family for itself. By 158 BC there were so many that the censors cleared every one the Senate had not voted; they came back. Under the emperors an honorific statue was the Senate's gift and the Emperor's, and few dared to put up their own.",
     "fall": "Empty column bases along the Forum's edge; the bronzes went to the melting pot in the sieges, and their inscriptions are the only thing left of the men."},
    # the age of heroes' twenty structures
    {"id": "carcer", "name": "the Prison (Carcer)", "kind": "hall", "at": [-90, 90], "face": 150, "size": 0.6, "from": -640, "ruin": 550,
     "note": "The Carcer under the Capitol, the Tullianum below it: a round vault of tufa with a spring in the floor, cut in the rock by King Servius Tullius, entered by a hole in the ceiling. Not a prison for keeping people: a place for waiting for execution. Jugurtha starved here; Vercingetorix was strangled here after Caesar's triumph. In another age it will be called Saint Peter's prison.",
     "fall": "The old prison under the Capitol, now a church, Saint Peter in Prison; the spring still runs in its floor."},
    {"id": "ara_maxima", "name": "the Great Altar of Hercules", "kind": "altar_open", "at": [-250, -380], "face": 0, "from": -700, "ruin": 400,
     "note": "The Ara Maxima in the cattle market: the altar of Hercules, who killed the giant Cacus on the Aventine and recovered his stolen cattle here. The oldest cult in Rome, older than the city, kept by the Potitii and Pinarii until the state took it over; merchants tithe their profits to it; women may not attend and dogs are kept away.",
     "fall": "A block of tufa in the cattle market, the altar of a god nobody sacrifices to."},
    {"id": "lupercal", "name": "the Lupercal", "kind": "cave", "at": [10, -300], "face": 350, "from": -800,
     "note": "The wolf's cave at the foot of the Palatine, where the she-wolf suckled the twins. On the fifteenth of February the Luperci, young men naked but for goat-skins, sacrifice goats and a dog here, and run round the hill striking the women they meet with thongs of the skins, for fertility. Antony offered Caesar a crown here in 44 BC. It goes on under Christian emperors until a pope stops it in 494.",
     "fall": "A cave under the Palatine's rock. The Lupercalia was stopped fifty-eight years ago; the last runners were senators."},
    {"id": "casa_romuli", "name": "the Hut of Romulus", "kind": "hut", "at": [60, -330], "face": 20, "from": -750, "ruin": 455,
     "note": "The Casa Romuli on the Palatine's slope toward the Circus: a round hut of wattle and thatch, kept up as it was in the founder's day by the priests, and rebuilt in the same materials every time it burns, which is often. Under the emperors it is a shrine among marble palaces, and they keep it.",
     "fall": "A ring of stones where the hut of the founder stood until the last fire, which nobody rebuilt after."},
    {"id": "tarpeia", "name": "the Tarpeian Rock", "kind": "rock", "at": [-215, 40], "face": 160, "size": 1.0, "from": -800,
     "note": "The cliff of the Capitol above the Forum, named for the girl who let the Sabines in and was crushed under their shields. Traitors, perjurers and runaway slaves are thrown from it. Manlius, who saved the Capitol from the Gauls, was thrown from the rock he saved."},
    {"id": "scipios_tomb", "name": "the Tomb of the Scipios", "kind": "tomb", "tomb": "round", "at": [330, -1090], "face": 60, "from": -280,
     "note": "The family tomb of the Cornelii Scipiones, cut into the tufa just inside the Capene Gate where the Appian Way begins: Scipio Barbatus, consul of 298 BC, in his carved sarcophagus, and his sons and grandsons in their niches, each with his verses in the old letters. Africanus is not here; he died angry at Rome and lies at Liternum.",
     "fall": "A tomb cut in the rock by the old gate, its sarcophagi robbed. The letters on them are the oldest Latin verses that survive."},
    {"id": "salus", "name": "the Temple of Salus", "kind": "temple", "at": [400, 880], "face": 200, "size": 0.7, "from": -302, "ruin": 400,
     "note": "The temple of Safety (Salus) on the Quirinal, vowed in the Samnite war and dedicated in 302 BC. Gaius Fabius Pictor painted its walls, the first Roman to paint, and his family was ashamed of it for a century; the paintings lasted until Claudius' fire."},
    {"id": "jupiter_victor", "name": "the Temple of Jupiter the Victor", "kind": "temple", "at": [100, -470], "face": 300, "size": 0.65, "from": -295, "ruin": 400,
     "note": "Vowed by Quintus Fabius Rullianus at Sentinum in 295 BC, when the Samnites and Gauls together were beaten, and the consul Decius Mus devoted himself to death for the legions. On the Palatine's south brow, over the Circus."},
    {"id": "venus_obsequens", "name": "the Temple of Venus the Compliant", "kind": "temple", "at": [-120, -690], "face": 40, "size": 0.6, "from": -295, "ruin": 400,
     "note": "The first temple of Venus in Rome, by the Circus, built by Fabius Gurges out of the fines he collected from matrons convicted of adultery. It stands where the games of the Circus begin, and the girls of the city keep its festival in August."},
    {"id": "tellus", "name": "the Temple of Tellus", "kind": "temple", "at": [330, 180], "face": 250, "size": 0.65, "from": -268, "ruin": 400,
     "note": "The temple of the Earth (Tellus) on the Carinae, vowed in 268 BC in a battle with the Picentes during which the ground shook. It stands where the house of Spurius Cassius stood, pulled down when he was executed for aiming at kingship. A map of Italy is painted on its wall. The Senate met here on the day after Caesar's murder."},
    {"id": "juno_lucina", "name": "the Temple of Juno Lucina", "kind": "temple", "at": [700, 320], "face": 220, "size": 0.65, "from": -375, "ruin": 400,
     "note": "Juno who brings to light: the goddess of childbirth, on the Esquiline in her sacred grove, dedicated in 375 BC. On the first of March, the Matronalia, the married women of Rome climb here with their daughters and pray with their hair loose and every knot untied."},
    {"id": "mars_capena", "name": "the Temple of Mars", "kind": "temple", "at": [420, -1180], "face": 300, "size": 0.75, "from": -388, "ruin": 400,
     "note": "Mars outside the Capene Gate on the Appian Way, dedicated in 388 BC after the Gauls: the god of war kept outside the walls, as the old rule required. The army musters here before it marches out; the knights ride from here in July in their parade; the road from the gate to the temple was the first paved in Rome.",
     "fall": "Mars outside the gate, roofless. The road the army marched out on is grass between its stones."},
    {"id": "consus", "name": "the altar of Consus", "kind": "altar_open", "at": [130, -740], "face": 0, "from": -750, "ruin": 455,
     "note": "The buried altar of Consus, the god of the stored harvest, at the far turning post of the Circus, dug out only for his festival in August and December, when the horses and mules are garlanded and race, and the priests sacrifice on it. Romulus held his games for Consus here, and the Sabine women were carried off from them.",
     "fall": "A hollow at the end of the Circus's grass where an altar is buried. Nobody digs it out any more."},
    {"id": "honos_virtus", "name": "the Temple of Honour and Valour", "kind": "double_temple", "at": [470, -1020], "face": 320, "size": 0.35, "from": -222, "ruin": 400,
     "note": "Honos and Virtus by the Capene Gate: Marcellus, who took Syracuse in 212 BC, vowed a temple to both and the pontiffs would not let one temple hold two gods, so his son built two cells. Marcellus filled them with the statues of Syracuse, the first Greek art Rome ever saw, and old men complained of it for a generation."},
    {"id": "porticus_aemilia", "name": "the Porticus Aemilia", "kind": "portico", "at": [-560, -820], "face": 90, "size": 1.0, "from": -193, "ruin": 450,
     "note": "The Aemilian Portico by the river port, built by the aediles of 193 BC and rebuilt in 174: a warehouse of fifty vaulted bays of concrete, five hundred metres long, the biggest roof in the world, where the grain and wine and oil of the provinces land. The Emporium in front of it is the port of Rome.",
     "fall": "The great warehouse by the river port, its vaults standing, empty of everything but goats. The grain of Africa does not come."},
    {"id": "tower_capena", "name": "the towers of the Capene Gate", "kind": "tower", "at": [300, -1015], "face": 150, "from": -378, "ruin": 455,
     "note": "The Servian wall's towers at the Capene Gate, where the Appian Way leaves the city: tufa, from the wall built after the Gauls in 378 BC, ten metres high and four thick, with an aqueduct dripping over the gate since the Marcia was built, so that Juvenal calls it the wet gate. The wall has sixteen gates and the city is inside it, in the age of heroes and long after."},
    {"id": "tower_esquilina", "name": "the towers of the Esquiline Gate", "kind": "tower", "at": [1000, 490], "face": 240, "from": -378, "ruin": 455,
     "note": "The Servian wall's towers at the Esquiline Gate, on the city's east side, where the agger, the great earth rampart behind the wall, is highest: a hundred feet thick, with a ditch in front. The Sicilian slave leader Eunus, and Spartacus's men, and the Gauls were all expected here."},
]

# site id -> age id -> {state? (whole unless said), variant?, style? (a temple's), note}
SITES = {
    "rostra": {
        "heroic": {"variant": "beaks", "note": "The speakers' platform, faced with the bronze beaks of the ships taken at Antium in 338 BC, fifty-eight years ago. The consuls speak from it to the people gathered in the Comitium; the beaks are still bright, and the magistrates' bronze tablets hang beside them."},
        "early": {"variant": "beaks", "note": "The beaks of Antium have gone green. From here the Senate's decrees are read out; here the news of Zama was cried this autumn. Beside the platform stands the column of Duilius, hung with beaks too, for the first sea victory over Carthage in 260 BC."},
        "republic": {"variant": "beaks", "note": "Clodius's gangs and Milo's fought over this platform. The tribunes harangue from it; Cicero spoke here against Catiline and against Antony's friends; the heads of the proscribed were shown on it in Sulla's day. It still faces the Comitium, where the old assembly met."},
        "empire": {"variant": "caesar", "note": "Caesar moved the Rostra to this side of the Forum and Augustus finished it: a long platform faced with marble, the old beaks of Antium and the new ones of Actium fixed to its front. On it the statues of the emperors; behind it the Golden Milestone, from which the roads are measured."},
        "late": {"variant": "caesar", "note": "The Rostra of Augustus, patched with brick. Five column bases on it carry the statues of the Tetrarchs' jubilee. This year Symmachus, prefect of the city, sent from here to Milan his plea for the Altar of Victory, and Ambrose answered it."},
        "collapse": {"variant": "stripped", "note": "The beaks were prised off for their bronze in the fourteen days of the Vandals. Their sockets are empty holes in the marble. Nobody has spoken from here since the crowd stoned the Emperor Petronius Maximus in the street in May."},
        "fall": {"variant": "pulpit", "note": "A stump of brick and travertine with a wooden pulpit on it, from which a priest reads to the people who are left. No one remembers what the holes in its face once held."},
    },
    "saturn": {
        "heroic": {"variant": "etruscan", "note": "The Temple of Saturn, dedicated in 497 BC in the first years of the Republic: a tufa podium, a deep porch of painted wooden columns, a terracotta roof. Under the podium is the treasury of the Roman people (the aerarium): the state's silver, the legions' standards, and the bronze tablets of the laws."},
        "early": {"variant": "etruscan", "note": "The treasury under the temple is filling again: Carthage pays ten thousand talents over fifty years, and the first instalment came in this year. The quaestors go in and out with their ledgers. The old timber temple has been repaired, not replaced."},
        "republic": {"variant": "greek", "note": "The treasury of the Republic, in a temple faced with stucco to look like marble. Next year Caesar will break its doors to take the gold for his war, and the tribune Metellus who stood in front of them will be told to stand aside. Munatius Plancus is to rebuild the whole temple in marble out of his Gallic spoils."},
        "empire": {"variant": "greek", "note": "Plancus's marble temple of 42 BC, Ionic, on the Republic's old podium. The treasury under it is now the Senate's, since the emperor keeps his own fiscus; the standards and the tablets of the laws are still kept here."},
        "late": {"variant": "odd_columns", "note": "Burnt within living memory and rebuilt by the Senate: the porch's eight columns are second-hand, of grey and pink granite that do not match, and the inscription on the architrave admits it: THE SENATE AND PEOPLE OF ROME RESTORED WHAT FIRE CONSUMED."},
        "collapse": {"variant": "odd_columns", "note": "The mismatched porch stands. The Vandals took the doors for their bronze and the gilt from the pediment. The treasury under the podium is empty; there was nothing in it left to take."},
        "fall": {"state": "ruin", "variant": "kiln", "note": "The porch and its eight odd columns stand alone over an empty treasury. Beside the podium a lime kiln has been built, and its fuel is the temple's own marble, burnt for mortar."},
    },
    "comitium": {
        "heroic": {"variant": "assembly", "note": "The Comitium: the round stepped hollow before the Senate House where the people meet in their curiae, facing the Rostra, and where the praetor sits in judgment at the tribunal. In its pavement is the Black Stone, over an altar and an inscription in letters nobody can read any more."},
        "early": {"variant": "assembly", "note": "The assembly's hollow, its steps worn by two centuries of voting. The tribes vote in it by turns, facing the Senate House; the augurs take the sky from the templum on its north side. Here the people voted the peace with Carthage this year."},
        "republic": {"variant": "assembly", "note": "The old hollow, half given over to the crowd's daily business. A century ago the tribune Gaius Licinius turned the assembly round to face the Forum instead of the Senate, and the tribes vote in the open Forum now; the Comitium is where lawyers' clients wait. Caesar means to pave it."},
        "empire": {"variant": "paved", "note": "Paved over under Caesar and Augustus: the Rostra was moved, the Senate House rebuilt, and the Comitium is a square of travertine before it. The Black Stone is kept under a slab of black marble, sacred still, and nobody quite sure why: Romulus's grave, some say, or his foster-father's."},
        "late": {"variant": "paved", "note": "The square before the Senate House. The Black Stone's slab is still in the pavement; the prefect's honorific statues stand on it, and the Senate's decrees are posted on the wall."},
        "collapse": {"variant": "broken", "note": "The pavement is cracked and the statues are down; the Vandals' carts went over it, loaded with the bronze of the Capitol. The Black Stone's slab has been prised up by someone looking for treasure under it."},
        "fall": {"state": "ruin", "variant": "grass", "note": "Grass in the cracks of the pavement, goats on it. The Black Stone's slab has gone into a wall. Under the grass the altar and the old inscription are still there, and will be found in 1899."},
    },
    "circus": {
        "heroic": {"variant": "wood", "note": "The Circus Maximus in the valley between the Palatine and the Aventine: wooden stands on the two slopes, a track of packed earth, the turning posts at either end, and the buried altar of Consus at the far one. The Roman Games are run here in September, four-horse chariots for the god."},
        "early": {"variant": "wood", "note": "The starting gates were rebuilt in stone in 329 BC; the stands are still timber, put up and taken down. The Roman Games and the new Plebeian Games fill the valley. The seven eggs were set up on the barrier six years ago, one taken down for each lap."},
        "republic": {"variant": "stone", "note": "Caesar has had the track lengthened and a moat dug round it against the elephants of the beast hunts. The stands, stone below and timber above, hold a hundred and fifty thousand. The four colours race, Red, White, Green and Blue, and the city bets on them."},
        "empire": {"variant": "marble", "note": "Trajan's Circus, rebuilt in stone and marble after Nero's fire and Domitian's: three storeys of arches on the outside, a quarter of a million in the stands, the emperor's box on the Palatine side. Augustus's obelisk stands on the barrier among the shrines, the eggs and the bronze dolphins."},
        "late": {"variant": "marble", "note": "Still full on race days, which are many. Constantius set up the second obelisk on the barrier twenty-seven years ago, the tallest in the world, from Karnak. The charioteers are the most famous men in Rome, and the richest."},
        "collapse": {"variant": "cracked", "note": "The races went on the week after the Vandals left. The upper stands are cracked from the earthquake of 443, and one stretch of the Aventine side has fallen and been fenced off."},
        "fall": {"state": "ruin", "variant": "grass", "note": "Totila the Goth held races here in 549 for a few thousand people, the last in the records. Grass grows on the track; the stands are quarried for their stone; the two obelisks stand, and will fall, and be found in a garden in 1587."},
    },
    "cloaca": {
        "heroic": {"variant": "running", "note": "The mouth of the Great Drain (Cloaca Maxima), where the stream the Tarquins vaulted over comes out into the Tiber under an arch of tufa. It drains the Forum's marsh and the valley between the hills: the kings' greatest work, built by forced labour, and some say men hanged themselves rather than dig it."},
        "early": {"variant": "running", "note": "The Great Drain's mouth, running brown and loud. The censors let the contract for its cleaning; the aediles fine those who block it. Seven branches drain the city into it."},
        "republic": {"variant": "running", "note": "The mouth of the Cloaca, rebuilt in three rings of dressed peperino. In seventeen years Agrippa will go through the whole drain in a boat to inspect it, and pay for its cleaning himself."},
        "empire": {"variant": "running", "note": "The Cloaca's mouth, three rings of dressed stone, the water rushing out below the Temple of Hercules. Pliny wrote that it has stood seven hundred years against floods, earthquakes and the weight of the city on top of it."},
        "late": {"variant": "running", "note": "Still running: the drain is cleaned less often than it was, and the mouth is half silted. The prefect's office keeps a gang for it, when there is money."},
        "collapse": {"variant": "choked", "note": "Choked with the rubble of the sack: the water backs up into the Forum Boarium and stinks. Nobody is paid to clear it."},
        "fall": {"state": "ruin", "variant": "choked", "note": "The mouth is a cave of mud and reeds. The Forum's marsh is coming back: the low ground by the Senate House floods every winter, as it did before the kings."},
    },
    "curia_hostilia": {
        "heroic": {"note": "The Senate House of King Tullus Hostilius, on the north side of the Comitium: a plain hall of tufa where three hundred senators sit on benches, the consuls before them. The augurs' templum is beside it, and the painting of the victory over Carthage's ally Hiero, the first in Rome, will hang on its wall in sixteen years."},
        "early": {"note": "The Senate House. Here, this year, the terms of Carthage's peace were voted; here the senators sat through the news of Cannae fifteen years ago and did not leave the city, and here they thanked the consul Varro for not despairing of the Republic."},
        "republic": {"variant": "burnt", "note": "Burnt in 52 BC by Clodius's mob, who made it the pyre for his body. Faustus Sulla's rebuilding stands to the roof-beams. Caesar will pull it down and build his own Senate House next door, and the site will be a temple of Felicity, and then paved over."},
    },
    "curia_julia": {
        "empire": {"note": "The Curia Julia, Caesar's Senate House finished by Augustus in 29 BC and rebuilt after Nero's fire: a tall brick hall faced with marble, bronze doors, and inside the door the Altar and the gold Statue of Victory that Augustus set up from Tarentum. Six hundred senators sit in three rows of marble seats."},
        "late": {"note": "Diocletian's Curia, rebuilt after the fire of 283. The Altar of Victory was carried out two years ago by order of the Emperor Gratian; this year the prefect Symmachus has asked for it back, and Bishop Ambrose has said no. The senators vote on with nothing on the altar's base."},
        "collapse": {"note": "The Senate met the day after the Vandals sailed. The bronze doors are still on; the roof has lost its gilt tiles to the sack, and a plaster Victory has been painted out."},
        "fall": {"note": "The Senate still meets in it: a few old families, Cassiodorus's letters, and a Goth king's leave. In eighty years the hall will be made the church of Saint Hadrian, and that will save it, alone of the Forum's buildings, roof and all."},
    },
    "jupiter": {
        "heroic": {"variant": "etruscan", "note": "The Temple of Jupiter Best and Greatest on the Capitol, dedicated in 509 BC, the first year of the Republic: three cells for Jupiter, Juno and Minerva, a deep porch of wooden columns on a podium of tufa, and terracotta gods on the roof by Vulca of Veii, Jupiter in his four-horse chariot on the ridge. The triumphs end at its stair, and the consuls take office here."},
        "early": {"variant": "etruscan", "note": "The Capitoline temple, its terracotta chariot on the ridge, its walls hung with the spoils of Hannibal's war: the standards of Carthage, the shields of Hasdrubal, a golden crown from Syracuse. The Sibylline books are kept in a stone chest under the podium."},
        "republic": {"variant": "greek", "note": "Burnt in 83 BC with the Sibylline books, and rebuilt by Sulla and Catulus in marble on the old podium, with columns carried off from the temple of Olympian Zeus at Athens. Its roof was gilded last year; the new Sibylline books were gathered from every oracle in Greece and Asia."},
        "empire": {"style": "imperial", "variant": "gilded", "note": "Domitian's temple, the fourth on this podium, after the fires of 69 and 80: Pentelic marble, columns of the same, a roof of gilded bronze tiles that cost twelve thousand talents, and doors plated with gold. The most expensive building in the world, and the first thing seen from the road."},
        "late": {"style": "imperial", "variant": "gilded", "note": "The gilded roof still stands over an empty rite: the Emperor Gratian gave up the office of pontifex maximus two years ago and cut off the priesthoods' money. The temple's treasures are inventoried by the prefect, and the sacrifices are private now, and illegal soon."},
        "collapse": {"state": "ruin", "style": "imperial", "variant": "stripped", "note": "Gaiseric's Vandals took half the gilded bronze roof-tiles in the fourteen days, and the gold from the doors; the roof is open on the north side. The rain gets in among the three gods."},
        "fall": {"state": "ruin", "style": "imperial", "note": "Open to the sky; the columns stand on the tufa podium of 509 BC; the three cells are goat pens. The Capitol is a hill of rocks with a church bell on it, and the name Campidoglio."},
    },
    "vesta": {
        "heroic": {"variant": "thatch", "note": "The round house of the hearth of Rome, of wattle and thatch as the first was, on a footing of tufa. Six Vestal Virgins keep its fire; if it goes out, Rome is in danger, and the Vestal who let it out is whipped by the pontifex maximus in the dark. Behind it is their house; beside it the spring of Juturna."},
        "early": {"variant": "stone", "note": "Burnt in 241 BC. Lucius Metellus the pontifex ran into the fire and carried out the Palladium, the image of Pallas that came from Troy, and was blinded for seeing it. Rebuilt in stone under a bronze roof. The fire has not gone out since."},
        "republic": {"variant": "stone", "note": "The temple of Vesta with its fire, the Regia of the pontifex maximus beside it and the Vestals' house behind. Caesar, who is pontifex maximus, lives in the Regia; the Vestals keep his will. The Vestals sit at the games in front of the senators."},
        "empire": {"variant": "marble", "note": "Rebuilt after Nero's fire: twenty Corinthian columns round the marble drum, the roof of bronze scales with a smoke-hole at the top. The fire inside; the Palladium in its inner room, which only the Vestals enter; the store of the sacred meal for the year's sacrifices."},
        "late": {"variant": "marble", "note": "Julia Domna's rebuilding after the fire of 191. The Vestals still keep the fire, six women of good family with thirty years' service, under a Christian emperor who has stopped paying them. Symmachus has pleaded for their stipend in the same letter as for the Altar of Victory."},
        "collapse": {"state": "ruin", "variant": "cold", "note": "The fire has been out sixty-one years, since Theodosius closed the temples in 394. The last Vestal, Coelia Concordia, was an old woman when it went out; a Christian senator's wife had set up her statue. The columns stand; the roof is gone; the hearth is cold ash."},
        "fall": {"state": "ruin", "variant": "cold", "note": "A ring of columns round a cold drum. Goats sleep in it. The spring of Juturna beside it still runs; people who have never heard of the twins water their animals there."},
    },
    "colosseum": {
        "empire": {"variant": "whole", "note": "The Flavian Amphitheatre, finished by Titus in AD 80 with a hundred days of games: fifty thousand seats in their orders, an awning worked by sailors of the fleet, and the arena over cages and lifts. Beast hunts in the morning, executions at noon, gladiators in the afternoon, and free bread thrown into the crowd."},
        "late": {"variant": "whole", "note": "Still full on the days of the games, which the calendar still gives. Gladiators are fewer and dearer; beast hunts go on. Struck by lightning under Macrinus in 217 and rebuilt over thirty years, the last restoration dedicated by the prefect this decade."},
        "collapse": {"variant": "cracked", "note": "Cracked by the earthquake of 443 and patched by the prefect Lampadius; the games go on, with beasts only, since Honorius stopped the gladiators. The Vandals took nothing from it: there was nothing here to carry."},
        "fall": {"state": "ruin", "variant": "houses", "note": "The last beast hunt was in 523, under Theoderic. The earthquake of 484 brought down part of the south side. People live in its arches with their animals, and grow beans in the arena."},
    },
}

# The Sublician bridge, kept by the pontiffs, through the same seven ages.
SUBLICIAN = {
    "heroic": "The Sublician Bridge, of wood and no iron in it, as the pontiffs require: the bridge Horatius held against Porsenna's Etruscans in 508 BC while it was cut behind him. Every May the Vestals throw the straw men of the Argei from it into the river.",
    "early": "Rebuilt after the flood of 202 BC, of the same wood, without a nail. Trade comes over it from the Etruscan bank; the pontiffs, the bridge-makers, keep it in repair and take the omens when it is mended.",
    "republic": "The bridge of Horatius, the pontiffs' bridge, kept in timber while three stone bridges stand up-river. The flood of 54 BC took it, and the pontifex maximus, who is Caesar, had it built again in wood.",
    "empire": "The oldest bridge, still of wood, rebuilt after every flood; the bridge Horatius held. Anyone with a cart prefers the stone bridges to the island, and the pontifex maximus, who is the emperor, pays for the timber.",
    "late": "The wooden bridge of the pontiffs. The bishop of Rome has begun to be called pontifex too, and the name will outlast the bridge by fifteen hundred years.",
    "collapse": "The Vandals' baggage went over it in their fourteenth day, on the way to their ships at Portus; the bridge held. Rome has three bishops' churches on the far bank now.",
    "fall": "The Goths burnt it in the siege of 546 and Belisarius's men rebuilt it in wood, as it always was. It is the one bridge the town by the river needs.",
}


def main() -> int:
    with open(CITY, encoding="utf-8") as f:
        city = json.load(f)
    by_id = {m["id"]: m for m in city["monuments"]}
    for m in NEW:
        if m["id"] in by_id:
            by_id[m["id"]].update(m)  # its place and years are this file's
        else:
            # the Comitium and the Cloaca belong with the old Forum, before the Senate House
            k = next(i for i, x in enumerate(city["monuments"]) if x["id"] == "curia_hostilia")
            city["monuments"].insert(k, m)
            by_id[m["id"]] = m
    for site, states in SITES.items():
        m = by_id[site]
        m["states"] = {a: dict(states[a]) for a in AGES if a in states}
    for b in city["bridges"]:
        if b["name"] == "the Sublician Bridge":
            b["states"] = {a: {"note": SUBLICIAN[a]} for a in AGES}
    with open(CITY, "w", encoding="utf-8") as f:
        json.dump(city, f, indent=2, ensure_ascii=False)
        f.write("\n")
    n = sum(len(v) for v in SITES.values()) + len(SUBLICIAN)
    print("sites: %d, states: %d" % (len(SITES) + 1, n))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
