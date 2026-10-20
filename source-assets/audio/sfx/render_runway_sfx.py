"""RC-018 Runway-source editor and PCM exporter; Python 3 + NumPy, no installs.

The MP3 originals are immutable inputs. PCM masters are editing/export masters,
not recovered lossless originals. Processing is deterministic for those bytes.
Godot decodes offline to float32; NumPy preserves the source gesture while
trimming quiet edges, resampling, gently filtering, fading and matching roles.

    python source-assets/audio/sfx/render_runway_sfx.py
    python source-assets/audio/sfx/render_runway_sfx.py --output-root output/qa/rc-018/reproduction

--cue may be repeated for an isolated subset preview. The default processes all
21 cues only after confirming that every required original exists. No network,
generation request, gameplay edits, or version control operations are performed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import subprocess
import wave

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(value: float) -> float:
    return float(20 * math.log10(max(abs(float(value)), 1e-15)))


def save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def sinc_resample(x: np.ndarray, source_rate: int, target_rate: int) -> np.ndarray:
    """Band-limited 96-tap Kaiser-sinc interpolation; no pitch/time change."""
    if source_rate == target_rate:
        return x.copy()
    count = round(len(x) * target_rate / source_rate)
    result = np.zeros(count, dtype=np.float64)
    half = 48
    cutoff = min(1.0, target_rate / source_rate) * 0.96
    offsets = np.arange(-half + 1, half + 1)
    denominator = np.i0(9.0)
    for start in range(0, count, 4096):
        positions = np.arange(start, min(start + 4096, count)) * source_rate / target_rate
        indices = np.floor(positions).astype(np.int64)[:, None] + offsets
        distance = positions[:, None] - indices
        window = np.i0(9.0 * np.sqrt(np.maximum(0.0, 1 - (distance / half) ** 2))) / denominator
        kernel = cutoff * np.sinc(cutoff * distance) * window
        kernel *= np.abs(distance) <= half
        kernel /= np.sum(kernel, axis=1, keepdims=True)
        valid = (indices >= 0) & (indices < len(x))
        samples = x[np.clip(indices, 0, len(x) - 1)] * valid
        result[start:start + len(positions)] = np.sum(samples * kernel, axis=1)
    return result


def soft_filter(x: np.ndarray, rate: int, highpass: float, lowpass: float) -> np.ndarray:
    """Zero-padded zero-phase rolloffs; broad per-material settings, no resonator."""
    pad = min(len(x), round(rate * .1))
    work = np.pad(x, (pad, pad))
    frequencies = np.fft.rfftfreq(len(work), 1 / rate)
    safe = np.maximum(frequencies, 1.0)
    response = 1 / np.sqrt(1 + (highpass / safe) ** 4)
    if lowpass > 0:
        response *= 1 / np.sqrt(1 + (safe / lowpass) ** 12)
    response[0] = 0
    return np.fft.irfft(np.fft.rfft(work) * response, n=len(work))[pad:pad + len(x)]


def edge_edit(x: np.ndarray, rate: int, cue: dict) -> tuple[np.ndarray, dict]:
    """Detect edge silence only, retain internal pauses and the natural envelope."""
    edit = cue["edit"]
    start = round(edit.get("source_start_seconds", 0) * rate)
    stop = min(len(x), round(edit.get("source_end_seconds", len(x) / rate) * rate))
    if not 0 <= start < stop:
        raise ValueError(f"{cue['cue_id']}: invalid source edit bounds")
    y = x[start:stop].copy()
    width = max(1, round(edit["trim_window_ms"] * rate / 1000))
    envelope = np.sqrt(np.convolve(y * y, np.ones(width) / width, mode="same"))
    threshold = max(float(np.max(envelope)) * 10 ** (edit["trim_relative_db"] / 20), 1e-6)
    active = np.flatnonzero(envelope >= threshold)
    if not len(active) or np.max(np.abs(y)) < 1e-6:
        raise ValueError(f"{cue['cue_id']}: silent original")
    left = max(0, int(active[0]) - round(edit["pre_roll_ms"] * rate / 1000))
    right = min(len(y), int(active[-1]) + 1 + round(edit["post_roll_ms"] * rate / 1000))
    y = y[left:right]
    maximum = round(cue["duration_max_seconds"] * rate)
    minimum = round(cue["duration_min_seconds"] * rate)
    cropped = 0
    crop_start = 0
    if len(y) > maximum:
        # Short cue prompts normally produce an isolated gesture. If a provider
        # overrun remains, keep the specified contiguous window, without speed
        # change or repeated synthetic hits. Explicit bounds can override this.
        cropped = len(y) - maximum
        if edit.get("overlength_window", "onset") == "highest_energy":
            integral = np.concatenate(([0.0], np.cumsum(y * y)))
            energy = integral[maximum:] - integral[:-maximum]
            crop_start = int(np.argmax(energy))
        y = y[crop_start:crop_start + maximum]
    padded = max(0, minimum - len(y))
    if padded:
        y = np.pad(y, (0, padded))
    return y, {"trim_threshold_linear_rms": threshold,
        "selected_source_start_seconds": (start + left + crop_start) / rate,
        "selected_source_end_seconds": (start + left + crop_start + len(y) - padded) / rate,
        "removed_overlength_seconds": cropped / rate, "minimum_duration_padding_seconds": padded / rate,
        "time_stretch": False, "pitch_shift": False, "natural_envelope_preserved": True}


def taper_and_center(x: np.ndarray, rate: int, fade_in_ms: float, fade_out_ms: float) -> np.ndarray:
    window = np.ones(len(x))
    incoming = min(len(x), max(2, round(rate * fade_in_ms / 1000)))
    outgoing = min(len(x), max(2, round(rate * fade_out_ms / 1000)))
    window[:incoming] *= np.sin(np.linspace(0, np.pi / 2, incoming)) ** 2
    window[-outgoing:] *= np.cos(np.linspace(0, np.pi / 2, outgoing)) ** 2
    x = x * window
    x -= window * (float(np.sum(x)) / float(np.sum(window)))
    x[0] = x[-1] = 0
    return x


def true_peak(x: np.ndarray) -> float:
    peak = float(np.max(np.abs(x)))
    positions = np.arange(-47, 49, dtype=float)
    for phase in range(1, 8):
        kernel = np.sinc(positions - phase / 8) * np.kaiser(96, 10)
        kernel /= np.sum(kernel)
        peak = max(peak, float(np.max(np.abs(np.convolve(x, kernel, mode="full")))))
    return peak


def level(x: np.ndarray, target_rms_dbfs: float, ceiling_dbfs: float) -> tuple[np.ndarray, float, bool]:
    rms = float(np.sqrt(np.mean(x * x)))
    if rms < 1e-10 or not np.all(np.isfinite(x)):
        raise ValueError("Silent or nonfinite audio")
    rms_gain = 10 ** (target_rms_dbfs / 20) / rms
    peak_gain = 10 ** (ceiling_dbfs / 20) / true_peak(x)
    gain = min(rms_gain, peak_gain)
    return x * gain, gain, peak_gain < rms_gain


def pcm_bytes(x: np.ndarray, depth: int, seed: int) -> bytes:
    scale = 2 ** (depth - 1)
    rng = np.random.default_rng(seed)
    dither = rng.random(len(x)) - rng.random(len(x))
    integers = np.clip(np.rint(x * scale + dither), -scale, scale - 1).astype(np.int32)
    integers[0] = integers[-1] = 0
    if depth == 16:
        return integers.astype("<i2").tobytes()
    packed = np.empty((len(integers), 3), dtype=np.uint8)
    for byte in range(3):
        packed[:, byte] = (integers >> (8 * byte)) & 255
    return packed.tobytes()


def write_wave(path: Path, x: np.ndarray, rate: int, depth: int, seed: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(depth // 8)
        handle.setframerate(rate)
        handle.writeframes(pcm_bytes(x, depth, seed))


def decode(root: Path, settings: dict, cues: list[dict], godot: Path, cache: Path, force: bool) -> dict:
    sources = [{"cue_id": cue["cue_id"], "path": str((root / cue["original_path"]).resolve())} for cue in cues]
    missing = [s["path"] for s in sources if not Path(s["path"]).is_file()]
    if missing:
        raise FileNotFoundError("Required originals absent; nothing rendered: " + ", ".join(missing))
    report_path = cache / "decode-report.json"
    if report_path.exists() and not force:
        report = json.loads(report_path.read_text(encoding="utf-8-sig"))
        indexed = {cue["cue_id"]: cue for cue in report["cues"]}
        good = report["passed"] and all(s["cue_id"] in indexed and
            indexed[s["cue_id"]]["original_sha256"] == sha(Path(s["path"])) and
            Path(indexed[s["cue_id"]]["pcm_path"]).is_file() and
            indexed[s["cue_id"]]["pcm_sha256"] == sha(Path(indexed[s["cue_id"]]["pcm_path"])) for s in sources)
        if good:
            return report
    cache.mkdir(parents=True, exist_ok=True)
    manifest = cache / "manifest.json"
    save_json(manifest, {"sources": sources})
    env = os.environ.copy()
    env["APPDATA"] = str(cache / "godot-user")
    env["LOCALAPPDATA"] = str(cache / "godot-user-local")
    Path(env["APPDATA"]).mkdir(parents=True, exist_ok=True)
    Path(env["LOCALAPPDATA"]).mkdir(parents=True, exist_ok=True)
    command = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(root),
               "--script", "res://tools/decode_sfx_sources.gd", "--", f"--manifest={manifest}", f"--output-dir={cache}"]
    result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=60)
    (cache / "decode.log").write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode or "SCRIPT ERROR" in result.stderr or "Parse Error" in result.stderr:
        raise RuntimeError("Godot decoder failed; inspect " + str(cache / "decode.log"))
    report = json.loads(report_path.read_text(encoding="utf-8-sig"))
    if not report["passed"]:
        raise RuntimeError("Godot decoder reported failure: " + str(report["failures"]))
    return report


def mono_source(record: dict) -> tuple[np.ndarray, dict]:
    stereo = np.fromfile(record["pcm_path"], dtype="<f4").astype(np.float64).reshape(-1, 2)
    if len(stereo) != record["frames"] or not np.all(np.isfinite(stereo)):
        raise ValueError("Invalid decoded PCM")
    mono = np.mean(stereo, axis=1)
    channel_rms = np.sqrt(np.mean(stereo * stereo, axis=0))
    mono_rms = float(np.sqrt(np.mean(mono * mono)))
    cancellation_db = db(mono_rms / max(float(max(channel_rms)), 1e-12))
    choice = "arithmetic mean L/R (-6.02 dB each), with phase-cancellation check"
    if cancellation_db < -16:
        channel = int(np.argmax(channel_rms))
        mono = stereo[:, channel].copy()
        choice = f"channel {channel} selected because stereo mean cancellation exceeded 16 dB"
    return mono, {"mono_method": choice, "downmix_cancellation_db": cancellation_db}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", type=Path, default=HERE / "runway-settings.json")
    parser.add_argument("--root", type=Path, default=ROOT, help="Input repository root")
    parser.add_argument("--output-root", type=Path, help="Separate export root for deterministic reproduction")
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--force-decode", action="store_true")
    parser.add_argument("--cue", action="append", default=[])
    args = parser.parse_args()
    if args.cue and args.output_root is None:
        parser.error("--cue requires --output-root so a subset cannot overwrite the full delivery report")
    root = args.root.resolve()
    output_root = (args.output_root or root).resolve()
    settings = json.loads(args.settings.read_text(encoding="utf-8-sig"))
    rate = int(settings["sample_rate"])
    cue_map = {cue["cue_id"]: cue for cue in settings["cues"]}
    selected = [cue_map[name] for name in args.cue] if args.cue else list(cue_map.values())
    needed = list(selected)
    stem_spec = settings["shared_enemy_base"]
    if any(cue.get("shared_enemy_base", False) for cue in selected) and stem_spec["source_cue"] not in [c["cue_id"] for c in needed]:
        needed.append(cue_map[stem_spec["source_cue"]])
    cache = root / settings["decoded_directory"]
    decoder_report = decode(root, settings, needed, args.godot or root / settings["godot_binary"], cache, args.force_decode)
    decoded = {cue["cue_id"]: cue for cue in decoder_report["cues"]}
    edited, edits = {}, {}
    for cue in needed:
        cue_id = cue["cue_id"]
        record = decoded[cue_id]
        mono, downmix = mono_source(record)
        trimmed, edit = edge_edit(mono, record["sample_rate"], cue)
        x = sinc_resample(trimmed, record["sample_rate"], rate)
        x = soft_filter(x, rate, cue["edit"]["highpass_hz"], cue["edit"]["lowpass_hz"])
        x = taper_and_center(x, rate, cue["fade_in_ms"], cue["fade_out_ms"])
        edited[cue_id] = x
        edits[cue_id] = {**edit, **downmix, "source_sample_rate": record["sample_rate"],
            "resampler": "96-tap Kaiser-windowed sinc, beta9, 0.96 Nyquist cutoff, float64 accumulation"}
    stem = None
    stem_path = output_root / stem_spec["source_path"]
    if any(cue.get("shared_enemy_base", False) for cue in selected):
        source = edited[stem_spec["source_cue"]]
        begin = round(stem_spec["source_start_seconds"] * rate)
        count = round(stem_spec["duration_seconds"] * rate)
        stem = source[begin:begin + count].copy()
        if len(stem) < count:
            stem = np.pad(stem, (0, count - len(stem)))
        stem = soft_filter(stem, rate, stem_spec["highpass_hz"], stem_spec["lowpass_hz"])
        stem = taper_and_center(stem, rate, stem_spec["fade_in_ms"], stem_spec["fade_out_ms"])
        stem, _, _ = level(stem, stem_spec["target_rms_dbfs"], stem_spec["peak_ceiling_dbfs"])
        stem_path.parent.mkdir(parents=True, exist_ok=True)
        np.save(stem_path, stem.astype("<f8"), allow_pickle=False)
    report = {"schema_version": 1, "task": "RC-018", "revision": settings["revision"],
        "settings_path": args.settings.resolve().relative_to(root).as_posix(),
        "generator_path": Path(__file__).resolve().relative_to(root).as_posix(),
        "settings_sha256": sha(args.settings), "generator_sha256": sha(Path(__file__)),
        "decoder_script_sha256": sha(root / "tools/decode_sfx_sources.gd"),
        "python_version": platform.python_version(), "numpy_version": np.__version__,
        "decoder_engine": decoder_report["engine"], "decoder_sample_rate": decoder_report["sample_rate"],
        "source_mode": settings["source_type"], "source_fidelity": settings["source_fidelity"],
        "shared_enemy_base_sha256": sha(stem_path) if stem is not None else None,
        "shared_enemy_base_source_path": stem_spec["source_path"] if stem is not None else None,
        "true_peak_method": "8x fractional reconstruction, 96 taps/phase Kaiser beta10; estimate, not certified meter",
        "level_method": "Per-role whole-file RMS target and individual true-peak cap; no compressor/limiter or integrated LUFS claim",
        "listening_review": "No agent perceptual/headphone/speaker listening claimed. Owner approved the five r002 source candidates; edited full-library exports require owner review.",
        "cues": []}
    for cue in selected:
        cue_id = cue["cue_id"]
        x = edited[cue_id].copy()
        # Establish accent level before adding the exact common air gesture.
        # Enemy accents retain their separate recorded/generated textures.
        if cue.get("shared_enemy_base", False):
            x, _, _ = level(x, cue["target_rms_dbfs"], cue["peak_ceiling_dbfs"])
            x[:len(stem)] += stem
        x, gain, capped = level(x, cue["target_rms_dbfs"], cue["peak_ceiling_dbfs"])
        master = output_root / cue["source_path"]
        runtime = output_root / cue["runtime_path"]
        seed = cue["dither_seed"]
        write_wave(master, x, rate, 24, seed + 24000)
        write_wave(runtime, x, rate, 16, seed + 16000)
        report["cues"].append({"cue_id": cue_id, "manifest_id": cue["manifest_id"],
            "original_path": cue["original_path"], "original_sha256": sha(root / cue["original_path"]),
            "source_path": cue["source_path"], "runtime_path": cue["runtime_path"],
            "source_sha256": sha(master), "runtime_sha256": sha(runtime),
            "source_mode": settings["source_type"], "source_fidelity": settings["source_fidelity"],
            "decoder_pcm_sha256": decoded[cue_id]["pcm_sha256"],
            "sample_count": len(x), "duration_seconds": len(x) / rate,
            "channels": 1, "sample_rate": rate, "master_bit_depth": 24, "runtime_bit_depth": 16,
            "dither_seed_master": seed + 24000, "dither_seed_runtime": seed + 16000,
            "render_scale_db": db(gain), "float_rms_dbfs": db(np.sqrt(np.mean(x * x))),
            "float_sample_peak_dbfs": db(np.max(np.abs(x))), "float_true_peak_estimate_dbtp": db(true_peak(x)),
            "intended_gain_db": cue["intended_gain_db"], "level_safety_cap_applied": capped,
            "shared_enemy_base": cue.get("shared_enemy_base", False),
            "shared_enemy_base_pre_export_gain_db": 0 if cue.get("shared_enemy_base", False) else None,
            "edit": edits[cue_id]})
    report_path = output_root / "source-assets/audio/sfx/runway-generation-report.json"
    save_json(report_path, report)
    print(f"Rendered {len(selected)} Runway-derived runtime WAVs and matching PCM editing masters.")
    print(f"Generation report: {report_path}")


if __name__ == "__main__":
    main()
