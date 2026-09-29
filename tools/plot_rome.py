"""A plot of the city of Rome as the game lays it out, for checking where everything stands:
docs/rome-plot.png and docs/rome-plot.csv.

On the relief of the ground (assets/maps/rome_relief.png, from the height map) it draws, north up,
in map metres east and north of the Forum with a grid every 250 m to read positions off:
  the Tiber and the island; the Servian wall (its gates joined) and the line of Aurelian's;
  every street, named; the bridges and the aqueducts;
  every monument in city.json as a square of about its footprint, numbered, coloured by kind;
  your house, and the regulars' places.
The index down the right side (and the csv) gives, for each number: the name, kind, map position,
the ground's height there in metres above the sea, and the years it stands (from, ruin, gone).

The height map is a reconstruction from the standard figures for the ancient ground and the
usual plans, not a survey: good for slopes and for which street runs where, not for centimetres.

Run: python3 tools/plot_rome.py
"""

import base64
import csv
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
CITY = json.load(open(os.path.join(ROOT, "content", "rome", "city.json")))
MAP = json.load(open(os.path.join(ROOT, "content", "rome", "republican_rome.json")))
HEIGHT = json.load(open(os.path.join(ROOT, "content", "rome", "height.json")))
TOWN = json.load(open(os.path.join(ROOT, "content", "rome", "town.json")))
ACTS = json.load(open(os.path.join(ROOT, "content", "rome", "activities.json")))

SCALE = float(MAP.get("scale", 0.35))  # world metres a map metre
FOOTPRINT = {"temple": 16.0, "double_temple": 42.0, "round_temple": 8.0, "hall": 10.0, "curia": 14.0,
             "basilica": 30.0, "vaulted_hall": 32.0, "rostra": 8.0, "shrine": 5.0, "arch": 10.0, "column": 5.0, "markets": 36.0,
             "amphitheatre": 100.0, "colossus": 6.0, "fountain_cone": 9.0, "ludus": 24.0, "baths": 70.0, "palace": 62.0,
             "houses": 50.0, "circus": 118.0, "obelisk": 4.0, "open_circus": 55.0, "theatre": 42.0, "pantheon": 30.0,
             "stadium": 52.0, "altar": 10.0, "mausoleum": 30.0, "church": 50.0, "forum": 30.0, "tabularium": 30.0}
COLOURS = {  # by what a thing is for
    "sacred": (170, 30, 30), "civic": (40, 70, 150), "shows": (120, 40, 140), "baths": (30, 120, 90),
    "imperial": (200, 110, 20), "church": (180, 140, 20), "tomb": (80, 80, 80), "other": (60, 60, 60),
}
KIND_GROUP = {
    "temple": "sacred", "double_temple": "sacred", "round_temple": "sacred", "shrine": "sacred", "altar": "sacred",
    "pantheon": "sacred",
    "hall": "civic", "curia": "civic", "basilica": "civic", "rostra": "civic", "tabularium": "civic", "vaulted_hall": "civic",
    "markets": "civic", "forum": "imperial", "arch": "imperial", "column": "imperial", "colossus": "imperial", "obelisk": "imperial",
    "palace": "imperial", "houses": "other", "fountain_cone": "other",
    "amphitheatre": "shows", "ludus": "shows", "circus": "shows", "open_circus": "shows", "theatre": "shows", "stadium": "shows",
    "baths": "baths", "church": "church", "mausoleum": "tomb",
}

# the plotted area, map metres
X0, X1 = -2000, 2700
Y0, Y1 = -2200, 2300
PPM = 0.5  # pixels a map metre
LEGEND_W = 760
W = int((X1 - X0) * PPM)
H = int((Y1 - Y0) * PPM)


def px(p):
    return ((float(p[0]) - X0) * PPM, (Y1 - float(p[1])) * PPM)


def heights():
    raw = base64.b64decode(HEIGHT["data"])
    v = np.frombuffer(raw, dtype="<u2").astype(np.float64).reshape(HEIGHT["h"], HEIGHT["w"])
    return v / 100.0 - float(HEIGHT["offset"])


HM = heights()


def height_at(x, y):
    fx = (x - HEIGHT["x0"]) / HEIGHT["px"]
    fy = (y - HEIGHT["y0"]) / HEIGHT["px"]
    i = int(np.clip(np.floor(fx), 0, HEIGHT["w"] - 2))
    j = int(np.clip(np.floor(fy), 0, HEIGHT["h"] - 2))
    tx, ty = fx - i, fy - j
    a = HM[j, i] * (1 - tx) + HM[j, i + 1] * tx
    b = HM[j + 1, i] * (1 - tx) + HM[j + 1, i + 1] * tx
    return a * (1 - ty) + b * ty


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def relief_background():
    img = Image.open(os.path.join(ROOT, "assets", "maps", "rome_relief.png")).convert("RGB")
    hx0, hy0, hpx = HEIGHT["x0"], HEIGHT["y0"], HEIGHT["px"]
    hw, hh = HEIGHT["w"], HEIGHT["h"]
    # the relief is north up: its top row is y = hy0 + (hh - 1) * hpx
    top = hy0 + (hh - 1) * hpx
    left = hx0
    canvas = Image.new("RGB", (W, H), (222, 208, 172))
    scaled = img.resize((int(hw * hpx * PPM), int(hh * hpx * PPM)), Image.BILINEAR)
    canvas.paste(scaled, (int((left - X0) * PPM), int((Y1 - top) * PPM)))
    return canvas


def draw_text_along(d, a, b, text, f, fill):
    """Text laid along a segment: rotated onto a small layer and pasted."""
    (ax, ay), (bx, by) = a, b
    ang = np.degrees(np.arctan2(-(by - ay), bx - ax))
    if ang > 90 or ang < -90:
        ang += 180
    tw = int(d.textlength(text, font=f)) + 8
    th = f.size + 6
    layer = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((4, 2), text, font=f, fill=fill)
    layer = layer.rotate(ang, expand=True, resample=Image.BICUBIC)
    mx, my = (ax + bx) / 2, (ay + by) / 2
    return layer, (int(mx - layer.width / 2), int(my - layer.height / 2))


def main():
    img = relief_background()
    d = ImageDraw.Draw(img, "RGBA")
    f_small = font(12)
    f_label = font(14)
    f_num = font(11)
    f_big = font(20)

    # the grid, every 250 m
    for x in range(int(np.ceil(X0 / 250)) * 250, X1 + 1, 250):
        xa = px((x, 0))[0]
        d.line([(xa, 0), (xa, H)], fill=(90, 80, 60, 70 if x % 500 else 130), width=1)
        d.text((xa + 3, 3), str(x), font=f_small, fill=(70, 60, 40))
        d.text((xa + 3, H - 16), str(x), font=f_small, fill=(70, 60, 40))
    for y in range(int(np.ceil(Y0 / 250)) * 250, Y1 + 1, 250):
        ya = px((0, y))[1]
        d.line([(0, ya), (W, ya)], fill=(90, 80, 60, 70 if y % 500 else 130), width=1)
        d.text((3, ya + 2), str(y), font=f_small, fill=(70, 60, 40))
        d.text((W - 40, ya + 2), str(y), font=f_small, fill=(70, 60, 40))

    # the river and the island
    tiber = MAP["tiber"]
    d.line([px(p) for p in tiber["course"]], fill=(90, 120, 160), width=int(tiber["width"] * PPM), joint="curve")
    isle = tiber["island"]
    cx, cy = px(isle["at"])
    r = isle["radius"] * PPM * 0.6
    d.ellipse([cx - r * 1.8, cy - r, cx + r * 1.8, cy + r], fill=(210, 196, 160), outline=(120, 100, 70))

    # the walls: the Servian (its gates joined), Aurelian's line
    gates = MAP["wall"]["gates"]
    d.polygon([px(g["at"]) for g in gates], outline=(60, 40, 20))
    d.line([px(g["at"]) for g in gates] + [px(gates[0]["at"])], fill=(60, 40, 20), width=3)
    for g in gates:
        x, y = px(g["at"])
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(60, 40, 20))
        d.text((x + 6, y - 6), g["name"], font=f_small, fill=(60, 40, 20))
    walk = CITY.get("walkable", [])
    pts = [px(p) for p in walk] + [px(walk[0])]
    for k in range(len(pts) - 1):  # dashed
        (ax, ay), (bx, by) = pts[k], pts[k + 1]
        n = max(1, int(np.hypot(bx - ax, by - ay) / 14))
        for i in range(0, n, 2):
            d.line([(ax + (bx - ax) * i / n, ay + (by - ay) * i / n), (ax + (bx - ax) * (i + 1) / n, ay + (by - ay) * (i + 1) / n)],
                   fill=(50, 50, 90), width=2)

    # the aqueducts and the bridges
    for a in CITY.get("aqueducts", []):
        d.line([px(a["from"]), px(a["to"])], fill=(120, 90, 160), width=3)
        d.text(px(a["to"]), a.get("name", "aqueduct") + " (%d)" % a["year"], font=f_small, fill=(100, 70, 140))
    for b in CITY.get("bridges", []):
        x, y = px(b["at"])
        d.line([(x - 16, y), (x + 16, y)], fill=(40, 30, 20), width=4)
        d.text((x + 18, y - 7), "%s (%d)" % (b["name"], b["from"]), font=f_small, fill=(40, 30, 20))

    # the streets, named
    overlays = []
    for road in CITY["roads"]:
        pts = [px(p) for p in road["points"]]
        d.line(pts, fill=(70, 40, 20), width=max(2, int(road["width"] * PPM / SCALE * 0.5)), joint="curve")
        best = max(range(len(pts) - 1), key=lambda i: np.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]))
        overlays.append(draw_text_along(d, pts[best], pts[best + 1], road["name"], f_label, (60, 30, 10, 255)))

    # the monuments, numbered
    rows = []
    for n, m in enumerate(CITY["monuments"], 1):
        x, y = px(m["at"])
        fp = FOOTPRINT.get(m["kind"], 16.0) * float(m.get("size", 1.0)) / SCALE * PPM  # map metres, then pixels
        r = max(4.0, fp / 2.0)
        col = COLOURS[KIND_GROUP.get(m["kind"], "other")]
        d.rectangle([x - r, y - r, x + r, y + r], outline=col, width=2, fill=col + (70,))
        d.text((x + r + 2, y - r - 2), str(n), font=f_num, fill=col)
        h = height_at(*m["at"])
        rows.append([n, m["id"], m["name"], m["kind"], m["at"][0], m["at"][1], round(h, 1), m["from"], m.get("ruin", ""),
                     m.get("gone", ""), "yes" if m.get("note") else ""])

    # your house and the regulars
    hx, hy = px(ACTS["room"]["at"])
    d.rectangle([hx - 7, hy - 7, hx + 7, hy + 7], fill=(220, 170, 40), outline=(60, 40, 10), width=2)
    d.text((hx + 10, hy - 8), "your house (%.0f m)" % height_at(*ACTS["room"]["at"]), font=f_label, fill=(80, 50, 10))
    for reg in TOWN.get("regulars", []):
        x, y = px(reg["at"])
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(30, 70, 160))
        d.text((x + 6, y - 7), reg["id"], font=f_small, fill=(30, 70, 160))

    for layer, at in overlays:
        img.paste(layer, at, layer)

    # the legend
    out = Image.new("RGB", (W + LEGEND_W, H), (245, 240, 228))
    out.paste(img, (0, 0))
    d = ImageDraw.Draw(out)
    d.text((W + 16, 10), "Rome as the game lays it out: every structure, numbered", font=f_big, fill=(40, 30, 20))
    d.text((W + 16, 36), "map metres east, north of the Forum; heights in metres above the sea, from the height map",
           font=f_small, fill=(90, 80, 60))
    y = 60
    for k, colname in [("sacred", "temples, shrines, altars"), ("civic", "the Forum's halls, basilicas, markets"),
                       ("imperial", "imperial fora, arches, columns, palace"), ("shows", "circus, theatres, amphitheatre, baths' rivals"),
                       ("baths", "baths"), ("church", "churches"), ("tomb", "tombs")]:
        d.rectangle([W + 16, y, W + 30, y + 12], fill=COLOURS[k])
        d.text((W + 36, y - 2), colname, font=f_small, fill=(60, 50, 40))
        y += 16
    y += 8
    col_w = (LEGEND_W - 24) // 2
    line_h = 13
    per_col = (H - y - 10) // line_h
    for i, row in enumerate(rows):
        cx = W + 12 + (i // per_col) * col_w
        cy = y + (i % per_col) * line_h
        n, mid, name, kind, mx, my, h, fr, ru, go, note = row
        years = "%d" % fr + (", ruin %s" % ru if ru != "" else "") + (", gone %s" % go if go != "" else "")
        text = "%2d %s  [%d, %d] %.0f m  %s%s" % (n, name.replace("the ", "", 1), mx, my, h, years, "" if note else "  (no story)")
        d.text((cx, cy), text[:86], font=f_num, fill=COLOURS[KIND_GROUP.get(kind, "other")])

    out.save(os.path.join(ROOT, "docs", "rome-plot.png"))
    with open(os.path.join(ROOT, "docs", "rome-plot.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["n", "id", "name", "kind", "east_m", "north_m", "height_m_asl", "from", "ruin", "gone", "has_note"])
        w.writerows(rows)
    print("%d structures plotted; %d without a story" % (len(rows), sum(1 for r in rows if not r[-1])))


if __name__ == "__main__":
    main()
