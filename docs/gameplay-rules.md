# Rune Cast gameplay rules

**October 9, 2026 — implemented production rules; RC-007 complete.** The owner accepted all proposed defaults. This document describes normal gameplay using `data/production_encounter.json`, verified by 1063 core / 333 UI checks and 52 rendered checks, all passing. See the [exact production contract](production-rules-spec.md#october-9-2026--accepted-rc-007-implementation-contract), [decisions](decisions.md) and [verification](verification.md).

## Starting a turn

Every playable turn, including the first and the first turn of the next encounter, begins with exactly one Begin, one End and fourteen empty cells on the 4 by 4 board. There are no blocked cells or prefilled circuits. The starting configuration uses 3 energy and 3 normal card draws per turn, including a shuffled first hand. Supported alternate encounters use their configured energy/draw values.

Begin and End start at any two distinct cells, including adjacent cells. First-turn placement is uniform among all 240 ordered pairs; later turns choose among 211 pairs that move both endpoints from their own old cells, allowing a cross-swap. Each new endpoint independently starts at rotation 0–3, so a port may initially face off-board. The player selects an endpoint and uses Rotate or Undo normally. Endpoints cannot be erased, overwritten, dragged or flipped; clicking one with a placement tool/card safely selects it.

Each turn receives one random ten-piece connector kit, separate from rune cards. All three currently have equal probability; repeats are allowed.

| Kit | Straight | Corner | Split | Join |
| --- | --- | --- | --- | --- |
| Extra straights | 6 | 2 | 1 | 1 |
| Extra corners | 4 | 4 | 1 | 1 |
| Extra branches | 4 | 2 | 2 | 2 |

New stock replaces the previous kit without banking unused pieces. Counts and probabilities are provisional balance values, not a claim that the three kits are equally useful.

## Construction and ownership

Pieces have directional input/output ports and connect orthogonally. Each cell holds one piece; paths cannot cross inside a cell. Rotate turns ports clockwise. Straight and Corner wires also support Flip. Effect runes have straight ports only.

Placement, rotation, Flip, replacement and erasure cost no energy. All installed connectors, including disconnected ones, reserve their own type's stock. Erase/replacement returns the displaced connector; installing a rune over a wire returns that wire to stock. Exhausted placement fails without changing the board or resources. Rotation/Flip do not change inventory. Stock labels show available and total amounts for all four types.

Replacing/erasing an installed rune returns that same card instance to hand. It does not create a free connector. Undo restores board, hand and stock; it cannot cross a committed technique or turn boundary. Playing a technique clears previous edit history because it can reveal cards.

A permanent card instance exists exactly once in hand, draw pile, discard or installed board. Splitting a signal never creates another owned card or charges the physical rune twice. Generated temporary runes are outside the permanent collection and never enter draw/discard piles.

## Validity and costs

A Cast is valid when every outgoing connection reachable from Begin matches the next piece's input and ultimately reaches End. A reachable Join needs both inputs powered. Directed loops are invalid. Disconnected pieces do not affect damage or cost, but still count against stock and are cleared at turn end.

There is no minimum route length or mandatory effect rune. Directly facing adjacent endpoints can form a valid zero-damage Cast. Invalid, unaffordable or terminal Cast attempts do not pay, clear, draw or reroll.

Each powered physical effect rune pays its defined casting cost once. Each powered physical Split costs 1 energy; Join and ordinary wires cost zero. Techniques spend from the same turn's energy pool immediately.

## Cards and spell evaluation

The starting permanent collection contains two copies each of Spark, Shield, Focus and Conjure Spark. The first hand is drawn normally from the shuffled collection; no curated first hand or guaranteed new card is used in production.

| Name | Kind | Effect | Energy | Timing |
| --- | --- | --- | --- | --- |
| Spark | Installed effect | 6 damage | 2 | On Cast |
| Shield | Installed effect | 5 shield | 1 | On Cast |
| Focus | Technique | Draw 2 | 1 | Immediately from hand |
| Conjure Spark | Technique | Create 1 temporary Free Spark | 0 | Immediately from hand |
| Free Spark | Temporary installed effect | 6 damage | 0 | On Cast |

Begin carries zero damage/shield. Effects add their values. Split sends a copy of the accumulated signal down each branch; Join adds arriving signals; End releases the combined total. The enemy receives one aggregate damage event, including zero. Requested damage and actual HP lost are recorded separately, clamping loss to remaining HP.

If the enemy survives, the spell's shield blocks that attack and remaining damage reduces player HP. A lethal Cast suppresses retaliation. Shield never persists. Techniques resolve explicitly from hand, enter discard if permanent, and do not occupy board cells. Playing to discard is not a new discard-trigger mechanic.

Rune cards keep compact name/symbol/value presentation. Costs and behavior appear in Guide and tooltips; RC-008 still owns the full touch-inspection interaction.

## Cast, Pass and cleanup

An accepted Cast pays once, damages the enemy, then resolves shield/retaliation only if the enemy survives. Pass resolves the enemy attack without a spell or shield, even from an incomplete board or empty hand.

Both actions then clear every non-endpoint cell in ascending cell order. All installed permanent runes, including disconnected ones, enter discard exactly once. Installed temporaries disappear; all Straight/Corner/Split/Join pieces clear. No replacement wire remains. Unplayed permanent hand cards enter discard, unused temporary hand cards disappear, and Undo history clears.

If the battle is terminal, cleanup ends there: no unused next hand, kit, geometry or turn is created. Otherwise the next turn selects endpoints, selects a full new kit, refreshes configured energy and draws normally. Empty draw piles recycle discard; this may immediately redraw a just-discarded card or repeat an entire hand. If both piles are empty, draw fewer cards. Different cards or circuits are a design aim, not a guarantee.

Events describe the already-applied mutations in this order. Presentation replay cannot pay costs, deal damage or apply cleanup again. Victory/defeat prevents further preparation until a supported Restart or victory transition.

## Randomness and encounter entry

Card, endpoint and kit RNG streams are separate. Fresh setup/Exact replay reproduce the same seed and setup. Ordinary Restart restores the selected starting setup while continuing all three streams and advancing presentation generation. Edits, Undo, rejected actions and presentation do not reroll any stream.

A validated compatible next encounter can be entered once after victory. Current/max player HP carries without healing. Permanent UIDs are conserved: collect instances in UID order, clear old zones, shuffle with the continuing card stream and draw using the next configured count. Temporary cards disappear. The next encounter resets turn to 1, energy to its configured amount, shield and Undo; it selects new first-turn endpoints and a new full kit using continuing streams. Invalid, incompatible or repeated transitions leave gameplay/RNG untouched.

RC-007 provides this bounded model/setup contract and a focused two-encounter fixture. Full run progression, rewards, collection changes and saving remain later tasks.

## Historical training and experiments

The old explicit training fixture has a prebuilt circuit, one tutorial Free Spark and curated Spark/Shield/Conjure hand. It delivers 12 damage for 1 energy on its opening Cast, leaving Shadeling at 20 HP and the player at 22 HP. That is historical fixture behavior, not the production opening. The generated tutorial card is not a ninth permanent card.

RC-005/RC-006 experiments remain explicitly opt-in with their original versions, fingerprints and rule alternatives. They may retain circuits, lock endpoints, use blocked cells/corner effects or multiple hits, and use fixture-specific energy. See [circuit experiments](circuit-experiments.md). Those historical settings do not override the accepted production contract. The owner acceptance adds no human balance findings or testing waiver.
