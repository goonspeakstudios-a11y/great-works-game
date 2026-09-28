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
| `urbs_activities.gd` | Places everything in the city for an age: your room, the ten recurring rites (with their days and hours, and waiting), the spots, offerings at every standing temple, and the talk panel's seventh button for each trade. |
| `urbs_quests.gd` | The regulars' stories: one short quest per family per age. |
| `urbs_errands.gd` | Errands across the city, with directions by landmarks. Paid on arrival, less if late. |
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

### Your room
Your room is in the Subura, off the Argiletum, in every age:
- a tufa house with a tiled roof in 280 BC;
- five and six storeys of flats above it later;
- a roofless ruin by 552.

In the room:
- **The household gods (lararium):** the morning rite. In AD 384 you choose whether to keep them; in 552 you keep them alone.
- **The bed:** sleep until morning.
- **The chest:** what you carry and what you have gathered.
- **Your purse:** look at the age's coin; this collects it.
- **The quern and hearth** (280 BC): the bread rite.

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
