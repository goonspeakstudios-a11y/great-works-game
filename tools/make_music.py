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

Usage: C:\\Python314\\python.exe tools/make_music.py
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


def drum(buf: list[float], start: int, level: float, rng: random.Random) -> None:
    """A marching drum: a low skin that drops in pitch as it settles, with a little slap."""
    for n in range(int(0.35 * RATE)):
        if start + n >= len(buf):
            break
        t = n / RATE
        f = 68.0 * (1.0 + 0.6 * math.exp(-t * 30.0))
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


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "shore.wav", render_loop(E1), 0.7)
    sicily = write_stems("sicily", render_sicily(), 0.7)
    write_ghost(OUT / "sicily_ghost.wav", render_ghost(SICILY_SCALE, 110.0, "lyre", seed=43), sicily)
    write_wav(OUT / "wind.wav", render_wind(12), 0.35)
    write_wav(OUT / "bell.wav", render_bell(), 0.6)
    write_wav(OUT / "waves.wav", render_waves(), 0.5)
    write_wav(OUT / "cicadas.wav", render_cicadas(), 0.35)
    write_wav(OUT / "fire.wav", render_fire(), 0.4)
    write_wav(OUT / "fountain.wav", render_fountain(), 0.3)
    write_wav(OUT / "croak.wav", render_croak(), 0.8)
    athens = write_stems("athens", render_athens(), 0.7, core=("drone", "walk", "pipes"))
    write_ghost(OUT / "athens_ghost.wav", render_ghost(ATHENS_SCALE, 82.41, "pipe", seed=41), athens)
    write_wav(OUT / "birds.wav", render_birds(), 0.4)
    write_wav(OUT / "stream.wav", render_stream(), 0.3)
    nexus = write_stems("nexus", render_nexus(), 0.7, core=("drone", "bass", "pad", "arp"))
    write_ghost(OUT / "nexus_ghost.wav", render_ghost(NEXUS_SCALE, 65.41, "chime", seed=47), nexus)
    write_wav(OUT / "void.wav", render_void(), 0.35)
    return 0


if __name__ == "__main__":
    sys.exit(main())
