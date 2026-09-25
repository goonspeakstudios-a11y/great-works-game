# Great Works

A 3D story and card-battle game for Steam. You walk the ancient world and watch
the great books play out, then fight at a card table where the cards are the
ideas you learned. No reading required.
You play a card at full power only by recalling its idea. Ideas you miss come back
sooner; ideas you master turn gold and hit harder.

Version 1 covers ancient Greece. Slice 1: the camp at Troy (3 story scenes from the Iliad,
1 card-table fight against Hector). Gray blocks stand in for art.

## Run it
- Game: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path .`
- Editor: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path . -e`
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
- Refresh works from the reading list: `C:\Python314\python.exe tools/import_works.py`

## Layout
- `content/greece/` - works (generated), ideas, enemies, bosses as JSON
- `scripts/` - memory (spaced review), recall (prompts), combat, story, save, content, main
- `scripts/world/` - 3D camp, player, gray-block builders; `scripts/table/` - 3D card table
- Screenshot a view: `godot --path . -- --shot=out.png --state=world|scene|learn|table|recall [--beats=N]`
- `tests/` - headless test runner; any engine error fails the test
