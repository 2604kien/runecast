# RC-019 music - pending by owner choice

The requested Home/exploration and combat tracks remain pending. Runway returned `paid_plan_required` when Home music generation was attempted, without creating a generation task. The owner explicitly chose **Leave music pending**. No combat request was submitted, no subscription was changed, and no music source or runtime audio is supplied.

[requests.json](requests.json) preserves the prepared prompts and exact blocked Home request. When the owner resumes music production with access available, use Runway to produce two related, restrained fantasy/crypt instrumentals, retaining originals and generation metadata before editing.

| Track | Planned runtime | Delivery contract |
| --- | --- | --- |
| Home/exploration | `assets/audio/music/home_exploration.ogg` | 60–120 s, 48 kHz stereo Vorbis, target 160–192 kb/s |
| Combat | `assets/audio/music/combat.ogg` | Same; all fights including guardian reuse it |

Each needs a 48 kHz stereo 24-bit PCM working master, editable loop settings and exact sample points, documented source/rights, measured -18 LUFS ±2 and estimated true peak at most -2 dBTP, codec import/playback verification, and five seam repeats heard on headphones and ordinary speakers. MP3-origin fidelity must be disclosed if the provider returns MP3.

Home music is reused across exploration, services, rewards and collection; Menu preserves the current music. RC-020 owns 0.4–0.8 s transitions between at most two music streams, independent ambience fading, persistent settings, lifecycle cancellation and interruption behavior. No third music track is planned.
