# RC-027 — Rune rewards and collection inspection

**October 23 persistence update:** [RC-028](rc-028-verification.md) completes the approved run/rune save handoff: offers, partial component claims, receipts, allocator gaps and permanent definition unlocks survive restart. Claims and route/profile changes commit together. Earlier session-only descriptions below record RC-027's original scope; Store persistence remains unresolved.

October 22, 2026 (Australia/Sydney). **Complete for the approved reward contract and currently supported content.** Authoritative run rewards, session definition-unlock ownership, pending-choice navigation, read-only collection inspection and committed-reward audio are implemented. Missing production enemies and service rooms still prevent a complete tower. This is not full-catalogue, Store, save, final-guardian-content, balance or device acceptance.

The owner resolved the reward-specific RC-024A questions during this task. **RC-024A remains open** for Store currency/payment, catalogue, purchase ownership/lifetime, accounts, perks and other item families. RC-022 remains deferred, RC-023 human/device acceptance remains pending, and both music tracks remain unavailable.

One initial `git status --short` was mistakenly dispatched in parallel with reading the pasted request, before its no-Git instruction was known. This was disclosed immediately. No subsequent Git operations, commits, branches, merges or worktrees were performed. Existing unrelated work and approved art were preserved.

## Gameplay screenshot restored as the shared Menu reference

**October 23, 2026 (Australia/Sydney):** the owner explicitly selected the **large gameplay Menu screenshot** for both screens and rejected the smaller Map reference from the October 22 shared-Menu revision below. The same `route_menu` instance still opens from Map, Combat and Combat's retained Map. It now uses the gameplay body, **“Resume keeps this battle unchanged. Quit to Home discards battle progress; Continue replays its entry.”**, and the literal **Resume Combat** label in both contexts. Caller-aware Resume, Options/Collection return, Quit confirmation and pending-reward behavior remain unchanged.

At an actual **450×1000 physical window**, the shared panel measures **402×660 at (24, 170)**. Its action minima are **68 px**, action gaps **14 px**, heading/body/action fonts **22/16/18 px**, and horizontal/vertical padding **36/40 px**. Only the Menu applies an inverse canvas transform to preserve this gameplay-reference size under the existing project stretch. Gameplay artwork, board/card layout, animation/audio ownership and the shared **82 px navigation geometry** are unchanged.

The **360×640 physical window** retains its **288×640** rendered content and **36 px** side letterboxes. The Menu fits to **249.6×528 physical pixels at (55.2, 56)**, with **54.4 px** action minima; wrapped labels may produce taller individual actions. At **720×1600**, the panel remains **560×660**. These are configured-window measurements rather than unscaled component captures. [Runner](../tests/shared_menu_capture.gd), [results and transforms](../output/qa/gameplay-menu/results.json), [capture log](../output/qa/gameplay-menu/capture.log), [Map Menu at 450×1000](../output/qa/gameplay-menu/map-menu-450x1000.png), [Combat Menu at the same size](../output/qa/gameplay-menu/combat-menu-450x1000.png) and [narrow Combat Menu](../output/qa/gameplay-menu/combat-menu-360x640.png).

The Menu uses local copies of the existing fonts with `oversampling = 1.0`, so its inverse canvas transform does not enlarge glyphs rasterized for the smaller game canvas. Shared font resources and imports remain unchanged. Final rendered configured-root validation passes **143 checks** and the post-font-fix application-shell rerun passes **118 checks**; the full UI run passes **1,174 checks**, all with zero failures. [UI log](../output/qa/gameplay-menu/ui-tests.log), [shell log](../output/qa/gameplay-menu/shell-tests.log).

Fresh resource-only validation passes **386 policy/integrity checks, 106 isolated payload-decode checks and 32 Python tests**. `builds/gameplay-menu-resources/RuneCast.pck` contains **12,297,760 bytes**, **373 entries**, SHA-256 **`fc89d4995d57389fc8bc7515efb7cb170ca86013b308403d7ebddb6b824d7006`**. All **200** final source-manifest hashes match. [Audit](../output/qa/gameplay-menu/resources/resource-audit.json), [source manifest](../output/qa/gameplay-menu/resources/source-manifest.json) and [Python log](../output/qa/gameplay-menu/resources/python-tests.log). Earlier package hashes below validate their respective historical revisions. No native mobile build, SDK installation, signing or physical-device acceptance was performed.

## One shared Menu and configured window scaling

**Historical October 22 revision:** its smaller Map-based sizing authority and generic Resume copy are superseded by the October 23 gameplay-screenshot selection above. The single Menu instance and caller-preserving navigation remain current; retain these measurements and package results as historical evidence only.

The owner's next correction requires the exact same Menu, not separate layouts with contextual text. Run-managed Combat now emits a Menu request to the application, which opens the **same `route_menu` Control instance** used by Map. Both have identical heading/body, **Resume**, Options, Collection, unavailable Store and Quit to Home. One canvas and sizing policy own all rendering. The previous native menu remains available only to explicit standalone development encounters, whose restart/replay controls have a separate purpose. Grey native title bars remain removed.

Menu caller identity includes its generation. Resume restores the same Map or Combat; opening Menu from a Map over Combat retains that Map. Options uses the current settings/audio owner, Collection stays read-only, and both return to the retained Menu. Quit during a live battle uses the existing explicit checkpoint confirmation; Cancel returns to the Menu and confirmed Home preserves exact battle-entry replay. Busy presentation still permits Menu/Resume while guarding Quit/Collection. System Back dismisses one layer, and stale callbacks cannot act on a replacement caller. Reward rules, pending choices and ownership are unchanged.

The screenshot discrepancy had two causes: the earlier layouts had different text, and the supplied comparison mixed normal root-window rendering with an unscaled test capture. The project renders a **720×1600** logical canvas into a **450×1000** physical window, so its **560×660** Menu appears at **350×412.5** physical pixels. The earlier direct 450×1000 SubViewport capture instead showed a **402×660** panel. A baseline from the previously audited package confirms both old menus shared the normal configured scale; the capture was not evidence of a live scaling defect between those two menus. The new implementation uses Map's existing scale for both entry points and verifies them through the same real root window. It does not alter global stretch or Combat geometry.

The configured-window suite passes **133 checks** at **450×1000, 720×1600 and 360×640 physical window sizes**. It checks the same Menu/panel object IDs, literal copy, logical and physical action rectangles, and **byte-identical opaque interior pixels** above Map, Combat and Combat's retained Map. Transparent outer corners correctly reveal their different backgrounds. The 360×640 window contains a 288×640 rendered canvas and 36 px side letterboxes; its PNG captures that actual content texture, without invented framing. [Root-window runner](../tests/shared_menu_capture.gd), [results and transforms](../output/qa/shared-menu/results.json), [capture log](../output/qa/shared-menu/capture.log), [Map at 450×1000](../output/qa/shared-menu/map-menu-450x1000.png) and [Combat at the same size](../output/qa/shared-menu/combat-menu-450x1000.png).

Regression results: **1,174 UI checks, 118 shell checks, 32 collection-lifecycle checks and 174 reward-integration checks pass**. The migrated unscaled component/panel suite also passes **387 checks**; those captures supplement the configured-window proof rather than standing in for it. Native input exercises Menu, Options, Collection, unavailable Store, Resume and Quit/Cancel. The shell suite additionally confirms Quit from a Map over Combat and exact battle-entry Continue. [UI log](../output/qa/shared-menu/ui-tests.log), [shell log](../output/qa/rc-027/shared-menu-shell/engine.log), [collection log](../output/qa/shared-menu/collection-shell.log), [reward log](../output/qa/shared-menu/reward-integration.log) and [component capture log](../output/qa/shared-menu/panels.log).

Fresh resource-only validation passes **386 policy/integrity checks, 106 isolated payload-decode checks and 32 Python tests**. `builds/shared-menu-resources/RuneCast.pck` contains **12,296,592 bytes**, **373 entries**, SHA-256 **`a398b92ef409e8785e14784fcc51457bad397e98a1ddd6926b2966baceb2d71b`**. All **200** final source-manifest hashes match. [Audit](../output/qa/shared-menu/resources/resource-audit.json), [source manifest](../output/qa/shared-menu/resources/source-manifest.json) and [Python log](../output/qa/shared-menu/resources/python-tests.log). No native build, SDK installation, signing or physical-device acceptance was performed.

## Matching menus and borderless popups

The next October 22 owner correction makes Combat's Menu match Map's Menu and removes grey title bars from popup windows. Both Menus use the same fitted **560×660 preferred panel**, internal heading, shade, **18 px** action text, **68 px** minimum action rows and exact footer geometry. Actions are Resume Map/Combat, Options, Collection, unavailable Store and Quit to Home. Combat retains truthful battle-entry replay copy and all existing navigation behavior.

All native window constructors are borderless. Guide/error/result and experiment-observation titles appear inside their content panels. Native Menu/Guide remove the unused native-footer gap and title-bar allowance, retaining **24 px** outer margins and **36/40 px** horizontal/vertical padding. Native buttons and their callbacks remain the same objects. The Guide heading receives its intended width before its text changes, preventing a transient oversized window on first open.

Actual renders at **450×1000, 720×1600 and 360×640** pass **384 panel/input checks**. Paired measurements compare Menu panel/action rectangles, fonts and primary/secondary palettes, then exercise native Resume, Options, Collection, unavailable Store, Quit/Cancel, Guide, short-body scrolling and pending rewards. Battle/controller/run/RNG/selection/scroll remain unchanged by inspection and cancellation. [Results](../output/qa/menu-match/results.json), [capture log](../output/qa/menu-match/capture.log), [Combat Menu](../output/qa/menu-match/combat-menu-450x1000.png), [narrow Combat Menu](../output/qa/menu-match/combat-menu-360x640.png), [matching narrow Map Menu](../output/qa/menu-match/map-menu-360x640.png) and [borderless Guide](../output/qa/menu-match/combat-guide-360x640.png). Earlier spacing captures and chrome-margin exceptions below are historical.

Final validation also passes **1,174 full UI checks** and **106 application-shell checks**. The fresh resource-only package passes **386 policy/integrity checks, 106 isolated payload-decode checks and 32 Python tests**. `builds/menu-match-resources/RuneCast.pck` has **12,295,648 bytes**, **373 entries**, SHA-256 **`6f57f0c98679e58535cbd025abe94307984c2b31c234bb459f0cbf205dda2269`**; all **200** manifest source hashes match the final runtime. [UI log](../output/qa/menu-match/ui-tests.log), [shell log](../output/qa/menu-match/shell-tests.log), [package audit](../output/qa/menu-match/resources/resource-audit.json), [source manifest](../output/qa/menu-match/resources/source-manifest.json) and [Python log](../output/qa/menu-match/resources/python-tests.log). No native build, SDK installation, signing or device acceptance ran.

## Menu and panel spacing follow-up

The owner's October 22 follow-up requests taller Menus/buttons and more padding and margin for panel windows. Map and Combat Menus now prefer **660 px** height with **68 px** action rows and **14 px** gaps. Shared modal bodies use **36 px** horizontal and **40 px** vertical padding, with **20 px** title/body/footer separation. A shared fitter keeps panels inside a **24 px** gutter and reduces the scrolling body on short screens so fixed actions remain reachable. Native window clients use the same gutter; their embedded decoration extends 8 px beyond each side, retaining at least 16 px to the screen edge.

This applies to Options, Guide, room inspection, result/entry/quit confirmations, collection, rewards and Combat inspection/Pass. Existing gold frames, navy bodies, cards, board and 82 px navigation are preserved. A passive reward-card hit-test defect exposed by the new scroll checks is also fixed: controls that explicitly ignore mouse input no longer intercept their containing touch scroll, while interactive children retain native input.

Actual rendered panels were inspected at **450×1000, 720×1600 and 360×640**. The capture uses ordinary fixed-seed Combat commands in the excluded reward fixture to reach rewards; it does not manufacture visits. [Capture runner](../tests/panel_spacing_capture.gd), [measurements and input assertions](../output/qa/menu-spacing/results.json), [Map Menu](../output/qa/menu-spacing/map-menu-450x1000.png), [narrow Combat Menu](../output/qa/menu-spacing/combat-menu-360x640.png), [narrow Options](../output/qa/menu-spacing/map-options-360x640.png) and [collection](../output/qa/menu-spacing/collection-720x1600.png). Earlier RC-027 captures and package hashes below remain historical evidence for the initial implementation.

Final follow-up validation: **312 rendered panel/input checks, 1,174 full UI checks and 106 application-shell checks pass**. The UI total includes three new regressions for passive-card scrolling and native child-control ownership. Capture checks cover reachable actions, touch scrolling, cancellation, unchanged battle/RNG/selection/scroll and pending-reward preservation. [Capture log](../output/qa/menu-spacing/capture.log), [UI log](../output/qa/menu-spacing/ui-tests.log), [shell log](../output/qa/menu-spacing/shell-tests.log) and [repaired reward swipe](../output/qa/menu-spacing/rewards-scrolled-450x1000.png).

The fresh resource-only package, built after the touch fix, passes **386 policy/integrity checks, 106 isolated payload-decode checks and 32 Python tests**. `builds/menu-spacing-resources/RuneCast.pck` has **12,294,416 bytes**, **373 entries** and SHA-256 **`54ff195dc0b2165e8155732d98e92eee81d91f4306762b9ca5adbbd485209d67`**. [Audit](../output/qa/menu-spacing/resources/resource-audit.json), [source manifest](../output/qa/menu-spacing/resources/source-manifest.json) and [Python log](../output/qa/menu-spacing/resources/python-tests.log). No native mobile build, SDK installation, signing or physical-device acceptance was performed.

## Approved decisions and supported production scope

The owner answered **“Unlock definitions”** and **“Accept”** to the milestone and pool proposals. The [dated decision](decisions.md#october-22-2026--rc-027-reward-and-definition-unlock-contract-accepted) supersedes earlier unresolved progression statements:

- Permanent acquisition unlocks a definition, not stored copies. Shadeling victory and final-guardian/map completion each offer one still-locked implemented definition. Repeat milestones consider only still-locked definitions; an exhausted pool grants nothing and no compensation.
- Run victories offer up to three distinct eligible definitions; Choose adds one new run instance, while Skip adds none. Owning copies does not exclude a definition. Small pools show fewer options and an empty run pool explicitly permits Skip. There is no Gold payout unless explicitly configured.
- Spark, Shield, Focus and Conjure Spark start unlocked. The existing eight-card starter is unchanged. Unlocks affect future reward/shop eligibility, not starter composition. Free Spark and unimplemented catalogue entries remain excluded.

All four currently implemented ownable definitions are initially unlocked. Consequently a production Shadeling milestone records **exhausted**, with zero permanent award, rather than inventing an unavailable rune. The separate required run-card choice remains pending until Choose/Skip. Exhaustion records its own once-only transaction identity and cannot be reused for compensation.

`ProgressionState.production_rules()` binds only the implemented `training_shadeling` definition with explicit `boss` role. Its `room_normal` family grants no ordinary-role permission. It offers up to three eligible run definitions, zero Gold and the permanent milestone. Missing normal/elite/guardian definitions need exact validated ID/role policy entries when RC-034 supplies their content; the accepted rules above apply when those encounters exist. Development encounters receive no production rule. Shop-pool consumers remain RC-029/RC-035 work.

## How to try it

Normal launch remains:

```powershell
.\tools\godot.ps1 -Action run
```

Home → **New Run → Map → Menu → Collection** shows eight actual owned instances and the separately labelled four session definition unlocks. Tap a card to inspect its effect, cost, owned copies and UIDs. Back returns to the collection's previous scroll position; Close returns to the same Menu/Map. Opening production rooms still explains missing content without consuming a visit.

Use the separately named, excluded reward-enabled fixture to play rewards now:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --path . --script res://tests/reward_integration_runner.gd -- --manual
```

The Map says **Reward-enabled test fixture**. It reuses existing Calibration Wisp content at the first two depths, with the retained four-energy/two-draw first loadout and three/three second loadout. Its **7 Gold**, development-role eligibility and three-option policy are explicit verification values, not production economics. No earlier visits are fabricated; the nine-depth graph, branches, designated depth-six Shadeling and separate guardian remain. The fixture stops at unavailable production content after the two supported encounters. RC-026's original reward-free fixture remains separate and unchanged.

1. Enter an available Wisp node and win with ordinary Combat controls. The settled result has **Review rewards**, **Return to Map** and **Return Home**. Result acknowledgement alone grants nothing.
2. Review the offered cards; scroll to each explicit Choose action. Gold has a separate Claim action. Choose/Skip and Gold can resolve in either order; successors wait for all required components/choices.
3. Close/Back leaves the choice pending. After acknowledging, inspect the current Map node → **Review rewards**. Map → Home → **Continue** reopens the same pending offering. Dismissing the unacknowledged result to Home instead reopens that result on Continue.
4. Claim a card, then enter the next connected Wisp. The new UID joins the ordinary continued shuffle/draw exactly once; it is never inserted into the settled encounter's hand.
5. During live Combat, **Menu → Collection** shows hand/draw/discard/installed locations alongside run ownership. Generated temporary cards appear separately. Closing restores the prior Menu, model/controller, selection, preparation and scroll. Live Map Resume and confirmed Quit → exact entry replay retain their existing behavior.

## Ownership, RNG and transaction interfaces

| Interface / record | Contract |
| --- | --- |
| `ProgressionState(validated_catalog, initial_ids)` | Shell-owned session definition eligibility, separate from run instances. Production defaults to the four current definitions; narrowed initial sets exist only in explicit tests. The same owner survives New Run. `snapshot()` is detached. No disk/settings writes. |
| `RunState(..., reward_rules, profile)` | Optional sixth/seventh constructor arguments. Production and test callers supply separately identified policies. No supplied/matching policy yields an unavailable pending record, not an implicit Skip or award. |
| Reward identity | Exact `{run_id, route_id, node_id, visit_id, choice_id}`. Encounter definition and battle replay generation are never claim keys. `encounter_rewards` owns the run card/configured Gold; `permanent_unlock` is a separate qualifying milestone choice. |
| Offer generation | Once, after accepted terminal battle transfer, using validated implemented definitions and explicit ID/role policy. Distinct options, no artificial padding. Stored `offered_ids` remain stable across inspection, Home/Continue and reopening. |
| Reward RNG | Separate generator seeded with `seed XOR 0x52435257`; exposed detached `reward_rng_state`. Route, card, endpoint and connector-kit streams are unchanged. Inspection/rejections/empty or exhausted pools consume no reward randomness. |
| `pending_reward()` / `reward_snapshot(identity)` | Detached records, including policy/kind, eligible/offered IDs, resolution, chosen ID/UID, Gold amount/claim state and receipts. Current unresolved choices are surfaced in order. |
| `choose_reward(identity, definition_id)` | Validates exact active identity, unresolved choice and eligibility before commit. A run card receives the transferred authoritative `next_uid`; a definition unlock changes profile eligibility without allocating a card/UID. |
| `skip_reward(identity)` | Resolves only an explicitly skippable run-card choice. No grant. Milestone unlocks have no implicit Skip; approved exhausted milestones resolve with a no-award record. |
| `claim_reward_gold(identity)` | Separate once-only configured payout. Does not resolve the rune selection. No unconfigured boss/guardian payout. |
| Transaction receipt | `{ok, error, record, claim, granted_card, gold_granted, transaction_id}`. IDs are the serialized five-part identity plus `/rune`, `/gold` or `/definition_unlock`. Choose and Skip share the same rune component identity. |
| Atomic boundary | The route choice is prevalidated and completed before publishing card/Gold/claim/profile changes. A transaction guard rejects reentrancy. Profile commit uses validated static assignments, avoiding a fallible callback after route completion. A rejected final choice leaves all owners unchanged. |
| `acknowledge_result(identity)` | Independent acknowledgement, grants nothing. Reward transactions are deliberately valid in both `result_pending` and `pending_choices`; no grant-first/failed-choice-completion split. |
| Result presentation | `pending_result.rewards` and `reward_summary` reflect actual committed cards/Gold/unlocks and remaining choices. Reward-free/defeat results truthfully retain no-award copy. Guardian completion requires all choices before a completion state can be shown. |
| Collection | `CollectionData.describe(run_snapshot, catalog, live_snapshot)` joins owned identities to detached zone data without taking ownership from those zones. Installed cards remain owned; new awards can have no settled-battle zone; temporaries never inflate owned counts. No upgrade mechanics are invented. |
| Reward audio | Existing coordinator `reward_committed(transaction_id, receipt)` accepts only successful nonempty awards and deduplicates the transaction. Skip, exhausted/no-op, failed/duplicate callbacks, inspection and reopening are silent. Muted/interrupted receipts are consumed without delayed playback. |

Generic `complete_room_choice()` cannot bypass reward-owned choices. Pending requirements are never automatically cleared merely to unlock successors. Replayed battles keep the visit identity; terminal replay creates one offering for that visit, while later visits reusing the same encounter definition have distinct records.

Collection and rewards reuse current compact painted cards/icons, fonts, gold frames and navy modal bodies. The shared 82-pixel neutral navigation and integrated parchment are preserved. Viewer controls invoke no technique, shuffle, gameplay edit or Combat construction. Persistent reward callbacks capture their displayed identity, and refreshing cancels held input; stale callbacks cannot act on the next choice. Shell transition ownership stays locked through synchronous reward audio callbacks and view refresh.

## Validation and visual review

Pinned **Godot 4.7.2.stable.official.ed1daf0bf**, Windows Compatibility renderer. Task-local application-data/cache paths and Dummy audio isolate settings and audible playback. Logs were inspected for script/engine errors as well as assertion totals.

| Coverage | Final result |
| --- | --- |
| Full core including reward/route/encounter suites | **2,354 checks, 0 failures** — [log](../output/qa/rc-027/core-tests.log). |
| Focused authoritative rewards | **75 checks, 0 failures** — [log](../output/qa/rc-027/reward-core.log). |
| Existing complete UI | **1,171 checks, 0 failures** — [log](../output/qa/rc-027/ui-tests.log). Deliberately missing/malformed fixtures retain expected diagnostics. |
| Existing application shell | **106 checks, 0 failures** after callback hardening — [log](../output/qa/rc-027/shell-regression.log). |
| Collection data and live ownership | **127 checks, 0 failures** — [log](../output/qa/rc-027/collection-tests.log). |
| Collection/Menu/Back/session lifetime | **28 checks, 0 failures** — [log](../output/qa/rc-027/collection-shell.log). |
| New reward audio/receipt/catalogue checks | **159 checks, 0 failures** — [log](../output/qa/rc-027/reward-audio.log). |
| Existing full audio suite | **428 checks, 0 failures** — [log](../output/qa/rc-027/audio-tests.log). |
| Existing focused presentation | **31 checks, 0 failures** — [log](../output/qa/rc-027/presentation-tests.log). |
| Existing reward-free real encounter regression | **78 checks, 0 failures** — [log](../output/qa/rc-027/reward-free-tests.log). |
| Reward-enabled real encounter integration, headless | **160 checks, 0 failures**, including retained stale footer callbacks and synchronous audio reentrancy — [log](../output/qa/rc-027/reward-reentrant-check.log). |
| Same reward/collection integration, rendered | **228 checks, 0 failures; 34 PNGs** — [log](../output/qa/rc-027/integration-capture.log), [assertions/trace](../output/qa/rc-027/integration/results-capture.json). |
| Shared neutral navigation/native input | **336 checks, 0 failures; 32 PNGs** — [log](../output/qa/rc-027/navigation-capture.log). |
| Absolute Combat-reference geometry | **257 checks, 15 known baseline failures** — [results](../output/qa/rc-027/combat-reference/results.json), [exact comparison](../output/qa/rc-027/combat-reference-baseline-comparison.json). |
| Fresh resource-only package | **386 policy/integrity checks + 106 isolated payload-decode checks, 0 failures** — [audit](../output/qa/rc-027/resources/resource-audit.json), [decode log](../output/qa/rc-027/resources/ios-resource-probe.log). |
| Python package/workflow/transfer regressions | **32 tests passed** — [log](../output/qa/rc-027/resources/python-tests.log). |

Fresh resource-only pack: `builds/rc-027-resources/RuneCast.pck`, **12,293,984 bytes**, **373 entries**, SHA-256 **`4138fd93668e4bd0c4a17359fc86cb04e6b6b7892cda3a22a0ab7b1272d819b7`**. The explicit inventory/probe now includes progression state, collection data/viewer and reward viewer. [Source manifest](../output/qa/rc-027/resources/source-manifest.json) binds the final runtime; the actual payload is decoded from an empty project without workspace fallback. Tests, fixtures, tools, references and evidence remain excluded. The export's existing SDK fallback notice is informational. This is no native build, SDK installation, signing, simulator or physical-device execution.

The absolute-reference failures have identical normalized descriptions and measured values to RC-026: the existing 13-pixel hand/forecast/Cast/navigation displacement remains. Assertions were not weakened and no unrelated layout spacer was added.

Core coverage includes deterministic offers, independent RNG, empty/small/invalid/temporary pools, duplicate/stale requests, both Gold/Skip orderings, transferred temporary-consumed allocator, same encounter across visits, replay, actual defeat, policy-role separation, final-choice rejection atomicity, reentrancy, and detached records. Actual Shadeling wins in an explicitly excluded **opening-boss boundary fixture** verify exhausted production eligibility and narrowed-profile test unlocks across New Run. That fixture does not fabricate preceding visits or prove a complete production tower.

The reward-enabled Wisp run earns its first victory at **21/30 HP**, claims **Conjure Spark UID 13** after temporary allocations, and starts its second real encounter with **nine owned instances** and that UID exactly once. It wins the second encounter and separately skips the rune/claims fixture Gold. Recorded legal controller commands and actual transaction receipts establish this path; no enemy health, endpoint placement, cards, favorable seeds or completed visits are fabricated.

Actual screens inspected at **450×1000** and **360×640**:

| Screen | Desktop | Narrow portrait |
| --- | --- | --- |
| Pending rewards | [image](../output/qa/rc-027/integration/rewards-pending-450x1000.png) | [image](../output/qa/rc-027/integration/rewards-pending-360x640.png) |
| Scrolled offerings/actions | [image](../output/qa/rc-027/integration/rewards-pending-scrolled-450x1000.png) | [image](../output/qa/rc-027/integration/rewards-pending-scrolled-360x640.png) |
| Live collection with installed card | [image](../output/qa/rc-027/integration/battle-installed-450x1000.png) | [image](../output/qa/rc-027/integration/battle-installed-360x640.png) |
| Card details and copy identities | [image](../output/qa/rc-027/integration/battle-installed-details-450x1000.png) | [image](../output/qa/rc-027/integration/battle-installed-details-360x640.png) |
| Temporary cards/session unlocks | [image](../output/qa/rc-027/integration/battle-installed-scrolled-450x1000.png) | [image](../output/qa/rc-027/integration/battle-installed-scrolled-360x640.png) |
| Claimed run ownership | [image](../output/qa/rc-027/integration/collection-awarded-450x1000.png) | [image](../output/qa/rc-027/integration/collection-awarded-360x640.png) |

Native mouse/finger input exercises card details, Choose, Skip, Gold, Close and modal return. Long content scrolls above fixed actions; the narrow initial reward sheet requires scrolling to read full offerings. Visual review confirmed readable card names/effects/cost, separate temporary/definition ownership and intact navy/gold framing. Desktop input/rendering is not physical-device or human acceptance.

Initial development checks exposed narrow modal minimum-size growth and detail scroll restoration before layout settled; deferred refitting and guarded post-layout restoration fixed both. Review also hardened retained footer identities and audio-callback reentrancy. The first reward-free regression revealed a truthful no-award string had been omitted; conditional no-record copy was restored, with the original diagnostic retained [here](../output/qa/rc-027/reward-free-result-copy-before.log). Final results above are after these fixes.

## Reproduce

From `C:\Dev\RuneCast`:

```powershell
$engine = 'C:\Dev\RuneCast\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$py = 'C:\Users\nguye\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$env:APPDATA = 'C:\Dev\RuneCast\output\qa\rc-027\recheck-appdata'
$env:LOCALAPPDATA = 'C:\Dev\RuneCast\output\qa\rc-027\recheck-localappdata'
& $engine --headless --path . --audio-driver Dummy --script res://tests/test_runner.gd
& $engine --headless --path . --audio-driver Dummy --script res://tests/ui_smoke.gd
& $engine --headless --path . --audio-driver Dummy --script res://tests/collection_data_runner.gd
& $engine --headless --path . --audio-driver Dummy --script res://tests/collection_shell_runner.gd
& $engine --headless --path . --audio-driver Dummy --script res://tests/reward_audio_runner.gd
& $engine --headless --path . --audio-driver Dummy --script res://tests/reward_integration_runner.gd
Start-Process -FilePath $engine -ArgumentList @('--path','C:/Dev/RuneCast','--audio-driver','Dummy','--script','res://tests/reward_integration_runner.gd','--','--capture-rewards') -WindowStyle Hidden -Wait
& $engine --headless --path . --export-pack iOS builds/rc-027-resources/RuneCast.pck
& $py tools/verify_ios_resources.py --pack builds/rc-027-resources/RuneCast.pck --engine $engine --report output/qa/rc-027/resources/resource-audit.json
$env:RUNECAST_RESOURCE_TEST_PACK = 'C:\Dev\RuneCast\builds\rc-027-resources\RuneCast.pck'
& $py -m unittest discover -s tests -p 'test_ios_*.py' -v
```

The task-local `audio_runner.gd` and `reward_free_runner.gd` copy the existing runners with only evidence destinations changed, preserving earlier records. The original RC-026 manual fixture command remains available. Source/test files and QA runners are excluded from production export.

## RC-028 persistence handoff and remaining limits

No save system or settings-file run/profile storage was introduced. The shared progression object survives session New Run, but closing the process loses the entire run and unlock state. RC-028 must persist both lifetimes deliberately.

Persist/restore authoritative run/profile ownership, run/route/node/visit identities, policy/version, offered and eligible IDs, rune/Gold/unlock resolution and receipts, dedicated reward RNG, completed transactions, allocator (including temporary-consumed UID gaps), route locks and result acknowledgement. A disk commit must encompass the resource grant, claim record and corresponding choice completion, including the session-profile owner for unlocks. Reopening must use retained offers/receipts rather than resampling; restore the exact pending result or reward screen and keep interrupted-battle entry replay separate. Presentation dictionaries are inspection contracts, **not save formats**. RC-028 owns serialization schema, atomic files, recovery, migration and unknown/corrupt version behavior.

The current catalogue has no locked production definition to award, and final guardian content is absent; no actual guardian playthrough is claimed. Production missing rooms/enemies remain blocked, while exact ID/role policy registration awaits those definitions. Store/shop/recovery/events, final roster/catalogue, upgrades/relic effects, pricing and pacing retain their existing task owners. RC-024A's remaining Store decisions are not completed by this reward-specific approval.
