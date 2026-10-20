"""Independent RC-019 crypt loop audit. Music remains pending by owner choice.

Uses the already-installed Blender libsndfile for independent file decoding.
Loudness follows the BS.1770-5 stereo weighting/gates with a causal truncated
impulse response; true peak is an 8x sinc estimate. Neither meter is certified.
"""
from __future__ import annotations

import ctypes
import hashlib
import json
import math
import os
import platform
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "output/qa/rc-019"
SOURCE = ROOT / "source-assets/audio/ambience/crypt"
LIBRARY = Path(r"C:\Program Files\Blender Foundation\Blender 5.2\blender.shared\sndfile.dll")
ITU_REFERENCE = "https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf"


class SFInfo(ctypes.Structure):
    _fields_ = [("frames", ctypes.c_int64), ("samplerate", ctypes.c_int),
                ("channels", ctypes.c_int), ("format", ctypes.c_int),
                ("sections", ctypes.c_int), ("seekable", ctypes.c_int)]


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def db(value):
    return float(20 * math.log10(max(float(value), 1e-15)))


def read_audio(path):
    with os.add_dll_directory(str(LIBRARY.parent)):
        lib = ctypes.CDLL(str(LIBRARY))
    lib.sf_open.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(SFInfo)]
    lib.sf_open.restype = ctypes.c_void_p
    lib.sf_readf_double.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_double), ctypes.c_int64]
    lib.sf_readf_double.restype = ctypes.c_int64
    lib.sf_close.argtypes = [ctypes.c_void_p]
    lib.sf_version_string.restype = ctypes.c_char_p
    info = SFInfo()
    handle = lib.sf_open(str(path).encode("utf-8"), 0x10, ctypes.byref(info))
    if not handle:
        raise ValueError("Cannot independently decode " + str(path))
    try:
        samples = np.empty((info.frames, info.channels), dtype=np.float64)
        read = 0
        while read < info.frames:
            count = min(4096, info.frames-read)
            view = samples[read:read+count]
            received = lib.sf_readf_double(handle, view.ctypes.data_as(ctypes.POINTER(ctypes.c_double)), count)
            if received != count:
                raise ValueError("Incomplete decoded frame count")
            read += received
    finally:
        lib.sf_close(handle)
    return samples, {"sample_rate_hz": info.samplerate, "channels": info.channels,
                    "sample_count": info.frames, "format_code": info.format,
                    "decoder": lib.sf_version_string().decode()}


def integrated_loudness(samples):
    # ITU-R BS.1770-5 Annex 1 tables 1 and 2, fixed 48 kHz coefficients.
    numerator = np.convolve([1.53512485958697, -2.69169618940638, 1.19839281085285], [1, -2, 1])
    denominator = np.convolve([1, -1.69065929318241, .73248077421585], [1, -1.99004745483398, .99007225036621])
    impulse = np.zeros(32768)
    for index in range(len(impulse)):
        impulse[index] = (numerator[index] if index < len(numerator) else 0.0) - sum(
            denominator[lag] * impulse[index-lag] for lag in range(1, min(index+1, len(denominator))))
    size = 1 << (len(samples) + len(impulse) - 2).bit_length()
    transfer = np.fft.rfft(impulse, n=size)
    weighted = np.empty_like(samples)
    for channel in range(2):
        weighted[:, channel] = np.fft.irfft(np.fft.rfft(samples[:, channel], n=size) * transfer, n=size)[:len(samples)]
    energy = np.sum(weighted * weighted, axis=1)  # Left/right channel weights are both one.
    cumulative = np.concatenate(([0.0], np.cumsum(energy)))
    starts = np.arange(0, len(samples) - 19200 + 1, 4800)
    powers = (cumulative[starts+19200] - cumulative[starts]) / 19200
    levels = -.691 + 10 * np.log10(np.maximum(powers, 1e-30))
    absolute = levels > -70
    if not np.any(absolute):
        return -300.0
    relative = -.691 + 10 * np.log10(np.mean(powers[absolute])) - 10
    gate = absolute & (levels > relative)
    return float(-.691 + 10 * np.log10(np.mean(powers[gate])))


def true_peak(samples):
    # Include the cyclic boundary rather than assuming silence outside a loop.
    periodic = np.concatenate((samples[-128:], samples, samples[:128]))
    peak = float(np.max(np.abs(periodic)))
    k = np.arange(-47, 49, dtype=float)
    for phase in range(1, 8):
        kernel = np.sinc(k - phase/8) * np.kaiser(96, 10)
        kernel /= kernel.sum()
        for channel in range(2):
            peak = max(peak, float(np.max(np.abs(np.convolve(periodic[:, channel], kernel, mode="valid")))))
    return db(peak)


def seam_metrics(samples, rate):
    width = round(.05 * rate)
    left_rms = np.sqrt(np.mean(samples[-width:] ** 2))
    right_rms = np.sqrt(np.mean(samples[:width] ** 2))
    delta = float(np.max(np.abs(samples[0] - samples[-1])))
    interior = np.abs(np.diff(samples, axis=0))
    quantile = float(np.quantile(interior, .999))
    around = np.concatenate((samples[-2*width:], samples[:2*width]))
    silent = np.max(np.abs(around), axis=1) < 1e-6
    runs = np.diff(np.concatenate(([False], silent, [False])).astype(int))
    starts, ends = np.flatnonzero(runs == 1), np.flatnonzero(runs == -1)
    maximum_gap = int(np.max(ends-starts, initial=0))
    return {"boundary_max_channel_delta": delta, "boundary_delta_dbfs": db(delta),
            "interior_adjacent_delta_p99_9": quantile,
            "boundary_delta_limit": max(.001, 2*quantile),
            "last_50ms_rms_dbfs": db(left_rms), "first_50ms_rms_dbfs": db(right_rms),
            "boundary_50ms_rms_difference_db": abs(db(left_rms)-db(right_rms)),
            "longest_near_zero_gap_around_boundary_ms": maximum_gap/rate*1000}


def measure(path):
    samples, metadata = read_audio(path)
    return {**metadata, "path": path.relative_to(ROOT).as_posix(), "sha256": sha(path), "bytes": path.stat().st_size,
            "duration_seconds": len(samples)/metadata["sample_rate_hz"],
            "average_bitrate_kbps": path.stat().st_size*8/(len(samples)/metadata["sample_rate_hz"])/1000,
            "sample_peak_dbfs": db(np.max(np.abs(samples))), "estimated_true_peak_dbtp": true_peak(samples),
            "integrated_loudness_lufs_estimate": integrated_loudness(samples),
            "dc_offset_per_channel": np.mean(samples, axis=0).tolist(),
            "clipped_or_out_of_range_samples": int(np.count_nonzero(np.abs(samples) >= 1)),
            "all_samples_finite": bool(np.all(np.isfinite(samples))),
            "seam": seam_metrics(samples, metadata["sample_rate_hz"])}, samples


def main():
    checks, failures = [], []
    def check(ok, label):
        checks.append(label)
        if not ok:
            failures.append(label)
    catalogue = load(ROOT / "docs/audio-loop-catalogue.json")
    entries = {cue["cue_id"]: cue for cue in catalogue["cues"]}
    check(set(entries) == {"home_exploration", "combat", "crypt"} and len(catalogue["cues"]) == 3,
          "exactly two pending music slots and one crypt ambience slot")
    check(catalogue["music_status"] == "pending_by_owner_choice", "music explicitly pending by owner choice")
    for cue_id in ("home_exploration", "combat"):
        cue = entries[cue_id]
        check(cue["status"] == "pending_source" and not (ROOT / cue["runtime_path"]).exists(), cue_id + ": no substitute music exported")
    cue = entries["crypt"]
    check(cue["status"] == "delivered" and cue["manifest_id"] == "crypt_ambience", "crypt delivered under stable manifest ID")
    runtime_path, master_path = ROOT / cue["runtime_path"], ROOT / cue["source_path"]
    runtime, rx = measure(runtime_path)
    master, mx = measure(master_path)
    for measurement, label in ((runtime, "Vorbis runtime"), (master, "PCM working master")):
        check(measurement["sample_rate_hz"] == 48000 and measurement["channels"] == 2, label + ": 48 kHz stereo")
        check(30 <= measurement["duration_seconds"] <= 60, label + ": 30–60 second loop")
        check(measurement["all_samples_finite"] and measurement["clipped_or_out_of_range_samples"] == 0, label + ": finite unclipped audio")
        check(max(abs(x) for x in measurement["dc_offset_per_channel"]) < .0001, label + ": negligible DC")
        check(-29 <= measurement["integrated_loudness_lufs_estimate"] <= -23, label + ": ambience loudness target")
        check(measurement["estimated_true_peak_dbtp"] <= -3, label + ": true-peak headroom")
        check(measurement["sample_count"] == cue["loop_end_sample"] and cue["loop_start_sample"] == 0, label + ": exact whole-file loop points")
        seam = measurement["seam"]
        check(seam["boundary_max_channel_delta"] <= seam["boundary_delta_limit"], label + ": boundary has no exceptional sample step")
        check(seam["boundary_50ms_rms_difference_db"] <= 3, label + ": boundary envelope remains within 3 dB")
        check(seam["longest_near_zero_gap_around_boundary_ms"] < 5, label + ": no decoder silence gap at boundary")
    check((runtime["format_code"] & 0x0FFF0000) == 0x200000 and (runtime["format_code"] & 0xFFFF) == 0x0060,
          "runtime is Ogg Vorbis, not renamed audio")
    check((master["format_code"] & 0x0FFF0000) == 0x010000 and (master["format_code"] & 0xFFFF) == 0x0003,
          "working master is 24-bit PCM WAV")
    check(96 <= runtime["average_bitrate_kbps"] <= 128, "runtime average bitrate in planned range")
    check(runtime["bytes"] <= 8*1024*1024, "current long-audio compressed payload within 8 MiB budget")
    original = load(SOURCE / "generation.json")
    check(sha(ROOT / original["original_path"]) == original["sha256"], "retained Runway original hash")
    check(original["requested"]["loop"] is True and original["seed"] is None, "actual loop request and unavailable provider seed recorded")
    settings = load(ROOT / catalogue["source_settings"])
    rendered = load(ROOT / "source-assets/audio/loop-generation-report.json")
    check(rendered["settings_sha256"] == sha(ROOT / catalogue["source_settings"])
          and rendered["renderer_sha256"] == sha(ROOT / catalogue["source_renderer"]), "current editable settings and renderer hashes")
    check({track["cue_id"] for track in settings["tracks"] if track["export_enabled"]} == {"crypt"}, "settings enable ambience only")
    check(len(rendered["tracks"]) == 1 and rendered["tracks"][0]["cue_id"] == "crypt", "render report contains only delivered ambience")
    record = rendered["tracks"][0]
    for field, actual in (("runtime_sha256", runtime["sha256"]), ("source_sha256", master["sha256"]), ("original_sha256", original["sha256"])):
        check(record[field] == actual and cue[field] == actual, "source/export/catalogue hash agreement " + field)
    check(record["loop_end_sample_exclusive"] == cue["loop_end_sample"], "rendered loop point agreement")
    protected = load(QA / "preservation-before.json")["files"]
    changed = [path for path, digest in protected.items() if not (ROOT/path).is_file() or sha(ROOT/path) != digest]
    for path in protected:
        check(path not in changed, "protected production/SFX file unchanged " + path)
    dump(QA / "preservation-after.json", {"checked": len(protected), "unchanged": len(protected)-len(changed), "changed_or_missing": changed})
    godot = load(QA / "godot-playback.json")
    check(godot["passed"] and not godot["failures"], "pinned Godot imported playback successful")
    check(godot["runtime_sha256"] == runtime["sha256"] and godot["catalogue_sha256"] == sha(ROOT / "docs/audio-loop-catalogue.json"),
          "Godot report matches current runtime and loop contract")
    check(godot["imported_loop"] and godot["imported_loop_offset_seconds"] == 0 and godot["loop_count"] >= 5,
          "actual imported Vorbis wraps at least five times")
    capture_path = ROOT / godot["capture_path"]
    check(sha(capture_path) == godot["capture_sha256"], "five-wrap decoded capture hash")
    capture = np.fromfile(capture_path, dtype="<f4").reshape(-1, 2)
    check(len(capture) == godot["captured_frames"] and np.all(np.isfinite(capture)), "five-wrap capture frame count and finiteness")
    check(np.max(np.abs(capture)) < 1 and np.count_nonzero(capture) > len(capture), "five-wrap capture nonzero unclipped stereo")
    # Assess all five actual boundaries within the engine's observed block windows.
    # The loop decoder may prebuffer; inspect +/- two blocks around each observation.
    engine_seams = []
    engine_delta_limit = max(.001, 2*float(np.quantile(np.abs(np.diff(capture, axis=0)), .999)))
    for observation in godot["wrap_observations"][:5]:
        end = observation["observed_after_mix_frame"]
        window = capture[max(0, end-8192):min(len(capture), end+4096)]
        delta = float(np.max(np.abs(np.diff(window, axis=0))))
        engine_seams.append({"loop_count": observation["loop_count"], "window_start_frame": max(0, end-8192),
                             "window_end_frame": min(len(capture), end+4096), "max_adjacent_delta": delta,
                             "adjacent_delta_limit": engine_delta_limit,
                             "rms_dbfs": db(np.sqrt(np.mean(window.astype(float)**2)))})
        check(np.all(np.isfinite(window)) and np.max(np.abs(window)) > 1e-6, "engine boundary " + str(observation["loop_count"]) + ": finite audible-level samples")
        check(delta <= engine_delta_limit, "engine boundary " + str(observation["loop_count"]) + ": no exceptional discontinuity in wrap window")
    check(len(engine_seams) == 5, "five engine loop-boundary windows inspected")
    report = {"schema_version": 1, "task": "RC-019", "scope": "crypt ambience technical delivery only; music pending by owner choice",
              "status": "fail" if failures else "pass", "checks": len(checks), "failures": failures,
              "tool": {"script": "tools/validate_loop_audio.py", "script_sha256": sha(Path(__file__)),
                       "python": platform.python_version(), "numpy": np.__version__, "decoder_library": str(LIBRARY),
                       "loudness": "BS.1770-5 stereo K-weighting, published 48 kHz coefficients, causal 32768-tap impulse response, FFT linear convolution, 400 ms blocks/75% overlap, -70 absolute and -10 relative gates; estimate, not certified",
                       "loudness_reference": ITU_REFERENCE,
                       "true_peak": "8x fractional-sample reconstruction, 96-tap Kaiser beta 10 sinc; cyclic boundary included; estimate, not certified"},
              "catalogue_sha256": sha(ROOT / "docs/audio-loop-catalogue.json"), "runtime": runtime, "master": master,
              "codec_difference": {"rms_error_dbfs": db(np.sqrt(np.mean((rx-mx)**2))) if rx.shape == mx.shape else None,
                                   "same_frame_count": rx.shape == mx.shape},
              "godot_report_sha256": sha(QA / "godot-playback.json"), "engine_boundary_windows": engine_seams,
              "listening_review": "No physical headphone, ordinary-speaker or mobile review performed. Five decoder wraps and seam statistics do not establish perceptual seam acceptance.",
              "music_status": "pending_by_owner_choice"}
    dump(QA / "audio-loop-validation.json", report)
    print(json.dumps({key: report[key] for key in ("status", "checks", "failures", "scope")}, indent=2))
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())
