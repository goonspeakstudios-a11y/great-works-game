"""Build content/greece/works.json from the Essential-Reading-List Essentials track.

The game follows the Essentials reading list in its own order. The Greek part is
Essentials modules 1-4, starting with Porphyry's Isagoge. Only the "Read" works are
imported (not the survey extras), with their assigned passages and editions, so the
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

# Essentials module -> the kind of game its works become (see docs/greek-game-map.md).
MODULE_STYLES = {
    "e1": "puzzle",              # How to Read and Argue: silent puzzles (The Witness)
    "e2": "story-walk",          # Homer and the Gods: wander and play the key moment (Journey)
    "e3": "hard-choices",        # Tragedy, History, and the City: every option costs (Papers, Please)
    "e4": "thought-experiment",  # Plato and Aristotle: the world obeys the idea (The Stanley Parable)
}


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
    essentials = json.loads((learn / "essentials.json").read_text(encoding="utf-8"))
    sources = json.loads((learn / "sources.json").read_text(encoding="utf-8"))
    by_id = {m["id"]: m for m in essentials["modules"]}
    modules, works = [], []
    for mid, style in MODULE_STYLES.items():
        mod = by_id[mid]
        modules.append({
            "id": mid,
            "title": mod["title"],
            "style": style,
            "intro": mod["intro"],
            "takeaways": mod["takeaways"],
        })
        for entry in mod["readings"]:
            author, title = split_match(entry["match"])
            src = sources["works"].get(entry["match"])
            if src is None:
                logger.warning("No edition in sources.json for %s", entry["match"])
                src = {}
            works.append({
                "id": slug(f"{author} {title}"),
                "author": author,
                "title": title,
                "module": mid,
                "style": style,
                "hours": entry["hours"],
                "read": entry["read"],
                "edition": src.get("ed", ""),
                "match": entry["match"],
            })
    return {
        "source": "essentials",
        "title": "The Greek World",
        "modules": modules,
        "works": works,
    }


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    learn = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_LEARN
    if not (learn / "essentials.json").exists():
        logger.error("essentials.json not found in %s", learn)
        return 1
    data = build(learn)
    OUT.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    logger.info("Wrote %d works in %d modules to %s", len(data["works"]), len(data["modules"]), OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
