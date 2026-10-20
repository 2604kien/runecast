# sfx_rotate - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## edit_orient.wav

Short circular stone scrape ending in its own natural detent.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [edit_orient.mp3](../revisions/r003-runway-library/originals/edit_orient.mp3); unchanged provider MP3.
- Working master: [edit_orient.wav](edit_orient.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [edit_orient.wav](../../../../assets/audio/sfx/sfx_rotate/edit_orient.wav); 48 kHz mono 16-bit PCM.
- Length: 9,600 samples / 0.200000 seconds; one-shot.
- Intended playback gain: -6.0 dB; float render RMS -24.50 dBFS; estimated true peak -8.43 dBTP.
- Source window: 0.000000 to 0.200000 seconds. Overlength removed: 0.188050 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `b09cca7ae73429973d6cd28e26c35d024ff670df04ae986ded5593b4be1983e0`.
- Master SHA-256: `ae47517fe6f61a4f6e51ead02af9ee9b7694235924d4baadaf4c11ac6834681b`.
- Runtime SHA-256: `18b3e92f8a033624eb3e225a509dfb821dddb3f83021b973d814a5b47086f7e0`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
