"""Build content/greece/works.json from the Essential-Reading-List curriculum.

Pulls the Greek phase (p2) core works, their focus notes and editions so the
game never retypes what the reading list already says.

Usage: C:\\Python314\\python.exe tools/import_works.py [path-to-Essential-Reading-List/learn]
"""
from __future__ import annotations

import json
import logging
import re
import sys
from pathlib import Path

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_LEARN = ROOT.parent / "Essential-Reading-List" / "learn"
OUT = ROOT / "content" / "greece" / "works.json"
PHASE_ID = "p2"


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def split_match(match: str) -> tuple[str, str]:
    """'5:Homer — The Iliad' -> ('Homer', 'The Iliad'); no dash -> ('', title)."""
    title = match.split(":", 1)[1]
    for dash in (" \u2014 ", " - "):
        if dash in title:
            author, work = title.split(dash, 1)
            return author.strip(), work.strip()
    return "", title.strip()


def build(learn: Path) -> dict:
    curriculum = json.loads((learn / "curriculum.json").read_text(encoding="utf-8"))
    sources = json.loads((learn / "sources.json").read_text(encoding="utf-8"))
    phase = next(p for p in curriculum["phases"] if p["id"] == PHASE_ID)
    works = []
    for entry in phase["core"]:
        author, title = split_match(entry["match"])
        src = sources["works"].get(entry["match"], {})
        works.append({
            "id": slug(f"{author} {title}"),
            "author": author,
            "title": title,
            "hours": entry["hours"],
            "focus": entry["focus"],
            "edition": src.get("ed", ""),
            "match": entry["match"],
        })
    return {
        "phase": PHASE_ID,
        "title": phase["title"],
        "span": phase["span"],
        "questions": phase["questions"],
        "works": works,
    }


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    learn = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_LEARN
    if not (learn / "curriculum.json").exists():
        logger.error("curriculum.json not found in %s", learn)
        return 1
    data = build(learn)
    OUT.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    logger.info("Wrote %d works to %s", len(data["works"]), OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
