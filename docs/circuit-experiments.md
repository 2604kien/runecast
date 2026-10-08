# RC-005 circuit experiments

Version `rc005_v1`, October 9, 2026. This is a playable development harness and RC-006 protocol. Every rule below is **provisional experiment behavior**, not an owner-approved or production-final decision. Normal Training Crypt and Calibration Wisp retain their existing rules. There are nine bounded scenarios (19 variants) covering six questions; this is not a combinatorial suite or the final RC-009 board set.

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

All six production decisions remain pending. Automated tests establish executable semantics, conservation, reproducibility and interface behavior; they do not establish enjoyment, comprehension, mobile usability, participant preferences or future balance. RC-006 requires humans; RC-010 remains independently available. Dated commands/counts/screenshots are in [verification](verification.md).
