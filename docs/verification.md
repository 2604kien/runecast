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

## October 8, 2026 — RC-001 checkpoint reconciliation during RC-002

The owner confirms RC-001 is complete. Read-only inspection verified starting revision `64930fcb05fb54e1711e084e59214eb33a2d53c0` (`Initial commit`), a clean `master` tracking `origin/master`, 70 committed baseline files, and a resolvable configured Git author identity. The checkpoint includes the workflow, previous verification records, source/data, approved references and both tracked runtime captures. The historical partial record above is preserved; its missing-identity/checkpoint prerequisite has been resolved.

The existing `import.log`, `test.log`, `smoke.log` and `capture.log` were read: import reports the same missing Android build-tools directory; core output reports 23 checks/0 failures; UI output reports 11 checks/0 failures; capture reports `Screenshot saved: OK`. Both tracked captures hash to `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, matching the original record. The four approved-image hashes also match the table above, and all four references were visually inspected for RC-002.

The committed `project.godot` includes the editor rewrite previously observed after the October 8 checks. Those earlier results do not verify that rewritten configuration. RC-002 neither changes it nor repeats completed baseline work; the next runtime task must run relevant checks against its actual starting configuration. This reconciliation records a restorable checkpoint and owner-confirmed completion, not fresh runtime or device acceptance.

## October 8, 2026 — RC-002 documentation validation

Starting revision: `64930fcb05fb54e1711e084e59214eb33a2d53c0`. Task branch: `codex/rc-002-v1-design-roster`. Checkpoint subject: `docs: define Rune Cast v1 scope and content roster`; its hash is reported in the chat handoff rather than embedded in the commit itself.

| Check actually performed | Result and limit |
| --- | --- |
| Source and reference review | Read required documentation/data, inspected relevant core/UI behavior and all four approved images. Current rules remain distinct from proposed features. |
| Native PowerShell roster-table validation | **52 unique content IDs**; every entry has six populated fields including implementation/rule dependencies and task ownership. Totals: 12 permanent, 1 generated, 5 enemies, 4 boards, 6 relics, 4 events, 6 room types, 6 services, 8 upgrades. |
| Existing ID and upgrade references | All five IDs from `data/runes.json` retain their permanent/generated classification; `training_shadeling` is preserved. All eight upgrade targets refer to permanent definitions. |
| Board witness validation | All four listed paths stay within 4 by 4 bounds, never repeat cells, use orthogonal steps, leave Begin eastward and enter End from north. These are geometric witnesses, not claims of final combat balance or implemented configurable boards. |
| Markdown file and anchor validation | All local links across README and the twelve Markdown files in `docs/` resolve, including the new specification/roster and experiment/economy anchors. |
| Task graph validation | All **60 task IDs** remain unique; referenced tasks exist; dependency ranges expand correctly; depth-first cycle check passes. All 60 dependency cells match the starting plan, so no prerequisite edges changed. |
| Cross-document review | Counts, starter ownership, six open experiments, four-screen states, save/terminal policy, asset owners and external prerequisites agree. The default shop follows Gold-producing fights; 75/90 base Gold makes the scoped individual services reachable. Relic acquisition remains useful before recovery/guardian. Values are proposals for later human tuning. |
| Preservation | Four approved SHA-256 values match the RC-001 table. `git diff --exit-code 64930fc -- data scripts scenes assets project.godot export_presets.cfg output/imagegen docs/gameplay-rules.md tools tests output/qa` passed. Gameplay rules, runtime, data, assets, tooling, tests and existing QA evidence are unchanged. |
| Change review | Only README and task documentation are included; the inventory change corrects Shadeling's role without expanding the manifest. Working and staged whitespace checks pass. Staged names/stat/full diff were reviewed before the authorized local checkpoint. |

No Godot command, gameplay implementation, production asset generation, mobile setup, account configuration, push or PR was performed. RC-002 is a documentation-only task; the earlier runtime evidence and its configuration limitation remain as recorded above. Detailed production specifications/manifest expansion remain RC-010, experiments RC-005/RC-006, and device/human acceptance remain their later tasks.

## October 8, 2026 — RC-003 combat/presentation separation

Starting revision: `b373a8c` (`docs: define Rune Cast v1 scope and content roster`), clean `codex/rc-002-v1-design-roster`. Created `codex/rc-003-combat-presentation` from that revision, preserving RC-002. No applicable `AGENTS.md` was found in the repository or ancestor directories. The branch write needed normal local access because `.git` is read-only in the sandbox. The authorized checkpoint subject is `refactor: separate combat resolution from presentation`; its resulting hash is reported in the chat handoff.

### Fresh baseline before editing

The actual committed `project.godot`, including the editor rewrite discussed in RC-001/RC-002, was verified afresh. The pinned engine was already installed; no engine upgrade/download or mobile prerequisite installation occurred.

| Command / attempt | Exit | Observed result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — sandbox | 0 | `Could not open 'user://' directory` from the object database profiler; not accepted as clean despite exit 0. Existing Android build-tools warning also present. |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Import completed without script/user-data errors; only existing Android warning remained. |
| `.\tools\godot.ps1 -Action test` | 0 | **23 checks, 0 failures** |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **11 UI checks, 0 failures**; sound preference restored |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; inspected before refactoring |

Baseline logs are retained locally as `output/qa/rc-003-before-*.log`, including `rc-003-before-import-sandbox.log`. The sandbox directory error is an environment restriction, not a game regression. The successful import/test/smoke/capture resolves the prior configuration-verification gap for desktop behavior.

### Final verification after implementation

All five required commands were executed separately and their exit codes and output inspected. No runtime source changed after this accepted sequence; subsequent edits record documentation/evidence.

| Command | Exit | Observed result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf` |
| `.\tools\godot.ps1 -Action import` — normal local access | 0 | Scripts imported successfully, including new `.gd.uid` companions; existing Android warning only |
| `.\tools\godot.ps1 -Action test` | 0 | **75 checks, 0 failures**: original 23 plus 52 event/controller/ownership/RNG checks |
| `.\tools\godot.ps1 -Action smoke` — normal local access | 0 | **32 UI checks, 0 failures**: original 11 plus 21 presentation/view checks; sound preference restored |
| `.\tools\godot.ps1 -Action capture` — normal local access | 0 | `Screenshot saved: OK`; fresh image inspected and compared |

Final logs are retained locally as `output/qa/rc-003-after-*.log` and the standard command logs. The initial expanded test compile attempt exposed a test-only inferred-Variant warning treated as an error; it was stopped, explicitly typed and rerun successfully. Independent read-only review also found selection help hiding inventory errors and cancellation reentering teardown; both were corrected and have focused regression coverage. Final outputs contain no script errors or leaked-object reports.

Additional preservation evidence: a local differential harness loaded `combat.gd` from `b373a8c` beside the refactored model and ran **720 deterministic command steps across seeds 0, 42 and 1234, 0 mismatches**, exit 0. It compared return values, board, hand, piles, history, health, energy, turn/state/log, next UID and RNG state after every step, including resets and invalid commands. An initial relative log-path attempt reported a user-directory error; rerunning with the absolute workspace log path produced clean output. The harness/baseline copy and `rc-003-differential.log` are ignored local evidence, not shipped runtime or a second maintained rules implementation. Four golden draw-order checks from that baseline are integrated into the regular core suite, including Reset continuing the RNG stream.

New checks cover ordered nonlethal/lethal/shielded/defeat/Pass outcomes, actual versus clamped damage, board/hand temporary expiry, cleanup/refresh/draw ordering, Conjure and Focus (including recycling Focus itself), invalid/unaffordable/missing/terminal actions, prior-result stability, consumer mutations and replay. Controlled completion tests cover every gameplay mutation during a pending action, signal reentry, duplicate/stale callbacks, Restart, cancellation, disposal during cancellation, callback owner lifetime and actual scene teardown. UI checks retain editing/navigation/audio behavior and verify local selection help, inventory errors, disabled controls and direct handler guards. Delayed-presentation assertions do not depend on timers or sleeps.

### Visual evidence

Both 450 by 1000 captures are intentionally checkpointed. Rendering used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88.

| Capture | Fresh write time, Sydney (AEDT) | UTC | Size |
| --- | --- | --- | --- |
| [Before refactor](../output/qa/rc-003-before.png) | October 8, 2026, **22:20:20** | October 8, 11:20:20 | 72,418 bytes |
| [After refactor](../output/qa/rc-003-after.png) | October 8, 2026, **22:33:14** | October 8, 11:33:14 | 72,418 bytes |

Both SHA-256 hashes are `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to the refreshed [foundation screen](../output/qa/foundation-screen.png). Fresh capture output and modification times establish that both were newly rendered despite identical bytes. Visual inspection confirmed the title, full enemy/intent/health, player stats, complete 4 by 4 board, wiring/editing controls, three rune cards, status text, Cast/cost and Menu/Map/Guide/Sound remain visible and consistent, with no observed clipping or missing controls at this desktop size.

### Review, scope and limitations

The [architecture contract](combat-presentation.md) documents responsibilities, command/result/event data, detached ownership, exact resolution order, completion/cancellation and RC-017 integration. Source changes are confined to combat outcomes, the controller/adapter boundary, view command routing and focused tests. Scene structure, circuit rules, JSON content, `project.godot`, export presets, audio implementation and approved artwork remain unchanged. README links the contract; the workflow and ignore exceptions preserve both comparison PNGs. Reviewed all **22 staged files**, names/stat/full diffs, generated UIDs and intentional PNG sizes; `git diff --cached --check` passed. All **79 local documentation links** in the edited Markdown files resolve. Preservation diffs against `b373a8c` are empty for scene/configuration/circuit/content/artwork, existing rules/design/roster/decisions and tooling. No unrelated files are staged; final commit/status are reported in the handoff.

The existing import message `Unable to open Android 'build-tools' directory.` is an Android export-configuration warning, separate from desktop success. No SDK/JDK/templates were installed, no mobile package was produced, and no physical-device or production-animation acceptance is claimed. Current UI, Menu and Map remain placeholders; future schemas, experiments, touch changes, production animation and run/save/reward systems remain outside RC-003. No push, remote change, PR or history rewrite occurred.


## October 8, 2026 — RC-004 validated content and configurable setup

RC-004 is complete. The owner explicitly prohibited **all Git operations**, including read-only inspection. None were performed; no revision, branch or checkpoint is asserted for this task. A commit is not an acceptance requirement under that instruction. No applicable `AGENTS.md` was found in the repository or ancestor directories. Required design, workflow, rules, RC-003 handoff and runtime/test files were reviewed before implementation.

### Fresh baseline and environment

The existing pinned `4.7.2.stable.official.ed1daf0bf` installation was used without downloads or upgrades. Before changing behavior, import, core and UI checks ran separately:

| Command / attempt | Exit | Actual result |
| --- | --- | --- |
| `-Action import`, sandbox | 0 | `Could not open 'user://' directory` in the object database profiler; not accepted as clean. Existing Android build-tools warning also present. |
| `-Action import`, normal local access | 0 | Import completed; existing Android build-tools warning only. |
| `-Action test` | 0 | **75 checks, 0 failures**. |
| `-Action smoke`, normal local access | 0 | **32 UI checks, 0 failures**; sound preference restored. |

Baseline logs remain locally as `output/qa/rc-004-before-{import-sandbox,import,test,smoke}.log`. The sandbox directory failure matches the prior environmental limitation and was resolved by normal local access, without changing project behavior.

### Final verification

The required actions were executed separately and their output and exit status inspected. The version/import/test/smoke/default-capture sequence was followed by the documented alternate-scene capture. No runtime edits followed the accepted sequence; later edits record documentation and evidence.

| Command | Exit | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf`. |
| `.\tools\godot.ps1 -Action import` | 0 | Clean desktop script import; existing Android build-tools warning only. |
| `.\tools\godot.ps1 -Action test` | 0 | **204 checks, 0 failures**: 75 retained core/controller checks, 90 loader checks, 39 configured-combat checks. |
| `.\tools\godot.ps1 -Action smoke` | 0 | **62 UI checks, 0 failures**: 32 retained checks plus 30 configuration checks. |
| `.\tools\godot.ps1 -Action capture` | 0 | `Screenshot saved: OK`; default screen inspected. |
| `.\tools\godot.ps1 -Action capture -Encounter 'res://data/dev_encounter.json' -CapturePath 'res://output/qa/rc-004-development.png'` | 0 | `Screenshot saved: OK`; actual alternate scene inspected. |
| `.\tools\godot.ps1 -Action capture -Encounter 'res://data/missing.json' -CapturePath 'res://output/qa/rc-004-invalid.png'` | **1, expected** | Missing-file diagnostic, `Screenshot saved: OK`, visibly disabled configuration-error screen. Negative capture completed before final sequence; failure handling was unchanged afterward. |

UI smoke intentionally prints two `Cannot start encounter` diagnostics: the absent fixture file and the targeted `invalid_ui.enemy_id` reference. They are asserted negative-test outcomes, not script failures. Final accepted runs report no script errors or leaked objects. Standard logs and `rc-004-after-{import,test,smoke}.log`, `rc-004-{training,development,invalid}-capture.log` are retained locally, not as shipped artifacts.

Focused development runs exposed incompatible-Variant comparisons while validating deliberately wrong types; validation now checks types before comparisons and includes six extra wrong-type regressions. The first loader-only probe omitted an absolute log path and reported the known `user://logs` environment restriction; subsequent probes used an explicit workspace log and passed cleanly. An earlier integrated run passed 198 checks before those six cases were added; **204** is the final count. Review also corrected the training title and adopted the roster's `board_training` ID before final acceptance.

Coverage includes required/optional fields, root/field types, numeric fractions/strings/booleans/nonfinite values, bounded health/energy/draw/inventory, unique IDs and references, unsupported effects and generated targets, malformed board geometry versus valid incomplete circuits, opening ownership and installed stock. Combat checks cover both configurations, unique UIDs, conservation through edits/undo/turns, generated-card exclusion, configured effect values/targets, fresh seed reproducibility, existing golden training shuffle/reset continuation, selected-setup Restart and detached input/state/snapshots/results. Retained RC-003 checks continue to prove ordered events, duplicate-input guards, cancellation reentry, stale callbacks and teardown. Actual scene tests cover alternate labels, tooltips, help, cast/undo/restart and every direct gameplay callback after invalid startup.

### Visual evidence

All three 450 by 1000 images were visually inspected. Rendering used OpenGL 3.3 Compatibility on NVIDIA GeForce RTX 5070 Ti, driver 610.88. These PNGs have explicit retention exceptions in the capture policy; other local QA output remains ignored.

| Capture | Fresh write time, Sydney (AEDT) | UTC | Bytes |
| --- | --- | --- | --- |
| [Training](../output/qa/rc-004-training.png) | October 8, 23:16:51 | October 8, 12:16:51 | 72,418 |
| [Development fixture](../output/qa/rc-004-development.png) | October 8, 23:17:14 | October 8, 12:17:14 | 71,458 |
| [Invalid configuration](../output/qa/rc-004-invalid.png) | October 8, 23:13:28 | October 8, 12:13:28 | 62,547 |

Training SHA-256 is `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to RC-003 and the refreshed `foundation-screen.png`. Its title, Shadeling/32 HP/attack 8, player 30/30 and energy 3/3, original board, three cards, stock, Cast and navigation remain visible without clipping. The first cast is still 12 damage for one energy, leaving enemy 20 HP and player 22 HP.

The alternate image visibly shows DEVELOPMENT FIXTURE, CALIBRATION WISP, 45/45 HP and attack 3, player 24/40, energy 4/4, Split 2/2 and Join 0/0, Focus/Shield hand, installed Spark, different path and a two-energy Cast. Labels and all controls fit the preserved layout. Its SHA-256 is `b97e5d49114f5d057db080b527c9883a5fdcf05429a8bc6a23366948165ea4be`. UI tests additionally verify draw-two help, the selected enemy's tooltip and contextual Menu/Map/Guide text.

The invalid capture shows CONTENT ERROR, the missing path/reason and visibly disabled board/edit/Cast controls. No hand or playable fallback is created; UI tests also verify disabled Pass/Restart and safe direct callbacks. Its SHA-256 is `558ca43cb1aef9b172e7572cf513f27de30d9fe27e9367b02e49e57f3faad0b1`.

The four approved-reference hashes still match the RC-001 table. No approved reference or production asset was changed or generated. Existing scene geometry, renderer/project settings and circuit rules remain in place; the gameplay-rules text only clarifies configurable training defaults, leaving future mechanics undecided. Documentation file-link validation checked **142 local links, zero broken targets**. All runtime/test GDScript files have their `.gd.uid` companions.

### Limits and handoff

The existing `Unable to open Android 'build-tools' directory.` warning concerns Android export configuration and is separate from desktop success. No engine upgrade, mobile SDK installation, mobile packaging or physical-device acceptance is claimed. The alternate fixture is deliberately development/test content using the shared placeholder artwork, not balanced production roster expansion. Alternate endpoints, obstacles, ports, mixed effects, relics, statuses, guardian phases, run/save/reward systems and production animation/audio remain outside this task. See [content definitions](content-definitions.md), [combat presentation](combat-presentation.md) and the [RC-004 handoff](project-plan.md). **RC-005** is next ready; **RC-010** remains independently available.

## October 9, 2026 — RC-005 controlled circuit experiments

**RC-005 complete.** This is executable experiment/protocol readiness, not human-playtest acceptance or production-rule selection. The original training encounter and Calibration Wisp remain unchanged. The [experiment matrix and RC-006 handoff](circuit-experiments.md) records exact provisional rules, matched setups, known solutions, controls, metrics, confounds and a blank observation/decision template.

### Baseline and scope

No applicable `AGENTS.md` was found in the repository or ancestor directories. Required design, content, gameplay, workflow (excluding Git work), setup, verification and RC-003/RC-004 handoffs were read. The pinned local Godot installation was used without upgrades or downloads.

The owner's request prohibited all Git operations. One initial `git status --short` was mistakenly included in the first inspection command before the pasted prohibition had been read; this was disclosed immediately. No further Git operations were performed. No branch/revision/checkpoint is asserted or required, and the owner retains Git handling.

Fresh pre-behavior baseline:

| Command / context | Exit | Observed result |
| --- | --- | --- |
| `-Action import`, sandbox | 0 | Existing `Could not open user:// directory` profiler error; not accepted as clean. Android build-tools warning also present. |
| `-Action import`, normal local access | 0 | Desktop import succeeded; Android build-tools warning only. |
| `-Action test` | 0 | **204 checks, 0 failures**. |
| `-Action smoke`, sandbox | 1 | **56 UI checks, 1 failure**, plus null-file script error in the existing user-directory fixture test; sound persistence could not write. |
| `-Action smoke`, normal local access | 0 | **62 UI checks, 0 failures**. First approval-review attempt timed out; the permitted retry succeeded. |

Baseline logs: `output/qa/rc-005-before-{import-sandbox,import,test,smoke-sandbox,smoke}.log`. These failures reproduce the earlier environment restriction; they preceded behavior edits and disappear with normal local user-directory access. They are distinct from runtime regressions.

### Final separate commands

Each action below was run separately; output and exit status were inspected after the final runtime changes:

| Exact command | Exit | Actual result |
| --- | --- | --- |
| `.\tools\godot.ps1 -Action version` | 0 | `4.7.2.stable.official.ed1daf0bf`. |
| `.\tools\godot.ps1 -Action import` | 0 | Script import and new UID companions succeeded; existing Android build-tools warning only. |
| `.\tools\godot.ps1 -Action test` | 0 | **478 checks, 0 failures**: retained204 + experimental core116 + experimental content122 + records/controller36. |
| `.\tools\godot.ps1 -Action smoke` | 0 | **179 UI checks, 0 failures**: retained62 + experiment117. |
| `.\tools\godot.ps1 -Action capture` | 0 | `Screenshot saved: OK`; default capture inspected and copied to `rc-005-training.png`. |

Final logs are `output/qa/rc-005-final-{import,test,smoke}.log` and `rc-005-training-capture.log`. Smoke intentionally prints three asserted startup diagnostics (missing normal fixture, invalid enemy reference, unknown experiment scenario); no script errors or leaked-object reports remain. Intermediate focused validation exposed and fixed a test-only inferred-Variant compile error. An early focused probe with a relative log path had the known user-directory path warning; clean absolute-path reruns passed. Integrated intermediate UI count150 preceded the expanded179-check final suite.

Coverage retains default opening damage/health, configured Wisp behavior, loading diagnostics, ordered events, detached snapshots and all RC-003 input/cancellation protections. New checks cover all19 variant semantics/known openings, the real extra-pair witness, strict options and geometry validation, endpoint/block protection, port rotation/connectivity, consumed/disconnected effects, temporary hand/board cleanup, all expiry replacements, multi-hit totals/order/lethal/zero damage, ownership/UID conservation, same-seed replay and reset/retain transfers, duplicate/incompatible transitions, controlled timing, metrics deduplication/classification, RNG independence, serialization and write failure. UI smoke selects and launches all variants, performs witness edits and casts through actual controls, compares exact-replay snapshots, completes both encounters under both transfer modes, checks stale callbacks across replay, exercises notes/export/write errors and malformed startup.

### Visual evidence

All seven fresh 450×1000 PNGs were inspected. Rendering: OpenGL3.3 Compatibility, NVIDIA GeForce RTX5070Ti, driver610.88. The experiment screen uses a compact enemy summary to keep controls/readouts legible; normal artwork/layout is untouched.

| Capture | Sydney AEDT, October9 | Bytes | What was inspected |
| --- | --- | --- | --- |
| [Normal training](../output/qa/rc-005-training.png) | 00:56:45 | 72,418 | Original complete board, hand, stats, arena, tools and navigation. |
| [Blocked cell and controls](../output/qa/rc-005-blocked.png) | 00:57:02 | 109,823 | Scenario/variant/seed, launch/replay/next/export, explicit blocked6 and valid route. |
| [Alternate endpoints](../output/qa/rc-005-endpoints.png) | 00:57:19 | 115,945 | Begin15/End1, reversed spatial direction, protected endpoint ports and unchanged forecast. |
| [Corner effect](../output/qa/rc-005-ports.png) | 00:57:29 | 107,879 | Spark3 west-to-south ports agree with the actual powered path. |
| [Multi-hit after Cast](../output/qa/rc-005-hits.png) | 00:57:38 | 106,446 | Two visible6-damage hits; enemy24/36, player37/40, turn2. |
| [Retained expiry after Cast](../output/qa/rc-005-expiry.png) | 00:57:48 | 108,796 | Powered3 and disconnected8 become corner wires at the original orientations. |
| [Record inspector](../output/qa/rc-005-record-inspector.png) | 00:58:13 | 137,366 | Scrollable JSON, resolved local path, optional note field and export button. |

Training SHA-256: `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`, identical to RC-003/RC-004. Its fresh timestamp and capture output establish a new render. Experiment capture commands use `-Action capture -Experiment -Scenario <id> -Variant <variant> -Seed 42 -CapturePath res://output/qa/<name>.png`; use `-CaptureStep cast` for hits/expiry and `-CaptureStep inspect` for the inspector. Other captures use the opening state. Captures produce only QA observation files.

### Actual exported records and reproducibility

Inspected JSON files under `output/qa/experiment-records/`:

- `capture-hits-treatment.json`: one accepted Cast, two hits of6, applied damage12, cost3, retaliation3; version `rc005_v1`, seed42, fingerprint `092168db73a29803cadb18666b48ad289e7f95792d39f77ffe1f67b2a40bc4ff`.
- `ui-split_inventory-treatment.json`: three accepted edits (two placements/one rotation), one Cast, damage18/cost4, confirming the extra pair is exercised.
- `ui-encounters-control-complete.json`: four Casts, one rune install, one transition, one rejected duplicate transition, two victories, applied damage48/cost12.
- `ui-encounters-treatment-complete.json`: four Casts, no required edit, one transition, one rejected duplicate transition, two victories, applied damage48/cost12. These scripted counts are **not human behavior findings**.

A separate local audit, `output/qa/rc005_replay_audit.gd`, read these four actual disk exports, rebuilt each validated scenario/variant/seed, checked its configuration fingerprint, replayed command arguments and compared every serialized after-state. **18 command outcomes reproduced, zero mismatches**, exit0; log `output/qa/rc-005-replay-audit.log`. The maintained UI suite also proves exact starting snapshot equality after every variant's Replay button. Preparation timings/notes are not claimed deterministic.

Human records default to `user://experiments/`; the inspector shows the absolute path. Test/capture files are explicitly separated and labelled automated. Ordinary gameplay constructs no recorder. Writes/exports never consume gameplay RNG; failed writes retain gameplay and show a visible error. Replay/Launch preserve an unsaved session rather than discarding its record.

### Limits and handoff

The Android `Unable to open Android build-tools directory` warning remains an export-configuration issue, separate from desktop success. No mobile SDKs were installed, no package was built, and no physical-device acceptance is claimed. No production rules/assets/animations/audio, on-hit/status system, full tower route, shops/rewards/relics or game saves were added. Approved artwork was not modified.

Equal-total multi-hit cannot establish future armor/on-hit balance. Endpoint rotation tests orientation rather than asymmetric board difficulty; the blocked cell initially lies off the path; the corner Spark changes starting cell to hold a valid path constant. The transfer harness supports two identical-geometry encounters only. All these limits are explicit in the protocol. **RC-006 requires actual human playtesting and decisions; RC-010 remains independently available.**

Documentation validation checked **128 local links, zero broken targets** across the updated handoff/reference files. Every runtime/test `.gd` has its generated `.gd.uid` companion. Read-only cross-reviews found no remaining blocking runtime issues; two protocol wording issues (installed Shield count and executable Focus setup) were corrected before handoff.
