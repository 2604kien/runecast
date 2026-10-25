# RC-035 — Complete bounded rune, upgrade, relic and Store catalogue

October 25, 2026 (Australia/Sydney). **The scoped technical catalogue delivery and desktop verification are complete. RC-023 human/device acceptance remains the prerequisite for full acceptance.** RC-036 economy, RC-041 icons, RC-042 final art integration and RC-045 human balance remain open.

## Definitions and ownership

[`data/runes.json`](../data/runes.json) contains exactly twelve ownable definitions and separate generated Free Spark. The original five definitions preserve their original values, costs, names and semantics. Added definitions are Ember (3 damage, 1 energy), Flare (10 damage, 3), Barrier (9 shield, 2), Bulwark (13 shield, 3), Deep Focus (draw up to 4, 2), Twin Conjure (create 2 Free Sparks, 1), Cinder Guard (4 damage AND 3 shield, 2), and Ward Spark (2 damage AND 2 shield, 1).

Mixed runes use the existing validated `damage_shield` representation. Both values travel through the circuit; the physical rune pays once. Every effect rune keeps straight ports. Techniques resolve immediately through the guarded command path. Free Spark remains 6 damage, cost zero and temporary; neither generated UID nor definition enters permanent ownership, unlock/reward/shop/Store pools, upgrades or saved run collections. No statuses, targeting, healing runes, energy generation, discard triggers or extra definitions were added.

Deep Focus retains the existing discard-before-draw ordering: the activated technique enters discard before drawing, so an otherwise empty pile can reshuffle and draw that same physical technique once. It never duplicates the UID or promises four available cards. Short/full pools and reshuffling are tested. Twin Conjure creates two distinct rank-zero temporary UIDs; both expire on accepted Cast/Pass, including terminal cleanup.

The existing shared instance resolver activates all eight rank-zero→rank-one contracts: Spark 6→8 damage; Shield 5→7 shield; Focus draw 2→3; Conjure create 1→2; Ember 3→4 damage; Flare 10→13 damage; Barrier 9→11 shield; Cinder Guard 4/3→6/4. IDs, costs and ports do not change. Rank belongs to the exact UID. Bulwark, Deep Focus, Twin Conjure, Ward Spark, Free Spark and connectors have no upgrade.

The six existing relic authorities/hooks remain unchanged: Ember Lens adds 2 once after positive final damage aggregation; Ward Seal adds 2 once after positive final shield aggregation and gives nothing on Pass; Opening Tome draws one extra owned opening card; Copper Coil gives one first-turn energy; Mender's Token adds 4 capped recovery healing with no Combat/Blood Tithe effect; Heart Stone gives 4 current/max HP once on acquisition outside Combat. Ownership is unique across sources and lasts only for the run. Mender's description now states its Combat exclusion explicitly.

## Registration, unlocks and offerings

[`catalogue_policy.gd`](../scripts/core/catalogue_policy.gd) separates the twelve registered ownable IDs from the four initially unlocked IDs. The starter remains two Spark, two Shield, two Focus and two Conjure. The eight additions are implemented but initially locked. Shadeling and guardian milestones can offer one still-locked registered definition. Its accepted unlock persists without allocating a card or changing the starter.

Future run-card rewards, route-shop stock and Store entries use the retained run catalogue plus current profile unlocks. Reward offerings remain distinct with Choose/Skip, allow duplicate owned copies, shrink for small pools and retain explicit exhaustion. Permanent-definition offers retain the accepted required choice behavior; there is no new Skip option or compensation. Unlocking does not reroll an already committed reward or shop.

The compact Store keeps stable definition identities, six relics, 45 Gold per rune and 90 per relic. One rune and one relic purchase total per run remain independent of route-shop stock and service allowances. Rune purchases allocate a fresh rank-zero UID; relics remain unique. Removal, Home and restart do not restore either allowance. Access stays between fully settled rooms, with Back returning to the retained Menu. Production battle Gold remains zero. Explicit fixture funding proves transactions only, not production affordability.

## Compatibility and durable transactions

**New Run is the catalogue expansion boundary.** Existing runs keep the complete historical catalogue and its eligibility semantics until they finish or are abandoned. They can continue through the real RC-034 enemies, but cannot acquire new catalogue definitions within that retained run. New Run uses the complete expanded catalogue and preserves the profile's existing unlocks without granting any new ones automatically.

Current serialization remains run **v6**, profile/route **v1**, envelope **`rc028_local_v1`**. New runs use reward policy **`rc035_rewards_v2`**, Store **`rc035_store_v2` / version 2**, and route-shop **eligibility version 2**. Historical runs retain **`rc027_owner_2026_10_22`**, **`rc032_store_v1` / version 1**, and shop **eligibility version 1**. The existing shop/service policy versions and prices remain intact. Policy metadata must agree with the complete retained catalogue; swapping the marker alone rejects.

The trusted compatibility module locally defines the entire original five-definition catalogue. Restore reconstructs current or complete historical candidate setups and compares the original saved fingerprint before selecting one. It never replaces a saved hash, executes saved definitions or accepts arbitrary subsets. Encounter/board/role binding, legacy planned-route hydration and original terminal/abandonment signature validation remain authoritative. Profile validation uses the current registered catalogue while the retained run filters its own historical pool.

Before modifying catalogue/schema behavior, 19 genuine specimens and the original rune source were retained under [`tests/fixtures/rc035`](../tests/fixtures/rc035/origins.json). Provenance records original paths, byte counts and SHA-256 hashes. They cover RC-034 entries/interruptions, pending rune/permanent choices, exhausted milestones, shops/services, ranked/relic ownership, Store purchases and terminal runs. The pending-permanent v6 specimen was produced by the unchanged pre-expansion runtime from a validated genuine predecessor through ordinary save commit; version numbers were not edited. The older v1–v6 originals remain separate and unchanged.

Final coverage contains **21 envelopes**: review additionally indexed two genuine v6 abandonment files already retained in the unchanged RC-034 output before this task. Their original bytes and timestamps are documented separately; they were not regenerated as historical saves. Original RC-034 replay witnesses were also copied with provenance and used to compare exact openings, commands and terminal states for every real enemy.

Clone → validate/save → publish remains the transaction boundary. Failed writes preserve previous durable bytes and owners; same-process Retry uses the identical candidate. Restart restores durable progress only. Historical offers, exhausted milestones, receipts, prices, limits, UID allocation, chronological HP/Gold and RNG are retained; no exhausted award is reopened by migration.

## UI and art scope

Hand/inspection/piles/collection/rewards/shop/service/Store/results continue to resolve effective instance values. Compact hand summaries keep both mixed values visible and fit larger technique counts within the approved hand lane. Full inspection explains generated Free Spark damage, zero cost and Cast/Pass expiry. Long names and upgrade markers retain supported inspection access. Unlock presentation includes future Store eligibility.

The approved Combat composition, display-only forecast, no board-slot inspection, absence of category rows, touch routing and shared modal sizing are preserved. Existing damage, shield, draw and conjure family glyphs are reused. Dedicated mappings for all eight additions and six relics remain RC-041; final art integration remains RC-042. No image/audio generation, native build, SDK installation or signing was performed.

## Reproduction and actual verification

Normal play remains `.\tools\godot.ps1 -Action run`. Start **New Run**, fight through the route, resolve the Shadeling/guardian permanent-definition choice, then inspect future rewards or settled-room **Menu → Store**. Existing runs remain on their historical catalogue until replaced. A new unlock grants eligibility, so it need not immediately appear in the up-to-three random reward options. Store browsing lists every eligible unlocked definition, with honest funds/allowance restrictions.

For isolated exploration from `C:\Dev\RuneCast`:

```powershell
.\tools\rc035_catalogue.ps1 -Mode Combat
.\tools\rc035_catalogue.ps1 -Mode Store -Narrow
.\tools\rc035_catalogue.ps1 -Mode Upgrade
```

Combat mode explicitly starts a gallery with all twelve owned cards, a twelve-card opening, 400 initial HP and normal three energy against real Stone Sentinel content. Drag the hand; Info/hold reads effects; tapping a technique activates it. Store mode declares an all-unlocked initial profile but retains the normal eight-card starter, wins an actual calibration Wisp battle for **500 fixture Gold**, then opens the ordinary shell. Upgrade mode legally buys Cinder Guard for 45 and refines its UID through recovery; Collection shows rank one and 6 damage/4 shield. All are excluded verification fixtures, never ordinary funding or balance evidence. Each Store/Upgrade launch creates a **fresh timestamped save**; repeating the launcher does not resume its previous gallery. Same-process Home/Continue works; the process tests below demonstrate actual restart persistence.

The ordinary progression proof is [`prepare-traces.json`](../output/qa/rc-035/compatibility-final/prepare-traces.json): normal seed 1 uses real fights and the unchanged starter to reach Shadeling and unlock **Cinder Guard**. The owned collection/allocator remain unchanged by the unlock; later shop/Store eligibility contains five definitions. In a separate process, [`restart-traces.json`](../output/qa/rc-035/compatibility-final/restart-traces.json) starts seed 0 with the same profile and eight-card starter. Wickling's real reward grants Cinder Guard **UID11**, which transfers through Stone Sentinel and executes against the next Wickling. The demonstrated checkpoint ends at **26 HP, zero Gold**. [`production-unlocked.json`](../output/qa/rc-035/compatibility-final/production-unlocked.json) and [`new-run-acquisition.json`](../output/qa/rc-035/compatibility-final/new-run-acquisition.json) are durable local envelopes, not invented milestone records.

All engine checks use pinned **Godot 4.7.2.stable.official.ed1daf0bf** with isolated save/settings and application-data directories. Counts overlap across suites and are not unique-test totals.

| Coverage | Actual result / evidence |
| --- | --- |
| Exact catalogue, all eight additions through Combat, mixed Split/Join/relic aggregation, draw/expiry, eight upgrade services, new Store/shop rejection boundaries | **480 checks, 0 failures**; [results](../output/qa/rc-035/catalogue/results.json), [accepted Combat commands](../output/qa/rc-035/catalogue/combat-commands.json) |
| All eight purchased/refined UIDs in a separate process, exact payload/rank/history/allowance and repeated-upgrade rejection | **25 checks, 0 failures**; [restart](../output/qa/rc-035/catalogue/restart-results.json) |
| 21 genuine retained envelopes, historical real-enemy replay, malformed catalogue/policy/ID/rank rejection, ordinary unlock and later acquisition/use | **177 prepare + 20 separate-process restart checks, 0 failures**; [prepare](../output/qa/rc-035/compatibility-final/prepare.json), [restart](../output/qa/rc-035/compatibility-final/restart.json) |
| New cards, inspection/piles, large hands, exact upgrades, real unlock, compact expanded Store | **286 headless / 332 rendered checks, 0 failures**; [headless](../output/qa/rc-035/ui/results-headless.json), [rendered](../output/qa/rc-035/ui/results-capture.json) |
| Existing Combat/content/rewards/shops/services/saves/collection/lifecycle suites | **10,245 checks across 28 suites, 0 unresolved failures**; [consolidated report with original/rerun provenance](../output/qa/rc-035/regression/results-final.json) |
| Retained Store, RC-033 and RC-034 model/presentation/shell suites | **3,860 checks across 11 suites, 0 unresolved failures**; [consolidated report](../output/qa/rc-035/retained-regression/results-final.json) |
| RC-034 fresh-process production entries/outcomes/rooms/rewards | **919 prepare + 219 restart checks, 63 checkpoints, 0 failures**; [prepare](../output/qa/rc-035/production-process/prepare.json), [restart](../output/qa/rc-035/production-process/restart.json) |
| RC-033 phase lifecycle | **46 prepare + 28 restart checks, 0 failures**; [prepare](../output/qa/rc-035/phase-process/prepare.json), [restart](../output/qa/rc-035/phase-process/restart.json) |
| Current Store write/flush/close/backup/replace failures, identical Retry, restart and previous-copy recovery | **1,980 checks across 240 launches, 0 failures**; [campaign](../output/qa/rc-035/store-process/2451e49189/results.json) |
| Genuine v1–v6 migration/recovery, 40 original specimens | **3,547 checks across 440 launches, 0 unresolved failures**; [consolidated compatibility](../output/qa/rc-035/migrations/results-final.json) |
| Shared Menu / popup spacing | **164 / 393 rendered checks, 0 failures**; [rendered campaign](../output/qa/rc-035/rendered-regression/a7b743b43c/results.json) |
| Reference geometry | **257 assertions, same 15 documented failures**, no new failed assertion; [exact failure comparison and explicit intentional text-layout differences](../output/qa/rc-035/reference/baseline-comparison.json) |
| Final exported resource package | **434 integrity + 233 isolated decode checks, 0 failures; 34 Python tests pass**; [package audit](../output/qa/rc-035/resources/resource-audit.json), [tool tests](../output/qa/rc-035/resources/tool-tests.txt) |

Initial runs exposed obsolete four-definition exhaustion/Store-version assumptions, a fixture context using the current policy for genuine `pending-reward-v2`, a test-only inferred Dictionary type, and RC-034 shell automation trying to Skip a now-real mandatory permanent reward. Tests now select explicit historical contracts where historical behavior is under test, reject unknown Store v3 and mismatched legacy markers, and choose the offered unlock through ordinary controls. Original failed outputs remain; consolidated reports identify the focused passing reruns. No assertion was removed to hide a failure.

All 15 failed reference assertions retain identical descriptions and failing geometry measurements. The only other measurement changes are inside Conjure Spark's compact hand summary: three-line “Create 1 temporary Free Spark” becomes two-line “1 Free Spark / Temporary”, centered within the same fixed card. The report retains all 43 changed leaf measurements explicitly. Every assertion description and pass/fail outcome is unchanged; neither theme geometry nor reference assertions were altered.

### Actual-window visual review

All **46 PNGs** were inspected individually; [visual-review.json](../output/qa/rc-035/ui/visual-review.json) records hashes, dimensions and findings. Windows were actually configured to **450×1000 and 360×640**. The existing narrow layout renders a **288×640 content texture** within 36-pixel side letterboxes; its screenshots are that renderer output, not resized mockups or physical-device evidence.

| Screen | 450×1000 window | 360×640 window |
| --- | --- | --- |
| Mixed card | [Cinder Guard](../output/qa/rc-035/ui/hand-cinder_guard-450x1000.png) | [Cinder Guard](../output/qa/rc-035/ui/hand-cinder_guard-360x640.png) |
| Large technique count | [Twin Conjure](../output/qa/rc-035/ui/hand-twin_conjure-450x1000.png) | [Twin Conjure](../output/qa/rc-035/ui/hand-twin_conjure-360x640.png) |
| Larger hand/generated cards | [hand](../output/qa/rc-035/ui/larger-hand-generated-450x1000.png) | [hand](../output/qa/rc-035/ui/larger-hand-generated-360x640.png) |
| Effective upgraded values | [inspection](../output/qa/rc-035/ui/upgraded-mixed-inspection-450x1000.png) | [inspection](../output/qa/rc-035/ui/upgraded-mixed-inspection-360x640.png) |
| Ordinary permanent unlock | [choice](../output/qa/rc-035/ui/production-unlock-action-450x1000.png) | [choice](../output/qa/rc-035/ui/production-unlock-action-360x640.png) |
| Expanded compact Store | [technique rows](../output/qa/rc-035/ui/store-expanded-techniques-450x1000.png) | [technique rows](../output/qa/rc-035/ui/store-expanded-techniques-360x640.png) |

### Repeat verification

```powershell
$rc035QA = 'C:\Dev\RuneCast\output\qa\rc-035\rerun-environment'
$env:APPDATA = Join-Path $rc035QA 'appdata'
$env:LOCALAPPDATA = Join-Path $rc035QA 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$rc035Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$rc035Python = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $rc035Engine --headless --path . --audio-driver Dummy --script res://tests/rc035_catalogue_runner.gd
& $rc035Engine --headless --path . --audio-driver Dummy --script res://tests/rc035_catalogue_runner.gd -- --restart
& $rc035Engine --headless --path . --audio-driver Dummy --script res://tests/rc035_compatibility_runner.gd -- --stage=prepare --save-root=res://output/qa/rc-035/compatibility-rerun
& $rc035Engine --headless --path . --audio-driver Dummy --script res://tests/rc035_compatibility_runner.gd -- --stage=restart --save-root=res://output/qa/rc-035/compatibility-rerun
& $rc035Engine --headless --path . --audio-driver Dummy --script res://tests/rc035_ui_runner.gd
& $rc035Engine --path . --audio-driver Dummy --rendering-method gl_compatibility --script res://tests/rc035_ui_runner.gd -- --capture-rc035
& $rc035Python tools/verify_rc032_regressions.py --output-root output/qa/rc-035/regression-rerun
& $rc035Python tools/verify_rc035_regressions.py --output-root output/qa/rc-035/retained-rerun
& $rc035Python tools/verify_rc032_regressions.py --render --only shared-menu,panel-spacing,reference --output-root output/qa/rc-035/rendered-rerun
& $rc035Python tools/verify_rc032_store_process.py --output-root output/qa/rc-035/store-process-rerun
& $rc035Python tools/verify_rc032_store_migrations.py --output output/qa/rc-035/migrations-rerun
& $rc035Engine --headless --path . --editor --export-pack 'iOS' builds/rc-035-resources/RuneCast.pck
& $rc035Python tools/verify_ios_resources.py --pack builds/rc-035-resources/RuneCast.pck --engine $rc035Engine --project-root . --report output/qa/rc-035/resources-rerun/resource-audit.json
```

Use a fresh checkpoint directory for every prepare/restart pair. The catalogue/UI runners update their scoped evidence destinations; archive the prior evidence first if retaining a second campaign. The reference suite intentionally exits nonzero for its 15 known failures; compare exact assertions/measurements and investigate any new difference.

Final [`RuneCast.pck`](../builds/rc-035-resources/RuneCast.pck): **401 entries, 12,488,792 bytes**, SHA-256 **`937e98b94809af5c5389463e7ae471773283a09c80479ec7200e966ad0d684d0`**. The [source manifest](../output/qa/rc-035/resources/source-manifest.json) records 218 source files, including development data identified as excluded source only. Package audits check the explicit twelve production JSON resources, trusted catalogue compatibility code and all shipped runtime dependencies. The actual isolated PCK loader verifies all thirteen definitions/values, eight upgrade targets, four initial unlocks, and a twelve-entry Store for an explicitly unlocked decoder-only profile. Tests, funded fixtures, old-save specimens, topology/replay witnesses and QA are excluded. This is a resource-only export, not a native iOS/Android build.

## Remaining work and RC-036 handoff

RC-036 can use the twelve registered definitions, eight exact-instance upgrades, six unique relic hooks, permanent unlock progression, separate route-shop/Store policies and retained historical contracts. It still owns final income, elite relic rewards, prices, offerings/weights and pacing. Any later eligibility or price change must preserve existing versioned receipts and pools. The current zero-Gold production fights do not fund the 45/90-Gold Store. No fixture payout has been copied into production.

RC-034's existing evidence remains precise: the ordinary normal route demonstrated a victory; its recorded 64 elite attempts did not demonstrate a complete win. Catalogue verification does not settle elite balance or the 15–25-minute human-play target. RC-023 full acceptance, physical-device usability, final art/music and the separately owned future tasks remain open.

Process exception: the first command batch mistakenly included read-only `git status` before the pasted prohibition was read. This was disclosed immediately. No subsequent Git operation or Git metadata read was used for the implementation.
