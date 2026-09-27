# Poly Haven (CC0)

Greek-world textures and props from polyhaven.com. Credits and license: `LICENSE.md`.
Refetch or add more: `python tools/fetch_polyhaven.py` (edit TEXTURES / MODELS at the top).

- Textures: `textures/<id>.png`, 64 px, 24 colours, to match the hall's pixel textures.
  Use one on any shape with `Textures.material("ph_<id>")`, e.g. `"ph_marble_tiles"`.
  The 1k sources (`*_src.jpg`) are not committed; the script re-downloads them.
- Models: `models/<id>/<id>.gltf` (marble bust, antique vase). Drop into a scene as-is.
