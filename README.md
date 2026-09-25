# Great Works

A card-battle run game for Steam. The cards are ideas from the great books,
and you play one at full power only by recalling it. Ideas you miss come back
sooner; ideas you master turn gold and hit harder.

Version 1 covers ancient Greece. This prototype has region one: Troy and the Epic Age
(Homer and Hesiod, 14 ideas, 3 enemies, and Achilles as the boss).

## Run it
- Game: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path .`
- Editor: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path . -e`
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
- Refresh works from the reading list: `C:\Python314\python.exe tools/import_works.py`

## Layout
- `content/greece/` - works (generated), ideas, enemies, bosses as JSON
- `scripts/` - memory (spaced review), recall (prompts), combat, run, save, content, main (screens)
- `tests/` - headless test runner; any engine error fails the test
