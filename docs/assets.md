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
| `beast` horse, ox, sheep, goat, dog, wolf, pig (any stuff, any size; four legs that swing) | everywhere; statues; the horse of Troy |
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

### The house set (scripts/hall/textures_houses.gd, `Textures.material("h_<name>")`)
The textures of Rome's houses, 64 pixels to a 4 m tile in the hall's pixel style, the pale ones
tinted per house (`rome_map.tinted`); shown together in `docs/dev/materials.png`. Walls, tiled
over the world: `h_plaster` (lime plaster, a crack, a chip), `h_plaster_worn` (patched, the brick
showing, grime under the sills), `h_brick` (each brick its own red, a yellow bonding course),
`h_tufa` (opus quadratum), `h_timber` (opus craticium: plaster panels in a timber frame),
`h_stucco` (drafted blocks of the good houses). Roofs: `h_roof`, `h_roof_moss`, `h_roof_broken`.
Fronts, one image to one quad: `h_shop` (the arched bay, shutters folded back, the counter and its
pots) and `h_shop_shut` (the shutters up, urbs_life.gd swaps them at dusk), `h_door` and its
painted `h_door_red`, `h_door_green`, `h_window` (frame and sill, clear in the middle for the
lit pane), `h_window_small` (barred), `h_shutter` (one leaf), `h_cloth` (washing, tinted the
tunics' colours), `h_vine`, `h_sign`. Storey-aligned things (the damp at the foot, the painted
dado) are geometry, since a world-tiled texture repeats up the wall.

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
| e3 | Aeschylus | `argos_palace` (the watchman on the roof, the beacon chain, the crimson carpet, the bath), `areopagus` (the Furies, the jury, Athena's casting pebble, the urns) | `People.figure` (Clytemnestra, Cassandra, the watchman, the Furies, Orestes), `Props.palace_front` (whole, ruined or shaken), `Props.beacon`, `Props.carpet`, `Props.bath`, `Props.voting_urns` |
| e3 | Sophocles | `thebes_gate` (the plague, the Sphinx on her column), `crossroads` (where three roads meet), `antigone_tomb` (the sealed door, Polynices unburied) | `People.figure` (Oedipus, Jocasta, Creon, Antigone), `People.sphinx`, `Props.rock_tomb`, `Props.bier` |
| e3 | Euripides | `cithaeron` (the maenads, Pentheus in the fir tree), `pentheus_palace` (shaken by the god, the fire on Semele's tomb) | `People.figure` (Dionysus, Pentheus, Agave, maenads with thyrsi and fawnskins), `Props.fir_tree`, `Props.palace_front` shaken |
| e3 | Aristophanes | `strepsiades_house` (the debts, the horse-mad son), `thinkery` (Socrates in the basket, the Clouds, the two Arguments caged, the fire at the end) | `People.figure` (Socrates, Strepsiades, Pheidippides, a Cloud), `Props.thinkery`, `Props.cages` |
| e3 | Herodotus | `sardis` (Croesus's treasury, Solon, Croesus on the pyre), `delphi` (the Pythia, the gold lion), `thermopylae` (the pass between cliff and sea, the Phocian wall, the Spartans and the Immortals) | `People.figure` (Croesus, Solon, the Pythia, Leonidas, Xerxes), `Props.pyre`, `Props.gold_offering`, `Props.phocian_wall` |
| e3 | Thucydides | `kerameikos` (the funeral oration: ten cypress coffins and the empty bier), `plague` (the sick carried into the street, the dead at the fountain, the pyres), `corcyra` (Hera's temple and its suppliants, a house burning), `melos` (the envoys, the walls, the siege line) | `People.figure` (Pericles, envoys, Melians), `Props.larnakes`, `Props.pyre`, `Props.siege_wall` |
| e4 | Pre-Socratics | `ephesus` (Heraclitus: the river with stepping stones, the ever-living fire, the Artemision, the boys at knucklebones, the way up and the way down), `elea` (Parmenides: the chariot and the Heliades, the gates of Night and Day, Justice with the keys, the goddess, the way of truth to the still sphere and the way of opinion into mist) | `People.figure` (Heraclitus, Parmenides, the goddess, Dike, the Heliades, children), `Props.artemision_column`, `Props.ever_fire`, `Props.great_gates` (doors that swing), `Props.sphere` |
| e4 | Plato | `court` (the Apology: jurors on their benches, the platform, water clock, urns, kleroterion), `cephalus_house` (Rep. I: the altar, the company, the harbour, the torch race on horseback), `gyges` (Rep. II: the chasm cut through a hill pasture, the bronze horse and the ring, the shepherds' meeting, the king's palace), `the_line` (Rep. VI: the sun and the divided line as a road cut 6 : 12 : 12 : 24), `cave` (Rep. VII: round 1's cave inside its hill, the way up, the sunlit world above), `er` (Rep. X: the meadow, the openings in earth and sky, the judges, the souls, the spindle, Necessity and the Fates, the lots and lives, the plain of Lethe, Er on his pyre), `symposium` (Agathon's dining room, Alcibiades at the door, Socrates in the neighbour's porch), `prison` (the Phaedo: the cell, the friends, the cup, Xanthippe sent home) | `People.figure` (Meletus, jurors, Cephalus, Polemarchus, Thrasymachus, Glaucon, Adeimantus, Gyges, Er, the three Fates, Necessity, Lachesis's prophet, Agathon, Aristophanes, Alcibiades, Eryximachus, Phaedrus, the flute girl, Phaedo, Crito, Xanthippe, the servant of the Eleven; poses `sit` and `recline`), `Props.kleroterion`, `Props.bronze_horse` (with the ring), `Props.spindle_of_necessity` (eight whorls that turn, with their Sirens), `Props.plain_of_lethe`, `Props.hemlock_cup`, `Props.prison_cell` |
| e4 | Aristotle (extras) | `politics` (the model in a colonnade, and the household, the village and the walled city at full size), `poetics` (round 1's theatre with actors, a chorus of fifteen and the crane) | `Props.household_to_city`, `People.figure` (Aristotle) |
| e4 | The Republic's mini-game | `city_in_speech(parent, at, yaw, stage, back)`: stage 0 the bare site, 1 the city of pigs, 2 the fevered city, 3 the army, 4 the guardians, 5 the just city, which turns into the soul (bronze belly, silver chest, gold head); returns `slots` (where the next stage goes), `buildings`, `orders` (producers, auxiliaries, guardians) and `soul` | `People.figure` (farmer, builder, weaver, cobbler, smith, herdsman, merchant, painter, cook, doctor, educator, ruler), `Greek.beast` pig |

People are in `scripts/hall/kit_greek_people.gd`, the props from e2 on in `scripts/hall/kit_greek_props.gd`,
the e1-e3 areas in `scripts/hall/kit_greek_areas.gd` and the philosophers' areas (e4) in
`scripts/hall/kit_greek_thinkers.gd`, which shares its helpers.
The gallery can look from a chosen spot: `--eye=x,y,z --look=x,y,z` (for inside caves and halls).

## In use (sprint 4)
The Rhetorica's place uses `Rome.atrium`, `lararium`, `capsa`, `pergola`, `fountain`, `stone_pine`,
`togatus`, `memory_image`, `far_city` and the areas `memory_house` and `law_court`; Euclid's uses
`museum_court`, `prop_one`, `prop_forty_seven` and `sand_tray`; Homer's uses `ships`, `achilles_hut`,
`forge`, `walls`, `cyclops_cave`, `underworld`, `ithaca_hall`, `sirens`, `Greek.ship` as the black
ship that sails between the islands, `People.figure` and `People.hero_arms` for the beats. The
places are built in `scripts/hall/places_greek.gd`; the beats are in `content/greece/beats.json`.

## In use (sprint 5)
Plato's Academy uses `Thinkers.city_in_speech` as the board of the city game (built to the saved
city's stage; after the just city `FALLS` takes its pieces away and `DECLINE` dims the soul's parts),
and round it `cephalus_house`, `gyges`, `the_line`, `cave` (with a way up added onto its hill), `er`,
`court`, `symposium` and `prison`; `Greek.herm`, `Kit.olive` for the grove; `People.figure` for
Socrates, Glaucon and Adeimantus at the council table; `People.hero_arms` with two new heroes,
Gyges (the ring) and Socrates (the cup). The music zone `academy` gains `crowd` (the city) and
`salpinx` (its guardians).
