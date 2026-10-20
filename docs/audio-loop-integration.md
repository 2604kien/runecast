# Loop playback and remaining music handoff

## October 18, 2026 — Implemented with available assets

The scene-owned [coordinator](../scripts/audio/audio_coordinator.gd) now starts the delivered `crypt` Ogg in ordinary Combat, routes `RuneCast Ambience` through `RuneCast Music`, and preserves the player and position through Menu, Options, refreshes, turns and compatible contexts. Home never selects crypt automatically. One independently fading ambience player and two fixed music slots enforce the bounded player policy. The imported `AudioStreamOggVorbis` remains compressed and retains its full-file loop flag and zero offset; production does not predecode long streams into PCM.

`set_context(context, crypt)` resolves only available entries from the shipped [catalogue](../scripts/audio/audio_catalogue.gd). Both music entries remain `pending_source` with unavailable runtime metadata, so every current music selection is a valid silent music state without loading nonexistent paths or creating placeholder assets. The 0.6-second transition mechanism is implemented within the documented 0.4–0.8-second range. Its structural/fade tests use clearly isolated test-only streams; production music looping, crossfades and the full mix cannot be accepted until RC-019 delivers both tracks.

Fades advance in the coordinator without retained timer/tween completions. Context replacement retargets the current envelopes; teardown closes the owner and stops all players. Focus loss/suspension and Music/master mute pause compatible loops and preserve their position, while obsolete SFX batches are consumed. Resume/unmute preserves the intended context without duplicate starts or old effects. Independent persistent Music/SFX controls, legacy master migration and the reused Options surface are documented in [audio integration](audio-integration.md).

[RC-020 verification](rc-020-verification.md) records measured playable-scene SFX/ambience output, Menu continuity, loop probing and lifecycle checks. It does not claim physical headphones/speakers, five-join acoustic acceptance or mobile interruption acceptance. RC-019 remains incomplete, and the original full RC-020 task stays partial pending music and final full-mix acceptance.

### When the music is delivered

1. Complete RC-019's original/master/runtime/provenance and encoded-loop measurements for both `home_exploration` and `combat`; keep the existing exact IDs and planned paths. Hear at least five imported loop boundaries on headphones and ordinary speakers.
2. Mark only actually delivered loop entries available, fill their measured sample points/offsets, and update the available compressed-resource metadata in `audio_catalogue.gd`. Keep the documentation/shipped-catalogue parity test passing. Never enable a path while its resource is absent.
3. Run the pinned import, core/UI/audio suites and actual-scene capture. Exercise Home/exploration↔combat context changes through the two existing music slots, interruption/mute during each fade, rapid context replacement, and ambience continuity. Future screens attach through their owners; no temporary Home/shop/map gameplay is required.
4. Measure combined music/ambience/SFX headroom at full user levels and maximum allowed overlaps, then perform final listening for relative level, loop comfort, crossfade quality and important-cue clarity in both motion modes. Record any deliberate gain changes, repeat the affected checks, and only then close the original music-dependent RC-020 acceptance. Platform interruption acceptance remains with its platform/lifecycle tasks.

## Retained RC-019 source handoff

October 17, 2026. [The loop catalogue](audio-loop-catalogue.json) distinguishes delivered resources from planned paths. The owner chose to leave the two music tracks pending after Runway required a paid plan. Only crypt ambience is being supplied in this RC-019 delivery. Do not load absent Home/exploration or combat paths, substitute silence, or infer that RC-019 is complete.

The ambience uses the same quiet fantasy/crypt direction as the approved RC-018 sources: distant air and enclosed stone-room texture with restrained incidental detail. It must sit beneath material effects and future music. The [audition](../output/audio/rc-019/index.html) compares the original, working master and runtime codec, and exposes repeated joins for listening review. The [verification record](rc-019-verification.md) separates measured playback/loop evidence from pending human acceptance.

## Ownership and selection

RC-019 creates sources, masters, encoded loops, edit/loop metadata, previews and measurements. RC-020 implements production players, buses/settings, start/stop/fade/synchronization and desktop lifecycle; RC-047 owns platform interruption/resume acceptance. RC-042 binds later progression screens. RC-020 removes the old main-scene Cast tone while preserving RC-017 pacing.

Use the single `crypt` ambience resource where the active context is a crypt: current Combat and future Map/shop/recovery/event views as appropriate. Preserve its playback through compatible views; do not restart it on each UI refresh or combat event. Home does not automatically acquire a crypt bed. Resource paths marked `pending_source` are unavailable, even when their parent source directory contains prepared prompts.

When music is delivered, Home/exploration is shared by Home, Map, shop/recovery/events, rewards and collection. Combat, elite and guardian encounters reuse the combat track. These are two music files, not a separate track per actor or screen. A Menu overlay preserves the active music and position.

## Playback and lifecycle contract

- Use at most two music streams during a 0.4–0.8 s transition, plus one independently fading ambience stream. Keep loop resources compressed; do not predecode all music and ambience into full PCM buffers in production.
- Route ambience with the Music volume/mute control unless a later explicit user need justifies a separate setting. Music and SFX settings persist independently. The ambience's documented mastering level and catalogue default gain are distinct from user bus volume.
- Load each loop once per audio-owner/session identity. Back navigation, save/load, repeated scene callbacks and Menu overlays must not create additional players or restart an existing compatible loop.
- Fade and cancel obsolete playback on owner teardown or context exit. Transition callbacks must check the current scene/session generation so an old completion cannot revive a previous loop.
- Follow the delivered full-file loop points and imported Vorbis loop flag. Use explicit fade envelopes for context changes; do not add a silence gap at every loop boundary. Reduced motion does not mute or change this audio meaning.
- Suspend, device/audio interruption, focus changes and resume require RC-020/RC-047 verification. Desktop offline looping does not establish Android/iOS interruption behavior or actual device residency.

## Acceptance still required

The audio specification calls for hearing at least five loop boundaries on headphones and ordinary speakers, including after runtime codec import. A six-cycle review WAV supplies five internal joins without depending on browser repeat scheduling. Numerical seam statistics and Godot wrap counts help find problems but do not establish inaudibility, repeated-use comfort or perceived balance.

The two music tracks, their looping/transition evidence, and the final music/ambience/SFX mix remain pending. RC-019 must remain unchecked while those requested music assets are absent. The original RC-019 delivery installed no production subscription; current playback is the separate RC-020 work above. RC-019 performed no Git operation. The separate RC-020 verification discloses its one initial read-only status mistake and no subsequent Git operation.
