"""Download CC0 textures and models from Poly Haven for the Greek world, check each file
against Poly Haven's published MD5, and make small pixel versions of the textures.

Run: python tools/fetch_polyhaven.py   (needs Pillow; re-running skips files already present)

Textures: assets/polyhaven/textures/<id>_src.jpg (1k source) and <id>.png (pixel version).
Models:   assets/polyhaven/models/<id>/<id>.gltf with its .bin and 1k textures.
"""
import hashlib
import json
import logging
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "polyhaven"
API = "https://api.polyhaven.com"
PIXEL_SIZE = 64      # the hall's own textures are 16-64 px
PALETTE = 24         # colours per texture, keeps the low-res look

# id on Poly Haven -> what it is for in Greece
TEXTURES = {
    "marble_01": "white marble: temple walls, stelae, plinths",
    "marble_tiles": "marble paving: stoa and temple floors",
    "large_sandstone_blocks": "cut limestone blocks: walls, the Lyceum",
    "clay_plaster": "plaster: houses, the hall's inner walls",
    "clay_roof_tiles": "terracotta roof tiles",
    "patterned_terracotta_tiling": "terracotta floor",
    "old_stone_wall": "rough stone: field walls, the hill",
    "oak_wood_planks": "wood: doors, lecterns, boats",
}
MODELS = {
    "marble_bust_01": "classical marble bust",
    "antique_ceramic_vase_01": "antique ceramic vase (amphora stand-in)",
}

log = logging.getLogger("fetch_polyhaven")


def get(url: str, tries: int = 4) -> bytes:
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "great-works-asset-fetch"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except OSError as e:
            if i == tries - 1:
                raise
            wait = 2 ** (i + 1)
            log.warning("fetch failed (%s), retry in %ss: %s", e, wait, url)
            time.sleep(wait)
    raise RuntimeError("unreachable")


def save_checked(url: str, md5: str, dest: Path) -> None:
    if dest.exists() and hashlib.md5(dest.read_bytes()).hexdigest() == md5:
        return
    data = get(url)
    if hashlib.md5(data).hexdigest() != md5:
        raise ValueError(f"MD5 mismatch for {url}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    log.info("saved %s (%d KB)", dest.relative_to(ROOT), len(data) // 1024)


def pixelate(src: Path, dest: Path) -> None:
    img = Image.open(src).convert("RGB").resize((PIXEL_SIZE, PIXEL_SIZE), Image.Resampling.BOX)
    img = img.quantize(colors=PALETTE, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    img.convert("RGB").save(dest)


def info(asset: str) -> dict:
    return json.loads(get(f"{API}/info/{asset}"))


def fetch_texture(asset: str) -> dict:
    files = json.loads(get(f"{API}/files/{asset}"))
    f = files["Diffuse"]["1k"]["jpg"]
    src = OUT / "textures" / f"{asset}_src.jpg"
    save_checked(f["url"], f["md5"], src)
    pixelate(src, OUT / "textures" / f"{asset}.png")
    return info(asset)


def fetch_model(asset: str) -> dict:
    files = json.loads(get(f"{API}/files/{asset}"))
    g = files["gltf"]["1k"]["gltf"]
    folder = OUT / "models" / asset
    save_checked(g["url"], g["md5"], folder / f"{asset}.gltf")
    for rel, f in g["include"].items():
        save_checked(f["url"], f["md5"], folder / rel)
    return info(asset)


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    credits = []
    failed = []
    for kind, table, fn in (("texture", TEXTURES, fetch_texture), ("model", MODELS, fetch_model)):
        for asset, use in table.items():
            try:
                meta = fn(asset)
                authors = ", ".join(meta.get("authors", {}))
                credits.append(f"| {kind} | {asset} | {meta.get('name', asset)} | {authors} | {use} |")
            except Exception as e:  # keep going; report at the end
                log.error("%s %s failed: %s", kind, asset, e)
                failed.append(asset)
    lines = [
        "# Poly Haven assets",
        "",
        "License: CC0 1.0 (public domain), https://polyhaven.com/license. No credit required;",
        "listed here for the game's credits. Fetched and MD5-checked by `tools/fetch_polyhaven.py`.",
        "",
        "| Kind | Id | Name | Author(s) | Use in Greece |",
        "|---|---|---|---|---|",
        *credits,
        "",
    ]
    (OUT / "LICENSE.md").write_text("\n".join(lines), encoding="utf-8")
    if failed:
        log.error("failed: %s", ", ".join(failed))
        return 1
    log.info("done: %d textures, %d models", len(TEXTURES), len(MODELS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
