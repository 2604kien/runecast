# RC-018 r003 Runway source library

The owner approved the five r002 audition sounds and requested the full sound-effect library in that direction. This revision retains those five exact MP3 originals and generates the other sixteen through Runway. All 21 source recordings are in `originals/`; no music or ambience is included.

[generation.json](generation.json) records every exact prompt, requested duration, returned duration/codec/options/model metadata, generation date, task/artifact identity, original byte count and SHA-256. `reused_from_r002` identifies the five approved examples. The service did not return a seed. Stored local dither seeds belong to PCM quantization and must not be represented as generation seeds.

[Editable processing settings](../../runway-settings.json), [renderer](../../render_runway_sfx.py) and the [render report](../../runway-generation-report.json) define every trim, fade, resample, level adjustment and shared enemy layer. The pinned Godot decoder produces floating-point intermediates; NumPy exports 48 kHz mono 24-bit working masters and 16-bit runtime WAVs to the unchanged manifest destinations. The retained MP3s allow later editing without downloading or generating again.

**The provider originals are MP3, not lossless recordings.** Floating-point intermediates and 24-bit working masters prevent unnecessary precision loss in subsequent processing; they cannot restore information discarded by MP3 encoding. Local export is reproducible from the saved sources and settings. A fresh service generation is not claimed to reproduce the same sound.

Runway's [Terms §4.4](https://runway.com/terms-of-use) do not claim output ownership or restrict commercial use, subject to the agreement. Its [commercial-use guidance](https://help.runwayml.com/hc/en-us/articles/21668707517587-Can-I-use-the-content-I-made-in-Runway-for-commercial-purposes) does not require credit. The public terms were reviewed October 17, 2026; no sound-effect-specific exception was identified, and account-specific supplemental terms were not independently inspected. The [current provenance](../../provenance.json) retains those boundaries; RC-050 owns final distribution review.

The user approved the r002 direction. Listening acceptance of all final edited cues, perceived balance, and the eventual music/SFX mix remain separate from automated validation. No agent headphone, speaker or physical-device listening is claimed.

Use the [current full audition](../../../../../output/audio/rc-018/index.html), [cue catalogue](../../../../../docs/audio-cue-catalogue.json) and [verification](../../../../../docs/rc-018-verification.md) for the finished delivery. Production buses, event synchronization and replacement of the main-scene tone remain RC-020 work.
