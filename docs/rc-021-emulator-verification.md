# RC-021 — Android emulator verification addendum

October 19, 2026 (Australia/Sydney). **The original arm64 debug APK installed and ran on the Android 16 emulator. Physical-device acceptance remains open.** This addendum records emulator execution after the original [RC-021 verification](rc-021-verification.md), whose historical statement that no emulator was used no longer describes the current coverage.

## Tested environment and APK

| Item | Recorded identity |
| --- | --- |
| Android Emulator | 37.2.12, build 16428233; official Windows x64 archive |
| System image | `system-images;android-36;google_apis;x86_64`, revision 7; Android 16 / API 36 |
| AVD / serial | `RuneCast_API36` / `emulator-5554` |
| Display / resources | 720×1600, density 320; 4 cores, 4096 MiB RAM; navigation mode value 2 |
| Acceleration / graphics | WHPX 10.0.26200; host rendering, NVIDIA GeForce RTX 5070 Ti; GLES dynamic version enabled |
| ABI | Image exposes `x86_64,arm64-v8a`; native bridge `libndk_translation.so`, Berberis 16.0.0 |
| Capture tooling | scrcpy 5.0.1; official release archive SHA-256 verified |
| Original APK | 38,455,179 bytes; SHA-256 `06e69cc92a6ecbdda334d292fc87551653740627a32007e4b91ae772199978f7` |
| App | `com.example.runecast`, version 0.1.0 / code 1; arm64-v8a; min API 24, target API 36; Godot 4.7.2 Compatibility |

The original APK was installed unchanged with `adb install -r` and launched through its exported launcher alias. Its superseded binary, subsequently named `RuneCast-pre-emulator-debug.apk`, was removed in the [owner-requested cleanup](../output/qa/rc-021/unused-emulator-cleanup.json); its hash and evidence remain. Installation and production Combat succeeded; the duplicated provider-authority metadata did not block this emulator's installation/startup. Evidence: [setup](../output/qa/rc-021/emulator/setup.json), [device](../output/qa/rc-021/emulator/api36/device.json), [original install](../output/qa/rc-021/emulator/api36/install.json), [launch](../output/qa/rc-021/emulator/api36/launch-verification.json), [opening](../output/qa/rc-021/emulator/screenshots/api36-opening.png).

## Observed gameplay and defect

Inputs were injected through ADB and results checked in captured emulator screens. These are synthetic Android interactions, not physical touch observations.

- **Editing and inspection:** placement, occupied-cell selection, Rotate, Remove and card inspection were exercised. Settled evidence: [reselected connector](../output/qa/rc-021/emulator/screenshots/straight-reselected.png), [removed connector](../output/qa/rc-021/emulator/screenshots/removed-settled.png), [Shield details](../output/qa/rc-021/emulator/screenshots/shield-inspector.png). The earlier `straight-rotated` and `straight-removed` captures preceded a frame update and are not used to establish those outcomes. Connector hold, pile inspection/scrolling and Guide scrolling were not tested.
- **Cast:** the completed circuit forecast 0 damage, 5 shield and 1 energy cost against an incoming 8. After Cast and a repeated tap during playback, Combat settled once at **27/30 HP, Turn 2**, with the board/hand refreshed. [Forecast](../output/qa/rc-021/emulator/screenshots/valid-shield-forecast.png), [settled result](../output/qa/rc-021/emulator/screenshots/cast-settled.png), [input sequence](../output/qa/rc-021/emulator/cast-sequence.json).
- **Pass and interruption:** visible Cancel preserved **27/30 HP, Turn 2**. A subsequent confirmed Pass was followed by Home after 150 ms and foreground resume; it settled at **15/30 HP, Turn 3**, matching one incoming 12-damage action. [Cancelled](../output/qa/rc-021/emulator/screenshots/pass-visible-cancel-verified.png), [resumed](../output/qa/rc-021/emulator/screenshots/pass-action-resumed.png), [input sequence](../output/qa/rc-021/emulator/pass-visible-sequence.json).
- **Settings:** the final recorded baseline was Music **0.51**, SFX **0.34**, both unmuted, master enabled and reduced motion enabled. Its exact bytes survived force-stop and relaunch: both files have SHA-256 `8daa78bcb991122f8eda6cb32e775fb29f3da2e134760ce8d7923b40292e78fa`. This is settings persistence, not terminated-battle saving. [Baseline](../output/qa/rc-021/emulator/settings/final-persistence-baseline-1.cfg), [after relaunch](../output/qa/rc-021/emulator/settings/final-after-relaunch-1.cfg).
- **Sleep/wake and short viewport:** emulator sleep/wake returned to usable Combat. At 720×1280 the full UI remained visible with pillarboxing; there was no overflow, so a swipe had no scrolling effect and does not establish a scrolling pass. The display was restored to 720×1600. [Wake](../output/qa/rc-021/emulator/screenshots/final-sleep-wake.png), [short portrait](../output/qa/rc-021/emulator/screenshots/final-short-portrait.png), [restored portrait](../output/qa/rc-021/emulator/screenshots/final-portrait.png).
- **Android Back defect found and retested:** one Back delivery notified the same scene twice during settled frame **85354**, first closing an inspector and then opening Menu. A diagnostic APK captured this directly. The source fix accepts one Back notification per process frame, allowing a new Back on the next frame without a timed cooldown. The corrected `e4fb4620…` APK passed emulator checks for Pass cancellation to Combat, Options → Menu and subsequent Back → Combat. [Trace](../output/qa/rc-021/emulator/back-diagnostic/settled-back-trace.txt), [Pass cancelled](../output/qa/rc-021/emulator/screenshots/fixed-pass-back-01.png), [Options → Menu](../output/qa/rc-021/emulator/screenshots/fixed-options-back-01.png), [Menu → Combat](../output/qa/rc-021/emulator/screenshots/fixed-menu-back-close-01.png).
- **Native-touch slider defect found:** a first slider touch in the native Options window could fail before mouse ownership was established. A focused Godot touch reproduction had **4 failures among 7 checks before**, then **zero failures after** the native ownership fix in [TouchRouter](../scripts/ui/touch_router.gd). [Before](../output/qa/rc-021/back-fix/native-touch-before.log), [after](../output/qa/rc-021/back-fix/native-touch-after.log). The full [UI suite](../output/qa/rc-021/back-fix/ui-smoke-native-touch.log) now passes **1,171 checks**. Final APK verification containing both fixes is pending below.

The diagnostic APK was used to investigate Back and is not the original unchanged-APK result. Rebuilding and retesting the production APK are tracked separately below.

## Captured audio and video

[gameplay.mkv](../output/qa/rc-021/emulator/gameplay.mkv) is **60.005 seconds**, with 720×1600 H.264 video and 48 kHz stereo Opus audio. Offline decoding succeeded for all **1,723 video frames** and **2,994 audio frames**. Decoded audio contains 5,744,160 nonzero samples; peak −42.05 dBFS and RMS −56.25 dBFS. [Media inspection and SHA-256](../output/qa/rc-021/emulator/record-info.json).

Separate PCM recordings establish captured signal and digital silence for the tested settings:

| Capture | Duration | Nonzero samples | RMS / peak |
| --- | ---: | ---: | --- |
| Enabled | 4.160 s | 391,968 | −56.56 / −44.07 dBFS |
| Music muted, idle | 4.053 s | 0 | Digital silence |
| SFX only | 7.211 s | 13,556 | −92.48 / −55.50 dBFS |
| Both muted | 7.232 s | 0 | Digital silence |
| Master Sound off | 4.053 s | 0 | Digital silence |

All five captures are 48 kHz, stereo, 16-bit PCM. [Comparison, hashes and per-second statistics](../output/qa/rc-021/emulator/audio-comparison.json). Nonzero output was low level; no human listening, cue-quality or final-mix acceptance is claimed. RC-019 music content and RC-020 final music/full-mix acceptance remain pending.

## Emulator limitations and configuration outcome

The API 30 Google APIs x86_64 image installed the arm64 APK, but initially exposed only GLES 2. Enabling `-feature GLESDynamicVersion` exposed GLES 3. Its SwiftShader run then reported fragment-uniform limits and native-translation `Undefined instruction 0x5ea1b842` / SIGILL. These failures are retained as unsuccessful emulator configurations, not physical-device findings. [API 30 log](../output/qa/rc-021/emulator/api30-attempt/app-logcat.txt).

API 36 revision 7 with host graphics and the newer ARM64 bridge successfully ran the same original APK. The scoped setup is reproducible through [android-emulator.ps1](../tools/android-emulator.ps1); archive URLs and verified hashes are in [setup evidence](../output/qa/rc-021/emulator/setup.json). This does not establish phone performance, thermal behavior, latency, touch feel, cutouts, hardware audio or complete lifecycle acceptance. Every physical-device gate remains open; the owner has no physical Android device available.

## Final production APK verification

The Back-fix candidate `RuneCast-verified-debug.apk` is **38,455,179 bytes**, SHA-256 `e4fb46201764b8444a7983d6ddca3a4459e7af013a82bdf80561f7cab50b1e18`. It passed 376 package checks, 46 exact-payload resource checks and the emulator Back checks above. [Build evidence](../output/qa/rc-021/emulator/verified-build/build.json). It predates the subsequent native-touch slider fix.

The delivered [RuneCast-debug.apk](../builds/android/RuneCast-debug.apk) contains both fixes: **38,455,179 bytes**, SHA-256 **`b9d8c7d26cb8b930d3c692edc9b35d18f16b69213d3dd1cc4f58f02d16b8f9e4`**. It passed **376 package checks, 46 exact-payload desktop decode checks, signature verification and alignment checks**. [Final build](../output/qa/rc-021/emulator/final-build/build.json), [package audit](../output/qa/rc-021/emulator/final-build/package-contents.json). The owner-requested cleanup removed superseded original, repeat, diagnostic and intermediate APKs, their obsolete signature sidecars, the unused API 30 emulator/image/archive and disposable SDK extraction folders. The current APK, API 36 emulator and app data, build toolchain and all QA evidence remain. [Cleanup record](../output/qa/rc-021/unused-emulator-cleanup.json).

The final APK was installed with the same signer and verified on `RuneCast_API36`:

- First Music touch immediately after opening Options changed it to **25%**. After a captured toggle, the first SFX touch changed it to **62%**. [Music](../output/qa/rc-021/emulator/screenshots/delivery-first-music-touch.png), [SFX](../output/qa/rc-021/emulator/screenshots/delivery-first-sfx-touch.png).
- Android Back dismissed the inspector and Pass without opening Menu or committing a turn; Options returned to Menu and a further Back resumed Combat. [Pass](../output/qa/rc-021/emulator/screenshots/delivery-pass-back.png), [inspector](../output/qa/rc-021/emulator/screenshots/delivery-inspector-back.png), [Options](../output/qa/rc-021/emulator/screenshots/delivery-options-back.png), [recorded inputs](../output/qa/rc-021/emulator/delivery-input-sequence.json).
- The shield circuit was repeated on this APK: **5 shield / 1 cost**, followed by **27 HP / Turn 2** despite a repeated Cast tap. [Forecast](../output/qa/rc-021/emulator/screenshots/delivery-cast-forecast.png), [result](../output/qa/rc-021/emulator/screenshots/delivery-cast-result.png).
- A second `install -r` of the same final APK preserved the exact settings bytes: SHA-256 `443c168d7d65de8ebb688a2634fa2b2fddd1c3de5a703fbe183dca4795af3db7`. [Before](../output/qa/rc-021/emulator/settings/delivery-settings-1.cfg), [after](../output/qa/rc-021/emulator/settings/delivery-after-repeat-install-1.cfg), [repeat install](../output/qa/rc-021/emulator/delivery-repeat-install/install.json).

[Final installed APK identity](../output/qa/rc-021/emulator/delivery/install.json), [device diagnostics](../output/qa/rc-021/emulator/delivery/device.json), [app-scoped log](../output/qa/rc-021/emulator/delivery/full-current-app-log.txt), [final Combat capture](../output/qa/rc-021/emulator/screenshots/delivery-final-combat.png). Earlier sleep/wake evidence contains a transient `EGL_BAD_SURFACE` while the screen turned off; the reviewed wake capture and subsequent interaction recovered. This is not a physical lifecycle or performance sign-off.

Final startup logs contain an Android ashmem deprecation, surface synchronization timeouts and a cached-shader load warning followed by recompilation. Startup and rendering recovered; no final-run fatal signal, script exception or missing-resource error was observed. These warnings remain in the retained log rather than being labelled a clean log or proof of phone performance.

Evidence naming caveat: only `fixed-*-01` screenshots establish the earlier Back-only candidate result. Unsuffixed `fixed-*` captures followed an offline-ADB install failure. The current combined APK uses the separate `delivery-*` evidence above. Physical-device acceptance remains open; no Git operations were performed during this emulator follow-up.

## Official sources

- [Android Emulator acceleration](https://developer.android.com/studio/run/emulator-acceleration) and [command-line configuration](https://developer.android.com/studio/run/emulator-commandline).
- [ARM translation announcement](https://android-developers.googleblog.com/2020/03/run-arm-apps-on-android-emulator.html) and [emulator release notes](https://developer.android.com/studio/releases/emulator).
- [Official API 36 revision 7 image](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-36_r07.zip): its actual `build.prop` identifies ARM64 support, `libndk_translation.so` and Berberis 16.0.0.
- [Official scrcpy 5.0.1 release](https://github.com/Genymobile/scrcpy/releases/tag/v5.0.1).
