# Rome: one city, opened a zone at a time

Decided with BB1 (2026-09-28): the Rome world is the whole city of ancient Rome, laid out on a
map of the ancient city and shrunk. It opens zone by zone as you go through the Rome books, and
the city grows as you do.

- **The map:** the layout follows W. R. Shepherd's *Plan of Republican Rome* (Historical Atlas,
  1911; about 40 BC; public domain). A copy is in `docs/shepherd-republican-rome.jpg`.
- **The data:** `content/rome/republican_rome.json`. Positions are in real metres east and north of
  the Roman Forum (41.8922 N, 12.4852 E). Ten landmarks come from Wikipedia's coordinates (the
  Forum, Palatine, Capitol, Circus Maximus, Aventine, Quirinal, Porta Capena, Lupercal and others);
  the rest are read off the plan and modern Rome, and are approximate.
- **The scale:** the game shrinks the city to 0.35 of its size, with north toward -Z. The Servian
  city becomes about 750 m across.
- **The code:** `scripts/hall/rome_map.gd` projects the map into the game, tests which zone a point
  is in, and builds the city round an open zone: the hills, the Tiber and its island, the Servian
  wall and its gates, the Circus Maximus, the Temple of Jupiter on the Capitol, the Theatre of
  Pompey, and roofs across the city. It also fences the open zone.

## Zones
| Zone | Covers | Opens with |
|---|---|---|
| `palatine_forum` | the Forum, and the Via Nova under the Palatine's north slope (Region IV, Palatina) | the Rhetorica ad Herennium (open now) |
| `capitolium` | the Capitol and the Arx | a Rome book, later |
| `palatina` | the Palatine and the Velia | later |
| `suburana` | the Subura, the Carinae and the Caelian (Region I) | later |
| `esquilina` | the Esquiline (Region II) | later |
| `collina` | the Quirinal and the Viminal (Region III) | later |
| `aventinus` | the Aventine, the Circus Maximus and the river port | later |
| `campus_martius` | the Campus Martius, outside the wall | later |
| `trans_tiberim` | across the Tiber, the Janiculum | later |

The four regions are those of Servius Tullius, marked in orange on Shepherd's plan. Which Rome book
opens which zone will be set when the Rome reading list is built.

## The Rhetorica's zone
The *Rhetorica ad Herennium* was written in Rome about 86-82 BC, by an unknown author for Gaius
Herennius. In those years the orators lived along the Via Nova under the Palatine's north slope, just
above the Forum: Crassus, whose bust stands in the atrium, had his house there, and Cicero later
bought one. The courts met in the open Forum below. So the book's place is the zone `palatine_forum`:

- You come down the Sacred Way over the Velia into the Forum.
- The Forum of about 85 BC stands round you: the Temple of Saturn under the Capitol, the Rostra,
  the Senate House over the round Comitium, the Basilicas Aemilia and Sempronia, the Temple of
  Castor, the round Temple of Vesta with its fire, and the Regia.
- The court sits in the open Forum, with the five plinths, the six stones of a speech and the three
  speakers.
- On the Via Nova, under the Palatine, are the Author's atrium house and the memory house.
- The zone is fenced by marble posts and a red cord. Everything beyond it is the rest of Rome, seen
  but not yet open.

For now the room stays in the Greek world, as gateway #4 on the Shore, because the reading list puts
it there. The room carries `"rome_zone": "palatine_forum"`. When the Rome world is built, this same
zone is its first open district, reached from the rest of the city, so the Rhetorica can be visited
again there.
