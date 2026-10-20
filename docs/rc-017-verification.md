# RC-017 verification — October 16–17, 2026

## October 17 owner follow-up — Sequential card arrival fades

Each actual `card_drawn` or `card_created` event now fades its card in over **0.40 s**, completing before the next card appears. Existing cards remain opaque. The incoming card is a disabled, nonfocusable UI preview of that event's UID; authoritative state, staged hand/pile counts and exactly-once event commits remain unchanged. Preview opacity is initialized before parenting and restored at current progress during any hand rebuild. Completion/cancellation removes the preview. The 146 px hand lane remains fixed; deferred horizontal reveal exposes incoming cards at narrow widths without scrolling the page vertically. Reduced motion uses an individual 0.06 s opacity fade. See [current usage](combat-animation.md).

Pinned Godot 4.7.2 with workspace-local application-data paths passes:

| Coverage | Result |
| --- | --- |
| Focused actual-scene arrival suite | **89 checks, zero failures**. Included in the UI total below. [Log](../output/qa/rc-017/card-arrival-2026-10-17/focused.log). |
| `tools/godot.ps1 -Action test -LogDirectory output/qa/rc-017/card-arrival-2026-10-17/core` | **1,796 checks, zero failures**. [Log](../output/qa/rc-017/card-arrival-2026-10-17/core/test.log). |
| `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/card-arrival-2026-10-17/ui` | **1,107 checks, zero failures**. [Log](../output/qa/rc-017/card-arrival-2026-10-17/ui/smoke.log). Only expected negative-content fixture diagnostics. |
| Pinned Godot `--path . --log-file output/qa/card-draw-fade-2026-10-17/capture.log --script res://output/qa/card-draw-fade-2026-10-17/capture.gd` | **556 checks, zero failures**, 245 frames across five native sequences. [Results](../output/qa/card-draw-fade-2026-10-17/motion/results.json), [log](../output/qa/card-draw-fade-2026-10-17/capture.log). |

Actual-scene regressions cover Focus draws, a new turn from an empty hand, generated cards, reduced motion, refresh without flashing, staged values/RNG, cancellation, Restart and Exact replay. Native observations at 720×1600, 450×1000 and 360×640 record exactly one preview per arrival, increasing opacity, no missing UID, fully visible incoming cards, fixed 146 px hand/scroll heights and constant vertical scroll. Reviewed early/mid/late frames show no added circles or scale changes. [Per-card observations](../output/qa/card-draw-fade-2026-10-17/motion/draw-observations.json), [450 Pass motion](../output/qa/card-draw-fade-2026-10-17/motion/pass-bottom-450x1000/motion.gif), [360 Pass motion](../output/qa/card-draw-fade-2026-10-17/motion/pass-bottom-360x640/motion.gif), [Focus motion](../output/qa/card-draw-fade-2026-10-17/motion/focus-bottom-720x1600/motion.gif).

Captured nominal totals are Pass **3.24 s** (three arrivals), Focus **1.80 s** (two arrivals), Conjure **1.40 s** (one created card), and reduced Pass **0.42 s**. Totals depend on supplied events. `tools/pack_combat_animation.py` packages the GIFs and [frame/media hashes](../output/qa/card-draw-fade-2026-10-17/motion/media.json); native arrival stills are retained. Earlier 0.24 s draw/creation timings below are historical. No gameplay, artwork or Git operation accompanied this follow-up.

## October 17 owner follow-up — Longer enemy actions and technique animation

Normal enemy hit and attack each last **1.50 s**. The attack phase contains 0.42 s anticipation, 0.66 s contact pose and 0.42 s recovery. Playing Focus or Conjure animates the actual supplied card UID for **1.00 s**: brighten, shrink inward by up to 12%, then fade. Its displayed payment/discard commits after that phase, followed by each actual draw/creation event. Temporary feedback circles remain removed and all effects remain sequential. Reduced motion retains its 0.06 s effect cap and stationary card tint/opacity.

The overlay resolves the card's current Control on each sample because normal UI refreshes rebuild the hand. Weak tracking and restoration of original tint, scale and pivot cover phase completion, cancellation, Restart and refresh rebinding. Position/size remain owned by the hand container. Gameplay, RNG and retained actor artwork are unchanged. Earlier timings and captures below remain historical.

Using the workspace-local application-data environment in Reproduction, pinned Godot 4.7.2 passes:

| Command / coverage | Result |
| --- | --- |
| `tools/godot.ps1 -Action test -LogDirectory output/qa/rc-017/actor-technique-pacing-2026-10-17/core` | **1,796 checks, zero failures**. [Log](../output/qa/rc-017/actor-technique-pacing-2026-10-17/core/test.log). |
| `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/actor-technique-pacing-2026-10-17/ui` | **1,018 checks, zero failures**. [Log](../output/qa/rc-017/actor-technique-pacing-2026-10-17/ui/smoke.log). Only deliberate missing/invalid-content fixture diagnostics appear. |
| Pinned Godot `--path . --log-file output/qa/rc-017/actor-technique-pacing-2026-10-17/motion.log --script res://output/qa/rc-017/actor-technique-pacing-2026-10-17/capture.gd` | **535 checks, zero failures**, 236 frames across five native scenes. [Results](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion/results.json), [log](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion.log). |

New actual-scene regressions observe only the played UID changing, staged payment/removal, reduced-motion stationary transforms, refresh rebinding, completion/cancel/restart restoration and inert late advancement. Core coverage asserts the 1.5 s minimum and exact sequential phase boundaries. Existing board-reselection regressions remain in the passing UI suite.

| Captured action | Nominal duration |
| --- | --- |
| Damage Cast, 450×1000 | **5.70 s** |
| Conjure, 450×1000 and 360×640 | **1.24 s** (1.00 s technique + 0.24 s creation) |
| Focus, 720×1600 | **1.48 s** (1.00 s technique + two 0.24 s draws) |
| Reduced Conjure, 360×640 | **0.12 s** |

These totals reflect the captured supplied events; other hands/circuits can take different times. Native early/mid/late stills show the played card stays inside its hand area while other cards retain their appearance. Reviewed actor frames retain the approved paintings and outcome text without temporary rings. [Narrow Conjure motion](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion/conjure-bottom-360x640/motion.gif), [Focus motion](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion/focus-bottom-720x1600/motion.gif), [enemy action motion](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion/cast-top-450x1000/motion.gif), [media/frame hashes](../output/qa/rc-017/actor-technique-pacing-2026-10-17/motion/media.json). Packaging uses `tools/pack_combat_animation.py`; native technique stills are retained separately. These are deterministic desktop captures, not physical-device performance measurements. No Git operations accompanied this follow-up.

## October 17 owner follow-up — Remove feedback circles

Removed all temporary circular feedback from cards, Draw/Discard piles, health/shield stats, actor hit/attack attachments and terminal/encounter-transition effects. `combat_feedback.gd` now draws outcome text and drives the existing board-slot illumination. The unused ring-width setting and obsolete card-pulse probe test/helper were removed. Begin/End artwork, slot lighting, actor poses, sequential timings and authoritative gameplay are unchanged. Ring-bearing captures in earlier sections are historical.

Pinned `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/no-feedback-circles/ui` with the workspace-local application-data environment passes **947 UI checks, zero failures**. [Log](../output/qa/rc-017/no-feedback-circles/ui/smoke.log). The total is three lower because assertions for the removed hand-card pulse were retired; timing, phase-boundary, input, cancellation, reduced-motion and lifecycle coverage remains. Only deliberate missing/invalid-content fixture diagnostics appear. Read-only review found no other production transient-circle renderer; existing status badges are already suppressed in production.

Focused actual-scene capture reuses `tools/capture_combat_animation.gd` through the [output-local wrapper](../output/qa/rc-017/no-feedback-circles/capture.gd): pinned Godot `--path . --log-file output/qa/rc-017/no-feedback-circles/motion.log --script res://output/qa/rc-017/no-feedback-circles/capture.gd`. It passes **613 checks, zero failures**, covering 287 frames across Shield at 450×1000, bottom-scrolled Cast at 450×1000, and board-scrolled Cast at 360×640. Reviewed frames show no temporary circles on the enemy, stats, cards or piles; labels and slot illumination remain. Measured durations remain Shield 4.20 s and damage Cast 3.85 s. [Results](../output/qa/rc-017/no-feedback-circles/motion/results.json), [engine log](../output/qa/rc-017/no-feedback-circles/motion.log), [cards/piles motion](../output/qa/rc-017/no-feedback-circles/motion/cast-bottom-450x1000/motion.gif), [shield/retaliation still](../output/qa/rc-017/no-feedback-circles/motion/shield-top-450x1000/key-retaliation.png), [narrow board motion](../output/qa/rc-017/no-feedback-circles/motion/cast-board-360x640/motion.gif). Packaging uses the existing `tools/pack_combat_animation.py`; the three GIFs total 3,739,708 bytes. No Git operations accompanied this follow-up.

## Owner follow-up — Slower sequential playback

The owner reported that the animation was too fast and requested every animation run in sequence. Production now gives traversal 0.90 s, hit 0.40 s, positive shield 0.35 s, retaliation 0.75 s, each cleared slot/hand card 0.18 s, each draw/create/reshuffle 0.24 s, technique 0.35 s and terminal feedback 0.75 s. Cleanup and draws no longer divide a tiny shared budget. Hand cleanup pulses one supplied card at a time, then commits its original event once. Empty hand cleanup adds no delay. Every transient clears before its event commits or the next effect starts; hit/attack restore neutral with idle stopped. Automatic frame hitches cannot skip several effects because clock advancement is capped at 1/30 s per frame. These changes supersede the original provisional 1.2 s turn target and the timings in earlier evidence below.

The turquoise slot illumination remains: detached active slots light, hold, then fade before hit feedback. Begin/End retain their existing rendering. Native fully lit stills are sampled near 78% Cast progress; the end of Cast now correctly shows the fade-out. No gameplay, RNG, retained artwork or audio changes accompany this follow-up.

| Action in the retained fixture | Previous duration | Current nominal duration |
| --- | --- | --- |
| Damage Cast | 0.98 s | **3.85 s** |
| Shield Cast | 1.08 s | **4.20 s** |
| Pass | 0.54 s | **2.01 s** |
| Lethal victory | 1.01 s | **3.13 s** |
| Player defeat | 0.87 s | **2.04 s** |
| Reduced-motion damage Cast | 0.42 s | **0.72 s** |
| Conjure | 0.24 s | **0.59 s** |

Totals sum the supplied event intervals, so other circuits/hands have different durations. Reduced motion retains brief 0.06 s colour/opacity effects per slot/card. Wall-clock completion may extend under frame stalls; these are deterministic schedule durations, not physical-device performance measurements.

Using the workspace-local application-data environment below, the final checks pass:

| Command / coverage | Result |
| --- | --- |
| `tools/godot.ps1 -Action test -LogDirectory output/qa/rc-017/sequential-pacing/core` | **1,795 checks, zero failures**. [Log](../output/qa/rc-017/sequential-pacing/core/test.log). |
| `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/sequential-pacing/ui` | **950 checks, zero failures**. [Log](../output/qa/rc-017/sequential-pacing/ui/smoke.log). Deliberate missing/invalid-content fixtures remain expected diagnostics. |
| Pinned Godot `--path . --log-file output/qa/rc-017/sequential-pacing/final/motion.log --script res://tools/capture_combat_animation.gd -- --capture-directory=res://output/qa/rc-017/sequential-pacing/final/motion` | **1,882 checks, zero failures**, 866 frames across 12 actual-scene sequences at 720×1600, 450×1000 and 360×640. [Results](../output/qa/rc-017/sequential-pacing/final/motion/results.json), [log](../output/qa/rc-017/sequential-pacing/final/motion.log). |

Regressions hold each phase just before its boundary, check full per-card/per-slot duration and ordered commit timestamps in normal/reduced motion, verify one actual hand-card pulse per slice, and require cleared cell lights/overlay and restored actor before the next event. A five-second automatic-frame hitch stays in Cast without committing later events. Existing input/cancellation/replay/teardown, ownership and RNG checks pass. Capture limits now derive from scheduled duration rather than a fixed five-second ceiling. The intermediate capture in `sequential-pacing/motion` predates the individual hand-card slices; only `sequential-pacing/final/motion` is final evidence.

Current motion: [450 damage Cast](../output/qa/rc-017/sequential-pacing/final/motion/cast-top-450x1000/motion.gif), [360 scrolled board](../output/qa/rc-017/sequential-pacing/final/motion/cast-board-360x640/motion.gif), [Pass](../output/qa/rc-017/sequential-pacing/final/motion/pass-top-450x1000/motion.gif), [reduced motion](../output/qa/rc-017/sequential-pacing/final/motion/cast-board-450x1000-reduced/motion.gif). Key stills: [720 fully lit circuit](../output/qa/rc-017/sequential-pacing/final/motion/cast-top-720x1600/key-cast-lit.png), [450 sequence sheet](../output/qa/rc-017/sequential-pacing/final/motion/cast-top-450x1000/contact.png). Packaging uses `tools/pack_combat_animation.py --directory output/qa/rc-017/sequential-pacing/final/motion` and retains native key stills plus [media/frame hashes](../output/qa/rc-017/sequential-pacing/final/motion/media.json). Observed resource maxima remain zero emitters/particles, 385 scene nodes, 524 draw calls and 49,525,995 engine-reported texture bytes in the multi-viewport harness.

## Owner follow-up — Cast slot illumination

The later owner request replaces board circles with illuminated valid slots in the connected Begin/End palette. `board_cell.gd` now renders that light beneath its symbols and wires, blending the amber rune face to the exact endpoint turquoise. `combat_feedback.gd` drives only detached active non-endpoint slots and removes added traversal spokes and cleanup circles. Cleanup uses fading slot illumination, with violet retained for temporary expiry. Existing Begin/End rendering remains unchanged, including when next-turn endpoints occupy a previous cleanup cell.

The pinned UI smoke command `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/slot-light/ui` passes **945 checks, zero failures** with the workspace-local application-data environment described below. [Log](../output/qa/rc-017/slot-light/ui/smoke.log). The focused actual-scene capture `Godot_v4.7.2-stable_win64_console.exe --path . --script res://output/qa/rc-017/slot-light/capture.gd` passes **12 grouped checks across four cases** (native 720×1600 and scrolled 360×640, normal and reduced motion). It verifies byte-identical Begin/End interiors before/mid/late Cast, only active non-endpoint slots illuminated, fixed authoritative outcomes, and restored light after completion/Restart cancellation. [Results](../output/qa/rc-017/slot-light/results.json), [720 all-lit](../output/qa/rc-017/slot-light/720x1600-normal/all-lit.png), [native 360 all-lit](../output/qa/rc-017/slot-light/360x640-normal/all-lit.png).

These latest captures supersede the initial RC-017 board-circle appearance below. Gameplay, event timings, non-board effects and source artwork remain unchanged. No Git operations were performed for this follow-up.

## Initial RC-017 delivery evidence

The runtime capture harness loads the ordinary `scenes/main.tscn` inside native 720×1600, 450×1000 and 360×640 SubViewports. It constructs a legal circuit using existing production UI controls and advances the actual production adapter by 1/24 second between rendered frames. It does not use a separate animation demo, sleep to prove completion, or animate a reconstructed post-cleanup path. The seeded opening contains Shield, Conjure and Focus, so the damage sequence first plays the actual Conjure and builds with its generated Spark.

The per-frame report records presentation phase/progress, visible health/energy/turn/hand, actor pose, emitted events and authoritative-state invariance. Top and board framing are separate repetitions of the same seeded action. Native 360 captures also scroll to the bottom to expose hand, forecast and Cast. Shield uses the actual drawn Shield UID moved to the front of the QA hand; terminal cases set current target HP to one before taking the action. These explicit fixtures do not change shipped data. The sound toggle is disabled only by the capture harness to avoid repeated capture audio; the reduced-motion setting does not mute it.

## Reproduction

Use the repository-pinned Godot `4.7.2.stable.official.ed1daf0bf`. The following process-local environment variables keep test-only `user://` writes inside this workspace; they do not change the player's real settings:

```powershell
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-017\user-data'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-017\user-local'
New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force | Out-Null
& .\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-017/final/core
& .\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/final/ui
& .\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --log-file output/qa/rc-017/final/motion.log --script res://tools/capture_combat_animation.gd -- --capture-directory=res://output/qa/rc-017/final/motion
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/pack_combat_animation.py --directory output/qa/rc-017/final/motion
```

`pack_combat_animation.py` produces compact looping GIFs, native key stills, contact sheets and a media/hash receipt. By default it removes only its own numbered intermediate PNG frames after recording their hashes; use `--keep-frames` to retain them. It does not edit source or runtime artwork.

## Executed baseline

| Command | Observed result |
| --- | --- |
| `tools/godot.ps1 -Action test -LogDirectory output/qa/rc-017/baseline/core` | **1,453 checks, zero failures**. [Log](../output/qa/rc-017/baseline/core/test.log). |
| `tools/godot.ps1 -Action smoke -LogDirectory output/qa/rc-017/baseline/ui-local` with the environment above | **601 checks, zero failures**. [Log](../output/qa/rc-017/baseline/ui-local/smoke.log). |

The first restricted smoke run used the host `user://` and could not write settings or its deliberately invalid fixture: 595 checks, one sound-persistence failure and a null-file script error. The unchanged suite passed after redirecting the process-local application-data directory; the [initial log](../output/qa/rc-017/baseline/ui/smoke.log) is retained. Deliberately missing/invalid fixture diagnostics in the passing run are expected test coverage.

## Final runtime evidence

The final ordinary-scene motion capture passes **642 checks, zero failures**, with **246 deterministic frames across 12 sequences**. [Results](../output/qa/rc-017/final/motion/results.json), [clean engine log](../output/qa/rc-017/final/motion.log), [media and frame hashes](../output/qa/rc-017/final/motion/media.json), [visual review](../output/qa/rc-017/final/motion/visual-review.json), [captured code hashes](../output/qa/rc-017/final/motion/code-hashes.json). The GIFs total 12,681,613 bytes; each uses one shared palette to avoid palette flicker. Native key stills remain unchanged.

| Executed suite | Final result |
| --- | --- |
| Core/model/controller and deterministic presentation | **1,758 checks, zero failures**. [Log](../output/qa/rc-017/final/core/test.log). |
| UI, interaction, scene lifecycle and actor | **945 checks, zero failures**, including 325 actor checks. [Log](../output/qa/rc-017/final/ui/smoke.log). |
| Existing actual-scene art/layout regression | **2,596 checks, zero failures**. [Results](../output/qa/rc-017/art-regression/results.json). |
| Current resource/import/consumer audit | **1,164 checks, zero failures**. [Report](../output/qa/rc-017/resource-audit.json). |
| Native rendered motion | **642 checks, zero failures**; every rendered frame preserves the already-resolved model and each complete trace equals the emitted event payload order. [Results](../output/qa/rc-017/final/motion/results.json). |

These expanded suite totals overlap their baseline runs and are not additional unique assertions. The historical RC-010 planning audit's sole remaining failure is its old protected-file baseline: 17 files have evolved in subsequent authorized work. Current schema, paths and links pass; the old baseline is not rewritten. Inherited generated-art rights remain unresolved and are not cleared by runtime verification.

The final `tools/godot.ps1 -Action import -LogDirectory output/qa/rc-017/final/import` completed successfully, with the pre-existing unavailable Android build-tools directory warning. No SDK change was made. Links in the three new usage/actor/verification documents resolve; [link record](../output/qa/rc-017/final/document-links.json). [Capture integrity](../output/qa/rc-017/final/capture-integrity.json) confirms the recorded production implementation matches the final motion capture.

Representative motion and native stills:

- [Damage Cast, actor and scenery at 450×1000](../output/qa/rc-017/final/motion/cast-top-450x1000/motion.gif), [ordered frame sheet](../output/qa/rc-017/final/motion/cast-top-450x1000/contact.png).
- [Full 720×1600 Cast](../output/qa/rc-017/final/motion/cast-top-720x1600/motion.gif), [native hit still](../output/qa/rc-017/final/motion/cast-top-720x1600/key-damage.png).
- [Native 360×640 board traversal/cleanup](../output/qa/rc-017/final/motion/cast-board-360x640/motion.gif), [lower-page scroll](../output/qa/rc-017/final/motion/cast-board-360x640/after-bottom.png).
- [Shield, zero enemy HP loss and blocked retaliation](../output/qa/rc-017/final/motion/shield-top-450x1000/motion.gif), [native blocked-hit still](../output/qa/rc-017/final/motion/shield-top-450x1000/key-retaliation.png).
- [Confirmed Pass](../output/qa/rc-017/final/motion/pass-top-450x1000/motion.gif), [victory](../output/qa/rc-017/final/motion/victory-top-450x1000/motion.gif), [defeat](../output/qa/rc-017/final/motion/defeat-top-450x1000/motion.gif).
- [Reduced-motion Cast](../output/qa/rc-017/final/motion/cast-board-450x1000-reduced/motion.gif), [Conjure and generated-card feedback at 360×640](../output/qa/rc-017/final/motion/conjure-bottom-360x640/motion.gif).

The review found and corrected a damage label overlapping the live enemy name; its final attachment follows the actor body. Player shield/retaliation cues now attach to player health. Dim cleanup rings persist through the remaining shared sweep/draw so short cell steps remain readable. Final samples show no residual neutral silhouette, pose-envelope clipping or final-board rollback. The native 360 page intentionally scrolls, with the hand, forecast, Cast and navigation still reachable. The owner-retained hit painting remains unchanged and has no dodge semantics.

An intermediate capture exposed an untyped array passed to `warm_poses`; the caller now uses its typed default, and the final engine log contains no script errors. Earlier captures/logs are intermediate evidence and do not supersede `final/motion`.

| Presentation | Observed deterministic duration |
| --- | --- |
| Damage Cast | 0.98 s |
| Shield Cast | 1.08 s |
| Pass | 0.54 s |
| Lethal victory | 1.01 s |
| Player defeat | 0.87 s |
| Reduced-motion damage Cast | 0.42 s |
| Conjure | 0.24 s |

At 24 samples/s, captures round up to the next sample boundary. Capture wall time per sequence ranged from 0.685 to 9.062 seconds due to render readback and PNG writing; it is not gameplay frame time. Observed maximums were **zero emitting particle nodes / zero particles**, **385 scene nodes**, **527 rendered draw calls**, and **49,525,995 engine-reported texture bytes** (about 47.23 MiB). The shared effects add no raster textures. Texture counters cover UI, caches and native render targets in this multi-viewport harness; compare the separate resource audit for decoded artwork estimates.

## Measurement limits

Capture duration is deterministic presentation time; wall-clock capture time includes readback, PNG compression and harness assertions. Resource observations include actual emitting particle-node counts and Godot-reported draw calls/texture bytes during sequential native viewport rendering. Those counters include render targets, caches and UI textures and do not establish physical-device or driver residency, input feel, frame rate, or owner aesthetic acceptance. No mobile build, SDK upgrade, audio production or gameplay change is part of this verification. The root agent disclosed an initial read-only Git status command before reading the pasted prohibition; no further Git operation was performed. The capture/regression subtask performed no Git operation.
