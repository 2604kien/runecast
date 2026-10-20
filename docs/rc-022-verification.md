# RC-022 — iOS development build preparation and verification

**Later October 19 owner direction: remaining RC-022 work is deferred.** Retain all delivered preparation and evidence below. Mac/signing/native-build/device execution will resume when scheduled by the owner; no completion criteria are waived. RC-024's independent run-state/application-shell groundwork is next, while RC-023 remains pending human/device acceptance. See the [current project plan](project-plan.md#current-starting-point).

October 19, 2026 (Australia/Sydney). **Partial delivery; physical acceptance remains open.** Windows preparation, export configuration, resource verification, source transfer and a macOS development workflow are delivered. No Xcode project, native iOS app, simulator execution, installation or physical launch was produced in this session. An exported PCK is only the game's resource payload.

The owner reports having an **iPhone 14 running iOS 18**. The exact OS patch, connection/trust and Developer Mode are unverified. An authorized Mac, compatible installed Xcode/SDK, development team and approved development bundle identifier have not been provided. The initial access question was answered with the phone details; no remote access, signing consent or paid enrollment is inferred.

## Recorded environment

| Item | Evidence / state |
| --- | --- |
| Host | Windows NT 10.0.26200.0, x64; Python 3.12.14. [Environment](../output/qa/rc-022/environment.json). |
| Editor used | Godot **4.7.2.stable.official.ed1daf0bf**, Standard/GDScript, Windows x64. Project Compatibility renderer retained. |
| Exporter schema | Actual installed `EditorExportPlatformIOS` options/defaults queried in an isolated editor project; [machine record](../output/qa/rc-022/exporter-options.json). No assumption that a preliminary preset was valid. |
| Templates | Official **4.7.2.stable** full TPZ in the existing Android download cache. SHA-512 matched the pinned official checksum before inspecting its iOS entry; [template inspection](../output/qa/rc-022/ios-template-inspection.json). Windows editor still has only Android templates installed. |
| iOS template inspected | `ios.zip`, **202,976,946 bytes**, SHA-256 `fd3280d10dc75356dded006f6f8813f40a5aebd32d128592b781256d8ffbdff4`; extracted only under `output/qa/rc-022/templates`, not installed or run. |
| macOS / Mac architecture/model | Unavailable/unverified. The helper records these on an authorized Mac. |
| Xcode / selected iPhoneOS SDK | Unavailable/unverified. Select against actual Mac/macOS and exact iPhone OS using Apple's compatibility table. |
| Development identity | Source team/bundle fields blank; no approved identity or usable signing access confirmed. Helper requires explicit external owner-approved JSON and existing development signing material. RC-052 retains production identity. |
| Configuration | Debug, arm64, iPhone family only, portrait, 0.1.0 / build 1. Configured deployment floor **15.0** comes from the pinned exporter; built app minimum and tested support remain unverified. |
| Device | Owner-reported iPhone 14 / iOS 18. No hardware UDID, exact patch, pairing, Developer Mode, app or observations obtained. |

The full template archive SHA-512 is `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079`. [Toolchain lock](../tools/ios-toolchain.json) repeats the exact engine/template requirements. No engine upgrade or mismatched template was used.

## Delivered changes

- [iOS workflow](../tools/ios.py): macOS preflight, fresh staged import/export, Debug/iphoneos build, signature/profile/artifact inspection, selected-device install/launch and app-console instructions. It checks artifacts and tool output, and rejects Godot error output even when the process exits zero. No global Xcode changes, downloads, account login, certificate creation/revocation, uninstall/data clearing, release archive or distribution command is performed.
- [Export preset](../export_presets.cfg): explicit development/project-only options, iPhone family and deployment floor; placeholder iOS bundle removed. Owner values are injected into a staged copy. Existing Android preset bytes remain unchanged; [preservation record](../output/qa/rc-022/preset-preservation.json).
- [PCK auditor](../tools/verify_ios_resources.py): checks the actual resource pack directory, path casing/collisions, bounds, payload hashes, production inventory and import/remap targets. It then runs the exact PCK in an empty project with isolated user data. The existing [Android resource probe](../tools/verify_android_resources.gd) accepts an optional iOS report label while keeping Android as its default; its completion is deferred to release coroutine-local resource references before shutdown.
- [Source-copy helper](../tools/prepare_ios_transfer.py): creates a new source-only ZIP with a per-file manifest, verifies copied bytes and excludes metadata/caches/SDKs/signing material/source masters/previous outputs. Development tests/tools/docs transfer for use on the Mac but remain excluded from the shipped payload.
- [Setup](setup.md#ios), project-plan status and external-access register now distinguish available phone hardware from missing Mac/signing execution. Runtime touch, settings, audio, timing and gameplay files were not changed.

The source/runtime audit found no demonstrated iOS defect to justify speculative changes. Existing pause cleanup releases stale pointer ownership. Native first-slider touches retain RC-021's corrected emulated-mouse handling; Android's single-frame Back guard remains. Audio interruption clears queued cues and stops SFX; compatible loop players pause/resume without replaying discarded cues. Settings edits preserve reduced motion and unrelated entries. These source/desktop observations do not establish iOS behavior.

Review corrected two new-helper defects before delivery: development certificate display names cannot identify the signing team, so team validation occurs against the signed app/profile; launch now requires a successful installation receipt tied to the same physical-device UDID and complete app-file manifest, rather than attributing a same-bundle older app to a new build. Diagnostics also retain the selected process-local Xcode path.

## Executed Windows checks

| Check | Observed result |
| --- | --- |
| Pinned exporter inspection | Schema/defaults obtained from the installed editor. iPhone enum 0 maps to Xcode device family 1; deployment default 15.0; development method 1 and project-only option exist. |
| iOS-preset resource export | [RuneCast.pck](../builds/ios/windows-resource-audit/RuneCast.pck), **10,308,676 bytes**, SHA-256 **`d53b86bf36a2c7c33232189c590369328f5a222c08817bc273f6645f3a6fadcb`**. Godot PCK v4, flags 2, 334 entries. This is not an Xcode project or installable app. |
| Actual PCK policy/integrity | **347 checks, zero failures**. [Inventory, hashes and checks](../output/qa/rc-022/windows-resource-audit/resource-audit.json). |
| Isolated exact-payload load/decode | **46 checks, zero failures**, no engine errors. [Probe log](../output/qa/rc-022/windows-resource-audit/ios-resource-probe.log). Production scene initializes, eight data files load, imported fonts/art/actor resources and all available audio load without workspace resources. |
| Repeat Windows resource export | Second PCK passes the same **347 + 46 checks**. Both pack hashes and all **334/334** payloads are identical; [measured comparison](../output/qa/rc-022/windows-resource-repeat/comparison.json). This establishes only the observed resource-pack repeat, not native-build reproducibility. |
| No-fallback negative control | A deliberately broken fixture removed a packed WAV import that still exists in the workspace. Decoder correctly returned 1 with one failed resource check; [result](../output/qa/rc-022/no-fallback-negative/result.json). This expected failure is not a defect in the delivered pack. |
| Core suite | **1,827 checks, zero failures**. [Log](../output/qa/rc-022/core-tests.log). |
| UI suite | **1,171 checks, zero failures**, including existing mobile input/pause coverage. [Log](../output/qa/rc-022/ui-tests.log). Intentional invalid-startup fixture messages are expected. |
| Python tooling checks | **30 tests pass**: 17 workflow, 10 PCK integrity/policy and 3 transfer-boundary tests; [combined log](../output/qa/rc-022/all-ios-tool-tests.txt). These use fixtures/mocks for unavailable Mac/signing/device tools. |
| Android preservation | Existing delivered APK re-audited: **376 package checks and 46 isolated resource checks**, zero failures. [Evidence](../output/qa/rc-022/android-regression). Android preset unchanged; no new Android installation or physical acceptance inferred. |
| Unsupported host | Real `ios.py preflight` exits 2 on Windows with a clear Mac/Xcode prerequisite failure; [record](../output/qa/rc-022/20261018T153338Z-3e043f68/workflow.json). It does not claim a successful build. |

Production inclusion covers the eight JSON definitions, both font licence/attribution files, live UI/textures/shaders including `assets/ui/combat/reference`, Shadeling attachments/motion, runtime audio metadata, all **21 SFX** and compressed looping crypt ambience. Documentation, tests, development fixtures/helpers, source masters, raw generations, SDKs, QA and previous builds are absent. Both music entries remain unavailable, with no packaged substitute and no documentation-file dependency. The desktop probe establishes imported resource loading/decoding, not native rendering, physical audio signal or human listening.

The successful export logged the already-known Android Build Tools fallback to 35.0.1 while scanning the existing Android setup. It did not make an Android change or establish an iOS warning. Initial Python fixture runs hit sandbox restrictions in the OS temporary directory; their retained failure logs distinguish those harness failures from the passing reruns using task-local temporary folders. The repeated PCK probe also exposed two retained resources at shutdown despite 46 passing assertions and exit 0. The auditor rejected that run; deferring probe completion until coroutine-local references release corrected the harness. The original PCK, repeat PCK and Android APK then passed cleanly. The [initial failed repeat evidence](../output/qa/rc-022/windows-resource-repeat/initial-probe) remains available.

The prepared source-transfer archive's exact location, size and SHA-256 are in [source-transfer.json](../output/qa/rc-022/source-transfer.json). Its contents are a verified development handoff, not an app. Historical output/evidence links in the copied docs refer to the original Windows workspace; those unrelated output trees are intentionally absent from the transfer.

Commands used, with process-local test data paths under `output/qa/rc-022`:

```powershell
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$engine = '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path . --export-pack iOS builds/ios/windows-resource-audit/RuneCast.pck
& $py tools/verify_ios_resources.py --pack builds/ios/windows-resource-audit/RuneCast.pck --engine $engine --report output/qa/rc-022/windows-resource-audit/resource-audit.json
& $engine --headless --path . --script res://tests/test_runner.gd
& $engine --headless --path . --script res://tests/ui_smoke.gd
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
& $py tools/verify_android_package.py builds/android/RuneCast-debug.apk --report output/qa/rc-022/android-regression.json
& $py tools/ios.py preflight
```

The existing pack/evidence paths above describe the executed run. For a fresh export, create a new destination under `builds/ios` and a new evidence folder instead of overwriting retained artifacts. The [setup workflow](setup.md#ios) documents Mac first-time setup separately from repeat builds. Mac artifacts will be under `builds/ios/<run>/export` and `DerivedData/Build/Products/Debug-iphoneos`; each command records evidence under `output/qa/rc-022/<run>`. Retain the staged `source` folder for later artifact comparisons. An `.app` directory is identified through its full per-file hash manifest, executable and PCK hashes, not an invented single-file archive hash.

## Remaining physical-device checks

**Every row below is pending.** Before observations, record Mac/macOS/architecture, Xcode/build number, SDK, exact editor/templates, approved development team/bundle, app hashes, iPhone model/exact OS, date and observation method. Label simulator results separately; neither the simulator nor running an iOS app on a Mac meets physical completion.

| Group | Required observations on the selected iPhone |
| --- | --- |
| Setup/install/launch | Owner connects/unlocks/trusts/pairs and enables Developer Mode. Build a Debug app for the selected phone and install without removing an existing app. Confirm the actual production Shadeling encounter renders and remains responsive; keep app-only console output and screenshots. |
| Portrait/layout | Readable fonts/cards/counters/forecast, complete actor/attachments, safe-area and notch/home-indicator clearance, reachable Cast/Pass/Close/Cancel controls. Check available display/zoom context. No landscape or separate tablet scope. |
| Board and actions | Card/connector selection, placement, rotation and removal; supported hand-card/connector-tool hold inspection. Board slots and forecast intentionally do not inspect. Cast with repeated taps during playback must commit once; Pass cancellation and confirmation must behave distinctly. Preserve current animation timing/rules. |
| Modals and scrolling | Pile and Guide inspection; scroll only where content actually overflows. Close/Cancel stay reachable, closing cannot activate underlying controls, Menu/Options return correctly. First Music touch immediately after opening Options, then reopen and test first SFX touch independently. |
| Reduced motion | Toggle/current preference, stationary reduced feedback and current normal animations. Return navigation and interrupted actions must remain usable without duplicated events. |
| Lifecycle | Background/foreground and lock/unlock during holds, drags, native sliders and action playback. No stale hold, stuck pointer/presentation, duplicated Cast/Pass or queued cue burst. Record any system interruption separately, including recovery. |
| Audio controls | Hear delivered effects and crypt. Music controls crypt; SFX controls effects; independent mutes and master Sound preserve levels. Pending music must stay unavailable. Observe continued loop policy after background/interruption without duplicate starts or stale cues. |
| Output routing/listening | Observe speaker/headphones, route changes and hardware silent-switch behavior where equipment allows. Separate captured signal from human listening/quality acceptance. Record unavailable routes rather than passing them. Final combined mix and pending music remain open. |
| Settings | Distinct volumes/mutes/master/reduced-motion values survive relaunch and a same-team/same-bundle development rebuild/install, preserving unrelated settings. Compare visible values and, if available, app-only settings files from Xcode's container download. Never uninstall/clear data or change identity to make this pass. Settings are not a battle/run save. |
| Repeatability | Repeat the documented Mac build with the same authorized identity; retain both manifests/hashes, install over the existing app and recheck launch/settings. Do not claim byte-identical native builds without measuring them. |

## Exact owner handoff / open gates

1. Provide/authorize a Mac and record its model, architecture and macOS; record the iPhone's exact iOS 18 patch. No remote Mac is currently authorized.
2. On that Mac, follow [first-time setup](setup.md#first-time-mac-and-device-setup) for compatible full Xcode and exact Godot/templates. Owner completes Xcode login, account consent and initial development signing/profile setup; approve the Team ID and unique development bundle ID without sharing credentials.
3. Copy the verified source handoff into a new Mac directory. Run preflight/export, complete initial Xcode provisioning, then the repeat build/install/launch sequence. Preserve all manifests and failed outputs; no uninstall workaround.
4. Exercise the physical matrix above on the iPhone 14, retain app-scoped diagnostics and report actual observations. Fix only demonstrated scoped defects and retest. Complete a repeat same-identity update and settings check.

RC-022 stays unchecked until physical installation/launch and initial touch/layout/audio/lifecycle evidence exists. Physical Android acceptance remains open under RC-021. RC-019 music and RC-020 final music/full-mix acceptance remain open. RC-023 still requires human encounter comprehension and both platforms' physical-device evidence. Shadeling remains one boss encounter on the map; no progression, save, content, music or visual redesign was added.

## Official references consulted

- [Godot 4.7 iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), [iOS exporter options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformios.html), [4.7.2 release archive](https://godotengine.org/download/archive/4.7.2-stable/).
- [Pinned iOS exporter source](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/ios/export/export_plugin.cpp) and [shared Apple exporter](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/editor/export/editor_export_platform_apple_embedded.cpp), checked against the local exporter/template. Fresh directories avoid normal exporter cleanup of previous generated projects.
- [Apple Xcode compatibility](https://developer.apple.com/xcode/system-requirements), [command-line tools](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference), [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), [Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account).
- [Apple DTS: development certificate name is not Team ID](https://developer.apple.com/forums/thread/798623), [devicectl iOS 17+ support](https://developer.apple.com/forums/thread/772724), [Xcode 16.4 diagnostic scope](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_4-release-notes). Use installed CLI help and app-scoped console output, not broad diagnostics.

One read-only `git status` was mistakenly launched alongside reading the pasted request before its no-Git restriction was known. This was disclosed immediately; no Git metadata was changed and no subsequent Git operation was performed. The owner handles Git.
