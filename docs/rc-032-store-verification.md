# RC-029A and RC-032 — Separate Store integration

## October 25, 2026 — Accepted defaults restored to the normal application

**RC-024A's Store contract is resolved; RC-029A and RC-032 are complete for the accepted supported scope.** Normal-shell Store navigation, transactions, full fixture endings and compatibility passed the fresh verification below. No Store blocker remains. This does not claim missing production enemies/guardian, final economy/art or physical-device acceptance.

The owner accepted the [concrete Store defaults](decisions.md#october-25-2026--store-defaults-accepted-and-production-enablement-authorized) and authorized re-enablement and RC-029A/RC-032 completion. This supersedes the preceding temporary unavailable-Store instruction. The runtime no longer has a `store_enabled_for_tests` switch: the normal application and manual fixture use the existing authoritative RunState availability, identity and transaction guards. No Git operations were performed for this acceptance and re-enablement work.

The separate Store opens from **Map → Menu → Store** after the room, result acknowledgement and all required choices are settled. Initial zero-Gold browsing is supported. Active Combat/replay, unresolved shops/services, pending results/rewards, busy/failed transactions and terminal runs cannot purchase. Back returns to the same Menu and Map; browsing consumes no visit, turn, allowance, Gold or RNG draw. Live Combat Resume, Quit-to-Home checkpoint behavior and final results retain their existing semantics.

The current catalogue contains **Spark, Shield, Focus and Conjure Spark**, filtered by profile unlock eligibility, and the **six existing relics**. A rune costs **45 Gold**, a relic **90**. The player may buy **one rune and one relic total per run**, independently of route-shop allowances. Rune copies receive a new rank-zero UID, including duplicate definitions. Relics remain unique across all sources and retain existing effects. Later removal/upgrading of a Store card uses ordinary room services; removal does not refund Gold or restore the allowance. Store purchases never grant permanent definition unlocks or alter the eight-card starter. Perks and extra item families/services remain deferred.

Compact 32px-icon rows, category prices/availability, exact benefit/cost confirmation and fixed Back reuse the approved presentation. The shared Menu retains literal **Resume Combat** and caller-specific shop/service information. Disabled Store states show the actual reason. There is no new asset pack, redesign or substitute route-shop screen.

**Compatibility:** this change does not alter the run model, Store policy, profile, local-save implementation or serialized format. Keep run **v6**, Store **`rc032_store_v1`**, profile/route **v1** and envelope **`rc028_local_v1`**. Existing receipts, consumed allowances, ranked cards, unique relics, chronological Gold/HP, pending results/rewards, exact entry/RNG and original room policies remain authoritative. The existing v1–v5 validators/migrations remain intact; real retained v6 files are also checked unchanged. No migration resets a Store cap or grants purchases. Future price/catalogue expansion must preserve old receipt semantics through explicit versioned policies.

Every purchase still follows **clone → validate/save → publish**. Payment, new UID/relic, acquisition health and receipt commit together; success audio and UI follow durable success. Cancellation, duplicates, stale/detached callbacks and reentrant actions cannot purchase. Five-point write failure tests preserve old owners and identical same-process Retry candidates; Home Retry works, and fresh restart loads only the last durable checkpoint. Restored receipts remain silent. Terminal results permit review, Home and explicit New Run, never later purchases or repeated awards.

## Try the accepted Store and complete fixture

From `C:\Dev\RuneCast`, create isolated manual slots and application-data directories:

```powershell
$storeManual = 'C:\Dev\RuneCast\output\qa\rc-032-store-accepted\manual-environment'
$env:APPDATA = Join-Path $storeManual 'appdata'
$env:LOCALAPPDATA = Join-Path $storeManual 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$storeEngine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $storeEngine --path C:\Dev\RuneCast --script res://tests/rc032_manual.gd -- --variant=normal --save-root=C:/Dev/RuneCast/output/qa/rc-032-store-accepted/manual
```

1. **Home → New Run → Menu → Store** browses with zero Gold; purchases show insufficient funds. Back returns to the same Menu/Map.
2. Play the first real fixture battle, resolve its rune/Gold rewards and acknowledge the result. Reopen Store, cancel a purchase, then confirm one rune. The run's rune allowance is now used.
3. After another settled room, buy a relic. Try Home/Continue and restarting the same command: ownership and both category limits remain. Store is unavailable inside an active room or while any result/reward remains pending.
4. Continue the nine-visit route through event, normal/elite branch, separate Shadeling boss, route shop, recovery and the calibration guardian. Route-shop purchases/upgrades remain independent. Resolve every guardian choice and review the final run-owned collection, ranks, relics and actual permanent awards.
5. Final **Home → View results** is read-only. **New Run** confirms replacement and resets run purchases/allowances while preserving unlocks/settings. On a separate unfinished run, **Map header → Run details → Abandon Run** ends it only after pending choices are resolved and the terminal save succeeds.

Use `--variant=elite` for the other branch slot, or add `--exhausted` for an initially full definition pool with no permanent award/compensation. At seed 42, normal begins at `d1b` (Satchel), elite at `d1a` (Reliquary); both use left depth four, then their selected depth-five branch. Both converge on Shadeling → shop → recovery → the distinct development guardian. Repeating the command restores its slot; `--save-root` leaves older manual slots intact.

The fixture retains the unchanged eight cards, 30 HP and zero initial Gold. Each calibration normal/elite victory explicitly offers 250 fixture Gold through real reward transactions. Ordinary Combat commands produce every outcome; no postlaunch resource injection, teleport or fabricated visit is used. The guardian is not delivered Bell Keeper content. Production encounter/catalogue delivery, final ordinary-income economy/art and physical-device acceptance remain with their existing tasks.

## Fresh accepted-default verification — October 25, 2026

All checks use pinned **Godot 4.7.2.stable.official.ed1daf0bf**, isolated save/settings and APPDATA/LOCALAPPDATA directories. New evidence is under `output/qa/rc-032-store-accepted`; earlier evidence is retained. The route shell uses ordinary Store access with no opt-in override. Counts across suites overlap and are not a sum of unique tests.

| Coverage | Result and evidence |
| --- | --- |
| Store model | **317 checks, 0 failures** — [report](../output/qa/rc-032-store-accepted/model/results.json). Exact affordability, per-category limits, both purchase orders, cross-source relic uniqueness, UID/rank allocation, upgrades/removal, terminal/stale rejection and receipt validation. |
| Ordinary Store shell and legal complete routes | **350 headless / 366 rendered checks, 0 failures** — [headless](../output/qa/rc-032-store-accepted/ui/results-headless.json), [rendered](../output/qa/rc-032-store-accepted/ui/results-capture.json), [legal actions](../output/qa/rc-032-store-accepted/ui/legal-commands-capture.json). Both nine-visit branches, purchases through actual confirmation/save APIs, pending choices, Home/Continue, results, replacement, stale/detached/reentrant input and error Retry. |
| Purchase failures/restart/recovery | **1,980 checks, 0 failures; 40 scenarios / 240 fresh-process launches** — [campaign](../output/qa/rc-032-store-accepted/process/a997b49d53/results.json). Rune/relic as first/second purchase × write/flush/close/backup/replace × same-process Retry/fresh restart, followed by damaged-current preservation and validated previous-copy recovery. |
| Genuine v1–v6 compatibility | **3,547 checks, 0 failures; 40 original specimens / 440 fresh-process launches** — [combined report](../output/qa/rc-032-store-accepted/compatibility-results.json). Real v1–v5 migration/recovery: [3,177 checks / 396 launches](../output/qa/rc-032-store-accepted/migrations/63f0dd4b2c/results.json). Four retained v6 Store files: [370 checks / 44 launches](../output/qa/rc-032-store-accepted/retained-v6/c2d7781878/results.json), explicitly `migrated=false`, exact unchanged bytes on load, preserved receipts/owners/limits and five-point rewrite/recovery failures. |
| Existing regression suites | **10,244 checks across 28 suites, 0 failures** — [report](../output/qa/rc-032-store-accepted/regression/ebc3bfaf4b/results.json), [summary/source hashes](../output/qa/rc-032-store-accepted/regression/summary.json). Includes 157 lifecycle-state, 462 full-route-model, 410 route-shell and 324 lifecycle-UI checks, plus core, saves, audio, rewards, collection, shops/services and RC-031 effects/hostile saves. |
| Rendered shared Menu and popup spacing | **164 + 393 checks, 0 failures** — [report](../output/qa/rc-032-store-accepted/regression-rendered/0e731ca06d/results.json). Default enabled zero-Gold Store, native Store/Back, blocked active-room/Combat callbacks, literal Resume Combat, common geometry and fixed actions. |
| Combat reference | **257 assertions, the same 15 documented geometry failures** — [exact comparison](../output/qa/rc-032-store-accepted/regression-rendered/reference-baseline.json). Every assertion description and measured result matches the prior baseline, normalizing only generated node IDs. No geometry assertion was removed or relaxed. |
| Exact resource package | **406 integrity/policy + 132 isolated payload-decode checks, 0 failures**, plus **32 Python tests passed** — [audit](../output/qa/rc-032-store-accepted/resources/resource-audit.json), [tool tests](../output/qa/rc-032-store-accepted/resources/tool-tests.txt). The actual exported application opens Store by default, displays its authoritative catalogue and rejects zero-Gold purchase callbacks. All tests/fixtures/QA remain excluded. |

The complete Store journeys contain **12 real battle victories and 338 accepted Combat commands**. Normal finishes with 760 Gold, 27/34 HP, ten cards and Heart Stone/Copper Coil; elite finishes with 725 Gold, 29/34 HP, ten cards and Ward Seal/Heart Stone/Copper Coil. Both commit two legitimate permanent definition awards. These are fixture outcomes, not production balance claims.

The four retained v6 specimens were copied byte-for-byte from the earlier enabled Store implementation: settled rune-only, settled relic-only and normal/elite completed runs with both purchases. [Original paths and SHA-256 provenance](../tests/fixtures/rc032/origins-v6.json), [all recorded v2–v6 hash checks](../output/qa/rc-032-store-accepted/fixture-provenance.json). No payload, version or terminal signature was fabricated. Earlier v1–v5 specimens and provenance are unchanged. Normal suites and campaigns finished with clean engine logs; the exploratory v6 pass is retained, but only the stronger final 370-check pass is counted above.

All **16 Store screenshots** and **8 shared-Menu screenshots** were individually inspected: [Store review/dimensions](../output/qa/rc-032-store-accepted/ui/visual-inspection.json), [Menu review/hashes](../output/qa/rc-032-store-accepted/regression-rendered/visual-review.json). Actual windows are 450×1000 and 360×640; shared Menu also covers 720×1600. The narrow content remains the existing 288×640 letterboxed framebuffer. Text wraps, scrolling works, and confirmation/Back actions stay reachable. Desktop Back checks do not constitute physical Android validation.

| Fresh state | 450×1000 | 360×640 |
| --- | --- | --- |
| Zero-Gold catalogue | [image](../output/qa/rc-032-store-accepted/ui/catalogue-zero-gold-normal-450x1000.png) | [image](../output/qa/rc-032-store-accepted/ui/catalogue-zero-gold-elite-360x640.png) |
| Rune confirmation | [image](../output/qa/rc-032-store-accepted/ui/rune-purchase-confirmation-normal-450x1000.png) | [image](../output/qa/rc-032-store-accepted/ui/rune-purchase-confirmation-elite-360x640.png) |
| Relic catalogue | [image](../output/qa/rc-032-store-accepted/ui/catalogue-relics-normal-450x1000.png) | [image](../output/qa/rc-032-store-accepted/ui/catalogue-relics-elite-360x640.png) |
| Failed-save Retry | [image](../output/qa/rc-032-store-accepted/ui/store-purchase-save-failure-normal-450x1000.png) | [image](../output/qa/rc-032-store-accepted/ui/store-purchase-save-failure-elite-360x640.png) |
| Store-owned final results | [image](../output/qa/rc-032-store-accepted/ui/store-equipped-final-results-normal-450x1000.png) | [image](../output/qa/rc-032-store-accepted/ui/store-equipped-final-results-elite-360x640.png) |

The new `builds/rc-032-store-accepted-resources/RuneCast.pck` has **12,466,908 bytes / 393 entries**, SHA-256 **`a1e629d1ccbbea14248c4835798729ac03d3ffad29744e73ba49acb88bf9c5c9`**. [206 runtime-source hashes](../output/qa/rc-032-store-accepted/resources/source-manifest.json) identify the source inventory. [Preservation audit](../output/qa/rc-032-store-accepted/preserved-source-final.json) confirms all 11 sampled authoritative model/policy/content/viewer files are byte-identical to the start of re-enablement. Only application availability/integration and verification/docs changed; no new runtime file or asset was introduced. The export is resource-only, with no native build, signing or device claim.

Reproduce from the isolated manual environment above:

```powershell
$storePython = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $storeEngine --headless --path . --audio-driver Dummy --script res://tests/rc032_store_state_runner.gd -- --output-root=res://output/qa/rc-032-store-accepted/model
& $storeEngine --headless --path . --audio-driver Dummy --script res://tests/rc032_store_shell_runner.gd -- --output-root=res://output/qa/rc-032-store-accepted/ui
& $storeEngine --path . --audio-driver Dummy --script res://tests/rc032_store_shell_runner.gd -- --capture-rc032-store --output-root=res://output/qa/rc-032-store-accepted/ui
& $storePython tools/verify_rc032_store_process.py --output-root output/qa/rc-032-store-accepted/process
& $storePython tools/verify_rc032_store_migrations.py --output output/qa/rc-032-store-accepted/compatibility
& $storePython tools/verify_rc032_regressions.py --output-root output/qa/rc-032-store-accepted/regression
& $storePython tools/verify_rc032_regressions.py --render --only shared-menu,panel-spacing,reference --output-root output/qa/rc-032-store-accepted/regression-rendered
New-Item -ItemType Directory -Force -Path builds/rc-032-store-accepted-resources | Out-Null
& $storeEngine --headless --path . --editor --export-pack 'iOS' builds/rc-032-store-accepted-resources/RuneCast.pck
& $storePython tools/verify_ios_resources.py --pack builds/rc-032-store-accepted-resources/RuneCast.pck --engine $storeEngine --project-root . --report output/qa/rc-032-store-accepted/resources/resource-audit.json
```

The reference command intentionally returns nonzero for the documented 15 failures. Model, process, migration and ordinary Store/UI evidence is independent of that baseline. Running the actual manual CLI with the accepted save root also passed its [startup probe](../output/qa/rc-032-store-accepted/manual-probe/console.txt).

## Prior Store implementation evidence

The historical implementation, compact-presentation corrections and earlier commands below remain evidence of the retained work. The accepted normal-shell behavior and fresh verification above take precedence over any prior availability notice.

October 25, 2026 (Australia/Sydney). **RC-029A and the remaining RC-032 integration are complete for the approved supported scope.** This extends the [RC-032 lifecycle delivery](rc-032-verification.md) with the [owner-approved Store contract](decisions.md#october-25-2026--separate-store-contract-accepted). No Git operations, native Android/iOS builds, signing or new asset generation were performed for this extension.

## Compact Store presentation follow-up

The owner requested smaller icons and less catalogue text. Store now uses whole-row purchase targets with **32px glyphs**, an item name and a short effect summary. Each category displays its price and purchase status once. Rows retain the shared **68px minimum action height** and grow when text wraps. Full rune energy/effect details, relic benefits, exact cost, remaining Gold and allowance use appear in the confirmation. The navy/gold popup and fixed Back action remain. Prices, purchase limits, eligibility, persistence and run rules are unchanged; see the [presentation decision](decisions.md#october-25-2026--compact-store-presentation).

The existing Store journeys passed again: **340 headless and 356 rendered checks, zero failures**, with clean engine logs. Actual viewport clicks on the rune name and icon opened the expected confirmation at both window sizes. All **16 new captures** were inspected for wrapping, overlap and reachable actions. Evidence is separate from the initial delivery: [headless results](../output/qa/rc-032-store-compact/ui/results-headless.json), [rendered results](../output/qa/rc-032-store-compact/ui/results-capture.json), [450×1000 catalogue](../output/qa/rc-032-store-compact/ui/catalogue-zero-gold-normal-450x1000.png), [360×640 catalogue](../output/qa/rc-032-store-compact/ui/catalogue-zero-gold-elite-360x640.png), [relic rows](../output/qa/rc-032-store-compact/ui/catalogue-relics-normal-450x1000.png), and [narrow confirmation](../output/qa/rc-032-store-compact/ui/rune-purchase-confirmation-elite-360x640.png). The original delivery evidence below remains retained.

An additional [funded catalogue preview](../output/qa/rc-032-store-compact/ui/catalogue-funded-normal-450x1000.png) follows the first legal fixture battle and its explicit 250-Gold reward. Its targeted capture passed 12 checks with no failures or engine errors; no resources were injected after launch.

The updated [resource-only package](../builds/rc-032-store-compact-resources/RuneCast.pck) passes **406 integrity checks, 132 exact-payload decode checks and 32 packaging-tool tests**, with no errors or warnings. It contains **393 entries / 12,466,908 bytes**, SHA-256 `8d90cb6ed41f5e54a9fd2ef9cd31fac1836a7abc0672491a752631195c44af80`. [Audit](../output/qa/rc-032-store-compact/resources/resource-audit.json), [source manifest](../output/qa/rc-032-store-compact/resources/source-manifest.json), [tool results](../output/qa/rc-032-store-compact/resources/tool-tests.txt). The earlier package is preserved. This follow-up does not constitute a native mobile build or device validation. No Git operations were performed.

## Behavior and navigation

**Map → Menu → Store** opens the separate run supply catalogue between rooms. The initial unvisited Map permits browsing with zero Gold. Active Combat, interrupted entry, active shops/services, pending results/rewards and terminal runs cannot buy from Store. The shared Menu explains unavailable access. Closing Store returns to the same Menu and Map; it consumes no turn, room visit or random draw. Home keeps its approved artwork/actions and the shared Menu retains literal **Resume Combat**.

The fixed catalogue contains every implemented, validated, unlocked ownable rune and the six supported relics. Generated Free Spark and missing definitions never appear. A rune costs **45 run Gold**; a relic costs **90**. There is **one rune purchase and one relic purchase total per run**, retained across Store visits, Home/Continue and restart. Rune copies receive a new UID at rank zero, even when that definition is already owned. Relics are unique across all sources, with the existing effects and one-time Heart Stone health hook. Store copies can subsequently be upgraded/removed by supported room services. Purchases end with the run; permanent unlocks and the eight-card starter retain their existing rules.

Store shows the current Gold, each item's benefit/cost, remaining category allowances and unavailable reasons. The shared confirmation shows the precise cost, Gold remaining, item benefit and allowance consumed. It uses the existing navy/gold popup, scrollable content and fixed Back action. Cancelling changes nothing. Back first dismisses confirmation, then Store, then Menu. Input cannot pass through an overlay, and detached or stale catalogue callbacks cannot transact.

Purchases use **clone → validate/save → publish**. Payment, grant, health change and receipt commit together. A failed write retains previous owners and the identical candidate for Retry. Retry can also be reached after returning Home, reconstructing Map/Menu/Store after durable success. Explicit Reload discards only the unsaved intent; a fresh process opens the last durable checkpoint. Publication stays locked through screen and audio callbacks. Successful rune acquisition uses the existing reward cue, relic acquisition uses the existing confirmation cue, and restored receipts are silent.

## Save contract and compatibility

The local envelope remains `rc028_local_v1`, profile v1 and route v1. Run **v6** has **34 explicit top-level fields**, adding `store` to v5. Store is `{version: 1, policy_id: "rc032_store_v1", transactions: []}` with at most two receipts, one per category. Each receipt retains its exact definition, price, visit-count/revision boundary, eligible catalogue, UID allocation, Gold and HP/maxHP boundaries. Existing chronological validators insert Store activity between visits when reconstructing ownership, income/spending, relic offers and health. They reject altered prices/limits, duplicates, unsupported or locked definitions, forged allocation/health and purchases at unsettled or terminal boundaries.

Genuine **v1–v5** saves validate their original contracts before promotion. Migration adds an empty Store ledger without consuming limits or changing retained room offerings, rewards, ranks or ownership. Existing v5 abandonment fingerprints are checked in their original format before re-signing the equivalent v6 checkpoint. The 14 genuine v5 envelopes were copied without changing their payload/version/signature before schema edits; [provenance and SHA-256 hashes](../tests/fixtures/rc032/origins-v5.json) accompany them. The 22 retained genuine v1–v4 specimens remain unchanged.

## Manual walkthrough

From `C:\Dev\RuneCast`, use the existing excluded development tower:

```powershell
$qaRoot = 'C:\Dev\RuneCast\output\qa\rc-032-store\manual-environment'
$env:APPDATA = Join-Path $qaRoot 'appdata'
$env:LOCALAPPDATA = Join-Path $qaRoot 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/rc032_manual.gd -- --variant=normal
```

Choose **New Run** on Home. Browse Store before entry to see insufficient funds. Win the first calibration battle with legal Combat actions, resolve its Gold/rune reward and acknowledge the result. Open **Menu → Store** to buy a rune, cancel a purchase, inspect relics or go Back. Win another battle before buying a relic to exercise separate Store visits. Resume the route through the real shop's purchase/upgrade/relic services and Recovery to the distinct calibration guardian. Resolve all guardian awards and acknowledge its result to reach final review. From Map's run header, inspect Run details and try confirmed abandonment on a separate run. Home's **View results** reopens terminal review; **New Run** confirms replacement and preserves profile/settings.

Use `--variant=elite` for the alternate depth-five choice and `--exhausted` for an initially exhausted permanent-unlock pool. These switches retain separate fixture save/settings paths. The fixture starts with the normal 30 HP, zero Gold and eight cards; its explicit 250-Gold normal/elite battle rewards fund verification. The guardian is a development calibration encounter, not delivered Bell Keeper content. The normal production tower still requires missing enemy/guardian content.

## Economy and remaining scope

The accepted prices remain provisional. At the older **proposed** 15-Gold normal/30-Gold elite values, 45 Gold equals three normal rewards and 90 equals six. The nine-visit structural route has three guaranteed normal fights and one normal/elite alternative before the zero-configured-Gold Shadeling milestone. Four 15-Gold normals plus Lost Satchel's 20 would yield 80: enough for a rune, below the relic price. Three normals, a 30-Gold elite and a hypothetical Satchel yield 95: enough for either category, not both (135). Actual event branches, Blood Tithe, reward choices and route-shop spending alter that budget. These are arithmetic scenarios using historical tuning proposals, not newly authorized production payouts or human balance evidence. RC-036/045 must tune rewards/prices together; the development fixture's 250-Gold payouts cannot establish economy balance.

Remaining production enemies/guardian, missing rune definitions, final descriptions/art, balance and physical-device lifecycle/accessibility acceptance stay with RC-033–RC-047 and their existing dependencies. Desktop Back simulation and configured-window captures do not constitute Android/iOS device validation. The previously documented 15 Combat reference geometry failures remain tracked separately and must not be hidden by Store verification.

## Verification and reproducible evidence

All gameplay runs used pinned **Godot 4.7.2.stable.official.ed1daf0bf**, isolated local save/settings and APPDATA/LOCALAPPDATA directories. The Store route harness uses the unchanged RC-032 graph, encounters and reward policy. Its two complete journeys contain **12 actual battle victories and 338 accepted legal Combat commands**. Normal ends with 760 Gold, 27/34 HP, ten cards and Heart Stone/Copper Coil; elite ends with 725 Gold, 29/34 HP, ten cards and Ward Seal/Heart Stone/Copper Coil. Each commits two legitimate definition awards. Fixture funding is explicit; there is no postlaunch resource injection, fabricated visit completion or auto-win.

| Verification | Result | Evidence |
| --- | --- | --- |
| Focused Store model | 317 checks, 0 failures | [Model assertions](../output/qa/rc-032-store/model/results.json) |
| Store shell, both full routes | 340 headless / 356 rendered, 0 failures | [Headless](../output/qa/rc-032-store/ui/results-headless.json), [rendered](../output/qa/rc-032-store/ui/results-capture.json), [legal commands](../output/qa/rc-032-store/ui/legal-commands-capture.json) |
| Purchase durability/recovery | 1,980 checks, 0 failures; 40 scenarios / 240 fresh-process launches | [Process campaign](../output/qa/rc-032-store/process/96e2cfb816/results.json) |
| Genuine predecessor migration/recovery | 3,177 checks, 0 failures; 36 specimens / 396 launches | [Migration campaign](../output/qa/rc-032-store/migrations/0a477b8009/results.json) |
| Final core follow-up | 52 checks, 0 failures / 6 launches | [Later-event purchase/recovery](../output/qa/rc-032-store/process/33b2678f07/results.json) |
| Existing regression suites, including RC-032 lifecycle/routes | 10,228 checks across 28 suites, 0 unresolved failures | [Consolidated results and exact rerun provenance](../output/qa/rc-032-store/regression/results-final.json) |
| Shared Menu and popup spacing, actual renderer | 161 + 393 checks, 0 failures | [Rendered regressions](../output/qa/rc-032-store/render-regression/4161ffab72/results.json) |
| Combat absolute reference | 257 checks, the same 15 prior geometry failures | [All-assertion comparison to the prior baseline](../output/qa/rc-032-store/reference-cleanup/comparison.json) |
| Resource-only package | 406 integrity + 132 exact-payload decode checks, 0 failures | [Audit](../output/qa/rc-032-store/resources/resource-audit.json), [decode log](../output/qa/rc-032-store/resources/ios-resource-probe-console.txt) |
| Packaging tools | 32 tests pass | [Tool results](../output/qa/rc-032-store/resources/tool-tests.txt) |

Focused cases include exact 44/45, 89/90 and 134/135 Gold boundaries using explicit excluded reward configurations, every relic hook, both purchase orders, repeated visits, cross-source uniqueness, new UID/rank ownership, later upgrades/removal, malformed receipts and outer policy data, pending choices, active rooms, terminal closure and stale confirmations. Shell checks exercise confirmation cancellation, nested Back, owner preservation, all five write/flush/close/backup/replace failure points, identical Retry, Home Retry, explicit Reload, fresh-shell rollback, silent restore, reentrant screen/audio callbacks and replacement resets. Process campaigns independently check rune/relic as first or second purchase, both Retry and restart, damaged-current preservation and validated previous-copy recovery. Migration validates original predecessor bytes, including original v5 abandonment fingerprints, before promotion.

The first broad regression pass found a malformed non-text Store policy ID that raised an engine error; the validator now rejects it cleanly. Four affected assertions and two shop Menu assertions were rerun successfully. Older Menu assertions were updated for the approved between-room Store availability and new explanatory copy while retaining their original geometry, input and visit/stock requirements. A rendered narrow-window check found that appending an unavailable suffix made the Store action wrap and shift other rows; the action now consistently reads **Store**, with disabled styling and a scrollable reason. Shared Menu geometry again matches across callers. The Combat reference harness needed deferred teardown to release its final Crypt ambience playback; **all 257 assertions and measured results remain unchanged**, including the 15 documented failures. No baseline was rewritten or failure suppressed.

All **16 final Store screenshots** were individually inspected. Representative paired captures:

| State | 450×1000 window | 360×640 window |
| --- | --- | --- |
| Zero-Gold catalogue | [Large](../output/qa/rc-032-store/ui/catalogue-zero-gold-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/catalogue-zero-gold-elite-360x640.png) |
| Rune confirmation | [Large](../output/qa/rc-032-store/ui/rune-purchase-confirmation-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/rune-purchase-confirmation-elite-360x640.png) |
| Relic catalogue | [Large](../output/qa/rc-032-store/ui/catalogue-relics-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/catalogue-relics-elite-360x640.png) |
| Heart Stone confirmation | [Large](../output/qa/rc-032-store/ui/heart-stone-confirmation-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/heart-stone-confirmation-elite-360x640.png) |
| Failed purchase save | [Large](../output/qa/rc-032-store/ui/store-purchase-save-failure-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/store-purchase-save-failure-elite-360x640.png) |
| Store unavailable in Combat | [Large](../output/qa/rc-032-store/ui/store-unavailable-combat-menu-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/store-unavailable-combat-menu-elite-360x640.png) |
| Store-equipped final results | [Large](../output/qa/rc-032-store/ui/store-equipped-final-results-normal-450x1000.png) | [Narrow](../output/qa/rc-032-store/ui/store-equipped-final-results-elite-360x640.png) |

The remaining two captures show the used rune allowance. Fixed actions remain reachable; overflowing catalogue/error/results content scrolls above them. The 360×640 configured window retains the project's 288×640 rendered content plus side letterboxing. These are actual renderer captures, not mockups.

New runtime files are `scripts/core/store_policy.gd` and `scripts/ui/store_viewer.gd`, with integration in `run_state.gd` and `application_shell.gd`. Shared Android/iOS inventories and decoded-payload checks include both scripts and actual Menu → Store → Back navigation. Tests, genuine predecessor fixtures and QA remain excluded. Final [resource-only PCK](../builds/rc-032-store-resources/RuneCast.pck): **12,463,804 bytes, 393 entries**, SHA-256 `96facf6f4a987ebe28c0cdce246b854a26ce6a0cf29d2c904120a5aa9d990d01`. [Source manifest](../output/qa/rc-032-store/resources/source-manifest.json). This is not a native Android/iOS build.

From the same isolated PowerShell environment as the manual walkthrough:

```powershell
$storeEngine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$storePython = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $storeEngine --headless --path . --audio-driver Dummy --script res://tests/rc032_store_state_runner.gd
& $storeEngine --headless --path . --audio-driver Dummy --script res://tests/rc032_store_shell_runner.gd
& $storeEngine --path . --audio-driver Dummy --script res://tests/rc032_store_shell_runner.gd -- --capture-rc032-store
& $storePython tools/verify_rc032_store_process.py
& $storePython tools/verify_rc032_store_migrations.py
& $storePython tools/verify_rc032_regressions.py --output-root output/qa/rc-032-store/regression
& $storePython tools/verify_rc032_regressions.py --render --only shared-menu,panel-spacing,reference --output-root output/qa/rc-032-store/render-regression
& $storeEngine --headless --path . --export-pack 'iOS' builds/rc-032-store-resources/RuneCast.pck
& $storePython tools/verify_ios_resources.py --pack builds/rc-032-store-resources/RuneCast.pck --engine $storeEngine --project-root . --report output/qa/rc-032-store/resources/resource-audit.json
```

The absolute-reference command deliberately retains its nonzero result for the 15 documented geometry failures. The current Store/lifecycle integration has no remaining implementation blocker; production content, balance and device work above remain open under their original task IDs.
