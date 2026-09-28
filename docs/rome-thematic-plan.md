# Rome: the thematic plan (the Roman substrate)

Status: plan only, nothing here is built yet (BB1, 2026-09-28). It fixes which authors and works
belong to which era of the city, where in Rome each book's place stands, what the player does
there, and how finishing Rome completes its part of the Nexus.

Source of the reading list: the Rome modules of Essential-Reading-List were not readable from this
session. This plan is written from the ancient sources themselves. When the Essentials Rome list is
imported (`tools/import_works.py`), each of its works takes the era and zone given here. A work the
list doesn't include stays in the city as a witness (its author walks the streets, its words are in
the citizens' mouths) rather than as a book to master.

## 1. The vision

Greece gave the player reason: definition, argument, proof, the good life. Rome gives the player
virtue in public, and its loss. That means law, duty, the res publica, the citizen who serves, and
then the long lesson of what happens when a people keeps the forms and loses the substance.

The city is one place, walked through seven eras. It falls from the age of heroes to the empty city
of 552, and the player falls with it, era by era, as the books are mastered. The descent should be
felt: the light greys, the tune turns minor and then to an echo, the streets empty, and the people's
talk goes from "you have my word" to "have you eaten?".

Three Roman writers state the arc outright. The plan uses them as its spine:
- **Livy, Preface 9:** "how, as discipline slackened, morals first gave way, then sank lower and
  lower, and then began to fall headlong, until we have reached these times, when we can endure
  neither our vices nor their cure."
- **Horace, Odes 3.6:** "Our parents' age, worse than our grandparents', bore us still worse, and
  we shall soon bring forth a more wicked offspring." This opens the Rome world, on the Nexus stele.
- **Polybius 6.57:** every constitution decays; Rome's too will, when prosperity breeds ambition
  and the people grow arrogant.

What the player carries to the Nexus is the Reformed Man's Roman lesson:
- virtue is a public practice, kept up by institutions, examples and memory;
- when it is not renewed, every form survives and nothing is left inside it.

## 2. The rules that tie books, eras and the city together

- **One book, one era, one zone.** Each Roman book has a place in its author's own time and in one
  zone of the city, built the way the Greek rooms are:
  - its teacher (the author);
  - its lesson points and stones;
  - a played activity or beat;
  - the place lost at first, then mended piece by piece.
- **Mastering a book moves the city's era forward to that book's era.** This is how the gating
  already works: `rome_age_reached()` follows mastered books. The city of the hub is always the
  latest era reached. The navel of the city lets you walk back to any earlier era.
- **Zones open with their books.** Each zone is fenced until the first book set in it is mastered,
  then open and revisitable in every era.
- **Reading order follows the fall.** Rome's books are read in the order of the era they belong to,
  heroes first, so the city only declines as the reading goes on.
  - This moves the Rhetorica from first to the late-Republic era, where its own date (85 BC) puts
    it.
  - If the Essentials order differs, the city still follows the latest era reached, never the list
    order.
- **Witnesses walk their era.** Each era has one or two authors (or their characters) walking the
  city, talking in their own voice (Claude's persona given their passages). Citizens' lines, news
  and events are rewritten from the era's own sources, cited in `content/rome/`.
- **Greek threads carry over.** Polybius is a Greek in Rome; Plutarch sets Greek and Roman lives in
  parallel; the Rhetorica is Greek rhetoric made Roman. Horace: "Captive Greece took her savage
  conqueror captive" (Epistles 2.1.156). The heroic era's calm towards Greek cleverness turns, by
  the Empire, into Rome's surrender to Greek luxury.

## 3. The seven eras

### Era I: the Age of Heroes, 280 BC

**Theme:**
- virtus, pietas, fides; exempla, the heroic stories Rome told itself to be good;
- libertas won from the kings;
- the farmer-soldier; enemies made kin (Sabines, Samnites, Umbrians);
- calm before Greek cleverness (Pyrrhus, Tarentum).

**Witnesses:**
- Contemporary: nothing survives in Roman prose. Ennius' *Annales* (fragments) is the nearest
  voice: "Rome stands on its ancient ways and its men."
- Looking back:
  - Livy, *Ab Urbe Condita* books 1, 2, 8 and 10 (founding, kings, Lucretia and Brutus, Horatius,
    Scaevola, Cloelia, Coriolanus, the Deciuses);
  - Plutarch's *Romulus*, *Numa*, *Publicola*, *Camillus*, *Coriolanus* and *Pyrrhus*
    (Fabricius, Curius);
  - Dionysius of Halicarnassus, *Roman Antiquities*.

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Livy, books 1–2 (the kings and the first Republic) | the Palatine's old places: the Hut of Romulus, the Lupercal, the steps of Cacus (`palatina`) | Livy, as the old storyteller (his own time is Augustan; his room is the memory of the city) | beats played as the heroes: **Horatius** holds the Sublician bridge while it is cut behind him (at the river, `aventinus`); **Scaevola** holds his hand in the Etruscan king's fire (across the Tiber, `trans_tiberim`); **the Sabine women** run between the two armies in the Forum valley; **Brutus's oath** over Lucretia's body ends the kings (told, not shown). Stones: exemplum, pietas, virtus, fides, libertas, mos maiorum |
| Plutarch, *Pyrrhus* (with Fabricius and Curius) | the Capitol and the Senate's old house (`capitolium`) | Plutarch (the Greek who admired Rome) | **blind Appius** is carried into the Senate: you speak or vote "no peace while a king is in Italy"; **Fabricius** in Pyrrhus's tent refuses the gold and doesn't flinch at the elephant (a beat of stillness); **Curius's turnips**: the Samnite envoys at his hearth |
| Livy, books 8 and 10 (the devotio) | the Campus Martius as the mustering field (`campus_martius`) | Livy | **the devotio of Decius Mus**: veil the head, stand on a spear, speak the formula with the priest, ride into the Gauls (Sentinum, 295 BC). The era's heart |

**The city shows:** the army marching out, the old tales told at dusk, sacrifices, market day. It is
tufa and timber, bright and simple.

### Era II: the Republic in its prime, 201 BC

**Theme:**
- the constitution and the discipline that won the Hannibalic war;
- the refusal to ask for peace after Cannae;
- the aristocratic funeral as a school of virtue;
- the first Greek luxuries, and Cato against them.

**Witnesses:**
- Contemporary:
  - Polybius (a Greek hostage in Rome from 167 BC and friend of the Scipios): *Histories* 3
    (Hannibal) and 6 (the constitution, army, camp, funerals, religion, decline);
  - Plautus' comedies (the city laughing at itself at the games);
  - Cato, *On Agriculture* (the farmer-soldier's creed).
- Looking back:
  - Livy books 21–30 (Hannibal's war: Cannae, the ransom debate, Zama);
  - Plutarch's *Fabius Maximus*, *Cato the Elder* and *Aemilius Paullus*.

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Polybius, *Histories* 6 | the Campus Martius: voting pens, Villa Publica, parade ground (`campus_martius`) | Polybius | **the census**: be enrolled into your class and century; **the levy and the oath**; **lay out a legionary camp** from Polybius's own plan (6.27–42), streets, gates and tents; **the funeral of a great man** (6.53–54): the ancestors' masks walk, and you give the praise from the Rostra. Stones: the mixed constitution, consuls, Senate, people, discipline, religio, anacyclosis |
| Livy, books 21–22 and 30 | the Forum and the Curia, news arriving (`palatine_forum`) | Livy | **the news of Cannae** comes to the Forum; **the Senate's choice** not to ransom the prisoners (22.58–61), argued and voted; **Zama**: open the lanes for Hannibal's elephants and close them (a beat) |
| Cato, *On Agriculture* (with Plutarch's *Cato*) | a farm at the Colline Gate, and the Basilica Porcia later (`collina`) | Cato the Elder | **run the farm by Cato's rules**; as censor, strike a senator off the roll for luxury |
| Plautus, one comedy (e.g. *Miles Gloriosus*) | a wooden stage at the Roman Games, by the Circus (`aventinus`) | Plautus | **watch and play a scene**: the braggart soldier, the clever slave. Rome laughs at Greeks and at itself |

**The city shows:** Scipio's triumph, the levy on the Capitol, a hero's funeral, the Cannae men home.
It is proud, plain and pious.

### Era III: the Late Republic, 50 BC ("the madness")

**Theme:**
- eloquence and ambition turned against the Republic;
- faction, bribery, gangs, generals' armies;
- the Republic's forms kept while its spirit dies;
- private refuges: Epicurus, Stoic duty, love poetry.

**Witnesses:**
- Contemporary:
  - Cicero (*Against Catiline*, *On Duties*, letters);
  - Sallust, *The War with Catiline*: decline dated from Carthage's fall (10–13);
  - Caesar, *Gallic War* and *Civil War*;
  - Lucretius, *On the Nature of Things*;
  - Catullus;
  - Quintus Cicero's *Handbook on Electioneering* (authorship disputed);
  - the *Rhetorica ad Herennium* (built).
- Looking back: Plutarch's *Gracchi*, *Marius*, *Sulla*, *Pompey*, *Crassus*, *Caesar*, *Cato the
  Younger* and *Cicero*.

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Rhetorica ad Herennium (built) | the Forum and the Via Nova, 85 BC (`palatine_forum`) | the unknown Author | the memory house; the five canons; the court (as built) |
| Cicero, *Against Catiline* 1 | the Temple of Jupiter Stator, the Senate in session, 63 BC (`palatine_forum`) | Cicero | **deliver the First Catilinarian** using the Rhetorica's canons (invention, arrangement, style, memory, delivery), with Catiline sitting alone as the senators move away from him |
| the *Handbook on Electioneering* | the Forum and the Campus at election time (`palatine_forum` and `campus_martius`) | Quintus Cicero | **canvass for office**: walk the Forum with a nomenclator whispering names, promise, flatter, buy. Every rule in the handbook works and every one corrupts. The corruption is played, not told |
| Sallust, *Catiline* | the Subura at night, the conspirators' house (`suburana`) | Sallust | **the conspiracy** from inside, and Sallust's verdict: stones on avarice, ambition and the fall after Carthage |
| Lucretius, *On the Nature of Things* | a garden on the Esquiline, above the pits of the poor dead (`esquilina`) | Lucretius | **the fear of death taken apart**, atom by atom, in sight of the burial pits; the Epicurean retreat |
| Cicero, *On Duties* | Cicero's house on the Palatine, 44 BC (`palatina`) | Cicero | **the honourable and the useful**: choices between them. His last book, written as the Republic dies |
| Plutarch, *Caesar* (the Ides of March) | the Curia in Pompey's portico (`campus_martius`) | Plutarch | **the Ides of March**, witnessed as a senator (a beat). The end of the era |

**The city shows:** bought votes, evictions, fires with speculators, the slave auction, the Subura by
night, a grain riot. Gangs, generals, noise.

### Era IV: the Empire at its height, AD 150 (with the Augustan founding at its gate)

**Theme:**
- order bought with liberty: "they rush into slavery" (Tacitus, *Annals* 1.7);
- pietas made into the imperial cult, and destiny into propaganda;
- luxury, spectacle, bread and circuses, informers;
- the Stoic inner citadel as the virtue left to private men.

**Witnesses:**
- Contemporary:
  - Juvenal, *Satires* 3 (the city) and 10 ("bread and circuses", 10.81);
  - Pliny the Younger's letters (including 10.96 on the Christians);
  - Martial;
  - Marcus Aurelius, *Meditations*;
  - Fronto.
- Looking back:
  - Virgil, *Aeneid* 1, 2, 4 and 6 (6.756–886, the parade of Rome's heroes, "to spare the humbled
    and war down the proud");
  - Horace, *Odes* 3.2, 3.6 and the *Carmen Saeculare*;
  - Augustus, *Res Gestae* (the bronze tablets at his Mausoleum);
  - Livy's Preface;
  - Seneca, *Letters* 7 (the games) and 56 (the noise of the baths);
  - Tacitus, *Annals* 1 and *Agricola* 30 ("they make a desert and call it peace");
  - Suetonius, *Augustus* and *Nero*.

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Virgil, *Aeneid* (books 1, 2, 4, 6) | the Forum of Augustus: Mars Ultor, the hall of the great men (`palatine_forum`) | Virgil | **the parade of heroes**: walk the statues of the summi viri and name them. They are Era I's heroes, now marble serving a dynasty (the callback of the whole world); **Dido's pyre**; **Aeneas carrying his father**: pietas as burden |
| Horace, *Odes* | Maecenas's gardens on the Esquiline, and the Secular Games (`esquilina`) | Horace | **Odes 3.6 read at the start of the Rome world**; the Secular Games' hymn sung; "it is sweet and fitting to die for one's country" (3.2), weighed |
| Augustus, *Res Gestae* | the Mausoleum and the Altar of Peace (`campus_martius`) | Augustus (his words on bronze) | **read the bronze**: what it says and what it leaves out (the proscriptions, the civil wars). Stones on the Principate |
| Tacitus, *Annals* 1 | the Curia and the Palatine palace (`palatina`) | Tacitus | **the Senate under Tiberius**: every choice is flattery or ruin; the servility game |
| Juvenal, *Satires* 3 and 10 | an insula in the Subura (`suburana`) | Juvenal | **a night in the Subura**: carts, pots from the windows, the collapsing block, the mugger, the rich man's escort. Survive it |
| Seneca, *Letters* | the baths of Trajan and the Colosseum (`suburana`) | Seneca | **the games** (Letter 7): stay and watch, or leave. The crowd changes you |
| Marcus Aurelius, *Meditations* | the Capitol, at his equestrian statue (`capitolium`) | Marcus Aurelius | **the inner citadel**: the emperor-philosopher's private virtue in the most public place in the world. The last good ruler |

**The city shows:** the arena, informers, executions at the gate, families sold apart, marble over
everything.

### Era V: the Late Empire, AD 384 (moved from 330 so its witnesses are eyewitnesses)

**Theme:**
- fear and taxes; trades bound by law;
- the old gods forbidden, the new faith in power;
- the aristocracy's vanity and the crowd's idleness;
- the soul's turn inward.

**Witnesses:**
- Contemporary:
  - Ammianus Marcellinus 14.6 and 28.4 (Rome's vain nobles and idle plebs) and 16.10 (the Emperor
    Constantius dumbstruck in Trajan's Forum, 357);
  - Symmachus, *Relatio* 3, for the Altar of Victory (384), against Ambrose's letters;
  - Augustine, *Confessions* 5–6 (in Rome, 383–384);
  - Jerome's letters from Rome.

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Augustine, *Confessions* (books 5–6) | the Colosseum, and a house on the Caelian (`suburana`) | Augustine | **Alypius at the games** (6.8): dragged in, eyes shut, then the roar, and he looks. Played; **the restless heart** stones |
| Ammianus Marcellinus (14.6, 16.10, 28.4) | Trajan's Forum, and the nobles' palaces on the Quirinal (`collina`) | Ammianus | **the Emperor's visit**: stand beside Constantius in Trajan's Forum as he gives up trying to copy it; **the nobles' promenade**: silk, eunuchs, fifty servants, vanity catalogued |
| Symmachus, *Relatio* 3 (against Ambrose) | the Curia Julia and the Altar of Victory (`palatine_forum`) | Symmachus | **the Altar of Victory debate**: "not by one road alone can one reach so great a mystery". Hear both sides, choose, and live with it |

**The city shows:** torture for unpaid taxes, bread riots, church offices bought, fear. The tune has
gone to its echo.

### Era VI: the Collapse, AD 455

**Theme:**
- absurd decadence: emperors made and murdered in weeks;
- the Senate arguing over seating while Africa's grain is gone;
- relics and charlatans;
- the Christian verdict on the earthly city.

**Witnesses:**
- Contemporary:
  - Salvian, *On the Government of God* 6–7 (the games while the barbarians are at the walls;
    Romans worse than the barbarians);
  - Sidonius Apollinaris' letters (the last elegance);
  - Pope Leo's sermons (Peter and Paul, Rome's new founders, sermon 82);
  - Prosper of Aquitaine.
- Looking back at 410:
  - Augustine, *City of God* 1 and 19 (the two cities);
  - Jerome, Letter 127 ("the city which had taken the whole world was itself taken").

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Augustine, *City of God* (1, 14, 19) | from the Palatine down to the Lateran (`palatina` to the Lateran) | Augustine | **the two cities walked**: the earthly (the stripped Capitol, the empty palace, the Circus) and the heavenly (the church). You choose the road |
| Salvian, *On the Government of God* | the Circus Maximus on race day (`aventinus`) | Salvian | **the races while Carthage falls**: the news arrives mid-race and the crowd doesn't stop. You can't make it stop |
| Jerome, Letter 127 | Marcella's house on the Aventine, sacked (`aventinus`) | Jerome | **the lament**: the sack of 410 remembered in the house it happened to |

**The city shows:** the Vandals just gone, relic stalls, bets on the next emperor's death, riots.

### Era VII: the Fall, AD 552

**Theme:**
- ruin, siege, famine, numbness;
- what is left: philosophy in prison, and the Church feeding the city;
- the monuments as quarries and fortresses.

**Witnesses:**
- Contemporary:
  - Procopius, *Wars* 5–7: the siege of 537, the floating mills on the Tiber (5.19), statues hurled
    from Hadrian's tomb (5.22), the city emptied in 546 (7.22);
  - Boethius, *Consolation of Philosophy* (524);
  - Cassiodorus, *Variae* (the last care for the monuments).
- Epilogue: Gregory the Great, *Homilies on Ezekiel* 2.6 ("Rome, once mistress of the world… now
  empty").

**Books to master:**

| Book | Place (zone) | Teacher | Activities |
|---|---|---|---|
| Boethius, *Consolation of Philosophy* | the empty Curia, the last senators (`palatine_forum`) | Lady Philosophy | **the wheel of Fortune**: everything the city was, given back as a lesson in what can't be taken. The last Roman book |
| Procopius, *Gothic War* (books 5–7) | Hadrian's tomb, the Tiber and its mills (`trans_tiberim` and the river) | Procopius | **defend the tomb**: throw the statues down on the Goths (5.22); **run the floating mills** to feed the besieged; **walk the emptied city of 546** |

**The city shows:** the starving, the dead, the empty city, and the Church's bread.

## 4. The zones, gathered

| Zone | Eras and books |
|---|---|
| `palatine_forum` (the Forum, the Curia, the Via Nova) | II Livy (Cannae news, the ransom debate); III Rhetorica, *Against Catiline*, the electioneering handbook; IV *Aeneid* (Forum of Augustus); V Symmachus (Altar of Victory); VII Boethius (the empty Curia) |
| `palatina` (the Palatine) | I Livy 1–2 (the founding places); III *On Duties* (Cicero's house); IV *Annals* (the palace); VI *City of God* (the empty palace, the start of the walk) |
| `capitolium` (the Capitol) | I *Pyrrhus* (Appius, Fabricius); IV *Meditations* (the equestrian statue) |
| `campus_martius` | I the devotio; II Polybius (census, levy, camp, funeral); III the canvass, the Ides of March; IV *Res Gestae* (Mausoleum, Altar of Peace) |
| `suburana` (the Subura, the Caelian) | III *Catiline*; IV Juvenal, Seneca; V *Confessions* |
| `esquilina` | III Lucretius (the garden above the pits); IV Horace (Maecenas's gardens) |
| `collina` (the Quirinal) | II Cato (the farm at the Colline Gate); V Ammianus (the nobles' palaces) |
| `aventinus` (the Aventine, the Circus, the river port) | I Horatius at the bridge; II Plautus at the Games; VI Salvian (the races), Jerome (Marcella's house) |
| `trans_tiberim` | I Scaevola in the Etruscan camp; VII Procopius (Hadrian's tomb) |

Every zone is visited in at least two eras, so the player sees the same streets fall.

## 5. How Rome completes into the Nexus

This mirrors Greece; the exact pieces are to be written into `content/nexus.json`.
- **Rome's door on the Nexus rim warms** when the first Roman book is mastered (the stele already
  opens it). Its stele carries Horace, *Odes* 3.6.
- **A column for each Roman book** rises on the Tower of the Reformed Man's Roman tier, as the Greek
  books raise theirs.
- **Rome's bridge to the Heart:** when half the Roman books are mastered, the bridge from the Heart
  to Rome's island mends.
- **The Roman tier stands whole** when every Roman book is mastered. It carries the Roman lesson
  into the Tower: law, duty and the res publica, and the warning (Polybius 6.57, Livy's Preface)
  that forms outlive their virtue unless it is renewed.
- **After completion:** the city of Rome can be walked in any era from the navel. The heroic age is
  lit as the Nexus remembers it, the rest as they were.
- **Hand-off to the next world:** Augustine and Boethius belong to Rome's last eras here and to Late
  Antiquity next. Rome reads the passages about the city; Late Antiquity reads the whole books.
  The fall of Rome is the doorway into the Late Antiquity world.

## 6. Decisions still open

1. **Import the Essentials Rome modules**, and settle which books are read in full here and which
   stay witnesses.
2. **Move Era V from AD 330 to 384.** Recommended, so Ammianus, Symmachus and Augustine are
   eyewitnesses.
3. **Livy's placement.** He is Augustan. Is he the storyteller of Eras I–II only, or also a book of
   Era IV (his Preface as the decline stated)? Recommended: both. His books teach Eras I and II;
   his Preface is a stone in Era IV.
4. **The Rhetorica moves from Rome's first book to Era III** under reading order by era.
5. **Handling Lucretia** (Era I): the oath of Brutus is played; her story is told, not shown.
