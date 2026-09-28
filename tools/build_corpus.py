"""Turn book files from Desktop\\Book Collections (or public-domain texts online) into searchable
passages for the Hall.

Each book becomes content/books/<work-id>.json: a list of short passages (about 200
words, split on paragraph edges) labelled with their chapter, so an author can quote
the real text. Only public-domain translations are used. A book can come from a file in the
library ("file") or from the web ("urls": [[url, heading], ...]); downloads are kept in
tools/data/books/ so a rebuild gives the same passages.

Usage: C:\\Python314\\python.exe tools/build_corpus.py [work-id ...]
"""
from __future__ import annotations

import json
import logging
import re
import sys
import time
import urllib.error
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
# BB1's book library lives on the E: drive; the Desktop copy is the fallback
LIBRARY = next((p for p in (Path("E:/Book Collections"), Path.home() / "Desktop" / "Book Collections") if p.exists()),
               Path("E:/Book Collections"))
OUT = ROOT / "content" / "books"
CACHE = ROOT / "tools" / "data" / "books"
TARGET_WORDS = 200
MAX_WORDS = 380

BOOKS = {
    "porphyry-isagoge": {
        "file": "Porphyry - Isagoge (tr. Owen 1853).html",
        "title": "Isagoge",
        "translation": "tr. Octavius Freire Owen (1853), public domain",
        "encoding": "cp1252",
        "start": r"INTRODUCTION OF PORPHYRY",
        "end": r"\[This translation appears",  # a transcriber's note, then footnotes
        "chapter": r"^\s*Chap\.\s*([IVXL]+)\.",
    },
    "aristotle-categories": {
        "file": "Aristotle - Categories (tr. Edghill).txt",
        "title": "Categories",
        "translation": "tr. E. M. Edghill (1928), public domain",
        "start": r"SECTION 1",
        "end": r"THE END",
        "chapter": r"^\s*Part (\d+)\s*$",
    },
    "aristotle-the-rest-of-the-organon": {  # two books in one corpus, each passage labelled with its own
        "title": "the Organon",
        "translation": "Prior Analytics tr. A. J. Jenkinson, Sophistical Refutations tr. W. A. Pickard-Cambridge, public domain",
        "parts": [
            {"file": "Aristotle - Prior Analytics (tr. Jenkinson).txt", "title": "Prior Analytics",
             "start": r"BOOK I", "end": r"THE END", "chapter": r"^\s*Part (\d+)\s*$", "book": r"^\s*BOOK ([IVX]+)\s*$"},
            {"file": "Aristotle - Sophistical Refutations (tr. Pickard-Cambridge).txt", "title": "Sophistical Refutations",
             "start": r"SECTION 1", "end": r"THE END", "chapter": r"^\s*Part (\d+)\s*$"},
        ],
    },
    "rhetorica-ad-herennium": {  # no English translation is out of copyright, so the Latin itself
        "title": "Rhetorica ad Herennium",
        "translation": "the Latin text, ed. F. Marx (Teubner, 1923), public domain",
        "wiki": True,
        "urls": [[f"https://la.wikisource.org/w/index.php?title=Rhetorica_ad_Herennium/Liber_{n}&action=raw", f"LIBER {n}"]
                 for n in ("I", "II", "III", "IV")],
        "start": r"LIBER I",
        "end": r"\Z",
        "chapter": r"^\s*==\s*(\d+)\s*==\s*$",
        "book": r"^\s*LIBER ([IV]+)\s*$",
    },
    "euclid-elements": {  # Heath's Book I from the scan of his first volume, without his notes
        "title": "Elements, Book I",
        "translation": "tr. T. L. Heath (1908), public domain",
        "urls": [["https://archive.org/download/thirteenbookseu02heibgoog/thirteenbookseu02heibgoog_djvu.txt", ""]],
        "segments": [
            {"start": r"^DEFINITIONS\.\s*$", "end": r"The whole is greater than the part", "heading": "FIRST PRINCIPLES", "once": True,
             "skip_start": False},
            {"start": r"^Proposition ([0-9ilIoO]{1,3})[\.,]\s*$",
             "end": r"required to (do|prove)\.|^Therefore etc\.|Q\. ?E\. ?[DF]\.",
             "heading": "PROPOSITION {n}", "skip_start": True, "max": 3200},
        ],
        "drop": [r"^.{0,3}$", r"^H\. E\. \d+.*$", r"^BOOK I \[.*$", r"^\[\d+\]\s*", r"^B\(X\)K I.*$"],
        "start": r"FIRST PRINCIPLES",
        "end": r"\Z",
        "chapter": r"^\s*(?:PROPOSITION|FIRST) (\d+|PRINCIPLES)\s*$",
        "chapter_label": "Prop.",
        "chapter_names": {"PRINCIPLES": "Definitions, Postulates, Common Notions"},
    },
    "homer-the-iliad": {  # both poems, as the reading takes both
        "title": "Homer",
        "translation": "tr. Samuel Butler (Iliad 1898, Odyssey 1900), public domain",
        "parts": [
            {"title": "The Iliad", "urls": [["https://www.gutenberg.org/cache/epub/2199/pg2199.txt", ""]],
             "start": r"(?m)^\s*BOOK I\.\s*$(?![\s\S]{0,200}BOOK II\.)", "end": r"\*\*\* ?END OF", "chapter": r"^\s*BOOK ([IVXL]+)\.\s*$",
             "chapter_label": "Book"},
            {"title": "The Odyssey", "urls": [["https://www.gutenberg.org/cache/epub/1727/pg1727.txt", ""]],
             "start": r"(?m)^\s*BOOK I\s*$(?![\s\S]{0,200}BOOK II\s*$)", "end": r"\*\*\* ?END OF", "chapter": r"^\s*BOOK ([IVXL]+)\.?\s*$",
             "chapter_label": "Book"},
        ],
    },
    "hesiod-theogony": {  # the Theogony and the Works and Days, as the reading takes both
        "title": "Hesiod",
        "translation": "tr. Hugh G. Evelyn-White (1914), public domain",
        "parts": [
            {"title": "Theogony", "urls": [["https://www.gutenberg.org/cache/epub/348/pg348.txt", ""]],
             "segments": [{"start": r"^THE THEOGONY\s*\n\s*\n\(ll\. 1-25\)", "end": r"(?=^THE CATALOGUES OF WOMEN)", "heading": "",
                           "once": True}],
             "drop": [r"(?<=[A-Za-z,;:’?])\s1\d{3}\b"],  # the footnote marks
             "start": r"\(ll\. 1-25\)", "end": r"\Zx", "chapter": r"^\(ll\. (\d+)-?\d*\)", "chapter_label": "line"},
            {"title": "Works and Days", "urls": [["https://www.gutenberg.org/cache/epub/348/pg348.txt", ""]],
             "segments": [{"start": r"^HESIOD’S WORKS AND DAYS\s*\n\s*\n\(ll\. 1-10\)", "end": r"(?=^THE THEOGONY\s*$)",
                           "heading": "", "once": True}],
             "drop": [r"(?<=[A-Za-z,;:’?])\s1\d{3}\b"],  # the footnote marks
             "start": r"\(ll\. 1-10\)", "end": r"\Zx", "chapter": r"^\(ll\. (\d+)-?\d*\)", "chapter_label": "line"},
        ],
    },
    "sappho-fragments": {  # Wharton's literal prose of each fragment, without the Greek or the verse renderings
        "title": "Sappho",
        "translation": "tr. Henry Thornton Wharton (1885), literal prose, public domain",
        "urls": [["https://www.gutenberg.org/cache/epub/57390/pg57390.txt", ""]],
        "segments": [{"start": r"^(\d+)(?:, ?\d+)*[ \t]*$", "end": r"^_\S.*?_[ \t.]{0,5}$", "max": 6000, "heading": "Fragment {n}",
                      "keep_last": True}],
        "drop": [r"^.*\[Greek:.*$", r"_"],
        "start": r"(?m)^Fragment 1\s*$", "end": r"\Zx", "chapter": r"^Fragment (\d+)\s*$", "chapter_label": "Fragment",
    },
    "aeschylus-the-oresteia": {  # the first and last plays of the trilogy, as the reading takes them
        "title": "Aeschylus",
        "translation": "tr. E. D. A. Morshead (1881), public domain",
        "parts": [
            {"title": "Agamemnon", "urls": [["https://www.gutenberg.org/cache/epub/8604/pg8604.txt", ""]],
             "start": r"(?m)^_A Watchman_\s*$", "end": r"(?m)^THE LIBATION-BEARERS\s*$", "chapter": r"^\Zx", "drop": [r"_"]},
            {"title": "The Eumenides", "urls": [["https://www.gutenberg.org/cache/epub/8604/pg8604.txt", ""]],
             "start": r"(?m)^_The Temple at Delphi_\s*$", "end": r"\*\*\* ?END OF", "chapter": r"^\Zx", "drop": [r"_"]},
        ],
    },
    "sophocles-the-theban-plays": {  # Oedipus the King and Antigone, as the reading takes them
        "title": "Sophocles",
        "translation": "tr. Francis Storr (1912), public domain",
        "parts": [
            {"title": "Oedipus the King", "urls": [["https://www.gutenberg.org/cache/epub/31/pg31.txt", ""]],
             "start": r"(?m)^Suppliants of all ages are seated round the altar", "end": r"(?m)^OEDIPUS AT COLONUS\s*$", "chapter": r"^\Zx"},
            {"title": "Antigone", "urls": [["https://www.gutenberg.org/cache/epub/31/pg31.txt", ""]],
             "start": r"(?m)^\s*ANTIGONE and ISMENE before the Palace gates", "end": r"\*\*\* ?END OF", "chapter": r"^\Zx"},
        ],
    },
    "plato-republic": {  # the Republic, with the Apology, the Symposium and the Phaedo the reading adds
        "title": "Plato",
        "translation": "tr. Benjamin Jowett (1871-1892), public domain",
        "parts": [
            {"title": "Republic", "urls": [["https://www.gutenberg.org/cache/epub/1497/pg1497.txt", ""]],
             "start": r"(?m)^ *PERSONS OF THE DIALOGUE\.\s*\n\s*\n\s*Socrates, who is the narrator", "end": r"\*\*\* ?END OF",
             "chapter": r"^\s*BOOK ([IVX]+)\.\s*$", "chapter_label": "Book"},
            {"title": "Apology", "urls": [["https://www.gutenberg.org/cache/epub/1656/pg1656.txt", ""]],
             "start": r"How you, O Athenians, have been affected", "end": r"\*\*\* ?END OF", "chapter": r"^\Zx"},
            {"title": "Symposium", "urls": [["https://www.gutenberg.org/cache/epub/1600/pg1600.txt", ""]],
             "start": r"PERSONS OF THE DIALOGUE: Apollodorus", "end": r"\*\*\* ?END OF", "chapter": r"^\Zx"},
            {"title": "Phaedo", "urls": [["https://www.gutenberg.org/cache/epub/1658/pg1658.txt", ""]],
             "start": r"PERSONS OF THE DIALOGUE:\s*\n\s*\nPhaedo, who is the narrator", "end": r"\*\*\* ?END OF", "chapter": r"^\Zx"},
        ],
    },
    "aristotle-nicomachean-ethics": {
        "file": "Aristotle - Nicomachean Ethics (tr. Chase).txt",
        "title": "Nicomachean Ethics",
        "translation": "tr. D. P. Chase (1847), public domain",
        "start": r"(?m)^BOOK I\s*$",
        "end": r"(?m)^\s*NOTES\s*$|\*\*\* ?END OF",
        "chapter": r"^\s*Chapter ([IVXL]+)\.\s*$",
        "book": r"^\s*BOOK ([IVX]+)\s*$",
    },
}


class _Text(HTMLParser):
    BREAKS = {"p", "br", "h1", "h2", "h3", "h4", "div", "li", "tr", "blockquote"}

    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag: str, attrs: list) -> None:
        if tag in ("script", "style"):
            self._skip += 1
        if tag in self.BREAKS:
            self.parts.append("\n\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in ("script", "style"):
            self._skip -= 1

    def handle_data(self, data: str) -> None:
        if not self._skip:
            self.parts.append(data)


def tidy(raw: str, html: bool = False) -> str:
    if html:
        parser = _Text()
        parser.feed(raw)
        raw = "".join(parser.parts)
    raw = raw.replace("\u00a0", " ").replace("\ufffd", " ")
    raw = re.sub(r"[ \t\r]+", " ", raw)
    return re.sub(r"\n\s*\n+", "\n\n", raw)


def read_text(path: Path, encoding: str) -> str:
    raw = path.read_text(encoding=encoding, errors="replace")
    return tidy(raw, path.suffix.lower() in (".html", ".htm"))


def fetch(url: str) -> str:
    """The text at url, from the cache when it has been fetched before (retrying a dropped
    connection a few times, waiting longer each time)."""
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / (re.sub(r"[^A-Za-z0-9._-]+", "_", url)[-150:] + ".txt")
    if cached.exists():
        return cached.read_text(encoding="utf-8")
    request = urllib.request.Request(url, headers={"User-Agent": "great-works-game corpus builder"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=60) as reply:
                text = reply.read().decode("utf-8", errors="replace")
            cached.write_text(text, encoding="utf-8")
            logger.info("fetched %s", url)
            return text
        except (urllib.error.URLError, TimeoutError, ConnectionError) as err:
            wait = 2 ** (attempt + 1)
            logger.warning("%s: %s; trying again in %d s", url, err, wait)
            time.sleep(wait)
    raise RuntimeError(f"could not fetch {url}")


def unwiki(raw: str) -> str:
    """Wikisource page source to plain text: templates, tags and editors' marks removed."""
    raw = re.sub(r"\{\{(?:[^{}]|\{\{[^{}]*\}\})*\}\}", "", raw, flags=re.S)
    raw = re.sub(r"<ref[^>]*>.*?</ref>|<[^>]+>", "", raw, flags=re.S)
    raw = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", raw)
    raw = raw.replace("‹", "").replace("›", "").replace("†", "")
    return raw


def segments(text: str, part: dict) -> str:
    """Only the parts of a scanned book that are the author's own text (not the editor's notes):
    each {"start", "end", "heading"} keeps every span from a start match to the end of its end
    match (or, failing that, "max" characters on, at a paragraph break), under a heading line ({n}
    numbers them in order), at most "limit" of them ("keep_last" keeps only the end match under the
    heading); "drop" removes scanner debris lines."""
    kept: list[str] = []
    for seg in part["segments"]:
        n = 0
        last = 0
        pos = 0
        while True:
            m = re.search(seg["start"], text[pos:], re.M)
            if not m:
                break
            start = pos + m.start()
            window = text[start: start + seg.get("max", 10**9)]
            e = re.search(seg["end"], window, re.M | re.S)
            if e:
                stop = start + e.end()
            elif "max" in seg:
                cut = window.rfind("\n\n")
                stop = start + (cut if cut > 0 else len(window))
            else:
                break
            n += 1
            number = n
            if m.groups():  # the number the book itself gives, read through the scanner's slips
                digits = m.group(1).translate(str.maketrans("ilIoOS", "111005"))
                number = int(digits) if digits.isdigit() else n
                if number < last:
                    break  # the next book begins again at 1
                last = number
            body = text[start + (m.end() - m.start()) if seg.get("skip_start") else start: stop]
            if seg.get("keep_last"):  # only what the end matched: e.g. the translation after the original
                body = e.group(0) if e else ""
            kept.append(seg["heading"].format(n=number) + "\n\n" + body)
            pos = stop
            if seg.get("once") or n >= seg.get("limit", 10**9):
                break
    out = "\n\n".join(kept)
    for pattern in part.get("drop", []):
        out = re.sub(pattern, "", out, flags=re.M)
    return out


def source_text(part: dict) -> str:
    if "urls" in part:
        pieces = []
        for url, heading in part["urls"]:
            raw = fetch(url)
            raw = unwiki(raw) if part.get("wiki") else raw
            pieces.append(f"{heading}\n\n{raw}" if heading else raw)
        return tidy("\n\n".join(pieces), part.get("html", False))
    return read_text(LIBRARY / part["file"], part.get("encoding", "utf-8"))


def body_of(text: str, spec: dict) -> str:
    start = re.search(spec["start"], text)
    if not start:
        raise ValueError(f"start marker {spec['start']!r} not found")
    text = text[start.start():]
    last_chapter = list(re.finditer(spec["chapter"], text, re.M))
    tail_from = last_chapter[-1].end() if last_chapter else 0
    end = re.search(spec["end"], text[tail_from:])
    return text[: tail_from + end.start()] if end else text


def clean(paragraph: str) -> str:
    paragraph = re.sub(r"^\s*==\s*\d+\s*==\s*", "", paragraph)  # a Wikisource section heading
    paragraph = re.sub(r"\|\d+", "", paragraph)  # page numbers like "|633"
    paragraph = re.sub(r"(?<=[a-zA-Z.,;:])\d{1,2}\b", "", paragraph)  # footnote marks like "Porphyry.1"
    return re.sub(r"\s+", " ", paragraph).strip()


def chunk(body: str, spec: dict, title: str) -> list[dict]:
    chunks: list[dict] = []
    chapter = ""
    book = ""
    words: list[str] = []

    def flush(final: bool = False) -> None:
        if len(words) < 25 and not final:
            return  # a lone heading joins the passage that follows it
        if words:
            named = spec.get("chapter_names", {}).get(chapter, "")
            where = title + (f", Book {book}" if book else "") + (
                f", {named}" if named else f", {spec.get('chapter_label', 'Chap.')} {chapter}" if chapter else "")
            chunks.append({"id": len(chunks), "where": where, "text": " ".join(words)})
            words.clear()

    for para in body.split("\n\n"):
        b = re.match(spec["book"], para, re.M) if spec.get("book") else None
        if b:
            flush(final=bool(chapter))
            book, chapter = b.group(1), ""
            continue
        m = re.match(spec["chapter"], para, re.M)
        if m:
            # a chapter's last lines stay with that chapter; only text before the
            # first chapter (a title) is carried into the chapter that follows
            flush(final=bool(chapter))
            chapter = next((g for g in m.groups() if g), "")
        text = clean(para)
        if not text:
            continue
        pw = text.split()
        if len(words) + len(pw) > MAX_WORDS:
            flush()
        while len(pw) > MAX_WORDS:  # one very long paragraph
            words.extend(pw[:TARGET_WORDS])
            pw = pw[TARGET_WORDS:]
            flush()
        words.extend(pw)
        if len(words) >= TARGET_WORDS:
            flush()
    flush(final=True)
    return chunks


def build(work_id: str) -> Path:
    spec = BOOKS[work_id]
    chunks: list[dict] = []
    for part in spec.get("parts", [spec]):
        text = source_text(part)
        if "segments" in part:
            text = tidy(segments(text, part))
        body = body_of(text, part)
        if "segments" not in part:  # (a segmented book has had its debris dropped already)
            for pattern in part.get("drop", []):
                body = re.sub(pattern, "", body, flags=re.M)
        for c in chunk(body, part, part["title"]):
            c["id"] = len(chunks)
            chunks.append(c)
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / f"{work_id}.json"
    data = {"work": work_id, "title": spec["title"], "translation": spec["translation"], "chunks": chunks}
    out.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    words = sum(len(c["text"].split()) for c in chunks)
    logger.info("%s: %d passages, %d words -> %s", work_id, len(chunks), words, out.name)
    return out


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    ids = sys.argv[1:] or list(BOOKS)
    for work_id in ids:
        if work_id not in BOOKS:
            logger.error("No book configured for %s", work_id)
            return 1
        build(work_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
