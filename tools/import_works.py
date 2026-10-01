"""Build content/greece/works.json and content/rome/works.json from the Essential-Reading-List
Essentials track.

The game follows the Essentials reading list in its own order. The Greek part is
Essentials modules 1-4, starting with Porphyry's Isagoge; the Roman part is module 5 ("Rome:
Duty, Empire, and the Stoics"), after the Rhetorica ad Herennium, which the game moved from
module 1 to Rome (docs/rome-city.md). Only the "Read" works are imported (not the survey
extras), with their assigned passages and editions, so the game never retypes what the reading
list already says. Each Roman book is given the age of the city it belongs to and the zone of
the city its place stands in (docs/rome-thematic-plan.md).

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
OUT_ROME = ROOT / "content" / "rome" / "works.json"

# Essentials module -> the kind of game its works become (see docs/greek-game-map.md).
MODULE_STYLES = {
    "e1": "puzzle",              # How to Read and Argue: silent puzzles (The Witness)
    "e2": "story-walk",          # Homer and the Gods: wander and play the key moment (Journey)
    "e3": "hard-choices",        # Tragedy, History, and the City: every option costs (Papers, Please)
    "e4": "thought-experiment",  # Plato and Aristotle: the world obeys the idea (The Stanley Parable)
}

# The Rhetorica ad Herennium is read in Rome, not on the Shore (docs/rome-city.md), so module 1's
# summary says so and leaves the speech out.
MOVED_TO_ROME = {"1:Rhetorica ad Herennium"}
GREECE_MODULE_NOTES = {
    "e1": {
        "intro": "The classical tools for reading and arguing: definition, the syllogism, the common fallacies, and the "
                 "geometric proof. These are enough to follow the arguments in every later module. (The art of the speech "
                 "itself is learned in Rome, with the Rhetorica ad Herennium.)",
        "takeaways": [
            "Classification comes before argument. Genus, species, and difference are the basis of a definition.",
            "A syllogism is valid because of its form, whatever its content. Fallacies are arguments that only look valid.",
            "Euclid's method of building from axioms became the model of certain knowledge.",
        ],
    },
}

# Rome: the module's works are played in the city of Rome, each in its author's own time and in
# one zone of the city (content/rome/republican_rome.json). The age is the city's age the book
# moves the years on to once it is mastered (content/rome/city.json: heroic 280 BC, republic 50 BC,
# empire AD 150); the Augustans stand with the late Republic, whose city they knew.
ROME_MODULE = "e5"
ROME_STYLE = "exemplum"  # Rome: virtue in public, played as the Romans' own examples
ROME_PLACES = {
    "9:Livy \u2014 The History of Rome": ("heroic", "palatina"),
    "9:Plutarch \u2014 Parallel Lives": ("republic", "campus_martius"),
    "6:Virgil \u2014 The Aeneid": ("republic", "esquilina"),
    "6:Lucretius \u2014 On the Nature of Things": ("republic", "collina"),
    "11:Cicero \u2014 On Duties": ("republic", "palatine_forum"),
    "3:Cicero \u2014 The Dream of Scipio": ("republic", "capitolium"),
    "6:Ovid \u2014 Metamorphoses": ("republic", "trans_tiberim"),
    "9:Tacitus \u2014 Annals": ("empire", "collina"),
    "12:Epictetus \u2014 Enchiridion": ("empire", "suburana"),
    "12:Marcus Aurelius \u2014 Meditations": ("empire", "palatina"),
    "11:Seneca \u2014 Letters to Lucilius": ("empire", "aventinus"),
}
# The Rhetorica ad Herennium, Rome's first book, as the game placed it (not in module 5).
RHETORICA = {
    "module": {"id": "r1", "title": "The Speaker in the Forum", "style": "puzzle",
               "intro": "The Roman art of the speech, as it was taught in the last generation of the Republic: "
                        "the five canons, the parts of a speech, the three styles, and the memory palace.",
               "takeaways": ["Rhetoric has five parts: invention, arrangement, style, memory, and delivery.",
                             "A trained memory is a house of places walked in order, with a striking image set in each."]},
    "work": {"id": "rhetorica-ad-herennium", "author": "", "title": "Rhetorica ad Herennium", "module": "r1",
             "style": "puzzle", "hours": 2,
             "read": "Book I.2-4 (the five canons and the parts of a speech) and Book III.16-24 (the art of memory).",
             "edition": "Tr. Harry Caplan (Loeb Classical Library 403)", "match": "1:Rhetorica ad Herennium",
             "age": "republic", "rome_zone": "palatine_forum"},
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
        if mid in GREECE_MODULE_NOTES:  # the game's own word on what the module now holds
            mod = {**mod, **GREECE_MODULE_NOTES[mid]}
            modules[-1].update(GREECE_MODULE_NOTES[mid])
        for entry in mod["readings"]:
            if entry["match"] in MOVED_TO_ROME:
                continue
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


def build_rome(learn: Path) -> dict:
    """Rome's reading list: the Rhetorica first, then module 5 in the list's own order, each book
    with the age of the city it moves the years on to and the zone its place stands in."""
    essentials = json.loads((learn / "essentials.json").read_text(encoding="utf-8"))
    sources = json.loads((learn / "sources.json").read_text(encoding="utf-8"))
    mod = next(m for m in essentials["modules"] if m["id"] == ROME_MODULE)
    modules = [RHETORICA["module"], {
        "id": mod["id"], "title": mod["title"], "style": ROME_STYLE, "intro": mod["intro"], "takeaways": mod["takeaways"],
    }]
    works = [RHETORICA["work"]]
    for entry in mod["readings"]:
        author, title = split_match(entry["match"])
        src = sources["works"].get(entry["match"])
        if src is None:
            logger.warning("No edition in sources.json for %s", entry["match"])
            src = {}
        if entry["match"] not in ROME_PLACES:
            logger.warning("No age and zone for %s; it stands in the Forum in the Republic", entry["match"])
        age, zone = ROME_PLACES.get(entry["match"], ("republic", "palatine_forum"))
        works.append({
            "id": slug(f"{author} {title}"),
            "author": author,
            "title": title,
            "module": mod["id"],
            "style": ROME_STYLE,
            "hours": entry["hours"],
            "read": entry["read"],
            "edition": src.get("ed", ""),
            "match": entry["match"],
            "age": age,
            "rome_zone": zone,
        })
    return {
        "source": "essentials",
        "title": "The Roman World",
        "note": "Rome's books, in reading order: the Rhetorica, then the Essentials' Rome module. Each stands in a "
                "zone of the city (content/rome/republican_rome.json) and belongs to one of the city's ages "
                "(content/rome/city.json): the city you walk is the age of the latest book you have mastered.",
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
    rome = build_rome(learn)
    OUT_ROME.write_text(json.dumps(rome, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    logger.info("Wrote %d works in %d modules to %s", len(rome["works"]), len(rome["modules"]), OUT_ROME)
    return 0


if __name__ == "__main__":
    sys.exit(main())
