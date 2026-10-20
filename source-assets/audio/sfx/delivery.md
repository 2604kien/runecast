# RC-018 sound-effect delivery - r003 Runway library

October 17, 2026. **16 stable manifest families / 21 runtime WAVs** now use Runway-generated material in the direction the owner approved. The five r002 source clips are retained and sixteen new sources complete the library. Quiet wood/cloth interface gestures, stone editing, paper techniques, flowing magic, glass shielding and distinct enemy materials replace r001's rejected percussion-like palette.

[Listen to the full library](../../../output/audio/rc-018/index.html), including individual cues at intended gains, five comparisons, sixteen normal/reduced action sequences and the indexed 19.274917-second reel. [Cue catalogue](../../../docs/audio-cue-catalogue.json) and [integration contract](../../../docs/audio-integration.md) retain the existing event/timing semantics.

## Files and editable sources

- [Original generation record](revisions/r003-runway-library/generation.json): all 21 original MP3s, exact prompts, task/artifact IDs, returned model/options metadata, dates, durations, byte sizes and hashes. Five entries identify approved r002 reuse; sixteen identify new generation. Model seeds were not returned.
- [Editing settings](runway-settings.json): source windows, edge detection, material filters, fade lengths, role levels, local dither seeds and exact export paths/durations.
- [Renderer](render_runway_sfx.py) and [offline Godot decoder](../../../tools/decode_sfx_sources.gd): reproducible processing from the retained originals with no new dependency.
- [Render report](runway-generation-report.json): actual edits, signal measurements, source/master/runtime hashes and tool versions. [Independent encoded-file audit](../../../output/qa/rc-018/audio-validation.json) checks the exported PCM separately.
- [Reproduction evidence](runway-generation-reproducibility.json): a fresh Godot decode and second render produced 44 byte-identical outputs: 21 masters, 21 runtimes, shared enemy stem and render report.
- [Provenance](provenance.json) and [source notes](revisions/r003-runway-library/README.md): reviewed Runway terms, fidelity limits and listening status.

Every original MP3 remains unchanged. Pinned Godot decodes offline to stereo float32 at the observed 44,100 Hz mix rate; the renderer checks finite output/completion, averages channels with phase-cancellation checks, then uses 96-tap Kaiser-windowed sinc resampling to 48,000 Hz. Decoded intermediates remain outside shipped assets.

**Working masters are 48 kHz, 24-bit mono PCM WAV; runtime files are 48 kHz, 16-bit mono PCM WAV.** Both are edited derivatives of MP3 originals. Their bit depth does not imply a lossless original recording or recover information discarded by MP3 encoding. The full original head/tail remains available for future edits.

The 21 runtime files total **9.474917 seconds / 910,516 bytes**; masters total **1,365,312 bytes**. Durations span **0.175042–1.479917 seconds**, all within their existing cue-specific ranges. Exact counts and hashes appear in each family's delivery note and the reports.

## Editing and level choices

Generated gestures keep their native time and pitch. Edge trimming removes padding; five overlength gestures (confirm, rotate, remove, rejection and cleanup) use explicit bounded onset windows with tapered endings. Every selected window and removed duration is recorded. Small attack/release fades, weighted DC correction and TPDF quantization avoid hard endpoints. Material-specific filtering leaves the sounds' distinct textures intact.

The five enemy files share one actual quiet 100 ms air/cloth stem derived from the approved spectral source, with their distinct generated spectral/flame/stone/chain/bell textures. This replaces the old synthetic common stem. One actor selects one completed file; never layer all five. Four later actors, reward and guardian phase remain future-only. The historical `sfx_undo` ID supplies Remove/refund, not an Undo control.

Role-specific RMS starting points and individual peak caps preserve headroom; no identical-peak normalization, compressor or integrated-LUFS claim is used. Intended playback gains remain separate. The independent encoded meter finds estimated true peaks **-16.963 to -6.174 dBTP**, with zero clipped samples, leading silence at most 1.75 ms and trailing material below -60 dBFS at most 44.355 ms. The 8x/96-tap-per-phase windowed-sinc true-peak estimate is not a certified BS.1770 meter. These are technical level checks; perceived balance still requires listening in context.

## Reproduce

From the project root, using the existing bundled Python and pinned Godot:

```powershell
& 'C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' source-assets/audio/sfx/render_runway_sfx.py
& 'C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/validate_audio_library.py
```

The renderer uses the saved sources; it makes no service call and consumes no generation credits. Add `--force-decode` to refresh the decoded cache. `--output-root` supports an isolated export for comparison. Then follow the [Godot import/playback and preview instructions](../../../output/audio/rc-018/README.md). Changed assets require fresh import/playback evidence. The old `generate_sfx.py` and `settings.json` describe r001 and must not be used to rebuild the active library.

## Acceptance and boundaries

The owner approved the five r002 examples and requested this full revision. All 21 runtime files pass independent technical checks and pinned Godot import/playback; [verification](../../../docs/rc-018-verification.md) distinguishes those checks from listening. No agent headphone, speaker or physical-device review is claimed. Full-library owner listening, perceived balance and the eventual music/SFX mix remain open.

Runway originals, prompts and reviewed terms are documented; no copyright ownership or final clearance is invented. RC-050 retains the distribution audit. The rejected [r001 archive](revisions/r001-procedural/README.md) and [approved direction comparison](../../../output/audio/rc-018/r002/index.html) remain available.

The main-scene Cast tone, RC-017 timing/visuals and controller behavior remain unchanged. RC-020 owns buses/settings, accepted-result and presentation-clock hooks, cancellation/deduplication, bounded voice policy and production playback. RC-019 remains ready for two music loops and one crypt ambience bed; no music or ambience was added here.


## October 18, 2026 — Production consumer update

RC-020 now consumes this unchanged delivery through one scene-owned coordinator, shipped catalogue metadata and available-resource caching. Current SFX and crypt Combat ambience, independent persisted controls and cancellation/lifecycle ownership are implemented. The generated Cast tone is removed; current actor/art/presentation pacing is preserved. Both music tracks and final loop/full-mix listening acceptance remain pending; RC-019 and the original full RC-020 task remain incomplete. [Production verification](../../../docs/rc-020-verification.md) records actual tests, measured playback and listening limits.
