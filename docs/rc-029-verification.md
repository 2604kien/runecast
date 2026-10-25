# RC-029 — Shop rooms and run currency

**October 24 RC-031 completion:** the previously gated relic purchase and exact-instance upgrade now pass integrated model, durable shell, fresh-process and rendered checks. RC-029 is complete for supported shop mechanics. New visits offer one unowned relic for 60 Gold and one upgrade for 35 Gold; retained v1 shops keep their original policy/stock. Final economics/art and the separate Store retain their existing owners. [Current behavior and evidence](rc-031-verification.md). The groundwork record below remains historical.

October 24, 2026 (Australia/Sydney). **Supported shop groundwork delivered; full RC-029 remains open for RC-031.** Inspection of the current runtime and plan found no implemented relic acquisition/effect/save or owned-instance upgrade contract. Rune stock, purchases, removal, active-room navigation and durable Leave are implemented. Relics and upgrades remain unavailable and never charge Gold. The separate menu Store remains with RC-024A/RC-029A.

No Git operations were performed. Production starting Gold, reward rules, Combat configuration, route generation, designated depth-six Shadeling and separate guardian remain unchanged. Missing enemies, events, recovery and guardian content still prevent a complete production tower. The excluded integration fixture establishes the supported sequence without fabricating completed visits.

## How to try the supported flow

Normal launch remains `./tools/godot.ps1 -Action run`. An eligible route shop now opens as a main screen; missing preceding production content still prevents naturally reaching it in a full production run today.

Use the separate fixture for a playable battle → shop → battle sequence:

```powershell
$rc029Root = 'C:\Dev\RuneCast\output\qa\rc-029\manual'
New-Item -ItemType Directory -Force -Path "$rc029Root\appdata", "$rc029Root\localappdata" | Out-Null
$env:APPDATA = "$rc029Root\appdata"
$env:LOCALAPPDATA = "$rc029Root\localappdata"
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path C:\Dev\RuneCast --script res://tests/shop_manual.gd
```

The titled **Shop integration fixture** uses genuine Calibration Wisp encounters. Its first victory explicitly awards **100 fixture Gold**, claimed through ordinary rewards. It begins with zero Gold and the unchanged eight-card starter. The fixture save and settings stay under `output/qa/rc-029/manual`; repeating the command restores that slot.

1. New Run → enter the first Wisp → win → resolve rune/Gold rewards → return to Map.
2. Enter the connected Shop. Inspect a painted card, buy it, and observe its Sold state and updated balance. Existing copies do not exclude a definition from stock.
3. Select **Remove one rune**, choose an exact copy and review its card, price and resulting collection count. Cancel changes nothing; confirm removes that UID once.
4. Open Map, the shared Menu, Collection or Options, then return. Home → Continue and a full application restart retain this shop, its original stock and used removal service. Closing an overlay or using Back never completes the room.
5. **Leave shop** completes the visit once, even without a purchase. Enter the next supported Wisp: purchased copies appear exactly once in its collection and removed copies remain absent. The completed shop cannot be reopened for further transactions.

The fixture's optional removal-chain variant is test-only and checks the four-card floor across distinct entered shops. Neither fixture changes production topology, content, payouts or balance.

## Policy and ownership contracts

`scripts/core/shop_policy.gd` registers **`rc029_shop_v1`**, with eligibility version **1**. These are configurable source defaults and **provisional RC-036 tuning**, rather than final economy acceptance:

| Offering/service | Initial default | Current support |
| --- | --- | --- |
| Rune | Up to three distinct definitions, 30 Gold each | One purchase per stable slot |
| Relic | One unowned relic, 60 Gold | Unavailable pending RC-031 |
| Remove rune | 40 Gold, once per visit | Exact UID; retain at least four cards |
| Upgrade rune | 35 Gold, once per visit | Unavailable pending RC-031 |

The implemented, profile-unlocked Spark, Shield, Focus and Conjure definitions are eligible. All four start unlocked. Free Spark and unauthored definitions are excluded; small pools produce fewer slots and an empty pool produces none. There is no refresh or restock action. Policy changes require a deliberate version/compatibility decision, so editing a price cannot silently invalidate an existing receipt's meaning.

Stock draws from a separate stream seeded with `seed XOR 0x52435348`. Route, reward, card, endpoint and connector-kit streams are untouched. Entry prepares stock with a detached RNG before committing the visit; retries retain that same prepared choice. Saved records contain run/route/node/visit identity, original eligible IDs, stable slot IDs and definitions, prices, sold/granted-UID state, removal allowance and removed copy, ordered receipts, entry allocator, before/after shop RNG and active/left status.

Purchases revalidate the active visit, slot, policy price, current eligibility, balance and 100-card collection limit. They add exactly one owned instance at authoritative `next_uid`, increment that allocator, spend Gold and mark the slot sold together. Temporary-consumed gaps remain spent. Removal selects one owned UID, preserves historical reward/purchase receipts and profile unlocks, and never decrements/recycles the allocator. These actions do not insert a card into an already settled battle or increment route revisions. Only entry and explicit Leave add their normal route-history revisions.

## Durability and v1 migration

The local envelope remains **`rc028_local_v1`**, with its exact tagged signed-integer encoding, SHA-256, revision/hash checks, writer lock, checked temporary write, validated previous copy and safe promotion/recovery. Profile and route remain version 1. **Run model version 2** adds the registered shop policy, retained shop records and independent RNG. Shop configuration remains outside Combat's configuration signature, preserving battle-entry compatibility.

`clone_for_transaction` and `publish_transaction` include shop records and RNG. The shell prepares a hidden, validated shop before staging entry. Entry, each purchase/removal, and Leave validate and save the entire candidate before publishing owners, navigation or success audio. Failed writes leave the old Gold, collection, stock, allowance and route intact. Retry retains the candidate's exact choice, price and allocated UID; it does not reroll, allocate again or replay restored acquisition receipts. Returning Home retains an in-memory failed intent; restarting retains only the last durable checkpoint.

Restore first applies strict v1 validation to real predecessor records, then constructs the v2 extension with no previous shops and the independently seeded shop RNG. The shell promotes this detached migration through the same commit/Retry path before publication. Backup and recovery validation continue accepting v1, including when v2 migration backs up its own predecessor. Failed promotion preserves the original bytes; explicit previous-copy recovery preserves damaged originals as before.

Version 2 reconciles resources in visit order: unchanged starter history, valid reward acquisitions/income, then each shop's purchases/removal/Leave. Current ownership must exactly equal that reconstruction; Gold must equal configured income minus recorded spending, without spending future income. Historical reward-granted cards may be absent only after a valid removal. Validation rejects unexplained cards/spending/removal, duplicate receipts, reused UIDs, altered prices, malformed or rerolled stock, incorrect eligibility/RNG chains, service-use disagreement and transactions after Leave. Unsupported service states, relics/upgrades and development policies remain rejected by production restore.

Actual active-shop persistence is exercised through the explicit supported integration fixture. Production graph availability and registered-handler validation are checked separately; this record does not claim a naturally reachable production shop or full tower playthrough.

## Verification

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility renderer; all new saves/settings and process application-data paths are isolated. Existing fixed-output test runners are copied into an excluded QA directory with only output path literals redirected, preserving historical evidence and assertions.

| Coverage | Result and evidence |
| --- | --- |
| Shop model, ownership, malformed records and real migration | **257 checks, 0 failures**; [report](../output/qa/rc-029/model/results.json). Distinct/retained stock, independent RNG, small/empty pools and temporary exclusion, insufficient/exact Gold, sold slots/capacity, removal of starter/reward/purchased copies, four-card floor, unchanged unlocks, stale/double/reentrant attempts, route locks/Leave and malformed history. |
| Shop fresh-process persistence | **471 checks, 0 failures across 80 launches**; [final report](../output/qa/rc-029/process/48cb774f4f/results.json). Before/after entry, purchase, removal and Leave, next battle, write/flush/close/backup/replace failures and restart/Retry without duplicate payment/grant. |
| Shop shell and configured-root captures | **83 headless / 159 rendered checks, 0 failures**; [headless report](../output/qa/rc-029/shell/results-headless.json), [rendered report](../output/qa/rc-029/shell/results-capture.json). Durable entry and service dispatch, cancellation/stale/reentrant callbacks, once-only post-save audio, Map/Home/Continue, scene-construction Retry, failed-purchase restart and real v1 startup migration/recovery. Both actual 450×1000 and narrow 360×640 root windows are exercised. |
| Existing persistence fresh-process regressions | **643 checks, 0 failures across 109 launches**; [report](../output/qa/rc-029/legacy-process/964ddbec63/results.json). Entry replay, pending results/rewards, both partial-claim orders, unlock/profile-only/terminal boundaries and all five write failures. |
| Existing model/store/shell/UI/audio/collection regressions | [Initial full report](../output/qa/rc-029/regression/results-all.json), [focused final rerun](../output/qa/rc-029/regression/results-selected.json). Core 2,354; save models 1,597; store 53; durable audio 10; persistence shell 77; shell 118; rewards 75; reward integration 174; reward audio 159; collection data 127; collection lifecycle 32; audio settings 26; audio playback 428; encounter integration 78; UI 1,175 checks. Final assertion counts are all zero failures. |
| Shared Menu configured-root regression | **143 checks, 0 failures**; [report](../output/qa/rc-029/shared-menu-regression/results.json). Existing literal Resume Combat, caller behavior and Map/Combat panel pixels/geometry retained at 450×1000, 720×1600 and 360×640. |
| Absolute Combat reference | **257 checks, 15 existing baseline geometry failures**; [report](../output/qa/rc-029/reference/results.json), [log](../output/qa/rc-029/reference.log). No reference assertions or unrelated Combat layout changed. The baseline run also logged four ObjectDB/two resource shutdown warnings. |

The old save-model test's unsupported-version example changed from `2` to `99` because v2 is now supported. One encounter test still required a scrollbar even when the latest approved popup policy fits all text; it now verifies that the complete body fits or can be reached by scrolling, retaining the fixed-action bounds assertions. An initial reward-audio run passed all assertions but logged a shutdown resource warning; its focused final rerun passed cleanly. Intermediate evidence is retained in the initial report.

The predecessor fixtures at `tests/fixtures/rc028/` are exact bytes copied from the completed RC-028 campaign, not downgraded v2 records. Model checks cover unchanged legacy identities/resources/RNG/results/receipts, failed migration byte preservation, successful promotion with an exact v1 backup and recovery of that predecessor after damage. The process harness also stores an uncommitted candidate in its test-only `expected.bin` to verify reapplying the identical transaction in another process. This is test evidence, not a shipped pending-intent save: the application retains Retry in memory and restarts from committed progress.

Reproducible new checks:

```powershell
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script res://tests/shop_model_runner.gd
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script res://tests/shop_shell_runner.gd
& 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --audio-driver Dummy --script res://tests/shop_shell_runner.gd -- --capture-shop
& 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/verify_shop_persistence.py
```

Use the isolated APPDATA/LOCALAPPDATA setup above for direct Godot checks. The process orchestrator isolates its own paths.

## Rendered shop evidence

The configured project keeps its 720×1600 canvas and existing letterboxing; the narrow 360×640 window's captured content texture is 288×640. Shop content uses local display sizing for readable cards/actions, with a single scrolling column when narrow and fixed Leave above the unchanged neutral 82 px navigation. Popup bodies remain navy, framed in gold and borderless; the existing content-fit policy caps their preferred height at 660 px with fixed actions. No Home status/footer blocks were restored.

All ten captured state families (**20 PNGs**) were visually inspected at both sizes. Initial review found an overwrapped header balance and a missing arrow glyph; both were corrected and the captures regenerated. Durable-audio tests also found the Home-parented mixer becoming hidden in Shop; the shell now owns nonbattle audio, preserving focus/mute/lifetime behavior while allowing once-only saved purchase feedback. The existing 428 audio and 118 shell checks pass after that correction. The shared Menu keeps its literal **Resume Combat** and geometry; only its body explains retained stock/visits when opened from Shop or Map over Shop. The original Map/Combat copy remains unchanged for those callers without a shop.

| State | Normal | Narrow portrait |
| --- | --- | --- |
| Shop and balance | [450×1000](../output/qa/rc-029/shell/shop-450x1000.png) | [360×640](../output/qa/rc-029/shell/shop-360x640.png) |
| Item inspection | [450×1000](../output/qa/rc-029/shell/item-inspection-450x1000.png) | [360×640](../output/qa/rc-029/shell/item-inspection-360x640.png) |
| Removal selection | [450×1000](../output/qa/rc-029/shell/removal-selection-450x1000.png) | [360×640](../output/qa/rc-029/shell/removal-selection-360x640.png) |
| Exact-copy confirmation | [450×1000](../output/qa/rc-029/shell/removal-confirmation-450x1000.png) | [360×640](../output/qa/rc-029/shell/removal-confirmation-360x640.png) |
| Sold stock | [450×1000](../output/qa/rc-029/shell/sold-450x1000.png) | [360×640](../output/qa/rc-029/shell/sold-360x640.png) |
| Insufficient Gold | [450×1000](../output/qa/rc-029/shell/insufficient-gold-450x1000.png) | [360×640](../output/qa/rc-029/shell/insufficient-gold-360x640.png) |
| Failed-save Retry | [450×1000](../output/qa/rc-029/shell/save-failure-450x1000.png) | [360×640](../output/qa/rc-029/shell/save-failure-360x640.png) |
| Shared Menu from Shop | [450×1000](../output/qa/rc-029/shell/shop-menu-450x1000.png) | [360×640](../output/qa/rc-029/shell/shop-menu-360x640.png) |
| Supported/gated services | [450×1000](../output/qa/rc-029/shell/services-450x1000.png) | [360×640](../output/qa/rc-029/shell/services-360x640.png) |
| Map-over-Shop Menu | [450×1000](../output/qa/rc-029/shell/shop-map-menu-450x1000.png) | [360×640](../output/qa/rc-029/shell/shop-map-menu-360x640.png) |

## Resource-only package

The fresh final `builds/rc-029-resources/RuneCast.pck` passes **392 policy/integrity checks, 111 isolated packaged-payload decode checks and 32 Python regression tests**. It contains **12,366,792 bytes / 379 entries**, SHA-256 **`3dc00cf866bf96aede810b8d445bf138869d740e9f9ab97e7146b8aa4ebaffaa`**. The inventory explicitly includes the new shop policy and viewer; all excluded fixtures, test v1 save files and QA evidence stay outside the payload. All **198** final runtime/configuration source hashes were recorded, with no source newer than the audited package. [Audit](../output/qa/rc-029/resources/resource-audit.json), [source manifest](../output/qa/rc-029/resources/source-manifest.json), [Python tests](../output/qa/rc-029/resources/python-tests.log).

The export used pinned Godot `--headless --path . --editor --export-pack iOS builds/rc-029-resources/RuneCast.pck`, followed by `tools/verify_ios_resources.py --pack builds/rc-029-resources/RuneCast.pck --engine .tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --report output/qa/rc-029/resources/resource-audit.json`. Python tests used `unittest discover -s tests -p test_ios*.py` with `RUNECAST_RESOURCE_TEST_PACK` set to this exact pack. This is a resource export, not an iOS native build. The existing Android build-tools/Target-SDK warning appears during editor initialization; no SDK was installed or altered.

[Preservation hashes](../output/qa/rc-029/preserved-hashes-final.json) confirm the production encounter/rules/boards/loadout, project stretch, shared components/modal/navigation and Combat model remain byte-identical to the start of this task. The local-save I/O implementation and its locking/recovery behavior were reused unchanged.

## Remaining scope

Full RC-029 remains unchecked, with dependencies **RC-027, RC-028 and RC-031** preserved. RC-031 owns relic/upgrade effect ordering, acquisition and save representation. RC-024A/RC-029A own Store decisions and implementation; RC-034/035 own missing enemies/catalogue; RC-030 owns events/recovery; RC-036 owns final economy; RC-041/042 own final shop art and integration. Existing painted cards, Gold icon, navy/gold panels and shared controls are reused.

RC-022 remains deferred. No native mobile build, SDK installation or signing is required or claimed. Music delivery and RC-023 human/physical-device acceptance remain pending; desktop fault injection and restart checks do not establish device power-loss guarantees.
