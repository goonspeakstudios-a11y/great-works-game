"""Helpers for writing the scenes of the city of Rome (scripts/hall/urbs_scene.gd reads them).

Each helper returns one step as a dict. A scene is scene(title, where, *steps). Amounts of money
are written as they were in 280 BC (the Standing turns them into each age's coin and prices).
"""

AGES = ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]


def say(t):
    return {"say": t}


def ask(t, *options):
    assert 1 <= len(options) <= 4, t
    return {"ask": t, "options": list(options)}


def opt(text, say=None, then=None, need=None, **fx):
    o = {"text": text}
    if say:
        o["say"] = say
    if then:
        o["then"] = then
    if need:
        o["need"] = need
    o.update(fx)
    return o


def end(t):
    return {"end": t}


def label(n):
    return {"label": n}


def go(n):
    return {"go": n}


def rite(t, order, wrong, strict=True, restart=None, slack=None, done=None):
    r = {"rite": t, "order": order, "wrong": wrong, "strict": strict}
    if restart:
        r["restart"] = restart
    if slack:
        r["slack"] = slack
    if done:
        r["done"] = done
    return r


def hold(t, secs=3.0, done=None):
    r = {"hold": t, "secs": secs}
    if done:
        r["done"] = done
    return r


def still(t, secs=5.0, broke=None, done=None):
    r = {"still": t, "secs": secs}
    if broke:
        r["broke"] = broke
    if done:
        r["done"] = done
    return r


def timing(t, hits=3, speed=1.0, zone=0.18, miss=None, done=None, good=None, spare=2):
    r = {"timing": t, "hits": hits, "speed": speed, "zone": zone, "spare": spare}
    if miss:
        r["miss"] = miss
    if done:
        r["done"] = done
    if good:
        r["good"] = good
    return r


def typing(text, secs=40, good=None, fair=None, bad=None):
    r = {"type": text, "secs": secs}
    for k, v in (("good", good), ("fair", fair), ("bad", bad)):
        if v:
            r[k] = v
    return r


def pick(q, options, right, yes=None, no=None):
    r = {"pick": q, "options": options, "right": right}
    if yes:
        r["yes"] = yes
    if no:
        r["no"] = no
    return r


def gain(say=None, **fx):
    r = {"gain": fx}
    if say:
        r["line"] = say
    return r


def pay(n, els=None, short=None):
    r = {"pay": n}
    if els:
        r["else"] = els
    if short:
        r["short"] = short
    return r


def wage(n, per=0, say=None):
    r = {"wage": n, "per": per}
    if say:
        r["line"] = say
    return r


def iff(cond, to):
    return {"if": cond, "to": to}


def play(game, win=None, lose=None, say=None, **opts):
    r = {"play": game, "opts": opts}
    if win:
        r["win"] = win
    if lose:
        r["lose"] = lose
    if say:
        r["line"] = say
    return r


def hour(h):
    return {"hour": h}


def errand(pay, what):
    return {"errand": {"pay": pay, "what": what}}


def ride(key):
    """A ride across the city to the place the scene's {a}, {b} or {c} names (given by the hall's
    `resolve_ride`: the walk done in a fade, an hour of the day gone)."""
    return {"ride": key}


def scene(title, where, *steps, **extra):
    s = {"title": title, "where": where, "steps": list(steps)}
    s.update(extra)
    return s
