"""RC-018 original procedural SFX renderer. No recordings or sample libraries.

Run from any directory with Python 3 + NumPy:
    python source-assets/audio/sfx/generate_sfx.py

Edit settings.json to change layers, deterministic seeds, levels, or durations.
The shared enemy action stem is rendered once and reused unchanged in all five
enemy mixes before each cue's final level adjustment. Nothing edits Godot code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import wave

import numpy as np


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def db(value: float) -> float:
    return float(20 * math.log10(max(abs(value), 1e-15)))


def filtered_noise(rng: np.random.Generator, count: int, rate: int,
                   low: float, high: float) -> np.ndarray:
    """Seeded white noise shaped with smooth, nonresonant FFT filters."""
    source = rng.standard_normal(count)
    frequencies = np.fft.rfftfreq(count, 1 / rate)
    safe = np.maximum(frequencies, 1)
    response = (1 / np.sqrt(1 + (low / safe) ** 8))
    response *= 1 / np.sqrt(1 + (safe / high) ** 12)
    response[0] = 0
    result = np.fft.irfft(np.fft.rfft(source) * response, n=count)
    return result / max(float(np.std(result)), 1e-12)


def layer_signal(layer: dict, rng: np.random.Generator, count: int,
                 rate: int) -> np.ndarray:
    out = np.zeros(count, dtype=np.float64)
    start = round(layer.get("start_s", 0) * rate)
    if start >= count:
        return out
    length = count - start
    t = np.arange(length) / rate
    attack = max(layer.get("attack_s", 0.002), 1 / rate)
    onset = 1 - np.exp(-t / attack)
    kind = layer["kind"]
    if kind == "modal":
        # Inharmonic damped modes model small solid resonators, rather than
        # oscillators playing generic sine notification tones.
        body = np.zeros(length)
        frequencies = layer["frequencies_hz"]
        amplitudes = layer["amplitudes"]
        decays = layer["decays_s"]
        glide = layer.get("glide_ratio", 1.0)
        glide_time = layer.get("glide_s", 0.12)
        wobble = layer.get("wobble_cents", 2.4)
        for frequency, amplitude, decay in zip(frequencies, amplitudes, decays):
            # Integral of a frequency that eases exponentially toward its
            # destination. Modes share the curve, not harmonic frequencies.
            phase = 2 * np.pi * frequency * (
                glide * t + (1 - glide) * glide_time *
                (1 - np.exp(-t / glide_time)))
            phase += (wobble / 1200) * np.sin(
                2 * np.pi * rng.uniform(4.0, 7.0) * t + rng.uniform(0, 6.28))
            body += amplitude * np.sin(phase) * np.exp(-t / decay)
        out[start:] = body * onset
    elif kind == "noise":
        body = filtered_noise(rng, length, rate, layer["low_hz"], layer["high_hz"])
        shape = np.exp(-t / layer["decay_s"]) * onset
        if layer.get("pulse_hz", 0):
            shape *= 0.78 + 0.22 * np.cos(2 * np.pi * layer["pulse_hz"] * t)
        out[start:] = body * shape * layer["amplitude"]
    elif kind == "grains":
        # Small grains give friction/crackle/chain articulation. All stochastic
        # choices come from the stored cue seed; there is no external sample.
        for index in range(layer["count"]):
            position = start + round(rate * (index * layer["span_s"] /
                              max(layer["count"] - 1, 1) + rng.uniform(0, 0.004)))
            size = min(count - position, round(layer["grain_s"] * rate))
            if size < 3:
                continue
            gt = np.arange(size) / rate
            grain = filtered_noise(rng, size, rate, layer["low_hz"], layer["high_hz"])
            envelope = np.sin(np.linspace(0, np.pi, size)) ** 2
            envelope *= np.exp(-gt / (layer["grain_s"] * 0.32))
            out[position:position + size] += grain * envelope * layer["amplitude"] * rng.uniform(0.65, 1.0)
    else:
        raise ValueError(f"Unknown layer kind: {kind}")
    return out


def recipe_signal(recipe: dict, seed: int, duration: float, rate: int) -> np.ndarray:
    count = round(duration * rate)
    rng = np.random.default_rng(seed)
    sound = np.zeros(count)
    for layer in recipe["layers"]:
        sound += layer_signal(layer, rng, count, rate)
    # Very short, quiet early reflections supply a common enclosed crypt
    # material character; these are not a long reverberation tail.
    original = sound.copy()
    for reflection in recipe.get("early_reflections", []):
        delay = round(reflection["delay_s"] * rate)
        if 0 < delay < count:
            sound[delay:] += original[:-delay] * reflection["amplitude"]
    return sound


def safety_filter(sound: np.ndarray, rate: int, low: float, high: float) -> np.ndarray:
    frequencies = np.fft.rfftfreq(len(sound), 1 / rate)
    safe = np.maximum(frequencies, 1)
    response = 1 / np.sqrt(1 + (low / safe) ** 8)
    response *= 1 / np.sqrt(1 + (safe / high) ** 12)
    response[0] = 0
    return np.fft.irfft(np.fft.rfft(sound) * response, n=len(sound))


def taper_and_center(sound: np.ndarray, rate: int, fade_in_ms: float,
                     fade_out_ms: float) -> np.ndarray:
    window = np.ones(len(sound))
    incoming = round(fade_in_ms * rate / 1000)
    outgoing = round(fade_out_ms * rate / 1000)
    window[:incoming] = np.sin(np.linspace(0, np.pi / 2, incoming)) ** 2
    window[-outgoing:] = np.cos(np.linspace(0, np.pi / 2, outgoing)) ** 2
    sound = sound * window
    # Weighted correction preserves zero-valued endpoints and removes the
    # residual DC introduced by tapering an asymmetric transient.
    sound -= window * (float(np.sum(sound)) / float(np.sum(window)))
    sound[0] = sound[-1] = 0
    return sound


def sinc_true_peak(sound: np.ndarray, factor: int = 8, taps_per_side: int = 16) -> float:
    """8x windowed-sinc interpolation estimate, NOT a certified BS.1770 meter.

    A 257-tap Kaiser(beta=8.6) low-pass interpolator at 8x, cutoff 24 kHz.
    Reported as an estimate; generous headroom below -3 dBTP is intentional.
    """
    positions = np.arange(-taps_per_side * factor, taps_per_side * factor + 1)
    kernel = np.sinc(positions / factor) * np.kaiser(len(positions), 8.6)
    kernel *= factor / np.sum(kernel)
    upsampled = np.zeros(len(sound) * factor)
    upsampled[::factor] = sound
    return float(np.max(np.abs(np.convolve(upsampled, kernel, mode="same"))))


def pcm_bytes(sound: np.ndarray, depth: int, seed: int) -> bytes:
    scale = 2 ** (depth - 1)
    rng = np.random.default_rng(seed)
    # Independent triangular dither, peak-to-peak 2 LSB. Integer rounding and
    # clipping bounds are explicit; no compressor/limiter is used.
    dither = rng.random(len(sound)) - rng.random(len(sound))
    integers = np.clip(np.rint(sound * scale + dither), -scale, scale - 1).astype(np.int32)
    integers[0] = integers[-1] = 0
    if depth == 16:
        return integers.astype("<i2").tobytes()
    if depth == 24:
        packed = np.empty((len(integers), 3), dtype=np.uint8)
        for byte in range(3):
            packed[:, byte] = (integers >> (8 * byte)) & 255
        return packed.tobytes()
    raise ValueError("Only 16-bit runtime and 24-bit master are supported")


def write_wave(path: Path, sound: np.ndarray, rate: int, depth: int, seed: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(depth // 8)
        handle.setframerate(rate)
        handle.writeframes(pcm_bytes(sound, depth, seed))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", type=Path, default=HERE / "settings.json")
    parser.add_argument("--root", type=Path, default=ROOT,
                        help="Repository root; useful for isolated reproducibility checks")
    args = parser.parse_args()
    settings = json.loads(args.settings.read_text(encoding="utf-8"))
    rate = settings["sample_rate"]
    stem_spec = settings["shared_enemy_base"]
    stem = recipe_signal(stem_spec["recipe"], stem_spec["seed"], stem_spec["duration_seconds"], rate)
    stem_path = args.root / "source-assets/audio/sfx/stems/enemy_action_base.npy"
    stem_path.parent.mkdir(parents=True, exist_ok=True)
    np.save(stem_path, stem.astype("<f8"), allow_pickle=False)
    report = {
        "schema_version": 1,
        "revision": settings["revision"],
        "python_version": platform.python_version(),
        "numpy_version": np.__version__,
        "settings_sha256": digest(args.settings),
        "generator_sha256": digest(Path(__file__)),
        "shared_enemy_base_sha256": digest(stem_path),
        "true_peak_method": "8x zero insertion; 257-tap sinc with Kaiser beta 8.6; interpolation estimate, not certified BS.1770",
        "level_method": "Role-dependent whole-file RMS target with per-cue peak safety cap; no integrated LUFS, compressor or brickwall limiter; intended playback gains separate",
        "listening_review": "Not performed by the procedural renderer. Measurements do not establish headphone/speaker acceptance.",
        "cues": [],
    }
    for cue in settings["cues"]:
        sound = recipe_signal(cue["recipe"], cue["seed"], cue["duration_seconds"], rate)
        if cue["recipe"].get("shared_enemy_base", False):
            sound[:len(stem)] += stem * cue["recipe"].get("shared_enemy_base_gain", 1.0)
        sound = safety_filter(sound, rate, settings["output_filter"]["highpass_hz"], settings["output_filter"]["lowpass_hz"])
        sound = taper_and_center(sound, rate, cue.get("fade_in_ms", 2.0), cue.get("fade_out_ms", 30.0))
        raw_rms = float(np.sqrt(np.mean(sound ** 2)))
        rms_gain = 10 ** (cue["target_rms_dbfs"] / 20) / raw_rms
        peak_gain = 10 ** (cue["peak_ceiling_dbfs"] / 20) / sinc_true_peak(sound)
        applied_gain = min(rms_gain, peak_gain)
        sound *= applied_gain
        master = args.root / cue["source_path"]
        runtime = args.root / cue["runtime_path"]
        write_wave(master, sound, rate, 24, cue["seed"] + 24000)
        write_wave(runtime, sound, rate, 16, cue["seed"] + 16000)
        report["cues"].append({
            "cue_id": cue["cue_id"], "manifest_id": cue["manifest_id"],
            "sample_count": len(sound), "duration_seconds": len(sound) / rate,
            "channels": 1, "sample_rate": rate, "master_bit_depth": 24,
            "runtime_bit_depth": 16, "seed": cue["seed"],
            "dither_seed_master": cue["seed"] + 24000,
            "dither_seed_runtime": cue["seed"] + 16000,
            "render_scale_db": db(applied_gain),
            "float_rms_dbfs": db(float(np.sqrt(np.mean(sound ** 2)))),
            "float_sample_peak_dbfs": db(float(np.max(np.abs(sound)))),
            "float_true_peak_estimate_dbtp": db(sinc_true_peak(sound)),
            "intended_gain_db": cue["intended_gain_db"],
            "source_sha256": digest(master), "runtime_sha256": digest(runtime),
            "level_safety_cap_applied": peak_gain < rms_gain,
        })
    report_path = args.root / "source-assets/audio/sfx/generation-report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered {len(report['cues'])} runtime WAVs and matching 24-bit masters.")
    print(f"Generation report: {report_path}")


if __name__ == "__main__":
    main()
