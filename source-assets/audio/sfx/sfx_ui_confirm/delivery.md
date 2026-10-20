# sfx_ui_confirm - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## ui_confirm.wav

Quiet single wooden latch acceptance click, generated Foley gesture.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [ui_confirm.mp3](../revisions/r003-runway-library/originals/ui_confirm.mp3); unchanged provider MP3.
- Working master: [ui_confirm.wav](ui_confirm.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [ui_confirm.wav](../../../../assets/audio/sfx/sfx_ui_confirm/ui_confirm.wav); 48 kHz mono 16-bit PCM.
- Length: 9,600 samples / 0.200000 seconds; one-shot.
- Intended playback gain: -8.0 dB; float render RMS -33.42 dBFS; estimated true peak -9.00 dBTP.
- Source window: 0.000000 to 0.200000 seconds. Overlength removed: 0.124150 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `ca6158c014b34761a4f11f2ca1412c18cfc4c6dda9c5ac243ee432b3bcc2c582`.
- Master SHA-256: `be5b54dbd618ccd187f803fb903edcc04f1c68ec5eb27ed4f3b4df5f37c960df`.
- Runtime SHA-256: `57053f7ab83bacfcb7c8e45a5c70600d848d2e48723a1bacb380b268e42237c9`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
