# Rome: the activities as built

This is the reference for what the player does in the city of Rome, as built from
`docs/rome-activities-plan.md`. Everything is written as data by `tools/make_rome_activities.py`
(sources in `tools/rome_acts/`) and played by a few engines in `scripts/hall/`.

Regenerate the content after editing the sources:

    python3 tools/make_rome_activities.py

Run the tests:

    godot --headless --path . --script res://tests/run_tests.gd

`tests/test_urbs.gd` plays every scene to its end with its first, second and last choices, won and lost.

## Engines

| Script | What it does |
|---|---|
| `urbs_standing.gd` | You, as Rome knows you. It holds fides (-20 to 20), coin, dignitas (0 to 20), the census class, the Ledger, what you carry, collections, rites played, quests and things done once. Money is counted in the age's own coin (as, sestertius, follis, nummus). Prices written as in 280 BC grow faster with the ages than wages do. Kept in the save under `rome_standing`. |
| `urbs_scene.gd` | The one engine for rites, trades, choices and played moments (step kinds below). |
| `urbs_panel.gd` | The activity panel. It shows a scene's words, up to four choices (keys 1 to 4), the timing and hold bar, a line for copying out, or a game at the table. |
| `urbs_games.gd` | Rules for tali (knucklebones, with loaded bones), terni lapilli, latrunculi, duodecim scripta, haggling, the money changer's test and the chariot race. |
| `urbs_games_view.gd` | Draws those games and takes moves by mouse or keys. Settles stakes and prices through the Standing. |
| `urbs_activities.gd` | Places everything in the city for an age: your house, the ten recurring rites (with their days and hours, and waiting), the spots, offerings at every standing temple, and the talk panel's seventh button for each trade. |
| `urbs_quests.gd` | The regulars' stories: one short quest per family per age. |
| `urbs_errands.gd` | Errands across the city, with directions by landmarks and streets. Paid on arrival, less if late. |
| `urbs_house.gd` | Your house: one floor plan (rooms, walls, doorways) that builds it in each age and draws its plan; your wife and household. |
| `urbs_plan.gd` | The streets as a network, routes, and directions in words. |
| `urbs_plan_panel.gd` | The Plan panel: the city (whole or close) and your house. |
| `nexus.gd` `_rome_pieces` | What Rome brings back to the Nexus: each completed set's piece, the frieze of the rites and the Ledger. |

## Scene steps

| Step | Played as |
|---|---|
| `{"say": text}` | a line; F goes on |
| `{"ask": text, "options": [...]}` | a choice. Each option can carry effects (`fides`, `coin`, `dignitas`, `pay`, `earn`, `ledger`, `give`, `take`, `collect`, `class`, `census`, `once`), a `need` and a `then` label |
| `{"rite": text, "order": [...], "wrong": [...], "strict": bool}` | each act in order, picked from three. While the gods are listened to, a slip begins the rite again; from 50 BC it is waved on |
| `{"hold": text, "secs": n}` | hold F |
| `{"still": text, "secs": n}` | touch nothing for n seconds |
| `{"timing": text, "hits": n}` | stop the swinging mark in the gold |
| `{"type": text}` | copy the words out |
| `{"pick": question, "options": [...], "right": k}` | a question with one right answer |
| `{"pay": n, "else": label}`, `{"gain": {...}}`, `{"wage": n, "per": m}` | money and standing |
| `{"if": condition, "to": label}` | a Standing condition, or `score`, `restarts`, `random`, `won` |
| `{"play": game, "opts": {...}, "win": l, "lose": l}` | a game at the table |
| `{"errand": {"pay": n, "what": text}}` | an errand across the city |
| `{"hour": h}`, `{"label": name}`, `{"go": name}`, `{"end": text}` | the day moves on (sleep, waiting), jumps, the end |

## What there is to do

### Your house and your family
Your house is an atrium house on the north side of the Argiletum, where it climbs into the Subura. It is 440 paces north-east of the Forum, and the same house in every age (`urbs_house.gd`, `tools/rome_acts/home.py`).

**One floor plan** builds the house in the world and draws its plan:
- two shops and the entrance on the street;
- the atrium with its pool under the opening in the roof;
- the children's room and the store;
- the wing with the household gods, and the kitchen;
- the dining room, the tablinum (master's room) and your bedroom;
- the garden.

**The house through the ages:**
- tufa, the hearth and the loom in the atrium, beans and a fig tree (280 BC);
- the ancestor's mask in the wing (201 BC);
- painted walls, mosaic floors and a strongbox, all on your wife's money (50 BC);
- marble, a bronze satyr, a fountain and slaves (AD 150);
- the garden door and your bedroom door bricked up (AD 384);
- looted, the dining room's and bedroom's roofs fallen in, one broken couch (AD 455);
- roofless, walls fallen, brambles, and the fig tree grown wild (AD 552).

**A wife in every age, each worse than the last, then none:**

| Age | Your wife | Your household |
|---|---|---|
| 280 BC | Postumia: spins and weaves in the atrium, drinks no wine, sends you to the levy with a clear face | three children round the hearth |
| 201 BC | Sulpicia: mourned her brothers from Cannae for the thirty days the Senate allowed and not an hour more; keeps her plain wool against the repeal of the Oppian law | a son home from Zama, a daughter betrothed |
| 50 BC | Valeria: married without her property passing to you, dines out, and threatens divorce with her dowry | one boy raised by a Greek nurse |
| AD 150 | Flavia: has her maid flogged for a curl, takes drugs against children, goes to the games for Callistus the net-fighter, asks the astrologer when you'll die | a lapdog |
| AD 384 | Rufina: gives your silver to the bishop, sues you for the Campanian farm, marries your twelve-year-old to a man of sixty-one for his estates, bricks up her doors | the daughter, and a eunuch |
| AD 455 | Galla: lives with a Gothic guardsman, drinks, and comes back to sell the candlesticks and the household gods | your son is a captive in Carthage |
| AD 552 | none | none |

Talking to your wife works like talking to anyone:
- her news comes visit by visit;
- the six topics are answered in her own words;
- the seventh button is **supper**, a scene in each age, and several of them go into the Ledger:
  - Tertia asleep on your knee;
  - Gaius's Zama at table;
  - Valeria's "friend", and the old divorce formula "take your things and go";
  - Flavia's slave whipped between courses;
  - Aemilia asking whether she must marry him;
  - Galla taking the Lar;
  - in AD 552, saying their names in the empty dining room.
- If Galla sold the household gods, the niche stays empty in AD 552.

**Also in the house:**
- the household gods in the wing;
- your bed;
- the strongbox;
- the coin in your purse;
- the quern and hearth in 280 BC;
- every room, readable for what it is like in the age;
- the **plan of the house** on the tablinum wall.

### The ground
The ground of the city is a height map (`content/rome/height.json`, made by `tools/make_rome_height.py`), from the real shapes and heights of the hills: the valleys and the Campus at about 12 m above the sea, the plateau rising to the east; the Quirinal, Viminal, Cispius and Oppius as long tongues off it with the valleys of the Vicus Longus, the Vicus Patricius and the Subura between; the Capitol's two summits, the Palatine, the Velia, the Caelian, the two Aventines, the Pincian, the Janiculum and the Vatican across the river. Every street is graded into it (its line evened out over forty metres, the ground either side cut and filled to meet it), and the ground under every monument is levelled, and under your house. The relief (`assets/maps/rome_relief.png`) is drawn under the plan. Regenerate after moving a street or a monument:

    python3 tools/make_rome_height.py

### Dev maps
Three tools for building the city up, all under `docs/`:
- `python3 tools/plot_rome.py` → `docs/rome-plot.png` and `.csv`: every structure numbered on the relief with a 250 m grid; the index gives each one's map position, ground height and years. This is the plan as written.
- `python3 tools/dev_maps.py [ages]` → `docs/dev/ortho_<age>.png`, `ortho_forum_<age>.png` and `ortho_ages.png`: the city as the game builds it, captured straight down with an orthographic camera (`--ortho=<metres> --res=N` in the hall's shot mode, fog and shadows off), with the same grid and numbers laid over it. This is the plan as built; lay it beside the plot to see what stands where it should.
- `python3 tools/dev_maps.py materials` → `docs/dev/materials.png`: every material of the city as a labelled swatch (`tools/material_sheet.gd` dumps them).

### The plan of the city, and directions that agree with it
**The live map** (M anywhere in the city) sits in the corner and follows you as you walk, close in on where you are, with the ground in relief, the streets, the monuments, your house and the regulars; M or Esc puts it away, Z shows the whole city.

**The Plan** (the house's plan on the tablinum wall, and in AD 384 the Severan Marble Plan on the Temple of Peace's wall) is the same map large and still. Both draw Rome from the same data the world is built from, north at the top:
- the Tiber and the island;
- the Servian wall, and Aurelian's from AD 271;
- every street with its name;
- every monument standing in the age, with ruins in grey;
- the regions;
- your house, the regulars' places, where your quests have sent you, and the errand's place;
- you, as an arrow the way you face;
- a north arrow and a bar of five hundred paces.

Z zooms in on where you stand, and the mouse names what is under it. Key 1 shows the city and key 2 the plan of the house, where the mouse names each room and what it is like in the age. Bricked-up doors are drawn in red and fallen walls dashed.

**Directions** (`urbs_plan.gd`) are worked out on the same streets:
- the streets are a network, walked in points 18 m apart and joined where they cross or meet;
- a route finds the way along it, and the directions name each street, the way it runs, the paces (1 pace = 1.48 m), the monument where you turn (a ruin in AD 552), and which side of you the place is when you arrive;
- errands, the quests' "go" steps (on the tablet, recomputed from where you stand) and anyone you ask the way ("Where is the Temple of Castor?", "How do I get home?") all give these directions;
- the "around" topic says which street you're on and which way the Forum lies;
- the tablet says where you are.

**Joined up** (the notes of `docs/rome-city-notes.md` 3, built 2026-09-29):
- the live map draws the way to where you've been sent (the errand, else the current quest's place) as a faint line along the streets (`Plan.way`), and when your house is off the map, an arrow the way home;
- when anyone gives you the way, the corner where it first turns glows on the ground for half a minute (`Plan.first_turn`, `hall._show_way`);
- with Claude on the line, a typed "where is X?" gives the citizen the way from where they stand as a fact of their persona, so anyone can be asked;
- the corner of the screen shows the street you are on under the region's name, and passing a gate of the Servian wall is said ("You pass through the Capene Gate, out of the walls");
- the crossroads shrines and the first fountain on each street are named landmarks ("the shrine at the crossing of the Argiletum and the Vicus Patricius", "the fountain on the Alta Semita"), used in directions and named on the map, though no errand sends you to one.

### Rides, and the way home
For the long walks (the Campus, the Aventine, the Lateran), the litter bearers, the muleteer and the boatman offer rides (`ride_litter`, `ride_cart`, `ride_boat` in `trades.json`, on their "act" button): three far places in different directions, and your house if it is far, for a fare in the age's coin; the walk is done in a fade and an hour of the day goes (`hall._ride_choices`, `_resolve_ride`, the scene step `{"ride": key}`). The toad, spoken to in Rome far from home, also offers the way home for an hour of the day.

### The recurring rites
Ten rites, each held in all seven ages at its place and hours. When one is not on, you can wait for it.

| Rite | Its course, 280 BC to AD 552 |
|---|---|
| The vote | oral voting for Decius Mus → the centuries voting No, then Yes, to war with Macedon, with the poor never called → a divisor's purse and the gangs at the pens → the Emperor's list acclaimed → an office bought → a Goth-made Emperor cheered, with bets on his fall → no vote |
| The games | the Equirria → Plautus and the chariots → a candidate's gladiators → the Colosseum's day, where you stay or leave at midday → dragging Alypius in → races after the Vandals, with a fixed race → the empty Circus |
| The funeral | the soldier's pyre, done exactly → wearing an ancestor's mask at the Rostra → Clodius burned in the Senate House → hired wailing for a freedman → a place near the martyrs in the catacombs → the burial pits, and the ring → carrying the unclaimed dead at night |
| The levy | stand forward or hang back against Pyrrhus, oath "idem in me" → the post-Cannae oath sworn word for word, property required → a general's recruiter → twenty-five years → the recruit tax and the maimed thumb → the palace's Gothic guard → a garrison with no Romans |
| The court | the Twelve Tables' five feet, and your oath → "trees" not "vines" in the legis actio → a bribed witness at an extortion trial → an informer's treason charge → paying a flogged debtor's arrears → a false oath on Peter's chains → a goat returned |
| The bread | your own quern → the aediles' grain at four asses → a dead man's place on Clodius's list → a sick neighbour's tessera → a baker's son hidden from his hereditary trade → the empty granaries' riot → the Church's bread |
| The sacrifice | the ox for Jupiter, done exactly → the same after Cannae, the victim bolting → waved through under Caesar's pontificate → incense for the Emperor, and the Christian beside you → Praetextatus's forbidden rite behind shut doors → relics sold → wine poured alone at Saturn's temple |
| The triumph | Coruncanius's rude songs → Scipio and "remember you are a man" → Cicero waiting outside the walls → the Emperor's victory he never went to → Constantius's visit remembered → the Vandals' carts → the keys sent to Constantinople |
| The Saturnalia | knucklebones with the farmers → the Greek-style feast → Davus's frankness → the drunken week and the Basilica's boards → Macrobius's dinner → a masked mob → an old woman's memory |
| The morning call | a patron who asks after your crops → a basket → the nomenclator → Martial's round → the steward's morning wait → the empty house → nothing |

### Work, the market, games
The talk panel's seventh button offers what each trade has:
- **Work:**
  - the baker (pounding grain in 201 BC; short weight or honest later; bound by law in 384; no flour in 552);
  - the fuller; the porter; the water carrier;
  - the scribe (Cicero, Virgil, Symmachus copied out);
  - the letter cutter (D M, V A, S T T L; H S E; IN PACE; old stones sawn up);
  - selling the fishwife's catch; poling the ferry.
- **Buying:** eighteen trades, by haggling. You can walk away, or lie ("I saw it cheaper at the Forum Boarium").
- **Games:**
  - knucklebones in the taverns, with loaded bones if you dare;
  - latrunculi with soldiers and veterans;
  - terni lapilli with anyone.
- **Money:**
  - the money changer's tray, where you ring, weigh and cut the coins (the Republic's silver, the Empire's debasement, the late copper);
  - the moneylender;
  - alms for the beggars.
- **Errands:** merchants, senators, matrons and clients send you across the city with directions by landmarks.
- **The Greens' practice run** at the Circus.

### Spots in the city
- **Scenes:**
  - the augurs on the Arx;
  - duodecim scripta on the Basilica steps;
  - the curse tablet at the fountain;
  - the census at the Villa Publica, and the tax assessor in 384;
  - the baths (Titus's, Diocletian's, a Subura bathhouse), with the thief;
  - the fire, when it is burning;
  - the Subura at night (Juvenal 3);
  - betting on the races.
- **The exempla:**
  - played in 280 BC: Horatius, Scaevola, Cloelia, the Sabine women, Curtius, Decius Mus's devotio, Appius in the Senate, Fabricius and the elephant, Curius and his turnips;
  - told in every age, in that age's manner: those nine, and Cincinnatus, Camillus, Torquatus, Regulus and Lucretia.
- **Inscriptions**, readable where they stand in the ages they stand:
  - the Black Stone, the Twelve Tables, a Subura wall, the Pantheon;
  - the Arches of Titus, Severus (with Geta's name cut out) and Constantine;
  - Trajan's Column, Damasus's verses, Saturn's restoration, a tomb on the road;
  - a tile that says ROMA.
- **An offering** at every temple standing, from 280 BC to AD 384.

### The regulars' stories
The same five families in every age they live in. There are 31 quests. Each is a talk, a walk, a scene, and a talk or a thing brought back. Finishing one gives its reward and adds that family's voice to the collection.
- **The Numisii:** the barley before the levy → bread for a Cannae widow → the midwife → the name in marble → the oven tax → a son in the Gothic guard → burying the last Felix.
- **The soldiers who become gladiators:** the wooden elephant → the land grant → the wooden sword → Hilarus's tavern → Nicias and the priest.
- **The Caecilii:** the silver salt cellar → the letter from the slave in Greece → the divisor's purse → a lamp for the Emperor's freedman → the Altar of Victory's lists → the grandson on the Vandal ships → the masks.
- **The Fabiae:** the first fish for Father Tiber → the cloak for the fleet → the night of the moneylender → the foundling → wine for the river in secret → her daughter in the Subura → beams from the Forum to boil water.
- **The barbers from Sicily:** the razors → thanks to the Twins → the man two chairs down → the informers' list → four hundred years in the chair.

### Collections and the Nexus
Five sets, each bringing a piece back to Rome's stele on the Heart of the Nexus:

| Set | Piece brought back |
|---|---|
| exempla (14) | the statues |
| inscriptions (12) | the dedication |
| coins (7, one per age) | the treasury |
| masks (2) | the niches |
| voices (31) | the choir |

- **The frieze of the rites** gains a panel for each recurring rite played in all seven ages.
- **The Ledger** stands as soon as anything is in it. It lists by age what you did when virtue cost something, and is never scored. It is carved when Rome is complete: every set, and every rite in every age.

## Open
- **The reading list's own books** attach to these spots and scenes when Essential-Reading-List is connected. They use the same engines: a book's played moment is a scene, and its point is counted in its place.
- **Taking office** (quaestor to consul) as a long chain across Eras II–III is not built.
