# sfx_reward - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## reward.wav

Small warm ascending magical reward flourish.

Future only; awaits the real gameplay system and RC-042 binding.

- Original: [reward.mp3](../revisions/r003-runway-library/originals/reward.mp3); unchanged provider MP3.
- Working master: [reward.wav](reward.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [reward.wav](../../../../assets/audio/sfx/sfx_reward/reward.wav); 48 kHz mono 16-bit PCM.
- Length: 20,520 samples / 0.427500 seconds; one-shot.
- Intended playback gain: -5.0 dB; float render RMS -23.00 dBFS; estimated true peak -6.99 dBTP.
- Source window: 0.000000 to 0.427506 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `51a71bd2ec64dd2dd420a4c838b3b472ff01d3d3c785971ffefd9b35bbc69d68`.
- Master SHA-256: `31dd527537437313aec4582152946f8982f86a8d400ce0a1e4be7b22c9b4f1e1`.
- Runtime SHA-256: `9a73059830d2c08d7cedf5521f024aa267e2d0f25df389631f562b5b160e2efe`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
