# Great Works

A dark, low-resolution 3D hall (in the spirit of King's Field) with one room per book on the
Essentials reading list, in order. In each room: short facts on the walls, the book itself on a
lectern (read a real page), and the author's portrait. Walk up and ask the author anything about
their book: they answer in plain words, powered by Claude Haiku 4.5, from passages of the actual
text, and show the lines they quoted.

Now: the Hall of Greece with all 17 doors; room 1 (Porphyry, Isagoge) is open. Design history and
the reading-list map: `docs/greek-game-map.md`. The earlier 3D card slice is kept under tag `3d-slice-final`.

## Run it
- Game: `Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe --path .`
- Controls: WASD/arrows walk, left/right arrows or mouse turn (click to capture the mouse), E to read or ask, Esc to close / free the mouse / quit.
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
- Screenshot a view: `godot --path . -- --shot=out.png --view=hall|door|room|read|ask`

## The authors (AI)
- Model: `claude-haiku-4-5`, about half a cent per question. Code: `scripts/hall/author_ai.gd`.
- API key: set `ANTHROPIC_API_KEY`, or put it in the game's user folder (never in this repo):
  `%APPDATA%\Godot\app_userdata\Great Works\secrets.cfg` with `[anthropic]` and `api_key="sk-ant-..."`.
- The authors need internet. The "Great Works (sandboxed)" shortcut's Sandboxie box blocks internet.
- Ask from the command line: `godot --headless --path . --script res://tools/ask_author.gd -- porphyry-isagoge "What is a genus?"`
- For a Steam release the key must move behind a small server, so players never hold it.

## Books
- Source files live in `Desktop\Book Collections` (public-domain translations).
- `C:\Python314\python.exe tools/build_corpus.py` turns a configured book into passages in `content/books/`.
- Room text (facts, the author's persona, suggested questions, portrait): `content/greece/rooms.json`.
- Works and their order come from the reading list: `C:\Python314\python.exe tools/import_works.py`.

## Layout
- `scripts/hall/` - hall (3D world and panels), player, rooms, library (passage search), author_ai, portrait, textures
- `scripts/pixel/music.gd` - the code-made music (rendered by `tools/make_music.py`)
- `scripts/` (top level) and `scripts/world`, `scripts/table` - the old 3D card slice. Its tests still pass, but it no longer displays correctly at the new 320x180 setting; it is kept only until it is removed (history: tag `3d-slice-final`)
