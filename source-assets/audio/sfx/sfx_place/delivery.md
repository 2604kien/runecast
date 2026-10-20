# sfx_place - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## edit_place.wav

Approved r002 stone/ceramic placement with grit settling; edge silence removed.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [edit_place.mp3](../revisions/r003-runway-library/originals/edit_place.mp3); unchanged provider MP3.
- Working master: [edit_place.wav](edit_place.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [edit_place.wav](../../../../assets/audio/sfx/sfx_place/edit_place.wav); 48 kHz mono 16-bit PCM.
- Length: 8,402 samples / 0.175042 seconds; one-shot.
- Intended playback gain: -6.0 dB; float render RMS -26.72 dBFS; estimated true peak -7.00 dBTP.
- Source window: 0.071156 to 0.246190 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `63ea9b8eaf63503a610a604a1d5947f362f98d6a45844bf58c27f34454ede513`.
- Master SHA-256: `986073afb769aaf957cbb1c99a7bb15f72fc741609068e3c89ce935f6fbede56`.
- Runtime SHA-256: `d51c5ac42c097e9a3d1d4f5b6140803ca3c8411e6f34bbc61c8c5e0a9b3634bc`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
