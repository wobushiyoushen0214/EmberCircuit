#!/usr/bin/env python3
"""Generate deterministic placeholder-quality WAV audio for EmberCircuit.

SFX are intentionally short and dry so Godot can mix many UI/combat events
without masking the card and battle readability. Music loops are lightweight
first-pass beds that establish state-specific audio slots for later licensed or
custom replacement.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22050
OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"
MUSIC_DIR = OUT_DIR / "music"


EVENTS = {
    "ui_click": {"duration": 0.070, "kind": "click", "freq": 720, "volume": 0.26},
    "card_play": {"duration": 0.140, "kind": "whoosh", "freq": 520, "volume": 0.24},
    "card_attack": {"duration": 0.180, "kind": "slash", "freq": 360, "volume": 0.34},
    "card_skill": {"duration": 0.170, "kind": "shimmer", "freq": 610, "volume": 0.27},
    "card_power": {"duration": 0.230, "kind": "pulse", "freq": 180, "volume": 0.31},
    "turn_end": {"duration": 0.160, "kind": "drop", "freq": 260, "volume": 0.24},
    "reward": {"duration": 0.240, "kind": "arpeggio", "freq": 620, "volume": 0.26},
    "potion": {"duration": 0.190, "kind": "bubble", "freq": 540, "volume": 0.24},
    "hit": {"duration": 0.160, "kind": "impact", "freq": 110, "volume": 0.38},
    "block": {"duration": 0.170, "kind": "metal", "freq": 280, "volume": 0.31},
    "heal": {"duration": 0.240, "kind": "rise", "freq": 520, "volume": 0.24},
    "phase": {"duration": 0.380, "kind": "rumble", "freq": 72, "volume": 0.39},
    "victory": {"duration": 0.420, "kind": "victory", "freq": 520, "volume": 0.28},
    "defeat": {"duration": 0.420, "kind": "defeat", "freq": 220, "volume": 0.31},
    "map_select": {"duration": 0.120, "kind": "ping", "freq": 480, "volume": 0.22},
    "campfire": {"duration": 0.300, "kind": "crackle", "freq": 220, "volume": 0.25},
    "shop": {"duration": 0.170, "kind": "coin", "freq": 740, "volume": 0.24},
    "save": {"duration": 0.160, "kind": "save", "freq": 880, "volume": 0.22},
    "error": {"duration": 0.180, "kind": "error", "freq": 180, "volume": 0.27},
}

MUSIC = {
    "menu_loop": {"duration": 4.0, "root": 146.83, "tempo": 72.0, "mood": "menu", "volume": 0.18},
    "map_loop": {"duration": 4.0, "root": 164.81, "tempo": 84.0, "mood": "map", "volume": 0.17},
    "combat_loop": {"duration": 4.0, "root": 110.00, "tempo": 112.0, "mood": "combat", "volume": 0.20},
    "boss_loop": {"duration": 4.0, "root": 82.41, "tempo": 126.0, "mood": "boss", "volume": 0.23},
    "event_loop": {"duration": 4.0, "root": 130.81, "tempo": 66.0, "mood": "event", "volume": 0.16},
    "shop_loop": {"duration": 4.0, "root": 174.61, "tempo": 92.0, "mood": "shop", "volume": 0.15},
    "campfire_loop": {"duration": 4.0, "root": 196.00, "tempo": 70.0, "mood": "campfire", "volume": 0.16},
    "reward_loop": {"duration": 4.0, "root": 220.00, "tempo": 88.0, "mood": "reward", "volume": 0.17},
    "victory_loop": {"duration": 4.0, "root": 246.94, "tempo": 96.0, "mood": "victory", "volume": 0.18},
    "defeat_loop": {"duration": 4.0, "root": 98.00, "tempo": 58.0, "mood": "defeat", "volume": 0.18},
}


def envelope(t: float, duration: float, attack: float = 0.012, release: float = 0.055) -> float:
    if t < attack:
        return t / max(attack, 0.0001)
    remaining = duration - t
    if remaining < release:
        return max(0.0, remaining / max(release, 0.0001))
    return 1.0


def sine(freq: float, t: float) -> float:
    return math.sin(math.tau * freq * t)


def square(freq: float, t: float) -> float:
    return 1.0 if sine(freq, t) >= 0.0 else -1.0


def tone(kind: str, freq: float, t: float, duration: float, rng: random.Random) -> float:
    progress = t / max(duration, 0.0001)
    noise = rng.uniform(-1.0, 1.0)

    if kind == "click":
        return 0.65 * sine(freq + 1200.0 * progress, t) + 0.18 * noise
    if kind == "whoosh":
        sweep = freq * (1.7 - 1.1 * progress)
        return 0.45 * sine(sweep, t) + 0.35 * noise * progress
    if kind == "slash":
        sweep = freq * (2.4 - 1.7 * progress)
        return 0.56 * sine(sweep, t) + 0.24 * square(sweep * 0.5, t) + 0.18 * noise
    if kind == "shimmer":
        return 0.42 * sine(freq, t) + 0.28 * sine(freq * 1.5, t) + 0.18 * sine(freq * 2.0, t)
    if kind == "pulse":
        pulse = 1.0 if math.sin(math.tau * 7.5 * t) > 0.15 else 0.35
        return pulse * (0.50 * sine(freq, t) + 0.25 * sine(freq * 2.0, t))
    if kind == "drop":
        return 0.62 * sine(freq * (1.25 - 0.60 * progress), t) + 0.10 * noise
    if kind == "arpeggio":
        ratios = [1.0, 1.25, 1.5, 2.0]
        ratio = ratios[min(len(ratios) - 1, int(progress * len(ratios)))]
        return 0.62 * sine(freq * ratio, t) + 0.18 * sine(freq * ratio * 2.0, t)
    if kind == "bubble":
        wobble = 1.0 + 0.18 * math.sin(math.tau * 18.0 * t)
        return 0.50 * sine(freq * wobble, t) + 0.26 * sine(freq * 0.62 * wobble, t)
    if kind == "impact":
        return 0.55 * sine(freq * (1.0 - 0.30 * progress), t) + 0.38 * noise * (1.0 - progress)
    if kind == "metal":
        return 0.34 * sine(freq, t) + 0.32 * sine(freq * 2.72, t) + 0.18 * noise
    if kind == "rise":
        sweep = freq * (0.70 + 0.95 * progress)
        return 0.50 * sine(sweep, t) + 0.20 * sine(sweep * 1.5, t)
    if kind == "rumble":
        return 0.58 * sine(freq, t) + 0.22 * sine(freq * 1.5, t) + 0.22 * noise * (1.0 - progress)
    if kind == "victory":
        ratios = [1.0, 1.25, 1.5, 2.0, 2.5]
        ratio = ratios[min(len(ratios) - 1, int(progress * len(ratios)))]
        return 0.54 * sine(freq * ratio, t) + 0.18 * sine(freq * ratio * 2.0, t)
    if kind == "defeat":
        return 0.56 * sine(freq * (1.2 - 0.72 * progress), t) + 0.18 * noise * progress
    if kind == "ping":
        return 0.62 * sine(freq, t) + 0.16 * sine(freq * 2.0, t)
    if kind == "crackle":
        spark = noise if rng.random() > 0.88 else noise * 2.2
        return 0.28 * sine(freq * (0.8 + progress), t) + 0.34 * spark
    if kind == "coin":
        return 0.36 * sine(freq, t) + 0.42 * sine(freq * 1.875, t)
    if kind == "save":
        return 0.50 * sine(freq * (1.0 + 0.25 * progress), t) + 0.24 * square(freq * 0.5, t)
    if kind == "error":
        return 0.54 * square(freq, t) + 0.20 * sine(freq * 0.5, t)
    return sine(freq, t)


def write_wav(event_id: str, profile: dict[str, float | str]) -> None:
    duration = float(profile["duration"])
    freq = float(profile["freq"])
    volume = float(profile["volume"])
    kind = str(profile["kind"])
    rng = random.Random(event_id)
    frames = int(SAMPLE_RATE * duration)
    samples: list[int] = []

    for i in range(frames):
        t = i / SAMPLE_RATE
        env = envelope(t, duration)
        value = tone(kind, freq, t, duration, rng) * env * volume
        value = max(-0.98, min(0.98, value))
        samples.append(int(value * 32767))

    path = OUT_DIR / f"{event_id}.wav"
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(b"".join(struct.pack("<h", sample) for sample in samples))


def music_tone(mood: str, root: float, tempo: float, t: float, duration: float, rng: random.Random) -> float:
    beat = t * tempo / 60.0
    step = int(beat * 2.0)
    phase = (t / max(duration, 0.0001)) % 1.0
    noise = rng.uniform(-1.0, 1.0)

    mood_scales = {
        "menu": [0, 3, 5, 7, 10],
        "map": [0, 2, 5, 7, 9],
        "combat": [0, 3, 6, 7, 10],
        "boss": [0, 1, 6, 7, 10],
        "event": [0, 2, 3, 7, 9],
        "shop": [0, 4, 7, 9, 12],
        "campfire": [0, 3, 5, 7, 12],
        "reward": [0, 4, 7, 11, 12],
        "victory": [0, 4, 7, 12, 16],
        "defeat": [0, 3, 5, 6, 10],
    }
    scale = mood_scales.get(mood, mood_scales["menu"])
    degree = scale[step % len(scale)]
    freq = root * (2.0 ** (degree / 12.0))
    bass = root * (0.50 if mood in ["boss", "combat", "defeat"] else 0.75)
    pulse = 0.5 + 0.5 * math.sin(math.tau * beat)

    pad = 0.32 * sine(root * 0.5, t) + 0.22 * sine(root * 0.75, t + 0.03)
    motif = 0.24 * sine(freq, t) * (0.35 + 0.65 * pulse)
    bassline = 0.30 * sine(bass, t)

    if mood == "combat":
        motif += 0.18 * square(freq * 0.5, t) * (1.0 if step % 2 == 0 else 0.35)
        bassline += 0.18 * noise * (1.0 if step % 4 == 0 else 0.18)
    elif mood == "boss":
        motif += 0.22 * square(freq * 0.25, t) * (1.0 - phase * 0.4)
        bassline += 0.25 * noise * (0.8 + 0.2 * pulse)
    elif mood == "shop":
        motif += 0.18 * sine(freq * 2.0, t) * (1.0 if step % 3 == 0 else 0.25)
    elif mood == "campfire":
        motif += 0.12 * noise * (1.0 if rng.random() > 0.94 else 0.12)
    elif mood == "victory":
        motif += 0.20 * sine(freq * 1.5, t) * pulse
    elif mood == "defeat":
        motif = 0.20 * sine(freq * (1.0 - 0.20 * phase), t)
        bassline += 0.14 * noise * phase

    seam_fade = min(1.0, max(0.0, min(t, duration - t) / 0.08))
    return (pad + motif + bassline) * seam_fade


def write_music_wav(track_id: str, profile: dict[str, float | str]) -> None:
    duration = float(profile["duration"])
    root = float(profile["root"])
    tempo = float(profile["tempo"])
    mood = str(profile["mood"])
    volume = float(profile["volume"])
    rng = random.Random(track_id)
    frames = int(SAMPLE_RATE * duration)
    samples: list[int] = []

    for i in range(frames):
        t = i / SAMPLE_RATE
        value = music_tone(mood, root, tempo, t, duration, rng) * volume
        value = max(-0.98, min(0.98, value))
        samples.append(int(value * 32767))

    path = MUSIC_DIR / f"{track_id}.wav"
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(b"".join(struct.pack("<h", sample) for sample in samples))


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    MUSIC_DIR.mkdir(parents=True, exist_ok=True)
    for event_id, profile in EVENTS.items():
        write_wav(event_id, profile)
    for track_id, profile in MUSIC.items():
        write_music_wav(track_id, profile)
    print(f"Generated {len(EVENTS)} SFX assets in {OUT_DIR}")
    print(f"Generated {len(MUSIC)} music loops in {MUSIC_DIR}")


if __name__ == "__main__":
    main()
