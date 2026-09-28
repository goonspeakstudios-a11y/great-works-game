# Sprint 5: Plato's Academy, and the city in speech

**Goal:** the Republic gets its place, built to the standard of sprints 3 and 4 (a teacher who
answers from the real text, a stone or a scene for every point, the place lost to the world and
mended piece by piece), with its own game at its heart: you found and govern the city in speech,
"logical, almost semi-CK3 political planning", season by season at a council table with Socrates.

Decided with BB1 (2026-09-28): scope is the Academy and the city game, with the other Republic
scenes (Gyges, the divided line, the cave, Er, Socrates' trial and death) as stones and beats; time
passes in seasons, turn by turn; the interface is council table panels. The design is
`docs/republic-city.md`.

## Stories
1. **The city** (`scripts/hall/city.gd`, `content/greece/republic.json`): ten founders with hidden
   metals (gold, silver, bronze, iron) and traits. Trials reveal a person's metal, two a season.
   Everyone is given one work: a trade, soldier or ruler. Ten laws in the book's order, each with
   Socrates' reasons and Glaucon's or Adeimantus's objection:
   - one man, one work
   - luxuries
   - war for land
   - the curriculum
   - the poets censored
   - the noble lie
   - no property
   - women guardians
   - common families
   - philosopher-kings

   Every season can bring trouble to answer: the perfumer at the gate, the plague, the grain route
   cut, the neighbours' war, stasis, a coup, the tyrant's bodyguard, Persian gold, a guardian with
   gold, the poet. The meters are food, land, luxury, rich and poor, unity, justice and the army.
   There are ten stages, from the bare site to the just city. After it the generations pass and the
   city falls: timocracy, oligarchy, democracy, tyranny.
2. **The council table** (`scripts/hall/council.gd`), laid out as panels:
   - the city's measures and what it needs next
   - its people, with trials and work
   - the laws
   - the season's trouble and its choices
   - what Socrates says
   - end the season, or let the generations pass

   The city is saved with your progress. For a Theoros the city of pigs and the just city count as
   they are reached.
3. **#7 Plato's Republic, the Academy, about 380 BC:**
   - Plato in his olive grove by the spring, with the busts of Socrates and Pythagoras, the new map
     of 380 BC, and Jowett's Republic, Apology, Symposium and Phaedo on the stand.
   - A terrace above the board with the council table, where Socrates, Glaucon and Adeimantus sit
     with you.
   - The board shows the city as far as you have governed it. When the city is just, the soul rises
     over it. As the city falls, the board loses its lamps, its green, its walls and at last its
     people, and the soul burns down to the tyrant's red appetite.
4. **The Republic's eight points, round the board:**
   - the argument at Cephalus's house (justice)
   - Gyges' ring (a beat as Gyges: down the chasm, the ring from the dead, invisible among the
     shepherds)
   - the city of pigs and the just city (stones on the board that wait until the city has got so
     far)
   - the soul (a beat on the board, once the city is just)
   - the divided line (walked from shadows to the sun)
   - the cave (a beat: sit chained, turn round, climb out, go back down)
   - Er (take your lot, choose a life, drink from Lethe)
5. **Not points:** Socrates' trial (a beat as Socrates, the gadfly and the verdict), Agathon's dinner
   (Diotima's ladder) and the last day (a beat as Socrates: the cup, the walk, the last words).
6. **Music:** the `academy` zone gains the city's crowd and its guardians' trumpet, so every piece
   brought back is heard.

## Playtest checklist for BB1
- The Shore: is the gateway to #7 open?
- The council table:
  - Is it clear what the city needs next, and why a law cannot yet pass?
  - Do trials, work and laws feel like planning, not clicking?
  - Is a season the right length?
  - Do Socrates' reasons and the brothers' objections help?
  - Does the trouble each season feel like the real threats of the time?
- The board: can you see the city grow from the terrace? Does the soul rising over the just city
  land? Is the fall, regime by regime, clear on the board and at the table?
- Play every beat: Gyges, the soul, the line, the cave, Er, the trial, the cup. Is the cave's way up
  easy to find and climb?
- Lost to whole: does each piece that comes back feel earned, and can you hear it?
- Anything annoying, confusing or ugly?

## Retro
(after the playtest)
