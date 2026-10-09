# RC-005 circuit experiments

RC-005 version `rc005_v1`, October 9, 2026, supplied nine bounded scenarios and 19 variants covering six questions. Those original fixtures and the protocol below retain their historical experimental semantics. RC-006 adds the separate [full-reset follow-up](#rc-006-full-reset-follow-up), version `rc006_full_reset_v1`, and [moving-endpoint follow-up](#rc-006-moving-endpoint-follow-up), version `rc006_moving_endpoints_v1`, plus the corrected [free-endpoint follow-up](#rc-006-free-endpoint-follow-up), version `rc006_free_endpoints_v1`; the current menu has nine scenarios and 22 variants. Experiment execution is not production acceptance. Normal Training Crypt and Calibration Wisp retain their rules; these fixtures are not the final RC-009 board set.

## Launch, controls and exact replay

From `C:\Dev\RuneCast` in PowerShell:

```powershell
.\tools\godot.ps1 -Action run
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant control -Seed 42
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant treatment -Seed 42
.\tools\godot.ps1 -Action run -Experiment -Scenario encounters -Variant treatment -Seed 42
.\tools\godot.ps1 -Action capture -Experiment -Scenario blocked -Variant treatment -Seed 42 -CapturePath res://output/qa/rc-005-blocked.png
```

Omitting `-Experiment` preserves normal launch. Experiment arguments apply to `run`/`capture` only and cannot be combined with `-Encounter`. Direct engine equivalents are `-- --experiment --scenario=effects --variant=control --seed=42`. Invalid scenarios, variants, options or seeds fail clearly; no fallback model is created at invalid startup.

The development panel shows active scenario, variant, seed, encounter number and concise rule differences. Choose a scenario and variant, enter an integer seed (0–2,147,483,647), and press **Launch**. Selection alone does not change the active session. Use ordinary tools/cards, Rotate, Flip, Undo, Erase, Cast and Menu > Pass. **Next encounter** enables after the first victory only in the paired scenario. **Inspect / export** shows the full local JSON, absolute output path and optional note field. Latest ordered hit/cleanup feedback is visible above the arena; full events remain in the record.

**Exact replay** saves the prior record, then creates a new model and record from the cached starting configuration and original seed, even if fixture files have since changed. Repeating the same launch command reproduces the starting configuration for that version; check the recorded fingerprint when comparing installations. **Menu > Restart continues RNG**, restores encounter one and logs a restart lifecycle entry. It is intentionally different from exact replay. A failed export leaves gameplay available and preserves the current session when Launch/Replay is attempted, so its in-memory record can be exported again.

## Shared fixtures and constants

Default comparison seed: **42**. Repeat matched pairs with **1234** only as a separately labelled repetition. Within each pair hold seed, permanent collection, enemy, stats, draw rules, temporary rules and all unspecified options constant. The fixture collection, in allocation order, is Spark, Shield, Conjure, Spark, Shield, Focus, Focus, Conjure. Opening hand: Spark, Shield, Conjure. Player starts at 40/40 HP, six energy, draw three each turn; Experiment Wisp has 36 HP and repeatedly attacks for three. Pair encounters use 24 HP each. Scalar effects/costs use the existing rune definitions. Extra energy supports experimental comparison, not a production balance recommendation.

Cells are zero-based, row-major:

```text
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15
```

Rotation `rN` means N clockwise quarter turns; unspecified rotation is zero. `flip` reverses an ordinary connector. All omitted cells are empty. Begin outputs east; End inputs north before rotation. Straight effects input west/output east; corner effects input west/output south. Endpoints are protected wherever located.

| Fixture | Exact starting placements / known solution |
| --- | --- |
| P: one pair | Begin0, Spark1, Split2, Corner3, Straight6 r1, Straight7 r1, disconnected Shield8, Join10, Corner11 r1, End14. Opening Cast = 12 damage, 0 shield, cost3. |
| Q: two pairs | P with Join6 replacing Straight6 and Split7 r1 replacing Straight7. Two Splits/two Joins are powered; Spark has three contributions. Cast = 18 damage, cost4 at Split cost1 or cost6 at cost2. |
| S: simple edge path | Begin0, Spark1, Straight2, Corner3, Straight7 r1, Corner10 r3 flipped, Corner11 r1, End14. Cast = 6 damage, cost2. |
| R: alternate endpoints | P with every cell `i` moved to `15-i` and every rotation increased by2 modulo4. Begin15 r2, End1 r2; same 12 damage/cost3. |
| T: corner temporaries | S with Free Spark corner at3 instead of Corner3; additional disconnected Free Spark corner8 r2. Permanent Spark remains1. Opening Cast = 12 damage/cost2. |

All variant openings are complete and affordable. [Fixture source](../scripts/core/experiments.gd) provides detached documents, scenario metadata and known solution commands. The installed Shield in P is intentionally disconnected: it counts as an owned installed permanent instance but contributes no shield or cost. Its exclusion from hand/piles is a useful depletion case.

## Bounded comparison matrix

Each row names a question/hypothesis, matched control/treatment, starting solution, measurements and limits. The shared constants above apply to every row unless explicitly changed here.

| Family / stable scenario | Question and hypothesis | Control / treatment and starting setup | Measurements and observation questions | Limits / confounds |
| --- | --- | --- | --- | --- |
| A `effects` | Does consuming powered effects increase reconstruction and card circulation? | `control`: persistent. `treatment`: powered permanent effects enter discard after Cast and become matching connectors. Both start P, seed42. Cast once; compare cell1 and disconnected Shield8, then reconstruct and Cast again. | Accepted edits, repeated layout hashes, permanent cards in hand/piles, preparation time; does the tester understand which effects vanished and why? Does circulation yield useful choices? | A discarded effect can be drawn again immediately. Counts cannot determine usefulness or enjoyable rebuilding. Six-energy fixture may hide production pressure. |
| B1 `split_inventory` | Does allowing a second pair create useful layout choice or more upstream stacking? | `control`: one pair. `treatment`: two pairs. Both start P, Split cost1, seed42. Treatment witness: place Join6, place Split7, rotate7 once, then Cast Q (18 damage/cost4). Control rejects extra stock. | Achieved amplification, installed/available stock, edits, preparation time; where are effects placed relative to both Splits? | Inventory is the only allowance change. Q multiplies by3, not4; one fixture cannot characterize all possible boards. No rewards/relics grant stock. |
| B2 `split_cost` | Does additional energy pressure change use of an available second pair? | Both start Q with two-pair allowance, seed42. `control`: each powered Split costs1; `treatment`: each costs2. Opening costs4 versus6. Cast immediately; on an exact replay, Pass once (drawing both Focus cards), play Focus, then attempt unchanged Q. | Actual energy spent, unaffordable rejections, techniques, casts/passes and layout changes; does a tester sacrifice amplification for techniques? | Extra-pair inventory/geometry is a dependency held fixed. This tests uniform per-Split cost, not a special surcharge only for the second piece. |
| C1 `endpoints` | Does changing endpoint orientation alter comprehension or encourage new layouts? | `control`: P. `treatment`: R (180-degree rotated board and ports). Seed42; opening Cast is the valid solution for both. | Misconnections, rotations, repeated layouts, preparation time; can the tester identify source/sink and direction? | Rotation holds graph and power exactly constant, so spatial orientation is isolated; it does not test all asymmetric endpoint puzzles. |
| C2 `blocked` | Does a prohibited cell constrain attempted reconstruction understandably? | Both start S, seed42. `control`: cell6 editable. `treatment`: cell6 blocked, zero ports, cannot erase/replace/rotate/flip. Opening Cast is valid; try routing a branch through6. | Rejected attempts, alternate route selection, explanation of block, valid repairs. | The opening path avoids6 and is equally strong. The constraint matters when exploring alternate paths; this is one obstacle, not RC-009 content. |
| C3 `ports` | Can corner effects create spatial decisions with readable connectivity? | `control`: S, straight Spark1. `treatment`: same edge path, Straight1 and corner Spark3, seed42. Both Cast6/cost2. Rotate Spark to inspect disconnection, Undo, Cast. | Rotations/undo/invalid casts, placements, correct prediction of ports and repairs. | The installed Spark moves from1 to3 to preserve a valid identical path. This unavoidable starting-position difference must be considered; every Spark uses the chosen shape, while Shield stays straight. |
| D `hits` | Can testers explain one total versus ordered contributions? | P, seed42. `control`: aggregate12. `treatment`: `[6,6]`, total12. Cast and inspect Latest plus JSON. | Predicted/actual damage, hit count, lethal truncation understanding and feedback preference. | Equal-total hits without armor/on-hit mechanics may be mechanically equivalent. This exposes comprehension and event/presentation differences; it cannot prove future combat balance. |
| E `expiry` | Which expiry geometry produces understandable repair work? | T, seed42 in all three. `control`: straight; `retained`: matching corner; `empty`: remove cell. Cast or Pass, inspect3 and8. Replay, use Conjure and leave generated corner in hand, then Pass. | Repair edits/time, validity after cleanup, unused-card expiry comprehension, orientation predictions. | Alternate corner ports are an explicit dependency held constant, including Conjure's generated target. These fixtures do not imply corner runes belong in production. |
| F `encounters` | Does retaining topology/instances reduce repetitive setup or reduce fresh choices? | Both start P, seed42, two 24-HP Wisps. `control`: reset to starting connectors. `treatment`: retain selected topology/permanent runes. Cast twice, press Next. | Encounter-two edits/time, layout repetition, hand/installed distribution, HP carried, explanation of new hand. | Identical compatible geometry only; no rewards, healing, tower route or saving. Retain changes the eligible card pool, an intended consequence rather than independently equal draws. |

## Exact resolution semantics

**Persistent / consumed.** Normal and experiment controls preserve ordinary installed effects. Consumption is applied only to powered permanent effect cells of an accepted Cast, once per physical card regardless of Split amplification. Damage and surviving-enemy shield/retaliation resolve first, then consumed permanent UIDs enter discard in ascending cell order, replaced by matching straight/corner connectors at the same rotation. Board temporary expiry follows, then hand discard/temporary deletion, undo clearing, terminal outcome or next-turn energy/draw. Consumed cards can therefore be recycled by the same turn's draw. Lethal casts still consume/clean up; rejected casts and Pass do not consume permanents. Disconnected permanents stay installed. Generated temporary runes never enter permanent ownership or piles.

**Extra pairs and ports.** Every physical powered Split pays the selected uniform cost; Join costs zero. Disconnected special pieces consume stock but no cast energy. Editing, rendering and evaluation use the same normalized piece ports. Blocked cells have no ports and remain immutable even through direct model commands. Alternate endpoints are found by kind and protected; exactly one of each is validated, with ports facing a board neighbor. Effects rotate but do not support Flip. Ordinary wires retain Flip.

**Multi-hit.** A positive damage rune appends its value to an ordered contribution list after its incoming contributions. Split copies the entire list onto each branch. Join concatenates parent lists in deterministic parent arrival order from Begin's depth-first output traversal (base Split east then south, rotated together). End releases each positive contribution as a separate ordered damage event. Stop immediately when enemy HP reaches zero; skip remaining hits and retaliation. `hit_index` is zero-based; `hit_count` describes the constructed list before lethal truncation. Each event reports requested `amount` and clamped `applied`. A zero-damage multi-hit spell has no damage events. Shield remains the existing single aggregate total, used only if the enemy survives, then expires; there are no armor/status/on-hit effects or multiple enemies.

**Temporary expiry.** Every installed temporary, powered or disconnected, expires after accepted Cast or Pass, including terminal turns. `straight` makes Straight with the rune's rotation; `retained` makes its actual straight/corner shape with that rotation; `empty` makes `{}`. Unused hand temporaries vanish without a connector and never enter discard/draw. For T, straight replacement at3 r0 points east off-board, so the circuit breaks; retained Corner3 r0 keeps the path valid; empty requires repair. Cell8 keeps r2 in straight/retained cases but remains disconnected. Repair3 using Corner r0 for straight/empty. History is cleared, so Undo cannot recover an expired card.

**Encounter transfer.** Only a victory in encounter one enables `next_encounter`, exactly once. The second enemy repeats the same configuration. Current/max player HP and the permanent collection/UIDs carry; no healing occurs. Reset rebuilds the original endpoints, blocked cells and ordinary/special connectors, converting every template rune slot to its matching connector rather than reinstalling a card. Retain keeps the selected current topology and installed permanent UIDs; any temporary is cleaned according to expiry. No temporary is recreated from the opening fixture.

All eligible permanent instances from board/hand/draw/discard are reconciled in UID order. Retained installed instances are excluded. Curated opening IDs select the first eligible matching UID; a missing eligible copy is skipped. Remaining cards are shuffled with the **continuing** RNG stream into a fresh draw pile; a draw-policy fixture then takes its configured opening draw. Old hand/discard/history are cleared; energy resets to6, turn to1, enemy health to24, shield is transient and carries nothing. Generation increments while action identity continues. Geometry changes and transition arguments are unsupported and explicitly rejected; the loader rejects second-board options. Duplicate Next calls cannot duplicate ownership or create encounter three.

For encounter-two reset's valid damage solution, install the new opening-hand Spark at1, then Cast twice. Retain can Cast twice without that install. Both may be explored freely before advancing; record any changed layout. If the first encounter ends in defeat, replay; there is no transfer.

## Local observation records

Human output: `user://experiments/<scenario>-<variant>-<time>-<ticks>.json`. **Inspect / export displays the resolved absolute path.** On the Windows default configuration this is below `%APPDATA%\Godot\app_userdata\Rune Cast\experiments`; use the displayed path as authoritative. Each launch/exact replay gets a fresh filename. Normal gameplay has no recorder. No network, accounts or analytics are involved.

Records are autosaved on controller changes and explicit export/notes. Writes use a temporary sibling file and backup/restore publication, with visible errors; the last complete file and in-memory gameplay are preserved on ordinary write failures. A crash during a filesystem rename can leave a recoverable `.previous` file. This is an observation log, not a crash-safe game save. Busy guard rejections are saved at the next controller change or explicit export. Closing during an unsaved write failure cannot guarantee persistence; keep the session open and retry/export to a writable destination through the recorder API.

Automated tests and captures use only `res://output/qa/experiment-records/`, separate from human observations. Automated capture records include a QA note. Do not pool them with participant data.

Schema1 is JSON with `experiment`, `configuration_fingerprint`, full normalized `starting_setup`, `seed`, summarized `initial_state`, `commands`, `lifecycle`, `notes`, and `totals`. Fingerprints are SHA-256 of sorted-key JSON. The setup hash includes the scenario/variant and display configuration; compare expected pair differences rather than requiring control/treatment hashes to match. Same-version exact replay should match the original hash.

| Metric / field | Definition and limit |
| --- | --- |
| `attempts`, `accepted`, `rejected` | Commands reaching the controller, including explicit busy/terminal/model rejections. Disabled controls and selection-only taps are not command attempts. |
| `edits`, `edits_by_kind`, `cumulative_edits` | Accepted placement, erase, rotate, flip and undo commands. Undo also has its own kind. Includes replacements/no-op placements; an edit count does not prove a meaningful layout change. |
| `casts`, `passes`, `techniques`, `cost` | Accepted commands; actual energy deducted in cast/technique events, not forecast cost. Rejections spend zero. |
| `damage`, `retaliation`, `hits` | Actual clamped enemy/player HP loss and ordered requested/applied hit values. Overkill is not counted as applied damage. |
| `shield`, `blocked` | Shield actually emitted against a surviving enemy and damage blocked during retaliation. Potential lethal-cast shield is visible in forecast but produces no shield event. |
| `preparation_ms` | Monotonic elapsed milliseconds from session/turn entry to accepted Cast/Pass recording. Includes thinking, edits, techniques, idle time, UI/write/presentation time and rejections; not CPU time or a validated measure of engagement. Tests inject a controlled clock. |
| `elapsed_ms`, `turn_elapsed_ms` | Session/turn-relative monotonic time at a command; Restart starts a fresh turn timer and adds a lifecycle entry. |
| `before` / `after` | Encounter/turn/stats, exact board cells and forecast, UID-independent layout fingerprint, hand/draw/discard card IDs/UIDs and category counts. Same geometry/definitions with another card copy gets the same layout hash. |
| hand `empty`, composition | Empty means zero cards. Nonempty does not mean usable or tactically useful. Record tester reasoning separately; do not infer useful-card depletion solely from size. |
| `outcomes`, `transitions`, `lifecycle` | Actual battle end, pair transfer and RNG-continuing Restart records. Event order and action IDs allow inspection. |
| `notes` | Optional local free text with relative time; no participant identity is required. |

The controller records each accepted authoritative result once before emitting presentation signals. Event replay, duplicate completion and exports do not add commands or consume gameplay RNG. Rejected attempts are separate observations, not accepted action IDs. The record is detached from model state and retains ordered events for auditing; it does not claim to record every hover, thought or screen interaction.

## RC-006 human protocol

1. Verify version/fixture fingerprint, seed, display/input context and writable record path. Use anonymous session labels in external notes, not names or contact data. Keep automated QA separate. Confirm there is no prior claimed participant evidence.
2. Familiarize the tester with normal training controls, costs, one Split/Join and Pass. Allow practice without including it in comparison records. Explain each candidate neutrally and ask for a prediction before its first cast/expiry/transfer.
3. Compare matched control/treatment setups at seed42. Alternate which variant is first across sessions where practical; for expiry vary the order of all three. Keep instructions/task time consistent and log the order. Do not coach the known solution until the free attempt ends; record any assistance.
4. Allow free construction through several turns, then demonstrate the documented valid solution. For B1 explicitly attempt the second pair; for B2 try a technique before a costly cast. For C test the changed location/cell/ports. For E run Cast, Pass, unused Conjure card, and disconnected temporary cases separately with exact replay. For F finish both encounters under both variants.
5. Record observed actions, validity errors, repairs, repeated layouts and timing separately from tester explanations/preferences. Ask what changed, where each card went, what costs were paid and what will happen next. Ask whether an apparently full hand offered a useful action and why.
6. Export notes/records before switching. Repeat a matched pair with seed1234 if useful; label learning/order effects. Compare within matched setups and distinguish fixture limitations from a rule's broader consequences.
7. RC-006 summarizes evidence by question, uncertainty, disagreement and possible focused follow-up. Do not choose a winner from edit counts alone. Update production decisions only after actual human evidence; RC-007 implements selected rules.

## Blank observation and decision template

```text
Session label (anonymous):
Date / input-display context / familiarity:
Harness version / configuration fingerprints / seed:
Scenario / variant order / record paths:
Task instructions / familiarization / assistance:

Prediction before action:
Observed behavior (actions and event/turn references):
Layout changes / repeated layouts / card availability:
Errors / repair actions / preparation times / interruptions:
Encounter outcomes / transition observations:
Tester explanation (quote or paraphrase clearly labelled):
Tester preference and stated reason:
Observer interpretation (separate from observations):
Confounds / order or learning effects / missing evidence:

RC-006 question:
Evidence supporting each candidate:
Counterevidence / uncertainty / proposed follow-up:
Decision: PENDING
Decision owner / date / linked supporting records:
Implications for RC-007, RC-009 and content:
```

At the RC-005 handoff, all six production decisions remained pending. Automated tests establish executable semantics, conservation, reproducibility and interface behavior; they do not establish enjoyment, comprehension, mobile usability, participant preferences or future balance. RC-006 requires humans; RC-010 remains independently available. Dated commands/counts/screenshots are in [verification](verification.md).

## RC-006 study progress — October 9, 2026

RC-006 is **partial**. The owner selected **endpoints-only starts every turn after Cast/Pass, all installed permanent cards to discard (including disconnected ones), and fresh normal draws with repeats allowed**. Those rules are exercised only in the separate follow-up below; normal gameplay is unchanged and matched-comparison validation is absent. The owner additionally selected **randomly changing Begin/End positions every turn at any two distinct cells, including adjacent cells, with normal player-controlled Rotate**. The moving-endpoint feedback confirms clearing and corrects the facilitator's protected-rotation/eight-layout interpretation; the separate [free-endpoint follow-up](#rc-006-free-endpoint-follow-up) is available. The owner now confirms manual endpoint rotation works; S01-08 records seven accepted rotations across Begin and End. It contains no Cast, Pass, Undo or adjacent-position play, so those outcomes are not inferred. The played full-reset fixture retains fixed endpoints. No topology or replacement connector carries into the selected next-turn start, and no anti-repeat guarantee is added. Initial orientation generation, first-turn policy, exact timing, blocked-cell compatibility and other fields remain unresolved in the [production contract](production-rules-spec.md), so RC-007 is not ready.

The [study results and evidence register](rc-006-playtest-results.md) hold current attempt details. Anonymous owner session `RC006-S01` has participant-reported practice completion, mouse input, initial control edits and a later treatment record containing two Casts. The owner reports expected doubled damage and new cards, but says “board should be clear.” The original treatment intentionally leaves connectors/disconnected effects; that report motivated the separate follow-up, not a retrospective change to old semantics. In the full-reset relaunch, the owner confirms clearing works and the hand changes; the two-Cast record corroborates that behavior. No completed matched comparison is recorded. “First game created” does not establish playing familiarity. No general testing waiver, future participant availability or mobile acceptance is inferred.

## RC-006 full-reset follow-up

This additive study fixture is **`effects/full_reset`**, version **`rc006_full_reset_v1`**, encounter ID `rc006_effects_full_reset`, board ID `rc006_effects_full_reset_board`. It exercises the owner's selected reset/discard/draw direction without changing normal gameplay or any original `rc005_v1` variant. Seed42 configuration fingerprint: `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`. Preserve that configuration identity separately from raw file hashes and previous fixture versions.

```powershell
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant full_reset -Seed 42
```

The screen identifies it as **RC-006 FOLLOW-UP**. It starts with only Begin at cell0 and End at cell14, both at their normal orientations; no other piece or installed card is prefilled. Retain the existing eight-card collection, curated three-card hand (Spark, Shield, Conjure), player40/40, energy6, draw3, enemy36 HP attacking3, and one Split/Join pair. Split costs1, Join0, aggregate damage and straight effect ports remain fixture controls, not new production selections. The player constructs the first circuit freely.

| Follow-up invariant | Experimental behavior |
| --- | --- |
| Accepted Cast | Pay/evaluate and resolve damage, then shield/retaliation only if the enemy survives. Clear the board afterward. |
| Accepted Pass | Retaliate without spell/shield, then perform the same full board cleanup even if the circuit is invalid. |
| Board cleanup | In cell order, remove every nonendpoint piece. All installed permanent cards, powered or disconnected, enter discard exactly once; installed temporaries disappear and never enter owned piles. Wires, Split and Join leave no replacement connector; their configured inventory allowance remains available. Begin/End remain. |
| Hand/history cleanup and draw | After board cleanup, ordinary hand cards discard, unused hand temporaries vanish and history clears. Then resolve victory/defeat, with no next draw, or refresh the next turn and draw normally. Recycle discard when needed; a just-discarded card can reappear. There is no anti-repeat filter. |
| Rejected commands | Do not clear the board, move cards or advance the turn. Technique play/preparation edits alone do not end the turn or trigger a reset. |
| Record separation | Use this version and its own configuration fingerprint. Preserve previous `rc005_v1` records, fingerprints and exposure history; never relabel or pool them as this follow-up. Exact replay creates a separate attempt. |

This is a **focused follow-up, not a matched pair** with `effects/control` or `effects/treatment`: it changes the initial layout and installed-card allocation, leaving more permanent cards eligible for the draw pile. The original variants only compare powered-effect lifetime and retain their known semantics. The six-energy, low-damage enemy still limits production-pressure conclusions. This fixture does not test blocked cells, alternate endpoints/ports, multi-hit, real encounter transfer or mobile use, and does not approve its precise timing for production.

Use the existing neutral protocol: ask for a cleanup/draw prediction, allow free construction before hints, record assistance and exports, then inspect whether the participant can rebuild and finds useful choices in the new hand. Repeated cards are permitted; more edits or time are not evidence of better decisions. Test Cast/Pass and disconnected/temporary cases as focused coverage, preserving separate attempts. One owner and prior exposure limit any preference finding; full RC-006 decisions and the RC-007 contract remain incomplete.

Actual focused validation recorded October9: [71 core checks, zero failures](../output/qa/rc-006-full-reset-checks-20261009-02.log), [11 UI checks, zero failures](../output/qa/rc-006-full-reset-ui-checks-02.log), and [363 regression checks, zero failures](../output/qa/rc-006-full-reset-regression-02.log). The final core count adds 17 negative loader/input-immutability cases; the earlier 54-check log remains historical evidence. All 19 pre-extension variant fingerprints were preserved, including the already-documented B1 help-copy correction in that baseline; earlier recorded hashes/exposure remain historical evidence and are not replaced. These automated checks establish fixture behavior, not human preference. See [dated verification](verification.md) for execution context and scope.

**Human follow-up, after relaunch:** the owner reports, “Yes, clearing is working and new hand also changes.” Attempt `S01-05` uses the version/seed/fingerprint above and contains 43 accepted commands: 38 edits, three techniques and two Casts, with no Pass, restart, lifecycle transition, note or terminal result. Both Casts leave only Begin0/End14, restore one available Split/Join each and clear Undo. The first circuit deals 12 damage for two energy; the second uses a longer route with Shield and deals 12 damage with five shield for three energy. The recorded hands change; Spark UID3 reappears immediately after the second Cast, consistent with repeats being allowed. Different circuits are observed; their difference alone does not establish useful choices.

The [frozen 43-command record](../output/playtests/rc-006/RC006-S01/effects-full_reset-1791509912-592636-attempt43-snapshot.json) has SHA-256 `7a6c9257034b342c4c11c955e195d9a67da84914d98da62863342c81062064c5`. The earlier `S01-04` launch remains opening-only. Keep the report and log findings distinct in [H14–H15 and the session evidence](rc-006-playtest-results.md); no causal benefit, Pass acceptance or matched-comparison result is inferred.

The owner's subsequent H16 report calls rebuilding worthwhile because they also want Begin and End to change positions every turn. This selects a future per-turn endpoint change, including after Cast/Pass, while the played fixture retains fixed endpoints. Do not attribute the report to experience of moving endpoints. H17 subsequently selects random positions with endpoint rotation allowed. The facilitator interpreted rotation as game-chosen protected orientations and built the separate `effects/moving_endpoints` fixture below. H19 corrects that interpretation: the player must be able to use normal Rotate on both endpoints, and random positions may use any two distinct cells, including adjacent cells. The moving fixture's old semantics/version remain preserved. Initial orientation generation, first-turn placement and encounter integration remain open.

## RC-006 moving-endpoint follow-up

The additive **`effects/moving_endpoints`** fixture implements the facilitator's initial interpretation of random positions/rotations for study with version **`rc006_moving_endpoints_v1`**. H19 subsequently corrects its protected endpoints and restricted catalog; preserve this historical fixture and its records. Encounter ID is `rc006_effects_moving_endpoints`, with board ID `rc006_effects_moving_endpoints_board`. Its seed42 configuration fingerprint is `94ea5c516cb6de6f77f55e75c83053e5dfc7849fe1ed2da53d29b90321226512`. The existing `effects/full_reset` stays fixed at Begin0/End14 and retains its version/fingerprint; all 20 prior configuration fingerprints remain unchanged.

```powershell
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant moving_endpoints -Seed 42
```

This fixture retains the full-reset collection, hand, energy, enemy, stock, effect ports and aggregate damage controls. Turn1 deliberately uses only Begin0/End14 at rotation0 so initial construction is comparable to the fixed full-reset fixture. That opening is a study control, not a selected production first-turn rule.

After each accepted **nonterminal Cast or Pass**, clear all nonendpoint pieces and clean up the hand/history exactly as in full-reset. Advance the turn and refresh energy, then choose uniformly from eligible entries in a pinned eight-layout catalog. **Both endpoint positions differ from their own previous positions**; rotations may repeat. Every catalog layout has a validated connecting path with at least one straight rune socket, and every layout has an eligible successor. This provides bounded variety rather than arbitrary board generation, and does not require a Split/Join to connect the endpoints. The game places the endpoints; they remain protected from player placement, erasure, rotation and Undo.

Endpoint selection uses a separate RNG seeded with `seed XOR 0x52434D45`, preserving the existing card RNG stream. Exact replay reseeds both streams and restores the opening. Menu Restart restores the opening while continuing both streams, as recorded lifecycle behavior. A terminal Cast/Pass still clears the nonendpoint board but does not move endpoints, consume endpoint randomness or draw. Rejected commands, preparation edits, techniques and Undo never move endpoints or consume endpoint randomness.

The normalized metadata adds `endpoint_policy: "random_each_turn"` and `endpoint_layouts`, whose eight entries contain `id`, `path`, `begin: {cell, rotation}` and `end: {cell, rotation}`. The versioned catalog participates in validation and the configuration fingerprint. Witness paths are facilitator/audit data: the participant's rules tooltip omits the catalog, while raw Inspect/export retains it for reproduction. See [content validation](content-definitions.md#rc-006-opt-in-moving-endpoint-extension) and [event ordering](combat-presentation.md#rc-006-moving-endpoint-events).

Focused validation completed October9: [77 moving-endpoint core checks](../output/qa/rc-006-moving-endpoint-checks-20261009-02.log), [18 UI/capture checks](../output/qa/rc-006-moving-endpoint-ui-02.log) and [444 regression checks](../output/qa/rc-006-moving-endpoint-regression-02.log), all with zero failures. The [turn2 capture](../output/qa/rc-006-moving-endpoint-turn2-02.png) was visually inspected: only Begin1 facing down and End7 with its input below, three hand cards, disabled Cast and readable text. The Begin glyph now reflects its port orientation. See [dated verification](verification.md) for import and environment warnings. These are automated fixture checks. The subsequent human report and corrective selection are recorded below; do not infer readability or useful routing choices from automated connectivity. Initial orientation generation, first-turn policy and encounter-boundary integration remain incomplete, as do the other RC-006 decisions.


**Human follow-up and correction (H19–H20):** the owner reports, “Yes, the board clear, but I want the begin and end spot can be rotated like normal spot. Then Begin and End spot can be anywhere even if they sit next to each other”. The selection is normal player-controlled Rotate and any two distinct endpoint cells, including adjacent cells. It supersedes the facilitator's H17 interpretation of protected rotations and eight allowed layouts. The report confirms clearing, without reporting enjoyment/readability of moving layouts or explaining the Pass choices.

The [frozen S01-07 record](../output/playtests/rc-006/RC006-S01/effects-moving_endpoints-1791511346-568465250-attempt25-snapshot.json), SHA-256 `d53053bfc710e8356dc31c769b55aeca42ae3e7648060da4b989b6a4fe4ccedb`, contains 25 attempts: 14 accepted (eight edits, one Cast, five Passes) and 11 rejected endpoint Rotate attempts. Cast attempt9 deals six damage for two energy, clears the board and moves Begin0/End14 to Begin1/End7. Attempts10–20 reject five Rotate attempts on Begin1 and six on End7. Five Passes subsequently clear and relocate endpoints, ending at turn7 with player22 HP and enemy30 HP. No techniques, notes, restarts, terminal outcomes or encounter transitions are recorded. S01-06 remains opening-only. The rejected commands corroborate the limitation the owner asks to change; they do not establish frustration or why the owner passed.


## RC-006 free-endpoint follow-up

The separate **`effects/free_endpoints`** fixture uses version **`rc006_free_endpoints_v1`**, encounter ID `rc006_effects_free_endpoints` and board ID `rc006_effects_free_endpoints_board`. It implements H19's clarification: click Begin or End and use the normal **Rotate** button; random positions may be any two distinct cells, including adjacent cells. It retains the full-reset collection, opening hand, energy, enemy, inventory, permanent discard/temporary expiry, straight effect ports and aggregate damage controls. These controls are not additional production selections. Keep the older protected-endpoint `moving_endpoints` fixture and its records unchanged. The seed42 configuration fingerprint is `9c83d6c3c90601b6abbfaaf110ae3195c12f705b2eb23a4ba91d68aade6dd005`; all 21 earlier variant fingerprints are preserved.

```powershell
.\tools\godot.ps1 -Action run -Experiment -Scenario effects -Variant free_endpoints -Seed 42
```

The actual opening samples uniformly from all **240 ordered distinct endpoint pairs**, with independent rotations0–3. Subsequent accepted nonterminal Cast/Pass clears the board/hand/history and chooses uniformly among **211 eligible pairs**, so both endpoints change their own positions. Adjacent positions and endpoint cross-swaps are included. Clicking an endpoint selects it and clears any held tool/card without attempting a replacement. Player Rotate turns the chosen endpoint 90 degrees clockwise and supports ordinary Undo; it does not move a cell, draw cards or consume endpoint randomness. Endpoints cannot be erased, replaced or flipped. Directions can initially point outward or fail to connect; the player can rotate them before constructing a valid route. This does not promise that every untouched random orientation is immediately castable.

Every distinct position pair permits a connecting route after endpoint rotation, including a route with a straight effect socket. Adjacent endpoints can also connect directly when their ports face each other; existing Cast rules allow that zero-effect connection, so the player can instead construct a longer route to include runes. No minimum-distance or forced-effect rule is introduced. The participant's help describes controls without exposing facilitator witness routes.

The endpoint RNG is separate from card draws, seeded with `seed XOR 0x52434D45`. Exact replay reproduces the opening and turn sequence; Menu Restart resamples the opening while continuing both streams. Terminal Cast/Pass clears the nonendpoint board without moving endpoints, drawing or consuming endpoint randomness. Rejected commands, normal edits, techniques and Undo do not randomize endpoints. Initial generation is setup rather than a gameplay event, and the raw record preserves the actual opening in `initial_state`. See [normalized metadata and validation](content-definitions.md#rc-006-opt-in-free-endpoint-extension) and [event ordering](combat-presentation.md#rc-006-free-endpoint-events).

Randomizing the first turn and independently assigning its starting directions are study implementation choices, not additional owner approval of production first-turn generation. H19 selects player rotation and unrestricted distinct position pairs; it does not settle blocked cells, effect shapes, hit semantics, final timing, encounter integration or mobile usability. The manual rotation result below confirms the requested control. Human outcomes for this variant's Cast/Pass transition, rebuilding and adjacent endpoints remain absent; no broader production approval follows from the control confirmation.


Actual focused validation on October9: [74 core checks](../output/qa/rc-006-free-endpoint-checks-20261009-03.log) and [23 UI/capture checks](../output/qa/rc-006-free-endpoint-ui-capture-03.log), all with zero failures. The core checks cover all 240 initial position pairs and 211 eligible successors per pair, with independent connecting-route witnesses including adjacent cells. The final UI check also asserts the Guide gives the manual endpoint Rotate instruction. The [adjacent-endpoint capture](../output/qa/rc-006-free-endpoint-adjacent-03.png) uses seed9 after manual rotation. The [536-check regression run](../output/qa/rc-006-free-endpoint-regression-01.log) passed and preserves all 21 prior fingerprints, including the original moving-endpoint and full-reset versions. These checks do not substitute for human feedback on the corrected controls.


**Manual rotation result (H22–H23):** the owner replies, “Yes it is working.” The [frozen S01-08 record](../output/playtests/rc-006/RC006-S01/effects-free_endpoints-1791512378-674454-attempt07-snapshot.json), SHA-256 `e8a68cf3d9053683ae3659e6003e5184ae25cdd18b1606e7c5b455dae9a0935e`, has seven accepted Rotate commands: three on Begin6 and four on End15. There are no Casts, Passes, Undo, techniques, rejections, notes or lifecycle entries. The record corroborates both endpoint controls. These cells are not adjacent, and no turn ends, so human adjacency/transition/rebuilding outcomes remain untested in this variant. Preserve the earlier H21 opening snapshot separately; it had zero commands and raw SHA-256 `3375c4afe5f6553c409c5270f120274b2b9840187a5f36e7d93ab1e3824240bf`.

The next handoff at that point was **B1, `split_inventory/treatment`, seed42**, allowing a free construction attempt and asking for predicted damage and energy before Cast. The facilitator explicitly explained that this original sample circuit persists between Casts to isolate Split/Join stock. It is not a change to the owner-selected clearing/random-endpoint/player-rotation rules. The subsequent treatment outcome is recorded below; no extra-pair preference is selected from it.


## RC-006 B1 extra-pair human probe

**Treatment result (H25–H26):** the owner supplies a screenshot and reports, “This is what I can build from extra pair. It is working as I expected.” The active `split_inventory/treatment`, seed42, screen shows turn2, enemy18 HP, player37 HP, two installed Splits and two Joins, with forecast18 damage/cost4. This is a retrospective expectation match; no numerical prediction was captured before the Cast, and it does not select two pairs or approve their balance/cost.

The [frozen S01-10 record](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-1791512908-337653853-attempt12-snapshot.json), SHA-256 `330fa3ab71e451ba83c6161dd4316dda4dd1436d3005a5648b7315fe0555b820`, contains 12 accepted commands: ten edits, one Cast and one Conjure technique. The player erases Shield8 and pieces6/7, places Split7 and rotates it, and places Join6. An additional Spark placement at3 breaks connectivity and is undone before the Cast. That Cast deals one aggregate18-damage event for four energy, taking enemy36→18 and player40→37 after retaliation. The powered installed Spark UID3 contributes three times through the two-pair route; cost4 is Spark2 plus two powered Splits at one each. Conjure then creates Free Spark UID8; placement at3 breaks the circuit and is undone. No Pass, rejection, restart, note, encounter transition or terminal result is recorded. The earlier S01-09 launch remains opening-only.

The [owner screenshot](../output/playtests/rc-006/RC006-S01/split_inventory-treatment-owner-screenshot-20261009.png), SHA-256 `2007ab454b3e5d58ab57baef718259a951e8b25f470dbee28ef9c81c73983475`, corroborates the final displayed layout/forecast. No facilitator solution was shown before the free attempt. The achieved route matches the documented Q witness; that match does not prove novelty or coaching. One successful treatment Cast establishes use of the second pair and its observed amplification, without resolving whether it improves choices or should be the production allowance.

**Control result (H28–H29):** the owner subsequently reports, “It work as expected.” The [frozen S01-11 record](../output/playtests/rc-006/RC006-S01/split_inventory-control-1791513150-645708-attempt06-snapshot.json), SHA-256 `83f6cf191f7ced6cebc620189c73e63445eebfef1169b4e2c3be28b0686eb880`, is the original `split_inventory/control` at seed42 and contains six accepted commands: five edits followed by one Cast. Its constructed circuit deals six damage and emits ten shield for four energy; player HP stays40. This is another retrospective expectation match, without a recorded numerical pre-Cast prediction. Both B1 variants have now been played from matched opening scenarios/seeds; initial states differ only in available Split/Join stock (control0/0, treatment1/1, with one pair already installed in both). Their freely constructed final circuits differ. The control audit conserves all eight permanent UIDs across all seven recorded states. Their different damage/shield results alone cannot isolate an allowance benefit.

**Design proposal request (H30, before H31 selection):** the owner asked, “Please think a mechanic for this, i'm thinking of all circuit should be given limited or random somehow.” At that point this requested a finite/random circuit-supply proposal, without approving a fixed one-/two-pair allowance or a specific random rule. The retained-circuit limitation, treatment-first order and retrospective expectation reports remain historical evidence. The resulting concrete proposal was subsequently selected for now in H31 below; that later selection does not turn the old casts into kit balance evidence.


### Provisional random circuit kits (H31)

The owner responds to the concrete three-kit proposal, “Okay, let's keep it like that for now.” **This is the current provisional owner selection**, not an unselected suggestion or a request for another approval. At each playable turn, randomly choose one ten-piece kit, separate from the normal rune hand:

| Kit | Straight | Corner | Split | Join | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 6 | 2 | 1 | 1 | 10 |
| 2 | 4 | 4 | 1 | 1 | 10 |
| 3 | 4 | 2 | 2 | 2 | 10 |

Erasing returns a piece to the current turn's available supply. Each new playable turn receives a new kit; unused or previously installed pieces cannot be carried or banked. The normal rune hand remains separate. These counts are selected starting values and can be tuned after playtesting; they are not a final balance finding. B2 per-cast costs remain unresolved, and no general testing waiver, successful kit playtest or production implementation is claimed. Preserve both historical B1 variants and records unchanged; neither implements this kit rule. Complete the remaining integration and rules in the [pending contract](production-rules-spec.md), retaining [H31 and evidence limits](rc-006-playtest-results.md).
