"""Dev maps of the city of Rome, for building it up: what is actually built, seen straight down,
against where it should be; and every surface it is built from.

  docs/dev/ortho_<age>.png   the city from above, orthographic, as the game builds it in that age,
                             with the plot's grid (map metres) and monument numbers laid over it
  docs/dev/ortho_forum_<age>.png   the same, close in on the Forum
  docs/dev/ortho_ages.png    all seven ages side by side
  docs/dev/materials.png     every material of the city as a labelled swatch

The captures come from the game itself (hall.gd's --ortho shot mode, under xvfb), so they show the
real buildings, textures and ground. Run with an age list to do fewer:

    python3 tools/dev_maps.py            # everything (about a quarter of an hour)
    python3 tools/dev_maps.py 0 2 6      # those ages only
    python3 tools/dev_maps.py materials  # the material sheet only
"""

import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "docs", "dev")
CITY = json.load(open(os.path.join(ROOT, "content", "rome", "city.json")))
MAP = json.load(open(os.path.join(ROOT, "content", "rome", "republican_rome.json")))
SCALE = float(MAP.get("scale", 0.35))  # world metres a map metre
AGES = [a["id"] for a in CITY["ages"]]
WHEN = [a["when"] for a in CITY["ages"]]

# the captures: name, centre (map metres), span (world metres), pixels
VIEWS = {"city": ([100, 0], 900.0, 2048), "forum": ([60, -40], 260.0, 1536)}


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def world(p):
    return (float(p[0]) * SCALE, -float(p[1]) * SCALE)


def capture(age_i, centre, span, res, path):
    wx, wz = world(centre)
    cmd = ["xvfb-run", "-a", "-s", "-screen 0 1280x720x24", "godot", "--path", ROOT, "--rendering-driver", "opengl3", "--",
           "--shot=%s" % path, "--view=place", "--work=urbs", "--age=%d" % age_i, "--hour=12", "--day=2",
           "--at=%.1f,0,%.1f" % (wx, wz), "--ortho=%.0f" % span, "--res=%d" % res]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=400)
    return os.path.exists(path)


def annotate(path, centre, span, age_i):
    """The plot's grid and monument numbers over the capture: world metres to pixels through the
    camera's centre and span (north is up in the capture, as the camera has no yaw)."""
    img = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    f = font(max(11, img.width // 120))
    ppm = img.width / span  # pixels a world metre
    cx, cz = world(centre)

    def px(map_p):
        x, z = world(map_p)
        return ((x - cx) * ppm + img.width / 2, (z - cz) * ppm + img.height / 2)

    step = 250 if span > 500 else 50
    lo_x = int((centre[0] - span / SCALE / 2) // step) * step
    hi_x = int((centre[0] + span / SCALE / 2) // step + 1) * step
    lo_y = int((centre[1] - span / SCALE / 2) // step) * step
    hi_y = int((centre[1] + span / SCALE / 2) // step + 1) * step
    for x in range(lo_x, hi_x + 1, step):
        xa = px((x, 0))[0]
        d.line([(xa, 0), (xa, img.height)], fill=(255, 255, 255, 90), width=1)
        d.text((xa + 3, 3), str(x), font=f, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    for y in range(lo_y, hi_y + 1, step):
        ya = px((0, y))[1]
        d.line([(0, ya), (img.width, ya)], fill=(255, 255, 255, 90), width=1)
        d.text((3, ya + 2), str(y), font=f, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    year = CITY["ages"][age_i]["year"]
    for n, m in enumerate(CITY["monuments"], 1):
        if year < m["from"] or ("gone" in m and year >= m["gone"]):
            continue
        x, y = px(m["at"])
        if not (0 <= x < img.width and 0 <= y < img.height):
            continue
        ruin = "ruin" in m and year >= m["ruin"]
        col = (255, 220, 60) if not ruin else (200, 200, 200)
        d.ellipse([x - 4, y - 4, x + 4, y + 4], outline=col, width=2)
        d.text((x + 6, y - 7), str(n), font=f, fill=col, stroke_width=2, stroke_fill=(0, 0, 0))
    d.text((10, img.height - f.size - 12), "Rome, %s: as built, from above. Numbers as in docs/rome-plot.png; grid in map metres." % WHEN[age_i],
           font=f, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    img.save(path)


def ortho(ages):
    os.makedirs(OUT, exist_ok=True)
    for age_i in ages:
        for name, (centre, span, res) in VIEWS.items():
            path = os.path.join(OUT, "ortho_%s%s.png" % ("" if name == "city" else name + "_", AGES[age_i]))
            print("capturing", AGES[age_i], name, "...", flush=True)
            if capture(age_i, centre, span, res, path):
                annotate(path, centre, span, age_i)
            else:
                print("  no capture for", AGES[age_i], name)
    sheet = [os.path.join(OUT, "ortho_%s.png" % a) for a in AGES]
    have = [p for p in sheet if os.path.exists(p)]
    if have:
        tiles = [Image.open(p).resize((700, 700)) for p in have]
        cols = min(4, len(tiles))
        rows = (len(tiles) + cols - 1) // cols
        out = Image.new("RGB", (cols * 700, rows * 720), (20, 20, 20))
        f = font(18)
        for k, t in enumerate(tiles):
            out.paste(t, ((k % cols) * 700, (k // cols) * 720 + 20))
            ImageDraw.Draw(out).text(((k % cols) * 700 + 6, (k // cols) * 720 + 2), os.path.basename(have[k]), font=f, fill=(255, 255, 255))
        out.save(os.path.join(OUT, "ortho_ages.png"))


def materials():
    os.makedirs(OUT, exist_ok=True)
    tmp = os.path.join(OUT, "_mat")
    os.makedirs(tmp, exist_ok=True)
    subprocess.run(["godot", "--headless", "--path", ROOT, "--script", "res://tools/material_sheet.gd", "--", "--out=%s" % tmp],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=300)
    files = sorted(f for f in os.listdir(tmp) if f.startswith("mat_") and f.endswith(".png"))
    if not files:
        print("no materials dumped")
        return
    cols = 7
    cell = 256
    rows = (len(files) + cols - 1) // cols
    out = Image.new("RGB", (cols * (cell + 12) + 12, rows * (cell + 30) + 12), (30, 30, 30))
    f = font(16)
    for k, name in enumerate(files):
        img = Image.open(os.path.join(tmp, name)).convert("RGB")
        x = 12 + (k % cols) * (cell + 12)
        y = 12 + (k // cols) * (cell + 30)
        out.paste(img, (x, y))
        ImageDraw.Draw(out).text((x, y + cell + 4), name[4:-4], font=f, fill=(230, 230, 230))
        os.remove(os.path.join(tmp, name))
    os.rmdir(tmp)
    out.save(os.path.join(OUT, "materials.png"))
    print("materials:", len(files))


def main(argv):
    if argv and argv[0] == "materials":
        materials()
        return
    ages = [int(a) for a in argv] if argv else list(range(len(AGES)))
    ortho(ages)
    if not argv:
        materials()


if __name__ == "__main__":
    main(sys.argv[1:])
