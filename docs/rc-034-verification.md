# RC-034 — Production enemy encounters and route integration

October 25, 2026 (Australia/Sydney). **Technical encounter delivery is implemented; full RC-034 acceptance remains pending RC-023 human/device acceptance.** Ordinary New Run now uses all five registered enemies through the existing nine-visit application route. Individual ordinary-resource victories and a complete normal-branch tower are reproduced. The recorded elite strategy does not demonstrate a complete win; provisional balance remains open. RC-035/036, remaining character packs, final presentation and device acceptance are not complete.

Process exception: an initial read-only `git status --short` was mistakenly dispatched in parallel with opening the pasted request, before its no-Git restriction was read. This was disclosed immediately. No subsequent Git operation or Git metadata read was performed. No native mobile builds, SDK installation, signing, generated art or generated sound were performed.

## Registered content and rules

| Actor / encounter | Role | Supported board IDs | HP | Repeating announced attacks |
| --- | --- | --- | --- | --- |
| `wickling` / `wickling` | normal | `board_gallery`, `board_ossuary` | 26 | 6, 6, 10 |
| `stone_sentinel` / `stone_sentinel` | normal | `board_gallery`, `board_ossuary` | 42 | 5, 13, 5 |
| `chain_warden` / `chain_warden` | elite | `board_ossuary` | 58 | 8, 8, 18 |
| `shadeling` / `training_shadeling` | boss | `board_training` | 32 | 8, 12, 6 |
| `bell_keeper` / `bell_keeper` | guardian | `board_belfry` | 80 | 8, 12, 16; at/below 40 HP, next surviving turn starts 12, 16, 20 |

The four new [encounter JSON files](../data/production_wickling_encounter.json) use the existing loader, [enemy definitions](../data/enemies.json), production boards/rules and `starter`. No requested baseline value was adjusted. Shadeling and calibration definitions retain their original values and normalized selected-configuration signatures. Adding an unrelated enemy does not fingerprint the entire enemy catalogue.

Player configuration remains 30/30 HP, three energy and three ordinary draws, with two each of Spark, Shield, Focus and Conjure Spark. Every board shares the same endpoint generation, independent streams, finite connector kits and no obstacles/prefills. Board names confer no additional stock or mechanical difficulty. Actual health, ranked UIDs, relics, allocator and RNG carry between encounters; entry grants no reset/heal.

Bell Keeper consumes RC-033's immutable optional `phase_two`, detached `snapshot.enemy_action`, scalar announced intent and committed `enemy_phase_changed`. A crossing Cast resolves the already announced attack with its shield, then normal cleanup. If both survive, phase two starts at index zero before the ordinary next turn; it advances/wraps without retriggering. Enemy lethal suppresses retaliation and phase change; player lethal suppresses all next-turn work. No UI HP polling drives it. Aggregate requested/applied damage, physical costs, upgraded effects, relic ordering, Pass and replay remain unchanged.

Shadeling's retained hit pose adds no dodge mechanic. Dodge remains deferred. No armour, statuses, summons, healing, extra targets or additional phases were introduced.

## Route and compatibility

The same seeded graph has nine visits: **normal → event → normal → normal → normal/elite branch → Shadeling boss → shop → recovery → Bell Keeper guardian**. The only normal identities are Wickling and Stone Sentinel. Depth six remains `room_normal` with explicit `boss` role; it does not finish the tower. The six room families, event selections, seeded crossover and branch edges remain unchanged. Inspection stays read-only and entry requires confirmation.

[`EncounterResolver`](../scripts/core/encounter_resolver.gd) owns trusted ID/actor/role/board/path registrations. It rejects mismatches before a visit or resource changes. Saved strings never become file paths. The retained development registration is unavailable to production routes/restores; excluded fixtures supply their own trusted context. Restore also binds the normalized setup to the **most recently selected battle visit**, so a different otherwise-supported board or future enemy is not accepted.

Run **v6**, profile/route **v1**, Store `rc032_store_v1` and envelope `rc028_local_v1` remain current. The compatibility rule recognizes only a complete genuine historical planned graph: all non-Shadeling battle IDs empty with their original pending flags. Mixed empty/authored routes, arbitrary empty IDs and historically impossible normal/elite/guardian visits reject. Original route/history, rewards, resources and terminal signatures validate **before** any hydration. An unfinished genuine old graph then fills only encounter IDs/pending flags; route/node/visit IDs, edges, selected branches, event choices, RNG and all history stay unchanged. It is not regenerated. Existing terminal graphs remain untouched, preserving genuine abandonment signatures and rejecting forged signatures.

Historical fixture route subclasses now explicitly preserve their old planned shape before applying their original substitutions. Fixture-only Shadeling/Gallery registration stays outside the production whitelist. Real old saves using a nonnegative int64 seed can enter through a matching validated run checkpoint; the standalone seed-override bound remains unchanged, and restored RNG streams are unchanged.

Live Resume retains the current Combat model/preparation. Quit and fresh-process Continue replay the exact committed entry; there is no mid-turn disk saving. Clone → validate/save → publish remains authoritative. Failed entry/outcome/reward writes retain prior owners/durable bytes and the identical Retry candidate. Retained reward offers, claims, permanent unlocks, ranks, unique relics, historical room policies, Store receipts/allowances, HP/Gold and endings remain validated.

## Rewards and interim economy

Production policy retains its historical policy ID and original Shadeling rule and adds exact new encounter/role entries. Every victory offers up to three distinct eligible implemented definitions, Choose one fresh run-owned copy or Skip. Already-owned copies do not exclude a definition. Small pools shrink; empty pools permit Skip. Generated Free Spark and unimplemented definitions remain excluded. Every new battle explicitly pays **zero Gold**, as does Shadeling.

Shadeling and Bell Keeper additionally resolve the accepted permanent-definition milestone. The four currently implemented ownable definitions are already unlocked in a normal profile, so the milestone records exhaustion with no grant or compensation. Guardian victory stays pending until every required component resolves. Acknowledgement grants nothing; terminal review cannot replay battle or reward transactions.

Final battle Gold and the elite relic offer remain **RC-036** work. Historical 15/30-Gold proposals and excluded 250-Gold fixture payouts are not production defaults. With zero starting/battle Gold and only one event, a Satchel yields 20 or a Tithe 40; other events yield none. Therefore the 45/90-Gold separate Store cannot be funded by this ordinary route. Shop rune/upgrade/removal prices of 30/35/40 are reachable only through Tithe and its HP tradeoff; the 60-Gold relic is not. The recorded runs leave the shop and retain zero Gold. This proves honest affordability and navigation, not a complete economy.

## Temporary presentation

[`TemporaryEnemyActor`](../scripts/ui/temporary_enemy_actor.gd) is a shared code-native token with distinct simple symbols and palette accents, retaining the arena's foot/body/attack attachments. The actual name, health and inspectable announcement remain live. Hit tint/motion, attack motion/contact and defeat fading are observational and respect reduced motion. Only Shadeling uses Shadeling art. Unknown or unavailable actor accents are intentionally silent.

The new actor contact ratio is explicitly 0.5. The presenter sends shared hit/block feedback at that event timing; it does not sample a hidden Shadeling pose or its metadata. Shadeling retains its existing actor timing. Bell Keeper retains RC-033's silent phase text. These temporary tokens do **not** complete RC-037 Wickling, RC-038 Stone Sentinel, RC-039 Chain Warden or RC-040 Bell Keeper. RC-042 still owns final integration; music, final guardian pose and environment remain outside scope.

Actual rendered enemy/intent/hit/attack/victory and guardian transition captures exist at **450×1000 and 360×640 configured windows**. All 48 presentation and 34 shell captures were inspected individually. The narrow viewport retains the existing 288×640 content and side letterboxing. These are actual renderer captures, not resized mockups or device acceptance. [Presentation review](../output/qa/rc-034/presentation/visual-review.json), [integrated shell review](../output/qa/rc-034/shell/visual-review.json).

## Legal playability evidence

The excluded [verification player](../tests/helpers/rc034_player.gd) chooses a simple route or one Split/Join diamond on the **sampled** board, then uses real technique, placement, rotation and Cast/Pass commands. Generated topology witnesses are search aids, never runtime prefills. Planned damage/shield/cost must equal the real evaluator. No post-launch HP, ownership, energy, stock, endpoints or RNG is written. It is a bounded heuristic, not an optimal solver or human balance study.

All individual victories begin at 30/30 HP with the ordinary eight-card collection in configured order: Spark UID0, Shield1, Conjure2, Spark3, Shield4, Focus5, Focus6, Conjure7; no upgrades/relics, normal three-draw/three-energy setup. [Full entry snapshots, commands, turns and failed guardian seeds](../output/qa/rc-034/play/individual.json) record exact state. These selected seeds are reproduction witnesses; gameplay does not search or reroll seeds.

| Encounter | Seed | Turns / remaining HP | Practical supported response shown |
| --- | --- | --- | --- |
| Wickling | 0 | 2 / 29 | Conjure plus a legal diamond delivers 18 damage and 5 shield on turn one, limiting the 6 attack to 1. A 12-damage lethal second Cast prevents retaliation. |
| Stone Sentinel | 0 | 3 / 22 | First 18 damage / 5 shield fully blocks its 5. A 6-damage / 5-shield second Cast reduces the telegraphed 13 to 8; 18 damage kills on turn three. |
| Chain Warden | 0 | 6 / 3 | After its first 18 spike, a shield-only 10-shield Cast blocks the next 8 while cycling the hand. The last 12 damage kills before the next announced 18. |
| Shadeling | 0 | 3 / 20 | Two mixed damage/shield Casts reduce its 8/12 retaliation, followed by a generated-Free-Spark lethal Cast. No dodge is applied. |
| Bell Keeper | 5 | 7 / 8 | Shield-only 10 blocks the opening 8. Damage/shield diamonds produce 12/10 then 24/10. Turn five crosses 44→20 HP with 24 damage, still retaliates for the announced 12, then announces phase-two 12. The final 12/10 Cast kills before the announced 16. |

Bell Keeper seeds 0–4 lost before the seed-five victory; retained failures matter. Supplemental exact-boundary probes use explicitly labelled pre-launch test resources, separately from these ordinary victories, and cannot establish playability.

### Complete ordinary normal route

Seed **1**, normal branch, real new profile and unchanged starter. The shell and model both reproduce the following history. Rewards choose Conjure when offered, otherwise Shield, Spark, then Focus. Every selected card/UID and all controller commands are retained in [normal-1.json](../output/qa/rc-034/play/runs/normal-1.json) and the [shell traces](../output/qa/rc-034/shell/traces-capture.json).

| Visit / node | Encounter or actual room choice | Entry → exit HP | Collection after reward |
| --- | --- | --- | --- |
| 1 / d1b | Wickling, Ossuary | 30 → 24 | 9 |
| 2 / d2b | Blood Tithe: Leave | 24 → 24 | 9 |
| 3 / d3 | Stone Sentinel, Gallery | 24 → 21 | 10 |
| 4 / d4a | Wickling, Gallery | 21 → 20 | 11 |
| 5 / d5a | Wickling, Ossuary | 20 → 18 | 12 |
| 6 / d6 | Shadeling, Training | 18 → 18 | 13 |
| 7 / d7 | Shop: browse, Leave | 18 → 18 | 13 |
| 8 / d8 | Recovery: Recover | 18 → 28 | 13 |
| 9 / d9 | Bell Keeper, Belfry | 28 → 5 | 14 |

Gold stays zero; no relics or upgrades are injected. Shadeling does not end the tower. Guardian rune choice and exhausted permanent milestone resolve before final victory. Fresh entry reconstruction is checked for every fight; final Home/Continue reopens read-only results.

### Elite attempts and remaining tuning

Seeds **0–63** were attempted using the same ordinary strategy and real room/reward APIs. **None demonstrated an elite-branch tower victory.** This is not proof that the branch is impossible. The [complete attempt summary](../output/qa/rc-034/play/run-summary.json) links every actual failure and command history.

The rendered seed **6** journey reaches the final guardian: d1a Wickling (30→29); d2b Etched Desk upgrades the existing Conjure UID2 for free; d3 Wickling (29→29); d4a Wickling (29→27); d5b Chain Warden (27→13); d6 Shadeling (13→10); d7 Leave; d8 Recover (10→20); d9 Bell Keeper defeats the player. [Exact trace and entry collection for every visit](../output/qa/rc-034/play/runs/elite-6.json). The real shell shows defeat results, not an invented completion. Additional real seed-six d1b entry exercises Stone Sentinel on Ossuary, completing all normal/board combinations across shell journeys.

### Try the route

Normal play remains `.\tools\godot.ps1 -Action run`: **Home → New Run → inspect a gold-highlighted Map node → Enter → confirm**. Fight, review the rune choice/Skip, then acknowledge and continue. Both branch alternatives remain available at depth five. Shop and recovery remain main-screen rooms; Menu/Options/Store behavior is unchanged.

For an isolated fixed-seed reproduction through the same shell:

```powershell
.\tools\rc034_route.ps1 -Seed 1
.\tools\rc034_route.ps1 -Seed 6 -Narrow
```

These open Home and bind the existing New Run seed argument. They do not pre-play or inject anything. Continue uses that seed's isolated save. Use the tables and exact logged zero-based row-major controller commands to reproduce decisions/construction. All paths are under `output/qa/rc-034/manual`; ordinary player saves/settings are separate.

## Verification and packaging

All checks use pinned **Godot 4.7.2.stable.official.ed1daf0bf** with isolated saves/settings/application-data directories. Final evidence is listed below; initial failed assertions/logs remain alongside repaired reruns.

| Check | Result | Evidence |
| --- | --- | --- |
| Content schema, values, six new board tuples, historical signatures, exact role policies/pools | 122 checks, 0 failures | [Content](../output/qa/rc-034/content/results.json) |
| Seeded route coverage, strict invalid-entry purity, legacy original-history validation, replay/Retry/reentrancy | 879 checks, 0 failures | [Route](../output/qa/rc-034/route/results.json) |
| Supported-other-board/future-enemy restore substitutions | 14 checks, 0 failures | [Adversarial](../output/qa/rc-034/adversarial/results.json) |
| Actual production Bell Keeper exact/crossed threshold, shield, lethal, player defeat, cycle/ordering | 289 checks, 0 failures | [Guardian](../output/qa/rc-034/guardian/results.json) |
| Temporary presentation, ordinary legal replay and actual-window inspection | 1,007 rendered / 959 headless checks, 0 failures; 48 images inspected | [Presentation](../output/qa/rc-034/presentation/results-capture.json) |
| Real production shell, normal victory/elite defeat, all board combinations, entry/outcome/reward failed Retry | 564 rendered checks, 0 failures | [Shell](../output/qa/rc-034/shell/results-capture.json) |
| Fresh-process new encounter lifecycle | 919 prepare + 219 restart checks, 0 failures, 63 checkpoints | [Prepare](../output/qa/rc-034/process-01/prepare.json), [restart](../output/qa/rc-034/process-01/restart.json) |
| Existing Combat/content/route/reward/save/rooms/lifecycle regressions | 10,244 checks across 28 suites, 0 unresolved failures | [Consolidated final results with original/rerun provenance](../output/qa/rc-034/regression/results-final.json) |
| RC-033 core / ordered presentation / rendered touch / two-process lifecycle | 191 / 159 / 48 / 74 checks, 0 failures | [Phase regressions](../output/qa/rc-034/phase-regression/results.json) |
| Additional Store model / shell | 317 / 350 checks, 0 failures | [Model](../output/qa/rc-034/store-regression/evidence/rc-032-store/model/results.json), [shell](../output/qa/rc-034/store-regression/evidence/rc-032-store/ui/results-headless.json) |
| Store failure/Retry/restart/recovery | 1,980 checks across 240 launches, 0 failures | [Durability](../output/qa/rc-034/store-process/bcbb7b5807/results.json) |
| Genuine v1–v6 migration/recovery | 3,547 checks, 40 specimens, 440 launches, 0 failures | [Compatibility](../output/qa/rc-034/migrations/b8df906e51/results.json) |
| Shared Menu / popup spacing | 164 / 393 rendered checks, 0 failures | [Rendered suite](../output/qa/rc-034/rendered-regression/83e594a01f/results.json) |
| Absolute reference geometry | 257 assertions; all assertions and measurements exactly match baseline, including the 15 documented failures | [Exact comparison](../output/qa/rc-034/reference/baseline-comparison.json) |
| Resource package | 416 integrity / 188 payload-decode checks and 33 Python tests pass | [Audit](../output/qa/rc-034/resources/resource-audit.json), [tests](../output/qa/rc-034/resources/tool-tests.txt) |

The supplemental guardian runner loads the real production enemy/configuration but supplies pre-launch 1,000-HP/eight-card custom-damage probe loadouts (8 current HP for the fatal case) to isolate 39/40/41-damage crossings and exact lethal boundaries. Placement and Cast still use legal actions and generated endpoints/kits; no live HP/phase/config writes. This is mechanics evidence only.

Initial verification found obsolete expectations that normals were unavailable and old routes never changed encounter references. Those checks now test an unavailable-load/invalid-registration boundary and compare all history fields while allowing only the specified ID/pending hydration. An initial concurrent regression run caught a transient script parse error during editing and timed out; final clean runs replace it explicitly. The final broad run passed every assertion, but RC-032 UI reported one resource still in use at shutdown; a focused rerun passed all 324 checks without warnings/errors and its provenance is retained in the consolidated report. A test launch initially used generic `--capture`, which the existing application interprets as its own capture-and-exit mode; the verifier now uses `--capture-rc034-shell`. The adversarial other-board acceptance was fixed in runtime and reverified. No assertion was removed to conceal the 15 geometry baseline failures.

Production JSON is explicitly enumerated in export/package inventories. The resource-only PCK contains all twelve production JSON files and the code-native actor, and loads the exact six new board tuples through the shipped resolver. The payload probe checks actual New Run/entry/Home/Continue/reconstruction, role rewards and guardian data. Tests, RC-032/033/034 fixtures, the 4.3 MB topology search data and QA remain excluded. This is a resource package, not a native application build.

Final [RuneCast.pck](../builds/rc-034-resources/RuneCast.pck): **399 entries, 12,483,100 bytes**, SHA-256 `b7242e5e064d0e17b22e4e7bd3e8770c9f9e9c675fbb48c61dd94949c5ebfa1d`. The [source manifest](../output/qa/rc-034/resources/source-manifest.json) records 210 source hashes. The last compatibility adjustment preserves historical visual-only player-damage text for excluded actors with no metadata; it invents no contact/audio. Registered actors retain explicit event timing. The package was rebuilt after that change.

### Reproduce verification

```powershell
$rc034QA = 'C:\Dev\RuneCast\output\qa\rc-034\rerun-environment'
$env:APPDATA = Join-Path $rc034QA 'appdata'
$env:LOCALAPPDATA = Join-Path $rc034QA 'localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$rc034Engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$rc034Python = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_content_runner.gd
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_route_runner.gd
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_adversarial_runner.gd
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_guardian_runner.gd
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_play_probe.gd
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_run_probe.gd
& $rc034Engine --path . --audio-driver Dummy --script res://tests/rc034_presentation_runner.gd -- --capture-rc034
& $rc034Engine --path . --audio-driver Dummy --script res://tests/rc034_shell_runner.gd -- --capture-rc034-shell
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_process_runner.gd -- --stage=prepare --save-root=res://output/qa/rc-034/process-rerun
& $rc034Engine --headless --path . --audio-driver Dummy --script res://tests/rc034_process_runner.gd -- --stage=restart --save-root=res://output/qa/rc-034/process-rerun
& $rc034Python tools/verify_rc032_regressions.py --output-root output/qa/rc-034/regression-rerun
& $rc034Python tools/verify_rc032_regressions.py --render --only shared-menu,panel-spacing,reference --output-root output/qa/rc-034/rendered-rerun
& $rc034Python tools/verify_rc032_store_process.py --output-root output/qa/rc-034/store-process-rerun
& $rc034Python tools/verify_rc032_store_migrations.py --output output/qa/rc-034/migrations-rerun
& $rc034Engine --headless --path . --editor --export-pack 'iOS' builds/rc-034-resources/RuneCast.pck
& $rc034Python tools/verify_ios_resources.py --pack builds/rc-034-resources/RuneCast.pck --engine $rc034Engine --project-root . --report output/qa/rc-034/resources-rerun/resource-audit.json
```

The reference suite intentionally exits nonzero for its known 15 failures. Compare the exact assertions/measurements; do not waive new failures. Use fresh process-checkpoint destinations for each prepare/restart pair.

## RC-035 handoff and open acceptance

RC-035 can build on real normal/elite/boss/guardian fights, exact role-bound reward policies, permanent-definition milestones, instance-aware upgrades/relic hooks, strict content/restore registration and complete normal-route lifecycle. Add the missing real rune definitions through compatible explicit reward/shop/Store registration. Preserve old selected-content signatures, retained offers/receipts and original policy semantics when expanding eligibility; avoid silently reinterpreting saves. Generated Free Spark remains temporary and excluded from ownership/pools.

Keep **RC-023** as the prerequisite for full acceptance. RC-036 retains battle Gold, the elite relic contract, affordability and final encounter/route tuning; RC-045 retains human balance. The elite completion limitation and selected-seed nature of victories must remain visible. RC-037–040 retain actual character packs; RC-041/042 retain remaining art/integration; RC-022 and mobile build/signing work remain deferred. No completion of those tasks is implied.
