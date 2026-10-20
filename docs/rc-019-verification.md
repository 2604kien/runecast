# RC-019 verification — ambience delivered, music pending

October 17, 2026. **RC-019 remains incomplete.** The crypt ambience is delivered through Runway in the established fantasy direction. The owner explicitly chose “Leave music pending” after Runway required a paid plan for music. Neither Home/exploration nor combat has an audio source or runtime export; their requests and deferral are retained in the [music record](../source-assets/audio/music/delivery.md).

## Delivery and measured levels

The [review page](../output/audio/rc-019/index.html), [source delivery](../source-assets/audio/ambience/crypt/delivery.md), [loop catalogue](audio-loop-catalogue.json) and [RC-020 handoff](audio-loop-integration.md) are the current entry points. The original 30-second MP3, exact prompt/task/options and rights review are retained. The 24-bit PCM master is a working derivative of MP3, not a lossless original recording.

One one-second head/tail overlap produces a 28.999917-second cycle. A circular shift of 38,974 samples (0.811958 seconds) chooses a stereo boundary with similar surrounding levels. Two repetitions yield the delivered duration without adding source variation or a fade to silence. The renderer records the source window, crossfade and all sample locations.

| Measure | Working master | Runtime |
| --- | --- | --- |
| Format | 48 kHz stereo, 24-bit PCM WAV | 48 kHz stereo, Ogg Vorbis |
| Duration / frames | 57.999833 s / 2,783,992 | Same |
| Loop interval | [0, 2,783,992), exclusive end | Full file; imported loop enabled, offset 0 |
| Size | 16,703,996 bytes | 819,769 bytes |
| Encoding rate | PCM | VBR quality 0.5125; 113.072 kb/s whole-container average |
| Estimated integrated loudness | −26.000 LUFS | −25.956 LUFS |
| Estimated true peak | −10.907 dBTP | −10.843 dBTP |
| Boundary sample delta | −64.256 dBFS | −60.684 dBFS |
| Adjacent 50 ms level difference | 0.366 dB | 0.344 dB |
| Nonfinite or clipped samples | 0 | 0 |

Both meet the ambience contract of 30–60 seconds, 96–128 kb/s runtime average, −26 LUFS ±3 and true peak at most −3 dBTP. The one delivered compressed bed is below the proposed 8 MiB total long-audio budget; the final combined budget awaits music. BS.1770-5-based stereo loudness and eight-times reconstructed true peak are implementation estimates, not certified-meter results. Independent measurements and methodology are recorded in the [audio validation report](../output/qa/rc-019/audio-loop-validation.json); the [render report](../source-assets/audio/loop-generation-report.json) holds exact hashes and tool versions.

## Validation performed

**437 focused independent checks pass, zero failures.** They cover decoded format/duration/levels, codec bitrate, discontinuity and short-window level/gap checks, loop metadata and hash agreement, retained originals, absence of deferred music, actual Godot loop evidence and preservation. Boundary alignment was improved after a short-window check failed; the validator thresholds were retained.

Pinned **Godot 4.7.2** imports an `AudioStreamOggVorbis` with looping enabled and offset zero. Its imported playback decoder advances through **five actual loop wraps**; capture windows remain finite and nonzero and meet the discontinuity check. A separate 0.7-second `AudioStreamPlayer` internal-bus capture produces nonzero output and stops successfully. [Godot evidence](../output/qa/rc-019/godot-playback.json). The Dummy audio driver mixes at 44.1 kHz for these checks; the supplied assets remain 48 kHz. This is internal desktop evidence, not sound emitted from physical headphones or speakers.

The [preservation report](../output/qa/rc-019/preservation-after.json) confirms **all 382 protected production and RC-018 files are unchanged**, against the retained before-snapshot. The existing Cast tone, gameplay, RC-017 timing/visuals and RC-018 library are preserved. No unrelated gameplay suites were rerun, no baseline was rewritten to force a pass, and no Git operations were performed.

The [handoff audit](../output/qa/rc-019/handoff-validation.json) passes **88 checks** covering delivery links, inventory/consumer reciprocity, current source/runtime/evidence hashes, export exclusions and the absence of deferred music files. The plan keeps both RC-019 and RC-020 unchecked.

The [preview audit](../output/qa/rc-019/preview-validation.json) passes **26 static/controller-mock checks** and confirms all **12 local references** exist. It covers source selection, five boundary start positions, Stop, repeat restoration and volume synchronization. Browser rendering and physical audio output are not established by those checks.

Reproduction uses a fresh original decode and separate output directory. The [reproducibility report](../source-assets/audio/loop-reproducibility.json) passes **8 of 8 checks**, recording identical master bytes and decoded runtime PCM, plus identical source/settings/renderer/loop points. Ogg container bytes differ because the encoder randomizes its stream serial; page comparison checks that only the serial and corresponding CRC fields differ. This is audio reproducibility, not a byte-identical Ogg claim.

## Rechecking and listening

The existing bundled Python 3.12.14/NumPy 2.3.5, pinned Godot and existing Blender libsndfile 1.2.2 DLL were used. No dependency was installed or shipped. After re-rendering or changing an import, refresh the import and Godot evidence before the Python validation:

```powershell
$env:APPDATA = Join-Path $PWD 'output/qa/rc-019/appdata'
$env:LOCALAPPDATA = Join-Path $PWD 'output/qa/rc-019/localappdata'
& '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import
& '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tools/loop_audio_audition.gd -- --verify
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/validate_loop_audio.py
```

Run the same audition script without `--headless` or `--verify` for its isolated Play/Stop interface on an actual audio device. The browser review also supplies six decoded-runtime cycles (347.999 seconds), providing five internal joins, and a ten-second boundary excerpt. Start at a comfortable volume and hear at least five joins on both headphones and ordinary speakers, including the imported runtime. Numerical checks do not establish inaudibility, repeated-use comfort or perceived balance; that acoustic review remains pending.

Both music tracks, their loop/transition evidence and the final mix remain outstanding. RC-020 owns production buses, persistent settings, contextual fades, player limits, scene/session cancellation and playback; RC-047 owns platform interruption/resume acceptance. RC-050 retains the distribution rights/credits audit. No production audio coordinator or physical-device acceptance is delivered here.
