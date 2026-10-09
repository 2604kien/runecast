# Production rules specification

## October 9, 2026 — accepted RC-007 implementation contract

**RC-007 is complete. The owner accepted the complete defaults with “Accept all default.” and the implemented production behavior passes final verification.** This dated contract supersedes the pending choices and proposals preserved below. Acceptance is an owner design decision, not a new human-playtest finding or a testing waiver. The existing reported observations and their limitations remain unchanged.

### Playable turn entry and finite supply

Every playable turn, including turn 1 and a subsequent encounter's turn 1, has exactly one Begin, one End and fourteen empty cells. No blocked cells, installed effects, wires, Split or Join are prefilled. The normal starting configuration remains 3 energy and 3 cards drawn per turn; its first hand is a normal draw from the shuffled permanent collection, not a curated tutorial hand. No repeat avoidance or useful-hand reroll is applied. Configuration retains explicit energy/draw values for supported alternate encounters.

Select one of the three ten-piece kits with equal probability at each playable turn entry: Straight/Corner/Split/Join **6/2/1/1**, **4/4/1/1** or **4/2/2/2**. Repeats are allowed and counts/probabilities remain provisional tuning values. A new kit replaces the preceding kit without banking. Rune ownership and connector stock are separate. Installed connectors, including disconnected ones, reserve their own type's stock; erase/replacement returns displaced pieces; rune-over-wire installation returns the wire. Rotation/Flip cannot change stock. Undo restores board, hand and stock consistently without rerolling. Exhausted placement rejects without gameplay mutation. Erasing a rune returns its owned card to hand and cannot create a connector.

### Geometry, costs and damage

The first pair is uniform among all **240 ordered distinct-cell pairs** on the 4×4 board. Later playable turns select uniformly among the **211** pairs moving both endpoints away from their own previous cells; cross-swaps are allowed. Adjacent, edge and corner positions remain eligible. Each newly generated endpoint independently receives rotation **0–3**, including outward directions. Players can select and Rotate endpoints clockwise through the normal control and Undo those rotations. Endpoints cannot be erased, replaced, dragged or flipped. Selecting one while holding a placement tool/card selects it safely. No minimum route length or required effect rune is introduced; a directly connected adjacent pair may cast zero damage.

Effect runes use **straight ports only**, with normal rotation. Ordinary wires remain directional Straight/Corner shapes with Rotate and Flip. Existing validity rules remain: reachable outputs must connect, every powered Join needs all inputs, and directed loops are invalid. Disconnected pieces have no spell effect/cost but remain subject to stock and cleanup.

Each powered physical Split costs **1 energy** per Cast; Join and ordinary wires cost **0**. Each powered physical effect rune pays its defined cost exactly once, even when Split amplifies its contribution. Unaffordable/invalid Cast rejects without spending, cleanup, redraw or random selection. Techniques keep their explicit immediate effect/payment rules and existing Undo boundary.

End resolves **one aggregate damage event, including zero damage**. Its requested amount is distinct from actual HP loss clamped to remaining enemy HP. Lethal damage suppresses shield/retaliation; otherwise the cast's aggregate shield blocks that enemy attack, and excess damage is clamped to remaining player HP. Shield is transient and never carries into the next turn/encounter. Pass has no spell, cost, enemy-damage or shield event; it resolves the enemy attack without shield. No multi-hit, armor, on-hit, status or multiple-target system is added.

### Action cleanup, event and terminal boundaries

An accepted Cast resolves in this order: **pay once → aggregate enemy damage → surviving-enemy shield/attack → board cleanup in ascending cell order → hand cleanup and Undo clearing → terminal outcome or next playable turn**. Pass resolves its no-shield enemy attack, then uses the identical cleanup/terminal path. Events describe actual mutations at their position in this order; presentation replay cannot apply them again.

Board cleanup visits every non-endpoint cell, including disconnected pieces. Each installed permanent UID enters discard exactly once; installed temporary runes disappear without entering permanent ownership or piles; every ordinary wire/Split/Join clears. Amplification cannot move an instance twice. Then unplayed permanent hand cards enter discard in hand order, unused temporary hand cards disappear, and Undo clears. Normal draw/discard recycling may immediately redraw cards discarded by the same action; fewer cards are drawn only if both piles are exhausted. No card/circuit novelty is guaranteed.

After nonterminal cleanup, choose the new endpoints, then the new kit, refresh configured energy and draw normally for the next turn. Terminal cleanup ends the battle without an unused hand, kit or next-turn endpoint selection; it does not start a new turn. Rejected or duplicate terminal commands cannot clear, pay, draw or reroll. Existing action/generation/sequence identities, busy-input guards and stale-completion protection remain authoritative.

### Randomness, Restart and encounter entry

Card, endpoint and kit RNG streams are independent. Fresh setup and Exact replay reproduce from the same validated setup/seed; ordinary Restart restores that setup while **continuing all three streams**. Edits, rejected commands, Undo, rendering and presentation playback never advance those streams. Endpoint rotations do not perturb future positions; kit selection does not perturb card draws or endpoint selection. Exact seed derivations and API fields are documented below.

Allow one validated transition from a won encounter into a compatible next encounter. Carry current/max player HP without healing and preserve every permanent UID exactly once. Collect all permanent instances in **ascending UID order**, clear their old zones, shuffle with the continuing card stream and draw normally using the next encounter's configured draw count. Delete all temporary instances. Reset turn to 1, energy to the next configured value, shield/transient state and Undo; initialize new random endpoints from the full first-turn domain and one new full kit using continuing streams. No old topology or stock carries. The enemy begins with its next encounter definition's health and intent sequence.

Reject incompatible, premature, terminal-defeat or repeated transitions before reconciliation; a failed transition cannot lose/duplicate cards, heal, consume RNG or replace state. A successful transition advances presentation generation and cannot be replayed to apply transfer twice. Full tower/map/reward/save progression is outside RC-007; provide the model/setup boundary and a focused compatible encounter fixture.

### Implementation profile and event identities

Use production profile **`rc007_production_v1`**, separately from historical experiment metadata. Expose detached `snapshot.production` options and `snapshot.kit` with `{id, totals, weight}`. Seed the card RNG with the setup seed, the endpoint RNG with `seed XOR 0x52434D45` and the kit RNG with `seed XOR 0x52434B49`. First setup and Restart use the 240-pair opening domain; nonterminal next turns use the 211-pair successor domain. Restart continues all streams while incrementing presentation generation; fresh setup/Exact replay reseed and reset instance identities with old-controller disposal/cancellation protection.

Initial setup deals/selects resources without emitting an action event batch. At ordinary playable turn entry after cleanup, emit endpoint change, then `kit_changed` with detached `before`/`after` kit values, then `turn_started`, then actual draw events, each after its described mutation. The kit is fully available on first-turn entry. Transition increments generation before emitting its events so stale callbacks cannot unlock or mutate the successor.

Encounter entry emits one `encounter_transition` with mode `production_reset`, prior/new encounter and content identities, carried HP/max HP, boards, kits/stock, energy/turn, prior zones, UID-ordered permanents and the new shuffled draw pile with empty hand/discard; actual draw events follow. It does not emit separate initial endpoint/kit events. The [combat/presentation contract](combat-presentation.md) details the detached payloads and playback safeguards.

The bounded transfer fixture uses optional prevalidated, cached `setup.next_encounter`, consumed through a no-arguments `next_encounter` command after victory. Support exactly one successor; reject nested successors, incompatible catalogs/ownership and repeated transition before mutation. Carry player maximum/current HP even if the successor's authored starting/max HP differs; use the successor's configured energy and draw values. Collect instances in UID order before the continued shuffle. The later run-state tasks own unrestricted progression, acquisitions and persistence.

Normal launch selects `data/production_encounter.json`, retaining stable `training_shadeling`, `board_training` and `starter` IDs. Explicit `data/encounter.json` preserves the old training opening; separate production board/loadout documents avoid rewriting the historical content/fixtures. Production loadouts omit authored connector inventory: runtime derives it solely from the selected kit. Opening draw equals configured `draw_per_turn`, drawing fewer only when the permanent pool is smaller. The bounded `production_transition_encounter.json` → `production_next_encounter.json` fixture uses Shadeling at 32 HP then the existing development Wisp at 45 HP, with next energy 4/draw 2; player current/max HP carries rather than adopting the development loadout's authored 24/40 values.

### Final verification and tuning limits

The accepted choices, implementation and documentation now agree. The fresh integration baseline passed **926 core / 289 UI** checks; final [core](../output/qa/rc-007/implementation/final-test.log) and [UI](../output/qa/rc-007/implementation/final-smoke-02.log) checks passed **1063 / 333**, all zero failures. A rendered actual-scene run passed [52 checks / 0 failures](../output/qa/rc-007/production-ui-implementation-04.log), with eight inspected captures covering opening, Guide, construction, next turn, adjacency, victory, defeat and encounter entry; the separate [final production capture](../output/qa/rc-007/implementation/final-production.png) also succeeded. Pinned Godot version/import/test/smoke/capture actions were run separately.

The [geometry test](../tests/connector_geometry_tests.gd) now uses the actual production model with one explicitly supplied Spark and naturally selected seeds for each kit. All **240 endpoint pairs × 3 kits = 720** cases pass, including 48 ordered adjacencies per kit; core coverage also checks endpoint rotations across all 240 pairs and all 48 direct adjacent zero-damage connections. This establishes bounded geometry and mechanics, not useful random hands or affordability. The [preservation audit](../output/qa/rc-007/implementation/preservation-results.json) confirms **193** prior evidence/asset files and all **22** historical fixture fingerprints unchanged.

The first final UI run had one historical endpoint-feedback regression; production-only feedback fixed it and the final rerun passed. Independent review found a lethal-Cast tooltip showing retaliation; that display now reports zero and is regression-tested. [Verification](verification.md) preserves these intermediate results, final logs and the Android build-tools warning separately. No new human or physical-device findings are claimed. Kit balance, rebuilding quality and arbitrary-position play remain later human-test/tuning work; owner acceptance does not invent those outcomes. No Git operations occurred in the final implementation phase; the earlier initial read-only status exception remains disclosed in the handoff.

## Historical proposal and preparation — before owner acceptance

## October 9, 2026 — RC-007 reconciliation

**RC-007 is partial: independent preparation is verified; final integration remains pending owner answers.** The implementation request reports RC-006 complete. A review of this specification, the study results, decisions and latest project handoff found no newer recorded owner decisions after H31 that resolve the remaining rule choices. The completion report alone does not select them. The current request explicitly confirms endpoints-only starts on the first playable turn as well as later turns, random distinct endpoint cells, and equal initial probabilities for the three selected kits; those directions need no reconfirmation.

Seven policy families await one consolidated owner answer: per-cast Split/Join costs; effect ports; aggregate or multiple-hit damage; blocked cells; exact endpoint orientation, selection and RNG policies; cleanup/event ordering and terminal behavior; and remaining encounter-entry ownership, health, hand/piles and RNG rules. Recommended defaults and existing experimental implementations are proposals, not accepted production choices. A precise final contract must precede dependent integration.

### Proposed contract awaiting owner answer

The following is the consolidated proposal presented to the owner, **not selected rules or playtest evidence**. Dependent implementation waits for an answer; elapsed time does not accept these defaults. Already confirmed reset, rotation and kit choices are not being reopened.

| Remaining choice | Recommended contract awaiting confirmation |
| --- | --- |
| Costs and opening hand | Each powered physical Split costs **1** energy per Cast; Join costs **0**. Retain **3 energy / 3 cards drawn** per turn. The first hand is a normal draw from the shuffled permanent collection. |
| Effect ports | **Straight effects only**; retain normal rotation. |
| Blocked cells | **None**, preserving exactly fourteen empty cells at playable turn entry. |
| Damage and shield | **One aggregate damage event, including zero**; record requested damage separately from applied HP loss. Lethal damage suppresses retaliation; shield applies only to the surviving enemy's attack. |
| Endpoints and RNG | First pair uniform among all **240** ordered distinct-cell pairs; later turns among **211** pairs moving both endpoints from their own prior cells, with cross-swaps allowed. Initial rotations are independent **0–3**, including outward ports. Card, endpoint and kit RNG streams are independent. Fresh setup/Exact replay reseed; ordinary Restart continues the streams. |
| Cleanup and terminal order | Pay → damage → surviving-enemy shield/attack → board cleanup in ascending cell order → hand cleanup and Undo clearing → terminal outcome **or** new endpoints, kit, energy refresh and normal draw. Terminal cleanup creates no unused hand, kit or next-turn geometry. |
| Encounter entry | Allow one validated transition after victory. Carry current/max HP and every permanent UID; collect permanent instances in UID order, shuffle and draw normally. Use the next encounter's configured energy/draw, fresh endpoints and kit, and continued RNG streams. Reject incompatible or repeated transitions; no implicit healing. |

### Verified independent preparation

Independent preparation now includes validated [production kit definitions](../data/production_rules.json), the [kit validator/selection helper](../scripts/core/production_rules.gd), optional finite inventory for all four connector types, and model/UI accounting. Each kit has its selected ten pieces and equal weight 1; returned rule/kit data is detached. Selection takes an explicitly supplied RNG, but no production seed, stream lifetime or turn-entry call site is chosen. Finite setup validation requires Straight and Corner totals together; installation, replacement, erasure, rotation, Flip and Undo preserve the configured per-kind totals. Snapshots, stock labels/tooltips and conditional Guide text expose finite quantities when configured. QA exports/captures use separate unique destinations.

**Normal gameplay has not adopted production turn rules.** Its historical prefilled opening, unlimited basic connectors, cleanup, endpoint policy and RNG behavior remain unchanged. The new helper is not wired into production turn/encounter setup; kit cadence, no-banking integration, full reset and the seven pending policy families still require the finalized contract. Existing experiments keep their historical behavior. No human observation or testing waiver is added.

Fresh verification passed with pinned Godot 4.7.2: baseline **737 core / 247 UI**, final **926 core / 289 UI**, all zero failures. The [geometry checks](../tests/connector_geometry_tests.gd) construct a supplied straight-Spark route through normal placement/Rotate/Flip for all **720 endpoint-pair/kit combinations**, including all 48 ordered adjacent pairs per kit, and verify finite stock exhaustion/returns. This is geometric feasibility with an explicitly supplied rune, not proof of affordable or useful random hands. The final rendered finite-stock fixture passed **43 checks / 0 failures**, including Guide text. The baseline/final training and finite-stock captures were inspected; baseline/final training are pixel-identical. All 98 audited prior evidence/asset files and 22 historical fixture fingerprints remain unchanged. Exact logs, image hashes, environment warnings and the Git restriction exception are recorded in [verification](verification.md) and the [RC-007 handoff](project-plan.md#october-9-2026--rc-007-reconciliation-and-independent-preparation). The historical selection snapshot below is preserved.

## RC-006 selection snapshot before this reconciliation

October 9, 2026. **PARTIALLY SELECTED / NOT READY FOR RC-007 IMPLEMENTATION.** Selected: endpoints-only starts after Cast/Pass, installed permanents to discard, normal draws with repeats allowed, random player-rotatable endpoints at any distinct cells, and the three random ten-piece circuit kits. H31 accepts the kits for now; balance/integration remain untested. Seven recorded rotations corroborate the corrected controls, while two earlier full-reset Casts support clearing/changed hands and rebuilding was reported worthwhile. No testing waiver exists. Other rules and final integration remain unresolved; [results and evidence](rc-006-playtest-results.md) retain their limits.

Current normal runtime remains defined by [gameplay rules](gameplay-rules.md), [content definitions](content-definitions.md) and [combat/presentation](combat-presentation.md). Exact provisional alternatives remain in [circuit experiments](circuit-experiments.md). The additive RC-006 `effects/full_reset` fixture now exercises the selected reset/discard/draw subset; this does not implement it in normal gameplay or approve its other fixture values for production. RC-010 remains independently available.

## Selection register

| Rule | Selection | Evidence / owner decision | Readiness |
| --- | --- | --- | --- |
| A: effect lifetime | SELECTED: every turn begins with only Begin/End; all installed permanents, powered or disconnected, enter discard after Cast/Pass; normal draws may repeat cards | Owner confirmations H03/H05/H06; full-reset Cast records/report H14/H15; worthwhile rebuilding H16, October9 | Two-turn evidence supports clearing/draw; detailed integration and relocation timing remain to finalize |
| B1: circuit-piece supply | SELECTED for now: random ten-piece kits, Straight/Corner/Split/Join6/2/1/1,4/4/1/1,4/2/2/2; no banking | H31 accepts the concrete proposal after H25–H29 stock play and H30 design request | Owner-directed provisional selection; kit balance/integration untested, values tunable; B2 remains separate |
| B2: per-cast costs | PENDING uniform Split1 versus Split2; Join cost explicit | None yet | Six-energy fixture is not production balance |
| C1: endpoints | SELECTED: random positions each turn across any two distinct cells, including adjacency; player-operated Rotate with normal Undo. Final integration/first-turn policy PENDING | H16/H17 clarified by H19; H22/H23 confirm manual Rotate, October9 | New free-endpoint test implements the corrected direction; human rotation works, but adjacency and repeated reconstruction are not human-tested in that variant |
| C2: blocked cells | PENDING compatibility with literal endpoints-only rule; no terrain exception approved | H03 does not authorize preserving obstacles | Do not silently retain fixed blocked cells; resolve any exception explicitly |
| C3: effect ports | PENDING straight-only versus corner support | None yet | Must coordinate with A/E/F |
| D: hits | PENDING aggregate versus ordered contributions | None yet | Single enemy; no speculative status/target system |
| E: temporary expiry | SELECTED at turn entry: empty cells, no replacement connectors; detailed cleanup pending | Consequence of H03; H15 records powered temporary deletion on both Casts, H14 confirms clearing | Expiry on Pass with installed temporaries, disconnected/unused-hand expiry and terminal cases have automated coverage only; final timing still needs exact contract |
| F: encounter transfer | SELECTED topology: endpoints-only on first turn too; no installed circuit retained | Consequence of owner-confirmed H03 | Health, card pool, inventory, energy, RNG and new-board setup pending |

## Confirmed owner direction — October 9

The owner said the player should start with “an empty rune board with only end and beginning spot in it,” then clarified **“At the start of every turn, after each Cast or Pass.”** The stated aim is for players to arrange the circuits themselves. This applies to the first turn as well as subsequent turns; no production prefill or tutorial exception has been selected. Existing historical training/experiment fixtures stay intact during RC-006.

At playable turn entry, there must be exactly one Begin and one End at that turn's selected cells/orientations and fourteen empty cells. Ordinary wires, Split/Join and all installed effects, including disconnected ones, cannot remain from the prior turn. Ordinary connector orientations do not carry. Clearing stock pieces restores availability within selected totals, never creates extra stock. All installed permanent cards move to discard, conserving each owned instance. Temporary runes disappear instead of entering permanent piles.

The owner selected **“Discard pile, available through later draws”**, with rationale **“Avoiding repeated casts, since every turn player should have different rune set on hand.”** They clarified **“Fresh normal draw; repeats are allowed.”** Thus the next hand uses normal draw/discard recycling, with no forced novelty, exclusion of previous cards or anti-repeat rerolls. A different hand and a different circuit are design aims, not guaranteed outcomes. The configured draw count is not changed by this choice.

The owner reported clearing/changed hands and worthwhile rebuilding, and requested random endpoint movement with rotation. The facilitator initially interpreted rotation as game-selected and protected during construction. The owner corrected that interpretation: **“I want the begin and end spot can be rotated like normal spot”** and **“Begin and End spot can be anywhere even if they sit next to each other.”** H19 supersedes that facilitator interpretation and the eight-arrangement restriction. The player can select either endpoint and Rotate it in90-degree steps, including temporarily outward-facing directions; the next turn randomly relocates both endpoints. Erasing/replacing/dragging endpoints is not selected. H22 says the correction works, and H23 records three Begin rotations and four End rotations. No Cast/Pass or adjacency outcome exists yet in that new human record.

The owner subsequently accepts the three random ten-piece kits in B below: “Okay, let's keep it like that for now.” This settles the current supply direction and prototype counts without selecting per-cast costs, hit representation or effect ports. Endpoint position eligibility includes every distinct-cell pair; exact initial orientation/first-turn and integration policies remain in the final contract. Fixed blocked cells would conflict with the literal fourteen-empty-cell rule; any terrain exception requires an explicit owner amendment. Automatic clearing, relocation and manual endpoint rotation exist only in separate RC-006 follow-ups; the kits are not implemented there or in normal gameplay.

### Experimental implementation of the selected subset

`effects/full_reset`, version `rc006_full_reset_v1`, seed42 fingerprint `9d979d1f087bced1b8d252ad2b07b78a690345c6d4bf9710e6d06d01680217ab`, implements the proposed A/E integration order below for study. Its initial state is endpoints-only; no production prefill is introduced. Terminal Cast/Pass clears without drawing, rejected actions preserve state, and ordinary draws may recycle just-discarded cards. S01-05 records two Casts that clear every installed piece, expire a powered temporary, discard installed permanents, clear Undo and draw three cards. The owner confirms visible clearing and changed hands; the second route includes Shield and differs from the first. Spark3 is immediately redrawn after the second Cast, as permitted. See [study results](rc-006-playtest-results.md) for the preserved record and limitations. Pass, disconnected-piece and terminal coverage remains automated only.

This fixture retains six energy, low repeated enemy damage, one Split/Join, straight effect ports, fixed endpoints and aggregate hits. It does not select those production values or provide a second encounter. Different initial geometry and card allocation prevent pooling it as the old matched pair. RC-007 still waits for the full rule contract and owner decisions; implementing an opt-in candidate is not completing RC-007.

The historical `effects/moving_endpoints` fixture, version `rc006_moving_endpoints_v1`, fingerprint `94ea5c516cb6de6f77f55e75c83053e5dfc7849fe1ed2da53d29b90321226512`, retains its eight-layout catalog and protected rotations. S01-07 records one Cast, five empty-board Passes and eleven rejected endpoint rotations, corroborating the mismatch H19 identified. Preserve this fixture and its records without treating it as the selected manual-rotation behavior.

The corrected `effects/free_endpoints` fixture, version `rc006_free_endpoints_v1`, seed42 fingerprint `9c83d6c3c90601b6abbfaaf110ae3195c12f705b2eb23a4ba91d68aade6dd005`, selects uniformly among all240 ordered distinct-cell pairs initially, then211 eligible pairs that change both endpoints' own positions on later turns. Swapping their previous cells is allowed. Initial orientations are independent0–3, may face off-board, and can be changed by normal Rotate/Undo. Every positional pair can support a rune-bearing path after orientation/building; the generated directions need not already connect. Initial random placement is recorded in the initial state. Endpoint/card RNG streams stay separate; Exact replay reseeds both, ordinary Restart continues both and selects a fresh opening. Cleanup precedes the later-turn relocation event, next-turn event and draw. Terminal/rejected actions do not relocate. This is the candidate integration policy, not blanket approval of all remaining production rules.

## Contract to finalize after selections

### A — Effect lifetime and resolution

Selected: both powered and disconnected permanent effects move from the board to discard, and every non-endpoint piece clears, before the next turn begins after accepted Cast or Pass. No matching connector survives. Each physical UID moves exactly once regardless of amplification. There is no guaranteed direct return to hand: subsequent availability comes from ordinary draw/discard recycling. Repeats are explicitly permitted.

Recommended integration order for the final six-question contract: pay and resolve the accepted action, damage, surviving-enemy shield/retaliation, then clear non-endpoint cells in ascending cell order, appending each permanent card to discard once and deleting temporaries; restore stock availability. Perform normal old-hand cleanup (discard unplayed permanents, delete unused temporaries) and clear Undo, then terminal outcome or energy refresh/normal draw. C1 relocation must be integrated before another playable turn begins, with its position/rotation/RNG/event order explicitly specified before implementation. If drawing exhausts the draw pile, newly discarded cards may be reshuffled and immediately drawn again; no special delay is proposed. Rejected actions must not clear/pay/mutate. Recommend terminal cleanup too, without starting another turn/draw or selecting unused next-turn endpoints. H15 supports ordinary nonterminal Cast cleanup/recycling; remaining boundaries and relocation are proposals for the final contract.

Acceptance cases implied by the selected direction, with unresolved fields identified:

- Production turn1 has only configured Begin/End; the player builds a circuit. No effect, wire or special piece is preinstalled.
- Given P as a pre-Cast player construction, cleanup removes Spark1 **and** disconnected Shield8 and every wire/Split/Join. The next turn contains only its newly selected Begin/End; no previous connector/effect survives, including where a new endpoint is placed. Each installed permanent UID enters discard once at cleanup; later draw/recycle may move it again. At every boundary each occurs in exactly one ownership zone.
- Pass from a valid or invalid construction also leads to endpoints-only next turn. Split/Join stock is fully available up to selected totals; Undo cannot restore the prior turn's circuit.
- Split amplification cannot move/pay a physical effect twice. Reject an unaffordable/invalid Cast without clearing the board. Under the proposed ordering, terminal turns perform discard/clear without a new draw; finish exact event assertions with the final integration contract.
- With an empty draw pile and permanent cards in discard, perform ordinary reshuffle/draw. Previously installed or drawn card IDs may recur, even the same hand composition if the available pool produces it. Do not reroll or insert a new card to force novelty.

### B — Circuit-piece stock and energy

The current kit totals are selected independently from cost. Per-powered-Split and Join cast costs, affordability after techniques and production energy pressure remain B2 decisions. Installed pieces, including disconnected ones, reserve their kit stock; no acquisitions through rewards or relics are implied. State any departure from tested uniform per-Split costs as an owner preference or follow-up requirement.

H25–H29 add actual B1 play: two-pair construction produced18 damage/cost4; one-pair construction produced6 damage and10 shield/cost4. Initial states match except stock, but chosen rune placements differ; these totals do not rank allowance or isolate its power. Both reports were retrospective, without numeric pre-Cast predictions. H30 broadens the question to finite/random supply; H31 accepts the proposed kits as the current rule, with tuning still open.

**Selected for now (H31):** give ten connector pieces per playable turn, choosing uniformly as the initial tuning distribution among `(Straight6, Corner2, Split1, Join1)`, `(4,4,1,1)` and `(4,2,2,2)`, separately from the normal rune hand. Repeats allowed; endpoint placement/rotation stays as selected. Place reserves stock, erase/replacement returns stock, Undo restores it, disconnected pieces count, and unused stock cannot accumulate. Installing a rune returns any displaced basic wire to the kit; installed permanents still enter discard at cleanup. No additional confirmation of this direction is required. Counts/probabilities can be revised through later playtesting.

Recommended integration contract: select a new kit only at playable turn entry, including the first turn, with its own replayable RNG stream, after any preceding cleanup; rejected actions, edits and Undo must not reroll it or alter subsequent rune/endpoint randomness. Terminal cleanup does not draw an unused kit. Exact replay/Restart and encounter-boundary RNG behavior must be pinned in any new fixture and final contract. Kit selection replaces old supply, rather than adding to it.

The common four Straights/two Corners supports a rune-bearing route for every distinct endpoint pair on the empty4×4 board after manual rotation; this is a geometry check, not proof of affordable/useful hands. Equal piece counts do not imply balanced power. See the [selection and smallest follow-up](rc-006-playtest-results.md#limited-circuit-kits--selected-for-now-awaiting-implementation). Existing B1 records cannot validate this combined mechanic. Keep B2 costs independent; implementation belongs to RC-007.

Kit acceptance cases: each new kit has exactly ten pieces with its selected per-kind totals; available plus installed stock equals those totals throughout editing. Exhaustion rejects another same-kind piece without mutation. Erase/replacement/Undo returns or reserves exactly the affected pieces, including disconnected ones, without creating free connectors from rune geometry. Removing a rune cannot increase kit totals. After Cast/Pass, the next turn has only endpoints and its new full kit; unspent or returned old pieces do not increase it. Identical replay reproduces kits independently of editing and rune draws. These are future acceptance cases, not checks already passed by normal gameplay.

Conditional acceptance: Q uses two powered Splits/two Joins with three Spark contributions, 18 damage. With existing Spark cost2 and Join0, Split1 costs4 and Split2 costs6. At energy5 the former is affordable and latter is rejected without mutation. A second pair is refused under allowance1; installation/erase/Undo conserve selected stock totals. These six-energy experimental examples do not approve production starter energy.

### C — Allowed geometry

**C1 selected direction:** Begin and End change positions randomly every turn, including after Cast or Pass. All240 ordered distinct-cell pairs on the4×4 board are eligible positions, including horizontal/vertical neighbors, corners and edges. Players rotate either endpoint clockwise90 degrees through the ordinary control; normal Undo restores that rotation until an existing history boundary. Rotation changes real input/output ports and may temporarily make the forecast invalid. Endpoints cannot be overwritten, erased or flipped; manual position dragging is not requested.

Candidate integration: randomize the first pair too; on each subsequent playable turn choose uniformly among211 pairs where each endpoint moves from its own old cell, permitting cross-swaps. Use independent0–3 starting rotations and a separate endpoint RNG stream; player rotation/Undo must not advance it or spend energy/cards. Clear and reconcile old cards before occupying new endpoint cells. Reject an invalid Cast without mutation, and do not select an unused layout after terminal cleanup. Include these precise policies in the final owner decision table; the current evidence confirms manual rotation, not repeated-turn usefulness for arbitrary pairs.

Acceptance: all240 positional pairs admit a simple rune-bearing route after endpoint rotation, including neighboring pairs whose useful route detours around the board. Directly facing adjacent endpoints may also form the existing valid zero-damage connection; do not introduce an unselected minimum-path or minimum-rune rule. Erase/replacement/Flip attempts preserve endpoints; Rotate and Undo work on either; four rotations return the original ports. Full reset and relocation clear old Undo history. Replay reproduces positions, directions and cards; arbitrary player rotations cannot alter subsequent randomness. Production geometry must remain buildable after permitted edits, rather than promising that every random starting orientation is already valid.

C2 blocked cells and C3 effect ports remain separate allowed/deferred choices. Define in-bounds ports, obstacle immutability/traversal, shapes per rune definition, rotation and Flip rules. State validation failures and legal board authoring limits. Experimental endpoint/obstacle/port support does not approve all three or arbitrary combinations.

Conditional acceptance: R is the 180-degree rotated P and retains damage/cost/connectivity; a blocked6 rejects edit and traversal without disturbing unrelated cells; corner Spark3 west-in/south-out differs from straight Spark1 west-in/east-out; rotation changes actual connectivity and Undo restores it. Normal form and rendering/evaluation must agree. Revalidate each selected RC-009 layout with actual starter resources.

### D — Bounded damage-hit model

Specify whether End emits one aggregate event or an ordered list. If list-based, define positive/zero contributions, traversal order, Split list duplication, Join parent order, hit count/index, lethal truncation, requested versus applied damage and shield behavior. Keep one enemy; no armor, on-hit, status or targeting system is implied.

Conditional acceptance: P total12 is either aggregate `[12]` or ordered `[6,6]`; against enemy HP5, requested damage and actual clamped loss differ and retaliation is suppressed. For the multi-hit candidate the first6 applies5, remaining hit is skipped, constructed hit_count remains2. Specify zero-damage event expectations explicitly rather than borrowing aggregate behavior accidentally. Check downstream threshold/event consumers once per their selected trigger, not once per UI replay.

### E — Temporary cleanup geometry

Selected turn-entry replacement for every installed temporary is empty, along with all other non-endpoint cells, after accepted Cast/Pass. This includes powered and disconnected temporaries of any permitted shape; no orientation remains on an empty cell. Recommend retaining current unused-hand temporary deletion, permanent-ownership/pile exclusion and history clearing. Set exact terminal/cleanup timing with A. C3 governs what can be built during a turn, not whether a replacement connector survives.

Acceptance: given T as an allowed pre-action construction, temporaries at cells3 and8 disappear after Cast and separately Pass; their cells become empty or hold a newly relocated endpoint. Every cell other than the new endpoints is empty. Under the recommended existing hand-cleanup rule, an unused generated hand temporary vanishes with no connector/pile entry. Undo must not resurrect expired cards or the previous turn's circuit. This is full reconstruction, not repair of a partly retained path. Straight/corner port permission is still pending; T's corner support is experimental only.

### F — Between-encounter transfer

Fill every row with an explicit selected value before implementation:

| State | Required contract |
| --- | --- |
| Eligibility / duplication | Victory/transition trigger, exactly-once reconciliation and invalid/repeated transition behavior |
| Board topology | SELECTED: next encounter's first turn starts endpoints-only, not reset to template connectors or retained topology. Select endpoint geometry; resolve blocked-terrain exception if any |
| Installed permanent cards | None stay installed at next encounter turn entry; turn cleanup sends them to discard. Reconcile the next encounter's card pool once without duplicate/lost UIDs |
| Current/max health | Carry/reset policy; any healing must be explicitly selected, not inferred |
| Temporary board/hand cards | Installed cells empty at next entry; recommend all temporaries deleted, no tutorial temporary silently recreated |
| Hand/draw/discard | Eligible card order, opening-hand policy, unavailable installed IDs, shuffle/recycle behavior and old-zone clearing |
| Inventory | Total allowance carried/reset and available stock recomputed from installed pieces |
| Energy / shield / turn | Exact reset values/source; transient shield handling; new encounter turn identity |
| History / identities | Undo clearing, generation/action IDs and ownership identities |
| RNG | Seed/state continuation versus reset; distinction from Exact replay and ordinary Restart |
| Changed board geometry | Build only next board's selected endpoints at turn entry; no old pieces to relocate. Validate next geometry and conserve all permanent cards; fixed obstacles require an explicit exception |

Acceptance to finalize: on entering encounter2, only that board's Begin/End are installed and there is no prebuilt circuit. Audit current/max HP and permanent collection; specify next hand/piles, temporary deletion and old history/shield handling. Compare every owned UID once across zones; duplicate transition cannot duplicate cards. Harness values energy6/enemy24 are fixture values, not selected production stats. Existing reset/retain trials do not implement this endpoints-only entry and cannot directly validate it. A different endpoint board needs a concrete selected-geometry case before RC-007/RC-009 completion.

## Cross-rule checks and handoff gate

Before RC-007 is ready:

- Link actual human records/notes and owner-confirmed selections (or explicit waiver/design choices) for all six, including B1/B2 and C1/C2/C3. Describe counterevidence, confidence and remaining repetitive-layout risk.
- Keep the confirmed endpoints-only/discard/normal-draw choices; resolve remaining conditional examples, F rows and A/E integration timing. Any recommended follow-up needs its actual result or a labelled owner decision to proceed without it; do not request reconfirmation of H03/H05/H06.
- Check whole-board reset plus chosen ports/expiry/transfer together, especially disconnected installed ownership, new-hand usefulness and changed board geometry. Two full-reset turns support clearing/changed hands, with worthwhile rebuilding reported. The later moving-endpoint record shows relocation and the rejected manual-rotation mismatch; the corrected free-endpoint record confirms manual Rotate only. Repeated rebuilding with arbitrary positions, adjacency and other selected-rule combinations remain unverified by human play. A manual reconstruction probe must be labelled as manual and cannot validate discard/draw timing.
- Synchronize decisions, current-versus-future gameplay docs, design/roster and project handoff without changing historical RC-005 semantics.
- Preserve `board_training`, `board_gallery`, `board_ossuary`, `board_belfry`, `training_shadeling`, `shadeling` and rune IDs. Retain the bounded content budget. RC-009 geometry/solutions and RC-024/026 ownership/transfer, RC-031 hooks, RC-033 hit consumers and RC-035 content must follow selected rules.

RC-006 remains partial until this gate is met. This worksheet alone is not an implementable production specification.
