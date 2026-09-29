# Rome: notes on the city's thematic effect and on navigating it

Status: notes of 2026-09-29, all of them built the same day, in the order of section 4. Where each
went: the ten sites and the Forum's furniture and the heroic structures in `tools/make_rome_sites.py`
(→ `city.json` `states`, read by `rome_map.state`/`staged`, shown by `kit_urbs.build`'s variants);
the temple styles in `kit_rome.temple`; the house kit per age, the farmland, the view corridors, the
hill vegetation, the corner names, the compita and the road tombs in `rome_map.gd`; the streets'
paving, epitaphs, signs and shrines in `tools/make_rome_streets.py` (→ `streets.json`); the live
map's route line and the way home in `urbs_plan_panel.gd`; the first turn's glow, the street name
in the corner, the gates as thresholds, the rides and the toad's way home in `hall.gd`; the sound
beds in `urbs_town.gd`; the light per age in `urbs_life.gd` and `places_rome.gd`. The reference is
`docs/rome-city.md` (the fabric, the light, the sound) and `docs/rome-activities.md` (the plan, the
rides); the flock driven down the Vicus Tuscus and the mule cart on the Via Lata in
`urbs_town._herds`. Nothing in these notes is left unbuilt.

They follow the audit of 2026-09-29 (86 structures, the seven-age overhead captures in `docs/dev/`,
the plot in `docs/rome-plot.png`) and the walks taken for the screenshots. The two questions are
taken separately: does the city *feel* like the theme (the age of heroes, the descent, the emptied
city), and can the player find their way in it?

## 1. What the city does well already

- The ground is right: the hills are where they are, the streets keep to the valleys and the
  ridges, the Argiletum climbs into the Subura, the Forum sits in its bowl.
- The years work: 21 structures in 280 BC, 68 in AD 150, 20 standing and 59 ruins in 552. The
  churches come as the temples go. From above the seven ages already read as one city aging.
- The people carry the theme: the jobs, the ages' spirits, the regulars' families, the rites
  played seven times. The words are ahead of the pictures.
- The big monuments are legible at a glance (the Circus's slab, the amphitheatre's ring, the baths'
  blue pools). The Forum is dense enough to feel like a centre.

## 2. The thematic effect: what is weak and what would fix it

### 2.1 The ages don't look different enough from street level
From above they do; in the street, 280 BC and AD 150 are the same brick-and-plaster houses with a
different palette. The theme is a descent from tufa and timber to marble and then to rubble, and the
walls should say so.

- **A house kit per age**, not a palette per age. 280 and 201 BC: low houses of tufa blocks and
  timber, one or two storeys, tiled or thatched, wide eaves, no shops on the street (the blank wall,
  the door). 50 BC: the first tall insulae, brick and rubble, shops under the flats, balconies,
  the Subura's five storeys. AD 150: brick-faced concrete, arcaded ground floors, six storeys,
  marble in the good streets, the imperial porticoes. 384: the same buildings repaired badly,
  plaster over brick, windows bricked up, the tall blocks half-empty. 455: burnt roofs, doors off,
  scaffolding no one finishes. 552: roofless walls, houses inside ruins, a hut in a basilica.
  `rome_map._house` already branches on `republic` and `fallen`; it wants four or five branches, not
  two, and the PLASTER palette becomes the least of the differences.
- **Temples with faces.** All fifteen temples of 280 BC are one model at different sizes. Three
  models would carry the whole descent: the Etruscan temple (high podium, deep wooden porch with
  wide-spaced columns, painted terracotta roof with acroteria) for the age of heroes; the Greek
  marble temple (peripteral, close columns, pediment sculpture) from 201 BC on; the Corinthian
  imperial temple on a tall podium (Mars Ultor, Venus and Rome) under the Empire. Then the
  temples stop looking like copies, and the Greek marble arriving *is* the theme of the Republic's
  turn. `kit_rome.temple` and `kit_urbs.build("temple")` take a `size`; they want a `style` too, set
  by year in `city.json` (Etruscan before 200 BC unless rebuilt).
- **The Forum's furniture.** The Forum of any age was crowded with things that are not buildings:
  the Rostra's beaks, the statues on columns (the Columna Rostrata of Duilius, 260 BC), the
  honorific statues that multiplied until the censors cleared them (158 BC), the Ficus Ruminalis, the
  Lacus Curtius, the Black Stone, the Milliarium Aureum (20 BC), the Umbilicus. A dozen small props
  do more for the feel of a Forum than another basilica.
- **What the decline takes away, seen.** The theme is loss; loss must be visible in the same place
  across ages. Choose ten sites and script their seven states explicitly, not by the general
  ruin rule: the Rostra (beaks, then Caesar's rebuilding, then a pulpit, then a stump), the Temple of
  Saturn (treasury, then re-columned with odd columns, then a lime kiln beside it), the Comitium
  (the assembly, then paved over, then a church), the Circus (races, then empty stands, then grass),
  the Cloaca's mouth (running, then choked), your own house (already done). Each state gets its own
  note. This is where the notes budget should go before it goes to breadth.

### 2.2 Nothing at street level teaches
The monuments teach when you press F. The streets between them teach nothing, and most of a walk is
streets.

- **Crossroads shrines (compita)**, one at every second or third junction, with their painted Lares
  and a garland; a pinch of meal there is an offering (already a scene). Christian shrines replace
  them in 384; both stand broken in 455.
- **Tombs along the roads outside every gate**, with their inscriptions readable (the
  `inscription_` scene already exists): "stranger, stop and read". The Via Appia inside the plot
  has none; it should have a dozen from the Capene Gate south, the Scipios' first.
- **Election notices and graffiti** on the walls in 50 BC and AD 150 (the `graffiti_republic`
  material exists; it wants placing on shop fronts along the main streets, and reading).
- **Shop signs**: the Romans painted what a shop sold; a wine jar, a loaf, a knife. The shops
  already have keepers; the signs would let the player read a street.
- **Sound by district.** `urbs_town._sounds` plays a trade's sound at its door. Add district
  beds: the Forum's crowd, the Subura's hammering and shouting, the Palatine's quiet and birds,
  the river port's gulls and ropes, the Campus's wind. The music zones are per age; the sound beds
  should be per region.

### 2.3 The age of heroes is under-furnished
The theme rests on 280 BC being whole, simple and proud, and it is the age with the least in it.
- The twenty early structures listed in the assessment of 2026-09-29 (Comitium, Carcer, the
  Cloaca's mouth, Lacus Curtius, Ara Maxima, Lupercal, the Hut of Romulus, the Tarpeian Rock, the
  Columna Rostrata, the Tomb of the Scipios, Salus, Jupiter Victor, Venus Obsequens, Tellus, Juno
  Lucina, Mars outside the Capene Gate, Consus, Honos and Virtus, the Servian wall's towers, the
  Porticus Aemilia for 201).
- **Farmland inside the walls.** In 280 BC the Esquiline, the Aventine's back and the Caelian were
  gardens and fields with houses among them. The block builder fills every cell; for the heroic and
  early ages it should leave two-thirds of the outer hills as vegetable plots, vineyards and pasture
  with a farmhouse (this also makes those ages *feel* smaller without shrinking the map).
- **Livestock and carts.** Oxen, sheep driven to the Forum Boarium, mule carts on the Via Lata.
  The town system has dogs, pigeons and an ox for the sacrifice; a herd and a cart are the same
  code.

### 2.4 Light and air
- **The sun.** The descent could be in the light: the heroic age in a clear morning, the Republic at
  noon, the Empire in a golden afternoon, 384 in haze, 455 under smoke, 552 at dusk. The moods exist
  (`ages[].mood`); the tuning is timid. Make 455's smoke visible (plumes from the burnt quarters,
  `_plume` already exists) and 552's dusk long.
- **Emptiness must be felt, not counted.** In 552 the streets are empty of people but full of
  houses. Take the houses away: the block builder in `fall` should leave open ground with a few
  ruins, not a ruined block in every cell, so the city looks like the 30,000-person village it was.

## 3. Navigation: what is hard and what would fix it

### 3.1 Everything looks the same at eye level
The player's view is a street of similar houses; the hills that would orient them are hidden by the
houses. The Romans navigated by monuments, gates, and the hills; the player must be able to.

- **Landmarks visible over the roofs.** The Capitol's temple, the Palatine's palace, the
  Colosseum, the aqueducts, the columns. Render them tall enough and light enough to be seen down
  a street (the temples' roofs are barely higher than the insulae). A gilded roof on Jupiter's
  temple and a glint on the obelisks would give the city a compass.
- **View corridors.** The big streets should be straight enough and wide enough that at their ends
  something stands: the Sacred Way ends at the Capitol; the Argiletum at the Senate House; the Via
  Lata at the Capitol's flank; the Vicus Tuscus at the Circus. Keep the block builder off the last
  forty metres of a street's line of sight to a monument (`clear` points along the axis, not only
  at the monument).
- **The hills as orientation.** Slopes are now real. Add the cue the eye needs: the ground's
  colour and vegetation should change with height (drier and lighter uphill is already tinted;
  add the stone pines on the ridges, cypresses at the Palatine, the fig and plane in the valleys,
  bare ground on the Capitol's rock face). From any street, "up is the Palatine" should be visible.

### 3.2 Streets need identities
- **Width, paving and name.** The main streets are 6-7 m basalt; the rest 4 m. Give the Sacred Way
  travertine, the Argiletum basalt with a gutter, the alleys packed earth. Put the Roman street
  names on the walls at junctions (the Romans didn't; the player needs it; a small painted name on
  the corner shop reads as period enough).
- **Fountains and shrines as junction markers.** Every fountain (`fab["fountains"]`) and compitum
  becomes a named node ("the fountain of the Four Scales"), used in directions and on the map.
- **Gates as thresholds.** Passing a gate should be an event: the wall's shadow, the tombs
  beginning, the region's name changing, a guard. Now the gates are points in the data.

### 3.3 The tools already built should be joined up
- **The live map (M)** shows you and the streets. Add: the destination of the current errand or
  quest as a ring (it has one for the errand; add the quest's `go` step), the route drawn along the
  streets from `urbs_plan.route` (a faint line, not a marker), and the compass direction to home.
- **Directions on the ground.** When a citizen gives you the way, the first turn could be shown as
  a brief glow on the street corner (the beat runner's `_beat_mark` does this for beats).
- **"Ask anyone."** Everyone should answer "where is X?" with `Plan.directions` from where *they*
  stand (already true for the "around" topic with a named place; extend to typed questions through
  Claude by passing the directions into the persona as a fact).
- **Region names in the corner** are good; add the street name under them when you are on a
  named street (`Plan.whereabouts` knows it).

### 3.4 Scale and pace
- The core is about 900 m across; a walk from the house to the Forum is 440 paces, two minutes at
  the walking speed. That is right for a city you learn on foot. The Campus and the Aventine are a
  further two minutes each way; the Lateran four. Keep the far places far, and give the player the
  litter, the cart and the boat as paid rides for the long ones (the boat exists in Greece; the
  litter bearers exist as a job).
- Fast return: the toad's offer of the Nexus exists; a "go home" from the toad in Rome (a walk of
  a few minutes done in a fade, at the cost of an hour of the day) would save the tedium without
  a teleport network.

## 4. Order of work, if all of it were done

1. The ten scripted sites through seven states, with their notes (theme, content only).
2. The three temple models, and the age's house kit (theme, the biggest visual return).
3. Landmarks over the roofs, view corridors, hill vegetation (navigation, one pass through the
   block builder and the kit).
4. Compita, road tombs, Forum furniture, shop signs, graffiti (street-level teaching).
5. The heroic age's twenty structures and its farmland (theme).
6. Street identities and junction names; the live map's route line (navigation).
7. Sound beds by region; the light per age (atmosphere).
8. Rides for the long walks.
