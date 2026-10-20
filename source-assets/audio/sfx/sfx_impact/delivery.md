# sfx_impact - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## damage.wav

One compact layered material contact, distinct from UI movement.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [damage.mp3](../revisions/r003-runway-library/originals/damage.mp3); unchanged provider MP3.
- Working master: [damage.wav](damage.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [damage.wav](../../../../assets/audio/sfx/sfx_impact/damage.wav); 48 kHz mono 16-bit PCM.
- Length: 17,131 samples / 0.356896 seconds; one-shot.
- Intended playback gain: -2.0 dB; float render RMS -24.20 dBFS; estimated true peak -6.17 dBTP.
- Source window: 0.000000 to 0.356893 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `fd50433959d3dcf530d7f37fdeae4ae469f0b5831b707b2915583c7048244630`.
- Master SHA-256: `e29273b75bc53ceee4449df1631394c15fa5ebf508ba054f421f238803574a7c`.
- Runtime SHA-256: `e179b6ccc86b1811430df148d1c0cf31d4b5de27c7a6bb8439de574fc5b8ee60`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
