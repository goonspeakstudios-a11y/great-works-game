# The Republic: the city in speech

**Decided with BB1 (2026-09-28, after playing it):** the council-table game was cut. As BB1 put it,
the planning game made no sense; seeing the world build as you build it up, in a sensible fashion,
is what's worth keeping. The city simulation (`city.gd`), the council panel (`council.gd`) and their
data (`republic.json`) are gone.

## How it works now
- On the terrace above the board sits the table where Socrates, Glaucon and Adeimantus talk. At it,
  one step of the argument waits at a time. It is a beat, played one line and one act at a time.
- The board below stands as far as the talk has gone. The next step's buildings stand on it,
  hidden. As you play the step, they rise one by one in front of you, in the order the book raises
  them.

| Step | Beat | What rises | Book |
|---|---|---|---|
| 1 | `found_1` the city of pigs | the farmer, then the builder and the weaver, then the other trades, then the merchant, with their houses and the feast | II.369-372 |
| 2 | `found_2` the fevered city | the couches, cooks and painters; the doctors and the swine; the boundary pushed onto the neighbours' land | II.372-373 |
| 3 | `found_3` the army | the camp on the land it took | II.373-376 |
| 4 | `found_4` the guardians | their common house and training ground; the young in training; the rulers on the height (with the noble lie and no property) | II-III |
| 5 | `found_5` the just city | the wall round the city, each order in its place; then the soul over the city | IV-V |
| 6-9 | `decline_6`..`decline_9` | the fall, a generation at a time: timocracy, oligarchy, democracy, tyranny. The board loses its lamps, green, walls and people, and the soul's parts dim until only appetite burns, red | VIII-IX |

- After tyranny, the city can be founded again from the bare site.
- The city's stage is kept in your progress (`city_stage`). The board is built half again as large
  as life, so it reads from the terrace.
- **Points:** for a Theoros, the city of pigs and the just city count as the city reaches them.
  Their stones on the board's edges, and the soul beat, wait until then.
