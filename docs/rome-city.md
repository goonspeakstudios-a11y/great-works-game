# Rome: the city is the world's hub

Decided with BB1 (2026-09-28):

- The Rome world's hub is the whole city of ancient Rome, laid out on a map of the ancient city and
  shrunk. Greece has its Shore of gateways; Rome has the city, walked street by street, with its
  regions, its people and its monuments. Rome's books stand in its zones behind Roman gateways.
- The city lives and dies. It goes through four ages, from the Republic's rise and glory to the
  empty city of the 6th century.
- There is no grass anywhere. The ground is the city's brick paving and, in the emptied city,
  rubble.
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
| The hub: ages, people, talk, the navel, the gateways | `scripts/hall/places_rome.gd` (`urbs`) |

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

## The four ages
| Age | Year | Light | People | The city |
|---|---|---|---|---|
| The Republic | about 50 BC | morning | 190 | Temples of Jupiter, Saturn, Castor, Vesta, Concord, Juno Moneta, Magna Mater, Ceres, Diana, Mars in the Circus, Venus Victrix on Pompey's new theatre; the Tabularium; Basilicas Aemilia and Sempronia; the burned Senate House being rebuilt; the Servian wall whole; low houses of tufa and plaster; the Campus Martius still open |
| The Empire | about AD 150 | noon | 240 | The imperial fora with Venus Genetrix and Mars Ultor, Trajan's forum, column and markets; the Colosseum, the Colossus and the Meta Sudans; the Pantheon; Venus and Rome; baths of Agrippa, Titus and Trajan; the palace on the Palatine; the Claudian aqueduct; brick insulae of up to six storeys with balconies |
| The Late Empire | about AD 330 | golden afternoon | 190 | Baths of Caracalla and Diocletian; the Arches of Septimius Severus and Constantine; the Basilica of Maxentius; Aurelian's wall and gates; the Lateran and St Peter's; clergy in the streets |
| The Fall | AD 552 | nightfall | 36 | After the Gothic War: most monuments in ruin, the aqueducts cut and dry, most blocks broken walls without roofs, the ground rubble; the few people live in the bend of the Tiber (the abitato), round the churches and the Lateran |

- A monument stands from its year of building (`from`), as a ruin from `ruin`, and is gone from
  `gone`.
- Moods: `noon` and `twilight` are new in `kit.gd`.
- Music: the Rome zone's layers thin out with the ages. The emptied city has only the ghost layer
  and the wind.

**Passing the ages:** the Navel of the City (Umbilicus Urbis), by the Rostra, lets the years pass
into the next age. From the Fall it goes back to the Republic.

- The city is rebuilt round where you stand.
- The corner shows the year and the region.
- For now every age is open to walk. When more Roman books exist, each book's `age` in
  `content/rome/works.json` can gate how far the navel goes.
- For screenshots: `--view=place --work=urbs --age=N [--fly]`.

## The city's fabric
- **Ground:**
  - One height-field sheet of herringbone brick (`cobble`), or broken brick and dust (`rubble`)
    in the Fall.
  - The seven hills rise in gentle domes you can walk up. The Tiber lies lower between its banks.
  - Beyond the walls is the dusty plain.
- **River:**
  - The Tiber and its island. An unseen wall runs along the banks.
  - The bridges stand by date: Sublician, Aemilian, Fabrician, Cestian, Agrippa's, Nero's (broken
    in the Fall) and Hadrian's.
- **Streets:** sixteen main streets in basalt paving, among them the Sacred Way, the Vicus Tuscus
  and the Vicus Iugarius, the Argiletum and the Clivus Suburanus, the Vicus Patricius, the Alta
  Semita, the Via Lata, the Appia, the Labicana and the Ostiensis.
- **Blocks:**
  - Thousands of blocks of houses and flats on a grid that bends and twists quarter by quarter,
    so streets wander and narrow into alleys. Some blocks run long over two cells.
  - Shops open on the ground floors, with awnings, amphorae and crates. Balconies from the
    Empire on. The houses of the rich on the hills. Little squares with street fountains.
  - The blocks are drawn with a few MultiMeshes, and each is solid.
- **Walls:**
  - The Servian wall is whole in the Republic and stands only in stretches after.
  - From AD 275, Aurelian's brick wall with towers and gates runs round the walkable city.
  - Before AD 275, boundary stones mark the edge.
- **Aqueducts:** the Marcia, the Claudia and Nero's arches of the Claudia, broken in the Fall.

## The people
- Everyone is solid, and most will talk: walk up and press F to listen. Each has a line of their
  own age.
- The people:
  - Shopkeepers at stalls laid with wares.
  - Patrols walking the streets in step: the praetor's lictors with the fasces, then the watch
    (vigiles), then the Urban Prefect's soldiers, then the Emperor's garrison.
  - Senators with their clients at their heels.
  - Plebs and porters.
  - Strangers: Greeks, Gauls, Syrians, Egyptians, the Jews of the city, Germans.
  - Priests and monks in the later ages.
- Knots of people argue by the monuments and the fountains. "Listen to them talking" gives the
  whole exchange.
- Crowds gather where the city did in each age: the Forum, the markets, the Subura, the Colosseum,
  the Pantheon. In the Fall they gather in the bend of the river and at the churches.
- People far down the street are not drawn.

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
