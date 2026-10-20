# RC-019 crypt ambience audition

Open [index.html](index.html) to compare the crypt ambience runtime loop, its working master and the original generated source. RC-019 remains incomplete: the owner explicitly chose to leave both music loops pending after Runway music generation required a paid plan.

## Sources and controls

- [Runtime Ogg](../../../assets/audio/ambience/crypt.ogg)
- [Working master WAV](../../../source-assets/audio/ambience/crypt/crypt.wav)
- [Original generated MP3](../../../source-assets/audio/ambience/crypt/originals/crypt.mp3)

The original provider output is a 30-second lossy MP3. PCM working-master encoding does not recover missing source fidelity. The delivered loop is 57.999833333 seconds: 2,783,992 stereo frames at 48 kHz, starting at frame 0 with the end excluded. It repeats the same edited 28.999916667-second source cycle twice and adds no new generated variation.

The working master is stereo 48 kHz/24-bit PCM WAV. The runtime is stereo 48 kHz Ogg Vorbis, 819,769 bytes, averaging 113.071911 kbps including its container. The renderer estimates the runtime at −25.95576 LUFS and −10.84290 dBTP; these implementation estimates do not establish perceived balance or audible seam quality.

One native audio element handles every source, so comparisons cannot overlap. Selecting another source stops playback and waits for a new Play action. Stop resets the selected file. Shared review volume starts at 50% and stays synchronized with the native volume control. No extra loudness matching or gameplay mixer gains are applied; the raw original may differ in level and duration from the edited exports.

Repeat selected clip starts enabled for the runtime loop. It is a native-browser audition option, not a claim about production-engine timing. The [six-cycle seam review](crypt-five-joins.wav) provides **five internal joins** in one 347.999-second PCM16 stereo 48 kHz WAV, decoded from the exported runtime Ogg. Its selector plays the full file or starts two seconds before any join. The [10-second seam excerpt](crypt-seam-ten-seconds.wav) is a shorter review of one boundary. Repeat is disabled for both review files.

| Join | Boundary time | Selector start |
| --- | ---: | ---: |
| 1 | 57.999833 s | 55.999833 s |
| 2 | 115.999667 s | 113.999667 s |
| 3 | 173.999500 s | 171.999500 s |
| 4 | 231.999333 s | 229.999333 s |
| 5 | 289.999167 s | 287.999167 s |

## Readiness

The delivered ambience passed 437 independent technical checks with zero failures; the validation report's runtime hash matches the current export. Native playback controls and numerical checks do not establish a clean audible loop. Headphone and ordinary-speaker review across all five boundaries, repeated-loop comfort, final music/SFX balance, production integration and physical-device behavior remain unreviewed.

The two planned music slots are Home/exploration and combat. Both remain pending with no files or playback controls. No silent tracks, fake placeholders or substitute music have been introduced.

This is an isolated review artifact. RC-020 owns production audio playback/settings. The RC-018 preview and its assets are unchanged.

- [Loop catalogue](../../../docs/audio-loop-catalogue.json)
- [Source delivery](../../../source-assets/audio/ambience/crypt/delivery.md)
- [Generation and edit report](../../../source-assets/audio/loop-generation-report.json)
- [Technical validation](../../qa/rc-019/audio-loop-validation.json)
- [Verification notes](../../../docs/rc-019-verification.md)
