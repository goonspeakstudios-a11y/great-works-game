# Greek Game Map

Decided with BB1, 2026-09-25. This replaces the card game and the recall quizzes.

## Rules
- The game follows the **Essentials reading list in its own order**, starting with Porphyry's Isagoge.
  Greece = Essentials modules 1-4, "Read" works only (17 works). `tools/import_works.py` generates
  `content/greece/works.json` from `Essential-Reading-List/learn/essentials.json`.
- **Look:** 16-bit pixel art, top-down, faded and haunted. You arrive after the fall.
  The world is gray; only memories have color. Music: slow, dark and grand (King's Field IV mood), original.
- **No quizzes, no health-bar battles.** You learn an idea by playing it: the idea is the rule
  of the level, or you live the choice and its cost.
- **Quick stages:** one work is one stage, about 10 minutes. One short line of text at a time.
  Book names, authors and Greek words are optional extras, never required.
- **Music is made in-house, in code** (BB1 approved the preview's sketch, 2026-09-25): low drones,
  slow minor chords, long reverb, distant bells, wind. Built with Godot's own audio (no downloads).
  Vary it by module where it fits: e1 sparse and quiet (thinking), e2 grand and mournful,
  e3 heavier and darker, e4 higher and stranger. Memory scenes can warm up; silence is allowed.
- One world, one hero, one art style. Each module changes *how you play*, not the world.

## Game style per module
| Module | Style (`style` in works.json) | Model games |
|---|---|---|
| e1 How to Read and Argue | `puzzle` - silent puzzles that teach their rule by solving | The Witness, Euclidea |
| e2 Homer and the Gods | `story-walk` - wander, then play the key moment | Journey, Hyper Light Drifter |
| e3 Tragedy, History, and the City | `hard-choices` - every option costs something | Papers, Please; This War of Mine |
| e4 Plato and Aristotle | `thought-experiment` - the world obeys the idea | The Stanley Parable, Braid |

## Stages (reading-list order)
| # | Work | What you play |
|---|---|---|
| 1 | Porphyry, Isagoge | Rebuild a shattered statue: strip what is extra, keep what makes it *that* thing (genus, species, difference, property, accident) |
| 2 | Aristotle, Categories | A ruined storeroom that only settles when everything is on its right shelf |
| 3 | Aristotle, the Organon | Cross a chasm on bridges of argument: valid forms hold, fallacies collapse; a trickster offers shortcuts |
| 4 | Rhetorica ad Herennium | Build a memory palace: place memories in rooms, walk back to recall them (the camp works this way) |
| 5 | Euclid, Elements | Rebuild a fallen temple with only compass and straight edge |
| 6 | Homer, Iliad and Odyssey | Achilles' pride, Hector at the gate, Priam kneels; Odysseus comes home |
| 7 | Hesiod | Sons overthrow fathers, again and again; a farming year where shortcuts fail |
| 8 | Sappho | Piece together torn poems, knowing most pieces are gone forever |
| 9 | Aeschylus, Oresteia | A revenge chain that only a jury can end |
| 10 | Sophocles, Theban Plays | Oedipus hunts the killer and finds himself; Antigone: brother or king |
| 11 | Euripides, The Bacchae | The god grows stronger the more you push him away |
| 12 | Aristophanes, The Clouds | Clever nonsense beats the honest argument |
| 13 | Herodotus | Croesus, happiest king alive, until he isn't; Thermopylae |
| 14 | Thucydides | Race to recall a ship sent to destroy a city; Melos, where nothing you say works |
| 15 | Pre-Socratics | The river that changes every visit; the world that refuses to change |
| 16 | Plato | The Cave; the invisibility ring; Socrates' last day |
| 17 | Aristotle, Ethics | The middle path; habits that become your controls |

Playable look preview: https://claude.ai/artifact/HDxwQCS9Ze3Z8YGY2Q6YAb (story and mood are right;
its quiz and battle screens are the part that was rejected).
