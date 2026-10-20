# sfx_defeat - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## defeat.wav

Subdued descending resonant resolution with a soft ending.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [defeat.mp3](../revisions/r003-runway-library/originals/defeat.mp3); unchanged provider MP3.
- Working master: [defeat.wav](defeat.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [defeat.wav](../../../../assets/audio/sfx/sfx_defeat/defeat.wav); 48 kHz mono 16-bit PCM.
- Length: 71,036 samples / 1.479917 seconds; one-shot.
- Intended playback gain: -4.0 dB; float render RMS -27.55 dBFS; estimated true peak -7.00 dBTP.
- Source window: 0.000000 to 1.479909 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `6f1203d821264548f8d6fb23bbdf22a97849a88f4a5034de23cb6129f257254c`.
- Master SHA-256: `f59e5e50563ca817135923c1dec2d3293cff10ab563bb251ecac83e22d98d9c6`.
- Runtime SHA-256: `9291e8878019f33d928104621b46b19075ffd813fa1f510aad83d6b7f5b848c0`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
