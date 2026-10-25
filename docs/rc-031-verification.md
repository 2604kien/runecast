# RC-031 — Instance upgrades, relics and integrated rooms

October 24, 2026 (Australia/Sydney). **The requested bounded mechanics are complete.** Four existing production bases support individual upgrades; all eight upgrade contracts are explicit; six provisional run relics work through shops, recovery and events. RC-029's relic/upgrade gate and RC-030's refinement/Reliquary gate are now verified. This does not deliver RC-035's remaining production catalogue, the complete tower, final balance/artwork or RC-024A's unresolved Store/perk decisions.

## Ownership and supported content

A current run owns `{id, uid, upgrade_rank}` cards. Rank is the exact integer 0 or 1 and belongs to that UID. Upgrading retains the base ID, cost and ports; identical copies can differ. Rewards and purchases allocate rank-zero cards. Free Spark, generated cards and connectors cannot upgrade. New Run resets ranks/relics and starts at 30/30 while preserving the separate definition-unlock profile. No base catalogue entry is mutated.

| Contract | Before → after | Energy | Production availability |
| --- | --- | --- | --- |
| `upgrade_spark` | 6 → 8 damage | 2 | Supported |
| `upgrade_shield` | 5 → 7 shield | 1 | Supported |
| `upgrade_focus` | Draw 2 → 3 | 1 | Supported |
| `upgrade_conjure` | Create 1 → 2 Free Sparks | 0 | Supported |
| `upgrade_ember` | 3 → 4 damage | 1 | Base awaits RC-035 |
| `upgrade_flare` | 10 → 13 damage | 3 | Base awaits RC-035 |
| `upgrade_barrier` | 9 → 11 shield | 2 | Base awaits RC-035 |
| `upgrade_cinder_guard` | 4 damage / 3 shield → 6 / 4 | 2 | Base awaits RC-035 |

`instance_effects.gd` owns validation, effective-definition resolution, eligibility, before/after previews, contributions and summaries. Circuit, Combat techniques, hand/card rendering, supported inspection, piles, collection, target picking and removal use that interpretation. Rank survives installation, Remove, terminal/nonterminal cleanup, recycling, handoff, later battles and exact entry replay. Upgraded Conjure allocates two different temporary UIDs; both remain ordinary rank-zero Free Sparks and expire normally.

The loader and both Circuit evaluators now support a genuine `damage_shield` rune with `value: {damage, shield}`. Both contributions propagate through the graph while the physical rune pays once. [Excluded framework definitions](../tests/fixtures/rc031/upgrade_framework_runes.json) validate through the normal content loader and execute through Combat. They demonstrate the missing bases' contracts without adding them to production rewards, shops or the catalogue. `data/runes.json` remains unchanged.

## Effect order and relics

1. Validate and resolve the physical instance, including its rank.
2. Propagate its effective contribution through normal graph traversal, Split and Join; count each powered physical rune/connector cost once.
3. Aggregate at End. Ember Lens adds 2 once if aggregated damage is positive; Ward Seal adds 2 once if aggregated shield is positive. Zero stays zero for each corresponding conditional bonus.
4. Cast validates topology and affordability before mutations, pays once, emits the agreed aggregate damage, then preserves existing lethal suppression, surviving-enemy shield/retaliation and cleanup. Forecast, emitted events and actual execution use the same resolved totals.

An upgraded Spark before Split/rejoin contributes **16**, then Ember Lens makes **18**. Relic bonuses do not travel back through Split and are not applied per hit. Pass bypasses cast damage/shield hooks. Endpoint generation, connector kits, physical cost policy and temporary expiry remain unchanged.

`relic_policy.gd` registers only these six bounded hooks, with fixed hook order and unique definition ownership:

| Relic | Effect |
| --- | --- |
| Ember Lens | +2 final damage once, conditional on positive pre-relic damage. |
| Ward Seal | +2 final shield once, conditional on positive pre-relic shield; none on Pass. |
| Opening Tome | One extra owned draw after the normal initial battle draw. |
| Copper Coil | +1 initial-turn energy; later turns use normal configured energy. |
| Mender's Token | Recovery healing +4, capped at current maximum; Tithe and Combat healing unchanged. |
| Heart Stone | At acquisition outside Combat, maximum/current HP +4 once, capped at the new maximum. |

Opening hooks run at battle construction and supported successor entry. Live Resume, inspection and refresh retain the existing model. Entry replay reconstructs the same opening instead of applying an extra bonus to a live hand. Heart Stone is never applied by battle construction, inspection or restore. Relics occupy no board slots, do not stack duplicate definitions, and never become profile-owned items.

## Interfaces, offerings and transactions

The shell continues to use **clone_for_transaction → validate/save candidate → publish_transaction**. Scene preparation and all resource/receipt changes precede publication; feedback follows durable success. Failed writes retain prior owners and the exact candidate for Retry. Loading receipts is silent. Existing confirmation feedback handles these acquisitions; no asset pack or new audio owner was introduced.

| Interface | Responsibility |
| --- | --- |
| `InstanceEffects.resolve(catalog, instance)` | Validated detached effective definition; catalogue unchanged. |
| `InstanceEffects.upgrade_preview(...)` | Actual before/after definitions and upgrade ID. |
| `RunState.eligible_upgrade_targets()` | Detached eligible owned copies. |
| `RunState.upgrade_shop_rune(identity, uid)` | Exact UID, rank 0→1, 35 Gold and once-per-visit allowance/receipt together. |
| `RunState.buy_shop_relic(identity, slot_id)` | Retained unowned slot, 60 Gold, unique ownership and acquisition health together. |
| `RunState.resolve_service(identity, choice_id, target)` | UID for refinement or retained relic ID for Reliquary; benefit/payment and room completion together. |
| `RunState.prepare_relic_acquisition(relic_id)` | Pure validated acquisition plan, including health. Shared by current transactions; a future elite reward can reuse it inside its own staged transaction and authoritative source receipt. No elite payout policy is invented here. |

New shops keep three finite rune slots, the existing exact-copy removal policy and explicit Leave, and add one unowned relic slot and one eligible-instance upgrade service. Recovery offers either capped healing or one free upgrade. Etched Desk offers one free upgrade or Leave. Sealed Reliquary retains up to two distinct eligible unowned relics; selecting one pays 15 Gold and resolves the room atomically. Small pools show fewer choices; empty pools allow free Leave with no compensation. Selecting/canceling a target changes nothing. Full health, no eligible rune, insufficient Gold and exhausted relic pools remain explicit.

Relic offer generation uses **`rc031_relic_offers_v1`**, a separate per-visit generator seeded from the version, run seed, node, visit ordinal/node suffix and source (`shop`/`service`). Random run identity is excluded, so equal seed/route histories reproduce offers. Records retain eligible/offered IDs and before/after RNG states. Existing route, battle, reward and rune-stock generators are untouched. Reopening, cancellation, Retry and restart do not regenerate offerings.

## Save versions and chronological health

The local envelope remains `rc028_local_v1`; integer encoding, checked writes, backup/recovery and LocalSave I/O remain unchanged. Run **v4** retains 32 explicit top-level fields, adding ranked instances, entry relic ownership and versioned nested item receipts/offerings. Profile v1 remains unchanged.

Real run **v1, v2 and v3** structures and registered predecessor policies remain accepted. Legacy cards become explicitly rank zero, including entry checkpoints and historical purchase/removal/reward card receipts. Legacy relic ownership stays empty. Only v1/v2 establish their existing legacy health boundary; **v3 service records, health boundary and battle-health records load intact**, rather than being replaced with a new anchor. Content signatures still bind unchanged immutable base Combat configuration.

New room records use `rc031_shop_v2` / `rc031_services_v2`. Existing records retain `rc029_shop_v1` / `rc030_services_v1`, their original stock and gated options. Migrating an active Desk or Reliquary does not retrofit fresh items. Leaving that room and entering a later room uses the new policy. Both record generations can coexist in one v4 run.

Ownership/Gold history replays in visit and transaction order, reconstructing purchases, exact rank changes, removals and unique relic ownership. Health validation advances through raw battle outcomes, service receipts and actual shop acquisition positions. Heart Stone changes maximum/current HP at acquisition; Mender affects only recoveries after its acquisition. A later relic cannot justify an earlier effect. Pending battle results retain raw outcome health independently of later acquisition effects. Battle entry and service entry/confirmation must match the preceding boundary.

Malformed ranks, duplicate relics, unavailable upgraded definitions, altered offerings, unexplained health, inconsistent receipts and invalid container types reject before publication. The hostile-save review found and fixed type-guard gaps where GDScript comparison exceptions could otherwise bypass a typed validator. Predecessor backup validation remains available, and migration never overwrites original bytes before durable success.

[Original v3 fixtures and provenance](../tests/fixtures/rc030/README.md) include all five active services, completed recovery/Tithe/shop history, a post-recovery interrupted battle and pending rewards. These are copied original RC-030 envelope bytes, not current saves with fields removed. The retained [v1](../tests/fixtures/rc028/README.md) and [v2](../tests/fixtures/rc029/README.md) specimens are also unchanged.

## Verification evidence

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility renderer, isolated save/settings and APPDATA/LOCALAPPDATA. New fixture routes use actual supported Wisp battles and explicitly labelled fixture rewards; no production victory, missing enemy or completed tower is fabricated.

| Coverage | Result |
| --- | --- |
| Effects, loader, Combat and Circuit, including mixed execution | **643 checks / 0 failures** — [report](../output/qa/rc-031/effects/results.json). Exact-copy values, installation/Remove/cleanup/recycle, upgraded Focus/Conjure UIDs/expiry, single rank/ineligibility, Split/Join then relics, invalid/unaffordable/zero/Pass/lethal, opening versus later turns and compatible successor. |
| Authoritative ownership/health/room models | **163 / 0** — [report](../output/qa/rc-031/state/results.json). Both Heart/Mender orders, free/paid upgrades, upgrade-removal, all five disk failure points, capped historical healing, duplicate/small/exhausted pools and full-health/no-target Leave. |
| Independent hostile-save review | **171 / 0** — [report](../output/qa/rc-031/review/results.json). Malformed new fields reject cleanly; chronological receipts and health reviewed independently. |
| New room shell and rendering | **205 headless / 243 rendered, 0 failures** — [headless](../output/qa/rc-031/ui/results-headless.json), [rendered](../output/qa/rc-031/ui/results-capture.json). Exact targets/previews, cancellation, stale/double/reentrant callbacks, insufficient Gold, five failure modes, Retry, post-save feedback and silent reopen. |
| Live upgraded Combat presentation | **22 headless / 30 rendered, 0 failures** — [headless](../output/qa/rc-031/ui/live-results-headless.json), [rendered](../output/qa/rc-031/ui/live-results-capture.json). Actual next-hand upgraded Spark, supported hand/collection/pile inspection, live Resume and exact replay with Heart Stone health retained once. |
| New item fresh-process campaign | **964 / 0 across 135 launches** — [report](../output/qa/rc-031/process/465155120b/results.json). Two acquisition orders, shop upgrades/relics/removal, recovery, Tithe, next battle, Desk and Reliquary, plus write/flush/close/backup/replace failures for paid upgrade and Heart acquisition followed by restart/identical Retry. |
| Real predecessor migration/recovery campaign | **1,449 / 0 across 176 launches** — [report](../output/qa/rc-031/migrations/b1b7d18e57/results.json). Sixteen real v1/v2/v3 specimens, five failure points each, original-byte backups, damaged-current preservation, restart, exact replay and retained old-policy continuation. |
| Existing regression suites | **7,654 assertions, all passing in final evidence** — [final report](../output/qa/rc-031/regression/results-final.json). Core 2,355; UI 1,175; shell 118; shop model/shell 277/83; service model/shell 365/338; save model 1,704; local save 53; persistence audio/shell 10/77; reward state/integration/audio 75/174/159; collection data/lifecycle 127/32; encounter 78; audio settings/playback 26/428. |
| Existing persistence restart campaigns | **643 / 0 across 109 launches** [run/reward/profile](../output/qa/rc-031/legacy-process/17bb52af25/results.json); **471 / 0 across 80 launches** [shops](../output/qa/rc-031/shop-process/752ef15eb7/results.json); **605 / 0 across 55 launches** [five ordinary service paths](../output/qa/rc-031/service-process/2a20c73eb6/results.json). |
| Shared Menu and Combat reference | **143 / 0** shared Menu checks at normal, large and narrow configured sizes. Combat reference: **257 checks, the same 15 documented baseline geometry failures**; assertions unchanged. [Recorded baseline report](../output/qa/rc-031/regression/reference-baseline.json). |

The process harness's `expected.bin` is excluded comparison evidence for retaining an uncommitted candidate across test processes. The shipped application retains Retry in memory and restarts from its last durable checkpoint; it does not persist arbitrary pending intent. Existing tests that expected two-field cards now explicitly expect rank zero or compare only the permitted new zero defaults. Former gated-Desk tests now exercise selection cancellation; insufficient-Gold and exact-target rejection remain asserted. No geometry assertions were relaxed.

Initial failed reports are retained. A final reward-audio run passed assertions but reported one shutdown resource warning; its clean focused rerun supplies final evidence. The live capture harness's initial shutdown warnings were fixed with test-only teardown time. An initial UI capture used the reserved generic `--capture` flag; the final runner uses `--capture-rc031`. These were verification-harness issues, not substituted production outcomes.

## Actual normal and narrow captures

The **46 screenshots** use actual configured root windows at **450×1000** and **360×640** (288×640 letterboxed content at the narrow size). Representative cards, exact-copy selection, previews, relic details, room choices and live Combat captures were visually inspected. Shared Menu typography, the 660 px popup cap, fixed reachable actions, navy/gold panels, clean Home, parchment Map and neutral navigation remain. No board-slot inspection or forecast interaction was added.

| Surface | Normal | Narrow |
| --- | --- | --- |
| Exact-copy upgrade selection | [image](../output/qa/rc-031/ui/exact-copy-selection-shop-450x1000.png) | [image](../output/qa/rc-031/ui/exact-copy-selection-shop-360x640.png) |
| Before/after preview | [image](../output/qa/rc-031/ui/upgrade-preview-shop-450x1000.png) | [image](../output/qa/rc-031/ui/upgrade-preview-shop-360x640.png) |
| Upgraded card detail | [image](../output/qa/rc-031/ui/upgraded-card-detail-shop-450x1000.png) | [image](../output/qa/rc-031/ui/upgraded-card-detail-shop-360x640.png) |
| Exact upgraded removal | [image](../output/qa/rc-031/ui/upgraded-removal-shop-450x1000.png) | [image](../output/qa/rc-031/ui/upgraded-removal-shop-360x640.png) |
| Acquired relic inspection | [image](../output/qa/rc-031/ui/owned-relic-inspection-shop-450x1000.png) | [image](../output/qa/rc-031/ui/owned-relic-inspection-shop-360x640.png) |
| Recovery choices | [image](../output/qa/rc-031/ui/choices-recovery-450x1000.png) | [image](../output/qa/rc-031/ui/choices-recovery-360x640.png) |
| Desk preview | [image](../output/qa/rc-031/ui/target-preview-desk-450x1000.png) | [image](../output/qa/rc-031/ui/target-preview-desk-360x640.png) |
| Reliquary choices | [image](../output/qa/rc-031/ui/target-selection-reliquary-450x1000.png) | [image](../output/qa/rc-031/ui/target-selection-reliquary-360x640.png) |
| Actual upgraded battle hand | [image](../output/qa/rc-031/ui/live-upgraded-hand-450x1000.png) | [image](../output/qa/rc-031/ui/live-upgraded-hand-360x640.png) |
| Supported hand inspection | [image](../output/qa/rc-031/ui/live-upgraded-hand-inspection-450x1000.png) | [image](../output/qa/rc-031/ui/live-upgraded-hand-inspection-360x640.png) |
| Upgraded pile inspection | [image](../output/qa/rc-031/ui/live-upgraded-pile-inspection-450x1000.png) | [image](../output/qa/rc-031/ui/live-upgraded-pile-inspection-360x640.png) |

## How to try upgrades and relics

Production uses the integrated handlers, but missing preceding enemies still prevent a natural complete tower. The separately named manual fixture starts at Home and requires a real Wisp victory; it never auto-wins or grants an item on launch.

```powershell
$rc031Root = 'C:\Dev\RuneCast\output\qa\rc-031\manual'
New-Item -ItemType Directory -Force -Path "$rc031Root\appdata", "$rc031Root\localappdata" | Out-Null
$env:APPDATA = "$rc031Root\appdata"
$env:LOCALAPPDATA = "$rc031Root\localappdata"
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path C:\Dev\RuneCast --script res://tests/rc031_manual.gd -- --variant=shop
```

Use `shop`, `recovery`, `desk` or `reliquary`; each has a separate stable save/settings folder. Choose New Run, defeat the supported Wisp, resolve its card choice/Skip and claim the explicitly configured **160 fixture Gold**, then enter the next room.

1. Shop: choose Upgrade, inspect the exact UID and before/after values, cancel to verify no change, then confirm for 35 Gold. Inspect Collection to compare Spark and Spark +. Buy the retained relic for 60 Gold; inspect its effect. Removal targets the actual ranked copy. Leave completes the visit.
2. Recovery or Desk: select an eligible copy and confirm free refinement. Recovery's alternative healing and refinement cannot both be taken. Leave remains available when health or upgrade eligibility is exhausted.
3. Reliquary: inspect retained distinct choices, cancel, reopen and choose one for 15 Gold. The payment and room completion happen together.
4. Open Map/Menu/Collection, return, Quit to Home, Continue and restart the same command. Stock, selected policy and committed receipts persist. Enter the next real encounter to inspect effective values. Live Resume preserves preparation; interrupted entry replay restores the saved opening.
5. New Run clears run modifiers and restores 30/30 while retaining definition unlocks. Failure injection is covered by the excluded runners; normal manual play performs ordinary durable saves.

Reproduce automated evidence with isolated APPDATA/LOCALAPPDATA as above. Run `tests/instance_effect_runner.gd`, `tests/upgrade_relic_state_runner.gd`, `tests/rc031_ui_runner.gd` and `tests/rc031_live_ui_runner.gd` through pinned Godot; add `-- --capture-rc031` for rendered captures. Python orchestrators are `tools/verify_rc031_migrations.py`, `tools/verify_rc031_process.py` and `tools/verify_rc031_regressions.py`. They use the pinned engine and separate output directories automatically.

## Resource package and remaining work

Explicit runtime inventory now requires `instance_effects.gd` and `relic_policy.gd`; fixtures and all QA files remain excluded. Fresh `builds/rc-031-resources/RuneCast.pck` passes **400 integrity/policy checks, 115 isolated payload-decode checks and 32 Python tests**. It contains **12,420,960 bytes / 387 entries**, SHA-256 **`8c9c018ba9c95e9c62da7f9026c00d025b1776f00164714d5e10b78f70dbb08e`**. [Audit](../output/qa/rc-031/resources/resource-audit.json), [200-source manifest](../output/qa/rc-031/resources/source-manifest.json), [Python log](../output/qa/rc-031/resources/python-tests.log). No runtime source is newer than the pack. [Protected-source comparison](../output/qa/rc-031/preserved-hashes.json) confirms unchanged production rules/encounter/boards/loadout, project canvas, shared components/modal/navigation and LocalSave I/O.

The resource export used pinned Godot `--headless --editor --export-pack iOS`, followed by `tools/verify_ios_resources.py`; no native build/signing was performed. The existing Android build-tools/Target-SDK warning appeared during editor initialization; no SDK was installed or changed.

RC-029 and RC-030 are complete for their supported room mechanics, including the previously gated integrations. RC-031 is complete for these eight upgrade contracts and six run-only hooks. **RC-035** still owns the remaining base definitions and final catalogue writing/validation; **RC-036** owns final balance, prices, weights and writing; **RC-041/042** own dedicated icons/art and final presentation integration. Missing production enemies and the separate guardian still block a complete tower. **RC-024A** still owns Store currency/payment, purchase ownership/lifetimes, accounts, distinct perks and extra item families. No such system was inferred.

RC-022 remains deferred; both music tracks and RC-023 human/device acceptance remain pending. Desktop tests and resource decoding do not establish physical-device acceptance.

One initial read-only `git status` and current-branch query ran before the pasted prohibition was reviewed; this was disclosed immediately. They changed no files or Git state. No subsequent Git operation was performed.
