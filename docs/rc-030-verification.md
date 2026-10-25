# RC-030 — Recovery and event rooms

**October 24 RC-031 completion:** Recovery refinement, Etched Desk and Sealed Reliquary now pass real integrated transaction, persistence and rendered checks. RC-030 is complete for supported room mechanics. Recovery healing/refinement are exclusive, Mender applies only after acquisition, Desk refines one exact copy, and Reliquary pays 15 Gold for one retained unowned relic. Retained v1 services keep their original policy without new offerings. Final writing/balance/art retain their existing owners. [Current behavior and evidence](rc-031-verification.md). The groundwork record below remains historical.

October 24, 2026 (Australia/Sydney). **Supported recovery/event groundwork; full RC-030 remains open for RC-031.** The current runtime has no supported relic acquisition/effect/save or owned-instance upgrade contract. This delivery uses the existing roster's provisional values. RC-036 retains final writing, weights and balance; RC-041/042 retain final room artwork.

## Supported choices

| Room | Choice | Eligibility and outcome |
| --- | --- | --- |
| Recovery | Recover | Free, restores up to 10 HP to the current maximum. The confirmation shows the actual capped gain. Disabled at full HP. |
| Recovery | Refine Rune | Unavailable until supported instance upgrades exist. |
| Lost Satchel | Take Gold | Gain 20 Gold. |
| Blood Tithe | Pay the Tithe | Lose 8 HP and gain 40 Gold together; requires more than 8 HP. |
| Sealed Reliquary | Open reliquary | Unavailable until supported relic acquisition exists; the proposed 15 Gold is never charged. |
| Etched Desk | Refine Rune | Unavailable until supported instance upgrades exist. |
| Every room | Leave | Free, records a no-benefit resolution. |

One confirmed benefit or Leave completes the visit and returns to Map. Recovery healing and upgrading are mutually exclusive. Canceling a confirmation, Back, closing an overlay, inspecting Map and quitting to Home do not resolve the room. Continue and restart reopen the same unresolved visit. Completed visits cannot provide another benefit.

Event entry uses the ID already retained in the route node's `room_reference`. All four identities remain distinct, including gated events. Unknown or malformed definitions fail preparation without consuming a visit. Base recovery, Satchel and Tithe use no RNG. No Mender's Token bonus, new relic mechanics, extra rune definitions, Store purchase, hidden battle or extra room is introduced.

## Persistence and validation

The local envelope remains `rc028_local_v1`, including exact signed-integer encoding, hashes/revisions, writer locks, checked staging writes, validated previous-copy recovery and preserved unreadable originals. Service policy stays outside Combat configuration signatures.

`scripts/core/service_policy.gd` registers **`rc030_services_v1`**. Its bounded declarative definitions permit only free Leave, capped healing, positive Gold, nonlethal HP-for-Gold and explicitly unavailable upgrade/relic choices. Stable choice IDs, exact integer bounds, unique choices, known definition identity and a free Leave are validated. Changing these provisional source constants requires an explicit policy-version/compatibility decision rather than silently changing saved receipts.

Run model v3 extends explicit clone/publication/export/restore with service records and health boundaries. Real v1 and v2 files remain supported predecessors. Their original validators run before migration; promotion uses the same durable transaction and Retry boundary. Existing shop stock, purchases/removals, ownership/allocator gaps, RNG streams, pending results/rewards, profile unlocks and battle replay are preserved.

Service entry prepares the screen and candidate before saving the visit. Resolution revalidates the current authoritative identity and eligibility, then stages HP/Gold, receipt, service resolution and route completion together. Publication, navigation and success feedback follow durable success. Failed saves preserve the prior owners and retain the identical candidate for Retry; restart restores the last committed checkpoint.

Gold is reconciled in visit order, including event income at its actual visit. Later income cannot fund an earlier purchase. New service entry/result HP and battle-boundary records validate nonlethal Tithe, capped healing, unchanged maximum HP and continuity into later battle entries. Migration establishes a boundary at validated legacy current HP rather than inventing missing historical HP.

| New saved record | Retained authority |
| --- | --- |
| Service | Run/route/node/visit identity; record and policy versions; room/definition identity; entry HP/max HP/Gold; active/resolved state; one receipt. |
| Resolution receipt | Stable transaction and choice IDs; HP/Gold deltas; result HP/max HP/Gold. Leave has zero deltas. |
| Health boundary | Source version, count of earlier visits, validated current HP and max HP. Native runs start at visit zero and 30/30. Migrated v1/v2 states explicitly anchor their surviving current state. |
| Battle health | Matching visit identity, entry/max HP, result HP and outcome. An active battle must match its exact replay checkpoint. Completed battles cannot heal under current mechanics. |

The v3 model has 32 fields, while original v1/v2 structure validation retains 25/28. Shop fields load for every version at least 2; shell promotion detects any supported predecessor below the current version. Health validation rejects missing/duplicate/discontinuous boundaries and cannot slide a legacy boundary past new service records. Service records validate independently of fixture capability. Production still rejects unsupported enemies, relics and upgrades. Saved graphs are not regenerated: runtime inspection updates service availability while retaining graph data and assigned event IDs.

## How to try the rooms

Normal launch remains `./tools/godot.ps1 -Action run`. Production room handlers are available, but missing preceding enemies still prevent a natural complete tower. Use the separately named excluded fixture to play genuine battles and services:

```powershell
$rc030Root = 'C:\Dev\RuneCast\output\qa\rc-030\manual'
New-Item -ItemType Directory -Force -Path "$rc030Root\appdata", "$rc030Root\localappdata" | Out-Null
$env:APPDATA = "$rc030Root\appdata"
$env:LOCALAPPDATA = "$rc030Root\localappdata"
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path C:\Dev\RuneCast --script res://tests/service_manual.gd -- --variant=recovery
```

Choose `recovery`, `satchel`, `tithe`, `reliquary` or `desk`. Each variant has a separate save/settings directory under `output/qa/rc-030/manual/<variant>`; repeating the command restores that slot. The window is titled **Recovery and event integration fixture**.

1. New Run → enter the Calibration Wisp → win → acknowledge its result. The fixture starts with the unchanged eight cards, 30/30 HP and zero Gold; it grants no fixture reward Gold.
2. Enter the connected recovery/event room. Review the visible outcome and confirm, or cancel to keep the visit open. Unavailable benefits still allow Leave.
3. Open Map, Menu, Options and Collection and return to the same room. Quit to Home → Continue, or close and restart the command: the same unresolved visit reopens. Back never silently chooses Leave.
4. Confirm one benefit or Leave. The room completes and returns to Map. It cannot reopen for another benefit.
5. Enter and win the next real Wisp. Its entry carries the service HP and unchanged owned instances. The following Blood Tithe and Shop exercise later eligibility and spending of actual event Gold.

The automated recovery path carries **30 → 21 HP after battle → 30 after the capped +9 recovery → 23 after the next battle → 15 after Tithe**, then spends 30 of its 40 event Gold in the shop. The Tithe-first path carries **21 → 13 → 6 HP**; the second Tithe correctly refuses payment and Leave remains usable. These are supported fixture encounters, not fabricated production victories or a completed tower. The prior reward-free, reward and shop fixtures remain separate.

## Verification

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility renderer. Saves/settings and process application-data directories were isolated from normal user data. Existing fixed-output runners use excluded copies with only output path literals redirected.

| Coverage | Actual result and evidence |
| --- | --- |
| Service model and hostile saves | **361 checks, zero failures** — [report](../output/qa/rc-030/model/results.json). Full-health rejection, capped gain, exact Tithe thresholds, all event identities, no RNG changes, clone/publication, cancellation, stale/reentrant/double input, generic completion guards, malformed records, HP continuity and later/future-income reconciliation. |
| Service shell and configured-root capture | **338 headless / 380 rendered checks, zero failures** — [headless](../output/qa/rc-030/shell/results-headless.json), [rendered](../output/qa/rc-030/shell/results-capture.json). Preparation/attachment failures, entry/benefit/Leave Retry, stale/reentrant callbacks, cancellation, caller-aware overlays, Home/Continue/restart, silent restore and genuine 6-HP ineligibility. |
| New process/restart campaigns | **3,577 checks, zero failures across 358 launches** — [aggregate](../output/qa/rc-030/process/results-final.json). Five genuine service paths: 595/55 launches; twenty entry/benefit failure cases: 2,520/240; seven real predecessor migrations including subsequent gameplay: 462/63. |
| Existing model, shell, shop, UI, rewards and audio | **17 suites, zero final failures** — [combined final report](../output/qa/rc-030/regression/results-final.json). Core 2,355; shop model 257; shop shell 83; save models 1,663; local store 53; durable audio 10; persistence shell 77; shell 118; rewards 75; reward integration 174; reward audio 159; Collection data 127/lifecycle 32; audio settings 26/playback 428; encounter integration 78; UI 1,175. |
| Existing persistence process campaign | **643 checks, zero failures across 109 launches** — [report](../output/qa/rc-030/legacy-process/a13eb7ec5d/results.json). Pending results/rewards, both claim orders, profile/terminal states, exact replay and failure recovery. |
| Existing shop process campaign | **471 checks, zero failures across 80 launches** — [report](../output/qa/rc-030/shop-process/e09a0122cf/results.json). Stock, purchases/removal/Leave, next battle and all five persistence failures. |
| Shared Menu | **143 configured-root checks, zero assertion failures** — [report](../output/qa/rc-030/shared-menu/results.json). Literal Resume Combat, unchanged Map/Combat body/geometry and caller return at normal, large and narrow sizes. The run logged four ObjectDB/two resource shutdown warnings. |
| Absolute Combat reference | **257 checks, the same 15 documented baseline geometry failures** — [report](../output/qa/rc-030/reference/results.json), [log](../output/qa/rc-030/reference.log). Reference assertions and Combat layout were not weakened or changed. |

The exact 8/9 HP authoritative Tithe tests are explicitly isolated model-boundary specimens; persistence rejects their manufactured starter-health histories. The normal integration and process paths carry real battle damage. Full-health rejection also uses a separately authored first-room recovery fixture with the untouched 30/30 starter. No fixture capability makes malformed production service records acceptable.

Fault injection covers checked write, flush, close, backup and replacement failures. The process harness's test-only `expected.bin` retains an uncommitted candidate to compare/reapply an identical action across launches. This is not a shipped pending-intent save: the application retains Retry in memory and restarts from its last durable checkpoint. Shell tests separately exercise actual in-memory Retry, silent restoration, failed scene preparation, and once-only post-save feedback.

Real predecessor bytes and SHA-256 provenance are retained in [RC-028 fixtures](../tests/fixtures/rc028/README.md) and [RC-029 fixtures](../tests/fixtures/rc029/README.md). They include active shops with two purchases/removal, completed shops, next-battle replay and a pending boss result/definition unlock. Migration tests verify unchanged old fields, failure byte preservation, exact old backup creation, damage/recovery, v3 restart and subsequent genuine gameplay. No predecessor was fabricated by removing v3 fields.

Initial regressions found a missing type guard in the new policy field and obsolete structural tests that bypassed service ownership. The guard was fixed; the route tests now use actual service Leave and shop Leave while retaining traversal/lock assertions. A shop availability assertion now reflects recovery support. The [initial report](../output/qa/rc-030/regression/results-all.json) retains those failures; the [focused rerun](../output/qa/rc-030/regression/results-selected.json) passes. An initial reward-audio run passed assertions but logged a resource shutdown warning; its final rerun passed cleanly. One initial direct shop-model run accidentally replaced the historical `output/qa/rc-029/model/results.json`; subsequent test reports use RC-030 paths. No normal user save was used or altered.

Reproduce with the isolated APPDATA/LOCALAPPDATA setup above:

```powershell
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script res://tests/service_model_runner.gd
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script res://tests/service_shell_runner.gd
& '.\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --audio-driver Dummy --script res://tests/service_shell_runner.gd -- --capture-service
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/verify_service_persistence.py
```

## Rendered evidence

All **42 final screenshots** were visually inspected at actual **450×1000** and **360×640** root-window sizes; the narrow content texture is 288×640 because the existing project letterboxes. [Visual review](../output/qa/rc-030/shell/visual-review.json). Header wrapping/overlap and an unsupported arrow glyph found in the first capture pass were corrected and every capture regenerated. A separate read-only core review found no remaining actionable defect.

The screens reuse the painted navy/gold backdrop, controls and fonts, with a fixed reachable Leave and unchanged 82 px navigation. Choice content scrolls only if needed. Confirmations use the shared borderless, content-fit modal policy capped at 660 px, with fixed actions. The existing shared Menu keeps **Resume Combat**; its service-specific body truthfully describes the retained room. Home has no restored status/footer blocks.

| State | Normal | Narrow |
| --- | --- | --- |
| Recovery with actual capped +9 preview | [450×1000](../output/qa/rc-030/shell/choices-recovery-450x1000.png) | [360×640](../output/qa/rc-030/shell/choices-recovery-360x640.png) |
| Capped-heal confirmation | [450×1000](../output/qa/rc-030/shell/confirm-recovery-450x1000.png) | [360×640](../output/qa/rc-030/shell/confirm-recovery-360x640.png) |
| Lost Satchel | [450×1000](../output/qa/rc-030/shell/choices-satchel-450x1000.png) | [360×640](../output/qa/rc-030/shell/choices-satchel-360x640.png) |
| Blood Tithe | [450×1000](../output/qa/rc-030/shell/choices-tithe-450x1000.png) | [360×640](../output/qa/rc-030/shell/choices-tithe-360x640.png) |
| Gated Sealed Reliquary | [450×1000](../output/qa/rc-030/shell/choices-reliquary-450x1000.png) | [360×640](../output/qa/rc-030/shell/choices-reliquary-360x640.png) |
| Gated Etched Desk | [450×1000](../output/qa/rc-030/shell/choices-desk-450x1000.png) | [360×640](../output/qa/rc-030/shell/choices-desk-360x640.png) |
| Genuine 6-HP Tithe rejection after battle | [450×1000](../output/qa/rc-030/shell/insufficient-after-battle-tithe-450x1000.png) | [360×640](../output/qa/rc-030/shell/insufficient-after-battle-tithe-360x640.png) |
| Full-health presentation specimen | [450×1000](../output/qa/rc-030/shell/presenter-full-health-recovery-450x1000.png) | [360×640](../output/qa/rc-030/shell/presenter-full-health-recovery-360x640.png) |
| 8-HP eligibility presentation specimen | [450×1000](../output/qa/rc-030/shell/presenter-insufficient-tithe-tithe-450x1000.png) | [360×640](../output/qa/rc-030/shell/presenter-insufficient-tithe-tithe-360x640.png) |
| Failed entry / Retry | [450×1000](../output/qa/rc-030/shell/entry-save-failure-recovery-450x1000.png) | [360×640](../output/qa/rc-030/shell/entry-save-failure-recovery-360x640.png) |
| Failed Tithe resolution / Retry | [450×1000](../output/qa/rc-030/shell/resolution-save-failure-tithe-450x1000.png) | [360×640](../output/qa/rc-030/shell/resolution-save-failure-tithe-360x640.png) |
| Shared Menu over active recovery | [450×1000](../output/qa/rc-030/shell/menu-recovery-450x1000.png) | [360×640](../output/qa/rc-030/shell/menu-recovery-360x640.png) |

## Resource-only package

The explicit resource inventory and missing-resource regression now include `service_policy.gd` and `service_viewer.gd`. Fresh `builds/rc-030-resources/RuneCast.pck` passes **396 integrity/policy checks, 111 isolated payload-decode checks and 32 Python tests**. It contains **12,391,888 bytes / 383 entries**, SHA-256 **`fc7bc2e92b78a8a83215438711c42fa1503cc88f6e08fb2bb3501ae1b64f429d`**. [Audit](../output/qa/rc-030/resources/resource-audit.json), [source manifest](../output/qa/rc-030/resources/source-manifest.json), [Python tests](../output/qa/rc-030/resources/python-tests.log).

The manifest records **198 runtime/configuration sources**, with none newer than the audited package. [Ten protected-source hashes](../output/qa/rc-030/preserved-hashes-final.json) confirm unchanged production encounter/rules/boards/loadout, project canvas configuration, shared component/modal/navigation geometry, Combat model and local-save I/O. Test fixtures, predecessor save bytes and QA evidence are excluded from the package.

The resource export used pinned Godot `--headless --path . --editor --export-pack iOS builds/rc-030-resources/RuneCast.pck`, followed by `tools/verify_ios_resources.py --pack builds/rc-030-resources/RuneCast.pck --engine .tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --report output/qa/rc-030/resources/resource-audit.json`. Python checks used `unittest discover -s tests -p test_ios*.py` with `RUNECAST_RESOURCE_TEST_PACK` set to that exact pack. The existing Android build-tools/Target-SDK warning appeared during editor initialization; no SDK was installed or changed.

## Remaining scope

Full RC-030 remains unchecked with dependencies **RC-027, RC-028 and RC-031** unchanged. RC-029's relic/upgrade services also remain open. Missing production enemies and the separate guardian still prevent a complete production tower. The nine-visit route, assigned event IDs, designated Shadeling boss, existing reward-free/reward/shop fixtures and approved Home/Map/Combat/Menu visuals are preserved.

RC-022 remains deferred, both music tracks remain pending, and RC-023 human/device acceptance remains open. No native build, SDK installation or signing is required or claimed.

One initial read-only `git status` ran alongside reading the pasted request, before its no-Git instruction was seen; this was disclosed immediately. No subsequent Git operations were performed.
