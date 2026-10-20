"""RC-019 source-derived loop editor: NumPy, pinned Godot and existing libsndfile.

Only enabled tracks export; the two requested music tracks stay pending. Run:
    python source-assets/audio/render_loop_audio.py
No installers, network requests, SFX edits or gameplay changes are performed.
Original MP3 bytes are immutable. A WAV editing master cannot restore MP3 loss.
"""
from __future__ import annotations
import argparse
import ctypes as ct
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
ROOT = HERE.parents[1]
RATE = 48000


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def db(x):
    return float(20 * math.log10(max(float(abs(x)), 1e-15)))


def save_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


class SFInfo(ct.Structure):
    _fields_ = [("frames", ct.c_longlong), ("samplerate", ct.c_int),
        ("channels", ct.c_int), ("format", ct.c_int), ("sections", ct.c_int), ("seekable", ct.c_int)]


class SoundFile:
    def __init__(self, library):
        self.directory_handle = os.add_dll_directory(str(Path(library).parent))
        self.lib = ct.CDLL(str(library))
        self.lib.sf_version_string.restype = ct.c_char_p
        self.version = self.lib.sf_version_string().decode()
        self.lib.sf_open.argtypes = [ct.c_char_p, ct.c_int, ct.POINTER(SFInfo)]
        self.lib.sf_open.restype = ct.c_void_p
        self.lib.sf_command.argtypes = [ct.c_void_p, ct.c_int, ct.c_void_p, ct.c_int]
        self.lib.sf_command.restype = ct.c_int
        self.lib.sf_close.argtypes = [ct.c_void_p]
        self.lib.sf_close.restype = ct.c_int
        self.lib.sf_strerror.argtypes = [ct.c_void_p]
        self.lib.sf_strerror.restype = ct.c_char_p
        for name in ("sf_readf_double", "sf_writef_double"):
            function = getattr(self.lib, name)
            function.argtypes = [ct.c_void_p, ct.POINTER(ct.c_double), ct.c_longlong]
            function.restype = ct.c_longlong

    def read(self, path):
        info = SFInfo()
        handle = self.lib.sf_open(str(path).encode(), 0x10, ct.byref(info))
        if not handle:
            raise RuntimeError(self.lib.sf_strerror(None).decode())
        data = np.zeros((info.frames, info.channels), dtype=np.float64)
        count = 0
        for start in range(0, info.frames, 4096):
            chunk = data[start:min(start + 4096, info.frames)]
            count += self.lib.sf_readf_double(handle, chunk.ctypes.data_as(ct.POINTER(ct.c_double)), len(chunk))
        self.lib.sf_close(handle)
        if count != info.frames or not np.all(np.isfinite(data)):
            raise ValueError("Incomplete/nonfinite decoded audio")
        return data, info

    def ogg(self, path, x, quality):
        path.parent.mkdir(parents=True, exist_ok=True)
        info = SFInfo(0, RATE, 2, 0x200000 | 0x0060, 0, 0)
        handle = self.lib.sf_open(str(path).encode(), 0x20, ct.byref(info))
        if not handle:
            raise RuntimeError(self.lib.sf_strerror(None).decode())
        q = ct.c_double(quality)
        if self.lib.sf_command(handle, 0x1300, ct.byref(q), ct.sizeof(q)) != 1:
            self.lib.sf_close(handle)
            raise RuntimeError("Vorbis quality control unavailable")
        x = np.ascontiguousarray(x, dtype=np.float64)
        # This installed Windows build needs bounded chunks; a whole long loop
        # in one sf_writef_double call can exhaust its native conversion stack.
        frames = 0
        for start in range(0, len(x), 4096):
            chunk = x[start:min(start + 4096, len(x))]
            frames += self.lib.sf_writef_double(handle, chunk.ctypes.data_as(ct.POINTER(ct.c_double)), len(chunk))
        result = self.lib.sf_close(handle)
        if frames != len(x) or result:
            raise RuntimeError("Vorbis write failed")


def resample(x, source_rate):
    if source_rate == RATE:
        return x.copy()
    output = np.zeros((round(len(x) * RATE / source_rate), 2))
    half, beta = 48, 9.0
    offsets = np.arange(-half + 1, half + 1)
    cutoff = min(1.0, RATE / source_rate) * .96
    for begin in range(0, len(output), 4096):
        positions = np.arange(begin, min(begin + 4096, len(output))) * source_rate / RATE
        indices = np.floor(positions).astype(np.int64)[:, None] + offsets
        distance = positions[:, None] - indices
        window = np.i0(beta * np.sqrt(np.maximum(0, 1 - (distance / half) ** 2))) / np.i0(beta)
        kernel = cutoff * np.sinc(cutoff * distance) * window * (np.abs(distance) <= half)
        kernel /= kernel.sum(axis=1, keepdims=True)
        valid = (indices >= 0) & (indices < len(x))
        for channel in range(2):
            values = x[np.clip(indices, 0, len(x) - 1), channel] * valid
            output[begin:begin + len(positions), channel] = np.sum(values * kernel, axis=1)
    return output


def integrated_lufs(x):
    """BS.1770 stereo coefficients/gates; FFT-realized causal IIR, zero-padded2s.

    This implementation is transparent but not a certified commercial meter.
    Coefficients: ITU-R BS.1770-5 Annex1 Tables1/2 (48kHz only).
    """
    size = 1 << (len(x) + 2 * RATE - 1).bit_length()
    z = np.exp(-2j * np.pi * np.fft.rfftfreq(size))
    h = ((1.53512485958697 - 2.69169618940638 * z + 1.19839281085285 * z * z) /
         (1 - 1.69065929318241 * z + .73248077421585 * z * z))
    h *= (1 - 2 * z + z * z) / (1 - 1.99004745483398 * z + .99007225036621 * z * z)
    power = np.zeros(len(x))
    for channel in range(2):
        weighted = np.fft.irfft(np.fft.rfft(x[:, channel], n=size) * h, n=size)[:len(x)]
        power += weighted * weighted
    integral = np.concatenate(([0.0], np.cumsum(power)))
    width, step = round(.4 * RATE), round(.1 * RATE)
    starts = np.arange(0, len(x) - width + 1, step)
    means = (integral[starts + width] - integral[starts]) / width
    loudness = -.691 + 10 * np.log10(np.maximum(means, 1e-30))
    absolute = loudness > -70
    if not np.any(absolute):
        raise ValueError("All loudness blocks below absolute gate")
    relative = -.691 + 10 * np.log10(np.mean(means[absolute])) - 10
    gated = absolute & (loudness > relative)
    return {"integrated_lufs": float(-.691 + 10 * np.log10(np.mean(means[gated]))),
        "absolute_gate_lufs": -70, "relative_gate_lufs": float(relative),
        "blocks_total": len(means), "blocks_after_gates": int(np.sum(gated))}


def true_peak(x):
    peak = float(np.max(np.abs(x)))
    k = np.arange(-47, 49, dtype=float)
    for phase in range(1, 8):
        h = np.sinc(k - phase / 8) * np.kaiser(96, 10)
        h /= h.sum()
        for channel in range(2):
            # Circular padding includes the actual loop boundary in the meter.
            padded = np.concatenate((x[-96:, channel], x[:, channel], x[:96, channel]))
            peak = max(peak, float(np.max(np.abs(np.convolve(padded, h, mode="valid")))))
    return peak


def seam_metrics(x):
    delta = np.abs(x[0] - x[-1])
    adjacent = np.abs(np.diff(x, axis=0))
    rms = lambda y: float(np.sqrt(np.mean(y * y)))
    before, after = x[-RATE:], x[:RATE]
    short = round(.05 * RATE)
    before_short, after_short = x[-short:], x[:short]
    return {"boundary_sample_delta_max": float(delta.max()),
        "boundary_sample_delta_dbfs": db(delta.max()),
        "adjacent_delta_99_9_percentile": float(np.percentile(adjacent, 99.9)),
        "boundary_delta_to_99_9_percentile_ratio": float(delta.max() / max(np.percentile(adjacent, 99.9), 1e-15)),
        "one_second_rms_before_dbfs": db(rms(before)), "one_second_rms_after_dbfs": db(rms(after)),
        "one_second_level_change_db": db(rms(after) / max(rms(before), 1e-15)),
        "fifty_ms_rms_before_dbfs": db(rms(before_short)),
        "fifty_ms_rms_after_dbfs": db(rms(after_short)),
        "fifty_ms_level_change_db": db(rms(after_short) / max(rms(before_short), 1e-15))}


def measurement(x):
    return {**integrated_lufs(x), "sample_count": len(x), "duration_seconds": len(x) / RATE,
        "sample_rate": RATE, "channels": 2, "sample_peak_dbfs": db(np.max(np.abs(x))),
        "estimated_true_peak_dbtp": db(true_peak(x)),
        "dc_offset_per_channel": [float(v) for v in np.mean(x, axis=0)],
        "clipped_samples": int(np.count_nonzero(np.abs(x) >= 1)),
        "stereo_correlation": float(np.corrcoef(x.T)[0, 1]), "seam": seam_metrics(x)}


def wave_bytes(x, bits, seed):
    scale = 2 ** (bits - 1)
    rng = np.random.default_rng(seed)
    dither = rng.random(x.shape) - rng.random(x.shape)
    pcm = np.clip(np.rint(x * scale + dither), -scale, scale - 1).astype(np.int32).reshape(-1)
    if bits == 16:
        return pcm.astype("<i2").tobytes()
    packed = np.empty((len(pcm), 3), dtype=np.uint8)
    for i in range(3):
        packed[:, i] = (pcm >> (8 * i)) & 255
    return packed.tobytes()


def write_wav(path, x, bits, seed, repeats=1):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(bits // 8)
        handle.setframerate(RATE)
        data = wave_bytes(x, bits, seed)
        for _ in range(repeats):
            handle.writeframes(data)


def source_decode(root, settings, track):
    cache = root / track["decoder_cache"]
    cache.mkdir(parents=True, exist_ok=True)
    original = root / track["original_path"]
    manifest = cache / "manifest.json"
    save_json(manifest, {"sources": [{"cue_id": track["cue_id"], "path": str(original)}]})
    env = os.environ.copy()
    env["APPDATA"] = str(cache / "godot-user")
    env["LOCALAPPDATA"] = str(cache / "godot-user-local")
    Path(env["APPDATA"]).mkdir(exist_ok=True)
    Path(env["LOCALAPPDATA"]).mkdir(exist_ok=True)
    command = [str(root / settings["godot_binary"]), "--headless", "--audio-driver", "Dummy",
        "--path", str(root), "--script", "res://tools/decode_loop_audio.gd", "--",
        f"--manifest={manifest}", f"--output-dir={cache}"]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
    (cache / "decode.log").write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode or "SCRIPT ERROR" in result.stderr:
        raise RuntimeError("Godot decoder failed: " + result.stderr)
    report = json.loads((cache / "decode-report.json").read_text())
    if not report["passed"]:
        raise RuntimeError("Godot decoder failures: " + str(report["failures"]))
    record = report["cues"][0]
    x = np.fromfile(record["pcm_path"], dtype="<f4").astype(np.float64).reshape(-1, 2)
    return x, record, report


def build_cycle(x, track):
    start = round(track["source_start_seconds"] * RATE)
    end = min(len(x), round(track["source_end_seconds"] * RATE))
    x = x[start:end]
    overlap = round(track["loop_crossfade_seconds"] * RATE)
    if len(x) <= overlap * 3:
        raise ValueError("Source too short for configured loop overlap")
    phase = np.linspace(0, np.pi / 2, overlap)[:, None]
    blend = x[-overlap:] * np.cos(phase) + x[:overlap] * np.sin(phase)
    # The exported boundary is between consecutive original samples at time
    # overlap; the edit transition is inside the cycle, never a fade to silence.
    cycle = np.concatenate((x[overlap:-overlap], blend))
    frequencies = np.fft.rfftfreq(len(cycle), 1 / RATE)
    response = 1 / np.sqrt(1 + (track["highpass_hz"] / np.maximum(frequencies, 1)) ** 4)
    response[0] = 0
    cycle = np.fft.irfft(np.fft.rfft(cycle, axis=0) * response[:, None], n=len(cycle), axis=0)
    cycle -= np.mean(cycle, axis=0)
    # Vorbis pads coding edges; a nonzero cut can exaggerate a continuous PCM
    # boundary. Rotate to a joint near-zero crossing with a low sample slope.
    # This is a circular shift, not a fade or deletion of room tone.
    search = min(round(track["boundary_alignment_search_seconds"] * RATE), len(cycle) - overlap)
    positions = np.arange(1, search)
    # A zero crossing alone can still sit at a conspicuous envelope change.
    # Keep only crossings with similar short-window energy on either side.
    rms_width = round(track["boundary_rms_window_ms"] * RATE / 1000)
    power = np.mean(cycle * cycle, axis=1)
    circular_power = np.concatenate((power[-rms_width:], power, power[:rms_width]))
    integral = np.concatenate(([0.0], np.cumsum(circular_power)))
    centers = positions + rms_width
    before = (integral[centers] - integral[centers - rms_width]) / rms_width
    after = (integral[centers + rms_width] - integral[centers]) / rms_width
    change_db = 10 * np.log10(np.maximum(after, 1e-30) / np.maximum(before, 1e-30))
    positions = positions[np.abs(change_db) <= track["boundary_rms_match_db"]]
    if not len(positions):
        raise ValueError("No steady-envelope boundary in configured search interval")
    score = np.max(np.abs(cycle[positions]), axis=1) + np.max(np.abs(cycle[positions - 1]), axis=1)
    score += .5 * np.max(np.abs(cycle[positions] - cycle[positions - 1]), axis=1)
    rotation = int(positions[np.argmin(score)])
    cycle = np.roll(cycle, -rotation, axis=0)
    exported = np.tile(cycle, (track["repeat_source_cycles"], 1))
    return exported, {"source_start_sample_at_48000": start, "source_end_sample_at_48000": end,
        "source_selected_seconds": len(x) / RATE, "crossfade_samples": overlap,
        "crossfade_seconds": overlap / RATE, "crossfade_curve": "equal-power cosine/sine",
        "unique_cycle_samples": len(cycle), "unique_cycle_seconds": len(cycle) / RATE,
        "source_cycle_repetitions": track["repeat_source_cycles"],
        "additional_source_variation": False,
        "boundary_rotation_samples": rotation, "boundary_rotation_seconds": rotation / RATE,
        "boundary_alignment": "Joint stereo near-zero, low-slope crossing with adjacent50ms RMS matched within0.5dB; circular shift only",
        "crossfade_location_each_cycle_samples": [len(cycle) - overlap - rotation, len(cycle) - rotation],
        "crossfade_sources_correlation": float(np.corrcoef(x[-overlap:].reshape(-1), x[:overlap].reshape(-1))[0, 1]),
        "seam_method": "Overlap original tail/head inside cycle; boundary follows consecutive source samples. Source-derived cycle repeated twice, not new generated material.",
        "transient_review": "Beat-free ambience requested; numerical seam checks do not establish absence of audible doubled water details. Human review pending."}


def encode_target(sf, path, x, track):
    low, high = 0.0, 1.0
    quality = track["vorbis_quality_start"]
    attempts = []
    for _ in range(9):
        sf.ogg(path, x, quality)
        bitrate = path.stat().st_size * 8 / (len(x) / RATE) / 1000
        attempts.append({"quality": quality, "container_average_kbps": bitrate})
        if track["vorbis_bitrate_min_kbps"] <= bitrate <= track["vorbis_bitrate_max_kbps"]:
            return quality, bitrate, attempts
        if bitrate < track["vorbis_bitrate_min_kbps"]:
            low = quality
        else:
            high = quality
        quality = (low + high) / 2
    raise ValueError("Cannot reach configured bitrate target using existing Vorbis encoder")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", type=Path, default=HERE / "loop-settings.json")
    parser.add_argument("--output-root", type=Path, default=ROOT)
    args = parser.parse_args()
    settings = json.loads(args.settings.read_text())
    output = args.output_root.resolve()
    sf = SoundFile(settings["sndfile_library"])
    report = {"schema_version": 1, "task": "RC-019", "revision": settings["revision"],
        "status": "ambience_exported_music_pending", "settings_path": "source-assets/audio/loop-settings.json",
        "renderer_path": "source-assets/audio/render_loop_audio.py", "settings_sha256": sha(args.settings),
        "renderer_sha256": sha(__file__), "decoder_sha256": sha(ROOT / "tools/decode_loop_audio.gd"),
        "python_version": platform.python_version(), "numpy_version": np.__version__,
        "encoder": sf.version, "encoder_library": settings["sndfile_library"],
        "encoder_library_sha256": sha(settings["sndfile_library"]),
        "source_fidelity": settings["source_fidelity"],
        "loudness_method": "ITU-R BS.1770-5 stereo K-weighting coefficients at48kHz, FFT-realized causal IIR padded2s,400ms blocks/100ms hop, -70LUFS absolute and -10LU relative gate; implementation estimate, not certified meter",
        "true_peak_method": "8x fractional reconstruction,96-tap Kaiser beta10, circular padding includes seam; estimate, not certified meter",
        "measurement_reference": "https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf",
        "pending_music": [t["cue_id"] for t in settings["tracks"] if not t["export_enabled"]], "tracks": [],
        "listening_review": "No headphone/speaker or agent perceptual review claimed. Six-cycle decoded-runtime audition provides five internal boundary joins for owner review."}
    for track in settings["tracks"]:
        if not track["export_enabled"]:
            continue
        print("Decoding " + track["cue_id"], flush=True)
        x, decoded, decoder = source_decode(ROOT, settings, track)
        x = resample(x, decoded["sample_rate"])
        x, edit = build_cycle(x, track)
        initial_lufs = integrated_lufs(x)["integrated_lufs"]
        wanted_gain = track["target_integrated_lufs"] - initial_lufs
        guard_gain = track["master_peak_guard_dbtp"] - db(true_peak(x))
        gain = min(wanted_gain, guard_gain)
        x *= 10 ** (gain / 20)
        master, runtime = output / track["source_path"], output / track["runtime_path"]
        write_wav(master, x, 24, track["dither_seed"])
        master_x, master_info = sf.read(master)
        print("Encoding Vorbis " + track["cue_id"], flush=True)
        quality, bitrate, attempts = encode_target(sf, runtime, master_x, track)
        runtime_x, runtime_info = sf.read(runtime)
        master_measure = measurement(master_x)
        runtime_measure = measurement(runtime_x)
        if runtime_info.samplerate != RATE or runtime_info.channels != 2 or runtime_info.frames != len(x):
            raise ValueError("Vorbis format/frame correspondence failed")
        if abs(runtime_measure["integrated_lufs"] - track["target_integrated_lufs"]) > track["integrated_lufs_tolerance"]:
            raise ValueError("Runtime loudness outside target tolerance")
        if runtime_measure["estimated_true_peak_dbtp"] > track["true_peak_ceiling_dbtp"]:
            raise ValueError("Runtime true peak outside ceiling")
        previews = output / "output/audio/rc-019"
        five = previews / "crypt-five-joins.wav"
        seam = previews / "crypt-seam-ten-seconds.wav"
        write_wav(five, runtime_x, 16, track["dither_seed"] + 16, repeats=6)
        write_wav(seam, np.concatenate((runtime_x[-5 * RATE:], runtime_x[:5 * RATE])), 16, track["dither_seed"] + 17)
        report["tracks"].append({"cue_id": track["cue_id"], "manifest_id": track["manifest_id"],
            "original_path": track["original_path"], "original_sha256": sha(ROOT / track["original_path"]),
            "source_path": track["source_path"], "source_sha256": sha(master),
            "runtime_path": track["runtime_path"], "runtime_sha256": sha(runtime),
            "runtime_decoded_float32_sha256": hashlib.sha256(runtime_x.astype("<f4").tobytes()).hexdigest(),
            "decoder_engine": decoder["engine"], "decoder_rate": decoded["sample_rate"],
            "decoded_original_sha256": decoded["pcm_sha256"], "edit": edit,
            "level_gain_db": gain, "peak_guard_limited_level": guard_gain < wanted_gain,
            "loop_start_sample": 0, "loop_end_sample_exclusive": len(x), "loop_sample_rate": RATE,
            "intended_bus": track["intended_bus"], "intended_gain_db": track["intended_gain_db"],
            "master": {**master_measure, "bit_depth": 24, "format": "PCM WAV"},
            "runtime": {**runtime_measure, "format": "Ogg Vorbis", "encoder_quality": quality,
                "container_average_kbps": bitrate, "bytes": runtime.stat().st_size, "encoding_attempts": attempts},
            "five_join_preview": "output/audio/rc-019/crypt-five-joins.wav",
            "five_join_preview_seconds": len(runtime_x) / RATE * 6,
            "five_join_preview_source": "Decoded exported Vorbis; six cycles with five internal joins, quantized16bit stereo48kHz",
            "seam_preview": "output/audio/rc-019/crypt-seam-ten-seconds.wav"})
        print(f"Exported {track['cue_id']}: {len(x)/RATE:.3f}s,{runtime_measure['integrated_lufs']:.3f}LUFS,{bitrate:.1f}kb/s", flush=True)
    report_path = output / "source-assets/audio/loop-generation-report.json"
    save_json(report_path, report)
    print("Report: " + str(report_path))


if __name__ == "__main__":
    main()
