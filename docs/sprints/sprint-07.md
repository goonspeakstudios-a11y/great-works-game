# Sprint 7: Rome's first module

**Goal:** the Essentials' first Rome module, "Rome: Duty, Empire, and the Stoics" (eleven books, after
the Rhetorica), gets its places in the city of Rome, built to the standard of the Greek rooms (a
teacher who answers from a public-domain translation, a stone or a beat for every point, the place
lost to the world and mended piece by piece, its music changing with each piece), each in its own
zone of the city and in its author's own years. Asked by BB1 (2026-10-01): "Let's focus just on the
first module."

Decided: the reading order is the Essentials' own (works.json), and the city's age follows the
latest book mastered, as before; the Augustans (Livy's kings aside) stand with the late Republic,
whose city they knew, and the Stoics with the Empire. Every zone of the city now opens with the
first of its books. The Essentials list was read from its repository
(`tools/import_works.py` now writes `content/rome/works.json` too).

## The places (`scripts/hall/places_rome_books.gd`)
Each stands on a terrace cut into its hill (or on the flat by the Forum and the river), fenced,
with the city of the book's age about it, grey rubble while the place is lost.

| # | Book | Age | Zone | Place | Beats (played as) |
|---|---|---|---|---|---|
| 2 | Livy, History of Rome (Preface, I) | heroic, 280 BC | `palatina` | the hut of Romulus, the Lupercal, the furrow, the Sabines in the valley, Lucretia's bier | the furrow (Romulus), the Sabine women (Hersilia), the oath (Brutus) |
| 3 | Plutarch, Caesar | republic, 44 BC | `campus_martius` | Pompey's portico and hall, the Lupercalia's platform, the Rubicon | the Rubicon, the diadem, the Ides (Caesar) |
| 4 | Virgil, Aeneid | republic, 19 BC | `esquilina` | Maecenas's gardens with Troy burning, Dido's pyre, the bough's grove, the souls to come, the duelling ground | out of Troy, the bough, the belt of Pallas (Aeneas) |
| 5 | Lucretius, On the Nature of Things | republic, 55 BC | `collina` | a walled garden by the Colline Gate, the dark room, the altar at Aulis, the road of tombs, Nature's seat | the sunbeam, death is nothing to us (yourself) |
| 6 | Cicero, On Duties and On Friendship | republic, 44 BC | `palatine_forum` | the Rostra, the Senate House, the four stones of the honourable, the gate where Regulus walks out, his house and Laelius's bench | Regulus goes back (Regulus) |
| 7 | Cicero, the Dream of Scipio | republic, 51 BC | `capitolium` | the Arx at night, Juno Moneta, Masinissa's couch, the nine spheres over the hill, Africanus | the ascent (Scipio) |
| 8 | Ovid, Metamorphoses I and X | republic, AD 8 | `trans_tiberim` | a garden under the Janiculum: the laurel, the flood's pool, the four ages, the way down, Orpheus's hill, Pygmalion's workshop | Daphne (Apollo), looking back (Orpheus), the ivory girl (Pygmalion) |
| 9 | Tacitus, Agricola | empire, AD 98 | `collina` | Agricola's house with the masks, the bath and the toga, the hill of Mons Graupius and the legion, Domitian's statue | a desert called peace (Calgacus) |
| 10 | Epictetus, Encheiridion | empire, AD 90 | `suburana` | the house of Epaphroditus in the Subura: the lamp on the stair, the jar, the banquet, the mask, two baskets | ours and not ours (yourself) |
| 11 | Marcus Aurelius, Meditations II and IV | empire, AD 175 | `palatina` | a wing of the palace before dawn: the camp bed, the desk and tablets, the inner court, the wall of names, the terrace over the city | begin the morning, into yourself (Marcus) |
| 12 | Seneca, On the Shortness of Life | empire, AD 49 | `aventinus` | the river port: the quay and barges, the granary and its measuring floor, Paulinus's office, the sundial, the wise on their plinths | the ledger of years (yourself) |

Each teacher answers from his book: Spillan's Livy, Dryden's Plutarch and Virgil, Munro's
Lucretius, Miller's and Shuckburgh's Cicero, Yonge's Dream, Riley's Ovid, the Oxford Agricola,
Long's Epictetus and Marcus, Stewart's Seneca (`tools/build_corpus.py`). Every line quoted in a
beat is from those.

Four music zones: `kings` (a tibia on the old tales, the ploughman's drum), `horti` (a lyre and
a voice in the gardens), `spheres` (nine tones swelling over the Arx at night), `stoa` (a tibia,
a slow pulse, the legion's march). Two maps: 19 BC and AD 60.

## Known rough edges (for the fix pass)
- Placements are from coordinates; a few captures were taken (docs/dev/walks/module1_*), not every
  place from every side. Terraces are flat tops cut into the hills; their edges show as a step.
- The Dream's spheres are rings of light hung over the hill; the ascent raises your eyes fourteen
  metres and lowers them again.
- Two scanned sources (Yonge's Dream, Stewart's Seneca) keep a few scanner's slips.
- The Cicero of On Duties and the Cicero of the Dream are two rooms with the same portrait.
- The places are flat, bright and spread out next to the look we build toward (`docs/the-look.md`,
  saved 2026-10-15): the look pass (fog to the sky, carved edges, a landmark each, prop clumps) is
  the fix pass's biggest item.

## Playtest checklist for BB1
- In the city: do the eleven gateways stand where you can find them, each in its own quarter?
- In each place: is the way in clear? Does anything float, sink or block the way? Is the fence
  where it should be?
- Play every beat. Is the pace right? Do the hands and what they hold read as the hero's?
- Lost to whole: does each piece that comes back show and sound?
- Do the teachers answer well from their books? Do the scanned ones read cleanly enough?
- The city's age: after mastering Seneca or Tacitus, does the city move on to the Empire?

## Retro
(after the playtest)
