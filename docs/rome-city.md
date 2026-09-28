# Rome: the city is the world's hub

Decided with BB1 (2026-09-28):

- The Rome world's hub is the whole city of ancient Rome, laid out on a map of the ancient city and
  shrunk. Greece has its Shore of gateways; Rome has the city, walked street by street, with its
  regions, its people and its monuments. Rome's books stand in its zones behind Roman gateways.
- The city lives and dies. It goes through four ages, from the Republic's rise and glory to the
  empty city of the 6th century.
- No grass underfoot: the ground is the city's trodden streets and paving, and rubble in the
  emptied city. Trees and gardens do grow: in the squares, the courtyards, on roof terraces, on the
  hills and along the river.
- The city is large but walkable, full of life in its first act (the Republic), with a day and
  night, a village-square town theme, and citizens with names and trades who talk and react.
- The *Rhetorica ad Herennium* is Rome's book, not Greece's. It has left the Shore and the Greek
  reading list, and is the first book of Rome's. The *Isagoge* stays in Greece.

## Where things are
| What | File |
|---|---|
| The map: hills, Tiber, island, Servian wall and gates, Circus, landmarks, zones | `content/rome/republican_rome.json` |
| The living city: ages, monuments and their years, streets, bridges, aqueducts, regions, open squares, where people cluster in the fall, what people say | `content/rome/city.json` |
| Rome's reading list | `content/rome/works.json` (module `r1`) |
| Rome's rooms and beats | `content/rome/rooms.json`, `content/rome/beats.json` |
| The map projection, ground, river, bridges, walls, streets, blocks of houses | `scripts/hall/rome_map.gd` |
| One builder per kind of monument | `scripts/hall/kit_urbs.gd` |
| The hub: ages, people, the navel, the gateways | `scripts/hall/places_rome.gd` (`urbs`) |
| The day and night, who is out, what people say out loud | `scripts/hall/urbs_life.gd` |
| A citizen: name, trade, family, what they say, who Claude plays | `scripts/hall/citizen.gd`, `content/rome/people.json` (from `tools/make_rome_people.py`) |
| The talk box | `scripts/hall/talk.gd` |
| Every job in the city | `docs/rome-jobs.md` |

- **The map:** the layout follows W. R. Shepherd's *Plan of Republican Rome* (Historical Atlas,
  1911; about 40 BC; public domain). A copy is in `docs/shepherd-republican-rome.jpg`.
- **Positions:** in real metres east and north of the Forum (41.8922 N, 12.4852 E). The plan's
  landmarks are from Wikipedia's coordinates or read off the plan. The monuments in `city.json`
  are placed from the modern coordinates of their remains. Both are approximate (unverified to the
  metre).
- **Scale:** the game shrinks the city to 0.35 of its size, with north toward -Z. Buildings stand
  at about half their real size, so the spaces between them still read.
- **Travel:**
  - In the Nexus, Rome's door is no longer sealed. Its stele on the rim takes you to the city
    (`"hub": "urbs"` in `content/worlds.json`).
  - Rome asks who you are there: Peregrinus (Zen) or Discipulus (Student).

## Size
- **Where you can walk** (`walkable` in `city.json`) is the core of the city: the Servian city, the
  Forum Boarium and the river port, the island, and the southern Campus Martius with the theatres
  and the Pantheon. It is about 850 by 875 m of game ground, three minutes' walk across.
  Boundary stones and an unseen wall mark its edge.
- **Beyond it** the city goes on to the line of Aurelian's wall (`outer`), in simpler houses, seen
  and not walked. That keeps the size manageable while still reading as a great city.

## The four ages, and the first act
| Age | Year | People | The city |
|---|---|---|---|
| The Republic | about 50 BC | 190 | Temples of Jupiter, Saturn, Castor, Vesta, Concord, Juno Moneta, Magna Mater, Ceres, Diana, Mars in the Circus, Venus Victrix on Pompey's new theatre; the Tabularium; Basilicas Aemilia and Sempronia; the Servian wall whole; low houses of plaster in creams and whites; the Campus Martius still open |
| The Empire | about AD 150 | 240 | The imperial fora with Venus Genetrix and Mars Ultor, Trajan's forum, column and markets; the Colosseum, the Colossus and the Meta Sudans; the Pantheon; Venus and Rome; baths; the palace on the Palatine; the Claudian aqueduct; flats of up to six storeys, ochre, rose and red |
| The Late Empire | AD 384 | 190 | Baths of Caracalla and Diocletian; the Arches of Septimius Severus and Constantine; the Basilica of Maxentius; Aurelian's wall; the Lateran and St Peter's; greyer light, the tune in a minor key |
| The Fall | AD 552 | 36 | After the Gothic War: monuments in ruin, the aqueducts dry, most houses broken walls overgrown with bushes and trees, rubble underfoot, the few people in the bend of the Tiber |

- **The first act is the Republic.** The city is young and loud until the Roman books move the
  years on. `rome_age_reached()` takes the age (`"age"` in `content/rome/works.json`) of the latest
  Roman book begun, so for now, with only the Rhetorica, Rome stays in the Republic.
- **The navel of the city,** by the Rostra, says so. Once a later age is reached, it lets the years
  pass that far, and from the last age reached it goes back to the Republic.
- **For testing:** `"rome_reached": 3` in the save, or `--age=N` for screenshots, opens every age.
- **An early-Republic prologue (about 300 BC)** was considered and left out: no book anchors it,
  and it would be a small tufa-and-timber town, not the lively city. It could come later with Livy.
- A monument stands from its year of building (`from`), as a ruin from `ruin`, and is gone from
  `gone`.

## The city's fabric
- **Ground:**
  - One height-field sheet of trodden grit and cobbles, tinted in broad patches (dusty, trodden
    dark, sun-bleached, lighter on the hills), so it reads as earth and wear rather than a pattern.
    It is rubble in the Fall.
  - Travertine steps before many shops, basalt streets, and the Forum's slabs.
  - The seven hills rise in walkable domes.
- **River:** the Tiber runs between its banks, with the island, and bridges standing by date.
- **Houses:**
  - A bent, twisting grid of blocks, each split into two or three houses of their own height,
    kind and colour.
  - Flats have a storey of arched shops, plaster or brick storeys with windows above, sometimes a
    top storey set back, and a tiled roof or a roof terrace with planters, a potted tree and a
    vine pergola. Some have wooden balconies with pots and washing, and awnings over wares.
  - The houses of the rich stand round courtyard gardens with a tree and a pool.
  - Warehouses line the river, and single-storey rows of shops line some streets.
  - Little squares hold fountains with a lamp.
  - Each house's plaster colour is its own, drawn from the age's palette.
- **Trees:** stone pines, cypresses by the temples, round-headed trees in the squares, along the
  river and in the gardens on the hills, and bushes in the ruins.
- **Walls and aqueducts:**
  - The Servian wall stands.
  - Aurelian's wall stands far off from AD 275.
  - The Marcia, the Claudia and Nero's arches carry water until they are cut.

## Day and night
- A whole day takes fifteen minutes (`urbs_life.gd`). The sun crosses from east to west, and the
  sky, fog and light change through dawn, morning, noon, a golden afternoon, dusk and night.
- At night the stars come out, the windows light up (every window is a real pane: dark shutters by
  day, lamplight by night), and the lamps by the fountains are lit.
- **People keep hours.** Most go home at dusk and come out after dawn. The early and the late are
  about at the edges of the day. The watch, the innkeepers and the carters (allowed in only at
  night) are out after dark.
- The hour is kept when you leave the city and come back. Screenshots: `--hour=H`.
- In the later ages the light is greyer and the air thicker (`GLOOM` in `places_rome.gd`).

## Music
- **The town theme** (`tools/make_music.py`, `render_urbs`) is meant to sound like a game's
  village square on a fine day, in the spirit of Zelda and Harvest Moon.
  - F major, 120 beats a minute, sixteen bars in a 32 s loop.
  - An ocarina carries the tune over a marimba's off-beat chords, a plucked bass, a soft kick, a
    woodblock and a shaker.
  - The crowd and the birds play by day.
- **By night** the same tune plays on a music box over a soft pad, with crickets.
- **Under the late Empire** the same tune is in F minor and a little out of tune (`urbs_late`).
- **In the Fall** there is only the echo of Rome's old tune and the wind.
- The music zones in `music.gd` are `urbs`, `urbs_late` and `urbs_fall`. Their layers need `day`
  or `night`.

## The citizens
- Everyone in the city is a citizen with a name, a trade, a home region, a family, a mood and a
  patron house.
- **Names** follow the age and the person:
  - citizens have the three names;
  - women have their family name and a cognomen;
  - freedmen take their old master's family name with a Greek cognomen;
  - slaves have Greek names;
  - foreigners have their own people's names: Greek, Syrian, Egyptian, Jewish, Gaulish, Spanish,
    African, German, and Gothic late on;
  - late and Christian Romans have saints' names.
- **Trades:** 68 jobs walk the city, each in its own ages, dress and place:
  - at a stall, at a shop door, in the street, at the river, at a temple, or on patrol;
  - bakers, butchers, fishmongers, fullers, cobblers, smiths, potters, the watch, charioteers,
    gladiators, midwives, undertakers, deacons, catacomb diggers, beggars, pilgrims and more.
  - `docs/rome-jobs.md` lists every job of the city, with its Latin name, the ages it belongs to,
    and which ones walk the game.
- **Talking to someone:** press F on anyone to stop them and talk. A box along the bottom shows
  their name and trade.
  - Ask the six topics (keys 1 to 6): who they are, their work, their life, the news of the age,
    their gods, and what's around (the nearest monuments, by name).
  - Or type anything. With an API key, Claude plays the citizen: first person, plain, of their
    trade and time, knowing nothing later, never a scholar (`Citizen.persona`). Without a key,
    what you type is matched to a topic and they answer from their own lines.
- **Reactions:** as you pass, people greet you in their own way; sellers cry their wares; walk
  into someone and they curse you. The words appear over their heads and fade.
- Screenshots: `--talk` stops the nearest citizen and asks about their work.

## Tone: the fall from virtue
Rome is a moral arc, and the descent is meant to be palpable, harsh and depressing (decided with BB1,
2026-09-28). The first act is the age of heroes, simple and whimsical; each age after it is harder,
greyer and emptier, and the music darkens with it.

| Age | Year | Spirit | What the streets show | Music |
|---|---|---|---|---|
| The Age of Heroes | 280 BC | simple, cheerful, sure of Rome and its gods; farmer-soldiers; Horatius, Scaevola, the Sabine women, Decius Mus at Sentinum, Curius and his turnips, Fabricius and Pyrrhus's gold; Samnites, Sabines and Umbrians fought and made kin; Greek arrogance met with calm | the army marching south to Pyrrhus, a veteran telling the old tales at dusk, sacrifices, market day | the bright town theme |
| The Republic | 201 BC, after Zama | virtus, pietas, fides, gravitas, frugality, service and sacrifice | Scipio's triumph, the levy on the Capitol, a hero's funeral with his ancestors' masks, the Cannae men home at last | the bright town theme |
| The Late Republic | about 50 BC | the virtues spoken of and betrayed: ambition, faction, money, gangs | bought votes, evictions, fires with speculators, the slave auction, the Subura by night, a grain riot | the tune in minor, out of true |
| The Empire | AD 150 | peace, plenty, spectacle; servility, informers, idleness | the arena, informers, executions at the gate, families sold apart | the tune in minor |
| The Late Empire | AD 384 | fear, cruelty, corruption, trades bound by law, the old gods forbidden | torture for tax arrears, bread riots, church offices bought | only the echo |
| The Collapse | AD 455 | absurd decadence: emperors murdered in weeks, the Senate arguing seating while Africa's grain is gone, relic sellers, betting on the next emperor's death | the Vandals just gone, relic stalls, bets at the Circus, riots, the Subura by night | only the echo |
| The Fall | AD 552 | ruin, famine, numbness | the starving, the dead, the empty city | only the echo and the wind |

- **People:** every citizen, the chatter, the gossip, the news, the gods, the moods and the
  regulars' stories follow the age.
  - The heroes' generation and the Republic of 201 BC have their own lines for each trade (`hero`
    and `rise` in `people.json`, and `life_heroic` and `life_early`).
  - The later ages speak plainly of slavery, debt, disease, violence and bought power, never
    explicitly.
- **The regulars' families:**
  - Numisius the farmer, whose son saw Decius ride out, becomes the baker whose son died at
    Cannae. His descendants are chained to the oven by law, his widow is left with a cold oven
    after the Vandals, and the last of them starve in the siege.
  - The senator Caecilius, embarrassed by one silver salt cellar, becomes, generations on, the
    illustrious nobody who paid both the Vandals and the general.
- **Claude:** when Claude plays a citizen, it is told the spirit of their age (`Citizen.SPIRIT`).
- **The years pass as Roman books are mastered.** Until the Rhetorica (a late-Republic book) is
  mastered, Rome stays in the age of heroes. Mastering it lets the navel of the city pass the years
  as far as the late Republic.
- `--age=N` (0 to 6) shows any age for screenshots.

## The city's days and memory
These live in `scripts/hall/urbs_town.gd`, with the content in `content/rome/town.json`. Add to that
file to add life; no code is needed.

- **The calendar:**
  - A day counter runs, and is kept in the save.
  - Every eighth day is a market day: a crowd and sellers in the Forum Boarium.
  - Festivals fall on set days of a 24-day year: the Saturnalia, the Lupercalia, the Parilia, the
    Roman Games, and Easter in the late ages. Each brings a crowd with its cries, and it is what
    everyone's news is about that day.
- **At their hours:**
  - Processions walk their street and go: a funeral with pipers and mourners, a wedding with
    torches at dusk, a sacrifice with its garlanded ox.
  - Gatherings stand for a while: a senator speaking from the Rostra, the crier's auctions, market
    day, the deacons' bread in the late ages.
  - Processions and gatherings are citizens like everyone else, and go when their time is over.
- **Rain:** some days rain comes for an hour or two. Drops fall around you, someone shouts about
  it, and the music takes a rain layer.
- **Streets:**
  - Pigeons peck in the Forum and fly up when you run through them.
  - Dogs trot along the streets.
  - Smoke rises from the bakers' and smiths' roofs by day.
  - Painted election notices and scratched words appear by the shop doors; the chi-rho appears in
    the late city.
- **Sounds:** the three nearest trades are heard at their doors: the smith's forge, the weaver's
  loom, the tavern's crowd at night, the bakery's fire, the fuller's water.
- **People talk to each other:** two acquaintances passing stop and exchange a word or two, by name.
- **Memory** (`rome_met` in the save):
  - Anyone you have talked to says "You again!" and greets you as you pass.
  - Asking the news brings gossip about people you have met.
  - Now and then someone asks you to carry a message to someone nearby. Deliver it, and both thank
    you.
- **The regulars:**
  - Five people keep fixed places, and their story moves on each time you talk: Felix the baker,
    Hilarus the gladiator, Caecilius Rufus the senator, Fabia the fishwife, and Stephanus the barber.
  - In the later ages their descendants keep the same places. Felix's bakery passes down the family,
    and in AD 552 a beggar remembers it.
- **Screenshots:** `--day=N`.

## Resolution
- Rome renders at 854x480 with Kit.detail 3, sharper than Greece's 320x180. The later worlds'
  ladder moves up to keep in order.
- The city's own textures are 64 pixels to Greece's 32:
  - `r_ground`: trodden grit with cobbles;
  - `r_wall`: pale plaster tinted house by house;
  - `r_brick`: brick with bonding courses;
  - `r_shop`: arched shop fronts;
  - `r_roof`: curved tiles;
  - `r_slab`: travertine.

## The Rhetorica's zone
The *Rhetorica ad Herennium* was written in Rome about 86-82 BC, by an unknown author for Gaius
Herennius. Its place is the zone `palatine_forum`, the Forum and the Via Nova under the Palatine,
about 85 BC.

- Its gateway stands in the Forum, near the Temple of Jupiter Stator.
- Inside, the zone is fenced as before, and the rest of the Republic's city stands about it.
- While the place is still lost, that city is grey rubble. Once mended, it is brick and tile.
- Its own gateway leads back into the city.

## Zones
| Zone | Covers | Opens with |
|---|---|---|
| `palatine_forum` | the Forum, and the Via Nova under the Palatine's north slope | the Rhetorica ad Herennium (open) |
| `capitolium` | the Capitol and the Arx | a Rome book, later |
| `palatina` | the Palatine and the Velia | later |
| `suburana` | the Subura, the Carinae and the Caelian | later |
| `esquilina` | the Esquiline | later |
| `collina` | the Quirinal and the Viminal | later |
| `aventinus` | the Aventine, the Circus Maximus and the river port | later |
| `campus_martius` | the Campus Martius | later |
| `trans_tiberim` | across the Tiber, the Janiculum | later |

A new Rome book gets:
- an entry in `content/rome/works.json`, with its `age` and `rome_zone`;
- a room in `content/rome/rooms.json`, with `"world": "rome"`;
- a gateway position under `gates` in `city.json`.
