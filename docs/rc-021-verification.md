# RC-021 — Android debug build; physical acceptance open

October 19, 2026 (Australia/Sydney). **Partial: the Android build and emulator path are delivered; physical acceptance remains open.** The owner explicitly answered “No physical Android device is available.” The subsequent [emulator verification addendum](rc-021-emulator-verification.md) records actual Android 16 installation, gameplay, captured audio, lifecycle checks and fixes. The original build evidence below remains historical; emulator results are not phone observations or human listening feedback.

## Original APK and build evidence

- Historical build: `RuneCast-pre-emulator-debug.apk`; this superseded binary was removed in the [owner-requested cleanup](../output/qa/rc-021/unused-emulator-cleanup.json), with its hash and test evidence retained. The current [RuneCast-debug.apk](../builds/android/RuneCast-debug.apk) includes the emulator-reproduced input fixes; its hash and tests are in the [addendum](rc-021-emulator-verification.md).
- **38,455,179 bytes** (36.67 MiB).
- **SHA-256:** `06e69cc92a6ecbdda334d292fc87551653740627a32007e4b91ae772199978f7`.
- `com.example.runecast`, version name **0.1.0**, code **1**; **arm64-v8a** only.
- Debuggable, one local Android Debug signer, RSA 2048; APK signature schemes **v2 and v3 verified**. No release signing. Public certificate digest is in [signature evidence](../output/qa/rc-021/apk-signature.txt); private signing material/credentials are outside the repository.
- **No requested Android permissions.** The template's profile-installer receiver requires its caller to hold Android's DUMP permission; that is not a permission requested by this app.
- Actual template manifest: **min SDK 24**, **target SDK 36**, compile SDK 36; portrait, OpenGL ES 3.0 requirement, `gl_compatibility` rendering metadata. The launcher is an exported `com.godot.game.GodotAppLauncher` activity alias targeting the non-exported `GodotApp` activity.

The technical API floor does not establish a supported minimum phone. No ABI was added, renderer changed, final publisher selected, release key configured or store/iOS work performed. System bars/cutouts and real renderer behavior require a physical target.

[Build manifest](../output/qa/rc-021/build.json) · [Manifest tree](../output/qa/rc-021/apk-manifest.txt) · [Package/version/ABI](../output/qa/rc-021/apk-badging.txt) · [Permissions](../output/qa/rc-021/apk-permissions.txt) · [16 KiB library/ZIP alignment](../output/qa/rc-021/apk-alignment.txt)

One upstream manifest detail is retained for the first device run: the official exporter assigns the same `com.example.runecast.fileprovider` authority to both its FileProvider and AndroidX Startup provider. [Godot's pinned exporter](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/export/export_plugin.cpp#L1282-L1284) rewrites provider authorities this way. [AOSP's provider registration](https://android.googlesource.com/platform/frameworks/base/+/dda790354c866877613d550afe7bb27e02fe35f7/services/core/java/com/android/server/pm/resolution/ComponentResolver.java) distinguishes cross-package conflicts from repeated authorities within the same package, so this alone does not establish an installation failure. [Manifest summary](../output/qa/rc-021/apk-manifest-summary.json) records it. RC-021's first device check should inspect startup/provider diagnostics; retain upstream ownership unless an actual failure requires a scoped workaround. No template rewriting or custom Gradle build was introduced.

## Toolchain and first-time preparation

The actual installed engine is **Godot 4.7.2.stable.official.ed1daf0bf**, Standard/GDScript. The `_sc_` marker activates self-contained mode. Settings are `.tools/godot/4.7.2/editor_data/editor_settings-4.7.tres`; templates are installed under that same `editor_data/export_templates/4.7.2.stable`, not a global Godot directory.

| Component | Actual selected version / location |
| --- | --- |
| Official templates | 4.7.2.stable; Standard archive SHA-512 verified; Android template digest rechecked on repeat builds |
| Java | Eclipse Temurin OpenJDK 17.0.20.1+1, `.tools/android/jdk/jdk-17.0.20.1+1` |
| Android SDK | `.tools/android/sdk` |
| Build Tools | 35.0.1; aapt, zipalign and apksigner used |
| SDK Platform | Android 35, revision 2; installed tooling platform is distinct from template target SDK 36 |
| Platform Tools | 37.0.1-15733141, ADB 1.0.41 |
| SDK command-line tools | 23.0 inspected during discovery; its sdkmanager compatibility wrapper failed package-name translation. Task-created installation/stage/archive removed after verification; final bootstrap/build does not require it |
| Debug signing | Existing external profile retained between builds; generated key/profile under local AppData `RuneCast/Android`, never embedded or logged |
| Package audit | Python 3 standard library; host executable supplied explicitly in commands below |

[Toolchain evidence](../output/qa/rc-021/toolchain.json), [pinned URLs/checksums](../tools/android-toolchain.json), [Google SDK archive evidence](../output/qa/rc-021/sdk-build-downloads.json). No compatible Java/SDK installation was found in PATH, environment variables or searched conventional local installations before the scoped setup. Official archives were downloaded with network access and verified. No system-wide PATH/environment setting was changed.

Only Android templates, JDK and required SDK components are used. No Gradle build, NDK/CMake, plugin or new native dependency was added. The SDK 23.0 wrapper attempt is retained in [sdk-install.log](../output/qa/rc-021/sdk-install.log); its zero exit despite missing packages was not treated as successful installation. The final bootstrap extracts Google's pinned verified component archives and validation checks the real files and component metadata.

The unused, task-created SDK-manager installation/stage/archive were removed after checking their exact paths remained under `.tools/android` and contained no reparse points. [Cleanup record](../output/qa/rc-021/unused-sdk-manager-cleanup.json). The working SDK components, verified archives used by bootstrap and all signing material were retained. A final [credential hygiene check](../output/qa/rc-021/signing-hygiene.json) found no generated debug password in the reviewed logs/docs/tools or any APK entry.

First-time setup:

```powershell
.\tools\bootstrap-godot.ps1
.\tools\godot.ps1 -Action import -LogDirectory output/qa/rc-021/first-import
.\tools\bootstrap-android.ps1 -InitializeDebugSigning -SigningProfile C:\Users\nguye\AppData\Local\RuneCast\Android\debug-signing.json
```

The bootstrap-android invocation was executed successfully after dependency downloads. It retained/reused the verified archives and installed scoped components, extracted matching templates and initialized the external debug signer. The editor and settings already existed on this host; the initial import above is required on a fresh checkout to create portable editor settings before validation. The existing `tools/godot.ps1` was not modified.

## Exact build and inspection commands

From `C:\Dev\RuneCast`, the successful repeat-build helper invocation was:

```powershell
.\tools\android.ps1 -Action build -SigningProfile C:\Users\nguye\AppData\Local\RuneCast\Android\debug-signing.json -PythonBin C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe
```

The helper configures the portable editor paths and process-only signing variables privately, isolates user-data paths, then invokes:

```powershell
& .tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Dev\RuneCast --editor --import --log-file C:\Dev\RuneCast\output\qa\rc-021\import-engine.log
& .tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Dev\RuneCast --export-debug Android C:\Dev\RuneCast\builds\android\RuneCast-debug.apk --log-file C:\Dev\RuneCast\output\qa\rc-021\export-engine.log
& .tools/android/sdk/build-tools/35.0.1/aapt.exe dump badging builds/android/RuneCast-debug.apk
& .tools/android/sdk/build-tools/35.0.1/aapt.exe dump permissions builds/android/RuneCast-debug.apk
& .tools/android/sdk/build-tools/35.0.1/aapt.exe dump xmltree builds/android/RuneCast-debug.apk AndroidManifest.xml
& .tools/android/sdk/build-tools/35.0.1/apksigner.bat verify --verbose --print-certs builds/android/RuneCast-debug.apk
& .tools/android/sdk/build-tools/35.0.1/zipalign.exe -c -P 16 -v 4 builds/android/RuneCast-debug.apk
```

The standalone inspection commands require the selected Java directory as `JAVA_HOME`; the helper manages/restores it. Its resource audit writes `package-contents.json` and an exact APK payload ZIP, then runs `tools/verify_android_resources.gd` against that ZIP with a new empty project directory and isolated user data. This prevents the probe succeeding by falling back to workspace assets or documentation.

A second complete build used the same command plus `-ApkPath builds/android/RuneCast-debug-repeat.apk -LogDirectory output/qa/rc-021/repeat` and passed the same package/decode checks. All **434 archive entry payloads were byte-identical** to the original APK, subsequently named `RuneCast-pre-emulator-debug.apk`. ZIP timestamps changed, producing repeat SHA-256 `29f2421a75bd867d094f1634622c9c6a785c18ab8a344f3c8858d50b3848f078`; the signed APK is therefore not claimed byte-for-byte deterministic. [Repeat comparison](../output/qa/rc-021/repeat-comparison.json), [repeat build](../output/qa/rc-021/repeat/build.json). Both historical binaries were removed in the owner-requested cleanup; their hashes and comparison evidence remain. Later fixes produce the current primary APK.

The first export identified the missing `textures/vram_compression/import_etc2_astc=true` setting; [initial error](../output/qa/rc-021/initial-export/export-engine.log). It is now enabled, with the renderer unchanged. A later sandbox export stalled on Windows safe-save failures; [retained log](../output/qa/rc-021/sandbox-export/export-engine.log). Only the stalled exporter processes were stopped, then the same command succeeded with ordinary local filesystem access. No antivirus or engine safeguard was disabled. Final import/export/probe logs have no script/resource errors. The exporter reports using Build Tools 35.0.1 when it finds no version matching target SDK 36; signing, APK audit and alignment subsequently pass. No engine/template mismatch was bypassed.

## Executed validation

| Evidence type | Result and limits |
| --- | --- |
| Actual APK static resource inspection | **376 checks, zero failures**. [Report](../output/qa/rc-021/package-contents.json), [console](../output/qa/rc-021/package-audit-console.txt). 336 Godot payload entries, actual archive CRCs/remaps/hashes and arm64 library checked. |
| Desktop decoding of exact APK payload | **46 checks, zero failures**. [Log](../output/qa/rc-021/apk-resource-probe.log). Production scene instantiates with no startup error; all 21 WAV imports decode; font/textures/resources load; compressed crypt has loop enabled at offset zero and the production coordinator selects it. This does not execute Android native code or establish audible output. |
| Current UI/input regressions | **1,163 checks, zero failures**, including 15 new pause/Back cases. [Log](../output/qa/rc-021/runtime-ui/smoke.log). Synthetic desktop notifications and pointer events. |
| Authored desktop examples | **160 checks, zero failures**. [Log](../output/qa/rc-021/board-examples.log). Existing example modes remain usable after removing their unconditional preload. |
| Pause defect reproduction | Before: one stale hold fired and one pointer remained after pause-only interruption; after: both zero. [Before](../output/qa/rc-021/pause-gesture-before.log), [after](../output/qa/rc-021/pause-gesture-after.log), [probe](../output/qa/rc-021/pause-gesture-probe.gd). |
| Helper checks | PowerShell parse passes; actual toolchain validation passes. Missing SDK returns 2 and absent/unspecified target returns 5 via `pwsh -File`. No attempted destructive fallback. Independent helper review found no remaining blocker. |
| Verifier self-test | Positive fixture passes; missing imported audio and injected docs are rejected. [Self-test](../output/qa/rc-021/verifier-self-test.json). Fixture evidence is separate from actual APK inspection. |
| Authorized-device discovery | Empty list. [ADB evidence](../output/qa/rc-021/adb-devices.log). Owner independently confirmed no phone available. |
| Physical install / launch / observations | **Untested.** No physical model, OS, ABI, display, navigation mode or renderer observed. Emulator screenshots, recordings and app logs are recorded separately in the addendum. |

The actual package contains the eight production JSON definitions, Noto Serif imported font and both attribution/licence files, live textures/shaders/UI resources, Shadeling attachments/motion and shipped audio catalogue/coordinator/settings code. `assets/ui/combat/reference/approved-atlas.png`, `status-frame.png`, icons and active shaders remain included. All 21 current SFX and compressed crypt are present. Remapped imported WAVs/textures/fonts and compiled GDScript are expected export forms; original source extensions need not appear as standalone payload bytes.

Documentation JSON, tools, tests, source masters, raw generations, captures, SDKs and development fixture data/scripts are absent. Production startup is verified with those files unavailable. Both music entries remain unavailable with empty loadable paths; no substitute or silent asset was added. RC-019 remains incomplete and RC-020 final music/full-mix acceptance remains pending.

## Scoped changes

- Added bootstrap, locked toolchain metadata, Android build/device helper and APK/resource verifiers. Existing engine launcher interface is preserved.
- Narrowed only Android's data/exclusion policy; existing live reference artwork is retained. Development board example code now loads only for an explicit desktop example request.
- Enabled Android texture imports, preserving portrait 720×1600 / preview 450×1000 and Compatibility.
- Android Back uses existing close/cancel/resume actions, then selection clearing or Menu. It never confirms an action or quits. Options returns to Menu; native modal touch ownership is released before hiding.
- Application pause drops stale touches even without focus loss. Current UI overrides, gameplay rules, RC-017 pacing and audio mix are unchanged. No speculative safe-area redesign was made.

## Remaining physical acceptance matrix

Every row is **untested on a physical device**. RC-021 owns the first pass; RC-044/RC-047–RC-049 broaden accessibility, lifecycle and supported-device acceptance. Record the APK hash, date, device identity and observation method beside every result. Separate automated ADB gestures, directly observed visuals and owner-reported listening/touch feedback.

| Group | Cases required before RC-021 closure |
| --- | --- |
| Device/install | Model, Android/API, ABI, dimensions/density, navigation mode, renderer. Install this exact APK; launch its exported launcher alias. Repeat `install -r` using the same signer and verify settings survive. Never uninstall/clear data to force success. |
| Board/actions | Select, place, Rotate, Remove; supported hand-card/connector/pile inspection (board-slot and forecast inspection are intentionally absent); Cast, Pass cancel/confirm and rapid repeated inputs. |
| Scrolling/modals | Page/hand scrolling without accidental actions; Menu/Options sliders/toggles; reachable Close and dismissals; Android Back across modals, selection, Menu and action playback without stuck input. |
| Layout | Font/card/pile/counter/forecast readability, aligned touches, portrait orientation, system/status/navigation bars, cutouts, safe areas, short/tall screens, complete character/lantern and unclipped effects. No desktop capture substitutes for these checks. |
| Audio/settings | Hear current SFX and crypt; master Sound and independent Music/SFX controls; crypt follows Music while music assets stay unavailable; relaunch/update persistence; reduced-motion policy; no duplicated loop, stale cue or missing-resource spam. Preserve current mix unless an observed defect warrants a documented change. |
| Lifecycle | Idle/action background→foreground, lock→unlock and interruption; responsive resume, no stale gesture, stuck presentation, queued burst or repeated player creation; correct audio pause/resume. Terminated battles are not saved. |
| Evidence | Representative device screenshots and UID-filtered game logs. A short recording if available, labelled for what it proves; recordings without captured app audio do not prove listening. |

Ready commands once a phone is available (not executed here):

```powershell
.\tools\android.ps1 -Action devices
.\tools\android.ps1 -Action install -Device SERIAL
.\tools\android.ps1 -Action launch -Device SERIAL
.\tools\android.ps1 -Action diagnostics -Device SERIAL
```

The install helper issues `adb -s SERIAL install -r <APK>`; it never uninstalls, clears data, downgrades or overwrites a different signer. Resolve a signing conflict using the original external key; otherwise preserve the installed app and deliberately prepare a separate development identity. Device settings are not a battle-save system. `settings.cfg` persistence cannot establish terminated-run restoration.

The emulator follow-up records Android input defects and their verification separately. Missing physical acceptance remains an RC-021 gate. Independent next tasks are **RC-024, RC-024A and RC-033**; RC-022 needs Mac/Xcode/iOS access and RC-023 retains its human/device gate.

## Official references consulted

- [Godot 4.7 Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) — JDK17, SDK35 export-tool requirements and signing environment overrides.
- [Godot 4.7 Android exporter options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html) — prebuilt/Gradle distinction and development options.
- [Godot 4.7 data/portable paths](https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html) and [official 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) — exact self-contained template placement and downloads.
- [Godot Back handling](https://docs.godotengine.org/en/4.7/tutorials/inputs/handling_quit_requests.html), [notifications](https://docs.godotengine.org/en/4.7/classes/class_node.html), [display safe area](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area) — mobile behavior and pending device checks.
- [Android platform tools](https://developer.android.com/tools/releases/platform-tools), [SDK manager](https://developer.android.com/tools/sdkmanager), [hardware setup](https://developer.android.com/studio/run/device), [official SDK package metadata](https://dl.google.com/android/repository/repository2-1.xml).

One initial read-only `git status` was mistakenly run concurrently with reading the pasted no-Git restriction and was disclosed immediately. No subsequent Git operation was performed; the owner handles Git. No applicable AGENTS.md was found in the repository or its ancestors.
