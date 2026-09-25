"""Render the game's music from code into assets/music/*.wav (no samples, no downloads).

The mood is slow, dark and grand: a low drone, slow minor chords, wind, and distant
bells (the bells are triggered in-game with random pitch). Reverb is added in-game on
the Music bus, so these files are dry. Loops are seamless: every drone partial fits the
loop length exactly, and chord tails that run past the end are folded back to the start.

Usage: C:\\Python314\\python.exe tools/make_music.py
"""
from __future__ import annotations

import array
import logging
import math
import random
import sys
import wave
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


def osc(buf: list[float], freq: float, level: float, start: int, env) -> None:
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

        def env(n: int, att=att, hold=hold, rel=rel) -> float:
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


def write_wav(path: Path, samples: list[float], peak: float) -> None:
    top = max(1e-9, max(abs(s) for s in samples))
    data = array.array("h", (int(s / top * peak * 32767) for s in samples))
    if sys.byteorder == "big":
        data.byteswap()
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    logger.info("Wrote %s (%.1f s)", path.name, len(samples) / RATE)


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "e1_loop.wav", render_loop(E1), 0.7)
    write_wav(OUT / "wind.wav", render_wind(12), 0.35)
    write_wav(OUT / "bell.wav", render_bell(), 0.6)
    return 0


if __name__ == "__main__":
    sys.exit(main())
