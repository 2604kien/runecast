# sfx_technique - RC-018 r003 Runway library

Runway-generated source audio in the owner-approved r002 direction, with documented local editing. Stable source/runtime destinations are preserved.

See [delivery](../delivery.md), [editing settings](../runway-settings.json), [renderer](../render_runway_sfx.py), [generation records](../revisions/r003-runway-library/generation.json) and [provenance](../provenance.json).

## technique_draw.wav

Approved r002 thick parchment slide, natural friction and flex.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [technique_draw.mp3](../revisions/r003-runway-library/originals/technique_draw.mp3); unchanged provider MP3.
- Working master: [technique_draw.wav](technique_draw.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [technique_draw.wav](../../../../assets/audio/sfx/sfx_technique/technique_draw.wav); 48 kHz mono 16-bit PCM.
- Length: 15,294 samples / 0.318625 seconds; one-shot.
- Intended playback gain: -5.0 dB; float render RMS -31.16 dBFS; estimated true peak -7.50 dBTP.
- Source window: 0.000000 to 0.318617 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 2/20 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `49fdf18b386faec49fc4ffcd3753fa42308aa8c1e11b01a69570ef7079d7c576`.
- Master SHA-256: `dd11926ed84c80c8cbaeb11fe838b758e68f0ada5cb37463b040b3ff059e7fa2`.
- Runtime SHA-256: `7fe8a3e55344315ef71017f3eebb42b1bce9c8dfc34566a1943f8ce8ec167110`.

## technique_conjure.wav

Parchment card forming in a compact airy magical bloom.

Current action/event candidate; production playback binding remains RC-020 work.

- Original: [technique_conjure.mp3](../revisions/r003-runway-library/originals/technique_conjure.mp3); unchanged provider MP3.
- Working master: [technique_conjure.wav](technique_conjure.wav); 48 kHz mono 24-bit PCM, an edited derivative of the MP3.
- Runtime: [technique_conjure.wav](../../../../assets/audio/sfx/sfx_technique/technique_conjure.wav); 48 kHz mono 16-bit PCM.
- Length: 16,234 samples / 0.338208 seconds; one-shot.
- Intended playback gain: -5.0 dB; float render RMS -28.36 dBFS; estimated true peak -7.00 dBTP.
- Source window: 0.000000 to 0.338209 seconds. Overlength removed: 0.000000 seconds. No time stretch or pitch shift.
- Fade in/out: 5/35 ms. Per-material filtering, DC correction, sinc resampling and TPDF quantization settings are recorded in the editable config.
- Original SHA-256: `81e9c02f5580e73c3775bbae3c0bce3c2241f84e0e97c79613868e17d82ce96d`.
- Master SHA-256: `b3a27fe0c8f885c9a32b555b285f81317e40e00d221856c41c69639e7e7b37af`.
- Runtime SHA-256: `946ca115334e3bf79c2fa9045bdd97423e653e618bd7947d56c5b69fdc6ac3de`.

## Evidence and boundaries

[Encoded measurements](../../../../output/qa/rc-018/audio-validation.json), [Godot playback](../../../../output/audio/rc-018/godot-playback.json), [cue catalogue](../../../../docs/audio-cue-catalogue.json) and [full audition](../../../../output/audio/rc-018/index.html). Sources are excluded from shipped assets. Import settings preserve uncompressed PCM without normalization, trim or resampling.

The MP3 origin is retained honestly; 24-bit working-master format does not restore lost fidelity. Exact service prompts and returned metadata are recorded; no model seed is invented. The owner approved the five-cue direction; full-library listening and final mix acceptance remain open. No agent headphone/speaker review is claimed.
