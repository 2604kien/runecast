# sfx_ui_back - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## ui_back.wav

Soft reverse wood release with a short cloth movement.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [ui_back.mp3](../revisions/r003-runway-library/originals/ui_back.mp3); unchanged provider MP3.
- Working master: [ui_back.wav](ui_back.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [ui_back.wav](../../../../assets/audio/sfx/sfx_ui_back/ui_back.wav); 48 kHz mono 16-bit PCM.
- Length: 8,850 samples / 0.184375 seconds; one-shot.
- Intended playback gain: -8.0 dB; float render RMS -29.48 dBFS; estimated true peak -9.50 dBTP.
- Source window: 0.003379 to 0.187755 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `1df4808dcfeed5ac44f65787515228c636e6321d6e8ec0549acc4e206f90858a`.
- Master SHA-256: `70ae2b0b741354e82e99f533b0de48688d54eb00133722b2dfe3f3e5d1fc560c`.
- Runtime SHA-256: `f0048ea532bef8c3edb0574743e39539045eab7e144410464a1938283efe457b`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
