# sfx_shield - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## shield.wav

Approved r002 protective glass resonance, tail edited to family limit.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [shield.mp3](../revisions/r003-runway-library/originals/shield.mp3); unchanged provider MP3.
- Working master: [shield.wav](shield.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [shield.wav](../../../../assets/audio/sfx/sfx_shield/shield.wav); 48 kHz mono 16-bit PCM.
- Length: 19,630 samples / 0.408958 seconds; one-shot.
- Intended playback gain: -4.0 dB; float render RMS -24.00 dBFS; estimated true peak -7.96 dBTP.
- Source window: 0.000000 to 0.408957 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `4bf94d092c96dd5362593c3fcd7bf53a689a303be03c716dbe218572f0378608`.
- Master SHA-256: `6a94fca7de79b50bebcfc9c48492ae96afaae9fc125fc1c2858aa2b194a7da01`.
- Runtime SHA-256: `aed3a30ad4dc2ba57817164335b776548cdf5917476c6d2826e39b2e86f49cbe`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
