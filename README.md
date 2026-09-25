# Great Works

A haunted 16-bit pixel game for Steam that follows the Essentials reading list.
You walk a gray, ruined ancient world and learn each book's ideas by playing them.
No reading required, and no quizzes. Design: `docs/greek-game-map.md`.

**Pivot in progress (2026-09-25):** the code below is still the old 3D slice (Troy camp,
story scenes, card-table fight). It is being replaced by the pixel version; see the
GitHub milestones "Pixel 1" onward.

## Run it
- Game: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path .`
- Editor: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path . -e`
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
- Refresh works from the reading list: `C:\Python314\python.exe tools/import_works.py`

## Layout
- `content/greece/` - works (generated from Essentials modules 1-4), ideas, enemies, bosses as JSON
- `scripts/` - memory (spaced review), recall (prompts), combat, story, save, content, main
- `scripts/world/` - 3D camp, player, gray-block builders; `scripts/table/` - 3D card table
- Screenshot a view: `godot --path . -- --shot=out.png --state=world|scene|learn|table|recall [--beats=N]`
- `tests/` - headless test runner; any engine error fails the test

## Roadmap
Tracked on GitHub: milestones "Pixel 1" to "Pixel 5", then "M4 Steam prep", plus
"Later: paid upgrades". Free work comes first.
Third-party assets and their licenses: `assets/quaternius/README.md`.
