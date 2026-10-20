# sfx_phase - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## guardian_phase_changed.wav

Compact larger spectral/bronze transition gesture.

Future only; awaits the real gameplay system and RC-042 binding.

- Original: [guardian_phase_changed.mp3](../revisions/r003-runway-library/originals/guardian_phase_changed.mp3); unchanged provider MP3.
- Working master: [guardian_phase_changed.wav](guardian_phase_changed.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [guardian_phase_changed.wav](../../../../assets/audio/sfx/sfx_phase/guardian_phase_changed.wav); 48 kHz mono 16-bit PCM.
- Length: 38,396 samples / 0.799917 seconds; one-shot.
- Intended playback gain: -3.0 dB; float render RMS -23.00 dBFS; estimated true peak -8.04 dBTP.
- Source window: 0.000000 to 0.799909 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `b25f77f5ca4901b3a5681eea4ac99d8db95dbc14262b826c8eefccc41ece6458`.
- Master SHA-256: `740c64274a782c59d918ab70ed4877af82a132f98c9e425b13f24681d9910a57`.
- Runtime SHA-256: `a94ce576e75b33d8fe864227fbb479b0befb6737ff68e812d8b20e089a15fe37`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
