# Rune Cast decisions

## October 12, 2026 — separate Store and permanent rune progression

The owner clarified that the menu's Shop option means a separate **Store**, where players buy in-game items such as runes, perks and relics. Use **Store** for that menu label. A route's **shop room** instead becomes the main screen when entered; the Store is not a shortcut to that room and is not restricted by being in one.

The owner also selected the direction that players can permanently obtain new runes by conquering a map or defeating a hard boss. This supersedes the October 8 proposals for no across-run rune progression, all twelve definitions being eligible from the first run, and Menu Shop opening only an unresolved shop room. Existing run-owned card instances and generated temporary runes retain their separate combat lifecycles.

This establishes intent, not an implemented Store or persistence contract. Store currency/payment, catalogue, availability, purchase ownership and account requirements remain undecided. Which maps/bosses qualify, rewards, duplicates, whether permanent acquisition grants a definition unlock or owned copies, effects on starter/reward/shop pools, and saving/migration also remain undecided. Perks are a Store example, not an authored mechanic or approved content count. No monetization model is inferred. [RC-024A](project-plan.md#phase-4--complete-run-systems) records the design work needed before dependent implementation; shop-room behavior remains RC-029 and navigation remains RC-032.

## October 11, 2026 — official final Combat visual and undirected design

The owner explicitly requested the supplied complete gameplay image become the **official final visual**, expanded the scope to include the crypt and supporting UI, and required no placeholders. [Exact approved image](../output/imagegen/approved/combat-final.png); [accepted visual/interaction contract](gameplay-visual-contract.md).

Accepted changes: circuit connections have no input/output direction; Remove and Rotate are the only visible editing actions; remove Flip, Undo, Inspect, Cancel selection and Details / Pass; show draw/discard piles, detailed cards and the information bar above Cast. The attachment already shows all of these, so its pixels are preserved exactly. This supersedes the prior compact-hand/no-forecast/control requirements as design direction. Runtime changes and undirected branch/cycle/turn behavior verification remain outstanding; the image does not prove implementation. No additional balance, infinite-stock or enemy-rank decision is inferred from illustrative labels.

## October 9, 2026 — complete RC-007 defaults accepted

The owner responded **“Accept all default.”** to the consolidated production-rule proposal. The [accepted RC-007 contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract) is now authoritative for implementation: Split1/Join0 per powered physical piece; normal shuffled first hand and 3-energy/3-draw starting values; straight effect ports; no blocked cells; one aggregate hit including zero with requested/applied damage and lethal suppression; first 240/later 211 endpoint pairs with independent random rotations and separate RNG streams; the explicit cleanup/terminal sequence; and victory-only compatible transfer preserving HP/max HP and permanent UIDs through UID-ordered collection, continued shuffle/draw and fresh endpoints/kit. Previously confirmed full-reset, manual endpoint rotation and equal-probability finite kits remain selected.

RC-007 is implemented and complete: final verification passes 1063 core / 333 UI checks plus 52 rendered checks, with historical records/fixtures preserved. See [verification](verification.md) and the [completed handoff](project-plan.md#october-9-2026--rc-007-production-rules-complete). This owner decision resolves the design gate; it is not a new human-playtest result or a testing waiver. The historical prototype defaults, unanswered-question records and earlier preparation descriptions below retain their chronology and do not override the accepted contract.

## October 9, 2026 — RC-007 reconciliation and independent groundwork

The current request reports RC-006 complete, but no post-H31 decision evidence resolves the remaining production rule choices. The request explicitly reconfirms endpoints-only first and later playable turns, all distinct endpoint positions including adjacency, player Rotate/Undo, normal draws with repeats, and the three equally likely provisional kits. One consolidated question asks the owner to resolve costs/resources, ports, blocked cells, hits, exact endpoint/RNG policies, cleanup/terminal order and remaining encounter-entry state. No answer or testing waiver has been inferred; recommendations remain proposals in the [specification](production-rules-spec.md).

Independent implementation adds validated kit definitions, optional all-four finite inventory, authoritative placement/refund/Undo accounting, accurate UI labels and conditional Guide text. Normal training, experiment versions, fixtures and production rule defaults remain as before pending integration. Automated baseline and final checks are recorded in [verification](verification.md); they are not new human observations. RC-007 remains in progress, and RC-010 remains independently available.

## Explicit direction

- Name: Rune Cast.
- Engine: Godot.
- Platforms: Android and iOS, confirmed October 7, 2026.
- Portrait presentation and a 4 by 4 board.
- Connected Begin and End sockets are required to cast.
- Splitting and rejoining can amplify an attack.
- Strong deckbuilding influence, including generated free runes and hand techniques.
- Hand-painted cartoon art with a Slay the Spire-like encounter presentation.
- Center the full-body enemy and omit the player character.
- Give the encounter substantial vertical room.
- Combat hand cards show cost, name, symbol, type and short effect text, with draw/discard piles (October11 update).
- Keep the information bar above Cast for damage, shield, cost and incoming damage (October11 update).
- Bottom navigation: Menu, Map, Guide, Sound.
- Final visual references for Home, Combat, Map, and Menu approved October 8, 2026; see [visual-reference.md](visual-reference.md). These supersede earlier visual drafts.
- Menu overlay: Resume, Options, Shop, Quit; Quit matches the navy Options and Shop buttons.
- Map uses a branching parchment route without the encounter legend strip.
- Home composition: moonlit tower with Continue, New Run, Options.

## Working defaults used in the foundation

- Godot 4.7.2 Standard, GDScript, Compatibility renderer.
- Three energy per turn and three cards drawn per turn.
- One Split and one Join initially; basic wires unlimited.
- Split costs one energy each cast.
- Editing is free and ordinary installed runes persist.
- Techniques resolve immediately from the hand.
- Temporary runes expire into their straight connector.
- The tutorial starts with a complete circuit and a curated first hand.
- Both branches must complete, joins require both inputs, and loops are invalid.
- A single combined damage total is released at End.
- Replacing an installed rune returns it to hand during preparation.
- A directional wire can be flipped as well as rotated.

These defaults allow playtesting. They are not claims that balance or the full game's rules are final.

## RC-002 proposed release defaults — October 8, 2026

**Historical proposal:** the October 12 decision above supersedes this snapshot's no-persistent-progression and room-gated Menu Shop rows. Keep the original proposals below as dated history, not current requirements.

The owner confirmed RC-001 complete; its checkpoint is `64930fc` (`Initial commit`). RC-002 defines a release proposal in [v1-design-spec.md](v1-design-spec.md) and [content-roster.md](content-roster.md). It does not implement gameplay or confer owner approval on new functional decisions.

| Proposal | Reason and owning task |
| --- | --- |
| Retain the original content budget; default nine rooms inside 8–10 | One loadout/theme, five enemies, four boards, twelve permanent definitions plus Free Spark, six relics/four events/eight single-rank upgrades keeps production bounded. RC-009/RC-034–RC-036 author it; RC-045 measures the 15–25 minute target. |
| Historical Shadeling introductory-normal proposal — superseded October 12 | Reuses the training encounter and first style pilot; simple telegraphed attacks teach circuits. The reference's BOSS label is illustrative. A separate guardian supplies the climax. Preserve `training_shadeling` and existing `shadeling` asset ID. RC-014/RC-034. |
| One local active run; offline English; no persistent power progression | Start each run with the existing eight-card loadout, 30 health, three energy/draw, zero relics/Gold. Gold is run-only. No extra currency/account system. RC-024/RC-036. |
| Interrupted combat replays the committed battle entry | Avoid partial-turn serialization while preserving completed-room progress and seeded offers. Save terminal outcomes and room transactions exactly once. RC-028/RC-047. |
| Menu Quit returns Home and keeps progress | Confirm loss of current battle preparation/replay when relevant. Separate confirmed Abandon action belongs in Map run details. RC-032. |
| Menu Shop is available only in the current unresolved shop room | Preserves route/economy choices and the four approved menu buttons. Elsewhere disabled with explanation; no global or real-money store. RC-029/RC-032. |
| Shared Options and explicit Home save states | Same audio/reduced-motion preferences from Home/Menu; no-save, valid-save and invalid-save states; confirm New Run replacing progress. RC-020/RC-028/RC-032/RC-044. |
| Separate Home tower illustration and in-game logo | RC-015 produces Home art alongside crypt layers, RC-013 produces logo/theme, RC-041 parchment/map art; RC-032/RC-042 integrate. RC-051 handles final distribution identity. Detailed manifest remains RC-010. |

The [external prerequisite register](v1-design-spec.md#external-prerequisites-and-owner-inputs) records unknown Android devices, Mac/Xcode/iOS devices, distribution/signing access, production identity/IDs and human participants with task owners. Unknown access does not block RC-002. Exact OS/device support is selected during RC-021/RC-022, not inferred from the desktop preview. Trailer, translation, extra music/biomes/characters and other expansion features are deferred as specified.

## Questions reserved for RC-005/RC-006

| Decision | Current prototype / outstanding choice |
| --- | --- |
| Persistent versus consumed effect runes | Ordinary effects currently persist; compare cast consumption and its destination without deleting run ownership. |
| Additional Split limits and costs | One Split/Join, Split costs 1 per cast today; extra inventory and costs are undecided. |
| Alternate effect ports and board constraints | Fixed endpoints and straight effect ports, no obstacles today; compare variants and known valid solutions. |
| Single-hit versus multi-hit | One aggregate hit today; no hit-count/targeting/status system is authorized by the roster. |
| Temporary-rune expiry geometry | Installed temporaries become straight wire with current rotation today; alternate-port cleanup needs evidence. |
| Reset versus retain circuit between encounters | No progression today. Reset board/retain collection is an earlier **planned default**, still undecided; compare paired encounters before implementation. |

The [experiment matrix](v1-design-spec.md#experiments-deliberately-left-open) records affected content, evidence and ownership for all six. RC-005 builds controlled scenarios, RC-006 records human evidence and decides, RC-007 implements. Stable roster IDs describe useful roles under either outcome; new effect types and relic hooks require explicit implementation, not JSON alone. Inspection and safe areas are assigned to RC-008/RC-044 and device tasks.

## Changes that need playtesting

The biggest remaining design risk is a standard layout that puts every effect before Split. A split limit controls scaling but does not solve layout repetition. Test varying board obstacles, endpoints, effect ports, and enemy demands before adding more currencies or arbitrary restrictions.


## RC-005 candidates available — October 9, 2026

The [controlled experiment harness](circuit-experiments.md) implements provisional alternatives for all six reserved questions: effect lifetime, extra Split allowance/cost, alternate endpoints/blocked cells/effect ports, damage-hit representation, temporary expiry geometry, and reset/retain transfer. It provides matched seeds, known solutions, local records and a human protocol. These are executable candidates, not owner-approved production rules. All six decisions remain **pending RC-006 human evidence**; automated checks establish behavior and reproducibility only. RC-007 implements subsequent selected rules. Existing normal gameplay defaults remain unchanged.

## RC-006 study preparation — October 9, 2026

**Preparation record, before the owner selection below:** the owner chose “Play the experiments now” and replied “ready” after normal-training practice instructions. Practice completion is participant-reported, not directly observed. Anonymous owner session `RC006-S01` began with `effects/control` seed 42; its initial export had zero commands at that inspection. No production rule had been selected at that preparation stage. See [current attempt evidence](rc-006-playtest-results.md) for subsequent activity.

The [evidence register and session guide](rc-006-playtest-results.md) track all six questions, with Split inventory/cost and endpoints/blocked cells/effect ports assessed separately. The [production specification](production-rules-spec.md) remains incomplete; confirmed choices below are distinguished from evidence-backed selections and any explicit waiver. RC-007 is not ready; RC-010 remains independently available.

## RC-006 owner-directed selection — October 9, 2026

**Confirmed future rules:** start **every turn with only Begin and End**, after each Cast/Pass; send **all installed permanent cards to discard**, including disconnected ones; use a **fresh normal draw, with repeats allowed**. No installed topology or replacement connector carries into the next turn. These owner-directed choices are not matched-playtest findings. Normal production gameplay has not adopted them; the separate [full-reset follow-up](circuit-experiments.md#rc-006-full-reset-follow-up) exercises them for study. They constrain effect lifetime, temporary-expiry geometry and between-encounter topology without settling their entire contracts.

The owner's stated rationale is: “Avoiding repeated casts, since every turn player should have different rune set on hand”. The subsequent clarification was “Fresh normal draw; repeats are allowed (recommended)”. Therefore the selected rule uses ordinary drawing and recycling, **not an anti-repeat guarantee**; a later hand can contain the same card or definition. Card destination and repeat allowance are confirmed and need no further approval.

Split totals/cost, effect ports, the hit model, exact cleanup timing and remaining encounter state are unresolved. The later H19 clarification below selects player-controlled endpoint rotation and random positions at any two distinct cells, including adjacent cells. Initial orientation generation, first-turn policy and encounter integration still need the complete production contract. Literal endpoints-only starts require explicit resolution before blocked cells can be approved. No general testing waiver is recorded. See the [pending implementation contract](production-rules-spec.md) for remaining fields and the [study guide](rc-006-playtest-results.md) for the next focused hands-on comparison/probe.

The owner reports mouse input and “this is my first game created,” which does not establish game-playing familiarity. The initial control attempt contains edits/rejections without a Cast. Later treatment feedback says damage matched the doubling prediction, new cards were drawn, and “board should be clear”; the associated newer record has four commands including two Casts. That treatment report supported the preference for full clearing but did not test the full-reset behavior. First-cast damage was one aggregate 12-damage event, not evidence selecting multiple hits. The [results](rc-006-playtest-results.md) preserve attribution, record references and owner-only desktop limitations.

The additive RC-006 follow-up is `effects/full_reset`, version `rc006_full_reset_v1`. It starts with only endpoints and therefore changes both initial layout and permanent-card allocation relative to the original effects fixtures. Keep its records separate from the original 19 `rc005_v1` variants; their semantics, fingerprints and exposure history remain historical evidence. This study addition does not authorize broader production work or approve its experimental timing as the final contract.

**Full-reset follow-up result:** after the relaunch, the owner reports, “Yes, clearing is working and new hand also changes.” Attempt `S01-05` contains 43 accepted commands and two Casts; each Cast leaves only Begin/End, restores the Split/Join supply and draws normally. The two constructed circuits differ, and the second draw includes an immediate repeat, consistent with the selected rule. This corroborates the reported behavior but does not by itself establish meaningful choice or a causal benefit from resetting. No Pass was played, and no matched comparison is complete. The [frozen record and evidence entries H14–H15](rc-006-playtest-results.md) preserve the report separately from the log.

**Per-turn endpoint direction (H16):** the owner subsequently says, “I think rebuilding is worthwhile because I also want the begin and end spot position change every turn as well”. Record rebuilding as worthwhile by owner report, with a rationale that includes a requested future feature. Begin and End should change positions at each new turn, including after Cast/Pass; this is more than allowing different static encounter boards. At this point, random selection versus a fixed sequence, allowed position pairs, orientations and the first-turn policy were unresolved. The played full-reset fixture keeps Begin0/End14 fixed, so it has not tested moving endpoints or their contribution to enjoyment.

**Random positions and rotation (H17, interpretation corrected by H19):** the owner answers, “Randomly choose but begin and End can also be rotated.” The facilitator initially interpreted rotation as game-chosen orientations with protected endpoints and built `effects/moving_endpoints` around eight validated layouts. That interpretation is historical, not an owner-selected restriction. Random selection was resolved at H17; H19 below clarifies player rotation and the allowed position pairs. Preserve the moving-endpoint fixture's existing version, fingerprint and records.

**Player rotation and unrestricted positions (H19):** the owner now says, “Yes, the board clear, but I want the begin and end spot can be rotated like normal spot. Then Begin and End spot can be anywhere even if they sit next to each other”. Clearing works by owner report. The corrective selection is to let the player select Begin or End and use normal **Rotate**, while random positions can use any two distinct cells, including adjacent cells. Both endpoints still change positions at each new turn. This supersedes the facilitator's protected-rotation/eight-layout interpretation; no further confirmation of those choices is needed. It does not report whether moving layouts were enjoyable or readable, approve blocked cells/effect ports, or settle first-turn generation and encounter integration. The separately versioned [free-endpoint follow-up](circuit-experiments.md#rc-006-free-endpoint-follow-up) is available; normal production gameplay and earlier experimental identities remain unchanged.


**Manual rotation follow-up (H22–H23):** in response to the corrected endpoint-rotation probe, the owner says, “Yes it is working.” S01-08 contains seven accepted Rotate commands: three on Begin6 and four on End15, without Cast, Pass, Undo, technique, rejection, note or lifecycle entry. This corroborates both manual rotation controls. It does not establish human experience of adjacent endpoints, the new variant's turn transition or rebuilding value. See the [frozen record and limitations](circuit-experiments.md#rc-006-free-endpoint-follow-up). The next block at that time was the isolated B1 stock probe; its retained sample circuit was an explicitly explained historical control, not a reversal of the owner's clear-board/endpoint choices.

## RC-006 random circuit kits selected for now — October 9, 2026

After playing both B1 stock variants and reporting each worked as expected, the owner requested a mechanic where circuit pieces are limited or random (H30). The concrete proposal gave ten connector pieces per turn, separately from the normal rune hand, with three possible Straight/Corner/Split/Join kits: **6/2/1/1, 4/4/1/1 and 4/2/2/2**. The owner's response was **“Okay, let's keep it like that for now.”** (H31).

This selects those kits as the current provisional rule, with equal chances as the starting tuning distribution and repeats allowed. A new kit is supplied at each playable turn; pieces are limited within that turn, erase returns installed pieces to available supply, and unused stock cannot accumulate. Split/Join arrive as matched pairs. The selected empty-board/random-endpoint reset and normal rune discard/draw remain intact. No extra economy or reward source is implied.

This is an owner-directed design choice; the earlier one-/two-pair Casts do not test random kits, finite basic connectors or their interaction with moving endpoints. Counts and probabilities remain tunable, with particular uncertainty about whether the second pair dominates extra routing pieces. No further confirmation of this direction is required. B2 costs, other unresolved rule questions and final integration remain open; no testing waiver exists. Normal gameplay and existing experiments do not yet implement these kits. RC-006 stays partial; RC-007 awaits the full contract. See [selection and follow-up](rc-006-playtest-results.md#limited-circuit-kits--selected-for-now-awaiting-implementation) and [stock accounting/acceptance cases](production-rules-spec.md#b--circuit-piece-stock-and-energy).

## October 12, 2026 — Shadeling map-encounter boss correction

Owner direction: Shadeling is a boss for one gameplay encounter on the map. This supersedes the historical RC-002 introductory-normal proposal. The five-actor budget is two normals (Wickling, Stone Sentinel), one elite (Chain Warden), Shadeling as the encounter boss, and Bell Keeper as the proposed final guardian. No sixth actor, extra environment, new phase or automatic permanent reward is implied.

RC-014 remains complete for its recorded asset scope. Reuse its artwork, anchors and isolated scene; follow-up work checks role consistency and only justified refinements. Preserve `shadeling`, `training_shadeling`, existing launch behavior and training/development stats. RC-023 can validate the isolated encounter without making Shadeling the opening/tutorial enemy.

RC-025/RC-034 must settle the designated boss node, board, encounter tuning and node representation, excluding Shadeling from normal random pools. RC-036 must reconcile the earlier room table, Gold arithmetic, rewards and difficulty within the nine-room default and 8–10-room budget. Do not silently add a visit or seventh room family. RC-041/RC-042 must communicate the boss role in map/encounter presentation, distinct from the final guardian. RC-024A determines whether this boss qualifies for permanent acquisition rewards.

This documentation correction does not implement runtime changes or establish new art approval, device results or release rights. Prior verification remains historical evidence. RC-015 remains next numerically.

## October 12, 2026 — Preserve Shadeling pose and consider dodging

Owner feedback: the delivered hit animation reads as dodging instead of getting hit. The owner explicitly directs keeping that pose and recording dodging as a possible mechanic for this boss. This supersedes the earlier description of the current study as readable recoil; it does not require repainting satisfactory art or confer broader art/release/device approval.

Preserve the current `hit` source/export names, common foot anchor, measured r006 mapping, four-state isolated interface and original generation/provenance evidence. RC-014 remains complete. This review adds no animation state and makes no change to the `shadeling` / `training_shadeling` IDs, combat values, training/development fixtures or shared gameplay.

RC-034 owns consideration and adoption of possible boss dodging. No probability, trigger, timing, damage-negation rule, phase or tuning is selected here. Any required framework work belongs to RC-033 after that decision. RC-017 owns event-driven presentation, completion/cancellation, reduced motion and clear actual-hit versus zero-damage feedback; if dodge is adopted, its outcome must also be distinguishable. RC-025/RC-034 retain encounter/node/board ownership, RC-036 retains route/economy/reward reconciliation, and RC-024A determines permanent-reward eligibility.
