# Rune Cast gameplay rules

These are the working rules implemented in the foundation. Numerical values and unresolved balance choices remain editable. The decisions document distinguishes explicit user direction from prototype defaults.

## Circuit construction

The board has sixteen cells arranged in four rows and four columns. Begin and End occupy fixed cells. In the training encounter Begin is row 1 column 1 and End is row 4 column 3.

Every piece has input and output ports. Rotation turns them clockwise. Straight and corner wires can also be reversed with Flip. Each cell holds one piece. Connections are orthogonal; paths cannot cross in one cell.

Basic straight and corner wires have unlimited supply and cost no energy. The training loadout owns one Split and one Join. Both remain reusable, but their installed instances are no longer available in the tray. RC-004 permits other validated starting totals; this does not settle the production limits reserved for RC-005/RC-006.

Placing, rotating, reversing, replacing, and removing pieces are free during preparation. Replacing or erasing an effect rune returns it to the hand. Undo restores board and hand changes. Playing a technique commits previous edits and clears undo because it can reveal new cards.

Begin and End cannot be removed or rotated in the prototype.

## Validity

A cast is valid only when every outgoing connection reachable from Begin is matched to the next piece's input and eventually reaches End. Every reachable Join needs both inputs powered. A path feeding into an earlier node is an invalid directed loop.

Disconnected pieces are inactive: they do not contribute effects or energy cost. Disconnected special pieces still occupy the player's inventory allowance.

The cast button is unavailable when the circuit is broken, exceeds remaining energy, or the battle is finished. Menu includes Pass turn so a player without a useful cast can continue.

## Spell evaluation

Runes prepare effects; enemies are not damaged as individual cells are visited.

- Begin starts with zero damage and zero shield.
- Spark adds 6 damage.
- Shield adds 5 shield.
- Split sends an identical copy of its accumulated spell down each outgoing branch.
- Join adds the damage and shield arriving from both branches.
- End releases the combined totals.

Each physical effect rune pays its casting cost once. Each reachable Split adds 1 energy to the casting cost. Join and ordinary wires cost zero.

The prototype applies the final damage total as one damage event. Hit-count interactions, armour, poison timing, and multiple targets are not yet designed.

## Hand and techniques

The training deck has two copies each of Spark, Shield, Focus, and Conjure Spark. The curated first hand is Spark, Shield, and Conjure Spark. The other five cards form a shuffled draw pile.

| Name | Kind | Value | Energy | Timing |
| --- | --- | --- | --- | --- |
| Spark | Installed effect | 6 damage | 2 | On cast |
| Shield | Installed effect | 5 shield | 1 | On cast |
| Focus | Technique | Draw 2 | 1 | Immediately from hand |
| Conjure Spark | Technique | Create 1 temporary Spark | 0 | Immediately from hand |
| Free Spark | Temporary installed effect | 6 damage | 0 | On cast |

Rune choices display only name, symbol, and value. Costs and behaviour are explained in Guide and desktop tooltips. A mobile inspection interaction remains a UI improvement to implement.

Techniques never occupy board cells. Their card goes to discard, their energy cost is paid immediately, and their effect resolves immediately. Playing a card and moving it to discard is not a discard-trigger event. Discard-trigger cards are not in the current starter set.

Normal installed runes remain on the board and are absent from draw/discard piles. Unplayed normal cards enter discard at turn end. Drawing from an empty pile reshuffles discard; if both piles are empty, draw fewer cards.

## Temporary runes

Conjure Spark creates a new temporary rune. A temporary rune costs zero to cast this turn. It disappears after the cast, or when the turn ends unused. It never enters draw or discard piles.

When an installed temporary rune disappears, its cell becomes a straight connector with the same orientation. Other installed pieces remain.

The opening training board includes one temporary free Spark as an explicit tutorial setup. It is not a ninth permanent deck card.

## Turn resolution

1. Begin with the configured energy and opening hand (3 energy in training).
2. Inspect the enemy's intent and prepare freely.
3. Use techniques as desired; they spend from the same energy pool.
4. Cast a valid affordable circuit once.
5. Pay its cost and apply damage to the enemy.
6. If the enemy survives, gain the cast's shield and take the remaining incoming damage.
7. Expire temporary runes and discard unplayed normal cards.
8. If both combatants live, advance the turn, refresh energy and draw the configured number of cards (3 energy and 3 cards in training).

Shield does not persist into the next turn. Lethal damage prevents retaliation. A defeat or victory stops further editing/casting until Restart. Pass turn resolves the enemy attack without a spell or shield, then performs the same cleanup.

## Training encounter

The player begins at 30 health. Shadeling begins at 32 health and cycles through attack intents 8, 12, and 6.

The opening reference circuit delivers 12 damage for 1 energy. Its first cast leaves Shadeling at 20 health and the player at 22 health. The next turn starts with the temporary Spark replaced by wire.

The visual reference uses illustrative health values and Turn 2. Those are not the training encounter's starting state.

RC-004's [content definitions](content-definitions.md) configure current stats, ownership, initial placement and scalar intents within these rules. The alternate development fixture is not a production roster addition or a balance decision. Endpoint geometry, effect lifetime, Split cost and other experiment questions remain unchanged.


## Experiment-only development mode

RC-005 provides explicitly opt-in alternatives through `-Experiment`; they do not change the normal rules above. See [circuit experiments](circuit-experiments.md) for provisional semantics, seeds, controls and limitations. No winning production rules or human-playtest results have been declared.
