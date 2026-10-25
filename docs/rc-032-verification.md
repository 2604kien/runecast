# RC-032 — End-to-end run navigation, results and explicit abandonment

Updated October 25, 2026 (Australia/Sydney). **RC-032 and RC-029A are complete for the accepted supported scope.** The owner accepted the concrete Store defaults and authorized normal re-enablement, superseding the earlier temporary unavailable-Store instruction. RC-024A's remaining Store decisions are resolved. [Accepted contract](decisions.md#october-25-2026--store-defaults-accepted-and-production-enablement-authorized), [current Store behavior, launch recipe, fresh verification and compatibility evidence](rc-032-store-verification.md). No Store dependency remains; production content, final balance/art and physical-device acceptance retain their separate owners.

The current application reuses the existing authoritative lifecycle and Store transactions. The test-only activation switch has been removed. Normal **Map → Menu → Store** opens between fully settled rooms; result acknowledgement and all required rewards must be resolved. Active rooms/replay, pending choices and terminal saves remain blocked. Store costs 45 run Gold per rune and 90 per relic, with one purchase per category per run; route-shop allowances and permanent definition awards remain separate. Run v6, Store policy v1 and all original receipt semantics are unchanged.

**Current completion evidence:** 317 Store-model checks; 350 headless/366 rendered ordinary-shell checks; 1,980 purchase durability checks across 240 launches; 3,547 genuine v1–v6 compatibility checks across 440 launches; 10,244 regression checks; 164 shared-Menu and 393 popup-spacing rendered checks all pass. Sixteen Store and eight Menu captures were inspected. The 15 prior Combat geometry failures remain exactly unchanged. The fresh resource pack passes 406 integrity and 132 payload-decode checks plus 32 Python tests. Counts overlap; [full reports, commands and limitations](rc-032-store-verification.md#fresh-accepted-default-verification--october-25-2026).

No Git operations, native Android/iOS builds, SDK changes or signing were performed during the accepted Store re-enablement. Historical process note: an initial read-only `git status` ran before the earlier attached request's prohibition was inspected and was disclosed immediately; it was not repeated. The development guardian is not delivered Bell Keeper content, and this handoff does not claim a complete production tower or final balance.

## Delivered navigation and endings

Fresh Home → New Run saves an unvisited Map. Home retains the approved artwork and actions without restoring removed status/footer prose. Continue returns to the saved between-room Map, active shop/service, pending result or required rewards. A live Combat Resume retains the same scene, controller, preparation and audio owner; an interrupted battle replays its exact committed entry and RNG streams. Map inspection does not enter a room, and entry requires explicit confirmation. Shop and service entry makes that room the main screen.

Home and Menu share persisted Options. The shared Menu retains its literal **Resume Combat** label and caller-aware behavior, including shop/service-specific information. Confirmed Quit returns Home and preserves the checkpoint; it neither abandons the run nor exits the process. New Run asks before replacing an existing save, prepares a detached replacement and saves it before releasing the previous run. Cancellation and failed writes retain the previous owner, profile and settings. No ending starts a new run automatically.

The lifecycle distinguishes a committed battle outcome, pending run rewards/permanent awards, encounter-result acknowledgement and final read-only results. Shadeling remains the designated depth-six boss. Only the separate depth-nine guardian, with a matching actual victory boundary and every required choice resolved, can establish tower victory. Acknowledging a result grants nothing. A player can acknowledge before or after resolving guardian choices; pending results and partial awards remain reachable after Home and restart without replay or duplicate payout.

Committed defeat is terminal, with no rescue, compensation or rewards. A failed outcome save leaves the durable entry checkpoint available for replay. Once settled, victory/defeat/abandonment saves expose **View results** from Home. Final results provide **Home** and **New Run**, and never send a completed run into a dead-end Map. Persisted final acknowledgement uses the same detached-save-publication boundary. Terminal entry, resume, shop/service and reward callbacks reject, including stale callbacks from an abandoned active room.

Invalid-save recovery remains actionable: replacement is blocked while a file is invalid; Retry loading can reopen an externally repaired file, and explicit recovery uses only a validated previous copy while preserving the damaged original. No unreadable file is silently replaced with defaults.

## Explicit abandonment and summaries

The secondary route is **Map run header → Run details → Abandon Run → confirmation**. The confirmation explains loss of run-only progress while previously committed permanent definition unlocks and Options remain. Cancellation changes nothing. Success saves a distinct `abandoned` terminal record before disposing scenes and returning Home; it does not set HP to zero or fabricate completed visits.

**Pending-choice policy:** abandonment is unavailable while any battle result remains unacknowledged or any required reward/permanent choice remains unresolved. Run details directs the player back to those choices. The application neither silently claims nor forfeits awards. Already completed or defeated runs cannot become abandoned. Confirmations carry a checkpoint signature, so entering a room or transacting in an active shop invalidates an older token. Repeated, stale and reentrant callbacks cannot publish another ending.

For live Combat, abandonment retains the existing committed entry boundary. It records that the room was entered but unfinished; current-turn damage, preparation and temporary cards are not persisted. Retained entry data remains available for validation, but a terminal save cannot use it to resume gameplay.

Run details and final results derive their information from authoritative history:

- Outcome; entered and completed room counts, with each visit's recorded state.
- Defeated enemies counted by victorious visit. Repeated definition IDs count as separate victories.
- Final run-owned cards with their exact UID/rank and effective descriptions/values from RC-031's shared instance resolver. Generated temporary cards are excluded.
- Final run relics.
- Permanent definitions actually unlocked by this run's committed award receipts. Previously owned profile definitions are not reported as new awards; exhausted pools grant no duplicate, extra stored copy or compensation.

No playtime, damage totals, scores, leaderboards or analytics were invented. No summary copy is persisted: restart reconstructs the display from visits, outcomes, owned instances and receipts, avoiding an independently editable statistics authority.

## Persistence and compatibility

The October 24 lifecycle schema retained **`rc028_local_v1`**, profile **v1**, and route **v1**. Run **v5** had **33 explicit top-level fields**, compared with v4's 32. Its sole new field was `terminal`, empty for an unfinished run or a five-field record containing `version: 1`, `outcome`, `identity`, `boundary_status` and `acknowledged`. The October 25 [v6 Store extension](rc-032-store-verification.md#save-contract-and-compatibility) adds the 34th field and preserves these terminal semantics, including strict validation/migration of genuine v5 abandonment signatures.

Victory/defeat metadata is checked against authoritative history. Guardian victory requires the final guardian identity, completed choices, matching completed-encounter ID and actual committed battle-health victory record. Only an already validated original v1/v2 historical health boundary may stand in for raw history that those predecessor formats did not retain. New history cannot be concealed behind that anchor. The old structural route fixture remains usable for its navigation assertions, but structural completion alone cannot create a durable final victory.

Abandonment retains its prior route/resources/entry checkpoint and records the former boundary status. Restore first validates that underlying checkpoint using the established validators, then checks eligibility, the exact signature and the distinct terminal outcome. It rejects pending choices, inconsistent outcome/HP, forged terminal identities, premature final acknowledgement and additional persisted summary fields. Fixture-specific encounter IDs require a caller-supplied, explicit resolver registration that validates each visited encounter's role, enemy, board and catalogue. Saved data cannot select that capability, and production content restrictions remain unchanged.

Real **v1/v2/v3/v4** saves pass their version-specific structure, ownership, route, reward, policy and history validation before promotion. Existing rank-zero normalization for v1–v3 and historical HP anchoring for v1/v2 remain intact. v3/v4 health records, ranked cards, relic ownership, allocator gaps, Gold chronology, pending results/rewards, exact entry RNG and retained shop/service policy generations survive. Migration does not retrofit current offerings into old active rooms.

Six genuine RC-031 v4 envelopes were copied **before the schema change**, without editing their versions or payloads: ranked history, active Reliquary, ranked/relic shop, interrupted entry, pending reward and pending defeat. [Original source paths and SHA-256 hashes](../tests/fixtures/rc031/origins-v4.json) record provenance. Earlier real specimens and provenance remain under [RC-028](../tests/fixtures/rc028/README.md), [RC-029](../tests/fixtures/rc029/README.md) and [RC-030](../tests/fixtures/rc030/README.md). The current [compatibility campaign](../output/qa/rc-032-store-accepted/compatibility-results.json) covers **36 genuine v1–v5 predecessor specimens plus four retained v6 saves: 40 specimens across 440 process launches**, including original-byte backups, invalid current files, validated previous-copy recovery and retained policy continuation. The v6 saves load without migration and retain their original bytes, receipts and purchase allowances.

All endings, acknowledgements, abandonment and replacement use **clone → validate/save candidate → publish**. Save success precedes navigation, scene disposal and success audio. The write/flush/close/backup/replace failure points preserve prior owners and retain the identical candidate for same-process Retry. A fresh process recovers only the last durable checkpoint; it does not recover an unsaved in-memory intention. Loading committed receipts remains silent. Existing desktop durability limits remain: these checks are not a power-loss or physical-device guarantee.

## Try the complete development route

Normal production launch remains `./tools/godot.ps1 -Action run`; missing production opening enemies still prevent a naturally complete production tower. The excluded [RC-032 fixture](../tests/fixtures/rc032/README.md) instead uses the actual Home and gameplay screens for a deterministic nine-visit run through all six room families.

From `C:\Dev\RuneCast`:

```powershell
$rc032Manual = 'C:\Dev\RuneCast\output\qa\rc-032-store-accepted\manual-environment'
$env:APPDATA = Join-Path $rc032Manual 'appdata'
$env:LOCALAPPDATA = Join-Path $rc032Manual 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$rc032Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $rc032Engine --path C:\Dev\RuneCast --script res://tests/rc032_manual.gd -- --variant=normal --save-root=C:/Dev/RuneCast/output/qa/rc-032-store-accepted/manual
```

Use `--variant=elite` for the other saved slot and branch walkthrough. Add `--exhausted` for a separate slot whose permanent definition pool starts full. This command keeps saves/settings under `output/qa/rc-032-store-accepted/manual/<variant>-<unlocks|exhausted>`; repeating it restores that slot. Omitting `--save-root` retains the older `output/qa/rc-032/manual` destination. Store is available at settled Map boundaries in every variant; see the [Store walkthrough](rc-032-store-verification.md#try-the-accepted-store-and-complete-fixture).

1. Choose **Home → New Run**. Inspect and explicitly enter the opening node. At seed 42 the normal walkthrough starts at the right-hand opening (`d1b`) leading to Lost Satchel; the elite walkthrough starts at the left-hand opening (`d1a`) leading to Sealed Reliquary.
2. Play the real battles and resolve the event. Choose the left-hand depth-four node, then the normal (`d5a`) or elite (`d5b`) branch. Branches are player choices; the launch variant does not select rooms automatically.
3. Defeat the unchanged production Shadeling at depth six and resolve its result/awards. The tower is still unfinished.
4. Enter the shop, buy a rune and relic, upgrade a physical rune UID and explicitly Leave. Enter recovery and resolve a supported choice.
5. Enter the separately labelled **Calibration Guardian**, win through ordinary Combat actions and resolve every required choice. Review final results, return Home and Continue back to read-only review, or explicitly confirm New Run.
6. To try abandonment, open the Map run header while the run is eligible. Cancel once to retain the run, then confirm. Home offers review of the distinct abandoned ending. Use ordinary confirmed Passes to exercise defeat.

The route is normal → event → normal → normal → normal/elite → Shadeling boss → shop → recovery → guardian. The three calibration definitions and their role registrations are isolated under `tests/fixtures/rc032`; they do not deliver Wickling, Stone Sentinel, Chain Warden or Bell Keeper. Starter ownership, 30/30 HP and zero initial Gold remain unchanged. Each calibration normal/elite victory explicitly offers a skippable rune and **250 fixture Gold**, paid through actual reward transactions. This is deterministic verification funding, not production tuning or postlaunch resource injection.

The unlock variant's isolated profile starts with Spark/Shield unlocked, leaving real Focus/Conjure definition awards for boss and guardian. Its eight-card starter is unchanged. Exhausted variants start with all four definitions unlocked and receive no permanent award or compensation. Subsequent New Runs retain that slot's committed profile. Automated walkthroughs use legal controller actions, actual battle outcomes and the existing room/reward APIs; they do not teleport, auto-win or fabricate completed visits.

## Historical temporary-unavailable scope verification — October 25

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, isolated APPDATA/LOCALAPPDATA and save/settings slots. Existing runtime lifecycle code already satisfied the model/UI audit; changes here enforce the requested Store boundary, add explicit route-family/boss assertions, provide an optional isolated manual save root, and correct scope/documentation. No core schema or transaction validator was weakened. Counts below overlap; they are not a sum of unique tests.

| Coverage | Fresh result and evidence |
| --- | --- |
| Regression aggregate | **10,076 checks, 0 failures across 28 suites**, including **9,047 existing regression checks across 25 suites** — [aggregate](../output/qa/rc-032/request-review/regressions-final.json). Includes core, UI, shell, save/recovery, shops/services, rewards, collections, audio, instance effects and RC-031 hostile-save checks. |
| Complete routes | **462 model checks / 410 headless shell checks / 428 rendered shell checks, 0 failures** — [four-variant family/resource evidence](../output/qa/rc-032/request-review/fixture-coverage.json), [rendered shell](../output/qa/rc-032/request-review/route-shell/results-capture.json). Both branches × genuine/exhausted pools; explicit nine-family order and separate boss/guardian identities. |
| Lifecycle rendered UI | **340 checks, 0 failures** — [report](../output/qa/rc-032/request-review/ui/results-capture.json). Live Resume/replay, pending choices, cancellation, abandonment/defeat, replacement, terminal review, invalid-save recovery and fixed actions. |
| Durable endings/replacement | **2,940 checks, 0 failures; 100 scenarios / 300 process launches** — [campaign](../output/qa/rc-032/request-review/process/5626bb10bc/results.json). Ten operations × five write/flush/close/backup/replace faults × identical Retry/fresh restart. |
| Genuine predecessor migration/recovery | **3,177 checks, 0 failures; 36 original v1–v5 specimens / 396 process launches** — [report](../output/qa/rc-032/current-core-migrations/93c4096f0b/results.json). Includes the six existing genuine v4 captures, five write failures, original-byte backups, damaged-file preservation/recovery and strict v5 abandonment signatures. The original v1–v4 harness also passes **83/0** on pending-defeat-v4 — [compatibility probe](../output/qa/rc-032/original-migration-harness-audit/d684b30b8c/results.json). No specimen was made by changing a current version number. |
| Default-unavailable Store / retained compatibility | **350 checks, 0 failures** — [historical harness with explicit test opt-in](../output/qa/rc-032/request-review/store-compatibility/evidence/results-headless.json). Added scope-gate checks reject signal/direct/stale Store entry and a valid retained purchase confirmation without saving or changing ownership; the retained implementation remains testable without enabling normal gameplay. |
| Shared Menu / Combat reference | **161 shared-Menu checks, 0 failures**; **257 Combat-reference checks with the same 15 pre-existing geometry failures** — [exact comparison](../output/qa/rc-032/request-review/reference-baseline.json). Failing descriptions and measured values match RC-031, ignoring only generated node IDs. No reference assertion was removed or relaxed. |
| Exact resource package | **406 integrity/policy + 132 isolated payload-decode checks, 0 failures**, and **32 Python tests passed** — [audit](../output/qa/rc-032/request-review/resources/resource-audit.json), [tool tests](../output/qa/rc-032/request-review/resources/tool-tests.txt). Existing inventory includes run review and retained Store components; fixtures/QA are excluded. |

All **34 fresh lifecycle/route PNGs were inspected**, including results, run details, abandonment confirmation, failed saves and invalid-save recovery at actual **450×1000** and **360×640** windows. [Review, dimensions and image hashes](../output/qa/rc-032/request-review/visual-review.json). The narrow framebuffer remains the existing 288×640 letterboxed content. Long bodies scroll; fixed actions remain reachable. These lifecycle captures started before the isolated Store gate patch; the affected shared Menu was separately rendered after that patch. Desktop Back checks are not physical Android validation.

The refreshed `builds/rc-032-request-resources/RuneCast.pck` contains **12,467,292 bytes / 393 entries**, SHA-256 **`c7369dcd3caff78c6e5f11a2006b05f1b46bf9da0f23dab17ccc49373f1ec9be`**. Its decoder explicitly checks unavailable Store callbacks in the actual exported shell while retaining v6 policy/receipt compatibility. [206 current runtime-source hashes](../output/qa/rc-032/request-review/resources/source-manifest.json) bind the reviewed source inventory to that pack. This is a desktop resource-only audit, not a native build or signing result.

| Fresh requested state | 450×1000 | 360×640 |
| --- | --- | --- |
| Run details | [image](../output/qa/rc-032/request-review/ui/run-details-live-450x1000.png) | [image](../output/qa/rc-032/request-review/ui/run-details-live-360x640.png) |
| Abandonment confirmation | [image](../output/qa/rc-032/request-review/ui/abandon-confirmation-450x1000.png) | [image](../output/qa/rc-032/request-review/ui/abandon-confirmation-360x640.png) |
| Final guardian results | [image](../output/qa/rc-032/request-review/route-shell/final-results-top-normal-450x1000.png) | [image](../output/qa/rc-032/request-review/route-shell/final-results-top-normal-360x640.png) |
| Failed abandonment / Retry | [image](../output/qa/rc-032/request-review/ui/abandon-save-failure-450x1000.png) | [image](../output/qa/rc-032/request-review/ui/abandon-save-failure-360x640.png) |
| Invalid-save recovery | [image](../output/qa/rc-032/request-review/ui/save-recovery-450x1000.png) | [image](../output/qa/rc-032/request-review/ui/save-recovery-360x640.png) |

Initial failures are retained: two shop-shell assertions expected the historical enabled-Store explanation; the exact-copy expectations were updated to the requested unavailable contract and a disabled assertion added (**85/0** final). The first package decoder still assumed a visible Store catalogue and timed out after accessing its absent presentation; [initial report](../output/qa/rc-032/request-review/resources/resource-audit-initial.json). Updating that scope assertion and reading retained policy from RunState preserved catalogue validation, added unavailable callback checks, and produced the clean final 132-check decode. No gameplay or geometry failure was hidden.

## Historical October 24 verification evidence

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer, isolated save/settings and APPDATA/LOCALAPPDATA. Repeated targeted suites below overlap with the regression aggregate; their totals are not additive claims of unique tests.

| Coverage | Final result and evidence |
| --- | --- |
| Authoritative lifecycle and adversarial terminal metadata | **157 checks, 0 failures** — [report](../output/qa/rc-032/state/results.json). Live-entry abandonment, stale tokens, all five service families, guardian choice/acknowledgement orders, repeated enemies, ranked/relic summaries, real unlocks/exhaustion and postterminal rejection. |
| Complete legal route models | **454 / 0** — [report](../output/qa/rc-032/routes/results.json). Both normal/elite alternatives, nine visits, all six room families, actual Shadeling and separate guardian, purchases/upgrades/relics/services and carried ownership/health. |
| Complete routes through the real application shell | **410 headless / 428 rendered, 0 failures** — [headless](../output/qa/rc-032/route-shell/results-headless.json), [rendered](../output/qa/rc-032/route-shell/results-capture.json). Guardian pending choices, Home/Continue, live Resume/replay, final results and awards. |
| Lifecycle UI, actual configured windows | **324 headless / 340 rendered, 0 failures** — [headless](../output/qa/rc-032/ui/results-headless.json), [rendered](../output/qa/rc-032/ui/results-capture.json). Abandonment/defeat, cancellation, stale callbacks, terminal active-room gates, replacement, recovery, reachable fixed actions and five failure points. |
| Terminal transaction process campaign | **2,940 / 0; 100 scenarios, 300 process launches** — [report](../output/qa/rc-032/process/results-final.json). Ten operations × five failure points × same-process Retry/fresh-process recovery. Includes guardian outcome and final choice, encounter/final acknowledgement, defeat, abandonment and replacement. |
| Genuine predecessor migration/recovery | **1,954 / 0; 22 specimens, 242 process launches** — [report](../output/qa/rc-032/migrations/ebeff78943/results.json). Real v1/v2/v3/v4 files, original-byte preservation and validated recovery. |
| Existing regressions | **8,866 / 0 across 24 suites** — [report](../output/qa/rc-032/regression/results-final.json). Core, UI, shell, persistence, rooms, rewards, collection, audio, effects and RC-031 hostile-save/live UI coverage. |
| Final core rerun after guardian-evidence hardening | **4,139 / 0** — [report](../output/qa/rc-032/final-core/results.json): core/run/route 2,355; save models 1,709; reward core 75. |
| Shared Menu reference | **143 / 0** — [report](../output/qa/rc-032/regression/2cb828498c/shared-menu/evidence/gameplay-menu/results.json). |
| Preserved Combat absolute-reference geometry | **257 checks, 15 pre-existing failures** — [exact baseline comparison](../output/qa/rc-032/regression/reference-baseline.json). Failed descriptions and measured evidence match RC-031, ignoring generated node IDs; no assertions were weakened. |
| Fresh resource-only pack | **402 integrity/policy checks + 122 isolated exact-payload decode checks, 0 failures** — [audit](../output/qa/rc-032/resources/resource-audit.json), [source manifest](../output/qa/rc-032/resources/source-manifest.json). |
| Resource/workflow Python tests | **32 passed** — [log](../output/qa/rc-032/resources/tool-tests.txt). |

Initial diagnostic runs are retained rather than concealed. Four old snapshot assertions exposed transient abandonment-availability fields; the runtime projection was corrected and the original assertions pass. The route-shell test initially referenced nonexistent `master_volume`; the test was corrected to supported `sfx_volume` before its final passes. The reward-audio harness now allows its runner frame to release references before shutdown; all 159 assertions remain unchanged. Final evidence is identified above; earlier failed/in-progress reports are not treated as passing runs.

The new `run_review.gd` runtime component is included in the resource inventory and decode checks. The final resource-only `builds/rc-032-resources/RuneCast.pck` contains **12,436,332 bytes and 389 entries**, SHA-256 **`3af0317f5d9b5a89c49bdf07118e44d275c013cba84a4c139b6987887e77f2d1`**. Its audit and source manifest were refreshed after the final terminal-room callback guards. All `tests/` fixture content, test runners and QA outputs remain excluded from the release pack. The resource report describes desktop decoding of this exact PCK, not a native mobile build.

## Historical October 24 window review

The team captured **34 screenshots** across actual **450×1000** and **360×640** configured Windows and inspected all 16 lifecycle images plus representative route results, ranked collection, award and pending-choice screens. The narrow viewport texture is **288×640** within the existing 360×640 letterboxed window; these are not unscaled component mockups. Wrapped text remains readable, long bodies scroll, and fixed actions stay reachable. Run details truthfully labels abandoned active visits as entered/unfinished; final summaries show the exact owned ranks/relics and actual award definitions. The approved Home/Map/Combat composition, shared popup sizing, neutral navigation and audio/reduced-motion ownership remain intact.

| State | 450×1000 | 360×640 |
| --- | --- | --- |
| Live committed run details | [image](../output/qa/rc-032/ui/run-details-live-450x1000.png) | [image](../output/qa/rc-032/ui/run-details-live-360x640.png) |
| Abandonment confirmation | [image](../output/qa/rc-032/ui/abandon-confirmation-450x1000.png) | [image](../output/qa/rc-032/ui/abandon-confirmation-360x640.png) |
| Failed abandonment save / Retry | [image](../output/qa/rc-032/ui/abandon-save-failure-450x1000.png) | [image](../output/qa/rc-032/ui/abandon-save-failure-360x640.png) |
| Abandoned final results | [image](../output/qa/rc-032/ui/abandoned-results-450x1000.png) | [image](../output/qa/rc-032/ui/abandoned-results-360x640.png) |
| Defeat final results | [image](../output/qa/rc-032/ui/defeat-results-450x1000.png) | [image](../output/qa/rc-032/ui/defeat-results-360x640.png) |
| Final acknowledgement save error | [image](../output/qa/rc-032/ui/results-save-failure-450x1000.png) | [image](../output/qa/rc-032/ui/results-save-failure-360x640.png) |
| Invalid-save recovery | [image](../output/qa/rc-032/ui/save-recovery-450x1000.png) | [image](../output/qa/rc-032/ui/save-recovery-360x640.png) |
| Guardian pending choices | [image](../output/qa/rc-032/route-shell/guardian-pending-elite-450x1000.png) | [image](../output/qa/rc-032/route-shell/guardian-pending-elite-360x640.png) |
| Pending-choice abandonment guidance | [image](../output/qa/rc-032/route-shell/guardian-pending-details-elite-450x1000.png) | [image](../output/qa/rc-032/route-shell/guardian-pending-details-elite-360x640.png) |
| Completed guardian summary | [image](../output/qa/rc-032/route-shell/final-results-top-normal-450x1000.png) | [image](../output/qa/rc-032/route-shell/final-results-top-normal-360x640.png) |
| Final ranked collection | [image](../output/qa/rc-032/route-shell/final-results-runes-normal-450x1000.png) | [image](../output/qa/rc-032/route-shell/final-results-runes-normal-360x640.png) |
| Actual permanent awards | [image](../output/qa/rc-032/route-shell/final-results-awards-elite-450x1000.png) | [image](../output/qa/rc-032/route-shell/final-results-awards-elite-360x640.png) |

Back/dismiss, nested overlays, busy states and stale generations are exercised on desktop. Desktop Back simulation does not constitute physical Android validation.

## Reproduce checks

From the workspace, using the isolated environment and `$rc032Engine` defined in the manual recipe:

```powershell
& $rc032Engine --headless --path . --audio-driver Dummy --script res://tests/rc032_state_runner.gd
& $rc032Engine --headless --path . --audio-driver Dummy --script res://tests/rc032_route_runner.gd
& $rc032Engine --headless --path . --audio-driver Dummy --script res://tests/rc032_ui_runner.gd
& $rc032Engine --headless --path . --audio-driver Dummy --script res://tests/rc032_route_shell_runner.gd

# Render actual configured windows and write screenshot evidence.
& $rc032Engine --path . --audio-driver Dummy --script res://tests/rc032_ui_runner.gd -- --capture-rc032
& $rc032Engine --path . --audio-driver Dummy --script res://tests/rc032_route_shell_runner.gd -- --capture-rc032-route

# Each campaign creates its own isolated directories and process logs.
$rc032Python = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $rc032Python tools/verify_rc032_process.py --output-root output/qa/rc-032/request-review/process
& $rc032Python tools/verify_rc032_migrations.py
# The retained v6-aware harness additionally verifies genuine v5 terminal signatures.
& $rc032Python tools/verify_rc032_store_migrations.py --output output/qa/rc-032/request-review/migrations
& $rc032Python tools/verify_rc032_regressions.py --output-root output/qa/rc-032/request-review/regression
& $rc032Python tools/verify_rc032_regressions.py --only shared-menu,reference --render --output-root output/qa/rc-032/request-review/regression-rendered

# Export and audit a resource-only payload; these commands perform no native build.
New-Item -ItemType Directory -Force -Path builds/rc-032-request-resources | Out-Null
& $rc032Engine --headless --path . --editor --export-pack 'iOS' builds/rc-032-request-resources/RuneCast.pck
& $rc032Python tools/verify_ios_resources.py --pack builds/rc-032-request-resources/RuneCast.pck --engine $rc032Engine --project-root . --report output/qa/rc-032/request-review/resources/resource-audit.json
```

The absolute-reference command retains its 15 documented baseline failures; use the comparison report above when interpreting its nonzero result.

## Completion boundary and remaining project work

1. **RC-024A resolved:** the accepted concrete Store contract fixes currency, current catalogue, availability, purchase lifetime/limits and deferred families/accounts/payment scope.
2. **RC-029A complete:** the retained implementation is enabled normally and verified against that contract, including atomic payment/grant/health/receipt, cancellation, duplicate/stale/reentrant rejection and original save compatibility.
3. **RC-032 complete for supported scope:** ordinary Store Menu entry/return, purchases, Home/Continue, interruption/identical Retry/fresh restart, recovery and shared overlay behavior pass alongside the delivered lifecycle. No Store blocker remains.

Missing production enemies and Bell Keeper remain RC-033/RC-034; remaining rune bases/catalogue RC-035; final rewards, prices, pacing and balance RC-036/RC-045; dedicated final art/integration RC-041/RC-042; accessibility and physical-device lifecycle acceptance RC-044/RC-047–RC-049. RC-022 remains deferred, RC-023 human/device acceptance remains open, and both music tracks remain unavailable. Those limitations are preserved without extending this implementation's scope.
