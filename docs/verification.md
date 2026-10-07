# Rune Cast verification record

Verified on October 7, 2026 using Windows x64 and Godot 4.7.2.stable.official.ed1daf0bf.

## Results

| Check | Result |
| --- | --- |
| Portable editor download | Official GitHub release, SHA-512 matched official checksum file |
| Godot project import | Completed; scripts and SVG icon imported |
| Circuit and combat checks | 23 checks passed, zero failures |
| UI smoke checks | 11 checks passed, zero failures |
| Rendered runtime capture | Saved successfully and visually inspected |
| Visual reference preservation | All five reference versions and their generation prompts retained |
| Local version control | Initialized, no commits or remotes created |

## What the checks cover

Circuit evaluation verifies the reference doubling circuit, unfinished branches, a misoriented Join, disconnected effects, amplified shielding, directed-loop detection, energy limits, and immutable endpoints.

Combat checks verify casting, enemy retaliation, lethal damage preventing retaliation, temporary-rune expiry, persistent ordinary effects, three-card turn draws, techniques, defeat, finite special-piece inventory, and undo.

UI checks instantiate the main scene and exercise rune placement, Cast, branch removal, Undo, Menu, Map, Guide, persistent sound preference, and Restart through their callbacks. These are desktop/headless integration checks, not physical touchscreen tests.

The October 7 runtime image is preserved as [foundation-screen-2026-10-07.png](../output/qa/foundation-screen-2026-10-07.png) (archived during RC-001 before refreshing the capture). The enemy, environment, and interface are editable placeholders rather than finished artwork.

## Known setup limitations

The Android exporter reports that its build-tools directory is not configured. Android SDK/JDK and export templates were not installed in this foundation task. The preset exists, but no APK or AAB has been built.

The iOS preset has a placeholder identifier and no signing team. No Mac/Xcode export or iPhone/iPad testing has occurred.

A first sandboxed editor launch could not write normal Godot user-data/cache locations. Final checks were run with normal local access and completed; the remaining import message concerns the missing Android build tools.

## Product limitations

Only the training encounter is playable. Map navigation, encounter rewards, between-encounter saves, shops, relics, and final art/audio are not implemented. The prototype uses one combined damage event and a fixed intent sequence. Touch-device safe areas and rune inspection need device verification.

## October 8, 2026 — RC-001 development baseline

These checks were executed during RC-001 on Windows x64 / PowerShell. The October 7 record above is historical evidence, not a substitute for this run. The existing pinned engine at `.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe` was used; `GODOT_BIN` was unset. No download, upgrade, or mobile SDK installation was needed. The previous archive checksum verification was not rerun.

| Command / attempt | Exit code | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — initial sandbox attempt | 0 | Import ran, but the object database profiler reported `Could not open 'user://' directory`. This attempt was not accepted as a clean import despite exit 0. |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Import completed without the user-data error or script/import errors. Android build-tools warning remained, recorded separately below. |
| `.\tools\godot.ps1 -Action test` | 0 | **23 checks, 0 failures** |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **11 UI checks, 0 failures**, including sound persistence and restoration |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; new desktop image visually inspected |

Each action was executed separately and its output inspected. Normal local access resolved the sandbox's restriction on Godot's standard user-data directory; no game/tooling change was necessary. UI smoke needed that directory to exercise saving/restoring the sound preference. Local logs are in `output/qa/import-sandbox-attempt.log`, `import.log`, `test.log`, `smoke.log`, and `capture.log`; logs are intentionally ignored.

### Capture evidence

The fresh [foundation-screen.png](../output/qa/foundation-screen.png) is 450 by 1000 pixels (72,418 bytes), written October 8, 2026 at **01:23:51 AEDT** (October 7 at 14:23:51 UTC). The capture used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88. The successful capture output and updated file timestamp establish freshness. Its SHA-256 is `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to the preserved earlier capture because the starting screen did not change.

Visual inspection found the full enemy and intent, enemy/player statistics, complete 4 by 4 board, wiring/editing controls, three rune cards, Cast with energy cost, and Menu/Map/Guide/Sound controls visible. No obvious clipping, missing controls, or missing placeholder assets appeared at this desktop size. This does not establish mobile touch/safe-area acceptance or production-art readiness.

### Repository and checkpoint review

- Initial Git state: unborn `master`, no history, no tracked/staged files, existing project untracked, and no configured remotes. No applicable `AGENTS.md` was found in the repository or its ancestor directories.
- Reviewed source, scenes, data, documentation, tooling and export settings. The large candidate files are intentional reference PNGs (roughly 1.75–2.66 MB each). Engine binaries/archive/settings/cache, `.godot/`, `.local/`, builds, and logs stay ignored. No unexpected binary or embedded signing secret was found among candidate files.
- Retain all seven `.gd.uid` files, the SVG import settings, runtime assets, all 14 reference PNGs (including the four approved images), and all 10 generation prompts. Approved-image SHA-256 values are recorded below for preservation checks.
- `.gitignore` now excludes additional signing formats (`.pfx`, `.p8`, `.provisionprofile`) and general QA output while retaining the two reviewed baseline PNGs as explicit evidence. Existing keystore/JKS/P12/mobileprovision and export-credential exclusions remain.
- Added [the separate-chat workflow](development-workflow.md) and README link. Corrected the plan's current-reference summary. Broader visual-plan synchronization remains a documented follow-up, including RC-011's older v5 wording.
- Staged and reviewed **70 files**, including the existing project and RC-001 deliverables. The index write initially encountered sandbox permission denial; staging succeeded with normal local access. No non-ignored untracked files remain. Ignore probes confirm cache/tool/build/log/credential exclusions and both intentional capture exceptions; all relative file links in the four edited Markdown files resolve. Approved-image hashes match their pre-edit values.
- The final status check found `project.godot` modified after staging, at **01:29:19 AEDT**, outside RC-001 edits. Its engine-style rewrite changes comments/spacing and removes explicit `window/stretch/aspect`, `textures/default_filters/use_nearest_mipmap_filter`, and `pointing/emulate_mouse_from_touch` entries. Preserve this change unstaged; the tested original configuration remains in the index. The checks and capture above predate this rewrite and do not validate the modified working copy. Review it and rerun affected checks if including it in the eventual checkpoint.
- `git diff --cached --check` returns native Git exit **2** with **28 existing blank-at-EOF warnings only** in the initial project files (the first PowerShell invocation reported process exit 1). These formatting-only warnings are retained to avoid unrelated source cleanup. `git -c core.whitespace=-blank-at-eof diff --cached --check` exits 0; this command-local diagnostic does not change Git configuration or conceal any other whitespace category.
- **Checkpoint pending:** configured email is present, but no Git author name is configured. The owner elected to configure Git after this task; no identity was invented or configuration changed. Intended commit subject: `chore: establish Rune Cast development baseline`. RC-001 remains **partial**, with its task checkbox open until the commit exists and its revision/status are verified.

| Approved file | SHA-256 |
| --- | --- |
| `output/imagegen/approved/home.png` | `5dcac9f327f25de8350c193ad0618530e12c041ec4c42ce97ce703c99ff71fc6` |
| `output/imagegen/approved/combat.png` | `d5fa939150e3953cf1a5e5d3943203d2af4839f191b5ee81533fa8b04d223841` |
| `output/imagegen/approved/map.png` | `58ec4b54b152b383d2b6afd165739d04da8c67108e35f4c5985b23d0f2a9f6e4` |
| `output/imagegen/approved/menu.png` | `d37c1a5ca8c1ccd5ed9066f559ccabc5f599133a2256d5d5b10bfd263c824d6a` |

### Remaining limitations and next tasks

The accepted import still reports `Unable to open Android 'build-tools' directory.` This is an Android export-configuration warning, separate from desktop verification; it did not prevent desktop checks or rendering. Android SDK/JDK/templates, Android packaging, iOS signing/Mac/Xcode work, and physical-device testing were outside RC-001 and remain unverified. No APK, AAB, or IPA was produced.

No gameplay, balance, or artwork changes were needed. The product limitations in the October 7 record still apply. After the owner configures Git identity and the reviewed local checkpoint is created and verified, RC-001 can be completed; **RC-002 and RC-003** are the next dependency-ready tasks.

