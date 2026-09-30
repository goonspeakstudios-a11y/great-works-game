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
| The feasibility map every placement is tested against and painted onto | `scripts/hall/urbs_occupancy.gd` |
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
- **Houses: a kit per age** (`rome_map._house`, `_old_house`, `_plot`, `_ruin`; the notes of
  `docs/rome-city-notes.md` 2.1, built 2026-09-29):
  - A bent, twisting grid of cells, each split into two or three houses of their own height,
    kind and colour. Between the cells run lanes of packed earth along the bent grid, every third
    row and every third column (`_lanes`, `LANE`), broken at the named streets, the squares, the
    monuments, the river and the wall; so the city is blocks of houses between streets. A house
    near a street (named or lane) is lined up along it, its front a step from the kerb, one after
    another on each side (`_nearest_road`, `lined`); no house is built into another (`placed`).
  - 280 and 201 BC: low houses of tufa blocks, or plaster over a timber frame with the timbers
    showing, one or two storeys under wide eaves of tiles or thatch, a blank wall to the street with
    a door in it, no shops. Two-thirds of the outer hills inside the wall (the Esquiline, the
    Caelian, the Aventine's back) are vegetable plots in rows, vineyards on their posts and fenced
    pasture with sheep, with a farmhouse and its fig among them.
  - 50 BC: the first tall insulae of two to four storeys over shops.
  - AD 150: brick-faced blocks of three to six storeys, arcaded shops, balconies, roof gardens.
    Election notices and scratched words on the shop fronts (50 BC and AD 150, the chi-rho later).
  - 384: the same blocks patched with plaster and brick, a third of the windows bricked up, shops
    shut up for good, fewer awnings.
  - 455: three in ten houses burnt to their charred beams, the doors off, scaffolding no one
    finishes; smoke still going up from the burnt quarters, seen across the city.
  - 552: open ground with a few ruins (two in five cells built by the river, one in seven beyond),
    huts of wood and thatch inside the ruined walls where people still live.
  - Every shop has a painted sign hung over its door: a wine jar, a loaf, a knife, a shoe, a bolt of
    cloth, a pot, a fish.
  - **The fronts** (the house set, `textures_houses.gd`; `_bays`, `_window`, `_washing`): the
    ground storey is bays, each a shop (its arched bay, a counter of stone before it with pots on
    it, the shutters put up at dusk and taken down at dawn by `urbs_life.gd`), a door (planks and
    iron bands, some painted red or green, a bronze lamp beside it) or blank wall with a barred
    window; the sides have fewer. Every window has its wooden frame and sill, the pane behind it
    lit at night; on half the shutters stand open, on a third a pot of flowers sits on the sill. A
    third of the tall houses on a street hang their washing on a line across it, in the tunics'
    colours; vines climb one wall in seven; a band of damp darkens every wall's foot; the ridges
    carry a line of cover tiles and, here and there, pigeons. The old houses are tufa or timber and
    plaster with a bench by the door, a lean-to and a woodpile; the houses of the rich are drafted
    stucco over a painted dado, with a porch. Cats sit by the house fronts (`urbs_town._cats`).
  - The houses of the rich stand round courtyard gardens with a lawn, two trees and a pool.
  - **Nothing is built into anything: the feasibility map** (`scripts/hall/urbs_occupancy.gd`,
    `rome_map._occ`): before a house, lane, tree, stall or basin is set down, the whole city is
    a map of what stands where, one byte a half-metre cell (an `Image` of the ground, the same
    2000 by 2000 cells whatever age), each cell one kind: free, water, bank, wall, monument, open
    ground, grove, road, lane, house, furniture, tree, or void off the walkable ground. Everything
    is painted onto it in the order it is laid, soft kinds first and hard kinds after, so the
    hard always show through: the walkable outline, then the open grounds, groves, ponds and
    their banks, the Forum's paving and the river's bank; then the river and the wall; the
    bridges and every named street with its kerb; the aqueducts; every monument's footprint
    (read from the built meshes' bounds, grown a pace and a half); the view corridors from each
    street's end to the monument it runs at, and the streets again over them; and the monuments
    last. The blocks then ask the map, not each other: a lane is laid only along a stretch
    whose whole band is free (`band_free`, so no lane runs through a monument, into the water or
    across the paving; it opens into the named street at its end and is painted a lane), a
    house only where its box is free (`box_free`, a get_region of the rows it covers and a
    count of the bytes, so 3200 houses test in a few hundred milliseconds; an exact
    separating-axis check against the boxes in its 16 m bin confirms the corners thinner than a
    cell), a fountain's square, a stall, a shrine, a basin, a tomb, a spring or a pool only on a
    free disc, each painted furniture as soon as it stands, and a tree only where a pace round
    its trunk is free ground, bank, open or grove (a tuft half a pace, reeds in the water too).
    The streets and lanes are lined first, each walked whole by arc length, house against house
    along both sides (a house narrowed to fit before a lane's mouth, or made shallower, its
    front always a step from the kerb; half have a neighbour within a pace and a half); now
    and then the line leaves a little square with a fountain; a stall stands on the pavement
    before the shops here and there, oftener on the named streets than in the lanes, and on
    the kerb where no house fits (never two within thirty paces there). The blocks between
    take what room is left, shrinking to fit or not built. Basins stand on the pavement against
    a house front (slid along the street to the nearest one), shrines on a corner pavement
    clear of every lane. `tools/audit_rome.gd -- --age=N [--map=path]` counts what is built
    into what (houses into houses, over a street, into a monument; lanes through a monument,
    in the water, across the paving; plants in a house or a street; basins, shrines, tombs and
    fountains in a house) and dumps the map; every count is zero in all four ages, and the
    whole city builds in five to seven seconds. `python3 tools/dev_maps.py feasibility 3 0`
    colours the map a kind a colour with a key (`docs/dev/feasibility_empire.png`,
    `feasibility_heroic.png`).
    The monuments of the Forum's cluster (city.json) were spaced and sized so no two solid
    buildings stand in one another: the Basilica Aemilia east of the Senate House, Janus's
    shrine at the Argiletum's mouth, the Carcer and Vespasian's temple at the Capitol's foot,
    Minerva's temple in Nerva's forum, the Meta Sudans and the gladiators' school clear of the
    Colosseum, the Basilica Julia clear of Castor's temple.
  - **Water** (`Rome.fountain`, `Rome.lacus`, `Rome.spring`, `Rome.jet`, `rome_map._street_basins`,
    `_waters`, `content/rome/green.json` "waters"): the water moves (a ripple shader on every sheet
    of it, the Tiber too) and falls (drops thrown from every running spout). A street basin, a
    trough of travertine with a bronze lion's head that never stops, stands every forty-five paces
    along the named streets you can walk, on the pavement against the house fronts, its overflow
    running over the kerb into the gutter that runs along every paved street from the first
    aqueducts (a few basins in 280 BC, from the Appia alone; all dry once the aqueducts are cut,
    the gutters gone). The square fountains and their planes stay. Besides the Tiber, the city's
    other waters stand in their years: the Goat Marsh in the Campus and the Petronia brook from
    the Cati spring under the Quirinal to the river, until the Campus is built up; Agrippa's lake
    and the Euripus canal from 25 BC; the Naumachia of Augustus across the river for a century;
    the pool of the Camenae outside the Porta Capena always. Each is a sheet of water in a bank of
    earth with reeds round it (and through the marsh), a quay on the lake; no house or lane is
    built across them, the streams' banks left green. The pleasure gardens have pools with a jet
    in the middle, the sacred groves their springs in a round basin with a rill running off, the
    pastures a pond the sheep drink at. Near any of it you hear it: the splash of a fountain or a
    basin, the run of a stream or a pond's edge (`urbs_town._water`).
  - **The people** (the people set, `textures_people.gd`; `Kit.walker`): every citizen wears a
    woven tunic in his own dye with its folds, belt and embroidered hem, bare below the knee and
    the elbow, sandals with straps; a face with eyes, brows and a mouth on the head; hair in
    strands. The togati's wool falls to the ankle, the women's dresses too.
  - Warehouses line the river, and single-storey rows of shops line some streets.
  - Little squares hold fountains with a lamp. Within seventy metres of a landmark the flats are
    kept to three storeys, so the landmark shows over the roofs.
  - Each house's plaster colour is its own, drawn from the age's palette.
- **Temples in three styles** (`kit_rome.temple`, `kit_urbs.temple_style`): the Etruscan temple
  (a tufa podium, a deep porch of four widely spaced wooden Tuscan columns, stuccoed walls with a
  painted dado, a wide-eaved terracotta roof with terracotta gods along the ridge and a chariot at
  the peak) in 280 and 201 BC; the Greek marble temple (columns all round, sculpture in the
  pediment) from 50 BC; the Corinthian imperial temple for one built under the emperors. A site's
  scripted state can name its own (Jupiter's is imperial from Domitian on).
- **Ten sites through seven states** (`tools/make_rome_sites.py` → each monument's `states` in
  `city.json`, read by `RomeMap.state`/`staged` and shown by `kit_urbs.build`'s variants): the
  Rostra (the beaks of Antium, Caesar's marble platform with the emperors on columns, the beaks
  prised off, a stump with a pulpit); the Temple of Saturn (Etruscan, Greek, the porch re-columned
  with odd granite columns, a lime kiln beside it); the Comitium (the stepped hollow, paved over,
  cracked, grass); the Circus (timber stands, stone, marble, a stretch fallen, grass); the Cloaca's
  mouth (running, choked); the Senate House (the kings' tufa hall, burnt with Clodius's body and
  scaffolded, the Curia Julia); Jupiter's temple (Etruscan, Sulla's Greek marble, gilded roof,
  stripped by the Vandals, open to the sky); Vesta's (thatch, stone, marble, cold); the Colosseum
  (whole, cracked and propped, huts in its arches with beans in the arena); the Sublician bridge
  (its note in every age); and your house. Each state has its own note, read where it stands.
- **The Forum's furniture** (`make_rome_sites.py` NEW): the Lacus Curtius, the fig with the bronze
  wolf, Duilius's column with its beaks, the Golden Milestone, the honorific statues on columns.
- **The age of heroes' twenty structures** (same file): the Comitium, the Carcer, the Cloaca's
  mouth, the Lacus Curtius, the Ara Maxima, the Lupercal, the Hut of Romulus, the Tarpeian Rock,
  Duilius's column, the Tomb of the Scipios, Salus, Jupiter Victor, Venus Obsequens, Tellus, Juno
  Lucina, Mars outside the Capene Gate, the altar of Consus, Honos and Virtus and the Porticus
  Aemilia, each with a note, placed by the map's own landmarks (`republican_rome.json`). The wall's
  towers are the ones `_servian_wall` already builds at every gate; each gate you can reach has its
  note beside them (`streets.json` "gates"). The wolf under the fig is `kit_rome.she_wolf`, the
  sheep and the mules are `kit_greek.beast`.
- **The streets** (`content/rome/streets.json`, `tools/make_rome_streets.py`):
  - Paving per street: the Sacred Way in travertine (under the emperors), the main roads in basalt,
    the alleys of the Subura and the hills in packed earth.
  - The streets' names painted in red on a plaster board on the corner shop a few paces along each
    street from every junction (`rome_map._corners`; the Romans did not, you need them).
  - A crossroads shrine (compitum) at every second junction: the painted Lares and the snake, an
    altar and a garland; a Christian niche with a cross in 384; broken in 455; a worn block in 552.
    Each can be looked at, and while offerings are made a pinch of meal can be left for the Lares.
  - Tombs along every road outside the Servian wall, every twenty-odd metres, alternating sides, an
    altar tomb or now and then a great drum, broken after 455; each one read (twelve epitaphs in the
    Roman formula, from the Scipios' to a Christian's).
  - View corridors: from each end of a street to the monument it runs at, nothing is built across
    the sight line (`CORRIDOR`).
  - A guard at every gate of the Servian wall you can reach; passing a gate is said in the corner.
- **Green** (the green set, `textures_green.gd`; `_trees`, `_grove_cell`, `content/rome/green.json`):
  every tree is a bark trunk and crossed quads of leaves. Stone pines on the ridges, cypresses on
  the Palatine and by the temples, the fig and the plane in the valleys, bare rock outcrops on the
  Capitol's face (`_hill_tree`); on the hills' open cells a clump of pines or cypresses, an olive
  and bushes, and a fig or a cypress in the yard behind half the hill houses; a pine or a cypress
  over one courtyard in five in the flats' blocks, so green stands up over the roofs; a plane
  over every street fountain; grass in tufts and flowers on all open ground you can walk; reeds
  and trees along the Tiber's banks; a cypress either side of the tombs along the roads. The
  groves of green.json stand in their years: the sacred groves (Vesta's, the Asylum, Juno Lucina's,
  Libitina's, the Fagutal, Strenia's, Furrina's, Stimula's) in every age; the woods on the Caelian
  (the hill of oaks), the Aventine, the Esquiline, the Quirinal's back and the Janiculum while the
  city is small; orchards of olives and figs on the Aventine and under the Esquiline; and from the
  last century BC the horti (Pompey's, Lucullus's, Sallust's, Maecenas's, Lamia's, Caesar's,
  Agrippa's, the Acilii's) with pines, cypresses, planes, box, flowers, lawns and a pergola now and
  then. On the street, a vine trained over one shop front in five on poles, and a pot of box or
  flowers by two doors in five. The houses of the rich have a lawn, two trees, box and flowers in
  the peristyle. The emptied city grows over: grass and bushes over the open ground and the ruins.
- **Walls and aqueducts:**
  - The Servian wall stands in every age, three metres thick with a tower at each gate, the agger
    (the earth rampart) behind it on the east; lower under the emperors, when the city has spilled
    over it. No house or lane is built across it, and the way along it is kept open.
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
- **The light of each age** (`places_rome.gd` `GLOOM`, `FOG`, `EXPOSURE`, `HAZE`, `SMOKE`;
  `urbs_life.gd`): the age of heroes in clear air, the Republic and the Empire a little dustier,
  384 in a yellow haze, 455 under brown smoke with plumes over the burnt quarters, and 552 with a
  long evening: its sky is drawn for a stretched clock (`sky_hour`), the afternoon's last two and a
  half hours lasting six, and dawn coming late.

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
- **Sound beds by region** (`urbs_town.gd` `BEDS`, `bed_for`): under the trades' sounds at their
  doors, a bed for the part of the city you are in, crossfading as the corner's name changes: the
  Forum's crowd, the Subura's hammering, the Palatine's birds, the river port's gulls, the Campus's
  and the Capitol's wind, sheep on the Aventine, looms on the Esquiline; crickets at night; only wind
  in the emptied city and in the Forum after the sack.

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

## The ground

Since the city's fourth build the ground is a height map made from the real topography (`tools/make_rome_height.py`, see `docs/rome-activities.md`, "The ground"): the streets keep to the valleys and the ridges they always ran along, and are graded into the hills rather than draped over them.
