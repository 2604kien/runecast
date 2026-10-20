# RC-020 — Available audio integrated; music acceptance pending

October 18, 2026. Production SFX, crypt ambience, persistent controls and the playback/lifecycle framework are implemented. **RC-019 remains incomplete and the original full RC-020 task remains partial**: Home/exploration and combat music are unavailable by owner choice. No substitute, silent placeholder or future gameplay system was created. One initial read-only `git status` ran before the pasted no-Git instruction was read; it was disclosed immediately. No further Git operation was performed; the owner handles Git.

[Recorded playable review](../output/qa/rc-020/demo/index.html) · [Captured mixer WAV](../output/qa/rc-020/demo/playable-mix.wav) · [Actual frame overview](../output/qa/rc-020/demo/contact.png) · [Full AVI](../output/qa/rc-020/demo/playable.avi) · [Runtime trace](../output/qa/rc-020/demo/results.json)

## Implemented scope

One scene-owned `AudioCoordinator` owns `RuneCast SFX`, `RuneCast Music` and `RuneCast Ambience` buses, eight fixed SFX voices including tails, two fixed music slots and one independently fading ambience player. The shipped GDScript catalogue contains current r003 resource paths and availability metadata; the coordinator lazily owns available imported resources and releases its cache on disposal. Source-only documentation JSON is not needed by the game. Pending music is never loaded. Four future actors and reward/purchase/upgrade/heal/guardian-phase aliases remain unbound.

Accepted command results retain actual arguments and targets. UI feedback has separate dispatch identity and a cross-reason 250 ms explicit-rejection throttle. Combat audio uses accepted batches, new phase/contact notices from the existing presentation clock, and post-effect/post-commit result events. Actor contact reads metadata; Shadeling remains 0.28. Large advances, zero-duration steps and cancellation reentry preserve exactly-once milestones. The generated Cast tone and its old player/path are removed. Gameplay, RNG and visual pacing remain independent of audio.

Normal contact has at most actor plus one actual player consequence; zero damage, duplicate block, later arrivals/cleanup and inferred outcomes are silent. Reduced Cast retains Cast then an actual retaliation outcome, suppressing its separate enemy-damage/shield-gain pings. One foreground plus at most one release tail replaces old sounds without a queue; ordinary arrivals and cleanup yield to important active cues. An 8 ms sample-domain envelope derived from the playing imported mono WAV supplies the bounded release. Normal WAV duration is unchanged; native player completion governs automatic lifetime, so a frame hitch does not subtract pre-start time from a new cue.

Menu → Options reuses the existing sliders, toggles and modal. Music and SFX each persist a level and mute; Sound is a compatible master switch retaining both levels. Ambience follows Music. Legacy `[audio] enabled` is authoritative; absent levels default to 1.0, individual mutes to false. Existing reduced motion and unrelated keys survive. Loading/reopening does not write defaults or play previews; the next actual setting change saves normalized values. Corrupt files are not overwritten. CLI/runtime reduced-motion overrides do not accidentally persist through unrelated audio changes.

Focus loss, suspension, hidden-scene state, mute, cancellation, Restart, Exact replay, replacement and teardown invalidate effects and stale subscriptions. Resume/unmute does not replay skipped effects. Compatible loops pause/resume at their position; context replacement retargets bounded fades. A 0.6 s music crossfade exists, but production music has not been validated.

## Executed checks

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility renderer, was used with isolated test settings/application-data paths. Expected invalid-content fixture messages are not new failures.

| Check | Executed result |
| --- | --- |
| Core regression, including presentation milestones | **1,827 checks, zero failures.** [Log](../output/qa/rc-020/core/test.log). |
| Playable UI regression | **1,148 checks, zero failures.** [Log](../output/qa/rc-020/ui/smoke.log). |
| Focused catalogue/audio/settings/lifecycle suite | **428 checks, zero failures.** [Assertions](../output/qa/rc-020/audio-tests.json), [log](../output/qa/rc-020/audio-tests.log). |
| Exported-resource playback probe | **28 checks, zero failures**, from the actual exported `runtime.pck`: docs unavailable, all 21 imported WAVs present, compressed looping crypt, accepted Pass actor playback and clean teardown. [Export](../output/qa/rc-020/export-pack.log), [standalone probe](../output/qa/rc-020/export-probe.log). |
| Actual Menu/Options geometry | **42 checks, zero failures**, nine renders at 720×1600, 450×1000 and 360×640. Fixed Close remains reachable; body scrolling exposes reduced motion. [Report](../output/qa/rc-020/options/results.json), [360 Options](../output/qa/rc-020/options/options-top-360x640.png), [360 Menu](../output/qa/rc-020/options/menu-360x640.png). |
| Playable audio/video capture | **11 sequences, zero failures**, 44.309 s of captured stereo mixer output, 267 timed review images; actual Movie Maker AVI has 1,330 frames at 30 fps / 44.333 s. [Report](../output/qa/rc-020/demo/results.json), [log](../output/qa/rc-020/demo/capture.log). |

Focused coverage includes accepted/rejected edits and supplied arguments, once-only Cast/phase/contact/commit, positive/zero loss, full/partial block, Pass and lethal outcomes, silent technique phase with actual first arrivals, grouped cleanup, normal/reduced voice limits and release samples, large advance, repeated refresh/input, cancellation/reentrant restart/replay/teardown, master/individual mute, persistence/migration, interruption without stale replay, crypt/Menu continuity, unavailable music and two-slot transition replacement using isolated test-only streams. The report lists each assertion, including 17 native lifetime/lifecycle checks and 26 settings checks. Nested focus/suspend notifications, stale disposed settings owners and hidden scenes are exercised. Test-only music streams do not ship and do not establish acceptance of the missing tracks.

The rendered capture loads ordinary `main.tscn`, uses real UI handlers and the automatic production clock. Existing test helpers construct legal paths through actual controls; Shield uses its actual drawn UID, and terminal fixtures set current target HP to one before resolution. Each sampled authoritative snapshot remains fixed throughout playback. Traces show one normal actor-plus-impact contact, no retaliation on lethal Cast, one first actual technique arrival, and reduced outcome grouping. Rapid setup edits intentionally stress all eight voices. Crypt records **one start throughout** Menu/Options, actions and replay; music records **zero starts**. The ending loop probe seeks the existing imported player to 0.2 s before its end and observes its actual wrap without a new start. It is a shortened boundary probe, not five complete listening cycles.

## Measured mix and listening limits

The first untrimmed eight-voice rapid-edit stress reached **+1.113 dBFS** in the float Master capture. Its failed [report](../output/qa/rc-020/initial-mix/results.json) and [log](../output/qa/rc-020/initial-mix/capture.log) are retained. The clipping occurred during unusually rapid control construction before the Cast phase, demonstrating why the full voice ceiling needs headroom.

The deliberate adjustment is **−6 dB on the SFX bus**, additional to unchanged catalogue/role gains and user volume. Music/ambience gain and cue priorities remain unchanged. Repeating the same stress with the native lifetime fix passes:

| Measurement | Result |
| --- | ---: |
| Internal float Master sample peak | −5.22023 dBFS |
| Saved 48 kHz, 16-bit stereo WAV sample peak | −5.2205 dBFS |
| Independently estimated reconstructed true peak | −5.2114 dBTP |
| Whole-recording RMS | −23.6184 dBFS |
| Clipped / nonfinite captured samples | 0 / 0 |
| Maximum SFX voices, including tails | 8 |

[Independent meter](../output/qa/rc-020/demo/mix-measurements.json) uses the retained RC-018 8×, 96-tap Kaiser-sinc reconstruction separately per channel. It is an estimate, not a certified meter or equal-perceived-loudness claim. The capture includes SFX plus the actual crypt bed at full user levels. The later resource-cache lifetime refinement changes resource ownership, not these imported files/gains or playback policy; final focused/export verification covers that refinement separately.

The recording uses Godot's Dummy/internal movie mixer and actual rendered scene. It demonstrates measured playback; **no headphone, ordinary-speaker, physical-device or human perceived-balance review is claimed**. The sparse-image HTML follows recorded PCM positions; use the AVI for full-frame-rate motion. Native 450×1000 top framing retains the normal page scrolling and does not pretend to show every off-page hand animation. The settings captures separately cover narrow reachability.

Five-join ambience listening, full-library repeated-use comfort, both music loops, production crossfade listening and the final music/ambience/SFX mix remain pending. Actual Android/iOS interruption and device acceptance remain with platform/lifecycle tasks. [Exact music-delivery follow-up](audio-loop-integration.md#when-the-music-is-delivered).

## Reproduction

From the project root, retain workspace-local `APPDATA`/`LOCALAPPDATA` for tests. The capture injects its own `demo-settings.cfg`, leaving player settings untouched.

```powershell
.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-020/core
.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-020/ui
& '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/audio_playback_runner.gd
& '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . --audio-driver Dummy --resolution 450x1000 --write-movie output/qa/rc-020/demo/playable.avi --fixed-fps 30 --disable-vsync --script res://tools/capture_audio_playback.gd
& 'C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/pack_audio_playback.py
```

The existing Android preset can produce a resource pack without claiming an installable Android build; its retained missing-build-tools diagnostic is separate from the successful resource-pack export and standalone playback probe. No Android/iOS installation or device result is claimed. The current handoff audit passes **629 checks** for usage/source-document local links, CSV shape and catalogue resource availability. [Audit](../output/qa/rc-020/handoff-validation.json).

The renderer needs a real graphics context; `--headless` is appropriate for core/audio assertions, not rendered evidence. The older RC-018/RC-019 asset validators include historical “production unchanged/no bindings” snapshots. Those original baselines remain intact and are not rewritten to make integration pass; current catalogue parity and RC-020 suites validate the new consumers.
