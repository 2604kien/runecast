# Rune Cast Godot and mobile setup

## Development baseline

Use Godot 4.7.2 Standard with GDScript and the Compatibility renderer. The pinned Windows x64 editor is installed locally by tools/bootstrap-godot.ps1. Its archive is checked against the official SHA-512 sums before extraction.

The project uses a 720 by 1600 portrait design canvas and a 450 by 1000 desktop preview. Canvas scaling preserves aspect ratio. Shorter windows can scroll the prototype controls; final safe-area behaviour remains a device-testing task.

The editor's self-contained marker keeps editor settings beside the portable executable. Runtime sound preferences use Godot's normal user data directory. Launch scripts put verification logs in output/qa.

## Windows commands

Normal `-Action run` opens the session-only Home shell. **New Run** starts the current production encounter; **Menu → Resume** leaves it unchanged. **Menu → Quit to Home** asks before discarding battle progress and retaining the exact entry checkpoint. **Continue** replays that entry in this running app only. Replacing an existing session requires confirmation. Closing the app loses run state; shared Options preferences keep their existing settings-file behavior. There is no saved-run recovery yet (RC-028).

Explicit encounter, board-example, experiment and capture arguments still open isolated Combat. `scenes/main.tscn` remains its direct test/development scene; `scenes/application.tscn` is the normal application entry. [RC-024 interfaces and verification](rc-024-verification.md) documents this boundary. No mobile toolchain or signing step is needed to try it on Windows.

```powershell
.\tools\bootstrap-godot.ps1
.\tools\godot.ps1 -Action editor
.\tools\godot.ps1 -Action run
.\tools\godot.ps1 -Action test
.\tools\godot.ps1 -Action smoke
.\tools\godot.ps1 -Action capture
```

Editor import scans are available with -Action import. An alternate editor can be supplied through GODOT_BIN. The bootstrap is Windows x64-specific; on another operating system download the matching Standard editor and import project.godot.

## Android

RC-021 supplies a local debug APK path through [tools/android.ps1](../tools/android.ps1). The preset keeps `com.example.runecast`, version **0.1.0 / code 1**, **arm64-v8a only**, portrait, GDScript and Compatibility. Production identity/signing belongs to RC-052. There is no custom Gradle build, native plugin, release signing or store setup.

### First-time Windows setup

Install the pinned editor first, then the scoped Android tools and a local debug signer:

```powershell
.\tools\bootstrap-godot.ps1
.\tools\godot.ps1 -Action import -LogDirectory output/qa/rc-021/first-import
.\tools\bootstrap-android.ps1 -InitializeDebugSigning
.\tools\android.ps1 -Action validate
```

The bootstrap uses [locked official archive URLs/checksums](../tools/android-toolchain.json): Godot **4.7.2.stable.official.ed1daf0bf**, matching **4.7.2.stable** Standard templates, Temurin JDK **17.0.20.1+1**, Android Build Tools **35.0.1**, platform **35 revision 2**, and platform-tools **37.0.1**. It extracts only Android debug/release templates and their version marker; the release template is installed but no release build/signing is configured. The simple prebuilt APK path does not need Gradle, NDK, CMake, Android Studio or command-line SDK manager. Archives are verified against official checksums before extraction. Standard Android SDK license terms apply to the downloaded SDK components.

Godot's self-contained `_sc_` marker makes the correct template location `.tools/godot/4.7.2/editor_data/export_templates/4.7.2.stable`; its settings file is `editor_data/editor_settings-4.7.tres` beside the same executable. Another Godot installation's templates/settings do not apply. Repeat validation checks the engine string, template version **and pinned Android-template hash**, JDK major version, SDK component identities and debug signer. Downloads and SDKs stay under `.tools/android`; no global PATH or environment changes are saved. Pass `-JavaSdkPath`, `-AndroidSdkPath` and `-GodotBin` explicitly to reuse compatible installations.

The exact official prebuilt template declares **minimum SDK 24 / Android 7.0**, **target SDK 36 / Android 16**, and compile SDK 36. These come from the actual APK manifest; installing platform 35 does not make it target 35. The 4.7 export guide names Build Tools 35.0.1; the exporter can use that version with this prebuilt template and logs its fallback. Gradle-only min/target fields are intentionally not used to imply a manifest override. API 24 is a technical install floor, **not an accepted minimum supported device**.

`-InitializeDebugSigning` creates a random-password local debug key and `debug-signing.json` under `%LOCALAPPDATA%\RuneCast\Android`, outside the repository, retaining any existing key/profile. Keep that directory for same-signer updates. No key, password or release identity belongs in source, export presets, evidence or APK resources. Build accepts `-SigningProfile <absolute external JSON path>`, or the complete process-only Godot environment trio `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `_USER`, `_PASSWORD`. Values are never printed and are restored after the helper exits. Do not paste profile contents into logs. This is local development signing only.

### Repeat debug builds

Python 3 is needed only for the standard-library package audit. Use a working `python` on PATH, or pass `-PythonBin` explicitly:

```powershell
.\tools\android.ps1 -Action build -PythonBin C:\Path\To\python.exe
```

Output is `builds/android/RuneCast-debug.apk`. Evidence defaults to `output/qa/rc-021`; `-LogDirectory` can select another location. The helper configures only the portable editor's Java/SDK paths and external debug-key path, imports the project including required Android ETC2/ASTC texture variants, exports, inspects signature/manifest/arm64/permissions/alignment, audits actual APK resources, and decodes those exact resources in an isolated desktop probe. The build manifest records APK size/hash and toolchain. A desktop payload probe is **not device execution**. Godot import/export and probe user data are isolated from normal player settings.

The delivered host used:

```powershell
.\tools\android.ps1 -Action build -SigningProfile C:\Users\nguye\AppData\Local\RuneCast\Android\debug-signing.json -PythonBin C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe
```

The bootstrap and repeat build are separate: no downloads or SDK upgrades occur during a repeat build. Reproducibility means a validated repeatable build process with recorded hashes; signed ZIP timestamps can vary. The existing `tools/godot.ps1` actions, parameters and `-LogDirectory` remain unchanged. Android helper exits are `0` success, `2` setup, `3` import/export, `4` package verification, `5` device/deployment, `6` diagnostics and `1` unexpected error. Run with `pwsh -NoProfile -File tools/android.ps1 ...` when a calling process needs the exact exit code.

`-Action inspect` rechecks the existing APK's manifest, signature, permissions and alignment without rebuilding; `-Action build` additionally verifies all runtime contents and decoded resources. The manifest summary records the exported launcher alias, portrait flag, renderer and the official exporter's duplicate provider-authority detail for first-device investigation. This metadata inspection does not establish device launch success.

### Scoped Windows Android emulator

[tools/android-emulator.ps1](../tools/android-emulator.ps1) installs the official Android Emulator **37.2.12** and **Android 16 / API 36 Google APIs x86_64, revision 7**, checking the pinned Google archive checksums. Its `RuneCast_API36` AVD, downloads and SDK remain under `.tools/android`; logs go to `output/qa/rc-021/emulator`. The image supplies ARM64 translation for testing the existing **arm64-only APK unchanged**. The virtual display is 720×1600 at density 320, with 4 CPU cores and 4 GiB RAM. Emulator translation and host graphics do not represent physical-phone performance. The unused API 30 image, AVD and download archive were removed during the [owner-requested cleanup](../output/qa/rc-021/unused-emulator-cleanup.json); this helper targets API 36 only.

Run the Android bootstrap above first, then:

```powershell
.\tools\android-emulator.ps1 -Action setup
.\tools\android-emulator.ps1 -Action start
.\tools\android-emulator.ps1 -Action status
.\tools\android.ps1 -Action install -Device emulator-5554 -LogDirectory output/qa/rc-021/emulator/device
.\tools\android.ps1 -Action launch -Device emulator-5554 -LogDirectory output/qa/rc-021/emulator/device
.\tools\android.ps1 -Action diagnostics -Device emulator-5554 -LogDirectory output/qa/rc-021/emulator/device
```

Start is headless by default and waits for Android boot; `-NoWait` returns after launch, and `-BootTimeoutSeconds` adjusts the default 300-second limit. On this host, acceleration uses the existing Windows Hypervisor Platform (WHPX). The helper checks acceleration, saves only process-local environment settings, and makes no Windows feature or global PATH changes.

**Keep the default host graphics and `GLESDynamicVersion` feature together.** The helper explicitly passes `-gpu host -feature GLESDynamicVersion` for the GLES 3 required by this APK; omitting the feature can leave the emulator capped at GLES 2. The `-Gpu` parameter also accepts `auto`, `software` and `swiftshader` for investigation. Those alternatives are not accepted substitutes for this configuration; runtime results belong in the verification record.

To show the emulator window, stop the current instance and start with `-Visible`; calling start on an already-running instance does not change its visibility:

```powershell
.\tools\android-emulator.ps1 -Action stop
.\tools\android-emulator.ps1 -Action start -Visible
```

Use `-Action stop` when finished. Start/stop verify both `RuneCast_API36` and its absolute workspace AVD path before operating on `emulator-5554`, preserving app/AVD data. The evidence helper [tools/android-emulator-qa.py](../tools/android-emulator-qa.py) applies the same guards before recording input, screenshots or app-only settings. Actual results and the delivered APK are recorded in the [emulator verification addendum](rc-021-emulator-verification.md); **physical-device acceptance remains open**.

### Physical install, launch and diagnostics

Connect a phone, enable USB debugging, unlock it and accept this computer's authorization prompt. Always select a serial explicitly, including when just one phone is connected:

```powershell
.\tools\android.ps1 -Action devices
.\tools\android.ps1 -Action install -Device SERIAL
.\tools\android.ps1 -Action launch -Device SERIAL
.\tools\android.ps1 -Action diagnostics -Device SERIAL
```

Installation uses `adb -s SERIAL install -r` and preserves existing app data. A different signer or a version downgrade fails without uninstalling, clearing data or forcing a downgrade. Retain the original local signer; if it is unavailable, keep that installation and establish a separately named development package through a deliberate preset/verifier adjustment. RC-052 still owns production identifiers. Launch verifies the reported activity and a live app process. Diagnostics use UID filtering where supported, otherwise current app PIDs or bounded recent exact-process exit records; they never collect unrestricted device logs or clear global logs. Godot export can restart ADB: if a deployment reports offline, wait for `devices` to show the selected target online and retry installation before testing.

On **October 19, 2026**, the owner confirmed no physical Android device is available and ADB listed none. RC-021 therefore remains partial. [The RC-021 verification record](rc-021-verification.md) contains actual build results and the remaining physical touch/layout/audio/lifecycle matrix. No emulator or desktop result closes that gate. Settings persistence is not battle saving; the future run/save systems remain unimplemented.

## iOS

RC-022 supplies [tools/ios.py](../tools/ios.py), a Python 3.10+ macOS development helper. **Mac/Xcode/signing execution remains unverified.** The owner has an iPhone 14 on iOS 18; exact OS patch, pairing/trust and Developer Mode are pending. [Verification and remaining device checks](rc-022-verification.md) separate Windows preparation from physical acceptance.

The source preset has blank team/bundle fields to prevent accidentally using `com.example.runecast` for iOS. It selects development signing, version **0.1.0 / 1**, **iPhone only**, arm64 and project-only export. **15.0** is the pinned exporter default/configured deployment floor, not an accepted minimum supported device. Portrait 720×1600, Compatibility and ETC2/ASTC imports remain unchanged. No tablet/landscape UI, release archive, IPA, TestFlight or store distribution is added. RC-052 owns final production identity.

### Source transfer from Windows without Git

Run with a working Python executable (this host's bundled Python path is recorded in the verification document):

```powershell
python tools/prepare_ios_transfer.py
```

The command creates a fresh `builds/ios/transfer-<id>/RuneCast-source.zip`, prints its SHA-256, and writes evidence under `output/qa/rc-022/transfer-<id>`. It includes project/export settings, README, runtime assets/data/scenes/scripts and tools/tests/docs needed for development verification. It excludes Git metadata, generated caches, SDKs, signing files, source masters/raw generations and previous builds/captures. Tests and tools belong in this source handoff; export filters exclude them from the app.

Copy that ZIP using an owner-approved file transfer/USB drive. On the Mac compare `shasum -a 256 /path/to/RuneCast-source.zip` with the recorded hash, extract into a **new empty** project directory, then run:

```sh
cd /path/to/RuneCast
python3 tools/prepare_ios_transfer.py --verify /path/to/RuneCast-source.zip
```

The internal file manifest verifies every copied byte and rejects extra paths. Import regenerates Mac caches. Do not copy `.git`, `.godot`, `.tools`, signing keys/profiles, the Windows editor, or the Android SDK. Copying the source is not a native iOS build.

### First-time Mac and device setup

1. Record Mac model/architecture/macOS and exact iPhone OS version. Select a full Xcode installation compatible with that Mac and device using [Apple's Xcode compatibility table](https://developer.apple.com/xcode/system-requirements). Open Xcode and let the owner accept its licence/install required platform components. Command Line Tools alone do not supply the iPhoneOS SDK. No Xcode version has been selected or tested in this Windows session.
2. Download **Godot 4.7.2 Standard for macOS** from the [official version archive](https://godotengine.org/download/archive/4.7.2-stable/), verify the official download checksum and open it once as required by macOS. The Standard Mac editor supports Intel and Apple Silicon. Do not substitute another engine version or use the Windows launcher.
3. Install matching **4.7.2.stable** export templates through that editor, or extract only `templates/version.txt` and `templates/ios.zip` from the official TPZ into a dedicated local template folder after checking its SHA-512 against [ios-toolchain.json](../tools/ios-toolchain.json). Pass that folder explicitly; the helper also verifies `ios.zip` SHA-256 `fd3280d10dc75356dded006f6f8813f40a5aebd32d128592b781256d8ffbdff4`. Android's Windows bootstrap installed only Android templates. The evidence copy of `ios.zip` inspected here was not installed into an editor.
4. The owner signs into **Xcode → Settings → Accounts**, selects their authorized development team and approves a unique development bundle identifier. Before running preflight/export, open that team's **Manage Certificates** and select an existing usable **Apple Development** identity, or have the owner create one if none exists; login alone does not establish a certificate. A [Personal Team supports testing on one's own device](https://developer.apple.com/help/account/basics/about-your-developer-account) without purchasing membership; its provisioning expires and may require renewal. No enrollment, certificate creation/revocation or account action is automated here. Keep credentials, keys and provisioning profiles in Xcode/Keychain locations outside sources and evidence.
5. Outside the project, save a small identity JSON with exactly `owner_approved`, `team_id` and `bundle_identifier`. Set the first to `true` only after the owner selects the values; Team ID is the actual 10-character code. Example structure below contains deliberately unusable markers:

```json
{"owner_approved": false, "team_id": "REPLACE_WITH_ACTUAL_TEAM", "bundle_identifier": "REPLACE_WITH_APPROVED_DEV_ID"}
```

6. Connect/unlock the iPhone, accept trust/pairing prompts and enable **Settings → Privacy & Security → Developer Mode**, restart and confirm when requested. These are owner actions. [Apple Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device). Use Xcode's Devices and Simulators window to confirm the exact phone and OS. `devicectl` device operations require iOS 17+; iOS 18 fits that CLI floor, subject to the selected Xcode. This is separate from app deployment support.

Set arguments in a Mac Terminal in the project directory (replace each path with the real installation/config):

```sh
ios_args=(--godot /Applications/Godot.app/Contents/MacOS/Godot
  --templates "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
  --identity "$HOME/Library/Application Support/RuneCast/ios-development.json"
  --developer-dir /Applications/Xcode.app/Contents/Developer)
python3 tools/ios.py devices --developer-dir /Applications/Xcode.app/Contents/Developer
python3 tools/ios.py preflight "${ios_args[@]}" --device SELECTED_DEVICE_ID
python3 tools/ios.py export "${ios_args[@]}"
```

`--developer-dir` affects only helper subprocesses; it does not change global `xcode-select`. Preflight records macOS, architecture/model, Xcode, SDK, exact editor/template hashes and development-certificate availability. No command downloads or upgrades tools. Fix the stated prerequisite and repeat if it fails; success requires checked outputs as well as command exit status.

For initial provisioning, open the fresh `builds/ios/<run>/export/RuneCast.xcodeproj` in Xcode. Select the approved team, automatic development signing, **Debug** and the connected iPhone; the owner resolves account/device registration and profile consent in Xcode. Retain any manually edited export. The repeat helper uses existing local signing material and does not pass automatic provisioning-update flags. If a profile is unavailable, preserve installed app data and finish Xcode setup before retrying.

### Repeat development builds and deployment

```sh
python3 tools/ios.py build "${ios_args[@]}"
```

Every import/export/build stages fresh sources under `builds/ios/<UTC-run-id>/source`, leaving source presets and older Xcode projects untouched. `build` imports, exports a project and PCK, audits/decodes that exact payload, invokes `xcodebuild` for Debug/iphoneos, then checks the resulting `.app` identity/version, iPhone portrait settings, arm64 executable, signature, development entitlements/profile and packaged resources. The application lives under that run's `DerivedData/Build/Products/Debug-iphoneos`. `import` and `export` are separately available milestones; neither establishes an app build.

Use the successful build's `output/qa/rc-022/<run>/workflow.json` for install. Use the successful install's receipt for launch and diagnostics:

```sh
python3 tools/ios.py install "${ios_args[@]}" --device SELECTED_DEVICE_ID --manifest output/qa/rc-022/BUILD_RUN/workflow.json
python3 tools/ios.py launch "${ios_args[@]}" --device SELECTED_DEVICE_ID --manifest output/qa/rc-022/INSTALL_RUN/workflow.json
python3 tools/ios.py diagnostics "${ios_args[@]}" --device SELECTED_DEVICE_ID --manifest output/qa/rc-022/INSTALL_RUN/workflow.json
```

`diagnostics` prepares an app-scoped console command; **it does not capture logs itself**. Run its printed command in another Terminal while exercising the phone, or use Xcode's RuneCast debug console. Retain only app-scoped diagnostics; do not run broad device/host sysdiagnose collection. Installed `xcrun devicectl ... --help` defines the actual toolchain syntax; unsupported JSON/schema fails explicitly and requires checking the selected phone in Xcode. Process creation is not proof of sustained gameplay.

To verify a same-identity update, set distinct Music/SFX values, mute/master/reduced-motion preferences, record them, close/relaunch, make another build with the same team/bundle and install it over the existing app. Confirm all values and unrelated settings remain. Do not uninstall, clear data, switch identity or revoke certificates to bypass an update failure. Preserve the failed log and resolve signing with the owner. Preference persistence does not imply battle/run saving. Repeat hashes are recorded, but byte-identical build reproducibility is not claimed.

Use the [physical acceptance matrix](rc-022-verification.md#remaining-physical-device-checks) for layout, gestures, first Options-slider touches, audio routes/silent mode, interruptions and lock/unlock. Simulator/Mac execution can supplement these observations and must be labelled separately; it cannot close RC-022 or RC-023's physical-device gate.

## Packaging boundaries

Android and iOS export explicitly include the eight production JSON files and font attribution/licence. All live textures, shaders, scenes, character attachments/motion and audio runtime code remain, including approved-atlas, status-frame and related artwork under `assets/ui/combat/reference`. A folder named `reference` is not an exclusion rule. Source masters, raw generations, docs, tools, tests, QA, SDKs and development fixtures/helpers are excluded. Desktop board examples are loaded lazily only when explicitly requested. Current 21 SFX and compressed looping crypt ambience ship; both unavailable music tracks remain unproduced and are never loaded. Documentation JSON is not a runtime dependency.

Android build evidence is distinct from physical-device acceptance. Windows iOS-preset resource export/decode is recorded, but no native iOS build/run is claimed. No platform account, analytics or backend is required for the local debug APK.

## Official references

- [Godot Windows download](https://godotengine.org/download/windows/)
- [Godot 4.7 Android export requirements](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- [Godot 4.7 Android export options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html)
- [Godot 4.7 portable editor paths](https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html)
- [Official Godot 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
- [Android platform-tools releases](https://developer.android.com/tools/releases/platform-tools)
- [Android hardware-device setup](https://developer.android.com/studio/run/device)
- [Godot iOS export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [Godot scalable UI textures](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)


## RC-005 desktop experiments

Use `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant control -Seed 42` for the development panel. Omit `-Experiment` for unchanged normal gameplay. [Circuit experiments](circuit-experiments.md) documents all scenario/variant IDs, replay versus Restart, local output and RC-006 protocol. `-Action test` and `-Action smoke` include automated experiment checks. `-CaptureStep cast|inspect` is optional with `-Action capture -Experiment` for post-cast/record-inspector evidence; the default is `opening`.
