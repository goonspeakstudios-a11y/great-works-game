"""Render a political map of the known world for a moment in history, as a pixel image.

Coastlines come from Natural Earth (public domain; put ne_50m_land.geojson in tools/data/).
Borders are drawn here by hand from the historical record, in longitude/latitude, and are
approximate. Output: assets/maps/<id>.png plus content/maps/<id>.json (the regions, their
colours and label spots, and the pinned places, in image pixels).

Usage: C:\\Python314\\python.exe tools/build_map.py [map-id ...]
"""
from __future__ import annotations

import json
import logging
import math
import struct
import sys
import zlib
from pathlib import Path

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
LAND = ROOT / "tools" / "data" / "ne_50m_land.geojson"
OUT_IMG = ROOT / "assets" / "maps"
OUT_DATA = ROOT / "content" / "maps"

SEA = (44, 70, 86)
SEA_DARK = (36, 60, 76)
OUTSIDE = (176, 158, 118)
COAST = (32, 28, 24)

MAPS = {
    "270ad": {
        "title": "The world in 270 AD",
        "bounds": [-11.0, 58.0, 20.0, 57.0],  # west, east, south, north
        "px_per_deg": 4.0,
        # later regions win where they overlap earlier ones
        "regions": [
            {"name": "Roman Empire", "sub": "Emperor Aurelian", "color": [150, 58, 42], "label": [18.0, 44.5],
             "poly": [(-5.5, 55.0), (-1.5, 55.0), (4.5, 52.0), (6.5, 51.5), (7.5, 50.5), (8.3, 50.0), (8.8, 50.4),
                      (9.5, 49.5), (10.5, 49.0), (12.1, 49.0), (13.5, 48.6), (16.4, 48.2), (18.9, 47.8),
                      (19.0, 47.5), (18.9, 45.9), (20.5, 44.8), (21.0, 45.4), (22.5, 47.5), (24.5, 47.8),
                      (26.5, 46.5), (26.0, 45.2), (27.5, 44.2), (29.5, 45.0), (33.0, 43.5), (41.5, 41.8),
                      (43.5, 40.5), (41.0, 37.5), (40.5, 35.0), (39.0, 34.0), (37.5, 32.0), (36.5, 29.0),
                      (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (20.0, 30.3), (15.0, 30.0),
                      (10.0, 32.0), (8.0, 33.5), (5.0, 34.5), (0.0, 34.5), (-5.0, 34.0), (-7.0, 34.0),
                      (-10.5, 34.5), (-10.5, 44.0), (-5.8, 50.0), (-5.2, 52.0), (-4.8, 54.0)]},
            {"name": "Gallic Empire", "sub": "breakaway west", "color": [70, 104, 138], "label": [1.5, 47.5],
             "poly": [(-5.5, 55.0), (-1.5, 55.0), (4.5, 52.0), (6.5, 51.5), (7.5, 50.5), (8.3, 50.0),
                      (8.3, 47.6), (7.0, 46.0), (7.6, 44.0), (3.2, 42.4), (-1.8, 43.3), (-5.0, 48.3),
                      (-5.8, 50.0), (-5.2, 52.0), (-4.8, 54.0)]},
            {"name": "Palmyrene Empire", "sub": "Queen Zenobia", "color": [196, 146, 48], "label": [36.0, 30.0],
             "poly": [(35.6, 36.9), (38.0, 37.1), (40.5, 37.4), (42.0, 36.5), (40.5, 34.5), (38.8, 32.0),
                      (37.0, 29.0), (35.0, 27.8), (33.6, 26.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5),
                      (25.1, 31.8), (29.0, 31.3), (34.2, 31.4), (35.2, 34.0)]},
            {"name": "Sasanian Persia", "sub": "King Hormizd I", "color": [84, 118, 70], "label": [50.5, 31.0],
             "poly": [(42.0, 38.8), (46.0, 40.2), (50.0, 39.0), (54.0, 38.3), (58.5, 38.0), (58.5, 24.5),
                      (56.5, 24.0), (51.5, 27.0), (48.5, 29.8), (47.5, 30.5), (44.5, 31.2), (42.0, 33.5),
                      (41.5, 35.5), (42.3, 36.8), (42.0, 36.5)]},
        ],
        "others": [
            {"name": "Germanic peoples", "at": [12.0, 52.5]},
            {"name": "Goths", "at": [31.0, 48.5]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Sahara", "at": [10.0, 25.0]},
        ],
        "pins": [
            {"name": "Lilybaeum, Sicily", "note": "Porphyry writes the Isagoge here", "at": [12.44, 37.80], "main": True},
            {"name": "Rome", "note": "Plotinus's school", "at": [12.49, 41.90]},
            {"name": "Tyre", "note": "Porphyry's birthplace", "at": [35.20, 33.27], "side": "below"},
            {"name": "Athens", "note": "where he studied", "at": [23.73, 37.98], "side": "above"},
            {"name": "Palmyra", "note": "Zenobia's city", "at": [38.27, 34.55]},
        ],
    },
}


def inside(x: float, y: float, poly: list) -> bool:
    """Even-odd test: is point (x, y) inside the polygon?"""
    hit = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            hit = not hit
        j = i
    return hit


class Projection:
    def __init__(self, spec: dict) -> None:
        self.w_lon, self.e_lon, self.s_lat, self.n_lat = spec["bounds"]
        ppd = spec["px_per_deg"]
        self.sx = ppd * math.cos(math.radians((self.s_lat + self.n_lat) / 2))
        self.sy = ppd
        self.width = round((self.e_lon - self.w_lon) * self.sx)
        self.height = round((self.n_lat - self.s_lat) * self.sy)

    def to_px(self, lon: float, lat: float) -> tuple[float, float]:
        return (lon - self.w_lon) * self.sx, (self.n_lat - lat) * self.sy

    def to_lonlat(self, px: float, py: float) -> tuple[float, float]:
        return self.w_lon + px / self.sx, self.n_lat - py / self.sy


def land_mask(proj: Projection) -> list[list[bool]]:
    """Scanline-fill every land polygon (holes included) into a pixel grid."""
    grid = [[False] * proj.width for _ in range(proj.height)]
    shapes = json.loads(LAND.read_text(encoding="utf-8"))["features"]
    for feature in shapes:
        geom = feature["geometry"]
        polys = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
        for rings in polys:
            px_rings = [[proj.to_px(lon, lat) for lon, lat in ring] for ring in rings]
            ys = [p[1] for r in px_rings for p in r]
            if max(ys) < 0 or min(ys) >= proj.height:
                continue
            xs = [p[0] for r in px_rings for p in r]
            if max(xs) < 0 or min(xs) >= proj.width:
                continue
            for row in range(max(0, int(min(ys))), min(proj.height, int(max(ys)) + 1)):
                cy = row + 0.5
                cross: list[float] = []
                for ring in px_rings:
                    for (x1, y1), (x2, y2) in zip(ring, ring[1:] + ring[:1]):
                        if (y1 > cy) != (y2 > cy):
                            cross.append(x1 + (cy - y1) * (x2 - x1) / (y2 - y1))
                cross.sort()
                for a, b in zip(cross[::2], cross[1::2]):
                    for col in range(max(0, math.ceil(a - 0.5)), min(proj.width, math.floor(b - 0.5) + 1)):
                        grid[row][col] = True
    return grid


def write_png(path: Path, pixels: list[list[tuple]], width: int, height: int) -> None:
    raw = b"".join(b"\x00" + bytes(c for px in row for c in px) for row in pixels)
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def build(map_id: str) -> None:
    spec = MAPS[map_id]
    proj = Projection(spec)
    land = land_mask(proj)
    w, h = proj.width, proj.height
    region_of = [[-1] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if not land[y][x]:
                continue
            lon, lat = proj.to_lonlat(x + 0.5, y + 0.5)
            for i, r in enumerate(spec["regions"]):
                if inside(lon, lat, r["poly"]):
                    region_of[y][x] = i
    pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            if not land[y][x]:
                row.append(SEA_DARK if (x + y) % 7 == 0 else SEA)
                continue
            coast = any(not land[yy][xx] for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1))
                        if 0 <= yy < h and 0 <= xx < w)
            r = region_of[y][x]
            base = tuple(spec["regions"][r]["color"]) if r >= 0 else OUTSIDE
            border = any(land[yy][xx] and region_of[yy][xx] != r for yy, xx in ((y, x + 1), (y + 1, x))
                         if 0 <= yy < h and 0 <= xx < w)
            if coast:
                row.append(COAST)
            elif border:
                row.append(tuple(max(0, c - 70) for c in base))
            else:
                row.append(base)
        pixels.append(row)
    OUT_IMG.mkdir(parents=True, exist_ok=True)
    OUT_DATA.mkdir(parents=True, exist_ok=True)
    write_png(OUT_IMG / f"{map_id}.png", pixels, w, h)

    def px(lonlat: list) -> list:
        x, y = proj.to_px(*lonlat)
        return [round(x), round(y)]

    data = {
        "title": spec["title"],
        "size": [w, h],
        "regions": [{"name": r["name"], "sub": r["sub"], "color": r["color"], "label": px(r["label"])}
                    for r in spec["regions"]],
        "others": [{"name": o["name"], "label": px(o["at"])} for o in spec["others"]],
        "pins": [{"name": p["name"], "note": p["note"], "at": px(p["at"]), "main": p.get("main", False),
                  "side": p.get("side", "right")}  # which side of the pin its name sits on
                 for p in spec["pins"]],
        "credit": "Coastlines: Natural Earth (public domain). Borders approximate.",
    }
    (OUT_DATA / f"{map_id}.json").write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    logger.info("%s: %dx%d map, %d regions, %d pins", map_id, w, h, len(spec["regions"]), len(spec["pins"]))


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    if not LAND.exists():
        logger.error("Missing %s (Natural Earth ne_50m_land.geojson)", LAND)
        return 1
    for map_id in sys.argv[1:] or list(MAPS):
        build(map_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
