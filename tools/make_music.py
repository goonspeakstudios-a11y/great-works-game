"""Render the game's music and sounds from code into assets/music/*.wav (no samples, no downloads).

Every zone has its own track: the Shore's is slow, dark and grand (a low drone, slow
minor chords, distant bells triggered in-game); Porphyry's Sicily is warmer, a plucked
lyre (a simulated string, Karplus-Strong) over a soft drone in the Dorian mode.
Ambient loops give each place its sound: waves, wind, fire, cicadas, a fountain.
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
          brightness: float = 0.5, decay: float = 0.996) -> None:
    """A plucked string (Karplus-Strong): a burst of noise that rings at freq and fades."""
    period = max(2, int(RATE / freq))
    string = [rng.uniform(-1, 1) for _ in range(period)]
    for _ in range(int(2 + (1 - brightness) * 4)):  # softer attack: smooth the burst first
        string = [(string[i] + string[i - 1]) * 0.5 for i in range(period)]
    for n in range(int(seconds * RATE)):
        i = n % period
        out = string[i]
        string[i] = decay * 0.5 * (string[i] + string[(i + 1) % period])
        if start + n < len(buf):
            buf[start + n] += out * level


# Porphyry's Sicily: a lyre in A Dorian over a soft drone, phrases with rests between.
SICILY_SCALE = [220.0, 246.94, 261.63, 293.66, 329.63, 369.99, 392.0, 440.0, 493.88, 523.25]


def render_lyre(seconds: int = 48, seed: int = 11) -> list[float]:
    rng = random.Random(seed)
    total = seconds * RATE
    buf = [0.0] * (total + 4 * RATE)
    for freq, level in ((110.0, 0.05), (164.81, 0.03), (220.0, 0.012)):
        f = fit(freq, seconds)
        osc(buf, f, level, 0, lambda n: 1.0 if n < total else -1)
        osc(buf, fit(f * 2, seconds), level * 0.25, 0, lambda n: 1.0 if n < total else -1)
    t = 0.6
    step = 4
    while t < seconds - 3.0:
        for k in range(rng.randint(4, 7)):  # a phrase: a gentle walk up and down the mode
            step = max(0, min(len(SICILY_SCALE) - 1, step + rng.choice([-2, -1, -1, 1, 1, 2])))
            last = k == 6 or rng.random() < 0.15
            pluck(buf, SICILY_SCALE[step], 0.2 if not last else 0.24, int(t * RATE), 3.0, rng)
            if rng.random() < 0.25:  # sometimes a low note under it
                pluck(buf, SICILY_SCALE[step] / 2, 0.12, int(t * RATE), 3.0, rng, 0.3)
            t += rng.choice([0.45, 0.6, 0.6, 0.9]) + (0.8 if last else 0.0)
            if last:
                break
        t += rng.uniform(1.4, 2.6)  # rest between phrases
    out = buf[:total]
    for n in range(total, len(buf)):
        out[n - total] += buf[n]
    return out


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
    write_wav(OUT / "shore.wav", render_loop(E1), 0.7)
    write_wav(OUT / "sicily.wav", render_lyre(), 0.7)
    write_wav(OUT / "wind.wav", render_wind(12), 0.35)
    write_wav(OUT / "bell.wav", render_bell(), 0.6)
    write_wav(OUT / "waves.wav", render_waves(), 0.5)
    write_wav(OUT / "cicadas.wav", render_cicadas(), 0.35)
    write_wav(OUT / "fire.wav", render_fire(), 0.4)
    write_wav(OUT / "fountain.wav", render_fountain(), 0.3)
    write_wav(OUT / "croak.wav", render_croak(), 0.8)
    return 0


if __name__ == "__main__":
    sys.exit(main())
