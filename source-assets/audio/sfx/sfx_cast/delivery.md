# sfx_cast - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## cast.wav

Approved r002 arcane gesture, preserved generated shimmer and release.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [cast.mp3](../revisions/r003-runway-library/originals/cast.mp3); unchanged provider MP3.
- Working master: [cast.wav](cast.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [cast.wav](../../../../assets/audio/sfx/sfx_cast/cast.wav); 48 kHz mono 16-bit PCM.
- Length: 22,512 samples / 0.469000 seconds; one-shot.
- Intended playback gain: -3.0 dB; float render RMS -23.00 dBFS; estimated true peak -8.96 dBTP.
- Source window: 0.000000 to 0.469002 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `49b98c66c8654fcd74c8e5ec3fbc90ffb93dd9603dff5e147955f5984da0c02c`.
- Master SHA-256: `47ffabb5661ab7b3cc148d9af6510177769ffe2963adea65819b9216dd178c37`.
- Runtime SHA-256: `a2eed026319d32018f95b8719d7d611c419bba11d2794f682a30c45c183c0645`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
