# The look

Saved 2026-10-15 from a reference BB1 sent: a video still in the N64 Rare style, a graveyard church
on a carved island against an orange sunset, in the manner of Banjo-Kazooie's Mad Monster Mansion
(the exact source is unverified). The copy is `docs/dev/look_reference.webp`. This page says what
the picture does and what it means for our places. It is direction, not a sprint: the look pass at
the bottom is the work it implies, and it is not built.

## What the picture does

1. **One sky, saturated, and everything stands against it.** A three-band gradient (deep orange at
   the horizon, through amber, to a brown-black top), with the far landmarks as flat dark silhouettes
   on it. No blue, no white. The sky is the biggest colour in the frame and the mood is in it.
2. **A focal spire.** One tall thin thing in the middle of the island (the church steeple), lit from
   the side, so the eye lands on it from anywhere. Behind it more spires and towers in the skyline,
   each smaller than the last.
3. **Carved islands, not plains.** The ground is a terrace with a visible edge: a carved rock face
   below, a kerb of worked stone, railings or fences along the brink, and steps or walkways that
   leave it. The flat top is small; most of the picture is edge.
4. **The dark below, the warm above.** The valley floor is near black, lit only by an orange sheen;
   the terrace top is warm and readable. Fog the colour of the sky fills the distance, so far things
   lose contrast and go to silhouette.
5. **Characterful props in clumps.** Gravestones in groups, dead trees, fences with gaps, a lantern,
   a skull set in a wall, a broken urn: dozens of small things, each one readable, placed in clumps
   with gaps between, never spread evenly.
6. **Chunky, textured forms.** Thick walls, oversized stones, exaggerated proportions, textures with
   visible grain and no detail smaller than the pixel grid will hold. Nothing thin, nothing smooth.
7. **Ground that remembers.** Tracks, bare patches, moss at the edges, a path worn where feet go.
   The top of the island is not one colour.
8. **A warm key light from the horizon.** Low, from the sunset's side, so every vertical gets a lit
   side and a dark side; the ambient is cool and dark; shadows are long and soft.

## What it means for us

The subject stays Rome (and Greece, and the rest); no Halloween, no pumpkins, no Rare characters, no
copying of their shapes. The vibe is in the composition, the light and the silhouette. Rules to
build to, in every world:

- **Every place is built against its sky.** The sky's horizon colour is the place's colour; the fog
  is tinted to it (the fog colour is the horizon, not grey, and `fog_sky_affect` is raised); the far
  city and hills read as silhouettes against it, nothing in the distance drawn in its own daylight
  colours. The MOODS table in `scripts/hall/kit.gd` gets a mood per place: the Kings' hut at a
  red-gold evening, the Arx at blue twilight, the Suburan insula at a smoky dusk; "noon" and
  "morning" only where the text asks for them.
- **One landmark per place**, tall and thin, in the frame from the gate: a temple on its podium, a
  column monument, a tower, a tall pine, the Pharos, the spheres. It stands where the lesson's centre
  is, so finding the teacher is finding the spire.
- **Terraces have edges.** Every terrace box (`_frame` in `scripts/hall/places_rome_books.gd`) gets
  a carved rock skirt below the lip (a stepped blob, darker than the top), a kerb of stone along the
  brink, a railing or fence where there is a drop, and one or two ramps that leave it. From the gate
  you see the edge and the drop, not a flat yellow sheet.
- **Props in clumps.** Three to seven things together, then a gap to the next clump; some tall (a
  cypress, a herm, a stele), some low (a basket, a broken pot, a stool); each clump about something
  (the well and its jars; the shrine and its offerings; the tomb and its cypress).
- **Ground is not one colour**: a worn path to the teacher and the stones, bare earth under the
  trees, a darker ring at the terrace's edge.
- **Light**: the key light low and warm, the ambient cool and dark (ambient energy down, the sky's
  top colour), shadows on. Exposure down a touch so the sky saturates instead of blowing out.
- **The dark below**: beyond the edge the ground drops to a valley floor darker than the terrace;
  the city is lit by the sky's sheen, not by its own daylight.
- **Keep the fidelity rule** (Greece 320x180, Rome 640x360). Chunky forms and visible grain are the
  point; fine detail is lost at that resolution and is not to be spent.

## Where we are (the sprint 7 captures)

- `docs/dev/walks/module1_livy_6.png`: bright noon, a white-blue sky, a flat yellow terrace, small
  white things spread out, the city behind in its own daylight colours. The reverse of the
  reference in every line above except the chunky forms.
- `docs/dev/walks/module1_dream_6.png`: the mood is right (twilight, the temple against the sky, a
  lit disc behind it) and the terrace box fills the frame because the gate looks at its lip. The
  disc reads as a moon, not as the spheres.

## The look pass (not built; to plan as a sprint or part of one)

1. Fog tinted to the horizon colour and `fog_sky_affect` raised; ambient energy lowered; exposure
   per mood. One change in `Kit.sunset`, checked in every place's capture, Greece included.
2. Rock skirts, kerbs, fences and ramps on every terrace in `_frame`; each gate and arrival placed
   to see the edge and the landmark.
3. A landmark per place, and the Dream's spheres as nine rings, not a disc. Proposed:

   | Place | Landmark |
   |---|---|
   | The domus (Rhetorica) | the Capitol's temple above the Forum |
   | The hut of Romulus (Livy) | the Ruminal fig, taller than the hut, the Capitol behind |
   | Pompey's curia (Plutarch) | the theatre with the temple of Venus on its crown |
   | Maecenas's gardens (Virgil) | the tower of Maecenas |
   | The Colline garden (Lucretius) | one umbrella pine over the garden |
   | The Rostra (Cicero, On Duties) | the Rostra's beaks with the temple of Jupiter behind |
   | The Arx (the Dream) | the temple of Juno Moneta under the spheres |
   | The gardens across the Tiber (Ovid) | a cypress on the bank, the Janiculum's ridge behind |
   | Agricola's house (Tacitus) | a cypress avenue and the family tomb |
   | The Suburan insula (Epictetus) | the insula itself, five storeys, the tallest thing round |
   | The palace (Marcus) | the belvedere tower over the Circus |
   | The Emporium (Seneca) | a crane on the quay and Diana's temple on the Aventine |

4. Prop clumps (a `Places.clump` helper that takes a theme) replacing the spread-out small scenes
   at the stones.
5. Worn paths and edge rings in the terrace top materials.
6. A mood per place, chosen for its hour in the book.
7. Captures from the gate of every place, lost and whole, laid side by side with the reference.
