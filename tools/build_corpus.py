"""Turn book files from Desktop\\Book Collections into searchable passages for the Hall.

Each book becomes content/books/<work-id>.json: a list of short passages (about 200
words, split on paragraph edges) labelled with their chapter, so an author can quote
the real text. Only public-domain translations are used.

Usage: C:\\Python314\\python.exe tools/build_corpus.py [work-id ...]
"""
from __future__ import annotations

import json
import logging
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
LIBRARY = Path.home() / "Desktop" / "Book Collections"
OUT = ROOT / "content" / "books"
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


def read_text(path: Path, encoding: str) -> str:
    raw = path.read_text(encoding=encoding, errors="replace")
    if path.suffix.lower() in (".html", ".htm"):
        parser = _Text()
        parser.feed(raw)
        raw = "".join(parser.parts)
    raw = raw.replace("\u00a0", " ").replace("\ufffd", " ")
    raw = re.sub(r"[ \t\r]+", " ", raw)
    return re.sub(r"\n\s*\n+", "\n\n", raw)


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
    paragraph = re.sub(r"\|\d+", "", paragraph)  # page numbers like "|633"
    paragraph = re.sub(r"(?<=[a-zA-Z.,;:])\d{1,2}\b", "", paragraph)  # footnote marks like "Porphyry.1"
    return re.sub(r"\s+", " ", paragraph).strip()


def chunk(body: str, spec: dict, title: str) -> list[dict]:
    chunks: list[dict] = []
    chapter = ""
    words: list[str] = []

    def flush(final: bool = False) -> None:
        if len(words) < 25 and not final:
            return  # a lone heading joins the passage that follows it
        if words:
            where = f"{title}, Chap. {chapter}" if chapter else title
            chunks.append({"id": len(chunks), "where": where, "text": " ".join(words)})
            words.clear()

    for para in body.split("\n\n"):
        m = re.match(spec["chapter"], para, re.M)
        if m:
            # a chapter's last lines stay with that chapter; only text before the
            # first chapter (a title) is carried into the chapter that follows
            flush(final=bool(chapter))
            chapter = m.group(1)
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
    text = read_text(LIBRARY / spec["file"], spec.get("encoding", "utf-8"))
    chunks = chunk(body_of(text, spec), spec, spec["title"])
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
