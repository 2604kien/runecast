# sfx_invalid - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## action_rejected.wav

Quiet muted wooden obstruction, restrained low feedback.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [action_rejected.mp3](../revisions/r003-runway-library/originals/action_rejected.mp3); unchanged provider MP3.
- Working master: [action_rejected.wav](action_rejected.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [action_rejected.wav](../../../../assets/audio/sfx/sfx_invalid/action_rejected.wav); 48 kHz mono 16-bit PCM.
- Length: 12,000 samples / 0.250000 seconds; one-shot.
- Intended playback gain: -10.0 dB; float render RMS -26.00 dBFS; estimated true peak -16.96 dBTP.
- Source window: 0.000000 to 0.250000 seconds. Overlength removed: 0.229002 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `ff572ad6c8136fa1c365784092126da93f07fcd18154d2ee694acfe60aa70fce`.
- Master SHA-256: `ea9072e14a23d77302c1f687373064fe2208a87f9e6ffc490bc2c75e9eaba7d6`.
- Runtime SHA-256: `38a7e219d591a5dd754a0b7f8138a7b1f9efd7e6827bc9d3c4ca4577df64ee53`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
