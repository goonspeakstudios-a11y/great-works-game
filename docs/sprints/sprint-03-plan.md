# Sprint 3 plan: Aristotle's areas, Zen and Student (planning, 2026-09-26)

Decided with BB1 (grill session). Nothing here is built yet.

## Two versions
- **Zen** and **Student** (not "Hardcore").
- Chosen PER WORLD, on first entering it, in that world's own words. Greece: **Theoros** (Zen, the pilgrim who comes to see) or **Mathetes** (Student, the pupil). Switchable in the Esc menu for the world you are in; nothing mended is undone. BUILT 2026-09-26 (scripts/hall/choice.gd, worlds.json "modes", Progress.mode).
- **Zen, for now:** pressing F on a lesson stone counts that point as understood, and a piece of the world comes back. (Reciting back to the teacher: later.) BUILT 2026-09-27 (hall.gd _read_stone, sharing _learned with the teacher's check).
- **Student:** the stones are there to read but heal nothing. A point counts only through the teacher: a correct explanation with the student's OWN example, plus one of these, chosen by the teacher: why it matters / a hard follow-up question / a tie to another point.

## Stones
- One stone per lesson point, carrying the plain summary (the lesson "point" text). Present in both versions.
- Each area's life facts move to one stone at the area's entrance, next to its banner. BUILT 2026-09-27 for the hill and the grove (the Lyceum's and the villa's facts stay along their ways in).

## Around each stone: a scene that relates to its point (life and character)
- More than one prop/plinth per scene is fine where it fits better.
- Lyceum: ten kinds (ring of ten plinths with things), homonyms (real horse, painted horse), said-of vs present-in (Socrates statue with a white sash), primary substance (one man, one horse), secondary substance (same, "man"/"animal" on a lintel), marks of substance (a man between a cold and a lit brazier).
- Organon hill: premise (stone carved "every A is B"), syllogism (three stones, the first two light the third), middle term (two stones joined by a lintel), three figures (the three stone groups), conversion (stone reads each way), fallacies (a painted false path).
- Ethics grove: highest good (stair of altars), activity (one swallow on a branch), habit (worn footprint path), the mean (ledge between rash fire and cowering shade), pleasure as test (a glad lyre player), contemplation (bench facing the sunset).

- Scenes play themselves for now; hands-on activities later, when each place gets its detail.
- Order: Aristotle's three areas first, then Porphyry's villa the same way.
- BUILT 2026-09-26/27: all four places (places.gd _lyceum_lessons, _organon_lessons, _ethics_lessons, _villa_lessons). The Lyceum's ring of ten stands by the way in; its other five stand behind the walkway, round its south end.
- Villa scenes (not decided in the grill session, so for BB1 to judge at the playtest), spread round the grounds (two by the way in, two on the lawns level with the house, two among the olives behind it): why (a letter to Chrysaorius on a stand), family and kind (a pen with a man, a goat and a dog), what splits them (a goat grazing beside a man reading), always vs. sometimes (a laughing mask on a post, an empty stool), definition (Porphyry's Tree in stone), the open question (an empty plinth carved ANIMAL).
