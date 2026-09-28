"""Writes the activities of the city of Rome into content/rome (docs/rome-activities-plan.md):

  activities.json  your room, the recurring rites' places and times, the spots (the augurs, the
                   boards on the Basilica steps...), the temples and their gods, what to ask each trade
  rites.json       the recurring rites, a scene for each in each age
  sacred.json      the household gods, the augurs, the haruspex, curse tablets, offerings, sleep
  trades.json      work, the market, dice and boards, the money changer, the lender, alms
  scenes.json      the city's other scenes (the census, the baths, the fire, the night...)
  exempla.json     the heroes' stories, played where they happened
  quests.json      the regulars' stories across the ages, step by step
  collections.json the sets you gather

Run: python3 tools/make_rome_activities.py
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rome_acts import rites, sacred, trades, scenes, exempla, quests, collections  # noqa: E402
from rome_acts.common import AGES  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "content", "rome")

# Your room: a rented room on the ground floor of a block in the Subura, off the Argiletum.
ROOM = {"at": [402, 345], "toward": [410, 322],
        "notes": {
            "heroic": "Your room: one room of a tufa house in the Subura, with a hearth, a bed and a chest. Your landlady's family lives above.",
            "early": "Your room in the Subura. The landlady's son died at Cannae. She keeps his portrait by the household shrine.",
            "republic": "Your room on the ground floor of a block of flats in the Subura. Five storeys above you, and all of them noisy.",
            "empire": "Your room in a block of six storeys. The landlord lives on the Esquiline and has never seen it.",
            "late": "Your room. Half the block is empty; the rent has gone up anyway.",
            "collapse": "Your room. The door was broken in by the Vandals and mended with a plank.",
            "fall": "What is left of your room. The roof came down in the second siege. The niche of the household gods is still in the wall.",
        }}

# Other places to do things: {scene, text, at or monument, ages}.
SPOTS = [
    {"scene": "augury", "text": "Watch the sky with the augur on the Arx", "at": [-140, 175],
     "ages": ["heroic", "early", "republic", "empire"]},
    {"scene": "dice_duodecim", "text": "Play at twelve lines on the Basilica steps", "at": [-20, -20],
     "ages": ["republic", "empire", "late", "collapse"]},
    {"scene": "curse_tablet", "text": "Go to the woman at the fountain", "at": [25, -25],
     "ages": ["republic", "empire", "late"]},
    {"scene": "census", "text": "Declare your property to the censors at the Villa Publica", "at": [-545, 300],
     "ages": ["early", "republic"]},
    {"scene": "census", "text": "Declare your property to the tax assessor", "at": [55, 25], "ages": ["late"]},
    {"scene": "practice_race", "text": "Ask at the Greens' stables for a practice run", "at": [120, -620],
     "ages": ["empire", "late"]},
] + scenes.SPOTS + exempla.SPOTS

# The gods of the temples, for an offering at their steps (the temples standing in each age).
TEMPLES = {
    "jupiter": "Jupiter Best and Greatest", "juno_moneta": "Juno the Warner", "saturn": "Saturn", "concord": "Concord",
    "vespasian": "the Deified Vespasian and Titus", "castor": "Castor and Pollux", "vesta": "Vesta",
    "divus_julius": "the Deified Julius", "antoninus": "Antoninus and Faustina", "venus_genetrix": "Venus the Mother",
    "mars_ultor": "Mars the Avenger", "minerva": "Minerva", "venus_roma": "Venus and Rome", "magna_mater": "the Great Mother",
    "apollo_palatinus": "Apollo", "ceres": "Ceres", "diana": "Diana", "juno_regina": "Juno the Queen",
    "hercules": "Hercules the Victor", "portunus": "Portunus, god of harbours", "sant_omobono": "Fortune",
    "aesculapius": "Aesculapius, the healer", "bellona": "Bellona, goddess of war", "apollo_sosianus": "Apollo the Healer",
    "mars_in_circo": "Mars", "venus_victrix": "Venus the Victor", "quirinus": "Quirinus, who was Romulus",
    "serapis": "Serapis", "jupiter_stator": "Jupiter the Stayer", "hadrian_temple": "the Deified Hadrian", "sol": "the Sun",
}
OFFERING_AGES = ["heroic", "early", "republic", "empire", "late"]


def check_scene(sid, s):
    labels = {st["label"] for st in s["steps"] if "label" in st}
    kinds = ["say", "ask", "rite", "hold", "still", "timing", "type", "pick", "pay", "gain", "wage", "if", "play", "label",
             "go", "hour", "end"]
    ends = 0
    for st in s["steps"]:
        k = [x for x in kinds if x in st]
        assert len(k) == 1, (sid, st)
        if k[0] == "end":
            ends += 1
        for key in ("go", "to", "else", "win", "lose"):
            if key in st:
                assert st[key] in labels, (sid, key, st[key])
        for o in st.get("options", []):
            if isinstance(o, dict) and "then" in o:
                assert o["then"] in labels, (sid, o["then"])
        if "say" in st and k[0] == "say":
            assert len(st["say"]) <= 330, (sid, st["say"][:50])
    assert ends > 0, sid


def write(name, data):
    path = os.path.join(OUT, name)
    with open(path, "w") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return path


def main():
    every = {}
    for mod in (rites, sacred, trades, scenes, exempla):
        for sid, s in mod.SCENES.items():
            assert sid not in every, sid
            check_scene(sid, s)
            every[sid] = s
    for rid, r in rites.RITES.items():
        for age in AGES:
            assert age in r["ages"], (rid, age)
            assert f"{rid}_{age}" in rites.SCENES, (rid, age)
    for job, j in trades.JOBS.items():
        assert j[1] in every or any(k.startswith(j[1] + "_") for k in every), (job, j)
    for sp in SPOTS:
        assert sp["scene"] in every or any(k.startswith(sp["scene"] + "_") for k in every), sp
    write("activities.json", {"about": "Where and when to do things in the city of Rome (tools/make_rome_activities.py).",
                              "room": ROOM, "spots": SPOTS, "temples": TEMPLES, "offering_ages": OFFERING_AGES})
    write("rites.json", {"about": "The recurring rites, in every age (tools/rome_acts/rites.py).", "rites": rites.RITES,
                         "scenes": rites.SCENES})
    write("sacred.json", {"about": "Rites done exactly (tools/rome_acts/sacred.py).", "scenes": sacred.SCENES})
    write("trades.json", {"about": "Work, the market, dice and money (tools/rome_acts/trades.py).", "jobs": trades.JOBS,
                          "scenes": trades.SCENES})
    write("scenes.json", {"about": "The city's other scenes (tools/rome_acts/scenes.py).", "scenes": scenes.SCENES})
    write("exempla.json", {"about": "The heroes' stories, played where they happened (tools/rome_acts/exempla.py).",
                           "exempla": exempla.EXEMPLA, "scenes": exempla.SCENES})
    write("quests.json", {"about": "The regulars' stories across the ages (tools/rome_acts/quests.py).", "quests": quests.QUESTS})
    write("collections.json", {"about": "What you gather in Rome, and what each set brings back to the Nexus.",
                               "sets": collections.SETS})
    print("%d scenes, %d rites, %d jobs, %d spots, %d quests" % (len(every), len(rites.RITES), len(trades.JOBS), len(SPOTS),
                                                                 len(quests.QUESTS)))


if __name__ == "__main__":
    main()
