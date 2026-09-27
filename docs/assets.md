# Asset catalogue

Every asset in the game is made in this repository, in code: nothing is downloaded or drawn by
hand except the Quaternius characters (`assets/quaternius`, CC0) and the Natural Earth coastlines
the map builder reads. Check this list before making something new, so nothing is made twice.

How to see and remake them:
- 3D pieces: `godot --path . --script res://tools/gallery.gd -- --out=<folder> [name ...]` renders
  each piece on its own (`--list` names them). On a server without a screen: `xvfb-run -a godot ...`.
- Music and sounds: `python tools/make_music.py [name ...]` (no names: everything; same output
  every time).
- Maps: `python tools/build_map.py [map-id ...]` (needs `tools/data/ne_50m_land.geojson`).
- Tests: `tests/test_assets.gd` builds every gallery piece and checks the music, sounds and maps.

## 3D pieces

### Already in use (scripts/hall/kit.gd, doors.gd, places.gd)
Land, sea and sky (moods golden, dusk, morning, ashen; stars; sea; clifftop plateau; mountain),
column, fallen column, temple ruin, colossus legs, fallen head, far ruin, tower site, olive,
cypress, plane tree, rock, stele, Greek gateway, bust, seated teacher, walker, scribe, bed,
hearth, scroll shelf, amphora, lamp stand, table with bread and wine, rug, wall lyre, potted
plant, bench, desk, brazier, framed board, stoa, stream, footbridge, the Acropolis from afar,
Macedonian soldier and squad, swallows, the toad, moths, fireflies, ash, shades, the Nexus
pieces (void, idea stars, nebulae, currents, shards, debris, rails, spans, far wrecks, the Tower,
stone hand, mourner), and one door per world (Greek, Roman, Israelite, Byzantine, Gothic, Moorish,
torii, Palladian, modern, surreal).

### New for the Greek places still to come (scripts/hall/kit_greek.gd)
| Piece | For |
|---|---|
| `beast` horse, ox, sheep, goat, dog, wolf (any stuff, any size; four legs that swing) | everywhere; statues; the horse of Troy |
| `plough_team`, `field`, `threshing_floor`, `hives` | Hesiod, Works and Days |
| `hoplite` Sparta / Athens (and undead), `phalanx` | Herodotus (Thermopylae), Thucydides |
| `immortal` (and undead) | Herodotus (Thermopylae, Salamis) |
| `achaean` (boar's-tusk helmet, figure-eight shield; and undead) | Homer |
| `ship` trireme (three banks, ram, sail) / pentekonter (Homer's black ship, open, benches) | Homer, Thucydides, Salamis |
| `troy_wall` with the Scaean Gate, `wooden_horse` | Homer |
| `lion_gate` (Mycenae) | Aeschylus, Oresteia; Homer |
| `theatre` (orchestra, altar, seats, aisles, skene; whole or ruined), `mask` tragic / comic, `actor`, `crane` (mechane, with Socrates' basket) | Aeschylus, Sophocles, Euripides, Aristophanes |
| `tripod` (with vapour), `omphalos` | Delphi: Herodotus (Croesus), Sophocles (Oedipus) |
| `pharos`, `sand_tray` (Elements I.1 drawn in the sand, dividers, straightedge) | Euclid |
| `cave` (prisoners, wall, bearers, fire, shadows, the way up to daylight), `herm` | Plato |
| `loom` (warp-weighted, Penelope's) | Homer, Odyssey |
| `kline`, `krater`, `kylix`, `barbitos` | Sappho; Plato, Symposium |
| `altar` Greek / Roman (lit or cold), `bema` | everywhere; Thucydides (the Pnyx) |

### New for Rome (scripts/hall/kit_rome.gd; Rome renders sharper: Kit.detail 2)
| Piece | For |
|---|---|
| `stone_pine` (alive or dead) | every Roman place |
| `column` (Corinthian), `temple` (whole or three columns standing) | the Forum |
| `triumphal_arch` with its bronze quadriga | the Forum, the Sacred Way |
| `aqueduct` (one or two tiers) | the Campagna |
| `rostra` | Cicero |
| `via`, `milestone`, `tomb` round (Caecilia Metella) / altar | the Appian Way |
| `legionary` (and undead), `century` | Caesar, Tacitus, Virgil |
| `togatus` (senator's stripe, bordered toga, a book roll; a walker) | every Roman teacher |
| `aquila`, `fasces`, `sella` | the Senate, magistrates |
| `atrium` (compluvium, impluvium, tablinum), `triclinium`, `lararium`, `fountain`, `pergola`, `insula` | the house and the street: Cicero, Horace, Seneca, Petronius |
| `she_wolf`, `equestrian` (Marcus Aurelius) | Livy; Marcus Aurelius |
| `capsa` (book rolls, wax tablets, stylus, inkpot, reed pen) | every Roman study |
| `colosseum`, `pantheon`, `far_city` | the city seen from a hill |
| `gateway` (Rome's own, same contract as the Greek one) | Rome's hub |

### New materials (scripts/hall/textures.gd)
Rome: travertine, tufa, brick, reticulatum, basalt paving, mosaic, fresco (Pompeian red), porphyry,
giallo antico, stone pine, toga wool, iron, rust, scutum (and faded). Greece: hoplon Sparta
(lambda) / Athens (owl) / dead, Persian rosette cloth, wicker, black-figure pottery, papyrus,
sand, grass, ploughed furrows, cave rock, cast shadow.

## Music (assets/music, from tools/make_music.py)
Every place track is 48 s, in layers that loop in step, with a ghost (the faint echo heard while
the place is lost). Zones are listed in `scripts/pixel/music.gd`.

| Zone | Mode and instruments | Layers |
|---|---|---|
| nexus | C minor prelude: glass chimes, plucked bass, pad, choir | drone, bass, pad, arp, voices, ghost |
| shore | D minor drone and chords | shore (one file) |
| sicily (Porphyry) | A Dorian lyre | drone, lyre, low, ghost |
| athens (the Lyceum) | E Phrygian pan pipes, walking bass, soldiers' drum | drone, walk, pipes, drum, ghost |
| **rome** | D Mixolydian: cornu pedal, hydraulis (water organ), tibia, legion drum and horn calls | drone, organ, tibia, march, ghost |
| **troy** (Homer) | D Hypophrygian: phorminx on the dactylic hexameter, the bard's hum, war drum | drone, phorminx, voice, drum, ghost |
| **theatre** (tragedy) | Greek Mixolydian (the mourning mode): aulos and its drone pipe, a men's chorus in strophe and antistrophe, heart drum | drone, aulos, chorus, drum, ghost |
| **lesbos** (Sappho) | Aeolian: barbitos on the Sapphic stanza, a woman's voice | drone, barbitos, voice, low, ghost |
| **alexandria** (Euclid) | Pythagorean tuning on F: the tetraktys on a kithara, the monochord's consonances | drone, kithara, monochord, low, ghost |
| **academy** (Plato) | the enharmonic genus (quarter tones): a pipe, the eight Sirens of Er, the three Fates | drone, pipe, spheres, voices, ghost |

Sounds already there: wind, waves, fire, fountain, cicadas, birds, stream, void, bell, croak.
**New sounds:** crowd (forum, agora), arena (the Colosseum from outside), rain, oars (a trireme
under way), loom, hooves (on paving), flock (sheep and goat bells), crickets (night), drip (the
cave), gulls (a harbour), and two one-shots: owl (Athena's little owl) and cornu (the legion's
horn call).

## Maps (assets/maps and content/maps, from tools/build_map.py)
Already there: 270 AD (Porphyry), 335 BC (Aristotle).
**New:** about 1200 BC (Troy: Achaeans, Hittites, Egypt, Assyria, Babylonia), 480 BC (Xerxes'
invasion: Thermopylae, Salamis), 431 BC (the Peloponnesian War: the Athenian empire, Sparta's
league, Melos, Mytilene), 300 BC (Euclid's Alexandria: the kingdoms after Alexander), 44 BC
(Caesar's death: the Republic, Cleopatra's Egypt, Parthia), 117 AD (Trajan: the empire at its
widest; Epictetus, Plutarch), 170 AD (Marcus Aurelius on the Danube). Borders are approximate.

## Round 2: every piece lost or whole, and ready-made areas (scripts/hall/kit_greek_areas.gd)
Every piece above now builds lost to the world as well as whole (flags `alive`, `whole`, `lit`,
`flowing`, `undead`, defaulting to whole); the gallery renders each both ways (`name`, `name_lost`).
An area set piece is one book's ground, built as far as its place is restored:
`Areas.<name>(parent, at, yaw, back)` returns the root, its people, lights, swaying trees, and the
spots a place needs (teacher, book, seat, facts, lesson stones).

| Module | Work | Areas | New props |
|---|---|---|---|
| e1 | Rhetorica ad Herennium | `law_court`, `memory_house` (twenty loci in order, a golden hand at every fifth) | `Rome.tribunal`, `Rome.subsellia`, `Rome.memory_image` (poison, bloodied, crowned, smeared, golden hand), `Greek.clepsydra` |
| e1 | Euclid | `museum_court`, `prop_one` (Elements I.1 at walking size), `prop_forty_seven` (9 + 16 = 25 tiles) | `Greek.armarium`, `Greek.date_palm`, `Greek.construction`, `Greek.tiled_squares`, `Greek.prop_one_drawing` |
| e2 | Homer (played as the scene's hero) | `ships`, `scaean_gate`, `achilles_hut`, `forge`, `walls` (the circuit round Troy), `ithaca_hall`, `cyclops_cave` and `underworld` (the horror zones: dark, mist, the dead crowding the trench), `sirens`; each returns its `beats` and whose eyes they are seen through | `People.hero_arms` (Achilles, Hector, Priam, Telemachus, Odysseus, Odysseus bound), `People.figure` (Agamemnon, Athena, Thetis, Briseis, Phoenix, Ajax, Odysseus, Hector, Andromache, Priam kneeling, Hermes, Penelope, Eurycleia, Telemachus, suitors, Teiresias, Anticleia, Elpenor, Achilles' shade), `People.cyclops`, `People.siren`, `Props.achaean_hut`, `Props.chariot`, `Props.shield_of_achilles` (walkable), `Props.forge`, `Props.bow_and_axes`, `Props.olive_bed`, `Props.blood_trench`, `Props.sirens_rock`, `Props.bier`, `Props.ground_fog` (material `mist`) |
| e2 | Hesiod | `helicon` (the Muses round the Horse's Spring, the gap of Chaos, Kronos), `farm` (Works and Days) | `People.figure` (the Muses, Pandora, Kronos), `Props.pithos`, `Props.prometheus_rock`, `Props.hippocrene`, `Props.ages_frieze` |
| e2 | Sappho | `garden` (the orchard, Aphrodite's shrine, the sparrow chariot, the two facing seats, the fleet far out) | `People.figure` (Aphrodite), `Props.apple_tree`, `Props.shrine`, `Props.sparrow_chariot` |

People are in `scripts/hall/kit_greek_people.gd`, the props from e2 on in `scripts/hall/kit_greek_props.gd`.
The gallery can look from a chosen spot: `--eye=x,y,z --look=x,y,z` (for inside caves and halls).
