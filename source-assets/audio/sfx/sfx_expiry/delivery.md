# sfx_expiry - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## temporary_expired.wav

Soft dissolving parchment/air cleanup gesture.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [temporary_expired.mp3](../revisions/r003-runway-library/originals/temporary_expired.mp3); unchanged provider MP3.
- Working master: [temporary_expired.wav](temporary_expired.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [temporary_expired.wav](../../../../assets/audio/sfx/sfx_expiry/temporary_expired.wav); 48 kHz mono 16-bit PCM.
- Length: 16,800 samples / 0.350000 seconds; one-shot.
- Intended playback gain: -9.0 dB; float render RMS -26.00 dBFS; estimated true peak -9.53 dBTP.
- Source window: 0.000000 to 0.350000 seconds. Overlength removed: 0.124467 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `a30ca63d071882a153937cf4ee25b4ca81fd4b44e70fdf759e9214a7a6e7997c`.
- Master SHA-256: `0a05de33ea3667de0ba212f7880b405603900301afd9bfe0cb0021e0dd043399`.
- Runtime SHA-256: `bd459b152210d58d10865b45244b09a01a614859aca5af9cfceb4d7cb53b109b`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
