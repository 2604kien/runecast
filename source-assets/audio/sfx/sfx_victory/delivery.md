# sfx_victory - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## victory.wav

Compact warm ascending victory resolution.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [victory.mp3](../revisions/r003-runway-library/originals/victory.mp3); unchanged provider MP3.
- Working master: [victory.wav](victory.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [victory.wav](../../../../assets/audio/sfx/sfx_victory/victory.wav); 48 kHz mono 16-bit PCM.
- Length: 51,816 samples / 1.079500 seconds; one-shot.
- Intended playback gain: -3.0 dB; float render RMS -36.16 dBFS; estimated true peak -6.50 dBTP.
- Source window: 0.000000 to 1.079501 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `ca16873dd5d6bfd4d45b2768a00123701d7ac7650b25f2a9c393687970491206`.
- Master SHA-256: `ac4d6a0582764120e8e4652d9a8715eda457761a4a4a119b1e58922db0cc8c66`.
- Runtime SHA-256: `f8fa3dc1cb5b63be8b0635d35b4f76d2aecbef9eba9e926cb65f90f02cec8f5e`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
