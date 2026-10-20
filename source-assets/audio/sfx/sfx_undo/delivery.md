# sfx_undo - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## edit_restore.wav

Small rune lifted from stone, short release friction and air.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [edit_restore.mp3](../revisions/r003-runway-library/originals/edit_restore.mp3); unchanged provider MP3.
- Working master: [edit_restore.wav](edit_restore.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [edit_restore.wav](../../../../assets/audio/sfx/sfx_undo/edit_restore.wav); 48 kHz mono 16-bit PCM.
- Length: 12,000 samples / 0.250000 seconds; one-shot.
- Intended playback gain: -6.0 dB; float render RMS -24.50 dBFS; estimated true peak -10.20 dBTP.
- Source window: 0.000000 to 0.250000 seconds. Overlength removed: 0.229909 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `da0be234c39d2badb368023f6430483d34be7c285c048202400916b81f978155`.
- Master SHA-256: `4d3fbeb7f4a899cc26c23330987a1acbba65acfb37a19f537bdda24e2609a431`.
- Runtime SHA-256: `7766214262847b5f99ba67e8b6466fae9f1ebf6aa423595f878bdc7d6cba2183`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
