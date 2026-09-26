"""Cuts the game's lettering from the glyph drawings in tools/fonts/ into bitmap fonts
Godot loads directly: assets/fonts/<face>.png (the atlas) and <face>.fnt (BMFont text).
Nothing is downloaded; every letter is drawn by hand in those modules.

  C:\\Python314\\python.exe tools/make_font.py            # cut both faces
  C:\\Python314\\python.exe tools/make_font.py --proof "Porphyry of Tyre"   # print a proof
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fonts import lapidary, scribe  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "assets" / "fonts"
ATLAS_W = 256
FACES = [lapidary, scribe]


def glyph_rows(face, ch: str) -> tuple[int, list[str]]:
    """The drawing for a character, following aliases (small letters in Lapidary)."""
    ch = face.ALIASES.get(ch, ch)
    return face.GLYPHS[ch]


def check(face) -> None:
    for ch, (top, rows) in face.GLYPHS.items():
        widths = {len(r) for r in rows}
        assert len(widths) <= 1, "%s %r: ragged rows %s" % (face.NAME, ch, widths)
        assert top + len(rows) <= face.CELL, "%s %r: runs past the cell" % (face.NAME, ch)
        assert set("".join(rows)) <= {"#", "."}, "%s %r: only # and . allowed" % (face.NAME, ch)


def pack(face) -> tuple[dict, int]:
    """Lays glyphs out in rows of the atlas; returns {char: (x, y, w, h, top)} and the atlas height."""
    places = {}
    x, y, row_h = 0, 0, 0
    for ch, (top, rows) in face.GLYPHS.items():
        w = len(rows[0]) if rows else face.SPACE
        h = len(rows)
        if x + w + 1 > ATLAS_W:
            x, y, row_h = 0, y + row_h + 1, 0
        places[ch] = (x, y, w, h, top)
        x += w + 1
        row_h = max(row_h, h)
    return places, y + row_h + 1


def render(face, places: dict, height: int) -> list[list[tuple[int, int, int, int]]]:
    img = [[(0, 0, 0, 0)] * ATLAS_W for _ in range(height)]
    for ch, (x, y, w, h, top) in places.items():
        for r, row in enumerate(face.GLYPHS[ch][1]):
            for c, px in enumerate(row):
                if px == "#":
                    img[y + r][x + c] = (255, 255, 255, 255)
    return img


def write_png(path: Path, img: list[list[tuple[int, int, int, int]]]) -> None:
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in img)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", ATLAS_W, len(img), 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def write_fnt(path: Path, face, places: dict, height: int) -> None:
    lines = [
        'info face="%s" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0'
        % (face.NAME, face.CELL),
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4"
        % (face.LINE, face.ASCENT, ATLAS_W, height),
        'page id=0 file="%s.png"' % face.NAME.lower(),
    ]
    chars = dict(face.GLYPHS)
    for alias, target in face.ALIASES.items():
        chars[alias] = target
    lines.append("chars count=%d" % len(chars))
    for ch in chars:
        src = face.ALIASES.get(ch, ch)
        x, y, w, h, top = places[src]
        advance = w + face.GAP
        lines.append(
            "char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15"
            % (ord(ch), x, y, w, h, top, advance)
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def proof(face, text: str) -> str:
    """The text as rows of # and . so a face can be judged in the terminal."""
    canvas = [[] for _ in range(face.CELL)]
    for ch in text:
        top, rows = glyph_rows(face, ch)
        w = len(rows[0]) if rows else face.SPACE
        for r in range(face.CELL):
            i = r - top
            canvas[r].append((rows[i] if 0 <= i < len(rows) else "." * w) + "." * face.GAP)
    return "\n".join("".join(row).replace(".", " ") for row in canvas)


def main(argv: list[str]) -> int:
    if len(argv) > 1 and argv[1] == "--proof":
        text = argv[2] if len(argv) > 2 else "Porphyry of Tyre, 270 AD"
        for face in FACES:
            print(face.NAME)
            print(proof(face, text))
            print()
        return 0
    OUT.mkdir(parents=True, exist_ok=True)
    for face in FACES:
        check(face)
        places, height = pack(face)
        write_png(OUT / ("%s.png" % face.NAME.lower()), render(face, places, height))
        write_fnt(OUT / ("%s.fnt" % face.NAME.lower()), face, places, height)
        print("%s: %d glyphs, atlas %dx%d" % (face.NAME, len(places), ATLAS_W, height))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
