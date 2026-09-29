"""The ground of ancient Rome as a height map (content/rome/height.json), and its plan
in relief (assets/maps/rome_relief.png), for the city of Rome (scripts/hall/rome_map.gd, the Plan).

The ground is built from the city's real topography, in metres above the sea, on the game's map
(metres east and north of the Forum):
  - the floor of the valleys and the Campus Martius at about 12 m, rising toward the eastern plateau
    (the Esquiline gate stands at about 50 m);
  - the Quirinal, Viminal, Cispius and Oppius as long tongues running south-west off that plateau
    (the Quirinal carries the Alta Semita along its ridge), with the valleys of the Vicus Longus,
    the Vicus Patricius and the Subura between them;
  - the Capitol's two summits (Arx and Capitolium, 46 m) and the saddle between them;
  - the Palatine (51 m), the Velia's saddle joining it to the Oppius, the Caelian (50 m), the
    Greater and Lesser Aventine (47 and 40 m), the Pincian (50 m), the Janiculum (82 m) across the
    river, the Vatican (40 m);
Heights follow the usual figures for the ancient ground (Forum about 12 m, Palatine 51, Quirinal 61,
Viminal 57, Esquiline 58, Capitol 46, Aventine 47, Caelian 50, Janiculum 82), smoothed; the shapes
follow the standard plans (Lanciani, Coarelli) as fitted to Shepherd's plan the city is laid on.

Then every street (content/rome/city.json) is graded into it: its line up and down is smoothed
over some forty metres, the ground under it is set to that line, and the ground either side is
cut and filled to meet it, so the streets run true on the hills and in the valleys.

The river is not in the height map: rome_map.gd lowers the ground to its bed along its course.

Run: python3 tools/make_rome_height.py
"""

import base64
import json
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
CITY = json.load(open(os.path.join(ROOT, "content", "rome", "city.json")))
MAP = json.load(open(os.path.join(ROOT, "content", "rome", "republican_rome.json")))

X0, Y0 = -2240.0, -2500.0  # the map position of the first pixel (west, south)
PX = 8.0  # map metres a pixel
W, H = 645, 630
FLOOR = 12.0  # the Forum's floor, metres above the sea
OFFSET = 20.0  # stored as (height + OFFSET) in centimetres, in two bytes
GRADE_SPAN = 40.0  # metres over which a street's rise is evened out
ROAD_MARGIN = 1.5  # metres either side of a street kept at its level
ROAD_BLEND = 14.0  # metres over which the ground meets the street


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# Hills and ridges: [from, to, radius, falloff, height at from, height at to] (map metres, metres asl).
# A ridge is a capsule: at its full height within `radius` of its axis, falling to the ground below
# over `falloff`; its height runs from one end to the other.
RIDGES = {
    "Quirinal": [[1400, 2000], [-10, 470], 115, 140, 61, 48],
    "Viminal": [[1700, 1350], [430, 600], 95, 130, 57, 46],
    "Cispius": [[1700, 900], [680, 560], 105, 130, 57, 47],
    "Oppius": [[1600, 330], [620, 30], 140, 130, 58, 47],
    "Capitolium": [[-190, 95], [-200, 80], 55, 35, 46, 46],
    "Arx": [[-155, 200], [-165, 185], 45, 35, 46, 46],
    "Asylum": [[-175, 145], [-178, 140], 40, 40, 40, 40],
    "Palatine": [[40, -380], [250, -470], 150, 55, 51, 51],
    "Velia": [[230, -190], [420, -60], 45, 70, 30, 34],
    "Caelian": [[640, -580], [1700, -720], 170, 110, 50, 56],
    "Greater Aventine": [[-380, -960], [-200, -1030], 150, 60, 47, 47],
    "Lesser Aventine": [[80, -1030], [260, -1120], 140, 90, 40, 40],
    "Pincian": [[-250, 1850], [200, 2000], 220, 150, 50, 52],
    "Janiculum": [[-1480, 400], [-1650, -950], 260, 220, 82, 75],
    "Vatican": [[-2300, 1300], [-2600, 1100], 300, 250, 40, 40],
}


def ridge(xs, ys, base, r):
    (ax, ay), (bx, by), rad, fall, ha, hb = r
    abx, aby = bx - ax, by - ay
    length2 = max(abx * abx + aby * aby, 1e-6)
    t = np.clip(((xs - ax) * abx + (ys - ay) * aby) / length2, 0.0, 1.0)
    d = np.hypot(xs - (ax + t * abx), ys - (ay + t * aby))
    top = ha + (hb - ha) * t
    f = 1.0 - smoothstep(rad, rad + fall, d)
    return base + (top - base) * f


def terrain():
    xs = X0 + np.arange(W) * PX
    ys = Y0 + np.arange(H) * PX
    gx, gy = np.meshgrid(xs, ys)
    # the valleys' floor, rising toward the eastern plateau the long hills run off
    base = FLOOR + 45.0 * smoothstep(250.0, 1500.0, 0.8 * gx + 0.35 * gy)
    h = base.copy()
    # the hills' edges wander: spurs, coves and gullies, not smooth outlines
    warp = np.random.default_rng(509)
    def field(cells, amp):
        coarse = warp.standard_normal((cells, cells)).astype(np.float32)
        return amp * np.asarray(Image.fromarray(coarse, "F").resize((W, H), Image.BICUBIC))
    wx = gx + field(9, 38.0) + field(26, 12.0)
    wy = gy + field(9, 38.0) + field(26, 12.0)
    for r in RIDGES.values():
        k = min(1.0, r[2] / 160.0)  # small hills wander less
        h = np.maximum(h, ridge(gx + (wx - gx) * k, gy + (wy - gy) * k, base, r))
    # the ground is never quite even: slow swells of a metre or two, and smaller ones on top
    rng = np.random.default_rng(753)
    for cells, amp in ((12, 1.6), (40, 0.5)):
        coarse = rng.standard_normal((cells, cells)).astype(np.float32)
        swell = np.asarray(Image.fromarray(coarse, "F").resize((W, H), Image.BICUBIC))
        h = h + amp * swell * np.clip((h - FLOOR + 2.0) / 4.0, 0.3, 1.0)
    return h, gx, gy


def sample(h, x, y):
    """The height at a map position, bilinearly."""
    fx = (x - X0) / PX
    fy = (y - Y0) / PX
    i = int(np.clip(np.floor(fx), 0, W - 2))
    j = int(np.clip(np.floor(fy), 0, H - 2))
    tx, ty = fx - i, fy - j
    a = h[j, i] * (1 - tx) + h[j, i + 1] * tx
    b = h[j + 1, i] * (1 - tx) + h[j + 1, i + 1] * tx
    return a * (1 - ty) + b * ty


def grade(h, gx, gy):
    """Every street's line, evened out, and the ground cut and filled to meet it."""
    best_d = np.full(h.shape, np.inf)
    target = np.zeros(h.shape)
    half = np.zeros(h.shape)
    for road in CITY["roads"]:
        pts = [np.array(p, dtype=float) for p in road["points"]]
        dense = []
        for a, b in zip(pts[:-1], pts[1:]):
            n = max(1, int(np.linalg.norm(b - a) / 4.0))
            for k in range(n):
                dense.append(a + (b - a) * k / n)
        dense.append(pts[-1])
        dense = np.array(dense)
        seg = np.linalg.norm(np.diff(dense, axis=0), axis=1)
        along = np.concatenate([[0.0], np.cumsum(seg)])
        raw = np.array([sample(h, x, y) for x, y in dense])
        prof = np.empty_like(raw)
        for k in range(len(raw)):
            w = np.exp(-0.5 * ((along - along[k]) / (GRADE_SPAN / 2.0)) ** 2)
            prof[k] = np.sum(w * raw) / np.sum(w)
        hw = float(road["width"]) / 2.0 / float(MAP.get("scale", 0.35))  # the street is laid `width` world metres wide
        reach = hw + ROAD_MARGIN + ROAD_BLEND
        for k in range(len(dense) - 1):
            ax, ay = dense[k]
            bx, by = dense[k + 1]
            x0, x1 = min(ax, bx) - reach, max(ax, bx) + reach
            y0, y1 = min(ay, by) - reach, max(ay, by) + reach
            i0, i1 = max(0, int((x0 - X0) / PX)), min(W, int((x1 - X0) / PX) + 2)
            j0, j1 = max(0, int((y0 - Y0) / PX)), min(H, int((y1 - Y0) / PX) + 2)
            if i0 >= i1 or j0 >= j1:
                continue
            sx = gx[j0:j1, i0:i1]
            sy = gy[j0:j1, i0:i1]
            abx, aby = bx - ax, by - ay
            l2 = max(abx * abx + aby * aby, 1e-6)
            t = np.clip(((sx - ax) * abx + (sy - ay) * aby) / l2, 0.0, 1.0)
            d = np.hypot(sx - (ax + t * abx), sy - (ay + t * aby))
            level = prof[k] + (prof[k + 1] - prof[k]) * t
            view = best_d[j0:j1, i0:i1]
            closer = d < view
            view[closer] = d[closer]
            target[j0:j1, i0:i1][closer] = level[closer]
            half[j0:j1, i0:i1][closer] = hw
    near = np.isfinite(best_d)
    w = np.zeros(h.shape)
    w[near] = 1.0 - smoothstep(half[near] + ROAD_MARGIN, half[near] + ROAD_MARGIN + ROAD_BLEND, best_d[near])
    return h * (1.0 - w) + target * w


# How far round each kind of monument the ground is levelled (world metres at size 1, as rome_map.gd's
# FOOTPRINT), and the scale of the map (world metres a map metre).
FOOTPRINT = {"temple": 16.0, "double_temple": 42.0, "round_temple": 8.0, "hall": 10.0, "curia": 14.0,
             "basilica": 30.0, "vaulted_hall": 32.0, "rostra": 8.0, "shrine": 5.0, "arch": 10.0, "column": 5.0, "markets": 36.0,
             "amphitheatre": 100.0, "colossus": 6.0, "fountain_cone": 9.0, "ludus": 24.0, "baths": 70.0, "palace": 62.0,
             "houses": 50.0, "circus": 118.0, "obelisk": 4.0, "open_circus": 55.0, "theatre": 42.0, "pantheon": 30.0,
             "stadium": 52.0, "altar": 10.0, "mausoleum": 30.0, "church": 50.0, "forum": 30.0, "tabularium": 30.0}
SCALE = float(MAP.get("scale", 0.35))
HOUSE = json.load(open(os.path.join(ROOT, "content", "rome", "activities.json")))["room"] \
    if os.path.exists(os.path.join(ROOT, "content", "rome", "activities.json")) else {"at": [507, 409], "toward": [523, 368]}


def pad(h, gx, gy, at, r, level, blend=20.0):
    """Levels the ground to `level` within `r` map metres of `at`, meeting the ground round it over `blend`."""
    d = np.hypot(gx - at[0], gy - at[1])
    w = 1.0 - smoothstep(r, r + blend, d)
    return h * (1.0 - w) + level * w


def pads(h, gx, gy):
    """The ground levelled under every monument, at the height of its middle."""
    for m in CITY["monuments"]:
        if m["kind"] in ("circus", "forum", "houses", "open_circus"):
            continue  # set in their valleys already, or too large to level
        r = FOOTPRINT.get(m["kind"], 16.0) * float(m.get("size", 1.0)) / SCALE * 0.6
        h = pad(h, gx, gy, m["at"], r, sample(h, *m["at"]))
    return h


def relief(h, graded_roads):
    """The plan's ground: parchment darkening with height, shaded from the north-west, contours every 5 m."""
    gy, gx = np.gradient(h, PX)
    # light from the north-west, high: north is up the image (the image is flipped so north is at the top)
    lx, ly, lz = -0.6, 0.6, 1.0
    n = np.sqrt(gx * gx + gy * gy + 1.0)
    shade = (-gx * lx - gy * ly + lz) / (n * np.sqrt(lx * lx + ly * ly + lz * lz))
    shade = np.clip(shade, 0.0, 1.0)
    t = np.clip((h - FLOOR) / 60.0, 0.0, 1.0)
    low = np.array([216, 200, 160], dtype=float)
    high = np.array([176, 150, 112], dtype=float)
    col = low[None, None, :] * (1 - t[..., None]) + high[None, None, :] * t[..., None]
    col *= (0.72 + 0.4 * shade)[..., None]
    band = np.floor(h / 5.0)
    edge = (np.abs(np.diff(band, axis=0, prepend=band[:1])) > 0) | (np.abs(np.diff(band, axis=1, prepend=band[:, :1])) > 0)
    col[edge] = col[edge] * 0.75
    img = np.clip(col, 0, 255).astype(np.uint8)[::-1]  # north up
    return Image.fromarray(img, "RGB")


def main():
    h, gx, gy = terrain()
    h = pads(h, gx, gy)
    h = grade(h, gx, gy)
    # your house, cut into the hillside at the level of the street before it
    street = sample(h, *HOUSE["toward"])
    h = pad(h, gx, gy, HOUSE["at"], 44.0, street, 16.0)
    v = np.clip(np.round((h + OFFSET) * 100.0), 0, 65535).astype("<u2")
    json.dump({"about": "The ground of Rome in metres above the sea (tools/make_rome_height.py): cell (i, j) is map position "
                        "(x0 + i*px, y0 + j*px); `data` is base64 of w*h little-endian uint16, row by row from the south: "
                        "height = value / 100 - offset.",
               "x0": X0, "y0": Y0, "px": PX, "w": W, "h": H, "offset": OFFSET, "floor": FLOOR,
               "data": base64.b64encode(v.tobytes()).decode("ascii")},
              open(os.path.join(ROOT, "content", "rome", "height.json"), "w"))
    relief(h, None).save(os.path.join(ROOT, "assets", "maps", "rome_relief.png"))
    for name, (x, y) in {"Forum": (0, 10), "Palatine": (144, -431), "Capitol": (-190, 90), "Quirinal (Alta Semita)": (500, 1000),
                         "Subura (Argiletum)": (300, 280), "your house": (507, 409), "Esquiline gate": (1310, 490),
                         "Circus": (41, -701), "Colosseum": (580, -222), "Campus Martius": (-800, 650),
                         "Aventine (Diana)": (-431, -955), "Janiculum": (-1550, -300)}.items():
        print("%-24s %5.1f m" % (name, sample(h, x, y)))


if __name__ == "__main__":
    main()
