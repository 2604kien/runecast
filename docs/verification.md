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

## October 9, 2026 — RC-006 study preparation and narrow guidance repair

**RC-006 partial.** The [results/session worksheet](rc-006-playtest-results.md) separates evidence sources and tracks the actual session. The [production contract](production-rules-spec.md) is pending, not a selected implementation contract. No rule preference, production choice or testing waiver has been supplied. RC-007 is not ready; RC-010 remains independently available.

No applicable `AGENTS.md` was found in repository/ancestor inspection. The requested design, rules, content, presentation, experiment and handoff documents and recording/launch code were inspected. No Git operations were performed during RC-006.

### Existing evidence and preservation

Both documented/candidate user-record locations initially lacked an experiments directory. A no-gameplay engine probe resolved `user://experiments/` to `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/`; see the [path/fingerprint log](../output/qa/rc-006-b1-copy-after-20261009.log). No undisclosed human record was inferred from a directory name.

The [evidence inventory](../output/qa/rc-006-record-inventory.json) parses all 29 pre-existing QA exports: six capture, 22 UI, one recorder fixture. Notes and producing test code establish automated provenance, including the unannotated `ui-session.json` and scripted notes in `record-test.json`. All 29 raw SHA-256 values were unchanged after the repair. `occupied.json` is a test directory, not a participant file. No automated action was counted as a human observation.

### Narrow study repair

`split_inventory/treatment` displayed the exact known solution in participant-facing help before a free attempt. `scripts/core/experiments.gd` now displays neutral stock/cost information instead. Geometry, rules, values, normal gameplay and facilitator/test solution actions are unchanged. The semantics version stays `rc005_v1`; the normalized setup includes help/opening text, so its seed42 configuration fingerprint distinguishes the exposure:

- Previous: `43981ff7148fbb934cb33de07dd23db37dd665f5fdcbd54c92f8256d563b3d5c`.
- Repaired: `639da6f6626f5d7dcc40fd709f8f4cea82c7cb0ca4acab696a1e0758f1842e0d`.

Earlier exports retain their original fingerprint and hint exposure. No located human observation was invalidated. Historical RC-005 semantics and verification entries above remain intact.

| Actual validation | Result / limit |
| --- | --- |
| Pinned engine, headless `--script res://output/qa/rc-006-b1-copy-checks-20261009.gd`, project path `C:/Dev/RuneCast`, unique absolute log path | Exit0; **5 focused checks, 0 failures**. [Log](../output/qa/rc-006-b1-copy-checks-20261009.log). Checks in `tests/experiment_content_tests.gd` cover neutral copy, matched configuration, unchanged options/version, preserved solution and valid 18-damage/cost4 witness. No UI, recorder or participant actions in this check. |
| No-gameplay setup/path probes before/after repair | Both completed; before hash matches the existing automated treatment export and after hash differs only through the intended text changes. Authoritative user path recorded. |
| Raw export integrity | 29 hashes checked, zero changed. No earlier raw records overwritten or relabelled. |
| Markdown local-file/anchor check | See [current audit output](../output/qa/rc-006-document-links.json); zero broken targets at the recorded pass. |

The full Godot suite was not rerun for this copy repair; 478/179 above remain historical RC-005 results. No production rules, new mechanic, mobile acceptance or balance result is claimed.

### Live human-session boundary

Normal `.\tools\godot.ps1 -Action run` launched for practice; restricted user-directory access produced a shader-cache-folder warning. The owner replied “ready” after the four practice steps; completion is participant-reported, not directly observed. The experiment command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant control -Seed 42` then launched with approved normal user-directory access and no startup error in returned output. Its initial JSON export exists at the resolved human path and contained zero commands, restarts and notes when inspected. That is export readiness, not comparison evidence.

Anonymous session `RC006-S01` is awaiting its first pre-Cast prediction and familiarity/input context. The facilitator has not operated gameplay. Record future actions, assistance and reports in the results worksheet and preserve each completed attempt's export before switching. The owner's participation in this session makes no claim about testers for later milestones.

### October 9 follow-up — initial owner interaction and selected reset direction

The owner reports mouse input and says this is their first game created. Creation experience is not treated as prior playing familiarity. They explicitly selected an endpoints-only board **at the start of every turn, after each Cast or Pass**. This is an owner-directed choice, not a completed persistence/consumption comparison or testing waiver. The [updated specification](production-rules-spec.md) records the selected A/E/F topology consequences; permanent-card destination and the remaining contracts are pending. RC-007 remains not ready.

The active `effects/control` record was read without modification and copied byte-for-byte to the separate [human-study snapshot](../output/playtests/rc-006/RC006-S01/effects-control-1791504179-987301-attempt09-snapshot.json). It contains **9 attempts, 7 accepted edits, 2 rejected placements, 0 Casts, 0 Passes**, and no techniques, damage, outcomes, restarts or embedded notes. Snapshot SHA-256: `de1670a8871ee062ac6ee932b7fbd6a783411787b1511cc2dff3813b93fe062b`. The source was not overwritten or relabelled. The earlier zero-command entry above remains the historical opening inspection.

The [results worksheet](rc-006-playtest-results.md) separates controller-recorded actions from chat preference and interpretation. No direct screen observation, repeated-turn outcome, matched comparison or mobile acceptance is claimed. Existing experimental variants do not implement full-board clearing; manual erase would return cards to hand and cannot validate an automatic discard/draw policy. No runtime/harness code changed during this follow-up, so no additional Godot test run was needed. Local links and original automated-record hashes were checked again; current link results remain in the audit output. No Git operations were performed.

### October 9 follow-up — discard/draw choices and limited next-hand probe

The owner chose **installed permanent cards to discard for later draws**, with the aim of avoiding repeated casts by rebuilding around a changing hand. They explicitly clarified **normal fresh draws, repeats allowed**; no anti-repeat rule is authorized. The specification and linked status documents now record these choices without asking for reconfirmation. This is owner-directed design input, not proof of repeated-turn enjoyment or different hands on every turn.

Before the next launch, the original control record still contained nine attempts and its raw hash matched the preserved human snapshot. The actual command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant treatment -Seed 42` launched with approved normal user-directory access. Its initial JSON exists at `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/effects-treatment-1791505836-787339.json`, version `rc005_v1`, configuration fingerprint `620b7deb4d37b790d538fb23635847bcd6e7029336745d27521ee451c5f79cb3`, with zero commands/restarts/notes at opening inspection.

S01-02 is a **limited one-Cast next-hand probe**, not a completed matched pair or the full-reset rule. The owner was instructed to enter/export their own prediction before Cast, cast once, export and report which new-hand card they would use first when rebuilding. The facilitator performs no gameplay. This fixture retains wires and disconnected Shield, unlike the selected policy; intended usefulness must not be reported as successful construction. Prediction/action/report remain pending at this entry. No runtime code or extra automated gameplay was introduced; documentation/link and prior-record-integrity checks suffice for this follow-up.

## October 9, 2026 — RC-006 full-reset follow-up available

**RC-006 still partial; normal gameplay unchanged.** The owner predicted doubled Spark damage, then reported damage matched, new cards were drawn, but the board should clear. The newer treatment record contains two Casts/four commands; first Cast12/cost3 consumes powered Spark into a straight wire and draws Conjure/Focus/Focus, then Conjure/install Free Spark7/Cast6. Its [unaltered snapshot](../output/playtests/rc-006/RC006-S01/effects-treatment-1791508590-4411584151-attempt04-snapshot.json) has SHA-256 `1e243f2519347a88b57320e9321ab022974ff90f7f5413bd42e8e1768cb47c38`. The owner exceeded the requested single Cast; actual actions and limits are retained. This is feedback on the original treatment, not validation of full-reset play or separate-hit preference.

### Additive experimental implementation

Added only `effects/full_reset`, version `rc006_full_reset_v1`, fingerprint at seed42 `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`. The menu now contains nine scenarios/twenty variants; historical RC-005 nine/nineteen remains intact. Existing normalized option dictionaries/setups and their fingerprints remain unchanged relative to the previously verified B1 neutral-copy repair. Normal training has no full-reset option or behavior change.

The new opening contains only Begin0/End14. Accepted Cast/Pass resolves combat, clears all non-endpoint pieces in cell order (permanent→discard, temporary→delete, connectors/special stock→empty), then ordinary hand/Undo cleanup, terminal result or refreshed energy/draw. Disconnected pieces and terminal turns clear; invalid/underfunded Casts do not. No anti-repeat draw logic was added. Loader rejects non-endpoint opening placements and missing/inconsistent metadata. Existing event boundaries are retained, with `board_piece_cleared` for connectors and concise UI cleanup feedback. A facilitator-only construction witness is available without revealing its steps in the player instructions.

Changed code: `scripts/core/{experiments,content_loader,combat}.gd`, experimental UI feedback in `scripts/ui/main.gd`, updated enumeration/witness handling in experiment tests, dedicated `tests/full_reset_tests.gd` and `tests/ui_full_reset_tests.gd`, and their core/UI suite registrations. New `.gd.uid` companions were generated by pinned-engine import. No production switch, route/transfer expansion or other rule selection is implemented.

### Actual validation

| Command / evidence | Result |
| --- | --- |
| Pinned Godot4.7.2, `--headless --script res://output/qa/rc-006-full-reset-checks.gd` with project path and unique absolute log | Final **71 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-full-reset-checks-20261009-02.log). Covers Cast/Pass, disconnected/card/temporary conservation, stock, history, rejection, terminal order, recycling, deterministic replay, legacy isolation, malformed new metadata/openings and input immutability. Earlier54-check log preserved before adding17 validation checks. |
| `--headless --script res://output/qa/rc-006-full-reset-ui-checks.gd` | **11 UI checks, 0 failures**, exit0. [UI log](../output/qa/rc-006-full-reset-ui-checks-02.log). Actual scene buttons build/cast, render clearing, save events, exact replay and Menu Pass with disconnected pieces; records use unique `output/qa/rc-006-full-reset-records/` paths, labelled automated. |
| `--headless --script res://output/qa/rc-006-full-reset-regression.gd` | **363 checks, 0 failures**, exit0. [Regression log](../output/qa/rc-006-full-reset-regression-02.log). Existing experiment content/combat, configuration and presentation coverage plus all19 normalized fixture fingerprints. B1 uses its already-repaired fingerprint, not a fabricated match to older hint text. |
| `--headless --editor --import` with unique absolute log | Exit0; new scripts imported and UID files generated. Existing Android build-tools warning only. [Import log](../output/qa/rc-006-full-reset-import.log). |
| `.\tools\godot.ps1 -Action capture -Experiment -Scenario effects -Variant full_reset -Seed 42 -CapturePath res://output/qa/rc-006-full-reset-opening.png` | Exit0, screenshot saved. [450×1000 capture](../output/qa/rc-006-full-reset-opening.png) inspected: only endpoints, curated three-card hand, available Split/Join, disabled Cast, readable controls and explicit testing-only label. New capture record labelled automated; guard confirmed no earlier same-name file would be overwritten. |

The first regression-audit runner stopped on a numeric recorder-fixture `version` compared with a string. That runner-only comparison was fixed with explicit string conversion; the failed log was preserved, then the successful run above completed. It was not a gameplay defect. UI wrapper refactoring was rechecked; no full original record-writing suite was run over earlier QA exports. The original29 raw exports and preserved human snapshots were checked for hash integrity. No Git operations occurred.

### Human follow-up and remaining limits

The verified command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant full_reset -Seed 42` opened a fresh owner session. The opening export `effects-full_reset-1791509340-605780.json` exists at the resolved user path with the new version/fingerprint and zero commands at initial inspection. It is an opening record, not a human result. The owner was invited to build freely, Cast/Pass and rebuild for two turns, then report whether new hands change their construction. No solution was shown.

The new combined-policy fixture changes starting topology and installed-card allocation, so it is not an isolated matched comparison with old effects control/treatment. Six energy, low repeated enemy damage, fixed endpoints, straight ports, aggregate hits and one pair remain fixture constants, not production approvals. Full-reset human outcomes, remaining rule decisions and complete production contract are pending; RC-007 is not generally ready. RC-010 remains independently available.

## October 9, 2026 — Full-reset human result and moving-endpoint follow-up

### Human evidence preserved

After the requested relaunch, S01-05 `effects/full_reset` recorded **43 accepted commands: 38 edits, three techniques and two Casts**. The owner reported “Yes, clearing is working and new hand also changes.” The [unaltered attempt43 snapshot](../output/playtests/rc-006/RC006-S01/effects-full_reset-1791509912-592636-attempt43-snapshot.json) has SHA-256 `7a6c9257034b342c4c11c955e195d9a67da84914d98da62863342c81062064c5`. Source: `C:/Users/nguye/AppData/Roaming/Godot/app_userdata/Rune Cast/experiments/effects-full_reset-1791509912-592636.json`; version `rc006_full_reset_v1`, seed42, unchanged fingerprint `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`.

First Cast12/cost2 uses Spark/Free Spark, clears four cells, takes3 retaliation and draws Focus/Spark/Conjure. The second uses a different longer route with Shield/Spark/Free Spark, deals12/cost3/shield5, blocks3, clears ten cells and draws Conjure/Spark/Conjure after reshuffling. Spark3 is immediately redrawn as allowed. Total recorded cost6 includes Focus1; neither cast uses Split. Both end with only Begin0/End14 and Undo0. No Pass, rejected command, embedded note, restart, terminal outcome or transition occurs. Command snapshots are continuous and totals agree; reasons for specific route choices are not inferred from edit counts.

The owner next said rebuilding was worthwhile because they also wanted Begin/End positions to change each turn, then selected random choice with rotation allowed. H14–H17 in [the results](rc-006-playtest-results.md) distinguish the positive subjective report, recorded fixed-endpoint actions and new design direction. The facilitator stated the interpretation as game-chosen positions/orientations at turn start, always connectable. This does not establish moving-endpoint enjoyment, a matched winner, durable novelty, or mobile usability.

### Separately versioned experimental implementation

Added `effects/moving_endpoints`, version `rc006_moving_endpoints_v1`, seed42 fingerprint `94ea5c516cb6de6f77f55e75c83053e5dfc7849fe1ed2da53d29b90321226512`. Current matrix is nine scenarios/twenty-one variants; all twenty earlier normalized setups retain their fingerprints, including the previously repaired B1 text and the human-played fixed full-reset setup. Normal gameplay rules are unchanged.

The new fixture preserves full-reset stats/cards and initial Begin0/End14, then selects uniformly from eligible entries in an eight-layout catalog where both endpoints change cells. Catalog paths and rotations are pinned in normalized options; each has a simple connection with a straight rune socket, and every layout has eligible successors. This is bounded variety, not arbitrary endpoint generation. Separate endpoint RNG uses `seed XOR 0x52434D45`, without consuming card RNG. Exact replay reseeds both; ordinary Restart restores the initial board and continues both streams.

Old-board/card cleanup happens before relocation; `endpoints_changed` records before/after layout IDs and endpoint cells/rotations before `turn_started` and draws. Terminal turns clear without choosing unused endpoints. Rejected commands, techniques, edits and Undo do not move them. New endpoint cells remain protected, vacated old cells are editable, and cards occupying new destinations are conserved through cleanup. Participant tooltip hides witness paths, while raw inspector/export retains them for audit. Latest feedback says endpoints moved; the Begin symbol follows its actual output direction.

Changed core: `scripts/core/{content_loader,experiments,combat}.gd`; presentation: `scripts/ui/{main,board_cell}.gd`; focused tests: `tests/{moving_endpoint_tests,ui_moving_endpoint_tests}.gd`, plus generic enumeration and core/UI registrations. New script UID companions were generated and verified. No production first-turn policy, catalog approval, terrain exception or other unresolved rule is implied by this fixture.

### Actual validation and launch

| Check / command | Result |
| --- | --- |
| Pinned Godot4.7.2 headless `--script res://output/qa/rc-006-moving-endpoint-checks.gd` | **77 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-moving-endpoint-checks-20261009-02.log). All eight layouts have independently constructed rune-capable routes; all56 permitted transitions covered. Mixed Cast/Pass replay, both RNG independence directions, Restart, cleanup/ownership, protection, terminal/rejected/edit/technique/Undo boundaries and malformed metadata covered. Earlier75-check log preserved. |
| `--script res://output/qa/rc-006-moving-endpoint-ui-checks.gd -- --moving-capture=res://output/qa/rc-006-moving-endpoint-turn2-02.png` | **18 UI/capture checks, 0 failures**, exit0. [Final UI log](../output/qa/rc-006-moving-endpoint-ui-02.log). Includes rendered movement, protection, vacated-cell edit, neutral tooltip, inspector export, exact replay and empty-board Menu Pass. Automated records use unique `output/qa/rc-006-moving-endpoint-records/` paths. Earlier headless17-check run also passed. |
| Headless `--script res://output/qa/rc-006-moving-endpoint-regression.gd` | **444 checks, 0 failures**, exit0. [Final regression log](../output/qa/rc-006-moving-endpoint-regression-02.log). Existing experiment/content/configuration/presentation and full-reset71 checks plus all20 prior fixture fingerprints. |
| `--headless --editor --import`, explicit project/log paths | Exit0; scripts imported and new test UIDs generated. [Import log](../output/qa/rc-006-moving-endpoint-import.log). Restricted `user://` profiler-directory warning and existing Android build-tools warning remain environment limitations. |
| Visual inspection of [turn2 capture](../output/qa/rc-006-moving-endpoint-turn2-02.png) | Only Begin1/End7 remain, with changed directions and Begin's downward symbol; three-card hand, disabled Cast, readable controls and relocation feedback. Capture succeeded despite restricted shader-cache-folder warning; no rendering failure observed. Earlier image retained before the directional-symbol correction. |

The command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant moving_endpoints -Seed 42` opened S01-06 with approved normal user-directory access and no startup error. Initial export `effects-moving_endpoints-1791510778-720169.json` exists in the verified human directory with the new version/fingerprint and zero commands. Opening-only SHA-256 `3ce4c7bd9eef0c38434cdabf3a9a17460031261be6391b8f6832aee9879be9da` is a point-in-time hash, not a final hash of an autosaving session. The owner is invited to build freely for two turns and report direction clarity and useful choices versus awkwardness. No known solution was shown; no moving-endpoint human result is claimed yet.

Original raw records and earlier human snapshots remain separate and unmodified; the current [local-link audit](../output/qa/rc-006-document-links.json) checks the synchronized handoff. No original record-writing suites were rerun over existing exports, and no Git operations occurred. **RC-006 remains partial, RC-007 not generally ready, RC-010 independently available.** Remaining evidence and contracts include B1/B2, C2/C3, D, transfer boundaries and final moving-endpoint production integration.

## October 9, 2026 — Player-controlled endpoint rotation and arbitrary positions

### Correction and preserved human evidence

The owner reported clearing worked, then clarified that Begin/End should rotate like normal pieces and appear anywhere, including next to each other. This corrects the facilitator's earlier interpretation of game-selected, protected rotations. It is an explicit C1 design choice, not approval of the eight-layout restriction or a reported enjoyment/readability result.

The initial S01-06 moving-endpoint file remains zero-command; its [opening snapshot](../output/playtests/rc-006/RC006-S01/effects-moving_endpoints-1791510778-720169-attempt00-snapshot.json) matches the opening hash above. A later active S01-07 file supplies [25 preserved attempts](../output/playtests/rc-006/RC006-S01/effects-moving_endpoints-1791511346-568465250-attempt25-snapshot.json), SHA-256 `d53053bfc710e8356dc31c769b55aeca42ae3e7648060da4b989b6a4fe4ccedb`: eight edits, one Cast6/cost2, eleven rejected endpoint Rotate attempts, and five Passes. Cast clears four cells and moves endpoints0/14→1/7. Five Begin1 and six End7 rotations are rejected. Empty-board Passes advance to turn7, player22HP/enemy30HP; no notes, restart, techniques, terminal outcome or transition. This corroborates the interaction mismatch without inferring frustration or reasons for Pass. Records remain distinct rather than merging the opening-only and played files.

### Corrected opt-in implementation

Added `effects/free_endpoints`, version `rc006_free_endpoints_v1`, seed42 fingerprint `9c83d6c3c90601b6abbfaaf110ae3195c12f705b2eb23a4ba91d68aade6dd005`. All21 earlier fixture fingerprints are preserved; current menu has nine scenarios/twenty-two variants. Normal gameplay rules are unchanged.

Initial placement samples uniformly from all240 ordered distinct-cell pairs. Subsequent surviving Cast/Pass selects among211 pairs moving both endpoints from their own previous cells, including cross-swaps and adjacency. Each starting orientation is sampled independently0–3 and may face off-board. Normal Rotate turns either endpoint90 degrees, updates its ports, and supports existing Undo/history semantics without changing cards/energy/RNG. Endpoint replacement, Erase and Flip remain prohibited. Every positional pair has a rune-bearing connection after suitable rotations/building; no promise that every generated orientation is already connectable. Direct facing neighbors retain the existing valid zero-damage connection, with no added minimum-path/rune requirement.

Initial placement is in the recorded initial state rather than an action event. After a surviving turn, card/board cleanup precedes `endpoints_changed`, then `turn_started` and normal draws. Terminal and rejected actions do not relocate; manual edits cannot consume endpoint RNG. Endpoint/card streams remain separate; Exact replay resets both, Restart continues them and selects a new random opening. Metadata pins `random_any_cells`, player rotation, random initialization, selection algorithm ID,240 initial/211 successor counts. No route catalog or solution is exposed in participant help.

Changed core: `scripts/core/{content_loader,experiments,combat}.gd`; UI: `scripts/ui/main.gd` endpoint selection/tooltip/Guide guidance; dedicated `tests/{free_endpoint_tests,ui_free_endpoint_tests}.gd`, generic enumeration/witness support and core/UI registrations. Clicking an endpoint clears a held placement tool/card and selects it for Rotate. The Guide's old blanket protection sentence now has a new-variant exception; all earlier guide behavior is retained. Facilitator-only solution actions accept a seed and construct a rune-bearing path for the actual random opening. New script UID companions are generated and verified.

### Actual validation

| Command / evidence | Result |
| --- | --- |
| Pinned Godot4.7.2 headless `--script res://output/qa/rc-006-free-endpoint-checks.gd` | **74 checks, 0 failures**, exit0. [Final core log](../output/qa/rc-006-free-endpoint-checks-20261009-03.log). Independently built affordable Spark routes for all240 positional pairs; all211 successor sets/cross-swaps, adjacency/direct zero-damage connection, Rotate/Undo/history limit, protection, cleanup/conservation, terminal/rejected behavior, RNG independence, Restart and exact record replay. |
| `--script res://output/qa/rc-006-free-endpoint-ui-checks.gd -- --free-capture=res://output/qa/rc-006-free-endpoint-adjacent-03.png` | **23 UI/capture checks, 0 failures**, exit0. [Final UI log](../output/qa/rc-006-free-endpoint-ui-capture-03.log). Actual click/Rotate/Undo on both endpoints, held tool/card selection, Guide, Cast, replay, Pass, inspector/export and adjacent seed9. Automated record paths are unique under `output/qa/rc-006-free-endpoint-records/`. |
| Headless `--script res://output/qa/rc-006-free-endpoint-regression.gd` | **536 checks, 0 failures**, exit0. [Regression log](../output/qa/rc-006-free-endpoint-regression-01.log). Existing experiment/configuration/presentation, full-reset71, moving-endpoint77 and all21 earlier fingerprints. |
| Read-only facilitator solution probe, seeds0–63 | Every generated opening solution is accepted, valid and6damage/cost2. [Probe log](../output/qa/rc-006-free-endpoints-core-probe-02.log). No participant record produced. |
| Editor import and generated UID inspection | Exit0; both new test UIDs exist. [Import log](../output/qa/rc-006-free-endpoint-import.log). Restricted user-directory profiler warning and existing Android build-tools warning remain environment limitations. |
| Visual inspection of [final adjacent capture](../output/qa/rc-006-free-endpoint-adjacent-03.png) | Seed9 is correctly shown in input and active label; End1 and Begin5 are neighbors. Begin is selected after normal Rotate, its symbol/port point left, instructions are readable and the board contains only endpoints. Capture succeeded despite restricted shader-cache warning. |

Earlier focused-check logs are preserved: an initial type-annotation parse issue in the new test was corrected; a second test incorrectly compared relocated endpoints with the normal fixed-position evaluator, then was corrected to compare with the existing dynamic-endpoint experiment evaluator. No gameplay defect was indicated by those test-runner issues. UI coverage was expanded after review found the stale Guide sentence. The adjacent UI probe now enters its seed through normal Launch controls, keeping the displayed input and active seed consistent. No full record-writing suites were run over earlier raw evidence.

### Human rotation confirmation and next block

The command `.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant free_endpoints -Seed 42` launched S01-08 with approved normal user-folder access and no startup error. Source `effects-free_endpoints-1791512378-674454.json` was initially zero-command, opening hash `3375c4afe5f6553c409c5270f120274b2b9840187a5f36e7d93ab1e3824240bf`. After click/Rotate guidance, the owner replied **“Yes it is working.”** The [seven-command snapshot](../output/playtests/rc-006/RC006-S01/effects-free_endpoints-1791512378-674454-attempt07-snapshot.json), SHA-256 `e8a68cf3d9053683ae3659e6003e5184ae25cdd18b1606e7c5b455dae9a0935e`, contains three accepted Begin6 rotations and four accepted End15 rotations. No Cast, Pass, Undo, other edit, technique, rejection, notes or lifecycle event appears. This confirms manual controls, not completion of the requested build/next turn or adjacency/rebuilding enjoyment.

After preserving that snapshot, `.\tools\godot.ps1 -Action run -Experiment -Scenario split_inventory -Variant treatment -Seed 42` opened S01-09 for B1. Initial source `split_inventory-treatment-1791512571-688570.json` has zero commands and the existing neutral-copy fingerprint `639da6f6626f5d7dcc40fd709f8f4cea82c7cb0ca4acab696a1e0758f1842e0d`. The owner was explicitly told this stock comparison uses a retained sample circuit and does not reverse selected clearing/endpoint rules. They are asked to explore the extra pair freely and state expected damage/cost before Cast; no known solution shown. One-pair control and comparison remain pending.

No Git operations occurred. Raw records, historical reports and snapshots are preserved; automated tests remain distinct from one owner's evidence. RC-006 remains partial and RC-007 is not generally ready; RC-010 is independently available. B1/B2, C2/C3, hit feedback, transfer boundaries and the final combined production contract remain unresolved.

## October 9, 2026 — RC-006 B1 human results and circuit-kit proposal

Preserved the owner's extra-pair screenshot and S01-10 treatment record as unaltered copies. [Treatment attempt12](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-1791512908-337653853-attempt12-snapshot.json), SHA-256 `330fa3ab71e451ba83c6161dd4316dda4dd1436d3005a5648b7315fe0555b820`, has twelve accepted commands: ten edits, one Cast18/cost4 and one Conjure. The two-pair circuit carries three copies of Spark6 to End and resolves one aggregate hit; enemy36→18/player40→37. [Screenshot](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-owner-screenshot-20261009.png), SHA-256 `2007ab454b3e5d58ab57baef718259a951e8b25f470dbee28ef9c81c73983475`, matches the final state and the supplied source image byte for byte. The owner said the extra-pair construction worked as expected. This is a retrospective report without a numeric pre-Cast prediction.

Launched `.\tools\godot.ps1 -Action run -Experiment -Scenario split_inventory -Variant control -Seed 42` with approved normal user-folder access. S01-11 source `split_inventory-control-1791513150-645708.json` initially had zero commands, opening hash `5ece9cf0e1a9f2773f8bd09595e58ae5bda7d2327d9616c841d938a0edf7866d`, fingerprint `361b22fd5bb6424f5af792ec0ed73882d91ccdbb8219da00afd1f345a825b24f`. After the human's free build, [control attempt06](../output/playtests/rc-006/RC006-S01/split_inventory-control-1791513150-645708-attempt06-snapshot.json), SHA-256 `83f6cf191f7ced6cebc620189c73e63445eebfef1169b4e2c3be28b0686eb880`, records five edits and one Cast6/shield10/cost4, blocking incoming3 and keeping player40HP. The owner reported “It work as expected.” Again no numeric pre-Cast prediction was supplied. Both records conserve permanent UIDs0–7 throughout. Initial states differ only in available stock; the resulting offense/defense constructions differ, so damage totals do not isolate stock benefit.

H30 asks for a limited/random supply mechanic instead of selecting one/two pairs. The documented **unselected proposal** uses three equally likely ten-piece kits: Straight/Corner/Split/Join counts6/2/1/1,4/4/1/1,4/2/2/2. A pure JavaScript abstract path enumeration visited all240 ordered distinct endpoint pairs on the4×4 grid and found a simple path for each with at most four interior straight cells, two corner cells and at least one straight socket; no missing pair. Search allowed orthogonal neighbors, no repeated cell, and at most eight path cells. This supports only the basic geometric supply claim with manual endpoint rotation and no obstacles. It is not an engine test, human result, balance finding or proof every rune hand has a useful affordable Cast.

This update changes evidence/documentation only. No gameplay code or Godot test suite rerun; earlier633 checks remain historical verification. The stock proposal is not implemented or selected. B2 and the other unresolved decisions remain open, RC-006 stays partial and RC-007 is not generally ready. Raw-evidence preservation and local-link checks are recorded in the linked audit outputs below. No Git operations occurred.

- [Preservation audit](../output/qa/rc-006-b1-human-preservation.json): all29 original QA records,19 exploration copies,eight frozen human JSON snapshots and one supplied PNG retain their expected hashes; the PNG also matches its original attachment. Zero failures.
- [Local documentation audit](../output/qa/rc-006-document-links.json): README and17 documentation files checked, including local target paths and Markdown anchors; zero broken references.

## October 9, 2026 — RC-006 provisional kit selection

H31 records the owner's acceptance of the three random ten-piece kits: “Okay, let's keep it like that for now.” Updated the evidence register, B1 selection/stock contract and acceptance cases, dated decisions, current-versus-future gameplay notes, project handoff, experiment notes, design, roster and README. The selected prototype counts are Straight/Corner/Split/Join6/2/1/1,4/4/1/1,4/2/2/2. Separate rune ownership, finite stock accounting and no banking remain explicit. Quantities/probabilities are tuning values; no new kit play, B2 cost selection or testing waiver is claimed.

Documentation-only change: no source code, raw records, stable content IDs or budgets changed, and no Godot tests or Git operations were run. The [local-link audit](../output/qa/rc-006-document-links.json) covers current target paths and Markdown anchors. Earlier engine checks and evidence hashes remain historical records. RC-006 stays partial; RC-007 is not generally ready because the other decisions and complete integration are unresolved.

## October 9, 2026 — RC-007 reconciliation and finite-stock groundwork

**Status: partial, pending the consolidated owner rule answer.** No post-H31 evidence closes the remaining decisions; the current request reconfirms first-turn empty setup and equal kit probabilities. Implemented only independent connector definitions, finite inventory/editing, UI labels/Guide and QA preservation. Normal production reset, per-turn kit scheduling, endpoint RNG policy and encounter entry remain unintegrated. This is automated desktop evidence, not a human playtest or a testing waiver.

Before gameplay changes, inventoried 98 existing human/QA evidence and asset files. Two existing test suites had fixed JSON export destinations; changed only their destinations to unique RC-007 QA subdirectories before running the baseline. Automated experiment capture records now also use unique QA paths. Human `user://experiments/` paths are unchanged, and no raw study file was rewritten.

| Separate pinned-engine action | Actual result / evidence |
| --- | --- |
| `tools/godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0; [final version](../output/qa/rc-007/final-version.log). No override or upgrade. |
| Baseline `-Action import` | Exit 0, but sandbox could not access the editor user-data directory. Normal local-access rerun exit 0 without that error; [local import](../output/qa/rc-007/baseline-import-local.log). Android build-tools warning remains. |
| Baseline `-Action test` | **737 checks, 0 failures**, exit 0; [baseline core](../output/qa/rc-007/baseline-test.log). |
| Baseline `-Action smoke` | Sandbox run failed sound-settings persistence and could not create a user-data fixture (241 checks, 1 failure, script diagnostic). Normal local-access rerun: **247 checks, 0 failures**, exit 0; [sandbox result](../output/qa/rc-007/baseline-smoke.log), [local result](../output/qa/rc-007/baseline-smoke-local.log). These precede implementation and are environment failures, not regressions. |
| Baseline `-Action capture -CapturePath res://output/qa/rc-007/baseline-training.png` | Exit 0; [baseline capture log](../output/qa/rc-007/baseline-capture.log). |
| Final `-Action import` | Exit 0 using normal local access; [final import](../output/qa/rc-007/final-import.log). Existing Android warning only. |
| Integrated `-Action test` | **926 checks, 0 failures**, exit 0; [integrated core](../output/qa/rc-007/integrated-test.log). Includes 175 connector-definition/editing checks and 14 assertions over 720 exhaustive geometry cases. |
| Final `-Action smoke` | **289 UI checks, 0 failures**, exit 0 with normal local access; [final smoke](../output/qa/rc-007/final-smoke.log). Includes 42 new finite-stock/Guide checks. Intentional invalid-startup diagnostics remain expected. |
| Final `-Action capture -CapturePath res://output/qa/rc-007/final-training.png` | Exit 0; [final capture log](../output/qa/rc-007/final-capture.log). |
| Rendered finite-stock fixture | **43 UI/capture checks, 0 failures**, exit 0; [runner](../output/qa/rc-007/finite-stock-capture.gd), [log](../output/qa/rc-007/finite-stock-render-final.log). Runs the actual scene, controls, Guide and screenshot save; no participant record. |

The existing core/UI runners already included the RC-006 full-reset, moving-endpoint and free-endpoint suites. They remain registered and unchanged. Their Cast/Pass, cleanup, terminal, endpoint Rotate/Undo, exact replay, Restart, encounter-pair, ownership, input-lock and stale-callback assertions still pass; these are historical fixture checks, not proof of integrated production rules. The new tests cover all three kit definitions, malformed/partial finite configuration, detached inputs/snapshots, injected-stream reproducibility, permitted repeats, all four stock caps, disconnected reservations, same-/cross-type replacement, rune refunds, erase, Rotate/Flip and Undo. Existing 12-damage opening assertions stay valid because normal default migration is explicitly pending.

The independent geometry search command-builds a supplied straight-Spark route for **240 ordered endpoint pairs × 3 kits = 720 cases**. Each kit includes all 48 ordered horizontal/vertical adjacencies; 180 Begin and 180 End cases start outward at a boundary and are repaired by ordinary Rotate. Actual piece ports are checked after Rotate/Flip. Each route is then surrounded by the remaining disconnected kit pieces, exhaustion is rejected for every type, and erasing the extras restores the route. No runtime solver, hidden reroll or extra piece is introduced. This establishes geometric feasibility with a supplied rune, not affordability, useful random hands, balance or human experience.

Visually inspected fresh 450×1000 [baseline training](../output/qa/rc-007/baseline-training.png), [final training](../output/qa/rc-007/final-training.png) and [finite-stock fixture](../output/qa/rc-007/finite-stock.png) images. Training remains pixel-identical: SHA-256 `17f12203709ab5df2d6dc39900f5464ddac96369b3d328c5d6bd563176f13de2`. The finite fixture shows Straight 5/6 after one disconnected placement, Corner 2/2, Split 1/1, Join 1/1, an incomplete-board Cast button, and the unchanged placeholder composition. It is clearly titled `FINITE STOCK QA`; its fixed endpoints/curated hand are test scaffolding, not a final production selection.

[Preservation results](../output/qa/rc-007/preservation-results.json): all **98** previously inventoried evidence/assets retain their SHA-256 hashes; all **22** seed-42 historical experiment configuration fingerprints match [before](../output/qa/rc-007/fixture-fingerprints-before.json) and [after](../output/qa/rc-007/fixture-fingerprints-after.json). The initial standalone fingerprint probe emitted a log-path/user-data diagnostic but successfully wrote its audit; rerunning with an absolute workspace log path completed cleanly. No historical experiment version, definition ID or approved image changed.

The first discovery command included a read-only `git status --short` before the pasted prohibition had been read. This was immediately disclosed; no later Git operations, staging, commit or checkpoint occurred. No mobile SDK installation, packaging, physical-device acceptance, assets, animation/audio, run/reward/save systems or later-task implementation is claimed. Pending owner choices and the exact continuation boundary are in the [RC-007 handoff](project-plan.md).

Documentation QA checked 326 relative file links across 11 updated documentation files, with zero missing targets; [results](../output/qa/rc-007/document-links.json). This check covers file existence, not Markdown anchors.

## October 9, 2026 — RC-007 accepted defaults and completed production integration

**RC-007 complete.** The owner answered “Accept all default.” to the consolidated seven-choice proposal. H32 records this as a design decision, not human-playtest evidence or a testing waiver. The [precise accepted contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract) was written before dependent integration. Earlier pending-status entries above are preserved as historical records. The [completed handoff](project-plan.md#october-9-2026--rc-007-production-rules-complete) identifies the delivered files, scope and next tasks.

Normal launch now loads `data/production_encounter.json`: endpoints-only turns, random rotatable endpoints, normal first/later draws, independent random finite kits, Split1/Join0, straight effect ports, no blocked cells, aggregate damage and complete board/hand cleanup. Terminal cleanup generates no unused turn; one configured victory transition conserves permanent UIDs and current/max HP. The original prefilled 12-damage opening is retained explicitly through `-Encounter res://data/encounter.json`. Historical assertions now select that fixture; their expected behavior was not weakened.

Before final integration, a fresh baseline imported successfully and passed **926 core / 289 UI checks**, zero failures: [import](../output/qa/rc-007/implementation/baseline-import.log), [core](../output/qa/rc-007/implementation/baseline-test.log), [UI](../output/qa/rc-007/implementation/baseline-smoke.log). All automated records/captures continue using isolated QA destinations. Inventoried 193 pre-existing evidence/asset files, including the earlier RC-007 preparation evidence, before changing production behavior.

The required launcher actions were run separately with the pinned engine and normal local user-directory access:

| Action | Final actual result |
| --- | --- |
| `.\tools\godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0; [log](../output/qa/rc-007/implementation/final-version.log). |
| `.\tools\godot.ps1 -Action import` | Exit 0; existing Android build-tools warning only; [log](../output/qa/rc-007/implementation/final-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 checks, 0 failures**, exit 0; [log](../output/qa/rc-007/implementation/final-test.log). |
| `.\tools\godot.ps1 -Action smoke` | **333 UI checks, 0 failures**, exit 0; [final rerun](../output/qa/rc-007/implementation/final-smoke-02.log). Expected invalid-configuration diagnostics remain part of safe-startup tests. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-007/implementation/final-production.png` | Exit 0 and screenshot saved; [log](../output/qa/rc-007/implementation/final-capture.log), [image](../output/qa/rc-007/implementation/final-production.png). Explicit fresh destination preserves older captures. |

The [first final smoke run](../output/qa/rc-007/implementation/final-smoke.log) recorded 333 checks with one failure: the new Rotate-direction feedback changed an explicitly historical endpoint fixture's expected guidance. Restricting that wording to production restored historical behavior; the final rerun above passes. Independent review also found that the Cast tooltip still predicted incoming damage on a lethal spell. It now reports zero incoming and has an actual-scene regression assertion. Intermediate logs remain preserved; neither issue is hidden as a pre-existing failure.

Focused production [core verification](../output/qa/rc-007/production-combat-final.log) passes **82 checks**; [content validation](../output/qa/rc-007/implementation/content-tests.log) passes **55 checks**. These counts are included in the full core suite, not additional totals. Coverage includes powered/disconnected permanent/temporary cleanup after Cast and Pass, physical cost/UID deduplication under amplification, zero/requested/applied damage, lethal/shield order, empty pools/immediate repeats, terminal/rejected boundaries, independent RNG sequences, Restart/Exact replay, detached data and guarded compatible encounter transfer.

[Geometry verification](../tests/connector_geometry_tests.gd) now runs the actual production model for **240 ordered endpoint pairs × 3 kits = 720 cases**, with one explicitly supplied straight Spark and naturally selected seeds for each kit. Its 14 aggregate assertions are included in the full suite. Each kit covers all 48 ordered adjacencies and 180 outward-facing starting directions for each endpoint. Ordinary commands build/rotate/flip the route, fill disconnected stock to exhaustion, reject excess placement, erase extras and verify all three RNG states stay unchanged. Core tests separately cover all endpoint rotations and all 48 direct zero-effect adjacency routes. This establishes bounded geometry and accounting, not random-hand usefulness, affordability or kit balance; no runtime reroll, solver or extra piece is added.

The final rendered [actual-scene run](../output/qa/rc-007/production-ui-implementation-04.log) passes **52 checks, 0 failures**, including eight captures. It exercises opening/build/Cast, incomplete-board Pass, changed turns, adjacency, stock exhaustion/Undo, victory/defeat, Restart, Exact replay, configured encounter entry and stale controller callbacks. Visually inspected the [opening](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-opening.png), [Guide](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-guide.png), [built circuit](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-built.png), [next turn](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-turn2.png), [adjacency](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-adjacent.png), [victory](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-victory.png), [defeat](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-defeat.png) and [successor](../output/qa/rc-007/implementation-ui-1791517855-6264-1588606/production-next-encounter.png). Stock/hand/pile labels, selected directions, reset guidance and controls fit the unchanged portrait composition. The successor displays the Wisp with carried 30/30 HP, four energy and two cards. The standalone renderer reports a sandbox shader-cache folder warning, but all rendered checks and saves complete; the separate launcher capture succeeds cleanly.

The [final preservation audit](../output/qa/rc-007/implementation/preservation-results.json) confirms **193 unchanged file hashes and all 22 unchanged historical experiment fingerprints**; [current fingerprints](../output/qa/rc-007/implementation/fixture-fingerprints-current.json) match the preserved before audit. Stable production IDs, original fixture documents, raw human records, historical exports and approved images remain intact. No new participant findings, physical-device acceptance, engine upgrade, SDK installation, packaging, production art/animation/audio or later progression systems are claimed. The Android warning remains separate from desktop success. No Git operations occurred during this integration phase; the initial read-only exception disclosed in the earlier entry remains on record.

Kit quantities/probabilities, arbitrary-position rebuilding quality and starter difficulty remain tuning risks. There are no remaining RC-007 implementation blockers. **RC-008, RC-009, RC-010, RC-024 and RC-033** are next-ready under the updated plan; external platform/device requirements still apply to RC-021/RC-022.

Final [documentation audit](../output/qa/rc-007/implementation/document-links.json) checks 13 updated documents and 432 relative file links, with zero missing targets. This covers file existence, not Markdown anchors.

## October 9, 2026 — RC-008 touch inspection complete

**RC-008 is complete.** The [touch interaction contract](touch-interactions.md) and [handoff](project-plan.md#october-9-2026--rc-008-touch-inspection-complete) describe the delivered behavior. Production/core rules, controller command/event ordering, distributions, ownership and historical experiment semantics remain unchanged. The user-requested no-Git exception and device limitations are recorded below.

### Fresh baseline before editing

Read the requested architecture/rules/content/visual documents, the latest RC-007 handoff, project configuration and launcher, and inspected the approved Combat reference. No applicable `AGENTS.md` was found in the project or its parent locations. Baseline records use a separate `output/qa/rc-008/` directory. Existing fixed-name launcher logs were archived before running commands and restored after verification.

| Baseline action | Actual result |
| --- | --- |
| `-Action import` | Exit 0, but restricted user-data access emitted a `user://` error; existing Android build-tools warning also appeared. [Log](../output/qa/rc-008/baseline-import.log). Final normal-access import below is clean apart from the known Android warning. |
| `-Action test` | **1063 checks / 0 failures**, exit 0. [Log](../output/qa/rc-008/baseline-test.log). |
| `-Action smoke`, restricted | Exit 1, **327 checks / 1 failure** plus a null file-write script error: settings persistence and the temporary invalid-content fixture could not write to `user://`. This incomplete environment-blocked run is preserved in its [log](../output/qa/rc-008/baseline-smoke.log). |
| `-Action smoke`, normal local access | **333 UI checks / 0 failures**, exit 0. Expected invalid-content diagnostics only. [Log](../output/qa/rc-008/baseline-smoke-normal-access.log). This is the valid pre-edit UI baseline. |
| Baseline rendering | [450×1000 normal preview](../output/qa/rc-008/baseline-normal.png) and [360×640 smaller window](../output/qa/rc-008/baseline-small.png), both saved successfully and inspected. |

The baseline showed compact cards with no visible touch inspector and eight small editing controls in one row. Source/input-path inspection confirmed immediate technique activation and no scroll/hold arbitration around card/board Button signals. A real native-window inspection succeeded, but the attempted click returned `SendInput sent 0 of 1 events; GetLastError=87`; the refreshed capture was not reliable for the intended window. Native input attempts stopped. Thus there is no successful manual technique/scroll test to infer from that attempt.

### Final required commands

Each launcher action was executed separately from PowerShell in `C:\Dev\RuneCast`, with actual output and exit status inspected. Normal local user-directory access was used for import/UI/rendering when required; no SDK or engine upgrade was performed.

| Command | Actual final result |
| --- | --- |
| `.\tools\godot.ps1 -Action version` | `4.7.2.stable.official.ed1daf0bf`, exit 0. [Log](../output/qa/rc-008/final-version.log). |
| `.\tools\godot.ps1 -Action import` | Exit 0. Existing `Unable to open Android 'build-tools' directory` warning; no script import error. [Log](../output/qa/rc-008/final-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 core checks / 0 failures**, exit 0. [Log](../output/qa/rc-008/final-test.log). |
| `.\tools\godot.ps1 -Action smoke` | **503 UI checks / 0 failures**, exit 0. [Final rerun](../output/qa/rc-008/final-smoke-02.log). Deliberately missing/invalid startup diagnostics are expected test coverage. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-008/final-production.png` | Exit 0; screenshot saved successfully to a new path. [Log](../output/qa/rc-008/final-capture.log), [normal launch](../output/qa/rc-008/final-production.png). |

The final core count retains all existing checks, including production geometry/accounting and historical rules. The UI count is the existing **333**, plus **67** read-only inspection/availability checks, **30** gesture arbitration checks and **73** actual-scene touch/lifecycle checks. Coverage lives in [inspection_data_tests.gd](../tests/inspection_data_tests.gd), [touch_router_tests.gd](../tests/touch_router_tests.gd) and [ui_touch_tests.gd](../tests/ui_touch_tests.gd), wired into [ui_smoke.gd](../tests/ui_smoke.gd). These include:

- Every hand/installed rune, technique, connector and endpoint description; configured costs/values/ports/stock and profile-specific cleanup; snapshot/RNG/UID/history purity.
- Real `Viewport.push_input` routing for short taps versus holds, exactly-at-threshold motion, scroll cancellation, cancelled release, multiple pointers and emulated touch/mouse suppression. Deterministic timing advances the production hold path; no fragile hold sleeps.
- Modal background blocking, scroll isolation, Close/Escape without click-through, keyboard focus trapping, native Guide scrolling, missing OS release after focus loss and fresh input recovery.
- Legal incomplete placement versus protected/exhausted targets, replacement/refund/Undo labels, endpoint direction and Undo, selection cancellation, technique energy/history boundaries and a validated 14-card hand scrolled to its last item.
- Busy presentation, late callbacks, turn/reset/Exact replay/encounter entry, historical experiment relaunch with synchronous cancellation reentry, scene teardown and safe invalid-content startup.
- Details / Pass consequence confirmation, exactly one accepted Pass, and stale confirmation rejection after Restart.

Intermediate evidence is retained. [Integration run 01](../output/qa/rc-008/integration-smoke-01.log) had nine assertions failing on changed inventory/endpoint feedback wording; restoring compatible wording with clearer reasons fixed them, and [run 02](../output/qa/rc-008/integration-smoke-02.log) passed all then-integrated 421 checks. Subsequent checks caught narrow-screen row overflow; navigation wrapping and responsive board sizing fixed it. A hidden native Guide label still contributed a large minimum height; limiting its visible lines and rendering the body in a scroll container fixed the [reviewed Guide](../output/qa/rc-008/guide-scroll-02.png). Visual review also shortened the narrow Cancel label and moved placement markers beside, rather than over, End's value. The final 503-check rerun and fresh rendered suite include these fixes.

### Rendered interaction evidence

Ran the pinned executable separately with `--path . --script res://tests/ui_touch_capture.gd` and a dedicated RC-008 log path. [Final rendered log](../output/qa/rc-008/touch-render-final-02.log): **82 synthetic touch UI/capture checks / 0 failures**, exit 0. This repeats the **73** scene interaction checks and adds **nine screenshot-save checks**; it is not 82 extra unique tests beyond the UI suite. Earlier restricted rendered runs reported a shader-cache access warning; the final normal-access rendered run does not. The deliberate missing-content diagnostic remains expected.

The following final states were visually inspected. The controlled scene uses a valid deterministic setup with both card types for repeatable inspection; the 14-card hand is an explicitly validated QA fixture, not a changed production opening. Ordinary standalone launch is separately captured above.

| State | Final evidence |
| --- | --- |
| Selected tool, eligible `+` cells and protected `x` endpoints | [720×1600 preview](../output/qa/rc-008/touch-capture-1791519954-3060/selected-tool-preview.png) |
| Selected/rotated Begin, direction feedback and actual editing availability | [Endpoint](../output/qa/rc-008/touch-capture-1791519954-3060/selected-rotated-endpoint.png) |
| Rune cost, ports and ownership/cleanup explanation | [Rune inspector](../output/qa/rc-008/touch-capture-1791519954-3060/inspect-hand-rune.png) |
| Technique effect/payment and explicit inspection safety | [Technique inspector](../output/qa/rc-008/touch-capture-1791519954-3060/inspect-hand-technique.png) |
| Exhausted stock, legal same-kind replacement and rejected new placement | [Unavailable stock](../output/qa/rc-008/touch-capture-1791519954-3060/unavailable-stock.png) |
| Larger hand, visible horizontal scrollbar and selected last card | [14-card hand](../output/qa/rc-008/touch-capture-1791519954-3060/large-hand-scrolled.png) |
| Small viewport with board/edit controls fitting horizontally | [360×640 board](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-board.png) |
| Small inspector with independent content scrolling and fixed Close | [360×640 inspector](../output/qa/rc-008/touch-capture-1791519954-3060/small-portrait-inspector.png) |
| Explicit enemy consequence and separate Pass confirmation | [Pass confirmation](../output/qa/rc-008/touch-capture-1791519954-3060/pass-confirmation.png) |

The normal 450×1000 preview preserves the substantial enemy arena and compact name/symbol/value cards. Extra editing rows remain labeled and reachable; the small viewport scrolls vertically, so not every area is visible simultaneously. Inspector content and background scrolling are separated. No permanent forecast strip, production artwork or screen redesign was added.

### Preservation and limits

The [preservation audit](../output/qa/rc-008/preservation-results.json) verifies **506 / 506** pre-existing output/evidence, asset and content file hashes unchanged against the [pre-edit manifest](../output/qa/rc-008/preservation-before.json). This includes the approved reference images, historical captures, experiment definitions and previous raw evidence. Launcher logs at their old fixed filenames were preserved through pre-run copies and restored after verification; all new evidence is separately named. No historical human finding was rewritten or inferred.

The computer-use skill was used to attempt native Windows testing. Input injection failed as recorded above; manual native interaction remains unverified. **All touch acceptance here is synthetic desktop input plus rendered QA. No physical touch device was available**, and no mobile packaging, SDK installation, OS/device minimum, safe-area acceptance or device usability result is claimed. Physical gesture feel, text scaling and platform lifecycle remain RC-021/RC-022 and their later acceptance tasks, including RC-023/RC-044. The existing Android build-tools warning is a platform setup limitation, not a failed desktop gameplay check.

The initial discovery command included one read-only `git status --short` before the pasted no-Git restriction was read. It returned no changes and was disclosed immediately; no subsequent Git operations, commit or checkpoint occurred. The owner retains Git responsibility.

Next-ready: **RC-009**, independently available **RC-010**, **RC-024** and **RC-033**, with platform access still conditional as recorded in the [current plan](project-plan.md).

Documentation QA checked six updated documents and 342 relative file links, with zero missing targets (output/qa/rc-008/document-links.json). This checks file existence, not Markdown anchors.

## October 9, 2026 — RC-009 board identities and construction examples

**RC-009 complete.** The [board catalog](board-catalog.md) distinguishes four stable identities, a sampled runtime layout and an authored example. All four identities use the same accepted random geometry, costs, starter resources and three equally probable finite kits. They do not create different mechanical difficulty. Normal launch remains the existing production encounter. Four clearly labeled development encounters reuse the existing Shadeling/starter catalogs; no final enemies, tower progression, environment art or lighting were added.

### Fresh baseline and environment

Read the applicable project/parent instruction locations (no `AGENTS.md` found), requested design/rules/architecture documents, latest RC-007/RC-008 handoffs, current production data, model/controller/circuit code and existing tests/launcher before implementation. Inspected test/capture output behavior; legacy helper suites use unique paths, while new RC-009 logs, scripts, reports and captures use `output/qa/rc-009/`. Archived fixed-name launcher logs before the baseline and restored them after verification. A pre-edit manifest recorded **897 existing output/evidence, asset and content hashes**.

| Baseline command | Actual result |
| --- | --- |
| `.\tools\godot.ps1 -Action import` | Exit 0; restricted `user://` access error and existing Android build-tools warning. [Baseline import](../output/qa/rc-009/baseline-import.log). |
| `.\tools\godot.ps1 -Action test` | **1063 checks, 0 failures**, exit 0. [Baseline core](../output/qa/rc-009/baseline-test.log). |
| `.\tools\godot.ps1 -Action smoke` with normal local user-directory access | **503 UI checks, 0 failures**, exit 0. Expected missing/invalid-content diagnostics. [Baseline UI](../output/qa/rc-009/baseline-smoke.log). |

A [normal-access import retry](../output/qa/rc-009/import-normal-access.log) exited 0 with only the existing `Unable to open Android 'build-tools' directory` warning. The restricted user-directory message was an environment limitation, not a gameplay regression. No engine upgrade or mobile SDK installation occurred.

### Final required commands

Run separately in PowerShell from `C:\Dev\RuneCast`, with output and exit statuses inspected. `-LogDirectory` is a new optional launcher output path; it prevents replacing the old fixed-name logs. Import/UI/rendering used normal local user-directory access.

| Exact command | Actual final result |
| --- | --- |
| `.\tools\godot.ps1 -Action version -LogDirectory output/qa/rc-009/final-engine` | **4.7.2.stable.official.ed1daf0bf**, exit 0. [Version](../output/qa/rc-009/final-version.log). |
| `.\tools\godot.ps1 -Action import -LogDirectory output/qa/rc-009/final-engine` | Exit 0; existing Android build-tools warning only, no script import error. [Import](../output/qa/rc-009/final-import.log). |
| `.\tools\godot.ps1 -Action test -LogDirectory output/qa/rc-009/final-engine` | **1363 checks, 0 failures**, exit 0. [Core](../output/qa/rc-009/final-test.log). |
| `.\tools\godot.ps1 -Action smoke -LogDirectory output/qa/rc-009/final-engine` | **564 UI checks, 0 failures**, exit 0. [UI](../output/qa/rc-009/final-smoke.log). Deliberately invalid startup diagnostics remain expected coverage. |
| `.\tools\godot.ps1 -Action capture -CapturePath res://output/qa/rc-009/final-production.png -LogDirectory output/qa/rc-009/final-engine` | Screenshot saved, exit 0. [Capture log](../output/qa/rc-009/final-capture.log), [normal production](../output/qa/rc-009/final-production.png). |

The core total retains the original **1063** checks, including all **720 endpoint-pair/kit geometry cases**, and adds **137 catalog checks + 163 example checks**. The UI total retains **503** checks and adds **61 actual-scene board checks**, including reused RC-008 touch controls on the added Belfry identity. These are aggregate assertion counts; the 720 geometry cases and seeded comparisons are not extra checks to add to the reported total.

Catalog coverage verifies all four actual encounter references, the preserved development-only board, malformed/invalid/duplicate/missing definitions, no prefills/obstacles/alternate ports, endpoint-only entries, controller rejections and detached reads. Per identity, **64 seeds** compare first entry, Pass and two continuing-stream Restarts against ordinary production, including altered legal template coordinates and presentation strings, with identical endpoint/card/kit outcomes and all three RNG states. A validated one-HP predecessor isolates successful encounter entry into each identity, preserving current/max HP and each permanent UID; it does not claim ordinary starter victory.

Each example uses a naturally generated starter setup and actual controller commands. Assertions cover every command's acceptance, finite-stock conservation, rotation/Flip, replacement/Undo, physical cost, aggregate damage/shield, ordered cleanup, permanent UID conservation, temporary expiry, exact next-turn resources, and rejected actions preserving state/RNG. Seeds **294 / 39 / 474 / 2149** are recorded authoring choices; there is no runtime search/reroll, extra card/stock, debug state mutation or changed difficulty. The [standalone run](../output/qa/rc-009/authoring/example-tests-01.log) passes **168 checks, 0 failures**, exit 0: the 163 checks above plus four report replays and one report-file check. Its [machine-readable report](../output/qa/rc-009/examples-1791523071-37904-420274/report.json) contains exact commands and outcomes.

### Rendered board and interaction evidence

Executed the pinned engine with `--path . --log-file C:\Dev\RuneCast\output\qa\rc-009\final-board-render-engine.log --script res://tests/ui_board_catalog_capture.gd`. The [rendered run](../output/qa/rc-009/final-board-render.log) passes **80 checks, 0 failures**, exit 0: **61 repeated scene checks plus 19 screenshot saves**, not 80 extra unique cases. All four scenes open their natural endpoints-only setup, execute the authored commands and the actual Cast button, then display cleanup/new turn. Belfry additionally runs synthetic touch inspection, endpoint selection/Rotate/Undo, stock exhaustion/refund and small-screen page/inspector/Guide scrolling.

Representative captures visually inspected:

| State | Evidence |
| --- | --- |
| Normal production remains Training Crypt | [450×1000 normal launch](../output/qa/rc-009/final-production.png) |
| Added identity with natural endpoints-only opening | [Belfry opening](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-opening.png) |
| Introductory rune route | [First Circuit built](../output/qa/rc-009/board-capture-1791523199-18876/board_training-built.png) |
| Longer route with Spark/Shield | [Long Gallery built](../output/qa/rc-009/board-capture-1791523199-18876/board_gallery-built.png) |
| Turning/reversal route | [Ossuary Turn built](../output/qa/rc-009/board-capture-1791523199-18876/board_ossuary-built.png) |
| Branching with finite Split/Join, 12 damage and Cast2 | [Belfry built](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-built.png) |
| Complete cleanup, moved endpoints, new hand and full kit | [Belfry turn2](../output/qa/rc-009/board-capture-1791523199-18876/board_belfry-turn2.png), [Gallery turn2](../output/qa/rc-009/board-capture-1791523199-18876/board_gallery-turn2.png) |
| Read-only rune details on an added identity | [Belfry Shield inspector](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/inspect-hand-rune.png) |
| Zero stock and unavailable placement feedback | [Belfry exhausted Straight](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/unavailable-stock.png) |
| Reachable editing and independent inspector scrolling | [360×640 board](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-board.png), [360×640 inspector](../output/qa/rc-009/board-capture-1791523199-18876/belfry-touch/small-portrait-inspector.png) |

Titles, stock labels, hands, Cast and bottom controls fit the 720×1600 scenes. The 360×640 scene scrolls vertically, with reachable controls and a fixed inspector Close. Vertical connections pass behind some rune labels in the existing renderer, but remain readable. All four identities intentionally share the same current crypt/enemy placeholder visuals; no distinct environment treatment is claimed.

The documented wrapper was also exercised directly:

```powershell
.\tools\godot.ps1 -Action capture -BoardExample board_belfry -ExampleStep built -CapturePath res://output/qa/rc-009/launcher-belfry-built.png -LogDirectory output/qa/rc-009/launcher-built-engine
.\tools\godot.ps1 -Action capture -BoardExample board_gallery -ExampleStep cast -CapturePath res://output/qa/rc-009/launcher-gallery-cast.png -LogDirectory output/qa/rc-009/launcher-cast-engine
```

Both saved screenshots and exited 0: [Belfry log](../output/qa/rc-009/launcher-belfry-built.log), [Gallery log](../output/qa/rc-009/launcher-gallery-cast.log). The catalog provides all four ordinary fixture and example-launch commands, plus standalone report/render runners. Normal startup does not load example metadata or auto-build.

### Fixed findings, preservation and limits

Intermediate failures remain visible. The first isolated catalog run had a GDScript inferred-type parse error, corrected before [137 passing checks](../output/qa/rc-009/board-catalog-02.log). The first authoring probe found an incorrectly oriented Ossuary corner; corrected commands produced all four expected results before the witness JSON was finalized. [Scene integration01](../output/qa/rc-009/ui-board-integration-01.log) rejected all four opening facts because JSON parsing represented whole numbers as floats and nested exact comparisons were type-sensitive. The helper now normalizes whole JSON numbers at the validation boundary while retaining full expected-state comparison. [Integration02](../output/qa/rc-009/ui-board-integration-02.log) passes 61 checks/0 failures. Independent review also added type guards for malformed version/setup-kind values. These are fixed development findings, not hidden environment failures or weakened historical assertions.

The [preservation audit](../output/qa/rc-009/preservation-results.json) checks **897 prior files: 896 unchanged hashes, one intended modification (`data/production_boards.json`), zero unexpected changes**. It preserves existing screenshots, raw experiment records, approved images and historical data. Fixed launcher logs were restored. A fresh [fingerprint audit](../output/qa/rc-009/fixture-fingerprint-audit.json) reconstructs all **22 historical fixtures at seed42**, with **22 unchanged fingerprints** against the preserved RC-007 map.

Geometry feasibility with a supplied Spark, affordability with a particular hand, ability to win an encounter and human balance/enjoyment are distinct claims. RC-009 proves the first through the reused geometry suite and the second for its four natural samples. It does not prove universal damaging/affordable hands or ordinary encounter victory. Focus can spend scarce energy, a hand can lack damage, and Pass remains the unchanged fallback. All UI/touch evidence is synthetic desktop input and rendered QA. No new human playtest, physical device, packaging or mobile acceptance is claimed; existing Android configuration and later device work remain outstanding.

The initial discovery command included one read-only `git status --short` before the pasted no-Git prohibition had been read. This was immediately disclosed; it changed no files. No subsequent Git operations, staging, commit or checkpoint occurred. The owner retains Git responsibility.

Next-ready tasks: **RC-010** is the next numbered task; **RC-024** and **RC-033** are also ready under the updated [plan](project-plan.md). Future encounter assignments and presentation remain with their owning tasks.

Documentation QA checked **7 updated documents and 443 relative file links**, with zero missing targets (`output/qa/rc-009/document-links.json`). This checks local file/directory existence, not Markdown anchors. A separate plan audit confirms 60 unique task rows and RC-009 checked complete.
