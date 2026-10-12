# Official final gameplay visual — October 11, 2026

**October 12 Menu/progression clarification:** The menu's former Shop label is now **Store**, a separate destination for purchasing in-game items such as runes, perks and relics. It is not a shortcut restricted to shop rooms. Entering a shop room opens that room as the main screen. The owner also intends permanent rune acquisition from conquering a map or defeating a hard boss; detailed progression and purchase rules remain planned. This updates Menu semantics without altering the retained approved images or the Combat requirements below. See the current [design specification](v1-design-spec.md) and [corrected menu specimen](../output/art/rc-013/store-clarification/menu-open-360x640.png).

The owner most recently requested: “Please use this one as approved final version of gameplay,” supplying the clean-board image below. This is the **current approved final Combat visual target**, superseding the earlier labelled/numbered board and prior Split/Join symbols. The complete crypt/supporting-UI scope remains. Home, Map and Menu retain their existing approvals.

![Official final gameplay visual](../output/imagegen/approved/combat-final-v2-clean-board.png)

The [canonical image](../output/imagegen/approved/combat-final-v2-clean-board.png) is an exact841×1870 copy of the latest supplied PNG, with no regeneration, retouching or resizing. [Current approval evidence](../source-assets/pilot/revisions/r005/delivery.md) records the exact attachment and comparison with v10. [Previous approved image](../output/imagegen/approved/combat-final.png) and r003/r004 sources/reviews remain preserved. This is a finished visual reference, not a layered production asset or runtime screenshot.

## Approved visual and interaction changes

| Requirement | Final image and implementation target |
| --- | --- |
| Complete painted screen | Full indigo crypt, stone floor/statues/candles, centered Shadeling and lantern, complete gold/navy/turquoise frames, serif labels and supporting UI. No placeholder environment, question-mark symbol or flat substitute panel may stand in for these in a future matching preview |
| Undirected circuits | Circuit connection strokes have no flow arrowheads. Wiring glyphs use the corrected approved silhouettes below. Compatible connected ports have no input/output direction requirement. Rotate changes connection geometry; its curved arrow represents an editing action |
| Clean board | Only **BEGIN** and **END** retain text inside the4×4board. Remove SPARK/SPLIT/JOIN and other slot names, rune values, branch totals, End total, cost badges and TEMP. Keep glyphs and connections. This does not remove labels/values from hand cards, toolbar, piles or external summary |
| Corrected Split/Join | Use the supplied **sideways fork** for Split (left stem, upper-right/lower-right branches) and **upright trident** for Join, on both board and wiring toolbar. Replace the r004 Y/T substitutes. Match the illustrated silhouettes; decorative terminal points do not restore directional port rules or by themselves redefine port counts |
| Editing actions | **Remove** and **Rotate** only. Remove Flip, Undo, Inspect, Cancel selection and Details / Pass from this gameplay control area. The eraser icon labels Remove. Wiring selection tools Straight, Corner, Split and Join remain |
| Hand and piles | Illustrated cards show energy cost, name, symbol, type and short effect description. Draw pile on the left and Discard pile on the right, each with a visible count |
| Information above Cast | Persistent bar shows damage, shield, energy cost and incoming damage directly above Cast. Keep the small action-log line above the hand |
| Primary action and navigation | Large turquoise pointed Cast, blue energy crystal and live cost; “Cast ends turn” beneath. Preserve Menu, Map, Guide and Sound navigation and the top pause control |

## Rules change and implementation boundary

The owner's directionless-circuit request is an **accepted design change**, not merely hiding arrowheads. Connected compatible ports must work in either traversal direction; a route may not be rejected solely because an old input/output label is reversed. Begin and End remain visibly present. Removing Flip and the extra editing controls is also accepted scope, as are the detailed cards, draw/discard sections and permanent information bar.

Saving this image does not implement those changes in Godot. The current core evaluator, directed port metadata, control bindings and tests still describe the older implemented contract. Before claiming playable completion, update and test undirected connectivity, rotated adjacency, branch/rejoin aggregation, cycle/repeated-trigger handling, costs/ownership/cleanup, Remove/Rotate controls, hand/pile counters and forecast bindings. The request does not specify a new cycle algorithm or repeat-trigger policy; do not silently invent one from painted lines. Likewise, removal of the visible Details / Pass control does not by itself specify an alternative no-cast turn-ending behavior.

Older documentation remains evidence of the implemented baseline, but conflicting design requirements—direction arrows, Flip/Undo/Inspect/Cancel/Details-Pass buttons, compact-only hand and no permanent forecast—must not be reintroduced into the new visual target. Existing affordance, affordability and terminal-state checks are not removed merely because circuits are undirected.

The latest image retains the yellow BOSS label above Shadeling's name/health. October 12 owner direction establishes Shadeling as a boss for one map encounter, with BOSS supplied by live role UI. Infinity stock, the particular board layout, HP, Turn2, Draw8/Discard5 and external12damage/1cost are illustrative values. The user did not separately request infinite connector supply, a guaranteed opening arrangement, or new balance values. The boss role does not establish final-guardian status, extra phases or permanent rewards. Removing board values does not remove their underlying gameplay data or the external forecast. Keep live state separate; do not bake this screen into the game as a replacement for controls.

## Scope and acceptance

The official final-image request is fulfilled by the exact supplied complete artwork. The earlier pilot's crypt/supporting-UI exclusions and permission to use placeholders are superseded for subsequent complete-preview production. Any rebuilt preview must match this entire image's visual construction; producing only a closer character/button does not meet that requirement.

This approval applies to this supplied image. It does not retroactively approve reconstructed assets, complete RC-012–RC-017, verify runtime behavior or prove device readiness. The [r006 editable pilot](../source-assets/pilot/revisions/r006/delivery.md) applies the latest board cleanup and corrected symbols while reusing r004 painted sources. Earlier revisions remain historical. Its assistant visual/source review is separate from owner approval of the supplied image. The original no-Git restriction remains in force.
