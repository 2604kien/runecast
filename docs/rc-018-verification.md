# RC-018 verification and handoff - r003 Runway library

October 17, 2026. **RC-018 is complete for the revised sound assets, editable processing, cue contract, previews and scoped technical validation.** The owner approved the five r002 Runway examples and requested the full library in that direction. Five exact originals are reused and sixteen additional generated sources complete the replacement. Final full-library listening and perceived mix acceptance remain open.

[Full audition](../output/audio/rc-018/index.html) · [Sources and reproduction](../source-assets/audio/sfx/delivery.md) · [Cue catalogue](audio-cue-catalogue.json) · [Integration contract](audio-integration.md)

## Delivered revision

Exactly **16 manifest families / 21 runtime WAVs** retain all existing IDs, basenames and destinations. Each has a matching 48 kHz mono 24-bit PCM working master; runtime is 48 kHz mono 16-bit PCM. The original provider MP3s and exact generation records are retained. Working masters are edited MP3 derivatives, not lossless original recordings.

The palette uses quiet wood/cloth UI, stone editing, parchment movement, flowing magic, rounded shielding and distinct spectral/flame/stone/chain/bell enemy material. The enemies share one quiet 100 ms air/cloth stem derived from the approved spectral source. Choose one actor variant. Four later actors, reward and guardian phase remain future-only; `sfx_undo` still supplies Remove/refund without restoring Undo.

Durations span **0.175042–1.479917 seconds**, total **9.474917 seconds**. Runtime files total **910,516 bytes**, masters **1,365,312 bytes**. All cues fit their unchanged duration ranges. Source gestures retain time and pitch; edge trims, five bounded onset selections, material filters, fades, DC correction and export levels are recorded per cue.

## Executed evidence

| Check | Result and scope |
| --- | --- |
| Independent encoded-file and cue audit | **864 checks, zero failures**: exact IDs/paths/counts, formats, duration, silence/tail/endpoints, DC/clipping, estimated true peaks, source/runtime quantization, gains, current/future mappings, hooks and uncompressed import recipes. [Report](../output/qa/rc-018/audio-validation.json), [validator](../tools/validate_audio_library.py). |
| Reproduction | Fresh pinned Godot MP3 decoding and a second render yield **44/44 byte-identical outputs**: 21 masters, 21 runtime files, common enemy stem and render report. [Evidence](../source-assets/audio/sfx/runway-generation-reproducibility.json). |
| Pinned Godot import/playback | **21 cues, zero failures**. Imported PCM equals the exact WAV payload; playback advances, produces finite nonzero unclipped output and ends naturally at intended gains. [Report](../output/audio/rc-018/godot-playback.json), [mix capture](../output/audio/rc-018/godot-mix-capture.wav), [import log](../output/audio/rc-018/import.log), [playback log](../output/audio/rc-018/playback.log). |
| Updated listening previews | 21 individual cues, five comparisons, sixteen actual-event normal/reduced sequences and a **19.274917-second indexed reel**. Highest review-mix sample peak **-8.1871 dBFS**. JavaScript syntax and all 53 local references pass. [Index](../output/audio/rc-018/preview-index.json), [reel timecodes](../output/audio/rc-018/listening-reel-index.md). |
| Independent preview contract | **827 checks, zero failures**: current waveform hashes, captured event boundaries/contact/results, actual supplied UIDs, one grouped arrival/cleanup, Pass/lethal/future suppression, reduced voice budgets/crossfades and 22 review WAVs. [Report](../output/qa/rc-018/cue-contract-review.json), [audit](../output/qa/rc-018/validate_preview_contract.py). |
| Final cross-artifact handoff | Source/decoder/export/audit/playback/preview hashes, all original MP3s, current source pointers, reciprocal manifest/consumer links, delivery links and export exclusions. [Final report](../output/qa/rc-018/handoff-validation.json). |
| Production preservation | **164 protected production files unchanged**, including scenes, controller/presentation/gameplay scripts, existing art and project/export settings. [Before snapshot](../output/qa/rc-018/preservation-before.json), [current audit](../output/qa/rc-018/preservation-after.json). |

Python **3.12.14**, NumPy **2.3.5** and Godot **4.7.2.stable.official.ed1daf0bf** were used. The decoder mixes MP3s offline to float32 at the actual **44,100 Hz** engine mix rate, without relying on elapsed recording time; a 96-tap Kaiser-sinc resampler produces 48,000 Hz output. The separate runtime playback harness uses the **Dummy driver** and an isolated capture bus at 44,100 Hz. This proves internal decode/import/playback, not output through physical headphones or speakers.

Encoded estimated true peaks range **-16.963 to -6.174 dBTP**, below the provisional -3 dBTP ceiling. The independent estimator uses 8x fractional reconstruction, 96 taps per phase and Kaiser beta 10; it is not a certified BS.1770 meter. No clipped samples occur. Maximum absolute DC is 0.000000371; endpoints are zero, final 1 ms peak is at most -66.227 dBFS, leading silence at most 1.75 ms and trailing samples below -60 dBFS at most 44.355 ms. Whole-file and maximum 50 ms RMS are retained; no integrated-LUFS or perceived-loudness equivalence is claimed.

Existing uncompressed import recipes preserve PCM without automatic normalization, trim, loops or resampling. Godot import exits successfully. The existing unavailable Android build-tools diagnostic remains in the log and is unrelated to these audio files. No dependency or SDK installation was performed. Browser automation cannot open local file URLs in this environment, so no screenshot or browser acoustic review is claimed; local native audio controls and the separate Godot player are provided.

## Cue timing and production handoff

The unchanged actual controller/presenter traces still define the previews; their production-source hashes are checked. No unrelated gameplay suite was rerun. Cast illumination remains 0.90 s, enemy hit/attack 1.50 s each, technique 1.00 s, actual card arrival 0.40 s, cleanup 0.18 s per cell/card, reduced individual effects at most 0.06 s. Actor contact is driven by its normalized 0.28 marker. Audio-file duration does not alter those phases.

`event_presented` remains **after visual completion and staged commit**, not phase start/contact. RC-020 must add presentation-clock phase/contact hooks and accepted UI/edit boundaries, with session/action/event identity, deduplication, cancellation and bounded voice ownership. Normal sequences use one first-arrival cue and one cleanup cue; Pass invents no Cast/gain/enemy injury; zero applied damage is silent; lethal outcomes schedule no retaliation. Reduced mode retains one Cast and one real retaliation outcome, plus any actual result, with 10 ms replacement release and optional decorative suppression. [Detailed integration contract](audio-integration.md).

The main-scene Cast tone and all RC-017 gameplay/visual behavior remain unchanged. RC-020 owns production playback, buses/settings, final mixing and tone replacement. RC-019 is ready for its two music loops and one crypt ambience bed; RC-042 binds future content.

## Acceptance, provenance and retained history

The user approved the r002 direction. No agent headphone/speaker review or final full-library acceptance is inferred from that approval or from automated checks. Repeated-use comfort, perceived level balance, final music/SFX mix and physical-device acceptance remain open.

[Source provenance](../source-assets/audio/sfx/provenance.json) and [generation records](../source-assets/audio/sfx/revisions/r003-runway-library/generation.json) identify Runway, exact returned task/model/options metadata, original MP3 hashes and the public terms reviewed October 17. No generation seed, lossless source, copyright ownership or licence transfer is invented. Local dither seeds are explicitly separate from absent model seeds. RC-050 retains final distribution review.

The rejected r001 sound direction and its original evidence are preserved in the [source archive](../source-assets/audio/sfx/revisions/r001-procedural/README.md) and [QA archive](../output/qa/rc-018/r001/). The [r002 comparison](../output/audio/rc-018/r002/index.html) uses frozen r001 WAVs beside the unchanged approved MP3s. Current runtime replacement does not rewrite the earlier comparison. No Git operation was performed in this revision; the owner handles Git.

For reproduction, use the active Runway renderer in the [source delivery](../source-assets/audio/sfx/delivery.md), then the [import/playback/preview commands](../output/audio/rc-018/README.md). The old r001 generator is historical and must not rebuild the active library.
