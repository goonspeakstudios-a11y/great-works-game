# Rome: activities, tasks and minigames (plan)

Status: plan only (BB1, 2026-09-28). This is the companion to `docs/rome-thematic-plan.md`: the
thematic plan fixes which authors and books belong to which era and zone; this document fixes
everything the player *does* in the Rome world. The reading list itself will be connected later from
Essential-Reading-List. Every activity here is written so it can be attached to whichever of those
books covers its era.

## 0. Design rules

1. **Every activity teaches or shows.** It either earns a lesson point of a book, or makes the era's
   virtue or its loss felt in the hands. No filler.
2. **The same rite in every era.** The strongest device in the world is the *recurring rite*: the
   vote, the games, the funeral, the levy, the court, the bread, the sacrifice, played again in each
   era. The rules are the same; what people do with them decays. The player feels the fall by doing
   the same thing seven times.
3. **Choices cost.** Where a choice matters (the Senate, the court, the canvass, the census), every
   option has a price, in the manner of Papers, Please. The virtuous choice gets harder and less
   rewarded as the eras go down, and that is the point.
4. **Book beats have no fail state.** As in Greece, a book's played moments can always be finished;
   the Zen and Student modes decide whether they count. **City tasks can fail softly**: you lose coin,
   standing or time, never progress.
5. **Short.** A minigame is one to five minutes; a book's place is twenty to forty; a recurring rite
   in one era is two to six.
6. **Built from engines, filled from data.** A handful of engines (section 8) and JSON content per
   era, so new activities are written, not coded.
7. **Adult, never gratuitous.** The later eras show slavery, violence and vice plainly, as their
   sources do; nothing is explicit, nothing is played for thrills (executions are witnessed, never
   performed by the player).

## 1. The player in Rome

You are a stranger (Peregrinus, in Zen; Discipulus, in Student) who stays. Rome treats you as it
treats people, so the world keeps a few simple measures of you, shown on the tablet (Tab).

| Measure | What it is | Raised by | Spent or lost by | What it changes |
|---|---|---|---|---|
| **Fides** (trust) | your word, as the city knows it | keeping promises, delivering messages, honest dealing, fair judgement | lying, cheating at dice, taking bribes, breaking a vow | how people greet you, whether they ask favours, prices, whether a patron takes you on |
| **Coin** (asses, sestertii, denarii; later folles and solidi) | money | working trades, winnings, a patron's basket, favours | bread, the baths, bets, fines, bribes, rent | what you can buy, bet, bribe; the coin itself changes with the era (see debasement) |
| **Dignitas** (standing) | your place in the order of Rome | the census class you are enrolled in, offices won, a patron's favour | disgrace, exposure of a bribe, a lost case | which century you vote in, whether the Senate hears you, where you sit at the games |
| **The Ledger** (hidden) | every choice you made when virtue cost something | recorded, never scored as good or bad in play | none | carved on Rome's tier of the Tower in the Nexus at the end (section 7): what you did when it cost |

In the heroic era virtue and reward line up; by the late Republic they part; by the Empire virtue
is punished and flattery paid; by the Collapse nothing pays at all. The measures make that audible
in the player's purse.

**Where you live.** A rented room (cenaculum) in an insula of the Subura, the same address in every
era, with its lararium (household shrine), a bed, a chest. It changes with the era: a family room in
280 BC, a crowded fifth floor in 50 BC, a room in a block that burns in AD 150, a ruin you sleep in
by 552. Saving happens here; the day's small rites (the lararium) start here.

## 2. The recurring rites: the decline played seven times

Each rite is one engine with a JSON entry per era. It is offered by the calendar (its day and hour),
by a citizen asking you along, or by a book that needs it.

### 2.1 The vote (comitia)
| Era | How it's played | What it shows |
|---|---|---|
| I 280 BC | walk down with your century to the Campus; hear the candidates speak plainly; drop your tablet in the urn | the citizen's voice |
| II 201 BC | you vote in the century of your census class; the rich centuries vote first and decide it before yours is called (the Polybian constitution in practice) | order and its tilt |
| III 50 BC | agents of both candidates find you on the way with coin; gangs block the voting pens; you vote (bought or not) while the pens are stormed | the vote for sale |
| IV AD 150 | the "election": the Senate reads out the Emperor's list; the assembly acclaims it; your century shouts on cue | the forms without substance |
| V AD 384 | offices are bought from the palace; you can buy a post in the Prefect's office, or stay out | office as merchandise |
| VI AD 455 | the Emperor is proclaimed by a barbarian general's army; the crowd is told to cheer; you cheer or you don't | power without Rome |
| VII AD 552 | no vote; the last senators sign what Narses sends | nothing left to choose |

### 2.2 The games (ludi and munera)
| Era | Played as | |
|---|---|---|
| I | the Equirria: horse races on the Campus for Mars; farmers bet a ham | play |
| II | the Roman Games: a Plautus comedy on a wooden stage, then chariots in the Circus; you sit where your class sits | the city laughing at itself |
| III | a candidate's gladiatorial show given for votes; the crowd is paid in bread to attend | spectacle bought |
| IV | a day at the Colosseum: morning beasts, midday executions (witnessed, the camera may turn away), afternoon gladiators; you may leave at any point (Seneca, Letter 7) | spectacle as government |
| V | Alypius: you are the friend who drags him in (Augustine, *Confessions* 6.8), then watch him look | the soul caught |
| VI | chariot races go on while news arrives that Carthage has fallen; you can shout the news; no one stops | absurdity |
| VII | the last races (549, under Totila): half the stands empty, the horses thin | the end of the circus |

A **chariot-race minigame** (section 3.6) is available at the Circus from Era II on; betting on the
factions from Era III on.

### 2.3 The funeral
| Era | |
|---|---|
| I | a farmer-soldier's pyre on the Esquiline; his comrades speak |
| II | a great man's funeral: men wear the ancestors' wax masks and ride in chariots; his son praises him from the Rostra (Polybius 6.53–54). You carry a mask and hear who each was |
| III | a funeral turned riot: the crowd burns the body in the Senate House (Clodius, 52 BC) |
| IV | a rich freedman's funeral with a hundred hired mourners and a vulgar tomb (Petronius's Trimalchio) |
| V | a Christian burial in the catacombs, bought near a martyr |
| VI | a mass grave after the Vandals |
| VII | the vespillones carry the unclaimed out at night; you help carry |

### 2.4 The levy and the oath (dilectus, sacramentum)
I: the whole tribe answers; you're chosen or not by lot. II: enrolled by census class, sworn. III:
Marius's volunteers; the general, not Rome, is paying. IV: a professional recruit signs for 25 years
for pay. V: a Goth signs as a federate; Romans pay to avoid service. VI: the Emperor's guard is a
barbarian general's household. VII: Byzantine garrison; no Roman levy at all.

### 2.5 The court
I: a king's or consul's judgement in the open Forum, by the Twelve Tables. II: a quaestio before a
jury of senators. III: the court under the Rhetorica's rules, jurors bribed (the play on Rhetorica's
court: argue the case with the five canons, see who pays). IV: a charge of treason (maiestas) from
an informer; defend a man, or inform. V: the Prefect's torture of a tax debtor. VI: a bishop's
arbitration. VII: none left but the bishop.

### 2.6 The bread
I: your own grain, milled at home. II: Sicilian grain cheap after the war. III: Clodius's free grain
dole: queue with your token; gangs control the line. IV: the annona: the tessera, the Portico of
Minucius, the ships from Egypt. V: baked bread and pork from the state, bakers chained to the trade.
VI: no grain from Africa; riot. VII: the Church's bread at the Lateran.

### 2.7 The sacrifice
I–II: performed exactly (section 3.5); a wrong word and it restarts; the gods answer. III: performed
for show by a pontifex who believes nothing (Caesar himself). IV: incense to the Emperor's genius; a
Christian refuses beside you. V: forbidden; performed in secret by an old senator. VI: gone; relics
sold instead. VII: none.

### 2.8 The triumph
I: a consul's triumph over the Samnites, farmers in armour. II: Scipio's triumph, the slave in the
chariot whispering "remember you are mortal". III: Pompey's third triumph, captives from every
nation, and the crowd counts the money. IV: an Emperor's triumph for a war he didn't fight. V: the
Emperor's once-in-thirty-years visit; the crowd is told to be amazed. VI: a Vandal procession
carrying Rome's treasures *away*. VII: none.

### 2.9 The Saturnalia (every era)
The day the world turns over: masters serve slaves, dice are legal, gifts. I–II: joyful and real.
III: the only honest day of the year. IV: a drunken week; the Emperor's own. V: half-Christianised.
VI: a mob. VII: remembered by the old.

### 2.10 The morning greeting (salutatio)
I: you visit your patron, a farmer-senator who asks after your crops. II: a crowd of clients, a
little basket. III: clients sold to the highest-spending patron; the nomenclator whispers your name.
IV: Martial's clients running from house to house for the basket (sportula). V: a great house's
steward keeps you waiting all morning. VI: the house is empty; the patron fled. VII: no patrons.

## 3. Minigames (city-wide, any book or none)

Each is short, repeatable, and exists in the eras where it makes sense. Each can pay coin, fides or
dignitas, and each has an era variant that shows the fall.

### 3.1 Work a trade (a day's work)
Talk to a worker of that trade and ask for a day's work. Each trade is a tiny loop of two or three
actions with timing:
- **Baker (pistor):** turn the donkey mill, knead, load the oven, pull at the right moment; stamp
  each loaf (honest weight or short weight: short pays more and risks the aedile). Era VII: no
  flour.
- **Fuller (fullo):** tread cloth in the vat (rhythm), rinse, hang over the sulphur frame; a
  senator's toga ruined costs you everything.
- **Porter / sack carrier:** carry loads from the river port up to an address across the city
  without a map, against a time limit (section 3.3); heavier loads pay more and slow you.
- **Water carrier:** fountain to fifth floor, stairs, spill meter.
- **Scribe (librarius):** copy a passage from a book of the era by typing it; speed and accuracy
  pay; in Era III you are asked to copy a banned pamphlet.
- **Letter cutter (marmorarius):** cut an epitaph: place the letters from a dictated text, in the
  right abbreviations (D M, V A, H S E); real epitaphs of each era.
- **Fishmonger:** sell the catch before noon (haggling, section 3.2); what's left spoils.
- **Boatman:** row a ferry across the Tiber with the current (steering).
- **Vigil (from Era IV):** a fire shift (section 3.8).

### 3.2 Haggling (the market)
A buyer and a seller exchange offers; each has a hidden limit that depends on fides, the era's
prices and the seller's mood. Walk away, split the difference, or lie ("I saw it cheaper at the
Forum Boarium"). Prices move by era: bread's price is one of the clearest signs of the decline.

### 3.3 Messenger runs (getting to know the city)
A citizen, patron or regular gives a message for someone "by the Temple of Castor, three doors past
the baker with the donkey". No map marker: directions are given the Roman way, by landmarks. The
city's own signs help: region names in the corner, monument notes, the regulars' shops. Soft fail:
the message arrives late. This is the "getting lost" the city was built for, turned into a
skill. Later eras: landmarks are ruins, directions refer to what used to be there.

### 3.4 Board games and dice (in taverns, on the Forum steps, at the baths)
Played against citizens for coin; cheating is possible and costs fides if caught.
- **Tali (knucklebones):** throw four; the Venus (all different) wins, the Dog (all ones) loses.
- **Duodecim scripta / alea:** a race game with three dice (the ancestor of backgammon); the
  Basilica Julia's steps still have the boards scratched into them.
- **Latrunculi ("little soldiers"):** capture by surrounding, on a grid; the soldier's game.
- **Terni lapilli:** three in a row, for children and idle guards.
Dice are illegal except at the Saturnalia; in Era III a lictor may fine you; in Era IV everyone
plays including the Emperor (Suetonius: Claudius wrote a book on dice).

### 3.5 Rites done exactly (religio)
A rite is a sequence: veil the head, wash the hands, the right victim for the right god (white for
the gods above, black for the gods below), the prayer said word for word from a tablet, the cake of
salted meal (mola salsa), the knife, the reading of the entrails. Any slip, a stumbling victim or a
wrong word, and the piper and priest start it again (the Romans did). Played at a temple with its
aedituus; the god and victim change by temple. Era I–II: the gods answer (the weather turns, a
bird calls); Era III on: the priest doesn't care.
- **Augury:** stand in the templum on the Arx, facing south, and watch the birds (which birds,
  which side, how many); read the sign by the augural rules; the magistrate proceeds or waits.
- **Haruspicy:** read a liver against the bronze Liver of Piacenza's regions (gods of the sky
  and gods below); a swollen lobe here, a missing head there.
- **The lararium:** each morning in your room, a pinch of incense and a cake for the household
  gods; small, daily, the thread that ties the eras (in Era V it's forbidden; in VII you keep it
  alone).
- **Curse tablets (defixiones):** from Era III, a citizen asks you to write and bury one at a
  fountain; you choose whether to. The Ledger records it.

### 3.6 The chariot race (Circus Maximus)
From Era II. As a driver (Era IV, a Greens contract) or a passenger in a practice run: seven laps,
four horses, the turning posts (metae). Reins left and right, whip for speed, the inside horse
takes the turn tight or the chariot "shipwrecks" (naufragium). Betting on factions from Era III:
the odds, the curse tablets under the gates, a fixed race in Era VI.

### 3.7 The baths
From Era III (public baths grow common in Era IV). The sequence: pay, undress, give clothes to the
capsarius (or not, and have them stolen), exercise, hot room, warm room, cold plunge, oil and
strigil. The gossip pool: citizens here tell you the news of the era. A thief to catch in the
changing room (a small chase). Era VII: dry, used as a quarry.

### 3.8 The fire (from Era IV with the vigiles, earlier with neighbours)
An insula burns: form the bucket chain from the fountain, soak blankets in vinegar, and choose which
neighbouring building to pull down with hooks to stop the spread. People on the top floor.
Crassus's agents (Era III) offer to buy the burning block. The choice and its cost go on the Ledger.

### 3.9 The census
From Era II. Declare your property to the censors at the Villa Publica: honest or not. Your
declaration sets your class (and so your century, your seat, your dignitas). The censors may check.
In Era V the census is the tax register, and honesty ruins you.

### 3.10 Advocacy (the courts)
From Era III, in the Basilica: take a case offered by a citizen; prepare it with the Rhetorica's
five canons (the Rhetorica's place teaches them; here you use them): invent the arguments from the
facts you gathered by talking to witnesses in the city, arrange them in the six parts of a speech,
choose the style, remember it (the memory house), deliver it (timing). The jury's verdict depends on
the speech and, in Era III, on who paid them.

### 3.11 The dole
From Era III. Collect your token (tessera), find the right distribution point on the right day,
queue. Gangs, forged tokens, the ship delayed. In Era V the bread is baked and the baker's family
is chained to the trade; in VII it's the Church's.

### 3.12 Collections (the city remembered)
Kept in the tablet, and each complete set rewards the Nexus (section 7):
- **Exempla:** the heroes' stories heard in the city (Horatius, Scaevola, Cloelia, Decius,
  Curius, Fabricius, Regulus, Cincinnatus...), each told by someone in its own place.
- **Inscriptions:** read on monuments, tombs and walls (the Res Gestae, epitaphs, election
  notices, graffiti), era by era.
- **Coins:** one of each era's coins, from the heavy bronze as of Era I to the gold solidus and the
  worthless copper of Era VII. The money changer (section 3.13) shows their silver.
- **Masks:** the ancestral masks of a family, carried at the Era II funeral.
- **Voices:** a line from each of the regulars in each era (their family's fall, complete).

### 3.13 The money changer's test (debasement)
At a nummularius's table: ring each coin, weigh it, cut it. The denarius was nearly pure silver
under the Republic; by the late third century the "silver" coin was mostly copper with a wash. The
player sees the Empire's value drain, coin by coin. Pays in knowing what you hold.

### 3.14 Night in the city
Survive the Subura after dark (Juvenal, Satire 3): the pots from the windows, the drunk bully, the
rich man's torchlit escort that shoves you into the gutter, the collapsing building, the thief.
Get home. Era VII: the dark is empty.

## 4. The books' places: activity catalogue by era and zone

These are the played moments of each book, as in the Greek rooms (a teacher, lesson points and
stones, a place mended as it is understood). Where the thematic plan named an activity, the steps
are given here.

### Era I (280 BC)
- **The bridge (Horatius), `aventinus`, the Sublician bridge:** a beat. Hold the far end of the
  bridge with two companions (Lartius, Herminius) against the Etruscans; at the right moments send
  them back across; behind you the axes cut; when it goes, pray to Father Tiber and swim in armour
  (a swim beat to the Roman bank).
- **The fire (Scaevola), `trans_tiberim`, the Etruscan camp:** creep into the camp by night, choose
  the wrong man (the king's secretary, who looks like the king), be caught; before Porsenna, hold
  your right hand in the altar fire (hold F against the flame; no damage is shown, only the king's
  face changing).
- **The Sabine women, Forum valley:** as a Sabine wife with her child, run between the two armies
  (a run between two lines while the shouting dies).
- **The devotio (Decius Mus), `campus_martius` set as Sentinum:** the pontifex speaks the formula,
  you repeat it word by word (the rite engine), veil the head, stand on the spear, mount, ride into
  the Gauls (the camera rises; the line holds).
- **Appius in the Senate, `capitolium`:** a hard choice: the Senate is ready to accept Pyrrhus's
  peace; you carry blind Appius in; his speech is played; you vote.
- **Fabricius and the gold, Pyrrhus's tent:** a stillness beat: the gold offered; the curtain
  drawn back and the elephant trumpets; do nothing (moving loses the moment, and you try again).
- **Curius at his hearth:** a small one: the Samnite envoys with gold, the turnips in the pot;
  refuse.
- **Cincinnatus at the plough** (if the book includes it): the envoys arrive at his four acres; put
  on the toga his wife brings; sixteen days later, give it back.

### Era II (201 BC)
- **The census and the levy, `campus_martius`:** the census (3.9), then the levy by tribe; the oath
  sworn word for word.
- **Lay out the camp (Polybius 6.27–42):** the consul's tent (praetorium) first, the flag, then
  measure out the Via Principalis and the Via Praetoria with a groma (sighting rod); place the
  legions, the allies, the cavalry by Polybius's plan; ditch and rampart. Scored on matching the
  plan; lesson: discipline as geometry.
- **The funeral with the masks (Polybius 6.53–54):** carry a mask (choose which ancestor, learn
  his deeds), ride in the procession, then speak the praise from the Rostra (the dead man's deeds
  and each ancestor's, in order).
- **Cannae's news and the ransom debate (Livy 22):** the news comes in pieces to the Forum
  (messengers, rumours); the women at the gates; then the Senate: the prisoners' envoys plead;
  Torquatus speaks against; you vote. The Ledger records it.
- **Zama:** the elephants' lanes: give the orders to open the maniples into lanes as the elephants
  charge, then close.
- **Cato's farm, `collina`:** run a small farm by *On Agriculture*: the jobs for rainy days, sell
  the old oxen and the sick slave (Cato's own advice; you may refuse), the accounts.
- **Cato the censor:** strike a senator off the roll for luxury (choose whom from the evidence
  you gather in the city: silver plate, Greek cooks, a kiss in public).
- **Plautus at the Roman Games:** watch a scene, then play the clever slave in the next one
  (dialogue choices to fool the braggart soldier).

### Era III (50 BC)
- **The Rhetorica** (built): the memory house, the court, the five canons.
- **The First Catilinarian (63 BC), Temple of Jupiter Stator:** deliver it with the canons: the
  opening ("How long, Catiline..."), the arrangement, the delivery timed to the senators moving
  away from Catiline's bench; the Senate's reaction follows your delivery.
- **The canvass (the Handbook on Electioneering):** a week of the campaign in a few days: the
  morning greeting at your house, the escort to the Forum, the nomenclator whispering names, the
  promises, the dinners, the bribes offered and taken. Every chapter of the handbook is a tool that
  works; the Ledger counts them.
- **The conspiracy (Sallust), the Subura at night:** go among Catiline's men, hear the oath, report
  to Cicero or not.
- **Lucretius's garden, `esquilina`:** above the burial pits; dismantle the fear of death: each of
  Lucretius's arguments is a stone you set, and the pits below grow quieter.
- **On Duties, Cicero's house:** cases of the honourable against the useful (the grain merchant who
  knows more ships are coming, the house with the hidden defect): decide each, then hear Cicero.
- **The Ides of March, the Curia of Pompey:** witness, as a senator on the benches; you can shout a
  warning or not; it happens either way.

### Era IV (AD 150)
- **The hall of heroes (Aeneid 6), Forum of Augustus:** walk the statues of the great men and name
  them; they are Era I's heroes, and you met them. Then Anchises' charge ("Remember, Roman, to rule
  the peoples..."), and the question of what they serve now.
- **Pietas (Aeneid 2), a burning house:** carry your father on your shoulders out of burning Troy
  with your son by the hand (a carrying beat, heavy and slow).
- **Dido (Aeneid 4):** the choice Aeneas makes; the pyre seen from the ships.
- **The Res Gestae, the Mausoleum:** read the bronze pillars; beside each claim, find in the city
  what it leaves out (the proscribed, the veterans' farms taken).
- **Horace's Odes, Maecenas's gardens:** 3.6 read at the start of the Rome world; 3.2 weighed:
  "sweet and fitting to die for one's country"; the Secular Games' hymn sung by the choir.
- **The Senate under Tiberius (Tacitus, Annals 1):** a session in which every speech is a test of
  flattery; say what the Emperor wants, or what you think, and watch the price.
- **A night in the Subura (Juvenal 3):** section 3.14, as its book.
- **The games (Seneca, Letter 7):** section 2.2, Era IV, as its book: stay or go.
- **The inner citadel (Marcus Aurelius), the Capitol at his statue:** the Meditations as short
  exercises in the most public place in the world: the view from above, the morning resolve, the
  impermanence of all the marble around you.

### Era V (AD 384)
- **Alypius at the games (Confessions 6.8):** section 2.2, Era V.
- **The Emperor in Trajan's Forum (Ammianus 16.10):** walk with Constantius through the Forum of
  Trajan as he gives up hope of copying it, and his Persian prince's remark.
- **The nobles' promenade (Ammianus 14.6, 28.4):** follow a senator through the streets: the
  silk, the carriages, the fifty servants, the fish weighed at dinner; list his vanities.
- **The Altar of Victory (Symmachus and Ambrose):** hear both in the Curia; choose; the Ledger.
- **A tax debtor at the Prefect's (the late laws):** witness; pay his arrears (all your coin) or
  walk on.

### Era VI (AD 455)
- **The two cities (City of God):** walk from the stripped Capitol through the empty palace and
  the Circus to the Lateran; at each place Augustine's argument; at the end you choose where you
  stand.
- **The races while Carthage falls (Salvian):** section 2.2, Era VI.
- **Marcella's house (Jerome, Letter 127):** on the Aventine, the house the Goths sacked in 410,
  and the letter read in it.
- **The Vandals' fourteen days:** watch the carts go down to the river with the temple's gilded
  tiles, and Pope Leo's embassy go out to meet Gaiseric.

### Era VII (AD 552)
- **Philosophy in the empty Curia (Boethius):** Lady Philosophy's consolation; the wheel of
  Fortune turned by hand, each spoke a thing Rome had.
- **The tomb of Hadrian (Procopius 5.22):** break the statues and hurl them down on the Goths at
  the walls.
- **The floating mills (Procopius 5.19):** moor the mill-boats between the bridge piers, set the
  wheels, grind for the besieged.
- **The emptied city (Procopius 7.22):** walk Rome in 546 with no one in it for forty days.

## 5. City tasks (quests) and the regulars' storylines

- **The regulars across the eras** become quest chains. Each regular's family (the baker, the
  soldier, the senator, the fishwife, the barber, and more to add) has a small task per era:
  - Era I: help Numisius bring the harvest in before the levy.
  - Era II: carry Numisius's bread to the Cannae widow.
  - Era III: hide Fabia's daughter from the moneylender.
  - Era IV: warn Stephanus about the informer.
  - Era V: pay the tax on the Felix oven, or don't.
  - Era VI: find the Caecilius heir after the Vandals.
  - Era VII: bury the last Felix.
  Doing them, in order, completes each family's voice in the collections.
- **Favours** (built): messages carried between citizens; expanded to small tasks: fetch the
  midwife, find the lost slave boy before the crier does, return a borrowed ring.
- **The patron:** from Era II you can attach yourself to a great house; its tasks run through
  the eras with its descendants (the Caecilii); in Era III it asks you to carry a bribe.
- **The exempla hunt:** each hero's story is told by someone in its own place (the bridge, the
  camp across the river, the Campus); hear them all.
- **The inscriptions trail:** read every inscription in an era; some are clues to others.

## 6. The daily loop and the calendar

- **A day** is fifteen minutes (built). Dawn: the lararium and the salutatio. Morning: work, the
  Forum, the courts. Noon: bread, the market. Afternoon: the baths, the games. Dusk: the tavern,
  the dice. Night: the streets.
- **The calendar** (built) sets market days, festivals and processions; the recurring rites are
  added to it by era (the vote in its season, the levy in spring, the Saturnalia in December).
- **The tablet** lists what is happening today and tomorrow ("Market day at the Forum Boarium;
  the Roman Games begin in three days").

## 7. How it all completes into the Nexus

- **Lesson points** (books) light stars, and **books** raise Rome's columns on the Tower (per the
  thematic plan).
- **Collections** each bring a Nexus piece back: the exempla bring the Roman door's statues; the
  coins, the treasury under the Tower; the masks, the ancestors' niches; the inscriptions, the
  Tower's dedication; the regulars' voices, the Roman choir.
- **The Ledger** is carved on the Roman tier when Rome is complete: a plain list of what you did
  when it cost (refused the ransom, took the bribe, left the games, paid the debtor's tax, threw
  the statues). No score. Rome's lesson is that nobody else will keep the record.
- **The recurring rites** played in all seven eras (each at least once) raise the tier's frieze:
  the rite's seven faces, carved.

## 8. Engines to build (and what already exists)

| Engine | Built? | For |
|---|---|---|
| Citizens, talk, reactions, favours, regulars | yes | everyone; the quest chains extend favours |
| Calendar, events, processions, gatherings, rain | yes | the recurring rites' timing, festivals |
| Beats (step runner) | yes (Greece) | the books' played moments (Horatius, Scaevola, the devotio...) |
| **Standing** (fides, coin, dignitas, the Ledger) | new | section 1; save keys `rome_fides`, `rome_coin`, `rome_dignitas`, `rome_ledger` |
| **Rites** (exact sequences with restarts) | new | 3.5, the devotio's formula, the oath, the Aeneid's prayers |
| **Choices** (Senate, court, census; costed options) | new | 2.1, 2.5, 3.9, the Ledger |
| **Work loops** (two or three timed actions) | new | 3.1, the mills, the fire's bucket chain |
| **Haggling** | new | 3.2, the market, the money changer |
| **Board games** (tali, duodecim scripta, latrunculi, terni lapilli) | new | 3.4 |
| **The race** (steering, laps, turns) | new | 3.6, and reused for the boat and the Equirria |
| **Directions** (landmark-described destinations, arrival check) | new | 3.3, messenger runs, favours |
| **Collections** (tablet pages) | new | 3.12 |
| **Your room** (save point, lararium) | new | section 1 |

All content goes in JSON under `content/rome/` (`rites.json`, `trades.json`, `games.json`,
`choices.json`, `collections.json`, per era), so most of the world is written, not coded.

## 9. Build order (phases)

1. **Standing and your room.** Fides, coin, dignitas, the Ledger; the room in the Subura; the
   lararium rite. Everything else pays into these.
2. **Rites and choices.** The two engines behind the recurring rites; then the vote, the funeral,
   the levy and the sacrifice in all seven eras.
3. **Work, haggling, dice.** The trades, the market, the tavern games, the money changer.
4. **Directions and messenger runs**, and the regulars' quest chains on top.
5. **The games**: the race engine, the Circus, betting, the Colosseum day, Alypius.
6. **The books' places**, era by era, as the reading list is connected (each a place like the
   Greek rooms, using the engines above).
7. **Collections and the Nexus completion.**

## 10. Open for later

- The reading list connection (the books named here are placeholders for the list's own).
- Whether the player may take office (quaestor to consul) as a long chain across Eras II–III.
- How much of Era IV's arena is shown (the plan: witnessed, the camera may turn away, never
  performed).
