# RC-018 isolated audition — r003 Runway library

17 October 2026. Open [index.html](index.html) in an ordinary browser. All cue buttons use native HTML audio and repository-relative runtime file URLs; no network account, fetch, WebAudio decode or server is required. Review volume defaults to 50% uniformly and can be raised to 100%; each individual cue still applies its specified relative gain. Stop halts the active player before another selection begins.

The active library contains 21 Runway-derived runtime WAVs in 16 manifest families. Original provider outputs are lossy MP3 files; the mono 48 kHz PCM16 runtime exports and PCM24 editing masters do not restore source fidelity. The owner approved the five-cue r002 direction. Acceptance of the complete edited library and final perceived balance remains pending.

- [Indexed 19.274917-second listening reel](listening-reel.wav), [timecodes](listening-reel-index.md) and [machine-readable index](listening-reel-index.json). Duration is measured from the current exports, including the 0.35-second lead and 0.45-second gaps. The reel sample peak is −8.1871 dBFS.
- Five labelled comparison WAVs: quiet UI/editing, magic/protection, the five separate actor variants, results/future transactions, and repeated editing/draw comfort check.
- Sixteen sequence WAVs: Cast, shield, Pass, Focus, Conjure, cleanup, victory and defeat, each normal/reduced. [Preview index](preview-index.json) records every actual event, cue, gain, scheduled time and omitted decorative/grouped cue.
- [Godot mixer capture](godot-mix-capture.wav) and [per-cue import/playback report](godot-playback.json). The report provides runtime hashes, imported PCM hashes, gains and capture offsets. The HTML exposes these as current evidence only when all 21 runtime file hashes match.
- [Cue catalogue](../../../docs/audio-cue-catalogue.json), [integration contract](../../../docs/audio-integration.md), [editable Runway render settings](../../../source-assets/audio/sfx/runway-settings.json), [audio renderer](../../../source-assets/audio/sfx/render_runway_sfx.py), [generation and edit report](../../../source-assets/audio/sfx/runway-generation-report.json).
- [Original generation records and prompts](../../../source-assets/audio/sfx/revisions/r003-runway-library/generation.json), [provenance](../../../source-assets/audio/sfx/provenance.json) and the [preserved five-cue audition](r002/index.html), whose earlier WAVs are frozen r001 copies.

Four future actor variants, reward and guardian phase are clearly marked future-only. None is inserted into current combat examples. These are review files excluded from runtime imports/exports by the existing output boundary.

## Verification and playback evidence

Current preview build: 21 cues, 16 actual-trace sequences and five comparison WAVs. All preview renders passed the −3 dBFS sample-peak guard; their highest sample peak is −8.1871 dBFS. The main preview JavaScript syntax and local resource paths are checked separately from perceptual listening.

Godot evidence status for this build: **21 current runtime files passed, with zero failures**. Every report hash matches r003; the HTML exposes the refreshed import/playback report and mixer capture. The harness is unchanged apart from selecting active settings through the cue catalogue. This run used the Dummy driver at a 44,100 Hz internal mix rate.

The pinned Godot `4.7.2.stable.official.ed1daf0bf` harness verifies imports as mono 48 kHz PCM16 `AudioStreamWAV`. `compress/mode=0`, `edit/trim=false`, `edit/normalize=false` and no sample-rate override preserve the runtime PCM data. The focused player compares the imported data bytes with each current RIFF data chunk and records both SHA-256 values.

Each file passes through a real `AudioStreamPlayer` at its intended gain, then an isolated bus with `AudioEffectCapture`. The harness checks advancing playback position, natural completion, finite nonzero output and unclipped captured peaks. Its report records the actual driver and mixer sample rate, which are separate from the 48,000 Hz source/import rate. The capture is stereo 16-bit WAV with indexed per-cue offsets in the report. This establishes automated engine playback evidence when current; it does not establish headphone, speaker or physical-device acceptance. No assistant listening review or complete-library owner approval is claimed.

[Presentation traces](presentation-traces.json) contain 16 successful cases obtained from actual `controller.command()` results and the real animated presenter. Every event commits once in supplied order; controller state remains unchanged during presentation and completion unlocks the controller. Circuit/cleanup/terminal cases use the existing detached animation-test setup and real cards/commands. Focus/Conjure use a natural seeded production opening. Full snapshots and fixture descriptions are retained; these are not fabricated gameplay events.

Normal timing comes directly from the adapter's scheduled steps: Cast 0.90s, enemy damage and retaliation 1.50s each, played technique 1.00s, actual arrivals 0.40s each, cleanup 0.18s per actual slot/hand card, terminal 0.75s. Reduced mode caps each individual effect at 0.06s. Attack contact uses the captured actor motion resource's normalized `attack_contact=0.28`, producing 0.42s normal and 0.0168s reduced contact offsets. No independent wall-clock gameplay delays are proposed. Frame hitches can extend actual wall time because the production presentation clock clamps automatic delta.

## Grouping used in the preview

Normal mode plays one accepted Cast, impact only for positive applied HP loss, a quiet shield gain with its later block duplicate suppressed, and one actor variant at contact with a quieter player-injury accent when applicable. Technique animation is silent; the first actual supplied card arrival gets one draw/conjure cue and later arrivals remain silent. Cleanup shares one accent from its first actual eligible event. Results play only after `battle_ended` visual completion and consequence commit. Pass has no fabricated Cast, enemy damage or player gain. Lethal victory has no retaliation, next-turn draw or reward cue.

Reduced mode retains one foreground voice with at most 10ms replacement crossfade. An accepted Cast shares its action sound, omits separate enemy-damage/shield-gain restarts, then uses one retaliation contact outcome: positive HP loss, else actual block, else actor. This gives at most two mandatory starts per Cast, one per Pass, plus any actual terminal result. A standalone technique has one sound at its first actual arrival. Lower-priority cleanup and ordinary next-turn arrivals are omitted while a higher-priority foreground sound is active; they are never delayed into a later phase. Sound durations are not time-compressed or forced to match the visual phase.

`event_presented` is a post-visual, post-staged-commit signal. It is suitable for the chosen result cue, but **not phase start or contact**. RC-020 still owns the needed generation-safe presentation-clock hooks, lifecycle cancellation, audio buses/settings, production voice rules, accepted UI feedback and replacement of the current tone. No main scene, controller, animation or model file is changed by these tools.

## Reproduce

From `C:\Dev\RuneCast`, using the retained source MP3s and deterministic edit settings:

```powershell
$audioPython = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $audioPython source-assets\audio\sfx\render_runway_sfx.py
# Process-local writable editor state; no project settings are changed.
$env:APPDATA = 'C:\Dev\RuneCast\output\audio\rc-018\godot-user'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\audio\rc-018\godot-user-local'
$godotAudio = '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $godotAudio --headless --path . --log-file 'C:\Dev\RuneCast\output\audio\rc-018\import.log' --editor --import
& $godotAudio --headless --path . --log-file 'C:\Dev\RuneCast\output\audio\rc-018\trace.log' --script res://tools/audio_audition_trace.gd
& $godotAudio --headless --path . --log-file 'C:\Dev\RuneCast\output\audio\rc-018\playback.log' --script res://tools/audio_audition.gd -- --verify
& $audioPython tools\build_audio_preview.py
# Optional visible isolated Godot cue buttons; real default system audio driver.
& $godotAudio --path . --log-file 'C:\Dev\RuneCast\output\audio\rc-018\player-ui.log' --script res://tools/audio_audition.gd
```

The Python preview renderer needs NumPy already available in the bundled runtime; no dependency was installed. Both the preview builder and Godot audition select the active settings through `docs/audio-cue-catalogue.json`. Every sequence/reference WAV is rendered from the delivered runtime PCM at the documented gain, without additional preview normalization or added sound sources. A full-scale peak assertion rejects preview mixes above −3 dBFS. These offline sample peaks are not an additional true-peak or perceived-loudness claim. Reproduction edits the retained MP3s; it does not rerun the generative service or promise that a repeated prompt would recreate the original.

The HTML JavaScript passed Node syntax checking. No browser screenshot or audible playback review is claimed for r003. The browser-independent source and local-link checks do not establish visual or listening acceptance.

Engine logs: [import](import.log), [trace](trace.log), [playback](playback.log). Consult the current report's hashes before treating any earlier log or capture as evidence for these files. Historical r001 diagnostics are not r003 acceptance results.
