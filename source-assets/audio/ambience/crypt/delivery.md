# RC-019 — crypt ambience delivery

October 17, 2026. Revision `r001-runway-crypt` delivers one quiet fantasy crypt ambience bed generated through Runway, with cool passage air, diffuse stone-room resonance and sparse distant water detail. The owner chose to leave both music tracks pending after Runway required a paid plan. RC-019 remains incomplete; no substitute music files were created.

## Files and use

- [Runtime Ogg Vorbis](../../../../assets/audio/ambience/crypt.ogg): stereo, 48 kHz, approximately 58 seconds. Loop over the entire stream, beginning at zero; the exact exclusive end sample and current measurements are in the [loop catalogue](../../../../docs/audio-loop-catalogue.json).
- [Working master](crypt.wav): stereo, 48 kHz, 24-bit PCM. This is an edited derivative of the provider's lossy MP3, not a lossless original recording or restored fidelity.
- [Original MP3](originals/crypt.mp3), [exact generation request/result](generation.json) and [provenance](provenance.json) retain the source, prompt, task and returned options. A seed was neither supplied nor returned.
- [Review player](../../../../output/audio/rc-019/index.html) offers the runtime, master, original and six-cycle decoded-runtime review with five internal joins. A ten-second boundary excerpt is also available.
- [Technical evidence](../../../../docs/rc-019-verification.md) and [RC-020 handoff](../../../../docs/audio-loop-integration.md) describe the completed checks and remaining acceptance.

The crypt bed is prepared for Combat and future crypt Map/service contexts. Its planned Ambience bus belongs under Music so the Music setting also controls the bed. RC-020 owns live playback, contextual gain, independent fading, bounded players, scene/session cancellation and persisted settings. This asset task does not install a production audio coordinator.

## Editable processing

The [settings](../../loop-settings.json), [renderer](../../render_loop_audio.py), [decoder](../../../../tools/decode_loop_audio.gd) and [generation report](../../loop-generation-report.json) record the full transformation. The source is decoded through pinned Godot, resampled to 48 kHz, high-pass filtered at 25 Hz and DC corrected. A one-second equal-power head/tail overlap produces an approximately 29-second circular cycle. The cycle is rotated to a suitable stereo boundary, then repeated twice to meet the specified 30–60-second runtime duration. Repetition adds no new source variation. No silence fade is inserted at the runtime join.

Loudness adjustment targets −26 LUFS, with deterministic dither for the 24-bit working master. The existing libsndfile encoder exports Vorbis using a selected VBR quality setting within the specified 96–128 kb/s average range. The report gives both encoder quality and measured whole-container average bitrate; this is not fixed-rate encoding. Runtime audio is decoded again for level and seam checks. Exact source windows, crossfade/rotation samples, hashes, loop points and tool versions remain machine-readable in the report.

From the repository root, the existing bundled Python can rebuild the delivery:

```powershell
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' source-assets/audio/render_loop_audio.py
```

The default writes the canonical master, runtime, previews and report. For an isolated comparison, pass `--output-root` with a separate directory under `output/qa/rc-019/`. The settings name the pinned Godot binary and existing Blender libsndfile DLL. Those existing tools were used without installing or shipping a new dependency. A second fresh decode/render and the [reproducibility record](../../loop-reproducibility.json) distinguish identical audio from randomized Ogg container serials.

## Review and rights

Numerical and engine checks are technical evidence only. Headphone and ordinary-speaker listening across at least five joins, including the runtime codec, remain pending. The review page supplies six cycles so five boundaries can be heard without manual restart; the original MP3 is a source comparison, not the finished loop. Final production balance and physical-device acceptance also remain separate.

The [provenance record](provenance.json) retains the reviewed Runway terms and commercial-use guidance with their limits. This delivery makes no public-domain, exclusive-ownership or blanket-clearance claim. RC-050 retains the distribution rights/credits audit. The [music delivery record](../../music/delivery.md) documents the owner's deferral and the prepared requests.


## October 18, 2026 — Production consumer update

RC-020 now consumes this unchanged delivery through one scene-owned coordinator, shipped catalogue metadata and available-resource caching. Current SFX and crypt Combat ambience, independent persisted controls and cancellation/lifecycle ownership are implemented. The generated Cast tone is removed; current actor/art/presentation pacing is preserved. Both music tracks and final loop/full-mix listening acceptance remain pending; RC-019 and the original full RC-020 task remain incomplete. [Production verification](../../../../docs/rc-020-verification.md) records actual tests, measured playback and listening limits.
