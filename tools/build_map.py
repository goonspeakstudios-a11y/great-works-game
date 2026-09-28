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
    "335bc": {
        "title": "The world in 335 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Persian Empire", "sub": "King Darius III", "color": [196, 146, 48], "label": [44.0, 34.5],
             "poly": [(26.0, 40.6), (26.3, 41.6), (29.0, 41.4), (33.0, 42.1), (36.0, 42.0), (41.5, 41.8),
                      (46.0, 41.0), (50.0, 40.0), (54.0, 38.5), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0),
                      (51.5, 27.0), (48.5, 29.8), (44.5, 31.0), (42.0, 33.5), (39.0, 34.0), (37.5, 32.0),
                      (36.5, 29.0), (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (25.1, 31.8),
                      (29.0, 31.3), (34.2, 31.4), (35.6, 36.9), (30.0, 36.6), (27.5, 37.0), (26.2, 39.0)]},
            {"name": "Macedon", "sub": "King Alexander, aged 21; Greece under his hand", "color": [70, 104, 138], "label": [25.2, 43.6],
             "poly": [(19.2, 41.8), (19.5, 42.6), (22.0, 42.6), (24.0, 42.1), (26.0, 41.7), (26.5, 40.8),
                      (24.5, 40.4), (23.5, 39.8), (22.8, 39.2), (23.2, 38.5), (24.2, 38.0), (23.2, 37.4),
                      (22.6, 36.5), (21.5, 36.8), (21.0, 38.0), (20.5, 39.0), (20.0, 40.0), (19.5, 41.0)]},
            {"name": "Carthage", "sub": "the sea's traders", "color": [124, 58, 96], "label": [6.0, 33.0],
             "poly": [(-2.0, 35.5), (3.0, 36.9), (8.5, 37.2), (11.2, 37.2), (11.3, 33.5), (15.5, 32.7),
                      (19.5, 30.5), (19.5, 29.5), (10.0, 31.5), (6.0, 34.0), (0.0, 34.2), (-2.0, 34.8)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(12.0, 38.3), (13.5, 38.2), (13.5, 37.2), (12.4, 37.5)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(8.0, 41.1), (9.9, 41.1), (9.9, 38.9), (8.2, 38.9)]},
            {"name": "Rome", "sub": "a small republic", "color": [150, 58, 42], "label": [12.5, 41.9],
             "poly": [(11.5, 42.5), (13.0, 42.7), (14.3, 41.4), (15.0, 40.8), (14.2, 40.5), (12.5, 41.4), (11.8, 42.1)]},
        ],
        "others": [
            {"name": "Celts", "at": [3.0, 47.0]},
            {"name": "Scythians", "at": [34.0, 48.0]},
            {"name": "Illyrians", "at": [15.5, 45.4]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Libya", "at": [16.0, 26.0]},
        ],
        "pins": [
            {"name": "Athens", "note": "the Lyceum, his new school", "at": [23.73, 37.98], "main": True},
            {"name": "Stagira", "note": "his birthplace", "at": [23.75, 40.53]},
            {"name": "Pella", "note": "where he taught the boy Alexander", "at": [22.52, 40.80], "side": "left"},
            {"name": "Mytilene", "note": "where he studied the creatures of the sea", "at": [26.55, 39.10], "side": "below"},
            {"name": "Persepolis", "note": "Darius's capital; Alexander burns it in 330", "at": [52.89, 29.93]},
        ],
    },
    # ---- the Greek places still to come, and Rome ----
    "1200bc": {
        "title": "The world about 1200 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Hittite Empire", "sub": "the last great king, Suppiluliuma II", "color": [120, 84, 54], "label": [33.5, 39.0],
             "poly": [(28.0, 40.9), (31.0, 41.3), (35.0, 41.8), (38.5, 40.5), (40.5, 38.0), (39.5, 36.0), (38.0, 35.2),
                      (36.2, 35.0), (35.5, 36.2), (33.0, 36.2), (30.5, 36.4), (28.5, 37.3), (28.6, 39.2)]},
            {"name": "Troy", "sub": "Wilusa, a city bound to the Hittites", "color": [176, 128, 64], "label": [27.0, 40.2],
             "poly": [(26.0, 40.5), (27.6, 40.6), (28.0, 39.4), (26.3, 39.2)]},
            {"name": "Achaeans", "sub": "the Mycenaean kings of Agamemnon's Greece", "color": [70, 104, 138], "label": [21.4, 39.6],
             "poly": [(21.0, 38.4), (21.8, 39.6), (22.8, 39.9), (23.4, 39.5), (24.0, 38.3), (24.1, 37.7), (23.3, 37.4),
                      (23.2, 36.4), (22.4, 36.4), (21.5, 36.8), (21.1, 37.8)]},
            {"name": "Achaeans", "sub": "", "color": [70, 104, 138],
             "poly": [(23.4, 35.75), (26.4, 35.4), (26.4, 34.85), (23.4, 35.15)]},
            {"name": "Egypt", "sub": "the pharaohs of the New Kingdom", "color": [170, 128, 64], "label": [30.5, 26.5],
             "poly": [(25.1, 31.6), (29.0, 31.3), (32.3, 31.2), (34.2, 31.3), (35.0, 32.8), (35.7, 33.6), (36.3, 33.2),
                      (35.9, 31.5), (34.9, 29.5), (34.5, 27.5), (33.0, 24.0), (32.5, 21.0), (30.5, 21.0), (29.0, 24.0), (25.0, 29.5)]},
            {"name": "Assyria", "sub": "a warrior kingdom on the Tigris", "color": [110, 70, 110], "label": [43.0, 36.2],
             "poly": [(40.5, 37.4), (44.5, 37.5), (45.6, 35.5), (44.5, 33.8), (42.0, 34.2), (39.8, 35.6)]},
            {"name": "Babylonia", "sub": "the Kassite kings", "color": [150, 110, 70], "label": [45.8, 31.6],
             "poly": [(44.5, 33.8), (45.6, 35.2), (47.8, 32.0), (47.9, 30.0), (46.5, 29.9), (45.0, 30.6), (44.0, 32.0)]},
        ],
        "others": [
            {"name": "Thracians", "at": [25.5, 42.6]},
            {"name": "Libyans", "at": [22.0, 28.5]},
            {"name": "Elam", "at": [50.0, 32.0]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Italy", "at": [14.2, 41.0]},
        ],
        "pins": [
            {"name": "Troy", "note": "Priam's city: the war Homer sings", "at": [26.24, 39.96], "main": True, "side": "above"},
            {"name": "Mycenae", "note": "Agamemnon's citadel", "at": [22.76, 37.73], "side": "left"},
            {"name": "Sparta", "note": "Menelaus and Helen", "at": [22.43, 37.08], "side": "below"},
            {"name": "Ithaca", "note": "Odysseus's home", "at": [20.67, 38.36], "side": "left"},
            {"name": "Hattusa", "note": "the Hittite king's capital", "at": [34.62, 40.02]},
        ],
    },
    "480bc": {
        "title": "The world in 480 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Persian Empire", "sub": "King Xerxes", "color": [196, 146, 48], "label": [44.0, 34.5],
             "poly": [(22.8, 40.5), (23.2, 41.4), (26.5, 42.4), (28.0, 42.0), (29.0, 41.4), (33.0, 42.1), (36.0, 42.0),
                      (41.5, 41.8), (46.0, 41.0), (50.0, 40.0), (54.0, 38.5), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0),
                      (51.5, 27.0), (48.5, 29.8), (44.5, 31.0), (42.0, 33.5), (39.0, 34.0), (37.5, 32.0), (36.5, 29.0),
                      (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (25.1, 31.8), (29.0, 31.3), (34.2, 31.4),
                      (35.6, 36.9), (30.0, 36.6), (27.5, 37.0), (26.2, 39.0)]},
            {"name": "Macedon", "sub": "King Alexander I, subject to Xerxes", "color": [110, 96, 140], "label": [20.2, 41.6],
             "poly": [(21.0, 41.2), (22.5, 41.4), (23.0, 40.6), (22.6, 40.0), (21.6, 40.0), (20.8, 40.6)]},
            {"name": "Greek allies", "sub": "Athens, Sparta and their league", "color": [70, 104, 138], "label": [21.0, 36.2],
             "poly": [(21.1, 37.9), (21.8, 38.4), (22.8, 38.2), (23.3, 38.3), (23.6, 38.4), (24.1, 38.2), (24.1, 37.6),
                      (23.2, 37.4), (23.2, 36.4), (22.4, 36.4), (21.6, 36.7), (21.5, 37.2)]},
            {"name": "Carthage", "sub": "Hamilcar sails for Sicily", "color": [124, 58, 96], "label": [6.0, 33.0],
             "poly": [(-2.0, 35.5), (3.0, 36.9), (8.5, 37.2), (11.2, 37.2), (11.3, 33.5), (15.5, 32.7),
                      (19.5, 30.5), (19.5, 29.5), (10.0, 31.5), (6.0, 34.0), (0.0, 34.2), (-2.0, 34.8)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(12.0, 38.3), (13.2, 38.2), (13.0, 37.3), (12.4, 37.5)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(8.0, 41.1), (9.9, 41.1), (9.9, 38.9), (8.2, 38.9)]},
            {"name": "Rome", "sub": "a young republic", "color": [150, 58, 42], "label": [12.5, 42.4],
             "poly": [(12.1, 42.1), (12.9, 42.1), (12.9, 41.6), (12.3, 41.7)]},
        ],
        "others": [
            {"name": "Celts", "at": [3.0, 47.0]},
            {"name": "Scythians", "at": [34.0, 48.0]},
            {"name": "Etruscans", "at": [11.4, 43.4]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Libya", "at": [16.0, 26.0]},
        ],
        "pins": [
            {"name": "Thermopylae", "note": "three hundred Spartans hold the pass", "at": [22.54, 38.80], "main": True, "side": "left"},
            {"name": "Salamis", "note": "the Greek fleet wins", "at": [23.50, 37.95], "side": "right"},
            {"name": "Sparta", "note": "King Leonidas's city", "at": [22.43, 37.08], "side": "below"},
            {"name": "Sardis", "note": "Xerxes' army musters", "at": [28.04, 38.48]},
            {"name": "Halicarnassus", "note": "Herodotus is born here, about 484", "at": [27.43, 37.04], "side": "below"},
            {"name": "Susa", "note": "Xerxes' capital", "at": [48.25, 32.19]},
        ],
    },
    "431bc": {
        "title": "The world in 431 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Persian Empire", "sub": "King Artaxerxes I", "color": [196, 146, 48], "label": [44.0, 34.5],
             "poly": [(26.0, 40.6), (26.3, 41.6), (29.0, 41.4), (33.0, 42.1), (36.0, 42.0), (41.5, 41.8),
                      (46.0, 41.0), (50.0, 40.0), (54.0, 38.5), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0),
                      (51.5, 27.0), (48.5, 29.8), (44.5, 31.0), (42.0, 33.5), (39.0, 34.0), (37.5, 32.0),
                      (36.5, 29.0), (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (25.1, 31.8),
                      (29.0, 31.3), (34.2, 31.4), (35.6, 36.9), (30.0, 36.6), (27.5, 37.0), (26.2, 39.0)]},
            {"name": "Macedon", "sub": "King Perdiccas II", "color": [110, 96, 140], "label": [20.6, 42.0],
             "poly": [(20.8, 41.4), (22.8, 41.6), (23.2, 40.9), (22.6, 40.1), (21.6, 40.0), (20.7, 40.7)]},
            {"name": "Sparta and allies", "sub": "the Peloponnesian League, Thebes, Corinth", "color": [160, 52, 52],
             "label": [20.6, 36.2],
             "poly": [(21.1, 37.8), (21.7, 38.3), (22.4, 38.5), (23.3, 38.55), (23.35, 38.3), (23.0, 38.1), (23.2, 37.9),
                      (22.9, 37.5), (23.2, 36.4), (22.4, 36.4), (21.6, 36.7), (21.5, 37.2)]},
            {"name": "Athenian empire", "sub": "Pericles; the Delian League", "color": [70, 104, 138], "label": [25.6, 38.4],
             "poly": [(23.35, 37.95), (23.6, 38.35), (22.9, 39.05), (23.4, 39.3), (24.2, 39.0), (23.0, 40.1), (22.9, 40.5),
                      (24.5, 40.9), (26.0, 40.9), (26.5, 40.4), (27.0, 40.3), (26.9, 39.9), (26.7, 39.5), (27.0, 38.8),
                      (27.2, 38.2), (27.4, 37.6), (27.6, 37.0), (28.0, 36.6), (28.4, 36.2), (27.8, 35.8), (26.0, 36.3),
                      (25.2, 36.3), (24.7, 36.95), (24.1, 36.95), (23.9, 37.6)]},
            {"name": "Carthage", "sub": "the sea's traders", "color": [124, 58, 96], "label": [6.0, 33.0],
             "poly": [(-2.0, 35.5), (3.0, 36.9), (8.5, 37.2), (11.2, 37.2), (11.3, 33.5), (15.5, 32.7),
                      (19.5, 30.5), (19.5, 29.5), (10.0, 31.5), (6.0, 34.0), (0.0, 34.2), (-2.0, 34.8)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(12.0, 38.3), (13.2, 38.2), (13.0, 37.3), (12.4, 37.5)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(8.0, 41.1), (9.9, 41.1), (9.9, 38.9), (8.2, 38.9)]},
            {"name": "Rome", "sub": "a republic of central Italy", "color": [150, 58, 42], "label": [12.4, 43.0],
             "poly": [(11.8, 42.4), (12.9, 42.5), (13.2, 41.6), (12.5, 41.4), (11.9, 42.0)]},
        ],
        "others": [
            {"name": "Thracians", "at": [25.5, 42.8]},
            {"name": "Scythians", "at": [34.0, 48.0]},
            {"name": "Celts", "at": [3.0, 47.0]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Libya", "at": [16.0, 26.0]},
        ],
        "pins": [
            {"name": "Athens", "note": "Pericles' city; Thucydides begins his history", "at": [23.73, 37.98], "main": True},
            {"name": "Sparta", "note": "the rival", "at": [22.43, 37.08], "side": "left"},
            {"name": "Melos", "note": "neutral; Athens takes it in 416", "at": [24.43, 36.72], "side": "below"},
            {"name": "Mytilene", "note": "revolts in 428; the debate", "at": [26.55, 39.10]},
            {"name": "Syracuse", "note": "the Athenians lost there, 413", "at": [15.29, 37.07], "side": "left"},
            {"name": "Corcyra", "note": "the quarrel that starts the war", "at": [19.92, 39.62], "side": "left"},
        ],
    },
    "300bc": {
        "title": "The world in 300 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Seleucid Empire", "sub": "King Seleucus I", "color": [84, 118, 70], "label": [47.0, 34.0],
             "poly": [(35.9, 34.0), (36.0, 36.6), (38.5, 37.3), (41.0, 37.3), (43.0, 37.2), (45.5, 38.0), (50.0, 37.5),
                      (54.0, 37.8), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0), (51.5, 27.0), (48.5, 29.8), (44.5, 31.0),
                      (42.0, 33.5), (39.0, 34.0), (37.8, 33.4)]},
            {"name": "Ptolemaic Egypt", "sub": "King Ptolemy I", "color": [170, 128, 64], "label": [29.5, 27.0],
             "poly": [(19.8, 31.0), (20.2, 32.3), (21.5, 32.95), (23.2, 32.6), (25.1, 31.8), (29.0, 31.3), (32.3, 31.2),
                      (34.2, 31.3), (35.0, 32.8), (35.8, 34.0), (36.6, 33.3), (35.8, 31.0), (35.0, 29.5), (34.5, 27.5),
                      (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (20.0, 29.8)]},
            {"name": "Ptolemaic Egypt", "sub": "", "color": [170, 128, 64],
             "poly": [(32.2, 35.2), (34.6, 35.7), (34.6, 34.5), (32.2, 34.6)]},
            {"name": "Lysimachus", "sub": "king of Thrace and Asia", "color": [110, 96, 140], "label": [31.0, 39.0],
             "poly": [(24.0, 41.2), (24.5, 42.0), (26.5, 42.8), (27.8, 43.5), (28.6, 44.5), (29.6, 45.2), (29.0, 41.4),
                      (30.5, 41.2), (33.0, 42.0), (34.5, 41.5), (34.0, 39.0), (33.5, 37.5), (32.0, 36.4), (29.5, 36.3),
                      (27.4, 36.8), (26.2, 39.0), (26.2, 40.6), (25.0, 40.8)]},
            {"name": "Macedon", "sub": "King Cassander; Greece under his hand", "color": [70, 104, 138], "label": [21.0, 43.0],
             "poly": [(19.2, 41.8), (19.5, 42.6), (22.0, 42.6), (24.0, 42.1), (24.3, 41.4), (24.5, 40.4), (23.5, 39.8),
                      (22.8, 39.2), (23.2, 38.5), (24.2, 38.0), (23.2, 37.4), (22.6, 36.5), (21.5, 36.8), (21.0, 38.0),
                      (20.5, 39.0), (20.0, 40.0), (19.5, 41.0)]},
            {"name": "Carthage", "sub": "the sea's traders", "color": [124, 58, 96], "label": [6.0, 33.0],
             "poly": [(-2.0, 35.5), (3.0, 36.9), (8.5, 37.2), (11.2, 37.2), (11.3, 33.5), (15.5, 32.7),
                      (19.5, 30.5), (19.5, 29.5), (10.0, 31.5), (6.0, 34.0), (0.0, 34.2), (-2.0, 34.8)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(12.0, 38.3), (13.8, 38.2), (13.6, 37.2), (12.4, 37.5)]},
            {"name": "Carthage", "sub": "", "color": [124, 58, 96],
             "poly": [(8.0, 41.1), (9.9, 41.1), (9.9, 38.9), (8.2, 38.9)]},
            {"name": "Rome", "sub": "winning the Samnite wars", "color": [150, 58, 42], "label": [12.3, 43.7],
             "poly": [(11.3, 42.9), (12.8, 43.1), (14.2, 42.2), (15.0, 41.3), (14.8, 40.6), (14.2, 40.5), (12.5, 41.4),
                      (11.5, 42.1)]},
        ],
        "others": [
            {"name": "Celts", "at": [3.0, 47.0]},
            {"name": "Scythians", "at": [34.0, 48.0]},
            {"name": "Arabia", "at": [44.0, 24.0]},
            {"name": "Libya", "at": [16.0, 26.0]},
            {"name": "Armenia", "at": [43.5, 40.2]},
        ],
        "pins": [
            {"name": "Alexandria", "note": "Euclid writes the Elements; the Library, the Pharos", "at": [29.92, 31.20],
             "main": True, "side": "left"},
            {"name": "Athens", "note": "Epicurus and Zeno teach", "at": [23.73, 37.98], "side": "left"},
            {"name": "Syracuse", "note": "Archimedes is born here, about 287", "at": [15.29, 37.07], "side": "left"},
            {"name": "Rhodes", "note": "the Colossus is raised, 292 - 280", "at": [28.22, 36.44], "side": "below"},
            {"name": "Seleucia", "note": "Seleucus's new capital on the Tigris", "at": [44.52, 33.10]},
        ],
    },
    "85bc": {
        "title": "The world in 85 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Roman Republic", "sub": "Sulla in the East, Marius's party in Rome", "color": [150, 58, 42],
             "label": [12.0, 44.0],
             "poly": [(2.0, 42.4), (1.4, 43.7), (3.2, 44.1), (4.6, 44.5), (6.2, 44.9), (7.2, 45.9), (9.5, 46.4),
                      (12.5, 46.6), (14.0, 46.0), (15.5, 45.2), (17.5, 44.3), (19.5, 43.0), (21.0, 42.4), (23.5, 42.0),
                      (25.5, 41.3), (26.3, 40.9), (26.4, 40.0), (25.0, 38.5), (24.2, 36.9), (23.0, 36.2), (21.5, 36.6),
                      (20.0, 38.0), (18.5, 39.8), (18.0, 39.0), (16.5, 38.0), (15.5, 37.5), (15.2, 36.6), (12.4, 37.6),
                      (12.5, 38.2), (8.0, 38.9), (8.1, 41.3), (9.0, 43.2), (7.5, 43.8), (5.5, 43.1), (3.4, 43.2)]},
            {"name": "Roman Republic", "sub": "", "color": [150, 58, 42],
             "poly": [(-8.9, 37.0), (-7.3, 37.2), (-6.3, 36.6), (-5.6, 36.0), (-4.0, 36.7), (-2.0, 36.7), (0.0, 38.6),
                      (0.2, 39.8), (0.9, 41.0), (3.2, 41.9), (2.5, 42.5), (0.5, 42.7), (-1.5, 42.2), (-3.0, 41.6),
                      (-4.5, 40.5), (-6.0, 39.5), (-7.3, 38.8), (-8.9, 38.4)]},
            {"name": "Roman Republic", "sub": "", "color": [150, 58, 42],
             "poly": [(26.2, 40.2), (27.5, 40.4), (29.0, 40.2), (30.0, 39.5), (30.5, 38.5), (30.0, 37.2), (29.0, 36.6),
                      (27.2, 36.9), (26.3, 38.3)]},
            {"name": "Roman Republic", "sub": "", "color": [150, 58, 42],
             "poly": [(8.5, 37.0), (10.3, 37.3), (11.1, 36.8), (11.1, 35.3), (10.4, 34.6), (9.3, 35.0), (8.5, 36.0)]},
            {"name": "Pontus", "sub": "King Mithridates VI, beaten back by Sulla", "color": [96, 84, 132], "label": [36.5, 40.6],
             "poly": [(33.0, 42.0), (35.0, 42.1), (37.5, 41.2), (40.5, 41.0), (41.6, 41.5), (41.0, 40.0), (38.5, 39.8),
                      (36.0, 40.0), (34.0, 40.5), (33.0, 41.0)]},
            {"name": "Armenia", "sub": "King Tigranes the Great", "color": [120, 96, 60], "label": [43.5, 38.8],
             "poly": [(41.6, 41.5), (44.5, 41.2), (46.5, 41.0), (47.5, 39.5), (46.0, 38.0), (44.0, 37.0), (41.5, 37.0),
                      (39.0, 37.6), (38.5, 39.0), (41.0, 40.0)]},
            {"name": "Parthian Empire", "sub": "the Arsacid kings", "color": [84, 118, 70], "label": [52.0, 32.0],
             "poly": [(47.5, 39.5), (48.5, 38.5), (53.5, 37.5), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0), (51.5, 27.0),
                      (48.5, 29.8), (47.5, 30.0), (44.5, 31.0), (42.0, 33.5), (44.0, 37.0), (46.0, 38.0)]},
            {"name": "Seleucid Syria", "sub": "the last Seleucids, at war with each other", "color": [140, 110, 90],
             "label": [36.9, 34.6],
             "poly": [(35.9, 36.9), (38.0, 36.5), (38.5, 35.0), (37.5, 33.5), (36.0, 33.3), (35.5, 35.0)]},
            {"name": "Ptolemaic Egypt", "sub": "the Ptolemies", "color": [170, 128, 64], "label": [30.0, 27.0],
             "poly": [(25.1, 31.6), (29.0, 31.3), (32.3, 31.2), (34.2, 31.3), (34.9, 29.5), (34.5, 27.5), (33.0, 24.0),
                      (29.0, 24.0), (25.0, 29.5)]},
            {"name": "Ptolemaic Egypt", "sub": "", "color": [170, 128, 64],
             "poly": [(32.2, 35.2), (34.6, 35.7), (34.6, 34.5), (32.2, 34.6)]},
        ],
        "others": [
            {"name": "Gauls", "at": [2.5, 47.0]},
            {"name": "Germans", "at": [10.5, 51.5]},
            {"name": "Dacians", "at": [24.5, 46.2]},
            {"name": "Numidia", "at": [5.0, 34.8]},
            {"name": "Mauretania", "at": [-4.5, 33.0]},
            {"name": "Arabia", "at": [44.0, 24.0]},
        ],
        "pins": [
            {"name": "Rome", "note": "The Rhetorica ad Herennium is written here", "at": [12.49, 41.90], "main": True},
            {"name": "Athens", "note": "Sacked by Sulla, 86 BC", "at": [23.73, 37.98], "side": "left"},
            {"name": "Chaeronea", "note": "Sulla beats Mithridates' army, 86 BC", "at": [22.84, 38.50], "side": "above"},
            {"name": "Rhodes", "note": "Molon's school of speaking", "at": [28.22, 36.43], "side": "below"},
        ],
    },
    "44bc": {
        "title": "The world in 44 BC",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Parthian Empire", "sub": "King Orodes II", "color": [84, 118, 70], "label": [50.0, 33.0],
             "poly": [(39.5, 37.2), (43.0, 37.5), (45.5, 38.5), (48.5, 38.5), (53.5, 37.5), (58.5, 38.0), (58.5, 24.5),
                      (56.5, 24.0), (51.5, 27.0), (48.5, 29.8), (47.5, 30.0), (44.5, 31.0), (42.0, 33.5), (40.2, 34.5),
                      (38.8, 35.8)]},
            {"name": "Roman Republic", "sub": "Caesar dictator for life, until the Ides", "color": [150, 58, 42],
             "label": [2.0, 45.5],
             "poly": [(-4.8, 48.4), (-1.5, 49.8), (1.5, 50.9), (4.5, 52.0), (6.5, 51.5), (7.5, 50.5), (8.3, 49.5),
                      (7.6, 47.6), (9.5, 47.0), (10.5, 46.6), (13.7, 46.4), (14.5, 45.6), (16.0, 45.5), (18.5, 44.0),
                      (19.8, 42.5), (21.5, 42.3), (23.5, 41.9), (24.5, 41.3), (26.3, 40.9), (29.0, 41.2), (31.5, 41.3),
                      (34.0, 42.0), (36.5, 41.4), (35.0, 40.0), (32.0, 39.5), (31.5, 38.0), (32.5, 37.2), (34.0, 37.3),
                      (36.2, 37.3), (37.0, 37.0), (38.0, 36.9), (38.5, 35.5), (38.8, 34.0), (37.0, 33.2), (36.0, 33.0),
                      (35.1, 33.0), (25.1, 31.7), (25.0, 30.0), (19.5, 30.0), (15.5, 30.6), (13.0, 32.0), (11.0, 32.3),
                      (9.5, 33.5), (8.5, 34.8), (6.3, 35.5), (6.2, 36.9), (-1.0, 37.3), (-5.5, 36.0), (-6.5, 36.5),
                      (-9.0, 37.0), (-9.5, 39.0), (-8.9, 41.0), (-7.5, 41.8), (-5.0, 42.8), (-2.0, 43.4), (-1.3, 45.5),
                      (-1.2, 46.3), (-2.5, 47.3)]},
            {"name": "Ptolemaic Egypt", "sub": "Queen Cleopatra", "color": [170, 128, 64], "label": [30.0, 27.0],
             "poly": [(25.1, 31.6), (29.0, 31.3), (32.3, 31.2), (34.2, 31.3), (34.9, 29.5), (34.5, 27.5), (33.0, 24.0),
                      (29.0, 24.0), (25.0, 29.5)]},
            {"name": "Ptolemaic Egypt", "sub": "", "color": [170, 128, 64],
             "poly": [(32.2, 35.2), (34.6, 35.7), (34.6, 34.5), (32.2, 34.6)]},
        ],
        "others": [
            {"name": "Germans", "at": [10.5, 51.5]},
            {"name": "Dacians", "at": [24.5, 46.2]},
            {"name": "Mauretania", "at": [-4.5, 33.0]},
            {"name": "Armenia", "at": [43.5, 40.2]},
            {"name": "Arabia", "at": [44.0, 24.0]},
        ],
        "pins": [
            {"name": "Rome", "note": "Caesar is killed on the Ides of March", "at": [12.49, 41.90], "main": True},
            {"name": "Philippi", "note": "Brutus and Cassius fall, 42 BC", "at": [24.29, 41.01], "side": "above"},
            {"name": "Actium", "note": "Octavian wins, 31 BC", "at": [20.77, 38.95], "side": "left"},
            {"name": "Alexandria", "note": "Cleopatra's capital", "at": [29.92, 31.20], "side": "below"},
            {"name": "Carrhae", "note": "Crassus's legions lost to Parthia, 53 BC", "at": [39.03, 36.87]},
        ],
    },
    "117ad": {
        "title": "The world in 117 AD",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Parthian Empire", "sub": "King Osroes I", "color": [84, 118, 70], "label": [52.0, 32.0],
             "poly": [(46.5, 39.5), (48.0, 38.5), (53.5, 37.5), (58.5, 38.0), (58.5, 24.5), (56.5, 24.0), (51.5, 27.0),
                      (48.5, 29.8), (47.5, 31.5), (46.0, 34.0), (45.0, 37.0), (46.0, 39.0)]},
            {"name": "Roman Empire", "sub": "Emperor Trajan, at its widest", "color": [150, 58, 42], "label": [18.0, 44.5],
             "poly": [(-5.5, 55.0), (-1.5, 55.0), (4.5, 52.0), (6.5, 51.5), (7.5, 50.5), (8.3, 50.0), (8.8, 50.4),
                      (9.5, 49.5), (10.5, 49.0), (12.1, 49.0), (13.5, 48.6), (16.4, 48.2), (18.9, 47.8),
                      (19.0, 47.5), (18.9, 45.9), (20.5, 44.8), (21.0, 45.4), (22.5, 47.5), (24.5, 47.8),
                      (26.5, 46.5), (26.0, 45.2), (27.5, 44.2), (29.5, 45.0), (33.0, 43.5), (41.5, 41.8),
                      (46.5, 41.2), (46.0, 39.0), (45.0, 37.0), (46.0, 34.0), (47.5, 31.5), (48.3, 30.0), (47.5, 29.8),
                      (45.5, 30.8), (43.0, 32.5), (40.5, 33.8), (39.0, 33.5), (37.5, 32.0), (36.5, 29.0),
                      (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (20.0, 30.3), (15.0, 30.0),
                      (10.0, 32.0), (8.0, 33.5), (5.0, 34.5), (0.0, 34.5), (-5.0, 34.0), (-7.0, 34.0),
                      (-10.5, 34.5), (-10.5, 44.0), (-5.8, 50.0), (-5.2, 52.0), (-4.8, 54.0)]},
        ],
        "others": [
            {"name": "Germans", "at": [11.0, 52.5]},
            {"name": "Sarmatians", "at": [34.0, 48.0]},
            {"name": "Arabia", "at": [42.0, 24.0]},
            {"name": "Garamantes", "at": [14.0, 26.0]},
        ],
        "pins": [
            {"name": "Rome", "note": "Trajan's forum and column", "at": [12.49, 41.90], "main": True, "side": "left"},
            {"name": "Nicopolis", "note": "Epictetus teaches here", "at": [20.73, 39.01], "side": "left"},
            {"name": "Chaeronea", "note": "Plutarch writes the Lives", "at": [22.85, 38.49], "side": "above"},
            {"name": "Sarmizegetusa", "note": "Dacia's capital, taken in 106", "at": [23.31, 45.62], "side": "above"},
            {"name": "Selinus", "note": "Trajan dies here, August 117", "at": [32.03, 36.26], "side": "below"},
            {"name": "Ctesiphon", "note": "the Parthian capital, taken in 116", "at": [44.58, 33.09]},
        ],
    },
    "170ad": {
        "title": "The world in 170 AD",
        "bounds": [-11.0, 58.0, 20.0, 57.0],
        "px_per_deg": 4.0,
        "regions": [
            {"name": "Parthian Empire", "sub": "King Vologases IV", "color": [84, 118, 70], "label": [50.5, 31.0],
             "poly": [(42.0, 38.8), (46.0, 40.2), (50.0, 39.0), (54.0, 38.3), (58.5, 38.0), (58.5, 24.5),
                      (56.5, 24.0), (51.5, 27.0), (48.5, 29.8), (47.5, 30.5), (44.5, 31.2), (42.0, 33.5),
                      (41.5, 35.5), (42.3, 36.8), (42.0, 36.5)]},
            {"name": "Roman Empire", "sub": "Emperor Marcus Aurelius", "color": [150, 58, 42], "label": [18.0, 44.5],
             "poly": [(-5.5, 55.0), (-1.5, 55.0), (4.5, 52.0), (6.5, 51.5), (7.5, 50.5), (8.3, 50.0), (8.8, 50.4),
                      (9.5, 49.5), (10.5, 49.0), (12.1, 49.0), (13.5, 48.6), (16.4, 48.2), (18.9, 47.8),
                      (19.0, 47.5), (18.9, 45.9), (20.5, 44.8), (21.0, 45.4), (22.5, 47.5), (24.5, 47.8),
                      (26.5, 46.5), (26.0, 45.2), (27.5, 44.2), (29.5, 45.0), (33.0, 43.5), (41.5, 41.8),
                      (43.5, 40.5), (41.0, 37.5), (40.5, 35.0), (39.0, 34.0), (37.5, 32.0), (36.5, 29.0),
                      (34.5, 27.5), (33.0, 24.0), (29.0, 24.0), (25.0, 29.5), (20.0, 30.3), (15.0, 30.0),
                      (10.0, 32.0), (8.0, 33.5), (5.0, 34.5), (0.0, 34.5), (-5.0, 34.0), (-7.0, 34.0),
                      (-10.5, 34.5), (-10.5, 44.0), (-5.8, 50.0), (-5.2, 52.0), (-4.8, 54.0)]},
        ],
        "others": [
            {"name": "Marcomanni and Quadi", "at": [15.0, 50.2]},
            {"name": "Iazyges", "at": [20.0, 46.7]},
            {"name": "Germans", "at": [9.5, 53.0]},
            {"name": "Sarmatians", "at": [34.0, 48.0]},
            {"name": "Arabia", "at": [44.0, 24.0]},
        ],
        "pins": [
            {"name": "Carnuntum", "note": "Marcus writes the Meditations in camp", "at": [16.86, 48.11], "main": True,
             "side": "above"},
            {"name": "Sirmium", "note": "his headquarters on the frontier", "at": [19.61, 44.97], "side": "below"},
            {"name": "Rome", "note": "the plague of Galen's day", "at": [12.49, 41.90], "side": "left"},
            {"name": "Athens", "note": "he founds four chairs of philosophy, 176", "at": [23.73, 37.98], "side": "below"},
            {"name": "Pergamon", "note": "Galen's home", "at": [27.18, 39.12]},
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
                    for r in spec["regions"] if r.get("label")],  # an island of a region carries no name
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
