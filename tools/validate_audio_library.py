"""Focused RC-018 asset audit; never invokes version control or gameplay suites.

Requires the already-bundled NumPy. True peak is an explicitly approximate
8x, 96-tap-per-phase Kaiser-windowed sinc reconstruction, not a certified meter.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import math
import platform
import sys
import wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "output/qa/rc-018"
EXPECTED = {
    "sfx_ui_confirm": (["ui_confirm"], .05, .20),
    "sfx_ui_back": (["ui_back"], .05, .20),
    "sfx_place": (["edit_place"], .05, .25),
    "sfx_rotate": (["edit_orient"], .05, .20),
    "sfx_undo": (["edit_restore"], .05, .25),
    "sfx_invalid": (["action_rejected"], .08, .25),
    "sfx_technique": (["technique_draw", "technique_conjure"], .15, .50),
    "sfx_cast": (["cast"], .25, .60),
    "sfx_impact": (["damage"], .10, .40),
    "sfx_shield": (["shield"], .15, .45),
    "sfx_enemy_attack": (["spectral", "flame", "stone", "chain", "bell"], .20, .60),
    "sfx_expiry": (["temporary_expired"], .10, .35),
    "sfx_reward": (["reward"], .20, .65),
    "sfx_victory": (["victory"], .60, 1.80),
    "sfx_defeat": (["defeat"], .60, 1.80),
    "sfx_phase": (["guardian_phase_changed"], .30, .80),
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

def inventory():
    with (ROOT / "docs/asset-inventory.csv").open(encoding="utf-8-sig", newline="") as f:
        return {r["id"]: r for r in csv.DictReader(f)}

def snapshot():
    paths = [ROOT / "project.godot", ROOT / "export_presets.cfg"]
    for folder in ("scripts", "scenes", "assets", "data"):
        paths += [p for p in (ROOT / folder).rglob("*") if p.is_file()
                  and "audio" not in p.relative_to(ROOT).parts
                  and p.suffix not in (".import", ".uid")]
    rows = inventory()
    write(QA / "preservation-before.json", {
        "purpose": "RC-018 scope guard, recorded before audio delivery; not a historical-baseline rewrite",
        "files": {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(paths)},
        "manifest_paths": {key: {field: rows[key][field] for field in
            ("source_master_path", "runtime_destination")} for key in EXPECTED},
        "existing_audio_files": [p.relative_to(ROOT).as_posix() for p in (ROOT / "assets").rglob("*")
                                 if p.suffix.lower() in (".wav", ".ogg", ".mp3")],
    })

def db(value):
    return round(20 * math.log10(max(float(value), 1e-12)), 4)

def read_pcm(path):
    with wave.open(str(path), "rb") as f:
        params = f.getparams()
        raw = f.readframes(f.getnframes())
    if params.sampwidth == 2:
        integers = np.frombuffer(raw, dtype="<i2").astype(np.int64)
    elif params.sampwidth == 3:
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3).astype(np.int64)
        integers = b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16)
        integers = np.where(integers & 0x800000, integers - 0x1000000, integers)
    else:
        raise ValueError(f"Unsupported PCM width: {params.sampwidth}")
    return integers / float(2 ** (params.sampwidth * 8 - 1)), params, integers

def true_peak(x):
    peak = float(np.max(np.abs(x)))
    k = np.arange(-47, 49, dtype=float)
    for phase in range(1, 8):
        h = np.sinc(k - phase / 8) * np.kaiser(96, 10)
        h /= np.sum(h)
        peak = max(peak, float(np.max(np.abs(np.convolve(x, h, mode="full")))))
    return peak

def measure(path):
    x, p, ints = read_pcm(path)
    active = np.flatnonzero(np.abs(x) > 10 ** (-60 / 20))
    energy = np.abs(np.fft.rfft(x)) ** 2
    freqs = np.fft.rfftfreq(len(x), 1 / p.framerate)
    energy_total = max(float(energy.sum()), 1e-20)
    n = min(len(x), round(.050 * p.framerate))
    integral = np.concatenate(([0.0], np.cumsum(x * x)))
    rms50 = float(np.sqrt(np.max((integral[n:] - integral[:-n]) / n)))
    return {
        "path": path.relative_to(ROOT).as_posix(), "sha256": sha(path),
        "bytes": path.stat().st_size, "format": "PCM WAV", "compression": p.comptype,
        "sample_rate_hz": p.framerate, "bit_depth": p.sampwidth * 8,
        "channels": p.nchannels, "sample_count": p.nframes,
        "duration_seconds": p.nframes / p.framerate,
        "sample_peak_dbfs": db(np.max(np.abs(x))),
        "estimated_true_peak_dbtp": db(true_peak(x)),
        "rms_dbfs": db(np.sqrt(np.mean(x*x))), "max_50ms_rms_dbfs": db(rms50),
        "dc_offset_linear": float(np.mean(x)), "dc_offset_dbfs": db(abs(np.mean(x))),
        "clipped_samples": int(np.count_nonzero((ints == -(2 ** (p.sampwidth*8-1))) |
                                                (ints == 2 ** (p.sampwidth*8-1) - 1))),
        "leading_below_minus60db_ms": float(active[0] / p.framerate * 1000) if len(active) else 1e9,
        "trailing_below_minus60db_ms": float((len(x)-1-active[-1]) / p.framerate * 1000) if len(active) else 1e9,
        "first_sample": float(x[0]), "last_sample": float(x[-1]),
        "last_1ms_peak_dbfs": db(np.max(np.abs(x[-round(p.framerate*.001):]))),
        "max_adjacent_sample_delta": float(np.max(np.abs(np.diff(x)))),
        "energy_below_60hz_percent": float(100*energy[freqs < 60].sum()/energy_total),
        "energy_above_12khz_percent": float(100*energy[freqs > 12000].sum()/energy_total),
        "integrated_lufs": None,
    }, x

def validate():
    QA.mkdir(parents=True, exist_ok=True)
    checks, failures = [], []
    def check(condition, label):
        checks.append(label)
        if not condition:
            failures.append(label)
    before = json.loads((QA / "preservation-before.json").read_text())
    rows = inventory()
    check({k for k in rows if k.startswith("sfx_")} == set(EXPECTED), "exactly 16 manifest families")
    expected_paths = {f"assets/audio/sfx/{family}/{cue}.wav" for family, (cues, _, _) in EXPECTED.items() for cue in cues}
    found_paths = {p.relative_to(ROOT).as_posix() for p in (ROOT / "assets/audio/sfx").rglob("*.wav")}
    check(found_paths == expected_paths and len(found_paths) == 21, "exactly 21 expected runtime WAV paths")
    for family, paths in before["manifest_paths"].items():
        for field, value in paths.items():
            check(rows[family][field] == value, f"stable {family} {field}")
    preserved = {}
    for path, digest in before["files"].items():
        preserved[path] = (ROOT / path).is_file() and sha(ROOT / path) == digest
        check(preserved[path], f"unchanged production file {path}")
    write(QA / "preservation-after.json", {"checked": len(preserved), "unchanged": sum(preserved.values()),
                                          "changed_or_missing": [p for p,v in preserved.items() if not v]})
    catalogue = json.loads((ROOT / "docs/audio-cue-catalogue.json").read_text(encoding="utf-8"))
    settings_path = catalogue["source_settings"]
    settings = json.loads((ROOT / settings_path).read_text(encoding="utf-8"))
    settings_cues = {r["cue_id"]: r for r in settings["cues"]}
    catalogue_cues = {r["cue_id"]: r for r in catalogue["cues"]}
    check(set(catalogue_cues) == set(settings_cues) and len(catalogue["cues"]) == len(settings["cues"]) == 21,
          "catalogue/settings 21 unique cues")
    check(settings.get("revision") == catalogue.get("revision"), "catalogue/settings active revision agreement")
    future_cues = {"flame", "stone", "chain", "bell", "reward", "guardian_phase_changed"}
    known_events = {"cast", "damage", "shield", "retaliation", "passed", "effect_consumed", "temporary_expired",
                    "board_piece_cleared", "turn_cleanup", "battle_ended", "turn_started", "endpoints_changed",
                    "kit_changed", "reshuffled", "card_drawn", "technique", "card_created", "encounter_transition"}
    hooks = {hook["id"]: hook for hook in catalogue["hooks"]}
    for cue_id, cue in catalogue_cues.items():
        check(cue["future_only"] == (cue_id in future_cues), f"{cue_id}: current/future designation")
        check(not cue["playback_hook_implemented"], f"{cue_id}: no production playback claim")
        check(all(cue.get(field) for field in ("grouping", "deduplication", "cancellation_owner", "rights_record", "source_record")),
              f"{cue_id}: grouping/identity/source contract")
        check(cue["source_record"].split("#", 1)[0] == settings_path,
              f"{cue_id}: source record names active editable settings")
        for field in ("rights_record", "source_record"):
            check((ROOT / cue[field].split("#", 1)[0]).is_file(), f"{cue_id}: {field} exists")
        for binding in cue["bindings"]:
            role = binding["role"]
            check(all(binding.get(field) for field in ("condition", "target", "timing", "normal_motion", "reduced_motion")),
                  f"{cue_id}/{role}: trigger/timing/motion contract")
            check(set(binding["event_types"]).issubset(known_events), f"{cue_id}/{role}: only supplied current event types")
            check(binding["timing"]["hook_id"] in hooks, f"{cue_id}/{role}: declared hook")
            if binding["binding_kind"] == "future_alias":
                check(not binding["event_types"] and binding["aliases_are_runtime_events"] is False,
                      f"{cue_id}/{role}: future aliases not fabricated runtime events")
            if binding["timing"]["hook_id"] == "consequence_committed":
                check(binding["timing"]["moment"] not in ("phase_start", "contact"),
                      f"{cue_id}/{role}: event_presented is post-commit")
    measurements = []
    for family, (cues, low, high) in EXPECTED.items():
        for cue in cues:
            runtime = ROOT / rows[family]["runtime_destination"] / (cue + ".wav")
            master = ROOT / rows[family]["source_master_path"] / (cue + ".wav")
            if not runtime.exists() or not master.exists():
                check(False, f"{cue}: source/runtime both exist")
                continue
            rm, rx = measure(runtime)
            sm, sx = measure(master)
            spec, cat = settings_cues[cue], catalogue_cues[cue]
            recipe_path = Path(str(runtime) + ".import")
            recipe = recipe_path.read_text(encoding="utf-8") if recipe_path.exists() else ""
            check(all(setting in recipe for setting in ("compress/mode=0", "force/8_bit=false", "force/max_rate=false",
                  "edit/trim=false", "edit/normalize=false", "edit/loop_mode=0")), f"{cue}: lossless non-normalizing Godot import")
            for measurement, width in ((rm, 16), (sm, 24)):
                tag = measurement["path"]
                check(measurement["sample_rate_hz"] == 48000 and measurement["bit_depth"] == width
                      and measurement["channels"] == 1 and measurement["compression"] == "NONE", f"{tag}: PCM format")
                check(low <= measurement["duration_seconds"] <= high, f"{tag}: duration range")
                check(measurement["estimated_true_peak_dbtp"] <= -3, f"{tag}: estimated true peak <= -3")
                check(measurement["clipped_samples"] == 0, f"{tag}: no clipping")
                check(abs(measurement["dc_offset_linear"]) < .0001, f"{tag}: negligible DC")
                check(measurement["leading_below_minus60db_ms"] < 25 and measurement["trailing_below_minus60db_ms"] < 100,
                      f"{tag}: trimmed silence")
                check(abs(measurement["first_sample"]) <= 1/32768 and abs(measurement["last_sample"]) <= 1/32768,
                      f"{tag}: smooth endpoints")
                check(measurement["last_1ms_peak_dbfs"] <= -55, f"{tag}: low tail termination")
            check(len(rx) == len(sx), f"{cue}: source/runtime sample correspondence")
            quant_error = float(np.max(np.abs(rx-sx))) if len(rx) == len(sx) else 999
            check(quant_error <= 2 / 32768, f"{cue}: master/runtime quantization correspondence")
            check(cat["manifest_id"] == family and cat["runtime_path"] == rm["path"] and cat["source_path"] == sm["path"],
                  f"{cue}: catalogue manifest/file mapping")
            check(spec["manifest_id"] == family and spec["runtime_path"] == rm["path"] and spec["source_path"] == sm["path"],
                  f"{cue}: settings manifest/file mapping")
            check(float(cat["intended_gain_db"]) == float(spec["intended_gain_db"]), f"{cue}: gain agreement")
            measurements.append({"cue_id": cue, "manifest_id": family, "intended_gain_db": spec["intended_gain_db"],
                "runtime": rm, "master": sm, "max_master_runtime_error": quant_error})
    report = {
        "schema_version": 1, "task": "RC-018", "client_date": "2026-10-17",
        "revision": catalogue.get("revision"), "source_settings": settings_path,
        "source_settings_sha256": sha(ROOT / settings_path),
        "catalogue_sha256": sha(ROOT / "docs/audio-cue-catalogue.json"),
        "status": "pass" if not failures else "fail", "checks": len(checks), "failures": failures,
        "tool": {"script": "tools/validate_audio_library.py", "script_sha256": sha(Path(__file__)),
                 "python": platform.python_version(), "numpy": np.__version__,
                 "true_peak_method": "8x fractional sample reconstruction, 96 taps/phase, Kaiser beta=10, normalized sinc, zero-padded full convolution; estimate, not certified ITU-R BS.1770 meter",
                 "loudness_method": "Whole-file RMS and maximum contiguous 50 ms RMS; no integrated LUFS for short SFX",
                 "silence_threshold_dbfs": -60},
        "listening_review": "No headphone/speaker or perceptual audio-tool review performed by this audit. Measurements do not establish perceived balance or aesthetic acceptance.",
        "measurements": measurements,
        "runtime_payload_bytes": sum(m["runtime"]["bytes"] for m in measurements),
        "master_payload_bytes": sum(m["master"]["bytes"] for m in measurements),
    }
    write(QA / "audio-validation.json", report)
    print(json.dumps({k: report[k] for k in ("status", "checks", "failures", "runtime_payload_bytes", "master_payload_bytes")}, indent=2))
    return bool(failures)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--snapshot", action="store_true", help="Record initial production hashes once, before delivery")
    args = parser.parse_args()
    if args.snapshot:
        if (QA / "preservation-before.json").exists():
            raise SystemExit("Existing baseline retained. Refusing to replace it.")
        snapshot()
        print("Saved RC-018 production preservation snapshot.")
    else:
        sys.exit(validate())
