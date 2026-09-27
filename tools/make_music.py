"""Render the game's music and sounds from code into assets/music/*.wav (no samples, no downloads).

Every zone has its own track: the Shore's is slow, dark and grand (a low drone, slow
minor chords, distant bells triggered in-game); Porphyry's Sicily is warmer, a plucked
lyre (a simulated string, Karplus-Strong) over a soft drone in the Dorian mode; Aristotle's
Lyceum is a bright morning, pan pipes in the Phrygian mode over a walking bass. The Nexus,
the broken realm above every world, is a slow prelude in C minor: glass chimes playing
falling broken chords over a deep plucked bass, a misty pad and a wordless choir.
A place's track is written as layers (stems) of the same length that loop in step, so the
game can bring them back one at a time as the place is restored; each place also has its
"ghost", the faint echo of its tune heard while the place is lost to the world.
Ambient loops give each place its sound: waves, wind, fire, cicadas, a fountain, birds, a stream,
and the void's breath around the Nexus.
Reverb is added in-game on the Music bus, so these files are dry. Loops are seamless:
drone partials fit the loop exactly, tails past the end fold back to the start, and
noise loops crossfade their seam.

Rome and the Greek places still to come have their tracks here too: Rome (a cornu, the
water organ, a tibia and the legion's drum), Troy (a phorminx to the hexameter), the theatre
(the aulos and a chorus, in the mourning Mixolydian), Lesbos (Sappho's barbitos to the Sapphic
stanza), Alexandria (the tetraktys on a kithara, in pure ratios) and the Academy (the
enharmonic quarter tones, the Sirens of Er); and their sounds: a crowd, the arena, rain, oars,
a loom, hooves, a flock's bells, crickets, a cave's drips, gulls, an owl and the horn call.
Round 2: Helicon (Hesiod), Sardis (Herodotus), the Kerameikos (Thucydides) and Ephesus (the
Pre-Socratics); the forge, sheep, the dead in the underworld, and the salpinx.

Usage: C:\\Python314\\python.exe tools/make_music.py [name ...]   (no names: everything)
"""
from __future__ import annotations

import array
import logging
import math
import random
import sys
import wave
from collections.abc import Callable
from pathlib import Path

logger = logging.getLogger(__name__)

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "music"
TAU = 2 * math.pi
TABLE_SIZE = 4096
SINE = [math.sin(TAU * i / TABLE_SIZE) for i in range(TABLE_SIZE)]

# Module 1 (How to Read and Argue): sparse and quiet, music to think to.
E1 = {
    "loop_seconds": 48,
    "drone": [(73.42, 0.16), (73.72, 0.10), (110.0, 0.05)],  # D2, a slow beat, A2
    "drone_harmonics": 4,
    "chords": [  # D minor, B flat, G minor, A: one every loop/4 seconds
        [146.83, 174.61, 220.00],
        [116.54, 146.83, 174.61],
        [98.00, 146.83, 196.00],
        [110.00, 138.59, 164.81],
    ],
    "pad_level": 0.055,
    "attack": 4.0,
    "release": 7.0,
}


def fit(freq: float, seconds: float) -> float:
    """Nudge a frequency so a whole number of cycles fits the loop (no click at the seam)."""
    return round(freq * seconds) / seconds


def osc(buf: list[float], freq: float, level: float, start: int, env: Callable[[int], float]) -> None:
    """Add a sine at freq into buf from sample `start`, shaped by env(sample_index)."""
    step = freq * TABLE_SIZE / RATE
    phase = 0.0
    for n in range(start, len(buf)):
        e = env(n - start)
        if e < 0:
            break
        if e:
            buf[n] += SINE[int(phase) % TABLE_SIZE] * level * e
        phase += step


def render_loop(spec: dict) -> list[float]:
    secs = spec["loop_seconds"]
    total = secs * RATE
    tail = int((spec["attack"] + spec["release"] + secs / 4) * RATE)
    buf = [0.0] * (total + tail)
    # Drone: band-limited saw from whole harmonics, each fitted to the loop.
    for freq, level in spec["drone"]:
        for k in range(1, spec["drone_harmonics"] + 1):
            osc(buf, fit(freq * k, secs), level / (k * k), 0, lambda n: 1.0 if n < total else -1)
    # Pads: each chord swells in, holds, and fades while the next one arrives.
    span = secs / len(spec["chords"])
    att, rel = spec["attack"] * RATE, spec["release"] * RATE
    hold = span * RATE
    for i, chord in enumerate(spec["chords"]):
        start = int(i * span * RATE)

        def env(n: int, att: float = att, hold: float = hold, rel: float = rel) -> float:
            if n < att:
                return n / att
            if n < hold:
                return 1.0
            if n < hold + rel:
                return 1.0 - (n - hold) / rel
            return -1

        for f in chord:
            for mult, lvl, detune in ((1, 1.0, 0.0), (1, 0.6, 0.35), (2, 0.18, 0.0), (3, 0.07, 0.0)):
                osc(buf, f * mult + detune, spec["pad_level"] * lvl, start, env)
    # Fold everything past the loop end back onto the start.
    out = buf[:total]
    for n in range(total, len(buf)):
        out[n - total] += buf[n]
    return out


def pluck(buf: list[float], freq: float, level: float, start: int, seconds: float, rng: random.Random,
          brightness: float = 0.5, decay: float = 0.996, release: float = 0.0) -> None:
    """A plucked string (Karplus-Strong): a burst of noise that rings at freq and fades. A long,
    low note still ringing when it stops can fade over its last `release` seconds, so it does
    not end in a click."""
    period = max(2, int(RATE / freq))
    string = [rng.uniform(-1, 1) for _ in range(period)]
    for _ in range(int(2 + (1 - brightness) * 4)):  # softer attack: smooth the burst first
        string = [(string[i] + string[i - 1]) * 0.5 for i in range(period)]
    count, fade = int(seconds * RATE), int(release * RATE)
    for n in range(count):
        i = n % period
        out = string[i]
        string[i] = decay * 0.5 * (string[i] + string[(i + 1) % period])
        if start + n < len(buf):
            buf[start + n] += out * (level if count - n > fade else level * (count - n) / fade)


# Porphyry's Sicily: a lyre in A Dorian over a soft drone, phrases with rests between.
SICILY_SCALE = [220.0, 246.94, 261.63, 293.66, 329.63, 369.99, 392.0, 440.0, 493.88, 523.25]


def _centred(samples: list[float]) -> list[float]:
    """Take out the offset many plucked notes leave (the loop's mean), so it sits on zero."""
    mean = sum(samples) / max(1, len(samples))
    return [x - mean for x in samples]


def _fold(buf: list[float], total: int) -> list[float]:
    """Fold everything past the loop end back onto the start, so the loop has no seam."""
    out = buf[:total]
    for n in range(total, len(buf)):
        out[n - total] += buf[n]
    return out


def render_sicily(seconds: int = 48, seed: int = 11) -> dict[str, list[float]]:
    """Porphyry's Sicily in three layers: the drone, the lyre, and the low notes under it."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 4 * RATE) for k in ("drone", "lyre", "low")}
    for freq, level in ((110.0, 0.05), (164.81, 0.03), (220.0, 0.012)):
        f = fit(freq, seconds)
        osc(stems["drone"], f, level, 0, lambda n: 1.0 if n < total else -1)
        osc(stems["drone"], fit(f * 2, seconds), level * 0.25, 0, lambda n: 1.0 if n < total else -1)
    t = 0.6
    step = 4
    while t < seconds - 3.0:
        for k in range(rng.randint(4, 7)):  # a phrase: a gentle walk up and down the mode
            step = max(0, min(len(SICILY_SCALE) - 1, step + rng.choice([-2, -1, -1, 1, 1, 2])))
            last = k == 6 or rng.random() < 0.15
            pluck(stems["lyre"], SICILY_SCALE[step], 0.2 if not last else 0.24, int(t * RATE), 3.0, rng)
            if rng.random() < 0.25:  # sometimes a low note under it
                pluck(stems["low"], SICILY_SCALE[step] / 2, 0.12, int(t * RATE), 3.0, rng, 0.3)
            t += rng.choice([0.45, 0.6, 0.6, 0.9]) + (0.8 if last else 0.0)
            if last:
                break
        t += rng.uniform(1.4, 2.6)  # rest between phrases
    return {k: _fold(v, total) for k, v in stems.items()}


# Aristotle's Lyceum, a bright morning in Athens: a syrinx (pan pipes) in E Phrygian over a
# light drone, with a low plucked note walking underneath at an unhurried pace.
ATHENS_SCALE = [329.63, 349.23, 392.0, 440.0, 493.88, 523.25, 587.33, 659.26, 698.46, 783.99]


def pipe(buf: list[float], freq: float, level: float, start: int, seconds: float, rng: random.Random,
         attack: float = 0.06) -> None:
    """A breathy pipe note: a sine with slow vibrato and a little air, swelling in and out."""
    total = int(seconds * RATE)
    phase = 0.0
    air = 0.0
    for n in range(total):
        if start + n >= len(buf):
            break
        t = n / RATE
        env = min(1.0, n / (attack * RATE)) * min(1.0, (total - n) / (max(0.12, attack) * RATE))
        vib = 1.0 + 0.006 * math.sin(TAU * 5.5 * t) * min(1.0, t / 0.4)
        phase += freq * vib * TABLE_SIZE / RATE
        air += (rng.uniform(-1, 1) - air) * 0.3
        tone = SINE[int(phase) % TABLE_SIZE] + 0.25 * SINE[int(phase * 2) % TABLE_SIZE]
        buf[start + n] += (tone + air * 0.08) * level * env


def drum(buf: list[float], start: int, level: float, rng: random.Random, base: float = 68.0) -> None:
    """A marching drum: a low skin that drops in pitch as it settles, with a little slap.
    `base` is the pitch it settles to (lower for a bigger drum)."""
    for n in range(int(0.35 * RATE)):
        if start + n >= len(buf):
            break
        t = n / RATE
        f = base * (1.0 + 0.6 * math.exp(-t * 30.0))
        env = math.exp(-t * 9.0)
        slap = rng.uniform(-1, 1) * 0.25 * math.exp(-t * 40.0)
        buf[start + n] += (math.sin(TAU * f * t) * 0.9 + slap) * env * level


def render_athens(seconds: int = 48, seed: int = 23) -> dict[str, list[float]]:
    """Aristotle's Lyceum in four layers: the drone, the walking bass, the pipes, and the
    soldiers' drum (heard only once they are men again)."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 4 * RATE) for k in ("drone", "walk", "pipes", "drum")}
    for freq, level in ((82.41, 0.045), (123.47, 0.03), (164.81, 0.018)):  # E2, B2, E3
        f = fit(freq, seconds)
        osc(stems["drone"], f, level, 0, lambda n: 1.0 if n < total else -1)
        osc(stems["drone"], fit(f * 2, seconds), level * 0.2, 0, lambda n: 1.0 if n < total else -1)
    beat = seconds / 52  # an unhurried walking pace (about 65 steps a minute), fitted to the loop
    for k in range(0, 52, 2):  # the walk: a low note every other step
        pluck(stems["walk"], 123.47 if k % 4 == 0 else 82.41, 0.13, int(k * beat * RATE), 1.6, rng, 0.25)
    drum_rng = random.Random(seed + 1)
    for k in range(52):  # left, right: every step, the left a little heavier
        drum(stems["drum"], int(k * beat * RATE), 0.2 if k % 2 == 0 else 0.13, drum_rng)
    t = 1.2
    step = 4
    while t < seconds - 4.0:
        for k in range(rng.randint(3, 6)):  # a phrase on the pipe
            step = max(0, min(len(ATHENS_SCALE) - 1, step + rng.choice([-2, -1, 1, 1, 2, 3])))
            length = rng.choice([0.5, 0.75, 1.0, 1.5])
            pipe(stems["pipes"], ATHENS_SCALE[step], 0.16, int(t * RATE), length * 0.95, rng)
            t += length
        t += rng.uniform(2.0, 3.5)  # then quiet, and the walk goes on
    return {k: _fold(v, total) for k, v in stems.items()}


# The Nexus, the broken realm above every world: a slow prelude in C minor, 60 beats a minute,
# twelve bars in a 48 s loop. Six chords of 8 s, each sharing a note with the next: C minor,
# A flat, F minor, D flat, E (the one alien turn, its G sharp the A flat carried through) and
# G7 flat 9, which leads back to C minor across the loop point. The chords and tune are new.
# A glass chime's partials: (ratio to the note, level, decay per second).
CHIME_PARTIALS = ((1.0, 1.0, 1.4), (2.0, 0.28, 2.2), (2.76, 0.09, 3.2), (5.4, 0.03, 5.0))


def chime(buf: list[float], freq: float, level: float, start: int, seconds: float = 3.5) -> None:
    """A glass chime, like a soft bell: a few ringing partials that fade, stopped hard after
    `seconds` so a note does not run on to the end of the buffer."""
    limit = int(seconds * RATE)
    for mult, lvl, decay in CHIME_PARTIALS:
        osc(buf, freq * mult, level * lvl, start,
            lambda n, d=decay: -1 if n >= limit else math.exp(-d * n / RATE) * min(1.0, n / 60))


def choir(buf: list[float], freq: float, level: float, start: int, seconds: float, rng: random.Random,
          attack: float = 2.0, release: float = 2.5) -> None:
    """A wordless, dark "oo": three voices a hair apart, each with its own slow vibrato,
    swelling in and fading out."""
    total = int(seconds * RATE)
    voices = [(ratio, rng.uniform(0, TAU), rng.uniform(4.6, 5.4)) for ratio in (1.0, 1.0035, 0.9968)]
    for ratio, vib_phase, vib_rate in voices:
        phase = 0.0
        for n in range(total):
            if start + n >= len(buf):
                break
            t = n / RATE
            env = min(1.0, t / attack, (total - n) / (release * RATE))
            vib = 1.0 + 0.004 * math.sin(TAU * vib_rate * t + vib_phase)
            phase += freq * ratio * vib * TABLE_SIZE / RATE
            p = int(phase)
            s = SINE[p % TABLE_SIZE] + 0.30 * SINE[(2 * p) % TABLE_SIZE] + 0.12 * SINE[(3 * p) % TABLE_SIZE]
            buf[start + n] += s * env * level / 3


NEXUS_ROOTS = [65.41, 51.91, 43.65, 69.30, 82.41, 49.00]  # C2, A flat 1, F1, D flat 2, E2, G1
NEXUS_ARP = [  # five notes of each chord for the broken-chord figure; A flat 4 runs through chords 2-6
    [261.63, 311.13, 392.00, 523.25, 622.25],  # C minor
    [261.63, 311.13, 415.30, 523.25, 622.25],  # A flat
    [261.63, 349.23, 415.30, 523.25, 698.46],  # F minor
    [277.18, 349.23, 415.30, 554.37, 698.46],  # D flat
    [246.94, 329.63, 415.30, 493.88, 659.26],  # E (the alien turn)
    [246.94, 293.66, 349.23, 415.30, 493.88],  # G7 flat 9
]
NEXUS_FIGURE = [(4, 2, 3, 1, 2, 0, 1, None), (4, 2, 3, 1, 0, None, None, None)]  # a falling sigh
NEXUS_PADS = {
    "loop_seconds": 48, "drone": [], "drone_harmonics": 1,
    "chords": [[130.81, 196.00, 311.13], [103.83, 155.56, 261.63], [174.61, 207.65, 261.63],
               [138.59, 207.65, 349.23], [164.81, 246.94, 415.30], [98.00, 174.61, 246.94, 415.30]],
    "pad_level": 0.03, "attack": 3.0, "release": 5.0,
}
NEXUS_LINE = [  # the choir's held notes (start s, length s, Hz), each hanging over a change of chord
    (0.0, 10.0, 392.00), (10.0, 8.0, 415.30), (18.0, 4.0, 392.00),
    (22.0, 12.0, 349.23), (34.0, 8.0, 329.63), (42.0, 6.0, 415.30),
]
# The ghost's notes: C harmonic minor, C4 to E flat 5 (the ghost plays them an octave down).
NEXUS_SCALE = [261.63, 293.66, 311.13, 349.23, 392.0, 415.30, 493.88, 523.25, 587.33, 622.25]


def render_nexus(seconds: int = 48, seed: int = 53) -> dict[str, list[float]]:
    """The Nexus in five layers: the void breathing (drone), a deep plucked bass on each chord,
    a misty pad, the glass-chime broken chords (the heart of it) and the wordless choir."""
    rng = random.Random(seed)
    total = seconds * RATE
    span = seconds // len(NEXUS_ROOTS)  # 8 s a chord
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "bass", "arp", "voices")}
    # Drone: C2 against a slightly sharp C2 (a slow, uneasy beat), G2 and C3, breathing every 12 s.
    for freq, level in ((65.41, 0.05), (65.67, 0.035), (98.0, 0.02), (130.81, 0.012)):
        osc(stems["drone"], fit(freq, seconds), level, 0,
            lambda n: (0.75 + 0.25 * math.sin(TAU * n / (12 * RATE))) if n < total else -1)
    # Bass: a dark pluck on each root, a soft octave 4 s later, and a sine under it for weight.
    limit = span * RATE
    for c, root in enumerate(NEXUS_ROOTS):
        s = c * span * RATE
        pluck(stems["bass"], root, 0.24, s, 7.8, rng, 0.2, 0.998, release=0.3)
        pluck(stems["bass"], root * 2, 0.08, s + 4 * RATE, 3.8, rng, 0.25, 0.997, release=0.3)
        osc(stems["bass"], root, 0.05, s, lambda n: -1 if n >= limit else
            math.exp(-0.25 * n / RATE) * min(1.0, n / 200, (limit - n) / 200))  # eased in and out
    # Arp: the falling figure on glass chimes, eighth notes; a few inner notes of each second bar
    # go missing, so the music itself has pieces lost.
    for c, voicing in enumerate(NEXUS_ARP):
        for bar, figure in enumerate(NEXUS_FIGURE):
            for k, idx in enumerate(figure):
                if idx is None or (bar == 1 and 0 < k < 4 and rng.random() < 0.15):
                    continue
                t = c * span + bar * 4 + k * 0.5 + rng.uniform(-0.01, 0.01)
                level = (0.12 if k == 0 else 0.085) * rng.uniform(0.9, 1.05)
                chime(stems["arp"], voicing[idx], level, max(0, int(t * RATE)))
    # Voices: each held note with a faint octave above, running 2 s on to fade under the next.
    for t0, length, f in NEXUS_LINE:
        choir(stems["voices"], f, 0.06, int(t0 * RATE), length + 2.0, rng)
        choir(stems["voices"], f * 2, 0.02, int(t0 * RATE), length + 2.0, rng)
    out = {k: _fold(v, total) for k, v in stems.items()}
    out["pad"] = render_loop(NEXUS_PADS)
    return {k: out[k] for k in ("drone", "bass", "pad", "arp", "voices")}


def render_ghost(scale: list[float], root: float, voice: str, seconds: int = 48, seed: int = 41) -> list[float]:
    """A place's tune as it is while the place is lost: its own mode an octave down, slow and
    sparse, each note doubled a little out of tune, over a cold drone that beats against itself."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 6 * RATE)
    for freq, level in ((root, 0.05), (root * 1.006, 0.045), (root * 2.0, 0.01)):
        osc(buf, fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    t = 2.0
    step = 3
    while t < seconds - 5.0:
        for _ in range(rng.randint(1, 3)):  # a fragment of the old tune
            step = max(0, min(len(scale) - 1, step + rng.choice([-2, -1, 1])))
            f = scale[step] / 2
            if voice == "pipe":
                length = rng.choice([1.8, 2.4, 3.0])
                pipe(buf, f, 0.12, int(t * RATE), length, rng, attack=0.5)
                pipe(buf, f * 1.007, 0.07, int((t + 0.05) * RATE), length, rng, attack=0.5)
            elif voice == "reed":  # a double pipe (tibia, aulos), sour and far off
                length = rng.choice([1.8, 2.4, 3.0])
                reed(buf, f, 0.1, int(t * RATE), length, rng, attack=0.4)
                reed(buf, f * 1.007, 0.06, int((t + 0.05) * RATE), length, rng, attack=0.4)
            elif voice == "chime":  # the Nexus: a music box at the bottom of the sea
                length = rng.choice([1.2, 1.8, 2.4])
                chime(buf, f, 0.16, int(t * RATE), 5.0)
                chime(buf, f * 1.007, 0.09, int((t + 0.04) * RATE), 5.0)
            else:
                length = 1.6
                pluck(buf, f, 0.18, int(t * RATE), 5.0, rng, 0.2, 0.998)
                pluck(buf, f * 1.007, 0.1, int((t + 0.03) * RATE), 5.0, rng, 0.2, 0.998)
            t += length
        t += rng.uniform(3.5, 6.5)  # long silences
    return _fold(buf, total)


def render_birds(seconds: int = 14, seed: int = 29) -> list[float]:
    """Songbirds in the plane trees: short whistles that rise or fall, now and then."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out = [0.0] * (total + fade)
    t = 0.3
    while t < seconds + 0.5:
        base = rng.uniform(2200.0, 3800.0)
        for k in range(rng.randint(2, 5)):  # a little run of notes
            length = rng.uniform(0.06, 0.16)
            sweep = rng.uniform(-900.0, 900.0)
            start = int((t + k * (length + 0.04)) * RATE)
            phase = 0.0
            for n in range(int(length * RATE)):
                if start + n >= len(out):
                    break
                f = base + sweep * n / (length * RATE)
                phase += f * TABLE_SIZE / RATE
                env = math.sin(math.pi * n / (length * RATE)) ** 0.7
                out[start + n] += SINE[int(phase) % TABLE_SIZE] * env * 0.5
        t += rng.uniform(1.2, 3.6)
    return _seam(out, total, fade)


def render_stream(seconds: int = 12, seed: int = 31) -> list[float]:
    """The Ilissos: a steady, wide trickle over stones."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out, a, b, c = [], 0.0, 0.0, 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        a += (x - a) * 0.35
        b += (a - b) * 0.1
        c += (rng.uniform(0.6, 1.0) - c) * 0.002  # slow unevenness in the flow
        out.append((a - b) * c)
    return _seam(out, total, fade)


def _seam(out: list[float], total: int, fade: int) -> list[float]:
    """Crossfade the extra tail onto the start so a noise loop has no seam."""
    for n in range(fade):
        t = n / fade
        out[n] = out[n] * t + out[total + n] * (1 - t)
    return out[:total]


def render_waves(seconds: int = 16, seed: int = 5) -> list[float]:
    """Surf far below the cliff: low rumble and hiss that swell and fall back."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    out, lo, hi = [], 0.0, 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.02
        hi += (x - hi) * 0.25
        swell = math.sin(math.pi * ((n / RATE) % 8.0) / 8.0) ** 3  # one wave every 8 s
        out.append(lo * (0.5 + 0.9 * swell) + (x - hi) * 0.12 * swell)
    return _seam(out, total, fade)


def render_void(seconds: int = 16, seed: int = 59) -> list[float]:
    """The void's breath around the Nexus (not music): a deep rumble that swells and sinks
    every 8 s, and now and then a far, glassy ping that beats against a copy of itself."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    out, lo, lo2 = [], 0.0, 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.01
        lo2 += (lo - lo2) * 0.002
        out.append((lo - lo2) * (0.6 + 0.4 * math.sin(TAU * n / (8 * RATE))))  # 8 s divides the loop
    out = _seam(out, total, fade)
    # The pings are pure tones, so they fold across the loop point instead of being crossfaded.
    pings = [0.0] * (total + 6 * RATE)
    first = rng.uniform(0.5, 2.0)
    t = first
    while t < seconds + first - 2.5:  # the gap across the loop point is at least 2.5 s too
        f = rng.uniform(2000.0, 4000.0)
        for freq, level in ((f, 0.05), (f * 1.003, 0.03)):
            osc(pings, freq, level, int(t * RATE),
                lambda n: -1 if n >= 4 * RATE else math.exp(-1.2 * n / RATE) * min(1.0, n / 40))
        t += rng.uniform(2.5, 6.0)
    return [a + b for a, b in zip(out, _fold(pings, total))]


def render_cicadas(seconds: int = 12, seed: int = 7) -> list[float]:
    """High buzzing pulses in bursts, three insects at different rates."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out = [0.0] * (total + fade)
    for rate, level, offset in ((42.0, 0.6, 0.0), (36.0, 0.45, 3.1), (47.0, 0.35, 6.4)):
        a = b = 0.0
        for n in range(total + fade):
            t = n / RATE
            x = rng.uniform(-1, 1)
            a += (x - a) * 0.75
            b += (a - b) * 0.18
            band = a - b  # roughly 4-6 kHz
            burst = max(0.0, math.sin(TAU * (t + offset) / 6.0)) ** 0.5  # 6 s divides the 12 s loop: no seam
            pulse = max(0.0, math.sin(TAU * rate * t)) ** 6
            out[n] += band * pulse * burst * level
    return _seam(out, total, fade)


def render_fire(seconds: int = 10, seed: int = 9) -> list[float]:
    """A soft roar with crackles and pops."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out, lo = [], 0.0
    pop = 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.05
        if rng.random() < 0.0009:
            pop = rng.uniform(0.4, 1.0)
        pop *= 0.93
        out.append(lo * 0.5 + x * pop)
    return _seam(out, total, fade)


def render_fountain(seconds: int = 10, seed: int = 13) -> list[float]:
    """Water trickling into a basin: bubbling, fluttering noise."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out, a, b, flutter = [], 0.0, 0.0, 0.5
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        a += (x - a) * 0.3
        b += (a - b) * 0.06
        if n % 180 == 0:
            flutter = rng.uniform(0.2, 1.0)
        out.append((a - b) * flutter)
    return _seam(out, total, fade)


def render_croak(seed: int = 17) -> list[float]:
    """A fat toad's croak: two low, buzzing grunts."""
    rng = random.Random(seed)
    out = [0.0] * int(0.75 * RATE)
    lo = 0.0
    for start, length in ((0.0, 0.22), (0.3, 0.34)):
        s0, n_len = int(start * RATE), int(length * RATE)
        for n in range(n_len):
            t = n / RATE
            f = 78.0 - 18.0 * (n / n_len)
            pulse = 1.0 if math.sin(TAU * f * t) > 0.6 else -0.25  # a buzzy, reedy wave
            env = math.sin(math.pi * n / n_len) ** 0.6 * (0.7 + 0.3 * math.sin(TAU * 22 * t))
            lo += (pulse + rng.uniform(-0.3, 0.3) - lo) * 0.18
            out[s0 + n] += lo * env
    return out


def render_wind(seconds: int, seed: int = 3) -> list[float]:
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    raw = [rng.uniform(-1, 1) for _ in range(total + fade)]
    out, lo, band = [], 0.0, 0.0
    for n, x in enumerate(raw):
        sweep = 0.035 + 0.02 * math.sin(TAU * n / (total / 3))  # slow gusts
        lo += (x - lo) * sweep
        band += (lo - band) * 0.004
        out.append((lo - band) * 0.9)
    for n in range(fade):  # crossfade the extra second onto the start
        t = n / fade
        out[n] = out[n] * t + out[total + n] * (1 - t)
    return out[:total]


def render_bell(seconds: float = 7.0, base: float = 587.33) -> list[float]:
    total = int(seconds * RATE)
    out = [0.0] * total
    for mult, level, decay in ((1, 0.5, 1.6), (2.76, 0.22, 2.4), (5.4, 0.1, 3.5), (8.93, 0.05, 5.0)):
        osc(out, base * mult, level, 0, lambda n, d=decay: math.exp(-d * n / RATE) * min(1.0, n / 40))
    return out


# ---------- instruments for the later places ----------

# A double reed (the Roman tibia, the Greek aulos): odd partials strong, like a shawm.
REED_PARTIALS = ((1, 1.0), (2, 0.3), (3, 0.55), (4, 0.15), (5, 0.3), (7, 0.12))


def reed(buf: list[float], freq: float, level: float, start: int, seconds: float, rng: random.Random,
         attack: float = 0.08, bend: float = 0.0) -> None:
    """A reed pipe note: a nasal, buzzing tone with breath in it. `bend` slides into the
    note from that fraction off pitch (the aulos player's bent notes)."""
    total = int(seconds * RATE)
    tail = max(0.1, attack) * RATE
    phase = 0.0
    air = 0.0
    (k1, a1), (k2, a2), (k3, a3), (k4, a4), (k5, a5), (k6, a6) = REED_PARTIALS
    for n in range(total):
        if start + n >= len(buf):
            break
        t = n / RATE
        env = min(1.0, n / (attack * RATE), (total - n) / tail)
        glide = 1.0 + bend * math.exp(-t * 12.0)
        vib = 1.0 + 0.005 * math.sin(TAU * 5.0 * t) * min(1.0, t / 0.5)
        phase += freq * glide * vib * TABLE_SIZE / RATE
        p = int(phase)
        tone = (a1 * SINE[(k1 * p) % TABLE_SIZE] + a2 * SINE[(k2 * p) % TABLE_SIZE] + a3 * SINE[(k3 * p) % TABLE_SIZE]
                + a4 * SINE[(k4 * p) % TABLE_SIZE] + a5 * SINE[(k5 * p) % TABLE_SIZE] + a6 * SINE[(k6 * p) % TABLE_SIZE])
        air += (rng.uniform(-1, 1) - air) * 0.5
        buf[start + n] += (tone * 0.45 + air * 0.05) * level * env


def brass(buf: list[float], freq: float, level: float, start: int, seconds: float,
          attack: float = 0.12, release: float = 0.3) -> None:
    """A Roman cornu or tuba: eight harmonics that grow brighter as the breath builds, and a
    small scoop up to the pitch as the lips find it."""
    total = int(seconds * RATE)
    phase = 0.0
    for n in range(total):
        if start + n >= len(buf):
            break
        t = n / RATE
        env = min(1.0, t / attack, (total - n) / (release * RATE))
        scoop = 1.0 - 0.03 * math.exp(-t * 25.0)
        phase += freq * scoop * TABLE_SIZE / RATE
        p = int(phase)
        w = math.sqrt(max(0.0, env))  # the brightness: each harmonic up is weighted by w once more
        s, g = 0.0, 1.0
        for k in range(1, 9):
            s += SINE[(k * p) % TABLE_SIZE] * g / k
            g *= w
        buf[start + n] += s * 0.5 * level * env


# The hydraulis (the Roman water organ): a few ranks of flue pipes, the air trembling a little
# with the water pressure under it.
ORGAN_PARTIALS = ((1, 1.0), (2, 0.5), (3, 0.25), (4, 0.18), (6, 0.08))


def organ(buf: list[float], freq: float, level: float, start: int, seconds: float,
          attack: float = 0.12, release: float = 0.4) -> None:
    total = int(seconds * RATE)
    phase = 0.0
    (k1, a1), (k2, a2), (k3, a3), (k4, a4), (k5, a5) = ORGAN_PARTIALS
    step = freq * TABLE_SIZE / RATE
    for n in range(total):
        if start + n >= len(buf):
            break
        t = n / RATE
        env = min(1.0, t / attack, (total - n) / (release * RATE)) * (1.0 + 0.04 * math.sin(TAU * 4.2 * t))
        phase += step
        p = int(phase)
        tone = (a1 * SINE[(k1 * p) % TABLE_SIZE] + a2 * SINE[(k2 * p) % TABLE_SIZE] + a3 * SINE[(k3 * p) % TABLE_SIZE]
                + a4 * SINE[(k4 * p) % TABLE_SIZE] + a5 * SINE[(k5 * p) % TABLE_SIZE])
        buf[start + n] += tone * 0.5 * level * env


def swell(buf: list[float], freq: float, level: float, start: int, seconds: float) -> None:
    """A pure tone that rises and falls away again (sin squared) over its whole length."""
    total = int(seconds * RATE)
    osc(buf, freq, level, start, lambda n: -1 if n >= total else math.sin(math.pi * n / total) ** 2)


def _phrases(rng: random.Random, seconds: float, first: float, scale: list[float], moves: list[int],
             lengths: list[float], rest: tuple[float, float], notes: tuple[int, int]):
    """The shape every melody here takes: short phrases that wander up and down a mode, with
    quiet between them. Yields (start s, length s, Hz)."""
    t = first
    step = len(scale) // 2
    while t < seconds - 4.0:
        for _ in range(rng.randint(*notes)):
            step = max(0, min(len(scale) - 1, step + rng.choice(moves)))
            length = rng.choice(lengths)
            yield t, length, scale[step]
            t += length
        t += rng.uniform(*rest)


# Rome: grand and martial, in D Mixolydian. A cornu breathes a low pedal, the hydraulis plays
# the chords, a tibia carries the tune, and the legion's drum keeps a quick step, with the horn
# call twice round the loop.
ROME_SCALE = [293.66, 329.63, 369.99, 392.00, 440.00, 493.88, 523.25, 587.33, 659.26, 739.99]
ROME_CHORDS = [  # D, G, C, D, A minor, G, E minor, C (C to D across the loop: the Mixolydian close)
    [146.83, 220.00, 293.66, 369.99], [196.00, 246.94, 293.66, 392.00], [130.81, 196.00, 261.63, 329.63],
    [146.83, 220.00, 293.66, 369.99], [110.00, 220.00, 261.63, 329.63], [196.00, 246.94, 293.66, 392.00],
    [164.81, 246.94, 329.63, 392.00], [130.81, 196.00, 261.63, 329.63],
]


def render_rome(seconds: int = 48, seed: int = 61) -> dict[str, list[float]]:
    """Rome in four layers: the cornu's pedal (drone), the water organ, the tibia, the march."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "organ", "tibia", "march")}
    for i in range(4):  # 14 s swells every 12 s: each fades out exactly as the next fades in
        brass(stems["drone"], 73.42, 0.09, i * 12 * RATE, 14.0, attack=2.0, release=2.0)
        brass(stems["drone"], 110.0, 0.045, i * 12 * RATE, 14.0, attack=2.0, release=2.0)
    span = seconds / len(ROME_CHORDS)
    for c, chord in enumerate(ROME_CHORDS):
        for f in chord:
            organ(stems["organ"], f, 0.05, int(c * span * RATE), span + 0.4, attack=0.15, release=0.4)
    for t, length, f in _phrases(rng, seconds, 1.5, ROME_SCALE, [-2, -1, -1, 1, 1, 2], [0.5, 0.75, 1.0, 1.5, 2.0],
                                 (2.0, 3.5), (3, 6)):
        reed(stems["tibia"], f, 0.13, int(t * RATE), length * 0.95, rng)
    beat = seconds / 80  # a hundred steps a minute
    drum_rng = random.Random(seed + 1)
    for k in range(80):
        drum(stems["march"], int(k * beat * RATE), 0.2 if k % 2 == 0 else 0.12, drum_rng, base=60.0)
    for t0 in (0.0, 24.0):  # the horn call: the cornu's third, fourth and sixth harmonics
        for dt, f, length in ((0.0, 220.26, 0.35), (0.45, 293.68, 0.35), (0.9, 440.52, 1.4)):
            brass(stems["march"], f, 0.16, int((t0 + dt) * RATE), length, attack=0.05, release=0.25)
    return {k: _fold(v, total) for k, v in stems.items()}


# Troy, Homer's song: a phorminx (the bard's lyre) in D (the Greek Hypophrygian), plucked to the
# dactylic hexameter (long short short, five times, then long long), over a bard's hum.
TROY_SCALE = [146.83, 164.81, 174.61, 196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23]
TROY_RECITE = [4, 4, 5, 3, 4]  # the note each of the five lines is chanted on


def render_troy(seconds: int = 48, seed: int = 67) -> dict[str, list[float]]:
    """Troy in four layers: the drone, the phorminx on the hexameter, the bard's hum, and the
    slow war drum of the camp (heard only once the soldiers are back)."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "phorminx", "voice", "drum")}
    for freq, level in ((73.42, 0.05), (110.0, 0.03), (146.83, 0.012)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    short = 0.4
    line = 24 * short  # 9.6 s: five lines to the loop
    drum_rng = random.Random(seed + 1)
    for li, recite in enumerate(TROY_RECITE):
        t = li * line
        drum(stems["drum"], int(t * RATE), 0.26, drum_rng, base=50.0)
        drum(stems["drum"], int((t + line / 2) * RATE), 0.16, drum_rng, base=50.0)
        choir(stems["voice"], TROY_SCALE[recite] / 2, 0.07, int(t * RATE), line + 1.5, rng, attack=1.5, release=2.0)
        for foot in range(6):
            last = foot == 5
            spondee = last or (foot != 4 and rng.random() < 0.3)
            beats = (2, 2) if spondee else (2, 1, 1)
            for b, units in enumerate(beats):
                step = recite
                if b == 0 and not last:
                    step = min(len(TROY_SCALE) - 1, recite + rng.choice([0, 1, 1, 2]))  # the rise on the beat
                elif last:
                    step = (recite - 2, 0)[b]  # the line falls home to D
                elif rng.random() < 0.3:
                    step = max(0, recite - 1)
                pluck(stems["phorminx"], TROY_SCALE[step], 0.22 if b == 0 else 0.14, int(t * RATE), 2.5, rng, 0.65, 0.995)
                t += units * short
    return {k: _fold(v, total) for k, v in stems.items()}


# The theatre of Dionysus: tragedy in the Greek Mixolydian (B to B on the white notes), the mode
# Plato calls the mourning one. An aulos over its own drone pipe, a chorus of men, and a slow
# drum like a heart.
THEATRE_SCALE = [246.94, 261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, 587.33]
THEATRE_STROPHE = [(0.0, 5.0, 123.47), (5.0, 7.0, 130.81), (12.0, 5.0, 110.00), (17.0, 7.0, 123.47)]


def render_theatre(seconds: int = 48, seed: int = 71) -> dict[str, list[float]]:
    """The theatre in four layers: the aulos's drone pipe, the aulos's tune (bent into its notes),
    the chorus (the strophe, then the antistrophe on the same notes) and the heart drum."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "aulos", "chorus", "drum")}
    for i in range(4):
        reed(stems["drone"], 123.47, 0.07, i * 12 * RATE, 14.0, rng, attack=2.0)
    for t, length, f in _phrases(rng, seconds, 2.0, THEATRE_SCALE, [-2, -1, -1, 1, 2], [0.75, 1.0, 1.5, 2.0, 3.0],
                                 (1.5, 3.0), (2, 5)):
        reed(stems["aulos"], f, 0.13, int(t * RATE), length * 0.95, rng, attack=0.1,
             bend=rng.choice([0.0, 0.0, -0.03, 0.02]))
    for half in (0.0, 24.0):
        for t0, length, f in THEATRE_STROPHE:
            choir(stems["chorus"], f, 0.07, int((half + t0) * RATE), length + 1.5, rng, attack=0.8, release=1.5)
            choir(stems["chorus"], f * 2, 0.025, int((half + t0) * RATE), length + 1.5, rng, attack=0.8, release=1.5)
    drum_rng = random.Random(seed + 1)
    beat = seconds / 32  # forty beats a minute
    for k in range(32):
        drum(stems["drum"], int(k * beat * RATE), 0.2, drum_rng, base=48.0)
        drum(stems["drum"], int((k * beat + 0.28) * RATE), 0.11, drum_rng, base=48.0)
    return {k: _fold(v, total) for k, v in stems.items()}


# Sappho's Lesbos, in the Aeolian mode (named for her own Aeolian Greeks): a barbitos, the
# long-armed low lyre she played, to the Sapphic stanza (three lines of long short long long
# long short short long short long long, then long short short long long), with a voice.
LESBOS_SCALE = [164.81, 174.61, 196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00]
SAPPHIC = [2, 1, 2, 2, 2, 1, 1, 2, 1, 2, 2]  # a line, in short units
ADONIC = [2, 1, 1, 2, 2]


def render_lesbos(seconds: int = 48, seed: int = 73) -> dict[str, list[float]]:
    """Lesbos in four layers: a soft drone, the barbitos on two Sapphic stanzas, a woman's voice
    on the long syllables, and low notes at the start of each line."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "barbitos", "voice", "low")}
    for freq, level in ((110.0, 0.04), (164.81, 0.02)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    unit = seconds / 2 / 70  # a stanza (three lines and the short one, each with a rest of 2) in 24 s
    t = 0.0
    step = 3
    for _stanza in range(2):
        for line in (SAPPHIC, SAPPHIC, SAPPHIC, ADONIC):
            pluck(stems["low"], (110.0, 82.41)[rng.random() < 0.3], 0.12, int(t * RATE), 3.0, rng, 0.25, 0.998)
            for k, units in enumerate(line):
                final = k == len(line) - 1
                step = 3 if final else max(0, min(len(LESBOS_SCALE) - 1, step + rng.choice([-2, -1, 1, 1, 2])))
                f = LESBOS_SCALE[step]
                pluck(stems["barbitos"], f, 0.2 if units == 2 else 0.15, int(t * RATE), 3.0, rng, 0.35, 0.998)
                if units == 2:
                    choir(stems["voice"], f * 2, 0.045, int(t * RATE), units * unit + 0.3, rng, attack=0.12, release=0.3)
                t += units * unit
            t += 2 * unit
    out = {k: _fold(v, total) for k, v in stems.items()}
    for k in ("barbitos", "low"):  # so many low plucks leave the strings off centre: take it out
        out[k] = _centred(out[k])
    return out


# Euclid's Alexandria: music to think to, tuned in pure Pythagorean ratios on F. A kithara plays
# the tetraktys (the numbers 1, 2, 3, 4 as the harmonics of a note: octave, fifth, octave) in
# groups of one, two, three and four; a monochord sounds the consonances of Euclid's own
# "Division of the Canon"; a low note marks each quarter.
PYTHAGOREAN = [1.0, 9 / 8, 81 / 64, 4 / 3, 3 / 2, 27 / 16, 243 / 128, 2.0]
ALEX_SCALE = [174.61 * r for r in PYTHAGOREAN] + [349.23 * r for r in PYTHAGOREAN[1:4]]
ALEX_ROOTS = [174.61, 174.61 * 3 / 2, 174.61 * 4 / 3, 174.61]  # F, C, B flat, F: one per 12 s
CANON = [(1.0, 2.0), (1.0, 3 / 2), (1.0, 4 / 3), (1.0, 2.0), (1.0, 9 / 8), (1.0, 3.0), (1.0, 4 / 3), (1.0, 2.0)]


def render_alexandria(seconds: int = 48, seed: int = 79) -> dict[str, list[float]]:
    """Alexandria in four layers: the drone, the kithara's tetraktys, the monochord, the low F."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "kithara", "monochord", "low")}
    for freq, level in ((87.31, 0.045), (87.31 * 1.5, 0.025)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    block = seconds / len(ALEX_ROOTS)
    for b, root in enumerate(ALEX_ROOTS):
        for g, size in enumerate((1, 2, 3, 4)):
            for k in range(size):
                t = b * block + g * 2.6 + k * 0.4
                pluck(stems["kithara"], root * (1, 2, 3, 4)[k], 0.18 if k == 0 else 0.13, int(t * RATE), 3.0, rng, 0.6, 0.996)
        pluck(stems["low"], 87.31, 0.14, int(b * block * RATE), 5.0, rng, 0.2, 0.998, release=0.5)
    span = seconds / len(CANON)
    for i, (a, b) in enumerate(CANON):
        for r in (a, b):
            osc(stems["monochord"], 174.61 * r, 0.05, int((i * span + 0.5) * RATE),
                lambda n: -1 if n >= 5 * RATE else math.exp(-0.7 * n / RATE) * min(1.0, n / 300))
    return {k: _fold(v, total) for k, v in stems.items()}


# Plato's Academy, high and strange: the enharmonic genus, whose tetrachords step by quarter
# tones (E, E a quarter up, F, then a leap to A). A pipe wanders it; the eight Sirens of the
# myth of Er each hold one note and together sound one harmony; the three Fates sing.
QUARTER = 2 ** (1 / 24)
ACADEMY_SCALE = [329.63, 329.63 * QUARTER, 349.23, 440.00, 493.88, 493.88 * QUARTER, 523.25, 659.26,
                 659.26 * QUARTER, 698.46]
SIRENS = [164.81, 247.22, 329.63, 439.51, 494.44, 659.26, 988.88, 1318.51]
FATES = [(0.0, 16.0, 329.63), (16.0, 16.0, 349.23), (32.0, 16.0, 329.63 * QUARTER)]


def render_academy(seconds: int = 48, seed: int = 83) -> dict[str, list[float]]:
    """The Academy in four layers: the drone, the enharmonic pipe, the Sirens, the Fates."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 21 * RATE) for k in ("drone", "pipe", "spheres", "voices")}
    for freq, level in ((82.41, 0.04), (123.47, 0.025)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    for t, length, f in _phrases(rng, seconds, 2.5, ACADEMY_SCALE, [-1, -1, 1, 1, 2, -3], [1.0, 1.5, 2.0, 3.0],
                                 (2.5, 4.0), (2, 4)):
        pipe(stems["pipe"], f, 0.12, int(t * RATE), length * 0.95, rng, attack=0.2)
    for k, f in enumerate(SIRENS):  # each Siren swells for 20 s, one entering every 6 s
        swell(stems["spheres"], f, 0.035 / (1.0 + k * 0.25), k * 6 * RATE, 20.0)
    for t0, length, f in FATES:
        choir(stems["voices"], f, 0.05, int(t0 * RATE), length + 2.0, rng, attack=3.0, release=3.0)
        choir(stems["voices"], f / 2, 0.02, int(t0 * RATE), length + 2.0, rng, attack=3.0, release=3.0)
    return {k: _fold(v, total) for k, v in stems.items()}


# Hesiod's Helicon: the shepherd on the mountain where the Muses found him, in the Hypolydian
# (F with a raised fourth). A shepherd's pipe, low and slow; the nine Muses in three parts; a
# lyre's low notes; a drone like the wind over the ridge.
HELICON_SCALE = [174.61, 196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00, 440.00]
MUSES = [  # (start s, length s, three notes): the Muses' chords, each part held by three voices
    (0.0, 12.0, (349.23, 440.00, 523.25)), (12.0, 12.0, (329.63, 392.00, 523.25)),
    (24.0, 12.0, (293.66, 440.00, 587.33)), (36.0, 12.0, (329.63, 392.00, 493.88)),
]


def render_helicon(seconds: int = 48, seed: int = 151) -> dict[str, list[float]]:
    """Helicon in four layers: the drone, the shepherd's pipe, the Muses, the lyre's low notes."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "pipe", "muses", "low")}
    for freq, level in ((87.31, 0.045), (130.81, 0.025), (174.61, 0.01)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    for t, length, f in _phrases(rng, seconds, 3.0, HELICON_SCALE, [-1, -1, 1, 1, 2, -2], [1.0, 1.5, 2.0, 2.5],
                                 (3.0, 5.0), (2, 4)):
        pipe(stems["pipe"], f, 0.13, int(t * RATE), length * 0.95, rng, attack=0.25)
    for t0, length, chord in MUSES:
        for f in chord:
            choir(stems["muses"], f, 0.03, int(t0 * RATE), length + 1.5, rng, attack=3.0, release=3.0)
    for k in range(8):
        pluck(stems["low"], (87.31, 130.81)[k % 2], 0.13, int(k * 6 * RATE), 5.0, rng, 0.25, 0.998, release=0.5)
    return {k: _fold(v, total) for k, v in stems.items()}


# Herodotus's Sardis and Thermopylae: Croesus's court in the Lydian mode (the white notes on C),
# a bright kithara over a warm drone; and, heard only once the soldiers are back, the Spartans'
# march: a reed pipe setting the step and a drum, as they went into battle to the aulos.
SARDIS_SCALE = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, 587.33, 659.26]
SPARTAN_MARCH = [(0, 1), (2, 1), (4, 2), (2, 1), (0, 1), (1, 1), (2, 2)]  # (scale step, beats): a plain, steady tune


def render_sardis(seconds: int = 48, seed: int = 157) -> dict[str, list[float]]:
    """Sardis in four layers: the drone, the kithara, the low notes, the Spartan march."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "kithara", "low", "march")}
    for freq, level in ((65.41, 0.045), (98.00, 0.03), (130.81, 0.012)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    for t, length, f in _phrases(rng, seconds, 1.0, SARDIS_SCALE, [-2, -1, 1, 1, 2, 3], [0.3, 0.3, 0.6, 0.9],
                                 (1.5, 3.0), (4, 8)):
        pluck(stems["kithara"], f, 0.17, int(t * RATE), 2.5, rng, 0.7, 0.996)
    for k in range(4):
        pluck(stems["low"], 65.41 * (1.0, 1.5, 1.0, 4 / 3)[k], 0.14, int(k * 12 * RATE), 6.0, rng, 0.2, 0.998, release=0.5)
    beat = seconds / 96  # 120 steps a minute
    drum_rng = random.Random(seed + 1)
    for k in range(96):
        drum(stems["march"], int(k * beat * RATE), 0.12 if k % 2 == 0 else 0.07, drum_rng, base=64.0)
    t = 0.0
    while t < seconds - 0.1:
        for step, beats in SPARTAN_MARCH:
            reed(stems["march"], SARDIS_SCALE[step + 2], 0.045, int(t * RATE), beats * beat * 1.9, rng, attack=0.05)
            t += beats * beat * 2
        t += 4 * beat
    out = {k: _fold(v, total) for k, v in stems.items()}
    out["kithara"] = _centred(out["kithara"])
    return out


def wail(buf: list[float], start_f: float, end_f: float, level: float, start: int, seconds: float,
         rng: random.Random) -> None:
    """A mourning voice: an "ah" that slides down from one note to another, trembling, as women
    keened over the dead."""
    total = int(seconds * RATE)
    phase = 0.0
    vib_phase = rng.uniform(0, TAU)
    for n in range(total):
        if start + n >= len(buf):
            break
        u = n / total
        t = n / RATE
        env = min(1.0, t / 0.4, (total - n) / (0.8 * RATE))
        f = start_f * (end_f / start_f) ** (u ** 1.5)
        vib = 1.0 + 0.012 * math.sin(TAU * 6.0 * t + vib_phase) * min(1.0, t / 0.3)
        phase += f * vib * TABLE_SIZE / RATE
        p = int(phase)
        s = SINE[p % TABLE_SIZE] + 0.45 * SINE[(2 * p) % TABLE_SIZE] + 0.25 * SINE[(3 * p) % TABLE_SIZE]
        buf[start + n] += s * env * level


# Thucydides' Athens at war: a funeral in the Kerameikos. G Dorian; a slow aulos, the women's
# lament falling from note to note, a drum beating twice like a slow tread, a dark drone.
KERAMEIKOS_SCALE = [196.00, 220.00, 233.08, 261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 466.16]
LAMENT = [(1.0, 6.0, 466.16, 392.00), (8.0, 5.0, 440.00, 349.23), (14.0, 7.0, 392.00, 293.66),
          (25.0, 6.0, 466.16, 392.00), (32.0, 5.0, 440.00, 329.63), (38.0, 8.0, 392.00, 293.66)]


def render_kerameikos(seconds: int = 48, seed: int = 163) -> dict[str, list[float]]:
    """Athens at war in four layers: the drone, the aulos, the lament, the funeral drum."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 8 * RATE) for k in ("drone", "aulos", "lament", "drum")}
    for i in range(4):
        reed(stems["drone"], 98.00, 0.06, i * 12 * RATE, 14.0, rng, attack=2.0)
    osc(stems["drone"], fit(49.0, seconds), 0.03, 0, lambda n: 1.0 if n < total else -1)
    for t, length, f in _phrases(rng, seconds, 4.0, KERAMEIKOS_SCALE, [-1, -1, -2, 1, 1], [1.5, 2.0, 3.0],
                                 (3.0, 5.0), (2, 4)):
        reed(stems["aulos"], f, 0.11, int(t * RATE), length * 0.95, rng, attack=0.2, bend=rng.choice([0.0, 0.02]))
    for t0, length, f0, f1 in LAMENT:
        wail(stems["lament"], f0, f1, 0.07, int(t0 * RATE), length, rng)
        wail(stems["lament"], f0 * 1.004, f1 * 1.004, 0.04, int((t0 + 0.15) * RATE), length, rng)
    drum_rng = random.Random(seed + 1)
    beat = seconds / 24  # thirty treads a minute
    for k in range(24):
        drum(stems["drum"], int(k * beat * RATE), 0.22, drum_rng, base=44.0)
        drum(stems["drum"], int((k * beat + 0.4) * RATE), 0.12, drum_rng, base=44.0)
    return {k: _fold(v, total) for k, v in stems.items()}


# The Pre-Socratics at Ephesus and Elea, high and strange, on G Lydian. Heraclitus: a quick
# figure that never comes round the same way twice (you cannot step into the same river twice),
# and the lyre's "back-stretched harmony" (strife resolving). Parmenides: one tone, held,
# unchanging from the first moment of the loop to the last: what is, is.
EPHESUS_SCALE = [392.00, 440.00, 493.88, 554.37, 587.33, 659.26, 739.99, 783.99, 880.00, 987.77]
STRIFE = [((277.18, 293.66), 293.66), ((369.99, 392.00), 392.00), ((246.94, 261.63), 293.66), ((554.37, 587.33), 587.33)]


def render_ephesus(seconds: int = 48, seed: int = 167) -> dict[str, list[float]]:
    """Ephesus and Elea in four layers: the drone, the river (flux), the one tone, the lyre."""
    rng = random.Random(seed)
    total = seconds * RATE
    stems = {k: [0.0] * (total + 6 * RATE) for k in ("drone", "flux", "one", "lyre")}
    for freq, level in ((98.00, 0.04), (146.83, 0.02)):
        osc(stems["drone"], fit(freq, seconds), level, 0, lambda n: 1.0 if n < total else -1)
    t = 0.5
    step = 4
    while t < seconds - 1.0:  # the river: runs of quick notes, each run starting somewhere new
        step = rng.randrange(len(EPHESUS_SCALE))
        for _ in range(rng.randint(5, 11)):
            step = max(0, min(len(EPHESUS_SCALE) - 1, step + rng.choice([-2, -1, 1, 2])))
            pluck(stems["flux"], EPHESUS_SCALE[step], 0.1, int(t * RATE), 1.2, rng, 0.8, 0.993)
            t += rng.choice([0.14, 0.18, 0.18, 0.24])
        t += rng.uniform(0.6, 1.6)
    one = fit(783.99, seconds)  # G5, a whole number of cycles in the loop: no seam, no change
    osc(stems["one"], one, 0.035, 0, lambda n: 1.0 if n < total else -1)
    osc(stems["one"], fit(one * 2, seconds), 0.006, 0, lambda n: 1.0 if n < total else -1)
    span = seconds / len(STRIFE)
    for i, (pair, rest) in enumerate(STRIFE):  # two notes pulling against each other, then one
        s0 = int(i * span * RATE)
        for f in pair:
            pluck(stems["lyre"], f / 2, 0.15, s0, 4.0, rng, 0.4, 0.997)
        pluck(stems["lyre"], rest / 2, 0.17, s0 + int(4.0 * RATE), 6.0, rng, 0.4, 0.998, release=0.5)
    return {k: _fold(v, total) for k, v in stems.items()}


# ---------- sounds of the later places ----------

def render_crowd(seconds: int = 12, seed: int = 89, voices: int = 14) -> list[float]:
    """A forum or agora: many people talking at once, none of them clearly. Each voice is a
    band of noise that comes and goes in syllables and falls silent between phrases."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    out = [0.0] * (total + fade)
    for _ in range(voices):
        lp, hp = rng.uniform(0.12, 0.3), rng.uniform(0.02, 0.05)
        rate = rng.uniform(3.0, 6.0)
        level = rng.uniform(0.5, 1.0)
        a = b = 0.0
        talking, until = rng.random() < 0.7, rng.uniform(0.5, 3.0)
        for n in range(total + fade):
            t = n / RATE
            if t > until:
                talking, until = not talking, t + (rng.uniform(1.0, 3.5) if not talking else rng.uniform(0.4, 1.5))
            x = rng.uniform(-1, 1)
            a += (x - a) * lp
            b += (a - b) * hp
            if talking:
                out[n] += (a - b) * level * max(0.0, math.sin(TAU * rate * t)) ** 2
    return _seam(out, total, fade)


def render_arena(seconds: int = 16, seed: int = 97) -> list[float]:
    """The arena's crowd from outside the walls: a huge roar that swells and falls every 8 s."""
    crowd = render_crowd(seconds, seed, voices=24)
    return [x * (0.55 + 0.45 * math.sin(TAU * n / (8 * RATE)) ** 2) for n, x in enumerate(crowd)]


def render_rain(seconds: int = 12, seed: int = 101) -> list[float]:
    """Steady rain: a high hiss, with drops ticking on tiles and stone."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE // 2
    out, lo, drop = [], 0.0, 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.25
        if rng.random() < 0.004:
            drop = rng.uniform(0.3, 0.9)
        drop *= 0.9
        out.append((x - lo) * 0.35 + x * drop)
    return _seam(out, total, fade)


def render_oars(seconds: int = 12, seed: int = 103) -> list[float]:
    """A trireme under oar: every 2.4 s the blades bite with a splash, the water rushes along the
    stroke, and the oars knock in their tholes."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 3 * RATE)
    stroke = seconds / 5
    for k in range(5):
        s0 = int(k * stroke * RATE)
        lo = hi = 0.0
        for n in range(int(1.4 * RATE)):  # the catch and the pull
            t = n / RATE
            x = rng.uniform(-1, 1)
            lo += (x - lo) * 0.06
            hi += (x - hi) * 0.5
            splash = (x - hi) * 0.8 * math.exp(-t * 14.0)
            rush = lo * 1.6 * math.sin(math.pi * min(1.0, t / 1.4)) ** 2
            buf[s0 + n] += splash + rush
        for n in range(int(0.12 * RATE)):  # the knock of the oar in its thole
            t = n / RATE
            buf[s0 + int(0.95 * RATE) + n] += math.sin(TAU * 240.0 * t) * math.exp(-t * 40.0) * 0.5
    return _fold(buf, total)


def _knock(buf: list[float], start: int, freq: float, level: float, decay: float, rng: random.Random) -> None:
    """A short wooden or clay knock: a damped tone with a click of noise at its start."""
    for n in range(int(0.25 * RATE)):
        if start + n >= len(buf):
            break
        t = n / RATE
        buf[start + n] += (math.sin(TAU * freq * t) + rng.uniform(-1, 1) * math.exp(-t * 200.0)) * math.exp(-t * decay) * level


def render_loom(seconds: int = 10, seed: int = 107) -> list[float]:
    """Penelope's loom: the shuttle hisses across, the beater thuds the weft home twice, and the
    clay weights at the bottom of the warp knock together."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + RATE)
    t = 0.2
    while t < seconds - 0.2:
        s0 = int(t * RATE)
        lo = 0.0
        for n in range(int(0.45 * RATE)):  # the shuttle
            x = rng.uniform(-1, 1)
            lo += (x - lo) * 0.3
            buf[s0 + n] += (x - lo) * 0.25 * math.sin(math.pi * n / (0.45 * RATE))
        for dt in (0.7, 1.05):  # the beater, twice
            _knock(buf, int((t + dt) * RATE), 150.0, 0.8, 30.0, rng)
        for _ in range(rng.randint(2, 4)):  # the weights swing and clink
            _knock(buf, int((t + rng.uniform(1.1, 1.8)) * RATE), rng.uniform(650.0, 900.0), 0.25, 60.0, rng)
        t += rng.uniform(2.2, 2.8)
    return _fold(buf, total)


def render_hooves(seconds: int = 8, seed: int = 109) -> list[float]:
    """A horse walking on a paved road: four hooves to a stride, one stride a second."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + RATE)
    for stride in range(seconds):
        for k, dt in enumerate((0.0, 0.27, 0.5, 0.77)):
            s0 = int((stride + dt + rng.uniform(-0.015, 0.015)) * RATE)
            level = 0.6 if k % 2 == 0 else 0.45
            _knock(buf, max(0, s0), 420.0 * rng.uniform(0.95, 1.05), level, 70.0, rng)
            _knock(buf, max(0, s0), 950.0 * rng.uniform(0.95, 1.05), level * 0.4, 90.0, rng)
    return _fold(buf, total)


def render_flock(seconds: int = 12, seed: int = 113) -> list[float]:
    """A flock on the hillside: the little bronze bells of sheep and goats as they graze."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 3 * RATE)
    bells = [rng.uniform(1000.0, 1800.0) for _ in range(5)]
    t = 0.1
    while t < seconds:
        f = rng.choice(bells)
        for k in range(rng.randint(1, 4)):  # a beast moves its head: a few rings
            s0 = int((t + k * rng.uniform(0.12, 0.3)) * RATE)
            for mult, level, decay in ((1.0, 0.3, 6.0), (2.43, 0.12, 9.0), (4.1, 0.05, 14.0)):
                osc(buf, f * mult, level, s0,
                    lambda n, d=decay: -1 if n >= RATE else math.exp(-d * n / RATE) * min(1.0, n / 30))
        t += rng.uniform(0.6, 2.2)
    return _fold(buf, total)


def render_crickets(seconds: int = 10, seed: int = 127) -> list[float]:
    """Crickets on a warm night: short chirps of three or four pulses, two insects out of step."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + RATE)
    for carrier, period, pulses, offset, level in ((4600.0, 0.5, 3, 0.0, 0.5), (4200.0, 0.625, 4, 0.21, 0.35)):
        count = round(seconds / period)
        for c in range(count):
            for p in range(pulses):
                s0 = int((offset + c * period + p * 0.033) * RATE)
                osc(buf, carrier, level, s0, lambda n: -1 if n >= int(0.02 * RATE) else math.sin(math.pi * n / (0.02 * RATE)))
    del rng
    return _fold(buf, total)


def render_drip(seconds: int = 12, seed: int = 131) -> list[float]:
    """Plato's cave: water dripping in the dark, each drop a tiny rising "plip", over the deep
    hush of the rock."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    out, lo, lo2 = [], 0.0, 0.0
    for n in range(total + fade):
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.01
        lo2 += (lo - lo2) * 0.003
        out.append((lo - lo2) * 0.5)
    out = _seam(out, total, fade)
    drops = [0.0] * (total + RATE)
    t = rng.uniform(0.2, 1.0)
    while t < seconds - 0.3:
        s0 = int(t * RATE)
        f0 = rng.uniform(700.0, 1100.0)
        phase = 0.0
        for n in range(int(0.09 * RATE)):
            tt = n / RATE
            phase += f0 * (1.0 + 1.2 * min(1.0, tt / 0.03)) * TABLE_SIZE / RATE
            drops[s0 + n] += SINE[int(phase) % TABLE_SIZE] * math.exp(-tt * 45.0) * 0.6
        t += rng.uniform(0.7, 2.6)
    return [a + b for a, b in zip(out, _fold(drops, total))]


def render_gulls(seconds: int = 12, seed: int = 137) -> list[float]:
    """Gulls over a harbour: harsh falling cries in little bouts."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 2 * RATE)
    t = 0.3
    while t < seconds - 0.5:
        base = rng.uniform(1300.0, 1900.0)
        for k in range(rng.randint(2, 5)):
            length = rng.uniform(0.18, 0.32)
            s0 = int((t + k * (length + 0.08)) * RATE)
            phase = 0.0
            for n in range(int(length * RATE)):
                u = n / (length * RATE)
                f = base * (1.0 + 0.25 * math.sin(math.pi * u) - 0.35 * u)
                phase += f * TABLE_SIZE / RATE
                p = int(phase)
                tone = SINE[p % TABLE_SIZE] + 0.5 * SINE[(2 * p) % TABLE_SIZE] + 0.3 * SINE[(3 * p) % TABLE_SIZE]
                buf[s0 + n] += tone * math.sin(math.pi * u) ** 0.5 * 0.3
        t += rng.uniform(1.8, 4.0)
    return _fold(buf, total)


def render_owl(seed: int = 139) -> list[float]:
    """Athena's little owl: two plaintive, rising calls in the dark (a sound, not a loop)."""
    rng = random.Random(seed)
    out = [0.0] * int(2.6 * RATE)
    for start in (0.0, 1.4):
        s0 = int(start * RATE)
        length = 0.7
        phase = 0.0
        for n in range(int(length * RATE)):
            u = n / (length * RATE)
            f = 720.0 + 200.0 * u ** 1.5 + rng.uniform(-3, 3)
            phase += f * TABLE_SIZE / RATE
            p = int(phase)
            env = min(1.0, u / 0.15) * (1.0 - u) ** 0.7
            out[s0 + n] += (SINE[p % TABLE_SIZE] + 0.15 * SINE[(2 * p) % TABLE_SIZE]) * env
    return out


def render_cornu(seed: int = 149) -> list[float]:
    """The legion's horn call (a sound, not a loop): the cornu's natural notes on D, short short
    long, then the high note held."""
    del seed
    out = [0.0] * int(3.4 * RATE)
    for dt, harmonic, length in ((0.0, 3, 0.3), (0.38, 4, 0.3), (0.76, 5, 0.3), (1.14, 6, 1.9)):
        brass(out, 73.42 * harmonic, 0.5, int(dt * RATE), length, attack=0.04, release=0.2)
    return out

def render_forge(seconds: int = 12, seed: int = 173) -> list[float]:
    """Hephaestus's forge: the hammer ringing on the anvil in threes, the bellows breathing, the fire."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 3 * RATE)
    lo = 0.0
    for n in range(total):  # the bellows: a slow breath of low noise every 3 s
        x = rng.uniform(-1, 1)
        lo += (x - lo) * 0.03
        buf[n] += lo * 0.8 * max(0.0, math.sin(TAU * n / (3 * RATE))) ** 2
    for k in range(seconds // 2):
        for j, dt in enumerate((0.0, 0.32, 0.64)):  # three blows, the last the hardest
            s0 = int((k * 2 + 0.5 + dt) * RATE)
            base = rng.uniform(1180.0, 1260.0)
            for mult, level, decay in ((1.0, 0.35, 5.0), (2.71, 0.2, 7.0), (5.1, 0.1, 11.0)):
                osc(buf, base * mult, level * (0.7 + 0.15 * j), s0,
                    lambda n, d=decay: -1 if n >= RATE else math.exp(-d * n / RATE) * min(1.0, n / 20))
            _knock(buf, s0, 180.0, 0.3, 40.0, rng)
    return _fold(buf, total)


def render_sheep(seconds: int = 12, seed: int = 179) -> list[float]:
    """Sheep in a cave or on a hillside: now and then a bleat, a nasal voice with a fast tremble."""
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 2 * RATE)
    t = 0.4
    while t < seconds - 0.5:
        f0 = rng.uniform(330.0, 520.0)
        length = rng.uniform(0.5, 0.9)
        s0 = int(t * RATE)
        phase = 0.0
        for n in range(int(length * RATE)):
            u = n / (length * RATE)
            tt = n / RATE
            f = f0 * (1.0 + 0.08 * math.sin(math.pi * u) - 0.1 * u)
            phase += f * TABLE_SIZE / RATE
            p = int(phase)
            tone = SINE[p % TABLE_SIZE] + 0.6 * SINE[(2 * p) % TABLE_SIZE] + 0.45 * SINE[(3 * p) % TABLE_SIZE] \
                + 0.3 * SINE[(4 * p) % TABLE_SIZE]
            tremble = 0.6 + 0.4 * math.sin(TAU * 22.0 * tt)
            buf[s0 + n] += tone * tremble * math.sin(math.pi * u) ** 0.6 * 0.25
        t += rng.uniform(1.5, 4.0)
    return _fold(buf, total)


def render_salpinx(seed: int = 181) -> list[float]:
    """The salpinx, the Greek battle trumpet (a sound, not a loop): one harsh, bright blast."""
    del seed
    out = [0.0] * int(2.6 * RATE)
    brass(out, 440.0, 0.5, 0, 0.35, attack=0.03, release=0.1)
    brass(out, 440.0, 0.6, int(0.45 * RATE), 1.9, attack=0.05, release=0.5)
    return out

def render_shades(seconds: int = 16, seed: int = 191) -> list[float]:
    """The dead crowding up out of the dark (Odyssey 11): a low, whispering throng, voices that
    are only breath, rising and falling in a slow surge, and now and then a thin cry."""
    rng = random.Random(seed)
    total, fade = seconds * RATE, RATE
    out = [0.0] * (total + fade)
    for _ in range(18):  # the whisperers: high breathy noise in syllables, no voice under it
        hp = rng.uniform(0.3, 0.6)
        rate = rng.uniform(2.0, 4.5)
        level = rng.uniform(0.3, 0.7)
        a = b = 0.0
        talking, until = rng.random() < 0.5, rng.uniform(0.5, 3.0)
        for n in range(total + fade):
            t = n / RATE
            if t > until:
                talking, until = not talking, t + (rng.uniform(0.8, 2.5) if not talking else rng.uniform(0.6, 2.0))
            x = rng.uniform(-1, 1)
            a += (x - a) * hp
            b += (a - b) * 0.08
            if talking:
                out[n] += (a - b) * level * max(0.0, math.sin(TAU * rate * t)) ** 3
    surge = [x * (0.45 + 0.55 * math.sin(math.pi * n / (8 * RATE)) ** 2) for n, x in enumerate(out)]  # 8 s divides 16
    surge = _seam(surge, total, fade)
    cries = [0.0] * (total + 3 * RATE)
    t = rng.uniform(1.0, 3.0)
    while t < seconds - 2.0:
        wail(cries, rng.uniform(900.0, 1300.0), rng.uniform(500.0, 700.0), 0.12, int(t * RATE), rng.uniform(1.2, 2.0), rng)
        t += rng.uniform(4.0, 7.0)
    return [a + b for a, b in zip(surge, _fold(cries, total))]




def write_wav(path: Path, samples: list[float], peak: float, top: float | None = None) -> None:
    """Write a mono 16-bit file, scaled so `top` (by default its own loudest sample) hits `peak`."""
    top = top or max(1e-9, max(abs(s) for s in samples))
    data = array.array("h", (int(s / top * peak * 32767) for s in samples))
    if sys.byteorder == "big":
        data.byteswap()
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    logger.info("Wrote %s (%.1f s)", path.name, len(samples) / RATE)


def rms(samples: list[float]) -> float:
    return math.sqrt(sum(s * s for s in samples) / max(1, len(samples)))


def write_stems(name: str, stems: dict[str, list[float]], peak: float, core: tuple[str, ...] = ()) -> float:
    """Write a track's layers with one shared scale, so together they sound as mixed. The scale
    comes from the core layers (by default all), so an extra layer heard only at the very end
    (the soldiers' drum) does not turn the rest down. Returns the loudness (RMS) of the core mix
    as written, for the ghost to sit under."""
    mix = [sum(v) for v in zip(*(stems[k] for k in (core or stems)))]
    top = max(1e-9, max(abs(s) for s in mix))
    for part, samples in stems.items():
        write_wav(OUT / f"{name}_{part}.wav", samples, peak, top)
    return rms(mix) * peak / top


def write_ghost(path: Path, samples: list[float], under: float) -> None:
    """Write a ghost (the echo heard while a place is lost) at about half the loudness of the
    place's whole track, so the echo is truly faint next to what comes back."""
    target = under * 0.5
    gain = target / max(1e-9, rms(samples))
    top = max(abs(s) for s in samples)
    gain = min(gain, 0.95 / max(1e-9, top))
    write_wav(path, samples, top * gain, top)
    logger.info("  %s sits at RMS %.3f under the whole track's %.3f", path.name, rms(samples) * gain, under)
    assert rms(samples) * gain < under, "a ghost must be quieter than the place it haunts"


def _track(name: str, render: Callable[[], dict[str, list[float]]], core: tuple[str, ...], scale: list[float],
           root: float, voice: str, seed: int) -> Callable[[], None]:
    """A place's whole track: its layers and the ghost that sits under them."""
    def job() -> None:
        loud = write_stems(name, render(), 0.7, core=core)
        write_ghost(OUT / f"{name}_ghost.wav", render_ghost(scale, root, voice, seed=seed), loud)
    return job


def _one(name: str, render: Callable[[], list[float]], peak: float) -> Callable[[], None]:
    return lambda: write_wav(OUT / f"{name}.wav", render(), peak)


# Everything this script makes, by name. Name some on the command line to make only those.
JOBS: dict[str, Callable[[], None]] = {
    "shore": _one("shore", lambda: render_loop(E1), 0.7),
    "sicily": _track("sicily", render_sicily, (), SICILY_SCALE, 110.0, "lyre", 43),
    "wind": _one("wind", lambda: render_wind(12), 0.35),
    "bell": _one("bell", render_bell, 0.6),
    "waves": _one("waves", render_waves, 0.5),
    "cicadas": _one("cicadas", render_cicadas, 0.35),
    "fire": _one("fire", render_fire, 0.4),
    "fountain": _one("fountain", render_fountain, 0.3),
    "croak": _one("croak", render_croak, 0.8),
    "athens": _track("athens", render_athens, ("drone", "walk", "pipes"), ATHENS_SCALE, 82.41, "pipe", 41),
    "birds": _one("birds", render_birds, 0.4),
    "stream": _one("stream", render_stream, 0.3),
    "nexus": _track("nexus", render_nexus, ("drone", "bass", "pad", "arp"), NEXUS_SCALE, 65.41, "chime", 47),
    "void": _one("void", render_void, 0.35),
    # Rome, and the Greek places still to come
    "rome": _track("rome", render_rome, ("drone", "organ", "tibia"), ROME_SCALE, 73.42, "reed", 63),
    "troy": _track("troy", render_troy, ("drone", "phorminx", "voice"), TROY_SCALE, 73.42, "lyre", 69),
    "theatre": _track("theatre", render_theatre, ("drone", "aulos", "chorus"), THEATRE_SCALE, 61.74, "reed", 75),
    "lesbos": _track("lesbos", render_lesbos, (), LESBOS_SCALE, 110.0, "lyre", 77),
    "alexandria": _track("alexandria", render_alexandria, (), ALEX_SCALE, 87.31, "lyre", 81),
    "academy": _track("academy", render_academy, (), ACADEMY_SCALE, 82.41, "pipe", 85),
    "crowd": _one("crowd", render_crowd, 0.35),
    "arena": _one("arena", render_arena, 0.4),
    "rain": _one("rain", render_rain, 0.3),
    "oars": _one("oars", render_oars, 0.45),
    "loom": _one("loom", render_loom, 0.45),
    "hooves": _one("hooves", render_hooves, 0.45),
    "flock": _one("flock", render_flock, 0.3),
    "crickets": _one("crickets", render_crickets, 0.25),
    "drip": _one("drip", render_drip, 0.4),
    "gulls": _one("gulls", render_gulls, 0.3),
    "owl": _one("owl", render_owl, 0.6),
    "cornu": _one("cornu", render_cornu, 0.7),
    # round 2: Hesiod, Herodotus, Thucydides, the Pre-Socratics
    "helicon": _track("helicon", render_helicon, (), HELICON_SCALE, 87.31, "pipe", 153),
    "sardis": _track("sardis", render_sardis, ("drone", "kithara", "low"), SARDIS_SCALE, 65.41, "lyre", 159),
    "kerameikos": _track("kerameikos", render_kerameikos, (), KERAMEIKOS_SCALE, 98.00, "reed", 165),
    "ephesus": _track("ephesus", render_ephesus, (), EPHESUS_SCALE, 98.00, "lyre", 169),
    "forge": _one("forge", render_forge, 0.45),
    "sheep": _one("sheep", render_sheep, 0.35),
    "salpinx": _one("salpinx", render_salpinx, 0.7),
    "shades": _one("shades", render_shades, 0.4),
}


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    names = sys.argv[1:] or list(JOBS)
    unknown = [n for n in names if n not in JOBS]
    if unknown:
        logger.error("Unknown: %s (known: %s)", ", ".join(unknown), ", ".join(JOBS))
        return 2
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names:
        JOBS[name]()
    return 0


if __name__ == "__main__":
    sys.exit(main())
